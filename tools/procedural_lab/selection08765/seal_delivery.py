"""Seal the scoped 0.87.6.5 evidence and exact three-host packages."""
from pathlib import Path
import hashlib,json,shutil,subprocess
ROOT=Path(__file__).resolve().parents[3]
RUN=ROOT/'build/mesh-selection-08765-20261029-02';HOST=RUN/'host-01';PACKAGES=RUN/'packages'
DOC=ROOT/'docs/plans/instance-selection-08765-20261029';DIST=ROOT/'dist/CyrusScatter-0.87.6.5-20261029'
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,value):p.write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')
def copy(a,b):
    if b.exists():assert sha(a)==sha(b),str(b)
    else:shutil.copy2(a,b)
    assert sha(a)==sha(b)

package=load(PACKAGES/'PACKAGE_VERIFICATION.json');assert package['status']=='passed'
generated=load(RUN/'generated/generated-check.json');assert generated['passed']
assert generated['generated_sha256']==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
assert '100% tests passed, 0 tests failed out of 62' in (RUN/'native-2027/tests.log').read_text()
workflow=load(HOST/'workflow.json');outlines=load(HOST/'outlines.json');posed=load(HOST/'posed.json')
assert all(v['status']=='complete' for v in (workflow,outlines,posed))
assert outlines['warm']['before']==outlines['warm']['after'] and outlines['warm']['unchanged_epochs_and_streams']
assert outlines['during_drag'][5] and not outlines['after_drag'][5] and posed['warm_reused']
loaded=load(HOST/'loaded-identity.json')
for name,item in loaded['modules'].items():assert item['sha256']==package['builds']['2027']['native'][name]
evidence=DOC/'evidence';evidence.mkdir(exist_ok=True)
names=['workflow.json','outlines.json','posed.json','loaded-identity.json','mesh-hover.png','selected-pointer-away.png','during-drag.png','after-drag.png','posed-hover.png','posed-selected.png']
for name in names:copy(HOST/name,evidence/name)
copy(RUN/'generated/generated-check.json',evidence/'generated-check.json')
copy(RUN/'native-2027/tests.log',evidence/'native-2027-tests.log')
qualification=dict(version='0.87.6.5',status='scoped_pass',max_year=2027,scene_schema=65,recipe_format=9,edit_storage=3,interactions=16,viewport_selection_capability=2,
    native_tests=dict(passed=62,total=62),generated=generated,package=package,loaded_identity=loaded,
    host_checks=dict(selection='Actual SDK viewport mouse messages: one mesh cue, correct layer/identity, persistent outline after pointer exit.',
        gesture='Native TransformStart/Move/TransformFinish across host events: selected outline hidden while held, restored after finish; Undo/Redo and exit Edit.',
        retained='Manual pending Count remains pending on new/existing Edit entry; warm cue redraw does not change placement epoch or geometry streams.',
        posed='Two prepared blades, one posed instance: all 20 visible triangle outlines, persistent selected cue, warm reuse and clear selection.',
        timings=dict(warm_redraw_submission_samples=24,median_ms=outlines['warm']['median_redraw_submission_ms'],max_ms=outlines['warm']['max_ms'],scope='CPU scripted redraw submission, not physical input-to-present latency or GPU FPS.')),
    bounds=dict(hover_face_samples=1024,selected_total_lines=4096,selected_outlined_instances=128,selection_limit=False,other_selected_instances='Existing center markers; all remain transformable.'),
    evidence={p.name:dict(path=p.relative_to(ROOT).as_posix(),sha256=sha(p)) for p in sorted(evidence.iterdir()) if p.is_file()},
    development_notes=['Run 01 compiled and passed native tests but was rejected because generated version inputs changed during its build. Only frozen run 02 is delivered.',
        'Posed fixture first missed contact after random placement rotation; the obstacle footprint was widened. A sub-unit viewport framing failure was corrected using centimetre coordinates, explicit unhide/frame and in-viewport sample checks. Neither required a solver change.'],
    limits=['Max 2024/2026 SDK-build/package only; neither host was launched.',
        'No renderer output, arbitrary plant corpus, device-loss, physical mouse latency or million-instance FPS claim.',
        'Outline samples are bounded; dense meshes show sampled edges. Exact surface picking retains its separate geometry cost.',
        'No artist profile installation, restart, scene overwrite or Git push. Website and indexed knowledge are not rebuilt.'])
write(DOC/'QUALIFICATION.json',qualification)
DIST.mkdir(exist_ok=True)
for name in [f'CyrusScatter-0.87.6.5-Max{y}.mzp' for y in (2024,2026,2027)]+['CyrusScatter-0.87.6.5-Setup.exe','PACKAGE_VERIFICATION.json','SHA256SUMS.txt']:
    copy(PACKAGES/name,DIST/name)
for p in PACKAGES.glob('*.build.json'):copy(p,DIST/p.name)
copy(DOC/'QUALIFICATION.json',DIST/'QUALIFICATION.json')
(DIST/'INSTALL.txt').write_text('Cyrus Scatter 0.87.6.5\n\nSave work, close the selected Max versions and run CyrusScatter-0.87.6.5-Setup.exe.\nSeparate native payloads: Max 2024, 2026 and 2027.\nMZP alternative: Scripting > Run Script, choose the matching MZP, then restart Max.\n\nMesh-shaped hover highlights one instance. Click to enter Cyrus Scatter Edit > Instances.\nSelected outlines remain visible after the pointer leaves, hide during transform gestures, and return afterward.\nMax 2027 scoped runtime checks; Max 2024/2026 SDK-build/package checks only.\n',encoding='utf-8')
print(json.dumps(dict(status='sealed',dist=str(DIST),exe_sha256=package['exe_sha256']),indent=2))
