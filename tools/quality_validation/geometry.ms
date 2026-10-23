fileIn ((getFilenamePath(getSourceFileName()))+"common.ms")
global QCircleSpline,QPaintSnapshot,QExportResult
fn QCircleSpline count radius:150 center:[0,0,0] = (
    local shape=splineShape name:(uniqueName "Q dense path")
    addNewSpline shape
    for i=0 to count-1 do (local a=360.0*i/count;addKnot shape 1 #corner #line (center+[radius*cos a,radius*sin a,0]))
    close shape 1;updateShape shape;shape
)
fn QPaintSnapshot = #(QArea.paintKey(),(cyrusBrushRecipeExport QArea.paintDocument)[1],QFingerprint(),QRoot.procEpoch,QArea.areaTarget,QArea.paintDensity)
if matchPattern QScenarioID pattern:"R2-*" then (
    QSetup paint:true
    local path=QCircleSpline 1024
    cyrusBrushImportSpline QArea.paintDocument path false .01;QArea.publishPaint();QCalculate()
    local before=QPaintSnapshot()
    case QScenarioID of (
     "R2-M01": (
        delete path;path=splineShape name:"Q painted ribbon and islands";addNewSpline path
        for i=0 to 511 do (local y=-400.0+800.0*i/511;addKnot path 1 #corner #line [90*sin(y*.3)-50,y,0])
        for i=511 to 0 by -1 do (local y=-400.0+800.0*i/511;addKnot path 1 #corner #line [90*sin(y*.3)+50,y,0])
        close path 1
        for center in #([-210,-250,0],[210,250,0]) do (
            addNewSpline path;local ring=numSplines path
            for i=0 to 127 do (local a=360.0*i/128;addKnot path ring #corner #line (center+[40*cos a,40*sin a,0]))
            close path ring
        )
        updateShape path;cyrusBrushImportSpline QArea.paintDocument path false .01;QArea.publishPaint();QCalculate();before=QPaintSnapshot()
        QMount();QClick QRoot.coverageUI.brushUI_exportSpline
        QRequire (CyrusPaintExportDialog!=undefined) "Actual export button did not open options"
        QClick CyrusPaintExportDialog.createSpline
        QRequire (matchPattern CyrusPaintExportDialog.result.text pattern:"Optimized:*") "Optimized export did not succeed"
        CyrusClosePaintExport()
     )
     "R2-M02": (
        local node=QRoot.exportPaintSpline QArea
        QRequire (isValidNode node and numKnots node 1>=1024) "Exact export lost source detail"
     )
     "R2-M03": (
        local hole=QCircleSpline 256 radius:30
        -- Add its closed contour to the same shape as an EvenOdd hole.
        addNewSpline path;for i=0 to 255 do (local a=360.0*i/256;addKnot path 2 #corner #line [30*cos a,30*sin a,0]);close path 2;updateShape path
        cyrusBrushImportSpline QArea.paintDocument path false .01;QArea.publishPaint();QCalculate();before=QPaintSnapshot()
        local result=QRoot.exportPaintSpline QArea optimized:true tolerance:.1
        QRequire (numSplines result[1]==2) "Optimized export lost hole topology"
     )
     "R2-M04": (
        QSurface.transform=(scaleMatrix [-2,.5,1])*(rotateZMatrix 27)*(rotateXMatrix 12)*(transMatrix [10000,20000,0])
        before=QPaintSnapshot()
        local result=QRoot.exportPaintSpline QArea optimized:true tolerance:.01
        QRequire (result[5] and result[4]<=.01) "Final SDK spline exceeds tolerance"
     )
     "R2-M05": (
        local sphereReceiver=sphere radius:100 segs:16
        QRoot.setLayerSurfaces QLayer #(QSurface,sphereReceiver)
        local curved=QRoot.addPaintArea QLayer target:sphereReceiver
        cyrusBrushFill curved.paintDocument 1.0
        local error="";try(QRoot.exportPaintSpline curved optimized:true tolerance:.1)catch(error=getCurrentException())
        QRequire (matchPattern error pattern:"*no border*" or matchPattern error pattern:"*has no border*") "Filled closed surface fabricated an export border"
     )
     "R2-M06": (
        CyrusOpenPaintExport QRoot QArea;QSettle 100
        cyrusBrushFill QArea.paintDocument 0.0
        local changed=QPaintSnapshot();QClick CyrusPaintExportDialog.createSpline
        QRequire (matchPattern CyrusPaintExportDialog.result.text pattern:"*changed*") "Stale export context was accepted"
        QRequire (QPaintSnapshot() as string==changed as string) "Stale rejection mutated Paint"
        before=changed;CyrusClosePaintExport()
     )
     "R2-M07": (
        local result=QRoot.exportPaintSpline QArea optimized:true tolerance:.1,node=result[1],name=result[1].name
        max undo;QRequire (not isValidNode node) "Export Undo retained node"
        max redo;QRequire (getNodeByName name!=undefined) "Export Redo did not restore node"
     )
     "R2-M08": (
        local result=QRoot.exportPaintSpline QArea optimized:true tolerance:.1
        local copyArea=QRoot.addPaintArea QLayer target:QSurface
        cyrusBrushImportSpline copyArea.paintDocument result[1] false .1
        QRequire ((cyrusBrushStats copyArea.paintDocument)[3]>0) "Optimized ordinary import was empty"
        -- Importing another Area must not mutate the captured original Area.
        QRoot.removePaintArea QLayer copyArea
     )
     "R2-M09": (
        for i=1 to 30 do (local result=QRoot.exportPaintSpline QArea optimized:true tolerance:.1;delete result[1])
        QRequire ((cyrusBrushStats QArea.paintDocument)[3]>0) "Repeated exports lost Paint"
     )
     default: throw ("Unknown Paint export scenario: "+QScenarioID)
    )
    QRequire (QArea.paintKey()==before[1] and (cyrusBrushRecipeExport QArea.paintDocument)[1]==before[2]) "Export changed original Paint bytes/revision"
    QRequire (QFingerprint()==before[3] and QRoot.procEpoch==before[4]) "Export applied or rebuilt placements"
) else (
    QSetup();QLayer.diversityMode=3
    local path=QCircleSpline 1024,band=QLayer.addStroke path side:2
    QLayer.patternWidths[band]=50;QLayer.setStrokeSelection band 2 #(QLayer.sourceRowIDs[1]);QCalculate()
    case QScenarioID of (
     "R3-M01": (
        for n in #(720,721,1000,2000,4000,8192) do (
            QLayer.removeBandPath QLayer.pathIDs[1];delete path
            path=QCircleSpline n;band=QLayer.addStroke path side:2;QLayer.patternWidths[band]=50;QLayer.setStrokeSelection band 2 #(QLayer.sourceRowIDs[1]);QCalculate()
            QRequire (QRoot.groupSnapshotRows[1].count>0) ("Dense path failed at "+n as string)
        )
        local outside=QLayer.addStroke path side:1;QLayer.patternWidths[outside]=25
        QLayer.setStrokeSelection outside 2 #(QLayer.sourceRowIDs[1]);QCalculate()
        QRequire (QRoot.groupSnapshotRows[1].count>0 and QLayer.patternLines.count==2) "Two Bands on one 8192-point Path were counted as duplicate geometry"
     )
     "R3-M02": (local before=QFingerprint();QCalculate();QRequire (QFingerprint()==before) "Repeated Band solve changed output")
     "R3-M03": (
        QLayer.removeBandPath QLayer.pathIDs[1];delete path
        path=splineShape name:"Q dense rectangle";addNewSpline path
        local corners=#([-150,-150,0],[150,-150,0],[150,150,0],[-150,150,0])
        for side=1 to 4 do for i=0 to 255 do addKnot path 1 #corner #line (corners[side]+(corners[if side==4 then 1 else side+1]-corners[side])*(i/256.0))
        close path 1;updateShape path;band=QLayer.addStroke path side:2;QLayer.setStrokeSelection band 2 #(QLayer.sourceRowIDs[1]);QLayer.patternWidths[band]=50
        QLayer.pathJoins[1]=2;QCalculate();QRequire (QRoot.groupSnapshotRows[1].count>0) "Dense collinear Sharp Band failed"
        local before=QFingerprint();QLayer.pathJoins[1]=1;QLayer.patternWidths[band]=.001;local error="";try(QCalculate())catch(error=getCurrentException())
        QRequire (matchPattern error pattern:"*too narrow*" and QFingerprint()==before) "Narrow Band did not reject while retaining its result"
     )
     "R3-M04": (
        addNewSpline path;for i=0 to 255 do (local a=360.0*i/256;addKnot path 2 #corner #line [30*cos a,30*sin a,0]);close path 2;updateShape path
        QCalculate();for row in QRows() do QRequire (distance row[1].row4 [0,0,0]>=29.999) "EvenOdd hole admitted a placement"
        QRequire (QRoot.groupSnapshotRows[1].count>0) "Holed Band lost all eligible output"
     )
     "R3-M05": (
        QLayer.convertBandArrangement 2;QLayer.strokeStarts[band]=10;QLayer.strokeEnds[band]=50;QCalculate()
        QRequire (QRoot.groupSnapshotRows[1].count>0) "Independent Band failed"
     )
     "R3-M06": (
        QLayer.fieldBoundaries=true;QLayer.fieldCombined=true;QCalculate();QRequire (QLayer.previewError=="") "Dense outline publication failed"
     )
     "R3-M07": (local builds=(QLayer.splineFieldStats())[1],before=QFingerprint();QMount();QSettle 500;QRequire ((QLayer.splineFieldStats())[1]==builds and QFingerprint()==before) "Browsing rebuilt static field")
     "R3-M08": (
        local before=QFingerprint(),epoch=QRoot.procEpoch,error=""
        QLayer.removeBandPath QLayer.pathIDs[1];local excessive=QCircleSpline 8193;band=QLayer.addStroke excessive side:2;QLayer.setStrokeSelection band 2 #(QLayer.sourceRowIDs[1])
        try(QCalculate())catch(error=getCurrentException())
        QRequire (error!="" and QFingerprint()==before and QRoot.procEpoch==epoch) "Failed dense successor lost complete result"
     )
     "R3-M09": (
        local before=QFingerprint(),scene=MCPFixtureDir+"bands.max"
        saveMaxFile scene quiet:true;resetMaxFile #noPrompt;units.SystemType=#centimeters;loadMaxFile scene quiet:true
        QNode=getNodeByName "Q Scatter";QRoot=QNode.baseObject;QLayer=QRoot.selectedLayer();QCalculate();QRequire (QFingerprint()==before) "Band save/reopen changed result"
     )
     "R3-M10": (
        QArea=QRoot.addPaintArea QLayer target:QSurface;cyrusBrushFill QArea.paintDocument 1.0
        local bytes=(cyrusBrushRecipeExport QArea.paintDocument)[1],result=QRoot.exportPaintSpline QArea optimized:true tolerance:.1
        local other=QRoot.newLayer();other=QRoot.selectedLayer();QRoot.setLayerSurfaces other #(QSurface);other.addModelSource QModel;other.diversityMode=3
        band=other.addStroke result[1] side:2;other.setStrokeSelection band 2 #(other.sourceRowIDs[1]);QCalculate()
        QRequire ((cyrusBrushRecipeExport QArea.paintDocument)[1]==bytes) "Consumer Band changed original Paint"
     )
     default: throw ("Unknown Band scenario: "+QScenarioID)
    )
)
QAssert true (QScenarioID+"-01") "Geometry workflow and preservation checks completed"
