module.exports=function(s) {
 s=s.replace('version:18','version:19');
 s=s.replace('AminScatterLayerFields=#(','AminScatterLayerFields=#(#sourceWeights,');
 s=s.replace('AminScatterLayerTabs=#(','AminScatterLayerTabs=#(#sourceWeights,');
 s=s.replace('    parameters centerDisplay (',`    parameters weightSettings (
        sourceWeights type:#floatTab tabSize:0 tabSizeVariable:true
        on sourceWeights set v i do dirty=true
    )
    fn sourceWeight i = (if i>0 and i<=sourceWeights.count then sourceWeights[i] else 1.0)
    fn assignWeight rows value = (
        undo "Cyrus Scatter source weight" on (
            while sourceWeights.count<sources.count do append sourceWeights 1.0
            for i in rows where i>0 and i<=sources.count do sourceWeights[i]=amin 1.0 (amax 0.0 value)
        )
        dirty=true
    )
    parameters centerDisplay (`);
 s=s.replace('if not collisionEnabled and not relaxEnabled and not advancedAxes','if sourceWeights.count==0 and not collisionEnabled and not relaxEnabled and not advancedAxes');
 s=s.replace('#(collisionEnabled,collisionRadius,relaxEnabled,relaxSpacing,relaxIterations,relaxStrength)','#(collisionEnabled,collisionRadius,relaxEnabled,relaxSpacing,relaxIterations,relaxStrength) (if sourceWeights.count==0 or plants.count==0 then #() else (for n in plants collect sourceWeight (findItem sources n)))');
 s=s.replace(/rollout (sourceUI(?:_\d+)?) "Source Object"[^]*?\n    \)/g,block=>{
  block=block.replace('        fn colorLabel',`        spinner weightSpin "Weight: " range:[0,1,1] scale:0.01 pos:[8,426] width:120 fieldWidth:54
        label weightHelp "0 = off; relative share" pos:[8,452] width:120
        fn colorLabel`);
  block=block.replace('((colorLabel (obj.sourceColor i))+" | "+','((formattedPrint (obj.sourceWeight i) format:".2f")+" | "+(colorLabel (obj.sourceColor i))+" | "+');
  block=block.replace('append obj.sourceColors groupColor.color;obj.dirty=true','append obj.sourceColors groupColor.color;if obj.sourceWeights.count>0 do append obj.sourceWeights 1.0;obj.dirty=true');
  block=block.replace('        on plantList selected',`        on weightSpin changed v do if not loadingColor do (obj.assignWeight plantList.selection v;updateList();redrawViews())
        on plantList selected`);
  block=block.replace('groupColor.color=obj.sourceColor focusedRow','groupColor.color=obj.sourceColor focusedRow\n                weightSpin.enabled=true;weightSpin.value=obj.sourceWeight focusedRow');
  block=block.replace('            local rows=plantList.selection\n','            local rows=plantList.selection\n            weightSpin.enabled=rows.numberSet>0\n');
  block=block.replace('deleteItem obj.sources rows[k];deleteItem obj.sourceColors rows[k]','if rows[k]<=obj.sourceWeights.count do deleteItem obj.sourceWeights rows[k]\n                    deleteItem obj.sources rows[k];deleteItem obj.sourceColors rows[k]');
  return block;
 });
 s=s.replace('on attachedToNode n do n.renderable=false','on attachedToNode n do (n.renderable=false;n.wirecolor=red)');
 s+='\nfn CyrusScatterRedIcons = (for n in objects where classof n.baseObject==AminScatterObject do n.wirecolor=red)\ncallbacks.removeScripts id:#CyrusScatterIconColor\ncallbacks.addScript #filePostOpen "CyrusScatterRedIcons()" id:#CyrusScatterIconColor\nCyrusScatterRedIcons()\n';
 return s;
};
