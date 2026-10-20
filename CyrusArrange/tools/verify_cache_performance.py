"""Strict independent raw-evidence validator for the owned cache benchmark.

No Max import or launch. A passing synthetic test is not host/performance evidence.
"""
import argparse
from collections import Counter, defaultdict
import csv
from decimal import Decimal
import json
import math
from pathlib import Path
import re
import statistics

CASES = ("small TV ordinary books", "medium open shelf book rows")
PHASES = ("lookupStamp", "furnitureCapture", "inspect", "registryBind", "obstacleCapture",
          "queryBuild", "assetRefresh", "solve", "visualCapture", "publish", "finalValidate", "total")
REASONS = {"none", "empty", "keyChanged", "dependencyChanged", "timeChanged", "unitsChanged",
           "sceneChanged", "ownerRemoved", "explicitClear", "disabled", "invalidKey",
           "accountingUnavailable", "tooLarge", "pinnedBudget", "metadataAllocation"}
OPERATIONS = ("Generate", "Preview", "CommitPreview")
POSE_FLOATS = ("anchor_x_mm", "anchor_y_mm", "anchor_z_mm", "yaw_degrees", "scale",
               *(f"bounds_{end}_{axis}" for end in ("min", "max") for axis in "xyz"),
               *(f"tm_row{row}_{axis}" for row in range(1, 5) for axis in "xyz"))
POSE_INTS = ("placement_id", "asset_id", "region_id", "parent_stack_id")
NATIVE_POSE_REALS = ("anchor_x_mm", "anchor_y_mm", "anchor_z_mm", "yaw_degrees", "scale")
COMPOSITION = ("row_attempts", "rows_formed", "row_failures", "balance_anchor_attempts", "rows_moved")
STATS = ("requested", "accepted", "kept", "candidates", "underfilled", "warnings")
MEMORY = ("working_before_bytes", "working_after_bytes", "private_before_bytes", "private_after_bytes",
          "process_lifetime_peak_working_before_bytes", "process_lifetime_peak_working_after_bytes")
LIMITS = {"entries": 4, "bytes": 268435456, "triangles": 1000000, "cells": 1000000}


def require(value, message):
    if not value:
        raise ValueError(message)


def integer(value, minimum=0, maximum=2**63-1):
    require(isinstance(value, str) and bool(re.fullmatch(r"-?(?:0|[1-9]\d*)", value)),
            f"Expected exact unsuffixed decimal integer, got {value!r}.")
    result = int(value)
    require(minimum <= result <= maximum, f"Integer out of bounds: {result}.")
    return result


def signed(value):
    return integer(value, -2**63)


def real(value):
    result = float(value)
    require(math.isfinite(result), f"Nonfinite numeric evidence: {value!r}.")
    return result


def boolean(value):
    # Proven caPNumber uses invariant .NET Boolean text (True/False), while
    # direct MAXScript environment formatting emits true/false. Neither accepts
    # numeric truthiness, arbitrary case, whitespace or missing evidence.
    require(value in ("true", "false", "True", "False"), f"Expected canonical Boolean literal, got {value!r}.")
    return value.lower() == "true"


def rows(folder, name):
    with (folder / name).open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        require(reader.fieldnames and len(reader.fieldnames) == len(set(reader.fieldnames)), f"Bad headers: {name}.")
        result = list(reader)
        require(all(None not in row and None not in row.values() for row in result), f"Truncated/extra CSV fields: {name}.")
        return result


def grouped_by_serial(values):
    result = defaultdict(list)
    for row in values:
        result[integer(row["serial"], 1)].append(row)
    return result


def expected_schedule(reverse):
    for case in CASES:
        for seed in (7231, 9349):
            yield case, "Generate", "baseline", 0, seed, "baseline", 0
        for pair in range(1, 11):
            yield case, "Generate", "preparation", pair, 9349 if pair % 2 else 7231, "preparation", 0
            cold_first = bool(pair % 2) != reverse
            for position, condition in enumerate(("cold", "warm") if cold_first else ("warm", "cold"), 1):
                for operation in OPERATIONS:
                    yield case, operation, "paired", pair, 9349 if pair % 2 else 7231, condition, position


