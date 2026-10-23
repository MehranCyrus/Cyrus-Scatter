-- 0.86.9.1 focused live handle feedback checks. Owned Max 2027 only.
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/quality_validation/common.ms"
global DRun,DMake,DState,DLog,DTrace,DTraceOn=false,DEdit,DWatch,DStart,DSelected,DRead,DFlush,DBench
global DObserveSelection
if DObserveSelection==undefined do DObserveSelection=false
try(unregisterRedrawViewsCallback DLog)catch()

fn DRead = (
    if DObserveSelection do (
        local rows=(cyrusEditInspect DEdit 0 100)[4]
        for row in rows where row[8] do return row
    )
    (cyrusEditInspect DEdit 0 1)[4][1]
)
fn DState = (
    local row=DRead()
    #(timeStamp(),CyrusInteractionHeld(),row[11].translation,(cyrusEditHandleMatrix DEdit row[1] row[2]).translation,QRoot.procEpoch,QRoot.groupBuilds,cyrusEditLocalRevision DEdit,QLayer.procPreparedBuilds,row[5],(getTransformAxis QNode 0).translation)
)
fn DLog = (if DTraceOn and DTrace.count<2000 do append DTrace (DState()))
fn DFlush label = (
    local f=createFile (MCPFixtureDir+label+"-frames.tsv")
    format "time_ms\theld\tdelta\tdisplayed\tepoch\tbuilds\tedit_revision\tprepared\tid\tgizmo\n" to:f
    for row in DTrace do format "%\t%\t%\t%\t%\t%\t%\t%\t%\t%\n" row[1] row[2] row[3] row[4] row[5] row[6] row[7] row[8] row[9] row[10] to:f
    close f
)
fn DMake count layers:1 = (
    DTraceOn=false;DObserveSelection=false;try(unregisterRedrawViewsCallback DLog)catch()
    QSetup();QLayer.amount=count
    local first=QLayer
    if layers>1 do for i=2 to layers do (
        QRoot.newLayer();local leaf=QRoot.selectedLayer();QRoot.setLayerSurfaces leaf #(QSurface);leaf.addModelSource QModel
        leaf.amount=count;leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false
    )
    QLayer=first;QRoot.selectLayer 1;QRoot.viewportMode=1;QRoot.pointsPerPlant=1
    DEdit=CyrusScatterEdit();addModifier QNode DEdit
    QCalculate();CyrusPerfHeadless=false;CyrusPointSuspended=false
    viewport.setLayout #layout_1;viewport.setType #view_top;viewport.setRenderLevel #wireframe
    QSurface.isHidden=false;QModel.isHidden=true;select QSurface;max zoomext sel all;QSurface.isHidden=true
    select QNode;max modify mode;modPanel.setCurrentObject DEdit;max move;subObjectLevel=1
    QRoot.updateMode=2
    QRoot.refreshDisplay();CyrusViewportRedraw();completeRedraw();QSettle 400
    modPanel.setCurrentObject DEdit;subObjectLevel=1;cyrusEditSelect DEdit #(1);completeRedraw();QSettle 200
    DSelected=DRead();DStart=DState();DTrace=#();clearUndoBuffer()
    -- Saving clears retained drawing until its normal post-save reconstruction.
    -- Leave persistence to the separate lifecycle check, after drag observation.
    QSettle 200
    true
)
fn DBench count layers:1 = (
    DMake count layers:layers
    local f=createFile (MCPFixtureDir+"bench-"+(count as string)+"-"+(layers as string)+".tsv")
    format "count_per_layer\tlayers\toperation\titeration\tms\tepoch\tbuilds\n" to:f
    local timer=dotNetObject "System.Diagnostics.Stopwatch",saved=CyrusPointSuspended
    CyrusPointSuspended=true
    for step=1 to 8 do (
        timer.Restart();theHold.Begin();cyrusEditTransform DEdit 0 [0.1,0,0] (matrix3 1) false;theHold.Accept "Drag probe callback";timer.Stop()
        format "%\t%\tcallback_no_publication\t%\t%\t%\t%\n" count layers step timer.Elapsed.TotalMilliseconds QRoot.procEpoch QRoot.groupBuilds to:f
    )
    local pending=DState()
    QAssert (distance pending[3] DStart[3]>0.7 and distance pending[4] (DStart[4]+[0.8,0,0])<0.001 and pending[5]==DStart[5]) ("pending_"+(count as string)+"_"+(layers as string)) "Selected handles follow all authored deltas without publishing placements."
    for step=1 to 5 do (
        timer.Restart();completeRedraw();timer.Stop()
        format "%\t%\tredraw_edit_active\t%\t%\t%\t%\n" count layers step timer.Elapsed.TotalMilliseconds QRoot.procEpoch QRoot.groupBuilds to:f
    )
    subObjectLevel=0
    for step=1 to 5 do (
        timer.Restart();completeRedraw();timer.Stop()
        format "%\t%\tredraw_edit_inactive\t%\t%\t%\t%\n" count layers step timer.Elapsed.TotalMilliseconds QRoot.procEpoch QRoot.groupBuilds to:f
    )
    subObjectLevel=1;CyrusPointSuspended=saved
    timer.Restart();QCalculate();QRoot.refreshDisplay();CyrusViewportRedraw();completeRedraw();timer.Stop()
    format "%\t%\trelease_update\t1\t%\t%\t%\n" count layers timer.Elapsed.TotalMilliseconds QRoot.procEpoch QRoot.groupBuilds to:f
    QSettle 300;local settled=DState()
    QAssert (distance settled[4] (DStart[4]+[0.8,0,0])<0.001) ("settled_"+(count as string)+"_"+(layers as string)) "The final displayed handle reaches the authored position after publication."
    close f
)
fn DRun scenario = (
    case scenario of (
        "setup": (DMake 100;DTrace=#();DTraceOn=true;registerRedrawViewsCallback DLog;DLog();QAssert true "setup_ready" "Fresh Max 2027 scene and exact production pair ready for a pointer drag.")
        "physical_begin": (DObserveSelection=true;DTrace=#();DStart=DState();DTraceOn=true;try(unregisterRedrawViewsCallback DLog)catch();registerRedrawViewsCallback DLog;DLog();QAssert true "physical_armed" "Read-only selected-instance frame observer armed; no transform issued by script.")
        "physical_end": (
            QSettle 700;DLog();DTraceOn=false;unregisterRedrawViewsCallback DLog;DFlush "physical"
            local final=DState(),f=createFile (MCPFixtureDir+"physical-state.txt")
            format "before=%\nafter=%\nframes=%\n" DStart final DTrace.count to:f;close f
            QAssert (final[9]==DStart[9] and final[7]>DStart[7] and distance final[4] DStart[4]>0.01) "physical_moved" "The same selected instance received a real pointer gesture and changed its final position."
            local image=gw.getViewportDib();image.filename=MCPFixtureDir+"physical-after.png";save image;close image
        )
        "physical_verify": (
            local held=for row in DTrace where row[2] collect row
            QRequire (held.count>1) "No pointer-held frames were captured"
            local initial=undefined,changed=undefined
            for a in held where changed==undefined do for b in held where changed==undefined and b[9]==a[9] and b[1]>a[1] and distance b[3] a[3]>0.01 do (initial=a;changed=b)
            QAssert (changed!=undefined) "pointer_authored" "One stable selected instance changes its authored delta while the physical mouse button is held."
            QAssert (distance (changed[4]-initial[4]) (changed[3]-initial[3])<0.001 and initial[5]==changed[5] and initial[6]==changed[6]) "pointer_feedback_live" "The same selected handle follows its authored delta while the physical mouse is held; placements remain unchanged."
            QAssert (distance (changed[10]-initial[10]) (changed[3]-initial[3])<0.001) "pointer_gizmo_live" "Max's actual transform axis follows the selected movement during the held gesture."
            local final=DState()
            QAssert (final[9]==changed[9] and distance final[4] (initial[4]+changed[3]-initial[3])<0.001) "pointer_release_matches" "After release the same instance displays the exact authored movement."
            QAssert (distance final[10] final[4]<0.001) "pointer_gizmo_release" "After renderer commit Max's cached axis matches the final displayed instance."
            QAssert (final[5]==initial[5]+1 and final[6]==initial[6]+1) "pointer_one_publication" "One complete successor is published after the observed drag."
        )
        "bench": (DBench 100;DBench 10000;DBench 10000 layers:3)
        "setup_medium": (DMake 10000;DTrace=#();DStart=DState();QAssert true "medium_ready" "Ten thousand instances ready for the second pointer witness.")
        "feedback_manual": (
            DMake 100;QRoot.updateMode=1
            local fingerprint=QFingerprint(),epoch=QRoot.procEpoch,builds=QRoot.groupBuilds,revision=cyrusEditLocalRevision DEdit
            QLayer.amount=125;QRoot.identificationMode=2;QRoot.refreshIdentification();QSettle 500
            QAssert (QFingerprint()==fingerprint and QRoot.procEpoch==epoch and QRoot.groupBuilds==builds and QLayer.amount==125 and cyrusEditLocalRevision DEdit==revision) "feedback_manual" "Renderer feedback and deferred axis refresh preserve pending Manual population and authored Edit revision."
        )
        "lifecycle": (
            QRoot.refreshDisplay();CyrusViewportRedraw();completeRedraw();QSettle 500
            local before=QFingerprint(),position=(DState())[4]
            theHold.Begin();cyrusEditTransform DEdit 0 [12,0,0] (matrix3 1) false;theHold.Accept "Drag probe lifecycle"
            QCalculate();QRoot.refreshDisplay();CyrusViewportRedraw();completeRedraw();QSettle 200
            local after=QFingerprint();QAssert (distance (DState())[4] (position+[12,0,0])<0.001) "lifecycle_move" "Movement still commits correctly."
            max undo;QCalculate();QRoot.refreshDisplay();CyrusViewportRedraw();completeRedraw();QSettle 200;QAssert (QFingerprint()==before) "lifecycle_undo" "Undo restores the exact preceding complete output."
            max redo;QCalculate();QRoot.refreshDisplay();CyrusViewportRedraw();completeRedraw();QSettle 200;QAssert (QFingerprint()==after) "lifecycle_redo" "Redo restores the same moved output."
            theHold.Begin();cyrusEditTransform DEdit 0 [3,0,0] (matrix3 1) false;theHold.Cancel();QCalculate()
            QAssert (QFingerprint()==after) "lifecycle_cancel" "Cancelling movement retains the previous complete output."
            local scene=MCPFixtureDir+"ui91-edits.max"
            saveMaxFile scene quiet:true;loadMaxFile scene quiet:true useFileUnits:true
            QNode=getNodeByName "Q Scatter";QRoot=QNode.baseObject;QLayer=QRoot.layerObjects[1];DEdit=QNode.modifiers[1]
            CyrusPointSuspended=true;QCalculate()
            QAssert (QFingerprint()==after) "lifecycle_scene" "Saved scene reload preserves the edited publication exactly."
        )
        default: throw "Unknown drag probe scenario"
    )
)
