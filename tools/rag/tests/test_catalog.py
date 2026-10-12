"""Behavioral fixtures only; all test writes live under _local/rag/test-data."""
from __future__ import annotations

import copy
import csv
import hashlib
import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

TOOL = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOL))
import build_manifest as cli
import catalog
import verify_runs
from rules import (ConfigError, classify, knowledge_status, navigation_metadata, load_config, parse_folder_tokens,
                   path_key, policy_for, read_inventory)

CONFIG_PATH = TOOL / "config.toml"
CONFIG = load_config(CONFIG_PATH)
TEMP_BASE = TOOL.parents[1] / "_local" / "rag" / "test-data"


class RuleTests(unittest.TestCase):
    def test_folder_tokens_preserve_sources(self):
        actual = parse_folder_tokens("docs/Terrace_Workflow_0.79.5_2026-10-11/a.md", CONFIG)
        self.assertEqual((actual["path_version"], actual["path_date"]), ("0.79.5", "2026-10-11"))
        self.assertEqual(actual["version_source"], "docs/Terrace_Workflow_0.79.5_2026-10-11")
        self.assertEqual(actual["issues"], [])

    def test_missing_tokens_are_normal_and_filename_is_not_folder(self):
        actual = parse_folder_tokens("docs/report_0.79_2026-10-12.md", CONFIG)
        self.assertIsNone(actual["path_version"])
        self.assertIsNone(actual["path_date"])
        self.assertEqual(actual["issues"], [])

    def test_conflicting_tokens_have_no_arbitrary_winner(self):
        actual = parse_folder_tokens("v0.79_2026-10-11/v0.80_2026-10-12/report.md", CONFIG)
        self.assertIsNone(actual["path_version"])
        self.assertIsNone(actual["path_date"])
        self.assertEqual({i["issue"] for i in actual["issues"]}, {"conflicting_version", "conflicting_date"})

    def test_repeated_tokens_and_windows_separators(self):
        actual = parse_folder_tokens(r"docs\v0.79\v0.79\a.md", CONFIG)
        self.assertEqual(actual["path_version"], "0.79")
        self.assertIn("docs/v0.79/v0.79", actual["version_source"])

    def test_malformed_date_and_version(self):
        actual = parse_folder_tokens("docs/v0.79..5_2026-02-30_2026-1-01/a.md", CONFIG)
        self.assertIsNone(actual["path_date"])
        self.assertEqual({i["issue"] for i in actual["issues"]}, {"malformed_version", "malformed_date"})

    def test_kind_and_component_precedence(self):
        cases = [("AminScatter/tests/test_engine.cpp", "test", "Scatter"),
                 ("website/public/maps/Blätter_1_alpha.JPG", "texture", "website"),
                 ("Landing Page Design/New folder/hero.png", "design_image", "landing_design"),
                 ("website/public/hero.png", "website_image", "website"),
                 ("docs/evidence/a.png", "evidence_image", "docs"),
                 ("CyrusMCP/requirements.txt", "config", "MCP"),
                 ("Test Scene/a.max", "binary_asset", "other"),
                 ("README.md", "doc", "root")]
        for path, kind, component in cases:
            with self.subTest(path=path):
                result = classify(path, CONFIG)
                self.assertEqual((result["kind"], result["component"]), (kind, component))
                self.assertIn("kind:", result["classification_rule"])

    def test_case_insensitive_matching_retains_path_independently(self):
        self.assertEqual(classify(r"AMINSCATTER\src\ENGINE.CPP", CONFIG)["component"], "Scatter")
        self.assertEqual(path_key(r"Docs\Blätter.md"), "docs/blätter.md")

    def test_only_evidenced_files_are_generated(self):
        self.assertTrue(classify("AminScatter/scripts/AminScatterObject.ms", CONFIG)["generated"])
        self.assertIn("generate.cjs", classify("AminScatter/scripts/AminScatterObject.ms", CONFIG)["generated_source"])
        self.assertTrue(classify("website/src/content/reference.json", CONFIG)["generated"])
        self.assertFalse(classify("website/content/guide-chapters.json", CONFIG)["generated"])
        self.assertFalse(classify("other.json", CONFIG)["generated"])

    def test_inventory_join_preserves_verbatim_and_unicode(self):
        text = 'path,decision,reason\n"docs/Blätter 1.md",preserved-excluded,"Earlier scope, not obsolescence"\n'
        rows, audit = read_inventory(text, CONFIG)
        self.assertEqual(audit, [])
        row = rows[path_key("DOCS/Blätter 1.md")]
        self.assertEqual(row["reason"], "Earlier scope, not obsolescence")
        status, _ = knowledge_status(row["path"], row, CONFIG, {})
        self.assertEqual(status, "unknown")
        self.assertEqual(row["decision"], "preserved-excluded")

    def test_ambiguous_inventory_decisions_remain_unknown(self):
        for decision in ("preserved-excluded", "preserved-data", "preserved-tool-guide", "consolidated", "removed"):
            self.assertEqual(knowledge_status("docs/unclassified.md", {"decision": decision}, CONFIG, {})[0], "unknown")

    def test_current_evidence_overrides_old_history_without_mutation(self):
        row = {"decision": "retained-history", "reason": "old review"}
        original = dict(row)
        status, source = knowledge_status("AGENTS.md", row, CONFIG, {})
        self.assertEqual(status, "current")
        self.assertIn("maintained-entrypoints", source)
        self.assertEqual(row, original)
        self.assertEqual(knowledge_status("docs/old/report.md", row, CONFIG, {})[0], "historical")

    def test_navigation_is_independent_of_authority_and_dated_interface(self):
        path = "docs/Report_0.79_2026-10-11/README.md"
        references = {path_key(path): ["website/content/source-manifest.json", "README.md", "README.md"]}
        metadata = navigation_metadata(path, references)
        self.assertTrue(metadata["referenced_by_current_docs"])
        self.assertEqual(metadata["current_reference_sources"], ["README.md", "website/content/source-manifest.json"])
        self.assertEqual(knowledge_status(path, None, CONFIG, {})[0], "unknown")
        self.assertEqual(knowledge_status(path, {"decision": "retained-history"}, CONFIG, {})[0], "historical")
        self.assertEqual(knowledge_status("docs/Current_System_2026-10-05/CAPABILITY_MATRIX.md", None, CONFIG, {})[0], "current")

    def test_navigation_provenance_is_sorted_and_deduplicated(self):
        path = "docs/report.md"
        sources = ["website/content/z.json", "README.md", "website/content/a.json", "README.md"]
        expected = navigation_metadata(path, {path_key(path): sources})
        self.assertEqual(expected, navigation_metadata(path, {path_key(path): list(reversed(sources))}))
        self.assertEqual(len(expected["current_reference_sources"]), 3)
        self.assertEqual(navigation_metadata("unreferenced.md", {}),
                         {"referenced_by_current_docs": False, "current_reference_sources": []})

    def test_root_and_nested_texture_directories_are_metadata_only(self):
        for path in ("maps/a.jpg", "textures/a.exr", "assets/maps/a.jpg", "assets/textures/a.exr",
                     "maps/deeper/a.py", "textures/deeper/more/a.json", "assets/maps/deeper/a.txt",
                     r"MAPS\Blätter 1.JPG", r"Assets\TeXtUrEs\Deep\a.exr"):
            with self.subTest(path=path):
                self.assertEqual(policy_for(path, False, CONFIG)[0], "metadata_only")
        for directory in ("maps", "textures", "assets/maps", "assets/textures/deeper"):
            self.assertEqual(policy_for(directory, True, CONFIG)[0], "metadata_only")

    def test_texture_matching_uses_directory_segments_and_skip_precedence(self):
        for path in ("roadmaps/a.jpg", "textures_backup/a.exr", "assets/roadmaps/a.jpg",
                     "assets/textures_backup/a.exr", "maps", "textures", "maps.txt", "textures.jpg"):
            self.assertEqual(policy_for(path, False, CONFIG)[0], "full", path)
        for path in ("maps/private/a.jpg", "textures/node_modules/a.exr", "maps/token.key",
                     "assets/maps/credentials.json", "build/maps/a.jpg", "textures/.env"):
            self.assertEqual(policy_for(path, False, CONFIG)[0], "skip", path)

    def test_duplicate_inventory_rows_are_all_excluded(self):
        rows, audit = read_inventory("path,decision,reason\ndocs/a.md,maintained,one\nDOCS/A.md,retained-history,two\ndocs/a.md,maintained,three\n", CONFIG)
        self.assertEqual(rows, {})
        self.assertEqual([r["finding"] for r in audit], ["duplicate_inventory_row"] * 3)

    def test_invalid_inventory_paths_columns_decisions_and_csv(self):
        for data in ("../outside.md,maintained,a", "C:\\secret.md,maintained,a", "a.md,INVALID,a", "a.md,maintained,a,extra"):
            rows, audit = read_inventory("path,decision,reason\n" + data + "\n", CONFIG)
            self.assertEqual(rows, {})
            self.assertEqual(audit[0]["finding"], "invalid_inventory_row")
        self.assertEqual(read_inventory("path,status\na.md,current\n", CONFIG)[1][0]["finding"], "invalid_inventory_header")
        self.assertEqual(read_inventory('path,decision,reason\n"unterminated', CONFIG)[1][0]["finding"], "invalid_inventory_csv")

    def test_inspection_policy_checks_ancestors_and_sensitive_paths(self):
        for path in ("website/node_modules/a.js", "_local/rag/out/x.json", ".git/config", "CyrusLicensing/private/a.json", "a/.env", "a/token.key", "config.local.json"):
            self.assertEqual(policy_for(path, False, CONFIG)[0], "skip", path)
        self.assertEqual(policy_for(".env.example", False, CONFIG)[0], "full")
        for path in ("Test Scene/maps/Blätter_1_alpha.jpg", "LOGO.psd", "a.zip"):
            self.assertEqual(policy_for(path, False, CONFIG)[0], "metadata_only")

    def test_duplicate_groups_are_digest_based_and_unhashed_excluded(self):
        digest = hashlib.sha256(b"same").hexdigest()
        rows = [{"path": p, "size_bytes": 4, "sha256": digest, "hash_status": s} for p, s in
                (("b", "hashed"), ("a", "hashed"), ("unread", "skipped_policy"))]
        groups = catalog.assign_duplicates(rows)
        self.assertEqual(groups[0]["duplicate_group"], "sha256:" + digest)
        self.assertEqual(groups[0]["potential_duplicate_bytes"], 4)
        self.assertEqual(groups[0]["paths"], ["a", "b"])
        self.assertIsNone(rows[2]["duplicate_group"])
        self.assertEqual(catalog.assign_duplicates(list(reversed(rows))), groups)

    def test_git_rename_nul_parsing(self):
        result = catalog.parse_git_status('R  new name.md\0old name.md\0 M Blätter.md\0'.encode())
        self.assertEqual(next(r for r in result if r["xy"] == "R ")["original_path"], "old name.md")


