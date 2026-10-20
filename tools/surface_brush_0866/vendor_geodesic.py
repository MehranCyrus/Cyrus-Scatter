"""Fetch the pinned MIT dependency; retain upstream bytes and SHA provenance."""
from pathlib import Path
import hashlib, json, urllib.request
ROOT=Path(__file__).resolve().parents[2]
COMMIT='8106598e5575c44ec2d74965362459e1c421896a'
BASE=f'https://raw.githubusercontent.com/mhogg/pygeodesic/{COMMIT}/'
names=('geodesic_algorithm_base.h','geodesic_algorithm_exact.h',
       'geodesic_algorithm_exact_elements.h','geodesic_constants_and_simple_functions.h',
       'geodesic_memory.h','geodesic_mesh.h','geodesic_mesh_elements.h')
out=ROOT/'AminScatter/third_party/geodesic';out.mkdir(parents=True,exist_ok=True)
receipts={}
for name in (*names,'LICENSE'):
    url=BASE+('LICENSE' if name=='LICENSE' else 'pygeodesic/geodesic_kirsanov/'+name)
    data=urllib.request.urlopen(url,timeout=30).read()
    (out/name).write_bytes(data)
    receipts[name]={'url':url,'sha256':hashlib.sha256(data).hexdigest()}
(out/'UPSTREAM.json').write_text(json.dumps({'repository':'https://github.com/mhogg/pygeodesic',
    'commit':COMMIT,'original_author':'Danil Kirsanov, 2008, MIT',
    'files':receipts},indent=2)+'\n',encoding='utf-8')
print(out)
