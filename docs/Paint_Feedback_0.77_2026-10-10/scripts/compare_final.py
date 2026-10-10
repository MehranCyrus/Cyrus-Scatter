from pathlib import Path
import sys
R=Path.cwd();sys.path.insert(0,str(R/'tools/procedural_lab'));from runtime_driver import run_script
H=R/'build/mcp-qualification/paint077-final'
code='global B77Compare\nfileIn @"'+(R/'tools/procedural_lab/Max_Brush_077_Compare.ms').as_posix()+'"\nB77Compare()'
r=run_script(H,code,120);(R/'build/paint077/comparison-final-result.txt').write_text(r);print(r)
