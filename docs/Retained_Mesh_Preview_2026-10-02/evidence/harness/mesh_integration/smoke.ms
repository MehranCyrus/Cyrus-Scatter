(
    global MISettle,MIStats
    fn MISettle = (CyrusPointSync();completeRedraw();windows.processPostedMessages();completeRedraw())
    fn MIStats n = (for value in (cyrusRetainedMeshStats (CyrusPointOwner n)) collect (value as integer))
    RINode.viewportMode=3;RINode.viewportInstances=5000;RINode.viewportFaces=2000000
    RINode.refreshDisplay();MISettle()
    local layer=RINode.layerObjects[1]
    local before=RIStats RINode
    RICapture "mesh-smoke-retained"
    for i=1 to 30 do (viewport.setTM ((rotateZMatrix (5.0*sin(i*7.0)))*RIBaseTM);completeRedraw())
    local after=RIStats RINode
    RIAssert (after[9]==before[9] and after[12]==1) "Retained mesh initialization failed"
    RIAssert (after[8]>before[8]) "Retained mesh did not draw"
    RIAssert (before[6]==after[6] and before[3]==after[3]) "Navigation re-uploaded Mesh"
    RIAssert ((MIStats RINode)[1]==cyrusPreviewFaces (layer.previewCache())) "Face count changed"
    viewport.setTM RIBaseTM
    CyrusRetainedMeshDrawing false;MISettle();RICapture "mesh-smoke-gw"
    CyrusRetainedMeshDrawing true;MISettle()
    CSPWriteText (RIDir+"mesh-smoke.json") (CSPObject #(#("before",before),#("after",after),#("mesh",MIStats RINode),#("error",CyrusPointLastError)))
)
