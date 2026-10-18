"""500k and one-million sparse/all-selection history in the final private host."""
import argparse,hashlib,json,re,time
from run_generation import ROOT,ready,send
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args()
assert a.host.startswith('foundation-memory0854-nativeaccept-controller-')
h=ROOT/'build/mcp-qualification'/a.host;ready(h)
source=(ROOT/'tools/native_placement/edit_controller.ms').read_text(encoding='utf-8-sig')
source=re.sub(r'\bNCRoot\.procNativeRoute=(?:true|false)\b;?','',source)
receipts=[]
for count in (500000,1000000):
    fixture=h/f'large-edit-{count}.ms'
    fixture.write_text(source.replace('200000',str(count)).replace('200k',str(count)))
    begin=time.monotonic()
    for phase in ('memory','memoryUndo','memoryRedo','abandon'):send(h,fixture,phase)
    receipts.append(dict(count=count,status='passed',seconds=time.monotonic()-begin,
        fixture_sha256=hashlib.sha256(fixture.read_bytes()).hexdigest()))
    (h/'large-edit.json').write_text(json.dumps(receipts,indent=2)+'\n')
print('LARGE SPARSE AND ALL-SELECTION EDIT HISTORY PASSED',flush=True)
