"""Package the qualified independent lab pair. Never install it."""
from pathlib import Path
import argparse
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / "CyrusPhysicsLab"


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    receipt = json.loads((args.build / "receipt.json").read_text())
    if receipt.get("faults"):
        raise RuntimeError("Private fault modules cannot be packaged")
    for relative, expected in receipt["source_hashes"].items():
        if digest((PROJECT / relative).read_bytes()) != expected:
            raise RuntimeError("Source changed since build: " + relative)
    for relative, expected in receipt["shared_source_hashes"].items():
        if digest((ROOT / relative).read_bytes()) != expected:
            raise RuntimeError("Shared dependency changed since build: " + relative)
    payload = {}
    for name in ("CyrusPhysicsLab.dlx", "CyrusPhysicsStorage.dlh", "CyrusPhysicsCrashWatch.exe"):
        data = (args.build / name).read_bytes()
        if digest(data) != receipt["binaries"][name]:
            raise RuntimeError("Native pair changed: " + name)
        payload["native/" + name] = data
    payload["native/build-identity.json"]=(json.dumps({"version":"0.2.1","max_year":2027,"binaries":receipt["binaries"],"source_hashes":receipt["source_hashes"]},indent=2)+"\n").encode()
    payload["scripts/CyrusPhysicsLab.ms"] = (PROJECT / "scripts/CyrusPhysicsLab.ms").read_bytes()
    payload["README.md"] = (PROJECT / "README.md").read_bytes()
    payload["licenses/Jolt-MIT.txt"] = (ROOT / "build/physics-lab-dependencies/jolt-1b2e77e3c6c09709e5edc79dc208459b8ff32051/LICENSE").read_bytes()
    payload["licenses/VHACD-BSD-3-Clause.txt"] = (PROJECT / "third_party/vhacd/LICENSE").read_bytes()
    payload["licenses/nlohmann-MIT.txt"] = (ROOT / "CyrusLicensing/third_party/nlohmann/LICENSE.MIT").read_bytes()
    payload["Uninstall.ms"] = r'''(
    if (maxVersion())[1]!=29000 do throw "Use Max 2027 to remove this laboratory registration."
    local root=getFilenamePath (getSourceFileName())
    local expected=pathConfig.appendPath root "native"
    local ini=pathConfig.appendPath (getFilenamePath (getMAXIniFile())) "Plugin.UserSettings.ini"
    local current=getINISetting ini "Directories" "CyrusPhysicsLab"
    if toLower current!=toLower expected do throw "Run Uninstall.ms from the currently installed laboratory directory. No registration was changed."
    setINISetting ini "Directories" "CyrusPhysicsLab" ""
    local startup=pathConfig.appendPath (getDir #userStartupScripts) "CyrusPhysicsLabStartup.ms"
    if doesFileExist startup do
    (
        local content=(dotNetClass "System.IO.File").ReadAllText startup
        if findString (toLower content) (toLower root)!=undefined do deleteFile startup
    )
    messageBox "Laboratory registration removed. Save work and restart Max 2027. Package files and scenes are preserved." title:"Physics Lab"
)
'''.encode("utf-8-sig")
    stamp = digest(json.dumps(receipt["source_hashes"], sort_keys=True).encode() + payload["native/CyrusPhysicsLab.dlx"] + payload["native/CyrusPhysicsStorage.dlh"])[:12]
    startup = (PROJECT / "installer/CyrusPhysicsLabStartup.ms").read_text()
    # getDir is resolved by the installer; the startup root is emitted there.
    startup = startup.replace("__DLX_SHA__", digest(payload["native/CyrusPhysicsLab.dlx"]))
    startup = startup.replace("__DLH_SHA__", digest(payload["native/CyrusPhysicsStorage.dlh"]))
    startup = startup.replace("__WATCH_SHA__",digest(payload["native/CyrusPhysicsCrashWatch.exe"]))
    startup = startup.replace("__IDENTITY_SHA__",digest(payload["native/build-identity.json"]))
    startup = startup.replace("__SCRIPT_SHA__", digest(payload["scripts/CyrusPhysicsLab.ms"]))
    payload["CyrusPhysicsLabStartup.ms"] = startup.encode("utf-8-sig")
    identities = {name: digest(data) for name, data in payload.items()}
    specs = ",\n".join('#(@"' + name + '","' + sha + '")' for name, sha in identities.items())
    installer = r'''global CPLInstallerValidateOnly
fn CPLInstallIndependentLab quiet:false =
(
    if (maxVersion())[1]!=29000 do throw "Cyrus Physics Lab 0.2.1 requires Max 2027."
    local packageRoot=getFilenamePath (getSourceFileName())
    local destination=pathConfig.appendPath (getDir #userScripts) "CyrusPhysicsLab/0.2.1/__STAMP__/"
    local specs=#(__SPECS__)
    fn fileSHA path =
    (
        local stream=(dotNetClass "System.IO.File").OpenRead path
        local hash=(dotNetClass "System.Security.Cryptography.SHA256").Create()
        local bytes=undefined
        try(bytes=hash.ComputeHash stream;stream.Close();hash.Dispose())catch(stream.Close();hash.Dispose();throw())
        toLower (substituteString ((dotNetClass "System.BitConverter").ToString bytes) "-" "")
    )
    for spec in specs do if fileSHA (pathConfig.appendPath packageRoot spec[1])!=spec[2] do throw ("Package payload failed hash validation: "+spec[1])
    for spec in specs do
    (
        local target=pathConfig.appendPath destination spec[1]
        makeDir (getFilenamePath target) all:true
        if doesFileExist target then
        (
            if fileSHA target!=spec[2] do throw ("Existing laboratory file differs: "+target)
        )
        else if not copyFile (pathConfig.appendPath packageRoot spec[1]) target do throw ("Copy failed: "+target)
        if fileSHA target!=spec[2] do throw ("Installed payload differs: "+target)
    )
    local pluginIni=pathConfig.appendPath (getFilenamePath (getMAXIniFile())) "Plugin.UserSettings.ini"
    local oldEntry=getINISetting pluginIni "Directories" "CyrusPhysicsLab"
    local startup=pathConfig.appendPath (getDir #userStartupScripts) "CyrusPhysicsLabStartup.ms"
    local oldStartup=if doesFileExist startup then (dotNetClass "System.IO.File").ReadAllText startup else undefined
    try
    (
        if not setINISetting pluginIni "Directories" "CyrusPhysicsLab" (pathConfig.appendPath destination "native") do throw "Cannot register laboratory native directory."
        makeDir (getFilenamePath startup) all:true
        local startupText=(dotNetClass "System.IO.File").ReadAllText (pathConfig.appendPath destination "CyrusPhysicsLabStartup.ms")
        startupText=substituteString startupText "__ROOT__" destination
        (dotNetClass "System.IO.File").WriteAllText startup startupText
    )catch
    (
        setINISetting pluginIni "Directories" "CyrusPhysicsLab" oldEntry
        if oldStartup!=undefined then (dotNetClass "System.IO.File").WriteAllText startup oldStartup else if doesFileExist startup do deleteFile startup
        throw()
    )
    if not quiet do messageBox "Cyrus Physics Lab 0.2.1 is staged. Save work and restart Max 2027. Create Geometry > Cyrus Labs > Cyrus Physics Lab. This is an independent experimental object; review its limits in README.md." title:"Physics Lab installed"
)
if CPLInstallerValidateOnly!=true do CPLInstallIndependentLab()
'''.replace("__STAMP__", stamp).replace("__SPECS__", specs)
    payload["install.ms"] = installer.encode("utf-8-sig")
    payload["mzp.run"] = b'name "Cyrus Physics Lab 0.2.1 Max 2027"\nversion 1\nrun "install.ms"\n'
    manifest = {"product": "CyrusPhysicsLab", "version": "0.2.1", "max_year": 2027,
                "integrated_into_scatter": False, "payload": {n: digest(d) for n, d in payload.items()}}
    payload["manifest.json"] = (json.dumps(manifest, indent=2) + "\n").encode()
    args.output.mkdir(parents=True, exist_ok=False)
    package = args.output / "CyrusPhysicsLab-0.2.1-Max2027.mzp"
    with zipfile.ZipFile(package, "w", zipfile.ZIP_DEFLATED) as archive:
        for name, data in payload.items():
            archive.writestr(name, data)
    with zipfile.ZipFile(package) as archive:
        if archive.testzip() is not None:
            raise RuntimeError("Archive integrity failed")
        for name, sha in manifest["payload"].items():
            if digest(archive.read(name)) != sha:
                raise RuntimeError("Archive payload identity mismatch: " + name)
    (args.output / "install.ms").write_text(installer, encoding="utf-8-sig")
    manifest["package"] = str(package.resolve())
    manifest["package_sha256"] = digest(package.read_bytes())
    manifest["package_bytes"] = package.stat().st_size
    manifest["installed"] = False
    (args.output / "package.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps({k: manifest[k] for k in ("package", "package_sha256", "package_bytes", "installed")}, indent=2))


if __name__ == "__main__":
    main()
