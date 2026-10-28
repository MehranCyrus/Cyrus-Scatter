"""Seal exact final source/package/owned-host evidence without installing an artist profile."""
from pathlib import Path
import hashlib,json,zipfile
ROOT=Path(__file__).resolve().parents[3];run=ROOT/'build/interactions08743-20261027-01';host=run/'host-03'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8'))
receipt=read(run/'native-03/receipt.json');assert receipt['status']=='complete' and receipt['tests_run'] and receipt['max_year']==2027
changed=[path for path,expected in receipt['sources'].items() if sha(ROOT/path)!=expected]
assert not changed,changed
identity=read(run/'payload-03/package-identity.json');archive=Path(identity['archive']);assert sha(archive)==identity['sha256']
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None;manifest=json.loads(z.read('manifest.json'))
    assert manifest['version']=='0.87.4.3' and manifest['max_year']==2027
    for name,expected in manifest['files'].items():assert hashlib.sha256(z.read(name)).hexdigest()==expected,name
loaded=read(host/'loaded-identity.json')
for name,value in loaded['modules'].items():assert sha(Path(value['path']))==manifest['files'][name] and value['sha256']==manifest['files'][name],name
required=['migration','setup','under-auto','margin','undo-read','redo-read','pending','bend','scale200','save','reload','restore','view-split','view-mesh-wire','view-texture-wire','view-deformed','view-f3shade','view-shade']
for phase in required:assert read(host/('check-'+phase+'.json'))['status']=='pass',phase
assert read(run/'generated-final/generated-check.json')['passed']
original=ROOT/'Test Scene/New Plants test.max';assert sha(original)=='70e2807fd2041f9f06766db71a09b565752c18a383c0a5ccf24684009a257f8d'
launch=read(host/'launch.json');artist=Path.home()/'AppData/Local/Autodesk/3dsMax/2027 - 64bit/ENU/3dsMax.ini'
report={'status':'pass','version':'0.87.4.3','max_year':2027,'native_capability':11,'scene_schema':63,'source_files_verified':len(receipt['sources']),
        'source_receipt':str(run/'native-03/receipt.json'),'archive':str(archive),'archive_sha256':sha(archive),'bytes':archive.stat().st_size,
        'original_scene_sha256':sha(original),'artist_ini_observed_unchanged':sha(artist)==launch['artist_ini_sha256'],
        'installer_receipt':read(run/'installer-03/receipt.json'),'loaded_identity':loaded,
        'host_checks':{phase:{'path':str(host/('check-'+phase+'.json')),'sha256':sha(host/('check-'+phase+'.json'))} for phase in required},
        'limits':'Scoped Max 2027 acceptance; native contact time is not FPS, independent audit is double precision; no renderer/other-host qualification.'}
(run/'qualification-final.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k in ('status','version','archive_sha256','source_files_verified','artist_ini_observed_unchanged','bytes')},indent=2))
