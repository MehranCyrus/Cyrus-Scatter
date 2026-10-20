"""Pin corrected packages to their compiled sources and actual host identities."""
from pathlib import Path
import hashlib,json,re,zipfile
ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'build/repair-08671-20261020'
DIST=ROOT/'dist/CyrusScatter-0.86.7.1-corrected-20261020'
def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
record={'version':'0.86.7.1','status':'passed','artifacts':{},'evidence':{},
        'artist_profiles_modified':False,'native_rebuilt':False,'content_copied':False}
exe=DIST/'CyrusScatter-0.86.7.1-Setup.exe';build=read(exe.with_suffix('.build.json'))
assert sha(exe)==build['artifact_sha256']
for path,digest in build['sources'].items():assert sha(ROOT/path)==digest,path
record['artifacts'][exe.name]=sha(exe)
script=ROOT/'AminScatter/scripts/AminScatterObject.ms'
fingerprint=re.search(r'CyrusLoadedScriptFingerprint="([a-f0-9]+)"',script.read_text(encoding='utf-8-sig'))[1]
for year in (2024,2026,2027):
    name='update08671-test-list-fixed-2027' if year==2027 else f'update08671-test-corrected-{year}'
    host=ROOT/'build/mcp-qualification'/name
    loaded=read(host/'loaded-identity.json');launch=read(host/'launch.json')
    gallery=read(WORK/f'max{year}/CyrusGallery.build.json')
    assert gallery['source_sha256']==sha(ROOT/'AminScatter/ui/LibraryGallery.cs')
    assert gallery['shared_source_sha256']==sha(ROOT/'AminScatter/shared/LibraryLocation.cs')
    mzp=DIST/f'CyrusScatter-0.86.7.1-Max{year}.mzp'
    with zipfile.ZipFile(mzp) as archive:
        assert archive.testzip() is None
        manifest=json.loads(archive.read('manifest.json'))
        assert manifest['version']=='0.86.7.1' and manifest['max_year']==year
        assert set(archive.namelist())==set(manifest['files'])|{'manifest.json'}
        for path,digest in manifest['files'].items():assert hashlib.sha256(archive.read(path)).hexdigest()==digest,path
        assert manifest['files']['CyrusScatter.ms']==sha(script)==launch['script_sha256']
        assert loaded['script']==fingerprint and loaded['year']==year
        assert loaded['gallery']==manifest['files']['CyrusGallery.dll']==gallery['artifact_sha256']
        assert manifest['files']['CyrusInstaller.dll']==build['core_sha256']
        assert str((year-1998)*1000).encode() in archive.read('install.ms')
        for module,digest in loaded['native'].items():
            assert manifest['files'][module]==digest==launch['binaries'][module]
            assert sha(ROOT/f'build/update-08671-20261020/max{year}'/module)==digest
        assert not any(p.startswith('Library/') or p.lower().endswith('.max') for p in archive.namelist())
    assert next(p for p in build['packages'] if p['year']==str(year))['package_sha256']==sha(mzp)
    record['artifacts'][mzp.name]=sha(mzp)
    receipts=['lists-and-library.txt','panel-acceptance.txt','gallery-host.txt','installer-corrected.txt']
    if year==2027:receipts+=['list-visibility.txt','leaf-acceptance.txt','live-lists.txt']
    for name in receipts:
        path=host/name;text=path.read_text()
        assert 'SUCCESS' in text and 'ERROR' not in text and 'FAIL:' not in text,path
        record['evidence'][str(path.relative_to(ROOT))]=sha(path)
    record['evidence'][str((host/'loaded-identity.json').relative_to(ROOT))]=sha(host/'loaded-identity.json')
assert (WORK/'exe-ui-delivery/exe-sha256.txt').read_text(encoding='utf-8-sig').strip()==sha(exe)
for path in [WORK/'exe-ui-delivery/result.txt',WORK/'installer-2c316dbab4/result.json']:
    text=path.read_text(encoding='utf-8-sig')
    assert 'SUCCESS' in text or read(path)['status']=='passed'
    record['evidence'][str(path.relative_to(ROOT))]=sha(path)
assert len(read(WORK/'installer-2c316dbab4/result.json')['checks'])==46
assert read(WORK/'generated/generated-check.json')['passed']
original=ROOT/'dist/CyrusScatter-0.86.7.1-20261020/CyrusScatter-0.86.7.1-Setup.exe'
assert sha(original)=='60f20560d221b9f7c5defe278390abc48ba97bb8e52072f9e6345e2ba5f29c20'
content=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content/content-manifest.json'
assert sha(content)=='010f43f09172c084ba15407227f9776e359b013e1f1a9583d31a2d4458e9a361'
assert not (DIST/'Content').exists()
record['content_manifest_sha256']=sha(content)
record['script_sha256']=sha(script);record['loaded_script_fingerprint']=fingerprint
(WORK/'final-receipt.json').write_text(json.dumps(record,indent=2)+'\n')
(DIST/'SHA256SUMS.txt').write_text(''.join(f'{digest}  {name}\n' for name,digest in record['artifacts'].items()))
(WORK/'package-checks.json').write_text(json.dumps({'status':'passed','hosts':[2024,2026,2027],
    'checks':['CRC','all member hashes','actual loaded identities','matched host guards','embedded EXE packages','source build receipts','unchanged content manifest'],
    'packages':record['artifacts'],'content_copied':False},indent=2)+'\n')
print(json.dumps({'status':'passed','artifacts':record['artifacts'],'receipts':len(record['evidence'])},indent=2))
