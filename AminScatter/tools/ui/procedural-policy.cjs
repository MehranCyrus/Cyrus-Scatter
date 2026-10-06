// Policy 3 is explicit and versioned. Transform only after the legacy generator
// stages have finished matching their original anchors.
const fs=require('fs');
module.exports=function(s){
 const read=n=>fs.readFileSync('tools/ui/templates/'+n+'.ms','utf8').replace(/\r/g,'');
 const one=(a,b)=>{if(s.split(a).length!==2)throw Error('Procedural policy anchor: '+a.slice(0,120));s=s.replace(a,b);};
 let model=read('procedural-model');const evaluation=read('procedural-evaluation');
 const fields=[...model.matchAll(/^        (\w+) type:/gm)].map(m=>m[1]);
 const tabs=[...model.matchAll(/^        (\w+) type:#\w+Tab/gm)].map(m=>m[1]);
 const layerFields=fields.filter(n=>!n.startsWith('procRule')&&!n.startsWith('containerGlobal'));
 const end=model.indexOf('\n    )\n    local procCandidateCount');
 model=model.slice(0,end)+'\n'+fields.map(n=>`        on ${n} set value${tabs.includes(n)?' index':''} do dirty=true`).join('\n')+model.slice(end);
 // MAXScript binds unqualified names at definition time. Declare the new
 // state before any old methods consume it; define the new methods only after
 // the legacy layer/group state and helpers they consume have been declared.
 const functions=model.indexOf('    fn proceduralPolicy');
 one('    parameters paintSettings (',model.slice(0,functions)+'\n    parameters paintSettings (');
 one('    fn nativeEditors =',model.slice(functions)+'\n'+read('source-containers')+'\n'+evaluation+'\n'+read('publication-read')+'\n    fn nativeEditors =');
 one('version:51\ninitialRollupState','version:53\ninitialRollupState');
 one('fn uiVersion = "1.2.3"','fn uiVersion = "0.7.1"');
 s=s.replaceAll('Cyrus Scatter 1.2','Cyrus Scatter 0.7.1');
 // Central capability predicate: all consumers of shared published placements
 // understand policy 3; the implementations of policy 1/2 remain available.
 s=s.replace(/\b((?:\w+\.)*groupPolicy)==2/g,'(CyrusUsesSharedPolicy $1)')
    .replace(/\b((?:\w+\.)*groupPolicy)!=2/g,'(not (CyrusUsesSharedPolicy $1))');
 one('global CyrusEditStackKey,CyrusEditApplyLayer','global CyrusUsesSharedPolicy\nfn CyrusUsesSharedPolicy policy = (policy==2 or policy==3)\nglobal CyrusEditStackKey,CyrusEditApplyLayer');
 one('fn CyrusEditStackKey root = (','fn CyrusEditStackKey root = (\n if root.groupPolicy==3 do return root.procEditKey()');
 one(' local signature=if layer.paintIdentity then layer.paintPopulation else',' local signature=if root.groupPolicy==3 then layer.procBindingKey else if layer.paintIdentity then layer.paintPopulation else');
 one('    fn evaluateGroups = (','    fn evaluateGroups = (\n        if groupPolicy==3 do return this.evaluateProcedural()');
 one('    fn groupPlacements group plants previewOnly = (',`    fn groupPlacements group plants previewOnly = (
        if groupPolicy==3 do (
            local snapshot=if groupDisplayOnly and groupSnapshotKey!="" then groupSnapshotRows else this.procReadSnapshot()
            local index=findItem procPublishedOwners group
            if index==0 do return #()
            local rows=snapshot[index]
            if not previewOnly do (
                local published=procPublishedSources[index]
                local same=plants.count==published.count
                if same do for i=1 to plants.count where plants[i]!=published[i] do same=false
                if not same do throw "Pending source changes differ from the published result. Use outputSources() for exact output, or Update."
                if plants.count==0 and rows.count>0 do throw "Assign plant assets before final output."
                rows=group.filterSourceRowsByPolicy rows procPublishedFinalKeep[index]
            )
            return rows
        )`);
 one('    fn bakeInstances ownerNode = (\n        local plants=validSources()', '    fn bakeInstances ownerNode = (\n        local plants=this.outputSources()');
 one('     local sources=obj.validSources()', '     local sources=obj.outputSources()');
 one('and (obj.validSurfaces()).count>0 do (', 'and (root.groupPolicy==3 or (obj.validSurfaces()).count>0) do (');
 one('   if r.updateMode==2 do (', `   if r.groupPolicy==3 do format "Procedural:%:%|" r.procEpoch (if r.updateMode==2 then r.procInputKey() else "published") to:s
   if r.updateMode==2 and r.groupPolicy!=3 do (`);
 one('    fn refreshPreview = (','    fn refreshPreview = (\n        if this.proceduralPolicy() do return this.procRefreshPreview()');
 one('hasResult:(cachedPoints!=undefined and previewError=="")','hasResult:(cachedPoints!=undefined and (previewError=="" or this.proceduralPolicy()))');
 one('    fn groupInputKey = (','    fn groupInputKey = (\n        if groupPolicy==3 do return this.procInputKey()');
 one('global CyrusPFManualRevision; if CyrusPFManualRevision!=undefined do CyrusPFManualRevision+=1','global CyrusPFManualRevision; if groupPolicy==3 then procManualRevision+=1 else if CyrusPFManualRevision!=undefined do CyrusPFManualRevision+=1');
 one('currentTime CyrusPFRevision CyrusPFManualRevision plants previewOnly to:stream','currentTime (if this.proceduralPolicy() then procGeometryRevision else CyrusPFRevision) (if this.proceduralPolicy() and overlapOwner!=undefined then overlapOwner.procManualRevision else CyrusPFManualRevision) (this.containerSourceKey plants) previewOnly to:stream');
 one('key==0 do format "%:%|" key (getProperty this key) to:stream','key==0 do format "%:%|" key (if key==#sources then this.containerSourceKey (sources as array) else getProperty this key) to:stream');
 one('where isValidNode n do format "%:%|" (getHandleByAnim n) n.objectTransform to:stream',`where isValidNode n do (
                local tm=n.objectTransform
                if this.proceduralPolicy() and this.containerProvider()!=undefined and findItem sources n>0 do tm.row4=[0,0,0]
                format "%:%|" (getHandleByAnim n) tm to:stream
            )`);
 one('        for n in objects where classof n.baseObject==AminScatterObject do (\n            for entry in (n.baseObject.layerEntries includeDisabled:true) do (',`        for n in objects where classof n.baseObject==AminScatterObject do (
            if n.baseObject.containerNote event nodes do redraw=true
            for entry in (n.baseObject.layerEntries includeDisabled:true) do (
                if n.baseObject.groupPolicy==3 then (if entry[2].procExternalChanged event nodes do redraw=true)
                else`);
 one('callbackEnd:CyrusScatterLiveBatchEnd deleted:AminScatterLiveChanged','callbackEnd:CyrusScatterLiveBatchEnd added:AminScatterLiveChanged deleted:AminScatterLiveChanged');
 one('for layer in layerObjects do layer.forcePreviewUpdate()','for layer in layerObjects do (if groupPolicy==3 then layer.dirty=true else layer.forcePreviewUpdate())');
 one('    fn applyPaint rows = (','    fn applyPaint rows = (\n        if this.proceduralPolicy() do return this.procApplyPaint rows');
 one('    fn placementRadii rows plants = (','    fn placementRadii rows plants = (\n        if this.proceduralPolicy() do return this.procRadii rows plants');
 one('    fn removeGroupRules group = (','    fn removeGroupRules group = (\n        this.procRemoveOwner group');
 one('    fn logicalLayers = (for leaf in this.layerObjects where leaf.logicalParentID=="" collect leaf)',`    fn logicalLayers = (
        local members=for leaf in this.layerObjects where leaf.logicalParentID=="" collect leaf
        if this.groupPolicy==3 then this.procSort members else members
    )`);
 one('    fn layerSets parent = (for leaf in this.layerObjects where leaf==parent or leaf.logicalParentID==parent.layerID collect leaf)',`    fn layerSets parent = (
        local members=for leaf in this.layerObjects where leaf==parent or leaf.logicalParentID==parent.layerID collect leaf
        if this.groupPolicy==3 then this.procSort members sets:true else members
    )`);
 one('local parent=this.logicalParent leaf,members=this.layerSets parent,total=0.0','local parent=this.logicalParent leaf,members=(for candidate in this.layerObjects where candidate==parent or candidate.logicalParentID==parent.layerID collect candidate),total=0.0');
 one('    fn effectiveSeed = (','    fn effectiveSeed = (\n        if this.proceduralPolicy() do return ((mod ((randomSeed as integer64)+(procSamplingSalt as integer64)*104729) 2147483647) as integer)');
 one('        local own=#(',`        local own=#(${layerFields.map(n=>'#'+n).join(',')},`);
 one('AminScatterLayerFields=#(',`AminScatterLayerFields=#(${layerFields.map(n=>'#'+n).join(',')},`);
 one('AminScatterLayerTabs=#(',`AminScatterLayerTabs=#(${tabs.filter(n=>!n.startsWith('procRule')&&!n.startsWith('containerGlobal')).map(n=>'#'+n).join(',')},`);
 one('        local pointRelax=relaxEnabled and not this.layerPaintActive(),','        local pointRelax=relaxEnabled and not this.layerPaintActive() and not this.proceduralPolicy(),');
 one('        if requestedCount<=0 do return #()','        if this.proceduralPolicy() and procCandidateCount!=undefined do requestedCount=procCandidateCount\n        if requestedCount<=0 do return #()');
 one('        local result=undefined\n        if baseKey!=undefined', '        if baseKey!=undefined and this.proceduralPolicy() do baseKey+="|StablePool:"+(requestedCount as string)\n        local result=undefined\n        if baseKey!=undefined');
 one('            if paintIdentity then (generate targets requestedCount','            if this.proceduralPolicy() do join nativeOptions #(1,0)\n            if paintIdentity then (generate targets requestedCount');
 one('result=cyrusWholeScale result wholeScaleMin wholeScaleMax seed','result=(if this.proceduralPolicy() then cyrusWholeScale result wholeScaleMin wholeScaleMax seed true else cyrusWholeScale result wholeScaleMin wholeScaleMax seed)');
 one('rows=cyrusBoundaryFalloff rows paths cfg randomSeed','rows=(if this.proceduralPolicy() then cyrusBoundaryFalloff rows paths cfg (this.effectiveSeed()) true else cyrusBoundaryFalloff rows paths cfg randomSeed)');
 one('rows=cyrusAreaFalloff rows this.areaNodes[i] cfg randomSeed (if i<=this.areaModes.count then this.areaModes[i] else 1)','rows=(if this.proceduralPolicy() then cyrusAreaFalloff rows this.areaNodes[i] cfg (((mod ((this.effectiveSeed() as integer64)+i*1009) 2147483647)) as integer) (if i<=this.areaModes.count then this.areaModes[i] else 1) true else cyrusAreaFalloff rows this.areaNodes[i] cfg randomSeed (if i<=this.areaModes.count then this.areaModes[i] else 1))');
 // Presentation and post-generation policy cannot invalidate candidate caches.
 one('        local stream=stringStream ""\n        with printAllElements on (\n            format "%|%|%|%|%|"',`        if this.proceduralPolicy() do join post #(${layerFields.filter(n=>n!=='procSamplingSalt').map(n=>'#'+n).join(',')})
        local stream=stringStream ""
        with printAllElements on (
            format "%|%|%|%|%|"`);
 one('and findItem #(#paintView,#paintColor,#showCenters) key==0','and findItem #(#paintView,#paintColor,#showCenters,#paintSetName,#paintSetVisible,#uiPaintSetID) key==0');
 one('            append layerObjects obj','            if groupPolicy==3 do (obj.procOrder=nextEditLayerKey;obj.procSetOrder=nextEditLayerKey)\n            append layerObjects obj');
 one('            leaf.logicalParentID=parent.layerID;leaf.paintSetName=label','            leaf.logicalParentID=parent.layerID;leaf.paintSetName=label\n            if this.groupPolicy==3 do (leaf.procSamplingSalt=leaf.editLayerKey;leaf.procSetOrder=this.nextEditLayerKey)');
 one('local members=this.layerSets origin,copyParent','local members=(for candidate in this.layerObjects where candidate==origin or candidate.logicalParentID==origin.layerID collect candidate),copyParent,copies=#()');
 one('            for member in members do (\n                this.newLayer();local destination=this.selectedLayer()', '            for member in members do (\n                this.newLayer();local destination=this.selectedLayer();append copies destination');
 one('        )\n        this.invalidateGroups();this.bindNativeUI();copyParent',`            if this.groupPolicy==3 do this.procCopyRelations members copies
        )
        this.invalidateGroups();this.bindNativeUI();copyParent`);
 // New controls replace the legacy priority/pair editor only on policy 3.
 s=s.replaceAll('local masked=valid and obj.layerPaintActive(),active=', 'local masked=valid and (obj.layerPaintActive() or obj.proceduralPolicy()),active=');
 s=s.replaceAll('Painted density pauses Relax. Choose Whole shared surface to use point Relax. Saved settings are preserved.', 'Brush or Procedural 0.7 pauses point Relax. Saved settings are preserved.');
 s=s.replaceAll('Brush mask active.\\nRelax is paused.\\nCollision remains available.', 'Relax is paused for this policy/coverage. Spacing remains available.');
 s=s.replaceAll('obj.layerPaintActive() and obj.relaxEnabled','(obj.layerPaintActive() or obj.proceduralPolicy()) and obj.relaxEnabled');
 s=s.replaceAll('not obj.layerPaintActive()', '(not obj.layerPaintActive() and not obj.proceduralPolicy())');
 one('fn brushRelaxPaused = ((this.layerPaintActive() and relaxEnabled)','fn brushRelaxPaused = (((this.layerPaintActive() or this.proceduralPolicy()) and relaxEnabled)');
 s+=read('procedural-notifications');
 return s;
};
