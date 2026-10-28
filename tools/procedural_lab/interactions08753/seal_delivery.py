"""Seal exact Max2027 package, final host checks and preserved artist inputs."""
from pathlib import Path
import hashlib,json,os,re,shutil,subprocess,sys,zipfile

ROOT=Path(__file__).resolve().parents[3]
RUN=ROOT/'build/interactions08753-20261028-01'
DOC=ROOT/'docs/plans/scene-repair-08753-20261028'
sys.path.insert(0,str(ROOT/'tools'))
import build_inputs

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def read(path):return json.loads(path.read_text(encoding='utf-8'))
def ref(path):return {'path':path.relative_to(ROOT).as_posix(),'sha256':sha(path)}

producer=RUN/'native-09';receipt=read(producer/'receipt.json')
assert receipt['status']=='complete' and receipt['tests_run'] and receipt['max_year']==2027
build_inputs.verify_frozen(receipt['input_manifest'],ROOT)
assert '100% tests passed, 0 tests failed out of 62' in (producer/'tests.log').read_text()
source_archive=RUN/'package-09/CyrusScatter-0.87.5.3-Max2027.mzp'
with zipfile.ZipFile(source_archive) as z:
    assert z.testzip() is None
    manifest=json.loads(z.read('manifest.json'))
    assert manifest['version']=='0.87.5.3' and manifest['max_year']==2027
    for name,digest in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest,name
    script=z.read('CyrusScatter.ms')
    fingerprint=re.search(rb'CyrusLoadedScriptFingerprint="([0-9a-f]{64})"',script)[1].decode()
    assert b'29000' in z.read('install.ms') and b'__MAX_' not in z.read('install.ms')
    assert hashlib.sha256(script).hexdigest()==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
installer=read(RUN/'installer-09/receipt.json')
assert installer['status']=='pass' and installer['archive_sha256']==sha(source_archive)
loaded=[]
artist=Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini'
for host_name in ('host-11','host-12'):
    host=RUN/host_name;identity=read(host/'loaded-identity.json');launch=read(host/'launch.json')
    assert identity['host']==2027 and identity['script_fingerprint']==fingerprint
    for name,item in identity['modules'].items():assert item['sha256']==manifest['files'][name] and sha(Path(item['path']))==item['sha256']
    assert sha(artist)==launch['artist_ini_sha256']
    for name,digest in launch['payload'].items():assert digest==manifest['files'][name]
    loaded.append({'host':host_name,**identity})

baseline=read(RUN/'starting-state.json');unaffected=[]
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()==baseline['head'].strip()
for path in ('AminScatter/shared/SharedLibrary.cs','AminScatter/shared/SharedLibrary.Management.cs',
             'AminScatter/src/recipe_library.cpp','AminScatter/src/recipes.cpp','AminScatter/src/recipes_bridge.cpp'):
    assert sha(ROOT/path)==baseline['files'][path],path;unaffected.append(path)
version_only=('AminScatter/shared/SharedLibrary.Scenes.cs','AminScatter/tools/ui/templates/scene-presets.ms','AminScatter/tools/ui/templates/recipes.ms')
for path in version_only:
    assert (ROOT/path).read_bytes().replace(b'0.87.5.3',b'0.87.5.2')==(RUN/'source-before'/path).read_bytes(),path
shader=ROOT/'AminScatter/src/deformation_shader.inc'
assert sha(shader)=='250da91bd361a84da43687c282287ec360a4342f96b19cbd9f84f9a8266276d3'
original=ROOT/'Test Scene/New Plants test 22.max'
assert sha(original)=='579d63bec07fb14fce17c1461baf8e2cc2bfa3a53516402367f7f4f16c96acfd'

host=RUN/'host-11';checks=[]
names=('sources-setup','sources-remove-models','sources-add-models','sources-missing-row','sources-stale-selection',
       'sources-manual','sources-placeholder-empty','sources-placeholder-point','library-native-add','library-native-observe',
       'scene-native-save','scene-native-ready','scene-native-merge','scale-setup','scale-model','scale-source-node',
       'scale-save-reload','render-small','render-dense','dense-move','dense-under','drag-check-final','reprepare-bindings','nav-arm-final')
for name in names:
    path=host/(name+'.json');value=read(path);assert value['status']=='pass',(name,value)
    checks.append({'name':name,**ref(path)})
