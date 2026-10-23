"""Qualify installed combined-EXE bytes in explicitly requested owned hosts."""
from pathlib import Path
import argparse,hashlib,json,os,re,shutil,subprocess,sys,time,uuid
ROOT=Path(__file__).resolve().parents[2];WORK=ROOT/'build/combined-installer-08685-20261022'
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import DIRECTORIES
sys.path.insert(0,str(ROOT/'tools/quality_validation'))
from host import wait_ready,run
from results import artifact_identity

def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def read(p):return json.loads(Path(p).read_text(encoding='utf-8'))
def launch(year,checks,attempt):
    checked=read(WORK/checks/'receipt.json');assert checked['exit_code']==0 and checked['checks']>=110
    rows=[line.split('\t') for line in (WORK/checks/'results/recipients.tsv').read_text(encoding='utf-8-sig').splitlines()]
    row=next(x for x in rows if x[0]==str(year));profile,scatter,analyzer=map(Path,row[1:])
    assert all(p.resolve().is_relative_to(WORK) for p in [profile,scatter,analyzer])
    folder=WORK/f'{attempt}-{year}';folder.mkdir(exist_ok=False)
    seed=Path(os.environ['LOCALAPPDATA'])/f'Autodesk/3dsMax/{year} - 64bit/ENU/3dsMax.ini'
    text=seed.read_bytes().decode('utf-16')
    destinations={'Additional Scripts':profile/'scripts','Additional Startup Scripts':profile/'startup','Additional Macros':profile/'macros'}
    for key,rel in DIRECTORIES.items():
        path=destinations.get(key,folder/rel);path.mkdir(parents=True,exist_ok=True)
        text,count=re.subn(r'(?m)^'+re.escape(key)+'=.*$',lambda _:key+'='+str(path),text);assert count==1,key
    ini=profile/'3dsMax.ini';ini.write_text(text,encoding='utf-16')
    schema=ROOT/'build/mcp-qualification/update08671-test-clearance-baseline-2027/schema58.max' if year==2027 else ROOT/'build/mcp-qualification/update08671-test-final4-2024/texture-persistence.max'
    (folder/'fixtures').mkdir();schema_copy=folder/'fixtures/schema58.max';shutil.copy2(schema,schema_copy)
    paths={'Scatter':scatter/'CyrusScatter.ms','AnalyzerScript':analyzer/'CyrusSurfaceAnalyzer.ms','CyrusGallery.dll':scatter/'CyrusGallery.dll',
           'ScatterStartup':profile/'startup/CyrusScatterStartup.ms','AnalyzerStartup':profile/'startup/CyrusSurfaceAnalyzerStartup.ms','schema58_input':schema_copy}
    for name in ['AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm']:paths[name]=scatter/'bin'/name
    paths['CyrusSurfaceAnalyzer.dlx']=analyzer/'bin/CyrusSurfaceAnalyzer.dlx'
    for p in (ROOT/'tools/quality_validation').iterdir():
        if p.suffix in ('.py','.ms','.cs','.cpp','.ps1'):paths['fixture:'+p.name]=p
    paths['driver:combined_host']=Path(__file__);paths['scenario_manifest']=ROOT/'tools/quality_validation/scenarios.json'
    identity,hashes=artifact_identity(paths)
    modules={n:p for n,p in paths.items() if n.endswith(('.dlx','.dlh','.dlm'))}
    expected=','.join('#(@"'+n+'",@"'+p.as_posix()+'")' for n,p in modules.items())
    script='''global AminScatterObject,CyrusSurfaceAnalyzer,CyrusPerfHeadless=true,MCPFixtureDir=@"__FOLDER__/",QSchemaFixture=@"__SCHEMA__"
fileIn @"__TRANSPORT__"
setSilentMode false
setQuietMode false
try (
 if AminScatterObject==undefined or CyrusSurfaceAnalyzer==undefined do throw "Installed startup did not load both product classes"
 if (maxVersion())[1]!=__HOST__ do throw "Wrong Max host"
 if cyrusAnalyzerContractVersion()!=1 do throw "Wrong Analyzer native contract"
 local expected=#(__EXPECTED__),process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(),pathUtil=dotNetClass "System.IO.Path",log=createFile (MCPFixtureDir+"loaded.tsv")
 for spec in expected do (
  local found=false
  for i=0 to process.Modules.Count-1 do (
   local module=process.Modules.Item[i]
   if toLower module.ModuleName==toLower spec[1] do (
    if toLower (pathUtil.GetFullPath module.FileName)!=toLower (pathUtil.GetFullPath spec[2]) do throw ("Mixed installed module: "+module.FileName)
    found=true;format "%\\t%\\n" module.ModuleName module.FileName to:log
   )
  )
  if not found do throw ("Installed module missing: "+spec[1])
 )
 close log
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"ready.json") "{}"
)catch((dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"startup-error.txt") (getCurrentException()+"\\n"+getCurrentExceptionStackTrace()))
'''
    for token,value in {'__FOLDER__':folder.as_posix(),'__SCHEMA__':schema_copy.as_posix(),'__TRANSPORT__':(ROOT/'tools/mcp/development_transport.ms').as_posix(),'__HOST__':str((year-1998)*1000),'__EXPECTED__':expected}.items():script=script.replace(token,value)
    start=folder/'start.ms';start.write_text(script,encoding='utf-8-sig')
    command=[f'C:/Program Files/Autodesk/3ds Max {year}/3dsmax.exe','-q','-silent','-i',str(ini),'-p',str(profile/'Plugin.UserSettings.ini'),'-U','MAXScript',str(start),'-listenerlog',str(folder/'listener.log')]
    env=os.environ.copy()
    for key,name in [('ADSK_3DSMAX_APPDATA_DIR','userdata'),('ADSK_3DSMAX_USERSETTINGS_DIR','usersettings'),('ADSK_3DSMAX_USERTOOLS_DIR','usertools')]:
        p=folder/name;p.mkdir();env[key]=str(p)
    startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
    process=subprocess.Popen(command,cwd=folder,env=env,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,startupinfo=startup)
    metadata={'run_id':uuid.uuid4().hex,'artifact_id':identity,'hashes':hashes,'paths':{n:str(p) for n,p in paths.items()},'pid':process.pid,'max_year':year,'command':command,'profile_ini':str(ini),'installed_profile':str(profile),'schema_input_source':str(schema),'schema_input_sha256':sha(schema),'installer_exe_sha256':checked['exe_sha256']}
    (folder/'qualification.json').write_text(json.dumps(metadata,indent=2)+'\n',encoding='utf-8');print(json.dumps({'pid':process.pid,'folder':str(folder)}),flush=True)
    wait_ready(folder,180);return folder

