"""Disposable regressions for terminology, read-only contracts and integrity checks."""
import copy
import io
import json
import sqlite3
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

import test_retrieval as previous
import contracts
import integrity
import lexical
import retrieval
import search as search_cli
import status


class TerminologyTests(unittest.TestCase):
    def compile(self, text, mode="keyword", advanced=False, profile="terminology", maximum=64):
        return lexical.compile_query(text, mode, advanced, profile, maximum)

    def test_one_hop_bounded_and_diagnostic(self):
        value = self.compile("authoring historical license expiry reimport saved scene")
        self.assertIn("mutation", value["search_terms"])
        self.assertIn("recorded", value["search_terms"])
        self.assertLessEqual(len(value["applied_expansions"]), 8)
        self.assertLessEqual(len(value["search_terms"])-len(value["original_terms"]), 16)
        glossary = {"max_applied_entries": 1, "max_added_terms": 1,
                    "entries": [{"concept": "first", "aliases": ["authoring"], "terms": ["mutation", "write"]},
                                {"concept": "second", "aliases": ["mutation"], "terms": ["recursive"]}]}
        with mock.patch.object(lexical, "load_glossary", return_value=glossary):
            value = self.compile("authoring")
            self.assertEqual(value["search_terms"], ["authoring", "mutation"])
            self.assertTrue(value["expansion_bound_reached"])
            self.assertNotIn("recursive", value["search_terms"])
        self.assertTrue(self.compile("authoring", maximum=1)["expansion_bound_reached"])

    def test_ambiguous_terms_and_protected_literals(self):
        for text in ("current model point source update", "license_issuer", "0.79.5", "abc123def456",
                     r"docs\license.md", "docs/license.md", "license.example", "license-hash"):
            self.assertFalse(self.compile(text)["applied_expansions"], text)
        for mode in ("identifier", "path"):
            self.assertFalse(self.compile("authoring", mode)["applied_expansions"])
        self.assertFalse(self.compile("authoring", advanced=True)["applied_expansions"])
        self.assertFalse(self.compile("authoring", profile="plain")["applied_expansions"])

    def test_unicode_original_terms_and_no_label_dependency(self):
        query = "انقضا لایسنس كاربرد يک\u200cبار"
        value = self.compile(query)
        self.assertIn("expired", value["search_terms"])
        self.assertIn("کاربرد", value["original_terms"])
        self.assertIn("یك".replace("ك", "ک"), value["original_terms"])
        self.assertIn("license", value["search_terms"])
        self.assertEqual(query, "انقضا لایسنس كاربرد يک\u200cبار")


