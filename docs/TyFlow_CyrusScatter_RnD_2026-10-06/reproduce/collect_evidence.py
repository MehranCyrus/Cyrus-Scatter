"""Curate factual receipts; never copy vendor pseudocode, assembly or SDK sources."""
import argparse
import hashlib
import json
import re
import shutil
import xml.etree.ElementTree as ET
from pathlib import Path


def sha(path):
    with path.open("rb") as stream:
        h = hashlib.sha256()
        for chunk in iter(lambda: stream.read(1024*1024), b""):
            h.update(chunk)
        return h.hexdigest()


def main():
    p = argparse.ArgumentParser()
    p.add_argument("repo", type=Path)
    p.add_argument("private", type=Path)
    p.add_argument("probe", type=Path)
    a = p.parse_args()
    out = Path(__file__).resolve().parents[1] / "evidence"
    out.mkdir(exist_ok=True)

    def write(name, value):
        target = out / name
        if target.exists():
            raise FileExistsError(target)
        target.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")

    old = a.repo / "docs/Integrated_UI_0.72_2026-10-06/evidence"
    index = json.loads((old / "index.json").read_text())
    checked = []
    for name, spec in index["files"].items():
        actual = {"bytes": (old / name).stat().st_size, "sha256": sha(old / name)}
        checked.append({"name": name, "matches": actual == spec})
    native = []
    for receipt in (old / "native-2026-scatter.json", old / "native-2027-scatter.json",
                    old / "native-2026-analyzer.json", old / "native-2027-analyzer.json"):
        data = json.loads(receipt.read_text())
        native.append({"receipt": receipt.name,
                       "checked_sources": len(data["sources"]),
                       "source_mismatches": [n for n,h in data["sources"].items() if sha(a.repo/n) != h],
                       "checked_binaries": len(data["binaries"]),
                       "binary_mismatches": [n for n,h in data["binaries"].items() if sha(a.repo/n) != h]})
    write("prior-receipt-audit.json", {"indexed_receipts": checked, "native": native,
                                       "all_matches": all(r["matches"] for r in checked) and
                                       all(not r["source_mismatches"] and not r["binary_mismatches"] for r in native),
                                       "runtime_reexecuted": False})
    selected = []
    for batch in ("batch07", "batch08", "batch09"):
        folder = a.private / batch
        data = json.loads((folder / "manifest.json").read_text())
        statuses = {}
        for line in (folder / "script-response.txt").read_text().splitlines():
            fields = line.split("\t")
            if len(fields) >= 7 and fields[4].isdigit() and fields[5].isdigit():
                statuses[fields[0]] = {"disassembly_command_ok": fields[3] == "true", "instructions": int(fields[4]),
                                       "decoded_instruction_bytes": int(fields[5]), "decompiler_completed": fields[6] == "true"}
        for item in data["selection"]:
            label = item["label"]
            body = (folder / (label + ".c")).read_text(errors="replace") if (folder / (label + ".c")).exists() else ""
            warnings = sorted(set(re.findall(r"/\* WARNING: ([^\r\n*]+)", body)))
            selected.append({"batch": batch, "label": label, "begin_rva": item["begin"],
                             "end_exclusive_rva": item["end_exclusive"],
                             "selected_span_bytes": int(item["end_exclusive"],16)-int(item["begin"],16),
                             **statuses[label], "generic_decompiler_warnings": warnings,
                             "private_artifacts": [v for v in data["files"] if v["name"].startswith(label + ".")],
                             "complete_private_function_not_certified": True})
    write("static-region-ledger.json", {"target_sha256": "5b1068b5b3627f64f78cd2b51ca0c23d616be09943077d5ffcf1c6fecc713fd9",
                                         "preferred_image_base": "0x180000000", "regions": selected,
                                         "vendor_executed": False,
                                         "semantic_label_corrections": {"Pool_Dispatch_Parameters": "Main-thread progress/UI guard",
                                                                        "Pool_Job_Bank_Access": "Worker-count settings/clamp"}})
    for name in ("selected-rtti.json", "process-closed.json"):
        write(name, json.loads((a.private / name).read_text(encoding="utf-8-sig")))
    write("display-abi.json", json.loads((a.private / "display-abi/receipt.json").read_text()))
    for name in ("CustomItemABIProbe.txt", "VirtualDeviceABIProbe.txt"):
        shutil.copyfile(a.private / "display-abi" / name, out / name)
    write("core-probe.json", json.loads((a.probe / "receipt.json").read_text()))
    first = a.probe.parent / "core-probe01"
    for name in ("ctest.log", "probe.log"):
        shutil.copyfile(first / name, out / ("first-" + name))
    write("core-build-commands.json", json.loads((first / "commands.json").read_text()))
    suites = ET.parse(a.probe.parent / "python-tests.xml").getroot()
    totals = {k: sum(int(s.attrib.get(k,0)) for s in suites.iter("testsuite")) for k in ("tests","failures","errors","skipped")}
    write("python-tests.json", {**totals, "junit_sha256": sha(a.probe.parent / "python-tests.xml"),
                               "command": "build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q --junitxml=build/rnd-072-20261006/python-tests.xml"})
    print(json.dumps({"prior_receipts": len(checked), "prior_all_match": all(r["matches"] for r in checked),
                      "new_selected_regions": len(selected), "python": totals}))


if __name__ == "__main__":
    main()
