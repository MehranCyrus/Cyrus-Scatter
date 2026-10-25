"""Owned proof of existing portable staging; no public MCP import or new store.

Run after the SDK planting slice. .max merge is limited to fixture preparation;
the operation measured here creates native meshes from an existing data package.
"""
import json
import time
import traceback
from pathlib import Path
import pymxs
from pymxs import runtime as r
import host_fixture as base

out=base.OUTPUT
assert "build" in out.parts and out.name=="host01"
receipt=out/"portable-source-probe.json"
result=dict(status="running",qualification="Owned native staging proof only; no MCP import authority, public tool, complete recipe-use or artist acceptance.")
stage=None
job=None
prepared=None

def names():return [str(v) for v in r.theHold.GetUndoNames()]
def handles():return sorted(int(r.getHandleByAnim(n)) for n in r.objects)
def wait(token,expected,terminal="complete"):
    deadline=time.monotonic()+30
    while True:
        state=r.cyrusAssetPackagePoll(token)
        if str(state[0])!=expected:break
        if time.monotonic()>=deadline:raise TimeoutError("Observe original native package worker before retrying")
        time.sleep(.05)
    assert str(state[0])==terminal,str(state)

try:
    assert not r.theHold.Holding(),"Start at idle; do not clear someone else's active hold"
    root=next(iter(base.PANEL.host.controllers.values())).baseObject
    bindings=r.Array()
    document=r.CyrusRecipeCapture(root,root.logicalLayers(),"Owned grass and flower sources",bindingResult=bindings)
    recipe=out/"portable-source.csrecipe.json"
    directory=out/"portable-source-package"
    if not recipe.exists():r.cyrusRecipeWrite(str(recipe),document)
    digest=str(r.cyrusRecipeInfo(str(recipe))[10])
    if not directory.exists():
        stage=r.CyrusAssetOwnStage()
        before=handles()
        graph,files=r.CyrusAssetCapture(root,str(recipe),digest,bindings,stage[0])
        assert handles()==before,"Capture changed scene nodes"
        job=r.cyrusAssetPackageStart(str(directory),str(recipe),digest,graph,files,"Owned private qualification; original library assets stay local.",1)
        wait(job,"exporting")
        r.cyrusAssetPackageRelease(job);job=None
        r.CyrusAssetRemoveStage(stage);stage=None
    prepared=r.cyrusAssetPackagePrepare(str(directory),str(out/"portable-source-bitmaps"))
    wait(prepared,"preparing","ready")
    package=r.cyrusAssetPackagePrepared(prepared,False)
    graph=r.CyrusRecipeGet(package,"graph")
    assert len(r.CyrusRecipeGet(graph,"nodes"))==2
    result.update(package=str(directory),nodes=2,materials=len(r.CyrusRecipeGet(graph,"materials")),maps=len(r.CyrusRecipeGet(graph,"maps")),
                  files=len(r.CyrusRecipeGet(graph,"files")),recipe_sha256=digest)
    sentinel=r.box(name="Owned portable Undo sentinel",width=.1,length=.1,height=.1)
    r.execute("global MCPPortableSentinel")
    r.MCPPortableSentinel=sentinel
    r.clearUndoBuffer()
    with pymxs.undo(True,"Owned prior portable edit"):
        sentinel.pos=r.Point3(7,0,0)
    original=handles();prior=names()
    result.update(prior_undo_names=prior,holding_before_stage=bool(r.theHold.Holding()))
    assert len(prior)==1 and not r.theHold.Holding(),str(result)
    with pymxs.undo(True,"Owned portable source import"):
        resolved=r.CyrusAssetStage(r.Array(graph,str(directory),prepared),r.Array())
        created=[n for n in r.objects if int(r.getHandleByAnim(n)) not in original]
        assert len(created)==2
        measured=[base.PANEL.host.source_descriptor(n) for n in created]
    accepted=names()
    assert accepted==prior+["Owned portable source import"],accepted
    pymxs.run_undo()
    assert handles()==original and names()==prior and float(sentinel.pos.x)==7
    pymxs.run_undo()
    assert abs(float(sentinel.pos.x))<1e-6
    pymxs.run_redo();pymxs.run_redo()
    assert len(handles())==len(original)+2 and float(sentinel.pos.x)==7
    assert all(r.isValidNode(n) for n in created)
    assert [base.PANEL.host.source_descriptor(n) for n in created]==measured
    result.update(prior_history_preserved=True,import_undo_removed_only_new_nodes=True,prior_undo_restored_artist_move=True,
                  redo_restored_meshes=True,measurements=measured,undo_before=prior,undo_after=accepted)
    before_failure=handles();history_before_failure=names()
    try:
        with pymxs.undo(True,"Owned failed portable staging"):
            r.CyrusAssetStage(r.Array(graph,str(directory),prepared),r.Array())
            raise RuntimeError("Owned injected failure after complete native staging")
    except RuntimeError:
        raise AssertionError("pymxs undo should consume the injected exception after rollback")
    assert handles()==before_failure and names()==history_before_failure
    result.update(status="passed",failed_successor_retained_existing_nodes_and_history=True)
except Exception:
    result.update(status="failed",error=traceback.format_exc())
    raise
finally:
    if stage is not None:r.CyrusAssetRemoveStage(stage)
    for token in (job,prepared):
        if token is not None:r.cyrusAssetPackageRelease(token)
    receipt.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