class InterfaceFixtures(unittest.TestCase):
    write = previous.RetrievalFixtures.write
    git = previous.RetrievalFixtures.git
    scan = previous.RetrievalFixtures.scan
    read_rows = previous.RetrievalFixtures.read_rows
    setUp = previous.RetrievalFixtures.setUp
    tearDown = previous.RetrievalFixtures.tearDown
    build = previous.RetrievalFixtures.build

    def test_basic_status_does_not_claim_source_verification(self):
        index = self.build()
        with mock.patch.object(status, "read_source", side_effect=AssertionError("parent accessed")):
            response = status.index_status(index)
        self.assertEqual(response["schema"], contracts.STATUS_SCHEMA)
        self.assertTrue(response["ok"])
        self.assertEqual(response["sources_checked"], 0)
        self.assertFalse(response["all_sources_verified"])
        self.assertTrue(response["verification_checks"]["all_searchable_rows_against_export"])

    def test_all_sources_including_unreturned_changed_and_deleted(self):
        index = self.build()
        self.assertTrue(status.index_status(index, True)["all_sources_verified"])
        sample = retrieval.search(index, "joins")
        self.assertNotIn(self.history, [r["path"] for r in sample["results"]])
        self.write(self.history, "changed unreturned evidence\n")
        (self.root / self.unknown).unlink()
        self.assertTrue(retrieval.search(index, "joins")["ok"])
        response = status.index_status(index, True)
        self.assertFalse(response["ok"])
        self.assertFalse(response["all_sources_verified"])
        self.assertEqual(response["sources_checked"], 4)
        self.assertEqual(response["sources_verified"], 2)
        self.assertEqual({e["source_status"] for e in response["source_issues"]}, {"missing", "changed"})

    def test_inaccessible_parent_does_not_stop_other_checks(self):
        index = self.build()
        original = retrieval.os.open
        def denied(path, *args, **kwargs):
            if Path(path) == self.root / self.history:
                raise PermissionError("owned denied fixture")
            return original(path, *args, **kwargs)
        with mock.patch.object(retrieval.os, "open", side_effect=denied):
            response = status.index_status(index, True)
        self.assertEqual(response["sources_checked"], 4)
        self.assertEqual(response["sources_verified"], 3)
        self.assertEqual(response["source_issues"][0]["source_status"], "inaccessible")
        self.assertFalse(response["all_sources_verified"])

    def test_forbidden_policy_and_links_rejected_before_content_open(self):
        with mock.patch.object(retrieval.os, "open", side_effect=AssertionError("forbidden content opened")):
            for path in ("private/not-open.txt", "maps/not-open.txt"):
                with self.assertRaises(contracts.SourceProblem) as caught:
                    retrieval.read_source(self.root, path, "0"*64, self.policy, 1000)
                self.assertEqual(caught.exception.details["source_status"], "forbidden")
            with mock.patch.object(retrieval.catalog, "is_link", return_value=True):
                with self.assertRaises(contracts.SourceProblem) as caught:
                    retrieval.read_source(self.root, self.current, "0"*64, self.policy, 1000)
                self.assertEqual(caught.exception.details["source_status"], "forbidden")
        index = self.build()
        changed_policy = copy.deepcopy(self.policy)
        with mock.patch.object(status, "load_config", return_value=changed_policy), mock.patch.object(retrieval, "policy_for", return_value=("skip", "fixture")):
            response = status.index_status(index, True)
        self.assertEqual(response["sources_verified"], 0)
        self.assertEqual({e["source_status"] for e in response["source_issues"]}, {"forbidden"})

    def test_search_schema_original_citations_and_complete_limits(self):
        index = self.build()
        plain = retrieval.search(index, "forRanges", profile="plain")
        response = retrieval.search(index, "forRanges")
        self.assertEqual(response["schema"], contracts.SEARCH_SCHEMA)
        self.assertEqual(response["query"], "forRanges")
        self.assertEqual(response["results"], plain["results"])
        for n, result in enumerate(response["results"], 1):
            self.assertEqual(result["rank"], n)
            text = (self.root / result["path"]).read_text(encoding="utf-8")
            loc = result["locator"]
            self.assertEqual(result["original_text"], text[loc["start_offset"]:loc["end_offset"]])
            self.assertIn("limits", result["source"]["applicability"])
        self.assertIn("runtime_sha256", response["configuration_identities"])
        self.assertFalse(response["all_sources_verified"])

    def test_zero_invalid_stale_incompatible_and_io_envelopes(self):
        index = self.build()
        def cli(query, *extra):
            output = io.StringIO()
            with redirect_stdout(output):
                code = search_cli.main(["--index", str(index), "--query", query, "--json", *extra])
            value = json.loads(output.getvalue())
            self.assertEqual(value["schema"], contracts.SEARCH_SCHEMA)
            return code, value
        code, value = cli("absentword")
        self.assertEqual(code, 0)
        self.assertTrue(value["ok"])
        self.assertEqual(value["results"], [])
        for extra in (("--top-k", "0"), ("--advanced",)):
            code, value = cli("(", *extra)
            self.assertEqual((code, value["error_type"]), (2, "invalid_input"))
        with mock.patch.object(retrieval, "runtime_hashes", return_value={}):
            code, value = cli("joins")
        self.assertEqual((code, value["error_type"]), (2, "incompatible_index"))
        self.write(self.current, self.body + "changed\n")
        code, value = cli("joins")
        self.assertEqual((code, value["error_type"]), (3, "stale_evidence"))
        self.assertEqual(value["error_details"]["source_status"], "changed")
        (index / "run.json").unlink()
        code, value = cli("joins")
        self.assertEqual((code, value["error_type"]), (3, "io_failure"))

    def test_malformed_cli_and_status_error_are_machine_readable(self):
        for main, schema in ((search_cli.main, contracts.SEARCH_SCHEMA), (status.main, contracts.STATUS_SCHEMA)):
            output = io.StringIO()
            with redirect_stdout(output), self.assertRaises(SystemExit) as caught:
                main(["--unknown"])
            self.assertEqual(caught.exception.code, 2)
            self.assertEqual(json.loads(output.getvalue())["schema"], schema)
        index = self.build()
        (index / "index.sqlite3").write_bytes(b"not a database")
        output = io.StringIO()
        with redirect_stdout(output):
            self.assertEqual(status.main(["--index", str(index), "--verify-sources", "--json"]), 3)
        value = json.loads(output.getvalue())
        self.assertEqual(value["error_type"], "integrity_failure")
        self.assertFalse(value["all_sources_verified"])

    def test_explicit_root_ranking_and_runtime_compatibility(self):
        index = self.build()
        with self.assertRaises(contracts.IncompatibleIndex):
            retrieval.search(index, "joins", expected_root=self.root.parent)
        with mock.patch.object(retrieval, "ranking_config", return_value={**retrieval.ranking_config(), "default_profile": "plain"}):
            with self.assertRaises(contracts.IncompatibleIndex):
                status.index_status(index)
        with mock.patch.object(retrieval, "runtime_hashes", return_value={}):
            with self.assertRaises(contracts.IncompatibleIndex):
                retrieval.search(index, "joins")

    def test_all_exports_and_immutable_metadata_detect_mismatch(self):
        index = self.build()
        for name in ("logical.json", "chunks.jsonl"):
            path = index / name
            raw = path.read_bytes()
            path.write_bytes(raw + b" ")
            with self.assertRaises(contracts.IntegrityError):
                status.index_status(index)
            path.write_bytes(raw)
        with sqlite3.connect(index / "index.sqlite3") as connection:
            metadata = json.loads(connection.execute("SELECT value FROM metadata").fetchone()[0])
            metadata["sources"][0]["role"] = "proposal"
            connection.execute("UPDATE metadata SET value=?", (json.dumps(metadata),))
        connection.close()
        with self.assertRaisesRegex(contracts.IntegrityError, "metadata disagrees"):
            status.index_status(index)

    def test_actual_searchable_rows_checked_even_if_byte_receipt_is_replaced(self):
        index = self.build()
        with sqlite3.connect(index / "index.sqlite3") as connection:
            connection.execute("UPDATE search_chunks SET context='mismatching context' WHERE rowid=1")
        connection.close()
        run = json.loads((index / "run.json").read_bytes())
        run["artifact_sha256"]["index.sqlite3"] = retrieval.digest((index / "index.sqlite3").read_bytes())
        run["database_bytes"] = (index / "index.sqlite3").stat().st_size
        retrieval.write_json(index / "run.json", run)
        with self.assertRaisesRegex(contracts.IntegrityError, "FTS rows disagree"):
            status.index_status(index)

    def test_owned_artifact_link_rejection_before_open(self):
        index = self.build()
        with mock.patch.object(integrity.catalog, "is_link", return_value=True), mock.patch.object(integrity.os, "open", side_effect=AssertionError("link opened")):
            with self.assertRaises(contracts.IntegrityError):
                retrieval.search(index, "joins")

    def test_search_status_read_only_and_evaluation_isolation(self):
        index = self.build()
        before = {p.name: (p.read_bytes(), p.stat().st_mtime_ns) for p in index.iterdir()}
        original = Path.open
        def guard(path, *args, **kwargs):
            if path.suffix == ".json" and path.name.startswith(("evaluation", "challenge", "label-review")):
                raise AssertionError("production loaded evaluation data")
            return original(path, *args, **kwargs)
        with mock.patch.object(Path, "open", guard):
            retrieval.search(index, "joins")
            status.index_status(index, True)
        self.assertEqual(before, {p.name: (p.read_bytes(), p.stat().st_mtime_ns) for p in index.iterdir()})

    def test_response_bound_fails_explicitly_without_pruning(self):
        ranking = {**retrieval.ranking_config(), "max_response_bytes": 1024}
        with mock.patch.object(retrieval, "ranking_config", return_value=ranking):
            index = self.build()
            with self.assertRaisesRegex(contracts.RetrievalError, "response byte bound"):
                retrieval.search(index, "joins")
        self.assertTrue(index.exists())


if __name__ == "__main__":
    unittest.main()
