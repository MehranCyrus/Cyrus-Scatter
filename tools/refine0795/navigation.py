"""Replay the preserved 26-controller navigation witness on a matched 0.79.5 host."""
from pathlib import Path
import argparse, hashlib, json, re, sys
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools/procedural_lab'))
from runtime_driver import run_script
p = argparse.ArgumentParser(); p.add_argument('profile', type=Path)
out = p.parse_args().profile.resolve()
if out.parent != ROOT/'build/mcp-qualification' or not out.name.startswith('refine0795-'):
    raise ValueError('Owned profile required')
source = ROOT/'tools/refine0792/navigation.py'
content = re.sub(r'ROOT\s*=\s*Path\(__file__\)\.resolve\(\)\.parents\[2\]',
    lambda _: 'ROOT=Path('+repr(ROOT.as_posix())+')', source.read_text())
content = content.replace('refine0791-layer0792-', 'refine0795-')
target = out/'adapted-navigation.py'; target.write_text(content)
result = run_script(out, 'python.ExecuteFile @"'+target.as_posix()+'"', timeout=600)
(out/'navigation-adapter.json').write_text(json.dumps(dict(source=str(source),
    source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
    adapter_sha256=hashlib.sha256(target.read_bytes()).hexdigest(), result=result), indent=2)+'\n')
if not result.startswith('SUCCESS '): raise RuntimeError(result)
d = json.loads((out/'navigation0792.json').read_text())
if d['errors'] or not d['assertions'] or not all(c['passed'] for c in d['assertions']):
    raise RuntimeError('Failed navigation witness; inspect navigation0792.json')
print(str(len(d['assertions']))+' navigation assertions passed')
