"""Actual notifications, ordinary Count history and optional preparation parity."""
import argparse, time
from run_generation import ROOT, ready, send

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('host')
args = parser.parse_args()
assert args.host.startswith('foundation-memory0854-nativeaccept-controller-')
host = ROOT/'build/mcp-qualification'/args.host
ready(host)
controller = ROOT/'tools/native_placement/controller.ms'
script = ROOT/'tools/native_placement/preparation_controller.ms'
# Load the shared authored fixture helpers; no private product hooks are used.
send(host, ROOT/'tools/native_placement/generation.ms', 'setup plane')
send(host, ROOT/'tools/native_placement/preparation.ms', 'setup')
send(host, ROOT/'tools/native_placement/preparation.ms', 'release')
for kind in ('plane', 'mountain'):
    send(host, controller, 'setup '+kind)
    for phase in ('cases','mapBlack','checkBlack','checkManual','checkCount','checkUndo','checkRedo','checkFailure','checkRecovery','checkDataChannel','idleStart'):
        send(host, script, phase)
        time.sleep(2)  # Observe normal delayed callbacks outside Max's thread.
    print('Observing 65 seconds optional-route idle', flush=True)
    time.sleep(65)
    send(host, script, 'idleEnd')
    send(host, controller, 'release')
print('MAX 2027 OPTIONAL CONTROLLER/HISTORY PASSED', flush=True)
