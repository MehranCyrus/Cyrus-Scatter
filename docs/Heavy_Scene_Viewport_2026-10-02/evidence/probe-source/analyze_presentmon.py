"""Correlate PresentMon QPC timestamps with the controlled camera-step cases."""
from collections import Counter
from pathlib import Path
import csv
import json
import sys
from analyze import percentile
import statistics


def summary(rows, key):
    values = [float(row[key]) for row in rows if row.get(key) not in (None, "NA", "")]
    return {"n": len(values), "median": statistics.median(values), "p95": percentile(values, .95)} if values else {"n": 0}


def main():
    folder = Path(sys.argv[1])
    with (folder / "presentmon-official.csv").open(encoding="utf-8-sig", newline="") as stream:
        rows = list(csv.DictReader(stream))
    cases = json.loads((folder / "points250000-presentmon-cases.json").read_text())
    # Version 2.6's header spelling differs from the README example; do not assume relative time.
    key = next(k for k in ("CPUStartQPCTimeInMs", "CPUStartQPCTime") if k in rows[0])
    trial_rows = []
    for case in cases:
        for row in rows:
            if row[key] in ("NA", ""):
                continue
            start = float(row[key])
            duration = float(row["MsBetweenAppStart"]) if row.get("MsBetweenAppStart") not in (None, "NA", "") else 0
            if case["begin_qpc_ms"] <= start and start + duration <= case["end_qpc_ms"]:
                trial_rows.append((case, row))
    chains = Counter(row["SwapChainAddress"] for _, row in trial_rows)
    if not chains:
        raise RuntimeError("No QPC-aligned presentation rows; do not infer frame timing")
    main_chain = chains.most_common(1)[0][0]
    result = {"source": "PresentMon 2.6.0 signed Intel release", "clock_column": key, "chain_counts": dict(chains), "selected_chain": main_chain, "arms": {}}
    for arm in ("off", "gw", "retained"):
        selected = [row for case, row in trial_rows if case["arm"] == arm and row["SwapChainAddress"] == main_chain]
        metrics = {k: summary(selected, k) for k in ("MsBetweenPresents", "MsBetweenDisplayChange", "MsCPUBusy", "MsGPUBusy", "MsGPUTime", "MsUntilDisplayed")}
        result["arms"][arm] = {"presents": len(selected), "presentation_modes": dict(Counter(row["PresentMode"] for row in selected)), "metrics_ms": metrics}
    result["limits"] = "Scripted completeRedraw throughput. Present interval is not guaranteed screen FPS; composed presentation and unavailable display intervals remain explicit. No calibrated input-to-photon measurement. GPU busy is process/frame work, not isolated plugin GPU timing."
    (folder / "presentmon-summary.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
