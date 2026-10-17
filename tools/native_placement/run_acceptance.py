"""Native radius/acceptance stage parity. Does not switch the product controller."""
import argparse
from run_generation import ROOT,ready,send

parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('host');args=parser.parse_args()
assert args.host.startswith('foundation-memory0854-nativeaccept-')
host=ROOT/'build/mcp-qualification'/args.host;ready(host)
generation=ROOT/'tools/native_placement/generation.ms'
script=ROOT/'tools/native_placement/acceptance.ms'
for kind in ('plane','mountain'):
    send(host,generation,'setup '+kind)
    for label,count in [('simple',5000),('simple',50000),('simple',200000),('receivers',5000),('grid',0),('sourceFilter',5000),('empty',5000),('surface',5000),('overrides',5000),('target',5000),('cleanup',5000)]:
        send(host,script,f'case {label} {count}')
    send(host,script,'scopes')
    send(host,script,'protectedSurface')
    send(host,script,'failure')
    send(host,script,'release')
print('MAX 2027 NATIVE RADII/ACCEPTANCE PARITY PASSED',flush=True)
