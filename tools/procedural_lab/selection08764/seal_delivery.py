"""Seal verified 0.87.6.4 bytes and scoped evidence; no installation or Git writes."""
from pathlib import Path
import json,hashlib,shutil
ROOT=Path(__file__).resolve().parents[3]
RUN=ROOT/'build/instance-selection-08764-20261029-03';HOST=RUN/'host-01';PACKAGES=RUN/'packages'
DOC=ROOT/'docs/plans/instance-selection-08764-20261029';DIST=ROOT/'dist/CyrusScatter-0.87.6.4-20261029'
def load(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,data):p.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
def copy(a,b):
    if b.exists():assert sha(a)==sha(b),str(b)
    else:shutil.copy2(a,b)
    assert sha(a)==sha(b)
package=load(PACKAGES/'PACKAGE_VERIFICATION.json');assert package['status']=='passed'
generated=load(RUN/'generated/generated-check.json');assert generated['passed']
assert generated['generated_sha256']==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
assert '100% tests passed, 0 tests failed out of 62' in (RUN/'native-2027/tests.log').read_text()
names=['workflow.json','pointer.json','lifecycle.json','garden-pick.json','navigation.json','campaign.json']
reports={name:load(HOST/name) for name in names};assert all(r['status']=='complete' for r in reports.values())
assert (HOST/'transform-events.txt').read_text().rstrip().endswith('COMPLETE')
garden=reports['garden-pick.json'];nav=reports['navigation.json']
assert garden['epochs_before']==garden['epochs_after'] and garden['streams_before']==garden['streams_after'] and not any(garden['errors'])
assert nav['before']==nav['after']
loaded=load(HOST/'loaded-identity.json')
for name,value in loaded['modules'].items():assert value['sha256']==package['builds']['2027']['native'][name]
evidence=DOC/'evidence';evidence.mkdir(exist_ok=True)
for name in names+['loaded-identity.json','transform-events.txt','native-hover.png','native-selected.png']:
    copy(HOST/name,evidence/name)
copy(RUN/'generated/generated-check.json',evidence/'generated-check.json')
copy(RUN/'native-2027/tests.log',evidence/'native-2027-tests.log')
qualification=dict(version='0.87.6.4',max_year=2027,scene_schema=65,recipe_format=9,edit_storage=3,interactions=16,viewport_selection_capability=2,status='scoped_pass',
    native_tests=dict(passed=62,total=62),generated=generated,package=package,loaded_identity=loaded,
    host_checks=dict(workflow='Visible instance/layer identity; new and existing separate Edit; Manual pending Count retained on selection; stale ticket rejected.',
        viewport='Max SDK PickNode and native viewport mouse messages: one bounds highlight and exact click-to-Edit selection; screenshots inspected.',
        editing='Move, Rotate, Scale, Undo and Redo across separate host events in Live; stable identity retained.',
        lifecycle='Transformed geometry pick, foreground ordinary-object occlusion, hidden preview, owner/settings selection, shared multi-owner controls, save/reload with explicit Update, deletion and exactly two transient helpers per controller.',
        garden=dict(placements=sum(garden['placements']),controllers=len(garden['owners']),rays=len(garden['samples']),median_pick_ms=garden['median_ms'],max_pick_ms=garden['max_ms'],unchanged_epochs_streams=True),
        navigation=dict(samples=len(nav['redraw_ms']),median_cpu_submission_ms=nav['median_ms'],unchanged_epochs_streams=True)),
    evidence={p.name:dict(path=p.relative_to(ROOT).as_posix(),sha256=sha(p)) for p in sorted(evidence.iterdir()) if p.is_file()},
    development_notes=[
        'Run 01 rejected: legacy DoOwnSelectHilite did not suppress Nitrous whole-helper preselection. Run 02 separates picking from render items.',
        'Run 02 rejected: nested MAXScript collection in helper deletion caused a free-thunk error during save. Run 03 uses explicit local arrays; save/reload/delete checks pass.',
        'Earlier fixture corrections: Manual author transforms correctly remained pending until Update; Live is used for immediate displayed transform checks. The test transport preserves its last request across reinstall to avoid rerunning completed lifecycle commands.',
        'Final delivery uses run 03 only. Earlier artifacts are development evidence and are not delivered.'],
    limits=[
        'Max 2024/2026 SDK builds and package integrity only; neither application was launched.',
        'Synthetic viewport messages and scripted redraw are not physical input-to-present latency or GPU FPS.',
        'Exact visible mesh picking still incurs bounded geometry work; only the highlight is reduced to twelve box edges. Point Cloud/Centers preserve existing selection behavior.',
        'Bend/Trim/contact algorithms are unchanged. No new renderer, library, licensing UI, device-loss or long-session soak qualification.',
        'EXE embedded payloads are verified without running installation in artist profiles. Website and indexed knowledge are not rebuilt.'])
write(DOC/'QUALIFICATION.json',qualification)
baseline=load(ROOT/'docs/KNOWLEDGE_BASELINE.json')
baseline['delivery_receipt']='docs/plans/instance-selection-08764-20261029/QUALIFICATION.json'
baseline['delivered']['version']='0.87.6.4'
baseline['limits'][0]='0.87.6.4 qualifies 62 native suites and focused Max 2027 instance hover/click, transforms, Undo/Redo, lifecycle and retained garden navigation. Combined EXE: Max 2024/2026 are build/package only.'
baseline['limits'][-1]='The 0.87.6.4 delivery does not refresh or activate indexed knowledge. Reverify source freshness before using older index results.'
baseline['owners']['qualification']='docs/plans/instance-selection-08764-20261029/DELIVERY.md'
baseline['owners']['viewport_selection']='docs/plans/instance-selection-08764-20261029/ARTIST_GUIDE.md'
write(ROOT/'docs/KNOWLEDGE_BASELINE.json',baseline)
DIST.mkdir(exist_ok=True)
for name in [f'CyrusScatter-0.87.6.4-Max{y}.mzp' for y in (2024,2026,2027)]+['CyrusScatter-0.87.6.4-Setup.exe','PACKAGE_VERIFICATION.json','SHA256SUMS.txt']:
    copy(PACKAGES/name,DIST/name)
for p in PACKAGES.glob('*.build.json'):copy(p,DIST/p.name)
copy(DOC/'QUALIFICATION.json',DIST/'QUALIFICATION.json')
(DIST/'INSTALL.txt').write_text('Cyrus Scatter 0.87.6.4\n\nSave work, close selected Max versions, and run CyrusScatter-0.87.6.4-Setup.exe.\nDistinct Max 2024/2026/2027 payloads are included.\nAlternative: Scripting > Run Script, choose the matching MZP, then restart Max.\n\nHover one mesh for a simple box. Click to enter Cyrus Scatter Edit > Instances\nand select its exact layer/instance. Select the SC icon for setup controls.\n\nMax 2027: focused runtime tests. Max 2024/2026: SDK-build/package only.\nExisting Library content is reused; independent Analyzer is unchanged.\n',encoding='utf-8')
print(json.dumps(dict(status='sealed',dist=str(DIST),exe_sha256=package['exe_sha256']),indent=2))
