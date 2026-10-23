-- NEVER_SHIP build only. One late Nitrous failure after CPU Edit publication.
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/edit_0869/edit_workflow.ms"
global EWFailureRun,EWWaitDisplay
fn EWWaitDisplay wanted = (
    local deadline=timeStamp()+20000,record=undefined,state=undefined
    while timeStamp()<deadline do (
        for entry in CyrusViewportRecords where entry[1]==QNode do record=entry
        if record!=undefined and isValidNode record[2] do (
            cyrusRetainedMatches record[2] record[3] record[4]
            completeRedraw();QSettle 80;state=cyrusRetainedPresentationStats record[2]
            if state[4]==wanted and (wanted==3 or state[5]) do return state
        )
        QSettle 50
    )
    throw ("Edit feedback presentation timeout: "+(state as string))
)
fn EWFailureRun scenario = (
    QRequire (scenario=="late_failure" and cyrusOwnedPreviewFault!=undefined) "Recorded private preview-fault build required"
    try (
        cyrusOwnedPreviewFault 0 0;EWSetup twoLayers:false
        QRoot.viewportFaces=20000000;QRoot.viewportNavigationFaces=20000000;QRoot.setGroupDisplay 3
        CyrusPointSuspended=false;QRoot.refreshDisplay();CyrusViewportRedraw()
        local ready=EWWaitDisplay 2,before=EWVisible EWEdit,original=QFingerprint()
        QAssert (ready[5] and before.count==36) "E4_gpu_initial" "Initial Mesh and Edit feedback are ready in the actual Max viewport."
        cyrusEditCommand EWEdit 1 undefined;CyrusPointSuspended=true
        undo "EW pending mesh move" on cyrusEditTransform EWEdit 0 [20,30,4] (matrix3 1) false
        QCalculate();local authored=EWState EWEdit
        QAssert (QFingerprint()!=original) "E4_gpu_cpu_successor" "A moved CPU publication exists before renderer realization."
        cyrusOwnedPreviewFault 3 2;CyrusPointSuspended=false;QRoot.refreshDisplay();CyrusViewportRedraw()
        local failed=EWWaitDisplay 3,oldFeedback=EWVisible EWEdit,aligned=before.count==oldFeedback.count
        for i=1 to before.count do aligned=aligned and before[i][5]==oldFeedback[i][5] and EWNear before[i][13] oldFeedback[i][13]
        QAssert (failed[3]==ready[3] and failed[5] and failed[8] and aligned) "E4_gpu_feedback_retained" "Failure during the second Mesh group retains the old complete display and every handle's old final matrix."
        local refused=false
        try(cyrusEditTransform EWEdit 0 [1,0,0] (matrix3 1) false)catch(refused=true)
        local radiusRefused=false,radii=QLayer.procRadiusIDs as array,binding=QLayer.procRadiusBinding
        try(QLayer.procSelectedRadius 1 4)catch(radiusRefused=true)
        QAssert (refused and radiusRefused and EWNear (EWState EWEdit) authored and EWNear (QLayer.procRadiusIDs as array) radii and QLayer.procRadiusBinding==binding) "E4_gpu_authoring_guard" "A stale displayed generation cannot author a transform or radius against unmatched CPU state."
        cyrusOwnedPreviewFault 0 0;QRoot.refreshDisplay();CyrusViewportRedraw();local recovered=EWWaitDisplay 2
        local current=EWVisible EWEdit,good=current.count==before.count
        for i=1 to before.count do good=good and EWNear current[i][13].translation (before[i][13].translation+[20,30,4])
        QAssert (good and recovered[3]!=ready[3] and EWNear (EWState EWEdit) authored) "E4_gpu_recovery" "Successful retry advances the image and Edit feedback together without reauthoring the move."
        cyrusOwnedPreviewFault 0 0
    )catch(if cyrusOwnedPreviewFault!=undefined do cyrusOwnedPreviewFault 0 0;throw())
)
