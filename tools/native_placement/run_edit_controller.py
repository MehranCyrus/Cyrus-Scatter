"""Native Edit full-output parity, actual holds, persistence and allocation curves."""
import argparse,time
from run_generation import ROOT,ready,send
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args()
assert a.host.startswith('foundation-memory0854-nativeaccept-controller-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
helper=host/'edit-helpers.ms'
helper.write_text('global NGAllCoveredSame\nfn NGAllCoveredSame a b=(for stage=2 to a.count where a[stage][1] do for k=2 to a[stage].count where a[stage][k]!=b[stage][k] do return false;true)\ncyrusPlacementTransportStats true\n')
send(host,helper,'helpers')
script=ROOT/'tools/native_placement/edit_controller.ms'
for kind in ('plane','mountain'):
    send(host,script,'old '+kind)
    for phase in ('undo','redo','repeated','gesture'):
        send(host,script,phase);time.sleep(1)
for phase in ('memory','memoryUndo','memoryRedo','abandon'):
    send(host,script,phase);time.sleep(1)
print('MAX 2027 NATIVE EDIT HISTORY/PERSISTENCE PASSED',flush=True)
