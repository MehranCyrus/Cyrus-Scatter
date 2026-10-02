(
    local results=#()
    fn pass results label = (append results label;CSPWriteText (RIDir+"mesh-lifecycle-progress.json") (CSPJson results))
    local layer=RINode.layerObjects[1]
    RINode.viewportMode=3;RINode.viewportInstances=5000;RINode.viewportFaces=2000000
    RINode.refreshDisplay();MISettle()
    local initial=MIStats RINode
    RIAssert (initial[1]==320000 and initial[2]==5000 and initial[3]==64) "Mesh geometry accounting"
    local placementHash=cyrusEditFingerprint (layer.placements (layer.validSources())) "render"
    local builds=(layer.previewStats())[1],before=RIStats RINode
    for i=1 to 90 do (viewport.setTM ((rotateZMatrix (5.0*sin(i*7.0)))*RIBaseTM);completeRedraw())
    local after=RIStats RINode
    RIAssert (after[3]==before[3] and after[6]==before[6] and after[13]==before[13] and after[8]>before[8]) "Mesh navigation regenerated display data"
    RIAssert ((layer.previewStats())[1]==builds) "Mesh navigation rebuilt cache"
    pass results "320000 triangles / 5000 exact instances; 90 camera steps without uploads or rebuilds"
    viewport.setTM RIBaseTM
    RINode.updateMode=1;MISettle();layer.amount=2500;MISettle()
    RIAssert ((MIStats RINode)[2]==5000) "Manual mode rebuilt"
    RINode.refreshAll();MISettle();RIAssert ((MIStats RINode)[2]==2500) "Manual refresh failed"
    RINode.updateMode=2;layer.amount=5000;MISettle();RIAssert ((MIStats RINode)[2]==5000) "Automatic mesh refresh failed"
    pass results "Manual hold, manual refresh and automatic update"
    for mode in #(1,2,3) do (
        RINode.viewportMode=mode;RINode.refreshDisplay();MISettle()
        RIAssert ((MIStats RINode)[1]==(if mode==3 then 320000 else 0)) "Stale mesh after mode switch"
        RIAssert ((cyrusEditFingerprint (layer.placements (layer.validSources())) "render")==placementHash) "Display changed rendering placements"
    )
    pass results "Point / Proxy / Mesh transitions preserve final placements"
    RINode.showPoints=false;MISettle();RIAssert ((MIStats RINode)[1]==0) "Preview off retained triangles"
    RINode.showPoints=true;MISettle()
    RINode.layerEnabled[1]=false;MISettle();RIAssert ((MIStats RINode)[1]==0) "Disabled layer retained triangles"
    RINode.layerEnabled[1]=true;MISettle()
    hide RINode;MISettle();RIAssert ((MIStats RINode)[1]==0) "Hidden controller retained triangles"
    unhide RINode;MISettle();RIAssert ((MIStats RINode)[1]==320000) "Visibility recovery"
    pass results "Show preview, layer enable, controller hide/unhide"
    RINode.pointColorMode=1;RINode.solidPointColor=red;MISettle();RICapture "mesh-solid-red"
    RINode.pointColorMode=2;MISettle();RICapture "mesh-source-color"
    pass results "Solid and source-group colors"
    local cloneNode=copy RINode;cloneNode.name="MI_Clone";MISettle()
    RIAssert (CyrusPointOwner cloneNode!=CyrusPointOwner RINode and (MIStats cloneNode)[1]==320000) "Clone display ownership"
    undo off delete cloneNode;MISettle();RIAssert (CyrusPointOwners.count==1) "Clone owner leaked"
    pass results "Independent cloned owner and deletion cleanup"
    undo "Mesh count change" on layer.amount=2500
    MISettle();RIAssert ((MIStats RINode)[2]==2500) "Undo setup"
    max undo
    MISettle();RIAssert ((MIStats RINode)[2]==5000) "Undo failed"
    max redo
    MISettle();RIAssert ((MIStats RINode)[2]==2500) "Redo failed"
    layer.amount=5000;MISettle()
    RISource.height=260;RINode.refreshDisplay();MISettle()
    RIAssert ((RIStats RINode)[13]!=before[13]) "Source change failed"
    RISource.height=180;RINode.refreshDisplay();MISettle()
    pass results "Undo / redo and source geometry invalidation"
    viewport.setLayout #layout_4;MISettle();before=RIStats RINode
    for i=1 to 10 do completeRedraw()
    RIAssert ((RIStats RINode)[6]==before[6]) "Multiple views re-uploaded buffers"
    viewport.setLayout #layout_1;viewport.setType #view_persp_user;viewport.setTM RIBaseTM
    pass results "Four viewports reuse buffers"
    local scene=RIDir+"mesh-lifecycle-copy.max"
    saveMaxFile scene quiet:true
    RIAssert (CyrusPointOwners.count==0 and not CyrusPointSuspended) "Save did not strip transient display"
    MISettle();RIAssert (not getSaveRequired()) "Transient rebuilding dirtied scene"
    loadMaxFile scene quiet:true
    RINode=getNodeByName "RI_Controller";RISurface=getNodeByName "RI_Surface";RISource=getNodeByName "RI_Source"
    MISettle();gc light:true;MISettle()
    RIAssert ((MIStats RINode)[1]==320000 and CyrusPointOwners.count==1) "Save/open/GC recovery failed"
    RIAssert (not (CyrusPointOwner RINode).renderable and not canConvertTo (CyrusPointOwner RINode) Editable_Mesh) "Preview enters final geometry"
    pass results "Save/open/GC, clean dirty flag, nonrenderable nonconvertible helper"
    CSPWriteText (RIDir+"mesh-lifecycle.json") (CSPObject #(#("passed",results),#("mesh",MIStats RINode),#("stats",RIStats RINode),#("render_fingerprint",placementHash)))
)
