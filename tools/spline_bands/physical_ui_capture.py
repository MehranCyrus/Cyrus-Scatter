"""Read back the owned physical-input session; does not drive its controls."""
import ctypes
import hashlib
import json
from pathlib import Path
import uuid
from pymxs import runtime as rt

folder = Path(str(rt.MCPFixtureDir))
assert folder.name.startswith('foundation-spline-')
leaf, root = rt.PhysicalLeaf, rt.PhysicalRoot
samples = list(rt.CyrusFallUnpack(leaf.strokeCurveSamples[3]))
checks = {
    'outside_band_added_to_second_path': len(leaf.strokeIDs) == 4 and leaf.strokePathIDs[3] == leaf.strokePathIDs[2],
    'other_widths_unchanged': list(leaf.patternWidths)[:3] == [15., 25., 20.],
    'spinner_changes_new_band': float(leaf.patternWidths[3]) > 39.4,
    'curve_enabled_on_captured_band': bool(leaf.strokeCurveEnabled[3]),
    'physical_drag_saved': len(samples) == 257 and samples[-1] < .999,
    'manual_epoch_unchanged': root.procEpoch == rt.PhysicalEpoch,
    'manual_rows_unchanged': str(rt.cyrusEditFingerprint(root.groupSnapshotRows[0], 'physical')) == str(rt.PhysicalFingerprint),
}
report = {'checks': checks, 'passed': all(checks.values()),
          'samples_endpoints': [samples[0], samples[-1]],
          'script_sha256': hashlib.sha256((Path(__file__).resolve().parents[2] / 'AminScatter/scripts/AminScatterObject.ms').read_bytes()).hexdigest(),
          'scope': 'Physical pointer inputs in owned Max 2026: Path navigation, outside Band creation, width spinner, field/boundary toggles and density endpoint drag. Other DPI and tablet gestures are unqualified.',
          'initial_graph_issue': 'Zoom extents fits flat 100% curve to about 99.5–100.5%; correction follows separately.'}
report['window_dpi'] = ctypes.windll.user32.GetDpiForWindow(ctypes.c_void_p(int(rt.windows.getMAXHWND())))
path = folder / ('physical-ui-' + uuid.uuid4().hex + '.json')
path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
assert report['passed'], report
