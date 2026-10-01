"""Summarize one recording or compare two. Standard-library only; never opens Max.

python tools/performance/compare_runs.py RUN_FOLDER [CANDIDATE_FOLDER] --out report.html
"""
from __future__ import annotations

import argparse
import csv
from datetime import datetime, timezone
import html
import json
import math
from pathlib import Path
import statistics


def read_json(path: Path, required=False):
    if not path.is_file():
        if required:
            raise ValueError(f"Missing {path.name} in {path.parent}")
        return {}
    return json.loads(path.read_text(encoding="utf-8-sig"))


def read_csv(path: Path):
    if not path.is_file():
        return []
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def finite(value):
    try:
        number = float(value)
    except (TypeError, ValueError):
        return None
    return number if math.isfinite(number) and number >= 0 else None


def describe(values):
    ordered = sorted(values)
    return {
        "n": len(ordered),
        "median_ms": statistics.median(ordered) if ordered else None,
        "p95_ms": ordered[math.ceil(.95 * len(ordered)) - 1] if len(ordered) >= 20 else None,
        "min_ms": min(ordered) if ordered else None,
        "max_ms": max(ordered) if ordered else None,
    }


def canonical(value):
    """Normalize serialized settings without concealing real value differences."""
    if isinstance(value, str):
        try:
            value = json.loads(value)
        except json.JSONDecodeError:
            pass
    return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(",", ":"))


def load_run(folder: Path):
    folder = folder.resolve()
    manifest = read_json(folder / "manifest.json", required=True)
    if manifest.get("schema_version") != 1:
        raise ValueError(f"Unsupported recording schema: {folder}")
    rows = read_csv(folder / "operations.csv")
    measured = [row for row in rows if row.get("phase") == "measured"]
    valid, failed = [], []
    for row in measured:
        duration = finite(row.get("duration_ms"))
        if row.get("success", "").lower() == "true" and duration is not None:
            valid.append((row, duration))
        else:
            failed.append(row)
    resources = read_csv(folder / "resources.csv")
    def peak(key):
        values = [value for row in resources if (value := finite(row.get(key))) is not None]
        return max(values) if values else None
    observations = read_csv(folder / "observations.csv")
    return {
        "folder": str(folder), "manifest": manifest,
        "host": read_json(folder / "host.json"),
        "summary": read_json(folder / "summary.json"),
        "sampler": read_json(folder / "sampler-summary.json"),
        "trace_summary": read_json(folder / "trace-summary.json"),
        "warmups": sum(row.get("phase") == "warmup" for row in rows),
        "failed_warmups": sum(row.get("phase") == "warmup" and row.get("success", "").lower() != "true" for row in rows),
        "measured": len(measured), "failed": len(failed), "failures": failed,
        "statistics": describe([duration for _, duration in valid]),
        "operations": sorted({row.get("operation", "") for row in measured}),
        "outputs": sorted({canonical(row.get("output_signature")) for row, _ in valid}),
        "settings": sorted({canonical(row.get("settings_after")) for row, _ in valid}),
        "changed_during_operation": any(canonical(row.get("settings_before")) != canonical(row.get("settings_after")) for row, _ in valid),
        "resource_samples": len(resources), "sampled_peak_private_bytes": peak("private_bytes"),
        "sampled_peak_working_set_bytes": peak("working_set_bytes"),
        "peak_cpu_percent_total_capacity": peak("cpu_percent_total_capacity"),
        "observed_counter_resets": sum(row.get("counter_reset", "").lower() == "true" for row in observations),
        "observer_errors": sum(bool(row.get("error")) for row in observations),
        "corona": read_csv(folder / "corona.csv"),
    }


def file_hashes(run, role):
    return sorted((Path(item.get("path", "")).name.lower(), item.get("sha256"))
                  for item in run["host"].get("files", []) if item.get("role") == role)


