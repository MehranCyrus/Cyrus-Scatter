-- Owned loaded-scene/application callback regression; no artist-file writes.
global CBCOwner,CBCRoot,CBCLeaf,CBCWall
(
    if not matchPattern GardenRun pattern:"*/build/callback08755-20261028-01/host-*/" do throw "Owned hotfix host required."
    if theHold.Holding() or theHold.IsSuspended() do throw "An authored operation is active."
    local failure="",beforeTime=sliderTime,report=stringStream ""
    try (
        if not loadMaxFile @"F:\Cursor\_Cyrus_Apps\CyrusScatter\Test Scene\Interaction 0.87.5.4\Scene_Collider_Grass_0.87.5.4.max" quiet:true useFileUnits:true missingDLLsAction:#logmsg do throw "Could not load the preserved grass trial."
        local owners=for node in objects where classof node.baseObject==AminScatterObject and node.baseObject.overlapOwner==undefined collect node
        if owners.count!=1 do throw "Expected one grass trial controller."
        CBCOwner=owners[1];CBCRoot=CBCOwner.baseObject;CBCLeaf=CBCRoot.layerObjects[1];CBCWall=CBCRoot.interactionSceneColliders[1]
        if not isValidNode CBCWall do throw "The ordinary wall reference was not retained."
        CBCRoot.refreshAll();CBCRoot.interactionsEnsure();CyrusPointSync()
        local epoch=CBCRoot.procEpoch,builds=CBCRoot.groupBuilds,count=CBCLeaf.amount,old= CBCWall.transform
        if count!=1000 do throw "Expected the 1,000-grass input."
        CBCRoot.updateMode=1;CBCLeaf.amount=count+1
        CBCRoot.liveTimeChanged();AminScatterLiveTime()
        sliderTime=1f;AminScatterLiveTime();sliderTime=0f;AminScatterLiveTime()
        AminScatterLiveChanged #controllerOtherEvent #(getHandleByAnim CBCWall)
        CBCRoot.layerEntries includeDisabled:true
        CBCWall.pos+= [30,0,0]
        CBCRoot.interactionSceneDirty=true;CyrusSceneColliderTick()
        if CBCRoot.procEpoch!=epoch or CBCRoot.groupBuilds!=builds do throw "Contact/time callbacks published pending Manual placements."
        if CBCRoot.interactionError!="" do throw CBCRoot.interactionError
        format "PASS loaded 1000 plants; direct application callbacks; scene transform; Manual pending count retained.\n" to:report
        format "epoch=% group_builds=% pending_amount=%\n%" CBCRoot.procEpoch CBCRoot.groupBuilds CBCLeaf.amount (CBCRoot.interactionsStatistics()) to:report
        CBCWall.transform=old;CBCLeaf.amount=count;CBCRoot.refreshAll();CBCRoot.interactionsEnsure();CyrusPointSync()
        CBCRoot.newLayer();CBCRoot.liveTimeChanged();AminScatterLiveTime()
        if CBCRoot.layerObjects.count!=3 do throw "The empty-layer lifecycle case was not created."
        format "\nPASS added empty layer and repeated callbacks.\n" to:report
    )catch(failure=getCurrentException();format "FAILED %\n%" failure (getCurrentExceptionStackTrace()) to:report)
    sliderTime=beforeTime
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+"populated-regression.txt") (report as string)
    if failure!="" do throw failure
)
