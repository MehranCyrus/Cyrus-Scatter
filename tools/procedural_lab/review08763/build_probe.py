"""Build isolated host API probes, never an installer payload."""
from pathlib import Path
import sys,subprocess,shutil
ROOT=Path(__file__).resolve().parents[3];sys.path.insert(0,str(ROOT/'tools'))
import build_max
mesh='--mesh' in sys.argv
out=ROOT/'build/interaction-review-08763-20261029-01/probe';out.mkdir(exist_ok=True)
sdk=ROOT/'build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk'
env=build_max.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
cmd=['cl','/nologo','/std:c++20','/EHsc','/MD','/O2','/DUNICODE','/D_UNICODE','/DNOMINMAX',f'/I{sdk}/include',str(ROOT/'tools/procedural_lab/selection08762'/('mesh_probe.cpp' if mesh else 'selection_probe.cpp')),'/LD',f'/Fe:{out}/'+('MeshProbe.dlx' if mesh else 'SelectionProbeV2.dlx'),'/link',f'/LIBPATH:{sdk}/lib/x64/Release','core.lib','geom.lib','maxutil.lib','maxscrpt.lib']
cmd[0]=shutil.which('cl.exe',path=env.get('PATH',env.get('Path')))
p=subprocess.run(cmd,cwd=out,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
(out/('mesh-build.log' if mesh else 'build.log')).write_text(p.stdout);print(p.stdout[-6000:]);sys.exit(p.returncode)
