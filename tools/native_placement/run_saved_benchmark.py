"""Repeat N01 Count windows on the exact saved baseline scene and identities."""
import argparse, ctypes, json, subprocess, threading, time
from run_generation import ROOT, ready, send
from run_baseline import Counters

p=argparse.ArgumentParser();p.add_argument('host');a=p.parse_args()
assert a.host.startswith('foundation-memory0854-nativeaccept-controller-')
h=ROOT/'build/mcp-qualification'/a.host;ready(h)
old=ROOT/'build/mcp-qualification/foundation-memory0854-nativeobserve-baseline-20261018-02'
launch=json.loads((h/'launch.json').read_text());pid=launch['pid']
actual=json.loads(subprocess.check_output(['powershell','-NoProfile','-Command',f'Get-CimInstance Win32_Process -Filter "ProcessId={pid}" | Select-Object CommandLine,ExecutablePath | ConvertTo-Json -Compress'],text=True))
assert str(h).lower() in actual['CommandLine'].lower() and actual['ExecutablePath'].lower().endswith('3ds max 2027\\3dsmax.exe')
assert not (h/'saved-native-baseline.tsv').exists()
kernel=ctypes.WinDLL('kernel32',use_last_error=True);kernel.OpenProcess.restype=ctypes.c_void_p;kernel.CloseHandle.argtypes=[ctypes.c_void_p]
kernel.QueryPerformanceCounter.argtypes=[ctypes.POINTER(ctypes.c_longlong)]
memory=ctypes.WinDLL('psapi',use_last_error=True);memory.GetProcessMemoryInfo.argtypes=[ctypes.c_void_p,ctypes.POINTER(Counters),ctypes.c_ulong]
handle=kernel.OpenProcess(0x1010,False,pid);assert handle
stop=threading.Event();errors=[]
def sample():
    try:
        with (h/'saved-native-process-samples.tsv').open('x') as f:
            f.write('qpc\tprivate_commit\tworking_set\n')
            while not stop.is_set():
                c=Counters();c.cb=ctypes.sizeof(c);stamp=ctypes.c_longlong()
                assert memory.GetProcessMemoryInfo(handle,ctypes.byref(c),c.cb) and kernel.QueryPerformanceCounter(ctypes.byref(stamp))
                f.write(f'{stamp.value}\t{c.PrivateUsage}\t{c.WorkingSetSize}\n');stop.wait(.02)
    except Exception as e:errors.append(repr(e))
thread=threading.Thread(target=sample,daemon=True);thread.start()
baseline=(ROOT/'tools/native_placement/baseline.ms').read_text()
baseline=baseline.replace('foundation-memory0854-nativeobserve-*/','foundation-memory0854-nativeaccept-controller-*/')
baseline=baseline.replace('native-baseline.tsv','saved-native-baseline.tsv')
script=h/'saved-baseline-adapter.ms';script.write_text(baseline)
try:
    for kind in ('plane','mountain'):
        setup=h/('saved-benchmark-'+kind+'.ms')
        setup.write_text('''resetMaxFile #noPrompt
loadMaxFile @"'''+(old/f'n01-{kind}.max').as_posix()+'''" quiet:true useFileUnits:true
global NPNode=getNodeByName "N01 '''+kind+''' controller",NPRoot=NPNode.baseObject,NPLeaf=NPRoot.layerObjects[1],NPKind="'''+kind+'''",NPHashes=#()
NPRoot.refreshAll();select NPNode;max modify mode;modPanel.setCurrentObject NPNode
if not NPRoot.mainUI.controlsReady do NPRoot.mainUI.mountTimer.tick()
undo "N01 unrelated scene marker" on (box name:"N01 unrelated marker" pos:[-75,0,0])
''');send(h,setup,'saved '+kind)
        for iteration in range(11):
            for count in (50000,90000,200000,5000):
                (h/'native-baseline-command.txt').write_text(f'sample {count} {iteration}')
                send(h,script,f'{kind} {count} {iteration}')
finally:stop.set();thread.join(5);kernel.CloseHandle(handle)
assert not errors,errors
expected={}
for line in (old/'native-baseline.tsv').read_text().splitlines():
    row=line.split('\t');key=(row[0],row[2]);expected[key]=row[15]
for line in (h/'saved-native-baseline.tsv').read_text().splitlines():
    row=line.split('\t');assert row[15]==expected[(row[0],row[2])]
(h/'saved-benchmark.json').write_text(json.dumps({'status':'passed','baseline':old.name,'full_fingerprints_equal':True,'repetitions':10,'warmup':1,'limits':'Same saved scenes and UI/history sequence. Concurrent soak/desktop activity remains measurement noise; no presented FPS claim.'},indent=2))
print('SAVED COUNT BENCHMARK PASSED',flush=True)
