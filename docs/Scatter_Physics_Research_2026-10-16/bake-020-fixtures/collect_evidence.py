"""Collect final exact-pair evidence for standalone Physics Lab 0.2.0."""
from pathlib import Path
import hashlib,json,zipfile,re
ROOT=Path(__file__).resolve().parents[3]
DOCS=Path(__file__).resolve().parent.parent
BUILD=ROOT/'build/physics-bake-020-20261018-01/native'
DIST=ROOT/'dist/CyrusPhysicsLab-0.2.0-20261018-02'
INSTALLED=ROOT/'build/physics-lab-bake-020-installed-02'
MOUNTAIN=INSTALLED
VALIDATION=ROOT/'build/physics-lab-bake-020-final-validation-01'
FAULTS=ROOT/'build/physics-lab-bake-020-faults-02'
UI=ROOT/'build/physics-lab-bake-020-ui-03'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def txt(p):return p.read_text(encoding='utf-8-sig').strip()
def host(folder,restart=False,fault=False):
    assert (folder/('restart-completed.json' if restart else 'completed.json')).exists(),folder
    assert not (folder/('restart-error.txt' if restart else 'error.txt')).exists(),folder
    diagnostics=folder/('restart-diagnostics' if restart else 'diagnostics')
    exits=[read(p) for p in diagnostics.glob('*/process-exit.json')]
    assert exits and all(v['exit_code']==0 and v['exception_notifications']==0 for v in exits),exits
    errors=[];expected=[];events=0;commits=0
    for p in diagnostics.glob('*/events-*.jsonl'):
        for line in p.read_text(encoding='utf-8-sig').splitlines():
            item=json.loads(line);events+=1
            if item['event']=='bake.commit':commits+=1
            if item['event'] in ('live.worker.error','paint.error','scene.notification.error','collision.display.error','source.cook.error'):errors.append(item)
            if item['event']=='live.commit.error':
                message=item['data'].get('message','')
                if fault and 'Injected failure' in message:expected.append(message)
                elif not fault and message.startswith('Bake collider exceeds 200,000'):expected.append(message)
                else:errors.append(item)
    assert not errors,(folder,errors[:2])
    launch=read(folder/'launch.json')
    if not fault:
        assert launch['script_sha256']==sha(ROOT/'CyrusPhysicsLab/scripts/CyrusPhysicsLab.ms')
        for name in ('CyrusPhysicsLab.dlx','CyrusPhysicsStorage.dlh'):assert launch['binaries'][name]==receipt['binaries'][name]
    return {'profile':str(folder.relative_to(ROOT)),'exits':exits,'retained_events':events,'bake_commits':commits,'expected_rejections':expected,'unexpected_errors':0,'launch':launch}
receipt=read(BUILD/'receipt.json')
assert receipt['version']=='0.2.0' and receipt['max_year']==2027 and not receipt['faults']
for name,digest in receipt['source_hashes'].items():assert sha(ROOT/'CyrusPhysicsLab'/name)==digest,name
for name,digest in receipt['shared_source_hashes'].items():assert sha(ROOT/name)==digest,name
for name,digest in receipt['binaries'].items():assert sha(BUILD/name)==digest,name
assert '100% tests passed, 0 tests failed out of 7' in txt(BUILD/'tests.log')
fault_receipt=read(BUILD.parent/'native-faults/private-fault-receipt.json')
assert fault_receipt['faults'] and not fault_receipt['package_allowed']
for name,digest in receipt['source_hashes'].items():
    if Path(name).suffix in ('.cpp','.inc','.h') or name=='CMakeLists.txt':
        assert fault_receipt['source_hashes'][str(Path(name))]==digest,('fault C++ identity',name)

