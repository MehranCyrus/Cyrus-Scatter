"""Assemble the verified local installer/scenes/docs; never install or publish."""
from pathlib import Path
import json,hashlib,shutil,zipfile
ROOT=Path(__file__).resolve().parents[3]
DOCS=Path(__file__).resolve().parent.parent
DIST=ROOT/'dist/CyrusPhysicsLab-0.1.9-20261018-06'
HOST=ROOT/'build/physics-lab-repair-019-all-04'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
report=json.loads((DOCS/'STABILITY_UI_019_EVIDENCE.json').read_text(encoding='utf8'))
assert report['pass'] and report['package_sha256']==sha(DIST/'CyrusPhysicsLab-0.1.9-Max2027.mzp')
scene_names={
 'PhysicsLab-0.1.9-Mountain-Test.max':'PhysicsLab-0.1.9-Mountain-Test.max',
 'palette-retired.max':'PhysicsLab-0.1.9-Palette-Retired-Test.max',
 'order-persist.max':'PhysicsLab-0.1.9-Palette-Order-Test.max',
}
for source,name in scene_names.items():shutil.copy2(HOST/source,DIST/name)
for name in ('STABILITY_UI_019.md','STABILITY_UI_019_EVIDENCE.json','TEST_SCENE_019.md'):
    shutil.copy2(DOCS/name,DIST/name)
(DIST/'README-TESTING.md').write_text('''# Cyrus Physics Lab 0.1.9 — Max 2027

Run CyrusPhysicsLab-0.1.9-Max2027.mzp through Scripting > Run Script, then restart
Max 2027. Save/Freeze or cancel an old pending session before upgrading.

Open PhysicsLab-0.1.9-Mountain-Test.max and select PhysicsLab_Brush_Ready_019.
It is empty, with Pyramid, Sphere and Teapot enabled. Check models to spray them;
highlight a row for its settings. + adds, x removes, Replace changes its binding.
Removal keeps already placed bodies. No All/None/Solo toolbar remains.

For the two saved-result regression scenes, adopt the file's system units.
TEST_SCENE_019.md explains their purposes and suggested artist checks.
STABILITY_UI_019.md and its JSON evidence record exact qualification and limits.

Detailed still approximates concavities; the known teapot handle opening remains
filled at the 16-piece bound. Freeze can keep moving-body overlaps. No physical
mouse/tablet, screen-pixel, mixed-monitor DPI or presented-FPS qualification is
claimed. This stays independent of CyrusScatter; no preset changes are included.
''',encoding='utf8')
names=['CyrusPhysicsLab-0.1.9-Max2027.mzp',*scene_names.values(),'README-TESTING.md','STABILITY_UI_019.md','STABILITY_UI_019_EVIDENCE.json','TEST_SCENE_019.md']
manifest={name:{'sha256':sha(DIST/name),'bytes':(DIST/name).stat().st_size} for name in names}
(DIST/'testing-kit-manifest.json').write_text(json.dumps({'version':'0.1.9','files':manifest},indent=2)+'\n',encoding='utf8')
target=DIST/'CyrusPhysicsLab-0.1.9-Mountain-Testing-Kit.zip'
with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
    for name in [*names,'testing-kit-manifest.json']:z.write(DIST/name,name)
with zipfile.ZipFile(target) as z:
    assert z.testzip() is None
    for name,v in manifest.items():assert hashlib.sha256(z.read(name)).hexdigest()==v['sha256']
print(json.dumps({'kit':str(target),'sha256':sha(target),'bytes':target.stat().st_size,'archive_verified':True},indent=2))