journal=sorted((host/'journal-native-history').glob('*.json'))
journal_values=[(path,read(path)) for path in journal]
assert all(v['status']=='pass' and not v['holding_after'] and not v['suspended_after'] for _,v in journal_values)
for kind in ('replace','model','empty','point','remove','scale','offset','fast'):
    for phase in ('journal-native-record','journal-native-undo-check','journal-native-redo-check'):
        assert any(v.get('kind')==kind and v['phase']==phase for _,v in journal_values),(kind,phase)
campaigns=sorted(host.glob('journal-campaign-*.json'))
assert campaigns and read(campaigns[-1])['status']=='pass' and read(campaigns[-1])['resumed_kinds'] is None
for path,value in journal_values:checks.append({'name':value['phase'],**ref(path)})
checks.append({'name':'native-journal-campaign',**ref(campaigns[-1])})
scene_campaigns=sorted(host.glob('scene-native-campaign-*.json'))
assert scene_campaigns and read(scene_campaigns[-1])['status']=='pass'
checks.append({'name':'scene-preset-campaign',**ref(scene_campaigns[-1])})

nav=read(host/'nav-arm-final.json');first,last=nav['samples'][0],nav['samples'][-1]
assert nav['navigation']==500000 and nav['idle']==0 and all(x>0 for x in nav['draw_delta'])
assert not any(nav['upload_delta'].values()) and not last['held'] and not last['idle_timer']
assert first['view_matrix']!=last['view_matrix'] and first['work']==last['work'] and first['epoch']==last['epoch']
drag=read(host/'drag-check-final.json');assert drag['upload_delta']['1']==drag['upload_delta']['7']==0
assert all(drag['work_delta'][key]==0 for key in ('source_preparations','source_captures','collider_cooks'))
binding=read(host/'reprepare-bindings.json');assert binding['upload_delta']['7']>0
small=read(host/'render-small.json');dense=read(host/'render-dense.json');under=read(host/'dense-under.json')
assert small['info']['constructed_faces']==small['bake']['faces']==550020
assert sum(x['combined_construction_bytes'] for x in dense['info']['outputs'])>1024**3
assert dense['info']['constructed_faces']>0 and all(x['batches']>1 for x in dense['info']['outputs'])
paired_path=ROOT/'build/source-scale-edit-08753-20261028-01/exact-cache/comparison.json';paired=read(paired_path)
assert paired['same_pose_digests_and_logical_budget']
generated=read(RUN/'generated-final-08/generated-check.json')
assert generated['passed'] and generated['development_version']=='0.87.5.3' and generated['generated_sha256']==manifest['files']['CyrusScatter.ms']

trials=[]
for label in ('broad','original'):
    trial_host=RUN/'host-12'
    saved_path=trial_host/('trial-native-save-'+label+'.json');loaded_path=trial_host/('trial-native-load-'+label+'.json')
    saved=read(saved_path);reloaded=read(loaded_path)
    assert saved['status']==reloaded['status']=='pass' and saved['snapshot']==reloaded['snapshot']
    assert not saved['holding_after'] and not reloaded['holding_after']
    scene=Path(saved['scene']).resolve();assert scene.is_relative_to(ROOT/'Test Scene/Interaction 0.87.5.3')
    assert scene.is_file() and scene!=original
    trials.append({'label':label,**ref(scene),'bytes':scene.stat().st_size,'configuration':reloaded['snapshot']})
    checks.extend([{'name':'native-trial-save-'+label,**ref(saved_path)},{'name':'native-trial-reload-'+label,**ref(loaded_path)}])

destination=ROOT/'dist/CyrusScatter-0.87.5.3-20261028';destination.mkdir(parents=True,exist_ok=True)
archive=destination/source_archive.name
if archive.exists():assert sha(archive)==sha(source_archive),'Existing delivery archive differs'
else:shutil.copy2(source_archive,archive)
for suffix in ('.build.json','.sha256'):
    companion=source_archive.with_suffix(suffix)
    if companion.exists():shutil.copy2(companion,destination/companion.name)

