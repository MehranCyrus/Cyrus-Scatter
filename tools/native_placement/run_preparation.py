"""Serialized optional native preparation parity in a disposable Max 2027 host."""
from run_generation import ROOT, ready, send
import argparse

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('host')
args = parser.parse_args()
assert args.host.startswith('foundation-memory0854-nativeaccept-controller-')
host = ROOT / 'build/mcp-qualification' / args.host
ready(host)
generation = ROOT / 'tools/native_placement/generation.ms'
script = ROOT / 'tools/native_placement/preparation.ms'
for terrain in ('plane', 'mountain'):
    send(host, generation, 'setup ' + terrain)
    send(host, script, 'setup')
    for count in (5000, 50000, 200000):
        send(host, script, f'case {count}')
    send(host, script, 'fields')
    send(host, script, 'release')
print('MAX 2027 OPTIONAL NATIVE PREPARATION PARITY PASSED', flush=True)
