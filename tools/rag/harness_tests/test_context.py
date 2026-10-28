"""Consumer contracts: compact evidence is complete and failure stays explicit."""
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import context
from context_projection import compact, render


def evidence():
    return {'schema': 'cyrus.search-response/2', 'ok': True,
            'index_generation': 'a' * 64, 'freshness_scope': 'Returned parents only',
            'all_sources_verified': False, 'sources_checked': 1,
            'configuration_identities': {'root': 'root', 'corpus_path': 'reviewed.json',
                'corpus_sha256': 'b' * 64, 'build_receipt': {'sha256': 'a' * 64},
                'runtime_sha256': {'worker': 'c' * 64}},
            'diagnostics': {'applied_expansions': ['grass']},
            'results': [{'path': 'guide.md', 'parent_sha256': 'd' * 64,
                'original_text': 'Required guarantee. Except within quotas. فارسی',
                'search_text': 'required guarantee except within quotas',
                'excerpt': 'Required guarantee.', 'excerpt_truncated': True,
                'locator': {'start_line': 1, 'end_line': 3},
                'source': {'role': 'maintained_guide', 'knowledge_status': 'unknown',
                    'applicability': {'snapshot': 'Historical 0.87.1', 'limits': 'Host not qualified'},
                    'canonical': {'preferred_path': 'guide.md'}},
                'equivalent_sources': [{'path': 'duplicate.md', 'source': {'limits': 'Original qualifiers'}}],
                'method_limits': 'Full requirements are not qualification.'}]}


class Projection(unittest.TestCase):
    def test_full_source_and_qualifiers_survive_compaction(self):
        raw = evidence(); before = copy.deepcopy(raw); result = compact(raw, {'mode': 'explicit'})
        self.assertEqual(raw, before)
        for key in ['original_text', 'locator', 'parent_sha256', 'source', 'equivalent_sources', 'method_limits']:
            self.assertEqual(result['results'][0][key], raw['results'][0][key])
        self.assertEqual(result['diagnostics'], raw['diagnostics'])
        self.assertFalse(result['all_sources_verified'])
        self.assertEqual(result['freshness_scope'], raw['freshness_scope'])
        self.assertNotIn('search_text', result['results'][0])
        self.assertEqual(result['provenance']['generation'], raw['index_generation'])

    def test_budget_rejects_without_clipping_or_success(self):
        value = evidence(); value['results'][0]['original_text'] = 'whole contract ' * 5000
        result = render(value, {'mode': 'explicit'}, max_chars=512)
        self.assertFalse(result['ok']); self.assertEqual(result['results'], [])
        self.assertEqual(result['error_type'], 'context_budget_exceeded')
        self.assertGreater(result['required_chars'], result['max_chars'])

    def test_full_view_preserves_original_fields(self):
        raw = evidence(); result = render(raw, {}, detail='full')
        for key, value in raw.items(): self.assertEqual(result[key], value)

    def test_stale_and_integrity_errors_are_not_hidden(self):
        for category in ['stale_evidence', 'integrity_failure', 'incompatible_index']:
            raw = {'schema': 'cyrus.search-response/2', 'ok': False, 'error_type': category,
                   'results': [], 'error_details': {'path': 'file'}, 'action': 'Inspect source'}
            result = compact(raw, {})
            for key, value in raw.items(): self.assertEqual(result[key], value)

    def test_status_retains_all_failures_and_counts(self):
        raw = {'ok': False, 'source_issues': [{'path': 'a', 'source_status': 'changed', 'error': 'hash mismatch'}],
               'sources_checked': 64, 'sources_verified': 33, 'all_sources_verified': False,
               'corpus_scope': {'paths': ['a', 'b'], 'source_count': 64, 'limits': 'Explicit enrollment'}}
        result = compact(raw, {})
        self.assertEqual(result['source_issues'], raw['source_issues'])
        self.assertEqual(result['sources_verified'], 33)
        self.assertNotIn('paths', result['corpus_scope'])


