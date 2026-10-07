"""Package the frozen unified pair after matching offline/private-host evidence.

Never installs or launches Max. 2026 is an SDK-only candidate, not runtime
qualification. Closed MCP wheels are packaged separately after its host tests.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys
from types import SimpleNamespace
import zipfile
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from build_max import package,scatter_version


def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def load(path):return json.loads(path.read_text(encoding='utf-8-sig'))


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    campaign_names=('core','ui','playback','navigation','mcp_direct','mcp_panel','analyzer_assignment','retirement','selection')
    for name in campaign_names:
        parser.add_argument('--'+name.replace('_','-'),type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    build=ROOT/'build/unified-073-20261006'
    script=digest(ROOT/'AminScatter/scripts/AminScatterObject.ms')
    assert scatter_version()=='0.73.0'
    native={}
    for year in (2026,2027):
        for project in ('scatter','analyzer'):
            receipt=load(build/f'{"native" if project=="scatter" else "analyzer"}-max{year}'/'receipt.json')
            assert receipt['project']==project and receipt['max_year']==year
            assert receipt.get('status')!='pending' and len(receipt['stages'])==3
            assert all(row['exit_code']==0 for row in receipt['stages'])
            for name,expected in {**receipt['sources'],**receipt['binaries']}.items():
                assert digest(ROOT/name)==expected,'Build source/binary changed: '+name
            native[year,project]=receipt
    qualifications={}
    for name in campaign_names:
        folder=getattr(args,name).resolve()
        assert folder.parent==ROOT/'build/mcp-qualification'
        receipt=load(folder/'qualification.json')
        assert receipt['passed'] and receipt['owned_process_stopped']
        assert receipt['installed_product_files_unchanged'] and not receipt['computer_use']
        assert receipt['launch']['script_sha256']==script
        for path,expected in native[2027,'scatter']['binaries'].items():
            assert receipt['launch']['binaries'][Path(path).name]==expected
        for path,expected in receipt['fixtures'].items():
            assert digest(ROOT/path)==expected,'Host fixture changed: '+path
        if 'external_fixture' in receipt:
            client=receipt['external_fixture']
            assert digest(Path(client['path']))==client['sha256'],'External host client changed'
        assert receipt['probes'] and all(row['result'].startswith('SUCCESS ') for row in receipt['probes'])
        qualifications[name]=dict(folder=folder.name,receipt_sha256=digest(folder/'qualification.json'))
    assert len(load(args.core/'qualification.json')['probes'])==5
    assert load(args.core/'core073.json')['complete']
    for name in ('containers','ports','groups','persistence'):
        assert load(args.core/(name+'073.json'))
    assert load(args.ui/'ui073-acceptance.json')['passed']
    idle=load(args.ui/'idle-qualification.json')
    assert idle['passed'] and idle['integrated_sections_open'] and len(idle['cases'])==8
    assert idle['launch_script_sha256']==script and all(not row['unexpected_changes'] for row in idle['cases'])
    corona=load(args.ui/'corona-stop-073.json')
    assert corona['passed'] and corona['mocked_lifecycle_cases']==8 and not corona['real_IR_qualified']
    result=(args.playback/'result.txt').read_text(encoding='utf-8')
    assert 'SUCCESS 942 assertions' in result
    for name in ('playback','analyzer_assignment'):
        launched=load(getattr(args,name)/'qualification.json')['launch']['binaries']
        for path,expected in native[2027,'analyzer']['binaries'].items():assert launched[Path(path).name]==expected
    nav=load(args.navigation/'unified073-final-100k-navigation.json')
    assert nav['population']==100000 and len(nav['trials'])==5
    for trial in nav['trials']:
        row=dict(trial)
        assert row['zero_rebuilds'] and row['zero_brush_work'] and row['generated']==100000
    assert load(args.mcp_direct/'mcp073.json')['passed']
    for name in ('mcp_direct','mcp_panel'):
        host=load(getattr(args,name)/'qualification.json')
        assert host['host_python_sources_unchanged']
        for path,expected in host['host_python_sources'].items():assert digest(ROOT/path)==expected,path
    panel=load(args.mcp_panel/'panel-runtime-result.json')
    assert panel['passed'] and panel['plan_schema']=='0.73' and panel['retired_schemas_rejected']
    assert panel['save_reopen']['match'] and panel['save_reopen']['scope_cleared']
    assert load(args.analyzer_assignment/'analyzer-assignment073.json')['analyzer_assignment']
    retired=load(args.retirement/'retirement073.json')
    assert retired['passed'] and retired['denied_controllers']>0
    assert all(retired[key] for key in ('copy_denied','resave_output_denied','original_unchanged'))
    selection=load(args.selection/'container-selection073.json')
    assert selection['passed'] and selection['natural_mount'] and selection['router_errors']==0
    assert selection['explicit_positive_mount_calls']==0 and selection['closed_timer_negative_probe']
    assert selection['unchanged_calculation_and_buffers'] and selection['reopen']
    assert len(selection['checks'])>=10 and all(row[1] for row in selection['checks'])
    generated=load(build/'generated-check.json')
    assert generated['passed'] and generated['generated_sha256']==script
    assert generated['fixture_delimiters_checked']==14
    tests=ET.parse(build/'python-tests.xml').getroot()
    suites=list(tests.iter('testsuite'))
    assert suites and sum(int(s.attrib['tests']) for s in suites)==141
    assert all(int(s.attrib.get(k,0))==0 for s in suites for k in ('failures','errors','skipped'))
    args.output=args.output.resolve()
    assert args.output.is_relative_to(ROOT/'dist'),'Dist destination required'
    assert not (args.output/'BUILD.json').exists() and all(not (args.output/f'Max{year}').exists() for year in (2026,2027)),'Fresh native package destinations required'
    packages={}
    for year in (2026,2027):
        staging=build/'package-payload'/str(year)
        modules={}
        for project,tool in (('AminScatter','scatter'),('CyrusSurfaceAnalyzer','analyzer')):
            for path,expected in native[year,tool]['binaries'].items():
                source=ROOT/path;destination=staging/project/source.name
                destination.parent.mkdir(parents=True,exist_ok=True)
                shutil.copy2(source,destination);modules[source.name]=expected
        output=args.output/f'Max{year}'
        config=SimpleNamespace(max_year=year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=output)
        package('AminScatter','Cyrus Scatter','0.73.0',
                ['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh'],
                'AminScatterObject.ms',config,staging)
        package('CyrusSurfaceAnalyzer','Cyrus Surface Analyzer','0.14',['CyrusSurfaceAnalyzer.dlx'],
                'CyrusSurfaceAnalyzer.ms',config,staging)
        rows={}
        for path in sorted(output.glob('*.mzp')):
            with zipfile.ZipFile(path) as archive:
                manifest=json.loads(archive.read('manifest.json'))
                assert manifest['max_year']==year and set(archive.namelist())==set(manifest['files'])|{'manifest.json'}
                for name,expected in manifest['files'].items():
                    assert hashlib.sha256(archive.read(name)).hexdigest()==expected
                    if name in modules:assert expected==modules[name]
                if 'CyrusScatter.ms' in manifest['files']:
                    assert manifest['version']=='0.73.0' and manifest['files']['CyrusScatter.ms']==script
                    guide=archive.read('INSTALL.txt')
                    assert b'CyrusUnified1' in guide and b'explicit opt-in' not in guide
                for name in archive.namelist():
                    if name.endswith(('.ms','.mcr')):
                        assert b'__VERSION__' not in archive.read(name) and b'__NATIVE_ID__' not in archive.read(name)
                        assert b'dev-request' not in archive.read(name) and b'CSRuntimePanel' not in archive.read(name)
                rows[path.name]=dict(sha256=digest(path),bytes=path.stat().st_size,manifest=manifest)
        record=dict(development_version='0.73',package_version='0.73.0',serialization=54,
                    calculation_model='CyrusUnified1',max_year=year,script_sha256=script,
                    installed=False,computer_use=False,max2027_scripted_runtime_qualified=year==2027,
                    max2026_runtime_qualified=False,pointer_qualified=False,real_IR_qualified=False,
                    correction='Container rollout startup/closed-handler lifecycle; same 0.73 schema and native binaries',
                    qualifications=qualifications if year==2027 else 'SDK build/native tests only',packages=rows)
        (output/'BUILD.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
        (output/'START_HERE.txt').write_text(
            f'Cyrus Scatter 0.73 - Max {year} development candidate\n\n'
            + ('Matching private Max 2027 API/control, idle, playback, container, MCP and 100k cache checks passed.\n'
               if year==2027 else 'SDK build/native tests passed. Max 2026 runtime remains unqualified.\n')
            + f'1. Save your work; Scripting > Run Script: CyrusScatter-0.73.0-Max{year}.mzp\n'
            + f'2. For Analyzer features: CyrusSurfaceAnalyzer-0.14-Max{year}.mzp\n'
            + '3. Close and restart Max before using this script/native pair.\n'
            + '4. Current serialization-54/0.73 scenes remain supported by this corrective build.\n'
            + '   For older unpublished Scatter/Edit scenes/plans, create a fresh Scatter setup.\n'
            + '   Max may open ordinary geometry from an older scene; retired Scatter records stay blocked, including after re-save.\n'
            + '5. Select a layer in Modify > Layer Manager. Create rectangle in Source containers.\n'
            + '6. Selecting the container exposes its linked Scatter context; parked models keep settings.\n\n'
            + 'No artist installation was performed. Do not fileIn the new script over older loaded DLLs.\n'
            + 'No presented-FPS, pointer/DPI, real Corona IR or publication-readiness claim.\n'
            + 'Documentation: docs/Unified_System_0.73_2026-10-06/README.md\n',encoding='utf-8')
        packages[str(year)]=record
    (args.output/'BUILD.json').write_text(json.dumps(packages,indent=2)+'\n',encoding='utf-8')
    print('PASS matching package manifests/hashes: '+str(args.output))


if __name__=='__main__':main()
