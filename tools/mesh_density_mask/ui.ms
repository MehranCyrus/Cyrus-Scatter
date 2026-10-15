(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-meshmask-*/" do throw "Owned mask host required"
    local log=createFile (MCPFixtureDir+"mesh-mask-ui.txt")
    fn verify pass label log = (format "%: %\n" (if pass then "PASS" else "FAIL") label to:log;flush log;if not pass do throw label)
    try (
        local root=MeshMaskRoot,leaf=MeshMaskLeaf,node=MeshMaskNode
        CyrusPerfHeadless=false;root.updateMode=1;select node;max modify mode
        if modPanel.getCurrentObject()!=root do modPanel.setCurrentObject root
        if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
        root.populationUI.open=true;root.mainUI.bindSection root.populationUI
        verify (root.populationUI.distributionUI_meshCheck.text=="Use mesh channel mask") "Mesh mask caption fits the narrow Amount column" log
        for i=1 to meshop.getNumMapVerts MeshMaskReceiver 1 do meshop.setMapVert MeshMaskReceiver 1 i [1,1,1]
        update MeshMaskReceiver
        leaf.meshMaskChannel=1;leaf.meshMaskInvert=false;leaf.meshMaskSamples=#(0.0,1.0);leaf.meshMaskGraph="";root.evaluateProcedural()
        local before=leaf.generatedCount
        root.populationUI.distributionUI_meshCurveButton.pressed()
        local editor=CyrusFalloffGraph
        verify (editor.obj==leaf and editor.isMeshMask and matchPattern editor.title pattern:"*Layer_01*") "Real graph button captures its layer owner and shows its layer name" log
        local curve=editor.graph.curves[1],p=curve.points[2]
        p.value=[1,0];curve.points[2]=p;editor.applyButton.pressed()
        verify (leaf.meshMaskSamples.count==257 and amax (leaf.meshMaskSamples as array)==0) "Actual native curve Apply stores sampled zero response" log
        verify (leaf.generatedCount==before) "Manual curve Apply leaves plants pending" log
        root.evaluateProcedural();verify (leaf.generatedCount==0) "Update applies the authored curve" log
        editor.doneButton.pressed();root.populationUI.distributionUI_meshCurveButton.pressed();editor=CyrusFalloffGraph
        verify (editor.graph.curves[1].points[2].value.y==0) "Reopening restores saved curve handles" log
        root.newLayer();local alternate=root.selectedLayer()
        curve=editor.graph.curves[1];p=curve.points[2];p.value=[1,50];curve.points[2]=p;editor.applyButton.pressed()
        verify (leaf.meshMaskSamples[257]==0.5 and (alternate.meshMaskCurve() as string)==(#(0.0,1.0) as string)) "Selection changes keep graph writes bound to the captured layer" log
        editor.doneButton.pressed();root.removeLogicalLayer alternate;root.selectLayer (findItem root.layerObjects leaf)
        leaf.meshMaskSamples=#(0.0,1.0);leaf.meshMaskGraph="";root.evaluateProcedural()
        root.populationUI.open=true;root.mainUI.bindSection root.populationUI
        local epoch=root.procEpoch,prepared=leaf.procPreparedBuilds
        root.populationUI.distributionUI_meshPreviewButton.pressed()
        verify (CyrusMeshMaskPreviewRows.count>0 and CyrusMeshMaskPreviewRows.count<=2048 and root.procEpoch==epoch and leaf.procPreparedBuilds==prepared) "Actual Preview button reads a bounded snapshot without publishing plants" log
        local native=cyrusMeshDensityStats()
        root.populationUI.distributionUI_meshHideButton.pressed()
        verify (CyrusMeshMaskPreviewRows.count==0 and (cyrusMeshDensityStats() as string)==(native as string)) "Actual Hide button changes only cached display" log
        leaf.paintEnabled=true;root.coverageUI.open=true;root.mainUI.bindSection root.coverageUI
        for key in #(#brushUI_modeRadio,#brushUI_beginButton,#brushUI_stopButton,#brushUI_fillButton,#brushUI_emptyButton,#brushUI_densitySpin,#brushUI_insideSpin,#brushUI_outsideSpin,#brushUI_densityFade,#brushUI_densityCurve,#brushUI_scaleFade,#brushUI_scaleMin,#brushUI_scaleMax,#brushUI_scaleCurve,#brushUI_overlayMode,#brushUI_overlayColor,#brushUI_radiusSpin,#brushUI_exportSpline,#brushUI_importMode,#brushUI_splineTolerance,#brushUI_importSpline,#setsUI_enabledCheck) do (
            local control=getProperty root.coverageUI key
            verify (control.tooltip!="") ("Native Paint tooltip: "+(key as string)) log
        )
        verify (matchPattern root.coverageUI.brushUI_scaleMin.tooltip pattern:"*0.5*half*" and matchPattern root.coverageUI.brushUI_scaleMax.tooltip pattern:"*2*double*") "Paint scale tooltips include concrete multiplier examples" log
        root.mainUI.bindSection root.populationUI
        format "COMPLETE\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
