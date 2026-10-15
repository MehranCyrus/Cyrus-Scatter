"""Freeze scoped evidence and copy the exact checked MZP; never install it."""
from pathlib import Path
import hashlib,json,shutil,zipfile
ROOT=Path(__file__).resolve().parents[2]
DOC=ROOT/'docs/plans/improvement-program'
BUILD=ROOT/'build/library-08261-20261016-01'
HOSTS=ROOT/'build/mcp-qualification'
MAIN='foundation-roadmap-library08261-final100-20261016-04'
FINAL='foundation-roadmap-library08261-final150-20261016-04'
DPI='foundation-roadmap-library08261-final100-20261016-05'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8'))
records={}
def evidence(p,passed=True):
 data=read(p)
 if passed:assert data.get('status')=='passed' or data.get('passed') is True,p
 records[str(p.relative_to(ROOT)).replace('\\','/')]={'sha256':sha(p),'result':data}
 return data
for host,labels in ((MAIN,['setup','save','browse','library128-complete','library2000-complete','library10000-complete','thumbnail_observe','cancel_observe','close_scan','reopen','failures-final','owner_deleted']),
 (FINAL,['setup','save','browse','bundled_observe','unicode_observe','offline_observe','lifecycle-02','idle_observe']),
 (DPI,['setup','bundled_observe','save','browse','readonly-observe-02','readonly_finalize'])):
 for label in labels:evidence(HOSTS/host/('qualification-'+label+'.json'))
for host,label in ((FINAL,'bundled150'),(DPI,'bundled100')):evidence(HOSTS/host/('layout-'+label+'.json'))
for slug in ('meadow','woodland','mountain','borders'):
 evidence(HOSTS/MAIN/('demo-'+slug+'.json'));evidence(HOSTS/MAIN/('demo-'+slug+'-prepare.json'))
 log=HOSTS/MAIN/('demo-'+slug+'-apply.txt');s=log.read_text();assert 'PASS: complete' in s and 'FAIL:' not in s and 'ERROR:' not in s
 records[str(log.relative_to(ROOT)).replace('\\','/')]={'sha256':sha(log),'text':s}
evidence(HOSTS/FINAL/'demo-borders-prepare.json')
log=HOSTS/FINAL/'demo-borders-apply.txt';s=log.read_text();assert 'PASS: complete' in s and 'FAIL:' not in s and 'ERROR:' not in s
records[str(log.relative_to(ROOT)).replace('\\','/')]={'sha256':sha(log),'text':s}
evidence(HOSTS/FINAL/'installer-compile.json');evidence(BUILD/'generated-final/generated-check.json')
shutdown=read(HOSTS/MAIN/'shutdown-result.json');assert shutdown['exited']
records[str((HOSTS/MAIN/'shutdown-result.json').relative_to(ROOT)).replace('\\','/')]={'sha256':sha(HOSTS/MAIN/'shutdown-result.json'),'result':shutdown}
native=read(BUILD/'native-02/receipt.json');assert all(s['exit_code']==0 for s in native['stages'])
source={}
for name,digest in native['sources'].items():
 if name!='AminScatter/scripts/AminScatterObject.ms':assert sha(ROOT/name)==digest,name
 source[name]={'build_input_sha256':digest,'current_sha256':sha(ROOT/name),'lf_sha256':hashlib.sha256((ROOT/name).read_bytes().replace(b'\r\n',b'\n')).hexdigest()}
package=read(BUILD/'candidate-dist/package.json');src=Path(package['package']);assert sha(src)==package['sha256']
with zipfile.ZipFile(src) as z:
 assert z.testzip() is None
 for name,digest in package['manifest']['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest
for host in (FINAL,DPI):
 launch=read(HOSTS/host/'launch.json');assert launch['script_sha256']==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')==package['manifest']['files']['CyrusScatter.ms']
 for name,digest in launch['binaries'].items():assert digest==package['manifest']['files'][name]
 records[str((HOSTS/host/'launch.json').relative_to(ROOT)).replace('\\','/')]={'sha256':sha(HOSTS/host/'launch.json'),'result':launch}
dest=ROOT/'dist/CyrusScatter-0.82.6.1-20261016';dest.mkdir(exist_ok=True)
target=dest/src.name
if target.exists():assert sha(target)==sha(src)
else:shutil.copy2(src,target)
package.update(state='scoped Max 2027 qualification and archive checks passed; not installed',package=str(target))
(DOC/'PACKAGE_08261.json').write_text(json.dumps(package,indent=2)+'\n',encoding='utf-8')
qualification={'version':'0.82.6.1','max_year':2027,'native_receipt':native,'native_receipt_sha256':sha(BUILD/'native-02/receipt.json'),'source_identity':source,
 'source_identity_note':'Native receipt pins raw build-input bytes. Git uses LF normalization for source text; lf_sha256 permits comparing that equivalent committed source. The final generated script and loaded native payload hashes are exact. The earlier native-build script hash is superseded only by the independently host-qualified final script.',
 'evidence':records,'limits':['No normal-profile installation or EXE yet','Physical 4K/mixed-monitor DPI and broad renderer/FPS qualification remain open','Localhost unavailable-share cancellation is not arbitrary network latency qualification','Sixty cycles and thirty seconds idle do not establish multi-hour memory stability','Initial four examples; eight-preset goal remains incomplete']}
(DOC/'QUALIFICATION_08261.json').write_text(json.dumps(qualification,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'package':str(target),'sha256':sha(target),'evidence_records':len(records)},indent=2))
