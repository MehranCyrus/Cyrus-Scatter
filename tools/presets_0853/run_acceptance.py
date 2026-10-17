"""Run actual preset progress callbacks and lifecycle boundaries serially."""
from pathlib import Path
import argparse, json, subprocess, sys
from await_host import wait

ROOT = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser()
p.add_argument('profile', type=Path)
p.add_argument('--ids', nargs='+', default=['meadow', 'woodland', 'mountain', 'borders', 'orchard', 'hexagonal', 'formal', 'valley'])
a = p.parse_args()
host = a.profile.resolve()
assert host.parent == ROOT / 'build/mcp-qualification' and host.name.startswith('foundation-presets0853-')
for identity in a.ids:
    receipt = json.loads((host / f'library-{identity}-capture.json').read_text(encoding='utf-8'))
    assert receipt['status'] == 'passed'
    (host / 'preset-path.txt').write_text(receipt['package'], encoding='utf-8')
    (host / 'acceptance-id.txt').write_text(identity, encoding='utf-8')
    for phase in ['setup', 'load', 'verify', 'undo', 'verifyUndo', 'redo', 'verifyRedo', 'reopen', 'verifyReopen']:
        if phase=='verify':wait(host,'CyrusReadyPresetEditor!=undefined and CyrusReadyPresetEditor.finished')
        (host / 'acceptance-phase.txt').write_text(phase, encoding='utf-8')
        result = subprocess.run([sys.executable, str(ROOT / 'tools/presets_0853/dispatch.py'), str(host)],
                                input='fileIn "' + (ROOT / 'tools/presets_0853/acceptance.ms').as_posix() + '"',
                                text=True, capture_output=True)
        print(identity, phase, result.stdout.strip(), flush=True)
        if result.returncode:
            print(result.stderr, flush=True)
            raise SystemExit(result.returncode)
        text = (host / f'acceptance-{identity}-{phase}.txt').read_text(encoding='utf-8-sig')
        assert 'PASS: complete' in text and 'FAIL:' not in text, text
