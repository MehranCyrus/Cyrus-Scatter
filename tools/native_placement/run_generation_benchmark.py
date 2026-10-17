"""Matched producer-only timings. These are not full Update/FPS measurements."""
from pathlib import Path
import argparse
from run_generation import ready,send,ROOT
parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('host');args=parser.parse_args()
assert args.host.startswith('foundation-memory0854-nativegenerate-')
host=ROOT/'build/mcp-qualification'/args.host;ready(host);script=ROOT/'tools/native_placement/generation.ms'
for kind in ['plane','mountain']:
    send(host,script,'setup '+kind)
    for count in [5000,50000,200000]:
        for iteration in range(11):
            # Alternate order; independent warmup iteration zero is excluded.
            modes=['legacy','native'] if iteration%2==0 else ['native','legacy']
            for mode in modes:send(host,script,f'bench {count} {iteration} {mode}')
    # Compare counter-on overhead separately at 50k, retaining all samples.
    for iteration in range(11):
        for mode in (['legacy','observed'] if iteration%2==0 else ['observed','legacy']):
            send(host,script,f'bench 50000 {iteration+20} {mode}')
    send(host,script,'release')
print('MATCHED GENERATION BENCHMARK PASSED',flush=True)
