from pathlib import Path
from datetime import datetime, timezone
import difflib
import hashlib
import json
import shutil
import zipfile

root = Path(__file__).resolve().parents[2]
work = Path(__file__).resolve().parent
archive = root / 'docs/Viewport_Performance_Round2_2026-10-01'
evidence = archive / 'evidence'
recipes = archive / 'recipes'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()

def copy(src, dst):
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dst)

def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')

for name in ('baseline-identity.json', 'desktop-ready.json', 'candidate-complete.json',
             'probe-stats.json', 'retained-geometry.json', 'gestures.csv',
             'gesture-counts.json', 'gesture-summary.json', 'image-comparison.json',
             'package-verification.json', 'session-final.json', 'restored-callbacks.txt',
             'cleanup-complete.txt', 'before-062.zip'):
    copy(work / name, evidence / name)
for name in ('candidate-matrix', 'matrix', 'profile', 'pilot', 'retained-pilot', 'images'):
    for source in sorted((work / name).glob('*')):
        if source.is_file() and source.suffix in ('.json', '.csv', '.png'):
            copy(source, evidence / name / source.name)
for source, name in (
    ('build/viewport-performance-test/result.txt', 'viewport-test.txt'),
    ('build/max2027-smoke-result.txt', 'max2027-smoke-test.txt'),
    ('build/compute-performance-test/result.txt', 'compute-test.txt')):
    copy(root / source, evidence / 'tests' / name)
for source in sorted(work.glob('*.ms')):
    if source.name != '03b-profile.ms':
        copy(source, recipes / source.name)
for name in ('build-probe.py', 'package-062.py', 'analyze-round2.py', 'archive-evidence.py', 'plugins.ini'):
    copy(work / name, recipes / name)
for source in sorted((work / 'probe').glob('*')):
    if source.is_file():
        copy(source, recipes / 'probe' / source.name)
sources = [
    'AminScatter/tools/ui/viewport-performance.cjs', 'AminScatter/scripts/AminScatterObject.ms',
    'tools/build_max.py', 'tools/test_viewport_performance.py', 'tools/tests/viewport_performance_smoke.ms',
    'tools/test_max2027.py', 'tools/test_compute_performance.py', 'tools/tests/compute_performance_smoke.ms',
    'tools/performance/CyrusViewportBenchmark.ms', 'tools/performance/CyrusPerformanceMonitor.ms',
    'tools/performance/summarize_viewport.py', 'cmake/CyrusMaxSDK.cmake',
    'CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms',
]
for source in sources:
    copy(root / source, recipes / 'source' / source)
with zipfile.ZipFile(work / 'before-062.zip') as z:
    patches = []
    for name in z.namelist():
        old = [line + '\n' for line in z.read(name).decode('utf-8-sig').splitlines()]
        new = [line + '\n' for line in (root / name).read_bytes().decode('utf-8-sig').splitlines()]
        patches.extend(difflib.unified_diff(old, new, fromfile='before-062/' + name, tofile='after-062/' + name))
    (evidence / 'change-from-061.diff').write_text(''.join(patches), encoding='utf-8', newline='\n')
identities = {}
for path in sources + ['build/max2027-release/AminScatter/AminScatter.dlx',
                       'build/max2027-release/AminScatter/CyrusScatterEdit.dlm',
                       'build/max2027-release/CyrusSurfaceAnalyzer/CyrusSurfaceAnalyzer.dlx',
                       'dist/CyrusScatter-0.61-Max2027.mzp', 'dist/CyrusScatter-0.62-Max2027.mzp',
                       'Test Scene/SaveSelect 2.max']:
    identities[path] = {'sha256': sha(root / path), 'bytes': (root / path).stat().st_size}
assert identities['Test Scene/SaveSelect 2.max']['sha256'] == '8a40f6a1a5c47eacbbee92920e131f4cae04cfb0de6be1991b4719ea2860bd2c'
assert identities['dist/CyrusScatter-0.61-Max2027.mzp']['sha256'] == '82167da439a60b2b9d08112cbd0732ae891252d76a6cc4ae38cc61cb9cd4e9de'
write(evidence / 'source-snapshot.json', identities)
profile = Path('C:/Users/Mehran/AppData/Local/Autodesk/3dsMax/2027 - 64bit/ENU/scripts/AminScatter/AminScatterObject.ms')
assert sha(profile) == '34062594ce2006833ba3f281eae8fabc4d2184c95955c9dfc092c7a597376391'
write(evidence / 'preservation.json', {
    'original_scene_unchanged': True, 'prior_061_package_unchanged': True,
    'installed_profile_script_unchanged': True,
    'installed_profile_script_sha256': sha(profile),
    'isolated_round2_process_id': 17140, 'original_process_id': 20244,
    'previous_061_process_id': 13548, 'normal_profile_installation_performed': False,
    'original_scene_save_performed': False,
})
for path in archive.rglob('*.json'):
    json.loads(path.read_text(encoding='utf-8-sig'))
files = [{'path': str(p.relative_to(archive)).replace('\\', '/'),
          'sha256': sha(p), 'bytes': p.stat().st_size}
         for p in sorted(archive.rglob('*')) if p.is_file() and p != evidence / 'index.json']
write(evidence / 'index.json', {
    'created_utc': datetime.now(timezone.utc).isoformat(),
    'scope': 'Round-two exploratory display experiments and accepted 0.62 held-input change; see main report for measurement limits.',
    'matrix_steps': 1260, 'candidate_comparison_steps': 720,
    'real_pan_strokes_per_version': 4,
    'excluded_from_accepted_trials': 'Stale initial desktop launch failure, initial compile/script setup failures; retained in ignored scratch work only. Invisible renderer trials remain archived but are explicitly rejected as performance evidence.',
    'files': files,
})
print(json.dumps({'archived_files': len(files), 'bytes': sum(f['bytes'] for f in files), 'json_parse': 'PASS',
                  'preservation_checks': 'PASS'}, indent=2))
