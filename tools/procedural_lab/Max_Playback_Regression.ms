-- Headless regression only. The launcher loads an exact private script/DLL pair.
-- It never opens an artist scene, installs files, or measures presented FPS.
global PTLog,PTNode,PTRoot,PTLeaf,PTSurface,PTSource,PTChecks=0
global cyrusPlaybackProbe
fn PTAssert condition message = (if not condition do throw message;PTChecks+=1)
fn PTRecord message = (format "PASS %\n" message to:PTLog;flush PTLog)
fn PTStopQueues = (
    CyrusPFTimer.Stop();CyrusPFCheckPending=false;CyrusReleaseTimer.Stop()
    CyrusPointPending=false;CyrusWasDragging=false
)
fn PTDraw = (for entry in PTRoot.layerEntries() do entry[2].previewCache interactionHeld:false)
fn PTCounts = (
    #(PTRoot.procEpoch,PTRoot.groupBuilds,CyrusPFBuilds,(PTRoot.inputTimeStats())[1],(PTRoot.inputTimeStats())[2],
      for leaf in PTRoot.layerObjects collect #((leaf.previewStats())[1],(leaf.paintCacheStats())[1],(leaf.procStatistics())[3],(leaf.inputTimeStats())[1],(leaf.inputTimeStats())[2]))
)
fn PTLayout = (cyrusEditFingerprint (PTLeaf.placements (PTLeaf.validSources()) previewOnly:true) "playback")
fn PTNew policy = (
    resetMaxFile #noPrompt;sliderTime=0
    AminScatterNodeEvents.enabled=false -- timeline policy isolated from delayed node batches
    PTSurface=plane name:"PT_Surface" width:1000 length:1000 widthsegs:2 lengthsegs:2
    PTSource=box name:"PT_Source" width:8 length:8 height:20 pos:[1600,0,0]
    hide PTSource
    PTNode=AminScatterObject name:"PT_Controller";PTRoot=PTNode.baseObject
    PTRoot.setLayerTransfer true
    PTRoot.autoRender=false;PTRoot.updateMode=1;PTRoot.surfaceNodes=#(PTSurface);PTRoot.showCenters=true
    PTRoot.newLayer();PTLeaf=PTRoot.selectedLayer()
    PTLeaf.sources=#(PTSource);PTLeaf.sourceWeights=#(1.0);PTLeaf.amount=120
    PTRoot.setLayerTransfer false
    if policy>=2 do PTRoot.groupConversion()
    if policy==3 do PTRoot.procUpgrade()
    PTRoot.updateMode=2;PTRoot.refreshAll();PTDraw();PTStopQueues()
    PTAssert (PTLeaf.previewError=="") ("Fixture failed: "+PTLeaf.previewError)
    PTAssert (PTLeaf.generatedCount==120) "Fixture count differs"
    PTAssert (findItem CyrusTimeOwners PTNode>0) "Evaluated Scatter was not registered"
    if cyrusPlaybackProbe!=undefined do (format "%\n" (cyrusPlaybackProbe PTLeaf PTSurface) to:PTLog;flush PTLog)
    PTAssert ((PTLeaf.inputTimeStats())[5][3]) "Static inputs did not report FOREVER"
)
fn PTUnrelated policy = (
    PTNew policy
    local car=box name:"PT_UnrelatedCar" width:15 length:25 height:10 pos:[-2000,0,0]
    with animate on (at time 0 car.pos=[-2000,0,0];at time 20 car.pos=[-1000,0,0])
    -- Exercise the real dependency classifier independently of callback delivery.
    AminScatterLiveChanged #controllerOtherEvent #(getHandleByAnim car)
    PTDraw();PTStopQueues()
    local before=PTCounts(),layout=PTLayout(),baseKey=PTLeaf.paintBaseInputKey (PTLeaf.validSources()) true
    local groupKey=PTRoot.groupInputKey(),renderKey=CyrusPFKey()
    local dirtyState=#(PTRoot.dirty,PTLeaf.dirty)
    CyrusDensityMapChanged undefined
    PTAssert ((PTCounts() as string)==(before as string) and (#(PTRoot.dirty,PTLeaf.dirty) as string)==(dirtyState as string)) "Missing texture notification invalidated unrelated owners"
    for frame in #(1,5,10,20,5,0) do (
        sliderTime=frame
        PTAssert (not AminScatterLiveTime()) "Unrelated animation requested Scatter redraw"
        PTDraw()
        PTAssert ((PTCounts() as string)==(before as string)) "Unrelated animation did Scatter work"
        PTAssert ((PTLeaf.paintBaseInputKey (PTLeaf.validSources()) true)==baseKey) "Static candidate key includes clock time"
        PTAssert (PTRoot.groupInputKey()==groupKey) "Static group key includes clock time"
        PTAssert (CyrusPFKey()==renderKey) "Unrelated time changed the render transport key"
        PTAssert (not CyrusPFCheckPending and not CyrusPFTimer.Enabled and not CyrusReleaseTimer.Enabled) ("Static playback armed deferred work: "+(#(policy,frame,CyrusPFCheckPending,CyrusPFTimer.Enabled,CyrusReleaseTimer.Enabled,CyrusPointPending) as string))
    )
    PTAssert (PTLayout()==layout) "Static layout changed during unrelated animation"
    PTRecord ("unrelated animation and rewind, policy "+policy as string)
    PTLeaf.amount=170;PTDraw()
    PTAssert (PTLeaf.generatedCount==170) "A real parameter edit did not rebuild"
    PTStopQueues();before=PTCounts();sliderTime=12;AminScatterLiveTime();PTDraw()
    PTAssert ((PTCounts() as string)==(before as string)) "Static validity was not re-armed after parameter edit"
    PTRecord ("parameter edit re-arms validity, policy "+policy as string)
)
fn PTAnimatedReceiver policy parented:false = (
    PTNew policy
    local target=PTSurface
    if parented do (target=point name:"PT_AnimatedParent";PTSurface.parent=target)
    with animate on (at time 0 target.pos=[0,0,0];at time 10 target.pos=[0,0,100])
    AminScatterLiveChanged #controllerOtherEvent #(getHandleByAnim target)
    PTDraw();PTStopQueues()
    local layout=PTLayout(),before=PTCounts()
    sliderTime=10;AminScatterLiveTime();PTDraw()
    local rows=PTLeaf.placements (PTLeaf.validSources()) previewOnly:true
    PTAssert (rows.count==120) "Animated receiver lost its population"
    for row in rows do PTAssert (abs(row[1].row4.z-100)<0.01) "Animated receiver/parent did not move placements"
    PTAssert ((PTCounts() as string)!=(before as string)) "Animated receiver was frozen"
    PTStopQueues();before=PTCounts();AminScatterLiveTime();PTDraw()
    PTAssert ((PTCounts() as string)==(before as string)) "Repeated notification at one time rebuilt"
    sliderTime=0;AminScatterLiveTime();PTDraw()
    PTAssert (PTLayout()==layout) "Receiver rewind changed the seeded layout"
    PTRecord ((if parented then "animated receiver parent" else "animated receiver")+", policy "+policy as string)
    PTRoot.updateMode=1;PTRoot.layerEntries();PTStopQueues();before=PTCounts()
    for frame in #(1,5,10,0) do (sliderTime=frame;AminScatterLiveTime();PTDraw())
    PTAssert ((PTCounts() as string)==(before as string)) "Manual playback did calculation or validity queries"
    PTRoot.updateMode=2;PTDraw()
    PTAssert (PTLeaf.previewError=="") "Returning to Live failed"
    PTRecord ("Manual freeze and return to Live, policy "+policy as string)
)
fn PTAnimatedSource = (
    PTNew 3;PTRoot.viewportMode=3;PTRoot.showCenters=false
    with animate on (at time 0 PTSource.height=20;at time 10 PTSource.height=80)
    AminScatterLiveChanged #geometryChanged #(getHandleByAnim PTSource)
    PTDraw();PTStopQueues()
    local before=PTCounts(),key=PTLeaf.paintBaseInputKey (PTLeaf.validSources()) true
    sliderTime=10;AminScatterLiveTime();PTDraw()
    PTAssert ((PTLeaf.paintBaseInputKey (PTLeaf.validSources()) true)!=key) "Animated source geometry key did not change"
    PTAssert ((PTCounts() as string)!=(before as string)) "Animated source preview was frozen"
    PTAssert (PTLeaf.previewError=="") "Animated source caused an error"
    PTRecord "animated source geometry in Mesh mode"
)
fn PTAnimatedParameter = (
    PTNew 3
    with animate on (at time 0 PTLeaf.amount=120;at time 10 PTLeaf.amount=240)
    PTLeaf.markInputDirty();PTDraw();PTStopQueues()
    PTAssert (PTLeaf.generatedCount==120) "Scatter amount did not receive animation keys"
    sliderTime=10;AminScatterLiveTime();PTDraw()
    PTAssert (PTLeaf.generatedCount==240) "Animated Scatter parameter was frozen"
    PTRecord "animated Scatter parameter"
)
fn PTAnimatedDensity = (
    PTNew 3
    local map=Checker color1:black color2:black
    with animate on (at time 0 (map.color1=black;map.color2=black);at time 10 (map.color1=white;map.color2=white))
    PTLeaf.distributionMode=3;PTLeaf.densityMap=map;PTDraw();PTStopQueues()
    PTAssert (PTLeaf.generatedCount==0) "Black density did not filter all plants"
    sliderTime=10;AminScatterLiveTime();PTDraw()
    PTAssert (PTLeaf.generatedCount==120) "Animated density map was frozen"
    PTRecord "animated density map"
)
fn PTDensityEdits policy = (
    PTNew policy
    local map=Checker color1:black color2:black
    PTLeaf.distributionMode=3;PTLeaf.densityMap=map;PTDraw();PTStopQueues()
    PTAssert (PTLeaf.generatedCount==0) "Static black density did not filter all plants"
    local revision=PTLeaf.procDensityRevision
    map.color1=white;map.color2=white
    PTAssert (PTLeaf.procDensityRevision>revision) "In-place texture edit did not notify its owner"
    PTDraw();PTStopQueues()
    PTAssert (PTLeaf.generatedCount==120) "Static density-map edit was stale"
    local before=PTCounts();sliderTime=10;AminScatterLiveTime();PTDraw()
    PTAssert ((PTCounts() as string)==(before as string)) "Settled density edit still rebuilt on time change"
    PTRoot.updateMode=1;PTDraw();PTStopQueues();before=PTCounts()
    map.color1=black;map.color2=black;PTDraw()
    PTAssert (PTLeaf.generatedCount==120) "Manual density edit published without Update"
    -- Dirty notifications may update state; they must not prepare or publish.
    PTAssert ((PTCounts() as string)==(before as string)) "Manual density edit did calculation"
    PTRoot.refreshAll();PTDraw();PTStopQueues()
    PTAssert (PTLeaf.generatedCount==0) "Manual density edit did not apply on explicit Update"
    PTRecord ("in-place density edit and Manual Update, policy "+policy as string)
)
fn PTProceduralReceiver = (
    PTNew 3
    local controller=position_script()
    controller.script="[0,0,F*10]"
    PTSurface.position.controller=controller
    PTAssert (numKeys controller<=0) "Script-controller fixture unexpectedly has keys"
    AminScatterLiveChanged #controllerStructured #(getHandleByAnim PTSurface)
    PTDraw();PTStopQueues()
    PTAssert (not (PTLeaf.inputTimeStats())[5][3]) "A procedural transform was incorrectly treated as constant"
    local layout=PTLayout()
    sliderTime=10;AminScatterLiveTime();PTDraw()
    for row in (PTLeaf.placements (PTLeaf.validSources()) previewOnly:true) do
        PTAssert (abs(row[1].row4.z-100)<0.01) "Unkeyed script transform was frozen"
    sliderTime=0;AminScatterLiveTime();PTDraw()
    PTAssert (PTLayout()==layout) "Procedural transform rewind changed the seeded layout"
    PTRecord "unkeyed script transform and rewind"
)
fn PTSkippedOwners = (
    PTNew 3
    with animate on (at time 0 PTSurface.pos=[0,0,0];at time 10 PTSurface.pos=[0,0,100])
    PTLeaf.markInputDirty();PTDraw();PTStopQueues()
    PTRoot.layerEnabled[1]=false;PTDraw();PTStopQueues()
    local before=PTCounts();sliderTime=10
    PTAssert (not AminScatterLiveTime()) "Disabled layer requested time work"
    PTAssert ((PTCounts() as string)==(before as string)) "Disabled layer did time work"
    PTRoot.layerEnabled[1]=true;PTDraw();PTStopQueues()
    PTRoot.cyrusEnabled=false;PTStopQueues();before=PTCounts();sliderTime=0
    PTAssert (not AminScatterLiveTime()) "Disabled controller requested time work"
    PTAssert ((PTCounts() as string)==(before as string)) "Disabled controller did time work"
    PTRoot.cyrusEnabled=true;PTDraw();PTStopQueues();hide PTNode;before=PTCounts();sliderTime=10
    PTAssert (not AminScatterLiveTime()) "Hidden controller requested time redraw"
    PTAssert ((PTCounts() as string)==(before as string)) "Hidden controller did time work"
    unhide PTNode;PTDraw()
    for row in (PTLeaf.placements (PTLeaf.validSources()) previewOnly:true) do
        PTAssert (abs(row[1].row4.z-100)<0.01) "Showing controller failed to catch up its animated input"
    PTRecord "disabled layer/controller and hidden controller catch-up"
)
fn PTDisplayModes = (
    for mode=1 to 3 do (
        PTNew 3
        PTRoot.groupCenters=false;PTRoot.viewportMode=mode;PTRoot.pointsPerPlant=12
        PTRoot.refreshDisplay();PTDraw();CyrusPointSync();PTStopQueues()
        PTAssert (PTLeaf.viewportMode==mode and not PTLeaf.showCenters) "Viewport fixture did not select its actual mode"
        PTAssert (PTLeaf.previewError=="") "Viewport mode failed to build"
        local owner=CyrusPointOwner PTNode
        local before=PTCounts(),retained=if isValidNode owner then cyrusRetainedStats owner else #()
        for frame in #(1,5,10,0) do (
            sliderTime=frame;AminScatterLiveTime();PTDraw();CyrusPointSync()
            PTAssert ((PTCounts() as string)==(before as string)) "Static viewport mode rebuilt during playback"
            if isValidNode owner do (
                local now=cyrusRetainedStats owner
                for i in #(3,4,5,6,7,13) do PTAssert (now[i]==retained[i]) "Unchanged retained data was prepared, published or uploaded again"
            )
        )
        PTRecord ("static playback and repeated retained publication, viewport mode "+mode as string)
    )
)
fn PTPointCulling = (
    PTNew 3
    PTSurface.pos=[100000,100000,0]
    PTRoot.groupCenters=false;PTRoot.viewportMode=1;PTRoot.pointsPerPlant=12
    PTRoot.refreshAll();CyrusPointSync();redrawViews();PTStopQueues()
    for row in (PTLeaf.placements (PTLeaf.validSources()) previewOnly:true) do PTAssert (row[1].row4.x>90000 and row[1].row4.y>90000) "Off-screen fixture did not move its actual placements"
    local owner=CyrusPointOwner PTNode
    PTAssert (isValidNode owner) "Off-screen fixture has no retained display owner"
    local cache=PTLeaf.previewCache interactionHeld:false
    local styles=#(#(PTLeaf.pointColorMode==1,PTLeaf.solidPointColor)),state=cyrusRetainedStats owner
    PTAssert (state[1]>0 and state[5]>0) "Off-screen point items were not submitted"
    PTAssert (cyrusRetainedMatches owner #(cache) styles) "Submitted point items failed matching after moving off-screen"
    format "POINT_CULLING_STATE %\n" state to:PTLog;flush PTLog
    local before=PTCounts(),endTime=timeStamp()+500
    while timeStamp()<endTime do (dotNetClass "System.Windows.Forms.Application").DoEvents()
    PTAssert ((PTCounts() as string)==(before as string)) "Off-screen point data did background calculation"
    PTAssert (not CyrusReleaseTimer.Enabled and not CyrusPointPending) "Culled point buffers caused recurring release work"
    PTRecord "submitted off-screen point data matches and settles without realization polling"
)
fn PTSceneLifecycle = (
    PTNew 3
    PTAssert (findItem CyrusTimeOwners PTNode>0) "Attached Scatter was not registered"
    local scene=PTDir+"disposable.max"
    PTAssert (saveMaxFile scene quiet:true) "Disposable scene did not save"
    resetMaxFile #noPrompt
    PTAssert (CyrusTimeOwners.count==0) "Scene reset retained old Scatter owners"
    PTAssert (loadMaxFile scene quiet:true) "Disposable scene did not reopen"
    PTNode=getNodeByName "PT_Controller";PTRoot=PTNode.baseObject;PTLeaf=PTRoot.layerObjects[1]
    PTAssert (CyrusTimeOwners.count==1 and CyrusTimeOwners[1]==PTNode) "Reopened Scatter was not registered exactly once"
    PTDraw();PTStopQueues()
    local before=PTCounts();sliderTime=10;AminScatterLiveTime();PTDraw()
    PTAssert ((PTCounts() as string)==(before as string)) "Reopened static scene rebuilt on time change"
    delete PTNode;CyrusPruneTimeOwners()
    PTAssert (CyrusTimeOwners.count==0) "Deleted Scatter owner was retained"
    PTRecord "registry save/reopen/reset/delete"
)
PTLog=createFile (PTDir+"result.txt")
try (
    PTAssert ((maxVersion())[1]==29000) "Wrong Max host"
    PTAssert (cyrusScatterInputValidity!=undefined) "Wrong native binary: validity primitive missing"
    local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(),modules=process.Modules
    local loaded=createFile (PTDir+"loaded-native.txt"),expected=PTNativeExpected
    for i=0 to modules.Count-1 do (
        local dll=modules.Item[i]
        if findItem expected (filenameFromPath dll.FileName)>0 do (
            local bytes=(dotNetClass "System.IO.File").ReadAllBytes dll.FileName
            local sha=(dotNetClass "System.Security.Cryptography.SHA256").Create()
            local hash=(dotNetClass "System.BitConverter").ToString (sha.ComputeHash bytes)
            format "%|%|%\n" (filenameFromPath dll.FileName) dll.FileName (toLower (substituteString hash "-" "")) to:loaded
            sha.Dispose()
        )
    )
    close loaded
    format "SCRIPT_PAYLOAD %\n" CyrusLoadedScriptFingerprint to:PTLog;flush PTLog
    for policy=1 to 3 do (PTUnrelated policy;PTAnimatedReceiver policy;PTDensityEdits policy)
    PTAnimatedReceiver 3 parented:true
    PTAnimatedSource();PTAnimatedParameter();PTAnimatedDensity();PTProceduralReceiver();PTSkippedOwners();PTDisplayModes();PTPointCulling();PTSceneLifecycle()
    if doesFileExist (PTDir+"analyzer-fixture.ms") do fileIn (PTDir+"analyzer-fixture.ms")
    PTStopQueues()
    format "SUCCESS % assertions\n" PTChecks to:PTLog;close PTLog
) catch (
    format "FAILED after % assertions: %\n" PTChecks (getCurrentException()) to:PTLog;close PTLog
    throw()
)
