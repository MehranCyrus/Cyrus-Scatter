from pathlib import Path
import subprocess,json,importlib.util,hashlib
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent;OUT=ROOT/'build/full-system-review-08763-20261029-01/supplemental';OUT.mkdir(exist_ok=False)
def run(cmd,name,env=None):
 p=subprocess.run(list(map(str,cmd)),cwd=OUT,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=120);(OUT/(name+'.log')).write_text(p.stdout,encoding='utf-8');print(name,p.returncode);print(p.stdout[-4000:]);p.check_returncode();return p.stdout
csc=Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe');fw=Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319')
sources=sorted((ROOT/'AminScatter/shared').glob('*.cs'))+[HERE/'library_probe.cs'];exe=OUT/'library_probe.exe'
run([csc,'/nologo','/noconfig','/nostdlib+','/langversion:latest','/warnaserror+','/target:exe','/platform:x64','/out:'+str(exe),*('/reference:'+str(fw/(x+'.dll')) for x in ('mscorlib','System','System.Core','System.IO.Compression')),*sources],'managed-compile')
run([exe,ROOT/'build/r8763-extra01'],'managed')
spec=importlib.util.spec_from_file_location('build_max',ROOT/'tools/build_max.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
vs=Path('C:/Program Files/Microsoft Visual Studio/2022/Community');env=mod.compiler_environment(vs,'14.38.33130','10.0.19041.0');cl=vs/'VC/Tools/MSVC/14.38.33130/bin/Hostx64/x64/cl.exe'
fixtures=OUT/'synthetic-license-fixtures';run([ROOT/'build/mcp-venv/Scripts/python.exe',ROOT/'tools/licensing_lab/make_signed_fixtures.py',fixtures],'test-authority')
libs=ROOT/'build/full-system-review-08763-20261029-01/native/license-core'
for target,source in [('signed_tests','CyrusLicensing/tests/signed_license_tests.cpp'),('permit_benchmark','tools/licensing_lab/permit_benchmark.cpp')]:
 inc=[ROOT/'CyrusLicensing/include',ROOT/'CyrusLicensing/third_party',ROOT/'tools/licensing_lab',fixtures]
 run([cl,'/nologo','/std:c++20','/EHsc','/O2','/MD','/W4','/WX','/DNOMINMAX','/DCYRUS_SIGNED_LICENSE_LAB_ONLY=1',*('/I'+str(p) for p in inc),ROOT/source,'/Fe:'+str(OUT/(target+'.exe')),'/Fo:'+str(OUT/(target+'.obj')),libs/'cyrus_license_token.lib',libs/'cyrus_license_policy.lib','bcrypt.lib','crypt32.lib'],target+'-compile',env)
 if target=='signed_tests':
  for group in ('profile','signature','claims','scope','lifecycle','isolation','permits','publication','transfer','activation'):run([OUT/(target+'.exe'),fixtures/'vectors.json',group],'signed-'+group)
 else:run([OUT/(target+'.exe'),fixtures/'vectors.json'],'permit-benchmark')
(OUT/'source-hashes.json').write_text(json.dumps({str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sources},indent=2))
