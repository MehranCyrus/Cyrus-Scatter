"""Frozen policy, signature, local state and activation profile regression run."""
from pathlib import Path
import argparse,re
from run import ROOT,snapshot,run_command,write_json,compiler_environment

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--run',required=True);args=parser.parse_args()
    if not re.fullmatch(r'[a-z0-9-]+',args.run):raise SystemExit('Invalid run name')
    out=ROOT/'build/licensing-core-20261005'/args.run;out.mkdir(parents=True,exist_ok=False)
    source=snapshot(out)
    env=compiler_environment(Path('C:/Program Files/Microsoft Visual Studio/2022/Community'),'14.38.33130','10.0.19041.0')
    run_command([ROOT/'build/licensing-l1-tools-2026-10-04/Scripts/python.exe',source/'tools/licensing_lab/make_signed_fixtures.py',out/'fixtures'],out/'issuer',env)
    for year in [2026,2027]:
        sdk=ROOT/f'build/tooling/max{year}-sdk/Program Files/Autodesk/3ds Max {year} SDK/maxsdk';target=out/f'native-{year}'
        run_command(['cmake','-S',source/'tools/licensing_lab','-B',target,'-G','NMake Makefiles','-DCMAKE_BUILD_TYPE=Release',
            '-DCYRUS_BUILD_LICENSING_LAB=ON','-DCYRUS_BUILD_SIGNED_LICENSE_LAB=ON',f'-DCYRUS_SIGNED_FIXTURES={out}/fixtures',
            f'-DCYRUS_MAX_YEAR={year}',f'-DMAXSDK_ROOT={sdk}'],out/f'configure-{year}',env)
        run_command(['cmake','--build',target],out/f'build-{year}',env,timeout=600)
        run_command(['ctest','--test-dir',target,'--output-on-failure','-V'],out/f'tests-{year}',env)
        run_command([target/'license_permit_benchmark.exe',out/'fixtures/vectors.json'],out/f'permit-benchmark-{year}',env)
    write_json(out/'result.json',{'status':'PASS','sdk_builds':[2026,2027],'scope':'Core/Windows components; not Max UI or customer service'})

if __name__=='__main__':main()
