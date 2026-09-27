/* Scene object UI for the native AminScatter C++ engine. */
global AminScatterObject
global AminScatterObjectDraw
global CyrusAnalyzerFilter
fn CyrusAnalyzerFilter n = (isValidNode n and isProperty n #boundaryVertices and isProperty n #pathVertices and isProperty n #samplePoints)
global AminScatterAreaFilter
fn AminScatterAreaFilter n = (try(isValidNode n and aminScatterValidArea n)catch(false))
global AminScatterSourceFilter
fn AminScatterSourceFilter n = (
    isValidNode n and classof n.baseObject!=AminScatterObject and canConvertTo n Editable_Mesh
)
try(unRegisterRedrawViewsCallback AminScatterObjectDraw)catch()

global AminScatterLayerFields, AminScatterLayerTabs
global AminScatterCopyLayer, AminScatterRefreshLayerPanels
AminScatterLayerFields=#(#sources,#bakedNodes,#amount,#randomSeed,#scaleMinimum,#scaleMaximum,#tiltDegrees,#yawMinimum,#yawMaximum,#movementRange,#alignNormal,#showPoints,#pointsPerPlant,#updateMode,#populationMode,#plantsPerM2,#advancedAxes,#projectMove,#rotXMin,#rotXMax,#rotYMin,#rotYMax,#rotZMin,#rotZMax,#sclXMin,#sclXMax,#sclYMin,#sclYMax,#sclZMin,#sclZMax,#movXMin,#movXMax,#movYMin,#movYMax,#movZMin,#movZMax,#distributionMode,#clusterCount,#clusterRadius,#densityMap,#invertDensity,#diversityMode,#diversitySize,#diversitySeed,#roughness,#blurryEdge,#diversityNoise,#autoRender,#previewBudget,#pointColorMode,#solidPointColor,#areaNodes,#areaModes,#sourceColors,#patternLines,#patternWidths,#patternGroups,#patternRestGroup)
AminScatterLayerTabs=#(#sources,#bakedNodes,#areaNodes,#areaModes,#sourceColors,#patternLines,#patternWidths,#patternGroups)
fn AminScatterCopyLayer origin destination = (
    destination.setLayerTransfer true
    try (
        for key in AminScatterLayerFields do (
            if findItem AminScatterLayerTabs key>0 then (
                setProperty destination key ((getProperty origin key) as array)
            ) else (
                local ctrl=try(getPropertyController origin key)catch(undefined)
                if ctrl!=undefined then setPropertyController destination key (copy ctrl)
                else (
                    local previous=try(getPropertyController destination key)catch(undefined)
                    if previous!=undefined do setPropertyController destination key undefined
                    setProperty destination key (getProperty origin key)
                )
            )
        )
        destination.setLayerTransfer false
    ) catch(destination.setLayerTransfer false;throw())
)
-- Rollout definitions exist before their native controls. Never access a control
-- until its rollout has received open; close clears readiness before destruction.
fn AminScatterRefreshLayerPanels obj reopen:true = (
    local prefix=obj.layerNames[obj.activeLayer]+" | "
    local pairs=#(#(obj.updateUI,"Update"),#(obj.sourceUI,"Source Object Scatter"),#(obj.distributionUI,"Point generation"),#(obj.areaUI,"Area"),#(obj.diversityUI,"Diversity"),#(obj.lineUI,"Line pattern"),#(obj.randomUI,"Randomize XYZ"),#(obj.previewUI,"Viewport / output"))
    if obj.layersUI.controlsReady do (
        obj.layersUI.layerList.items=for i=1 to obj.layerNames.count collect ((if obj.layerEnabled[i] then "On | " else "Off | ")+obj.layerNames[i])
        obj.layersUI.layerList.selection=obj.activeLayer
        obj.layersUI.nameEdit.text=obj.layerNames[obj.activeLayer]
        obj.layersUI.enabledCheck.checked=obj.layerEnabled[obj.activeLayer]
        obj.layersUI.newButton.enabled=obj.layerObjects.count<10
        obj.layersUI.removeButton.enabled=obj.layerObjects.count>1
    )
    if obj.surfaceUI.controlsReady do obj.surfaceUI.newLayerButton.enabled=obj.layerObjects.count<10
    if obj.layerFooterUI.controlsReady do obj.layerFooterUI.newLayerBottom.enabled=obj.layerObjects.count<10
    if obj.sourceUI.controlsReady do obj.sourceUI.plantList.selection=#{}
    if obj.areaUI.controlsReady do obj.areaUI.areaList.selection=#{}
    if obj.lineUI.controlsReady do obj.lineUI.lineList.selection=#{}
    for pair in pairs where pair[1].controlsReady do (
        local r=pair[1];local opened=r.open
        r.title=prefix+pair[2]
        if opened and reopen do (r.open=false;r.open=true)
    )
    if obj.previewUI.controlsReady do obj.previewUI.status.text=obj.statusText()
)
plugin simpleObject AminScatterObject
name:"Amin Scatter"
classID:#(0x617d43a1,0x395c2e17)
category:"Amin"
version:12
(
    local layerTransfer=false
    local cachedPoints=undefined
    local cachedAnalyzerRun=-1
    local cachedPointCount=0
    local dirty=true
    local previewError=""
    local generatedCount=0
    local previewBuildCount=0
    local previewBuildMs=0
    local requestedCount=0
    local densityCapped=false
    parameters settings (
        surface type:#node useNodeTmValidity:true useNodeOsValidity:true
        sources type:#nodeTab tabSize:0 tabSizeVariable:true useNodeTmValidity:true useNodeOsValidity:true
        bakedNodes type:#nodeTab tabSize:0 tabSizeVariable:true
        amount type:#integer default:200
        randomSeed type:#integer default:42
        scaleMinimum type:#float default:0.8
        scaleMaximum type:#float default:1.2
        tiltDegrees type:#float default:0
        yawMinimum type:#float default:0
        yawMaximum type:#float default:360
        movementRange type:#worldUnits default:0
        alignNormal type:#boolean default:true
        showPoints type:#boolean default:true
        pointsPerPlant type:#integer default:80
        iconSize type:#worldUnits default:10
        on surface set v do dirty=true
        on sources set v i do dirty=true
        on amount set v do dirty=true
        on randomSeed set v do dirty=true
        on scaleMinimum set v do dirty=true
        on scaleMaximum set v do dirty=true
        on tiltDegrees set v do dirty=true
        on yawMinimum set v do dirty=true
        on yawMaximum set v do dirty=true
        on movementRange set v do dirty=true
        on alignNormal set v do dirty=true
        on pointsPerPlant set v do dirty=true
    )
    parameters surfaceSettings rollout:surfaceUI (
        surfaceNodes type:#nodeTab tabSize:0 tabSizeVariable:true useNodeTmValidity:true useNodeOsValidity:true
        on surfaceNodes set v i do dirty=true
    )
    parameters updateSettings rollout:updateUI (
        updateMode type:#integer default:2 ui:updateRadio
        on updateMode set v do (dirty=true;if not layerTransfer do redrawViews())
    )
    parameters populationSettings rollout:distributionUI (
        populationMode type:#integer default:1 ui:populationRadio
        plantsPerM2 type:#float default:100 ui:densitySpin
        on populationMode set v do dirty=true
        on plantsPerM2 set v do dirty=true
    )
    fn validSurfaces = (
        local result=#()
        local nodes=if surfaceNodes.count>0 then (surfaceNodes as array) else #(surface)
        for n in nodes where isValidNode n and classof n.baseObject!=AminScatterObject and findItem result n==0 do append result n
        result
    )
    parameters randomization rollout:randomUI (
        advancedAxes type:#boolean default:true
        projectMove type:#boolean default:true ui:projectCheck
        rotXMin type:#float default:0 ui:rotXMinSpin
        rotXMax type:#float default:0 ui:rotXMaxSpin
        rotYMin type:#float default:0 ui:rotYMinSpin
        rotYMax type:#float default:0 ui:rotYMaxSpin
        rotZMin type:#float default:0 ui:rotZMinSpin
        rotZMax type:#float default:360 ui:rotZMaxSpin
        sclXMin type:#float default:1 ui:sclXMinSpin
        sclXMax type:#float default:1 ui:sclXMaxSpin
        sclYMin type:#float default:1 ui:sclYMinSpin
        sclYMax type:#float default:1 ui:sclYMaxSpin
        sclZMin type:#float default:1 ui:sclZMinSpin
        sclZMax type:#float default:1 ui:sclZMaxSpin
        movXMin type:#float default:0 ui:movXMinSpin
        movXMax type:#float default:0 ui:movXMaxSpin
        movYMin type:#float default:0 ui:movYMinSpin
        movYMax type:#float default:0 ui:movYMaxSpin
        movZMin type:#float default:0 ui:movZMinSpin
        movZMax type:#float default:0 ui:movZMaxSpin
        on projectMove set v do dirty=true
        on rotXMin set v do (if not layerTransfer and v>rotXMax do rotXMax=v;dirty=true)
        on rotXMax set v do (if not layerTransfer and v<rotXMin do rotXMin=v;dirty=true)
        on rotYMin set v do (if not layerTransfer and v>rotYMax do rotYMax=v;dirty=true)
        on rotYMax set v do (if not layerTransfer and v<rotYMin do rotYMin=v;dirty=true)
        on rotZMin set v do (if not layerTransfer and v>rotZMax do rotZMax=v;dirty=true)
        on rotZMax set v do (if not layerTransfer and v<rotZMin do rotZMin=v;dirty=true)
        on sclXMin set v do (if not layerTransfer and v>sclXMax do sclXMax=v;dirty=true)
        on sclXMax set v do (if not layerTransfer and v<sclXMin do sclXMin=v;dirty=true)
        on sclYMin set v do (if not layerTransfer and v>sclYMax do sclYMax=v;dirty=true)
        on sclYMax set v do (if not layerTransfer and v<sclYMin do sclYMin=v;dirty=true)
        on sclZMin set v do (if not layerTransfer and v>sclZMax do sclZMax=v;dirty=true)
        on sclZMax set v do (if not layerTransfer and v<sclZMin do sclZMin=v;dirty=true)
        on movXMin set v do (if not layerTransfer and v>movXMax do movXMax=v;dirty=true)
        on movXMax set v do (if not layerTransfer and v<movXMin do movXMin=v;dirty=true)
        on movYMin set v do (if not layerTransfer and v>movYMax do movYMax=v;dirty=true)
        on movYMax set v do (if not layerTransfer and v<movYMin do movYMin=v;dirty=true)
        on movZMin set v do (if not layerTransfer and v>movZMax do movZMax=v;dirty=true)
        on movZMax set v do (if not layerTransfer and v<movZMin do movZMin=v;dirty=true)
    )
    parameters distributionSettings rollout:distributionUI (
        distributionMode type:#integer default:1
        clusterCount type:#integer default:12
        clusterRadius type:#worldUnits default:10
        densityMap type:#textureMap ui:densityButton
        invertDensity type:#boolean default:false ui:invertCheck
        on distributionMode set v do dirty=true
        on clusterCount set v do dirty=true
        on clusterRadius set v do dirty=true
        on densityMap set v do dirty=true
        on invertDensity set v do dirty=true
    )
    parameters diversitySettings rollout:diversityUI (
        diversityMode type:#integer default:1 ui:diversityRadio
        diversitySize type:#worldUnits default:10 ui:sizeSpin
        diversitySeed type:#integer default:42 ui:divSeedSpin
        roughness type:#float default:0 ui:roughSpin
        blurryEdge type:#float default:0 ui:blurSpin
        diversityNoise type:#float default:0 ui:noiseSpin
        on diversityMode set v do dirty=true
        on diversitySize set v do dirty=true
        on diversitySeed set v do dirty=true
        on roughness set v do dirty=true
        on blurryEdge set v do dirty=true
        on diversityNoise set v do dirty=true
    )
    parameters displaySettings rollout:previewUI (
        autoRender type:#boolean default:true ui:autoRenderCheck
        previewBudget type:#integer default:20000 ui:budgetSpin
        on previewBudget set v do dirty=true
        pointColorMode type:#integer default:2 ui:pointColorRadio
        solidPointColor type:#color default:(color 100 220 120) ui:solidColorPicker
        on pointColorMode set v do if not layerTransfer do redrawViews()
        on solidPointColor set v do if not layerTransfer do redrawViews()
    )
    fn displayPointColor groupColor = (if pointColorMode==1 then solidPointColor else groupColor)
    parameters areaSettings rollout:areaUI (
        areaNodes type:#nodeTab tabSize:0 tabSizeVariable:true useNodeTmValidity:true useNodeOsValidity:true
        areaModes type:#intTab tabSize:0 tabSizeVariable:true
        on areaNodes set v i do dirty=true
        on areaModes set v i do dirty=true
    )
    fn areaInputs = (
        local nodes=#();local modes=#()
        for i=1 to areaNodes.count where isValidNode areaNodes[i] do (
            append nodes areaNodes[i]
            append modes (if i<=areaModes.count then areaModes[i] else 1)
        )
        #(nodes,modes)
    )
    parameters colorGroups (
        sourceColors type:#colorTab tabSize:0 tabSizeVariable:true
        on sourceColors set v i do dirty=true
    )
    parameters lineSettings rollout:lineUI (
        patternLines type:#nodeTab tabSize:0 tabSizeVariable:true useNodeTmValidity:true useNodeOsValidity:true
        patternWidths type:#worldUnitsTab tabSize:0 tabSizeVariable:true
        patternGroups type:#intTab tabSize:0 tabSizeVariable:true
        patternRestGroup type:#integer default:-1
        on patternLines set v i do dirty=true
        on patternWidths set v i do dirty=true
        on patternGroups set v i do dirty=true
        on patternRestGroup set v do dirty=true
    )
    fn assignLineGroup rows key = (
        undo "Amin Scatter band group" on (for i in rows where i>0 and i<=patternGroups.count do patternGroups[i]=key)
        dirty=true
    )
    fn assignRestGroup key = (patternRestGroup=key;dirty=true)
    fn externalChanged changedNodes = (
        if updateMode!=2 then false else (
            local affected=false
            local inputs=validSurfaces()
            join inputs (sources as array)
            join inputs (areaNodes as array)
            join inputs (patternLines as array)
            for input in inputs where isValidNode input do (
                local dep=input
                while isValidNode dep and not affected do (
                    if findItem changedNodes dep>0 do affected=true
                    dep=dep.parent
                )
            )
            if affected do dirty=true
            affected
        )
    )
    fn invalidateLive = (if updateMode==2 do dirty=true)
    fn canonicalColor c = (color (floor(c.r+0.5)) (floor(c.g+0.5)) (floor(c.b+0.5)))
    fn colorKey c = (
        local rgb=canonicalColor c
        (rgb.r as integer)*65536+(rgb.g as integer)*256+(rgb.b as integer)
    )
    fn sourceColor i = (
        local palette=#((color 100 220 120),(color 240 190 70),(color 90 175 255),(color 230 110 170))
        if i>0 and i<=sourceColors.count then canonicalColor sourceColors[i] else palette[(mod (amax 0 (i-1)) palette.count)+1]
    )
    fn syncColors = (
        while sourceColors.count<sources.count do append sourceColors (sourceColor (sourceColors.count+1))
    )
    fn assignGroup indices c = (
        syncColors()
        undo "Amin Scatter color group" on (
            for i in indices where i>0 and i<=sources.count do sourceColors[i]=canonicalColor c
        )
        dirty=true
    )
    fn usableSource n = (
        isValidNode n and findItem (validSurfaces()) n==0 and classof n.baseObject!=AminScatterObject
    )
    fn validSources = (for n in sources where usableSource n collect n)
    fn lineInputs plants = (
        if diversityMode!=3 then #(false,0,#()) else (
            local keys=for n in plants collect (colorKey (sourceColor (findItem sources n)))
            local rest=if patternRestGroup<0 then keys[1] else patternRestGroup
            if findItem keys rest==0 do throw "Line pattern: choose an existing source color for Rest group."
            local bands=#()
            for i=1 to patternLines.count where isValidNode patternLines[i] do (
                if i>patternWidths.count or i>patternGroups.count do throw "Line pattern settings are incomplete."
                if findItem keys patternGroups[i]==0 do throw "Line pattern: reselect Band group from existing source colors."
                append bands #(patternLines[i],patternWidths[i],patternGroups[i])
            )
            #(true,rest,bands)
        )
    )
    fn placements plants = (
        local targets=validSurfaces()
        if targets.count==0 do throw "Add at least one scatter surface."
        if plants.count==0 do throw "Add a plant mesh."
        requestedCount=amount;densityCapped=false
        if populationMode==2 do (
            local meters=units.decodeValue "1m"
            local areaM2=(aminScatterSurfaceArea targets)/(meters*meters)
            local wanted=areaM2*plantsPerM2
            densityCapped=wanted>100000
            requestedCount=(amin 100000 (floor(wanted+0.5))) as integer
        )
        local image=undefined
        local weights=#()
        if distributionMode==3 do (
            if densityMap==undefined do throw "Choose a density texture map."
            try (
                image=renderMap densityMap size:[128,128]
                for y=0 to 127 do (
                    local pixels=getPixels image [0,y] 128
                    for c in pixels do (
                        local w=amin 1.0 (amax 0.0 ((c.r*0.2126+c.g*0.7152+c.b*0.0722)/255.0))
                        append weights (if invertDensity then 1-w else w)
                    )
                )
                close image
            ) catch (if image!=undefined do close image; throw())
        )
        local areas=areaInputs()
        if not advancedAxes and areas[1].count==0 and targets.count==1 and populationMode==1 and diversityMode<3 then (
            aminScatterTransforms targets[1] requestedCount randomSeed plants.count scaleMinimum scaleMaximum [-tiltDegrees,-tiltDegrees,yawMinimum] [tiltDegrees,tiltDegrees,yawMaximum] [movementRange,movementRange,movementRange] alignNormal
        ) else (
            local groups=for n in plants collect (colorKey (sourceColor (findItem sources n)))
            aminScatterAdvanced targets requestedCount randomSeed plants.count [sclXMin,sclYMin,sclZMin] [sclXMax,sclYMax,sclZMax] [rotXMin,rotYMin,rotZMin] [rotXMax,rotYMax,rotZMax] [movXMin,movYMin,movZMin] [movXMax,movYMax,movZMax] alignNormal projectMove (distributionMode-1) clusterCount clusterRadius weights 128 groups (diversityMode==2) diversitySize diversitySeed (roughness/100.0) (blurryEdge/100.0) (diversityNoise/100.0) areas[1] areas[2] (populationMode==2) (lineInputs plants)
        )
    )
    fn refreshPreview = (
        local buildStarted=timeStamp()
        previewBuildCount+=1
        cachedPoints=undefined;cachedPointCount=0;previewError="";generatedCount=0
        try (
            local plants=validSources()
            local data=placements plants
            generatedCount=data.count
            local samples=for n in plants collect (aminScatterSourcePoints n pointsPerPlant randomSeed)
            local colors=for n in plants collect (sourceColor (findItem sources n))
            cachedPoints=aminScatterBuildPreview data samples colors previewBudget
            cachedPointCount=aminScatterPreviewCount cachedPoints
        ) catch (previewError=getCurrentException();cachedPoints=undefined;cachedPointCount=0)
        dirty=false
        cachedAnalyzerRun=if diversityMode==4 and isValidNode analyzerNode then analyzerNode.getAnalysisRuns() else -1
        previewBuildMs=timeStamp()-buildStarted
        cachedPointCount
    )
    fn previewCache = (
        if updateMode==2 and diversityMode==4 do (
            local revision=if isValidNode analyzerNode then analyzerNode.getAnalysisRuns() else -1
            if revision!=cachedAnalyzerRun do dirty=true
        )
        if dirty and (updateMode==2 or previewBuildCount==0) do refreshPreview()
        cachedPoints
    )
    fn previewPoints = (
        local cache=previewCache()
        if cache==undefined then #() else aminScatterPreviewPoints cache
    )
    fn previewStats = (#(previewBuildCount,previewBuildMs,cachedPointCount))
    fn statusText = (
        if previewError!="" then previewError else (generatedCount as string)+" / "+(requestedCount as string)+" plants; "+(cachedPointCount as string)+" points"+(if densityCapped then " (density capped at 100000)" else "")
    )
    parameters layerSettings rollout:layersUI (
        layerObjects type:#maxObjectTab tabSize:0 tabSizeVariable:true
        layerNames type:#stringTab tabSize:0 tabSizeVariable:true
        layerEnabled type:#boolTab tabSize:0 tabSizeVariable:true
        activeLayer type:#integer default:1
    )
    fn setLayerTransfer state = (layerTransfer=state)
    fn cacheSnapshot = (#(cachedPoints,cachedPointCount,dirty,previewError,generatedCount,previewBuildCount,previewBuildMs,requestedCount,densityCapped))
    fn restoreCache state = (
        cachedPoints=state[1];cachedPointCount=state[2];dirty=state[3];previewError=state[4]
        generatedCount=state[5];previewBuildCount=state[6];previewBuildMs=state[7]
        requestedCount=state[8];densityCapped=state[9]
    )
    fn forcePreviewUpdate = (dirty=true;previewBuildCount=0)
    fn ensureLayers = (
        if layerObjects.count==0 do (
            local wasDirty=getSaveRequired()
            undo off (
                layerObjects=#(createInstance AminScatterObject)
                layerNames=#("Layer 01");layerEnabled=#(true);activeLayer=1
            )
            if not wasDirty do setSaveRequired false
        )
        layerObjects.count
    )
    fn syncLayerSurface obj = (
        local targets=validSurfaces()
        local equal=obj.surfaceNodes.count==targets.count
        if equal do for i=1 to targets.count where obj.surfaceNodes[i]!=targets[i] do equal=false
        if not equal do undo off (obj.surfaceNodes=targets;obj.surface=undefined)
    )
    fn layerEntries includeDisabled:false = (
        ensureLayers()
        local entries=#()
        for i=1 to layerObjects.count where includeDisabled or layerEnabled[i] do (
            local obj=if i==activeLayer then this else layerObjects[i]
            if i!=activeLayer do syncLayerSurface obj
            append entries #(i,obj)
        )
        entries
    )
    fn storeActiveLayer = (
        local state=cacheSnapshot()
        AminScatterCopyLayer this layerObjects[activeLayer]
        syncLayerSurface layerObjects[activeLayer]
        layerObjects[activeLayer].restoreCache state
    )
    fn loadLayer i = (
        local obj=layerObjects[i]
        syncLayerSurface obj
        local state=obj.cacheSnapshot()
        activeLayer=i
        AminScatterCopyLayer obj this
        restoreCache state
    )
    fn selectLayer i = (
        ensureLayers()
        if i<1 or i>layerObjects.count do throw "Invalid scatter layer."
        if i!=activeLayer do (
            local wasDirty=getSaveRequired()
            undo off (storeActiveLayer();loadLayer i)
            if not wasDirty do setSaveRequired false
        )
        i
    )
    fn newLayer = (
        ensureLayers()
        if layerObjects.count>=10 do throw "A scatter controller supports up to 10 layers."
        undo "Amin Scatter new layer" on (
            storeActiveLayer()
            local obj=createInstance AminScatterObject
            obj.randomSeed=42+layerObjects.count*101
            append layerObjects obj
            local number=1;local label=""
            do (label="Layer "+(formattedPrint number format:"02d");number+=1) while findItem layerNames label>0
            append layerNames label;append layerEnabled true
            loadLayer layerObjects.count
        )
        activeLayer
    )
    fn removeLayer = (
        ensureLayers()
        if layerObjects.count<=1 do throw "Keep at least one layer."
        if (for n in bakedNodes where isValidNode n collect n).count>0 do throw "Remove this layer's baked output before removing the layer."
        undo "Amin Scatter remove layer" on (
            local i=activeLayer
            deleteItem layerObjects i;deleteItem layerNames i;deleteItem layerEnabled i
            loadLayer (amin i layerObjects.count)
        )
        activeLayer
    )
    fn clearBaked ownerNode = (
        local key=ownerNode.handle as string
        undo "Amin Scatter remove baked output" on (
            for n in bakedNodes where isValidNode n do (
                if (getUserProp n "AminScatterOwner" as string)==key do delete n
            )
            bakedNodes=#()
        )
    )
    fn bakeInstances ownerNode = (
        local plants=validSources()
        local data=placements plants
        local fresh=#()
        local ownerKey=ownerNode.handle as string
        undo "Amin Scatter build" on (
            try (
                with redraw off (
                    for row in data do (
                        local n=instance plants[row[2]]
                        append fresh n
                        n.parent=undefined
                        n.name=uniqueName (ownerNode.name+"_Plant_")
                        n.transform=row[1]
                        n.renderable=true;n.isHidden=false
                        setUserProp n "AminScatterOwner" ownerKey
                    )
                    for n in bakedNodes where isValidNode n do (
                        if (getUserProp n "AminScatterOwner" as string)==ownerKey do delete n
                    )
                    bakedNodes=fresh
                    showPoints=false;autoRender=false
                )
            ) catch (
                for n in fresh where isValidNode n do delete n
                throw()
            )
        )
        fresh.count
    )
    rollout surfaceUI "01 - Scatter Surface (shared)" width:#cmdPanel (
        local controlsReady=false
        on surfaceUI close do controlsReady=false
        multiListBox surfaceList "Surfaces (Ctrl/Shift)" items:#() pos:[8,8] width:146 height:6
        button addSurfaceScene "Select From Scene..." pos:[8,134] width:146
        pickbutton pickSurface "Add: pick surface" filter:AminScatterSourceFilter pos:[8,160] width:146
        button removeSurface "Remove selected rows" pos:[8,186] width:146
        button newLayerButton "New Layer" pos:[8,220] width:146
        fn updateSurfaces = (
            local rows=surfaceList.selection
            surfaceList.items=for n in surfaceNodes collect (if isValidNode n then n.name else "<deleted>")
            surfaceList.selection=rows
        )
        fn addSurface n = (
            if AminScatterSourceFilter n and findItem sources n==0 and findItem surfaceNodes n==0 do (
                append surfaceNodes n;surface=undefined;dirty=true
            )
        )
        on surfaceUI open do (controlsReady=true;ensureLayers();updateSurfaces();newLayerButton.enabled=layerObjects.count<10)
        on newLayerButton pressed do (
            try(newLayer();AminScatterRefreshLayerPanels this;redrawViews())catch(messageBox (getCurrentException()) title:"Amin Scatter")
        )
        on pickSurface picked n do (addSurface n;updateSurfaces();redrawViews())
        on addSurfaceScene pressed do (
            local nodes=selectByName title:"Amin Scatter - Surfaces" buttonText:"Add" filter:AminScatterSourceFilter single:false
            if nodes!=undefined do for n in nodes do addSurface n
            updateSurfaces();redrawViews()
        )
        on removeSurface pressed do (
            local rows=surfaceList.selection as array
            undo "Amin Scatter remove surfaces" on (for i=rows.count to 1 by -1 do deleteItem surfaceNodes rows[i])
            surface=undefined;surfaceList.selection=#{};dirty=true;updateSurfaces();redrawViews()
        )
    )
    rollout layersUI "02 - Scatter Layers" width:#cmdPanel (
        local controlsReady=false
        on layersUI close do controlsReady=false
        listbox layerList "Layers (maximum 10)" items:#() pos:[8,8] width:146 height:7
        edittext nameEdit "Name:" pos:[8,156] width:146
        checkbox enabledCheck "Enable this layer" pos:[8,184] width:146
        button newButton "New Layer" pos:[8,214] width:146
        button removeButton "Remove layer" pos:[8,242] width:146
        label editorHint "Edit the selected layer below." pos:[8,272] width:146
        on layersUI open do (
            ensureLayers()
            layerList.items=for i=1 to layerNames.count collect ((if layerEnabled[i] then "On | " else "Off | ")+layerNames[i])
            layerList.selection=activeLayer;nameEdit.text=layerNames[activeLayer]
            enabledCheck.checked=layerEnabled[activeLayer]
            newButton.enabled=layerObjects.count<10;removeButton.enabled=layerObjects.count>1
            controlsReady=true
        )
        on layerList selected i do (
            if i>0 do (selectLayer i;AminScatterRefreshLayerPanels this;redrawViews())
        )
        on nameEdit entered value do (
            if value!="" do undo "Amin Scatter rename layer" on layerNames[activeLayer]=value
            AminScatterRefreshLayerPanels this
        )
        on enabledCheck changed value do (
            undo "Amin Scatter layer enabled" on layerEnabled[activeLayer]=value
            AminScatterRefreshLayerPanels this;redrawViews()
        )
        on newButton pressed do (
            try(newLayer();AminScatterRefreshLayerPanels this;redrawViews())catch(messageBox (getCurrentException()) title:"Amin Scatter")
        )
        on removeButton pressed do (
            try(removeLayer();AminScatterRefreshLayerPanels this;redrawViews())catch(messageBox (getCurrentException()) title:"Amin Scatter")
        )
    )
    rollout updateUI "Update mode" width:#cmdPanel (
        local controlsReady=false
        on updateUI close do controlsReady=false
        on updateUI open do (controlsReady=true;ensureLayers();updateUI.title=layerNames[activeLayer]+" | Update";)
        radiobuttons updateRadio "Viewport update" labels:#("Manual","Real-time") columns:1 pos:[8,8] width:146
        button updateNow "Update now" pos:[8,78] width:146
        label updateHint "Updates after a brief pause." pos:[8,110] width:146
        on updateNow pressed do (refreshPreview();redrawViews())
    )
    rollout sourceUI "02 - Source objects / color groups" width:#cmdPanel (
        local controlsReady=false
        on sourceUI close do controlsReady=false
        local groupPalette=#()
        local loadingColor=false
        local focusedRow=0
        multiListBox plantList "Sources (Ctrl/Shift)" items:#() pos:[8,8] height:6 width:146
        button selectFromScene "Select From Scene..." pos:[8,134] width:146
        pickbutton addPlant "Add: pick in viewport" pos:[8,160] width:146
        button addSelected "Add selected objects" pos:[8,186] width:146
        button removePlant "Remove selected rows" pos:[8,212] width:146
        button selectPlant "Select sources" pos:[8,238] width:146
        label groupHeading "Cluster color group" pos:[8,270] width:146
        dropdownlist existingGroups "Reuse a group" items:#() pos:[8,293] width:146
        colorpicker groupColor "Color: " color:(color 100 220 120) pos:[8,341] width:146 modal:true notifyAfterAccept:true
        button applyColor "Apply to selected rows" pos:[8,368] width:146
        label colorHelp "OK saves the selected color." pos:[8,398] width:146
        fn colorLabel c = ("#"+(formattedPrint (colorKey c) format:"06X"))
        fn updateList = (
            local selectedRows=plantList.selection
            if selectedRows.numberSet==0 and sources.count>0 do selectedRows=#{1}
            syncColors()
            plantList.items=for i=1 to sources.count collect ((colorLabel (sourceColor i))+" | "+(if isValidNode sources[i] then sources[i].name else "<deleted>"))
            plantList.selection=selectedRows
            groupPalette=#()
            local keys=#()
            for i=1 to sources.count do (
                local c=sourceColor i
                local k=colorKey c
                if findItem keys k==0 do (append keys k;append groupPalette c)
            )
            existingGroups.items=for c in groupPalette collect (colorLabel c)
        )
        fn addSource n = (
            if usableSource n and (findItem sources n)==0 do (
                syncColors();append sources n;append sourceColors groupColor.color;dirty=true
            )
        )
        fn addSources nodes = (
            if nodes!=undefined do for n in nodes do addSource n
            updateList();redrawViews()
        )
        fn showSelectedColor = (
            local rows=plantList.selection
            if rows.numberSet>0 then (
                if focusedRow<1 or not rows[focusedRow] do focusedRow=(rows as array)[1]
                loadingColor=true
                groupColor.color=sourceColor focusedRow
                existingGroups.selection=findItem groupPalette (sourceColor focusedRow)
                loadingColor=false
            ) else (
                loadingColor=true;groupColor.color=sourceColor 1;existingGroups.selection=0;focusedRow=0;loadingColor=false
            )
        )
        on sourceUI open do (controlsReady=true;ensureLayers();sourceUI.title=layerNames[activeLayer]+" | Source Object Scatter";(updateList();showSelectedColor()))
        on plantList selected i do (
            if i>0 and plantList.selection[i] do focusedRow=i
        )
        on plantList selectionEnd do showSelectedColor()
        on existingGroups selected i do (
            if i>0 and i<=groupPalette.count do (
                local c=groupPalette[i]
                loadingColor=true;groupColor.color=c;loadingColor=false
                assignGroup plantList.selection c;updateList();redrawViews()
            )
        )
        on groupColor changed c do (
            if not loadingColor and plantList.selection.numberSet>0 do (
                assignGroup plantList.selection c
                updateList();redrawViews()
            )
        )
        on applyColor pressed do (
            assignGroup plantList.selection groupColor.color
            updateList();redrawViews()
        )
        on selectFromScene pressed do (
            local picked=selectByName title:"Amin Scatter - Select From Scene" buttonText:"Add" filter:AminScatterSourceFilter single:false
            addSources picked
        )
        on addPlant picked n do addSources #(n)
        on addSelected pressed do addSources (selection as array)
        on removePlant pressed do (
            syncColors()
            local rows=plantList.selection as array
            undo "Amin Scatter remove sources" on (
                for k=rows.count to 1 by -1 do (
                    deleteItem sources rows[k];deleteItem sourceColors rows[k]
                )
            )
            plantList.selection=#{};dirty=true;updateList();redrawViews()
        )
        on selectPlant pressed do (
            local nodes=for i in plantList.selection where i<=sources.count and isValidNode sources[i] collect sources[i]
            if nodes.count>0 do select nodes
        )
    )
    rollout distributionUI "03 - Point generation" width:#cmdPanel (
        local controlsReady=false
        on distributionUI close do controlsReady=false
        radiobuttons modeRadio "Method" labels:#("Random","Texture Density") columns:1 pos:[8,8] width:146
        radiobuttons populationRadio "Population" labels:#("Count","Plants per m2") columns:1 pos:[8,78] width:146
        spinner countSpin "Count: " range:[1,100000,200] type:#integer fieldWidth:64 width:146 pos:[8,148]
        spinner densitySpin "Per m2: " range:[0,1000000,100] fieldWidth:64 width:146 pos:[8,174]
        spinner seedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:64 width:146 pos:[8,200]
        label densityHeading "Texture density" pos:[8,234] width:146
        mapbutton densityButton "Choose density map" pos:[8,258] width:146
        checkbox invertCheck "Invert density" pos:[8,286] width:146
        label uvHint "UV channel 1; 0..1" pos:[8,312] width:146
        label mapHint "White: dense / Black: empty" pos:[8,334] width:146
        on distributionUI open do (controlsReady=true;ensureLayers();distributionUI.title=layerNames[activeLayer]+" | Point generation";(countSpin.value=amount;seedSpin.value=randomSeed;modeRadio.state=if distributionMode==3 then 2 else 1))
        on modeRadio changed v do (distributionMode=if v==2 then 3 else 1;dirty=true;redrawViews())
        on countSpin changed v do (amount=v;dirty=true;redrawViews())
        on seedSpin changed v do (randomSeed=v;dirty=true;redrawViews())
    )
    rollout areaUI "04 - Area" width:#cmdPanel (
        local controlsReady=false
        on areaUI close do controlsReady=false
        multiListBox areaList "Closed lines / shapes" items:#() pos:[8,8] width:146 height:6
        button addAreaScene "Select From Scene..." pos:[8,134] width:146
        pickbutton pickArea "Add: pick closed line" filter:AminScatterAreaFilter pos:[8,160] width:146
        button removeArea "Remove selected rows" pos:[8,186] width:146
        radiobuttons areaMode "Selected area mode" labels:#("Include","Exclude") columns:1 pos:[8,220] width:146
        label areaHint "Exclude overrides Include." pos:[8,290] width:146
        label projectionHint "Top / world XY projection." pos:[8,312] width:146
        button refreshAreas "Refresh areas / preview" pos:[8,340] width:146
        fn updateAreas = (
            local selectedRows=areaList.selection
            areaList.items=for i=1 to areaNodes.count collect (
                (if i<=areaModes.count and areaModes[i]==2 then "Exclude | " else "Include | ")+
                (if isValidNode areaNodes[i] then areaNodes[i].name else "<deleted>")
            )
            areaList.selection=selectedRows
        )
        fn addArea n = (
            if AminScatterAreaFilter n and findItem areaNodes n==0 do (
                append areaNodes n;append areaModes 1;dirty=true
            )
        )
        on areaUI open do (controlsReady=true;ensureLayers();areaUI.title=layerNames[activeLayer]+" | Area";updateAreas())
        on pickArea picked n do (addArea n;updateAreas();redrawViews())
        on addAreaScene pressed do (
            local nodes=selectByName title:"Amin Scatter - Closed Areas" buttonText:"Add" filter:AminScatterAreaFilter single:false
            if nodes!=undefined do for n in nodes do addArea n
            updateAreas();redrawViews()
        )
        on areaList selectionEnd do (
            if areaList.selection.numberSet>0 do areaMode.state=areaModes[(areaList.selection as array)[1]]
        )
        on areaMode changed mode do (
            undo "Amin Scatter area mode" on (for i in areaList.selection do areaModes[i]=mode)
            dirty=true;updateAreas();redrawViews()
        )
        on removeArea pressed do (
            local rows=areaList.selection as array
            undo "Amin Scatter remove areas" on (
                for i=rows.count to 1 by -1 do (deleteItem areaNodes rows[i];deleteItem areaModes rows[i])
            )
            areaList.selection=#{};dirty=true;updateAreas();redrawViews()
        )
        on refreshAreas pressed do (dirty=true;refreshPreview();redrawViews())
    )
    rollout diversityUI "05 - Diversity / color groups" width:#cmdPanel (
        local controlsReady=false
        on diversityUI close do controlsReady=false
        radiobuttons diversityRadio "Source assignment" labels:#("Random","Clusters","Line Pattern","Analyze Surface") columns:1 pos:[8,8] width:146
        spinner sizeSpin "Size: " range:[0.01,100000,10] type:#worldUnits fieldWidth:64 width:146 pos:[8,104]
        spinner divSeedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:64 width:146 pos:[8,130]
        spinner roughSpin "Roughness %: " range:[0,100,0] fieldWidth:54 width:146 pos:[8,156]
        spinner blurSpin "Blur edge %: " range:[0,100,0] fieldWidth:54 width:146 pos:[8,182]
        spinner noiseSpin "Noise %: " range:[0,100,0] fieldWidth:54 width:146 pos:[8,208]
        label groupHint "Uses source group colors." pos:[8,238] width:146
        label fixedHint "Point positions stay fixed." pos:[8,260] width:146
        fn updateControls = (
            local active=diversityMode==2
            sizeSpin.enabled=active;divSeedSpin.enabled=active;roughSpin.enabled=active
            blurSpin.enabled=active;noiseSpin.enabled=active
        )
        on diversityUI open do (controlsReady=true;ensureLayers();diversityUI.title=layerNames[activeLayer]+" | Diversity";updateControls())
        on diversityRadio changed v do (updateControls();updatePattern();dirty=true;redrawViews())
    )
    rollout lineUI "06 - Line pattern" width:#cmdPanel (
        local controlsReady=false
        on lineUI close do controlsReady=false
        local keys=#(), colors=#(), syncing=false
        multiListBox lineList "Pattern lines" items:#() pos:[8,8] width:146 height:5
        button addLineScene "Select From Scene..." pos:[8,118] width:146
        pickbutton pickLine "Add: pick closed line" filter:AminScatterAreaFilter pos:[8,144] width:146
        button removeLine "Remove selected rows" pos:[8,170] width:146
        spinner widthSpin "Width: " range:[0.001,100000,1] type:#worldUnits fieldWidth:64 width:146 pos:[8,208]
        dropdownlist bandDrop "Band group" items:#() pos:[8,236] width:146
        colorpicker bandSwatch "" color:white enabled:false pos:[8,282] width:146
        dropdownlist restDrop "Rest of surface" items:#() pos:[8,312] width:146
        colorpicker restSwatch "" color:green enabled:false pos:[8,358] width:146
        button refreshGroups "Refresh source groups" pos:[8,388] width:146
        label lineHint "Outside only / Top XY." pos:[8,418] width:146
        label priorityHint "First matching line wins." pos:[8,440] width:146
        fn showSettings = (
            syncing=true
            local rows=lineList.selection as array
            widthSpin.enabled=rows.count>0;bandDrop.enabled=rows.count>0
            if rows.count>0 do (
                local i=rows[1]
                widthSpin.value=patternWidths[i]
                local k=findItem keys patternGroups[i]
                bandDrop.selection=k
                if k>0 do bandSwatch.color=colors[k]
            )
            local k=if patternRestGroup<0 and keys.count>0 then 1 else findItem keys patternRestGroup
            restDrop.selection=k
            if k>0 do restSwatch.color=colors[k]
            syncing=false
        )
        fn updatePattern = (
            syncing=true
            local selectedRows=lineList.selection
            if selectedRows.numberSet==0 and patternLines.count>0 do selectedRows=#{1}
            lineList.items=for i=1 to patternLines.count collect (if isValidNode patternLines[i] then patternLines[i].name else "<deleted>")
            lineList.selection=selectedRows
            keys=#();colors=#();local labels=#()
            for n in validSources() do (
                local c=sourceColor (findItem sources n);local key=colorKey c
                if findItem keys key==0 do (
                    append keys key;append colors c
                    append labels ("#"+(formattedPrint key format:"06X")+" | "+n.name)
                )
            )
            bandDrop.items=labels;restDrop.items=labels
            syncing=false;showSettings()
        )
        fn addLine n = (
            if AminScatterAreaFilter n and findItem patternLines n==0 do (
                local plants=validSources()
                local key=if plants.count>0 then colorKey(sourceColor(findItem sources plants[(amin 2 plants.count)])) else 0
                append patternLines n;append patternWidths (units.decodeValue "1m");append patternGroups key
                updatePattern();lineList.selection=#{patternLines.count};showSettings();dirty=true
            )
        )
        fn chooseBandGroup k = (
            if not syncing and k>0 and k<=keys.count do (
                assignLineGroup lineList.selection keys[k]
                bandSwatch.color=colors[k];dirty=true;redrawViews()
            )
        )
        fn chooseRestGroup k = (
            if not syncing and k>0 and k<=keys.count do (
                assignRestGroup keys[k];restSwatch.color=colors[k];dirty=true;redrawViews()
            )
        )
        on lineUI open do (controlsReady=true;ensureLayers();lineUI.title=layerNames[activeLayer]+" | Line pattern";updatePattern())
        on lineList selectionEnd do showSettings()
        on pickLine picked n do (addLine n;updatePattern();redrawViews())
        on addLineScene pressed do (
            local nodes=selectByName title:"Amin Scatter - Line Pattern" buttonText:"Add" filter:AminScatterAreaFilter single:false
            if nodes!=undefined do for n in nodes do addLine n
            updatePattern();redrawViews()
        )
        on removeLine pressed do (
            local rows=lineList.selection as array
            undo "Amin Scatter remove pattern lines" on (
                for i=rows.count to 1 by -1 do (deleteItem patternLines rows[i];deleteItem patternWidths rows[i];deleteItem patternGroups rows[i])
            )
            lineList.selection=#{};dirty=true;updatePattern();redrawViews()
        )
        on widthSpin changed v do if not syncing do (
            for i in lineList.selection do patternWidths[i]=v
            dirty=true;redrawViews()
        )
        on bandDrop selected k do chooseBandGroup k
        on restDrop selected k do chooseRestGroup k
        on refreshGroups pressed do updatePattern()
    )

    rollout randomUI "07 - Randomize XYZ" width:#cmdPanel (
        local controlsReady=false
        on randomUI close do controlsReady=false
        label rotTitle "Rotation (degrees)" pos:[8,8] width:146
        label rotMinTitle "Min" pos:[24,30] width:58
        label rotMaxTitle "Max" pos:[94,30] width:58
        label rotXLabel "X" pos:[8,52] width:12
        spinner rotXMinSpin "" range:[-360,360,0]  pos:[24,50] fieldWidth:46 width:58
        spinner rotXMaxSpin "" range:[-360,360,0]  pos:[94,50] fieldWidth:46 width:58
        label rotYLabel "Y" pos:[8,76] width:12
        spinner rotYMinSpin "" range:[-360,360,0]  pos:[24,74] fieldWidth:46 width:58
        spinner rotYMaxSpin "" range:[-360,360,0]  pos:[94,74] fieldWidth:46 width:58
        label rotZLabel "Z" pos:[8,100] width:12
        spinner rotZMinSpin "" range:[-360,360,0]  pos:[24,98] fieldWidth:46 width:58
        spinner rotZMaxSpin "" range:[-360,360,360]  pos:[94,98] fieldWidth:46 width:58
        label sclTitle "Scale (multiplier)" pos:[8,132] width:146
        label sclMinTitle "Min" pos:[24,154] width:58
        label sclMaxTitle "Max" pos:[94,154] width:58
        label sclXLabel "X" pos:[8,176] width:12
        spinner sclXMinSpin "" range:[0.001,100,1]  pos:[24,174] fieldWidth:46 width:58
        spinner sclXMaxSpin "" range:[0.001,100,1]  pos:[94,174] fieldWidth:46 width:58
        label sclYLabel "Y" pos:[8,200] width:12
        spinner sclYMinSpin "" range:[0.001,100,1]  pos:[24,198] fieldWidth:46 width:58
        spinner sclYMaxSpin "" range:[0.001,100,1]  pos:[94,198] fieldWidth:46 width:58
        label sclZLabel "Z" pos:[8,224] width:12
        spinner sclZMinSpin "" range:[0.001,100,1]  pos:[24,222] fieldWidth:46 width:58
        spinner sclZMaxSpin "" range:[0.001,100,1]  pos:[94,222] fieldWidth:46 width:58
        label movTitle "Movement (world units)" pos:[8,256] width:146
        label movMinTitle "Min" pos:[24,278] width:58
        label movMaxTitle "Max" pos:[94,278] width:58
        label movXLabel "X" pos:[8,300] width:12
        spinner movXMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[24,298] fieldWidth:46 width:58
        spinner movXMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[94,298] fieldWidth:46 width:58
        label movYLabel "Y" pos:[8,324] width:12
        spinner movYMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[24,322] fieldWidth:46 width:58
        spinner movYMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[94,322] fieldWidth:46 width:58
        label movZLabel "Z" pos:[8,348] width:12
        spinner movZMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[24,346] fieldWidth:46 width:58
        spinner movZMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[94,346] fieldWidth:46 width:58
        checkbox projectCheck "Keep on surface" pos:[8,380] width:146
        checkbox alignCheck "Align to normal" pos:[8,404] width:146
        on randomUI open do (controlsReady=true;ensureLayers();randomUI.title=layerNames[activeLayer]+" | Randomize XYZ";alignCheck.checked=alignNormal)
        on alignCheck changed v do (alignNormal=v;dirty=true;redrawViews())
    )
    rollout previewUI "08 - Viewport and output" width:#cmdPanel (
        local controlsReady=false
        on previewUI close do controlsReady=false
        checkbox previewCheck "Point Cloud" pos:[8,8] width:146
        radiobuttons pointColorRadio "Point Cloud color" labels:#("Solid Color","Source Group Colors") columns:1 pos:[8,34] width:146
        colorpicker solidColorPicker "Solid: " color:(color 100 220 120) pos:[8,104] width:146
        spinner budgetSpin "Point limit: " range:[1000,500000,20000] type:#integer fieldWidth:58 width:146 pos:[8,132]
        spinner pointsSpin "Points/plant: " range:[10,10000,80] type:#integer fieldWidth:58 width:146 pos:[8,158]
        spinner iconSpin "Icon size: " range:[0.1,10000,10] type:#worldUnits fieldWidth:58 width:146 pos:[8,184]
        button refreshButton "Refresh Point Cloud" pos:[8,214] width:146
        checkbox autoRenderCheck "Automatic final render" pos:[8,244] width:146
        button clearBakedButton "Remove old baked output" pos:[8,274] width:146
        button buildButton "Bake editable instances" pos:[8,302] width:146
        label status "Ready" pos:[8,334] width:146 height:60
        on previewUI open do (controlsReady=true;ensureLayers();previewUI.title=layerNames[activeLayer]+" | Viewport / output";(previewCheck.checked=showPoints;pointsSpin.value=pointsPerPlant;iconSpin.value=iconSize))
        on previewCheck changed v do (showPoints=v;redrawViews())
        on pointsSpin changed v do (pointsPerPlant=v;dirty=true;redrawViews())
        on iconSpin changed v do iconSize=v
        on refreshButton pressed do (refreshPreview();status.text=statusText();redrawViews())
        on clearBakedButton pressed do (
            local owners=refs.dependentNodes this
            if owners.count==1 do clearBaked owners[1]
            autoRender=true;showPoints=true;previewCheck.checked=true;redrawViews()
        )
        on buildButton pressed do (
            try (
                local owners=refs.dependentNodes this
                if owners.count!=1 do throw "Use a unique scatter controller."
                local n=bakeInstances owners[1]
                previewCheck.checked=showPoints
                status.text=(n as string)+" / "+(amount as string)+" instances built."
                redrawViews()
            ) catch (messageBox (getCurrentException()) title:"Amin Scatter")
        )
    )
    rollout layerFooterUI "Add scatter layer" width:#cmdPanel (
        local controlsReady=false
        on layerFooterUI close do controlsReady=false
        button newLayerBottom "New Layer" pos:[8,8] width:146
        on layerFooterUI open do (controlsReady=true;ensureLayers();newLayerBottom.enabled=layerObjects.count<10)
        on newLayerBottom pressed do (
            try(newLayer();AminScatterRefreshLayerPanels this;redrawViews())catch(messageBox (getCurrentException()) title:"Amin Scatter")
        )
    )
    on update do (
        if version<10 and isValidNode surface and surfaceNodes.count==0 do (append surfaceNodes surface;surface=undefined)
        if version<4 and distributionMode==2 do (distributionMode=1;diversityMode=2;diversitySize=clusterRadius)
        -- Version-1 scenes retain their former uniform scale and XYZ ranges.
        if version==1 do (
        sclXMin=sclYMin=sclZMin=scaleMinimum
        sclXMax=sclYMax=sclZMax=scaleMaximum
        rotXMin=rotYMin=-tiltDegrees;rotXMax=rotYMax=tiltDegrees
        rotZMin=yawMinimum;rotZMax=yawMaximum
        movXMin=movYMin=movZMin=-movementRange
        movXMax=movYMax=movZMax=movementRange
        )
        syncColors()
        dirty=true
    )
    on attachedToNode n do n.renderable=false
    fn iconLines = (
        local paths=#()
        local ring=for i=0 to 64 collect [cos(i*360.0/64),sin(i*360.0/64),0]
        append paths ring
        -- S outline, composed of two connected semicircular arcs.
        local letterS=#()
        for i=0 to 24 do (local a=i*270.0/24;append letterS [-0.35+0.23*cos(a),0.23+0.23*sin(a),0])
        for i=0 to 24 do (local a=90-i*270.0/24;append letterS [-0.35+0.23*cos(a),-0.23+0.23*sin(a),0])
        append paths letterS
        append paths (for i=0 to 48 collect [0.35+0.25*cos(45+i*270.0/48),0.46*sin(45+i*270.0/48),0])

        for path in paths collect (for p in path collect p*iconSize)
 )
 on buildMesh do (
        -- Zero-area edges supply picking bounds; visible icon is drawn as lines.
        local verts=#(),faces=#()
        for path in iconLines() do for i=1 to path.count-1 do (
            local k=verts.count;join verts #(path[i],path[i+1]);append faces [k+1,k+2,k+2]
        )
        setMesh mesh vertices:verts faces:faces
 )
  tool create (
        on mousePoint click do (
            if click==1 do nodeTM.translation=gridPoint
            if click==2 do #stop
        )
        on mouseMove click do (
            if click==2 do iconSize=amax 0.1 (distance nodeTM.translation gridPoint)
        )
    )
)
fn AminScatterObjectDraw = (
    gw.setTransform (matrix3 1)
    for n in objects where (classof n.baseObject==AminScatterObject and not n.isHidden) do (
        gw.setTransform n.objectTransform;gw.setColor #line red
        for path in n.baseObject.iconLines() do gw.polyline path false
        gw.setTransform (matrix3 1)
        for entry in n.baseObject.layerEntries() do (
            local obj=entry[2]
            if obj.showPoints do (
                local cache=obj.previewCache()
                if cache!=undefined do aminScatterDrawPreview cache (obj.pointColorMode==1) obj.solidPointColor
            )
        )
    )
    gw.enlargeUpdateRect #whole
)
registerRedrawViewsCallback AminScatterObjectDraw









