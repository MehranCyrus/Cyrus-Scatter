"""Summarize CyrusViewportBenchmark recordings without treating them as GPU frames."""
import argparse
import csv
import json
import math
import statistics
from pathlib import Path


def summarize(directory):
    directory = Path(directory)
    with (directory / "frames.csv").open(encoding="utf-8-sig", newline="") as stream:
        rows = list(csv.DictReader(stream))
    cases = json.loads((directory / "cases.json").read_text(encoding="utf-8-sig"))
    result = {"scope": "Synchronous camera change, redraw and message-pump wall time; no GPU completion fence",
              "directory": str(directory), "frame_count": len(rows), "cases": {}}
    for label in dict.fromkeys(row["case"] for row in rows):
        subset = [row for row in rows if row["case"] == label]
        metadata = [case for case in cases if case["label"] == label]
        metrics = {}
        for key in ("wall_ms", "scatter_callback_ms", "analyzer_callback_ms", "scatter_calls", "analyzer_calls"):
            values = sorted(float(row[key]) for row in subset)
            if any(not math.isfinite(value) or value < 0 for value in values):
                raise ValueError(f"Invalid {label} {key}")
            metrics[key] = {"median": statistics.median(values),
                            "p95": values[math.ceil(len(values) * .95) - 1] if len(values) >= 20 else None,
                            "mean": statistics.mean(values), "min": min(values), "max": max(values)}
        rebuilds = []
        populations = []
        errors = []
        analyzer_deltas = []
        pflow_deltas = []
        for case in metadata:
            before, after = case["before_measured"], case["after_measured"]
            if [(x[0], x[1]) for x in before] != [(x[0], x[1]) for x in after]:
                raise ValueError("Layer identity changed during a trial")
            rebuilds.append(sum(b[8] - a[8] for a, b in zip(before, after)))
            populations.append({"generated": sum(x[5] for x in after), "cache_display_count": sum(x[6] for x in after),
                                "cache_triangles": sum(x[7] for x in after),
                                "stable_during_measurement": all(a[3:9] == b[3:9] for a, b in zip(before, after))})
            errors.extend(x[10] for x in after if x[10])
            analyzer_deltas.append(sum(b-a for a, b in zip(case["analyzer_before_measured"], case["analyzer_after"])))
            pflow_deltas.append(case["pflow_after"] - case["pflow_before"])
        result["cases"][label] = {
            "samples": len(subset), "metrics": metrics,
            "repeat_median_wall_ms": {r: statistics.median(float(x["wall_ms"]) for x in subset if x["repeat"] == r)
                                      for r in dict.fromkeys(x["repeat"] for x in subset)},
            "preview_rebuild_deltas": rebuilds, "analyzer_run_deltas": analyzer_deltas,
            "pflow_build_deltas": pflow_deltas, "populations": populations, "errors": errors,
            "reciprocal_median_wall_rate_not_presented_fps": 1000 / metrics["wall_ms"]["median"],
        }
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directories", type=Path, nargs="+")
    args = parser.parse_args()
    for directory in args.directories:
        result = summarize(directory)
        (directory / "summary.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
        for label, case in result["cases"].items():
            print(f'{directory.name}: {label}: median {case["metrics"]["wall_ms"]["median"]:.2f} ms, '
                  f'p95 {case["metrics"]["wall_ms"]["p95"]:.2f} ms, {case["samples"]} samples, '
                  f'rebuilds {case["preview_rebuild_deltas"]}')


if __name__ == "__main__":
    main()
