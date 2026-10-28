"""Reuse 0.87.4 editor checks with outputs confined to this owned host."""
from pathlib import Path
import json
from pymxs import runtime as r

root = Path(__file__).resolve().parents[3]
host = Path(str(r.GardenRun))
phase = str(r.CVProfileCase)
if phase not in ('fern', 'contacts-fern', 'grass', 'contacts-grass'):
    raise ValueError('Unsupported owned editor test phase')
r.execute('global PEFern,PEGrass,PEPhase')
r.PEFern = r.getNodeByName('Outdoor_Plants_01_Neottopteris_Nidus_Bush_Decorative05_001')
r.PEGrass = r.getNodeByName('Outdoor_Plants_01_Grass_Wild_QMH_001')
r.PEPhase = phase
original = root / 'tools/procedural_lab/interactions0874/checks.py'
source = original.read_text(encoding='utf-8')
old = "ROOT/'Test Scene/CyrusScatter_0874_OwnedTests'"
assert source.count(old) == 4
source = source.replace(old, "O/'editor-trials'").replace('_Preparation_0874.max', '_Preparation_08741.max')
scope = {'__file__': str(original), '__name__': '__main__'}
exec(compile(source, str(original), 'exec'), scope)
result = json.loads((host / (phase + '.json')).read_text(encoding='utf-8'))
if result.get('status') != 'pass':
    raise RuntimeError('Owned editor phase failed: ' + str(result.get('error', result)))
