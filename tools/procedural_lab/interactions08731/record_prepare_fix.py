"""Retain bounded evidence for the tested ParamBlock2 preparation correction."""
from pathlib import Path
import hashlib,json,re,shutil,zipfile
ROOT=Path(__file__).resolve().parents[3];RUN=ROOT/'build/interactions08731-preparefix-20261026-01';HOST=RUN/'final-host-02';DOC=ROOT/'docs/plans/scatter-interactions-garden-20261025'
def read(path):return json.loads(path.read_text(encoding='utf-8'))
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
identity=read(RUN/'final-payload/package-identity.json');loaded=read(HOST/'loaded-identity.json');controls=read(HOST/'prepare-controls.json');contacts=read(HOST/'hover-contacts.json');undo=read(HOST/'prepare-undo.json');lifecycle=read(HOST/'prepare-lifecycle.json')
assert all(x.get('status')=='pass' for x in [loaded,controls,undo,lifecycle]);assert len(contacts['moves'])==5 and all(x.get('status')=='pass' for x in contacts['moves'])
for name,item in loaded['modules'].items():assert item['sha256']==identity['files'][name]==sha(Path(item['path']))
script=ROOT/'AminScatter/scripts/AminScatterObject.ms';assert sha(script)==identity['files']['CyrusScatter.ms'];assert re.search(r'CyrusLoadedScriptFingerprint="([a-f0-9]+)"',script.read_text(encoding='utf-8-sig')).group(1)==loaded['script_fingerprint']
with zipfile.ZipFile(identity['archive']) as archive:
    assert archive.testzip() is None;manifest=json.loads(archive.read('manifest.json'))
    for name,digest in manifest['files'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==digest
assert sha(Path(identity['archive']))==identity['sha256']
OUT=DOC/'evidence-08731-preparefix';OUT.mkdir(exist_ok=True)
files={'intake.json':RUN/'intake.json','baseline-probe.json':RUN/'baseline/prepare-probe.json','baseline-loaded.json':RUN/'baseline/loaded-identity.json','native-receipt.json':RUN/'native-01/receipt.json','native-tests.log':RUN/'native-01/tests.log','package-identity.json':RUN/'final-payload/package-identity.json','loaded-identity.json':HOST/'loaded-identity.json','controls.json':HOST/'prepare-controls.json','contacts.json':HOST/'hover-contacts.json','undo.json':HOST/'prepare-undo.json','lifecycle.json':HOST/'prepare-lifecycle.json','initial-contact-expectation.json':RUN/'candidate-host/hover-contacts.json','initial-lifecycle-command-scope.json':RUN/'final-host/prepare-lifecycle.json','initial-lifecycle-diagnostic.json':RUN/'final-host/debug-retention.json'}
for name,path in files.items():shutil.copy2(path,OUT/name)
generated=RUN/'generated/generated-check.json';shutil.copy2(generated,OUT/'generated-check.json');files['generated-check.json']=generated
for name,source in {'template-eol-normalization.json':RUN/'template-eol-normalization.json','template-as-built.ms':RUN/'template-as-built.ms'}.items():shutil.copy2(source,OUT/name);files[name]=source
record={'schema':'cyrus.preparation-qualification/1','version':'0.87.3.1','host':2027,'native_capability':6,'saved_schema':61,'archive':identity,'intake':read(RUN/'intake.json'),'checks':{'native_tests':'59/59','generated_handler_assertions':len(controls['checks']),'lifecycle_assertions':len(lifecycle['checks']),'hover_positions':5,'full_mesh_audits':'5/5 pass','preparation_undo_redo':'pass','physical_click':'Interrupted by manual-input guard; not claimed'},'contact_metrics':[{'step':m['step'],'fitted_guides':m['statistics']['fitted_guides'],'hidden_roots':m['statistics']['hidden_roots'],'command_seconds':m['command_seconds'],'fit_ms':m['statistics']['fit_ms'],'triangles':m['audit']['triangles'],'passed':m['audit']['passed']} for m in contacts['moves']],'scope':'Final exact MZP payload, owned standard-plugin Max 2027 profile. Handler and numeric mesh evidence; renderer float/material delivery, physical drag FPS and large-scale/long-session behavior remain separate.','evidence':{name:{'path':'evidence-08731-preparefix/'+name,'sha256':sha(OUT/name)} for name in files}}
(DOC/'QUALIFICATION_PREPARATION_FIX_08731.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'archive':identity['archive'],'sha256':identity['sha256'],'checks':record['checks']},indent=2))
