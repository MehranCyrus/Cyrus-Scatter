"""Curate assertions and verify release payload identity, without scene assets/secrets."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import xml.etree.ElementTree as ET
import zipfile
from build import ROOT, BASE


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    release=BASE/'hosts/layers-first-release'
    reopened=BASE/'hosts/layers-first-reopened'
    beta=BASE/'hosts/layers-first-beta'
    mcp=ROOT/'build/mcp-qualification/layers-first-final'
    output=ROOT/'docs/Layers_First_2026-10-03/evidence'
    output.mkdir(parents=True,exist_ok=True)
    records={}
    def copy(path,name):
        destination=output/name
        destination.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(path,destination)
        records[name]={"source":path.relative_to(ROOT).as_posix(),"sha256":sha(destination)}
    for name in ('planting-groups-acceptance.json','planting-output-acceptance.json','planting-advanced-acceptance.json',
                 'layers-first-acceptance.json','layers-features.json','navigation-acceptance.json','navigation-all-modes.json',
                 'render-acceptance.json','layers-demo.json','layers-native-brush.json','layers-set-picker.json','loaded-identity.json'):
        copy(release/name,name)
    copy(release/'screenshots/layers-and-sets.png','screenshots/layers-and-sets.png')
    for name in ('layers-reopen-acceptance.json','layers-legacy-acceptance.json','uninstall-acceptance.json'):
        copy(reopened/name,name)
    for name in ('layers-native-clicks.json','installer-acceptance.json'):
        copy(beta/name,name)
    for name in ('cycles.json','layers-v2.json','scenarios.json','refinement-recovery.json','stdio-acceptance.json',
                 'boundaries.json','retained.json','inspection.json','budget-generation.json','release-campaign.json','logical-inspection.json'):
        copy(mcp/name,'mcp/'+name)
    xml=BASE/'layers-python-tests.xml'
    suites=ET.parse(xml).getroot().findall('testsuite')
    assert sum(int(s.get('tests',0)) for s in suites)==75
    assert not any(int(s.get(k,0)) for s in suites for k in ('failures','errors','skipped'))
    copy(xml,'python-tests.xml')
    packages={}
    installed=json.loads((release/'scripts/CyrusScatter/manifest.json').read_text())
    loaded=json.loads((release/'loaded-identity.json').read_text())
    assert loaded['script_version']=='1.2.0'
    for name,path in loaded['modules']:
        assert sha(Path(path))==installed['files'][name]
    assert sha(release/'scripts/CyrusScatter/CyrusScatter.ms')==installed['files']['CyrusScatter.ms']
    for year in (2026,2027):
        native=BASE/f'max{year}'
        assert '100% tests passed, 0 tests failed out of 12' in (native/'build-2.log').read_text()
        for name in ('build-0.log','build-1.log','build-2.log','identity.json'):
            copy(native/name,f'max{year}/'+name)
        package=ROOT/f'dist/layers-first-1.2.0/CyrusScatter-1.2.0-Max{year}.mzp'
        with zipfile.ZipFile(package) as archive:
            manifest=json.loads(archive.read('manifest.json'))
            for name,value in manifest['files'].items():
                assert hashlib.sha256(archive.read(name)).hexdigest()==value,name
            for name in ('AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh'):
                assert sha(native/name)==manifest['files'][name]
            assert sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')==manifest['files']['CyrusScatter.ms']
        differences=[]
        if year==2027:
            differences=[name for name,value in manifest['files'].items() if installed['files'].get(name)!=value]
            assert set(differences)<= {'INSTALL.txt'},differences
        (output/f'max{year}/package-manifest.json').write_text(json.dumps(manifest,indent=2))
        packages[str(year)]={"sha256":sha(package),"native_id":manifest['native_id'],"changes_since_installed_runtime_test":differences}
    mcp_package=ROOT/'dist/layers-first-1.2.0/Cyrus-MCP-1.1.0'
    mcp_manifest=json.loads((mcp_package/'package-manifest.json').read_text())
    mcp_installed=ROOT/'build/mcp-install-layers-first'/mcp_manifest['build_id']
    for entry in mcp_manifest['files']:
        assert sha(mcp_package/entry['path'])==entry['sha256']
        if entry['path'].startswith('host/'):
            assert sha(mcp_installed/entry['path'])==entry['sha256']
            assert sha(ROOT/'CyrusMCP'/entry['path'].removeprefix('host/'))==entry['sha256']
    copy(mcp_package/'package-manifest.json','mcp/package-manifest.json')
    paths=subprocess.check_output(['git','ls-files','-co','--exclude-standard','AminScatter','CyrusMCP','tools/v1','tools/mcp','tools/build_max.py'],cwd=ROOT,text=True).splitlines()
    hashes={p:sha(ROOT/p) for p in sorted(set(paths)) if (ROOT/p).is_file()}
    record={"recorded_date":"2026-10-04","scatter_version":"1.2.0","mcp_version":"1.1.0","source_base_commit":subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
            "working_tree_sources_sha256":hashes,"results":records,"packages":packages,"mcp_build_id":mcp_manifest['build_id'],
            "demo_sha256":sha(release/'Cyrus_Scatter_1.2_Layers_Demo.max'),"runtime":"3ds Max 2027.1",
            "limits":["Max 2026 SDK/native tests only","Synchronous navigation timings are not FPS","Scanline synthetic render only","Private fixture approval is test-only; shipped MCP still requires local artist approval"]}
    (output/'MANIFEST.json').write_text(json.dumps(record,indent=2)+'\n')
    print(f'Verified {len(records)} evidence files and {len(hashes)} source files; both MZPs and installed MCP payloads match')


if __name__=='__main__':main()
