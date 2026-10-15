"""Preserve the user scene and launch an owned matched baseline Max process."""
from pathlib import Path
import hashlib,json,shutil,subprocess,sys,time

ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'build/terrace-0815-20261013-01'
SCENES=ROOT/'Test Scene/Terraces_0815'
ORIGINAL=ROOT/'Test Scene/Terraces Buiding Test.max'
NATIVE=ROOT/'build/performance-0.81.3-20261013-01/native-2027-01'
HOST=ROOT/'build/mcp-qualification/foundation-terrace0815-baseline2027-01'
SCRIPT=ROOT/'AminScatter/scripts/AminScatterObject.ms'

def digest(path):
    h=hashlib.sha256()
    with Path(path).open('rb') as stream:
        for block in iter(lambda:stream.read(8*1024*1024),b''):h.update(block)
    return h.hexdigest()

WORK.mkdir(parents=True,exist_ok=False)
SCENES.mkdir(parents=True,exist_ok=False)
copy=SCENES/'Terraces_0815_Baseline.max'
shutil.copy2(ORIGINAL,copy)
original_hash=digest(ORIGINAL)
assert digest(copy)==original_hash
source_receipt=json.loads((NATIVE/'receipt.json').read_text())
for path,value in source_receipt['sources'].items():assert digest(ROOT/path)==value,path
for name,value in source_receipt['binaries'].items():assert digest(NATIVE/name)==value,name
assert digest(SCRIPT)=='803df45bb17ec88e9d15fcf42b130d5e5b55df93c1f7621131cfb2497f604d32'
snapshot=WORK/'baseline-source'
for path in source_receipt['sources']:
    target=snapshot/path;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/path,target)
shutil.copy2(SCRIPT,snapshot/'AminScatter/scripts/AminScatterObject.ms')
receipt={'original_scene':str(ORIGINAL),'original_sha256':original_hash,'scene_copy':str(copy),
         'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
         'tracked_status':subprocess.check_output(['git','status','--short','--untracked-files=no'],cwd=ROOT,text=True).splitlines(),
         'native_build':str(NATIVE),'script_sha256':digest(SCRIPT)}
(WORK/'baseline.json').write_text(json.dumps(receipt,indent=2)+'\n')
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import launch
process,metadata=launch(HOST,SCRIPT,NATIVE,transport=True,max_year=2027,silent_startup=True)
print(json.dumps(metadata),flush=True)
deadline=time.monotonic()+180
while time.monotonic()<deadline:
    if (HOST/'startup-error.txt').exists():raise RuntimeError((HOST/'startup-error.txt').read_text(encoding='utf-8-sig'))
    if (HOST/'ready.json').exists():print('Owned terrace baseline host ready',flush=True);break
    if process.poll() is not None:raise RuntimeError('Owned host exited before readiness')
    time.sleep(.5)
else:raise TimeoutError('Inspect this exact owned process before retrying')
