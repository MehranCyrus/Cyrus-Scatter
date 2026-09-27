module.exports=function(s){
 s=s.replace('version:26','version:27');
 s=s.replace('AminScatterLayerFields=#(','AminScatterLayerFields=#(#finalCleanup,#finalNeighborRadius,#finalMinNeighbors,#finalMinIsland,#finalRelax,#finalStrength,#finalIterations,#finalMaxMove,');
 s=s.replace('    parameters radiusSettings (',`    parameters finalSettings (
        finalCleanup type:#boolean default:false
        finalNeighborRadius type:#worldunits default:100
        finalMinNeighbors type:#integer default:2
        finalMinIsland type:#integer default:5
        finalRelax type:#boolean default:false
        finalStrength type:#float default:0.3
        finalIterations type:#integer default:5
        finalMaxMove type:#worldunits default:10
        on finalCleanup set v do dirty=true
        on finalNeighborRadius set v do dirty=true
        on finalMinNeighbors set v do dirty=true
        on finalMinIsland set v do dirty=true
        on finalRelax set v do dirty=true
        on finalStrength set v do dirty=true
        on finalIterations set v do dirty=true
        on finalMaxMove set v do dirty=true
    )
    parameters radiusSettings (`);
 s=s.replace('previewOnly:false rawOnly:false = (','previewOnly:false rawOnly:false finalPass:undefined = (');
 s=s.replace('local result=if sourceWeights.count==0','local result=if finalPass==undefined and sourceWeights.count==0');
 s=s.replace(/(aminScatterAdvanced targets[^\n]*)/g,'$1 finalPass');
 s=s.replace('        if plants.count>0 and sourceEmpty.count>0','        if finalPass!=undefined do return result\n        if plants.count>0 and sourceEmpty.count>0');
 s=s.replace('            overlapBefore=result.count','            local obstacles=#(),obstacleRadii=#()\n            overlapBefore=result.count');
 s=s.replace('                local obstacles=#(),obstacleRadii=#()','');
 s=s.replace('            overlapAfter=result.count',`            overlapAfter=result.count
            if (finalCleanup or finalRelax) and result.count>0 do (
                local own=if overlapSourceRadius and plants.count>0 then placementRadii result plants else (for row in result collect 0.0)
                if not overlapSourceRadius do obstacleRadii=for row in obstacles collect 0.0
                local gap=if overlapEnabled then (if overlapSourceRadius then overlapGap else overlapRadius+overlapGap) else 0.0
                result=placements plants previewOnly:previewOnly finalPass:#(result,obstacles,own,obstacleRadii,finalCleanup,finalNeighborRadius,finalMinNeighbors,finalMinIsland,finalRelax,finalStrength,finalIterations,finalMaxMove,gap,overlapPlanar)
            )
            overlapAfter=result.count`);
 s=s.replace('        fn currentLayer =',`        label finalTitle "Final Cleanup / Boundary Relax" pos:[6,590] width:146
        checkbox cleanCheck "Remove isolated points" pos:[6,615] width:146
        spinner neighborSpin "Neighbor radius:" type:#worldunits range:[0.001,1e9,100] pos:[6,642] width:146 fieldWidth:55
        spinner minNeighborSpin "Min neighbors:" type:#integer range:[0,10000,2] pos:[6,669] width:146 fieldWidth:55
        spinner minIslandSpin "Min island size:" type:#integer range:[0,100000,5] pos:[6,696] width:146 fieldWidth:55
        checkbox boundaryRelaxCheck "Boundary Relax (move only)" pos:[6,724] width:146
        spinner finalStrengthSpin "Strength:" range:[0,1,.3] pos:[6,751] width:146 fieldWidth:55
        spinner finalIterSpin "Iterations:" type:#integer range:[0,100,5] pos:[6,778] width:146 fieldWidth:55
        spinner finalMoveSpin "Max movement:" type:#worldunits range:[0,1e9,10] pos:[6,805] width:146 fieldWidth:55
        fn currentLayer =`);
 s=s.replace('                radiusMode.selection=',`                cleanCheck.checked=layer.finalCleanup;neighborSpin.value=layer.finalNeighborRadius;minNeighborSpin.value=layer.finalMinNeighbors;minIslandSpin.value=layer.finalMinIsland
                boundaryRelaxCheck.checked=layer.finalRelax;finalStrengthSpin.value=layer.finalStrength;finalIterSpin.value=layer.finalIterations;finalMoveSpin.value=layer.finalMaxMove
                radiusMode.selection=`);
 let handlers='';for(const [ctrl,field] of [['cleanCheck','finalCleanup'],['neighborSpin','finalNeighborRadius'],['minNeighborSpin','finalMinNeighbors'],['minIslandSpin','finalMinIsland'],['boundaryRelaxCheck','finalRelax'],['finalStrengthSpin','finalStrength'],['finalIterSpin','finalIterations'],['finalMoveSpin','finalMaxMove']])handlers+=`        on ${ctrl} changed v do if not refreshing and currentLayer()!=undefined do (undo "Final cleanup setting" on (currentLayer()).${field}=v;changedOverlap())\n`;
 s=s.replace('        on radiusSpin changed',handlers+'        on radiusSpin changed');
 return s;
};

