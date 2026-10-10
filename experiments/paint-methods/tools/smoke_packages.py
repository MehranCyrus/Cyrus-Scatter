"""Run the four extracted trial launchers serially in owned hidden processes."""
from pathlib import Path
import argparse,ctypes,json,subprocess,time
LAB=Path(__file__).resolve().parents[1]
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--packages',type=Path,required=True);parser.add_argument('--output',type=Path,required=True);args=parser.parse_args();root=args.packages.resolve()
    if not root.is_relative_to(LAB/'dist'):raise ValueError('Lab packages required')
    kernel=ctypes.WinDLL('kernel32',use_last_error=True);kernel.OpenProcess.restype=ctypes.c_void_p;kernel.WaitForSingleObject.argtypes=[ctypes.c_void_p,ctypes.c_uint32];kernel.CloseHandle.argtypes=[ctypes.c_void_p]
    results=[]
    for folder in sorted(p for p in root.iterdir() if p.is_dir()):
        output=subprocess.check_output(['python',str(folder/'trial.py'),'--smoke'],text=True);meta=json.loads(output);run=Path(meta['session']);pid=meta['pid'];print(folder.name,pid,flush=True);handle=kernel.OpenProcess(0x100000,False,pid)
        deadline=time.monotonic()+180
        while not (run/'done.txt').exists() and not (run/'error.txt').exists():
            if time.monotonic()>deadline:raise TimeoutError(str(run))
            time.sleep(.2)
        error=(run/'error.txt').read_text() if (run/'error.txt').exists() else None
        status='FAIL' if error else 'PASS';print(status,error or '',flush=True);forced=False
        if handle:
            if kernel.WaitForSingleObject(handle,20000)==258:
                path=str(run).replace("'","''")
                code=f"$p=Get-CimInstance Win32_Process -Filter 'ProcessId = {pid}'; if($p -and $p.CommandLine.Contains('{path}')){{Stop-Process -Id {pid}; 'OWNED_STOP'}}"
                forced='OWNED_STOP' in subprocess.check_output(['powershell','-NoProfile','-Command',code],text=True)
            kernel.CloseHandle(handle)
        results.append({'method':folder.name,'status':status,'session':str(run),'pid':pid,'error':error,'forced_stop_after_script':forced})
        if error:break
    args.output.write_text(json.dumps(results,indent=2));print('PACKAGES',len(results),flush=True)
    if len(results)!=4 or any(r['status']!='PASS' for r in results):raise SystemExit(1)
if __name__=='__main__':main()
