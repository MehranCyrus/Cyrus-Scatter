"""Build only the native host/core with private publication faults; never package."""
from pathlib import Path
import importlib.util,json,hashlib
ROOT=Path(__file__).resolve().parents[3]
spec=importlib.util.spec_from_file_location('lab_build',ROOT/'CyrusPhysicsLab/tools/build.py')
b=importlib.util.module_from_spec(spec);spec.loader.exec_module(b)
pins=b.dependencies();folder=ROOT/'build/physics-bake-020-20261018-01/native-faults';folder.mkdir(exist_ok=True)
env=b.compiler_environment()
sdk=ROOT/'build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk'
command=['cmake','-S',str(b.PROJECT),'-B',str(folder),'-G','Ninja','-DCMAKE_BUILD_TYPE=Release',f"-DJOLT_SOURCE={pins['jolt']}",f"-DPHYSX_SOURCE={pins['physx']}",f'-DMAXSDK_ROOT={sdk}','-DCYRUS_MAX_YEAR=2027','-DCPL_TEST_FAULTS=ON']
before={str(p.relative_to(b.PROJECT)):b.digest(p) for p in b.PROJECT.rglob('*') if p.is_file() and '__pycache__' not in p.parts}
b.run(command,folder,'configure',env)
b.run(['cmake','--build',str(folder),'--target','CyrusPhysicsStorage','--parallel','4'],folder,'build',env)
after={str(p.relative_to(b.PROJECT)):b.digest(p) for p in b.PROJECT.rglob('*') if p.is_file() and '__pycache__' not in p.parts}
assert before==after,'Sources changed during fault build'
(folder/'private-fault-receipt.json').write_text(json.dumps({'faults':True,'package_allowed':False,'max_year':2027,'source_hashes':after,'binaries':{p.name:b.digest(p) for p in folder.glob('*') if p.suffix in ('.dlx','.dlh','.exe')}},indent=2))
