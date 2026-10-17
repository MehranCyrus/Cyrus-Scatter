"""Run bounded extra workflows; idle pause is explicitly caller-owned."""
from pathlib import Path
import argparse, subprocess, sys
from await_host import wait
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);p.add_argument('phases',nargs='+');a=p.parse_args()
host=a.profile.resolve()
assert host.parent==ROOT/'build/mcp-qualification' and host.name.startswith('foundation-presets0853-')
for phase in a.phases:
    if phase in ('checkCapacity','checkLive'):wait(host,'CyrusReadyPresetEditor!=undefined and CyrusReadyPresetEditor.finished')
    if phase=='checkRevision':wait(host,'CyrusPresetReviseEditor!=undefined and CyrusPresetReviseEditor.finished')
    if phase=='idleStart':wait(host,'not CyrusRecipeBrowser.scanTimer.active')
    if phase=='closeAfterAddFinish':wait(host,'(cyrusAssetPackagePoll CyrusReadyPresetEditor.job)[1]=="ready"')
    (host/'extra-phase.txt').write_text(phase,encoding='utf-8')
    result=subprocess.run([sys.executable,str(ROOT/'tools/presets_0853/dispatch.py'),str(host)],input='fileIn "'+(ROOT/'tools/presets_0853/extra.ms').as_posix()+'"',text=True,capture_output=True)
    print(phase,result.stdout.strip(),flush=True)
    assert result.returncode==0,result.stderr
    text=(host/f'extra-{phase}.txt').read_text(encoding='utf-8-sig')
    assert 'PASS: complete' in text and 'FAIL:' not in text,text
