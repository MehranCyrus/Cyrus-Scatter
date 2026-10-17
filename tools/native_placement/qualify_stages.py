"""Validate local stage witnesses and retain their exact identities in the handoff.

This dated receipt is internal progress, never a delivery/certification verifier.
Raw Max scenes, request copies and native modules remain ignored local artifacts.
"""
from pathlib import Path
import hashlib,json,subprocess

ROOT=Path(__file__).resolve().parents[2]
RUN=ROOT/'build/native-migration-0860-20261017-02'
CURRENT=ROOT/'build/mcp-qualification/foundation-memory0854-nativeaccept-20261017-01'
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def record(path):return {'path':Path(path).relative_to(ROOT).as_posix(),'sha256':sha(path)}
def read(path):return Path(path).read_text(encoding='utf-8-sig')
def build(name):
    path=RUN/name/'receipt.json';data=json.loads(read(path))
    assert data['max_year']==2027 and all(s['exit_code']==0 for s in data['stages'])
    assert '42/42' in read(RUN/name/'tests.log') and '100% tests passed, 0 tests failed out of 42' in read(RUN/name/'tests.log')
    return {**record(path),'placement_qualification':data['placement_qualification'],'source_set':'acceptance' if name.startswith('acceptance') else 'producer-and-hold','binaries':data['binaries'],'native_suites_passed':42,'test_output':record(RUN/name/'tests.log')}
def host(name,outputs):
    folder=ROOT/'build/mcp-qualification'/name
    launch=json.loads(read(folder/'launch.json'));closure=json.loads(read(folder/'closure-observation.json'))
    assert closure['close_marker'] and closure['exited']
    requests=sorted(folder.glob('generation-*.ms'))+sorted(folder.glob('request-*.ms'))
    return {'name':name,'pid':launch['pid'],'script_sha256':launch['script_sha256'],'binaries':launch['binaries'],'placement_qualification':launch.get('placement_qualification',False),'launch':record(folder/'launch.json'),'loaded':record(folder/'loaded.tsv'),'closure':closure,'closure_receipt':record(folder/'closure-observation.json'),'outputs':[record(folder/p) for p in outputs],'copied_request_scripts':{p.name:sha(p) for p in requests}}

old=json.loads(read(RUN/'product-native-01/receipt.json'))['sources']
assert old==json.loads(read(RUN/'qualification-native-01/receipt.json'))['sources']
current=json.loads(read(RUN/'acceptance-native-01/receipt.json'))['sources']
assert all(sha(ROOT/p)==h for p,h in current.items())
assert 'MAX 2027 NATIVE RADII/ACCEPTANCE PARITY PASSED' in read(RUN/'acceptance-02.log')
accept=read(CURRENT/'acceptance.txt')
for terrain in ('plane','mountain'):
    for label in ('simple','receivers','grid','sourceFilter','empty','surface','overrides','target','cleanup','scopes','protected surface','failure retention'):
        assert f'PASS {terrain} {label}' in accept,(terrain,label)
    for count in (5000,50000,200000):assert f'PASS {terrain} simple requested={count} ' in accept
assert 'FAIL' not in accept and read(CURRENT/'generation.txt').count('PASS CASE ')==26
assert 'CORE PASSED' in read(RUN/'acceptance-core.log')
assert 'ALL EIGHT PRESETS PASSED' in read(RUN/'acceptance-presets.log')
inventory=json.loads(read(ROOT/'AminScatter/library/inventory.json'))
preset_outputs=[]
for entry in inventory['entries']:
    for phase in ('setup','load','verify','undo','verifyUndo','redo','verifyRedo','reopen','verifyReopen'):
        path=CURRENT/f"acceptance-{entry['id']}-{phase}.txt";text=read(path)
        assert 'PASS: complete' in text and 'FAIL:' not in text
        preset_outputs.append(record(path))
assert 'PASS: complete' in read(CURRENT/'generation-boundaries.txt')
hold=ROOT/'build/mcp-qualification/foundation-memory0854-nativegenerate-hold-20261017-03'
assert len(read(hold/'hold-events.txt').splitlines())==42
assert 'PASS complete state=#(0L, 0L, 0L, 0L, 5L, 5L' in read(hold/'hold-observations.txt')
preserved={}
for path in ('AminScatter/tools/ui/templates/unified-core.ms','AminScatter/scripts/AminScatterObject.ms','AminScatter/src/surface_filter.cpp','AminScatter/include/surface_filter.h'):
    original=subprocess.check_output(['git','show','8645c6c:'+path],cwd=ROOT)
    assert hashlib.sha256(original).hexdigest()==sha(ROOT/path);preserved[path]=sha(ROOT/path)
helpers=[*sorted((ROOT/'tools/native_placement').glob('*.py')),*sorted((ROOT/'tools/native_placement').glob('*.ms')),
    ROOT/'tools/build_max.py',ROOT/'tools/memory_0854/host.py',ROOT/'tools/procedural_lab/layer_editor_071/private_host.py',ROOT/'tools/procedural_lab/offline_build.py',ROOT/'tools/tests/test_package_version.py']
