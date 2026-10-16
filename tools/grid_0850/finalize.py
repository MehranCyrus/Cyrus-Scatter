"""Freeze exact I06 evidence and package identities; never install."""
from pathlib import Path
import hashlib,json,zipfile
ROOT=Path(__file__).resolve().parents[2];DOC=ROOT/'docs/plans/improvement-program';BUILD=ROOT/'build/grid-0850-20261016-01'
HOSTS=ROOT/'build/mcp-qualification';MAIN=HOSTS/'foundation-roadmap-grid0850-final100-20261016-03';DPI=HOSTS/'foundation-roadmap-grid0850-final150-20261016-04'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8'))
records={}
def evidence(p):
 value=read(p);assert value.get('status') in ('passed','prepared') or value.get('passed') is True,p
 records[p.relative_to(ROOT).as_posix()]={'sha256':sha(p),'result':value};return value
def latest(folder,pattern):
 files=sorted(folder.glob(pattern),key=lambda x:x.stat().st_mtime_ns);assert files,pattern;return evidence(files[-1])
def log(p,marker='PASS: complete'):
 value=p.read_text(encoding='utf-8');assert marker in value and 'FAIL:' not in value and '\nERROR:' not in value,p
 records[p.relative_to(ROOT).as_posix()]={'sha256':sha(p),'text':value}
for host,scale in ((MAIN,100),(DPI,150)):
 log(sorted(host.glob('grid-core-*.txt'))[-1],'PASS COMPLETE GRID CORE')
 for pattern in ('heavy-setup-*.json','passive-[0-9]*.json','idle-*.json','panel-costs-*.json'):latest(host,pattern)
 evidence(host/f'layout-all{scale}-settled.json')
 for path in sorted(host.glob('lifecycle-*.json')):
  if path.name!='lifecycle-baseline.json':evidence(path)
for pattern in ('binding-guard-*.txt','masks-*.txt','bands-*.txt','integration-*.txt','failures-*.txt'):log(sorted(MAIN.glob(pattern))[-1])
latest(MAIN,'existing-examples-*.json');latest(DPI,'cache-lifecycle-*.json');log(sorted(DPI.glob('units-*.txt'))[-1])
for slug in ('orchard','hexagonal'):
 evidence(MAIN/('demo-'+slug+'.json'));evidence(MAIN/('demo-'+slug+'-prepare.json'));log(MAIN/('demo-'+slug+'-apply.txt'))
for name in ('grid-layout150.png','grid-layout150-bottom.png'):
 path=DPI/name;records[path.relative_to(ROOT).as_posix()]={'sha256':sha(path),'scope':'Owned-window visual inspection of grid controls and scrolling; Max UI scale, not physical 4K/mixed-monitor qualification'}
evidence(DPI/'installer-compile.json');evidence(BUILD/'generated-03/generated-check.json')
native=read(BUILD/'native-integration-06/receipt.json');assert all(s['exit_code']==0 for s in native['stages'])
sources={}
for name,digest in native['sources'].items():
 assert sha(ROOT/name)==digest,name
 sources[name]={'build_input_sha256':digest,'lf_sha256':hashlib.sha256((ROOT/name).read_bytes().replace(b'\r\n',b'\n')).hexdigest()}
package=read(ROOT/'dist/CyrusScatter-0.85.0-20261016/package.json');archive=Path(package['package']);assert sha(archive)==package['sha256']
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 for name,digest in package['manifest']['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest
for host in (MAIN,DPI):
 launch=read(host/'launch.json');assert launch['script_sha256']==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')==package['manifest']['files']['CyrusScatter.ms']
 for name,digest in launch['binaries'].items():assert digest==package['manifest']['files'][name]
 records[(host/'launch.json').relative_to(ROOT).as_posix()]={'sha256':sha(host/'launch.json'),'result':launch}
fixtures={p.relative_to(ROOT).as_posix():sha(p) for p in (ROOT/'tools/grid_0850').glob('*') if p.is_file()}
package.update(state='scoped Max 2027 qualification and archive checks passed; not installed')
(DOC/'PACKAGE_0850.json').write_text(json.dumps(package,indent=2)+'\n',encoding='utf-8')
qualification={'version':'0.85.0','max_year':2027,'native_receipt':native,'native_receipt_sha256':sha(BUILD/'native-integration-06/receipt.json'),'source_identity':sources,
 'source_identity_note':'Raw hashes pin the exact built and host-loaded pair; LF hashes describe equivalent Git-normalized source text. Fixtures and bounded results do not certify untested scenes/renderers/devices.',
 'evidence':records,'fixtures':fixtures,'python_tests':{'command':'build/mcp-venv/Scripts/python.exe -m pytest CyrusMCP/tests tools/tests -q','passed':166,'seconds':12.17},
 'limits':['Physical 4K/mixed-monitor/picker input remains separate','No renderer/device/FPS or multi-hour stability certification','Per-receiver projection bounds are not a process-wide memory budget; I09/I11 remain','B26 low-heap-headroom Undo remains unresolved','Six procedural examples; at least two more and the final EXE remain','No artist installation or website publication'],
 'failed_iterations':'See I06_0850.md and PROGRESS.md. Prior candidate caught script ownership and inactive Count animation bugs; corrected successors pass. Fixture reserved identifiers/top-level local scope were corrected. Immediate all-panel reads preceded queued reflow; settled reads pass. An example fixture selected New variation while expecting Saved; corrected selection 2 passes.'}
(DOC/'QUALIFICATION_0850.json').write_text(json.dumps(qualification,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'evidence_records':len(records),'package':str(archive),'sha256':sha(archive),'bytes':archive.stat().st_size}))
