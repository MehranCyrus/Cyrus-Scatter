"""Verify and retain scoped 0.1.5 delivery evidence; never launch or install Max."""
from pathlib import Path
import hashlib, json, re, statistics, subprocess, zipfile
root=Path(__file__).resolve().parents[3]
docs=Path(__file__).resolve().parent.parent
run=root/'build/physics-grip-015-20261018-01'
def read(path): return json.loads(path.read_text(encoding='utf-8-sig'))
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def artifact(path): return {'path':path.relative_to(root).as_posix(),'sha256':sha(path),'bytes':path.stat().st_size}
ordinary=read(run/'qualified-docs/receipt.json')
compiled=read(run/'qualified/receipt.json')
fault=read(run/'core-01/receipt.json')
assert not ordinary['faults'] and fault['faults']
assert compiled['source_hashes']==fault['source_hashes']
assert {p for p,h in compiled['source_hashes'].items() if ordinary['source_hashes'][p]!=h}=={'README.md'}
assert compiled['binaries']==ordinary['binaries']
for name,h in ordinary['source_hashes'].items(): assert sha(root/'CyrusPhysicsLab'/name)==h,name
for name,h in ordinary['shared_source_hashes'].items(): assert sha(root/name)==h,name
for name,h in ordinary['binaries'].items(): assert sha(run/'qualified-docs'/name)==h,name
package=read(root/'dist/CyrusPhysicsLab-0.1.5-20261018-02/package.json')
mzp=Path(package['package'])
assert sha(mzp)==package['package_sha256']
with zipfile.ZipFile(mzp) as z:
    assert z.testzip() is None
    manifest=json.loads(z.read('manifest.json'))
    assert manifest['version']=='0.1.5' and manifest['max_year']==2027
    for name,h in manifest['payload'].items(): assert hashlib.sha256(z.read(name)).hexdigest()==h,name
    assert '29000' in z.read('install.ms').decode('utf-8-sig')
    assert hashlib.sha256(z.read('scripts/CyrusPhysicsLab.ms')).hexdigest()==ordinary['source_hashes']['scripts/CyrusPhysicsLab.ms']
host={}
for name in ['grip-host-02','secondary-host-02','lifecycle-host-02','recovery-host-01','fault-host-01','performance-host-01']:
    folder=root/('build/physics-lab-015-'+name)
    assert (folder/'completed.json').exists() and not (folder/'error.txt').exists(),name
    launch=read(folder/'launch.json')
    expected=fault if name.startswith('fault-') else ordinary
    assert launch['script_sha256']==expected['source_hashes']['scripts/CyrusPhysicsLab.ms']
    for module,h in launch['binaries'].items(): assert expected['binaries'][module]==h,name
    host[name]={'launch':launch,'assertions':(folder/'assertions.txt').read_text(),
                'files':[artifact(folder/p) for p in ['launch.json','loaded.tsv','assertions.txt']]}
installer=root/'build/physics-lab-015-installer-02'
installed=read(installer/'installer-receipt.json')
assert installed['pass'] and installed['package_sha256']==sha(mzp)
assert installed['installed_script_sha256']==ordinary['source_hashes']['scripts/CyrusPhysicsLab.ms']
assert 'PASS 57' in (installer/'assertions.txt').read_text() and 'Checks: 98' in (installer/'assertions.txt').read_text()
crashes={}
for kind in ['fatal','hardkill']:
    folder=root/('build/physics-lab-015-'+kind+'-01')
    diagnostic=list((folder/'diagnostics').iterdir());assert len(diagnostic)==1
    diagnostic=diagnostic[0];recovery=read(diagnostic/'live-recovery-0.json')
    # Exact recovery shape is preserved; assert the recorded captured grip.
    assert recovery['core']['input']['settings']['stickiness']>.79
    events=list(diagnostic.glob('events-*.jsonl'));assert events and sum(p.stat().st_size for p in events)>0
    dumps=[]
    for dump in diagnostic.glob('*.dmp'):
        receipt=read(Path(str(dump)+'.json'));assert receipt['dump_written']
        dumps.append({'file':artifact(dump),'receipt':receipt})
    assert bool(dumps)==(kind=='fatal')
    crashes[kind]={'harness':read(folder/'crash-harness.json'),'exit':read(diagnostic/'process-exit.json'),
        'recovery':artifact(diagnostic/'live-recovery-0.json'),'dumps':dumps,
        'attempts':[json.loads(s) for s in (diagnostic/'dump-attempts.jsonl').read_text().splitlines()] if (diagnostic/'dump-attempts.jsonl').exists() else [],
        'events':[artifact(p) for p in events]}
