"""Matched, disposable Max 2027 hosts and serialized test requests only."""
from pathlib import Path
import argparse,hashlib,json,os,sys,time,uuid
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('mode',choices=('launch','send'));p.add_argument('name');p.add_argument('--native',type=Path);p.add_argument('--script',type=Path);p.add_argument('--script-only',action='store_true');p.add_argument('--placement-qualification',action='store_true');a=p.parse_args()
assert a.name.startswith('foundation-memory0854-')
host=ROOT/'build/mcp-qualification'/a.name
if a.mode=='launch':
 sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'));from private_host import launch
 native=a.native.resolve();receipt=json.loads((native/'receipt.json').read_text())
 assert receipt['max_year']==2027 and all(s['exit_code']==0 for s in receipt['stages'])
 mismatches=[name for name,h in receipt['sources'].items() if hashlib.sha256((ROOT/name).read_bytes()).hexdigest()!=h]
 assert not mismatches or (a.script_only and mismatches==['AminScatter/scripts/AminScatterObject.ms']),mismatches
 process,record=launch(host,ROOT/'AminScatter/scripts/AminScatterObject.ms',native,transport=True,max_year=2027,silent_startup=True,script_assets=('CyrusGallery.dll',),placement_qualification=a.placement_qualification)
 if mismatches:
  record['native_reuse']='All native sources match; generated-script-only iteration. Final delivery requires frozen exact-pair qualification.'
  record['native_receipt_sha256']=hashlib.sha256((native/'receipt.json').read_bytes()).hexdigest()
  (host/'launch.json').write_text(json.dumps(record,indent=2))
 print(json.dumps({'pid':process.pid,'profile':str(host)}))
else:
 assert (host/'ready.json').exists() and not (host/'startup-error.txt').exists()
 launch=json.loads((host/'launch.json').read_text());assert Path(launch['output']).resolve()==host and launch['development_transport']
 pointer=host/'dev-request.txt';response=host/'dev-result.txt'
 if pointer.exists():
  previous=pointer.read_text(encoding='utf-8-sig');state=response.read_text(encoding='utf-8-sig')
  assert previous in state and state.startswith(('SUCCESS','ERROR')),'Observe prior request before retrying'
 request=host/('request-'+uuid.uuid4().hex+'.ms');request.write_text(a.script.resolve().read_text(encoding='utf-8-sig'),encoding='utf-8-sig')
 pending=host/('pending-'+uuid.uuid4().hex+'.txt');pending.write_text(request.as_posix(),encoding='utf-8-sig')
 for attempt in range(100):
  try:os.replace(pending,pointer);break
  except PermissionError:
   if attempt==99:raise
   time.sleep(.02)
 print('Submitted',request.name,flush=True)
 deadline=time.monotonic()+45
 while time.monotonic()<deadline:
  try:state=response.read_text(encoding='utf-8-sig') if response.exists() else ''
  except PermissionError:time.sleep(.05);continue
  if request.as_posix() in state:
   print(state);sys.exit(0 if state.startswith('SUCCESS') else 1)
  time.sleep(.2)
 raise TimeoutError('Observe completion before sending another request')
