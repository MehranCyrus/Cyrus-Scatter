"""Restart only an owned profile after the exact Analyzer installer test."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import subprocess
import time
import uuid
from host import ROOT,wait_ready
from results import artifact_identity

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--folder',type=Path,required=True)
parser.add_argument('--recover',action='store_true',help='Recover a recorded failed owned startup after observing process exit')
args=parser.parse_args();folder=args.folder.resolve()
assert folder.is_relative_to(ROOT/'build/refinement-08683-20261022')
metadata=json.loads((folder/'qualification.json').read_text())
pid=int(metadata['pid'])
command=subprocess.check_output(['powershell','-NoProfile','-Command',f'(Get-CimInstance Win32_Process -Filter "ProcessId={pid}").CommandLine'],text=True)
if command.strip():assert str(folder/'max.ini').lower() in command.lower()
else:assert args.recover and (folder/'restart.json').is_file() and (folder/'startup-error.txt').is_file()
pointer=folder/'dev-request.txt';response=folder/'dev-result.txt'
if command.strip():
    if pointer.exists():assert response.read_text(encoding='utf-8-sig').startswith('SUCCESS') and pointer.read_text(encoding='utf-8-sig') in response.read_text(encoding='utf-8-sig')
    else:assert args.recover and (folder/'startup-error.txt').is_file()
else:
    previous=Path(pointer.read_text(encoding='utf-8-sig')).resolve()
    assert previous.parent==folder and previous.name.startswith('restart-close-') and previous.read_text(encoding='utf-8-sig').strip()=='quitMAX #noPrompt'
receipts=[json.loads(p.read_text()) for p in folder.glob('installer-*.json')]
successful=[r for r in receipts if r.get('status')=='passed'];assert successful
runtime=Path(successful[-1]['runtime']).resolve();assert runtime.is_relative_to(folder)
if command.strip():
    request=folder/('restart-close-'+uuid.uuid4().hex+'.ms');request.write_text('quitMAX #noPrompt',encoding='utf-8-sig')
    pointer.write_text(request.as_posix(),encoding='utf-8-sig')
deadline=time.monotonic()+60
while True:
    exists=subprocess.check_output(['powershell','-NoProfile','-Command',f'(Get-Process -Id {pid} -ErrorAction SilentlyContinue).Id'],text=True).strip()
    if not exists:break
    if time.monotonic()>deadline:raise TimeoutError('Owned close remains unresolved; do not launch another process')
    time.sleep(.2)
archive=folder/('pre-restart-'+metadata['run_id']);archive.mkdir()
for name in ('qualification.json','ready.json','loaded.tsv','startup-error.txt','dev-request.txt','dev-result.txt'):
    source=folder/name
    if source.exists():os.replace(source,archive/name)
native=folder/'bin/CyrusSurfaceAnalyzer.dlx'
old_hash=hashlib.sha256(native.read_bytes()).hexdigest() if native.is_file() else None
if native.is_file():os.replace(native,archive/native.name)
start=(folder/'start.ms').read_text(encoding='utf-8-sig')
start=start.replace(str(native),str(runtime/'bin/CyrusSurfaceAnalyzer.dlx'))
old='fileIn (MCPFixtureDir+"scripts/CyrusSurfaceAnalyzer.ms")'
assert old in start
start=start.replace(old,'fileIn @"'+(runtime/'CyrusSurfaceAnalyzer.ms').as_posix()+'"')
bootstrap=folder/'restart-start.ms';bootstrap.write_text(start,encoding='utf-8-sig')
launch=json.loads((folder/'launch.json').read_text())
# -p replaces the normal user INI chain. Include this profile's actual installer
# registration explicitly, while continuing to exclude the artist's profile.
plugins=folder/'restart-plugins.ini'
plugins.write_text('[Directories]\nAdditional MAX plug-ins=C:/Program Files/Autodesk/3ds Max 2027/PlugIns\nCyrusPrivate='+str(folder/'bin')+'\n[Include]\nCyrusOwnedUserSettings='+str(folder/'Plugin.UserSettings.ini')+'\n[Help]\n',encoding='utf-16')
launch_command=[str(bootstrap) if arg==str(folder/'start.ms') else str(plugins) if arg==str(folder/'plugins.ini') else arg for arg in launch['command']]
startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
process=subprocess.Popen(launch_command,cwd=folder,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,startupinfo=startup)
paths={name:Path(path) for name,path in metadata['paths'].items()}
paths['AnalyzerScript']=runtime/'CyrusSurfaceAnalyzer.ms';paths['CyrusSurfaceAnalyzer.dlx']=runtime/'bin/CyrusSurfaceAnalyzer.dlx'
identity,hashes=artifact_identity(paths)
metadata.update(run_id=uuid.uuid4().hex,parent_run_id=metadata['run_id'],pid=process.pid,artifact_id=identity,hashes=hashes,paths={n:str(p) for n,p in paths.items()})
(folder/'qualification.json').write_text(json.dumps(metadata,indent=2))
receipt={'pid':process.pid,'previous_pid':pid,'profile':str(folder),'runtime':str(runtime),'previous_native_sha256':old_hash,'driver_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'command':launch_command,'artist_session_restarted':False}
(folder/'restart.json').write_text(json.dumps(receipt,indent=2))
print(json.dumps(receipt),flush=True)
wait_ready(folder,timeout=240)
print('PASS: owned profile restarted and bootstrap verified installed native path',flush=True)
