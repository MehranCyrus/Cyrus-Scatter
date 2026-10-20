"""Run frozen fixtures in an owned Max 2027 batch process; no computer use or artist-session commands."""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import uuid

from build import ROOT, sha, source_hashes

INTERACTIVE_TESTS = frozenset({
    "arrange_workflow_tests.ms", "arrange_simple_workflow_tests.ms",
    "arrange_bulk_workflow_tests.ms", "arrange_modifier_workflow_tests.ms",
    "arrange_unified_modify_tests.ms", "arrange_fit_feedback_tests.ms",
    "arrange_status_undo_tests.ms", "arrange_road_scene_tests.ms",
    "arrange_device_imported_tests.ms", "arrange_packing_recovery_tests.ms",
    "arrange_legacy_minimum_workflow_tests.ms",
})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--binary-dir", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--test-script", default="tests/max/inspect_tests.ms")
    parser.add_argument("--timeout", type=int, default=360)
    parser.add_argument("--capture-full-crash-dump", action="store_true",
                        help="Request an extra full-heap post-fault Max dump in this owned child's private TEMP; does not enable first-chance debugging")
    args = parser.parse_args()
    ui_host = Path(args.test_script).name in INTERACTIVE_TESTS
    native = args.binary_dir.resolve()
    out = args.output.resolve()
    if not out.is_relative_to(ROOT / "build"):
        parser.error("Use a fresh output under CyrusArrange/build")
    if args.capture_full_crash_dump and shutil.disk_usage(ROOT / "build").free < 8 * 1024**3:
        parser.error("Full crash capture requires at least 8 GiB free before this owned launch")
    test = (ROOT / args.test_script).resolve()
    if not test.is_relative_to(ROOT / "tests") or test.suffix != ".ms" or not test.is_file():
        parser.error("Test script must be a .ms file under CyrusArrange/tests")
    build = json.loads((native / "receipt.json").read_text())
    if build.get("status") != "passed" or build.get("max_year") != 2027:
        raise SystemExit("A passed Max 2027 build receipt is required")
    if build["sources"] != source_hashes():
        raise SystemExit("Sources changed after build; rebuild the final pair first")
    for name in ("CyrusArrange.dlx", "CyrusArrangeStorage.dlh"):
        if build["binaries"].get(name) != sha(native / name):
            raise SystemExit("Native module changed after qualification: " + name)
    out.mkdir(parents=True, exist_ok=False)
    for name in ("bin", "startup", "scripts", "macros", "plugcfg", "temp", "autoback", "user", "bundle"):
        (out / name).mkdir()
    shutil.copy2(native / "CyrusArrange.dlx", out / "bin/CyrusArrange.dlx")
    shutil.copy2(native / "CyrusArrangeStorage.dlh", out / "bin/CyrusArrangeStorage.dlh")
    for folder in ("scripts", "tests", "installer"):
        if (ROOT / folder).exists():
            shutil.copytree(ROOT / folder, out / "bundle" / folder)
    artist = Path(os.environ["LOCALAPPDATA"]) / "Autodesk/3dsMax/2027 - 64bit/ENU"
    preserved = [p for p in (artist / "3dsMax.ini", artist / "Plugin.UserSettings.ini") if p.is_file()]
    before = {str(p): sha(p) for p in preserved}
    config = (artist / "3dsMax.ini").read_text(encoding="utf-16")
    config = config.replace(str(artist), str(out / "user"))
    for key, folder in {"Additional Scripts": "scripts", "Additional Macros": "macros", "Additional Startup Scripts": "startup", "PlugCFG": "plugcfg", "Temp": "temp", "Page File": "temp", "AutoBackup": "autoback"}.items():
        config, found = re.subn(rf"(?m)^{re.escape(key)}=.*$", lambda _: key + "=" + str(out / folder), config)
        if found != 1:
            raise SystemExit("Unrecognized profile key: " + key)
    (out / "private.ini").write_text(config, encoding="utf-16")
    maxdir = Path("C:/Program Files/Autodesk/3ds Max 2027")
    (out / "plugins.ini").write_text("[Directories]\nAdditional MAX plug-ins=" + str(maxdir / "PlugIns") + "\nCyrusArrange=" + str(out / "bin") + "\n[Help]\n")
    entry = out / "entry.ms"
    run_token = uuid.uuid4().hex
    entry.write_text(
        f'global CA_TEST_ROOT=@"{(out / "bundle").as_posix()}/"\n'
        f'global CA_TEST_OUTPUT=@"{out.as_posix()}/"\n'
        'global CA_AUTO_SHOW_UI=false\n'
        'global CA_RUN_OWNED=false\n'
        'try (\n'
        f'  if ((dotNetClass "System.Environment").GetEnvironmentVariable "CYRUS_ARRANGE_OWNED_RUN") != "{run_token}" do throw "Owned-process token mismatch; fixture was not run."\n'
        f'  if toLower(getMAXIniFile()) != toLower(@"{str(out / "private.ini")}") do throw "Private INI mismatch; fixture was not run."\n'
        '  CA_RUN_OWNED=true\n'
        f'  if toLower((caModulePaths())[1]) != toLower(@"{str(out / "bin/CyrusArrange.dlx")}") or toLower((caModulePaths())[2]) != toLower(@"{str(out / "bin/CyrusArrangeStorage.dlh")}") do throw "Private native pair mismatch; fixture was not run."\n'
        f'  fileIn @"{(out / "bundle" / test.relative_to(ROOT)).as_posix()}"\n'
        '  local identity=createFile (CA_TEST_OUTPUT+"loaded-native.txt")\n'
        '  format "%\\n" (caDiagnostics())[1] to:identity\n'
        '  format "%\\n" (maxVersion()) to:identity\n'
        '  format "%\\n" (getMAXIniFile()) to:identity\n'
        '  format "%\\n" (caModulePaths())[2] to:identity\n'
        '  close identity\n'
        ') catch (\n'
        '  local err=createFile (CA_TEST_OUTPUT+"result.txt")\n'
        '  format "ERROR %\\n" (getCurrentException()) to:err\n'
        '  close err\n'
        ')\n' + ('if CA_RUN_OWNED do quitMAX #noPrompt\n' if ui_host else ''), encoding="utf-8")
    result_path = out / "result.txt"
    result_path.write_text("PENDING\n")
    command = ([str(maxdir / "3dsmax.exe"), "-q", "-i", str(out / "private.ini"), "-p", str(out / "plugins.ini"), "-U", "MAXScript", str(entry)] if ui_host else
               [str(maxdir / "3dsmaxbatch.exe"), str(entry), "-i", str(out / "private.ini"), "-p", str(out / "plugins.ini")])
    command += ["-listenerlog", str(out / "listener.log"), "-log", str(out / "session.log")]
    environment = os.environ.copy()
    environment["CYRUS_ARRANGE_OWNED_RUN"] = run_token
    # Early startup faults occur before the private INI's Temp path is active.
    # Scope both temporary files and optional crash capture to this child only.
    environment.update(TEMP=str(out / "temp"), TMP=str(out / "temp"))
    if args.capture_full_crash_dump:
        environment["AMED_MAX_BIGMINIDUMP"] = "full"
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    receipt = {"status": "pending", "utc": datetime.now(timezone.utc).isoformat(), "build_receipt": str(native / "receipt.json"), "test_script": test.relative_to(ROOT).as_posix(), "test_sha256": sha(test), "native_sha256": sha(out / "bin/CyrusArrange.dlx"), "storage_sha256": sha(out / "bin/CyrusArrangeStorage.dlh"), "sources": build["sources"], "computer_use": False, "installed": False, "artist_scene_opened": False, "host_mode": "owned-interactive-command-panel" if ui_host else "owned-batch"}
    receipt_path = out / "receipt.json"
    receipt["crash_capture"] = {"full_heap_requested": args.capture_full_crash_dump,
                                "extra_dump_environment": environment.get("AMED_MAX_BIGMINIDUMP"),
                                "private_temp": str(out / "temp"),
                                "scope": "child-only post-fault handler capture request; no first-chance or successful-capture claim"}
    with (out / "stdout.log").open("wb") as stdout, (out / "stderr.log").open("wb") as stderr:
        process = subprocess.Popen(command, cwd=out, env=environment, stdout=stdout, stderr=stderr, startupinfo=startup)
        receipt.update(pid=process.pid, command=command)
        receipt_path.write_text(json.dumps(receipt, indent=2))
        print(f"Owned Max batch PID {process.pid}: {out}", flush=True)
        try:
            exit_code = process.wait(timeout=args.timeout)
        except subprocess.TimeoutExpired:
            receipt.update(status="timeout-observe-owned-process", artist_profiles_unchanged=all(sha(Path(p)) == v for p, v in before.items()))
            receipt_path.write_text(json.dumps(receipt, indent=2))
            raise SystemExit("Observation timeout. Do not duplicate commands; inspect the recorded owned PID and output before continuing.")
    result = result_path.read_text(encoding="utf-8-sig")
    loaded = (out / "loaded-native.txt").read_text(encoding="utf-8-sig").splitlines() if (out / "loaded-native.txt").exists() else []
    matches = bool(loaded) and Path(loaded[0]).resolve() == (out / "bin/CyrusArrange.dlx").resolve()
    unchanged = all(sha(Path(p)) == v for p, v in before.items())
    private_ini = len(loaded) >= 3 and Path(loaded[2]).resolve() == (out / "private.ini").resolve()
    storage_matches = len(loaded) >= 4 and Path(loaded[3]).resolve() == (out / "bin/CyrusArrangeStorage.dlh").resolve()
    binaries_unchanged = all(sha(out / "bin" / name) == build["binaries"][name] for name in ("CyrusArrange.dlx", "CyrusArrangeStorage.dlh"))
    passed = exit_code == 0 and result.startswith("SUCCESS") and matches and storage_matches and binaries_unchanged and unchanged and private_ini
    receipt.update(status="passed" if passed else "failed", exit_code=exit_code, report=result, loaded_native=loaded, loaded_path_matches=matches, loaded_storage_path_matches=storage_matches, binaries_unchanged=binaries_unchanged, private_ini_matches=private_ini, artist_profiles_unchanged=unchanged, preserved_profile_hashes=before)
    receipt_path.write_text(json.dumps(receipt, indent=2) + "\n")
    print(result, flush=True)
    print(f"Loaded modules match: main={matches}, storage={storage_matches}; binary hashes unchanged: {binaries_unchanged}; private INI: {private_ini}; artist profiles unchanged: {unchanged}", flush=True)
    if not passed:
        sys.exit(1)


if __name__ == "__main__":
    main()
