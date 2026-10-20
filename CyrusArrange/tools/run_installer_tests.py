"""Qualify an unchanged MZP in two new private Max 2027 processes; never install into an artist profile."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import zipfile
import uuid

from build import ROOT, sha, source_hashes
from package import INSTALLED_MODULES, MODULES, VERSION, now, require, validate_candidate


TESTS = {"install": "tests/max/installer_tests.ms", "startup": "tests/max/installed_startup_tests.ms"}


def write_receipt(path, receipt):
    path.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8")


def profile_snapshot(artist):
    """Read only the artist config and this product's existing owned files, including absence."""
    watched = {artist / "3dsMax.ini", artist / "Plugin.UserSettings.ini"}
    roots = set()
    ini = artist / "3dsMax.ini"
    if ini.is_file():
        config = ini.read_text(encoding="utf-16")
        for key, child in (("Additional Scripts", "CyrusArrange"), ("Additional Startup Scripts", "CyrusArrangeStartup.ms"), ("Additional Macros", "CyrusArrange.mcr")):
            match = re.search(rf"(?m)^{re.escape(key)}=(.*)$", config)
            if match:
                target = Path(match.group(1).strip()) / child
                watched.add(target)
                if child == "CyrusArrange":
                    roots.add(target)
    for root in roots:
        if root.is_dir():
            watched.update(p for p in root.rglob("*") if p.is_file())
    return {str(p): sha(p) if p.is_file() else "directory" if p.is_dir() else None for p in sorted(watched)}


def make_private_profile(artist, profile, maxdir):
    folders = ("scripts", "startup", "macros", "plugcfg", "temp", "autoback", "user")
    for name in folders:
        (profile / name).mkdir(parents=True)
    config = (artist / "3dsMax.ini").read_text(encoding="utf-16")
    config = config.replace(str(artist), str(profile / "user"))
    for key, folder in {"Additional Scripts": "scripts", "Additional Macros": "macros", "Additional Startup Scripts": "startup", "PlugCFG": "plugcfg", "Temp": "temp", "Page File": "temp", "AutoBackup": "autoback"}.items():
        config, count = re.subn(rf"(?m)^{re.escape(key)}=.*$", lambda _: key + "=" + str(profile / folder), config)
        require(count == 1, "Unrecognized private profile key: " + key)
    (profile / "private.ini").write_text(config, encoding="utf-16")
    (profile / "plugins-bootstrap.ini").write_text("[Directories]\nAdditional MAX plug-ins=" + str(maxdir / "PlugIns") + "\n[Help]\n", encoding="utf-8")


def mxs_string(value):
    # Verbatim MAXScript string quoting. Do not use JSON's backslash escapes for paths.
    return '@"' + str(value).replace('"', '""') + '"'


def hash_rows(files):
    return "#(" + ",".join("#(" + mxs_string(name) + "," + mxs_string(value) + ")" for name, value in sorted(files.items())) + ")"


