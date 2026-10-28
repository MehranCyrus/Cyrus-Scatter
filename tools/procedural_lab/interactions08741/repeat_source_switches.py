"""Repeat real source/contact and rejected-sphere cycles in an owned Max host.

This records a bounded negative-reproduction experiment, not proof that an
earlier intermittent access violation has been fixed. Every UI phase uses a
separate host event; a failure or captured access violation stops the run.
"""
from argparse import ArgumentParser
from pathlib import Path
import json
import subprocess
import sys
import traceback

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
parser = ArgumentParser()
parser.add_argument('--host', type=Path, required=True)
parser.add_argument('--models', nargs='+', required=True)
args = parser.parse_args()
host = args.host.resolve()
if not host.is_relative_to(ROOT / 'build') or not (host / 'launch.json').is_file():
    raise ValueError('A specifically launched disposable host is required')
if not json.loads((host / 'ready.json').read_text(encoding='utf-8')).get('status') == 'ready':
    raise ValueError('The disposable host did not pass initialization')
if any(not key.isalnum() for key in args.models):
    raise ValueError('Each source key must be alphanumeric')

result_path = host / 'source-switch-stress-final.json'
if result_path.exists():
    raise ValueError('Use a fresh host for each run')
result = {'status': 'running', 'models': args.models, 'cycles': [],
          'access_violation_captures': [],
          'scope': 'Owned Max 2027 process, matched package; first-chance '
                   'recorder does not handle exceptions. No reproduction is '
                   'not a diagnosis or proof of absence.'}


def save():
    result['access_violation_captures'] = sorted(p.name for p in host.glob('access-violation-*.txt'))
    result_path.write_text(json.dumps(result, indent=2), encoding='utf-8')


def command(script, *options):
    completed = subprocess.run([sys.executable, str(HERE / script), '--host', str(host), *options],
                               cwd=ROOT, capture_output=True, text=True, timeout=620)
    if completed.returncode:
        raise RuntimeError((completed.stderr or completed.stdout)[-5000:])
    return completed.stdout


try:
    command('dispatch_job.py', '--script', str(HERE / 'install_av_capture_host.py'),
            '--case', 'AVCapture', '--direction', '1')
    capture = json.loads((host / 'av-capture-install.json').read_text(encoding='utf-8'))
    if capture.get('status') != 'installed':
        raise RuntimeError('The access-violation recorder did not install: ' + str(capture))
    for number, model in enumerate(args.models, 1):
        key = model + '-switch' + str(number).zfill(2)
        command('dispatch.py', '--case', key, '--timeout', '600')
        case = json.loads((host / 'cases' / (key + '.json')).read_text(encoding='utf-8'))
        cycle = {'case': key, 'name': case.get('name'), 'case_status': case.get('status'),
                 'contacts': case.get('contact_count'), 'audits': case.get('valid_audit_count'),
                 'away_restored': case.get('away_restored')}
        result['cycles'].append(cycle)
        save()
        if (case.get('status') != 'pass' or case.get('contact_count') != 3 or
                case.get('valid_audit_count') != 3 or not case.get('away_restored')):
            raise RuntimeError('Plant contact cycle failed: ' + str(cycle))
        for phase, expected in ((1, 'box_selected'), (2, 'expected_preparation_failure')):
            command('dispatch_job.py', '--script', str(HERE / 'wrong_source_recovery_host.py'),
                    '--case', key, '--direction', str(phase))
            phase_result = json.loads((host / 'wrong-source-recovery.json').read_text(encoding='utf-8'))
            cycle['wrong_source_phase_' + str(phase)] = phase_result
            save()
            if phase_result.get('status') != expected:
                raise RuntimeError('Wrong-source phase failed: ' + str(phase_result))
            if result['access_violation_captures']:
                raise RuntimeError('An access violation was captured; inspect it before proceeding')
        print(number, model, case.get('name'), 'three contacts passed; sphere rejected', flush=True)
    result['status'] = 'pass'
except Exception:
    result.update(status='failed', error=traceback.format_exc())
    print(result['error'], flush=True)
finally:
    save()
if result['status'] != 'pass':
    raise SystemExit(1)
