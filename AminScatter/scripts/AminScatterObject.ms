global CyrusPerfTraceBegin,CyrusPerfTraceEnd,CyrusPerfTraceInput
global CyrusStartBrush,CyrusStopBrush,CyrusBrushSessionRoot,CyrusBrushSessionLayer
global CyrusScatterObject,CyrusNewLayerID
fn CyrusNewLayerID = (local value=(dotNetClass "System.Guid").NewGuid();value.ToString())
global CyrusLayerStatusData,CyrusUICount,CyrusUILayerState
struct CyrusLayerStatusData (
    hasResult=false,placements=0,previewCount=0,mode=0,buildMs=0,
    needsUpdate=true,errorText="",densityCapped=false,inputOff=false
)
fn CyrusUICount value compact:false = (
    if compact and value>=1000000 do return ((formattedPrint (value/1000000.0) format:".1f")+"m")
    if compact and value>=1000 do return ((formattedPrint (value/1000.0) format:".1f")+"k")
    local digits=substituteString (value as string) "L" "",result=""
    for i=1 to digits.count do (
        result+=substring digits i 1
        if i<digits.count and mod (digits.count-i) 3==0 do result+=","
    )
    result
)
fn CyrusUILayerState stats enabled controllerEnabled previewVisible = (
    if not controllerEnabled do return #("Off","Controller disabled")
    if not enabled do return #("Off","Layer disabled")
    if stats.inputOff do return #("Off","Analyzer input disabled")
    if stats.errorText!="" do return #("Error","Preview error")
    if not previewVisible do return #("Hidden",if stats.needsUpdate then "Preview hidden; needs Update" else "Preview hidden")
    if not stats.hasResult do return #("--","Not built")
    if stats.needsUpdate do return #("Stale","Needs update")
    if stats.mode>1 and stats.previewCount<stats.placements do return #("Limited","Preview displays a subset")
    if stats.placements==0 do return #("Empty","Empty")
    #("OK","Cached")
)

