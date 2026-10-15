"""Package the exact qualified 0.82.6 Max 2027 pair without installing."""
from pathlib import Path
from types import SimpleNamespace
import hashlib,importlib.util,json,shutil,sys,zipfile
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/panel-0826-20261015-01'
NATIVE=OUT/'script-delivery-final';QUALIFICATION=OUT/'final-receipt.json';DIST=ROOT/'dist/CyrusScatter-0.82.6-20261015'
sys.path.insert(0,str(ROOT/'tools'));import build_max

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
receipt=json.loads((NATIVE/'receipt.json').read_text());qualified=json.loads(QUALIFICATION.read_text())
assert receipt['max_year']==2027 and not receipt['preview_fault_lab'] and all(s['exit_code']==0 for s in receipt['stages'])
assert build_max.scatter_version()==qualified['version']=='0.82.6'
spec=importlib.util.spec_from_file_location('offline',ROOT/'tools/procedural_lab/offline_build.py');offline=importlib.util.module_from_spec(spec);spec.loader.exec_module(offline)
assert receipt['sources']==offline.source_hashes('AminScatter')
assert all(sha(ROOT/path)==digest for path,digest in qualified['source_hashes'].items())
names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
stage=OUT/'package-stage-01';(stage/'AminScatter').mkdir(parents=True,exist_ok=False)
for name in names:
 source=NATIVE/name;assert sha(source)==receipt['binaries'][source.relative_to(ROOT).as_posix()];shutil.copy2(source,stage/'AminScatter'/name)
target=DIST/'CyrusScatter-0.82.6-Max2027.mzp';assert not target.exists()
args=SimpleNamespace(max_year=2027,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=DIST,team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h')
build_max.package('AminScatter','Cyrus Scatter','0.82.6',names,'AminScatterObject.ms',args,stage)
with zipfile.ZipFile(target) as archive:
 assert archive.testzip() is None
 manifest=json.loads(archive.read('manifest.json'));assert manifest['version']=='0.82.6' and manifest['max_year']==2027
 assert set(archive.namelist())==set(manifest['files'])|{'manifest.json'}
 for name,expected in manifest['files'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==expected
 assert manifest['files']['CyrusScatter.ms']==receipt['sources']['AminScatter/scripts/AminScatterObject.ms']
 for name in names:assert manifest['files'][name]==sha(NATIVE/name)
 installer=archive.read('install.ms').decode('utf-8');assert '(maxVersion())[1]!=29000' in installer and f'bin-max2027-{manifest["native_id"]}' in installer
 assert not any(t in installer for t in ('__MAX_YEAR__','__MAX_VERSION__','__VERSION__','__NATIVE_ID__'))
 assert '0.82.6' in archive.read('mzp.run').decode('utf-8') and 'run "install.ms"' in archive.read('mzp.run').decode('utf-8')
 instructions=archive.read('INSTALL.txt').decode('utf-8');assert 'Scripting > Run Script, then restart Max.' in instructions and 'Layers > Recipes' in instructions
result={'version':'0.82.6','max_year':2027,'package':str(target),'sha256':sha(target),'bytes':target.stat().st_size,'manifest':manifest,'native_build':str(NATIVE),'native_build_receipt_sha256':sha(NATIVE/'receipt.json'),'qualification_receipt':str(QUALIFICATION),'qualification_receipt_sha256':sha(QUALIFICATION),'source_packager_sha256':sha(ROOT/'tools/build_max.py'),'qualification':'Exact qualified script/native pair; archive verification does not execute the installer.','installed':False,'normal_profile_modified':False,'phase6':'paused'}
(OUT/'package.json').write_text(json.dumps(result,indent=2)+'\n');(ROOT/'docs/plans/panel-performance-0826/PACKAGE.json').write_text(json.dumps(result,indent=2)+'\n')
print(target);print('SHA-256:',result['sha256']);print('Bytes:',result['bytes'])
