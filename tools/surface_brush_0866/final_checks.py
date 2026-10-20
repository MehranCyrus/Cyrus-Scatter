from pathlib import Path
import hashlib,json,zipfile,time
ROOT=Path(__file__).resolve().parents[2];dest=ROOT/'dist/CyrusScatter-0.86.6-20261019'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
native=json.loads((dest/'receipt.json').read_text())
for name,digest in {**native['sources'],**native['binaries']}.items():assert sha(ROOT/name)==digest,name
exe=json.loads((dest/'exe-receipt.json').read_text());assert sha(dest/'CyrusScatter-0.86.6-Setup.exe')==exe['exe_sha256']
mzp=dest/'CyrusScatter-0.86.6-Max2027.mzp';assert sha(mzp)==exe['mzp_sha256']
with zipfile.ZipFile(mzp) as z:
 assert z.testzip() is None
 manifest=json.loads(z.read('manifest.json'));assert manifest['version']=='0.86.6' and manifest['max_year']==2027
 assert set(z.namelist())==set(manifest['files'])|{'manifest.json'}
 for name,digest in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==digest
 assert not any('probe' in name.lower() for name in z.namelist())
 assert b'Copyright (C) 2008 Danil Kirsanov' in z.read('SurfaceGeodesic-NOTICE.txt')
 assert manifest['files']['CyrusScatter.ms']==sha(ROOT/'AminScatter/scripts/AminScatterObject.ms')
qualification=json.loads((dest/'QUALIFICATION_0866.json').read_text());assert len(qualification['records'])==18
p=ROOT/'website/content/source-manifest.json';d=json.loads(p.read_text(encoding='utf-8'))
for name in ('docs/Current_System_2026-10-05/CAPABILITY_MATRIX.md','docs/ARCHITECTURE.md','docs/plans/preset-gallery-improvements/ARTIST_WORKFLOW.md'):
 assert name in d['reviewedSourceHashes'];d['reviewedSourceHashes'][name]=sha(ROOT/name)
name='docs/plans/preset-gallery-improvements/DELIVERY_0866.md';d['reviewedSourceHashes'][name]=sha(ROOT/name)
for attempt in range(6):
 try:p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');break
 except OSError as error:
  if error.errno not in (13,22) or attempt==5:raise
  time.sleep(.2*(attempt+1))
print('Final source/native/archive/EXE hashes match; 18 host records; no private probe in delivery.')
