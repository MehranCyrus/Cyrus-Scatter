from pathlib import Path
import sys,subprocess
root=Path.cwd();run=root/'build/edit-size-review-20261029-01';sys.path.insert(0,str(root/'tools'));import build_max
env=build_max.compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0');out=run/'violet-native';out.mkdir(exist_ok=True)
native=run/(sys.argv[1] if len(sys.argv)>1 else 'final-0877-native')
includes=['AminScatter/include','CyrusVegetationLab/experiments/stem-live','CyrusVegetationLab/core/include','CyrusLicensing/third_party']
cmd=['C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.38.33130/bin/Hostx64/x64/cl.exe','/nologo','/std:c++20','/EHsc','/MD','/O2','/DNOMINMAX',*['/I'+str(root/p) for p in includes],str(run/'violet_contact.cpp'),'/Fe:'+str(out/'violet_contact.exe'),'/link',str(native/'amin_scatter.lib'),str(native/'cyrus_interaction_rig.lib'),str(native/'cyrus_vector_clip.lib'),'bcrypt.lib']
result=subprocess.run(cmd,cwd=out,env=env,capture_output=True,text=True);(out/'contact-build.log').write_text(result.stdout+result.stderr);print(result.stdout[-2000:]+result.stderr);sys.exit(result.returncode)
