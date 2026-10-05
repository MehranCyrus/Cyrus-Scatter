// Flowing native layer editors and persisted ownership. Feature control bodies
// are reused; their events are bound to the owner, never global UI selection.
const fs=require('fs');
module.exports=function(s){
 s=s.replace(/\r/g,'');
 const read=n=>fs.readFileSync('tools/ui/templates/'+n+'.ms','utf8').replace(/\r/g,'');
 const one=(a,b)=>{if(s.split(a).length!==2)throw Error('Layers-first anchor: '+a.slice(0,110));s=s.replace(a,b);};
 one('version:50\ninitialRollupState','version:51\ninitialRollupState');
 one('fn uiVersion = "1.1.0"','fn uiVersion = "1.2.3"');
 one('initialRollupState:0xffe','initialRollupState:0xffc');
 const model=read('logical-layers').replace(/(?<![.\w])\b(layerObjects|layerEnabled|layerVisible|layerNames|activeLayer|groupPolicy|overlapOwner)\b/g,'this.$1');
 one('    parameters plantingSettings (',model+'\n    parameters plantingSettings (');
 one('AminScatterLayerFields=#(','AminScatterLayerFields=#(#logicalParentID,#paintSetName,#paintSetWeight,#paintSetEnabled,#paintSetVisible,');
 one('    fn visibleLayer i = (i>0 and i<=layerObjects.count and (i>layerVisible.count or layerVisible[i]))\n','');
 s=s.replaceAll('pointRelax=relaxEnabled and not this.brushMaskActive()','pointRelax=relaxEnabled and not this.layerPaintActive()')
    .replaceAll('(relaxEnabled and not this.brushMaskActive())','(relaxEnabled and not this.layerPaintActive())')
    .replaceAll('(this.brushMaskActive() and relaxEnabled)','(this.layerPaintActive() and relaxEnabled)');
 one('    fn removeLayer = (','    fn removePopulation = (');
 const cs=s.indexOf('    fn copySelectedLayer = ('),ce=s.indexOf('    fn bindNativeUI = (',cs);
 s=s.slice(0,cs)+`    fn copySelectedLayer = (
        local leaf=this.selectedLayer()
        if leaf==undefined do return false
        local parent=this.copyLogicalLayer (this.logicalParent leaf)
        activeLayer=findItem layerObjects parent;parent
    )
    fn removeLayer = (
        local leaf=this.selectedLayer()
        if leaf==undefined do return false
        if leaf.logicalParentID=="" then this.removeLogicalLayer leaf else this.removePaintSet leaf
    )
`+s.slice(ce);
 // Runtime participation and render/Edit consumers share one ownership policy.
 s=s.replaceAll('root.layerEnabled[i] collect','root.enabledLayer i collect')
    .replaceAll('this.layerEnabled[i] do (','this.enabledLayer i do (')
    .replaceAll('overlapOwner.layerEnabled[idx] do','overlapOwner.enabledLayer idx do')
    .replaceAll('(cyrusEnabled and layerEnabled[i])','(cyrusEnabled and this.enabledLayer i)')
    .replaceAll('cyrusEnabled and layerEnabled[i] and','cyrusEnabled and this.enabledLayer i and')
    .replaceAll('where layerEnabled[e[1]] and','where this.enabledLayer e[1] and')
    .replaceAll('root.cyrusEnabled and root.layerEnabled[entry[1]]','root.cyrusEnabled and root.enabledLayer entry[1]');
 s=s.replaceAll('(for flag in layerEnabled where flag collect flag).count','(for i=1 to layerObjects.count where this.enabledLayer i collect i).count');
 one('    fn layerEntries includeDisabled:false = (','    fn layerEntries includeDisabled:false = (\n        this.syncLogicalSettings()');
 one('        for group in this.layerObjects do this.syncLayerSurface group','        this.syncLogicalSettings()\n        for group in this.layerObjects do this.syncLayerSurface group');
 one('    fn groupPair a b = (','    fn groupPair a b = (\n        a=this.logicalParent a;b=this.logicalParent b');
 one('    fn setGroupPair a b enabled gap footprints planar = (','    fn setGroupPair a b enabled gap footprints planar = (\n        a=this.logicalParent a;b=this.logicalParent b');
 // Stable, deterministic allocation; amount remains the authoritative parent
 // budget. No hidden writes to the parent count during child evaluation.
 one('        requestedCount=amount;densityCapped=false','        local allocation=this.effectivePopulation(),seed=this.effectiveSeed()\n        requestedCount=allocation[1];densityCapped=false');
 one('local wanted=areaM2*plantsPerM2','local wanted=areaM2*allocation[2]');
 one('            requestedCount=(amin 100000 (floor(wanted+0.5))) as integer',`            requestedCount=(amin 100000 (floor(wanted+0.5))) as integer
            if overlapOwner!=undefined do (
                local parent=overlapOwner.logicalParent this
                wanted=areaM2*parent.plantsPerM2;densityCapped=wanted>100000
                requestedCount=(overlapOwner.populationAllocation this countOverride:((amin 100000 (floor(wanted+0.5))) as integer))[1]
            )`);
 const pa=s.indexOf('    fn placements '),pb=s.indexOf('\n    fn ',pa+8);
 if(pa<0||pb<0)throw Error('Missing placement body');
 let placement=s.slice(pa,pb).replace(/\brandomSeed\b/g,'seed');
 placement=placement.replace('        local image=undefined', '        if requestedCount<=0 do return #()\n        local image=undefined');
 s=s.slice(0,pa)+placement+s.slice(pb);
 one('            format "EffectiveRelax:%|"','            format "Ownership:%:%:%:%:%|" logicalParentID paintSetEnabled paintSetWeight (this.effectivePopulation()) (this.effectiveSeed()) to:stream\n            format "EffectiveRelax:%|"');
 // Parent groups must be contiguous: cleanup sees their accepted union before
 // another parent is allowed to use that union as a blocker.
 const old='this.layerObjects[order[j]].editLayerKey>this.layerObjects[chosen].editLayerKey';
 one(old,'((this.logicalParent this.layerObjects[order[j]]).editLayerKey>(this.logicalParent this.layerObjects[chosen]).editLayerKey or ((this.logicalParent this.layerObjects[order[j]]).editLayerKey==(this.logicalParent this.layerObjects[chosen]).editLayerKey and this.layerObjects[order[j]].editLayerKey>this.layerObjects[chosen].editLayerKey))');
 one('                    local pair=this.groupPair group this.layerObjects[j]\n                    if pair>0 and groupRuleEnabled[pair] do (',`                    local sibling=(this.logicalParent group)==(this.logicalParent this.layerObjects[j])
                    if sibling and group.collisionEnabled do (
                        local blockers=if completed[j] then accepted[j] else pins[j]
                        if blockers.count>0 do append rules #(blockers,2*group.collisionRadius,false,(for row in rows collect 0.0),(for row in blockers collect 0.0))
                    )
                    local pair=if sibling then 0 else this.groupPair group this.layerObjects[j]
                    if pair>0 and groupRuleEnabled[pair] do (`);
 one('                if group.finalCleanup and finalRows.count>0 do finalRows=cyrusCleanupGroup finalRows group.finalNeighborRadius group.finalMinNeighbors group.finalMinIsland group.overlapPlanar','');
 one('                accepted[i]=finalRows;completed[i]=true;results[i]=#(rows.count,finalRows.count,resolved[2])',`                accepted[i]=finalRows;completed[i]=true;results[i]=#(rows.count,finalRows.count,resolved[2])
                local parent=this.logicalParent group,finished=true
                for j in order where (this.logicalParent this.layerObjects[j])==parent and not completed[j] do finished=false
                if finished do (
                    accepted=this.cleanLogicalLayer parent accepted
                    for j in order where (this.logicalParent this.layerObjects[j])==parent do results[j][2]=accepted[j].count
                )`);
 // Named layers share one flowing host with the general sections and manager.
 const names=['sourceUI','distributionUI','brushUI','areaUI','diversityUI','randomUI','spacingUI','separationUI','proceduralUI','sourceContainersUI'];
 const blocks={};
 for(const name of [...names,'updateUI','previewUI']){if(name==='proceduralUI'||name==='sourceContainersUI'){blocks[name]=read(name==='proceduralUI'?'procedural-ui':'source-containers-ui');continue;}const a=s.indexOf('    rollout '+name+' ');let b=s.indexOf('\n    rollout ',a+1);if(b<0)b=s.indexOf('\n    on update do',a);if(a<0||b<0)throw Error('Missing editor '+name);blocks[name]=s.slice(a,b);}
 const controls=r=>[...r.matchAll(/^\s*(checkbox|spinner|button|pickbutton|dropdownlist|radiobuttons|mapbutton|multiListBox|listbox|colorpicker|edittext) (\w+)/gm)].map(m=>({kind:m[1],name:m[2]}));
 const inventory={general:{},layer:{},set:['setsUI','sourceUI','brushUI','proceduralUI','sourceContainersUI']};
 for(const name of names)inventory.layer[name]=controls(blocks[name]);
 inventory.general.host=controls(read('layers-first-host'));
 for(const name of ['updateUI','previewUI']){const a=s.indexOf('    rollout '+name+' '),b=s.indexOf('\n    rollout ',a+1);inventory.general[name]=controls(s.slice(a,b));}
 for(const name of ['sets','details','panel'])inventory.layer[name+'UI']=controls(read('layers-first-'+name));
 inventory.general.surface=controls(read('layers-flow-surface'));
 inventory.general.manager=controls(read('layers-flow-manager'));
 fs.writeFileSync('tools/ui/layers-control-inventory.json',JSON.stringify(inventory,null,2)+'\n');
 let factories=read('layers-flow-helpers')+'\nglobal CyrusLayerUIRoot,CyrusLayerUIOwner,CyrusLayerUISlot,CyrusLayerUIPanel,CyrusCreateLayerEditors\n';
 // Let Max lay out retained native controls against their actual parent width.
 // Layout expressions are re-evaluated by autoLayoutOnResize; no width timer,
 // HWND resizing or remounting is needed. Height fitting is event-driven.
 const stretchEditor=(r,name)=>{
  r=r.replace(/(rollout \w+ "[^"]+" width:\d+) \(/,'$1 autoLayoutOnResize:true (');
  return r.replace(/^\s*(?:checkbox|spinner|button|pickbutton|dropdownlist|radiobuttons|mapbutton|multiListBox|listbox|colorpicker|edittext|label) .+$/gm,line=>{
   const pos=line.match(/pos:\[(\d+),(\d+)\]/),width=line.match(/\bwidth:(\d+)/);
   if(!pos||!width)throw Error('Missing native layout: '+line);
   const x=Number(pos[1]),w=Number(width[1]);
   let newX=String(x),newWidth;
   if(w>=120) newWidth=`(${name}.width-${x*2})`;
   else if((x===4||x===72)&&(w===62||w===64)){
    newX=x===4?'4':`(${name}.width/2+2)`;
    newWidth=`((${name}.width-12)/2)`;
   }else if(name==='randomUI'&&(x===24||x===84)&&w===50){
    newX=x===24?'24':`((${name}.width+18)/2)`;
    newWidth=`((${name}.width-38)/2)`;
    // Empty-label transform spinners can devote the whole column to the value.
    line=line.replace(/fieldWidth:\d+/,`fieldWidth:${newWidth}`);
   }else if(w===12) return line; // Fixed axis labels.
   else throw Error('Unclassified native layout: '+line);
   if(name==='diversityUI' && /button addInside /.test(line)){
    newX=`(if boundaryOnly then 4 else ${name}.width/2+2)`;
    newWidth=`(if boundaryOnly then ${name}.width-8 else (${name}.width-12)/2)`;
   }
   return line.replace(pos[0],`pos:[${newX},${pos[2]}]`).replace(width[0],`width:${newWidth}`);
  });
 };
 const addFlowHandler=(r,name)=>{
  if(new RegExp('on '+name+' rolledUp').test(r))throw Error('Duplicate flow handler '+name);
  const end=r.lastIndexOf('    )');
  return r.slice(0,end)+`        on ${name} rolledUp state do root.mainUI.layoutPanels()\n`+r.slice(end);
 };
 let nativeRoots='',nativeLayers='';
 for(const name of ['updateUI','surfaceUI','previewUI','layersUI']){
  let r=name==='surfaceUI'?read('layers-flow-surface'):name==='layersUI'?read('layers-flow-manager'):blocks[name];
  if(name==='updateUI'||name==='previewUI'){
   r=r.replace('width:#cmdPanel (','width:162 (\n        local root=CyrusLayerUIRoot')
      .replace(/\bthis\b/g,'root').replace(/(?<![.\w])selectedLayer\(\)/g,'root.selectedLayer()');
   r=stretchEditor(r,name);
  }
  r=addFlowHandler(r,name);
  // General sections are actual scripted-plugin rollouts, so the command
  // panel can distribute them across native columns. Preserve the aliases
  // used by existing feature code; rename only unqualified UI references.
  nativeRoots+=r.replace('local root=CyrusLayerUIRoot','local root=undefined')
   .replace(new RegExp('on '+name+' open do ([^\\n]+)'),(_,body)=>'on '+name+' open do (root=this;'+body+')')
   .replace(new RegExp('(?<![.\\w])'+name+'\\b','g'),'flow_'+name)+'\n';
 }
 const all=['setsUI',...names,'detailsUI'];
 for(let slot=1;slot<=10;slot++){
  for(const name of all){
   let r=name==='setsUI'?read('layers-first-sets'):name==='detailsUI'?read('layers-first-details'):blocks[name];
   if(name!=='setsUI' && name!=='detailsUI' && name!=='proceduralUI' && name!=='sourceContainersUI'){
    r=r.replace('width:#cmdPanel (','width:146 (\n        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel\n        local setSpecific='+(['sourceUI','brushUI'].includes(name)?'true':'false'));
    r=r.replace(/\bthis\b/g,'root').replace(/\bselectedLayer\(\)/g,'selectedPaintSet owner');
    r=r.replaceAll('root source list',"this set's source list").replaceAll("root group's saved paint","this paint set's saved paint").replaceAll('Increase root for denser','Increase this for denser').replaceAll('Within root layer only','Within this layer only').replaceAll('Keep root pair apart','Keep this pair apart');
    r=r.replaceAll('root.selectedPaintSet owner','(if setSpecific then root.selectedPaintSet owner else owner)');
    r=r.replaceAll('bind (selectedPaintSet owner)','bind (if setSpecific then root.selectedPaintSet owner else owner)');
    r=r.replaceAll('local next=if layer==undefined then root else layer','local next=layer');
    r=r.replaceAll('local layer=(if setSpecific then root.selectedPaintSet owner else owner),valid=layer!=undefined and obj==layer','local layer=owner,valid=layer!=undefined and obj==layer');
    r=r.replaceAll('"Painting: "+root.layerNames[root.activeLayer]','"Painting: "+(root.setCaption layer)');
    r=r.replace('fn currentLayer = ((if setSpecific then root.selectedPaintSet owner else owner))','fn currentLayer = owner');
    r=r.replace('where obj.layerObjects[i]!=group do','where obj.layerObjects[i]!=group and obj.layerObjects[i].logicalParentID=="" do');
    r=r.replaceAll('root.resetSelectedRandomization','resetBoundRandomization');
    if(name==='randomUI')r=r.replace('        on resetRotation pressed',`        fn resetBoundRandomization kind = (
            undo "Cyrus reset layer transforms" on owner.resetRandomization kind
            randomUI.bind owner;root.invalidateGroups();true
        )
        on resetRotation pressed`);
    if(name==='spacingUI')r=r.replaceAll('obj.brushMaskActive()','obj.layerPaintActive()');
    if(name==='diversityUI'){
     r=r.replace('obj.diversityMode=v;', 'if v>=3 and (root.layerSets owner).count>1 do (messageBox "Line Pattern / Analyzer need an independent layer. Multi-set layers support Random and Clusters." title:"Cyrus assignment";syncControls();return false);obj.diversityMode=v;');
     r=r.replace('local controlsReady=false','local boundaryOnly=false\n        local controlsReady=false')
      .replace('local boundaryOnly=analyzed','boundaryOnly=analyzed')
      .replace('addInside.pos=[if boundaryOnly then 8 else 84,addOutside.pos.y]','addInside.pos=[if boundaryOnly then 4 else diversityUI.width/2+2,addOutside.pos.y]')
      .replace('addInside.width=if boundaryOnly then 146 else 70','addInside.width=if boundaryOnly then diversityUI.width-8 else (diversityUI.width-12)/2');
     r=r.replace(/(if strokeExpandedHeight>0 do diversityUI.height=[^\n]+\n)\s*true/,'$1            root.mainUI.layoutPanels()');
    }
    // Preserve the standard Max visual style, fitting the nested native width.
    r=r.replace(/width:146/g,'width:132').replace(/pos:\[8,/g,'pos:[4,').replace(/pos:\[84,/g,'pos:[72,').replace(/width:70/g,'width:64');
    if(name==='randomUI')r=r.replace(/pos:\[94,/g,'pos:[84,').replace(/width:58/g,'width:50');
    if(name==='distributionUI')r=r.replace('"Population / Density"','"Population"');
    if(name==='separationUI')r=r.replace('"Group spacing / Cleanup"','"Spacing / Cleanup"');
   }
   r=stretchEditor(r,name);
   r=addFlowHandler(r,name);
   r=r.replace(new RegExp('\\b'+name+'\\b','g'),name+'_'+slot);
   factories+=`global CyrusLayerEditor_${name}_${slot}\nfn CyrusLayerEditor_${name}_${slot} = (\n${r}\n${name}_${slot}\n)\n`;
  }
  let panel=read('layers-first-panel').replace(/\blayerPanel\b/g,'layerPanel_'+slot);
  nativeLayers+=panel.replace('root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,slot=CyrusLayerUISlot','root=undefined,owner=undefined,slot='+slot)
   .replace('on layerPanel_'+slot+' open do bind()','on layerPanel_'+slot+' open do (root=this;bind())')+'\n';
 }
 factories+='fn CyrusCreateLayerEditors slot root owner panel = (\nCyrusLayerUIRoot=root;CyrusLayerUIOwner=owner;CyrusLayerUIPanel=panel\ncase slot of (\n'+Array.from({length:10},(_,i)=>`${i+1}: #(${all.map(n=>`CyrusLayerEditor_${n}_${i+1}()`).join(',')})`).join('\n')+'\n)\n)\n';
 const a=s.indexOf('    rollout sourceUI '),b=s.indexOf('\n    on update do',a);s=s.slice(0,a)+s.slice(b);
 const ma=s.indexOf('    fn bindNativeUI = ('),mb=s.indexOf('\n    on update do',ma);
 s=s.slice(0,ma)+read('layers-first-host')+'\n'+nativeRoots+nativeLayers+'\n'+s.slice(mb);
 one('initialRollupState:0xffc','initialRollupState:0x7ffe');
 s=s.replaceAll('if this.brushUI.controlsReady do this.brushUI.status()','this.refreshBrushEditors()')
    .replaceAll('if root.brushUI.controlsReady do (root.brushUI.refreshHistory();root.brushUI.status())','root.refreshBrushEditors history:true')
    .replaceAll('if root.brushUI.controlsReady do root.brushUI.status()','root.refreshBrushEditors()')
    .replaceAll('if this.randomUI.controlsReady do this.randomUI.bind layer','this.bindNativeUI()');
 s=s.replaceAll('(if this.groupPolicy==2 then "Group_" else "Layer_")','"Layer_"');
 s=s.replace('plugin simpleObject AminScatterObject',factories+'\nplugin simpleObject AminScatterObject');
 return s;
};
