"""Serialize final qualification in one owned Max; retain each subprocess log."""
import argparse, datetime, hashlib, json, subprocess, sys, time
from run_generation import ROOT, ready

p = argparse.ArgumentParser()
p.add_argument('host')
p.add_argument('--start', default='capacity')
a = p.parse_args()
assert a.host.startswith('foundation-memory0854-nativeaccept-controller-')
h = ROOT / 'build/mcp-qualification' / a.host
ready(h)
steps = [('capacity', 'run_capacity.py'), ('lifecycle', 'run_lifecycle.py'),
         ('retention', 'run_retention.py')]
steps += [(name, 'run_shipping.py', name) for name in
          ('goldens', 'controller', 'edit', 'preparation', 'fields')]
steps += [('presets', 'run_presets.py'), ('outputs', 'run_shipping.py', 'outputs'),
          ('render', 'run_render.py')]
assert a.start in [s[0] for s in steps]
steps = steps[[s[0] for s in steps].index(a.start):]
script = ROOT / 'AminScatter/scripts/AminScatterObject.ms'
identity = hashlib.sha256(script.read_bytes()).hexdigest()
for name, driver, *extra in steps:
    assert hashlib.sha256(script.read_bytes()).hexdigest() == identity
    log = h / ('final-' + name + '.log')
    receipt = h / ('final-' + name + '.json')
    assert not log.exists() and not receipt.exists(), 'Use fresh evidence names'
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    begin = time.monotonic()
    print('FINAL MATRIX: ' + name, flush=True)
    cmd = [sys.executable, '-B', str(ROOT / 'tools/native_placement' / driver), a.host, *extra]
    with log.open('w') as out:
        result = subprocess.run(cmd, stdout=out, stderr=subprocess.STDOUT)
    receipt.write_text(json.dumps({'status': 'passed' if result.returncode == 0 else 'failed',
        'started_utc': started, 'elapsed_seconds': time.monotonic() - begin,
        'command': cmd, 'script_sha256': identity,
        'launch_sha256': hashlib.sha256((h / 'launch.json').read_bytes()).hexdigest(),
        'log_sha256': hashlib.sha256(log.read_bytes()).hexdigest()}, indent=2) + '\n')
    if result.returncode:
        print(log.read_text()[-6000:], flush=True)
        raise SystemExit(result.returncode)
    print('FINAL MATRIX PASSED: ' + name, flush=True)
