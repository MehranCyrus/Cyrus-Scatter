"""Stage a verified script-only pair and test Amount in an existing owned Max 2027 host."""
from pathlib import Path
import argparse, hashlib, json, re, sys, time

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/native_placement'))
from run_generation import send, ready

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('host')
parser.add_argument('--pair', type=Path, required=True)
parser.add_argument('--phase', nargs='+')
args = parser.parse_args()
assert re.fullmatch(r'density0862-map-audit-[a-z0-9-]+', args.host)
host = ROOT / 'build/mcp-qualification' / args.host
ready(host)
launch = json.loads((host / 'launch.json').read_text())
assert launch['max_year'] == 2027
pair = args.pair.resolve()
receipt = json.loads((pair / 'receipt.json').read_text())
assert receipt['max_year'] == 2027 and receipt.get('script_only_revision')
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
for name, digest in receipt['sources'].items():
    assert sha(ROOT / name) == digest, name
for name, digest in launch['binaries'].items():
    assert sha(host / 'bin' / name) == sha(pair / name) == digest, name
assert sha(host / 'scripts/CyrusGallery.dll') == sha(pair / 'CyrusGallery.dll')

if not args.phase:
    script = host / 'scripts/CyrusScatter.ms'
    original = sha(script)
    script.write_bytes((ROOT / 'AminScatter/scripts/AminScatterObject.ms').read_bytes())
    stage = host / 'reload-candidate.ms'
    stage.write_text('''(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-map-audit-*/" do throw "Owned audit profile required"
 CyrusClearMeshMaskPreview undefined
 resetMaxFile #noPrompt
 gc light:true
 fileIn (MCPFixtureDir+"scripts/CyrusScatter.ms")
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"candidate-fingerprint.txt") CyrusLoadedScriptFingerprint
)
''', encoding='utf-8-sig')
    send(host, stage, 'Stage matched Clear candidate')
    fingerprint = re.search(r'CyrusLoadedScriptFingerprint="([a-f0-9]+)"', script.read_text())[1]
    assert (host / 'candidate-fingerprint.txt').read_text(encoding='utf-8-sig') == fingerprint
    (host / 'candidate-stage.json').write_text(json.dumps({
        'original_script_sha256': original, 'candidate_script_sha256': sha(script),
        'fingerprint': fingerprint, 'pair_receipt_sha256': sha(pair / 'receipt.json'),
        'native_binaries_unchanged': True, 'max_year': 2027,
    }, indent=2))

phases = args.phase or ('setup', 'mount', 'manualClear', 'undo', 'verifyUndo',
    'redo', 'verifyRedo', 'meshClear', 'undo', 'verifyMeshUndo', 'switch', 'patternClear',
    'liveClear', 'verifyLive', 'idle', 'liveMeshClear', 'verifyLiveMesh',
    'save', 'reopen', 'verifyReopen')
for phase in phases:
    if phase in ('mount', 'verifyLive', 'idle', 'verifyLiveMesh', 'save', 'verifyReopen'):
        time.sleep(3)
    (host / 'audit-phase.txt').write_text(phase)
    send(host, ROOT / 'tools/density_map_audit/regression.ms', phase)
    result = (host / ('regression-' + phase + '.txt')).read_text(encoding='utf-8-sig')
    print(result, flush=True)
    assert 'PASS: complete' in result and 'ERROR' not in result
print('PASS: requested Amount regression phases', flush=True)
