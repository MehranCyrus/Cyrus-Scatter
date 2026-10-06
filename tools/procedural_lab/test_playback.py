"""Run a headless, disposable Max 2027 regression; no computer-use/UI automation.

Copies the exact built DLLs and generated script into a unique ignored lab. It
never opens an artist scene, installs into a profile, or commands an existing Max.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
BINARIES = ("AminScatter.dlx", "CyrusBrush.dlx", "CyrusBrushStorage.dlh", "CyrusScatterEdit.dlm")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary-dir", type=Path, required=True)
    parser.add_argument("--analyzer-dir", type=Path, help="Matching private Surface Analyzer build")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--max-dir", type=Path, default=Path("C:/Program Files/Autodesk/3ds Max 2027"))
    parser.add_argument("--probe", type=Path, help="Optional private diagnostic DLX")
    args = parser.parse_args()
    binary_dir = args.binary_dir.resolve()
    out = args.output.resolve()
    lab_root = (ROOT / "build/playback-20261006").resolve()
    if not out.is_relative_to(lab_root):
        raise SystemExit("Output must be inside build/playback-20261006")
    out.mkdir(parents=True, exist_ok=False)
    for name in ("bin", "startup", "scripts", "plugcfg", "temp", "autoback"):
        (out / name).mkdir()
    receipt = json.loads((binary_dir / "receipt.json").read_text())
    if receipt.get("status") == "pending" or receipt["max_year"] != 2027 or any(s["exit_code"] for s in receipt["stages"]):
        raise SystemExit("A passing Max 2027 build receipt is required")
    for name, digest in receipt["sources"].items():
        if sha(ROOT / name) != digest:
            raise SystemExit(f"Native build source changed; rebuild first: {name}")
    identities = {}
    for name in BINARIES:
        src = binary_dir / name
        key = src.relative_to(ROOT).as_posix()
        if receipt["binaries"].get(key) != sha(src):
            raise SystemExit(f"Build receipt differs: {name}")
        shutil.copy2(src, out / "bin" / name)
        identities[name] = sha(out / "bin" / name)
    script = ROOT / "AminScatter/scripts/AminScatterObject.ms"
    if receipt["sources"][script.relative_to(ROOT).as_posix()] != sha(script):
        raise SystemExit("Generated script differs from the SDK build receipt; rebuild first")
    shutil.copy2(script, out / script.name)
    shutil.copy2(ROOT / "tools/procedural_lab/Max_Playback_Regression.ms", out / "fixture.ms")
    identities[script.name] = sha(out / script.name)
    identities["fixture.ms"] = sha(out / "fixture.ms")
    native_names = list(BINARIES)
    analyzer_script = None
    if args.analyzer_dir:
        analyzer_dir = args.analyzer_dir.resolve()
        analyzer_receipt = json.loads((analyzer_dir / "receipt.json").read_text())
        if (analyzer_receipt.get("status") == "pending" or analyzer_receipt.get("project") != "analyzer" or
                analyzer_receipt["max_year"] != 2027 or any(s["exit_code"] for s in analyzer_receipt["stages"])):
            raise SystemExit("A passing Analyzer Max 2027 build receipt is required")
        for name, digest in analyzer_receipt["sources"].items():
            if sha(ROOT / name) != digest:
                raise SystemExit(f"Analyzer source changed; rebuild first: {name}")
        name = "CyrusSurfaceAnalyzer.dlx"
        src = analyzer_dir / name
        if analyzer_receipt["binaries"].get(src.relative_to(ROOT).as_posix()) != sha(src):
            raise SystemExit("Analyzer DLL differs from its build receipt")
        shutil.copy2(src, out / "bin" / name)
        native_names.append(name)
        identities[name] = sha(out / "bin" / name)
        analyzer_script = out / "CyrusSurfaceAnalyzer.ms"
        shutil.copy2(ROOT / "CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms", analyzer_script)
        identities[analyzer_script.name] = sha(analyzer_script)
        shutil.copy2(ROOT / "tools/procedural_lab/Max_Analyzer_Playback_Regression.ms", out / "analyzer-fixture.ms")
        identities["analyzer-fixture.ms"] = sha(out / "analyzer-fixture.ms")
    if args.probe:
        shutil.copy2(args.probe, out / "bin" / args.probe.name)
        identities[args.probe.name] = sha(out / "bin" / args.probe.name)
    # Read-only configuration seed. All profile paths point at the private lab.
    artist = Path(os.environ["LOCALAPPDATA"]) / "Autodesk/3dsMax/2027 - 64bit/ENU"
    profile = artist / "3dsMax.ini"
    profile_before = sha(profile)
    config = profile.read_text(encoding="utf-16")
    config = config.replace(str(artist), str(out / "user"))
    for key, dest in {"Additional Startup Scripts": "startup", "Scripts": "scripts", "PlugCFG": "plugcfg",
                      "Temp": "temp", "Page File": "temp", "AutoBackup": "autoback"}.items():
        config, found = re.subn(rf"(?m)^{re.escape(key)}=.*$", lambda _: key + "=" + str(out / dest), config)
        if key != "Scripts" and found != 1:
            raise SystemExit(f"Expected one configuration key: {key}")
    (out / "private.ini").write_text(config, encoding="utf-16")
    (out / "plugins.ini").write_text("[Directories]\nAdditional MAX plug-ins=" + str(args.max_dir / "PlugIns") +
                                      "\nCyrusPlayback=" + str(out / "bin") + "\n[Help]\n")
    entry = out / "entry.ms"
    analyzer_entry = f'fileIn @"{analyzer_script.as_posix()}"\n' if analyzer_script else ""
    names_entry = ",".join(f'"{name}"' for name in native_names)
    entry.write_text(f'global PTRunDir=@"{out.as_posix()}/",PTDir=@"{out.as_posix()}/",PTNativeExpected=#({names_entry})\n'
                     f'fileIn @"{(out / script.name).as_posix()}"\n' + analyzer_entry +
                     f'fileIn @"{(out / "fixture.ms").as_posix()}"\n', encoding="utf-8")
    report = out / "result.txt"
    report.write_text("PENDING\n")
    command = [str(args.max_dir / "3dsmaxbatch.exe"), str(entry), "-i", str(out / "private.ini"),
               "-p", str(out / "plugins.ini"), "-listenerlog", str(out / "listener.log"), "-log", str(out / "session.log")]
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    with (out / "stdout.log").open("wb") as stdout, (out / "stderr.log").open("wb") as stderr:
        run = subprocess.run(command, cwd=out, stdout=stdout, stderr=stderr, startupinfo=startup, timeout=300)
    result = report.read_text(encoding="utf-8-sig")
    match = re.search(r"SCRIPT_PAYLOAD ([0-9a-f]{64})", result)
    expected = re.search(r'CyrusLoadedScriptFingerprint="([0-9a-f]{64})"', (out / script.name).read_text()).group(1)
    observed = {}
    loaded = out / "loaded-native.txt"
    if loaded.is_file():
        for line in loaded.read_text(encoding="utf-8-sig").splitlines():
            name, path, digest = line.split("|")
            if name in observed:
                raise SystemExit(f"Duplicate loaded native binary: {name}")
            observed[name] = {"path": path, "sha256": digest}
    native_match = set(observed) == set(native_names) and all(
        observed[name]["sha256"] == identities[name] and Path(observed[name]["path"]).resolve() == (out / "bin" / name).resolve()
        for name in native_names)
    passed = run.returncode == 0 and "SUCCESS " in result and native_match and match is not None and match.group(1) == expected
    evidence = {"recorded_at_utc": datetime.now(timezone.utc).isoformat(), "exit_code": run.returncode,
                "passed": passed, "headless_max2027": True, "computer_use": False, "artist_scene_opened": False,
                "installed": False, "artist_profile_unchanged": sha(profile) == profile_before,
                "sources_and_binaries": identities, "payload_expected": expected,
                "loaded_native": observed, "loaded_native_matches": native_match,
                "payload_observed": match.group(1) if match else None, "report": result,
                "limitations": ["No presented FPS, interactive UI, real playback timing, or Corona IR qualification."]}
    (out / "receipt.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    print(result)
    if not passed or not evidence["artist_profile_unchanged"]:
        raise SystemExit(f"Playback regression failed; inspect {out}")


if __name__ == "__main__":
    main()
