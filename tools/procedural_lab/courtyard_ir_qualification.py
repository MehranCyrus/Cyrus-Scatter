"""Corona idle/edit/output checks on a disposable copy of the supplied courtyard."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import shutil
import time

from runtime_driver import ROOT, run_script


def qualify(folder):
    source=ROOT/"Test Scene/Cyrus_071_Courtyard/Cyrus_071_Garden_Pavilion.max"
    before=hashlib.sha256(source.read_bytes()).hexdigest()
    copied=folder/"Courtyard_private.max";shutil.copy2(source,copied)
    evidence={"scene_original_sha256":before,"scene_copy_sha256":hashlib.sha256(copied.read_bytes()).hexdigest(),"cases":[]}
    def execute(code):
        result=run_script(folder,code,timeout=300)
        assert result.startswith("SUCCESS "),result
    def sample(label):
        execute('CSIdleSample P07Node "'+label+'"')
        return json.loads((folder/(label+".json")).read_text())
    def idle(label):
        a=sample(label+"-start");time.sleep(12);b=sample(label+"-end")
        keys=("epoch","prepared_builds","preview_builds","container_scans","container_tests",
              "membership_builds","interaction_checks","ir_timer_calls","render_key_calls","bridge_builds","retained","retained_mesh")
        changed={k:[a[k],b[k]] for k in keys if a[k]!=b[k]}
        row={"case":label,"unexpected_changes":changed,"start":a,"end":b}
        evidence["cases"].append(row)
        (folder/"courtyard-runtime.json").write_text(json.dumps(evidence,indent=2)+"\n")
        assert not changed,row
        print("PASS "+label,flush=True)
        return b
    execute('cyrusDiagnosticStop();CSIdleRemove();loadMaxFile @"'+copied.as_posix()+'" quiet:true useFileUnits:true;global P07Node=(for n in objects where classof n.baseObject==AminScatterObject collect n)[1],P07Root=P07Node.baseObject,P07Layer=P07Root.layerObjects[1];fileIn @"'+(ROOT/"tools/real_scene_071/relink.ms").as_posix()+'";P07Root.autoRender=true;P07Root.updateMode=2;P07Root.refreshAll();select P07Node;max modify mode;CyrusOpenLayerEditor P07Root P07Layer;CSIdleInstall();CSPWriteText (MCPFixtureDir+"courtyard-loaded-payload.txt") CyrusLoadedScriptFingerprint')
    evidence["loaded_payload_sha256"]=(folder/"courtyard-loaded-payload.txt").read_text()
    time.sleep(5)
    idle("courtyard-editor-idle")
    execute('renderers.current.system_numThreads=8;renderers.current.interactive_numThreads=8;renderers.current.interactive_passLimit=0;renderers.current.denoise_interactiveMode=0;renderWidth=600;renderHeight=420;viewport.setCamera (getNodeByName "01 HERO | garden pavilion");cyrusDiagnosticStart "courtyard_final_ir" 4096 4194304 600000;local result=CoronaRenderer.startInteractive();if result!=0 do throw ("IR start failed: "+result as string)')
    time.sleep(12)
    base=idle("courtyard-ir-idle")
    execute('P07Layer.amount+=10')
    time.sleep(12)
    changed=idle("courtyard-ir-edited")
    assert changed["epoch"]==base["epoch"]+1,(base,changed)
    assert changed["bridge_builds"]==base["bridge_builds"]+1,(base,changed)
    execute('CSPWriteText (MCPFixtureDir+"courtyard-ir-stats.json") (CSPObject #(#("passes",CoronaRenderer.getStatistic 0),#("render_type",CoronaRenderer.getRenderType()),#("pflow_groups",CyrusPFData.count),#("counts",for leaf in P07Root.layerObjects collect leaf.generatedCount),#("error",CyrusPFLastError)));local bitmap=CoronaRenderer.getVfbContent 0 true false;if bitmap==undefined do throw "IR has no bitmap";bitmap.filename=MCPFixtureDir+"Courtyard_IR.png";save bitmap;close bitmap;local result=CoronaRenderer.stopRender();if result!=0 do throw "IR stop failed"')
    time.sleep(3)
    execute('cyrusDiagnosticStop();CSPWriteText (MCPFixtureDir+"courtyard-ir-trace.json") (cyrusDiagnosticSnapshot 0 500);if CyrusPFTimer.Enabled or CyrusPFNodes.count!=0 do throw "User stop left active bridge/timer"')
    trace=json.loads((folder/"courtyard-ir-trace.json").read_text())
    assert trace["last_sequence"]==len(trace["events"]),"Export additional pages before claiming complete trace"
    events=Counter(e["name"] for e in trace["events"])
    assert events["ir.stop_requested"]==1 and events["ir.start_requested"]==1,events
    evidence["ir_events"]=dict(events);evidence["ir_recording_health"]=trace["health"]
    evidence["ir_stats"]=json.loads((folder/"courtyard-ir-stats.json").read_text())
    assert evidence["ir_stats"]["passes"]>1 and evidence["ir_stats"]["render_type"]==3 and not evidence["ir_stats"]["error"]
    execute('renderers.current.progressive_passLimit=4;renderers.current.progressive_timeLimit=0;local before=CyrusPFBuilds,epoch=P07Root.procEpoch,start=timeStamp();local bitmap=render camera:(getNodeByName "01 HERO | garden pavilion") vfb:false outputfile:(MCPFixtureDir+"Courtyard_Production.png");if bitmap==undefined do throw "Production has no bitmap";close bitmap;CSPWriteText (MCPFixtureDir+"courtyard-production.json") (CSPObject #(#("duration_ms",timeStamp()-start),#("bridge_builds",CyrusPFBuilds-before),#("epoch_before",epoch),#("epoch_after",P07Root.procEpoch),#("error",CyrusPFLastError),#("pass_limit",4)))')
    evidence["production"]=json.loads((folder/"courtyard-production.json").read_text())
    assert evidence["production"]["bridge_builds"]==1 and not evidence["production"]["error"]
    assert evidence["production"]["epoch_before"]==evidence["production"]["epoch_after"]
    # A real unavailable docked viewport must fail once and leave no retry loop.
    time.sleep(3)
    execute('if not CyrusPFBuild() do throw CyrusPFLastError;local staged=CyrusPFNodes.count;CyrusPFLastError="";CyrusPFResumeMode=2;CyrusPFPhase=2;CyrusPFCheckPending=true;CyrusPFTick undefined undefined;CSPWriteText (MCPFixtureDir+"docked-unavailable.json") (CSPObject #(#("error",CyrusPFLastError),#("timer",CyrusPFTimer.Enabled),#("phase",CyrusPFPhase),#("resume",CyrusPFResume),#("nodes_before",staged),#("nodes_after",CyrusPFNodes.count),#("render_type",CoronaRenderer.getRenderType())));if CyrusPFLastError=="" or CyrusPFTimer.Enabled or CyrusPFPhase!=0 or CyrusPFNodes.count!=0 do throw "Unavailable docked IR was not bounded or cleaned up"')
    evidence["docked_failure"]=json.loads((folder/"docked-unavailable.json").read_text())
    assert hashlib.sha256(source.read_bytes()).hexdigest()==before,"Original artist scene changed"
    evidence["original_unchanged"]=True;evidence["scheduling_passed"]=True
    evidence["artifact_visual_review_required"]=True
    (folder/"courtyard-runtime.json").write_text(json.dumps(evidence,indent=2)+"\n")
    print("PASS courtyard scheduling/output/failed-resume checks; inspect rendered images separately",flush=True)


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument("folder",type=Path)
    folder=parser.parse_args().folder.resolve()
    if folder.parent!=ROOT/"build/mcp-qualification":raise ValueError("Private host folder required")
    qualify(folder)
