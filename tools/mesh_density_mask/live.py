"""Run one request at a time, with observer waits outside the Max UI thread."""
from pathlib import Path
import argparse,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('folder',type=Path);p.add_argument('--start-stage',type=int,default=1);a=p.parse_args()
for stage in range(a.start_stage,10):
    print('Mesh mask Live stage',stage,flush=True)
    subprocess.run([sys.executable,str(ROOT/'tools/eleven_phases/request.py'),str(a.folder),str(Path(__file__).with_suffix('.ms'))],check=True)
    if stage<9:
        marker=a.folder/'mesh-live-ready.txt';deadline=time.monotonic()+30
        while not marker.exists() and time.monotonic()<deadline:time.sleep(.1)
        assert marker.exists(),'Observer did not finish; inspect the owned host before retrying'
