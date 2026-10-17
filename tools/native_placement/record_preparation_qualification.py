"""Verify and record the optional-preparation checkpoint, not a product release."""
import argparse, hashlib, json, subprocess
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--host', required=True)
parser.add_argument('--native', required=True, type=Path)
parser.add_argument('--run', required=True, type=Path)
parser.add_argument('--output', required=True, type=Path)
args = parser.parse_args()
assert args.host.startswith('foundation-memory0854-nativeaccept-controller-')
host = ROOT/'build/mcp-qualification'/args.host
native, run = args.native.resolve(), args.run.resolve()
receipt = json.loads((native/'receipt.json').read_text())
launch = json.loads((host/'launch.json').read_text())
assert receipt['max_year'] == launch['max_year'] == 2027
assert all(row['exit_code'] == 0 for row in receipt['stages'])
assert not receipt['placement_qualification'] and not receipt['preview_fault_lab']
assert not launch.get('native_reuse') and not launch['normal_profile_modified']
assert all(sha(ROOT/path) == digest for path, digest in receipt['sources'].items())
assert sha(ROOT/'AminScatter/scripts/AminScatterObject.ms') == launch['script_sha256'] == sha(host/'scripts/CyrusScatter.ms')
for path, digest in receipt['binaries'].items(): assert sha(ROOT/path) == digest
for name, digest in launch['binaries'].items(): assert sha(host/'bin'/name) == digest
for name, digest in launch['script_assets'].items(): assert sha(host/'scripts'/name) == digest
checks = {
    'preparation-final.log': 'MAX 2027 OPTIONAL NATIVE PREPARATION PARITY PASSED',
    'controller-final.log': 'MAX 2027 OPTIONAL CONTROLLER/HISTORY PASSED',
    'base-controller-final.log': 'MAX 2027 NATIVE CONTROLLER/HISTORY PASSED',
    'core-final.log': 'CORE PASSED',
    'presets-final.log': 'ALL EIGHT PRESETS PASSED',
    'python-final.log': '168 passed',
}
for filename, marker in checks.items(): assert marker in (run/filename).read_text(encoding='utf-8-sig'), filename
assert '100% tests passed, 0 tests failed out of 43' in (native/'tests.log').read_text()
generated = json.loads((run/'generated-final/generated-check.json').read_text())
assert generated['generated_sha256'] == launch['script_sha256']
modules = json.loads((run/'loaded-modules-final.json').read_text(encoding='utf-8-sig'))
assert {row['Name'] for row in modules} == set(launch['binaries'])
for row in modules:
    assert Path(row['Path']).resolve() == (host/'bin'/row['Name']).resolve()
    assert row['SHA256'] == launch['binaries'][row['Name']]
closure = json.loads((host/'closure-observation.json').read_text())
assert closure['exited'] and closure['close_marker']
artifacts = [native/'receipt.json', native/'tests.log', host/'launch.json', host/'closure-observation.json',
             host/'native-preparation.txt', host/'native-controller.txt', host/'generation.txt',
             run/'loaded-modules-final.json', run/'generated-final/generated-check.json']
artifacts += [run/name for name in checks]
drivers = [ROOT/'tools/native_placement'/name for name in (
    'preparation.ms','preparation_controller.ms','run_preparation.py','run_preparation_controller.py',
    'generation.ms','controller.ms','run_controller.py','run_generation.py')]
output = {
    'schema': 'cyrus.native-optional-preparation-qualification/1',
    'recorded_utc': datetime.now(timezone.utc).isoformat(),
    'implementation_parent': subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
    'status': 'Scoped internal checkpoint; default controller still selects the existing engine; not N03/N09 completion or a release',
    'source_version': '0.85.4', 'planned_first_native_delivery': '0.86.0',
    'host': args.host, 'max_year': 2027, 'sources': receipt['sources'],
    'artifacts': {str(path.relative_to(ROOT)).replace('\\','/'): sha(path) for path in artifacts+drivers},
    'qualification': [
        'Whole Scale, mesh density and Analyzer Area direct adapters match complete ordered fields on plane/mountain through 200k candidates.',
        'Native adapter calls produce no placement-sized script rows/matrices/identities/population arrays in covered counters.',
        'Scale builders and removal selections preserve source/receiver provenance; failure leaves input immutable; final pins release.',
        'Internal Whole Scale/mesh-mask controller matches complete accepted rows/radii/statistics through 200k and zero Count.',
        'Real same-frame mesh mapping and Data Channel Curvature/Vertex Output notifications update Live results.',
        'Manual pending, Count Undo/Redo, missing-channel retention/recovery and optional-feature save/reopen pass.',
        '65 seconds idle/panel browsing performs zero mesh reads, preparation, solves, preview builds or retained uploads on both terrains.',
        'Existing native controller lifecycle, default engine core and all eight ready-preset regressions pass on this exact pair.',
    ],
    'limits': [
        'Analyzer Area controller routing remains guarded pending actual Analyzer-owner freshness/history qualification.',
        'No new physical VertexPaint stroke, UI drag/scroll/DPI or renderer qualification.',
        'Single optional-route Update timing observations are not controlled performance distributions or presented FPS.',
        'Existing small-count native overhead remains an N08 profiling/correction requirement.',
        'Tracked placement vectors exclude solver scratch, metadata, allocator/GC, full process peaks and graphics allocations.',
        'Paint, falloff, special Analyzer orientation, final Relax, remaining grid/Band routing, active Edit and downstream consumers remain open.',
        'No version bump, user installer or artist installation at this internal checkpoint.',
    ],
    'corrected_iterations': [
        'Initial direct test used an empty density curve; corrected to the required two-sample identity curve.',
        'Initial controller test helper conflicted with MAXScript log(); helpers now have a PC prefix.',
        'A nonempty StringStream initialized the read buffer; explicit format now writes the ReceiverFields prefix before its values.',
        'Data Channel test used a signed 32-bit hex operator ID; full-width Integer64 Class IDs create both actual operators.',
    ],
}
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps(output, indent=2)+'\n', encoding='utf-8')
print(f'Recorded {len(receipt["sources"])} source hashes and {len(output["artifacts"])} evidence hashes', flush=True)
