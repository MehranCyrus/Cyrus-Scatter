"""Package the verified Mesh candidate without installing into the artist host."""
from pathlib import Path
from types import SimpleNamespace
import argparse,hashlib,json,shutil,sys
from build import ROOT,BASE
sys.path.insert(0,str(ROOT/'tools'))
from build_max import package

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--run',required=True);args=parser.parse_args()
    run=(BASE/args.run).resolve()
    if run.parent!=BASE.resolve(): raise SystemExit('Run must be a private child directory')
    for name in ['ready.json','mesh-smoke.json','mesh-lifecycle.json','lifecycle.json','hardening.json','mesh-parity.json','mesh-memory.json','artist-mesh-200k-metadata.json','artist-mesh-2m-metadata.json','artist-mesh-2m-trials.json','analysis.json','shutdown.json']:
        json.loads((run/name).read_text(encoding='utf-8'))
    script=ROOT/'AminScatter/scripts/AminScatterObject.ms'
    if sha(script)!=sha(run/'AminScatterObject.ms'): raise SystemExit('Current script differs from tested script')
    records=[]
    for year in [2026,2027]:
        build=BASE/f'max{year}'
        if '100% tests passed, 0 tests failed out of 9' not in (build/'build-2.log').read_text():
            raise SystemExit(f'Missing native suite pass for {year}')
        staging=BASE/'package-staging'/f'max{year}';target=staging/'AminScatter';target.mkdir(parents=True,exist_ok=True)
        for name in ['AminScatter.dlx','CyrusScatterEdit.dlm']:
            if year==2027 and sha(build/name)!=sha(run/'bin'/name): raise SystemExit('Native build differs from tested DLL')
            shutil.copy2(build/name,target/name)
        config=SimpleNamespace(max_year=year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=ROOT/'dist/retained-mesh-0.64')
        package('AminScatter','Cyrus Scatter','0.64',['AminScatter.dlx','CyrusScatterEdit.dlm'],'AminScatterObject.ms',config,staging)
        path=config.output/f'CyrusScatter-0.64-Max{year}.mzp'
        records.append({'year':year,'package':str(path),'sha256':sha(path),'script_sha256':sha(script),'runtime_tested':year==2027})
    (BASE/'packages.json').write_text(json.dumps(records,indent=2)+'\n')
    print(json.dumps(records,indent=2))

if __name__=='__main__': main()
