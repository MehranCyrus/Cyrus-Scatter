"""Publish only an accepted frozen local pair to a fresh installer directory.

This copies packages and writes evidence; it never runs either installer.
"""
from pathlib import Path
import hashlib,json,re,shutil,xml.etree.ElementTree as ET,zipfile

ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'build/native-fields-0860-20261018-01'
HOSTS=ROOT/'build/mcp-qualification'
MAIN=HOSTS/'foundation-memory0854-nativeaccept-controller-20261018-20'
SOAK=HOSTS/'foundation-memory0854-nativeaccept-controller-20261018-21'
EXTRA=HOSTS/'foundation-memory0854-nativeaccept-controller-20261018-22'
FAULT=HOSTS/'foundation-memory0854-nativegenerate-hold-20261018-11'
DEST=ROOT/'dist/CyrusScatter-0.86.0-20261018'
DOC=ROOT/'docs/plans/native-placement'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
assert not DEST.exists() and not (DOC/'QUALIFICATION_0860.json').exists()
normal=read(BASE/'native-11/receipt.json');fault=read(BASE/'fault-11/receipt.json')
for label,receipt in [('native-11',normal),('fault-11',fault)]:
    assert receipt['max_year']==2027 and all(s['exit_code']==0 for s in receipt['stages'])
    assert '100% tests passed, 0 tests failed out of 44' in (BASE/label/'tests.log').read_text()
    for name,expected in receipt['sources'].items():assert sha(ROOT/name)==expected,name
    for name,expected in receipt['binaries'].items():assert sha(ROOT/name)==expected,name
assert not normal.get('placement_qualification') and fault.get('placement_qualification')
for path in (BASE/'native-11').glob('*.dl*'):
    data=path.read_bytes()
    for encoding in ('ascii','utf-16-le'):
        assert 'cyrusOwnedNativeFault'.encode(encoding) not in data,path
suite=ET.parse(BASE/'python-final.xml').getroot()
assert sum(int(s.get('tests','0')) for s in suite.findall('testsuite'))==168
assert all(int(s.get('failures','0'))==0 and int(s.get('errors','0'))==0 for s in suite.findall('testsuite'))
steps={}
for name in ('capacity','lifecycle','retention','goldens','controller','edit','fields','presets','outputs','render'):
    steps[name]=read(MAIN/f'final-{name}.json');assert steps[name]['status']=='passed',name
steps['preparation']=read(MAIN/'final-preparation-recheck.json');assert steps['preparation']['status']=='passed'
soak=read(SOAK/'native-soak.json')
assert soak['status']=='passed' and soak['seconds']>=3600 and len(soak['cycles'])>=60
assert soak['fixture_sha256']==sha(ROOT/'tools/native_placement/soak.ms')
for name in ('saved-counts.json','saved-benchmark.json','physical-ui-100.json'):
    assert read(EXTRA/name)['status']=='passed',name
edits=read(EXTRA/'large-edit.json');assert [s['count'] for s in edits]==[500000,1000000] and all(s['status']=='passed' for s in edits)
ui=read(EXTRA/'physical-ui.json');assert ui['configured_scale']==1.5 and len(ui['actual_input'])==5
assert (EXTRA/'native-ui-passive.txt').read_text().startswith('PASS configured scale=1.5')
assert 'PASS subsequent render/update/reset' in (EXTRA/'production-cancel.txt').read_text()
assert 'PASS final release bytes=#(0L' in (FAULT/'native-failures.txt').read_text()
package=BASE/'package-11';candidate=read(package/'candidate.json')
assert candidate['script_sha256']==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
mzp=package/'CyrusScatter-0.86.0-Max2027.mzp';exe=package/'CyrusScatter-0.86.0-Max2027-Setup.exe'
assert sha(mzp)==candidate['mzp_sha256'] and sha(exe)==candidate['exe_sha256']
embedded=read(package/'embedded-payload.json')
assert embedded['status']=='passed' and not embedded['executed_installer'] and embedded['embedded_payload_sha256']==sha(mzp)
with zipfile.ZipFile(mzp) as z:
    assert z.testzip() is None
    manifest=json.loads(z.read('manifest.json'));assert set(z.namelist())==set(manifest['files'])|{'manifest.json'}
    for name,digest in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest,name
    assert b'29000' in z.read('install.ms') and b'0.86.0' in z.read('install.ms')
