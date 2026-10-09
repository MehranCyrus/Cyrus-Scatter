RSAssert()
global RSRoot,RSLeaf,RSReceivers,RSModels,RSRowLabels,RSRowSets
(
    resetMaxFile #noPrompt
    units.SystemType=#Centimeters;units.SystemScale=1.0
    RSReceivers=#()
    for i=1 to 20 do append RSReceivers (plane name:("RS_Receiver_"+i as string) width:100 length:100 widthsegs:1 lengthsegs:1 pos:[i*300,0,0])
    RSModels=#(box name:"RS_Box" width:2 length:3 height:5 pos:[-1000,-1000,0],sphere name:"RS_Sphere" radius:2 segs:8 pos:[-1100,-1000,0])
    local controller=AminScatterObject name:"RS_Cyrus"
    RSRoot=controller.baseObject
    RSRoot.setLayerTransfer true
    RSRoot.autoRender=false;RSRoot.updateMode=1;RSRoot.surfaceNodes=(RSReceivers as array);RSRoot.newLayer()
    RSLeaf=RSRoot.selectedLayer();RSLeaf.amount=10000;RSLeaf.sources=RSModels;RSLeaf.sourceWeights=#(1.0,1.0);RSLeaf.paintEnabled=false;RSLeaf.randomSeed=42
    RSRoot.setLayerTransfer false
    RSRowLabels=#();RSRowSets=#()
    fn RSCapture label = (
        RSWrite "stage.txt" ("Cyrus "+label)
        local start=timestamp(),rows=(RSRoot.evaluateGroups())[1],elapsed=timestamp()-start
        local s=stringStream ""
        format "milliseconds % count % receivers % area % statistics %\n" elapsed rows.count (RSRoot.validSurfaces()).count (aminScatterSurfaceArea (RSRoot.validSurfaces())) (RSLeaf.procStatistics()) to:s
        for row in rows do format "%\t%\t%\n" row[3] row[2] row[1] to:s
        RSWrite (label+".tsv") (s as string);close s
        append RSRowLabels label;append RSRowSets (cyrusClonePlacementRows rows)
        rows
    )
    RSCapture "fixed_20"
    RSCapture "fixed_20_repeat"
    local extra=plane name:"RS_Receiver_21" width:100 length:100 widthsegs:1 lengthsegs:1 pos:[9000,0,0]
    fn RSFirst20 = (for i=1 to 20 collect (getNodeByName ("RS_Receiver_"+i as string) exact:true))
    RSRoot.surfaceNodes=join (RSFirst20()) #(extra)
    RSCapture "fixed_21"
    RSRoot.surfaceNodes=RSFirst20();RSCapture "fixed_20_restored"
    RSRoot.surfaceNodes=for i=20 to 1 by -1 collect (getNodeByName ("RS_Receiver_"+i as string) exact:true)
    RSCapture "fixed_20_reordered"
    RSRoot.surfaceNodes=RSFirst20()
    local first=getNodeByName "RS_Receiver_1" exact:true
    first.pos += [0,0,100]
    RSCapture "fixed_20_moved"
    first.pos -= [0,0,100]
    RSLeaf.populationMode=2;RSLeaf.plantsPerM2=500.0
    RSCapture "density_20"
    RSRoot.surfaceNodes=join (RSFirst20()) #(extra)
    RSCapture "density_21"
    extra.pos=[315,0,0]
    RSCapture "density_21_near"
    RSRoot.surfaceNodes=RSFirst20()
    first.width=150
    RSCapture "density_20_edited"
    first.width=100
    RSLeaf.procSelfOverride=true;RSLeaf.procSelfEnabled=true;RSLeaf.procSelfGap=5;RSLeaf.procSelfMultiplier=0
    RSCapture "collision_20"
    extra.pos=[9000,0,0]
    RSRoot.surfaceNodes=join (RSFirst20()) #(extra)
    RSCapture "collision_21_far"
    extra.pos=[315,0,0]
    RSCapture "collision_21_near"
    RSRoot.surfaceNodes=for i=1 to 3 collect (getNodeByName ("RS_Receiver_"+i as string) exact:true)
    first.length=100;(getNodeByName "RS_Receiver_2" exact:true).length=200;(getNodeByName "RS_Receiver_3" exact:true).length=300
    RSLeaf.procSelfEnabled=false;RSLeaf.populationMode=1;RSLeaf.amount=600
    RSCapture "three_unequal_fixed"
    RSLeaf.populationMode=2;RSLeaf.plantsPerM2=100
    RSCapture "three_unequal_density"
    local summary=stringStream ""
    format "before\tafter\tbeforeCount\tafterCount\tsameIDs\tsamePositions\tsameBasis\tsameModels\tsameTransforms\n" to:summary
    for pair in #(#("fixed_20","fixed_20_repeat"),#("fixed_20","fixed_21"),#("fixed_20","fixed_20_restored"),#("fixed_20","fixed_20_reordered"),#("fixed_20","fixed_20_moved"),#("density_20","density_21"),#("density_21","density_21_near"),#("density_20","density_20_edited"),#("collision_20","collision_21_far"),#("collision_21_far","collision_21_near")) do (
        local before=RSRowSets[findItem RSRowLabels pair[1]],after=RSRowSets[findItem RSRowLabels pair[2]]
        local lookup=dotNetObject "System.Collections.Hashtable"
        for i=1 to after.count do lookup.Add (after[i][3] as string) i
        local ids=0,positions=0,basis=0,models=0,transforms=0
        for row in before where lookup.ContainsKey (row[3] as string) do (
            local other=after[lookup.Item[row[3] as string]]
            ids+=1
            if row[1].row4==other[1].row4 do positions+=1
            if row[1].row1==other[1].row1 and row[1].row2==other[1].row2 and row[1].row3==other[1].row3 do basis+=1
            if row[2]==other[2] do models+=1
            if row[1]==other[1] do transforms+=1
        )
        format "%\t%\t%\t%\t%\t%\t%\t%\t%\n" pair[1] pair[2] before.count after.count ids positions basis models transforms to:summary
    )
    RSWrite "exact-comparisons.tsv" (summary as string);close summary
    RSWrite "stage.txt" "Cyrus surface campaign completed"
)
