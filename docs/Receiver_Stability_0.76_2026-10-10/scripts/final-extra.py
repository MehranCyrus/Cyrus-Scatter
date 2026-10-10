from pathlib import Path
import sys,json,time
sys.path.insert(0,'tools/procedural_lab');from runtime_driver import run_script
r=Path.cwd();w=r/'build/receiver076';h=r/'build/mcp-qualification/receiver076-release'
code='global R76FractionalAndGuards;global R76KeepChecks=R76Checks;fileIn @"'+(r/'tools/procedural_lab/Max_Receiver_Stability_076.ms').as_posix()+'";R76Checks=R76KeepChecks;R76FractionalAndGuards()'
t=time.monotonic();result=run_script(h,code,300);row=dict(name='fractional-and-guards',result=result,passed=result.startswith('SUCCESS '),seconds=time.monotonic()-t);(w/'final-extra.json').write_text(json.dumps(row,indent=2));print(result)
assert row['passed']
