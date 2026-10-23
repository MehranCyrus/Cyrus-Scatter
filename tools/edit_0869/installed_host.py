"""Launch a fresh owned Max process from exact EXE-installed paths.

Requires a passed installer_checks.py receipt. No native DLL or product script is
copied to the host profile. Max reads the installed plugin INI and startup folder.
"""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import subprocess
import uuid
import zipfile

from compatibility_host import ROOT, suite_paths, owned_folder, wait_ready, verify_owned, artifact_identity
from private_host import DIRECTORIES
from package import SCATTER_NATIVE, ANALYZER_NATIVE
import build_inputs


def installed_inputs(receipt_path, year):
    receipt_path = Path(receipt_path).resolve()
    if not receipt_path.is_relative_to(ROOT / "build"):
        raise ValueError("Owned installer evidence required")
    receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
    if (receipt.get("schema") != "cyrus.edit-installer-checks/1" or receipt.get("status") != "pass"
            or receipt.get("checks") != 53 or year not in (2024, 2026, 2027)):
        raise ValueError("A passed exact three-host EXE handler receipt is required")
    executable = Path(receipt["exe"])
    build_inputs.verify_managed(executable, "installer-exe", ROOT)
    if (build_inputs.digest(executable) != receipt["exe_sha256"]
            or build_inputs.digest(executable.with_suffix(".build.json")) != receipt["exe_receipt_sha256"]):
        raise ValueError("Tested EXE or producer receipt differs")
    selected = receipt["installed"][str(year)]
    profile = Path(selected["profile"]).resolve()
    scatter, analyzer = Path(selected["scatter_runtime"]).resolve(), Path(selected["analyzer_runtime"]).resolve()
    for path in (profile, scatter, analyzer):
        if not path.is_relative_to(receipt_path.parent / "profiles"):
            raise ValueError("Installer runtime escaped its owned fixture")
    paths = {name: scatter / "bin" / name for name in SCATTER_NATIVE}
    paths.update({name: analyzer / "bin" / name for name in ANALYZER_NATIVE})
    paths.update({"CyrusScatter.ms": scatter / "CyrusScatter.ms", "CyrusGallery.dll": scatter / "CyrusGallery.dll",
                  "CyrusSurfaceAnalyzer.ms": analyzer / "CyrusSurfaceAnalyzer.ms"})
    for product, descriptor, names in (("Scatter", selected["scatter_package"], (*SCATTER_NATIVE, "CyrusScatter.ms", "CyrusGallery.dll")),
                                        ("Analyzer", selected["analyzer_package"], (*ANALYZER_NATIVE, "CyrusSurfaceAnalyzer.ms"))):
        package = Path(descriptor["path"])
        build_inputs.verify_package_receipt(package, ROOT)
        if build_inputs.digest(package) != descriptor["package_sha256"]:
            raise ValueError("Installed package differs: " + product)
        with zipfile.ZipFile(package) as archive:
            manifest = json.loads(archive.read("manifest.json"))
            if manifest["max_year"] != year or manifest["version"] != ("0.86.9" if product == "Scatter" else "0.14.2"):
                raise ValueError("Installed host/version mismatch")
            for name in names:
                if build_inputs.digest(paths[name]) != manifest["files"][name]:
                    raise ValueError("Installed product differs: " + name)
            startup = "CyrusScatterStartup.ms" if product == "Scatter" else "CyrusSurfaceAnalyzerStartup.ms"
            paths[startup] = profile / "u" / startup
            if build_inputs.digest(paths[startup]) != manifest["files"][startup]:
                raise ValueError("Installed startup wrapper differs")
    paths["installed_plugin_ini"] = profile / "Plugin.UserSettings.ini"
    paths["installed_scatter_receipt"] = profile / "s/CyrusScatter/installed.txt"
    paths["installed_analyzer_receipt"] = profile / "s/CyrusSurfaceAnalyzer/installed.txt"
    paths["installed_library_binding"] = scatter / "LibraryBinding.txt"
    paths["installed_library_state"] = profile / "cs/library-state.txt"
    paths["installer_evidence"] = receipt_path
    return selected, paths


