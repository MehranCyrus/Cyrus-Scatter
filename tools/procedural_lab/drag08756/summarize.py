"""Summarize only the executed Max viewport campaign, never inferred FPS."""
from pathlib import Path
import argparse, hashlib, json, re, statistics

ROOT = Path(__file__).resolve().parents[3]
p = argparse.ArgumentParser()
p.add_argument('--run', type=Path, required=True)
p.add_argument('--host', required=True)
p.add_argument('--payload', required=True)
p.add_argument('--output', type=Path, required=True)
a = p.parse_args()
run = a.run.resolve()

def movement(folder, name, require_pass=False):
    path = run / folder / (name + '.txt')
    lines = path.read_text(encoding='utf-8-sig').splitlines()
    samples, frames = [], []
    for line in lines:
        if line.startswith('STEP '):
            prefix, data = line.split(' stats:', 1)
            match = re.fullmatch(r'STEP (\d+) native_ms:(\d+) redraw_ms:(\d+)', prefix)
            samples.append({'step': int(match[1]), 'command_ms': int(match[2]),
                            'redraw_call_ms': int(match[3]), 'work': json.loads(data)})
        elif line.startswith('FRAME '):
            match = re.match(r'FRAME #\(1, (\d+)L, (\d+)L', line)
            frames.append({'requested': int(match[1]), 'presented': int(match[2]),
                           'raw': line})
    assert len(samples) == 24 and len(frames) == 24, path
    moving = samples[:12]
    steady = samples[12:]
    errors = [s['work']['error'] for s in samples if s['work']['error']]
    unchanged = all(s['work']['process_work'] == samples[11]['work']['process_work'] for s in steady)
    presented = len({f['presented'] for f in frames[:12]})
    cache_keys = ('source_preparations', 'source_captures', 'collider_cooks', 'layouts')
    cache_reuse = all(all(s['work']['process_work'][k] == moving[0]['work']['process_work'][k]
                         for k in cache_keys) for s in moving)
    if require_pass:
        assert not errors and all(s['work']['failures'] == 0 for s in samples), errors
        assert unchanged and cache_reuse and presented >= 10
        assert all(s['work']['mesh_refinement_work'] == 0 for s in samples)
    return {'path': str(path.relative_to(ROOT)), 'fit_median_ms': statistics.median(s['work']['fit_ms'] for s in moving),
            'fit_range_ms': [min(s['work']['fit_ms'] for s in moving), max(s['work']['fit_ms'] for s in moving)],
            'command_median_ms': statistics.median(s['command_ms'] for s in moving),
            'redraw_call_median_ms': statistics.median(s['redraw_call_ms'] for s in moving),
            'navigation_redraw_call_median_ms': statistics.median(s['redraw_call_ms'] for s in steady),
            'compute_participants': sorted({s['work']['compute_participants'] for s in moving}),
            'presented_tickets_during_movement': presented, 'errors': errors,
            'navigation_work_unchanged': unchanged, 'movement_source_and_layout_reuse': cache_reuse,
            'samples': samples, 'frames': frames}

baseline = movement('host-baseline', 'baseline-scene')
scene = movement(a.host, 'final-scene', True)
edit = movement(a.host, 'final-edit', True)
rapid_scene = movement(a.host, 'rapid-scene', True)
controls_path = run/a.host/'trunk-controls.txt'
controls = []
for line in controls_path.read_text(encoding='utf-8-sig').splitlines():
    if line.startswith('CONTROL '):
        prefix, data = line.split(' stats:', 1)
        match = re.fullmatch(r'CONTROL (\d+) trunk:([\d.]+) base:([\d.]+) fade:([\d.]+)', prefix)
        controls.append({'sample': int(match[1]), 'trunk': float(match[2]),
                         'fixed_base': float(match[3]), 'fade': float(match[4]), 'work': json.loads(data)})
assert len(controls) == 4
assert all(not c['work']['error'] and c['work']['failures'] == 0 for c in controls)
assert all(c['work']['process_work']['source_preparations'] == controls[0]['work']['process_work']['source_preparations'] for c in controls)
assert controls[2]['fixed_base'] == 1 and controls[2]['work']['fitted_guides'] == 0
identity = json.loads((run/a.payload/'package-identity.json').read_text(encoding='utf-8'))
loaded = json.loads((run/a.host/'loaded-identity.json').read_text(encoding='utf-8'))
launch = json.loads((run/a.host/'launch.json').read_text(encoding='utf-8'))
for name, module in loaded['modules'].items():
    assert module['sha256'] == identity['files'][name]
for name, digest in launch['payload'].items():
    assert digest == identity['files'][name]
script = (run/a.payload/'CyrusScatter.ms').read_text(encoding='utf-8-sig')
assert re.search(r'CyrusLoadedScriptFingerprint="([0-9a-f]{64})"', script)[1] == loaded['script_fingerprint']
archive = Path(identity['archive'])
assert hashlib.sha256(archive.read_bytes()).hexdigest() == identity['sha256']
scene_file = ROOT/'Test Scene/New Plants test 22.max'
result = {'version': '0.87.5.6', 'host': 2027,
          'scope': 'MAXScript viewport, scripted scene/Cyrus Edit stone movement and navigation only; no Computer Use',
          'limitations': ['Timer-driven moves with the held-input predicate enabled are not physical mouse-gesture qualification.',
                         'Fit timings measure CPU contact calculation, not end-to-end frame rate.',
                         'Baseline used Detailed contact; the new artistic Bend path deliberately has different approximation quality.',
                         'Native test suites, external renderers, installer UI and older Max hosts were not run.'],
          'package': identity, 'loaded_identity': loaded,
          'input_scene': {'path': str(scene_file), 'sha256': hashlib.sha256(scene_file.read_bytes()).hexdigest(),
                          'note': 'Loaded from this path; all saved trial files are inside the owned build profile.'},
          'baseline': baseline, 'scene_drag': scene, 'edit_drag': edit, 'rapid_scene_drag': rapid_scene,
          'trunk_controls': controls,
          'scene_fit_speedup': baseline['fit_median_ms']/scene['fit_median_ms']}
a.output.parent.mkdir(parents=True, exist_ok=True)
a.output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
print(json.dumps({k: result[k] for k in ('version','scene_fit_speedup')}))
print('Scene fit median:', scene['fit_median_ms'], 'Edit fit median:', edit['fit_median_ms'])
