"""Seal the exact source/package/loaded-pair evidence without refreshing knowledge."""
from pathlib import Path
import hashlib,json,os,re,subprocess,sys,zipfile
ROOT=Path(__file__).resolve().parents[3];RUN=ROOT/'build/interactions08752-20261027-01'
DOC=ROOT/'docs/plans/contact-audit-08752-20261027';sys.path.insert(0,str(ROOT/'tools'))
import build_inputs
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8'))
producer=RUN/'native-final';receipt=read(producer/'receipt.json')
assert receipt['status']=='complete' and receipt['tests_run'] and receipt['max_year']==2027
build_inputs.verify_frozen(receipt['input_manifest'],ROOT)
assert '100% tests passed, 0 tests failed out of 61' in (producer/'tests.log').read_text()
archive=ROOT/'dist/CyrusScatter-0.87.5.2-20261027/CyrusScatter-0.87.5.2-Max2027.mzp'
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None;manifest=json.loads(z.read('manifest.json'))
    assert manifest['version']=='0.87.5.2' and manifest['max_year']==2027
    for name,digest in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest,name
    script=z.read('CyrusScatter.ms');fingerprint=re.search(rb'CyrusLoadedScriptFingerprint="([0-9a-f]{64})"',script)[1].decode()
    assert b'29000' in z.read('install.ms') and b'__MAX_' not in z.read('install.ms')
    assert hashlib.sha256(script).hexdigest()==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
loaded=read(RUN/'host-final/loaded-identity.json');assert loaded['host']==2027 and loaded['script_fingerprint']==fingerprint
for name,item in loaded['modules'].items():assert item['sha256']==manifest['files'][name] and sha(Path(item['path']))==item['sha256']
launch=read(RUN/'host-final/launch.json');artist=Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini'
assert sha(artist)==launch['artist_ini_sha256']
for name,digest in launch['payload'].items():assert digest==manifest['files'][name]
baseline=read(RUN/'starting-state.json');unaffected=[]
for path in ('AminScatter/shared/SharedLibrary.cs','AminScatter/shared/SharedLibrary.Management.cs','AminScatter/src/cyrus_edit.cpp','AminScatter/src/recipe_library.cpp','AminScatter/src/recipes.cpp','AminScatter/src/recipes_bridge.cpp'):
    assert sha(ROOT/path)==baseline['files'][path],path;unaffected.append(path)
for path in ('AminScatter/shared/SharedLibrary.Scenes.cs','AminScatter/tools/ui/templates/scene-presets.ms'):
    assert (ROOT/path).read_bytes().replace(b'0.87.5.2',b'0.87.5.1')==(RUN/'source-before'/path).read_bytes(),path
checks=[]
for name in ('audit-setup','audit-passive','audit-bench-200','audit-bench-1000','audit-pending','audit-save-reload',
             'runtime-grass','runtime-fern','runtime-authored-fern','runtime-bake','runtime-all-hidden','runtime-drag-before',
             'runtime-drag-after','runtime-record-undo','runtime-undo-read','runtime-redo-read','runtime-failure',
             'library-save','library-poll','library-merge'):
    path=RUN/'host-final'/(name+'.json');d=read(path);assert d['status']=='pass',(name,d)
    checks.append({'name':name,'path':str(path.relative_to(ROOT)),'sha256':sha(path)})
