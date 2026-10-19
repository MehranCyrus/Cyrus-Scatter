"""Check current delivery links, artifacts, source freeze and owned-host teardown."""
from pathlib import Path
import hashlib,json,re,subprocess,urllib.parse
ROOT=Path(__file__).resolve().parents[2]
DOC=ROOT/'docs/plans/preset-gallery-improvements'
receipt=json.loads((DOC/'QUALIFICATION_0862.json').read_text(encoding='utf-8'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for name,digest in {**receipt['sources'],**receipt['binaries']}.items():assert sha(ROOT/name)==digest,name
for item in receipt['artifacts'].values():assert sha(ROOT/item['path'])==item['sha256'],item['path']
files=('README.md','AminScatter/README.md','docs/README.md','docs/ARTIST_GUIDE.md','docs/ARCHITECTURE.md','docs/Current_System_2026-10-05/CAPABILITY_MATRIX.md','docs/Max_2027_Installation.md','docs/Release_Versioning.md','docs/BACKLOG.md','docs/plans/improvement-program/PROGRESS.md','docs/plans/preset-gallery-improvements/README.md','docs/plans/preset-gallery-improvements/ARTIST_WORKFLOW.md','docs/plans/preset-gallery-improvements/PACKAGE_CONTRACT.md','docs/plans/preset-gallery-improvements/INSTALLER_CONTRACT.md','docs/plans/preset-gallery-improvements/BROWSER_LAYOUT.md','docs/plans/preset-gallery-improvements/DELIVERY_0862.md')
links=0
for name in files:
    path=ROOT/name;text=path.read_text(encoding='utf-8')
    for value in re.findall(r'\]\(([^\n]+?)\)',text):
        target=value.split('#',1)[0].strip('<>')
        if not target or re.match(r'^[a-z]+:',target,re.I):continue
        target=urllib.parse.unquote(target)
        assert (path.parent/target).exists(),(name,target)
        links+=1
head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
assert head==receipt['git_head']
processes=json.loads(subprocess.check_output(['powershell','-NoProfile','-Command',"@(Get-CimInstance Win32_Process -Filter \"name='3dsmax.exe'\" | Select-Object ProcessId,CommandLine) | ConvertTo-Json -Compress"],text=True))
assert all('density0862-' not in (p['CommandLine'] or '') for p in processes),processes
assert {1416,45684}.issubset({p['ProcessId'] for p in processes}),processes
result={'passed':True,'local_links':links,'source_and_artifact_hashes_unchanged':True,'git_head':head,'owned_test_hosts_remaining':0,'preserved_artist_pids':[1416,45684],'docs':{name:sha(ROOT/name) for name in files},'knowledge_activation_performed':False}
out=ROOT/'build/density-recipes-0862-20261018-01/delivery-checks/documentation.json'
out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
receipt['final_documentation_check']={'path':str(out.relative_to(ROOT)),'sha256':sha(out),'local_links':links}
receipt['owned_test_hosts_remaining']=0
(DOC/'QUALIFICATION_0862.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k!='docs'},indent=2))
