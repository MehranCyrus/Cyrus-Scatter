"""Compile an SDK-only vtable witness; never links or executes a plugin.

Uses the repository's existing compiler setup and exact local Max 2027 headers.
The MSVC diagnostic is an implementation-specific ABI aid, not a portable API.
"""
import argparse
import hashlib
import importlib.util
import json
import shutil
import subprocess
from pathlib import Path

SOURCE = """#include <max.h>
#include <iparamb2.h>
#include <Graphics/IObjectDisplay2.h>
class PBAccessorABIProbe : public PBAccessor { public: ~PBAccessorABIProbe() override = default; };
class ParamBlockABIProbe : public IParamBlock2 { public: ~ParamBlockABIProbe() override = default; };
class GeomObjectABIProbe : public GeomObject { public: ~GeomObjectABIProbe() override = default; };
class CoreInterfaceABIProbe : public Interface { public: ~CoreInterfaceABIProbe() override = default; };
class NativeDisplayABIProbe : public MaxSDK::Graphics::IObjectDisplay2 { public: ~NativeDisplayABIProbe() override = default; };
class Interface15ABIProbe : public Interface15 { public: ~Interface15ABIProbe() override = default; };
int witness() { return sizeof(PBAccessorABIProbe) + sizeof(ParamBlockABIProbe) + sizeof(GeomObjectABIProbe) + sizeof(CoreInterfaceABIProbe) + sizeof(NativeDisplayABIProbe) + sizeof(Interface15ABIProbe); }
"""


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("repo", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    source = args.output / "sdk_layout.cpp"
    source.write_text(SOURCE, encoding="utf-8")
    spec = importlib.util.spec_from_file_location("build_max", args.repo / "tools/build_max.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    env = module.compiler_environment(
        Path("C:/Program Files/Microsoft Visual Studio/2022/Community"),
        "14.38.33130", "10.0.19041.0"
    )
    sdk = args.repo / "build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk/include"
    compiler = shutil.which("cl.exe", path=env.get("PATH", env.get("Path", "")))
    if not compiler:
        raise RuntimeError("Existing MSVC compiler was not found")
    # MSVC honors only the last single-class selector in one invocation.
    commands, outputs, exit_codes = [], [], []
    for name in ("PBAccessorABIProbe", "ParamBlockABIProbe", "GeomObjectABIProbe", "CoreInterfaceABIProbe", "NativeDisplayABIProbe", "Interface15ABIProbe"):
        command = [compiler, "/nologo", "/c", "/std:c++17", "/EHsc", "/D_UNICODE", "/DUNICODE",
                   "/DNOMINMAX", "/I" + str(sdk), "/Fo" + str(args.output / (name + ".obj")),
                   "/d1reportSingleClassLayout" + name, str(source)]
        result = subprocess.run(command, env=env, cwd=args.output, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        commands.append(command)
        outputs.append(result.stdout)
        exit_codes.append(result.returncode)
    exit_code = next((code for code in exit_codes if code), 0)
    log = args.output / "compile.txt"
    log.write_text("\n".join(outputs), encoding="utf-8")
    (args.output / "receipt.json").write_text(json.dumps(dict(
        commands=commands, exit_codes=exit_codes, exit_code=exit_code, executed=False, linked=False,
        source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
        log_sha256=hashlib.sha256(log.read_bytes()).hexdigest(),
        compiler="MSVC 14.38.33130", sdk="Max 2027 local headers",
    ), indent=2), encoding="utf-8")
    print(f"compile={exit_code}; full ABI witness: {log}")
    raise SystemExit(exit_code)


if __name__ == "__main__":
    main()
