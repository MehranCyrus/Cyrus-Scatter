"""Verify the exact tested pair and preserve bounded, durable review evidence."""
from pathlib import Path
import hashlib,json,os,shutil,statistics,sys,zipfile

ROOT=Path(__file__).resolve().parents[3]
RUN=ROOT/'build/interaction-review-08763-20261029-01'
DOC=ROOT/'docs/plans/interaction-review-08763-20261029'
OUT=ROOT/'dist/CyrusScatter-0.87.6.3-20261029'
sys.path[:0]=[str(ROOT/'tools'),str(ROOT/'AminScatter/tools')]
import build_max

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,d):p.write_text(json.dumps(d,indent=2)+'\n',encoding='utf-8')

names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
native=RUN/'native-2027';payload=RUN/'payload-2027';host=RUN/'host-01'
receipt=build_max.verify_native_receipt(native/'receipt.json','AminScatter',2027,{n:native/n for n in names})
generated=read(RUN/'generated/generated-check.json')
assert generated['passed'] and generated['development_version']=='0.87.6.3'
assert generated['generated_sha256']==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
assert '100% tests passed, 0 tests failed out of 62' in (native/'tests.log').read_text()
loaded=read(host/'loaded-identity.json');launch=read(host/'launch.json')
assert loaded['host']==2027
for n in names:
    assert loaded['modules'][n]['sha256']==sha(native/n)==sha(payload/n)==launch['payload'][n]
    assert Path(loaded['modules'][n]['path']).resolve()==(payload/n).resolve()
assert launch['payload']['CyrusScatter.ms']==generated['generated_sha256']
artist=Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini'
assert sha(artist)==launch['artist_ini_sha256'],'Artist profile changed; investigate before claiming preservation'

for n in ('smoke.json','host-regressions.json','garden-pick.json','navigation.json','posed-pick.json','garden-drag.json'):
    assert read(host/n)['status']=='complete',n
regressions=read(host/'host-regressions.json');drag=read(host/'garden-drag.json')
assert drag['verification']=='passed'
assert len(regressions['roles'])==5 and len(regressions['hiding'])==8 and len(regressions['budgets'])==5
assert 'COMPLETE' in (host/'persistence-events.txt').read_text() and 'ERROR' not in (host/'persistence-events.txt').read_text()
probe=read(RUN/'probes/probe-results.json');assert all(x['exit_code']==0 for x in probe.values())
garden=read(host/'garden-pick.json');nav=read(host/'navigation.json');posed=read(host/'posed-pick.json')
assert garden['epochs_before']==garden['epochs_after'] and garden['streams_before']==garden['streams_after']
assert posed['unchanged_epoch_streams']

package=RUN/'packages/CyrusScatter-0.87.6.3-Max2027.mzp'
with zipfile.ZipFile(package) as z:
    assert z.testzip() is None
    manifest=json.loads(z.read('manifest.json'))
    assert manifest['version']=='0.87.6.3' and manifest['max_year']==2027
    assert set(z.namelist())==set(manifest['files'])|{'manifest.json'}
    for name,digest in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest,name
    assert b'29000' in z.read('install.ms') and b'__MAX_' not in z.read('install.ms')
    for name in names+['CyrusScatter.ms','CyrusGallery.dll','CyrusInstaller.dll']:
        assert hashlib.sha256(z.read(name)).hexdigest()==sha(payload/name)
    assert hashlib.sha256(z.read('CyrusScatter.ms')).hexdigest()==generated['generated_sha256']

evidence=DOC/'evidence';evidence.mkdir(exist_ok=True)
files={
    'native-tests.log':native/'tests.log',
    'generated-check.json':RUN/'generated/generated-check.json',
    'probe-results.json':RUN/'probes/probe-results.json',
    'baseline-probe-recheck.json':ROOT/'build/review-followup-08762-20261029-01/probe-recheck.json',
    'review-original.md':ROOT/'build/review-system-20261029-01/REVIEW.md',
    **{n:host/n for n in ('loaded-identity.json','smoke.json','host-regressions.json','garden-pick.json','navigation.json','posed-pick.json','garden-drag.json','persistence-events.txt')}
}
for name,source in files.items():shutil.copy2(source,evidence/name)
write(evidence/'native-source-hashes.json',read(native/'receipt.json')['sources'])
write(evidence/'package-manifest.json',manifest)
write(evidence/'driver-hashes.json',{p.relative_to(ROOT).as_posix():sha(p) for p in (ROOT/'tools/procedural_lab/review08763').glob('*') if p.is_file()})

