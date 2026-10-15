"""Launch a fresh, isolated terrace qualification process from a matched build."""
from pathlib import Path
import argparse,hashlib,json,sys,time
ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('name');parser.add_argument('--baseline',action='store_true')
parser.add_argument('--native',type=Path)
parser.add_argument('--year',type=int,choices=(2026,2027),default=2027)
args=parser.parse_args()
assert args.name.startswith('foundation-terrace0815-') and Path(args.name).name==args.name
native=args.native or ROOT/'build/performance-0.81.3-20261013-01/native-2027-01'
source=ROOT/'build/terrace-0815-20261013-01/baseline-source' if args.baseline else ROOT
script=source/'AminScatter/scripts/AminScatterObject.ms'
receipt=json.loads((native/'receipt.json').read_text())
assert receipt['max_year']==args.year,'Build/host year mismatch'
def digest(path):
    value=hashlib.sha256()
    with Path(path).open('rb') as stream:
        for block in iter(lambda:stream.read(8*1024*1024),b''):value.update(block)
    return value.hexdigest()
for name,expected in receipt['sources'].items():assert digest(source/name)==expected,name
for name,expected in receipt['binaries'].items():assert digest(native/Path(name).name)==expected,name
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import launch
folder=ROOT/'build/mcp-qualification'/args.name
process,metadata=launch(folder,script,native,transport=True,max_year=args.year,silent_startup=True)
print(json.dumps(metadata),flush=True)
deadline=time.monotonic()+180
while time.monotonic()<deadline:
    if (folder/'startup-error.txt').exists():raise RuntimeError((folder/'startup-error.txt').read_text(encoding='utf-8-sig'))
    if (folder/'ready.json').exists():print('Owned terrace host ready',flush=True);break
    if process.poll() is not None:raise RuntimeError('Owned host exited before readiness')
    time.sleep(.5)
else:raise TimeoutError('Inspect this exact owned process before retrying')
