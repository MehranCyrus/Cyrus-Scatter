// Authoring gates are generated beside the owned model, not patched into its output.
// This is a team-workflow boundary, not protection against replacing MAXScript.
const blocks=require('./maxscript-blocks.cjs');
const mutations=[
 'setSourceRadius','setFallConfig','setFallGraph','assignSourceForward','assignSourceTransform',
 'assignWeight','assignGroup','addEmptySource','addPointSource',
 'replacePointSource','makePointSource','addStroke','removeStroke','setStrokeSelection','removeLogicalLayer','copyLogicalLayer',
 'setGroupCoverage','addPaintArea','removePaintArea','setPaintAreaTarget','setLayerSurfaces',
 'newLayer','removePopulation','refreshAll','clearAllBaked','clearBaked','bakeInstances',
 'resetRandomization','resetSelectedRandomization','copySelectedLayer','removeLayer',
 'procMove','procSetPair','procRemoveRule','procRemoveOwner','procSelectedRadius','procClearRadii',
 'containerSetMode','containerAdd','containerRemove','containerCreate'
];
// Rendering/identity repair and local presentation can write these properties.
const continuity=new Set(`procSchemaValid procSourceNodes procSourceIDs procSourceSlots
 procReceiverNodes procReceiverIDs procReceiverID procRadiusBinding editLayerKey nextEditLayerKey
 layerID activeLayer uiAreaID bakedNodes paintView paintColor showPoints pointsPerPlant iconSize
 viewportMode proxyShape viewportInstances viewportFaces viewportNavigationPoints viewportNavigationInstances viewportNavigationFaces radiusDisplayLimit radiusDisplayAll radiusDisplayMetric
 fieldFalloff fieldBoundaries fieldCombined fieldSamples fieldBandID
 sourceShowRadius showCenters previewBudget pointColorMode solidPointColor layerVisible
 paintSetVisible groupCenters visualSourceNodes visualSourceLabels visualSourceColors
 visualSourceColorSet layerIDColor identificationMode`.split(/\s+/));
module.exports=function(source){
 for(const name of mutations){
  const expression=new RegExp('(^    fn '+name+'\\b[^\\n]*?= \\()','m');
  if(!expression.test(source))throw Error('Missing licensing operation '+name);
  source=source.replace(expression,'$1CyrusRequireAuthor();');
 }
 // Scalar preSet runs before storage. Loading and native Undo restoration must
 // keep their original lifecycle; ordinary setters must not change data first.
 const matches=[...source.matchAll(/^    parameters \w+ \(/gm)].reverse();
 for(const match of matches){
  const start=source.indexOf('(',match.index),end=blocks.close(source,start);
  let body=source.slice(start+1,end-1),guards=[];
  for(const field of body.matchAll(/^        (\w+) type:#(\w+)/gm)){
   const [_,name,type]=field;
   // Table edits also occur during native identity/dependency normalization.
   // Their explicit authoring methods/UI are gated; do not block cold render.
   if(continuity.has(name)||/Tab$/i.test(type))continue;
   // Legacy set overrides preSet in Max. Preserve its invalidation as postSet.
   body=body.replace(new RegExp('(on '+name+' )set(\\s)','g'),'$1postSet$2');
   guards.push('        on '+name+' preSet value do (if not loading and not (cyrusLicenseRestoring()) and value!='+name+' and not (cyrusLicenseAllows()) then '+name+' else value)');
  }
  body+='\n'+guards.join('\n')+'\n    ';
  source=source.slice(0,start+1)+body+source.slice(end-1);
 }
 return source;
};
