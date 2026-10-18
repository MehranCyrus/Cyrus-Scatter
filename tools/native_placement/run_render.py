"""Reuse the real Corona lifecycle witness with a native-only fixture."""
import argparse,sys
from run_generation import ROOT,ready,send
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args()
assert a.host.startswith('foundation-memory0854-nativeaccept-controller-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
helpers=(ROOT/'tools/performance/CyrusPerformanceMonitor.ms').read_text(encoding='utf-8-sig')
# Only JSON serialization helpers. Do not load or start the performance monitor.
start=helpers.index('fn CSPText');end=helpers.index('\n)',helpers.index('fn CSPWriteText'))+2
fixture=helpers[start:end]+r'''
global P07Node,P07Root,P07Layer,P07Source,P07Surface,P07Case
fn P07Assert yes message=(if not yes do throw message)
fn P07New count:120=(
 with undo off (
  resetMaxFile #noPrompt;units.SystemType=#centimeters;units.SystemScale=1.0
  P07Surface=plane width:1000 length:1000 widthsegs:32 lengthsegs:32
  P07Source=pyramid width:15 depth:15 height:40 pos:[800,0,0];hide P07Source
  P07Node=AminScatterObject name:"Native render fixture";P07Root=P07Node.baseObject
  if isProperty P07Root #procNativeRoute do P07Root.procNativeRoute=true;P07Root.updateMode=1;P07Root.newLayer();P07Layer=P07Root.selectedLayer()
  P07Root.setLayerSurfaces P07Layer #(P07Surface);P07Layer.sources=#(P07Source);P07Layer.amount=count
  P07Layer.procSelfOverride=true;P07Layer.procSelfEnabled=false;P07Layer.sourceRadiiWU=#(0.0)
  P07Root.refreshAll();P07Assert (P07Layer.previewError=="" and cyrusPlacementIsNative P07Root.groupSnapshotRows[1]) "Native render setup"
 )
)
'''
script=host/'native-render-helper.ms';script.write_text(fixture,encoding='utf-8-sig');send(host,script,'render helpers')
sys.path.insert(0,str(ROOT/'tools/procedural_lab'))
import corona_072_qualification as witness
# The historical witness predates lazy outer rollout slots. Open the actual
# slot before exporting, so its controller is bound by the normal UI lifecycle.
original=witness.run_script
def run_current(folder,code,timeout=120):
    code=code.replace('P07Root.statisticsUI.open=true;', 'P07Root.statisticsUISlot.open=true;')
    return original(folder,code,timeout=timeout)
witness.run_script=run_current
witness.qualify(host)
