"""Ask a verified owned host to quit; check marker and OS absence separately."""
from pathlib import Path
import argparse,json,os,uuid
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);a=p.parse_args();host=a.profile.resolve()
assert host.parent==ROOT/'build/mcp-qualification' and host.name.startswith('foundation-presets0853-')
launch=json.loads((host/'launch.json').read_text());pid=int(launch['pid'])
pointer=host/'dev-request.txt'
if pointer.exists():
    previous=pointer.read_text(encoding='utf-8-sig');state=(host/'dev-result.txt').read_text(encoding='utf-8-sig')
    assert previous in state and state.startswith(('SUCCESS','ERROR'))
request=host/('request-close-'+uuid.uuid4().hex+'.ms')
request.write_text('(local p=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess();if p.Id!='+str(pid)+' do throw "Owned PID differs";(dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"closed-owned-session.txt") "Qualified owned host cleanup";quitMAX #noPrompt quiet:true exitCode:0)',encoding='utf-8-sig')
pending=host/'closing-pointer.tmp';pending.write_text(request.as_posix(),encoding='utf-8-sig');os.replace(pending,pointer)
print('Requested owned shutdown:',pid)