-- Final-render bridge: geometry-sharing nodes exist only for the render session.
global AminScatterRenderNodes
global AminScatterRenderRestore
global AminScatterRenderRedrawHeld
global AminScatterRenderWasDirty
global AminScatterRenderBegin
global AminScatterRenderEnd
if AminScatterRenderNodes==undefined do AminScatterRenderNodes=#()
if AminScatterRenderRestore==undefined do AminScatterRenderRestore=#()
if AminScatterRenderRedrawHeld==undefined do AminScatterRenderRedrawHeld=false
fn AminScatterRenderEnd = (
    undo off (
        for n in AminScatterRenderNodes where isValidNode n do delete n
        AminScatterRenderNodes=#()
        for item in AminScatterRenderRestore where isValidNode item[1] do item[1].renderable=item[2]
        AminScatterRenderRestore=#()
    )
    if AminScatterRenderRedrawHeld do (
        AminScatterRenderRedrawHeld=false
        enableSceneRedraw()
        if AminScatterRenderWasDirty==false do setSaveRequired false
        redrawViews()
    )
)
fn AminScatterRenderBegin = (
    AminScatterRenderEnd()
    local controllers=for n in objects where classof n.baseObject==AminScatterObject and not n.isHidden collect n
    if controllers.count>0 do (
        AminScatterRenderWasDirty=getSaveRequired()
        disableSceneRedraw();AminScatterRenderRedrawHeld=true
        try (
            undo off (
                for owner in controllers do (
                    local root=owner.baseObject
                    local key=owner.handle as string
                    for entry in (root.layerEntries includeDisabled:true) do (
                        local index=entry[1];local obj=entry[2]
                        local enabled=root.layerEnabled[index]
                        if not enabled or obj.autoRender do (
                            for old in obj.bakedNodes where isValidNode old do (
                                if (getUserProp old "AminScatterOwner" as string)==key do (
                                    append AminScatterRenderRestore #(old,old.renderable)
                                    old.renderable=false
                                )
                            )
                        )
                        local plants=obj.validSources()
                        if enabled and obj.autoRender and plants.count>0 and (obj.validSurfaces()).count>0 do (
                            local data=obj.placements plants
                            for row in data do (
                                local n=instance plants[row[2]]
                                append AminScatterRenderNodes n
                                n.parent=undefined
                                n.name=uniqueName "AminScatter_RenderTemp_"
                                n.transform=row[1];n.renderable=true;n.isHidden=false
                                n.boxMode=true
                                setUserProp n "AminScatterRenderTemporary" true
                                setUserProp n "AminScatterLayer" root.layerNames[index]
                            )
                        )
                    )
                )
            )
        ) catch (
            local reason=getCurrentException()
            AminScatterRenderEnd()
            format "Amin Scatter automatic render failed: %\n" reason
            throw()
        )
    )
)
callbacks.removeScripts id:#AminScatterAutoRender
callbacks.addScript #preRender "AminScatterRenderBegin()" id:#AminScatterAutoRender persistent:false
callbacks.addScript #postRender "AminScatterRenderEnd()" id:#AminScatterAutoRender persistent:false
callbacks.addScript #systemPreReset "AminScatterRenderEnd()" id:#AminScatterAutoRender persistent:false
callbacks.addScript #filePreOpen "AminScatterRenderEnd()" id:#AminScatterAutoRender persistent:false








