"""Owned local fixtures for citation integrity, retrieval and evaluation contracts."""
from __future__ import annotations

import copy
import io
import json
import sqlite3
import sys
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import test_catalog as phase1
import evaluation
import extract
import retrieval
import search as search_cli


class ChunkTests(unittest.TestCase):
    def source(self, path="a.md", text="# Heading\n\nOriginal ي ك\n"):
        return {"path": path, "sha256": retrieval.digest(text.encode()), "ranges": [[1, len(text.splitlines())]]}

    def test_exact_original_offsets_and_stable_ids(self):
        text = "# Heading\r\n\r\nOriginal ي ك\r\n\r\nMore words\r\n"
        source = self.source(text=text)
        first = extract.chunks(text, source, retrieval.settings())
        self.assertEqual(first, extract.chunks(text, source, retrieval.settings()))
        for chunk in first:
            loc = chunk["locator"]
            self.assertEqual(text[loc["start_offset"]:loc["end_offset"]], chunk["original_text"])
            self.assertIn("Heading", chunk["context"])
        self.assertIn("ي ك", "".join(c["original_text"] for c in first))
        self.assertIn("ی ک", " ".join(c["search_text"] for c in first))

    def test_large_function_and_single_line_are_bounded_without_gaps(self):
        text = "def large():\n" + "    very_long_name = 1\n" * 100 + "x" * 1000 + "\n"
        bounds = {**retrieval.settings(), "max_chunk_chars": 80, "max_chunk_lines": 4, "overlap_lines": 1}
        chunks = extract.chunks(text, self.source("a.py", text), bounds)
        through = 0
        for chunk in chunks:
            loc = chunk["locator"]
            self.assertLessEqual(len(chunk["original_text"]), 80)
            self.assertLessEqual(loc["end_line"] - loc["start_line"] + 1, 4)
            self.assertLessEqual(loc["start_offset"], through)
            through = max(through, loc["end_offset"])
            self.assertEqual(chunk["method"], "declaration-line-window")
        self.assertEqual(through, len(text))

    def test_unicode_normalization_preserves_names_versions_and_hashes(self):
        self.assertEqual(extract.normalize("كیك ي\u200cك  Foo_Bar 0.79.5 AbC123"), "کیک ی ک foo_bar 0.79.5 abc123")

    def test_structured_text_records_line_locators_and_limits(self):
        text = '{\n "value": 3,\n "unit": "ms"\n}\n'
        chunk = extract.chunks(text, self.source("a.json", text), retrieval.settings())[0]
        self.assertEqual(chunk["method"], "structured-line-window")
        self.assertEqual((chunk["locator"]["start_line"], chunk["locator"]["end_line"]), (1, 4))
        self.assertIn("not AST", chunk["method_limits"])


