from pathlib import Path
import ctypes,json,os,subprocess,sys,time,uuid
ROOT=Path(r'F:/Cursor/_Cyrus_Apps/CyrusScatter')
host=ROOT/'build/mcp-qualification'/sys.argv[1]
assert host.name.startswith('foundation-memory0854-')
launch=json.loads((host/'launch.json').read_text())
pid=launch['pid']
command=f'Get-CimInstance Win32_Process -Filter "ProcessId={pid}" | Select-Object ProcessId,CommandLine,ExecutablePath | ConvertTo-Json -Compress'
result=subprocess.check_output(['powershell','-NoProfile','-Command',command],text=True).strip()
if not result:
    print(json.dumps({'pid':pid,'already_absent':True}));sys.exit(0)
process=json.loads(result)
assert str(host).lower() in process['CommandLine'].lower()
assert process['ExecutablePath'].lower()==r'C:\Program Files\Autodesk\3ds Max 2027\3dsmax.exe'.lower()
pointer=host/'dev-request.txt';response=host/'dev-result.txt'
if pointer.exists():
    previous=pointer.read_text(encoding='utf-8-sig');state=response.read_text(encoding='utf-8-sig')
    assert previous in state and state.startswith(('SUCCESS','ERROR'))
request=host/('request-close-'+uuid.uuid4().hex+'.ms')
request.write_text((Path(__file__).parent/'close.ms').read_text(),encoding='utf-8-sig')
pending=host/('pointer-close-'+uuid.uuid4().hex+'.tmp');pending.write_text(request.as_posix(),encoding='utf-8-sig');os.replace(pending,pointer)
kernel=ctypes.WinDLL('kernel32',use_last_error=True)
kernel.OpenProcess.restype=ctypes.c_void_p
handle=kernel.OpenProcess(0x100000,False,pid)
end=time.monotonic()+8
exited=False
while time.monotonic()<end:
    if not handle or kernel.WaitForSingleObject(ctypes.c_void_p(handle),0)==0:
        exited=True;break
    time.sleep(.2)
if handle:kernel.CloseHandle(ctypes.c_void_p(handle))
record={'pid':pid,'close_marker':(host/'closed-owned-session.txt').exists(),'exited':exited}
(host/'closure-observation.json').write_text(json.dumps(record,indent=2))
print(json.dumps(record))
