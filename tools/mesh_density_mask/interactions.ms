-- Map seams, Band ownership, bounded accepted-target refill and real modifier animation.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-*meshmask*/" do throw "Owned mask host required"
    global MeshInteractionStage,MeshInteractionNode,MeshInteractionRoot,MeshInteractionLeaf,MeshInteractionEpoch,MeshInteractionBinding
    global MeshInteractionTimer,MeshInteractionTicks,MeshInteractionTick,MeshInteractionArm
    if MeshInteractionStage==undefined do MeshInteractionStage=0
    fn MeshInteractionTick sender args = (
        MeshInteractionTicks+=1
        if MeshInteractionTicks>=20 do (
            MeshInteractionTimer.Stop()
            (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"mesh-interaction-ready.txt") "ready"
        )
    )
    fn MeshInteractionArm = (
        try(MeshInteractionTimer.Stop();MeshInteractionTimer.Dispose())catch()
        deleteFile (MCPFixtureDir+"mesh-interaction-ready.txt")
        MeshInteractionTicks=0;MeshInteractionTimer=dotNetObject "System.Windows.Forms.Timer";MeshInteractionTimer.Interval=100
        dotNet.addEventHandler MeshInteractionTimer "Tick" MeshInteractionTick;MeshInteractionTimer.Start()
    )
    local stage=MeshInteractionStage+1
    local log=if stage==1 then createFile (MCPFixtureDir+"mesh-mask-interactions.txt") else openFile (MCPFixtureDir+"mesh-mask-interactions.txt") mode:"a"
    fn verify pass label log = (format "%: %\n" (if pass then "PASS" else "FAIL") label to:log;flush log;if not pass do throw label)
    fn fullRows rows = (local s=stringStream "";with printAllElements on format "%" rows to:s;s as string)
    try (
        case stage of (
            1:(
                CyrusPerfHeadless=true;resetMaxFile #noPrompt
                units.SystemType=#meters;units.SystemScale=1
                local node=AminScatterObject name:"Mask interactions",root=node.baseObject,receiver=plane length:30 width:30 lengthsegs:1 widthsegs:1
                root.updateMode=1;root.autoRender=false;convertToMesh receiver
                meshop.setNumMaps receiver 8 keep:true;meshop.setMapSupport receiver 7 true
                meshop.setNumMapVerts receiver 7 6;meshop.setNumMapFaces receiver 7 2
                for i=1 to 6 do meshop.setMapVert receiver 7 i (if i<=3 then [0,0,0] else [1,1,1])
                meshop.setMapFace receiver 7 1 [1,2,3];meshop.setMapFace receiver 7 2 [4,5,6];update receiver
                root.newLayer();local leaf=root.selectedLayer();root.setLayerSurfaces leaf #(receiver);leaf.addPointSource()
                leaf.amount=10000;leaf.procSelfOverride=true;leaf.procSelfEnabled=false;root.evaluateProcedural()
                local expected=for row in root.groupSnapshotRows[1] where row[4]==2 collect row
                leaf.meshMaskEnabled=true;leaf.meshMaskChannel=7;root.evaluateProcedural()
                verify (leaf.generatedCount>4500 and leaf.generatedCount<5500 and fullRows root.groupSnapshotRows[1]==fullRows expected) "Map-face seams use their own numeric corners instead of geometry vertex indices" log
                for i=1 to 6 do meshop.setMapVert receiver 7 i [1,1,1]
                update receiver;leaf.meshMaskEnabled=false;leaf.amount=2000
                local path=rectangle length:20 width:20
                leaf.addStroke path;leaf.diversityMode=3;leaf.setStrokeSelection 1 2 #(leaf.sourceRowIDs[1])
                leaf.strokeStarts[1]=0;leaf.strokeEnds[1]=5;root.evaluateProcedural();local banded=fullRows root.groupSnapshotRows[1]
                verify (leaf.generatedCount>0 and leaf.generatedCount<2000) "Band layout has a real bounded subset before the mask" log
                leaf.meshMaskEnabled=true;root.evaluateProcedural()
                verify (fullRows root.groupSnapshotRows[1]==banded) "White mesh mask preserves complete Band ownership and source metadata" log
                for i=1 to 6 do meshop.setMapVert receiver 7 i [0,0,0]
                update receiver;root.refreshAll();verify (leaf.generatedCount==0) "Bands cannot bypass a zero mesh mask" log
                leaf.diversityMode=1;leaf.amount=50;leaf.procPopulation=2;leaf.procAttemptFactor=8;leaf.procRounds=8;leaf.procRepair=true
                for i=1 to 6 do meshop.setMapVert receiver 7 i [0.5,0.5,0.5]
                update receiver;root.refreshAll();verify (leaf.generatedCount==50) "Accepted target refills from the eligible stable prefix within its work limits" log
                for i=1 to 6 do meshop.setMapVert receiver 7 i [0,0,0]
                update receiver;root.refreshAll()
                verify (leaf.generatedCount==0 and (leaf.procStatistics())[1][11]==50) "Impossible mesh eligibility returns bounded accepted-target shortfall" log
                leaf.procPopulation=1;leaf.amount=1000
                local dc=DataChannelModifier();dc.AddOperator 0x0e12bb44 0 0;dc.AddOperator 2882382387L 0 1
                dc.operators[2].output=2;dc.operators[2].channelNum=7;dc.operators[2].xyz=0;dc.operators[2].replace=0
                addModifier receiver dc
                with animate on (
                    at time 0 (dc.operators[1].convex=1;dc.operators[1].flat=1;dc.operators[1].concave=1)
                    at time 10 (dc.operators[1].convex=0;dc.operators[1].flat=0;dc.operators[1].concave=0)
                )
                sliderTime=0;root.refreshAll();CyrusPointSync()
                local animatedEnd=at time 10 dc.operators[1].flat
                verify (leaf.generatedCount==1000 and animatedEnd==0) "Real Data Channel Curvature parameters carry an animated numeric output" log
                MeshInteractionNode=node;MeshInteractionRoot=root;MeshInteractionLeaf=leaf
                MeshInteractionEpoch=root.procEpoch;MeshInteractionBinding=leaf.procBindingKey
                CyrusPerfHeadless=false;root.updateMode=2;sliderTime=10;MeshInteractionArm()
            )
            2:(
                local root=MeshInteractionRoot,leaf=MeshInteractionLeaf
                verify (leaf.generatedCount==0 and root.procEpoch>MeshInteractionEpoch) "Relevant animated Data Channel validity causes a real Live successor without explicit Update" log
                verify (leaf.procBindingKey==MeshInteractionBinding) "Animated channel-only output preserves Edit geometry binding" log
                root.updateMode=1;MeshInteractionEpoch=root.procEpoch;sliderTime=0;MeshInteractionArm()
            )
            3:(
                local root=MeshInteractionRoot,leaf=MeshInteractionLeaf
                verify (leaf.generatedCount==0 and root.procEpoch==MeshInteractionEpoch) "Manual animated channel changes wait through actual idle callbacks" log
                root.refreshAll();verify (leaf.generatedCount==1000) "Explicit Update consumes pending animated channel values" log
                leaf.meshMaskEnabled=false;local before=cyrusMeshDensityStats();root.refreshAll()
                verify ((cyrusMeshDensityStats() as string)==(before as string)) "Disabled mask performs no native channel reads or filter queries" log
                MeshInteractionTimer.Dispose();format "COMPLETE\n" to:log
            )
        )
        MeshInteractionStage=stage;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
