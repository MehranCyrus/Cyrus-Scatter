"""Own one source-matched Max 2027 test profile; never install into artist Max."""
from pathlib import Path
import argparse,hashlib,json,sys,time,shutil

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/procedural_lab/layer_editor_071'))
from private_host import launch
sys.path.insert(0,str(ROOT/'tools/native_placement'))
from run_generation import send


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('operation',choices=('launch','send'))
    parser.add_argument('--name',required=True)
    parser.add_argument('--native',type=Path)
    parser.add_argument('--script',type=Path)
    parser.add_argument('--scale',type=float,choices=(1.,1.5,2.))
    args=parser.parse_args()
    if not args.name.startswith('density0862-'):raise ValueError('Use the owned density0862 profile prefix')
    host=ROOT/'build/mcp-qualification'/args.name
    if args.operation=='send':
        state=json.loads((host/'launch.json').read_text(encoding='utf-8'))
        assert state['max_year']==2027 and (host/'ready.json').is_file()
        send(host,args.script.resolve(),args.script.stem)
        return
    assert Path('C:/Program Files/Autodesk/3ds Max 2027/3dsmax.exe').is_file()
    native=args.native.resolve()
    receipt=json.loads((native/'receipt.json').read_text(encoding='utf-8'))
    assert receipt['max_year']==2027 and all(stage['exit_code']==0 for stage in receipt['stages'])
    for name,digest in receipt['sources'].items():
        assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==digest,name
    process,metadata=launch(host,ROOT/'AminScatter/scripts/AminScatterObject.ms',native,
        transport=True,max_year=2027,silent_startup=True,script_assets=('CyrusGallery.dll',),
        extra=('CustomControlsOptions.UIUserScaleFactor='+str(args.scale) if args.scale else ''))
    shutil.copytree(ROOT/'AminScatter/patterns',host/'scripts/Patterns')
    (host/'qualification-patterns.json').write_text(json.dumps({'source':'AminScatter/patterns','scope':'Product starter patterns, also verified against the final package'}))
    print(json.dumps({'pid':process.pid,'profile':str(host)}),flush=True)
    end=time.monotonic()+180
    while time.monotonic()<end:
        if (host/'startup-error.txt').is_file():raise RuntimeError((host/'startup-error.txt').read_text(encoding='utf-8-sig'))
        if (host/'ready.json').is_file():print('Owned Max 2027 host ready',flush=True);return
        if process.poll() is not None:raise RuntimeError('Owned host exited before readiness: '+str(process.returncode))
        time.sleep(.3)
    raise TimeoutError('Read the current owned process before considering any replacement')


if __name__=='__main__':main()