slopes=read(run/'qualified/grip-results.json');leaf=read(run/'native-leaf.json')
assert slopes['pass'] and leaf['pass']
assert leaf['checks']==948 and len(leaf['cases'])==18
leaf_build=read(run/'native-leaf-receipt.json')
assert leaf_build['source_sha256']==sha(Path(__file__).with_name('native_leaf.cpp'))
assert leaf_build['core_lib_sha256']==sha(run/'core-01/cpl_core.lib')
assert leaf_build['executable_sha256']==sha(run/'native-leaf.exe')
parity=read(run/'parity/parity.json');assert parity['pass'] and parity['pairs']==40
stress=[read(run/('stress-'+g+'.json')) for g in ['0','0.8']]
for measured in stress:
    assert [x['bodies'] for x in measured['runs']]==[1000,5000]
    assert all(x['lost']==0 and x['moving']==0 for x in measured['runs'])
latency=read(root/'build/physics-lab-015-performance-host-01/latency.json')
layout=read(root/'build/physics-lab-015-secondary-host-02/ui-layout.json')
assert not any(row['overlaps'] for row in layout)
assert all(control['inside'] and control['glyphs_fit'] for row in layout for control in row['controls'])
assert any(control['text']=='Stickiness (%)' for row in layout for control in row['controls'])
evidence={'date_local':'2026-10-18','version':'0.1.5','host':2027,'scope':'standalone lab only',
    'computer_use':False,'artist_installation':False,'commit_or_push':False,
    'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),
    'knowledge':'stale 29/36 at task start; lab unenrolled; direct source used',
    'ordinary_build':ordinary,'private_fault_build':artifact(run/'core-01/receipt.json'),
    'package':package,'installed_test':installed,'installed_assertions':(installer/'assertions.txt').read_text(),
    'native_checks':{'core':3175,'continuous':413,'grip':1898,'extended_curved_leaf':948,'total':6434},
    'grip_matrix':slopes,'curved_leaf_matrix':leaf,'zero_grip_parity':parity,
    'host_runs':host,'layout':layout,'crashes':crashes,'stress':stress,'scripted_latency':latency,
    'fixtures':[artifact(p) for p in sorted(Path(__file__).parent.glob('*')) if p.is_file()],
    'native_leaf_build':leaf_build,
    'probe':artifact(root/'build/physics-lab-brush-probe-013/CyrusPhysicsProbe.dlx'),
    'limitations':['75-degree rounded-source Finish timed out; retained preview and Freeze verified',
        'Rejected stronger grip variants had severe triangle-contact penetration; not delivered',
        'No physical input, screenshots, presented FPS, production scene or renderer qualification',
        'A later fatal-dump attempt failed; the successful first dump remains'],
    'primary_sources':['https://www.sidefx.com/docs/houdini/nodes/sop/rbdconfigure.html',
        'https://www.sidefx.com/docs/houdini/nodes/sop/rbdbulletsolver.html',
        'https://www.sidefx.com/docs/houdini/destruction/sticky.html',
        'https://jrouwe.github.io/JoltPhysicsDocs/5.6.0/class_contact_listener.html'],
    'guide':artifact(docs/'SURFACE_GRIP_015.md')}
target=docs/'SURFACE_GRIP_015_EVIDENCE.json'
target.write_text(json.dumps(evidence,indent=2)+'\n')
for doc in [docs/'SURFACE_GRIP_015.md',docs/'DOCUMENTATION.md',root/'CyrusPhysicsLab/README.md']:
    for link in re.findall(r'\]\(([^)]+)\)',doc.read_text(encoding='utf-8')):
        if '://' in link or link.startswith('#'):continue
        assert (doc.parent/link.split('#')[0]).resolve().exists(),(doc,link)
print('PASS exact ordinary/source/package/installed identities, scoped receipts and documentation links')
print(target)
