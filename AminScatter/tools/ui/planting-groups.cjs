// Shared planting groups are a new evaluated policy; legacy scene evaluation
// remains explicit. Changes belong here/templates, never only in generated MS.
const fs=require('fs');
module.exports=function(s){
 const replace=(a,b)=>{if(s.split(a).length!==2)throw Error('Planting anchor must be unique: '+a.slice(0,110));s=s.replace(a,b);};
 replace('version:49\ninitialRollupState','version:50\ninitialRollupState');
 replace('    fn uiVersion = "1.0.1"','    fn uiVersion = "1.1.0"');
 replace('    on update do (','    on update do (\n        if version<50 do this.groupPolicy=1');
 replace('    local blockerCacheKey=',fs.readFileSync('tools/ui/templates/planting-model.ms','utf8')+'\n    local blockerCacheKey=');
 replace('AminScatterLayerFields=#(','AminScatterLayerFields=#(#paintView,#paintColor,#groupPriority,');
 replace('        paintDocument type:#maxObject','        paintView type:#integer default:2\n        paintColor type:#color default:(color 90 200 150)\n        paintDocument type:#maxObject');
 replace('    fn placements plants previewOnly:false rawOnly:false finalPass:undefined = (',`    fn placements plants previewOnly:false rawOnly:false finalPass:undefined = (
        if this.sharedSpacing() and not rawOnly and finalPass==undefined do return (overlapOwner.groupPlacements this plants previewOnly)`);
 s=s.replaceAll('#(collisionEnabled,collisionRadius,pointRelax,relaxSpacing,relaxIterations,relaxStrength)','#((collisionEnabled and not this.sharedSpacing()),collisionRadius,pointRelax,relaxSpacing,relaxIterations,relaxStrength)');
 replace('if this.paintIdentity and this.paintDocument!=undefined do (','if this.paintIdentity and this.paintDocument!=undefined and not this.sharedSpacing() do (');
 replace('if layer.paintIdentity then cyrusEditStack active rows index signature true else cyrusEditStack active rows index signature','if layer.paintIdentity then (if layer.sharedSpacing() then cyrusEditStack active rows index signature true true else cyrusEditStack active rows index signature true) else cyrusEditStack active rows index signature');
 replace('    fn paintBaseInputKey plants previewOnly = (',`    fn paintBaseInputKey plants previewOnly = (
        local post=if this.sharedSpacing() then #(#groupPriority,#collisionEnabled,#collisionRadius,#overlapEnabled,#overlapRadius,#overlapGap,#overlapPlanar,#overlapBlockers,#overlapSourceRadius,#sourceRadii,#sourceFollowScale,#sourceShowRadius,#finalCleanup,#finalNeighborRadius,#finalMinNeighbors,#finalMinIsland,#finalRelax,#finalStrength,#finalIterations,#finalMaxMove) else #()`);
 replace('key==0 do format "%:%|" key (getProperty this key) to:stream','key==0 and findItem post key==0 and findItem #(#paintView,#paintColor,#showCenters) key==0 do format "%:%|" key (getProperty this key) to:stream');
 replace('            format "EffectiveRelax:%|"','            format "DensityMap:%|" (if densityMap==undefined then 0 else getHandleByAnim densityMap) to:stream\n            format "EffectiveRelax:%|"');
 replace('obj.editLayerKey=nextEditLayerKey;nextEditLayerKey+=1','obj.editLayerKey=nextEditLayerKey;nextEditLayerKey+=1\n            if this.groupPolicy==2 do (obj.paintIdentity=true;obj.groupPriority=if layerObjects.count==0 then 0 else 100-layerObjects.count)');
 replace('if (for e in entries where layerEnabled[e[1]] and e[2].dirty collect e).count>0 do\n            for e in entries where layerEnabled[e[1]] and e[2].overlapEnabled do e[2].dirty=true','if (for e in entries where layerEnabled[e[1]] and e[2].dirty collect e).count>0 do\n            for e in entries where layerEnabled[e[1]] and (this.groupPolicy==2 or e[2].overlapEnabled) do e[2].dirty=true');
 replace('        obj.setOverlapOwner this','        obj.setOverlapOwner this\n        if this.groupPolicy==2 and obj.showCenters!=this.groupCenters do undo off obj.showCenters=this.groupCenters');
 replace('    fn refreshDisplay = (\n        for entry in (layerEntries()) do entry[2].refreshPreview()\n        CyrusViewportRedraw()\n    )',`    fn refreshDisplay = (
        local entries=layerEntries(),pending=this.groupPolicy==2 and groupSnapshotKey!="" and groupSnapshotKey!=this.groupInputKey()
        groupDisplayOnly=this.groupPolicy==2 and updateMode==1
        try (for entry in entries do (entry[2].refreshPreview();if pending and updateMode==1 do entry[2].dirty=true)) catch(groupDisplayOnly=false;throw())
        groupDisplayOnly=false;CyrusViewportRedraw()
    )`);
 replace('        for entry in (layerEntries()) do entry[2].refreshPreview()\n        CyrusViewportRedraw()','        for entry in (layerEntries()) do entry[2].refreshPreview()\n        if this.mainUI.controlsReady do this.mainUI.refreshStats()\n        if this.brushUI.controlsReady do this.brushUI.status()\n        CyrusViewportRedraw()');
 replace('            uiPreviewMode=viewportMode','            uiPreviewMode=if viewportMode==1 and showCenters then 4 else viewportMode');
 replace('    fn brushRelaxPaused = (this.brushMaskActive() and (relaxEnabled or finalRelax))','    fn brushRelaxPaused = ((this.brushMaskActive() and relaxEnabled) or ((this.brushMaskActive() or this.sharedSpacing()) and finalRelax))');
 replace('   text+=("|"+(getHandleByAnim m as string)',`   if root.groupPolicy==2 do for i=1 to root.layerObjects.count do cyrusEditGroupVisibility m root.layerObjects[i].editLayerKey (root.cyrusEnabled and root.visibleLayer i)
   text+=("|"+(getHandleByAnim m as string)`);
 replace('((cyrusBrushStats paintDocument)[1] as string)','((cyrusBrushStats paintDocument)[1] as string)+":"+((cyrusBrushStats paintDocument)[4] as string)');
 // Shared policy changes are also render-cache inputs.
 replace('   format "Enabled:%|" r.cyrusEnabled to:s','   format "Enabled:%|" r.cyrusEnabled to:s\n   for key in #(#groupPolicy,#groupRuleA,#groupRuleB,#groupRuleEnabled,#groupRuleGap,#groupRuleFootprints,#groupRulePlanar) do format "%:%|" key (getProperty r key) to:s');
 replace('    for obj in r.layerObjects do (','    for obj in r.layerObjects do (\n     format "DensityMap:%|" (if obj.densityMap==undefined then 0 else getHandleByAnim obj.densityMap) to:s');
 replace('            do (label="Layer_"','            do (label=(if this.groupPolicy==2 then "Group_" else "Layer_")');
 replace('                local i=activeLayer\n                -- Remap','                local i=activeLayer\n                this.removeGroupRules layerObjects[i]\n                -- Remap');
 replace('            destination.bakedNodes=#()','            destination.bakedNodes=#()\n            if this.groupPolicy==2 do this.copyGroupRules origin destination');
 replace('checkbox showCenterCheck "Show Point"','checkbox showCenterCheck "Plant centres (legacy)"');
 replace('fn syncControls = (populationRadio.state=obj.populationMode;','fn syncControls = (showCenterCheck.visible=not obj.sharedSpacing();populationRadio.state=obj.populationMode;');
 replace('try (undo off ((showCenterCheck.checked=obj.showCenters;','showCenterCheck.visible=not obj.sharedSpacing()\n            try (undo off ((showCenterCheck.checked=obj.showCenters;');
 replace('spinner countSpin "Count: " range:[1,100000,200] type:#integer fieldWidth:64 width:146 pos:[8,174]','spinner countSpin "Candidates: " range:[1,100000,200] type:#integer fieldWidth:64 width:146 pos:[8,174] tooltip:"Generated over the whole receiving surface, before painted coverage and spacing. Increase this for denser small painted areas."');
 // Native templates are replaced as complete rollouts; no dynamic remounting.
 const section=(name,endName,path)=>{
  const a=s.indexOf('    rollout '+name+' '),b=s.indexOf('    '+endName,a);
  if(a<0||b<0)throw Error('Missing planting editor '+name);
  s=s.slice(0,a)+fs.readFileSync(path,'utf8')+'\n'+s.slice(b);
 };
 section('mainUI','fn nativeEditors','tools/ui/templates/planting-manager.ms');
 section('brushUI','rollout areaUI','tools/ui/templates/planting-brush.ms');
 section('separationUI','on update do','tools/ui/templates/planting-separation.ms');
 const a=s.indexOf('    rollout surfaceUI '),b=s.indexOf('    rollout previewUI ',a);
 if(a<0||b<0)throw Error('Missing shared surface rollout');
 s=s.slice(0,a)+s.slice(b);
 replace('this.updateUI,this.surfaceUI,this.previewUI','this.updateUI,this.previewUI');
 s=s.replaceAll('rollout sourceUI "Source Object"','rollout sourceUI "Plant assets"').replaceAll('rollout distributionUI "Point Generation"','rollout distributionUI "Population / Density"');
 s=s.replaceAll('Turn off Use painted density to use Relax.','Choose Whole shared surface to use point Relax.');
 s=s.replaceAll('" layers; "','" groups; "').replaceAll('" layer(s) have a preview error"','" group(s) have a preview error"');
 replace('items:#("Point Cloud","Proxy","Mesh")','items:#("Point Cloud","Proxy","Mesh","Plant centres")');
 replace('displayModeDrop.selection=obj.viewportMode','displayModeDrop.selection=if obj.groupCenters then 4 else obj.viewportMode');
 replace('obj.viewportMode=v;obj.refreshDisplay()','obj.setGroupDisplay v');
 replace('pointsSpin.enabled=obj.viewportMode==1','pointsSpin.enabled=obj.viewportMode==1 and not obj.groupCenters');
 replace('    cyrusBrushBegin layer.paintDocument','    cyrusBrushDisplay layer.paintDocument layer.paintView layer.paintColor\n    cyrusBrushBegin layer.paintDocument');
 s+=`
global CyrusBrushViewportDraw
try(unregisterRedrawViewsCallback CyrusBrushViewportDraw)catch()
fn CyrusBrushViewportDraw = (cyrusBrushDrawCurrent())
registerRedrawViewsCallback CyrusBrushViewportDraw
`;
 return s;
};
