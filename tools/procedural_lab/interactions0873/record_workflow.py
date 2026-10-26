"""Retain bounded, non-geometry evidence for the 0.87.3 workflow delivery."""
from pathlib import Path
import hashlib,json,re,shutil,zipfile
ROOT=Path(__file__).resolve().parents[3];RUN=ROOT/'build/interactions0873-workflow-20261026-01';HOST=RUN/'host-06'
DOC=ROOT/'docs/plans/scatter-interactions-garden-20261025';OUT=DOC/'evidence-workflow-0873';OUT.mkdir(exist_ok=True)
def read(p):return json.loads(p.read_text())
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
identity=read(RUN/'payload-06/package-identity.json');loaded=read(HOST/'loaded-identity.json');trial=read(HOST/'trial.json')
assert loaded['status']==trial['status']=='pass'
for name,value in loaded['modules'].items():assert value['sha256']==identity['files'][name]==sha(Path(value['path']))
script=ROOT/'AminScatter/scripts/AminScatterObject.ms';assert sha(script)==identity['files']['CyrusScatter.ms']
assert re.search(r'CyrusLoadedScriptFingerprint="([a-f0-9]+)"',script.read_text()).group(1)==loaded['script_fingerprint']
with zipfile.ZipFile(identity['archive']) as archive:
    assert archive.testzip() is None
    manifest=json.loads(archive.read('manifest.json'))
    for name,digest in manifest['files'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==digest
assert sha(Path(identity['archive']))==identity['sha256']
original=ROOT/'Test Scene/New Plants test.max';baseline=read(RUN/'baseline-02/baseline.json');assert sha(original)==baseline['scene_sha256']
assert sha(Path(trial['trial']))==trial['sha256']
files={
 'baseline.json':RUN/'baseline-02/baseline.json','baseline-loaded.json':RUN/'baseline-02/loaded-identity.json',
 'sweep-before.json':RUN/'sweep-before/report.json','guide-probe.json':RUN/'guide-probe.json','sweep-final.json':RUN/'sweep-06/report.json',
 'native-receipt.json':RUN/'native-06/receipt.json','native-tests.log':RUN/'native-06/tests.log',
 'generated-check.json':RUN/'generated-06/generated-check.json','package-identity.json':RUN/'payload-06/package-identity.json',
 'loaded-identity.json':HOST/'loaded-identity.json','controls.json':HOST/'controls.json','contacts.json':HOST/'replay-contacts.json',
 'lifecycle.json':HOST/'lifecycle.json','undo.json':HOST/'final-undo.json','trial.json':HOST/'trial.json',
 'physical-drag.json':HOST/'physical-drag.json','physical-drag-position.txt':HOST/'physical-drag-position.txt',
 'superseded-save-failure.json':RUN/'host-05/lifecycle.json',
}
for name,source in files.items():
    assert source.is_file(),source
    shutil.copy2(source,OUT/name)
before=read(files['sweep-before.json'])['cases'];after=read(files['sweep-final.json'])['cases']
contacts=read(files['contacts.json']);controls=read(files['controls.json']);lifecycle=read(files['lifecycle.json'])
assert len(after)==24 and all(c['exit']==0 for c in after)
assert controls['status']==lifecycle['status']=='pass' and all(m.get('status')=='pass' for m in contacts['moves'])
record={
 'schema':'cyrus.interactions.workflow-qualification/1','version':'0.87.3','native_capability':5,'saved_schema':61,'host':2027,
 'original_scene':{'path':str(original),'sha256':sha(original),'unchanged':True},'package':identity,'trial':{'path':trial['trial'],'sha256':trial['sha256']},
 'checks':{'native_tests':'59/59','generated':'pass','control_assertions':len(controls['checks']),'lifecycle_assertions':len(lifecycle['checks']),
           'numeric_sweep_before':{'cases':len(before),'failures':sum(c['exit']!=0 for c in before)},'numeric_sweep_after':{'cases':len(after),'failures':0},
           'edit_moves':len(contacts['moves']),'full_mesh_move_audits':all(m['audit']['passed'] for m in contacts['moves']),'undo_redo':'gap and individual collider pass',
           'physical_drag_final_position':files['physical-drag-position.txt'].read_text().strip()},
 'command_seconds':[m['command_seconds'] for m in contacts['moves']],'numeric_fit_ms':[m['stats']['fit_ms'] for m in contacts['moves']],
 'scope':'Owned standard-plugin Max 2027 profile. Command timing is not FPS; complete visible mesh audit uses double precision. Original file predates the screenshot configuration; same failure class was reproduced, not its exact guide index.',
 'remaining':['Renderer-specific materials and float delivery','Held-pointer FPS, long sessions and larger/new geometry cases','Immediate source-node deletion before updating retained placements','Exposed-root collider generation remains on hold'],
 'evidence':{name:{'path':'evidence-workflow-0873/'+name,'sha256':sha(OUT/name)} for name in files}
}
(DOC/'QUALIFICATION_WORKFLOW_0873.json').write_text(json.dumps(record,indent=2)+'\n')
print(json.dumps({'package':identity['archive'],'archive_sha256':identity['sha256'],'checks':record['checks'],'trial':record['trial']},indent=2))