global CyrusPointOwner,CyrusPointSync,CyrusViewportRedraw,CyrusPointClear,CyrusPointAfterSave
global CyrusPointOwners,CyrusPointEnabled=true,CyrusMeshEnabled=true,CyrusPointAvailable=false,CyrusPointBusy=false,CyrusPointPending=false,CyrusPointSuspended=false,CyrusPointLastError="",CyrusPointDeletedHandles=#()
try(CyrusPointClear())catch()
CyrusPointOwners=#()
global cyrusFilterSourceRows,cyrusApplySourceTransforms
global CyrusInteractionHeld,CyrusWasDragging=false,CyrusReleaseTimer,CyrusReleaseTick
fn CyrusInteractionHeld = (try((dotNetClass "System.Windows.Forms.Control").MouseButtons != (dotNetClass "System.Windows.Forms.MouseButtons").None)catch(false))
global CyrusFallPack,CyrusFallUnpack,CyrusOpenFalloffGraph
fn CyrusFallPack values = (local s=stringStream "";for i=1 to values.count do format "% %" values[i] (if i<values.count then "," else "") to:s;s as string)
fn CyrusFallUnpack data = (for v in filterString data "," collect (v as float))
global CyrusFalloffGraph,CyrusFallGraphTarget,CyrusFallGraphArea,CyrusFallGraphDensity
fn CyrusOpenFalloffGraph target areaNode density = (
    if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()
    rollout editor "Area Falloff - Edit Graph" width:760 height:470 (
        local obj,area,isDensity=false,loading=true
        curveControl graph "" pos:[8,8] width:744 height:396 numCurves:1 x_range:[0,1] y_range:[0,100] commandMode:#move_xy asPopup:false
        button applyButton "Apply" pos:[538,424] width:100
        button doneButton "Close" pos:[648,424] width:100
        label help "X: distance along ramp (0 to 1). Y: percent. Drag points / edit Bezier handles." pos:[12,424] width:510 height:36
        fn storeCurve = (
            if not loading do (
                local cfg=obj.getFallConfig area
                local curve=graph.curves[1],packed=#()
                if curve.numPoints<2 do return false
                for i=1 to curve.numPoints do (
                    local p=curve.points[i]
                    join packed #(p.value.x,p.value.y,p.inTangent.x,p.inTangent.y,p.outTangent.x,p.outTangent.y,(if p.bezier then 1 else 0),(if p.corner then 1 else 0))
                )
                local values=for i=0 to 256 collect (
                    local v=amax 0.0 ((getValue curve 0 (i/256.0))/100.0)
                    if isDensity then amin 1.0 v else v
                )
                cfg[if isDensity then 8 else 5]=values
                obj.setFallConfig area cfg
                obj.setFallGraph area isDensity (CyrusFallPack packed)
                CyrusViewportRedraw()
            )
            true
        )
        on editor open do (
            obj=CyrusFallGraphTarget;area=CyrusFallGraphArea;isDensity=CyrusFallGraphDensity
            editor.title=(if isDensity then "Area Density Falloff" else "Area Scale Falloff")+" - "+(if area==undefined then "Analyzer Boundary" else area.name)
            local cfg=obj.getFallConfig area
            local packed=CyrusFallUnpack (obj.getFallGraph area isDensity)
            local values=cfg[if isDensity then 8 else 5]
            local c=graph.curves[1];c.color=red
            graph.y_range=[0,(if isDensity then 100 else amax 100.0 ((amax values)*100))]
            if packed.count>=16 and mod packed.count 8==0 then (
                c.numPoints=packed.count/8
                for i=1 to c.numPoints do (
                    local j=(i-1)*8,p=c.points[i]
                    p.value=[packed[j+1],packed[j+2]];p.inTangent=[packed[j+3],packed[j+4]];p.outTangent=[packed[j+5],packed[j+6]]
                    p.bezier=packed[j+7]>0;p.corner=packed[j+8]>0;p.lock_x=(i==1 or i==c.numPoints)
                    c.points[i]=p
                )
            ) else (
                c.numPoints=values.count
                for i=1 to c.numPoints do (
                    local p=c.points[i];p.value=[(i-1.0)/(c.numPoints-1),values[i]*100];p.bezier=false;p.corner=true;p.lock_x=(i==1 or i==c.numPoints);c.points[i]=p
                )
            )
            zoom graph #all;loading=false
        )
        on graph ptChanged ci val do storeCurve()
        on graph tangentChanged ci val kind do storeCurve()
        on graph ptInserted ci val do storeCurve()
        on graph deleted ci val do storeCurve()
        on graph reset ci do storeCurve()
        on applyButton pressed do storeCurve()
        on doneButton pressed do (storeCurve();destroyDialog editor)
        on editor close do (storeCurve();CyrusFalloffGraph=undefined)
    )
    CyrusFallGraphTarget=target;CyrusFallGraphArea=areaNode;CyrusFallGraphDensity=density
    CyrusFalloffGraph=editor
    createDialog editor style:#(#style_titlebar,#style_sysmenu,#style_minimizebox) pos:[200,160]
    editor
)

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
AminScatterLayerFields=#(#paintDocument,#paintEnabled,#paintIdentity,#paintDensity,#streetTrimStart,#streetTrimEnd,#centerStreetOffset,#areaAnalyzer,#areaUseLine,#areaLineWidth,#areaLineCaps,#areaUsePoints,#areaPointRadius,#wholeScaleMin,#wholeScaleMax,#fallScaleGraph,#fallDensityGraph,#areaFallConfigs,#areaFallScaleGraphs,#areaFallDensityGraphs,#fallAnalyzer,#fallDelete,#fallDeleteWidth,#fallScale,#fallScaleWidth,#fallScaleCurve,#fallDensity,#fallDensityWidth,#fallDensityCurve,#edgeRotX,#edgeRotY,#edgeRotZ,#edgeKeepCorners,#edgeCornerAngle,#edgeCornerCount,#edgeFaceOut,#edgeCornerRadius,#edgeOffsets,#edgeAlong,#edgeAcross,#borderFaceOut,#streetFaceOut,#borderCornerRadius,#streetCornerRadius,#sourceForwardAxes,#finalCleanup,#finalNeighborRadius,#finalMinNeighbors,#finalMinIsland,#finalRelax,#finalStrength,#finalIterations,#finalMaxMove,#overlapSourceRadius,#sourceRadii,#sourceFollowScale,#sourceShowRadius,#streetStraight,#sourcePoint,#sourceEmpty,#overlapEnabled,#overlapRadius,#overlapGap,#overlapPlanar,#overlapBlockers,#sourceZOffsets,#sourceScales,#sourceWeights,#showCenters,#collisionEnabled,#collisionRadius,#relaxEnabled,#relaxSpacing,#relaxIterations,#relaxStrength,#sources,#bakedNodes,#amount,#randomSeed,#scaleMinimum,#scaleMaximum,#tiltDegrees,#yawMinimum,#yawMaximum,#movementRange,#alignNormal,#showPoints,#pointsPerPlant,#updateMode,#populationMode,#plantsPerM2,#advancedAxes,#projectMove,#rotXMin,#rotXMax,#rotYMin,#rotYMax,#rotZMin,#rotZMax,#sclXMin,#sclXMax,#sclYMin,#sclYMax,#sclZMin,#sclZMax,#movXMin,#movXMax,#movYMin,#movYMax,#movZMin,#movZMax,#distributionMode,#clusterCount,#clusterRadius,#densityMap,#invertDensity,#diversityMode,#diversitySize,#diversitySeed,#roughness,#blurryEdge,#diversityNoise,#autoRender,#previewBudget,#pointColorMode,#solidPointColor,#areaNodes,#areaModes,#sourceColors,#patternLines,#patternWidths,#patternGroups,#patternRestGroup)
AminScatterLayerTabs=#(#areaFallConfigs,#areaFallScaleGraphs,#areaFallDensityGraphs,#fallScaleCurve,#fallDensityCurve,#edgeRotX,#edgeRotY,#edgeRotZ,#edgeOffsets,#edgeAlong,#edgeAcross,#sourceForwardAxes,#sourceRadii,#sourceFollowScale,#sourceShowRadius,#sourcePoint,#sourceEmpty,#overlapBlockers,#sourceZOffsets,#sourceScales,#sourceWeights,#sources,#bakedNodes,#areaNodes,#areaModes,#sourceColors,#patternLines,#patternWidths,#patternGroups)
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
                    setProperty destination key (if key==#paintDocument and origin.paintDocument!=undefined then copy origin.paintDocument else getProperty origin key)
                )
            )
        )
        destination.setLayerTransfer false
    ) catch(destination.setLayerTransfer false;throw())
)
fn AminScatterRefreshLayerPanels obj reopen:true = (obj.bindNativeUI())
global CyrusEditStackKey,CyrusEditApplyLayer
fn CyrusEditStackKey root = (
 local text=(cyrusEditRevision() as string)
 for n in refs.dependentNodes root where n.baseObject==root do (
  for m in n.modifiers where classof m==CyrusScatterEdit do (
   cyrusEditActiveLayers m (for i=1 to root.layerEnabled.count where root.layerEnabled[i] collect (if root.layerObjects[i].editLayerKey>0 then root.layerObjects[i].editLayerKey else i))
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
 local index=if layer.editLayerKey>0 then layer.editLayerKey else findItem root.layerObjects layer
 local signature=if layer.paintIdentity then layer.paintPopulation else cyrusEditFingerprint rows ((layer.randomSeed as string)+"|"+(layer.diversitySeed as string)+"|"+(index as string))
 if layer.paintIdentity then cyrusEditStack active rows index signature true else cyrusEditStack active rows index signature
)

plugin simpleObject AminScatterObject
name:"Cyrus Scatter"
classID:#(0x617d43a1,0x395c2e17)
category:"Cyrus"
version:49
initialRollupState:0xffe
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
    local cachedPaintRevision=0,paintPopulation="",paintBaseKey="",paintBaseRows=undefined,paintBaseBuilds=0,paintBaseHits=0,paintSignatureRows=undefined
    parameters paintSettings (
        paintDocument type:#maxObject
        paintEnabled type:#boolean default:false
        paintIdentity type:#boolean default:false
        paintDensity type:#float default:1
        editLayerKey type:#integer default:0
        nextEditLayerKey type:#integer default:1
        on paintDocument set value do (cachedPaintRevision=0;dirty=true)
        on paintEnabled set value do dirty=true
        on paintDensity set value do dirty=true
    )

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
    parameters surfaceSettings (
        surfaceNodes type:#nodeTab tabSize:0 tabSizeVariable:true useNodeTmValidity:true useNodeOsValidity:true
        on surfaceNodes set v i do dirty=true
    )
    parameters updateSettings (
        updateMode type:#integer default:2
        on updateMode set v do (dirty=true;if not layerTransfer do CyrusViewportRedraw())
    )
    parameters populationSettings (
        populationMode type:#integer default:1
        plantsPerM2 type:#float default:100
        on populationMode set v do dirty=true
        on plantsPerM2 set v do dirty=true
    )
    fn validSurfaces = (
        if this.paintIdentity and this.paintDocument!=undefined do (
            local target=cyrusBrushTarget this.paintDocument
            return (if isValidNode target then #(target) else #())
        )
        local result=#()
        local nodes=if surfaceNodes.count>0 then (surfaceNodes as array) else #(surface)
        for n in nodes where isValidNode n and classof n.baseObject!=AminScatterObject and findItem result n==0 do append result n
        result
    )
    local overlapOwner=undefined,overlapBefore=0,overlapAfter=0
    parameters overlapSettings (
        overlapEnabled type:#boolean default:false
        overlapRadius type:#worldunits default:10
        overlapGap type:#worldunits default:0
        overlapPlanar type:#boolean default:true
        overlapBlockers type:#intTab tabSize:0 tabSizeVariable:true
        on overlapEnabled set v do dirty=true
        on overlapRadius set v do dirty=true
        on overlapGap set v do dirty=true
        on overlapPlanar set v do dirty=true
        on overlapBlockers set v i do dirty=true
    )
    fn setOverlapOwner root = (overlapOwner=root)
    fn overlapStats = (#(overlapBefore,overlapBefore-overlapAfter,overlapAfter))
    local radiusPreview=#()
    parameters finalSettings (
        finalCleanup type:#boolean default:false
        finalNeighborRadius type:#worldunits default:100
        finalMinNeighbors type:#integer default:2
        finalMinIsland type:#integer default:5
        finalRelax type:#boolean default:false
        finalStrength type:#float default:0.3
        finalIterations type:#integer default:5
        finalMaxMove type:#worldunits default:10
        on finalCleanup set v do dirty=true
        on finalNeighborRadius set v do dirty=true
        on finalMinNeighbors set v do dirty=true
        on finalMinIsland set v do dirty=true
        on finalRelax set v do dirty=true
        on finalStrength set v do dirty=true
        on finalIterations set v do dirty=true
        on finalMaxMove set v do dirty=true
    )
    parameters viewportGeometrySettings (
        viewportMode type:#integer default:1
        proxyShape type:#integer default:1
        viewportInstances type:#integer default:2000
        viewportFaces type:#integer default:2000000
        on viewportMode set v do dirty=true
        on proxyShape set v do dirty=true
        on viewportInstances set v do dirty=true
        on viewportFaces set v do dirty=true
    )
    parameters radiusDisplaySettings (
        radiusDisplayLimit type:#integer default:2000
        radiusDisplayAll type:#boolean default:false
        on radiusDisplayLimit set v do dirty=true
        on radiusDisplayAll set v do dirty=true
    )
    parameters radiusSettings (
        sourceRadii type:#floatTab tabSize:0 tabSizeVariable:true
        sourceFollowScale type:#boolTab tabSize:0 tabSizeVariable:true
        sourceShowRadius type:#boolTab tabSize:0 tabSizeVariable:true
        overlapSourceRadius type:#boolean default:false
        on sourceRadii set v i do dirty=true
        on sourceFollowScale set v i do dirty=true
        on sourceShowRadius set v i do dirty=true
        on overlapSourceRadius set v do dirty=true
    )
    fn sourceRadius i = (if i>0 and i<=sourceRadii.count then sourceRadii[i] else 0.0)
    fn sourceFollows i = (i>0 and i<=sourceFollowScale.count and sourceFollowScale[i])
    fn sourceShows i = (i>0 and i<=sourceShowRadius.count and sourceShowRadius[i])
    fn setSourceRadius rows value kind:1 = (
        undo "Source collision radius" on (
            while sourceRadii.count<sources.count do append sourceRadii 0.0
            while sourceFollowScale.count<sources.count do append sourceFollowScale false
            while sourceShowRadius.count<sources.count do append sourceShowRadius false
            for i in rows do case kind of (1: (sourceRadii[i]=value); 2: (sourceFollowScale[i]=value); 3: (sourceShowRadius[i]=value))
        )
        dirty=true
    )
    parameters emptySettings (
        sourcePoint type:#boolTab tabSize:0 tabSizeVariable:true
        on sourcePoint set v i do dirty=true
        sourceEmpty type:#boolTab tabSize:0 tabSizeVariable:true
        on sourceEmpty set v i do dirty=true
    )
    local cachedFallRun=-1
    parameters falloffSettings (
        fallAnalyzer type:#node useNodeTmValidity:true useNodeOsValidity:true
        fallDelete type:#boolean default:false
        fallDeleteWidth type:#worldunits default:0
        fallScale type:#boolean default:false
        fallScaleWidth type:#worldunits default:100
        fallScaleCurve type:#floatTab tabSize:0 tabSizeVariable:true
        fallDensity type:#boolean default:false
        fallDensityWidth type:#worldunits default:100
        fallDensityCurve type:#floatTab tabSize:0 tabSizeVariable:true
        on fallAnalyzer set v do dirty=true
        on fallDelete set v do dirty=true
        on fallDeleteWidth set v do dirty=true
        on fallScale set v do dirty=true
        on fallScaleWidth set v do dirty=true
        on fallScaleCurve set v i do dirty=true
        on fallDensity set v do dirty=true
        on fallDensityWidth set v do dirty=true
        on fallDensityCurve set v i do dirty=true
    )
    fn ensureFallCurves = (
        while fallScaleCurve.count<5 do append fallScaleCurve (fallScaleCurve.count/4.0)
        while fallDensityCurve.count<5 do append fallDensityCurve (fallDensityCurve.count/4.0)
    )
    parameters wholeScaleSettings (
        wholeScaleMin type:#float default:1.0
        wholeScaleMax type:#float default:1.0
        on wholeScaleMin set v do dirty=true
        on wholeScaleMax set v do dirty=true
    )
    local cachedAreaAnalyzerRun=-1
    parameters analyzerAreaSettings (
        areaAnalyzer type:#node useNodeTmValidity:true useNodeOsValidity:true
        on areaAnalyzer set v do dirty=true
        areaUseLine type:#boolean default:false
        on areaUseLine set v do dirty=true
        areaLineWidth type:#worldunits default:100
        on areaLineWidth set v do dirty=true
        areaLineCaps type:#integer default:1
        on areaLineCaps set v do dirty=true
        areaUsePoints type:#boolean default:false
        on areaUsePoints set v do dirty=true
        areaPointRadius type:#worldunits default:100
        on areaPointRadius set v do dirty=true
    )
    fn applyAnalyzerArea rows = (
        if not (areaUseLine or areaUsePoints) then rows else (
            if not (CyrusAnalyzerFilter areaAnalyzer) do throw "Area: pick a Surface Analyzer."
            local paths=if areaUseLine then this.centerStreetPaths areaAnalyzer else #()
            local pts=if areaUsePoints then areaAnalyzer.samplePoints as array else #()
            cyrusAnalyzerArea rows paths pts (areaLineWidth/2.0) areaPointRadius areaLineCaps
        )
    )
    parameters areaFalloffSettings (
        fallScaleGraph type:#string default:""
        fallDensityGraph type:#string default:""
        areaFallConfigs type:#stringTab tabSize:0 tabSizeVariable:true
        areaFallScaleGraphs type:#stringTab tabSize:0 tabSizeVariable:true
        areaFallDensityGraphs type:#stringTab tabSize:0 tabSizeVariable:true
        on areaFallConfigs set v i do dirty=true
    )
    fn ensureAreaFalloffs = (
        while areaFallConfigs.count<this.areaNodes.count do append areaFallConfigs ""
        while areaFallScaleGraphs.count<this.areaNodes.count do append areaFallScaleGraphs ""
        while areaFallDensityGraphs.count<this.areaNodes.count do append areaFallDensityGraphs ""
    )
    fn getFallConfig areaNode = (
        ensureFallCurves()
        if areaNode==undefined then #(fallDelete,fallDeleteWidth,fallScale,fallScaleWidth,fallScaleCurve as array,fallDensity,fallDensityWidth,fallDensityCurve as array) else (
            local i=findItem this.areaNodes areaNode
            if i==0 do throw "Area line was removed. Close this graph."
            ensureAreaFalloffs()
            local parts=filterString areaFallConfigs[i] "|"
            if parts.count==8 then #((parts[1] as integer)==1,parts[2] as float,(parts[3] as integer)==1,parts[4] as float,CyrusFallUnpack parts[5],(parts[6] as integer)==1,parts[7] as float,CyrusFallUnpack parts[8]) else #(false,0.0,false,100.0,#(0.0,1.0),false,100.0,#(0.0,1.0))
        )
    )
    fn setFallConfig areaNode cfg = (
        if areaNode==undefined then (
            fallDelete=cfg[1];fallDeleteWidth=cfg[2];fallScale=cfg[3];fallScaleWidth=cfg[4];fallScaleCurve=cfg[5];fallDensity=cfg[6];fallDensityWidth=cfg[7];fallDensityCurve=cfg[8]
        ) else (
            local i=findItem this.areaNodes areaNode
            if i==0 do throw "Area line was removed. Close this graph."
            ensureAreaFalloffs()
            local s=stringStream ""
            format "%|%|%|%|%|%|%|%" (if cfg[1] then 1 else 0) cfg[2] (if cfg[3] then 1 else 0) cfg[4] (CyrusFallPack cfg[5]) (if cfg[6] then 1 else 0) cfg[7] (CyrusFallPack cfg[8]) to:s
            areaFallConfigs[i]=s as string
        )
        dirty=true
    )
    fn getFallGraph areaNode density = (
        if areaNode==undefined then (if density then fallDensityGraph else fallScaleGraph) else (
            ensureAreaFalloffs();local i=findItem this.areaNodes areaNode
            if i==0 then "" else (if density then areaFallDensityGraphs[i] else areaFallScaleGraphs[i])
        )
    )
    fn setFallGraph areaNode density data = (
        if areaNode==undefined then (if density then fallDensityGraph=data else fallScaleGraph=data) else (
            ensureAreaFalloffs();local i=findItem this.areaNodes areaNode
            if i>0 do (if density then areaFallDensityGraphs[i]=data else areaFallScaleGraphs[i]=data)
        )
    )
    fn applyFalloff rows = (
        local cfg=getFallConfig undefined
        if cfg[1] or cfg[3] or cfg[6] do (
            if not (CyrusAnalyzerFilter fallAnalyzer) do throw "Area Edge Falloff: pick a Surface Analyzer."
            local paths=fallAnalyzer.packedLines fallAnalyzer.boundaryVertices fallAnalyzer.boundaryCounts
            if paths.count==0 do throw "Area Edge Falloff: Analyzer has no Boundary. Run Analyze first."
            rows=cyrusBoundaryFalloff rows paths cfg randomSeed
        )
        for i=1 to this.areaNodes.count where isValidNode this.areaNodes[i] do (
            cfg=getFallConfig this.areaNodes[i]
            if cfg[1] or cfg[3] or cfg[6] do rows=cyrusAreaFalloff rows this.areaNodes[i] cfg randomSeed (if i<=this.areaModes.count then this.areaModes[i] else 1)
        )
        rows
    )


    parameters edgeRowSettings (
        edgeRotX type:#floatTab tabSize:0 tabSizeVariable:true
        on edgeRotX set v i do dirty=true
        edgeRotY type:#floatTab tabSize:0 tabSizeVariable:true
        on edgeRotY set v i do dirty=true
        edgeRotZ type:#floatTab tabSize:0 tabSizeVariable:true
        on edgeRotZ set v i do dirty=true
        edgeKeepCorners type:#boolean default:false
        edgeCornerAngle type:#float default:45
        edgeCornerCount type:#integer default:1
        on edgeKeepCorners set v do dirty=true
        on edgeCornerAngle set v do dirty=true
        on edgeCornerCount set v do dirty=true
        edgeOffsets type:#floatTab tabSize:0 tabSizeVariable:true
        edgeAlong type:#floatTab tabSize:0 tabSizeVariable:true
        edgeAcross type:#floatTab tabSize:0 tabSizeVariable:true
        edgeFaceOut type:#boolean default:true
        edgeCornerRadius type:#worldunits default:10.0
        on edgeOffsets set v i do dirty=true
        on edgeAlong set v i do dirty=true
        on edgeAcross set v i do dirty=true
        on edgeFaceOut set v do dirty=true
        on edgeCornerRadius set v do dirty=true
    )
    parameters orientationSettings (
        sourceForwardAxes type:#intTab tabSize:0 tabSizeVariable:true
        borderFaceOut type:#boolean default:false
        streetFaceOut type:#boolean default:false
        borderCornerRadius type:#worldunits default:10.0
        streetCornerRadius type:#worldunits default:10.0
        on sourceForwardAxes set v i do dirty=true
        on borderFaceOut set v do dirty=true
        on streetFaceOut set v do dirty=true
        on borderCornerRadius set v do dirty=true
        on streetCornerRadius set v do dirty=true
    )
    fn sourceForward i = (if i>0 and i<=sourceForwardAxes.count then amax 1 (amin 4 sourceForwardAxes[i]) else 1)
    fn assignSourceForward rows value = (
        undo "Cyrus source forward axis" on (
            while sourceForwardAxes.count<sources.count do append sourceForwardAxes 1
            for i in rows where i>0 and i<=sources.count do sourceForwardAxes[i]=value
        )
        dirty=true
    )
    parameters sourceTransformSettings (
        sourceZOffsets type:#floatTab tabSize:0 tabSizeVariable:true
        sourceScales type:#floatTab tabSize:0 tabSizeVariable:true
        on sourceZOffsets set v i do dirty=true
        on sourceScales set v i do dirty=true
    )
    fn sourceZOffset i = (if i>0 and i<=sourceZOffsets.count then sourceZOffsets[i] else 0.0)
    fn sourceScale i = (if i>0 and i<=sourceScales.count then sourceScales[i] else 1.0)
    fn assignSourceTransform rows value scaling:false = (
        undo "Cyrus Scatter source transform" on (
            if scaling then (
                while sourceScales.count<sources.count do append sourceScales 1.0
                for i in rows where i>0 and i<=sources.count do sourceScales[i]=amax 0.0 value
            ) else (
                while sourceZOffsets.count<sources.count do append sourceZOffsets 0.0
                for i in rows where i>0 and i<=sources.count do sourceZOffsets[i]=value
            )
        )
        dirty=true
    )
    parameters weightSettings (
        sourceWeights type:#floatTab tabSize:0 tabSizeVariable:true
        on sourceWeights set v i do dirty=true
    )
    fn sourceWeight i = (if i>0 and i<=sourceWeights.count then sourceWeights[i] else 1.0)
    fn assignWeight rows value = (
        undo "Cyrus Scatter source weight" on (
            while sourceWeights.count<sources.count do append sourceWeights 1.0
            for i in rows where i>0 and i<=sources.count do sourceWeights[i]=amin 1.0 (amax 0.0 value)
        )
        dirty=true
    )
    parameters centerDisplay (
        showCenters type:#boolean default:false
        on showCenters set v do (dirty=true;previewBuildCount=0)
    )
    parameters spacingSettings (
        collisionEnabled type:#boolean default:false
        collisionRadius type:#worldUnits default:0.1
        relaxEnabled type:#boolean default:false
        relaxSpacing type:#worldUnits default:0.2
        relaxIterations type:#integer default:10
        relaxStrength type:#float default:0.5
        on collisionEnabled set v do dirty=true
        on collisionRadius set v do dirty=true
        on relaxEnabled set v do dirty=true
        on relaxSpacing set v do dirty=true
        on relaxIterations set v do dirty=true
        on relaxStrength set v do dirty=true
    )
    parameters randomization (
        advancedAxes type:#boolean default:true
        projectMove type:#boolean default:true
        rotXMin type:#float default:0
        rotXMax type:#float default:0
        rotYMin type:#float default:0
        rotYMax type:#float default:0
        rotZMin type:#float default:0
        rotZMax type:#float default:360
        sclXMin type:#float default:1
        sclXMax type:#float default:1
        sclYMin type:#float default:1
        sclYMax type:#float default:1
        sclZMin type:#float default:1
        sclZMax type:#float default:1
        movXMin type:#float default:0
        movXMax type:#float default:0
        movYMin type:#float default:0
        movYMax type:#float default:0
        movZMin type:#float default:0
        movZMax type:#float default:0
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
    parameters distributionSettings (
        distributionMode type:#integer default:1
        clusterCount type:#integer default:12
        clusterRadius type:#worldUnits default:10
        densityMap type:#textureMap
        invertDensity type:#boolean default:false
        on distributionMode set v do dirty=true
        on clusterCount set v do dirty=true
        on clusterRadius set v do dirty=true
        on densityMap set v do dirty=true
        on invertDensity set v do dirty=true
    )
    parameters diversitySettings (
        diversityMode type:#integer default:1
        diversitySize type:#worldUnits default:10
        diversitySeed type:#integer default:42
        roughness type:#float default:0
        blurryEdge type:#float default:0
        diversityNoise type:#float default:0
        on diversityMode set v do dirty=true
        on diversitySize set v do dirty=true
        on diversitySeed set v do dirty=true
        on roughness set v do dirty=true
        on blurryEdge set v do dirty=true
        on diversityNoise set v do dirty=true
    )
    parameters displaySettings (
        autoRender type:#boolean default:true
        previewBudget type:#integer default:20000
        on previewBudget set v do dirty=true
        pointColorMode type:#integer default:2
        solidPointColor type:#color default:(color 100 220 120)
        on pointColorMode set v do if not layerTransfer do CyrusViewportRedraw()
        on solidPointColor set v do if not layerTransfer do CyrusViewportRedraw()
    )
    fn displayPointColor groupColor = (if pointColorMode==1 then solidPointColor else groupColor)
    parameters areaSettings (
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
    parameters lineSettings (
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
        undo "Cyrus Scatter band group" on (for i in rows where i>0 and i<=patternGroups.count do patternGroups[i]=key)
        dirty=true
    )
    fn assignRestGroup key = (patternRestGroup=key;dirty=true)
    fn cspImpl_externalChanged changedNodes = (
        if updateMode!=2 then false else (
            local affected=false
            local inputs=validSurfaces()
            join inputs (sources as array)
            join inputs (areaNodes as array)
            if isValidNode areaAnalyzer do append inputs areaAnalyzer
            if isValidNode fallAnalyzer do append inputs fallAnalyzer
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
    fn externalChanged changedNodes = (
        local token=undefined
        if CyrusPerfTraceBegin!=undefined do try(token=CyrusPerfTraceBegin this "external_invalidation")catch()
        try (
            local answer=cspImpl_externalChanged changedNodes
            if token!=undefined and CyrusPerfTraceEnd!=undefined do try(CyrusPerfTraceEnd token ("changed="+(answer as string)))catch()
            answer
        )catch(
            if token!=undefined and CyrusPerfTraceEnd!=undefined do try(CyrusPerfTraceEnd token ("EXCEPTION: "+getCurrentException()))catch()
            throw()
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
        undo "Cyrus Scatter color group" on (
            for i in indices where i>0 and i<=sources.count do sourceColors[i]=canonicalColor c
        )
        dirty=true
    )
    fn usableSource n = (
        isValidNode n and findItem (validSurfaces()) n==0 and classof n.baseObject!=AminScatterObject
    )
    fn isPointSource i = (i>0 and i<=sourcePoint.count and sourcePoint[i])
    fn isEmptySource i = (i>0 and i<=sourceEmpty.count and sourceEmpty[i])
    fn sourceRow n = (if classof n==Integer then -n else findItem sources n)
    fn addEmptySource = (
        undo "Cyrus Scatter add empty source" on (
            syncColors()
            while sourceEmpty.count<sources.count do append sourceEmpty false
            while sourceWeights.count<sources.count do append sourceWeights 1.0
            sources.count=sources.count+1;append sourceEmpty true;append sourceWeights 1.0
            append sourceColors (color 100 100 100)
            if sourceZOffsets.count>0 do append sourceZOffsets 0.0
            if sourceScales.count>0 do append sourceScales 1.0
        )
        dirty=true;sources.count
    )
    fn addPointSource = (
        local i=addEmptySource()
        while sourcePoint.count<sources.count do append sourcePoint false
        sourcePoint[i]=true;dirty=true;i
    )
    fn replacePointSource row node = (
        if not (isPointSource row) or not (usableSource node) or findItem sources node>0 do return false
        undo "Cyrus Scatter replace point" on (
            sources[row]=node;sourcePoint[row]=false;sourceEmpty[row]=false
        )
        dirty=true;previewBuildCount=0;true
    )
    fn placementRadii rows plants = (
        for row in rows collect (
            local i=sourceRow plants[row[2]],r=sourceRadius i
            if sourceFollows i do r*=amax (length row[1].row1) (amax (length row[1].row2) (length row[1].row3))
            r
        )
    )
    fn cacheRadii rows plants = (
        radiusPreview=#()
        if plants.count>0 and (findItem (sourceShowRadius as array) true)>0 do (
            local radii=placementRadii rows plants
            local eligible=for j=1 to rows.count where (sourceShows (sourceRow plants[rows[j][2]])) and radii[j]>0 collect j
            local count=if radiusDisplayAll then eligible.count else amin (amax 0 radiusDisplayLimit) eligible.count
            for k=1 to count do (
                local j=eligible[1+(floor((k-1.0)*eligible.count/(amax 1 count)) as integer)]
                local i=sourceRow plants[rows[j][2]]
                if sourceShows i and radii[j]>0 do (
                    local center=rows[j][1].row4,r=radii[j]
                    local points=for k=0 to 23 collect center+[r*cos(k*15),r*sin(k*15),0]
                    append radiusPreview #(points,sourceColor i)
                )
            )
        )
    )
    fn radiusDisplayCount = radiusPreview.count
    fn drawRadii = (for ring in radiusPreview do (gw.setColor #line ring[2];gw.polyline ring[1] true))
    fn validSources = (for i=1 to sources.count where (isEmptySource i) or (usableSource sources[i]) collect (if isEmptySource i then -i else sources[i]))
    parameters strokeSettings (
        streetStraight type:#boolean default:false
        on streetStraight set v do dirty=true
        strokeSides type:#intTab tabSize:0 tabSizeVariable:true
        patternPaths type:#nodeTab tabSize:0 tabSizeVariable:true
        strokeModes type:#intTab tabSize:0 tabSizeVariable:true
        strokeColorRows type:#intTab tabSize:0 tabSizeVariable:true
        strokeColorKeys type:#intTab tabSize:0 tabSizeVariable:true
        strokeSourceRows type:#intTab tabSize:0 tabSizeVariable:true
        strokeSourceNodes type:#nodeTab tabSize:0 tabSizeVariable:true
        strokeMin type:#floatTab tabSize:0 tabSizeVariable:true
        strokeMax type:#floatTab tabSize:0 tabSizeVariable:true
        analyzerNode type:#node useNodeTmValidity:true useNodeOsValidity:true
        on analyzerNode set v do dirty=true
    )
    fn syncStrokes = (
        while edgeRotX.count<patternLines.count do append edgeRotX 0.0
        while edgeRotY.count<patternLines.count do append edgeRotY 0.0
        while edgeRotZ.count<patternLines.count do append edgeRotZ 0.0
        while edgeOffsets.count<patternLines.count do append edgeOffsets 0.0
        while edgeAlong.count<patternLines.count do append edgeAlong 0.0
        while edgeAcross.count<patternLines.count do append edgeAcross 0.0
        while strokeSides.count<patternLines.count do append strokeSides 1
        for n in patternLines where isValidNode n and findItem patternPaths n==0 do append patternPaths n
        while strokeModes.count<patternLines.count do append strokeModes 1
        while strokeMin.count<patternLines.count do append strokeMin 1.0
        while strokeMax.count<patternLines.count do append strokeMax 1.0
    )
    fn addStroke path side:1 = (
        syncStrokes()
        append patternLines path;append patternWidths (units.decodeValue "1m")
        local key=if sources.count>0 then colorKey(sourceColor 1) else 0
        append strokeSides side;append patternGroups key;append strokeModes 1;append strokeMin 1.0;append strokeMax 1.0
        syncStrokes();dirty=true;patternLines.count
    )
    fn removeStroke row = (
        for pair in #(#strokeColorRows,#strokeSourceRows) do (
            local rows=getProperty this pair
            local values=getProperty this (if pair==#strokeColorRows then #strokeColorKeys else #strokeSourceNodes)
            for i=rows.count to 1 by -1 do (
                if rows[i]==row then (deleteItem rows i;deleteItem values i)
                else if rows[i]>row do rows[i]-=1
            )
        )
        for key in #(#edgeRotX,#edgeRotY,#edgeRotZ,#edgeOffsets,#edgeAlong,#edgeAcross,#strokeSides,#patternLines,#patternWidths,#patternGroups,#strokeModes,#strokeMin,#strokeMax) do deleteItem (getProperty this key) row
        dirty=true
    )
    fn setStrokeSelection row mode values = (
        local rows=if mode==1 then strokeColorRows else strokeSourceRows
        local targets=if mode==1 then strokeColorKeys else strokeSourceNodes
        for i=rows.count to 1 by -1 where rows[i]==row do (deleteItem rows i;deleteItem targets i)
        for value in values do (append rows row;append targets value)
        if mode==1 do patternGroups[row]=if values.count>0 then values[1] else -1
        dirty=true
    )
    fn streetEdgeMask path = (
        if not isProperty path #streetVertices do throw "Update Surface Analyzer to use Street Side."
        local edges=path.packedLines path.streetVertices path.streetCounts,flags=#()
        for loop in (path.packedLines path.boundaryVertices path.boundaryCounts) do for i=1 to loop.count do (
            local a=loop[i],b=loop[if i==loop.count then 1 else i+1],keep=false
            for edge in edges where edge.count==2 do (
                if ((distance a edge[1]<.00001 and distance b edge[2]<.00001) or (distance a edge[2]<.00001 and distance b edge[1]<.00001)) do keep=true
            )
            append flags keep
        )
        flags
    )
    parameters activationSettings (
        cyrusEnabled type:#boolean default:true
        on cyrusEnabled set v do (dirty=true;CyrusViewportRedraw())
    )
    fn analyzerOff n = (isValidNode n and isProperty n #cyrusEnabled and not n.cyrusEnabled)
    fn disabledAnalyzerInput = (
        (diversityMode==4 and analyzerOff analyzerNode) or
        ((areaUseLine or areaUsePoints) and analyzerOff areaAnalyzer) or
        ((fallDelete or fallScale or fallDensity) and analyzerOff fallAnalyzer)
    )
    parameters streetLayoutSettings (
        streetTrimStart type:#worldunits default:0
        streetTrimEnd type:#worldunits default:0
        centerStreetOffset type:#worldunits default:0
        on streetTrimStart set v do dirty=true
        on streetTrimEnd set v do dirty=true
        on centerStreetOffset set v do dirty=true
    )
    fn centerStreetPaths analyzer = (
        local paths=analyzer.packedLines analyzer.pathVertices analyzer.pathCounts
        if centerStreetOffset==0 then paths else (
            local streets=analyzer.packedLines analyzer.streetVertices analyzer.streetCounts
            if streets.count==0 do throw "Center Line offset: Analyzer has no Street Side."
            for path in paths collect (for p in path collect (
                local nearest=undefined,best=1e30
                for edge in streets do for j=1 to edge.count-1 do (
                    local a=edge[j],b=edge[j+1],v=[b.x-a.x,b.y-a.y,0],d=dot v v
                    if d>0 do (
                        local q=a+v*(amax 0.0 (amin 1.0 (dot ([p.x-a.x,p.y-a.y,0]) v/d)))
                        local delta=[p.x-q.x,p.y-q.y,0],ds=dot delta delta
                        if ds<best do (best=ds;nearest=delta)
                    )
                )
                if nearest==undefined or best<1e-12 then p else p+(normalize nearest)*centerStreetOffset
            ))
        )
    )
    fn trimmedStreetData analyzer = (
        local loops=analyzer.packedLines analyzer.boundaryVertices analyzer.boundaryCounts
        local flags=streetEdgeMask analyzer
        if streetTrimStart==0 and streetTrimEnd==0 then #(loops,flags) else (
            local output=#(),mask=#(),offset=0
            for loop in loops do (
                local n=loop.count,lens=#(),selected=#(),verts=#()
                for i=1 to n do (append lens (distance loop[i] loop[if i==n then 1 else i+1]);append selected flags[offset+i])
                local allSelected=(findItem selected false)==0
                for i=1 to n do (
                    local a=loop[i],b=loop[if i==n then 1 else i+1],len=lens[i],cuts=#(0.0,1.0),before=0.0,total=len
                    if selected[i] and not allSelected and len>1e-9 do (
                        local j=if i==1 then n else i-1
                        while selected[j] and j!=i do (before+=lens[j];j=if j==1 then n else j-1)
                        total+=before;j=if i==n then 1 else i+1
                        while selected[j] and j!=i do (total+=lens[j];j=if j==n then 1 else j+1)
                        for d in #(streetTrimStart,total-streetTrimEnd) do (
                            local t=(d-before)/len
                            if t>0.000001 and t<0.999999 and findItem cuts t==0 do append cuts t
                        )
                        sort cuts
                    )
                    for k=1 to cuts.count-1 do (
                        append verts (a+(b-a)*cuts[k])
                        local along=before+len*(cuts[k]+cuts[k+1])*0.5
                        append mask (selected[i] and (allSelected or (along>=streetTrimStart and along<=total-streetTrimEnd)))
                    )
                )
                append output verts;offset+=n
            )
            #(output,mask)
        )
    )

    fn lineInputs plants previewOnly:false = (
        if diversityMode!=3 and diversityMode!=4 then #(false,0,#()) else (
            syncStrokes()
            if diversityMode==4 and not isValidNode analyzerNode do throw "Pick a Surface Analyzer."
            local keys=for n in plants collect colorKey(sourceColor(sourceRow n))
            local rest=0 -- retained wire format; outside strokes is always empty
            local bands=#();local paths=#();local totals=#()
            for i=1 to patternLines.count where isValidNode patternLines[i] and (if diversityMode==4 then patternLines[i]==analyzerNode else not isProperty patternLines[i] #samplePoints) do (
                local path=patternLines[i];local pathIndex=findItem paths path
                if pathIndex==0 do (append paths path;append totals #(0.0,0.0,0.0,0.0,0.0,0.0,0.0);pathIndex=paths.count)
                local side=strokeSides[i]
                local start=totals[pathIndex][side]
                totals[pathIndex][side]+=patternWidths[i]
                local choices=#()
                if strokeModes[i]==1 then (
                    local groups=for j=1 to strokeColorRows.count where strokeColorRows[j]==i collect strokeColorKeys[j]
                    if groups.count==0 do groups=#(patternGroups[i])
                    choices=for j=1 to plants.count where findItem groups keys[j]>0 collect j
                ) else (
                    for j=1 to strokeSourceRows.count where strokeSourceRows[j]==i do (
                        local k=findItem plants strokeSourceNodes[j]
                        if k>0 and findItem choices k==0 do append choices k
                    )
                )
                if previewOnly and plants.count==0 do choices=#(1)
                if choices.count==0 do throw ("Stroke "+(i as string)+": select a color group or Source Object.")
                if diversityMode==4 then (
                    local data=case side of (
                        1: (path.packedLines path.boundaryVertices path.boundaryCounts)
                        2: (path.packedLines path.boundaryVertices path.boundaryCounts)
                        6: (path.packedLines path.boundaryVertices path.boundaryCounts)
                        7: (path.packedLines path.boundaryVertices path.boundaryCounts)
                        3: (centerStreetPaths path)
                        default: (#(path.samplePoints as array))
                    )
                    local mask=if side==6 then streetEdgeMask path else if (side<=2 or side==7) and isProperty path #includeStreetBoundary then path.boundaryEdgeMask() else #()
                    if side==6 do (local trimmed=trimmedStreetData path;data=trimmed[1];mask=trimmed[2])
                    append bands #(data,(if side==7 then patternWidths[i] else totals[pathIndex][side]),rest,choices,strokeMin[i],strokeMax[i],(side==2 or side==6),(if side==7 then 6 else if side==6 then 2 else side),(if side==7 then 0 else start),mask,(side==6 and streetStraight),#((if side==7 then edgeFaceOut else if side==6 then streetFaceOut else if side<=2 then borderFaceOut else false),(if side==7 then edgeCornerRadius else if side==6 then streetCornerRadius else borderCornerRadius)),#(edgeOffsets[i],edgeAlong[i],edgeAcross[i],edgeKeepCorners,edgeCornerAngle,edgeCornerCount,edgeRotX[i],edgeRotY[i],edgeRotZ[i]))
                ) else append bands #(path,totals[pathIndex][side],rest,choices,strokeMin[i],strokeMax[i],side==2)
            )
            #(true,rest,bands)
        )
    )


    local blockerCacheKey="",blockerCacheRows=#(),blockerCacheBuilds=0,blockerCacheHits=0
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
        local key=(stream as string)+"|Brush:"+this.paintKey()+":"+(paintEnabled as string)+":"+(paintDensity as string)
        if key!=blockerCacheKey then (
            blockerCacheRows=this.placements plants previewOnly:showCenters rawOnly:true
            blockerCacheKey=key;blockerCacheBuilds+=1
        ) else blockerCacheHits+=1
        blockerCacheRows
    )
    fn blockerCacheStats = (#(blockerCacheBuilds,blockerCacheHits))
    fn filterSourceRowsByPolicy rows keep = (
        if cyrusFilterSourceRows!=undefined then cyrusFilterSourceRows rows keep
        else (for row in rows where keep[row[2]] collect row)
    )
    fn cspImpl_placements plants previewOnly:false rawOnly:false finalPass:undefined = (
        if not cyrusEnabled or disabledAnalyzerInput() do return #()
        -- Keep saved Relax settings, but pause movement while a Brush mask is active.
        local pointRelax=relaxEnabled and not this.brushMaskActive(),boundaryRelax=finalRelax and not this.brushMaskActive()
        if this.brushMaskActive() and not projectMove and (movXMin!=0 or movXMax!=0 or movYMin!=0 or movYMax!=0 or movZMin!=0 or movZMax!=0 or movementRange!=0) do throw "Brush requires projected movement."
        local targets=validSurfaces()
        if targets.count==0 do throw "Add at least one scatter surface."
        if plants.count==0 and not previewOnly do throw "Add a plant mesh."
        local sourceCount=amax 1 plants.count
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
        local baseKey=if paintIdentity and distributionMode!=3 and finalPass==undefined then this.paintBaseInputKey plants previewOnly else undefined
        local result=undefined
        if baseKey!=undefined and baseKey==paintBaseKey and paintBaseRows!=undefined then (
            result=paintBaseRows;paintBaseHits+=1
        ) else (
        result=if not paintIdentity and distributionMode!=3 and finalPass==undefined and sourceWeights.count==0 and not collisionEnabled and not pointRelax and not advancedAxes and areas[1].count==0 and targets.count==1 and populationMode==1 and diversityMode<3 then (
            aminScatterTransforms targets[1] requestedCount randomSeed sourceCount scaleMinimum scaleMaximum [-tiltDegrees,-tiltDegrees,yawMinimum] [tiltDegrees,tiltDegrees,yawMaximum] [movementRange,movementRange,movementRange] alignNormal
        ) else (
            local groups=if plants.count==0 then #(0) else (for n in plants collect (colorKey (sourceColor (sourceRow n))))
            local generate=if paintIdentity then cyrusScatterAdvanced else aminScatterAdvanced
            local nativeOptions=if paintIdentity then #(paintIdentity,not advancedAxes,scaleMinimum,scaleMaximum,tiltDegrees,yawMinimum,yawMaximum,movementRange) else undefined
            if paintIdentity then (generate targets requestedCount randomSeed sourceCount [sclXMin,sclYMin,sclZMin] [sclXMax,sclYMax,sclZMax] [rotXMin,rotYMin,rotZMin] [rotXMax,rotYMax,rotZMax] [movXMin,movYMin,movZMin] [movXMax,movYMax,movZMax] alignNormal projectMove (distributionMode-1) clusterCount clusterRadius weights 128 groups (diversityMode==2) diversitySize diversitySeed (roughness/100.0) (blurryEdge/100.0) (diversityNoise/100.0) areas[1] areas[2] (populationMode==2) (lineInputs plants previewOnly:previewOnly) #(collisionEnabled,collisionRadius,pointRelax,relaxSpacing,relaxIterations,relaxStrength) (if sourceWeights.count==0 or plants.count==0 then #() else (for n in plants collect sourceWeight (sourceRow n))) finalPass nativeOptions) else (generate targets requestedCount randomSeed sourceCount [sclXMin,sclYMin,sclZMin] [sclXMax,sclYMax,sclZMax] [rotXMin,rotYMin,rotZMin] [rotXMax,rotYMax,rotZMax] [movXMin,movYMin,movZMin] [movXMax,movYMax,movZMax] alignNormal projectMove (distributionMode-1) clusterCount clusterRadius weights 128 groups (diversityMode==2) diversitySize diversitySeed (roughness/100.0) (blurryEdge/100.0) (diversityNoise/100.0) areas[1] areas[2] (populationMode==2) (lineInputs plants previewOnly:previewOnly) #(collisionEnabled,collisionRadius,pointRelax,relaxSpacing,relaxIterations,relaxStrength) (if sourceWeights.count==0 or plants.count==0 then #() else (for n in plants collect sourceWeight (sourceRow n))) finalPass)
        )
        if finalPass!=undefined do return result
        if wholeScaleMin!=1.0 or wholeScaleMax!=1.0 do result=cyrusWholeScale result wholeScaleMin wholeScaleMax randomSeed
        result=applyAnalyzerArea result
        result=applyFalloff result

            if baseKey!=undefined do (paintBaseRows=result;paintBaseKey=baseKey;paintBaseBuilds+=1)
        )
        result=this.applyPaint result
        if plants.count>0 and sourceEmpty.count>0 do (
            local keep=for n in plants collect (not (isEmptySource (sourceRow n)) or isPointSource (sourceRow n))
            result=filterSourceRowsByPolicy result keep
        )
        if plants.count>0 and (sourceZOffsets.count>0 or sourceScales.count>0) do (
            local offsets=for n in plants collect sourceZOffset (sourceRow n)
            local scales=for n in plants collect sourceScale (sourceRow n)
            if cyrusApplySourceTransforms!=undefined then result=cyrusApplySourceTransforms result offsets scales
            else (
            for row in result do (
                local tm=row[1], k=row[2], factor=scales[k]
                tm.row1=tm.row1*factor;tm.row2=tm.row2*factor;tm.row3=tm.row3*factor
                tm.row4=tm.row4+[0,0,offsets[k]]
                row[1]=tm
            )
            )
        )
        if not rawOnly do (
            local obstacles=#(),obstacleRadii=#()
            overlapBefore=result.count
            if overlapEnabled and overlapOwner!=undefined and (overlapSourceRadius or overlapRadius+overlapGap>0) do (

                for idx in overlapBlockers where idx>0 and idx<=overlapOwner.layerObjects.count do (
                    local blocker=overlapOwner.layerObjects[idx]
                    if blocker!=this and overlapOwner.layerEnabled[idx] do (
                        overlapOwner.syncLayerSurface blocker
                        local src=blocker.validSources()
                        if src.count>0 or blocker.showCenters do (
                            local blocked=blocker.cachedBlockerRows src
                            join obstacles blocked
                            if overlapSourceRadius do join obstacleRadii (if src.count>0 then blocker.placementRadii blocked src else (for row in blocked collect 0.0))
                        )
                    )
                )
                result=if overlapSourceRadius then (
                    local ownRadii=if plants.count>0 then placementRadii result plants else (for row in result collect 0.0)
                    cyrusRemoveOverlaps result obstacles overlapGap overlapPlanar ownRadii obstacleRadii
                ) else cyrusRemoveOverlaps result obstacles (overlapRadius+overlapGap) overlapPlanar
            )
            overlapAfter=result.count
            if (finalCleanup or boundaryRelax) and result.count>0 do (
                local own=if overlapSourceRadius and plants.count>0 then placementRadii result plants else (for row in result collect 0.0)
                if not overlapSourceRadius do obstacleRadii=for row in obstacles collect 0.0
                local gap=if overlapEnabled then (if overlapSourceRadius then overlapGap else overlapRadius+overlapGap) else 0.0
                result=this.placements plants previewOnly:previewOnly finalPass:#(result,obstacles,own,obstacleRadii,finalCleanup,finalNeighborRadius,finalMinNeighbors,finalMinIsland,boundaryRelax,finalStrength,finalIterations,finalMaxMove,gap,overlapPlanar)
            )
            overlapAfter=result.count
        )
        if not rawOnly and diversityMode==4 and (borderFaceOut or streetFaceOut or (findItem strokeSides 7>0)) and result.count>0 do (
            local forward=if plants.count==0 then #(1) else for n in plants collect sourceForward (sourceRow n)
            local offsets=if plants.count==0 then #(0.0) else for n in plants collect sourceZOffset (sourceRow n)
            result=cyrusOrientRows result (lineInputs plants previewOnly:true) forward offsets
        )
        if not rawOnly do result=CyrusEditApplyLayer overlapOwner this result
        if not previewOnly and not rawOnly and plants.count>0 do (
            local keep=for n in plants collect (not (isPointSource (sourceRow n)))
            result=filterSourceRowsByPolicy result keep
        )
        result
    )
    fn pointSourceSamples n = (
        local result=undefined,reason=""
        try(result=aminScatterSourcePoints n pointsPerPlant randomSeed)catch(reason=getCurrentException())
        if reason!="" do throw ("Point Cloud source "+n.name+": "+reason)
        result
    )
    local uiPreviewMode=0
    fn uiLayerStats = (
        CyrusLayerStatusData hasResult:(cachedPoints!=undefined and previewError=="") placements:generatedCount previewCount:cachedPointCount mode:uiPreviewMode buildMs:previewBuildMs needsUpdate:dirty errorText:previewError densityCapped:densityCapped inputOff:(disabledAnalyzerInput())
    )
    fn uiVersion = "1.0.1"
    fn placements plants previewOnly:false rawOnly:false finalPass:undefined = (
        local token=undefined
        if CyrusPerfTraceBegin!=undefined do try(token=CyrusPerfTraceBegin this "placements")catch()
        try (
            local answer=cspImpl_placements plants previewOnly:previewOnly rawOnly:rawOnly finalPass:finalPass
            if token!=undefined and CyrusPerfTraceEnd!=undefined do try(CyrusPerfTraceEnd token #("",answer.count,previewOnly,rawOnly,finalPass!=undefined))catch()
            answer
        )catch(
            if token!=undefined and CyrusPerfTraceEnd!=undefined do try(CyrusPerfTraceEnd token ("EXCEPTION: "+getCurrentException()))catch()
            throw()
        )
    )
    fn cspImpl_refreshPreview = (
        local buildStarted=timeStamp()
        previewBuildCount+=1
        radiusPreview=#();cachedPoints=undefined;cachedPointCount=0;previewError="";generatedCount=0
        try (
            local plants=validSources()
            local data=placements plants previewOnly:true
            generatedCount=data.count;cacheRadii data plants
            local samples=if viewportMode!=1 then #() else if showCenters then (for i=1 to (amax 1 plants.count) collect #([0,0,0])) else (for n in plants collect (if classof n==Integer then (for p=1 to pointsPerPlant collect [0,0,0]) else pointSourceSamples n))
            local colors=if plants.count==0 then #(solidPointColor) else (for n in plants collect (sourceColor (sourceRow n)))
            cachedPoints=if viewportMode==1 then aminScatterBuildPreview data samples colors (if showCenters then 500000 else previewBudget) else cyrusBuildGeometryPreview data (if plants.count==0 then #(-1) else plants) colors (if viewportMode==2 then proxyShape else 4) viewportInstances viewportFaces
            cachedPointCount=aminScatterPreviewCount cachedPoints
            uiPreviewMode=viewportMode
        ) catch (previewError=getCurrentException();cachedPoints=undefined;cachedPointCount=0)
        dirty=false
        cachedAreaAnalyzerRun=if isValidNode areaAnalyzer then areaAnalyzer.getAnalysisRuns() else -1
        cachedFallRun=if isValidNode fallAnalyzer then fallAnalyzer.getAnalysisRuns() else -1
        cachedAnalyzerRun=if diversityMode==4 and isValidNode analyzerNode then analyzerNode.getAnalysisRuns() else -1
        previewBuildMs=timeStamp()-buildStarted
        cachedPointCount
    )
    fn refreshPreview = (
        local token=undefined
        if CyrusPerfTraceBegin!=undefined do try(token=CyrusPerfTraceBegin this "preview_rebuild")catch()
        try (
            local answer=cspImpl_refreshPreview()
            if token!=undefined and CyrusPerfTraceEnd!=undefined do try(CyrusPerfTraceEnd token #(previewError,generatedCount,cachedPointCount,previewBuildCount))catch()
            answer
        )catch(
            if token!=undefined and CyrusPerfTraceEnd!=undefined do try(CyrusPerfTraceEnd token ("EXCEPTION: "+getCurrentException()))catch()
            throw()
        )
    )
    fn checkAnalyzerRevision = (
        if updateMode==2 and isValidNode areaAnalyzer and (areaUseLine or areaUsePoints) do if cachedAreaAnalyzerRun!=areaAnalyzer.getAnalysisRuns() do dirty=true
        if updateMode==2 and isValidNode fallAnalyzer and (fallDelete or fallScale or fallDensity) do if cachedFallRun!=fallAnalyzer.getAnalysisRuns() do dirty=true
        if updateMode==2 and diversityMode==4 do (
            local revision=if isValidNode analyzerNode then analyzerNode.getAnalysisRuns() else -1
            if revision!=cachedAnalyzerRun do dirty=true
        )
    )
    local cachedDisabledInput=false,cachedDisabledPreview=undefined
    fn previewCache interactionHeld:undefined = (
        local held=if interactionHeld==undefined then CyrusInteractionHeld() else interactionHeld
        if held do (CyrusWasDragging=true;return cachedPoints)
        local inputOff=disabledAnalyzerInput()
        if inputOff!=cachedDisabledInput do (dirty=true;cachedDisabledInput=inputOff)
        if inputOff do (
            if cachedDisabledPreview==undefined do cachedDisabledPreview=aminScatterBuildPreview #() #() #() 1
            return cachedDisabledPreview
        )
        checkAnalyzerRevision()
        if dirty and (updateMode==2 or previewBuildCount==0) do refreshPreview()
        cachedPoints
    )
    fn previewPoints = (
        local cache=previewCache()
        if cache==undefined then #() else aminScatterPreviewPoints cache
    )
    fn previewStats = (#(previewBuildCount,previewBuildMs,cachedPointCount))
    fn statusText = (
        if previewError!="" then previewError else (generatedCount as string)+" / "+(requestedCount as string)+" plants; "+(cachedPointCount as string)+(if viewportMode==1 then " points" else " shown instances")+(if densityCapped then " (density capped at 100000)" else "")
    )
    parameters layerSettings (
        layerID type:#string default:""
        layerVisible type:#boolTab tabSize:0 tabSizeVariable:true
        on layerVisible set value index do (global CyrusPointPending;CyrusPointPending=true)
        layerObjects type:#maxObjectTab tabSize:0 tabSizeVariable:true
        layerNames type:#stringTab tabSize:0 tabSizeVariable:true
        layerEnabled type:#boolTab tabSize:0 tabSizeVariable:true
        on layerEnabled set v i do (for layer in layerObjects do layer.dirty=true)
        activeLayer type:#integer default:1
    )
    fn setLayerTransfer state = (layerTransfer=state)
    fn performanceTraceVersion = 1
    fn cacheSnapshot = (#(cachedPoints,cachedPointCount,dirty,previewError,generatedCount,previewBuildCount,previewBuildMs,requestedCount,densityCapped))
    fn restoreCache state = (
        uiPreviewMode=0
        cachedPoints=state[1];cachedPointCount=state[2];dirty=state[3];previewError=state[4]
        generatedCount=state[5];previewBuildCount=state[6];previewBuildMs=state[7]
        requestedCount=state[8];densityCapped=state[9]
    )
    fn forcePreviewUpdate = (dirty=true;previewBuildCount=0)
    fn ensureLayers = layerObjects.count
    fn syncLayerSurface obj targets:undefined layerBudget:undefined = (
        obj.setOverlapOwner this
        if targets==undefined do targets=validSurfaces()
        local equal=obj.surfaceNodes.count==targets.count
        if equal do for i=1 to targets.count where obj.surfaceNodes[i]!=targets[i] do equal=false
        if not equal do undo off (obj.surfaceNodes=targets;obj.surface=undefined)
        if layerBudget==undefined do (
            local enabledCount=(for flag in layerEnabled where flag collect flag).count
            layerBudget=amax 1 (floor(previewBudget/(amax 1 enabledCount)))
        )
        if obj.previewBudget!=layerBudget do undo off obj.previewBudget=layerBudget
        -- These settings belong to the controller, not an individual layer.
        undo off for key in #(#viewportMode,#proxyShape,#viewportInstances,#viewportFaces,#radiusDisplayLimit,#radiusDisplayAll,#updateMode,#showPoints,#pointsPerPlant,#pointColorMode,#solidPointColor,#autoRender) do (
            if getProperty obj key != getProperty this key do setProperty obj key (getProperty this key)
        )
    )
    local editCacheKey=""
    fn layerEntries includeDisabled:false = (
        local key=CyrusEditStackKey this
        if key!=editCacheKey do (
            editCacheKey=key
            for layer in layerObjects do layer.forcePreviewUpdate()
        )
        local entries=#(),targets=validSurfaces()
        local enabledCount=(for flag in layerEnabled where flag collect flag).count
        local layerBudget=amax 1 (floor(previewBudget/(amax 1 enabledCount)))
        for i=1 to layerObjects.count where includeDisabled or (cyrusEnabled and layerEnabled[i]) do (
            local obj=layerObjects[i]
            syncLayerSurface obj targets:targets layerBudget:layerBudget
            obj.checkAnalyzerRevision();obj.checkPaintRevision()
            append entries #(i,obj)
        )
        if (for e in entries where layerEnabled[e[1]] and e[2].dirty collect e).count>0 do
            for e in entries where layerEnabled[e[1]] and e[2].overlapEnabled do e[2].dirty=true
        entries
    )
    fn viewportLayerEntries held = (
        if not held do return (for entry in layerEntries() where this.visibleLayer entry[1] collect entry)
        for i=1 to layerObjects.count where cyrusEnabled and layerEnabled[i] and this.visibleLayer i collect #(i,layerObjects[i])
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
        if CyrusBrushSessionLayer!=undefined do CyrusStopBrush()
        activeLayer=i
    )
    fn newLayer = (
        this.syncLayerIdentity()
        if layerObjects.count>=10 do throw "A scatter controller supports up to 10 layers."
        undo "Cyrus Scatter add layer" on (
            local obj=createInstance AminScatterObject
            obj.editLayerKey=nextEditLayerKey;nextEditLayerKey+=1
            obj.randomSeed=42+layerObjects.count*101
            append layerObjects obj
            local number=1;local label=""
            do (label="Layer_"+(formattedPrint number format:"02d");number+=1) while findItem layerNames label>0
            obj.layerID=CyrusNewLayerID()
            append layerNames label;append layerEnabled true;append layerVisible true
            activeLayer=layerObjects.count
            syncLayerSurface obj
        )
        activeLayer
    )
    fn removeLayer = (
        if CyrusBrushSessionLayer!=undefined do CyrusStopBrush()
        if layerObjects.count>0 and activeLayer>0 do (
            if (for n in layerObjects[activeLayer].bakedNodes where isValidNode n collect n).count>0 do throw "Remove this layer's baked output first."
            undo "Cyrus Scatter remove layer" on (
                local i=activeLayer
                -- Remap surviving indices on deletion.
                for layer in layerObjects do (
                    layer.overlapBlockers=for k in layer.overlapBlockers where k!=i collect (if k>i then k-1 else k)

                    layer.dirty=true
                )
                deleteItem layerObjects i;deleteItem layerNames i;deleteItem layerEnabled i
                if i<=layerVisible.count do deleteItem layerVisible i
                activeLayer=amin i layerObjects.count
            )
        )
        activeLayer
    )
    fn refreshDisplay = (
        for entry in (layerEntries()) do entry[2].refreshPreview()
        CyrusViewportRedraw()
    )
    fn refreshAll = (
        global CyrusPFManualRevision; if CyrusPFManualRevision!=undefined do CyrusPFManualRevision+=1
        for entry in (layerEntries()) do entry[2].refreshPreview()
        CyrusViewportRedraw()
    )
    fn allStatus = (
        local plants=0;local points=0;local errors=0
        for entry in (layerEntries()) do (
            local state=entry[2].cacheSnapshot()
            plants+=state[5];points+=state[2];if state[4]!="" do errors+=1
        )
        (layerObjects.count as string)+" layers; "+(plants as string)+" plants; "+(points as string)+(if viewportMode==1 then " points" else " shown instances (display limits apply)")+(if errors>0 then "; "+(errors as string)+" layer(s) have a preview error" else "")+(if CyrusPointLastError!="" then "; native preview fallback" else "")
    )
    fn clearAllBaked = (
        local owners=refs.dependentNodes this
        if owners.count==1 do for entry in (layerEntries includeDisabled:true) do entry[2].clearBaked owners[1]
        autoRender=true;showPoints=true;CyrusViewportRedraw()
    )

    fn clearBaked ownerNode = (
        local key=ownerNode.handle as string
        undo "Cyrus Scatter remove baked output" on (
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
        undo "Cyrus Scatter build" on (
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
    -- Native rollups: one editor per controller, bound to the selected layer.
    -- UI browsing never rebuilds a rollout or a placement cache.
    fn brushMaskActive = (paintIdentity and paintEnabled and paintDocument!=undefined)
    fn brushRelaxPaused = (this.brushMaskActive() and (relaxEnabled or finalRelax))
    fn checkPaintRevision = (
        if paintDocument!=undefined do (
            local state=cyrusBrushStats paintDocument
            if state[6]==0 and state[1]!=cachedPaintRevision do (cachedPaintRevision=state[1];dirty=true)
        )
    )
    fn paintKey = (
        if paintDocument==undefined then "none" else ((getHandleByAnim paintDocument as string)+":"+((cyrusBrushStats paintDocument)[1] as string))
    )
    fn applyPaint rows = (
        if not paintIdentity do return rows
        if paintSignatureRows!=rows do (
            -- Ownership GUIDs must not change probabilistic mask acceptance on Copy Layer.
            paintPopulation=cyrusEditFingerprint rows ((randomSeed as string)+"|"+(diversitySeed as string))
            paintSignatureRows=rows
        )
        if not paintEnabled or paintDocument==undefined do return (cyrusClonePlacementRows rows)
        local result=cyrusBrushFilter paintDocument rows paintPopulation paintDensity
        cachedPaintRevision=(cyrusBrushStats paintDocument)[1]
        result
    )
    fn paintBaseInputKey plants previewOnly = (
        local stream=stringStream ""
        with printAllElements on (
            format "%|%|%|%|%|" currentTime CyrusPFRevision CyrusPFManualRevision plants previewOnly to:stream
            format "EffectiveRelax:%|" (relaxEnabled and not this.brushMaskActive()) to:stream
            for key in AminScatterLayerFields where findItem #(#paintDocument,#paintEnabled,#paintIdentity,#paintDensity,#bakedNodes,#showPoints,#pointsPerPlant,#updateMode,#autoRender,#previewBudget,#pointColorMode,#solidPointColor) key==0 do format "%:%|" key (getProperty this key) to:stream
            for n in (this.validSurfaces()+(sources as array)+(areaNodes as array)+(patternLines as array)+#(analyzerNode,areaAnalyzer,fallAnalyzer)) where isValidNode n do format "%:%|" (getHandleByAnim n) n.objectTransform to:stream
            for n in #(analyzerNode,areaAnalyzer,fallAnalyzer) where isValidNode n do format "%|" (n.getAnalysisRuns()) to:stream
            format "%|%|%|%|%|%|%|%|" strokeSides strokeModes strokeColorRows strokeColorKeys strokeSourceRows strokeSourceNodes strokeMin strokeMax to:stream
        )
        stream as string
    )
    fn paintCacheStats = (#(paintBaseBuilds,paintBaseHits,if paintBaseRows==undefined then 0 else paintBaseRows.count))
    fn publishPaint = (
        checkPaintRevision()
        if this.mainUI.controlsReady do this.mainUI.refreshStats()
        CyrusViewportRedraw()
    )

    fn resetRandomization group = (
        local values=case group of (
            #rotation: #(#(#rotXMin,0.0),#(#rotXMax,0.0),#(#rotYMin,0.0),#(#rotYMax,0.0),#(#rotZMin,0.0),#(#rotZMax,0.0),#(#tiltDegrees,0.0),#(#yawMinimum,0.0),#(#yawMaximum,0.0))
            #scale: #(#(#sclXMin,1.0),#(#sclXMax,1.0),#(#sclYMin,1.0),#(#sclYMax,1.0),#(#sclZMin,1.0),#(#sclZMax,1.0),#(#scaleMinimum,1.0),#(#scaleMaximum,1.0))
            #wholeScale: #(#(#wholeScaleMin,1.0),#(#wholeScaleMax,1.0))
            #movement: #(#(#movXMin,0.0),#(#movXMax,0.0),#(#movYMin,0.0),#(#movYMax,0.0),#(#movZMin,0.0),#(#movZMax,0.0),#(#movementRange,0.0))
            default: undefined
        )
        if values==undefined do return false
        local priorTransfer=layerTransfer
        layerTransfer=true
        try (for row in values do setProperty this row[1] row[2]) catch(layerTransfer=priorTransfer;throw())
        layerTransfer=priorTransfer;dirty=true;true
    )
    fn resetSelectedRandomization group = (
        local layer=this.selectedLayer()
        if layer==undefined do return false
        local caption=case group of (#rotation:"Cyrus reset rotation";#scale:"Cyrus reset XYZ scale";#wholeScale:"Cyrus reset whole scale";#movement:"Cyrus reset movement";default:undefined)
        if caption==undefined do return false
        undo caption on layer.resetRandomization group
        if this.randomUI.controlsReady do this.randomUI.bind layer
        if this.mainUI.controlsReady do this.mainUI.refreshStats()
        CyrusViewportRedraw();true
    )
    fn selectedLayer = (
        if activeLayer>0 and activeLayer<=layerObjects.count then layerObjects[activeLayer] else undefined
    )
    fn syncLayerIdentity = (
        undo off (
            while layerVisible.count<layerObjects.count do append layerVisible true
            while layerVisible.count>layerObjects.count do deleteItem layerVisible layerVisible.count
            for i=1 to layerObjects.count do (
                local layer=layerObjects[i]
                if layer.layerID=="" or layer.layerID=="dotNetObject:System.Guid" do layer.layerID=CyrusNewLayerID()
                if layer.editLayerKey==0 do layer.editLayerKey=i
                nextEditLayerKey=amax nextEditLayerKey (layer.editLayerKey+1)
            )
        )
    )
    fn visibleLayer i = (i>0 and i<=layerObjects.count and (i>layerVisible.count or layerVisible[i]))
    fn copySelectedLayer = (
        local origin=selectedLayer()
        if origin==undefined do return false
        local label=layerNames[activeLayer]
        undo "Cyrus copy layer" on (
            newLayer()
            local destination=selectedLayer()
            AminScatterCopyLayer origin destination
            destination.bakedNodes=#()
            layerNames[activeLayer]=label+" copy"
        )
        this.bindNativeUI();CyrusViewportRedraw()
    )
    fn bindNativeUI = (
        if this.mainUI.controlsReady do this.mainUI.bind()
        local layer=selectedLayer()
        for r in this.nativeEditors() where r.controlsReady do r.bind layer
        true
    )
    fn syncBrushCompatibility = (
        if this.spacingUI.controlsReady do this.spacingUI.syncRelaxAvailability()
        if this.separationUI.controlsReady do this.separationUI.syncFinalRelaxAvailability()
    )
    rollout mainUI "Cyrus Scatter 1.0 | Layers" width:#cmdPanel (
        local controlsReady=false,binding=false,dpiScale=1.0,lastRows=#()
        checkbox enabledCheck "Enable Cyrus Scatter" pos:[8,8] width:146
        listbox layerList "Layer / placed / state" items:#() pos:[8,34] width:146 height:7
        button addButton "Add" pos:[8,190] width:46 tooltip:"Create a new procedural layer."
        button copyButton "Copy" pos:[58,190] width:46 tooltip:"Copy settings and an independent Brush history into a new layer."
        button removeButton "Remove" pos:[108,190] width:46
        edittext nameEdit "Name:" pos:[8,222] width:146
        checkbox visibleCheck "Visible in viewport" pos:[8,250] width:146 tooltip:"Hides this layer's preview. Cached placement and final rendering are preserved."
        checkbox renderCheck "Enabled in final output" pos:[8,276] width:146 tooltip:"Disables this layer's placement, final rendering and blocking of other layers."
        label countInfo "No layer selected." pos:[8,306] width:146 height:76
        label countHelp "Counts show the last build.\nStale = Update is needed." pos:[8,387] width:146 height:36
        button helpButton "Layer details / help" pos:[8,430] width:146
        timer statusTimer interval:1000 active:false
        fn layoutPanels = true -- Native Max owns rollup sizing and expansion.
        fn refreshTitles = true
        fn refreshStats = (
            if not controlsReady or binding do return false
            local rows=#(),detail="No layer selected."
            for i=1 to layerObjects.count do (
                local layer=layerObjects[i],state=layer.uiLayerStats()
                local status=CyrusUILayerState state layerEnabled[i] cyrusEnabled (visibleLayer i and (layer.showPoints or layer.showCenters))
                append rows (layerNames[i]+" | "+(if state.hasResult then CyrusUICount state.placements compact:true else "--")+" | "+status[1])
                if i==activeLayer do (
                    detail=status[2]+"\nPlaced: "+(if state.hasResult then CyrusUICount state.placements else "--")
                    detail+="\n"+(if state.mode==1 then "Preview points: " else "Preview instances: ")+(if state.hasResult then CyrusUICount state.previewCount else "--")
                    detail+="\nBuild: "+(if state.hasResult then (state.buildMs as string)+" ms" else "--")
                    if layer.brushRelaxPaused() do detail+="\nRelax paused by Brush."
                    if state.errorText!="" do detail+="\n"+state.errorText
                )
            )
            local rowsChanged=rows.count!=lastRows.count
            if not rowsChanged do for i=1 to rows.count where rows[i]!=lastRows[i] do rowsChanged=true
            if rowsChanged do (
                binding=true;layerList.items=rows;layerList.selection=activeLayer;lastRows=rows;binding=false
            )
            if countInfo.text!=detail do countInfo.text=detail
            this.syncBrushCompatibility()
            true
        )
        fn bind = (
            binding=true
            local valid=selectedLayer()!=undefined
            enabledCheck.checked=cyrusEnabled
            layerList.selection=activeLayer
            for c in #(removeButton,nameEdit,visibleCheck,renderCheck) do c.enabled=valid
            addButton.enabled=layerObjects.count<10
            copyButton.enabled=valid and layerObjects.count<10
            nameEdit.text=if valid then layerNames[activeLayer] else ""
            visibleCheck.checked=valid and visibleLayer activeLayer
            renderCheck.checked=valid and layerEnabled[activeLayer]
            binding=false;refreshStats()
        )
        fn rebuild = bindNativeUI()
        fn rebuildLayers = bindNativeUI()
        fn selectLayerView layer expand:false = (
            local i=findItem layerObjects layer
            if i>0 do selectLayer i
            bindNativeUI()
        )
        on mainUI open do (syncLayerIdentity();controlsReady=true;statusTimer.active=true;bind())
        on mainUI close do (controlsReady=false;statusTimer.active=false)
        on statusTimer tick do if mainUI.open and not CyrusInteractionHeld() do refreshStats()
        on layerList selected i do if not binding and i>0 do (selectLayer i;bindNativeUI())
        on enabledCheck changed value do if not binding do (undo "Cyrus Scatter enabled" on cyrusEnabled=value;CyrusViewportRedraw();bind())
        on visibleCheck changed value do if not binding and selectedLayer()!=undefined do (
            undo "Cyrus layer viewport visibility" on layerVisible[activeLayer]=value
            CyrusViewportRedraw();bind()
        )
        on renderCheck changed value do if not binding and selectedLayer()!=undefined do (
            undo "Cyrus layer output enabled" on layerEnabled[activeLayer]=value
            CyrusViewportRedraw();bind()
        )
        on nameEdit entered value do if not binding and selectedLayer()!=undefined and value!="" do (
            undo "Cyrus layer name" on layerNames[activeLayer]=value
            bindNativeUI()
        )
        on addButton pressed do (newLayer();syncLayerIdentity();bindNativeUI();CyrusViewportRedraw())
        on copyButton pressed do copySelectedLayer()
        on removeButton pressed do (removeLayer();bindNativeUI();CyrusViewportRedraw())
        on helpButton pressed do (
            local layer=selectedLayer(),message="Select a layer to edit its sources and settings.\nNative rollout headers open with one click.\n\nVisible in viewport hides only the cached preview.\nEnabled in final output controls generation, rendering and blockers.\nPlaced is the last generated count; Preview counts visible points or instances within the current display budget.\nLimited means the geometry preview displays a subset; check its instance/face budget.\nBuild is preview preparation time, not FPS.\nStale means settings changed and Update is needed.\n\nBrush: choose one static receiving mesh, then Paint or Erase. Count/density and randomization remain procedural. Manual mode publishes plants on Update.\nPainted density pauses Relax and Boundary Relax without changing their saved settings. Turn off Use painted density to use Relax. Collision and final cleanup remain available."
            if layer!=undefined do (message="Layer: "+layerNames[activeLayer]+"\n"+countInfo.text+"\n\n"+message;if layer.previewError!="" do message+="\n\nFull error:\n"+layer.previewError)
            messageBox message title:"Cyrus Scatter 1.0"
        )
    )

    fn nativeEditors = #(this.updateUI,this.surfaceUI,this.previewUI,this.sourceUI,this.distributionUI,this.areaUI,this.diversityUI,this.randomUI,this.spacingUI,this.separationUI,this.brushUI)
    rollout updateUI "Update" width:#cmdPanel (
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false


        radiobuttons updateRadio "Viewport update" labels:#("Manual","Real-time") columns:1 pos:[6,8] width:138
        button updateNow "Update now" pos:[6,78] width:138
        label updateHint "Updates after a brief pause." pos:[6,110] width:138
        fn syncControls = (updateRadio.state=obj.updateMode;)
        on updateNow pressed do if controlsReady and not binding and obj!=undefined do (obj.refreshAll();CyrusViewportRedraw())

        on updateRadio changed v do if controlsReady and not binding and obj!=undefined do (obj.updateMode=v;obj.dirty=true;syncControls();CyrusViewportRedraw())



        fn bind layer = (
            local next=this
            binding=true;controlsReady=false
            if obj!=next do ()
            obj=next;parentView=this.mainUI
            for c in updateUI.controls do c.enabled=true
            try (undo off ((updateRadio.state=obj.updateMode;controlsReady=true;))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        on updateUI open do (controlsReady=true;bind (selectedLayer()))
        on updateUI close do controlsReady=false
    )
    rollout surfaceUI "Surface Scatter" width:#cmdPanel (
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false

        multiListBox surfaceList "Surfaces (Ctrl/Shift)" items:#() pos:[6,8] width:138 height:6
        button addSurfaceScene "Select From Scene..." pos:[6,134] width:138
        pickbutton pickSurface "Add: pick surface" filter:AminScatterSourceFilter pos:[6,160] width:138
        button removeSurface "Remove selected rows" pos:[6,186] width:138
        fn updateSurfaces = (
            local rows=surfaceList.selection
            surfaceList.items=for n in obj.surfaceNodes collect (if isValidNode n then n.name else "<deleted>")
            surfaceList.selection=rows
        )
        fn addSurface n = (
            if AminScatterSourceFilter n and findItem obj.sources n==0 and findItem obj.surfaceNodes n==0 do (
                append obj.surfaceNodes n;obj.surface=undefined;obj.dirty=true
            )
        )

        on pickSurface picked n do if controlsReady and not binding and obj!=undefined do (addSurface n;updateSurfaces();CyrusViewportRedraw())
        on addSurfaceScene pressed do if controlsReady and not binding and obj!=undefined do (
            local nodes=selectByName title:"Cyrus Scatter - Surfaces" buttonText:"Add" filter:AminScatterSourceFilter single:false
            if nodes!=undefined do for n in nodes do addSurface n
            updateSurfaces();CyrusViewportRedraw()
        )
        on removeSurface pressed do if controlsReady and not binding and obj!=undefined do (
            local rows=surfaceList.selection as array
            undo "Cyrus Scatter remove surfaces" on (for i=rows.count to 1 by -1 do deleteItem obj.surfaceNodes rows[i])
            obj.surface=undefined;surfaceList.selection=#{};obj.dirty=true;updateSurfaces();CyrusViewportRedraw()
        )




        fn bind layer = (
            local next=this
            binding=true;controlsReady=false
            if obj!=next do (surfaceList.selection=0;)
            obj=next;parentView=this.mainUI
            for c in surfaceUI.controls do c.enabled=true
            try (undo off ((controlsReady=true;updateSurfaces()))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        on surfaceUI open do (controlsReady=true;bind (selectedLayer()))
        on surfaceUI close do controlsReady=false
    )
    rollout previewUI "Viewport and Render" width:#cmdPanel (
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false

        checkbox previewCheck "Show preview" pos:[6,8] width:138
        dropdownlist displayModeDrop "Display mode" items:#("Point Cloud","Proxy","Mesh") pos:[6,34] width:138
        dropdownlist proxyShapeDrop "Proxy shape" items:#("Box","Sphere","Pyramid") pos:[6,82] width:138
        spinner instancesLimitSpin "Instances/layer:" range:[1,100000,2000] type:#integer fieldWidth:58 pos:[6,138] width:138
        spinner faceLimitSpin "Faces/layer:" range:[12,20000000,2000000] type:#integer fieldWidth:58 pos:[6,166] width:138
        radiobuttons pointColorRadio "Preview color" labels:#("Solid Color","Source Group Colors") columns:1 pos:[6,194] width:138
        colorpicker solidColorPicker "Solid: " color:(color 100 220 120) pos:[6,264] width:138
        spinner budgetSpin "Point limit: " range:[1000,500000,20000] type:#integer fieldWidth:58 width:138 pos:[6,292]
        spinner pointsSpin "Points/plant: " range:[10,10000,80] type:#integer fieldWidth:58 width:138 pos:[6,318]
        spinner radiusLimitSpin "Radii / layer:" range:[0,1000000,2000] type:#integer fieldWidth:58 width:138 pos:[6,344]
        checkbox radiusAllCheck "Show All Radii" pos:[6,370] width:138
        label radiusHint "Display only; 0 = hide radii" pos:[6,396] width:138
        spinner iconSpin "Icon size: " range:[0.1,10000,10] type:#worldUnits fieldWidth:58 width:138 pos:[6,422]
        button refreshButton "Refresh preview" pos:[6,452] width:138
        checkbox autoRenderCheck "Automatic final render" pos:[6,482] width:138
        button clearBakedButton "Remove old baked output" pos:[6,512] width:138
        label status "Ready" pos:[6,572] width:138 height:60

        fn syncDisplay = (
            displayModeDrop.selection=obj.viewportMode;proxyShapeDrop.selection=obj.proxyShape
            proxyShapeDrop.visible=obj.viewportMode==2
            instancesLimitSpin.visible=obj.viewportMode!=1;faceLimitSpin.visible=obj.viewportMode!=1
            instancesLimitSpin.value=obj.viewportInstances;faceLimitSpin.value=obj.viewportFaces
            budgetSpin.enabled=obj.viewportMode==1;pointsSpin.enabled=obj.viewportMode==1
        )
        fn syncControls = (syncDisplay();radiusLimitSpin.value=obj.radiusDisplayLimit;radiusAllCheck.checked=obj.radiusDisplayAll;radiusLimitSpin.enabled=not obj.radiusDisplayAll;autoRenderCheck.checked=obj.autoRender;budgetSpin.value=obj.previewBudget;pointColorRadio.state=obj.pointColorMode;solidColorPicker.color=obj.solidPointColor;)
        on radiusLimitSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.radiusDisplayLimit=v;obj.refreshAll();syncControls();CyrusViewportRedraw())
        on radiusAllCheck changed v do if controlsReady and not binding and obj!=undefined do (obj.radiusDisplayAll=v;obj.refreshAll();syncControls();CyrusViewportRedraw())
        on displayModeDrop selected v do if controlsReady and not binding and obj!=undefined do (obj.viewportMode=v;obj.refreshDisplay();syncControls();status.text=obj.allStatus();CyrusViewportRedraw())
        on proxyShapeDrop selected v do if controlsReady and not binding and obj!=undefined do (obj.proxyShape=v;obj.refreshDisplay();syncControls();status.text=obj.allStatus();CyrusViewportRedraw())
        on instancesLimitSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.viewportInstances=v;obj.refreshDisplay();syncControls();status.text=obj.allStatus();CyrusViewportRedraw())
        on faceLimitSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.viewportFaces=v;obj.refreshDisplay();syncControls();status.text=obj.allStatus();CyrusViewportRedraw())
        on previewCheck changed v do if controlsReady and not binding and obj!=undefined do (obj.showPoints=v;CyrusViewportRedraw())
        on pointsSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.pointsPerPlant=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on iconSpin changed v do if controlsReady and not binding and obj!=undefined do obj.iconSize=v
        on refreshButton pressed do if controlsReady and not binding and obj!=undefined do (obj.refreshAll();status.text=obj.allStatus();CyrusViewportRedraw())
        on clearBakedButton pressed do if controlsReady and not binding and obj!=undefined do obj.clearAllBaked()

        on autoRenderCheck changed v do if controlsReady and not binding and obj!=undefined do (obj.autoRender=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on budgetSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.previewBudget=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on pointColorRadio changed v do if controlsReady and not binding and obj!=undefined do (obj.pointColorMode=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on solidColorPicker changed v do if controlsReady and not binding and obj!=undefined do (obj.solidPointColor=v;obj.dirty=true;syncControls();CyrusViewportRedraw())



        fn bind layer = (
            local next=this
            binding=true;controlsReady=false
            if obj!=next do ()
            obj=next;parentView=this.mainUI
            for c in previewUI.controls do c.enabled=true
            try (undo off ((syncDisplay();radiusLimitSpin.value=obj.radiusDisplayLimit;radiusAllCheck.checked=obj.radiusDisplayAll;radiusLimitSpin.enabled=not obj.radiusDisplayAll;autoRenderCheck.checked=obj.autoRender;budgetSpin.value=obj.previewBudget;pointColorRadio.state=obj.pointColorMode;solidColorPicker.color=obj.solidPointColor;controlsReady=true;(previewCheck.checked=obj.showPoints;pointsSpin.value=obj.pointsPerPlant;iconSpin.value=obj.iconSize)))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        on previewUI open do (controlsReady=true;bind (selectedLayer()))
        on previewUI close do controlsReady=false
    )
    rollout sourceUI "Source Object" width:#cmdPanel (
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false

        local groupPalette=#()
        local loadingColor=false
        local focusedRow=0
        multiListBox plantList "Sources (Ctrl/Shift)" items:#() pos:[8,8] height:6 width:146
        button selectFromScene "Select From Scene..." pos:[8,134] width:146
        pickbutton addPlant "Add: pick in viewport" pos:[8,160] width:146
        button addSelected "Add selected objects" pos:[8,186] width:146
        button removePlant "Remove selected rows" pos:[8,212] width:146
        button selectPlant "Select sources" pos:[8,238] width:146
        button addPoint "Add Point" pos:[7,264] width:123
        button addEmpty "Add Empty" pos:[7,290] width:123
        pickbutton replacePoint "Replace Point: pick object" filter:AminScatterSourceFilter pos:[7,316] width:123
        label groupHeading "Cluster color group" pos:[8,348] width:146
        dropdownlist existingGroups "Reuse a group" items:#() pos:[8,371] width:146
        colorpicker groupColor "Color: " color:(color 100 220 120) pos:[8,419] width:146 modal:true notifyAfterAccept:true
        button applyColor "Apply to selected rows" pos:[8,446] width:146
        label colorHelp "OK saves the selected color." pos:[8,476] width:146
        spinner weightSpin "Weight: " range:[0,1,1] scale:0.01 pos:[8,504] width:120 fieldWidth:54
        label weightHelp "0 = off; relative share" pos:[8,530] width:120
        spinner sourceZSpin "Z Offset: " range:[-1000000,1000000,0] type:#worldunits pos:[8,556] width:146 fieldWidth:65
        spinner sourceScaleSpin "Scale: " range:[0,10000,1] scale:0.01 pos:[8,582] width:146 fieldWidth:65
        label sourceTransformHelp "Scale: 1 = original" pos:[8,608] width:146
        spinner radiusSourceSpin "Collision radius:" type:#worldunits range:[0,1e9,0] pos:[7,686] width:123 fieldWidth:54
        checkbox followRadiusCheck "Follow Scale" pos:[7,712] width:123
        checkbox showRadiusCheck "Show Radius" pos:[7,738] width:123
        dropdownlist forwardAxis "Forward axis:" items:#("+Y","-Y","+X","-X") pos:[8,634] width:123
        fn colorLabel c = ("#"+(formattedPrint (obj.colorKey c) format:"06X"))
        fn updateList = (
            local selectedRows=plantList.selection
            if selectedRows.numberSet==0 and obj.sources.count>0 do selectedRows=#{1}
            plantList.items=for i=1 to obj.sources.count collect ((formattedPrint (obj.sourceWeight i) format:".2f")+" | "+(colorLabel (obj.sourceColor i))+" | "+(if obj.isPointSource i then "[Point]" else if obj.isEmptySource i then "[Empty]" else if isValidNode obj.sources[i] then obj.sources[i].name else "<deleted>"))
            plantList.selection=selectedRows
            groupPalette=#()
            local keys=#()
            for i=1 to obj.sources.count do (
                local c=obj.sourceColor i
                local k=obj.colorKey c
                if findItem keys k==0 do (append keys k;append groupPalette c)
            )
            existingGroups.items=for c in groupPalette collect (colorLabel c)
        )
        fn addSource n = (
            if obj.usableSource n and (findItem obj.sources n)==0 do (
                obj.syncColors();while obj.sourceEmpty.count<obj.sources.count do append obj.sourceEmpty false;append obj.sourceEmpty false;append obj.sources n;append obj.sourceColors groupColor.color;if obj.sourceWeights.count>0 do append obj.sourceWeights 1.0;if obj.sourceZOffsets.count>0 do append obj.sourceZOffsets 0.0;if obj.sourceScales.count>0 do append obj.sourceScales 1.0;obj.dirty=true
            )
        )

        fn showSelectedColor = (
            local rows=plantList.selection
            weightSpin.enabled=rows.numberSet>0;sourceZSpin.enabled=rows.numberSet>0;sourceScaleSpin.enabled=rows.numberSet>0;forwardAxis.enabled=rows.numberSet>0
            if rows.numberSet>0 then (
                if focusedRow<1 or not rows[focusedRow] do focusedRow=(rows as array)[1]
                loadingColor=true
                groupColor.color=obj.sourceColor focusedRow
                weightSpin.enabled=true;weightSpin.value=obj.sourceWeight focusedRow
                radiusSourceSpin.value=obj.sourceRadius focusedRow;followRadiusCheck.checked=obj.sourceFollows focusedRow;showRadiusCheck.checked=obj.sourceShows focusedRow;sourceZSpin.value=obj.sourceZOffset focusedRow;sourceScaleSpin.value=obj.sourceScale focusedRow;forwardAxis.selection=obj.sourceForward focusedRow
                existingGroups.selection=findItem groupPalette (obj.sourceColor focusedRow)
                loadingColor=false
            ) else (
                loadingColor=true;groupColor.color=obj.sourceColor 1;existingGroups.selection=0;focusedRow=0;loadingColor=false
            )
        )

        fn addSources nodes = (
            local before=obj.sources.count
            if nodes!=undefined do for n in nodes do addSource n
            updateList()
            if obj.sources.count>before do (
                local rows=#{}
                for i=before+1 to obj.sources.count do rows[i]=true
                plantList.selection=rows;focusedRow=before+1
            )
            showSelectedColor();CyrusViewportRedraw()
        )
        on addPoint pressed do if controlsReady and not binding and obj!=undefined do (
            local i=obj.addPointSource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();CyrusViewportRedraw()
        )
        on replacePoint picked n do if controlsReady and not binding and obj!=undefined do (
            local rows=plantList.selection as array
            if rows.count!=1 then messageBox "Select one Point row to replace." title:"Cyrus Scatter"
            else if not (obj.replacePointSource rows[1] n) do messageBox "Select a Point row and an object that is not already in this source list." title:"Cyrus Scatter"
            replacePoint.text="Replace Point: pick object";updateList();showSelectedColor();CyrusViewportRedraw()
        )
        on addEmpty pressed do if controlsReady and not binding and obj!=undefined do (
            local i=obj.addEmptySource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();CyrusViewportRedraw()
        )
        on radiusSourceSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingColor do (obj.setSourceRadius plantList.selection v;CyrusViewportRedraw())
        on followRadiusCheck changed v do if controlsReady and not binding and obj!=undefined do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:2;CyrusViewportRedraw())
        on showRadiusCheck changed v do if controlsReady and not binding and obj!=undefined do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:3;CyrusViewportRedraw())
        on forwardAxis selected v do if controlsReady and not binding and obj!=undefined do if not loadingColor do (obj.assignSourceForward plantList.selection v;CyrusViewportRedraw())
        on sourceZSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingColor do (obj.assignSourceTransform plantList.selection v;CyrusViewportRedraw())
        on sourceScaleSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingColor do (obj.assignSourceTransform plantList.selection v scaling:true;CyrusViewportRedraw())
        on weightSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingColor do (obj.assignWeight plantList.selection v;updateList();CyrusViewportRedraw())
        on plantList selected i do if controlsReady and not binding and obj!=undefined do (
            if i>0 and plantList.selection[i] do focusedRow=i
        )
        on plantList selectionEnd do if controlsReady and not binding and obj!=undefined do showSelectedColor()
        on existingGroups selected i do if controlsReady and not binding and obj!=undefined do (
            if i>0 and i<=groupPalette.count do (
                local c=groupPalette[i]
                loadingColor=true;groupColor.color=c;loadingColor=false
                obj.assignGroup plantList.selection c;updateList();CyrusViewportRedraw()
            )
        )
        on groupColor changed c do if controlsReady and not binding and obj!=undefined do (
            if not loadingColor and plantList.selection.numberSet>0 do (
                obj.assignGroup plantList.selection c
                updateList();CyrusViewportRedraw()
            )
        )
        on applyColor pressed do if controlsReady and not binding and obj!=undefined do (
            obj.assignGroup plantList.selection groupColor.color
            updateList();CyrusViewportRedraw()
        )
        on selectFromScene pressed do if controlsReady and not binding and obj!=undefined do (
            local picked=selectByName title:"Cyrus Scatter - Select From Scene" buttonText:"Add" filter:AminScatterSourceFilter single:false
            addSources picked
        )
        on addPlant picked n do if controlsReady and not binding and obj!=undefined do addSources #(n)
        on addSelected pressed do if controlsReady and not binding and obj!=undefined do addSources (selection as array)
        on removePlant pressed do if controlsReady and not binding and obj!=undefined do (
            obj.syncColors()
            local rows=plantList.selection as array
            undo "Cyrus Scatter remove sources" on (
                for k=rows.count to 1 by -1 do (
                    for key in #(#sourceRadii,#sourceFollowScale,#sourceShowRadius) do (local tab=getProperty obj key;if rows[k]<=tab.count do deleteItem tab rows[k])
                    if rows[k]<=obj.sourcePoint.count do deleteItem obj.sourcePoint rows[k]
                    if rows[k]<=obj.sourceEmpty.count do deleteItem obj.sourceEmpty rows[k]
                    if rows[k]<=obj.sourceZOffsets.count do deleteItem obj.sourceZOffsets rows[k]
                    if rows[k]<=obj.sourceScales.count do deleteItem obj.sourceScales rows[k]
                    if rows[k]<=obj.sourceForwardAxes.count do deleteItem obj.sourceForwardAxes rows[k]
                    if rows[k]<=obj.sourceWeights.count do deleteItem obj.sourceWeights rows[k]
                    deleteItem obj.sources rows[k];deleteItem obj.sourceColors rows[k]
                )
            )
            plantList.selection=#{};obj.dirty=true;updateList();CyrusViewportRedraw()
        )
        on selectPlant pressed do if controlsReady and not binding and obj!=undefined do (
            local nodes=for i in plantList.selection where i<=obj.sources.count and isValidNode obj.sources[i] collect obj.sources[i]
            if nodes.count>0 do select nodes
        )




        fn bind layer = (
            local next=if layer==undefined then this else layer
            binding=true;controlsReady=false
            if obj!=next do (plantList.selection=#{};)
            obj=next;parentView=this.mainUI
            for c in sourceUI.controls do c.enabled=layer!=undefined
            try (undo off ((controlsReady=true;(updateList();showSelectedColor())))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        on sourceUI open do (controlsReady=true;bind (selectedLayer()))
        on sourceUI close do controlsReady=false
    )
    rollout distributionUI "Point Generation" width:#cmdPanel (
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false

        radiobuttons modeRadio "Method" labels:#("Random","Texture Density") columns:1 pos:[8,8] width:146
        radiobuttons populationRadio "Population" labels:#("Count","Plants per m2") columns:1 pos:[8,78] width:146
        checkbox showCenterCheck "Show Point" pos:[8,148] width:120
        on showCenterCheck changed v do if controlsReady and not binding and obj!=undefined do (obj.showCenters=v;CyrusViewportRedraw())
        spinner countSpin "Count: " range:[1,100000,200] type:#integer fieldWidth:64 width:146 pos:[8,174]
        spinner densitySpin "Per m2: " range:[0,1000000,100] fieldWidth:64 width:146 pos:[8,200]
        spinner seedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:64 width:146 pos:[8,226]
        label densityHeading "Texture density" pos:[8,260] width:146
        mapbutton densityButton "Choose density map" pos:[8,284] width:146
        checkbox invertCheck "Invert density" pos:[8,312] width:146
        label uvHint "UV channel 1; 0..1" pos:[8,338] width:146
        label mapHint "White: dense / Black: empty" pos:[8,360] width:146

        fn syncControls = (populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;)
        on modeRadio changed v do if controlsReady and not binding and obj!=undefined do (obj.distributionMode=if v==2 then 3 else 1;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on countSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.amount=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on seedSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.randomSeed=v;obj.dirty=true;syncControls();CyrusViewportRedraw())

        on populationRadio changed v do if controlsReady and not binding and obj!=undefined do (obj.populationMode=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on densitySpin changed v do if controlsReady and not binding and obj!=undefined do (obj.plantsPerM2=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on densityButton picked v do if controlsReady and not binding and obj!=undefined do (obj.densityMap=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on invertCheck changed v do if controlsReady and not binding and obj!=undefined do (obj.invertDensity=v;obj.dirty=true;syncControls();CyrusViewportRedraw())



        fn bind layer = (
            local next=if layer==undefined then this else layer
            binding=true;controlsReady=false
            if obj!=next do ()
            obj=next;parentView=this.mainUI
            for c in distributionUI.controls do c.enabled=layer!=undefined
            try (undo off ((showCenterCheck.checked=obj.showCenters;populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;controlsReady=true;(countSpin.value=obj.amount;seedSpin.value=obj.randomSeed;modeRadio.state=if obj.distributionMode==3 then 2 else 1)))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        on distributionUI open do (controlsReady=true;bind (selectedLayer()))
        on distributionUI close do controlsReady=false
    )
    rollout brushUI "Procedural Brush" width:#cmdPanel (
        local obj=undefined,controlsReady=false,binding=false,history=#()
        checkbox maskCheck "Use painted density" pos:[8,8] width:146
        pickbutton targetPick "Pick receiving surface" filter:AminScatterSourceFilter pos:[8,34] width:146 tooltip:"This Brush layer uses one receiving object, including curved meshes. It overrides the shared surface list for this layer."
        label targetInfo "No Brush target" pos:[8,62] width:146 height:32
        radiobuttons modeRadio "Next stroke" labels:#("Paint","Erase") columns:2 pos:[8,98] width:146
        spinner radiusSpin "Radius:" type:#worldunits range:[0.0001,1e9,20] fieldWidth:58 pos:[8,152] width:146
        spinner strengthSpin "Strength %:" range:[0,100,100] fieldWidth:58 pos:[8,180] width:146
        spinner softSpin "Softness %:" range:[0,100,50] fieldWidth:58 pos:[8,208] width:146
        spinner densitySpin "Density %:" range:[0,100,100] fieldWidth:58 pos:[8,236] width:146 tooltip:"Thins the stable candidate population. Increase Count or plants/m2 in Point Generation for a larger base population."
        button beginButton "Start Brush" pos:[8,270] width:70
        button stopButton "Stop" pos:[84,270] width:70
        button fillButton "Fill" pos:[8,302] width:70 tooltip:"Fill the receiving surface and reset stroke history. Undo restores the previous field."
        button emptyButton "Empty" pos:[84,302] width:70 tooltip:"Empty the density field and reset stroke history. Undo restores the previous field."
        label brushState "Pick a target to start." pos:[8,334] width:146 height:54
        listbox strokeList "Editable stroke history" items:#() pos:[8,394] width:146 height:5
        checkbox strokeEnabled "Stroke enabled" pos:[8,514] width:146
        checkbox strokeErase "Erase stroke" pos:[8,540] width:146
        spinner strokeRadius "Radius:" type:#worldunits range:[0.0001,1e9,20] fieldWidth:58 pos:[8,568] width:146
        spinner strokeStrength "Strength %:" range:[0,100,100] fieldWidth:58 pos:[8,596] width:146
        spinner strokeSoft "Softness %:" range:[0,100,50] fieldWidth:58 pos:[8,624] width:146
        button deleteStroke "Delete stroke" pos:[8,658] width:146
        label brushHelp "White dots show density.\nRight-click stops Brush.\nManual mode waits for Update." pos:[8,690] width:146 height:54
        fn showStroke = (
            binding=true
            local i=strokeList.selection,valid=i>0 and i<=history.count
            for c in #(strokeEnabled,strokeErase,strokeRadius,strokeStrength,strokeSoft,deleteStroke) do c.enabled=valid
            if valid do (
                local row=history[i]
                strokeEnabled.checked=row[1];strokeErase.checked=row[2];strokeRadius.value=row[3];strokeStrength.value=row[4]*100;strokeSoft.value=row[5]*100
            )
            binding=false
        )
        fn refreshHistory = (
            binding=true
            local chosen=strokeList.selection
            history=if obj!=undefined and obj.paintDocument!=undefined then cyrusBrushHistory obj.paintDocument else #()
            strokeList.items=for i=1 to history.count collect ((i as string)+" | "+(if history[i][2] then "Erase" else "Paint")+(if history[i][1] then "" else " (off)")+" | "+(history[i][6] as string)+" samples")
            strokeList.selection=amin chosen history.count
            binding=false;showStroke()
        )
        fn editStroke = (
            local i=strokeList.selection
            if binding or i<1 or i>history.count do return false
            cyrusBrushStroke obj.paintDocument i strokeEnabled.checked (strokeStrength.value/100.0) strokeRadius.value (strokeSoft.value/100.0) strokeErase.checked
            obj.publishPaint();refreshHistory()
        )
        fn saveOptions = (
            if not binding and obj!=undefined and obj.paintDocument!=undefined do cyrusBrushSettings obj.paintDocument radiusSpin.value (strengthSpin.value/100.0) (softSpin.value/100.0) (modeRadio.state==2) 1.0
        )
        fn status = (
            if obj==undefined do return false
            if obj.paintDocument==undefined then brushState.text="Pick a receiving surface." else (
                local state=cyrusBrushStats obj.paintDocument
                local message=(if state[5]==1 then "Brush active" else "Brush stopped")+" | "+(CyrusUICount state[2])+" strokes"
                if state[11]!="" do message+="\n"+state[11]
                if obj.updateMode==1 and obj.dirty do message+="\nPlants need Update."
                if brushState.text!=message do brushState.text=message
            )
        )
        fn bind layer = (
            binding=true;obj=layer
            for c in brushUI.controls do c.enabled=layer!=undefined
            local has=layer!=undefined and layer.paintDocument!=undefined
            for c in #(maskCheck,modeRadio,radiusSpin,strengthSpin,softSpin,densitySpin,beginButton,stopButton,fillButton,emptyButton) do c.enabled=has
            targetInfo.text=if has and isValidNode (cyrusBrushTarget layer.paintDocument) then (cyrusBrushTarget layer.paintDocument).name else "No Brush target"
            if has do (
                local cfg=cyrusBrushOptions layer.paintDocument
                maskCheck.checked=layer.paintEnabled;radiusSpin.value=cfg[1];strengthSpin.value=cfg[2]*100;softSpin.value=cfg[3]*100;modeRadio.state=if cfg[5] then 2 else 1;densitySpin.value=layer.paintDensity*100
            )
            controlsReady=true;binding=false;refreshHistory();status()
        )
        on brushUI open do bind (this.selectedLayer())
        on brushUI close do (controlsReady=false;CyrusStopBrush())
        on targetPick picked node do if obj!=undefined do (
            CyrusStopBrush()
            undo "Cyrus Brush target" on (obj.paintDocument=cyrusBrushCreate node;obj.paintIdentity=true;obj.paintEnabled=true)
            obj.publishPaint();bind obj;this.syncBrushCompatibility()
        )
        on maskCheck changed value do if not binding do (undo "Cyrus Brush enabled" on obj.paintEnabled=value;obj.publishPaint();this.syncBrushCompatibility())
        on modeRadio changed value do saveOptions()
        on radiusSpin changed value do saveOptions()
        on strengthSpin changed value do saveOptions()
        on softSpin changed value do saveOptions()
        on densitySpin changed value do if not binding do (undo "Cyrus Brush density" on obj.paintDensity=value/100.0;obj.publishPaint())
        on beginButton pressed do (saveOptions();CyrusStartBrush this obj;status())
        on stopButton pressed do (CyrusStopBrush();refreshHistory();status())
        on fillButton pressed do (cyrusBrushFill obj.paintDocument 1.0;obj.publishPaint();refreshHistory();status())
        on emptyButton pressed do (cyrusBrushFill obj.paintDocument 0.0;obj.publishPaint();refreshHistory();status())
        on strokeList selected value do showStroke()
        on strokeEnabled changed value do editStroke()
        on strokeErase changed value do editStroke()
        on strokeRadius changed value do editStroke()
        on strokeStrength changed value do editStroke()
        on strokeSoft changed value do editStroke()
        on deleteStroke pressed do if strokeList.selection>0 do (cyrusBrushDeleteStroke obj.paintDocument strokeList.selection;obj.publishPaint();refreshHistory();status())
    )

    rollout areaUI "Area" width:#cmdPanel (
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false

        multiListBox areaList "Closed lines / shapes" items:#() pos:[8,8] width:146 height:6
        button addAreaScene "Select From Scene..." pos:[8,134] width:146
        pickbutton pickArea "Add: pick closed line" filter:AminScatterAreaFilter pos:[8,160] width:146
        button removeArea "Remove selected rows" pos:[8,186] width:146
        radiobuttons areaMode "Selected area mode" labels:#("Include","Exclude") columns:1 pos:[8,220] width:146
        label areaHint "Exclude overrides Include." pos:[8,290] width:146
        label projectionHint "Top / world XY projection." pos:[8,312] width:146
        button refreshAreas "Refresh areas / preview" pos:[8,340] width:146
        local loadingAnalyzerArea=false
        label aaTitle "Surface Analyzer Area" pos:[8,378] width:146
        pickbutton aaPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[8,404] width:146
        button aaRemove "Remove Area Analyzer" pos:[8,432] width:146
        checkbox aaLine "Center Line" pos:[8,464] width:146
        spinner aaWidth "Full width:" range:[0,1e9,100] type:#worldunits pos:[8,490] width:146 fieldWidth:62
        dropdownlist aaCaps "Line ends" items:#("Flat","Round") selection:1 pos:[8,518] width:146
        spinner aaStreetOffset "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[8,572] width:146 fieldWidth:62
        checkbox aaPoints "Points" pos:[8,604] width:146
        spinner aaRadius "Radius:" range:[0,1e9,100] type:#worldunits pos:[8,630] width:146 fieldWidth:62
        label aaHelp "XY mask. Both enabled = union. Works with Random / Clusters." pos:[8,660] width:146 height:40
        fn syncAnalyzerArea = (
            loadingAnalyzerArea=true
            aaPick.text=if isValidNode obj.areaAnalyzer then obj.areaAnalyzer.name else "Pick Surface Analyzer"
            aaLine.checked=obj.areaUseLine;aaPoints.checked=obj.areaUsePoints
            aaStreetOffset.value=obj.centerStreetOffset;aaStreetOffset.enabled=obj.areaUseLine
            aaWidth.value=obj.areaLineWidth;aaRadius.value=obj.areaPointRadius;aaCaps.selection=obj.areaLineCaps
            aaWidth.enabled=obj.areaUseLine;aaCaps.enabled=obj.areaUseLine;aaRadius.enabled=obj.areaUsePoints
            loadingAnalyzerArea=false
        )
        on aaPick picked n do if controlsReady and not binding and obj!=undefined do (obj.areaAnalyzer=n;syncAnalyzerArea();CyrusViewportRedraw())
        on aaRemove pressed do if controlsReady and not binding and obj!=undefined do (obj.areaUseLine=false;obj.areaUsePoints=false;obj.areaAnalyzer=undefined;syncAnalyzerArea();CyrusViewportRedraw())
        on aaLine changed v do if controlsReady and not binding and obj!=undefined do if not loadingAnalyzerArea do (obj.areaUseLine=v;syncAnalyzerArea();CyrusViewportRedraw())
        on aaPoints changed v do if controlsReady and not binding and obj!=undefined do if not loadingAnalyzerArea do (obj.areaUsePoints=v;syncAnalyzerArea();CyrusViewportRedraw())
        on aaStreetOffset changed v do if controlsReady and not binding and obj!=undefined do if not loadingAnalyzerArea do (obj.centerStreetOffset=v;CyrusViewportRedraw())
        on aaWidth changed v do if controlsReady and not binding and obj!=undefined do if not loadingAnalyzerArea do (obj.areaLineWidth=v;CyrusViewportRedraw())
        on aaRadius changed v do if controlsReady and not binding and obj!=undefined do if not loadingAnalyzerArea do (obj.areaPointRadius=v;CyrusViewportRedraw())
        on aaCaps selected v do if controlsReady and not binding and obj!=undefined do if not loadingAnalyzerArea do (obj.areaLineCaps=v;CyrusViewportRedraw())

        local loadingFall=false
        dropdownlist fallTarget "Edge falloff target" items:#("Analyzer Boundary","Selected Area line") selection:1 pos:[8,704] width:146
        pickbutton fallPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[8,760] width:146
        button fallRemove "Remove Analyzer" pos:[8,788] width:146
        label fallTargetName "" pos:[8,818] width:146 height:40
        checkbox fallDeleteCheck "Delete edge band" pos:[8,860] width:146
        spinner fallDeleteSpin "Delete width:" range:[0,1e9,0] type:#worldunits pos:[8,886] width:146 fieldWidth:62
        checkbox fallScaleCheck "Scale ramp" pos:[8,918] width:146
        spinner fallScaleSpin "Scale width:" range:[0,1e9,100] type:#worldunits pos:[8,944] width:146 fieldWidth:62
        button fallScaleEdit "Edit Scale Graph..." pos:[8,974] width:146
        checkbox fallDensityCheck "Density ramp" pos:[8,1010] width:146
        spinner fallDensitySpin "Density width:" range:[0,1e9,100] type:#worldunits pos:[8,1036] width:146 fieldWidth:62
        button fallDensityEdit "Edit Density Graph..." pos:[8,1066] width:146
        label fallHelp "Ramps start after delete band. Each Area line has its own settings." pos:[8,1104] width:146 height:56
        fn fallNode = (
            if fallTarget.selection==1 then undefined else (
                local rows=areaList.selection as array
                if rows.count==1 and rows[1]<=obj.areaNodes.count then obj.areaNodes[rows[1]] else undefined
            )
        )
        fn syncFalloff = (
            loadingFall=true
            local n=fallNode(),valid=(fallTarget.selection==1 or isValidNode n)
            local cfg=if valid then obj.getFallConfig n else #(false,0,false,100,#(0,1),false,100,#(0,1))
            fallPick.enabled=fallTarget.selection==1;fallRemove.enabled=fallTarget.selection==1
            fallPick.text=if isValidNode obj.fallAnalyzer then obj.fallAnalyzer.name else "Pick Surface Analyzer"
            fallTargetName.text=if fallTarget.selection==1 then "Full Boundary / inward" else (if valid then n.name+" / "+(if obj.areaModes[findItem obj.areaNodes n]==2 then "outward" else "inward") else "Select exactly one Area line above."
            )
            for c in #(fallDeleteCheck,fallDeleteSpin,fallScaleCheck,fallScaleSpin,fallScaleEdit,fallDensityCheck,fallDensitySpin,fallDensityEdit) do c.enabled=valid
            fallDeleteCheck.checked=cfg[1];fallDeleteSpin.value=cfg[2];fallScaleCheck.checked=cfg[3];fallScaleSpin.value=cfg[4];fallDensityCheck.checked=cfg[6];fallDensitySpin.value=cfg[7]
            loadingFall=false
        )
        fn setFallValue index value = (
            if not loadingFall do (
                local n=fallNode()
                if fallTarget.selection==1 or isValidNode n do (local cfg=obj.getFallConfig n;cfg[index]=value;obj.setFallConfig n cfg;CyrusViewportRedraw())
            )
        )
        on fallTarget selected v do if controlsReady and not binding and obj!=undefined do syncFalloff()
        on fallPick picked n do if controlsReady and not binding and obj!=undefined do (if CyrusAnalyzerFilter n do obj.fallAnalyzer=n;syncFalloff();CyrusViewportRedraw())
        on fallRemove pressed do if controlsReady and not binding and obj!=undefined do (obj.fallAnalyzer=undefined;obj.fallDelete=false;obj.fallScale=false;obj.fallDensity=false;syncFalloff();CyrusViewportRedraw())
        on fallDeleteCheck changed v do if controlsReady and not binding and obj!=undefined do setFallValue 1 v
        on fallDeleteSpin changed v do if controlsReady and not binding and obj!=undefined do setFallValue 2 v
        on fallScaleCheck changed v do if controlsReady and not binding and obj!=undefined do setFallValue 3 v
        on fallScaleSpin changed v do if controlsReady and not binding and obj!=undefined do setFallValue 4 v
        on fallDensityCheck changed v do if controlsReady and not binding and obj!=undefined do setFallValue 6 v
        on fallDensitySpin changed v do if controlsReady and not binding and obj!=undefined do setFallValue 7 v
        on fallScaleEdit pressed do if controlsReady and not binding and obj!=undefined do CyrusOpenFalloffGraph obj (fallNode()) false
        on fallDensityEdit pressed do if controlsReady and not binding and obj!=undefined do CyrusOpenFalloffGraph obj (fallNode()) true

        fn updateAreas = (
            local selectedRows=areaList.selection
            areaList.items=for i=1 to obj.areaNodes.count collect (
                (if i<=obj.areaModes.count and obj.areaModes[i]==2 then "Exclude | " else "Include | ")+
                (if isValidNode obj.areaNodes[i] then obj.areaNodes[i].name else "<deleted>")
            )
            areaList.selection=selectedRows
            syncFalloff()
        )
        fn addArea n = (
            if AminScatterAreaFilter n and findItem obj.areaNodes n==0 do (
                append obj.areaNodes n;append obj.areaModes 1;obj.dirty=true
            )
        )

        on pickArea picked n do if controlsReady and not binding and obj!=undefined do (addArea n;updateAreas();CyrusViewportRedraw())
        on addAreaScene pressed do if controlsReady and not binding and obj!=undefined do (
            local nodes=selectByName title:"Cyrus Scatter - Closed Areas" buttonText:"Add" filter:AminScatterAreaFilter single:false
            if nodes!=undefined do for n in nodes do addArea n
            updateAreas();CyrusViewportRedraw()
        )
        on areaList selectionEnd do if controlsReady and not binding and obj!=undefined do (
            if areaList.selection.numberSet==1 do fallTarget.selection=2
            syncFalloff()
            if areaList.selection.numberSet>0 do areaMode.state=obj.areaModes[(areaList.selection as array)[1]]
        )
        on areaMode changed mode do if controlsReady and not binding and obj!=undefined do (
            undo "Cyrus Scatter area mode" on (for i in areaList.selection do obj.areaModes[i]=mode)
            obj.dirty=true;updateAreas();CyrusViewportRedraw()
        )
        on removeArea pressed do if controlsReady and not binding and obj!=undefined do (
            if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()
            local rows=areaList.selection as array
            undo "Cyrus Scatter remove areas" on (
                obj.ensureAreaFalloffs()
                for i=rows.count to 1 by -1 do (deleteItem obj.areaNodes rows[i];deleteItem obj.areaModes rows[i];deleteItem obj.areaFallConfigs rows[i];deleteItem obj.areaFallScaleGraphs rows[i];deleteItem obj.areaFallDensityGraphs rows[i])
            )
            areaList.selection=#{};obj.dirty=true;updateAreas();CyrusViewportRedraw()
        )
        on refreshAreas pressed do if controlsReady and not binding and obj!=undefined do (obj.dirty=true;obj.refreshPreview();CyrusViewportRedraw())




        fn bind layer = (
            local next=if layer==undefined then this else layer
            binding=true;controlsReady=false
            if obj!=next do (areaList.selection=#{};)
            obj=next;parentView=this.mainUI
            for c in areaUI.controls do c.enabled=layer!=undefined
            try (undo off ((syncAnalyzerArea();syncFalloff();controlsReady=true;updateAreas()))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        on areaUI open do (controlsReady=true;bind (selectedLayer()))
        on areaUI close do controlsReady=false
    )
    rollout diversityUI "Diversity / Colors" width:#cmdPanel (
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false,strokeExpandedHeight=0

        radiobuttons diversityRadio "Source assignment" labels:#("Random","Clusters","Line Pattern","Analyze Surface") columns:1 pos:[8,8] width:146
        spinner sizeSpin "Size: " range:[0.01,100000,10] type:#worldUnits fieldWidth:64 width:146 pos:[8,104]
        spinner divSeedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:64 width:146 pos:[8,130]
        spinner roughSpin "Roughness %: " range:[0,100,0] fieldWidth:54 width:146 pos:[8,156]
        spinner blurSpin "Blur edge %: " range:[0,100,0] fieldWidth:54 width:146 pos:[8,182]
        spinner noiseSpin "Noise %: " range:[0,100,0] fieldWidth:54 width:146 pos:[8,208]
        label groupHint "Uses source group colors." pos:[8,238] width:146
        label fixedHint "Point positions stay fixed." pos:[8,260] width:146




        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[8,118] width:146
        dropdownlist pathsDrop "Paths" items:#() pos:[8,142] width:146
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[8,142] width:146
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[8,192] width:146
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[8,192] width:146
        button removePath "Remove path" pos:[8,218] width:146
        listbox strokesList "Consecutive strokes" items:#() pos:[8,250] width:146 height:4
        button addOutside "Add Outside" pos:[8,346] width:70
        button addInside "Add Inside" pos:[84,346] width:70
        button removeStrokeButton "Remove Stroke" pos:[8,372] width:146
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[8,406] width:146 fieldWidth:64
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[8,434] width:146
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[8,506] width:146 height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[8,618] width:146 fieldWidth:58
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[8,644] width:146 fieldWidth:58
        button refreshGroups "Refresh sources / groups" pos:[8,676] width:146
        label strokeHelp "Outside strokes: empty." pos:[8,704] width:146
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[8,814] width:123 fieldWidth:52
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[8,842] width:123 fieldWidth:52
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[8,870] width:123 fieldWidth:52
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[8,898] width:123 height:36
        checkbox keepCornerCheck "Keep corner points" pos:[8,940] width:123
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[8,968] width:123 fieldWidth:52
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[8,996] width:123 fieldWidth:52
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[8,1024] width:123 height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[8,1066] width:123 fieldWidth:52
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[8,1094] width:123 fieldWidth:52
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[8,1122] width:123 fieldWidth:52
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[8,814] width:146 fieldWidth:62
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[8,842] width:146 fieldWidth:62
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[8,814] width:146 fieldWidth:62
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[8,874] width:146 height:44
        checkbox faceOutCheck "Face outward" pos:[8,756] width:123
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[8,784] width:123 fieldWidth:52
        checkbox straightStreet "Straight ends (Street Side)" pos:[8,730] width:146
        fn syncControls = (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;)
        on faceOutCheck changed v do if controlsReady and not binding and obj!=undefined do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;CyrusViewportRedraw()
        )
        on cornerRadiusSpin changed v do if controlsReady and not binding and obj!=undefined do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;CyrusViewportRedraw()
        )
        on streetStartSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (obj.streetTrimStart=v;CyrusViewportRedraw())
        on streetEndSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (obj.streetTrimEnd=v;CyrusViewportRedraw())
        on centerStreetSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (obj.centerStreetOffset=v;CyrusViewportRedraw())
        on straightStreet changed v do if controlsReady and not binding and obj!=undefined do (obj.streetStraight=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        fn selectedStroke = (if strokesList.selection>0 and strokesList.selection<=strokeRows.count then strokeRows[strokesList.selection] else 0)
        fn showStroke = (
            loadingStroke=true
            obj.syncStrokes()
            local edgeVisible=obj.diversityMode==4 and analyzerChannel.selection==5
            for c in #(edgeOffsetSpin,edgeAlongSpin,edgeAcrossSpin,edgeRowHelp,keepCornerCheck,cornerAngleSpin,cornerCountSpin,cornerHelp,edgeRotXSpin,edgeRotYSpin,edgeRotZSpin) do c.visible=edgeVisible
            cornerRadiusSpin.text=if edgeVisible then "Blend radius:" else "Corner radius:"
            keepCornerCheck.checked=obj.edgeKeepCorners
            cornerAngleSpin.value=obj.edgeCornerAngle;cornerCountSpin.value=obj.edgeCornerCount
            cornerAngleSpin.enabled=obj.edgeKeepCorners;cornerCountSpin.enabled=obj.edgeKeepCorners
            strokeWidth.text=if edgeVisible then "Spacing:" else "Width:"
            local row=selectedStroke();local active=row>0
            for c in #(strokeWidth,strokeMode,strokeChoices,strokeScaleMin,strokeScaleMax,removeStrokeButton) do c.enabled=active
            choiceValues=#();strokeChoices.items=#()
            for c in #(edgeOffsetSpin,edgeAlongSpin,edgeAcrossSpin,edgeRotXSpin,edgeRotYSpin,edgeRotZSpin) do c.enabled=active
            if active do (
                edgeRotXSpin.value=obj.edgeRotX[row]
                edgeRotYSpin.value=obj.edgeRotY[row]
                edgeRotZSpin.value=obj.edgeRotZ[row]
                edgeOffsetSpin.value=obj.edgeOffsets[row];edgeAlongSpin.value=obj.edgeAlong[row];edgeAcrossSpin.value=obj.edgeAcross[row]
                strokeWidth.value=obj.patternWidths[row];strokeMode.state=obj.strokeModes[row]
                strokeWidth.enabled=obj.strokeSides[row]!=5
                strokeScaleMin.value=obj.strokeMin[row];strokeScaleMax.value=obj.strokeMax[row]
                local labels=#();local selectedRows=#{}
                if obj.strokeModes[row]==1 then (
                    for i=1 to obj.sources.count do (
                        local key=obj.colorKey(obj.sourceColor i)
                        if findItem choiceValues key==0 do (append choiceValues key;append labels ("#"+(formattedPrint key format:"06X")))
                    )
                    local keys=for i=1 to obj.strokeColorRows.count where obj.strokeColorRows[i]==row collect obj.strokeColorKeys[i]
                    if keys.count==0 do keys=#(obj.patternGroups[row])
                    for i=1 to choiceValues.count where findItem keys choiceValues[i]>0 do selectedRows[i]=true
                ) else (
                    for n in obj.sources where isValidNode n do (append choiceValues n;append labels n.name)
                    for i=1 to obj.strokeSourceRows.count where obj.strokeSourceRows[i]==row do (
                        local k=findItem choiceValues obj.strokeSourceNodes[i];if k>0 do selectedRows[k]=true
                    )
                )
                strokeChoices.items=labels;strokeChoices.selection=selectedRows
            )
            loadingStroke=false
        )
        fn showPath = (
            loadingStroke=true
            local old=strokesList.selection;strokeRows=#();local labels=#();local total=#(0.0,0.0,0.0,0.0,0.0,0.0,0.0)
            local analyzed=obj.diversityMode==4
            local path=if analyzed then obj.analyzerNode else (if pathsDrop.selection>0 then pathRows[pathsDrop.selection] else undefined)
            if isValidNode path do (
                for i=1 to obj.patternLines.count where obj.patternLines[i]==path and (not analyzed or (analyzerChannel.selection==1 and obj.strokeSides[i]<=2) or (analyzerChannel.selection==2 and obj.strokeSides[i]==3) or (analyzerChannel.selection==3 and (obj.strokeSides[i]==4 or obj.strokeSides[i]==5)) or (analyzerChannel.selection==4 and obj.strokeSides[i]==6) or (analyzerChannel.selection==5 and obj.strokeSides[i]==7)) do (
                    append strokeRows i
                    local side=obj.strokeSides[i];local start=total[side];total[side]+=obj.patternWidths[i]
                    local prefixes=#("Out ","In ","Both ","Radius ","Single ","Street ","Edge ")
                    append labels (if side==7 then ("Edge "+(strokeRows.count as string)+": spacing "+units.formatValue obj.patternWidths[i]) else (prefixes[side]+(strokeRows.count as string)+": "+units.formatValue start+" - "+units.formatValue total[side]))
                )
            )
            strokesList.items=labels;strokesList.selection=amin (amax 1 old) labels.count
            addOutside.enabled=isValidNode path;addInside.enabled=isValidNode path and (not analyzed or analyzerChannel.selection!=2);removePath.enabled=isValidNode path
            loadingStroke=false;showStroke()
        )
        fn updatePattern = (
            faceOutCheck.visible=obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5)
            cornerRadiusSpin.visible=faceOutCheck.visible
            faceOutCheck.checked=if analyzerChannel.selection==5 then obj.edgeFaceOut else if analyzerChannel.selection==4 then obj.streetFaceOut else obj.borderFaceOut
            cornerRadiusSpin.value=if analyzerChannel.selection==5 then obj.edgeCornerRadius else if analyzerChannel.selection==4 then obj.streetCornerRadius else obj.borderCornerRadius
            cornerRadiusSpin.enabled=faceOutCheck.checked
            streetStartSpin.visible=obj.diversityMode==4 and analyzerChannel.selection==4
            streetEndSpin.visible=streetStartSpin.visible
            centerStreetSpin.visible=obj.diversityMode==4 and analyzerChannel.selection==2
            streetLayoutHelp.visible=streetStartSpin.visible or centerStreetSpin.visible
            streetStartSpin.value=obj.streetTrimStart;streetEndSpin.value=obj.streetTrimEnd;centerStreetSpin.value=obj.centerStreetOffset
            straightStreet.checked=obj.streetStraight;straightStreet.visible=obj.diversityMode==4 and analyzerChannel.selection==4
            obj.syncStrokes();local old=pathsDrop.selection
            local analyzed=obj.diversityMode==4
            pathRows=for n in obj.patternPaths where isValidNode n and not isProperty n #samplePoints collect n
            pathsDrop.items=for n in pathRows collect n.name
            pathsDrop.selection=amin (amax 1 old) pathRows.count
            pathsDrop.visible=obj.diversityMode==3;pickPath.visible=obj.diversityMode==3
            analyzerChannel.visible=analyzed;pickAnalyzer.visible=analyzed
            pickAnalyzer.text=if isValidNode obj.analyzerNode then obj.analyzerNode.name else "Pick Surface Analyzer"
            removePath.text=if analyzed then "Remove Analyzer" else "Remove path"
            strokeTitle.text=if analyzed then "Analyze Surface / Strokes" else "Line Pattern / Strokes"
            addOutside.text=if not analyzed or analyzerChannel.selection==1 then "Add Outside" else (if analyzerChannel.selection==2 then "Add Stroke" else "Add Radius")
            addInside.text=if analyzed and analyzerChannel.selection==3 then "Add Single" else "Add Inside"
            local boundaryOnly=analyzed and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5)
            addOutside.visible=(obj.diversityMode==3 or analyzed) and not boundaryOnly
            addInside.pos=[if boundaryOnly then 8 else 84,addOutside.pos.y]
            addInside.width=if boundaryOnly then 146 else 70
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do if controlsReady and not binding and obj!=undefined do showPath()
        on analyzerChannel selected i do if controlsReady and not binding and obj!=undefined do updatePattern()
        on pickAnalyzer picked n do if controlsReady and not binding and obj!=undefined do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();CyrusViewportRedraw())
        )
        on strokesList selected i do if controlsReady and not binding and obj!=undefined do showStroke()
        on pickPath picked n do if controlsReady and not binding and obj!=undefined do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do if controlsReady and not binding and obj!=undefined do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;syncControls();CyrusViewportRedraw()
        )
        on addOutside pressed do if controlsReady and not binding and obj!=undefined do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();CyrusViewportRedraw()
        )
        on addInside pressed do if controlsReady and not binding and obj!=undefined do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();CyrusViewportRedraw()
        )
        on removeStrokeButton pressed do if controlsReady and not binding and obj!=undefined do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();CyrusViewportRedraw())
        on edgeOffsetSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;CyrusViewportRedraw())
        on edgeAlongSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;CyrusViewportRedraw())
        on edgeAcrossSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;CyrusViewportRedraw())
        on keepCornerCheck changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;CyrusViewportRedraw())
        on cornerAngleSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (obj.edgeCornerAngle=v;CyrusViewportRedraw())
        on cornerCountSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (obj.edgeCornerCount=v;CyrusViewportRedraw())
        on edgeRotXSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;CyrusViewportRedraw())
        on edgeRotYSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;CyrusViewportRedraw())
        on edgeRotZSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;CyrusViewportRedraw())
        on strokeWidth changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();CyrusViewportRedraw())
        on strokeMode changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;syncControls();CyrusViewportRedraw())
        on strokeChoices selectionEnd do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            CyrusViewportRedraw()
        )
        on strokeScaleMin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;syncControls();CyrusViewportRedraw())
        on strokeScaleMax changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;syncControls();CyrusViewportRedraw())
        on refreshGroups pressed do if controlsReady and not binding and obj!=undefined do updatePattern()
                fn updateControls = (
            for c in #(sizeSpin,divSeedSpin,roughSpin,blurSpin,noiseSpin,groupHint,fixedHint) do c.visible=obj.diversityMode==2
            for c in #(strokeTitle,pathsDrop,analyzerChannel,pickAnalyzer,pickPath,removePath,strokesList,addOutside,addInside,removeStrokeButton,strokeWidth,strokeMode,strokeChoices,strokeScaleMin,strokeScaleMax,refreshGroups,strokeHelp) do c.visible=(obj.diversityMode==3 or obj.diversityMode==4)
            if strokeExpandedHeight>0 do diversityUI.height=if obj.diversityMode>=3 then strokeExpandedHeight else (if obj.diversityMode==2 then 310 else 124)*1.0
            true
        )
        on diversityRadio changed v do if controlsReady and not binding and obj!=undefined do (obj.diversityMode=v;updateControls();updatePattern();obj.dirty=true;syncControls();CyrusViewportRedraw())


        on sizeSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.diversitySize=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on divSeedSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.diversitySeed=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on roughSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.roughness=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on blurSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.blurryEdge=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on noiseSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.diversityNoise=v;obj.dirty=true;syncControls();CyrusViewportRedraw())



        fn bind layer = (
            local next=if layer==undefined then this else layer
            binding=true;controlsReady=false
            if obj!=next do (strokesList.selection=0;strokeChoices.selection=0;)
            obj=next;parentView=this.mainUI
            for c in diversityUI.controls do c.enabled=layer!=undefined
            try (undo off ((diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;controlsReady=true;strokeExpandedHeight=diversityUI.height;updateControls();updatePattern()))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        on diversityUI open do (controlsReady=true;bind (selectedLayer()))
        on diversityUI close do controlsReady=false
    )
    rollout randomUI "Randomize XYZ" width:#cmdPanel (
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false

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
        label sclTitle "Scale (multiplier)" pos:[8,162] width:146
        label sclMinTitle "Min" pos:[24,184] width:58
        label sclMaxTitle "Max" pos:[94,184] width:58
        label sclXLabel "X" pos:[8,206] width:12
        spinner sclXMinSpin "" range:[0.001,100,1]  pos:[24,204] fieldWidth:46 width:58
        spinner sclXMaxSpin "" range:[0.001,100,1]  pos:[94,204] fieldWidth:46 width:58
        label sclYLabel "Y" pos:[8,230] width:12
        spinner sclYMinSpin "" range:[0.001,100,1]  pos:[24,228] fieldWidth:46 width:58
        spinner sclYMaxSpin "" range:[0.001,100,1]  pos:[94,228] fieldWidth:46 width:58
        label sclZLabel "Z" pos:[8,254] width:12
        spinner sclZMinSpin "" range:[0.001,100,1]  pos:[24,252] fieldWidth:46 width:58
        spinner sclZMaxSpin "" range:[0.001,100,1]  pos:[94,252] fieldWidth:46 width:58
        label wholeTitle "Whole Scale (uniform)" pos:[8,312] width:146
        label wholeMinTitle "Min" pos:[24,334] width:58
        label wholeMaxTitle "Max" pos:[94,334] width:58
        spinner wholeMinSpin "" range:[0.001,1000,1] scale:0.01 pos:[24,356] fieldWidth:46 width:58
        spinner wholeMaxSpin "" range:[0.001,1000,1] scale:0.01 pos:[94,356] fieldWidth:46 width:58
        on wholeMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.wholeScaleMin=v;if v>obj.wholeScaleMax do (obj.wholeScaleMax=v;wholeMaxSpin.value=v);CyrusViewportRedraw())
        on wholeMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.wholeScaleMax=v;if v<obj.wholeScaleMin do (obj.wholeScaleMin=v;wholeMinSpin.value=v);CyrusViewportRedraw())
        label movTitle "Movement (world units)" pos:[8,422] width:146
        label movMinTitle "Min" pos:[24,444] width:58
        label movMaxTitle "Max" pos:[94,444] width:58
        label movXLabel "X" pos:[8,466] width:12
        spinner movXMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[24,464] fieldWidth:46 width:58
        spinner movXMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[94,464] fieldWidth:46 width:58
        label movYLabel "Y" pos:[8,490] width:12
        spinner movYMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[24,488] fieldWidth:46 width:58
        spinner movYMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[94,488] fieldWidth:46 width:58
        label movZLabel "Z" pos:[8,514] width:12
        spinner movZMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[24,512] fieldWidth:46 width:58
        spinner movZMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[94,512] fieldWidth:46 width:58
        checkbox projectCheck "Keep on surface" pos:[8,576] width:146
        checkbox alignCheck "Align to normal" pos:[8,600] width:146

        button resetRotation "Reset rotation" pos:[8,124] width:146 height:20
        button resetScale "Reset XYZ scale" pos:[8,278] width:146 height:20
        button resetWholeScale "Reset whole scale" pos:[8,382] width:146 height:20
        button resetMovement "Reset movement" pos:[8,536] width:146 height:20
        on resetRotation pressed do this.resetSelectedRandomization #rotation
        on resetScale pressed do this.resetSelectedRandomization #scale
        on resetWholeScale pressed do this.resetSelectedRandomization #wholeScale
        on resetMovement pressed do this.resetSelectedRandomization #movement
        fn syncControls = (projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;)
        on alignCheck changed v do if controlsReady and not binding and obj!=undefined do (obj.alignNormal=v;obj.dirty=true;syncControls();CyrusViewportRedraw())

        on projectCheck changed v do if controlsReady and not binding and obj!=undefined do (obj.projectMove=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on rotXMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.rotXMin=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on rotXMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.rotXMax=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on rotYMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.rotYMin=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on rotYMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.rotYMax=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on rotZMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.rotZMin=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on rotZMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.rotZMax=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on sclXMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.sclXMin=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on sclXMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.sclXMax=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on sclYMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.sclYMin=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on sclYMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.sclYMax=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on sclZMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.sclZMin=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on sclZMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.sclZMax=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on movXMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movXMin=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on movXMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movXMax=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on movYMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movYMin=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on movYMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movYMax=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on movZMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movZMin=v;obj.dirty=true;syncControls();CyrusViewportRedraw())
        on movZMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movZMax=v;obj.dirty=true;syncControls();CyrusViewportRedraw())



        fn bind layer = (
            local next=if layer==undefined then this else layer
            binding=true;controlsReady=false
            if obj!=next do ()
            obj=next;parentView=this.mainUI
            for c in randomUI.controls do c.enabled=layer!=undefined
            try (undo off ((wholeMinSpin.value=obj.wholeScaleMin;wholeMaxSpin.value=obj.wholeScaleMax;projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;controlsReady=true;alignCheck.checked=obj.alignNormal))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        on randomUI open do (controlsReady=true;bind (selectedLayer()))
        on randomUI close do controlsReady=false
    )
    rollout spacingUI "Collision / Relax" width:#cmdPanel (
        local binding=false,controlsReady=false,
        obj=undefined,parentView=undefined,ready=false
        checkbox collisionCheck "Enable collision" pos:[8,8] width:120
        spinner radiusSpin "Radius: " pos:[8,34] width:120 fieldWidth:54 type:#worldUnits range:[0.00001,1e9,0.1]
        label radiusHint "Min gap = 2 x radius" pos:[8,62] width:120
        checkbox relaxCheck "Enable relax" pos:[8,94] width:120
        spinner spacingSpin "Spacing: " pos:[8,120] width:120 fieldWidth:54 type:#worldUnits range:[0.00001,1e9,0.2]
        spinner iterationsSpin "Iterations: " pos:[8,146] width:120 fieldWidth:45 type:#integer range:[1,100,10]
        spinner strengthSpin "Strength %: " pos:[8,172] width:120 fieldWidth:45 range:[0,100,50]
        label orderHint "Relax, then collision" pos:[8,202] width:120
        label layerHint "Within this layer only" pos:[8,224] width:146 height:48
        fn syncRelaxAvailability = (
            local wasReady=ready;ready=false
            local layer=this.selectedLayer(),valid=layer!=undefined and obj==layer
            local masked=valid and obj.brushMaskActive(),active=valid and obj.relaxEnabled and not masked
            relaxCheck.checked=valid and obj.relaxEnabled
            -- An already saved paused setting can still be unchecked.
            relaxCheck.enabled=valid and (not masked or obj.relaxEnabled)
            relaxCheck.tooltip="Painted density pauses Relax. Turn off Use painted density to use Relax. Saved settings are preserved."
            spacingSpin.enabled=active;iterationsSpin.enabled=active;strengthSpin.enabled=active
            local message=if masked then "Brush mask active.\nRelax is paused.\nCollision remains available." else "Within this layer only"
            if layerHint.text!=message do layerHint.text=message
            ready=wasReady
        )
        fn syncControls = (
            ready=false
            collisionCheck.checked=obj.collisionEnabled;radiusSpin.value=obj.collisionRadius;radiusSpin.enabled=obj.collisionEnabled
            relaxCheck.checked=obj.relaxEnabled;spacingSpin.value=obj.relaxSpacing;iterationsSpin.value=obj.relaxIterations;strengthSpin.value=obj.relaxStrength*100
            syncRelaxAvailability()
            ready=true
        )
        on collisionCheck changed v do if controlsReady and not binding and obj!=undefined do if ready do (obj.collisionEnabled=v;syncControls();CyrusViewportRedraw())
        on radiusSpin changed v do if controlsReady and not binding and obj!=undefined do if ready do (obj.collisionRadius=v;CyrusViewportRedraw())
        on relaxCheck changed v do if controlsReady and not binding and obj!=undefined do if ready do (undo "Cyrus Relax" on obj.relaxEnabled=(v and not obj.brushMaskActive());syncControls();CyrusViewportRedraw())
        on spacingSpin changed v do if controlsReady and not binding and obj!=undefined do if ready do (obj.relaxSpacing=v;CyrusViewportRedraw())
        on iterationsSpin changed v do if controlsReady and not binding and obj!=undefined do if ready do (obj.relaxIterations=v;CyrusViewportRedraw())
        on strengthSpin changed v do if controlsReady and not binding and obj!=undefined do if ready do (obj.relaxStrength=v/100.0;CyrusViewportRedraw())




        fn bind layer = (
            local next=if layer==undefined then this else layer
            binding=true;controlsReady=false
            if obj!=next do ()
            obj=next;parentView=this.mainUI
            for c in spacingUI.controls do c.enabled=layer!=undefined
            try (undo off (syncControls())) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        on spacingUI open do (controlsReady=true;bind (selectedLayer()))
        on spacingUI close do controlsReady=false
    )
    rollout separationUI "Separation / Final cleanup" width:#cmdPanel (
        local obj=undefined,parentView=undefined,controlsReady=false,refreshing=true
        local blockerRows=#()
        label overlapTitle "Remove Overlaps" pos:[6,8] width:146
        checkbox overlapCheck "Enable" pos:[6,31] width:140
        multiListBox blockerList "Blocking layers (Ctrl/Shift)" pos:[6,55] width:146 height:5
        spinner radiusSpin "Radius: " type:#worldunits range:[0,1000000,10] pos:[6,165] width:146 fieldWidth:62
        spinner gapSpin "Extra gap: " type:#worldunits range:[0,1000000,0] pos:[6,191] width:146 fieldWidth:62
        checkbox planarCheck "Plan XY (ignore height)" checked:true pos:[6,217] width:146
        label overlapInfo "Before / Removed / Left" pos:[6,243] width:146
        label overlapCounts "-- / -- / --" pos:[6,263] width:146
        button statsButton "Update scatter + counts" pos:[6,287] width:146
        dropdownlist radiusMode "Collision radius" items:#("Fixed Radius","Source Radius") pos:[6,317] width:146
        label finalTitle "Final Cleanup / Boundary Relax" pos:[6,372] width:146
        checkbox cleanCheck "Remove isolated points" pos:[6,397] width:146
        spinner neighborSpin "Neighbor radius:" type:#worldunits range:[0.001,1e9,100] pos:[6,424] width:146 fieldWidth:55
        spinner minNeighborSpin "Min neighbors:" type:#integer range:[0,10000,2] pos:[6,451] width:146 fieldWidth:55
        spinner minIslandSpin "Min island size:" type:#integer range:[0,100000,5] pos:[6,478] width:146 fieldWidth:55
        checkbox boundaryRelaxCheck "Boundary Relax (move only)" pos:[6,506] width:146
        spinner finalStrengthSpin "Strength:" range:[0,1,.3] pos:[6,533] width:146 fieldWidth:55
        spinner finalIterSpin "Iterations:" type:#integer range:[0,100,5] pos:[6,560] width:146 fieldWidth:55
        spinner finalMoveSpin "Max movement:" type:#worldunits range:[0,1e9,10] pos:[6,587] width:146 fieldWidth:55
        label relaxHint "" pos:[6,614] width:146 height:48
        fn currentLayer = (if obj.activeLayer>0 and obj.activeLayer<=obj.layerObjects.count then obj.layerObjects[obj.activeLayer] else undefined)
        fn syncFinalRelaxAvailability = (
            local wasRefreshing=refreshing;refreshing=true
            local layer=currentLayer(),valid=layer!=undefined
            local masked=valid and layer.brushMaskActive(),active=valid and layer.finalRelax and not masked
            boundaryRelaxCheck.checked=valid and layer.finalRelax
            boundaryRelaxCheck.enabled=valid and (not masked or layer.finalRelax)
            boundaryRelaxCheck.tooltip="Painted density pauses Boundary Relax. Turn off Use painted density to use it. Final cleanup remains available."
            finalStrengthSpin.enabled=active;finalIterSpin.enabled=active;finalMoveSpin.enabled=active
            local message=if masked then "Brush mask active.\nBoundary Relax is paused.\nFinal cleanup is available." else ""
            if relaxHint.text!=message do relaxHint.text=message
            refreshing=wasRefreshing
        )
        fn refreshOverlap = (
            refreshing=true
            local layer=currentLayer()
            for c in #(overlapCheck,blockerList,radiusSpin,gapSpin,planarCheck,statsButton) do c.enabled=layer!=undefined
            blockerRows=#();local labels=#();local chosen=#{}
            if layer!=undefined do (
                cleanCheck.checked=layer.finalCleanup;neighborSpin.value=layer.finalNeighborRadius;minNeighborSpin.value=layer.finalMinNeighbors;minIslandSpin.value=layer.finalMinIsland
                boundaryRelaxCheck.checked=layer.finalRelax;finalStrengthSpin.value=layer.finalStrength;finalIterSpin.value=layer.finalIterations;finalMoveSpin.value=layer.finalMaxMove
                radiusMode.selection=if layer.overlapSourceRadius then 2 else 1;radiusSpin.enabled=not layer.overlapSourceRadius;overlapCheck.checked=layer.overlapEnabled;radiusSpin.value=layer.overlapRadius;gapSpin.value=layer.overlapGap;planarCheck.checked=layer.overlapPlanar
                for i=1 to obj.layerObjects.count where obj.layerObjects[i]!=layer do (
                    append blockerRows i;append labels (obj.layerNames[i]+(if obj.layerEnabled[i] then "" else " (off)"))
                    if findItem layer.overlapBlockers i>0 do chosen[blockerRows.count]=true
                )
                local stats=layer.overlapStats();overlapCounts.text=(stats[1] as string)+" / "+(stats[2] as string)+" / "+(stats[3] as string)
            )
            blockerList.items=labels;blockerList.selection=chosen
            syncFinalRelaxAvailability();refreshing=false
        )
        fn changedOverlap = (for layer in obj.layerObjects do layer.dirty=true;CyrusViewportRedraw())
        on overlapCheck changed v do if not refreshing do (undo "Remove overlaps" on (currentLayer()).overlapEnabled=v;changedOverlap())
        on radiusMode selected i do if not refreshing do ((currentLayer()).overlapSourceRadius=i==2;changedOverlap())
        on cleanCheck changed v do if not refreshing and currentLayer()!=undefined do (undo "Final cleanup setting" on (currentLayer()).finalCleanup=v;changedOverlap())
        on neighborSpin changed v do if not refreshing and currentLayer()!=undefined do (undo "Final cleanup setting" on (currentLayer()).finalNeighborRadius=v;changedOverlap())
        on minNeighborSpin changed v do if not refreshing and currentLayer()!=undefined do (undo "Final cleanup setting" on (currentLayer()).finalMinNeighbors=v;changedOverlap())
        on minIslandSpin changed v do if not refreshing and currentLayer()!=undefined do (undo "Final cleanup setting" on (currentLayer()).finalMinIsland=v;changedOverlap())
        on boundaryRelaxCheck changed v do if not refreshing and currentLayer()!=undefined do (undo "Final cleanup setting" on (currentLayer()).finalRelax=(v and not (currentLayer()).brushMaskActive());changedOverlap())
        on finalStrengthSpin changed v do if not refreshing and currentLayer()!=undefined do (undo "Final cleanup setting" on (currentLayer()).finalStrength=v;changedOverlap())
        on finalIterSpin changed v do if not refreshing and currentLayer()!=undefined do (undo "Final cleanup setting" on (currentLayer()).finalIterations=v;changedOverlap())
        on finalMoveSpin changed v do if not refreshing and currentLayer()!=undefined do (undo "Final cleanup setting" on (currentLayer()).finalMaxMove=v;changedOverlap())
        on radiusSpin changed v do if not refreshing do (undo "Overlap radius" on (currentLayer()).overlapRadius=v;changedOverlap())
        on gapSpin changed v do if not refreshing do (undo "Overlap gap" on (currentLayer()).overlapGap=v;changedOverlap())
        on planarCheck changed v do if not refreshing do (undo "Overlap distance" on (currentLayer()).overlapPlanar=v;changedOverlap())
        on blockerList selected i do if not refreshing do (
            undo "Blocking layers" on (currentLayer()).overlapBlockers=(for k in blockerList.selection collect blockerRows[k])
            changedOverlap()
        )
        on statsButton pressed do (obj.refreshAll();refreshOverlap())

        fn bind layer = (
            obj=this;parentView=this.mainUI;refreshing=true
            for c in separationUI.controls do c.enabled=layer!=undefined
            refreshOverlap();controlsReady=true;refreshing=false
        )
        on separationUI open do bind (selectedLayer())
        on separationUI close do (controlsReady=false;refreshing=true)
    )

    on update do (
        if version<13 do migrateLayers()
        if version<15 do syncStrokes()
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
    on attachedToNode n do (n.renderable=false;n.wirecolor=red)
    local iconCacheSize=undefined,iconCachePaths=#()
    fn iconLines = (
        if iconCacheSize==iconSize do return iconCachePaths
        local paths=#()
        local ring=for i=0 to 64 collect [cos(i*360.0/64),sin(i*360.0/64),0]
        append paths ring
        -- S outline, composed of two connected semicircular arcs.
        local letterS=#()
        for i=0 to 24 do (local a=i*270.0/24;append letterS [-0.35+0.23*cos(a),0.23+0.23*sin(a),0])
        for i=0 to 24 do (local a=90-i*270.0/24;append letterS [-0.35+0.23*cos(a),-0.23+0.23*sin(a),0])
        append paths letterS
        append paths (for i=0 to 48 collect [0.35+0.25*cos(45+i*270.0/48),0.46*sin(45+i*270.0/48),0])

        iconCachePaths=for path in paths collect (for p in path collect p*iconSize)
        iconCacheSize=iconSize
        iconCachePaths
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
    local held=CyrusInteractionHeld()
    gw.setTransform (matrix3 1)
    for n in objects where (classof n.baseObject==AminScatterObject and not n.isHidden) do (
        gw.setTransform n.objectTransform;gw.setColor #line red
        for path in n.baseObject.iconLines() do gw.polyline path false
        gw.setTransform (matrix3 1)
        local caches=#(),styles=#()
        for entry in n.baseObject.viewportLayerEntries held do (
            local obj=entry[2]
            local cache=obj.previewCache interactionHeld:held
            obj.drawRadii()
            if (obj.showPoints or obj.showCenters) and cache!=undefined do (
                if (obj.viewportMode==1 and CyrusPointEnabled) or (obj.viewportMode==3 and CyrusMeshEnabled) then (append caches cache;append styles #(obj.pointColorMode==1,obj.solidPointColor))
                else aminScatterDrawPreview cache (obj.pointColorMode==1) obj.solidPointColor
            )
        )
        local ready=false,owner=CyrusPointOwner n
        if (CyrusPointEnabled or CyrusMeshEnabled) and isValidNode owner do try(ready=cyrusRetainedMatches owner caches styles)catch(CyrusPointLastError=getCurrentException())
        if not ready do (
            for i=1 to caches.count do aminScatterDrawPreview caches[i] styles[i][1] styles[i][2]
            if caches.count>0 and CyrusPointAvailable and not CyrusPointSuspended do (
                local failed=false
                if isValidNode owner do try(failed=(cyrusRetainedStats owner)[12]==2)catch()
                if failed do CyrusPointLastError="Retained preview unavailable; using legacy preview. Refresh preview to retry."
                if not failed do CyrusPointPending=true
            )
        )
    )
    gw.enlargeUpdateRect #whole
)
registerRedrawViewsCallback AminScatterObjectDraw









-- Native Particle Flow transport. Generated nodes are disposable and never saved.
global CyrusPFNodes=#(),CyrusPFData=#(),CyrusPFBusy=false,CyrusPFSignature="",CyrusPFRevision=0,CyrusPFManualRevision=0
global CyrusPFProduction=false,CyrusPFPhase=0,CyrusPFPendingKey="",CyrusPFStableSince=0
global CyrusPFTimer,CyrusPFResume=false,CyrusPFLastError="",CyrusPFBuilds=0
global AminScatterRenderNodes=#(),AminScatterRenderRestore=#(),AminScatterRenderRedrawHeld=false
try(CyrusPFTimer.Stop())catch()
fn CyrusPFIR = (try(CoronaRenderer.getRenderType()==3)catch(false))
fn CyrusPFRestoreBaked = (
 for item in AminScatterRenderRestore where isValidNode item[1] do item[1].renderable=item[2]
 AminScatterRenderRestore=#()
)
global CyrusPFDeletedHandles=#()
fn CyrusPFClear = (
 CyrusPFDeletedHandles=for n in CyrusPFNodes where isValidNode n collect (getHandleByAnim n)
 CyrusPFBusy=true;AminScatterRenderRedrawHeld=true
 try(undo off (delete (for n in CyrusPFNodes where isValidNode n collect n)))catch()
 CyrusPFNodes=#();CyrusPFData=#();CyrusPFSignature=""
 CyrusPFRestoreBaked()
 AminScatterRenderRedrawHeld=false;CyrusPFBusy=false
)
fn CyrusPFKey = (
 local s=stringStream ""
 with printAllElements on (
  format "%|%|%|" currentTime CyrusPFRevision CyrusPFManualRevision to:s
  for n in objects where classof n.baseObject==AminScatterObject do (
   local r=n.baseObject
   format "Enabled:%|" r.cyrusEnabled to:s
   for layer in r.layerObjects do format "Brush:%:%:%|" layer.paintEnabled layer.paintDensity (layer.paintKey()) to:s
   format "|Edit:%|" (CyrusEditStackKey r) to:s
   format "%|%|%|%|%|" n.handle n.isHidden r.autoRender r.layerEnabled r.updateMode to:s
   for obj in r.layerObjects do format "Analyzer enabled:%|" (not obj.disabledAnalyzerInput()) to:s
   if r.updateMode==2 do (
    format "%|" r.surfaceNodes to:s
    -- Signature polling must never synchronize parameters or invalidate preview.
    for obj in r.layerObjects do (
     if isValidNode obj.areaAnalyzer and (obj.areaUseLine or obj.areaUsePoints) do format "|AnalyzerArea:%|" (obj.areaAnalyzer.getAnalysisRuns()) to:s
     if isValidNode obj.fallAnalyzer and (obj.fallDelete or obj.fallScale or obj.fallDensity) do format "|Falloff:%|" (obj.fallAnalyzer.getAnalysisRuns()) to:s
     if obj.diversityMode==4 and isValidNode obj.analyzerNode do format "|Analyzer:%|" (obj.analyzerNode.getAnalysisRuns()) to:s
     for key in (AminScatterLayerFields+#(#strokeSides,#strokeModes,#strokeColorRows,#strokeColorKeys,#strokeSourceRows,#strokeSourceNodes,#strokeMin,#strokeMax,#analyzerNode)) where isProperty obj key do format "%|" (getProperty obj key) to:s
     for src in obj.sources where isValidNode src do format "%|%|" src.transform src.material to:s
    )
   )
  )
 )
 s as string
)
fn CyrusPFBuild = (
 if CyrusPFBusy do return false
 CyrusPFClear();CyrusPFBusy=true;AminScatterRenderRedrawHeld=true
 local before=objects as array;local links=#()
 disableSceneRedraw()
 try (
  undo off (

   for owner in before where isValidNode owner and classof owner.baseObject==AminScatterObject and not owner.isHidden do (
    local root=owner.baseObject
    for entry in (root.layerEntries includeDisabled:true) do (
     local obj=entry[2];local enabled=root.cyrusEnabled and root.layerEnabled[entry[1]]
     if not enabled or obj.autoRender do for old in obj.bakedNodes where isValidNode old do (
      append AminScatterRenderRestore #(old,old.renderable);old.renderable=false
     )
     local sources=obj.validSources()
     if enabled and obj.autoRender and sources.count>0 and (obj.validSurfaces()).count>0 do (
      local rows=obj.placements sources
      local groups=for src in sources collect #()
      for row in rows do append groups[row[2]] row[1]
      for k=1 to sources.count where groups[k].count>0 do (
       append CyrusPFData groups[k];local slot=CyrusPFData.count
       local prototype=sources[k]
       -- PFlow reads the viewport mesh. Resolve a Corona proxy once per source group,
       -- without changing the user's original proxy display or material settings.
       if (try(classof prototype==CProxy)catch(false)) do (
        prototype=copy prototype;prototype.name="Cyrus_Render_ProxyPrototype"
        prototype.previzType=3;prototype.renderable=false;hide prototype
       )
       local pf=PF_Source name:("Cyrus_Render_"+(owner.handle as string)+"_"+(slot as string)) Quantity_Viewport:100 Quantity_Render:100 Particle_Amount_Limit:(groups[k].count+1) Show_Logo:false Show_Emitter:false
       -- Create PF_Source before beginEdit: otherwise PFlow does not create its PFEngine.
       ParticleFlow.BeginEdit()
       local renderOp=RenderParticles();pf.AppendAction renderOp
       local ev=Event();local birthOp=Birth Emit_Start:animationRange.start Emit_Stop:animationRange.start Amount:groups[k].count
       local shapeOp=Shape_Instance Acquire_Material:true Shape_Object:prototype
       local matOp=Material_Static Material:sources[k].material;matOp.setMaterial sources[k].material
       local body="on ChannelsUsed c do (c.useTM=true;c.useScale=true)\non Init c do ()\non Proceed c do (global CyrusPFData;local a=if CyrusPFData.count>="+(slot as string)+" then CyrusPFData["+(slot as string)+"] else #();for i=1 to (amin (c.NumParticles()) a.count) do (c.particleIndex=i;c.particleTM=a[i];c.particleScaleXYZ=[length a[i].row1,length a[i].row2,length a[i].row3]))\non Release c do ()"
       local scriptOp=Script_Operator Proceed_Script:body
       ev.AppendAction birthOp;ev.AppendAction shapeOp;ev.AppendAction matOp;ev.AppendAction scriptOp
       ParticleFlow.EndEdit()
       append links #(pf,ev);pf.material=sources[k].material;ev.material=sources[k].material
      )
     )
    )
   )
   ParticleFlow.EndEdit()
   for link in links do link[1].appendInitialActionList link[2]
   CyrusPFNodes=for n in objects where findItem before n==0 collect n
   for n in CyrusPFNodes do setUserProp n "CyrusPFTransient" true
   local observed=0;local expected=0
   for a in CyrusPFData do expected+=a.count
   for n in CyrusPFNodes where classof n==PF_Source do (n.updateParticles n currentTime;observed+=n.numParticles())
   if observed!=expected do throw "PFlow did not evaluate the expected number of Cyrus instances."
  )
  CyrusPFSignature=CyrusPFKey();CyrusPFBuilds+=1;CyrusPFLastError=""
 ) catch (
  local reason=getCurrentException();try(ParticleFlow.EndEdit())catch()
  CyrusPFNodes=for n in objects where findItem before n==0 collect n
  CyrusPFClear();CyrusPFLastError=reason
  format "Cyrus PFlow bridge: %\n" reason
 )
 enableSceneRedraw();AminScatterRenderRedrawHeld=false;CyrusPFBusy=false
 CyrusPFLastError==""
)
fn AminScatterRenderBegin = (
 if not CyrusPFBusy do (CyrusPFProduction=true;if CyrusPFKey()!=CyrusPFSignature do if not CyrusPFBuild() do (CyrusPFProduction=false;throw CyrusPFLastError))
)
fn AminScatterRenderEnd = (CyrusPFProduction=false;if not CyrusPFBusy do CyrusPFRestoreBaked())
fn CyrusPFBeforeSceneChange = (
 CyrusPFResume=false;CyrusPFPhase=0
 if CyrusPFIR() do CoronaRenderer.stopRender()
 CyrusPFClear()
)
fn CyrusPFBeforeSave = (
 CyrusPFPhase=0;CyrusPFResume=CyrusPFIR()
 if CyrusPFResume do CoronaRenderer.stopRender()
 CyrusPFClear()
)
fn CyrusPFTickImpl sender args = (
 try (
 if not CyrusPFBusy and not CyrusInteractionHeld() and (not CyrusPFProduction or CyrusPFIR()) do (
  local active=CyrusPFIR();if active do CyrusPFProduction=false
  if CyrusPFPhase==1 then (
   if not active do (if CyrusPFBuild() then CyrusPFPhase=2 else (CyrusPFPhase=0;CyrusPFResume=false))
  ) else if CyrusPFPhase==2 then (
   for n in CyrusPFNodes where isValidNode n and classof n==PF_Source do n.updateParticles n currentTime
   CyrusPFPhase=0;CyrusPFResume=false;CoronaRenderer.startInteractive()
  ) else if active or CyrusPFResume then (
   if CyrusPFNodes.count==0 and not CyrusPFResume and (for n in objects where classof n.baseObject==AminScatterObject collect n).count==0 do return false
   local wanted=CyrusPFKey()
   if wanted!=CyrusPFSignature or CyrusPFResume then (
    if wanted!=CyrusPFPendingKey then (CyrusPFPendingKey=wanted;CyrusPFStableSince=timeStamp())
    else if abs(timeStamp()-CyrusPFStableSince)>=1000 do (
     CyrusPFPhase=1;CyrusPFPendingKey=""
     if active do CoronaRenderer.stopRender()
    )
   ) else CyrusPFPendingKey=""
  ) else if CyrusPFNodes.count>0 do CyrusPFClear()
 )
 ) catch (CyrusPFLastError=getCurrentException();CyrusPFPhase=0;CyrusPFResume=false;format "Cyrus IR update: %\n" CyrusPFLastError)
)
-- Corona start/stop may pump Windows messages; never re-enter this timer.
fn CyrusPFTick sender args = (
 CyrusPFTimer.Stop()
 try(CyrusPFTickImpl sender args)catch(CyrusPFLastError=getCurrentException())
 CyrusPFTimer.Start()
)
callbacks.removeScripts id:#AminScatterAutoRender
callbacks.removeScripts id:#CyrusPFBridge
callbacks.addScript #preRender "AminScatterRenderBegin()" id:#AminScatterAutoRender
callbacks.addScript #postRender "AminScatterRenderEnd()" id:#AminScatterAutoRender
callbacks.addScript #systemPreReset "CyrusPFBeforeSceneChange()" id:#CyrusPFBridge
callbacks.addScript #filePreOpen "CyrusPFBeforeSceneChange()" id:#CyrusPFBridge
callbacks.addScript #filePreSave "CyrusPFBeforeSave()" id:#CyrusPFBridge
CyrusPFTimer=dotNetObject "System.Windows.Forms.Timer";CyrusPFTimer.Interval=750
dotNet.addEventHandler CyrusPFTimer "Tick" CyrusPFTick;CyrusPFTimer.Start()

-- Events mark only controllers whose inputs changed. No geometry polling loop.
global AminScatterNodeEvents
global AminScatterLiveChanged
global AminScatterLiveTime
try(AminScatterNodeEvents.enabled=false)catch()
try(unRegisterTimeCallback AminScatterLiveTime)catch()
global CyrusLiveBatchDepth=0,CyrusLiveBatchRedraw=false,CyrusLiveBatchCount=0,CyrusLiveRedrawRequests=0,CyrusLiveChangeCalls=0
fn CyrusScatterLiveBatchStats = (#(CyrusLiveBatchCount,CyrusLiveRedrawRequests,CyrusLiveBatchDepth,CyrusLiveBatchRedraw,CyrusLiveChangeCalls))
fn CyrusScatterLiveBatchBegin event handles = (
    if CyrusLiveBatchDepth==0 do CyrusLiveBatchRedraw=false
    CyrusLiveBatchDepth+=1
)
fn CyrusScatterLiveBatchEnd event handles = (
    CyrusLiveBatchDepth=amax 0 (CyrusLiveBatchDepth-1)
    if CyrusLiveBatchDepth==0 do (
        CyrusLiveBatchCount+=1
        local wanted=CyrusLiveBatchRedraw
        CyrusLiveBatchRedraw=false
        if wanted and AminScatterRenderRedrawHeld!=true do (CyrusLiveRedrawRequests+=1;CyrusViewportRedraw())
    )
)
fn AminScatterLiveChanged event handles = (
    if CyrusPerfTraceInput!=undefined do try(CyrusPerfTraceInput "scatter_input_received" event handles)catch()
    CyrusLiveChangeCalls+=1
    if event==#deleted do (handles=for h in handles where findItem CyrusPFDeletedHandles h==0 and findItem CyrusPointDeletedHandles h==0 collect h;if handles.count==0 do return false)
    if AminScatterRenderRedrawHeld!=true do (
        local nodes=for h in handles collect (getAnimByHandle h)
        -- Analyzer helper geometry invalidates on selection too. Its data revision
        -- is polled by previewCache/PFKey, so do not treat icon notifications as data.
        nodes=for n in nodes where not (isValidNode n and isProperty n #samplePoints and isProperty n #pathCounts) collect n
        if event!=#deleted and nodes.count==0 do return false
        local redraw=false
        for n in objects where classof n.baseObject==AminScatterObject do (
            for entry in (n.baseObject.layerEntries includeDisabled:true) do (
                if event==#deleted then (entry[2].invalidateLive();redraw=true)
                else if entry[2].externalChanged nodes do (redraw=true;CyrusPFRevision+=1)
            )
        )
        if redraw do (
            if CyrusLiveBatchDepth>0 then CyrusLiveBatchRedraw=true
            else (CyrusLiveRedrawRequests+=1;CyrusViewportRedraw())
        )
    )
)
fn AminScatterLiveTime = (
    if AminScatterRenderRedrawHeld!=true do (
        for n in objects where classof n.baseObject==AminScatterObject do (for entry in (n.baseObject.layerEntries includeDisabled:true) do entry[2].invalidateLive())
        CyrusViewportRedraw()
    )
)
AminScatterNodeEvents=NodeEventCallback mouseUp:true delay:150 callbackBegin:CyrusScatterLiveBatchBegin callbackEnd:CyrusScatterLiveBatchEnd deleted:AminScatterLiveChanged geometryChanged:AminScatterLiveChanged topologyChanged:AminScatterLiveChanged mappingChanged:AminScatterLiveChanged modelStructured:AminScatterLiveChanged controllerOtherEvent:AminScatterLiveChanged controllerStructured:AminScatterLiveChanged linkChanged:AminScatterLiveChanged
registerTimeCallback AminScatterLiveTime




global AminScatterLayerUndo
fn AminScatterLayerUndo = (
    for n in objects where classof n.baseObject==AminScatterObject do (
        for entry in (n.baseObject.layerEntries includeDisabled:true) do entry[2].forcePreviewUpdate()
        if (modPanel.getCurrentObject())==n.baseObject do AminScatterRefreshLayerPanels n.baseObject
    )
    CyrusViewportRedraw()
)
callbacks.removeScripts id:#AminScatterLayers
callbacks.addScript #sceneUndo "AminScatterLayerUndo()" id:#AminScatterLayers persistent:false
callbacks.addScript #sceneRedo "AminScatterLayerUndo()" id:#AminScatterLayers persistent:false


fn CyrusScatterRedIcons = (for n in objects where classof n.baseObject==AminScatterObject do n.wirecolor=red)
callbacks.removeScripts id:#CyrusScatterIconColor
callbacks.addScript #filePostOpen "CyrusScatterRedIcons()" id:#CyrusScatterIconColor
CyrusScatterRedIcons()

try(CyrusReleaseTimer.Stop())catch()
fn CyrusReleaseTick sender args = (
 if CyrusInteractionHeld() then CyrusWasDragging=true
 else if CyrusWasDragging or CyrusPointPending do (CyrusWasDragging=false;CyrusPointPending=false;CyrusViewportRedraw())
)
CyrusReleaseTimer=dotNetObject "System.Windows.Forms.Timer"
CyrusReleaseTimer.Interval=200
dotNet.addEventHandler CyrusReleaseTimer "Tick" CyrusReleaseTick
CyrusReleaseTimer.Start()

fn CyrusPointOwner controller = (
    for pair in CyrusPointOwners where pair[1]==controller and isValidNode pair[2] do return pair[2]
    undefined
)
fn CyrusPointDelete nodes = (
    local live=for n in nodes where isValidNode n collect n
    for n in live do appendIfUnique CyrusPointDeletedHandles (getHandleByAnim n)
    if live.count>0 do (
        local wasDirty=getSaveRequired()
        undo off delete live
        if not wasDirty do setSaveRequired false
    )
)
fn CyrusPointClear = (
    CyrusPointPending=false
    local old=CyrusPointOwners;CyrusPointOwners=#()
    if old!=undefined do CyrusPointDelete (for pair in old collect pair[2])
)
fn CyrusPointSync = (
    if CyrusPointBusy or CyrusPointSuspended or AminScatterRenderRedrawHeld==true or CyrusInteractionHeld() do return false
    CyrusPointBusy=true
    try (
        local publishError=""
        local surviving=#()
        for pair in CyrusPointOwners do (
            if isValidNode pair[1] and classof pair[1].baseObject==AminScatterObject and isValidNode pair[2] then append surviving pair
            else CyrusPointDelete #(pair[2])
        )
        CyrusPointOwners=surviving
        for n in (for node in objects where classof node.baseObject==AminScatterObject collect node) do (
            local caches=#(),styles=#()
            if CyrusPointAvailable and not n.isHidden do for entry in n.baseObject.viewportLayerEntries false do (
                local obj=entry[2],cache=obj.previewCache interactionHeld:false
                if ((obj.viewportMode==1 and CyrusPointEnabled) or (obj.viewportMode==3 and CyrusMeshEnabled)) and (obj.showPoints or obj.showCenters) and cache!=undefined do (
                    append caches cache;append styles #(obj.pointColorMode==1,obj.solidPointColor)
                )
            )
            local owner=CyrusPointOwner n
            if caches.count>0 and not isValidNode owner and cyrusRetainedCreate!=undefined do (
                local wasDirty=getSaveRequired()
                undo off owner=cyrusRetainedCreate()
                if isValidNode owner do (setTransformLockFlags owner #all;append CyrusPointOwners #(n,owner))
                if not wasDirty do setSaveRequired false
            )
            if isValidNode owner do (
                if not cyrusRetainedPublish owner n caches styles do publishError="Retained preview unavailable; using legacy preview. Refresh preview to retry."
            )
        )
        CyrusPointLastError=publishError
    )catch(CyrusPointLastError=getCurrentException())
    CyrusPointBusy=false
    true
)
fn CyrusViewportRedraw = (
    if not CyrusPointBusy do CyrusPointSync()
    redrawViews()
)
fn CyrusPointBeforeSave = (CyrusPointSuspended=true;CyrusPointClear())
fn CyrusPointAfterSave = (CyrusPointSuspended=false;CyrusPointPending=true)
fn CyrusPointBeforeScene = (CyrusPointSuspended=true;CyrusPointClear())
fn CyrusPointAfterScene = (CyrusPointSuspended=false;CyrusPointDeletedHandles=#();CyrusPointPending=true)
-- Session-only A/B switch. Scene data and placement caches are unchanged.
fn CyrusRetainedPointDrawing enabled = (
    CyrusPointEnabled=enabled;CyrusPointLastError=""
    CyrusPointAvailable=try(cyrusRetainedAvailable())catch(false)
    CyrusViewportRedraw()
    CyrusPointEnabled
)
fn CyrusRetainedMeshDrawing enabled = (
    CyrusMeshEnabled=enabled;CyrusPointLastError=""
    CyrusPointAvailable=try(cyrusRetainedAvailable())catch(false)
    CyrusViewportRedraw()
    CyrusMeshEnabled
)
callbacks.removeScripts id:#CyrusRetainedPoints
callbacks.addScript #filePreSaveProcess "CyrusPointBeforeSave()" id:#CyrusRetainedPoints
callbacks.addScript #filePostSaveProcess "CyrusPointAfterSave()" id:#CyrusRetainedPoints
callbacks.addScript #filePreOpenProcess "CyrusPointBeforeScene()" id:#CyrusRetainedPoints
callbacks.addScript #systemPreReset "CyrusPointBeforeScene()" id:#CyrusRetainedPoints
callbacks.addScript #systemPreNew "CyrusPointBeforeScene()" id:#CyrusRetainedPoints
callbacks.addScript #filePostOpenProcess "CyrusPointAfterScene()" id:#CyrusRetainedPoints
callbacks.addScript #systemPostReset "CyrusPointAfterScene()" id:#CyrusRetainedPoints
callbacks.addScript #systemPostNew "CyrusPointAfterScene()" id:#CyrusRetainedPoints
CyrusPointAvailable=try(cyrusRetainedAvailable())catch(false)
CyrusPointPending=true

CyrusScatterObject=AminScatterObject
-- Session scheduling observes only the active Brush. Idle viewport drawing
-- does not scan documents, pick meshes, replay strokes or upload buffers.
global CyrusBrushSessionRoot,CyrusBrushSessionLayer,CyrusBrushSessionRevision=0,CyrusBrushTimer,CyrusBrushBusy=false
global CyrusStartBrush,CyrusStopBrush,CyrusBrushTick
fn CyrusStopBrush = (
    cyrusBrushStop()
    local root=CyrusBrushSessionRoot,layer=CyrusBrushSessionLayer
    CyrusBrushSessionRoot=undefined;CyrusBrushSessionLayer=undefined
    if layer!=undefined do layer.checkPaintRevision()
    if root!=undefined do root.bindNativeUI()
    CyrusViewportRedraw()
)
fn CyrusStartBrush root layer = (
    CyrusStopBrush()
    if layer==undefined or layer.paintDocument==undefined do throw "Pick a Brush receiving surface first."
    cyrusBrushBegin layer.paintDocument
    CyrusBrushSessionRoot=root;CyrusBrushSessionLayer=layer;CyrusBrushSessionRevision=0
    cyrusBrushRefreshMask layer.paintDocument;redrawViews()
)
fn CyrusBrushTick sender args = (
    if CyrusBrushBusy or CyrusBrushSessionLayer==undefined do return false
    CyrusBrushBusy=true
    try (
        local layer=CyrusBrushSessionLayer,root=CyrusBrushSessionRoot,state=cyrusBrushStats layer.paintDocument
        if state[1]!=CyrusBrushSessionRevision do (
            cyrusBrushRefreshMask layer.paintDocument
            CyrusBrushSessionRevision=state[1]
            if state[6]==0 then (layer.checkPaintRevision();CyrusViewportRedraw()) else redrawViews()
            if root.brushUI.controlsReady do (root.brushUI.refreshHistory();root.brushUI.status())
        )
        if state[5]==0 do (
            layer.checkPaintRevision()
            if root.brushUI.controlsReady do root.brushUI.status()
            CyrusBrushSessionLayer=undefined;CyrusBrushSessionRoot=undefined
        )
    ) catch (
        local failure=getCurrentException()
        cyrusBrushStop();CyrusBrushSessionLayer=undefined;CyrusBrushSessionRoot=undefined
        format "Cyrus Brush: %\n" failure
    )
    CyrusBrushBusy=false
)
try(CyrusBrushTimer.Stop())catch()
CyrusBrushTimer=dotNetObject "System.Windows.Forms.Timer"
CyrusBrushTimer.Interval=150
dotNet.addEventHandler CyrusBrushTimer "Tick" CyrusBrushTick
CyrusBrushTimer.Start()
callbacks.removeScripts id:#CyrusBrushSession
callbacks.addScript #filePreOpen "CyrusStopBrush()" id:#CyrusBrushSession
callbacks.addScript #systemPreReset "CyrusStopBrush()" id:#CyrusBrushSession