class Binding(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(); self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.index = self.root / '_local/rag/indexes/test'
        self.index.mkdir(parents=True)
        (self.index / 'run.json').write_text(json.dumps({'complete': True,
            'identities': {'root': str(self.root)}, 'generation_id': 'a' * 64}))

    def test_explicit_index_must_be_owned(self):
        self.assertEqual(context.index_binding(self.root, self.index)[1]['mode'], 'explicit')
        with self.assertRaises(ValueError): context.index_binding(self.root, self.root)

    def test_foreign_generation_is_rejected(self):
        (self.index / 'run.json').write_text(json.dumps({'complete': True,
            'identities': {'root': 'another-root'}, 'generation_id': 'a' * 64}))
        with self.assertRaises(ValueError): context.index_binding(self.root, self.index)

    def test_bad_configured_scope_never_falls_back(self):
        p = self.root / '_local/rag/harness/selected.json'; p.parent.mkdir()
        p.write_text('{"schema":"wrong"}')
        with self.assertRaises(ValueError): context.index_binding(self.root)

    def test_selection_requires_matching_reviewed_acceptance(self):
        import hashlib
        folder = self.root / '_local/rag/harness'; folder.mkdir()
        receipt = folder / 'review.json'
        review = {'schema': 'cyrus.context-review/1', 'status': 'approved_scoped',
                  'generation': 'a' * 64, 'agent_reviewed': True}
        receipt.write_text(json.dumps(review))
        selected = {'schema': 'cyrus.context-selection/1', 'index': '_local/rag/indexes/test',
                    'generation': 'a' * 64, 'scope': 'test', 'exclusions': ['other scope'],
                    'review_receipt': '_local/rag/harness/review.json',
                    'review_sha256': hashlib.sha256(receipt.read_bytes()).hexdigest()}
        (folder / 'selected.json').write_text(json.dumps(selected))
        self.assertEqual(context.index_binding(self.root)[1]['mode'], 'scoped')
        receipt.write_text('{}')
        with self.assertRaises(ValueError): context.index_binding(self.root)

    def test_worker_generation_and_deadline_are_bound(self):
        result = subprocess.CompletedProcess([], 0, json.dumps({'ok': True, 'index_generation': 'b' * 64}).encode(), b'')
        with patch.object(context.subprocess, 'run', return_value=result) as run:
            with self.assertRaises(ValueError): context.execute(self.root, self.index, {'generation': 'a' * 64}, 'knowledge_status', {})
            self.assertEqual(run.call_args.kwargs['timeout'], 15)

    def test_worker_large_output_fails_closed(self):
        result = subprocess.CompletedProcess([], 0, b' ' * (context.MAX_WIRE + 1), b'')
        with patch.object(context.subprocess, 'run', return_value=result):
            with self.assertRaises(ValueError): context.execute(self.root, self.index, {'generation': 'a' * 64}, 'knowledge_status', {})

    def test_linked_input_is_rejected(self):
        target = self.root / 'file'; target.write_text('ok')
        link = self.root / 'link'
        try: link.symlink_to(target)
        except OSError: self.skipTest('This host cannot create symlinks')
        with self.assertRaises(ValueError): context.regular(link, 50)


class DeliveredFacts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(); self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        (self.root / 'docs').mkdir(); (self.root / 'AminScatter').mkdir()
        self.delivered = {'version': '0.87.5.1', 'scene_schema': 63, 'recipe_format': 9,
                          'edit_storage': 3, 'max_year': 2027, 'interactions': 12}
        self.proof = self.root / 'docs/proof.json'
        self.proof.write_text(json.dumps({'status': 'scoped_pass', **self.delivered}))
        (self.root / 'docs/KNOWLEDGE_BASELINE.json').write_text(json.dumps({
            'schema': 'cyrus.knowledge-baseline/1', 'delivery_receipt': 'docs/proof.json',
            'delivered': self.delivered, 'limits': ['Scope remains Library only']}))
        (self.root / 'AminScatter/CMakeLists.txt').write_text(
            'project(CyrusScatter VERSION 0.87.5.2 LANGUAGES CXX)\n')

    def test_working_label_never_replaces_delivered_qualification(self):
        result = context.facts(self.root)
        self.assertEqual(result['delivered'], self.delivered)
        self.assertEqual(result['working_tree_version'], '0.87.5.2')
        self.assertEqual(result['limits'], ['Scope remains Library only'])

    def test_mismatching_or_unqualified_receipt_is_rejected(self):
        for change in [{'scene_schema': 61}, {'max_year': True}, {'status': 'pending'}]:
            self.proof.write_text(json.dumps({'status': 'scoped_pass', **self.delivered, **change}))
            with self.assertRaises(ValueError): context.facts(self.root)


if __name__ == '__main__': unittest.main()
