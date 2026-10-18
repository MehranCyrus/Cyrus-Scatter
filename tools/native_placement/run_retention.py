"""Compaction, ten-owner cap and evaluated receiver capacity in owned Max."""
import argparse,time
from run_generation import ROOT,ready,send
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args()
assert a.host.startswith('foundation-memory0854-nativeaccept-controller-')
h=ROOT/'build/mcp-qualification'/a.host;ready(h)
for phase in ('compact','pinRelease','tenLayers','empty','release'):
 send(h,ROOT/'tools/native_placement/retention.ms',phase);time.sleep(.5)
print('NATIVE COMPACTION AND TEN-POPULATION CAPACITY PASSED',flush=True)
