const fs=require('fs');
module.exports=function(s){
 const read=n=>fs.readFileSync('tools/ui/templates/'+n,'utf8');
 const tabs=['areaFallConfigs','areaFallScaleGraphs','areaFallDensityGraphs'];
 s=s.replace('version:36','version:37');
 s=s.replace('AminScatterLayerFields=#(','AminScatterLayerFields=#(#fallScaleGraph,#fallDensityGraph,'+tabs.map(x=>'#'+x).join(',')+',');
 s=s.replace('AminScatterLayerTabs=#(','AminScatterLayerTabs=#('+tabs.map(x=>'#'+x).join(',')+',');
 const a=s.indexOf('    fn applyFalloff rows = ('),b=s.indexOf('    parameters edgeRowSettings (',a);
 if(a<0||b<0)throw Error('Missing falloff methods');
 s=s.slice(0,a)+read('area-falloff-methods.ms')+'\n'+s.slice(b);
 s=s.replace(/rollout (areaUI(?:_\d+)?) "[^]*?\n    \)/g,block=>{
  const a=block.indexOf('        local loadingFall=false'),b=block.indexOf('        fn updateAreas = (',a);
  block=block.slice(0,a)+read('area-falloff-ui.ms')+'\n'+block.slice(b);
  block=block.replace('            areaList.selection=selectedRows','            areaList.selection=selectedRows\n            syncFalloff()');
  block=block.replace('on areaList selectionEnd do (','on areaList selectionEnd do (\n            if areaList.selection.numberSet==1 do fallTarget.selection=2\n            syncFalloff()');
  block=block.replace('for i=rows.count to 1 by -1 do (deleteItem obj.areaNodes rows[i];deleteItem obj.areaModes rows[i])','obj.ensureAreaFalloffs()\n                for i=rows.count to 1 by -1 do (deleteItem obj.areaNodes rows[i];deleteItem obj.areaModes rows[i];deleteItem obj.areaFallConfigs rows[i];deleteItem obj.areaFallScaleGraphs rows[i];deleteItem obj.areaFallDensityGraphs rows[i])');
  block=block.replace('on removeArea pressed do (','on removeArea pressed do (\n            if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()');
  return block;
 });
 const helpers=`global CyrusFallPack,CyrusFallUnpack,CyrusOpenFalloffGraph\nfn CyrusFallPack values = (local s=stringStream "";for i=1 to values.count do format "% %" values[i] (if i<values.count then "," else "") to:s;s as string)\nfn CyrusFallUnpack data = (for v in filterString data "," collect (v as float))\n`;
 return helpers+read('falloff-graph.ms')+'\n'+s;
};