class RetrievalFixtures(unittest.TestCase):
    write = phase1.FixtureTests.write
    git = phase1.FixtureTests.git
    scan = phase1.FixtureTests.scan
    read_rows = phase1.FixtureTests.read_rows

    def setUp(self):
        phase1.FixtureTests.setUp(self)
        self.current = "docs/ARTIST_GUIDE.md"
        self.history = "docs/older.md"
        self.unknown = "docs/unclassified.md"
        self.duplicate = "docs/copy.md"
        self.body = "# Guide\n\nforRanges joins workers. Version 0.79.5.\n\nفارسی كاربرد يک\u200cبار\n"
        self.write(self.current, self.body)
        self.write(self.duplicate, self.body)
        self.write(self.history, "# Past\n\nforRanges historical evidence schema 54.\n")
        self.write(self.unknown, "# Unknown\n\nforRanges unknown evidence.\n")
        inventory = self.root / "docs/documentation-inventory.csv"
        self.write("docs/documentation-inventory.csv", inventory.read_text() + self.history + ",retained-history,keep reason\n")
        self.write("maps/not-open.txt", "forbidden content")
        self.write("private/not-open.txt", "forbidden content")
        code, self.audit = self.scan()
        self.assertEqual(code, 0)
        self.rows = {r["path"]: r for r in self.read_rows(self.audit)}
        sources = []
        for path in (self.current, self.history, self.unknown, self.duplicate):
            row = self.rows[path]
            source = {k: row[k] for k in ("path", "sha256", "knowledge_status", "status_source", "inventory_decision", "inventory_reason", "referenced_by_current_docs", "current_reference_sources", "component", "generated", "generated_source")}
            source.update(role="maintained_guide" if path == self.current else "historical_evidence", selection_reason="fixture evidence", review_status="fixture", applicability={"snapshot": "fixture", "limits": "fixture"}, canonical={"preferred_path": self.current if path == self.duplicate else path}, ranges=[[1, len((self.root/path).read_text(encoding="utf-8").splitlines())]])
            sources.append(source)
        self.definition = {"schema": "cyrus.corpus/1", "sources": sources}
        self.corpus = self.write("fixture-corpus.json", json.dumps(self.definition))
        self.policy = retrieval.load_config(retrieval.TOOL / "config.toml")
        self.out = self.root / "_local/rag/indexes/first"

    def tearDown(self):
        phase1.FixtureTests.tearDown(self)

    def build(self, name="first"):
        out = self.root / "_local/rag/indexes" / name
        retrieval.build(self.root, self.corpus, self.audit, out)
        return out

    def test_full_enrollment_retains_inventory_and_provenance(self):
        corpus, texts, run = retrieval.load_corpus(self.root, self.corpus, self.audit, self.policy, retrieval.settings())
        self.assertEqual(corpus["sources"][1]["inventory_reason"], "keep reason")
        self.assertEqual(corpus["sources"][1]["knowledge_status"], "historical")
        self.assertEqual(texts[self.current], self.body)

    def test_metadata_excluded_unhashed_and_tooling_sources_rejected_before_open(self):
        for path in ("maps/not-open.txt", "private/not-open.txt", "tools/rag/evaluation.json"):
            altered = copy.deepcopy(self.definition)
            altered["sources"][0].update(path=path, sha256="0" * 64)
            self.corpus.write_text(json.dumps(altered), encoding="utf-8")
            with mock.patch.object(retrieval, "read_source", side_effect=AssertionError("opened rejected input")):
                with self.assertRaises(retrieval.RetrievalError):
                    retrieval.load_corpus(self.root, self.corpus, self.audit, self.policy, retrieval.settings())
        with mock.patch.object(retrieval.os, "open", side_effect=AssertionError("opened metadata input")):
            with self.assertRaises(retrieval.RetrievalError):
                retrieval.read_source(self.root, "maps/not-open.txt", "0"*64, self.policy, 1000)

    def test_mismatching_parent_hash_fails_and_leaves_diagnostics(self):
        self.write(self.current, self.body + "changed\n")
        with self.assertRaises(retrieval.StaleIndex):
            self.build()
        self.assertFalse(self.out.exists())
        self.assertTrue(list(self.out.parent.glob(".first.partial-*/failure.json")))

    def test_source_change_during_build_is_detected(self):
        original = retrieval.read_source
        changed = False
        def racing(root, path, *args):
            nonlocal changed
            text = original(root, path, *args)
            if path == self.current and not changed:
                changed = True
                self.write(self.current, self.body + "racing\n")
            return text
        with mock.patch.object(retrieval, "read_source", side_effect=racing):
            with self.assertRaises(retrieval.StaleIndex):
                self.build()
        self.assertFalse(self.out.exists())

    def test_changed_or_disappeared_returned_parent_is_stale(self):
        index = self.build()
        self.write(self.current, self.body + "changed\n")
        with self.assertRaises(retrieval.StaleIndex):
            retrieval.search(index, self.current, mode="path")
        (self.root / self.history).unlink()
        with self.assertRaises(retrieval.StaleIndex):
            retrieval.search(index, self.history, mode="path")

    def test_exact_identifier_path_and_version_queries(self):
        index = self.build()
        for query in ("forRanges", "0.79.5"):
            result = retrieval.search(index, query, mode="identifier")
            self.assertTrue(result["results"])
            self.assertTrue(all(r["match"]["exact_identifier"] for r in result["results"]))
        result = retrieval.search(index, r"DOCS\ARTIST_GUIDE.MD", mode="path")
        self.assertEqual({r["path"] for r in result["results"]}, {self.current})
        self.assertFalse(retrieval.search(index, "0.79", mode="identifier")["results"])
        self.assertFalse(retrieval.search(index, "79.5", mode="identifier")["results"])
        self.assertFalse(retrieval.search(index, "forRange", mode="identifier")["results"])

    def test_ordinary_quotes_punctuation_and_sql_are_data(self):
        index = self.build()
        for query in ('"forRanges"', "forRanges()", "forRanges OR '); DROP TABLE chunks; --", "(", '"'):
            retrieval.search(index, query)
        self.assertTrue(retrieval.search(index, "forRanges")["results"])
        with self.assertRaisesRegex(retrieval.RetrievalError, "FTS"):
            retrieval.search(index, "(", advanced=True)

    def test_current_filter_does_not_promote_historical_or_unknown(self):
        index = self.build()
        for status in ("current", "historical", "unknown"):
            result = retrieval.search(index, "forRanges", filters={"knowledge_status": status, "component": "docs"})
            self.assertTrue(result["results"])
            self.assertTrue(all(r["source"]["knowledge_status"] == status for r in result["results"]))
            self.assertTrue(all(a["source"]["knowledge_status"] == status for r in result["results"] for a in r["equivalent_sources"]))
        self.assertFalse(retrieval.search(index, "forRanges", filters={"role": "proposal"})["results"])

    def test_duplicate_results_keep_each_paths_authority(self):
        result = retrieval.search(self.build(), "joins")
        self.assertEqual(len(result["results"]), 1)
        first = result["results"][0]
        self.assertEqual(first["path"], self.current)
        self.assertEqual(first["equivalent_sources"][0]["path"], self.duplicate)
        self.assertEqual(first["equivalent_sources"][0]["source"]["knowledge_status"], "unknown")

    def test_persian_query_normalization_and_original_excerpt(self):
        result = retrieval.search(self.build(), "کاربرد یک بار")
        self.assertTrue(result["results"])
        self.assertIn("كاربرد", result["results"][0]["original_text"])

    def test_two_builds_have_same_logical_export_and_ranking(self):
        first, second = self.build(), self.build("second")
        self.assertEqual((first / "logical.json").read_bytes(), (second / "logical.json").read_bytes())
        a, b = retrieval.search(first, "forRanges"), retrieval.search(second, "forRanges")
        a.pop("duration_seconds"); b.pop("duration_seconds")
        self.assertEqual(a, b)

    def test_json_cli_and_empty_outcome(self):
        index = self.build()
        output = io.StringIO()
        with redirect_stdout(output):
            self.assertEqual(search_cli.main(["--index", str(index), "--query", "absentword", "--json"]), 0)
        value = json.loads(output.getvalue())
        self.assertEqual(value["results"], [])
        self.assertFalse(value["stale"])

    def test_failed_publication_keeps_prior_index_bytes_and_usability(self):
        previous = self.build()
        before = (previous / "index.sqlite3").read_bytes()
        with mock.patch.object(Path, "rename", side_effect=OSError("owned publication failure")):
            with self.assertRaises(OSError):
                self.build("failed")
        self.assertEqual(before, (previous / "index.sqlite3").read_bytes())
        self.assertTrue(retrieval.search(previous, "joins")["results"])
        self.assertFalse((previous.parent / "failed").exists())

    def test_schema_config_and_corpus_compatibility(self):
        index = self.build()
        with mock.patch.object(retrieval, "settings", return_value={**retrieval.settings(), "max_chunk_chars": 100}):
            with self.assertRaisesRegex(retrieval.RetrievalError, "incompatibility"):
                retrieval.search(index, "joins")
        self.corpus.write_text("{}", encoding="utf-8")
        with self.assertRaises(retrieval.StaleIndex):
            retrieval.search(index, "joins")
        self.corpus.write_text(json.dumps(self.definition), encoding="utf-8")
        with sqlite3.connect(index / "index.sqlite3") as connection:
            metadata = json.loads(connection.execute("SELECT value FROM metadata").fetchone()[0])
            metadata["schema"] = "future/99"
            connection.execute("UPDATE metadata SET value=?", (json.dumps(metadata),))
        connection.close()
        with self.assertRaisesRegex(retrieval.RetrievalError, "incompatibility"):
            retrieval.search(index, "joins")

    def test_mutated_index_text_cannot_forge_valid_citation(self):
        index = self.build()
        with sqlite3.connect(index / "index.sqlite3") as connection:
            row = connection.execute("SELECT id,data FROM chunks WHERE path=?", (self.current,)).fetchone()
            record = json.loads(row[1]); record["original_text"] = "forged original"
            connection.execute("UPDATE chunks SET data=? WHERE id=?", (json.dumps(record), row[0]))
        connection.close()
        with self.assertRaisesRegex(retrieval.IntegrityError, "text/locator"):
            retrieval.search(index, self.current, mode="path")


