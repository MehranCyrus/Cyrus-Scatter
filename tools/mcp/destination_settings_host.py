"""Owned destination readback probes. No production or model-callable hooks."""
from copy import deepcopy
import pymxs
from pymxs import runtime as rt
import host_fixture as base
ORIGINALS={}
SKIP=set()


def owners(identity):
    root=base.PANEL.host.controllers[identity]
    return root,list(root.layerObjects)


def state(identity):
    from cyrus_mcp.max_host import frozen
    from cyrus_mcp.contracts import digest
    root,layers=owners(identity)
    data=[]
    for owner in [root.baseObject,*layers]:
        fields={}
        for key in rt.AminScatterLayerFields:
            if str(key) in SKIP:continue
            fields[str(key)]=frozen(rt.getProperty(owner,key))
        data.append(dict(layer_id=str(owner.layerID),fields=fields,dirty=bool(owner.dirty),
            prepare_builds=int(owner.procPreparedBuilds),preview_builds=int(owner.previewBuildCount),density_bakes=int(owner.procDensityBakes)))
    return dict(settings_sha256=digest(data),layers=data,nodes=len(rt.objects),selected=[int(rt.getHandleByAnim(n)) for n in rt.selection],
        history=[str(v) for v in rt.theHold.GetUndoNames()],save_required=bool(rt.getSaveRequired()),
        publication=base.PANEL.host.publication_identity(root),solves=int(root.groupBuilds),time=str(rt.sliderTime),auto_key=bool(rt.animButtonState))


def command(data):
    global SKIP
    host=base.PANEL.host;action=data["action"]
    if action=="destination_step_guard":
        assert not ORIGINALS
        rt.execute("global CyrusMCPDestinationReadTrap=0")
        def deny(*args,**kwargs):raise AssertionError("Destination settings read invoked geometry/task fingerprinting")
        for key in ("fingerprint","mesh","source_descriptor"):
            ORIGINALS[key]=getattr(host,key);setattr(host,key,deny)
        ORIGINALS["destination_settings"]=host.destination_settings
        def traced(*args,**kwargs):
            before=int(rt.CyrusMCPDestinationReadTrap or 0)
            result=ORIGINALS["destination_settings"](*args,**kwargs)
            assert int(rt.CyrusMCPDestinationReadTrap or 0)==before,"Unsupported script controller was sampled"
            return result
        host.destination_settings=traced
        return dict(geometry_and_task_fingerprint_guard=True)
    if action=="destination_step_restore":
        for key,method in ORIGINALS.items():setattr(host,key,method)
        ORIGINALS.clear()
        if not data.get("keep_skip",False):SKIP.clear()
        return dict(restored=True)
    if action=="destination_step_state":return state(data["controller_id"])
    if action=="destination_step_observed_id":
        assert len(base.PANEL.service.observed)==1
        return dict(controller_id=next(iter(base.PANEL.service.observed)))
    root,layers=owners(data["controller_id"]);leaf=layers[0]
    if action=="destination_step_observe":
        base.PANEL.service.observe(root)
        return base.PANEL.service.connection()
    if action=="destination_step_pending":
        old=rt.CyrusPointSuspended;rt.CyrusPointSuspended=True
        try:
            with pymxs.undo(True,"Owned pending destination settings"),pymxs.animate(False):
                leaf.amount=125;leaf.randomSeed=305
                leaf.movXMinWU=-.15/host.metre;leaf.movXMaxWU=.35/host.metre
                leaf.procSelfOverride=False;leaf.procSelfEnabled=False;leaf.procSelfGap=.1/host.metre
                leaf.procLayerSelfEnabled=True;leaf.procLayerSelfMultiplier=1.75;leaf.procLayerSelfGap=.4/host.metre;leaf.procLayerSelfPlanar=True
                leaf.fallDensityCurve=rt.Array();leaf.fallScaleCurve=rt.Array();leaf.fallDensityGraph="";leaf.fallScaleGraph=""
                leaf.markInputDirty()
        finally:rt.CyrusPointSuspended=old
        return dict(layer_id=str(leaf.layerID),metres_per_unit=host.metre)
    if action=="destination_step_roundtrip":
        result=[]
        for category in data["categories"]:
            assert category in ("population","transforms","spacing")
            binding=rt.CyrusPresetMakeBinding(root.baseObject,leaf,category)
            encoded=str(rt.cyrusPresetEncode(category,"Same destination",rt.CyrusPresetCapture(binding)))
            before=state(data["controller_id"])
            changed=bool(rt.CyrusPresetApply(binding,rt.cyrusPresetDecode(encoded)))
            after=state(data["controller_id"])
            assert not changed and before==after,(category,changed)
            result.append(dict(category=category,changed=False,state_and_history_preserved=True))
        return dict(cases=result)
    if action=="destination_step_override":
        with pymxs.undo(True,"Owned explicit self spacing"),pymxs.animate(False):
            leaf.procSelfOverride=True;leaf.procSelfEnabled=True;leaf.procSelfMultiplier=2.;leaf.procSelfGap=.25/host.metre;leaf.procSelfPlanar=False
        return dict(layer_id=str(leaf.layerID))
    if action=="destination_step_curves":
        with pymxs.undo(True,"Owned stored curves"),pymxs.animate(False):
            leaf.fallDensityCurve=rt.Array(0.,.25,1.);leaf.fallScaleCurve=rt.Array(.5,1.,2.)
            leaf.fallDensityGraph="";leaf.fallScaleGraph=""
            leaf.fallDensityWidth=2./host.metre;leaf.fallScaleWidth=3./host.metre
        return dict(layer_id=str(leaf.layerID))
    if action=="destination_step_tracks":
        rt.CyrusMCPDestinationReadTrap=0
        script=rt.float_script();script.script="(CyrusMCPDestinationReadTrap+=1;0.0)"
        with pymxs.undo(True,"Owned unsupported settings track"):
            rt.setPropertyController(leaf,rt.Name("movXMinWU"),script)
            control=rt.bezier_float();rt.setPropertyController(leaf,rt.Name("movXMaxWU"),control)
            with pymxs.animate(True):
                with pymxs.attime(0):leaf.movXMaxWU=.35/host.metre
                with pymxs.attime(10):leaf.movXMaxWU=.5/host.metre
        SKIP={"movXMinWU","movXMaxWU"};rt.CyrusMCPDestinationReadTrap=0
        return dict(unsupported_class=str(rt.classOf(rt.getPropertyController(leaf,rt.Name("movXMinWU")))),
            animated_keys=int(rt.numKeys(rt.getPropertyController(leaf,rt.Name("movXMaxWU")))))
    if action=="destination_step_duplicate":
        assert len(layers)==2
        layers[1].layerID=layers[0].layerID
        assert str(layers[1].layerID)==str(layers[0].layerID)
        return dict(duplicate=True)
    raise ValueError("Unknown owned destination probe")
