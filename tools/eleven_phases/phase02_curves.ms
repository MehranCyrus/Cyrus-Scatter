(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-*/" do throw "Owned P02 host required"
    local log=createFile (MCPFixtureDir+"phase02-curves.txt")
    fn verify value label log = (
        format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log
        if not value do throw label
    )
    fn same a b = ((a as string)==(b as string))
    try (
        CyrusPerfHeadless=true;resetMaxFile #noPrompt
        local node=AminScatterObject name:"P02 curve domains",root=node.baseObject
        root.updateMode=1;root.autoRender=false
        local receiver=plane length:30 width:30 lengthsegs:1 widthsegs:1
        root.newLayer();local leaf=root.selectedLayer()
        root.setLayerSurfaces leaf #(receiver);leaf.addPointSource();leaf.amount=50
        leaf.procSelfOverride=true;leaf.procSelfEnabled=false
        local boundary=rectangle length:15 width:15
        leaf.areaNodes=#(boundary);leaf.areaModes=#(1)
        local path=splineShape name:"P02 path"
        addNewSpline path;addKnot path 1 #corner #line [-10,0,0];addKnot path 1 #corner #line [10,0,0];updateShape path
        leaf.addStroke path;local band=leaf.strokeIDs[1]
        local paint=root.addPaintArea leaf target:receiver
        local paintBefore=cyrusBrushFalloff paint.paintDocument
        root.refreshAll();local epoch=root.procEpoch
        CyrusPerfHeadless=false
        for caseIndex=1 to 6 do (
            local targetOwner=if caseIndex<=2 then paint else leaf
            local isDensity=mod caseIndex 2==1,targetArea=if caseIndex==3 or caseIndex==4 then boundary else undefined
            local bandID=if caseIndex>4 then band else 0
            local editor=CyrusOpenFalloffGraph targetOwner targetArea isDensity bandID:bandID
            local category=if isDensity then "density_curve" else "scale_curve"
            local target=CyrusPresetMakeBinding root targetOwner category editor:editor
            local multiplier=not isDensity and not targetOwner.isPaintArea
            local values=if multiplier then #(0.5,1.5,2.0) else #(0.2,0.4,0.8)
            local doc=#(category,"Domain",#(values,#(),multiplier))
            local original=if bandID>0 then (if isDensity then leaf.strokeCurveSamples[1] else leaf.strokeScaleSamples[1]) else CyrusFallPack ((targetOwner.getFallConfig targetArea)[if isDensity then 8 else 5])
            clearUndoBuffer();CyrusPresetApply target doc
            local actual=CyrusPresetCapture target
            verify (abs(actual[1][1]-values[1])<0.0001 and abs(actual[1][257]-values[3])<0.0001) ("Correct curve domain " + caseIndex as string) log
            verify (actual[3]==multiplier) ("Correct domain metadata " + caseIndex as string) log
            local applied=if bandID>0 then (if isDensity then leaf.strokeCurveSamples[1] else leaf.strokeScaleSamples[1]) else CyrusFallPack ((targetOwner.getFallConfig targetArea)[if isDensity then 8 else 5])
            local mismatch=#(category,"Mismatch",#(#(0.9,0.1),actual[2],multiplier)),rejected=false
            try(CyrusPresetApply target mismatch)catch(rejected=true)
            verify rejected ("Mismatched handles rejected " + caseIndex as string) log
            local retained=if bandID>0 then (if isDensity then leaf.strokeCurveSamples[1] else leaf.strokeScaleSamples[1]) else CyrusFallPack ((targetOwner.getFallConfig targetArea)[if isDensity then 8 else 5])
            verify (retained==applied and not theHold.Holding()) ("Mismatch preserves model and native hold " + caseIndex as string) log
            if caseIndex==2 do (
                rejected=false
                try(CyrusPresetApply target #("scale_curve","Wrong domain",#(#(0.5,1.5),#(),true)))catch(rejected=true)
                verify rejected "Paint scale rejects a multiplier-domain curve" log
            )
            max undo
            local restored=if bandID>0 then (if isDensity then leaf.strokeCurveSamples[1] else leaf.strokeScaleSamples[1]) else CyrusFallPack ((targetOwner.getFallConfig targetArea)[if isDensity then 8 else 5])
            verify (restored==original) ("One Undo restores correct curve target " + caseIndex as string) log
            destroyDialog editor
            max redo
            retained=if bandID>0 then (if isDensity then leaf.strokeCurveSamples[1] else leaf.strokeScaleSamples[1]) else CyrusFallPack ((targetOwner.getFallConfig targetArea)[if isDensity then 8 else 5])
            verify (retained==applied) ("Redo survives graph close " + caseIndex as string) log
        )
        local paintAfter=cyrusBrushFalloff paint.paintDocument
        verify (same (for i=1 to 6 collect paintBefore[i]) (for i=1 to 6 collect paintAfter[i])) "Curve presets preserve Paint widths, enable flags and scale range" log
        verify (not leaf.strokeCurveEnabled[1] and leaf.strokeScaleModes[1]==1) "Band curve presets preserve independent enable and scale mode" log
        verify (root.procEpoch==epoch) "All curve transactions retain Manual publication" log
        local beforeDensity=leaf.strokeCurveSamples[1],beforeScale=leaf.strokeScaleSamples[1]
        local scene=MCPFixtureDir+"P02_curve_domains.max"
        saveMaxFile scene quiet:true;loadMaxFile scene quiet:true useFileUnits:true
        node=getNodeByName "P02 curve domains";root=node.baseObject;leaf=root.layerObjects[1]
        verify (leaf.strokeCurveSamples[1]==beforeDensity and leaf.strokeScaleSamples[1]==beforeScale) "Band preset values survive current-schema save/reopen" log
        local editor=CyrusOpenFalloffGraph leaf undefined false bandID:leaf.strokeIDs[1]
        local target=CyrusPresetMakeBinding root leaf "scale_curve" editor:editor
        leaf.removeStroke 1
        local rejected=false
        try(CyrusPresetApply target #("scale_curve","Removed",#(#(1.0,1.0),#(),true)))catch(rejected=true)
        verify rejected "Removed Band invalidates the captured preset editor" log
        destroyDialog editor
        format "COMPLETE\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
