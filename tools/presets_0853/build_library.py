"""Serialize eight isolated Max scene/capture requests; never replay a timeout."""
from pathlib import Path
import argparse, json, subprocess, sys

ROOT = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('profile', type=Path)
p.add_argument('--ids', nargs='+', default=['woodland', 'mountain', 'borders', 'orchard', 'hexagonal', 'formal', 'valley'])
a = p.parse_args()
host = a.profile.resolve()
assert host.parent == ROOT / 'build/mcp-qualification' and host.name.startswith('foundation-presets0853-')
for identity in a.ids:
    for phase in ('open', 'capture'):
        (host / 'command.json').write_text(json.dumps({'id': identity, 'phase': phase}), encoding='utf-8')
        result = subprocess.run([sys.executable, str(ROOT / 'tools/presets_0853/dispatch.py'), str(host)],
                                input='python.ExecuteFile "' + (ROOT / 'tools/presets_0853/library.py').as_posix() + '"',
                                text=True, capture_output=True)
        print(identity, phase, result.stdout.strip(), flush=True)
        if result.returncode:
            print(result.stderr, flush=True)
            raise SystemExit(result.returncode)
        record = json.loads((host / f'library-{identity}-{phase}.json').read_text(encoding='utf-8'))
        assert record['status'] == 'passed', record
