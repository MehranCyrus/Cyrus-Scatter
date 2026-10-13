-- Compare viewport drawing only. Does not create/delete nodes or save the scene.
-- Both modes use the current plugin, cache, settings and placement calculation.
global CyrusViewportComparisonUI,CyrusSetViewportComparison
global CyrusViewportComparisonHeadless

fn CyrusSetViewportComparison optimized = (
    if cyrusPreviewBatchDrawing==undefined do throw "Install Cyrus Scatter 0.62 and restart 3ds Max first."
    cyrusPreviewBatchDrawing optimized
    redrawViews()
    cyrusPreviewBatchDrawing()
)

try(destroyDialog CyrusViewportComparisonUI)catch()
if cyrusPreviewBatchDrawing==undefined then (
    if CyrusViewportComparisonHeadless==true then throw "Cyrus Scatter 0.62 native drawing helper is unavailable."
    else messageBox "Install Cyrus Scatter 0.62 and restart 3ds Max first." title:"Cyrus viewport comparison"
) else (
    rollout CyrusViewportComparisonUI "Cyrus viewport comparison" width:340 height:198 (
        label explanation "Move around the SAME scene after each choice." pos:[12,12] width:316
        button previous "Previous drawing" pos:[12,39] width:151 height:30
        button optimized "Optimized drawing" pos:[177,39] width:151 height:30
        label mode "Active: optimized drawing" pos:[12,83] width:316
        label scope "Compares drawing only within this plugin version." pos:[12,110] width:316
        label closing "Closing this panel restores optimized drawing." pos:[12,131] width:316
        button done "Done" pos:[222,160] width:106 height:25
        on previous pressed do (
            CyrusSetViewportComparison false
            mode.text="Active: previous drawing"
        )
        on optimized pressed do (
            CyrusSetViewportComparison true
            mode.text="Active: optimized drawing"
        )
        on done pressed do destroyDialog CyrusViewportComparisonUI
        on CyrusViewportComparisonUI close do CyrusSetViewportComparison true
    )
    if CyrusViewportComparisonHeadless!=true do (
        CyrusSetViewportComparison true
        createDialog CyrusViewportComparisonUI
    )
)
