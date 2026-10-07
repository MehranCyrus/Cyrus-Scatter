"""Read-only bounded RTTI anchors; names and slots are leads, not behavior proof."""
import argparse
import importlib.util
import json
import mmap
import struct
from pathlib import Path


def main():
    p = argparse.ArgumentParser()
    p.add_argument("binary", type=Path)
    p.add_argument("output", type=Path)
    a = p.parse_args()
    spec = importlib.util.spec_from_file_location("static_pe", Path(__file__).resolve().parents[2] / "TyFlow_Architecture_Research_2026-10-06/reproduce/static_pe.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    with a.binary.open("rb") as stream, mmap.mmap(stream.fileno(), 0, access=mmap.ACCESS_READ) as data:
        pe = module.PE(data)
        records = pe.rtti([".?AV" + name + "@@" for name in (
            "ParticleRenderer", "TerrainRendererItem", "ThreadPool", "ThreadPool_lockless", "tfSpatialHashmapFlat")])
        for record in records:
            for locator in record["locators"]:
                ch = struct.unpack_from("<IIII", data, pe.offset(int(locator["hierarchy_rva"], 16)))
                if ch[2] > 256:
                    raise ValueError("Unreasonable RTTI base count")
                bases = []
                for i in range(ch[2]):
                    bcd = struct.unpack_from("<I", data, pe.offset(ch[3]) + i * 4)[0]
                    td, count, mdisp, pdisp, vdisp, attr = struct.unpack_from("<IIiiiI", data, pe.offset(bcd))
                    bases.append({"name": pe.string(td + 16), "mdisp": mdisp, "pdisp": pdisp, "vdisp": vdisp, "attributes": attr})
                locator["bases"] = bases
    if a.output.exists():
        raise FileExistsError(a.output)
    a.output.write_text(json.dumps(records, indent=2))
    for r in records:
        print(r["name"], [(x["object_offset"], [b["name"] for b in x["bases"]],
                            [(v["vtable_rva"], len(v["slots"])) for v in x["vtables"]]) for x in r["locators"]])


if __name__ == "__main__":
    main()
