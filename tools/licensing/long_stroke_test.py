"""Regress a staged vector stroke lasting longer than the old permit cap."""
import argparse,json,sys,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab'))
from runtime_driver import run_script
p=argparse.ArgumentParser();p.add_argument('--host',action='append',required=True);a=p.parse_args()
folders=[]
def run(f,s):
    result=run_script(f,s);print(result,flush=True)
    if not result.startswith('SUCCESS'):raise RuntimeError('Long stroke assertion failed')
for name in a.host:
    if Path(name).name!=name or name in ('.','..'):raise ValueError('Expected owned profile name')
    f=ROOT/'build/mcp-qualification'/name;folders.append(f)
    run(f,'global LTLongBefore=(cyrusBrushStats LTArea.paintDocument)[3]\n'
          'cyrusBrushSettings LTArea.paintDocument 8 true\n'
          'LTAssert (cyrusBrushDab LTArea.paintDocument [0,0,100] [0,0,-1] false) "Long stroke begins with valid authority"\n'
          'LTAssert ((cyrusBrushStats LTArea.paintDocument)[6]==1) "Long stroke stays staged before commit"')
print('Holding staged strokes for 32 real seconds',flush=True);time.sleep(32)
for f in folders:
    run(f,'LTAssert (cyrusBrushDab LTArea.paintDocument [2,0,100] [0,0,-1] true) "Stroke over 30 seconds commits with active license"\n'
          'local s=cyrusBrushStats LTArea.paintDocument\n'
          'LTAssert (s[6]==0 and s[3]>LTLongBefore) "Long stroke publishes changed region and clears staging"')
    (f/'long-stroke.json').write_text(json.dumps({'passed':True,'held_seconds':32},indent=2))
