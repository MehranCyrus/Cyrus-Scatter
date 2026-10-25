"""Owned source metadata and native model-import measurements. Never shipped."""
import json
import time
from pathlib import Path
from pymxs import runtime as rt
import host_fixture as base

HIGH=None
MESH_ORIGINAL=None


def high_fixture():
    global HIGH,MESH_ORIGINAL
    panel=base.PANEL
    if MESH_ORIGINAL is not None:panel.host.mesh=MESH_ORIGINAL
    HIGH=rt.sphere(name="Owned baked high-detail source",radius=.4,segs=120,pos=rt.Point3(-20,4,1))
    rt.convertToMesh(HIGH);HIGH.rotation=rt.quat(37,rt.Point3(0,0,1));HIGH.objectOffsetPos=rt.Point3(.1,0,0)
    rt.hide(HIGH)
    MESH_ORIGINAL=panel.host.mesh
    def guarded(node,*args,**kwargs):
        assert node!=HIGH,"Baked sources must not copy geometry through Host.mesh"
        return MESH_ORIGINAL(node,*args,**kwargs)
    panel.host.mesh=guarded
    rt.select(rt.Array(panel.picked["site"][0],HIGH,panel.picked["regions"][0]));panel.inspect_scene_selected();panel.scene_task_dialog.hide()
    return dict(scope_id=panel.service.scope["scope_id"],objects=panel.service.scope["snapshot"]["objects"],
                polygons=[int(x) for x in rt.getPolygonCount(HIGH)])


def edit_vertex():
    point=rt.getVert(HIGH,1);rt.setVert(HIGH,1,point+rt.Point3(.02,0,.01));rt.update(HIGH)
    return dict(edited=True)


def transform_identity_offset():
    HIGH.objectOffsetPos=rt.Point3(0,0,0)
    return dict(prepared=True)


def move():
    HIGH.pos=HIGH.pos+rt.Point3(5,2,1)
    return dict(moved=True)


def restore_guard():
    global MESH_ORIGINAL
    if MESH_ORIGINAL is not None:base.PANEL.host.mesh=MESH_ORIGINAL;MESH_ORIGINAL=None


def import_probe(root,entry_id):
    """Measure the existing importer unchanged; do not infer Undo promises."""
    restore_guard()
    rt.execute('dotNet.loadAssembly (pathConfig.appendPath CyrusRecipeScriptDirectory "CyrusGallery.dll")')
    catalog=rt.execute('dotNetObject "CyrusScatter.UI.IndividualModelCatalog"')
    catalog.Load(root,str(rt.CyrusLibraryVersion()),2027)
    entry=next(catalog.MatchingAt("","",i) for i in range(int(catalog.Count)) if str(catalog.MatchingAt("","",i).Id)==entry_id)
    sentinel=rt.box(name="Owned import Undo sentinel",width=.1,length=.1,height=.1)
    rt.CyrusMCPImportSentinel=sentinel
    rt.clearUndoBuffer()
    rt.execute('undo "MCP pre-import sentinel move" on (CyrusMCPImportSentinel.pos=[7,0,0])')
    names=lambda:[str(v) for v in rt.theHold.GetUndoNames()]
    before=dict(nodes=len(rt.objects),undo=names(),sentinel_pos=[float(x) for x in (sentinel.pos.x,sentinel.pos.y,sentinel.pos.z)],
                selection=[int(rt.getHandleByAnim(rt.selection[i])) for i in range(len(rt.selection))])
    started=time.perf_counter();model=None
    try:
        model=rt.CyrusModelMerge(catalog,entry)
        result=dict(status="imported",seconds=time.perf_counter()-started,before=before,after_nodes=len(rt.objects),after_undo=names(),
                    model_handle=int(rt.getHandleByAnim(model)),model_class=str(rt.classOf(model.baseObject)),
                    polygons=[int(x) for x in rt.getPolygonCount(model)],node_scale=[float(model.scale[i]) for i in range(3)],
                    material_class=str(rt.classOf(model.material)) if model.material else None)
        value=base.PANEL.host.source_descriptor(model)
        result["geometry"]=value
        rt.execute("max undo")
        result["after_import_undo"]=dict(model_valid=bool(rt.isValidNode(model)),nodes=len(rt.objects),undo=names(),sentinel_x=float(sentinel.pos.x))
        rt.execute("max undo")
        result["after_sentinel_undo"]=dict(sentinel_x=float(sentinel.pos.x),nodes=len(rt.objects),undo=names())
        rt.execute("max redo");rt.execute("max redo")
        result["after_redo"]=dict(model_valid=bool(rt.isValidNode(model)),sentinel_x=float(sentinel.pos.x),nodes=len(rt.objects),undo=names())
    except Exception as exc:
        result=dict(status="failed",seconds=time.perf_counter()-started,error=str(exc),before=before,after_nodes=len(rt.objects),after_undo=names(),
                    selection=[int(rt.getHandleByAnim(rt.selection[i])) for i in range(len(rt.selection))])
    result.update(entry_id=entry_id,declared_scene_sha256=str(entry.SceneHash),scope="Existing local importer on owned scene; measurement only, not MCP import approval/transaction qualification.")
    path=base.OUTPUT/("import-probe-"+entry_id+".json");path.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    return result
