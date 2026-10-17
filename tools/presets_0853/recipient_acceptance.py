"""Qualify the shipped Paint/channel packages from their installed paths."""
from pathlib import Path
import argparse,json,subprocess,sys
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);p.add_argument('producer',type=Path);a=p.parse_args()
host=a.profile.resolve();producer=a.producer.resolve()
assert host.parent==ROOT/'build/mcp-qualification' and host.name.startswith('foundation-presets0853-recipient-')
launch=json.loads((host/'launch.json').read_text());library=Path(launch['release'])/'Library-0.85.3'
for identity in ('borders','valley'):
    record=json.loads((producer/f'library-{identity}-capture.json').read_text())
    directory=library/'Presets'/record['recipe_sha256']
    assert (directory/'cyrus.package.json').is_file()
    record['package']=str(directory)
    (host/f'library-{identity}-capture.json').write_text(json.dumps(record,indent=2))
subprocess.run([sys.executable,str(ROOT/'tools/presets_0853/run_acceptance.py'),str(host),'--ids','borders','valley'],check=True)
