"""Point the configured-150% owned host at an exact qualified package."""
from pathlib import Path
import argparse,json,subprocess,sys
from await_host import wait
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);p.add_argument('producer',type=Path);a=p.parse_args()
host=a.profile.resolve();producer=a.producer.resolve()
assert host.parent==ROOT/'build/mcp-qualification' and host.name.startswith('foundation-presets0853-scale150-')
record=json.loads((producer/'library-borders-capture.json').read_text())
(host/'preset-path.txt').write_text(record['package']);(host/'acceptance-id.txt').write_text('borders')
for phase in ('setup','load','verify'):
    if phase=='verify':wait(host,'CyrusReadyPresetEditor!=undefined and CyrusReadyPresetEditor.finished')
    (host/'acceptance-phase.txt').write_text(phase)
    result=subprocess.run([sys.executable,str(ROOT/'tools/presets_0853/dispatch.py'),str(host)],input='fileIn "'+(ROOT/'tools/presets_0853/acceptance.ms').as_posix()+'"',text=True,capture_output=True)
    print(phase,result.stdout.strip(),flush=True);assert result.returncode==0,result.stderr