class MetricTests(unittest.TestCase):
    def fixture(self):
        text = "one\ntwo\nthree\n"
        source = {"path": "a.md", "sha256": retrieval.digest(text.encode()), "ranges": [[1, 3]]}
        loc = {"path": "a.md", "sha256": source["sha256"], "start_line": 2, "end_line": 3}
        q = {"id": "fixture", "language": "en", "category": "workflow", "query": "two", "information_need": "test", "required_qualifiers": ["fixture"], "review_status": "fixture", "split": "holdout", "answerable": True, "required_evidence": [{"id": "unit", "alternatives": [loc], "canonical_paths": ["a.md"]}], "optional_evidence": [], "misleading_substitutions": []}
        return text, source, loc, q

    def test_label_hash_and_locator_validation(self):
        text, source, loc, q = self.fixture()
        dataset = {"schema": "cyrus.evaluation/1", "review_status": "fixture", "queries": [q], "anchors": []}
        self.assertEqual(evaluation.validate_labels(dataset, [source], {"a.md": text}, False)["hash_locators_validated"], 1)
        loc["sha256"] = "0"*64
        with self.assertRaises(retrieval.RetrievalError):
            evaluation.validate_labels(dataset, [source], {"a.md": text}, False)
        loc["sha256"] = source["sha256"]; loc["end_line"] = 99
        with self.assertRaises(ValueError):
            evaluation.validate_labels(dataset, [source], {"a.md": text}, False)

    def test_multi_chunk_coverage_alternatives_and_empty_metrics(self):
        text, source, loc, q = self.fixture()
        def result(a, b):
            return {"path": "a.md", "parent_sha256": source["sha256"], "locator": {"start_offset": a, "end_offset": b}}
        partial = evaluation.score_question(q, [result(4,8)], {"a.md": text})
        complete = evaluation.score_question(q, [result(4,8), result(8,14)], {"a.md": text})
        self.assertEqual(partial["at_k"]["5"]["required_recall"], 0)
        self.assertEqual(complete["at_k"]["5"]["required_recall"], 1)
        self.assertEqual(complete["canonical_reciprocal_rank"], 1)
        q["required_evidence"][0]["alternatives"].append({**loc, "start_line": 1, "end_line": 1})
        alternative = evaluation.score_question(q, [result(0,4)], {"a.md": text})
        self.assertEqual(alternative["at_k"]["10"]["required_recall"], 1)
        q["misleading_substitutions"] = [{"kind": "wrong_build", "evidence": {**loc, "start_line": 1, "end_line": 1}}]
        negative = {**q, "scores": alternative}
        # Rescore after adding the negative label; labels do not alter retrieval.
        negative["scores"] = evaluation.score_question(q, [result(0,4)], {"a.md": text})
        self.assertEqual(evaluation.aggregate([negative])["wrong_build_hits_at_10"], 1)
        scored = {**q, "scores": complete}
        self.assertEqual(evaluation.aggregate([scored])["required_evidence_coverage_at_10"], 1)
        q.update(answerable=False, required_evidence=[])
        empty = {**q, "scores": evaluation.score_question(q, [], {"a.md": text})}
        aggregate = evaluation.aggregate([empty])
        self.assertIsNone(aggregate["answerable_empty_rate"])
        self.assertEqual(aggregate["unanswerable_nonempty_count"], 0)


if __name__ == "__main__":
    unittest.main()
