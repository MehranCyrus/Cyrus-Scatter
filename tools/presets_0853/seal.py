"""Seal the final exact-pair preset delivery after all declared host gates."""
from pathlib import Path
import ast,hashlib,json,re,shutil,zipfile
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/presets-0853-20261016-01';DOC=ROOT/'docs/plans/preset-gallery-improvements'
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def record(path):return {'path':path.relative_to(ROOT).as_posix(),'sha256':sha(path)}
def passed(path):
    text=path.read_text(encoding='utf-8-sig');assert 'PASS: complete' in text and 'FAIL:' not in text,(path,text);return record(path)
native=BASE/'native-04';receipt=read(native/'receipt.json')
assert receipt['max_year']==2027 and all(s['exit_code']==0 for s in receipt['stages'])
for name,digest in {**receipt['sources'],**receipt['binaries']}.items():assert sha(ROOT/name)==digest,name
producer=ROOT/'build/mcp-qualification/foundation-presets0853-qualified-20261016-01'
host=ROOT/'build/mcp-qualification/foundation-presets0853-final-timing-20261016-02'
recipient=ROOT/'build/mcp-qualification/foundation-presets0853-recipient-e8186a8b'
ids=('meadow','woodland','mountain','borders','orchard','hexagonal','formal','valley')
phases=('setup','load','verify','undo','verifyUndo','redo','verifyRedo','reopen','verifyReopen')
acceptance=[passed(host/f'acceptance-{identity}-{phase}.txt') for identity in ids for phase in phases]
recipient_checks=[passed(recipient/f'acceptance-{identity}-{phase}.txt') for identity in ('borders','valley') for phase in phases]
workflow=[]
for phase in ('setup','galleryLoad','preserved','undo','checkUndo','redo','checkRedo','save','checkSave','loadSaved','checkSaved','cancel','fault','checkFault'):
    paths=sorted(host.glob('workflow-*-'+phase+'.txt'),key=lambda p:p.stat().st_mtime);assert paths,phase;workflow.append(passed(paths[-1]))
extras=[passed(host/f'extra-{phase}.txt') for phase in ('capacity','checkCapacity','revise','checkRevision','liveLoad','checkLive','closeAfterAddStart','closeAfterAddFinish','idleStart','browse','idleCheck')]
terrain=[passed(recipient/f'terrain-{phase}.txt') for phase in ('missing','checkMissing','settled','valid','checkValid','liveCount','checkLiveCount')]
assert (recipient/'mzp-wrapper-passed.txt').is_file() and (recipient/'actual-click-load-final.txt').is_file()
assert read(recipient/'result.json')['status']=='passed'
script=ROOT/'AminScatter/scripts/AminScatterObject.ms';script_hash=sha(script)
for profile in (host,recipient):
    launch=read(profile/'launch.json');assert launch['max_year']==2027 and launch['script_sha256']==script_hash
    assert (profile/'closed-owned-session.txt').is_file()
layouts=[]
for name,scale in (('foundation-presets0853-scale150-20261016-01','1.5'),('foundation-presets0853-recipient-af636a31','1.0')):
    profile=ROOT/'build/mcp-qualification'/name
    for owner in (0,1):
        path=profile/f'layout-settled-{scale}-{owner}-observe.json';data=read(path)
        assert data['status']=='passed' and data['clipped_count']==data['overlap_count']==0 and len(data['pages'])==12
        layouts.append(record(path))
    for size in ('1000x680','850x620'):
        assert read(profile/f'library-{size}.json')['status']=='passed'
