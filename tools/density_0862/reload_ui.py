"""Stage script-only revisions in an owned host when every loaded binary is identical."""
from pathlib import Path
import argparse,hashlib,json,re,sys,time
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/native_placement'));from run_generation import send,ready
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('--native',type=Path,required=True);a=p.parse_args();assert re.fullmatch(r'density0862-[a-z]+',a.host)
host=ROOT/'build/mcp-qualification'/a.host;ready(host);native=a.native.resolve();receipt=json.loads((native/'receipt.json').read_text(encoding='utf-8'))
assert receipt['max_year']==2027 and all(s['exit_code']==0 for s in receipt['stages'])
sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
launch=json.loads((host/'launch.json').read_text(encoding='utf-8'));assert launch['max_year']==2027
for name,digest in launch['binaries'].items():assert sha(host/'bin'/name)==sha(native/name)==digest,name
assert sha(host/'scripts/CyrusGallery.dll')==sha(native/'CyrusGallery.dll')
for name,digest in receipt['sources'].items():assert sha(ROOT/name)==digest,name
script=host/'scripts/CyrusScatter.ms';before=sha(script);script.write_bytes((ROOT/'AminScatter/scripts/AminScatterObject.ms').read_bytes())
request=host/'reload-matched-ui.ms'
request.write_text('''(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 for dialog in #(CyrusRecipeBrowser,CyrusRecipeSaveEditor,CyrusReadyPresetEditor,CyrusPresetSaveEditor) where dialog!=undefined do destroyDialog dialog
 CyrusClearMeshMaskPreview undefined
 resetMaxFile #noPrompt
 DNode=DRoot=DLayer=DTerrain=DModel=undefined
 gc light:true
 fileIn (MCPFixtureDir+"scripts/CyrusScatter.ms")
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"loaded-script-stage.txt") CyrusLoadedScriptFingerprint
)
''',encoding='utf-8-sig')
send(host,request,'Stage matching UI revision in empty owned scene')
expected=re.search(r'CyrusLoadedScriptFingerprint="([a-f0-9]+)"',script.read_text(encoding='utf-8'))[1]
assert (host/'loaded-script-stage.txt').read_text(encoding='utf-8-sig')==expected
path=host/'script-staging-history.json';history=json.loads(path.read_text()) if path.exists() else []
history.append({'utc_epoch':time.time(),'previous_script_sha256':before,'script_sha256':sha(script),'fingerprint':expected,'native_receipt_sha256':sha(native/'receipt.json'),'binaries_unchanged':True})
path.write_text(json.dumps(history,indent=2)+'\n',encoding='utf-8');print('Verified source-matched UI stage',a.host)
