(
    global MIBenchmark
    RIAssert (matchPattern RIDir pattern:"*mesh-integration-2026-10-02/run*/") "Not a private test process"
    loadMaxFile (RIRoot+"Test Scene/SaveSelect 2.max") quiet:true
    CyrusPFTimer.Stop()
    local controllers=for n in objects where classof n.baseObject==AminScatterObject collect n
    local savedViewTM=viewport.getTM()
    viewport.setLayout #layout_1;viewport.setType #view_persp_user;viewport.setTM savedViewTM
    viewport.setRenderLevel #smoothhighlights
    (NitrousGraphicsManager.GetActiveViewportSetting()).AdaptiveDegradeNeverDegradeGeometry=true
    for node in controllers do (
        node.updateMode=1;node.viewportMode=3;node.viewportInstances=2000;node.viewportFaces=200000
        node.refreshDisplay()
    )
    MISettle();RICapture "artist-mesh-200k-initial"
    CSPWriteText (RIDir+"artist-mesh-initial.json") (CSPObject #(#("controllers",for n in controllers collect #(n.name,MIStats n,RIStats n)),#("error",CyrusPointLastError)))
)
