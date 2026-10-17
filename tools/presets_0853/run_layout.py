"""Mount first, let Max/Qt settle, then measure actual panel bounds."""
from pathlib import Path
import argparse,json,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('profile',type=Path);p.add_argument('--scale',type=float,required=True);a=p.parse_args();host=a.profile.resolve()
assert host.parent==ROOT/'build/mcp-qualification' and host.name.startswith('foundation-presets0853-')
for owner in (0,1):
    for mode in ('prepare','observe'):
        label=f'settled-{a.scale}-{owner}-{mode}'
        command={'label':label,'owner_index':owner,'scale':a.scale,'advanced':True,'close':False,'capture':False,mode:True}
        (host/'layout-command.json').write_text(json.dumps(command))
        result=subprocess.run([sys.executable,str(ROOT/'tools/presets_0853/dispatch.py'),str(host)],input='python.ExecuteFile "'+(ROOT/'tools/presets_0853/inspect_layout.py').as_posix()+'"',text=True,capture_output=True)
        print(label,result.stdout.strip(),flush=True);assert result.returncode==0,result.stderr
        if mode=='prepare':time.sleep(1)
        else:
            record=json.loads((host/('layout-'+label+'.json')).read_text());assert record['status']=='passed',(record['clipped_count'],record['overlap_count'])
