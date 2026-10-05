"""Build a fresh, frozen native-ownership experiment; NEVER SHIP this target."""
from pathlib import Path
import argparse,json,re,shutil
from PIL import Image,ImageChops
from run import ROOT,snapshot,run_command,host,write_json,digest,compiler_environment

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run',required=True)
    parser.add_argument('--years',nargs='+',type=int,choices=[2026,2027],default=[2026,2027])
    args=parser.parse_args()
    if not re.fullmatch(r'[a-z0-9-]+',args.run):raise SystemExit('Invalid private run name')
    output=ROOT/'build/licensing-native-20261005'/args.run
    output.mkdir(parents=True,exist_ok=False)
    source=snapshot(output)
    env=compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
    run_command([ROOT/'build/licensing-l1-tools-2026-10-04/Scripts/python.exe',source/'tools/licensing_lab/make_signed_fixtures.py',output/'fixtures'],output/'issuer',env)
    for year in args.years:
        sdk=ROOT/f'build/tooling/max{year}-sdk/Program Files/Autodesk/3ds Max {year} SDK/maxsdk'
        target=output/f'native-{year}'
        run_command(['cmake','-S',source/'AminScatter','-B',target,'-G','NMake Makefiles','-DCMAKE_BUILD_TYPE=Release',
                     '-DCYRUS_NATIVE_LICENSE_EXPERIMENT=ON',f'-DCYRUS_SIGNED_FIXTURES={output}/fixtures',
                     f'-DCYRUS_MAX_YEAR={year}',f'-DMAXSDK_ROOT={sdk}'],output/f'configure-{year}',env)
        run_command(['cmake','--build',target],output/f'build-{year}',env,timeout=600)
        run_command(['ctest','--test-dir',target,'--output-on-failure','-V'],output/f'tests-{year}',env)
    if 2027 not in args.years:return
    native=output/'bin';native.mkdir()
    for path in (output/'native-2027').glob('*.dl?'):shutil.copy2(path,native)
    write_json(output/'binaries.json',{p.name:digest(p) for p in native.glob('*.dl?')})
    checks={stage:host(source,output,stage,Path('C:/Program Files/Autodesk/3ds Max 2027'),fixture='native_fixture.ms') for stage in ['create','reopen']}
    comparisons={}
    with Image.open(output/'owned-active.png') as active:
        if active.size!=(128,128) or len(active.convert('RGB').getcolors(16385) or [])<4:raise RuntimeError('Blank render')
        for name in ['owned-expired.png','owned-reopened.png']:
            with Image.open(output/name) as image:
                difference=ImageChops.difference(active.convert('RGB'),image.convert('RGB'))
                maximum=max(high for low,high in difference.getextrema())
                changed=sum(p!=(0,0,0) for p in difference.getdata())
                comparisons[name]={'maximum_channel_difference':maximum,'changed_pixels':changed}
                # Native rows are compared independently at full float precision.
                # Allow one quantization level in at most two pixels at 128x128;
                # record exact values, never describe this as pixel-identical.
                if maximum>1 or changed>2:raise RuntimeError('Changed continuity render: '+name)
        with Image.open(output/'owned-source-changed.png') as image:
            if not ImageChops.difference(active.convert('RGB'),image.convert('RGB')).getbbox():raise RuntimeError('Missing external source counterexample')
    write_json(output/'result.json',{'status':'PASS','scope':'Native count/seed owner, actual CS Edit and simple raw generator; development issuer and clock',
        'sdk_builds':args.years,'runtime':'Max 2027 Scanline, instance-based disposable render transport',
        'render_comparisons':comparisons,'external_source_changes_pixels':True,'checks':checks,
        'full_product_enforcement':False,'scene_cryptographic_provenance':False,'pflow_qualification':False})
    print('PASS native ownership experiment: '+str(output),flush=True)

if __name__=='__main__':main()
