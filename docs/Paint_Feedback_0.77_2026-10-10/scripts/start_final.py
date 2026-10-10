from pathlib import Path
import sys,subprocess,shutil,json
R=Path.cwd(); W=R/'build/paint077'
sys.path.insert(0,str(R/'tools'));from build_max import compiler_environment
env=compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
subprocess.run([str(Path(env['PATH'].split(';')[0])/'cl.exe'),'/nologo','/O2','/EHsc','/std:c++17','/MD','/I'+str(R/'AminScatter/include'),str(R/'tools/procedural_lab/brush_feedback_benchmark.cpp'),str(W/'release-max2027/amin_scatter.lib'),'/Fe:'+str(W/'benchmark.exe'),'/Fo:'+str(W/'benchmark.obj')],env=env,check=True)
with (W/'benchmark-final.csv').open('w') as out:subprocess.run([str(W/'benchmark.exe')],stdout=out,check=True)
print((W/'benchmark-final.csv').read_text())
sys.path.insert(0,str(R/'tools/procedural_lab/layer_editor_071'));from private_host import launch
native=W/'native';native.mkdir(exist_ok=True)
for name in ('AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm'):shutil.copy2(W/'release-max2027'/name,native/name)
shutil.copy2(R/'build/courtyard-fixes075/analyzer2027-release/CyrusSurfaceAnalyzer.dlx',native/'CyrusSurfaceAnalyzer.dlx')
extra='fileIn @"'+(R/'tools/performance/CyrusPerformanceMonitor.ms').as_posix()+'"\nfileIn @"'+(R/'CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms').as_posix()+'"'
p,meta=launch(R/'build/mcp-qualification/paint077-final',R/'AminScatter/scripts/AminScatterObject.ms',native,extra=extra,transport=True,extra_modules=('CyrusSurfaceAnalyzer.dlx',))
print(json.dumps(meta),flush=True)
