"""Full multi-area Paint output parity, timing and sampled process commit."""
import argparse,ctypes,json,threading,time,subprocess
from run_generation import ROOT,ready,send
from run_baseline import Counters
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('route',choices=('old','native'));a=p.parse_args()
assert a.host.startswith('foundation-memory0854-')
h=ROOT/'build/mcp-qualification'/a.host;ready(h)
launch=json.loads((h/'launch.json').read_text());pid=launch['pid']
actual=json.loads(subprocess.check_output(['powershell','-NoProfile','-Command',f'Get-CimInstance Win32_Process -Filter "ProcessId={pid}" | Select-Object CommandLine,ExecutablePath | ConvertTo-Json -Compress'],text=True))
assert str(h).lower() in actual['CommandLine'].lower() and actual['ExecutablePath'].lower().endswith('3ds max 2027\\3dsmax.exe')
kernel=ctypes.WinDLL('kernel32',use_last_error=True);kernel.OpenProcess.restype=ctypes.c_void_p;kernel.CloseHandle.argtypes=[ctypes.c_void_p];kernel.QueryPerformanceCounter.argtypes=[ctypes.POINTER(ctypes.c_longlong)]
memory=ctypes.WinDLL('psapi',use_last_error=True);memory.GetProcessMemoryInfo.argtypes=[ctypes.c_void_p,ctypes.POINTER(Counters),ctypes.c_ulong]
handle=kernel.OpenProcess(0x1010,False,pid);assert handle
stop=threading.Event();errors=[]
def sample():
 try:
  with (h/'paint-process-samples.tsv').open('w') as f:
   f.write('qpc\tprivate_commit\tworking_set\n')
   while not stop.is_set():
    c=Counters();c.cb=ctypes.sizeof(c);stamp=ctypes.c_longlong()
    assert memory.GetProcessMemoryInfo(handle,ctypes.byref(c),c.cb) and kernel.QueryPerformanceCounter(ctypes.byref(stamp))
    f.write(f'{stamp.value}\t{c.PrivateUsage}\t{c.WorkingSetSize}\n');stop.wait(.02)
 except Exception as e:errors.append(repr(e))
thread=threading.Thread(target=sample,daemon=True);thread.start();s=ROOT/'tools/native_placement/paint_benchmark.ms'
try:
 send(h,s,'setup '+a.route)
 for i in range(11):
  for count in (200000,5000):send(h,s,f'sample {count} {i} {a.route}')
finally:stop.set();thread.join(5);kernel.CloseHandle(handle)
assert not errors,errors
(h/'paint-benchmark-driver.json').write_text(json.dumps({'status':'passed','route':a.route,'repetitions':10,'warmup':0,'sample_interval_seconds':.02,'limits':'Process samples include host/allocator memory; no Modify UI timing; not presented FPS or complete VRAM.'},indent=2))
print('MULTI-AREA PAINT BENCHMARK PASSED',flush=True)
