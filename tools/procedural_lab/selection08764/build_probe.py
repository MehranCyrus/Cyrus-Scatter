"""Build isolated host API probes, never an installer payload."""
from pathlib import Path
import sys,subprocess,shutil
ROOT=Path(__file__).resolve().parents[3];sys.path.insert(0,str(ROOT/'tools'))
import build_max
from argparse import ArgumentParser
p=ArgumentParser();p.add_argument('--output',type=Path,default=ROOT/'build/instance-selection-08764-20261029-03/probe');a=p.parse_args()
out=a.output.resolve();assert out.is_relative_to(ROOT/'build');out.mkdir(parents=True,exist_ok=True)
sdk=ROOT/'build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk'
env=build_max.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
cmd=['cl','/nologo','/std:c++20','/EHsc','/MD','/O2','/DUNICODE','/D_UNICODE','/DNOMINMAX',f'/I{sdk}/include',str(Path(__file__).with_name('selection_probe.cpp')),'/LD',f'/Fe:{out}/'+'SelectionProbeV2.dlx','/link',f'/LIBPATH:{sdk}/lib/x64/Release','user32.lib','core.lib','geom.lib','maxutil.lib','maxscrpt.lib']
cmd[0]=shutil.which('cl.exe',path=env.get('PATH',env.get('Path')))
p=subprocess.run(cmd,cwd=out,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
(out/'build.log').write_text(p.stdout);print(p.stdout[-6000:]);sys.exit(p.returncode)
