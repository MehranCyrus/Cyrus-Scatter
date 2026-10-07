"""Actual Corona production/IR checks on an already-owned real-plant scene."""
import argparse
from collections import Counter
import json
from pathlib import Path
import time
from runtime_driver import ROOT, run_script


def qualify(folder):
    folder=folder.resolve()
    if folder.parent!=ROOT/'build/mcp-qualification' or not folder.name.startswith('real073-'):
        raise ValueError('Owned real-asset fixture required')
    metadata=json.loads((folder/'launch.json').read_text())
    evidence=dict(pid=metadata['pid'],script_sha256=metadata['script_sha256'],cases=[],passed=False)
    def save():
        (folder/'real-corona-qualification.json').write_text(json.dumps(evidence,indent=2)+'\n')
    def execute(code):
        result=run_script(folder,code,timeout=300)
        if not result.startswith('SUCCESS '):raise RuntimeError(result)
    def sample(label):
        execute('CSIdleSample Real073Node "'+label+'"')
        return json.loads((folder/(label+'.json')).read_text())
    def quiet(label):
        # Let the delayed Max node/post-render notification batch settle before
        # measuring a quiet window. Do not force a tick or delete bridge nodes.
        time.sleep(3)
        a=sample(label+'-start');time.sleep(12);b=sample(label+'-end')
        keys=('epoch','prepared_builds','preview_builds','container_scans','container_tests','membership_builds','ir_timer_calls','render_key_calls','bridge_builds')
        changes={k:[a[k],b[k]] for k in keys if a[k]!=b[k]}
        for k in (2,3,4,5,6,8):
            if a['retained'] and a['retained'][k]!=b['retained'][k]:changes['upload_'+str(k)]=[a['retained'][k],b['retained'][k]]
        evidence['cases'].append(dict(label=label,before=a,after=b,unexpected_calculation_upload_changes=changes));save()
        if changes:raise AssertionError(changes)
        print('PASS '+label,flush=True);return b
    try:
        execute('fileIn @"'+(ROOT/'tools/procedural_lab/Max_Live_Idle_Probe.ms').as_posix()+'"')
        execute('CyrusStopBrush();cyrusDiagnosticStop();stopAnimation();if isValidNode Real073StressNode do hide Real073StressNode;unhide Real073Node;Real073Root.autoRender=true;Real073Root.updateMode=2;viewport.setCamera (getNodeByName "01 HERO | garden pavilion");clearSelection();max create mode;CyrusViewportRedraw();CSIdleInstall();local s=createFile (MCPFixtureDir+"corona-api.txt");showInterfaces renderers.current to:s;close s')
        time.sleep(5)
        quiet('real-editor-idle')
        execute('renderers.current.system_numThreads=8;renderers.current.interactive_numThreads=8;renderers.current.interactive_passLimit=0;renderers.current.denoise_interactiveMode=0;renderWidth=600;renderHeight=420;cyrusDiagnosticStart "real_assets_ir" 8192 4194304 600000;local status=CoronaRenderer.startInteractive();if status!=0 do throw ("IR start status: "+status as string)')
        for attempt in range(15):
            time.sleep(6)
            execute('CSPWriteText (MCPFixtureDir+"corona-progress.json") (CSPObject #(#("passes",CoronaRenderer.getStatistic 0),#("type",CoronaRenderer.getRenderType()),#("error",CyrusPFLastError)))')
            progress=json.loads((folder/'corona-progress.json').read_text())
            print('IR progress',progress,flush=True)
            if progress['passes']>1:break
        if progress['passes']<=1 or progress['type']!=3 or progress['error']:raise AssertionError(progress)
        baseline=quiet('real-ir-idle')
        execute('global R73IRSeed=Real073Parents[1].randomSeed;Real073Parents[1].randomSeed=R73IRSeed+1;CyrusViewportRedraw()')
        time.sleep(12)
        changed=quiet('real-ir-edited')
        if changed['epoch']!=baseline['epoch']+1 or changed['bridge_builds']!=baseline['bridge_builds']+1:
            raise AssertionError({'baseline':baseline,'edited':changed})
        execute('CSPWriteText (MCPFixtureDir+"real-ir-final.json") (CSPObject #(#("passes",CoronaRenderer.getStatistic 0),#("type",CoronaRenderer.getRenderType()),#("groups",CyrusPFData.count),#("error",CyrusPFLastError),#("accepted",for leaf in Real073Root.layerObjects collect leaf.generatedCount)));local b=CoronaRenderer.getVfbContent 0 true false;if b==undefined do throw "IR bitmap missing";b.filename=MCPFixtureDir+"Real_Garden_IR.png";save b;close b;local status=CoronaRenderer.stopRender();if status!=0 do throw ("IR stop status: "+status as string)')
        stop_started=time.monotonic()
        evidence['stop_observations']=[]
        while True:
            execute('CSPWriteText (MCPFixtureDir+"real-stop-state.json") (CSPObject #(#("type",CoronaRenderer.getRenderType()),#("timer",CyrusPFTimer.Enabled),#("phase",CyrusPFPhase),#("pending",CyrusPFCheckPending),#("resume",CyrusPFResume),#("nodes",CyrusPFNodes.count),#("busy",CyrusPFBusy),#("error",CyrusPFLastError)))')
            state=json.loads((folder/'real-stop-state.json').read_text());state['observed_after_s']=time.monotonic()-stop_started
            evidence['stop_observations'].append(state);save()
            if state['type']==0 and not state['timer'] and not state['pending'] and not state['resume'] and not state['phase'] and not state['nodes'] and not state['busy']:break
            if time.monotonic()-stop_started>15:raise AssertionError({'bounded_stop_cleanup_failed':state})
            time.sleep(1)
        quiet('real-after-stop-idle')
        execute('cyrusDiagnosticStop();CSPWriteText (MCPFixtureDir+"real-ir-trace.json") (cyrusDiagnosticSnapshot 0 500);if CyrusPFTimer.Enabled or CyrusPFNodes.count!=0 do throw "IR stop left bridge nodes/timer";Real073Parents[1].randomSeed=R73IRSeed;CyrusViewportRedraw()')
        trace=json.loads((folder/'real-ir-trace.json').read_text());events=Counter(e['name'] for e in trace['events'])
        while trace['has_more']:
            execute('CSPWriteText (MCPFixtureDir+"real-ir-trace-page.json") (cyrusDiagnosticSnapshot '+str(trace['next_sequence'])+' 500)')
            page=json.loads((folder/'real-ir-trace-page.json').read_text())
            trace['events'].extend(page['events']);trace['has_more']=page['has_more'];trace['next_sequence']=page['next_sequence']
        (folder/'real-ir-trace.json').write_text(json.dumps(trace,indent=2)+'\n')
        events=Counter(e['name'] for e in trace['events'])
        if trace['last_sequence']!=len(trace['events']):raise AssertionError('Incomplete diagnostic page')
        if events['ir.stop_requested']!=1 or events['ir.start_requested']!=1:raise AssertionError(events)
        evidence['ir_events']=dict(events);evidence['ir_health']=trace['health'];evidence['ir']=json.loads((folder/'real-ir-final.json').read_text());save()
        print('PASS one IR stop/start for one real recipe edit',flush=True)
        execute('renderers.current.progressive_passLimit=4;renderers.current.progressive_timeLimit=0;local before=CyrusPFBuilds,epoch=Real073Root.procEpoch,start=timeStamp();local b=render camera:(getNodeByName "01 HERO | garden pavilion") vfb:false outputfile:(MCPFixtureDir+"Real_Garden_Production.png");if b==undefined do throw "Production bitmap missing";close b;CSPWriteText (MCPFixtureDir+"real-production.json") (CSPObject #(#("duration_ms",timeStamp()-start),#("bridge_builds",CyrusPFBuilds-before),#("epoch_before",epoch),#("epoch_after",Real073Root.procEpoch),#("error",CyrusPFLastError),#("pass_limit",4)))')
        evidence['production']=json.loads((folder/'real-production.json').read_text())
        result=evidence['production']
        if result['bridge_builds']!=1 or result['error'] or result['epoch_before']!=result['epoch_after']:raise AssertionError(result)
        evidence['passed']=True;evidence['visual_review_required']=True;save()
        print('PASS actual production/IR scheduling; review saved pixels separately',flush=True)
    except Exception as exc:
        evidence['error']=str(exc);save();raise
    finally:
        execute('try(CoronaRenderer.stopRender())catch();cyrusDiagnosticStop();CSIdleRemove()')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('folder',type=Path)
    qualify(parser.parse_args().folder)
