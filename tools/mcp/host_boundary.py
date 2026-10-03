"""Extra private Max qualification controls; excluded from the shipped package."""
import time
import pymxs
from pymxs import runtime as rt
from PySide6 import QtWidgets
from cyrus_mcp.contracts import Fault

MODAL=None


def command(panel,data):
    global MODAL
    kind=data["kind"]
    if kind=="busy":
        mode=data["mode"]
        enabled=data["enabled"]
        if mode=="render_callback":
            panel.render_start() if enabled else panel.render_end()
        elif mode=="undo_hold":
            rt.theHold.Begin() if enabled else rt.theHold.Cancel()
        elif mode=="animation":
            rt.playAnimation() if enabled else rt.stopAnimation()
        elif mode=="modal":
            if enabled:
                MODAL=QtWidgets.QDialog(panel)
                MODAL.setWindowTitle("Private MCP modal qualification")
                MODAL.setModal(True)
                MODAL.show()
            elif MODAL:
                MODAL.close();MODAL=None
        return {"busy":bool(panel.host.busy())}
    if kind=="capture_permission":
        panel.share.setChecked(data["enabled"])
        return {"allowed":panel.service.scope["allow_capture"]}
    if kind=="other_edit":
        with pymxs.undo(True,"Unrelated artist edit"):
            rt.Box(name="Artist object",position=rt.Point3(40,0,0))
        return {"nodes":len(list(rt.objects))}
    if kind=="guarded_undo":
        try:
            panel.service.undo()
            return {"undone":True}
        except Fault as exc:
            return exc.result()
    if kind=="delete_input":
        with pymxs.undo(True,"Private fixture delete"):
            rt.delete(panel.picked[data["group"]][0])
        return {"deleted":True}
    if kind=="repick":
        rt.select(panel.picked["site"][0])
        panel.pick("site")
        return {"scope_cleared":panel.service.scope is None}
    if kind=="inspect":
        node=next(iter(panel.host.controllers.values()))
        rt.select(node)
        panel.inspect_selected()
        return panel.service.connection()
    if kind=="display_mode":
        obj=next(iter(panel.host.controllers.values()))
        with pymxs.undo(True,"Private fixture display change"):
            obj.setLayerTransfer(True)
            obj.viewportMode=data["mode"]
            for layer in obj.layerObjects:layer.viewportMode=data["mode"]
            obj.setLayerTransfer(False)
            obj.refreshAll()
        if data["mode"]==3:rt.CyrusRetainedMeshDrawing(True)
        if data["mode"]==1:rt.CyrusRetainedPointDrawing(True)
        rt.CyrusPointSync()
        rt.completeRedraw()
        return {"mode":data["mode"]}
    with pymxs.undo(True,"Private fixture input change"):
        modify_inputs(panel,data)
    started=time.perf_counter()
    try:
        panel.enroll()
        return {"enrolled":True,"duration_ms":(time.perf_counter()-started)*1000}
    except Fault as exc:
        return {**exc.result(),"duration_ms":(time.perf_counter()-started)*1000}


def modify_inputs(panel,data):
    kind=data["kind"]
    if kind=="complexity":
        source=panel.picked["sources"][0]
        rt.delete(source)
        replacement=rt.Plane(name="Complex source",width=.4,length=.4,widthsegs=data["x"],lengthsegs=data["y"],position=rt.Point3(-25,0,0))
        rt.hide(replacement)
        panel.picked["sources"]=[replacement]
    elif kind=="tilted_site":
        panel.picked["site"][0].rotation=rt.quat(15,rt.Point3(1,0,0))
    elif kind=="animated_source":
        with pymxs.animate(True):
            with pymxs.attime(10):
                panel.picked["sources"][0].height=3
    elif kind=="outside_region":
        panel.picked["regions"][0].position=rt.Point3(100,0,0)
    elif kind=="concave_region":
        rt.setKnotPoint(panel.picked["regions"][0],1,2,rt.Point3(-7,7,0))
        rt.updateShape(panel.picked["regions"][0])
    elif kind=="protected_region":
        from host_fixture import shape
        panel.picked["excluded"]=[shape("Protected",[(-1,-1),(1,-1),(1,1),(-1,1)])]
    elif kind=="huge_asset":
        panel.picked["sources"][0].radius1=25
    else:
        raise ValueError("Unknown boundary fixture")
