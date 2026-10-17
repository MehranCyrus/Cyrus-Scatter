from pathlib import Path
import argparse,subprocess,sys,time
from await_host import wait
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);a=p.parse_args();host=a.profile.resolve()
assert host.parent==ROOT/'build/mcp-qualification' and host.name.startswith('foundation-presets0853-recipient-')
for phase in ('missing','checkMissing','settled','valid','checkValid','liveCount','checkLiveCount'):
    if phase in ('checkMissing','checkValid','checkLiveCount'):wait(host,'CyrusReadyPresetEditor!=undefined and CyrusReadyPresetEditor.finished')
    (host/'terrain-phase.txt').write_text(phase)
    result=subprocess.run([sys.executable,str(ROOT/'tools/presets_0853/dispatch.py'),str(host)],input='fileIn "'+(ROOT/'tools/presets_0853/terrain.ms').as_posix()+'"',text=True,capture_output=True)
    print(phase,result.stdout.strip(),flush=True);assert result.returncode==0,result.stderr
    if phase in ('missing','checkMissing','valid'):time.sleep(1)
