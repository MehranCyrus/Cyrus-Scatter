from pathlib import Path
import sys,json,hashlib
R=Path.cwd();base=R/'build/mcp-qualification/receiver076-release';H=R/'build/mcp-qualification/paint077-before'
meta=json.loads((base/'launch.json').read_text())
for name,digest in meta['binaries'].items():assert hashlib.sha256((base/'bin'/name).read_bytes()).hexdigest()==digest
assert hashlib.sha256((base/'scripts/CyrusScatter.ms').read_bytes()).hexdigest()==meta['script_sha256']
sys.path.insert(0,str(R/'tools/procedural_lab/layer_editor_071'));from private_host import launch
extra='fileIn @"'+(R/'tools/performance/CyrusPerformanceMonitor.ms').as_posix()+'"\nfileIn @"'+(R/'CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms').as_posix()+'"'
p,meta=launch(H,base/'scripts/CyrusScatter.ms',base/'bin',extra=extra,transport=True,extra_modules=('CyrusSurfaceAnalyzer.dlx',));print('owned baseline PID',p.pid,flush=True)
sys.path.insert(0,str(R/'tools/procedural_lab'));from runtime_driver import run_script
code='global B77Compare\n'+'\n'.join('fileIn @"'+(R/'tools/procedural_lab'/n).as_posix()+'"' for n in ('Max_Layer_Regions_074.ms','Max_Brush_077_Compare.ms'))+'\nB77Compare()'
r=run_script(H,code,300);(R/'build/paint077/baseline-result.txt').write_text(r);print(r)

if not r.startswith("SUCCESS "):raise RuntimeError(r)