def launch_installed(folder, year, installer_receipt, *, visible=False, bindings=None, timeout=180):
    folder = owned_folder(folder)
    selected, paths = installed_inputs(installer_receipt, year)
    installed = Path(selected["profile"])
    folder.mkdir(parents=True, exist_ok=False)
    template = Path(os.environ["LOCALAPPDATA"]) / f"Autodesk/3dsMax/{year} - 64bit/ENU/3dsMax.ini"
    original = template.read_bytes()
    ini = original.decode("utf-16")
    overrides = {"Additional Scripts": installed / "s", "Additional Startup Scripts": installed / "u", "Additional Macros": installed / "m"}
    for key, relative in DIRECTORIES.items():
        destination = overrides.get(key, folder / relative)
        destination.mkdir(parents=True, exist_ok=True)
        ini, count = re.subn(r"(?m)^" + re.escape(key) + "=.*$", lambda _: key + "=" + str(destination), ini)
        if count != 1:
            raise ValueError("Profile field missing/ambiguous: " + key)
    (folder / "max.ini").write_text(ini, encoding="utf-16")
    plugins = folder / "plugins.ini"
    plugins.write_text(f"[Directories]\nAdditional MAX plug-ins=C:/Program Files/Autodesk/3ds Max {year}/PlugIns\n"
                       "[Include]\nCyrusOwnedUserSettings=" + str(paths["installed_plugin_ini"]) + "\n[Help]\n", encoding="utf-16")
    # This small copy is only a fixture input. Gallery resolves the installed
    # immutable runtime's own LibraryBinding.txt into the original owned state.
    state = folder / "library-state.txt"
    state.write_bytes(paths["installed_library_state"].read_bytes())
    library = Path(state.read_text(encoding="utf-8-sig").splitlines()[1])
    inputs = {"fixture-library-state": state, "library-catalog": library / "model-catalog.json"}
    inputs.update(bindings or {})
    paths.update(suite_paths(inputs))
    expected = ",".join('#(@"' + n + '",@"' + str(paths[n]) + '")' for n in (*SCATTER_NATIVE, *ANALYZER_NATIVE))
    source = '''global AminScatterObject,CyrusSurfaceAnalyzer,CyrusPerfHeadless=true,EWHostYear=__YEAR__,MCPFixtureDir=@"__FOLDER__/"
setSilentMode false
setQuietMode false
fileIn @"__TRANSPORT__"
try (
 local expected=#(__EXPECTED__),process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(),log=createFile (MCPFixtureDir+"loaded.tsv")
 if process.Modules.Count>8192 do throw "Module inspection exceeds its bound"
 for spec in expected do (
  local found=0
  for i=0 to process.Modules.Count-1 do (
   local item=process.Modules.Item[i]
   if toLower item.ModuleName==toLower spec[1] do (
    if toLower item.FileName!=toLower spec[2] do throw ("Wrong installed native: "+item.FileName)
    found+=1;format "%\\t%\\n" item.ModuleName item.FileName to:log
   )
  )
  if found!=1 do throw ("Missing/duplicate installed module: "+spec[1])
 )
 close log
 if AminScatterObject==undefined or CyrusSurfaceAnalyzer==undefined do throw "Installed startup scripts did not register before the owned startup probe"
 if cyrusEditVersion()==2 and cyrusAnalyzerContractVersion()==1 then (
  (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"installed-startup.txt") "PASS: automatic installed wrappers and matching native modules; no product fileIn in probe"
 ) else throw "Installed API version differs"
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"ready.json") "{}"
)catch((dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"startup-error.txt") (getCurrentException()+"\\nSOURCE: "+(getErrorSourceFileName() as string)+" LINE: "+(getErrorSourceFileLine() as string)+"\\n"+getCurrentExceptionStackTrace()))
'''.replace("__YEAR__", str(year)).replace("__FOLDER__", folder.as_posix()).replace("__TRANSPORT__", (ROOT / "tools/mcp/development_transport.ms").as_posix()).replace("__EXPECTED__", expected)
    bootstrap = folder / "start.ms"
    bootstrap.write_text(source, encoding="utf-8-sig")
    command = [f"C:/Program Files/Autodesk/3ds Max {year}/3dsmax.exe", "-q", "-silent", "-i", str(folder / "max.ini"),
               "-p", str(plugins), "-U", "MAXScript", str(bootstrap), "-listenerlog", str(folder / "listener.log")]
    environment, redirected = os.environ.copy(), {}
    for key, relative in (("ADSK_3DSMAX_APPDATA_DIR", "userdata"), ("ADSK_3DSMAX_USERSETTINGS_DIR", "usersettings"), ("ADSK_3DSMAX_USERTOOLS_DIR", "usertools")):
        target = folder / relative
        target.mkdir(exist_ok=True)
        environment[key] = str(target)
        redirected[key] = str(target)
    identity, hashes = artifact_identity(paths)
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 1 if visible else 0
    process = subprocess.Popen(command, cwd=folder, env=environment, stdout=subprocess.DEVNULL,
                               stderr=subprocess.DEVNULL, startupinfo=startup)
    metadata = {"schema": "cyrus.edit-host/1", "route": "exact-exe-installed-startup", "run_id": uuid.uuid4().hex,
                "pid": process.pid, "max_year": year, "command": command, "artifact_id": identity, "hashes": hashes,
                "paths": {n: str(p) for n, p in paths.items()}, "origins": {n: str(p) for n, p in paths.items()},
                "bindings": {n: str(Path(p).resolve()) for n, p in inputs.items()}, "version": "0.86.9", "analyzer_version": "0.14.2",
                "historical_baseline": False, "require_edit_version": True, "artist_profile_modified": False}
    launch = {"pid": process.pid, "max_year": year, "command": command, "user_directories": redirected,
              "profile_template": str(template), "profile_template_sha256": hashlib.sha256(original).hexdigest(),
              "installed_profile": str(installed), "artist_profile_modified": False,
              "startup_script_sha256": build_inputs.digest(bootstrap), "plugin_ini_sha256": build_inputs.digest(plugins)}
    (folder / "launch.json").write_text(json.dumps(launch, indent=2) + "\n", encoding="utf-8")
    (folder / "qualification.json").write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"pid": process.pid, "folder": str(folder), "route": metadata["route"]}), flush=True)
    wait_ready(folder, timeout)
    verify_owned(folder)
    return metadata


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--folder", type=Path, required=True)
    parser.add_argument("--year", type=int, choices=(2024, 2026, 2027), required=True)
    parser.add_argument("--installer-receipt", type=Path, required=True)
    parser.add_argument("--visible", action="store_true")
    args = parser.parse_args()
    print(json.dumps(launch_installed(args.folder, args.year, args.installer_receipt, visible=args.visible), indent=2))


if __name__ == "__main__":
    main()
