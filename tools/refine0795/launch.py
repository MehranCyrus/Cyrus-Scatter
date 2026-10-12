"""Launch an owned landscape qualification host with immutable input identities."""
from pathlib import Path
import argparse, hashlib, json, shutil, subprocess, sys, time

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/procedural_lab/layer_editor_071'))
from private_host import launch

p = argparse.ArgumentParser()
p.add_argument('--candidate', type=Path, required=True)
p.add_argument('--name', required=True)
p.add_argument('--analyzer-candidate', type=Path)
a = p.parse_args()
candidate = a.candidate.resolve()
year = json.loads((candidate / 'build.json').read_text())['year']
if a.analyzer_candidate:
    previous=a.analyzer_candidate.resolve()
    if json.loads((previous/'build.json').read_text())['year']!=year:
        raise ValueError('Analyzer SDK year mismatch')
    frozen=previous/'source/CyrusSurfaceAnalyzer'
    for path in frozen.rglob('*'):
        if path.is_file() and path.suffix in ('.cpp','.h','.inc','.ms'):
            current=ROOT/'CyrusSurfaceAnalyzer'/path.relative_to(frozen)
            if path.read_bytes()!=current.read_bytes():raise RuntimeError('Analyzer source changed: '+str(current))
    shutil.copytree(frozen,candidate/'source/CyrusSurfaceAnalyzer')
    shutil.copy2(previous/'native/CyrusSurfaceAnalyzer.dlx',candidate/'native/CyrusSurfaceAnalyzer.dlx')
if not a.name.startswith('refine0795-') or Path(a.name).name != a.name:
    raise ValueError('Owned refine0795 profile name required')
for rel, digest in json.loads((candidate / 'source.json').read_text()).items():
    if rel.endswith(('.cpp', '.h', '.inc', '.cmake')) or rel.endswith('CMakeLists.txt'):
        path=ROOT/('CyrusLicensing/team/team_public_key.h' if rel=='team_public_key.h' else rel)
        if hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            raise RuntimeError('Compiled source changed: ' + rel)
folder = ROOT / 'build/mcp-qualification' / a.name
extra = 'fileIn @"' + (candidate / 'source/CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms').as_posix() + '"'
process, metadata = launch(folder, ROOT / 'AminScatter/scripts/AminScatterObject.ms', candidate / 'native',
    extra=extra, transport=True, max_year=year, silent_startup=True, extra_modules=('CyrusSurfaceAnalyzer.dlx',))
(folder / 'baseline-git-status.txt').write_text(subprocess.check_output(['git', 'status', '--short'], cwd=ROOT, text=True))
(folder / 'baseline-head.txt').write_text(subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True))
print(json.dumps(metadata), flush=True)
deadline = time.monotonic() + 240
while time.monotonic() < deadline:
    if (folder / 'startup-error.txt').exists():
        raise RuntimeError((folder / 'startup-error.txt').read_text(encoding='utf-8-sig'))
    if (folder / 'ready.json').exists():
        print('Owned landscape host ready', flush=True)
        break
    if process.poll() is not None:
        raise RuntimeError('Owned host exited before readiness')
    time.sleep(.5)
else:
    raise TimeoutError('Inspect owned host before further requests')
