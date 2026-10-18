"""Native optional controller, actual Paint history and real Analyzer ownership."""
import argparse, time
from run_generation import ROOT, ready, send
p=argparse.ArgumentParser(description=__doc__);p.add_argument('host');a=p.parse_args()
assert a.host.startswith('foundation-memory0854-nativeaccept-controller-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
helper=host/'fields-helpers.ms'
helper.write_text('global NGAllCoveredSame\nfn NGAllCoveredSame a b=(for stage=2 to a.count where a[stage][1] do for k=2 to a[stage].count where a[stage][k]!=b[stage][k] do return false;true)\n')
send(host,helper,'helpers')
controller=ROOT/'tools/native_placement/controller.ms'
fields=ROOT/'tools/native_placement/fields_controller.ms'
for kind in ('plane','mountain'):
    send(host,controller,'setup '+kind)
    for phase in ('features','paintClear','paintUndo','paintRedo','analyzer','release'):
        send(host,fields,phase)
        time.sleep(2)
    send(host,controller,'idleStart')
    print('Observing 65 seconds optional feature idle',flush=True);time.sleep(65)
    send(host,controller,'idleEnd')
    send(host,controller,'release')
print('MAX 2027 OPTIONAL FEATURES/PAINT/ANALYZER CONTROLLER PASSED',flush=True)
