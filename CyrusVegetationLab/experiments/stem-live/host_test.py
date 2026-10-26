"""Owned Max 2027 profile runner for Preparation Lab. No artist install or restart."""
from pathlib import Path
import argparse,hashlib,importlib.util,json,os,re,subprocess,time
ROOT=Path(__file__).resolve().parents[3];HERE=Path(__file__).resolve().parent
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def main():
    p=argparse.ArgumentParser();p.add_argument('--build',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--fixture',type=Path,required=True);p.add_argument('--kit',type=Path);p.add_argument('--visible',action='store_true');p.add_argument('--timeout',type=int,default=240);a=p.parse_args();out=a.output.resolve();native=a.build.resolve();fixture=a.fixture.resolve()
    if not out.is_relative_to(ROOT/'build'):raise RuntimeError('Profile must stay under build/')
    out.mkdir(parents=True,exist_ok=False);r=json.loads((native/'receipt.json').read_text());assert r['status']=='complete' and r['host']==2027
    for name,expected in {**r['sources'],**r['dependencies']}.items():
        if sha(ROOT/name)!=expected:raise RuntimeError('Build input changed: '+name)
    spec=importlib.util.spec_from_file_location('owned',ROOT/'tools/procedural_lab/source_container_preview/launch.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
    for relative in mod.DIRECTORIES.values():(out/relative).mkdir(parents=True,exist_ok=True)
    template=Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini';original=template.read_bytes();ini=original.decode('utf-16')
    for key,relative in mod.DIRECTORIES.items():
        ini,count=re.subn(r'(?m)^'+re.escape(key)+r'=.*$',lambda _:key+'='+str(out/relative),ini)
        assert count==1,key
    (out/'max.ini').write_text(ini,encoding='utf-16');(out/'plugins.ini').write_text('[Directories]\nStandard=C:/Program Files/Autodesk/3ds Max 2027/stdplugs\n[Help]\n')
    load='\n'.join('loadDllsFromDir @"'+native.as_posix()+'/" "'+name+'"' for name in ('CyrusVegetationStemLab.dlx','CyrusVegetationStemGeometry.dlo'))
    ui='fileIn @"'+(HERE/'PreparationLab.ms').as_posix()+'"'
    if a.kit:load='global CVPKitRoot=@"'+a.kit.resolve().as_posix()+'/"';ui=''
    start='''global CVLTestDir=@"__OUT__/"
fn cvlStage s = ((dotNetClass "System.IO.File").AppendAllText (CVLTestDir+"stages.txt") (s+"\\n"))
try (
__LOAD__
__UI__
fileIn @"__FIXTURE__"
(dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"completed.json") "{}"
)catch((dotNetClass "System.IO.File").WriteAllText (CVLTestDir+"error.txt") (getCurrentException()+"\\n"+getCurrentExceptionStackTrace()))
quitMax #noPrompt
'''.replace('__OUT__',out.as_posix()).replace('__LOAD__',load).replace('__UI__',ui).replace('__FIXTURE__',fixture.as_posix())
    (out/'start.ms').write_text(start,encoding='utf-8-sig');cmd=['C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe','-q','-silent','-i',str(out/'max.ini'),'-p',str(out/'plugins.ini'),'-U','MAXScript',str(out/'start.ms'),'-listenerlog',str(out/'listener.log')]
    si=subprocess.STARTUPINFO();si.dwFlags|=subprocess.STARTF_USESHOWWINDOW;si.wShowWindow=5 if a.visible else 0
    process=subprocess.Popen(cmd,cwd=out,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,startupinfo=si);record={'pid':process.pid,'command':cmd,'native':r['binaries'],'fixture_sha256':sha(fixture),'ui_sha256':sha(HERE/'PreparationLab.ms'),'status':'running','host':2027};(out/'launch.json').write_text(json.dumps(record,indent=2));print('Owned Max 2027 PID',process.pid,str(out),flush=True)
    end=time.monotonic()+a.timeout
    while process.poll() is None and time.monotonic()<end:time.sleep(1)
    if process.poll() is None:process.terminate();process.wait(timeout=30);raise RuntimeError('Owned host timed out; logs preserved')
    assert template.read_bytes()==original,'Artist INI changed'
    if (out/'error.txt').exists():raise RuntimeError((out/'error.txt').read_text(encoding='utf-8-sig'))
    if not (out/'completed.json').exists():raise RuntimeError('No completion marker: '+str(process.returncode))
    record.update(status='pass',exit_code=process.returncode,artist_ini_unchanged=True);(out/'receipt.json').write_text(json.dumps(record,indent=2));print('PASS owned Max 2027 fixture',flush=True)
if __name__=='__main__':main()
