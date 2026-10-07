"""Measure one explicitly owned real-asset Max process, with QPC-aligned ETW.

Presented/display timing, synchronous drawing, publication reuse and whole-host
resources are separate measurements. This does not open an artist session.
"""
import argparse
from collections import Counter
import csv
import hashlib
import json
from pathlib import Path
import statistics
import subprocess
import time

from runtime_driver import ROOT, run_script
from real_assets_073_load import resource_sample

PRESENTMON = ROOT / "build/heavy-viewport-2026-10-02/PresentMon-2.6.0-x64.exe"


def summary(values):
    values = sorted(values)
    return dict(n=len(values), median=statistics.median(values), p95=values[min(len(values)-1, int(.95*len(values)))]) if values else dict(n=0)


def analyze(path, phases, pid):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        rows = [r for r in csv.DictReader(stream) if int(r["ProcessID"]) == pid]
    if not rows:
        return {"available": False, "reason": "No owned-process ETW rows; no FPS inference"}
    clock = next(k for k in ("CPUStartQPCTimeInMs", "CPUStartQPCTime") if k in rows[0])
    arms = []
    for phase in phases:
        selected = [r for r in rows if r.get(clock) not in ("", "NA") and phase["begin_qpc_ms"] <= float(r[clock]) <= phase["end_qpc_ms"]]
        chains = Counter(r["SwapChainAddress"] for r in selected)
        main = chains.most_common(1)[0][0] if chains else None
        selected = [r for r in selected if r["SwapChainAddress"] == main]
        metrics = {}
        for key in ("MsBetweenAppStart", "MsBetweenPresents", "MsBetweenDisplayChange", "DisplayedTime", "MsCPUBusy", "MsGPUBusy", "MsGPUTime", "DisplayLatency"):
            metrics[key] = summary([float(r[key]) for r in selected if r.get(key) not in (None, "", "NA")])
        arms.append(dict(label=phase["label"], chain_counts=dict(chains), selected_chain=main, presents=len(selected),
                         modes=dict(Counter(r["PresentMode"] for r in selected)), metrics_ms=metrics))
    return dict(available=True, clock_column=clock, arms=arms,
                limits="Dominant swap chain per phase. DisplayedTime excludes unavailable/dropped rows; presentation does not guarantee screen FPS. Whole Max scene/GPU work, not isolated plugin timing. No calibrated input-to-photon latency.")


