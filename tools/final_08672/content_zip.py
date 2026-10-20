"""Archive existing qualified content without resaving assets or staging a copy."""
from pathlib import Path
import hashlib,json,zipfile
ROOT=Path(__file__).resolve().parents[2]
source=ROOT/'dist/CyrusScatter-0.86.7-20261020/Content'
out=ROOT/'dist/CyrusScatter-0.86.7.2-20261020'
out.mkdir(exist_ok=True)
target=out/'CyrusScatter-Content-0.86.7.zip'
manifest=(source/'content-manifest.json').read_bytes()
files=json.loads(manifest)['files']
assert not target.exists(), 'Preserve a completed content archive'
temporary=target.with_suffix('.zip.partial')
assert not temporary.exists(), 'Inspect an interrupted archive before retrying'
with zipfile.ZipFile(temporary,'x',zipfile.ZIP_DEFLATED,compresslevel=1,allowZip64=True) as archive:
    archive.writestr('content-manifest.json',manifest)
    for name,spec in files.items():
        digest=hashlib.sha256();count=0
        with (source/name).open('rb') as src,archive.open(name,'w',force_zip64=True) as dst:
            while chunk:=src.read(1024*1024):
                count+=len(chunk);digest.update(chunk);dst.write(chunk)
        assert count==spec['bytes'] and digest.hexdigest()==spec['sha256'],name
with zipfile.ZipFile(temporary) as archive:
    assert archive.testzip() is None
temporary.rename(target)
with target.open('rb') as src:digest=hashlib.file_digest(src,'sha256').hexdigest()
(ROOT/'build/final-08672-20261020/content-zip.json').write_text(json.dumps({
    'path':str(target),'sha256':digest,'bytes':target.stat().st_size,
    'manifest_sha256':hashlib.sha256(manifest).hexdigest(),
    'files':len(files),'expanded_bytes':sum(v['bytes'] for v in files.values())+len(manifest),
    'checks':['every source size and SHA256','archive CRC','unchanged manifest'],
    'assets_regenerated':False},indent=2)+'\n',encoding='utf-8')
print(target,flush=True)