-- Events mark only controllers whose inputs changed. No geometry polling loop.
global AminScatterNodeEvents
global AminScatterLiveChanged
global AminScatterLiveTime
try(AminScatterNodeEvents.enabled=false)catch()
try(unRegisterTimeCallback AminScatterLiveTime)catch()
fn AminScatterLiveChanged event handles = (
    if AminScatterRenderRedrawHeld!=true do (
        local nodes=for h in handles collect (getAnimByHandle h)
        local redraw=false
        for n in objects where classof n.baseObject==AminScatterObject do (
            for entry in (n.baseObject.layerEntries includeDisabled:true) do (
                if event==#deleted then (entry[2].invalidateLive();redraw=true)
                else if entry[2].externalChanged nodes do redraw=true
            )
        )
        if redraw do redrawViews()
    )
)
fn AminScatterLiveTime = (
    if AminScatterRenderRedrawHeld!=true do (
        for n in objects where classof n.baseObject==AminScatterObject do (for entry in (n.baseObject.layerEntries includeDisabled:true) do entry[2].invalidateLive())
        redrawViews()
    )
)
AminScatterNodeEvents=NodeEventCallback mouseUp:false delay:150 deleted:AminScatterLiveChanged geometryChanged:AminScatterLiveChanged topologyChanged:AminScatterLiveChanged mappingChanged:AminScatterLiveChanged modelStructured:AminScatterLiveChanged modelOtherEvent:AminScatterLiveChanged controllerOtherEvent:AminScatterLiveChanged controllerStructured:AminScatterLiveChanged linkChanged:AminScatterLiveChanged
registerTimeCallback AminScatterLiveTime




global AminScatterLayerUndo
fn AminScatterLayerUndo = (
    for n in objects where classof n.baseObject==AminScatterObject do (
        for entry in (n.baseObject.layerEntries includeDisabled:true) do entry[2].forcePreviewUpdate()
        if (modPanel.getCurrentObject())==n.baseObject do AminScatterRefreshLayerPanels n.baseObject
    )
    redrawViews()
)
callbacks.removeScripts id:#AminScatterLayers
callbacks.addScript #sceneUndo "AminScatterLayerUndo()" id:#AminScatterLayers persistent:false
callbacks.addScript #sceneRedo "AminScatterLayerUndo()" id:#AminScatterLayers persistent:false