assert '168 passed' in read(RUN/'pytest.log')
generated=RUN/'generated/generated-check.json';assert json.loads(read(generated))['passed']
document={
    'schema':'cyrus.native-stage-qualification/1','date':'2026-10-17','parent_git_head':'8645c6cc4878a05e8fa6f835610872b2da1359ea',
    'status':'Internal native producer/preparation/acceptance adapters; full goal active. Not an integrated native controller or user delivery.',
    'version':{'product_metadata':'0.85.4','schema':58,'target_first_coherent_delivery':'0.86.0','installer_created':False,'artist_installation':False},
    'source_sets':{'producer-and-hold':old,'acceptance':current},
    'builds':{name:build(name) for name in ('product-native-01','qualification-native-01','acceptance-native-01')},
    'hosts':[
        host('foundation-memory0854-nativegenerate-product-20261017-01',['generation.txt','generation-benchmark.tsv','generation-boundaries.txt']),
        host('foundation-memory0854-nativegenerate-hold-20261017-03',['generation.txt','hold-observations.txt','hold-events.txt']),
        host('foundation-memory0854-nativeaccept-20261017-01',['startup-observation.json','acceptance.txt','generation.txt','generation-boundaries.txt','memory-fix.txt'])],
    'checks':{'generated':record(generated),'python':{'passed':168,'output':record(RUN/'pytest.log')},'current_generation_cases':26,
        'acceptance_terrains':['plane','mountain'],'acceptance_counts':[5000,50000,200000],
        'acceptance':'Full ordered semantic rows, radii, supplied bindings/statistics; source transforms/filtering, explicit receiver correspondence, grids, existing surface math, overrides, cleanup/refill, protected scopes and failure retention.',
        'current_controller_regression':record(RUN/'acceptance-core.log'),'current_eight_presets':record(RUN/'acceptance-presets.log'),'preset_outputs':preset_outputs,
        'private_hold':{'created':5,'destroyed_after_abandoned_redo':5,'events':42,'unique_vector_bytes':13920000,'maximum_conservative_record_pins_bytes':19680000,'explicit_held_size_bytes':4800160,'last_pin_release_bytes':0,
            'limits':'Standalone private SDK owner; not production Count/preset Undo implementation. Size calls include explicit theHold.Size(). Independent script/current pins remain until final release.'}},
    'preserved_source_sha256':preserved,'helpers_at_checkpoint':{p.relative_to(ROOT).as_posix():sha(p) for p in helpers},
    'benchmark':record(ROOT/'docs/plans/native-placement/N03_PRODUCER_BENCHMARK.json'),
    'source_eol_observation':{'receipt':record(RUN/'git-source-eol-observation.json'),'explanation':'24 pre-existing unedited inputs differ from Git HEAD only by CRLF. Raw compiled inputs are hashed above. Changed native inputs preserve qualified bytes. This is not an exact-byte clean-checkout/release rebuild claim.'},
    'knowledge':{'generation':'70c3934732cfdcec5c56ac5b5cef3b261a25491cce8826b38198a8a42a3e3100','compatible':True,'verified':33,'enrolled':36,'stale':['AGENTS.md','README.md','AminScatter/src/cyrus_edit_stack.inc'],'new_sources':'Direct source inspection; not enrolled. No index refresh.'},
    'failed_or_incomplete_attempts':[
        {'host':'foundation-memory0854-nativegenerate-regression-20261017-01','status':'PID 55632 observed absent before fixture readiness. No product result or exit code established.'},
        {'host':'foundation-memory0854-nativegenerate-regression-20261017-02','status':'PID 31152 observed absent before fixture readiness. No product result or exit code established.'},
        {'host':'foundation-memory0854-nativegenerate-hold-20261017-01','status':'Private marker rejected before Max creation. Mistakenly started waiting Python helper alone was identity-verified and stopped.'},
        {'host':'foundation-memory0854-nativegenerate-hold-20261017-02','status':'Hold sequence passed; Max abbreviated event-array print. One-off export had a top-level local compile error. Fresh -03 passed with all 42 events exported.'},
        {'host':'foundation-memory0854-nativegenerate-product-20261017-01','status':'Initial boundary helper names were local across fileIn calls. Explicit globals repaired the driver; rerun passed without a native change.'}],
    'remaining':['N01 complete peak/scratch/history attribution and physical input measurement','N02 controller ownership, source correspondence and publication epoch','N03 optional Paint/mesh-mask/falloff/Bands/Analyzer/Relax adapters and production grid integration','N04 reduce copied Sample scratch and measure view/compaction retention','N05 immutable publication, retained preview and ordinary Count Undo/Redo on the actual native route','N06 inspection/render/PFlow/Bake','N07 sparse authored Edit and real history accounting','N08 measured admission/caches/responsiveness','N09 full frozen-pair matrix, knowledge, MZP/EXE and recipient acceptance','Every original and advanced area in OBJECTIVE.md after the foundation'],
    'limits':['Parity uses the retained bridge and existing independent pure numerical tests; no independent renderer oracle.','Bare joins validate owner/stage/source count, not asset identity tables. v2 hashes metadata supplied by the caller.','Zero script materializations applies to covered adapters, not Paint or the still-scripted main placement route.','Native counters exclude solver/sample/geometry/source/allocator/GPU storage. No full Update speedup or complete peak reduction claimed.','Successful hosts were guarded-closed; artist and unrelated Physics Lab hosts preserved.','Ignored fixtures/modules/copied requests remain local; hashes do not embed their binary contents.']}
output=ROOT/'docs/plans/native-placement/N03_N04_QUALIFICATION.json'
output.write_text(json.dumps(document,indent=2)+'\n',encoding='utf-8')
print(output,'validated')
