"""Regression checks for edit boundaries, reused IDs and nested wall timings."""
from pathlib import Path
import csv
import json
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/performance'))
import summarize_edit_trace as report

FIELDS = ['elapsed_ms', 'kind', 'span_id', 'parent_span_id', 'edit_id',
          'edit_label', 'actor', 'stage', 'duration_ms', 'detail']


def marker(kind, time, edit_id, label):
    return dict(zip(FIELDS, [time, kind, '0', '0', edit_id, label,
                             'artist', 'manual_marker', '', '']))


def span(span_id, start, duration, edit_id='0', label='unmarked',
         stage='preview_rebuild', parent='0', actor='layer:1:Grass', detail=''):
    common = [span_id, parent, edit_id, label, actor, stage]
    return [dict(zip(FIELDS, [start, 'start', *common, '', ''])),
            dict(zip(FIELDS, [start+duration, 'end', *common, duration, detail]))]


class EditTraceReportTests(unittest.TestCase):
    def setUp(self):
        parent = ROOT / 'build/edit-trace-report-tests'
        parent.mkdir(parents=True, exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(dir=parent)
        self.root = Path(self.temporary.name).resolve()
        assert self.root.is_relative_to(parent.resolve())

    def tearDown(self):
        self.temporary.cleanup()

    def fixture(self, rows, **summary):
        with (self.root / 'trace.csv').open('w', encoding='utf-8', newline='') as stream:
            writer = csv.DictWriter(stream, fieldnames=FIELDS)
            writer.writeheader()
            writer.writerows(sorted(rows, key=lambda r: r['elapsed_ms']))
        meta = dict(spans_started=sum(r['kind'] == 'start' for r in rows),
                    dropped_rows=0, collector_errors=0, stage_errors=0,
                    unclosed_spans=0, unfinished_edit=0)
        meta.update(summary)
        (self.root / 'trace-summary.json').write_text(json.dumps(meta), encoding='utf-8')
        return self.root

    def test_reused_ids_and_repeated_labels_remain_separate(self):
        rows = span('unmarked1', 0, 1) + span('unmarked2', 20, 3)
        for index, (begin, duration, label) in enumerate([
                (10, 4, 'corner_move'), (30, 8, 'corner_move'), (50, 2, 'undo_extension')]):
            rows += [marker('edit_begin', begin, '1', label)]
            rows += span(str(index+1), begin+1, duration, '1', label)
            rows += [marker('result_seen', begin+duration+2, '1', label)]
        data = report.summarize(self.fixture(rows))
        self.assertEqual([e['window_id'] for e in data['edits']], [1, 2, 3])
        self.assertEqual([e['edit_id'] for e in data['edits']], ['1']*3)
        self.assertEqual([e['preview_builds'] for e in data['edits']], [1]*3)
        self.assertEqual([e['traced_work_window_ms'] for e in data['edits']], [4, 8, 2])
        self.assertEqual(data['unmarked_stage_count'], 2)
        self.assertEqual(len(data['warnings']), 1)
        self.assertIn('reused edit IDs', data['warnings'][0])

    def test_nested_work_is_subtracted_once_and_gaps_are_retained(self):
        rows = [marker('edit_begin', 0, '1', 'extension')]
        rows += span('1', 1, 10, '1', 'extension', 'analyzer_run', actor='analyzer:A')
        rows += span('2', 2, 6, '1', 'extension', parent='1')
        rows += span('3', 3, 4, '1', 'extension', 'placements', parent='2', actor='layer:2:clover')
        rows += span('4', 15, 2, '1', 'extension')
        rows += [marker('result_seen', 20, '1', 'extension')]
        data = report.summarize(self.fixture(rows))
        self.assertFalse(data['warnings'])
        costs = {s['span_id']: s['child_excluded_ms'] for s in data['spans']}
        self.assertEqual(costs, {'1': 4, '2': 2, '3': 4, '4': 2})
        self.assertEqual(data['edits'][0]['covered_work_ms'], 12)
        self.assertEqual(data['edits'][0]['traced_work_window_ms'], 16)
        self.assertEqual(data['edits'][0]['manual_window_ms'], 20)

    def test_partial_trace_does_not_report_child_excluded_times(self):
        rows = [marker('edit_begin', 0, '1', 'unfinished')]
        rows += span('1', 1, 5, '1', 'unfinished')[:1]
        rows += span('2', 2, 2, '1', 'unfinished', 'placements', parent='1')
        data = report.summarize(self.fixture(rows, unclosed_spans=1, unfinished_edit=1))
        self.assertIsNone(data['spans'][0]['child_excluded_ms'])
        self.assertIsNone(data['edits'][0]['manual_window_ms'])
        self.assertTrue(any('missing end' in w for w in data['warnings']))
        self.assertTrue(any('lacks Result visible' in w for w in data['warnings']))
        # An orphan child end also makes subtraction unsafe, even if a stale
        # summary claims that the collector lost nothing.
        rows = span('1', 1, 5) + span('2', 2, 2, '0', 'unmarked', 'placements', parent='1')[1:]
        data = report.summarize(self.fixture(rows))
        self.assertIsNone(data['spans'][0]['child_excluded_ms'])
        self.assertTrue(any('End without start' in w for w in data['warnings']))

    def test_mismatched_result_is_not_paired_and_late_work_is_flagged(self):
        rows = [marker('edit_begin', 0, '1', 'first'), marker('result_seen', 5, '2', 'first'),
                marker('edit_begin', 10, '2', 'second'), marker('result_seen', 15, '2', 'second')]
        rows += span('1', 11, 6, '2', 'second')
        data = report.summarize(self.fixture(rows))
        self.assertIsNone(data['edits'][0]['manual_window_ms'])
        self.assertEqual(data['edits'][1]['manual_window_ms'], 5)
        self.assertEqual(data['edits'][1]['preview_builds'], 1)
        self.assertTrue(any('no matching active edit' in w for w in data['warnings']))
        self.assertTrue(any('ended after Result visible' in w for w in data['warnings']))

    def test_changed_span_label_is_rejected(self):
        rows = span('1', 1, 2)
        rows[1]['edit_label'] = 'wrong'
        with self.assertRaisesRegex(ValueError, 'Span identity changed'):
            report.summarize(self.fixture(rows))

    def test_stage_errors_and_html_are_preserved(self):
        label = '<script>bad</script>'
        rows = [marker('edit_begin', 0, '1', label), marker('result_seen', 5, '1', label)]
        rows += span('1', 1, 2, '1', label, detail='["Failed",0,0,1]')
        data = report.summarize(self.fixture(rows, stage_errors=1))
        self.assertEqual(data['spans'][0]['error'], 'Failed')
        self.assertTrue(any('stage_errors' in w for w in data['warnings']))
        destination = self.root / 'report.html'
        report.render(data, destination)
        self.assertNotIn(label, destination.read_text(encoding='utf-8'))
        self.assertIn('&lt;script&gt;', destination.read_text(encoding='utf-8'))
        self.assertEqual(json.loads(destination.with_suffix('.json').read_text())['edits'][0]['label'], label)


if __name__ == '__main__':
    unittest.main()
