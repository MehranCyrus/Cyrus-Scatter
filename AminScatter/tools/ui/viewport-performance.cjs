// Preserve dependency synchronization while removing redundant redraw work.
module.exports=function(s){
 const replace=(a,b)=>{if(s.split(a).length!==2)throw Error('Viewport performance anchor must be unique: '+a.slice(0,90));s=s.replace(a,b);};
 replace('version:45','version:47');
 replace('    fn previewCache = (\n        if CyrusInteractionHeld() do',
 `    fn previewCache interactionHeld:undefined = (
        local held=if interactionHeld==undefined then CyrusInteractionHeld() else interactionHeld
        if held do`);
 replace('fn AminScatterObjectDraw = (\n    gw.setTransform',
 `fn AminScatterObjectDraw = (
    local held=CyrusInteractionHeld()
    gw.setTransform`);
 replace('            obj.previewCache();obj.drawRadii()\n            if obj.showPoints or obj.showCenters do (\n                local cache=obj.previewCache()',
 `            local cache=obj.previewCache interactionHeld:held
            obj.drawRadii()
            if obj.showPoints or obj.showCenters do (`);
 // Icon geometry depends on only one local scalar. Object transforms remain live.
 replace('    fn iconLines = (\n        local paths=#()',
 `    local iconCacheSize=undefined,iconCachePaths=#()
    fn iconLines = (
        if iconCacheSize==iconSize do return iconCachePaths
        local paths=#()`);
 replace('        for path in paths collect (for p in path collect p*iconSize)',
 `        iconCachePaths=for path in paths collect (for p in path collect p*iconSize)
        iconCacheSize=iconSize
        iconCachePaths`);
 // Compute controller-owned surface/budget inputs once per layer traversal.
 // Standalone callers keep the same behavior through optional arguments.
 replace('    fn syncLayerSurface obj = (\n        obj.setOverlapOwner this\n        local targets=validSurfaces()',
 `    fn syncLayerSurface obj targets:undefined layerBudget:undefined = (
        obj.setOverlapOwner this
        if targets==undefined do targets=validSurfaces()`);
 replace('        local enabledCount=(for flag in layerEnabled where flag collect flag).count\n        local layerBudget=amax 1 (floor(previewBudget/(amax 1 enabledCount)))',
 `        if layerBudget==undefined do (
            local enabledCount=(for flag in layerEnabled where flag collect flag).count
            layerBudget=amax 1 (floor(previewBudget/(amax 1 enabledCount)))
        )`);
 replace('        local entries=#()\n        for i=1 to layerObjects.count where includeDisabled',
 `        local entries=#(),targets=validSurfaces()
        local enabledCount=(for flag in layerEnabled where flag collect flag).count
        local layerBudget=amax 1 (floor(previewBudget/(amax 1 enabledCount)))
        for i=1 to layerObjects.count where includeDisabled`);
 replace('            syncLayerSurface obj\n            obj.checkAnalyzerRevision()',
         '            syncLayerSurface obj targets:targets layerBudget:layerBudget\n            obj.checkAnalyzerRevision()');
 // Held input already displays the last completed preview. Defer dependency
 // synchronization with it; live layer membership/visibility still apply. The
 // first redraw after release goes through the complete synchronization path.
 replace('    fn migrateLayers = (',
 `    fn viewportLayerEntries held = (
        if not held do return layerEntries()
        for i=1 to layerObjects.count where cyrusEnabled and layerEnabled[i] collect #(i,layerObjects[i])
    )
    fn migrateLayers = (`);
 replace('        for entry in n.baseObject.layerEntries() do (',
         '        for entry in n.baseObject.viewportLayerEntries held do (');
 return s;
};
