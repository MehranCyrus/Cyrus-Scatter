"""Build the local 0.2.0 handoff kit from accepted evidence; never install."""
from pathlib import Path
import json,hashlib,zipfile,shutil
ROOT=Path(__file__).resolve().parents[3];DOCS=Path(__file__).resolve().parent.parent
DIST=ROOT/'dist/CyrusPhysicsLab-0.2.0-20261018-02'
INSTALLED=ROOT/'build/physics-lab-bake-020-installed-02'
VALIDATION=ROOT/'build/physics-lab-bake-020-final-validation-01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
report=json.loads((DOCS/'BAKE_WORKFLOW_020_EVIDENCE.json').read_text(encoding='utf8'))
assert report['pass'] and report['package_sha256']==sha(DIST/'CyrusPhysicsLab-0.2.0-Max2027.mzp')
scenes={'PhysicsLab-0.2.0-Mountain-Test.max':VALIDATION/'PhysicsLab-0.2.0-Mountain-Test.max','PhysicsLab-0.2.0-Baked-Stack-Test.max':INSTALLED/'baked-stack.max','PhysicsLab-0.2.0-Baked-Workflow-Test.max':INSTALLED/'baked-workflow.max'}
for name,source in scenes.items():shutil.copy2(source,DIST/name)
for name in ('ARTIST_GUIDE_020.md','BAKE_WORKFLOW_020.md','BAKE_WORKFLOW_020_EVIDENCE.json'):shutil.copy2(DOCS/name,DIST/name)
shutil.copy2(VALIDATION/'baked-material-render.png',DIST/'baked-material-render.png')
(DIST/'README-TESTING.md').write_text('''# Cyrus Physics Lab 0.2.0 / Max 2027

Run CyrusPhysicsLab-0.2.0-Max2027.mzp using Scripting > Run Script, then save work
and restart Max 2027. Finish/Freeze or cancel an old pending session before upgrading.
No artist-profile installation was performed by this task.

Open PhysicsLab-0.2.0-Mountain-Test.max, adopt its saved system units and select
PhysicsLab_Brush_Ready_020. Pyramid, Sphere and Teapot are enabled in Detailed mode.
A mixed baked example is visible and automatically bound as that Lab's collider;
it was frozen while moving and may contain overlaps. Other comparison Labs and
batches are hidden. Test on another part of the mountain, Finish a small batch,
switch quality and brush across it, then Undo/Redo and save/reopen.

Only a checkbox click changes model enablement. Names select collision settings;
empty list space does nothing. + adds, x removes and Replace changes the model.
Finish now creates one independent Editable Poly and static collider per session.
Quality changes affect new strokes. Original unassigned models retain their state;
the Lab uses their wire colours as fallback materials. Assigned materials remain
shared normal Max materials. Save the MAX scene for all baked batches.

The Baked-Stack scene demonstrates a sphere resting on a previously baked platform.
The Baked-Workflow scene exercises independent materials and edited/deleted colliders.
The PNG is an isolated render of baked materials, not a viewport screenshot.

The shared 200,000 collision-triangle / 64 collider budgets still apply. Finish
can reach a settle limit on slopes; Freeze accepts current poses. Dynamic convex
quality approximates holes. The technical report records tested scope and limits.
No Computer Use, preset changes, main Scatter integration or physical-input/FPS
qualification is included.
''',encoding='utf8')
names=['CyrusPhysicsLab-0.2.0-Max2027.mzp',*scenes,'ARTIST_GUIDE_020.md','BAKE_WORKFLOW_020.md','BAKE_WORKFLOW_020_EVIDENCE.json','baked-material-render.png','README-TESTING.md']
manifest={name:{'sha256':sha(DIST/name),'bytes':(DIST/name).stat().st_size} for name in names}
(DIST/'testing-kit-manifest.json').write_text(json.dumps({'version':'0.2.0','files':manifest},indent=2)+'\n',encoding='utf8')
kit=DIST/'CyrusPhysicsLab-0.2.0-Testing-Kit.zip'
with zipfile.ZipFile(kit,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
 for name in [*names,'testing-kit-manifest.json']:z.write(DIST/name,name)
with zipfile.ZipFile(kit) as z:
 assert z.testzip() is None
 for name,v in manifest.items():assert hashlib.sha256(z.read(name)).hexdigest()==v['sha256']
source=DIST/'CyrusPhysicsLab-0.2.0-Source.zip'
with zipfile.ZipFile(source,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as z:
 for name,digest in report['receipt']['source_hashes'].items():
  p=ROOT/'CyrusPhysicsLab'/name;assert sha(p)==digest;z.write(p,'CyrusPhysicsLab/'+name)
with zipfile.ZipFile(source) as z:assert z.testzip() is None
print(json.dumps({'kit':str(kit),'kit_sha256':sha(kit),'kit_bytes':kit.stat().st_size,'source_sha256':sha(source),'verified':True},indent=2))
