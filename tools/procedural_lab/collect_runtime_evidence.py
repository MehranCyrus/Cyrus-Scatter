"""Validate and preserve concise receipts from the isolated 0.7 Max campaign."""
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import shutil
import statistics

ROOT = Path(__file__).resolve().parents[2]
RUN = ROOT / 'build/mcp-qualification/procedural07-runtime-b'
BASELINE = ROOT / 'build/mcp-qualification/procedural07-baseline-064'
OUT = ROOT / 'docs/Procedural_Implementation_0.7_2026-10-04/evidence/runtime'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    checks = read(RUN / 'procedural-acceptance.json')
    assert checks['complete']
    campaign = read(RUN / 'release-campaign.json')
    assert len(campaign) == 9 and all(c['exit_code'] == 0 for c in campaign)
    mcp = read(RUN / 'procedural-mcp.json')
    assert all(mcp[k] is True for k in ('pure_inspection', 'new_order_and_rule', 'pending_recipe_separate_from_epoch', 'legacy_mutation_guard_rejected'))
    assert all(read(RUN / 'bindings-acceptance.json').values())
    ui = read(RUN / 'ui-lifetime.json')
    assert ui['handles_retained'] and ui['zero_generation'] and ui['zero_display_rebuild']
    pointer = read(RUN / 'ui-pointer.json')
    assert pointer['painted'] > pointer['undo_count'] and pointer['redo_exact']
    units = read(RUN / 'units-acceptance.json')
    assert not units['automatic_rescale_supported'] and units['adopt_file_units_exact'] and units['history_preserved']
    OUT.mkdir(parents=True, exist_ok=True)
    names = ('procedural-acceptance.json', 'release-campaign.json', 'procedural-mcp.json', 'bindings-acceptance.json', 'units-acceptance.json', 'ui-pointer.json', 'ui-rule.json', 'ui-lifetime.json', 'loaded-binaries.json', 'artist-example.json')
    for name in names:
        shutil.copy2(RUN / name, OUT / name)
    for folder in (RUN, BASELINE):
        loaded = read(folder / 'loaded-binaries.json')
        expected = read(folder / 'launch.json')['binaries']
        for module in loaded:
            assert module['sha256'] == expected[module['name']] == sha(Path(module['path']))
        shutil.copy2(folder / 'loaded-binaries.json', OUT / ('baseline-loaded-binaries.json' if folder == BASELINE else 'loaded-binaries.json'))
    navigation = []
    modes = {0: 'Scatter hidden', 1: 'Point Cloud', 2: 'Proxy', 3: 'Mesh', 4: 'Plant centres'}
    for folder, prefix in ((BASELINE, 'baseline'), (RUN, 'procedural')):
        for size in ('20k', '100k'):
            path = folder / f'{prefix}-{size}-navigation.json'
            data = read(path)
            assert data['viewport'] == [1302, 750] and data['source_faces'] == 32
            summaries = []
            for pairs in data['trials']:
                trial = dict(pairs)
                assert trial['generated'] == data['population'] and trial['zero_rebuilds']
                if trial['retained_before'] is not None:
                    for index in (2, 3, 4, 5, 6, 8):
                        assert trial['retained_before'][index] == trial['retained_after'][index]
                if trial['mode'] == 3:
                    assert trial['mesh'][1] == data['population']
                values = sorted(trial['step_ms'])
                summaries.append({'mode': modes[trial['mode']], 'frames': len(values), 'p50_ms': round(statistics.median(values), 3), 'p95_ms': round(values[math.ceil(.95 * len(values)) - 1], 3), 'p99_ms': round(values[math.ceil(.99 * len(values)) - 1], 3), 'zero_rebuilds': True})
            navigation.append({**{k: v for k, v in data.items() if k != 'trials'}, 'trials': summaries})
            shutil.copy2(path, OUT / path.name)
    (OUT / 'navigation-summary.json').write_text(json.dumps(navigation, indent=2) + '\n')
    script = ROOT / 'AminScatter/scripts/AminScatterObject.ms'
    example = ROOT / 'dist/procedural-0.7-candidate/CyrusScatter-0.7-Example-Max2027.max'
    summary = {'recorded_at_utc': datetime.now(timezone.utc).isoformat(), 'host_year': 2027, 'maxscript_loaded': True, 'generated_sha256': sha(script), 'private_sessions_only': True, 'artist_profile_installed': False,
               'mcp_live_campaigns_passed': 9, 'procedural_mcp_read_only_passed': True,
               'brush_pointer_surface': 'nonuniformly scaled sphere', 'planar_brush_test': 'native ray/dab API', 'native_rollout_cycles': 20,
               'navigation_populations': [20000, 100000], 'navigation_zero_rebuilds': True,
               'max2026_runtime': 'unavailable; SDK build/native suites only',
               'artist_example': {'path': example.relative_to(ROOT).as_posix(), 'sha256': sha(example)},
               'limitations': ['Automatic system-unit rescaling of stored Brush/Edit/radius data is unsupported. Adopt saved scene units.', 'High-count Proxy drawing remains expensive in both 0.64 and 0.7.', 'Policy 3 MCP mutation and ML are not implemented.', 'Installer replacement of an artist profile was not performed.'],
               'files_sha256': {p.name: sha(p) for p in sorted(OUT.iterdir()) if p.is_file() and p.name != 'summary.json'}}
    (OUT / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    print(json.dumps(summary, indent=2))


if __name__ == '__main__':
    main()
