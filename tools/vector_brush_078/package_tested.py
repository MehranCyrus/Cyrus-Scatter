"""Package an explicitly named, qualified private run; never installs anything."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
from types import SimpleNamespace
import sys
import zipfile

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from build_max import package,scatter_version

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    p=argparse.ArgumentParser()
    for name in ('host','native','analyzer'):p.add_argument('--'+name,required=True)
    p.add_argument('--output',type=Path,required=True)
    p.add_argument('--receipt',type=Path,required=True)
    a=p.parse_args();base=ROOT/'build/vector-brush-078'
    for value in (a.host,a.native,a.analyzer):
        if Path(value).name!=value or value in ('.','..'):raise SystemExit('Campaign directory names required')
    host=base/a.host;launch=json.loads((host/'launch.json').read_text())
    year=launch['max_year']
    button_checks=(host/'button-checks.txt').read_text().splitlines()
    if 'Button workflow saved' not in button_checks:raise SystemExit('Button/callback workflow incomplete')
    layout=json.loads((host/'layout-result.json').read_text())
    if not layout['passed']:raise SystemExit('Native layout qualification failed')
    suite=json.loads((host/'suite.json').read_text())
    if len(suite)!=8 or any(row['exit_code'] for row in suite):raise SystemExit('Host regression suite incomplete')
    checks=(host/'vector-checks.txt').read_text().splitlines()
    if 'Unchanged feather settings do not invalidate caches or create edits' not in checks:
        raise SystemExit('Extended vector qualification incomplete')
    playback=(host/'playback/result.txt').read_text()
    if 'SUCCESS 835 assertions' not in playback:raise SystemExit('Playback qualification incomplete')
    inspection=json.loads((host/'inspection.json').read_text())
    if len(inspection['checks'])!=6:raise SystemExit('Passive inspection qualification incomplete')
    script=ROOT/'AminScatter/scripts/AminScatterObject.ms'
    if sha(script)!=launch['script_sha256']:raise SystemExit('Generated script differs from the tested script')
    # UI may be revised after compilation; all compiled source must still match.
    builds={}
    for product,folder in (('AminScatter',base/a.native),('CyrusSurfaceAnalyzer',base/a.analyzer)):
        receipt=json.loads((folder/'receipt.json').read_text());builds[product]=receipt
        if receipt['max_year']!=year:raise SystemExit('Build/host year mismatch')
        if any(stage['exit_code']!=0 for stage in receipt['stages']):raise SystemExit('Build stage failed')
        for name,digest in receipt['sources'].items():
            if name=='AminScatter/scripts/AminScatterObject.ms':continue
            if sha(ROOT/name)!=digest:raise SystemExit('Compiled source changed: '+name)
    vendor=ROOT/'AminScatter/third_party/clipper2'
    provenance=json.loads((vendor/'PROVENANCE.json').read_text())
    for name,digest in provenance['files'].items():
        if sha(vendor/name)!=digest:raise SystemExit('Vendor source changed: '+name)
    stage=base/f'package-stage-{year}';(stage/'AminScatter').mkdir(parents=True,exist_ok=True)
    (stage/'CyrusSurfaceAnalyzer').mkdir(parents=True,exist_ok=True)
    product_modules=['AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm']
    for name in product_modules:
        digest=launch['binaries'][name]
        path=base/a.native/name
        if sha(path)!=digest or sha(host/'bin'/name)!=digest:raise SystemExit('Native module differs from tested build: '+name)
        shutil.copy2(path,stage/'AminScatter'/name)
    analyzer=base/a.analyzer/'CyrusSurfaceAnalyzer.dlx'
    if sha(analyzer)!=next(iter(builds['CyrusSurfaceAnalyzer']['binaries'].values())):raise SystemExit('Analyzer binary changed')
    shutil.copy2(analyzer,stage/'CyrusSurfaceAnalyzer'/analyzer.name)
    args=SimpleNamespace(max_year=year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=a.output)
    package('AminScatter','Cyrus Scatter',scatter_version(),product_modules,'AminScatterObject.ms',args,stage)
    package('CyrusSurfaceAnalyzer','Cyrus Surface Analyzer','0.14',[analyzer.name],'CyrusSurfaceAnalyzer.ms',args,stage)
    archives={}
    for path in sorted(a.output.glob('*.mzp')):
        with zipfile.ZipFile(path) as z:
            manifest=json.loads(z.read('manifest.json'))
            if 'CyrusPrivatePaintProbe.dlx' in z.namelist():raise SystemExit('Private probe entered package')
        archives[path.name]={'sha256':sha(path),'manifest':manifest}
    result={'qualification':'Development candidate; no artist-profile installation or computer use',
            'scatter_private_host':host.relative_to(ROOT).as_posix(),'script_sha256':launch['script_sha256'],
            'native_build':(base/a.native).relative_to(ROOT).as_posix(),'native_suites':15,
            'host_assertions':len(checks),'playback_assertions':835,
            'button_workflow_assertions':len(button_checks),'native_layout':layout,'max_year':year,
            'passive_inspection_assertions':len(inspection['checks']),
            'analyzer_qualification':'Unchanged 0.14 source; fresh SDK compilation and one core suite only',
            'clipper2':provenance,'archives':archives}
    a.receipt.parent.mkdir(parents=True,exist_ok=True)
    a.receipt.write_text(json.dumps(result,indent=2)+'\n')

if __name__=='__main__':main()