class FixtureTests(unittest.TestCase):
    def setUp(self):
        TEMP_BASE.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(prefix="catalog-", dir=TEMP_BASE)
        self.root = Path(self.temporary.name) / "repo"
        self.root.mkdir()
        self.write(".gitignore", "/_local/\n*.ignored\n/Test Scene/\n")
        self.write("README.md", "# Fixture\nCurrent development: Scatter 3.2.1 / package metadata 3.2.1 / schema 55\n[latest](docs/Trial_3.2.1_2026-10-12/README.md)\n")
        self.write("docs/documentation-inventory.csv", "path,decision,reason\nAGENTS.md,retained-history,old record\ndocs/removed.md,removed,intentionally removed\ndocs/missing.md,maintained,unexpected\n")
        self.write("AGENTS.md", "fixture instructions\n")
        self.write("docs/Trial_3.2.1_2026-10-12/README.md", "bounded fixture evidence\n")
        self.write("CyrusSurfaceAnalyzer/README.md", "# Cyrus Surface Analyzer 0.14\n")
        self.write("CyrusMCP/README.md", "Package is **0.73.0**, closed authoring plan **0.73**\n")
        self.write("website/content/source-manifest.json", '{"documents":[],"reviewedSourceHashes":{}}\n')
        self.git("init", "-q")
        self.git("config", "user.email", "fixture@example.invalid")
        self.git("config", "user.name", "Temporary catalog fixture")
        self.git("config", "core.autocrlf", "false")
        self.git("config", "commit.gpgsign", "false")
        self.git("config", "core.hooksPath", str(self.root / "_local" / "empty-hooks"))
        self.git("add", ".")
        self.git("commit", "-qm", "fixture baseline")

    def tearDown(self):
        self.temporary.cleanup()

    def write(self, relative, content):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8", newline="\n")
        return path

    def git(self, *args):
        return subprocess.run(["git", "-C", str(self.root), *args], check=True, stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE, env=dict(os.environ, GIT_OPTIONAL_LOCKS="0")).stdout

    def scan(self, name="run", config_path=CONFIG_PATH):
        from contextlib import redirect_stderr
        with redirect_stderr(io.StringIO()):
            return cli.run_audit(self.root, self.root / "_local" / "rag" / "out" / name, config_path)

    def read_rows(self, directory, partial=False):
        stem = "manifest.partial" if partial else "manifest"
        return [json.loads(line) for line in (directory / f"{stem}.jsonl").read_text(encoding="utf-8").splitlines()]

    def test_two_scans_have_identical_deterministic_artifacts(self):
        self.write("docs/Blätter 1.md", "identical\n")
        self.write("Landing Page Design/New folder/duplicate.md", "identical\n")
        code_a, a = self.scan("one")
        code_b, b = self.scan("two")
        self.assertEqual((code_a, code_b), (0, 0))
        for name in ("manifest.jsonl", "manifest.csv", "inventory_audit.csv", "summary.md", "duplicates.json", "exclusions.csv", "errors.jsonl", "path_token_issues.csv"):
            self.assertEqual((a / name).read_bytes(), (b / name).read_bytes(), name)
        self.assertTrue(json.loads((a / "run.json").read_text())["scan_complete"])
        comparison = verify_runs.compare_runs(a, b)
        self.assertTrue(comparison["deterministic_artifacts_identical"])
        self.assertTrue(comparison["observed_inputs_unchanged"])
        rows = self.read_rows(a)
        self.assertEqual(sum(r["path"].startswith("_local/") for r in rows), 0)
        self.assertEqual(next(r for r in rows if r["path"] == "docs/Blätter 1.md")["kind"], "doc")
        run = json.loads((a / "run.json").read_text())
        self.assertEqual(next(v for v in run["versions"] if v["component"] == "Scatter")["version"], "3.2.1")

    def test_tracked_ignored_untracked_and_dirty_are_separate(self):
        self.write("tracked.ignored", "tracked despite pattern")
        self.git("add", "-f", "tracked.ignored")
        self.git("commit", "-qm", "tracked ignored fixture")
        self.write("tracked.ignored", "dirty tracked despite pattern")
        self.write("untracked Blätter.txt", "new")
        self.write("scratch.ignored", "ignored but inspectable")
        code, out = self.scan()
        self.assertEqual(code, 0)
        rows = {r["path"]: r for r in self.read_rows(out)}
        self.assertEqual(rows["tracked.ignored"]["git_status"], "tracked")
        self.assertEqual(rows["tracked.ignored"]["git_worktree_status"], " M")
        self.assertEqual(rows["untracked Blätter.txt"]["git_status"], "untracked")
        self.assertEqual(rows["untracked Blätter.txt"]["git_worktree_status"], "??")
        self.assertEqual(rows["scratch.ignored"]["git_status"], "ignored")
        self.assertIsNone(rows["scratch.ignored"]["git_worktree_status"])
        self.assertEqual(rows["README.md"]["git_worktree_status"], "  ")

    def test_linked_history_retains_status_inventory_and_reference_sources(self):
        report = "docs/Trial_3.2.1_2026-10-12/README.md"
        inventory = self.root / "docs/documentation-inventory.csv"
        self.write("docs/documentation-inventory.csv", inventory.read_text() + report + ",retained-history,original historical reason\n")
        self.write("README.md", (self.root / "README.md").read_text() + f"[again]({report})\n")
        digest = hashlib.sha256((self.root / report).read_bytes()).hexdigest()
        self.write("website/content/source-manifest.json", json.dumps({"documents": [], "reviewedSourceHashes": {report: digest}}))
        code, out = self.scan()
        self.assertEqual(code, 0)
        row = next(r for r in self.read_rows(out) if r["path"] == report)
        self.assertEqual(row["knowledge_status"], "historical")
        self.assertEqual(row["inventory_decision"], "retained-history")
        self.assertEqual(row["inventory_reason"], "original historical reason")
        self.assertTrue(row["referenced_by_current_docs"])
        self.assertEqual(row["current_reference_sources"], ["README.md", "website/content/source-manifest.json"])
        self.assertIn("inventory:retained-history", row["status_source"])
        with (out / "manifest.csv").open(encoding="utf-8", newline="") as handle:
            csv_rows = {r["path"]: r for r in csv.DictReader(handle)}
        self.assertEqual(json.loads(csv_rows[report]["current_reference_sources"]), row["current_reference_sources"])
        self.assertEqual(csv_rows[report]["referenced_by_current_docs"], "true")
        self.assertEqual(json.loads(csv_rows[".gitignore"]["current_reference_sources"]), [])
        with (out / "inventory_audit.csv").open(encoding="utf-8", newline="") as handle:
            self.assertFalse(any(r["finding"] == "authority_conflict" and r["path"] == report for r in csv.DictReader(handle)))

    def test_unclassified_linked_report_stays_unknown(self):
        code, out = self.scan()
        self.assertEqual(code, 0)
        rows = {r["path"]: r for r in self.read_rows(out)}
        row = rows["docs/Trial_3.2.1_2026-10-12/README.md"]
        self.assertEqual(row["knowledge_status"], "unknown")
        self.assertTrue(row["referenced_by_current_docs"])
        self.assertEqual(row["current_reference_sources"], ["README.md"])
        self.assertEqual(rows["AGENTS.md"]["knowledge_status"], "current")
        self.assertEqual(rows["AGENTS.md"]["inventory_decision"], "retained-history")

    def test_curated_maintained_entries_and_supporting_paths_are_distinct(self):
        curated, support, incidental = "docs/curated.md", "docs/support.md", "docs/incidental.md"
        for path in (curated, support, incidental):
            self.write(path, "fixture\n")
        inventory = self.root / "docs/documentation-inventory.csv"
        self.write("docs/documentation-inventory.csv", inventory.read_text() + support + ",retained-history,historical evidence\n")
        manifest = {"documents": [{"path": curated}, {"path": curated}], "catalog": incidental,
                    "reviewedSourceHashes": {support: hashlib.sha256((self.root / support).read_bytes()).hexdigest()}}
        self.write("website/content/source-manifest.json", json.dumps(manifest))
        code, out = self.scan()
        self.assertEqual(code, 0)
        rows = {r["path"]: r for r in self.read_rows(out)}
        self.assertEqual(rows[curated]["knowledge_status"], "current")
        self.assertIn("rule:curated-maintained-source", rows[curated]["status_source"])
        self.assertEqual(rows[support]["knowledge_status"], "historical")
        self.assertEqual(rows[incidental]["knowledge_status"], "unknown")
        for path in (curated, support, incidental):
            self.assertEqual(rows[path]["current_reference_sources"], ["website/content/source-manifest.json"])

    def test_nondesignated_source_manifest_does_not_grant_authority(self):
        target = "docs/curated.md"
        self.write(target, "fixture")
        self.write("website/content/source-manifest.json", json.dumps({"documents": [{"path": target}]}))
        configuration = CONFIG_PATH.read_text().replace('maintained_source_manifests = ["website/content/source-manifest.json"]', 'maintained_source_manifests = []')
        local_config = self.write("fixture-config.toml", configuration)
        code, out = self.scan(config_path=local_config)
        self.assertEqual(code, 0)
        row = next(r for r in self.read_rows(out) if r["path"] == target)
        self.assertEqual(row["knowledge_status"], "unknown")
        self.assertTrue(row["referenced_by_current_docs"])

    def test_all_texture_directory_descendants_are_never_opened(self):
        relatives = ("maps/a.jpg", "textures/a.exr", "maps/Deep/Blätter 1.py", "textures/Deep/a.json",
                     "assets/maps/a.jpg", "assets/textures/Deeper/a.exr", "assets/maps/Deeper/a.txt")
        targets = {self.write(path, "content that must remain unread") for path in relatives}
        original_open, original_path_open = catalog.os.open, Path.open
        def guarded_open(path, *args, **kwargs):
            self.assertNotIn(Path(path), targets, "texture contents opened")
            return original_open(path, *args, **kwargs)
        def guarded_path_open(path, *args, **kwargs):
            self.assertNotIn(path, targets, "texture contents opened through Path.open")
            return original_path_open(path, *args, **kwargs)
        with mock.patch.object(catalog.os, "open", side_effect=guarded_open), mock.patch.object(Path, "open", guarded_path_open):
            code, out = self.scan()
        self.assertEqual(code, 0)
        rows = {r["path"]: r for r in self.read_rows(out)}
        for path in relatives:
            self.assertEqual(rows[path]["path"], path)
            self.assertEqual(rows[path]["inspection_policy"], "metadata_only")
            self.assertEqual(rows[path]["hash_status"], "skipped_policy")
            self.assertTrue(rows[path]["catalog_only"])
            self.assertIsNone(rows[path]["sha256"])

    def test_metadata_only_files_never_opened_for_hashing(self):
        for path in ("Test Scene/maps/Blätter_1_alpha.jpg", "LOGO.psd", "models.zip"):
            self.write(path, "must never hash")
        original_open = catalog.os.open
        opened = []
        def guarded_open(path, *args, **kwargs):
            opened.append(str(path))
            self.assertNotIn("Test Scene", str(path))
            self.assertNotIn("LOGO.psd", str(path))
            self.assertNotIn("models.zip", str(path))
            return original_open(path, *args, **kwargs)
        with mock.patch.object(catalog.os, "open", side_effect=guarded_open):
            code, out = self.scan()
        self.assertEqual(code, 0)
        for row in self.read_rows(out):
            if row["inspection_policy"] == "metadata_only":
                self.assertIsNone(row["sha256"])
                self.assertEqual(row["hash_status"], "skipped_policy")
                self.assertTrue(row["catalog_only"])
        self.assertTrue(opened)

    def test_skip_directories_not_traversed_and_counts_unknown(self):
        self.write("build/do-not-read.txt", "secret")
        self.write("website/node_modules/do-not-read.js", "secret")
        self.write("private/do-not-read.txt", "secret")
        original_scandir = catalog.os.scandir
        def guarded_scandir(path):
            self.assertNotIn(Path(path).name, ("build", "node_modules", "private", ".git"))
            return original_scandir(path)
        with mock.patch.object(catalog.os, "scandir", side_effect=guarded_scandir):
            code, out = self.scan()
        self.assertEqual(code, 0)
        rows = self.read_rows(out)
        self.assertFalse(any("do-not-read" in r["path"] for r in rows))
        with (out / "exclusions.csv").open(encoding="utf-8", newline="") as handle:
            exclusions = list(csv.DictReader(handle))
        self.assertEqual(next(r for r in exclusions if r["path"] == "build")["file_count"], "")

    def test_size_limit_skips_content_without_loading_it(self):
        path = self.root / "large.dat"
        with path.open("wb") as handle:
            handle.truncate(CONFIG["max_hash_bytes"] + 1)
        code, out = self.scan()
        self.assertEqual(code, 0)
        row = next(r for r in self.read_rows(out) if r["path"] == "large.dat")
        self.assertEqual(row["hash_status"], "skipped_size")
        self.assertEqual(row["inspection_policy"], "full")
        self.assertTrue(row["catalog_only"])
        self.assertIsNone(row["sha256"])

    def test_unreadable_file_preserves_diagnostics_without_success_output(self):
        target = self.write("cannot-read.txt", "content")
        original = catalog.os.open
        def denied(path, *args, **kwargs):
            if Path(path) == target:
                raise PermissionError("fixture permission denied")
            return original(path, *args, **kwargs)
        with mock.patch.object(catalog.os, "open", side_effect=denied):
            code, partial = self.scan()
        self.assertEqual(code, 3)
        self.assertFalse((self.root / "_local/rag/out/run").exists())
        self.assertFalse((partial / "manifest.jsonl").exists())
        row = next(r for r in self.read_rows(partial, True) if r["path"] == "cannot-read.txt")
        self.assertEqual(row["hash_status"], "error")
        self.assertIn("fixture permission denied", (partial / "errors.jsonl").read_text())
        self.assertFalse(json.loads((partial / "run.json").read_text())["scan_complete"])

    def test_file_changed_while_hashing_has_no_stable_digest(self):
        path = self.write("unstable.txt", "before")
        before = path.stat()
        real_sha = hashlib.sha256
        class MutatingDigest:
            def __init__(self):
                self.digest = real_sha()
            def update(self, chunk):
                self.digest.update(chunk)
                path.write_text("AFTER!", encoding="utf-8")
            def hexdigest(self):
                return self.digest.hexdigest()
        with mock.patch.object(catalog.hashlib, "sha256", MutatingDigest):
            digest, status, message = catalog.stable_hash(path, before, CONFIG["max_hash_bytes"], self.root)
        self.assertIsNone(digest)
        self.assertEqual(status, "changed_during_scan")
        self.assertIsNotNone(message)

    def test_file_disappearing_after_cataloging_makes_run_incomplete(self):
        target = self.write("vanishing.txt", "content")
        original = catalog.verify_scan
        def disappear(*args):
            target.unlink()
            return original(*args)
        with mock.patch.object(cli, "verify_scan", side_effect=disappear):
            code, out = self.scan()
        self.assertEqual(code, 3)
        row = next(r for r in self.read_rows(out, True) if r["path"] == "vanishing.txt")
        self.assertEqual(row["hash_status"], "changed_during_scan")
        self.assertIsNone(row["sha256"])

    def test_invalid_inventory_is_integrity_failure(self):
        self.write("docs/documentation-inventory.csv", "path,decision,reason\na.md,maintained,x\nA.md,retained-history,y\n")
        code, out = self.scan()
        self.assertEqual(code, 3)
        self.assertIn("duplicate_inventory_row", (out / "errors.jsonl").read_text())

    def test_reconciliation_keeps_missing_removed_and_conflicts_separate(self):
        code, out = self.scan()
        self.assertEqual(code, 0)
        with (out / "inventory_audit.csv").open(encoding="utf-8", newline="") as handle:
            audit = list(csv.DictReader(handle))
        self.assertEqual(next(r for r in audit if r["path"] == "docs/removed.md")["finding"], "missing_intentionally_removed")
        self.assertEqual(next(r for r in audit if r["path"] == "docs/missing.md")["finding"], "missing_unexpected")
        self.assertIn("authority_conflict", [r["finding"] for r in audit if r["path"] == "AGENTS.md"])
        self.assertIn("current_candidate_not_listed", [r["finding"] for r in audit])
        self.assertFalse(any(r["path"] in ("docs/removed.md", "docs/missing.md") for r in self.read_rows(out)))

    def test_source_fingerprint_conflict_is_audit_evidence_not_scan_error(self):
        manifest = {"documents": [{"path": "AGENTS.md"}], "reviewedSourceHashes": {"AGENTS.md": "0" * 64}}
        self.write("website/content/source-manifest.json", json.dumps(manifest))
        code, out = self.scan()
        self.assertEqual(code, 0)
        self.assertIn("source_fingerprint_mismatch", (out / "inventory_audit.csv").read_text())

    def test_existing_destination_rejected_without_rewriting(self):
        code, out = self.scan()
        before = (out / "run.json").read_bytes()
        self.assertEqual(code, 0)
        with self.assertRaises(ConfigError):
            self.scan()
        self.assertEqual(before, (out / "run.json").read_bytes())

    def test_comparison_identifies_changed_inputs(self):
        _, first = self.scan("before")
        self.write("README.md", "# Fixture changed\nCurrent development: Scatter 3.2.2\n")
        _, second = self.scan("after")
        result = verify_runs.compare_runs(first, second)
        self.assertFalse(result["deterministic_artifacts_identical"])
        self.assertFalse(result["observed_inputs_unchanged"])
        self.assertIn("README.md", result["changed_paths"])

    def test_incompatible_schema_comparison_is_rejected(self):
        _, first = self.scan("schema-before")
        _, second = self.scan("schema-after")
        metadata = second / "run.json"
        value = json.loads(metadata.read_text())
        value["schema_version"] = "cyrus.file-catalog/1"
        metadata.write_text(json.dumps(value), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "incompatible manifest schemas"):
            verify_runs.compare_runs(first, second)
        from contextlib import redirect_stdout
        captured = io.StringIO()
        with redirect_stdout(captured):
            code = verify_runs.main([str(first), str(second)])
        self.assertEqual(code, 2)
        self.assertIn("not a determinism comparison", captured.getvalue())

    def test_publication_failure_is_explicitly_partial(self):
        with mock.patch.object(Path, "rename", side_effect=OSError("fixture publication failure")):
            code, out = self.scan()
        self.assertEqual(code, 3)
        self.assertFalse(json.loads((out / "run.json").read_text())["scan_complete"])
        self.assertIn("publication failure", (out / "errors.jsonl").read_text())

    def test_invalid_rule_configuration_fails_with_code_two(self):
        bad = self.write("bad-rule.toml", CONFIG_PATH.read_text().replace('evidence = "website/content/README.md"', 'missing_evidence = "website/content/README.md"'))
        with self.assertRaises(ConfigError):
            load_config(bad)

    def test_invalid_configuration_and_output_location(self):
        bad = self.write("invalid.toml", "schema_version = 99\n")
        self.assertEqual(cli.main(["--root", str(self.root), "--out", str(self.root / "_local/rag/out/run"), "--config", str(bad)]), 2)
        with self.assertRaises(ConfigError):
            cli.prepare_output(self.root, self.root / "outside")

    def test_directory_change_is_detected(self):
        self.write("docs/existing.txt", "stable")
        original = catalog.verify_scan
        def add_file(*args):
            self.write("docs/concurrent.txt", "created concurrently")
            return original(*args)
        with mock.patch.object(cli, "verify_scan", side_effect=add_file):
            code, out = self.scan()
        self.assertEqual(code, 3)
        self.assertIn("verify_directory", (out / "errors.jsonl").read_text())

    def test_symlink_target_not_traversed(self):
        outside = Path(self.temporary.name) / "outside"
        outside.mkdir()
        (outside / "outside.txt").write_text("not a repository input")
        link = self.root / "linked"
        try:
            link.symlink_to(outside, target_is_directory=True)
        except OSError as exc:
            self.skipTest(f"symlinks unavailable: {exc}")
        code, out = self.scan()
        self.assertEqual(code, 0)
        self.assertFalse(any(r["path"].startswith("linked/") for r in self.read_rows(out)))
        self.assertIn("symlink/junction/reparse point", (out / "exclusions.csv").read_text())
        link.unlink()

    @unittest.skipUnless(os.name == "nt", "Windows junction fixture")
    def test_junction_target_not_traversed(self):
        target = Path(self.temporary.name) / "junction-target"
        target.mkdir()
        (target / "outside.txt").write_text("outside")
        link = self.root / "junction"
        result = subprocess.run(["cmd", "/c", "mklink", "/J", str(link), str(target)], capture_output=True)
        if result.returncode:
            self.skipTest("junction creation unavailable")
        try:
            self.assertTrue(catalog.is_link(link.lstat()))
            code, out = self.scan()
            self.assertEqual(code, 0)
            self.assertFalse(any(r["path"].startswith("junction/") for r in self.read_rows(out)))
        finally:
            os.rmdir(link)

    def test_cli_subprocess_exit_code_and_progress(self):
        result = subprocess.run([sys.executable, "-B", str(TOOL / "build_manifest.py"), "--root", str(self.root),
                                 "--out", str(self.root / "_local/rag/out/subprocess")], capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr.decode("utf-8", "replace"))
        self.assertIn(b"COMPLETE:", result.stderr)
        self.assertEqual(result.stdout, b"")


if __name__ == "__main__":
    unittest.main()
