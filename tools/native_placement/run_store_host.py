"""N02 real Max 2027 native GC, readback, precision and Brush ABI checks."""
from pathlib import Path
import argparse,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('host');args=parser.parse_args()
assert args.host.startswith('foundation-memory0854-nativestore-')
host=ROOT/'build/mcp-qualification'/args.host
deadline=time.monotonic()+90
while not (host/'ready.json').exists():
    if (host/'startup-error.txt').exists():raise RuntimeError((host/'startup-error.txt').read_text())
    if time.monotonic()>deadline:raise TimeoutError('Observe owned startup before retrying')
    time.sleep(.2)
for phase in ['construct','retain','release']:
    (host/'native-store-phase.txt').write_text(phase)
    proc=subprocess.run([sys.executable,str(ROOT/'tools/memory_0854/host.py'),'send',args.host,
                         '--script',str(ROOT/'tools/native_placement/store_host.ms')],capture_output=True,text=True)
    print(proc.stdout,flush=True)
    if proc.returncode:raise RuntimeError(proc.stdout+proc.stderr)
    result=(host/f'native-store-{phase}.txt').read_text(encoding='utf-8-sig')
    assert 'PASS: complete' in result and 'FAIL:' not in result,result
print('N02 HOST LIFETIME AND POD BOUNDARY PASSED',flush=True)
