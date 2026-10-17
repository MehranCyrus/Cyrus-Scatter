"""Matched controller A/B with complete fingerprints outside Update timing."""
import argparse
from run_generation import ROOT,ready,send
parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('host');args=parser.parse_args()
assert args.host.startswith('foundation-memory0854-nativeaccept-controller-')
host=ROOT/'build/mcp-qualification'/args.host;ready(host)
script=ROOT/'tools/native_placement/controller.ms'
for kind in ('plane','mountain'):
    send(host,script,'setup '+kind)
    send(host,script,'benchmark');send(host,script,'release')
print('MAX 2027 MATCHED CONTROLLER BENCHMARK PASSED',flush=True)
