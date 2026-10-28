"""Seal the exact executed scene-preset delivery; keep preliminary evidence separate."""
from pathlib import Path
import hashlib,json,zipfile,subprocess
ROOT=Path(__file__).resolve().parents[3];RUN=ROOT/'build/scene-presets-08751-20261027-01';DOC=ROOT/'docs/plans/scene-presets-08751'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
native=read(RUN/'native-final/receipt.json');package=read(RUN/'payload-final/package-identity.json');installer=read(RUN/'installer-final/receipt.json');loaded=read(RUN/'host-final/loaded-identity.json')
assert native['status']=='complete' and native['tests_run'] and native['max_year']==2027
assert not [name for name,digest in native['sources'].items() if sha(ROOT/name)!=digest], 'Native producer sources changed after qualification'
assert sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')==package['files']['CyrusScatter.ms']
archive=Path(package['archive']);assert sha(archive)==package['sha256']==installer['archive_sha256']
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None;manifest=json.loads(z.read('manifest.json'));assert manifest['version']=='0.87.5.1' and manifest['max_year']==2027
    for name,digest in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest
for name,row in loaded['modules'].items():
    if name in package['files']:assert row['sha256']==package['files'][name],name
final_names=['final-inspect','final-repeat','final-unit-guard','final-ui','final-save-ui','final-poll-ui','setup-fern','poll-save','merge-first','paint-pending-setup','paint-pending-check','paint-pending-merge','save-reopen','missing-poll','cancel-poll','portable','gallery-poll']
proofs={}
for name in final_names:
    value=read(RUN/'host-final'/(name+'.json'));assert value['status']=='passed',(name,value);proofs[name]=value
development={}
for name in ['metadata-poll','export-poll','import-poll','merge-repeat']:
    value=read(RUN/'host-03'/(name+'.json'));assert value['status']=='passed';development[name]=value
receipt={'status':'scoped_pass','version':'0.87.5.1','max_year':2027,'scene_schema':63,'interactions':12,'recipe_format':9,'edit_storage':3,'scene_preset_format':1,'managed_version':'0.87.5.1',
         'archive':str(archive),'archive_sha256':sha(archive),'bytes':archive.stat().st_size,'producer':str(RUN/'native-final/receipt.json'),'native_tests':61,
         'source_files':len(native['sources']),'current_source_hashes_verified':True,'package_files':package['files'],'installer':installer,'loaded_identity':loaded,'final_pair_checks':proofs,
         'development_store_checks':{'scope':'Earlier owned development host; unchanged managed implementation. Full final-pair transfer restore is separate above.','checks':development},
         'limits':['Max 2027 only; matching system units and required object/material plug-ins.','Standard Max merge clears Undo history; explicitly selected by the user and disclosed in the load dialog.','Interactions retain their existing one-Edit-per-controller limit; authored two-Edit/radius case uses interactions off.','Destination render/environment/colour configuration follows Max merge. Arbitrary third-party graphs and production renderer frames are unqualified.','Original-file unavailability exercised on an owned collected PNG, not by removing the vendor asset tree.','Physical UI capture/input was stopped after Computer Use reported manual input/capture issues; real rollout construction, controls and save action were exercised through Max.','Large preparation envelopes can exceed the existing portable authored-text bounds; scene presets handle the tested fern.'],
         'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()}
(DOC/'QUALIFICATION_08751.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'status':receipt['status'],'version':receipt['version'],'sha256':receipt['archive_sha256'],'final_checks':len(proofs),'source_files':receipt['source_files']},indent=2))
