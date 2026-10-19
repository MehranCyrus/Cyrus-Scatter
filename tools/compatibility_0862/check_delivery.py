"""Final immutable artifact, source-preservation and navigation audit."""
from pathlib import Path
import csv, hashlib, json, re, subprocess
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/compatibility-0862-20261019'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
baseline=load(BASE/'baseline.json');receipt=load(ROOT/'docs/plans/preset-gallery-improvements/QUALIFICATION_0862_COMPATIBILITY.json')
changed=[name for name,digest in baseline['files'].items() if not (ROOT/name).is_file() or sha(ROOT/name)!=digest]
assert changed==['AminScatter/README.md'],changed
for artifact in receipt['artifacts'].values():assert sha(ROOT/artifact['path'])==artifact['sha256']
for item in receipt['evidence']:assert sha(ROOT/item['path'])==item['sha256'],item['path']
for data in receipt['pairs'].values():
    native=load(ROOT/data['native_receipt']['path'])
    for key in ('sources','binaries'):
        for name,digest in native[key].items():assert sha(ROOT/name)==digest,name
report=ROOT/'docs/plans/preset-gallery-improvements/DELIVERY_0862.md'
current=report.read_text(encoding='utf-8').split('## Qualified UI follow-up')[0]
for link in re.findall(r'\]\(([^)]+)\)',current):assert (report.parent/link).resolve().exists(),link
rows=list(csv.DictReader((ROOT/'docs/documentation-inventory.csv').open(encoding='utf-8',newline='')))
assert len({r['path'] for r in rows})==len(rows)
assert any(r['path'].endswith('/QUALIFICATION_0862_COMPATIBILITY.json') for r in rows)
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()==baseline['head']
result={'status':'passed','plugin_implementation_changed':False,'source_doc_changed':changed,'current_links_valid':True,
        'artifacts_verified':receipt['artifacts'],'git_head':baseline['head'],
        'owned_hosts_closed':[(ROOT/'build/mcp-qualification'/name/'shutdown.txt').is_file() for name in ('density0862-compat-backsave01','density0862-compat-max2026-01')],
        'artist_installation':False,'knowledge_activation':False,'git_push':False}
assert all(result['owned_hosts_closed'])
(BASE/'final-review.json').write_text(json.dumps(result,indent=2)+'\n')
print('PASS: artifact hashes, unchanged plugin sources, receipt evidence, navigation, inventory, Git identity and owned-host closure')
