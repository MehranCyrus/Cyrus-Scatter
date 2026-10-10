from pathlib import Path
import sys,shutil,json
R=Path.cwd();W=R/'build/brush076';N=W/'native';N.mkdir(exist_ok=True)
sys.path.insert(0,str(R/'tools/procedural_lab/layer_editor_071'))
from private_host import launch
for name in ('AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm'):
 shutil.copy2(W/'max2027'/name,N/name)
shutil.copy2(R/'build/courtyard-fixes075/analyzer2027-release/CyrusSurfaceAnalyzer.dlx',N/'CyrusSurfaceAnalyzer.dlx')
extra='fileIn @"'+(R/'tools/performance/CyrusPerformanceMonitor.ms').as_posix()+'"\nfileIn @"'+(R/'CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms').as_posix()+'"'
p,meta=launch(R/'build/mcp-qualification/brush076',R/'AminScatter/scripts/AminScatterObject.ms',N,extra=extra,transport=True,extra_modules=('CyrusSurfaceAnalyzer.dlx',))
print(json.dumps(meta,indent=2))
