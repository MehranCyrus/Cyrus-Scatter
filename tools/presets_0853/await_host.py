"""Observe asynchronous completion; never retry a scene mutation."""
from pathlib import Path
import subprocess,sys,time,uuid
ROOT=Path(__file__).resolve().parents[2]
def wait(host,expression,seconds=20):
    name='await-'+uuid.uuid4().hex+'.txt';end=time.monotonic()+seconds
    code='(local ready=('+expression+');(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"'+name+'") (ready as string))'
    while time.monotonic()<end:
        result=subprocess.run([sys.executable,str(ROOT/'tools/presets_0853/dispatch.py'),str(host)],input=code,text=True,capture_output=True)
        assert result.returncode==0,result.stdout+result.stderr
        if (host/name).read_text(encoding='utf-8-sig')=='true':return
        time.sleep(.1)
    raise TimeoutError('Completion did not settle: '+expression)
