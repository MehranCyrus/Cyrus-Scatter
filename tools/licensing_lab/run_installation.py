"""Real CNG/DPAPI/clock activation -> expiry -> cold Max render -> renewal.

Development authority only. No external service, artist install or customer grant.
"""
from pathlib import Path
import argparse,json,os,re,shutil,subprocess,time,uuid,sys
import psutil
from PIL import Image,ImageChops
from run import ROOT,snapshot,run_command,write_json,digest,compiler_environment
sys.path.insert(0,str(ROOT/'tools/procedural_lab'))
from runtime_driver import run_script

def launch_private(source,out,native,label,startup_source=None,profile_prefix='licensing-installation'):
    if not re.fullmatch(r'[a-z0-9-]+',profile_prefix):raise ValueError('Invalid private profile prefix')
    folder=ROOT/'build/mcp-qualification'/(profile_prefix+'-'+out.name+'-'+label)
    folder.mkdir(parents=True,exist_ok=False)
    for name in ['startup','scripts','macros','plugcfg','temp','autoback','bin']:(folder/name).mkdir()
    for path in native.glob('*.dl?'):shutil.copy2(path,folder/'bin'/path.name)
    ini=(Path(os.environ['LOCALAPPDATA'])/'Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini').read_text(encoding='utf-16')
    for key,directory in {'Additional Startup Scripts':'startup','Additional Scripts':'scripts','Additional Macros':'macros',
                          'PlugCFG':'plugcfg','Temp':'temp','Page File':'temp','AutoBackup':'autoback'}.items():
        ini,count=re.subn(rf'(?m)^{re.escape(key)}=.*$',lambda _:key+'='+str(folder/directory),ini)
        if count!=1:raise RuntimeError('Private profile field mismatch: '+key)
    (folder/'max.ini').write_text(ini,encoding='utf-16')
    (folder/'plugins.ini').write_text('[Directories]\nAdditional MAX plug-ins=C:/Program Files/Autodesk/3ds Max 2027/PlugIns\nCyrusLab='+str(folder/'bin')+'\n[Help]\n')
    start=folder/'start.ms'
    if startup_source is None:startup_source='fileIn @"'+(source/'tools/licensing_lab/installation_fixture.ms').as_posix()+'"\n'
    start.write_text('global MCPFixtureDir="'+folder.as_posix()+'/"\nfileIn @"'+(ROOT/'tools/mcp/development_transport.ms').as_posix()+'"\n'+startup_source+
        '(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"ready.json") "{}"\n')
    command=['C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe','-q','-i',str(folder/'max.ini'),'-p',str(folder/'plugins.ini'),'-U','MAXScript',str(start),'-listenerlog',str(folder/'listener.log')]
    startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
    process=subprocess.Popen(command,cwd=ROOT,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,startupinfo=startup)
    write_json(folder/'launch.json',{'pid':process.pid,'output':str(folder),'command':command,
        'binaries':{p.name:digest(p) for p in (folder/'bin').iterdir()}})
    return process,folder

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--run',required=True);args=parser.parse_args()
    if not re.fullmatch(r'[a-z0-9-]+',args.run):raise SystemExit('Invalid run name')
    out=ROOT/'build/licensing-native-20261005'/('installation-'+args.run);out.mkdir(parents=True,exist_ok=False)
    source=snapshot(out);fixtures=out/'fixtures';fixtures.mkdir()
    issuer=subprocess.Popen([str(ROOT/'build/licensing-l1-tools-2026-10-04/Scripts/python.exe'),str(source/'tools/licensing_lab/local_issuer.py')],
        stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
    key='CyrusLicensing-PRIVATE-TEST-'+uuid.uuid4().hex;processes=[];exe=None
    try:
        info=json.loads(issuer.stdout.readline());write_json(out/'issuer.json',info)
        public=bytes.fromhex(info['public_xy'])
        (fixtures/'lab_public_key.h').write_text('#pragma once\n#ifndef CYRUS_SIGNED_LICENSE_LAB_ONLY\n#error Development issuer only\n#endif\ninline constexpr unsigned char CyrusLabPublicXY[]={'+','.join(map(str,public))+'};\n')
        (fixtures/'lab_installation_context.h').write_text('#pragma once\ninline constexpr wchar_t CyrusLabKeyName[]=L"'+key+'";\ninline constexpr wchar_t CyrusLabStatePath[]=LR"('+str(out/'state')+')";\n')
        env=compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
        sdk=ROOT/'build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk'
        common=['-G','NMake Makefiles','-DCMAKE_BUILD_TYPE=Release','-DCYRUS_MAX_YEAR=2027',f'-DMAXSDK_ROOT={sdk}',f'-DCYRUS_SIGNED_FIXTURES={fixtures}']
        for name,directory,flags in [('client','tools/licensing_lab',['-DCYRUS_BUILD_LICENSING_LAB=ON','-DCYRUS_BUILD_LOCAL_CLIENT_LAB=ON']),
                                     ('native','AminScatter',['-DCYRUS_NATIVE_LICENSE_EXPERIMENT=ON','-DCYRUS_LICENSE_INSTALLATION_CONTEXT=ON'])]:
            run_command(['cmake','-S',source/directory,'-B',out/name,*common,*flags],out/(name+'-configure'),env)
            run_command(['cmake','--build',out/name],out/(name+'-build'),env,timeout=600)
            run_command(['ctest','--test-dir',out/name,'--output-on-failure','-V'],out/(name+'-tests'),env)
        exe=out/'client/CyrusLocalClientLab.exe'
        request=None
        def issue(duration):
            issuer.stdin.write(json.dumps({'request':request,'duration':duration})+'\n');issuer.stdin.flush()
            response=json.loads(issuer.stdout.readline())
            if 'error' in response:raise RuntimeError(response['error'])
            return response
        def execute(folder,script):
            result=run_script(folder,script,timeout=180)
            if not result.startswith('SUCCESS '):raise RuntimeError(result)
        first=launch_private(source,out,out/'native','a');processes.append(first)
        execute(first[1],'if cyrusOwnedLabClock!=undefined do throw "Unexpected synthetic clock"')
        panel=(source/'tools/licensing_lab/Activation_Panel.ms').as_posix()
        execute(first[1],'global CyrusLicenseDevelopmentPanel\nfileIn @"'+panel+'"\nCyrusLicenseDevelopmentPanel.saveRequest @"'+(out/'request.json').as_posix()+'"')
        request=json.loads((out/'request.json').read_text(encoding='utf-8-sig'))
        # Issue only after Max is ready, so the bounded real-time expiry test
        # measures uptime rather than variable application startup duration.
        active=issue(20);responseFile=out/'activation.response';responseFile.write_text(active['response'])
        execute(first[1],'LNStart "'+out.as_posix()+'/" @"'+responseFile.as_posix()+'" viaPanel:true')
        print('PASS first Max activated and authored',flush=True)
        deadline=active['expires']+1
        while time.time()<deadline:time.sleep(min(.5,deadline-time.time()))
        execute(first[1],'LNExpired()')
        print('PASS first Max expired and retained scene',flush=True)
        second=launch_private(source,out,out/'native','b');processes.append(second)
        execute(second[1],'LNReopen "'+out.as_posix()+'/"')
        renewed=issue(3600);renewalFile=out/'renewal.license';renewalFile.write_text(renewed['license'])
        execute(second[1],'fileIn @"'+panel+'"\nLNRenew @"'+renewalFile.as_posix()+'" viaPanel:true')
        print('Waiting for the fixed 60-second background refresh/checkpoint, without explicit refresh',flush=True)
        deadline=time.monotonic()+75;poll=out/'background-status.json'
        while True:
            execute(first[1],'(dotNetClass "System.IO.File").WriteAllText @"'+poll.as_posix()+'" ((cyrusOwnedLabStatus())+"\\n"+(cyrusOwnedLabWorkerStats()))')
            lines=poll.read_text(encoding='utf-8-sig').splitlines();worker=json.loads(lines[1])
            if lines[0]=='allowed' and worker['cycles']>=1 and not worker['error']:break
            if time.monotonic()>=deadline:raise RuntimeError('Automatic background refresh did not publish renewal')
            time.sleep(2)
        state=json.loads(subprocess.check_output([str(exe),'state-summary',str(out/'state'),key],text=True))
        if state['highest_utc']<=active['expires']-20:raise RuntimeError('Background clock floor was not persisted')
        write_json(out/'background-maintenance.json',{'status':'PASS','automatic_refresh':True,'worker':worker,'persisted_generation':state['generation'],'persisted_highest_utc':state['highest_utc']})
        print('PASS second Max cold render and shared renewal',flush=True)
        binaries={p.name:digest(p) for p in (out/'native').glob('*.dl?')}
        for stage,folder in [('create',first[1]),('reopen',second[1])]:
            loaded={}
            for line in (out/f'max-{stage}-modules.tsv').read_text(encoding='utf-8-sig').splitlines():
                name,path=line.split('\t',1)
                if name in binaries:
                    if Path(path).resolve()!=(folder/'bin'/name).resolve() or digest(Path(path))!=binaries[name]:raise RuntimeError('Wrong loaded module '+name)
                    loaded[name]=binaries[name]
            if loaded!=binaries:raise RuntimeError('Incomplete loaded identities')
        comparisons={}
        with Image.open(out/'active.png') as activeImage:
            if activeImage.size!=(128,128) or len(activeImage.convert('RGB').getcolors(16385) or [])<4:raise RuntimeError('Blank render')
            for name in ['expired.png','reopened.png']:
                with Image.open(out/name) as image:
                    diff=ImageChops.difference(activeImage.convert('RGB'),image.convert('RGB'))
                    maximum=max(high for low,high in diff.getextrema());changed=sum(p!=(0,0,0) for p in diff.getdata())
                    comparisons[name]={'maximum_channel_difference':maximum,'changed_pixels':changed}
                    if maximum>1 or changed>2:raise RuntimeError('Continuity image changed '+name)
            with Image.open(out/'source-changed.png') as image:
                if not ImageChops.difference(activeImage.convert('RGB'),image.convert('RGB')).getbbox():raise RuntimeError('External dependency counterexample absent')
        shutdowns=[]
        for process,folder in processes:
            if str(folder/'max.ini') not in psutil.Process(process.pid).cmdline():raise RuntimeError('Unrelated process at clean shutdown')
            # Purpose-built private script transport. The process exits before
            # it can write a normal response, so wait for its OS exit instead.
            script=folder/'clean-shutdown.ms';script.write_text('quitMAX #noPrompt\n')
            requestFile=folder/'dev-request.txt';temporary=requestFile.with_suffix('.tmp')
            temporary.write_text(script.as_posix());temporary.replace(requestFile)
            process.wait(timeout=45)
            receipt=out/'state'/f'shutdown-{process.pid}.json'
            closed=json.loads(receipt.read_text())
            if not closed['joined'] or closed['cycles']<1 or closed['error']:raise RuntimeError('Worker did not checkpoint/join at host shutdown')
            shutdowns.append(closed)
        write_json(out/'shutdowns.json',{'status':'PASS','processes':shutdowns})
        write_json(out/'result.json',{'status':'PASS','scope':'Native-owned count/seed, CS Edit and Brush history mutations through one shared runtime; real CNG/DPAPI and authenticated time anchor; development issuance only',
            'render_comparisons':comparisons,'max_instances':64,'concurrent_Max_processes':2,'binaries':binaries,
            'no_fake_clock_primitive':True,'native_full_product_coverage':False,'PFlow_or_other_renderers_qualified':False,
            'source_scene_cryptographic_provenance':False,'automatic_background_refresh_checkpoint':True,
            'clean_host_shutdown_join':True,'processes':[str(p[1]) for p in processes]})
    finally:
        for process,folder in processes:
            if process.poll() is None:
                command=psutil.Process(process.pid).cmdline()
                if str(folder/'max.ini') not in command:raise RuntimeError('Refusing to close an unrelated Max')
                process.terminate();process.wait(timeout=30)
        if exe and exe.exists():
            result=subprocess.run([str(exe),'delete-test-key',str(out/'state'),key],capture_output=True,text=True,timeout=15)
            write_json(out/'private-key-cleanup.json',{'exit_code':result.returncode,'result':result.stdout.strip()})
        issuer.stdin.close();issuer.wait(timeout=10)
    print('PASS real installation Max candidate '+str(out),flush=True)

if __name__=='__main__':main()
