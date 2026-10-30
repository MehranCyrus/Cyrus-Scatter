"""Check the delivery's local Markdown targets and durable artifact hashes."""
from pathlib import Path
from urllib.parse import unquote
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[3];DOC=ROOT/'docs/plans/terraces-performance-20261029'
DIST=ROOT/'dist/CyrusScatter-0.87.6.1-20261029'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
checked=0
for p in DOC.glob('*.md'):
    for target in re.findall(r'\]\(([^)]+)\)',p.read_text(encoding='utf-8')):
        target=unquote(target.split('#',1)[0].strip('<>'))
        if not target or '://' in target:continue
        assert (p.parent/target).resolve().exists(),(str(p),target)
        checked+=1
evidence=json.loads((DOC/'EVIDENCE_MANIFEST.json').read_text())
for name,entry in evidence.items():assert sha(DOC/'evidence'/name)==entry['sha256'],name
manifest=json.loads((DIST/'DELIVERY_MANIFEST.json').read_text())
for name,entry in manifest.items():assert sha(DIST/name)==entry['sha256'],name
result=dict(status='passed',local_markdown_targets=checked,evidence_files=len(evidence),delivery_files=len(manifest))
(DOC/'FINAL_CHECK.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result,indent=2))
