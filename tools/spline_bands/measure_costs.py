"""Compile an owned benchmark against a frozen SDK-free native build; no Max."""
import argparse
import ctypes
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from build_max import compiler_environment


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--native-build", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--kind", choices=("field", "generation"), default="generation")
    args = parser.parse_args()
    build = args.native_build.resolve()
    receipt = json.loads((build / "receipt.json").read_text(encoding="utf-8"))
    if any(x["exit_code"] for x in receipt["stages"]):
        raise ValueError("Successful frozen native build required")
    header = ROOT / "AminScatter/include/scatter.h"
    if hashlib.sha256(header.read_bytes()).hexdigest() != receipt["sources"][header.relative_to(ROOT).as_posix()]:
        raise ValueError("Current header differs from its compiled build")
    for rel in ("AminScatter/include/spline_bands.h", "AminScatter/src/spline_bands.cpp"):
        if hashlib.sha256((ROOT / rel).read_bytes()).hexdigest() != receipt["sources"].get(rel):
            raise ValueError("Field implementation differs from its build: " + rel)
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    env = compiler_environment(Path("C:/Program Files/Microsoft Visual Studio/2022/Community"), "14.38.33130", "10.0.19041.0")
    source = Path(__file__).with_name(args.kind + "_benchmark.cpp")
    compiler = shutil.which("cl.exe", path=env["PATH"])
    if compiler is None:
        raise ValueError("Configured MSVC compiler unavailable")
    command = [compiler, "/nologo", "/O2", "/EHsc", "/std:c++17", "/MD", f"/I{header.parent}", str(source),
               str(build / "amin_scatter.lib"), str(build / "cyrus_vector_clip.lib"),
               f"/Fo{output / 'benchmark.obj'}", f"/Fe{output / 'benchmark.exe'}"]
    compiled = subprocess.run(command, cwd=output, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    (output / "compile.log").write_text(compiled.stdout, encoding="utf-8")
    if compiled.returncode:
        print(compiled.stdout)
        raise SystemExit(compiled.returncode)
    process = subprocess.Popen([str(output / "benchmark.exe")], cwd=output, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    measured, _ = process.communicate()

    class MemoryCounters(ctypes.Structure):
        _fields_ = [("cb", ctypes.c_ulong), ("faults", ctypes.c_ulong)] + [(name, ctypes.c_size_t) for name in
                    ("peak_working_set", "working_set", "peak_paged", "paged", "peak_nonpaged", "nonpaged", "pagefile", "peak_pagefile")]

    memory = MemoryCounters()
    memory.cb = ctypes.sizeof(memory)
    memory_ok = ctypes.windll.psapi.GetProcessMemoryInfo(ctypes.c_void_p(int(process._handle)), ctypes.byref(memory), memory.cb)
    (output / "measurements.csv").write_text(measured, encoding="utf-8")
    evidence = {"command": command, "exit_code": process.returncode, "build": str(build),
                "benchmark_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
                "build_receipt_sha256": hashlib.sha256((build / "receipt.json").read_bytes()).hexdigest(),
                "peak_working_set_bytes": memory.peak_working_set if memory_ok else None,
                "peak_pagefile_bytes": memory.peak_pagefile if memory_ok else None,
                "limitations": "SDK-free CPU wall times; no UI, GPU, host extraction or presented frames."}
    (output / "receipt.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    print(measured)
    raise SystemExit(process.returncode)


if __name__ == "__main__":
    main()
