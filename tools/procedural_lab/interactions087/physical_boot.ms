-- Owned Max 2027 terrace pointer qualification. Never loaded in artist profiles.
(
global TOwner,TRoot,TEdit,TRocks,PTrace,PWatching=false,PRead,PObserve,PArm,PFinish,PSettle
global PInspectOffset,PInputs
global MCPFixtureDir=GardenRun
global CyrusPerfHeadless,CyrusPointSuspended,CyrusPFResume
fn PSettle ms=(local end=timeStamp()+ms;while timeStamp()<end do (windows.processPostedMessages();redrawViews()))
loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/interactions087-pointer-20261025-05/Terraces_087_Artist_Stage.max" quiet:true useFileUnits:true
TOwner=getNodeByName "CyrusScatter 0.87 - Terrace contact study";TRoot=TOwner.baseObject;TEdit=TOwner.modifiers[1];TRocks=TRoot.layerObjects[6]
CyrusPerfHeadless=false;CyrusPointSuspended=false;CyrusPFResume=false
TRoot.identificationMode=4;TRoot.autoRender=true
local originalRock=getNodeByName "rock-foreground"
if isValidNode originalRock do (hide originalRock;originalRock.renderable=false)
TRoot.refreshAll();CyrusPointSync();completeRedraw();PSettle 500
select TOwner;max modify mode;modPanel.setCurrentObject TEdit;subObjectLevel=1;max move
completeRedraw();PSettle 300
cyrusEditActiveLayers TEdit #(TRocks.editLayerKey);cyrusEditSelect TEdit #(1)
completeRedraw();PSettle 300
local rockPosition=(cyrusEditHandleMatrix TEdit TRocks.editLayerKey 1).translation
-- The actual supplied boulder is a scatter instance, selected through Cyrus Edit.
viewport.setLayout #layout_1;viewport.setType #view_top;viewport.setRenderLevel #smoothhighlights
local frame=plane name:"087 temporary view frame" width:320 length:320 pos:rockPosition
select frame;max zoomext sel all;delete frame
select TOwner;max modify mode;modPanel.setCurrentObject TEdit;subObjectLevel=1;max move
cyrusEditActiveLayers TEdit #(TRocks.editLayerKey);cyrusEditSelect TEdit #(1)
completeRedraw();PSettle 500
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/procedural_lab/interactions087/pointer_observer.ms"
fn PArm=(
    try(unregisterRedrawViewsCallback PObserve)catch();PInspectOffset=undefined
    local total=(cyrusEditInspect TEdit 0 1)[2] as integer
    for offset=(amax 0 (total-2000)) to (total-1) by 500 do (
        local page=(cyrusEditInspect TEdit offset (amin 500 (total-offset)))[4]
        for i=1 to page.count where page[i][1]==TRocks.editLayerKey and page[i][2]==1 do PInspectOffset=offset+i-1
    )
    if PInspectOffset==undefined do throw "Selected stone's authored row was not found in the bounded trial history tail."
    PInputs=for leaf in TRoot.layerObjects collect #(leaf.amount,leaf.randomSeed)
    PTrace=#();PWatching=true;registerRedrawViewsCallback PObserve;PObserve()
    if PTrace.count==0 do (PWatching=false;unregisterRedrawViewsCallback PObserve;throw "Activate the trial viewport and wait for complete feedback before arming.")
    true
)
fn PFinish = (
    PSettle 300;PObserve();PWatching=false;unregisterRedrawViewsCallback PObserve
    local f=createFile (GardenRun+"pointer-frames.tsv")
    format "time_ms\theld\thandle\tgizmo\tcontact_generation\tepoch\tbuilds\tedit_revision\tstatistics\tpresented_stone\n" to:f
    for row in PTrace do format "%\t%\t%\t%\t%\t%\t%\t%\t%\t%\n" row[1] row[2] row[3] row[4] row[5] row[6] row[7] row[8] row[9] row[10] to:f
    close f
    local first=PTrace[1],last=PTrace[PTrace.count],witness=undefined
    for row in PTrace where row[2] and row[5]>first[5] and row[10]!=undefined and distance row[3] first[3]>0.01 and distance row[3] row[4]<0.05 and distance row[10] row[3]<0.05 do witness=row
    if witness==undefined do throw "No physical held-pointer frame proved updated contacts, renderer feedback and matching gizmo."
    if last[6]!=first[6] or last[7]!=first[7] do throw "Physical drag rebuilt static placements."
    if TRoot.interactionError!="" do throw TRoot.interactionError
    for i=1 to PInputs.count where TRoot.layerObjects[i].amount!=PInputs[i][1] or TRoot.layerObjects[i].randomSeed!=PInputs[i][2] do throw "A pointer gesture changed authored population inputs."
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+"pointer-result.json") ("{\"status\":\"pass\",\"frames\":"+(PTrace.count as string)+",\"held_generation\":"+((witness[5] as integer) as string)+",\"final_generation\":"+((last[5] as integer) as string)+",\"placement_epoch_unchanged\":true,\"authored_population_inputs_unchanged\":true,\"scope\":\"Actual Sky mouse drag, contact successor, renderer-committed stone feedback and Max gizmo updated before release; no presented FPS claim\"}")
    true
)
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/mcp/development_transport.ms"
(dotNetClass "System.IO.File").WriteAllText (GardenRun+"ready.json") "{\"status\":\"ready\",\"host\":2027,\"scope\":\"Owned terrace pointer fixture\"}"
)
