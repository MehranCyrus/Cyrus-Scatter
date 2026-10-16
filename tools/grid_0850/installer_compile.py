"""Compile the expanded installer as an uncalled function; do not install."""
from pathlib import Path
import hashlib,json
from pymxs import runtime as r
ROOT=Path(__file__).resolve().parents[2];OUT=Path(str(r.MCPFixtureDir)).resolve()
assert OUT.parent==ROOT/'build/mcp-qualification' and OUT.name.startswith('foundation-roadmap-grid0850-')
folder=ROOT/'dist/CyrusScatter-0.85.0-20261016';script=folder/'expanded-install.ms'
source=script.read_text(encoding='utf-8');r.execute('global CyrusInstallerCompileOnly\nfn CyrusInstallerCompileOnly = (\n'+source+'\n)')
assert r.CyrusInstallerCompileOnly is not None
files=r.execute((folder/'expanded-library-files.ms').read_text());assert len(files)==27
result={'status':'passed','installer_sha256':hashlib.sha256(script.read_bytes()).hexdigest(),'bundled_file_count':len(files),'installed':False,'scope':'Actual Max compilation, function never invoked; inventory array evaluated as data only.'}
(OUT/'installer-compile.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