def main():
    p=argparse.ArgumentParser();p.add_argument('action',choices=['launch','batch','close','observe','rebind']);p.add_argument('--year',type=int,choices=[2024,2026,2027],required=True);p.add_argument('--checks',default='checks02');p.add_argument('--attempt',default='host01');a=p.parse_args()
    if not a.checks.isalnum() or not a.attempt.isalnum():raise ValueError('Owned alphanumeric run required')
    folder=WORK/f'{a.attempt}-{a.year}'
    if a.action=='launch':launch(a.year,a.checks,a.attempt);return
    if a.action=='rebind':
        path=folder/'qualification.json';old=read(path)
        if (folder/'dev-request.txt').exists():raise RuntimeError('Explicit rebind is allowed only before the first mutation in this compatibility runner')
        for n,p in old['paths'].items():
            if not n.startswith(('fixture:','driver:')) and n!='scenario_manifest':assert sha(p)==old['hashes'][n],n
        (folder/('qualification-'+old['run_id']+'.json')).write_bytes(path.read_bytes())
        if (folder/'batch.json').exists():shutil.copy2(folder/'batch.json',folder/('batch-'+old['run_id']+'.json'))
        identity,hashes=artifact_identity({n:Path(p) for n,p in old['paths'].items()})
        old.update(parent_run_id=old['run_id'],run_id=uuid.uuid4().hex,artifact_id=identity,hashes=hashes,profile_ini=str(Path(old['installed_profile'])/'3dsMax.ini'))
        path.write_text(json.dumps(old,indent=2)+'\n',encoding='utf-8');print('Rebound unchanged installed product with explicit fixture successor');return
    if a.action=='observe':
        for n in ['startup-error.txt','dev-result.txt']:
            if (folder/n).exists():print((folder/n).read_text(encoding='utf-8-sig'))
        return
    if a.action=='close':
        request=folder/'close-owned.ms';request.write_text('quitMax #noPrompt\n',encoding='utf-8-sig');(folder/'dev-request.txt').write_text(request.as_posix(),encoding='utf-8-sig');return
    wait_ready(folder,5)
    previous=read(ROOT/'build/installer-panels-08684-20261022/host-final03/batch-final.json')
    ids=[x['scenario'] for x in previous if x['scenario'] not in ['UI84-SDKORDER','INSTALL84-HOST','R6-M01']]
    manifest=read(ROOT/'tools/quality_validation/scenarios.json');rows=[]
    for name in ids:
        scenario=next(s for s in manifest['scenarios'] if s['id']==name);start=time.monotonic()
        try:r=run(folder,scenario,timeout=180);status=r['status'];error=r.get('error','')
        except Exception as exc:status='fail';error=str(exc)
        row={'scenario':name,'status':status,'seconds':round(time.monotonic()-start,2),'error':error};rows.append(row)
        (folder/'batch.json').write_text(json.dumps(rows,indent=2)+'\n',encoding='utf-8');print(json.dumps(row),flush=True)
        if status!='pass':raise RuntimeError('Observe the failed/original request before any continuation: '+name)
    print('Passed',len(rows),'installed-host scenarios',flush=True)
if __name__=='__main__':main()
