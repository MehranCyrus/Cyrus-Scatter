"""Private qualification controls. Not shipped in the product and not an MCP tool."""
from pathlib import Path
import json
import traceback
import time
import pymxs
from pymxs import runtime as rt
from PySide6 import QtCore

PANEL=None
TIMER=None
OUTPUT=None
LAST=None


def shape(name, coords):
    obj=rt.splineShape(name=name)
    rt.addNewSpline(obj)
    for x,y in coords:
        rt.addKnot(obj,1,rt.Name("corner"),rt.Name("line"),rt.Point3(x,y,0))
    rt.close(obj,1)
    rt.updateShape(obj)
    return obj


def setup(kind=0):
    PANEL.service.reset()
    if len(list(rt.objects)):
        rt.resetMaxFile(rt.Name("noPrompt"))
    rt.units.SystemType=rt.Name("Meters")
    rt.units.SystemScale=1.0
    site=rt.Plane(name="MCP Site",width=30,length=30,widthsegs=1+kind,lengthsegs=1+kind)
    source=rt.Cone(name="MCP Tree",radius1=.3,radius2=0,height=2,sides=8,heightsegs=1,position=rt.Point3(-25,0,0))
    shrub=rt.Sphere(name="MCP Shrub",radius=.2,segs=8,position=rt.Point3(-25,3,0))
    rt.hide(source)
    rt.hide(shrub)
    region=shape("MCP Planting",[(-14,-14),(14,-14),(14,14),(-14,14)])
    if kind==1:
        rt.units.SystemType=rt.Name("Centimeters")
    if kind==2:
        site.position=rt.Point3(7,4,2)
        site.rotation=rt.quat(31,rt.Point3(0,0,1))
        region.transform=site.transform
        source.objectOffsetPos=rt.Point3(.05,0,0)
    PANEL.picked={"site":[site],"sources":[source,shrub],"regions":[region],"excluded":[]}
    for key,nodes in PANEL.picked.items():
        PANEL.picks[key].setText(", ".join(str(n.name) for n in nodes) or "None")
    PANEL.share.setChecked(True)
    PANEL.enroll()
    rt.viewport.setLayout(rt.Name("layout_1"))
    rt.viewport.setType(rt.Name("view_persp_user"))
    cam=rt.targetCamera(pos=rt.Point3(30,-40,35),target=rt.targetObject(pos=rt.Point3(0,0,0)))
    tm=rt.inverse(cam.transform)
    target=cam.target
    rt.delete(cam)
    if rt.isValidNode(target):rt.delete(target)
    rt.viewport.setTM(tm)
    rt.viewport.setRenderLevel(rt.Name("smoothhighlights"))
    rt.completeRedraw()
    rt.select(site)
    return PANEL.service.connection()


def command(data):
    action=data["action"]
    if action=="setup":
        return setup(data.get("kind",0))
    if action=="boundary":
        from host_boundary import command as boundary_command
        return boundary_command(PANEL,data)
    if action=="approve":
        PANEL.service.approve(data["validation_id"])
        return {"approved":True}
    if action=="undo":
        PANEL.service.undo()
        return {"nodes":len(list(rt.objects))}
    if action=="fault":
        PANEL.host.fail_phase=data.get("phase")
        return {"fault":PANEL.host.fail_phase}
    if action=="cancel":
        PANEL.service.cancel()
        return {"cancelled":True}
    if action=="snapshot":
        return {"fingerprint":PANEL.host.fingerprint(),"nodes":len(list(rt.objects)),"selected":[int(rt.getHandleByAnim(n)) for n in rt.selection],"dirty":bool(rt.getSaveRequired()),"undo":[str(v) for v in rt.theHold.GetUndoNames()],"diagnostics":PANEL.host.diagnostics(),"redraw_disabled":bool(rt.isSceneRedrawDisabled()),"auto_key":bool(rt.animButtonState)}
    if action=="edit":
        node=PANEL.picked["sources"][0]
        with pymxs.undo(True,"Artist source edit"):
            node.height=float(node.height)+.1
        return {"edited":True}
    if action=="save_reopen":
        path=OUTPUT/"QualifiedLayout.max"
        records={cid:{"object_name":str(obj.name),"rows":[str(rt.cyrusEditFingerprint(layer.placements(layer.validSources()),"mcp")) for layer in obj.layerObjects]} for cid,obj in PANEL.host.controllers.items()}
        rt.saveMaxFile(str(path),quiet=True)
        rt.loadMaxFile(str(path),quiet=True)
        after={cid:[str(rt.cyrusEditFingerprint(layer.placements(layer.validSources()),"mcp")) for layer in rt.getNodeByName(record["object_name"]).layerObjects] for cid,record in records.items()}
        return {"path":str(path),"match":all(record["rows"]==after[cid] for cid,record in records.items()),"controllers":len(records),"scope_cleared":PANEL.service.scope is None}
    raise ValueError("Unknown private fixture action")


def tick():
    global LAST
    path=OUTPUT/"fixture-command.json"
    if not path.exists():return
    try:
        data=json.loads(path.read_text())
    except (OSError,json.JSONDecodeError):
        return
    if data["id"]==LAST:return
    LAST=data["id"]
    try:
        result={"id":LAST,"ok":True,"result":command(data)}
    except Exception:
        result={"id":LAST,"ok":False,"error":traceback.format_exc()}
    (OUTPUT/"fixture-result.json").write_text(json.dumps(result,indent=2))


def start(output):
    global PANEL,TIMER,OUTPUT
    OUTPUT=Path(output)
    try:
        (OUTPUT/"startup-stage.txt").write_text("Import panel")
        from cyrus_mcp.panel import start as start_panel
        (OUTPUT/"startup-stage.txt").write_text("Create panel")
        PANEL=start_panel(OUTPUT/"connection")
        (OUTPUT/"startup-stage.txt").write_text("Setup scene")
        result=setup()
        TIMER=QtCore.QTimer(PANEL)
        TIMER.timeout.connect(tick)
        TIMER.start(100)
        (OUTPUT/"ready.json").write_text(json.dumps(result,indent=2))
        (OUTPUT/"startup-error.txt").unlink(missing_ok=True)
    except Exception:
        (OUTPUT/"startup-error.txt").write_text(traceback.format_exc())


def start_installed(output,script):
    """Bootstrap the actual installed package, without automatic enrollment."""
    global PANEL,TIMER,OUTPUT
    OUTPUT=Path(output)
    try:
        rt.fileIn(script)
        import cyrus_mcp.panel as panel
        PANEL=panel.PANEL
        assert PANEL is not None
        TIMER=QtCore.QTimer(PANEL)
        TIMER.timeout.connect(tick)
        TIMER.start(100)
        (OUTPUT/"installed-host.json").write_text(json.dumps({
            "module":panel.__file__,"connection_directory":str(PANEL.directory),
            "scope":PANEL.service.scope,"visible":PANEL.isVisible()},indent=2))
        (OUTPUT/"ready.json").write_text(json.dumps(PANEL.service.connection(),indent=2))
    except Exception:
        (OUTPUT/"startup-error.txt").write_text(traceback.format_exc())
