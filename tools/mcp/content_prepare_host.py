"""Owned content-build process. Never shipped or exposed through MCP."""
import json
from pathlib import Path
import time
import traceback
import pymxs
from pymxs import runtime as r
from PySide6 import QtCore
import host_fixture as base

STATE=None
TIMER=None
CATALOG=None
ITEMS=[]
JOB=None
STAGE=None
CURRENT=None
BUSY=False

def save():
    (base.OUTPUT/"content-preparation.json").write_text(json.dumps(STATE,indent=2)+"\n",encoding="utf-8")

def start(root,output,ids):
    global STATE,TIMER,CATALOG,ITEMS
    output=Path(output).resolve();assert output.is_relative_to(base.OUTPUT.parent.resolve())
    r.execute('dotNet.loadAssembly (pathConfig.appendPath CyrusRecipeScriptDirectory "CyrusGallery.dll")')
    CATALOG=r.execute('dotNetObject "CyrusScatter.UI.IndividualModelCatalog"')
    CATALOG.Load(root,str(r.CyrusLibraryVersion()),2027)
    ITEMS=[CATALOG.MatchingAt("","",i) for i in range(int(CATALOG.Count))]
    ITEMS.sort(key=lambda entry:str(entry.Id))
    STATE=dict(status="running",output=str(output),entries=[],requested_ids=ids,remaining=len(ITEMS),
               qualification="Owned Max 2027 derivative preparation only; no artist-scene import, MCP readiness or renderer-output qualification.")
    TIMER=QtCore.QTimer(base.PANEL);TIMER.setInterval(150);TIMER.timeout.connect(tick);TIMER.start();save()
    return dict(started=True,entries=len(ITEMS))

def cleanup():
    global JOB,STAGE
    if JOB is not None:r.cyrusAssetPackageRelease(JOB);JOB=None
    if STAGE is not None:r.CyrusAssetRemoveStage(STAGE);STAGE=None

def prepare(entry):
    global JOB,STAGE,CURRENT
    output=Path(STATE["output"]);folder=output/str(entry.Id);folder.mkdir()
    r.resetMaxFile(r.Name("noPrompt"));r.units.SystemType=r.Name("Meters");r.units.SystemScale=1.0
    r.CyrusPointSuspended=True
    CATALOG.VerifyScene(entry)
    source=r.CyrusModelMerge(CATALOG,entry)
    counts=[int(x) for x in r.getPolygonCount(source)]
    CURRENT.update(triangles=counts[0],vertices=counts[1])
    # Native portable admission precedes source/image copies.
    r.cyrusAssetMeshProfile(source)
    receiver=r.Plane(width=1,length=1,widthsegs=1,lengthsegs=1)
    node=r.AminScatterObject(name="Owned content source descriptor")
    root=node.baseObject;root.setLayerTransfer(True);root.layerID=r.CyrusNewLayerID();root.updateMode=1
    layer=r.createInstance(r.AminScatterObject);layer.setLayerTransfer(True);layer.layerID=r.CyrusNewLayerID()
    layer.logicalParentID="";layer.isPaintArea=False;layer.sources=r.Array(source);layer.surfaceNodes=r.Array(receiver)
    layer.totalCount=0;layer.procOrder=1;layer.procSetOrder=1;layer.setLayerTransfer(False)
    root.surfaceNodes=r.Array(receiver);root.layerObjects=r.Array(layer);root.layerNames=r.Array(str(entry.Name))
    root.layerEnabled=r.Array(True);root.layerVisible=r.Array(True);root.activeLayer=1;root.setLayerTransfer(False)
    bindings=r.Array();document=r.CyrusRecipeCapture(root,r.Array(layer),str(entry.Name),bindingResult=bindings)
    recipe=folder/"source.csrecipe.json";r.cyrusRecipeWrite(str(recipe),document)
    sha=str(r.cyrusRecipeInfo(str(recipe))[10]);STAGE=r.CyrusAssetOwnStage()
    graph,files=r.CyrusAssetCapture(root,str(recipe),sha,bindings,STAGE[0])
    CURRENT.update(materials=len(r.CyrusRecipeGet(graph,"materials")),maps=len(r.CyrusRecipeGet(graph,"maps")),
                   files=len(r.CyrusRecipeGet(graph,"files")),package=str(folder/"package"))
    JOB=r.cyrusAssetPackageStart(str(folder/"package"),str(recipe),sha,graph,files,
        "Private derivative of locally installed Cyrus content; original redistribution restrictions are retained.",1)

def tick():
    global CURRENT,JOB,BUSY
    if BUSY:return
    BUSY=True
    try:
        with pymxs.undo(False):
            if JOB is not None:
                value=r.cyrusAssetPackagePoll(JOB)
                if str(value[0])=="exporting":return
                if str(value[0])!="complete":raise RuntimeError("Native export failed: "+str(value))
                CURRENT.update(status="prepared",duration_seconds=time.monotonic()-CURRENT.pop("started"))
                cleanup();STATE["entries"].append(CURRENT);CURRENT=None;save()
            if not ITEMS:
                TIMER.stop();STATE.update(status="complete",remaining=0);r.CyrusPointSuspended=False;save();return
            entry=ITEMS.pop(0);STATE["remaining"]=len(ITEMS)
            CURRENT=dict(entry_id=str(entry.Id),name=str(entry.Name),scene_sha256=str(entry.SceneHash),scene_bytes=int(entry.SceneBytes),started=time.monotonic())
            if STATE["requested_ids"] and str(entry.Id) not in STATE["requested_ids"]:
                CURRENT.update(status="not_requested",reason="outside_explicit_preparation_selection")
            elif int(entry.SceneBytes)>64*1024**2:
                CURRENT.update(status="deferred",reason="requires_larger_owned_scene_preparation_budget")
            else:
                prepare(entry);save();return
            CURRENT.pop("started");STATE["entries"].append(CURRENT);CURRENT=None;save()
    except Exception:
        if CURRENT is not None:
            CURRENT.update(status="rejected",error=traceback.format_exc());CURRENT.pop("started",None)
            STATE["entries"].append(CURRENT);CURRENT=None
        else:STATE.update(status="failed",error=traceback.format_exc());TIMER.stop()
        cleanup();save()
    finally:BUSY=False
