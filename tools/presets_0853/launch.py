"""Start only an owned Max 2027 host with its matched preset build."""
from pathlib import Path
import argparse, hashlib, json, sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/procedural_lab/layer_editor_071'))
from private_host import launch

p = argparse.ArgumentParser()
p.add_argument('name')
p.add_argument('--native', required=True, type=Path)
p.add_argument('--scale', type=float, choices=(0., 1., 1.5), default=0.)
a = p.parse_args()
assert a.name.startswith('foundation-presets0853-')
native = a.native.resolve()
receipt = json.loads((native / 'receipt.json').read_text(encoding='utf-8'))
assert receipt['max_year'] == 2027 and all(s['exit_code'] == 0 for s in receipt['stages'])
for path, digest in receipt['sources'].items():
    assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, path
process, record = launch(ROOT / 'build/mcp-qualification' / a.name,
                         ROOT / 'AminScatter/scripts/AminScatterObject.ms', native,
                         extra=f'CustomControlsOptions.UIUserScaleFactor={a.scale}',
                         transport=True, max_year=2027, silent_startup=True,
                         script_assets=('CyrusGallery.dll',))
print(json.dumps({'pid': process.pid, 'profile': record['output']}, indent=2))
