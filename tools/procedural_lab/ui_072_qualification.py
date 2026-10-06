"""Qualify real script control events in an explicitly launched private Max.

No computer-use, screenshots, artist scenes or installation. The fixture
transport is private engineering tooling, not MCP authority or a product timer.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import sys
import time

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import launch,digest
from runtime_driver import run_script


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run',required=True)
    parser.add_argument('--native',required=True,type=Path)
    parser.add_argument('--analyzer',required=True,type=Path)
    parser.add_argument('--keep-open',action='store_true')
    parser.add_argument('--full',action='store_true')
    args=parser.parse_args()
    if not re.fullmatch(r'[a-z0-9-]+',args.run):raise ValueError('Invalid private run ID')
    folder=ROOT/'build/mcp-qualification'/('procedural07-ui-072-'+args.run)
    staging=ROOT/'build/ui-072-20261006'/args.run
    staging.mkdir(parents=True,exist_ok=False)
    frozen={}
    for project,directory in [('scatter',args.native),('analyzer',args.analyzer)]:
        receipt=json.loads((directory/'receipt.json').read_text())
        if receipt.get('status')=='pending' or receipt['project']!=project or receipt['max_year']!=2027 or any(s['exit_code'] for s in receipt['stages']):
            raise ValueError('Passing Max 2027 SDK receipt required')
        for name,expected in receipt['sources'].items():
            if digest(ROOT/name)!=expected:raise ValueError('Build source changed: '+name)
            frozen[name]=expected
        for name,expected in receipt['binaries'].items():
            if digest(ROOT/name)!=expected:raise ValueError('Build binary changed: '+name)
            shutil.copy2(ROOT/name,staging/Path(name).name)
    extra='fileIn @"'+(ROOT/'tools/performance/CyrusPerformanceMonitor.ms').as_posix()+'"\n'
    extra+='fileIn @"'+(ROOT/'CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms').as_posix()+'"\n'
    profile=Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini'
    profile_before=digest(profile)
    process,metadata=launch(folder,ROOT/'AminScatter/scripts/AminScatterObject.ms',staging,extra=extra,transport=True,extra_modules=('CyrusSurfaceAnalyzer.dlx',))
    stages=[];succeeded=False
    def execute(label,code):
        result=run_script(folder,code,timeout=600)
        stages.append(dict(stage=label,result=result,fixture_sha256=hashlib.sha256(code.encode()).hexdigest()))
        (staging/'stages.json').write_text(json.dumps(stages,indent=2)+'\n')
        print(label+': '+result.strip(),flush=True)
        if not result.startswith('SUCCESS '):raise RuntimeError(result)
    def fixture(name):
        code=(ROOT/'tools/procedural_lab'/name).read_text(encoding='utf-8-sig')
        return re.sub(r'/procedural07-ui-(?:071-|072-)?',lambda _:'/'+folder.name,code)
    try:
        deadline=time.monotonic()+180
        while not (folder/'ready.json').exists():
            if (folder/'startup-error.txt').exists():raise RuntimeError((folder/'startup-error.txt').read_text())
            if process.poll() is not None or time.monotonic()>deadline:raise RuntimeError('Private Max startup failed')
            time.sleep(.5)
        execute('definitions',fixture('Max_Procedural_07_Acceptance.ms'))
        execute('UI 0.72',fixture('Max_UI_072_Acceptance.ms'))
        execute('Corona stop failure paths',fixture('Max_Corona_Stop_072.ms'))
        report=json.loads((folder/'direct-diagnostics.json').read_text(encoding='utf-8-sig'))
        assert report['schema']=='cyrus.diagnostic-bundle/1.0' and report['training_eligible'] is False
        assert report['native_file_sha256']=={name:value for name,value in metadata['binaries'].items() if name!='CyrusSurfaceAnalyzer.dlx'}
        from importlib.util import spec_from_file_location,module_from_spec
        sys.path.insert(0,str(ROOT/'CyrusMCP'))
        from cyrus_mcp.diagnostics import validate_page
        cursor=0;events=[];session=report['pages'][0]['session_id']
        for page in report['pages']:
            validate_page(json.dumps(page),session,cursor,500)
            assert not page['active'];events.extend(page['events']);cursor=page['next_sequence']
        assert len(events)==report['pages'][0]['health']['retained'] and len(events)>=620
        assert not report['pages'][-1]['has_more']
        if args.full:
            execute('procedural core','P07Acceptance()')
            for name in ['Max_Procedural_07_Bindings.ms','Max_Layer_Editor_071_Acceptance.ms','Max_Layer_Editor_071_BrushLive.ms','Max_Procedural_07_Regression.ms','Max_Source_Containers_Acceptance.ms','Max_Source_Containers_EdgeCases.ms','Max_Source_Containers_Output.ms']:
                execute(name,fixture(name))
            execute('event definitions',fixture('Max_Source_Containers_Events.ms')+'\nSCEventSetup()')
            for stage in ['SCEventPark','SCEventReturn','SCEventEnroll','SCEventFinish','SCEventGroupFinish','SCEventContainerReturn','SCEventGeometry','SCEventGeometryFinish']:
                time.sleep(1);execute(stage,stage+'()')
            execute('retained 100k navigation',fixture('Max_Procedural_07_Navigation.ms')+
                    '\nP07Navigation "ui072-100k" 100000 procedural:true frames:30 modes:#(0,1,3,4) containers:true')
            execute('retained integrated and popup browsing',r'''
                local node=getNodeByName "NAV_Controller",root=node.baseObject,leaf=root.layerObjects[1]
                select node;max modify mode;modPanel.setCurrentObject root
                if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
                root.mainUI.selectLayerView leaf
                local view=CyrusPointOwner node,before=cyrusRetainedStats view,mesh=cyrusRetainedMeshStats view
                local epoch=root.procEpoch,builds=leaf.procPreparedBuilds,key=root.procInputKey()
                local handles=for r in root.mainUI.editors collect r.hwnd
                CyrusOpenLayerEditor root leaf
                for cycle=1 to 3 do (
                    for r in root.mainUI.editors do (r.open=true;root.mainUI.bindSection r;completeRedraw();r.open=false)
                    for topic=1 to 6 do (CyrusLayerEditor.showTopic topic;completeRedraw())
                )
                local after=cyrusRetainedStats view,meshAfter=cyrusRetainedMeshStats view
                for k in #(3,4,5,6,7,9) do P07Assert (before[k]==after[k]) "UI browsing rebuilt/uploaded retained buffers"
                P07Assert (mesh as string==meshAfter as string) "UI browsing changed retained Mesh statistics"
                P07Assert (root.procEpoch==epoch and leaf.procPreparedBuilds==builds and root.procInputKey()==key) "UI browsing regenerated placements"
                P07Assert ((for r in root.mainUI.editors collect r.hwnd) as string==handles as string) "UI browsing replaced native controls"
                CSPWriteText (MCPFixtureDir+"retained-ui-072.json") (CSPObject #(#("population",100000),#("zero_regeneration",true),#("zero_uploads",true),#("native_sections",16),#("popup_topics",6)))
                CyrusCloseLayerEditor()
            ''')
        assert all(digest(ROOT/name)==expected for name,expected in frozen.items()),'Frozen source changed during runtime tests'
        assert digest(profile)==profile_before,'Artist profile changed'
        receipt=dict(passed=True,development_version='0.72',package_version='0.72.0',serialization=53,
                     computer_use=False,artist_scene_opened=False,artist_profile_unchanged=True,
                     script_sha256=metadata['script_sha256'],modules=metadata['binaries'],stages=stages,
                     profile_sha256_before=profile_before,profile_sha256_after=digest(profile),
                     diagnostic_pages=len(report['pages']),diagnostic_events=len(events),
                     loaded_paths_checked=True,normal_profile_installed=False,pointer_test=False,
                     max2027_runtime=True,max2026_runtime=False,full=args.full)
        (staging/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
        succeeded=True
        print('PASS: '+str(staging),flush=True)
    finally:
        if (not args.keep_open or not succeeded) and process.poll() is None:
            process.terminate();process.wait(timeout=30)


if __name__=='__main__':main()