for name in ('runtime-grass','runtime-fern','runtime-authored-fern'):assert read(RUN/'host-final'/(name+'.json'))['audit']['passed']
generated=read(RUN/'generated-seal/generated-check.json');assert generated['passed'] and generated['development_version']=='0.87.5.2' and generated['generated_sha256']==manifest['files']['CyrusScatter.ms']
gpu=read(RUN/'gpu-final/gpu-audit.json');assert gpu['status']=='pass'
paired=read(RUN/'paired-final/summary.json');assert paired['poses_and_warnings_identical'] and paired['new_median_ms']<paired['old_median_ms']
natural=read(RUN/'final-natural/replay.json');assert all(x['poses_identical'] for x in natural['comparison'])
stress=read(RUN/'host-final/stress-audit.json');assert stress['status']=='recorded' and not stress['audit']['passed']
stress_geometry={'triangles':stress['audit']['triangles'],
    'penetrating_vertex_obstacle_pairs':sum(x['penetrating_vertex_obstacle_pairs'] for x in stress['audit']['results']),
    'touching_triangle_obstacle_pairs':sum(x['touching_triangle_obstacle_pairs'] for x in stress['audit']['results']),
    'root_anchor_error_m':max(x['root_anchor_error_m'] for x in stress['audit']['results']),
    'maximum_stem_edge_change':max(x['maximum_stem_edge_change'] for x in stress['audit']['results']),
    'quality_passed':False}
assert stress_geometry['penetrating_vertex_obstacle_pairs']==0 and stress_geometry['touching_triangle_obstacle_pairs']==0 and stress_geometry['root_anchor_error_m']==0
saved=Path(read(RUN/'host-final/audit-save-reload.json')['scene']);assert saved.is_file() and saved.is_relative_to(RUN)
report={'schema':'cyrus.interaction-audit-delivery/1','version':'0.87.5.2','date':'2026-10-27','max_year':2027,
    'status':'qualified_with_recorded_limits','baseline':{'version':'0.87.5.1','branch':baseline['branch'].strip(),'head':baseline['head'].strip(),'snapshot_sha256':sha(RUN/'starting-state.json')},
    'scope':'CPU contact work optimization, diagnostics and retained Max 2027 delivery; no claim of universal physical correctness or presented FPS',
    'native':{'receipt':str((producer/'receipt.json').relative_to(ROOT)),'receipt_sha256':sha(producer/'receipt.json'),'sources_verified':len(receipt['sources']),'tests_passed':61},
    'package':{'path':str(archive.relative_to(ROOT)),'bytes':archive.stat().st_size,'sha256':sha(archive),'files':manifest['files'],'embedded_script_fingerprint':fingerprint},
    'loaded_identity':loaded,'host_checks':checks,'generated':generated,
    'paired_numeric':{k:paired[k] for k in ('fixture','fixture_sha256','poses_and_warnings_identical','old_median_ms','new_median_ms','improvement_percent')},
    'natural_replay':natural['comparison'],'hardware_math':{'corners':sum(x['gpu']['corners'] for x in gpu['results']),'visibility_mismatches':sum(x['gpu']['visibility_mismatches'] for x in gpu['results']),'maximum_error_m':max(x['gpu']['maximum_error_m'] for x in gpu['results']),'receipt_sha256':sha(RUN/'gpu-final/gpu-audit.json')},
    'stress_geometry':stress_geometry,'saved_test_copy':{'path':str(saved.relative_to(ROOT)),'bytes':saved.stat().st_size,'sha256':sha(saved)},
    'preservation':{'artist_ini_unchanged':True,'library_implementation_unchanged':unaffected,'scene_preset_changes':'version strings only','artist_installed_or_restarted':False},
    'knowledge':{'generation':'637cdc784e7dba8eab31f2703578abc9011bd792d70fa553095aa37fd1b4613a','verified_at_start':40,'enrolled':64,'status':'stale; direct source inspected','refreshed':False},
    'limits':['Dense/deep overlap retains the preceding basal skin strain failure; observed roughly 3.915 mm absolute edge change.',
              'Real Max command durations are not GPU time or presented FPS; source-edit/material/renderer/soak cases are not universally qualified.',
              'No older Max host, CUDA solver, proxy-feature implementation, EXE, website publication or git push in this scope.']}
(DOC/'QUALIFICATION_08752.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(RUN/'qualification-final.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps({'version':report['version'],'archive_sha256':sha(archive),'sources':len(receipt['sources']),'host_checks':len(checks),'paired_improvement_percent':paired['improvement_percent'],'stress_quality_pass':False},indent=2))
