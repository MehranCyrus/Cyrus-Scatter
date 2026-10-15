"""Serialize audit requests and quiet windows in one owned Max 2027 host."""
from pathlib import Path
import argparse
import ctypes
from ctypes import wintypes
import json
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[3]
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('folder', type=Path)
p.add_argument('--operations', nargs='+', default=['idle', 'navigation', 'panels', 'unrelated', 'parameter', 'not_ready', 'recover'])
p.add_argument('--prefix', default='', help='Separate receipts for another representation')
a = p.parse_args()
folder = a.folder.resolve()
assert folder.parent == ROOT / 'build/mcp-qualification' and folder.name.startswith(('foundation-roadmap-idle-', 'foundation-roadmap-p05-idle-'))
metadata = json.loads((folder / 'launch.json').read_text())
assert metadata['max_year'] == 2027
kernel = ctypes.WinDLL('kernel32', use_last_error=True)
kernel.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
kernel.OpenProcess.restype = wintypes.HANDLE
kernel.GetProcessTimes.argtypes = [wintypes.HANDLE] + [ctypes.POINTER(wintypes.FILETIME)] * 4
kernel.CloseHandle.argtypes = [wintypes.HANDLE]
handle = kernel.OpenProcess(0x1000, False, metadata['pid'])
assert handle


def cpu():
    values = [wintypes.FILETIME() for _ in range(4)]
    if not kernel.GetProcessTimes(handle, *(ctypes.byref(x) for x in values)):
        raise ctypes.WinError(ctypes.get_last_error())
    return sum((x.dwHighDateTime << 32) | x.dwLowDateTime for x in values[2:]) / 10000


def request(operation, label=None):
    data = {'operation': operation, 'label': label or operation}
    (folder / 'idle-request.json').write_text(json.dumps(data))
    subprocess.run([sys.executable, str(ROOT / 'tools/eleven_phases/request.py'), str(folder),
                    str(Path(__file__).with_name('fixture.py')), '--timeout', '180'], check=True)


try:
    for operation in a.operations:
        if operation != 'idle':
            request(operation, a.prefix + operation)
        # Let preceding host notifications settle before measuring genuine idle.
        time.sleep(2)
        request('arm_idle', a.prefix + operation + '-idle-before')
        started = time.perf_counter()
        before = cpu()
        while not (folder / 'idle-ready.txt').exists():
            if time.perf_counter() - started > 45:
                raise TimeoutError('Quiet observer did not finish; inspect the owned host')
            time.sleep(.1)
        observation = {'wall_ms': (time.perf_counter() - started) * 1000,
                       'process_cpu_ms': cpu() - before,
                       'scope': 'Max process including private 200 ms transport and 100 ms observer'}
        request('observe', a.prefix + operation + '-idle-after')
        (folder / ('idle-' + a.prefix + operation + '-cpu.json')).write_text(json.dumps(observation, indent=2) + '\n')
        print(operation + ': ' + json.dumps(observation), flush=True)
finally:
    kernel.CloseHandle(handle)
