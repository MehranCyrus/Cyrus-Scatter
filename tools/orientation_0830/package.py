"""Build a candidate MZP from a verified loaded pair and qualified examples."""
from pathlib import Path
from types import SimpleNamespace
import argparse,hashlib,json,shutil,sys,zipfile
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'));import build_max
p=argparse.ArgumentParser();p.add_argument('--host',required=True);p.add_argument('--native',required=True);p.add_argument('--output',required=True);a=p.parse_args()
host=(ROOT/'build/mcp-qualification'/a.host).resolve();native=(ROOT/a.native).resolve();out=(ROOT/a.output).resolve()
assert host.parent==ROOT/'build/mcp-qualification' and host.name.startswith('foundation-roadmap-orientation0830-')
assert native.is_relative_to(ROOT/'build') and (out.is_relative_to(ROOT/'build') or out.is_relative_to(ROOT/'dist'))
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
receipt=json.loads((native/'receipt.json').read_text());loaded=json.loads((host/'launch.json').read_text());version=build_max.scatter_version()
assert version=='0.83.0' and receipt['max_year']==loaded['max_year']==2027 and all(s['exit_code']==0 for s in receipt['stages'])
for name,digest in receipt['sources'].items():
 if name!='AminScatter/scripts/AminScatterObject.ms':assert sha(ROOT/name)==digest,name
assert sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')==sha(host/'scripts/CyrusScatter.ms')==loaded['script_sha256']
assert (host/'ready.json').exists()
for pattern in ('orientation-core-*.json','existing-examples-*.json','heavy-[0-9]*.json'):
 records=sorted(host.glob(pattern));assert records,pattern
 assert json.loads(records[-1].read_text(encoding='utf-8'))['status']=='passed',pattern
assert json.loads((host/'lifecycle-ui.json').read_text())['status']=='passed'
assert json.loads((host/'layout-orientation150-final-02.json').read_text())['status']=='passed'
names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
stage=out/'staging';(stage/'AminScatter').mkdir(parents=True,exist_ok=False)
for name in names:
 assert sha(native/name)==sha(host/'bin'/name)==loaded['binaries'][name]
 shutil.copy2(native/name,stage/'AminScatter'/name)
args=SimpleNamespace(max_year=2027,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=out,team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h',library_dir=ROOT/'AminScatter/library')
build_max.package('AminScatter','Cyrus Scatter',version,names,'AminScatterObject.ms',args,stage)
target=out/f'CyrusScatter-{version}-Max2027.mzp'
with zipfile.ZipFile(target) as z:
 assert z.testzip() is None
 manifest=json.loads(z.read('manifest.json'));assert manifest['version']==version and manifest['max_year']==2027
 assert set(z.namelist())==set(manifest['files'])|{'manifest.json'}
 for name,digest in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest
 assert manifest['files']['CyrusScatter.ms']==loaded['script_sha256']
 for name in names:assert manifest['files'][name]==loaded['binaries'][name]
 installer=z.read('install.ms').decode('utf-8');assert '(maxVersion())[1]!=29000' in installer and 'Library-'+version in installer
 assert not any(token in installer for token in ('__VERSION__','__MAX_YEAR__','__NATIVE_ID__','__MAX_VERSION__'))
 assert 'run "install.ms"' in z.read('mzp.run').decode('utf-8')
 (out/'expanded-install.ms').write_bytes(z.read('install.ms'))
 (out/'expanded-library-files.ms').write_bytes(z.read('LibraryFiles.ms'))
result={'state':'candidate; final delivery receipt required','version':version,'max_year':2027,'package':str(target),'sha256':sha(target),'bytes':target.stat().st_size,'manifest':manifest,'host':a.host,'native_receipt_sha256':sha(native/'receipt.json'),'source_packager_sha256':sha(ROOT/'tools/build_max.py'),'library_inventory_sha256':sha(ROOT/'AminScatter/library/inventory.json'),'installed':False}
(out/'package.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps({k:result[k] for k in ('state','package','sha256','bytes')},indent=2))
