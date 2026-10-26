"""Read-only crash analysis and diagnostic relink; never modifies producer files."""
from pathlib import Path
import re,subprocess,sys
ROOT=Path(__file__).resolve().parents[3];sys.path.insert(0,str(ROOT/'tools'))
from build_max import compiler_environment
out=ROOT/'build/mcp-qualification/interactions087-pointer-20261025-04'
env=compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
source=(ROOT/'build/crash-08691-20261023-01/analyze_dump.cpp').read_text()
source=source.replace('build\\\\ui-edit-08691-20261023\\\\stage-2027-05','build\\\\interactions087-final-payload-20261025-01')
source=source.replace('.ecxr; r; k 50; u @rip L8; lmv m AminScatter','.ecxr; .exr -1; r; k 60; u @rip L8; lmv m AminScatter')
(out/'analyze.cpp').write_text(source)
cl='C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.38.33130/bin/Hostx64/x64/cl.exe'
subprocess.run([cl,'/nologo','/EHsc','/std:c++17',str(out/'analyze.cpp'),'/Fe:'+str(out/'analyze.exe'),'/Fo:'+str(out/'analyze.obj')],env=env,check=True,capture_output=True)
with (out/'drag-crash-full.txt').open('w') as log:subprocess.run([str(out/'analyze.exe'),str(out/'drag-crash.dmp')],stdout=log,stderr=subprocess.STDOUT,check=True,timeout=45)
build=ROOT/'build/interactions087-release-20261025-02/AminScatter'
ninja=re.search(r'CMAKE_MAKE_PROGRAM:FILEPATH=(.+)',(build/'CMakeCache.txt').read_text()).group(1)
commands=subprocess.check_output([ninja,'-t','commands','AminScatter.dlx'],cwd=build,env=env,text=True)
link=commands.splitlines()[-1]
for suffix in ['dlx','lib','pdb']:
    link=link.replace('AminScatter.'+suffix,(out/('diagnostic.'+suffix)).as_posix())
link=link.replace('/INCREMENTAL:NO','/INCREMENTAL:NO /MAP:'+str(out/'diagnostic.map').replace('\\','/'))
(out/'diagnostic-link.txt').write_text(link)
r=subprocess.run(link,cwd=build,env=env,text=True,capture_output=True);(out/'diagnostic-link.log').write_text(r.stdout+r.stderr);r.check_returncode()
print((out/'drag-crash-full.txt').read_text(errors='replace')[-15000:])
