"""Mechanical refresh in disposable roots; no production policy or switch."""
import copy
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import unittest
from unittest import mock

TOOL = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(TOOL), str(TOOL / 'candidate_tests'), str(TOOL / 'refresh_tests'), str(TOOL / 'tests'), str(TOOL / 'adapter_tests')]
import automatic_refresh as auto
import candidate_support as s
import refresh_evidence as evidence
import evaluation
import test_candidate


class RelocationTests(unittest.TestCase):
    def setUp(self):
        self.raw = b'# Guide\n\nforRanges uses copied data.\n'
        self.source = {'path': 'guide.md', 'sha256': evidence.sha(self.raw), 'ranges': [[1, 3]],
                       'knowledge_status': 'current', 'role': 'maintained_guide', 'canonical': {'preferred_path': 'guide.md'}}
        self.corpus = {'schema': 'cyrus.corpus/1', 'sources': [self.source]}
        self.location = {'path': 'guide.md', 'sha256': self.source['sha256'], 'start_line': 3, 'end_line': 3}
        self.labels = {'questions': [{'query': 'worker contract', 'required_qualifiers': ['copied'],
                                     'alternatives': [self.location], 'answerable': True}]}
    def revise(self, raw):
        return evidence.successor(self.corpus, self.labels, {'guide.md': self.raw}, {'guide.md': raw})
    def test_full_parent_addition_relocates_exact_gold_without_mutating_inputs(self):
        before = copy.deepcopy((self.corpus, self.labels))
        corpus, labels, changed = self.revise(b'New introduction.\n' + self.raw)
        self.assertEqual(corpus['sources'][0]['ranges'], [[1, 4]])
        self.assertEqual(labels['questions'][0]['alternatives'][0]['start_line'], 4)
        self.assertEqual(changed, ['guide.md'])
        self.assertEqual(before, (self.corpus, self.labels))
        self.assertEqual(labels['questions'][0]['required_qualifiers'], ['copied'])
        self.assertIn('does not certify', corpus['sources'][0]['review_status'])
        self.assertIn('not human-reviewed', corpus['sources'][0]['applicability']['automatic_refresh'])
    def test_changed_or_duplicate_gold_requires_review(self):
        for raw in (self.raw.replace(b'copied', b'live'), self.raw + b'forRanges uses copied data.\n'):
            with self.subTest(raw=raw), self.assertRaises(evidence.ReviewRequired):
                self.revise(raw)
    def test_partial_range_remains_exact(self):
        self.source['ranges'] = [[3, 3]]
        corpus, _, _ = self.revise(b'Intro.\n' + self.raw + b'Unenrolled tail.\n')
        self.assertEqual(corpus['sources'][0]['ranges'], [[4, 4]])
        with self.assertRaises(evidence.ReviewRequired):
            self.revise(self.raw.replace(b'copied', b'live'))
    def test_contract_relocation_is_exact_and_changed_limits_require_review(self):
        self.source['contract_sections']=[[1,3]]
        corpus,_,_=self.revise(b'Introduction.\n'+self.raw)
        self.assertEqual(corpus['sources'][0]['contract_sections'],[[2,4]])
        with self.assertRaises(evidence.ReviewRequired):
            self.revise(self.raw.replace(b'copied',b'live'))
    def test_historical_unknown_and_delivered_evidence_are_immutable(self):
        for status, role in [('historical', 'maintained_guide'), ('unknown', 'implementation'), ('current', 'delivered_artifact')]:
            self.source.update(knowledge_status=status, role=role)
            with self.assertRaises(evidence.ReviewRequired):
                self.revise(self.raw + b'New text.\n')
    def test_parent_scope_and_baseline_hash_cannot_change(self):
        with self.assertRaises(evidence.ReviewRequired):
            evidence.successor(self.corpus, self.labels, {}, {})
        self.source['sha256'] = '0' * 64
        with self.assertRaises(evidence.ReviewRequired):
            self.revise(self.raw)
    def test_unanswerable_definition_preserved(self):
        self.labels['negative'] = {'query': 'unsupported host behavior', 'answerable': False, 'required_evidence': []}
        _, labels, _ = self.revise(self.raw + b'Unrelated note.\n')
        self.assertEqual(labels['negative'], self.labels['negative'])


class AutomaticTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fixture = test_candidate.CandidateTests('test_complete_unchanged_rehearsal_and_preservation')
        cls.fixture.setUp()
        f = cls.fixture
        cls.root = f.root
        for name in auto.HELPERS:
            f.write('tools/rag/' + name, (TOOL / name).read_bytes())
        # This baseline already distinguishes the current guide from its old
        # copy, so an ordinary new fact does not itself split a duplicate group.
        body = (cls.root / f.current).read_bytes() + b'\nExisting current-specific note.\n'
        f.write(f.current, body)
        code, f.audit = f.scan('automatic-baseline-audit', cls.root / 'tools/rag/config.toml')
        assert code == 0
        f.definition['sources'][0].update(sha256=s.sha(body), ranges=[[1, len(body.decode().splitlines())]])
        f.corpus.write_bytes(s.encoded(f.definition))
        f.index = f.build('automatic-baseline')
        f.labels['queries'][0]['required_evidence'][0]['alternatives'][0]['sha256'] = s.sha(body)
        f.dataset.write_bytes(s.encoded(f.labels))
        f.historical = []
        for profile in ('plain', 'terminology'):
            out = cls.root / '_local/rag/evaluations' / ('automatic-baseline-' + profile)
            evaluation.run_evaluation(f.index, f.dataset, out, profile)
            f.historical.append(out / 'run.json')
        sdk = TOOL.parents[1] / '_local/rag/mcp-venv/Scripts/python.exe'
        cls.config = ("# preserve unrelated bytes\nother = 'fixture'\n[mcp_servers.cyrus_knowledge]\n"
            "command = '" + str(sdk) + "'\nargs = ['-B', '" + str(cls.root / 'tools/rag/adapter.py')
            + "', '--root', '" + str(cls.root) + "', '--index', '" + str(f.index) + "', '--follow-project']\n"
            "cwd = '" + str(cls.root) + "'\nenabled_tools = ['knowledge_search', 'knowledge_status']\n").encode()
        f.registration.write_bytes(cls.config)
        with mock.patch.object(s, 'TOOL', cls.root / 'tools/rag'):
            cls.proposal = auto.prepare(cls.root, f.index, f.historical, cls.root / '_local/rag/refresh/fixture-policy',
                                        'Explicit disposable fixture authorization; no production consent')
        cls.original = (cls.root / f.current).read_bytes()
    @classmethod
    def tearDownClass(cls):
        cls.fixture.tearDown()
    def setUp(self):
        self.fixture.registration.write_bytes(self.config)
        (self.root / self.fixture.current).write_bytes(self.original)
    def tearDown(self):
        self.fixture.registration.write_bytes(self.config)
        (self.root / self.fixture.current).write_bytes(self.original)
    def tick(self, sha=None):
        with mock.patch.object(s, 'TOOL', self.root / 'tools/rag'):
            return auto.tick(self.root, Path(self.proposal['path']), sha or self.proposal['sha256'])
    def test_unchanged_source_is_read_only(self):
        before = self.fixture.protected()
        value = self.tick()
        self.assertEqual(value['state'], 'unchanged', value)
        self.assertEqual(before, self.fixture.protected())
    def test_wrong_authorization_sha_rejected(self):
        value = self.tick('0' * 64)
        self.assertEqual(value['issue'], 'evidence_changed', value)
        self.assertEqual(self.fixture.registration.read_bytes(), self.config)
    def test_changed_labeled_evidence_holds_without_candidate_or_activation(self):
        path = self.root / self.fixture.current
        path.write_bytes(self.original.replace(b'forRanges', b'newWorkerName'))
        value = self.tick()
        self.assertEqual(value['state'], 'review_required', value)
        self.assertNotIn('output', value)
        self.assertFalse(value['activation_attempted'])
        self.assertEqual(self.fixture.registration.read_bytes(), self.config)
    def test_runtime_change_holds_before_pipeline_execution(self):
        path = self.root / 'tools/rag/retrieval.py'
        saved = path.read_bytes()
        try:
            path.write_bytes(saved + b'\n# changed\n')
            value = self.tick()
            self.assertEqual(value['issue'], 'changed_input', value)
            self.assertNotIn('output', value)
        finally:
            path.write_bytes(saved)
    def test_actual_paired_refresh_and_stdio_then_following_tick(self):
        path = self.root / self.fixture.current
        path.write_bytes(self.original + b'\nNew fixture capability: bounded resource observations.\n')
        value = self.tick()
        self.assertEqual(value['state'], 'activated', {k: v for k, v in value.items() if k != 'stages'})
        self.assertEqual(value['exit_code'], 0)
        expected = self.config.replace(str(self.fixture.index).encode(), value['selected_index'].encode())
        self.assertEqual(self.fixture.registration.read_bytes(), expected)
        self.assertTrue((Path(value['output']) / 'transport/knowledge_search-response.json').is_file())
        repeated = self.tick()
        self.assertEqual(repeated['state'], 'unchanged', repeated)
        self.assertEqual(repeated['generation'], value['selected_generation'])

    def test_precision_regression_preserves_prior_registration(self):
        path = self.root / self.fixture.current
        path.write_bytes(self.original + b'\nAdditional forRanges detail. ' * 500)
        value = self.tick()
        self.assertEqual(value['issue'], 'retrieval_regression', {k: v for k, v in value.items() if k != 'stages'})
        self.assertFalse(value['activation_attempted'])
        self.assertEqual(self.fixture.registration.read_bytes(), self.config)

    def test_watcher_does_not_repeat_an_identical_failed_attempt(self):
        elapsed = [0.0]
        def sleep(seconds):
            elapsed[0] += seconds
        result = {'schema': auto.SCHEMA, 'state': 'review_required', 'exit_code': 2, 'issue': 'retrieval_regression'}
        with mock.patch.object(s, 'TOOL', self.root / 'tools/rag'), \
                mock.patch.object(auto.time, 'monotonic', side_effect=lambda: elapsed[0]), \
                mock.patch.object(auto.time, 'sleep', side_effect=sleep), \
                mock.patch.object(auto, 'watch_signature', return_value='same-actual-inputs'), \
                mock.patch.object(auto, 'tick', return_value=result) as operation:
            value = auto.watch(self.root, Path(self.proposal['path']), self.proposal['sha256'], 30, 90)
        self.assertEqual(operation.call_count, 1)
        self.assertFalse(value['watcher_running'])
        self.assertEqual(value['issue'], 'retrieval_regression')

    def test_watcher_retains_failed_signature_across_sessions_unless_retry_requested(self):
        elapsed = [0.0]
        def sleep(seconds): elapsed[0] += seconds
        policy_path = Path(self.proposal['path'])
        status = {'schema': auto.SCHEMA, 'state': 'review_required', 'exit_code': 2,
                  'policy_sha256': self.proposal['sha256'], 'input_signature': 'same'}
        (policy_path.parent / 'watch-status.json').write_bytes(s.encoded(status))
        with mock.patch.object(s, 'TOOL', self.root / 'tools/rag'), \
                mock.patch.object(auto.time, 'monotonic', side_effect=lambda: elapsed[0]), \
                mock.patch.object(auto.time, 'sleep', side_effect=sleep), \
                mock.patch.object(auto, 'watch_signature', return_value='same'), \
                mock.patch.object(auto, 'tick', return_value=status) as operation:
            auto.watch(self.root, policy_path, self.proposal['sha256'], 30, 30)
            self.assertEqual(operation.call_count, 0)
            elapsed[0] = 0
            auto.watch(self.root, policy_path, self.proposal['sha256'], 30, 30, retry=True)
            self.assertEqual(operation.call_count, 1)

    def test_stdio_connection_owns_refresh_and_adopts_its_successor(self):
        # This test needs the pinned SDK interpreter, like the adapter suite.
        from test_transport import RawClient
        args_tail = ", '--refresh-policy', '" + self.proposal['path'] + "', '--refresh-policy-sha256', '" + self.proposal['sha256'] + "'"
        configured = self.config.replace(b"'--follow-project']", ("'--follow-project'" + args_tail + ']').encode())
        self.fixture.registration.write_bytes(configured)
        from adapter import refresh_authorization
        refresh_authorization(self.root, Path(self.proposal['path']), self.proposal['sha256'])
        path = self.root / self.fixture.current
        path.write_bytes(self.original + b'\nNew watched fixture capability: bounded observations.\n')
        client = RawClient(self.root, self.fixture.index, follow_project=True, refresh=self.proposal)
        self.addCleanup(client.close)
        print('Owned lifecycle fixture: ' + str(self.root), flush=True)
        deadline = time.monotonic() + 150
        while time.monotonic() < deadline and self.fixture.registration.read_bytes() == configured:
            time.sleep(.25)
        status_file = Path(self.proposal['path']).parent / 'watch-status.json'
        stages = []
        for file in sorted((self.root / '_local/rag/candidates').glob('refresh-*/stages/*.result.json')):
            data = json.loads(file.read_bytes())
            stages.append({'file': str(file), **{k: data[k] for k in ('state', 'issue', 'reason', 'duration_seconds') if k in data}})
        actual = client.call('knowledge_status')['result']['structuredContent']
        diagnostic = {'stderr': client.stderr, 'status': status_file.read_text() if status_file.exists() else 'no watcher receipt',
                      'actual_status': {k: actual.get(k) for k in ('ok', 'refresh', 'index_generation')}, 'stages': stages}
        if self.fixture.registration.read_bytes() == configured:
            diagnostic['thread_snapshots'] = {p.name: p.read_text(errors='replace')
                for p in status_file.parent.glob('watch-stack-*.log')}
        self.assertNotEqual(self.fixture.registration.read_bytes(), configured, diagnostic)
        response = client.call('knowledge_status', {'verify_sources': True})['result']['structuredContent']
        self.assertTrue(response['ok'], response)
        # Atomic registration replacement precedes the coordinator's final chain
        # and completion receipts. Wait for those witnesses, not just the token.
        state_path = Path(self.proposal['path']).parent / 'selected.json'
        state = completion = None
        while time.monotonic() < deadline:
            if state_path.exists():
                state = json.loads(state_path.read_bytes())
                receipt = Path(state['transaction']) / 'refresh-receipt.json'
                if state['baseline']['generation'] == response['index_generation'] and receipt.exists():
                    completion = json.loads(receipt.read_bytes())
                    break
            time.sleep(.1)
        self.assertIsNotNone(completion, diagnostic)
        self.assertEqual(completion['state'], 'activated', completion.get('issue'))
        self.assertEqual(response['index_generation'], state['baseline']['generation'])
        self.assertTrue(response['all_sources_verified'])
        self.assertTrue(response['refresh']['configured'])
        witness = client.call(arguments={'query': 'forRanges', 'mode': 'identifier', 'top_k': 1})['result']['structuredContent']
        self.assertTrue(witness['ok'], witness)
        self.assertEqual(witness['index_generation'], response['index_generation'])
        child = int(next(line.split('pid=')[1] for line in client.stderr if line.startswith('knowledge refresh start pid=')))
        if os.name == 'nt':
            import ctypes
            from ctypes import wintypes
            kernel = ctypes.WinDLL('kernel32', use_last_error=True)
            kernel.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
            kernel.OpenProcess.restype = wintypes.HANDLE
            kernel.WaitForSingleObject.argtypes = [wintypes.HANDLE, wintypes.DWORD]
            kernel.CloseHandle.argtypes = [wintypes.HANDLE]
            handle = kernel.OpenProcess(0x100000, False, child)
            self.assertTrue(handle)
            try:
                client.close()
                self.assertEqual(kernel.WaitForSingleObject(handle, 3000), 0)
            finally:
                kernel.CloseHandle(handle)
        else:
            client.close()
            with self.assertRaises(ProcessLookupError): os.kill(child, 0)
        self.assertEqual(client.process.returncode, 0, client.stderr)

    def test_watch_lease_allows_only_one_live_owner_and_can_be_reused(self):
        with auto.watch_lease(self.root):
            with self.assertRaises(s.Blocked) as caught:
                with auto.watch_lease(self.root):
                    self.fail('second watcher acquired live lease')
            self.assertEqual(caught.exception.issue, 'watcher_busy')
        with auto.watch_lease(self.root):
            pass

    def test_owned_busy_watcher_exits_cleanly_with_control_pipe_open(self):
        # A second Codex connection keeps its control pipe open while the worker
        # reports lease contention. Interpreter shutdown must not race a blocked
        # daemon reader of Python's buffered stdin.
        command = [sys.executable, '-B', str(self.root / 'tools/rag/automatic_refresh.py'),
                   'watch', '--root', str(self.root), '--policy', self.proposal['path'],
                   '--policy-sha256', self.proposal['sha256'], '--owned-gate']
        with auto.watch_lease(self.root):
            worker = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                      stderr=subprocess.PIPE)
            try:
                worker.stdin.write(b'go\n'); worker.stdin.flush()
                worker.wait(timeout=15)
                output = json.loads(worker.stdout.read())
                self.assertEqual(output['issue'], 'watcher_busy', output)
                self.assertEqual(worker.returncode, 2, worker.stderr.read().decode(errors='replace'))
            finally:
                if worker.poll() is None: worker.kill(); worker.wait()
                worker.stdin.close(); worker.stdout.close(); worker.stderr.close()


if __name__ == '__main__':
    unittest.main()