def qualify(folder, target="stress", kind="navigation"):
    folder = folder.resolve()
    if folder.parent != ROOT / "build/mcp-qualification" or not folder.name.startswith("real073-"):
        raise ValueError("Owned real-asset folder required")
    metadata = json.loads((folder / "launch.json").read_text())
    pid = metadata["pid"]
    session = f"Cyrus073_{pid}_{target}_{kind}_{time.time_ns()}"
    label = f"{target}-{kind}"
    initial=label;attempt=1
    while (folder/(label+'-performance.json')).exists():
        attempt+=1;label=initial+'-'+str(attempt)
    csv_path = folder / (label + "-presentmon.csv")
    log = (folder / (label + "-presentmon.log")).open("w")
    capture = subprocess.Popen([str(PRESENTMON), "--process_id", str(pid), "--session_name", session,
                                "--output_file", str(csv_path), "--qpc_time_ms", "--timed", "240",
                                "--terminate_after_timed", "--no_console_stats"], stdout=log, stderr=log)
    evidence = dict(pid=pid, script_sha256=metadata["script_sha256"], target=target, kind=kind, phases=[],
                    presentmon_sha256=hashlib.sha256(PRESENTMON.read_bytes()).hexdigest(),
                    measurement_limits="Resource counters include whole Max, asset geometry/materials/renderer and private transport polling; no exclusive Cyrus RAM/VRAM claim.")
    def execute(code):
        result = run_script(folder, code, timeout=240)
        if not result.startswith("SUCCESS "):
            raise RuntimeError(result)
    node = "Real073StressNode" if target == "stress" else "Real073Node"
    root = "Real073StressRoot" if target == "stress" else "Real073Root"
    try:
        time.sleep(2)
        if capture.poll() is not None:
            raise RuntimeError("PresentMon did not start; inspect log without elevation")
        if kind == "navigation":
            for mode in range(5):
                phase_label = f"{label}-{mode}"
                before = resource_sample(pid)
                execute(f'Real073Navigate {node} "{phase_label}" frames:20 modes:#({mode})')
                data = json.loads((folder / (phase_label+"-navigation.json")).read_text())
                row = dict(data["trials"][0]);row["label"] = phase_label
                row.update(viewport=data["viewport"], before_resource=before, after_resource=resource_sample(pid))
                evidence["phases"].append(row)
                print(phase_label, "median synchronous ms", round(statistics.median(row["step_ms"]), 2), flush=True)
        else:
            execute('fileIn @"'+(ROOT/'tools/procedural_lab/Max_Live_Idle_Probe.ms').as_posix()+'"')
            execute('Real073Car();CSIdleRemove();CSIdleInstall();global R73PerfRoot='+root+',R73PerfNode='+node+',R73PerfBegin,R73PerfStop;fn R73PerfStop = (if (dotNetClass "System.Diagnostics.Stopwatch").GetTimestamp() as double/(dotNetClass "System.Diagnostics.Stopwatch").Frequency*1000.0-R73PerfBegin>=10000.0 do stopAnimation())')
            arms=((0,1,False),(1,1,True)) if kind=='enabled' else ((0,1,True),(1,1,True),(1,2,True),(3,1,True),(3,2,True))
            for display, update, enabled in arms:
                phase_label=f"{label}-{display}-{update}"
                execute(f'R73PerfRoot.updateMode={update};R73PerfRoot.cyrusEnabled={str(enabled).lower()};R73PerfRoot.showPoints={str(display!=0).lower()};if {display}==0 do R73PerfRoot.groupCenters=false;if {display}!=0 do R73PerfRoot.setGroupDisplay {display};R73PerfRoot.refreshDisplay();sliderTime=0;CyrusViewportRedraw();for i=1 to 8 do (completeRedraw();windows.processPostedMessages());for leaf in R73PerfRoot.layerObjects where leaf.previewError!="" do throw leaf.previewError')
                time.sleep(3)
                before=resource_sample(pid)
                execute('CSIdleSample R73PerfNode "'+phase_label+'-before";R73PerfBegin=(dotNetClass "System.Diagnostics.Stopwatch").GetTimestamp() as double/(dotNetClass "System.Diagnostics.Stopwatch").Frequency*1000.0;registerTimeCallback R73PerfStop;playAnimation();unregisterTimeCallback R73PerfStop')
                after=resource_sample(pid)
                execute('stopAnimation();local finish=(dotNetClass "System.Diagnostics.Stopwatch").GetTimestamp() as double/(dotNetClass "System.Diagnostics.Stopwatch").Frequency*1000.0;CSIdleSample R73PerfNode "'+phase_label+'-after";CSPWriteText (MCPFixtureDir+"'+phase_label+'-clock.json") (CSPObject #(#("begin_qpc_ms",R73PerfBegin),#("end_qpc_ms",finish)))')
                a=json.loads((folder/(phase_label+'-before.json')).read_text());b=json.loads((folder/(phase_label+'-after.json')).read_text())
                keys=("epoch","prepared_builds","preview_builds","container_scans","container_tests","membership_builds","bridge_builds")
                changes={k:[a[k],b[k]] for k in keys if a[k]!=b[k]}
                for k in (2,3,4,5,6,8):
                    if a["retained"] and a["retained"][k]!=b["retained"][k]:changes['retained_'+str(k)]=[a['retained'][k],b['retained'][k]]
                row=dict(label=phase_label, display=display, update=update, controller_enabled=enabled, unexpected_calculation_upload_changes=changes,
                         before=a, after=b, before_resource=before, after_resource=after,
                         **json.loads((folder/(phase_label+'-clock.json')).read_text()))
                evidence["phases"].append(row)
                print(phase_label, "unchanged calculations/uploads", not changes, flush=True)
                if changes:raise AssertionError(row)
            execute('stopAnimation();unregisterTimeCallback R73PerfStop;CSIdleRemove();sliderTime=0')
        evidence["passed"]=True
    except Exception as exc:
        evidence["passed"]=False;evidence["error"]=str(exc)
        raise
    finally:
        subprocess.run([str(PRESENTMON),"--session_name",session,"--terminate_existing_session"],stdout=log,stderr=log)
        try:capture.wait(timeout=15)
        except subprocess.TimeoutExpired:capture.terminate();capture.wait(timeout=10)
        log.close()
        evidence["capture_exit_code"]=capture.returncode
        if csv_path.is_file() and csv_path.stat().st_size:
            evidence["presentmon"]=analyze(csv_path,evidence["phases"],pid)
        (folder/(label+"-performance.json")).write_text(json.dumps(evidence,indent=2)+"\n")


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("folder",type=Path)
    parser.add_argument("--target",choices=("garden","stress"),default="stress")
    parser.add_argument("--kind",choices=("navigation","playback","enabled"),default="navigation")
    args=parser.parse_args();qualify(args.folder,args.target,args.kind)
