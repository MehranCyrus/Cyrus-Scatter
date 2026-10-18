"""Shipping native-only qualification; comparison fixtures remain immutable."""
import argparse,re,time
from run_generation import ROOT,ready,send
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('mode',choices=('goldens','controller','edit','outputs','preparation','fields'));a=p.parse_args()
assert a.host.startswith('foundation-memory0854-nativeaccept-controller-')
h=ROOT/'build/mcp-qualification'/a.host;ready(h)
helper=h/'shipping-helper.ms';helper.write_text('''global NGAllCoveredSame
fn NGAllCoveredSame a b=(for stage=2 to a.count where a[stage][1] do for k=2 to a[stage].count where a[stage][k]!=b[stage][k] do return false;true)
if cyrusPlacementNativeVersion()!=2 do throw "Shipping native capability required"
cyrusPlacementTransportStats true
''');send(h,helper,'helpers')
def native_fixture(name):
 s=(ROOT/'tools/native_placement'/name).read_text(encoding='utf-8-sig')
 # Remove only retired test-route assignments. These are native-only tests,
 # not new A/B evidence; earlier frozen pair receipts retain the A/B claims.
 s=re.sub(r'\b(?:NCRoot|root)\.procNativeRoute=(?:true|false)\b;?','',s)
 s=s.replace('equals legacy controller output','equals native repeat fingerprint')
 s=s.replace('full ordered output matches comparison','full ordered output remains stable')
 s=s.replace('Old authored stack on native and comparison routes','Old authored stack and unchanged native repeat')
 path=h/('shipping-'+name);path.write_text(s);return path
controller=native_fixture('controller.ms')
if a.mode=='goldens':
 original=ROOT/'build/mcp-qualification/foundation-memory0854-nativeaccept-controller-20261018-11'
 files=sorted(original.glob('golden-*.max'),key=lambda f:int(f.stem.split('-')[1]));assert len(files)==50
 script=h/'shipping-golden.ms'
 for f in files:
  expected,kind,label=f.with_suffix('.txt').read_text(encoding='utf-8-sig').splitlines()
  script.write_text('''(
   loadMaxFile @"'''+f.as_posix()+'''" quiet:true useFileUnits:true
   local node=getNodeByName "Native controller",root=node.baseObject
   if isProperty root #procNativeRoute do throw "Retired comparison route must not ship"
   root.procExplicitUpdate=true;root.refreshAll();root.procExplicitUpdate=false
   for leaf in root.layerObjects where leaf.previewError!="" do throw leaf.previewError
   local hash=cyrusPlacementPublicationFingerprint root.groupSnapshotRows root.procPublishedRadii #("field-controller") (for leaf in root.layerObjects collect #(leaf.procLastStats,leaf.procLastRounds,leaf.procLastSurfaceStats))
   if hash!="'''+expected+'''" do throw "Frozen comparison output differs"
   if (for rows in root.groupSnapshotRows where not cyrusPlacementIsNative rows collect rows).count>0 do throw "Non-native published rows"
   local before=cyrusPlacementTransportStats();root.refreshAll()
   if not NGAllCoveredSame before (cyrusPlacementTransportStats()) do throw "Unchanged native update materialized rows"
  )''');send(h,script,f.stem+' '+kind+' '+label)
elif a.mode=='controller':
 for kind in ('plane','mountain'):
  send(h,controller,'setup '+kind)
  for phase in ('undo','verifyUndo','redo','verifyRedo','counts','manual','failure','display','bindings','panels','copy','undoDelete','verifyDeleteUndo','redoDelete','verifyDeleteRedo','reopen','idleStart'):
   send(h,controller,phase);time.sleep(1)
  print('Observing 120-second native idle',flush=True)
  for _ in range(12):time.sleep(10)
  send(h,controller,'idleEnd');send(h,controller,'release')
elif a.mode=='edit':
 script=native_fixture('edit_controller.ms')
 for kind in ('plane','mountain'):
  send(h,script,'old '+kind)
  for phase in ('undo','redo','repeated','gesture'):send(h,script,phase);time.sleep(1)
 for phase in ('memory','memoryUndo','memoryRedo','abandon'):send(h,script,phase);time.sleep(1)
elif a.mode=='preparation':
 send(h,ROOT/'tools/native_placement/generation.ms','setup plane')
 send(h,ROOT/'tools/native_placement/preparation.ms','setup')
 send(h,ROOT/'tools/native_placement/preparation.ms','release')
 script=native_fixture('preparation_controller.ms')
 for kind in ('plane','mountain'):
  send(h,controller,'setup '+kind)
  for phase in ('cases','mapBlack','checkBlack','checkManual','checkCount','checkUndo','checkRedo','checkFailure','checkRecovery','checkDataChannel','idleStart'):
   send(h,script,phase);time.sleep(2)
  print('Observing 65-second numeric field idle',flush=True);time.sleep(65)
  send(h,script,'idleEnd');send(h,controller,'release')
elif a.mode=='fields':
 script=native_fixture('fields_controller.ms')
 for kind in ('plane','mountain'):
  send(h,controller,'setup '+kind)
  for phase in ('features','paintClear','paintUndo','paintRedo','analyzer','release'):
   send(h,script,phase);time.sleep(2)
  send(h,controller,'idleStart');print('Observing 65-second Paint/Analyzer idle',flush=True);time.sleep(65)
  send(h,controller,'idleEnd');send(h,controller,'release')
elif a.mode=='outputs':
 s=native_fixture('outputs.ms').read_text()
 needle='NOapply();NOExpected=NCLeaf.placements (NCLeaf.outputSources())'
 assert needle in s
 s=s.replace(needle,'''NOapply();local view=NCLeaf.placements (NCLeaf.outputSources()),token=cyrusPlacementToken view
   NOExpected=#();for first=0 to view.count-1 by 500 do join NOExpected (cyrusPlacementPage view token first (amin 500 (view.count-first)))''')
 s=s.replace('equals legacy PF','equals the native reference PF')
 script=h/'shipping-outputs.ms';script.write_text(s)
 for kind in ('plane','mountain'):
  send(h,controller,'setup '+kind)
  for phase in ('compare','undo','redo'):send(h,script,phase);time.sleep(1)
  send(h,controller,'release')
print('SHIPPING NATIVE '+a.mode.upper()+' PASSED',flush=True)
