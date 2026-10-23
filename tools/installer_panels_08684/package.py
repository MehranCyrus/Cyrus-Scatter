"""Package the qualified Max 2027 refinement pair without artist installation."""
from pathlib import Path
from types import SimpleNamespace
import hashlib
import json
import shutil
import sys
import zipfile

ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'build/installer-panels-08684-20261022'
NATIVE=WORK/'scatter-final02'
ANALYZER=ROOT/'build/refinement-08683-20261022/analyzer-final01'
OUTPUT=ROOT/'dist/CyrusScatter-0.86.8.4-20261022'
sys.path.insert(0,str(ROOT/'tools'))
import build_max
sys.path.insert(0,str(ROOT/'AminScatter/tools'))
import build_installer


def sha(path):
    with path.open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()


def verify_build(folder):
    receipt=json.loads((folder/'receipt.json').read_text(encoding='utf-8'))
    if receipt.get('max_year')!=2027 or not receipt.get('clean_compilation') or any(row['exit_code'] for row in receipt['stages']):
        raise ValueError('A passing Max 2027 build is required')
    for name,expected in {**receipt['sources'],**receipt['binaries']}.items():
        if sha(ROOT/name)!=expected:raise ValueError('Build identity differs: '+name)


def verify_archive(path):
    with zipfile.ZipFile(path) as archive:
        if archive.testzip() is not None:raise ValueError('Archive CRC failed')
        manifest=json.loads(archive.read('manifest.json'))
        if set(archive.namelist())!=set(manifest['files'])|{'manifest.json'}:raise ValueError('Unexpected package files')
        for name,digest in manifest['files'].items():
            if hashlib.sha256(archive.read(name)).hexdigest()!=digest:raise ValueError('Payload differs: '+name)
        if manifest['max_year']!=2027:raise ValueError('Wrong package host')
        if b'__' in archive.read('install.ms'):raise ValueError('Unexpanded installer token')
        if b'29000' not in archive.read('install.ms'):raise ValueError('Missing Max 2027 guard')
        return manifest


def main():
    for folder in (NATIVE,ANALYZER):verify_build(folder)
    build_installer.build(WORK/'CyrusInstaller.dll')
    stage=WORK/'package-final03';stage.mkdir(exist_ok=False)
    scatter=stage/'AminScatter';analyzer=stage/'CyrusSurfaceAnalyzer'
    scatter.mkdir();analyzer.mkdir()
    names=['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh']
    for name in names+['CyrusGallery.dll']:shutil.copy2(NATIVE/name,scatter/name)
    for name in ('CyrusInstaller.dll','CyrusInstaller.build.json'):shutil.copy2(WORK/name,scatter/name)
    shutil.copy2(ANALYZER/'CyrusSurfaceAnalyzer.dlx',analyzer/'CyrusSurfaceAnalyzer.dlx')
    args=SimpleNamespace(max_year=2027,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=OUTPUT,
        team_trust_header=ROOT/'CyrusLicensing/team/team_public_key.h',content_dir=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content')
    build_max.package('AminScatter','Cyrus Scatter','0.86.8.4',names,'AminScatterObject.ms',args,stage)
    build_max.package('CyrusSurfaceAnalyzer','Cyrus Surface Analyzer','0.14.1',['CyrusSurfaceAnalyzer.dlx'],'CyrusSurfaceAnalyzer.ms',args,stage)
    scatter_mzp=OUTPUT/'CyrusScatter-0.86.8.4-Max2027.mzp'
    analyzer_mzp=OUTPUT/'CyrusSurfaceAnalyzer-0.14.1-Max2027.mzp'
    manifests={p.name:verify_archive(p) for p in (scatter_mzp,analyzer_mzp)}
    exe=OUTPUT/'CyrusScatter-0.86.8.4-Setup.exe'
    build_installer.build_exe(exe,[scatter_mzp],WORK/'CyrusInstaller.dll')
    hashes={p.name:sha(p) for p in (scatter_mzp,analyzer_mzp,exe)}
    (OUTPUT/'SHA256SUMS.txt').write_text(''.join(h+'  '+n+'\n' for n,h in hashes.items()),encoding='utf-8')
    (WORK/'package-receipt.json').write_text(json.dumps({'max_year':2027,'artifacts':hashes,'manifests':manifests},indent=2)+'\n',encoding='utf-8')
    print(OUTPUT)


if __name__=='__main__':main()
