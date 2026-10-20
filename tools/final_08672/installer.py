"""Inert installer transactions: no artist paths or installed payloads."""
from pathlib import Path
import hashlib,json,re,subprocess,uuid
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'build/final-08672-20261020'/('installer-'+uuid.uuid4().hex[:10]);OUT.mkdir()
sha=lambda b:hashlib.sha256(b).hexdigest()
names=re.findall(r'"([^"]+)"',(ROOT/'AminScatter/setup/InstallEngine.cs').read_text().split('static readonly HashSet<string> Runtime =')[1].split('};')[0])
content=OUT/'Content'
data={'Library/Maps/shared.bin':b'Owned texture\n'*7000,'Library/Models/leaf/model.max':b'Owned inert model\n'*3000,'Library/model-catalog.json':b'{"format":"inert qualification data"}'}
for name,value in data.items():
    p=content/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(value)
identity=dict(format='cyrus.scatter.content',schema=2,version='0.86.7',max_year=2024,hosts={'2024':1,'2026':1,'2027':1})
raw=json.dumps(dict(identity,files={n:dict(bytes=len(b),sha256=sha(b)) for n,b in data.items()})).encode()
(content/'content-manifest.json').write_bytes(raw)
import zipfile
with zipfile.ZipFile(OUT/'CyrusScatter-Content-0.86.7.zip','w',zipfile.ZIP_DEFLATED) as z:
 z.writestr('content-manifest.json',raw)
 for name,value in data.items():z.writestr(name,value)
for case,extra in [('traversal','Library/../escape'),('extra','Library/unlisted'),('duplicate','Library/model-catalog.json')]:
 d=OUT/case;d.mkdir()
 with zipfile.ZipFile(d/'CyrusScatter-Content-0.86.7.zip','w') as z:
  z.writestr('content-manifest.json',raw)
  for name,value in data.items():z.writestr(name,value)
  z.writestr(extra,b'bad')
d=OUT/'damaged';d.mkdir()
with zipfile.ZipFile(d/'CyrusScatter-Content-0.86.7.zip','w') as z:
 z.writestr('content-manifest.json',raw)
 for name,value in data.items():z.writestr(name,b'x'*len(value) if name.endswith('model.max') else value)
packages=[]
for year in [2024,2026,2027]:
    base=OUT/f'package{year}';base.mkdir()
    payload={n:('Inert CyrusScatter '+n).encode() for n in names}
    payload['ExternalContent.json']=json.dumps(dict(identity,manifest_sha256=sha(raw))).encode()
    for name,value in payload.items():(base/name).write_bytes(value)
    inv=(f'CyrusScatterInstall1\t0.86.7.2\t{year}\t{sha(str(year).encode())[:12]}\n'+''.join(f'{n}\t{sha(b)}\t{len(b)}\n' for n,b in payload.items())).encode()
    (base/'InstallInventory.txt').write_bytes(inv);packages.append(dict(path=str(base),hash=sha(inv),year=year))
(OUT/'packages.json').write_text(json.dumps(packages))
r=subprocess.run(['powershell.exe','-NoProfile','-NonInteractive','-File',str(ROOT/'tools/final_08672/installer.ps1'),'-Output',str(OUT)],capture_output=True,text=True)
(OUT/'transport.txt').write_text(r.stdout+r.stderr);print(OUT);print(r.stdout+r.stderr);raise SystemExit(r.returncode)
