"""Read a completed owned Max benchmark; print strict raw-sample summaries, no cache/speedup claims."""
import argparse
from collections import Counter, defaultdict
import csv
import json
import math
from pathlib import Path
import re
import statistics


CASES = ("small TV ordinary books", "medium open shelf book rows")
PHASES = {
    ("Generate", "initial scene first command"): 1,
    ("Generate", "fixed seed repeat"): 10,
    ("Generate", "alternating seed reroll"): 10,
    ("Preview", "first preview after full generation"): 1,
    ("Preview", "fixed seed repeat"): 10,
    ("Preview", "alternating seed reroll"): 10,
    ("CommitPreview", "fixed seed commit"): 1,
}


def read_csv(folder, name):
    with (folder / name).open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def summarize(folder):
    report = (folder / "result.txt").read_text(encoding="utf-8-sig")
    if not report.startswith("SUCCESS "):
        raise ValueError("Host harness did not finish successfully; retain raw failure evidence.")
    if not re.match(r"SUCCESS passes=\d+ failures=0(?:\s|$)", report):
        raise ValueError("Unexpected successful result contract.")
    rows = read_csv(folder, "metrics.csv")
    if len(rows) != 86 or {int(row["serial"]) for row in rows} != set(range(1, 87)):
        raise ValueError("Expected exactly 86 unique serial complete command measurements.")
    expected = Counter({(case, operation, phase): count for case in CASES
                        for (operation, phase), count in PHASES.items()})
    observed = Counter((row["case"], row["operation"], row["phase"]) for row in rows)
    if observed != expected:
        raise ValueError(f"Case/operation/phase inventory changed: {observed - expected!r}; missing {expected - observed!r}")
    schedule = []
    for case in CASES:
        schedule.append((case, "Generate", "initial scene first command", 0, 7231))
        schedule.extend((case, "Generate", "fixed seed repeat", i, 7231) for i in range(1, 11))
        schedule.extend((case, "Generate", "alternating seed reroll", i, 9349 if i % 2 else 7231) for i in range(1, 11))
        schedule.append((case, "Preview", "first preview after full generation", 0, 7231))
        schedule.extend((case, "Preview", "fixed seed repeat", i, 7231) for i in range(1, 11))
        schedule.extend((case, "Preview", "alternating seed reroll", i, 9349 if i % 2 else 7231) for i in range(1, 11))
        schedule.append((case, "CommitPreview", "fixed seed commit", 1, 7231))
    for serial, (row, wanted) in enumerate(zip(rows, schedule), 1):
        actual = (row["case"], row["operation"], row["phase"], int(row["iteration"]), int(row["seed"]))
        if int(row["serial"]) != serial or actual != wanted:
            raise ValueError(f"Unexpected ordered trial schedule at serial {serial}: {actual!r}.")
    environment = (folder / "performance-environment.txt").read_text(encoding="utf-8-sig")
    pid_match = re.search(r"^OwnedPID=(\d+)$", environment, re.MULTILINE)
    if not pid_match or int(pid_match[1]) <= 0 or not re.search(
            rf"^ObservedMaxProcess=3dsmax PID={int(pid_match[1])}$", environment, re.MULTILINE):
        raise ValueError("Owned process ID must be positive and match the observed actual Max process.")
    frequency_match = re.search(r"^StopwatchFrequency=(\d+)", environment, re.MULTILINE)
    if not frequency_match or int(frequency_match[1]) <= 0:
        raise ValueError("Missing actual positive Stopwatch frequency.")
    frequency = int(frequency_match[1])
    by_serial = {int(row["serial"]): row for row in rows}
    poses = read_csv(folder, "poses.csv")
    boxes = read_csv(folder, "preview-bounds.csv")
    groups = read_csv(folder, "groups.csv")
    pose_counts = Counter(int(row["serial"]) for row in poses)
    box_counts = Counter(int(row["serial"]) for row in boxes)
    group_counts = Counter(int(row["serial"]) for row in groups)
    for row in rows:
        serial = int(row["serial"])
        if row["computation"] != "full_recapture_rebuild":
            raise ValueError("Unexpected cache/computation claim.")
        elapsed = float(row["elapsed_ms"])
        ticks = int(row["elapsed_ticks"])
        if not math.isfinite(elapsed) or elapsed < 0 or ticks < 0:
            raise ValueError(f"Invalid timing in serial {serial}.")
        if abs(elapsed - 1000 * ticks / frequency) > max(0.001, elapsed * 1e-7):
            raise ValueError(f"Milliseconds/ticks disagree in serial {serial}.")
        for key in ("working_before_bytes", "working_after_bytes", "private_before_bytes", "private_after_bytes",
                    "process_lifetime_peak_working_before_bytes", "process_lifetime_peak_working_after_bytes"):
            if int(row[key]) <= 0:
                raise ValueError(f"Missing positive process memory {key}, serial {serial}.")
        if int(row["requested"]) < int(row["accepted"]) or int(row["underfilled"]) != int(row["requested"]) - int(row["accepted"]):
            raise ValueError(f"Invalid observed target/accepted/underfill relation in serial {serial}.")
        if pose_counts[serial] != int(row["committed_outputs"]):
            raise ValueError(f"Actual complete pose evidence count differs in serial {serial}.")
        if group_counts[serial] != int(row["committed_groups"]):
            raise ValueError(f"Actual complete group evidence count differs in serial {serial}.")
        if row["operation"] == "Preview":
            if box_counts[serial] != int(row["preview_boxes"]) or int(row["accepted"]) != box_counts[serial]:
                raise ValueError(f"Preview bounds/accepted count differs in serial {serial}.")
            if row["revision_before"] != row["revision_after"]:
                raise ValueError(f"Preview unexpectedly published a revision in serial {serial}.")
        elif int(row["accepted"]) != int(row["committed_outputs"]):
            raise ValueError(f"Generate/Commit accepted count differs from actual output in serial {serial}.")
    handles_by_serial = defaultdict(set)
    ids_by_serial = defaultdict(set)
    for pose in poses:
        metric = by_serial.get(int(pose["serial"]))
        if metric is None or any(pose[key] != metric[key] for key in ("case", "operation", "phase", "iteration", "seed")):
            raise ValueError("Pose references an unknown serial or mismatched command metadata.")
        serial = int(pose["serial"])
        handle, placement_id = int(pose["node_handle"]), int(pose["placement_id"])
        if handle <= 0 or handle in handles_by_serial[serial] or placement_id == 0 or placement_id in ids_by_serial[serial]:
            raise ValueError("Actual pose node handles and placement IDs must be nonzero and unique per command; handles must be positive.")
        handles_by_serial[serial].add(handle)
        ids_by_serial[serial].add(placement_id)
        for key in ("anchor_x_mm", "anchor_y_mm", "anchor_z_mm", "yaw_degrees", "scale",
                    "bounds_min_x", "bounds_min_y", "bounds_min_z", "bounds_max_x", "bounds_max_y", "bounds_max_z",
                    *(f"tm_row{axis}_{component}" for axis in range(1, 5) for component in "xyz")):
            if not math.isfinite(float(pose[key])):
                raise ValueError("Nonfinite actual pose evidence.")
    browse = read_csv(folder, "browsing.csv")
    if Counter(row["case"] for row in browse) != Counter({case: 10 for case in CASES}):
        raise ValueError("Expected ten actual UI-handler refresh trials per case.")
    grouped = defaultdict(list)
    for row in rows:
        grouped[row["case"], row["operation"], row["phase"]].append(row)
    summaries = []
    for (case, operation, phase), samples in grouped.items():
        times = sorted(float(row["elapsed_ms"]) for row in samples)
        summaries.append({
            "case": case, "operation": operation, "phase": phase, "n": len(times),
            "median_ms": statistics.median(times), "p95_nearest_rank_ms": times[math.ceil(.95 * len(times)) - 1],
            "min_ms": times[0], "max_ms": times[-1],
            "requested_observed": sorted({int(row["requested"]) for row in samples}),
            "accepted_observed": sorted({int(row["accepted"]) for row in samples}),
            "candidates_observed": sorted({int(row["candidates"]) for row in samples}),
            "underfilled_observed": sorted({int(row["underfilled"]) for row in samples}),
            "private_before_range_bytes": [min(int(row["private_before_bytes"]) for row in samples), max(int(row["private_before_bytes"]) for row in samples)],
            "private_after_range_bytes": [min(int(row["private_after_bytes"]) for row in samples), max(int(row["private_after_bytes"]) for row in samples)],
            "whole_process_peak_working_bytes": max(int(row["process_lifetime_peak_working_after_bytes"]) for row in samples),
        })
    return {
        "status": "complete_raw_command_measurements", "host_assertion_result": report.splitlines()[0],
        "computation": "full_recapture_rebuild", "retained_geometry_query_cache": False,
        "speedup_claim": False, "samples": summaries,
        "limits": ["Root runner receipt must independently qualify native pair, full test inputs and artist/private-profile identities.",
                   "Root must establish that other QA/render processes did not overlap; process inventory alone cannot prove machine idleness.",
                   "First commands are separate; repeated runs still recapture and rebuild, with bounded accumulating native Undo history.",
                   "Process peak working set spans process lifetime, including earlier cases; it is not a per-command allocation peak.",
                   "Ten-sample nearest-rank p95 equals the maximum; no FPS, renderer, worst-case or general-scene performance claim."]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run_output", type=Path)
    args = parser.parse_args()
    try:
        result = summarize(args.run_output.resolve())
    except (ValueError, OSError, KeyError, csv.Error) as error:
        parser.exit(1, "Incomplete/invalid benchmark evidence: " + str(error) + "\n")
    print(json.dumps(result, indent=2, allow_nan=False))


if __name__ == "__main__":
    main()
