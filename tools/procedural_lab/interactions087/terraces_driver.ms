(
global TCount,TOwner,TRoot,TEdit,TRocks,TSettle,TAssert,TWrite,TGeneration
fn TAssert v msg=(if not v do throw msg;true)
fn TWrite name content=((dotNetClass "System.IO.File").WriteAllText (GardenRun+name) content)
fn TSettle ms=(local end=timeStamp()+ms;while timeStamp()<end do (windows.processPostedMessages();(dotNetClass "System.Windows.Forms.Application").DoEvents();redrawViews()))
fn TGeneration = (local m=(dotNetClass "System.Text.RegularExpressions.Regex").Match (TRoot.interactionsStatistics()) "\"generation\":([0-9]+)";m.Groups.Item[1].Value as integer64)
local log=createFile (GardenRun+"moves.tsv")
format "tier\tstep\tcommand_ms\tredraw_ms\tepoch\tbuilds\tposition\n" to:log
for tier in #(0,10000,50000,250000) do (
    TCount=tier
    python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/procedural_lab/interactions087/terraces_phase.py"
    TAssert (doesFileExist (GardenRun+"phase-"+(tier as string)+"-ok.txt")) "Terrace tier setup failed."
    viewport.setLayout #layout_1;viewport.setType #view_top;viewport.setRenderLevel #smoothhighlights
    local receiver=getNodeByName "087 Contact study receiver";unhide receiver;select receiver;max zoomext sel all;hide receiver
    select TOwner;max modify mode;modPanel.setCurrentObject TEdit;subObjectLevel=1;max move
    cyrusEditActiveLayers TEdit #(TRocks.editLayerKey);cyrusEditSelect TEdit #(1);completeRedraw();TSettle 300
    local epoch=TRoot.procEpoch,builds=TRoot.groupBuilds,watch=dotNetObject "System.Diagnostics.Stopwatch"
    local before=(cyrusEditHandleMatrix TEdit TRocks.editLayerKey 1).translation
    for step=1 to 8 do (
        local generation=TGeneration()
        watch.Restart();undo "Terrace individual stone" on cyrusEditTransform TEdit 0 [2,0,0] (matrix3 1) false;watch.Stop()
        local command=watch.Elapsed.TotalMilliseconds
        TAssert ((TGeneration())>generation) "The contact generation must advance during each individual stone move."
        TAssert ((findString (TRoot.interactionsStatistics()) "\"error\":\"\"")!=undefined) "A native contact successor was rejected."
        TWrite ((tier as string)+"-move-"+(step as string)+".json") (TRoot.interactionsStatistics())
        watch.Restart();completeRedraw();watch.Stop();local redraw=watch.Elapsed.TotalMilliseconds
        TSettle 40
        local pos=(cyrusEditHandleMatrix TEdit TRocks.editLayerKey 1).translation
        TAssert (distance pos (before+[step*2,0,0])<0.01) "Individual stone handle must follow every command."
        TAssert (TRoot.procEpoch==epoch and TRoot.groupBuilds==builds) "A stone drag must not rebuild static placements."
        TAssert (TRoot.interactionError=="") "A contact successor failed."
        format "%\t%\t%\t%\t%\t%\t%\n" tier step command redraw TRoot.procEpoch TRoot.groupBuilds pos to:log;flush log
    )
)
close log
TCount=-1
python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/procedural_lab/interactions087/terraces_phase.py"
TAssert (doesFileExist (GardenRun+"phase--1-ok.txt")) "Final mixed garden setup failed."
local eye=[-7750,-3650,-700],target=[-8000,-3100,-950],look=normalize(target-eye),right=normalize(cross look [0,0,1]),up=normalize(cross right look)
viewport.setType #view_persp_user;viewport.setTM (inverse(matrix3 right up (-look) eye));viewport.setRenderLevel #smoothhighlights
select TOwner;modPanel.setCurrentObject TEdit;subObjectLevel=1;cyrusEditActiveLayers TEdit #(TRocks.editLayerKey);cyrusEditSelect TEdit #(1)
completeRedraw();TSettle 500
saveMaxFile (GardenRun+"Terraces_CyrusScatter_087_Interactions.max") quiet:true
TSettle 500
local image=gw.getViewportDib();image.filename=GardenRun+"terrace-preview.png";save image;close image
TWrite "completed.json" "{\"status\":\"pass\",\"host\":2027,\"scope\":\"Fixed foreground and full terrace tiers, eight individual Cyrus Edit stone moves each, no static placement rebuild; mixed dense foreground saved. Timings are CPU commands and synchronous redraw, not presented FPS.\"}"
)
