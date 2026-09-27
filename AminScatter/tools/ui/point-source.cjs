module.exports=function(s){
 s=s.replace('version:23','version:24');
 for(const key of ['AminScatterLayerFields','AminScatterLayerTabs'])s=s.replace(key+'=#(',key+'=#(#sourcePoint,');
 s=s.replace('    parameters emptySettings (','    parameters emptySettings (\n        sourcePoint type:#boolTab tabSize:0 tabSizeVariable:true\n        on sourcePoint set v i do dirty=true');
 s=s.replace('    fn isEmptySource i',`    fn isPointSource i = (i>0 and i<=sourcePoint.count and sourcePoint[i])
    fn addPointSource = (
        local i=addEmptySource()
        while sourcePoint.count<sources.count do append sourcePoint false
        sourcePoint[i]=true;dirty=true;i
    )
    fn replacePointSource row node = (
        if not (isPointSource row) or not (usableSource node) or findItem sources node>0 do return false
        undo "Cyrus Scatter replace point" on (
            sources[row]=node;sourcePoint[row]=false;sourceEmpty[row]=false
        )
        dirty=true;previewBuildCount=0;true
    )
    fn isEmptySource i`);
 // Place helpers after addEmptySource so MAXScript resolves the function binding.
 const a=s.indexOf('    fn addPointSource ='),b=s.indexOf('    fn isEmptySource i',a);
 const helpers=s.slice(a,b);s=s.slice(0,a)+s.slice(b);
 s=s.replace('    fn validSources =',helpers+'    fn validSources =');
 s=s.replace('where not (isEmptySource (sourceRow plants[row[2]])) collect row','where (not (isEmptySource (sourceRow plants[row[2]])) or (previewOnly and isPointSource (sourceRow plants[row[2]]))) collect row');
 s=s.replace('local data=placements plants previewOnly:showCenters','local data=placements plants previewOnly:true');
 // Keep Add Empty and Add Point next to the source selection controls.
 s=s.replace(/rollout (sourceUI(?:_\d+)?) "Source Object"[^]*?\n    \)/g,b=>{
  b=b.replace(/        button addEmpty[^\n]*\n/,'');
  b=b.replace(/pos:\[(\d+),(\d+)\]/g,(m,x,y)=>Number(y)>=270?`pos:[${x},${Number(y)+78}]`:m);
  b=b.replace('        label groupHeading',`        button addPoint "Add Point" pos:[7,264] width:123
        button addEmpty "Add Empty" pos:[7,290] width:123
        pickbutton replacePoint "Replace Point: pick object" filter:AminScatterSourceFilter pos:[7,316] width:123
        label groupHeading`);
  b=b.replace('if obj.isEmptySource i then "[Empty]"','if obj.isPointSource i then "[Point]" else if obj.isEmptySource i then "[Empty]"');
  b=b.replace('        on addEmpty pressed',`        on addPoint pressed do (
            local i=obj.addPointSource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on replacePoint picked n do (
            local rows=plantList.selection as array
            if rows.count!=1 then messageBox "Select one Point row to replace." title:"Cyrus Scatter"
            else if not (obj.replacePointSource rows[1] n) do messageBox "Select a Point row and an object that is not already in this source list." title:"Cyrus Scatter"
            replacePoint.text="Replace Point: pick object";updateList();showSelectedColor();redrawViews()
        )
        on addEmpty pressed`);
  b=b.replace('if rows[k]<=obj.sourceEmpty.count','if rows[k]<=obj.sourcePoint.count do deleteItem obj.sourcePoint rows[k]\n                    if rows[k]<=obj.sourceEmpty.count');
  return b;
 });
 return s;
};
