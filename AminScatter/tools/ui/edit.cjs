module.exports=function(s){
 s=s.replace('version:28','version:30');
 const helpers=`
global CyrusEditStackKey,CyrusEditApplyLayer
fn CyrusEditStackKey root = (
 local text=(cyrusEditRevision() as string)
 for n in refs.dependentNodes root where n.baseObject==root do (
  for m in n.modifiers where classof m==CyrusScatterEdit do (
   cyrusEditActiveLayers m (for i=1 to root.layerEnabled.count where root.layerEnabled[i] collect i)
   text+=("|"+(getHandleByAnim m as string)+":"+(m.enabled as string)))
 )
 text
)
fn CyrusEditApplyLayer root layer rows = (
 if root==undefined do return rows
 local owners=for n in refs.dependentNodes root where n.baseObject==root collect n
 if owners.count==0 do return rows
 local mods=owners[1].modifiers
 local active=for m in mods where classof m==CyrusScatterEdit and m.enabled collect m
 if active.count==0 do return rows
 local index=findItem root.layerObjects layer
 local signature=cyrusEditFingerprint rows ((layer.randomSeed as string)+"|"+(layer.diversitySeed as string)+"|"+(index as string))
 cyrusEditStack active rows index signature
)
`;
 // Place definitions before the scripted class, after global declarations.
 s=s.replace('plugin simpleObject AminScatterObject',helpers+'\nplugin simpleObject AminScatterObject');
 s=s.replace('((previewOnly or rawOnly) and isPointSource','(isPointSource');
 s=s.replace('        result\n    )\n    fn refreshPreview',`        if not rawOnly do result=CyrusEditApplyLayer overlapOwner this result
        if not previewOnly and not rawOnly and plants.count>0 do result=for row in result where not (isPointSource (sourceRow plants[row[2]])) collect row
        result
    )
    fn refreshPreview`);
 s=s.replace('    fn layerEntries includeDisabled:false = (',`    local editCacheKey=""
    fn layerEntries includeDisabled:false = (
        local key=CyrusEditStackKey this
        if key!=editCacheKey do (
            editCacheKey=key
            for layer in layerObjects do layer.forcePreviewUpdate()
        )`);
 s=s.replace('local r=n.baseObject\n   format','local r=n.baseObject\n   format "|Edit:%|" (CyrusEditStackKey r) to:s\n   format');
 return s;
};
