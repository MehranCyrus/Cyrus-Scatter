"""Launch a Max 2027 investigation in a fresh owned profile, preserving artist sessions."""
from pathlib import Path
import argparse,hashlib,importlib.util,json,os,re,subprocess,time
ROOT=Path(__file__).resolve().parents[3]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    p=argparse.ArgumentParser();p.add_argument('--output',required=True,type=Path);p.add_argument('--script',required=True,type=Path);p.add_argument('--visible',action='store_true');p.add_argument('--stay-open',action='store_true');p.add_argument('--timeout',type=int,default=360);a=p.parse_args();out=a.output.resolve();assert out.is_relative_to(ROOT/'build');out.mkdir(parents=True,exist_ok=False)
    spec=importlib.util.spec_from_file_location('owned',ROOT/'tools/procedural_lab/source_container_preview/launch.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
    for rel in mod.DIRECTORIES.values():(out/rel).mkdir(parents=True,exist_ok=True)
    template=Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini';original=template.read_bytes();ini=original.decode('utf-16')
    for key,rel in mod.DIRECTORIES.items():ini,n=re.subn(r'(?m)^'+re.escape(key)+r'=.*$',lambda _:key+'='+str(out/rel),ini);assert n==1,key
    (out/'max.ini').write_text(ini,encoding='utf-16');(out/'plugins.ini').write_text('[Directories]\nStandard=C:/Program Files/Autodesk/3ds Max 2027/stdplugs\n[Help]\n')
    package=ROOT/'build/garden-investigation-20261025-01/scatter-payload';native=ROOT/'build/vegetation-root-plugin-20261025-03'
    start='global GardenRun=@"'+out.as_posix()+'/"\ntry (\n'
    for name in ['AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm']:start+='loadDllsFromDir @"'+package.as_posix()+'/" "'+name+'"\n'
    start+='fileIn @"'+(package/'CyrusScatter.ms').as_posix()+'"\n'
    start+='loadDllsFromDir @"'+native.as_posix()+'/" "CyrusStemInspect.dlx"\n'
    start+='python.ExecuteFile @"'+(Path(__file__).parent/'verify_loaded_host.py').as_posix()+'"\n'
    if a.script.suffix=='.py':start+='python.ExecuteFile @"'+a.script.resolve().as_posix()+'"\n'
    else:start+='fileIn @"'+a.script.resolve().as_posix()+'"\n'
    start+=')catch((dotNetClass "System.IO.File").WriteAllText (GardenRun+"bootstrap-error.txt") (getCurrentException()+"\\n"+getCurrentExceptionStackTrace()))\n'
    (out/'start.ms').write_text(start,encoding='utf-8-sig');cmd=['C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe','-q','-silent','-i',str(out/'max.ini'),'-p',str(out/'plugins.ini'),'-U','MAXScript',str(out/'start.ms'),'-listenerlog',str(out/'listener.log')]
    si=subprocess.STARTUPINFO();si.dwFlags|=subprocess.STARTF_USESHOWWINDOW;si.wShowWindow=5 if a.visible else 0
    proc=subprocess.Popen(cmd,cwd=out,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,startupinfo=si);receipt={'pid':proc.pid,'host':2027,'command':cmd,'script':str(a.script.resolve()),'script_sha256':sha(a.script),'artist_ini_sha256':hashlib.sha256(original).hexdigest(),'native':{name:sha(package/name) for name in ['AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm']}};(out/'launch.json').write_text(json.dumps(receipt,indent=2));print('Owned Max 2027 PID',proc.pid,str(out),flush=True)
    if a.stay_open:return
    end=time.monotonic()+a.timeout
    while proc.poll() is None and time.monotonic()<end:time.sleep(1)
    if proc.poll() is None:proc.terminate();proc.wait(timeout=30);raise RuntimeError('Owned host timed out; evidence retained')
    assert template.read_bytes()==original,'Artist INI changed'
    for name in ['bootstrap-error.txt','error.txt']:
        if (out/name).exists():raise RuntimeError((out/name).read_text(encoding='utf-8-sig'))
    assert (out/'completed.json').exists(),'No completion marker'
    assert proc.returncode==0,'Owned Max exited unsuccessfully'
    assert json.loads((out/'loaded-identity.json').read_text())['status']=='pass','Loaded identity was not verified'
    receipt.update(status='pass',exit_code=proc.returncode,artist_ini_unchanged=True);(out/'receipt.json').write_text(json.dumps(receipt,indent=2));print('PASS owned investigation run')
if __name__=='__main__':main()