package=DIST/'CyrusPhysicsLab-0.2.0-Max2027.mzp'
with zipfile.ZipFile(package) as archive:
    assert archive.testzip() is None
    manifest=json.loads(archive.read('manifest.json'))
    assert manifest['version']=='0.2.0' and manifest['max_year']==2027
    for name,digest in manifest['payload'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==digest,name
    assert not any('Probe' in n or n.endswith('.pdb') for n in archive.namelist())
    assert b'29000' in archive.read('install.ms')
    assert archive.read('scripts/CyrusPhysicsLab.ms')==(ROOT/'CyrusPhysicsLab/scripts/CyrusPhysicsLab.ms').read_bytes()
installed=read(INSTALLED/'installer-receipt.json');assert installed['package_sha256']==sha(package)
profiles=[host(INSTALLED,True),host(VALIDATION),host(UI),host(FAULTS,fault=True)]
assert int(txt(INSTALLED/'workflow-count.txt'))==56
assert int(txt(INSTALLED/'stack-count.txt'))==68
assert int(txt(FAULTS/'fault-count.txt'))==16
assert txt(MOUNTAIN/'mountain-count.txt').startswith('9 cases;')
assert '0 black pixels' in txt(VALIDATION/'render-counts.txt')
assert all(str(i) in txt(VALIDATION/'mixed-material-ids.txt') for i in (1,2,3))
original=ROOT/'Test Scene/Mountain Scene Brush Test.max'
assert sha(original)=='99ee36fd84f34995ca565aa27ad6292a5b83b46a24ea7cfbe92a7ab87315b28e'
scene=VALIDATION/'PhysicsLab-0.2.0-Mountain-Test.max'
assert scene.exists()
evidence={'pass':True,'version':'0.2.0','date':'2026-10-18','max_year':2027,'computer_use':False,'artist_installation':False,'scatter_integration':False,'preset_changes':False,'build':str(BUILD.relative_to(ROOT)),'receipt':receipt,'package':str(package.relative_to(ROOT)),'package_sha256':sha(package),'package_bytes':package.stat().st_size,'installed':installed,'profiles':profiles,'native_suites':7,'mountain':txt(MOUNTAIN/'mountain-count.txt'),'installed_workflow_assertions':56,'installed_workflow_and_stack_assertions':68,'recovery_assertions':txt(INSTALLED/'recovery-count.txt'),'fault_assertions':16,'scaled_checkbox_assertions':txt(UI/'scaled-checkbox-count.txt'),'reopen_assertions':txt(VALIDATION/'reopen-count.txt'),'render':txt(VALIDATION/'render-counts.txt'),'mixed_assertions':txt(VALIDATION/'mixed-count.txt'),'mixed_material_ids':txt(VALIDATION/'mixed-material-ids.txt'),'artist_scene_reopen_assertions':txt(VALIDATION/'artist-reopen-count.txt'),'stack_height_metres':txt(INSTALLED/'stack-height.txt'),'original_scene_sha256':sha(original),'ready_scene_sha256':sha(scene),'fixtures':{p.name:sha(p) for p in Path(__file__).resolve().parent.iterdir() if p.is_file() and p.name!='collect_evidence.py'},'limits':['200000 combined collider triangles','64 colliders including receiver','Dynamic convex proxies approximate concavities','Finish may reach a finite settle limit; Freeze is explicit','No physical input, screen-pixel or presented-FPS qualification']}
before_shared=read(BUILD/'attempts/receipt-before-shared-change.json')
assert before_shared['binaries']==receipt['binaries']
assert before_shared['source_hashes']==receipt['source_hashes']
assert 'no work to do' in txt(BUILD/'build.log')
evidence['shared_configuration_recheck']={'previous_receipt':'build/physics-bake-020-20261018-01/native/attempts/receipt-before-shared-change.json','before':before_shared['shared_source_hashes'],'after':receipt['shared_source_hashes'],'product_sources_unchanged':True,'product_binaries_unchanged':True,'explicit_max_year':2027,'build_noop':True,'native_suites_passed':7}
(DOCS/'BAKE_WORKFLOW_020_EVIDENCE.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf8')
print('PASS final sources, exact pair, package, native/host/fault/material/mountain/recovery evidence')
