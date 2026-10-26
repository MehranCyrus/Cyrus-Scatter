"""Package source-matched 0.87.1 SDK payloads; never installs into artist profiles."""
from pathlib import Path
from argparse import ArgumentParser,Namespace
import hashlib,json,shutil,sys,zipfile
ROOT=Path(__file__).resolve().parents[2]
sys.path[:0]=[str(ROOT/'tools'),str(ROOT/'AminScatter/tools')]
import build_max,build_installer
NAMES=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
    p=ArgumentParser();p.add_argument('--producer',type=Path,required=True,help='Parent with max2024/max2026/max2027 build folders')
    p.add_argument('--output',type=Path,required=True);p.add_argument('--work',type=Path,required=True)
    p.add_argument('--producer-2024',type=Path,help='Explicit alternate short build path');a=p.parse_args()
    output=a.output.resolve();work=a.work.resolve();producers=a.producer.resolve()
    if not output.is_relative_to(ROOT/'dist') or not work.is_relative_to(ROOT/'build'):raise ValueError('Owned distribution/build paths required')
    assert build_max.scatter_version()=='0.87.1';output.mkdir(parents=True,exist_ok=False);work.mkdir(parents=True,exist_ok=False)
    core=work/'core/CyrusInstaller.dll';build_installer.build(core);packages=[];evidence={}
    for year in (2024,2026,2027):
        native=a.producer_2024.resolve() if year==2024 and a.producer_2024 else producers/f'max{year}';receipt_path=native/'receipt.json'
        receipt=build_max.verify_native_receipt(receipt_path,'AminScatter',year,{n:native/n for n in NAMES})
        assert receipt['status']=='complete' and receipt['tests_run'] and not receipt['preview_fault_lab']
        stage=work/f'stage-{year}/AminScatter';stage.mkdir(parents=True)
        for name in [*NAMES,'CyrusGallery.dll','CyrusGallery.build.json']:shutil.copy2(native/name,stage/name)
        for name in ['CyrusInstaller.dll','CyrusInstaller.build.json']:shutil.copy2(core.with_name(name),stage/name)
        args=Namespace(max_year=year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=output,
            team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h',content_dir=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content',native_receipts={'AminScatter':receipt_path})
        build_max.package('AminScatter','Cyrus Scatter','0.87.1',NAMES,'AminScatterObject.ms',args,stage.parent)
        package=output/f'CyrusScatter-0.87.1-Max{year}.mzp';packages.append(package)
        payload=work/f'payload-{year}';payload.mkdir()
        with zipfile.ZipFile(package) as z:
            assert z.testzip() is None;manifest=json.loads(z.read('manifest.json'))
            assert manifest['version']=='0.87.1' and manifest['max_year']==year
            for name,digest in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest,name
            assert str((year-1998)*1000).encode() in z.read('install.ms') and b'__MAX_' not in z.read('install.ms')
            for name in [*NAMES,'CyrusScatter.ms','CyrusGallery.dll','CyrusInstaller.dll']:(payload/name).write_bytes(z.read(name))
        evidence[str(year)]={'native_receipt':str(receipt_path),'receipt_sha256':sha(receipt_path),'mzp':str(package),'mzp_sha256':sha(package),'manifest':manifest,'payload':str(payload)}
    exe=output/'CyrusScatter-0.87.1-Setup.exe';build_installer.build_exe(exe,packages,core)
    (output/'SHA256SUMS.txt').write_text(''.join(sha(path)+'  '+path.name+'\n' for path in [exe,*packages]))
    (output/'PACKAGE_RECEIPT.json').write_text(json.dumps({'version':'0.87.1','exe':str(exe),'exe_sha256':sha(exe),'hosts':evidence,'scope':'Source-matched build and archive verification. Runtime and owned-profile installer qualification are recorded separately. Analyzer/content remain independently versioned.'},indent=2)+'\n')
    print(json.dumps({'exe':str(exe),'sha256':sha(exe),'packages':[str(p) for p in packages]},indent=2))
if __name__=='__main__':main()
