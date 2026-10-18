"""Named allocation/late-publication failures in a nonshipping Max 2027 build."""
import argparse
from run_generation import ROOT,ready,send
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args()
assert a.host.startswith('foundation-memory0854-nativegenerate-hold-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
script=ROOT/'tools/native_placement/failures.ms';send(host,script,'setup')
for stage,occurrence in [(1,1),(2,1),(3,1),(3,2),(3,4),(4,20),(5,1),(5,20),(6,1),(7,1),(8,1),(8,2),(9,1)]:send(host,script,f'fault {stage} {occurrence}')
for phase in ('authored','bake','release'):send(host,script,phase)
print('NATIVE FAILURE RETENTION, AUTHORED ATOMICITY, PARTIAL BAKE AND RELEASE PASSED',flush=True)
