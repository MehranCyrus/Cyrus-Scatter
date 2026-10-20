"""Reload only a proven script-only pair in an owned disposable reliability host."""
from pathlib import Path
import argparse, hashlib, json, re, sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send,ready
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('host');p.add_argument('--pair',type=Path,required=True);a=p.parse_args()
assert re.fullmatch(r'density0862-reliability-[a-z0-9-]+',a.host)
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
launch=json.loads((host/'launch.json').read_text());pair=a.pair.resolve()
receipt=json.loads((pair/'receipt.json').read_text())
assert launch['max_year']==receipt['max_year']==2027 and receipt.get('script_only_revision')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for name,digest in receipt['sources'].items():assert sha(ROOT/name)==digest,name
for name,digest in launch['binaries'].items():assert sha(host/'bin'/name)==sha(pair/name)==digest,name
assert sha(host/'scripts/CyrusGallery.dll')==sha(pair/'CyrusGallery.dll')
target=host/'scripts/CyrusScatter.ms';original=sha(target)
target.write_bytes((ROOT/'AminScatter/scripts/AminScatterObject.ms').read_bytes())
reload=host/'reload-paired-script.ms'
reload.write_text('''(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-reliability-*/" do throw "Owned reliability profile required"
 CyrusClearMeshMaskPreview undefined
 resetMaxFile #noPrompt
 gc light:false
 fileIn (MCPFixtureDir+"scripts/CyrusScatter.ms")
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"candidate-fingerprint.txt") CyrusLoadedScriptFingerprint
)
''',encoding='utf-8-sig')
send(host,reload,'Stage matched script revision')
fingerprint=re.search(r'CyrusLoadedScriptFingerprint="([a-f0-9]+)"',target.read_text())[1]
assert (host/'candidate-fingerprint.txt').read_text(encoding='utf-8-sig')==fingerprint
(host/'script-stage.json').write_text(json.dumps({'original_script_sha256':original,'script_sha256':sha(target),
 'pair_receipt':str(pair/'receipt.json'),'pair_receipt_sha256':sha(pair/'receipt.json'),
 'loaded_fingerprint':fingerprint,'native_binaries_unchanged':True,'max_year':2027},indent=2)+'\n')