def run_phase(name, out, profile, plugins, candidate, source, globals_text, timeout, receipt, receipt_path, environment, maxdir):
    phase = out / name
    phase.mkdir()
    entry = phase / "entry.ms"
    ui_host = name == "startup"
    run_token = uuid.uuid4().hex
    entry.write_text(
        "global CA_TEST_OUTPUT=" + mxs_string(phase.as_posix() + "/") + "\n"
        "global CA_INSTALL_QA_ROOT=" + mxs_string(profile.as_posix() + "/") + "\n" + globals_text +
        "global CA_INSTALL_RUN_OWNED=false\n"
        "try (\n"
        '  if ((dotNetClass "System.Environment").GetEnvironmentVariable "CYRUS_ARRANGE_INSTALL_RUN") != ' + mxs_string(run_token) + ' do throw "Owned installer-process token mismatch."\n'
        '  if toLower(getMAXIniFile()) != toLower(' + mxs_string(str(profile / "private.ini")) + ') do throw "Private installer INI mismatch."\n'
        "  CA_INSTALL_RUN_OWNED=true\n"
        "  fileIn " + mxs_string(source.as_posix()) + ") catch (\n"
        "  local output=createFile (CA_TEST_OUTPUT+\"result.txt\")\n"
        "  format \"ERROR entry exception %\\n\" (getCurrentException()) to:output\n"
        "  close output\n)\n" + ("if CA_INSTALL_RUN_OWNED do quitMAX #noPrompt\n" if ui_host else ""), encoding="utf-8")
    result = phase / "result.txt"
    result.write_text("PENDING\n", encoding="utf-8")
    command = ([str(maxdir / "3dsmax.exe"), "-q", "-i", str(profile / "private.ini"), "-p", str(plugins), "-U", "MAXScript", str(entry)] if ui_host else
               [str(maxdir / "3dsmaxbatch.exe"), str(entry), "-i", str(profile / "private.ini"), "-p", str(plugins)])
    command += ["-listenerlog", str(phase / "listener.log"), "-log", str(phase / "session.log")]
    phase_environment = environment.copy()
    phase_environment["CYRUS_ARRANGE_INSTALL_RUN"] = run_token
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    item = {"status": "pending", "test_script": TESTS[name], "test_sha256": sha(source), "command": command, "entry_sha256": sha(entry), "utc": now(), "host_mode": "owned-interactive-command-panel" if ui_host else "owned-batch"}
    receipt["phases"][name] = item
    write_receipt(receipt_path, receipt)
    with (phase / "stdout.log").open("wb") as stdout, (phase / "stderr.log").open("wb") as stderr:
        process = subprocess.Popen(command, cwd=phase, env=phase_environment, stdout=stdout, stderr=stderr, startupinfo=startup)
        item["pid"] = process.pid
        write_receipt(receipt_path, receipt)
        print("Owned private installer " + name + " PID " + str(process.pid) + ": " + str(phase), flush=True)
        try:
            code = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            item["status"] = "timeout-observe-owned-process"
            receipt["status"] = "timeout-observe-owned-process"
            write_receipt(receipt_path, receipt)
            raise RuntimeError("Observation timeout. Inspect recorded owned PID before continuing; do not duplicate the process.")
    report = result.read_text(encoding="utf-8-sig")
    marker = "INSTALLER_DESTINATIONS_PRIVATE" if name == "install" else "INSTALLED_STARTUP_PRIVATE_PROFILE"
    passed = code == 0 and report.startswith("SUCCESS") and marker in report
    item.update(status="passed" if passed else "failed", exit_code=code, report=report, result_sha256=sha(result), private_profile_marker=marker in report)
    write_receipt(receipt_path, receipt)
    print(report, flush=True)
    require(passed, "Private " + name + " host failed; inspect " + str(result))
    return phase


