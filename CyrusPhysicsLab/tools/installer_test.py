"""Install and restart ONLY an owned hidden Max 2027 profile; no artist changes."""
from pathlib import Path
import argparse
import json
import os
import subprocess
import sys
import zipfile
from host_test import ROOT, PROJECT, digest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", required=True, type=Path)
    parser.add_argument("--package", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--fixture", type=Path, default=PROJECT / "tests/host_continuous.ms")
    parser.add_argument("--timeout", type=int, default=240, help="Bound for each owned host, including cold startup and exit")
    args = parser.parse_args()
    folder = args.output.resolve()
    if folder.parent != ROOT / "build" or not folder.name.startswith("physics-lab") or folder.exists():
        parser.error("Choose a fresh build/physics-lab... profile")
    qa = folder.with_name(folder.name + "-payload")
    qa.mkdir(exist_ok=False)
    with zipfile.ZipFile(args.package) as archive:
        assert archive.testzip() is None
        manifest = json.loads(archive.read("manifest.json"))
        assert manifest["version"] == "0.2.1" and manifest["max_year"] == 2027
        for name, expected in manifest["payload"].items():
            destination = (qa / name).resolve()
            assert destination.is_relative_to(qa)
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(archive.read(name))
            assert digest(destination) == expected, name
    fixture = qa / "installer-test.ms"
    fixture.write_text('''global CPLInstallIndependentLab
global CPLInstallerValidateOnly=true
(
 fn owned path =
 (
  local actual=substituteString (toLower path) "/" "\\\\"
  local expected=substituteString (toLower CPLTestDir) "/" "\\\\"
  if findString actual expected!=1 do throw ("Installer escaped owned profile: "+path)
 )
 owned (getDir #userScripts)
 owned (getDir #userStartupScripts)
 owned (getFilenamePath (getMAXIniFile()))
 fileIn @"__INSTALL__"
 CPLInstallIndependentLab quiet:true
 local ini=pathConfig.appendPath (getFilenamePath (getMAXIniFile())) "Plugin.UserSettings.ini"
 local registered=getINISetting ini "Directories" "CyrusPhysicsLab"
 owned registered
 if not doesFileExist (pathConfig.appendPath registered "CyrusPhysicsLab.dlx") do throw "Installed native module missing."
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"installed-path.txt") registered
)
'''.replace("__INSTALL__", (qa / "install.ms").as_posix()), encoding="utf-8-sig")
    subprocess.run([sys.executable, str(PROJECT / "tools/host_test.py"), "--build", str(args.build),
                    "--output", str(folder), "--fixture", str(fixture), "--timeout", str(args.timeout)], check=True)
    installed = Path((folder / "installed-path.txt").read_text()).resolve()
    assert installed.is_relative_to(folder / "scripts/CyrusPhysicsLab/0.2.1")
    for name in ("CyrusPhysicsLab.dlx", "CyrusPhysicsStorage.dlh"):
        assert digest(installed / name) == manifest["payload"]["native/" + name]
    plugins = folder / "restart-plugins.ini"
    plugins.write_text("[Directories]\nStandard=C:/Program Files/Autodesk/3ds Max 2027/stdplugs\nPhysicsLab=" + str(installed) + "\n[Help]\n")
    # No fileIn of the product script: the staged startup must register the class.
    bootstrap = '''global CPLTestDir=@"__FOLDER__/"
fn cplStage name = ((dotNetClass "System.IO.File").AppendAllText (CPLTestDir+"restart-stages.txt") (name+"\\n"))
fn cplResetScene = (setSilentMode true;setQuietMode true;try(resetMaxFile #noPrompt)catch(setSilentMode false;setQuietMode false;throw());setSilentMode false;setQuietMode false)
setSilentMode false
setQuietMode false
try (
 if CyrusPhysicsLab==undefined do throw "Automatic startup did not register the lab."
 cplStage "automatic startup registered"
 local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
 local log=createFile (CPLTestDir+"restart-loaded.tsv")
 for i=0 to process.Modules.Count-1 do (local item=process.Modules.Item[i];if matchPattern item.ModuleName pattern:"CyrusPhysics*" do format "%\\t%\\n" item.ModuleName item.FileName to:log)
 close log
 fileIn @"__FIXTURE__"
 (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"restart-completed.json") "{}"
)catch((dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"restart-error.txt") (getCurrentException()+"\\n"+getCurrentExceptionStackTrace()))
quitMax #noPrompt
'''.replace("__FOLDER__", folder.as_posix()).replace("__FIXTURE__", args.fixture.resolve().as_posix())
    start = folder / "restart.ms"
    start.write_text(bootstrap, encoding="utf-8-sig")
    normal = Path(os.environ["LOCALAPPDATA"]) / "Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini"
    original = normal.read_bytes()
    command = ["C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe", "-q", "-silent", "-i", str(folder / "max.ini"),
               "-p", str(plugins), "-U", "MAXScript", str(start), "-listenerlog", str(folder / "restart-listener.log")]
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    environment=os.environ.copy()
    environment["CYRUS_PHYSICS_LOG_DIR"]=str(folder/"restart-diagnostics")
    process = subprocess.Popen(command, cwd=folder, env=environment, startupinfo=startup, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("Owned installed-profile restart PID", process.pid, flush=True)
    try:
        process.wait(timeout=args.timeout)
    except subprocess.TimeoutExpired:
        process.terminate()
        process.wait(timeout=30)
        raise
    assert normal.read_bytes() == original, "Normal profile changed"
    if (folder / "restart-error.txt").exists():
        raise RuntimeError((folder / "restart-error.txt").read_text())
    assert (folder / "restart-completed.json").exists(), "No restart completion receipt"
    loaded = {}
    for line in (folder / "restart-loaded.tsv").read_text(encoding="utf-8-sig").splitlines():
        name, path = line.split("\t")
        resolved = Path(path).resolve()
        assert resolved.parent == installed, name
        assert digest(resolved) == manifest["payload"]["native/" + name], name
        loaded[name] = {"path": str(resolved), "sha256": digest(resolved)}
    assert len(loaded) == 2
    (folder / "installer-receipt.json").write_text(json.dumps({"pass": True, "computer_use": False,
        "normal_profile_modified": False, "package_sha256": digest(args.package), "installed_pair": loaded,
        "installed_script_sha256": digest(installed.parent / "scripts/CyrusPhysicsLab.ms"),
        "fixture_sha256": digest(args.fixture), "restart_command": command}, indent=2) + "\n")
    print("PASS isolated installer, automatic startup and installed-pair button/Painter workflow", flush=True)


if __name__ == "__main__":
    main()
