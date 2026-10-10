-- Only registered Scatter nodes participate in timeline notifications. This
-- registry is rebuilt at scene boundaries, never by scanning every animation frame.
global AminScatterObject,CyrusSourceContainer,CyrusContainerRefreshLabels
global CyrusTimeOwners=#(),CyrusRegisterTimeOwner,CyrusResetTimeOwners,CyrusPruneTimeOwners
fn CyrusRegisterTimeOwner node = (
    if isValidNode node and classof node.baseObject==AminScatterObject do appendIfUnique CyrusTimeOwners node
)
fn CyrusPruneTimeOwners = (
    CyrusTimeOwners=for node in CyrusTimeOwners where isValidNode node and classof node.baseObject==AminScatterObject collect node
)
fn CyrusResetTimeOwners = (
    CyrusTimeOwners=for node in objects where classof node.baseObject==AminScatterObject collect node
)

global CyrusDiagnosticEmit
fn CyrusDiagnosticEmit event origin owner epoch detail = (
    if cyrusDiagnosticActive!=undefined do try (
        if cyrusDiagnosticActive() do cyrusDiagnosticEvent event origin owner epoch detail
    )catch()
    undefined
)
global CyrusPerfTraceBegin,CyrusPerfTraceEnd,CyrusPerfTraceInput
-- Callbacks only request deferred work. No idle signature/scene polling.
global CyrusScheduleRelease,CyrusScheduleUI,CyrusPFRequestCheck,CyrusRenderNodeChanged
global CyrusPFCheckPending=false,CyrusPFResumeMode=3,CyrusPFTicking=false
global CyrusReleaseTimer,CyrusPFTimer,CyrusPFBusy,CyrusLayerEditor,CyrusPointPending,AminScatterObject
global CyrusPFStopIR,CyrusPFLastError
-- Corona stop can pump messages and deliver nested host callbacks. Keep bridge
-- mutation excluded through the stop, and verify the resulting render state.
-- A nonzero return alone cannot distinguish a nested/already-stopped request.
-- The optional provider exists for deterministic failure/reentrancy fixtures.
fn CyrusPFStopIR renderer:undefined = (
    if CyrusPFBusy==true do (CyrusPFLastError="Corona Stop deferred while the Cyrus bridge is busy.";return false)
    if renderer==undefined do renderer=CoronaRenderer
    local previousBusy=CyrusPFBusy,stopped=false
    CyrusPFBusy=true
    try (
        local before=renderer.getRenderType()
        if before==0 then stopped=true
        else if findItem #(2,3) before>0 then (
            CyrusDiagnosticEmit "ir.stop_requested" "renderer" "" 0 "bridge"
            local result=renderer.stopRender(),after=renderer.getRenderType()
            CyrusDiagnosticEmit "ir.stop_result" "renderer" "" 0 ((result as string)+":"+(after as string))
            stopped=after==0
            if not stopped do CyrusPFLastError="Corona IR remains active after Stop (status "+(result as string)+", render type "+(after as string)+")."
        ) else CyrusPFLastError="Corona render is not an interactive session; its bridge was preserved."
    )catch(CyrusPFLastError=getCurrentException())
    CyrusPFBusy=previousBusy
    stopped
)
fn CyrusScheduleRelease = (
    if CyrusReleaseTimer!=undefined do CyrusReleaseTimer.Start()
)
fn CyrusScheduleUI = (
    if CyrusLayerEditor!=undefined do CyrusLayerEditor.statusTimer.active=true
    local obj=try(modPanel.getCurrentObject())catch(undefined)
    if obj!=undefined and (classof obj==AminScatterObject or classof obj==CyrusSourceContainer) and obj.mainUI.controlsReady do obj.mainUI.statusTimer.active=true
)
fn CyrusPFRequestCheck = (
    if CyrusPFBusy!=true do (
        CyrusPFCheckPending=true
        if CyrusPFTimer!=undefined and not CyrusPFTicking do CyrusPFTimer.Start()
    )
)
fn CyrusRenderNodeChanged event handles = (
    if CyrusPFBusy==true do return false
    local nodes=for h in handles collect (getAnimByHandle h),relevant=false
    for n in nodes where isValidNode n do (
        if classof n.baseObject==AminScatterObject then (
            CyrusScheduleUI()
            if event==#hideChanged do (relevant=true;(CyrusPointPending=true;CyrusScheduleRelease()))
        ) else if classof n.baseObject==CyrusSourceContainer and event==#nameChanged then CyrusContainerRefreshLabels undefined
        else if event!=#nameChanged and event!=#hideChanged do (
            for owner in objects where classof owner.baseObject==AminScatterObject do
                for leaf in owner.baseObject.layerObjects where findItem leaf.sources n>0 do relevant=true
        )
    )
    if relevant do CyrusPFRequestCheck()
    true
)

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
AminScatterLayerFields=#(#procOrder,#procSetOrder,#procSamplingSalt,#procPopulation,#procAttemptFactor,#procRounds,#procRepair,#procSelfOverride,#procSelfEnabled,#procSelfMultiplier,#procSelfGap,#procSelfPlanar,#procLayerSelfEnabled,#procLayerSelfMultiplier,#procLayerSelfGap,#procLayerSelfPlanar,#procSiblingEnabled,#procSiblingMultiplier,#procSiblingGap,#procSiblingPlanar,#procBackground,#procBackgroundIDs,#procRadiusIDs,#procRadiusModes,#procRadiusValues,#procRadiusBinding,#procSourceNodes,#procSourceIDs,#procSourceSlots,#procReceiverNodes,#procReceiverIDs,#procReceiverID,#containerMode,#containerNodes,#logicalParentID,#paintSetName,#paintSetWeight,#paintSetEnabled,#paintSetVisible,#paintView,#paintColor,#paintDocument,#paintEnabled,#paintDensity,#streetTrimStart,#streetTrimEnd,#centerStreetOffset,#areaAnalyzer,#areaUseLine,#areaLineWidth,#areaLineCaps,#areaUsePoints,#areaPointRadius,#wholeScaleMin,#wholeScaleMax,#fallScaleGraph,#fallDensityGraph,#areaFallConfigs,#areaFallScaleGraphs,#areaFallDensityGraphs,#fallAnalyzer,#fallDelete,#fallDeleteWidth,#fallScale,#fallScaleWidth,#fallScaleCurve,#fallDensity,#fallDensityWidth,#fallDensityCurve,#edgeRotX,#edgeRotY,#edgeRotZ,#edgeKeepCorners,#edgeCornerAngle,#edgeCornerCount,#edgeFaceOut,#edgeCornerRadius,#edgeOffsets,#edgeAlong,#edgeAcross,#borderFaceOut,#streetFaceOut,#borderCornerRadius,#streetCornerRadius,#sourceForwardAxes,#finalCleanup,#finalNeighborRadius,#finalMinNeighbors,#finalMinIsland,#finalRelax,#finalStrength,#finalIterations,#finalMaxMove,#sourceRadii,#sourceFollowScale,#sourceShowRadius,#streetStraight,#sourcePoint,#sourceEmpty,#cleanupPlanar,#sourceZOffsets,#sourceScales,#sourceWeights,#showCenters,#relaxEnabled,#relaxSpacing,#relaxIterations,#relaxStrength,#sources,#bakedNodes,#amount,#randomSeed,#scaleMinimum,#scaleMaximum,#tiltDegrees,#yawMinimum,#yawMaximum,#movementRange,#alignNormal,#showPoints,#pointsPerPlant,#updateMode,#populationMode,#plantsPerM2,#advancedAxes,#projectMove,#rotXMin,#rotXMax,#rotYMin,#rotYMax,#rotZMin,#rotZMax,#sclXMin,#sclXMax,#sclYMin,#sclYMax,#sclZMin,#sclZMax,#movXMin,#movXMax,#movYMin,#movYMax,#movZMin,#movZMax,#distributionMode,#clusterCount,#clusterRadius,#densityMap,#invertDensity,#diversityMode,#diversitySize,#diversitySeed,#roughness,#blurryEdge,#diversityNoise,#autoRender,#previewBudget,#pointColorMode,#solidPointColor,#areaNodes,#areaModes,#sourceColors,#patternLines,#patternWidths,#patternGroups,#patternRestGroup)
AminScatterLayerTabs=#(#procBackgroundIDs,#procRadiusIDs,#procRadiusModes,#procRadiusValues,#procSourceNodes,#procSourceIDs,#procSourceSlots,#procReceiverNodes,#procReceiverIDs,#containerNodes,#areaFallConfigs,#areaFallScaleGraphs,#areaFallDensityGraphs,#fallScaleCurve,#fallDensityCurve,#edgeRotX,#edgeRotY,#edgeRotZ,#edgeOffsets,#edgeAlong,#edgeAcross,#sourceForwardAxes,#sourceRadii,#sourceFollowScale,#sourceShowRadius,#sourcePoint,#sourceEmpty,#sourceZOffsets,#sourceScales,#sourceWeights,#sources,#bakedNodes,#areaNodes,#areaModes,#sourceColors,#patternLines,#patternWidths,#patternGroups)
fn AminScatterCopyLayer origin destination = (
    origin.procAssertSchema()
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
        for key in #(#visualSourceNodes,#visualSourceLabels,#visualSourceColors,#visualSourceColorSet) do setProperty destination key ((getProperty origin key) as array)
        destination.layerIDColor=origin.layerIDColor
        destination.ownsReceivers=origin.ownsReceivers;destination.areaMode=origin.areaMode
        destination.paintAreas=#();destination.uiAreaID=""
        for area in origin.paintAreas do (
            local duplicate=createInstance AminScatterObject
            duplicate.isPaintArea=true;duplicate.layerID=CyrusNewLayerID();duplicate.logicalParentID=destination.layerID
            duplicate.areaTarget=area.areaTarget;duplicate.paintSetName=area.paintSetName
            duplicate.paintSetEnabled=area.paintSetEnabled;duplicate.paintEnabled=true
            duplicate.paintDensity=area.paintDensity;duplicate.paintView=area.paintView;duplicate.paintColor=area.paintColor
            if area.paintDocument!=undefined do duplicate.paintDocument=copy area.paintDocument
            append destination.paintAreas duplicate
        )
        destination.setLayerTransfer false
    ) catch(destination.setLayerTransfer false;throw())
)
fn AminScatterRefreshLayerPanels obj reopen:true = (obj.bindNativeUI())
global CyrusEditStackKey,CyrusEditApplyLayer
fn CyrusEditStackKey root = (root.procEditKey())
fn CyrusEditApplyLayer root layer rows = (
 if root==undefined do return rows
 local owners=for n in refs.dependentNodes root where n.baseObject==root collect n
 if owners.count==0 do return rows
 local mods=owners[1].modifiers
 local active=for m in mods where classof m==CyrusScatterEdit and m.enabled collect m
 if active.count==0 do return rows
 local index=if layer.editLayerKey>0 then layer.editLayerKey else findItem root.layerObjects layer
 local signature=layer.procBindingKey
 cyrusEditStack active rows index signature true true
)

global CyrusFlowRolloutExtent,CyrusFlowLayerSummary
global CyrusRetainListItems
fn CyrusRetainListItems control values = (
    local previous=control.items,changed=previous.count!=values.count
    if not changed do for i=1 to values.count while not changed do changed=previous[i]!=values[i]
    if changed do control.items=values
    changed
)
global CyrusSourceContainer,CyrusContainerPanel,CyrusContainerRefreshAll,CyrusContainerRefreshPresentation,CyrusContainerRefreshLabels,CyrusSourceContainerFilter
fn CyrusSourceContainerFilter node = (isValidNode node and (classof node.baseObject==CyrusSourceContainer or classof node.baseObject==Rectangle) and node.modifiers.count==0 and (not isProperty node #cornerRadius or node.cornerRadius==0))
-- Native rollup headers occupy 21 logical pixels with 2 pixels between pages.
-- Body heights remain MAXScript logical units; automatic layout applies DPI.
fn CyrusFlowRolloutExtent r = (23+(if r.open then r.height else 0))
fn CyrusFlowLayerSummary root parent = (
    local placed=0,shown=0,pending=false,failed=false,index=findItem root.layerObjects parent
    for leaf in root.layerSets parent do (
        local state=leaf.uiLayerStats()
        if state.hasResult do (placed+=state.placements;shown+=state.previewCount)
        pending=pending or state.needsUpdate;failed=failed or state.errorText!=""
    )
    local status=if failed then "Error" else if index==0 or not root.layerEnabled[index] then "Disabled" else if not root.layerVisible[index] then "Hidden" else if pending then "Pending" else "Cached"
    #(placed,shown,status)
)

global CyrusLayerUIRoot,CyrusLayerUIOwner,CyrusLayerUIPanel,CyrusCreateLayerEditorSection
global CyrusLayerEditor_setsUI_1
fn CyrusLayerEditor_setsUI_1 = (
    rollout setsUI_1 "Paint sets" width:146 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel,controlsReady=false,binding=false,members=#()
        dropdownlist setList "Edit set" items:#() pos:[4,8] width:(setsUI_1.width-8)
        button addButton "Add set" pos:[4,60] width:((setsUI_1.width-12)/2) tooltip:"Add another paint set sharing this layer's population and defaults."
        button removeButton "Remove" pos:[(setsUI_1.width/2+2),60] width:((setsUI_1.width-12)/2) tooltip:"Remove this paint set and its settings. The base set cannot be removed separately."
        edittext nameEdit "Name:" pos:[4,90] width:(setsUI_1.width-8) tooltip:"Rename this paint set without changing its identity."
        spinner weightSpin "Share weight:" pos:[4,120] width:(setsUI_1.width-8) fieldWidth:82 range:[0,10000,1] tooltip:"Relative share of the layer population among enabled paint sets."
        checkbox enabledCheck "Enable set" pos:[4,148] width:(setsUI_1.width-8) tooltip:"Include this set in calculation and final output."
        checkbox visibleCheck "Show set" pos:[4,172] width:(setsUI_1.width-8) tooltip:"Viewport visibility only. Hidden sets still calculate and affect spacing."
        button upButton "Move up" pos:[4,200] width:((setsUI_1.width-12)/2) tooltip:"Evaluate this set earlier. Earlier sets occupy space first."
        button downButton "Move down" pos:[(setsUI_1.width/2+2),200] width:((setsUI_1.width-12)/2) tooltip:"Evaluate this set later, after the preceding sets."
        label info "Layers own surfaces, models and population. Paint Areas optionally restrict where the layer scatters." pos:[4,232] width:(setsUI_1.width-8) height:76
        fn currentSet = (root.selectedPaintSet owner)
        fn bind layer = (
            binding=true;members=root.layerSets owner
            local leaf=currentSet()
            CyrusRetainListItems setList (for member in members collect member.paintSetName)
            setList.selection=findItem members leaf
            nameEdit.text=leaf.paintSetName;weightSpin.value=leaf.paintSetWeight
            enabledCheck.checked=leaf.paintSetEnabled;visibleCheck.checked=leaf.paintSetVisible
            removeButton.enabled=leaf!=owner;addButton.enabled=true and root.layerObjects.count<10
            upButton.enabled=true and findItem members leaf>1;downButton.enabled=true and findItem members leaf<members.count
            controlsReady=true;binding=false
        )
        on setsUI_1 open do bind owner
        on setsUI_1 close do controlsReady=false
        fn selectSet i = (
            if binding or i<1 or i>members.count or (currentSet())==members[i] do return false
            CyrusStopBrush();owner.uiPaintSetID=members[i].layerID;panel.bindEditors();true
        )
        on setList selected i do selectSet i
        -- These model operations already refresh the native and popup views.
        -- They can close/rebind this rollout; do not read its locals afterwards.
        on addButton pressed do try(root.addPaintSet owner label:("Paint "+(((root.layerSets owner).count+1) as string)))catch(messageBox (getCurrentException()) title:"Cyrus paint set")
        on removeButton pressed do try(root.removePaintSet (currentSet()))catch(messageBox (getCurrentException()) title:"Cyrus paint set")
        on nameEdit entered value do if not binding and value!="" do (undo "Cyrus set name" on (currentSet()).paintSetName=value;panel.bindEditors())
        on weightSpin changed value do if not binding do (undo "Cyrus set weight" on (currentSet()).paintSetWeight=value;root.invalidateGroups())
        on enabledCheck changed value do if not binding do (undo "Cyrus set enabled" on (currentSet()).paintSetEnabled=value;root.invalidateGroups())
        on visibleCheck changed value do if not binding do (undo "Cyrus set visible" on (currentSet()).paintSetVisible=value;root.procSyncEditVisibility();CyrusViewportRedraw())
        on upButton pressed do try(root.procMove (currentSet()) -1 sets:true)catch(messageBox (getCurrentException()) title:"Cyrus order")
        on downButton pressed do try(root.procMove (currentSet()) 1 sets:true)catch(messageBox (getCurrentException()) title:"Cyrus order")
        on setsUI_1 rolledUp state do (CyrusContainerPanel root).layoutPanels()
    )

setsUI_1
)
global CyrusLayerEditor_sourceUI_1
fn CyrusLayerEditor_sourceUI_1 = (
    rollout sourceUI_1 "Models and settings - layer" width:132 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel
        local setSpecific=true
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false

        local groupPalette=#()
        local loadingColor=false
        local focusedRow=0
        edittext sourceName "Name:" text:"" pos:[4,116] width:(sourceUI_1.width-8) tooltip:"Label inside Scatter only. Clear it to use the scene object's name."
        colorpicker idColor "" color:(color 100 220 120) pos:[4,118] width:22 height:22 modal:true notifyAfterAccept:true tooltip:"Viewport identification color. This does not change clustering or model frequency."
        multiListBox plantList "Sources (Ctrl/Shift)" items:#() pos:[4,8] height:6 width:(sourceUI_1.width-8)
        button selectFromScene "Choose from list..." pos:[4,170] width:((sourceUI_1.width-12)/2) tooltip:"Choose one or more source models by name."
        pickbutton addPlant "Pick model" pos:[4,140] width:((sourceUI_1.width-12)/2) tooltip:"Pick a scene model for this layer. The editor stays on its layer."
        button addSelected "Add selection" pos:[(sourceUI_1.width/2+2),140] width:((sourceUI_1.width-12)/2) tooltip:"Add the currently selected scene objects to this layer."
        button removePlant "Remove rows" pos:[4,200] width:(sourceUI_1.width-8) tooltip:"Unregister highlighted rows. To keep their settings, park models outside a source rectangle instead."
        button selectPlant "Select sources" pos:[(sourceUI_1.width/2+2),170] width:((sourceUI_1.width-12)/2) tooltip:"Select the highlighted source models in the scene."
        button addPoint "Add Point" pos:[4,460] width:((sourceUI_1.width-12)/2) tooltip:"Add a placeholder source that can later be replaced by a model."
        button addEmpty "Add Empty" pos:[(sourceUI_1.width/2+2),460] width:((sourceUI_1.width-12)/2) tooltip:"Add a weighted empty source for intentional gaps in candidate-budget mode."
        pickbutton replacePoint "Replace Point: pick object" filter:AminScatterSourceFilter pos:[4,490] width:(sourceUI_1.width-8) tooltip:"Replace one highlighted Point row with a scene model."
        label groupHeading "Cluster color group" pos:[4,530] width:(sourceUI_1.width-8)
        dropdownlist existingGroups "Reuse a group" items:#() pos:[4,552] width:(sourceUI_1.width-8) tooltip:"Assign highlighted sources to an existing color group for clustering."
        colorpicker groupColor "Color: " color:(color 100 220 120) pos:[4,606] width:(sourceUI_1.width-8) modal:true notifyAfterAccept:true tooltip:"Assign a color group to highlighted sources when the color is accepted."
        button applyColor "Apply to selected rows" pos:[4,634] width:(sourceUI_1.width-8) tooltip:"Assign the chosen color group to all highlighted source rows."
        label colorHelp "OK saves the selected color." pos:[4,664] width:(sourceUI_1.width-8)
        spinner weightSpin "Weight: " range:[0,1,1] scale:0.01 pos:[4,236] width:((sourceUI_1.width-12)/2) fieldWidth:82 tooltip:"Relative model frequency in this layer. Zero disables the model."
        label weightHelp "0 = off; relative share" pos:[4,378] width:(sourceUI_1.width-8)
        spinner sourceZSpin "Z Offset: " range:[-1000000,1000000,0] type:#worldunits pos:[4,266] width:((sourceUI_1.width-12)/2) fieldWidth:82 tooltip:"Offset instances of highlighted models along their placement normal."
        spinner sourceScaleSpin "Scale: " range:[0,10000,1] scale:0.01 pos:[(sourceUI_1.width/2+2),236] width:((sourceUI_1.width-12)/2) fieldWidth:82 tooltip:"Per-model scale multiplier. 1 keeps the model's original scale."
        label sourceTransformHelp "Scale: 1 = original" pos:[4,398] width:(sourceUI_1.width-8)
        spinner radiusSourceSpin "Radius:" type:#worldunits range:[0,1e9,0] pos:[(sourceUI_1.width/2+2),266] width:((sourceUI_1.width-12)/2) fieldWidth:82 tooltip:"Collision footprint radius for highlighted source rows, in scene units."
        checkbox followRadiusCheck "Follow Scale" pos:[4,294] width:((sourceUI_1.width-12)/2) tooltip:"Scale this source's collision footprint with its instance scale."
        checkbox showRadiusCheck "Show Radius" pos:[(sourceUI_1.width/2+2),294] width:((sourceUI_1.width-12)/2) tooltip:"Show this source's radius in the viewport; does not change collision rules."
        dropdownlist forwardAxis "Forward axis:" items:#("+Y","-Y","+X","-X") pos:[4,326] width:(sourceUI_1.width-8) tooltip:"The model's local forward direction, used for orientation."
        fn colorLabel c = ("#"+(formattedPrint (obj.colorKey c) format:"06X"))
        fn updateList = (
            local selectedRows=plantList.selection
            if selectedRows.numberSet==0 and obj.sources.count>0 do selectedRows=#{1}
            plantList.items=for i=1 to obj.sources.count collect ((obj.sourceLabel i)+" | "+(formattedPrint (obj.sourceWeight i) format:".2f"))
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
                obj.syncColors();while obj.sourceEmpty.count<obj.sources.count do append obj.sourceEmpty false;append obj.sourceEmpty false;append obj.sources n;append obj.sourceColors groupColor.color;if obj.sourceWeights.count>0 do append obj.sourceWeights 1.0;if obj.sourceZOffsets.count>0 do append obj.sourceZOffsets 0.0;if obj.sourceScales.count>0 do append obj.sourceScales 1.0;obj.markInputDirty()
            )
        )

        fn showSelectedColor = (
            local rows=plantList.selection
            weightSpin.enabled=rows.numberSet>0;sourceZSpin.enabled=rows.numberSet>0;sourceScaleSpin.enabled=rows.numberSet>0;forwardAxis.enabled=rows.numberSet>0
            if rows.numberSet>0 then (
                if focusedRow<1 or not rows[focusedRow] do focusedRow=(rows as array)[1]
                loadingColor=true
                sourceName.text=obj.sourceLabel focusedRow;idColor.color=obj.sourceIDColor focusedRow
                sourceName.enabled=isValidNode obj.sources[focusedRow];idColor.enabled=sourceName.enabled
                groupColor.color=obj.sourceColor focusedRow
                weightSpin.enabled=true;weightSpin.value=obj.sourceWeight focusedRow
                radiusSourceSpin.value=obj.sourceRadius focusedRow;followRadiusCheck.checked=obj.sourceFollows focusedRow;showRadiusCheck.checked=obj.sourceShows focusedRow;sourceZSpin.value=obj.sourceZOffset focusedRow;sourceScaleSpin.value=obj.sourceScale focusedRow;forwardAxis.selection=obj.sourceForward focusedRow
                existingGroups.selection=findItem groupPalette (obj.sourceColor focusedRow)
                loadingColor=false
            ) else (
                sourceName.text="";sourceName.enabled=false;idColor.enabled=false
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
        on sourceName entered value do if not loadingColor and focusedRow>0 do (obj.setSourceLabel focusedRow value;updateList())
        on idColor changed value do if not loadingColor do (obj.setSourceIDColor plantList.selection value;updateList())
        on addPoint pressed do if controlsReady and not binding and obj!=undefined do (
            local i=obj.addPointSource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();CyrusViewportRedraw()
        )
        on replacePoint picked n do if controlsReady and not binding and obj!=undefined do (
            local rows=plantList.selection as array
            if rows.count!=1 then messageBox "Select one Point row to replace." title:"Cyrus Scatter"
            else if not (obj.replacePointSource rows[1] n) do messageBox "Select a Point row and an object that is not already in this set's source list." title:"Cyrus Scatter"
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
            plantList.selection=#{};obj.markInputDirty();updateList();CyrusViewportRedraw()
        )
        on selectPlant pressed do if controlsReady and not binding and obj!=undefined do (
            local nodes=for i in plantList.selection where i<=obj.sources.count and isValidNode obj.sources[i] collect obj.sources[i]
            if nodes.count>0 do select nodes
        )




        fn bindFeatures layer = (
            local next=layer
            binding=true;controlsReady=false
            if obj!=next do (plantList.selection=#{};)
            obj=next;parentView=(CyrusContainerPanel root)
            for c in sourceUI_1.controls do c.enabled=layer!=undefined
            try (undo off ((controlsReady=true;(updateList();showSelectedColor())))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        checkbutton detailsToggle "Point / Empty sources and color groups" pos:[4,426] width:(sourceUI_1.width-8) height:26 tooltip:"Show or hide these advanced controls; their saved settings are preserved."
        fn arrangeDetails = (
            for c in #(addPoint,addEmpty,replacePoint,groupHeading,existingGroups,groupColor,applyColor,colorHelp) do c.visible=detailsToggle.checked
            sourceUI_1.height=if detailsToggle.checked then 692 else 460
        )
        fn bind layer = (bindFeatures layer;arrangeDetails())
        on detailsToggle changed value do arrangeDetails()
        on sourceUI_1 open do (controlsReady=true;bind (if setSpecific then root.selectedPaintSet owner else owner))
        on sourceUI_1 close do controlsReady=false
        on sourceUI_1 rolledUp state do (CyrusContainerPanel root).layoutPanels()
    )
sourceUI_1
)
global CyrusLayerEditor_sourceContainersUI_1
fn CyrusLayerEditor_sourceContainersUI_1 = (
    rollout sourceContainersUI_1 "Source containers - own / inherited" width:146 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel,controlsReady=false,binding=false,setSpecific=true,modes=#()
        dropdownlist modeList "Source pool" items:#() pos:[4,8] width:(sourceContainersUI_1.width-8) tooltip:"Use the model list directly, or optionally collect models from source rectangles."
        listbox containersList "Rectangles" items:#() pos:[4,60] width:(sourceContainersUI_1.width-8) height:4
        button createContainer "Create container" pos:[4,154] width:(sourceContainersUI_1.width-8) tooltip:"Create a Rectangle for this owner. Put source-model pivots inside its local XY bounds."
        pickbutton pickContainer "Pick boundary" filter:CyrusSourceContainerFilter pos:[4,184] width:(sourceContainersUI_1.width-8) tooltip:"Link a Cyrus container, or copy a square-corner Rectangle into a container. The original spline is preserved."
        button removeContainer "Unlink selected rectangle" pos:[4,214] width:(sourceContainersUI_1.width-8) tooltip:"Unlink this rectangle without deleting it or registered source settings."
        label membershipInfo "Manual source list." pos:[4,244] width:(sourceContainersUI_1.width-8) height:48
        label helpInfo "Pivot inside = active. Height is ignored. Moving out keeps source settings. Manual needs Update." pos:[4,286] width:(sourceContainersUI_1.width-8) height:44
        fn currentSet = root.selectedPaintSet owner
        fn bind layer = (
            binding=true
            local leaf=currentSet(),active=true,own=leaf.logicalParentID==""
            modes=if own then #(1,3,4) else #(1,2,3,4)
            modeList.items=if own then #("Manual sources","Global containers","Layer containers") else #("Manual sources","Layer default","Global containers","This set's containers")
            modeList.selection=amax 1 (findItem modes leaf.containerMode)
            local nodes=leaf.effectiveContainers()
            containersList.items=for node in nodes collect (if isValidNode node then node.name else "<deleted rectangle>")
            modeList.enabled=active;containersList.enabled=active
            createContainer.enabled=true;pickContainer.enabled=true;removeContainer.enabled=leaf.containerMode==4
            local registered=leaf.sources.count,count=0
            for value in leaf.containerActive where value do count+=1
            membershipInfo.text=if leaf.containerProvider()==undefined then "Manual source list." else (count as string)+" active / "+(registered as string)+" registered\nGlobal rectangles: Surface Scatter."
            controlsReady=true;binding=false
        )
        on sourceContainersUI_1 open do bind owner
        on sourceContainersUI_1 close do controlsReady=false
        on modeList selected index do if not binding do try((currentSet()).containerSetMode modes[index];bind owner)catch(messageBox (getCurrentException()) title:"Cyrus source containers")
        on createContainer pressed do try((currentSet()).containerCreate();bind owner)catch(messageBox (getCurrentException()) title:"Cyrus source containers")
        on pickContainer picked node do try((currentSet()).containerAdd node;bind owner)catch(messageBox (getCurrentException()) title:"Cyrus source containers")
        on removeContainer pressed do try((currentSet()).containerRemove containersList.selection;bind owner)catch(messageBox (getCurrentException()) title:"Cyrus source containers")
        on sourceContainersUI_1 rolledUp state do (CyrusContainerPanel root).layoutPanels()
    )

sourceContainersUI_1
)
global CyrusLayerEditor_distributionUI_1
fn CyrusLayerEditor_distributionUI_1 = (
    rollout distributionUI_1 "Population and seed - layer" width:132 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel
        local setSpecific=false
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false

        radiobuttons modeRadio "Method" labels:#("Random","Texture Density") columns:2 pos:[4,130] width:(distributionUI_1.width-8)
        radiobuttons populationRadio "Population" labels:#("Count","Plants per m2") columns:2 pos:[4,8] width:(distributionUI_1.width-8)
        spinner countSpin "Requested count: " range:[1,100000,200] type:#integer fieldWidth:82 width:(distributionUI_1.width-8) pos:[4,62] tooltip:"Layer population before eligibility. Accepted target can retry up to its limits."
        spinner densitySpin "Per m2: " range:[0,1000000,100] fieldWidth:82 width:(distributionUI_1.width-8) pos:[4,62] tooltip:"Requested plants per square metre of receiving surface; capped at 100,000."
        spinner seedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:82 width:(distributionUI_1.width-8) pos:[4,92] tooltip:"Deterministic generation seed. Changing it can invalidate existing Edit bindings."
        label densityHeading "Texture density" pos:[4,180] width:(distributionUI_1.width-8)
        mapbutton densityButton "Choose density map" pos:[4,204] width:(distributionUI_1.width-8) tooltip:"Use UV channel 1: white permits candidates; black excludes them."
        checkbox invertCheck "Invert density" pos:[4,234] width:(distributionUI_1.width-8) tooltip:"Reverse the density map's white and black eligibility."
        label uvHint "UV channel 1; 0..1" pos:[4,260] width:(distributionUI_1.width-8)
        label mapHint "White: dense / Black: empty" pos:[4,282] width:(distributionUI_1.width-8)

        fn arrangePopulation = (
            local textured=obj.distributionMode==3
            countSpin.visible=obj.populationMode==1;densitySpin.visible=obj.populationMode==2
            for c in #(densityHeading,densityButton,invertCheck,uvHint,mapHint) do c.visible=textured
            distributionUI_1.height=if obj.sharedSpacing() then (if textured then 308 else 184) else (if textured then 340 else 208)
        )
        fn syncControls = (populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;;arrangePopulation())
        on modeRadio changed v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.distributionMode=if v==2 then 3 else 1;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on countSpin changed v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.amount=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on seedSpin changed v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.randomSeed=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())

        on populationRadio changed v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.populationMode=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on densitySpin changed v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.plantsPerM2=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on densityButton picked v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.densityMap=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on invertCheck changed v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.invertDensity=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())



        fn bindFeatures layer = (
            local next=layer
            binding=true;controlsReady=false
            if obj!=next do ()
            obj=next;parentView=(CyrusContainerPanel root)
            for c in distributionUI_1.controls do c.enabled=layer!=undefined
            try (undo off ((populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;controlsReady=true;(countSpin.value=obj.amount;seedSpin.value=obj.randomSeed;modeRadio.state=if obj.distributionMode==3 then 2 else 1)))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        fn bind layer = (bindFeatures layer;arrangePopulation())
        on distributionUI_1 open do (controlsReady=true;bind (if setSpecific then root.selectedPaintSet owner else owner))
        on distributionUI_1 close do controlsReady=false
        on distributionUI_1 rolledUp state do (CyrusContainerPanel root).layoutPanels()
    )
distributionUI_1
)
global CyrusLayerEditor_populationPolicyUI_1
fn CyrusLayerEditor_populationPolicyUI_1 = (
    rollout populationPolicyUI_1 "Target and retry limits - layer" width:146 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel,controlsReady=false,binding=false,setSpecific=false
        dropdownlist populationList "Layer population" items:#("Candidate budget","Accepted target") pos:[4,8] width:(populationPolicyUI_1.width-8) tooltip:"Budget evaluates the generated candidates; target makes bounded replacement attempts."
        spinner attemptSpin "Attempt factor:" range:[1,32,8] type:#integer pos:[4,58] width:(populationPolicyUI_1.width-8) fieldWidth:82 tooltip:"Maximum candidate attempts as a multiple of the requested population."
        spinner roundSpin "Max rounds:" range:[1,16,8] type:#integer pos:[4,86] width:(populationPolicyUI_1.width-8) fieldWidth:82 tooltip:"Maximum rounds of eligibility, collision and cleanup. A shortfall can remain."
        checkbox repairCheck "Retry cleanup gaps" pos:[4,114] width:(populationPolicyUI_1.width-8) tooltip:"Allow bounded retries for plants removed by final cleanup."
        label info "Candidate budget makes one bounded population. Accepted target retries rejected candidates up to these limits; it can finish short." pos:[4,152] width:(populationPolicyUI_1.width-8) height:64
        fn bind layer = (
            binding=true
            for c in populationPolicyUI_1.controls do c.enabled=true
            populationList.selection=owner.procPopulation;attemptSpin.value=owner.procAttemptFactor;roundSpin.value=owner.procRounds;repairCheck.checked=owner.procRepair
            local retry=true and owner.procPopulation==2
            attemptSpin.enabled=retry;roundSpin.enabled=retry;repairCheck.enabled=retry
            info.enabled=true;controlsReady=true;binding=false
        )
        fn changeLayer key value = (if not binding do (undo "Cyrus procedural settings" on setProperty owner key value;root.invalidateGroups();bind owner))
        on populationPolicyUI_1 open do bind owner
        on populationPolicyUI_1 close do controlsReady=false
        on populationList selected i do changeLayer #procPopulation i
        on attemptSpin changed v do changeLayer #procAttemptFactor v
        on roundSpin changed v do changeLayer #procRounds v
        on repairCheck changed v do changeLayer #procRepair v
        on populationPolicyUI_1 rolledUp state do (CyrusContainerPanel root).layoutPanels()
    )

populationPolicyUI_1
)
global CyrusLayerEditor_areaUI_1
fn CyrusLayerEditor_areaUI_1 = (
    rollout areaUI_1 "Include / exclude areas - layer" width:132 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel
        local setSpecific=false
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false

        multiListBox areaList "Closed lines / shapes" items:#() pos:[4,8] width:(areaUI_1.width-8) height:6
        button addAreaScene "Select From Scene..." pos:[4,134] width:(areaUI_1.width-8) tooltip:"Choose closed Area shapes by name."
        pickbutton pickArea "Add: pick closed line" filter:AminScatterAreaFilter pos:[4,160] width:(areaUI_1.width-8) tooltip:"Pick a closed shape as an include/exclude Area shared by all sets in this layer."
        button removeArea "Remove selected rows" pos:[4,186] width:(areaUI_1.width-8) tooltip:"Unlink highlighted Areas and their falloff settings; keep the scene shapes."
        radiobuttons areaMode "Selected area mode" labels:#("Include","Exclude") columns:1 pos:[4,220] width:(areaUI_1.width-8)
        label areaHint "Exclude overrides Include." pos:[4,290] width:(areaUI_1.width-8)
        label projectionHint "Top / world XY projection." pos:[4,312] width:(areaUI_1.width-8)
        button refreshAreas "Refresh areas / preview" pos:[4,340] width:(areaUI_1.width-8) tooltip:"Refresh Area geometry and recalculate the layer preview."
        local loadingAnalyzerArea=false
        label aaTitle "Surface Analyzer Area" pos:[4,412] width:(areaUI_1.width-8)
        pickbutton aaPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[4,438] width:(areaUI_1.width-8) tooltip:"Choose an existing Cyrus Surface Analyzer for line or point masks."
        button aaRemove "Remove Area Analyzer" pos:[4,466] width:(areaUI_1.width-8) tooltip:"Disable and unlink the layer's Analyzer Area mask."
        checkbox aaLine "Center Line" pos:[4,498] width:(areaUI_1.width-8) tooltip:"Use the Analyzer centre line as an XY mask; unions with its point mask."
        spinner aaWidth "Full width:" range:[0,1e9,100] type:#worldunits pos:[4,524] width:(areaUI_1.width-8) fieldWidth:62 tooltip:"Full width of the Analyzer centre-line Area mask."
        dropdownlist aaCaps "Line ends" items:#("Flat","Round") selection:1 pos:[4,552] width:(areaUI_1.width-8) tooltip:"Flat or round ends for the line mask."
        spinner aaStreetOffset "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[4,606] width:(areaUI_1.width-8) fieldWidth:62 tooltip:"Lateral offset from the Analyzer centre line."
        checkbox aaPoints "Points" pos:[4,638] width:(areaUI_1.width-8) tooltip:"Use discs around Analyzer points as an XY mask."
        spinner aaRadius "Radius:" range:[0,1e9,100] type:#worldunits pos:[4,664] width:(areaUI_1.width-8) fieldWidth:62 tooltip:"Radius of each Analyzer point mask."
        label aaHelp "XY mask. Both enabled = union. Works with Random / Clusters." pos:[4,694] width:(areaUI_1.width-8) height:40
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
        dropdownlist fallTarget "Edge falloff target" items:#("Analyzer Boundary","Selected Area line") selection:1 pos:[4,738] width:(areaUI_1.width-8) tooltip:"Edit Analyzer boundary falloff or one highlighted Area's independent falloff."
        pickbutton fallPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[4,794] width:(areaUI_1.width-8) tooltip:"Choose the Analyzer whose boundary drives this falloff."
        button fallRemove "Remove Analyzer" pos:[4,822] width:(areaUI_1.width-8) tooltip:"Unlink the falloff Analyzer and disable its falloff effects."
        label fallTargetName "" pos:[4,852] width:(areaUI_1.width-8) height:40
        checkbox fallDeleteCheck "Delete edge band" pos:[4,894] width:(areaUI_1.width-8) tooltip:"Exclude an edge band before scale and density ramps begin."
        spinner fallDeleteSpin "Delete width:" range:[0,1e9,0] type:#worldunits pos:[4,920] width:(areaUI_1.width-8) fieldWidth:62 tooltip:"Width of the excluded edge band in scene units."
        checkbox fallScaleCheck "Scale ramp" pos:[4,952] width:(areaUI_1.width-8) tooltip:"Vary instance scale with distance from this boundary."
        spinner fallScaleSpin "Scale width:" range:[0,1e9,100] type:#worldunits pos:[4,978] width:(areaUI_1.width-8) fieldWidth:62 tooltip:"Distance over which the scale curve is evaluated."
        button fallScaleEdit "Edit Scale Graph..." pos:[4,1008] width:(areaUI_1.width-8) tooltip:"Edit this boundary's scale curve."
        checkbox fallDensityCheck "Density ramp" pos:[4,1044] width:(areaUI_1.width-8) tooltip:"Vary candidate eligibility with distance from this boundary."
        spinner fallDensitySpin "Density width:" range:[0,1e9,100] type:#worldunits pos:[4,1070] width:(areaUI_1.width-8) fieldWidth:62 tooltip:"Distance over which the density curve is evaluated."
        button fallDensityEdit "Edit Density Graph..." pos:[4,1100] width:(areaUI_1.width-8) tooltip:"Edit this boundary's density curve."
        label fallHelp "Ramps start after delete band. Each Area line has its own settings." pos:[4,1138] width:(areaUI_1.width-8) height:56
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
                append obj.areaNodes n;append obj.areaModes 1;obj.markInputDirty()
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
            obj.markInputDirty();updateAreas();CyrusViewportRedraw()
        )
        on removeArea pressed do if controlsReady and not binding and obj!=undefined do (
            if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()
            local rows=areaList.selection as array
            undo "Cyrus Scatter remove areas" on (
                obj.ensureAreaFalloffs()
                for i=rows.count to 1 by -1 do (deleteItem obj.areaNodes rows[i];deleteItem obj.areaModes rows[i];deleteItem obj.areaFallConfigs rows[i];deleteItem obj.areaFallScaleGraphs rows[i];deleteItem obj.areaFallDensityGraphs rows[i])
            )
            areaList.selection=#{};obj.markInputDirty();updateAreas();CyrusViewportRedraw()
        )
        on refreshAreas pressed do if controlsReady and not binding and obj!=undefined do (obj.markInputDirty();(if obj.overlapOwner==undefined then obj else obj.overlapOwner).refreshAll();CyrusViewportRedraw())




        fn bindFeatures layer = (
            local next=layer
            binding=true;controlsReady=false
            if obj!=next do (areaList.selection=#{};)
            obj=next;parentView=(CyrusContainerPanel root)
            for c in areaUI_1.controls do c.enabled=layer!=undefined
            try (undo off ((syncAnalyzerArea();syncFalloff();controlsReady=true;updateAreas()))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        checkbutton detailsToggle "Analyzer masks and edge falloff" pos:[4,378] width:(areaUI_1.width-8) height:26 tooltip:"Show or hide these advanced controls; their saved settings are preserved."
        fn arrangeDetails = (
            for c in #(aaTitle,aaPick,aaRemove,aaLine,aaWidth,aaCaps,aaStreetOffset,aaPoints,aaRadius,aaHelp,fallTarget,fallPick,fallRemove,fallTargetName,fallDeleteCheck,fallDeleteSpin,fallScaleCheck,fallScaleSpin,fallScaleEdit,fallDensityCheck,fallDensitySpin,fallDensityEdit,fallHelp) do c.visible=detailsToggle.checked
            areaUI_1.height=if detailsToggle.checked then 1202 else 412
        )
        fn bind layer = (bindFeatures layer;arrangeDetails())
        on detailsToggle changed value do arrangeDetails()
        on areaUI_1 open do (controlsReady=true;bind (if setSpecific then root.selectedPaintSet owner else owner))
        on areaUI_1 close do controlsReady=false
        on areaUI_1 rolledUp state do (CyrusContainerPanel root).layoutPanels()
    )
areaUI_1
)
global CyrusLayerEditor_brushUI_1
fn CyrusLayerEditor_brushUI_1 = (
    rollout brushUI_1 "Brush coverage and strokes - paint set" width:132 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel
        local setSpecific=true
        local obj=undefined,controlsReady=false,binding=false,history=#()
        label activeInfo "Select a plant group." pos:[4,8] width:(brushUI_1.width-8) height:32
        dropdownlist coverageMode "Coverage" items:#("Whole shared surface","Painted area") pos:[4,44] width:(brushUI_1.width-8) tooltip:"Use the whole receiver or this paint set's saved painted coverage."
        label targetInfo "Receiving surface comes from the setup." pos:[4,94] width:(brushUI_1.width-8) height:32
        radiobuttons modeRadio "Next stroke" labels:#("Paint","Erase") columns:2 pos:[4,130] width:(brushUI_1.width-8)
        spinner radiusSpin "Radius:" type:#worldunits range:[0.0001,1e9,20] fieldWidth:82 pos:[4,184] width:(brushUI_1.width-8) tooltip:"World-space radius of the next Brush stroke on the receiving surface."
        spinner strengthSpin "Strength %:" range:[0,100,100] fieldWidth:82 pos:[4,212] width:(brushUI_1.width-8) tooltip:"Amount of coverage painted or erased by the next stroke."
        spinner softSpin "Softness %:" range:[0,100,50] fieldWidth:82 pos:[4,240] width:(brushUI_1.width-8) tooltip:"Softness of the next stroke's edge."
        spinner densitySpin "Mask %:" range:[0,100,100] fieldWidth:82 pos:[4,268] width:(brushUI_1.width-8) tooltip:"Thin plants allowed by the saved mask. Set absolute population on Population."
        button beginButton "Start Brush" pos:[4,300] width:((brushUI_1.width-12)/2) tooltip:"Paint this set on the shared surface. Creates an empty mask when needed."
        button stopButton "Stop" pos:[(brushUI_1.width/2+2),300] width:((brushUI_1.width-12)/2) tooltip:"Finish painting and retain the editable stroke history."
        button fillButton "Fill" pos:[4,332] width:((brushUI_1.width-12)/2) tooltip:"Fill coverage and reset stroke history. Undo restores the previous field."
        button emptyButton "Empty" pos:[(brushUI_1.width/2+2),332] width:((brushUI_1.width-12)/2) tooltip:"Empty coverage and reset stroke history. Undo restores the previous field."
        label brushState "Select a group and receiving surface." pos:[4,366] width:(brushUI_1.width-8) height:66
        dropdownlist overlayMode "Paint feedback" items:#("Coverage tint","Coverage samples","Off") pos:[4,470] width:(brushUI_1.width-8) tooltip:"Coverage feedback only; it does not show which plants survive spacing."
        colorpicker overlayColor "Color:" pos:[4,524] width:(brushUI_1.width-8) tooltip:"Viewport color for this paint set's coverage feedback."
        listbox strokeList "Group stroke history" items:#() pos:[4,556] width:(brushUI_1.width-8) height:5
        checkbox strokeEnabled "Enabled" pos:[4,672] width:((brushUI_1.width-12)/2) tooltip:"Enable or disable the highlighted saved stroke without deleting it."
        checkbox strokeErase "Erase" pos:[(brushUI_1.width/2+2),672] width:((brushUI_1.width-12)/2) tooltip:"Change the highlighted saved stroke between paint and erase."
        spinner strokeRadius "Radius:" type:#worldunits range:[0.0001,1e9,20] fieldWidth:82 pos:[4,700] width:(brushUI_1.width-8) tooltip:"Change the radius of the highlighted saved stroke."
        spinner strokeStrength "Strength %:" range:[0,100,100] fieldWidth:82 pos:[4,728] width:(brushUI_1.width-8) tooltip:"Change the strength of the highlighted saved stroke."
        spinner strokeSoft "Softness %:" range:[0,100,50] fieldWidth:82 pos:[4,756] width:(brushUI_1.width-8) tooltip:"Change the edge softness of the highlighted saved stroke."
        button deleteStroke "Delete selected stroke" pos:[4,788] width:(brushUI_1.width-8) tooltip:"Delete the highlighted stroke. Undo restores it."
        button resetTarget "Reset coverage target..." pos:[4,820] width:(brushUI_1.width-8) tooltip:"Confirm before replacing this set's paint with an empty mask on the current receiver."
        label brushHelp "One centre = one plant.\nTint shows painted coverage.\nManual mode needs Update." pos:[4,852] width:(brushUI_1.width-8) height:54
        fn showStroke = (
            binding=true
            local i=strokeList.selection,valid=i>0 and i<=history.count
            for c in #(strokeEnabled,strokeErase,strokeRadius,strokeStrength,strokeSoft,deleteStroke) do c.enabled=valid
            if valid do (local row=history[i];strokeEnabled.checked=row[1];strokeErase.checked=row[2];strokeRadius.value=row[3];strokeStrength.value=row[4]*100;strokeSoft.value=row[5]*100)
            binding=false
        )
        fn refreshHistory = (
            binding=true
            local chosen=strokeList.selection
            history=if obj!=undefined and obj.paintDocument!=undefined then cyrusBrushHistory obj.paintDocument else #()
            strokeList.items=for i=1 to history.count collect ((i as string)+" | "+(if history[i][2] then "Erase" else "Paint")+(if history[i][1] then "" else " (off)")+" | "+(history[i][6] as string)+" samples")
            strokeList.selection=amin chosen history.count;binding=false;showStroke()
        )
        fn editStroke = (
            local i=strokeList.selection
            if binding or i<1 or i>history.count do return false
            cyrusBrushStroke obj.paintDocument i strokeEnabled.checked (strokeStrength.value/100.0) strokeRadius.value (strokeSoft.value/100.0) strokeErase.checked
            obj.publishPaint();refreshHistory()
        )
        fn saveOptions = (
            if not binding and obj!=undefined and obj.paintDocument!=undefined do (
                cyrusBrushSettings obj.paintDocument radiusSpin.value (strengthSpin.value/100.0) (softSpin.value/100.0) (modeRadio.state==2) 1.0
                cyrusBrushDisplay obj.paintDocument obj.paintView obj.paintColor
            )
        )
        fn status = (
            if obj==undefined do return false
            if obj.paintDocument==undefined then brushState.text="Start Brush creates an empty mask\non the shared receiving surface." else (
                local state=cyrusBrushStats obj.paintDocument
                local message=(if state[5]==1 then "Brush active" else "Brush stopped")+" | "+(CyrusUICount state[2])+" strokes"
                if not obj.paintEnabled do message+="\nWhole surface; strokes retained."
                if state[11]!="" do message+="\n"+state[11]
                if obj.updateMode==1 and obj.dirty do message+="\nChanges pending; plants need Update."
                if state.count>=18 and state[18]>0 do message+="\nCoverage preview uses bounded detail."
                if brushState.text!=message do brushState.text=message
            )
        )
        fn bindFeatures layer = (
            binding=true;obj=layer
            for c in brushUI_1.controls do c.enabled=layer!=undefined
            local has=layer!=undefined and layer.paintDocument!=undefined
            for c in #(fillButton,emptyButton,stopButton) do c.enabled=has
            activeInfo.text=if layer==undefined then "Select a plant group." else "Painting: "+(root.setCaption layer)
            local targets=root.validSurfaces()
            targetInfo.text=if has then "Mask surface: "+(if isValidNode (cyrusBrushTarget layer.paintDocument) then (cyrusBrushTarget layer.paintDocument).name else "<missing>") else (if targets.count==1 then "Shared surface: "+targets[1].name else "Pick one shared surface above.")
            if layer!=undefined do (
                coverageMode.selection=if layer.paintEnabled then 2 else 1
                densitySpin.value=layer.paintDensity*100;overlayMode.selection=findItem #(2,1,0) layer.paintView;overlayColor.color=layer.paintColor
            )
            if has do (local cfg=cyrusBrushOptions layer.paintDocument;radiusSpin.value=cfg[1];strengthSpin.value=cfg[2]*100;softSpin.value=cfg[3]*100;modeRadio.state=if cfg[5] then 2 else 1)
            controlsReady=true;binding=false;refreshHistory();status()
        )
        checkbutton detailsToggle "Paint feedback and editable stroke history" pos:[4,436] width:(brushUI_1.width-8) height:26 tooltip:"Show or hide these advanced controls; their saved settings are preserved."
        fn arrangeDetails = (
            for c in #(overlayMode,overlayColor,strokeList,strokeEnabled,strokeErase,strokeRadius,strokeStrength,strokeSoft,deleteStroke,resetTarget,brushHelp) do c.visible=detailsToggle.checked
            brushUI_1.height=if detailsToggle.checked then 914 else 470
        )
        fn bind layer = (bindFeatures layer;arrangeDetails())
        on detailsToggle changed value do arrangeDetails()
        on brushUI_1 open do bind ((if setSpecific then root.selectedPaintSet owner else owner))
        on brushUI_1 close do (controlsReady=false;CyrusStopBrush())
        on coverageMode selected i do if not binding and obj!=undefined do try(root.setGroupCoverage obj (i==2))catch(messageBox (getCurrentException()) title:"Cyrus coverage";bind obj)
        on beginButton pressed do if obj!=undefined do (
            try (
                local options=#(radiusSpin.value,strengthSpin.value,softSpin.value,modeRadio.state)
                root.setGroupCoverage obj true
                radiusSpin.value=options[1];strengthSpin.value=options[2];softSpin.value=options[3];modeRadio.state=options[4]
                saveOptions();CyrusStartBrush root obj;status()
            ) catch(messageBox (getCurrentException()) title:"Cyrus Brush")
        )
        on stopButton pressed do (CyrusStopBrush();refreshHistory();status())
        on modeRadio changed value do saveOptions()
        on radiusSpin changed value do saveOptions()
        on strengthSpin changed value do saveOptions()
        on softSpin changed value do saveOptions()
        on densitySpin changed value do if not binding and obj!=undefined do (undo "Cyrus painted density" on obj.paintDensity=value/100.0;obj.publishPaint())
        on overlayMode selected value do if not binding and obj!=undefined do (undo "Cyrus coverage display" on obj.paintView=(#(2,1,0))[value];saveOptions();redrawViews())
        on overlayColor changed value do if not binding and obj!=undefined do (undo "Cyrus coverage color" on obj.paintColor=value;saveOptions();redrawViews())
        on fillButton pressed do (cyrusBrushFill obj.paintDocument 1.0;obj.publishPaint();refreshHistory();status())
        on emptyButton pressed do (cyrusBrushFill obj.paintDocument 0.0;obj.publishPaint();refreshHistory();status())
        on strokeList selected value do showStroke()
        on strokeEnabled changed value do editStroke()
        on strokeErase changed value do editStroke()
        on strokeRadius changed value do editStroke()
        on strokeStrength changed value do editStroke()
        on strokeSoft changed value do editStroke()
        on deleteStroke pressed do if strokeList.selection>0 do (cyrusBrushDeleteStroke obj.paintDocument strokeList.selection;obj.publishPaint();refreshHistory();status())
        on resetTarget pressed do if obj!=undefined do (
            if queryBox "Replace this paint set's saved paint with an empty mask on the shared surface? Undo restores the previous document." title:"Cyrus reset coverage" do try(root.setGroupCoverage obj true reset:true)catch(messageBox (getCurrentException()) title:"Cyrus coverage")
        )
        on brushUI_1 rolledUp state do (CyrusContainerPanel root).layoutPanels()
    )

brushUI_1
)
global CyrusLayerEditor_backgroundUI_1
fn CyrusLayerEditor_backgroundUI_1 = (
    rollout backgroundUI_1 "Background fill - paint set" width:146 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel,controlsReady=false,binding=false,setSpecific=true,backgrounds=#()
        dropdownlist backgroundList "This set: background" items:#("Off","Outside painted coverage","Between plants","Outside + between") pos:[4,8] width:(backgroundUI_1.width-8) tooltip:"Exclude earlier painted coverage, fill between plants, combine both, or turn off."
        multiListBox referenceList "Earlier paint sets" items:#() pos:[4,60] width:(backgroundUI_1.width-8) height:4
        button applyBackground "Apply background" pos:[4,152] width:(backgroundUI_1.width-8) tooltip:"Save this background mode and the selected earlier-set references together."
        label backgroundInfo "Outside uses earlier sibling coverage. Between plants uses the rules on the Spacing tab." pos:[4,182] width:(backgroundUI_1.width-8) height:62
        fn currentSet = (root.selectedPaintSet owner)
        fn bind layer = (
            binding=true
            for c in backgroundUI_1.controls do c.enabled=true
            local leaf=currentSet()
            backgroundList.selection=leaf.procBackground;backgrounds=#()
            for p in root.layerSets owner while p!=leaf do append backgrounds p
            referenceList.items=for p in backgrounds collect p.paintSetName
            referenceList.selection=for i=1 to backgrounds.count where findItem leaf.procBackgroundIDs backgrounds[i].layerID>0 collect i
            controlsReady=true;binding=false
        )
        on backgroundUI_1 open do bind owner
        on backgroundUI_1 close do controlsReady=false
        on applyBackground pressed do try(
            local leaf=currentSet(),ids=for i in referenceList.selection collect backgrounds[i].layerID
            if backgroundList.selection!=1 and ids.count==0 do throw "Choose at least one earlier paint set."
            undo "Cyrus background coverage" on (leaf.procBackground=backgroundList.selection;leaf.procBackgroundIDs=if backgroundList.selection==1 then #() else ids)
            root.invalidateGroups();bind owner
        )catch(messageBox (getCurrentException()) title:"Cyrus background")
        on backgroundUI_1 rolledUp state do (CyrusContainerPanel root).layoutPanels()
    )

backgroundUI_1
)
global CyrusLayerEditor_randomUI_1
fn CyrusLayerEditor_randomUI_1 = (
    rollout randomUI_1 "Random transforms - layer" width:132 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel
        local setSpecific=false
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false

        label rotTitle "Rotation (degrees)" pos:[4,8] width:(randomUI_1.width-8)
        label rotMinTitle "Min" pos:[24,30] width:((randomUI_1.width-38)/2)
        label rotMaxTitle "Max" pos:[((randomUI_1.width+18)/2),30] width:((randomUI_1.width-38)/2)
        label rotXLabel "X" pos:[4,52] width:12
        spinner rotXMinSpin "" range:[-360,360,0]  pos:[24,50] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        spinner rotXMaxSpin "" range:[-360,360,0]  pos:[((randomUI_1.width+18)/2),50] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        label rotYLabel "Y" pos:[4,76] width:12
        spinner rotYMinSpin "" range:[-360,360,0]  pos:[24,74] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        spinner rotYMaxSpin "" range:[-360,360,0]  pos:[((randomUI_1.width+18)/2),74] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        label rotZLabel "Z" pos:[4,100] width:12
        spinner rotZMinSpin "" range:[-360,360,0]  pos:[24,98] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        spinner rotZMaxSpin "" range:[-360,360,360]  pos:[((randomUI_1.width+18)/2),98] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        label sclTitle "Scale (multiplier)" pos:[4,162] width:(randomUI_1.width-8)
        label sclMinTitle "Min" pos:[24,184] width:((randomUI_1.width-38)/2)
        label sclMaxTitle "Max" pos:[((randomUI_1.width+18)/2),184] width:((randomUI_1.width-38)/2)
        label sclXLabel "X" pos:[4,206] width:12
        spinner sclXMinSpin "" range:[0.001,100,1]  pos:[24,204] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        spinner sclXMaxSpin "" range:[0.001,100,1]  pos:[((randomUI_1.width+18)/2),204] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        label sclYLabel "Y" pos:[4,230] width:12
        spinner sclYMinSpin "" range:[0.001,100,1]  pos:[24,228] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        spinner sclYMaxSpin "" range:[0.001,100,1]  pos:[((randomUI_1.width+18)/2),228] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        label sclZLabel "Z" pos:[4,254] width:12
        spinner sclZMinSpin "" range:[0.001,100,1]  pos:[24,252] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        spinner sclZMaxSpin "" range:[0.001,100,1]  pos:[((randomUI_1.width+18)/2),252] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        label wholeTitle "Whole Scale (uniform)" pos:[4,312] width:(randomUI_1.width-8)
        label wholeMinTitle "Min" pos:[24,334] width:((randomUI_1.width-38)/2)
        label wholeMaxTitle "Max" pos:[((randomUI_1.width+18)/2),334] width:((randomUI_1.width-38)/2)
        spinner wholeMinSpin "" range:[0.001,1000,1] scale:0.01 pos:[24,356] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        spinner wholeMaxSpin "" range:[0.001,1000,1] scale:0.01 pos:[((randomUI_1.width+18)/2),356] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        on wholeMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.wholeScaleMin=v;if v>obj.wholeScaleMax do (obj.wholeScaleMax=v;wholeMaxSpin.value=v);CyrusViewportRedraw())
        on wholeMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.wholeScaleMax=v;if v<obj.wholeScaleMin do (obj.wholeScaleMin=v;wholeMinSpin.value=v);CyrusViewportRedraw())
        label movTitle "Movement (world units)" pos:[4,422] width:(randomUI_1.width-8)
        label movMinTitle "Min" pos:[24,444] width:((randomUI_1.width-38)/2)
        label movMaxTitle "Max" pos:[((randomUI_1.width+18)/2),444] width:((randomUI_1.width-38)/2)
        label movXLabel "X" pos:[4,466] width:12
        spinner movXMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[24,464] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        spinner movXMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[((randomUI_1.width+18)/2),464] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        label movYLabel "Y" pos:[4,490] width:12
        spinner movYMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[24,488] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        spinner movYMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[((randomUI_1.width+18)/2),488] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        label movZLabel "Z" pos:[4,514] width:12
        spinner movZMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[24,512] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        spinner movZMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[((randomUI_1.width+18)/2),512] fieldWidth:((randomUI_1.width-38)/2) width:((randomUI_1.width-38)/2)
        checkbox projectCheck "Keep on surface" pos:[4,576] width:(randomUI_1.width-8) tooltip:"Project random movement back onto the receiving surface."
        checkbox alignCheck "Align to normal" pos:[4,600] width:(randomUI_1.width-8) tooltip:"Align instances to the receiving surface normal."

        button resetRotation "Reset rotation" pos:[4,124] width:(randomUI_1.width-8) height:20 tooltip:"Reset only this layer's random rotation limits. Undo is available."
        button resetScale "Reset XYZ scale" pos:[4,278] width:(randomUI_1.width-8) height:20 tooltip:"Reset only this layer's separate X, Y and Z scale limits."
        button resetWholeScale "Reset whole scale" pos:[4,382] width:(randomUI_1.width-8) height:20 tooltip:"Reset only this layer's uniform scale multiplier."
        button resetMovement "Reset movement" pos:[4,536] width:(randomUI_1.width-8) height:20 tooltip:"Reset only this layer's random translation limits."
        fn resetBoundRandomization kind = (
            undo "Cyrus reset layer transforms" on owner.resetRandomization kind
            randomUI_1.bind owner;root.invalidateGroups();true
        )
        on resetRotation pressed do resetBoundRandomization #rotation
        on resetScale pressed do resetBoundRandomization #scale
        on resetWholeScale pressed do resetBoundRandomization #wholeScale
        on resetMovement pressed do resetBoundRandomization #movement
        fn syncControls = (projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;)
        on alignCheck changed v do if controlsReady and not binding and obj!=undefined do (obj.alignNormal=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())

        on projectCheck changed v do if controlsReady and not binding and obj!=undefined do (obj.projectMove=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on rotXMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.rotXMin=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on rotXMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.rotXMax=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on rotYMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.rotYMin=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on rotYMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.rotYMax=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on rotZMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.rotZMin=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on rotZMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.rotZMax=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on sclXMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.sclXMin=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on sclXMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.sclXMax=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on sclYMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.sclYMin=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on sclYMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.sclYMax=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on sclZMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.sclZMin=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on sclZMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.sclZMax=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on movXMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movXMin=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on movXMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movXMax=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on movYMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movYMin=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on movYMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movYMax=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on movZMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movZMin=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on movZMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movZMax=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())



        fn bind layer = (
            local next=layer
            binding=true;controlsReady=false
            if obj!=next do ()
            obj=next;parentView=(CyrusContainerPanel root)
            for c in randomUI_1.controls do c.enabled=layer!=undefined
            try (undo off ((wholeMinSpin.value=obj.wholeScaleMin;wholeMaxSpin.value=obj.wholeScaleMax;projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;controlsReady=true;alignCheck.checked=obj.alignNormal))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        on randomUI_1 open do (controlsReady=true;bind (if setSpecific then root.selectedPaintSet owner else owner))
        on randomUI_1 close do controlsReady=false
        on randomUI_1 rolledUp state do (CyrusContainerPanel root).layoutPanels()
    )
randomUI_1
)
global CyrusLayerEditor_diversityUI_1
fn CyrusLayerEditor_diversityUI_1 = (
    rollout diversityUI_1 "Source assignment - layer" width:132 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel
        local setSpecific=false
        local binding=false,
        obj=undefined,parentView=undefined
        local boundaryOnly=false
        local controlsReady=false,strokeExpandedHeight=0

        radiobuttons diversityRadio "Source assignment" labels:#("Random mix","Clusters","Spline bands","Surface Analyzer") columns:1 pos:[4,8] width:(diversityUI_1.width-8)
        label layoutHelp "" pos:[4,90] width:(diversityUI_1.width-8) height:36
        label analyzerStatus "Pick a Surface Analyzer." pos:[4,100] width:(diversityUI_1.width-8) height:54
        button selectAnalyzer "Select" pos:[4,100] width:70 tooltip:"Select the linked Surface Analyzer in the scene."
        button updateAnalyzer "Update Analyzer" pos:[4,124] width:140 tooltip:"Analyze the linked guide. In Manual mode, use Update scatter afterwards to publish placements."
        spinner sizeSpin "Size: " range:[0.01,100000,10] type:#worldUnits fieldWidth:82 width:(diversityUI_1.width-8) pos:[4,104] tooltip:"Spatial size of source-color clusters."
        spinner divSeedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:82 width:(diversityUI_1.width-8) pos:[4,130] tooltip:"Change source assignment randomness without changing the generation seed."
        spinner roughSpin "Roughness %: " range:[0,100,0] fieldWidth:82 width:(diversityUI_1.width-8) pos:[4,156]
        spinner blurSpin "Blur edge %: " range:[0,100,0] fieldWidth:82 width:(diversityUI_1.width-8) pos:[4,182]
        spinner noiseSpin "Noise %: " range:[0,100,0] fieldWidth:82 width:(diversityUI_1.width-8) pos:[4,208]
        label groupHint "Uses assignment groups, not viewport colors." pos:[4,238] width:(diversityUI_1.width-8)
        label fixedHint "Point positions stay fixed." pos:[4,260] width:(diversityUI_1.width-8)




        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Spline bands" pos:[4,118] width:(diversityUI_1.width-8)
        dropdownlist pathsDrop "Paths" items:#() pos:[4,142] width:(diversityUI_1.width-8)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[4,142] width:(diversityUI_1.width-8)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[4,192] width:(diversityUI_1.width-8) tooltip:"Use Surface Analyzer output for bands, rows and fixed anchors."
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[4,192] width:(diversityUI_1.width-8) tooltip:"Pick a spline for Line Pattern assignment."
        button removePath "Remove path" pos:[4,218] width:(diversityUI_1.width-8) tooltip:"Remove the selected assignment path while keeping the scene spline."
        listbox strokesList "Bands" items:#() pos:[4,250] width:(diversityUI_1.width-8) height:4
        button addOutside "Add Outside" pos:[4,346] width:((diversityUI_1.width-12)/2) tooltip:"Add a source-assignment band outside the selected path."
        button addInside "Add Inside" pos:[(if boundaryOnly then 4 else diversityUI_1.width/2+2),346] width:(if boundaryOnly then diversityUI_1.width-8 else (diversityUI_1.width-12)/2) tooltip:"Add a source-assignment band inside the selected path."
        button removeStrokeButton "Remove band" pos:[4,372] width:(diversityUI_1.width-8) tooltip:"Remove the selected band and its settings."
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[4,406] width:(diversityUI_1.width-8) fieldWidth:82
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[4,434] width:(diversityUI_1.width-8)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[4,506] width:(diversityUI_1.width-8) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[4,618] width:(diversityUI_1.width-8) fieldWidth:82
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[4,644] width:(diversityUI_1.width-8) fieldWidth:82
        button refreshGroups "Refresh sources / groups" pos:[4,676] width:(diversityUI_1.width-8) tooltip:"Refresh available source color groups for assignment."
        label strokeHelp "Outside bands: empty. First match wins." pos:[4,704] width:(diversityUI_1.width-8)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[4,814] width:(diversityUI_1.width-8) fieldWidth:82
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[4,842] width:(diversityUI_1.width-8) fieldWidth:82
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[4,870] width:(diversityUI_1.width-8) fieldWidth:82
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[4,898] width:(diversityUI_1.width-8) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[4,940] width:(diversityUI_1.width-8)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[4,968] width:(diversityUI_1.width-8) fieldWidth:82
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[4,996] width:(diversityUI_1.width-8) fieldWidth:82
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[4,1024] width:(diversityUI_1.width-8) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[4,1066] width:(diversityUI_1.width-8) fieldWidth:82
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[4,1094] width:(diversityUI_1.width-8) fieldWidth:82
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[4,1122] width:(diversityUI_1.width-8) fieldWidth:82
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[4,814] width:(diversityUI_1.width-8) fieldWidth:62
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[4,842] width:(diversityUI_1.width-8) fieldWidth:62
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[4,814] width:(diversityUI_1.width-8) fieldWidth:62
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[4,874] width:(diversityUI_1.width-8) height:44
        checkbox faceOutCheck "Face outward" pos:[4,756] width:(diversityUI_1.width-8)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[4,784] width:(diversityUI_1.width-8) fieldWidth:82
        checkbox straightStreet "Straight ends (Street Side)" pos:[4,730] width:(diversityUI_1.width-8)
        fn syncControls = (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;)
        on faceOutCheck changed v do if controlsReady and not binding and obj!=undefined do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.markInputDirty();CyrusViewportRedraw()
        )
        on cornerRadiusSpin changed v do if controlsReady and not binding and obj!=undefined do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.markInputDirty();CyrusViewportRedraw()
        )
        on streetStartSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (obj.streetTrimStart=v;CyrusViewportRedraw())
        on streetEndSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (obj.streetTrimEnd=v;CyrusViewportRedraw())
        on centerStreetSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (obj.centerStreetOffset=v;CyrusViewportRedraw())
        on straightStreet changed v do if controlsReady and not binding and obj!=undefined do (obj.streetStraight=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
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
                    for n in obj.sources where isValidNode n do (append choiceValues n;append labels (obj.sourceLabel (obj.sourceRow n)))
                    for i=1 to obj.strokeSourceRows.count where obj.strokeSourceRows[i]==row do (
                        local k=findItem choiceValues obj.strokeSourceNodes[i];if k>0 do selectedRows[k]=true
                    )
                )
                strokeChoices.items=labels;strokeChoices.selection=selectedRows
            )
            loadingStroke=false
            if obj.diversityMode>=3 do (
                local analyzed=obj.diversityMode==4
                strokeHelp.text=if analyzed then "Width is spread per side; spacing and masks still apply." else "Outside bands: empty. First match wins."
                local guideReady=if analyzed then isValidNode obj.analyzerNode else pathsDrop.selection>0
                if not guideReady then strokeHelp.text=if analyzed then "Pick an Analyzer to begin." else "Pick a closed spline to begin."
                else if strokeRows.count==0 then strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "Add an edge row, then choose models." else "Add a band, then choose models."
                else if selectedStroke()>0 and strokeChoices.selection.numberSet==0 then strokeHelp.text="Choose models or groups for this band."
                else if analyzed and analyzerChannel.selection==5 then strokeHelp.text="Spacing controls row count. Amount 0 disables output."
                else if analyzed and analyzerChannel.selection==3 and obj.strokeSides[selectedStroke()]==5 then strokeHelp.text="Analyzer points control count. Amount 0 disables output."
            )
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
        fn updateAnalyzerStatus = (
            local guide=obj.analyzerNode,valid=isValidNode obj.analyzerNode
            selectAnalyzer.enabled=valid;updateAnalyzer.enabled=valid
            analyzerStatus.text=if not valid then "Pick an existing Analyzer. Open planar surfaces only." else (
                local target=if isValidNode guide.surface then guide.surface.name else "Missing surface"
                local state=if not guide.cyrusEnabled then "Disabled" else if not isValidNode guide.surface then "Missing surface" else if not isProperty guide #analysisCurrent then "Update Analyzer script" else if not guide.analysisCurrent() then "Update Analyzer needed" else "Ready"
                guide.name+"\nSurface: "+target+"\n"+state
            )
        )
        on selectAnalyzer pressed do if controlsReady and not binding and obj!=undefined do (
            local guide=obj.analyzerNode
            if isValidNode guide do (select guide;max modify mode)
        )
        on updateAnalyzer pressed do if controlsReady and not binding and obj!=undefined do (
            local savedOwner=obj,guide=obj.analyzerNode
            if isValidNode guide do try (
                guide.runAnalysis();savedOwner.markInputDirty()
                if controlsReady and obj==savedOwner do updateAnalyzerStatus()
                CyrusViewportRedraw()
            )catch(if controlsReady and obj==savedOwner do analyzerStatus.text="Analysis failed: "+getCurrentException())
        )
        fn updatePattern = (
            updateAnalyzerStatus()
            layoutHelp.text=case obj.diversityMode of (
                1: "Mix models using their weights."
                2: "Group models into patches. Size controls patch size."
                3: "Closed spline bands use top-down XY projection."
                4: "Use the linked Analyzer's published guides."
            )
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
            strokeTitle.text=if analyzed then "Analyzer bands / rows" else "Spline bands"
            addOutside.text=if not analyzed or analyzerChannel.selection==1 then "Add Outside" else (if analyzerChannel.selection==2 then "Add band" else "Add Radius")
            addInside.text=if analyzed and analyzerChannel.selection==3 then "Add Single" else "Add Inside"
            boundaryOnly=analyzed and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5)
            addOutside.visible=(obj.diversityMode==3 or analyzed) and not boundaryOnly
            addInside.pos=[if boundaryOnly then 4 else diversityUI_1.width/2+2,addOutside.pos.y]
            addInside.width=if boundaryOnly then diversityUI_1.width-8 else (diversityUI_1.width-12)/2
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add band inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside bands: empty. First match wins."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()

        )

        on pathsDrop selected i do if controlsReady and not binding and obj!=undefined do showPath()
        on analyzerChannel selected i do if controlsReady and not binding and obj!=undefined do updatePattern()
        on pickAnalyzer picked n do if controlsReady and not binding and obj!=undefined do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.markInputDirty();updatePattern();CyrusViewportRedraw())
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
            updatePattern();obj.markInputDirty();syncControls();CyrusViewportRedraw()
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
        on strokeWidth changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.markInputDirty();showPath();CyrusViewportRedraw())
        on strokeMode changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on strokeChoices selectionEnd do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            CyrusViewportRedraw()
        )
        on strokeScaleMin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on strokeScaleMax changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on refreshGroups pressed do if controlsReady and not binding and obj!=undefined do updatePattern()
                fn updateControls = (
            for c in #(sizeSpin,divSeedSpin,roughSpin,blurSpin,noiseSpin,groupHint,fixedHint) do c.visible=obj.diversityMode==2
            for c in #(strokeTitle,pathsDrop,analyzerChannel,pickAnalyzer,pickPath,removePath,strokesList,addOutside,addInside,removeStrokeButton,strokeWidth,strokeMode,strokeChoices,strokeScaleMin,strokeScaleMax,refreshGroups,strokeHelp) do c.visible=(obj.diversityMode==3 or obj.diversityMode==4)
            if strokeExpandedHeight>0 do diversityUI_1.height=if obj.diversityMode>=3 then strokeExpandedHeight else (if obj.diversityMode==2 then 310 else 124)*1.0
            (CyrusContainerPanel root).layoutPanels()
        )
        on diversityRadio changed v do if controlsReady and not binding and obj!=undefined do (obj.diversityMode=v;updateControls();updatePattern();obj.markInputDirty();syncControls();CyrusViewportRedraw())


        on sizeSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.diversitySize=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on divSeedSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.diversitySeed=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on roughSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.roughness=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on blurSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.blurryEdge=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on noiseSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.diversityNoise=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())



        fn bind layer = (
            local next=layer
            binding=true;controlsReady=false
            if obj!=next do (strokesList.selection=0;strokeChoices.selection=0;)
            obj=next;parentView=(CyrusContainerPanel root)
            for c in diversityUI_1.controls do c.enabled=layer!=undefined
            try (undo off ((diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;controlsReady=true;strokeExpandedHeight=diversityUI_1.height;updateControls();updatePattern()))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        on diversityUI_1 open do (controlsReady=true;bind (if setSpecific then root.selectedPaintSet owner else owner))
        on diversityUI_1 close do controlsReady=false
        on diversityUI_1 rolledUp state do (CyrusContainerPanel root).layoutPanels()
    )
diversityUI_1
)
global CyrusLayerEditor_proceduralUI_1
fn CyrusLayerEditor_proceduralUI_1 = (
    rollout proceduralUI_1 "Spacing rules - selected scope" width:146 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel,controlsReady=false,binding=false,setSpecific=true,peers=#()
        dropdownlist scopeList "Spacing scope" items:#("This paint set","Default between sets","Pair of paint sets","Pair of layers","Layer default within sets") pos:[4,12] width:(proceduralUI_1.width-8) selection:1 tooltip:"Each scope is independent. A set can inherit or override its layer's within-set default."
        dropdownlist peerList "Other owner" items:#() pos:[4,64] width:(proceduralUI_1.width-8)
        checkbox enabledCheck "Enable this spacing" pos:[4,118] width:(proceduralUI_1.width-8)
        spinner multiplierSpin "Radius factor:" range:[0,10000,1] pos:[4,146] width:(proceduralUI_1.width-8) fieldWidth:82
        spinner gapSpin "Extra gap:" range:[0,1e9,0] type:#worldUnits pos:[4,174] width:(proceduralUI_1.width-8) fieldWidth:82
        checkbox planarCheck "XY distance (off = 3D)" pos:[4,202] width:(proceduralUI_1.width-8)
        label ruleInfo "Factor x (radius A + radius B) + gap" pos:[4,230] width:(proceduralUI_1.width-8) height:40
        button resetRule "Use inherited / default" pos:[4,274] width:(proceduralUI_1.width-8)
        fn currentSet = (root.selectedPaintSet owner)
        fn bindRule resetPeer:false = (
            local wasBinding=binding,leaf=currentSet(),scope=scopeList.selection,rule,previous=undefined,pair=scope==3 or scope==4
            if not resetPeer and peerList.selection>0 and peerList.selection<=peers.count do previous=peers[peerList.selection]
            binding=true
            try (
                peers=case scope of (3:(for p in root.layerSets owner where p!=leaf collect p);4:(for p in root.logicalLayers() where p!=owner collect p);default:#())
                peerList.items=for p in peers collect (if scope==4 then root.layerCaption p else p.paintSetName)
                peerList.selection=if peers.count==0 then 0 else amax 1 (findItem peers previous)
                local editable=not pair or peers.count>0
                peerList.enabled=pair and editable
                for c in #(enabledCheck,multiplierSpin,gapSpin,planarCheck,resetRule) do c.enabled=editable
                rule=case scope of (
                    1: leaf.procSelfRule()
                    2:#(owner.procSiblingEnabled,owner.procSiblingMultiplier,owner.procSiblingGap,owner.procSiblingPlanar)
                    5:#(owner.procLayerSelfEnabled,owner.procLayerSelfMultiplier,owner.procLayerSelfGap,owner.procLayerSelfPlanar)
                    default:#(false,1.0,0.0,false)
                )
                if pair and peerList.selection>0 do (
                    local i=root.procPair (scope-2) (if scope==3 then leaf else owner) peers[peerList.selection]
                    if i>0 then rule=#(root.procRuleEnabled[i],root.procRuleMultiplier[i],root.procRuleGap[i],root.procRulePlanar[i])
                    else if scope==3 do rule=#(owner.procSiblingEnabled,owner.procSiblingMultiplier,owner.procSiblingGap,owner.procSiblingPlanar)
                )
                enabledCheck.checked=rule[1];multiplierSpin.value=rule[2];gapSpin.value=rule[3];planarCheck.checked=rule[4]
                ruleInfo.text=if not editable then "Add another owner for a pair rule." else if scope==1 and not leaf.procSelfOverride then "Using layer default. Edit to override this paint set." else "Factor x (radius A + radius B) + gap. Saves automatically."
                binding=wasBinding
            )catch(binding=wasBinding;throw())
        )
        fn bind layer = (binding=true;bindRule();controlsReady=true;binding=false)
        on proceduralUI_1 open do bind owner
        on proceduralUI_1 close do controlsReady=false
        fn saveRule = (
            if binding or not controlsReady do return false
            local leaf=currentSet(),scope=scopeList.selection,pair=scope==3 or scope==4
            if pair and (peerList.selection<1 or peerList.selection>peers.count) do return false
            try (
                undo "Cyrus scoped spacing" on case scope of (
                    1:(leaf.procSelfOverride=true;leaf.procSelfEnabled=enabledCheck.checked;leaf.procSelfMultiplier=multiplierSpin.value;leaf.procSelfGap=gapSpin.value;leaf.procSelfPlanar=planarCheck.checked)
                    2:(owner.procSiblingEnabled=enabledCheck.checked;owner.procSiblingMultiplier=multiplierSpin.value;owner.procSiblingGap=gapSpin.value;owner.procSiblingPlanar=planarCheck.checked)
                    5:(owner.procLayerSelfEnabled=enabledCheck.checked;owner.procLayerSelfMultiplier=multiplierSpin.value;owner.procLayerSelfGap=gapSpin.value;owner.procLayerSelfPlanar=planarCheck.checked)
                    default: root.procSetPair (scope-2) (if scope==3 then leaf else owner) peers[peerList.selection] enabledCheck.checked multiplierSpin.value gapSpin.value planarCheck.checked
                )
                root.invalidateGroups();ruleInfo.text="Factor x (radius A + radius B) + gap. Saves automatically.";true
            )catch(bindRule();messageBox (getCurrentException()) title:"Cyrus spacing";false)
        )
        on scopeList selected i do if not binding do bindRule resetPeer:true
        on peerList selected i do if not binding and i>0 do bindRule()
        on enabledCheck changed value do saveRule()
        on multiplierSpin changed value do saveRule()
        on gapSpin changed value do saveRule()
        on planarCheck changed value do saveRule()
        on resetRule pressed do try(
            local leaf=currentSet(),scope=scopeList.selection
            undo "Cyrus spacing inheritance" on case scope of (
                1: leaf.procSelfOverride=false
                2:(owner.procSiblingEnabled=false;owner.procSiblingMultiplier=1;owner.procSiblingGap=0;owner.procSiblingPlanar=false)
                5:(owner.procLayerSelfEnabled=false;owner.procLayerSelfMultiplier=1;owner.procLayerSelfGap=0;owner.procLayerSelfPlanar=false)
                default:(if peerList.selection>0 do root.procRemoveRule (root.procPair (scope-2) (if scope==3 then leaf else owner) peers[peerList.selection]))
            )
            root.invalidateGroups();bind owner
        )catch(messageBox (getCurrentException()) title:"Cyrus spacing")
        on proceduralUI_1 rolledUp state do (CyrusContainerPanel root).layoutPanels()
    )


proceduralUI_1
)
global CyrusLayerEditor_instanceRadiusUI_1
fn CyrusLayerEditor_instanceRadiusUI_1 = (
    rollout instanceRadiusUI_1 "Instance radii - CS Edit" width:146 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel,controlsReady=false,setSpecific=true
        dropdownlist radiusMode "Selected CS Edit instances" items:#("World radius","Radius multiplier") selection:1 pos:[4,8] width:(instanceRadiusUI_1.width-8) tooltip:"Use an absolute world radius or multiply the selected instances' source radius."
        spinner radiusSpin "Value:" range:[0,1e9,1] pos:[4,60] width:(instanceRadiusUI_1.width-8) fieldWidth:82 tooltip:"Value applied only when Set selected radii is pressed."
        button applyRadius "Set selected radii" pos:[4,88] width:(instanceRadiusUI_1.width-8) tooltip:"Apply radius overrides to selected instances in this layer or older model group."
        button resetRadius "Clear selected overrides" pos:[4,116] width:(instanceRadiusUI_1.width-8) tooltip:"Restore the selected instances' inherited source radii."
        button clearRadius "Clear radius overrides" pos:[4,144] width:(instanceRadiusUI_1.width-8) tooltip:"Remove instance-radius overrides for this layer or older model group."
        label info "Select instances with CS Edit before applying a radius. Overrides follow their stable instance identities." pos:[4,180] width:(instanceRadiusUI_1.width-8) height:54
        fn currentSet = (root.selectedPaintSet owner)
        fn bind layer = (for c in instanceRadiusUI_1.controls do c.enabled=true;controlsReady=true)
        on instanceRadiusUI_1 open do bind owner
        on instanceRadiusUI_1 close do controlsReady=false
        on applyRadius pressed do try((currentSet()).procSelectedRadius radiusMode.selection radiusSpin.value;bind owner)catch(messageBox (getCurrentException()) title:"Cyrus radius")
        on resetRadius pressed do try((currentSet()).procSelectedRadius radiusMode.selection radiusSpin.value reset:true;bind owner)catch(messageBox (getCurrentException()) title:"Cyrus radius")
        on clearRadius pressed do try((currentSet()).procClearRadii();bind owner)catch(messageBox (getCurrentException()) title:"Cyrus radius")
        on instanceRadiusUI_1 rolledUp state do (CyrusContainerPanel root).layoutPanels()
    )

instanceRadiusUI_1
)
global CyrusLayerEditor_spacingUI_1
fn CyrusLayerEditor_spacingUI_1 = (
    rollout spacingUI_1 "Candidate Relax - layer" width:146 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel,obj=undefined,controlsReady=false,binding=false
        checkbox relaxCheck "Point Relax" pos:[4,8] width:(spacingUI_1.width-8) tooltip:"Separate nearby candidates on the receiving surface before Brush, artist edits and spacing. Fixed anchors stay fixed."
        spinner spacingSpin "Desired spacing:" pos:[4,36] width:(spacingUI_1.width-8) fieldWidth:82 type:#worldUnits range:[0.00001,1e9,0.2]
        spinner iterationsSpin "Iterations:" pos:[4,64] width:(spacingUI_1.width-8) fieldWidth:82 type:#integer range:[1,100,10]
        spinner strengthSpin "Strength %:" pos:[4,92] width:(spacingUI_1.width-8) fieldWidth:82 range:[0,100,50]
        checkbox boundaryRelaxCheck "Boundary Relax" pos:[4,128] width:(spacingUI_1.width-8) tooltip:"Smooth candidate neighborhoods with bounded movement. Eligibility is checked before publication; author edits run afterwards."
        spinner finalStrengthSpin "Strength:" pos:[4,156] width:(spacingUI_1.width-8) fieldWidth:82 range:[0,1,.3]
        spinner finalIterSpin "Iterations:" pos:[4,184] width:(spacingUI_1.width-8) fieldWidth:82 type:#integer range:[0,100,5]
        spinner finalMoveSpin "Max movement:" pos:[4,212] width:(spacingUI_1.width-8) fieldWidth:82 type:#worldUnits range:[0,1e9,10]
        label orderHint "Candidates move first; optional Painting, instance edits and spacing follow." pos:[4,244] width:(spacingUI_1.width-8) height:58
        fn bind layer = (
            binding=true;obj=owner
            relaxCheck.checked=obj.relaxEnabled;spacingSpin.value=obj.relaxSpacing;iterationsSpin.value=obj.relaxIterations;strengthSpin.value=obj.relaxStrength*100
            boundaryRelaxCheck.checked=obj.finalRelax;finalStrengthSpin.value=obj.finalStrength;finalIterSpin.value=obj.finalIterations;finalMoveSpin.value=obj.finalMaxMove
            for c in #(spacingSpin,iterationsSpin,strengthSpin) do c.enabled=obj.relaxEnabled
            for c in #(finalStrengthSpin,finalIterSpin,finalMoveSpin) do c.enabled=obj.finalRelax
            controlsReady=true;binding=false
        )
        fn save key value = (if controlsReady and not binding do (undo "Cyrus layer Relax" on setProperty owner key value;root.invalidateGroups()))
        on spacingUI_1 open do bind owner
        on spacingUI_1 close do controlsReady=false
        on spacingUI_1 rolledUp state do (CyrusContainerPanel root).layoutPanels()
        on relaxCheck changed value do (save #relaxEnabled value;bind owner)
        on spacingSpin changed value do save #relaxSpacing value
        on iterationsSpin changed value do save #relaxIterations value
        on strengthSpin changed value do save #relaxStrength (value/100.0)
        on boundaryRelaxCheck changed value do (save #finalRelax value;bind owner)
        on finalStrengthSpin changed value do save #finalStrength value
        on finalIterSpin changed value do save #finalIterations value
        on finalMoveSpin changed value do save #finalMaxMove value
    )

spacingUI_1
)
global CyrusLayerEditor_separationUI_1
fn CyrusLayerEditor_separationUI_1 = (
    rollout separationUI_1 "Cleanup - accepted layer" width:146 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel,controlsReady=false,binding=false
        checkbox cleanCheck "Remove isolated plants" pos:[4,8] width:(separationUI_1.width-8) tooltip:"Remove isolated plants after spacing. Protected instance edits remain."
        spinner neighborSpin "Neighbor distance:" type:#worldUnits range:[0.001,1e9,100] pos:[4,36] width:(separationUI_1.width-8) fieldWidth:82
        spinner minNeighborSpin "Minimum neighbors:" type:#integer range:[0,10000,2] pos:[4,64] width:(separationUI_1.width-8) fieldWidth:82
        spinner minIslandSpin "Minimum island size:" type:#integer range:[0,100000,5] pos:[4,92] width:(separationUI_1.width-8) fieldWidth:82
        checkbox planarCheck "XY neighborhoods (off = 3D)" pos:[4,128] width:(separationUI_1.width-8)
        label helpInfo "Cleanup releases space before bounded refill. Spacing rules are in the selected-scope section." pos:[4,160] width:(separationUI_1.width-8) height:54
        fn bind layer = (
            binding=true
            cleanCheck.checked=owner.finalCleanup;neighborSpin.value=owner.finalNeighborRadius;minNeighborSpin.value=owner.finalMinNeighbors;minIslandSpin.value=owner.finalMinIsland;planarCheck.checked=owner.cleanupPlanar
            for c in #(neighborSpin,minNeighborSpin,minIslandSpin,planarCheck) do c.enabled=owner.finalCleanup
            controlsReady=true;binding=false
        )
        fn save key value = (if controlsReady and not binding do (undo "Cyrus layer cleanup" on setProperty owner key value;root.invalidateGroups()))
        on separationUI_1 open do bind owner
        on separationUI_1 close do controlsReady=false
        on separationUI_1 rolledUp state do (CyrusContainerPanel root).layoutPanels()
        on cleanCheck changed value do (save #finalCleanup value;bind owner)
        on neighborSpin changed value do save #finalNeighborRadius value
        on minNeighborSpin changed value do save #finalMinNeighbors value
        on minIslandSpin changed value do save #finalMinIsland value
        on planarCheck changed value do save #cleanupPlanar value
    )


separationUI_1
)
global CyrusLayerEditor_detailsUI_1
fn CyrusLayerEditor_detailsUI_1 = (
    rollout detailsUI_1 "Statistics / Help" width:146 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel,controlsReady=false
        label info "Statistics describe the last build." pos:[4,74] width:(detailsUI_1.width-8) height:300
        button refreshButton "Read cached statistics" pos:[4,8] width:(detailsUI_1.width-8) tooltip:"Read the existing calculation statistics without regenerating placements."
        button helpButton "Layer / display help" pos:[4,38] width:(detailsUI_1.width-8) tooltip:"Explain settings ownership, display budgets, evaluation order and policy limits."
        fn bind layer = (
            local text="Last completed build\n"
            for leaf in root.layerSets owner do (
                local state=leaf.uiLayerStats(),stats=leaf.groupStats(),cache=leaf.cacheSnapshot(),index=findItem root.layerObjects leaf
                local status=CyrusUILayerState state (root.enabledLayer index) root.cyrusEnabled (root.visibleLayer index)
                text+="\n"+leaf.paintSetName+" | "+status[2]
                local eligible=CyrusUICount stats[1],removed=CyrusUICount stats[2]
                text+="\nRequested: "+(CyrusUICount cache[8])+" | Eligible: "+eligible
                text+="\nPlaced: "+(CyrusUICount state.placements)+" | Removed: "+removed
                text+="\nShown: "+(CyrusUICount state.previewCount)+" | "+(state.buildMs as string)+" ms"
                if stats[3]>0 do text+="\nManual conflicts: "+(CyrusUICount stats[3])
                (
                    local detail=leaf.procStatistics()
                    if detail[1].count==12 do (
                        text+="\nRejected layer / set / self: "+(detail[1][5] as string)+" / "+(detail[1][6] as string)+" / "+(detail[1][7] as string)
                        text+="\nCleanup: "+(detail[1][8] as string)+" | Shortfall: "+(detail[1][11] as string)
                        text+="\nEpoch: "+(detail[5] as string)+" | Rounds: "+(detail[2][1] as string)
                    )
                )
                if state.densityCapped do text+="\nDensity limited to 100,000 candidates."
                if state.errorText!="" do text+="\n"+state.errorText
            )
            info.text=text;info.height=amax 300 ((filterString text "\n").count*17+20);detailsUI_1.height=info.height+86;controlsReady=true
        )
        on detailsUI_1 open do bind owner
        on detailsUI_1 close do controlsReady=false
        on refreshButton pressed do bind owner
        on helpButton pressed do messageBox (info.text+"\n\nEach layer owns its surfaces, models and amount. Optional Paint Areas restrict where those models appear; areas do not create separate populations.\n\nPoint Cloud samples and viewport budgets control display detail. Manual preserves the previous completed result until Update scatter.\n\nEarlier layers win ordinary spacing conflicts. Radius factor x (radius A + radius B) + extra gap sets the required distance. Protected edits are retained and conflicts reported. Advanced settings offer bounded retries, Relax and cleanup. Older files may retain separate model groups.") title:"Cyrus layer help"
        on detailsUI_1 rolledUp state do (CyrusContainerPanel root).layoutPanels()
    )

detailsUI_1
)
global CyrusLayerEditor_workflowUI_1
fn CyrusLayerEditor_workflowUI_1 = (
    rollout workflowUI_1 "Workflow and ownership" width:146 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,panel=CyrusLayerUIPanel,controlsReady=false
        label steps "1. LAYER\nAdd a layer for a group of plants, such as Grass or Trees.\n\n2. SURFACES\nAdd the surfaces this layer should cover. Each layer has its own list.\n\n3. MODELS\nAdd scene models. Select a row to edit its label, preview color and Properties. Source containers are optional under Advanced.\n\n4. AMOUNT\nChoose a total count or plants per square meter. Spacing and masks can reduce the final count.\n\n5. UPDATE SCATTER\nManual waits for Update scatter. Live responds to relevant edits.\n\nOPTIONAL PAINTING\nEnable Use Paint Areas to restrict this layer. Add a named area, choose its surface and paint. Further strokes edit the same area. Turn painting off to use the whole surfaces without deleting your paint." pos:[4,8] width:(selected_workflowUI.width-8) height:500
        label help "Layers own models, amount and surfaces. Paint Areas only control where the layer appears. Advanced settings are optional. Older files may retain separate model groups.\n\nViewport budgets change how much is shown, not the final plant count." pos:[4,516] width:(selected_workflowUI.width-8) height:120
        fn bind layer = (controlsReady=true)
        on workflowUI_1 open do bind owner
        on workflowUI_1 close do controlsReady=false
        on workflowUI_1 rolledUp state do (CyrusContainerPanel root).layoutPanels()
    )

workflowUI_1
)
fn CyrusCreateLayerEditorSection name root owner panel = (
CyrusLayerUIRoot=root;CyrusLayerUIOwner=owner;CyrusLayerUIPanel=panel
case name of (
#setsUI: CyrusLayerEditor_setsUI_1()
#sourceUI: CyrusLayerEditor_sourceUI_1()
#sourceContainersUI: CyrusLayerEditor_sourceContainersUI_1()
#distributionUI: CyrusLayerEditor_distributionUI_1()
#populationPolicyUI: CyrusLayerEditor_populationPolicyUI_1()
#areaUI: CyrusLayerEditor_areaUI_1()
#brushUI: CyrusLayerEditor_brushUI_1()
#backgroundUI: CyrusLayerEditor_backgroundUI_1()
#randomUI: CyrusLayerEditor_randomUI_1()
#diversityUI: CyrusLayerEditor_diversityUI_1()
#proceduralUI: CyrusLayerEditor_proceduralUI_1()
#instanceRadiusUI: CyrusLayerEditor_instanceRadiusUI_1()
#spacingUI: CyrusLayerEditor_spacingUI_1()
#separationUI: CyrusLayerEditor_separationUI_1()
#detailsUI: CyrusLayerEditor_detailsUI_1()
#workflowUI: CyrusLayerEditor_workflowUI_1()
)
)
-- One modeless editor; each topic is built on first use and retained. Binding
-- changes only owner references and controls, never calculation parameters.
global CyrusLayerEditor,CyrusOpenLayerEditor,CyrusBindLayerEditor,CyrusCloseLayerEditor,CyrusLayerEditorSections
global CyrusLayerEditorSize,CyrusLayerEditorPosition
global CyrusBrushSessionRoot,CyrusStopBrush
if CyrusCloseLayerEditor!=undefined do CyrusCloseLayerEditor()
if CyrusLayerEditorSize==undefined do CyrusLayerEditorSize=[920,800]
if CyrusLayerEditorPosition==undefined do CyrusLayerEditorPosition=[80,80]
fn CyrusLayerEditorSections root method:undefined = (
    if CyrusLayerEditor==undefined or CyrusLayerEditor.root!=root then #()
    else for r in CyrusLayerEditor.activeEditors() where method==undefined or isProperty r method collect r
)
fn CyrusCloseLayerEditor = (
    if CyrusLayerEditor!=undefined do destroyDialog CyrusLayerEditor
    CyrusLayerEditor=undefined
    true
)
fn CyrusBindLayerEditor root = (
    if CyrusLayerEditor!=undefined and CyrusLayerEditor.root==root and not CyrusLayerEditor.binding do CyrusLayerEditor.bind()
    true
)
fn CyrusOpenLayerEditor root owner = (
    if owner==undefined or findItem root.layerObjects owner==0 do return false
    if CyrusLayerEditor!=undefined then (CyrusLayerEditor.retarget root owner;CyrusLayerEditor.visible=true;return true)
    rollout editor "Cyrus Scatter 0.77 - Layer Editor" width:920 height:800 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,ownerNode=undefined,binding=false,controlsReady=false,closing=false
        local clientSize=CyrusLayerEditorSize,layingOut=false
        local editors=#(),pages=#(),pageEditors=#(#(),#(),#(),#(),#(),#()),built=#{},topic=1,members=#(),sets=#(),pageSections=#(),ownerStates=#(),lastSet=undefined
        label setupInfo "" pos:[12,10] width:(clientSize.x-178) height:18
        button updateNow "Update setup" pos:[clientSize.x-158,8] width:146 height:24 tooltip:"Recalculate every enabled layer in this setup, in order."
        dropdownlist layerList "Layer" pos:[12,36] width:((clientSize.x-36)/2)
        dropdownlist setList "Existing model group" pos:[clientSize.x/2+6,36] width:((clientSize.x-36)/2)
        checkbutton assetsTab "Assets" pos:[12,90] width:((clientSize.x-34)/6) height:26 checked:true tooltip:"Models and receiving surfaces for this layer."
        checkbutton populationTab "Population" pos:[12+(clientSize.x-22)/6,90] width:((clientSize.x-34)/6) height:26 tooltip:"Shared layer count, density, Area and retry limits."
        checkbutton paintTab "Paint" pos:[12+2*(clientSize.x-22)/6,90] width:((clientSize.x-34)/6) height:26 tooltip:"Optional receiver-bound Paint Areas."
        checkbutton transformTab "Transform" pos:[12+3*(clientSize.x-22)/6,90] width:((clientSize.x-34)/6) height:26 tooltip:"Layer random transforms and source assignment."
        checkbutton spacingTab "Spacing" pos:[12+4*(clientSize.x-22)/6,90] width:((clientSize.x-34)/6) height:26 tooltip:"Self, between-set and layer-pair rules, radii and cleanup."
        checkbutton statisticsTab "Statistics" pos:[12+5*(clientSize.x-22)/6,90] width:((clientSize.x-34)/6) height:26 tooltip:"Cached calculation results and workflow help."
        label pageInfo "" pos:[12,122] width:(clientSize.x-24) height:34
        subrollout assetsLeft "" pos:[8,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout assetsRight "" pos:[clientSize.x/2+4,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout populationLeft "" pos:[8,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout populationRight "" pos:[clientSize.x/2+4,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout paintLeft "" pos:[8,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout paintRight "" pos:[clientSize.x/2+4,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout transformLeft "" pos:[8,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout transformRight "" pos:[clientSize.x/2+4,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout spacingLeft "" pos:[8,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout spacingRight "" pos:[clientSize.x/2+4,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout statisticsLeft "" pos:[8,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout statisticsRight "" pos:[clientSize.x/2+4,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        label resultInfo "" pos:[12,clientSize.y-32] width:(clientSize.x-170) height:22
        button refreshButton "Refresh fields" pos:[clientSize.x-148,clientSize.y-34] width:136 height:24 tooltip:"Read current settings and cached counts; does not rebuild placements."
        timer statusTimer interval:1000 active:false
        fn validOwner = (isValidNode ownerNode and ownerNode.baseObject==root and findItem root.layerObjects owner>0 and owner.logicalParentID=="")
        fn activeEditors = pageEditors[topic]
        fn stopTools = (
            if CyrusBrushSessionRoot==root do CyrusStopBrush()
            -- End Max's pick mode before the same controls acquire a new owner.
            max select
        )
        fn rememberOwner = (
            if owner!=undefined do (
                local row=0
                for i=1 to ownerStates.count where ownerStates[i][1]==owner.layerID do row=i
                local state=#(owner.layerID,topic,for r in editors collect #(r,r.open))
                if row==0 then append ownerStates state else ownerStates[row]=state
            )
        )
        fn refreshStats = (
            if not controlsReady or not validOwner() do return false
            local summary=CyrusFlowLayerSummary root owner
            local unit=if root.viewportMode==1 and not root.groupCenters then " preview samples" else " shown"
            local text=(if root.updateMode==1 then "Manual" else "Live")+" | "+summary[3]+" | "+(CyrusUICount summary[1])+" placed / "+(CyrusUICount summary[2])+unit
            if resultInfo.text!=text do resultInfo.text=text
            local caption="Cyrus Scatter 0.77 | "+ownerNode.name+" / "+(root.layerCaption owner)
            if editor.title!=caption do editor.title=caption
            local setupText="Setup: "+ownerNode.name+"  |  Selecting scene models keeps this editor on its layer"
            if setupInfo.text!=setupText do setupInfo.text=setupText
            true
        )
        fn retainListItems control values = (
            local existing=control.items,changed=existing.count!=values.count
            if not changed do for i=1 to values.count while not changed do changed=existing[i]!=values[i]
            if changed do control.items=values
        )
        fn bindEditors = (
            if not validOwner() do return false
            local previous=binding;binding=true
            try (
                members=root.logicalLayers();sets=root.layerSets owner;setList.visible=sets.count>1
                retainListItems layerList (for m in members collect root.layerCaption m)
                local layerIndex=findItem members owner
                if layerList.selection!=layerIndex do layerList.selection=layerIndex
                retainListItems setList (for m in sets collect m.paintSetName)
                local setIndex=findItem sets (root.selectedPaintSet owner)
                if setList.selection!=setIndex do setList.selection=setIndex
                for r in editors do (
                    local changedOwner=r.root!=root or r.owner!=owner
                    r.root=root;r.owner=owner;r.panel=editor
                    if findItem (activeEditors()) r>0 then r.bind (if isProperty r #setSpecific and r.setSpecific then root.selectedPaintSet owner else owner)
                    else (r.controlsReady=false;if changedOwner and isProperty r #obj do r.obj=undefined)
                )
                lastSet=root.selectedPaintSet owner
                if (CyrusContainerPanel root).controlsReady and not (CyrusContainerPanel root).binding do (CyrusContainerPanel root).bindEditors()
                refreshStats();binding=previous;true
            )catch(binding=previous;throw())
        )
        fn bind = (
            if binding or closing do return false
            if not validOwner() then (CyrusCloseLayerEditor();false) else bindEditors()
        )
        fn showTopic index rebind:false = (
            if index<1 or index>6 do return false
            if topic==index and built[index] do (
                local tabs=#(assetsTab,populationTab,paintTab,transformTab,spacingTab,statisticsTab)
                local previous=binding;binding=true;tabs[index].checked=true;binding=previous
                if rebind then bindEditors() else refreshStats()
                return true
            )
            if topic!=index do stopTools()
            topic=index
            local tabs=#(assetsTab,populationTab,paintTab,transformTab,spacingTab,statisticsTab)
            for i=1 to tabs.count do tabs[i].checked=i==index
            -- Create native controls only after their parent is visible. Max
            -- can otherwise retain empty child pages after a height change.
            for p=1 to pages.count do for c in pages[p] do c.visible=p==index
            if not built[index] do (
                for col=1 to 2 do for spec in pageSections[index][col] do (
                    local r=CyrusCreateLayerEditorSection spec[1] root owner editor
                    append editors r
                    append pageEditors[index] r
                    addSubRollout pages[index][col] r rolledUp:spec[2]
                )
                built[index]=true
            )
            pageInfo.text=(#(
                "PAINT SET  |  Choose models, adjust their share and radii, or use source rectangles. Each model keeps its saved settings when parked outside.",
                "LAYER DEFAULTS  |  Set population and limits. All enabled paint sets share this budget, Area and generation seed.",
                "PAINT SET  |  Paint coverage on the shared surface. Background options reference earlier paint sets; spacing remains independent.",
                "LAYER DEFAULTS  |  Randomize transforms and source assignment. Per-model offsets, scale and forward axes are under Assets.",
                "LAYER + SET RULES  |  Choose the spacing scope first. Within a set, between sets and between layers are independent rules.",
                "CACHED RESULTS  |  Last completed calculation. In Manual mode, pending changes appear after Update."
            ))[index]
            bindEditors();true
        )
        fn retarget nextRoot nextOwner = (
            if root==nextRoot and owner==nextOwner do return bind()
            stopTools();rememberOwner()
            if root!=nextRoot do ownerStates=#()
            root=nextRoot;owner=nextOwner;ownerNode=undefined
            for node in refs.dependentNodes root where isValidNode node and node.baseObject==root do if ownerNode==undefined do ownerNode=node
            if not validOwner() do (CyrusCloseLayerEditor();return false)
            local nextTopic=1,state=undefined
            for row in ownerStates where row[1]==owner.layerID do (nextTopic=row[2];state=row)
            showTopic nextTopic rebind:true
            if state!=undefined do for r in editors do for row in state[3] where row[1]==r do r.open=row[2]
            true
        )
        fn selectSet index = (
            if not binding and index>0 and index<=sets.count and (root.selectedPaintSet owner)!=sets[index] do (stopTools();owner.uiPaintSetID=sets[index].layerID;bindEditors())
        )
        on editor open do (
            pages=#(#(assetsLeft,assetsRight),#(populationLeft,populationRight),#(paintLeft,paintRight),#(transformLeft,transformRight),#(spacingLeft,spacingRight),#(statisticsLeft,statisticsRight))
            pageSections=#(
                #(#(#(#sourceUI,false)),#(#(#sourceContainersUI,false),#(#setsUI,true))),
                #(#(#(#distributionUI,false),#(#populationPolicyUI,false)),#(#(#areaUI,false))),
                #(#(#(#brushUI,false)),#(#(#backgroundUI,false))),
                #(#(#(#randomUI,false)),#(#(#diversityUI,false))),
                #(#(#(#proceduralUI,false),#(#instanceRadiusUI,true)),#(#(#spacingUI,false),#(#separationUI,false))),
                #(#(#(#detailsUI,false)),#(#(#workflowUI,false)))
            )
            for node in refs.dependentNodes root where isValidNode node and node.baseObject==root do if ownerNode==undefined do ownerNode=node
            controlsReady=true;showTopic 1
        )
        on editor resized size do if not layingOut do (
            local target=[amax size.x 720,amax size.y 500]
            if target!=size then setDialogSize editor target else (
                -- The rollout's intrinsic height can differ from the dialog's
                -- client area. Base scroll viewports and footer on this event.
                layingOut=true;clientSize=size
                try(updateRolloutLayout editor forceUpdate:true)catch(layingOut=false;throw())
                layingOut=false
            )
        )
        on editor close do (
            closing=true;statusTimer.active=false;stopTools()
            CyrusLayerEditorSize=getDialogSize editor;CyrusLayerEditorPosition=getDialogPos editor
            editors=#();ownerStates=#();owner=undefined;root=undefined;ownerNode=undefined;controlsReady=false
            CyrusLayerEditor=undefined
        )
        on assetsTab changed value do if not binding do showTopic 1
        on populationTab changed value do if not binding do showTopic 2
        on paintTab changed value do if not binding do showTopic 3
        on transformTab changed value do if not binding do showTopic 4
        on spacingTab changed value do if not binding do showTopic 5
        on statisticsTab changed value do if not binding do showTopic 6
        on layerList selected index do if not binding and index>0 do (
            local next=members[index]
            if next==owner do return false
            undo off root.selectLayer (findItem root.layerObjects next)
            retarget root next
            if (CyrusContainerPanel root).controlsReady do (CyrusContainerPanel root).bind()
        )
        on setList selected index do selectSet index
        on updateNow pressed do try(root.refreshAll();CyrusViewportRedraw();bind())catch(messageBox (getCurrentException()) title:"Cyrus update")
        on refreshButton pressed do bind()
        on statusTimer tick do (
            statusTimer.active=false
            if CyrusInteractionHeld() do (statusTimer.active=true;return false)
            if not validOwner() then CyrusCloseLayerEditor() else if not CyrusInteractionHeld() do (
                local sourceChanges=false
                for leaf in root.layerSets owner where leaf.containerUIChanged do (leaf.containerUIChanged=false;sourceChanges=true)
                if sourceChanges or lastSet!=root.selectedPaintSet owner then bind() else refreshStats()
            )
        )
    )
    CyrusLayerUIRoot=root;CyrusLayerUIOwner=owner
    CyrusLayerEditor=editor
    try (
        createDialog editor width:CyrusLayerEditorSize.x height:CyrusLayerEditorSize.y pos:CyrusLayerEditorPosition style:#(#style_titlebar,#style_sysmenu,#style_resizing) autoLayoutOnResize:false escapeEnable:false
        true
    )catch(CyrusCloseLayerEditor();throw())
)
callbacks.removeScripts id:#CyrusLayerEditorLifecycle
callbacks.addScript #filePreOpen "CyrusCloseLayerEditor()" id:#CyrusLayerEditorLifecycle persistent:false
callbacks.addScript #systemPreReset "CyrusCloseLayerEditor()" id:#CyrusLayerEditorLifecycle persistent:false
callbacks.addScript #nodePreDelete "if CyrusLayerEditor!=undefined and callbacks.notificationParam()==CyrusLayerEditor.ownerNode do CyrusCloseLayerEditor()" id:#CyrusLayerEditorLifecycle persistent:false
callbacks.addScript #sceneUndo "if CyrusLayerEditor!=undefined do CyrusLayerEditor.bind()" id:#CyrusLayerEditorLifecycle persistent:false
callbacks.addScript #sceneRedo "if CyrusLayerEditor!=undefined do CyrusLayerEditor.bind()" id:#CyrusLayerEditorLifecycle persistent:false


plugin simpleObject AminScatterObject
name:"Cyrus Scatter"
classID:#(0x617d43a1,0x395c2e17)
category:"Cyrus"
version:54
initialRollupState:0x8
(
    local layerTransfer=false
    local cachedPoints=undefined
    local cachedAnalyzerRun=-1
    local cachedPointCount=0
    local dirty = true
    -- Session-only validity. Scene identities and publication records are unchanged.
    local inputTimeValidity=undefined,inputTimeStamp=0,inputTimeObserved=0
    local inputTimeQueries=0,inputTimeInvalidations=0
    local timeOwnerRegistered=false
    fn ensureTimeOwner = (
        if not timeOwnerRegistered do (
            for node in refs.dependentNodes this where isValidNode node and node.baseObject==this do (
                CyrusRegisterTimeOwner node;timeOwnerRegistered=true
            )
        )
    )
    fn markInputDirty = (inputTimeValidity=undefined;dirty=true)
    fn inputTimeExpired = (
        if inputTimeValidity==undefined do return false
        local tick=currentTime as integer
        tick<inputTimeValidity[1] or tick>inputTimeValidity[2] or inputTimeStamp!=inputTimeObserved
    )
    fn inputTimeKey = (
        local tick=currentTime as integer
        if inputTimeValidity==undefined or tick<inputTimeValidity[1] or tick>inputTimeValidity[2] do (
            if cyrusScatterInputValidity==undefined do throw "This Scatter script requires matching native binaries with input validity support. Restart Max with the complete script/native pair."
            local nodes=this.validSurfaces(),settings=#(this),maps=#()
            join nodes (this.sources as array);join nodes (this.areaNodes as array);join nodes (this.patternLines as array)
            -- Analyzer is a cached producer. checkAnalyzerRevision() observes
            -- its published output; its icon/receiver clock must not bypass
            -- the Analyzer's own Manual mode or real-time scheduling.
            join nodes (this.effectiveContainers())
            nodes=for n in nodes where isValidNode n collect n
            if this.overlapOwner==undefined do join settings (this.procModifiers())
            this.procWatchDensity()
            if this.densityMap!=undefined and this.distributionMode==3 do append maps this.densityMap
            local interval=cyrusScatterInputValidity settings nodes maps
            inputTimeQueries+=1
            -- Keep one key throughout a validity interval, including stepped keys.
            -- FOREVER has no time component. A dirty notification re-arms the
            -- interval without unnecessarily changing a still-valid time stamp.
            if interval[3] then inputTimeStamp=0
            else if inputTimeStamp<interval[1] or inputTimeStamp>interval[2] do inputTimeStamp=tick
            inputTimeValidity=interval
        )
        inputTimeStamp
    )
    fn invalidateInputTime = (
        if not this.inputTimeExpired() do return false
        inputTimeInvalidations+=1
        CyrusDiagnosticEmit "time.invalidated" "host_callback" this.layerID inputTimeInvalidations "dependency_interval_expired"
        this.markInputDirty();true
    )
    fn liveTimeChanged = (
        if this.updateMode!=2 or not this.cyrusEnabled do return false
        local rootChanged=this.invalidateInputTime(),changed=rootChanged
        for i=1 to this.layerObjects.count where this.enabledLayer i do (
            local leaf=this.layerObjects[i]
            if rootChanged then leaf.markInputDirty()
            else if leaf.invalidateInputTime() do changed=true
        )
        changed
    )
    fn inputTimeStats = (#(inputTimeQueries,inputTimeInvalidations,inputTimeStamp,inputTimeObserved,inputTimeValidity))
    fn publishedInputTime = inputTimeObserved

    local previewError=""
    local generatedCount=0
    local previewBuildCount=0
    local previewBuildMs=0
    local requestedCount=0
    local densityCapped=false
    local cachedPaintRevision=0,paintPopulation="",paintBaseKey="",paintBaseRows=undefined,paintBaseBuilds=0,paintBaseHits=0,paintSignatureRows=undefined
    -- Sole ordered model, with explicit layer defaults and paint-set overrides.
    parameters proceduralSettings (
        procSchemaValid type:#boolean default:true
        procOrder type:#integer default:0
        procSetOrder type:#integer default:0
        procSamplingSalt type:#integer default:0
        procPopulation type:#integer default:1
        procAttemptFactor type:#integer default:8
        procRounds type:#integer default:8
        procRepair type:#boolean default:true
        procSelfOverride type:#boolean default:false
        procSelfEnabled type:#boolean default:true
        procSelfMultiplier type:#float default:1.0
        procSelfGap type:#worldUnits default:0.0
        procSelfPlanar type:#boolean default:false
        procLayerSelfEnabled type:#boolean default:false
        procLayerSelfMultiplier type:#float default:1.0
        procLayerSelfGap type:#worldUnits default:0.0
        procLayerSelfPlanar type:#boolean default:false
        procSiblingEnabled type:#boolean default:false
        procSiblingMultiplier type:#float default:1.0
        procSiblingGap type:#worldUnits default:0.0
        procSiblingPlanar type:#boolean default:false
        procBackground type:#integer default:1
        procBackgroundIDs type:#stringTab tabSize:0 tabSizeVariable:true
        procRadiusIDs type:#stringTab tabSize:0 tabSizeVariable:true
        procRadiusModes type:#intTab tabSize:0 tabSizeVariable:true
        procRadiusValues type:#floatTab tabSize:0 tabSizeVariable:true
        procRadiusBinding type:#string default:""
        procSourceNodes type:#nodeTab tabSize:0 tabSizeVariable:true
        procSourceIDs type:#stringTab tabSize:0 tabSizeVariable:true
        procSourceSlots type:#stringTab tabSize:0 tabSizeVariable:true
        procReceiverNodes type:#nodeTab tabSize:0 tabSizeVariable:true
        procReceiverIDs type:#stringTab tabSize:0 tabSizeVariable:true
        procReceiverID type:#string default:""
        procRuleScope type:#intTab tabSize:0 tabSizeVariable:true
        procRuleA type:#stringTab tabSize:0 tabSizeVariable:true
        procRuleB type:#stringTab tabSize:0 tabSizeVariable:true
        procRuleEnabled type:#boolTab tabSize:0 tabSizeVariable:true
        procRuleMultiplier type:#floatTab tabSize:0 tabSizeVariable:true
        procRuleGap type:#floatTab tabSize:0 tabSizeVariable:true
        procRulePlanar type:#boolTab tabSize:0 tabSizeVariable:true
        containerMode type:#integer default:1
        containerNodes type:#nodeTab tabSize:0 tabSizeVariable:true useNodeTmValidity:true useNodeOsValidity:true
        containerGlobalNodes type:#nodeTab tabSize:0 tabSizeVariable:true useNodeTmValidity:true useNodeOsValidity:true
        on procOrder set value do markInputDirty()
        on procSetOrder set value do markInputDirty()
        on procSamplingSalt set value do markInputDirty()
        on procPopulation set value do markInputDirty()
        on procAttemptFactor set value do markInputDirty()
        on procRounds set value do markInputDirty()
        on procRepair set value do markInputDirty()
        on procSelfOverride set value do markInputDirty()
        on procSelfEnabled set value do markInputDirty()
        on procSelfMultiplier set value do markInputDirty()
        on procSelfGap set value do markInputDirty()
        on procSelfPlanar set value do markInputDirty()
        on procLayerSelfEnabled set value do markInputDirty()
        on procLayerSelfMultiplier set value do markInputDirty()
        on procLayerSelfGap set value do markInputDirty()
        on procLayerSelfPlanar set value do markInputDirty()
        on procSiblingEnabled set value do markInputDirty()
        on procSiblingMultiplier set value do markInputDirty()
        on procSiblingGap set value do markInputDirty()
        on procSiblingPlanar set value do markInputDirty()
        on procBackground set value do markInputDirty()
        on procBackgroundIDs set value index do markInputDirty()
        on procRadiusIDs set value index do markInputDirty()
        on procRadiusModes set value index do markInputDirty()
        on procRadiusValues set value index do markInputDirty()
        on procRadiusBinding set value do markInputDirty()
        on procSourceNodes set value index do markInputDirty()
        on procSourceIDs set value index do markInputDirty()
        on procSourceSlots set value index do markInputDirty()
        on procReceiverNodes set value index do markInputDirty()
        on procReceiverIDs set value index do markInputDirty()
        on procReceiverID set value do markInputDirty()
        on procRuleScope set value index do markInputDirty()
        on procRuleA set value index do markInputDirty()
        on procRuleB set value index do markInputDirty()
        on procRuleEnabled set value index do markInputDirty()
        on procRuleMultiplier set value index do markInputDirty()
        on procRuleGap set value index do markInputDirty()
        on procRulePlanar set value index do markInputDirty()
        on containerMode set value do markInputDirty()
        on containerNodes set value index do markInputDirty()
        on containerGlobalNodes set value index do markInputDirty()
    )
    local procCandidateCount=undefined,procPreparedKey="",procPreparedRows=#(),procBindingKey="",procBoundBase=undefined,procSurfaceKey=""
    local procReceiverPlanData=#(#(),#(),0,0,false),procReceiverCache=#(),procReceiverGeometry=#(),procReceiverBuilds=0,procReceiverHits=0
    local procLastStats=#(),procLastRounds=#(),procPreparedBuilds=0,procPreparedHits=0,procEpoch=0,procPublishedDisplayKey="",procManualRevision=0
    local procPublishedOwners=#(),procPublishedSources=#(),procPublishedFinalKeep=#()
    local procPublishedRadii=#(),procPublishedInfo=#()
    local procDensityMap=undefined,procDensityWatch=undefined,procDensityRevision=0
    local procGeometryRevision=0,containerConfigKey="",containerPending=#(),containerScan=true,containerScans=0,containerTests=0
    local containerMembershipKey="",containerActive=#(),containerReconciling=false
    local containerTrackedSources=#(),containerTrackedPivots=#(),containerCachedFrames=#(),containerFrameState=#(),containerMembershipBuilds=0
    local containerUIChanged=false

    parameters paintSettings (
        paintView type:#integer default:2
        paintColor type:#color default:(color 90 200 150)
        paintDocument type:#maxObject
        paintEnabled type:#boolean default:false
        paintDensity type:#float default:1
        editLayerKey type:#integer default:0
        nextEditLayerKey type:#integer default:1
        on paintDocument set value do (cachedPaintRevision=0;markInputDirty())
        on paintEnabled set value do markInputDirty()
        on paintDensity set value do markInputDirty()
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
        on surface set v do markInputDirty()
        on sources set v i do markInputDirty()
        on amount set v do markInputDirty()
        on randomSeed set v do markInputDirty()
        on scaleMinimum set v do markInputDirty()
        on scaleMaximum set v do markInputDirty()
        on tiltDegrees set v do markInputDirty()
        on yawMinimum set v do markInputDirty()
        on yawMaximum set v do markInputDirty()
        on movementRange set v do markInputDirty()
        on alignNormal set v do markInputDirty()
        on pointsPerPlant set v do markInputDirty()
    )
    parameters surfaceSettings (
        surfaceNodes type:#nodeTab tabSize:0 tabSizeVariable:true useNodeTmValidity:true useNodeOsValidity:true
        on surfaceNodes set v i do markInputDirty()
    )
    parameters updateSettings (
        updateMode type:#integer default:2
        on updateMode set v do (markInputDirty();if not layerTransfer do CyrusViewportRedraw())
    )
    parameters populationSettings (
        populationMode type:#integer default:1
        plantsPerM2 type:#float default:100
        on populationMode set v do markInputDirty()
        on plantsPerM2 set v do markInputDirty()
    )
    fn validSurfaces = (
        local result=#()
        local nodes=if surfaceNodes.count>0 then (surfaceNodes as array) else #(surface)
        if this.layerObjects.count>0 do for layer in this.layerObjects where layer.ownsReceivers do join nodes (layer.validSurfaces())
        for n in nodes where isValidNode n and classof n.baseObject!=AminScatterObject and findItem result n==0 do append result n
        result
    )
    local overlapOwner=undefined,overlapBefore=0,overlapAfter=0
    parameters overlapSettings (
        cleanupPlanar type:#boolean default:true
        on cleanupPlanar set v do markInputDirty()
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
        on finalCleanup set v do markInputDirty()
        on finalNeighborRadius set v do markInputDirty()
        on finalMinNeighbors set v do markInputDirty()
        on finalMinIsland set v do markInputDirty()
        on finalRelax set v do markInputDirty()
        on finalStrength set v do markInputDirty()
        on finalIterations set v do markInputDirty()
        on finalMaxMove set v do markInputDirty()
    )
    parameters viewportGeometrySettings (
        viewportMode type:#integer default:1
        proxyShape type:#integer default:1
        viewportInstances type:#integer default:2000
        viewportFaces type:#integer default:2000000
        on viewportMode set v do markInputDirty()
        on proxyShape set v do markInputDirty()
        on viewportInstances set v do markInputDirty()
        on viewportFaces set v do markInputDirty()
    )
    parameters radiusDisplaySettings (
        radiusDisplayLimit type:#integer default:2000
        radiusDisplayAll type:#boolean default:false
        on radiusDisplayLimit set v do markInputDirty()
        on radiusDisplayAll set v do markInputDirty()
    )
    parameters radiusSettings (
        sourceRadii type:#floatTab tabSize:0 tabSizeVariable:true
        sourceFollowScale type:#boolTab tabSize:0 tabSizeVariable:true
        sourceShowRadius type:#boolTab tabSize:0 tabSizeVariable:true
        on sourceRadii set v i do markInputDirty()
        on sourceFollowScale set v i do markInputDirty()
        on sourceShowRadius set v i do markInputDirty()
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
        markInputDirty()
    )
    parameters emptySettings (
        sourcePoint type:#boolTab tabSize:0 tabSizeVariable:true
        on sourcePoint set v i do markInputDirty()
        sourceEmpty type:#boolTab tabSize:0 tabSizeVariable:true
        on sourceEmpty set v i do markInputDirty()
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
        on fallAnalyzer set v do markInputDirty()
        on fallDelete set v do markInputDirty()
        on fallDeleteWidth set v do markInputDirty()
        on fallScale set v do markInputDirty()
        on fallScaleWidth set v do markInputDirty()
        on fallScaleCurve set v i do markInputDirty()
        on fallDensity set v do markInputDirty()
        on fallDensityWidth set v do markInputDirty()
        on fallDensityCurve set v i do markInputDirty()
    )
    fn ensureFallCurves = (
        while fallScaleCurve.count<5 do append fallScaleCurve (fallScaleCurve.count/4.0)
        while fallDensityCurve.count<5 do append fallDensityCurve (fallDensityCurve.count/4.0)
    )
    parameters wholeScaleSettings (
        wholeScaleMin type:#float default:1.0
        wholeScaleMax type:#float default:1.0
        on wholeScaleMin set v do markInputDirty()
        on wholeScaleMax set v do markInputDirty()
    )
    local cachedAreaAnalyzerRun=-1
    parameters analyzerAreaSettings (
        areaAnalyzer type:#node useNodeTmValidity:true useNodeOsValidity:true
        on areaAnalyzer set v do markInputDirty()
        areaUseLine type:#boolean default:false
        on areaUseLine set v do markInputDirty()
        areaLineWidth type:#worldunits default:100
        on areaLineWidth set v do markInputDirty()
        areaLineCaps type:#integer default:1
        on areaLineCaps set v do markInputDirty()
        areaUsePoints type:#boolean default:false
        on areaUsePoints set v do markInputDirty()
        areaPointRadius type:#worldunits default:100
        on areaPointRadius set v do markInputDirty()
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
        on areaFallConfigs set v i do markInputDirty()
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
        markInputDirty()
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
            rows=cyrusBoundaryFalloff rows paths cfg (this.effectiveSeed()) true
        )
        for i=1 to this.areaNodes.count where isValidNode this.areaNodes[i] do (
            cfg=getFallConfig this.areaNodes[i]
            if cfg[1] or cfg[3] or cfg[6] do rows=cyrusAreaFalloff rows this.areaNodes[i] cfg (((mod ((this.effectiveSeed() as integer64)+i*1009) 2147483647)) as integer) (if i<=this.areaModes.count then this.areaModes[i] else 1) true
        )
        rows
    )


    parameters edgeRowSettings (
        edgeRotX type:#floatTab tabSize:0 tabSizeVariable:true
        on edgeRotX set v i do markInputDirty()
        edgeRotY type:#floatTab tabSize:0 tabSizeVariable:true
        on edgeRotY set v i do markInputDirty()
        edgeRotZ type:#floatTab tabSize:0 tabSizeVariable:true
        on edgeRotZ set v i do markInputDirty()
        edgeKeepCorners type:#boolean default:false
        edgeCornerAngle type:#float default:45
        edgeCornerCount type:#integer default:1
        on edgeKeepCorners set v do markInputDirty()
        on edgeCornerAngle set v do markInputDirty()
        on edgeCornerCount set v do markInputDirty()
        edgeOffsets type:#floatTab tabSize:0 tabSizeVariable:true
        edgeAlong type:#floatTab tabSize:0 tabSizeVariable:true
        edgeAcross type:#floatTab tabSize:0 tabSizeVariable:true
        edgeFaceOut type:#boolean default:true
        edgeCornerRadius type:#worldunits default:10.0
        on edgeOffsets set v i do markInputDirty()
        on edgeAlong set v i do markInputDirty()
        on edgeAcross set v i do markInputDirty()
        on edgeFaceOut set v do markInputDirty()
        on edgeCornerRadius set v do markInputDirty()
    )
    parameters orientationSettings (
        sourceForwardAxes type:#intTab tabSize:0 tabSizeVariable:true
        borderFaceOut type:#boolean default:false
        streetFaceOut type:#boolean default:false
        borderCornerRadius type:#worldunits default:10.0
        streetCornerRadius type:#worldunits default:10.0
        on sourceForwardAxes set v i do markInputDirty()
        on borderFaceOut set v do markInputDirty()
        on streetFaceOut set v do markInputDirty()
        on borderCornerRadius set v do markInputDirty()
        on streetCornerRadius set v do markInputDirty()
    )
    fn sourceForward i = (if i>0 and i<=sourceForwardAxes.count then amax 1 (amin 4 sourceForwardAxes[i]) else 1)
    fn assignSourceForward rows value = (
        undo "Cyrus source forward axis" on (
            while sourceForwardAxes.count<sources.count do append sourceForwardAxes 1
            for i in rows where i>0 and i<=sources.count do sourceForwardAxes[i]=value
        )
        markInputDirty()
    )
    parameters sourceTransformSettings (
        sourceZOffsets type:#floatTab tabSize:0 tabSizeVariable:true
        sourceScales type:#floatTab tabSize:0 tabSizeVariable:true
        on sourceZOffsets set v i do markInputDirty()
        on sourceScales set v i do markInputDirty()
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
        markInputDirty()
    )
    parameters weightSettings (
        sourceWeights type:#floatTab tabSize:0 tabSizeVariable:true
        on sourceWeights set v i do markInputDirty()
    )
    fn sourceWeight i = (if i>0 and i<=sourceWeights.count then sourceWeights[i] else 1.0)
    fn assignWeight rows value = (
        undo "Cyrus Scatter source weight" on (
            while sourceWeights.count<sources.count do append sourceWeights 1.0
            for i in rows where i>0 and i<=sources.count do sourceWeights[i]=amin 1.0 (amax 0.0 value)
        )
        markInputDirty()
    )
    parameters centerDisplay (
        showCenters type:#boolean default:false
        on showCenters set v do (markInputDirty();previewBuildCount=0)
    )
    parameters spacingSettings (
        relaxEnabled type:#boolean default:false
        relaxSpacing type:#worldUnits default:0.2
        relaxIterations type:#integer default:10
        relaxStrength type:#float default:0.5
        on relaxEnabled set v do markInputDirty()
        on relaxSpacing set v do markInputDirty()
        on relaxIterations set v do markInputDirty()
        on relaxStrength set v do markInputDirty()
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
        on projectMove set v do markInputDirty()
        on rotXMin set v do (if not layerTransfer and v>rotXMax do rotXMax=v;markInputDirty())
        on rotXMax set v do (if not layerTransfer and v<rotXMin do rotXMin=v;markInputDirty())
        on rotYMin set v do (if not layerTransfer and v>rotYMax do rotYMax=v;markInputDirty())
        on rotYMax set v do (if not layerTransfer and v<rotYMin do rotYMin=v;markInputDirty())
        on rotZMin set v do (if not layerTransfer and v>rotZMax do rotZMax=v;markInputDirty())
        on rotZMax set v do (if not layerTransfer and v<rotZMin do rotZMin=v;markInputDirty())
        on sclXMin set v do (if not layerTransfer and v>sclXMax do sclXMax=v;markInputDirty())
        on sclXMax set v do (if not layerTransfer and v<sclXMin do sclXMin=v;markInputDirty())
        on sclYMin set v do (if not layerTransfer and v>sclYMax do sclYMax=v;markInputDirty())
        on sclYMax set v do (if not layerTransfer and v<sclYMin do sclYMin=v;markInputDirty())
        on sclZMin set v do (if not layerTransfer and v>sclZMax do sclZMax=v;markInputDirty())
        on sclZMax set v do (if not layerTransfer and v<sclZMin do sclZMin=v;markInputDirty())
        on movXMin set v do (if not layerTransfer and v>movXMax do movXMax=v;markInputDirty())
        on movXMax set v do (if not layerTransfer and v<movXMin do movXMin=v;markInputDirty())
        on movYMin set v do (if not layerTransfer and v>movYMax do movYMax=v;markInputDirty())
        on movYMax set v do (if not layerTransfer and v<movYMin do movYMin=v;markInputDirty())
        on movZMin set v do (if not layerTransfer and v>movZMax do movZMax=v;markInputDirty())
        on movZMax set v do (if not layerTransfer and v<movZMin do movZMin=v;markInputDirty())
    )
    parameters distributionSettings (
        distributionMode type:#integer default:1
        clusterCount type:#integer default:12
        clusterRadius type:#worldUnits default:10
        densityMap type:#textureMap
        invertDensity type:#boolean default:false
        on distributionMode set v do markInputDirty()
        on clusterCount set v do markInputDirty()
        on clusterRadius set v do markInputDirty()
        on densityMap set v do markInputDirty()
        on invertDensity set v do markInputDirty()
    )
    parameters diversitySettings (
        diversityMode type:#integer default:1
        diversitySize type:#worldUnits default:10
        diversitySeed type:#integer default:42
        roughness type:#float default:0
        blurryEdge type:#float default:0
        diversityNoise type:#float default:0
        on diversityMode set v do markInputDirty()
        on diversitySize set v do markInputDirty()
        on diversitySeed set v do markInputDirty()
        on roughness set v do markInputDirty()
        on blurryEdge set v do markInputDirty()
        on diversityNoise set v do markInputDirty()
    )
    parameters displaySettings (
        autoRender type:#boolean default:true
        previewBudget type:#integer default:20000
        on previewBudget set v do markInputDirty()
        pointColorMode type:#integer default:2
        solidPointColor type:#color default:(color 100 220 120)
        on pointColorMode set v do if not layerTransfer do CyrusViewportRedraw()
        on solidPointColor set v do if not layerTransfer do CyrusViewportRedraw()
    )
    fn displayPointColor groupColor = (if pointColorMode==1 then solidPointColor else groupColor)
    parameters areaSettings (
        areaNodes type:#nodeTab tabSize:0 tabSizeVariable:true useNodeTmValidity:true useNodeOsValidity:true
        areaModes type:#intTab tabSize:0 tabSizeVariable:true
        on areaNodes set v i do markInputDirty()
        on areaModes set v i do markInputDirty()
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
        on sourceColors set v i do markInputDirty()
    )
    parameters lineSettings (
        patternLines type:#nodeTab tabSize:0 tabSizeVariable:true useNodeTmValidity:true useNodeOsValidity:true
        patternWidths type:#worldUnitsTab tabSize:0 tabSizeVariable:true
        patternGroups type:#intTab tabSize:0 tabSizeVariable:true
        patternRestGroup type:#integer default:-1
        on patternLines set v i do markInputDirty()
        on patternWidths set v i do markInputDirty()
        on patternGroups set v i do markInputDirty()
        on patternRestGroup set v do markInputDirty()
    )
    fn assignLineGroup rows key = (
        undo "Cyrus Scatter band group" on (for i in rows where i>0 and i<=patternGroups.count do patternGroups[i]=key)
        markInputDirty()
    )
    fn assignRestGroup key = (patternRestGroup=key;markInputDirty())
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
            if affected do markInputDirty()
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
    fn invalidateLive = (if updateMode==2 do markInputDirty())
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
        markInputDirty()
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
        markInputDirty();sources.count
    )
    fn addPointSource = (
        local i=addEmptySource()
        while sourcePoint.count<sources.count do append sourcePoint false
        sourcePoint[i]=true;markInputDirty();i
    )
    fn replacePointSource row node = (
        if not (isPointSource row) or not (usableSource node) or findItem sources node>0 do return false
        undo "Cyrus Scatter replace point" on (
            sources[row]=node;sourcePoint[row]=false;sourceEmpty[row]=false
        )
        markInputDirty();previewBuildCount=0;true
    )
    fn placementRadii rows plants = (this.procRadii rows plants)
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
        on streetStraight set v do markInputDirty()
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
        on analyzerNode set v do markInputDirty()
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
        syncStrokes();markInputDirty();patternLines.count
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
        markInputDirty()
    )
    fn setStrokeSelection row mode values = (
        local rows=if mode==1 then strokeColorRows else strokeSourceRows
        local targets=if mode==1 then strokeColorKeys else strokeSourceNodes
        for i=rows.count to 1 by -1 where rows[i]==row do (deleteItem rows i;deleteItem targets i)
        for value in values do (append rows row;append targets value)
        if mode==1 do patternGroups[row]=if values.count>0 then values[1] else -1
        markInputDirty()
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
        on cyrusEnabled set v do (markInputDirty();CyrusViewportRedraw())
    )
    fn analyzerOff n = (isValidNode n and isProperty n #cyrusEnabled and not n.cyrusEnabled)
    fn disabledAnalyzerInput = (
        (diversityMode==4 and analyzerOff analyzerNode) or
        ((areaUseLine or areaUsePoints) and analyzerOff areaAnalyzer) or
        ((fallDelete or fallScale or fallDensity) and analyzerOff fallAnalyzer)
    )
    fn requireCurrentAnalyzers = (
        local guides=#()
        if diversityMode==4 do appendIfUnique guides analyzerNode
        if areaUseLine or areaUsePoints do appendIfUnique guides areaAnalyzer
        if fallDelete or fallScale or fallDensity do appendIfUnique guides fallAnalyzer
        for guide in guides where isValidNode guide and not (analyzerOff guide) do (
            if not isProperty guide #analysisCurrent do throw "Update the Surface Analyzer script to the matching package."
            if not guide.analysisCurrent() do throw ("Update Surface Analyzer '"+guide.name+"' first, then update Scatter. Its guides are out of date; the previous Scatter result is preserved.")
        )
        true
    )
    parameters streetLayoutSettings (
        streetTrimStart type:#worldunits default:0
        streetTrimEnd type:#worldunits default:0
        centerStreetOffset type:#worldunits default:0
        on streetTrimStart set v do markInputDirty()
        on streetTrimEnd set v do markInputDirty()
        on centerStreetOffset set v do markInputDirty()
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
                if choices.count>0 do (
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
            )
            #(true,rest,bands)
        )
    )


    -- Logical layers own policy; population objects are stable, independent sets.
    parameters layerOwnership (
        logicalParentID type:#string default:""
        paintSetName type:#string default:"Base"
        paintSetWeight type:#float default:1.0
        paintSetEnabled type:#boolean default:true
        paintSetVisible type:#boolean default:true
        uiPaintSetID type:#string default:""
        on logicalParentID set value do markInputDirty()
        on paintSetWeight set value do markInputDirty()
        on paintSetEnabled set value do markInputDirty()
    )
    fn logicalParent leaf = (
        if leaf.logicalParentID=="" do return leaf
        for candidate in this.layerObjects where candidate.layerID==leaf.logicalParentID and candidate.logicalParentID=="" do return candidate
        throw "Cyrus paint set has no owning layer. Restore its parent before evaluating."
    )
    fn logicalLayers = (
        local members=for leaf in this.layerObjects where leaf.logicalParentID=="" collect leaf
        this.procSort members
    )
    fn layerSets parent = (
        local members=for leaf in this.layerObjects where leaf==parent or leaf.logicalParentID==parent.layerID collect leaf
        this.procSort members sets:true
    )
    fn enabledLayer i = (
        if i<1 or i>this.layerObjects.count or not this.layerEnabled[i] do return false
        local leaf=this.layerObjects[i],parent=this.logicalParent leaf,p=findItem this.layerObjects parent
        p>0 and this.layerEnabled[p] and leaf.paintSetEnabled
    )
    fn visibleLayer i = (
        if i<1 or i>this.layerObjects.count do return false
        local leaf=this.layerObjects[i],parent=this.logicalParent leaf,p=findItem this.layerObjects parent
        p>0 and (p>this.layerVisible.count or this.layerVisible[p]) and (i>this.layerVisible.count or this.layerVisible[i]) and leaf.paintSetVisible
    )
    fn selectedPaintSet parent = (
        local members=this.layerSets parent
        for leaf in members where leaf.layerID==parent.uiPaintSetID do return leaf
        parent
    )
    fn layerCaption parent = (local i=findItem this.layerObjects parent;if i>0 then this.layerNames[i] else "Removed layer")
    fn setCaption leaf = ((this.layerCaption (this.logicalParent leaf))+" / "+leaf.paintSetName)
    fn populationAllocation leaf countOverride:undefined = (
        local parent=this.logicalParent leaf,members=(for candidate in this.layerObjects where candidate==parent or candidate.logicalParentID==parent.layerID collect candidate),total=0.0,shares=#(),fractions=#()
        local budget=if countOverride==undefined then parent.amount else countOverride,remaining=budget
        for member in members do total+=if this.enabledLayer (findItem this.layerObjects member) then amax 0.0 member.paintSetWeight else 0.0
        if total<=0 do return #(0,0.0)
        for member in members do (
            local weight=if this.enabledLayer (findItem this.layerObjects member) then amax 0.0 member.paintSetWeight else 0.0
            local exact=budget*weight/total,n=(floor exact) as integer
            append shares n;append fractions (exact-n);remaining-=n
        )
        -- Largest remainder; creation order is stable when weights tie.
        for n=1 to remaining do (
            local best=0
            for i=1 to members.count where fractions[i]>=0 do if best==0 or fractions[i]>fractions[best] do best=i
            if best>0 do (shares[best]+=1;fractions[best]=-1)
        )
        local index=findItem members leaf
        #(shares[index],if this.enabledLayer (findItem this.layerObjects leaf) then parent.plantsPerM2*(amax 0.0 leaf.paintSetWeight)/total else 0.0)
    )
    fn effectivePopulation = (if this.overlapOwner==undefined then #(amount,plantsPerM2) else this.overlapOwner.populationAllocation this)
    fn effectiveSeed = (
        ((mod ((randomSeed as integer64)+(procSamplingSalt as integer64)*104729) 2147483647) as integer)
    )
    fn layerPaintActive = (
        if this.overlapOwner==undefined do return this.brushMaskActive()
        local parent=this.overlapOwner.logicalParent this
        for leaf in this.overlapOwner.layerSets parent where this.overlapOwner.enabledLayer (findItem this.overlapOwner.layerObjects leaf) and leaf.brushMaskActive() do return true
        false
    )
    fn syncLogicalSettings = (
        local own=#(#procOrder,#procSetOrder,#procSamplingSalt,#procPopulation,#procAttemptFactor,#procRounds,#procRepair,#procSelfOverride,#procSelfEnabled,#procSelfMultiplier,#procSelfGap,#procSelfPlanar,#procSiblingEnabled,#procSiblingMultiplier,#procSiblingGap,#procSiblingPlanar,#procBackground,#procBackgroundIDs,#procRadiusIDs,#procRadiusModes,#procRadiusValues,#procRadiusBinding,#procSourceNodes,#procSourceIDs,#procSourceSlots,#procReceiverNodes,#procReceiverIDs,#procReceiverID,#containerMode,#containerNodes,#sources,#sourceWeights,#sourceColors,#sourceZOffsets,#sourceScales,#sourceForwardAxes,#sourceRadii,#sourceFollowScale,#sourceShowRadius,#sourcePoint,#sourceEmpty,#bakedNodes,#paintDocument,#paintEnabled,#paintDensity,#paintView,#paintColor,#logicalParentID,#paintSetName,#paintSetWeight,#paintSetEnabled,#paintSetVisible,#uiPaintSetID)
        undo off for leaf in this.layerObjects where leaf.logicalParentID!="" do (
            local parent=this.logicalParent leaf
            for key in AminScatterLayerFields where findItem own key==0 do (
                local value=getProperty parent key,previous=getProperty leaf key
                local tab=findItem AminScatterLayerTabs key>0,same=false
                if tab then (
                    same=previous.count==value.count
                    if same do for i=1 to value.count where previous[i]!=value[i] do same=false
                ) else same=previous==value
                if not same do setProperty leaf key (if tab then value as array else value)
            )
            for key in #(#strokeSides,#patternPaths,#strokeModes,#strokeColorRows,#strokeColorKeys,#strokeSourceRows,#strokeSourceNodes,#strokeMin,#strokeMax) do (
                local value=getProperty parent key
                local previous=getProperty leaf key,same=previous.count==value.count
                if same do for i=1 to value.count where previous[i]!=value[i] do same=false
                if not same do setProperty leaf key (value as array)
            )
            if leaf.analyzerNode!=parent.analyzerNode do leaf.analyzerNode=parent.analyzerNode
        )
    )
    fn addPaintSet parent label:"Paint set" = (
        if findItem this.layerObjects parent==0 or parent.logicalParentID!="" do throw "Choose an owning layer."
        if this.layerObjects.count>=10 do throw "Cyrus currently supports 10 total populations, including paint sets."
        local leaf
        undo "Cyrus add paint set" on (
            this.newLayer();leaf=this.selectedLayer()
            leaf.logicalParentID=parent.layerID;leaf.paintSetName=label
            (leaf.procSamplingSalt=leaf.editLayerKey;leaf.procSetOrder=this.nextEditLayerKey)
            leaf.paintEnabled=true
            local targets=this.validSurfaces()
            if targets.count==1 do leaf.paintDocument=cyrusBrushCreate targets[1]
            parent.uiPaintSetID=leaf.layerID
            this.syncLogicalSettings()
        )
        this.invalidateGroups();this.bindNativeUI();leaf
    )
    fn removeLogicalLayer parent = (
        local members=this.layerSets parent
        for member in members where (for node in member.bakedNodes where isValidNode node collect node).count>0 do throw "Remove the layer's baked output before deleting it."
        undo "Cyrus remove layer" on (
            for i=this.layerObjects.count to 1 by -1 where findItem members this.layerObjects[i]>0 do (this.activeLayer=i;this.removePopulation())
        )
        this.invalidateGroups();this.bindNativeUI()
    )
    fn removePaintSet leaf = (
        if leaf.logicalParentID=="" do throw "The base set belongs to the layer. Disable it or clear its sources/paint; remove the layer to delete it."
        undo "Cyrus remove paint set" on (this.activeLayer=findItem this.layerObjects leaf;this.removePopulation())
        this.invalidateGroups();this.bindNativeUI()
    )
    fn copyLogicalLayer origin = (
        local members=(for candidate in this.layerObjects where candidate==origin or candidate.logicalParentID==origin.layerID collect candidate),copyParent,copies=#()
        if this.layerObjects.count+members.count>10 do throw "Copy exceeds the 10-population capacity."
        undo "Cyrus copy layer and paint sets" on (
            for member in members do (
                this.newLayer();local destination=this.selectedLayer();append copies destination
                AminScatterCopyLayer member destination
                destination.bakedNodes=#()
                if member==origin then (
                    copyParent=destination;destination.logicalParentID="";destination.uiPaintSetID=""
                    this.layerNames[this.activeLayer]=(this.layerCaption origin)+" copy"
                ) else destination.logicalParentID=copyParent.layerID
            )
            this.procCopyRelations members copies
        )
        this.invalidateGroups();this.bindNativeUI();copyParent
    )


    parameters plantingSettings (
        groupCenters type:#boolean default:false
    )
    local groupSnapshotKey="",groupSnapshotRows=#(),groupSolving=false,groupDisplayOnly=false,procExplicitUpdate=false
    local groupBuilds=0,groupHits=0,groupPrepareKey="",groupPrepareRows=#(),groupPrepareBuilds=0
    local groupEligible=0,groupConflicts=0,groupRemoved=0
    fn sharedSpacing = (overlapOwner!=undefined)
    fn invalidateGroups = (for group in this.layerObjects do group.markInputDirty();CyrusViewportRedraw())
    fn groupCounters = (#(groupBuilds,groupHits,groupPrepareBuilds))
    fn groupStats = (#(groupEligible,groupRemoved,groupConflicts))
    fn setGroupDisplay mode = (
        if mode<1 or mode>4 do throw "Unknown Cyrus display mode."
        groupCenters=mode==4;viewportMode=if mode==4 then 1 else mode
        this.refreshDisplay()
    )


    fn removeGroupRules group = (this.procRemoveOwner group)

    fn publishGroupEdits rows = (
        for node in refs.dependentNodes this where node.baseObject==this do (
            local mods=for m in node.modifiers where classof m==CyrusScatterEdit and m.enabled collect m
            if mods.count>0 do for i=1 to this.layerObjects.count do cyrusEditPublish mods this.layerObjects[i].editLayerKey rows[i]
        )
    )
    fn groupInputKey = (this.procInputKey())

    fn setGroupResult eligibleCount finalCount conflicts = (
        groupEligible=eligibleCount;groupRemoved=eligibleCount-finalCount;groupConflicts=conflicts
        overlapBefore=eligibleCount;overlapAfter=finalCount
    )
    fn evaluateGroups = (this.evaluateProcedural())
    fn groupPlacements group plants previewOnly = (
        local snapshot=if groupDisplayOnly and groupSnapshotKey!="" then groupSnapshotRows else this.procReadSnapshot()
        local index=findItem procPublishedOwners group
        if index==0 do return #()
        local rows=snapshot[index]
        if not previewOnly do (
            local published=procPublishedSources[index],same=plants.count==published.count
            if same do for i=1 to plants.count where plants[i]!=published[i] do same=false
            if not same do throw "Pending sources differ from the published result. Use outputSources() or Update."
            if plants.count==0 and rows.count>0 do throw "Assign plant assets before exact output."
            rows=group.filterSourceRowsByPolicy rows procPublishedFinalKeep[index]
        )
        rows
    )

    fn setGroupCoverage group painted reset:false = (
        if group==undefined do return false
        if group.isPaintArea do (
            local parent=this.logicalParent group,target=group.areaTarget
            if not isValidNode target or findItem (parent.validSurfaces()) target==0 do throw "This Paint Area is inactive. Add its target surface back to the layer, or create a new area."
            CyrusStopBrush()
            undo "Cyrus painted area" on (
                if group.paintDocument==undefined or reset do group.paintDocument=cyrusBrushCreate target
                parent.paintEnabled=painted;group.paintEnabled=true
            )
            group.setOverlapOwner this;parent.markInputDirty();this.bindNativeUI();return true
        )
        CyrusStopBrush()
        if painted then (
            local targets=group.validSurfaces()
            if targets.count!=1 or not isValidNode targets[1] do throw "Choose one shared receiving surface before painting. Curved meshes are supported."
            if group.paintDocument!=undefined and cyrusBrushTarget group.paintDocument!=targets[1] and not reset do throw "This group has strokes on another surface. Restore that surface or use Reset coverage to explicitly create an empty mask."
            undo "Cyrus painted coverage" on (
                if group.paintDocument==undefined or reset do group.paintDocument=cyrusBrushCreate targets[1]
                group.paintEnabled=true
            )
        ) else undo "Cyrus whole surface coverage" on group.paintEnabled=false
        this.invalidateGroups();this.bindNativeUI();true
    )

    local paintBaseFaceCounts=#()
    local blockerCacheKey="",blockerCacheRows=#(),blockerCacheBuilds=0,blockerCacheHits=0

    fn blockerCacheStats = (#(blockerCacheBuilds,blockerCacheHits))
    fn filterSourceRowsByPolicy rows keep = (
        if cyrusFilterSourceRows!=undefined then cyrusFilterSourceRows rows keep
        else (for row in rows where keep[row[2]] collect row)
    )
    -- One generation path. Eligibility follows candidate movement; author edits
    -- and the three collision scopes run later in the ordered publication pass.
    fn cspImpl_placements plants previewOnly:false rawOnly:false finalPass:undefined = (
        this.procAssertSchema()
        if not rawOnly and finalPass==undefined and overlapOwner!=undefined do return overlapOwner.groupPlacements this plants previewOnly
        if not cyrusEnabled or disabledAnalyzerInput() do return #()
        if this.brushMaskActive() and not projectMove and (movXMin!=0 or movXMax!=0 or movYMin!=0 or movYMax!=0 or movZMin!=0 or movZMax!=0 or movementRange!=0) do throw "Brush requires projected movement."
        local targets=this.validSurfaces(),seed=this.effectiveSeed(),sourceCount=amax 1 plants.count
        if targets.count==0 do return #()
        if plants.count==0 and not previewOnly do throw "Add a plant model."
        requestedCount=if procCandidateCount==undefined then (this.effectivePopulation())[1] else procCandidateCount
        if requestedCount<=0 do return #()
        local baseKey=(this.paintBaseInputKey plants previewOnly)+"|StablePool:"+(requestedCount as string)
        local result
        if finalPass==undefined and baseKey==paintBaseKey and paintBaseRows!=undefined then (result=paintBaseRows;paintBaseHits+=1)
        else (
            local weights=#(),image=undefined
            if distributionMode==3 do (
                if densityMap==undefined do throw "Choose a density texture map."
                try (
                    image=renderMap densityMap size:[128,128]
                    for y=0 to 127 do for c in (getPixels image [0,y] 128) do (
                        local w=amin 1.0 (amax 0.0 ((c.r*0.2126+c.g*0.7152+c.b*0.0722)/255.0))
                        append weights (if invertDensity then 1-w else w)
                    )
                    close image;image=undefined
                )catch(if image!=undefined do try(close image)catch();throw())
            )
            local areas=this.areaInputs(),line=this.lineInputs plants previewOnly:previewOnly
            local groups=if plants.count==0 then #(0) else for n in plants collect colorKey (sourceColor (sourceRow n))
            local shares=if sourceWeights.count==0 or plants.count==0 then #() else for n in plants collect sourceWeight (sourceRow n)
            if finalPass!=undefined do throw "Use the receiver-local candidate path before final acceptance."
            local shapeNodes=for node in areaNodes where isValidNode node collect node
            if diversityMode==3 do join shapeNodes (patternLines as array)
            local commonKey=(this.paintBaseInputKey plants previewOnly receiverLocal:true)+"|Shapes:"+(cyrusReceiverShapeKey shapeNodes)
            local nextCache=#(),faceOffset=0
            result=#();paintBaseFaceCounts=cyrusReceiverFaceCounts targets
            for receiverIndex=1 to targets.count do (
                local receiver=targets[receiverIndex],slot=findItem procReceiverNodes receiver,request=undefined,geometryKey=""
                for entry in procReceiverPlanData[1] where entry[1]==slot do request=entry
                for entry in procReceiverGeometry where entry[1]==slot do geometryKey=entry[2]
                if request==undefined do throw "Receiver allocation is missing."
                local receiverCount=request[4],receiverRows=#()
                local receiverKey=commonKey+"|"+procReceiverIDs[slot]+"|"+geometryKey+"|"+(receiverCount as string)
                local cached=undefined
                for entry in procReceiverCache where entry[1]==slot and entry[2]==receiverKey do cached=entry[3]
                if cached!=undefined then (receiverRows=cached;procReceiverHits+=1)
                else if receiverCount>0 do (
                    local options=#(true,not advancedAxes,scaleMinimum,scaleMaximum,tiltDegrees,yawMinimum,yawMaximum,movementRange,1,0,procReceiverIDs[slot],slot)
                    receiverRows=cyrusScatterAdvanced #(receiver) receiverCount seed sourceCount [sclXMin,sclYMin,sclZMin] [sclXMax,sclYMax,sclZMax] [rotXMin,rotYMin,rotZMin] [rotXMax,rotYMax,rotZMax] [movXMin,movYMin,movZMin] [movXMax,movYMax,movZMax] alignNormal projectMove (distributionMode-1) clusterCount clusterRadius weights 128 groups (diversityMode==2) diversitySize diversitySeed (roughness/100.0) (blurryEdge/100.0) (diversityNoise/100.0) areas[1] areas[2] (populationMode==2) line #(false,0.0,relaxEnabled,relaxSpacing,relaxIterations,relaxStrength) shares undefined options
                    if finalRelax and receiverRows.count>0 do (
                        local relaxPass=#(receiverRows,#(),(for row in receiverRows collect 0.0),#(),false,relaxSpacing,0,1,true,finalStrength,finalIterations,finalMaxMove,0.0,cleanupPlanar)
                        receiverRows=cyrusScatterAdvanced #(receiver) receiverCount seed sourceCount [sclXMin,sclYMin,sclZMin] [sclXMax,sclYMax,sclZMax] [rotXMin,rotYMin,rotZMin] [rotXMax,rotYMax,rotZMax] [movXMin,movYMin,movZMin] [movXMax,movYMax,movZMax] alignNormal projectMove (distributionMode-1) clusterCount clusterRadius weights 128 groups (diversityMode==2) diversitySize diversitySeed (roughness/100.0) (blurryEdge/100.0) (diversityNoise/100.0) areas[1] areas[2] (populationMode==2) line #(false,0.0,relaxEnabled,relaxSpacing,relaxIterations,relaxStrength) shares relaxPass options
                    )
                    if wholeScaleMin!=1.0 or wholeScaleMax!=1.0 do receiverRows=cyrusWholeScale receiverRows wholeScaleMin wholeScaleMax seed true
                    receiverRows=this.applyAnalyzerArea receiverRows
                    receiverRows=this.applyFalloff receiverRows
                    procReceiverBuilds+=1
                )
                append nextCache #(slot,receiverKey,receiverRows)
                join result (cyrusReceiverOffsetRows receiverRows faceOffset)
                faceOffset+=paintBaseFaceCounts[receiverIndex]
            )
            -- Replace one bounded cache generation after all receiver preparation succeeds.
            procReceiverCache=nextCache
            paintBaseRows=result;paintBaseKey=baseKey;paintBaseBuilds+=1
        )
        result=this.procApplyPaint result
        if plants.count>0 and sourceEmpty.count>0 do result=this.filterSourceRowsByPolicy result (for n in plants collect not (isEmptySource (sourceRow n)) or isPointSource (sourceRow n))
        if plants.count>0 and (sourceZOffsets.count>0 or sourceScales.count>0) do result=cyrusApplySourceTransforms result (for n in plants collect sourceZOffset (sourceRow n)) (for n in plants collect sourceScale (sourceRow n))
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
        CyrusLayerStatusData hasResult:(cachedPoints!=undefined) placements:generatedCount previewCount:cachedPointCount mode:uiPreviewMode buildMs:previewBuildMs needsUpdate:dirty errorText:previewError densityCapped:densityCapped inputOff:(disabledAnalyzerInput())
    )
    fn uiVersion = "0.77"
    fn calculationModel = (this.procAssertSchema();"CyrusUnified1")
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
    fn cspImpl_refreshPreview = (this.procRefreshPreview())
    fn refreshPreview = (
        local token=undefined
        if CyrusPerfTraceBegin!=undefined do try(token=CyrusPerfTraceBegin this "preview_rebuild")catch()
        try (
            this.inputTimeKey()
            local answer=cspImpl_refreshPreview()
            inputTimeObserved=inputTimeStamp
            if token!=undefined and CyrusPerfTraceEnd!=undefined do try(CyrusPerfTraceEnd token #(previewError,generatedCount,cachedPointCount,previewBuildCount))catch()
            answer
        )catch(
            if token!=undefined and CyrusPerfTraceEnd!=undefined do try(CyrusPerfTraceEnd token ("EXCEPTION: "+getCurrentException()))catch()
            throw()
        )
    )
    fn checkAnalyzerRevision = (
        if updateMode==2 and isValidNode areaAnalyzer and (areaUseLine or areaUsePoints) do if cachedAreaAnalyzerRun!=areaAnalyzer.getAnalysisRuns() do markInputDirty()
        if updateMode==2 and isValidNode fallAnalyzer and (fallDelete or fallScale or fallDensity) do if cachedFallRun!=fallAnalyzer.getAnalysisRuns() do markInputDirty()
        if updateMode==2 and diversityMode==4 do (
            local revision=if isValidNode analyzerNode then analyzerNode.getAnalysisRuns() else -1
            if revision!=cachedAnalyzerRun do markInputDirty()
        )
    )
    local cachedDisabledInput=false,cachedDisabledPreview=undefined
    fn previewCache interactionHeld:undefined = (
        local held=if interactionHeld==undefined then CyrusInteractionHeld() else interactionHeld
        if held do ((CyrusWasDragging=true;CyrusScheduleRelease());return cachedPoints)
        local inputOff=disabledAnalyzerInput()
        if inputOff!=cachedDisabledInput do (markInputDirty();cachedDisabledInput=inputOff)
        if inputOff do (
            if cachedDisabledPreview==undefined do cachedDisabledPreview=aminScatterBuildPreview #() #() #() 1
            return cachedDisabledPreview
        )
        checkAnalyzerRevision()
        if updateMode==2 do this.invalidateInputTime()
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
        on layerVisible set value index do (global CyrusPointPending;(CyrusPointPending=true;CyrusScheduleRelease()))
        layerObjects type:#maxObjectTab tabSize:0 tabSizeVariable:true
        layerNames type:#stringTab tabSize:0 tabSizeVariable:true
        layerEnabled type:#boolTab tabSize:0 tabSizeVariable:true
        on layerEnabled set v i do (for layer in layerObjects do layer.markInputDirty())
        activeLayer type:#integer default:1
    )
    -- Saved identification metadata never enters placement keys.
    parameters identificationSettings (
        visualSourceNodes type:#nodeTab tabSize:0 tabSizeVariable:true
        visualSourceLabels type:#stringTab tabSize:0 tabSizeVariable:true
        visualSourceColors type:#colorTab tabSize:0 tabSizeVariable:true
        visualSourceColorSet type:#boolTab tabSize:0 tabSizeVariable:true
        layerIDColor type:#color default:(color 100 220 120)
        identificationMode type:#integer default:1
    )
    -- Appended storage keeps earlier 0.74 parameter blocks readable.
    parameters regionSettings (
        ownsReceivers type:#boolean default:false
        areaMode type:#boolean default:false
        paintAreas type:#maxObjectTab tabSize:0 tabSizeVariable:true
        areaTarget type:#node
        uiAreaID type:#string default:""
        isPaintArea type:#boolean default:false
    )
    fn selectedPaintArea parent = (
        if parent==undefined do return undefined
        for area in parent.paintAreas where area.layerID==parent.uiAreaID do return area
        if parent.paintAreas.count>0 then parent.paintAreas[1] else undefined
    )
    fn adoptPaintArea parent = (
        -- Preserve the old document exactly, including soft paint and erase.
        if parent.paintDocument==undefined or parent.paintAreas.count>0 do return false
        local area=createInstance AminScatterObject
        area.isPaintArea=true;area.layerID=CyrusNewLayerID();area.logicalParentID=parent.layerID
        area.paintDocument=parent.paintDocument;area.areaTarget=cyrusBrushTarget parent.paintDocument
        area.paintSetName="Existing paint";area.paintDensity=parent.paintDensity
        area.paintView=parent.paintView;area.paintColor=parent.paintColor;area.paintEnabled=true
        area.setOverlapOwner this;parent.areaMode=true;append parent.paintAreas area;parent.uiAreaID=area.layerID
        true
    )
    fn addPaintArea parent target:undefined = (
        if parent==undefined or findItem layerObjects parent==0 or parent.logicalParentID!="" do throw "Select an owning layer first."
        if (this.layerSets parent).count>1 do throw "This older layer has model-owning sets. Its original settings are retained; convert those populations before adding Paint Areas."
        if parent.paintAreas.count>=128 do throw "A layer supports up to 128 Paint Areas."
        local targets=parent.validSurfaces(),area
        if target==undefined and targets.count==1 do target=targets[1]
        if target!=undefined and findItem targets target==0 do throw "Choose a surface assigned to this layer."
        CyrusStopBrush()
        undo "Cyrus add Paint Area" on (
            this.adoptPaintArea parent
            area=createInstance AminScatterObject
            area.isPaintArea=true;area.layerID=CyrusNewLayerID();area.logicalParentID=parent.layerID
            area.paintSetName="Area "+((parent.paintAreas.count+1) as string)
            area.areaTarget=target;area.paintEnabled=true;area.setOverlapOwner this
            if isValidNode target do area.paintDocument=cyrusBrushCreate target
            append parent.paintAreas area;parent.areaMode=true;parent.uiAreaID=area.layerID;parent.paintEnabled=true
        )
        parent.markInputDirty();this.bindNativeUI();CyrusViewportRedraw();area
    )
    fn removePaintArea parent area = (
        local index=findItem parent.paintAreas area
        if index==0 do return false
        CyrusStopBrush()
        undo "Cyrus remove Paint Area" on (deleteItem parent.paintAreas index;parent.uiAreaID="";parent.paintDocument=undefined)
        parent.markInputDirty();this.bindNativeUI();CyrusViewportRedraw();true
    )
    fn setPaintAreaTarget parent area target = (
        if findItem parent.paintAreas area==0 or findItem (parent.validSurfaces()) target==0 do throw "Choose a surface in this layer."
        if area.areaTarget==target do return false
        if area.paintDocument!=undefined and ((cyrusBrushStats area.paintDocument)[2]>0 or (cyrusBrushStats area.paintDocument)[17]!=0) do throw "This area already has paint. Add another area for a different surface; existing paint is preserved."
        CyrusStopBrush()
        undo "Cyrus Paint Area surface" on (area.areaTarget=target;area.paintDocument=cyrusBrushCreate target)
        parent.markInputDirty();this.bindNativeUI();CyrusViewportRedraw();true
    )
    fn setLayerSurfaces parent nodes = (
        if parent==undefined or findItem layerObjects parent==0 or parent.logicalParentID!="" do throw "Select an owning layer first."
        local targets=#()
        for node in nodes do (
            if not isValidNode node or classof node.baseObject==AminScatterObject do throw "Invalid receiving surface."
            if findItem targets node==0 do append targets node
        )
        if targets.count>128 do throw "A layer supports up to 128 receiving surfaces."
        CyrusStopBrush()
        undo "Cyrus layer surfaces" on (
            this.adoptPaintArea parent
            parent.ownsReceivers=true;parent.surfaceNodes=targets;parent.surface=undefined
            for member in this.layerSets parent where member!=parent do (member.ownsReceivers=true;member.surfaceNodes=targets;member.surface=undefined)
        )
        parent.markInputDirty();this.bindNativeUI();CyrusViewportRedraw();true
    )
    fn sourceVisualIndex row create:false = (
        if row<1 or row>this.sources.count or not isValidNode this.sources[row] do return 0
        local index=findItem visualSourceNodes this.sources[row]
        if index==0 and create do (
            append visualSourceNodes this.sources[row];append visualSourceLabels ""
            append visualSourceColors (this.sourceColor row);append visualSourceColorSet false
            index=visualSourceNodes.count
        )
        index
    )
    fn sourceLabel row = (
        local index=this.sourceVisualIndex row
        if index>0 and visualSourceLabels[index]!="" then visualSourceLabels[index]
        else if this.isPointSource row then "[Point]" else if this.isEmptySource row then "[Empty]"
        else if row>0 and row<=this.sources.count and isValidNode this.sources[row] then this.sources[row].name else "<deleted>"
    )
    fn sourceIDColor row = (
        local index=this.sourceVisualIndex row
        if index>0 and visualSourceColorSet[index] then visualSourceColors[index] else this.sourceColor row
    )
    fn setSourceLabel row value = (
        undo "Cyrus source label" on (local index=this.sourceVisualIndex row create:true;if index>0 do visualSourceLabels[index]=value)
        true
    )
    fn setSourceIDColor rows value = (
        undo "Cyrus source identification color" on for row in rows do (
            local index=this.sourceVisualIndex row create:true
            if index>0 do (visualSourceColors[index]=value;visualSourceColorSet[index]=true)
        )
        this.refreshIdentification()
    )
    fn refreshIdentification = (
        local controller=if this.overlapOwner==undefined then this else this.overlapOwner
        if controller.groupSnapshotKey!="" do controller.procEnsureDisplay pending:(controller.groupSnapshotKey!=controller.procInputKey())
        CyrusViewportRedraw();true
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
    fn forcePreviewUpdate = (markInputDirty();if updateMode==2 or cachedPoints==undefined do previewBuildCount=0)
    fn ensureLayers = layerObjects.count
    fn syncLayerSurface obj targets:undefined layerBudget:undefined = (
        obj.setOverlapOwner this
        if obj.showCenters!=this.groupCenters do undo off obj.showCenters=this.groupCenters
        if obj.ownsReceivers then targets=obj.validSurfaces() else (
            targets=#();for node in ((this.surfaceNodes as array)+#(this.surface)) where isValidNode node and findItem targets node==0 do append targets node
        )
        local equal=obj.surfaceNodes.count==targets.count
        if equal do for i=1 to targets.count where obj.surfaceNodes[i]!=targets[i] do equal=false
        if not equal do undo off (obj.surfaceNodes=targets;obj.surface=undefined)
        if layerBudget==undefined do (
            local enabledCount=(for i=1 to layerObjects.count where this.enabledLayer i collect i).count
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
        this.ensureTimeOwner()
        if cyrusEnabled and updateMode==2 do (
            this.liveTimeChanged()
            this.inputTimeKey();inputTimeObserved=inputTimeStamp
        )
        this.syncLogicalSettings()
        local key=CyrusEditStackKey this
        if key!=editCacheKey do (
            editCacheKey=key
            for layer in layerObjects do layer.markInputDirty()
        )
        local entries=#(),targets=validSurfaces()
        local enabledCount=(for i=1 to layerObjects.count where this.enabledLayer i collect i).count
        local layerBudget=amax 1 (floor(previewBudget/(amax 1 enabledCount)))
        for i=1 to layerObjects.count where includeDisabled or (cyrusEnabled and this.enabledLayer i) do (
            local obj=layerObjects[i]
            syncLayerSurface obj targets:targets layerBudget:layerBudget
            obj.checkAnalyzerRevision();obj.checkPaintRevision()
            append entries #(i,obj)
        )
        if (for e in entries where this.enabledLayer e[1] and e[2].dirty collect e).count>0 do
            for e in entries where this.enabledLayer e[1] and not e[2].dirty and (true ) do e[2].markInputDirty()
        entries
    )
    fn viewportLayerEntries held = (
        if not held do return (for entry in layerEntries() where this.visibleLayer entry[1] collect entry)
        for i=1 to layerObjects.count where cyrusEnabled and this.enabledLayer i and this.visibleLayer i collect #(i,layerObjects[i])
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
            obj.ownsReceivers=true;obj.surfaceNodes=this.surfaceNodes as array;obj.surface=this.surface
            obj.editLayerKey=nextEditLayerKey;nextEditLayerKey+=1
            
            obj.randomSeed=42+layerObjects.count*101
            (obj.procOrder=nextEditLayerKey;obj.procSetOrder=nextEditLayerKey)
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
    fn removePopulation = (
        if CyrusBrushSessionLayer!=undefined do CyrusStopBrush()
        if layerObjects.count>0 and activeLayer>0 do (
            if (for n in layerObjects[activeLayer].bakedNodes where isValidNode n collect n).count>0 do throw "Remove this layer's baked output first."
            undo "Cyrus Scatter remove layer" on (
                local i=activeLayer
                this.removeGroupRules layerObjects[i]
                -- Remap surviving indices on deletion.
                for layer in layerObjects do (

                    layer.markInputDirty()
                )
                deleteItem layerObjects i;deleteItem layerNames i;deleteItem layerEnabled i
                if i<=layerVisible.count do deleteItem layerVisible i
                activeLayer=amin i layerObjects.count
            )
        )
        activeLayer
    )
    fn refreshDisplay = (
        local entries=layerEntries(),pending=true and groupSnapshotKey!="" and groupSnapshotKey!=this.groupInputKey()
        groupDisplayOnly=true and updateMode==1
        try (for entry in entries do (entry[2].refreshPreview();if pending and updateMode==1 do entry[2].markInputDirty())) catch(groupDisplayOnly=false;throw())
        groupDisplayOnly=false;CyrusViewportRedraw()
    )
    fn refreshAll = (
        procManualRevision+=1
        local previousExplicit=procExplicitUpdate
        procExplicitUpdate=true
        -- One leaf refresh evaluates and atomically installs the entire root.
        -- Repeating it per leaf only repeats root validation and key building.
        try (
            local entries=layerEntries()
            if entries.count>0 do entries[1][2].refreshPreview()
        ) catch(procExplicitUpdate=previousExplicit;throw())
        procExplicitUpdate=previousExplicit
        if (CyrusContainerPanel this).controlsReady do (CyrusContainerPanel this).refreshStats()
        this.refreshBrushEditors()
        CyrusViewportRedraw()
    )
    fn allStatus = (
        local plants=0;local points=0;local errors=0
        for entry in (layerEntries()) do (
            local state=entry[2].cacheSnapshot()
            plants+=state[5];points+=state[2];if state[4]!="" do errors+=1
        )
        (layerObjects.count as string)+" groups; "+(plants as string)+" plants; "+(points as string)+(if viewportMode==1 then " points" else " shown instances (display limits apply)")+(if errors>0 then "; "+(errors as string)+" group(s) have a preview error" else "")+(if CyrusPointLastError!="" then "; native preview fallback" else "")
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
        local plants=this.outputSources()
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
    fn brushMaskActive = (paintEnabled and (areaMode or paintDocument!=undefined))
    fn brushRelaxPaused = (false)
    fn checkPaintRevision = (
        for area in paintAreas do (area.setOverlapOwner overlapOwner;area.checkPaintRevision())
        if paintDocument!=undefined do (
            local state=cyrusBrushStats paintDocument
            if state[6]==0 and state[1]!=cachedPaintRevision do (cachedPaintRevision=state[1];markInputDirty();if isPaintArea and overlapOwner!=undefined do (overlapOwner.logicalParent this).markInputDirty())
        )
    )
    fn paintKey = (
        if paintDocument==undefined then "none" else ((getHandleByAnim paintDocument as string)+":"+((cyrusBrushStats paintDocument)[1] as string)+":"+((cyrusBrushStats paintDocument)[4] as string))
    )
    fn applyPaint rows = (this.procApplyPaint rows)
    fn paintBaseInputKey plants previewOnly receiverLocal:false = (
        local post=if this.sharedSpacing() then #(#cleanupPlanar,#sourceRadii,#sourceFollowScale,#sourceShowRadius,#finalCleanup,#finalNeighborRadius,#finalMinNeighbors,#finalMinIsland,#finalRelax,#finalStrength,#finalIterations,#finalMaxMove) else #()
        join post #(#procOrder,#procSetOrder,#procPopulation,#procAttemptFactor,#procRounds,#procRepair,#procSelfOverride,#procSelfEnabled,#procSelfMultiplier,#procSelfGap,#procSelfPlanar,#procLayerSelfEnabled,#procLayerSelfMultiplier,#procLayerSelfGap,#procLayerSelfPlanar,#procSiblingEnabled,#procSiblingMultiplier,#procSiblingGap,#procSiblingPlanar,#procBackground,#procBackgroundIDs,#procRadiusIDs,#procRadiusModes,#procRadiusValues,#procRadiusBinding,#procSourceNodes,#procSourceIDs,#procSourceSlots,#procReceiverNodes,#procReceiverIDs,#procReceiverID,#containerMode,#containerNodes)
        local stream=stringStream ""
        with printAllElements on (
            format "%|%|%|%|%|" (this.inputTimeKey()) (if receiverLocal then 0 else procGeometryRevision) (if receiverLocal then 0 else if overlapOwner!=undefined then overlapOwner.procManualRevision else procManualRevision) (this.containerSourceKey plants) previewOnly to:stream
            format "DensityMap:%|" (if densityMap==undefined then 0 else getHandleByAnim densityMap) to:stream
            format "Ownership:%:%:%:%:%|" logicalParentID paintSetEnabled paintSetWeight (if receiverLocal then 0 else this.effectivePopulation()) (this.effectiveSeed()) to:stream
            format "EffectiveRelax:%|" (relaxEnabled and not this.layerPaintActive()) to:stream
            format "FinalRelax:%:%:%:%|" finalRelax finalStrength finalIterations finalMaxMove to:stream
            format "Texture:%|" (this.procWatchDensity()) to:stream
            for key in AminScatterLayerFields where findItem #(#paintDocument,#paintEnabled,#paintDensity,#bakedNodes,#showPoints,#pointsPerPlant,#updateMode,#autoRender,#previewBudget,#pointColorMode,#solidPointColor) key==0 and findItem post key==0 and findItem #(#paintView,#paintColor,#showCenters,#paintSetName,#paintSetVisible,#uiPaintSetID) key==0 and (not receiverLocal or findItem #(#amount,#plantsPerM2,#populationMode) key==0) do format "%:%|" key (if key==#sources then this.containerSourceKey (sources as array) else getProperty this key) to:stream
            for n in ((if receiverLocal then #() else this.validSurfaces())+(sources as array)+(areaNodes as array)+(patternLines as array)+#(analyzerNode,areaAnalyzer,fallAnalyzer)) where isValidNode n do (
                local tm=n.objectTransform
                if this.containerProvider()!=undefined and findItem sources n>0 do tm.row4=[0,0,0]
                format "%:%|" (getHandleByAnim n) tm to:stream
            )
            for n in #(analyzerNode,areaAnalyzer,fallAnalyzer) where isValidNode n do format "%|" (n.getAnalysisRuns()) to:stream
            format "%|%|%|%|%|%|%|%|" strokeSides strokeModes strokeColorRows strokeColorKeys strokeSourceRows strokeSourceNodes strokeMin strokeMax to:stream
        )
        stream as string
    )
    fn paintCacheStats = (#(paintBaseBuilds,paintBaseHits,if paintBaseRows==undefined then 0 else paintBaseRows.count))
    fn publishPaint = (
        checkPaintRevision()
        if (CyrusContainerPanel this).controlsReady do (CyrusContainerPanel this).refreshStats()
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
        layerTransfer=priorTransfer;markInputDirty();true
    )
    fn resetSelectedRandomization group = (
        local layer=this.selectedLayer()
        if layer==undefined do return false
        local caption=case group of (#rotation:"Cyrus reset rotation";#scale:"Cyrus reset XYZ scale";#wholeScale:"Cyrus reset whole scale";#movement:"Cyrus reset movement";default:undefined)
        if caption==undefined do return false
        undo caption on layer.resetRandomization group
        this.bindNativeUI()
        if (CyrusContainerPanel this).controlsReady do (CyrusContainerPanel this).refreshStats()
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
    fn copySelectedLayer = (
        local leaf=this.selectedLayer()
        if leaf==undefined do return false
        local parent=this.copyLogicalLayer (this.logicalParent leaf)
        activeLayer=findItem layerObjects parent;parent
    )
    fn removeLayer = (
        local leaf=this.selectedLayer()
        if leaf==undefined do return false
        if leaf.logicalParentID=="" then this.removeLogicalLayer leaf else this.removePaintSet leaf
    )
    local updateUI,surfaceUI,previewUI,layersUI,uiRootState=#(),uiPresentationState=#()

    fn procWatchDensity = (
        global CyrusDensityMapChanged
        local watched=if distributionMode==3 then densityMap else undefined
        if procDensityMap!=watched do (
            if procDensityWatch!=undefined do deleteChangeHandler procDensityWatch
            procDensityWatch=undefined;procDensityMap=watched;procDensityRevision+=1
            if watched!=undefined do procDensityWatch=when parameters watched changes id:#CyrusDensityMap affected do (CyrusDensityMapChanged affected)
        )
        procDensityRevision
    )
    fn procReadSnapshot = (
        -- A reopened scene has no transient publication and reconstructs once.
        -- After that, only Live or explicit Update may publish pending settings.
        if updateMode==2 or groupSnapshotKey=="" do this.evaluateProcedural()
        groupSnapshotRows
    )
    fn outputSources = (
        if overlapOwner==undefined do return this.validSources()
        local root=overlapOwner
        root.procReadSnapshot()
        local i=findItem root.procPublishedOwners this
        if i==0 do return #()
        local plants=root.procPublishedSources[i]
        for n in plants where classof n!=Integer do if not isValidNode n do throw "A published source was deleted. Restore it or Update before exact output."
        plants
    )
    fn procStatistics = (#(procLastStats as array,procLastRounds as array,procPreparedBuilds,procPreparedHits,procEpoch))
    fn procSort members sets:false = (
        local result=members as array
        for i=2 to result.count do (
            local chosen=result[i],j=i-1,key=if sets then chosen.procSetOrder else chosen.procOrder
            while j>0 and (if sets then result[j].procSetOrder else result[j].procOrder)>key do (result[j+1]=result[j];j-=1)
            result[j+1]=chosen
        )
        result
    )
    fn procMove item delta sets:false = (
        local members=if sets then this.layerSets (this.logicalParent item) else this.logicalLayers()
        local i=findItem members item,j=i+delta
        if i==0 or j<1 or j>members.count do return false
        -- Reject a reordering which would turn a background reference forward.
        members[i]=members[j];members[j]=item
        if sets do for k=1 to members.count do for id in members[k].procBackgroundIDs do (
            local found=0
            for p=1 to k-1 where members[p].layerID==id do found=p
            if found==0 do throw "Move would place a background reference after its consumer. Change the reference first."
        )
        undo "Cyrus evaluation order" on for k=1 to members.count do setProperty members[k] (if sets then #procSetOrder else #procOrder) k
        this.invalidateGroups();this.bindNativeUI();true
    )
    fn procModifiers = (
        local result=#()
        for node in refs.dependentNodes this where node.baseObject==this do for m in node.modifiers where classof m==CyrusScatterEdit do appendIfUnique result m
        result
    )
    fn procEditKey = (
        local text="ProceduralEdit1"
        for m in this.procModifiers() do text+="|"+(getHandleByAnim m as string)+":"+(m.enabled as string)+":"+(cyrusEditLocalRevision m as string)
        text
    )
    fn procSyncEditVisibility = (
        for m in this.procModifiers() do (
            cyrusEditActiveLayers m (for i=1 to layerObjects.count where cyrusEnabled and this.enabledLayer i collect layerObjects[i].editLayerKey)
            for i=1 to layerObjects.count do cyrusEditGroupVisibility m layerObjects[i].editLayerKey (cyrusEnabled and this.visibleLayer i)
        )
        true
    )
    fn procEnsureSources = (
        this.ensureFallCurves();this.ensureAreaFalloffs()
        -- Keep correspondence history so replacing a node and Undo can recover
        -- its original binding. This metadata never becomes an artist Undo step.
        undo off (
            local ids=#()
            for i=1 to sources.count do (
                local node=sources[i]
                if isValidNode node then (
                    local index=findItem procSourceNodes node
                    if index==0 do (
                        if procSourceNodes.count>=1024 do throw "Source identity history is full. Create a new setup before enrolling more assets."
                        append procSourceNodes node;append procSourceIDs (CyrusNewLayerID());index=procSourceNodes.count
                    )
                    append ids procSourceIDs[index]
                ) else append ids ("placeholder:"+(i as string))
            )
            local same=procSourceSlots.count==ids.count
            if same do for i=1 to ids.count where ids[i]!=procSourceSlots[i] do same=false
            if not same do procSourceSlots=ids
            local receiverKey=""
            for node in this.validSurfaces() do (
                local index=findItem procReceiverNodes node
                if index==0 do (
                    if procReceiverNodes.count>=128 do throw "Receiver identity history is full. Create a new setup before enrolling more surfaces."
                    append procReceiverNodes node;append procReceiverIDs (CyrusNewLayerID());index=procReceiverNodes.count
                )
                receiverKey+=procReceiverIDs[index]+"|"
            )
            if procReceiverID!=receiverKey do procReceiverID=receiverKey
        )
    )
    fn procPair scope a b = (
        for i=1 to procRuleA.count where procRuleScope[i]==scope and ((procRuleA[i]==a.layerID and procRuleB[i]==b.layerID) or (procRuleA[i]==b.layerID and procRuleB[i]==a.layerID)) do return i
        0
    )
    fn procSetPair scope a b enabled multiplier gap planar = (
        if scope!=1 and scope!=2 do throw "Unknown spacing scope."
        if a==b or findItem layerObjects a==0 or findItem layerObjects b==0 do throw "Choose two existing owners."
        if scope==1 and (this.logicalParent a)!=(this.logicalParent b) do throw "Paint-set rules require siblings."
        if scope==2 and (a.logicalParentID!="" or b.logicalParentID!="") do throw "Layer rules require logical layers."
        if multiplier<0 or gap<0 do throw "Spacing values must be nonnegative."
        undo "Cyrus scoped spacing" on (
            local i=this.procPair scope a b
            if i==0 do (
                append procRuleScope scope;append procRuleA a.layerID;append procRuleB b.layerID
                append procRuleEnabled false;append procRuleMultiplier 1.0;append procRuleGap 0.0;append procRulePlanar false;i=procRuleA.count
            )
            procRuleEnabled[i]=enabled;procRuleMultiplier[i]=multiplier;procRuleGap[i]=gap;procRulePlanar[i]=planar
        )
        this.invalidateGroups()
    )
    fn procRemoveRule i = (
        if i>0 do for key in #(#procRuleScope,#procRuleA,#procRuleB,#procRuleEnabled,#procRuleMultiplier,#procRuleGap,#procRulePlanar) do deleteItem (getProperty this key) i
    )
    fn procRemoveOwner leaf = (
        for i=procRuleA.count to 1 by -1 where procRuleA[i]==leaf.layerID or procRuleB[i]==leaf.layerID do this.procRemoveRule i
        for member in layerObjects do member.procBackgroundIDs=for id in member.procBackgroundIDs where id!=leaf.layerID collect id
    )
    fn procCopyRelations originals copies = (
        -- Remap references inside the copy; preserve external layer rules.
        (
            for s=1 to copies.count do (
                local leaf=copies[s]
                leaf.procRadiusIDs=#();leaf.procRadiusModes=#();leaf.procRadiusValues=#();leaf.procRadiusBinding=""
                leaf.procBackgroundIDs=for id in originals[s].procBackgroundIDs collect (
                    local replacement=id
                    for j=1 to originals.count where originals[j].layerID==id do replacement=copies[j].layerID
                    replacement
                )
            )
            local count=procRuleA.count
            for i=1 to count do (
                local a=undefined,b=undefined,changed=false
                for j=1 to originals.count do (
                    if procRuleA[i]==originals[j].layerID do (a=copies[j];changed=true)
                    if procRuleB[i]==originals[j].layerID do (b=copies[j];changed=true)
                )
                if changed do (
                    if a==undefined do for leaf in layerObjects where leaf.layerID==procRuleA[i] do a=leaf
                    if b==undefined do for leaf in layerObjects where leaf.layerID==procRuleB[i] do b=leaf
                    if a!=undefined and b!=undefined do this.procSetPair procRuleScope[i] a b procRuleEnabled[i] procRuleMultiplier[i] procRuleGap[i] procRulePlanar[i]
                )
            )
            if copies.count>0 do copies[1].procOrder=nextEditLayerKey
        )
    )
    fn procSelfRule = (
        if procSelfOverride then #(procSelfEnabled,procSelfMultiplier,procSelfGap,procSelfPlanar)
        else (
            local parent=if overlapOwner==undefined then this else overlapOwner.logicalParent this
            #(parent.procLayerSelfEnabled,parent.procLayerSelfMultiplier,parent.procLayerSelfGap,parent.procLayerSelfPlanar)
        )
    )
    fn procRadii rows plants = (
        if rows.count==0 do return #()
        if procRadiusIDs.count>0 do (
            if procRadiusBinding=="" do throw "Radius overrides have no generation binding. Explicitly clear them before updating."
            cyrusReceiverMergeBinding procRadiusBinding procBindingKey
        )
        local radii=if plants.count==0 then #(0.0) else for n in plants collect sourceRadius (sourceRow n)
        local follow=if plants.count==0 then #(false) else for n in plants collect sourceFollows (sourceRow n)
        cyrusProceduralRadii rows radii follow (procRadiusIDs as array) (procRadiusModes as array) (procRadiusValues as array)
    )
    fn procSelectedRadius mode value reset:false = (
        if overlapOwner==undefined do throw "Select a paint set using Procedural 0.7."
        if mode<1 or mode>2 or value<0 do throw "Invalid instance radius."
        if not reset do (
            if procBindingKey=="" do throw "Update a valid binding before assigning radii."
            if procRadiusIDs.count>0 do cyrusReceiverMergeBinding procRadiusBinding procBindingKey
        )
        local ids=cyrusEditSelectedIDs (overlapOwner.procModifiers()) editLayerKey
        if ids.count==0 do throw "Select plant instances in CS Edit first."
        undo "Cyrus selected instance radii" on (
        for id in ids do (
            local i=findItem procRadiusIDs id
            if reset then (if i>0 do (deleteItem procRadiusIDs i;deleteItem procRadiusModes i;deleteItem procRadiusValues i))
            else (
                if i==0 do (append procRadiusIDs id;append procRadiusModes mode;append procRadiusValues value;i=procRadiusIDs.count)
                procRadiusModes[i]=mode;procRadiusValues[i]=value
            )
        )
        procRadiusBinding=if procRadiusIDs.count>0 then cyrusReceiverMergeBinding procRadiusBinding procBindingKey else ""
        )
        overlapOwner.invalidateGroups()
    )
    fn procClearRadii = (
        undo "Cyrus clear set radius overrides" on (procRadiusIDs=#();procRadiusModes=#();procRadiusValues=#();procRadiusBinding="")
        if overlapOwner!=undefined do overlapOwner.invalidateGroups()
    )
    fn procBackgroundMembers = (
        if overlapOwner==undefined do return #()
        local members=overlapOwner.layerSets (overlapOwner.logicalParent this),before=#(),found=false
        for member in members while member!=this do append before member
        for id in procBackgroundIDs do if (for member in before where member.layerID==id collect member).count!=1 do throw "Background must reference earlier paint sets in the same layer."
        for member in before where findItem procBackgroundIDs member.layerID>0 and overlapOwner.enabledLayer (findItem overlapOwner.layerObjects member) collect member
    )
    fn procCoverageKey = (
        local stream=stringStream ""
        format "%:%:%:%:%:%|" (this.paintKey()) paintEnabled paintDensity procBackground procBackgroundIDs areaMode to:stream
        for area in paintAreas do format "Area:%:%:%:%:%|" area.layerID area.areaTarget area.paintSetEnabled area.paintDensity (area.paintKey()) to:stream
        if procBackground!=1 do for member in this.procBackgroundMembers() do format "%:%:%|" member.layerID member.paintEnabled (member.paintKey()) to:stream
        stream as string
    )
    fn procApplyPaint rows = (
        if areaMode do (
            if not paintEnabled or rows.count==0 do return cyrusClonePlacementRows rows
            local docs=#(),densities=#(),targets=this.validSurfaces()
            for area in paintAreas where area.paintSetEnabled and area.paintDocument!=undefined and findItem targets area.areaTarget>0 do (
                if cyrusBrushTarget area.paintDocument!=area.areaTarget do throw "Paint Area target mismatch; saved paint is preserved."
                append docs area.paintDocument;append densities area.paintDensity
            )
            return cyrusBrushRegionFilter rows docs densities targets paintBaseFaceCounts ("CyrusStableMask1:"+(this.effectiveSeed() as string))
        )
        local sampling="CyrusStableMask1:"+(this.effectiveSeed() as string)
        local outside=procBackground==2 or procBackground==4,refs=if outside then this.procBackgroundMembers() else #()
        if outside and refs.count>0 then (
            local targets=this.validSurfaces()
            if targets.count!=1 do throw "Outside coverage requires one shared receiver."
            local docs=#(if paintEnabled then paintDocument else undefined)
            for member in refs do append docs (if member.paintEnabled then member.paintDocument else undefined)
            cyrusBrushCompositeFilter rows docs (if paintEnabled then paintDensity else 1.0) sampling targets[1]
        ) else if this.brushMaskActive() then cyrusBrushFilter paintDocument rows sampling paintDensity else cyrusClonePlacementRows rows
    )
    fn procBinding plants rows = (
        local stream=stringStream ""
        with printAllElements on (
            format "CyrusBinding2:%|" (this.effectiveSeed()) to:stream
            for n in plants do (local i=sourceRow n;format "%|" (if i>0 and i<=procSourceSlots.count then procSourceSlots[i] else "preview") to:stream)
            for key in #(#distributionMode,#clusterCount,#clusterRadius,#diversityMode,#diversitySize,#diversitySeed,#roughness,#blurryEdge,#diversityNoise,#sourceWeights,#sourceColors,#sourceEmpty,#sourcePoint,#sourceScales,#sourceZOffsets,#advancedAxes,#scaleMinimum,#scaleMaximum,#tiltDegrees,#yawMinimum,#yawMaximum,#movementRange,#sclXMin,#sclXMax,#sclYMin,#sclYMax,#sclZMin,#sclZMax,#rotXMin,#rotXMax,#rotYMin,#rotYMax,#rotZMin,#rotZMax,#movXMin,#movXMax,#movYMin,#movYMax,#movZMin,#movZMax,#wholeScaleMin,#wholeScaleMax,#projectMove,#alignNormal) do format "%:%|" key (getProperty this key) to:stream
            if diversityMode>=3 do for key in #(#patternLines,#patternWidths,#strokeSides,#strokeModes,#strokeColorRows,#strokeColorKeys,#strokeSourceRows,#strokeSourceNodes,#strokeMin,#strokeMax,#analyzerNode,#edgeOffsets,#edgeAlong,#edgeAcross,#edgeKeepCorners,#edgeCornerAngle,#edgeCornerCount,#edgeFaceOut,#edgeCornerRadius,#edgeRotX,#edgeRotY,#edgeRotZ,#borderFaceOut,#streetFaceOut,#borderCornerRadius,#streetCornerRadius,#streetStraight,#streetTrimStart,#streetTrimEnd,#centerStreetOffset) do format "%:%|" key (getProperty this key) to:stream
            if relaxEnabled or finalRelax do for key in #(#relaxEnabled,#relaxSpacing,#relaxIterations,#relaxStrength,#finalRelax,#finalStrength,#finalIterations,#finalMaxMove) do format "%:%|" key (getProperty this key) to:stream
            format "\nCyrusReceivers2\n" to:stream
            for entry in procReceiverGeometry do format "%=%\n" procReceiverIDs[entry[1]] entry[2] to:stream
        )
        stream as string
    )

    fn receiverCacheStats = (#(procReceiverBuilds,procReceiverHits,procReceiverCache.count))
    fn procPlanReceivers active = (
        local parent=overlapOwner.logicalParent this,allocation=this.effectivePopulation(),meters=units.decodeValue "1m"
        local requirements=cyrusEditReceiverRequirements active editLayerKey,inputs=#()
        procReceiverGeometry=#()
        for node in this.validSurfaces() do (
            local slot=findItem procReceiverNodes node
            append inputs #(slot,procReceiverIDs[slot],(aminScatterSurfaceArea #(node)),requirements[slot])
            append procReceiverGeometry #(slot,(cyrusProceduralSurfaceKey #(node) (distributionMode==3)))
        )
        procReceiverPlanData=cyrusReceiverPlan inputs allocation[1] (if parent.populationMode==2 then allocation[2]/(meters*meters) else -1.0) (if parent.procPopulation==2 then parent.procAttemptFactor else 1) ((overlapOwner.populationAllocation this countOverride:100000)[1])
        densityCapped=procReceiverPlanData[5]
        procReceiverPlanData
    )


    -- Persistent source rows own artist settings. Containers only admit/park
    -- those rows; they never compact the registered list on boundary crossing.
    fn containerRoot = (if overlapOwner==undefined then this else overlapOwner)
    fn containerProvider = (
        if containerMode==1 do return undefined
        local root=this.containerRoot()
        case containerMode of (
            2:(if overlapOwner==undefined or logicalParentID=="" then root else (root.logicalParent this).containerProvider())
            3: root
            4: this
            default:(throw "Unknown source-container mode.")
        )
    )
    fn effectiveContainers = (
        local provider=this.containerProvider()
        if provider==undefined then #() else if provider==this.containerRoot() then provider.containerGlobalNodes as array else provider.containerNodes as array
    )
    fn containerSourceKey plants = (
        if this.containerProvider()==undefined then plants else (for n in plants collect (if classof n==Integer then n else if isValidNode n then getHandleByAnim n else 0))
    )
    fn containerFrames = (
        local result=#(),nodes=this.effectiveContainers()
        if nodes.count>32 do throw "A source pool supports at most 32 containers."
        for n in nodes where isValidNode n do (
            if classof n.baseObject!=CyrusSourceContainer or n.modifiers.count>0 do throw "Use a Cyrus Source Container without modifiers."
            local tm=n.objectTransform,volume=(length tm.row1)*(length tm.row2)*(length tm.row3)
            if volume<=0 or abs(dot tm.row1 (cross tm.row2 tm.row3))<=volume*1e-8 do throw "A source container has a singular transform. Restore its scale."
            if n.width<=0 or n.length<=0 do throw "Source container dimensions must be positive."
            if isProperty n #cornerRadius and n.cornerRadius!=0 do throw "Source containers require square rectangle corners."
            append result #((inverse tm),n.width/2,n.length/2)
        )
        result
    )
    fn containerContains node frames = (
        if not isValidNode node do return false
        local pivot=node.transform.row4
        for frame in frames do (
            local p=pivot*frame[1],epsilon=(amax 1e-4 ((amax frame[2] frame[3])*1e-6))
            if abs p.x<=frame[2]+epsilon and abs p.y<=frame[3]+epsilon do return true
        )
        false
    )
    fn containerEligible node excluded = (
        if not isValidNode node or superclassof node!=GeometryClass or isGroupHead node do return false
        if not this.usableSource node or classof node.baseObject==CyrusPointDisplay or classof node.baseObject==CyrusSourceContainer do return false
        if getUserProp node "CyrusPFTransient"==true do return false
        if findItem excluded node>0 do return false
        canConvertTo node Editable_Mesh
    )
    fn containerRegister node = (
        if findItem sources node>0 do return false
        if sources.count>=1024 do throw "Source registration is full (1,024 rows). Remove unused rows explicitly."
        -- Fill optional tabs before appending so a new source cannot inherit
        -- a prior row's sparse setting. Automatic registration survives parking.
        undo off (
            syncColors()
            for spec in #(#(#sourceWeights,1.0),#(#sourceZOffsets,0.0),#(#sourceScales,1.0),#(#sourceForwardAxes,1),#(#sourceRadii,0.0),#(#sourceFollowScale,false),#(#sourceShowRadius,false),#(#sourcePoint,false),#(#sourceEmpty,false)) do (
                local values=getProperty this spec[1]
                while values.count<sources.count do append values spec[2]
                append values spec[2]
            )
            append sources node;append sourceColors (this.sourceColor sources.count)
        )
        markInputDirty();true
    )
    fn containerRefresh = (
        if containerReconciling do return false
        if this.containerProvider()==undefined do (containerActive=#();containerMembershipKey="manual";return false)
        containerReconciling=true
        try (
            local nodes=this.effectiveContainers(),changed=false
            local state=for n in nodes collect (
                if isValidNode n then (
                    if classof n.baseObject!=CyrusSourceContainer do throw "Use a Cyrus Source Container."
                    #(n,n.objectTransform,n.width,n.length,n.modifiers.count,if isProperty n #cornerRadius then n.cornerRadius else 0)
                ) else #(undefined)
            )
            local configurationChanged=containerConfigKey=="" or state.count!=containerFrameState.count
            if not configurationChanged do for i=1 to state.count while not configurationChanged do (
                if state[i].count!=containerFrameState[i].count then configurationChanged=true
                else for j=1 to state[i].count where state[i][j]!=containerFrameState[i][j] do configurationChanged=true
            )
            if configurationChanged do (containerScan=true;containerCachedFrames=this.containerFrames())
            local frames=containerCachedFrames
            local candidates=if containerScan then (geometry as array) else containerPending as array
            if containerScan do containerScans+=1
            local excluded=#()
            if candidates.count>0 do for controller in objects where classof controller.baseObject==AminScatterObject do (
                join excluded (controller.baseObject.validSurfaces())
                for leaf in controller.baseObject.layerObjects do join excluded (leaf.bakedNodes as array)
            )
            for node in candidates where findItem sources node==0 do (
                containerTests+=1
                if this.containerContains node frames and this.containerEligible node excluded do changed=(this.containerRegister node) or changed
            )
            local membershipChanged=configurationChanged or sources.count!=containerTrackedSources.count or sources.count!=containerActive.count
            if not membershipChanged do for i=1 to sources.count while not membershipChanged do (
                local node=sources[i],pivot=if isValidNode node then node.transform.row4 else undefined
                if node!=containerTrackedSources[i] or pivot!=containerTrackedPivots[i] do membershipChanged=true
            )
            if membershipChanged do (
                containerActive=for node in sources collect (this.containerContains node frames)
                containerTrackedSources=sources as array
                containerTrackedPivots=for node in sources collect (if isValidNode node then node.transform.row4 else undefined)
                containerMembershipBuilds+=1
            )
            containerConfigKey="ready";containerFrameState=state;containerPending=#();containerScan=false
            local membership=stringStream ""
            with printAllElements on format "%" containerActive to:membership
            local nextMembership=membership as string
            if nextMembership!=containerMembershipKey or changed do containerUIChanged=true
            containerMembershipKey=nextMembership
            containerReconciling=false;if membershipChanged or changed do CyrusContainerRefreshAll();changed
        )catch(containerReconciling=false;throw())
    )
    fn containerFilter rows plants = (
        if this.containerProvider()==undefined do return rows
        if plants.count==0 do return #()
        local keep=for node in plants collect (
            local i=this.sourceRow node
            i>0 and i<=containerActive.count and containerActive[i]
        )
        this.filterSourceRowsByPolicy rows keep
    )
    fn containerNote event nodes = (
        local interested=false
        for leaf in layerObjects where leaf.containerProvider()!=undefined do (
            -- Deletion payloads may no longer resolve to nodes. Keep the
            -- existing conservative reconciliation for genuine deletions; the
            -- dispatcher already filters our known deleted helper handles.
            local relevant=event==#deleted,frames=undefined,rectangles=leaf.effectiveContainers()
            if relevant do leaf.containerScan=true
            for rectangle in rectangles where isValidNode rectangle do (
                local parent=rectangle
                while isValidNode parent and not relevant do (
                    if findItem nodes parent>0 do relevant=true
                    parent=parent.parent
                )
            )
            -- A moved parent may carry previously unregistered children into a
            -- rectangle. Traverse only this changed subtree, never every frame.
            -- Keep callback work bounded. A large changed subtree requests one
            -- conservative scan during normal reconciliation, not in this hook.
            -- A new array also avoids appending children to the caller's batch.
            local pending=(for i=1 to (amin nodes.count 512) collect nodes[i]),index=1
            if nodes.count>512 do (leaf.containerScan=true;relevant=true)
            while index<=pending.count do (
                local node=pending[index];index+=1
                if isValidNode node do (
                    local generated=classof node.baseObject==AminScatterObject or classof node.baseObject==CyrusPointDisplay or classof node.baseObject==CyrusSourceContainer or getUserProp node "CyrusPFTransient"==true
                    if not generated do (
                        if findItem leaf.sources node>0 then relevant=true
                        else if superclassof node==GeometryClass and not isGroupHead node do (
                            -- An unrelated helper or a model outside the pool
                            -- must not mark every container-backed layer dirty.
                            try (
                                if frames==undefined do frames=leaf.containerFrames()
                                if leaf.containerContains node frames do (appendIfUnique leaf.containerPending node;relevant=true)
                            )catch(relevant=true)
                        )
                    )
                    for child in node.children while pending.count<512 do appendIfUnique pending child
                    if pending.count>=512 do (leaf.containerScan=true;relevant=true)
                )
            )
            if relevant do (leaf.markInputDirty();interested=true)
            CyrusDiagnosticEmit "container.notification" "host_callback" leaf.layerID leaf.procEpoch (if relevant then "reconcile_needed" else "unrelated")
        )
        interested
    )
    fn procExternalChanged event nodes = (
        local inputs=this.validSurfaces(),affected=false
        local staging=this.containerProvider()!=undefined and findItem #(#controllerOtherEvent,#controllerStructured,#linkChanged) event>0
        if not staging then join inputs (sources as array)
        else for source in sources where isValidNode source and (source.modifiers.count>0 or cyrusSourceWorldDependent source) do appendIfUnique inputs source
        join inputs (areaNodes as array);join inputs (patternLines as array)
        join inputs #(analyzerNode,areaAnalyzer,fallAnalyzer)
        for input in inputs where isValidNode input do (
            local dep=input
            while isValidNode dep and not affected do (
                if findItem nodes dep>0 do affected=true
                dep=dep.parent
            )
        )
        if event==#deleted do affected=true
        if affected do (procGeometryRevision+=1;markInputDirty())
        CyrusDiagnosticEmit "input.classified" "host_callback" layerID procEpoch (if affected then "geometry_dependency" else "unrelated")
        affected
    )
    fn containerSetMode mode = (
        if mode<1 or mode>4 do throw "Unknown source-container mode."
        undo "Cyrus source pool" on containerMode=mode
        containerScan=true;containerConfigKey="";markInputDirty()
        local root=this.containerRoot();root.invalidateGroups();CyrusContainerRefreshAll();root.bindNativeUI()
    )
    fn containerAdd node globalPool:false = (
        if not CyrusSourceContainerFilter node do throw "Pick a Cyrus container or an unmodified square-corner Rectangle."
        local target=if globalPool then this.containerRoot() else this,key=if globalPool then #containerGlobalNodes else #containerNodes
        local nodes=(getProperty target key) as array
        if findItem nodes node==0 and nodes.count>=32 do throw "A source pool supports at most 32 containers."
        undo "Cyrus add source container" on (
            if classof node.baseObject==Rectangle do (
                local original=node
                node=CyrusSourceContainer name:(uniqueName (original.name+" Sources ")) width:original.width length:original.length
                node.transform=original.objectTransform
                local controller=this.containerRoot(),consumer=if globalPool then controller.selectedLayer() else this
                if controller.layerID=="" do controller.layerID=CyrusNewLayerID()
                node.contextRootID=controller.layerID;node.contextSetID=if consumer==undefined then "" else consumer.layerID
            )
            if not globalPool do this.containerMode=4
            if findItem nodes node==0 do (append nodes node;setProperty target key nodes)
        )
        local root=this.containerRoot();root.invalidateGroups();CyrusContainerRefreshAll();root.bindNativeUI();true
    )
    fn containerRemove index globalPool:false = (
        local target=if globalPool then this.containerRoot() else this,key=if globalPool then #containerGlobalNodes else #containerNodes
        local nodes=(getProperty target key) as array
        if index>0 and index<=nodes.count do undo "Cyrus remove source container" on (deleteItem nodes index;setProperty target key nodes)
        local root=this.containerRoot();root.invalidateGroups();CyrusContainerRefreshAll();root.bindNativeUI()
    )
    fn containerCreate globalPool:false = (
        local root=this.containerRoot(),label=if globalPool then "Global sources" else root.layerCaption (root.logicalParent this),node
        undo "Cyrus create source container" on (
            node=CyrusSourceContainer name:(uniqueName ("CS Sources - "+label+" ")) width:500 length:300
            local receivers=root.validSurfaces()
            if receivers.count>0 do (local bounds=nodeGetBoundingBox receivers[1] (matrix3 1);node.pos=[bounds[2].x+350,bounds[1].y,0])
            if root.layerID=="" do root.layerID=CyrusNewLayerID()
            local consumer=if globalPool then root.selectedLayer() else this
            node.contextRootID=root.layerID;node.contextSetID=if consumer==undefined then "" else consumer.layerID
            if not globalPool do this.containerMode=4
            this.containerAdd node globalPool:globalPool
        )
        CyrusContainerRefreshAll();node
    )

    fn procInputKey = (
        local stream=stringStream ""
        with printAllElements on (
            format "Proc1:%:%:%:%:%:%:%:%|" (this.inputTimeKey()) 0 procManualRevision cyrusEnabled layerEnabled (this.procEditKey()) procRuleScope procRuleA to:stream
            format "%:%:%:%:%|" procRuleB procRuleEnabled procRuleMultiplier procRuleGap procRulePlanar to:stream
            for parent in this.logicalLayers() do for leaf in this.layerSets parent do (
                leaf.containerRefresh()
                format "Membership:%|" leaf.containerMembershipKey to:stream
                format "Texture:%|" (leaf.procWatchDensity()) to:stream
                format "%:%:%:%:%:%|" leaf.layerID leaf.logicalParentID leaf.procReceiverID leaf.procRadiusBinding (leaf.paintBaseInputKey (leaf.validSources()) true) (leaf.procCoverageKey()) to:stream
                for key in #(#procOrder,#procSetOrder,#procSamplingSalt,#procPopulation,#procAttemptFactor,#procRounds,#procRepair,#procSelfOverride,#procSelfEnabled,#procSelfMultiplier,#procSelfGap,#procSelfPlanar,#procLayerSelfEnabled,#procLayerSelfMultiplier,#procLayerSelfGap,#procLayerSelfPlanar,#procSiblingEnabled,#procSiblingMultiplier,#procSiblingGap,#procSiblingPlanar,#procRadiusIDs,#procRadiusModes,#procRadiusValues,#procSourceIDs,#sourceRadii,#sourceFollowScale,#finalCleanup,#finalNeighborRadius,#finalMinNeighbors,#finalMinIsland,#cleanupPlanar) do format "%:%|" key (getProperty leaf key) to:stream
            )
        )
        stream as string
    )
    fn procQuota = (
        local parent=overlapOwner.logicalParent this,budget=parent.amount
        if parent.populationMode==2 do (
            local meters=units.decodeValue "1m",wanted=(aminScatterSurfaceArea (this.validSurfaces()))/(meters*meters)*parent.plantsPerM2
            densityCapped=wanted>100000;budget=(amin 100000 (floor(wanted+0.5))) as integer
        )
        (overlapOwner.populationAllocation this countOverride:budget)[1]
    )
    fn procPrepare pool plants = (
        if not areaMode and paintEnabled and paintDocument!=undefined do (
            local targets=this.validSurfaces()
            if targets.count!=1 or (cyrusBrushTarget paintDocument)!=targets[1] do throw "Paint target differs from the shared receiver. Saved strokes are preserved."
        )
        local key=(this.paintBaseInputKey plants true)+"|Texture:"+(this.procWatchDensity() as string)+"|Pool:"+(pool as string)+"|"+(this.procCoverageKey())+"|"+(overlapOwner.procEditKey())
        if key==procPreparedKey do (CyrusDiagnosticEmit "prepare.reused" "engine" layerID procEpoch "key_match";procPreparedHits+=1;return procPreparedRows)
        CyrusDiagnosticEmit "prepare.started" "engine" layerID procEpoch "key_changed"
        local rows
        procCandidateCount=pool
        try(rows=this.cspImpl_placements plants previewOnly:true rawOnly:true)catch(procCandidateCount=undefined;throw())
        procCandidateCount=undefined
        if diversityMode==4 and (borderFaceOut or streetFaceOut or (findItem strokeSides 7>0)) and rows.count>0 do (
            local forward=if plants.count==0 then #(1) else for n in plants collect sourceForward (sourceRow n)
            local offsets=if plants.count==0 then #(0.0) else for n in plants collect sourceZOffset (sourceRow n)
            rows=cyrusOrientRows rows (this.lineInputs plants previewOnly:true) forward offsets
        )
        procBindingKey=this.procBinding plants rows
        rows=CyrusEditApplyLayer overlapOwner this rows
        procPreparedRows=rows;procPreparedKey=key;procPreparedBuilds+=1
        rows
    )
    fn procAssertSchema = (
        local message="This unpublished development scene uses a retired Cyrus settings schema. Create a new 0.77 setup."
        if not procSchemaValid do throw message
        for leaf in layerObjects where not leaf.procSchemaValid do throw message
        true
    )
    fn procValidate = (
        this.procAssertSchema()
        if cyrusEvaluateProcedural==undefined or cyrusEditTransaction==undefined or cyrusProceduralPublicationVersion==undefined do throw "Cyrus 0.77 requires the matching native plugin binaries. Restart the private test host with the complete matching script/native pair."
        if layerObjects.count>10 do throw "A setup supports ten total populations."
        for parent in this.logicalLayers() do (
            if parent.procPopulation<1 or parent.procPopulation>2 or parent.procAttemptFactor<1 or parent.procAttemptFactor>32 or parent.procRounds<1 or parent.procRounds>16 do throw "Invalid procedural work limits."
            for leaf in this.layerSets parent where this.enabledLayer (findItem layerObjects leaf) do (
                if cyrusEnabled do leaf.requireCurrentAnalyzers()
                if leaf.procBackground<1 or leaf.procBackground>4 do throw "Unknown background mode."
                if leaf.procBackground!=1 do leaf.procBackgroundMembers()
                if leaf.procBackground==3 or leaf.procBackground==4 do for member in leaf.procBackgroundMembers() do (
                    local pair=this.procPair 1 leaf member
                    local enabled=if pair>0 then procRuleEnabled[pair] else parent.procSiblingEnabled
                    local multiplier=if pair>0 then procRuleMultiplier[pair] else parent.procSiblingMultiplier
                    local gap=if pair>0 then procRuleGap[pair] else parent.procSiblingGap
                    if not enabled or (multiplier<=0 and gap<=0) do throw "Between plants requires a nonzero applicable set-pair spacing rule. Configure the rule before updating."
                )
                if leaf.procBackground==2 or leaf.procBackground==4 do (
                    if not leaf.projectMove and (leaf.movementRange!=0 or leaf.movXMin!=0 or leaf.movXMax!=0 or leaf.movYMin!=0 or leaf.movYMax!=0 or leaf.movZMin!=0 or leaf.movZMax!=0) do throw "Outside coverage needs projected movement."
                    for member in leaf.procBackgroundMembers() where member.paintEnabled and member.paintDocument==undefined do throw "A referenced painted set has no coverage document."
                )
                if parent.procPopulation==2 do for source in leaf.validSources() do (
                    local index=leaf.sourceRow source
                    if leaf.isEmptySource index and not leaf.isPointSource index and leaf.sourceWeight index>0 do throw "Accepted target does not refill weighted Empty assets. Use candidate budget, Point placeholders, or remove the Empty weight."
                )
            )
        )
        true
    )
    fn procDisplayInputKey epoch:undefined = (
        local stream=stringStream ""
        with printAllElements on (
            format "Display:%:%|" (if epoch==undefined then procEpoch else epoch) identificationMode to:stream
            for leaf in layerObjects do format "%:%|" (for i=1 to leaf.sources.count collect leaf.sourceIDColor i) (this.logicalParent leaf).layerIDColor to:stream
            for leaf in layerObjects do for key in #(#viewportMode,#proxyShape,#viewportInstances,#viewportFaces,#previewBudget,#showCenters,#pointsPerPlant,#pointColorMode,#solidPointColor,#sourceShowRadius,#radiusDisplayLimit,#radiusDisplayAll) do format "%:%|" key (getProperty leaf key) to:stream
        )
        stream as string
    )
    fn procStagePreview data plants:undefined = (
        local start=timeStamp(),previousRadius=radiusPreview,radii
        if plants==undefined do plants=this.validSources()
        try(cacheRadii data plants;radii=radiusPreview;radiusPreview=previousRadius)catch(radiusPreview=previousRadius;throw())
        local samples=if viewportMode!=1 then #() else if showCenters then (for i=1 to (amax 1 plants.count) collect #([0,0,0])) else (for n in plants collect (if classof n==Integer then (for p=1 to pointsPerPlant collect [0,0,0]) else pointSourceSamples n))
        local controller=if overlapOwner==undefined then this else overlapOwner,parent=controller.logicalParent this
        local colors=if plants.count==0 then #(solidPointColor) else for n in plants collect (if controller.identificationMode==2 then parent.layerIDColor else this.sourceIDColor (sourceRow n))
        local cache=if data.count==0 then aminScatterBuildPreview #() #() #() 1 else if viewportMode==1 then aminScatterBuildPreview data samples colors (if showCenters then 500000 else previewBudget) else cyrusBuildGeometryPreview data (if plants.count==0 then #(-1) else plants) colors (if viewportMode==2 then proxyShape else 4) viewportInstances viewportFaces
        #(cache,(aminScatterPreviewCount cache),data.count,radii,(if viewportMode==1 and showCenters then 4 else viewportMode),timeStamp()-start,(if isValidNode areaAnalyzer then areaAnalyzer.getAnalysisRuns() else -1),(if isValidNode fallAnalyzer then fallAnalyzer.getAnalysisRuns() else -1))
    )
    fn procInstallPreview state pending = (
        inputTimeObserved=inputTimeStamp
        CyrusDiagnosticEmit "preview.installed" "engine" layerID procEpoch (if pending then "pending" else "current")
        cachedPoints=state[1];cachedPointCount=state[2];generatedCount=state[3];radiusPreview=state[4];uiPreviewMode=state[5]
        previewBuildMs=state[6];cachedAreaAnalyzerRun=state[7];cachedFallRun=state[8]
        cachedAnalyzerRun=if isValidNode analyzerNode then analyzerNode.getAnalysisRuns() else -1
        previewBuildCount+=1;previewError="";dirty=pending
    )
    fn procEnsureDisplay pending:false = (
        local key=this.procDisplayInputKey()
        if key!=procPublishedDisplayKey do (
            local stage=for i=1 to layerObjects.count collect layerObjects[i].procStagePreview groupSnapshotRows[i] plants:procPublishedSources[i]
            for i=1 to layerObjects.count do layerObjects[i].procInstallPreview stage[i] pending
            procPublishedDisplayKey=key
        )
    )
    fn procRefreshPreview = (
        local root=overlapOwner
        try (
            if root.groupSnapshotKey=="" or (not root.groupDisplayOnly and (root.updateMode==2 or root.procExplicitUpdate)) do root.evaluateProcedural()
            local pending=root.groupSnapshotKey!=root.procInputKey()
            root.procEnsureDisplay pending:pending
            dirty=pending;cachedPointCount
        ) catch (
            -- A failed successor cannot erase the preceding complete viewport.
            local failure=getCurrentException()
            for leaf in root.layerObjects do (leaf.previewError=failure;leaf.dirty=false)
            cachedPointCount
        )
    )
    fn evaluateProcedural = (
        this.procAssertSchema()
        if groupSolving do throw "Recursive procedural evaluation."
        this.syncLogicalSettings()
        for leaf in layerObjects do (this.syncLayerSurface leaf;leaf.containerRefresh();leaf.procEnsureSources())
        local key=this.procInputKey()
        if key==groupSnapshotKey do (
            CyrusDiagnosticEmit "publication.reused" "engine" layerID procEpoch "key_match"
            -- A correction may restore the exact last successful recipe.
            -- Reusing its publication is success; clear a prior failure status.
            for leaf in layerObjects do leaf.previewError=""
            groupHits+=1;return groupSnapshotRows
        )
        -- A cached read still consumes the last published Analyzer guides.
        -- Only a successor solve may reject its now-pending dependencies.
        this.procValidate()
        CyrusDiagnosticEmit "solve.started" "engine" layerID procEpoch "input_changed"
        local mods=this.procModifiers(),active=for m in mods where m.enabled collect m
        local parents=this.logicalLayers(),mapping=#(),layers=#(),admission=0
        local requests=for leaf in layerObjects collect #(0,0,0)
        -- Admit the full bounded candidate pool before any Edit/publication mutation.
        for i=1 to layerObjects.count where cyrusEnabled and this.enabledLayer i do (
            local leaf=layerObjects[i],parent=this.logicalParent leaf,receiverPlan=leaf.procPlanReceivers active
            local quota=receiverPlan[3],attempts=receiverPlan[4],pool=receiverPlan[2].count
            if pool>100000 do throw "The required candidate pool exceeds 100,000 for a paint set."
            requests[i]=#(quota,attempts,pool);admission+=pool
        )
        if admission>1000000 do throw "Procedural candidate admission exceeds 1,000,000. Reduce population or attempt limits."
        groupSolving=true
        local transaction=false,previousBindings=for leaf in layerObjects collect leaf.procBindingKey
        try (
            cyrusEditTransaction mods 0;transaction=true
            for parent in parents do (
                local members=this.layerSets parent,sets=#(),indices=#()
                for leaf in members do (
                    local i=findItem layerObjects leaf,request=requests[i],plants=leaf.validSources(),rows=#()
                    if cyrusEnabled and this.enabledLayer i do rows=leaf.containerFilter (leaf.procPrepare request[3] plants) plants
                    append sets #(leaf.layerID,rows,(leaf.procRadii rows plants),(leaf.procSelfRule()),request[1],request[2],(if cyrusEnabled and this.enabledLayer i then leaf.procReceiverPlanData[2] else #()))
                    append indices i
                )
                append layers #(parent.layerID,parent.procPopulation==2,parent.procRepair,parent.procRounds,#(parent.procSiblingEnabled,parent.procSiblingMultiplier,parent.procSiblingGap,parent.procSiblingPlanar),#(parent.finalCleanup,parent.finalNeighborRadius,parent.finalMinNeighbors,parent.finalMinIsland,parent.cleanupPlanar),sets)
                append mapping indices
            )
            local pairs=for i=1 to procRuleA.count collect #(procRuleScope[i],procRuleA[i],procRuleB[i],#(procRuleEnabled[i],procRuleMultiplier[i],procRuleGap[i],procRulePlanar[i]))
            local resolved=cyrusEvaluateProcedural layers pairs 1000000
            local accepted=for leaf in layerObjects collect #(),stats=for leaf in layerObjects collect #(),rounds=for leaf in layerObjects collect #(),radii=for leaf in layerObjects collect #()
            for l=1 to mapping.count do for s=1 to mapping[l].count do (
                local i=mapping[l][s]
                accepted[i]=resolved[1][l][s];stats[i]=resolved[2][l][s];rounds[i]=resolved[3][l]
                radii[i]=resolved[4][l][s]
            )
            local display=for i=1 to layerObjects.count collect layerObjects[i].procStagePreview accepted[i]
            local displayKey=this.procDisplayInputKey epoch:(procEpoch+1)
            local publishedOwners=layerObjects as array,publishedSources=for leaf in layerObjects collect leaf.validSources()
            local finalKeep=for i=1 to layerObjects.count collect (for n in publishedSources[i] collect not (layerObjects[i].isPointSource (layerObjects[i].sourceRow n)))
            local publicationInfo=this.procStagePublication accepted requests publishedSources finalKeep
            -- Allocation and computation have finished; publish one coherent epoch.
            this.publishGroupEdits accepted
            this.procSyncEditVisibility()
            local finishedKey=this.procInputKey()
            cyrusEditTransaction mods 1;transaction=false
            procEpoch+=1
            for i=1 to layerObjects.count do (
                local leaf=layerObjects[i]
                leaf.procLastStats=stats[i];leaf.procLastRounds=rounds[i];leaf.procEpoch=procEpoch
                leaf.requestedCount=requests[i][1]
                -- Unconsumed refill capacity is not a rejected plant.
                leaf.setGroupResult (stats[i][1]-stats[i][9]) stats[i][2] stats[i][4]
                leaf.procInstallPreview display[i] false
            )
            procPublishedOwners=publishedOwners;procPublishedSources=publishedSources;procPublishedFinalKeep=finalKeep
            procPublishedRadii=radii;procPublishedInfo=publicationInfo
            groupSnapshotRows=accepted;groupSnapshotKey=finishedKey;procPublishedDisplayKey=displayKey;groupBuilds+=1
            CyrusScheduleUI();CyrusPFRequestCheck()
            CyrusDiagnosticEmit "publication.committed" "engine" layerID procEpoch "complete"
            groupSolving=false;accepted
        ) catch (
            local failure=getCurrentException()
            if transaction do cyrusEditTransaction mods 2
            for i=1 to layerObjects.count do (layerObjects[i].procPreparedKey="";layerObjects[i].procCandidateCount=undefined;layerObjects[i].procBindingKey=previousBindings[i])
            CyrusDiagnosticEmit "publication.retained" "engine" layerID procEpoch "successor_failed"
            groupSolving=false;throw()
        )
    )

    -- Private transient publication metadata. All values are captured before
    -- commit. These read methods never call validSources/procInputKey/solve.
    fn procStagePublication accepted requests publishedSources finalKeep = (
        local sets=#(),count=0,parents=this.logicalLayers()
        for i=1 to layerObjects.count do (
            local leaf=layerObjects[i],parent=this.logicalParent leaf,assets=#()
            for s=1 to publishedSources[i].count do (
                local node=publishedSources[i][s],slot=leaf.sourceRow node
                local sourceID=if slot>0 and slot<=leaf.procSourceSlots.count then leaf.procSourceSlots[slot] else ("placeholder:"+(s as string))
                append assets #(sourceID,(if classof node==Integer then 0 else getHandleByAnim node),finalKeep[i][s],(leaf.isPointSource slot),(leaf.isEmptySource slot))
            )
            if assets.count==0 do append assets #("unassigned:1",0,false,true,false)
            count+=accepted[i].count
            append sets #(leaf.layerID,parent.layerID,(findItem parents parent),(findItem (this.layerSets parent) leaf),accepted[i].count,requests[i][1],requests[i][2],requests[i][3],leaf.procSamplingSalt,assets)
        )
        -- Rule values are retained in system units; the snapshot contains the
        -- unit conversion that was effective for this publication.
        local pairs=for i=1 to procRuleA.count collect #(procRuleScope[i],procRuleA[i],procRuleB[i],procRuleEnabled[i],procRuleMultiplier[i],procRuleGap[i],procRulePlanar[i])
        #(CyrusNewLayerID(),procEpoch+1,(currentTime as integer),1.0/(units.decodeValue "1m"),count,sets,pairs,CyrusLoadedScriptFingerprint)
    )
    fn procPublicationInfo = (
        if procPublishedInfo.count==0 do throw "No cached procedural publication. Use Update locally first."
        if groupSnapshotKey.count>2097152 do throw "Publication input signature exceeds the inspection budget."
        local result=deepCopy procPublishedInfo
        append result groupSnapshotKey
        result
    )
    fn procPublicationPage publicationID offset limit = (
        if procPublishedInfo.count==0 or procPublishedInfo[1]!=publicationID do throw "Procedural publication changed. Read its manifest again."
        if offset<0 or offset>procPublishedInfo[5] or limit<1 or limit>500 do throw "Publication page bounds are invalid."
        local result=#(),base=0
        for i=1 to groupSnapshotRows.count do (
            local rows=groupSnapshotRows[i],first=amax 1 (offset-base+1),last=amin rows.count (offset+limit-base)
            if first<=last do for j=first to last do (
                local row=rows[j],id=if classof row[3]==String then row[3] else ("c:"+(row[3] as string))
                local keep=row[2]<=procPublishedFinalKeep[i].count and procPublishedFinalKeep[i][row[2]]
                append result #(i,(copy row[1]),row[2],id,(row.count==4 and row[4]==true),procPublishedRadii[i][j],keep)
            )
            base+=rows.count
        )
        #(procPublishedInfo[1],procPublishedInfo[5],offset+result.count,result)
    )

    fn nativeEditors = (for r in #(updateUI,surfaceUI,previewUI,layersUI) where r!=undefined collect r)
    fn brushEditors = (
        local editors=CyrusLayerEditorSections this method:#refreshHistory
        if (CyrusContainerPanel this).controlsReady do for r in (CyrusContainerPanel this).editors where isProperty r #refreshHistory and r.controlsReady do appendIfUnique editors r
        editors
    )
    fn refreshBrushEditors history:false = (for r in this.brushEditors() where r.controlsReady do (if history do r.refreshHistory();r.status()))
    fn syncBrushCompatibility = (
        local editors=CyrusLayerEditorSections this
        if (CyrusContainerPanel this).controlsReady do join editors (CyrusContainerPanel this).editors
        for r in editors where r.controlsReady do (
            if isProperty r #syncRelaxAvailability do r.syncRelaxAvailability()
            if isProperty r #syncFinalRelaxAvailability do r.syncFinalRelaxAvailability()
        )
    )
    fn bindNativeUI = (
        if (CyrusContainerPanel this).controlsReady do (CyrusContainerPanel this).bind()
        CyrusBindLayerEditor this
        true
    )
    rollout mainUI "Cyrus Scatter 0.77" width:#cmdPanel height:30 autoLayoutOnResize:true (
        local root=undefined,controlsReady=false,binding=false,layerBinding=false,roots=#(),editors=#(),owner=undefined,layerPagesVisible=false
        checkbox enabledCheck "Enable Cyrus Scatter" pos:[8,6] width:(mainUI.width-16) tooltip:"Enable calculation and output for this entire Scatter setup."
        timer mountTimer interval:1 active:false
        timer statusTimer interval:1000 active:false
        fn layoutPanels = true
        fn refreshTitles = (
            if owner!=undefined and root.selected_setsUI!=undefined do root.selected_setsUI.title="Paint Areas | "+(root.layerCaption owner)
            CyrusContainerRefreshLabels root;CyrusBindLayerEditor root;true
        )
        fn refreshStats = (
            if not controlsReady do return false
            if root.layersUI!=undefined and root.layersUI.controlsReady do root.layersUI.refreshStats()
            if root.surfaceUI!=undefined and root.surfaceUI.controlsReady do root.surfaceUI.refreshStats()
            root.syncBrushCompatibility();true
        )
        fn bindSection section = (
            if not controlsReady or owner==undefined or findItem root.layerObjects owner==0 do return false
            section.root=root;section.owner=owner;section.panel=mainUI
            if section.open then section.bind (if isProperty section #setSpecific and section.setSpecific then root.selectedPaintSet owner else owner)
            else section.controlsReady=false
            true
        )
        fn bindEditors = (
            if not controlsReady or layerBinding do return false
            layerBinding=true
            try (
            local leaf=root.selectedLayer(),nextOwner=if leaf==undefined then undefined else root.logicalParent leaf
            if nextOwner!=owner do (
                if CyrusBrushSessionRoot==root do CyrusStopBrush()
                max select
                owner=nextOwner
                for r in editors do (
                    r.root=root;r.owner=owner;r.panel=mainUI;r.controlsReady=false
                    if isProperty r #obj do r.obj=undefined
                )
            )
            local showPages=owner!=undefined
            if layerPagesVisible!=showPages do (
                for i=1 to editors.count do if not (cyrusSetRolloutVisible editors[i].hwnd showPages (40+i*10)) do throw "Cannot arrange selected-layer controls."
                layerPagesVisible=showPages
            )
            if owner!=undefined do for r in editors do bindSection r
            refreshTitles();layerBinding=false;true
            )catch(layerBinding=false;throw())
        )
        fn bind = (
            if binding or not controlsReady do return false
            binding=true
            try (
                enabledCheck.checked=root.cyrusEnabled
                for r in root.nativeEditors() where r.controlsReady do r.bind undefined
                bindEditors();binding=false;refreshStats();true
            )catch(binding=false;throw())
        )
        fn rebuild = (bind();CyrusBindLayerEditor root)
        fn rebuildLayers = rebuild()
        fn selectLayerView layer expand:false = (
            if layer==undefined do return false
            local parent=root.logicalParent layer
            if root.selectedLayer()!=parent do undo off root.selectLayer (findItem root.layerObjects parent)
            bindEditors()
            if expand then CyrusOpenLayerEditor root parent
            else if CyrusLayerEditor!=undefined and CyrusLayerEditor.root==root do CyrusLayerEditor.retarget root parent
            if root.layersUI!=undefined and root.layersUI.controlsReady do root.layersUI.bind undefined
            true
        )
        on mainUI open do (root=this;controlsReady=false;mountTimer.active=true)
        on mountTimer tick do (
            if not mainUI.isDisplayed do return false
            mountTimer.active=false
            if cyrusSetRolloutVisible==undefined do throw "Load the matching Cyrus 0.77 native plugin and restart Max."
            root.syncLayerIdentity()
            roots=#(root.flow_updateUI,root.flow_surfaceUI,root.flow_previewUI,root.flow_layersUI)
            root.updateUI=roots[1];root.surfaceUI=roots[2];root.previewUI=roots[3];root.layersUI=roots[4]
            editors=#(root.selected_setsUI,root.selected_sourceUI,root.selected_sourceContainersUI,root.selected_distributionUI,root.selected_populationPolicyUI,root.selected_areaUI,root.selected_brushUI,root.selected_backgroundUI,root.selected_randomUI,root.selected_diversityUI,root.selected_proceduralUI,root.selected_instanceRadiusUI,root.selected_spacingUI,root.selected_separationUI,root.selected_detailsUI,root.selected_workflowUI)
            owner=undefined;layerPagesVisible=false
            for r in editors do (r.root=root;r.owner=undefined;r.panel=mainUI;r.controlsReady=false;r.open=false)
            for i=1 to editors.count do if not (cyrusSetRolloutVisible editors[i].hwnd false (40+i*10)) do throw "Cannot arrange selected-layer controls."
            root.diagnosticsUI.root=root;root.diagnosticsUI.open=false
            if not (cyrusSetRolloutVisible root.diagnosticsUI.hwnd true 220) do throw "Cannot arrange diagnostic controls."
            for i=1 to roots.count do (
                roots[i].open=if i<=root.uiRootState.count then root.uiRootState[i] else (i==4 or (i==2 and (root.validSurfaces()).count==0))
                if not (cyrusSetRolloutVisible roots[i].hwnd true (i*10)) do throw "Cannot arrange Cyrus setup controls."
            )
            cyrusSetRolloutVisible mainUI.hwnd true 0
            controlsReady=true;bind()
        )
        on mainUI close do (
            root.uiRootState=for r in roots collect r.open
            controlsReady=false;statusTimer.active=false;mountTimer.active=false;roots=#();editors=#();owner=undefined;layerPagesVisible=false
            root.updateUI=root.surfaceUI=root.previewUI=root.layersUI=undefined
            -- The modeless editor keeps its explicitly bound owner when scene
            -- selection changes. Command-panel lifetime does not own it.
        )
        on statusTimer tick do (
            statusTimer.active=false
            if CyrusInteractionHeld() do (statusTimer.active=true;return false)
            local sourceChanges=false
            for leaf in root.layerObjects where leaf.containerUIChanged do (leaf.containerUIChanged=false;sourceChanges=true)
            if sourceChanges then root.bindNativeUI() else refreshStats()
        )
        on enabledCheck changed value do if controlsReady and root!=undefined and not binding do (undo "Cyrus enabled" on root.cyrusEnabled=value;root.invalidateGroups();bind())
    )

    rollout flow_updateUI "Update" width:162 category:10 autoLayoutOnResize:true (
        local root=undefined
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false


        radiobuttons updateRadio "Viewport update" labels:#("Manual","Live") columns:1 pos:[6,8] width:(flow_updateUI.width-12)
        button updateNow "Update now" pos:[6,78] width:(flow_updateUI.width-12) tooltip:"Calculate all enabled layers and paint sets in order."
        label updateHint "Updates after a brief pause." pos:[6,110] width:(flow_updateUI.width-12)
        fn syncControls = (updateRadio.state=obj.updateMode;updateHint.text=if obj.updateMode==1 then "Pending edits wait for Update." else "Updates after a brief pause.";)
        on updateNow pressed do if controlsReady and not binding and obj!=undefined do (obj.refreshAll();CyrusViewportRedraw())

        on updateRadio changed v do if controlsReady and not binding and obj!=undefined do (obj.updateMode=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())



        fn bind layer = (
            local next=root
            binding=true;controlsReady=false
            if obj!=next do ()
            obj=next;parentView=(CyrusContainerPanel root)
            for c in flow_updateUI.controls do c.enabled=true
            try (undo off ((syncControls();controlsReady=true;))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        on flow_updateUI open do (root=this;(controlsReady=true;bind (root.selectedLayer())))
        on flow_updateUI close do controlsReady=false
        on flow_updateUI rolledUp state do (CyrusContainerPanel root).layoutPanels()
    )
    rollout flow_surfaceUI "Surface Scatter" width:162 category:20 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,controlsReady=false,binding=false,receiverRows=#()
        multiListBox receiversList "Surfaces" items:#() pos:[8,8] width:(flow_surfaceUI.width-16) height:6
        button removeSurfaces "Remove selected surfaces" pos:[8,108] width:(flow_surfaceUI.width-16) tooltip:"Remove highlighted assignments from this setup. Scene objects are kept."
        pickbutton sharedPick "Pick receiving surface" filter:AminScatterSourceFilter pos:[8,8] width:(flow_surfaceUI.width-16) tooltip:"Add a receiving surface without replacing existing assignments."
        label sharedInfo "Choose a receiving surface." pos:[8,38] width:(flow_surfaceUI.width-16) height:32
        button surfacesButton "Receiving surfaces..." pos:[8,76] width:(flow_surfaceUI.width-16) tooltip:"Add multiple receiving surfaces by name. Existing assignments are kept. Choose the target for each Paint Area under Painting."
        label countInfo "Add a layer in Layer Manager." pos:[8,136] width:(flow_surfaceUI.width-16) height:42
        checkbutton containersToggle "Global source containers" pos:[8,188] width:(flow_surfaceUI.width-16) height:26 tooltip:"Optional shared source pool. Enable Global containers in a layer's Assets tab."
        listbox globalContainers "Global source containers" items:#() pos:[8,224] width:(flow_surfaceUI.width-16) height:4
        button createContainer "Create source rectangle" pos:[8,320] width:(flow_surfaceUI.width-16) tooltip:"Create a source rectangle shared by owners that explicitly use the global pool."
        pickbutton pickContainer "Pick source rectangle" filter:CyrusSourceContainerFilter pos:[8,350] width:(flow_surfaceUI.width-16) tooltip:"Link an existing Cyrus Source Container to the global pool."
        button removeContainer "Unlink selected rectangle" pos:[8,380] width:(flow_surfaceUI.width-16) tooltip:"Unlink the rectangle while keeping its scene node and registered model settings."
        label containerInfo "Choose Global containers under Assets in each layer's editor." pos:[8,414] width:(flow_surfaceUI.width-16) height:48
        fn arrangeContainers = (
            for c in #(globalContainers,createContainer,pickContainer,removeContainer,containerInfo) do c.visible=containersToggle.checked
            flow_surfaceUI.height=if containersToggle.checked then 470 else 222
        )
        fn refreshStats = (
            local total=0,pending=0
            for leaf in root.layerObjects do (local state=leaf.uiLayerStats();if state.hasResult do total+=state.placements;if state.needsUpdate do pending+=1)
            local text=((root.logicalLayers()).count as string)+" layers | "+(CyrusUICount total)+" cached plants\n"+(root.layerObjects.count as string)+" / 10 populations"+(if pending>0 then " | Pending update" else "")
            if countInfo.text!=text do countInfo.text=text
        )
        fn bind layer = (
            binding=true
            local targets=if owner==undefined then #() else owner.validSurfaces(),selected=for i in receiversList.selection where i<=receiverRows.count collect receiverRows[i]
            receiverRows=targets
            receiversList.items=for node in receiverRows collect node.name
            receiversList.selection=for node in selected where findItem receiverRows node>0 collect findItem receiverRows node
            removeSurfaces.enabled=receiversList.selection.numberSet>0
            sharedInfo.text=if targets.count==1 then targets[1].name else (targets.count as string)+" surfaces in this layer"
            globalContainers.items=for node in root.containerGlobalNodes collect (if isValidNode node then node.name else "<deleted rectangle>")
            for control in #(globalContainers,createContainer,pickContainer,removeContainer) do control.enabled=true
            controlsReady=true;binding=false;refreshStats();arrangeContainers()
        )
        fn setSurfaces nodes = (
            local controller=root,uniqueNodes=#()
            for node in nodes where isValidNode node and findItem uniqueNodes node==0 do append uniqueNodes node
            if owner==undefined do return false
            local previous=owner.validSurfaces(),same=previous.count==uniqueNodes.count
            if same do for i=1 to previous.count where previous[i]!=uniqueNodes[i] do same=false
            if same do return false
            controller.setLayerSurfaces owner uniqueNodes
        )
        fn addSurfaces nodes = (if owner==undefined do return false;local combined=owner.validSurfaces();for node in nodes where findItem combined node==0 do append combined node;setSurfaces combined)
        fn removeSelectedSurfaces = (
            local selectedRows=receiversList.selection,remaining=#()
            for i=1 to receiverRows.count do if not selectedRows[i] do append remaining receiverRows[i]
            setSurfaces remaining
        )
        on flow_surfaceUI open do (root=this;bind undefined)
        on flow_surfaceUI close do controlsReady=false
        on containersToggle changed value do arrangeContainers()
        on sharedPick picked node do addSurfaces #(node)
        on receiversList selectionEnd do removeSurfaces.enabled=receiversList.selection.numberSet>0
        on removeSurfaces pressed do removeSelectedSurfaces()
        on surfacesButton pressed do (
            local controller=root,nodes=selectByName title:"Add receiving surfaces" buttonText:"Add selected" filter:AminScatterSourceFilter single:false
            if controlsReady and root==controller and nodes!=undefined and nodes.count>0 do addSurfaces nodes
        )
        on createContainer pressed do try(root.containerCreate globalPool:true;bind undefined)catch(messageBox (getCurrentException()) title:"Cyrus source containers")
        on pickContainer picked node do try(root.containerAdd node globalPool:true;bind undefined)catch(messageBox (getCurrentException()) title:"Cyrus source containers")
        on removeContainer pressed do try(root.containerRemove globalContainers.selection globalPool:true;bind undefined)catch(messageBox (getCurrentException()) title:"Cyrus source containers")
        on flow_surfaceUI rolledUp state do (CyrusContainerPanel root).layoutPanels()
    )

    rollout flow_previewUI "Viewport and Render" width:162 category:30 autoLayoutOnResize:true (
        local root=undefined
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false

        checkbox previewCheck "Show preview" pos:[6,8] width:(flow_previewUI.width-12)
        dropdownlist displayModeDrop "Display mode" items:#("Point Cloud","Proxy","Mesh","Plant centres") pos:[6,34] width:(flow_previewUI.width-12)
        dropdownlist proxyShapeDrop "Proxy shape" items:#("Box","Sphere","Pyramid") pos:[6,82] width:(flow_previewUI.width-12)
        spinner instancesLimitSpin "Instances/layer:" range:[1,100000,2000] type:#integer fieldWidth:58 pos:[6,138] width:(flow_previewUI.width-12)
        spinner faceLimitSpin "Faces/layer:" range:[12,20000000,2000000] type:#integer fieldWidth:58 pos:[6,166] width:(flow_previewUI.width-12)
        dropdownlist identificationDrop "Color by" items:#("Model","Layer") pos:[6,208] width:(flow_previewUI.width-12) tooltip:"Use model or layer identification colors in Points, Proxy and shaded Mesh previews."
        radiobuttons pointColorRadio "Preview color" labels:#("Solid Color","Identification Colors") columns:1 pos:[6,194] width:(flow_previewUI.width-12)
        colorpicker solidColorPicker "Solid: " color:(color 100 220 120) pos:[6,264] width:(flow_previewUI.width-12)
        spinner budgetSpin "Point limit: " range:[1000,500000,20000] type:#integer fieldWidth:58 width:(flow_previewUI.width-12) pos:[6,292]
        spinner pointsSpin "Points/plant: " range:[10,10000,80] type:#integer fieldWidth:58 width:(flow_previewUI.width-12) pos:[6,318]
        spinner radiusLimitSpin "Radii / layer:" range:[0,1000000,2000] type:#integer fieldWidth:58 width:(flow_previewUI.width-12) pos:[6,344]
        checkbox radiusAllCheck "Show All Radii" pos:[6,370] width:(flow_previewUI.width-12)
        label radiusHint "Display only; 0 = hide radii" pos:[6,396] width:(flow_previewUI.width-12)
        spinner iconSpin "Icon size: " range:[0.1,10000,10] type:#worldUnits fieldWidth:58 width:(flow_previewUI.width-12) pos:[6,422]
        button refreshButton "Refresh preview" pos:[6,452] width:(flow_previewUI.width-12)
        checkbox autoRenderCheck "Automatic final render" pos:[6,482] width:(flow_previewUI.width-12)
        button clearBakedButton "Remove old baked output" pos:[6,512] width:(flow_previewUI.width-12)
        label status "Ready" pos:[6,572] width:(flow_previewUI.width-12) height:60

        fn syncDisplay = (
            displayModeDrop.selection=if obj.groupCenters then 4 else obj.viewportMode;proxyShapeDrop.selection=obj.proxyShape
            proxyShapeDrop.visible=obj.viewportMode==2
            instancesLimitSpin.visible=obj.viewportMode!=1;faceLimitSpin.visible=obj.viewportMode!=1
            instancesLimitSpin.value=obj.viewportInstances;faceLimitSpin.value=obj.viewportFaces
            budgetSpin.enabled=obj.viewportMode==1;pointsSpin.enabled=obj.viewportMode==1 and not obj.groupCenters
        )
        fn syncControls = (syncDisplay();identificationDrop.selection=obj.identificationMode;radiusLimitSpin.value=obj.radiusDisplayLimit;radiusAllCheck.checked=obj.radiusDisplayAll;radiusLimitSpin.enabled=not obj.radiusDisplayAll;autoRenderCheck.checked=obj.autoRender;budgetSpin.value=obj.previewBudget;pointColorRadio.state=obj.pointColorMode;solidColorPicker.color=obj.solidPointColor;)
        on radiusLimitSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.radiusDisplayLimit=v;obj.refreshAll();syncControls();CyrusViewportRedraw())
        on radiusAllCheck changed v do if controlsReady and not binding and obj!=undefined do (obj.radiusDisplayAll=v;obj.refreshAll();syncControls();CyrusViewportRedraw())
        on displayModeDrop selected v do if controlsReady and not binding and obj!=undefined do (obj.setGroupDisplay v;syncControls();status.text=obj.allStatus();CyrusViewportRedraw())
        on proxyShapeDrop selected v do if controlsReady and not binding and obj!=undefined do (obj.proxyShape=v;obj.refreshDisplay();syncControls();status.text=obj.allStatus();CyrusViewportRedraw())
        on instancesLimitSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.viewportInstances=v;obj.refreshDisplay();syncControls();status.text=obj.allStatus();CyrusViewportRedraw())
        on faceLimitSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.viewportFaces=v;obj.refreshDisplay();syncControls();status.text=obj.allStatus();CyrusViewportRedraw())
        on previewCheck changed v do if controlsReady and not binding and obj!=undefined do (obj.showPoints=v;CyrusViewportRedraw())
        on pointsSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.pointsPerPlant=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on iconSpin changed v do if controlsReady and not binding and obj!=undefined do obj.iconSize=v
        on refreshButton pressed do if controlsReady and not binding and obj!=undefined do (obj.refreshAll();status.text=obj.allStatus();CyrusViewportRedraw())
        on clearBakedButton pressed do if controlsReady and not binding and obj!=undefined do obj.clearAllBaked()

        on autoRenderCheck changed v do if controlsReady and not binding and obj!=undefined do (obj.autoRender=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on budgetSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.previewBudget=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        fn selectIdentification value = (obj.identificationMode=value;identificationDrop.selection=value;obj.refreshIdentification())
        on identificationDrop selected v do selectIdentification v
        on pointColorRadio changed v do if controlsReady and not binding and obj!=undefined do (obj.pointColorMode=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on solidColorPicker changed v do if controlsReady and not binding and obj!=undefined do (obj.solidPointColor=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())



        fn bind layer = (
            local next=root
            binding=true;controlsReady=false
            if obj!=next do ()
            obj=next;parentView=(CyrusContainerPanel root)
            for c in flow_previewUI.controls do c.enabled=true
            try (undo off ((syncDisplay();identificationDrop.selection=obj.identificationMode;radiusLimitSpin.value=obj.radiusDisplayLimit;radiusAllCheck.checked=obj.radiusDisplayAll;radiusLimitSpin.enabled=not obj.radiusDisplayAll;autoRenderCheck.checked=obj.autoRender;budgetSpin.value=obj.previewBudget;pointColorRadio.state=obj.pointColorMode;solidColorPicker.color=obj.solidPointColor;controlsReady=true;(previewCheck.checked=obj.showPoints;pointsSpin.value=obj.pointsPerPlant;iconSpin.value=obj.iconSize)))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        on flow_previewUI open do (root=this;(controlsReady=true;bind (root.selectedLayer())))
        on flow_previewUI close do controlsReady=false
        on flow_previewUI rolledUp state do (CyrusContainerPanel root).layoutPanels()
    )
    rollout flow_layersUI "Layer Manager" width:162 category:40 autoLayoutOnResize:true (
        local root=undefined,controlsReady=false,binding=false,members=#()
        listbox layerList "Layer | placed | status" pos:[8,8] width:(flow_layersUI.width-16) height:6
        button editButton "Edit layer in window..." pos:[8,138] width:(flow_layersUI.width-16) height:28 tooltip:"Optional floating view of the same layer settings. Select a layer to edit it below in Modify."
        button addButton "Add layer" pos:[8,174] width:(flow_layersUI.width-16) tooltip:"Add a layer and edit its controls below. Layers calculate from top to bottom."
        button copyButton "Copy" pos:[8,204] width:((flow_layersUI.width-22)/2) tooltip:"Copy this layer, its models, surfaces and Paint Areas."
        button removeButton "Remove" pos:[(flow_layersUI.width/2+3),204] width:((flow_layersUI.width-22)/2) tooltip:"Remove this layer and its Paint Areas. Undo restores them."
        colorpicker layerColor "" color:(color 100 220 120) pos:[8,238] width:22 height:22 modal:true notifyAfterAccept:true tooltip:"Identification color for this layer. Choose Layer colors in Viewport & render to display it."
        edittext nameEdit "Name:" pos:[8,236] width:(flow_layersUI.width-16) tooltip:"Rename the selected layer without changing its identity."
        checkbox visibleCheck "Visible in viewport" pos:[8,264] width:(flow_layersUI.width-16) tooltip:"Hide display only. Hidden layers still calculate and affect spacing."
        checkbox enabledCheck "Enabled in output" pos:[8,288] width:(flow_layersUI.width-16) tooltip:"Include this layer in calculation and final output."
        button upButton "Move up" pos:[8,318] width:((flow_layersUI.width-22)/2) tooltip:"Evaluate earlier; earlier layers occupy space first."
        button downButton "Move down" pos:[(flow_layersUI.width/2+3),318] width:((flow_layersUI.width-22)/2) tooltip:"Evaluate after the preceding layers."
        label countInfo "Select a layer." pos:[8,350] width:(flow_layersUI.width-16) height:46
        fn currentLayer = (local leaf=root.selectedLayer();if leaf==undefined then undefined else root.logicalParent leaf)
        fn refreshStats = (
            if not controlsReady do return false
            local rows=#(),selected=currentLayer(),selectedSummary=undefined
            for member in members do (
                local summary=CyrusFlowLayerSummary root member
                append rows ((root.layerCaption member)+" | "+(CyrusUICount summary[1] compact:true)+" | "+summary[3])
                if member==selected do selectedSummary=summary
            )
            binding=true
            if layerList.items as string!=rows as string do layerList.items=rows
            layerList.selection=findItem members selected
            local text=if selectedSummary==undefined then "Select a layer." else "Placed: "+(CyrusUICount selectedSummary[1])+" | Shown: "+(CyrusUICount selectedSummary[2])+"\n"+selectedSummary[3]+"\nCounts describe the last build."
            if countInfo.text!=text do countInfo.text=text
            binding=false
        )
        fn bind layer = (
            binding=true;members=root.logicalLayers()
            local selected=currentLayer(),index=findItem root.layerObjects selected,valid=index>0
            for c in #(editButton,copyButton,removeButton,nameEdit,visibleCheck,enabledCheck) do c.enabled=valid
            nameEdit.text=if valid then root.layerNames[index] else ""
            layerColor.enabled=valid;layerColor.color=if valid then selected.layerIDColor else (color 100 220 120)
            visibleCheck.checked=valid and root.layerVisible[index]
            enabledCheck.checked=valid and root.layerEnabled[index]
            addButton.enabled=root.layerObjects.count<10
            upButton.enabled=true and findItem members selected>1;downButton.enabled=true and findItem members selected<members.count
            controlsReady=true;binding=false;refreshStats()
        )
        on layerColor changed value do if not binding do (local controller=root,layer=currentLayer();undo "Cyrus layer identification color" on layer.layerIDColor=value;controller.refreshIdentification())
        on flow_layersUI open do (root=this;bind undefined)
        on flow_layersUI close do controlsReady=false
        on layerList selected i do if not binding and i>0 do ((CyrusContainerPanel root).selectLayerView members[i];bind undefined)
        on layerList doubleClicked i do if not binding and i>0 do (CyrusContainerPanel root).selectLayerView members[i] expand:true
        on editButton pressed do (CyrusContainerPanel root).selectLayerView (currentLayer()) expand:true
        on addButton pressed do (
            -- Max can close/recreate this rollout during the refresh. The
            -- command owns its controller reference until the action ends.
            local controller=root
            controller.newLayer()
            local added=controller.selectedLayer()
            controller.invalidateGroups();controller.bindNativeUI()
            local targetPanel=CyrusContainerPanel controller
            if targetPanel.controlsReady and targetPanel.root==controller do targetPanel.selectLayerView added
        )
        on copyButton pressed do try(
            local controller=root,parent=controller.copyLogicalLayer (currentLayer())
            local targetPanel=CyrusContainerPanel controller
            if targetPanel.controlsReady and targetPanel.root==controller do targetPanel.selectLayerView parent
        )catch(messageBox (getCurrentException()) title:"Cyrus layer")
        on removeButton pressed do try(root.removeLogicalLayer (currentLayer()))catch(messageBox (getCurrentException()) title:"Cyrus layer")
        on nameEdit entered value do if not binding and value!="" do (
            undo "Cyrus layer name" on root.layerNames[findItem root.layerObjects (currentLayer())]=value
            (CyrusContainerPanel root).refreshTitles();refreshStats()
        )
        on visibleCheck changed value do if not binding do (
            undo "Cyrus layer visibility" on root.layerVisible[findItem root.layerObjects (currentLayer())]=value
            root.procSyncEditVisibility();CyrusViewportRedraw();(CyrusContainerPanel root).refreshStats()
        )
        on enabledCheck changed value do if not binding do (
            undo "Cyrus layer enabled" on root.layerEnabled[findItem root.layerObjects (currentLayer())]=value
            root.invalidateGroups();(CyrusContainerPanel root).refreshStats()
        )
        on upButton pressed do try(root.procMove (currentLayer()) -1)catch(messageBox (getCurrentException()) title:"Cyrus order")
        on downButton pressed do try(root.procMove (currentLayer()) 1)catch(messageBox (getCurrentException()) title:"Cyrus order")
        on flow_layersUI rolledUp state do (CyrusContainerPanel root).layoutPanels()
    )


    rollout selected_setsUI "Paint Areas" width:#cmdPanel category:50 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined,controlsReady=false,binding=false,members=#(),targets=#()
        checkbox paintedCheck "Use Paint Areas" pos:[4,8] width:(selected_setsUI.width-8) tooltip:"Restrict this layer to its painted areas. Turn off to scatter across all its surfaces."
        button importButton "Use existing paint" pos:[4,30] width:(selected_setsUI.width-8) tooltip:"Bring this older layer's existing coverage into a named area without changing its paint. Undo restores the old ownership."
        dropdownlist setList "Paint Area" items:#() pos:[4,36] width:(selected_setsUI.width-8)
        button addButton "+" pos:[4,86] width:60 tooltip:"Create a named area. Painting again edits the selected area."
        button removeButton "Remove" pos:[68,86] width:60 tooltip:"Remove the selected area. Undo restores it."
        edittext nameEdit "Name:" pos:[4,116] width:(selected_setsUI.width-8)
        dropdownlist targetList "Surface" items:#() pos:[4,144] width:(selected_setsUI.width-8) tooltip:"Explicit target within this layer. An area with saved paint cannot be silently retargeted."
        checkbox enabledCheck "Enable area" pos:[4,198] width:(selected_setsUI.width-8)
        label info "Areas use the layer's models. Overlaps combine coverage." pos:[4,226] width:(selected_setsUI.width-8) height:58
        fn currentSet = (root.selectedPaintArea owner)
        fn bind layer = (
            binding=true;members=owner.paintAreas as array;targets=owner.validSurfaces()
            local area=currentSet()
            paintedCheck.checked=owner.paintEnabled
            setList.items=for item in members collect (item.paintSetName+(if findItem targets item.areaTarget==0 then " (inactive)" else ""))
            setList.selection=findItem members area
            targetList.items=for node in targets collect node.name
            for control in #(removeButton,nameEdit,targetList,enabledCheck) do control.enabled=area!=undefined
            nameEdit.text=if area==undefined then "" else area.paintSetName
            targetList.selection=if area==undefined then 0 else findItem targets area.areaTarget
            enabledCheck.checked=area!=undefined and area.paintSetEnabled
            importButton.enabled=owner.paintDocument!=undefined and not owner.areaMode and (root.layerSets owner).count==1
            addButton.enabled=members.count<128 and (root.layerSets owner).count==1
            info.text=if (root.layerSets owner).count>1 then "Older model-owning sets are retained. Conversion is required before adding areas." else if area!=undefined and findItem targets area.areaTarget==0 then "Inactive: assign a surface, or restore this area's original surface to the layer. Saved paint is retained." else "Paint and Erase edit this area. Areas share the layer's models; overlaps do not duplicate plants."
            controlsReady=true;binding=false
        )
        fn selectSet i = (
            if binding or i<1 or i>members.count do return false
            local controller=root,parent=owner
            CyrusStopBrush();parent.uiAreaID=members[i].layerID;controller.bindNativeUI();true
        )
        on importButton pressed do (
            local controller=root,parent=owner
            undo "Cyrus use existing paint" on controller.adoptPaintArea parent
            parent.markInputDirty();controller.bindNativeUI();CyrusViewportRedraw()
        )
        on setList selected i do selectSet i
        on addButton pressed do try(root.addPaintArea owner)catch(messageBox (getCurrentException()) title:"Cyrus Paint Area")
        on removeButton pressed do try(root.removePaintArea owner (currentSet()))catch(messageBox (getCurrentException()) title:"Cyrus Paint Area")
        on nameEdit entered value do if not binding and value!="" and currentSet()!=undefined do (undo "Cyrus area name" on (currentSet()).paintSetName=value;root.bindNativeUI())
        on paintedCheck changed value do if not binding do (
            local controller=root,parent=owner
            CyrusStopBrush();undo "Cyrus coverage mode" on (controller.adoptPaintArea parent;parent.areaMode=true;parent.paintEnabled=value)
            parent.markInputDirty();controller.bindNativeUI();CyrusViewportRedraw()
        )
        on enabledCheck changed value do if not binding and currentSet()!=undefined do (undo "Cyrus area enabled" on (currentSet()).paintSetEnabled=value;owner.markInputDirty();CyrusViewportRedraw())
        on targetList selected i do if not binding and i>0 do try(root.setPaintAreaTarget owner (currentSet()) targets[i])catch(messageBox (getCurrentException()) title:"Cyrus Paint Area";root.bindNativeUI())
        on selected_setsUI open do (root=this;controlsReady=false)
        on selected_setsUI close do controlsReady=false
    )

    rollout selected_sourceUI "Models and settings - layer" width:#cmdPanel category:60 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined
        local setSpecific=true
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false

        local groupPalette=#()
        local loadingColor=false
        local focusedRow=0
        edittext sourceName "Name:" text:"" pos:[4,116] width:(selected_sourceUI.width-8) tooltip:"Label inside Scatter only. Clear it to use the scene object's name."
        colorpicker idColor "" color:(color 100 220 120) pos:[4,118] width:22 height:22 modal:true notifyAfterAccept:true tooltip:"Viewport identification color. This does not change clustering or model frequency."
        multiListBox plantList "Sources (Ctrl/Shift)" items:#() pos:[4,8] height:6 width:(selected_sourceUI.width-8)
        button selectFromScene "Choose from list..." pos:[4,170] width:((selected_sourceUI.width-12)/2) tooltip:"Choose one or more source models by name."
        pickbutton addPlant "Pick model" pos:[4,140] width:((selected_sourceUI.width-12)/2) tooltip:"Pick a scene model for this layer. The editor stays on its layer."
        button addSelected "Add selection" pos:[(selected_sourceUI.width/2+2),140] width:((selected_sourceUI.width-12)/2) tooltip:"Add the currently selected scene objects to this layer."
        button removePlant "Remove rows" pos:[4,200] width:(selected_sourceUI.width-8) tooltip:"Unregister highlighted rows. To keep their settings, park models outside a source rectangle instead."
        button selectPlant "Select sources" pos:[(selected_sourceUI.width/2+2),170] width:((selected_sourceUI.width-12)/2) tooltip:"Select the highlighted source models in the scene."
        button addPoint "Add Point" pos:[4,460] width:((selected_sourceUI.width-12)/2) tooltip:"Add a placeholder source that can later be replaced by a model."
        button addEmpty "Add Empty" pos:[(selected_sourceUI.width/2+2),460] width:((selected_sourceUI.width-12)/2) tooltip:"Add a weighted empty source for intentional gaps in candidate-budget mode."
        pickbutton replacePoint "Replace Point: pick object" filter:AminScatterSourceFilter pos:[4,490] width:(selected_sourceUI.width-8) tooltip:"Replace one highlighted Point row with a scene model."
        label groupHeading "Cluster color group" pos:[4,530] width:(selected_sourceUI.width-8)
        dropdownlist existingGroups "Reuse a group" items:#() pos:[4,552] width:(selected_sourceUI.width-8) tooltip:"Assign highlighted sources to an existing color group for clustering."
        colorpicker groupColor "Color: " color:(color 100 220 120) pos:[4,606] width:(selected_sourceUI.width-8) modal:true notifyAfterAccept:true tooltip:"Assign a color group to highlighted sources when the color is accepted."
        button applyColor "Apply to selected rows" pos:[4,634] width:(selected_sourceUI.width-8) tooltip:"Assign the chosen color group to all highlighted source rows."
        label colorHelp "OK saves the selected color." pos:[4,664] width:(selected_sourceUI.width-8)
        spinner weightSpin "Weight: " range:[0,1,1] scale:0.01 pos:[4,236] width:((selected_sourceUI.width-12)/2) fieldWidth:82 tooltip:"Relative model frequency in this layer. Zero disables the model."
        label weightHelp "0 = off; relative share" pos:[4,378] width:(selected_sourceUI.width-8)
        spinner sourceZSpin "Z Offset: " range:[-1000000,1000000,0] type:#worldunits pos:[4,266] width:((selected_sourceUI.width-12)/2) fieldWidth:82 tooltip:"Offset instances of highlighted models along their placement normal."
        spinner sourceScaleSpin "Scale: " range:[0,10000,1] scale:0.01 pos:[(selected_sourceUI.width/2+2),236] width:((selected_sourceUI.width-12)/2) fieldWidth:82 tooltip:"Per-model scale multiplier. 1 keeps the model's original scale."
        label sourceTransformHelp "Scale: 1 = original" pos:[4,398] width:(selected_sourceUI.width-8)
        spinner radiusSourceSpin "Radius:" type:#worldunits range:[0,1e9,0] pos:[(selected_sourceUI.width/2+2),266] width:((selected_sourceUI.width-12)/2) fieldWidth:82 tooltip:"Collision footprint radius for highlighted source rows, in scene units."
        checkbox followRadiusCheck "Follow Scale" pos:[4,294] width:((selected_sourceUI.width-12)/2) tooltip:"Scale this source's collision footprint with its instance scale."
        checkbox showRadiusCheck "Show Radius" pos:[(selected_sourceUI.width/2+2),294] width:((selected_sourceUI.width-12)/2) tooltip:"Show this source's radius in the viewport; does not change collision rules."
        dropdownlist forwardAxis "Forward axis:" items:#("+Y","-Y","+X","-X") pos:[4,326] width:(selected_sourceUI.width-8) tooltip:"The model's local forward direction, used for orientation."
        fn colorLabel c = ("#"+(formattedPrint (obj.colorKey c) format:"06X"))
        fn updateList = (
            local selectedRows=plantList.selection
            if selectedRows.numberSet==0 and obj.sources.count>0 do selectedRows=#{1}
            plantList.items=for i=1 to obj.sources.count collect ((obj.sourceLabel i)+" | "+(formattedPrint (obj.sourceWeight i) format:".2f"))
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
                obj.syncColors();while obj.sourceEmpty.count<obj.sources.count do append obj.sourceEmpty false;append obj.sourceEmpty false;append obj.sources n;append obj.sourceColors groupColor.color;if obj.sourceWeights.count>0 do append obj.sourceWeights 1.0;if obj.sourceZOffsets.count>0 do append obj.sourceZOffsets 0.0;if obj.sourceScales.count>0 do append obj.sourceScales 1.0;obj.markInputDirty()
            )
        )

        fn showSelectedColor = (
            local rows=plantList.selection
            weightSpin.enabled=rows.numberSet>0;sourceZSpin.enabled=rows.numberSet>0;sourceScaleSpin.enabled=rows.numberSet>0;forwardAxis.enabled=rows.numberSet>0
            if rows.numberSet>0 then (
                if focusedRow<1 or not rows[focusedRow] do focusedRow=(rows as array)[1]
                loadingColor=true
                sourceName.text=obj.sourceLabel focusedRow;idColor.color=obj.sourceIDColor focusedRow
                sourceName.enabled=isValidNode obj.sources[focusedRow];idColor.enabled=sourceName.enabled
                groupColor.color=obj.sourceColor focusedRow
                weightSpin.enabled=true;weightSpin.value=obj.sourceWeight focusedRow
                radiusSourceSpin.value=obj.sourceRadius focusedRow;followRadiusCheck.checked=obj.sourceFollows focusedRow;showRadiusCheck.checked=obj.sourceShows focusedRow;sourceZSpin.value=obj.sourceZOffset focusedRow;sourceScaleSpin.value=obj.sourceScale focusedRow;forwardAxis.selection=obj.sourceForward focusedRow
                existingGroups.selection=findItem groupPalette (obj.sourceColor focusedRow)
                loadingColor=false
            ) else (
                sourceName.text="";sourceName.enabled=false;idColor.enabled=false
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
        on sourceName entered value do if not loadingColor and focusedRow>0 do (obj.setSourceLabel focusedRow value;updateList())
        on idColor changed value do if not loadingColor do (obj.setSourceIDColor plantList.selection value;updateList())
        on addPoint pressed do if controlsReady and not binding and obj!=undefined do (
            local i=obj.addPointSource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();CyrusViewportRedraw()
        )
        on replacePoint picked n do if controlsReady and not binding and obj!=undefined do (
            local rows=plantList.selection as array
            if rows.count!=1 then messageBox "Select one Point row to replace." title:"Cyrus Scatter"
            else if not (obj.replacePointSource rows[1] n) do messageBox "Select a Point row and an object that is not already in this set's source list." title:"Cyrus Scatter"
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
            plantList.selection=#{};obj.markInputDirty();updateList();CyrusViewportRedraw()
        )
        on selectPlant pressed do if controlsReady and not binding and obj!=undefined do (
            local nodes=for i in plantList.selection where i<=obj.sources.count and isValidNode obj.sources[i] collect obj.sources[i]
            if nodes.count>0 do select nodes
        )




        fn bindFeatures layer = (
            local next=layer
            binding=true;controlsReady=false
            if obj!=next do (plantList.selection=#{};)
            obj=next;parentView=(CyrusContainerPanel root)
            for c in selected_sourceUI.controls do c.enabled=layer!=undefined
            try (undo off ((controlsReady=true;(updateList();showSelectedColor())))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        checkbutton detailsToggle "Point / Empty sources and color groups" pos:[4,426] width:(selected_sourceUI.width-8) height:26 tooltip:"Show or hide these advanced controls; their saved settings are preserved."
        fn arrangeDetails = (
            for c in #(addPoint,addEmpty,replacePoint,groupHeading,existingGroups,groupColor,applyColor,colorHelp) do c.visible=detailsToggle.checked
            selected_sourceUI.height=if detailsToggle.checked then 692 else 460
        )
        fn bind layer = (bindFeatures layer;arrangeDetails())
        on detailsToggle changed value do arrangeDetails()
        on selected_sourceUI open do (root=this;controlsReady=false)
        on selected_sourceUI close do controlsReady=false
        on selected_sourceUI rolledUp state do (CyrusContainerPanel root).bindSection selected_sourceUI
    )
    rollout selected_sourceContainersUI "Source containers - own / inherited" width:#cmdPanel category:70 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined,controlsReady=false,binding=false,setSpecific=true,modes=#()
        dropdownlist modeList "Source pool" items:#() pos:[4,8] width:(selected_sourceContainersUI.width-8) tooltip:"Use the model list directly, or optionally collect models from source rectangles."
        listbox containersList "Rectangles" items:#() pos:[4,60] width:(selected_sourceContainersUI.width-8) height:4
        button createContainer "Create container" pos:[4,154] width:(selected_sourceContainersUI.width-8) tooltip:"Create a Rectangle for this owner. Put source-model pivots inside its local XY bounds."
        pickbutton pickContainer "Pick boundary" filter:CyrusSourceContainerFilter pos:[4,184] width:(selected_sourceContainersUI.width-8) tooltip:"Link a Cyrus container, or copy a square-corner Rectangle into a container. The original spline is preserved."
        button removeContainer "Unlink selected rectangle" pos:[4,214] width:(selected_sourceContainersUI.width-8) tooltip:"Unlink this rectangle without deleting it or registered source settings."
        label membershipInfo "Manual source list." pos:[4,244] width:(selected_sourceContainersUI.width-8) height:48
        label helpInfo "Pivot inside = active. Height is ignored. Moving out keeps source settings. Manual needs Update." pos:[4,286] width:(selected_sourceContainersUI.width-8) height:44
        fn currentSet = root.selectedPaintSet owner
        fn bind layer = (
            binding=true
            local leaf=currentSet(),active=true,own=leaf.logicalParentID==""
            modes=if own then #(1,3,4) else #(1,2,3,4)
            modeList.items=if own then #("Manual sources","Global containers","Layer containers") else #("Manual sources","Layer default","Global containers","This set's containers")
            modeList.selection=amax 1 (findItem modes leaf.containerMode)
            local nodes=leaf.effectiveContainers()
            containersList.items=for node in nodes collect (if isValidNode node then node.name else "<deleted rectangle>")
            modeList.enabled=active;containersList.enabled=active
            createContainer.enabled=true;pickContainer.enabled=true;removeContainer.enabled=leaf.containerMode==4
            local registered=leaf.sources.count,count=0
            for value in leaf.containerActive where value do count+=1
            membershipInfo.text=if leaf.containerProvider()==undefined then "Manual source list." else (count as string)+" active / "+(registered as string)+" registered\nGlobal rectangles: Surface Scatter."
            controlsReady=true;binding=false
        )
        on selected_sourceContainersUI open do (root=this;controlsReady=false)
        on selected_sourceContainersUI close do controlsReady=false
        on modeList selected index do if not binding do try((currentSet()).containerSetMode modes[index];bind owner)catch(messageBox (getCurrentException()) title:"Cyrus source containers")
        on createContainer pressed do try((currentSet()).containerCreate();bind owner)catch(messageBox (getCurrentException()) title:"Cyrus source containers")
        on pickContainer picked node do try((currentSet()).containerAdd node;bind owner)catch(messageBox (getCurrentException()) title:"Cyrus source containers")
        on removeContainer pressed do try((currentSet()).containerRemove containersList.selection;bind owner)catch(messageBox (getCurrentException()) title:"Cyrus source containers")
        on selected_sourceContainersUI rolledUp state do (CyrusContainerPanel root).bindSection selected_sourceContainersUI
    )

    rollout selected_distributionUI "Population and seed - layer" width:#cmdPanel category:80 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined
        local setSpecific=false
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false

        radiobuttons modeRadio "Method" labels:#("Random","Texture Density") columns:2 pos:[4,130] width:(selected_distributionUI.width-8)
        radiobuttons populationRadio "Population" labels:#("Count","Plants per m2") columns:2 pos:[4,8] width:(selected_distributionUI.width-8)
        spinner countSpin "Requested count: " range:[1,100000,200] type:#integer fieldWidth:82 width:(selected_distributionUI.width-8) pos:[4,62] tooltip:"Layer population before eligibility. Accepted target can retry up to its limits."
        spinner densitySpin "Per m2: " range:[0,1000000,100] fieldWidth:82 width:(selected_distributionUI.width-8) pos:[4,62] tooltip:"Requested plants per square metre of receiving surface; capped at 100,000."
        spinner seedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:82 width:(selected_distributionUI.width-8) pos:[4,92] tooltip:"Deterministic generation seed. Changing it can invalidate existing Edit bindings."
        label densityHeading "Texture density" pos:[4,180] width:(selected_distributionUI.width-8)
        mapbutton densityButton "Choose density map" pos:[4,204] width:(selected_distributionUI.width-8) tooltip:"Use UV channel 1: white permits candidates; black excludes them."
        checkbox invertCheck "Invert density" pos:[4,234] width:(selected_distributionUI.width-8) tooltip:"Reverse the density map's white and black eligibility."
        label uvHint "UV channel 1; 0..1" pos:[4,260] width:(selected_distributionUI.width-8)
        label mapHint "White: dense / Black: empty" pos:[4,282] width:(selected_distributionUI.width-8)

        fn arrangePopulation = (
            local textured=obj.distributionMode==3
            countSpin.visible=obj.populationMode==1;densitySpin.visible=obj.populationMode==2
            for c in #(densityHeading,densityButton,invertCheck,uvHint,mapHint) do c.visible=textured
            selected_distributionUI.height=if obj.sharedSpacing() then (if textured then 308 else 184) else (if textured then 340 else 208)
        )
        fn syncControls = (populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;;arrangePopulation())
        on modeRadio changed v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.distributionMode=if v==2 then 3 else 1;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on countSpin changed v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.amount=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on seedSpin changed v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.randomSeed=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())

        on populationRadio changed v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.populationMode=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on densitySpin changed v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.plantsPerM2=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on densityButton picked v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.densityMap=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on invertCheck changed v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.invertDensity=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())



        fn bindFeatures layer = (
            local next=layer
            binding=true;controlsReady=false
            if obj!=next do ()
            obj=next;parentView=(CyrusContainerPanel root)
            for c in selected_distributionUI.controls do c.enabled=layer!=undefined
            try (undo off ((populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;controlsReady=true;(countSpin.value=obj.amount;seedSpin.value=obj.randomSeed;modeRadio.state=if obj.distributionMode==3 then 2 else 1)))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        fn bind layer = (bindFeatures layer;arrangePopulation())
        on selected_distributionUI open do (root=this;controlsReady=false)
        on selected_distributionUI close do controlsReady=false
        on selected_distributionUI rolledUp state do (CyrusContainerPanel root).bindSection selected_distributionUI
    )
    rollout selected_populationPolicyUI "Target and retry limits - layer" width:#cmdPanel category:90 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined,controlsReady=false,binding=false,setSpecific=false
        dropdownlist populationList "Layer population" items:#("Candidate budget","Accepted target") pos:[4,8] width:(selected_populationPolicyUI.width-8) tooltip:"Budget evaluates the generated candidates; target makes bounded replacement attempts."
        spinner attemptSpin "Attempt factor:" range:[1,32,8] type:#integer pos:[4,58] width:(selected_populationPolicyUI.width-8) fieldWidth:82 tooltip:"Maximum candidate attempts as a multiple of the requested population."
        spinner roundSpin "Max rounds:" range:[1,16,8] type:#integer pos:[4,86] width:(selected_populationPolicyUI.width-8) fieldWidth:82 tooltip:"Maximum rounds of eligibility, collision and cleanup. A shortfall can remain."
        checkbox repairCheck "Retry cleanup gaps" pos:[4,114] width:(selected_populationPolicyUI.width-8) tooltip:"Allow bounded retries for plants removed by final cleanup."
        label info "Candidate budget makes one bounded population. Accepted target retries rejected candidates up to these limits; it can finish short." pos:[4,152] width:(selected_populationPolicyUI.width-8) height:64
        fn bind layer = (
            binding=true
            for c in selected_populationPolicyUI.controls do c.enabled=true
            populationList.selection=owner.procPopulation;attemptSpin.value=owner.procAttemptFactor;roundSpin.value=owner.procRounds;repairCheck.checked=owner.procRepair
            local retry=true and owner.procPopulation==2
            attemptSpin.enabled=retry;roundSpin.enabled=retry;repairCheck.enabled=retry
            info.enabled=true;controlsReady=true;binding=false
        )
        fn changeLayer key value = (if not binding do (undo "Cyrus procedural settings" on setProperty owner key value;root.invalidateGroups();bind owner))
        on selected_populationPolicyUI open do (root=this;controlsReady=false)
        on selected_populationPolicyUI close do controlsReady=false
        on populationList selected i do changeLayer #procPopulation i
        on attemptSpin changed v do changeLayer #procAttemptFactor v
        on roundSpin changed v do changeLayer #procRounds v
        on repairCheck changed v do changeLayer #procRepair v
        on selected_populationPolicyUI rolledUp state do (CyrusContainerPanel root).bindSection selected_populationPolicyUI
    )

    rollout selected_areaUI "Include / exclude areas - layer" width:#cmdPanel category:100 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined
        local setSpecific=false
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false

        multiListBox areaList "Closed lines / shapes" items:#() pos:[4,8] width:(selected_areaUI.width-8) height:6
        button addAreaScene "Select From Scene..." pos:[4,134] width:(selected_areaUI.width-8) tooltip:"Choose closed Area shapes by name."
        pickbutton pickArea "Add: pick closed line" filter:AminScatterAreaFilter pos:[4,160] width:(selected_areaUI.width-8) tooltip:"Pick a closed shape as an include/exclude Area shared by all sets in this layer."
        button removeArea "Remove selected rows" pos:[4,186] width:(selected_areaUI.width-8) tooltip:"Unlink highlighted Areas and their falloff settings; keep the scene shapes."
        radiobuttons areaMode "Selected area mode" labels:#("Include","Exclude") columns:1 pos:[4,220] width:(selected_areaUI.width-8)
        label areaHint "Exclude overrides Include." pos:[4,290] width:(selected_areaUI.width-8)
        label projectionHint "Top / world XY projection." pos:[4,312] width:(selected_areaUI.width-8)
        button refreshAreas "Refresh areas / preview" pos:[4,340] width:(selected_areaUI.width-8) tooltip:"Refresh Area geometry and recalculate the layer preview."
        local loadingAnalyzerArea=false
        label aaTitle "Surface Analyzer Area" pos:[4,412] width:(selected_areaUI.width-8)
        pickbutton aaPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[4,438] width:(selected_areaUI.width-8) tooltip:"Choose an existing Cyrus Surface Analyzer for line or point masks."
        button aaRemove "Remove Area Analyzer" pos:[4,466] width:(selected_areaUI.width-8) tooltip:"Disable and unlink the layer's Analyzer Area mask."
        checkbox aaLine "Center Line" pos:[4,498] width:(selected_areaUI.width-8) tooltip:"Use the Analyzer centre line as an XY mask; unions with its point mask."
        spinner aaWidth "Full width:" range:[0,1e9,100] type:#worldunits pos:[4,524] width:(selected_areaUI.width-8) fieldWidth:62 tooltip:"Full width of the Analyzer centre-line Area mask."
        dropdownlist aaCaps "Line ends" items:#("Flat","Round") selection:1 pos:[4,552] width:(selected_areaUI.width-8) tooltip:"Flat or round ends for the line mask."
        spinner aaStreetOffset "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[4,606] width:(selected_areaUI.width-8) fieldWidth:62 tooltip:"Lateral offset from the Analyzer centre line."
        checkbox aaPoints "Points" pos:[4,638] width:(selected_areaUI.width-8) tooltip:"Use discs around Analyzer points as an XY mask."
        spinner aaRadius "Radius:" range:[0,1e9,100] type:#worldunits pos:[4,664] width:(selected_areaUI.width-8) fieldWidth:62 tooltip:"Radius of each Analyzer point mask."
        label aaHelp "XY mask. Both enabled = union. Works with Random / Clusters." pos:[4,694] width:(selected_areaUI.width-8) height:40
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
        dropdownlist fallTarget "Edge falloff target" items:#("Analyzer Boundary","Selected Area line") selection:1 pos:[4,738] width:(selected_areaUI.width-8) tooltip:"Edit Analyzer boundary falloff or one highlighted Area's independent falloff."
        pickbutton fallPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[4,794] width:(selected_areaUI.width-8) tooltip:"Choose the Analyzer whose boundary drives this falloff."
        button fallRemove "Remove Analyzer" pos:[4,822] width:(selected_areaUI.width-8) tooltip:"Unlink the falloff Analyzer and disable its falloff effects."
        label fallTargetName "" pos:[4,852] width:(selected_areaUI.width-8) height:40
        checkbox fallDeleteCheck "Delete edge band" pos:[4,894] width:(selected_areaUI.width-8) tooltip:"Exclude an edge band before scale and density ramps begin."
        spinner fallDeleteSpin "Delete width:" range:[0,1e9,0] type:#worldunits pos:[4,920] width:(selected_areaUI.width-8) fieldWidth:62 tooltip:"Width of the excluded edge band in scene units."
        checkbox fallScaleCheck "Scale ramp" pos:[4,952] width:(selected_areaUI.width-8) tooltip:"Vary instance scale with distance from this boundary."
        spinner fallScaleSpin "Scale width:" range:[0,1e9,100] type:#worldunits pos:[4,978] width:(selected_areaUI.width-8) fieldWidth:62 tooltip:"Distance over which the scale curve is evaluated."
        button fallScaleEdit "Edit Scale Graph..." pos:[4,1008] width:(selected_areaUI.width-8) tooltip:"Edit this boundary's scale curve."
        checkbox fallDensityCheck "Density ramp" pos:[4,1044] width:(selected_areaUI.width-8) tooltip:"Vary candidate eligibility with distance from this boundary."
        spinner fallDensitySpin "Density width:" range:[0,1e9,100] type:#worldunits pos:[4,1070] width:(selected_areaUI.width-8) fieldWidth:62 tooltip:"Distance over which the density curve is evaluated."
        button fallDensityEdit "Edit Density Graph..." pos:[4,1100] width:(selected_areaUI.width-8) tooltip:"Edit this boundary's density curve."
        label fallHelp "Ramps start after delete band. Each Area line has its own settings." pos:[4,1138] width:(selected_areaUI.width-8) height:56
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
                append obj.areaNodes n;append obj.areaModes 1;obj.markInputDirty()
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
            obj.markInputDirty();updateAreas();CyrusViewportRedraw()
        )
        on removeArea pressed do if controlsReady and not binding and obj!=undefined do (
            if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()
            local rows=areaList.selection as array
            undo "Cyrus Scatter remove areas" on (
                obj.ensureAreaFalloffs()
                for i=rows.count to 1 by -1 do (deleteItem obj.areaNodes rows[i];deleteItem obj.areaModes rows[i];deleteItem obj.areaFallConfigs rows[i];deleteItem obj.areaFallScaleGraphs rows[i];deleteItem obj.areaFallDensityGraphs rows[i])
            )
            areaList.selection=#{};obj.markInputDirty();updateAreas();CyrusViewportRedraw()
        )
        on refreshAreas pressed do if controlsReady and not binding and obj!=undefined do (obj.markInputDirty();(if obj.overlapOwner==undefined then obj else obj.overlapOwner).refreshAll();CyrusViewportRedraw())




        fn bindFeatures layer = (
            local next=layer
            binding=true;controlsReady=false
            if obj!=next do (areaList.selection=#{};)
            obj=next;parentView=(CyrusContainerPanel root)
            for c in selected_areaUI.controls do c.enabled=layer!=undefined
            try (undo off ((syncAnalyzerArea();syncFalloff();controlsReady=true;updateAreas()))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        checkbutton detailsToggle "Analyzer masks and edge falloff" pos:[4,378] width:(selected_areaUI.width-8) height:26 tooltip:"Show or hide these advanced controls; their saved settings are preserved."
        fn arrangeDetails = (
            for c in #(aaTitle,aaPick,aaRemove,aaLine,aaWidth,aaCaps,aaStreetOffset,aaPoints,aaRadius,aaHelp,fallTarget,fallPick,fallRemove,fallTargetName,fallDeleteCheck,fallDeleteSpin,fallScaleCheck,fallScaleSpin,fallScaleEdit,fallDensityCheck,fallDensitySpin,fallDensityEdit,fallHelp) do c.visible=detailsToggle.checked
            selected_areaUI.height=if detailsToggle.checked then 1202 else 412
        )
        fn bind layer = (bindFeatures layer;arrangeDetails())
        on detailsToggle changed value do arrangeDetails()
        on selected_areaUI open do (root=this;controlsReady=false)
        on selected_areaUI close do controlsReady=false
        on selected_areaUI rolledUp state do (CyrusContainerPanel root).bindSection selected_areaUI
    )
    rollout selected_brushUI "Painting" width:#cmdPanel category:110 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined,obj=undefined,controlsReady=false,binding=false,setSpecific=true
        label targetInfo "Add a Paint Area to begin." pos:[4,8] width:(selected_brushUI.width-8) height:36
        radiobuttons modeRadio "Brush" labels:#("Paint","Erase") columns:2 pos:[4,48] width:(selected_brushUI.width-8)
        spinner radiusSpin "Radius:" type:#worldunits range:[0.0001,1e9,20] pos:[4,94] width:(selected_brushUI.width-8) fieldWidth:82
        spinner strengthSpin "Strength %:" range:[0,100,100] pos:[4,122] width:(selected_brushUI.width-8) fieldWidth:82
        spinner softSpin "Softness %:" range:[0,100,0] pos:[4,150] width:(selected_brushUI.width-8) fieldWidth:82
        button beginButton "Start Brush" pos:[4,178] width:80
        button stopButton "Stop" pos:[88,178] width:80
        button fillButton "Fill" pos:[4,208] width:80
        button emptyButton "Clear" pos:[88,208] width:80
        label brushState "" pos:[4,238] width:(selected_brushUI.width-8) height:54
        spinner densitySpin "Area density %:" range:[0,100,100] pos:[4,298] width:(selected_brushUI.width-8) fieldWidth:82
        dropdownlist overlayMode "Paint feedback" items:#("Coverage tint","Coverage samples","Off") pos:[4,326] width:(selected_brushUI.width-8)
        colorpicker overlayColor "" color:(color 100 220 120) pos:[4,380] width:(selected_brushUI.width-8)
        label brushHelp "Continue painting to edit the same area. Undo/Redo restores brush actions. Manual mode needs Update." pos:[4,412] width:(selected_brushUI.width-8) height:56
        fn refreshHistory = (true)
        fn status = (
            if obj==undefined then brushState.text="Add or select a Paint Area." else (
                local state=if obj.paintDocument==undefined then undefined else cyrusBrushStats obj.paintDocument
                brushState.text=if state==undefined then "Choose this area's surface." else (if state[5]==1 then "Brush active" else "Brush stopped")+(if state[11]!="" then "\n"+state[11] else "")
                if owner!=undefined and not owner.paintEnabled do brushState.text+="\nWhole surfaces; areas retained."
            )
        )
        fn saveOptions = (
            if not binding and obj!=undefined and obj.paintDocument!=undefined do (
                cyrusBrushSettings obj.paintDocument radiusSpin.value (strengthSpin.value/100.0) (softSpin.value/100.0) (modeRadio.state==2) 1.0
                cyrusBrushDisplay obj.paintDocument obj.paintView obj.paintColor
            )
        )
        fn bind layer = (
            binding=true;obj=layer
            local has=obj!=undefined and obj.paintDocument!=undefined
            for control in selected_brushUI.controls do control.enabled=obj!=undefined
            for control in #(stopButton,fillButton,emptyButton) do control.enabled=has
            local target=if obj==undefined then undefined else obj.areaTarget
            targetInfo.text=if obj==undefined then "Add a Paint Area to begin." else obj.paintSetName+" / "+(if isValidNode target then target.name else "<choose surface>")
            beginButton.enabled=obj!=undefined and isValidNode target and findItem (owner.validSurfaces()) target>0
            if obj!=undefined do (densitySpin.value=obj.paintDensity*100;overlayMode.selection=findItem #(2,1,0) obj.paintView;overlayColor.color=obj.paintColor;obj.setOverlapOwner root)
            if has do (local cfg=cyrusBrushOptions obj.paintDocument;radiusSpin.value=cfg[1];strengthSpin.value=cfg[2]*100;softSpin.value=cfg[3]*100;modeRadio.state=if cfg[5] then 2 else 1)
            controlsReady=true;binding=false;status()
        )
        on beginButton pressed do if obj!=undefined do try (
            local controller=root,area=obj,options=#(radiusSpin.value,strengthSpin.value,softSpin.value,modeRadio.state)
            controller.setGroupCoverage area true
            cyrusBrushSettings area.paintDocument options[1] (options[2]/100.0) (options[3]/100.0) (options[4]==2) 1.0
            cyrusBrushDisplay area.paintDocument area.paintView area.paintColor
            CyrusStartBrush controller area
        )catch(messageBox (getCurrentException()) title:"Cyrus Brush")
        on stopButton pressed do (CyrusStopBrush();status())
        on modeRadio changed value do saveOptions()
        on radiusSpin changed value do saveOptions()
        on strengthSpin changed value do saveOptions()
        on softSpin changed value do saveOptions()
        on densitySpin changed value do if not binding and obj!=undefined do (undo "Cyrus area density" on obj.paintDensity=value/100.0;owner.markInputDirty();obj.publishPaint())
        on overlayMode selected value do if not binding and obj!=undefined do (undo "Cyrus paint feedback" on obj.paintView=(#(2,1,0))[value];saveOptions();redrawViews())
        on overlayColor changed value do if not binding and obj!=undefined do (undo "Cyrus paint color" on obj.paintColor=value;saveOptions();redrawViews())
        on fillButton pressed do if obj!=undefined and obj.paintDocument!=undefined do (cyrusBrushFill obj.paintDocument 1.0;obj.publishPaint();status())
        on emptyButton pressed do if obj!=undefined and obj.paintDocument!=undefined do (cyrusBrushFill obj.paintDocument 0.0;obj.publishPaint();status())
        on selected_brushUI open do (root=this;controlsReady=false)
        on selected_brushUI close do (controlsReady=false;CyrusStopBrush())
    )

    rollout selected_backgroundUI "Background fill - paint set" width:#cmdPanel category:120 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined,controlsReady=false,binding=false,setSpecific=true,backgrounds=#()
        dropdownlist backgroundList "This set: background" items:#("Off","Outside painted coverage","Between plants","Outside + between") pos:[4,8] width:(selected_backgroundUI.width-8) tooltip:"Exclude earlier painted coverage, fill between plants, combine both, or turn off."
        multiListBox referenceList "Earlier paint sets" items:#() pos:[4,60] width:(selected_backgroundUI.width-8) height:4
        button applyBackground "Apply background" pos:[4,152] width:(selected_backgroundUI.width-8) tooltip:"Save this background mode and the selected earlier-set references together."
        label backgroundInfo "Outside uses earlier sibling coverage. Between plants uses the rules on the Spacing tab." pos:[4,182] width:(selected_backgroundUI.width-8) height:62
        fn currentSet = (root.selectedPaintSet owner)
        fn bind layer = (
            binding=true
            for c in selected_backgroundUI.controls do c.enabled=true
            local leaf=currentSet()
            backgroundList.selection=leaf.procBackground;backgrounds=#()
            for p in root.layerSets owner while p!=leaf do append backgrounds p
            referenceList.items=for p in backgrounds collect p.paintSetName
            referenceList.selection=for i=1 to backgrounds.count where findItem leaf.procBackgroundIDs backgrounds[i].layerID>0 collect i
            controlsReady=true;binding=false
        )
        on selected_backgroundUI open do (root=this;controlsReady=false)
        on selected_backgroundUI close do controlsReady=false
        on applyBackground pressed do try(
            local leaf=currentSet(),ids=for i in referenceList.selection collect backgrounds[i].layerID
            if backgroundList.selection!=1 and ids.count==0 do throw "Choose at least one earlier paint set."
            undo "Cyrus background coverage" on (leaf.procBackground=backgroundList.selection;leaf.procBackgroundIDs=if backgroundList.selection==1 then #() else ids)
            root.invalidateGroups();bind owner
        )catch(messageBox (getCurrentException()) title:"Cyrus background")
        on selected_backgroundUI rolledUp state do (CyrusContainerPanel root).bindSection selected_backgroundUI
    )

    rollout selected_randomUI "Random transforms - layer" width:#cmdPanel category:130 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined
        local setSpecific=false
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false

        label rotTitle "Rotation (degrees)" pos:[4,8] width:(selected_randomUI.width-8)
        label rotMinTitle "Min" pos:[24,30] width:((selected_randomUI.width-38)/2)
        label rotMaxTitle "Max" pos:[((selected_randomUI.width+18)/2),30] width:((selected_randomUI.width-38)/2)
        label rotXLabel "X" pos:[4,52] width:12
        spinner rotXMinSpin "" range:[-360,360,0]  pos:[24,50] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        spinner rotXMaxSpin "" range:[-360,360,0]  pos:[((selected_randomUI.width+18)/2),50] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        label rotYLabel "Y" pos:[4,76] width:12
        spinner rotYMinSpin "" range:[-360,360,0]  pos:[24,74] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        spinner rotYMaxSpin "" range:[-360,360,0]  pos:[((selected_randomUI.width+18)/2),74] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        label rotZLabel "Z" pos:[4,100] width:12
        spinner rotZMinSpin "" range:[-360,360,0]  pos:[24,98] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        spinner rotZMaxSpin "" range:[-360,360,360]  pos:[((selected_randomUI.width+18)/2),98] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        label sclTitle "Scale (multiplier)" pos:[4,162] width:(selected_randomUI.width-8)
        label sclMinTitle "Min" pos:[24,184] width:((selected_randomUI.width-38)/2)
        label sclMaxTitle "Max" pos:[((selected_randomUI.width+18)/2),184] width:((selected_randomUI.width-38)/2)
        label sclXLabel "X" pos:[4,206] width:12
        spinner sclXMinSpin "" range:[0.001,100,1]  pos:[24,204] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        spinner sclXMaxSpin "" range:[0.001,100,1]  pos:[((selected_randomUI.width+18)/2),204] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        label sclYLabel "Y" pos:[4,230] width:12
        spinner sclYMinSpin "" range:[0.001,100,1]  pos:[24,228] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        spinner sclYMaxSpin "" range:[0.001,100,1]  pos:[((selected_randomUI.width+18)/2),228] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        label sclZLabel "Z" pos:[4,254] width:12
        spinner sclZMinSpin "" range:[0.001,100,1]  pos:[24,252] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        spinner sclZMaxSpin "" range:[0.001,100,1]  pos:[((selected_randomUI.width+18)/2),252] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        label wholeTitle "Whole Scale (uniform)" pos:[4,312] width:(selected_randomUI.width-8)
        label wholeMinTitle "Min" pos:[24,334] width:((selected_randomUI.width-38)/2)
        label wholeMaxTitle "Max" pos:[((selected_randomUI.width+18)/2),334] width:((selected_randomUI.width-38)/2)
        spinner wholeMinSpin "" range:[0.001,1000,1] scale:0.01 pos:[24,356] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        spinner wholeMaxSpin "" range:[0.001,1000,1] scale:0.01 pos:[((selected_randomUI.width+18)/2),356] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        on wholeMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.wholeScaleMin=v;if v>obj.wholeScaleMax do (obj.wholeScaleMax=v;wholeMaxSpin.value=v);CyrusViewportRedraw())
        on wholeMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.wholeScaleMax=v;if v<obj.wholeScaleMin do (obj.wholeScaleMin=v;wholeMinSpin.value=v);CyrusViewportRedraw())
        label movTitle "Movement (world units)" pos:[4,422] width:(selected_randomUI.width-8)
        label movMinTitle "Min" pos:[24,444] width:((selected_randomUI.width-38)/2)
        label movMaxTitle "Max" pos:[((selected_randomUI.width+18)/2),444] width:((selected_randomUI.width-38)/2)
        label movXLabel "X" pos:[4,466] width:12
        spinner movXMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[24,464] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        spinner movXMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[((selected_randomUI.width+18)/2),464] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        label movYLabel "Y" pos:[4,490] width:12
        spinner movYMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[24,488] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        spinner movYMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[((selected_randomUI.width+18)/2),488] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        label movZLabel "Z" pos:[4,514] width:12
        spinner movZMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[24,512] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        spinner movZMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[((selected_randomUI.width+18)/2),512] fieldWidth:((selected_randomUI.width-38)/2) width:((selected_randomUI.width-38)/2)
        checkbox projectCheck "Keep on surface" pos:[4,576] width:(selected_randomUI.width-8) tooltip:"Project random movement back onto the receiving surface."
        checkbox alignCheck "Align to normal" pos:[4,600] width:(selected_randomUI.width-8) tooltip:"Align instances to the receiving surface normal."

        button resetRotation "Reset rotation" pos:[4,124] width:(selected_randomUI.width-8) height:20 tooltip:"Reset only this layer's random rotation limits. Undo is available."
        button resetScale "Reset XYZ scale" pos:[4,278] width:(selected_randomUI.width-8) height:20 tooltip:"Reset only this layer's separate X, Y and Z scale limits."
        button resetWholeScale "Reset whole scale" pos:[4,382] width:(selected_randomUI.width-8) height:20 tooltip:"Reset only this layer's uniform scale multiplier."
        button resetMovement "Reset movement" pos:[4,536] width:(selected_randomUI.width-8) height:20 tooltip:"Reset only this layer's random translation limits."
        fn resetBoundRandomization kind = (
            undo "Cyrus reset layer transforms" on owner.resetRandomization kind
            selected_randomUI.bind owner;root.invalidateGroups();true
        )
        on resetRotation pressed do resetBoundRandomization #rotation
        on resetScale pressed do resetBoundRandomization #scale
        on resetWholeScale pressed do resetBoundRandomization #wholeScale
        on resetMovement pressed do resetBoundRandomization #movement
        fn syncControls = (projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;)
        on alignCheck changed v do if controlsReady and not binding and obj!=undefined do (obj.alignNormal=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())

        on projectCheck changed v do if controlsReady and not binding and obj!=undefined do (obj.projectMove=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on rotXMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.rotXMin=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on rotXMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.rotXMax=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on rotYMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.rotYMin=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on rotYMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.rotYMax=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on rotZMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.rotZMin=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on rotZMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.rotZMax=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on sclXMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.sclXMin=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on sclXMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.sclXMax=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on sclYMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.sclYMin=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on sclYMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.sclYMax=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on sclZMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.sclZMin=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on sclZMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.sclZMax=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on movXMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movXMin=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on movXMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movXMax=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on movYMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movYMin=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on movYMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movYMax=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on movZMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movZMin=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on movZMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movZMax=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())



        fn bind layer = (
            local next=layer
            binding=true;controlsReady=false
            if obj!=next do ()
            obj=next;parentView=(CyrusContainerPanel root)
            for c in selected_randomUI.controls do c.enabled=layer!=undefined
            try (undo off ((wholeMinSpin.value=obj.wholeScaleMin;wholeMaxSpin.value=obj.wholeScaleMax;projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;controlsReady=true;alignCheck.checked=obj.alignNormal))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        on selected_randomUI open do (root=this;controlsReady=false)
        on selected_randomUI close do controlsReady=false
        on selected_randomUI rolledUp state do (CyrusContainerPanel root).bindSection selected_randomUI
    )
    rollout selected_diversityUI "Source assignment - layer" width:#cmdPanel category:140 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined
        local setSpecific=false
        local binding=false,
        obj=undefined,parentView=undefined
        local boundaryOnly=false
        local controlsReady=false,strokeExpandedHeight=0

        radiobuttons diversityRadio "Source assignment" labels:#("Random mix","Clusters","Spline bands","Surface Analyzer") columns:1 pos:[4,8] width:(selected_diversityUI.width-8)
        label layoutHelp "" pos:[4,90] width:(selected_diversityUI.width-8) height:36
        label analyzerStatus "Pick a Surface Analyzer." pos:[4,100] width:(selected_diversityUI.width-8) height:54
        button selectAnalyzer "Select" pos:[4,100] width:70 tooltip:"Select the linked Surface Analyzer in the scene."
        button updateAnalyzer "Update Analyzer" pos:[4,124] width:140 tooltip:"Analyze the linked guide. In Manual mode, use Update scatter afterwards to publish placements."
        spinner sizeSpin "Size: " range:[0.01,100000,10] type:#worldUnits fieldWidth:82 width:(selected_diversityUI.width-8) pos:[4,104] tooltip:"Spatial size of source-color clusters."
        spinner divSeedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:82 width:(selected_diversityUI.width-8) pos:[4,130] tooltip:"Change source assignment randomness without changing the generation seed."
        spinner roughSpin "Roughness %: " range:[0,100,0] fieldWidth:82 width:(selected_diversityUI.width-8) pos:[4,156]
        spinner blurSpin "Blur edge %: " range:[0,100,0] fieldWidth:82 width:(selected_diversityUI.width-8) pos:[4,182]
        spinner noiseSpin "Noise %: " range:[0,100,0] fieldWidth:82 width:(selected_diversityUI.width-8) pos:[4,208]
        label groupHint "Uses assignment groups, not viewport colors." pos:[4,238] width:(selected_diversityUI.width-8)
        label fixedHint "Point positions stay fixed." pos:[4,260] width:(selected_diversityUI.width-8)




        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Spline bands" pos:[4,118] width:(selected_diversityUI.width-8)
        dropdownlist pathsDrop "Paths" items:#() pos:[4,142] width:(selected_diversityUI.width-8)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[4,142] width:(selected_diversityUI.width-8)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[4,192] width:(selected_diversityUI.width-8) tooltip:"Use Surface Analyzer output for bands, rows and fixed anchors."
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[4,192] width:(selected_diversityUI.width-8) tooltip:"Pick a spline for Line Pattern assignment."
        button removePath "Remove path" pos:[4,218] width:(selected_diversityUI.width-8) tooltip:"Remove the selected assignment path while keeping the scene spline."
        listbox strokesList "Bands" items:#() pos:[4,250] width:(selected_diversityUI.width-8) height:4
        button addOutside "Add Outside" pos:[4,346] width:((selected_diversityUI.width-12)/2) tooltip:"Add a source-assignment band outside the selected path."
        button addInside "Add Inside" pos:[(if boundaryOnly then 4 else selected_diversityUI.width/2+2),346] width:(if boundaryOnly then selected_diversityUI.width-8 else (selected_diversityUI.width-12)/2) tooltip:"Add a source-assignment band inside the selected path."
        button removeStrokeButton "Remove band" pos:[4,372] width:(selected_diversityUI.width-8) tooltip:"Remove the selected band and its settings."
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[4,406] width:(selected_diversityUI.width-8) fieldWidth:82
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[4,434] width:(selected_diversityUI.width-8)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[4,506] width:(selected_diversityUI.width-8) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[4,618] width:(selected_diversityUI.width-8) fieldWidth:82
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[4,644] width:(selected_diversityUI.width-8) fieldWidth:82
        button refreshGroups "Refresh sources / groups" pos:[4,676] width:(selected_diversityUI.width-8) tooltip:"Refresh available source color groups for assignment."
        label strokeHelp "Outside bands: empty. First match wins." pos:[4,704] width:(selected_diversityUI.width-8)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[4,814] width:(selected_diversityUI.width-8) fieldWidth:82
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[4,842] width:(selected_diversityUI.width-8) fieldWidth:82
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[4,870] width:(selected_diversityUI.width-8) fieldWidth:82
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[4,898] width:(selected_diversityUI.width-8) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[4,940] width:(selected_diversityUI.width-8)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[4,968] width:(selected_diversityUI.width-8) fieldWidth:82
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[4,996] width:(selected_diversityUI.width-8) fieldWidth:82
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[4,1024] width:(selected_diversityUI.width-8) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[4,1066] width:(selected_diversityUI.width-8) fieldWidth:82
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[4,1094] width:(selected_diversityUI.width-8) fieldWidth:82
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[4,1122] width:(selected_diversityUI.width-8) fieldWidth:82
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[4,814] width:(selected_diversityUI.width-8) fieldWidth:62
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[4,842] width:(selected_diversityUI.width-8) fieldWidth:62
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[4,814] width:(selected_diversityUI.width-8) fieldWidth:62
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[4,874] width:(selected_diversityUI.width-8) height:44
        checkbox faceOutCheck "Face outward" pos:[4,756] width:(selected_diversityUI.width-8)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[4,784] width:(selected_diversityUI.width-8) fieldWidth:82
        checkbox straightStreet "Straight ends (Street Side)" pos:[4,730] width:(selected_diversityUI.width-8)
        fn syncControls = (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;)
        on faceOutCheck changed v do if controlsReady and not binding and obj!=undefined do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.markInputDirty();CyrusViewportRedraw()
        )
        on cornerRadiusSpin changed v do if controlsReady and not binding and obj!=undefined do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.markInputDirty();CyrusViewportRedraw()
        )
        on streetStartSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (obj.streetTrimStart=v;CyrusViewportRedraw())
        on streetEndSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (obj.streetTrimEnd=v;CyrusViewportRedraw())
        on centerStreetSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (obj.centerStreetOffset=v;CyrusViewportRedraw())
        on straightStreet changed v do if controlsReady and not binding and obj!=undefined do (obj.streetStraight=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
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
                    for n in obj.sources where isValidNode n do (append choiceValues n;append labels (obj.sourceLabel (obj.sourceRow n)))
                    for i=1 to obj.strokeSourceRows.count where obj.strokeSourceRows[i]==row do (
                        local k=findItem choiceValues obj.strokeSourceNodes[i];if k>0 do selectedRows[k]=true
                    )
                )
                strokeChoices.items=labels;strokeChoices.selection=selectedRows
            )
            loadingStroke=false
            if obj.diversityMode>=3 do (
                local analyzed=obj.diversityMode==4
                strokeHelp.text=if analyzed then "Width is spread per side; spacing and masks still apply." else "Outside bands: empty. First match wins."
                local guideReady=if analyzed then isValidNode obj.analyzerNode else pathsDrop.selection>0
                if not guideReady then strokeHelp.text=if analyzed then "Pick an Analyzer to begin." else "Pick a closed spline to begin."
                else if strokeRows.count==0 then strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "Add an edge row, then choose models." else "Add a band, then choose models."
                else if selectedStroke()>0 and strokeChoices.selection.numberSet==0 then strokeHelp.text="Choose models or groups for this band."
                else if analyzed and analyzerChannel.selection==5 then strokeHelp.text="Spacing controls row count. Amount 0 disables output."
                else if analyzed and analyzerChannel.selection==3 and obj.strokeSides[selectedStroke()]==5 then strokeHelp.text="Analyzer points control count. Amount 0 disables output."
            )
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
        fn updateAnalyzerStatus = (
            local guide=obj.analyzerNode,valid=isValidNode obj.analyzerNode
            selectAnalyzer.enabled=valid;updateAnalyzer.enabled=valid
            analyzerStatus.text=if not valid then "Pick an existing Analyzer. Open planar surfaces only." else (
                local target=if isValidNode guide.surface then guide.surface.name else "Missing surface"
                local state=if not guide.cyrusEnabled then "Disabled" else if not isValidNode guide.surface then "Missing surface" else if not isProperty guide #analysisCurrent then "Update Analyzer script" else if not guide.analysisCurrent() then "Update Analyzer needed" else "Ready"
                guide.name+"\nSurface: "+target+"\n"+state
            )
        )
        on selectAnalyzer pressed do if controlsReady and not binding and obj!=undefined do (
            local guide=obj.analyzerNode
            if isValidNode guide do (select guide;max modify mode)
        )
        on updateAnalyzer pressed do if controlsReady and not binding and obj!=undefined do (
            local savedOwner=obj,guide=obj.analyzerNode
            if isValidNode guide do try (
                guide.runAnalysis();savedOwner.markInputDirty()
                if controlsReady and obj==savedOwner do updateAnalyzerStatus()
                CyrusViewportRedraw()
            )catch(if controlsReady and obj==savedOwner do analyzerStatus.text="Analysis failed: "+getCurrentException())
        )
        fn updatePattern = (
            updateAnalyzerStatus()
            layoutHelp.text=case obj.diversityMode of (
                1: "Mix models using their weights."
                2: "Group models into patches. Size controls patch size."
                3: "Closed spline bands use top-down XY projection."
                4: "Use the linked Analyzer's published guides."
            )
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
            strokeTitle.text=if analyzed then "Analyzer bands / rows" else "Spline bands"
            addOutside.text=if not analyzed or analyzerChannel.selection==1 then "Add Outside" else (if analyzerChannel.selection==2 then "Add band" else "Add Radius")
            addInside.text=if analyzed and analyzerChannel.selection==3 then "Add Single" else "Add Inside"
            boundaryOnly=analyzed and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5)
            addOutside.visible=(obj.diversityMode==3 or analyzed) and not boundaryOnly
            addInside.pos=[if boundaryOnly then 4 else selected_diversityUI.width/2+2,addOutside.pos.y]
            addInside.width=if boundaryOnly then selected_diversityUI.width-8 else (selected_diversityUI.width-12)/2
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add band inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside bands: empty. First match wins."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()

        )

        on pathsDrop selected i do if controlsReady and not binding and obj!=undefined do showPath()
        on analyzerChannel selected i do if controlsReady and not binding and obj!=undefined do updatePattern()
        on pickAnalyzer picked n do if controlsReady and not binding and obj!=undefined do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.markInputDirty();updatePattern();CyrusViewportRedraw())
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
            updatePattern();obj.markInputDirty();syncControls();CyrusViewportRedraw()
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
        on strokeWidth changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.markInputDirty();showPath();CyrusViewportRedraw())
        on strokeMode changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on strokeChoices selectionEnd do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            CyrusViewportRedraw()
        )
        on strokeScaleMin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on strokeScaleMax changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on refreshGroups pressed do if controlsReady and not binding and obj!=undefined do updatePattern()
                fn updateControls = (
            for c in #(sizeSpin,divSeedSpin,roughSpin,blurSpin,noiseSpin,groupHint,fixedHint) do c.visible=obj.diversityMode==2
            for c in #(strokeTitle,pathsDrop,analyzerChannel,pickAnalyzer,pickPath,removePath,strokesList,addOutside,addInside,removeStrokeButton,strokeWidth,strokeMode,strokeChoices,strokeScaleMin,strokeScaleMax,refreshGroups,strokeHelp) do c.visible=(obj.diversityMode==3 or obj.diversityMode==4)
            if strokeExpandedHeight>0 do selected_diversityUI.height=if obj.diversityMode>=3 then strokeExpandedHeight else (if obj.diversityMode==2 then 310 else 124)*1.0
            (CyrusContainerPanel root).layoutPanels()
        )
        on diversityRadio changed v do if controlsReady and not binding and obj!=undefined do (obj.diversityMode=v;updateControls();updatePattern();obj.markInputDirty();syncControls();CyrusViewportRedraw())


        on sizeSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.diversitySize=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on divSeedSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.diversitySeed=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on roughSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.roughness=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on blurSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.blurryEdge=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on noiseSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.diversityNoise=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())



        fn bind layer = (
            local next=layer
            binding=true;controlsReady=false
            if obj!=next do (strokesList.selection=0;strokeChoices.selection=0;)
            obj=next;parentView=(CyrusContainerPanel root)
            for c in selected_diversityUI.controls do c.enabled=layer!=undefined
            try (undo off ((diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;controlsReady=true;strokeExpandedHeight=selected_diversityUI.height;updateControls();updatePattern()))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        on selected_diversityUI open do (root=this;controlsReady=false)
        on selected_diversityUI close do controlsReady=false
        on selected_diversityUI rolledUp state do (CyrusContainerPanel root).bindSection selected_diversityUI
    )
    rollout selected_proceduralUI "Spacing rules - selected scope" width:146 category:150 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined,controlsReady=false,binding=false,setSpecific=true,peers=#(),scopeRows=#(1,4)
        dropdownlist scopeList "Spacing scope" items:#("Within this layer","Between layers") pos:[4,12] width:(selected_proceduralUI.width-8) selection:1 tooltip:"Choose spacing within the selected layer or between it and another layer."
        dropdownlist peerList "Other owner" items:#() pos:[4,64] width:(selected_proceduralUI.width-8)
        checkbox enabledCheck "Enable this spacing" pos:[4,118] width:(selected_proceduralUI.width-8)
        spinner multiplierSpin "Radius factor:" range:[0,10000,1] pos:[4,146] width:(selected_proceduralUI.width-8) fieldWidth:82
        spinner gapSpin "Extra gap:" range:[0,1e9,0] type:#worldUnits pos:[4,174] width:(selected_proceduralUI.width-8) fieldWidth:82
        checkbox planarCheck "XY distance (off = 3D)" pos:[4,202] width:(selected_proceduralUI.width-8)
        label ruleInfo "Factor x (radius A + radius B) + gap" pos:[4,230] width:(selected_proceduralUI.width-8) height:40
        button resetRule "Use inherited / default" pos:[4,274] width:(selected_proceduralUI.width-8)
        fn currentScope = (if scopeList.selection>0 and scopeList.selection<=scopeRows.count then scopeRows[scopeList.selection] else 1)
        fn currentSet = (root.selectedPaintSet owner)
        fn bindRule resetPeer:false = (
            local wasBinding=binding,leaf=currentSet(),scope=currentScope(),rule,previous=undefined,pair=scope==3 or scope==4
            if not resetPeer and peerList.selection>0 and peerList.selection<=peers.count do previous=peers[peerList.selection]
            binding=true
            try (
                peers=case scope of (3:(for p in root.layerSets owner where p!=leaf collect p);4:(for p in root.logicalLayers() where p!=owner collect p);default:#())
                peerList.items=for p in peers collect (if scope==4 then root.layerCaption p else p.paintSetName)
                peerList.selection=if peers.count==0 then 0 else amax 1 (findItem peers previous)
                local editable=not pair or peers.count>0
                peerList.enabled=pair and editable
                for c in #(enabledCheck,multiplierSpin,gapSpin,planarCheck,resetRule) do c.enabled=editable
                rule=case scope of (
                    1: leaf.procSelfRule()
                    2:#(owner.procSiblingEnabled,owner.procSiblingMultiplier,owner.procSiblingGap,owner.procSiblingPlanar)
                    5:#(owner.procLayerSelfEnabled,owner.procLayerSelfMultiplier,owner.procLayerSelfGap,owner.procLayerSelfPlanar)
                    default:#(false,1.0,0.0,false)
                )
                if pair and peerList.selection>0 do (
                    local i=root.procPair (scope-2) (if scope==3 then leaf else owner) peers[peerList.selection]
                    if i>0 then rule=#(root.procRuleEnabled[i],root.procRuleMultiplier[i],root.procRuleGap[i],root.procRulePlanar[i])
                    else if scope==3 do rule=#(owner.procSiblingEnabled,owner.procSiblingMultiplier,owner.procSiblingGap,owner.procSiblingPlanar)
                )
                enabledCheck.checked=rule[1];multiplierSpin.value=rule[2];gapSpin.value=rule[3];planarCheck.checked=rule[4]
                ruleInfo.text=if not editable then "Add another owner for a pair rule." else if scope==1 and not leaf.procSelfOverride then "Using the saved default. Changing a value creates an override." else "Factor x (radius A + radius B) + gap. Saves automatically."
                binding=wasBinding
            )catch(binding=wasBinding;throw())
        )
        fn bind layer = (
            binding=true
            local previous=currentScope(),older=(root.layerSets owner).count>1
            scopeRows=if older then #(1,2,3,4,5) else #(1,4)
            scopeList.items=if older then #("Within model group","Between model groups","Pair of model groups","Between layers","Layer default") else #("Within this layer","Between layers")
            scopeList.selection=amax 1 (findItem scopeRows previous)
            bindRule();controlsReady=true;binding=false
        )
        on selected_proceduralUI open do (root=this;controlsReady=false)
        on selected_proceduralUI close do controlsReady=false
        fn saveRule = (
            if binding or not controlsReady do return false
            local leaf=currentSet(),scope=currentScope(),pair=scope==3 or scope==4
            if pair and (peerList.selection<1 or peerList.selection>peers.count) do return false
            try (
                undo "Cyrus scoped spacing" on case scope of (
                    1:(leaf.procSelfOverride=true;leaf.procSelfEnabled=enabledCheck.checked;leaf.procSelfMultiplier=multiplierSpin.value;leaf.procSelfGap=gapSpin.value;leaf.procSelfPlanar=planarCheck.checked)
                    2:(owner.procSiblingEnabled=enabledCheck.checked;owner.procSiblingMultiplier=multiplierSpin.value;owner.procSiblingGap=gapSpin.value;owner.procSiblingPlanar=planarCheck.checked)
                    5:(owner.procLayerSelfEnabled=enabledCheck.checked;owner.procLayerSelfMultiplier=multiplierSpin.value;owner.procLayerSelfGap=gapSpin.value;owner.procLayerSelfPlanar=planarCheck.checked)
                    default: root.procSetPair (scope-2) (if scope==3 then leaf else owner) peers[peerList.selection] enabledCheck.checked multiplierSpin.value gapSpin.value planarCheck.checked
                )
                root.invalidateGroups();ruleInfo.text="Factor x (radius A + radius B) + gap. Saves automatically.";true
            )catch(bindRule();messageBox (getCurrentException()) title:"Cyrus spacing";false)
        )
        on scopeList selected i do if not binding do bindRule resetPeer:true
        on peerList selected i do if not binding and i>0 do bindRule()
        on enabledCheck changed value do saveRule()
        on multiplierSpin changed value do saveRule()
        on gapSpin changed value do saveRule()
        on planarCheck changed value do saveRule()
        on resetRule pressed do try(
            local leaf=currentSet(),scope=currentScope()
            undo "Cyrus spacing inheritance" on case scope of (
                1: leaf.procSelfOverride=false
                2:(owner.procSiblingEnabled=false;owner.procSiblingMultiplier=1;owner.procSiblingGap=0;owner.procSiblingPlanar=false)
                5:(owner.procLayerSelfEnabled=false;owner.procLayerSelfMultiplier=1;owner.procLayerSelfGap=0;owner.procLayerSelfPlanar=false)
                default:(if peerList.selection>0 do root.procRemoveRule (root.procPair (scope-2) (if scope==3 then leaf else owner) peers[peerList.selection]))
            )
            root.invalidateGroups();bind owner
        )catch(messageBox (getCurrentException()) title:"Cyrus spacing")
        on selected_proceduralUI rolledUp state do (CyrusContainerPanel root).bindSection selected_proceduralUI
    )


    rollout selected_instanceRadiusUI "Instance radii - CS Edit" width:#cmdPanel category:160 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined,controlsReady=false,setSpecific=true
        dropdownlist radiusMode "Selected CS Edit instances" items:#("World radius","Radius multiplier") selection:1 pos:[4,8] width:(selected_instanceRadiusUI.width-8) tooltip:"Use an absolute world radius or multiply the selected instances' source radius."
        spinner radiusSpin "Value:" range:[0,1e9,1] pos:[4,60] width:(selected_instanceRadiusUI.width-8) fieldWidth:82 tooltip:"Value applied only when Set selected radii is pressed."
        button applyRadius "Set selected radii" pos:[4,88] width:(selected_instanceRadiusUI.width-8) tooltip:"Apply radius overrides to selected instances in this layer or older model group."
        button resetRadius "Clear selected overrides" pos:[4,116] width:(selected_instanceRadiusUI.width-8) tooltip:"Restore the selected instances' inherited source radii."
        button clearRadius "Clear radius overrides" pos:[4,144] width:(selected_instanceRadiusUI.width-8) tooltip:"Remove instance-radius overrides for this layer or older model group."
        label info "Select instances with CS Edit before applying a radius. Overrides follow their stable instance identities." pos:[4,180] width:(selected_instanceRadiusUI.width-8) height:54
        fn currentSet = (root.selectedPaintSet owner)
        fn bind layer = (for c in selected_instanceRadiusUI.controls do c.enabled=true;controlsReady=true)
        on selected_instanceRadiusUI open do (root=this;controlsReady=false)
        on selected_instanceRadiusUI close do controlsReady=false
        on applyRadius pressed do try((currentSet()).procSelectedRadius radiusMode.selection radiusSpin.value;bind owner)catch(messageBox (getCurrentException()) title:"Cyrus radius")
        on resetRadius pressed do try((currentSet()).procSelectedRadius radiusMode.selection radiusSpin.value reset:true;bind owner)catch(messageBox (getCurrentException()) title:"Cyrus radius")
        on clearRadius pressed do try((currentSet()).procClearRadii();bind owner)catch(messageBox (getCurrentException()) title:"Cyrus radius")
        on selected_instanceRadiusUI rolledUp state do (CyrusContainerPanel root).bindSection selected_instanceRadiusUI
    )

    rollout selected_spacingUI "Candidate Relax - layer" width:#cmdPanel category:170 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined,obj=undefined,controlsReady=false,binding=false
        checkbox relaxCheck "Point Relax" pos:[4,8] width:(selected_spacingUI.width-8) tooltip:"Separate nearby candidates on the receiving surface before Brush, artist edits and spacing. Fixed anchors stay fixed."
        spinner spacingSpin "Desired spacing:" pos:[4,36] width:(selected_spacingUI.width-8) fieldWidth:82 type:#worldUnits range:[0.00001,1e9,0.2]
        spinner iterationsSpin "Iterations:" pos:[4,64] width:(selected_spacingUI.width-8) fieldWidth:82 type:#integer range:[1,100,10]
        spinner strengthSpin "Strength %:" pos:[4,92] width:(selected_spacingUI.width-8) fieldWidth:82 range:[0,100,50]
        checkbox boundaryRelaxCheck "Boundary Relax" pos:[4,128] width:(selected_spacingUI.width-8) tooltip:"Smooth candidate neighborhoods with bounded movement. Eligibility is checked before publication; author edits run afterwards."
        spinner finalStrengthSpin "Strength:" pos:[4,156] width:(selected_spacingUI.width-8) fieldWidth:82 range:[0,1,.3]
        spinner finalIterSpin "Iterations:" pos:[4,184] width:(selected_spacingUI.width-8) fieldWidth:82 type:#integer range:[0,100,5]
        spinner finalMoveSpin "Max movement:" pos:[4,212] width:(selected_spacingUI.width-8) fieldWidth:82 type:#worldUnits range:[0,1e9,10]
        label orderHint "Candidates move first; optional Painting, instance edits and spacing follow." pos:[4,244] width:(selected_spacingUI.width-8) height:58
        fn bind layer = (
            binding=true;obj=owner
            relaxCheck.checked=obj.relaxEnabled;spacingSpin.value=obj.relaxSpacing;iterationsSpin.value=obj.relaxIterations;strengthSpin.value=obj.relaxStrength*100
            boundaryRelaxCheck.checked=obj.finalRelax;finalStrengthSpin.value=obj.finalStrength;finalIterSpin.value=obj.finalIterations;finalMoveSpin.value=obj.finalMaxMove
            for c in #(spacingSpin,iterationsSpin,strengthSpin) do c.enabled=obj.relaxEnabled
            for c in #(finalStrengthSpin,finalIterSpin,finalMoveSpin) do c.enabled=obj.finalRelax
            controlsReady=true;binding=false
        )
        fn save key value = (if controlsReady and not binding do (undo "Cyrus layer Relax" on setProperty owner key value;root.invalidateGroups()))
        on selected_spacingUI open do (root=this;controlsReady=false)
        on selected_spacingUI close do controlsReady=false
        on selected_spacingUI rolledUp state do (CyrusContainerPanel root).bindSection selected_spacingUI
        on relaxCheck changed value do (save #relaxEnabled value;bind owner)
        on spacingSpin changed value do save #relaxSpacing value
        on iterationsSpin changed value do save #relaxIterations value
        on strengthSpin changed value do save #relaxStrength (value/100.0)
        on boundaryRelaxCheck changed value do (save #finalRelax value;bind owner)
        on finalStrengthSpin changed value do save #finalStrength value
        on finalIterSpin changed value do save #finalIterations value
        on finalMoveSpin changed value do save #finalMaxMove value
    )

    rollout selected_separationUI "Cleanup - accepted layer" width:#cmdPanel category:180 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined,controlsReady=false,binding=false
        checkbox cleanCheck "Remove isolated plants" pos:[4,8] width:(selected_separationUI.width-8) tooltip:"Remove isolated plants after spacing. Protected instance edits remain."
        spinner neighborSpin "Neighbor distance:" type:#worldUnits range:[0.001,1e9,100] pos:[4,36] width:(selected_separationUI.width-8) fieldWidth:82
        spinner minNeighborSpin "Minimum neighbors:" type:#integer range:[0,10000,2] pos:[4,64] width:(selected_separationUI.width-8) fieldWidth:82
        spinner minIslandSpin "Minimum island size:" type:#integer range:[0,100000,5] pos:[4,92] width:(selected_separationUI.width-8) fieldWidth:82
        checkbox planarCheck "XY neighborhoods (off = 3D)" pos:[4,128] width:(selected_separationUI.width-8)
        label helpInfo "Cleanup releases space before bounded refill. Spacing rules are in the selected-scope section." pos:[4,160] width:(selected_separationUI.width-8) height:54
        fn bind layer = (
            binding=true
            cleanCheck.checked=owner.finalCleanup;neighborSpin.value=owner.finalNeighborRadius;minNeighborSpin.value=owner.finalMinNeighbors;minIslandSpin.value=owner.finalMinIsland;planarCheck.checked=owner.cleanupPlanar
            for c in #(neighborSpin,minNeighborSpin,minIslandSpin,planarCheck) do c.enabled=owner.finalCleanup
            controlsReady=true;binding=false
        )
        fn save key value = (if controlsReady and not binding do (undo "Cyrus layer cleanup" on setProperty owner key value;root.invalidateGroups()))
        on selected_separationUI open do (root=this;controlsReady=false)
        on selected_separationUI close do controlsReady=false
        on selected_separationUI rolledUp state do (CyrusContainerPanel root).bindSection selected_separationUI
        on cleanCheck changed value do (save #finalCleanup value;bind owner)
        on neighborSpin changed value do save #finalNeighborRadius value
        on minNeighborSpin changed value do save #finalMinNeighbors value
        on minIslandSpin changed value do save #finalMinIsland value
        on planarCheck changed value do save #cleanupPlanar value
    )


    rollout selected_detailsUI "Statistics / Help" width:#cmdPanel category:190 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined,controlsReady=false
        label info "Statistics describe the last build." pos:[4,74] width:(selected_detailsUI.width-8) height:300
        button refreshButton "Read cached statistics" pos:[4,8] width:(selected_detailsUI.width-8) tooltip:"Read the existing calculation statistics without regenerating placements."
        button helpButton "Layer / display help" pos:[4,38] width:(selected_detailsUI.width-8) tooltip:"Explain settings ownership, display budgets, evaluation order and policy limits."
        fn bind layer = (
            local text="Last completed build\n"
            for leaf in root.layerSets owner do (
                local state=leaf.uiLayerStats(),stats=leaf.groupStats(),cache=leaf.cacheSnapshot(),index=findItem root.layerObjects leaf
                local status=CyrusUILayerState state (root.enabledLayer index) root.cyrusEnabled (root.visibleLayer index)
                text+="\n"+leaf.paintSetName+" | "+status[2]
                local eligible=CyrusUICount stats[1],removed=CyrusUICount stats[2]
                text+="\nRequested: "+(CyrusUICount cache[8])+" | Eligible: "+eligible
                text+="\nPlaced: "+(CyrusUICount state.placements)+" | Removed: "+removed
                text+="\nShown: "+(CyrusUICount state.previewCount)+" | "+(state.buildMs as string)+" ms"
                if stats[3]>0 do text+="\nManual conflicts: "+(CyrusUICount stats[3])
                (
                    local detail=leaf.procStatistics()
                    if detail[1].count==12 do (
                        text+="\nRejected layer / set / self: "+(detail[1][5] as string)+" / "+(detail[1][6] as string)+" / "+(detail[1][7] as string)
                        text+="\nCleanup: "+(detail[1][8] as string)+" | Shortfall: "+(detail[1][11] as string)
                        text+="\nEpoch: "+(detail[5] as string)+" | Rounds: "+(detail[2][1] as string)
                    )
                )
                if state.densityCapped do text+="\nDensity limited to 100,000 candidates."
                if state.errorText!="" do text+="\n"+state.errorText
            )
            info.text=text;info.height=amax 300 ((filterString text "\n").count*17+20);selected_detailsUI.height=info.height+86;controlsReady=true
        )
        on selected_detailsUI open do (root=this;controlsReady=false)
        on selected_detailsUI close do controlsReady=false
        on refreshButton pressed do bind owner
        on helpButton pressed do messageBox (info.text+"\n\nPaint sets own assets and independent stroke history. Population, area, transforms and cleanup belong to the layer. Enabled set weights divide the layer budget.\n\nPoint Cloud uses many samples per plant; Plant centres uses one. Preview budgets affect display. Hidden owners still affect collision and render; disabled owners do not. Manual shows the previous completed build until Update. Paint feedback shows coverage, not accepted instances.\n\n"+"Visible order decides ordinary winners. Self, sibling-set and layer-pair rules are independent. Radius factor x (A + B) + gap, in XY or 3D. Protected edits survive and report conflicts. Background coverage uses earlier siblings. Accepted target retries a bounded prefix. Relax moves candidates before Brush, edits and collisions; each set uses its layer recipe."+"\n\nBase cannot be removed separately; disable or erase it. Capacity: ten populations, including sets. A Point source is an accepted placeholder. Weighted Empty sources are supported in candidate-budget mode.") title:"Cyrus layer help"
        on selected_detailsUI rolledUp state do (CyrusContainerPanel root).bindSection selected_detailsUI
    )

    rollout selected_workflowUI "Workflow and ownership" width:#cmdPanel category:200 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined,controlsReady=false
        label steps "1. SETUP\nChoose receiving surfaces in Modify. Add layers in the order they should calculate.\n\n2. ASSETS\nChoose models for each paint set, or place model pivots inside a source rectangle. Move outside to park a model without losing its settings.\n\n3. POPULATION\nSet the layer count or density. Enabled paint-set weights share that population. Accepted target retries within explicit limits.\n\n4. PAINT\nEnable coverage, then paint on the receiving surface. Area limits apply to all sets in this layer. Use earlier sets as explicit background references.\n\n5. TRANSFORM + SPACING\nLayer transforms apply to every set. Set self-spacing, between-set rules and layer pairs separately. Earlier owners occupy space first.\n\n6. UPDATE + INSPECT\nManual keeps the last completed result until Update. Live publishes after edits. Hidden owners still calculate; disabled owners do not. Counts here describe cached results, not an estimate of available room." pos:[4,8] width:(selected_workflowUI.width-8) height:500
        label help "The editor stays on this Scatter when scene selection changes. Use the Layer and Paint set selectors to change ownership. Hover buttons and numeric fields for short explanations.\n\nPoint Cloud samples and viewport budgets affect display. They are not plant counts or a promise of presented FPS." pos:[4,516] width:(selected_workflowUI.width-8) height:120
        fn bind layer = (controlsReady=true)
        on selected_workflowUI open do (root=this;controlsReady=false)
        on selected_workflowUI close do controlsReady=false
        on selected_workflowUI rolledUp state do (CyrusContainerPanel root).bindSection selected_workflowUI
    )


    rollout diagnosticsUI "Diagnostics" width:#cmdPanel category:220 autoLayoutOnResize:true (
        local root=undefined,controlsReady=false
        button startButton "Start recording" pos:[8,8] width:(diagnosticsUI.width-16) tooltip:"Record engineering events in this Max process. Off by default; at most ten minutes, 4,096 events and 4 MiB."
        button stopButton "Stop" pos:[8,38] width:((diagnosticsUI.width-22)/2) tooltip:"Stop recording and retain the bounded history in memory."
        button saveButton "Save report..." pos:[diagnosticsUI.width/2+3,38] width:((diagnosticsUI.width-22)/2) tooltip:"Choose a local JSON file, stop recording and save its retained pages. No MCP or upload is required."
        button refreshButton "Read recording status" pos:[8,68] width:(diagnosticsUI.width-16) tooltip:"Read recorder state without evaluating the scene. Status has no polling timer."
        label statusInfo "Recording is off." pos:[8,98] width:(diagnosticsUI.width-16) height:74
        label scopeInfo "Records all Scatter setups in this Max process. Engineering events are not training data. Save reports explicitly; closing this panel keeps the session." pos:[8,178] width:(diagnosticsUI.width-16) height:84
        fn field page name = (
            local pattern="\""+name+"\":(\"[^\"]*\"|[0-9]+|true|false)"
            local match=(dotNetClass "System.Text.RegularExpressions.Regex").Match page pattern
            if not match.Success do throw ("Missing diagnostic field: "+name)
            match.Groups.Item[1].Value
        )
        fn refresh = (
            local page=cyrusDiagnosticSnapshot 0 0,active=cyrusDiagnosticActive(),session=field page "session_id"
            startButton.enabled=not active;stopButton.enabled=active;saveButton.enabled=session!="\"\""
            statusInfo.text=(if active then "Recording" else "Stopped / off")+" | "+(field page "retained")+" retained\nEvicted: "+(field page "evicted")+" | Lock drops: "+(field page "lock_drops")+"\nFailures: "+(field page "failures")+" | Truncated: "+(field page "truncated")+"\nUse Read recording status to refresh."
            controlsReady=true;true
        )
        fn startRecording = (
            local identifier=(dotNetClass "System.Guid").NewGuid(),session="trace_"+(identifier.ToString "N")
            cyrusDiagnosticStart session 4096 4194304 600000
            refresh();session
        )
        fn nativeIdentity = (
            local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(),pairs=#()
            local names=#("AminScatter.dlx","CyrusBrush.dlx","CyrusBrushStorage.dlh","CyrusScatterEdit.dlm")
            for i=0 to process.Modules.Count-1 do (
                local module=process.Modules.Item[i],name=filenameFromPath module.FileName
                if findItem names name>0 do (
                    local sha=(dotNetClass "System.Security.Cryptography.SHA256").Create(),hash
                    try(hash=sha.ComputeHash ((dotNetClass "System.IO.File").ReadAllBytes module.FileName))catch(sha.Dispose();throw())
                    sha.Dispose()
                    append pairs ("\""+name+"\":\""+(toLower (substituteString ((dotNetClass "System.BitConverter").ToString hash) "-" ""))+"\"")
                )
            )
            if pairs.count!=names.count do throw "Cannot identify the four loaded Cyrus native modules."
            local json="{"
            for i=1 to pairs.count do json+=(if i==1 then "" else ",")+pairs[i]
            json+"}"
        )
        fn failReport message = (throw message)
        fn saveReport path = (
            if path==undefined or path=="" do return false
            local initial=cyrusDiagnosticSnapshot 0 0,session=field initial "session_id"
            if session=="\"\"" do throw "Start a diagnostic recording first."
            cyrusDiagnosticStop()
            local identifier=(dotNetClass "System.Guid").NewGuid(),temporary=path+"."+(identifier.ToString "N")+".tmp",stream=undefined
            try (
                stream=dotNetObject "System.IO.StreamWriter" temporary false (dotNetObject "System.Text.UTF8Encoding" false)
                local header="{\"schema\":\"cyrus.diagnostic-bundle/1.0\",\"training_eligible\":false,\"development_version\":\""+root.uiVersion()+"\",\"script_payload_sha256\":\""+CyrusLoadedScriptFingerprint+"\",\"native_file_sha256\":"+(nativeIdentity())+",\"pages\":["
                stream.Write header
                local cursor=0L,pageCount=0,bytes=header.count,finished=false,last=undefined,retained=undefined
                while not finished do (
                    local page=cyrusDiagnosticSnapshot cursor 500
                    if field page "session_id"!=session or field page "active"!="false" do throw "Diagnostic session changed while saving."
                    if last==undefined then (last=field page "last_sequence";retained=field page "retained")
                    else if field page "last_sequence"!=last or field page "retained"!=retained do throw "Diagnostic history changed while saving."
                    pageCount+=1;bytes+=(dotNetClass "System.Text.Encoding").UTF8.GetByteCount page
                    if pageCount>33 or bytes>16777100 do throw "Diagnostic report exceeds its export limit."
                    if pageCount>1 do stream.Write ","
                    stream.Write page
                    local next=(field page "next_sequence") as integer64
                    finished=(field page "has_more")=="false"
                    if not finished and next<=cursor do throw "Diagnostic page did not advance."
                    cursor=next
                )
                stream.Write "]}";stream.Flush();stream.Close();stream=undefined
                local cleanupNote=""
                if (dotNetClass "System.IO.File").Exists path then (
                    local backup=temporary+".previous"
                    (dotNetClass "System.IO.File").Replace temporary path backup
                    try((dotNetClass "System.IO.File").Delete backup)catch(cleanupNote="\nThe previous report backup remains beside the saved file.")
                )
                else (dotNetClass "System.IO.File").Move temporary path
                refresh();statusInfo.text="Saved "+(pageCount as string)+" diagnostic pages locally.\nRecording stopped. Inspect page health for any dropped or evicted events."+cleanupNote
                true
            )catch(
                local primary=getCurrentException(),cleanupErrors=""
                try(if stream!=undefined do stream.Close())catch(cleanupErrors+="\nClosing temporary report: "+getCurrentException())
                try(if (dotNetClass "System.IO.File").Exists temporary do (dotNetClass "System.IO.File").Delete temporary)catch(cleanupErrors+="\nTemporary report remains at "+temporary+": "+getCurrentException())
                try(refresh())catch(cleanupErrors+="\nRefreshing diagnostic status: "+getCurrentException())
                failReport (primary+cleanupErrors)
            )
        )
        on diagnosticsUI open do (root=this;controlsReady=false)
        on diagnosticsUI close do controlsReady=false
        on diagnosticsUI rolledUp state do if diagnosticsUI.open do refresh()
        on startButton pressed do try(startRecording())catch(messageBox (getCurrentException()) title:"Cyrus diagnostics")
        on stopButton pressed do (cyrusDiagnosticStop();refresh())
        on saveButton pressed do try(
            local path=getSaveFileName caption:"Save Cyrus engineering report" types:"JSON report (*.json)|*.json|" filename:"Cyrus-diagnostics.json"
            saveReport path
        )catch(messageBox (getCurrentException()) title:"Cyrus diagnostics")
        on refreshButton pressed do refresh()
    )


    on update do (
        -- Max may continue loading after an update-handler exception. Keep a
        -- persisted denial so later redraw/output and re-save cannot qualify it.
        if version!=54 do procSchemaValid=false
        this.procAssertSchema()
        syncColors();markInputDirty()
    )
    on attachedToNode n do (n.renderable=false;n.wirecolor=red;timeOwnerRegistered=false;CyrusRegisterTimeOwner n)
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
                if (obj.viewportMode==1 and CyrusPointEnabled) or ((obj.viewportMode==2 or obj.viewportMode==3) and CyrusMeshEnabled) then (append caches cache;append styles #(obj.pointColorMode==1,obj.solidPointColor))
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
                if failed do CyrusPointLastError="Retained preview unavailable; using the CPU preview. Refresh preview to retry."
                if not failed do (CyrusPointPending=true;CyrusScheduleRelease())
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
try(CyrusPFTimer.Stop();CyrusPFTimer.Dispose())catch()
fn CyrusPFIR = (try(findItem #(2,3) (CoronaRenderer.getRenderType())>0)catch(false))
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
  format "%|%|%|" 0 CyrusPFRevision CyrusPFManualRevision to:s
  for n in objects where classof n.baseObject==AminScatterObject do (
   local r=n.baseObject
   if r.updateMode==2 and false do format "InputTime:%|" (r.publishedInputTime()) to:s
   format "Enabled:%|" r.cyrusEnabled to:s
   for key in #() do format "%:%|" key (getProperty r key) to:s
   for layer in r.layerObjects do format "Brush:%:%:%|" layer.paintEnabled layer.paintDensity (layer.paintKey()) to:s
   format "|Edit:%|" (CyrusEditStackKey r) to:s
   format "%|%|%|%|%|" n.handle n.isHidden r.autoRender r.layerEnabled r.updateMode to:s
   for obj in r.layerObjects do format "Analyzer enabled:%|" (not obj.disabledAnalyzerInput()) to:s
   (
    format "Procedural:%|" r.procEpoch to:s
    for plants in r.procPublishedSources do for src in plants where isValidNode src do format "%:%|" (getHandleByAnim src) (if src.material==undefined then 0 else getHandleByAnim src.material) to:s
   )
   if r.updateMode==2 and false do (
    format "%|" r.surfaceNodes to:s
    -- Signature polling must never synchronize parameters or invalidate preview.
    for obj in r.layerObjects do (
     format "InputTime:%|Texture:%|" (obj.publishedInputTime()) obj.procDensityRevision to:s
     format "DensityMap:%|" (if obj.densityMap==undefined then 0 else getHandleByAnim obj.densityMap) to:s
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
 CyrusDiagnosticEmit "bridge.build_requested" "renderer" "" 0 (if CyrusPFBusy then "busy" else "admitted")
 if CyrusPFBusy do return false
 CyrusPFClear();CyrusPFBusy=true;AminScatterRenderRedrawHeld=true
 local before=objects as array;local links=#()
 disableSceneRedraw()
 try (
  undo off (

   for owner in before where isValidNode owner and classof owner.baseObject==AminScatterObject and not owner.isHidden do (
    local root=owner.baseObject
    for entry in (root.layerEntries includeDisabled:true) do (
     local obj=entry[2];local enabled=root.cyrusEnabled and root.enabledLayer entry[1]
     if not enabled or obj.autoRender do for old in obj.bakedNodes where isValidNode old do (
      append AminScatterRenderRestore #(old,old.renderable);old.renderable=false
     )
     local sources=obj.outputSources()
     if enabled and obj.autoRender and sources.count>0 and (true or (obj.validSurfaces()).count>0) do (
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
  CyrusDiagnosticEmit "bridge.completed" "renderer" "" 0 "particle_count_verified"
 ) catch (
  local reason=getCurrentException();try(ParticleFlow.EndEdit())catch()
  CyrusPFNodes=for n in objects where findItem before n==0 collect n
  CyrusPFClear();CyrusPFLastError=reason
  CyrusDiagnosticEmit "bridge.failed" "renderer" "" 0 "inspect_local_error"
  format "Cyrus PFlow bridge: %\n" reason
 )
 enableSceneRedraw();AminScatterRenderRedrawHeld=false;CyrusPFBusy=false
 CyrusPFLastError==""
)
fn AminScatterRenderBegin = (
 CyrusDiagnosticEmit "render.pre" "host_callback" "" 0 (if CyrusPFBusy then "bridge_busy" else "setup_allowed")
 if not CyrusPFBusy do CyrusPointSync()
 CyrusPFRequestCheck()
 if not CyrusPFBusy do (CyrusPFProduction=true;if CyrusPFKey()!=CyrusPFSignature do if not CyrusPFBuild() do (CyrusPFProduction=false;throw CyrusPFLastError))
)
fn AminScatterRenderEnd = (CyrusDiagnosticEmit "render.post" "host_callback" "" 0 "restore";CyrusPFRequestCheck();CyrusPFProduction=false;if not CyrusPFBusy do CyrusPFRestoreBaked())
fn CyrusPFBeforeSceneChange = (
 CyrusPFResume=false;CyrusPFPhase=0;CyrusPFCheckPending=false;CyrusPFTimer.Stop()
 if CyrusPFIR() do (if not CyrusPFStopIR() do throw CyrusPFLastError)
 CyrusPFClear()
)
fn CyrusPFBeforeSave = (
 CyrusPFPhase=0;CyrusPFResume=CyrusPFIR();if CyrusPFResume do CyrusPFResumeMode=CoronaRenderer.getRenderType();CyrusPFRequestCheck()
 if CyrusPFResume do (if not CyrusPFStopIR() do throw CyrusPFLastError)
 CyrusPFClear()
)
fn CyrusPFTickImpl sender args = (
 try (
 if not CyrusPFBusy and not CyrusInteractionHeld() and (not CyrusPFProduction or CyrusPFIR()) do (
  local active=CyrusPFIR();if active do (CyrusPFProduction=false;CyrusPFResumeMode=CoronaRenderer.getRenderType())
  if CyrusPFPhase==1 then (
   if not active do (if CyrusPFBuild() then CyrusPFPhase=2 else (CyrusPFPhase=0;CyrusPFResume=false))
  ) else if CyrusPFPhase==2 then (
   for n in CyrusPFNodes where isValidNode n and classof n==PF_Source do n.updateParticles n currentTime
   CyrusPFPhase=0;CyrusPFResume=false;(local result=(if CyrusPFResumeMode==2 then (CyrusDiagnosticEmit "ir.start_requested" "renderer" "" 0 "bridge_docked";CoronaRenderer.startInteractiveDocked()) else (CyrusDiagnosticEmit "ir.start_requested" "renderer" "" 0 "bridge";CoronaRenderer.startInteractive()));if result!=0 do throw ("Corona IR start failed: "+result as string);result)
  ) else if active or CyrusPFResume then (
   if CyrusPFNodes.count==0 and not CyrusPFResume and (for n in objects where classof n.baseObject==AminScatterObject collect n).count==0 do return false
   if not CyrusPFCheckPending and not CyrusPFResume do return false
   local wanted=CyrusPFKey()
   if wanted!=CyrusPFSignature or CyrusPFResume then (
    if wanted!=CyrusPFPendingKey then (CyrusPFPendingKey=wanted;CyrusPFStableSince=timeStamp())
    else if abs(timeStamp()-CyrusPFStableSince)>=1000 do (
     CyrusPFPhase=1;CyrusPFPendingKey=""
     if active do (if not CyrusPFStopIR() do throw CyrusPFLastError)
    )
   ) else (CyrusPFPendingKey="";CyrusPFCheckPending=false)
  ) else (CyrusPFCheckPending=false;if CyrusPFNodes.count>0 do CyrusPFClear())
 )
 ) catch (CyrusPFLastError=getCurrentException();CyrusPFPhase=0;CyrusPFResume=false;CyrusPFCheckPending=false;if not CyrusPFIR() do CyrusPFClear();format "Cyrus IR update: %\n" CyrusPFLastError)
)
-- Corona start/stop may pump Windows messages; never re-enter this timer.
fn CyrusPFTick sender args = (
 if CyrusPFTicking do return false
 CyrusPFTicking=true
 CyrusPFTimer.Stop()
 try(CyrusPFTickImpl sender args)catch(CyrusPFLastError=getCurrentException();CyrusPFCheckPending=false;CyrusPFPhase=0;CyrusPFResume=false)
 CyrusPFTicking=false
 if CyrusPFCheckPending or CyrusPFPhase>0 or CyrusPFResume do CyrusPFTimer.Start()
)
callbacks.removeScripts id:#AminScatterAutoRender
callbacks.removeScripts id:#CyrusPFBridge
callbacks.addScript #preRender "AminScatterRenderBegin()" id:#AminScatterAutoRender
callbacks.addScript #postRender "AminScatterRenderEnd()" id:#AminScatterAutoRender
callbacks.addScript #systemPreReset "CyrusPFBeforeSceneChange()" id:#CyrusPFBridge
callbacks.addScript #filePreOpen "CyrusPFBeforeSceneChange()" id:#CyrusPFBridge
callbacks.addScript #filePreSave "CyrusPFBeforeSave()" id:#CyrusPFBridge
CyrusPFTimer=dotNetObject "System.Windows.Forms.Timer";CyrusPFTimer.Interval=750
dotNet.addEventHandler CyrusPFTimer "Tick" CyrusPFTick

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
    if event==#deleted do (CyrusPruneTimeOwners();CyrusContainerRefreshAll())
    CyrusDiagnosticEmit "input.received" "host_callback" "" 0 (event as string)
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
            if n.baseObject.containerNote event nodes do redraw=true
            for entry in (n.baseObject.layerEntries includeDisabled:true) do (
                if entry[2].procExternalChanged event nodes do redraw=true
            )
            if findItem nodes n>0 do (
                CyrusScheduleUI()
                if n.baseObject.updateMode==2 and (for leaf in n.baseObject.layerObjects where leaf.dirty collect leaf).count>0 do redraw=true
            )
        )
        if redraw do (
            if CyrusLiveBatchDepth>0 then CyrusLiveBatchRedraw=true
            else (CyrusLiveRedrawRequests+=1;CyrusViewportRedraw())
        )
    )
)
fn AminScatterLiveTime = (
    if AminScatterRenderRedrawHeld==true do return false
    local changed=false
    for node in CyrusTimeOwners where isValidNode node and not node.isHidden do (
        local root=node.baseObject
        if root.liveTimeChanged() do changed=true
    )
    if changed do CyrusViewportRedraw()
    changed
)
AminScatterNodeEvents=NodeEventCallback hideChanged:CyrusRenderNodeChanged materialStructured:CyrusRenderNodeChanged materialOtherEvent:CyrusRenderNodeChanged nameChanged:CyrusRenderNodeChanged mouseUp:true delay:150 callbackBegin:CyrusScatterLiveBatchBegin callbackEnd:CyrusScatterLiveBatchEnd added:AminScatterLiveChanged deleted:AminScatterLiveChanged geometryChanged:AminScatterLiveChanged topologyChanged:AminScatterLiveChanged mappingChanged:AminScatterLiveChanged modelStructured:AminScatterLiveChanged controllerOtherEvent:AminScatterLiveChanged controllerStructured:AminScatterLiveChanged linkChanged:AminScatterLiveChanged
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

try(CyrusReleaseTimer.Stop();CyrusReleaseTimer.Dispose())catch()
fn CyrusReleaseTick sender args = (
 CyrusReleaseTimer.Stop()
 if CyrusInteractionHeld() then (CyrusWasDragging=true;CyrusScheduleRelease())
 else if CyrusWasDragging or CyrusPointPending do (CyrusWasDragging=false;CyrusPointPending=false;CyrusViewportRedraw())
)
CyrusReleaseTimer=dotNetObject "System.Windows.Forms.Timer"
CyrusReleaseTimer.Interval=200
dotNet.addEventHandler CyrusReleaseTimer "Tick" CyrusReleaseTick

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
                if ((obj.viewportMode==1 and CyrusPointEnabled) or ((obj.viewportMode==2 or obj.viewportMode==3) and CyrusMeshEnabled)) and (obj.showPoints or obj.showCenters) and cache!=undefined do (
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
                if not cyrusRetainedPublish owner n caches styles do publishError="Retained preview unavailable; using the CPU preview. Refresh preview to retry."
            )
        )
        CyrusPointLastError=publishError
    )catch(CyrusPointLastError=getCurrentException())
    CyrusPointBusy=false
    true
)
fn CyrusViewportRedraw = (
    CyrusScheduleUI()
    CyrusPFRequestCheck()
    if not CyrusPointBusy do CyrusPointSync()
    redrawViews()
)
fn CyrusPointBeforeSave = (CyrusPointSuspended=true;CyrusPointClear())
fn CyrusPointAfterSave = (CyrusPointSuspended=false;(CyrusPointPending=true;CyrusScheduleRelease()))
fn CyrusPointBeforeScene = (CyrusPointSuspended=true;CyrusPointClear())
fn CyrusPointAfterScene = (CyrusPointSuspended=false;CyrusPointDeletedHandles=#();(CyrusPointPending=true;CyrusScheduleRelease()))
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
(CyrusPointPending=true;CyrusScheduleRelease())

CyrusScatterObject=AminScatterObject
-- Session scheduling observes only the active Brush. Idle viewport drawing
-- does not scan documents, pick meshes, replay strokes or upload buffers.
global CyrusBrushSessionRoot,CyrusBrushSessionLayer,CyrusBrushSessionRevision=0,CyrusBrushTimer,CyrusBrushBusy=false
global CyrusStartBrush,CyrusStopBrush,CyrusBrushTick
fn CyrusStopBrush = (
    if CyrusBrushTimer!=undefined do CyrusBrushTimer.Stop()
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
    cyrusBrushDisplay layer.paintDocument layer.paintView layer.paintColor
    cyrusBrushBegin layer.paintDocument
    CyrusBrushSessionRoot=root;CyrusBrushSessionLayer=layer;CyrusBrushSessionRevision=0
    cyrusBrushRefreshMask layer.paintDocument;redrawViews()
    CyrusBrushTimer.Start()
)
fn CyrusBrushTick sender args = (
    if CyrusBrushSessionLayer==undefined do (CyrusBrushTimer.Stop();return false)
    if CyrusBrushBusy do return false
    CyrusBrushBusy=true
    try (
        local layer=CyrusBrushSessionLayer,root=CyrusBrushSessionRoot,state=cyrusBrushStats layer.paintDocument
        if state[1]!=CyrusBrushSessionRevision do (
            cyrusBrushRefreshMask layer.paintDocument
            CyrusBrushSessionRevision=state[1]
            if state[6]==0 then (layer.checkPaintRevision();CyrusViewportRedraw()) else redrawViews()
            root.refreshBrushEditors history:(state[6]==0)
        )
        if state[5]==0 do (
            layer.checkPaintRevision()
            root.refreshBrushEditors()
            CyrusBrushSessionLayer=undefined;CyrusBrushSessionRoot=undefined
        )
    ) catch (
        local failure=getCurrentException()
        cyrusBrushStop();CyrusBrushSessionLayer=undefined;CyrusBrushSessionRoot=undefined
        format "Cyrus Brush: %\n" failure
    )
    CyrusBrushBusy=false
    if CyrusBrushSessionLayer==undefined do CyrusBrushTimer.Stop()
)
try(CyrusBrushTimer.Stop();CyrusBrushTimer.Dispose())catch()
CyrusBrushTimer=dotNetObject "System.Windows.Forms.Timer"
CyrusBrushTimer.Interval=33
dotNet.addEventHandler CyrusBrushTimer "Tick" CyrusBrushTick
callbacks.removeScripts id:#CyrusBrushSession
callbacks.addScript #filePreOpen "CyrusStopBrush()" id:#CyrusBrushSession
callbacks.addScript #systemPreReset "CyrusStopBrush()" id:#CyrusBrushSession

global CyrusBrushViewportDraw
try(unregisterRedrawViewsCallback CyrusBrushViewportDraw)catch()
fn CyrusBrushViewportDraw = (cyrusBrushDrawCurrent())
registerRedrawViewsCallback CyrusBrushViewportDraw

-- Texture edits propagate through submaps. Watchers are transient and installed
-- lazily on a bound map after load/Undo; navigation only reads the revision.
global CyrusDensityMapChanged
fn CyrusDensityMapChanged texture = (
    CyrusDiagnosticEmit "density.changed" "host_callback" "" 0 "parameter_notification"
    if texture==undefined do return false
    local changed=false
    for node in objects where classof node.baseObject==AminScatterObject do (
        for leaf in (#(node.baseObject)+node.baseObject.layerObjects) where leaf.procDensityMap==texture do (
            leaf.procDensityRevision+=1;leaf.markInputDirty();changed=true
        )
    )
    if changed do ((CyrusPointPending=true;CyrusScheduleRelease());CyrusScheduleUI())
)

callbacks.removeScripts id:#CyrusInputTimeOwners
callbacks.addScript #filePostOpen "CyrusResetTimeOwners()" id:#CyrusInputTimeOwners persistent:false
callbacks.addScript #filePostMerge "CyrusResetTimeOwners()" id:#CyrusInputTimeOwners persistent:false
callbacks.addScript #systemPostReset "CyrusResetTimeOwners()" id:#CyrusInputTimeOwners persistent:false
callbacks.addScript #sceneUndo "CyrusResetTimeOwners()" id:#CyrusInputTimeOwners persistent:false
callbacks.addScript #sceneRedo "CyrusResetTimeOwners()" id:#CyrusInputTimeOwners persistent:false
callbacks.addScript #nodeCreated "CyrusRegisterTimeOwner (callbacks.notificationParam())" id:#CyrusInputTimeOwners persistent:false
CyrusResetTimeOwners()
