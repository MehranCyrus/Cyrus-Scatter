"""Read-only final runtime identity witness in a previously verified private host."""
from pathlib import Path
import hashlib,json,re
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-') and 'meshmask' in OUT.name
manifest=json.loads((OUT/'runtime.json').read_text())
script=ROOT/'AminScatter/scripts/AminScatterObject.ms'
expected=re.match(r'global CyrusLoadedScriptFingerprint="([0-9a-f]{64})"',script.read_text()).group(1)
assert manifest['status']=='loaded'
assert hashlib.sha256(Path(manifest['script']).read_bytes()).hexdigest()==hashlib.sha256(script.read_bytes()).hexdigest()==manifest['script_sha256']
assert str(r.CyrusLoadedScriptFingerprint)==expected and int(r.cyrusMeshDensityVersion())==1
instance=r.createInstance(r.AminScatterObject)
assert str(instance.uiVersion())=='0.82.4'
data={'status':'passed','version':str(instance.uiVersion()),'native_capability':int(r.cyrusMeshDensityVersion()),
    'loaded_script_payload_sha256':expected,'script_file_sha256':manifest['script_sha256'],
    'verified_runtime_manifest':'runtime.json','native_binaries':manifest['binaries'],
    'preview_budget_integer_check':int(r.execute('(amax 1 ((2048/3) as integer))*3'))}
assert data['preview_budget_integer_check']<=2048
(OUT/'mesh-mask-final-identity.json').write_text(json.dumps(data,indent=2)+'\n')
