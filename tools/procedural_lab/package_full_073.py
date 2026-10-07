"""Package a frozen pair using explicit, current qualification receipts.

No Max launch, artist installation, scene changes or Git operations. A manifest
selects the evidence; old version captions or unrelated passing runs do not.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path
import shutil
import sys
from types import SimpleNamespace
import xml.etree.ElementTree as ET
import zipfile

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools'))
from build_max import package,scatter_version

def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def load(path):return json.loads(Path(path).read_text(encoding='utf-8-sig'))
def require(value,message):
    if not value:raise RuntimeError(message)
def rooted(path):
    result=(ROOT/path).resolve()
    require(result.is_relative_to(ROOT),'Workspace evidence required')
    return result

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args();config=load(args.manifest)
    script=digest(ROOT/'AminScatter/scripts/AminScatterObject.ms')
    require(scatter_version()=='0.73.0','Current version is not 0.73.0')
    native={}
    for year in (2026,2027):
        for project in ('scatter','analyzer'):
            path=rooted(config['native'][str(year)][project])/'receipt.json';receipt=load(path)
            require(receipt.get('status')!='pending' and receipt['project']==project and receipt['max_year']==year,'Wrong native build receipt')
            require(len(receipt['stages'])==3 and all(row['exit_code']==0 for row in receipt['stages']),'Native tests/build failed')
            for name,expected in {**receipt['sources'],**receipt['binaries']}.items():
                require(digest(ROOT/name)==expected,'Build source/binary changed: '+name)
            native[year,project]=receipt
    campaigns={}
    for name,path in config['campaigns'].items():
        folder=rooted(path);receipt=load(folder/'qualification.json')
        require(receipt['passed'] and receipt['owned_process_stopped'] and receipt['installed_product_files_unchanged'],'Host campaign failed or remains running: '+name)
        require(receipt['launch']['script_sha256']==script,'Host script differs: '+name)
        for path,expected in native[2027,'scatter']['binaries'].items():
            require(receipt['launch']['binaries'][Path(path).name]==expected,'Loaded native pair differs: '+name)
        for path,expected in receipt['fixtures'].items():require(digest(ROOT/path)==expected,'Fixture changed: '+path)
        require(all(row['result'].startswith('SUCCESS ') for row in receipt['probes']),'Host probe failed: '+name)
        if 'external_fixture' in receipt:
            row=receipt['external_fixture'];require(digest(row['path'])==row['sha256'],'External client changed')
        if name.startswith('mcp'):
            require(receipt['host_python_sources_unchanged'],'Host Python changed during test')
            for path,expected in receipt['host_python_sources'].items():require(digest(ROOT/path)==expected,'MCP source changed: '+path)
        campaigns[name]=dict(folder=folder.relative_to(ROOT).as_posix(),sha256=digest(folder/'qualification.json'))
    paths={name:rooted(path) for name,path in config['campaigns'].items()}
    core=paths['core']
    require(len(load(core/'qualification.json')['probes'])==8,'Expected eight integrated core probes')
    require(load(core/'core073.json')['complete'] and load(core/'approved-layout073.json')['passed'],'Core/layout failed')
    for name in ('ports073.json','containers073.json','groups073.json','node-move073.json','persistence073.json','analyzer-assignment073.json'):
        require(bool(load(core/name)),'Core result missing: '+name)
    for path,expected in native[2027,'analyzer']['binaries'].items():
        for name in ('core','playback'):
            require(load(paths[name]/'qualification.json')['launch']['binaries'][Path(path).name]==expected,'Analyzer loaded identity differs')
    idle=load(paths['idle']/'idle-qualification.json')
    require(idle['passed'] and idle['integrated_sections_open'] and len(idle['cases'])==8 and all(not row['unexpected_changes'] for row in idle['cases']),'Idle failed')
    payload=re.search(r'global CyrusLoadedScriptFingerprint="([0-9a-f]{64})"',(ROOT/'AminScatter/scripts/AminScatterObject.ms').read_text()).group(1)
    require(idle['launch_script_sha256']==script and idle['loaded_payload_sha256']==payload,'Idle loaded script differs')
    require('SUCCESS 942 assertions' in (paths['playback']/'result.txt').read_text(),'Playback regression failed')
    selection=load(paths['selection']/'container-selection073.json')
    require(selection['passed'] and selection['natural_mount'] and not selection['router_errors'] and selection['explicit_positive_mount_calls']==0,'Natural container mount failed')
    require(selection['reopen'] and selection['unchanged_calculation_and_buffers'] and len(selection['checks'])>=10 and all(row[1] for row in selection['checks']),'Container selection/reopen failed')
    require(load(paths['mcp_direct']/'mcp073.json')['passed'],'MCP direct failed')
    panel=load(paths['mcp_panel']/'panel-runtime-result.json')
    require(panel['passed'] and panel['plan_schema']=='0.73' and panel['retired_schemas_rejected'] and panel['save_reopen']['match'] and panel['save_reopen']['scope_cleared'],'MCP panel failed')
    require(load(paths['corona_mock']/'corona-stop-073.json')['passed'],'Corona stop failure probes failed')
    retired=load(paths['retirement']/'retirement073.json')
    require(retired['passed'] and retired['denied_controllers']>0 and all(retired[k] for k in ('original_unchanged','copy_denied','resave_output_denied')),'Old unpublished schema denial failed')
    real=rooted(config['real_host']);protection=load(real/'protection.json')
    require(all(protection[k] for k in ('owned_process_stopped','original_scene_unchanged','installed_product_files_unchanged')),'Real host protection failed')
    require(load(real/'launch.json')['script_sha256']==script,'Real host script differs')
    for path,expected in native[2027,'scatter']['binaries'].items():
        require(load(real/'launch.json')['binaries'][Path(path).name]==expected,'Real host native differs')
    pointer=load(real/'pointer-container-movement.json')
    require(pointer['passed'] and pointer['undo_passed'] and pointer['redo_passed'],'Actual pointer Move/Undo/Redo failed')
    require(load(real/'pointer-ui-qualification.json')['passed'],'Actual native re-selection/layout rerun failed')
    brush=load(real/'pointer-brush-after.json');undo=load(real/'pointer-brush-undo.json')
    require(brush['manual_calculation_unchanged'] and brush['history_after']==brush['history_before']+1 and brush['stroke_samples']>1 and undo['passed'],'Actual Brush/Undo rerun failed')
    for name in (config['navigation_report'],config['playback_report'],config['enabled_report'],'real-corona-qualification.json'):
        row=load(real/name);require(row['passed'] and row['script_sha256']==script,'Real qualification failed: '+name)
    enabled=load(real/config['enabled_report'])['phases']
    require(len(enabled)==2 and not enabled[0]['controller_enabled'] and enabled[1]['controller_enabled'],'Actual controller enable baseline missing')
    require(load(real/'saved-stress-100k.json')['accepted']==[100000],'100k population missing')
    generated=load(rooted(config['offline'])/'generated-check.json')
    require(generated['passed'] and generated['generated_sha256']==script and generated['fixture_delimiters_checked']>=19,'Generator check failed')
    suites=list(ET.parse(rooted(config['offline'])/'python-tests.xml').getroot().iter('testsuite'))
    require(suites and sum(int(s.attrib['tests']) for s in suites)>=141 and all(int(s.attrib.get(k,0))==0 for s in suites for k in ('failures','errors','skipped')),'Python tests failed')
    output=args.output.resolve()
    require(output.is_relative_to(ROOT/'dist') and not (output/'BUILD.json').exists() and all(not (output/f'Max{year}').exists() for year in (2026,2027)),'Use fresh native package destinations')
    record=dict(development_version='0.73',version='0.73.0',serialization=54,calculation_model='CyrusUnified1',script_sha256=script,
                campaigns=campaigns,real_host=real.relative_to(ROOT).as_posix(),installed=False,pushed=False,
                pointer_scope='Final real two-column captions, disclosures, scrolling, retargeting, Brush/Undo and controlled whole-node source Move/Undo/Redo in isolated Max 2027. Automated narrow/wide dimensions; not all pointer controls/DPI',
                real_IR_scope='Real garden, floating Corona 15 IR idle/edit/stop and four-pass production. Seven Missing_TextureMap placeholders limit source-material fidelity',
                measurement_limits='Real 100k mixed sources; Mesh triangle budget displays 839 plants. Whole-host RAM/VRAM and limited PresentMon phases, no unlimited FPS claim.',
                unresolved_findings=['First cold container Undo/Redo lost its stack; controlled repeat passed. Cause remains unisolated; see retained failing receipt and roadmap.'],
                publication_ready=False,packages={})
    for year in (2026,2027):
        staging=rooted(config['offline'])/'package-payload'/str(year);modules={}
        for project,tool in (('AminScatter','scatter'),('CyrusSurfaceAnalyzer','analyzer')):
            for path,expected in native[year,tool]['binaries'].items():
                source=ROOT/path;destination=staging/project/source.name
                destination.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,destination);modules[source.name]=expected
        settings=SimpleNamespace(max_year=year,tools_version='14.38.33130',windows_sdk='10.0.19041.0',output=output/f'Max{year}')
        package('AminScatter','Cyrus Scatter','0.73.0',['AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh'],'AminScatterObject.ms',settings,staging)
        package('CyrusSurfaceAnalyzer','Cyrus Surface Analyzer','0.14',['CyrusSurfaceAnalyzer.dlx'],'CyrusSurfaceAnalyzer.ms',settings,staging)
        rows={}
        for path in sorted(settings.output.glob('*.mzp')):
            with zipfile.ZipFile(path) as archive:
                manifest=load_json_bytes(archive.read('manifest.json'))
                require(manifest['max_year']==year and set(archive.namelist())==set(manifest['files'])|{'manifest.json'},'Archive entries differ')
                for name,expected in manifest['files'].items():
                    require(hashlib.sha256(archive.read(name)).hexdigest()==expected,'Archive hash differs')
                    if name in modules:require(expected==modules[name],'Archive native differs')
                if 'CyrusScatter.ms' in manifest['files']:
                    require(manifest['files']['CyrusScatter.ms']==script and b'Layers & paint sets' in archive.read('INSTALL.txt'),'Archive script/guide differs')
                for name in archive.namelist():
                    if name.endswith(('.ms','.mcr')):
                        for token in (b'__VERSION__',b'__NATIVE_ID__',b'dev-request',b'CSRuntimePanel'):
                            require(token not in archive.read(name),'Private/unexpanded installer content')
            rows[path.name]=dict(sha256=digest(path),bytes=path.stat().st_size,manifest=manifest)
        record['packages'][str(year)]=dict(runtime_qualified=year==2027,qualification='Controlled isolated Max 2027 campaigns pass; first cold pointer Undo history remains open' if year==2027 else 'SDK/native tests only; Max 2026 runtime unqualified',files=rows)
        (settings.output/'START_HERE.txt').write_text(
            f'Cyrus Scatter 0.73.0 approved layout - Max {year}\n\n'
            +'Save your work. Run the Scatter MZP, then restart Max before opening a new 0.73 scene.\n'
            +'Run the matching Analyzer MZP for Analyzer features. New script and old loaded DLLs must not be mixed.\n'
            +'Workflow and results: docs/Full_Qualification_0.73_2026-10-07/README.md\n'
            +'Max 2026 is SDK-only; runtime/pointer/render tests were on Max 2027.\n'
            +'Heavy Proxy drawing and long/DPI/docked-IR sessions remain qualification work.\n'
            +'The first cold container Undo lost its stack in one repeated scenario; controlled repeats pass. Development test copies only; see RESULTS.md.\n'
            +'No artist installation, Git commit or push was performed.\n',encoding='utf-8')
    (output/'BUILD.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
    print('PASS frozen native package manifests and source/evidence: '+str(output))

def load_json_bytes(data):return json.loads(data.decode('utf-8-sig'))
if __name__=='__main__':main()
