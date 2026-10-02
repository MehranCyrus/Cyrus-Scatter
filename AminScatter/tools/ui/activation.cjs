module.exports=s=>{
 s=s.replace('version:41','version:42');
 s=s.replace('    parameters streetLayoutSettings (',`    parameters activationSettings (
        cyrusEnabled type:#boolean default:true
        on cyrusEnabled set v do (dirty=true;redrawViews())
    )
    fn analyzerOff n = (isValidNode n and isProperty n #cyrusEnabled and not n.cyrusEnabled)
    fn disabledAnalyzerInput = (
        (diversityMode==4 and analyzerOff analyzerNode) or
        ((areaUseLine or areaUsePoints) and analyzerOff areaAnalyzer) or
        ((fallDelete or fallScale or fallDensity) and analyzerOff fallAnalyzer)
    )
    parameters streetLayoutSettings (`);
 s=s.replace('where includeDisabled or layerEnabled[i] do','where includeDisabled or (cyrusEnabled and layerEnabled[i]) do');
 s=s.replace('local enabled=root.layerEnabled[entry[1]]','local enabled=root.cyrusEnabled and root.layerEnabled[entry[1]]');
 s=s.replace('   local r=n.baseObject','   local r=n.baseObject\n   format "Enabled:%|" r.cyrusEnabled to:s');
 s=s.replace('   if r.updateMode==2 do (','   for obj in r.layerObjects do format "Analyzer enabled:%|" (not obj.disabledAnalyzerInput()) to:s\n   if r.updateMode==2 do (');
 s=s.replace('    fn placements plants previewOnly:false rawOnly:false finalPass:undefined = (','    fn placements plants previewOnly:false rawOnly:false finalPass:undefined = (\n        if not cyrusEnabled or disabledAnalyzerInput() do return #()');
 // Return a fresh empty display cache while off; invalidate the previous cache once on transitions.
 s=s.replace('    fn previewCache = (',`    local cachedDisabledInput=false
    fn previewCache = (
        local inputOff=disabledAnalyzerInput()
        if inputOff!=cachedDisabledInput do (dirty=true;cachedDisabledInput=inputOff)
        if inputOff do return (aminScatterBuildPreview #() #() #() 1)`);
 s=s.replace('        subrollout panels "" pos:[0,0]',`        checkbox enableCyrus "Enable Cyrus Scatter" checked:true pos:[8,4] width:220
        on enableCyrus changed v do undo "Enable Cyrus Scatter" on cyrusEnabled=v
        subrollout panels "" pos:[0,28]`);
 s=s.replace('if panels.pos!=[0,0] do panels.pos=[0,0]','if panels.pos!=[0,28] do panels.pos=[0,28]');
 s=s.replace('if mainUI.height!=h do mainUI.height=h','if mainUI.height!=h+28 do mainUI.height=h+28');
 s=s.replace('            controller=this','            controller=this\n            enableCyrus.checked=cyrusEnabled');
 return s;
};