launches={h.name:read(h/'launch.json') for h in (MAIN,SOAK,EXTRA,FAULT)}
for h in (MAIN,SOAK,EXTRA):assert launches[h.name]['script_sha256']==candidate['script_sha256']
evidence={}
for h in (MAIN,SOAK,EXTRA,FAULT):
    for pattern in ('final-*.json','native-*.txt','native-*.tsv','native-soak.json','large-edit.json','physical-ui*.json','saved-*.json','production-cancel*.txt','production-cancel*.json','corona072-result.json'):
        for path in h.glob(pattern):evidence[path.relative_to(ROOT).as_posix()]=sha(path)
for path in (BASE/'python-final.xml',BASE/'generated-11/generated-check.json',BASE/'native-11/receipt.json',BASE/'fault-11/receipt.json',BASE/'performance-final.json'):
    evidence[path.relative_to(ROOT).as_posix()]=sha(path)
qualification={'schema':'cyrus.native-delivery/1','status':'scoped-qualified','version':'0.86.0','max_year':2027,
    'script_sha256':candidate['script_sha256'],'native_build':normal,'fault_build':fault,
    'tests':{'normal_native':44,'fault_native':44,'python':168,'frozen_scenes':50,'matrix':steps,
             'soak_seconds':soak['seconds'],'soak_cycles':len(soak['cycles'])},
    'performance':read(BASE/'performance-final.json'),'launches':launches,'evidence_sha256':evidence,
    'limits':['Private Max 2027 profiles only; no artist installation/restart.',
              'One-hour bounded history soak; not arbitrary lifetime or actual OS exhaustion certification.',
              'Corona 15 lifecycle and production Stop; not every renderer family or image-quality acceptance.',
              '100/150 percent process UI scale; no physical 4K mixed-monitor or presented FPS claim.',
              'Synchronous scatter/Bake work remains; one-million work cap unchanged.',
              'Historical failed candidates and fixture corrections retain their failed evidence.']}
package_record={'schema':'cyrus.package-delivery/1','version':'0.86.0','max_year':2027,'installed':False,
    'mzp':{'path':(DEST/mzp.name).relative_to(ROOT).as_posix(),'sha256':sha(mzp),'bytes':mzp.stat().st_size},
    'exe':{'path':(DEST/exe.name).relative_to(ROOT).as_posix(),'sha256':sha(exe),'bytes':exe.stat().st_size,'signed':False},
    'embedded_payload':embedded,'manifest':manifest,
    'limits':'Archive/static payload checks and exact-pair private-host tests. These installers were not executed; historical installer-core tests retain their own scope.'}
DEST.mkdir(parents=True)
for path in (mzp,exe):shutil.copy2(path,DEST/path.name);assert sha(path)==sha(DEST/path.name)
for name,record in [('QUALIFICATION_0860.json',qualification),('PACKAGE_0860.json',package_record)]:
    (DOC/name).write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
    shutil.copy2(DOC/name,DEST/name)
(DEST/'INSTALL_AND_TEST.txt').write_text('Cyrus Scatter 0.86.0 for 3ds Max 2027\n\nSave your scene. In Max choose Scripting > Run Script and select CyrusScatter-0.86.0-Max2027.mzp, then restart Max. Alternatively run the companion unsigned EXE; use one route. Neither installer has been run by this task.\n\nSee docs/plans/native-placement/DELIVERY_0860.md for tests, exact identities and remaining limits.\n',encoding='utf-8')
print('ACCEPTED INSTALLERS READY: '+str(DEST))
