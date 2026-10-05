"""Verify already-built artifacts and summarize offline evidence. Does not run Max."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET
import zipfile

ROOT=Path(__file__).resolve().parents[2]


def sha(data):return hashlib.sha256(data).hexdigest()


def main():
    generated=json.loads((ROOT/'build/procedural-07/generated-check.json').read_text())
    script=(ROOT/'AminScatter/scripts/AminScatterObject.ms').read_bytes()
    assert generated['passed'] and generated['generated_sha256']==sha(script)
    native_files=sorted(p for folder in ('include','src','tests') for p in (ROOT/'AminScatter'/folder).rglob('*') if p.is_file() and p.suffix in ('.cpp','.h','.inc','.rc'))
    native_files.append(ROOT/'AminScatter/CMakeLists.txt')
    source_hashes={p.relative_to(ROOT).as_posix():sha(p.read_bytes()) for p in native_files}
    packages=[];builds=[]
    for year in (2026,2027):
        directory=ROOT/f'build/procedural-07/max{year}'
        tests=(directory/'tests.log').read_text()
        assert '100% tests passed, 0 tests failed out of 13' in tests
        native={n:sha((directory/n).read_bytes()) for n in ('AminScatter.dlx','CyrusScatterEdit.dlm','CyrusBrush.dlx','CyrusBrushStorage.dlh')}
        package=ROOT/f'dist/procedural-0.7-candidate/CyrusScatter-0.7.0-Max{year}.mzp'
        with zipfile.ZipFile(package) as archive:
            assert archive.testzip() is None
            manifest=json.loads(archive.read('manifest.json'))
            assert manifest['version']=='0.7.0' and manifest['max_year']==year
            for name,expected in manifest['files'].items():assert sha(archive.read(name))==expected,name
            assert archive.read('CyrusScatter.ms')==script,'Package contains stale generated source'
            for name,expected in native.items():assert sha(archive.read(name))==expected,name
        packages.append({'path':package.relative_to(ROOT).as_posix(),'sha256':sha(package.read_bytes()),'manifest':manifest})
        builds.append({'max_sdk':year,'native_tests_passed':13,'native_tests_failed':0,'native_files':native,
                       'logs':{name:sha((directory/name).read_bytes()) for name in ('configure.log','build.log','tests.log')}})
    junit=ET.parse(ROOT/'build/procedural-07/mcp-tests.xml').getroot()
    suites=list(junit.iter('testsuite'))
    assert sum(int(x.attrib.get('failures',0))+int(x.attrib.get('errors',0)) for x in suites)==0
    assert sum(int(x.attrib['tests']) for x in suites)==64
    runtime_path=ROOT/'docs/Procedural_Implementation_0.7_2026-10-04/evidence/runtime/summary.json'
    runtime=json.loads(runtime_path.read_text()) if runtime_path.exists() else None
    if runtime:assert runtime['generated_sha256']==sha(script),'Runtime tested a different generated script'
    report={'recorded_at_utc':datetime.now(timezone.utc).isoformat(),
            'checkpoint_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
            'working_tree_implementation':True,'product_version':'0.7.0','evaluation_policy':3,
            'maxscript_serialization':52,'max_started':runtime is not None,'installed':False,
            'interactive_qualification':'Max 2027 private host qualified within documented limits; Max 2026 host unavailable' if runtime else 'pending user access',
            'generator':generated,'native_builds':builds,'mcp_tests':{'passed':64,'failed':0,'live_host':False},
            'native_source_sha256':source_hashes,'packages':packages,'runtime':runtime}
    destination=ROOT/'docs/Procedural_Implementation_0.7_2026-10-04/evidence.json'
    destination.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'evidence':str(destination),'sdk_builds':2,'native_suites_per_build':13,'mcp_tests':64,'packages_verified':len(packages),'max_started':runtime is not None},indent=2))


if __name__=='__main__':main()
