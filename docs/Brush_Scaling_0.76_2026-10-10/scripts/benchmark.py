from pathlib import Path
import sys, subprocess
R=Path.cwd();W=R/'build/brush076';sys.path.insert(0,str(R/'tools'))
from build_max import compiler_environment
env=compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
label=sys.argv[1];lib=Path(sys.argv[2]).resolve();exe=W/(label+'.exe')
include=Path(sys.argv[3]).resolve() if len(sys.argv)>3 else R/'AminScatter/include'
cmd=[str(Path(env['PATH'].split(';')[0])/'cl.exe'),'/nologo','/O2','/EHsc','/std:c++17','/MD','/I'+str(include),str(R/'tools/brush_lab/scaling_benchmark.cpp'),str(lib),'/Fe:'+str(exe),'/Fo:'+str(W/(label+'.obj'))]
subprocess.run(cmd,env=env,check=True)
result=subprocess.run([str(exe)],capture_output=True,text=True,check=True)
(W/(label+'.csv')).write_text(result.stdout);print(result.stdout)

