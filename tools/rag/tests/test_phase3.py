"""Regression contracts for compact provenance and pre-read corpus containment."""
import json
import os
from pathlib import Path
import unittest
from unittest import mock
import test_retrieval as fixtures
import retrieval
import catalog
from locations import corpus_location
from status import index_status


class ReviewFixes(unittest.TestCase):
    setUp = fixtures.RetrievalFixtures.setUp
    tearDown = fixtures.RetrievalFixtures.tearDown
    write = fixtures.RetrievalFixtures.write
    git = fixtures.RetrievalFixtures.git
    scan = fixtures.RetrievalFixtures.scan
    read_rows = fixtures.RetrievalFixtures.read_rows
    build = fixtures.RetrievalFixtures.build

    def test_compact_payload_preserves_complete_results_and_receipt(self):
        index = self.build()
        value = retrieval.search(index, "forRanges", top_k=5)
        self.assertEqual(value["schema"], "cyrus.search-response/2")
        self.assertLess(len(retrieval.encoded(value)), 64*1024)
        self.assertLess(len(retrieval.encoded(index_status(index))), 16*1024)
        self.assertLess(len(retrieval.encoded(retrieval.search(index, "absentxyz"))), 16*1024)
        identities = value["configuration_identities"]
        self.assertEqual(set(identities["git_state"]), {"branch", "head", "index_sha256"})
        logical = json.loads((index/"logical.json").read_bytes())
        self.assertIn("working_tree", logical["identities"]["git_state"])
        self.assertEqual(identities["build_receipt"]["sha256"], value["index_generation"])
        guide = next(row for row in value["results"] if row["path"] == self.current)
        self.assertEqual(guide["original_text"], self.body)
        self.assertTrue(guide["equivalent_sources"])

    def test_inventory_growth_does_not_grow_public_payload(self):
        snapshot = catalog.git_snapshot(self.root)
        sizes = []
        for n in (0, 10000):
            expanded = {**snapshot, "untracked": ["unrelated/" + str(i) for i in range(n)]}
            with mock.patch.object(catalog, "git_snapshot", return_value=expanded):
                index = self.build("growth-"+str(n))
            sizes.append(len(retrieval.encoded(index_status(index))))
        self.assertEqual(*sizes)

    def test_external_and_sibling_rejected_before_content_read(self):
        for target in (self.root.parent/"outside.json", self.root.parent/(self.root.name+"-sibling")/"corpus.json"):
            with mock.patch.object(Path, "read_bytes", side_effect=AssertionError("unsupported content read")), mock.patch.object(Path, "read_text", side_effect=AssertionError("unsupported content read")):
                with self.assertRaisesRegex(retrieval.RetrievalError, "inside"):
                    retrieval.build(self.root, target, self.audit, self.root/"_local/rag/indexes"/target.parent.name)
        self.assertTrue(list((self.root/"_local/rag/indexes").glob(".*.partial-*/failure.json")))

    def test_build_success_opens_in_reader_and_normalizes_parent_segments(self):
        self.corpus = self.corpus.parent/"docs"/".."/self.corpus.name
        index = self.build()
        connection, metadata = retrieval.open_index(index, self.root)
        connection.close()
        self.assertEqual(metadata["identities"]["corpus_path"], str(self.root/"fixture-corpus.json"))

    @unittest.skipUnless(os.name == "nt", "Windows spelling contract")
    def test_windows_case_spelling_is_accepted(self):
        location = corpus_location(Path(str(self.root).upper()), Path(str(self.corpus).lower()))
        self.assertEqual(location, self.corpus)
        self.corpus = Path(str(self.corpus).upper())
        connection, _ = retrieval.open_index(self.build(), Path(str(self.root).upper()))
        connection.close()

    def test_linked_file_and_linked_ancestor_rejected_before_read(self):
        for ancestor in (False, True):
            link = self.root/("linked-dir" if ancestor else "linked.json")
            try: link.symlink_to(self.corpus.parent if ancestor else self.corpus, target_is_directory=ancestor)
            except OSError as exc: self.skipTest("symlink creation unavailable: "+str(exc))
            target = link/self.corpus.name if ancestor else link
            with mock.patch.object(Path, "read_bytes", side_effect=AssertionError("linked content read")):
                with self.assertRaisesRegex(retrieval.RetrievalError, "link/reparse"):
                    retrieval.build(self.root, target, self.audit, self.root/"_local/rag/indexes"/link.name)
            link.unlink()

    def test_cli_preflight_precedes_implicit_audit_definition_read(self):
        import build_index
        from contextlib import redirect_stdout
        import io
        with mock.patch.object(Path, "read_text", side_effect=AssertionError("outside definition read")), redirect_stdout(io.StringIO()):
            code = build_index.main(["--root", str(self.root), "--corpus", str(self.root.parent/"external.json"), "--out", str(self.out)])
        self.assertEqual(code, 2)
