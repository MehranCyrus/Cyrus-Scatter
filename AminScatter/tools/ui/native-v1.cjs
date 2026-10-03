// Product UI is composed of ordinary Max command-panel rollouts. Feature stages
// remain the authoritative control definitions, but no nested/factory UI is
// emitted. All selected-layer editors are constructed once per panel lifetime.
const fs=require('fs');
module.exports=function(s){
 const unique=(a,b)=>{if(s.split(a).length!==2)throw Error('v1 anchor must be unique: '+a.slice(0,85));s=s.replace(a,b);};
 function editor(name,root=false){
  const factory=name==='spacingUI'?'spacingUI_1':name;
  const a=s.indexOf(`fn CyrusMake_${factory} target view = (`);
  const tail=s.slice(a).match(new RegExp(`\\n\\s*${factory}\\.obj=target;`));
  const b=tail?a+tail.index:-1;
  if(a<0||b<0)throw Error('Missing native editor '+factory);
  let r=s.slice(s.indexOf('    rollout ',a),b).trimEnd();
  r=r.replace(new RegExp(`\\b${factory}\\b`,'g'),name);
  r=r.replace(/width:(162|136) \(/,'width:#cmdPanel (');
  r=r.replace('obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView','obj=undefined,parentView=undefined');
  if(!r.includes('controlsReady='))r=r.replace('local obj=','local controlsReady=false,\n        obj=');
  r=r.replace('local obj=','local binding=false,\n        obj=');
  if(!r.includes('binding='))r=r.replace('local controlsReady=false,','local binding=false,controlsReady=false,');
  const pat=new RegExp(`        on ${name} open do ([^\\n]+)`);
  const open=r.match(pat);if(!open)throw Error('Missing native init '+name);
  let init=open[1];
  r=r.replace(pat,'').replace(new RegExp(`        on ${name} rolledUp [^\\n]+`),'');
  r=r.replace(new RegExp(`        on ${name} close do [^\\n]+`),'');
  // No Win32 resizing, polling or height correction belongs to a native rollup.
  r=r.replaceAll('parentView.layoutPanels()','true').replaceAll('parentView.dpiScale','1.0');
  r=r.replace('            obj.syncColors()\n','');
  if(name==='spacingUI'){
   r=r.replace('label layerHint "Within this layer only" pos:[8,224] width:120','label layerHint "Within this layer only" pos:[8,224] width:146 height:48');
   r=r.replace('        fn syncControls = (',`        fn syncRelaxAvailability = (
            local wasReady=ready;ready=false
            local layer=this.selectedLayer(),valid=layer!=undefined and obj==layer
            local masked=valid and obj.brushMaskActive(),active=valid and obj.relaxEnabled and not masked
            relaxCheck.checked=valid and obj.relaxEnabled
            -- An already saved paused setting can still be unchecked.
            relaxCheck.enabled=valid and (not masked or obj.relaxEnabled)
            relaxCheck.tooltip="Painted density pauses Relax. Turn off Use painted density to use Relax. Saved settings are preserved."
            spacingSpin.enabled=active;iterationsSpin.enabled=active;strengthSpin.enabled=active
            local message=if masked then "Brush mask active.\\nRelax is paused.\\nCollision remains available." else "Within this layer only"
            if layerHint.text!=message do layerHint.text=message
            ready=wasReady
        )
        fn syncControls = (`);
   r=r.replace('spacingSpin.enabled=obj.relaxEnabled;iterationsSpin.enabled=obj.relaxEnabled;strengthSpin.enabled=obj.relaxEnabled','syncRelaxAvailability()');
   r=r.replace('obj.relaxEnabled=v;syncControls()','undo "Cyrus Relax" on obj.relaxEnabled=(v and not obj.brushMaskActive());syncControls()');
  }
  r=r.replace(/(        on (?!\w+ open\b|\w+ close\b)[^\n]+? do )/g,'$1if controlsReady and not binding and obj!=undefined do ');
  // Do not retain source/area selection indices from the previous layer.
  const controls=[...r.matchAll(/^        (?:multiListBox|listbox) (\w+)/gm)].map(m=>m[1]);
  const clear=controls.map(c=>`${c}.selection=${c==='plantList'||c==='areaList'?'#{}':'0'};`).join('');
  const binds=`
        fn bind layer = (
            local next=${root?'this':'if layer==undefined then this else layer'}
            binding=true;controlsReady=false
            if obj!=next do (${clear})
            obj=next;parentView=this.mainUI
            for c in ${name}.controls do c.enabled=${root?'true':'layer!=undefined'}
            try (undo off (${init})) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        on ${name} open do (controlsReady=true;bind (selectedLayer()))
        on ${name} close do controlsReady=false
`;
  r=r.slice(0,r.lastIndexOf('    )'))+binds+'    )';
  return r;
 }
 const names=['updateUI','surfaceUI','previewUI','sourceUI','distributionUI','areaUI','diversityUI','randomUI','spacingUI'];
 const editors=names.map(n=>editor(n,['updateUI','surfaceUI','previewUI'].includes(n)));
 // Keep separation and final-operation controls from the existing model, in
 // their own ordinary native rollup, independent of layer-list presentation.
 const ma=s.indexOf('fn CyrusMakeManager target view = ('),mb=s.indexOf('\nglobal CyrusMake_spacingUI_1',ma);
 let manager=s.slice(ma,mb);
 const start=manager.indexOf('        local blockerRows=#()'),end=manager.indexOf('        fn resizeColumns',start);
 if(start<0||end<0)throw Error('Missing native separation definition');
 manager=manager.slice(start,end).replace(/pos:\[(\d+),(\d+)\]/g,(_,x,y)=>`pos:[${x},${Number(y)-314}]`);
 manager=manager.replace('        fn currentLayer = (',`        label relaxHint "" pos:[6,614] width:146 height:48
        fn currentLayer = (`);
 manager=manager.replace('        fn refreshOverlap = (',`        fn syncFinalRelaxAvailability = (
            local wasRefreshing=refreshing;refreshing=true
            local layer=currentLayer(),valid=layer!=undefined
            local masked=valid and layer.brushMaskActive(),active=valid and layer.finalRelax and not masked
            boundaryRelaxCheck.checked=valid and layer.finalRelax
            boundaryRelaxCheck.enabled=valid and (not masked or layer.finalRelax)
            boundaryRelaxCheck.tooltip="Painted density pauses Boundary Relax. Turn off Use painted density to use it. Final cleanup remains available."
            finalStrengthSpin.enabled=active;finalIterSpin.enabled=active;finalMoveSpin.enabled=active
            local message=if masked then "Brush mask active.\\nBoundary Relax is paused.\\nFinal cleanup is available." else ""
            if relaxHint.text!=message do relaxHint.text=message
            refreshing=wasRefreshing
        )
        fn refreshOverlap = (`);
 manager=manager.replace('            refreshing=false','            syncFinalRelaxAvailability();refreshing=false');
 manager=manager.replace('(currentLayer()).finalRelax=v','(currentLayer()).finalRelax=(v and not (currentLayer()).brushMaskActive())');
 const sep=`    rollout separationUI "Separation / Final cleanup" width:#cmdPanel (
        local obj=undefined,parentView=undefined,controlsReady=false,refreshing=true
${manager}
        fn bind layer = (
            obj=this;parentView=this.mainUI;refreshing=true
            for c in separationUI.controls do c.enabled=layer!=undefined
            refreshOverlap();controlsReady=true;refreshing=false
        )
        on separationUI open do bind (selectedLayer())
        on separationUI close do (controlsReady=false;refreshing=true)
    )\n`;
 const hostStart=s.indexOf('    rollout mainUI "Cyrus Scatter"'),hostEnd=s.indexOf('\n    on update do',hostStart);
 if(hostStart<0||hostEnd<0)throw Error('Missing nested host to replace');
 let host=fs.readFileSync('tools/ui/templates/native-layers.ms','utf8').trimEnd()+'\n\n';
 host+=`    fn nativeEditors = #(${names.map(n=>'this.'+n).join(',')},this.separationUI)\n`;
 host+=editors.join('\n')+'\n'+sep;
 s=s.slice(0,hostStart)+host+s.slice(hostEnd);
 const fa=s.indexOf('global CyrusUIBuildTarget,CyrusUIBuildView,CyrusUIBuildIndex\n'),fb=s.indexOf('global CyrusEditStackKey,CyrusEditApplyLayer',fa);
 if(fa<0||fb<0)throw Error('Missing obsolete factory region');
 s=s.slice(0,fa)+s.slice(fb);
 unique('fn AminScatterRefreshLayerPanels obj reopen:true = (if obj.mainUI.controlsReady do obj.mainUI.rebuild())','fn AminScatterRefreshLayerPanels obj reopen:true = (obj.bindNativeUI())');
 unique('version:48','version:49');
 unique('    fn uiVersion = "2026-10-02.5"','    fn uiVersion = "1.0.1"');
 unique('        layerObjects type:#maxObjectTab tabSize:0 tabSizeVariable:true',`        layerID type:#string default:""
        layerVisible type:#boolTab tabSize:0 tabSizeVariable:true
        on layerVisible set value index do (global CyrusPointPending;CyrusPointPending=true)
        layerObjects type:#maxObjectTab tabSize:0 tabSizeVariable:true`);
 unique('            append layerNames label;append layerEnabled true','            obj.layerID=CyrusNewLayerID()\n            append layerNames label;append layerEnabled true;append layerVisible true');
 unique('deleteItem layerObjects i;deleteItem layerNames i;deleteItem layerEnabled i','deleteItem layerObjects i;deleteItem layerNames i;deleteItem layerEnabled i\n                if i<=layerVisible.count do deleteItem layerVisible i');
 // Only viewport consumers honor visibility. Placement blockers and final
 // output retain their existing enablement semantics and cached populations.
 unique('        if not held do return layerEntries()','        if not held do return (for entry in layerEntries() where this.visibleLayer entry[1] collect entry)');
 unique('for i=1 to layerObjects.count where cyrusEnabled and layerEnabled[i] collect #(i,layerObjects[i])','for i=1 to layerObjects.count where cyrusEnabled and layerEnabled[i] and this.visibleLayer i collect #(i,layerObjects[i])');
 unique('if CyrusPointAvailable and not n.isHidden do for entry in n.baseObject.layerEntries() do (','if CyrusPointAvailable and not n.isHidden do for entry in n.baseObject.viewportLayerEntries false do (');
 // Expose Cyrus names without breaking class IDs and saved legacy parameters.
 s='global CyrusScatterObject,CyrusNewLayerID\nfn CyrusNewLayerID = (local value=(dotNetClass "System.Guid").NewGuid();value.ToString())\n'+s;
 s+='\nCyrusScatterObject=AminScatterObject\n';
 if(/\bsubrollout\b|\bCyrusMake_|\bwidthTimer\b|\bwindows\.setWindowPos\b/.test(s))throw Error('Obsolete nested UI survived v1 generation');
 return s;
};
