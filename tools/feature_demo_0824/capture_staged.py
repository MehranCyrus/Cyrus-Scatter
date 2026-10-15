from pathlib import Path
import argparse,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('folder',type=Path);a=p.parse_args()
for stage in range(5):
    print('Viewport capture stage',stage,flush=True)
    subprocess.run([sys.executable,str(ROOT/'tools/eleven_phases/request.py'),str(a.folder),str(Path(__file__).with_suffix('.ms'))],check=True)
    if stage<4:
        marker=a.folder/'demo-shot-ready.txt';deadline=time.monotonic()+30
        while not marker.exists() and time.monotonic()<deadline:time.sleep(.1)
        assert marker.exists(),'Inspect owned host; observer did not finish'
