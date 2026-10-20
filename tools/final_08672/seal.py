"""Verify the delivered archives against compiled sources and loaded host pairs."""
from pathlib import Path
import hashlib, json, re, zipfile
ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'build/final-08672-20261020'
DIST=ROOT/'dist/CyrusScatter-0.86.7.2-20261020'
def sha(path):
    with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
record={'version':'0.86.7.2','status':'passed','artifacts':{},'evidence':{},
        'artist_profiles_modified':False,'native_rebuilt':True,'assets_regenerated':False,
        'temporary_test_library_retained':'Recursive deletion rejected by automatic approval review; reused instead of duplicating.'}
def receipt(path):
    text=path.read_text(encoding='utf-8-sig')
    assert 'SUCCESS' in text and 'FAIL:' not in text and not re.search(r'^ERROR',text,re.M),path
    record['evidence'][str(path.relative_to(ROOT))]=sha(path)
exe=DIST/'CyrusScatter-0.86.7.2-Setup.exe'
buildpath=exe.with_suffix('.build.json')
if not buildpath.exists():buildpath=WORK/'artifact-build'/buildpath.name
build=read(buildpath)
assert sha(exe)==build['artifact_sha256']
for path,digest in build['sources'].items():assert sha(ROOT/path)==digest,path
core=read(WORK/'CyrusInstaller.build.json')
for field,path in [('source_sha256','AminScatter/setup/InstallEngine.cs'),('options_source_sha256','AminScatter/setup/LibraryOptions.cs'),('shared_source_sha256','AminScatter/shared/LibraryLocation.cs')]:
    assert core[field]==sha(ROOT/path)
assert core['artifact_sha256']==build['core_sha256']==sha(WORK/'CyrusInstaller.dll')
record['artifacts'][exe.name]=sha(exe)
script=ROOT/'AminScatter/scripts/AminScatterObject.ms'
fingerprint=re.search(r'CyrusLoadedScriptFingerprint="([a-f0-9]+)"',script.read_text(encoding='utf-8-sig'))[1]
for year in (2024,2026,2027):
    host=ROOT/f'build/mcp-qualification/update08671-test-final4-{year}'
    loaded=read(host/'loaded-identity.json');launch=read(host/'launch.json')
    gallery=read(WORK/f'max{year}/CyrusGallery.build.json')
    assert gallery['source_sha256']==sha(ROOT/'AminScatter/ui/LibraryGallery.cs')
    assert gallery['shared_source_sha256']==sha(ROOT/'AminScatter/shared/LibraryLocation.cs')
    mzp=DIST/f'CyrusScatter-0.86.7.2-Max{year}.mzp'
    with zipfile.ZipFile(mzp) as archive:
        assert archive.testzip() is None
        manifest=json.loads(archive.read('manifest.json'))
        assert manifest['version']=='0.86.7.2' and manifest['max_year']==year
        assert set(archive.namelist())==set(manifest['files'])|{'manifest.json'}
        for path,digest in manifest['files'].items():assert hashlib.sha256(archive.read(path)).hexdigest()==digest,path
        assert manifest['files']['CyrusScatter.ms']==sha(script)==launch['script_sha256']
        assert loaded['script']==fingerprint and loaded['year']==year
        assert loaded['gallery']==manifest['files']['CyrusGallery.dll']==gallery['artifact_sha256']
        assert manifest['files']['CyrusInstaller.dll']==build['core_sha256']
        assert str((year-1998)*1000).encode() in archive.read('install.ms')
        assert len(loaded['native'])==4
        for module,digest in loaded['native'].items():
            assert manifest['files'][module]==digest==launch['binaries'][module]==sha(WORK/f'max{year}'/module)
        assert not any(p.startswith('Library/') or p.lower().endswith('.max') for p in archive.namelist())
    assert next(p for p in build['packages'] if p['year']==str(year))['package_sha256']==sha(mzp)
    record['artifacts'][mzp.name]=sha(mzp)
    for name in ['surface-08672.txt','brush-ui-08672.txt','viewport-08672.txt','source-controls.txt',
                 'lists-and-library.txt','panel-acceptance.txt','gallery-host.txt','library-binding.txt','texture-acceptance.txt']:
        receipt(host/name)
    if year==2027:
        for name in ['library-layers-08672.txt','leaf-acceptance.txt','live-lists.txt','installed-content-08672.txt']:
            receipt(host/name)
    finalinstaller=ROOT/'build/mcp-qualification'/('update08671-test-cold-2027' if year==2027 else f'update08671-test-installer-final-{year}')/'installer-corrected.txt'
    receipt(finalinstaller)
    assert 'LOADED_CORE '+build['core_sha256'] in finalinstaller.read_text(encoding='utf-8-sig')
    record['evidence'][str((host/'loaded-identity.json').relative_to(ROOT))]=sha(host/'loaded-identity.json')
receipt(ROOT/'build/mcp-qualification/update08671-test-cold-2027/cold-surface-08672.txt')
receipt(WORK/'exe-ui-release/result.txt')
assert (WORK/'exe-ui-release/exe-sha256.txt').read_text(encoding='utf-8-sig').strip()==sha(exe)
transactions=WORK/'installer-907246ed98/result.json'
assert read(transactions)['status']=='passed' and len(read(transactions)['checks'])==66
record['evidence'][str(transactions.relative_to(ROOT))]=sha(transactions)
assert read(WORK/'generated-final/generated-check.json')['passed']
record['evidence'][str((WORK/'generated-final/generated-check.json').relative_to(ROOT))]=sha(WORK/'generated-final/generated-check.json')
archive=DIST/'CyrusScatter-Content-0.86.7.zip';content=read(WORK/'content-zip.json')
assert sha(archive)==content['sha256'] and archive.stat().st_size==content['bytes']
manifest=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content/content-manifest.json'
assert sha(manifest)==content['manifest_sha256']=='010f43f09172c084ba15407227f9776e359b013e1f1a9583d31a2d4458e9a361'
assert not (DIST/'Content').exists()
record['artifacts'][archive.name]=content['sha256']
record['content_manifest_sha256']=sha(manifest)
record['script_sha256']=sha(script);record['loaded_script_fingerprint']=fingerprint
record['current_sources']={path:sha(ROOT/path) for path in [
    'AminScatter/src/brush_host.cpp','AminScatter/src/surface_visibility.inc','AminScatter/CMakeLists.txt',
    'AminScatter/tools/ui/templates/unified-core.ms','AminScatter/tools/ui/approved-layout-rows.cjs',
    'AminScatter/setup/InstallEngine.cs','AminScatter/setup/LibraryOptions.cs','AminScatter/setup/Program.cs']}
prior=ROOT/'dist/CyrusScatter-0.86.7.1-corrected-20261020/CyrusScatter-0.86.7.1-Setup.exe'
assert sha(prior)=='4a4ffe641c87e4ffe5030c0f69a0fe4a5ffff09710d886a4e7526cfbc3c97948'
resources=read(WORK/'exe-resource-hashes.json')
for item in build['packages']:
    assert resources[item['resource']]==item['package_sha256']
(WORK/'final-receipt.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
(DIST/'SHA256SUMS.txt').write_text(''.join(f'{digest}  {name}\n' for name,digest in record['artifacts'].items()),encoding='utf-8')
print(json.dumps({'status':'passed','artifacts':record['artifacts'],'evidence_files':len(record['evidence'])},indent=2))
