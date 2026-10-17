"""Native frozen source/data-publication tests in the actual owned Max host."""
import argparse
from run_generation import ROOT,ready,send
parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('host');args=parser.parse_args()
assert args.host.startswith(('foundation-memory0854-nativeaccept-binding-','foundation-memory0854-nativeaccept-controller-'))
host=ROOT/'build/mcp-qualification'/args.host;ready(host)
generation=ROOT/'tools/native_placement/generation.ms';script=ROOT/'tools/native_placement/binding.ms'
for kind in ('plane','mountain'):
    send(host,generation,'setup '+kind);send(host,script,'setup')
    for amount in (5000,50000,200000,5000):send(host,script,f'case {amount}')
    send(host,script,'failure');send(host,script,'receivers');send(host,script,'pins');send(host,script,'release')
print('MAX 2027 NATIVE SOURCE/DATA PUBLICATION PASSED',flush=True)
