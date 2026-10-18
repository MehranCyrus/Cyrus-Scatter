"""Capacity with process private-commit/working-set samples; never raises heap."""
import argparse,ctypes,json,threading,time
from run_baseline import Counters
from run_generation import ROOT,ready,send
p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args()
assert a.host.startswith('foundation-memory0854-nativeaccept-controller-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
pid=json.loads((host/'launch.json').read_text())['pid']
kernel=ctypes.WinDLL('kernel32',use_last_error=True);kernel.OpenProcess.restype=ctypes.c_void_p;kernel.CloseHandle.argtypes=[ctypes.c_void_p]
memory=ctypes.WinDLL('psapi',use_last_error=True);memory.GetProcessMemoryInfo.argtypes=[ctypes.c_void_p,ctypes.POINTER(Counters),ctypes.c_ulong]
handle=kernel.OpenProcess(0x1000|0x10,False,pid);assert handle,ctypes.get_last_error()
helper=host/'capacity-helper.ms';helper.write_text('global NGAllCoveredSame\nfn NGAllCoveredSame a b=(for stage=2 to a.count where a[stage][1] do for k=2 to a[stage].count where a[stage][k]!=b[stage][k] do return false;true)')
send(host,helper,'helpers');script=ROOT/'tools/native_placement/capacity.ms';send(host,script,'setup')
results=[]
for count in [5000,50000,90000,200000,500000,1000000,5000,500000,1000000,5000,500000,1000000,5000]:
    stop=threading.Event();samples=[];errors=[]
    def sample():
        while not stop.is_set():
            m=Counters();m.cb=ctypes.sizeof(m)
            if not memory.GetProcessMemoryInfo(handle,ctypes.byref(m),m.cb):errors.append(ctypes.get_last_error());return
            samples.append([time.monotonic(),m.PrivateUsage,m.WorkingSetSize]);stop.wait(.02)
    thread=threading.Thread(target=sample);thread.start()
    try:send(host,script,'count '+str(count))
    finally:stop.set();thread.join()
    assert not errors,errors
    results.append({'count':count,'samples':samples})
    (host/'native-capacity-process.json').write_text(json.dumps(results)+'\n')
for phase in ('undo','verifyUndo','verifyRedo','over','release'):send(host,script,phase);time.sleep(.5)
kernel.CloseHandle(handle)
print('NATIVE CAPACITY 5K THROUGH 1M, HISTORY AND RELEASE PASSED',flush=True)
