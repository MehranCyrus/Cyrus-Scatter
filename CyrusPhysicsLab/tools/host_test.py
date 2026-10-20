"""Run scripted tests in an owned hidden Max 2027 profile; no Computer Use."""
from pathlib import Path
import argparse
import hashlib
import importlib.util
import json
import os
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / "CyrusPhysicsLab"


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--fixture", type=Path, default=PROJECT / "tests/host.ms")
    parser.add_argument("--timeout", type=int, default=240)
    parser.add_argument("--script", type=Path, default=PROJECT / "scripts/CyrusPhysicsLab.ms")
    parser.add_argument("--scale", type=float, choices=(1.0, 1.5), help="Owned Max custom-control scale, set before panel creation")
    args = parser.parse_args()
    folder, native = args.output.resolve(), args.build.resolve()
    if not folder.is_relative_to(ROOT / "build"):
        parser.error("Private profiles belong under ignored build/")
    folder.mkdir(parents=True, exist_ok=False)
    spec = importlib.util.spec_from_file_location("owned_profile_paths", ROOT / "tools/procedural_lab/source_container_preview/launch.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    for relative in {"bin", *module.DIRECTORIES.values()}:
        (folder / relative).mkdir(parents=True, exist_ok=True)
    template = Path(os.environ["LOCALAPPDATA"]) / "Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini"
    original = template.read_bytes()
    ini = original.decode("utf-16")
    for key, relative in module.DIRECTORIES.items():
        ini, count = re.subn(r"(?m)^" + re.escape(key) + r"=.*$", lambda _: key + "=" + str(folder / relative), ini)
        if count != 1:
            raise RuntimeError("Private profile field is missing/ambiguous: " + key)
    (folder / "max.ini").write_text(ini, encoding="utf-16")
    hashes = {}
    for name in ("CyrusPhysicsLab.dlx", "CyrusPhysicsStorage.dlh"):
        destination = folder / "bin" / name
        shutil.copy2(native / name, destination)
        hashes[name] = digest(destination)
    helper = native / "CyrusPhysicsCrashWatch.exe"
    if helper.exists():
        shutil.copy2(helper,folder / "bin" / helper.name)
        (folder / "bin/build-identity.json").write_text(json.dumps({"version":"0.2.1","binaries":hashes,"helper_sha256":digest(helper)}))
    script = folder / "scripts/CyrusPhysicsLab.ms"
    shutil.copy2(args.script, script)
    fixture = folder / "fixture.ms"
    shutil.copy2(args.fixture, fixture)
    (folder / "plugins.ini").write_text("[Directories]\nStandard=C:/Program Files/Autodesk/3ds Max 2027/stdplugs\nPhysicsLab=" + str(folder / "bin") + "\n[Help]\n")
    bootstrap = '''
global CPLTestDir=@"__FOLDER__/"
fn cplStage name = ((dotNetClass "System.IO.File").AppendAllText (CPLTestDir+"stages.txt") (name+"\\n"))
cplStage "bootstrap"
setSilentMode false
setQuietMode false
__SCALE__
fn cplResetScene =
(
    setSilentMode true
    setQuietMode true
    try(resetMaxFile #noPrompt)catch(setSilentMode false;setQuietMode false;throw())
    setSilentMode false
    setQuietMode false
)
try (
    cplStage "load class"
    fileIn @"__SCRIPT__"
    cplStage "class loaded"
    local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
    local log=createFile (CPLTestDir+"loaded.tsv")
    for i=0 to process.Modules.Count-1 do (
        local item=process.Modules.Item[i]
        if matchPattern item.ModuleName pattern:"CyrusPhysics*" do format "%\\t%\\n" item.ModuleName item.FileName to:log
    )
    close log
    cplStage "fixture"
    fileIn @"__FIXTURE__"
    (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"completed.json") "{}"
) catch (
    (dotNetClass "System.IO.File").WriteAllText (CPLTestDir+"error.txt") (getCurrentException()+"\\nSOURCE: "+(getErrorSourceFileName() as string)+" LINE: "+(getErrorSourceFileLine() as string)+"\\n"+getCurrentExceptionStackTrace())
)
quitMax #noPrompt
'''.replace("__FOLDER__", folder.as_posix()).replace("__SCRIPT__", script.as_posix()).replace("__FIXTURE__", fixture.as_posix()).replace("__SCALE__", "" if args.scale is None else f"CustomControlsOptions.UIUserScaleFactor={args.scale}")
    start = folder / "start.ms"
    start.write_text(bootstrap, encoding="utf-8-sig")
    command = ["C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe", "-q", "-silent", "-i", str(folder / "max.ini"),
               "-p", str(folder / "plugins.ini"), "-U", "MAXScript", str(start), "-listenerlog", str(folder / "listener.log")]
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    environment=os.environ.copy()
    environment["CYRUS_PHYSICS_LOG_DIR"]=str(folder/"diagnostics")
    process = subprocess.Popen(command, cwd=folder, env=environment, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, startupinfo=startup)
    metadata = {"pid": process.pid, "command": command, "max_year": 2027, "computer_use": False,
                "max_executable_sha256": digest(command[0]),
                "normal_profile_modified": False, "requested_scale": args.scale, "binaries": hashes, "script_sha256": digest(script),
                "diagnostic_helper_sha256": digest(helper) if helper.exists() else None, "fixture_sha256": digest(fixture), "profile_template_sha256": digest(template)}
    (folder / "launch.json").write_text(json.dumps(metadata, indent=2) + "\n")
    print(f"Owned Max 2027 PID {process.pid}; profile {folder}", flush=True)
    deadline = time.monotonic() + args.timeout
    while process.poll() is None and time.monotonic() < deadline:
        time.sleep(1)
    if process.poll() is None:
        # Popen identity belongs to this invocation; never enumerate/kill other Max processes.
        process.terminate()
        process.wait(timeout=30)
        raise RuntimeError("Owned host timed out; preserved profile and logs")
    if template.read_bytes() != original:
        raise RuntimeError("Normal profile changed during run; inspect concurrent activity")
    if (folder / "error.txt").exists():
        print((folder / "error.txt").read_text(encoding="utf-8"), flush=True)
        raise SystemExit(1)
    if not (folder / "completed.json").exists():
        raise RuntimeError(f"Max exited without completion receipt ({process.returncode})")
    loaded = (folder / "loaded.tsv").read_text(encoding="utf-8-sig")
    for name, expected in hashes.items():
        if str(folder / "bin" / name).lower() not in loaded.lower() or digest(folder / "bin" / name) != expected:
            raise RuntimeError("Loaded binary identity not verified: " + name)
    print("PASS scripted Max 2027 fixture; physical input not tested", flush=True)


if __name__ == "__main__":
    main()
