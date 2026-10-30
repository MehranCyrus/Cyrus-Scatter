"""Copy qualified artifacts and small evidence into durable delivery locations."""
from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[3];RUN=ROOT/'build/terraces0877-20261029-01'
DOC=ROOT/'docs/plans/terraces-performance-20261029';DIST=ROOT/'dist/CyrusScatter-0.87.6.1-20261029'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def copy(source,target):
    assert source.is_file(),source
    target.parent.mkdir(parents=True,exist_ok=True)
    if target.exists():assert sha(source)==sha(target),'Refuse to replace different delivery bytes: '+str(target)
    else:shutil.copy2(source,target)
    assert sha(source)==sha(target)
receipt=json.loads((DOC/'QUALIFICATION.json').read_text())
assert receipt['status']=='scoped_pass' and receipt['landscape_render']['status']=='complete'
for source in (RUN/'packages').iterdir():
    if source.is_file():copy(source,DIST/source.name)
for name in ['Terraces_Garden_0.87.6.1_Max2027.max','Contact_Distant_10000_Stress.max']:
    assert sha(RUN/name)==receipt['scene_files'][name]['sha256']
    copy(RUN/name,DIST/'Scenes'/name)
copy(RUN/'host-candidate/Terraces_Garden_0.87.6.1.png',DIST/'Terraces_Garden_0.87.6.1.png')
copy(RUN/'host-candidate/Terraces_Garden_0.87.6.1.png',DOC/'images/Terraces_Garden_0.87.6.1.png')
files={
 'host-baseline':['loaded-identity.json','ui-fixture.json','ui-warm.json','contact-sweep.json','inventory.json','palette.json','planting-design.json'],
 'host-ui-01':['ui-fixture.json','ui-warm.json'],
 'host-candidate':['loaded-identity.json','ui-final-check.json','contact-sweep.json','locality-sweep.json','proxy-sweep.json','rapid-scene.txt','rapid-edit.txt','edit-settings-check.json','garden-navigation.json','garden-drag-finish.json','garden-final-render.json','garden-reload.json','garden-drag-attempt-duplicate-modifier.json','garden-drag-attempt-stale-owner.json'],
 'native-2027':['receipt.json','tests.log'], 'native-2024':['receipt.json'], 'native-2026':['receipt.json'],
 'packages':['PACKAGE_VERIFICATION.json','SHA256SUMS.txt'], 'generated-final':['generated-check.json']}
for folder,names in files.items():
    for name in names:copy(RUN/folder/name,DOC/'evidence'/folder/name)
for p in (RUN/'cleanup').glob('*.json'):copy(p,DOC/'evidence/cleanup'/p.name)
for name in ['DELIVERY.md','ARTIST_GUIDE.md','MEASUREMENTS.md','QUALIFICATION.json']:
    copy(DOC/name,DIST/'Reports'/name)
copy(DOC/'images/Terraces_Garden_0.87.6.1.png',DIST/'Reports/images/Terraces_Garden_0.87.6.1.png')
guide='''# Cyrus Scatter 0.87.6.1

The EXE includes separate Max 2024, 2026 and 2027 packages. Save work and close
the selected Max versions, then run CyrusScatter-0.87.6.1-Setup.exe and choose
Install / Update. Leave optional library installation off if content is installed.
MZP alternative: Scripting > Run Script, select the matching host MZP, restart Max.
Do not mix a loose script with another version's native modules.

Max 2027 has scoped native/UI/contact/navigation/scene testing. Max 2024/2026
are compile/package checked only. The saved Scenes are Max 2027 files.

Open Scenes/Terraces_Garden_0.87.6.1_Max2027.max. Four GARDEN cameras and five
named Scatter controllers organize 18,229 placements. Start at camera 04 Boulder
garden; use Cyrus Scatter Edit on GARDEN | Lakeside boulders to move a stone.
Interactive grass is already prepared. Other landscape controllers are static.
Textures reference the existing local library under dist/CyrusScatter-0.86.7-20261020/
Content/Library/Maps and Test Scene/Rock_Boulder_10. Keep those asset folders.
Corona and the source scene's installed dependencies are needed for its materials.

Contact_Distant_10000_Stress.max is a separate heavy measurement fixture.
See Reports/ARTIST_GUIDE.md and Reports/MEASUREMENTS.md for controls and limits.
The original Test Scene files and artist profiles were not replaced.
'''
(DIST/'README.md').write_text(guide,encoding='utf-8')
evidence={p.relative_to(DOC/'evidence').as_posix():dict(bytes=p.stat().st_size,sha256=sha(p)) for p in sorted((DOC/'evidence').rglob('*')) if p.is_file()}
(DOC/'EVIDENCE_MANIFEST.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf-8')
manifest={p.relative_to(DIST).as_posix():dict(bytes=p.stat().st_size,sha256=sha(p)) for p in sorted(DIST.rglob('*')) if p.is_file() and p.name!='DELIVERY_MANIFEST.json'}
(DIST/'DELIVERY_MANIFEST.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
print(json.dumps(dict(delivery=str(DIST),files=len(manifest),evidence_files=len(evidence),status='verified'),indent=2))
