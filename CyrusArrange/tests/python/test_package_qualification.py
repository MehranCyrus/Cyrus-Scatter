"""Offline package-policy controls. Synthetic files are never Max/mesh evidence."""
import copy
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

PROJECT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(PROJECT / "tools"))
SPEC = importlib.util.spec_from_file_location("arrange_package_policy_under_test", PROJECT / "tools/package.py")
p = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(p)
from run_max_tests import INTERACTIVE_TESTS as RUNNER_INTERACTIVE_TESTS


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


class PackagePolicyTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="arrange-package-policy-SYNTHETIC-")
        self.root = Path(self.temporary.name).resolve()
        self.root_patch = patch.object(p, "ROOT", self.root)
        self.root_patch.start()
        self.addCleanup(self.root_patch.stop)
        self.addCleanup(self.temporary.cleanup)
        names = set(p.REQUIRED_TESTS + p.PERFORMANCE_TESTS + p.DEPLOYMENT_INPUTS)
        names.update("tools/" + dep for spec in p.PROOFS.values() for dep in spec[4])
        names.update(("tools/verify_cache_performance.py", "src/runtime.cpp", "third_party/clipper2/LICENSE"))
        names.update("scripts/" + name for name in p.UI_SCRIPTS)
        for name in names:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("SYNTHETIC POLICY CONTROL ONLY: " + name, encoding="utf-8")
        self.sources = {name: p.sha(self.root / name) for name in sorted(names)}
        self.source_patch = patch.object(p, "source_hashes", side_effect=lambda: copy.deepcopy(self.sources))
        self.source_patch.start()
        self.addCleanup(self.source_patch.stop)
        self.native = self.root / "build/native"
        self.native.mkdir(parents=True)
        for name in p.MODULES:
            (self.native / name).write_bytes(("synthetic-" + name).encode())
        self.build = dict(status="passed", version=p.VERSION, max_year=2027, sources=copy.deepcopy(self.sources),
                          binaries={name: p.sha(self.native / name) for name in p.MODULES},
                          stages=[dict(name=name, exit_code=0) for name in ("configure", "build", "tests")])
        write_json(self.native / "receipt.json", self.build)
        self.hosts = {}
        self.next_pid = 100

    def host(self, test):
        if test in self.hosts:
            return self.hosts[test]
        folder = self.root / "build" / Path(test).stem
        (folder / "bin").mkdir(parents=True)
        for name in p.MODULES:
            (folder / "bin" / name).write_bytes((self.native / name).read_bytes())
        loaded = [str(folder / "bin" / p.MODULES[0]), '#(29000, 70, 0, 29, 1, 0, 11426, 2027, ".1")',
                  str(folder / "private.ini"), str(folder / "bin" / p.MODULES[1])]
        (folder / "loaded-native.txt").write_text("\n".join(loaded) + "\n", encoding="utf-8")
        report = "SUCCESS passes=1 failures=0\nSYNTHETIC POLICY CONTROL ONLY\n"
        (folder / "result.txt").write_text(report, encoding="utf-8")
        self.next_pid += 1
        run = dict(status="passed", exit_code=0, report=report, test_script=test,
                   test_sha256=self.sources[test], sources=copy.deepcopy(self.sources),
                   native_sha256=self.build["binaries"][p.MODULES[0]], storage_sha256=self.build["binaries"][p.MODULES[1]],
                   host_mode="owned-interactive-command-panel" if test in p.INTERACTIVE_TESTS else "owned-batch",
                   computer_use=False, installed=False, artist_scene_opened=False, loaded_native=loaded, pid=self.next_pid)
        run.update({flag: True for flag in p.HOST_FLAGS})
        write_json(folder / "receipt.json", run)
        for spec in p.PROOFS.values():
            if test == "tests/max/" + spec[0]:
                for name in spec[3]:
                    (folder / name).write_text("SYNTHETIC INPUT " + name, encoding="utf-8")
        if test in p.PERFORMANCE_TESTS:
            for name in p.PERFORMANCE_INPUTS:
                if name != "result.txt":
                    (folder / name).write_text("SYNTHETIC RAW PERFORMANCE INPUT " + name, encoding="utf-8")
        self.hosts[test] = folder
        return folder

    def change_host(self, test, change):
        folder = self.host(test)
        run = p.read_json(folder / "receipt.json")
        change(run)
        write_json(folder / "receipt.json", run)
        return folder

    def all_hosts(self):
        return [self.host(test) for test in p.REQUIRED_TESTS]

    def performance(self):
        runs = [self.host(test) for test in p.PERFORMANCE_TESTS]
        isolation = self.root / "build/isolation.json"
        write_json(isolation, dict(no_overlapping_qa_workload=True, scope=p.PERFORMANCE_SCOPE,
                   runs=[dict(receipt=str(folder / "receipt.json"), sha256=p.sha(folder / "receipt.json")) for folder in runs]))
        return runs, isolation

    def fake_verifier(self, command, log):
        """Only emulate subprocess transport; policy still binds every real byte."""
        verifier = Path(command[1]).name
        folder = Path(command[2])
        if verifier == "verify_cache_performance.py":
            reverse = Path(command[4])
            result = dict(status="validated_two_opposite_order_runs", runs=[dict(
                status="validated_raw_cache_command_samples", reverse_order=bool(index),
                owned_pid=p.read_json(run / "receipt.json")["pid"])
                for index, run in enumerate((folder, reverse))])
        else:
            key, spec = next((key, spec) for key, spec in p.PROOFS.items() if spec[1] == verifier)
            if key == "inspector":
                result = dict(status="passed", files={Path(name).stem: {} for name in p.EXPORT_FILES})
            else:
                result = dict(status="passed", host_receipt_sha256=p.sha(folder / "receipt.json"),
                              cases={str(i): {"status": "passed"} for i in range(spec[5])},
                              negative_controls=[dict(case=str(i), status="correctly-rejected") for i in range(spec[6])])
            write_json(folder / spec[2], result)
        text = json.dumps(result, indent=2)
        log.write_text(text, encoding="utf-8")
        return text

    def accepted_evidence(self):
        hosts = self.all_hosts()
        runs, isolation = self.performance()
        with patch.object(p, "run_verifier", side_effect=self.fake_verifier):
            return p.validate_receipts(self.native, hosts, runs, isolation)

    def candidate(self):
        (self.root / "README.md").write_text("SYNTHETIC policy package only; not a delivery")
        (self.root / "docs").mkdir(exist_ok=True)
        (self.root / "docs/policy.md").write_text("Synthetic archive identity control")
        runs, isolation = self.performance()
        out = self.root / "dist/synthetic-candidate"
        with patch.object(p, "run_verifier", side_effect=self.fake_verifier):
            record = p.create_candidate(self.native, self.all_hosts(), out, runs, isolation)
        return out, record

    def installer(self, folder, candidate):
        out = self.root / "build/installer"
        record = dict(status="passed", archive_sha256=candidate["archive_sha256"], sources=candidate["sources"],
                      computer_use=False, artist_installation_executed=False,
                      installed_modules={name: candidate["files"][p.INSTALLED_MODULES[name]] for name in p.MODULES},
                      candidate_receipt={"sha256": p.sha(folder / "package-receipt.json")})
        record.update({name: True for name in ("actual_mzp_executed", "installed_startup_passed", "installed_payload_verified", "artist_profiles_unchanged", "private_profiles_verified", "archive_unchanged", "loaded_path_matches", "private_ini_matches")})
        record["phases"] = {phase: dict(status="passed", exit_code=0, report="SUCCESS synthetic transport only",
            private_profile_marker=True, test_script=test, test_sha256=candidate["sources"][test],
            host_mode="owned-interactive-command-panel" if phase == "startup" else "owned-batch")
            for phase, test in (("install", "tests/max/installer_tests.ms"), ("startup", "tests/max/installed_startup_tests.ms"))}
        write_json(out / "receipt.json", record)
        return out

    def test_explicit_coverage_preserves_old_and_adds_current(self):
        self.assertEqual(len(p.REQUIRED_TESTS), 32)
        self.assertEqual(len(set(p.REQUIRED_TESTS)), 32)
        for name in ("migration", "composition_lifecycle", "library_validation", "cache_atomic", "real_world", "legacy_minimum_workflow", "unified_modify"):
            self.assertIn("tests/max/arrange_" + name + "_tests.ms", p.REQUIRED_TESTS)
        self.assertTrue(p.INTERACTIVE_TESTS <= set(p.REQUIRED_TESTS))
        self.assertEqual(p.INTERACTIVE_TESTS, {"tests/max/" + name for name in RUNNER_INTERACTIVE_TESTS})
        self.assertFalse(set(p.PERFORMANCE_TESTS) & set(p.REQUIRED_TESTS))

    def test_positive_complete_synthetic_evidence(self):
        build, sources, hosts, proofs, performance = self.accepted_evidence()
        self.assertEqual(build, self.build)
        self.assertEqual(sources, self.sources)
        self.assertEqual(set(hosts), set(p.REQUIRED_TESTS))
        self.assertEqual(set(proofs), set(p.PROOFS))
        self.assertEqual(performance["status"], "validated_two_opposite_order_runs")
        with patch.object(p, "run_verifier", side_effect=self.fake_verifier):
            p.validate_saved_proofs(proofs, performance, sources, hosts, build)

    def test_missing_suite_is_rejected_before_proof_execution(self):
        runs, isolation = self.performance()
        with self.assertRaisesRegex(ValueError, "Missing functional suites"), patch.object(p, "run_verifier") as execute:
            p.validate_receipts(self.native, self.all_hosts()[:-1], runs, isolation)
        execute.assert_not_called()

    def test_duplicate_suite_is_rejected(self):
        runs, isolation = self.performance()
        hosts = self.all_hosts()
        with self.assertRaisesRegex(ValueError, "exactly one final receipt"):
            p.validate_receipts(self.native, hosts + hosts[:1], runs, isolation)

    def test_wrong_interactive_host_is_rejected(self):
        for test in p.INTERACTIVE_TESTS:
            with self.subTest(test=test):
                folder = self.change_host(test, lambda run: run.update(host_mode="owned-batch"))
                with self.assertRaisesRegex(ValueError, "Wrong owned host mode"):
                    p.validate_host(folder, self.build, p.REQUIRED_TESTS)

    def test_each_actual_host_guard_is_required(self):
        test = p.REQUIRED_TESTS[0]
        for flag in p.HOST_FLAGS:
            with self.subTest(flag=flag):
                folder = self.change_host(test, lambda run: run.update({key: key != flag for key in p.HOST_FLAGS}))
                with self.assertRaisesRegex(ValueError, "identity checks missing"):
                    p.validate_host(folder, self.build, p.REQUIRED_TESTS)

    def test_old_source_pair_is_rejected(self):
        folder = self.change_host(p.REQUIRED_TESTS[0], lambda run: run["sources"].update({"src/runtime.cpp": "old"}))
        with self.assertRaisesRegex(ValueError, "source mismatch"):
            p.validate_host(folder, self.build, p.REQUIRED_TESTS)

    def test_changed_test_hash_is_rejected(self):
        folder = self.change_host(p.REQUIRED_TESTS[0], lambda run: run.update(test_sha256="old"))
        with self.assertRaisesRegex(ValueError, "source mismatch"):
            p.validate_host(folder, self.build, p.REQUIRED_TESTS)

    def test_development_only_receipt_is_rejected(self):
        folder = self.change_host(p.REQUIRED_TESTS[0], lambda run: run.update(package_qualification_eligible=False))
        with self.assertRaisesRegex(ValueError, "Development-only"):
            p.validate_host(folder, self.build, p.REQUIRED_TESTS)

    def test_tampered_terminal_report_is_rejected(self):
        folder = self.host(p.REQUIRED_TESTS[0])
        (folder / "result.txt").write_text("SUCCESS fabricated\n")
        with self.assertRaisesRegex(ValueError, "terminal report differs"):
            p.validate_host(folder, self.build, p.REQUIRED_TESTS)

    def test_tampered_native_payload_is_rejected(self):
        folder = self.host(p.REQUIRED_TESTS[0])
        (folder / "bin" / p.MODULES[1]).write_bytes(b"changed-storage")
        with self.assertRaisesRegex(ValueError, "payload changed"):
            p.validate_host(folder, self.build, p.REQUIRED_TESTS)

    def test_false_loaded_path_is_rejected(self):
        folder = self.host(p.REQUIRED_TESTS[0])
        path = folder / "loaded-native.txt"
        path.write_text(path.read_text().replace("private.ini", "artist.ini"))
        with self.assertRaisesRegex(ValueError, "Loaded native/private INI paths"):
            p.validate_host(folder, self.build, p.REQUIRED_TESTS)

    def test_runtime_change_cannot_use_deployment_reuse(self):
        self.sources["src/runtime.cpp"] = "changed"
        with self.assertRaisesRegex(ValueError, "Runtime/functional inputs changed"):
            p.validate_receipts(self.native, [], [], self.root / "unused", True)

    def test_added_input_cannot_use_deployment_reuse(self):
        self.sources["tools/new-input.py"] = "new"
        with self.assertRaisesRegex(ValueError, "paths were added or removed"):
            p.validate_receipts(self.native, [], [], self.root / "unused", True)

    def test_deployment_reuse_requires_explicit_opt_in(self):
        self.sources["installer/install.ms"] = "changed"
        with self.assertRaisesRegex(ValueError, "requires explicit"):
            p.validate_receipts(self.native, [], [], self.root / "unused")

    def test_missing_ctest_stage_is_rejected(self):
        self.build["stages"].pop()
        write_json(self.native / "receipt.json", self.build)
        with self.assertRaisesRegex(ValueError, "Full build/CTest"):
            p.validate_receipts(self.native, [], [], self.root / "unused")

    def test_snapshot_tamper_and_missing_settings_are_rejected(self):
        source = self.root / "input"
        source.mkdir()
        (source / "settings.txt").write_text("scale=1")
        records = p.snapshot_inputs(source, self.root / "copy", ("settings.txt",))
        with self.assertRaisesRegex(ValueError, "coverage changed"):
            p.check_inputs(records, ("settings.txt", "mesh.txt"))
        (source / "settings.txt").write_text("scale=0.01")
        with self.assertRaisesRegex(ValueError, "source/copy identity changed"):
            p.check_inputs(records, ("settings.txt",))

    def test_missing_or_accepted_negative_controls_are_rejected(self):
        spec = p.PROOFS["base"]
        result = dict(status="passed", host_receipt_sha256="producer", cases={str(i): {"status": "passed"} for i in range(spec[5])},
                      negative_controls=[dict(case=str(i), status="correctly-rejected") for i in range(spec[6])])
        p.check_proof_result("base", result, "producer")
        result["negative_controls"][0]["status"] = "accepted"
        with self.assertRaisesRegex(ValueError, "invalid-geometry controls"):
            p.check_proof_result("base", result, "producer")
        result["negative_controls"].pop()
        with self.assertRaisesRegex(ValueError, "invalid-geometry controls"):
            p.check_proof_result("base", result, "producer")

    def test_wrong_producer_hash_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "different producer"):
            p.check_proof_result("device", dict(status="passed", host_receipt_sha256="old"), "current")

    def test_transitive_verifier_change_is_rejected(self):
        (self.root / "tools/verify_shelves_stairs.py").write_text("changed imported dependency")
        with self.assertRaisesRegex(ValueError, "differs from frozen inputs"):
            p.verifier_records(p.PROOFS["packing"][4], self.sources)

    def test_isolation_cannot_be_inferred_from_pass_or_timing(self):
        runs, path = self.performance()
        record = p.read_json(path)
        record.pop("no_overlapping_qa_workload")
        write_json(path, record)
        with self.assertRaisesRegex(ValueError, "explicit no-overlapping-QA"):
            p.check_performance_isolation(path, runs)

    def test_performance_scope_cannot_claim_fps(self):
        runs, path = self.performance()
        record = p.read_json(path)
        record["scope"] = "Everything is fast, including FPS"
        write_json(path, record)
        with self.assertRaisesRegex(ValueError, "bounded backend workload"):
            p.check_performance_isolation(path, runs)

    def test_isolation_is_bound_to_exact_ordered_receipts(self):
        runs, path = self.performance()
        with self.assertRaisesRegex(ValueError, "ordered exact receipts"):
            p.check_performance_isolation(path, list(reversed(runs)))

    def test_performance_pid_and_direction_are_bound_to_receipts(self):
        runs, _ = self.performance()
        result = dict(status="validated_two_opposite_order_runs", runs=[dict(status="validated_raw_cache_command_samples", reverse_order=bool(i),
                      owned_pid=p.read_json(folder / "receipt.json")["pid"]) for i, folder in enumerate(runs)])
        p.check_performance_result(result, runs)
        result["runs"][0]["owned_pid"] += 1000
        with self.assertRaisesRegex(ValueError, "PID/schedule"):
            p.check_performance_result(result, runs)
        result["runs"][0]["owned_pid"] -= 1000
        result["runs"][1]["reverse_order"] = False
        with self.assertRaisesRegex(ValueError, "PID/schedule"):
            p.check_performance_result(result, runs)

    def test_proof_recomputation_rejects_rehashed_fabricated_result(self):
        build, sources, hosts, proofs, performance = self.accepted_evidence()
        path = Path(proofs["base"]["result"]["path"])
        value = p.read_json(path)
        value["fabricated_metric"] = 123
        write_json(path, value)
        proofs["base"]["result"]["sha256"] = p.sha(path)
        with patch.object(p, "run_verifier", side_effect=self.fake_verifier), self.assertRaisesRegex(ValueError, "Recomputed independent proof differs"):
            p.validate_saved_proofs(proofs, performance, sources, hosts, build)

    def test_changed_settings_file_invalidates_saved_proof(self):
        build, sources, hosts, proofs, performance = self.accepted_evidence()
        item = proofs["device"]["inputs"]["cabinet-fit-settings.txt"]
        Path(item["copy_path"]).write_text("changed scale fit policy")
        with patch.object(p, "run_verifier", side_effect=self.fake_verifier), self.assertRaisesRegex(ValueError, "source/copy identity changed"):
            p.validate_saved_proofs(proofs, performance, sources, hosts, build)

    def test_archive_round_trip_and_finalize_preserve_exact_mzp(self):
        folder, candidate = self.candidate()
        before = Path(candidate["archive"]).read_bytes()
        installer = self.installer(folder, candidate)
        with patch.object(p, "run_verifier", side_effect=self.fake_verifier):
            self.assertEqual(p.validate_candidate(folder), candidate)
            final = p.finalize(folder, installer)
        self.assertEqual(final["status"], "qualified")
        self.assertEqual(final["archive_sha256"], candidate["archive_sha256"])
        self.assertEqual(Path(candidate["archive"]).read_bytes(), before)
        self.assertEqual(final["acceptance_policy"], p.ACCEPTANCE_POLICY)
        with patch.object(p, "run_verifier", side_effect=self.fake_verifier), self.assertRaisesRegex(ValueError, "already exists"):
            p.finalize(folder, installer)

    def test_archive_tamper_cannot_finalize(self):
        folder, candidate = self.candidate()
        installer = self.installer(folder, candidate)
        with Path(candidate["archive"]).open("ab") as stream:
            stream.write(b"changed after installer")
        with self.assertRaisesRegex(ValueError, "archive changed"):
            p.finalize(folder, installer)
        self.assertFalse((folder / "qualification-receipt.json").exists())

    def test_installer_must_execute_the_same_candidate(self):
        folder, candidate = self.candidate()
        installer = self.installer(folder, candidate)
        path = installer / "receipt.json"
        record = p.read_json(path)
        record["archive_sha256"] = "another-mzp"
        write_json(path, record)
        with patch.object(p, "run_verifier", side_effect=self.fake_verifier), self.assertRaisesRegex(ValueError, "unchanged candidate"):
            p.finalize(folder, installer)

    def test_installed_startup_needs_actual_modify_host(self):
        folder, candidate = self.candidate()
        installer = self.installer(folder, candidate)
        path = installer / "receipt.json"
        record = p.read_json(path)
        record["phases"]["startup"]["host_mode"] = "owned-batch"
        write_json(path, record)
        with patch.object(p, "run_verifier", side_effect=self.fake_verifier), self.assertRaisesRegex(ValueError, "Installed Modify controls"):
            p.finalize(folder, installer)

    def test_existing_candidate_is_preserved(self):
        out = self.root / "dist/existing"
        out.mkdir(parents=True)
        sentinel = out / "existing.mzp"
        sentinel.write_bytes(b"preserved archive")
        with self.assertRaisesRegex(ValueError, "already exists"):
            p.create_candidate(self.native, [], out, [], self.root / "unused")
        self.assertEqual(sentinel.read_bytes(), b"preserved archive")


if __name__ == "__main__":
    unittest.main()
