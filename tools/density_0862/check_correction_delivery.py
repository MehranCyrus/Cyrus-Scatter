"""Verify the correction without rewriting the original qualification receipt."""
from pathlib import Path
import hashlib,json,re,subprocess,urllib.parse
ROOT=Path(__file__).resolve().parents[2]
BUILD=ROOT/'build/density-0862-correction-20261019'
DOC=ROOT/'docs/plans/preset-gallery-improvements'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
receipt=json.loads((DOC/'QUALIFICATION_0862_CORRECTION.json').read_text(encoding='utf-8'))
assert sha(DOC/'QUALIFICATION_0862.json')==receipt['original_qualification_sha256']
for name,digest in {**receipt['sources'],**receipt['binaries']}.items():assert sha(ROOT/name)==digest,name
for item in receipt['artifacts'].values():assert sha(ROOT/item['path'])==item['sha256'],item['path']
for item in receipt['evidence']:assert sha(ROOT/item['path'])==item['sha256'],item['path']
files=('README.md','docs/BACKLOG.md','docs/plans/improvement-program/PROGRESS.md','docs/plans/preset-gallery-improvements/DELIVERY_0862.md')
links=0
for name in files:
    path=ROOT/name;text=path.read_text(encoding='utf-8')
    for value in re.findall(r'\]\(([^\n]+?)\)',text):
        target=value.split('#',1)[0].strip('<>')
        if not target or re.match(r'^[a-z]+:',target,re.I):continue
        assert (path.parent/urllib.parse.unquote(target)).exists(),(name,target)
        links+=1
head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
assert head==receipt['git_head']
processes=json.loads(subprocess.check_output(['powershell','-NoProfile','-Command',"@(Get-CimInstance Win32_Process -Filter \"name='3dsmax.exe'\" | Select-Object ProcessId,CommandLine) | ConvertTo-Json -Compress"],text=True))
if isinstance(processes,dict):processes=[processes]
assert all('density0862-' not in (p['CommandLine'] or '') for p in processes),processes
installed=Path('C:/Users/Mehran/AppData/Local/Autodesk/3dsMax/2027 - 64bit/ENU/scripts/CyrusScatter/Releases/0.86.2-1bb44604fb5d/CyrusScatter.ms')
assert sha(installed)=='d18694039c99e2ab61cd557ea38ad5ca4a10f54f85b5cf866bbf751dbe23c82a'
result={'passed':True,'local_links':links,'source_and_artifact_hashes_unchanged':True,'git_head':head,'owned_test_hosts_remaining':0,'remaining_max_process_ids':[p['ProcessId'] for p in processes],'installed_original_script_unchanged':True,'docs':{name:sha(ROOT/name) for name in files},'knowledge_activation_performed':False}
out=BUILD/'documentation-check.json';out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k!='docs'},indent=2))