candidate=read(BASE/'package-04/candidate.json');manifest=candidate['manifest']
mzp=BASE/'package-04/CyrusScatter-0.85.3-Max2027.mzp';exe=mzp.with_name('CyrusScatter-0.85.3-Max2027-Setup.exe')
assert sha(mzp)==candidate['mzp_sha256'] and sha(exe)==candidate['exe_sha256']
assert candidate['script_sha256']==script_hash and manifest['files']['CyrusScatter.ms']==script_hash
with zipfile.ZipFile(mzp) as archive:
    assert archive.testzip() is None and set(archive.namelist())==set(manifest['files'])|{'manifest.json'}
    for name,digest in manifest['files'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==digest,name
    assert b'29000' in archive.read('install.ms') and b'0.85.3' in archive.read('install.ms')
for name,digest in receipt['binaries'].items():assert manifest['files'][Path(name).name]==digest
assert read(recipient/'launch.json')['package_sha256']==sha(mzp)
assert read(recipient/'result.json')['executable_sha256']==sha(exe)
inventory=read(ROOT/'AminScatter/library/inventory.json');assert inventory['version']=='0.85.3' and len(inventory['entries'])==8
baseline=read(BASE/'library-baseline.json')
for name,digest in baseline.items():
    if name.endswith('.max'):assert sha(ROOT/'AminScatter/library'/name)==digest
dest=ROOT/'dist/CyrusScatter-0.85.3-20261016';dest.mkdir(exist_ok=True)
artifacts=[]
for source in (mzp,exe):
    target=dest/source.name
    if target.exists():assert sha(target)==sha(source)
    else:shutil.copy2(source,target)
    artifacts.append({**record(target),'bytes':target.stat().st_size})
(dest/'CyrusScatter-0.85.3-Max2027.sha256').write_text(''.join(f"{item['sha256']}  {Path(item['path']).name}\n" for item in artifacts))
package={'version':'0.85.3','max_year':2027,'signed':False,'artist_profile_installed':False,'artifacts':artifacts,'payload_manifest':manifest,'native_receipt':record(native/'receipt.json'),'qualified_script_sha256':script_hash,'library_inventory':record(ROOT/'AminScatter/library/inventory.json'),'owned_actual_exe_and_mzp':'passed'}
(DOC/'PACKAGE_0853.json').write_text(json.dumps(package,indent=2)+'\n')
fixtures=list((ROOT/'tools/presets_0853').glob('*.py'))
for path in fixtures:ast.parse(path.read_text(encoding='utf-8-sig'),filename=str(path))
qualification={'version':'0.85.3','status':'passed for the bounded ready-preset delivery','baseline_commit':'5aee4ef2242307b92e16c96e0106ee095d6a4215','branch':'codex/workflow-0.75','max_year':2027,'script_sha256':script_hash,'native_receipt':record(native/'receipt.json'),'native_inputs_rehashed':len(receipt['sources']),'native_suites':39,'native_test_log':record(native/'tests.log'),'python_tests':167,'python_result':'167 passed in 14.06 s; terminal result observed, raw pytest log not retained','generated':record(BASE/'generated-final-timing/generated-check.json'),'asset_capture_producer':record(producer/'launch.json'),'asset_captures':[record(producer/f'library-{i}-capture.json') for i in ids],'final_host':record(host/'launch.json'),'recipient':record(recipient/'launch.json'),'acceptance':acceptance,'workflow':workflow,'extra':extras,'installed_acceptance':recipient_checks,'terrain_and_single_live_solve':terrain,'exe_handler':record(recipient/'result.json'),'mzp_wrapper':record(recipient/'mzp-wrapper-passed.txt'),'actual_pointer_load':record(recipient/'actual-click-load-final.txt'),'layout_predecessor_checks':layouts,'layout_scope':'48 settled page/owner layouts at default and configured 150%; native/C#/main-panel code unchanged by final ready-command timing correction; final installed 150% Load/Save visually inspected','idle_seconds':float(re.search(r'SECONDS: ([0-9.]+)',(host/'extra-idleCheck.txt').read_text()).group(1)),'notification_failure_predecessor':record(BASE/'notification-predecessor/terrain-settled.txt'),'screenshots':[record(BASE/name) for name in ('ready-load-final-150.png','ready-save-final-150.png','modify-navigation-default.png')],'fixtures':{p.relative_to(ROOT).as_posix():sha(p) for p in fixtures},'limitations':['Static mesh/Standard-Blinn/static-PNG adapter; unsupported shaders/proxies/XRefs/animation and authored Edit/radius codecs remain open','Included terrain is an evaluated snapshot; arbitrary-terrain Paint reprojection is not implemented','Per-layer viewport budget share redistributes; explicit Load + Update applies pending Manual edits','Configured DPI/layout and pointer checks are not physical 4K/mixed-monitor or tablet qualification','No new production-renderer, huge-asset, full-disk/ACL/network or general B26 heavy-session qualification','Normal artist profile not installed or restarted; no Git push or website publication in this task']}
(DOC/'QUALIFICATION_0853.json').write_text(json.dumps(qualification,indent=2)+'\n')
print('Sealed',dest,'script',script_hash,'with',len(acceptance),'final host lifecycle phases')
