"""Package the qualified independent lab; do not install it in the artist profile."""
from pathlib import Path
import argparse, hashlib, json, zipfile
ROOT=Path(__file__).resolve().parents[2];PROJECT=ROOT/'CyrusVegetationLab'
def sha(data):return hashlib.sha256(data).hexdigest()
def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--build',type=Path,required=True);parser.add_argument('--output',type=Path,required=True);args=parser.parse_args()
    receipt=json.loads((args.build/'receipt.json').read_text())
    if receipt['status']!='complete' or receipt['version']!='0.1.0' or receipt['host']!=2027:raise RuntimeError('A matching complete native build is required')
    for base,key in [(PROJECT,'source_hashes'),(ROOT,'shared_source_hashes')]:
        for name,expected in receipt[key].items():
            if sha((base/name).read_bytes())!=expected:raise RuntimeError('Source changed since build: '+name)
    payload={}
    for name,expected in receipt['binaries'].items():
        data=(args.build/name).read_bytes()
        if sha(data)!=expected:raise RuntimeError('Native module changed: '+name)
        payload['native/'+name]=data
    for name in ('README.md','scripts/CyrusVegetationLab.ms','installer/OpenCyrusVegetationLab.ms','docs/IMPLEMENTATION.md','core/PROVENANCE.json'):
        payload[name.removeprefix('installer/')]=(PROJECT/name).read_bytes()
    payload['native/build-identity.json']=(json.dumps(receipt,indent=2)+'\n').encode()
    payload['licenses/Jolt-MIT.txt']=(PROJECT/'core/collision/cmake/Jolt-LICENSE.txt').read_bytes()
    payload['licenses/nlohmann-MIT.txt']=(ROOT/'CyrusLicensing/third_party/nlohmann/LICENSE.MIT').read_bytes()
    startup=(PROJECT/'installer/CyrusVegetationLabStartup.ms').read_text()
    for key,name in [('__DLX_SHA__','native/CyrusVegetationLab.dlx'),('__DLH_SHA__','native/CyrusVegetationStorage.dlh'),('__SCRIPT_SHA__','scripts/CyrusVegetationLab.ms')]:startup=startup.replace(key,sha(payload[name]))
    payload['CyrusVegetationLabStartup.ms']=startup.encode('utf-8-sig')
    payload['Uninstall.ms']=r'''(
    if (maxVersion())[1]!=29000 do throw "Use Max 2027 to remove this lab registration."
    local root=getFilenamePath (getSourceFileName())
    local ini=pathConfig.appendPath (getFilenamePath (getMAXIniFile())) "Plugin.UserSettings.ini"
    local expected=pathConfig.appendPath root "native"
    if toLower (getINISetting ini "Directories" "CyrusVegetationLab")!=toLower expected do throw "Run Uninstall.ms from the currently installed Vegetation Lab directory."
    local startup=pathConfig.appendPath (getDir #userStartupScripts) "CyrusVegetationLabStartup.ms"
    if doesFileExist startup do
    (
        local content=(dotNetClass "System.IO.File").ReadAllText startup
        if findString content "-- Cyrus Vegetation Lab owned startup v1"!=1 or findString (toLower content) (toLower root)==undefined do throw "Startup ownership differs. No registration changed."
        deleteFile startup
    )
    setINISetting ini "Directories" "CyrusVegetationLab" ""
    messageBox "Vegetation Lab registration removed. Save work and restart Max 2027. Scenes and files were preserved." title:"Vegetation Lab"
)
'''.encode('utf-8-sig')
    stamp=sha(b''.join(name.encode()+data for name,data in sorted(payload.items())))[:12]
    specs=',\n'.join('#(@"'+name+'","'+sha(data)+'")' for name,data in payload.items())
    installer=r'''global CVLInstallerValidateOnly
fn CVLInstallIndependentLab quiet:false =
(
    if (maxVersion())[1]!=29000 do throw "Cyrus Vegetation Lab 0.1.0 requires Max 2027."
    local packageRoot=getFilenamePath (getSourceFileName())
    local destination=pathConfig.appendPath (getDir #userScripts) "CyrusVegetationLab/0.1.0/__STAMP__/"
    local specs=#(__SPECS__)
    fn fileSHA path =
    (
        local stream=(dotNetClass "System.IO.File").OpenRead path
        local hash=(dotNetClass "System.Security.Cryptography.SHA256").Create(),bytes=undefined
        try(bytes=hash.ComputeHash stream;stream.Close();hash.Dispose())catch(stream.Close();hash.Dispose();throw())
        toLower (substituteString ((dotNetClass "System.BitConverter").ToString bytes) "-" "")
    )
    for spec in specs do if fileSHA (pathConfig.appendPath packageRoot spec[1])!=spec[2] do throw ("Package hash validation failed: "+spec[1])
    local pluginIni=pathConfig.appendPath (getFilenamePath (getMAXIniFile())) "Plugin.UserSettings.ini"
    local oldEntry=getINISetting pluginIni "Directories" "CyrusVegetationLab"
    local startup=pathConfig.appendPath (getDir #userStartupScripts) "CyrusVegetationLabStartup.ms"
    local oldStartup=if doesFileExist startup then (dotNetClass "System.IO.File").ReadAllBytes startup else undefined
    local oldIni=if doesFileExist pluginIni then (dotNetClass "System.IO.File").ReadAllBytes pluginIni else undefined
    if oldStartup!=undefined do
    (
        local content=(dotNetClass "System.IO.File").ReadAllText startup
        if findString content "-- Cyrus Vegetation Lab owned startup v1"!=1 do throw "An unrecognized startup file already uses the Vegetation Lab name. No registration was changed."
    )
    if oldEntry!="" do
    (
        local ownedRoot=pathConfig.appendPath (getDir #userScripts) "CyrusVegetationLab/"
        if findString (toLower (pathConfig.convertPathToAbsolute oldEntry)) (toLower (pathConfig.convertPathToAbsolute ownedRoot))!=1 or oldStartup==undefined do throw "An unrecognized native registration uses the Vegetation Lab name. No registration was changed."
    )
    for spec in specs do
    (
        local target=pathConfig.appendPath destination spec[1]
        makeDir (getFilenamePath target) all:true
        if doesFileExist target then
        (
            if fileSHA target!=spec[2] do throw ("Existing versioned lab file differs: "+target)
        )
        else if not copyFile (pathConfig.appendPath packageRoot spec[1]) target do throw ("Copy failed: "+target)
        if fileSHA target!=spec[2] do throw ("Copied lab file differs: "+target)
    )
    try
    (
        if not setINISetting pluginIni "Directories" "CyrusVegetationLab" (pathConfig.appendPath destination "native") do throw "Cannot register Vegetation Lab native directory."
        makeDir (getFilenamePath startup) all:true
        local content=(dotNetClass "System.IO.File").ReadAllText (pathConfig.appendPath destination "CyrusVegetationLabStartup.ms")
        content=substituteString content "__ROOT__" destination
        (dotNetClass "System.IO.File").WriteAllText startup content
        if (dotNetClass "System.IO.File").ReadAllText startup!=content do throw "Startup verification failed."
    )
    catch
    (
        if oldIni!=undefined then (dotNetClass "System.IO.File").WriteAllBytes pluginIni oldIni else if doesFileExist pluginIni do deleteFile pluginIni
        if oldStartup!=undefined then (dotNetClass "System.IO.File").WriteAllBytes startup oldStartup else if doesFileExist startup do deleteFile startup
        throw()
    )
    if not quiet do messageBox "Vegetation Lab 0.1.0 is staged. Save work and restart Max 2027. Then run OpenCyrusVegetationLab.ms and click Create Demo. Select the grass, open Modify, and press Fit." title:"Vegetation Lab installed"
    destination
)
if CVLInstallerValidateOnly!=true do CVLInstallIndependentLab()
'''.replace('__STAMP__',stamp).replace('__SPECS__',specs)
    payload['install.ms']=installer.encode('utf-8-sig');payload['mzp.run']=b'name "Cyrus Vegetation Lab 0.1.0 Max 2027"\nversion 1\nrun "install.ms"\n'
    manifest={'product':'CyrusVegetationLab','version':'0.1.0','host':2027,'integrated_into_scatter':False,'payload':{name:sha(data) for name,data in payload.items()}}
    payload['manifest.json']=(json.dumps(manifest,indent=2)+'\n').encode()
    args.output.mkdir(parents=True,exist_ok=False);package=args.output/'CyrusVegetationLab-0.1.0-Max2027.mzp'
    with zipfile.ZipFile(package,'w',zipfile.ZIP_DEFLATED) as archive:
        for name,data in payload.items():archive.writestr(name,data)
    with zipfile.ZipFile(package) as archive:
        if archive.testzip():raise RuntimeError('Package CRC failed')
        for name,expected in manifest['payload'].items():
            if sha(archive.read(name))!=expected:raise RuntimeError('Package payload differs: '+name)
    (args.output/'OpenCyrusVegetationLab.ms').write_bytes(payload['OpenCyrusVegetationLab.ms']);(args.output/'README.md').write_bytes(payload['README.md'])
    manifest.update(package=str(package.resolve()),package_sha256=sha(package.read_bytes()),package_bytes=package.stat().st_size,installed_into_artist_profile=False)
    (args.output/'package.json').write_text(json.dumps(manifest,indent=2)+'\n');print(package.resolve())
if __name__=='__main__':main()
