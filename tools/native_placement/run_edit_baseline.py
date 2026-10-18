"""Freeze old Edit scene/ordered output in the prior, verified native-03 host."""
import argparse
from run_generation import ROOT,ready,send
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args()
assert a.host=='foundation-memory0854-nativeaccept-controller-20261018-07'
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
for kind in ('plane','mountain'):
    send(host,ROOT/'tools/native_placement/controller.ms','setup '+kind)
    send(host,ROOT/'tools/native_placement/edit_baseline.ms','baseline')
    send(host,ROOT/'tools/native_placement/controller.ms','release')
print('OLD EDIT PLANE/MOUNTAIN AUTHORED SCENES SAVED',flush=True)
