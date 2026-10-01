-- Run only in a fresh 3dsmaxbatch process; creates its own disposable scene.
(
    global AminScatterObject,CyrusSurfaceAnalyzer
    local root=(dotNetClass "System.IO.Path").GetFullPath ((getFilenamePath (getSourceFileName()))+"../../")
    local log=createFile (root+"build/max2027-smoke-result.txt")
    fn require condition description = (if not condition do throw description)
    try (
        require ((maxVersion())[1]==29000) "Wrong host version"
        -- Native extensions must be loaded at startup via the test plugin INI.
        -- loadDllsFromDir uses the ordinary class-plugin loader, not DLX startup.
        require (aminScatterTransforms!=undefined and cyrusAnalyzeSurface!=undefined) "Native primitives missing"
        format "PASS native loading\n" to:log;flush log
        fileIn (root+"CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms")
        fileIn (root+"AminScatter/scripts/AminScatterObject.ms")
        format "PASS script registration\n" to:log;flush log
        local surfaceNode=plane name:"Cyrus_Test_Surface" length:1000 width:1000 lengthsegs:2 widthsegs:2
        local sourceNode=box name:"Cyrus_Test_Source" length:10 width:10 height:30 pos:[1500,0,0]
        local rows=aminScatterTransforms surfaceNode 200 42 1 1.0 1.0 [0,0,0] [0,0,0] [0,0,0] true
        local again=aminScatterTransforms surfaceNode 200 42 1 1.0 1.0 [0,0,0] [0,0,0] [0,0,0] true
        require (rows.count==200) "Wrong native scatter count"
        require ((cyrusEditFingerprint rows "smoke")==(cyrusEditFingerprint again "smoke")) "Nonrepeatable placements"
        local controller=AminScatterObject name:"Cyrus_Test_Controller"
        controller.surfaceNodes=#(surfaceNode)
        controller.updateMode=2
        controller.newLayer()
        local layer=controller.layerObjects[1]
        layer.sources=#(sourceNode);layer.amount=200
        controller.syncLayerSurface layer
        local actual=layer.placements (layer.validSources())
        require (actual.count==200) "Wrong controller placement count"
        local cache=aminScatterBuildPreview actual #(#([0,0,0],[0,0,10])) #([100,220,120]) 1000
        require ((aminScatterPreviewCount cache)==400) "Wrong point preview count"
        local geometry=cyrusBuildGeometryPreview actual #(sourceNode) #([100,220,120]) 1 100 20000
        require ((cyrusPreviewFaces geometry)==1200) "Wrong box proxy face count"
        format "PASS scatter repeatability, controller and previews\n" to:log;flush log
        local modifier=execute "CyrusScatterEdit()"
        addModifier controller modifier
        local editSignature=cyrusEditFingerprint actual ((layer.randomSeed as string)+"|"+(layer.diversitySeed as string)+"|1")
        local edited=cyrusEditStack #(modifier) actual 1 editSignature
        require (edited.count==200) "CS Edit stack failed"
        format "PASS CS Edit\n" to:log;flush log
        local analyzerNode=CyrusSurfaceAnalyzer name:"Cyrus_Test_Analyzer"
        analyzerNode.surface=surfaceNode
        analyzerNode.fitRadius=1;analyzerNode.pointRadius=50
        analyzerNode.runAnalysis()
        require ((analyzerNode.getAnalysisRuns())>0) "Analyzer did not run"
        format "PASS Analyzer\n" to:log;flush log
        local scene=root+"build/max2027-smoke.max"
        require (saveMaxFile scene quiet:true) "Save failed"
        require (loadMaxFile scene quiet:true) "Reload failed"
        require (isValidNode (getNodeByName "Cyrus_Test_Controller")) "Scatter did not persist"
        require (isValidNode (getNodeByName "Cyrus_Test_Analyzer")) "Analyzer did not persist"
        local restored=getNodeByName "Cyrus_Test_Controller"
        require (restored.modifiers.count==1) "CS Edit did not persist"
        local entries=restored.layerEntries()
        local restoredLayer=entries[1][2]
        local restoredRows=restoredLayer.placements (restoredLayer.validSources())
        require (restoredRows.count==200) "Placement count changed after reopen"
        require ((cyrusEditFingerprint restoredRows "smoke")==(cyrusEditFingerprint actual "smoke")) "Layout changed after reopen"
        format "PASS save/reopen\nSUCCESS\n" to:log;close log
    ) catch (
        local reason=getCurrentException()
        format "FAILED: %\n" reason to:log;close log
        throw()
    )
)
