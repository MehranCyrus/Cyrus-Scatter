"""Compile-only Max 2027 render-interface ABI witness using installed tooling."""
import argparse
import hashlib
import importlib.util
import json
import shutil
import subprocess
from pathlib import Path

SOURCE = '''#include <max.h>
#include <Graphics/ICustomRenderItem.h>
#include <Graphics/IVirtualDevice.h>
class CustomItemABIProbe : public MaxSDK::Graphics::ICustomRenderItem { public: ~CustomItemABIProbe() override = default; };
class VirtualDeviceABIProbe : public MaxSDK::Graphics::IVirtualDevice { public: ~VirtualDeviceABIProbe() override = default; };
int witness() { return sizeof(CustomItemABIProbe) + sizeof(VirtualDeviceABIProbe); }
'''


def main():
    p = argparse.ArgumentParser()
    p.add_argument("repo", type=Path)
    p.add_argument("output", type=Path)
    a = p.parse_args()
    a.output.mkdir(parents=True, exist_ok=False)
    source = a.output / "display_abi.cpp"
    source.write_text(SOURCE)
    spec = importlib.util.spec_from_file_location("build_max", a.repo / "tools/build_max.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    env = module.compiler_environment(Path("C:/Program Files/Microsoft Visual Studio/2022/Community"), "14.38.33130", "10.0.19041.0")
    sdk = a.repo / "build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk/include"
    compiler = shutil.which("cl.exe", path=env.get("PATH", env.get("Path", "")))
    results = []
    for name in ("CustomItemABIProbe", "VirtualDeviceABIProbe"):
        cmd = [compiler, "/nologo", "/c", "/std:c++17", "/EHsc", "/D_UNICODE", "/DUNICODE", "/DNOMINMAX",
               "/I" + str(sdk), "/Fo" + str(a.output / (name + ".obj")), "/d1reportSingleClassLayout" + name, str(source)]
        r = subprocess.run(cmd, cwd=a.output, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        log = a.output / (name + ".txt")
        log.write_text(r.stdout)
        results.append({"command": cmd, "exit_code": r.returncode, "log": log.name, "sha256": hashlib.sha256(log.read_bytes()).hexdigest()})
    receipt = {"linked": False, "executed": False, "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(), "results": results}
    (a.output / "receipt.json").write_text(json.dumps(receipt, indent=2))
    print(json.dumps(receipt))
    raise SystemExit(max(r["exit_code"] for r in results))


if __name__ == "__main__":
    main()
