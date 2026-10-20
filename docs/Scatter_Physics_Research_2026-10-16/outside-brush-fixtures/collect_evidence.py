"""Test-only receipt collector; never edits Physics Lab or artist files."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import subprocess

ROOT = next(p for p in Path(__file__).resolve().parents
            if (p / 'CyrusPhysicsLab').is_dir() and (p / 'cmake').is_dir())
DEST = ROOT / 'docs/Scatter_Physics_Research_2026-10-16'
BEFORE = ROOT / 'build/physics-lab-012-outside-fixtures/before.json'

def sha(path):
    path = Path(path)
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None

def ref(path):
    path = Path(path)
    return {'path': path.relative_to(ROOT).as_posix(), 'sha256': sha(path)}

def read(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))

def run_name(number):
    return ROOT / f'build/physics-lab-012-outside-{number:02}'

def state(number, name):
    return read(run_name(number) / f'{name}-state.json')

def stats(number, name):
    return read(run_name(number) / f'{name}-stats.json')

def snapshot(number, name):
    folder = run_name(number)
    value = state(number, name)
    return {'state': ref(folder / f'{name}-state.json'),
            'stats': stats(number, name),
            'ui': (folder / f'{name}-ui.txt').read_text(encoding='utf-8-sig'),
            'rows': len(value['rows']), 'births': len(value['births']),
            'revision': value['revision'], 'gesture': value['gesture'],
            'nextId': value['nextId']}

def path_rows(number):
    lines = (run_name(number) / 'paths.tsv').read_text(encoding='utf-8-sig').splitlines()
    return [dict(zip(lines[0].split('\t'), line.split('\t'))) for line in lines[1:]]

before = read(BEFORE)
changed = [p for p, original in before.items() if sha(p) != original]
assert not changed, changed
receipt_path = ROOT / 'build/physics-lab-012-delivery-20261016-01/receipt.json'
receipt = read(receipt_path)
source_mismatches = [p for p, original in receipt['source_hashes'].items()
                     if sha(ROOT / 'CyrusPhysicsLab' / p) != original]
assert not source_mismatches, source_mismatches

runs = []
total = 0
for number in (1, 3, 4):
    folder = run_name(number)
    assert (folder / 'completed.json').exists()
    assert not (folder / 'error.txt').exists()
    assertions = (folder / 'assertions.txt').read_text()
    total += int(re.search(r'PASS (\d+)', assertions).group(1))
    launch = read(folder / 'launch.json')
    for name, expected in launch['binaries'].items():
        assert sha(folder / 'bin' / name) == expected
        assert sha(ROOT / 'build/physics-lab-012-delivery-20261016-01' / name) == expected
    assert launch['script_sha256'] == receipt['source_hashes']['scripts/CyrusPhysicsLab.ms']
    runs.append({'run': folder.relative_to(ROOT).as_posix(), 'launch': launch,
                 'launch_receipt': ref(folder / 'launch.json'),
                 'loaded': ref(folder / 'loaded.tsv'),
                 'completion': ref(folder / 'completed.json'),
                 'assertions': assertions.strip(), 'paths': path_rows(number),
                 'raw_files': [ref(p) for p in sorted(folder.glob('*')) if p.is_file()
                               and (p.name.endswith(('-state.json', '-stats.json', '-ui.txt'))
                                    or p.name in ('paths.tsv', 'fixture.ms', 'start.ms', 'assertions.txt', 'listener.log'))]})

cases = []
for name in ('all-outside', 'leave-reenter', 'release-outside', 'start-outside',
             'outside-overlap', 'edge-footprint', 'cancel-outside'):
    a, b = state(1, name+'-before'), state(1, name+'-after')
    assert b['rows'][:len(a['rows'])] == a['rows']
    cases.append({'name': name, 'before': snapshot(1, name+'-before'),
                  'after': snapshot(1, name+'-after'),
                  'previous_saved_poses_unchanged': True,
                  'changed_saved_state_fields': [key for key in a if a[key] != b[key]],
                  'new_births': b['births'][len(a['births']):]})

gap_before, gap_miss = stats(1, 'leave-reenter-inside1'), stats(1, 'leave-reenter-gap')
assert gap_before['preview'] == gap_miss['preview'] == 2
new_births = cases[1]['new_births']
assert len(new_births) == 4
# In metres relative to origin [0,0,0]: two disjoint on-surface segments.
assert all((abs(b['p'][1]) <= .03 and -1.55 <= b['p'][0] <= -1.05)
           or (abs(b['p'][1]-1) <= .03 and 1.05 <= b['p'][0] <= 1.55)
           for b in new_births)
assert state(1, 'leave-reenter-before') == state(1, 'leave-reenter-undo')

edge_before, edge_after = state(3, 'edge-sweep-before'), state(3, 'edge-sweep-after')
assert edge_before == edge_after
assert stats(3, 'edge-sweep-safe')['preview'] == 3
assert stats(3, 'edge-sweep-after')['preview'] == 0
assert 'Brush footprint leaves the receiver' in stats(3, 'edge-sweep-after')['error']
cases.append({'name':'extended-edge-sweep',
              'before':snapshot(3, 'edge-sweep-before'),
              'safe_pending':snapshot(3, 'edge-sweep-safe'),
              'after':snapshot(3, 'edge-sweep-after'),
              'recovered':snapshot(3, 'edge-sweep-recovered'),
              'exact_saved_state_unchanged_on_failure':True,
              'finding':'Off-receiver generated footprint cancels the entire pending stroke; earlier valid pending bodies are lost.'})

for name in ('hold-outside','hold-limit','empty-undo'):
    a, b = state(4, name+'-before'), state(4, name+'-after')
    assert b['rows'][:len(a['rows'])] == a['rows']
    case = {'name':name, 'before':snapshot(4, name+'-before'),
            'after':snapshot(4, name+'-after'), 'previous_saved_poses_unchanged':True}
    if name == 'hold-outside':
        case['held_after_240_steps'] = snapshot(4, 'hold-outside-240steps')
        assert case['held_after_240_steps']['stats']['motion']['steps'] == 240
        assert case['held_after_240_steps']['stats']['preview'] == 3
    if name == 'hold-limit':
        assert a == b
        case['recovered'] = snapshot(4, 'hold-limit-recovered')
        case['step_budget'] = a['input']['settings']['max_steps'] if 'max_steps' in a['input']['settings'] else 3600
        case['finding'] = 'At the existing 3600-step stroke budget, an unreleased off-surface stroke cancels instead of offering Keep preview.'
    if name == 'empty-undo':
        case['undo1'] = snapshot(4, 'empty-undo-undo1')
        case['undo2'] = snapshot(4, 'empty-undo-undo2')
        assert state(4, 'empty-undo-undo1') == a
        assert not state(4, 'empty-undo-undo2')['rows']
        case['finding'] = 'Zero-birth gesture commits a revision/gesture advance and consumes an Undo step.'
    cases.append(case)

# Preserve exact test-only fixtures in the same research folder. Later fixtures
# intentionally reference run 01's captured helper definitions, as executed.
fixture_dest = DEST / 'outside-brush-fixtures'
fixture_dest.mkdir(exist_ok=True)
for number, name in ((1,'edge_cases.ms'),(3,'edge_sweep.ms'),(4,'hold_outside.ms')):
    shutil.copy2(run_name(number) / 'fixture.ms', fixture_dest / name)
shutil.copy2(__file__, fixture_dest / 'collect_evidence.py')

evidence = {
    'product':'CyrusPhysicsLab', 'version':'0.1.2', 'max_year':2027,
    'scope':{'test_only':True, 'computer_use':False, 'physical_input_tested':False,
             'implementation_changes':False,'preset_changes':False,
             'integration':False,'install_restart_artist_session':False,
             'commit_push':False},
    'method':'Owned hidden Max 2027; actual Start button handler; private SDK driver uses viewport projection, Painter TestHit, StartStroke, PaintStroke, EndStroke/CancelStroke; ordinary product binaries.',
    'fixture':{'receiver':'5000 x 5000 mm Plane, 4 x 4 segments, XY at z=0',
               'source':'Sphere32, radius 32.788mm, scale 1; full 482-vertex render mesh',
               'seed':42,'spacing_m':.2,'drop_height_m':.1,
               'radii_m':[.01,.25],'viewport':'Top; 12000 x 9000 mm disposable hidden framing Plane; receiver is the sole Painter target'},
    'source_receipt':ref(receipt_path), 'git':{
        'branch':subprocess.check_output(['git','branch','--show-current'],text=True).strip(),
        'head':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),
        'status':subprocess.check_output(['git','status','--short'],text=True)},
    'preservation':{'before_receipt':ref(BEFORE),'all_before_hashes':before,
                    'changed_files':changed,'frozen_build_source_mismatches':source_mismatches,
                    'normal_profile_files_unchanged':True},
    'private_probe':{'binary':ref(ROOT/'build/physics-lab-brush-probe-011/CyrusPhysicsProbe.dlx'),
                     'source':ref(ROOT/'CyrusPhysicsLab/tests/paint_probe/probe.cpp'),
                     'packaged':False},
    'package_unchanged':ref(ROOT/'dist/CyrusPhysicsLab-0.1.2-20261016/CyrusPhysicsLab-0.1.2-Max2027.mzp'),
    'scripted_assertions':total, 'scenarios':len(cases), 'runs':runs,'cases':cases,
    'failed_test_harness_iteration':{
        'run':'build/physics-lab-012-outside-02',
        'error':(run_name(2)/'error.txt').read_text(),
        'interpretation':'Test fixture compile error from a top-level local declaration; no brush behavior exercised. Corrected only the ignored test fixture; successor run 03 passed.'},
    'knowledge':{'status':'stale_evidence','source_verification_requested':True,
                 'sources_checked':38,'sources_verified':15,
                 'physics_lab_enrolled':False,'fallback':'Direct current and frozen source inspection; ordinary frozen binaries hash verified.'},
    'limits':['No physical mouse/tablet input or artist-session testing.',
              'One horizontal finite Plane and one Sphere32 source; arbitrary curved/concave receivers, holes, production scenes, and body motion beyond receiver edges are not qualified.',
              'Viewport quantization affects spacing counts; recorded counts are observations, not general spacing guarantees.',
              'Hold-budget test advances fixed solver steps directly; it is not a wall-clock latency measurement.',
              'Private driver calls StartStroke when resuming a split path; existing session is retained; miss samples run actual Painter TestHit and PaintStroke.']}
(DEST/'OUTSIDE_BRUSH_012_EVIDENCE.json').write_text(json.dumps(evidence,indent=2)+'\n')
print(json.dumps({'scripted_assertions':total,'scenarios':len(cases),'source_changes':changed,
                  'edge_failure_reproduced':True,'evidence':str(DEST/'OUTSIDE_BRUSH_012_EVIDENCE.json')},indent=2))
