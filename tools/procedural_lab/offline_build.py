"""Build/test into a new private directory. Never starts Max or installs files."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--year", type=int, choices=(2026, 2027))
    args = parser.parse_args()
    spec = importlib.util.spec_from_file_location("build_max", ROOT / "tools/build_max.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    env = module.compiler_environment(Path("C:/Program Files/Microsoft Visual Studio/2022/Community"), "14.38.33130", "10.0.19041.0")
    folder = ROOT / "build/offline-implementation-20261005" / (f"max{args.year}" if args.year else "core")
    folder.mkdir(parents=True, exist_ok=True)
    command = ["cmake", "-S", str(ROOT / "AminScatter"), "-B", str(folder), "-G", "NMake Makefiles", "-DCMAKE_BUILD_TYPE=Release"]
    if args.year:
        sdk = ROOT / f"build/tooling/max{args.year}-sdk/Program Files/Autodesk/3ds Max {args.year} SDK/maxsdk"
        command += ["-DAMIN_BUILD_MAX=ON", f"-DCYRUS_MAX_YEAR={args.year}", f"-DMAXSDK_ROOT={sdk}"]
    else:
        command += ["-DAMIN_BUILD_MAX=OFF"]
    stages = [("configure", command), ("build", ["cmake", "--build", str(folder)]),
              ("tests", ["ctest", "--test-dir", str(folder), "--output-on-failure", "-j", "1"])]
    results = []
    for stage, cmd in stages:
        result = subprocess.run(cmd, cwd=ROOT, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (folder / f"{stage}.log").write_text(result.stdout, encoding="utf-8")
        results.append({"stage": stage, "exit_code": result.returncode})
        print(f"{stage}: {result.returncode}", flush=True)
        if result.returncode or stage == "tests":
            print(result.stdout[-18000:], flush=True)
        if result.returncode:
            raise SystemExit(result.returncode)
    binary_suffixes={".dlx",".dlm",".dlh",".dlu"}
    binaries={str(p.relative_to(ROOT)).replace("\\","/"):hashlib.sha256(p.read_bytes()).hexdigest()
              for p in folder.rglob("*") if p.is_file() and p.suffix.lower() in binary_suffixes}
    source_paths=[ROOT/"AminScatter/CMakeLists.txt",ROOT/"AminScatter/scripts/AminScatterObject.ms"]
    for name in ("src","include","tests"):
        source_paths += sorted((ROOT/"AminScatter"/name).rglob("*"))
    sources={str(p.relative_to(ROOT)).replace("\\","/"):hashlib.sha256(p.read_bytes()).hexdigest()
             for p in source_paths if p.is_file()}
    (folder / "receipt.json").write_text(json.dumps({"stages": results, "max_year": args.year,
        "host_launched": False, "installed": False,"binaries":binaries,"sources":sources,
        "qualification":"SDK compilation and native executables only; generated MAXScript is hashed, not compiled by Max."}, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
