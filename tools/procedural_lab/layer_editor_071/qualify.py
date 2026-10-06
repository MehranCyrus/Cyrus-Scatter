"""Freeze the UI candidate; reuse verified native builds and qualify in private Max."""
from pathlib import Path
import argparse,json,shutil,sys,time
import psutil
from private_host import ROOT,launch,digest
sys.path.insert(0,str(ROOT/'tools/licensing_lab'))
from run import snapshot,write_json,run_command
sys.path.insert(0,str(ROOT/'tools/procedural_lab'))
from runtime_driver import run_script


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run',required=True)
    parser.add_argument('--native-build',required=True,type=Path)
    parser.add_argument('--keep-open',action='store_true')
    parser.add_argument('--reuse-session',type=Path,help='Reuse an idle private host only when script and native hashes match exactly')
    args=parser.parse_args()
    if not args.run.replace('-','').isalnum():raise ValueError('Invalid run name')
    native=args.native_build.resolve()
    if not native.is_relative_to(ROOT/'build'):raise ValueError('Private native build required')
    out=ROOT/'build/ui-071'/args.run;out.mkdir(parents=True,exist_ok=False)
    run_command([sys.executable,ROOT/'tools/procedural_lab/check_generated.py'],out/'generated',None)
    source=snapshot(out)
    for year in [2026,2027]:
        result=json.loads((native/f'tests-{year}.json').read_text())
        if result['exit_code']!=0:raise RuntimeError('Native tests failed')
        expected=json.loads((native/f'ready-{year}.json').read_text())
        target=out/f'max{year}';target.mkdir()
        for name,sha in expected.items():
            if digest(native/f'max{year}'/name)!=sha:raise RuntimeError('Native artifact changed')
            shutil.copy2(native/f'max{year}'/name,target/name)
        shutil.copy2(native/f'tests-{year}.log',out/f'tests-{year}.log')
    run_command([ROOT/'build/mcp-venv/Scripts/python.exe','-m','pytest',ROOT/'CyrusMCP/tests','-q'],out/'mcp-tests',None)
    folder=ROOT/'build/mcp-qualification'/('procedural07-ui-071-'+args.run)
    extra='fileIn @"'+(source/'tools/performance/CyrusPerformanceMonitor.ms').as_posix()+'"\n'
    extra+='fileIn @"'+(source/'tools/procedural_lab/Max_Procedural_07_Acceptance.ms').as_posix()+'"'
    if args.reuse_session:
        folder=args.reuse_session.resolve()
        if not folder.is_relative_to(ROOT/'build/mcp-qualification') or not folder.name.startswith('procedural07-ui-071-'):
            raise ValueError('Private 0.7.1 session required')
        metadata=json.loads((folder/'launch.json').read_text())
        if metadata['script_sha256']!=digest(source/'AminScatter/scripts/AminScatterObject.ms'):
            raise RuntimeError('Reuse requires identical loaded script')
        for name,sha in metadata['binaries'].items():
            if sha!=digest(out/'max2027'/name) or sha!=digest(folder/'bin'/name):raise RuntimeError('Reuse native mismatch')
        process=psutil.Process(metadata['pid'])
        if str(folder/'max.ini') not in process.cmdline():raise RuntimeError('Unrelated process')
        metadata['reused_for']=args.run
    else:
        process,metadata=launch(folder,source/'AminScatter/scripts/AminScatterObject.ms',out/'max2027',extra=extra,transport=True)
    def running():
        return process.is_running() if isinstance(process,psutil.Process) else process.poll() is None
    stages=[]
    def execute(label,script):
        result=run_script(folder,script,timeout=600)
        stages.append({'stage':label,'result':result.strip()});write_json(out/'stages.json',stages)
        print(label+': '+result.strip(),flush=True)
        if not result.startswith('SUCCESS '):raise RuntimeError(result)
    try:
        deadline=time.monotonic()+180
        while not (folder/'ready.json').exists():
            if (folder/'startup-error.txt').exists():raise RuntimeError((folder/'startup-error.txt').read_text())
            if not running() or time.monotonic()>deadline:raise RuntimeError('Private Max startup failed')
            time.sleep(.5)
        print('Private Max ready; matching module paths verified.',flush=True)
        execute('core','P07Acceptance()')
        for name in ['Max_Procedural_07_Bindings.ms','Max_Layer_Editor_071_Acceptance.ms','Max_Layer_Editor_071_BrushLive.ms',
                     'Max_Procedural_07_Regression.ms','Max_Source_Containers_Acceptance.ms',
                     'Max_Source_Containers_EdgeCases.ms','Max_Source_Containers_Output.ms']:
            execute(name,(source/'tools/procedural_lab'/name).read_text())
        execute('Live source events setup',(source/'tools/procedural_lab/Max_Source_Containers_Events.ms').read_text()+'\nSCEventSetup()')
        for stage in ['SCEventPark','SCEventReturn','SCEventEnroll','SCEventFinish','SCEventGroupFinish','SCEventContainerReturn','SCEventGeometry','SCEventGeometryFinish']:
            time.sleep(1);execute(stage,stage+'()')
        execute('retained 100k navigation',(source/'tools/procedural_lab/Max_Procedural_07_Navigation.ms').read_text()+
                '\nP07Navigation "layer-editor-071-100k" 100000 procedural:true frames:30 modes:#(0,1,3,4) containers:true')
        # Opening all UI topics must also leave retained GPU buffers untouched.
        execute('retained UI browsing','''
            local node=getNodeByName "NAV_Controller",root=node.baseObject,leaf=root.layerObjects[1]
            local view=CyrusPointOwner node,before=cyrusRetainedStats view,mesh=cyrusRetainedMeshStats view
            local epoch=root.procEpoch,builds=leaf.procPreparedBuilds,key=root.procInputKey()
            CyrusOpenLayerEditor root leaf
            for cycle=1 to 3 do for topic=1 to 6 do (CyrusLayerEditor.showTopic topic;completeRedraw())
            local after=cyrusRetainedStats view,meshAfter=cyrusRetainedMeshStats view
            for k in #(3,4,5,6,7,9) do if before[k]!=after[k] do throw "UI browsing uploaded retained buffers"
            if mesh as string!=meshAfter as string do throw "UI browsing changed retained Mesh statistics"
            if root.procEpoch!=epoch or leaf.procPreparedBuilds!=builds or root.procInputKey()!=key do throw "UI browsing regenerated placements"
            CSPWriteText (MCPFixtureDir+"retained-ui-071.json") (CSPObject #(#("population",100000),#("zero_regeneration",true),#("zero_uploads",true),#("topics",6)))
            CyrusCloseLayerEditor()
        ''')
        for row in json.loads((out/'source.json').read_text())['files']:
            if digest(ROOT/row['path'])!=row['sha256']:raise RuntimeError('Source changed during qualification: '+row['path'])
        result={'status':'PASS','product':'0.7.1','serialization':53,'metadata':metadata,
                'max_2027_runtime':True,'max_2026_runtime':False,'pointer_qualification':False,'stages':stages,
                'native_build':str(native),'normal_profile_installed':False}
        write_json(out/'result.json',result)
        print('PASS: '+str(out),flush=True)
    finally:
        if not args.keep_open and running():
            if str(folder/'max.ini') not in psutil.Process(process.pid).cmdline():raise RuntimeError('Unrelated Max process')
            process.terminate();process.wait(timeout=30)


if __name__=='__main__':main()
