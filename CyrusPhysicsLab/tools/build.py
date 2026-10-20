"""Build the independent Max 2027 physics laboratory; never install or launch Max."""
from pathlib import Path
import argparse
import hashlib
import importlib.util
import json
import subprocess
import time
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / "CyrusPhysicsLab"
PINS = {
    "jolt": ("jrouwe/JoltPhysics", "1b2e77e3c6c09709e5edc79dc208459b8ff32051"),
    "physx": ("NVIDIA-Omniverse/PhysX", "b97365c6ddb32fda8469bc788ec18024862b0368"),
}


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def dependencies():
    base = ROOT / "build/physics-lab-dependencies"
    base.mkdir(parents=True, exist_ok=True)
    result = {}
    for name, (repository, commit) in PINS.items():
        target = base / (name + "-" + commit)
        receipt = target / "cyrus-source-receipt.json"
        if not receipt.exists():
            archive = base / (name + "-" + commit + ".zip")
            if not archive.exists():
                url = f"https://codeload.github.com/{repository}/zip/{commit}"
                print(f"Downloading {name} at {commit}", flush=True)
                temporary = archive.with_suffix(".part")
                for attempt in range(3):
                    try:
                        with urllib.request.urlopen(url, timeout=60) as src, temporary.open("wb") as dst:
                            while chunk := src.read(1024 * 1024):
                                dst.write(chunk)
                        temporary.replace(archive)
                        break
                    except Exception:
                        if attempt == 2:
                            raise
                        time.sleep(2)
            target.mkdir(exist_ok=True)
            with zipfile.ZipFile(archive) as source:
                for item in source.infolist():
                    relative = Path(*Path(item.filename).parts[1:])
                    destination = (target / relative).resolve()
                    if not destination.is_relative_to(target.resolve()):
                        raise RuntimeError("Invalid source archive path")
                    if item.is_dir():
                        destination.mkdir(parents=True, exist_ok=True)
                    else:
                        destination.parent.mkdir(parents=True, exist_ok=True)
                        destination.write_bytes(source.read(item))
            receipt.write_text(json.dumps({"repository": repository, "commit": commit,
                "archive_sha256": digest(archive)}, indent=2) + "\n", encoding="utf-8")
        result[name] = target
        print(f"{name}: {target}", flush=True)
    return result


def compiler_environment():
    spec = importlib.util.spec_from_file_location("cyrus_build_toolchain", ROOT / "tools/build_max.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.compiler_environment(Path("C:/Program Files/Microsoft Visual Studio/2022/Community"),
                                       "14.38.33130", "10.0.19041.0")


def run(command, folder, stage, env):
    print(stage, flush=True)
    previous = folder / (stage + ".log")
    if previous.exists():
        archive = folder / "attempts"
        archive.mkdir(exist_ok=True)
        previous.replace(archive / (str(time.time_ns()) + "-" + stage + ".log"))
    with (folder / (stage + ".log")).open("w", encoding="utf-8") as log:
        process = subprocess.run(command, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT)
    print(f"{stage}: {process.returncode}", flush=True)
    if process.returncode:
        print((folder / (stage + ".log")).read_text(encoding="utf-8")[-18000:], flush=True)
        raise SystemExit(process.returncode)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dependencies-only", action="store_true")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--core-only", action="store_true")
    parser.add_argument("--faults", action="store_true", help="Private fault build; cannot be packaged")
    args = parser.parse_args()
    sources = dependencies()
    if args.dependencies_only:
        return
    folder = args.output.resolve() if args.output else ROOT / "build/physics-lab-010-20261016-01"
    if not folder.is_relative_to(ROOT / "build"):
        parser.error("Build output must be inside the ignored repository build directory")
    folder.mkdir(parents=True, exist_ok=True)
    env = compiler_environment()
    shared_paths = ("cmake/CyrusMaxSDK.cmake", "tools/build_max.py",
                    "CyrusLicensing/third_party/nlohmann/json.hpp",
                    "CyrusLicensing/third_party/nlohmann/LICENSE.MIT")
    shared_before = {name: digest(ROOT / name) for name in shared_paths}
    before = {p.relative_to(PROJECT).as_posix(): digest(p) for p in PROJECT.rglob("*")
              if p.is_file() and "__pycache__" not in p.parts}
    sdk = ROOT / "build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk"
    command = ["cmake", "-S", str(PROJECT), "-B", str(folder), "-G", "Ninja",
               "-DCMAKE_BUILD_TYPE=Release", f"-DJOLT_SOURCE={sources['jolt']}",
               f"-DPHYSX_SOURCE={sources['physx']}", f"-DMAXSDK_ROOT={sdk}",
               "-DCYRUS_MAX_YEAR=2027", f"-DCPL_TEST_FAULTS={'ON' if args.faults else 'OFF'}",
               f"-DCPL_BUILD_MAX={'OFF' if args.core_only else 'ON'}"]
    run(command, folder, "configure", env)
    run(["cmake", "--build", str(folder), "--parallel", "4"], folder, "build", env)
    run(["ctest", "--test-dir", str(folder), "--output-on-failure"], folder, "tests", env)
    files = {p.relative_to(PROJECT).as_posix(): digest(p) for p in PROJECT.rglob("*")
             if p.is_file() and "__pycache__" not in p.parts}
    if files != before:
        raise RuntimeError("Laboratory sources changed during the build; rerun for a qualified pair")
    if shared_before != {name: digest(ROOT / name) for name in shared_paths}:
        raise RuntimeError("Shared build/header dependencies changed during this build")
    (folder / "receipt.json").write_text(json.dumps({"version": "0.2.1", "max_year": 2027,
        "source_hashes": files, "shared_source_hashes": shared_before, "pins": PINS,
        "toolchain": {"msvc": "14.38.33130", "windows_sdk": "10.0.19041.0"},
        "dependency_archives": {name: json.loads((path / "cyrus-source-receipt.json").read_text())
                                for name, path in sources.items()},
        "host_launched": False, "installed": False, "faults": args.faults,
        "binaries": {p.name: digest(p) for p in folder.glob("*")
                     if p.suffix.lower() in (".exe", ".dll", ".dlo", ".dlx", ".dlh")}}, indent=2) + "\n")


if __name__ == "__main__":
    main()
