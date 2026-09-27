module.exports=function(s){
 s=s.replace('version:24','version:26');
 s=s.replace('AminScatterLayerFields=#(','AminScatterLayerFields=#(#streetStraight,');
 for(const key of ['AminScatterLayerFields','AminScatterLayerTabs'])s=s.replace(key+'=#(',key+'=#(#sourceRadii,#sourceFollowScale,#sourceShowRadius,');
 s=s.replace('AminScatterLayerFields=#(','AminScatterLayerFields=#(#overlapSourceRadius,');
 s=s.replace('    parameters emptySettings (',`    local radiusPreview=#()
    parameters radiusSettings (
        sourceRadii type:#floatTab tabSize:0 tabSizeVariable:true
        sourceFollowScale type:#boolTab tabSize:0 tabSizeVariable:true
        sourceShowRadius type:#boolTab tabSize:0 tabSizeVariable:true
        overlapSourceRadius type:#boolean default:false
        on sourceRadii set v i do dirty=true
        on sourceFollowScale set v i do dirty=true
        on sourceShowRadius set v i do dirty=true
        on overlapSourceRadius set v do dirty=true
    )
    fn sourceRadius i = (if i>0 and i<=sourceRadii.count then sourceRadii[i] else 0.0)
    fn sourceFollows i = (i>0 and i<=sourceFollowScale.count and sourceFollowScale[i])
    fn sourceShows i = (i>0 and i<=sourceShowRadius.count and sourceShowRadius[i])
    fn setSourceRadius rows value kind:1 = (
        undo "Source collision radius" on (
            while sourceRadii.count<sources.count do append sourceRadii 0.0
            while sourceFollowScale.count<sources.count do append sourceFollowScale false
            while sourceShowRadius.count<sources.count do append sourceShowRadius false
            for i in rows do case kind of (1: (sourceRadii[i]=value); 2: (sourceFollowScale[i]=value); 3: (sourceShowRadius[i]=value))
        )
        dirty=true
    )
    parameters emptySettings (`);
 s=s.replace('    fn validSources =',`    fn placementRadii rows plants = (
        for row in rows collect (
            local i=sourceRow plants[row[2]],r=sourceRadius i
            if sourceFollows i do r*=amax (length row[1].row1) (amax (length row[1].row2) (length row[1].row3))
            r
        )
    )
    fn cacheRadii rows plants = (
        radiusPreview=#()
        if plants.count>0 and (findItem (sourceShowRadius as array) true)>0 do (
            local radii=placementRadii rows plants
            local step=amax 1 (ceil(rows.count/2000.0) as integer)
            for j=1 to rows.count by step do (
                local i=sourceRow plants[rows[j][2]]
                if sourceShows i and radii[j]>0 do (
                    local center=rows[j][1].row4,r=radii[j]
                    local points=for k=0 to 23 collect center+[r*cos(k*15),r*sin(k*15),0]
                    append radiusPreview #(points,sourceColor i)
                )
            )
        )
    )
    fn drawRadii = (for ring in radiusPreview do (gw.setColor #line ring[2];gw.polyline ring[1] true))
    fn validSources =`);
 // Raw collision data includes Point sources; actual rendering still excludes them.
 s=s.replace('previewOnly and isPointSource','(previewOnly or rawOnly) and isPointSource');
 s=s.replace('local obstacles=#()','local obstacles=#(),obstacleRadii=#()');
 s=s.replace('if src.count>0 or blocker.showCenters do join obstacles (blocker.placements src previewOnly:blocker.showCenters rawOnly:true)',`if src.count>0 or blocker.showCenters do (
                            local blocked=blocker.placements src previewOnly:blocker.showCenters rawOnly:true
                            join obstacles blocked
                            if overlapSourceRadius do join obstacleRadii (if src.count>0 then blocker.placementRadii blocked src else (for row in blocked collect 0.0))
                        )`);
 s=s.replace('and overlapRadius+overlapGap>0','and (overlapSourceRadius or overlapRadius+overlapGap>0)');
 s=s.replace('result=cyrusRemoveOverlaps result obstacles (overlapRadius+overlapGap) overlapPlanar',`result=if overlapSourceRadius then (
                    local ownRadii=if plants.count>0 then placementRadii result plants else (for row in result collect 0.0)
                    cyrusRemoveOverlaps result obstacles overlapGap overlapPlanar ownRadii obstacleRadii
                ) else cyrusRemoveOverlaps result obstacles (overlapRadius+overlapGap) overlapPlanar`);
 s=s.replace('cachedPoints=undefined;cachedPointCount=0;previewError=""','radiusPreview=#();cachedPoints=undefined;cachedPointCount=0;previewError=""');
 s=s.replace('generatedCount=data.count','generatedCount=data.count;cacheRadii data plants');
 s=s.replace('if cache!=undefined do aminScatterDrawPreview cache (obj.pointColorMode==1) obj.solidPointColor','if cache!=undefined do aminScatterDrawPreview cache (obj.pointColorMode==1) obj.solidPointColor');
 s=s.replace('            if obj.showPoints or obj.showCenters do (','            obj.previewCache();obj.drawRadii()\n            if obj.showPoints or obj.showCenters do (');
 s=s.replace(/rollout (sourceUI(?:_\d+)?) "Source Object"[^]*?\n    \)/g,b=>{
  b=b.replace('        fn colorLabel',`        spinner radiusSourceSpin "Collision radius:" type:#worldunits range:[0,1e9,0] pos:[7,634] width:123 fieldWidth:54
        checkbox followRadiusCheck "Follow Scale" pos:[7,660] width:123
        checkbox showRadiusCheck "Show Radius" pos:[7,686] width:123
        fn colorLabel`);
  b=b.replace('sourceZSpin.value=obj.sourceZOffset focusedRow;', 'radiusSourceSpin.value=obj.sourceRadius focusedRow;followRadiusCheck.checked=obj.sourceFollows focusedRow;showRadiusCheck.checked=obj.sourceShows focusedRow;sourceZSpin.value=obj.sourceZOffset focusedRow;');
  b=b.replace('        on sourceZSpin changed',`        on radiusSourceSpin changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v;redrawViews())
        on followRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:2;redrawViews())
        on showRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:3;redrawViews())
        on sourceZSpin changed`);
  b=b.replace('if rows[k]<=obj.sourcePoint.count',`for key in #(#sourceRadii,#sourceFollowScale,#sourceShowRadius) do (local tab=getProperty obj key;if rows[k]<=tab.count do deleteItem tab rows[k])
                    if rows[k]<=obj.sourcePoint.count`);
  return b;
 });
 s=s.replace('        fn currentLayer =',`        dropdownlist radiusMode "Collision radius" items:#("Fixed Radius","Source Radius") pos:[6,535] width:146
        on radiusMode selected i do if not refreshing do ((currentLayer()).overlapSourceRadius=i==2;changedOverlap())
        fn currentLayer =`);
 // Handler must follow helper definitions for MAXScript bindings.
 const handler='        on radiusMode selected i do if not refreshing do ((currentLayer()).overlapSourceRadius=i==2;changedOverlap())\n';
 s=s.replace(handler,'').replace('        on radiusSpin changed',handler+'        on radiusSpin changed');
 s=s.replace('overlapCheck.checked=layer.overlapEnabled;','radiusMode.selection=if layer.overlapSourceRadius then 2 else 1;radiusSpin.enabled=not layer.overlapSourceRadius;overlapCheck.checked=layer.overlapEnabled;');
 return s;
};

