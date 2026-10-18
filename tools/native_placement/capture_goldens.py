"""Freeze real comparison-route scenes/hashes before removing the temporary route."""
import argparse,time
from run_generation import ROOT,ready,send
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args()
assert a.host.startswith('foundation-memory0854-nativeaccept-controller-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
helper=host/'golden-helper.ms'
helper.write_text('''global NGAllCoveredSame,FGIndex=0
fn NGAllCoveredSame a b=(for stage=2 to a.count where a[stage][1] do for k=2 to a[stage].count where a[stage][k]!=b[stage][k] do return false;true)
fn FGSave label hash=(
 FGIndex+=1;local name="golden-"+(FGIndex as string)
 saveMaxFile (MCPFixtureDir+name+".max") quiet:true useNewFile:false
 local f=createFile (MCPFixtureDir+name+".txt");format "%\\n%\\n%\\n" hash NCKind label to:f;close f
)
''')
send(host,helper,'helpers')
original=ROOT/'tools/native_placement/fields_controller.ms';s=original.read_text()
needle='  FCwrite ("PASS "+label+" accepted="+(NCLeaf.generatedCount as string)+" hash="+expected)'
assert needle in s;s=s.replace(needle,needle+'\n  FGSave label expected')
fields=host/'capture-field-goldens.ms';fields.write_text(s)
controller=ROOT/'tools/native_placement/controller.ms'
for kind in ('plane','mountain'):
 send(host,controller,'setup '+kind)
 for phase in ('features','paintClear','paintUndo','paintRedo','analyzer','release'):
  send(host,fields,phase);time.sleep(2)
 send(host,controller,'release')
print('FROZEN CROSS-VERSION FIELD GOLDENS SAVED',flush=True)
