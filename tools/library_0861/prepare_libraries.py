"""Stage host-specific library copies and use the owned 2027 host for back-saving."""
from pathlib import Path
import argparse,hashlib,json,shutil,sys
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'tools/native_placement'));from run_generation import send,ready
p=argparse.ArgumentParser();p.add_argument('host');p.add_argument('--output',required=True,type=Path);a=p.parse_args();assert a.host.startswith('library-surface0861-')
host=ROOT/'build/mcp-qualification'/a.host;ready(host);assert json.loads((host/'launch.json').read_text())['max_year']==2027
out=a.output.resolve();assert out.is_relative_to(ROOT/'build')
source=ROOT/'AminScatter/library';inventory=json.loads((source/'inventory.json').read_text())
for year in (2024,2026,2027):
 destination=out/f'library{year}';assert not destination.exists();shutil.copytree(source,destination)
 if year!=2027:
  script=host/f'backsave-{year}.ms'
  script.write_text('''for d in #(CyrusRecipeBrowser,CyrusReadyPresetEditor) where d!=undefined do destroyDialog d
'''+ '\n'.join('if not loadMaxFile @"'+(source/entry['scene']).as_posix()+'" quiet:true useFileUnits:true do throw "Example load failed"\nif not saveMaxFile @"'+(destination/entry['scene']).as_posix()+'" quiet:true saveAsVersion:'+str(year)+' do throw "Example back-save failed"' for entry in inventory['entries']),encoding='utf-8-sig')
  send(host,script,'Save example copies for '+str(year))
 copied=json.loads((destination/'inventory.json').read_text());copied['version']='0.86.1';copied['max_year']=year
 copied['delivery_note']='Native/managed pair built for this host. Example copies saved in matching format; consult 0.86.1 report for actual host qualification.'
 copied['files']={name:hashlib.sha256((destination/name).read_bytes()).hexdigest() for name in copied['files']}
 (destination/'inventory.json').write_text(json.dumps(copied,indent=2)+'\n',encoding='utf-8')
 print('Staged',destination,flush=True)
