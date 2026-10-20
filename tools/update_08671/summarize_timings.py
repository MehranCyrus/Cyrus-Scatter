"""Summarize sequential owned-host probes without conflating first and full readiness."""
from pathlib import Path
import json
import statistics

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / "build/update-08671-20261020"
result = {
    "scope": "Sequential Max 2027 private profiles on the same workstation; empty Manual controller; ten observations per condition; OS load is uncontrolled.",
    "units": "milliseconds",
    "versions": {},
}
for version, folder in (("0.86.7", "update08671-baseline-final"),
                        ("0.86.7.1", "update08671-panel-final")):
    data = json.loads((WORK / folder / "panel-probe.json").read_text())
    assert data["status"] == "complete" and len(data["samples"]) == 20
    assert data["version"] == version
    for sample in data["samples"]:
        assert sample["epoch"] == sample["epoch_after_bind"]
        for phase in ("native_diagnostics", "warm_diagnostics"):
            for stage in sample[phase]["measurements"]["stages"]:
                if not stage["stage"].startswith("ui_"):
                    assert stage["calls"] == 0, stage
    summaries = {}
    for prefix in ("two", "all"):
        samples = [s for s in data["samples"] if s["case"].startswith(prefix)]
        summaries[prefix] = {
            metric: {name: round(fn(s[metric] for s in samples), 2)
                     for name, fn in (("median", statistics.median), ("min", min), ("max", max))}
            for metric in ("first_interactive_observed_ms", "ready_observed_ms", "warm_bind_ms")
        }
    result["versions"][version] = summaries
result["non_ui_stage_calls"] = 0
(WORK / "panel-comparison.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps(result, indent=2))
