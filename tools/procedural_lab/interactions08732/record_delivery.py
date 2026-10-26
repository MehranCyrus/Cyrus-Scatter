"""Seal compact, scoped final-pair receipts without copying private meshes."""
from pathlib import Path
import hashlib,json,re,shutil,zipfile,subprocess,os
ROOT=Path(__file__).resolve().parents[3];run=ROOT/'build/interactions08732-neottopteris-20261026-01';host=run/'final-host-03';docs=ROOT/'docs/plans/scatter-interactions-garden-20261025';evidence=docs/'evidence-08732'
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def read(path):return json.loads(Path(path).read_text(encoding='utf-8-sig'))
native=read(run/'native-04/receipt.json');package=read(run/'final-payload/package-identity.json');loaded=read(host/'loaded-identity.json')
assert native['status']=='complete' and native['tests_run'] and native['max_year']==2027
assert '100% tests passed, 0 tests failed out of 59' in (run/'native-04/tests.log').read_text()
for name,digest in native['sources'].items():assert sha(ROOT/name)==digest,name
archive=Path(package['archive']);assert sha(archive)==package['sha256']
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    manifest=json.loads(z.read('manifest.json'));assert manifest['version']=='0.87.3.2' and manifest['max_year']==2027
    for name,digest in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest,name
    script=z.read('CyrusScatter.ms').decode('utf-8-sig');assert 'cyrusInteractionVersion()!=7' in script and '29000' in z.read('install.ms').decode('utf-8-sig')
    stamp=re.search(r'CyrusLoadedScriptFingerprint\s*=\s*"([a-f0-9]+)"',script).group(1);assert loaded['script_fingerprint']==stamp
for name,data in loaded['modules'].items():assert data['sha256']==package['files'][name],name
reports={name:read(host/(name+'.json')) for name in ['prepare-controls','hover-setup','hover-contacts','prepare-undo','prepare-lifecycle','source-controls','swatch-geometry','broadleaf-setup','broadleaf-contacts','fern-roundtrip','physical-ui']}
for name in ['prepare-controls','prepare-undo','prepare-lifecycle','source-controls','swatch-geometry','fern-roundtrip','physical-ui']:assert reports[name].get('status')=='pass',(name,reports[name])
for name in ['hover-contacts','broadleaf-contacts']:
    assert len(reports[name]['moves'])==5
    for row in reports[name]['moves']:assert row['status']=='pass' and row['audit']['passed'] and row['statistics']['hidden_roots']==0,row
trial=reports['fern-roundtrip'];assert sha(trial['trial'])==trial['file_sha256']
intake=read(run/'intake.json');assert sha(intake['scene'])==intake['sha256']
launch=read(host/'launch.json');artist=Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini';assert sha(artist)==launch['artist_ini_sha256']
before=read(run/'before-surface-fix-contact.log');after=read(run/'after-surface-fix-contact.log')
assert before['full_mesh_audit']['results'][0]['touching_triangle_obstacle_pairs']==1
assert after['full_mesh_audit']['results'][0]['touching_triangle_obstacle_pairs']==0
evidence.mkdir(exist_ok=False)
for name in reports:shutil.copy2(host/(name+'.json'),evidence/(name+'.json'))
for source,name in [(host/'loaded-identity.json','loaded-identity.json'),(host/'launch.json','launch.json'),(run/'final-payload/package-identity.json','package-identity.json'),(run/'intake.json','intake.json'),(run/'native-04/tests.log','native-tests.log'),(run/'before-surface-fix-contact.log','before-surface-fix.json'),(run/'after-surface-fix-contact.log','after-surface-fix.json'),(run/'baseline-host/model-inspection.json','baseline-model-inspection.json'),(run/'actual-sources-final.log','actual-sources-final.log')]:shutil.copy2(source,evidence/name)
qualification={'schema':'cyrus.interactions-08732/1','version':'0.87.3.2','max_year':2027,'native_interactions':7,'saved_schema':61,'scope':'Source controls, primary preparation settings, native swatches, supplied Neottopteris preparation and bounded actual-surface contact; owned Max 2027 only','package':package,'archive_files_verified':len(manifest['files']),'script_fingerprint':stamp,'native_receipt':str(run/'native-04/receipt.json'),'native_input_manifest_sha256':native['input_manifest_sha256'],'native_source_hashes':native['sources'],'native_tests_passed':59,'generated_sha256':package['files']['CyrusScatter.ms'],'host':{'pid':launch['pid'],'hwnd':trial['hwnd'],'directory':str(host),'controls':len(reports['prepare-controls']['checks']),'lifecycle':len(reports['prepare-lifecycle']['checks']),'source_controls':len(reports['source-controls']['checks']),'swatch_checks':len(reports['swatch-geometry']['checks']),'grass_moves':5,'fern_moves':5,'physical_actions':reports['physical-ui']['physical_actions']},'trial':trial,'original_scene_unchanged':True,'artist_ini_unchanged':True,'git':{'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()},'evidence_files':{p.name:sha(p) for p in evidence.iterdir()},'limits':['Actual source/pose payload counters are not process-wide memory peaks.','Per-guide detailed proof: 50k vertices / 100k faces, one at-most-1.2MB Vec3 scratch vector; 2M geometry work per plant.','Held-pointer presented FPS, production renderer delivery, other DPI scales and broader botanical geometry are not newly qualified.','The research index was not refreshed; current originals and exact build/loaded receipts supplied evidence.'],'installed_in_artist_profile':False,'committed_or_pushed':False}
(docs/'QUALIFICATION_08732.json').write_text(json.dumps(qualification,indent=2),encoding='utf-8')
print(json.dumps({'status':'pass','native_tests':59,'package_sha256':package['sha256'],'trial':trial['trial'],'evidence_files':len(qualification['evidence_files']),'host_checks':qualification['host']},indent=2))
