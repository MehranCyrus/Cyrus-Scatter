"""Freeze I04 scoped receipts and the exact MZP without installing it."""
from pathlib import Path
import hashlib,json,shutil,zipfile
ROOT=Path(__file__).resolve().parents[2];DOC=ROOT/'docs/plans/improvement-program';BUILD=ROOT/'build/orientation-0830-20261016-01'
HOSTS=ROOT/'build/mcp-qualification';MAIN='foundation-roadmap-orientation0830-final100-20261016-06';DPI='foundation-roadmap-orientation0830-final150-20261016-07'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8'))
records={}
def evidence(p):
 v=read(p);assert v.get('status')=='passed' or v.get('passed') is True,p
 records[p.relative_to(ROOT).as_posix()]={'sha256':sha(p),'result':v};return v
def latest(host,pattern):
 files=sorted((HOSTS/host).glob(pattern));assert files,pattern;return evidence(files[-1])
for host in (MAIN,DPI):latest(host,'orientation-core-*.json');evidence(HOSTS/host/'lifecycle-ui.json')
for label in ('live_setup','time_step','time_check','idle_check','parent_move','parent_check','inactive_setup','inactive_check','normal_animation_setup','normal_animation_step','normal_animation_check','normal_idle_check','target_geometry_setup','target_geometry_edit','target_geometry_check','pivot_rotation','pivot_rotation_check','target_delete_setup','target_delete','target_delete_check'):
 evidence(HOSTS/MAIN/('lifecycle-'+label+'.json'))
for host,label in ((MAIN,'orientation100-final'),(DPI,'orientation150-final-02')):
 evidence(HOSTS/host/('layout-'+label+'.json'))
 image=HOSTS/host/('orientation-controls100.png' if host==MAIN else 'orientation-controls150.png')
 records[image.relative_to(ROOT).as_posix()]={'sha256':sha(image),'scope':'Owned-window visual inspection; Max UI scale, not physical 4K/mixed-monitor qualification'}
latest(DPI,'heavy-[0-9]*.json');latest(DPI,'existing-examples-*.json');latest(MAIN,'heavy-ui-[0-9]*.json');latest(MAIN,'heavy-ui-idle-[0-9]*.json')
log=sorted((HOSTS/DPI).glob('transactions-*.txt'))[-1];s=log.read_text(encoding='utf-8');assert 'PASS: complete' in s and 'FAIL:' not in s and 'ERROR:' not in s
records[log.relative_to(ROOT).as_posix()]={'sha256':sha(log),'text':s}
evidence(HOSTS/DPI/'installer-compile.json');evidence(BUILD/'generated-final/generated-check.json')
native=read(BUILD/'native-integration-05/receipt.json');assert all(s['exit_code']==0 for s in native['stages'])
sources={}
for path,digest in native['sources'].items():
 if path!='AminScatter/scripts/AminScatterObject.ms':assert sha(ROOT/path)==digest,path
 sources[path]={'build_input_sha256':digest,'current_sha256':sha(ROOT/path),'lf_sha256':hashlib.sha256((ROOT/path).read_bytes().replace(b'\r\n',b'\n')).hexdigest()}
package=read(BUILD/'candidate-dist/package.json');src=Path(package['package']);assert sha(src)==package['sha256']
with zipfile.ZipFile(src) as z:
 assert z.testzip() is None
 for path,digest in package['manifest']['files'].items():assert hashlib.sha256(z.read(path)).hexdigest()==digest
for host in (MAIN,DPI):
 launch=read(HOSTS/host/'launch.json');assert launch['script_sha256']==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')==package['manifest']['files']['CyrusScatter.ms']
 for path,digest in launch['binaries'].items():assert digest==package['manifest']['files'][path]
 records[(HOSTS/host/'launch.json').relative_to(ROOT).as_posix()]={'sha256':sha(HOSTS/host/'launch.json'),'result':launch}
dest=ROOT/'dist/CyrusScatter-0.83.0-20261016';dest.mkdir(exist_ok=True);target=dest/src.name
if target.exists():assert sha(target)==sha(src)
else:shutil.copy2(src,target)
package.update(state='scoped Max 2027 qualification and archive checks passed; not installed',package=str(target));(DOC/'PACKAGE_0830.json').write_text(json.dumps(package,indent=2)+'\n',encoding='utf-8')
qualification={'version':'0.83.0','max_year':2027,'native_receipt':native,'native_receipt_sha256':sha(BUILD/'native-integration-05/receipt.json'),'source_identity':sources,
 'source_identity_note':'Native receipt pins raw inputs. LF hashes identify equivalent Git-normalized text. Native inputs remain unchanged; the independently host-qualified final script includes the subsequent target-animation-validity repair. Launch and package records pin the exact loaded bytes.',
 'evidence':records,'limits':['No artist-profile installation, physical 4K/mixed-monitor or picker-input qualification','Scoped native/Max 2027 tests do not qualify arbitrary renderers, presented FPS or multi-hour stability','Thirty panel cycles and brief idle observations are bounded measurements','Four existing procedural examples; eight-example goal and EXE remain incomplete'],
 'fixture_failures':'Historical owned profiles and failed receipts are preserved. See I04_0830.md; failed heavy-ui-idle.json started before deferred Live activation and is superseded by settled-cycle and timestamped idle receipts.'}
(DOC/'QUALIFICATION_0830.json').write_text(json.dumps(qualification,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'package':str(target),'sha256':sha(target),'bytes':target.stat().st_size,'evidence_records':len(records)},indent=2))
