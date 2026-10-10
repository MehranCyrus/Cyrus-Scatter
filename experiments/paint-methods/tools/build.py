"""Build only this lab; never install into Max or build Cyrus modules."""
from pathlib import Path
import argparse,hashlib,json,subprocess,os,datetime
LAB=Path(__file__).resolve().parents[1]
ROOT=LAB.parents[1]
def hashes():
    return {p.relative_to(LAB).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['src','methods','third_party','tests','scripts'] for p in (LAB/folder).rglob('*') if p.is_file() and p.suffix in ['.h','.cpp','.ms','.json']}
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--output',type=Path,required=True);ap.add_argument('--core-only',action='store_true');args=ap.parse_args()
    output=args.output.resolve();output.mkdir(parents=True,exist_ok=True)
    sdk=ROOT/'build/tooling/max2027-sdk/Program Files/Autodesk/3ds Max 2027 SDK/maxsdk'
    vc=Path('C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.38.33130')
    kits=Path('C:/Program Files (x86)/Windows Kits/10');version='10.0.19041.0'
    bins=[vc/'bin/Hostx64/x64',kits/'bin'/version/'x64']
    includes=[vc/'include',vc/'atlmfc/include']+[kits/'Include'/version/x for x in ['ucrt','shared','um','winrt','cppwinrt']]
    libs=[vc/'lib/x64',vc/'atlmfc/lib/x64']+[kits/'Lib'/version/x/'x64' for x in ['ucrt','um']]
    env=dict(os.environ);env['PATH']=os.pathsep.join(map(str,bins))+os.pathsep+env['PATH'];env['INCLUDE']=os.pathsep.join(map(str,includes));env['LIB']=os.pathsep.join(map(str,libs))
    before=hashes();commands=[['cmake','-S',str(LAB),'-B',str(output),'-G','NMake Makefiles','-DCMAKE_BUILD_TYPE=Release',f'-DPAINTLAB_MAX={"OFF" if args.core_only else "ON"}',f'-DMAXSDK_ROOT={sdk}'],['cmake','--build',str(output)],['ctest','--test-dir',str(output),'--output-on-failure']]
    for i,cmd in enumerate(commands):
        result=subprocess.run(cmd,env=env,capture_output=True,text=True);(output/f'stage-{i}.log').write_text(result.stdout+result.stderr);print(f'stage {i}: {result.returncode}',flush=True)
        if result.returncode:print((result.stdout+result.stderr)[-16000:]);raise SystemExit(result.returncode)
    if before!=hashes():raise RuntimeError('Sources changed during build; rerun')
    receipt={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'sources':before,'commands':commands,'binaries':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in output.glob('*.dlx')},'host_tested':False}
    (output/'build-receipt.json').write_text(json.dumps(receipt,indent=2));print(output)
if __name__=='__main__':main()
