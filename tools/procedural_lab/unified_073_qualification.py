"""Isolated scripted qualification; never connects to an existing Max process."""
import argparse
import hashlib
import json
from pathlib import Path
import sys
import time
import shutil
import os
import subprocess

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
sys.path.insert(0,str(ROOT/'tools/procedural_lab'))
from private_host import launch
from runtime_driver import run_script

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--name',required=True)
    parser.add_argument('--fixture',type=Path)
    parser.add_argument('--definitions',type=Path,action='append',default=[])
    parser.add_argument('--code',default='')
    parser.add_argument('--probe',action='append',default=[],help='Separate dependent probe blocks, each with its own timeout')
    parser.add_argument('--native',type=Path,default=ROOT/'build/unified-073-20261006/native-max2027')
    parser.add_argument('--analyzer',type=Path)
    parser.add_argument('--idle',action='store_true')
    parser.add_argument('--completion',help='Asynchronous private report, with passed=true')
    parser.add_argument('--external',type=Path,help='Private external client runner; receives this fixture folder')
    parser.add_argument('--external-python',type=Path,default=Path(sys.executable))
    parser.add_argument('--external-timeout',type=int,default=300,help='Bounded total seconds for a serial multi-scenario external campaign')
    args=parser.parse_args()
    fixture_paths=([args.fixture] if args.fixture else [])+args.definitions
    # Reject malformed fixture arguments before creating a Max process. A
    # missing file must never bypass the owned-process finally block.
    fixture_hashes={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in fixture_paths}
    if args.external and not args.external.is_file():raise FileNotFoundError(args.external)
    folder=ROOT/'build/mcp-qualification'/args.name
    if folder.exists():raise RuntimeError('Use a fresh private fixture directory')
    python_paths=[p for p in (ROOT/'CyrusMCP/cyrus_mcp').rglob('*') if p.is_file() and p.suffix in ('.py','.json')]
    python_paths += [ROOT/name for name in ('tools/mcp/host_fixture.py','tools/mcp/host_boundary.py',
        'tools/procedural_lab/Max_Runtime_Panel_Fixture.py','tools/procedural_lab/unified_073_panel_host.py',
        'tools/procedural_lab/unified_073_mcp_host.py')]
    def python_snapshot():
        return {p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(python_paths)}
    python_before=python_snapshot()
    def verify(directory,project):
        receipt=json.loads((directory/'receipt.json').read_text())
        if receipt.get('status')=='pending' or receipt['project']!=project or receipt['max_year']!=2027 or any(s['exit_code'] for s in receipt['stages']):raise RuntimeError('Passing matching SDK receipt required')
        for name,key in {**receipt['sources'],**receipt['binaries']}.items():
            if hashlib.sha256((ROOT/name).read_bytes()).hexdigest()!=key:raise RuntimeError('Source/binary changed since build: '+name)
    verify(args.native,'scatter')
    installed=Path.home()/'AppData/Local/Autodesk/3dsMax/2027 - 64bit/ENU'
    profile_paths=[installed/'scripts/CyrusScatter',installed/'scripts/CyrusSurfaceAnalyzer',
                   installed/'scripts/Startup/CyrusScatterStartup.ms',installed/'scripts/Startup/CyrusSurfaceAnalyzerStartup.ms',
                   installed/'usermacros/CyrusScatter-CyrusScatter.mcr',installed/'usermacros/CyrusSurfaceAnalyzer-CyrusSurfaceAnalyzer.mcr']
    profile_paths += [installed/'plugins'/name for name in ('AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusSurfaceAnalyzer.dlx')]
    def profile_snapshot():
        snapshot={}
        for path in profile_paths:
            if path.is_dir():
                for file in sorted(path.rglob('*')):
                    if file.is_file():snapshot[str(file)]=hashlib.sha256(file.read_bytes()).hexdigest()
            else:snapshot[str(path)]=hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
        return snapshot
    profile_before=profile_snapshot()
    native=args.native
    extra='fileIn @"'+(ROOT/'tools/performance/CyrusPerformanceMonitor.ms').as_posix()+'"\n'
    modules=()
    if args.analyzer:
        verify(args.analyzer,'analyzer')
        native=ROOT/'build/unified-073-20261006/launch-payload'/args.name
        native.mkdir(parents=True,exist_ok=False)
        for name in ('AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh'):shutil.copy2(args.native/name,native/name)
        shutil.copy2(args.analyzer/'CyrusSurfaceAnalyzer.dlx',native/'CyrusSurfaceAnalyzer.dlx')
        modules=('CyrusSurfaceAnalyzer.dlx',)
        extra+='fileIn @"'+(ROOT/'CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms').as_posix()+'"\n'
    process,metadata=launch(folder,ROOT/'AminScatter/scripts/AminScatterObject.ms',native,transport=True,extra=extra,extra_modules=modules)
    receipt=dict(passed=False,launch=metadata,computer_use=False,
                 fixtures=fixture_hashes,
                 code_sha256=hashlib.sha256(args.code.encode()).hexdigest(),
                 probe_sha256=[hashlib.sha256(code.encode()).hexdigest() for code in args.probe],
                 probes=[],normal_profile_before=profile_before,host_python_sources=python_before)
    if args.external:
        receipt['external_fixture']=dict(path=str(args.external),sha256=hashlib.sha256(args.external.read_bytes()).hexdigest())
    try:
        deadline=time.monotonic()+360
        while not (folder/'ready.json').exists():
            if (folder/'startup-error.txt').exists():raise RuntimeError((folder/'startup-error.txt').read_text())
            if process.poll() is not None:raise RuntimeError(f'Max exited before bootstrap, code {process.returncode}')
            if time.monotonic()>deadline:raise RuntimeError('Max startup timed out before private bootstrap')
            time.sleep(.5)
        # Compile dependent expressions only after their globals are defined;
        # Max compiles each probe block before executing its fileIn statements.
        for path in ([args.fixture] if args.fixture else [])+args.definitions:
            result=run_script(folder,'fileIn @"'+path.resolve().as_posix()+'"',timeout=240)
            if not result.startswith('SUCCESS '):raise RuntimeError(result)
        for index,code in enumerate(([args.code] if args.code else [])+args.probe):
            started=time.monotonic()
            result=run_script(folder,code,timeout=240)
            receipt['probes'].append(dict(index=index,elapsed_s=time.monotonic()-started,result=result))
            print(f'Probe {index}: '+result,flush=True)
            if not result.startswith('SUCCESS '):raise RuntimeError(result)
        if args.external:
            environment=dict(os.environ,PYTHONPATH=str(ROOT/'CyrusMCP'))
            external=subprocess.run([str(args.external_python),str(args.external.resolve()),str(folder)],
                cwd=ROOT,env=environment,text=True,encoding='utf-8',errors='replace',
                stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=args.external_timeout)
            (folder/'external-client.log').write_text(external.stdout,encoding='utf-8')
            receipt['external_exit_code']=external.returncode
            if external.returncode:raise RuntimeError(external.stdout[-8000:])
            print('PASS external client',flush=True)
        if args.completion:
            report=folder/args.completion
            deadline=time.monotonic()+240
            while not report.exists():
                if process.poll() is not None or time.monotonic()>deadline:raise RuntimeError('Asynchronous fixture did not finish')
                time.sleep(.25)
            data=json.loads(report.read_text())
            if data.get('passed') is not True:raise RuntimeError(data)
            print('PASS '+args.completion,flush=True)
        if args.idle:
            from live_idle_073_qualification import qualify
            qualify(folder,integrated=True)
        receipt['passed']=True
    except Exception as exc:
        receipt['error']=str(exc)
        raise
    finally:
        if process.poll() is None:process.terminate();process.wait(timeout=30)
        receipt['owned_process_stopped']=process.poll() is not None
        receipt['owned_process_returncode']=process.returncode
        receipt['normal_profile_after']=profile_snapshot()
        receipt['installed_product_files_unchanged']=receipt['normal_profile_after']==profile_before
        receipt['host_python_sources_unchanged']=python_snapshot()==python_before
        if not receipt['host_python_sources_unchanged']:
            receipt['passed']=False;receipt['error']='Host Python sources changed during qualification'
        (folder/'qualification.json').write_text(json.dumps(receipt,indent=2)+'\n')

if __name__=='__main__':main()