def expected_source_boxes(case):
    """Independent analytic closed-box fixture oracle; no native support data used."""
    result = []

    def box(size, x, y, z):
        result.append((x-size[0]/2, y-size[1]/2, z, x+size[0]/2, y+size[1]/2, z+size[2]))

    if case == CASES[0]:
        box((1800, 450, 30), 2600, 0, 0)
        box((1800, 450, 30), 2600, 0, 570)
        for x in (1715, 3485):
            box((30, 450, 540), x, 0, 30)
        box((1740, 12, 540), 2600, 219, 30)
        box((1740, 438, 24), 2600, -6, 285)
        box((24, 438, 540), 2600, -6, 30)
    else:
        box((1200, 350, 30), 5200, 0, 0)
        box((1200, 350, 30), 5200, 0, 1770)
        for x in (4615, 5785):
            box((30, 350, 1740), x, 0, 30)
        box((1140, 12, 1740), 5200, 169, 30)
        for z in (340, 680, 1020, 1360):
            box((1140, 338, 24), 5200, -6, z)
        box((20, 338, 1740), 5200, -6, 30)
    return sorted(result)


def close_values(a, b, tolerance=.002):
    return len(a) == len(b) and all(abs(x-y) <= tolerance for x, y in zip(a, b))


def pose_map(values):
    result = {}
    handles = set()
    for row in values:
        identity = signed(row["placement_id"])
        handle = integer(row["node_handle"], 1, 2**32-1)
        require(identity and identity not in result and handle not in handles, "Duplicate/zero placement identity or actual handle.")
        handles.add(handle)
        for name in POSE_INTS:
            signed(row[name])
        integer(row["region_id"], 1, 2**32-1)
        require(signed(row["asset_id"]), "Missing asset identity.")
        for name in POSE_FLOATS:
            real(row[name])
        require(not boolean(row["locked"]) and signed(row["parent_stack_id"]) == 0, "Benchmark unexpectedly has protected/stacked output.")
        result[identity] = row
    return result


def same_poses(first, second, handles=False):
    a, b = pose_map(first), pose_map(second)
    require(list(a) == list(b), "Full ordered placement identity inventory differs from the seed baseline/committed state.")
    for identity, one in a.items():
        two = b[identity]
        require(all(one[key] == two[key] for key in (*POSE_INTS, "locked")), "Placement identity/category/parent/protection changed.")
        for key in POSE_FLOATS:
            if key in NATIVE_POSE_REALS:
                require(Decimal(one[key]) == Decimal(two[key]), f"Exact returned native pose changed: {identity}, {key}.")
            else:
                tolerance = .00001 if key.startswith("tm_row") and not key.startswith("tm_row4") else .002
                require(abs(real(one[key])-real(two[key])) <= tolerance, f"Independent actual bounds/TM changed: {identity}, {key}.")
        if handles:
            require(one["node_handle"] == two["node_handle"], "Preview replaced a committed output handle.")


def group_map(values):
    result = {}
    for row in values:
        identity = signed(row["group_id"])
        require(identity and identity not in result and integer(row["kind"], 1) == 1, "Invalid/duplicate group or kind.")
        text = row["ordered_member_ids"]
        require(bool(re.fullmatch(r"#\(\s*-?\d+[Ll]?(?:\s*,\s*-?\d+[Ll]?){1,3}\s*\)", text)), "Expected 2..4 exact ordered book member IDs.")
        members = tuple(int(value.rstrip("Ll")) for value in re.findall(r"-?\d+[Ll]?", text))
        require(len(set(members)) == len(members) and all(members), "Duplicate/zero ordered row member.")
        for member in members:
            require(-2**63 <= member < 2**63, "Member ID outside signed64.")
        result[identity] = (integer(row["region_id"], 1, 2**32-1), members,
                            *(real(row[f"front_{a}"]) for a in "xyz"), real(row["gap_mm"]))
    return result


def same_groups(first, second):
    a, b = group_map(first), group_map(second)
    require(list(a) == list(b), "Full ordered native group identity inventory changed.")
    require(a == b, "Complete native group relationships changed.")
    for one, two in zip(first, second):
        for key in ("front_x", "front_y", "front_z", "gap_mm"):
            require(Decimal(one[key]) == Decimal(two[key]), f"Exact native group field changed: {key}.")


def composition_payload(values, metric):
    require(len(values) == 1, "Missing/duplicate complete native composition statistics.")
    row = values[0]
    require(all(row[key] == metric[key] for key in ("case", "operation", "phase", "iteration", "seed")), "Composition statistics are not bound to the command.")
    require(boolean(row["available"]), "Published native composition statistics are unavailable.")
    return (True, *(integer(row[key]) for key in COMPOSITION))