series={}
for mode in ('edit','scene','orbit'):
    rows=[x for x in drag['samples'] if x['mode']==mode]
    series[mode]=dict(samples=len(rows),median_cpu_submit_ms=statistics.median(x['submit_ms'] for x in rows),
                     presented_tickets=len(set(x['frame'][2] for x in rows)),
                     first_work=rows[0]['stats']['process_work'],last_work=rows[-1]['stats']['process_work'])
    if mode!='orbit':series[mode]['median_native_fit_ms']=statistics.median(x['stats']['fit_ms'] for x in rows)
verification=dict(status='passed',version='0.87.6.3',max_year=2027,sha256=sha(package),bytes=package.stat().st_size,
                  native_receipt_sha256=sha(native/'receipt.json'),payload={n:sha(payload/n) for n in names+['CyrusScatter.ms','CyrusGallery.dll','CyrusInstaller.dll']},
                  archive_integrity=True,manifest_hashes=True,host_guard=True,source_receipt_verified=True,loaded_payload_matches=True,
                  artist_ini_unchanged=True,installed_in_artist_profile=False,exe_created=False,older_hosts_built=False)
write(evidence/'package-verification.json',verification)
qualification=dict(version='0.87.6.3',max_year=2027,scene_schema=65,recipe_format=9,edit_storage=3,interactions=16,
    viewport_selection_capability=1,status='scoped_pass',baseline='0.87.5.6 artistic response; 0.87.6.2 selection/shared controls',
    native_tests=dict(passed=62,total=62,host=2027),generated=generated,package=verification,loaded_identity=loaded,
    host_checks=dict(role_transitions=5,hiding_combinations=8,draw_budget_changes=5,reactors_in_budget_fixture=500,
        manual_pending_amount=777,published_count=500,shared_controls_and_picking='smoke.json',
        garden=dict(controllers=len(garden['owners']),placements=sum(garden['placements']),rays=len(garden['samples']),median_pick_ms=garden['median_ms'],unchanged_epochs_streams=True),
        navigation=dict(samples=len(nav['redraw_ms']),median_cpu_submit_ms=nav['median_ms'],unchanged_epochs_streams=True),
        posed_pick=dict(samples=len(posed['samples']),max_world_unit_error=posed['max_error_world_units'],world_units_per_metre=drag['system_units_per_metre'],unchanged_epochs_streams=True),
        held_replay=series,save_reload_undo_redo='persistence-events.txt'),
    development_notes=[
        'Early garden replay drivers used an open collider mesh, incorrect proxy transform or incorrect callback/publication order. The final driver passes computation and presented-ticket assertions without production changes.',
        'Earlier persistence drivers selected before reload publication, inspected the wrong layer, or included setup in the transport Undo hold. Separate timed MAXScript events pass the named move, Undo and Redo.',
        'Earlier failed driver receipts remain in the owned build folder; final evidence is explicitly named here.'
    ],limits=[
        'Max 2027 only; no EXE, Max 2024/2026 build/test or artist installation.',
        'Scripted held-input and presentation-ticket checks are not physical mouse latency or GPU-presented FPS.',
        'Native allocation probes isolate bookkeeping; the million-row view test is not a million-reactor Max scene.',
        'The 13,087-pose limit example is arithmetic; the actual budget-change host fixture has 500 reactors.',
        'Render-bound containment and fixed-visibility parity do not qualify all external renderers, representations or arbitrary plant topology.',
        'Global pose bookkeeping, dense high-poly picking, exact peak memory/VRAM, device loss and long-session soak remain open.',
        'The environment-only CPU posed-batch display route is unchanged; source capture/geometry preparation and render output retain separate costs.',
        'No website build/publication or indexed-knowledge refresh; existing independent-product qualification is unchanged.'
    ])
qualification['evidence']={p.name:dict(path=p.relative_to(ROOT).as_posix(),sha256=sha(p)) for p in sorted(evidence.iterdir()) if p.is_file()}
write(DOC/'QUALIFICATION.json',qualification)
OUT.mkdir(exist_ok=True)
target=OUT/package.name
if target.exists():assert sha(target)==sha(package),'Do not overwrite a distinct delivered artifact'
else:shutil.copy2(package,target)
write(OUT/'PACKAGE_VERIFICATION.json',verification)
(OUT/'SHA256SUMS.txt').write_text(sha(target)+'  '+target.name+'\n',encoding='utf-8')
print(json.dumps(dict(status='passed',package=str(target),sha256=sha(target),native_tests=62,host=2027),indent=2))
