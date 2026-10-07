"""Staged real-plant load evidence for an already-owned visible Max host.

No existing artist session is discovered or controlled. Whole-process Windows
memory counters are deliberately separate from retained Cyrus payload bytes.
"""
import argparse
import json
from pathlib import Path
import subprocess
import time

from runtime_driver import ROOT, run_script


def resource_sample(pid):
    script = f"""$taskProcess = Get-Process -Id {pid}
    $taskGraphics = @(Get-CimInstance -ClassName Win32_PerfFormattedData_GPUPerformanceCounters_GPUProcessMemory -ErrorAction SilentlyContinue | Where-Object {{ $_.Name -like 'pid_{pid}_*' }} | Select-Object Name,DedicatedUsage,SharedUsage,TotalCommitted)
    [pscustomobject]@{{cpu_s=$taskProcess.CPU;private_bytes=$taskProcess.PrivateMemorySize64;working_bytes=$taskProcess.WorkingSet64;graphics=$taskGraphics}} | ConvertTo-Json -Depth 4 -Compress"""
    return json.loads(subprocess.check_output(["powershell", "-NoProfile", "-Command", script], text=True))


def qualify(folder, stress=False):
    folder = folder.resolve()
    if folder.parent != ROOT / "build/mcp-qualification" or not folder.name.startswith("real073-"):
        raise ValueError("Owned real-asset fixture folder required")
    metadata = json.loads((folder / "launch.json").read_text())
    evidence = dict(pid=metadata["pid"], script_sha256=metadata["script_sha256"], stages=[],
                    metric_limits="CPU/RAM and GPU-process memory include the entire private Max scene and renderer. They do not identify exclusive plugin allocations. The development transport polls independently.")

    def execute(code):
        result = run_script(folder, code, timeout=240)
        if not result.startswith("SUCCESS "):
            raise RuntimeError(result)

    execute('fileIn @"' + (ROOT / "tools/procedural_lab/Max_Real_Assets_073_Load.ms").as_posix() + '"')
    for count in ((10000, 50000, 100000) if stress else (60000, 100000)):
        start = resource_sample(metadata["pid"])
        wall = time.monotonic()
        execute(("Real073Stress " if stress else "Real073Raise ") + str(count))
        elapsed = time.monotonic() - wall
        time.sleep(2)
        end = resource_sample(metadata["pid"])
        label = ("stress_" if stress else "garden_") + str(count)
        stage = json.loads((folder / (label + ".json")).read_text())
        if any(stage["errors"]):
            raise AssertionError(stage)
        evidence["stages"].append(dict(label=label, source=stage, transport_wall_s=elapsed,
                                        host_cpu_s=end["cpu_s"]-start["cpu_s"], before=start, after=end))
        (folder / (("stress" if stress else "garden") + "-resource-stages.json")).write_text(json.dumps(evidence, indent=2)+"\n")
        print(label, "accepted", sum(stage["accepted"]), "generation/publication ms", round(stage["duration_ms"], 2), flush=True)
    evidence["passed"] = True
    (folder / (("stress" if stress else "garden") + "-resource-stages.json")).write_text(json.dumps(evidence, indent=2)+"\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("folder", type=Path)
    parser.add_argument("--stress", action="store_true")
    args = parser.parse_args()
    qualify(args.folder, args.stress)
