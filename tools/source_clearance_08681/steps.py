"""Serialized presentation checks in an already-owned Max 2027 fixture."""
from pathlib import Path
import argparse
import sys
import time
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import ready,send
parser=argparse.ArgumentParser()
parser.add_argument('host')
parser.add_argument('phases',nargs='+')
args=parser.parse_args()
if not args.host.startswith('update08671-test-clearance-perf-') or not args.host.endswith('-2027'):
    raise ValueError('Owned Max 2027 performance host required')
host=ROOT/'build/mcp-qualification'/args.host
ready(host)
for phase in args.phases:
    send(host,ROOT/'tools/source_clearance_08681/viewport_steps.ms',phase)
    # Let Max present outside the command callback before the next observation.
    time.sleep(.3)
    receipt=host/'viewport-steps-r2.txt'
    if receipt.exists() and any(line.startswith(('FAIL:','ERROR ')) for line in receipt.read_text().splitlines()):
        raise RuntimeError(receipt.read_text())
