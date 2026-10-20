"""Verify exact final Lab inputs, archive, host exits and authored-slot witnesses."""
from pathlib import Path
import json,hashlib,zipfile,subprocess

ROOT=Path(__file__).resolve().parents[3]
PROJECT=ROOT/'CyrusPhysicsLab'
BUILD=ROOT/'build/physics-repair-019-20261018-01/native-01'
HOST=ROOT/'build/physics-lab-repair-019-all-04'
INSTALLED=ROOT/'build/physics-lab-repair-019-installed-03'
REOPEN=ROOT/'build/physics-lab-repair-019-reopen-02'
DIST=ROOT/'dist/CyrusPhysicsLab-0.1.9-20261018-06'
REPORT=Path(__file__).resolve().parent.parent/'STABILITY_UI_019_EVIDENCE.json'

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def text(p):return p.read_text(encoding='utf-8-sig').strip()
def checked_host(folder,diagnostics='diagnostics',restart=False):
    completion='restart-completed.json' if restart else 'completed.json'
    error='restart-error.txt' if restart else 'error.txt'
    assert (folder/completion).exists(),(folder,completion)
    assert not (folder/error).exists(),(folder,error)
    exits=[read(p) for p in (folder/diagnostics).glob('*/process-exit.json')]
    assert exits and all(p['exit_code']==0 and p['exception_notifications']==0 for p in exits),exits
    unexpected=[];expected_preflight=[];events=0
    for p in (folder/diagnostics).glob('*/events-*.jsonl'):
        for line in p.read_text().splitlines():
            d=json.loads(line);events+=1
            if d['event'] in ('live.worker.error','paint.error','scene.notification.error','collision.display.error'):unexpected.append(d)
            if d['event']=='source.cook.error':expected_preflight.append(d['data'])
    assert not unexpected,(folder,unexpected[:3])
    if folder!=INSTALLED:assert not expected_preflight,(folder,expected_preflight)
    else:assert all(v.get('model')=='Guard_Teapot_019' for v in expected_preflight),expected_preflight
    return {'completion':completion,'exits':exits,'retained_events':events,'unexpected_errors':0,'expected_invalid_source_preflights':len(expected_preflight)}

