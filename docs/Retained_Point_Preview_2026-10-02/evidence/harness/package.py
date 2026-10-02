"""Package exactly the qualified candidate, without installing it."""
from pathlib import Path
from types import SimpleNamespace
import argparse
import hashlib
import json
import shutil
import sys
from build import ROOT, BASE

sys.path.insert(0,str(ROOT/'tools'))
from build_max import package

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--run',required=True)
    args=parser.parse_args()
    run=(BASE/args.run).resolve()
    if run.parent!=BASE.resolve():
        raise SystemExit('Run must be a child of the private build directory')
    for name in ['ready.json','lifecycle.json','hardening.json','artist-maximized-metadata.json','artist-maximized-trials.json']:
        json.loads((run/name).read_text(encoding='utf-8'))
    script=ROOT/'AminScatter/scripts/AminScatterObject.ms'
    if sha(script)!=sha(run/'AminScatterObject.ms'):
        raise SystemExit('Current generated script differs from the tested script')
    records=[]
    for year in [2026,2027]:
        build=BASE/f'max{year}'
        log=(build/'build-2.log').read_text()
        if '100% tests passed, 0 tests failed out of 9' not in log:
            raise SystemExit(f'Missing nine-suite pass for {year}')
        staging=BASE/'package-staging'/f'max{year}'
        target=staging/'AminScatter'
        target.mkdir(parents=True,exist_ok=True)
        for name in ['AminScatter.dlx','CyrusScatterEdit.dlm']:
            source=build/name
            if year==2027 and sha(source)!=sha(run/'bin'/name):
                raise SystemExit(f'Package binary {name} differs from the interactive-tested binary')
            shutil.copy2(source,target/name)
        config=SimpleNamespace(max_year=year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=ROOT/'dist/retained-point-0.63')
        package('AminScatter','Cyrus Scatter','0.63',['AminScatter.dlx','CyrusScatterEdit.dlm'],'AminScatterObject.ms',config,staging)
        result=config.output/f'CyrusScatter-0.63-Max{year}.mzp'
        records.append({'year':year,'package':str(result),'sha256':sha(result),'interactive_runtime':year==2027,'script_sha256':sha(script)})
    (BASE/'packages.json').write_text(json.dumps(records,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(records,indent=2))

if __name__=='__main__':
    main()
