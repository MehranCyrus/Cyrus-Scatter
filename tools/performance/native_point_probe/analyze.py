"""Analyze the verified full-redraw experiment; never relabel it as completed FPS."""
from pathlib import Path
import csv
import json
import math
import statistics
import argparse


def percentile(values, fraction):
    values = sorted(values)
    index = (len(values) - 1) * fraction
    lo, hi = math.floor(index), math.ceil(index)
    return values[lo] + (values[hi] - values[lo]) * (index - lo)


def summarize(rows, field):
    values = [float(row[field]) for row in rows]
    return {"n": len(values), "median": statistics.median(values), "p95": percentile(values, .95), "p99": percentile(values, .99), "mean": statistics.fmean(values)}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("folder", type=Path)
    args = parser.parse_args()
    results = []
    for case_file in sorted(args.folder.glob("points*-cases.json")):
        name = case_file.name.removesuffix("-cases.json")
        cases = json.loads(case_file.read_text(encoding="utf-8-sig"))
        fixture = json.loads((args.folder / f"{name}-fixture.json").read_text(encoding="utf-8-sig"))
        with (args.folder / f"{name}-frames.csv").open(encoding="utf-8-sig", newline="") as stream:
            rows = list(csv.DictReader(stream))
        validation = []
        for case in cases:
            before, after = case["before"], case["after"]
            selected = [row for row in rows if row["arm"] == case["arm"] and int(row["repeat"]) == case["repeat"]]
            assert selected, (name, "missing frames")
            assert before[0] == after[0] == fixture["actual_points"], (name, "point count")
            assert before[2] == after[2] and before[10] == after[10], (name, "data changed")
            assert after[8] == 0, (name, "GPU initialization failure")
            if case["arm"] == "retained":
                assert before[5] == after[5], (name, "upload during navigation")
                assert after[7] - before[7] >= len(selected), (name, "renderer not exercised")
            validation.append({"arm": case["arm"], "repeat": case["repeat"], "frames": len(selected), "draw_increment": after[7] - before[7], "upload_increment": after[5] - before[5], "prepare_increment": after[3] - before[3], "node_update_increment": after[4] - before[4]})
        arms = {}
        for arm in ["off", "gw", "retained"]:
            selected = [row for row in rows if row["arm"] == arm]
            arms[arm] = {
                "step_ms": summarize(selected, "step_ms"),
                "callback_ms": summarize(selected, "callback_ms"),
                "callback_calls": sum(int(row["callback_calls"]) for row in selected),
                "repeats": {
                    str(rep): summarize([row for row in selected if int(row["repeat"]) == rep], "step_ms")
                    for rep in sorted({int(row["repeat"]) for row in selected})
                },
            }
        result = {"case": name, "fixture": fixture, "arms": arms, "validation": validation, "same_count_p95_reduction_percent": 100 * (1 - arms["retained"]["step_ms"]["p95"] / arms["gw"]["step_ms"]["p95"])}
        results.append(result)
    report = {"metric": "synchronous completeRedraw camera-step milliseconds; not completed-frame FPS", "visual_limit": "Same point data; retained point-list rasterization is finer than POINT_MRKR. Not pixel-equivalent.", "cases": results}
    (args.folder / "summary.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    for result in results:
        values = [f'{result["arms"][arm]["step_ms"]["median"]:.3f}/{result["arms"][arm]["step_ms"]["p95"]:.3f}' for arm in ["off", "gw", "retained"]]
        print(result["case"], "median/p95 ms off, GW, retained:", " | ".join(values))
    print(f"Validated {len(results)} cases; {sum(v['frames'] for r in results for v in r['validation'])} camera steps")


if __name__ == "__main__":
    main()
