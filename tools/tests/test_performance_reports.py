"""Data-quality gates that prevent misleading performance comparisons."""
from pathlib import Path
import csv
import json
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/performance"))
import compare_runs as report


class PerformanceReportTests(unittest.TestCase):
    def setUp(self):
        parent = ROOT / "build/performance-report-tests"
        parent.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(dir=parent)
        self.root = Path(self.temporary.name).resolve()
        assert self.root.is_relative_to(parent.resolve())

    def tearDown(self):
        self.temporary.cleanup()

    def fixture(self, name, durations=(90, 100, 110)):
        folder = self.root / name
        folder.mkdir()
        def write(name, value):
            (folder / name).write_text(json.dumps(value), encoding="utf-8")
        write("manifest.json", {
            "schema_version": 1, "build_label": name, "scene_dirty": False,
            "frozen_copy_attested": True, "case_id": "preview", "max_version": [29000],
            "renderer_class": "CoronaRenderer", "renderer_build_note": "Corona 15",
            "corona_version": "15", "controller_handle": 1, "units": ["meters", 1],
            "frame": "0f", "viewport": ["perspective", 1920, 1080], "context": "idle",
        })
        write("host.json", {
            "machine": "same-pc", "cpu": [{"Name": "CPU"}], "gpu": [{"Name": "GPU"}],
            "physical_ram_bytes": 32 * 2**30, "logical_processors": 8,
            "os_version": "same-os", "power_scheme": "same-power", "scene": {"sha256": "scene"},
            "files": [{"path": "CyrusPerformanceMonitor.ms", "role": "measurement_tool", "sha256": "tool"},
                      {"path": "Measure-CyrusProcess.ps1", "role": "resource_sampler", "sha256": "sampler"}],
        })
        write("summary.json", {"stop_reason": "user_stopped"})
        write("sampler-summary.json", {"status": "stopped"})
        fields = ["operation", "phase", "iteration", "duration_ms", "success", "error", "output_signature", "settings_before", "settings_after"]
        with (folder / "operations.csv").open("w", encoding="utf-8", newline="") as stream:
            writer = csv.writer(stream)
            writer.writerow(fields)
            for index, duration in enumerate((10000, *durations)):
                writer.writerow(["controller_refreshDisplay", "measured" if index else "warmup", index,
                                 duration, "true", "", "[[1,200,200,2000]]", '{"seed":"42"}', '{"seed":"42"}'])
        (folder / "resources.csv").write_text("private_bytes,working_set_bytes,cpu_percent_total_capacity\n100,80,25\n120,90,50\n", encoding="utf-8")
        return folder

    def test_trial_and_p95_sample_threshold(self):
        self.assertEqual(report.describe([1, 3, 2])["median_ms"], 2)
        self.assertIsNone(report.describe([1, 2, 3])["p95_ms"])
        self.assertEqual(report.describe(list(range(1, 21)))["p95_ms"], 19)

    def test_warmup_is_excluded_and_matching_runs_compare(self):
        a = report.load_run(self.fixture("baseline"))
        b = report.load_run(self.fixture("candidate", (45, 50, 55)))
        self.assertEqual(a["statistics"]["median_ms"], 100)
        self.assertEqual(a["warmups"], 1)
        comparison = report.compare(a, b)
        self.assertTrue(comparison["comparable"], comparison)
        self.assertEqual(comparison["median_speedup"], 2)
        self.assertEqual(comparison["median_time_reduction_percent"], 50)

    def test_fewer_generated_items_blocks_speedup(self):
        a = report.load_run(self.fixture("baseline"))
        b = report.load_run(self.fixture("candidate", (45, 50, 55)))
        b["outputs"] = ["[[1,100,200,1000]]"]
        comparison = report.compare(a, b)
        self.assertFalse(comparison["comparable"])
        self.assertIsNone(comparison["median_speedup"])

    def test_bad_durations_remain_failures(self):
        run = report.load_run(self.fixture("bad", (10, "nan", -1, "")))
        self.assertEqual(run["measured"], 4)
        self.assertEqual(run["failed"], 3)
        self.assertEqual(run["statistics"]["n"], 1)
        self.assertTrue(any("failed" in value for value in report.blockers(run)))

    def test_dirty_scene_and_changed_measurement_tool_block(self):
        a = report.load_run(self.fixture("baseline"))
        b = report.load_run(self.fixture("candidate"))
        b["manifest"]["scene_dirty"] = True
        b["host"]["files"][0]["sha256"] = "different-tool"
        comparison = report.compare(a, b)
        self.assertFalse(comparison["comparable"])
        self.assertTrue(any("measurement_tool" in reason for reason in comparison["blocked_reasons"]))

    def test_unsaved_or_incomplete_recording_is_reportable(self):
        run = report.load_run(self.fixture("partial"))
        run["host"]["scene"] = None
        run["sampler"] = {}
        run["summary"] = {}
        self.assertGreaterEqual(len(report.blockers(run)), 3)
        report.render_report([run], None, self.root / "partial.html")

    def test_settings_order_and_html_escaping(self):
        self.assertEqual(report.canonical('{"a":1,"b":2}'), report.canonical('{"b":2,"a":1}'))
        run = report.load_run(self.fixture("baseline"))
        run["manifest"]["build_label"] = '<script>alert("test")</script>'
        destination = self.root / "report.html"
        report.render_report([run], None, destination)
        self.assertNotIn('<script>alert', destination.read_text(encoding="utf-8"))
        self.assertIn('&lt;script&gt;', destination.read_text(encoding="utf-8"))

    def test_unstable_outputs_and_settings_block(self):
        run = report.load_run(self.fixture("unstable"))
        run["outputs"].append("different counts")
        run["changed_during_operation"] = True
        self.assertTrue(any("counts" in item for item in report.blockers(run)))
        self.assertTrue(any("Settings" in item for item in report.blockers(run)))


if __name__ == "__main__":
    unittest.main()