def blockers(run):
    problems = []
    m = run["manifest"]
    if m.get("edit_trace_requested"):
        trace = run.get("trace_summary", {})
        if not trace or any(trace.get(k) for k in ("dropped_rows", "collector_errors", "unclosed_spans", "stage_errors")):
            problems.append("Detailed trace is incomplete or reports errors; inspect trace-summary.json.")
    if not run["summary"]:
        problems.append("Recording has no completed summary (still recording or interrupted).")
    if run["summary"].get("stop_reason") not in {"user_stopped", "panel_closed", "smoke_complete"}:
        problems.append("Recording ended abnormally or reached its limit.")
    if run["statistics"]["n"] < 3:
        problems.append("Fewer than three successful measured rebuilds; collect more samples.")
    if run["failed"] or run["failed_warmups"]:
        problems.append("At least one controlled operation failed; successful-only timings cannot establish a gain.")
    if run["changed_during_operation"] or len(run["settings"]) != 1:
        problems.append("Settings changed within or between measured operations.")
    if len(run["outputs"]) != 1:
        problems.append("Generated/displayed counts or density caps differ between operations.")
    if run["operations"] != ["controller_refreshDisplay"]:
        problems.append("The measured operation is missing, unsupported, or mixed.")
    if m.get("context") != "idle":
        problems.append("This controlled preview comparison requires an idle session.")
    if m.get("scene_dirty") or not m.get("frozen_copy_attested"):
        problems.append("The saved scene was dirty or not confirmed to match the open scene.")
    if not (run["host"].get("scene") or {}).get("sha256"):
        problems.append("Saved scene fingerprint is missing.")
    if not file_hashes(run, "measurement_tool") or not file_hashes(run, "resource_sampler"):
        problems.append("Measurement tool fingerprints are missing.")
    if run["sampler"].get("status") != "stopped" or run["resource_samples"] < 2:
        problems.append("The resource recording is incomplete; wait for sampler-summary.json after stopping.")
    return problems


def compare(baseline, candidate):
    reasons = ["Baseline: " + reason for reason in blockers(baseline)]
    reasons += ["Candidate: " + reason for reason in blockers(candidate)]
    for key in ("case_id", "max_version", "renderer_class", "renderer_build_note", "corona_version", "controller_handle", "units", "frame", "viewport", "context", "reported_fps_opt_in", "edit_trace_requested"):
        if canonical(baseline["manifest"].get(key)) != canonical(candidate["manifest"].get(key)):
            reasons.append(f"Different {key}.")
    for key in ("machine", "cpu", "gpu", "physical_ram_bytes", "logical_processors", "os_version", "power_scheme"):
        if not baseline["host"].get(key) or canonical(baseline["host"].get(key)) != canonical(candidate["host"].get(key)):
            reasons.append(f"Missing or different hardware/environment field: {key}.")
    if (baseline["host"].get("scene") or {}).get("sha256") != (candidate["host"].get("scene") or {}).get("sha256"):
        reasons.append("The saved scene files have different content.")
    for role in ("measurement_tool", "resource_sampler"):
        if file_hashes(baseline, role) != file_hashes(candidate, role):
            reasons.append(f"Different {role}; measure both builds with identical tools.")
    def corona_files(run):
        return [item for item in file_hashes(run, "loaded_module_file_on_disk") if item[0].startswith("corona")]
    if corona_files(baseline) != corona_files(candidate):
        reasons.append("Loaded Corona module file fingerprints differ.")
    if baseline["outputs"] != candidate["outputs"]:
        reasons.append("Baseline/candidate generated counts, displayed counts, or caps differ.")
    if baseline["settings"] != candidate["settings"]:
        reasons.append("Baseline/candidate Cyrus parameter snapshots differ.")
    if baseline["warmups"] != candidate["warmups"]:
        reasons.append("Different numbers of warmups.")
    a, b = baseline["statistics"]["median_ms"], candidate["statistics"]["median_ms"]
    if not a or not b:
        reasons.append("A positive median is required for ratios.")
    return {
        "comparable": not reasons, "blocked_reasons": reasons,
        "median_speedup": a / b if not reasons else None,
        "median_time_reduction_percent": 100 * (1 - b / a) if not reasons else None,
        "qualification": "Preliminary timing comparison only; verify visual/layout parity and repeat sessions. Instrumentation overhead is not yet quantified.",
    }


