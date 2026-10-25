"""Package the exact independent Max 2027 preparation kit. Never installs it."""
from pathlib import Path
import argparse,hashlib,json,zipfile
ROOT=Path(__file__).resolve().parents[3];HERE=Path(__file__).resolve().parent
def sha(b):return hashlib.sha256(b).hexdigest()
def specs(payload):return ',\n'.join('#(@"'+n+'","'+sha(b)+'")' for n,b in payload.items())
def main():
    p=argparse.ArgumentParser();p.add_argument('--build',type=Path,required=True);p.add_argument('--scene',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();r=json.loads((a.build/'receipt.json').read_text());assert r['status']=='complete' and r['version']=='0.3.1' and r['host']==2027
    for name,expected in {**r['sources'],**r['dependencies']}.items():
        if sha((ROOT/name).read_bytes())!=expected:raise RuntimeError('Compiled input changed: '+name)
    payload={}
    for name in ('CyrusVegetationStemLab.dlx','CyrusVegetationStemGeometry.dlo'):
        b=(a.build/name).read_bytes();assert sha(b)==r['binaries'][name];payload['native/'+name]=b
    for source,target in [('PreparationLab.ms','PreparationLab.ms'),('GUIDE_031.md','README.md'),('REPORT_031.md','REPORT_031.md')]:payload[target]=(HERE/source).read_bytes()
    payload['Vegetation_Preparation_Max2027.max']=a.scene.read_bytes();payload['native/build-identity.json']=(json.dumps(r,indent=2)+'\n').encode()
    payload['licenses/Jolt-MIT.txt']=(ROOT/'CyrusVegetationLab/core/collision/cmake/Jolt-LICENSE.txt').read_bytes()
    payload['licenses/nlohmann-MIT.txt']=(ROOT/'CyrusLicensing/third_party/nlohmann/LICENSE.MIT').read_bytes()
    hash_fn=r'''
fn CVPFileSHA path =
(
    local stream=(dotNetClass "System.IO.File").OpenRead path,hash=(dotNetClass "System.Security.Cryptography.SHA256").Create(),bytes=undefined
    try(bytes=hash.ComputeHash stream;stream.Close();hash.Dispose())catch(stream.Close();hash.Dispose();throw())
    toLower (substituteString ((dotNetClass "System.BitConverter").ToString bytes) "-" "")
)
'''
    core=r'''global CVPFileSHA,CVPLoadKit
__HASH__
fn CVPLoadKit root =
(
    if (maxVersion())[1]!=29000 do throw "Vegetation Preparation Lab 0.3.1 requires Max 2027."
    local specifications=#(__SPECS__)
    for spec in specifications do if CVPFileSHA (pathConfig.appendPath root spec[1])!=spec[2] do throw ("Kit payload hash differs: "+spec[1])
    fn canonical path = (toLower (substituteString ((dotNetClass "System.IO.Path").GetFullPath path) "\\" "/"))
    fn loadedPath name =
    (
        local found="",process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
        for i=0 to process.Modules.Count-1 do (local item=process.Modules.Item[i];if toLower item.ModuleName==toLower name do found=item.FileName)
        found
    )
    for name in #("CyrusVegetationStemLab.dlx","CyrusVegetationStemGeometry.dlo") do
    (
        local current=loadedPath name,expected=pathConfig.appendPath root ("native/"+name)
        if current!="" and canonical current!=canonical expected do throw "Another Stem Lab module is loaded. Save work and restart Max 2027, then run this kit."
    )
    for name in #("CyrusVegetationStemLab.dlx","CyrusVegetationStemGeometry.dlo") do
    (
        if loadedPath name=="" do loadDllsFromDir (pathConfig.appendPath root "native/") name
        if canonical (loadedPath name)!=canonical (pathConfig.appendPath root ("native/"+name)) do throw ("Native module did not load from this kit: "+name)
    )
    fileIn (pathConfig.appendPath root "PreparationLab.ms")
    true
)
'''.replace('__HASH__',hash_fn).replace('__SPECS__',specs(payload))
    payload['LaunchCore.ms']=core.encode('utf-8-sig')
    for name,test in [('OpenTest.ms',True),('OpenLab.ms',False)]:
        open_code=r'''(
    global CVPLoadKit,CVPOpen
    if (maxVersion())[1]!=29000 do throw "Vegetation Preparation Lab 0.3.1 requires Max 2027."
    __UNSAVED__
    local root=getFilenamePath (getSourceFileName())
    __HASH__
    if CVPFileSHA (root+"LaunchCore.ms")!="__CORE_SHA__" do throw "Launcher hash differs. Extract the original kit again."
    fileIn (root+"LaunchCore.ms")
    CVPLoadKit root
    __SCENE__
    CVPOpen()
)
'''.replace('__UNSAVED__','if getSaveRequired() do throw "Save your current scene before running OpenTest.ms. Your work was left unchanged."' if test else '').replace('__HASH__',hash_fn).replace('__CORE_SHA__',sha(payload['LaunchCore.ms'])).replace('__SCENE__','if not loadMaxFile (root+"Vegetation_Preparation_Max2027.max") quiet:true useFileUnits:true do throw "Test scene failed to open."\n    local collider=getNodeByName "CVP_Test_Sphere"\n    if isValidNode collider do (select collider;max move)' if test else '')
        payload[name]=open_code.encode('utf-8-sig')
    stamp=sha(b''.join(n.encode()+b for n,b in sorted(payload.items())))[:12]
    install=r'''global CVPInstallRoot=getFilenamePath(getSourceFileName()),CVPInstallKit,CVPFileSHA
__HASH__
fn CVPInstallKit quiet:false =
(
    if (maxVersion())[1]!=29000 do throw "Vegetation Preparation Lab requires Max 2027."
    local source=CVPInstallRoot,destination=pathConfig.appendPath (getDir #userScripts) "CyrusVegetationLab/0.3.1/__STAMP__/",specifications=#(__SPECS__)
    for spec in specifications do if CVPFileSHA (pathConfig.appendPath source spec[1])!=spec[2] do throw ("Package hash failed: "+spec[1])
    for spec in specifications do
    (
        local target=pathConfig.appendPath destination spec[1]
        makeDir (getFilenamePath target) all:true
        if doesFileExist target then (if CVPFileSHA target!=spec[2] do throw ("Existing kit file differs: "+target))
        else if not copyFile (pathConfig.appendPath source spec[1]) target do throw ("Copy failed: "+target)
        if CVPFileSHA target!=spec[2] do throw ("Copied kit hash differs: "+target)
    )
    format "Vegetation Preparation Lab installed: %OpenTest.ms\n" destination
    if not quiet do messageBox ("Kit ready. Save work and restart Max 2027 if an older Stem Lab is loaded. Then use Scripting > Run Script:\n\n"+destination+"OpenTest.ms\n\nUse OpenLab.ms to prepare models in your own scene.") title:"Vegetation Preparation Lab 0.3.1"
    destination
)
'''.replace('__HASH__',hash_fn).replace('__STAMP__',stamp).replace('__SPECS__',specs(payload))
    payload['InstallCore.ms']=install.encode('utf-8-sig');payload['install.ms']=b'(fileIn ((getFilenamePath (getSourceFileName()))+"InstallCore.ms");CVPInstallKit())\n'
    payload['mzp.run']=b'name "Vegetation Preparation Lab 0.3.1 Max 2027"\nversion 1\nrun "install.ms"\n'
    manifest={'product':'Cyrus Vegetation Preparation Lab','version':'0.3.1','host':2027,'scope':'Independent preparation foundation; no Scatter integration','payload':{n:sha(b) for n,b in payload.items()}}
    payload['manifest.json']=(json.dumps(manifest,indent=2)+'\n').encode();a.output.mkdir(parents=True,exist_ok=False)
    for name,b in payload.items():target=a.output/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(b)
    mzp=a.output/'CyrusVegetationPreparationLab-0.3.1-Max2027.mzp'
    with zipfile.ZipFile(mzp,'w',zipfile.ZIP_DEFLATED) as z:
        for name,b in payload.items():z.writestr(name,b)
    with zipfile.ZipFile(mzp) as z:
        assert z.testzip() is None
        for name,expected in manifest['payload'].items():assert sha(z.read(name))==expected,name
        assert z.read('mzp.run').splitlines()==[b'name "Vegetation Preparation Lab 0.3.1 Max 2027"',b'version 1',b'run "install.ms"']
    manifest.update(package=str(mzp.resolve()),package_sha256=sha(mzp.read_bytes()),artist_profile_installed=False);(a.output/'package.json').write_text(json.dumps(manifest,indent=2)+'\n');print(a.output.resolve())
if __name__=='__main__':main()
