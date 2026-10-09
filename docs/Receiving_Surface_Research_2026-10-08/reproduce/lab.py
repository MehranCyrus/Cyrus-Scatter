"""Owned surface research: inventory, isolated Max launch and serialized script requests."""
import argparse
import hashlib
import importlib.util
import json
import re
import shutil
import subprocess
import time
import zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
APP=Path('C:/ProgramData/Autodesk/ApplicationPlugins')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action',choices=['capture','launch','request'])
    parser.add_argument('--run',type=Path,required=True)
    parser.add_argument('--script',type=Path)
    args=parser.parse_args()
    run=args.run.resolve()
    if not run.is_relative_to(ROOT/'build'): raise ValueError('Use owned ignored build directory')
    if args.action=='capture':
        run.mkdir(parents=True,exist_ok=False)
        chosen=[APP/'ForestPackLite2027/PackageContents.xml',APP/'ForestPackLite2027/Contents/plugins/2027/ForestPackLite.dlo',
                APP/'ForestPackLite2027/Contents/scripts/startup/forestpack.ms']
        chosen += [APP/'ChaosScatter3dsMax2027'/n for n in ['PackageContents.xml','ChaosScatterMax2027.dlt','ScatterMax_Release-2027.dll','ScatterCore.ForScatter_Release.dll']]
        records=[]
        for p in chosen:
            dest=run/'inputs'/p.relative_to(APP);dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
            assert sha(p)==sha(dest)
            records.append(dict(original=str(p),copy=str(dest),sha256=sha(p),bytes=p.stat().st_size))
        config=json.loads(Path('C:/Users/Mehran/Documents/ChatGPT/Play/tyflow-analysis/tools.json').read_text())
        availability={n:Path(p).is_dir() for n,p in config.items() if n in ['ghidra','java']}
        availability['jars']=all(Path(p).is_file() for p in config['mcp_jars'])
        sources=['AminScatter/src/scatter.cpp','AminScatter/src/max_bridge.cpp','AminScatter/src/procedural.cpp',
                 'AminScatter/src/point_display.cpp','AminScatter/src/mesh_display.inc','AminScatter/src/brush_host.cpp',
                 'AminScatter/tools/ui/templates/unified-core.ms','AminScatter/scripts/AminScatterObject.ms']
        state=dict(head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
                   branch=subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),
                   status=subprocess.check_output(['git','status','--short'],cwd=ROOT,text=True),inputs=records,
                   tools=availability,sources={n:sha(ROOT/n) for n in sources})
        (run/'capture.json').write_text(json.dumps(state,indent=2)+'\n')
        spec=importlib.util.spec_from_file_location('inventory',ROOT/'docs/ForestPack_Research_2026-10-08/reproduce/capture.py')
        mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
        spec=importlib.util.spec_from_file_location('pe',ROOT/'docs/TyFlow_Architecture_Research_2026-10-06/reproduce/static_pe.py')
        pe=importlib.util.module_from_spec(spec);spec.loader.exec_module(pe)
        (run/'static').mkdir()
        for item in records:
            p=Path(item['copy'])
            if p.suffix.lower() in ['.dlo','.dll','.dlt']: mod.scan(p,run/'static'/p.stem,pe.PE)
        print(json.dumps(dict(run=str(run),files=len(records),tools=availability)))
    elif args.action=='launch':
        host=run/'host';host.mkdir(exist_ok=False)
        template=ROOT/'build/mcp-qualification/ui074-grips-20261008-01/max.ini'
        config=template.read_text(encoding='utf-16')
        replacements={
            'Additional Startup Scripts':'startup','Additional Scripts':'scripts','Additional Macros':'macros','PlugCFG':'plugcfg',
            'Temp':'temp','Page File':'temp','AutoBackup':'project/autoback','ProjectFolder':'project','Scenes':'project/scenes',
            'MaxStart':'project/scenes','MaxData':'maxdata','Hardware Shaders Cache':'shadercache','PlugCFG_ln':'plugcfg_ln',
            'Additional Icons':'icons','Additional Startup Templates':'templates','Import':'project/import','Export':'project/export',
            'Previews':'project/previews','RenderOutput':'project/renderoutput','Materials':'project/materiallibraries',
            'Images':'project/sceneassets/images','Sounds':'project/sceneassets/sounds','Animations':'project/sceneassets/animations',
            'RenderAssets':'project/sceneassets/renderassets','Archives':'project/archives','Downloads':'project/downloads',
            'BitmapProxies':'project/proxies','VideoPost':'project/vpost','Expressions':'project/express','RenderPresets':'project/renderpresets'}
        for key,relative in replacements.items():
            dest=host/relative;dest.mkdir(parents=True,exist_ok=True)
            config,count=re.subn(r'(?m)^'+re.escape(key)+r'=.*$',lambda _:key+'='+str(dest),config)
            if count!=1: raise ValueError('Profile field missing or ambiguous: '+key)
        (host/'max.ini').write_text(config,encoding='utf-16')
        (host/'bin').mkdir()
        package=json.loads((ROOT/'docs/UI_Refinements_0.74_2026-10-08/GRIP_PACKAGE.json').read_text())
        mzp=ROOT/package['package'];assert sha(mzp)==package['sha256']
        selected=['AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm','CyrusScatter.ms']
        with zipfile.ZipFile(mzp) as archive:
            for name in selected:
                data=archive.read(name);assert hashlib.sha256(data).hexdigest()==package['manifest']['files'][name]
                (host/('scripts' if name.endswith('.ms') else 'bin')/name).write_bytes(data)
        (host/'plugins.ini').write_text('[Directories]\nStandard=C:/Program Files/Autodesk/3ds Max 2027/PlugIns\nSurfaceResearch='+str(host/'bin')+'\n[Help]\n')
        shutil.copy2(HERE/'transport.ms',host/'transport.ms')
        (host/'start.ms').write_text('global RSDir=@"'+host.as_posix()+'/"\nfileIn (RSDir+"transport.ms")\n',encoding='utf-8-sig')
        command=['C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe','-q','-i',str(host/'max.ini'),'-p',str(host/'plugins.ini'),
                 '-U','MAXScript',str(host/'start.ms'),'-listenerlog',str(host/'listener.log')]
        startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
        process=subprocess.Popen(command,cwd=host,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,startupinfo=startup)
        result=dict(pid=process.pid,command=command,host=str(host),files={n:package['manifest']['files'][n] for n in selected})
        (host/'launch.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
    else:
        host=run/'host';source=args.script.resolve()
        response=host/'response.txt'
        if response.exists() and response.read_text(encoding='utf-8-sig').startswith('RUNNING '):
            raise RuntimeError('Previous host request is still running. A timeout is not cancellation.')
        if source.suffix!='.ms' or not source.is_relative_to(HERE): raise ValueError('Use this research script folder')
        dest=host/(source.stem+'-'+str(time.time_ns())+'.ms');shutil.copy2(source,dest)
        (host/'request.txt').write_text(dest.as_posix(),encoding='utf-8')
        # Only one request may be outstanding. A timeout is not cancellation.
        end=time.monotonic()+50
        while time.monotonic()<end:
            response=host/'response.txt'
            if response.exists():
                value=response.read_text(encoding='utf-8-sig')
                if dest.as_posix() in value and value.startswith(('SUCCESS','ERROR')): print(value);return
            time.sleep(.25)
        print('PENDING: inspect response.txt for this exact request before another mutation: '+dest.as_posix())

if __name__=='__main__':main()
