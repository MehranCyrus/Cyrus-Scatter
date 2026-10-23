"""Build the explicitly requested three-host Scatter + Analyzer EXE."""
from pathlib import Path
from types import SimpleNamespace
import argparse,hashlib,json,shutil,sys,zipfile

ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'build/combined-installer-08685-20261022'
sys.path.insert(0,str(ROOT/'tools'));import build_max
sys.path.insert(0,str(ROOT/'AminScatter/tools'));import build_installer
YEARS=(2024,2026,2027)
NAMES=('AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh')

def sha(p):
    with Path(p).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def verify_build(folder,year):
    receipt=json.loads((folder/'receipt.json').read_text(encoding='utf-8'))
    assert receipt['max_year']==year and receipt['clean_compilation'] and all(s['exit_code']==0 for s in receipt['stages'])
    for p,h in {**receipt['sources'],**receipt['binaries']}.items():assert sha(ROOT/p)==h,p
    return receipt
def verify_archive(path,year,native):
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None
        m=json.loads(z.read('manifest.json'));assert m['max_year']==year
        assert set(z.namelist())==set(m['files'])|{'manifest.json'}
        for n,h in m['files'].items():assert hashlib.sha256(z.read(n)).hexdigest()==h,n
        for n in native:assert m['files'][n]==sha(native[n]),n
        assert str((year-1998)*1000).encode() in z.read('install.ms')
        assert b'__MAX_' not in z.read('install.ms')
        assert not any('fixture' in n.lower() or n.endswith('.max') for n in z.namelist())
        return m

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--attempt',required=True);a=parser.parse_args()
    if not a.attempt.isalnum():raise ValueError('An alphanumeric fresh attempt identity is required')
    out=WORK/a.attempt;out.mkdir(exist_ok=False)
    core=WORK/'CyrusInstaller.dll';build_installer.build(core)
    scatter=[];analyzers=[];manifests={};builds={}
    for year in YEARS:
        native=WORK/f'scatter-{year}'
        analyzer=WORK/f'analyzer-{year}' if year!=2027 else ROOT/'build/refinement-08683-20261022/analyzer-final01'
        builds[f'scatter-{year}']=verify_build(native,year);builds[f'analyzer-{year}']=verify_build(analyzer,year)
        stage=out/f'stage-{year}';s=stage/'AminScatter';an=stage/'CyrusSurfaceAnalyzer'
        s.mkdir(parents=True);an.mkdir()
        for n in (*NAMES,'CyrusGallery.dll'):shutil.copy2(native/n,s/n)
        for n in ('CyrusInstaller.dll','CyrusInstaller.build.json'):shutil.copy2(WORK/n,s/n)
        shutil.copy2(analyzer/'CyrusSurfaceAnalyzer.dlx',an/'CyrusSurfaceAnalyzer.dlx')
        args=SimpleNamespace(max_year=year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=out/'packages',
            team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h',content_dir=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content')
        build_max.package('AminScatter','Cyrus Scatter','0.86.8.5',list(NAMES),'AminScatterObject.ms',args,stage)
        build_max.package('CyrusSurfaceAnalyzer','Cyrus Surface Analyzer','0.14.1',['CyrusSurfaceAnalyzer.dlx'],'CyrusSurfaceAnalyzer.ms',args,stage)
        sm=args.output/f'CyrusScatter-0.86.8.5-Max{year}.mzp';am=args.output/f'CyrusSurfaceAnalyzer-0.14.1-Max{year}.mzp'
        manifests[sm.name]=verify_archive(sm,year,{n:native/n for n in (*NAMES,'CyrusGallery.dll')})
        manifests[am.name]=verify_archive(am,year,{'CyrusSurfaceAnalyzer.dlx':analyzer/'CyrusSurfaceAnalyzer.dlx'})
        scatter.append(sm);analyzers.append(am)
    exe=out/'CyrusScatter-0.86.8.5-Setup.exe'
    build_installer.build_exe(exe,scatter,core,analyzers)
    receipt={'exe':str(exe),'exe_sha256':sha(exe),'packages':{p.name:sha(p) for p in scatter+analyzers},'manifests':manifests,
        'max_years':list(YEARS),'scatter_version':'0.86.8.5','analyzer_version':'0.14.1','builds':builds}
    (out/'package-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'exe':str(exe),'sha256':sha(exe),'max_years':list(YEARS),'analyzer':'0.14.1'}))

if __name__=='__main__':main()
