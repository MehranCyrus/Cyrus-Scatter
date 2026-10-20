"""Assemble a local testing kit only after final 0.2.1 qualification."""
from pathlib import Path
import hashlib, json, shutil, zipfile
ROOT = Path(__file__).resolve().parents[3]
DOCS = Path(__file__).resolve().parent.parent
DIST = ROOT / "dist/CyrusPhysicsLab-0.2.1-20261019-02"
evidence = json.loads((DOCS / "COLLIDER_COOK_021_EVIDENCE.json").read_text(encoding="utf-8"))
assert evidence["pass"]
def sha(data): return hashlib.sha256(data).hexdigest()
files = {"CyrusPhysicsLab-0.2.1-Max2027.mzp": (DIST / "CyrusPhysicsLab-0.2.1-Max2027.mzp").read_bytes()}
scenes = {
    "PhysicsLab-0.2.1-Captured-Teapot-Test.max": "build/physics-lab-collider-021-installed-03/PhysicsLab-0.2.1-Captured-Teapot-Test.max",
    "PhysicsLab-0.2.1-Small-Teapot-Transition.max": "build/physics-lab-collider-021-installed-03/teapot-0.00334-transition.max",
    "PhysicsLab-0.2.1-Mountain-Test.max": "build/physics-lab-collider-021-installed-03/PhysicsLab-0.2.0-Mountain-Test.max",
}
for name, path in scenes.items():
    data = (ROOT / path).read_bytes();files["Scenes/" + name] = data
    (DIST / name).write_bytes(data)
for name in ("COLLIDER_COOK_021.md", "COLLIDER_COOK_021_EVIDENCE.json", "ARTIST_GUIDE_020.md", "BAKE_WORKFLOW_020.md"):
    files["Docs/" + name] = (DOCS / name).read_bytes()
files["README-TESTING.txt"] = b"""Standalone Cyrus Physics Lab 0.2.1 / Max 2027

1. Cancel any failed pending session, or Finish/Freeze a valid pending session.
   Existing baked Editable Poly nodes are preserved. Save your MAX scene.
2. Run CyrusPhysicsLab-0.2.1-Max2027.mzp through Scripting > Run Script.
3. Save work and restart Max 2027. This kit has not installed into your profile.
4. Open a supplied scene and adopt its file system units. Select its Lab icon.

Captured-Teapot-Test reconstructs the receiver, source and 21 baked teapots from
the supplied numeric diagnostic capture. It is a reproduction scene, not a copy
of the original MAX scene/material setup. The baked batch is already a collider.
Switch Fast/Detailed, Start brush, add strokes, Finish and repeat.

Small-Teapot-Transition contains the completed 21-teapot Fast batch and a second
Detailed batch from the automated workflow. A second batch may use Freeze after
its settling limit; see the exact run results in the report. Compare old geometry
while changing future stroke quality.

Mountain-Test is the original mountain geometry copied for testing, with pyramid,
sphere and teapot models and a selected ready Lab. Nine comparison Labs/batches
are hidden. It uses the same automated fixture layout as the 0.2.0 test scene.
Some comparison cases need Freeze at the finite settle limit; see report.

This remains a standalone experimental Lab. Triangle/collider/body limits apply.
The fix retains small mesh triangles and improves small-object contact precision;
it does not promise universal topology/scale or renderer qualification.

Docs contain the actual results, expected rejections, limits and provenance.
"""
files["manifest.json"] = (json.dumps({"version": "0.2.1", "max_year": 2027, "files": {n: sha(v) for n,v in files.items()}}, indent=2)+"\n").encode()
kit = DIST / "CyrusPhysicsLab-0.2.1-Testing-Kit.zip"
with zipfile.ZipFile(kit, "w", zipfile.ZIP_DEFLATED) as z:
    for name, data in files.items(): z.writestr(name, data)
with zipfile.ZipFile(kit) as z:
    assert z.testzip() is None
    for name, digest in json.loads(z.read("manifest.json"))["files"].items(): assert sha(z.read(name)) == digest
source = DIST / "CyrusPhysicsLab-0.2.1-Source.zip"
with zipfile.ZipFile(source, "w", zipfile.ZIP_DEFLATED) as z:
    for name, digest in evidence["receipt"]["source_hashes"].items():
        data = (ROOT / "CyrusPhysicsLab" / name).read_bytes();assert sha(data) == digest
        z.writestr("CyrusPhysicsLab/" + name, data)
    z.writestr("build-receipt.json", json.dumps(evidence["receipt"], indent=2))
with zipfile.ZipFile(source) as z: assert z.testzip() is None
artifacts = {p.name: {"bytes": p.stat().st_size, "sha256": sha(p.read_bytes())} for p in [kit,source,*[DIST/n for n in scenes]]}
(DIST / "testing-artifacts.json").write_text(json.dumps(artifacts, indent=2)+"\n")
print(json.dumps(artifacts, indent=2))
