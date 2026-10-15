"""Stage the host interaction witness, waiting outside the host UI thread."""
from pathlib import Path
import argparse,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('folder',type=Path);a=p.parse_args()
for stage in range(1,4):
    print('Mesh interactions stage',stage,flush=True)
    subprocess.run([sys.executable,str(ROOT/'tools/eleven_phases/request.py'),str(a.folder),str(Path(__file__).with_suffix('.ms'))],check=True)
    if stage<3:
        marker=a.folder/'mesh-interaction-ready.txt';deadline=time.monotonic()+30
        while not marker.exists() and time.monotonic()<deadline:time.sleep(.1)
        assert marker.exists(),'Observer did not finish; inspect owned host before retrying'
