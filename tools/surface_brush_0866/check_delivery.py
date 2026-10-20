"""Build shareable EXE and qualify its exact embedded package in owned profiles."""
from pathlib import Path
import argparse,hashlib,json,subprocess,zipfile,uuid
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'build/surface-brush-0866-20261019'
p=argparse.ArgumentParser();p.add_argument('package',type=Path);p.add_argument('--ui-only',action='store_true');a=p.parse_args();out=a.package.resolve();assert out.is_relative_to(BASE)
mzp=out/'CyrusScatter-0.86.6-Max2027.mzp';exe=out/'CyrusScatter-0.86.6-Setup.exe'
if not a.ui_only:subprocess.run(['python','-X','utf8',str(ROOT/'AminScatter/tools/build_installer.py'),'--output',str(exe),'--package',str(mzp),'--core',str(out/'staging/AminScatter/CyrusInstaller.dll')],check=True)
else:assert hashlib.sha256(exe.read_bytes()).hexdigest()==json.loads(exe.with_suffix('.build.json').read_text())['artifact_sha256'] and 'PASSED 34' in (out/'RecipientChecks-results.txt').read_text()
owned=Path('D:/CyrusScatterBuilds/if0866')/uuid.uuid4().hex[:6];owned.mkdir(parents=True)
if not a.ui_only:(out/'recipient-root.txt').write_text(str(owned))
else:assert (out/'recipient-root.txt').is_file(), 'Record the completed recipient root before resuming only UI checks'
old=ROOT/'dist/CyrusScatter-0.87.0-20261019/CyrusScatter-0.87.0-Max2027.mzp'
with zipfile.ZipFile(old) as z:
 assert z.testzip() is None
 for n in z.namelist():assert not Path(n).is_absolute() and '..' not in Path(n).parts
 z.extractall(owned/'old2027')
framework=Path('C:/Windows/Microsoft.NET/Framework64/v4.0.30319');compiler=Path('C:/Program Files/Microsoft Visual Studio/2022/Community/MSBuild/Current/Bin/Roslyn/csc.exe')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
logs={}
for name in ('RecipientChecks','UiChecks'):
 harness=out/(name+'.exe');source=Path(__file__).parent/(name+'.cs')
 if a.ui_only and name=='RecipientChecks':
  logs[name]={'source_sha256':sha(source),'log_sha256':sha(out/(name+'-results.txt'))};continue
 cmd=[str(compiler),'/nologo','/noconfig','/nostdlib+','/langversion:latest','/warnaserror+','/target:exe','/platform:x64','/out:'+str(harness),'/reference:'+str(exe),*('/reference:'+str(framework/(n+'.dll')) for n in ('mscorlib','System','System.Core','System.Drawing','System.Windows.Forms')),str(source)]
 r=subprocess.run(cmd,capture_output=True,text=True);(out/(name+'-compile.txt')).write_text(r.stdout+r.stderr);assert r.returncode==0,r.stdout+r.stderr
 r=subprocess.run([str(harness),str(exe),str(owned),str(out)],capture_output=True,text=True);log=out/(name+'-results.txt');log.write_text(r.stdout+r.stderr);print(r.stdout+r.stderr,flush=True);assert r.returncode==0
 logs[name]={'source_sha256':sha(source),'log_sha256':sha(log)}
(out/'exe-receipt.json').write_text(json.dumps({'status':'passed','version':'0.86.6','max_year':2027,'exe_sha256':sha(exe),'mzp_sha256':sha(mzp),'previous_mzp_sha256':sha(old),'owned_test_roots':{'recipient':(out/'recipient-root.txt').read_text(),'ui':str(owned)},'artist_installation':False,'logs':logs},indent=2)+'\n')
