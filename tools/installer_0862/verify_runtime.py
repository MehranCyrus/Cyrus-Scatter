"""Hash every installed runtime asset and the gallery actually loaded in Max."""
from pathlib import Path
import hashlib,json
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];out=Path(str(r.MCPFixtureDir));assert out.name.startswith('density0862-installer-')
meta=json.loads((out/'launch.json').read_text());year=meta['max_year'];release=Path(meta['installed_release']);assert release.is_relative_to(Path(meta['short_profile']))
package=json.loads((ROOT/'build/installer-0862-20261019-01/package03/candidate.json').read_text())['packages'][str(year)]
native={'AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm'};files=[]
for name,record in package['logical_inventory'].items():
 relative=('bin/'+name) if name in native else 'Library-0.86.2/'+name[8:] if name.startswith('Library/') else name
 path=release/relative;assert hashlib.sha256(path.read_bytes()).hexdigest()==record['sha256'],name;assert path.stat().st_size==record['bytes'];files.append({'path':str(path),'sha256':record['sha256']})
paths=r.execute('''(local paths=#(),domain=(dotNetClass "System.AppDomain").CurrentDomain
for a in domain.GetAssemblies() do (local n=a.GetName();if n.Name=="CyrusGallery" do append paths a.Location)
paths)''')
assert len(paths)==1 and Path(str(paths[0])).resolve()==(release/'CyrusGallery.dll').resolve(),str(paths)
(out/'installed-runtime.json').write_text(json.dumps({'status':'passed','year':year,'release':str(release),'gallery_assembly':str(paths[0]),'files':files,'max_absolute_path':max(len(x['path']) for x in files)},indent=2)+'\n')
