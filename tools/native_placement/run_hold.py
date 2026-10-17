"""Real Max 2027 holds, repeated Restore/Redo, Size, and shared pin disposal."""
from pathlib import Path
import argparse
from run_generation import ROOT,ready,send
parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('host');args=parser.parse_args()
assert args.host.startswith('foundation-memory0854-nativegenerate-hold-')
host=ROOT/'build/mcp-qualification'/args.host;ready(host)
generation=ROOT/'tools/native_placement/generation.ms';script=ROOT/'tools/native_placement/hold.ms'
send(host,generation,'setup plane');send(host,generation,'prepareHold')
for phase in ['ordinary','undo','checkA','redo','checkB','undo','checkA','redo','checkB','cancel',
              'super','undo','checkSuperUndo','redo','checkSuperRedo','undo','checkSuperUndo',
              'undo','checkA','abandon','finish']:
    send(host,script,phase)
print('MAX 2027 NATIVE HOLD/SIZE/LIFETIME PROBES PASSED',flush=True)
