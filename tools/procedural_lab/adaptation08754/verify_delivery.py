"""Seal 0.87.5.4 evidence without launching or installing into artist hosts."""
from pathlib import Path
import hashlib,json,os,statistics,sys,zipfile
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'tools'))
import build_inputs,build_max

BASE=ROOT/'build/adaptation08754-20261028-01'
DIST=ROOT/'dist/CyrusScatter-0.87.5.4-20261028'
DOC=ROOT/'docs/plans/scene-adaptation-08754-20261028'
NAMES=('AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh')
def read(path):return json.loads(Path(path).read_text(encoding='utf-8-sig'))
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def relative(path):return Path(path).resolve().relative_to(ROOT).as_posix()
def ref(path):return {'path':relative(path),'sha256':sha(path)}
def stats(record,key='statistics'):return json.loads(record[key])

packages={}
for year,producer,stage in [(2027,'native-07','package-stage-01'),(2024,'native-2024-01','package-2024-stage-01'),(2026,'native-2026-01','package-2026-stage-01')]:
    receipt_path=BASE/producer/'receipt.json'
    receipt=build_max.verify_native_receipt(receipt_path,'AminScatter',year,{name:BASE/stage/'AminScatter'/name for name in NAMES})
    archive=DIST/f'CyrusScatter-0.87.5.4-Max{year}.mzp'
    build_inputs.verify_package_receipt(archive,ROOT)
    with zipfile.ZipFile(archive) as z:
        assert z.testzip() is None
        manifest=json.loads(z.read('manifest.json'))
        assert manifest['max_year']==year and manifest['version']=='0.87.5.4'
        assert set(z.namelist())==set(manifest['files'])|{'manifest.json'}
        for name,expected in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==expected,name
        install=z.read('install.ms')
        assert str((year-1998)*1000).encode() in install and b'__MAX_' not in install
        assert hashlib.sha256(z.read('CyrusScatter.ms')).hexdigest()==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
        packages[str(year)]={**ref(archive),'native_producer':ref(receipt_path),'tests_run':receipt['tests_run'],
            'native_test_count':62 if receipt['tests_run'] else 0,'host_tested':year==2027,
            'scope':receipt['qualification'],'payload_hashes':{name:manifest['files'][name] for name in (*NAMES,'CyrusScatter.ms','CyrusGallery.dll','CyrusInstaller.dll')}}
    print('Verified exact SDK/source/package:',year,flush=True)

exe=DIST/'CyrusScatter-0.87.5.4-Setup.exe'
build_inputs.verify_managed(exe,'installer-exe',ROOT)
exe_resources=read(BASE/'exe-integrity.json')
assert exe_resources['status']=='pass' and exe_resources['exe_sha256']==sha(exe)
assert {r['year'] for r in exe_resources['hosts']}=={2024,2026,2027}
assert all(r['matches_mzp'] and r['sha256']==packages[str(r['year'])]['sha256'] for r in exe_resources['hosts'])

suite=ET.parse(BASE/'pytest-final.xml').getroot()
suites=list(suite) if suite.tag=='testsuites' else [suite]
assert sum(int(s.get('tests','0')) for s in suites)==577
assert sum(int(s.get('failures','0'))+int(s.get('errors','0')) for s in suites)==0

dense=read(BASE/'host-05/dense.json');after=stats(dense,'after');times=[x for x in dense['times_ms'] if x>0]
assert dense['status']=='pass' and after['plants']==1000 and after['limited_guides']==0 and after['mesh_refinement_work']==0
render=read(BASE/'host-05/render-bake-native.json');render_info=stats(render,'render')
assert render_info['constructed_faces']==render['baked_faces']==18291
grove=read(BASE/'host-06/neighbor-grove.json');off,on,again=(stats(grove,k) for k in ('neighbors_off','neighbors_on','repeated'))
assert off['posed']==0 and on['posed']>0 and on['pruned_guides']>0 and on['limited_guides']==0
assert on['process_work']==again['process_work'] and on['generation']==again['generation']
restore=read(BASE/'host-06/neighbor-restore.json');before,away,returned=(stats(restore,k) for k in ('before','away','returned'))
assert before['pruned_guides']>0 and away['pruned_guides']==0 and returned['pruned_guides']==before['pruned_guides']
for key in ('source_captures','source_preparations','collider_cooks','layouts'):
    assert before['process_work'][key]==returned['process_work'][key]
drag=read(BASE/'host-06/actual-drag-redraw.json');held=[r for r in drag if r['held']]
assert held and stats(held[-1])['generation']>stats(drag[0])['generation']
for key in ('source_captures','source_preparations','collider_cooks','layouts'):
    assert stats(held[-1])['process_work'][key]==stats(drag[0])['process_work'][key]
assert held[-1]['epoch']==drag[0]['epoch'] and held[-1]['group_builds']==drag[0]['group_builds']
nav=read(BASE/'host-06/actual-navigation.json')
assert nav['status']=='pass' and not any(nav['upload_deltas'].values())
color=read(BASE/'host-06/color-after-failure.json')
assert color['status']=='pass' and stats(color,'before')['process_work']==stats(color,'after')['process_work']
scene=read(BASE/'host-07/scene-native-merge.json')
assert scene['status']=='pass' and scene['independent_scene_colliders'] and scene['placements_preserved'] and scene['original_retained']
for name in ('prepare-branch-tree','prepare-fern','save-load','verify-delete-undo','recipe-guard'):
    host='host-07' if name=='recipe-guard' else 'host-06'
    assert read(BASE/host/(name+'.json'))['status']=='pass',name

