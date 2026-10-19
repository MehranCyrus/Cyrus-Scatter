"""Record a frozen compatibility baseline or stage back-saved example copies."""
from pathlib import Path
import argparse, hashlib, json, shutil, subprocess, sys
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT/'build/compatibility-0862-20261019'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
p = argparse.ArgumentParser(); p.add_argument('operation', choices=('baseline', 'libraries')); p.add_argument('--host'); a = p.parse_args()
if a.operation == 'baseline':
    OUT.mkdir(parents=True, exist_ok=True)
    assert not (OUT/'baseline.json').exists()
    paths = [p for root in ('AminScatter', 'cmake') for p in (ROOT/root).rglob('*') if p.is_file() and 'build' not in p.relative_to(ROOT).parts]
    state = {key: subprocess.check_output(['git', *args], cwd=ROOT, text=True).strip() for key, args in (
        ('head', ['rev-parse', 'HEAD']), ('branch', ['branch', '--show-current']), ('status', ['status', '--short']))}
    state.update(version='0.86.2', requested_hosts=[2024, 2026, 2027], artist_installation=False,
        acceptance=['Matching SDK/native/managed pairs', 'Max 2026 density/library/UI/Undo/idle qualification',
                    'Max 2024 preview with explicit missing runtime limit', 'Exact multi-host EXE inventory and disposable install/upgrade tests'],
        files={p.relative_to(ROOT).as_posix(): sha(p) for p in paths})
    (OUT/'baseline.json').write_text(json.dumps(state, indent=2)+'\n')
else:
    assert a.host.startswith('density0862-compat-')
    host = ROOT/'build/mcp-qualification'/a.host
    assert json.loads((host/'launch.json').read_text())['max_year'] == 2027
    sys.path.insert(0, str(ROOT/'tools/native_placement'))
    from run_generation import send, ready
    ready(host)
    src = ROOT/'AminScatter/library'; inventory = json.loads((src/'inventory.json').read_text())
    for year in (2024, 2026):
        dest = OUT/f'libraries/library{year}'; assert not dest.exists(); shutil.copytree(src, dest)
        code = 'for d in #(CyrusRecipeBrowser,CyrusReadyPresetEditor) where d!=undefined do destroyDialog d\n'
        for entry in inventory['entries']:
            code += f'if not loadMaxFile @"{(src/entry["scene"]).as_posix()}" quiet:true useFileUnits:true do throw "Example load failed"\n'
            code += f'if not saveMaxFile @"{(dest/entry["scene"]).as_posix()}" quiet:true saveAsVersion:{year} do throw "Example back-save failed"\n'
        script = host/f'backsave-{year}.ms'; script.write_text(code, encoding='utf-8-sig')
        send(host, script, f'Back-save copies for {year}')
        copied = json.loads((dest/'inventory.json').read_text())
        copied.update(version='0.86.2', max_year=year,
            delivery_note='0.86.2 compatibility payload. Examples back-saved by an owned Max 2027 host; see current delivery for runtime scope.')
        copied['files'] = {name: sha(dest/name) for name in copied['files']}
        (dest/'inventory.json').write_text(json.dumps(copied, indent=2)+'\n')
        print('Staged', dest, flush=True)
