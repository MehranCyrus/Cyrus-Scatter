from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[2];WORK=ROOT/'build/viewport-0867-20261020'
OUT=ROOT/'dist/CyrusScatter-0.86.7-20261020'
cleanup=json.loads((WORK/'cleanup.json').read_text(encoding='utf-8-sig'))
assert cleanup['status']=='passed'
evidence=OUT/'Evidence';evidence.mkdir(exist_ok=True)
report=(ROOT/'docs/plans/preset-gallery-improvements/DELIVERY_0867.md').read_text()
for name in ['real-leaves-original.png','real-leaves-corrected.png','real-leaves-edited.png',
             'real-leaves-opacity-off.png','real-leaves-opacity-restored.png']:
    shutil.copy2(ROOT/'build/mcp-qualification/viewport0867-test6-2027'/name,evidence/name)
    report=report.replace('../../../build/mcp-qualification/viewport0867-test6-2027/'+name,'Evidence/'+name)
(OUT/'RELEASE-NOTES.md').write_text(report)
for path in [OUT/'QUALIFICATION.json',WORK/'qualification-final.json']:
    data=json.loads(path.read_text());data['cleanup']=cleanup
    data['evidence_images']={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(evidence.glob('*.png'))}
    path.write_text(json.dumps(data,indent=2)+'\n')
assert (OUT/'Content/content-manifest.json').is_file()
for entry in (OUT/'SHA256SUMS.txt').read_text().splitlines():
    digest,name=entry.split('  ')
    path=OUT/name if name!='content-manifest.json' else OUT/'Content'/name
    assert hashlib.file_digest(path.open('rb'),'sha256').hexdigest()==digest,name
print('Final package hashes, cleanup receipt and leaf evidence ready.')
