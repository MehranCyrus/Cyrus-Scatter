"""Package a frozen 0.72 pair after offline and private-host qualification.

No installation, Max launch, artist profile writes or computer-use. Max 2026
packages are SDK-only candidates; Max 2027 must match the supplied receipts.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys
from types import SimpleNamespace
import zipfile

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from build_max import package,scatter_version


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--qualified',type=Path,required=True)
    parser.add_argument('--playback',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    host=args.qualified.resolve()
    assert host.parent==ROOT/'build/mcp-qualification'
    version=scatter_version()
    assert version=='0.72.0'
    identity=load(host/'launch.json')
    current_script=digest(ROOT/'AminScatter/scripts/AminScatterObject.ms')
    assert current_script==identity['script_sha256']
    controls=load(ROOT/'build/ui-072-20261006'/host.name.removeprefix('procedural07-ui-072-')/'receipt.json')
    assert controls['passed'] and controls['full'] and controls['script_sha256']==current_script
    idle=load(host/'idle-qualification.json')
    corona=load(host/'corona072-result.json')
    assert idle['passed'] and idle['integrated_sections_open'] and idle['launch_script_sha256']==current_script
    assert corona['passed'] and corona['script_sha256']==current_script
    assert load(host/'retained-ui-072.json')['zero_uploads']
    playback=load(args.playback/'receipt.json')
    assert playback['passed'] and playback['artist_profile_unchanged']
    assert playback['sources_and_binaries']['AminScatterObject.ms']==current_script
    packages={}
    for year in (2026,2027):
        staging=ROOT/'build/ui-072-20261006/package-payload'/str(year)
        modules={}
        for project,build in [('AminScatter',ROOT/f'build/ui-072-20261006/native-max{year}'),
                              ('CyrusSurfaceAnalyzer',ROOT/f'build/playback-20261006/analyzer-max{year}')]:
            receipt=load(build/'receipt.json')
            assert receipt.get('status')!='pending' and receipt['max_year']==year
            assert all(row['exit_code']==0 for row in receipt['stages'])
            for name,expected in receipt['sources'].items():
                assert digest(ROOT/name)==expected,'Build source changed: '+name
            for name,expected in receipt['binaries'].items():
                source=ROOT/name
                assert digest(source)==expected,name
                if year==2027:
                    assert identity['binaries'][source.name]==expected
                    assert playback['sources_and_binaries'][source.name]==expected
                destination=staging/project/source.name
                destination.parent.mkdir(parents=True,exist_ok=True)
                shutil.copy2(source,destination)
                modules[source.name]=expected
        output=args.output.resolve()/f'Max{year}'
        config=SimpleNamespace(max_year=year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=output)
        package('AminScatter','Cyrus Scatter',version,
                ['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh'],
                'AminScatterObject.ms',config,staging)
        package('CyrusSurfaceAnalyzer','Cyrus Surface Analyzer','0.14',
                ['CyrusSurfaceAnalyzer.dlx'],'CyrusSurfaceAnalyzer.ms',config,staging)
        rows={}
        for path in sorted(output.glob('*.mzp')):
            with zipfile.ZipFile(path) as archive:
                manifest=json.loads(archive.read('manifest.json'))
                assert manifest['max_year']==year
                assert set(archive.namelist())==set(manifest['files'])|{'manifest.json'}
                for name,expected in manifest['files'].items():
                    assert hashlib.sha256(archive.read(name)).hexdigest()==expected
                    if name in modules:assert expected==modules[name]
                if 'CyrusScatter.ms' in manifest['files']:
                    assert manifest['version']==version
                    assert manifest['files']['CyrusScatter.ms']==current_script
                for name in archive.namelist():
                    if name.endswith(('.ms','.mcr')):
                        assert b'__VERSION__' not in archive.read(name) and b'__NATIVE_ID__' not in archive.read(name)
                rows[path.name]=dict(sha256=digest(path),bytes=path.stat().st_size,manifest=manifest)
        record=dict(development_version='0.72',package_version=version,serialization=53,max_year=year,
                    script_sha256=current_script,normal_profile_installed=False,
                    max2027_runtime_qualified=year==2027,max2026_runtime_qualified=False,
                    computer_use=False,pointer_qualification=False,packages=rows,
                    qualification=host.name if year==2027 else 'SDK build/native executables only',
                    scope='Scatter and unchanged Analyzer dependency. MCP/Automation remains separate.')
        (output/'BUILD.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
        (output/'START_HERE.txt').write_text(
            f'Cyrus Scatter 0.72 (package {version}) - Max {year} development candidate\n\n'
            + ('Private Max 2027 API/control, idle, playback, retained and Corona lifecycle checks passed.\n'
               if year==2027 else 'SDK compilation and native tests passed. Max 2026 runtime is not qualified here.\n')
            + f'1. Save your work. Scripting > Run Script: CyrusScatter-{version}-Max{year}.mzp\n'
            + f'2. For Analyzer features/courtyard scenes: CyrusSurfaceAnalyzer-0.14-Max{year}.mzp\n'
            + '3. Close and restart Max before using the new script/native pair.\n'
            + '4. Select Scatter > Modify > Layer Manager > select a layer; its sections are below.\n'
            + '5. Edit layer in window... remains optional. Modify > Diagnostics records and saves local reports.\n\n'
            + 'No artist profile was installed by this campaign. Do not fileIn the new script with an older loaded DLL.\n'
            + 'No presented-FPS, pointer/DPI, successful docked-IR or publication-readiness claim is made.\n'
            + 'See docs/Integrated_UI_0.72_2026-10-06/RESULTS.md for scope and remaining gates.\n',encoding='utf-8')
        packages[str(year)]=record
    args.output.mkdir(parents=True,exist_ok=True)
    (args.output/'BUILD.json').write_text(json.dumps(packages,indent=2)+'\n',encoding='utf-8')
    print('PASS frozen package manifests/hashes: '+str(args.output))


if __name__=='__main__':main()