def qualify(candidate_folder, out, timeout):
    candidate = validate_candidate(candidate_folder)
    require(out.is_relative_to(ROOT / "build") and out != ROOT / "build", "Use a fresh output folder under CyrusArrange/build")
    require(timeout > 0, "Timeout must be positive")
    out.mkdir(parents=True, exist_ok=False)
    profile = out / "profile"
    maxdir = Path("C:/Program Files/Autodesk/3ds Max 2027")
    require((maxdir / "3dsmaxbatch.exe").is_file(), "Max 2027 batch executable is unavailable")
    artist = Path(os.environ["LOCALAPPDATA"]) / "Autodesk/3dsMax/2027 - 64bit/ENU"
    before = profile_snapshot(artist)
    receipt = {"status": "pending", "version": VERSION, "utc": now(), "archive": candidate["archive"], "archive_sha256": candidate["archive_sha256"], "sources": candidate["sources"], "candidate_receipt": {"path": str(candidate_folder / "package-receipt.json"), "sha256": sha(candidate_folder / "package-receipt.json")}, "computer_use": False, "artist_installation_executed": False, "phases": {}, "preserved_artist_hashes": before}
    receipt_path = out / "receipt.json"
    write_receipt(receipt_path, receipt)
    try:
        make_private_profile(artist, profile, maxdir)
        bundle = out / "bundle"
        bundle.mkdir()
        scripts = {}
        for name, relative in TESTS.items():
            source = ROOT / relative
            require(sha(source) == candidate["sources"].get(relative), "Installer test source differs from candidate: " + relative)
            scripts[name] = bundle / source.name
            shutil.copy2(source, scripts[name])
        archive = Path(candidate["archive"])
        tampered = out / "tampered-payload.mzp"
        with zipfile.ZipFile(archive) as original, zipfile.ZipFile(tampered, "w", zipfile.ZIP_DEFLATED) as changed:
            for item in original.infolist():
                data = original.read(item.filename)
                if item.filename == "ArrangeRegions.ms":
                    data += b"\n-- owned QA tampered payload\n"
                changed.writestr(item, data)
        environment = os.environ.copy()
        environment.update(TEMP=str(profile / "temp"), TMP=str(profile / "temp"))
        install_globals = "global CA_INSTALL_ARCHIVE=" + mxs_string(archive.as_posix()) + "\n" + "global CA_INSTALL_BAD_ARCHIVE=" + mxs_string(tampered.as_posix()) + "\n" + "global CA_INSTALL_FILES=" + hash_rows(candidate["installed_files"]) + "\n"
        installed_phase = run_phase("install", out, profile, profile / "plugins-bootstrap.ini", candidate, scripts["install"], install_globals, timeout, receipt, receipt_path, environment, maxdir)
        destination = Path((installed_phase / "installed-dir.txt").read_text(encoding="utf-8-sig").strip()).resolve()
        require(destination.is_relative_to((profile / "scripts/CyrusArrange").resolve()), "Installer returned a destination outside the private product directory")
        require(all(sha(destination / name) == value for name, value in candidate["installed_files"].items()), "Installed payload differs from the unchanged candidate")
        receipt.update(actual_mzp_executed=True, installed_payload_verified=True, installed_directory=str(destination))
        write_receipt(receipt_path, receipt)
        # No fileIn of startup or macro here: a new host must discover the actual installed configuration itself.
        startup_globals = "global CA_INSTALL_EXPECTED_DIR=" + mxs_string(destination.as_posix() + "/") + "\n"
        startup_phase = run_phase("startup", out, profile, profile / "Plugin.UserSettings.ini", candidate, scripts["startup"], startup_globals, timeout, receipt, receipt_path, environment, maxdir)
        loaded = (startup_phase / "loaded-native.txt").read_text(encoding="utf-8-sig").splitlines()
        module_paths_match = len(loaded) == 3 and all(Path(loaded[i]).resolve() == destination / INSTALLED_MODULES[name] for i, name in enumerate(MODULES))
        private_ini = len(loaded) == 3 and Path(loaded[2]).resolve() == (profile / "private.ini").resolve()
        require(module_paths_match and private_ini, "Installed startup loaded the wrong native pair or INI")
        require(all(sha(destination / name) == value for name, value in candidate["installed_files"].items()), "Installed payload changed during startup verification")
        require(sha(archive) == candidate["archive_sha256"] and source_hashes() == candidate["sources"], "Archive or source changed during installer qualification")
        require(profile_snapshot(artist) == before, "Artist product/profile files changed during private qualification")
        receipt.update(status="passed", installed_startup_passed=True, private_profiles_verified=True, artist_profiles_unchanged=True, loaded_native=loaded, loaded_path_matches=module_paths_match, private_ini_matches=private_ini, installed_modules={name: sha(destination / INSTALLED_MODULES[name]) for name in MODULES}, archive_unchanged=True)
        write_receipt(receipt_path, receipt)
        return receipt
    except Exception as error:
        if receipt["status"] != "timeout-observe-owned-process":
            receipt["status"] = "failed"
        receipt.update(error=str(error), artist_profiles_unchanged=profile_snapshot(artist) == before)
        write_receipt(receipt_path, receipt)
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--timeout", type=int, default=360)
    args = parser.parse_args()
    try:
        result = qualify(args.candidate.resolve(), args.output.resolve(), args.timeout)
    except (OSError, ValueError, RuntimeError, KeyError, zipfile.BadZipFile) as error:
        parser.exit(1, str(error) + "\n")
    print(json.dumps({k: result[k] for k in ("status", "archive_sha256", "installed_directory")}, indent=2))


if __name__ == "__main__":
    main()
