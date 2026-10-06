// Time is an input only outside a dependency's cached validity interval.
// Apply after feature stages so every real dirty notification re-arms the same
// lifecycle hook, including UI, Brush, containers, Undo, and scripted setters.
const fs=require('fs');
module.exports=function(s) {
 const read=name=>fs.readFileSync('tools/ui/templates/'+name+'.ms','utf8').replace(/\r/g,'');
 const one=(a,b)=>{if(s.split(a).length!==2)throw Error('Input time anchor: '+a.slice(0,100));s=s.replace(a,b);};
 one('    local dirty=true','    local dirty = true');
 s=s.replace(/\b([A-Za-z_]\w*(?:\[\d+\])?)\.dirty=true\b/g,'$1.markInputDirty()');
 const bare=(s.match(/(?<![\w.])dirty=true\b/g)||[]).length;
 if(bare<100)throw Error('Missing Scatter dirty lifecycle handlers');
 s=s.replace(/(?<![\w.])dirty=true\b/g,'markInputDirty()');
 if(/\.dirty=true\b/.test(s))throw Error('Unclassified qualified dirty assignment');
 one('    local dirty = true','    local dirty = true\n'+read('input-time'));
 one('    fn layerEntries includeDisabled:false = (',`    fn layerEntries includeDisabled:false = (
        this.ensureTimeOwner()
        if cyrusEnabled and updateMode==2 do (
            this.liveTimeChanged()
            this.inputTimeKey();inputTimeObserved=inputTimeStamp
        )`);
 one('            local answer=cspImpl_refreshPreview()',`            this.inputTimeKey()
            local answer=cspImpl_refreshPreview()
            inputTimeObserved=inputTimeStamp`);
 one('    fn procInstallPreview state pending = (','    fn procInstallPreview state pending = (\n        inputTimeObserved=inputTimeStamp');
 one('        checkAnalyzerRevision()\n        if dirty',`        checkAnalyzerRevision()
        if updateMode==2 do this.invalidateInputTime()
        if dirty`);
 one('currentTime (if this.proceduralPolicy() then procGeometryRevision else CyrusPFRevision)',
     '(this.inputTimeKey()) (if this.proceduralPolicy() then procGeometryRevision else CyrusPFRevision)');
 one('currentTime CyrusPFRevision CyrusPFManualRevision cyrusEnabled this.layerEnabled',
     '(this.inputTimeKey()) CyrusPFRevision CyrusPFManualRevision cyrusEnabled this.layerEnabled');
 one('currentTime CyrusPFRevision CyrusPFManualRevision plants to:stream',
     '(this.inputTimeKey()) CyrusPFRevision CyrusPFManualRevision plants to:stream');
 one('currentTime 0 procManualRevision cyrusEnabled layerEnabled',
     '(this.inputTimeKey()) 0 procManualRevision cyrusEnabled layerEnabled');
 // The render transport must not rebuild solely because an unrelated frame
 // changed. Actual animation is represented by the owner/leaf validity keys.
 one('currentTime CyrusPFRevision CyrusPFManualRevision to:s','0 CyrusPFRevision CyrusPFManualRevision to:s');
 one('   local r=n.baseObject','   local r=n.baseObject\n   if r.updateMode==2 and r.groupPolicy!=3 do format "InputTime:%|" (r.publishedInputTime()) to:s');
 one('    for obj in r.layerObjects do (','    for obj in r.layerObjects do (\n     format "InputTime:%|Texture:%|" (obj.publishedInputTime()) obj.procDensityRevision to:s');
 one('fn AminScatterLiveTime = (\n    if AminScatterRenderRedrawHeld!=true do (\n        for n in objects where classof n.baseObject==AminScatterObject do (for entry in (n.baseObject.layerEntries includeDisabled:true) do entry[2].invalidateLive())\n        CyrusViewportRedraw()\n    )\n)',`fn AminScatterLiveTime = (
    if AminScatterRenderRedrawHeld==true do return false
    local changed=false
    for node in CyrusTimeOwners where isValidNode node and not node.isHidden do (
        local root=node.baseObject
        if root.liveTimeChanged() do changed=true
    )
    if changed do CyrusViewportRedraw()
    changed
)`);
 one('    on attachedToNode n do (n.renderable=false;n.wirecolor=red)',
     '    on attachedToNode n do (n.renderable=false;n.wirecolor=red;timeOwnerRegistered=false;CyrusRegisterTimeOwner n)');
 one('fn AminScatterLiveChanged event handles = (','fn AminScatterLiveChanged event handles = (\n    if event==#deleted do CyrusPruneTimeOwners()');
 s=read('input-time-owners')+'\n'+s;
 s+=`\ncallbacks.removeScripts id:#CyrusInputTimeOwners
callbacks.addScript #filePostOpen "CyrusResetTimeOwners()" id:#CyrusInputTimeOwners persistent:false
callbacks.addScript #filePostMerge "CyrusResetTimeOwners()" id:#CyrusInputTimeOwners persistent:false
callbacks.addScript #systemPostReset "CyrusResetTimeOwners()" id:#CyrusInputTimeOwners persistent:false
callbacks.addScript #sceneUndo "CyrusResetTimeOwners()" id:#CyrusInputTimeOwners persistent:false
callbacks.addScript #sceneRedo "CyrusResetTimeOwners()" id:#CyrusInputTimeOwners persistent:false
callbacks.addScript #nodeCreated "CyrusRegisterTimeOwner (callbacks.notificationParam())" id:#CyrusInputTimeOwners persistent:false
CyrusResetTimeOwners()
`;
 return s;
};
