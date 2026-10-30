"""Seal already verified packages and preserve focused host evidence.

Does not install, launch Max, publish a site or commit anything.
"""
from pathlib import Path
import hashlib, json, shutil, statistics

ROOT=Path(__file__).resolve().parents[3]
RUN=ROOT/'build/viewport-selection-08762-20261029-02'
HOST=RUN/'host-01'; PACKAGES=RUN/'packages'
DOC=ROOT/'docs/plans/viewport-selection-08762-20261029'
DIST=ROOT/'dist/CyrusScatter-0.87.6.2-20261029'
def load(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def write(path,value):path.write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')
def exact_copy(source,destination):
    if destination.exists():assert sha(source)==sha(destination),f'Refusing to replace a different delivery: {destination}'
    else:shutil.copy2(source,destination)
    assert sha(source)==sha(destination)

package=load(PACKAGES/'PACKAGE_VERIFICATION.json');assert package['status']=='passed'
generated=load(RUN/'generated/generated-check.json');assert generated['passed']
assert '100% tests passed, 0 tests failed out of 62' in (RUN/'native-2027/tests.log').read_text()
evidence_names=['smoke.json','picking-host.json','pick-lifecycle.json','garden-pick.json','navigation.json','posed-pick.json']
reports={name:load(HOST/name) for name in evidence_names}
assert all(value['status']=='complete' for value in reports.values())
assert (HOST/'batch-events.txt').read_text().rstrip().endswith('COMPLETE')
pose=reports['posed-pick.json']; garden=reports['garden-pick.json']; nav=reports['navigation.json']
assert nav['before']==nav['after'] and pose['unchanged_epoch_streams']
assert garden['epochs_before']==garden['epochs_after'] and garden['streams_before']==garden['streams_after']
assert not any(garden['errors'])
loaded=load(HOST/'loaded-identity.json');assert loaded['status']=='pass'
for name,value in loaded['modules'].items():assert value['sha256']==package['builds']['2027']['native'][name]
assert generated['generated_sha256']==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')

evidence=DOC/'evidence';evidence.mkdir(exist_ok=True)
for name in evidence_names+['loaded-identity.json','batch-events.txt']:
    exact_copy(HOST/name,evidence/name)
exact_copy(RUN/'native-2027/tests.log',evidence/'native-2027-tests.log')
exact_copy(RUN/'generated/generated-check.json',evidence/'generated-check.json')
qualification=dict(
    version='0.87.6.2',max_year=2027,scene_schema=65,recipe_format=9,edit_storage=3,interactions=15,
    viewport_selection_capability=1,status='scoped_pass',
    baseline='0.87.6.1 contact implementation, preserving the artist-endorsed 0.87.5.6 response',
    native_tests=dict(passed=62,total=62,host=2027,log_sha256=sha(RUN/'native-2027/tests.log')),
    generated=generated,package=package,loaded_identity=loaded,
    host_checks=dict(
        shared_controls='Automatic multi-owner window; Manual pending; explicit Update; budgets; display mode; Enable/Disable; Show/Hide; one named Undo across separate event callbacks.',
        object_pick='Actual SDK PickNode, owner redirection and foreground ordinary-object occlusion.',
        instance_pick='Actual SubObHitTest/SelectSubComponent off the pivot; stable identity after moving; no hit after authored deletion plus Manual Update.',
        posed_pick=dict(samples=len(pose['samples']),cpu_bake_faces=pose['baked_faces'],unposed_excluded=pose['unposed_instances'],
                        max_world_unit_error=pose['max_error_world_units'],bent_plants=pose['contact']['posed'],pruned_guides=pose['contact']['pruned_guides'],
                        hidden_root_groups=pose['contact']['hidden_roots'],unchanged_epoch_streams=True,
                        reference='Private two-sided brute-force SDK ray against CPU-baked accepted poses, no product picker geometry used for reference.'),
        garden=dict(placements=sum(garden['placements']),controllers=len(garden['owners']),rays=len(garden['samples']),hits=sum(bool(s['owners']) for s in garden['samples']),
                    median_ms=garden['median_ms'],hit_median_ms=statistics.median(s['ms'] for s in garden['samples'] if s['owners']),max_ms=garden['max_ms'],unchanged_epochs_streams=True),
        navigation=dict(samples=len(nav['redraw_ms']),median_cpu_submission_ms=nav['median_ms'],unchanged_epochs_streams=True)),
    evidence={p.name:dict(path=p.relative_to(ROOT).as_posix(),sha256=sha(p)) for p in sorted(evidence.iterdir()) if p.is_file()},
    development_notes=[
        'Final product payload is run 02; earlier run 01 packages are superseded development artifacts and are not delivered.',
        'Shared-window node-array capture and a reserved MAXScript identifier were corrected before the final three-host builds.',
        'Private driver corrections: bounded Edit inspection is at most 500 rows; the garden grass is layer 4; baked poses exclude untouched shared instances; Max intersectRay was not an adequate two-sided thin-blade reference. Earlier failed driver receipts remain in the owned run. The independent two-sided CPU reference passes without any production solver change.'
    ],
    limits=[
        'Max 2024 and 2026 were SDK-built and packaged only; neither was launched.',
        'Scripted host API and redraw checks do not establish physical mouse-to-screen latency, tooltip dwell timing or GPU-presented FPS.',
        'Hover uses the displayed geometry and its draw limits. Point Cloud/Centers and rectangle selection retain their existing icon/marker behavior.',
        'Complex yellow highlights sample at most 1024 faces; hit testing is not sampled. Atlas alpha uses nearest threshold rather than identical GPU filtering.',
        'The environment-only CPU posed-batch viewport route, arbitrary renderer output, device-loss/long-session soak and million-instance claims are not qualified.',
        'Installer payload integrity was verified without executing installation in artist profiles. Website and indexed knowledge were not rebuilt.'
    ])
write(DOC/'QUALIFICATION.json',qualification)

baseline=load(ROOT/'docs/KNOWLEDGE_BASELINE.json')
baseline['delivery_receipt']='docs/plans/viewport-selection-08762-20261029/QUALIFICATION.json'
baseline['delivered']['version']='0.87.6.2'
baseline['limits'][0]='0.87.6.2 qualifies the recorded Max 2027 shared-controls, geometry selection, posed-pick and navigation checks and 62 native tests; Max 2024/2026 are build/package only.'
baseline['limits'][-1]='The 0.87.6.2 delivery does not refresh or activate indexed knowledge. Current source hashes must be reverified before relying on previous corpus freshness reports.'
baseline['owners']['qualification']='docs/plans/viewport-selection-08762-20261029/DELIVERY.md'
baseline['owners']['viewport_selection']='docs/plans/viewport-selection-08762-20261029/ARTIST_GUIDE.md'
write(ROOT/'docs/KNOWLEDGE_BASELINE.json',baseline)

DIST.mkdir(exist_ok=True)
for name in [f'CyrusScatter-0.87.6.2-Max{year}.mzp' for year in (2024,2026,2027)]+['CyrusScatter-0.87.6.2-Setup.exe','PACKAGE_VERIFICATION.json','SHA256SUMS.txt']:
    exact_copy(PACKAGES/name,DIST/name)
for source in sorted(PACKAGES.glob('*.build.json')):exact_copy(source,DIST/source.name)
exact_copy(DOC/'QUALIFICATION.json',DIST/'QUALIFICATION.json')
(DIST/'INSTALL.txt').write_text('Cyrus Scatter 0.87.6.2\n\nClose the selected Max versions and run CyrusScatter-0.87.6.2-Setup.exe.\nIt includes distinct Max 2024, 2026 and 2027 payloads.\n\nAlternative: Scripting > Run Script, choose the matching .mzp, then restart Max.\n\nMax 2027: scoped native and runtime qualification.\nMax 2024/2026: matching SDK builds and package verification only; runtime not tested.\n\nHover/click displayed mesh to select its Scatter controller.\nUse the separate Cyrus Scatter Edit > Instances level to pick individual meshes.\nSelect multiple controllers, or Viewport & render > Multiple Scatters..., for shared controls.\n\nGuide: docs/plans/viewport-selection-08762-20261029/ARTIST_GUIDE.md\n',encoding='utf-8')
print(json.dumps(dict(status='sealed',version='0.87.6.2',dist=str(DIST),posed_samples=len(pose['samples']),max_posed_error=pose['max_error_world_units'],exe_sha256=package['exe_sha256']),indent=2))
