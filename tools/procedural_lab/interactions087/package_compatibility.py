"""Package existing 0.87.0 features for three hosts; never runs tests or Max."""
from pathlib import Path
from types import SimpleNamespace
import hashlib,json,shutil,sys

ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'tools'))
import build_max
sys.path.insert(0,str(ROOT/'AminScatter/tools'))
import build_installer

WORK=ROOT/'build/interactions087-compatibility-20261025-01'
OUTPUT=ROOT/'dist/CyrusScatter-0.87.0-20261025-Compatibility'
PREVIOUS=ROOT/'dist/CyrusScatter-0.87.0-20261025-r4'
MAX2027=ROOT/'build/interactions087-release-20261025-06/AminScatter'
NAMES=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']

def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def main():
    assert build_max.scatter_version()=='0.87.0'
    OUTPUT.mkdir(exist_ok=False)
    core=MAX2027/'CyrusInstaller.dll'
    build_installer.verify_core(core)
    packages=[];builds={}
    for year in [2024,2026,2027]:
        native=MAX2027 if year==2027 else WORK/f'max{year}/AminScatter'
        receipt_path=native/'receipt.json'
        receipt=build_max.verify_native_receipt(receipt_path,'AminScatter',year,{n:native/n for n in NAMES})
        if year!=2027:
            assert receipt['tests_run'] is False and receipt['source_selection']['build_testing'] is False
            stage=WORK/f'package-stage-{year}'/'AminScatter';stage.mkdir(parents=True,exist_ok=False)
            for name in [*NAMES,'CyrusGallery.dll','CyrusGallery.build.json']:
                shutil.copy2(native/name,stage/name)
            for name in ['CyrusInstaller.dll','CyrusInstaller.build.json']:
                shutil.copy2(MAX2027/name,stage/name)
            args=SimpleNamespace(max_year=year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',
                output=OUTPUT,team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h',
                content_dir=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content',
                native_receipts={'AminScatter':receipt_path})
            build_max.package('AminScatter','Cyrus Scatter','0.87.0',NAMES,'AminScatterObject.ms',args,stage.parent)
        else:
            # Preserve the previously delivered/host-exercised 2027 archive exactly.
            for suffix in ['.mzp','.build.json','.sha256']:
                name='CyrusScatter-0.87.0-Max2027'+suffix
                shutil.copy2(PREVIOUS/name,OUTPUT/name)
        package=OUTPUT/f'CyrusScatter-0.87.0-Max{year}.mzp'
        packages.append(package)
        builds[str(year)]={'native_receipt':str(receipt_path),'native_receipt_sha256':sha(receipt_path),
            'native':{n:sha(native/n) for n in NAMES},'tests_run_in_this_request':False,
            'prior_tests_in_receipt':receipt['tests_run'],'scope':receipt['qualification']}
    exe=OUTPUT/'CyrusScatter-0.87.0-Setup.exe'
    build_installer.build_exe(exe,packages,core)
    result={'version':'0.87.0','max_years':[2024,2026,2027],'exe':str(exe),'exe_sha256':sha(exe),
        'scope':'Build/package only as requested. No new automated tests, Max launches, installer execution or artist profile changes. Max 2024/2026 payloads are built and untested; Max 2027 archive is byte-identical to the earlier r4 trial.',
        'analyzer':'Not bundled or changed; existing independent installation retained.',
        'content':'Reuses existing shared library; content remains independently versioned at 0.86.7.',
        'builds':builds,'packages':{p.name:sha(p) for p in packages}}
    (OUTPUT/'BUILD_ONLY_RECEIPT.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    (OUTPUT/'SHA256SUMS.txt').write_text(''.join(sha(p)+'  '+p.name+'\n' for p in [exe,*packages]),encoding='utf-8')
    (OUTPUT/'READ_ME.txt').write_text('CyrusScatter 0.87.0 — Max 2024, 2026 and 2027\n\nSave your work and close the target Max versions. Run CyrusScatter-0.87.0-Setup.exe, select the versions you want, and choose Install / Update. Reopen Max afterwards.\n\nBuild/package-only delivery requested by the user. No new tests, Max launches or installer execution were performed. Max 2024/2026 builds are untested. The 2027 package is unchanged from the prior r4 trial. Existing library and independent Analyzer installation are retained. Use saved scene copies for testing.\n',encoding='utf-8')
    print(json.dumps({'exe':str(exe),'sha256':sha(exe),'max_years':result['max_years'],'new_tests_run':False},indent=2))

if __name__=='__main__':main()
