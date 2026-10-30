"""Submit one serialized MAXScript request to this campaign's private host."""
from pathlib import Path
import argparse, time

p=argparse.ArgumentParser()
p.add_argument('host', type=Path)
p.add_argument('script', type=Path)
p.add_argument('--wait', type=float, default=20)
a=p.parse_args()
root=Path(__file__).resolve().parents[3]
host=a.host.resolve(); script=a.script.resolve()
assert host.is_relative_to(root/'build') and (host/'loaded-identity.json').exists()
assert script.is_file()
request=host/('request-'+str(time.time_ns())+'.ms')
command=('python.ExecuteFile' if script.suffix.lower()=='.py' else 'fileIn')+' @"'+script.as_posix()+'"\n'
request.write_text(command,encoding='utf-8-sig')
(host/'dev-request.txt').write_text(request.as_posix(),encoding='utf-8')
until=time.monotonic()+a.wait
while time.monotonic()<until:
    result=host/'dev-result.txt'
    if result.exists():
        text=result.read_text(encoding='utf-8-sig')
        if request.as_posix() in text:
            print(text[:2500]);break
    time.sleep(.2)
else:
    print('Request still pending; inspect its result before submitting another:',request)
