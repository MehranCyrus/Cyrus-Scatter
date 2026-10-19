"""Preserve the first 0.86.2 receipt and deliver its qualified thumbnail correction."""
from pathlib import Path
import hashlib,json,re,shutil,subprocess,zipfile
ROOT=Path(__file__).resolve().parents[2]
BUILD=ROOT/'build/density-0862-correction-20261019'
NATIVE=Path('D:/CyrusScatterBuilds/density-0862-correction-20261019/pair03')
PACKAGE=BUILD/'package03';DIST=ROOT/'dist/CyrusScatter-0.86.2-20261019-correction01'
DOC=ROOT/'docs/plans/preset-gallery-improvements'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:p.read_text(encoding='utf-8-sig')
load=lambda p:json.loads(read(p))
def path(p):return p.relative_to(ROOT).as_posix() if p.is_relative_to(ROOT) else p.as_posix()
evidence=[]
def log(p,needle):
    text=read(p);assert needle in text and not re.search(r'^(FAIL|ERROR)\b',text,re.M),p
    evidence.append({'path':path(p),'sha256':sha(p),'pass_lines':len(re.findall(r'^PASS:',text,re.M))})
native=load(NATIVE/'receipt.json');candidate=load(PACKAGE/'candidate.json')
assert native['max_year']==2027 and all(s['exit_code']==0 for s in native['stages'])
for name,digest in {**native['sources'],**native['binaries']}.items():assert sha(ROOT/name)==digest,name
assert candidate['native_receipt_sha256']==sha(NATIVE/'receipt.json')
script=sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
assert candidate['manifest']['files']['CyrusScatter.ms']==script
assert '100% tests passed, 0 tests failed out of 45' in read(NATIVE/'tests.log')
provenance=native['script_only_revision']
assert sha(Path(provenance['native_build_receipt']))==provenance['native_build_receipt_sha256']
assert sha(NATIVE/'tests.log')==provenance['native_tests_log_sha256']
inventory=load(ROOT/'AminScatter/library/inventory.json')
host=ROOT/'build/mcp-qualification/density0862-s'
stages=load(host/'final-campaign.json');assert len(stages)==10 and all(s['exit_code']==0 for s in stages)
for name,needle in [('extended.log','HEAVY 250000 candidates:'),('field-numeric.txt','maximum_error='),('channels.txt','PASS: complete'),('workflow.log','PASS campaign workflow'),('examples.log','PASS campaign examples'),('save.log','PASS campaign save'),('demo-verify.txt','Reopen reproduces every full placement record'),('lifecycle-liveIdle.txt','PASS: complete'),('lifecycle-unrelatedTime.txt','PASS: complete'),('lifecycle-staleField.txt','PASS: complete'),('relocated-demo-result.txt','PASS:'),('demo-curvatureVerify.txt','at the same frame'),('demo-curvatureUndo.txt','exact channel values')]:log(host/name,needle)
for entry in inventory['entries']:log(host/('panels-example-'+entry['id']+'.txt'),'PASS: complete')
for name in ('library-new','library-append','saved-image-paint'):log(host/('panels-'+name+'.txt'),'PASS: complete')
for name,scale in [('density0862-s',1.0),('density0862-t',1.5)]:
    profile=ROOT/'build/mcp-qualification'/name;launch=load(profile/'launch.json')
    staged=load(profile/'script-staging-history.json')[-1]
    assert staged['script_sha256']==script and staged['native_receipt_sha256']==sha(NATIVE/'receipt.json') and sha(profile/'scripts/CyrusScatter.ms')==script
    for binary,digest in launch['binaries'].items():assert sha(profile/'bin'/binary)==digest==candidate['manifest']['files'][binary]
    assert sha(profile/'scripts/CyrusGallery.dll')==candidate['manifest']['files']['CyrusGallery.dll']
    log(profile/'thumbnail-campaign.txt','PASS:')
    log(profile/'thumbnail-checks.txt','50 passive panel bindings')
    for label in ('fresh-blank','fresh-blank-reopened','fresh-blank-scene-reopened'):log(profile/('panels-'+label+'.txt'),'PASS: complete')
    layout=Path(read(profile/'layout-latest.txt').strip());log(layout,'PASS: all mounted visible control HWNDs fit')
    assert float(re.search(r'^scale=([\d.]+)',read(layout)).group(1))==scale
