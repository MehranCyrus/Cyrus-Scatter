from pathlib import Path
import json,shutil,hashlib
ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'build/update-08671-20261020'
receipt=json.loads((WORK/'real-installer/result.json').read_text(encoding='utf-8-sig'))
assert receipt['status']=='passed'
for year,folder in receipt['releases'].items():
    installed=Path(folder);stage=WORK/f'installed-stage{year}';stage.mkdir(exist_ok=True)
    for name in ['AminScatter.dlx','CyrusBrush.dlx','CyrusBrushStorage.dlh','CyrusScatterEdit.dlm','CyrusScatter.ms','CyrusGallery.dll','LibraryBinding.txt']:
        source=installed/('bin/'+name if name.endswith(('.dlx','.dlm','.dlh')) else name)
        shutil.copy2(source,stage/name)
        assert hashlib.file_digest(source.open('rb'),'sha256').digest()==hashlib.file_digest((stage/name).open('rb'),'sha256').digest()
print('Staged exact installed runtimes and shared bindings for all three hosts')
