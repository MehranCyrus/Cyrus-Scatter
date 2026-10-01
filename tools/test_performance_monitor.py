"""Verify the standalone monitor in a fresh Max 2027 batch process, never the open UI."""
from pathlib import Path
import csv
import json
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    destination = ROOT / "build/performance-monitor-test"
    destination.mkdir(parents=True, exist_ok=True)
    plugins = destination / "plugins.ini"
    plugins.write_text(
        "[Directories]\nCyrusScatterTest=" + str(ROOT / "build/max2027-release/AminScatter")
        + "\nCyrusAnalyzerTest=" + str(ROOT / "build/max2027-release/CyrusSurfaceAnalyzer") + "\n",
        encoding="utf-8",
    )
    config = destination / "max.ini"
    if not config.exists():
        config.write_text("[Directories]\n", encoding="utf-8")
    result = destination / "result.txt"
    result.write_text("PENDING\n", encoding="utf-8")
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    command = ["C:/Program Files/Autodesk/3ds Max 2027/3dsmaxbatch.exe",
               str(ROOT / "tools/tests/performance_monitor_smoke.ms"),
               "-i", str(config), "-p", str(plugins),
               "-listenerlog", str(destination / "listener.log"),
               "-log", str(destination / "session.log")]
    with (destination / "stdout.log").open("wb") as out, (destination / "stderr.log").open("wb") as err:
        completed = subprocess.run(command, cwd=ROOT, startupinfo=startup, stdout=out, stderr=err, timeout=240)
    report = result.read_text(encoding="utf-8-sig")
    print(report)
    if completed.returncode or "SUCCESS" not in report:
        raise SystemExit("Monitor smoke test failed; inspect build/performance-monitor-test/*.log")
    run = Path(re.search(r"^RUN (.+)$", report, re.M).group(1).strip())
    for path in run.glob("*.json"):
        json.loads(path.read_text(encoding="utf-8-sig"))
    for path in run.glob("*.csv"):
        with path.open(encoding="utf-8-sig", newline="") as stream:
            assert all(None not in row for row in csv.DictReader(stream)), path
    sys.path.insert(0, str(ROOT / "tools/performance"))
    import compare_runs
    data = compare_runs.load_run(run)
    assert data["statistics"]["n"] == 3 and data["failed"] == 0, data["statistics"]
    assert data["sampler"]["status"] == "stopped" and data["resource_samples"] >= 2, data["sampler"]
    assert data["observed_counter_resets"] >= 1
    compare_runs.render_report([data], None, destination / "smoke-report.html")
    import summarize_edit_trace
    trace_path = Path(re.search(r"^TRACE_RUN (.+)$", report, re.M).group(1).strip())
    trace = summarize_edit_trace.summarize(trace_path)
    assert not trace["warnings"], trace["warnings"]
    assert [e["edit_id"] for e in trace["edits"]] == ["1", "2", "3"]
    assert [e["window_id"] for e in trace["edits"]] == [1, 2, 3]
    assert [e["preview_builds"] for e in trace["edits"]] == [2, 1, 1]
    assert trace["edits"][0]["label"] == trace["edits"][1]["label"]
    assert trace["edits"][0]["preview_builds"] == 2
    assert trace["edits"][0]["analyzer_runs"] == 1
    assert len(trace["input_events"]) >= 1
    previews = [s for s in trace["spans"] if s["stage"] == "preview_rebuild"]
    assert all(s["metadata"][1:3] == [200,16000] for s in previews)
    assert all(s["parent_span_id"] != "0" for s in trace["spans"] if s["stage"] == "placements")
    assert sum(s["stage"] == "preview_rebuild" and s["window_id"] is None for s in trace["spans"]) == 1
    assert all(0 <= s["child_excluded_ms"] <= s["duration_ms"] for s in trace["spans"])
    summarize_edit_trace.render(trace, destination / "edit-trace-report.html")
    failed_path = Path(re.search(r"^FAILURE_TRACE_RUN (.+)$", report, re.M).group(1).strip())
    failed = summarize_edit_trace.summarize(failed_path)
    assert any(s["error"] for s in failed["spans"]), "Failed stages reported as successes"
    print("PASS trace pairing, nested stages, per-build counts, error reporting and edit report")
    print("PASS exported JSON/CSV, numeric timings, counter reset, sampler completion and report generation")


if __name__ == "__main__":
    main()