move=read(host/'dense-move.json')
report={'schema':'cyrus.scene-repair-delivery/1','version':'0.87.5.3','date':'2026-10-28','max_year':2027,
        'status':'qualified_with_recorded_limits',
        'baseline':{'version':'0.87.5.2','branch':baseline['branch'].strip(),'head':baseline['head'].strip(),**ref(RUN/'starting-state.json')},
        'scope':'Test22 source workflow, evaluated source scale, Edit binding, bounded exact render construction, CPU work reuse and explicit retained viewport navigation',
        'capabilities':{'interactions':13,'source_transform':2,'source_command_undo':1,'edit':4,'edit_storage':3,'scene_schema':63,'portable_recipe':9,'scene_preset_metadata':1},
        'native':{'sources_verified':len(receipt['sources']),'tests_passed':62,**ref(producer/'receipt.json')},
        'package':{**ref(archive),'bytes':archive.stat().st_size,'files':manifest['files'],'embedded_script_fingerprint':fingerprint},
        'installer':installer,'loaded_identities':loaded,'generated':generated,'host_checks':checks,
        'measurements':{'scope':'CPU wall/contact costs and observed graphics work; no presented FPS or GPU timing claim',
            'broad_inside_solid_median_fit_ms':move['median_fit_ms'],'broad_inside_solid_median_edit_command_ms':move['median_wall_edit_ms'],
            'under_collider_fit_ms':under['statistics']['fit_ms'],'under_collider_hidden_roots':under['statistics']['hidden_roots'],
            'under_collider_fitted_guides':under['statistics']['fitted_guides'],
            'paired_numeric':{**paired,'receipt':ref(paired_path)},
            'viewport_idle_planned_triangles':last['viewport'][5],'viewport_moving_planned_triangles':last['viewport'][6],
            'orbit_draw_callbacks_idle_moving':nav['draw_delta'],'orbit_upload_bytes':nav['upload_delta'],
            'physical_drag_upload_bytes':drag['upload_delta'],'physical_drag_work_delta':drag['work_delta'],
            'new_preparation_binding_upload_bytes':binding['upload_delta']['7'],
            'dense_render_combined_construction_bytes':sum(x['combined_construction_bytes'] for x in dense['info']['outputs']),
            'dense_render_batches':sum(x['batches'] for x in dense['info']['outputs']),
            'small_render_bake_faces':small['bake']['faces']},
        'trial_scenes':trials,
        'preservation':{'original_scene':ref(original),'artist_ini_unchanged':True,'library_implementation_unchanged':unaffected,
            'version_strings_only':list(version_only),'production_hlsl_unchanged':True,'artist_profile_installed_or_restarted':False,
            'git_committed_or_pushed':False,'older_hosts_built_or_tested':False},
        'knowledge':{'generation':'637cdc784e7dba8eab31f2703578abc9011bd792d70fa553095aa37fd1b4613a','fresh_at_start':32,'enrolled':64,'status':'stale; current source inspected directly','refreshed':False},
        'harness_limits':['Earlier Python-bridge Undo/hold observations are diagnostics, not source-command Undo qualification. Final journal uses pure MAXScript events and actual GUI picker/Ctrl-Z/Ctrl-Y.',
            'A reprepare test syntax error was repaired in the harness; its failed receipt remains. Final new-source binding invalidation passed.',
            'Whole-scene texture relinking/save was repeated in a fresh pure-MAXScript host after the Python test bridge reported an active hold; final trial load/save/reload gates are clean.'],
        'limits':['Deep broad overlaps still report stem-edge strain warnings; exact geometric checks do not establish botanical plausibility.',
            'Contacts require positive uniform similarity; arbitrary shear, mirror and singular scales remain guarded.',
            'Source-command journal supports static authored settings. The keyed-controller guard is inspected but not independently qualified in Max by this campaign.',
            'Batch construction bounds exclude renderer-held meshes and total RSS. Only public callback construction and Bake counts are checked; broad external-renderer output is not qualified.',
            'Fast navigation is an explicit complete-instance subset. Zero remains unlimited; no per-plant decimation, CUDA solver, new hull feature, universal million-object FPS or soak qualification.']}
DOC.mkdir(parents=True,exist_ok=True)
(DOC/'QUALIFICATION_08753.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(RUN/'qualification-final.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps({'version':report['version'],'archive':str(archive),'sha256':sha(archive),'native_tests':62,'host_receipts':len(checks),'trial_scenes':len(trials)},indent=2))
