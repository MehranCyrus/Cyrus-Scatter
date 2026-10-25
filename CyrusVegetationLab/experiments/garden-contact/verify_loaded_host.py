"""Preflight: verify actual process module paths/hashes before the host probe."""
from pathlib import Path
import hashlib,json,re
from pymxs import runtime as rt
_root=Path(r'F:/Cursor/_Cyrus_Apps/CyrusScatter')
_package=_root/'build/garden-investigation-20261025-01/scatter-payload'
_expected={name:_package/name for name in ['AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm']}
_expected['CyrusStemInspect.dlx']=_root/'build/vegetation-root-plugin-20261025-03/CyrusStemInspect.dlx'
_modules=rt.execute('(local p=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(); for i=0 to p.Modules.Count-1 collect #(p.Modules.Item[i].ModuleName,p.Modules.Item[i].FileName))')
_loaded={str(row[0]).lower():Path(str(row[1])) for row in _modules}
_result={}
for _name,_path in _expected.items():
    _actual=_loaded[_name.lower()]
    assert _actual.resolve()==_path.resolve(), 'Different loaded module: '+_name
    _result[_name]={'path':str(_actual),'sha256':hashlib.sha256(_actual.read_bytes()).hexdigest()}
_script=(_package/'CyrusScatter.ms').read_text(encoding='utf-8-sig')
_fp=re.search(r'CyrusLoadedScriptFingerprint="([0-9a-f]+)"',_script).group(1)
assert str(rt.CyrusLoadedScriptFingerprint)==_fp,'Loaded script fingerprint differs'
assert int(rt.maxVersion()[0])==29000,'Max 2027 required'
(Path(str(rt.GardenRun))/'loaded-identity.json').write_text(json.dumps({'status':'pass','host':2027,'native':_result,'loaded_script_fingerprint':_fp,'script_sha256':hashlib.sha256((_package/'CyrusScatter.ms').read_bytes()).hexdigest()},indent=2))
