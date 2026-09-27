module.exports=function(s) {
 s=s.replace('version:19','version:20');
 for(const key of ['AminScatterLayerFields','AminScatterLayerTabs']) s=s.replace(key+'=#(',key+'=#(#sourceZOffsets,#sourceScales,');
 s=s.replace('    parameters weightSettings (',`    parameters sourceTransformSettings (
        sourceZOffsets type:#floatTab tabSize:0 tabSizeVariable:true
        sourceScales type:#floatTab tabSize:0 tabSizeVariable:true
        on sourceZOffsets set v i do dirty=true
        on sourceScales set v i do dirty=true
    )
    fn sourceZOffset i = (if i>0 and i<=sourceZOffsets.count then sourceZOffsets[i] else 0.0)
    fn sourceScale i = (if i>0 and i<=sourceScales.count then sourceScales[i] else 1.0)
    fn assignSourceTransform rows value scaling:false = (
        undo "Cyrus Scatter source transform" on (
            if scaling then (
                while sourceScales.count<sources.count do append sourceScales 1.0
                for i in rows where i>0 and i<=sources.count do sourceScales[i]=amax 0.0 value
            ) else (
                while sourceZOffsets.count<sources.count do append sourceZOffsets 0.0
                for i in rows where i>0 and i<=sources.count do sourceZOffsets[i]=value
            )
        )
        dirty=true
    )
    parameters weightSettings (`);
 s=s.replace('        if sourceWeights.count==0 and not collisionEnabled','        local result=if sourceWeights.count==0 and not collisionEnabled');
 const end='\n    )\n    fn refreshPreview = (';
 s=s.replace(end,`
        if plants.count>0 and (sourceZOffsets.count>0 or sourceScales.count>0) do (
            local offsets=for n in plants collect sourceZOffset (findItem sources n)
            local scales=for n in plants collect sourceScale (findItem sources n)
            for row in result do (
                local tm=row[1], k=row[2], factor=scales[k]
                tm.row1=tm.row1*factor;tm.row2=tm.row2*factor;tm.row3=tm.row3*factor
                tm.row4=tm.row4+[0,0,offsets[k]]
                row[1]=tm
            )
        )
        result`+end);
 s=s.replace(/rollout (sourceUI(?:_\d+)?) "Source Object"[^]*?\n    \)/g,block=>{
  block=block.replace('        fn colorLabel',`        spinner sourceZSpin "Z Offset: " range:[-1000000,1000000,0] type:#worldunits pos:[8,478] width:146 fieldWidth:65
        spinner sourceScaleSpin "Scale: " range:[0,10000,1] scale:0.01 pos:[8,504] width:146 fieldWidth:65
        label sourceTransformHelp "Scale: 1 = original" pos:[8,530] width:146
        fn colorLabel`);
  block=block.replace('if obj.sourceWeights.count>0 do append obj.sourceWeights 1.0;', 'if obj.sourceWeights.count>0 do append obj.sourceWeights 1.0;if obj.sourceZOffsets.count>0 do append obj.sourceZOffsets 0.0;if obj.sourceScales.count>0 do append obj.sourceScales 1.0;');
  block=block.replace('weightSpin.enabled=rows.numberSet>0','weightSpin.enabled=rows.numberSet>0;sourceZSpin.enabled=rows.numberSet>0;sourceScaleSpin.enabled=rows.numberSet>0');
  block=block.replace('weightSpin.value=obj.sourceWeight focusedRow','weightSpin.value=obj.sourceWeight focusedRow\n                sourceZSpin.value=obj.sourceZOffset focusedRow;sourceScaleSpin.value=obj.sourceScale focusedRow');
  block=block.replace('        on weightSpin changed',`        on sourceZSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v;redrawViews())
        on sourceScaleSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v scaling:true;redrawViews())
        on weightSpin changed`);
  block=block.replace('if rows[k]<=obj.sourceWeights.count do deleteItem obj.sourceWeights rows[k]',`if rows[k]<=obj.sourceZOffsets.count do deleteItem obj.sourceZOffsets rows[k]
                    if rows[k]<=obj.sourceScales.count do deleteItem obj.sourceScales rows[k]
                    if rows[k]<=obj.sourceWeights.count do deleteItem obj.sourceWeights rows[k]`);
  return block;
 });
 return s;
};