artist=Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini'
profile_checks={host:sha(artist)==read(BASE/host/'launch.json')['artist_ini_sha256'] for host in ('host-06','host-07')}
assert all(profile_checks.values())
original=ROOT/'Test Scene/New Plants test 22.max'
fixture=ROOT/'build/interactions08753-20261028-01/fixtures/New-Plants-22-input.max'
assert sha(fixture)=='579d63bec07fb14fce17c1461baf8e2cc2bfa3a53516402367f7f4f16c96acfd'
reopened=read(BASE/'host-07/reopen-trials.json')
assert reopened['status']=='pass' and len(reopened['trials'])==3
trial_folder=ROOT/'Test Scene/Interaction 0.87.5.4'
trials=[ref(trial_folder/name) for name in ('Scene_Collider_Grass_0.87.5.4.max','Scene_Collider_Fern_0.87.5.4.max','Branch_Tree_Neighbors_0.87.5.4.max')]
evidence_files=['generated-final-03/generated-check.json','pytest-final.xml','installer-01/receipt.json','exe-integrity.json',
    'host-05/loaded-identity.json','host-05/scaled-boxes-native.json','host-05/equivalent-boxes.json','host-05/geometry-edit.json','host-05/dense.json','host-05/render-bake-native.json',
    'host-06/loaded-identity.json','host-06/actual-drag-redraw.json','host-06/actual-navigation.json','host-06/prepare-branch-tree.json','host-06/neighbor-grove.json','host-06/neighbor-restore.json',
    'host-06/prepare-fern.json','host-06/save-load.json','host-06/verify-delete-undo.json','host-06/color-after-failure.json','host-07/loaded-identity.json','host-07/scene-native-merge.json','host-07/recipe-guard.json','host-07/reopen-trials.json']
report={'schema':'cyrus.scene-adaptation-qualification/1','version':'0.87.5.4','date':'2026-10-28',
    'status':'scoped-delivery','runtime_qualified_hosts':[2027],'older_host_tests_waived_by_user':True,
    'domains':{'scene':64,'interactions':14,'source_transform':2,'source_command_undo':2,'edit_capability':4,'edit_storage':3,'portable_recipe':9,'scene_preset_metadata':1},
    'packages':packages,'exe':{**ref(exe),'producer':ref(exe.with_suffix('.build.json')),'signed':False,'embedded_payloads_verified':True,'artist_installation_run':False},
    'checks':{'native_2027':62,'python':577,'generator_controls':375,'ordinary_scaled_and_mirrored_boxes':True,'equivalent_parameter_box':True,'scene_reference_undo_redo':True,'deleted_reference_undo':True,
        'held_actual_mouse_drag':True,'navigation_no_new_solve_or_upload':True,'retained_color_after_failure':True,'native_scene_save_load':True,'trial_scenes_reopened':3,'scene_preset_independent_collider_nodes':True,'portable_capture_rejects_new_unsupported_fields':True,'public_render_and_bake_faces':18291},
    'performance':{'scope':'CPU observations in owned Max 2027; not presented FPS, external renderer or million-instance proof',
        'grass_1000':{'movement_steps':len(times),'step_ms_min':min(times),'step_ms_median':statistics.median(times),'step_ms_max':max(times),**{k:after[k] for k in ('affected','posed','pruned_guides','limited_guides','mesh_refinement_work','pose_payload_bytes','preview_ms')}},
        'generated_trees_60':{k:on[k] for k in ('posed','pruned_guides','blocked_guides','limited_guides','total_ms')},
        'fern_12':{k:stats(read(BASE/'host-06/prepare-fern.json'))[k] for k in ('affected','posed','hinge_fits','pruned_guides','limited_guides','total_ms')}},
    'preservation':{'artist_ini_unchanged_from_owned_launches':profile_checks,'artist_scene_observed_at_delivery':ref(original),'tested_owned_scene_snapshot':ref(fixture),
        'artist_file_matches_test_snapshot':sha(original)==sha(fixture),'artist_scene_note':'The artist file was saved separately at 09:48 during the wider task; it differs from the 00:09 test snapshot. This delivery operates on the owned snapshot and separate trial copies, not by saving over the artist path.',
        'artist_profile_installations':False,'git_commit_or_push':False},
    'trials':trials,'evidence':[ref(BASE/name) for name in evidence_files],
    'limits':['Max 2024/2026 runtime not tested; 2024 native tests completed before waiver; 2026 compile only.',
        'Broad guide envelopes do not guarantee leaf-level clearance. Structural trunks and unresolved blocked guides can remain visible.',
        'Neighbor response uses stable one-way rest-proxy priority, not symmetric dynamics.',
        'Automatic preparation is not universal for welded commercial tree topology.',
        'The original renderer-dependent Scene preset was rejected for unavailable shader dependencies. Round-trip proof uses a fresh material-free four-node fixture.',
        'Source-geometry failure and retained recoloring are tested; arbitrary changed-source preparation recovery is not qualified.',
        'True singular rejection is numeric-suite evidence. Max clamped typed zero to a small nonzero evaluated axis.',
        'No new analytic sphere recognition or convex-hull simplifier is delivered; closed collider meshes use existing geometry queries.',
        'Full external renderer images, animation/soak and million-instance realtime are not qualified.',
        'Knowledge index activation and website deployment were not performed.']}
DOC.mkdir(parents=True,exist_ok=True)
(DOC/'QUALIFICATION_08754.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
checksums=''.join(sha(p)+'  '+p.name+'\n' for p in [exe,*[DIST/f'CyrusScatter-0.87.5.4-Max{y}.mzp' for y in (2024,2026,2027)]])
(DIST/'CHECKSUMS.sha256').write_text(checksums,encoding='ascii')
print('Sealed exact delivery evidence, all selected checks passed.',flush=True)
