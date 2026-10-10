from pathlib import Path
import sys,json,time
R=Path.cwd();W=R/'build/paint077';H=R/'build/mcp-qualification/paint077-final'
sys.path.insert(0,str(R/'tools/procedural_lab'));from runtime_driver import run_script
rows=[]
for label,code in [('load','fileIn @"'+(R/'tools/procedural_lab/Max_Layer_Regions_074.ms').as_posix()+'"\nfileIn @"'+(R/'tools/procedural_lab/Max_Brush_077.ms').as_posix()+'"'),('feedback','B77Feedback()')]:
 t=time.monotonic();result=run_script(H,code,300);rows.append(dict(name=label,result=result,passed=result.startswith('SUCCESS '),seconds=time.monotonic()-t));(W/'feedback-final-run.json').write_text(json.dumps(rows,indent=2));print(result,flush=True)
 if not rows[-1]['passed']:raise RuntimeError(result)
