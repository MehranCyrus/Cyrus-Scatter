"""Serialized structural ownership and New Setup regression in owned Max."""
import argparse,time
from run_generation import ROOT,ready,send
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args()
assert a.host.startswith('foundation-memory0854-nativeaccept-controller-')
h=ROOT/'build/mcp-qualification'/a.host;ready(h)
for phase in ('setup','removeUndo','removeRedo','clone','receiver','receiverUndo','newSetup','newUndo','newRedo','abandon'):
 send(h,ROOT/'tools/native_placement/lifecycle.ms',phase);time.sleep(.5)
print('NATIVE STRUCTURAL EDIT AND NEW SETUP LIFECYCLE PASSED',flush=True)
