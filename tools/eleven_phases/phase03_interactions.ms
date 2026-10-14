(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-*/" do throw "Owned P03 host required"
    local log=createFile (MCPFixtureDir+"phase03-interactions.txt")
    fn verify value label log = (
        format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log
        if not value do throw label
    )
    fn fullRows rows = (local stream=stringStream "";with printAllElements on (format "%" rows to:stream);stream as string)
    fn countUpper rows z = ((for row in rows where row[1].row4.z<=z collect row).count)
    try (
        CyrusPerfHeadless=true;resetMaxFile #noPrompt
        units.SystemType=#meters;units.SystemScale=1
        local node=AminScatterObject name:"P03 interactions",root=node.baseObject
        root.updateMode=1;root.autoRender=false
        local receiver=plane length:30 width:30 lengthsegs:1 widthsegs:1
        root.newLayer();local leaf=root.selectedLayer()
        root.setLayerSurfaces leaf #(receiver);leaf.addPointSource();leaf.amount=2000
        leaf.procSelfOverride=true;leaf.procSelfEnabled=false
        local paintA=root.addPaintArea leaf target:receiver,paintB=root.addPaintArea leaf target:receiver
        cyrusBrushFill paintA.paintDocument 1.0;cyrusBrushFill paintB.paintDocument 1.0
        paintA.paintDensity=0.35;paintB.paintDensity=0.65;leaf.paintEnabled=true
        root.evaluateProcedural();local painted=fullRows root.groupSnapshotRows[1],paintCount=leaf.generatedCount
        verify (paintCount>1100 and paintCount<1450) "Overlapping Paint uses existing max-union density" log
        leaf.altitudeEnabled=true;leaf.altitudeMinimum=-1;leaf.altitudeMaximum=1
        root.evaluateProcedural()
        verify (fullRows root.groupSnapshotRows[1]==painted) "Neutral altitude preserves overlapping Paint IDs and transforms" log
        leaf.altitudeMinimum=0.1;root.evaluateProcedural()
        verify (leaf.generatedCount==0) "Altitude multiplies Paint eligibility without a second quota" log
        leaf.altitudeMinimum=-1;leaf.paintEnabled=false
        leaf.distributionMode=3;leaf.densityMap=checker color1:(color 128 128 128) color2:(color 128 128 128)
        root.evaluateProcedural();local mappedRows=fullRows root.groupSnapshotRows[1],mapCount=leaf.generatedCount
        verify (mapCount>800 and mapCount<1200) "Texture density remains active with neutral surface filters" log
        leaf.altitudeEnabled=false;root.evaluateProcedural()
        verify (fullRows root.groupSnapshotRows[1]==mappedRows) "Disabled filter exactly preserves map density channel" log
        leaf.distributionMode=1;leaf.densityMap=undefined
        local path=rectangle name:"P03 band path" length:20 width:20
        leaf.addStroke path;leaf.diversityMode=3;leaf.setStrokeSelection 1 2 #(leaf.sourceRowIDs[1])
        leaf.strokeStarts[1]=0;leaf.strokeEnds[1]=5
        root.evaluateProcedural();local banded=fullRows root.groupSnapshotRows[1]
        verify (leaf.generatedCount>0 and leaf.generatedCount<2000) "Band subset is present before eligibility" log
        leaf.slopeEnabled=true;leaf.slopeMaximum=5;root.evaluateProcedural()
        verify (fullRows root.groupSnapshotRows[1]==banded) "Neutral slope preserves Band owner and assignment" log
        leaf.slopeMinimum=10;leaf.slopeMaximum=30;root.evaluateProcedural()
        verify (leaf.generatedCount==0) "Bands cannot bypass surface eligibility" log
        leaf.slopeEnabled=false;leaf.diversityMode=1
        -- Bounded refill thins the same schedule; impossible intervals report shortfall.
        leaf.amount=50;leaf.procPopulation=2;leaf.procAttemptFactor=8;leaf.procRounds=8;leaf.procRepair=true
        leaf.altitudeEnabled=true;leaf.altitudeMinimum=-1;leaf.altitudeMaximum=1;leaf.altitudeLowerFade=2;leaf.altitudeUpperFade=0
        root.evaluateProcedural()
        verify (leaf.generatedCount==50) "Accepted target refills from the eligible stable candidate prefix" log
        leaf.altitudeMinimum=2;leaf.altitudeMaximum=4;leaf.altitudeLowerFade=0;root.evaluateProcedural()
        verify (leaf.generatedCount==0 and (leaf.procStatistics())[1][11]==50) "Impossible filter is bounded and reports the accepted-target shortfall" log
        leaf.procPopulation=1;leaf.amount=500;leaf.altitudeEnabled=false
        -- Normals are computed after nonuniform world transforms and mirroring.
        receiver.rotation=angleAxis 30 [1,0,0];receiver.scale=[2,3,0.5]
        root.evaluateProcedural();local transformed=fullRows root.groupSnapshotRows[1]
        leaf.slopeEnabled=true;leaf.slopeMinimum=29;leaf.slopeMaximum=31;root.evaluateProcedural()
        verify (fullRows root.groupSnapshotRows[1]==transformed) "Nonuniform transformed receiver uses world geometric normal" log
        local mirroredTM=receiver.transform;mirroredTM.row1=-mirroredTM.row1;receiver.transform=mirroredTM;leaf.slopeMinimum=149;leaf.slopeMaximum=151;root.evaluateProcedural()
        verify (leaf.generatedCount==500) "Mirrored winding reports the corresponding underside slope" log
        -- Multiple receiver slots use the right global anchor face and height.
        receiver.rotation=quat 0 0 0 1;receiver.scale=[1,1,1]
        local upper=copy receiver;upper.pos=[50,0,20]
        root.setLayerSurfaces leaf #(receiver,upper);leaf.slopeEnabled=false;leaf.altitudeEnabled=true;leaf.altitudeMinimum=19;leaf.altitudeMaximum=21
        root.evaluateProcedural()
        verify (leaf.generatedCount==250 and (for row in root.groupSnapshotRows[1] where abs(row[1].row4.z-20)>0.0001 collect row).count==0) "Receiver slots and concatenated face anchors select the correct elevation" log
        verify (not theHold.Holding()) "Interaction fixture leaves no stranded hold" log
        format "COMPLETE\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
