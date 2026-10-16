"""Generate bounded synthetic catalogs outside Max, never modify artist libraries."""
from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'build/gallery-0851-20261016-01/catalogs'
source=ROOT/'AminScatter/library';base=json.loads((source/'borders.csrecipe.json').read_text())
presentation=json.loads((source/'borders.csrecipe.json.library.json').read_text());image=presentation['thumbnail']['file']
for count in (128,2000,10000):
 folder=OUT/str(count);folder.mkdir(parents=True,exist_ok=False);shutil.copy2(source/image,folder/image)
 for i in range(count):
  value=dict(base);value['id']='gallery-fixture-'+str(i);value['name']=('Forest duplicate' if i%11==0 else 'Tree catalog '+str(i))+(' باغ' if i%13==0 else '')
  data=json.dumps(value,ensure_ascii=False).encode('utf-8');path=folder/(str(i)+'.csrecipe.json');path.write_bytes(data)
  if i%3==0:
   meta=dict(presentation);meta['recipeSHA256']=hashlib.sha256(data).hexdigest();meta['metadata']={'category':['Garden','Forest','Mountain'][i%7%3],'tags':['synthetic','group-'+str(i%10)],'description':'Owned synthetic metadata-only test entry. Paint is intentionally not hydrated.'}
   Path(str(path)+'.library.json').write_text(json.dumps(meta,ensure_ascii=False),encoding='utf-8')
 (folder/'bad.csrecipe.json').write_text('{')
 print('Generated',count,'entries',flush=True)