log(BUILD/'managed02/result.txt','PASSED 41')
profile=ROOT/'build/mcp-qualification/density0862-u';launch=load(profile/'launch.json')
assert launch['script_sha256']==script==sha(profile/'scripts/CyrusScatter.ms')
for binary,digest in launch['binaries'].items():assert sha(profile/'bin'/binary)==digest==candidate['manifest']['files'][binary]
assert sha(profile/'scripts/CyrusGallery.dll')==candidate['manifest']['files']['CyrusGallery.dll']
for name,needle in [('thumbnail-campaign.txt','PASS:'),('thumbnail-checks.txt','50 passive panel bindings'),('physical-library-load.txt','PASS:'),('physical-pattern-load.txt','PASS:'),('physical-idle.txt','PASS:')]:log(profile/name,needle)
for line in read(profile/'loaded.tsv').splitlines():
    name,loaded_path=line.split('\t');assert Path(loaded_path).resolve().is_relative_to((profile/'bin').resolve())
    assert sha(Path(loaded_path))==candidate['manifest']['files'][name]
for label in ('shown','inverted','hidden'):log(profile/('physical-mask-'+label+'.txt'),'PASS:')
python=load(BUILD/'python-final-result.json');assert python['exit_code']==0 and python['generated_script_sha256']==script and python['result'].startswith('175 passed')
evidence.append({'path':path(BUILD/'python-final-result.json'),'sha256':sha(BUILD/'python-final-result.json')})
log(ROOT/'build/density-recipes-0862-20261018-01/distribution-correction03/result.txt','PASSED 35')
assert load(BUILD/'generated04/generated-check.json')['passed']
DIST.mkdir(exist_ok=False)
artifacts={}
for name,key in [('CyrusScatter-0.86.2-Max2027.mzp','mzp_sha256'),('CyrusScatter-0.86.2-Setup.exe','exe_sha256')]:
    source=PACKAGE/name;assert sha(source)==candidate[key]
    shutil.copy2(source,DIST/name);artifacts[name]={'path':path(DIST/name),'bytes':source.stat().st_size,'sha256':sha(source)}
with zipfile.ZipFile(PACKAGE/'CyrusScatter-0.86.2-Max2027.mzp') as archive:
    assert archive.testzip() is None
    for name,digest in candidate['manifest']['files'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==digest
result={'version':'0.86.2','delivery':'correction01','reason':'User requested fixes without a version bump. Use native ImgTag for safe empty/procedural thumbnail binding and whole-image scaling.','git_head':subprocess.check_output(['git','rev-parse','HEAD'],text=True,cwd=ROOT).strip(),'source_script_sha256':script,'native_receipt':{'path':path(NATIVE/'receipt.json'),'sha256':sha(NATIVE/'receipt.json')},'sources':native['sources'],'binaries':native['binaries'],'artifacts':artifacts,'evidence':evidence,'supersedes_installers_only':'QUALIFICATION_0862.json','original_qualification_sha256':sha(DOC/'QUALIFICATION_0862.json'),'artist_installation_performed':False,'knowledge_activation_performed':False,'limitations':['Scoped Max 2027 qualification only','Final product pattern artwork remains pending; three existing QA masks only','Physical mixed-monitor transitions and every third-party renderer/map are not qualified']}
result['native_build_provenance']=provenance
result['native_test_scope']='45 native tests ran for native02. Final pair03 changes only the generated script; native source and binary hashes were verified unchanged. Fresh final-script host tests are listed separately.'
result['final_host_profiles']=['density0862-s (100%, matching-binary script staging)','density0862-t (150%, matching-binary script staging)','density0862-u (100%, cold start with final pair)']
for name in ('physical-library.png','physical-pattern.png'):
    p=BUILD/name;assert p.is_file();result['evidence'].append({'path':path(p),'sha256':sha(p),'scope':'Observed owned Max 2027 screenshot'})
(DOC/'QUALIFICATION_0862_CORRECTION.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps(artifacts,indent=2))
