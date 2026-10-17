"""Coherent native Surface-random controller and ordinary history in Max 2027."""
import argparse,time
from run_generation import ROOT,ready,send
parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('host');args=parser.parse_args()
assert args.host.startswith('foundation-memory0854-nativeaccept-controller-')
host=ROOT/'build/mcp-qualification'/args.host;ready(host)
script=ROOT/'tools/native_placement/controller.ms'
# Load shared opt-in counter comparison helpers without creating a second scene.
helper=host/'controller-helpers.ms'
helper.write_text('global NGAllCoveredSame\nfn NGAllCoveredSame a b=(for stage=2 to a.count where a[stage][1] do for k=2 to a[stage].count where a[stage][k]!=b[stage][k] do return false;true)\n')
send(host,helper,'helpers')
for kind in ('plane','mountain'):
    send(host,script,'setup '+kind)
    for phase in ('undo','verifyUndo','redo','verifyRedo','counts','manual','failure','display','bindings','panels','copy','undoDelete','verifyDeleteUndo','redoDelete','verifyDeleteRedo','reopen','idleStart'):
        send(host,script,phase)
    print('Observing 65 seconds actual idle',flush=True);time.sleep(65)
    send(host,script,'idleEnd');send(host,script,'release')
print('MAX 2027 NATIVE CONTROLLER/HISTORY PASSED',flush=True)
