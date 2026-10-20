"""Validate the exact 0.1.6 delivery receipts and publish a bounded evidence index."""
from pathlib import Path
import hashlib,json,re,subprocess,zipfile
root=Path(__file__).resolve().parents[3]
run=root/'build/physics-settling-016-20261018-01'
native=run/'native-01'
host=root/'build/physics-lab-016-installer-02'
layout=root/'build/physics-lab-016-layout150-02'
package=root/'dist/CyrusPhysicsLab-0.1.6-20261018-01/CyrusPhysicsLab-0.1.6-Max2027.mzp'
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
receipt=read(native/'receipt.json')
assert receipt['version']=='0.1.6' and receipt['max_year']==2027 and not receipt['faults']
for path,h in receipt['source_hashes'].items():assert digest(root/'CyrusPhysicsLab'/path)==h,path
for path,h in receipt['shared_source_hashes'].items():assert digest(root/path)==h,path
for path,h in receipt['binaries'].items():assert digest(native/path)==h,path
tests=(native/'Testing/Temporary/LastTest.log').read_text(encoding='utf-8')
assert tests.count('Test Passed.')==4 and 'Test Failed.' not in tests
native_checks=sum(int(n) for n in re.findall(r'PASS (\d+) ',tests))
assert native_checks==6065
assert (host/'restart-completed.json').exists() and not (host/'restart-error.txt').exists()
assert (layout/'completed.json').exists() and not (layout/'error.txt').exists()
installed=read(host/'installer-receipt.json')
assert installed['pass'] and not installed['computer_use'] and not installed['normal_profile_modified']
assert installed['package_sha256']==digest(package)
assert installed['installed_script_sha256']==receipt['source_hashes']['scripts/CyrusPhysicsLab.ms']
for name,item in installed['installed_pair'].items():
    assert item['sha256']==receipt['binaries'][name] and digest(Path(item['path']))==item['sha256']
host_reports={name:(host/(name+'-installed-assertions.txt')).read_text(encoding='utf-8') for name in ('continuous','collision','terrain')}
assert all('PASS' in text for text in host_reports.values())
for folder in (host,layout):
    launch=read(folder/'launch.json')
    for name,h in launch['binaries'].items():assert h==receipt['binaries'][name]
    assert launch['script_sha256']==receipt['source_hashes']['scripts/CyrusPhysicsLab.ms']
    assert launch['computer_use'] is False and launch['normal_profile_modified'] is False
layouts={}
for folder in (host,layout):
    rows=read(folder/'ui-layout.json')
    assert all(row['controls'] and not row['overlaps'] for row in rows)
    assert all(c['inside'] and c['glyphs_fit'] for row in rows for c in row['controls'])
    layouts[folder.name]={'scale':rows[0]['scale'],'controls':sum(len(row['controls']) for row in rows),'all_bounds_fonts_overlaps_pass':True}
diagnostic=read(layout/'diagnostic-status.json')
assert diagnostic['recording'] and diagnostic['watcher_alive'] and diagnostic['version']=='0.1.6'
compare=read(run/'compare-replay-receipt.json')
assert compare['pass'] and compare['016']['core_lib_sha256']==digest(native/'cpl_core.lib')
snapshot=run/'artist-snapshot-01'
inputs=[]
for n in (0,1):
    path=snapshot/f'context-{n}.json';data=read(path)['prepared']['input']
    def span(points):return [max(p[i] for p in points)-min(p[i] for p in points) for i in range(3)]
    inputs.append({'context_sha256':digest(path),'friction':data['settings']['friction'],'stickiness':data['settings']['stickiness'],'render_span_m':span(data['sources'][0]['render']['vertices']),'hull_span_m':span(data['sources'][0]['hulls'][0]),'static_collider_count':len(data['colliders'])})
with zipfile.ZipFile(package) as z:
    assert z.testzip() is None;manifest=json.loads(z.read('manifest.json'))
    assert manifest['version']=='0.1.6' and manifest['max_year']==2027
    for path,h in manifest['payload'].items():assert hashlib.sha256(z.read(path)).hexdigest()==h,path
    for name in ('CyrusPhysicsLab.dlx','CyrusPhysicsStorage.dlh','CyrusPhysicsCrashWatch.exe'):
        assert manifest['payload']['native/'+name]==receipt['binaries'][name]
    assert manifest['payload']['scripts/CyrusPhysicsLab.ms']==receipt['source_hashes']['scripts/CyrusPhysicsLab.ms']
    install=z.read('install.ms').decode('utf-8-sig');assert '29000' in install and 'requires Max 2027' in install
evidence={'version':'0.1.6','date':'2026-10-18','scope':'standalone Physics Lab; no main Scatter integration, Computer Use, artist installation, commit or push',
 'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),
 'knowledge':{'source_verification_requested':True,'generation':'70c3934732cfdcec5c56ac5b5cef3b261a25491cce8826b38198a8a42a3e3100','status':'stale; Physics Lab not enrolled; direct source and fresh receipts used; no refresh'},
 'build':receipt,'native_checks':native_checks,'collision_results':read(native/'collision-results.json'),
 'grip_summary':{k:v for k,v in read(native/'grip-results.json').items() if k not in ('slopes','terrains')},
 'artist_inputs':inputs,'comparison':compare,'host_reports':host_reports,'layouts':layouts,
 'crash_recording':diagnostic,'installed_receipt':installed,'package':{'path':str(package.relative_to(root)),'sha256':digest(package),'bytes':package.stat().st_size,'archive_integrity':True,'payload_hashes':manifest['payload'],'installed_into_owned_profile_only':True},
 'limitations':['Physical pointer input and presented FPS not tested','Transient small-sphere impact overlap reached 3.225 mm; settled overlap below 0.001 mm in native fixture','Jolt/grip code unchanged; steeper-slope settling limit from 0.1.5 remains','Old pending sessions retain preview; exact-build replay guard remains','Finite surfaces have no invisible edge walls'],
 'primary_reference':'https://jrouwe.github.io/JoltPhysics/struct_physics_settings.html'}
paths=[native/'receipt.json',native/'Testing/Temporary/LastTest.log',native/'collision-results.json',native/'grip-results.json',run/'compare-replay-receipt.json',host/'launch.json',host/'installer-receipt.json',host/'restart-loaded.tsv',host/'restart-completed.json',host/'assertions.txt',host/'ui-layout.json',layout/'launch.json',layout/'completed.json',layout/'ui-layout.json',layout/'diagnostic-status.json']
evidence['receipts']={str(p.relative_to(root)):digest(p) for p in paths}
evidence['fixture_hashes']={str(p.relative_to(root)):digest(p) for p in Path(__file__).parent.iterdir() if p.is_file()}
target=Path(__file__).parent.parent/'COLLISION_BINDINGS_016_EVIDENCE.json'
target.write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'pass':True,'native_checks':native_checks,'host_reports':host_reports,'layouts':layouts,'package_sha256':digest(package)},indent=2))
