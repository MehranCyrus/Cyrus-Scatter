"""Send a script only to this campaign's redirected Max process."""
from pathlib import Path
import argparse,time,uuid
root=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('script',type=Path);p.add_argument('--host',required=True);p.add_argument('--timeout',type=float,default=180);a=p.parse_args()
folder=(root/'build/vector-brush-078'/a.host).resolve()
if folder.parent!=root/'build/vector-brush-078' or not (folder/'ready.json').is_file():raise SystemExit('Owned host not ready')
target=folder/('test-'+uuid.uuid4().hex+'.ms');target.write_bytes(a.script.read_bytes())
request=folder/'next-request.txt';request.write_text(target.as_posix());request.replace(folder/'dev-request.txt')
start=time.monotonic()
while time.monotonic()-start<a.timeout:
 r=folder/'dev-result.txt';text=r.read_text(encoding='utf-8-sig') if r.exists() else ''
 if target.as_posix() in text:
  print(text);raise SystemExit(0 if text.startswith('SUCCESS') else 1)
 time.sleep(.25)
raise SystemExit('Timed out; inspect owned host before submitting more work.')
