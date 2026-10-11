"""Package a frozen owner-trusted candidate without building or installing it."""
import argparse,json,shutil,sys
from pathlib import Path
from types import SimpleNamespace
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
import build_max

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--candidate',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True);a=p.parse_args();candidate=a.candidate.resolve()
    receipt=json.loads((candidate/'build.json').read_text())
    native=candidate/'native';source=candidate/'source'
    header=ROOT/'CyrusLicensing/team/team_public_key.h'
    # A test authority build cannot be passed off as the owner's deliverable.
    build_max.require_team_authority((native/'AminScatter.dlx').read_bytes(),header)
    for name,digest in receipt['files'].items():
        if build_max.sha((native/name).read_bytes())!=digest:raise RuntimeError('Candidate binary changed: '+name)
    records=json.loads((candidate/'source.json').read_text())
    for name,digest in records.items():
        if name=='team_public_key.h':continue
        if build_max.sha((source/name).read_bytes())!=digest:raise RuntimeError('Candidate source changed: '+name)
    stage=candidate/'package-stage';(stage/'AminScatter').mkdir(parents=True,exist_ok=False)
    for name in receipt['files']:shutil.copy2(native/name,stage/'AminScatter'/name)
    build_max.ROOT=source
    args=SimpleNamespace(max_year=receipt['year'],tools_version='14.38.33130',windows_sdk='10.0.19041.0',
                         output=a.output,team_trust_header=header)
    build_max.package('AminScatter','Cyrus Scatter',build_max.scatter_version(),
        ['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh'],'AminScatterObject.ms',args,stage)

if __name__=='__main__':main()
