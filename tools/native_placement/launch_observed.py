"""Launch a source-matched private host and retain its Windows process handle.

A readiness timeout is recorded as live/unknown, never permission to relaunch.
No termination or artist-profile mutation is performed here.
"""
import argparse,ctypes,json,subprocess,sys,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('host');parser.add_argument('--native',required=True)
args=parser.parse_args()
assert args.host.startswith('foundation-memory0854-nativeaccept-')
host=ROOT/'build/mcp-qualification'/args.host
result=subprocess.run([sys.executable,'-B',str(ROOT/'tools/memory_0854/host.py'),'launch',args.host,'--native',args.native],cwd=ROOT,capture_output=True,text=True)
print(result.stdout,flush=True)
if result.returncode:raise RuntimeError(result.stderr)
pid=json.loads(result.stdout)['pid']
kernel=ctypes.WinDLL('kernel32',use_last_error=True)
kernel.OpenProcess.restype=ctypes.c_void_p
kernel.GetExitCodeProcess.argtypes=[ctypes.c_void_p,ctypes.POINTER(ctypes.c_ulong)]
kernel.WaitForSingleObject.argtypes=[ctypes.c_void_p,ctypes.c_ulong]
kernel.CloseHandle.argtypes=[ctypes.c_void_p]
handle=kernel.OpenProcess(0x100000|0x1000,False,pid)
if not handle:raise RuntimeError(f'Cannot acquire launched process handle: {ctypes.get_last_error()}; inspect the exact PID/profile before continuing')
observation={'pid':pid,'ready':False,'exited':False}
try:
    end=time.monotonic()+120
    while time.monotonic()<end:
        if (host/'ready.json').exists():observation['ready']=True;break
        if (host/'startup-error.txt').exists():observation['startup_error']=(host/'startup-error.txt').read_text(encoding='utf-8-sig');break
        if kernel.WaitForSingleObject(handle,0)==0:
            code=ctypes.c_ulong()
            if not kernel.GetExitCodeProcess(handle,ctypes.byref(code)):raise OSError(ctypes.get_last_error())
            observation.update(exited=True,exit_code=code.value);break
        time.sleep(.2)
    else:observation['observation_timeout_live']=True
finally:kernel.CloseHandle(handle)
(host/'startup-observation.json').write_text(json.dumps(observation,indent=2)+'\n')
print(json.dumps(observation),flush=True)
sys.exit(0 if observation['ready'] else 1)
