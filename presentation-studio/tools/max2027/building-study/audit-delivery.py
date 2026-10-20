"""Check the current building delivery against its scoped acceptance evidence."""
import base64
import datetime
import hashlib
import json
from pathlib import Path
import re
import subprocess
import zipfile

APP = Path(__file__).resolve().parents[3]
ROOT = APP.parent
BASE = APP / 'exports/building-20261016'
OUT = BASE / 'final-presentation-v1'
QUAL = BASE / 'qualification'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def digest(path):
    result = hashlib.sha256()
    with path.open('rb') as source:
        for block in iter(lambda: source.read(4 * 1024 * 1024), b''):
            result.update(block)
    return result.hexdigest()


checks = []


def check(name, condition, evidence, scope):
    if not condition:
        raise AssertionError(name)
    checks.append(dict(requirement=name, passed=True, evidence=evidence, scope=scope))


source = ROOT / 'Test Scene/Big building.max'
profile = Path('C:/Users/Mehran/AppData/Local/Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini')
check('Original scene and normal Max profile preserved',
      digest(source) == '809e90a91a8616d7dd9e930f0e14e09a026ad0dd66cf27de6e429e6ce1cbe208'
      and digest(profile) == '38d5088e0bb8fdcd1579d1dec49ee16a4de4a761ab78534a221e5f89da638ca4',
      ['source-baseline.json', 'qualification/final-preservation-v1.json'],
      'Original file bytes and recorded normal Max INI; derivative processing only.')
inspection, baseline = read(BASE / 'inspection.json'), read(BASE / 'baseline-glb-stats.json')
check('Inspection, baseline and numerical targets retained',
      '2027' in str(inspection['maxVersion']) and baseline['bytes'] == (BASE / 'baseline-native.glb').stat().st_size
      and (BASE / 'material-inventory.json').is_file() and (BASE / 'targets.json').is_file(),
      ['inspection.json', 'material-inventory.json', 'baseline-glb-stats.json', 'targets.json'],
      'Baseline exceeds production admission; no baseline app FPS claim.')
run = BASE / 'reproduction-v4/delivery'
report = read(run / 'report.json')
post = report['post']
check('Current reusable pipeline and published files match qualification',
      read(BASE / 'reproduction-v4/run.json')['phase'] == 'complete'
      and all(digest(Path(path)) == sha for path, sha in report['toolHashes'].items())
      and all(digest(run / path) == entry['sha256'] for path, entry in report['files'].items()),
      ['reproduction-v4/run.json', 'reproduction-v4/delivery/report.json'],
      'Exact current preparation modules and all published files; private Max 2027 static workflow.')
model = OUT / 'BAILEY.optimized.glb'
check('Repeatable self-contained optimized GLB meets selected size/geometry budgets',
      digest(model) == post['outputSha256'] == read(BASE / 'reproduction-v3/delivery/post-report.json')['outputSha256']
      and model.stat().st_size <= 50 * 1024 ** 2 and post['submittedTriangles'] <= 3_000_000
      and post['exactMeshoptRoundtrip'] and post['renderedPlacements'] == 295 and len(post['layers']) == 16,
      ['reproduction-v3/delivery/post-report.json', 'reproduction-v4/delivery/post-report.json', 'final-presentation-v1/BAILEY.optimized.glb'],
      'Two independent complete reproductions; exact codec identity allows winding-preserving corner rotation.')
visual = read(BASE / 'final-silhouette-v1/metrics.json')
geometry = read(OUT / 'geometry-material-successor.json')
check('Architectural visual quality and material successor verified',
      len(visual['rows']) == 5 and all(row['intersectionOverUnion'] >= .995 for row in visual['rows'])
      and geometry['exactAttributesAndOrientedTriangles'] and not geometry['materialDifferences']
      and geometry['maximumWorldPositionBoundMetres'] <= .0001,
      ['final-silhouette-v1/metrics.json', 'final-browser-v2/render-comparison.json', 'final-presentation-v1/geometry-material-successor.json'],
      'Five actual rendered silhouette views and inspected material/camera views; not hidden-detail or Hausdorff certification.')
check('Generated texture provenance and source material diagnostics retained',
      all((BASE / 'textures' / path).is_file() for path in ['brick-provenance.json', 'timber-provenance.json', 'fiber-cement-provenance.json'])
      and (run / 'material-audit.jsonl').is_file() and (run / 'source-dependencies.jsonl').is_file(),
      ['textures/', 'reproduction-v4/delivery/material-audit.jsonl', 'material-uv-probe-01.jsonl'],
      'Labelled artistic PBR approximation; source missing maps/proxies are not claimed recovered.')
camera = read(OUT / 'building-camera-parity.json')
native = read(OUT / 'native-reopen-check.json')
check('Prepared Max, matching camera coordinates and original timing verified',
      camera['passed'] and camera['samples'] == 4321 and camera['independentNativeSamples'] == 8641
      and camera['duration'] == 36 and camera['presentationOffsetSeconds'] == 2 and camera['maxTimeSeconds'] == 0
      and camera['maxPositionMetres'] <= .00002 and camera['reverseAndRandomSeeks'] == 1012
      and digest(OUT / 'building-hero.camera.json') == camera['cameraSha256']
      and native['passed'] and native['positionKeys'] == native['targetKeys'] == 1081
      and all(Path(path).is_file() for path in native['reachableBitmaps']),
      ['final-presentation-v1/building-camera-parity.json', 'final-presentation-v1/native-reopen-check.json'],
      'Independent native poses include orientation/roll/lens; saved Max reopens with all reachable prepared bitmaps.')
