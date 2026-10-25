"""Private, separate-callback native package staging/Undo qualification."""
import json
from pathlib import Path
import pymxs
from pymxs import runtime as r
import host_fixture as base

TOKEN=None
PACKAGE=None
DIRECTORY=None
SENTINEL=None
CREATED=[]
STAGED=False

def state():
    return dict(nodes=sorted(int(r.getHandleByAnim(n)) for n in r.objects),undo=[str(v) for v in r.theHold.GetUndoNames()],
                holding=bool(r.theHold.Holding()),sentinel_x=float(SENTINEL.pos.x) if SENTINEL is not None else None,
                created_valid=[bool(r.isValidNode(n)) for n in CREATED],
                geometry=[base.PANEL.host.source_descriptor(n) for n in CREATED if r.isValidNode(n)],
                materials=[str(r.classOf(n.material)) for n in CREATED if r.isValidNode(n)])

def command(data):
    global TOKEN,PACKAGE,DIRECTORY,SENTINEL,CREATED,STAGED
    action=data["action"]
    assert not r.theHold.Holding(),"Fixture requires an idle host; no active hold is cleared"
    if action=="portable_step_prepare":
        DIRECTORY=Path(data["directory"]).resolve()
        assert DIRECTORY.is_relative_to(base.OUTPUT.parent.resolve())
        assert TOKEN is None
        TOKEN=r.cyrusAssetPackagePrepare(str(DIRECTORY),str(base.OUTPUT/"portable-bitmaps"))
        return dict(started=True)
    if action=="portable_step_poll":
        value=r.cyrusAssetPackagePoll(TOKEN)
        if str(value[0])=="ready":PACKAGE=r.cyrusAssetPackagePrepared(TOKEN,False)
        return dict(state=str(value[0]),phase=str(value[1]),error=str(value[3]))
    if action=="portable_step_prior":
        assert PACKAGE is not None
        SENTINEL=r.box(name="Owned portable prior-edit sentinel",width=.1,length=.1,height=.1)
        r.clearUndoBuffer()
        with pymxs.undo(True,"Owned prior portable edit"):
            SENTINEL.pos=r.Point3(7,0,0)
        return state()
    if action=="portable_step_stage":
        before=set(int(r.getHandleByAnim(n)) for n in r.objects)
        with pymxs.undo(True,"Owned portable source import"):
            r.CyrusAssetStage(r.Array(r.CyrusRecipeGet(PACKAGE,"graph"),str(DIRECTORY),TOKEN),r.Array())
        CREATED=[n for n in r.objects if int(r.getHandleByAnim(n)) not in before]
        assert len(CREATED)==2
        return state()
    if action=="portable_step_failure":
        STAGED=False
        with pymxs.undo(True,"Owned failed portable import"):
            r.CyrusAssetStage(r.Array(r.CyrusRecipeGet(PACKAGE,"graph"),str(DIRECTORY),TOKEN),r.Array())
            STAGED=True
            raise RuntimeError("Owned injected failure after native portable staging")
        assert STAGED,"Fault must occur after node staging"
        return state()
    if action=="portable_step_undo":pymxs.run_undo();return state()
    if action=="portable_step_redo":pymxs.run_redo();return state()
    if action=="portable_step_state":return state()
    if action=="portable_step_release":
        r.cyrusAssetPackageRelease(TOKEN);TOKEN=None;PACKAGE=None
        return dict(released=True)
    raise ValueError("Unknown private portable step")
