"""Read back a physical density drag in the owned current editor."""
import ctypes
import hashlib
import json
from pathlib import Path
import uuid
from pymxs import runtime as rt

folder = Path(str(rt.MCPFixtureDir))
assert folder.name.startswith('foundation-spline-')
leaf, root = rt.PhysicalLeaf, rt.PhysicalRoot
samples = list(rt.CyrusFallUnpack(leaf.strokeCurveSamples[0]))
checks = {
    'physical_drag_saved_on_release': len(samples) == 257 and .38 < samples[-1] < .41,
    'other_band_curves_unchanged': all(str(x) == '1,1' for x in list(leaf.strokeCurveSamples)[1:]),
    'manual_epoch_unchanged': root.procEpoch == rt.PhysicalEpoch,
    'manual_rows_unchanged': str(rt.cyrusEditFingerprint(root.groupSnapshotRows[0], 'physical')) == str(rt.PhysicalFingerprint),
}
report = {'checks': checks, 'passed': all(checks.values()), 'endpoints': [samples[0], samples[-1]],
          'script_sha256': hashlib.sha256((Path(__file__).resolve().parents[2] / 'AminScatter/scripts/AminScatterObject.ms').read_bytes()).hexdigest(),
          'window_dpi': ctypes.windll.user32.GetDpiForWindow(ctypes.c_void_p(int(rt.windows.getMAXHWND()))),
          'scope': 'Owned Max 2026 physical density drag after corrected full-domain initial zoom. No claims for other DPI, tablet, artist scenes or Max 2027 pointer input.'}
path = folder / ('physical-graph-' + uuid.uuid4().hex + '.json')
path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
assert report['passed'], report
