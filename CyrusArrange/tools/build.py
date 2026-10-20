"""Build/test Cyrus Arrange in a new private directory. Does not install or launch Max."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_hashes():
    files = [ROOT / "CMakeLists.txt"]
    for folder in ("include", "src", "scripts", "tests", "tools", "installer", "third_party"):
        files += [p for p in (ROOT / folder).rglob("*") if p.is_file() and "__pycache__" not in p.parts]
    return {p.relative_to(ROOT).as_posix(): sha(p) for p in sorted(files)}


def compiler_environment():
    vc = Path("C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.38.33130")
    kits = Path("C:/Program Files (x86)/Windows Kits/10")
    bins = [vc / "bin/Hostx64/x64", kits / "bin/10.0.19041.0/x64"]
    includes = [vc / "include", vc / "atlmfc/include"] + [kits / "Include/10.0.19041.0" / p for p in ("ucrt", "shared", "um", "winrt", "cppwinrt")]
    libs = [vc / "lib/x64", vc / "atlmfc/lib/x64"] + [kits / "Lib/10.0.19041.0" / p / "x64" for p in ("ucrt", "um")]
    for path in [bins[0] / "cl.exe", bins[0] / "nmake.exe", bins[1] / "rc.exe"] + includes + libs:
        if not path.exists():
            raise SystemExit(f"Missing prerequisite: {path}")
    env = os.environ.copy()
    env.update(PATH=os.pathsep.join(map(str, bins)) + os.pathsep + env["PATH"], INCLUDE=os.pathsep.join(map(str, includes)), LIB=os.pathsep.join(map(str, libs)))
    return env


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--core-only", action="store_true")
    parser.add_argument("--sdk", type=Path, default=ROOT.parent / "build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk")
    args = parser.parse_args()
    output = args.output.resolve()
    if not output.is_relative_to(ROOT / "build"):
        parser.error("Build output must be under CyrusArrange/build")
    output.mkdir(parents=True, exist_ok=False)
    env = compiler_environment()
    sources = source_hashes()
    receipt = {"status": "pending", "version": "0.3.2", "utc": datetime.now(timezone.utc).isoformat(), "sources": sources, "max_year": 2027 if not args.core_only else None, "installed": False, "host_launched": False}
    receipt_path = output / "receipt.json"
    receipt_path.write_text(json.dumps(receipt, indent=2))
    configure = ["cmake", "-S", str(ROOT), "-B", str(output), "-G", "NMake Makefiles", "-DCMAKE_BUILD_TYPE=Release", "-DCYRUS_ARRANGE_BUILD_MAX=" + ("OFF" if args.core_only else "ON")]
    if not args.core_only:
        configure.append("-DMAXSDK_ROOT=" + str(args.sdk.resolve()))
    receipt["stages"] = []
    for name, command in [("configure", configure), ("build", ["cmake", "--build", str(output)]), ("tests", ["ctest", "--test-dir", str(output), "--output-on-failure"])]:
        run = subprocess.run(command, env=env, cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        (output / f"{name}.log").write_text(run.stdout, encoding="utf-8")
        print(f"{name}: {run.returncode}\n{run.stdout[-12000:]}", flush=True)
        receipt["stages"].append({"name": name, "exit_code": run.returncode})
        receipt_path.write_text(json.dumps(receipt, indent=2))
        if run.returncode:
            raise SystemExit(run.returncode)
    if sources != source_hashes():
        raise SystemExit("Source changed during build: receipt remains pending; rebuild frozen sources")
    receipt.update(status="passed", binaries={p.name: sha(p) for suffix in ("*.dlx", "*.dlh") for p in output.glob(suffix)}, toolchain={"msvc": "14.38.33130", "windows_sdk": "10.0.19041.0", "max_sdk": str(args.sdk.resolve()) if not args.core_only else None})
    receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")


if __name__ == "__main__":
    main()
