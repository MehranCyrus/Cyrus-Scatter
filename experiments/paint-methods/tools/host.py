"""Owned isolated Max profiles for this lab. Never attaches to another session."""
from pathlib import Path
import argparse,datetime,hashlib,json,os,re,shutil,subprocess,time,uuid
LAB=Path(__file__).resolve().parents[1]
MAX=Path('C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe')
DIRECTORIES={'Additional Startup Scripts':'startup','Additional Scripts':'scripts','Additional Macros':'macros','PlugCFG':'plugcfg','Temp':'temp','Page File':'temp','AutoBackup':'project/autoback','ProjectFolder':'project','Scenes':'project/scenes','MaxStart':'project/scenes','MaxData':'maxdata','Hardware Shaders Cache':'shadercache','PlugCFG_ln':'plugcfg_ln','Additional Icons':'icons','Additional Startup Templates':'templates','Import':'project/import','Export':'project/export','Previews':'project/previews','RenderOutput':'project/renderoutput','Materials':'project/materiallibraries','Images':'project/images','Sounds':'project/sounds','Animations':'project/animations','RenderAssets':'project/renderassets','Archives':'project/archives','Downloads':'project/downloads','BitmapProxies':'project/proxies','VideoPost':'project/vpost','Expressions':'project/express','RenderPresets':'project/renderpresets'}
FOLDERS=['01-vector-regions','02-tiled-mask','03-surface-volumes','04-surface-field']
def digest(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def launch(build,method=None,visible=False):
    build=Path(build).resolve();receipt=json.loads((build/'build-receipt.json').read_text())
    folder=LAB/'build/hosts'/(datetime.datetime.now().strftime('%Y%m%d-%H%M%S')+'-'+uuid.uuid4().hex[:8])
    folder.mkdir(parents=True,exist_ok=False)
    ini=(Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini').read_text(encoding='utf-16')
    for key,rel in DIRECTORIES.items():
        dest=folder/rel;dest.mkdir(parents=True,exist_ok=True)
        ini,count=re.subn(r'(?m)^'+re.escape(key)+'=.*$',lambda _:key+'='+str(dest),ini)
        if count!=1:raise RuntimeError('Cannot redirect profile key '+key)
    (folder/'max.ini').write_text(ini,encoding='utf-16');(folder/'bin').mkdir()
    methods=[method] if method else [1,2,3,4]
    hashes={}
    for m in methods:
        name=f'PaintLab{m}.dlx';source=build/name
        if digest(source)!=receipt['binaries'][name]:raise RuntimeError('Unmatched binary '+name)
        shutil.copy2(source,folder/'bin'/name);hashes[name]=digest(source)
    (folder/'plugins.ini').write_text('[Directories]\nAdditional MAX plug-ins=C:/Program Files/Autodesk/3ds Max 2027/PlugIns\nPaintLab='+str(folder/'bin')+'\n[Help]\n')
    expected=','.join('#(@"'+n+'",@"'+(folder/'bin'/n).as_posix()+'")' for n in hashes)
    action=('fileIn @"'+(LAB/'methods'/FOLDERS[method-1]/'scripts/Launch.ms').as_posix()+'"\nlocal receiver=plane name:"PaintLab_Receiver" length:1000 width:1000 lengthsegs:1 widthsegs:1\nselect receiver\nmax zoomext sel all\n') if method else 'fileIn @"'+(LAB/'tests/host_tests.ms').as_posix()+'"\n'
    script='global PaintLabSource=@"'+LAB.as_posix()+'"\nglobal PaintLabRun=@"'+folder.as_posix()+'/"\ntry (\nlocal expected=#('+expected+'''), process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
local log=createFile (PaintLabRun+"loaded.tsv")
for i=0 to process.Modules.Count-1 do (
 local mod=process.Modules.Item[i]
 if matchPattern (toLower mod.ModuleName) pattern:"*cyrus*" or toLower mod.ModuleName=="aminscatter.dlx" do throw ("Unexpected production module: "+mod.FileName)
 for item in expected where toLower item[1]==toLower mod.ModuleName do (
  if toLower ((dotNetClass "System.IO.Path").GetFullPath mod.FileName)!=toLower ((dotNetClass "System.IO.Path").GetFullPath item[2]) do throw ("Loaded module path mismatch: "+mod.FileName)
  format "%\\t%\\n" mod.ModuleName mod.FileName to:log
 )
)
close log
for item in expected do (
 local found=false
 for i=0 to process.Modules.Count-1 where toLower process.Modules.Item[i].ModuleName==toLower item[1] do found=true
 if not found do throw ("Missing module "+item[1])
)
'''+action+'''
(dotNetClass "System.IO.File").WriteAllText (PaintLabRun+"done.txt") "SUCCESS"
) catch ((dotNetClass "System.IO.File").WriteAllText (PaintLabRun+"error.txt") (getCurrentException()+"\\n"+getCurrentExceptionStackTrace()))
'''
    if not visible:script+='quitMax #noPrompt\n'
    (folder/'start.ms').write_text(script,encoding='utf-8-sig')
    command=[str(MAX),'-q','-i',str(folder/'max.ini'),'-p',str(folder/'plugins.ini'),'-U','MAXScript',str(folder/'start.ms'),'-listenerlog',str(folder/'listener.log')]
    startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=1 if visible else 0
    process=subprocess.Popen(command,cwd=folder,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,startupinfo=startup)
    meta={'pid':process.pid,'folder':str(folder),'binaries':hashes,'command':command,'normal_profile_modified':False,'visible':visible,'test_script_hash':digest(LAB/'tests/host_tests.ms') if not method else None}
    (folder/'launch.json').write_text(json.dumps(meta,indent=2));print(json.dumps(meta,indent=2),flush=True);return process,folder
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--build',type=Path,required=True);ap.add_argument('--method',type=int,choices=[1,2,3,4]);ap.add_argument('--visible',action='store_true');args=ap.parse_args();launch(args.build,args.method,args.visible)
if __name__=='__main__':main()
