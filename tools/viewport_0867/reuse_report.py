from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[2];WORK=ROOT/'build/viewport-0867-20261020'
before=json.loads((WORK/'content-manifest-before.json').read_text())
after=json.loads((ROOT/'dist/CyrusScatter-0.86.7-20261020/Content/content-manifest.json').read_text())
assert before['files'].keys()==after['files'].keys()
unchanged={n:d for n,d in after['files'].items() if before['files'][n]==d}
changed=[n for n in after['files'] if n not in unchanged]
assert len(changed)==97 and all(n.endswith('/model.max') or n.endswith('/model-catalog.json') for n in changed)
receipt=json.loads((WORK/'content-saveback.json').read_text())
assert receipt['status']=='passed' and len(receipt['complete'])==96 and not receipt['failures']
result={'status':'passed','unchanged_files':len(unchanged),'unchanged_bytes':sum(d['bytes'] for d in unchanged.values()),
        'models_saved_back':96,'new_geometry_created':False,'previews_regenerated':False,
        'library_path':'dist/CyrusScatter-0.86.7-20261020/Content',
        'old_distribution_content_exists':(ROOT/'dist/CyrusScatter-0.86.6.2-20261020/Content').exists(),
        'note':'Original catalog and artist installation untouched; pre-existing build copy retained.'}
assert not result['old_distribution_content_exists']
(WORK/'content-reuse.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
