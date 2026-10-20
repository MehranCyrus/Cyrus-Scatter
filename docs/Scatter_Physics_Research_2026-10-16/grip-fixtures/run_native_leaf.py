"""Run the extended curved-leaf witness against this run's compiled core."""
from pathlib import Path
import sys, subprocess, json, shutil
root=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(root/'CyrusPhysicsLab/tools'))
import build
out=root/'build/physics-grip-015-20261018-01'
native=out/'core-01'
source=Path(__file__).with_name('native_leaf.cpp')
env=build.compiler_environment()
compiler=shutil.which('cl.exe',path=env['PATH'])
assert compiler
command=[compiler,'/nologo','/std:c++20','/O2','/MD','/EHsc','/DNOMINMAX',
         '/I'+str(build.PROJECT/'include'),'/I'+str(root/'CyrusLicensing/third_party'),
         str(source),str(native/'cpl_core.lib'),str(native/'jolt/Jolt.lib'),
         '/Fe:'+str(out/'native-leaf.exe'),'/Fo:'+str(out/'native-leaf.obj')]
with (out/'native-leaf-build.log').open('w') as log:
    subprocess.run(command,env=env,stdout=log,stderr=subprocess.STDOUT,check=True)
subprocess.run([str(out/'native-leaf.exe'),str(out/'native-leaf.json')],check=True)
(out/'native-leaf-receipt.json').write_text(json.dumps({
    'source_sha256':build.digest(source),'core_lib_sha256':build.digest(native/'cpl_core.lib'),
    'executable_sha256':build.digest(out/'native-leaf.exe'),'command':command},indent=2)+'\n')
