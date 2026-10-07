"""Current 0.73 idle checks using actual control handlers and explicit scripted redraw signals.

The development transport polls independently. CPU measures the whole host;
plugin assertions use passive counters and never call a calculation key.
"""
import argparse
import json
from pathlib import Path
import statistics
import subprocess
import time

from runtime_driver import ROOT, run_script


def qualify(folder, integrated=False):
    metadata=json.loads((folder/"launch.json").read_text())
    evidence={"private_host_pid":metadata["pid"],"launch_script_sha256":metadata["script_sha256"],"integrated_sections_open":integrated,"cases":[],"parameter_edits":"Live mode/count use actual Modify handlers; direct texture and invalid-value fixture writes explicitly request redraw, as authoring callers must."}
    def execute(code):
        result=run_script(folder,code,timeout=90)
        if not result.startswith("SUCCESS "):raise AssertionError(result)
    def sample(label):
        execute('CSIdleSample P07Node "'+label+'"')
        return json.loads((folder/(label+".json")).read_text())
    def cpu():
        script='Get-Process -Id '+str(metadata["pid"])+" | Select-Object @{N='cpu_s';E={$_.CPU}},WorkingSet64,PrivateMemorySize64 | ConvertTo-Json -Compress"
        return json.loads(subprocess.check_output(["powershell","-NoProfile","-Command",script],text=True))
    def quiet(label,seconds=10):
        time.sleep(3)
        before=sample(label+"-start");host0=cpu();start=time.monotonic()
        time.sleep(seconds)
        after=sample(label+"-end");host1=cpu();elapsed=time.monotonic()-start
        fields=("epoch","prepared_builds","preview_builds","container_scans","container_tests",
                "membership_builds","ir_timer_calls","render_key_calls",
                "bridge_builds","live_callbacks","live_redraw_requests","retained_mesh")
        changes={k:[before[k],after[k]] for k in fields if before[k]!=after[k]}
        # Max can redraw while a scene is otherwise unchanged. Retained index 8
        # is the global draw count; the interaction query also services draws.
        # Neither proves an idle solver or upload. Assert actual work/identity
        # and timer inactivity, while retaining both callback observations.
        retained_before=[v for i,v in enumerate(before['retained']) if i!=7]
        retained_after=[v for i,v in enumerate(after['retained']) if i!=7]
        if retained_before!=retained_after:changes['retained_work']=[retained_before,retained_after]
        if any(before['plugin_timers']) or any(after['plugin_timers']) or before['animation_playing'] or after['animation_playing']:
            changes['active_timer_or_animation']=[before['plugin_timers'],after['plugin_timers'],before['animation_playing'],after['animation_playing']]
        row=dict(case=label,elapsed_s=elapsed,unexpected_changes=changes,
                 draw_callback_observations=dict(interaction_queries=after['interaction_checks']-before['interaction_checks'],retained_draws=(after['retained'][7]-before['retained'][7]) if after['retained'] else 0),
                 host_cpu_s=host1["cpu_s"]-host0["cpu_s"],host_memory_start=host0,host_memory_end=host1)
        evidence["cases"].append(row)
        (folder/"idle-qualification.json").write_text(json.dumps(evidence,indent=2)+"\n")
        assert not changes,row
        print("PASS "+label,flush=True)
    execute('global CSIdleInstall,CSIdleSample,CSIdleRemove;if CSIdleRemove!=undefined do CSIdleRemove();fileIn @"'+(ROOT/"tools/procedural_lab/Max_Live_Idle_Probe.ms").as_posix()+'";CSIdleInstall();P07New count:400;P07Case="Live idle qualification";P07Root.updateMode=2;P07Root.refreshAll()')
    execute('CSPWriteText (MCPFixtureDir+"idle-loaded-payload.txt") CyrusLoadedScriptFingerprint')
    evidence["loaded_payload_sha256"]=(folder/"idle-loaded-payload.txt").read_text()
    quiet("live-closed")
    execute("select P07Node;max modify mode;CyrusOpenLayerEditor P07Root P07Layer")
    if integrated:
        execute('if not P07Root.mainUI.controlsReady do P07Root.mainUI.mountTimer.tick();for section in P07Root.mainUI.editors do section.open=true;P07Root.mainUI.bindEditors();CyrusLayerEditor.showTopic 5;P07Root.statisticsUI.open=true;P07Root.mainUI.bindSection P07Root.statisticsUI')
    quiet("live-editor-open")
    execute("P07Root.updateMode=1;P07Layer.amount=500")
    quiet("manual-pending")
    execute('P07Assert (P07Layer.generatedCount==400 and P07Layer.dirty) "Manual edit evaluated itself";P07Root.mainUI.updateRadio.changed 2;P07Root.populationUI.distributionUI_countSpin.changed 600')
    quiet("live-real-edit")
    execute('P07Assert (P07Layer.generatedCount==600 and not P07Layer.dirty) "Live edit did not publish";P07Layer.distributionMode=3;P07Layer.densityMap=Checker color1:black color2:black;P07Root.refreshAll()')
    time.sleep(3)
    execute('P07Assert (P07Layer.generatedCount==0) "Black density not empty";P07Layer.densityMap.color1=white;P07Layer.densityMap.color2=white;CyrusViewportRedraw()')
    quiet("live-density-edit")
    execute('P07Assert (P07Layer.generatedCount==600 and not P07Layer.dirty) "In-place density change did not publish";global CSRecoveryEpoch=P07Root.procEpoch;P07Layer.procAttemptFactor=0;CyrusViewportRedraw()')
    quiet("failed-successor")
    execute('P07Assert (P07Layer.generatedCount==600 and P07Layer.previewError!="") "Failure did not preserve result and expose error";P07Layer.procAttemptFactor=8;CyrusViewportRedraw()')
    quiet("restored-valid-recipe")
    execute('P07Assert (P07Layer.previewError=="" and P07Root.procEpoch==CSRecoveryEpoch) "Cached recovery kept stale error or republished";CyrusCloseLayerEditor()')
    # Interleave recording off/on in one warmed scene; timings include host and
    # test-call overhead and are evidence, not an FPS or throughput guarantee.
    execute('global CSOverhead=#();for phase=1 to 6 do (local enabled=(mod phase 2)==0;if enabled then cyrusDiagnosticStart ("overhead_"+phase as string) 4096 4194304 600000 else cyrusDiagnosticStop();local rows=#();for i=1 to 8 do (P07Layer.randomSeed=100+phase*8+i;local start=timeStamp();P07Root.refreshAll();append rows (timeStamp()-start));append CSOverhead #(enabled,rows));cyrusDiagnosticStop();CSPWriteText (MCPFixtureDir+"diagnostic-overhead.json") (CSPJson CSOverhead)')
    overhead=json.loads((folder/"diagnostic-overhead.json").read_text())
    evidence["diagnostic_overhead"]={str(enabled):dict(samples_ms=[v for on,rows in overhead if on==enabled for v in rows],median_ms=statistics.median([v for on,rows in overhead if on==enabled for v in rows])) for enabled in (False,True)}
    quiet("after-diagnostic-recording")
    evidence["passed"]=True
    (folder/"idle-qualification.json").write_text(json.dumps(evidence,indent=2)+"\n")
    print("PASS idle/change/failure/overhead qualification",flush=True)


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument("folder",type=Path)
    parser.add_argument('--integrated',action='store_true',help='Keep every native selected-layer section and Diagnostics open alongside the optional popup')
    args=parser.parse_args();folder=args.folder.resolve()
    if folder.parent!=ROOT/"build/mcp-qualification":raise ValueError("Private host folder required")
    qualify(folder,integrated=args.integrated)
