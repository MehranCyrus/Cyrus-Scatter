-- Definitions only. Run in an explicitly launched disposable qualification host.
-- These wrappers count calls without querying inputs, forcing redraw or solving.
global CSIdleOldHeld,CSIdleOldPFKey,CSIdleOldPFTick,CSIdleHeld=0,CSIdlePFKeys=0,CSIdlePFTicks=0
global CSIdleInstall,CSIdleRemove,CSIdleSample
fn CSIdleInstall = (
    if CSIdleOldHeld!=undefined do throw "Idle probe already installed."
    CSIdleOldHeld=CyrusInteractionHeld;CSIdleOldPFKey=CyrusPFKey;CSIdleOldPFTick=CyrusPFTickImpl
    CSIdleHeld=0;CSIdlePFKeys=0;CSIdlePFTicks=0
    fn CyrusInteractionHeld = (CSIdleHeld+=1;CSIdleOldHeld())
    fn CyrusPFKey = (CSIdlePFKeys+=1;CSIdleOldPFKey())
    fn CyrusPFTickImpl sender args = (CSIdlePFTicks+=1;CSIdleOldPFTick sender args)
    true
)
fn CSIdleRemove = (
    if CSIdleOldHeld!=undefined do (
        CyrusInteractionHeld=CSIdleOldHeld;CyrusPFKey=CSIdleOldPFKey;CyrusPFTickImpl=CSIdleOldPFTick
        CSIdleOldHeld=undefined;CSIdleOldPFKey=undefined;CSIdleOldPFTick=undefined
    )
)
fn CSIdleSample node label = (
    local root=node.baseObject,view=CyrusPointOwner node
    local data=#(
        #("label",label),#("time_ms",timeStamp()),#("epoch",root.procEpoch),
        #("group_hits",root.groupHits),#("prepared_builds",for leaf in root.layerObjects collect leaf.procPreparedBuilds),
        #("prepared_hits",for leaf in root.layerObjects collect leaf.procPreparedHits),
        #("preview_builds",for leaf in root.layerObjects collect leaf.previewBuildCount),
        #("dirty",for leaf in root.layerObjects collect leaf.dirty),
        #("container_scans",for leaf in root.layerObjects collect leaf.containerScans),
        #("container_tests",for leaf in root.layerObjects collect leaf.containerTests),
        #("membership_builds",for leaf in root.layerObjects collect leaf.containerMembershipBuilds),
        #("interaction_checks",CSIdleHeld),#("ir_timer_calls",CSIdlePFTicks),#("render_key_calls",CSIdlePFKeys),
        #("bridge_builds",CyrusPFBuilds),#("bridge_error",CyrusPFLastError),
        #("live_callbacks",CyrusLiveChangeCalls),#("live_redraw_requests",CyrusLiveRedrawRequests),
        #("retained",if isValidNode view then cyrusRetainedStats view else #()),
        #("retained_mesh",if isValidNode view then cyrusRetainedMeshStats view else #())
    )
    CSPWriteText (MCPFixtureDir+label+".json") (CSPObject data)
    true
)
