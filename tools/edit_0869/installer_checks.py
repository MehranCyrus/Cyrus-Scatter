"""Exercise the exact three-host EXE against fresh disposable profiles only."""
from pathlib import Path
import argparse
import json
import os
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
import build_inputs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exe", type=Path, required=True)
    parser.add_argument("--library-state", type=Path, required=True, help="Read-only existing content registration; copied into owned profiles")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    executable, output, state = args.exe.resolve(), args.output.resolve(), args.library_state.resolve()
    if not output.is_relative_to(ROOT / "build") or len(str(output)) > 88:
        raise ValueError("Use a fresh owned build directory no longer than 88 characters")
    receipt = build_inputs.verify_managed(executable, "installer-exe", ROOT)
    if receipt.get("version") != "0.86.9" or receipt.get("max_years") != [2024, 2026, 2027]:
        raise ValueError("This fixture requires the exact three-host 0.86.9 delivery")
    if sorted((p["year"], p["version"]) for p in receipt["analyzer_packages"]) != [(str(y), "0.14.2") for y in (2024, 2026, 2027)]:
        raise ValueError("The exact three Analyzer 0.14.2 packages are required")
    if not state.is_file() or state.stat().st_size > 16384:
        raise ValueError("A bounded existing library registration is required")
    output.mkdir(parents=True, exist_ok=False)
    evidence = {"schema": "cyrus.edit-installer-checks/1", "status": "pending", "version": "0.86.9",
                "max_years": [2024, 2026, 2027], "exe": str(executable), "exe_sha256": build_inputs.digest(executable),
                "exe_receipt_sha256": build_inputs.digest(executable.with_suffix(".build.json")),
                "library_state": str(state), "library_state_sha256": build_inputs.digest(state),
                "artist_install": False, "host_launched": False}
    destination = output / "receipt.json"
    destination.write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    source = Path(__file__).with_suffix(".cs")
    compiler = Path("C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe")
    framework = Path("C:/Windows/Microsoft.NET/Framework64/v4.0.30319")
    references = [framework / name for name in ("mscorlib.dll", "System.dll", "System.Core.dll", "System.Drawing.dll", "System.Windows.Forms.dll", "System.IO.Compression.dll")]
    probe = output / "Installer0869Checks.exe"
    compile_command = [str(compiler), "/nologo", "/noconfig", "/nostdlib+", "/langversion:latest", "/warnaserror+",
                       "/target:exe", "/platform:x64", "/out:" + str(probe),
                       *("/reference:" + str(path) for path in references), str(source)]
    inputs = build_inputs.snapshot([source, Path(__file__), compiler, *references, executable, executable.with_suffix(".build.json"), state], ROOT)
    try:
        compiled = subprocess.run(compile_command, capture_output=True, text=True, check=False)
        (output / "compile.log").write_text(compiled.stdout + compiled.stderr, encoding="utf-8")
        if compiled.returncode:
            raise RuntimeError("Installer fixture compilation failed; inspect compile.log")
        temporary = output / "temp"
        temporary.mkdir()
        command = [str(probe), str(executable), evidence["exe_sha256"], str(output / "profiles"), str(state)]
        environment = dict(os.environ, TEMP=str(temporary), TMP=str(temporary))
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = 0
        result = subprocess.run(command, cwd=output, env=environment, capture_output=True, text=True,
                                timeout=300, startupinfo=startup)
        (output / "handler.log").write_text(result.stdout + result.stderr, encoding="utf-8")
        counts = re.findall(r"^CHECKS (\d+)$", result.stdout, re.MULTILINE)
        if result.returncode or counts != ["53"]:
            raise RuntimeError("Exact EXE handler assertions failed or incomplete; inspect handler.log")
        if build_inputs.snapshot([ROOT / p for p in inputs], ROOT) != inputs:
            raise RuntimeError("Fixture, library input or EXE changed during the scenario")
        build_inputs.verify_managed(executable, "installer-exe", ROOT)
        installed = {}
        for year in (2024, 2026, 2027):
            folder = output / "profiles/installed" / str(year)
            fields = (folder / "installed-runtime.tsv").read_text(encoding="utf-8-sig").strip().split("\t")
            if len(fields) != 3 or fields[0] != str(year):
                raise ValueError("Missing installed runtime witness")
            installed[str(year)] = {"profile": str(folder), "scatter_runtime": fields[1], "analyzer_runtime": fields[2],
                                    "scatter_package": next(p for p in receipt["packages"] if p["year"] == str(year)),
                                    "analyzer_package": next(p for p in receipt["analyzer_packages"] if p["year"] == str(year))}
        evidence.update(status="pass", checks=53, installed=installed, command=command, compile_command=compile_command,
                        fixture_inputs=inputs, compiled_fixture_sha256=build_inputs.digest(probe),
                        assertions=[line[5:] for line in result.stdout.splitlines() if line.startswith("PASS ")],
                        scope="Actual Primary.PerformClick with all three host cards selected; exact embedded native/script/Gallery bytes; repeat and custom-registration preflight; copied library registration; no Max process controlled")
    except Exception as error:
        evidence.update(status="fail", error=str(error), fixture_inputs=inputs)
        raise
    finally:
        destination.write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(evidence, indent=2), flush=True)


if __name__ == "__main__":
    main()
