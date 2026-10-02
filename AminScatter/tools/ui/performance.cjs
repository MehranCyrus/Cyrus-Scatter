module.exports=s=>{
 const replace=(a,b)=>{if(!s.includes(a))throw Error('Performance anchor missing: '+a.slice(0,90));s=s.replace(a,b)};
 replace('version:42','version:44');
 // Keep layer contents unmounted until the user opens that layer.
 let lazyLayers=0;
 s=s.replace(/on (layerPanel_\d+) open do \(\n( +children=#[^]*?)\n        \)\n        on \1 close do \(children=#\(\)\)\n        on \1 rolledUp state do parentView.layoutPanels\(\)/g,(_,name,body)=>{
  lazyLayers++;
  return `local pendingSections=#()
        fn sectionStates = (if children.count==0 then pendingSections else (for r in children collect r.open))
        fn ensureContents = (
            if children.count==0 do (
                local wasBuilding=parentView.building
                parentView.building=true
                try (
${body.replace(/\n\s+fitHeight\(\)\s*$/,'')}
                    for k=1 to (amin children.count pendingSections.count) do children[k].open=pendingSections[k]
                    pendingSections=#()
                    fitHeight()
                )catch(
                    for r in children where r.isDisplayed do try(removeSubRollout sections r)catch()
                    children=#();parentView.building=wasBuilding
                    throw()
                )
                parentView.building=wasBuilding
            )
        )
        on ${name} open do (children=#();pendingSections=#();${name}.height=24)
        on ${name} close do (children=#();pendingSections=#())
        on ${name} rolledUp expanded do (
            if expanded and not parentView.building do (
                ensureContents()
                parentView.selectLayerView obj
            )
            parentView.layoutPanels()
        )`;
 });
 if(lazyLayers!==10)throw Error('Expected ten lazy layer handlers, got '+lazyLayers);
 replace('if previous!=undefined do for k=1 to r.children.count do r.children[k].open=previous[3][k]', 'if previous!=undefined do (r.pendingSections=previous[3];if previous[2] do r.ensureContents())');
 // Mouse polling also covers spinners and native sub-object transforms.
 s=`global CyrusInteractionHeld,CyrusWasDragging=false,CyrusReleaseTimer,CyrusReleaseTick\nfn CyrusInteractionHeld = (try((dotNetClass "System.Windows.Forms.Control").MouseButtons != (dotNetClass "System.Windows.Forms.MouseButtons").None)catch(false))\n`+s;
 replace('    fn previewCache = (','    fn previewCache = (\n        if CyrusInteractionHeld() do (CyrusWasDragging=true;return cachedPoints)');
 replace(' if not CyrusPFBusy and (not CyrusPFProduction or CyrusPFIR()) do (',' if not CyrusPFBusy and not CyrusInteractionHeld() and (not CyrusPFProduction or CyrusPFIR()) do (');
 s=s.replace('NodeEventCallback mouseUp:false delay:150','NodeEventCallback mouseUp:true delay:150');
 // Cache only raw blocker placements, never the edited/final output. The key includes
 // all persisted placement inputs and dependency revisions. External events and time
 // changes are represented by PF revision/time. No recursion through overlap layers.
 replace('    fn placements plants previewOnly:false rawOnly:false finalPass:undefined = (',`    local blockerCacheKey="",blockerCacheRows=#(),blockerCacheBuilds=0,blockerCacheHits=0
    fn cachedBlockerRows plants = (
        local stream=stringStream ""
        with printAllElements on (
            format "%|%|%|%|" currentTime CyrusPFRevision CyrusPFManualRevision plants to:stream
            for key in (AminScatterLayerFields+#(#cyrusEnabled,#surfaceNodes,#strokeSides,#strokeModes,#strokeColorRows,#strokeColorKeys,#strokeSourceRows,#strokeSourceNodes,#strokeMin,#strokeMax,#analyzerNode)) do (
                if isProperty this key do try(format "%:%|" key (getProperty this key) to:stream)catch()
            )
            for n in ((surfaceNodes as array)+(sources as array)+(areaNodes as array)+(patternLines as array)+#(analyzerNode,areaAnalyzer,fallAnalyzer)) where isValidNode n do format "%:%|" (getHandleByAnim n) n.transform to:stream
            for a in #(analyzerNode,areaAnalyzer,fallAnalyzer) where isValidNode a do format "%|" (a.getAnalysisRuns()) to:stream
        )
        local key=stream as string
        if key!=blockerCacheKey then (
            blockerCacheRows=this.placements plants previewOnly:showCenters rawOnly:true
            blockerCacheKey=key;blockerCacheBuilds+=1
        ) else blockerCacheHits+=1
        blockerCacheRows
    )
    fn blockerCacheStats = (#(blockerCacheBuilds,blockerCacheHits))
    fn placements plants previewOnly:false rawOnly:false finalPass:undefined = (`);
 replace('local blocked=blocker.placements src previewOnly:blocker.showCenters rawOnly:true','local blocked=blocker.cachedBlockerRows src');
 replace('fn CyrusPFClear = (','global CyrusPFDeletedHandles=#()\nfn CyrusPFClear = (\n CyrusPFDeletedHandles=for n in CyrusPFNodes where isValidNode n collect (getHandleByAnim n)');
 replace('fn AminScatterLiveChanged event handles = (','fn AminScatterLiveChanged event handles = (\n    if event==#deleted do (handles=for h in handles where findItem CyrusPFDeletedHandles h==0 collect h;if handles.count==0 do return false)');
 // Display/sub-object state sends modelOtherEvent without geometry changes.
 s=s.replace(' modelOtherEvent:AminScatterLiveChanged','');
 replace('local nodes=for h in handles collect (getAnimByHandle h)', 'local nodes=for h in handles collect (getAnimByHandle h)\n        -- Analyzer helper geometry invalidates on selection too. Its data revision\n        -- is polled by previewCache/PFKey, so do not treat icon notifications as data.\n        nodes=for n in nodes where not (isValidNode n and isProperty n #samplePoints and isProperty n #pathCounts) collect n\n        if event!=#deleted and nodes.count==0 do return false');
 // Poll Analyzer DATA revisions before propagating overlap dirtiness, not only
 // while drawing each layer; dependent grass must see an Analyzer-only edit too.
 const pa=s.indexOf('        if updateMode==2 and isValidNode areaAnalyzer',s.indexOf('    fn previewCache = ('));
 const pb=s.indexOf('        if dirty and ',pa);
 if(pa<0||pb<0)throw Error('Analyzer revision polling anchor missing');
 const poll=s.slice(pa,pb);
 s=s.slice(0,pa)+'        checkAnalyzerRevision()\n'+s.slice(pb);
 replace('    local cachedDisabledInput=false','    fn checkAnalyzerRevision = (\n'+poll+'    )\n    local cachedDisabledInput=false');
 replace('            syncLayerSurface obj\n            append entries', '            syncLayerSurface obj\n            obj.checkAnalyzerRevision()\n            append entries');
 // Wait for a settled input key before stopping/restarting IR. Do not absorb a new
 // key into the render signature without actually building its output.
 replace('global CyrusPFProduction=false,CyrusPFPhase=0','global CyrusPFProduction=false,CyrusPFPhase=0,CyrusPFPendingKey="",CyrusPFStableSince=0');
 replace('   if CyrusPFResume or CyrusPFKey()!=CyrusPFSignature do (\n    CyrusPFPhase=1\n    if active do CoronaRenderer.stopRender()\n   )',`   local wanted=CyrusPFKey()
   if wanted!=CyrusPFSignature or CyrusPFResume then (
    if wanted!=CyrusPFPendingKey then (CyrusPFPendingKey=wanted;CyrusPFStableSince=timeStamp())
    else if abs(timeStamp()-CyrusPFStableSince)>=1000 do (
     CyrusPFPhase=1;CyrusPFPendingKey=""
     if active do CoronaRenderer.stopRender()
    )
   ) else CyrusPFPendingKey=""`);
 s+=`\ntry(CyrusReleaseTimer.Stop())catch()
fn CyrusReleaseTick sender args = (
 if CyrusInteractionHeld() then CyrusWasDragging=true
 else if CyrusWasDragging do (CyrusWasDragging=false;redrawViews())
)
CyrusReleaseTimer=dotNetObject "System.Windows.Forms.Timer"
CyrusReleaseTimer.Interval=200
dotNet.addEventHandler CyrusReleaseTimer "Tick" CyrusReleaseTick
CyrusReleaseTimer.Start()
`;
 if(!s.includes('fn ensureContents'))throw Error('Lazy layer patch failed');
 return s;
};
