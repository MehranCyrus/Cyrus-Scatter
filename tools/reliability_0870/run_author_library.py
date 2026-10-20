"""Stage and reauthor eight library entries without overwriting their source receipts."""
from pathlib import Path
import argparse,hashlib,json,re,shutil,sys,time,uuid
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send,ready
p=argparse.ArgumentParser(description=__doc__);p.add_argument('host');p.add_argument('--ids',nargs='+',required=True);p.add_argument('--library',type=Path,required=True);a=p.parse_args()
assert re.fullmatch(r'density0862-reliability-[a-z0-9-]+',a.host)
host=ROOT/'build/mcp-qualification'/a.host;ready(host)
library=a.library.resolve();assert library.is_relative_to(ROOT/'build/reliability-0870-20261019')
source=ROOT/'AminScatter/library';sha=lambda path:hashlib.sha256(path.read_bytes()).hexdigest()
if not library.exists():
 shutil.copytree(source,library)
 (library.parent/(library.name+'-baseline.json')).write_text(json.dumps({p.relative_to(source).as_posix():sha(p) for p in source.rglob('*') if p.is_file()},indent=2)+'\n')
inventory=json.loads((library/'inventory.json').read_text());assert set(a.ids)<={e['id'] for e in inventory['entries']}
script=host/('author-library-'+uuid.uuid4().hex+'.ms')
script.write_text('python.ExecuteFile "'+(ROOT/'tools/reliability_0870/author_library.py').as_posix()+'"',encoding='utf-8-sig')
for identifier in a.ids:
 for phase in ('open','capture'):
  (host/'author-library-command.json').write_text(json.dumps({'id':identifier,'phase':phase,'library':str(library)}))
  send(host,script,'author '+identifier+' / '+phase);time.sleep(2)
  record=json.loads((host/('author-'+identifier+'-'+phase+'.json')).read_text());assert record['status']=='passed',record
 print(identifier,'PASS',flush=True)
