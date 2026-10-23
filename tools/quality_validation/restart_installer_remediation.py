"""Restart the verified owned installer-test profile on its installed Analyzer.

Run only after R7-I01 passed. It verifies the recorded process command, requests
that exact process to close through its existing transport, waits for exit, then
relaunches the same redirected profile with its installed Analyzer registration.
No force termination, artist profile discovery, or fallback process is used.
"""
from pathlib import Path
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import time
import uuid
from host import ROOT,wait_ready
from results import artifact_identity


def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def command_for(pid):
    return subprocess.check_output(['powershell.exe','-NoProfile','-NonInteractive','-Command',
        '(Get-CimInstance Win32_Process -Filter "ProcessId='+str(int(pid))+'").CommandLine'],text=True).strip()


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--folder',type=Path,required=True)
    parser.add_argument('--result',type=Path,required=True,help='Passed R7-I01 auxiliary installer-remediation JSON')
    parser.add_argument('--visible',action='store_true')
    args=parser.parse_args();folder=args.folder.resolve();result_path=args.result.resolve()
    if not folder.is_relative_to(ROOT/'build') or not result_path.is_relative_to(folder):raise ValueError('An owned profile/result is required.')
    metadata=json.loads((folder/'qualification.json').read_text(encoding='utf-8'))
    launch=json.loads((folder/'launch.json').read_text(encoding='utf-8'))
    result=json.loads(result_path.read_text(encoding='utf-8'))
    config_path=folder/'installer-remediation-config.json'
    config=json.loads(config_path.read_text(encoding='utf-8'))
    if (result.get('schema')!='cyrus.installer-host/1' or result.get('status')!='passed' or result.get('mode')!='main'
            or result.get('package_sha256')!=config['package']['sha256']):raise ValueError('A passed exact-package R7-I01 result is required.')
    if Path(metadata['paths']['installer_config']).resolve()!=config_path or digest(config_path)!=metadata['hashes']['installer_config']:
        raise ValueError('Installer configuration binding differs.')
    profile=Path(metadata.get('profile_ini',folder/'max.ini')).resolve()
    if profile!=folder/'max.ini' or launch['max_year']!=2027:raise ValueError('The recorded owned Max2027 profile is required.')
    pid=int(metadata['pid']);current=command_for(pid);expected_command=metadata.get('command',launch['command'])
    if current.lower()!=subprocess.list2cmdline(expected_command).lower() or str(profile).lower() not in current.lower():
        raise ValueError('Owned process identity/command differs; do not retry or select another Max process.')
    for name,path in metadata['paths'].items():
        if digest(path)!=metadata['hashes'][name]:raise ValueError('Bound qualification input changed: '+name)
    runtime=Path(result['runtime']).resolve()
    if not runtime.is_relative_to(folder):raise ValueError('Installed runtime escaped the owned profile.')
    native=runtime/'bin/CyrusSurfaceAnalyzer.dlx';script=runtime/'CyrusSurfaceAnalyzer.ms'
    if digest(native)!=result['payload_hashes']['CyrusSurfaceAnalyzer.dlx'] or digest(script)!=result['payload_hashes']['CyrusSurfaceAnalyzer.ms']:
        raise ValueError('Installed pair differs from the successful MZP result.')
    pointer,response=folder/'dev-request.txt',folder/'dev-result.txt'
    previous=pointer.read_text(encoding='utf-8-sig');state=response.read_text(encoding='utf-8-sig')
    if not state.startswith('SUCCESS') or previous not in state:raise ValueError('Prior request remains unresolved; observe it before restarting.')
    environment=os.environ.copy()
    for name in ('ADSK_3DSMAX_APPDATA_DIR','ADSK_3DSMAX_USERSETTINGS_DIR','ADSK_3DSMAX_USERTOOLS_DIR'):
        path=Path(launch['user_directories'][name]).resolve()
        if not path.is_relative_to(folder):raise ValueError('Redirected environment escaped owned profile.')
        environment[name]=str(path)
    identity=uuid.uuid4().hex
    restart_record=folder/('installer-restart-'+identity+'.json')
    restart={'schema':'cyrus.installer-restart/1','status':'close-requested','previous_pid':pid,'runtime':str(runtime),
        'profile':str(profile),'source_result':str(result_path),'source_result_sha256':digest(result_path),
        'driver_sha256':digest(Path(__file__)),'artist_session_restarted':False}
    restart_record.write_text(json.dumps(restart,indent=2)+'\n',encoding='utf-8')
    request=folder/('restart-close-'+identity+'.ms');request.write_text('quitMAX #noPrompt\n',encoding='utf-8-sig')
    pending=folder/('pointer-'+identity+'.tmp');pending.write_text(request.as_posix(),encoding='utf-8-sig');os.replace(pending,pointer)
    deadline=time.monotonic()+90
    while True:
        observed=command_for(pid)
        if not observed:break
        if observed.lower()!=current.lower():raise ValueError('Recorded PID no longer identifies the owned process.')
        if time.monotonic()>deadline:raise TimeoutError('Owned close unresolved. Observe the recorded PID; do not launch again.')
        time.sleep(.2)
    archive=folder/('pre-installer-restart-'+identity);archive.mkdir()
    for name in ('qualification.json','ready.json','loaded.tsv','startup-error.txt','dev-request.txt','dev-result.txt','listener.log'):
        source=(folder/name).resolve();target=(archive/name).resolve()
        if not source.is_relative_to(folder) or not target.is_relative_to(archive):raise ValueError('Restart archive path escaped ownership.')
        if source.exists():os.replace(source,target)
    shutil.copy2(config_path,archive/config_path.name)
    old_native=folder/'bin/CyrusSurfaceAnalyzer.dlx'
    if old_native.exists():
        if digest(old_native)!=metadata['hashes']['CyrusSurfaceAnalyzer.dlx']:raise ValueError('Previous owned native changed.')
        os.replace(old_native,archive/old_native.name)
    start=(folder/'start.ms').read_text(encoding='utf-8-sig')
    if str(old_native) not in start:raise ValueError('Owned bootstrap native location differs.')
    start=start.replace(str(old_native),str(native))
    old='fileIn (MCPFixtureDir+"scripts/CyrusSurfaceAnalyzer.ms")'
    if old not in start:raise ValueError('Owned bootstrap Analyzer script location differs.')
    start=start.replace(old,'fileIn @"'+script.as_posix()+'"')
    bootstrap=folder/('installer-restart-start-'+identity+'.ms');bootstrap.write_text(start,encoding='utf-8-sig')
    plugins=folder/('installer-restart-plugins-'+identity+'.ini')
    plugins.write_text('[Directories]\nAdditional MAX plug-ins=C:/Program Files/Autodesk/3ds Max 2027/PlugIns\nCyrusPrivate='+str(folder/'bin')+
        '\n[Include]\nCyrusOwnedUserSettings='+str(folder/'Plugin.UserSettings.ini')+'\n[Help]\n',encoding='utf-16')
    launch_command=[str(bootstrap) if arg==str(folder/'start.ms') else str(plugins) if arg==str(folder/'plugins.ini') else arg for arg in launch['command']]
    config.update(mode='restart',expected_runtime=str(runtime));config_path.write_text(json.dumps(config,indent=2)+'\n',encoding='utf-8')
    paths={name:Path(path) for name,path in metadata['paths'].items()}
    paths.update(AnalyzerScript=script,installer_config=config_path)
    paths['CyrusSurfaceAnalyzer.dlx']=native;paths['driver:restart_installer_remediation.py']=Path(__file__).resolve()
    artifact,hashes=artifact_identity(paths)
    startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=1 if args.visible else 0
    process=subprocess.Popen(launch_command,cwd=folder,env=environment,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,startupinfo=startup)
    metadata.update(parent_run_id=metadata['run_id'],run_id=uuid.uuid4().hex,pid=process.pid,command=launch_command,profile_ini=str(profile),
                    artifact_id=artifact,hashes=hashes,paths={name:str(path) for name,path in paths.items()})
    (folder/'qualification.json').write_text(json.dumps(metadata,indent=2)+'\n',encoding='utf-8')
    restart.update(status='launched',pid=process.pid,command=launch_command,artifact_id=artifact,user_directories=launch['user_directories'])
    restart_record.write_text(json.dumps(restart,indent=2)+'\n',encoding='utf-8');print(json.dumps(restart),flush=True)
    wait_ready(folder,timeout=240)
    restart['status']='ready';restart_record.write_text(json.dumps(restart,indent=2)+'\n',encoding='utf-8')
    print('Owned installed pair is ready for R7-I03; this driver does not claim the scenario passed.',flush=True)


if __name__=='__main__':main()
