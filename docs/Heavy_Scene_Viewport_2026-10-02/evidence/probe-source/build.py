"""Build only the disposable point probe; never package or install production files."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "tools"))
from build_max import compiler_environment


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--year", type=int, choices=[2026, 2027], default=2027)
    args = parser.parse_args()
    output = ROOT / "build/heavy-viewport-2026-10-02" / f"probe-{args.year}"
    output.mkdir(parents=True, exist_ok=True)
    sdk = ROOT / f"build/tooling/max{args.year}-sdk/Program Files/Autodesk/3ds Max {args.year} SDK/maxsdk"
    env = compiler_environment(Path("C:/Program Files/Microsoft Visual Studio/2022/Community"), "14.38.33130", "10.0.19041.0")
    commands = [
        ["cmake", "-S", str(Path(__file__).parent), "-B", str(output), "-G", "NMake Makefiles", "-DCMAKE_BUILD_TYPE=Release", f"-DCYRUS_MAX_YEAR={args.year}", f"-DMAXSDK_ROOT={sdk}"],
        ["cmake", "--build", str(output)],
    ]
    for index, command in enumerate(commands):
        result = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True)
        (output / f"build-{index}.log").write_text(result.stdout + result.stderr, encoding="utf-8")
        print(result.stdout + result.stderr)
        result.check_returncode()
    dll = output / "CyrusRetainedPointProbe.dlx"
    identity = {"path": str(dll), "sha256": hashlib.sha256(dll.read_bytes()).hexdigest(), "sdk": str(sdk), "commands": commands}
    (output / "identity.json").write_text(json.dumps(identity, indent=2), encoding="utf-8")
    print(json.dumps(identity, indent=2))


if __name__ == "__main__":
    main()
