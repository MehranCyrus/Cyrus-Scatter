"""Inert multi-host content reuse/transaction fixtures in owned folders."""
from pathlib import Path
import hashlib,json,re,subprocess,uuid
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'build/viewport-0867-20261020'/('installer-'+uuid.uuid4().hex[:10])
OUT.mkdir()
sha=lambda b:hashlib.sha256(b).hexdigest()
source=(ROOT/'AminScatter/setup/InstallEngine.cs').read_text()
names=re.findall(r'"([^"]+)"',source.split('static readonly HashSet<string> Runtime =')[1].split('};')[0])
packages=[]
for version,year in [('0.86.6.2',2027),('0.86.7',2027),('0.86.7',2024),('0.86.7',2026)]:
    base=OUT/f'{version}-{year}';base.mkdir()
    content=base/'Content';(content/'Library/Maps').mkdir(parents=True)
    files={'Library/Maps/reused.bin':b'Existing prepared content\n'*50000,'Library/model-catalog.json':version.encode()}
    for name,data in files.items():(content/name).write_bytes(data)
    identity=dict(format='cyrus.scatter.content',schema=2,version=version,max_year=2024,hosts={'2024':1,'2026':1,'2027':1})
    raw=json.dumps(dict(identity,files={n:dict(bytes=len(b),sha256=sha(b)) for n,b in files.items()})).encode()
    (content/'content-manifest.json').write_bytes(raw)
    payload={n:('Owned inert payload CyrusScatter CyrusScatterCreate '+n).encode() for n in names}
    payload['ExternalContent.json']=json.dumps(dict(identity,manifest_sha256=sha(raw))).encode()
    for name,data in payload.items():(base/name).write_bytes(data)
    inventory=(f'CyrusScatterInstall1\t{version}\t{year}\t{sha(raw)[:12]}\n'+''.join(f'{n}\t{sha(b)}\t{len(b)}\n' for n,b in payload.items())).encode()
    (base/'InstallInventory.txt').write_bytes(inventory)
    packages.append(dict(path=str(base),hash=sha(inventory),year=year,version=version))
(OUT/'packages.json').write_text(json.dumps(packages))
command=['powershell.exe','-NoProfile','-NonInteractive','-File',str(ROOT/'tools/viewport_0867/installer.ps1'),'-Output',str(OUT)]
result=subprocess.run(command,text=True,capture_output=True)
(OUT/'transport.txt').write_text(result.stdout+result.stderr)
print(OUT);print(result.stdout+result.stderr)
raise SystemExit(result.returncode)