check('Generic preparation fixture preserves source state and export materials',
      read(BASE / 'preparation-end-to-end-v6/run.json')['phase'] == 'complete'
      and (BASE / 'preparation-roundtrip-v5/complete.txt').read_text() == 'PASS'
      and (BASE / 'preparation-roundtrip-v5/host-checks.txt').read_text().count('PASS') == 9,
      ['preparation-end-to-end-v6/delivery/report.json', 'preparation-roundtrip-v5/host-checks.txt', 'qualification/final-browser-regression-v2.json'],
      'Owned native fixture plus browser colour/UV/layer/portable checks; original nonconsecutive IDs survive Max reopen.')
studio, saved = read(OUT / 'studio-workflow.json'), read(OUT / 'downloads-v2.json')
check('Final building studio workflow and editable archive verified',
      studio['localGLBImportMs'] <= 15000 and studio['captureSaveUndo'] and studio['layerUndo'] and studio['seekReuse']
      and studio['authoredProjectPreserved'] and not studio['errors']
      and saved['autosaveReopen'] and saved['exactPortableReopen'] and not saved['errors']
      and read(OUT / 'replacement-undo-redo.json')['exactAuthoredContentRestored'],
      ['final-presentation-v1/studio-workflow.json', 'final-presentation-v1/downloads-v2.json', 'final-presentation-v1/replacement-undo-redo.json'],
      'Actual heavy-model mouse/keyboard/orbit/plan/capture/save/undo/layers; real menu downloads, autosave and preview.')
archive = OUT / 'BAILEY-presentation-v2.zip'
verification, performance = read(Path(str(archive) + '.verification.json')), read(OUT / 'standalone-v2/report.json')
with zipfile.ZipFile(archive) as public:
    assert public.testzip() is None
    for name, encoded in read(APP / 'public/player-shell.json'):
        if name != 'index.html':
            assert public.read(name) == base64.b64decode(encoded), f'Built player mismatch: {name}'
check('Independent current website and sustained performance verified',
      digest(archive) == verification['sha256'] == performance['archiveSha256']
      and performance['elapsedSeconds'] >= 180 and performance['rafObservedRenderIntervalMs']['p95'] <= 33.4
      and performance['initial']['uploads'] == performance['final']['uploads']
      and performance['initial']['rebuilds'] == performance['final']['rebuilds']
      and performance['resourcesStart'] == performance['resourcesEnd']
      and not performance['errors'] and not performance['external'] and not performance['failures'],
      ['final-presentation-v1/BAILEY-presentation-v2.zip.verification.json', 'final-presentation-v1/standalone-v2/report.json'],
      'Exact current built player, nested HTTP, controls/portrait/reduced motion and 180 s forward/reverse; recorded RTX desktop only.')
regression = read(QUAL / 'final-browser-regression-v2.json')['stats']
check('Relevant full software regression passes',
      regression['expected'] == 50 and not any(regression[key] for key in ['unexpected', 'skipped', 'flaky']),
      ['qualification/final-browser-regression-v2.json', 'qualification/final-source-qualification-v2.json'],
      '50 browser tests; companion receipt records observed 34 unit/15 integration and unchanged 10 Python/5 Node tool checks.')
guide = ROOT / 'docs/plans/landscape-presentation/BUILDING_DELIVERY.md'
missing = []
for label, target in re.findall(r'\[([^\]]*)\]\(([^)]+)\)', guide.read_text(encoding='utf-8')):
    if target.startswith(('http:', 'https:', '#')):
        continue
    path = Path(target) if re.match(r'^[A-Za-z]:/', target) else guide.parent / target
    if not path.exists() and path.resolve() != (QUAL / 'completion-audit-v2.json').resolve():
        missing.append(target)
check('Usable delivery documentation and artifact paths', not missing,
      ['docs/plans/landscape-presentation/BUILDING_DELIVERY.md', 'final-presentation-v1/artifact-manifest-v2.json'],
      'Instructions, measurements, images, recipes, hashes and limitations; ignored artifacts require separate backup.')
git = lambda *args: subprocess.check_output(['git', *args], cwd=ROOT, encoding='utf-8').strip()
check('Existing website and concurrent repository work preserved', not git('diff', '--name-only', 'HEAD', '--', 'website'),
      ['qualification/final-preservation-v1.json', 'git status --short'],
      'Website changed through independent Scatter commits since enrollment; no tracked website diff now. Native work is outside this delivery.')
result = dict(date=datetime.datetime.now(datetime.timezone.utc).isoformat(), passed=True, head=git('rev-parse', 'HEAD'), checks=checks,
              limits=['This audit ties current files to actual recorded native/browser experiments; it is not a substitute for their scenario coverage.',
                      'Missing original dependencies, artistic renderer approximation and hardware qualification limits remain explicit.'])
target = QUAL / 'completion-audit-v2.json'
target.write_text(json.dumps(result, indent=2), encoding='utf-8')
print(json.dumps(dict(passed=True, requirements=len(checks), receipt=str(target)), indent=2))
