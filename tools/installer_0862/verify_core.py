"""Verify the exact installer assembly loaded by the owned MZP host adapter."""
from pathlib import Path
import hashlib,json,zipfile
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];out=Path(str(r.MCPFixtureDir));assert out.name.startswith('density0862-installer-')
year=json.loads((out/'launch.json').read_text())['max_year'];package=ROOT/f'build/installer-0862-20261019-01/package03/CyrusScatter-0.86.2-Max{year}.mzp'
with zipfile.ZipFile(package) as z:expected=hashlib.sha256(z.read('CyrusInstaller.dll')).hexdigest()
paths=r.execute('''(local paths=#(),domain=(dotNetClass "System.AppDomain").CurrentDomain
for a in domain.GetAssemblies() do (local n=a.GetName();if n.Name=="CyrusInstaller" do append paths a.Location)
paths)''')
rows=[{'path':str(path),'sha256':hashlib.sha256(Path(str(path)).read_bytes()).hexdigest()} for path in paths]
assert len(rows)==1 and rows[0]['sha256']==expected,rows
(out/'loaded-installer.json').write_text(json.dumps({'status':'passed','expected_sha256':expected,'assemblies':rows},indent=2)+'\n')
