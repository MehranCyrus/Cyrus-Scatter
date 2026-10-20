"""Restart an owned profile using the installed native/script registration."""
from pathlib import Path
import argparse,hashlib,json,subprocess,time
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--from-host',required=True);p.add_argument('--name',required=True);a=p.parse_args()
assert a.from_host.startswith('density0862-installer-') and a.name.startswith('density0862-installer-')
previous=ROOT/'build/mcp-qualification'/a.from_host;prior=json.loads((previous/'launch.json').read_text())
assert (previous/'shutdown.txt').is_file(),'Close the preceding owned process first'
profile=Path(prior['short_profile']).resolve();assert profile.parent==ROOT/'build' and profile.name.startswith('if')
host=ROOT/'build/mcp-qualification'/a.name;host.mkdir(exist_ok=False)
year=prior['max_year'];release=Path(json.loads((previous/'mzp.json').read_text())['release']);assert release.is_relative_to(profile)
candidate=json.loads((ROOT/'build/installer-0862-20261019-01/package03/candidate.json').read_text())['packages'][str(year)]
sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
modules={n:sha(release/'bin'/n) for n in prior['binaries']}
for name,digest in modules.items():assert digest==candidate['manifest']['files'][name],name
for name in ('CyrusScatter.ms','CyrusGallery.dll'):assert sha(release/name)==candidate['manifest']['files'][name],name
plugins=profile/'installed-plugins.ini';plugins.write_text(f'[Directories]\nAdditional MAX plug-ins=C:/Program Files/Autodesk/3ds Max {year}/PlugIns\nCyrusInstalled={release / "bin"}\n[Help]\n')
expected=','.join('#(@"'+name+'",@"'+str(release/'bin'/name)+'")' for name in modules)
fingerprint=(release/'CyrusScatter.ms').read_text(encoding='utf-8-sig').splitlines()[0].split('"')[1]
code='''global CyrusPerfHeadless=true,MCPFixtureDir=@"__HOST__/"
setSilentMode false
setQuietMode false
try (
 local expected=#(__EXPECTED__),p=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
 local log=createFile (MCPFixtureDir+"loaded.tsv")
 for spec in expected do (
  local found=false
  for i=0 to p.Modules.Count-1 do (
   local m=p.Modules.Item[i]
   if toLower m.ModuleName==toLower spec[1] do (
    if toLower m.FileName!=toLower spec[2] do throw ("Mixed installed module: "+m.FileName)
    found=true;format "%\\t%\\n" m.ModuleName m.FileName to:log
   )
  )
  if not found do throw ("Missing installed module: "+spec[1])
 )
 close log
 if AminScatterObject==undefined do throw "Registered startup did not load the installed Scatter script"
 if CyrusLoadedScriptFingerprint!="__FINGERPRINT__" do throw "Installed script fingerprint differs"
 fileIn @"__TRANSPORT__"
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"ready.json") "{}"
)catch((dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"startup-error.txt") (getCurrentException()+"\\n"+getCurrentExceptionStackTrace()))
'''.replace('__HOST__',host.as_posix()).replace('__EXPECTED__',expected).replace('__FINGERPRINT__',fingerprint).replace('__TRANSPORT__',(ROOT/'tools/mcp/development_transport.ms').as_posix())
script=profile/'installed-start.ms';script.write_text(code,encoding='utf-8-sig')
command=[f'C:/Program Files/Autodesk/3ds Max {year}/3dsmax.exe','-q','-silent','-i',str(profile/'max.ini'),'-p',str(plugins),'-U','MAXScript',str(script),'-listenerlog',str(host/'listener.log')]
si=subprocess.STARTUPINFO();si.dwFlags|=subprocess.STARTF_USESHOWWINDOW;si.wShowWindow=0
process=subprocess.Popen(command,cwd=profile,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,startupinfo=si)
meta={**prior,'pid':process.pid,'command':command,'installed_release':str(release),'binaries':modules,'script_sha256':sha(release/'CyrusScatter.ms'),'script_fingerprint':fingerprint,'normal_profile_modified':False,'startup_filein_product':False}
(host/'launch.json').write_text(json.dumps(meta,indent=2)+'\n')
import shutil
shutil.copytree(release/'Patterns',host/'scripts/Patterns')
print(json.dumps(meta),flush=True)
deadline=time.monotonic()+240
while time.monotonic()<deadline:
 if (host/'startup-error.txt').exists():raise RuntimeError((host/'startup-error.txt').read_text())
 if (host/'ready.json').exists():print('Installed startup ready',flush=True);break
 if process.poll()!=None:raise RuntimeError('Owned installed host exited')
 time.sleep(.3)
else:raise TimeoutError('Observe this owned process before another launch')
