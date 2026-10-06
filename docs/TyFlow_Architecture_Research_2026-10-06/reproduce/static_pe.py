"""Bounded, read-only PE anchors. No loading or executing the target.

Raw instruction-byte matches and unwind ranges are candidates, not verified
instructions or complete source functions. Verify selected candidates in Ghidra.
"""
import argparse
import bisect
import hashlib
import json
import mmap
import re
import struct
from collections import Counter
from pathlib import Path


class PE:
    def __init__(self, data):
        self.data = data
        if data[:2] != b"MZ":
            raise ValueError("Not a PE image")
        header = struct.unpack_from("<I", data, 0x3C)[0]
        if data[header:header + 4] != b"PE\0\0":
            raise ValueError("Invalid PE signature")
        count = struct.unpack_from("<H", data, header + 6)[0]
        optional_size = struct.unpack_from("<H", data, header + 20)[0]
        optional = header + 24
        if struct.unpack_from("<H", data, optional)[0] != 0x20B:
            raise ValueError("Expected PE32+")
        self.base = struct.unpack_from("<Q", data, optional + 24)[0]
        self.directories = [
            struct.unpack_from("<II", data, optional + 112 + i * 8)
            for i in range(16)
        ]
        self.sections = []
        for i in range(count):
            fields = struct.unpack_from(
                "<8sIIIIIIHHI", data, optional + optional_size + i * 40
            )
            self.sections.append(dict(
                name=fields[0].rstrip(b"\0").decode("ascii", "replace"),
                size=fields[3], rva=fields[2], raw=fields[4],
                executable=bool(fields[9] & 0x20000000),
            ))
        self.unwind = []
        rva, size = self.directories[3]
        for offset in range(self.offset(rva), self.offset(rva) + size, 12):
            begin, end, info = struct.unpack_from("<III", data, offset)
            self.unwind.append((begin, end, info))
        self.unwind.sort()
        self.starts = [row[0] for row in self.unwind]

    def offset(self, rva):
        for section in self.sections:
            delta = rva - section["rva"]
            if 0 <= delta < section["size"]:
                return section["raw"] + delta
        raise ValueError(f"Unmapped RVA {rva:#x}")

    def rva(self, offset):
        for section in self.sections:
            if section["raw"] <= offset < section["raw"] + section["size"]:
                return section["rva"] + offset - section["raw"]
        raise ValueError(f"Unmapped file offset {offset:#x}")

    def string(self, rva):
        offset = self.offset(rva)
        end = self.data.find(b"\0", offset, offset + 8192)
        if end < 0:
            raise ValueError("Unterminated string")
        return self.data[offset:end].decode("ascii", "replace")

    def code(self, va):
        return any(
            s["executable"] and s["rva"] <= va - self.base < s["rva"] + s["size"]
            for s in self.sections
        )

    def region(self, rva):
        index = bisect.bisect_right(self.starts, rva) - 1
        if index >= 0 and rva < self.unwind[index][1]:
            begin, end, info = self.unwind[index]
            result = dict(begin=hex(begin), end_exclusive=hex(end), bytes=end - begin)
            try:
                header = self.offset(info)
                flags = self.data[header] >> 3
                slots = self.data[header + 2]
                result["unwind_info_rva"] = hex(info)
                result["unwind_flags"] = flags
                if flags & 4:
                    parent = struct.unpack_from(
                        "<III", self.data, header + 4 + ((slots + 1) & ~1) * 2
                    )
                    result["chained_parent"] = dict(
                        begin=hex(parent[0]), end_exclusive=hex(parent[1]),
                        unwind_info_rva=hex(parent[2]),
                    )
            except (ValueError, struct.error):
                result["unwind_decode_error"] = True
            return result
        return None

    def imports(self):
        records = []
        for directory, delay in ((1, False), (13, True)):
            rva, _ = self.directories[directory]
            if not rva:
                continue
            table = self.offset(rva)
            for i in range(4096):
                if delay:
                    attributes, name, _, iat, lookup, _, _, _ = struct.unpack_from(
                        "<IIIIIIII", self.data, table + i * 32
                    )
                    if not name:
                        break
                    if not attributes & 1:
                        raise ValueError("Unsupported VA-based delay table")
                else:
                    lookup, _, _, name, iat = struct.unpack_from(
                        "<IIIII", self.data, table + i * 20
                    )
                    if not name:
                        break
                    lookup = lookup or iat
                module = self.string(name)
                for j in range(100000):
                    value = struct.unpack_from("<Q", self.data, self.offset(lookup) + j * 8)[0]
                    if not value:
                        break
                    symbol = (
                        f"ordinal:{value & 65535}" if value >> 63
                        else self.string(value + 2)
                    )
                    records.append(dict(
                        module=module, name=symbol, iat_rva=iat + j * 8,
                        delay_loaded=delay,
                    ))
        return records

    def pointer_locations(self, value, width=8):
        pattern = struct.pack("<Q" if width == 8 else "<I", value)
        result = []
        for section in self.sections:
            if section["name"] not in {".rdata", ".data"}:
                continue
            start, end = section["raw"], section["raw"] + section["size"]
            position = self.data.find(pattern, start, end)
            while position >= 0:
                result.append(self.rva(position))
                position = self.data.find(pattern, position + 1, end)
        return result

    def rtti(self, names):
        """MSVC x64 COL signature/self-RVA validation, with bounded vtable reads."""
        records = []
        for name in names:
            encoded = name.encode("ascii") + b"\0"
            position = self.data.find(encoded)
            if position < 0:
                continue
            descriptor = self.rva(position) - 16
            locators = []
            for reference in self.pointer_locations(descriptor, width=4):
                locator_rva = reference - 12
                try:
                    signature, obj_offset, cd_offset, td, hierarchy, self_rva = struct.unpack_from(
                        "<IIIIII", self.data, self.offset(locator_rva)
                    )
                    if signature != 1 or td != descriptor or self_rva != locator_rva:
                        continue
                    tables = []
                    for pointer_rva in self.pointer_locations(self.base + locator_rva):
                        if pointer_rva % 8:
                            continue
                        table = pointer_rva + 8
                        slots = []
                        for slot in range(512):
                            address = struct.unpack_from(
                                "<Q", self.data, self.offset(table + slot * 8)
                            )[0]
                            if not self.code(address):
                                break
                            slots.append(dict(
                                slot=slot, va=hex(address), rva=hex(address - self.base),
                                unwind_region=self.region(address - self.base),
                            ))
                        if slots:
                            tables.append(dict(vtable_rva=hex(table), slots=slots))
                    locators.append(dict(
                        rva=hex(locator_rva), object_offset=obj_offset,
                        constructor_displacement=cd_offset, hierarchy_rva=hex(hierarchy),
                        vtables=tables,
                    ))
                except (ValueError, struct.error):
                    continue
            records.append(dict(
                name=name, descriptor_rva=hex(descriptor), locators=locators,
            ))
        return records


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("binary", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--expected-sha256", required=True)
    args = parser.parse_args()
    fingerprint = hashlib.sha256()
    with args.binary.open("rb") as stream:
        for block in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            fingerprint.update(block)
    actual = fingerprint.hexdigest()
    if actual.lower() != args.expected_sha256.lower():
        raise ValueError("Different binary build; addresses must be reconsidered")
    args.output.mkdir(parents=True, exist_ok=True)
    with args.binary.open("rb") as stream, mmap.mmap(stream.fileno(), 0, access=mmap.ACCESS_READ) as data:
        pe = PE(data)
        imports = pe.imports()
        selected = {
            row["iat_rva"]: row for row in imports if re.search(
                r"QmaxRollup|Create.*ParamMap|BeginEditParams@ClassDesc|EndEditParams@ClassDesc|"
                r"NotifyDependents|RegisterNotification|UnRegisterNotification|"
                r"blockSignals@QObject|setUpdatesEnabled@QWidget|"
                r"activate@QLayout|connectImpl@QObject|connect@QObject|"
                r"start@QTimer|stop@QTimer|"
                r"ObjectValidity|UpdateValidity|Validity@ObjectState", row["name"]
            )
        }
        import_refs, direct_refs = [], []
        anchors = {0x4023650, 0x1C4F790}
        for section in pe.sections:
            if not section["executable"]:
                continue
            start, end = section["raw"], section["raw"] + section["size"]
            for match in re.finditer(rb"\xff[\x15\x25].{4}", data[start:end], re.DOTALL):
                rva = section["rva"] + match.start()
                target = rva + 6 + struct.unpack_from("<i", match.group(), 2)[0]
                if target in selected:
                    import_refs.append(dict(
                        rva=hex(rva), opcode=match.group().hex(),
                        import_symbol=selected[target], unwind_region=pe.region(rva),
                    ))
            for match in re.finditer(rb"[\xe8\xe9].{4}", data[start:end], re.DOTALL):
                rva = section["rva"] + match.start()
                target = rva + 5 + struct.unpack_from("<i", match.group(), 1)[0]
                if target in anchors:
                    direct_refs.append(dict(
                        rva=hex(rva), target_rva=hex(target),
                        opcode=match.group().hex(), unwind_region=pe.region(rva),
                    ))
        names = [
            ".?AV" + name + "@@" for name in (
                "TFlow", "TFlowClassDesc", "TFlow_OP_birth", "tfPBAccessor",
                "ParticleRenderer", "Ui_objects_tyflow_settings_wrapper",
                "Ui_objects_tyflow_cache_wrapper", "Ui_op_birth_wrapper",
                "Ui_op_birth_tracking_wrapper", "tyQtLineEdit",
                "tyQtFilterableCombobox", "tyQtDoubleSpinBox", "tyQtSpinBox",
                "tyQtWorldSpinBox", "tyQtPushButton",
            )
        ]
        report = dict(
            binary=str(args.binary), sha256=actual, base=hex(pe.base),
            method="Read-only raw PE scan; selected instruction candidates need disassembler verification",
            limitations=[
                "Byte patterns can match non-instructions",
                "Unwind regions are not guaranteed complete multi-region functions",
                "Bounded code-pointer sequences are candidate vtables, not recovered declarations",
                "No target execution or runtime profiling",
            ],
            imports=imports, selected_import_refs=import_refs,
            selected_direct_refs=direct_refs, selected_rtti=pe.rtti(names),
        )
        (args.output / "static-anchors.json").write_text(
            json.dumps(report, indent=2), encoding="utf-8"
        )
        counts = Counter(row["import_symbol"]["name"] for row in import_refs)
        print(json.dumps(dict(
            sha256=actual, imports=len(imports), candidate_refs=len(import_refs),
            direct_constructor_candidates=len(direct_refs),
            named_rtti=len(report["selected_rtti"]), import_counts=counts,
        ), indent=2))


if __name__ == "__main__":
    main()
