"""Check current library sizing and passive resize at two window sizes."""
from pathlib import Path
import argparse,json,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);p.add_argument('--installed',action='store_true');a=p.parse_args();host=a.profile.resolve()
assert host.parent==ROOT/'build/mcp-qualification' and host.name.startswith('foundation-presets0853-')
for size in ([1000,680],[850,620]):
    label='library-'+'x'.join(map(str,size))
    for operation in ('open','verify'):
        (host/'library-command.json').write_text(json.dumps({'operation':operation,'size':size,'installed':a.installed,'label':label}))
        result=subprocess.run([sys.executable,str(ROOT/'tools/presets_0853/dispatch.py'),str(host)],input='python.ExecuteFile "'+(ROOT/'tools/presets_0853/inspect_library.py').as_posix()+'"',text=True,capture_output=True)
        print(label,operation,result.stdout.strip(),flush=True);assert result.returncode==0,result.stderr
        if operation=='open':time.sleep(2)