def main():
    build=read(BUILD/'receipt.json')
    assert build['version']=='0.1.9' and build['max_year']==2027 and not build['faults']
    for name,digest in build['source_hashes'].items():assert sha(PROJECT/name)==digest,name
    for name,digest in build['shared_source_hashes'].items():assert sha(ROOT/name)==digest,name
    for name,digest in build['binaries'].items():assert sha(BUILD/name)==digest,name
    assert '100% tests passed, 0 tests failed out of 7' in text(BUILD/'tests.log')
    native_hulls=read(BUILD/'hull-results.json');assert native_hulls['pass'] and native_hulls['legacy_rejected_pieces']==4
    package=DIST/'CyrusPhysicsLab-0.1.9-Max2027.mzp'
    with zipfile.ZipFile(package) as archive:
        assert archive.testzip() is None
        manifest=json.loads(archive.read('manifest.json'))
        assert manifest['version']=='0.1.9' and manifest['max_year']==2027
        for name,digest in manifest['payload'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==digest,name
        assert not any('Probe' in name or name.endswith('.pdb') for name in archive.namelist())
        assert archive.read('scripts/CyrusPhysicsLab.ms')==(PROJECT/'scripts/CyrusPhysicsLab.ms').read_bytes()
        assert b'29000' in archive.read('install.ms')
    installed=read(INSTALLED/'installer-receipt.json')
    hosts={HOST.name:checked_host(HOST),INSTALLED.name:checked_host(INSTALLED,installed.get('restart_diagnostics','restart-diagnostics'),True),REOPEN.name:checked_host(REOPEN)}
    for folder in (HOST,REOPEN):
        launch=read(folder/'launch.json')
        assert launch['script_sha256']==sha(PROJECT/'scripts/CyrusPhysicsLab.ms')
        for name in ('CyrusPhysicsLab.dlx','CyrusPhysicsStorage.dlh'):
            assert launch['binaries'][name]==build['binaries'][name]
        profile=Path.home()/'AppData/Local/Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini'
        assert sha(profile)==launch['profile_template_sha256'],'Normal profile changed; review concurrent activity'
    assert installed['pass'] and installed['package_sha256']==sha(package)
    assert installed['installed_script_sha256']==sha(PROJECT/'scripts/CyrusPhysicsLab.ms')
    for name,v in installed['installed_pair'].items():assert v['sha256']==build['binaries'][name]
    cases=sorted(HOST.glob('artist-case-*.json'));assert len(cases)==27
    assert all(read(p)['error']=='' for p in cases)
    assert len(list(HOST.glob('*_q*-result.json')))==9
    order=read(HOST/'order-sphere-result.json');assert {v['source'] for v in order['rows']}=={1}
    assert len(order['input']['sources'][1]['render']['vertices'])==482
    reopened_order=read(REOPEN/'reopened-order.json');assert reopened_order['rows']==order['rows']
    mixed=read(REOPEN/'reopened-order-mixed.json');assert {v['source'] for v in mixed['rows']}=={0,1}
    assert len(mixed['input']['sources'][0]['render']['vertices'])==8
    retired=read(HOST/'palette-final-result.json');assert read(REOPEN/'reopened-retired.json')['rows']==retired['rows']
    reclaimed=read(HOST/'reclaimed-result.json');assert len(reclaimed['input']['sources'][0]['render']['vertices'])==482
    assert all(len(s['render']['vertices'])==8 and s['weight']==0 for s in reclaimed['input']['sources'][1:])
    popup=[]
    for p in sorted(INSTALLED.glob('popup-[0-9]*.json')):
        data=read(p);assert len(data)==3
        for row in data:
            assert row['actual_logical_width']>=96
            assert row['items']==3 and row['popup_rect'][3]-row['popup_rect'][1]>=row['collapsed_height']+3*row['item_height']+2
        assert min(row['actual_logical_width'] for row in data)<=150
        assert max(row['actual_logical_width'] for row in data)>=175
        popup.append({'file':p.name,'data':data})
    assert len(popup)==2
    replay=read(ROOT/'build/physics-repair-019-20261018-01/replay-04/receipt.json')
    assert replay['core_library_sha256']==sha(BUILD/'cpl_core.lib')
    assert replay['no_interior_tunnels'] and len(replay['cases'])==12
    original=ROOT/'Test Scene/Mountain Scene Brush Test.max'
    assert sha(original)=='99ee36fd84f34995ca565aa27ad6292a5b83b46a24ea7cfbe92a7ab87315b28e'
    statements={}
    for folder,names in [(HOST,['artist-assertions.txt','mountain-assertions.txt','order-assertions.txt']),(INSTALLED,['continuous-assertions.txt','installed-assertions.txt']),(REOPEN,['assertions.txt','reopen-assertions.txt'])]:
        statements[folder.name]={name:text(folder/name) for name in names}
    scenes={name:{'sha256':sha(HOST/name),'bytes':(HOST/name).stat().st_size} for name in ('PhysicsLab-0.1.9-Mountain-Test.max','palette-retired.max','order-persist.max')}
    report={'pass':True,'version':'0.1.9','max_year':2027,'computer_use':False,'normal_profile_modified':False,'scatter_integrated':False,
        'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),
        'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        'build_receipt_sha256':sha(BUILD/'receipt.json'),'native_binaries':build['binaries'],
        'script_sha256':sha(PROJECT/'scripts/CyrusPhysicsLab.ms'),'package':str(package),'package_sha256':sha(package),
        'native_hulls':native_hulls,'hosts':hosts,'statements':statements,'popup_checks':popup,'scenes':scenes,
        'replay':replay,'original_scene_preserved':True,'source_slot_order_sphere_only':True,'reopened_order_both_models':True,
        'reopened_rows_exact':True,'unused_retired_geometry_reclaimed':True,
        'fixture_hashes':{p.name:sha(p) for p in Path(__file__).parent.iterdir() if p.is_file()},
        'limits':['Physical input/pixels/mixed-monitor DPI/FPS not qualified.','V-HACD approximation/16-piece hole limits remain.','Freeze can retain moving-body overlaps; arbitrary settling is not guaranteed.']}
    REPORT.write_text(json.dumps(report,indent=2)+'\n')
    print('PASS final exact source/pair/package, owned exits, ordering, persistence, popup and replay evidence')

if __name__=='__main__':main()
