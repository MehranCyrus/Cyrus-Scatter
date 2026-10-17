"""Actual Max native draw-content and retained-buffer comparisons."""
import argparse
from run_generation import ROOT,ready,send
parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('host');args=parser.parse_args()
assert args.host.startswith('foundation-memory0854-nativeaccept-preview-')
host=ROOT/'build/mcp-qualification'/args.host;ready(host)
generation=ROOT/'tools/native_placement/generation.ms';script=ROOT/'tools/native_placement/preview.ms'
for kind in ('plane','mountain'):
    send(host,generation,'setup '+kind)
    for amount in (5000,50000,200000):
        send(host,script,f'prepare {amount}')
        for budget in (0,1,8192):send(host,script,f'point {budget}')
        for mode in (1,2,3,4):
            for limit in (0,1,4096):send(host,script,f'mesh {mode} {limit} geometry')
        send(host,script,'mesh 4 4096 placeholder')
        send(host,script,'bands');send(host,script,'failure')
        if amount==5000:send(host,script,'comparison')
    send(host,script,'publish');send(host,script,'releaseInput');send(host,script,'release')
print('MAX 2027 NATIVE PREVIEW/RETAINED PARITY PASSED',flush=True)
