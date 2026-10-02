from pathlib import Path
import sys,subprocess
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'tools'))
from build_max import compiler_environment
env=compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
base=Path(__file__).resolve().parent
sdk=root/'build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk'
for command in ([ 'cmake','-S',str(base/'probe'),'-B',str(base/'probe-build'),'-G','NMake Makefiles','-DCMAKE_BUILD_TYPE=Release','-DCYRUS_MAX_YEAR=2027','-DMAXSDK_ROOT='+str(sdk)],['cmake','--build',str(base/'probe-build')]):
 subprocess.run(command,cwd=root,env=env,check=True)
