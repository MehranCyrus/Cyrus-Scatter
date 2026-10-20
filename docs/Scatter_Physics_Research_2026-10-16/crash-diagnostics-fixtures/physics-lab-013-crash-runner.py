"""Own one hidden host; retain evidence and stop only its launch-recorded PID."""
from pathlib import Path
import argparse,json,subprocess,sys,time,ctypes,os
root=Path.cwd()
p=argparse.ArgumentParser();p.add_argument('--build',required=True);p.add_argument('--script',required=True);p.add_argument('--fixture',required=True);p.add_argument('--output',required=True);p.add_argument('--baseline',action='store_true');a=p.parse_args()
folder=(root/a.output).resolve()
startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
command=[sys.executable,str(root/'CyrusPhysicsLab/tools/host_test.py'),'--build',a.build,'--script',a.script,'--fixture',a.fixture,'--output',str(folder),'--timeout','180']
process=subprocess.Popen(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,startupinfo=startup)
deadline=time.monotonic()+170
reason=None
while time.monotonic()<deadline:
    if process.poll() is not None:break
    dump=list(folder.glob('diagnostics/*/dump-status.json'))
    exits=list(folder.glob('diagnostics/*/process-exit.json'))
    if (a.baseline and (folder/'before-late.json').exists()) or dump or exits:
        time.sleep(8 if a.baseline else 3)
        if process.poll() is None and (folder/'launch.json').exists():
            launch=json.loads((folder/'launch.json').read_text())
            # This exact PID was created by our unique host_test invocation.
            kernel=ctypes.WinDLL('kernel32',use_last_error=True)
            kernel.OpenProcess.restype=ctypes.c_void_p
            kernel.OpenProcess.argtypes=[ctypes.c_ulong,ctypes.c_int,ctypes.c_ulong]
            kernel.TerminateProcess.argtypes=[ctypes.c_void_p,ctypes.c_uint]
            kernel.CloseHandle.argtypes=[ctypes.c_void_p]
            handle=kernel.OpenProcess(1,False,launch['pid'])
            if handle:kernel.TerminateProcess(handle,78);kernel.CloseHandle(handle)
        reason='baseline post-callback witness' if a.baseline else 'crash artifact captured'
        break
    time.sleep(.2)
output=process.communicate(timeout=40)[0]
(folder/'crash-harness-output.txt').write_text(output)
(folder/'crash-harness.json').write_text(json.dumps({'test_only':True,'computer_use':False,'expected_crash':True,'reason':reason,'launcher_exit':process.returncode,'baseline':a.baseline,'unexpected_return':(folder/'unexpected-return.txt').exists()},indent=2))
print(output[-2000:]);print('Crash witness retained:',folder,reason)