def physical(poses, groups, asset_sizes, source_boxes):
    pm = pose_map(poses)
    boxes = []
    for row in pm.values():
        asset = asset_sizes.get(signed(row["asset_id"]))
        require(asset is not None, "Output references unknown authored asset.")
        low = tuple(real(row[f"bounds_min_{a}"]) for a in "xyz")
        high = tuple(real(row[f"bounds_max_{a}"]) for a in "xyz")
        anchor = tuple(real(row[f"anchor_{a}_mm"]) for a in "xyz")
        require(abs(real(row["yaw_degrees"])) <= .00001 and abs(real(row["scale"])-1) <= .00001, "Full-size/zero-yaw workload changed.")
        require(close_values(tuple(b-a for a, b in zip(low, high)), asset, .03), "Actual complete output bounds differ from authored source size.")
        require(close_values(low, (anchor[0]-asset[0]/2, anchor[1]-asset[1]/2, anchor[2]), .03), "Actual contact/pivot differs from native pose.")
        for r in range(1, 4):
            require(close_values(tuple(real(row[f"tm_row{r}_{a}"]) for a in "xyz"), tuple(float(i == r-1) for i in range(3)), .00001), "Actual output basis does not match yaw/scale.")
        require(close_values(tuple(real(row[f"tm_row4_{a}"]) for a in "xyz"), anchor, .003), "Actual output translation differs from native anchor.")
        supported = False
        for b in source_boxes:
            if abs(low[2]-b[5]) < .03 and low[0] >= b[0]-.03 and high[0] <= b[3]+.03 and low[1] >= b[1]-.03 and high[1] <= b[4]+.03:
                supported = True
            require(not all(min(high[i], b[i+3])-max(low[i], b[i]) > .03 for i in range(3)), "Actual output penetrates physical furniture.")
        require(supported, "Whole actual footprint lacks independent physical board-top support.")
        boxes.append((low, high))
    for i, (a, aa) in enumerate(boxes):
        for b, bb in boxes[i+1:]:
            require(not all(min(aa[k], bb[k])-max(a[k], b[k]) > .03 for k in range(3)), "Actual full outputs overlap in 3D.")
    used = set()
    for region, members, fx, fy, fz, gap in group_map(groups).values():
        require(gap >= 0 and close_values((fx, fy, fz), (0., -1., 0.), .00001), "Saved row front/gap changed.")
        previous = None
        for identity in members:
            require(identity in pm and identity not in used and int(pm[identity]["region_id"]) == region, "Row members must exist once on their saved region.")
            used.add(identity)
            row = pm[identity]
            if previous is not None:
                require(abs(real(row["bounds_min_x"])-real(previous["bounds_max_x"])-gap) <= .03 and
                        abs(real(row["bounds_min_y"])-real(previous["bounds_min_y"])) <= .03 and
                        abs(real(row["bounds_min_z"])-real(previous["bounds_min_z"])) <= .03,
                        "Generated row lost physical adjacency/front/support plane.")
            previous = row


def summary_values(values):
    values = sorted(values)
    return {"n": len(values), "median": statistics.median(values),
            "p95_nearest_rank": values[math.ceil(.95*len(values))-1], "min": values[0], "max": values[-1]}


