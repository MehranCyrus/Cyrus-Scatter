"""Launch the qualified product in a disposable visible Max profile."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
from build import ROOT,BASE

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--run',required=True)
    parser.add_argument('--scene',type=Path)
    parser.add_argument('--reopen-expected',type=Path,help='Saved-scene expectations produced by output_and_restore_fixture.ms')
    parser.add_argument('--with-analyzer',action='store_true',help='Load the unchanged Analyzer 0.14 dependency for artist-scene checks')
    parser.add_argument('--installed-from',type=Path,help='Restart a copy of a verified private installer result, using its real startup script')
    parser.add_argument('--config',type=Path,default=Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini')
    args=parser.parse_args()
    if not re.fullmatch(r'[a-z0-9-]+',args.run):raise SystemExit('Use a lowercase run name')
    output=BASE/'hosts'/args.run
    output.mkdir(parents=True,exist_ok=False)
    for name in ('startup','scripts','macros','plugcfg','temp','bin','autoback'):(output/name).mkdir()
    native=output/'bin'
    if args.installed_from:
        origin=args.installed_from.resolve()
        if not origin.is_relative_to(BASE/'hosts') or not (origin/'installer-acceptance.json').is_file():raise SystemExit('Expected a verified private installation')
        product=output/'scripts/CyrusScatter'
        shutil.copytree(origin/'scripts/CyrusScatter',product)
        for name,folder in [('CyrusScatterStartup.ms','startup'),('CyrusScatter.mcr','macros')]:shutil.copy2(origin/folder/name,output/folder/name)
        manifest=json.loads((product/'manifest.json').read_text())
        native=product/f'bin-max2027-{manifest["native_id"]}'
        for name in ('CyrusScatter.ms','AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh'):
            path=product/name if name.endswith('.ms') else native/name
            if hashlib.sha256(path.read_bytes()).hexdigest()!=manifest['files'][name]:raise SystemExit('Installed file failed its manifest: '+name)
    else:
        for name in ('AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh'):
            shutil.copy2(BASE/'max2027'/name,native/name)
    if args.with_analyzer:
        shutil.copy2(ROOT/'build/codebase-research-2026-10-01/max2027/CyrusSurfaceAnalyzer/CyrusSurfaceAnalyzer.dlx',native/'CyrusSurfaceAnalyzer.dlx')
    config=args.config.read_text(encoding='utf-16')
    for key,target in {'Additional Scripts':output/'scripts','Additional Macros':output/'macros','Additional Startup Scripts':output/'startup','PlugCFG':output/'plugcfg','Temp':output/'temp','Page File':output/'temp','AutoBackup':output/'autoback'}.items():
        config,count=re.subn(rf'(?m)^{re.escape(key)}=.*$',lambda _:key+'='+str(target),config)
        if count!=1:raise SystemExit(f'Expected one {key} entry')
    (output/'desktop.ini').write_text(config,encoding='utf-16')
    (output/'plugins.ini').write_text('[Directories]\nAdditional MAX plug-ins=C:/Program Files/Autodesk/3ds Max 2027/PlugIns/\nCyrusV1='+str(native)+'\n[Help]\n')
    scene=args.scene.resolve() if args.scene else None
    if scene and (not scene.is_file() or scene.suffix.lower()!='.max' or '"' in str(scene)):raise SystemExit('Expected an existing .max fixture')
    if args.reopen_expected:
        expected=args.reopen_expected.resolve()
        if not expected.is_relative_to(BASE/'hosts') or expected.name!='reopen-expected.ms' or not scene:raise SystemExit('Expected a private saved-scene fixture and its expectation file')
        shutil.copy2(expected,output/'reopen-expected.ms')
    start=output/'start.ms'
    text=f'global BLRoot="{ROOT.as_posix()}/",BLDir="{output.as_posix()}/"\n'
    text+='fileIn (BLRoot+"tools/v1/transport.ms")\n'
    if args.installed_from:text+='if CyrusScatterObject==undefined do throw "Installed Cyrus startup did not register the scene class"\n'
    else:text+='fileIn (BLRoot+"AminScatter/scripts/AminScatterObject.ms")\n'
    if args.with_analyzer:text+='fileIn (BLRoot+"CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms")\n'
    if scene:text+=f'loadMaxFile "{scene.as_posix()}" useFileUnits:true quiet:true\n'
    start.write_text(text,encoding='utf-8')
    (output/'identity.json').write_text(json.dumps({p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in native.glob('*.dl?')},indent=2))
    command=['C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe','-q','-i',str(output/'desktop.ini'),'-p',str(output/'plugins.ini'),'-U','MAXScript',str(start),'-listenerlog',str(output/'listener.log')]
    process=subprocess.Popen(command,cwd=ROOT,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    result={'pid':process.pid,'command':command,'output':str(output)}
    (output/'launch.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))

if __name__=='__main__':main()
