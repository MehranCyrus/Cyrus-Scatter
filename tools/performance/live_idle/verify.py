"""Check recorded work counters independently of wall-clock performance."""
import argparse
import json
from pathlib import Path

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('folder', type=Path)
p.add_argument('--baseline', type=Path)
p.add_argument('--prefix', default='')
a = p.parse_args()
folder = a.folder.resolve()


def read(name, directory=folder):
    if directory == folder and name != 'setup':
        name = a.prefix + name
    result = json.loads((directory / ('idle-' + name + '.json')).read_text())
    assert result['status'] == 'complete', name
    return result


checks = []


def verify(condition, label):
    checks.append({'passed': bool(condition), 'check': label})


setup = read('setup')
if a.baseline:
    baseline = read('setup', a.baseline)
    if not setup.get('scene_sha256') or not baseline.get('scene_sha256'):
        raise ValueError('Cross-build equality requires the same saved scene, including receiver identities; independently created synthetic scenes have different receiver salts.')
    verify(setup.get('scene_sha256') == baseline.get('scene_sha256'), 'Identical input scene')
    verify(setup['placements'] == baseline['placements'], 'Identical placement counts')
    verify(setup['fingerprints'] == baseline['fingerprints'], 'Identical position/source fingerprints')

work = ['epoch', 'builds', 'hits', 'prepared', 'preview_builds', 'time_queries',
        'syncs', 'redraw_requests']
for operation in ['idle', 'navigation', 'panels', 'unrelated', 'parameter', 'not_ready', 'recover']:
    before, after = read(operation + '-idle-before'), read(operation + '-idle-after')
    x, y = before['before'], after['after']
    for key in work:
        verify(x[key] == y[key], operation + ': idle ' + key + ' unchanged')
    # Native draws may increase when the OS repaints. No generation, preparation,
    # publication, upload, allocation or failure may change during a quiet window.
    for i in [0, 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12]:
        verify(x['retained'][i] == y['retained'][i], operation + ': retained field ' + str(i + 1) + ' unchanged')
    verify(before['fingerprints'] == after['fingerprints'], operation + ': idle placements unchanged')
    for key in ['pending', 'presentation_pending', 'records_dirty', 'release_timer', 'ui_timer']:
        verify(not y[key], operation + ': ' + key + ' is stopped/clear')
    verify(not any(y['dirty']), operation + ': all evaluated layers clean')
    verify(not any(y['errors']) and not y['display_error'], operation + ': no error')

for operation in ['navigation', 'panels', 'unrelated']:
    action = read(operation)
    verify(action['before_fingerprints'] == action['fingerprints'], operation + ': interaction preserves placements')
    for key in ['epoch', 'builds', 'prepared', 'preview_builds']:
        verify(action['before'][key] == action['after'][key], operation + ': no ' + key + ' work')
    verify(action['before']['retained'][5:7] == action['after']['retained'][5:7], operation + ': no GPU uploads')

action = read('parameter')
settled = read('parameter-idle-after')['after']
verify(settled['epoch'] == action['before']['epoch'] + 1, 'Relevant parameter commits exactly one successor')
verify(action['before_fingerprints'] != read('parameter-idle-after')['fingerprints'], 'Relevant parameter changes placements')
verify(read('recover-idle-after')['after']['retained'][11] == '1', 'Explicit refresh restores ready native preview')

report = {'passed': all(x['passed'] for x in checks), 'assertions': len(checks),
          'placements': sum(setup['placements']), 'checks': checks,
          'limits': 'Counters are not presented FPS; measurements cover these owned fixtures only.'}
(folder / ('idle-' + a.prefix + 'verification.json')).write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({k: v for k, v in report.items() if k != 'checks'}, indent=2))
for check in checks:
    if not check['passed']:
        print('FAIL: ' + check['check'])
raise SystemExit(0 if report['passed'] else 1)
