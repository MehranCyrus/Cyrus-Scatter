const fs=require('fs');
module.exports=function(s){
 const replace=(a,b)=>{if(s.split(a).length!==2)throw Error('Brush anchor must be unique: '+a.slice(0,100));s=s.replace(a,b);};
 s='global CyrusStartBrush,CyrusStopBrush,CyrusBrushSessionRoot,CyrusBrushSessionLayer\n'+s;
 const integration=fs.readFileSync('tools/ui/templates/brush-integration.ms','utf8');
 const methods=integration.indexOf('    fn checkPaintRevision = (');
 const brushUI=integration.indexOf('    rollout brushUI ');
 replace('    parameters settings (',integration.slice(0,methods)+'\n    parameters settings (');
 replace('    fn selectedLayer = (',integration.slice(methods,brushUI)+'\n    fn selectedLayer = (');
 replace('    rollout areaUI ',integration.slice(brushUI)+'\n    rollout areaUI ');
 replace('version:49\n(','version:49\ninitialRollupState:0xffe\n(');
 replace('this.spacingUI,this.separationUI)','this.spacingUI,this.separationUI,this.brushUI)');
 replace('    fn validSurfaces = (',`    fn validSurfaces = (
        if this.paintIdentity and this.paintDocument!=undefined do (
            local target=cyrusBrushTarget this.paintDocument
            return (if isValidNode target then #(target) else #())
        )`);
 replace('obj.checkAnalyzerRevision()','obj.checkAnalyzerRevision();obj.checkPaintRevision()');
 replace('        activeLayer=i\n    )','        if CyrusBrushSessionLayer!=undefined do CyrusStopBrush()\n        activeLayer=i\n    )');
 replace('        if not cyrusEnabled or disabledAnalyzerInput() do return #()',`        if not cyrusEnabled or disabledAnalyzerInput() do return #()
        if paintEnabled and (finalRelax or relaxEnabled) do throw "Brush density with point relaxation requires a mask-constrained solver. Disable Relax for this layer. Collision and final cleanup are supported."
        if paintEnabled and not projectMove and (movXMin!=0 or movXMax!=0 or movYMin!=0 or movYMax!=0 or movZMin!=0 or movZMax!=0 or movementRange!=0) do throw "Brush requires projected movement."`);
 replace('local result=if finalPass==undefined and sourceWeights.count==0','local result=if not paintIdentity and distributionMode!=3 and finalPass==undefined and sourceWeights.count==0');
 replace('            aminScatterAdvanced targets requestedCount', '            local generate=if paintIdentity then cyrusScatterAdvanced else aminScatterAdvanced\n            local nativeOptions=if paintIdentity then #(paintIdentity,not advancedAxes,scaleMinimum,scaleMaximum,tiltDegrees,yawMinimum,yawMaximum,movementRange) else undefined\n            generate targets requestedCount');
 // Dispatch with optional keyed transport while leaving the legacy call's
 // argument count unchanged; MAXScript cannot spread an arbitrary arg array.
 const start=s.indexOf('            generate targets requestedCount'),end=s.indexOf('\n        )\n        if finalPass!=undefined',start);
 if(start<0||end<0)throw Error('Missing keyed generation invocation');
 const call=s.slice(start,end).trim();
 s=s.slice(0,start)+'            if paintIdentity then ('+call+' nativeOptions) else ('+call+')'+s.slice(end);
 const ga=s.indexOf('        local result=if not paintIdentity'),gb=s.indexOf('        if plants.count>0 and sourceEmpty.count>0',ga);
 if(ga<0||gb<0)throw Error('Missing complete base population stage');
 const base=s.slice(ga,gb).replace('        local result=if','        result=if');
 const cached=`        local baseKey=if paintIdentity and distributionMode!=3 and finalPass==undefined then this.paintBaseInputKey plants previewOnly else undefined
        local result=undefined
        if baseKey!=undefined and baseKey==paintBaseKey and paintBaseRows!=undefined then (
            result=paintBaseRows;paintBaseHits+=1
        ) else (
${base}
            if baseKey!=undefined do (paintBaseRows=result;paintBaseKey=baseKey;paintBaseBuilds+=1)
        )
        result=this.applyPaint result
`;
 s=s.slice(0,ga)+cached+s.slice(gb);
 replace('            local obj=createInstance AminScatterObject','            local obj=createInstance AminScatterObject\n            obj.editLayerKey=nextEditLayerKey;nextEditLayerKey+=1');
 replace('    fn newLayer = (','    fn newLayer = (\n        this.syncLayerIdentity()');
 replace('    fn removeLayer = (','    fn removeLayer = (\n        if CyrusBrushSessionLayer!=undefined do CyrusStopBrush()');
 replace('            for layer in layerObjects where layer.layerID=="" do layer.layerID=CyrusNewLayerID()',`            for i=1 to layerObjects.count do (
                local layer=layerObjects[i]
                if layer.layerID=="" or layer.layerID=="dotNetObject:System.Guid" do layer.layerID=CyrusNewLayerID()
                if layer.editLayerKey==0 do layer.editLayerKey=i
                nextEditLayerKey=amax nextEditLayerKey (layer.editLayerKey+1)
            )`);
 replace('AminScatterLayerFields=#(','AminScatterLayerFields=#(#paintDocument,#paintEnabled,#paintIdentity,#paintDensity,');
 replace('setProperty destination key (getProperty origin key)','setProperty destination key (if key==#paintDocument and origin.paintDocument!=undefined then copy origin.paintDocument else getProperty origin key)');
 replace('local index=findItem root.layerObjects layer','local index=if layer.editLayerKey>0 then layer.editLayerKey else findItem root.layerObjects layer');
 replace('local signature=cyrusEditFingerprint rows ((layer.randomSeed as string)+"|"+(layer.diversitySeed as string)+"|"+(index as string))','local signature=if layer.paintIdentity then layer.paintPopulation else cyrusEditFingerprint rows ((layer.randomSeed as string)+"|"+(layer.diversitySeed as string)+"|"+(index as string))');
 replace('cyrusEditStack active rows index signature','if layer.paintIdentity then cyrusEditStack active rows index signature true else cyrusEditStack active rows index signature');
 replace('for i=1 to root.layerEnabled.count where root.layerEnabled[i] collect i','for i=1 to root.layerEnabled.count where root.layerEnabled[i] collect (if root.layerObjects[i].editLayerKey>0 then root.layerObjects[i].editLayerKey else i)');
 replace('        local key=stream as string','        local key=(stream as string)+"|Brush:"+this.paintKey()+":"+(paintEnabled as string)+":"+(paintDensity as string)');
 // The trace wrapper is declared later. Qualify recursion so MAXScript does
 // not capture an undefined local named placements inside cspImpl_placements.
 replace('result=placements plants previewOnly:previewOnly finalPass:', 'result=this.placements plants previewOnly:previewOnly finalPass:');
 replace('   format "Enabled:%|" r.cyrusEnabled to:s','   format "Enabled:%|" r.cyrusEnabled to:s\n   for layer in r.layerObjects do format "Brush:%:%:%|" layer.paintEnabled layer.paintDensity (layer.paintKey()) to:s');
 s+=fs.readFileSync('tools/ui/templates/brush-session.ms','utf8');
 return s;
};
