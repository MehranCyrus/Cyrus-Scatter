"""Check current documentation links and final delivery identities."""
from pathlib import Path
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/presets-0853-20261016-01'
names=['README.md','docs/ARTIST_GUIDE.md','docs/Release_Versioning.md','docs/ARCHITECTURE.md','docs/BACKLOG.md','docs/plans/preset-gallery-improvements/LOAD_0853.md','docs/plans/preset-gallery-improvements/ARTIST_WORKFLOW.md']
checked=0
for name in names:
    path=ROOT/name;text=path.read_text(encoding='utf-8')
    for target in re.findall(r'\]\(([^\n]+?)\)',text):
        target=target.strip('<>').split('#')[0]
        if not target or re.match(r'^(https?://|mailto:)',target):continue
        candidate=Path(target) if re.match(r'^[A-Za-z]:[/\\]',target) else path.parent/target
        assert candidate.exists(),(name,target)
        checked+=1
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
package=json.loads((ROOT/'docs/plans/preset-gallery-improvements/PACKAGE_0853.json').read_text())
for item in package['artifacts']:assert sha(ROOT/item['path'])==item['sha256']
site=json.loads((ROOT/'website/verification/react-static-checks.json').read_text());assert site['status']=='PASS' and site['development_version']=='0.85.3'
report={'status':'passed','local_links':checked,'documents':{name:sha(ROOT/name) for name in names},'website_sources_checked':True,'website_build':'tsc and Vite passed; observed terminal receipt','website_published':False,'artist_profile_installed':False,'git_pushed':False}
(BASE/'documentation-check.json').write_text(json.dumps(report,indent=2)+'\n')
print('PASS',checked,'local links; artifact hashes and website static receipt')
