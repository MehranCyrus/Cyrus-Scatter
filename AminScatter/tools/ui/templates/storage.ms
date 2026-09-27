    fn ensureLayers = layerObjects.count
    fn syncLayerSurface obj = (
        local targets=validSurfaces()
        local equal=obj.surfaceNodes.count==targets.count
        if equal do for i=1 to targets.count where obj.surfaceNodes[i]!=targets[i] do equal=false
        if not equal do undo off (obj.surfaceNodes=targets;obj.surface=undefined)
        local enabledCount=(for flag in layerEnabled where flag collect flag).count
        local layerBudget=amax 1 (floor(previewBudget/(amax 1 enabledCount)))
        if obj.previewBudget!=layerBudget do undo off obj.previewBudget=layerBudget
        -- These settings belong to the controller, not an individual layer.
        undo off for key in #(#updateMode,#showPoints,#pointsPerPlant,#pointColorMode,#solidPointColor,#autoRender) do (
            if getProperty obj key != getProperty this key do setProperty obj key (getProperty this key)
        )
    )
    fn layerEntries includeDisabled:false = (
        local entries=#()
        for i=1 to layerObjects.count where includeDisabled or layerEnabled[i] do (
            local obj=layerObjects[i]
            syncLayerSurface obj
            append entries #(i,obj)
        )
        entries
    )
    fn migrateLayers = (
        if layerObjects.count==0 then (
            if sources.count>0 or (validSurfaces()).count>0 do (
                layerObjects=#(createInstance AminScatterObject)
                layerNames=#("Layer_01");layerEnabled=#(true);activeLayer=1
                AminScatterCopyLayer this layerObjects[1]
            )
        ) else if activeLayer>0 and activeLayer<=layerObjects.count do AminScatterCopyLayer this layerObjects[activeLayer]
    )
    fn selectLayer i = (
        if i<1 or i>layerObjects.count do throw "Invalid scatter layer."
        activeLayer=i
    )
    fn newLayer = (
        if layerObjects.count>=10 do throw "A scatter controller supports up to 10 layers."
        undo "Cyrus Scatter add layer" on (
            local obj=createInstance AminScatterObject
            obj.randomSeed=42+layerObjects.count*101
            append layerObjects obj
            local number=1;local label=""
            do (label="Layer_"+(formattedPrint number format:"02d");number+=1) while findItem layerNames label>0
            append layerNames label;append layerEnabled true
            activeLayer=layerObjects.count
            syncLayerSurface obj
        )
        activeLayer
    )
    fn removeLayer = (
        if layerObjects.count>0 and activeLayer>0 do (
            if (for n in layerObjects[activeLayer].bakedNodes where isValidNode n collect n).count>0 do throw "Remove this layer's baked output first."
            undo "Cyrus Scatter remove layer" on (
                local i=activeLayer
                deleteItem layerObjects i;deleteItem layerNames i;deleteItem layerEnabled i
                activeLayer=amin i layerObjects.count
            )
        )
        activeLayer
    )
    fn refreshAll = (
        for entry in (layerEntries()) do entry[2].refreshPreview()
        redrawViews()
    )
    fn allStatus = (
        local plants=0;local points=0
        for entry in (layerEntries()) do (
            local state=entry[2].cacheSnapshot()
            plants+=state[5];points+=state[2]
        )
        (layerObjects.count as string)+" layers; "+(plants as string)+" plants; "+(points as string)+" points"
    )
    fn clearAllBaked = (
        local owners=refs.dependentNodes this
        if owners.count==1 do for entry in (layerEntries includeDisabled:true) do entry[2].clearBaked owners[1]
        autoRender=true;showPoints=true;redrawViews()
    )

