"""Launch a private visible Brush lab; never modifies the artist installation."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
from build import ROOT, BASE

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--run',required=True)
    parser.add_argument('--scene',type=Path,help='Open a saved Brush lab fixture after startup')
    parser.add_argument('--config',type=Path,default=Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini',help='Read-only source configuration; the lab writes its own copy')
    args=parser.parse_args()
    if not re.fullmatch(r'[a-z0-9-]+',args.run):
        raise SystemExit('Use a lowercase run name')
    output=BASE/args.run
    output.mkdir(parents=True,exist_ok=False)
    for name in ('startup','plugcfg','temp','bin','autoback'):
        (output/name).mkdir()
    for name in ('AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh'):
        shutil.copy2(BASE/'max2027'/name,output/'bin'/name)
    config=args.config.read_text(encoding='utf-16')
    for key,target in {'Additional Startup Scripts':output/'startup','PlugCFG':output/'plugcfg','Temp':output/'temp','Page File':output/'temp','AutoBackup':output/'autoback'}.items():
        config,count=re.subn(rf'(?m)^{re.escape(key)}=.*$',lambda _:key+'='+str(target),config)
        if count!=1:
            raise SystemExit(f'Expected one {key} entry in the source config')
    (output/'desktop.ini').write_text(config,encoding='utf-16')
    (output/'plugins.ini').write_text('[Directories]\nAdditional MAX plug-ins=C:/Program Files/Autodesk/3ds Max 2027/PlugIns/\nCyrusBrushLab='+str(output/'bin')+'\n[Help]\n')
    start=output/'start.ms'
    scene=args.scene.resolve() if args.scene else None
    if scene and (not scene.is_file() or scene.suffix.lower()!='.max' or '"' in str(scene)):
        raise SystemExit('Expected an existing .max fixture')
    scene_assignment=f'global BLReopenScene="{scene.as_posix()}"\n' if scene else 'global BLReopenScene=undefined\n'
    start.write_text(f'global BLRoot="{ROOT.as_posix()}/",BLDir="{output.as_posix()}/"\n'+scene_assignment+'fileIn (BLRoot+"tools/brush_lab/transport.ms")\n',encoding='utf-8')
    (output/'identity.json').write_text(json.dumps({p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (output/'bin').iterdir()},indent=2))
    command=['C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe','-q','-i',str(output/'desktop.ini'),'-p',str(output/'plugins.ini'),'-U','MAXScript',str(start),'-listenerlog',str(output/'listener.log')]
    process=subprocess.Popen(command,cwd=ROOT,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    result={'pid':process.pid,'command':command,'output':str(output)}
    (output/'launch.json').write_text(json.dumps(result,indent=2))
    print(json.dumps(result,indent=2))

if __name__=='__main__':main()
