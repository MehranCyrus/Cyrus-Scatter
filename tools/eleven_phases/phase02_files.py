"""Admission limits and storage failures; writes only an owned disposable directory."""
from pathlib import Path
import json
import stat
import time
import traceback
from pymxs import runtime as r

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent == ROOT / 'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-p02-')
run = Path(str(r.MCPFixtureLast)).stem
folder = OUT / ('file-admission-' + run)
folder.mkdir()
result = {'status': 'started', 'checks': []}

def check(ok, label):
    result['checks'].append({'passed': bool(ok), 'label': label})
    if not ok:
        raise AssertionError(label)

def reject(fn, label):
    failed = False
    try:
        fn()
    except Exception:
        failed = True
    check(failed, label)

try:
    doc = r.Array('spacing', 'Admission witness', r.Array(True, 1.5, .25, False))
    text = str(r.cyrusPresetEncode(*list(doc))).encode('utf-8')
    for i in range(512):
        (folder / f'{i:04}.cspreset.json').write_bytes(text)
    started = time.perf_counter()
    rows = r.CyrusPresetEntries(str(folder), 'spacing')
    result['scan_512_ms'] = (time.perf_counter()-started)*1000
    check(len(rows[0]) == 512 and rows[1] == 0, '512 valid files are admitted without truncation')
    extra = folder / 'extra.cspreset.json'
    extra.write_bytes(text)
    reject(lambda: r.CyrusPresetEntries(str(folder), 'spacing'), '513 files produce an explicit library-limit error')
    extra.unlink()
    boundary = folder / 'boundary.json'
    boundary.write_bytes(text + b' '*(65536-len(text)))
    check(str(r.CyrusPresetRead(str(boundary))[0]) == 'spacing', '64 KiB valid document is admitted')
    boundary.write_bytes(text + b' '*(65537-len(text)))
    reject(lambda: r.CyrusPresetRead(str(boundary)), '64 KiB plus one byte is rejected before parsing')
    boundary.unlink()
    reject(lambda: r.CyrusPresetRead(str(boundary)), 'Missing file reports failure')
    target = folder / '0000.cspreset.json'
    original = target.read_bytes()
    target.chmod(stat.S_IREAD)
    try:
        reject(lambda: r.CyrusPresetWrite(str(target), doc, replace=True), 'Read-only replacement fails')
    finally:
        target.chmod(stat.S_IWRITE | stat.S_IREAD)
    check(target.read_bytes() == original and not list(folder.glob('*.tmp')), 'Read-only failure preserves existing bytes and cleans temporary file')
    obstacle = folder / 'not-a-directory'
    obstacle.write_text('owned fixture', encoding='utf-8')
    reject(lambda: r.CyrusPresetWrite(str(obstacle / 'preset.json'), doc), 'Unavailable storage reports failure')
    check(obstacle.read_text() == 'owned fixture', 'Storage failure preserves blocking file')
    result['status'] = 'complete'
except Exception:
    result['status'] = 'failed'
    result['error'] = traceback.format_exc()
finally:
    payload = json.dumps(result, indent=2) + '\n'
    (OUT / ('phase02-files-' + run + '.json')).write_text(payload)
    (OUT / 'phase02-files.json').write_text(payload)
if result['status'] != 'complete':
    raise RuntimeError(result['error'])
