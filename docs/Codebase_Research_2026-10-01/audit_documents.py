"""Mechanical link/ledger/run checks supporting the report's human self-audit."""
from research_tools import ROOT,HERE,EVIDENCE,digest,record,stamp
from pathlib import Path
import csv,json,re

entries=[json.loads(line) for line in (EVIDENCE/'read-coverage.jsonl').read_text().splitlines()]
with (EVIDENCE/'read-coverage.csv').open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.writer(f);w.writerow(['path','requested_line_ranges','total_lines','sha256','note'])
    for path in dict.fromkeys(x['path'] for x in entries):
        group=[x for x in entries if x['path']==path];spans=[]
        for start,end in sorted((x['start'],x['end']) for x in group):
            if spans and start<=spans[-1][1]+1:spans[-1][1]=max(spans[-1][1],end)
            else:spans.append([start,end])
        w.writerow([path,'; '.join(f'{a}-{b}' for a,b in spans),group[-1]['total_lines'],group[-1]['sha256'],
                    'Requested reads; see COVERAGE.md for truncation and scope limits'])

missing=[];bad_lines=[];link_count=0
for p in HERE.glob('*.md'):
    text=p.read_text(encoding='utf-8')
    for dest in re.findall(r'\]\((F:/[^)]+)\)',text):
        dest=dest.strip('<>');line=None
        m=re.search(r':(\d+)$',dest)
        if m:line=int(m[1]);dest=dest[:m.start()]
        target=Path(dest);link_count+=1
        if not target.exists():missing.append(dict(document=p.name,target=dest))
        elif line and (not target.is_file() or line>len(target.read_text(encoding='utf-8-sig',errors='replace').splitlines())):
            bad_lines.append(dict(document=p.name,target=dest,line=line))

with (HERE/'claims.csv').open(encoding='utf-8-sig',newline='') as f:claims=list(csv.DictReader(f))
with (HERE/'decisions.csv').open(encoding='utf-8-sig',newline='') as f:decisions=list(csv.DictReader(f))
ids={x['id'] for x in claims}
assert len(ids)==len(claims)
assert len({x['id'] for x in decisions})==len(decisions)
assert all(all(v for v in row.values()) for row in claims+decisions)
assert all(set(x['claim_ids'].split(','))<=ids for x in decisions)
threads=json.loads((EVIDENCE/'threads-summary.json').read_text())
assert len(threads['cases'])==17
assert all(x['1']['n']==x['0']['n']==21 for x in threads['cases'])
projection=json.loads((EVIDENCE/'projection-summary.json').read_text())
assert projection['tie']['drop_in_identity_equivalent'] is False
assert all(x['trials']==9 and x['position_mismatches']==x['triangle_mismatches']==0 for x in projection['cases'])
verified=[]
for fixture in ['max2027_smoke','compute_performance_smoke','viewport_performance_smoke']:
    run=json.loads((EVIDENCE/f'verified-v4-{fixture}-run.json').read_text())
    identity=json.loads((EVIDENCE/f'verified-v4-{fixture}-identity.json').read_text())
    assert run['returncode']==0 and 'SUCCESS' in run['result'] and identity['expected_modules_present']
    assert run['fixture_sha256']==run['copy_sha256']
    assert len(identity['modules'])==4
    assert all(digest(Path(m['path']))==m['sha256'] for m in identity['modules'])
    verified.append(fixture)
record('document-audit.json',dict(audited_utc=stamp(),scope='Self-audit; mechanical checks supplement source/claim review',
       local_links=link_count,missing_links=missing,bad_line_links=bad_lines,claims=len(claims),decisions=len(decisions),
       verified_host_fixtures=verified,native_timing_cases=17,projection_random_mismatches=0,
       projection_adversarial_tie_equivalent=False))
print(json.dumps(dict(local_links=link_count,missing=missing,bad_lines=bad_lines,claims=len(claims),decisions=len(decisions),verified_hosts=verified),indent=2))
if missing or bad_lines:raise RuntimeError('Invalid document links')
