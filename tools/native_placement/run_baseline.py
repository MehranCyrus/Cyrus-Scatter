"""Explicit serialized N01 commands and external Windows private-commit samples.

Uses an already launched owned Max 2027 host. It never launches/attaches to the
artist session, adjusts preferences, installs a plugin or discards Undo history.
"""
from pathlib import Path
import argparse, ctypes, json, os, subprocess, sys, threading, time, uuid

ROOT=Path(__file__).resolve().parents[2]
class Counters(ctypes.Structure):
    _fields_=[('cb',ctypes.c_ulong),('PageFaultCount',ctypes.c_ulong),
        ('PeakWorkingSetSize',ctypes.c_size_t),('WorkingSetSize',ctypes.c_size_t),
        ('QuotaPeakPagedPoolUsage',ctypes.c_size_t),('QuotaPagedPoolUsage',ctypes.c_size_t),
        ('QuotaPeakNonPagedPoolUsage',ctypes.c_size_t),('QuotaNonPagedPoolUsage',ctypes.c_size_t),
        ('PagefileUsage',ctypes.c_size_t),('PeakPagefileUsage',ctypes.c_size_t),('PrivateUsage',ctypes.c_size_t)]

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('host');parser.add_argument('--repetitions',type=int,default=10)
    parser.add_argument('--idle',action='store_true')
    args=parser.parse_args()
    assert args.host.startswith('foundation-memory0854-nativeobserve-')
    assert 1<=args.repetitions<=20
    host=ROOT/'build/mcp-qualification'/args.host
    launch=json.loads((host/'launch.json').read_text())
    assert Path(launch['output']).resolve()==host and launch['development_transport']
    pid=launch['pid']
    raw=subprocess.check_output(['powershell','-NoProfile','-Command',
        f'Get-CimInstance Win32_Process -Filter "ProcessId={pid}" | Select-Object CommandLine,ExecutablePath | ConvertTo-Json -Compress'],text=True)
    process=json.loads(raw)
    assert str(host).lower() in process['CommandLine'].lower()
    assert process['ExecutablePath'].lower()==r'C:\Program Files\Autodesk\3ds Max 2027\3dsmax.exe'.lower()
    kernel=ctypes.WinDLL('kernel32',use_last_error=True)
    kernel.OpenProcess.restype=ctypes.c_void_p
    kernel.CloseHandle.argtypes=[ctypes.c_void_p]
    kernel.QueryPerformanceCounter.argtypes=[ctypes.POINTER(ctypes.c_longlong)]
    memory=ctypes.WinDLL('psapi',use_last_error=True)
    memory.GetProcessMemoryInfo.argtypes=[ctypes.c_void_p,ctypes.POINTER(Counters),ctypes.c_ulong]
    handle=kernel.OpenProcess(0x1000|0x10,False,pid)
    assert handle,ctypes.get_last_error()
    stop=threading.Event();samples=[];sampling_errors=[]
    def sample():
        try:
            with (host/'native-process-samples.tsv').open('w') as out:
                out.write('qpc\tprivate_commit\tworking_set\n')
                while not stop.is_set():
                    data=Counters();data.cb=ctypes.sizeof(data);stamp=ctypes.c_longlong()
                    if not memory.GetProcessMemoryInfo(handle,ctypes.byref(data),data.cb):raise OSError(ctypes.get_last_error())
                    if not kernel.QueryPerformanceCounter(ctypes.byref(stamp)):raise OSError(ctypes.get_last_error())
                    samples.append((stamp.value,data.PrivateUsage,data.WorkingSetSize))
                    out.write(f'{stamp.value}\t{data.PrivateUsage}\t{data.WorkingSetSize}\n')
                    stop.wait(.02)
        except Exception as exc:sampling_errors.append(repr(exc))
    def send(command):
        pointer=host/'dev-request.txt';response=host/'dev-result.txt'
        if pointer.exists():
            previous=pointer.read_text(encoding='utf-8-sig');state=response.read_text(encoding='utf-8-sig')
            assert previous in state and state.startswith(('SUCCESS','ERROR')), 'Prior request still pending; observe it, never duplicate it'
        (host/'native-baseline-command.txt').write_text(command)
        request=host/f'native-request-{uuid.uuid4().hex}.ms'
        request.write_text((ROOT/'tools/native_placement/baseline.ms').read_text(),encoding='utf-8-sig')
        pending=host/f'pointer-{uuid.uuid4().hex}.tmp';pending.write_text(request.as_posix(),encoding='utf-8-sig');os.replace(pending,pointer)
        deadline=time.monotonic()+180
        while time.monotonic()<deadline:
            try:state=response.read_text(encoding='utf-8-sig') if response.exists() else ''
            except PermissionError:time.sleep(.05);continue
            if request.as_posix() in state:
                if not state.startswith('SUCCESS'):raise RuntimeError(command+'\n'+state)
                print(command,flush=True);return
            time.sleep(.1)
        raise TimeoutError(f'Observation expired for {request}; do not resubmit while it remains pending')
    thread=threading.Thread(target=sample,daemon=True);thread.start()
    try:
        deadline=time.monotonic()+90
        while not (host/'ready.json').exists():
            if (host/'startup-error.txt').exists():raise RuntimeError((host/'startup-error.txt').read_text())
            if time.monotonic()>deadline:raise TimeoutError('Owned startup observation expired')
            time.sleep(.2)
        send('observer')
        for kind in ['plane','mountain']:
            send('setup '+kind)
            # Iteration zero is an independent warm-up, excluded from summaries.
            for iteration in range(args.repetitions+1):
                for count in [50000,90000,200000,5000]:send(f'sample {count} {iteration}')
                # Explicit reachability snapshots are outside all Update windows.
                send('observe')
            if args.idle and kind=='mountain':
                send('idleStart')
                # The main agent continues useful work and can observe progress.
                for _ in range(12):time.sleep(10);print('idle observation',flush=True)
                send('idleEnd')
    finally:
        stop.set();thread.join(5);kernel.CloseHandle(handle)
        (host/'native-baseline-driver.json').write_text(json.dumps({'pid':pid,'repetitions':args.repetitions,
            'process_samples':len(samples),'sampling_errors':sampling_errors,'sample_interval_seconds':.02,
            'observer_in_timing_window':False,'note':'Sampled process private commit is not exact plugin-owned allocation or driver/VRAM usage.'},indent=2)+'\n')
    assert not sampling_errors,sampling_errors
    print('N01 BASELINE SEQUENCE PASSED',flush=True)

if __name__=='__main__':main()
