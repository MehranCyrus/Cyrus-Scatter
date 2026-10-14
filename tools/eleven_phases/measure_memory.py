"""Sample private committed process bytes during the owned P04 Max witness.

This is a sampled process peak on a shared workstation, not allocator attribution
or a guarantee that every instantaneous allocation spike was observed.
"""
from pathlib import Path
import argparse
import ctypes
from ctypes import wintypes
import json
import subprocess
import sys
import time

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('folder', type=Path)
a = p.parse_args(); folder = a.folder.resolve()
assert folder.parent == ROOT / 'build/mcp-qualification' and folder.name.startswith('foundation-roadmap-p04-')
metadata = json.loads((folder / 'launch.json').read_text(encoding='utf-8'))
pid = int(metadata['pid'])
process = json.loads(subprocess.check_output(['powershell', '-NoProfile', '-Command',
    f'Get-CimInstance Win32_Process -Filter "ProcessId={pid}" | Select-Object ExecutablePath,CommandLine | ConvertTo-Json'], text=True))
assert Path(process['ExecutablePath']).resolve() == Path(metadata['command'][0]).resolve()
assert str(folder).lower() in process['CommandLine'].lower()


class Counters(ctypes.Structure):
    _fields_ = [('cb', wintypes.DWORD), ('faults', wintypes.DWORD)] + [
        (name, ctypes.c_size_t) for name in ['peakWorking', 'working', 'peakPaged', 'paged',
                                           'peakNonPaged', 'nonPaged', 'pagefile', 'peakPagefile', 'private']]


kernel = ctypes.WinDLL('kernel32', use_last_error=True)
kernel.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
kernel.OpenProcess.restype = wintypes.HANDLE
kernel.CloseHandle.argtypes = [wintypes.HANDLE]
psapi = ctypes.WinDLL('psapi', use_last_error=True)
psapi.GetProcessMemoryInfo.argtypes = [wintypes.HANDLE, ctypes.POINTER(Counters), wintypes.DWORD]
handle = kernel.OpenProcess(0x410, False, pid)
assert handle


def private_bytes():
    value = Counters(); value.cb = ctypes.sizeof(value)
    assert psapi.GetProcessMemoryInfo(handle, ctypes.byref(value), value.cb)
    return int(value.private)


try:
    baseline = private_bytes(); samples = []
    child = subprocess.Popen([sys.executable, str(HERE / 'request.py'), str(folder),
                              str(HERE / 'phase04_memory.ms'), '--timeout', '120'])
    started = time.monotonic()
    while child.poll() is None:
        marker = folder / 'phase04-memory-stage.txt'
        try:
            label = marker.read_text(encoding='utf-8-sig') if marker.exists() else 'waiting'
        except OSError:
            label = 'marker write in progress'
        samples.append([time.monotonic() - started, private_bytes(), label])
        time.sleep(.01)
    assert child.returncode == 0
    peak = max(row[1] for row in samples)
    result = dict(scope=__doc__, baseline_bytes=baseline, sampled_peak_bytes=peak,
                  observed_peak_above_baseline_bytes=peak-baseline, final_bytes=private_bytes(),
                  sampling_target_ms=10, samples=samples)
    (folder / 'phase04-memory-process.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key: value for key, value in result.items() if key != 'samples'}))
finally:
    kernel.CloseHandle(handle)
