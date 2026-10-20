"""Reconstruct copied numeric diagnostics in an owned Max test host only."""
from pathlib import Path
import json
from pymxs import runtime as rt

root = Path(__file__).resolve().parents[3]
capture = root / "build/physics-collider-021-20261019-01/artist-capture/context-3.json"
data = json.loads(capture.read_text())
input_data = data["prepared"]["input"]

def mesh(name, values):
    vertices = rt.Array(*[rt.Point3(*(c * 1000 for c in p)) for p in values["vertices"]])
    faces = rt.Array(*[rt.Point3(*(i + 1 for i in f)) for f in values["faces"]])
    return rt.mesh(name=name, vertices=vertices, faces=faces)

rt.units.SystemType = rt.Name("millimeters")
rt.units.SystemScale = 1
receiver = mesh("Captured_Receiver_021", input_data["colliders"][1])
baked = mesh("Captured_Baked_21_Teapots_021", input_data["colliders"][0])
rt.convertToPoly(baked)
source = mesh("Captured_Teapot_Source_021", input_data["sources"][0]["render"])
source.position = rt.Point3(300, 0, 0)
source.wirecolor = rt.color(60, 180, 230)
baked.material = rt.standardMaterial(name="Captured batch blue", diffuse=rt.color(60, 180, 230))
rt.hide(source)
lab = rt.CyrusPhysicsLab(name="Captured_Lab_021")
lab.setReceiver(receiver)
lab.addSource(source)
lab.addCollider(baked)
lab.brushRadius = .001
lab.birthSpacing = .08
lab.emissionHeight = .04
lab.viewportIconSize = .01
