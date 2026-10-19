from pathlib import Path
import argparse,sys,time
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/native_placement'));from run_generation import send,ready
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('--demo',action='store_true');a=p.parse_args();assert a.host.startswith('density0862-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
if a.demo:
 send(host,ROOT/'tools/density_0862/demo.ms','demo')
 send(host,ROOT/'tools/density_0862/demo_verify.ms','demo_verify')
 send(host,ROOT/'tools/density_0862/ui_demo_setup.ms','ui_demo_setup')
else:
 send(host,ROOT/'tools/density_0862/initial.ms','initial')
 send(host,ROOT/'tools/density_0862/ui_setup.ms','ui_setup')
time.sleep(.5);send(host,ROOT/'tools/density_0862/layout_prepare.ms','layout_prepare')
time.sleep(.5);send(host,ROOT/'tools/density_0862/layout.ms','layout')
print((Path((host/'layout-latest.txt').read_text(encoding='utf-8-sig'))).read_text(encoding='utf-8-sig')[-600:])