def verify(folder):
    folder = Path(folder)
    report = (folder / "result.txt").read_text(encoding="utf-8-sig")
    require(bool(re.match(r"SUCCESS passes=[1-9]\d* failures=0(?:\s|$)", report)), "Host harness did not finish successfully; preserve failure evidence.")
    environment = (folder / "performance-environment.txt").read_text(encoding="utf-8-sig")

    def field(name):
        matches = re.findall(rf"^{re.escape(name)}=(.*)$", environment, re.MULTILINE)
        require(len(matches) == 1, f"Missing/duplicate environment field {name}.")
        return matches[0]

    frequency = integer(field("StopwatchFrequency"), 1)
    pid = integer(field("OwnedPID"), 1, 2**31-1)
    reverse = boolean(field("ReverseOrder"))
    require(field("NativeVersion") == "0.3.2" and field("StopwatchHighResolution") == "true", "Unexpected native version/non-high-resolution clock.")
    require(bool(re.search(rf"^ObservedMaxProcess=3dsmax PID={pid}$", environment, re.MULTILINE)), "Exact owned PID not in observed Max process inventory.")
    metrics = rows(folder, "metrics.csv")
    require(len(metrics) == 144, "Expected exactly120 paired commands plus4 seed baselines plus20 explicit priming/context commands.")
    by_serial = {}
    for serial, (row, wanted) in enumerate(zip(metrics, expected_schedule(reverse)), 1):
        require(integer(row["serial"], 1) == serial, "Serial measurements missing/reordered/duplicated.")
        actual = (row["case"], row["operation"], row["phase"], integer(row["iteration"]), integer(row["seed"]), row["condition"], integer(row["position"]))
        require(actual == wanted and boolean(row["reverse_order"]) == reverse, f"Unexpected complete paired schedule at serial {serial}.")
        require(row["computation"] == "geometry_query_cache_enabled", "Unexpected computation claim.")
        elapsed, ticks = real(row["elapsed_ms"]), integer(row["elapsed_ticks"], 1)
        require(elapsed > 0 and abs(elapsed-1000*ticks/frequency) <= max(.001, elapsed*1e-7), "Script elapsed milliseconds disagree with exact Stopwatch ticks.")
        for name in MEMORY:
            integer(row[name], 1)
        require(int(row["process_lifetime_peak_working_after_bytes"]) >= int(row["process_lifetime_peak_working_before_bytes"]) and
                int(row["process_lifetime_peak_working_after_bytes"]) >= int(row["working_after_bytes"]), "Invalid process lifetime peak observation.")
        for name in STATS:
            integer(row[name])
        require(integer(row["accepted"], 1) <= int(row["requested"]) and int(row["underfilled"]) == int(row["requested"])-int(row["accepted"]), "Target/accepted/underfill relation invalid.")
        by_serial[serial] = row
    source_rows, asset_rows = rows(folder, "sources.csv"), rows(folder, "assets.csv")
    require({r["case"] for r in source_rows} == set(CASES) and {r["case"] for r in asset_rows} == set(CASES), "Fixture scope incomplete.")
    sources, assets = {}, {}
    for case in CASES:
        case_sources = [r for r in source_rows if r["case"] == case]
        require(sorted(integer(r["source_index"], 1) for r in case_sources) == list(range(1, len(case_sources)+1)), "Duplicate/missing actual source index.")
        sources[case] = sorted(tuple(real(r[f"{end}_{a}_mm"]) for end in ("min", "max") for a in "xyz") for r in case_sources)
        oracle = expected_source_boxes(case)
        require(len(sources[case]) == len(oracle) and all(close_values(a, b, .002) for a, b in zip(sources[case], oracle)), "Actual source boards differ from independent original-fixture dimensions.")
        assets[case] = {}
        for row in (r for r in asset_rows if r["case"] == case):
            identity = signed(row["asset_id"])
            require(identity and identity not in assets[case], "Duplicate/zero source asset.")
            assets[case][identity] = tuple(real(row[f"size_{a}_mm"]) for a in "xyz")
        require(sorted(assets[case].values()) == [(20.,120.,100.), (30.,120.,200.), (40.,120.,300.)], "Expected three full-size individual original book models.")
    tables = {name: grouped_by_serial(rows(folder, name)) for name in ("poses.csv", "groups.csv", "regions.csv", "preview-bounds.csv", "warnings.csv", "cache-commands.csv", "cache-phases.csv", "composition-stats.csv")}
    for name, table in tables.items():
        require(set(table).issubset(by_serial), f"Unknown command serial in {name}.")
    baselines, previous, sequence, ticket, reference_regions = {}, {}, 0, {}, {}
    paired_work = defaultdict(dict)
    raw = defaultdict(list)
    for serial, metric in by_serial.items():
        case, operation, condition, seed = (metric[k] for k in ("case", "operation", "condition", "seed"))
        poses, groups, regions, boxes, warning_rows, commands, phase_rows, composition_rows = (tables[name].get(serial, []) for name in tables)
        composition = composition_payload(composition_rows, metric)
        require(len(poses) == integer(metric["committed_outputs"], 1) and len(groups) == integer(metric["committed_groups"]), "Complete actual pose/group count differs.")
        for evidence in (*poses, *groups):
            require(all(evidence[key] == metric[key] for key in ("case", "operation", "phase", "iteration", "seed")), "Pose/group metadata not bound to its actual command.")
        require(len(regions) == integer(metric["regions"], 1), "Region evidence incomplete.")
        region_ids = set()
        for region in regions:
            identity = integer(region["region_id"], 1, 2**32-1)
            require(region["case"] == case and identity not in region_ids and not boolean(region["excluded"]), "Invalid/duplicate/excluded region record.")
            region_ids.add(identity)
            for key in ("role",):
                integer(region[key])
            for key in (*(f"bounds_{e}_{a}" for e in ("min", "max") for a in "xyz"), "minimum_clearance_mm"):
                real(region[key])
            boolean(region["open_above"])
        region_payload = {int(row["region_id"]): (int(row["role"]),
            *(real(row[f"bounds_{e}_{a}"]) for e in ("min", "max") for a in "xyz"),
            real(row["minimum_clearance_mm"]), boolean(row["open_above"]), boolean(row["excluded"])) for row in regions}
        reference_regions.setdefault(case, region_payload)
        require(reference_regions[case] == region_payload, "Geometry reuse changed persistent region identity/shape/clearance metadata.")
        require(all(int(row["region_id"]) in region_ids for row in poses), "Actual output record refers to missing region.")
        require(len(warning_rows) == int(metric["warnings"]) and [integer(row["index"], 1) for row in warning_rows] == list(range(1, len(warning_rows)+1)), "Warnings missing/reordered.")
        physical(poses, groups, assets[case], sources[case])
        require(len(commands) == 1, "Missing/duplicate native cache command record.")
        command = commands[0]
        require(command["reason"] in REASONS, "Unknown native cache reason.")
        require(boolean(command["enabled"]) and boolean(command["completed"]) and boolean(command["published"]) == (operation != "Preview"), "Native completed/published/cache-enabled contract invalid.")
        require(command["operation"].lower() == operation.lower(), "Native operation differs from measured API.")
        new_sequence = integer(command["command_sequence"], 1)
        require(new_sequence > sequence, "Native command sequence is stale/repeated.")
        sequence = new_sequence
        work = {key: integer(command[key]) for key in ("inspection_work_original", "inspection_work_executed", "query_build_work_original", "query_build_work_executed", "solver_work")}
        require(work["inspection_work_original"] > 0 and work["query_build_work_original"] > 0 and work["solver_work"] > 0, "Nonvacuous original/native solver work required.")
        require([r["phase"] for r in phase_rows] == list(PHASES), "All12 native phase names/order must be present exactly once.")
        phases = {row["phase"]: integer(row["nanoseconds"]) for row in phase_rows}
        require(phases["total"] > 0 and all(n <= phases["total"] for n in phases.values()) and
                phases["total"]/1e6 <= real(metric["elapsed_ms"])+1, "Native phase bounds inconsistent with enclosing command interval.")
        require(phases["assetRefresh"] > 0 and phases["solve"] > 0, "Warm cache must still refresh actual assets and solve.")
        if condition in ("warm", "preparation"):
            require(command["disposition"] == "hit" and command["reason"] == "none" and boolean(command["lookup_validated"]) and
                    work["inspection_work_executed"] == 0 and work["query_build_work_executed"] == 0 and
                    all(phases[key] == 0 for key in ("furnitureCapture", "inspect", "obstacleCapture", "queryBuild")), "Warm label is not a validated native hit with zero actual geometry build work.")
        else:
            require(command["disposition"] == "cold" and not boolean(command["lookup_validated"]) and
                    work["inspection_work_executed"] == work["inspection_work_original"] and
                    work["query_build_work_executed"] == work["query_build_work_original"] and
                    phases["furnitureCapture"] > 0 and phases["inspect"] > 0 and phases["queryBuild"] > 0,
                    "Cold label did not execute complete native inspection/query build.")
        for prefix in ("live", "peak"):
            for key, cap in LIMITS.items():
                require(integer(command[f"{prefix}_{key}"]) <= cap, "Cache retained footprint exceeds explicit cap.")
        require(integer(command["resident"], 1)+integer(command["retired_borrowed"]) == int(command["live_entries"]) and
                int(command["live_bytes"]) > 0, "Global actual retained entries/bytes inconsistent.")
        for key in LIMITS:
            require(int(command[f"peak_{key}"]) >= int(command[f"live_{key}"]), "Retained peak below current live footprint.")
        for key in ("entry_metadata_live_bytes", "entry_metadata_peak_bytes", "fixed_service_inline_bytes", "fixed_control_object_bytes"):
            integer(command[key], 1)
        require(int(command["entry_metadata_peak_bytes"]) >= int(command["entry_metadata_live_bytes"]), "Metadata peak below current.")
        current_ticket = tuple(integer(command[key], 1) for key in ("document_instance", "scene_epoch", "geometry_epoch"))
        require(integer(command["time_ticks"]) == 0, "Same-time cache benchmark changed scene time.")
        ticket.setdefault(case, current_ticket)
        require(ticket[case] == current_ticket, "Geometry dependency ticket changed during recipe-only paired workload.")
        revision_before, revision_after = integer(metric["revision_before"]), integer(metric["revision_after"])
        publication_index = integer(metric["prior_publications_in_case"])
        require(publication_index == (0 if case not in previous else previous[case][1]), "Unreported publication history growth.")
        if operation == "Preview":
            require(revision_before == revision_after and len(boxes) == int(metric["preview_boxes"]) == int(metric["accepted"]), "Preview published or bounds evidence incomplete.")
            require(case in previous, "Preview lacks committed predecessor.")
            predecessor = previous[case][0]
            same_poses(tables["poses.csv"][predecessor], poses, handles=True)
            same_groups(tables["groups.csv"].get(predecessor, []), groups)
            require(composition_payload(tables["composition-stats.csv"].get(predecessor, []), by_serial[predecessor]) == composition,
                    "Preview changed complete committed composition statistics.")
        else:
            require(not boxes and int(metric["preview_boxes"]) == 0 and revision_after == revision_before+1 and len(poses) == int(metric["accepted"]), "Generate/Commit actual publication contract changed.")
        warning_text = tuple(r["warning"] for r in warning_rows)
        if condition == "baseline":
            require((case, seed) not in baselines, "Duplicate baseline seed.")
            baselines[case, seed] = (serial, tuple(metric[k] for k in STATS), warning_text, work, composition)
        else:
            baseline_serial, stats, baseline_warnings, baseline_work, baseline_composition = baselines[case, seed]
            require(tuple(metric[k] for k in STATS) == stats and warning_text == baseline_warnings, "Full logical stats/warnings differ from exact seed baseline.")
            require(composition == baseline_composition, "Complete native composition statistics differ from seed baseline.")
            for key in ("inspection_work_original", "query_build_work_original"):
                require(work[key] == baseline_work[key], "Original geometry build work changed under reuse.")
            baseline_poses = tables["poses.csv"][baseline_serial]
            if operation != "Preview":
                same_poses(baseline_poses, poses)
                same_groups(tables["groups.csv"].get(baseline_serial, []), groups)
            else:
                require([integer(r["index"], 1) for r in boxes] == list(range(1, len(boxes)+1)), "Preview box sequence missing/reordered.")
                for box, pose in zip(boxes, baseline_poses):
                    low = tuple(real(pose[f"bounds_min_{a}"]) for a in "xyz")
                    high = tuple(real(pose[f"bounds_max_{a}"]) for a in "xyz")
                    require(close_values(tuple(real(box[f"center_{a}_mm"]) for a in "xyz"), tuple((a+b)/2 for a,b in zip(low,high)), .03) and
                            close_values(tuple(real(box[f"half_{a}_mm"]) for a in "xyz"), tuple((b-a)/2 for a,b in zip(low,high)), .03) and abs(real(box["yaw_degrees"])-real(pose["yaw_degrees"])) <= .00001,
                            "Actual Preview boxes differ from independently measured baseline meshes.")
            if condition in ("cold", "warm"):
                paired_work[case, operation, int(metric["iteration"])][condition] = work["solver_work"]
                raw[case, operation, condition].append({"iteration": int(metric["iteration"]), "position": int(metric["position"]),
                "script_ms": real(metric["elapsed_ms"]), "native_total_ms": phases["total"]/1e6,
                "preparation_ms": sum(phases[p] for p in ("lookupStamp", "furnitureCapture", "inspect", "registryBind", "obstacleCapture", "queryBuild"))/1e6,
                "phases_ns": phases, "live_bytes": int(command["live_bytes"]),
                "private_after_bytes": int(metric["private_after_bytes"]), "prior_publications": publication_index})
        previous[case] = (serial, publication_index+(operation != "Preview"))
    require(len(paired_work) == 60 and all(set(value) == {"cold", "warm"} and value["cold"] == value["warm"] for value in paired_work.values()),
            "Matched previous state must yield identical per-pair cold/warm solver work.")
    require(len(baselines) == 4 and all(len(v) == 10 for v in raw.values()) and len(raw) == 12, "Missing cold/warm ten-sample workload.")
    for case in CASES:
        a, b = (baselines[case, str(seed)][0] for seed in (7231, 9349))
        require([(r["placement_id"], *(r[k] for k in POSE_FLOATS)) for r in tables["poses.csv"][a]] !=
                [(r["placement_id"], *(r[k] for k in POSE_FLOATS)) for r in tables["poses.csv"][b]], "Seed reroll fixture is vacuous.")
        if case == CASES[1]:
            require(tables["groups.csv"].get(a) and tables["groups.csv"].get(b), "Open-shelf native row workload must form actual groups for both seeds.")
    summaries = []
    for case in CASES:
        for operation in OPERATIONS:
            cold, warm = raw[case, operation, "cold"], raw[case, operation, "warm"]
            require([r["iteration"] for r in cold] == list(range(1,11)) == [r["iteration"] for r in warm], "Matched paired inventory changed.")
            item = {"case": case, "operation": operation, "samples_per_condition": 10,
                    "cold": {}, "warm": {}, "paired_delta_cold_minus_warm_ms": {}, "order_strata": {}}
            for key, values in (("cold", cold), ("warm", warm)):
                item[key] = {field: summary_values([r[field] for r in values]) for field in ("script_ms", "native_total_ms", "preparation_ms")}
                item[key]["native_phases_ms"] = {phase: summary_values([r["phases_ns"][phase]/1e6 for r in values]) for phase in PHASES}
                for field in ("live_bytes", "private_after_bytes", "prior_publications"):
                    item[key][field+"_range"] = [min(r[field] for r in values), max(r[field] for r in values)]
            for field in ("script_ms", "native_total_ms", "preparation_ms"):
                item["paired_delta_cold_minus_warm_ms"][field] = summary_values([a[field]-b[field] for a,b in zip(cold,warm)])
            for position in (1,2):
                item["order_strata"][f"cold_position_{position}"] = {field: summary_values([a[field]-b[field] for a,b in zip(cold,warm) if a["position"]==position]) for field in ("script_ms", "native_total_ms", "preparation_ms")}
            summaries.append(item)
    return {"status": "validated_raw_cache_command_samples", "host_assertion_result": report.splitlines()[0],
            "paired_commands": 120, "separate_seed_baselines": 4, "separate_context_commands": 20, "reverse_order": reverse, "owned_pid": pid,
            "samples": summaries, "limits": [
                "Requires an external matching native/UI/source/runner receipt; this validator does not launch or qualify Max.",
                "Cache hits are established from native disposition, lookup validation and executed work; elapsed time is never a hit oracle.",
                "Geometry prep saving and whole command effect are reported separately; no minimum speedup threshold is imposed.",
                "20 explicit warm-hit context commands equalize previous logical state and are excluded from paired samples. Undo/publication history accumulates and is exported; opposite-order fresh run is required for the proposed performance gate.",
                "Global retained requested bytes exclude allocator-private overhead/host meshes/history; process memory includes the entire Max process.",
                "Nearest-rank p95 with ten samples is the maximum, not a tail-latency guarantee.",
                "No FPS/rendering/general-scene/stress-scene performance or machine-idleness claim follows from these fixtures."]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run_output", type=Path)
    parser.add_argument("--opposite-run", type=Path)
    args = parser.parse_args()
    try:
        result = verify(args.run_output.resolve())
        if args.opposite_run:
            other = verify(args.opposite_run.resolve())
            require(result["reverse_order"] != other["reverse_order"] and result["owned_pid"] != other["owned_pid"], "Opposite-order qualification needs a reversed schedule in a different owned process.")
            result = {"status": "validated_two_opposite_order_runs", "runs": [result, other],
                      "qualification_boundary": "Root must separately bind both runs to the same native pair and record no overlapping QA workload."}
    except (ValueError, OSError, KeyError, csv.Error) as error:
        parser.exit(1, "Incomplete/invalid cache benchmark evidence: "+str(error)+"\n")
    print(json.dumps(result, indent=2, allow_nan=False))


if __name__ == "__main__":
    main()
