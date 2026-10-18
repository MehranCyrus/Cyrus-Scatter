"""Serialized native boundary/Paint parity in an owned Max 2027 host."""
import argparse
from run_generation import ROOT, ready, send

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('host')
a = p.parse_args()
assert a.host.startswith('foundation-memory0854-nativeaccept-controller-')
host = ROOT/'build/mcp-qualification'/a.host
ready(host)
script = ROOT/'tools/native_placement/fields.ms'
for terrain in ('plane', 'mountain'):
    send(host, ROOT/'tools/native_placement/generation.ms', 'setup '+terrain)
    send(host, script, 'setup')
    for count in (5000, 50000, 200000):
        send(host, script, f'case {count}')
    send(host, script, 'receivers')
    send(host, script, 'release')
print('MAX 2027 NATIVE BOUNDARY/PAINT ADAPTER PARITY PASSED', flush=True)
