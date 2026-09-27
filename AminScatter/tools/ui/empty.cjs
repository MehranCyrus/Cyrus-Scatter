module.exports=function(s){
 s=s.replace('version:22','version:23');
 for(const key of ['AminScatterLayerFields','AminScatterLayerTabs'])s=s.replace(key+'=#(',key+'=#(#sourceEmpty,');
 s=s.replace('    parameters sourceTransformSettings (',`    parameters emptySettings (
        sourceEmpty type:#boolTab tabSize:0 tabSizeVariable:true
        on sourceEmpty set v i do dirty=true
    )
    fn isEmptySource i = (i>0 and i<=sourceEmpty.count and sourceEmpty[i])
    fn sourceRow n = (if classof n==Integer then -n else findItem sources n)
    fn addEmptySource = (
        undo "Cyrus Scatter add empty source" on (
            syncColors()
            while sourceEmpty.count<sources.count do append sourceEmpty false
            while sourceWeights.count<sources.count do append sourceWeights 1.0
            sources.count=sources.count+1;append sourceEmpty true;append sourceWeights 1.0
            append sourceColors (color 100 100 100)
            if sourceZOffsets.count>0 do append sourceZOffsets 0.0
            if sourceScales.count>0 do append sourceScales 1.0
        )
        dirty=true;sources.count
    )
    parameters sourceTransformSettings (`);
 const start=s.indexOf('    fn isEmptySource i'),end=s.indexOf('    parameters sourceTransformSettings (',start);
 const helpers=s.slice(start,end);s=s.slice(0,start)+s.slice(end);
 s=s.replace('    fn validSources =',helpers+'    fn validSources =');
 // Empty entries use unique negative row tokens, never scene nodes.
 s=s.replace('fn validSources = (for n in sources where usableSource n collect n)',
 'fn validSources = (for i=1 to sources.count where (isEmptySource i) or (usableSource sources[i]) collect (if isEmptySource i then -i else sources[i]))');
 s=s.replaceAll('findItem sources n','sourceRow n');
 s=s.replace('else sourceRow n)','else findItem sources n)'); // sourceRow implementation itself
 s=s.replace('        if plants.count>0 and (sourceZOffsets.count>0',`        if plants.count>0 and sourceEmpty.count>0 do result=for row in result where not (isEmptySource (sourceRow plants[row[2]])) collect row
        if plants.count>0 and (sourceZOffsets.count>0`);
 s=s.replace('(aminScatterSourcePoints n pointsPerPlant randomSeed)','(if classof n==Integer then (for p=1 to pointsPerPlant collect [0,0,0]) else aminScatterSourcePoints n pointsPerPlant randomSeed)');
 s=s.replace(/rollout (sourceUI(?:_\d+)?) "Source Object"[^]*?\n    \)/g,b=>{
  b=b.replace('        fn colorLabel', '        button addEmpty "Add Empty" pos:[8,556] width:146\n        fn colorLabel');
  b=b.replace('if isValidNode obj.sources[i] then obj.sources[i].name else "<deleted>"','if obj.isEmptySource i then "[Empty]" else if isValidNode obj.sources[i] then obj.sources[i].name else "<deleted>"');
  b=b.replace('obj.syncColors();append obj.sources n;', 'obj.syncColors();while obj.sourceEmpty.count<obj.sources.count do append obj.sourceEmpty false;append obj.sourceEmpty false;append obj.sources n;');
  b=b.replace('        on sourceZSpin changed',`        on addEmpty pressed do (
            local i=obj.addEmptySource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on sourceZSpin changed`);
  b=b.replace('if rows[k]<=obj.sourceZOffsets.count', 'if rows[k]<=obj.sourceEmpty.count do deleteItem obj.sourceEmpty rows[k]\n                    if rows[k]<=obj.sourceZOffsets.count');
  return b;
 });
 return s;
};


