"""Actual Max 2027 PFlow and bounded Bake transport qualification."""
import argparse,time
from run_generation import ROOT,ready,send
p=argparse.ArgumentParser(description=__doc__);p.add_argument('host');a=p.parse_args()
assert a.host.startswith('foundation-memory0854-nativeaccept-controller-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
helper=host/'outputs-helpers.ms'
helper.write_text('global NGAllCoveredSame\nfn NGAllCoveredSame a b=(for stage=2 to a.count where a[stage][1] do for k=2 to a[stage].count where a[stage][k]!=b[stage][k] do return false;true)\n')
send(host,helper,'helpers')
for kind in ('plane','mountain'):
    send(host,ROOT/'tools/native_placement/controller.ms','setup '+kind)
    for phase in ('compare','undo','redo'):
        send(host,ROOT/'tools/native_placement/outputs.ms',phase);time.sleep(2)
    send(host,ROOT/'tools/native_placement/controller.ms','release')
print('MAX 2027 NATIVE PFLOW/BAKE PASSED',flush=True)
