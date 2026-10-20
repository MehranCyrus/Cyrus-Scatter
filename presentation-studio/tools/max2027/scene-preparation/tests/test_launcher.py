import importlib.util
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('prepare_scene', Path(__file__).resolve().parents[2] / 'prepare_scene.py')
tool = importlib.util.module_from_spec(spec); spec.loader.exec_module(tool)


class LauncherTests(unittest.TestCase):
    def test_native_request_is_deterministic_and_quotes_artist_labels(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary); source = root / 'source.max'; source.write_bytes(b'owned source')
            config = root / 'recipe.json'; config.write_text(json.dumps({'version': 1, 'materials': {'mode': 'scalar-approximation', 'rules': [{'sourceName': 'artist "quoted" \\ label', 'label': 'Explicit choice'}]}}), encoding='utf-8')
            plan = tool.make_plan(source, root / 'fresh', config)
            a = tool.native_request(plan, root / 'copy.max', root / 'staging', root / 'delivery')
            b = tool.native_request(plan, root / 'copy.max', root / 'staging', root / 'delivery')
            self.assertEqual(a, b); self.assertIn(tool.max_string('artist "quoted" \\ label'), a)
            self.assertTrue(a.index('fileIn') < a.index('CyrusPrepareNative #(')); self.assertFalse((root / 'fresh').exists())
    def test_only_the_recorded_process_image_profile_pid_and_creation_time_are_accepted(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary); image = root / '3dsmax.exe'; metadata = {'pid': 123, 'command': [str(image)], 'run': str(root / 'owned'), 'creationDate': 'same start'}
            actual = {'ProcessId': 123, 'ExecutablePath': str(image), 'CommandLine': str(root / 'owned' / 'max.ini'), 'CreationDate': 'same start'}
            for field, wrong in [('ProcessId', 456), ('ExecutablePath', str(root / 'other.exe')), ('CommandLine', str(root / 'artist.ini')), ('CreationDate', 'different start')]:
                changed = {**actual, field: wrong}
                with self.subTest(field=field), patch.object(tool.subprocess, 'run', return_value=SimpleNamespace(stdout=json.dumps(changed))), self.assertRaises(RuntimeError): tool.process_state(metadata)
            with patch.object(tool.subprocess, 'run', return_value=SimpleNamespace(stdout=json.dumps(actual))): self.assertEqual(tool.process_state(metadata), actual)
            with patch.object(tool.subprocess, 'run', return_value=SimpleNamespace(stdout='')): self.assertIsNone(tool.process_state(metadata))


if __name__ == '__main__': unittest.main()
