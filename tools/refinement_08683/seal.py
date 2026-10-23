"""Seal the exact Max 2027 test delivery; never closes broader roadmap gates."""
from pathlib import Path
import hashlib
import json
import sys
import zipfile

ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'build/refinement-08683-20261022'
OUTPUT=ROOT/'dist/CyrusScatter-0.86.8.3-20261022'
sys.path.insert(0,str(ROOT/'tools/quality_validation'))
from results import Expected,read_result


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def evidence(path):return {'path':path.relative_to(ROOT).as_posix(),'sha256':sha(path)}


def main():
    builds=[]
    for directory in ('scatter-final04','analyzer-final01'):
        path=WORK/directory/'receipt.json';receipt=json.loads(path.read_text())
        assert receipt['max_year']==2027 and receipt['clean_compilation']
        assert all(stage['exit_code']==0 for stage in receipt['stages'])
        assert not receipt.get('preview_fault_lab') and not receipt.get('placement_qualification')
        for name,digest in {**receipt['sources'],**receipt['binaries']}.items():assert sha(ROOT/name)==digest,name
        builds.append(evidence(path))
    host=WORK/'host-final04';metadata=json.loads((host/'qualification.json').read_text())
    for name,path in metadata['paths'].items():assert sha(Path(path))==metadata['hashes'][name],name
    required=['R3-M01','R6-M06','R6-M07','R6-M01','R6-M02','R6-M03','R6-M04','R6-M05','R6-M08','R6-M09','R6-M10','R6-M11',
              'R2-M01','R2-M04','R2-M06','R3-M03','R3-M06','R3-M08','R3-M09','R3-M10','R1-M02','R1-M03','R1-M06','R1-M08',
              'R4-M01','R4-M02','R4-M04','R4-M05','R4-M07','R4-M08','R4-M09','R4-M10','R4-M11','R4-M12','R4-M13','R4-M14','R4-M15',
              'R5-M02','R5-M06','R4-M12-UPGRADE','R1-M10']
    completed={}
    for request in host.glob('request-*.json'):
        data=json.loads(request.read_text())
        if data['run_id']!=metadata['run_id'] or data['artifact_id']!=metadata['artifact_id']:continue
        expected=Expected(data['run_id'],data['request_id'],data['scenario_id'],data['artifact_id'],tuple(data['assertions']))
        result=host/('result-'+expected.request_id+'.json')
        read_result(result,expected);completed[expected.scenario_id]=evidence(result)
    assert set(required)<=set(completed),'Missing final artifact scenarios: '+str(set(required)-set(completed))
    packages={}
    for filename in ('CyrusScatter-0.86.8.3-Max2027.mzp','CyrusSurfaceAnalyzer-0.14.1-Max2027.mzp'):
        path=OUTPUT/filename
        with zipfile.ZipFile(path) as archive:
            assert archive.testzip() is None
            manifest=json.loads(archive.read('manifest.json'));assert manifest['max_year']==2027
            assert set(archive.namelist())==set(manifest['files'])|{'manifest.json'}
            for name,digest in manifest['files'].items():assert hashlib.sha256(archive.read(name)).hexdigest()==digest,name
            if filename.startswith('CyrusScatter-'):
                for name in ('AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm','CyrusGallery.dll'):
                    assert manifest['files'][name]==metadata['hashes'][name],name
                assert manifest['files']['CyrusScatter.ms']==metadata['hashes']['Scatter']
                assert 'Clipper2-NOTICE.txt' in manifest['files']
                assert manifest['files']['CyrusInstaller.dll']==sha(WORK/'CyrusInstaller.dll')
            else:
                assert manifest['files']['CyrusSurfaceAnalyzer.dlx']==metadata['hashes']['CyrusSurfaceAnalyzer.dlx']
                assert manifest['files']['CyrusSurfaceAnalyzer.ms']==metadata['hashes']['AnalyzerScript']
        packages[filename]=evidence(path)
    setup=WORK/'CyrusInstaller.build.json';setup_receipt=json.loads(setup.read_text())
    assert setup_receipt['source_sha256']==sha(ROOT/'AminScatter/setup/InstallEngine.cs')
    assert setup_receipt['artifact_sha256']==sha(WORK/'CyrusInstaller.dll')
    core=WORK/'installer-core-final06/receipt.json';core_receipt=json.loads(core.read_text())
    assert core_receipt['status']=='passed' and core_receipt['max_year']==2027
    assert core_receipt['package_sha256']==packages['CyrusScatter-0.86.8.3-Max2027.mzp']['sha256']
    install_reports=[json.loads(p.read_text()) for p in host.glob('installer-*.json')]
    assert any(r.get('status')=='passed' and r['package_sha256']==packages['CyrusSurfaceAnalyzer-0.14.1-Max2027.mzp']['sha256'] for r in install_reports)
    assert '190 passed' in (WORK/'python-seal.log').read_text(encoding='utf-8-sig')
    exe=OUTPUT/'CyrusScatter-0.86.8.3-Setup.exe';packages[exe.name]=evidence(exe)
    result={'status':'Max 2027 test delivery; scoped qualification, not full matrix completion',
            'scatter_version':'0.86.8.3','analyzer_version':'0.14.1','schema':59,'recipe':8,'max_year':2027,
            'native_test_count':51,'python_test_count':190,'final_artifact_scenarios':len(required),
            'builds':builds,'host':evidence(host/'qualification.json'),'loaded':evidence(host/'loaded.tsv'),
            'scenarios':{name:completed[name] for name in required},'packages':packages,
            'installer_core':evidence(core),'installer_build':evidence(setup),
            'preserved_paint':True,'artist_installation':False,'artist_restart':False,'git_commit_push':False,'website_deployment':False,
            'remaining':['full physical picking/brush focus and DPI','sustained artist-scene/resource soaks',
                         'all commit-tail/observer fault subcases','full production renderer/Particle Flow matrix',
                         'full unsupported/missing shader matrix','older Max host qualification'],
            'seal_driver_sha256':sha(Path(__file__))}
    (WORK/'delivery-seal.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({'status':result['status'],'native_tests':51,'python_tests':190,'final_artifact_scenarios':len(required),'packages':{n:p['sha256'] for n,p in packages.items()}},indent=2))


if __name__=='__main__':main()
