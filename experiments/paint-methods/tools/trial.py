"""Portable local trial launcher packaged beside one DLL and Launch.ms."""
from pathlib import Path
import argparse,datetime,hashlib,json,os,re,shutil,subprocess,uuid
HERE=Path(__file__).resolve().parent
DIRECTORIES={'Additional Startup Scripts':'startup','Additional Scripts':'scripts','Additional Macros':'macros','PlugCFG':'plugcfg','Temp':'temp','Page File':'temp','AutoBackup':'project/autoback','ProjectFolder':'project','Scenes':'project/scenes','MaxStart':'project/scenes','MaxData':'maxdata','Hardware Shaders Cache':'shadercache','PlugCFG_ln':'plugcfg_ln','Additional Icons':'icons','Additional Startup Templates':'templates','Import':'project/import','Export':'project/export','Previews':'project/previews','RenderOutput':'project/renderoutput','Materials':'project/materiallibraries','Images':'project/images','Sounds':'project/sounds','Animations':'project/animations','RenderAssets':'project/renderassets','Archives':'project/archives','Downloads':'project/downloads','BitmapProxies':'project/proxies','VideoPost':'project/vpost','Expressions':'project/express','RenderPresets':'project/renderpresets'}
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--smoke',action='store_true',help='Test the packaged window in an owned hidden process');args=parser.parse_args()
    manifest=json.loads((HERE/'manifest.json').read_text())
    for name,sha in manifest['files'].items():
        if hashlib.sha256((HERE/name).read_bytes()).hexdigest()!=sha:raise RuntimeError('Package file changed: '+name)
    run=HERE/'sessions'/(datetime.datetime.now().strftime('%Y%m%d-%H%M%S')+'-'+uuid.uuid4().hex[:8]);run.mkdir(parents=True)
    ini=(Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini').read_text(encoding='utf-16')
    for key,rel in DIRECTORIES.items():
        dest=run/rel;dest.mkdir(parents=True,exist_ok=True)
        ini,count=re.subn(r'(?m)^'+re.escape(key)+'=.*$',lambda _:key+'='+str(dest),ini)
        if count!=1:raise RuntimeError('Cannot redirect profile key '+key)
    (run/'max.ini').write_text(ini,encoding='utf-16');(run/'bin').mkdir()
    name=f"PaintLab{manifest['method']}.dlx";shutil.copy2(HERE/name,run/'bin'/name)
    (run/'plugins.ini').write_text('[Directories]\nAdditional MAX plug-ins=C:/Program Files/Autodesk/3ds Max 2027/PlugIns\nPaintLab='+str(run/'bin')+'\n[Help]\n')
    startup='''try (
local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(), found=false
for i=0 to process.Modules.Count-1 do (
 local module=process.Modules.Item[i]
 if matchPattern (toLower module.ModuleName) pattern:"*cyrus*" or toLower module.ModuleName=="aminscatter.dlx" do throw "Unexpected Cyrus module in isolated trial"
 if toLower module.ModuleName=="__DLL__" do (
  if toLower ((dotNetClass "System.IO.Path").GetFullPath module.FileName)!=toLower ((dotNetClass "System.IO.Path").GetFullPath @"__EXPECTED__") do throw "Trial module path mismatch"
  found=true
 )
)
if not found do throw "Trial module did not load"
fileIn @"__UI__"
local receiver=plane name:"PaintLab_Receiver" length:1000 width:1000 lengthsegs:1 widthsegs:1
select receiver
max zoomext sel all
__SMOKE__
)catch(__ERROR__)
'''.replace('__UI__',(HERE/'Launch.ms').as_posix()).replace('__DLL__',name.lower()).replace('__EXPECTED__',(run/'bin'/name).as_posix())
    letter='ABCD'[manifest['method']-1]
    startup=f'global PL_{letter}\n'+startup
    smoke=f'''PL_{letter}.addReceiver receiver
PL_{letter}.beginPainting()
PL_{letter}.endPainting()
destroyDialog PL_{letter}
paintLab{letter} "shutdown" #()
(dotNetClass "System.IO.File").WriteAllText @"{(run/'done.txt').as_posix()}" "SUCCESS"
'''
    startup=startup.replace('__SMOKE__',smoke if args.smoke else '').replace('__ERROR__',f'(dotNetClass "System.IO.File").WriteAllText @"{(run/"error.txt").as_posix()}" (getCurrentException()+"\\n"+getCurrentExceptionStackTrace())' if args.smoke else 'messageBox (getCurrentException()) title:"Paint Methods Lab"')
    if args.smoke:startup+='quitMax #noPrompt\n'
    (run/'start.ms').write_text(startup,encoding='utf-8-sig')
    cmd=['C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe','-q','-i',str(run/'max.ini'),'-p',str(run/'plugins.ini'),'-U','MAXScript',str(run/'start.ms')]
    info=subprocess.STARTUPINFO();info.dwFlags|=subprocess.STARTF_USESHOWWINDOW;info.wShowWindow=0 if args.smoke else 1
    process=subprocess.Popen(cmd,cwd=run,startupinfo=info)
    (run/'launch.json').write_text(json.dumps({'pid':process.pid,'command':cmd,'package':manifest,'normal_profile_modified':False,'smoke':args.smoke},indent=2))
    print(json.dumps({'pid':process.pid,'session':str(run)}))
if __name__=='__main__':main()