def render_report(runs, comparison, destination):
    esc = lambda value: html.escape(str(value))
    def display(value, unit=""):
        return "Unavailable" if value is None else f"{value:,.2f}{unit}"
    table_rows = []
    metrics = [
        ("Successful measured rebuilds", lambda r: str(r["statistics"]["n"])),
        ("Failed measured rebuilds", lambda r: str(r["failed"])),
        ("Warmups (excluded)", lambda r: str(r["warmups"])),
        ("Median rebuild", lambda r: display(r["statistics"]["median_ms"], " ms")),
        ("p95 rebuild (at least 20 samples)", lambda r: display(r["statistics"]["p95_ms"], " ms")),
        ("Minimum / maximum rebuild", lambda r: display(r["statistics"]["min_ms"], " ms") + " / " + display(r["statistics"]["max_ms"], " ms")),
        ("Session sampled peak private memory", lambda r: display(r["sampled_peak_private_bytes"] / 2**30 if r["sampled_peak_private_bytes"] is not None else None, " GiB")),
        ("Session sampled peak working set", lambda r: display(r["sampled_peak_working_set_bytes"] / 2**30 if r["sampled_peak_working_set_bytes"] is not None else None, " GiB")),
        ("Session highest sampled CPU (all logical processors)", lambda r: display(r["peak_cpu_percent_total_capacity"], "%")),
        ("Observed counter resets", lambda r: str(r["observed_counter_resets"])),
        ("Resource samples", lambda r: str(r["resource_samples"])),
    ]
    for label, getter in metrics:
        table_rows.append("<tr><th>" + esc(label) + "</th>" + "".join("<td>" + esc(getter(r)) + "</td>" for r in runs) + "</tr>")
    headings = "".join("<th>" + esc(r["manifest"].get("build_label", "Unknown build")) + "</th>" for r in runs)
    issues = comparison["blocked_reasons"] if comparison else blockers(runs[0])
    verdict = "Baseline recording"
    if comparison:
        verdict = "Comparison needs attention" if issues else f"Median time reduced by {comparison['median_time_reduction_percent']:.1f}% ({comparison['median_speedup']:.2f}x speedup)"
    issue_html = "<ul>" + "".join("<li>" + esc(item) + "</li>" for item in issues) + "</ul>" if issues else "<p>Recorded comparison checks passed. Visual correctness and instrumentation overhead still require verification.</p>"
    details = ""
    for run in runs:
        details += "<details><summary>" + esc(run["manifest"].get("build_label")) + " — metadata and raw-file locations</summary><pre>" + esc(json.dumps(run, indent=2, ensure_ascii=False)) + "</pre></details>"
    document = """<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Cyrus performance recording</title><style>
body{font:16px/1.6 system-ui,sans-serif;background:#10151d;color:#e4ebf5;max-width:1100px;margin:40px auto;padding:0 22px}
h1{font-size:32px;margin-bottom:0}h2{color:#87d5be}small,p{color:#bdc9d9}table{border-collapse:collapse;width:100%;margin:24px 0}
th,td{text-align:left;padding:12px;border-bottom:1px solid #334055}thead{background:#1c2838}td{font-variant-numeric:tabular-nums}
details{margin:14px 0;border:1px solid #334055;padding:14px}summary{cursor:pointer}pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:12px}
li{margin-bottom:8px}.scope{border-left:4px solid #87d5be;padding-left:18px}
</style><h1>Cyrus performance recording</h1>"""
    document += "<small>Generated " + esc(datetime.now(timezone.utc).isoformat()) + "</small><h2>" + esc(verdict) + "</h2>"
    document += '<p class="scope">Preview rebuild timing includes the existing controller refreshDisplay call and redraw submission. It does not measure completed GPU frames or exact input-to-visible latency. Warmups and failed samples are excluded from the timing distribution; failures remain visible and block speedup claims.</p>'
    document += issue_html + "<table><thead><tr><th>Metric</th>" + headings + "</tr></thead><tbody>" + "".join(table_rows) + "</tbody></table>"
    document += "<p>Memory peaks cover the entire recorded session and can miss sub-500 ms spikes. CPU activity includes the renderer and all Max work. FPS, when opted in, is a coarse viewport statistic, not individual frame timing. GPU usage and internal native stage timings are unavailable in this version.</p>"
    document += "<p>Three measured runs are a trial. Use three warmups and 30 measured runs for the first engineering comparison, preserve slow valid samples, and repeat sessions. Equal counts do not prove equal layouts. Corona values are manually entered whole-scene VFB statistics and are not automatically compared.</p>" + details + "</html>"
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(document, encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("baseline", type=Path)
    parser.add_argument("candidate", type=Path, nargs="?")
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    try:
        runs = [load_run(args.baseline)]
        if args.candidate:
            runs.append(load_run(args.candidate))
        comparison = compare(*runs) if len(runs) == 2 else None
        render_report(runs, comparison, args.out)
        args.out.with_suffix(".json").write_text(json.dumps({"runs": runs, "comparison": comparison}, indent=2, ensure_ascii=False), encoding="utf-8")
    except (OSError, ValueError, KeyError, csv.Error) as error:
        parser.error(str(error))
    print(args.out.resolve())
    if comparison and not comparison["comparable"]:
        print("Comparison blocked; see the report for reasons.")


if __name__ == "__main__":
    main()
