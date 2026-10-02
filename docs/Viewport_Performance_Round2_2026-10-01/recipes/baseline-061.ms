global CyrusPerfTraceBegin,CyrusPerfTraceEnd,CyrusPerfTraceInput
global CyrusUISize,CyrusUIBuildView
fn CyrusUISize n depth view:CyrusUIBuildView = (local w=if view==undefined then 162 else amax 140 (view.width-16-depth*16);floor(n*w/162.0+0.5))
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
                redrawViews()
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
AminScatterLayerFields=#(#streetTrimStart,#streetTrimEnd,#centerStreetOffset,#areaAnalyzer,#areaUseLine,#areaLineWidth,#areaLineCaps,#areaUsePoints,#areaPointRadius,#wholeScaleMin,#wholeScaleMax,#fallScaleGraph,#fallDensityGraph,#areaFallConfigs,#areaFallScaleGraphs,#areaFallDensityGraphs,#fallAnalyzer,#fallDelete,#fallDeleteWidth,#fallScale,#fallScaleWidth,#fallScaleCurve,#fallDensity,#fallDensityWidth,#fallDensityCurve,#edgeRotX,#edgeRotY,#edgeRotZ,#edgeKeepCorners,#edgeCornerAngle,#edgeCornerCount,#edgeFaceOut,#edgeCornerRadius,#edgeOffsets,#edgeAlong,#edgeAcross,#borderFaceOut,#streetFaceOut,#borderCornerRadius,#streetCornerRadius,#sourceForwardAxes,#finalCleanup,#finalNeighborRadius,#finalMinNeighbors,#finalMinIsland,#finalRelax,#finalStrength,#finalIterations,#finalMaxMove,#overlapSourceRadius,#sourceRadii,#sourceFollowScale,#sourceShowRadius,#streetStraight,#sourcePoint,#sourceEmpty,#overlapEnabled,#overlapRadius,#overlapGap,#overlapPlanar,#overlapBlockers,#sourceZOffsets,#sourceScales,#sourceWeights,#showCenters,#collisionEnabled,#collisionRadius,#relaxEnabled,#relaxSpacing,#relaxIterations,#relaxStrength,#sources,#bakedNodes,#amount,#randomSeed,#scaleMinimum,#scaleMaximum,#tiltDegrees,#yawMinimum,#yawMaximum,#movementRange,#alignNormal,#showPoints,#pointsPerPlant,#updateMode,#populationMode,#plantsPerM2,#advancedAxes,#projectMove,#rotXMin,#rotXMax,#rotYMin,#rotYMax,#rotZMin,#rotZMax,#sclXMin,#sclXMax,#sclYMin,#sclYMax,#sclZMin,#sclZMax,#movXMin,#movXMax,#movYMin,#movYMax,#movZMin,#movZMax,#distributionMode,#clusterCount,#clusterRadius,#densityMap,#invertDensity,#diversityMode,#diversitySize,#diversitySeed,#roughness,#blurryEdge,#diversityNoise,#autoRender,#previewBudget,#pointColorMode,#solidPointColor,#areaNodes,#areaModes,#sourceColors,#patternLines,#patternWidths,#patternGroups,#patternRestGroup)
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
                    setProperty destination key (getProperty origin key)
                )
            )
        )
        destination.setLayerTransfer false
    ) catch(destination.setLayerTransfer false;throw())
)
fn AminScatterRefreshLayerPanels obj reopen:true = (if obj.mainUI.controlsReady do obj.mainUI.rebuild())
global CyrusUIBuildTarget,CyrusUIBuildView,CyrusUIBuildIndex
global CyrusMakeLayer, CyrusMakeManager
global CyrusMake_updateUI
fn CyrusMake_updateUI target view = (
    CyrusUIBuildView=view
    rollout updateUI "Update" width:(CyrusUISize 162 0) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on updateUI close do controlsReady=false

        radiobuttons updateRadio "Viewport update" labels:#("Manual","Real-time") columns:1 pos:[(CyrusUISize 8 0),8] width:(CyrusUISize 146 0)
        button updateNow "Update now" pos:[(CyrusUISize 8 0),78] width:(CyrusUISize 146 0)
        label updateHint "Updates after a brief pause." pos:[(CyrusUISize 8 0),110] width:(CyrusUISize 146 0)
        fn syncControls = (updateRadio.state=obj.updateMode;)
        on updateNow pressed do (obj.refreshAll();redrawViews())

        on updateRadio changed v do (obj.updateMode=v;obj.dirty=true;syncControls();redrawViews())
        on updateUI rolledUp state do parentView.layoutPanels()
        on updateUI open do (updateRadio.state=obj.updateMode;controlsReady=true;)
    )
updateUI.obj=target;updateUI.parentView=view;updateUI
)
global CyrusMake_surfaceUI
fn CyrusMake_surfaceUI target view = (
    CyrusUIBuildView=view
    rollout surfaceUI "Surface Scatter" width:(CyrusUISize 162 0) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on surfaceUI close do controlsReady=false
        multiListBox surfaceList "Surfaces (Ctrl/Shift)" items:#() pos:[(CyrusUISize 8 0),8] width:(CyrusUISize 146 0) height:6
        button addSurfaceScene "Select From Scene..." pos:[(CyrusUISize 8 0),134] width:(CyrusUISize 146 0)
        pickbutton pickSurface "Add: pick surface" filter:AminScatterSourceFilter pos:[(CyrusUISize 8 0),160] width:(CyrusUISize 146 0)
        button removeSurface "Remove selected rows" pos:[(CyrusUISize 8 0),186] width:(CyrusUISize 146 0)
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

        on pickSurface picked n do (addSurface n;updateSurfaces();redrawViews())
        on addSurfaceScene pressed do (
            local nodes=selectByName title:"Cyrus Scatter - Surfaces" buttonText:"Add" filter:AminScatterSourceFilter single:false
            if nodes!=undefined do for n in nodes do addSurface n
            updateSurfaces();redrawViews()
        )
        on removeSurface pressed do (
            local rows=surfaceList.selection as array
            undo "Cyrus Scatter remove surfaces" on (for i=rows.count to 1 by -1 do deleteItem obj.surfaceNodes rows[i])
            obj.surface=undefined;surfaceList.selection=#{};obj.dirty=true;updateSurfaces();redrawViews()
        )

        on surfaceUI rolledUp state do parentView.layoutPanels()
        on surfaceUI open do (controlsReady=true;updateSurfaces())
    )
surfaceUI.obj=target;surfaceUI.parentView=view;surfaceUI
)
global CyrusMake_previewUI
fn CyrusMake_previewUI target view = (
    CyrusUIBuildView=view
    rollout previewUI "Viewport and Render" width:(CyrusUISize 162 0) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on previewUI close do controlsReady=false
        checkbox previewCheck "Show preview" pos:[(CyrusUISize 8 0),8] width:(CyrusUISize 146 0)
        dropdownlist displayModeDrop "Display mode" items:#("Point Cloud","Proxy","Mesh") pos:[(CyrusUISize 8 0),34] width:(CyrusUISize 146 0)
        dropdownlist proxyShapeDrop "Proxy shape" items:#("Box","Sphere","Pyramid") pos:[(CyrusUISize 8 0),82] width:(CyrusUISize 146 0)
        spinner instancesLimitSpin "Instances/layer:" range:[1,100000,2000] type:#integer fieldWidth:(CyrusUISize 58 0) pos:[(CyrusUISize 8 0),138] width:(CyrusUISize 146 0)
        spinner faceLimitSpin "Faces/layer:" range:[12,20000000,2000000] type:#integer fieldWidth:(CyrusUISize 58 0) pos:[(CyrusUISize 8 0),166] width:(CyrusUISize 146 0)
        radiobuttons pointColorRadio "Preview color" labels:#("Solid Color","Source Group Colors") columns:1 pos:[(CyrusUISize 8 0),194] width:(CyrusUISize 146 0)
        colorpicker solidColorPicker "Solid: " color:(color 100 220 120) pos:[(CyrusUISize 8 0),264] width:(CyrusUISize 146 0)
        spinner budgetSpin "Point limit: " range:[1000,500000,20000] type:#integer fieldWidth:(CyrusUISize 58 0) width:(CyrusUISize 146 0) pos:[(CyrusUISize 8 0),292]
        spinner pointsSpin "Points/plant: " range:[10,10000,80] type:#integer fieldWidth:(CyrusUISize 58 0) width:(CyrusUISize 146 0) pos:[(CyrusUISize 8 0),318]
        spinner radiusLimitSpin "Radii / layer:" range:[0,1000000,2000] type:#integer fieldWidth:(CyrusUISize 58 0) width:(CyrusUISize 146 0) pos:[(CyrusUISize 8 0),344]
        checkbox radiusAllCheck "Show All Radii" pos:[(CyrusUISize 8 0),370] width:(CyrusUISize 146 0)
        label radiusHint "Display only; 0 = hide radii" pos:[(CyrusUISize 8 0),396] width:(CyrusUISize 146 0)
        spinner iconSpin "Icon size: " range:[0.1,10000,10] type:#worldUnits fieldWidth:(CyrusUISize 58 0) width:(CyrusUISize 146 0) pos:[(CyrusUISize 8 0),422]
        button refreshButton "Refresh preview" pos:[(CyrusUISize 8 0),452] width:(CyrusUISize 146 0)
        checkbox autoRenderCheck "Automatic final render" pos:[(CyrusUISize 8 0),482] width:(CyrusUISize 146 0)
        button clearBakedButton "Remove old baked output" pos:[(CyrusUISize 8 0),512] width:(CyrusUISize 146 0)
        label status "Ready" pos:[(CyrusUISize 8 0),572] width:(CyrusUISize 146 0) height:60

        fn syncDisplay = (
            displayModeDrop.selection=obj.viewportMode;proxyShapeDrop.selection=obj.proxyShape
            proxyShapeDrop.visible=obj.viewportMode==2
            instancesLimitSpin.visible=obj.viewportMode!=1;faceLimitSpin.visible=obj.viewportMode!=1
            instancesLimitSpin.value=obj.viewportInstances;faceLimitSpin.value=obj.viewportFaces
            budgetSpin.enabled=obj.viewportMode==1;pointsSpin.enabled=obj.viewportMode==1
        )
        fn syncControls = (syncDisplay();radiusLimitSpin.value=obj.radiusDisplayLimit;radiusAllCheck.checked=obj.radiusDisplayAll;radiusLimitSpin.enabled=not obj.radiusDisplayAll;autoRenderCheck.checked=obj.autoRender;budgetSpin.value=obj.previewBudget;pointColorRadio.state=obj.pointColorMode;solidColorPicker.color=obj.solidPointColor;)
        on radiusLimitSpin changed v do (obj.radiusDisplayLimit=v;obj.refreshAll();syncControls();redrawViews())
        on radiusAllCheck changed v do (obj.radiusDisplayAll=v;obj.refreshAll();syncControls();redrawViews())
        on displayModeDrop selected v do (obj.viewportMode=v;obj.refreshDisplay();syncControls();status.text=obj.allStatus();redrawViews())
        on proxyShapeDrop selected v do (obj.proxyShape=v;obj.refreshDisplay();syncControls();status.text=obj.allStatus();redrawViews())
        on instancesLimitSpin changed v do (obj.viewportInstances=v;obj.refreshDisplay();syncControls();status.text=obj.allStatus();redrawViews())
        on faceLimitSpin changed v do (obj.viewportFaces=v;obj.refreshDisplay();syncControls();status.text=obj.allStatus();redrawViews())
        on previewCheck changed v do (obj.showPoints=v;redrawViews())
        on pointsSpin changed v do (obj.pointsPerPlant=v;obj.dirty=true;syncControls();redrawViews())
        on iconSpin changed v do obj.iconSize=v
        on refreshButton pressed do (obj.refreshAll();status.text=obj.allStatus();redrawViews())
        on clearBakedButton pressed do obj.clearAllBaked()

        on autoRenderCheck changed v do (obj.autoRender=v;obj.dirty=true;syncControls();redrawViews())
        on budgetSpin changed v do (obj.previewBudget=v;obj.dirty=true;syncControls();redrawViews())
        on pointColorRadio changed v do (obj.pointColorMode=v;obj.dirty=true;syncControls();redrawViews())
        on solidColorPicker changed v do (obj.solidPointColor=v;obj.dirty=true;syncControls();redrawViews())
        on previewUI rolledUp state do parentView.layoutPanels()
        on previewUI open do (syncDisplay();radiusLimitSpin.value=obj.radiusDisplayLimit;radiusAllCheck.checked=obj.radiusDisplayAll;radiusLimitSpin.enabled=not obj.radiusDisplayAll;autoRenderCheck.checked=obj.autoRender;budgetSpin.value=obj.previewBudget;pointColorRadio.state=obj.pointColorMode;solidColorPicker.color=obj.solidPointColor;controlsReady=true;(previewCheck.checked=obj.showPoints;pointsSpin.value=obj.pointsPerPlant;iconSpin.value=obj.iconSize))
    )
previewUI.obj=target;previewUI.parentView=view;previewUI
)
global CyrusMake_sourceUI
fn CyrusMake_sourceUI target view = (
    CyrusUIBuildView=view
    rollout sourceUI "Source Object" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on sourceUI close do controlsReady=false
        local groupPalette=#()
        local loadingColor=false
        local focusedRow=0
        multiListBox plantList "Sources (Ctrl/Shift)" items:#() pos:[(CyrusUISize 8 1),8] height:6 width:(CyrusUISize 146 1)
        button selectFromScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton addPlant "Add: pick in viewport" pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button addSelected "Add selected objects" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        button removePlant "Remove selected rows" pos:[(CyrusUISize 8 1),212] width:(CyrusUISize 146 1)
        button selectPlant "Select sources" pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        button addPoint "Add Point" pos:[(CyrusUISize 8 1),264] width:(CyrusUISize 146 1)
        button addEmpty "Add Empty" pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        pickbutton replacePoint "Replace Point: pick object" filter:AminScatterSourceFilter pos:[(CyrusUISize 8 1),316] width:(CyrusUISize 146 1)
        label groupHeading "Cluster color group" pos:[(CyrusUISize 8 1),348] width:(CyrusUISize 146 1)
        dropdownlist existingGroups "Reuse a group" items:#() pos:[(CyrusUISize 8 1),371] width:(CyrusUISize 146 1)
        colorpicker groupColor "Color: " color:(color 100 220 120) pos:[(CyrusUISize 8 1),419] width:(CyrusUISize 146 1) modal:true notifyAfterAccept:true
        button applyColor "Apply to selected rows" pos:[(CyrusUISize 8 1),446] width:(CyrusUISize 146 1)
        label colorHelp "OK saves the selected color." pos:[(CyrusUISize 8 1),476] width:(CyrusUISize 146 1)
        spinner weightSpin "Weight: " range:[0,1,1] scale:0.01 pos:[(CyrusUISize 8 1),504] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        label weightHelp "0 = off; relative share" pos:[(CyrusUISize 8 1),530] width:(CyrusUISize 146 1)
        spinner sourceZSpin "Z Offset: " range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),556] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        spinner sourceScaleSpin "Scale: " range:[0,10000,1] scale:0.01 pos:[(CyrusUISize 8 1),582] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        label sourceTransformHelp "Scale: 1 = original" pos:[(CyrusUISize 8 1),608] width:(CyrusUISize 146 1)
        spinner radiusSourceSpin "Collision radius:" type:#worldunits range:[0,1e9,0] pos:[(CyrusUISize 8 1),686] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        checkbox followRadiusCheck "Follow Scale" pos:[(CyrusUISize 8 1),712] width:(CyrusUISize 146 1)
        checkbox showRadiusCheck "Show Radius" pos:[(CyrusUISize 8 1),738] width:(CyrusUISize 146 1)
        dropdownlist forwardAxis "Forward axis:" items:#("+Y","-Y","+X","-X") pos:[(CyrusUISize 8 1),634] width:(CyrusUISize 146 1)
        fn colorLabel c = ("#"+(formattedPrint (obj.colorKey c) format:"06X"))
        fn updateList = (
            local selectedRows=plantList.selection
            if selectedRows.numberSet==0 and obj.sources.count>0 do selectedRows=#{1}
            obj.syncColors()
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
            showSelectedColor();redrawViews()
        )
        on addPoint pressed do (
            local i=obj.addPointSource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on replacePoint picked n do (
            local rows=plantList.selection as array
            if rows.count!=1 then messageBox "Select one Point row to replace." title:"Cyrus Scatter"
            else if not (obj.replacePointSource rows[1] n) do messageBox "Select a Point row and an object that is not already in this source list." title:"Cyrus Scatter"
            replacePoint.text="Replace Point: pick object";updateList();showSelectedColor();redrawViews()
        )
        on addEmpty pressed do (
            local i=obj.addEmptySource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on radiusSourceSpin changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v;redrawViews())
        on followRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:2;redrawViews())
        on showRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:3;redrawViews())
        on forwardAxis selected v do if not loadingColor do (obj.assignSourceForward plantList.selection v;redrawViews())
        on sourceZSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v;redrawViews())
        on sourceScaleSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v scaling:true;redrawViews())
        on weightSpin changed v do if not loadingColor do (obj.assignWeight plantList.selection v;updateList();redrawViews())
        on plantList selected i do (
            if i>0 and plantList.selection[i] do focusedRow=i
        )
        on plantList selectionEnd do showSelectedColor()
        on existingGroups selected i do (
            if i>0 and i<=groupPalette.count do (
                local c=groupPalette[i]
                loadingColor=true;groupColor.color=c;loadingColor=false
                obj.assignGroup plantList.selection c;updateList();redrawViews()
            )
        )
        on groupColor changed c do (
            if not loadingColor and plantList.selection.numberSet>0 do (
                obj.assignGroup plantList.selection c
                updateList();redrawViews()
            )
        )
        on applyColor pressed do (
            obj.assignGroup plantList.selection groupColor.color
            updateList();redrawViews()
        )
        on selectFromScene pressed do (
            local picked=selectByName title:"Cyrus Scatter - Select From Scene" buttonText:"Add" filter:AminScatterSourceFilter single:false
            addSources picked
        )
        on addPlant picked n do addSources #(n)
        on addSelected pressed do addSources (selection as array)
        on removePlant pressed do (
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
            plantList.selection=#{};obj.dirty=true;updateList();redrawViews()
        )
        on selectPlant pressed do (
            local nodes=for i in plantList.selection where i<=obj.sources.count and isValidNode obj.sources[i] collect obj.sources[i]
            if nodes.count>0 do select nodes
        )

        on sourceUI rolledUp state do parentView.layoutPanels()
        on sourceUI open do (controlsReady=true;(updateList();showSelectedColor()))
    )
sourceUI.obj=target;sourceUI.parentView=view;sourceUI
)
global CyrusMake_distributionUI
fn CyrusMake_distributionUI target view = (
    CyrusUIBuildView=view
    rollout distributionUI "Point Generation" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on distributionUI close do controlsReady=false
        radiobuttons modeRadio "Method" labels:#("Random","Texture Density") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        radiobuttons populationRadio "Population" labels:#("Count","Plants per m2") columns:1 pos:[(CyrusUISize 8 1),78] width:(CyrusUISize 146 1)
        checkbox showCenterCheck "Show Point" pos:[(CyrusUISize 8 1),148] width:(CyrusUISize 146 1)
        on showCenterCheck changed v do (obj.showCenters=v;redrawViews())
        spinner countSpin "Count: " range:[1,100000,200] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),174]
        spinner densitySpin "Per m2: " range:[0,1000000,100] fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),200]
        spinner seedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),226]
        label densityHeading "Texture density" pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)
        mapbutton densityButton "Choose density map" pos:[(CyrusUISize 8 1),284] width:(CyrusUISize 146 1)
        checkbox invertCheck "Invert density" pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        label uvHint "UV channel 1; 0..1" pos:[(CyrusUISize 8 1),338] width:(CyrusUISize 146 1)
        label mapHint "White: dense / Black: empty" pos:[(CyrusUISize 8 1),360] width:(CyrusUISize 146 1)

        fn syncControls = (populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;)
        on modeRadio changed v do (obj.distributionMode=if v==2 then 3 else 1;obj.dirty=true;syncControls();redrawViews())
        on countSpin changed v do (obj.amount=v;obj.dirty=true;syncControls();redrawViews())
        on seedSpin changed v do (obj.randomSeed=v;obj.dirty=true;syncControls();redrawViews())

        on populationRadio changed v do (obj.populationMode=v;obj.dirty=true;syncControls();redrawViews())
        on densitySpin changed v do (obj.plantsPerM2=v;obj.dirty=true;syncControls();redrawViews())
        on densityButton picked v do (obj.densityMap=v;obj.dirty=true;syncControls();redrawViews())
        on invertCheck changed v do (obj.invertDensity=v;obj.dirty=true;syncControls();redrawViews())
        on distributionUI rolledUp state do parentView.layoutPanels()
        on distributionUI open do (showCenterCheck.checked=obj.showCenters;populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;controlsReady=true;(countSpin.value=obj.amount;seedSpin.value=obj.randomSeed;modeRadio.state=if obj.distributionMode==3 then 2 else 1))
    )
distributionUI.obj=target;distributionUI.parentView=view;distributionUI
)
global CyrusMake_areaUI
fn CyrusMake_areaUI target view = (
    CyrusUIBuildView=view
    rollout areaUI "Area" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on areaUI close do controlsReady=false
        multiListBox areaList "Closed lines / shapes" items:#() pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1) height:6
        button addAreaScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton pickArea "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button removeArea "Remove selected rows" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        radiobuttons areaMode "Selected area mode" labels:#("Include","Exclude") columns:1 pos:[(CyrusUISize 8 1),220] width:(CyrusUISize 146 1)
        label areaHint "Exclude overrides Include." pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        label projectionHint "Top / world XY projection." pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        button refreshAreas "Refresh areas / preview" pos:[(CyrusUISize 8 1),340] width:(CyrusUISize 146 1)
        local loadingAnalyzerArea=false
        label aaTitle "Surface Analyzer Area" pos:[(CyrusUISize 8 1),378] width:(CyrusUISize 146 1)
        pickbutton aaPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),404] width:(CyrusUISize 146 1)
        button aaRemove "Remove Area Analyzer" pos:[(CyrusUISize 8 1),432] width:(CyrusUISize 146 1)
        checkbox aaLine "Center Line" pos:[(CyrusUISize 8 1),464] width:(CyrusUISize 146 1)
        spinner aaWidth "Full width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),490] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        dropdownlist aaCaps "Line ends" items:#("Flat","Round") selection:1 pos:[(CyrusUISize 8 1),518] width:(CyrusUISize 146 1)
        spinner aaStreetOffset "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),572] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox aaPoints "Points" pos:[(CyrusUISize 8 1),604] width:(CyrusUISize 146 1)
        spinner aaRadius "Radius:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),630] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label aaHelp "XY mask. Both enabled = union. Works with Random / Clusters." pos:[(CyrusUISize 8 1),660] width:(CyrusUISize 146 1) height:40
        fn syncAnalyzerArea = (
            loadingAnalyzerArea=true
            aaPick.text=if isValidNode obj.areaAnalyzer then obj.areaAnalyzer.name else "Pick Surface Analyzer"
            aaLine.checked=obj.areaUseLine;aaPoints.checked=obj.areaUsePoints
            aaStreetOffset.value=obj.centerStreetOffset;aaStreetOffset.enabled=obj.areaUseLine
            aaWidth.value=obj.areaLineWidth;aaRadius.value=obj.areaPointRadius;aaCaps.selection=obj.areaLineCaps
            aaWidth.enabled=obj.areaUseLine;aaCaps.enabled=obj.areaUseLine;aaRadius.enabled=obj.areaUsePoints
            loadingAnalyzerArea=false
        )
        on aaPick picked n do (obj.areaAnalyzer=n;syncAnalyzerArea();redrawViews())
        on aaRemove pressed do (obj.areaUseLine=false;obj.areaUsePoints=false;obj.areaAnalyzer=undefined;syncAnalyzerArea();redrawViews())
        on aaLine changed v do if not loadingAnalyzerArea do (obj.areaUseLine=v;syncAnalyzerArea();redrawViews())
        on aaPoints changed v do if not loadingAnalyzerArea do (obj.areaUsePoints=v;syncAnalyzerArea();redrawViews())
        on aaStreetOffset changed v do if not loadingAnalyzerArea do (obj.centerStreetOffset=v;redrawViews())
        on aaWidth changed v do if not loadingAnalyzerArea do (obj.areaLineWidth=v;redrawViews())
        on aaRadius changed v do if not loadingAnalyzerArea do (obj.areaPointRadius=v;redrawViews())
        on aaCaps selected v do if not loadingAnalyzerArea do (obj.areaLineCaps=v;redrawViews())

        local loadingFall=false
        dropdownlist fallTarget "Edge falloff target" items:#("Analyzer Boundary","Selected Area line") selection:1 pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        pickbutton fallPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1)
        button fallRemove "Remove Analyzer" pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1)
        label fallTargetName "" pos:[(CyrusUISize 8 1),818] width:(CyrusUISize 146 1) height:40
        checkbox fallDeleteCheck "Delete edge band" pos:[(CyrusUISize 8 1),860] width:(CyrusUISize 146 1)
        spinner fallDeleteSpin "Delete width:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox fallScaleCheck "Scale ramp" pos:[(CyrusUISize 8 1),918] width:(CyrusUISize 146 1)
        spinner fallScaleSpin "Scale width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),944] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallScaleEdit "Edit Scale Graph..." pos:[(CyrusUISize 8 1),974] width:(CyrusUISize 146 1)
        checkbox fallDensityCheck "Density ramp" pos:[(CyrusUISize 8 1),1010] width:(CyrusUISize 146 1)
        spinner fallDensitySpin "Density width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),1036] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallDensityEdit "Edit Density Graph..." pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1)
        label fallHelp "Ramps start after delete band. Each Area line has its own settings." pos:[(CyrusUISize 8 1),1104] width:(CyrusUISize 146 1) height:56
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
                if fallTarget.selection==1 or isValidNode n do (local cfg=obj.getFallConfig n;cfg[index]=value;obj.setFallConfig n cfg;redrawViews())
            )
        )
        on fallTarget selected v do syncFalloff()
        on fallPick picked n do (if CyrusAnalyzerFilter n do obj.fallAnalyzer=n;syncFalloff();redrawViews())
        on fallRemove pressed do (obj.fallAnalyzer=undefined;obj.fallDelete=false;obj.fallScale=false;obj.fallDensity=false;syncFalloff();redrawViews())
        on fallDeleteCheck changed v do setFallValue 1 v
        on fallDeleteSpin changed v do setFallValue 2 v
        on fallScaleCheck changed v do setFallValue 3 v
        on fallScaleSpin changed v do setFallValue 4 v
        on fallDensityCheck changed v do setFallValue 6 v
        on fallDensitySpin changed v do setFallValue 7 v
        on fallScaleEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) false
        on fallDensityEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) true

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

        on pickArea picked n do (addArea n;updateAreas();redrawViews())
        on addAreaScene pressed do (
            local nodes=selectByName title:"Cyrus Scatter - Closed Areas" buttonText:"Add" filter:AminScatterAreaFilter single:false
            if nodes!=undefined do for n in nodes do addArea n
            updateAreas();redrawViews()
        )
        on areaList selectionEnd do (
            if areaList.selection.numberSet==1 do fallTarget.selection=2
            syncFalloff()
            if areaList.selection.numberSet>0 do areaMode.state=obj.areaModes[(areaList.selection as array)[1]]
        )
        on areaMode changed mode do (
            undo "Cyrus Scatter area mode" on (for i in areaList.selection do obj.areaModes[i]=mode)
            obj.dirty=true;updateAreas();redrawViews()
        )
        on removeArea pressed do (
            if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()
            local rows=areaList.selection as array
            undo "Cyrus Scatter remove areas" on (
                obj.ensureAreaFalloffs()
                for i=rows.count to 1 by -1 do (deleteItem obj.areaNodes rows[i];deleteItem obj.areaModes rows[i];deleteItem obj.areaFallConfigs rows[i];deleteItem obj.areaFallScaleGraphs rows[i];deleteItem obj.areaFallDensityGraphs rows[i])
            )
            areaList.selection=#{};obj.dirty=true;updateAreas();redrawViews()
        )
        on refreshAreas pressed do (obj.dirty=true;obj.refreshPreview();redrawViews())

        on areaUI rolledUp state do parentView.layoutPanels()
        on areaUI open do (syncAnalyzerArea();syncFalloff();controlsReady=true;updateAreas())
    )
areaUI.obj=target;areaUI.parentView=view;areaUI
)
global CyrusMake_diversityUI
fn CyrusMake_diversityUI target view = (
    CyrusUIBuildView=view
    rollout diversityUI "Diversity / Colors" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false,strokeExpandedHeight=0
        on diversityUI close do controlsReady=false
        radiobuttons diversityRadio "Source assignment" labels:#("Random","Clusters","Line Pattern","Analyze Surface") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner sizeSpin "Size: " range:[0.01,100000,10] type:#worldUnits fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),104]
        spinner divSeedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),130]
        spinner roughSpin "Roughness %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),156]
        spinner blurSpin "Blur edge %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),182]
        spinner noiseSpin "Noise %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),208]
        label groupHint "Uses source group colors." pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        label fixedHint "Point positions stay fixed." pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)



    
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),118] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),218] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),250] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),346] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),346] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),372] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),406] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),434] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),506] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),618] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),644] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),676] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),870] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),898] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),940] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),968] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),996] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),1024] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1094] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1122] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),874] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),756] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),784] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),730] width:(CyrusUISize 146 1)
        fn syncControls = (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;syncControls();redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;syncControls();redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on refreshGroups pressed do updatePattern()
                fn updateControls = (
            for c in #(sizeSpin,divSeedSpin,roughSpin,blurSpin,noiseSpin,groupHint,fixedHint) do c.visible=obj.diversityMode==2
            for c in #(strokeTitle,pathsDrop,analyzerChannel,pickAnalyzer,pickPath,removePath,strokesList,addOutside,addInside,removeStrokeButton,strokeWidth,strokeMode,strokeChoices,strokeScaleMin,strokeScaleMax,refreshGroups,strokeHelp) do c.visible=(obj.diversityMode==3 or obj.diversityMode==4)
            if strokeExpandedHeight>0 do diversityUI.height=if obj.diversityMode>=3 then strokeExpandedHeight else (if obj.diversityMode==2 then 310 else 124)*parentView.dpiScale
            parentView.layoutPanels()
        )
        on diversityRadio changed v do (obj.diversityMode=v;updateControls();updatePattern();obj.dirty=true;syncControls();redrawViews())


        on sizeSpin changed v do (obj.diversitySize=v;obj.dirty=true;syncControls();redrawViews())
        on divSeedSpin changed v do (obj.diversitySeed=v;obj.dirty=true;syncControls();redrawViews())
        on roughSpin changed v do (obj.roughness=v;obj.dirty=true;syncControls();redrawViews())
        on blurSpin changed v do (obj.blurryEdge=v;obj.dirty=true;syncControls();redrawViews())
        on noiseSpin changed v do (obj.diversityNoise=v;obj.dirty=true;syncControls();redrawViews())
        on diversityUI rolledUp state do parentView.layoutPanels()
        on diversityUI open do (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;controlsReady=true;strokeExpandedHeight=diversityUI.height;updateControls();updatePattern())
    )
diversityUI.obj=target;diversityUI.parentView=view;diversityUI
)
global CyrusMake_lineUI
fn CyrusMake_lineUI target view = (
    CyrusUIBuildView=view
    rollout lineUI "Line Pattern" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),108] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),140] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),236] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),236] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),262] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),296] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),324] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),396] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),508] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),534] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),566] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),594] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),830] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),858] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),914] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),956] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),984] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1012] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),764] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),646] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),674] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),620] width:(CyrusUISize 146 1)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;redrawViews())
        on refreshGroups pressed do updatePattern()

        on lineUI rolledUp state do parentView.layoutPanels()
        on lineUI open do updatePattern()
    )
lineUI.obj=target;lineUI.parentView=view;lineUI
)
global CyrusMake_randomUI
fn CyrusMake_randomUI target view = (
    CyrusUIBuildView=view
    rollout randomUI "Randomize XYZ" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on randomUI close do controlsReady=false
        label rotTitle "Rotation (degrees)" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        label rotMinTitle "Min" pos:[(CyrusUISize 24 1),30] width:(CyrusUISize 58 1)
        label rotMaxTitle "Max" pos:[(CyrusUISize 94 1),30] width:(CyrusUISize 58 1)
        label rotXLabel "X" pos:[(CyrusUISize 8 1),52] width:(CyrusUISize 12 1)
        spinner rotXMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotXMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotYLabel "Y" pos:[(CyrusUISize 8 1),76] width:(CyrusUISize 12 1)
        spinner rotYMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotYMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotZLabel "Z" pos:[(CyrusUISize 8 1),100] width:(CyrusUISize 12 1)
        spinner rotZMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotZMaxSpin "" range:[-360,360,360]  pos:[(CyrusUISize 94 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclTitle "Scale (multiplier)" pos:[(CyrusUISize 8 1),132] width:(CyrusUISize 146 1)
        label sclMinTitle "Min" pos:[(CyrusUISize 24 1),154] width:(CyrusUISize 58 1)
        label sclMaxTitle "Max" pos:[(CyrusUISize 94 1),154] width:(CyrusUISize 58 1)
        label sclXLabel "X" pos:[(CyrusUISize 8 1),176] width:(CyrusUISize 12 1)
        spinner sclXMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclXMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclYLabel "Y" pos:[(CyrusUISize 8 1),200] width:(CyrusUISize 12 1)
        spinner sclYMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclYMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclZLabel "Z" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 12 1)
        spinner sclZMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclZMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label wholeTitle "Whole Scale (uniform)" pos:[(CyrusUISize 8 1),252] width:(CyrusUISize 146 1)
        label wholeMinTitle "Min" pos:[(CyrusUISize 24 1),274] width:(CyrusUISize 58 1)
        label wholeMaxTitle "Max" pos:[(CyrusUISize 94 1),274] width:(CyrusUISize 58 1)
        spinner wholeMinSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 24 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner wholeMaxSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 94 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        on wholeMinSpin changed v do (obj.wholeScaleMin=v;if v>obj.wholeScaleMax do (obj.wholeScaleMax=v;wholeMaxSpin.value=v);redrawViews())
        on wholeMaxSpin changed v do (obj.wholeScaleMax=v;if v<obj.wholeScaleMin do (obj.wholeScaleMin=v;wholeMinSpin.value=v);redrawViews())
        label movTitle "Movement (world units)" pos:[(CyrusUISize 8 1),332] width:(CyrusUISize 146 1)
        label movMinTitle "Min" pos:[(CyrusUISize 24 1),354] width:(CyrusUISize 58 1)
        label movMaxTitle "Max" pos:[(CyrusUISize 94 1),354] width:(CyrusUISize 58 1)
        label movXLabel "X" pos:[(CyrusUISize 8 1),376] width:(CyrusUISize 12 1)
        spinner movXMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movXMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movYLabel "Y" pos:[(CyrusUISize 8 1),400] width:(CyrusUISize 12 1)
        spinner movYMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movYMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movZLabel "Z" pos:[(CyrusUISize 8 1),424] width:(CyrusUISize 12 1)
        spinner movZMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movZMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        checkbox projectCheck "Keep on surface" pos:[(CyrusUISize 8 1),456] width:(CyrusUISize 146 1)
        checkbox alignCheck "Align to normal" pos:[(CyrusUISize 8 1),480] width:(CyrusUISize 146 1)

        fn syncControls = (projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;)
        on alignCheck changed v do (obj.alignNormal=v;obj.dirty=true;syncControls();redrawViews())

        on projectCheck changed v do (obj.projectMove=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMinSpin changed v do (obj.rotXMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMaxSpin changed v do (obj.rotXMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMinSpin changed v do (obj.rotYMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMaxSpin changed v do (obj.rotYMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMinSpin changed v do (obj.rotZMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMaxSpin changed v do (obj.rotZMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMinSpin changed v do (obj.sclXMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMaxSpin changed v do (obj.sclXMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMinSpin changed v do (obj.sclYMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMaxSpin changed v do (obj.sclYMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMinSpin changed v do (obj.sclZMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMaxSpin changed v do (obj.sclZMax=v;obj.dirty=true;syncControls();redrawViews())
        on movXMinSpin changed v do (obj.movXMin=v;obj.dirty=true;syncControls();redrawViews())
        on movXMaxSpin changed v do (obj.movXMax=v;obj.dirty=true;syncControls();redrawViews())
        on movYMinSpin changed v do (obj.movYMin=v;obj.dirty=true;syncControls();redrawViews())
        on movYMaxSpin changed v do (obj.movYMax=v;obj.dirty=true;syncControls();redrawViews())
        on movZMinSpin changed v do (obj.movZMin=v;obj.dirty=true;syncControls();redrawViews())
        on movZMaxSpin changed v do (obj.movZMax=v;obj.dirty=true;syncControls();redrawViews())
        on randomUI rolledUp state do parentView.layoutPanels()
        on randomUI open do (wholeMinSpin.value=obj.wholeScaleMin;wholeMaxSpin.value=obj.wholeScaleMax;projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;controlsReady=true;alignCheck.checked=obj.alignNormal)
    )
randomUI.obj=target;randomUI.parentView=view;randomUI
)
global CyrusMake_sourceUI_1
fn CyrusMake_sourceUI_1 target view = (
    CyrusUIBuildView=view
    rollout sourceUI_1 "Source Object" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on sourceUI_1 close do controlsReady=false
        local groupPalette=#()
        local loadingColor=false
        local focusedRow=0
        multiListBox plantList "Sources (Ctrl/Shift)" items:#() pos:[(CyrusUISize 8 1),8] height:6 width:(CyrusUISize 146 1)
        button selectFromScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton addPlant "Add: pick in viewport" pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button addSelected "Add selected objects" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        button removePlant "Remove selected rows" pos:[(CyrusUISize 8 1),212] width:(CyrusUISize 146 1)
        button selectPlant "Select sources" pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        button addPoint "Add Point" pos:[(CyrusUISize 8 1),264] width:(CyrusUISize 146 1)
        button addEmpty "Add Empty" pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        pickbutton replacePoint "Replace Point: pick object" filter:AminScatterSourceFilter pos:[(CyrusUISize 8 1),316] width:(CyrusUISize 146 1)
        label groupHeading "Cluster color group" pos:[(CyrusUISize 8 1),348] width:(CyrusUISize 146 1)
        dropdownlist existingGroups "Reuse a group" items:#() pos:[(CyrusUISize 8 1),371] width:(CyrusUISize 146 1)
        colorpicker groupColor "Color: " color:(color 100 220 120) pos:[(CyrusUISize 8 1),419] width:(CyrusUISize 146 1) modal:true notifyAfterAccept:true
        button applyColor "Apply to selected rows" pos:[(CyrusUISize 8 1),446] width:(CyrusUISize 146 1)
        label colorHelp "OK saves the selected color." pos:[(CyrusUISize 8 1),476] width:(CyrusUISize 146 1)
        spinner weightSpin "Weight: " range:[0,1,1] scale:0.01 pos:[(CyrusUISize 8 1),504] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        label weightHelp "0 = off; relative share" pos:[(CyrusUISize 8 1),530] width:(CyrusUISize 146 1)
        spinner sourceZSpin "Z Offset: " range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),556] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        spinner sourceScaleSpin "Scale: " range:[0,10000,1] scale:0.01 pos:[(CyrusUISize 8 1),582] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        label sourceTransformHelp "Scale: 1 = original" pos:[(CyrusUISize 8 1),608] width:(CyrusUISize 146 1)
        spinner radiusSourceSpin "Collision radius:" type:#worldunits range:[0,1e9,0] pos:[(CyrusUISize 8 1),686] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        checkbox followRadiusCheck "Follow Scale" pos:[(CyrusUISize 8 1),712] width:(CyrusUISize 146 1)
        checkbox showRadiusCheck "Show Radius" pos:[(CyrusUISize 8 1),738] width:(CyrusUISize 146 1)
        dropdownlist forwardAxis "Forward axis:" items:#("+Y","-Y","+X","-X") pos:[(CyrusUISize 8 1),634] width:(CyrusUISize 146 1)
        fn colorLabel c = ("#"+(formattedPrint (obj.colorKey c) format:"06X"))
        fn updateList = (
            local selectedRows=plantList.selection
            if selectedRows.numberSet==0 and obj.sources.count>0 do selectedRows=#{1}
            obj.syncColors()
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
            showSelectedColor();redrawViews()
        )
        on addPoint pressed do (
            local i=obj.addPointSource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on replacePoint picked n do (
            local rows=plantList.selection as array
            if rows.count!=1 then messageBox "Select one Point row to replace." title:"Cyrus Scatter"
            else if not (obj.replacePointSource rows[1] n) do messageBox "Select a Point row and an object that is not already in this source list." title:"Cyrus Scatter"
            replacePoint.text="Replace Point: pick object";updateList();showSelectedColor();redrawViews()
        )
        on addEmpty pressed do (
            local i=obj.addEmptySource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on radiusSourceSpin changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v;redrawViews())
        on followRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:2;redrawViews())
        on showRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:3;redrawViews())
        on forwardAxis selected v do if not loadingColor do (obj.assignSourceForward plantList.selection v;redrawViews())
        on sourceZSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v;redrawViews())
        on sourceScaleSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v scaling:true;redrawViews())
        on weightSpin changed v do if not loadingColor do (obj.assignWeight plantList.selection v;updateList();redrawViews())
        on plantList selected i do (
            if i>0 and plantList.selection[i] do focusedRow=i
        )
        on plantList selectionEnd do showSelectedColor()
        on existingGroups selected i do (
            if i>0 and i<=groupPalette.count do (
                local c=groupPalette[i]
                loadingColor=true;groupColor.color=c;loadingColor=false
                obj.assignGroup plantList.selection c;updateList();redrawViews()
            )
        )
        on groupColor changed c do (
            if not loadingColor and plantList.selection.numberSet>0 do (
                obj.assignGroup plantList.selection c
                updateList();redrawViews()
            )
        )
        on applyColor pressed do (
            obj.assignGroup plantList.selection groupColor.color
            updateList();redrawViews()
        )
        on selectFromScene pressed do (
            local picked=selectByName title:"Cyrus Scatter - Select From Scene" buttonText:"Add" filter:AminScatterSourceFilter single:false
            addSources picked
        )
        on addPlant picked n do addSources #(n)
        on addSelected pressed do addSources (selection as array)
        on removePlant pressed do (
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
            plantList.selection=#{};obj.dirty=true;updateList();redrawViews()
        )
        on selectPlant pressed do (
            local nodes=for i in plantList.selection where i<=obj.sources.count and isValidNode obj.sources[i] collect obj.sources[i]
            if nodes.count>0 do select nodes
        )

        on sourceUI_1 rolledUp state do parentView.layoutPanels()
        on sourceUI_1 open do (controlsReady=true;(updateList();showSelectedColor()))
    )
sourceUI_1.obj=target;sourceUI_1.parentView=view;sourceUI_1
)
global CyrusMake_distributionUI_1
fn CyrusMake_distributionUI_1 target view = (
    CyrusUIBuildView=view
    rollout distributionUI_1 "Point Generation" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on distributionUI_1 close do controlsReady=false
        radiobuttons modeRadio "Method" labels:#("Random","Texture Density") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        radiobuttons populationRadio "Population" labels:#("Count","Plants per m2") columns:1 pos:[(CyrusUISize 8 1),78] width:(CyrusUISize 146 1)
        checkbox showCenterCheck "Show Point" pos:[(CyrusUISize 8 1),148] width:(CyrusUISize 146 1)
        on showCenterCheck changed v do (obj.showCenters=v;redrawViews())
        spinner countSpin "Count: " range:[1,100000,200] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),174]
        spinner densitySpin "Per m2: " range:[0,1000000,100] fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),200]
        spinner seedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),226]
        label densityHeading "Texture density" pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)
        mapbutton densityButton "Choose density map" pos:[(CyrusUISize 8 1),284] width:(CyrusUISize 146 1)
        checkbox invertCheck "Invert density" pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        label uvHint "UV channel 1; 0..1" pos:[(CyrusUISize 8 1),338] width:(CyrusUISize 146 1)
        label mapHint "White: dense / Black: empty" pos:[(CyrusUISize 8 1),360] width:(CyrusUISize 146 1)

        fn syncControls = (populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;)
        on modeRadio changed v do (obj.distributionMode=if v==2 then 3 else 1;obj.dirty=true;syncControls();redrawViews())
        on countSpin changed v do (obj.amount=v;obj.dirty=true;syncControls();redrawViews())
        on seedSpin changed v do (obj.randomSeed=v;obj.dirty=true;syncControls();redrawViews())

        on populationRadio changed v do (obj.populationMode=v;obj.dirty=true;syncControls();redrawViews())
        on densitySpin changed v do (obj.plantsPerM2=v;obj.dirty=true;syncControls();redrawViews())
        on densityButton picked v do (obj.densityMap=v;obj.dirty=true;syncControls();redrawViews())
        on invertCheck changed v do (obj.invertDensity=v;obj.dirty=true;syncControls();redrawViews())
        on distributionUI_1 rolledUp state do parentView.layoutPanels()
        on distributionUI_1 open do (showCenterCheck.checked=obj.showCenters;populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;controlsReady=true;(countSpin.value=obj.amount;seedSpin.value=obj.randomSeed;modeRadio.state=if obj.distributionMode==3 then 2 else 1))
    )
distributionUI_1.obj=target;distributionUI_1.parentView=view;distributionUI_1
)
global CyrusMake_areaUI_1
fn CyrusMake_areaUI_1 target view = (
    CyrusUIBuildView=view
    rollout areaUI_1 "Area" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on areaUI_1 close do controlsReady=false
        multiListBox areaList "Closed lines / shapes" items:#() pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1) height:6
        button addAreaScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton pickArea "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button removeArea "Remove selected rows" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        radiobuttons areaMode "Selected area mode" labels:#("Include","Exclude") columns:1 pos:[(CyrusUISize 8 1),220] width:(CyrusUISize 146 1)
        label areaHint "Exclude overrides Include." pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        label projectionHint "Top / world XY projection." pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        button refreshAreas "Refresh areas / preview" pos:[(CyrusUISize 8 1),340] width:(CyrusUISize 146 1)
        local loadingAnalyzerArea=false
        label aaTitle "Surface Analyzer Area" pos:[(CyrusUISize 8 1),378] width:(CyrusUISize 146 1)
        pickbutton aaPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),404] width:(CyrusUISize 146 1)
        button aaRemove "Remove Area Analyzer" pos:[(CyrusUISize 8 1),432] width:(CyrusUISize 146 1)
        checkbox aaLine "Center Line" pos:[(CyrusUISize 8 1),464] width:(CyrusUISize 146 1)
        spinner aaWidth "Full width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),490] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        dropdownlist aaCaps "Line ends" items:#("Flat","Round") selection:1 pos:[(CyrusUISize 8 1),518] width:(CyrusUISize 146 1)
        spinner aaStreetOffset "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),572] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox aaPoints "Points" pos:[(CyrusUISize 8 1),604] width:(CyrusUISize 146 1)
        spinner aaRadius "Radius:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),630] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label aaHelp "XY mask. Both enabled = union. Works with Random / Clusters." pos:[(CyrusUISize 8 1),660] width:(CyrusUISize 146 1) height:40
        fn syncAnalyzerArea = (
            loadingAnalyzerArea=true
            aaPick.text=if isValidNode obj.areaAnalyzer then obj.areaAnalyzer.name else "Pick Surface Analyzer"
            aaLine.checked=obj.areaUseLine;aaPoints.checked=obj.areaUsePoints
            aaStreetOffset.value=obj.centerStreetOffset;aaStreetOffset.enabled=obj.areaUseLine
            aaWidth.value=obj.areaLineWidth;aaRadius.value=obj.areaPointRadius;aaCaps.selection=obj.areaLineCaps
            aaWidth.enabled=obj.areaUseLine;aaCaps.enabled=obj.areaUseLine;aaRadius.enabled=obj.areaUsePoints
            loadingAnalyzerArea=false
        )
        on aaPick picked n do (obj.areaAnalyzer=n;syncAnalyzerArea();redrawViews())
        on aaRemove pressed do (obj.areaUseLine=false;obj.areaUsePoints=false;obj.areaAnalyzer=undefined;syncAnalyzerArea();redrawViews())
        on aaLine changed v do if not loadingAnalyzerArea do (obj.areaUseLine=v;syncAnalyzerArea();redrawViews())
        on aaPoints changed v do if not loadingAnalyzerArea do (obj.areaUsePoints=v;syncAnalyzerArea();redrawViews())
        on aaStreetOffset changed v do if not loadingAnalyzerArea do (obj.centerStreetOffset=v;redrawViews())
        on aaWidth changed v do if not loadingAnalyzerArea do (obj.areaLineWidth=v;redrawViews())
        on aaRadius changed v do if not loadingAnalyzerArea do (obj.areaPointRadius=v;redrawViews())
        on aaCaps selected v do if not loadingAnalyzerArea do (obj.areaLineCaps=v;redrawViews())

        local loadingFall=false
        dropdownlist fallTarget "Edge falloff target" items:#("Analyzer Boundary","Selected Area line") selection:1 pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        pickbutton fallPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1)
        button fallRemove "Remove Analyzer" pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1)
        label fallTargetName "" pos:[(CyrusUISize 8 1),818] width:(CyrusUISize 146 1) height:40
        checkbox fallDeleteCheck "Delete edge band" pos:[(CyrusUISize 8 1),860] width:(CyrusUISize 146 1)
        spinner fallDeleteSpin "Delete width:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox fallScaleCheck "Scale ramp" pos:[(CyrusUISize 8 1),918] width:(CyrusUISize 146 1)
        spinner fallScaleSpin "Scale width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),944] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallScaleEdit "Edit Scale Graph..." pos:[(CyrusUISize 8 1),974] width:(CyrusUISize 146 1)
        checkbox fallDensityCheck "Density ramp" pos:[(CyrusUISize 8 1),1010] width:(CyrusUISize 146 1)
        spinner fallDensitySpin "Density width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),1036] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallDensityEdit "Edit Density Graph..." pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1)
        label fallHelp "Ramps start after delete band. Each Area line has its own settings." pos:[(CyrusUISize 8 1),1104] width:(CyrusUISize 146 1) height:56
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
                if fallTarget.selection==1 or isValidNode n do (local cfg=obj.getFallConfig n;cfg[index]=value;obj.setFallConfig n cfg;redrawViews())
            )
        )
        on fallTarget selected v do syncFalloff()
        on fallPick picked n do (if CyrusAnalyzerFilter n do obj.fallAnalyzer=n;syncFalloff();redrawViews())
        on fallRemove pressed do (obj.fallAnalyzer=undefined;obj.fallDelete=false;obj.fallScale=false;obj.fallDensity=false;syncFalloff();redrawViews())
        on fallDeleteCheck changed v do setFallValue 1 v
        on fallDeleteSpin changed v do setFallValue 2 v
        on fallScaleCheck changed v do setFallValue 3 v
        on fallScaleSpin changed v do setFallValue 4 v
        on fallDensityCheck changed v do setFallValue 6 v
        on fallDensitySpin changed v do setFallValue 7 v
        on fallScaleEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) false
        on fallDensityEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) true

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

        on pickArea picked n do (addArea n;updateAreas();redrawViews())
        on addAreaScene pressed do (
            local nodes=selectByName title:"Cyrus Scatter - Closed Areas" buttonText:"Add" filter:AminScatterAreaFilter single:false
            if nodes!=undefined do for n in nodes do addArea n
            updateAreas();redrawViews()
        )
        on areaList selectionEnd do (
            if areaList.selection.numberSet==1 do fallTarget.selection=2
            syncFalloff()
            if areaList.selection.numberSet>0 do areaMode.state=obj.areaModes[(areaList.selection as array)[1]]
        )
        on areaMode changed mode do (
            undo "Cyrus Scatter area mode" on (for i in areaList.selection do obj.areaModes[i]=mode)
            obj.dirty=true;updateAreas();redrawViews()
        )
        on removeArea pressed do (
            if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()
            local rows=areaList.selection as array
            undo "Cyrus Scatter remove areas" on (
                obj.ensureAreaFalloffs()
                for i=rows.count to 1 by -1 do (deleteItem obj.areaNodes rows[i];deleteItem obj.areaModes rows[i];deleteItem obj.areaFallConfigs rows[i];deleteItem obj.areaFallScaleGraphs rows[i];deleteItem obj.areaFallDensityGraphs rows[i])
            )
            areaList.selection=#{};obj.dirty=true;updateAreas();redrawViews()
        )
        on refreshAreas pressed do (obj.dirty=true;obj.refreshPreview();redrawViews())

        on areaUI_1 rolledUp state do parentView.layoutPanels()
        on areaUI_1 open do (syncAnalyzerArea();syncFalloff();controlsReady=true;updateAreas())
    )
areaUI_1.obj=target;areaUI_1.parentView=view;areaUI_1
)
global CyrusMake_diversityUI_1
fn CyrusMake_diversityUI_1 target view = (
    CyrusUIBuildView=view
    rollout diversityUI_1 "Diversity / Colors" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false,strokeExpandedHeight=0
        on diversityUI_1 close do controlsReady=false
        radiobuttons diversityRadio "Source assignment" labels:#("Random","Clusters","Line Pattern","Analyze Surface") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner sizeSpin "Size: " range:[0.01,100000,10] type:#worldUnits fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),104]
        spinner divSeedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),130]
        spinner roughSpin "Roughness %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),156]
        spinner blurSpin "Blur edge %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),182]
        spinner noiseSpin "Noise %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),208]
        label groupHint "Uses source group colors." pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        label fixedHint "Point positions stay fixed." pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)



    
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),118] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),218] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),250] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),346] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),346] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),372] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),406] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),434] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),506] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),618] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),644] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),676] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),870] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),898] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),940] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),968] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),996] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),1024] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1094] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1122] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),874] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),756] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),784] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),730] width:(CyrusUISize 146 1)
        fn syncControls = (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;syncControls();redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;syncControls();redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on refreshGroups pressed do updatePattern()
                fn updateControls = (
            for c in #(sizeSpin,divSeedSpin,roughSpin,blurSpin,noiseSpin,groupHint,fixedHint) do c.visible=obj.diversityMode==2
            for c in #(strokeTitle,pathsDrop,analyzerChannel,pickAnalyzer,pickPath,removePath,strokesList,addOutside,addInside,removeStrokeButton,strokeWidth,strokeMode,strokeChoices,strokeScaleMin,strokeScaleMax,refreshGroups,strokeHelp) do c.visible=(obj.diversityMode==3 or obj.diversityMode==4)
            if strokeExpandedHeight>0 do diversityUI_1.height=if obj.diversityMode>=3 then strokeExpandedHeight else (if obj.diversityMode==2 then 310 else 124)*parentView.dpiScale
            parentView.layoutPanels()
        )
        on diversityRadio changed v do (obj.diversityMode=v;updateControls();updatePattern();obj.dirty=true;syncControls();redrawViews())


        on sizeSpin changed v do (obj.diversitySize=v;obj.dirty=true;syncControls();redrawViews())
        on divSeedSpin changed v do (obj.diversitySeed=v;obj.dirty=true;syncControls();redrawViews())
        on roughSpin changed v do (obj.roughness=v;obj.dirty=true;syncControls();redrawViews())
        on blurSpin changed v do (obj.blurryEdge=v;obj.dirty=true;syncControls();redrawViews())
        on noiseSpin changed v do (obj.diversityNoise=v;obj.dirty=true;syncControls();redrawViews())
        on diversityUI_1 rolledUp state do parentView.layoutPanels()
        on diversityUI_1 open do (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;controlsReady=true;strokeExpandedHeight=diversityUI_1.height;updateControls();updatePattern())
    )
diversityUI_1.obj=target;diversityUI_1.parentView=view;diversityUI_1
)
global CyrusMake_lineUI_1
fn CyrusMake_lineUI_1 target view = (
    CyrusUIBuildView=view
    rollout lineUI_1 "Line Pattern" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),108] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),140] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),236] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),236] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),262] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),296] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),324] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),396] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),508] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),534] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),566] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),594] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),830] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),858] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),914] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),956] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),984] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1012] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),764] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),646] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),674] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),620] width:(CyrusUISize 146 1)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;redrawViews())
        on refreshGroups pressed do updatePattern()

        on lineUI_1 rolledUp state do parentView.layoutPanels()
        on lineUI_1 open do updatePattern()
    )
lineUI_1.obj=target;lineUI_1.parentView=view;lineUI_1
)
global CyrusMake_randomUI_1
fn CyrusMake_randomUI_1 target view = (
    CyrusUIBuildView=view
    rollout randomUI_1 "Randomize XYZ" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on randomUI_1 close do controlsReady=false
        label rotTitle "Rotation (degrees)" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        label rotMinTitle "Min" pos:[(CyrusUISize 24 1),30] width:(CyrusUISize 58 1)
        label rotMaxTitle "Max" pos:[(CyrusUISize 94 1),30] width:(CyrusUISize 58 1)
        label rotXLabel "X" pos:[(CyrusUISize 8 1),52] width:(CyrusUISize 12 1)
        spinner rotXMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotXMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotYLabel "Y" pos:[(CyrusUISize 8 1),76] width:(CyrusUISize 12 1)
        spinner rotYMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotYMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotZLabel "Z" pos:[(CyrusUISize 8 1),100] width:(CyrusUISize 12 1)
        spinner rotZMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotZMaxSpin "" range:[-360,360,360]  pos:[(CyrusUISize 94 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclTitle "Scale (multiplier)" pos:[(CyrusUISize 8 1),132] width:(CyrusUISize 146 1)
        label sclMinTitle "Min" pos:[(CyrusUISize 24 1),154] width:(CyrusUISize 58 1)
        label sclMaxTitle "Max" pos:[(CyrusUISize 94 1),154] width:(CyrusUISize 58 1)
        label sclXLabel "X" pos:[(CyrusUISize 8 1),176] width:(CyrusUISize 12 1)
        spinner sclXMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclXMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclYLabel "Y" pos:[(CyrusUISize 8 1),200] width:(CyrusUISize 12 1)
        spinner sclYMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclYMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclZLabel "Z" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 12 1)
        spinner sclZMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclZMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label wholeTitle "Whole Scale (uniform)" pos:[(CyrusUISize 8 1),252] width:(CyrusUISize 146 1)
        label wholeMinTitle "Min" pos:[(CyrusUISize 24 1),274] width:(CyrusUISize 58 1)
        label wholeMaxTitle "Max" pos:[(CyrusUISize 94 1),274] width:(CyrusUISize 58 1)
        spinner wholeMinSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 24 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner wholeMaxSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 94 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        on wholeMinSpin changed v do (obj.wholeScaleMin=v;if v>obj.wholeScaleMax do (obj.wholeScaleMax=v;wholeMaxSpin.value=v);redrawViews())
        on wholeMaxSpin changed v do (obj.wholeScaleMax=v;if v<obj.wholeScaleMin do (obj.wholeScaleMin=v;wholeMinSpin.value=v);redrawViews())
        label movTitle "Movement (world units)" pos:[(CyrusUISize 8 1),332] width:(CyrusUISize 146 1)
        label movMinTitle "Min" pos:[(CyrusUISize 24 1),354] width:(CyrusUISize 58 1)
        label movMaxTitle "Max" pos:[(CyrusUISize 94 1),354] width:(CyrusUISize 58 1)
        label movXLabel "X" pos:[(CyrusUISize 8 1),376] width:(CyrusUISize 12 1)
        spinner movXMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movXMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movYLabel "Y" pos:[(CyrusUISize 8 1),400] width:(CyrusUISize 12 1)
        spinner movYMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movYMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movZLabel "Z" pos:[(CyrusUISize 8 1),424] width:(CyrusUISize 12 1)
        spinner movZMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movZMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        checkbox projectCheck "Keep on surface" pos:[(CyrusUISize 8 1),456] width:(CyrusUISize 146 1)
        checkbox alignCheck "Align to normal" pos:[(CyrusUISize 8 1),480] width:(CyrusUISize 146 1)

        fn syncControls = (projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;)
        on alignCheck changed v do (obj.alignNormal=v;obj.dirty=true;syncControls();redrawViews())

        on projectCheck changed v do (obj.projectMove=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMinSpin changed v do (obj.rotXMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMaxSpin changed v do (obj.rotXMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMinSpin changed v do (obj.rotYMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMaxSpin changed v do (obj.rotYMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMinSpin changed v do (obj.rotZMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMaxSpin changed v do (obj.rotZMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMinSpin changed v do (obj.sclXMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMaxSpin changed v do (obj.sclXMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMinSpin changed v do (obj.sclYMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMaxSpin changed v do (obj.sclYMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMinSpin changed v do (obj.sclZMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMaxSpin changed v do (obj.sclZMax=v;obj.dirty=true;syncControls();redrawViews())
        on movXMinSpin changed v do (obj.movXMin=v;obj.dirty=true;syncControls();redrawViews())
        on movXMaxSpin changed v do (obj.movXMax=v;obj.dirty=true;syncControls();redrawViews())
        on movYMinSpin changed v do (obj.movYMin=v;obj.dirty=true;syncControls();redrawViews())
        on movYMaxSpin changed v do (obj.movYMax=v;obj.dirty=true;syncControls();redrawViews())
        on movZMinSpin changed v do (obj.movZMin=v;obj.dirty=true;syncControls();redrawViews())
        on movZMaxSpin changed v do (obj.movZMax=v;obj.dirty=true;syncControls();redrawViews())
        on randomUI_1 rolledUp state do parentView.layoutPanels()
        on randomUI_1 open do (wholeMinSpin.value=obj.wholeScaleMin;wholeMaxSpin.value=obj.wholeScaleMax;projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;controlsReady=true;alignCheck.checked=obj.alignNormal)
    )
randomUI_1.obj=target;randomUI_1.parentView=view;randomUI_1
)
global CyrusMake_sourceUI_2
fn CyrusMake_sourceUI_2 target view = (
    CyrusUIBuildView=view
    rollout sourceUI_2 "Source Object" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on sourceUI_2 close do controlsReady=false
        local groupPalette=#()
        local loadingColor=false
        local focusedRow=0
        multiListBox plantList "Sources (Ctrl/Shift)" items:#() pos:[(CyrusUISize 8 1),8] height:6 width:(CyrusUISize 146 1)
        button selectFromScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton addPlant "Add: pick in viewport" pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button addSelected "Add selected objects" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        button removePlant "Remove selected rows" pos:[(CyrusUISize 8 1),212] width:(CyrusUISize 146 1)
        button selectPlant "Select sources" pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        button addPoint "Add Point" pos:[(CyrusUISize 8 1),264] width:(CyrusUISize 146 1)
        button addEmpty "Add Empty" pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        pickbutton replacePoint "Replace Point: pick object" filter:AminScatterSourceFilter pos:[(CyrusUISize 8 1),316] width:(CyrusUISize 146 1)
        label groupHeading "Cluster color group" pos:[(CyrusUISize 8 1),348] width:(CyrusUISize 146 1)
        dropdownlist existingGroups "Reuse a group" items:#() pos:[(CyrusUISize 8 1),371] width:(CyrusUISize 146 1)
        colorpicker groupColor "Color: " color:(color 100 220 120) pos:[(CyrusUISize 8 1),419] width:(CyrusUISize 146 1) modal:true notifyAfterAccept:true
        button applyColor "Apply to selected rows" pos:[(CyrusUISize 8 1),446] width:(CyrusUISize 146 1)
        label colorHelp "OK saves the selected color." pos:[(CyrusUISize 8 1),476] width:(CyrusUISize 146 1)
        spinner weightSpin "Weight: " range:[0,1,1] scale:0.01 pos:[(CyrusUISize 8 1),504] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        label weightHelp "0 = off; relative share" pos:[(CyrusUISize 8 1),530] width:(CyrusUISize 146 1)
        spinner sourceZSpin "Z Offset: " range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),556] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        spinner sourceScaleSpin "Scale: " range:[0,10000,1] scale:0.01 pos:[(CyrusUISize 8 1),582] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        label sourceTransformHelp "Scale: 1 = original" pos:[(CyrusUISize 8 1),608] width:(CyrusUISize 146 1)
        spinner radiusSourceSpin "Collision radius:" type:#worldunits range:[0,1e9,0] pos:[(CyrusUISize 8 1),686] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        checkbox followRadiusCheck "Follow Scale" pos:[(CyrusUISize 8 1),712] width:(CyrusUISize 146 1)
        checkbox showRadiusCheck "Show Radius" pos:[(CyrusUISize 8 1),738] width:(CyrusUISize 146 1)
        dropdownlist forwardAxis "Forward axis:" items:#("+Y","-Y","+X","-X") pos:[(CyrusUISize 8 1),634] width:(CyrusUISize 146 1)
        fn colorLabel c = ("#"+(formattedPrint (obj.colorKey c) format:"06X"))
        fn updateList = (
            local selectedRows=plantList.selection
            if selectedRows.numberSet==0 and obj.sources.count>0 do selectedRows=#{1}
            obj.syncColors()
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
            showSelectedColor();redrawViews()
        )
        on addPoint pressed do (
            local i=obj.addPointSource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on replacePoint picked n do (
            local rows=plantList.selection as array
            if rows.count!=1 then messageBox "Select one Point row to replace." title:"Cyrus Scatter"
            else if not (obj.replacePointSource rows[1] n) do messageBox "Select a Point row and an object that is not already in this source list." title:"Cyrus Scatter"
            replacePoint.text="Replace Point: pick object";updateList();showSelectedColor();redrawViews()
        )
        on addEmpty pressed do (
            local i=obj.addEmptySource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on radiusSourceSpin changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v;redrawViews())
        on followRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:2;redrawViews())
        on showRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:3;redrawViews())
        on forwardAxis selected v do if not loadingColor do (obj.assignSourceForward plantList.selection v;redrawViews())
        on sourceZSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v;redrawViews())
        on sourceScaleSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v scaling:true;redrawViews())
        on weightSpin changed v do if not loadingColor do (obj.assignWeight plantList.selection v;updateList();redrawViews())
        on plantList selected i do (
            if i>0 and plantList.selection[i] do focusedRow=i
        )
        on plantList selectionEnd do showSelectedColor()
        on existingGroups selected i do (
            if i>0 and i<=groupPalette.count do (
                local c=groupPalette[i]
                loadingColor=true;groupColor.color=c;loadingColor=false
                obj.assignGroup plantList.selection c;updateList();redrawViews()
            )
        )
        on groupColor changed c do (
            if not loadingColor and plantList.selection.numberSet>0 do (
                obj.assignGroup plantList.selection c
                updateList();redrawViews()
            )
        )
        on applyColor pressed do (
            obj.assignGroup plantList.selection groupColor.color
            updateList();redrawViews()
        )
        on selectFromScene pressed do (
            local picked=selectByName title:"Cyrus Scatter - Select From Scene" buttonText:"Add" filter:AminScatterSourceFilter single:false
            addSources picked
        )
        on addPlant picked n do addSources #(n)
        on addSelected pressed do addSources (selection as array)
        on removePlant pressed do (
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
            plantList.selection=#{};obj.dirty=true;updateList();redrawViews()
        )
        on selectPlant pressed do (
            local nodes=for i in plantList.selection where i<=obj.sources.count and isValidNode obj.sources[i] collect obj.sources[i]
            if nodes.count>0 do select nodes
        )

        on sourceUI_2 rolledUp state do parentView.layoutPanels()
        on sourceUI_2 open do (controlsReady=true;(updateList();showSelectedColor()))
    )
sourceUI_2.obj=target;sourceUI_2.parentView=view;sourceUI_2
)
global CyrusMake_distributionUI_2
fn CyrusMake_distributionUI_2 target view = (
    CyrusUIBuildView=view
    rollout distributionUI_2 "Point Generation" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on distributionUI_2 close do controlsReady=false
        radiobuttons modeRadio "Method" labels:#("Random","Texture Density") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        radiobuttons populationRadio "Population" labels:#("Count","Plants per m2") columns:1 pos:[(CyrusUISize 8 1),78] width:(CyrusUISize 146 1)
        checkbox showCenterCheck "Show Point" pos:[(CyrusUISize 8 1),148] width:(CyrusUISize 146 1)
        on showCenterCheck changed v do (obj.showCenters=v;redrawViews())
        spinner countSpin "Count: " range:[1,100000,200] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),174]
        spinner densitySpin "Per m2: " range:[0,1000000,100] fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),200]
        spinner seedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),226]
        label densityHeading "Texture density" pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)
        mapbutton densityButton "Choose density map" pos:[(CyrusUISize 8 1),284] width:(CyrusUISize 146 1)
        checkbox invertCheck "Invert density" pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        label uvHint "UV channel 1; 0..1" pos:[(CyrusUISize 8 1),338] width:(CyrusUISize 146 1)
        label mapHint "White: dense / Black: empty" pos:[(CyrusUISize 8 1),360] width:(CyrusUISize 146 1)

        fn syncControls = (populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;)
        on modeRadio changed v do (obj.distributionMode=if v==2 then 3 else 1;obj.dirty=true;syncControls();redrawViews())
        on countSpin changed v do (obj.amount=v;obj.dirty=true;syncControls();redrawViews())
        on seedSpin changed v do (obj.randomSeed=v;obj.dirty=true;syncControls();redrawViews())

        on populationRadio changed v do (obj.populationMode=v;obj.dirty=true;syncControls();redrawViews())
        on densitySpin changed v do (obj.plantsPerM2=v;obj.dirty=true;syncControls();redrawViews())
        on densityButton picked v do (obj.densityMap=v;obj.dirty=true;syncControls();redrawViews())
        on invertCheck changed v do (obj.invertDensity=v;obj.dirty=true;syncControls();redrawViews())
        on distributionUI_2 rolledUp state do parentView.layoutPanels()
        on distributionUI_2 open do (showCenterCheck.checked=obj.showCenters;populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;controlsReady=true;(countSpin.value=obj.amount;seedSpin.value=obj.randomSeed;modeRadio.state=if obj.distributionMode==3 then 2 else 1))
    )
distributionUI_2.obj=target;distributionUI_2.parentView=view;distributionUI_2
)
global CyrusMake_areaUI_2
fn CyrusMake_areaUI_2 target view = (
    CyrusUIBuildView=view
    rollout areaUI_2 "Area" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on areaUI_2 close do controlsReady=false
        multiListBox areaList "Closed lines / shapes" items:#() pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1) height:6
        button addAreaScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton pickArea "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button removeArea "Remove selected rows" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        radiobuttons areaMode "Selected area mode" labels:#("Include","Exclude") columns:1 pos:[(CyrusUISize 8 1),220] width:(CyrusUISize 146 1)
        label areaHint "Exclude overrides Include." pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        label projectionHint "Top / world XY projection." pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        button refreshAreas "Refresh areas / preview" pos:[(CyrusUISize 8 1),340] width:(CyrusUISize 146 1)
        local loadingAnalyzerArea=false
        label aaTitle "Surface Analyzer Area" pos:[(CyrusUISize 8 1),378] width:(CyrusUISize 146 1)
        pickbutton aaPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),404] width:(CyrusUISize 146 1)
        button aaRemove "Remove Area Analyzer" pos:[(CyrusUISize 8 1),432] width:(CyrusUISize 146 1)
        checkbox aaLine "Center Line" pos:[(CyrusUISize 8 1),464] width:(CyrusUISize 146 1)
        spinner aaWidth "Full width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),490] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        dropdownlist aaCaps "Line ends" items:#("Flat","Round") selection:1 pos:[(CyrusUISize 8 1),518] width:(CyrusUISize 146 1)
        spinner aaStreetOffset "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),572] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox aaPoints "Points" pos:[(CyrusUISize 8 1),604] width:(CyrusUISize 146 1)
        spinner aaRadius "Radius:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),630] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label aaHelp "XY mask. Both enabled = union. Works with Random / Clusters." pos:[(CyrusUISize 8 1),660] width:(CyrusUISize 146 1) height:40
        fn syncAnalyzerArea = (
            loadingAnalyzerArea=true
            aaPick.text=if isValidNode obj.areaAnalyzer then obj.areaAnalyzer.name else "Pick Surface Analyzer"
            aaLine.checked=obj.areaUseLine;aaPoints.checked=obj.areaUsePoints
            aaStreetOffset.value=obj.centerStreetOffset;aaStreetOffset.enabled=obj.areaUseLine
            aaWidth.value=obj.areaLineWidth;aaRadius.value=obj.areaPointRadius;aaCaps.selection=obj.areaLineCaps
            aaWidth.enabled=obj.areaUseLine;aaCaps.enabled=obj.areaUseLine;aaRadius.enabled=obj.areaUsePoints
            loadingAnalyzerArea=false
        )
        on aaPick picked n do (obj.areaAnalyzer=n;syncAnalyzerArea();redrawViews())
        on aaRemove pressed do (obj.areaUseLine=false;obj.areaUsePoints=false;obj.areaAnalyzer=undefined;syncAnalyzerArea();redrawViews())
        on aaLine changed v do if not loadingAnalyzerArea do (obj.areaUseLine=v;syncAnalyzerArea();redrawViews())
        on aaPoints changed v do if not loadingAnalyzerArea do (obj.areaUsePoints=v;syncAnalyzerArea();redrawViews())
        on aaStreetOffset changed v do if not loadingAnalyzerArea do (obj.centerStreetOffset=v;redrawViews())
        on aaWidth changed v do if not loadingAnalyzerArea do (obj.areaLineWidth=v;redrawViews())
        on aaRadius changed v do if not loadingAnalyzerArea do (obj.areaPointRadius=v;redrawViews())
        on aaCaps selected v do if not loadingAnalyzerArea do (obj.areaLineCaps=v;redrawViews())

        local loadingFall=false
        dropdownlist fallTarget "Edge falloff target" items:#("Analyzer Boundary","Selected Area line") selection:1 pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        pickbutton fallPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1)
        button fallRemove "Remove Analyzer" pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1)
        label fallTargetName "" pos:[(CyrusUISize 8 1),818] width:(CyrusUISize 146 1) height:40
        checkbox fallDeleteCheck "Delete edge band" pos:[(CyrusUISize 8 1),860] width:(CyrusUISize 146 1)
        spinner fallDeleteSpin "Delete width:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox fallScaleCheck "Scale ramp" pos:[(CyrusUISize 8 1),918] width:(CyrusUISize 146 1)
        spinner fallScaleSpin "Scale width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),944] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallScaleEdit "Edit Scale Graph..." pos:[(CyrusUISize 8 1),974] width:(CyrusUISize 146 1)
        checkbox fallDensityCheck "Density ramp" pos:[(CyrusUISize 8 1),1010] width:(CyrusUISize 146 1)
        spinner fallDensitySpin "Density width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),1036] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallDensityEdit "Edit Density Graph..." pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1)
        label fallHelp "Ramps start after delete band. Each Area line has its own settings." pos:[(CyrusUISize 8 1),1104] width:(CyrusUISize 146 1) height:56
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
                if fallTarget.selection==1 or isValidNode n do (local cfg=obj.getFallConfig n;cfg[index]=value;obj.setFallConfig n cfg;redrawViews())
            )
        )
        on fallTarget selected v do syncFalloff()
        on fallPick picked n do (if CyrusAnalyzerFilter n do obj.fallAnalyzer=n;syncFalloff();redrawViews())
        on fallRemove pressed do (obj.fallAnalyzer=undefined;obj.fallDelete=false;obj.fallScale=false;obj.fallDensity=false;syncFalloff();redrawViews())
        on fallDeleteCheck changed v do setFallValue 1 v
        on fallDeleteSpin changed v do setFallValue 2 v
        on fallScaleCheck changed v do setFallValue 3 v
        on fallScaleSpin changed v do setFallValue 4 v
        on fallDensityCheck changed v do setFallValue 6 v
        on fallDensitySpin changed v do setFallValue 7 v
        on fallScaleEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) false
        on fallDensityEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) true

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

        on pickArea picked n do (addArea n;updateAreas();redrawViews())
        on addAreaScene pressed do (
            local nodes=selectByName title:"Cyrus Scatter - Closed Areas" buttonText:"Add" filter:AminScatterAreaFilter single:false
            if nodes!=undefined do for n in nodes do addArea n
            updateAreas();redrawViews()
        )
        on areaList selectionEnd do (
            if areaList.selection.numberSet==1 do fallTarget.selection=2
            syncFalloff()
            if areaList.selection.numberSet>0 do areaMode.state=obj.areaModes[(areaList.selection as array)[1]]
        )
        on areaMode changed mode do (
            undo "Cyrus Scatter area mode" on (for i in areaList.selection do obj.areaModes[i]=mode)
            obj.dirty=true;updateAreas();redrawViews()
        )
        on removeArea pressed do (
            if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()
            local rows=areaList.selection as array
            undo "Cyrus Scatter remove areas" on (
                obj.ensureAreaFalloffs()
                for i=rows.count to 1 by -1 do (deleteItem obj.areaNodes rows[i];deleteItem obj.areaModes rows[i];deleteItem obj.areaFallConfigs rows[i];deleteItem obj.areaFallScaleGraphs rows[i];deleteItem obj.areaFallDensityGraphs rows[i])
            )
            areaList.selection=#{};obj.dirty=true;updateAreas();redrawViews()
        )
        on refreshAreas pressed do (obj.dirty=true;obj.refreshPreview();redrawViews())

        on areaUI_2 rolledUp state do parentView.layoutPanels()
        on areaUI_2 open do (syncAnalyzerArea();syncFalloff();controlsReady=true;updateAreas())
    )
areaUI_2.obj=target;areaUI_2.parentView=view;areaUI_2
)
global CyrusMake_diversityUI_2
fn CyrusMake_diversityUI_2 target view = (
    CyrusUIBuildView=view
    rollout diversityUI_2 "Diversity / Colors" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false,strokeExpandedHeight=0
        on diversityUI_2 close do controlsReady=false
        radiobuttons diversityRadio "Source assignment" labels:#("Random","Clusters","Line Pattern","Analyze Surface") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner sizeSpin "Size: " range:[0.01,100000,10] type:#worldUnits fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),104]
        spinner divSeedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),130]
        spinner roughSpin "Roughness %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),156]
        spinner blurSpin "Blur edge %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),182]
        spinner noiseSpin "Noise %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),208]
        label groupHint "Uses source group colors." pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        label fixedHint "Point positions stay fixed." pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)



    
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),118] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),218] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),250] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),346] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),346] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),372] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),406] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),434] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),506] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),618] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),644] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),676] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),870] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),898] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),940] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),968] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),996] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),1024] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1094] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1122] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),874] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),756] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),784] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),730] width:(CyrusUISize 146 1)
        fn syncControls = (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;syncControls();redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;syncControls();redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on refreshGroups pressed do updatePattern()
                fn updateControls = (
            for c in #(sizeSpin,divSeedSpin,roughSpin,blurSpin,noiseSpin,groupHint,fixedHint) do c.visible=obj.diversityMode==2
            for c in #(strokeTitle,pathsDrop,analyzerChannel,pickAnalyzer,pickPath,removePath,strokesList,addOutside,addInside,removeStrokeButton,strokeWidth,strokeMode,strokeChoices,strokeScaleMin,strokeScaleMax,refreshGroups,strokeHelp) do c.visible=(obj.diversityMode==3 or obj.diversityMode==4)
            if strokeExpandedHeight>0 do diversityUI_2.height=if obj.diversityMode>=3 then strokeExpandedHeight else (if obj.diversityMode==2 then 310 else 124)*parentView.dpiScale
            parentView.layoutPanels()
        )
        on diversityRadio changed v do (obj.diversityMode=v;updateControls();updatePattern();obj.dirty=true;syncControls();redrawViews())


        on sizeSpin changed v do (obj.diversitySize=v;obj.dirty=true;syncControls();redrawViews())
        on divSeedSpin changed v do (obj.diversitySeed=v;obj.dirty=true;syncControls();redrawViews())
        on roughSpin changed v do (obj.roughness=v;obj.dirty=true;syncControls();redrawViews())
        on blurSpin changed v do (obj.blurryEdge=v;obj.dirty=true;syncControls();redrawViews())
        on noiseSpin changed v do (obj.diversityNoise=v;obj.dirty=true;syncControls();redrawViews())
        on diversityUI_2 rolledUp state do parentView.layoutPanels()
        on diversityUI_2 open do (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;controlsReady=true;strokeExpandedHeight=diversityUI_2.height;updateControls();updatePattern())
    )
diversityUI_2.obj=target;diversityUI_2.parentView=view;diversityUI_2
)
global CyrusMake_lineUI_2
fn CyrusMake_lineUI_2 target view = (
    CyrusUIBuildView=view
    rollout lineUI_2 "Line Pattern" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),108] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),140] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),236] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),236] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),262] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),296] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),324] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),396] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),508] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),534] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),566] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),594] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),830] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),858] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),914] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),956] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),984] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1012] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),764] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),646] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),674] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),620] width:(CyrusUISize 146 1)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;redrawViews())
        on refreshGroups pressed do updatePattern()

        on lineUI_2 rolledUp state do parentView.layoutPanels()
        on lineUI_2 open do updatePattern()
    )
lineUI_2.obj=target;lineUI_2.parentView=view;lineUI_2
)
global CyrusMake_randomUI_2
fn CyrusMake_randomUI_2 target view = (
    CyrusUIBuildView=view
    rollout randomUI_2 "Randomize XYZ" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on randomUI_2 close do controlsReady=false
        label rotTitle "Rotation (degrees)" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        label rotMinTitle "Min" pos:[(CyrusUISize 24 1),30] width:(CyrusUISize 58 1)
        label rotMaxTitle "Max" pos:[(CyrusUISize 94 1),30] width:(CyrusUISize 58 1)
        label rotXLabel "X" pos:[(CyrusUISize 8 1),52] width:(CyrusUISize 12 1)
        spinner rotXMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotXMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotYLabel "Y" pos:[(CyrusUISize 8 1),76] width:(CyrusUISize 12 1)
        spinner rotYMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotYMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotZLabel "Z" pos:[(CyrusUISize 8 1),100] width:(CyrusUISize 12 1)
        spinner rotZMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotZMaxSpin "" range:[-360,360,360]  pos:[(CyrusUISize 94 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclTitle "Scale (multiplier)" pos:[(CyrusUISize 8 1),132] width:(CyrusUISize 146 1)
        label sclMinTitle "Min" pos:[(CyrusUISize 24 1),154] width:(CyrusUISize 58 1)
        label sclMaxTitle "Max" pos:[(CyrusUISize 94 1),154] width:(CyrusUISize 58 1)
        label sclXLabel "X" pos:[(CyrusUISize 8 1),176] width:(CyrusUISize 12 1)
        spinner sclXMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclXMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclYLabel "Y" pos:[(CyrusUISize 8 1),200] width:(CyrusUISize 12 1)
        spinner sclYMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclYMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclZLabel "Z" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 12 1)
        spinner sclZMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclZMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label wholeTitle "Whole Scale (uniform)" pos:[(CyrusUISize 8 1),252] width:(CyrusUISize 146 1)
        label wholeMinTitle "Min" pos:[(CyrusUISize 24 1),274] width:(CyrusUISize 58 1)
        label wholeMaxTitle "Max" pos:[(CyrusUISize 94 1),274] width:(CyrusUISize 58 1)
        spinner wholeMinSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 24 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner wholeMaxSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 94 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        on wholeMinSpin changed v do (obj.wholeScaleMin=v;if v>obj.wholeScaleMax do (obj.wholeScaleMax=v;wholeMaxSpin.value=v);redrawViews())
        on wholeMaxSpin changed v do (obj.wholeScaleMax=v;if v<obj.wholeScaleMin do (obj.wholeScaleMin=v;wholeMinSpin.value=v);redrawViews())
        label movTitle "Movement (world units)" pos:[(CyrusUISize 8 1),332] width:(CyrusUISize 146 1)
        label movMinTitle "Min" pos:[(CyrusUISize 24 1),354] width:(CyrusUISize 58 1)
        label movMaxTitle "Max" pos:[(CyrusUISize 94 1),354] width:(CyrusUISize 58 1)
        label movXLabel "X" pos:[(CyrusUISize 8 1),376] width:(CyrusUISize 12 1)
        spinner movXMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movXMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movYLabel "Y" pos:[(CyrusUISize 8 1),400] width:(CyrusUISize 12 1)
        spinner movYMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movYMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movZLabel "Z" pos:[(CyrusUISize 8 1),424] width:(CyrusUISize 12 1)
        spinner movZMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movZMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        checkbox projectCheck "Keep on surface" pos:[(CyrusUISize 8 1),456] width:(CyrusUISize 146 1)
        checkbox alignCheck "Align to normal" pos:[(CyrusUISize 8 1),480] width:(CyrusUISize 146 1)

        fn syncControls = (projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;)
        on alignCheck changed v do (obj.alignNormal=v;obj.dirty=true;syncControls();redrawViews())

        on projectCheck changed v do (obj.projectMove=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMinSpin changed v do (obj.rotXMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMaxSpin changed v do (obj.rotXMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMinSpin changed v do (obj.rotYMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMaxSpin changed v do (obj.rotYMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMinSpin changed v do (obj.rotZMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMaxSpin changed v do (obj.rotZMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMinSpin changed v do (obj.sclXMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMaxSpin changed v do (obj.sclXMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMinSpin changed v do (obj.sclYMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMaxSpin changed v do (obj.sclYMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMinSpin changed v do (obj.sclZMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMaxSpin changed v do (obj.sclZMax=v;obj.dirty=true;syncControls();redrawViews())
        on movXMinSpin changed v do (obj.movXMin=v;obj.dirty=true;syncControls();redrawViews())
        on movXMaxSpin changed v do (obj.movXMax=v;obj.dirty=true;syncControls();redrawViews())
        on movYMinSpin changed v do (obj.movYMin=v;obj.dirty=true;syncControls();redrawViews())
        on movYMaxSpin changed v do (obj.movYMax=v;obj.dirty=true;syncControls();redrawViews())
        on movZMinSpin changed v do (obj.movZMin=v;obj.dirty=true;syncControls();redrawViews())
        on movZMaxSpin changed v do (obj.movZMax=v;obj.dirty=true;syncControls();redrawViews())
        on randomUI_2 rolledUp state do parentView.layoutPanels()
        on randomUI_2 open do (wholeMinSpin.value=obj.wholeScaleMin;wholeMaxSpin.value=obj.wholeScaleMax;projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;controlsReady=true;alignCheck.checked=obj.alignNormal)
    )
randomUI_2.obj=target;randomUI_2.parentView=view;randomUI_2
)
global CyrusMake_sourceUI_3
fn CyrusMake_sourceUI_3 target view = (
    CyrusUIBuildView=view
    rollout sourceUI_3 "Source Object" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on sourceUI_3 close do controlsReady=false
        local groupPalette=#()
        local loadingColor=false
        local focusedRow=0
        multiListBox plantList "Sources (Ctrl/Shift)" items:#() pos:[(CyrusUISize 8 1),8] height:6 width:(CyrusUISize 146 1)
        button selectFromScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton addPlant "Add: pick in viewport" pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button addSelected "Add selected objects" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        button removePlant "Remove selected rows" pos:[(CyrusUISize 8 1),212] width:(CyrusUISize 146 1)
        button selectPlant "Select sources" pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        button addPoint "Add Point" pos:[(CyrusUISize 8 1),264] width:(CyrusUISize 146 1)
        button addEmpty "Add Empty" pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        pickbutton replacePoint "Replace Point: pick object" filter:AminScatterSourceFilter pos:[(CyrusUISize 8 1),316] width:(CyrusUISize 146 1)
        label groupHeading "Cluster color group" pos:[(CyrusUISize 8 1),348] width:(CyrusUISize 146 1)
        dropdownlist existingGroups "Reuse a group" items:#() pos:[(CyrusUISize 8 1),371] width:(CyrusUISize 146 1)
        colorpicker groupColor "Color: " color:(color 100 220 120) pos:[(CyrusUISize 8 1),419] width:(CyrusUISize 146 1) modal:true notifyAfterAccept:true
        button applyColor "Apply to selected rows" pos:[(CyrusUISize 8 1),446] width:(CyrusUISize 146 1)
        label colorHelp "OK saves the selected color." pos:[(CyrusUISize 8 1),476] width:(CyrusUISize 146 1)
        spinner weightSpin "Weight: " range:[0,1,1] scale:0.01 pos:[(CyrusUISize 8 1),504] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        label weightHelp "0 = off; relative share" pos:[(CyrusUISize 8 1),530] width:(CyrusUISize 146 1)
        spinner sourceZSpin "Z Offset: " range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),556] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        spinner sourceScaleSpin "Scale: " range:[0,10000,1] scale:0.01 pos:[(CyrusUISize 8 1),582] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        label sourceTransformHelp "Scale: 1 = original" pos:[(CyrusUISize 8 1),608] width:(CyrusUISize 146 1)
        spinner radiusSourceSpin "Collision radius:" type:#worldunits range:[0,1e9,0] pos:[(CyrusUISize 8 1),686] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        checkbox followRadiusCheck "Follow Scale" pos:[(CyrusUISize 8 1),712] width:(CyrusUISize 146 1)
        checkbox showRadiusCheck "Show Radius" pos:[(CyrusUISize 8 1),738] width:(CyrusUISize 146 1)
        dropdownlist forwardAxis "Forward axis:" items:#("+Y","-Y","+X","-X") pos:[(CyrusUISize 8 1),634] width:(CyrusUISize 146 1)
        fn colorLabel c = ("#"+(formattedPrint (obj.colorKey c) format:"06X"))
        fn updateList = (
            local selectedRows=plantList.selection
            if selectedRows.numberSet==0 and obj.sources.count>0 do selectedRows=#{1}
            obj.syncColors()
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
            showSelectedColor();redrawViews()
        )
        on addPoint pressed do (
            local i=obj.addPointSource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on replacePoint picked n do (
            local rows=plantList.selection as array
            if rows.count!=1 then messageBox "Select one Point row to replace." title:"Cyrus Scatter"
            else if not (obj.replacePointSource rows[1] n) do messageBox "Select a Point row and an object that is not already in this source list." title:"Cyrus Scatter"
            replacePoint.text="Replace Point: pick object";updateList();showSelectedColor();redrawViews()
        )
        on addEmpty pressed do (
            local i=obj.addEmptySource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on radiusSourceSpin changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v;redrawViews())
        on followRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:2;redrawViews())
        on showRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:3;redrawViews())
        on forwardAxis selected v do if not loadingColor do (obj.assignSourceForward plantList.selection v;redrawViews())
        on sourceZSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v;redrawViews())
        on sourceScaleSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v scaling:true;redrawViews())
        on weightSpin changed v do if not loadingColor do (obj.assignWeight plantList.selection v;updateList();redrawViews())
        on plantList selected i do (
            if i>0 and plantList.selection[i] do focusedRow=i
        )
        on plantList selectionEnd do showSelectedColor()
        on existingGroups selected i do (
            if i>0 and i<=groupPalette.count do (
                local c=groupPalette[i]
                loadingColor=true;groupColor.color=c;loadingColor=false
                obj.assignGroup plantList.selection c;updateList();redrawViews()
            )
        )
        on groupColor changed c do (
            if not loadingColor and plantList.selection.numberSet>0 do (
                obj.assignGroup plantList.selection c
                updateList();redrawViews()
            )
        )
        on applyColor pressed do (
            obj.assignGroup plantList.selection groupColor.color
            updateList();redrawViews()
        )
        on selectFromScene pressed do (
            local picked=selectByName title:"Cyrus Scatter - Select From Scene" buttonText:"Add" filter:AminScatterSourceFilter single:false
            addSources picked
        )
        on addPlant picked n do addSources #(n)
        on addSelected pressed do addSources (selection as array)
        on removePlant pressed do (
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
            plantList.selection=#{};obj.dirty=true;updateList();redrawViews()
        )
        on selectPlant pressed do (
            local nodes=for i in plantList.selection where i<=obj.sources.count and isValidNode obj.sources[i] collect obj.sources[i]
            if nodes.count>0 do select nodes
        )

        on sourceUI_3 rolledUp state do parentView.layoutPanels()
        on sourceUI_3 open do (controlsReady=true;(updateList();showSelectedColor()))
    )
sourceUI_3.obj=target;sourceUI_3.parentView=view;sourceUI_3
)
global CyrusMake_distributionUI_3
fn CyrusMake_distributionUI_3 target view = (
    CyrusUIBuildView=view
    rollout distributionUI_3 "Point Generation" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on distributionUI_3 close do controlsReady=false
        radiobuttons modeRadio "Method" labels:#("Random","Texture Density") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        radiobuttons populationRadio "Population" labels:#("Count","Plants per m2") columns:1 pos:[(CyrusUISize 8 1),78] width:(CyrusUISize 146 1)
        checkbox showCenterCheck "Show Point" pos:[(CyrusUISize 8 1),148] width:(CyrusUISize 146 1)
        on showCenterCheck changed v do (obj.showCenters=v;redrawViews())
        spinner countSpin "Count: " range:[1,100000,200] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),174]
        spinner densitySpin "Per m2: " range:[0,1000000,100] fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),200]
        spinner seedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),226]
        label densityHeading "Texture density" pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)
        mapbutton densityButton "Choose density map" pos:[(CyrusUISize 8 1),284] width:(CyrusUISize 146 1)
        checkbox invertCheck "Invert density" pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        label uvHint "UV channel 1; 0..1" pos:[(CyrusUISize 8 1),338] width:(CyrusUISize 146 1)
        label mapHint "White: dense / Black: empty" pos:[(CyrusUISize 8 1),360] width:(CyrusUISize 146 1)

        fn syncControls = (populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;)
        on modeRadio changed v do (obj.distributionMode=if v==2 then 3 else 1;obj.dirty=true;syncControls();redrawViews())
        on countSpin changed v do (obj.amount=v;obj.dirty=true;syncControls();redrawViews())
        on seedSpin changed v do (obj.randomSeed=v;obj.dirty=true;syncControls();redrawViews())

        on populationRadio changed v do (obj.populationMode=v;obj.dirty=true;syncControls();redrawViews())
        on densitySpin changed v do (obj.plantsPerM2=v;obj.dirty=true;syncControls();redrawViews())
        on densityButton picked v do (obj.densityMap=v;obj.dirty=true;syncControls();redrawViews())
        on invertCheck changed v do (obj.invertDensity=v;obj.dirty=true;syncControls();redrawViews())
        on distributionUI_3 rolledUp state do parentView.layoutPanels()
        on distributionUI_3 open do (showCenterCheck.checked=obj.showCenters;populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;controlsReady=true;(countSpin.value=obj.amount;seedSpin.value=obj.randomSeed;modeRadio.state=if obj.distributionMode==3 then 2 else 1))
    )
distributionUI_3.obj=target;distributionUI_3.parentView=view;distributionUI_3
)
global CyrusMake_areaUI_3
fn CyrusMake_areaUI_3 target view = (
    CyrusUIBuildView=view
    rollout areaUI_3 "Area" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on areaUI_3 close do controlsReady=false
        multiListBox areaList "Closed lines / shapes" items:#() pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1) height:6
        button addAreaScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton pickArea "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button removeArea "Remove selected rows" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        radiobuttons areaMode "Selected area mode" labels:#("Include","Exclude") columns:1 pos:[(CyrusUISize 8 1),220] width:(CyrusUISize 146 1)
        label areaHint "Exclude overrides Include." pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        label projectionHint "Top / world XY projection." pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        button refreshAreas "Refresh areas / preview" pos:[(CyrusUISize 8 1),340] width:(CyrusUISize 146 1)
        local loadingAnalyzerArea=false
        label aaTitle "Surface Analyzer Area" pos:[(CyrusUISize 8 1),378] width:(CyrusUISize 146 1)
        pickbutton aaPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),404] width:(CyrusUISize 146 1)
        button aaRemove "Remove Area Analyzer" pos:[(CyrusUISize 8 1),432] width:(CyrusUISize 146 1)
        checkbox aaLine "Center Line" pos:[(CyrusUISize 8 1),464] width:(CyrusUISize 146 1)
        spinner aaWidth "Full width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),490] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        dropdownlist aaCaps "Line ends" items:#("Flat","Round") selection:1 pos:[(CyrusUISize 8 1),518] width:(CyrusUISize 146 1)
        spinner aaStreetOffset "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),572] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox aaPoints "Points" pos:[(CyrusUISize 8 1),604] width:(CyrusUISize 146 1)
        spinner aaRadius "Radius:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),630] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label aaHelp "XY mask. Both enabled = union. Works with Random / Clusters." pos:[(CyrusUISize 8 1),660] width:(CyrusUISize 146 1) height:40
        fn syncAnalyzerArea = (
            loadingAnalyzerArea=true
            aaPick.text=if isValidNode obj.areaAnalyzer then obj.areaAnalyzer.name else "Pick Surface Analyzer"
            aaLine.checked=obj.areaUseLine;aaPoints.checked=obj.areaUsePoints
            aaStreetOffset.value=obj.centerStreetOffset;aaStreetOffset.enabled=obj.areaUseLine
            aaWidth.value=obj.areaLineWidth;aaRadius.value=obj.areaPointRadius;aaCaps.selection=obj.areaLineCaps
            aaWidth.enabled=obj.areaUseLine;aaCaps.enabled=obj.areaUseLine;aaRadius.enabled=obj.areaUsePoints
            loadingAnalyzerArea=false
        )
        on aaPick picked n do (obj.areaAnalyzer=n;syncAnalyzerArea();redrawViews())
        on aaRemove pressed do (obj.areaUseLine=false;obj.areaUsePoints=false;obj.areaAnalyzer=undefined;syncAnalyzerArea();redrawViews())
        on aaLine changed v do if not loadingAnalyzerArea do (obj.areaUseLine=v;syncAnalyzerArea();redrawViews())
        on aaPoints changed v do if not loadingAnalyzerArea do (obj.areaUsePoints=v;syncAnalyzerArea();redrawViews())
        on aaStreetOffset changed v do if not loadingAnalyzerArea do (obj.centerStreetOffset=v;redrawViews())
        on aaWidth changed v do if not loadingAnalyzerArea do (obj.areaLineWidth=v;redrawViews())
        on aaRadius changed v do if not loadingAnalyzerArea do (obj.areaPointRadius=v;redrawViews())
        on aaCaps selected v do if not loadingAnalyzerArea do (obj.areaLineCaps=v;redrawViews())

        local loadingFall=false
        dropdownlist fallTarget "Edge falloff target" items:#("Analyzer Boundary","Selected Area line") selection:1 pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        pickbutton fallPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1)
        button fallRemove "Remove Analyzer" pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1)
        label fallTargetName "" pos:[(CyrusUISize 8 1),818] width:(CyrusUISize 146 1) height:40
        checkbox fallDeleteCheck "Delete edge band" pos:[(CyrusUISize 8 1),860] width:(CyrusUISize 146 1)
        spinner fallDeleteSpin "Delete width:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox fallScaleCheck "Scale ramp" pos:[(CyrusUISize 8 1),918] width:(CyrusUISize 146 1)
        spinner fallScaleSpin "Scale width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),944] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallScaleEdit "Edit Scale Graph..." pos:[(CyrusUISize 8 1),974] width:(CyrusUISize 146 1)
        checkbox fallDensityCheck "Density ramp" pos:[(CyrusUISize 8 1),1010] width:(CyrusUISize 146 1)
        spinner fallDensitySpin "Density width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),1036] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallDensityEdit "Edit Density Graph..." pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1)
        label fallHelp "Ramps start after delete band. Each Area line has its own settings." pos:[(CyrusUISize 8 1),1104] width:(CyrusUISize 146 1) height:56
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
                if fallTarget.selection==1 or isValidNode n do (local cfg=obj.getFallConfig n;cfg[index]=value;obj.setFallConfig n cfg;redrawViews())
            )
        )
        on fallTarget selected v do syncFalloff()
        on fallPick picked n do (if CyrusAnalyzerFilter n do obj.fallAnalyzer=n;syncFalloff();redrawViews())
        on fallRemove pressed do (obj.fallAnalyzer=undefined;obj.fallDelete=false;obj.fallScale=false;obj.fallDensity=false;syncFalloff();redrawViews())
        on fallDeleteCheck changed v do setFallValue 1 v
        on fallDeleteSpin changed v do setFallValue 2 v
        on fallScaleCheck changed v do setFallValue 3 v
        on fallScaleSpin changed v do setFallValue 4 v
        on fallDensityCheck changed v do setFallValue 6 v
        on fallDensitySpin changed v do setFallValue 7 v
        on fallScaleEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) false
        on fallDensityEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) true

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

        on pickArea picked n do (addArea n;updateAreas();redrawViews())
        on addAreaScene pressed do (
            local nodes=selectByName title:"Cyrus Scatter - Closed Areas" buttonText:"Add" filter:AminScatterAreaFilter single:false
            if nodes!=undefined do for n in nodes do addArea n
            updateAreas();redrawViews()
        )
        on areaList selectionEnd do (
            if areaList.selection.numberSet==1 do fallTarget.selection=2
            syncFalloff()
            if areaList.selection.numberSet>0 do areaMode.state=obj.areaModes[(areaList.selection as array)[1]]
        )
        on areaMode changed mode do (
            undo "Cyrus Scatter area mode" on (for i in areaList.selection do obj.areaModes[i]=mode)
            obj.dirty=true;updateAreas();redrawViews()
        )
        on removeArea pressed do (
            if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()
            local rows=areaList.selection as array
            undo "Cyrus Scatter remove areas" on (
                obj.ensureAreaFalloffs()
                for i=rows.count to 1 by -1 do (deleteItem obj.areaNodes rows[i];deleteItem obj.areaModes rows[i];deleteItem obj.areaFallConfigs rows[i];deleteItem obj.areaFallScaleGraphs rows[i];deleteItem obj.areaFallDensityGraphs rows[i])
            )
            areaList.selection=#{};obj.dirty=true;updateAreas();redrawViews()
        )
        on refreshAreas pressed do (obj.dirty=true;obj.refreshPreview();redrawViews())

        on areaUI_3 rolledUp state do parentView.layoutPanels()
        on areaUI_3 open do (syncAnalyzerArea();syncFalloff();controlsReady=true;updateAreas())
    )
areaUI_3.obj=target;areaUI_3.parentView=view;areaUI_3
)
global CyrusMake_diversityUI_3
fn CyrusMake_diversityUI_3 target view = (
    CyrusUIBuildView=view
    rollout diversityUI_3 "Diversity / Colors" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false,strokeExpandedHeight=0
        on diversityUI_3 close do controlsReady=false
        radiobuttons diversityRadio "Source assignment" labels:#("Random","Clusters","Line Pattern","Analyze Surface") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner sizeSpin "Size: " range:[0.01,100000,10] type:#worldUnits fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),104]
        spinner divSeedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),130]
        spinner roughSpin "Roughness %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),156]
        spinner blurSpin "Blur edge %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),182]
        spinner noiseSpin "Noise %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),208]
        label groupHint "Uses source group colors." pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        label fixedHint "Point positions stay fixed." pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)



    
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),118] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),218] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),250] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),346] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),346] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),372] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),406] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),434] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),506] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),618] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),644] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),676] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),870] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),898] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),940] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),968] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),996] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),1024] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1094] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1122] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),874] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),756] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),784] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),730] width:(CyrusUISize 146 1)
        fn syncControls = (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;syncControls();redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;syncControls();redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on refreshGroups pressed do updatePattern()
                fn updateControls = (
            for c in #(sizeSpin,divSeedSpin,roughSpin,blurSpin,noiseSpin,groupHint,fixedHint) do c.visible=obj.diversityMode==2
            for c in #(strokeTitle,pathsDrop,analyzerChannel,pickAnalyzer,pickPath,removePath,strokesList,addOutside,addInside,removeStrokeButton,strokeWidth,strokeMode,strokeChoices,strokeScaleMin,strokeScaleMax,refreshGroups,strokeHelp) do c.visible=(obj.diversityMode==3 or obj.diversityMode==4)
            if strokeExpandedHeight>0 do diversityUI_3.height=if obj.diversityMode>=3 then strokeExpandedHeight else (if obj.diversityMode==2 then 310 else 124)*parentView.dpiScale
            parentView.layoutPanels()
        )
        on diversityRadio changed v do (obj.diversityMode=v;updateControls();updatePattern();obj.dirty=true;syncControls();redrawViews())


        on sizeSpin changed v do (obj.diversitySize=v;obj.dirty=true;syncControls();redrawViews())
        on divSeedSpin changed v do (obj.diversitySeed=v;obj.dirty=true;syncControls();redrawViews())
        on roughSpin changed v do (obj.roughness=v;obj.dirty=true;syncControls();redrawViews())
        on blurSpin changed v do (obj.blurryEdge=v;obj.dirty=true;syncControls();redrawViews())
        on noiseSpin changed v do (obj.diversityNoise=v;obj.dirty=true;syncControls();redrawViews())
        on diversityUI_3 rolledUp state do parentView.layoutPanels()
        on diversityUI_3 open do (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;controlsReady=true;strokeExpandedHeight=diversityUI_3.height;updateControls();updatePattern())
    )
diversityUI_3.obj=target;diversityUI_3.parentView=view;diversityUI_3
)
global CyrusMake_lineUI_3
fn CyrusMake_lineUI_3 target view = (
    CyrusUIBuildView=view
    rollout lineUI_3 "Line Pattern" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),108] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),140] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),236] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),236] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),262] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),296] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),324] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),396] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),508] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),534] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),566] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),594] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),830] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),858] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),914] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),956] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),984] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1012] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),764] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),646] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),674] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),620] width:(CyrusUISize 146 1)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;redrawViews())
        on refreshGroups pressed do updatePattern()

        on lineUI_3 rolledUp state do parentView.layoutPanels()
        on lineUI_3 open do updatePattern()
    )
lineUI_3.obj=target;lineUI_3.parentView=view;lineUI_3
)
global CyrusMake_randomUI_3
fn CyrusMake_randomUI_3 target view = (
    CyrusUIBuildView=view
    rollout randomUI_3 "Randomize XYZ" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on randomUI_3 close do controlsReady=false
        label rotTitle "Rotation (degrees)" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        label rotMinTitle "Min" pos:[(CyrusUISize 24 1),30] width:(CyrusUISize 58 1)
        label rotMaxTitle "Max" pos:[(CyrusUISize 94 1),30] width:(CyrusUISize 58 1)
        label rotXLabel "X" pos:[(CyrusUISize 8 1),52] width:(CyrusUISize 12 1)
        spinner rotXMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotXMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotYLabel "Y" pos:[(CyrusUISize 8 1),76] width:(CyrusUISize 12 1)
        spinner rotYMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotYMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotZLabel "Z" pos:[(CyrusUISize 8 1),100] width:(CyrusUISize 12 1)
        spinner rotZMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotZMaxSpin "" range:[-360,360,360]  pos:[(CyrusUISize 94 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclTitle "Scale (multiplier)" pos:[(CyrusUISize 8 1),132] width:(CyrusUISize 146 1)
        label sclMinTitle "Min" pos:[(CyrusUISize 24 1),154] width:(CyrusUISize 58 1)
        label sclMaxTitle "Max" pos:[(CyrusUISize 94 1),154] width:(CyrusUISize 58 1)
        label sclXLabel "X" pos:[(CyrusUISize 8 1),176] width:(CyrusUISize 12 1)
        spinner sclXMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclXMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclYLabel "Y" pos:[(CyrusUISize 8 1),200] width:(CyrusUISize 12 1)
        spinner sclYMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclYMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclZLabel "Z" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 12 1)
        spinner sclZMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclZMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label wholeTitle "Whole Scale (uniform)" pos:[(CyrusUISize 8 1),252] width:(CyrusUISize 146 1)
        label wholeMinTitle "Min" pos:[(CyrusUISize 24 1),274] width:(CyrusUISize 58 1)
        label wholeMaxTitle "Max" pos:[(CyrusUISize 94 1),274] width:(CyrusUISize 58 1)
        spinner wholeMinSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 24 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner wholeMaxSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 94 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        on wholeMinSpin changed v do (obj.wholeScaleMin=v;if v>obj.wholeScaleMax do (obj.wholeScaleMax=v;wholeMaxSpin.value=v);redrawViews())
        on wholeMaxSpin changed v do (obj.wholeScaleMax=v;if v<obj.wholeScaleMin do (obj.wholeScaleMin=v;wholeMinSpin.value=v);redrawViews())
        label movTitle "Movement (world units)" pos:[(CyrusUISize 8 1),332] width:(CyrusUISize 146 1)
        label movMinTitle "Min" pos:[(CyrusUISize 24 1),354] width:(CyrusUISize 58 1)
        label movMaxTitle "Max" pos:[(CyrusUISize 94 1),354] width:(CyrusUISize 58 1)
        label movXLabel "X" pos:[(CyrusUISize 8 1),376] width:(CyrusUISize 12 1)
        spinner movXMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movXMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movYLabel "Y" pos:[(CyrusUISize 8 1),400] width:(CyrusUISize 12 1)
        spinner movYMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movYMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movZLabel "Z" pos:[(CyrusUISize 8 1),424] width:(CyrusUISize 12 1)
        spinner movZMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movZMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        checkbox projectCheck "Keep on surface" pos:[(CyrusUISize 8 1),456] width:(CyrusUISize 146 1)
        checkbox alignCheck "Align to normal" pos:[(CyrusUISize 8 1),480] width:(CyrusUISize 146 1)

        fn syncControls = (projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;)
        on alignCheck changed v do (obj.alignNormal=v;obj.dirty=true;syncControls();redrawViews())

        on projectCheck changed v do (obj.projectMove=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMinSpin changed v do (obj.rotXMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMaxSpin changed v do (obj.rotXMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMinSpin changed v do (obj.rotYMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMaxSpin changed v do (obj.rotYMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMinSpin changed v do (obj.rotZMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMaxSpin changed v do (obj.rotZMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMinSpin changed v do (obj.sclXMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMaxSpin changed v do (obj.sclXMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMinSpin changed v do (obj.sclYMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMaxSpin changed v do (obj.sclYMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMinSpin changed v do (obj.sclZMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMaxSpin changed v do (obj.sclZMax=v;obj.dirty=true;syncControls();redrawViews())
        on movXMinSpin changed v do (obj.movXMin=v;obj.dirty=true;syncControls();redrawViews())
        on movXMaxSpin changed v do (obj.movXMax=v;obj.dirty=true;syncControls();redrawViews())
        on movYMinSpin changed v do (obj.movYMin=v;obj.dirty=true;syncControls();redrawViews())
        on movYMaxSpin changed v do (obj.movYMax=v;obj.dirty=true;syncControls();redrawViews())
        on movZMinSpin changed v do (obj.movZMin=v;obj.dirty=true;syncControls();redrawViews())
        on movZMaxSpin changed v do (obj.movZMax=v;obj.dirty=true;syncControls();redrawViews())
        on randomUI_3 rolledUp state do parentView.layoutPanels()
        on randomUI_3 open do (wholeMinSpin.value=obj.wholeScaleMin;wholeMaxSpin.value=obj.wholeScaleMax;projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;controlsReady=true;alignCheck.checked=obj.alignNormal)
    )
randomUI_3.obj=target;randomUI_3.parentView=view;randomUI_3
)
global CyrusMake_sourceUI_4
fn CyrusMake_sourceUI_4 target view = (
    CyrusUIBuildView=view
    rollout sourceUI_4 "Source Object" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on sourceUI_4 close do controlsReady=false
        local groupPalette=#()
        local loadingColor=false
        local focusedRow=0
        multiListBox plantList "Sources (Ctrl/Shift)" items:#() pos:[(CyrusUISize 8 1),8] height:6 width:(CyrusUISize 146 1)
        button selectFromScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton addPlant "Add: pick in viewport" pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button addSelected "Add selected objects" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        button removePlant "Remove selected rows" pos:[(CyrusUISize 8 1),212] width:(CyrusUISize 146 1)
        button selectPlant "Select sources" pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        button addPoint "Add Point" pos:[(CyrusUISize 8 1),264] width:(CyrusUISize 146 1)
        button addEmpty "Add Empty" pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        pickbutton replacePoint "Replace Point: pick object" filter:AminScatterSourceFilter pos:[(CyrusUISize 8 1),316] width:(CyrusUISize 146 1)
        label groupHeading "Cluster color group" pos:[(CyrusUISize 8 1),348] width:(CyrusUISize 146 1)
        dropdownlist existingGroups "Reuse a group" items:#() pos:[(CyrusUISize 8 1),371] width:(CyrusUISize 146 1)
        colorpicker groupColor "Color: " color:(color 100 220 120) pos:[(CyrusUISize 8 1),419] width:(CyrusUISize 146 1) modal:true notifyAfterAccept:true
        button applyColor "Apply to selected rows" pos:[(CyrusUISize 8 1),446] width:(CyrusUISize 146 1)
        label colorHelp "OK saves the selected color." pos:[(CyrusUISize 8 1),476] width:(CyrusUISize 146 1)
        spinner weightSpin "Weight: " range:[0,1,1] scale:0.01 pos:[(CyrusUISize 8 1),504] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        label weightHelp "0 = off; relative share" pos:[(CyrusUISize 8 1),530] width:(CyrusUISize 146 1)
        spinner sourceZSpin "Z Offset: " range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),556] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        spinner sourceScaleSpin "Scale: " range:[0,10000,1] scale:0.01 pos:[(CyrusUISize 8 1),582] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        label sourceTransformHelp "Scale: 1 = original" pos:[(CyrusUISize 8 1),608] width:(CyrusUISize 146 1)
        spinner radiusSourceSpin "Collision radius:" type:#worldunits range:[0,1e9,0] pos:[(CyrusUISize 8 1),686] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        checkbox followRadiusCheck "Follow Scale" pos:[(CyrusUISize 8 1),712] width:(CyrusUISize 146 1)
        checkbox showRadiusCheck "Show Radius" pos:[(CyrusUISize 8 1),738] width:(CyrusUISize 146 1)
        dropdownlist forwardAxis "Forward axis:" items:#("+Y","-Y","+X","-X") pos:[(CyrusUISize 8 1),634] width:(CyrusUISize 146 1)
        fn colorLabel c = ("#"+(formattedPrint (obj.colorKey c) format:"06X"))
        fn updateList = (
            local selectedRows=plantList.selection
            if selectedRows.numberSet==0 and obj.sources.count>0 do selectedRows=#{1}
            obj.syncColors()
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
            showSelectedColor();redrawViews()
        )
        on addPoint pressed do (
            local i=obj.addPointSource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on replacePoint picked n do (
            local rows=plantList.selection as array
            if rows.count!=1 then messageBox "Select one Point row to replace." title:"Cyrus Scatter"
            else if not (obj.replacePointSource rows[1] n) do messageBox "Select a Point row and an object that is not already in this source list." title:"Cyrus Scatter"
            replacePoint.text="Replace Point: pick object";updateList();showSelectedColor();redrawViews()
        )
        on addEmpty pressed do (
            local i=obj.addEmptySource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on radiusSourceSpin changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v;redrawViews())
        on followRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:2;redrawViews())
        on showRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:3;redrawViews())
        on forwardAxis selected v do if not loadingColor do (obj.assignSourceForward plantList.selection v;redrawViews())
        on sourceZSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v;redrawViews())
        on sourceScaleSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v scaling:true;redrawViews())
        on weightSpin changed v do if not loadingColor do (obj.assignWeight plantList.selection v;updateList();redrawViews())
        on plantList selected i do (
            if i>0 and plantList.selection[i] do focusedRow=i
        )
        on plantList selectionEnd do showSelectedColor()
        on existingGroups selected i do (
            if i>0 and i<=groupPalette.count do (
                local c=groupPalette[i]
                loadingColor=true;groupColor.color=c;loadingColor=false
                obj.assignGroup plantList.selection c;updateList();redrawViews()
            )
        )
        on groupColor changed c do (
            if not loadingColor and plantList.selection.numberSet>0 do (
                obj.assignGroup plantList.selection c
                updateList();redrawViews()
            )
        )
        on applyColor pressed do (
            obj.assignGroup plantList.selection groupColor.color
            updateList();redrawViews()
        )
        on selectFromScene pressed do (
            local picked=selectByName title:"Cyrus Scatter - Select From Scene" buttonText:"Add" filter:AminScatterSourceFilter single:false
            addSources picked
        )
        on addPlant picked n do addSources #(n)
        on addSelected pressed do addSources (selection as array)
        on removePlant pressed do (
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
            plantList.selection=#{};obj.dirty=true;updateList();redrawViews()
        )
        on selectPlant pressed do (
            local nodes=for i in plantList.selection where i<=obj.sources.count and isValidNode obj.sources[i] collect obj.sources[i]
            if nodes.count>0 do select nodes
        )

        on sourceUI_4 rolledUp state do parentView.layoutPanels()
        on sourceUI_4 open do (controlsReady=true;(updateList();showSelectedColor()))
    )
sourceUI_4.obj=target;sourceUI_4.parentView=view;sourceUI_4
)
global CyrusMake_distributionUI_4
fn CyrusMake_distributionUI_4 target view = (
    CyrusUIBuildView=view
    rollout distributionUI_4 "Point Generation" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on distributionUI_4 close do controlsReady=false
        radiobuttons modeRadio "Method" labels:#("Random","Texture Density") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        radiobuttons populationRadio "Population" labels:#("Count","Plants per m2") columns:1 pos:[(CyrusUISize 8 1),78] width:(CyrusUISize 146 1)
        checkbox showCenterCheck "Show Point" pos:[(CyrusUISize 8 1),148] width:(CyrusUISize 146 1)
        on showCenterCheck changed v do (obj.showCenters=v;redrawViews())
        spinner countSpin "Count: " range:[1,100000,200] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),174]
        spinner densitySpin "Per m2: " range:[0,1000000,100] fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),200]
        spinner seedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),226]
        label densityHeading "Texture density" pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)
        mapbutton densityButton "Choose density map" pos:[(CyrusUISize 8 1),284] width:(CyrusUISize 146 1)
        checkbox invertCheck "Invert density" pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        label uvHint "UV channel 1; 0..1" pos:[(CyrusUISize 8 1),338] width:(CyrusUISize 146 1)
        label mapHint "White: dense / Black: empty" pos:[(CyrusUISize 8 1),360] width:(CyrusUISize 146 1)

        fn syncControls = (populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;)
        on modeRadio changed v do (obj.distributionMode=if v==2 then 3 else 1;obj.dirty=true;syncControls();redrawViews())
        on countSpin changed v do (obj.amount=v;obj.dirty=true;syncControls();redrawViews())
        on seedSpin changed v do (obj.randomSeed=v;obj.dirty=true;syncControls();redrawViews())

        on populationRadio changed v do (obj.populationMode=v;obj.dirty=true;syncControls();redrawViews())
        on densitySpin changed v do (obj.plantsPerM2=v;obj.dirty=true;syncControls();redrawViews())
        on densityButton picked v do (obj.densityMap=v;obj.dirty=true;syncControls();redrawViews())
        on invertCheck changed v do (obj.invertDensity=v;obj.dirty=true;syncControls();redrawViews())
        on distributionUI_4 rolledUp state do parentView.layoutPanels()
        on distributionUI_4 open do (showCenterCheck.checked=obj.showCenters;populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;controlsReady=true;(countSpin.value=obj.amount;seedSpin.value=obj.randomSeed;modeRadio.state=if obj.distributionMode==3 then 2 else 1))
    )
distributionUI_4.obj=target;distributionUI_4.parentView=view;distributionUI_4
)
global CyrusMake_areaUI_4
fn CyrusMake_areaUI_4 target view = (
    CyrusUIBuildView=view
    rollout areaUI_4 "Area" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on areaUI_4 close do controlsReady=false
        multiListBox areaList "Closed lines / shapes" items:#() pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1) height:6
        button addAreaScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton pickArea "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button removeArea "Remove selected rows" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        radiobuttons areaMode "Selected area mode" labels:#("Include","Exclude") columns:1 pos:[(CyrusUISize 8 1),220] width:(CyrusUISize 146 1)
        label areaHint "Exclude overrides Include." pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        label projectionHint "Top / world XY projection." pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        button refreshAreas "Refresh areas / preview" pos:[(CyrusUISize 8 1),340] width:(CyrusUISize 146 1)
        local loadingAnalyzerArea=false
        label aaTitle "Surface Analyzer Area" pos:[(CyrusUISize 8 1),378] width:(CyrusUISize 146 1)
        pickbutton aaPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),404] width:(CyrusUISize 146 1)
        button aaRemove "Remove Area Analyzer" pos:[(CyrusUISize 8 1),432] width:(CyrusUISize 146 1)
        checkbox aaLine "Center Line" pos:[(CyrusUISize 8 1),464] width:(CyrusUISize 146 1)
        spinner aaWidth "Full width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),490] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        dropdownlist aaCaps "Line ends" items:#("Flat","Round") selection:1 pos:[(CyrusUISize 8 1),518] width:(CyrusUISize 146 1)
        spinner aaStreetOffset "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),572] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox aaPoints "Points" pos:[(CyrusUISize 8 1),604] width:(CyrusUISize 146 1)
        spinner aaRadius "Radius:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),630] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label aaHelp "XY mask. Both enabled = union. Works with Random / Clusters." pos:[(CyrusUISize 8 1),660] width:(CyrusUISize 146 1) height:40
        fn syncAnalyzerArea = (
            loadingAnalyzerArea=true
            aaPick.text=if isValidNode obj.areaAnalyzer then obj.areaAnalyzer.name else "Pick Surface Analyzer"
            aaLine.checked=obj.areaUseLine;aaPoints.checked=obj.areaUsePoints
            aaStreetOffset.value=obj.centerStreetOffset;aaStreetOffset.enabled=obj.areaUseLine
            aaWidth.value=obj.areaLineWidth;aaRadius.value=obj.areaPointRadius;aaCaps.selection=obj.areaLineCaps
            aaWidth.enabled=obj.areaUseLine;aaCaps.enabled=obj.areaUseLine;aaRadius.enabled=obj.areaUsePoints
            loadingAnalyzerArea=false
        )
        on aaPick picked n do (obj.areaAnalyzer=n;syncAnalyzerArea();redrawViews())
        on aaRemove pressed do (obj.areaUseLine=false;obj.areaUsePoints=false;obj.areaAnalyzer=undefined;syncAnalyzerArea();redrawViews())
        on aaLine changed v do if not loadingAnalyzerArea do (obj.areaUseLine=v;syncAnalyzerArea();redrawViews())
        on aaPoints changed v do if not loadingAnalyzerArea do (obj.areaUsePoints=v;syncAnalyzerArea();redrawViews())
        on aaStreetOffset changed v do if not loadingAnalyzerArea do (obj.centerStreetOffset=v;redrawViews())
        on aaWidth changed v do if not loadingAnalyzerArea do (obj.areaLineWidth=v;redrawViews())
        on aaRadius changed v do if not loadingAnalyzerArea do (obj.areaPointRadius=v;redrawViews())
        on aaCaps selected v do if not loadingAnalyzerArea do (obj.areaLineCaps=v;redrawViews())

        local loadingFall=false
        dropdownlist fallTarget "Edge falloff target" items:#("Analyzer Boundary","Selected Area line") selection:1 pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        pickbutton fallPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1)
        button fallRemove "Remove Analyzer" pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1)
        label fallTargetName "" pos:[(CyrusUISize 8 1),818] width:(CyrusUISize 146 1) height:40
        checkbox fallDeleteCheck "Delete edge band" pos:[(CyrusUISize 8 1),860] width:(CyrusUISize 146 1)
        spinner fallDeleteSpin "Delete width:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox fallScaleCheck "Scale ramp" pos:[(CyrusUISize 8 1),918] width:(CyrusUISize 146 1)
        spinner fallScaleSpin "Scale width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),944] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallScaleEdit "Edit Scale Graph..." pos:[(CyrusUISize 8 1),974] width:(CyrusUISize 146 1)
        checkbox fallDensityCheck "Density ramp" pos:[(CyrusUISize 8 1),1010] width:(CyrusUISize 146 1)
        spinner fallDensitySpin "Density width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),1036] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallDensityEdit "Edit Density Graph..." pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1)
        label fallHelp "Ramps start after delete band. Each Area line has its own settings." pos:[(CyrusUISize 8 1),1104] width:(CyrusUISize 146 1) height:56
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
                if fallTarget.selection==1 or isValidNode n do (local cfg=obj.getFallConfig n;cfg[index]=value;obj.setFallConfig n cfg;redrawViews())
            )
        )
        on fallTarget selected v do syncFalloff()
        on fallPick picked n do (if CyrusAnalyzerFilter n do obj.fallAnalyzer=n;syncFalloff();redrawViews())
        on fallRemove pressed do (obj.fallAnalyzer=undefined;obj.fallDelete=false;obj.fallScale=false;obj.fallDensity=false;syncFalloff();redrawViews())
        on fallDeleteCheck changed v do setFallValue 1 v
        on fallDeleteSpin changed v do setFallValue 2 v
        on fallScaleCheck changed v do setFallValue 3 v
        on fallScaleSpin changed v do setFallValue 4 v
        on fallDensityCheck changed v do setFallValue 6 v
        on fallDensitySpin changed v do setFallValue 7 v
        on fallScaleEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) false
        on fallDensityEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) true

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

        on pickArea picked n do (addArea n;updateAreas();redrawViews())
        on addAreaScene pressed do (
            local nodes=selectByName title:"Cyrus Scatter - Closed Areas" buttonText:"Add" filter:AminScatterAreaFilter single:false
            if nodes!=undefined do for n in nodes do addArea n
            updateAreas();redrawViews()
        )
        on areaList selectionEnd do (
            if areaList.selection.numberSet==1 do fallTarget.selection=2
            syncFalloff()
            if areaList.selection.numberSet>0 do areaMode.state=obj.areaModes[(areaList.selection as array)[1]]
        )
        on areaMode changed mode do (
            undo "Cyrus Scatter area mode" on (for i in areaList.selection do obj.areaModes[i]=mode)
            obj.dirty=true;updateAreas();redrawViews()
        )
        on removeArea pressed do (
            if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()
            local rows=areaList.selection as array
            undo "Cyrus Scatter remove areas" on (
                obj.ensureAreaFalloffs()
                for i=rows.count to 1 by -1 do (deleteItem obj.areaNodes rows[i];deleteItem obj.areaModes rows[i];deleteItem obj.areaFallConfigs rows[i];deleteItem obj.areaFallScaleGraphs rows[i];deleteItem obj.areaFallDensityGraphs rows[i])
            )
            areaList.selection=#{};obj.dirty=true;updateAreas();redrawViews()
        )
        on refreshAreas pressed do (obj.dirty=true;obj.refreshPreview();redrawViews())

        on areaUI_4 rolledUp state do parentView.layoutPanels()
        on areaUI_4 open do (syncAnalyzerArea();syncFalloff();controlsReady=true;updateAreas())
    )
areaUI_4.obj=target;areaUI_4.parentView=view;areaUI_4
)
global CyrusMake_diversityUI_4
fn CyrusMake_diversityUI_4 target view = (
    CyrusUIBuildView=view
    rollout diversityUI_4 "Diversity / Colors" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false,strokeExpandedHeight=0
        on diversityUI_4 close do controlsReady=false
        radiobuttons diversityRadio "Source assignment" labels:#("Random","Clusters","Line Pattern","Analyze Surface") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner sizeSpin "Size: " range:[0.01,100000,10] type:#worldUnits fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),104]
        spinner divSeedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),130]
        spinner roughSpin "Roughness %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),156]
        spinner blurSpin "Blur edge %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),182]
        spinner noiseSpin "Noise %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),208]
        label groupHint "Uses source group colors." pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        label fixedHint "Point positions stay fixed." pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)



    
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),118] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),218] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),250] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),346] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),346] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),372] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),406] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),434] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),506] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),618] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),644] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),676] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),870] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),898] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),940] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),968] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),996] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),1024] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1094] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1122] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),874] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),756] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),784] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),730] width:(CyrusUISize 146 1)
        fn syncControls = (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;syncControls();redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;syncControls();redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on refreshGroups pressed do updatePattern()
                fn updateControls = (
            for c in #(sizeSpin,divSeedSpin,roughSpin,blurSpin,noiseSpin,groupHint,fixedHint) do c.visible=obj.diversityMode==2
            for c in #(strokeTitle,pathsDrop,analyzerChannel,pickAnalyzer,pickPath,removePath,strokesList,addOutside,addInside,removeStrokeButton,strokeWidth,strokeMode,strokeChoices,strokeScaleMin,strokeScaleMax,refreshGroups,strokeHelp) do c.visible=(obj.diversityMode==3 or obj.diversityMode==4)
            if strokeExpandedHeight>0 do diversityUI_4.height=if obj.diversityMode>=3 then strokeExpandedHeight else (if obj.diversityMode==2 then 310 else 124)*parentView.dpiScale
            parentView.layoutPanels()
        )
        on diversityRadio changed v do (obj.diversityMode=v;updateControls();updatePattern();obj.dirty=true;syncControls();redrawViews())


        on sizeSpin changed v do (obj.diversitySize=v;obj.dirty=true;syncControls();redrawViews())
        on divSeedSpin changed v do (obj.diversitySeed=v;obj.dirty=true;syncControls();redrawViews())
        on roughSpin changed v do (obj.roughness=v;obj.dirty=true;syncControls();redrawViews())
        on blurSpin changed v do (obj.blurryEdge=v;obj.dirty=true;syncControls();redrawViews())
        on noiseSpin changed v do (obj.diversityNoise=v;obj.dirty=true;syncControls();redrawViews())
        on diversityUI_4 rolledUp state do parentView.layoutPanels()
        on diversityUI_4 open do (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;controlsReady=true;strokeExpandedHeight=diversityUI_4.height;updateControls();updatePattern())
    )
diversityUI_4.obj=target;diversityUI_4.parentView=view;diversityUI_4
)
global CyrusMake_lineUI_4
fn CyrusMake_lineUI_4 target view = (
    CyrusUIBuildView=view
    rollout lineUI_4 "Line Pattern" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),108] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),140] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),236] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),236] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),262] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),296] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),324] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),396] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),508] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),534] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),566] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),594] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),830] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),858] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),914] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),956] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),984] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1012] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),764] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),646] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),674] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),620] width:(CyrusUISize 146 1)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;redrawViews())
        on refreshGroups pressed do updatePattern()

        on lineUI_4 rolledUp state do parentView.layoutPanels()
        on lineUI_4 open do updatePattern()
    )
lineUI_4.obj=target;lineUI_4.parentView=view;lineUI_4
)
global CyrusMake_randomUI_4
fn CyrusMake_randomUI_4 target view = (
    CyrusUIBuildView=view
    rollout randomUI_4 "Randomize XYZ" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on randomUI_4 close do controlsReady=false
        label rotTitle "Rotation (degrees)" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        label rotMinTitle "Min" pos:[(CyrusUISize 24 1),30] width:(CyrusUISize 58 1)
        label rotMaxTitle "Max" pos:[(CyrusUISize 94 1),30] width:(CyrusUISize 58 1)
        label rotXLabel "X" pos:[(CyrusUISize 8 1),52] width:(CyrusUISize 12 1)
        spinner rotXMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotXMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotYLabel "Y" pos:[(CyrusUISize 8 1),76] width:(CyrusUISize 12 1)
        spinner rotYMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotYMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotZLabel "Z" pos:[(CyrusUISize 8 1),100] width:(CyrusUISize 12 1)
        spinner rotZMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotZMaxSpin "" range:[-360,360,360]  pos:[(CyrusUISize 94 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclTitle "Scale (multiplier)" pos:[(CyrusUISize 8 1),132] width:(CyrusUISize 146 1)
        label sclMinTitle "Min" pos:[(CyrusUISize 24 1),154] width:(CyrusUISize 58 1)
        label sclMaxTitle "Max" pos:[(CyrusUISize 94 1),154] width:(CyrusUISize 58 1)
        label sclXLabel "X" pos:[(CyrusUISize 8 1),176] width:(CyrusUISize 12 1)
        spinner sclXMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclXMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclYLabel "Y" pos:[(CyrusUISize 8 1),200] width:(CyrusUISize 12 1)
        spinner sclYMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclYMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclZLabel "Z" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 12 1)
        spinner sclZMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclZMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label wholeTitle "Whole Scale (uniform)" pos:[(CyrusUISize 8 1),252] width:(CyrusUISize 146 1)
        label wholeMinTitle "Min" pos:[(CyrusUISize 24 1),274] width:(CyrusUISize 58 1)
        label wholeMaxTitle "Max" pos:[(CyrusUISize 94 1),274] width:(CyrusUISize 58 1)
        spinner wholeMinSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 24 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner wholeMaxSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 94 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        on wholeMinSpin changed v do (obj.wholeScaleMin=v;if v>obj.wholeScaleMax do (obj.wholeScaleMax=v;wholeMaxSpin.value=v);redrawViews())
        on wholeMaxSpin changed v do (obj.wholeScaleMax=v;if v<obj.wholeScaleMin do (obj.wholeScaleMin=v;wholeMinSpin.value=v);redrawViews())
        label movTitle "Movement (world units)" pos:[(CyrusUISize 8 1),332] width:(CyrusUISize 146 1)
        label movMinTitle "Min" pos:[(CyrusUISize 24 1),354] width:(CyrusUISize 58 1)
        label movMaxTitle "Max" pos:[(CyrusUISize 94 1),354] width:(CyrusUISize 58 1)
        label movXLabel "X" pos:[(CyrusUISize 8 1),376] width:(CyrusUISize 12 1)
        spinner movXMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movXMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movYLabel "Y" pos:[(CyrusUISize 8 1),400] width:(CyrusUISize 12 1)
        spinner movYMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movYMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movZLabel "Z" pos:[(CyrusUISize 8 1),424] width:(CyrusUISize 12 1)
        spinner movZMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movZMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        checkbox projectCheck "Keep on surface" pos:[(CyrusUISize 8 1),456] width:(CyrusUISize 146 1)
        checkbox alignCheck "Align to normal" pos:[(CyrusUISize 8 1),480] width:(CyrusUISize 146 1)

        fn syncControls = (projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;)
        on alignCheck changed v do (obj.alignNormal=v;obj.dirty=true;syncControls();redrawViews())

        on projectCheck changed v do (obj.projectMove=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMinSpin changed v do (obj.rotXMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMaxSpin changed v do (obj.rotXMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMinSpin changed v do (obj.rotYMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMaxSpin changed v do (obj.rotYMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMinSpin changed v do (obj.rotZMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMaxSpin changed v do (obj.rotZMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMinSpin changed v do (obj.sclXMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMaxSpin changed v do (obj.sclXMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMinSpin changed v do (obj.sclYMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMaxSpin changed v do (obj.sclYMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMinSpin changed v do (obj.sclZMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMaxSpin changed v do (obj.sclZMax=v;obj.dirty=true;syncControls();redrawViews())
        on movXMinSpin changed v do (obj.movXMin=v;obj.dirty=true;syncControls();redrawViews())
        on movXMaxSpin changed v do (obj.movXMax=v;obj.dirty=true;syncControls();redrawViews())
        on movYMinSpin changed v do (obj.movYMin=v;obj.dirty=true;syncControls();redrawViews())
        on movYMaxSpin changed v do (obj.movYMax=v;obj.dirty=true;syncControls();redrawViews())
        on movZMinSpin changed v do (obj.movZMin=v;obj.dirty=true;syncControls();redrawViews())
        on movZMaxSpin changed v do (obj.movZMax=v;obj.dirty=true;syncControls();redrawViews())
        on randomUI_4 rolledUp state do parentView.layoutPanels()
        on randomUI_4 open do (wholeMinSpin.value=obj.wholeScaleMin;wholeMaxSpin.value=obj.wholeScaleMax;projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;controlsReady=true;alignCheck.checked=obj.alignNormal)
    )
randomUI_4.obj=target;randomUI_4.parentView=view;randomUI_4
)
global CyrusMake_sourceUI_5
fn CyrusMake_sourceUI_5 target view = (
    CyrusUIBuildView=view
    rollout sourceUI_5 "Source Object" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on sourceUI_5 close do controlsReady=false
        local groupPalette=#()
        local loadingColor=false
        local focusedRow=0
        multiListBox plantList "Sources (Ctrl/Shift)" items:#() pos:[(CyrusUISize 8 1),8] height:6 width:(CyrusUISize 146 1)
        button selectFromScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton addPlant "Add: pick in viewport" pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button addSelected "Add selected objects" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        button removePlant "Remove selected rows" pos:[(CyrusUISize 8 1),212] width:(CyrusUISize 146 1)
        button selectPlant "Select sources" pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        button addPoint "Add Point" pos:[(CyrusUISize 8 1),264] width:(CyrusUISize 146 1)
        button addEmpty "Add Empty" pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        pickbutton replacePoint "Replace Point: pick object" filter:AminScatterSourceFilter pos:[(CyrusUISize 8 1),316] width:(CyrusUISize 146 1)
        label groupHeading "Cluster color group" pos:[(CyrusUISize 8 1),348] width:(CyrusUISize 146 1)
        dropdownlist existingGroups "Reuse a group" items:#() pos:[(CyrusUISize 8 1),371] width:(CyrusUISize 146 1)
        colorpicker groupColor "Color: " color:(color 100 220 120) pos:[(CyrusUISize 8 1),419] width:(CyrusUISize 146 1) modal:true notifyAfterAccept:true
        button applyColor "Apply to selected rows" pos:[(CyrusUISize 8 1),446] width:(CyrusUISize 146 1)
        label colorHelp "OK saves the selected color." pos:[(CyrusUISize 8 1),476] width:(CyrusUISize 146 1)
        spinner weightSpin "Weight: " range:[0,1,1] scale:0.01 pos:[(CyrusUISize 8 1),504] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        label weightHelp "0 = off; relative share" pos:[(CyrusUISize 8 1),530] width:(CyrusUISize 146 1)
        spinner sourceZSpin "Z Offset: " range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),556] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        spinner sourceScaleSpin "Scale: " range:[0,10000,1] scale:0.01 pos:[(CyrusUISize 8 1),582] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        label sourceTransformHelp "Scale: 1 = original" pos:[(CyrusUISize 8 1),608] width:(CyrusUISize 146 1)
        spinner radiusSourceSpin "Collision radius:" type:#worldunits range:[0,1e9,0] pos:[(CyrusUISize 8 1),686] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        checkbox followRadiusCheck "Follow Scale" pos:[(CyrusUISize 8 1),712] width:(CyrusUISize 146 1)
        checkbox showRadiusCheck "Show Radius" pos:[(CyrusUISize 8 1),738] width:(CyrusUISize 146 1)
        dropdownlist forwardAxis "Forward axis:" items:#("+Y","-Y","+X","-X") pos:[(CyrusUISize 8 1),634] width:(CyrusUISize 146 1)
        fn colorLabel c = ("#"+(formattedPrint (obj.colorKey c) format:"06X"))
        fn updateList = (
            local selectedRows=plantList.selection
            if selectedRows.numberSet==0 and obj.sources.count>0 do selectedRows=#{1}
            obj.syncColors()
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
            showSelectedColor();redrawViews()
        )
        on addPoint pressed do (
            local i=obj.addPointSource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on replacePoint picked n do (
            local rows=plantList.selection as array
            if rows.count!=1 then messageBox "Select one Point row to replace." title:"Cyrus Scatter"
            else if not (obj.replacePointSource rows[1] n) do messageBox "Select a Point row and an object that is not already in this source list." title:"Cyrus Scatter"
            replacePoint.text="Replace Point: pick object";updateList();showSelectedColor();redrawViews()
        )
        on addEmpty pressed do (
            local i=obj.addEmptySource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on radiusSourceSpin changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v;redrawViews())
        on followRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:2;redrawViews())
        on showRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:3;redrawViews())
        on forwardAxis selected v do if not loadingColor do (obj.assignSourceForward plantList.selection v;redrawViews())
        on sourceZSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v;redrawViews())
        on sourceScaleSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v scaling:true;redrawViews())
        on weightSpin changed v do if not loadingColor do (obj.assignWeight plantList.selection v;updateList();redrawViews())
        on plantList selected i do (
            if i>0 and plantList.selection[i] do focusedRow=i
        )
        on plantList selectionEnd do showSelectedColor()
        on existingGroups selected i do (
            if i>0 and i<=groupPalette.count do (
                local c=groupPalette[i]
                loadingColor=true;groupColor.color=c;loadingColor=false
                obj.assignGroup plantList.selection c;updateList();redrawViews()
            )
        )
        on groupColor changed c do (
            if not loadingColor and plantList.selection.numberSet>0 do (
                obj.assignGroup plantList.selection c
                updateList();redrawViews()
            )
        )
        on applyColor pressed do (
            obj.assignGroup plantList.selection groupColor.color
            updateList();redrawViews()
        )
        on selectFromScene pressed do (
            local picked=selectByName title:"Cyrus Scatter - Select From Scene" buttonText:"Add" filter:AminScatterSourceFilter single:false
            addSources picked
        )
        on addPlant picked n do addSources #(n)
        on addSelected pressed do addSources (selection as array)
        on removePlant pressed do (
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
            plantList.selection=#{};obj.dirty=true;updateList();redrawViews()
        )
        on selectPlant pressed do (
            local nodes=for i in plantList.selection where i<=obj.sources.count and isValidNode obj.sources[i] collect obj.sources[i]
            if nodes.count>0 do select nodes
        )

        on sourceUI_5 rolledUp state do parentView.layoutPanels()
        on sourceUI_5 open do (controlsReady=true;(updateList();showSelectedColor()))
    )
sourceUI_5.obj=target;sourceUI_5.parentView=view;sourceUI_5
)
global CyrusMake_distributionUI_5
fn CyrusMake_distributionUI_5 target view = (
    CyrusUIBuildView=view
    rollout distributionUI_5 "Point Generation" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on distributionUI_5 close do controlsReady=false
        radiobuttons modeRadio "Method" labels:#("Random","Texture Density") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        radiobuttons populationRadio "Population" labels:#("Count","Plants per m2") columns:1 pos:[(CyrusUISize 8 1),78] width:(CyrusUISize 146 1)
        checkbox showCenterCheck "Show Point" pos:[(CyrusUISize 8 1),148] width:(CyrusUISize 146 1)
        on showCenterCheck changed v do (obj.showCenters=v;redrawViews())
        spinner countSpin "Count: " range:[1,100000,200] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),174]
        spinner densitySpin "Per m2: " range:[0,1000000,100] fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),200]
        spinner seedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),226]
        label densityHeading "Texture density" pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)
        mapbutton densityButton "Choose density map" pos:[(CyrusUISize 8 1),284] width:(CyrusUISize 146 1)
        checkbox invertCheck "Invert density" pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        label uvHint "UV channel 1; 0..1" pos:[(CyrusUISize 8 1),338] width:(CyrusUISize 146 1)
        label mapHint "White: dense / Black: empty" pos:[(CyrusUISize 8 1),360] width:(CyrusUISize 146 1)

        fn syncControls = (populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;)
        on modeRadio changed v do (obj.distributionMode=if v==2 then 3 else 1;obj.dirty=true;syncControls();redrawViews())
        on countSpin changed v do (obj.amount=v;obj.dirty=true;syncControls();redrawViews())
        on seedSpin changed v do (obj.randomSeed=v;obj.dirty=true;syncControls();redrawViews())

        on populationRadio changed v do (obj.populationMode=v;obj.dirty=true;syncControls();redrawViews())
        on densitySpin changed v do (obj.plantsPerM2=v;obj.dirty=true;syncControls();redrawViews())
        on densityButton picked v do (obj.densityMap=v;obj.dirty=true;syncControls();redrawViews())
        on invertCheck changed v do (obj.invertDensity=v;obj.dirty=true;syncControls();redrawViews())
        on distributionUI_5 rolledUp state do parentView.layoutPanels()
        on distributionUI_5 open do (showCenterCheck.checked=obj.showCenters;populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;controlsReady=true;(countSpin.value=obj.amount;seedSpin.value=obj.randomSeed;modeRadio.state=if obj.distributionMode==3 then 2 else 1))
    )
distributionUI_5.obj=target;distributionUI_5.parentView=view;distributionUI_5
)
global CyrusMake_areaUI_5
fn CyrusMake_areaUI_5 target view = (
    CyrusUIBuildView=view
    rollout areaUI_5 "Area" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on areaUI_5 close do controlsReady=false
        multiListBox areaList "Closed lines / shapes" items:#() pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1) height:6
        button addAreaScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton pickArea "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button removeArea "Remove selected rows" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        radiobuttons areaMode "Selected area mode" labels:#("Include","Exclude") columns:1 pos:[(CyrusUISize 8 1),220] width:(CyrusUISize 146 1)
        label areaHint "Exclude overrides Include." pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        label projectionHint "Top / world XY projection." pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        button refreshAreas "Refresh areas / preview" pos:[(CyrusUISize 8 1),340] width:(CyrusUISize 146 1)
        local loadingAnalyzerArea=false
        label aaTitle "Surface Analyzer Area" pos:[(CyrusUISize 8 1),378] width:(CyrusUISize 146 1)
        pickbutton aaPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),404] width:(CyrusUISize 146 1)
        button aaRemove "Remove Area Analyzer" pos:[(CyrusUISize 8 1),432] width:(CyrusUISize 146 1)
        checkbox aaLine "Center Line" pos:[(CyrusUISize 8 1),464] width:(CyrusUISize 146 1)
        spinner aaWidth "Full width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),490] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        dropdownlist aaCaps "Line ends" items:#("Flat","Round") selection:1 pos:[(CyrusUISize 8 1),518] width:(CyrusUISize 146 1)
        spinner aaStreetOffset "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),572] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox aaPoints "Points" pos:[(CyrusUISize 8 1),604] width:(CyrusUISize 146 1)
        spinner aaRadius "Radius:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),630] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label aaHelp "XY mask. Both enabled = union. Works with Random / Clusters." pos:[(CyrusUISize 8 1),660] width:(CyrusUISize 146 1) height:40
        fn syncAnalyzerArea = (
            loadingAnalyzerArea=true
            aaPick.text=if isValidNode obj.areaAnalyzer then obj.areaAnalyzer.name else "Pick Surface Analyzer"
            aaLine.checked=obj.areaUseLine;aaPoints.checked=obj.areaUsePoints
            aaStreetOffset.value=obj.centerStreetOffset;aaStreetOffset.enabled=obj.areaUseLine
            aaWidth.value=obj.areaLineWidth;aaRadius.value=obj.areaPointRadius;aaCaps.selection=obj.areaLineCaps
            aaWidth.enabled=obj.areaUseLine;aaCaps.enabled=obj.areaUseLine;aaRadius.enabled=obj.areaUsePoints
            loadingAnalyzerArea=false
        )
        on aaPick picked n do (obj.areaAnalyzer=n;syncAnalyzerArea();redrawViews())
        on aaRemove pressed do (obj.areaUseLine=false;obj.areaUsePoints=false;obj.areaAnalyzer=undefined;syncAnalyzerArea();redrawViews())
        on aaLine changed v do if not loadingAnalyzerArea do (obj.areaUseLine=v;syncAnalyzerArea();redrawViews())
        on aaPoints changed v do if not loadingAnalyzerArea do (obj.areaUsePoints=v;syncAnalyzerArea();redrawViews())
        on aaStreetOffset changed v do if not loadingAnalyzerArea do (obj.centerStreetOffset=v;redrawViews())
        on aaWidth changed v do if not loadingAnalyzerArea do (obj.areaLineWidth=v;redrawViews())
        on aaRadius changed v do if not loadingAnalyzerArea do (obj.areaPointRadius=v;redrawViews())
        on aaCaps selected v do if not loadingAnalyzerArea do (obj.areaLineCaps=v;redrawViews())

        local loadingFall=false
        dropdownlist fallTarget "Edge falloff target" items:#("Analyzer Boundary","Selected Area line") selection:1 pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        pickbutton fallPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1)
        button fallRemove "Remove Analyzer" pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1)
        label fallTargetName "" pos:[(CyrusUISize 8 1),818] width:(CyrusUISize 146 1) height:40
        checkbox fallDeleteCheck "Delete edge band" pos:[(CyrusUISize 8 1),860] width:(CyrusUISize 146 1)
        spinner fallDeleteSpin "Delete width:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox fallScaleCheck "Scale ramp" pos:[(CyrusUISize 8 1),918] width:(CyrusUISize 146 1)
        spinner fallScaleSpin "Scale width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),944] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallScaleEdit "Edit Scale Graph..." pos:[(CyrusUISize 8 1),974] width:(CyrusUISize 146 1)
        checkbox fallDensityCheck "Density ramp" pos:[(CyrusUISize 8 1),1010] width:(CyrusUISize 146 1)
        spinner fallDensitySpin "Density width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),1036] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallDensityEdit "Edit Density Graph..." pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1)
        label fallHelp "Ramps start after delete band. Each Area line has its own settings." pos:[(CyrusUISize 8 1),1104] width:(CyrusUISize 146 1) height:56
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
                if fallTarget.selection==1 or isValidNode n do (local cfg=obj.getFallConfig n;cfg[index]=value;obj.setFallConfig n cfg;redrawViews())
            )
        )
        on fallTarget selected v do syncFalloff()
        on fallPick picked n do (if CyrusAnalyzerFilter n do obj.fallAnalyzer=n;syncFalloff();redrawViews())
        on fallRemove pressed do (obj.fallAnalyzer=undefined;obj.fallDelete=false;obj.fallScale=false;obj.fallDensity=false;syncFalloff();redrawViews())
        on fallDeleteCheck changed v do setFallValue 1 v
        on fallDeleteSpin changed v do setFallValue 2 v
        on fallScaleCheck changed v do setFallValue 3 v
        on fallScaleSpin changed v do setFallValue 4 v
        on fallDensityCheck changed v do setFallValue 6 v
        on fallDensitySpin changed v do setFallValue 7 v
        on fallScaleEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) false
        on fallDensityEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) true

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

        on pickArea picked n do (addArea n;updateAreas();redrawViews())
        on addAreaScene pressed do (
            local nodes=selectByName title:"Cyrus Scatter - Closed Areas" buttonText:"Add" filter:AminScatterAreaFilter single:false
            if nodes!=undefined do for n in nodes do addArea n
            updateAreas();redrawViews()
        )
        on areaList selectionEnd do (
            if areaList.selection.numberSet==1 do fallTarget.selection=2
            syncFalloff()
            if areaList.selection.numberSet>0 do areaMode.state=obj.areaModes[(areaList.selection as array)[1]]
        )
        on areaMode changed mode do (
            undo "Cyrus Scatter area mode" on (for i in areaList.selection do obj.areaModes[i]=mode)
            obj.dirty=true;updateAreas();redrawViews()
        )
        on removeArea pressed do (
            if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()
            local rows=areaList.selection as array
            undo "Cyrus Scatter remove areas" on (
                obj.ensureAreaFalloffs()
                for i=rows.count to 1 by -1 do (deleteItem obj.areaNodes rows[i];deleteItem obj.areaModes rows[i];deleteItem obj.areaFallConfigs rows[i];deleteItem obj.areaFallScaleGraphs rows[i];deleteItem obj.areaFallDensityGraphs rows[i])
            )
            areaList.selection=#{};obj.dirty=true;updateAreas();redrawViews()
        )
        on refreshAreas pressed do (obj.dirty=true;obj.refreshPreview();redrawViews())

        on areaUI_5 rolledUp state do parentView.layoutPanels()
        on areaUI_5 open do (syncAnalyzerArea();syncFalloff();controlsReady=true;updateAreas())
    )
areaUI_5.obj=target;areaUI_5.parentView=view;areaUI_5
)
global CyrusMake_diversityUI_5
fn CyrusMake_diversityUI_5 target view = (
    CyrusUIBuildView=view
    rollout diversityUI_5 "Diversity / Colors" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false,strokeExpandedHeight=0
        on diversityUI_5 close do controlsReady=false
        radiobuttons diversityRadio "Source assignment" labels:#("Random","Clusters","Line Pattern","Analyze Surface") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner sizeSpin "Size: " range:[0.01,100000,10] type:#worldUnits fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),104]
        spinner divSeedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),130]
        spinner roughSpin "Roughness %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),156]
        spinner blurSpin "Blur edge %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),182]
        spinner noiseSpin "Noise %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),208]
        label groupHint "Uses source group colors." pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        label fixedHint "Point positions stay fixed." pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)



    
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),118] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),218] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),250] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),346] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),346] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),372] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),406] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),434] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),506] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),618] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),644] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),676] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),870] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),898] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),940] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),968] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),996] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),1024] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1094] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1122] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),874] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),756] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),784] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),730] width:(CyrusUISize 146 1)
        fn syncControls = (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;syncControls();redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;syncControls();redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on refreshGroups pressed do updatePattern()
                fn updateControls = (
            for c in #(sizeSpin,divSeedSpin,roughSpin,blurSpin,noiseSpin,groupHint,fixedHint) do c.visible=obj.diversityMode==2
            for c in #(strokeTitle,pathsDrop,analyzerChannel,pickAnalyzer,pickPath,removePath,strokesList,addOutside,addInside,removeStrokeButton,strokeWidth,strokeMode,strokeChoices,strokeScaleMin,strokeScaleMax,refreshGroups,strokeHelp) do c.visible=(obj.diversityMode==3 or obj.diversityMode==4)
            if strokeExpandedHeight>0 do diversityUI_5.height=if obj.diversityMode>=3 then strokeExpandedHeight else (if obj.diversityMode==2 then 310 else 124)*parentView.dpiScale
            parentView.layoutPanels()
        )
        on diversityRadio changed v do (obj.diversityMode=v;updateControls();updatePattern();obj.dirty=true;syncControls();redrawViews())


        on sizeSpin changed v do (obj.diversitySize=v;obj.dirty=true;syncControls();redrawViews())
        on divSeedSpin changed v do (obj.diversitySeed=v;obj.dirty=true;syncControls();redrawViews())
        on roughSpin changed v do (obj.roughness=v;obj.dirty=true;syncControls();redrawViews())
        on blurSpin changed v do (obj.blurryEdge=v;obj.dirty=true;syncControls();redrawViews())
        on noiseSpin changed v do (obj.diversityNoise=v;obj.dirty=true;syncControls();redrawViews())
        on diversityUI_5 rolledUp state do parentView.layoutPanels()
        on diversityUI_5 open do (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;controlsReady=true;strokeExpandedHeight=diversityUI_5.height;updateControls();updatePattern())
    )
diversityUI_5.obj=target;diversityUI_5.parentView=view;diversityUI_5
)
global CyrusMake_lineUI_5
fn CyrusMake_lineUI_5 target view = (
    CyrusUIBuildView=view
    rollout lineUI_5 "Line Pattern" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),108] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),140] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),236] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),236] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),262] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),296] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),324] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),396] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),508] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),534] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),566] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),594] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),830] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),858] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),914] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),956] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),984] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1012] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),764] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),646] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),674] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),620] width:(CyrusUISize 146 1)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;redrawViews())
        on refreshGroups pressed do updatePattern()

        on lineUI_5 rolledUp state do parentView.layoutPanels()
        on lineUI_5 open do updatePattern()
    )
lineUI_5.obj=target;lineUI_5.parentView=view;lineUI_5
)
global CyrusMake_randomUI_5
fn CyrusMake_randomUI_5 target view = (
    CyrusUIBuildView=view
    rollout randomUI_5 "Randomize XYZ" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on randomUI_5 close do controlsReady=false
        label rotTitle "Rotation (degrees)" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        label rotMinTitle "Min" pos:[(CyrusUISize 24 1),30] width:(CyrusUISize 58 1)
        label rotMaxTitle "Max" pos:[(CyrusUISize 94 1),30] width:(CyrusUISize 58 1)
        label rotXLabel "X" pos:[(CyrusUISize 8 1),52] width:(CyrusUISize 12 1)
        spinner rotXMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotXMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotYLabel "Y" pos:[(CyrusUISize 8 1),76] width:(CyrusUISize 12 1)
        spinner rotYMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotYMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotZLabel "Z" pos:[(CyrusUISize 8 1),100] width:(CyrusUISize 12 1)
        spinner rotZMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotZMaxSpin "" range:[-360,360,360]  pos:[(CyrusUISize 94 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclTitle "Scale (multiplier)" pos:[(CyrusUISize 8 1),132] width:(CyrusUISize 146 1)
        label sclMinTitle "Min" pos:[(CyrusUISize 24 1),154] width:(CyrusUISize 58 1)
        label sclMaxTitle "Max" pos:[(CyrusUISize 94 1),154] width:(CyrusUISize 58 1)
        label sclXLabel "X" pos:[(CyrusUISize 8 1),176] width:(CyrusUISize 12 1)
        spinner sclXMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclXMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclYLabel "Y" pos:[(CyrusUISize 8 1),200] width:(CyrusUISize 12 1)
        spinner sclYMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclYMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclZLabel "Z" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 12 1)
        spinner sclZMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclZMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label wholeTitle "Whole Scale (uniform)" pos:[(CyrusUISize 8 1),252] width:(CyrusUISize 146 1)
        label wholeMinTitle "Min" pos:[(CyrusUISize 24 1),274] width:(CyrusUISize 58 1)
        label wholeMaxTitle "Max" pos:[(CyrusUISize 94 1),274] width:(CyrusUISize 58 1)
        spinner wholeMinSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 24 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner wholeMaxSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 94 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        on wholeMinSpin changed v do (obj.wholeScaleMin=v;if v>obj.wholeScaleMax do (obj.wholeScaleMax=v;wholeMaxSpin.value=v);redrawViews())
        on wholeMaxSpin changed v do (obj.wholeScaleMax=v;if v<obj.wholeScaleMin do (obj.wholeScaleMin=v;wholeMinSpin.value=v);redrawViews())
        label movTitle "Movement (world units)" pos:[(CyrusUISize 8 1),332] width:(CyrusUISize 146 1)
        label movMinTitle "Min" pos:[(CyrusUISize 24 1),354] width:(CyrusUISize 58 1)
        label movMaxTitle "Max" pos:[(CyrusUISize 94 1),354] width:(CyrusUISize 58 1)
        label movXLabel "X" pos:[(CyrusUISize 8 1),376] width:(CyrusUISize 12 1)
        spinner movXMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movXMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movYLabel "Y" pos:[(CyrusUISize 8 1),400] width:(CyrusUISize 12 1)
        spinner movYMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movYMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movZLabel "Z" pos:[(CyrusUISize 8 1),424] width:(CyrusUISize 12 1)
        spinner movZMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movZMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        checkbox projectCheck "Keep on surface" pos:[(CyrusUISize 8 1),456] width:(CyrusUISize 146 1)
        checkbox alignCheck "Align to normal" pos:[(CyrusUISize 8 1),480] width:(CyrusUISize 146 1)

        fn syncControls = (projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;)
        on alignCheck changed v do (obj.alignNormal=v;obj.dirty=true;syncControls();redrawViews())

        on projectCheck changed v do (obj.projectMove=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMinSpin changed v do (obj.rotXMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMaxSpin changed v do (obj.rotXMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMinSpin changed v do (obj.rotYMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMaxSpin changed v do (obj.rotYMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMinSpin changed v do (obj.rotZMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMaxSpin changed v do (obj.rotZMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMinSpin changed v do (obj.sclXMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMaxSpin changed v do (obj.sclXMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMinSpin changed v do (obj.sclYMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMaxSpin changed v do (obj.sclYMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMinSpin changed v do (obj.sclZMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMaxSpin changed v do (obj.sclZMax=v;obj.dirty=true;syncControls();redrawViews())
        on movXMinSpin changed v do (obj.movXMin=v;obj.dirty=true;syncControls();redrawViews())
        on movXMaxSpin changed v do (obj.movXMax=v;obj.dirty=true;syncControls();redrawViews())
        on movYMinSpin changed v do (obj.movYMin=v;obj.dirty=true;syncControls();redrawViews())
        on movYMaxSpin changed v do (obj.movYMax=v;obj.dirty=true;syncControls();redrawViews())
        on movZMinSpin changed v do (obj.movZMin=v;obj.dirty=true;syncControls();redrawViews())
        on movZMaxSpin changed v do (obj.movZMax=v;obj.dirty=true;syncControls();redrawViews())
        on randomUI_5 rolledUp state do parentView.layoutPanels()
        on randomUI_5 open do (wholeMinSpin.value=obj.wholeScaleMin;wholeMaxSpin.value=obj.wholeScaleMax;projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;controlsReady=true;alignCheck.checked=obj.alignNormal)
    )
randomUI_5.obj=target;randomUI_5.parentView=view;randomUI_5
)
global CyrusMake_sourceUI_6
fn CyrusMake_sourceUI_6 target view = (
    CyrusUIBuildView=view
    rollout sourceUI_6 "Source Object" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on sourceUI_6 close do controlsReady=false
        local groupPalette=#()
        local loadingColor=false
        local focusedRow=0
        multiListBox plantList "Sources (Ctrl/Shift)" items:#() pos:[(CyrusUISize 8 1),8] height:6 width:(CyrusUISize 146 1)
        button selectFromScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton addPlant "Add: pick in viewport" pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button addSelected "Add selected objects" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        button removePlant "Remove selected rows" pos:[(CyrusUISize 8 1),212] width:(CyrusUISize 146 1)
        button selectPlant "Select sources" pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        button addPoint "Add Point" pos:[(CyrusUISize 8 1),264] width:(CyrusUISize 146 1)
        button addEmpty "Add Empty" pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        pickbutton replacePoint "Replace Point: pick object" filter:AminScatterSourceFilter pos:[(CyrusUISize 8 1),316] width:(CyrusUISize 146 1)
        label groupHeading "Cluster color group" pos:[(CyrusUISize 8 1),348] width:(CyrusUISize 146 1)
        dropdownlist existingGroups "Reuse a group" items:#() pos:[(CyrusUISize 8 1),371] width:(CyrusUISize 146 1)
        colorpicker groupColor "Color: " color:(color 100 220 120) pos:[(CyrusUISize 8 1),419] width:(CyrusUISize 146 1) modal:true notifyAfterAccept:true
        button applyColor "Apply to selected rows" pos:[(CyrusUISize 8 1),446] width:(CyrusUISize 146 1)
        label colorHelp "OK saves the selected color." pos:[(CyrusUISize 8 1),476] width:(CyrusUISize 146 1)
        spinner weightSpin "Weight: " range:[0,1,1] scale:0.01 pos:[(CyrusUISize 8 1),504] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        label weightHelp "0 = off; relative share" pos:[(CyrusUISize 8 1),530] width:(CyrusUISize 146 1)
        spinner sourceZSpin "Z Offset: " range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),556] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        spinner sourceScaleSpin "Scale: " range:[0,10000,1] scale:0.01 pos:[(CyrusUISize 8 1),582] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        label sourceTransformHelp "Scale: 1 = original" pos:[(CyrusUISize 8 1),608] width:(CyrusUISize 146 1)
        spinner radiusSourceSpin "Collision radius:" type:#worldunits range:[0,1e9,0] pos:[(CyrusUISize 8 1),686] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        checkbox followRadiusCheck "Follow Scale" pos:[(CyrusUISize 8 1),712] width:(CyrusUISize 146 1)
        checkbox showRadiusCheck "Show Radius" pos:[(CyrusUISize 8 1),738] width:(CyrusUISize 146 1)
        dropdownlist forwardAxis "Forward axis:" items:#("+Y","-Y","+X","-X") pos:[(CyrusUISize 8 1),634] width:(CyrusUISize 146 1)
        fn colorLabel c = ("#"+(formattedPrint (obj.colorKey c) format:"06X"))
        fn updateList = (
            local selectedRows=plantList.selection
            if selectedRows.numberSet==0 and obj.sources.count>0 do selectedRows=#{1}
            obj.syncColors()
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
            showSelectedColor();redrawViews()
        )
        on addPoint pressed do (
            local i=obj.addPointSource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on replacePoint picked n do (
            local rows=plantList.selection as array
            if rows.count!=1 then messageBox "Select one Point row to replace." title:"Cyrus Scatter"
            else if not (obj.replacePointSource rows[1] n) do messageBox "Select a Point row and an object that is not already in this source list." title:"Cyrus Scatter"
            replacePoint.text="Replace Point: pick object";updateList();showSelectedColor();redrawViews()
        )
        on addEmpty pressed do (
            local i=obj.addEmptySource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on radiusSourceSpin changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v;redrawViews())
        on followRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:2;redrawViews())
        on showRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:3;redrawViews())
        on forwardAxis selected v do if not loadingColor do (obj.assignSourceForward plantList.selection v;redrawViews())
        on sourceZSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v;redrawViews())
        on sourceScaleSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v scaling:true;redrawViews())
        on weightSpin changed v do if not loadingColor do (obj.assignWeight plantList.selection v;updateList();redrawViews())
        on plantList selected i do (
            if i>0 and plantList.selection[i] do focusedRow=i
        )
        on plantList selectionEnd do showSelectedColor()
        on existingGroups selected i do (
            if i>0 and i<=groupPalette.count do (
                local c=groupPalette[i]
                loadingColor=true;groupColor.color=c;loadingColor=false
                obj.assignGroup plantList.selection c;updateList();redrawViews()
            )
        )
        on groupColor changed c do (
            if not loadingColor and plantList.selection.numberSet>0 do (
                obj.assignGroup plantList.selection c
                updateList();redrawViews()
            )
        )
        on applyColor pressed do (
            obj.assignGroup plantList.selection groupColor.color
            updateList();redrawViews()
        )
        on selectFromScene pressed do (
            local picked=selectByName title:"Cyrus Scatter - Select From Scene" buttonText:"Add" filter:AminScatterSourceFilter single:false
            addSources picked
        )
        on addPlant picked n do addSources #(n)
        on addSelected pressed do addSources (selection as array)
        on removePlant pressed do (
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
            plantList.selection=#{};obj.dirty=true;updateList();redrawViews()
        )
        on selectPlant pressed do (
            local nodes=for i in plantList.selection where i<=obj.sources.count and isValidNode obj.sources[i] collect obj.sources[i]
            if nodes.count>0 do select nodes
        )

        on sourceUI_6 rolledUp state do parentView.layoutPanels()
        on sourceUI_6 open do (controlsReady=true;(updateList();showSelectedColor()))
    )
sourceUI_6.obj=target;sourceUI_6.parentView=view;sourceUI_6
)
global CyrusMake_distributionUI_6
fn CyrusMake_distributionUI_6 target view = (
    CyrusUIBuildView=view
    rollout distributionUI_6 "Point Generation" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on distributionUI_6 close do controlsReady=false
        radiobuttons modeRadio "Method" labels:#("Random","Texture Density") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        radiobuttons populationRadio "Population" labels:#("Count","Plants per m2") columns:1 pos:[(CyrusUISize 8 1),78] width:(CyrusUISize 146 1)
        checkbox showCenterCheck "Show Point" pos:[(CyrusUISize 8 1),148] width:(CyrusUISize 146 1)
        on showCenterCheck changed v do (obj.showCenters=v;redrawViews())
        spinner countSpin "Count: " range:[1,100000,200] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),174]
        spinner densitySpin "Per m2: " range:[0,1000000,100] fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),200]
        spinner seedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),226]
        label densityHeading "Texture density" pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)
        mapbutton densityButton "Choose density map" pos:[(CyrusUISize 8 1),284] width:(CyrusUISize 146 1)
        checkbox invertCheck "Invert density" pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        label uvHint "UV channel 1; 0..1" pos:[(CyrusUISize 8 1),338] width:(CyrusUISize 146 1)
        label mapHint "White: dense / Black: empty" pos:[(CyrusUISize 8 1),360] width:(CyrusUISize 146 1)

        fn syncControls = (populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;)
        on modeRadio changed v do (obj.distributionMode=if v==2 then 3 else 1;obj.dirty=true;syncControls();redrawViews())
        on countSpin changed v do (obj.amount=v;obj.dirty=true;syncControls();redrawViews())
        on seedSpin changed v do (obj.randomSeed=v;obj.dirty=true;syncControls();redrawViews())

        on populationRadio changed v do (obj.populationMode=v;obj.dirty=true;syncControls();redrawViews())
        on densitySpin changed v do (obj.plantsPerM2=v;obj.dirty=true;syncControls();redrawViews())
        on densityButton picked v do (obj.densityMap=v;obj.dirty=true;syncControls();redrawViews())
        on invertCheck changed v do (obj.invertDensity=v;obj.dirty=true;syncControls();redrawViews())
        on distributionUI_6 rolledUp state do parentView.layoutPanels()
        on distributionUI_6 open do (showCenterCheck.checked=obj.showCenters;populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;controlsReady=true;(countSpin.value=obj.amount;seedSpin.value=obj.randomSeed;modeRadio.state=if obj.distributionMode==3 then 2 else 1))
    )
distributionUI_6.obj=target;distributionUI_6.parentView=view;distributionUI_6
)
global CyrusMake_areaUI_6
fn CyrusMake_areaUI_6 target view = (
    CyrusUIBuildView=view
    rollout areaUI_6 "Area" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on areaUI_6 close do controlsReady=false
        multiListBox areaList "Closed lines / shapes" items:#() pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1) height:6
        button addAreaScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton pickArea "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button removeArea "Remove selected rows" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        radiobuttons areaMode "Selected area mode" labels:#("Include","Exclude") columns:1 pos:[(CyrusUISize 8 1),220] width:(CyrusUISize 146 1)
        label areaHint "Exclude overrides Include." pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        label projectionHint "Top / world XY projection." pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        button refreshAreas "Refresh areas / preview" pos:[(CyrusUISize 8 1),340] width:(CyrusUISize 146 1)
        local loadingAnalyzerArea=false
        label aaTitle "Surface Analyzer Area" pos:[(CyrusUISize 8 1),378] width:(CyrusUISize 146 1)
        pickbutton aaPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),404] width:(CyrusUISize 146 1)
        button aaRemove "Remove Area Analyzer" pos:[(CyrusUISize 8 1),432] width:(CyrusUISize 146 1)
        checkbox aaLine "Center Line" pos:[(CyrusUISize 8 1),464] width:(CyrusUISize 146 1)
        spinner aaWidth "Full width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),490] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        dropdownlist aaCaps "Line ends" items:#("Flat","Round") selection:1 pos:[(CyrusUISize 8 1),518] width:(CyrusUISize 146 1)
        spinner aaStreetOffset "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),572] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox aaPoints "Points" pos:[(CyrusUISize 8 1),604] width:(CyrusUISize 146 1)
        spinner aaRadius "Radius:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),630] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label aaHelp "XY mask. Both enabled = union. Works with Random / Clusters." pos:[(CyrusUISize 8 1),660] width:(CyrusUISize 146 1) height:40
        fn syncAnalyzerArea = (
            loadingAnalyzerArea=true
            aaPick.text=if isValidNode obj.areaAnalyzer then obj.areaAnalyzer.name else "Pick Surface Analyzer"
            aaLine.checked=obj.areaUseLine;aaPoints.checked=obj.areaUsePoints
            aaStreetOffset.value=obj.centerStreetOffset;aaStreetOffset.enabled=obj.areaUseLine
            aaWidth.value=obj.areaLineWidth;aaRadius.value=obj.areaPointRadius;aaCaps.selection=obj.areaLineCaps
            aaWidth.enabled=obj.areaUseLine;aaCaps.enabled=obj.areaUseLine;aaRadius.enabled=obj.areaUsePoints
            loadingAnalyzerArea=false
        )
        on aaPick picked n do (obj.areaAnalyzer=n;syncAnalyzerArea();redrawViews())
        on aaRemove pressed do (obj.areaUseLine=false;obj.areaUsePoints=false;obj.areaAnalyzer=undefined;syncAnalyzerArea();redrawViews())
        on aaLine changed v do if not loadingAnalyzerArea do (obj.areaUseLine=v;syncAnalyzerArea();redrawViews())
        on aaPoints changed v do if not loadingAnalyzerArea do (obj.areaUsePoints=v;syncAnalyzerArea();redrawViews())
        on aaStreetOffset changed v do if not loadingAnalyzerArea do (obj.centerStreetOffset=v;redrawViews())
        on aaWidth changed v do if not loadingAnalyzerArea do (obj.areaLineWidth=v;redrawViews())
        on aaRadius changed v do if not loadingAnalyzerArea do (obj.areaPointRadius=v;redrawViews())
        on aaCaps selected v do if not loadingAnalyzerArea do (obj.areaLineCaps=v;redrawViews())

        local loadingFall=false
        dropdownlist fallTarget "Edge falloff target" items:#("Analyzer Boundary","Selected Area line") selection:1 pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        pickbutton fallPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1)
        button fallRemove "Remove Analyzer" pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1)
        label fallTargetName "" pos:[(CyrusUISize 8 1),818] width:(CyrusUISize 146 1) height:40
        checkbox fallDeleteCheck "Delete edge band" pos:[(CyrusUISize 8 1),860] width:(CyrusUISize 146 1)
        spinner fallDeleteSpin "Delete width:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox fallScaleCheck "Scale ramp" pos:[(CyrusUISize 8 1),918] width:(CyrusUISize 146 1)
        spinner fallScaleSpin "Scale width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),944] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallScaleEdit "Edit Scale Graph..." pos:[(CyrusUISize 8 1),974] width:(CyrusUISize 146 1)
        checkbox fallDensityCheck "Density ramp" pos:[(CyrusUISize 8 1),1010] width:(CyrusUISize 146 1)
        spinner fallDensitySpin "Density width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),1036] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallDensityEdit "Edit Density Graph..." pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1)
        label fallHelp "Ramps start after delete band. Each Area line has its own settings." pos:[(CyrusUISize 8 1),1104] width:(CyrusUISize 146 1) height:56
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
                if fallTarget.selection==1 or isValidNode n do (local cfg=obj.getFallConfig n;cfg[index]=value;obj.setFallConfig n cfg;redrawViews())
            )
        )
        on fallTarget selected v do syncFalloff()
        on fallPick picked n do (if CyrusAnalyzerFilter n do obj.fallAnalyzer=n;syncFalloff();redrawViews())
        on fallRemove pressed do (obj.fallAnalyzer=undefined;obj.fallDelete=false;obj.fallScale=false;obj.fallDensity=false;syncFalloff();redrawViews())
        on fallDeleteCheck changed v do setFallValue 1 v
        on fallDeleteSpin changed v do setFallValue 2 v
        on fallScaleCheck changed v do setFallValue 3 v
        on fallScaleSpin changed v do setFallValue 4 v
        on fallDensityCheck changed v do setFallValue 6 v
        on fallDensitySpin changed v do setFallValue 7 v
        on fallScaleEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) false
        on fallDensityEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) true

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

        on pickArea picked n do (addArea n;updateAreas();redrawViews())
        on addAreaScene pressed do (
            local nodes=selectByName title:"Cyrus Scatter - Closed Areas" buttonText:"Add" filter:AminScatterAreaFilter single:false
            if nodes!=undefined do for n in nodes do addArea n
            updateAreas();redrawViews()
        )
        on areaList selectionEnd do (
            if areaList.selection.numberSet==1 do fallTarget.selection=2
            syncFalloff()
            if areaList.selection.numberSet>0 do areaMode.state=obj.areaModes[(areaList.selection as array)[1]]
        )
        on areaMode changed mode do (
            undo "Cyrus Scatter area mode" on (for i in areaList.selection do obj.areaModes[i]=mode)
            obj.dirty=true;updateAreas();redrawViews()
        )
        on removeArea pressed do (
            if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()
            local rows=areaList.selection as array
            undo "Cyrus Scatter remove areas" on (
                obj.ensureAreaFalloffs()
                for i=rows.count to 1 by -1 do (deleteItem obj.areaNodes rows[i];deleteItem obj.areaModes rows[i];deleteItem obj.areaFallConfigs rows[i];deleteItem obj.areaFallScaleGraphs rows[i];deleteItem obj.areaFallDensityGraphs rows[i])
            )
            areaList.selection=#{};obj.dirty=true;updateAreas();redrawViews()
        )
        on refreshAreas pressed do (obj.dirty=true;obj.refreshPreview();redrawViews())

        on areaUI_6 rolledUp state do parentView.layoutPanels()
        on areaUI_6 open do (syncAnalyzerArea();syncFalloff();controlsReady=true;updateAreas())
    )
areaUI_6.obj=target;areaUI_6.parentView=view;areaUI_6
)
global CyrusMake_diversityUI_6
fn CyrusMake_diversityUI_6 target view = (
    CyrusUIBuildView=view
    rollout diversityUI_6 "Diversity / Colors" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false,strokeExpandedHeight=0
        on diversityUI_6 close do controlsReady=false
        radiobuttons diversityRadio "Source assignment" labels:#("Random","Clusters","Line Pattern","Analyze Surface") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner sizeSpin "Size: " range:[0.01,100000,10] type:#worldUnits fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),104]
        spinner divSeedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),130]
        spinner roughSpin "Roughness %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),156]
        spinner blurSpin "Blur edge %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),182]
        spinner noiseSpin "Noise %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),208]
        label groupHint "Uses source group colors." pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        label fixedHint "Point positions stay fixed." pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)



    
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),118] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),218] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),250] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),346] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),346] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),372] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),406] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),434] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),506] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),618] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),644] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),676] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),870] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),898] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),940] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),968] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),996] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),1024] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1094] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1122] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),874] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),756] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),784] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),730] width:(CyrusUISize 146 1)
        fn syncControls = (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;syncControls();redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;syncControls();redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on refreshGroups pressed do updatePattern()
                fn updateControls = (
            for c in #(sizeSpin,divSeedSpin,roughSpin,blurSpin,noiseSpin,groupHint,fixedHint) do c.visible=obj.diversityMode==2
            for c in #(strokeTitle,pathsDrop,analyzerChannel,pickAnalyzer,pickPath,removePath,strokesList,addOutside,addInside,removeStrokeButton,strokeWidth,strokeMode,strokeChoices,strokeScaleMin,strokeScaleMax,refreshGroups,strokeHelp) do c.visible=(obj.diversityMode==3 or obj.diversityMode==4)
            if strokeExpandedHeight>0 do diversityUI_6.height=if obj.diversityMode>=3 then strokeExpandedHeight else (if obj.diversityMode==2 then 310 else 124)*parentView.dpiScale
            parentView.layoutPanels()
        )
        on diversityRadio changed v do (obj.diversityMode=v;updateControls();updatePattern();obj.dirty=true;syncControls();redrawViews())


        on sizeSpin changed v do (obj.diversitySize=v;obj.dirty=true;syncControls();redrawViews())
        on divSeedSpin changed v do (obj.diversitySeed=v;obj.dirty=true;syncControls();redrawViews())
        on roughSpin changed v do (obj.roughness=v;obj.dirty=true;syncControls();redrawViews())
        on blurSpin changed v do (obj.blurryEdge=v;obj.dirty=true;syncControls();redrawViews())
        on noiseSpin changed v do (obj.diversityNoise=v;obj.dirty=true;syncControls();redrawViews())
        on diversityUI_6 rolledUp state do parentView.layoutPanels()
        on diversityUI_6 open do (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;controlsReady=true;strokeExpandedHeight=diversityUI_6.height;updateControls();updatePattern())
    )
diversityUI_6.obj=target;diversityUI_6.parentView=view;diversityUI_6
)
global CyrusMake_lineUI_6
fn CyrusMake_lineUI_6 target view = (
    CyrusUIBuildView=view
    rollout lineUI_6 "Line Pattern" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),108] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),140] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),236] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),236] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),262] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),296] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),324] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),396] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),508] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),534] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),566] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),594] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),830] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),858] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),914] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),956] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),984] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1012] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),764] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),646] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),674] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),620] width:(CyrusUISize 146 1)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;redrawViews())
        on refreshGroups pressed do updatePattern()

        on lineUI_6 rolledUp state do parentView.layoutPanels()
        on lineUI_6 open do updatePattern()
    )
lineUI_6.obj=target;lineUI_6.parentView=view;lineUI_6
)
global CyrusMake_randomUI_6
fn CyrusMake_randomUI_6 target view = (
    CyrusUIBuildView=view
    rollout randomUI_6 "Randomize XYZ" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on randomUI_6 close do controlsReady=false
        label rotTitle "Rotation (degrees)" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        label rotMinTitle "Min" pos:[(CyrusUISize 24 1),30] width:(CyrusUISize 58 1)
        label rotMaxTitle "Max" pos:[(CyrusUISize 94 1),30] width:(CyrusUISize 58 1)
        label rotXLabel "X" pos:[(CyrusUISize 8 1),52] width:(CyrusUISize 12 1)
        spinner rotXMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotXMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotYLabel "Y" pos:[(CyrusUISize 8 1),76] width:(CyrusUISize 12 1)
        spinner rotYMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotYMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotZLabel "Z" pos:[(CyrusUISize 8 1),100] width:(CyrusUISize 12 1)
        spinner rotZMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotZMaxSpin "" range:[-360,360,360]  pos:[(CyrusUISize 94 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclTitle "Scale (multiplier)" pos:[(CyrusUISize 8 1),132] width:(CyrusUISize 146 1)
        label sclMinTitle "Min" pos:[(CyrusUISize 24 1),154] width:(CyrusUISize 58 1)
        label sclMaxTitle "Max" pos:[(CyrusUISize 94 1),154] width:(CyrusUISize 58 1)
        label sclXLabel "X" pos:[(CyrusUISize 8 1),176] width:(CyrusUISize 12 1)
        spinner sclXMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclXMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclYLabel "Y" pos:[(CyrusUISize 8 1),200] width:(CyrusUISize 12 1)
        spinner sclYMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclYMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclZLabel "Z" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 12 1)
        spinner sclZMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclZMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label wholeTitle "Whole Scale (uniform)" pos:[(CyrusUISize 8 1),252] width:(CyrusUISize 146 1)
        label wholeMinTitle "Min" pos:[(CyrusUISize 24 1),274] width:(CyrusUISize 58 1)
        label wholeMaxTitle "Max" pos:[(CyrusUISize 94 1),274] width:(CyrusUISize 58 1)
        spinner wholeMinSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 24 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner wholeMaxSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 94 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        on wholeMinSpin changed v do (obj.wholeScaleMin=v;if v>obj.wholeScaleMax do (obj.wholeScaleMax=v;wholeMaxSpin.value=v);redrawViews())
        on wholeMaxSpin changed v do (obj.wholeScaleMax=v;if v<obj.wholeScaleMin do (obj.wholeScaleMin=v;wholeMinSpin.value=v);redrawViews())
        label movTitle "Movement (world units)" pos:[(CyrusUISize 8 1),332] width:(CyrusUISize 146 1)
        label movMinTitle "Min" pos:[(CyrusUISize 24 1),354] width:(CyrusUISize 58 1)
        label movMaxTitle "Max" pos:[(CyrusUISize 94 1),354] width:(CyrusUISize 58 1)
        label movXLabel "X" pos:[(CyrusUISize 8 1),376] width:(CyrusUISize 12 1)
        spinner movXMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movXMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movYLabel "Y" pos:[(CyrusUISize 8 1),400] width:(CyrusUISize 12 1)
        spinner movYMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movYMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movZLabel "Z" pos:[(CyrusUISize 8 1),424] width:(CyrusUISize 12 1)
        spinner movZMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movZMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        checkbox projectCheck "Keep on surface" pos:[(CyrusUISize 8 1),456] width:(CyrusUISize 146 1)
        checkbox alignCheck "Align to normal" pos:[(CyrusUISize 8 1),480] width:(CyrusUISize 146 1)

        fn syncControls = (projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;)
        on alignCheck changed v do (obj.alignNormal=v;obj.dirty=true;syncControls();redrawViews())

        on projectCheck changed v do (obj.projectMove=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMinSpin changed v do (obj.rotXMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMaxSpin changed v do (obj.rotXMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMinSpin changed v do (obj.rotYMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMaxSpin changed v do (obj.rotYMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMinSpin changed v do (obj.rotZMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMaxSpin changed v do (obj.rotZMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMinSpin changed v do (obj.sclXMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMaxSpin changed v do (obj.sclXMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMinSpin changed v do (obj.sclYMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMaxSpin changed v do (obj.sclYMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMinSpin changed v do (obj.sclZMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMaxSpin changed v do (obj.sclZMax=v;obj.dirty=true;syncControls();redrawViews())
        on movXMinSpin changed v do (obj.movXMin=v;obj.dirty=true;syncControls();redrawViews())
        on movXMaxSpin changed v do (obj.movXMax=v;obj.dirty=true;syncControls();redrawViews())
        on movYMinSpin changed v do (obj.movYMin=v;obj.dirty=true;syncControls();redrawViews())
        on movYMaxSpin changed v do (obj.movYMax=v;obj.dirty=true;syncControls();redrawViews())
        on movZMinSpin changed v do (obj.movZMin=v;obj.dirty=true;syncControls();redrawViews())
        on movZMaxSpin changed v do (obj.movZMax=v;obj.dirty=true;syncControls();redrawViews())
        on randomUI_6 rolledUp state do parentView.layoutPanels()
        on randomUI_6 open do (wholeMinSpin.value=obj.wholeScaleMin;wholeMaxSpin.value=obj.wholeScaleMax;projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;controlsReady=true;alignCheck.checked=obj.alignNormal)
    )
randomUI_6.obj=target;randomUI_6.parentView=view;randomUI_6
)
global CyrusMake_sourceUI_7
fn CyrusMake_sourceUI_7 target view = (
    CyrusUIBuildView=view
    rollout sourceUI_7 "Source Object" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on sourceUI_7 close do controlsReady=false
        local groupPalette=#()
        local loadingColor=false
        local focusedRow=0
        multiListBox plantList "Sources (Ctrl/Shift)" items:#() pos:[(CyrusUISize 8 1),8] height:6 width:(CyrusUISize 146 1)
        button selectFromScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton addPlant "Add: pick in viewport" pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button addSelected "Add selected objects" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        button removePlant "Remove selected rows" pos:[(CyrusUISize 8 1),212] width:(CyrusUISize 146 1)
        button selectPlant "Select sources" pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        button addPoint "Add Point" pos:[(CyrusUISize 8 1),264] width:(CyrusUISize 146 1)
        button addEmpty "Add Empty" pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        pickbutton replacePoint "Replace Point: pick object" filter:AminScatterSourceFilter pos:[(CyrusUISize 8 1),316] width:(CyrusUISize 146 1)
        label groupHeading "Cluster color group" pos:[(CyrusUISize 8 1),348] width:(CyrusUISize 146 1)
        dropdownlist existingGroups "Reuse a group" items:#() pos:[(CyrusUISize 8 1),371] width:(CyrusUISize 146 1)
        colorpicker groupColor "Color: " color:(color 100 220 120) pos:[(CyrusUISize 8 1),419] width:(CyrusUISize 146 1) modal:true notifyAfterAccept:true
        button applyColor "Apply to selected rows" pos:[(CyrusUISize 8 1),446] width:(CyrusUISize 146 1)
        label colorHelp "OK saves the selected color." pos:[(CyrusUISize 8 1),476] width:(CyrusUISize 146 1)
        spinner weightSpin "Weight: " range:[0,1,1] scale:0.01 pos:[(CyrusUISize 8 1),504] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        label weightHelp "0 = off; relative share" pos:[(CyrusUISize 8 1),530] width:(CyrusUISize 146 1)
        spinner sourceZSpin "Z Offset: " range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),556] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        spinner sourceScaleSpin "Scale: " range:[0,10000,1] scale:0.01 pos:[(CyrusUISize 8 1),582] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        label sourceTransformHelp "Scale: 1 = original" pos:[(CyrusUISize 8 1),608] width:(CyrusUISize 146 1)
        spinner radiusSourceSpin "Collision radius:" type:#worldunits range:[0,1e9,0] pos:[(CyrusUISize 8 1),686] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        checkbox followRadiusCheck "Follow Scale" pos:[(CyrusUISize 8 1),712] width:(CyrusUISize 146 1)
        checkbox showRadiusCheck "Show Radius" pos:[(CyrusUISize 8 1),738] width:(CyrusUISize 146 1)
        dropdownlist forwardAxis "Forward axis:" items:#("+Y","-Y","+X","-X") pos:[(CyrusUISize 8 1),634] width:(CyrusUISize 146 1)
        fn colorLabel c = ("#"+(formattedPrint (obj.colorKey c) format:"06X"))
        fn updateList = (
            local selectedRows=plantList.selection
            if selectedRows.numberSet==0 and obj.sources.count>0 do selectedRows=#{1}
            obj.syncColors()
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
            showSelectedColor();redrawViews()
        )
        on addPoint pressed do (
            local i=obj.addPointSource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on replacePoint picked n do (
            local rows=plantList.selection as array
            if rows.count!=1 then messageBox "Select one Point row to replace." title:"Cyrus Scatter"
            else if not (obj.replacePointSource rows[1] n) do messageBox "Select a Point row and an object that is not already in this source list." title:"Cyrus Scatter"
            replacePoint.text="Replace Point: pick object";updateList();showSelectedColor();redrawViews()
        )
        on addEmpty pressed do (
            local i=obj.addEmptySource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on radiusSourceSpin changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v;redrawViews())
        on followRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:2;redrawViews())
        on showRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:3;redrawViews())
        on forwardAxis selected v do if not loadingColor do (obj.assignSourceForward plantList.selection v;redrawViews())
        on sourceZSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v;redrawViews())
        on sourceScaleSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v scaling:true;redrawViews())
        on weightSpin changed v do if not loadingColor do (obj.assignWeight plantList.selection v;updateList();redrawViews())
        on plantList selected i do (
            if i>0 and plantList.selection[i] do focusedRow=i
        )
        on plantList selectionEnd do showSelectedColor()
        on existingGroups selected i do (
            if i>0 and i<=groupPalette.count do (
                local c=groupPalette[i]
                loadingColor=true;groupColor.color=c;loadingColor=false
                obj.assignGroup plantList.selection c;updateList();redrawViews()
            )
        )
        on groupColor changed c do (
            if not loadingColor and plantList.selection.numberSet>0 do (
                obj.assignGroup plantList.selection c
                updateList();redrawViews()
            )
        )
        on applyColor pressed do (
            obj.assignGroup plantList.selection groupColor.color
            updateList();redrawViews()
        )
        on selectFromScene pressed do (
            local picked=selectByName title:"Cyrus Scatter - Select From Scene" buttonText:"Add" filter:AminScatterSourceFilter single:false
            addSources picked
        )
        on addPlant picked n do addSources #(n)
        on addSelected pressed do addSources (selection as array)
        on removePlant pressed do (
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
            plantList.selection=#{};obj.dirty=true;updateList();redrawViews()
        )
        on selectPlant pressed do (
            local nodes=for i in plantList.selection where i<=obj.sources.count and isValidNode obj.sources[i] collect obj.sources[i]
            if nodes.count>0 do select nodes
        )

        on sourceUI_7 rolledUp state do parentView.layoutPanels()
        on sourceUI_7 open do (controlsReady=true;(updateList();showSelectedColor()))
    )
sourceUI_7.obj=target;sourceUI_7.parentView=view;sourceUI_7
)
global CyrusMake_distributionUI_7
fn CyrusMake_distributionUI_7 target view = (
    CyrusUIBuildView=view
    rollout distributionUI_7 "Point Generation" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on distributionUI_7 close do controlsReady=false
        radiobuttons modeRadio "Method" labels:#("Random","Texture Density") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        radiobuttons populationRadio "Population" labels:#("Count","Plants per m2") columns:1 pos:[(CyrusUISize 8 1),78] width:(CyrusUISize 146 1)
        checkbox showCenterCheck "Show Point" pos:[(CyrusUISize 8 1),148] width:(CyrusUISize 146 1)
        on showCenterCheck changed v do (obj.showCenters=v;redrawViews())
        spinner countSpin "Count: " range:[1,100000,200] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),174]
        spinner densitySpin "Per m2: " range:[0,1000000,100] fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),200]
        spinner seedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),226]
        label densityHeading "Texture density" pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)
        mapbutton densityButton "Choose density map" pos:[(CyrusUISize 8 1),284] width:(CyrusUISize 146 1)
        checkbox invertCheck "Invert density" pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        label uvHint "UV channel 1; 0..1" pos:[(CyrusUISize 8 1),338] width:(CyrusUISize 146 1)
        label mapHint "White: dense / Black: empty" pos:[(CyrusUISize 8 1),360] width:(CyrusUISize 146 1)

        fn syncControls = (populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;)
        on modeRadio changed v do (obj.distributionMode=if v==2 then 3 else 1;obj.dirty=true;syncControls();redrawViews())
        on countSpin changed v do (obj.amount=v;obj.dirty=true;syncControls();redrawViews())
        on seedSpin changed v do (obj.randomSeed=v;obj.dirty=true;syncControls();redrawViews())

        on populationRadio changed v do (obj.populationMode=v;obj.dirty=true;syncControls();redrawViews())
        on densitySpin changed v do (obj.plantsPerM2=v;obj.dirty=true;syncControls();redrawViews())
        on densityButton picked v do (obj.densityMap=v;obj.dirty=true;syncControls();redrawViews())
        on invertCheck changed v do (obj.invertDensity=v;obj.dirty=true;syncControls();redrawViews())
        on distributionUI_7 rolledUp state do parentView.layoutPanels()
        on distributionUI_7 open do (showCenterCheck.checked=obj.showCenters;populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;controlsReady=true;(countSpin.value=obj.amount;seedSpin.value=obj.randomSeed;modeRadio.state=if obj.distributionMode==3 then 2 else 1))
    )
distributionUI_7.obj=target;distributionUI_7.parentView=view;distributionUI_7
)
global CyrusMake_areaUI_7
fn CyrusMake_areaUI_7 target view = (
    CyrusUIBuildView=view
    rollout areaUI_7 "Area" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on areaUI_7 close do controlsReady=false
        multiListBox areaList "Closed lines / shapes" items:#() pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1) height:6
        button addAreaScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton pickArea "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button removeArea "Remove selected rows" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        radiobuttons areaMode "Selected area mode" labels:#("Include","Exclude") columns:1 pos:[(CyrusUISize 8 1),220] width:(CyrusUISize 146 1)
        label areaHint "Exclude overrides Include." pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        label projectionHint "Top / world XY projection." pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        button refreshAreas "Refresh areas / preview" pos:[(CyrusUISize 8 1),340] width:(CyrusUISize 146 1)
        local loadingAnalyzerArea=false
        label aaTitle "Surface Analyzer Area" pos:[(CyrusUISize 8 1),378] width:(CyrusUISize 146 1)
        pickbutton aaPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),404] width:(CyrusUISize 146 1)
        button aaRemove "Remove Area Analyzer" pos:[(CyrusUISize 8 1),432] width:(CyrusUISize 146 1)
        checkbox aaLine "Center Line" pos:[(CyrusUISize 8 1),464] width:(CyrusUISize 146 1)
        spinner aaWidth "Full width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),490] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        dropdownlist aaCaps "Line ends" items:#("Flat","Round") selection:1 pos:[(CyrusUISize 8 1),518] width:(CyrusUISize 146 1)
        spinner aaStreetOffset "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),572] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox aaPoints "Points" pos:[(CyrusUISize 8 1),604] width:(CyrusUISize 146 1)
        spinner aaRadius "Radius:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),630] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label aaHelp "XY mask. Both enabled = union. Works with Random / Clusters." pos:[(CyrusUISize 8 1),660] width:(CyrusUISize 146 1) height:40
        fn syncAnalyzerArea = (
            loadingAnalyzerArea=true
            aaPick.text=if isValidNode obj.areaAnalyzer then obj.areaAnalyzer.name else "Pick Surface Analyzer"
            aaLine.checked=obj.areaUseLine;aaPoints.checked=obj.areaUsePoints
            aaStreetOffset.value=obj.centerStreetOffset;aaStreetOffset.enabled=obj.areaUseLine
            aaWidth.value=obj.areaLineWidth;aaRadius.value=obj.areaPointRadius;aaCaps.selection=obj.areaLineCaps
            aaWidth.enabled=obj.areaUseLine;aaCaps.enabled=obj.areaUseLine;aaRadius.enabled=obj.areaUsePoints
            loadingAnalyzerArea=false
        )
        on aaPick picked n do (obj.areaAnalyzer=n;syncAnalyzerArea();redrawViews())
        on aaRemove pressed do (obj.areaUseLine=false;obj.areaUsePoints=false;obj.areaAnalyzer=undefined;syncAnalyzerArea();redrawViews())
        on aaLine changed v do if not loadingAnalyzerArea do (obj.areaUseLine=v;syncAnalyzerArea();redrawViews())
        on aaPoints changed v do if not loadingAnalyzerArea do (obj.areaUsePoints=v;syncAnalyzerArea();redrawViews())
        on aaStreetOffset changed v do if not loadingAnalyzerArea do (obj.centerStreetOffset=v;redrawViews())
        on aaWidth changed v do if not loadingAnalyzerArea do (obj.areaLineWidth=v;redrawViews())
        on aaRadius changed v do if not loadingAnalyzerArea do (obj.areaPointRadius=v;redrawViews())
        on aaCaps selected v do if not loadingAnalyzerArea do (obj.areaLineCaps=v;redrawViews())

        local loadingFall=false
        dropdownlist fallTarget "Edge falloff target" items:#("Analyzer Boundary","Selected Area line") selection:1 pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        pickbutton fallPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1)
        button fallRemove "Remove Analyzer" pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1)
        label fallTargetName "" pos:[(CyrusUISize 8 1),818] width:(CyrusUISize 146 1) height:40
        checkbox fallDeleteCheck "Delete edge band" pos:[(CyrusUISize 8 1),860] width:(CyrusUISize 146 1)
        spinner fallDeleteSpin "Delete width:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox fallScaleCheck "Scale ramp" pos:[(CyrusUISize 8 1),918] width:(CyrusUISize 146 1)
        spinner fallScaleSpin "Scale width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),944] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallScaleEdit "Edit Scale Graph..." pos:[(CyrusUISize 8 1),974] width:(CyrusUISize 146 1)
        checkbox fallDensityCheck "Density ramp" pos:[(CyrusUISize 8 1),1010] width:(CyrusUISize 146 1)
        spinner fallDensitySpin "Density width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),1036] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallDensityEdit "Edit Density Graph..." pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1)
        label fallHelp "Ramps start after delete band. Each Area line has its own settings." pos:[(CyrusUISize 8 1),1104] width:(CyrusUISize 146 1) height:56
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
                if fallTarget.selection==1 or isValidNode n do (local cfg=obj.getFallConfig n;cfg[index]=value;obj.setFallConfig n cfg;redrawViews())
            )
        )
        on fallTarget selected v do syncFalloff()
        on fallPick picked n do (if CyrusAnalyzerFilter n do obj.fallAnalyzer=n;syncFalloff();redrawViews())
        on fallRemove pressed do (obj.fallAnalyzer=undefined;obj.fallDelete=false;obj.fallScale=false;obj.fallDensity=false;syncFalloff();redrawViews())
        on fallDeleteCheck changed v do setFallValue 1 v
        on fallDeleteSpin changed v do setFallValue 2 v
        on fallScaleCheck changed v do setFallValue 3 v
        on fallScaleSpin changed v do setFallValue 4 v
        on fallDensityCheck changed v do setFallValue 6 v
        on fallDensitySpin changed v do setFallValue 7 v
        on fallScaleEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) false
        on fallDensityEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) true

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

        on pickArea picked n do (addArea n;updateAreas();redrawViews())
        on addAreaScene pressed do (
            local nodes=selectByName title:"Cyrus Scatter - Closed Areas" buttonText:"Add" filter:AminScatterAreaFilter single:false
            if nodes!=undefined do for n in nodes do addArea n
            updateAreas();redrawViews()
        )
        on areaList selectionEnd do (
            if areaList.selection.numberSet==1 do fallTarget.selection=2
            syncFalloff()
            if areaList.selection.numberSet>0 do areaMode.state=obj.areaModes[(areaList.selection as array)[1]]
        )
        on areaMode changed mode do (
            undo "Cyrus Scatter area mode" on (for i in areaList.selection do obj.areaModes[i]=mode)
            obj.dirty=true;updateAreas();redrawViews()
        )
        on removeArea pressed do (
            if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()
            local rows=areaList.selection as array
            undo "Cyrus Scatter remove areas" on (
                obj.ensureAreaFalloffs()
                for i=rows.count to 1 by -1 do (deleteItem obj.areaNodes rows[i];deleteItem obj.areaModes rows[i];deleteItem obj.areaFallConfigs rows[i];deleteItem obj.areaFallScaleGraphs rows[i];deleteItem obj.areaFallDensityGraphs rows[i])
            )
            areaList.selection=#{};obj.dirty=true;updateAreas();redrawViews()
        )
        on refreshAreas pressed do (obj.dirty=true;obj.refreshPreview();redrawViews())

        on areaUI_7 rolledUp state do parentView.layoutPanels()
        on areaUI_7 open do (syncAnalyzerArea();syncFalloff();controlsReady=true;updateAreas())
    )
areaUI_7.obj=target;areaUI_7.parentView=view;areaUI_7
)
global CyrusMake_diversityUI_7
fn CyrusMake_diversityUI_7 target view = (
    CyrusUIBuildView=view
    rollout diversityUI_7 "Diversity / Colors" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false,strokeExpandedHeight=0
        on diversityUI_7 close do controlsReady=false
        radiobuttons diversityRadio "Source assignment" labels:#("Random","Clusters","Line Pattern","Analyze Surface") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner sizeSpin "Size: " range:[0.01,100000,10] type:#worldUnits fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),104]
        spinner divSeedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),130]
        spinner roughSpin "Roughness %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),156]
        spinner blurSpin "Blur edge %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),182]
        spinner noiseSpin "Noise %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),208]
        label groupHint "Uses source group colors." pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        label fixedHint "Point positions stay fixed." pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)



    
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),118] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),218] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),250] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),346] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),346] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),372] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),406] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),434] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),506] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),618] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),644] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),676] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),870] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),898] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),940] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),968] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),996] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),1024] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1094] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1122] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),874] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),756] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),784] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),730] width:(CyrusUISize 146 1)
        fn syncControls = (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;syncControls();redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;syncControls();redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on refreshGroups pressed do updatePattern()
                fn updateControls = (
            for c in #(sizeSpin,divSeedSpin,roughSpin,blurSpin,noiseSpin,groupHint,fixedHint) do c.visible=obj.diversityMode==2
            for c in #(strokeTitle,pathsDrop,analyzerChannel,pickAnalyzer,pickPath,removePath,strokesList,addOutside,addInside,removeStrokeButton,strokeWidth,strokeMode,strokeChoices,strokeScaleMin,strokeScaleMax,refreshGroups,strokeHelp) do c.visible=(obj.diversityMode==3 or obj.diversityMode==4)
            if strokeExpandedHeight>0 do diversityUI_7.height=if obj.diversityMode>=3 then strokeExpandedHeight else (if obj.diversityMode==2 then 310 else 124)*parentView.dpiScale
            parentView.layoutPanels()
        )
        on diversityRadio changed v do (obj.diversityMode=v;updateControls();updatePattern();obj.dirty=true;syncControls();redrawViews())


        on sizeSpin changed v do (obj.diversitySize=v;obj.dirty=true;syncControls();redrawViews())
        on divSeedSpin changed v do (obj.diversitySeed=v;obj.dirty=true;syncControls();redrawViews())
        on roughSpin changed v do (obj.roughness=v;obj.dirty=true;syncControls();redrawViews())
        on blurSpin changed v do (obj.blurryEdge=v;obj.dirty=true;syncControls();redrawViews())
        on noiseSpin changed v do (obj.diversityNoise=v;obj.dirty=true;syncControls();redrawViews())
        on diversityUI_7 rolledUp state do parentView.layoutPanels()
        on diversityUI_7 open do (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;controlsReady=true;strokeExpandedHeight=diversityUI_7.height;updateControls();updatePattern())
    )
diversityUI_7.obj=target;diversityUI_7.parentView=view;diversityUI_7
)
global CyrusMake_lineUI_7
fn CyrusMake_lineUI_7 target view = (
    CyrusUIBuildView=view
    rollout lineUI_7 "Line Pattern" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),108] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),140] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),236] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),236] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),262] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),296] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),324] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),396] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),508] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),534] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),566] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),594] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),830] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),858] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),914] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),956] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),984] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1012] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),764] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),646] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),674] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),620] width:(CyrusUISize 146 1)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;redrawViews())
        on refreshGroups pressed do updatePattern()

        on lineUI_7 rolledUp state do parentView.layoutPanels()
        on lineUI_7 open do updatePattern()
    )
lineUI_7.obj=target;lineUI_7.parentView=view;lineUI_7
)
global CyrusMake_randomUI_7
fn CyrusMake_randomUI_7 target view = (
    CyrusUIBuildView=view
    rollout randomUI_7 "Randomize XYZ" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on randomUI_7 close do controlsReady=false
        label rotTitle "Rotation (degrees)" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        label rotMinTitle "Min" pos:[(CyrusUISize 24 1),30] width:(CyrusUISize 58 1)
        label rotMaxTitle "Max" pos:[(CyrusUISize 94 1),30] width:(CyrusUISize 58 1)
        label rotXLabel "X" pos:[(CyrusUISize 8 1),52] width:(CyrusUISize 12 1)
        spinner rotXMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotXMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotYLabel "Y" pos:[(CyrusUISize 8 1),76] width:(CyrusUISize 12 1)
        spinner rotYMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotYMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotZLabel "Z" pos:[(CyrusUISize 8 1),100] width:(CyrusUISize 12 1)
        spinner rotZMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotZMaxSpin "" range:[-360,360,360]  pos:[(CyrusUISize 94 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclTitle "Scale (multiplier)" pos:[(CyrusUISize 8 1),132] width:(CyrusUISize 146 1)
        label sclMinTitle "Min" pos:[(CyrusUISize 24 1),154] width:(CyrusUISize 58 1)
        label sclMaxTitle "Max" pos:[(CyrusUISize 94 1),154] width:(CyrusUISize 58 1)
        label sclXLabel "X" pos:[(CyrusUISize 8 1),176] width:(CyrusUISize 12 1)
        spinner sclXMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclXMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclYLabel "Y" pos:[(CyrusUISize 8 1),200] width:(CyrusUISize 12 1)
        spinner sclYMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclYMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclZLabel "Z" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 12 1)
        spinner sclZMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclZMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label wholeTitle "Whole Scale (uniform)" pos:[(CyrusUISize 8 1),252] width:(CyrusUISize 146 1)
        label wholeMinTitle "Min" pos:[(CyrusUISize 24 1),274] width:(CyrusUISize 58 1)
        label wholeMaxTitle "Max" pos:[(CyrusUISize 94 1),274] width:(CyrusUISize 58 1)
        spinner wholeMinSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 24 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner wholeMaxSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 94 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        on wholeMinSpin changed v do (obj.wholeScaleMin=v;if v>obj.wholeScaleMax do (obj.wholeScaleMax=v;wholeMaxSpin.value=v);redrawViews())
        on wholeMaxSpin changed v do (obj.wholeScaleMax=v;if v<obj.wholeScaleMin do (obj.wholeScaleMin=v;wholeMinSpin.value=v);redrawViews())
        label movTitle "Movement (world units)" pos:[(CyrusUISize 8 1),332] width:(CyrusUISize 146 1)
        label movMinTitle "Min" pos:[(CyrusUISize 24 1),354] width:(CyrusUISize 58 1)
        label movMaxTitle "Max" pos:[(CyrusUISize 94 1),354] width:(CyrusUISize 58 1)
        label movXLabel "X" pos:[(CyrusUISize 8 1),376] width:(CyrusUISize 12 1)
        spinner movXMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movXMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movYLabel "Y" pos:[(CyrusUISize 8 1),400] width:(CyrusUISize 12 1)
        spinner movYMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movYMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movZLabel "Z" pos:[(CyrusUISize 8 1),424] width:(CyrusUISize 12 1)
        spinner movZMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movZMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        checkbox projectCheck "Keep on surface" pos:[(CyrusUISize 8 1),456] width:(CyrusUISize 146 1)
        checkbox alignCheck "Align to normal" pos:[(CyrusUISize 8 1),480] width:(CyrusUISize 146 1)

        fn syncControls = (projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;)
        on alignCheck changed v do (obj.alignNormal=v;obj.dirty=true;syncControls();redrawViews())

        on projectCheck changed v do (obj.projectMove=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMinSpin changed v do (obj.rotXMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMaxSpin changed v do (obj.rotXMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMinSpin changed v do (obj.rotYMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMaxSpin changed v do (obj.rotYMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMinSpin changed v do (obj.rotZMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMaxSpin changed v do (obj.rotZMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMinSpin changed v do (obj.sclXMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMaxSpin changed v do (obj.sclXMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMinSpin changed v do (obj.sclYMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMaxSpin changed v do (obj.sclYMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMinSpin changed v do (obj.sclZMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMaxSpin changed v do (obj.sclZMax=v;obj.dirty=true;syncControls();redrawViews())
        on movXMinSpin changed v do (obj.movXMin=v;obj.dirty=true;syncControls();redrawViews())
        on movXMaxSpin changed v do (obj.movXMax=v;obj.dirty=true;syncControls();redrawViews())
        on movYMinSpin changed v do (obj.movYMin=v;obj.dirty=true;syncControls();redrawViews())
        on movYMaxSpin changed v do (obj.movYMax=v;obj.dirty=true;syncControls();redrawViews())
        on movZMinSpin changed v do (obj.movZMin=v;obj.dirty=true;syncControls();redrawViews())
        on movZMaxSpin changed v do (obj.movZMax=v;obj.dirty=true;syncControls();redrawViews())
        on randomUI_7 rolledUp state do parentView.layoutPanels()
        on randomUI_7 open do (wholeMinSpin.value=obj.wholeScaleMin;wholeMaxSpin.value=obj.wholeScaleMax;projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;controlsReady=true;alignCheck.checked=obj.alignNormal)
    )
randomUI_7.obj=target;randomUI_7.parentView=view;randomUI_7
)
global CyrusMake_sourceUI_8
fn CyrusMake_sourceUI_8 target view = (
    CyrusUIBuildView=view
    rollout sourceUI_8 "Source Object" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on sourceUI_8 close do controlsReady=false
        local groupPalette=#()
        local loadingColor=false
        local focusedRow=0
        multiListBox plantList "Sources (Ctrl/Shift)" items:#() pos:[(CyrusUISize 8 1),8] height:6 width:(CyrusUISize 146 1)
        button selectFromScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton addPlant "Add: pick in viewport" pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button addSelected "Add selected objects" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        button removePlant "Remove selected rows" pos:[(CyrusUISize 8 1),212] width:(CyrusUISize 146 1)
        button selectPlant "Select sources" pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        button addPoint "Add Point" pos:[(CyrusUISize 8 1),264] width:(CyrusUISize 146 1)
        button addEmpty "Add Empty" pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        pickbutton replacePoint "Replace Point: pick object" filter:AminScatterSourceFilter pos:[(CyrusUISize 8 1),316] width:(CyrusUISize 146 1)
        label groupHeading "Cluster color group" pos:[(CyrusUISize 8 1),348] width:(CyrusUISize 146 1)
        dropdownlist existingGroups "Reuse a group" items:#() pos:[(CyrusUISize 8 1),371] width:(CyrusUISize 146 1)
        colorpicker groupColor "Color: " color:(color 100 220 120) pos:[(CyrusUISize 8 1),419] width:(CyrusUISize 146 1) modal:true notifyAfterAccept:true
        button applyColor "Apply to selected rows" pos:[(CyrusUISize 8 1),446] width:(CyrusUISize 146 1)
        label colorHelp "OK saves the selected color." pos:[(CyrusUISize 8 1),476] width:(CyrusUISize 146 1)
        spinner weightSpin "Weight: " range:[0,1,1] scale:0.01 pos:[(CyrusUISize 8 1),504] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        label weightHelp "0 = off; relative share" pos:[(CyrusUISize 8 1),530] width:(CyrusUISize 146 1)
        spinner sourceZSpin "Z Offset: " range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),556] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        spinner sourceScaleSpin "Scale: " range:[0,10000,1] scale:0.01 pos:[(CyrusUISize 8 1),582] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        label sourceTransformHelp "Scale: 1 = original" pos:[(CyrusUISize 8 1),608] width:(CyrusUISize 146 1)
        spinner radiusSourceSpin "Collision radius:" type:#worldunits range:[0,1e9,0] pos:[(CyrusUISize 8 1),686] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        checkbox followRadiusCheck "Follow Scale" pos:[(CyrusUISize 8 1),712] width:(CyrusUISize 146 1)
        checkbox showRadiusCheck "Show Radius" pos:[(CyrusUISize 8 1),738] width:(CyrusUISize 146 1)
        dropdownlist forwardAxis "Forward axis:" items:#("+Y","-Y","+X","-X") pos:[(CyrusUISize 8 1),634] width:(CyrusUISize 146 1)
        fn colorLabel c = ("#"+(formattedPrint (obj.colorKey c) format:"06X"))
        fn updateList = (
            local selectedRows=plantList.selection
            if selectedRows.numberSet==0 and obj.sources.count>0 do selectedRows=#{1}
            obj.syncColors()
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
            showSelectedColor();redrawViews()
        )
        on addPoint pressed do (
            local i=obj.addPointSource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on replacePoint picked n do (
            local rows=plantList.selection as array
            if rows.count!=1 then messageBox "Select one Point row to replace." title:"Cyrus Scatter"
            else if not (obj.replacePointSource rows[1] n) do messageBox "Select a Point row and an object that is not already in this source list." title:"Cyrus Scatter"
            replacePoint.text="Replace Point: pick object";updateList();showSelectedColor();redrawViews()
        )
        on addEmpty pressed do (
            local i=obj.addEmptySource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on radiusSourceSpin changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v;redrawViews())
        on followRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:2;redrawViews())
        on showRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:3;redrawViews())
        on forwardAxis selected v do if not loadingColor do (obj.assignSourceForward plantList.selection v;redrawViews())
        on sourceZSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v;redrawViews())
        on sourceScaleSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v scaling:true;redrawViews())
        on weightSpin changed v do if not loadingColor do (obj.assignWeight plantList.selection v;updateList();redrawViews())
        on plantList selected i do (
            if i>0 and plantList.selection[i] do focusedRow=i
        )
        on plantList selectionEnd do showSelectedColor()
        on existingGroups selected i do (
            if i>0 and i<=groupPalette.count do (
                local c=groupPalette[i]
                loadingColor=true;groupColor.color=c;loadingColor=false
                obj.assignGroup plantList.selection c;updateList();redrawViews()
            )
        )
        on groupColor changed c do (
            if not loadingColor and plantList.selection.numberSet>0 do (
                obj.assignGroup plantList.selection c
                updateList();redrawViews()
            )
        )
        on applyColor pressed do (
            obj.assignGroup plantList.selection groupColor.color
            updateList();redrawViews()
        )
        on selectFromScene pressed do (
            local picked=selectByName title:"Cyrus Scatter - Select From Scene" buttonText:"Add" filter:AminScatterSourceFilter single:false
            addSources picked
        )
        on addPlant picked n do addSources #(n)
        on addSelected pressed do addSources (selection as array)
        on removePlant pressed do (
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
            plantList.selection=#{};obj.dirty=true;updateList();redrawViews()
        )
        on selectPlant pressed do (
            local nodes=for i in plantList.selection where i<=obj.sources.count and isValidNode obj.sources[i] collect obj.sources[i]
            if nodes.count>0 do select nodes
        )

        on sourceUI_8 rolledUp state do parentView.layoutPanels()
        on sourceUI_8 open do (controlsReady=true;(updateList();showSelectedColor()))
    )
sourceUI_8.obj=target;sourceUI_8.parentView=view;sourceUI_8
)
global CyrusMake_distributionUI_8
fn CyrusMake_distributionUI_8 target view = (
    CyrusUIBuildView=view
    rollout distributionUI_8 "Point Generation" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on distributionUI_8 close do controlsReady=false
        radiobuttons modeRadio "Method" labels:#("Random","Texture Density") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        radiobuttons populationRadio "Population" labels:#("Count","Plants per m2") columns:1 pos:[(CyrusUISize 8 1),78] width:(CyrusUISize 146 1)
        checkbox showCenterCheck "Show Point" pos:[(CyrusUISize 8 1),148] width:(CyrusUISize 146 1)
        on showCenterCheck changed v do (obj.showCenters=v;redrawViews())
        spinner countSpin "Count: " range:[1,100000,200] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),174]
        spinner densitySpin "Per m2: " range:[0,1000000,100] fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),200]
        spinner seedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),226]
        label densityHeading "Texture density" pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)
        mapbutton densityButton "Choose density map" pos:[(CyrusUISize 8 1),284] width:(CyrusUISize 146 1)
        checkbox invertCheck "Invert density" pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        label uvHint "UV channel 1; 0..1" pos:[(CyrusUISize 8 1),338] width:(CyrusUISize 146 1)
        label mapHint "White: dense / Black: empty" pos:[(CyrusUISize 8 1),360] width:(CyrusUISize 146 1)

        fn syncControls = (populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;)
        on modeRadio changed v do (obj.distributionMode=if v==2 then 3 else 1;obj.dirty=true;syncControls();redrawViews())
        on countSpin changed v do (obj.amount=v;obj.dirty=true;syncControls();redrawViews())
        on seedSpin changed v do (obj.randomSeed=v;obj.dirty=true;syncControls();redrawViews())

        on populationRadio changed v do (obj.populationMode=v;obj.dirty=true;syncControls();redrawViews())
        on densitySpin changed v do (obj.plantsPerM2=v;obj.dirty=true;syncControls();redrawViews())
        on densityButton picked v do (obj.densityMap=v;obj.dirty=true;syncControls();redrawViews())
        on invertCheck changed v do (obj.invertDensity=v;obj.dirty=true;syncControls();redrawViews())
        on distributionUI_8 rolledUp state do parentView.layoutPanels()
        on distributionUI_8 open do (showCenterCheck.checked=obj.showCenters;populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;controlsReady=true;(countSpin.value=obj.amount;seedSpin.value=obj.randomSeed;modeRadio.state=if obj.distributionMode==3 then 2 else 1))
    )
distributionUI_8.obj=target;distributionUI_8.parentView=view;distributionUI_8
)
global CyrusMake_areaUI_8
fn CyrusMake_areaUI_8 target view = (
    CyrusUIBuildView=view
    rollout areaUI_8 "Area" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on areaUI_8 close do controlsReady=false
        multiListBox areaList "Closed lines / shapes" items:#() pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1) height:6
        button addAreaScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton pickArea "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button removeArea "Remove selected rows" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        radiobuttons areaMode "Selected area mode" labels:#("Include","Exclude") columns:1 pos:[(CyrusUISize 8 1),220] width:(CyrusUISize 146 1)
        label areaHint "Exclude overrides Include." pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        label projectionHint "Top / world XY projection." pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        button refreshAreas "Refresh areas / preview" pos:[(CyrusUISize 8 1),340] width:(CyrusUISize 146 1)
        local loadingAnalyzerArea=false
        label aaTitle "Surface Analyzer Area" pos:[(CyrusUISize 8 1),378] width:(CyrusUISize 146 1)
        pickbutton aaPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),404] width:(CyrusUISize 146 1)
        button aaRemove "Remove Area Analyzer" pos:[(CyrusUISize 8 1),432] width:(CyrusUISize 146 1)
        checkbox aaLine "Center Line" pos:[(CyrusUISize 8 1),464] width:(CyrusUISize 146 1)
        spinner aaWidth "Full width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),490] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        dropdownlist aaCaps "Line ends" items:#("Flat","Round") selection:1 pos:[(CyrusUISize 8 1),518] width:(CyrusUISize 146 1)
        spinner aaStreetOffset "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),572] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox aaPoints "Points" pos:[(CyrusUISize 8 1),604] width:(CyrusUISize 146 1)
        spinner aaRadius "Radius:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),630] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label aaHelp "XY mask. Both enabled = union. Works with Random / Clusters." pos:[(CyrusUISize 8 1),660] width:(CyrusUISize 146 1) height:40
        fn syncAnalyzerArea = (
            loadingAnalyzerArea=true
            aaPick.text=if isValidNode obj.areaAnalyzer then obj.areaAnalyzer.name else "Pick Surface Analyzer"
            aaLine.checked=obj.areaUseLine;aaPoints.checked=obj.areaUsePoints
            aaStreetOffset.value=obj.centerStreetOffset;aaStreetOffset.enabled=obj.areaUseLine
            aaWidth.value=obj.areaLineWidth;aaRadius.value=obj.areaPointRadius;aaCaps.selection=obj.areaLineCaps
            aaWidth.enabled=obj.areaUseLine;aaCaps.enabled=obj.areaUseLine;aaRadius.enabled=obj.areaUsePoints
            loadingAnalyzerArea=false
        )
        on aaPick picked n do (obj.areaAnalyzer=n;syncAnalyzerArea();redrawViews())
        on aaRemove pressed do (obj.areaUseLine=false;obj.areaUsePoints=false;obj.areaAnalyzer=undefined;syncAnalyzerArea();redrawViews())
        on aaLine changed v do if not loadingAnalyzerArea do (obj.areaUseLine=v;syncAnalyzerArea();redrawViews())
        on aaPoints changed v do if not loadingAnalyzerArea do (obj.areaUsePoints=v;syncAnalyzerArea();redrawViews())
        on aaStreetOffset changed v do if not loadingAnalyzerArea do (obj.centerStreetOffset=v;redrawViews())
        on aaWidth changed v do if not loadingAnalyzerArea do (obj.areaLineWidth=v;redrawViews())
        on aaRadius changed v do if not loadingAnalyzerArea do (obj.areaPointRadius=v;redrawViews())
        on aaCaps selected v do if not loadingAnalyzerArea do (obj.areaLineCaps=v;redrawViews())

        local loadingFall=false
        dropdownlist fallTarget "Edge falloff target" items:#("Analyzer Boundary","Selected Area line") selection:1 pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        pickbutton fallPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1)
        button fallRemove "Remove Analyzer" pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1)
        label fallTargetName "" pos:[(CyrusUISize 8 1),818] width:(CyrusUISize 146 1) height:40
        checkbox fallDeleteCheck "Delete edge band" pos:[(CyrusUISize 8 1),860] width:(CyrusUISize 146 1)
        spinner fallDeleteSpin "Delete width:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox fallScaleCheck "Scale ramp" pos:[(CyrusUISize 8 1),918] width:(CyrusUISize 146 1)
        spinner fallScaleSpin "Scale width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),944] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallScaleEdit "Edit Scale Graph..." pos:[(CyrusUISize 8 1),974] width:(CyrusUISize 146 1)
        checkbox fallDensityCheck "Density ramp" pos:[(CyrusUISize 8 1),1010] width:(CyrusUISize 146 1)
        spinner fallDensitySpin "Density width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),1036] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallDensityEdit "Edit Density Graph..." pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1)
        label fallHelp "Ramps start after delete band. Each Area line has its own settings." pos:[(CyrusUISize 8 1),1104] width:(CyrusUISize 146 1) height:56
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
                if fallTarget.selection==1 or isValidNode n do (local cfg=obj.getFallConfig n;cfg[index]=value;obj.setFallConfig n cfg;redrawViews())
            )
        )
        on fallTarget selected v do syncFalloff()
        on fallPick picked n do (if CyrusAnalyzerFilter n do obj.fallAnalyzer=n;syncFalloff();redrawViews())
        on fallRemove pressed do (obj.fallAnalyzer=undefined;obj.fallDelete=false;obj.fallScale=false;obj.fallDensity=false;syncFalloff();redrawViews())
        on fallDeleteCheck changed v do setFallValue 1 v
        on fallDeleteSpin changed v do setFallValue 2 v
        on fallScaleCheck changed v do setFallValue 3 v
        on fallScaleSpin changed v do setFallValue 4 v
        on fallDensityCheck changed v do setFallValue 6 v
        on fallDensitySpin changed v do setFallValue 7 v
        on fallScaleEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) false
        on fallDensityEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) true

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

        on pickArea picked n do (addArea n;updateAreas();redrawViews())
        on addAreaScene pressed do (
            local nodes=selectByName title:"Cyrus Scatter - Closed Areas" buttonText:"Add" filter:AminScatterAreaFilter single:false
            if nodes!=undefined do for n in nodes do addArea n
            updateAreas();redrawViews()
        )
        on areaList selectionEnd do (
            if areaList.selection.numberSet==1 do fallTarget.selection=2
            syncFalloff()
            if areaList.selection.numberSet>0 do areaMode.state=obj.areaModes[(areaList.selection as array)[1]]
        )
        on areaMode changed mode do (
            undo "Cyrus Scatter area mode" on (for i in areaList.selection do obj.areaModes[i]=mode)
            obj.dirty=true;updateAreas();redrawViews()
        )
        on removeArea pressed do (
            if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()
            local rows=areaList.selection as array
            undo "Cyrus Scatter remove areas" on (
                obj.ensureAreaFalloffs()
                for i=rows.count to 1 by -1 do (deleteItem obj.areaNodes rows[i];deleteItem obj.areaModes rows[i];deleteItem obj.areaFallConfigs rows[i];deleteItem obj.areaFallScaleGraphs rows[i];deleteItem obj.areaFallDensityGraphs rows[i])
            )
            areaList.selection=#{};obj.dirty=true;updateAreas();redrawViews()
        )
        on refreshAreas pressed do (obj.dirty=true;obj.refreshPreview();redrawViews())

        on areaUI_8 rolledUp state do parentView.layoutPanels()
        on areaUI_8 open do (syncAnalyzerArea();syncFalloff();controlsReady=true;updateAreas())
    )
areaUI_8.obj=target;areaUI_8.parentView=view;areaUI_8
)
global CyrusMake_diversityUI_8
fn CyrusMake_diversityUI_8 target view = (
    CyrusUIBuildView=view
    rollout diversityUI_8 "Diversity / Colors" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false,strokeExpandedHeight=0
        on diversityUI_8 close do controlsReady=false
        radiobuttons diversityRadio "Source assignment" labels:#("Random","Clusters","Line Pattern","Analyze Surface") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner sizeSpin "Size: " range:[0.01,100000,10] type:#worldUnits fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),104]
        spinner divSeedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),130]
        spinner roughSpin "Roughness %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),156]
        spinner blurSpin "Blur edge %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),182]
        spinner noiseSpin "Noise %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),208]
        label groupHint "Uses source group colors." pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        label fixedHint "Point positions stay fixed." pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)



    
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),118] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),218] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),250] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),346] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),346] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),372] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),406] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),434] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),506] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),618] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),644] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),676] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),870] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),898] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),940] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),968] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),996] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),1024] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1094] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1122] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),874] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),756] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),784] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),730] width:(CyrusUISize 146 1)
        fn syncControls = (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;syncControls();redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;syncControls();redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on refreshGroups pressed do updatePattern()
                fn updateControls = (
            for c in #(sizeSpin,divSeedSpin,roughSpin,blurSpin,noiseSpin,groupHint,fixedHint) do c.visible=obj.diversityMode==2
            for c in #(strokeTitle,pathsDrop,analyzerChannel,pickAnalyzer,pickPath,removePath,strokesList,addOutside,addInside,removeStrokeButton,strokeWidth,strokeMode,strokeChoices,strokeScaleMin,strokeScaleMax,refreshGroups,strokeHelp) do c.visible=(obj.diversityMode==3 or obj.diversityMode==4)
            if strokeExpandedHeight>0 do diversityUI_8.height=if obj.diversityMode>=3 then strokeExpandedHeight else (if obj.diversityMode==2 then 310 else 124)*parentView.dpiScale
            parentView.layoutPanels()
        )
        on diversityRadio changed v do (obj.diversityMode=v;updateControls();updatePattern();obj.dirty=true;syncControls();redrawViews())


        on sizeSpin changed v do (obj.diversitySize=v;obj.dirty=true;syncControls();redrawViews())
        on divSeedSpin changed v do (obj.diversitySeed=v;obj.dirty=true;syncControls();redrawViews())
        on roughSpin changed v do (obj.roughness=v;obj.dirty=true;syncControls();redrawViews())
        on blurSpin changed v do (obj.blurryEdge=v;obj.dirty=true;syncControls();redrawViews())
        on noiseSpin changed v do (obj.diversityNoise=v;obj.dirty=true;syncControls();redrawViews())
        on diversityUI_8 rolledUp state do parentView.layoutPanels()
        on diversityUI_8 open do (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;controlsReady=true;strokeExpandedHeight=diversityUI_8.height;updateControls();updatePattern())
    )
diversityUI_8.obj=target;diversityUI_8.parentView=view;diversityUI_8
)
global CyrusMake_lineUI_8
fn CyrusMake_lineUI_8 target view = (
    CyrusUIBuildView=view
    rollout lineUI_8 "Line Pattern" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),108] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),140] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),236] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),236] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),262] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),296] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),324] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),396] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),508] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),534] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),566] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),594] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),830] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),858] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),914] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),956] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),984] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1012] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),764] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),646] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),674] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),620] width:(CyrusUISize 146 1)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;redrawViews())
        on refreshGroups pressed do updatePattern()

        on lineUI_8 rolledUp state do parentView.layoutPanels()
        on lineUI_8 open do updatePattern()
    )
lineUI_8.obj=target;lineUI_8.parentView=view;lineUI_8
)
global CyrusMake_randomUI_8
fn CyrusMake_randomUI_8 target view = (
    CyrusUIBuildView=view
    rollout randomUI_8 "Randomize XYZ" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on randomUI_8 close do controlsReady=false
        label rotTitle "Rotation (degrees)" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        label rotMinTitle "Min" pos:[(CyrusUISize 24 1),30] width:(CyrusUISize 58 1)
        label rotMaxTitle "Max" pos:[(CyrusUISize 94 1),30] width:(CyrusUISize 58 1)
        label rotXLabel "X" pos:[(CyrusUISize 8 1),52] width:(CyrusUISize 12 1)
        spinner rotXMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotXMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotYLabel "Y" pos:[(CyrusUISize 8 1),76] width:(CyrusUISize 12 1)
        spinner rotYMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotYMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotZLabel "Z" pos:[(CyrusUISize 8 1),100] width:(CyrusUISize 12 1)
        spinner rotZMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotZMaxSpin "" range:[-360,360,360]  pos:[(CyrusUISize 94 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclTitle "Scale (multiplier)" pos:[(CyrusUISize 8 1),132] width:(CyrusUISize 146 1)
        label sclMinTitle "Min" pos:[(CyrusUISize 24 1),154] width:(CyrusUISize 58 1)
        label sclMaxTitle "Max" pos:[(CyrusUISize 94 1),154] width:(CyrusUISize 58 1)
        label sclXLabel "X" pos:[(CyrusUISize 8 1),176] width:(CyrusUISize 12 1)
        spinner sclXMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclXMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclYLabel "Y" pos:[(CyrusUISize 8 1),200] width:(CyrusUISize 12 1)
        spinner sclYMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclYMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclZLabel "Z" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 12 1)
        spinner sclZMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclZMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label wholeTitle "Whole Scale (uniform)" pos:[(CyrusUISize 8 1),252] width:(CyrusUISize 146 1)
        label wholeMinTitle "Min" pos:[(CyrusUISize 24 1),274] width:(CyrusUISize 58 1)
        label wholeMaxTitle "Max" pos:[(CyrusUISize 94 1),274] width:(CyrusUISize 58 1)
        spinner wholeMinSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 24 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner wholeMaxSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 94 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        on wholeMinSpin changed v do (obj.wholeScaleMin=v;if v>obj.wholeScaleMax do (obj.wholeScaleMax=v;wholeMaxSpin.value=v);redrawViews())
        on wholeMaxSpin changed v do (obj.wholeScaleMax=v;if v<obj.wholeScaleMin do (obj.wholeScaleMin=v;wholeMinSpin.value=v);redrawViews())
        label movTitle "Movement (world units)" pos:[(CyrusUISize 8 1),332] width:(CyrusUISize 146 1)
        label movMinTitle "Min" pos:[(CyrusUISize 24 1),354] width:(CyrusUISize 58 1)
        label movMaxTitle "Max" pos:[(CyrusUISize 94 1),354] width:(CyrusUISize 58 1)
        label movXLabel "X" pos:[(CyrusUISize 8 1),376] width:(CyrusUISize 12 1)
        spinner movXMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movXMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movYLabel "Y" pos:[(CyrusUISize 8 1),400] width:(CyrusUISize 12 1)
        spinner movYMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movYMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movZLabel "Z" pos:[(CyrusUISize 8 1),424] width:(CyrusUISize 12 1)
        spinner movZMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movZMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        checkbox projectCheck "Keep on surface" pos:[(CyrusUISize 8 1),456] width:(CyrusUISize 146 1)
        checkbox alignCheck "Align to normal" pos:[(CyrusUISize 8 1),480] width:(CyrusUISize 146 1)

        fn syncControls = (projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;)
        on alignCheck changed v do (obj.alignNormal=v;obj.dirty=true;syncControls();redrawViews())

        on projectCheck changed v do (obj.projectMove=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMinSpin changed v do (obj.rotXMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMaxSpin changed v do (obj.rotXMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMinSpin changed v do (obj.rotYMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMaxSpin changed v do (obj.rotYMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMinSpin changed v do (obj.rotZMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMaxSpin changed v do (obj.rotZMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMinSpin changed v do (obj.sclXMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMaxSpin changed v do (obj.sclXMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMinSpin changed v do (obj.sclYMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMaxSpin changed v do (obj.sclYMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMinSpin changed v do (obj.sclZMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMaxSpin changed v do (obj.sclZMax=v;obj.dirty=true;syncControls();redrawViews())
        on movXMinSpin changed v do (obj.movXMin=v;obj.dirty=true;syncControls();redrawViews())
        on movXMaxSpin changed v do (obj.movXMax=v;obj.dirty=true;syncControls();redrawViews())
        on movYMinSpin changed v do (obj.movYMin=v;obj.dirty=true;syncControls();redrawViews())
        on movYMaxSpin changed v do (obj.movYMax=v;obj.dirty=true;syncControls();redrawViews())
        on movZMinSpin changed v do (obj.movZMin=v;obj.dirty=true;syncControls();redrawViews())
        on movZMaxSpin changed v do (obj.movZMax=v;obj.dirty=true;syncControls();redrawViews())
        on randomUI_8 rolledUp state do parentView.layoutPanels()
        on randomUI_8 open do (wholeMinSpin.value=obj.wholeScaleMin;wholeMaxSpin.value=obj.wholeScaleMax;projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;controlsReady=true;alignCheck.checked=obj.alignNormal)
    )
randomUI_8.obj=target;randomUI_8.parentView=view;randomUI_8
)
global CyrusMake_sourceUI_9
fn CyrusMake_sourceUI_9 target view = (
    CyrusUIBuildView=view
    rollout sourceUI_9 "Source Object" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on sourceUI_9 close do controlsReady=false
        local groupPalette=#()
        local loadingColor=false
        local focusedRow=0
        multiListBox plantList "Sources (Ctrl/Shift)" items:#() pos:[(CyrusUISize 8 1),8] height:6 width:(CyrusUISize 146 1)
        button selectFromScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton addPlant "Add: pick in viewport" pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button addSelected "Add selected objects" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        button removePlant "Remove selected rows" pos:[(CyrusUISize 8 1),212] width:(CyrusUISize 146 1)
        button selectPlant "Select sources" pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        button addPoint "Add Point" pos:[(CyrusUISize 8 1),264] width:(CyrusUISize 146 1)
        button addEmpty "Add Empty" pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        pickbutton replacePoint "Replace Point: pick object" filter:AminScatterSourceFilter pos:[(CyrusUISize 8 1),316] width:(CyrusUISize 146 1)
        label groupHeading "Cluster color group" pos:[(CyrusUISize 8 1),348] width:(CyrusUISize 146 1)
        dropdownlist existingGroups "Reuse a group" items:#() pos:[(CyrusUISize 8 1),371] width:(CyrusUISize 146 1)
        colorpicker groupColor "Color: " color:(color 100 220 120) pos:[(CyrusUISize 8 1),419] width:(CyrusUISize 146 1) modal:true notifyAfterAccept:true
        button applyColor "Apply to selected rows" pos:[(CyrusUISize 8 1),446] width:(CyrusUISize 146 1)
        label colorHelp "OK saves the selected color." pos:[(CyrusUISize 8 1),476] width:(CyrusUISize 146 1)
        spinner weightSpin "Weight: " range:[0,1,1] scale:0.01 pos:[(CyrusUISize 8 1),504] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        label weightHelp "0 = off; relative share" pos:[(CyrusUISize 8 1),530] width:(CyrusUISize 146 1)
        spinner sourceZSpin "Z Offset: " range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),556] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        spinner sourceScaleSpin "Scale: " range:[0,10000,1] scale:0.01 pos:[(CyrusUISize 8 1),582] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        label sourceTransformHelp "Scale: 1 = original" pos:[(CyrusUISize 8 1),608] width:(CyrusUISize 146 1)
        spinner radiusSourceSpin "Collision radius:" type:#worldunits range:[0,1e9,0] pos:[(CyrusUISize 8 1),686] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        checkbox followRadiusCheck "Follow Scale" pos:[(CyrusUISize 8 1),712] width:(CyrusUISize 146 1)
        checkbox showRadiusCheck "Show Radius" pos:[(CyrusUISize 8 1),738] width:(CyrusUISize 146 1)
        dropdownlist forwardAxis "Forward axis:" items:#("+Y","-Y","+X","-X") pos:[(CyrusUISize 8 1),634] width:(CyrusUISize 146 1)
        fn colorLabel c = ("#"+(formattedPrint (obj.colorKey c) format:"06X"))
        fn updateList = (
            local selectedRows=plantList.selection
            if selectedRows.numberSet==0 and obj.sources.count>0 do selectedRows=#{1}
            obj.syncColors()
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
            showSelectedColor();redrawViews()
        )
        on addPoint pressed do (
            local i=obj.addPointSource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on replacePoint picked n do (
            local rows=plantList.selection as array
            if rows.count!=1 then messageBox "Select one Point row to replace." title:"Cyrus Scatter"
            else if not (obj.replacePointSource rows[1] n) do messageBox "Select a Point row and an object that is not already in this source list." title:"Cyrus Scatter"
            replacePoint.text="Replace Point: pick object";updateList();showSelectedColor();redrawViews()
        )
        on addEmpty pressed do (
            local i=obj.addEmptySource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on radiusSourceSpin changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v;redrawViews())
        on followRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:2;redrawViews())
        on showRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:3;redrawViews())
        on forwardAxis selected v do if not loadingColor do (obj.assignSourceForward plantList.selection v;redrawViews())
        on sourceZSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v;redrawViews())
        on sourceScaleSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v scaling:true;redrawViews())
        on weightSpin changed v do if not loadingColor do (obj.assignWeight plantList.selection v;updateList();redrawViews())
        on plantList selected i do (
            if i>0 and plantList.selection[i] do focusedRow=i
        )
        on plantList selectionEnd do showSelectedColor()
        on existingGroups selected i do (
            if i>0 and i<=groupPalette.count do (
                local c=groupPalette[i]
                loadingColor=true;groupColor.color=c;loadingColor=false
                obj.assignGroup plantList.selection c;updateList();redrawViews()
            )
        )
        on groupColor changed c do (
            if not loadingColor and plantList.selection.numberSet>0 do (
                obj.assignGroup plantList.selection c
                updateList();redrawViews()
            )
        )
        on applyColor pressed do (
            obj.assignGroup plantList.selection groupColor.color
            updateList();redrawViews()
        )
        on selectFromScene pressed do (
            local picked=selectByName title:"Cyrus Scatter - Select From Scene" buttonText:"Add" filter:AminScatterSourceFilter single:false
            addSources picked
        )
        on addPlant picked n do addSources #(n)
        on addSelected pressed do addSources (selection as array)
        on removePlant pressed do (
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
            plantList.selection=#{};obj.dirty=true;updateList();redrawViews()
        )
        on selectPlant pressed do (
            local nodes=for i in plantList.selection where i<=obj.sources.count and isValidNode obj.sources[i] collect obj.sources[i]
            if nodes.count>0 do select nodes
        )

        on sourceUI_9 rolledUp state do parentView.layoutPanels()
        on sourceUI_9 open do (controlsReady=true;(updateList();showSelectedColor()))
    )
sourceUI_9.obj=target;sourceUI_9.parentView=view;sourceUI_9
)
global CyrusMake_distributionUI_9
fn CyrusMake_distributionUI_9 target view = (
    CyrusUIBuildView=view
    rollout distributionUI_9 "Point Generation" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on distributionUI_9 close do controlsReady=false
        radiobuttons modeRadio "Method" labels:#("Random","Texture Density") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        radiobuttons populationRadio "Population" labels:#("Count","Plants per m2") columns:1 pos:[(CyrusUISize 8 1),78] width:(CyrusUISize 146 1)
        checkbox showCenterCheck "Show Point" pos:[(CyrusUISize 8 1),148] width:(CyrusUISize 146 1)
        on showCenterCheck changed v do (obj.showCenters=v;redrawViews())
        spinner countSpin "Count: " range:[1,100000,200] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),174]
        spinner densitySpin "Per m2: " range:[0,1000000,100] fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),200]
        spinner seedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),226]
        label densityHeading "Texture density" pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)
        mapbutton densityButton "Choose density map" pos:[(CyrusUISize 8 1),284] width:(CyrusUISize 146 1)
        checkbox invertCheck "Invert density" pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        label uvHint "UV channel 1; 0..1" pos:[(CyrusUISize 8 1),338] width:(CyrusUISize 146 1)
        label mapHint "White: dense / Black: empty" pos:[(CyrusUISize 8 1),360] width:(CyrusUISize 146 1)

        fn syncControls = (populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;)
        on modeRadio changed v do (obj.distributionMode=if v==2 then 3 else 1;obj.dirty=true;syncControls();redrawViews())
        on countSpin changed v do (obj.amount=v;obj.dirty=true;syncControls();redrawViews())
        on seedSpin changed v do (obj.randomSeed=v;obj.dirty=true;syncControls();redrawViews())

        on populationRadio changed v do (obj.populationMode=v;obj.dirty=true;syncControls();redrawViews())
        on densitySpin changed v do (obj.plantsPerM2=v;obj.dirty=true;syncControls();redrawViews())
        on densityButton picked v do (obj.densityMap=v;obj.dirty=true;syncControls();redrawViews())
        on invertCheck changed v do (obj.invertDensity=v;obj.dirty=true;syncControls();redrawViews())
        on distributionUI_9 rolledUp state do parentView.layoutPanels()
        on distributionUI_9 open do (showCenterCheck.checked=obj.showCenters;populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;controlsReady=true;(countSpin.value=obj.amount;seedSpin.value=obj.randomSeed;modeRadio.state=if obj.distributionMode==3 then 2 else 1))
    )
distributionUI_9.obj=target;distributionUI_9.parentView=view;distributionUI_9
)
global CyrusMake_areaUI_9
fn CyrusMake_areaUI_9 target view = (
    CyrusUIBuildView=view
    rollout areaUI_9 "Area" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on areaUI_9 close do controlsReady=false
        multiListBox areaList "Closed lines / shapes" items:#() pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1) height:6
        button addAreaScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton pickArea "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button removeArea "Remove selected rows" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        radiobuttons areaMode "Selected area mode" labels:#("Include","Exclude") columns:1 pos:[(CyrusUISize 8 1),220] width:(CyrusUISize 146 1)
        label areaHint "Exclude overrides Include." pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        label projectionHint "Top / world XY projection." pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        button refreshAreas "Refresh areas / preview" pos:[(CyrusUISize 8 1),340] width:(CyrusUISize 146 1)
        local loadingAnalyzerArea=false
        label aaTitle "Surface Analyzer Area" pos:[(CyrusUISize 8 1),378] width:(CyrusUISize 146 1)
        pickbutton aaPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),404] width:(CyrusUISize 146 1)
        button aaRemove "Remove Area Analyzer" pos:[(CyrusUISize 8 1),432] width:(CyrusUISize 146 1)
        checkbox aaLine "Center Line" pos:[(CyrusUISize 8 1),464] width:(CyrusUISize 146 1)
        spinner aaWidth "Full width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),490] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        dropdownlist aaCaps "Line ends" items:#("Flat","Round") selection:1 pos:[(CyrusUISize 8 1),518] width:(CyrusUISize 146 1)
        spinner aaStreetOffset "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),572] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox aaPoints "Points" pos:[(CyrusUISize 8 1),604] width:(CyrusUISize 146 1)
        spinner aaRadius "Radius:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),630] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label aaHelp "XY mask. Both enabled = union. Works with Random / Clusters." pos:[(CyrusUISize 8 1),660] width:(CyrusUISize 146 1) height:40
        fn syncAnalyzerArea = (
            loadingAnalyzerArea=true
            aaPick.text=if isValidNode obj.areaAnalyzer then obj.areaAnalyzer.name else "Pick Surface Analyzer"
            aaLine.checked=obj.areaUseLine;aaPoints.checked=obj.areaUsePoints
            aaStreetOffset.value=obj.centerStreetOffset;aaStreetOffset.enabled=obj.areaUseLine
            aaWidth.value=obj.areaLineWidth;aaRadius.value=obj.areaPointRadius;aaCaps.selection=obj.areaLineCaps
            aaWidth.enabled=obj.areaUseLine;aaCaps.enabled=obj.areaUseLine;aaRadius.enabled=obj.areaUsePoints
            loadingAnalyzerArea=false
        )
        on aaPick picked n do (obj.areaAnalyzer=n;syncAnalyzerArea();redrawViews())
        on aaRemove pressed do (obj.areaUseLine=false;obj.areaUsePoints=false;obj.areaAnalyzer=undefined;syncAnalyzerArea();redrawViews())
        on aaLine changed v do if not loadingAnalyzerArea do (obj.areaUseLine=v;syncAnalyzerArea();redrawViews())
        on aaPoints changed v do if not loadingAnalyzerArea do (obj.areaUsePoints=v;syncAnalyzerArea();redrawViews())
        on aaStreetOffset changed v do if not loadingAnalyzerArea do (obj.centerStreetOffset=v;redrawViews())
        on aaWidth changed v do if not loadingAnalyzerArea do (obj.areaLineWidth=v;redrawViews())
        on aaRadius changed v do if not loadingAnalyzerArea do (obj.areaPointRadius=v;redrawViews())
        on aaCaps selected v do if not loadingAnalyzerArea do (obj.areaLineCaps=v;redrawViews())

        local loadingFall=false
        dropdownlist fallTarget "Edge falloff target" items:#("Analyzer Boundary","Selected Area line") selection:1 pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        pickbutton fallPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1)
        button fallRemove "Remove Analyzer" pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1)
        label fallTargetName "" pos:[(CyrusUISize 8 1),818] width:(CyrusUISize 146 1) height:40
        checkbox fallDeleteCheck "Delete edge band" pos:[(CyrusUISize 8 1),860] width:(CyrusUISize 146 1)
        spinner fallDeleteSpin "Delete width:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox fallScaleCheck "Scale ramp" pos:[(CyrusUISize 8 1),918] width:(CyrusUISize 146 1)
        spinner fallScaleSpin "Scale width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),944] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallScaleEdit "Edit Scale Graph..." pos:[(CyrusUISize 8 1),974] width:(CyrusUISize 146 1)
        checkbox fallDensityCheck "Density ramp" pos:[(CyrusUISize 8 1),1010] width:(CyrusUISize 146 1)
        spinner fallDensitySpin "Density width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),1036] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallDensityEdit "Edit Density Graph..." pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1)
        label fallHelp "Ramps start after delete band. Each Area line has its own settings." pos:[(CyrusUISize 8 1),1104] width:(CyrusUISize 146 1) height:56
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
                if fallTarget.selection==1 or isValidNode n do (local cfg=obj.getFallConfig n;cfg[index]=value;obj.setFallConfig n cfg;redrawViews())
            )
        )
        on fallTarget selected v do syncFalloff()
        on fallPick picked n do (if CyrusAnalyzerFilter n do obj.fallAnalyzer=n;syncFalloff();redrawViews())
        on fallRemove pressed do (obj.fallAnalyzer=undefined;obj.fallDelete=false;obj.fallScale=false;obj.fallDensity=false;syncFalloff();redrawViews())
        on fallDeleteCheck changed v do setFallValue 1 v
        on fallDeleteSpin changed v do setFallValue 2 v
        on fallScaleCheck changed v do setFallValue 3 v
        on fallScaleSpin changed v do setFallValue 4 v
        on fallDensityCheck changed v do setFallValue 6 v
        on fallDensitySpin changed v do setFallValue 7 v
        on fallScaleEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) false
        on fallDensityEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) true

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

        on pickArea picked n do (addArea n;updateAreas();redrawViews())
        on addAreaScene pressed do (
            local nodes=selectByName title:"Cyrus Scatter - Closed Areas" buttonText:"Add" filter:AminScatterAreaFilter single:false
            if nodes!=undefined do for n in nodes do addArea n
            updateAreas();redrawViews()
        )
        on areaList selectionEnd do (
            if areaList.selection.numberSet==1 do fallTarget.selection=2
            syncFalloff()
            if areaList.selection.numberSet>0 do areaMode.state=obj.areaModes[(areaList.selection as array)[1]]
        )
        on areaMode changed mode do (
            undo "Cyrus Scatter area mode" on (for i in areaList.selection do obj.areaModes[i]=mode)
            obj.dirty=true;updateAreas();redrawViews()
        )
        on removeArea pressed do (
            if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()
            local rows=areaList.selection as array
            undo "Cyrus Scatter remove areas" on (
                obj.ensureAreaFalloffs()
                for i=rows.count to 1 by -1 do (deleteItem obj.areaNodes rows[i];deleteItem obj.areaModes rows[i];deleteItem obj.areaFallConfigs rows[i];deleteItem obj.areaFallScaleGraphs rows[i];deleteItem obj.areaFallDensityGraphs rows[i])
            )
            areaList.selection=#{};obj.dirty=true;updateAreas();redrawViews()
        )
        on refreshAreas pressed do (obj.dirty=true;obj.refreshPreview();redrawViews())

        on areaUI_9 rolledUp state do parentView.layoutPanels()
        on areaUI_9 open do (syncAnalyzerArea();syncFalloff();controlsReady=true;updateAreas())
    )
areaUI_9.obj=target;areaUI_9.parentView=view;areaUI_9
)
global CyrusMake_diversityUI_9
fn CyrusMake_diversityUI_9 target view = (
    CyrusUIBuildView=view
    rollout diversityUI_9 "Diversity / Colors" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false,strokeExpandedHeight=0
        on diversityUI_9 close do controlsReady=false
        radiobuttons diversityRadio "Source assignment" labels:#("Random","Clusters","Line Pattern","Analyze Surface") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner sizeSpin "Size: " range:[0.01,100000,10] type:#worldUnits fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),104]
        spinner divSeedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),130]
        spinner roughSpin "Roughness %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),156]
        spinner blurSpin "Blur edge %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),182]
        spinner noiseSpin "Noise %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),208]
        label groupHint "Uses source group colors." pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        label fixedHint "Point positions stay fixed." pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)



    
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),118] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),218] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),250] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),346] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),346] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),372] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),406] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),434] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),506] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),618] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),644] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),676] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),870] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),898] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),940] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),968] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),996] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),1024] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1094] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1122] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),874] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),756] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),784] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),730] width:(CyrusUISize 146 1)
        fn syncControls = (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;syncControls();redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;syncControls();redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on refreshGroups pressed do updatePattern()
                fn updateControls = (
            for c in #(sizeSpin,divSeedSpin,roughSpin,blurSpin,noiseSpin,groupHint,fixedHint) do c.visible=obj.diversityMode==2
            for c in #(strokeTitle,pathsDrop,analyzerChannel,pickAnalyzer,pickPath,removePath,strokesList,addOutside,addInside,removeStrokeButton,strokeWidth,strokeMode,strokeChoices,strokeScaleMin,strokeScaleMax,refreshGroups,strokeHelp) do c.visible=(obj.diversityMode==3 or obj.diversityMode==4)
            if strokeExpandedHeight>0 do diversityUI_9.height=if obj.diversityMode>=3 then strokeExpandedHeight else (if obj.diversityMode==2 then 310 else 124)*parentView.dpiScale
            parentView.layoutPanels()
        )
        on diversityRadio changed v do (obj.diversityMode=v;updateControls();updatePattern();obj.dirty=true;syncControls();redrawViews())


        on sizeSpin changed v do (obj.diversitySize=v;obj.dirty=true;syncControls();redrawViews())
        on divSeedSpin changed v do (obj.diversitySeed=v;obj.dirty=true;syncControls();redrawViews())
        on roughSpin changed v do (obj.roughness=v;obj.dirty=true;syncControls();redrawViews())
        on blurSpin changed v do (obj.blurryEdge=v;obj.dirty=true;syncControls();redrawViews())
        on noiseSpin changed v do (obj.diversityNoise=v;obj.dirty=true;syncControls();redrawViews())
        on diversityUI_9 rolledUp state do parentView.layoutPanels()
        on diversityUI_9 open do (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;controlsReady=true;strokeExpandedHeight=diversityUI_9.height;updateControls();updatePattern())
    )
diversityUI_9.obj=target;diversityUI_9.parentView=view;diversityUI_9
)
global CyrusMake_lineUI_9
fn CyrusMake_lineUI_9 target view = (
    CyrusUIBuildView=view
    rollout lineUI_9 "Line Pattern" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),108] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),140] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),236] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),236] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),262] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),296] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),324] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),396] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),508] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),534] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),566] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),594] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),830] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),858] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),914] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),956] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),984] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1012] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),764] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),646] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),674] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),620] width:(CyrusUISize 146 1)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;redrawViews())
        on refreshGroups pressed do updatePattern()

        on lineUI_9 rolledUp state do parentView.layoutPanels()
        on lineUI_9 open do updatePattern()
    )
lineUI_9.obj=target;lineUI_9.parentView=view;lineUI_9
)
global CyrusMake_randomUI_9
fn CyrusMake_randomUI_9 target view = (
    CyrusUIBuildView=view
    rollout randomUI_9 "Randomize XYZ" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on randomUI_9 close do controlsReady=false
        label rotTitle "Rotation (degrees)" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        label rotMinTitle "Min" pos:[(CyrusUISize 24 1),30] width:(CyrusUISize 58 1)
        label rotMaxTitle "Max" pos:[(CyrusUISize 94 1),30] width:(CyrusUISize 58 1)
        label rotXLabel "X" pos:[(CyrusUISize 8 1),52] width:(CyrusUISize 12 1)
        spinner rotXMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotXMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotYLabel "Y" pos:[(CyrusUISize 8 1),76] width:(CyrusUISize 12 1)
        spinner rotYMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotYMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotZLabel "Z" pos:[(CyrusUISize 8 1),100] width:(CyrusUISize 12 1)
        spinner rotZMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotZMaxSpin "" range:[-360,360,360]  pos:[(CyrusUISize 94 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclTitle "Scale (multiplier)" pos:[(CyrusUISize 8 1),132] width:(CyrusUISize 146 1)
        label sclMinTitle "Min" pos:[(CyrusUISize 24 1),154] width:(CyrusUISize 58 1)
        label sclMaxTitle "Max" pos:[(CyrusUISize 94 1),154] width:(CyrusUISize 58 1)
        label sclXLabel "X" pos:[(CyrusUISize 8 1),176] width:(CyrusUISize 12 1)
        spinner sclXMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclXMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclYLabel "Y" pos:[(CyrusUISize 8 1),200] width:(CyrusUISize 12 1)
        spinner sclYMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclYMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclZLabel "Z" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 12 1)
        spinner sclZMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclZMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label wholeTitle "Whole Scale (uniform)" pos:[(CyrusUISize 8 1),252] width:(CyrusUISize 146 1)
        label wholeMinTitle "Min" pos:[(CyrusUISize 24 1),274] width:(CyrusUISize 58 1)
        label wholeMaxTitle "Max" pos:[(CyrusUISize 94 1),274] width:(CyrusUISize 58 1)
        spinner wholeMinSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 24 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner wholeMaxSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 94 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        on wholeMinSpin changed v do (obj.wholeScaleMin=v;if v>obj.wholeScaleMax do (obj.wholeScaleMax=v;wholeMaxSpin.value=v);redrawViews())
        on wholeMaxSpin changed v do (obj.wholeScaleMax=v;if v<obj.wholeScaleMin do (obj.wholeScaleMin=v;wholeMinSpin.value=v);redrawViews())
        label movTitle "Movement (world units)" pos:[(CyrusUISize 8 1),332] width:(CyrusUISize 146 1)
        label movMinTitle "Min" pos:[(CyrusUISize 24 1),354] width:(CyrusUISize 58 1)
        label movMaxTitle "Max" pos:[(CyrusUISize 94 1),354] width:(CyrusUISize 58 1)
        label movXLabel "X" pos:[(CyrusUISize 8 1),376] width:(CyrusUISize 12 1)
        spinner movXMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movXMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movYLabel "Y" pos:[(CyrusUISize 8 1),400] width:(CyrusUISize 12 1)
        spinner movYMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movYMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movZLabel "Z" pos:[(CyrusUISize 8 1),424] width:(CyrusUISize 12 1)
        spinner movZMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movZMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        checkbox projectCheck "Keep on surface" pos:[(CyrusUISize 8 1),456] width:(CyrusUISize 146 1)
        checkbox alignCheck "Align to normal" pos:[(CyrusUISize 8 1),480] width:(CyrusUISize 146 1)

        fn syncControls = (projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;)
        on alignCheck changed v do (obj.alignNormal=v;obj.dirty=true;syncControls();redrawViews())

        on projectCheck changed v do (obj.projectMove=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMinSpin changed v do (obj.rotXMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMaxSpin changed v do (obj.rotXMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMinSpin changed v do (obj.rotYMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMaxSpin changed v do (obj.rotYMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMinSpin changed v do (obj.rotZMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMaxSpin changed v do (obj.rotZMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMinSpin changed v do (obj.sclXMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMaxSpin changed v do (obj.sclXMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMinSpin changed v do (obj.sclYMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMaxSpin changed v do (obj.sclYMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMinSpin changed v do (obj.sclZMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMaxSpin changed v do (obj.sclZMax=v;obj.dirty=true;syncControls();redrawViews())
        on movXMinSpin changed v do (obj.movXMin=v;obj.dirty=true;syncControls();redrawViews())
        on movXMaxSpin changed v do (obj.movXMax=v;obj.dirty=true;syncControls();redrawViews())
        on movYMinSpin changed v do (obj.movYMin=v;obj.dirty=true;syncControls();redrawViews())
        on movYMaxSpin changed v do (obj.movYMax=v;obj.dirty=true;syncControls();redrawViews())
        on movZMinSpin changed v do (obj.movZMin=v;obj.dirty=true;syncControls();redrawViews())
        on movZMaxSpin changed v do (obj.movZMax=v;obj.dirty=true;syncControls();redrawViews())
        on randomUI_9 rolledUp state do parentView.layoutPanels()
        on randomUI_9 open do (wholeMinSpin.value=obj.wholeScaleMin;wholeMaxSpin.value=obj.wholeScaleMax;projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;controlsReady=true;alignCheck.checked=obj.alignNormal)
    )
randomUI_9.obj=target;randomUI_9.parentView=view;randomUI_9
)
global CyrusMake_sourceUI_10
fn CyrusMake_sourceUI_10 target view = (
    CyrusUIBuildView=view
    rollout sourceUI_10 "Source Object" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on sourceUI_10 close do controlsReady=false
        local groupPalette=#()
        local loadingColor=false
        local focusedRow=0
        multiListBox plantList "Sources (Ctrl/Shift)" items:#() pos:[(CyrusUISize 8 1),8] height:6 width:(CyrusUISize 146 1)
        button selectFromScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton addPlant "Add: pick in viewport" pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button addSelected "Add selected objects" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        button removePlant "Remove selected rows" pos:[(CyrusUISize 8 1),212] width:(CyrusUISize 146 1)
        button selectPlant "Select sources" pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        button addPoint "Add Point" pos:[(CyrusUISize 8 1),264] width:(CyrusUISize 146 1)
        button addEmpty "Add Empty" pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        pickbutton replacePoint "Replace Point: pick object" filter:AminScatterSourceFilter pos:[(CyrusUISize 8 1),316] width:(CyrusUISize 146 1)
        label groupHeading "Cluster color group" pos:[(CyrusUISize 8 1),348] width:(CyrusUISize 146 1)
        dropdownlist existingGroups "Reuse a group" items:#() pos:[(CyrusUISize 8 1),371] width:(CyrusUISize 146 1)
        colorpicker groupColor "Color: " color:(color 100 220 120) pos:[(CyrusUISize 8 1),419] width:(CyrusUISize 146 1) modal:true notifyAfterAccept:true
        button applyColor "Apply to selected rows" pos:[(CyrusUISize 8 1),446] width:(CyrusUISize 146 1)
        label colorHelp "OK saves the selected color." pos:[(CyrusUISize 8 1),476] width:(CyrusUISize 146 1)
        spinner weightSpin "Weight: " range:[0,1,1] scale:0.01 pos:[(CyrusUISize 8 1),504] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        label weightHelp "0 = off; relative share" pos:[(CyrusUISize 8 1),530] width:(CyrusUISize 146 1)
        spinner sourceZSpin "Z Offset: " range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),556] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        spinner sourceScaleSpin "Scale: " range:[0,10000,1] scale:0.01 pos:[(CyrusUISize 8 1),582] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 65 1)
        label sourceTransformHelp "Scale: 1 = original" pos:[(CyrusUISize 8 1),608] width:(CyrusUISize 146 1)
        spinner radiusSourceSpin "Collision radius:" type:#worldunits range:[0,1e9,0] pos:[(CyrusUISize 8 1),686] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1)
        checkbox followRadiusCheck "Follow Scale" pos:[(CyrusUISize 8 1),712] width:(CyrusUISize 146 1)
        checkbox showRadiusCheck "Show Radius" pos:[(CyrusUISize 8 1),738] width:(CyrusUISize 146 1)
        dropdownlist forwardAxis "Forward axis:" items:#("+Y","-Y","+X","-X") pos:[(CyrusUISize 8 1),634] width:(CyrusUISize 146 1)
        fn colorLabel c = ("#"+(formattedPrint (obj.colorKey c) format:"06X"))
        fn updateList = (
            local selectedRows=plantList.selection
            if selectedRows.numberSet==0 and obj.sources.count>0 do selectedRows=#{1}
            obj.syncColors()
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
            showSelectedColor();redrawViews()
        )
        on addPoint pressed do (
            local i=obj.addPointSource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on replacePoint picked n do (
            local rows=plantList.selection as array
            if rows.count!=1 then messageBox "Select one Point row to replace." title:"Cyrus Scatter"
            else if not (obj.replacePointSource rows[1] n) do messageBox "Select a Point row and an object that is not already in this source list." title:"Cyrus Scatter"
            replacePoint.text="Replace Point: pick object";updateList();showSelectedColor();redrawViews()
        )
        on addEmpty pressed do (
            local i=obj.addEmptySource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();redrawViews()
        )
        on radiusSourceSpin changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v;redrawViews())
        on followRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:2;redrawViews())
        on showRadiusCheck changed v do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:3;redrawViews())
        on forwardAxis selected v do if not loadingColor do (obj.assignSourceForward plantList.selection v;redrawViews())
        on sourceZSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v;redrawViews())
        on sourceScaleSpin changed v do if not loadingColor do (obj.assignSourceTransform plantList.selection v scaling:true;redrawViews())
        on weightSpin changed v do if not loadingColor do (obj.assignWeight plantList.selection v;updateList();redrawViews())
        on plantList selected i do (
            if i>0 and plantList.selection[i] do focusedRow=i
        )
        on plantList selectionEnd do showSelectedColor()
        on existingGroups selected i do (
            if i>0 and i<=groupPalette.count do (
                local c=groupPalette[i]
                loadingColor=true;groupColor.color=c;loadingColor=false
                obj.assignGroup plantList.selection c;updateList();redrawViews()
            )
        )
        on groupColor changed c do (
            if not loadingColor and plantList.selection.numberSet>0 do (
                obj.assignGroup plantList.selection c
                updateList();redrawViews()
            )
        )
        on applyColor pressed do (
            obj.assignGroup plantList.selection groupColor.color
            updateList();redrawViews()
        )
        on selectFromScene pressed do (
            local picked=selectByName title:"Cyrus Scatter - Select From Scene" buttonText:"Add" filter:AminScatterSourceFilter single:false
            addSources picked
        )
        on addPlant picked n do addSources #(n)
        on addSelected pressed do addSources (selection as array)
        on removePlant pressed do (
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
            plantList.selection=#{};obj.dirty=true;updateList();redrawViews()
        )
        on selectPlant pressed do (
            local nodes=for i in plantList.selection where i<=obj.sources.count and isValidNode obj.sources[i] collect obj.sources[i]
            if nodes.count>0 do select nodes
        )

        on sourceUI_10 rolledUp state do parentView.layoutPanels()
        on sourceUI_10 open do (controlsReady=true;(updateList();showSelectedColor()))
    )
sourceUI_10.obj=target;sourceUI_10.parentView=view;sourceUI_10
)
global CyrusMake_distributionUI_10
fn CyrusMake_distributionUI_10 target view = (
    CyrusUIBuildView=view
    rollout distributionUI_10 "Point Generation" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on distributionUI_10 close do controlsReady=false
        radiobuttons modeRadio "Method" labels:#("Random","Texture Density") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        radiobuttons populationRadio "Population" labels:#("Count","Plants per m2") columns:1 pos:[(CyrusUISize 8 1),78] width:(CyrusUISize 146 1)
        checkbox showCenterCheck "Show Point" pos:[(CyrusUISize 8 1),148] width:(CyrusUISize 146 1)
        on showCenterCheck changed v do (obj.showCenters=v;redrawViews())
        spinner countSpin "Count: " range:[1,100000,200] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),174]
        spinner densitySpin "Per m2: " range:[0,1000000,100] fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),200]
        spinner seedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),226]
        label densityHeading "Texture density" pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)
        mapbutton densityButton "Choose density map" pos:[(CyrusUISize 8 1),284] width:(CyrusUISize 146 1)
        checkbox invertCheck "Invert density" pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        label uvHint "UV channel 1; 0..1" pos:[(CyrusUISize 8 1),338] width:(CyrusUISize 146 1)
        label mapHint "White: dense / Black: empty" pos:[(CyrusUISize 8 1),360] width:(CyrusUISize 146 1)

        fn syncControls = (populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;)
        on modeRadio changed v do (obj.distributionMode=if v==2 then 3 else 1;obj.dirty=true;syncControls();redrawViews())
        on countSpin changed v do (obj.amount=v;obj.dirty=true;syncControls();redrawViews())
        on seedSpin changed v do (obj.randomSeed=v;obj.dirty=true;syncControls();redrawViews())

        on populationRadio changed v do (obj.populationMode=v;obj.dirty=true;syncControls();redrawViews())
        on densitySpin changed v do (obj.plantsPerM2=v;obj.dirty=true;syncControls();redrawViews())
        on densityButton picked v do (obj.densityMap=v;obj.dirty=true;syncControls();redrawViews())
        on invertCheck changed v do (obj.invertDensity=v;obj.dirty=true;syncControls();redrawViews())
        on distributionUI_10 rolledUp state do parentView.layoutPanels()
        on distributionUI_10 open do (showCenterCheck.checked=obj.showCenters;populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;controlsReady=true;(countSpin.value=obj.amount;seedSpin.value=obj.randomSeed;modeRadio.state=if obj.distributionMode==3 then 2 else 1))
    )
distributionUI_10.obj=target;distributionUI_10.parentView=view;distributionUI_10
)
global CyrusMake_areaUI_10
fn CyrusMake_areaUI_10 target view = (
    CyrusUIBuildView=view
    rollout areaUI_10 "Area" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on areaUI_10 close do controlsReady=false
        multiListBox areaList "Closed lines / shapes" items:#() pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1) height:6
        button addAreaScene "Select From Scene..." pos:[(CyrusUISize 8 1),134] width:(CyrusUISize 146 1)
        pickbutton pickArea "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),160] width:(CyrusUISize 146 1)
        button removeArea "Remove selected rows" pos:[(CyrusUISize 8 1),186] width:(CyrusUISize 146 1)
        radiobuttons areaMode "Selected area mode" labels:#("Include","Exclude") columns:1 pos:[(CyrusUISize 8 1),220] width:(CyrusUISize 146 1)
        label areaHint "Exclude overrides Include." pos:[(CyrusUISize 8 1),290] width:(CyrusUISize 146 1)
        label projectionHint "Top / world XY projection." pos:[(CyrusUISize 8 1),312] width:(CyrusUISize 146 1)
        button refreshAreas "Refresh areas / preview" pos:[(CyrusUISize 8 1),340] width:(CyrusUISize 146 1)
        local loadingAnalyzerArea=false
        label aaTitle "Surface Analyzer Area" pos:[(CyrusUISize 8 1),378] width:(CyrusUISize 146 1)
        pickbutton aaPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),404] width:(CyrusUISize 146 1)
        button aaRemove "Remove Area Analyzer" pos:[(CyrusUISize 8 1),432] width:(CyrusUISize 146 1)
        checkbox aaLine "Center Line" pos:[(CyrusUISize 8 1),464] width:(CyrusUISize 146 1)
        spinner aaWidth "Full width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),490] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        dropdownlist aaCaps "Line ends" items:#("Flat","Round") selection:1 pos:[(CyrusUISize 8 1),518] width:(CyrusUISize 146 1)
        spinner aaStreetOffset "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),572] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox aaPoints "Points" pos:[(CyrusUISize 8 1),604] width:(CyrusUISize 146 1)
        spinner aaRadius "Radius:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),630] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label aaHelp "XY mask. Both enabled = union. Works with Random / Clusters." pos:[(CyrusUISize 8 1),660] width:(CyrusUISize 146 1) height:40
        fn syncAnalyzerArea = (
            loadingAnalyzerArea=true
            aaPick.text=if isValidNode obj.areaAnalyzer then obj.areaAnalyzer.name else "Pick Surface Analyzer"
            aaLine.checked=obj.areaUseLine;aaPoints.checked=obj.areaUsePoints
            aaStreetOffset.value=obj.centerStreetOffset;aaStreetOffset.enabled=obj.areaUseLine
            aaWidth.value=obj.areaLineWidth;aaRadius.value=obj.areaPointRadius;aaCaps.selection=obj.areaLineCaps
            aaWidth.enabled=obj.areaUseLine;aaCaps.enabled=obj.areaUseLine;aaRadius.enabled=obj.areaUsePoints
            loadingAnalyzerArea=false
        )
        on aaPick picked n do (obj.areaAnalyzer=n;syncAnalyzerArea();redrawViews())
        on aaRemove pressed do (obj.areaUseLine=false;obj.areaUsePoints=false;obj.areaAnalyzer=undefined;syncAnalyzerArea();redrawViews())
        on aaLine changed v do if not loadingAnalyzerArea do (obj.areaUseLine=v;syncAnalyzerArea();redrawViews())
        on aaPoints changed v do if not loadingAnalyzerArea do (obj.areaUsePoints=v;syncAnalyzerArea();redrawViews())
        on aaStreetOffset changed v do if not loadingAnalyzerArea do (obj.centerStreetOffset=v;redrawViews())
        on aaWidth changed v do if not loadingAnalyzerArea do (obj.areaLineWidth=v;redrawViews())
        on aaRadius changed v do if not loadingAnalyzerArea do (obj.areaPointRadius=v;redrawViews())
        on aaCaps selected v do if not loadingAnalyzerArea do (obj.areaLineCaps=v;redrawViews())

        local loadingFall=false
        dropdownlist fallTarget "Edge falloff target" items:#("Analyzer Boundary","Selected Area line") selection:1 pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        pickbutton fallPick "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1)
        button fallRemove "Remove Analyzer" pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1)
        label fallTargetName "" pos:[(CyrusUISize 8 1),818] width:(CyrusUISize 146 1) height:40
        checkbox fallDeleteCheck "Delete edge band" pos:[(CyrusUISize 8 1),860] width:(CyrusUISize 146 1)
        spinner fallDeleteSpin "Delete width:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        checkbox fallScaleCheck "Scale ramp" pos:[(CyrusUISize 8 1),918] width:(CyrusUISize 146 1)
        spinner fallScaleSpin "Scale width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),944] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallScaleEdit "Edit Scale Graph..." pos:[(CyrusUISize 8 1),974] width:(CyrusUISize 146 1)
        checkbox fallDensityCheck "Density ramp" pos:[(CyrusUISize 8 1),1010] width:(CyrusUISize 146 1)
        spinner fallDensitySpin "Density width:" range:[0,1e9,100] type:#worldunits pos:[(CyrusUISize 8 1),1036] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        button fallDensityEdit "Edit Density Graph..." pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1)
        label fallHelp "Ramps start after delete band. Each Area line has its own settings." pos:[(CyrusUISize 8 1),1104] width:(CyrusUISize 146 1) height:56
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
                if fallTarget.selection==1 or isValidNode n do (local cfg=obj.getFallConfig n;cfg[index]=value;obj.setFallConfig n cfg;redrawViews())
            )
        )
        on fallTarget selected v do syncFalloff()
        on fallPick picked n do (if CyrusAnalyzerFilter n do obj.fallAnalyzer=n;syncFalloff();redrawViews())
        on fallRemove pressed do (obj.fallAnalyzer=undefined;obj.fallDelete=false;obj.fallScale=false;obj.fallDensity=false;syncFalloff();redrawViews())
        on fallDeleteCheck changed v do setFallValue 1 v
        on fallDeleteSpin changed v do setFallValue 2 v
        on fallScaleCheck changed v do setFallValue 3 v
        on fallScaleSpin changed v do setFallValue 4 v
        on fallDensityCheck changed v do setFallValue 6 v
        on fallDensitySpin changed v do setFallValue 7 v
        on fallScaleEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) false
        on fallDensityEdit pressed do CyrusOpenFalloffGraph obj (fallNode()) true

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

        on pickArea picked n do (addArea n;updateAreas();redrawViews())
        on addAreaScene pressed do (
            local nodes=selectByName title:"Cyrus Scatter - Closed Areas" buttonText:"Add" filter:AminScatterAreaFilter single:false
            if nodes!=undefined do for n in nodes do addArea n
            updateAreas();redrawViews()
        )
        on areaList selectionEnd do (
            if areaList.selection.numberSet==1 do fallTarget.selection=2
            syncFalloff()
            if areaList.selection.numberSet>0 do areaMode.state=obj.areaModes[(areaList.selection as array)[1]]
        )
        on areaMode changed mode do (
            undo "Cyrus Scatter area mode" on (for i in areaList.selection do obj.areaModes[i]=mode)
            obj.dirty=true;updateAreas();redrawViews()
        )
        on removeArea pressed do (
            if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()
            local rows=areaList.selection as array
            undo "Cyrus Scatter remove areas" on (
                obj.ensureAreaFalloffs()
                for i=rows.count to 1 by -1 do (deleteItem obj.areaNodes rows[i];deleteItem obj.areaModes rows[i];deleteItem obj.areaFallConfigs rows[i];deleteItem obj.areaFallScaleGraphs rows[i];deleteItem obj.areaFallDensityGraphs rows[i])
            )
            areaList.selection=#{};obj.dirty=true;updateAreas();redrawViews()
        )
        on refreshAreas pressed do (obj.dirty=true;obj.refreshPreview();redrawViews())

        on areaUI_10 rolledUp state do parentView.layoutPanels()
        on areaUI_10 open do (syncAnalyzerArea();syncFalloff();controlsReady=true;updateAreas())
    )
areaUI_10.obj=target;areaUI_10.parentView=view;areaUI_10
)
global CyrusMake_diversityUI_10
fn CyrusMake_diversityUI_10 target view = (
    CyrusUIBuildView=view
    rollout diversityUI_10 "Diversity / Colors" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false,strokeExpandedHeight=0
        on diversityUI_10 close do controlsReady=false
        radiobuttons diversityRadio "Source assignment" labels:#("Random","Clusters","Line Pattern","Analyze Surface") columns:1 pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner sizeSpin "Size: " range:[0.01,100000,10] type:#worldUnits fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),104]
        spinner divSeedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:(CyrusUISize 64 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),130]
        spinner roughSpin "Roughness %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),156]
        spinner blurSpin "Blur edge %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),182]
        spinner noiseSpin "Noise %: " range:[0,100,0] fieldWidth:(CyrusUISize 54 1) width:(CyrusUISize 146 1) pos:[(CyrusUISize 8 1),208]
        label groupHint "Uses source group colors." pos:[(CyrusUISize 8 1),238] width:(CyrusUISize 146 1)
        label fixedHint "Point positions stay fixed." pos:[(CyrusUISize 8 1),260] width:(CyrusUISize 146 1)



    
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),118] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),142] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),192] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),218] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),250] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),346] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),346] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),372] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),406] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),434] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),506] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),618] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),644] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),676] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),870] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),898] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),940] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),968] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),996] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),1024] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1066] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1094] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1122] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),842] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),814] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),874] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),756] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),784] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),730] width:(CyrusUISize 146 1)
        fn syncControls = (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;syncControls();redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;syncControls();redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;syncControls();redrawViews())
        on refreshGroups pressed do updatePattern()
                fn updateControls = (
            for c in #(sizeSpin,divSeedSpin,roughSpin,blurSpin,noiseSpin,groupHint,fixedHint) do c.visible=obj.diversityMode==2
            for c in #(strokeTitle,pathsDrop,analyzerChannel,pickAnalyzer,pickPath,removePath,strokesList,addOutside,addInside,removeStrokeButton,strokeWidth,strokeMode,strokeChoices,strokeScaleMin,strokeScaleMax,refreshGroups,strokeHelp) do c.visible=(obj.diversityMode==3 or obj.diversityMode==4)
            if strokeExpandedHeight>0 do diversityUI_10.height=if obj.diversityMode>=3 then strokeExpandedHeight else (if obj.diversityMode==2 then 310 else 124)*parentView.dpiScale
            parentView.layoutPanels()
        )
        on diversityRadio changed v do (obj.diversityMode=v;updateControls();updatePattern();obj.dirty=true;syncControls();redrawViews())


        on sizeSpin changed v do (obj.diversitySize=v;obj.dirty=true;syncControls();redrawViews())
        on divSeedSpin changed v do (obj.diversitySeed=v;obj.dirty=true;syncControls();redrawViews())
        on roughSpin changed v do (obj.roughness=v;obj.dirty=true;syncControls();redrawViews())
        on blurSpin changed v do (obj.blurryEdge=v;obj.dirty=true;syncControls();redrawViews())
        on noiseSpin changed v do (obj.diversityNoise=v;obj.dirty=true;syncControls();redrawViews())
        on diversityUI_10 rolledUp state do parentView.layoutPanels()
        on diversityUI_10 open do (diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;controlsReady=true;strokeExpandedHeight=diversityUI_10.height;updateControls();updatePattern())
    )
diversityUI_10.obj=target;diversityUI_10.parentView=view;diversityUI_10
)
global CyrusMake_lineUI_10
fn CyrusMake_lineUI_10 target view = (
    CyrusUIBuildView=view
    rollout lineUI_10 "Line Pattern" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local pathRows=#(),strokeRows=#(),choiceValues=#(),restKeys=#(),loadingStroke=false
        label strokeTitle "Line Pattern / Strokes" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        dropdownlist pathsDrop "Paths" items:#() pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[(CyrusUISize 8 1),32] width:(CyrusUISize 146 1)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[(CyrusUISize 8 1),82] width:(CyrusUISize 146 1)
        button removePath "Remove path" pos:[(CyrusUISize 8 1),108] width:(CyrusUISize 146 1)
        listbox strokesList "Consecutive strokes" items:#() pos:[(CyrusUISize 8 1),140] width:(CyrusUISize 146 1) height:4
        button addOutside "Add Outside" pos:[(CyrusUISize 8 1),236] width:(CyrusUISize 70 1)
        button addInside "Add Inside" pos:[(CyrusUISize 84 1),236] width:(CyrusUISize 70 1)
        button removeStrokeButton "Remove Stroke" pos:[(CyrusUISize 8 1),262] width:(CyrusUISize 146 1)
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[(CyrusUISize 8 1),296] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 64 1)
        radiobuttons strokeMode "Assign by" labels:#("Color groups","Source objects") columns:1 pos:[(CyrusUISize 8 1),324] width:(CyrusUISize 146 1)
        multiListBox strokeChoices "Ctrl / Shift: select several" items:#() pos:[(CyrusUISize 8 1),396] width:(CyrusUISize 146 1) height:5
        spinner strokeScaleMin "Scale min:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),508] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        spinner strokeScaleMax "Scale max:" range:[0.001,100,1] pos:[(CyrusUISize 8 1),534] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 58 1)
        button refreshGroups "Refresh sources / groups" pos:[(CyrusUISize 8 1),566] width:(CyrusUISize 146 1)
        label strokeHelp "Outside strokes: empty." pos:[(CyrusUISize 8 1),594] width:(CyrusUISize 146 1)
        spinner edgeOffsetSpin "Offset inward:" range:[-1000000,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAlongSpin "Jitter along:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeAcrossSpin "Jitter across:" range:[0,1000000,0] type:#worldunits pos:[(CyrusUISize 8 1),760] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label edgeRowHelp "Spacing sets count. Jitter 0 = exact." pos:[(CyrusUISize 8 1),788] width:(CyrusUISize 146 1) height:36
        checkbox keepCornerCheck "Keep corner points" pos:[(CyrusUISize 8 1),830] width:(CyrusUISize 146 1)
        spinner cornerAngleSpin "Min turn:" range:[0,180,45] type:#float pos:[(CyrusUISize 8 1),858] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner cornerCountSpin "Points/corner:" range:[1,64,1] type:#integer pos:[(CyrusUISize 8 1),886] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        label cornerHelp "Turn angle in degrees. 0 = straight." pos:[(CyrusUISize 8 1),914] width:(CyrusUISize 146 1) height:36
        spinner edgeRotXSpin "Local X (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),956] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotYSpin "Local Y (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),984] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner edgeRotZSpin "Local Z (deg):" range:[-36000,36000,0] type:#float pos:[(CyrusUISize 8 1),1012] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        spinner streetStartSpin "Trim start:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner streetEndSpin "Trim end:" range:[0,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),732] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        spinner centerStreetSpin "Street offset:" range:[-1e9,1e9,0] type:#worldunits pos:[(CyrusUISize 8 1),704] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 62 1)
        label streetLayoutHelp "Positive offset = away from street. Trim follows path direction." pos:[(CyrusUISize 8 1),764] width:(CyrusUISize 146 1) height:44
        checkbox faceOutCheck "Face outward" pos:[(CyrusUISize 8 1),646] width:(CyrusUISize 146 1)
        spinner cornerRadiusSpin "Corner radius:" type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 1),674] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 52 1)
        checkbox straightStreet "Straight ends (Street Side)" pos:[(CyrusUISize 8 1),620] width:(CyrusUISize 146 1)
        on faceOutCheck changed v do (
            if analyzerChannel.selection==5 then obj.edgeFaceOut=v else if analyzerChannel.selection==4 then obj.streetFaceOut=v else obj.borderFaceOut=v
            cornerRadiusSpin.enabled=v;obj.dirty=true;redrawViews()
        )
        on cornerRadiusSpin changed v do (
            if analyzerChannel.selection==5 then obj.edgeCornerRadius=v else if analyzerChannel.selection==4 then obj.streetCornerRadius=v else obj.borderCornerRadius=v
            obj.dirty=true;redrawViews()
        )
        on streetStartSpin changed v do if not loadingStroke do (obj.streetTrimStart=v;redrawViews())
        on streetEndSpin changed v do if not loadingStroke do (obj.streetTrimEnd=v;redrawViews())
        on centerStreetSpin changed v do if not loadingStroke do (obj.centerStreetOffset=v;redrawViews())
        on straightStreet changed v do (obj.streetStraight=v;obj.dirty=true;redrawViews())
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
            addInside.pos=[(CyrusUISize (if boundaryOnly then 8 else 84) 1 view:parentView),addOutside.pos.y]
            addInside.width=CyrusUISize (if boundaryOnly then 146 else 70) 1 view:parentView
            if boundaryOnly do addInside.text=if analyzerChannel.selection==5 then "Add Edge Row" else "Add Stroke Inside"
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else "Outside strokes: empty."
            restKeys=#()
            for i=1 to obj.sources.count do (local key=obj.colorKey(obj.sourceColor i);if findItem restKeys key==0 do append restKeys key)
            showPath()
        )

        on pathsDrop selected i do showPath()
        on analyzerChannel selected i do updatePattern()
        on pickAnalyzer picked n do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.dirty=true;updatePattern();redrawViews())
        )
        on strokesList selected i do showStroke()
        on pickPath picked n do (
            if isValidNode n and findItem obj.patternPaths n==0 do append obj.patternPaths n
            updatePattern();pathsDrop.selection=findItem pathRows n;showPath()
        )
        on removePath pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            for i=obj.patternLines.count to 1 by -1 where obj.patternLines[i]==path do obj.removeStroke i
            local k=findItem obj.patternPaths path;if k>0 do deleteItem obj.patternPaths k
            if obj.diversityMode==4 do obj.analyzerNode=undefined
            updatePattern();obj.dirty=true;redrawViews()
        )
        on addOutside pressed do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on addInside pressed do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else pathRows[pathsDrop.selection]
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            obj.addStroke path side:side;showPath();strokesList.selection=strokeRows.count;showStroke();redrawViews()
        )
        on removeStrokeButton pressed do (local row=selectedStroke();if row>0 do obj.removeStroke row;showPath();redrawViews())
        on edgeOffsetSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsets[row]=v;redrawViews())
        on edgeAlongSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlong[row]=v;redrawViews())
        on edgeAcrossSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcross[row]=v;redrawViews())
        on keepCornerCheck changed v do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;redrawViews())
        on cornerAngleSpin changed v do if not loadingStroke do (obj.edgeCornerAngle=v;redrawViews())
        on cornerCountSpin changed v do if not loadingStroke do (obj.edgeCornerCount=v;redrawViews())
        on edgeRotXSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;redrawViews())
        on edgeRotYSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;redrawViews())
        on edgeRotZSpin changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;redrawViews())
        on strokeWidth changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.dirty=true;showPath();redrawViews())
        on strokeMode changed v do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeChoices selectionEnd do if not loadingStroke do (
            local row=selectedStroke()
            if row>0 do obj.setStrokeSelection row obj.strokeModes[row] (for i in strokeChoices.selection collect choiceValues[i])
            redrawViews()
        )
        on strokeScaleMin changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.dirty=true;redrawViews())
        on strokeScaleMax changed v do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.dirty=true;redrawViews())
        on refreshGroups pressed do updatePattern()

        on lineUI_10 rolledUp state do parentView.layoutPanels()
        on lineUI_10 open do updatePattern()
    )
lineUI_10.obj=target;lineUI_10.parentView=view;lineUI_10
)
global CyrusMake_randomUI_10
fn CyrusMake_randomUI_10 target view = (
    CyrusUIBuildView=view
    rollout randomUI_10 "Randomize XYZ" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView
        local controlsReady=false
        on randomUI_10 close do controlsReady=false
        label rotTitle "Rotation (degrees)" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        label rotMinTitle "Min" pos:[(CyrusUISize 24 1),30] width:(CyrusUISize 58 1)
        label rotMaxTitle "Max" pos:[(CyrusUISize 94 1),30] width:(CyrusUISize 58 1)
        label rotXLabel "X" pos:[(CyrusUISize 8 1),52] width:(CyrusUISize 12 1)
        spinner rotXMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotXMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),50] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotYLabel "Y" pos:[(CyrusUISize 8 1),76] width:(CyrusUISize 12 1)
        spinner rotYMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotYMaxSpin "" range:[-360,360,0]  pos:[(CyrusUISize 94 1),74] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label rotZLabel "Z" pos:[(CyrusUISize 8 1),100] width:(CyrusUISize 12 1)
        spinner rotZMinSpin "" range:[-360,360,0]  pos:[(CyrusUISize 24 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner rotZMaxSpin "" range:[-360,360,360]  pos:[(CyrusUISize 94 1),98] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclTitle "Scale (multiplier)" pos:[(CyrusUISize 8 1),132] width:(CyrusUISize 146 1)
        label sclMinTitle "Min" pos:[(CyrusUISize 24 1),154] width:(CyrusUISize 58 1)
        label sclMaxTitle "Max" pos:[(CyrusUISize 94 1),154] width:(CyrusUISize 58 1)
        label sclXLabel "X" pos:[(CyrusUISize 8 1),176] width:(CyrusUISize 12 1)
        spinner sclXMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclXMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),174] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclYLabel "Y" pos:[(CyrusUISize 8 1),200] width:(CyrusUISize 12 1)
        spinner sclYMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclYMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),198] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label sclZLabel "Z" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 12 1)
        spinner sclZMinSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 24 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner sclZMaxSpin "" range:[0.001,100,1]  pos:[(CyrusUISize 94 1),222] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label wholeTitle "Whole Scale (uniform)" pos:[(CyrusUISize 8 1),252] width:(CyrusUISize 146 1)
        label wholeMinTitle "Min" pos:[(CyrusUISize 24 1),274] width:(CyrusUISize 58 1)
        label wholeMaxTitle "Max" pos:[(CyrusUISize 94 1),274] width:(CyrusUISize 58 1)
        spinner wholeMinSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 24 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner wholeMaxSpin "" range:[0.001,1000,1] scale:0.01 pos:[(CyrusUISize 94 1),296] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        on wholeMinSpin changed v do (obj.wholeScaleMin=v;if v>obj.wholeScaleMax do (obj.wholeScaleMax=v;wholeMaxSpin.value=v);redrawViews())
        on wholeMaxSpin changed v do (obj.wholeScaleMax=v;if v<obj.wholeScaleMin do (obj.wholeScaleMin=v;wholeMinSpin.value=v);redrawViews())
        label movTitle "Movement (world units)" pos:[(CyrusUISize 8 1),332] width:(CyrusUISize 146 1)
        label movMinTitle "Min" pos:[(CyrusUISize 24 1),354] width:(CyrusUISize 58 1)
        label movMaxTitle "Max" pos:[(CyrusUISize 94 1),354] width:(CyrusUISize 58 1)
        label movXLabel "X" pos:[(CyrusUISize 8 1),376] width:(CyrusUISize 12 1)
        spinner movXMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movXMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),374] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movYLabel "Y" pos:[(CyrusUISize 8 1),400] width:(CyrusUISize 12 1)
        spinner movYMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movYMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),398] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        label movZLabel "Z" pos:[(CyrusUISize 8 1),424] width:(CyrusUISize 12 1)
        spinner movZMinSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 24 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        spinner movZMaxSpin "" range:[-100000,100000,0] type:#worldUnits pos:[(CyrusUISize 94 1),422] fieldWidth:(CyrusUISize 46 1) width:(CyrusUISize 58 1)
        checkbox projectCheck "Keep on surface" pos:[(CyrusUISize 8 1),456] width:(CyrusUISize 146 1)
        checkbox alignCheck "Align to normal" pos:[(CyrusUISize 8 1),480] width:(CyrusUISize 146 1)

        fn syncControls = (projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;)
        on alignCheck changed v do (obj.alignNormal=v;obj.dirty=true;syncControls();redrawViews())

        on projectCheck changed v do (obj.projectMove=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMinSpin changed v do (obj.rotXMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotXMaxSpin changed v do (obj.rotXMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMinSpin changed v do (obj.rotYMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotYMaxSpin changed v do (obj.rotYMax=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMinSpin changed v do (obj.rotZMin=v;obj.dirty=true;syncControls();redrawViews())
        on rotZMaxSpin changed v do (obj.rotZMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMinSpin changed v do (obj.sclXMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclXMaxSpin changed v do (obj.sclXMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMinSpin changed v do (obj.sclYMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclYMaxSpin changed v do (obj.sclYMax=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMinSpin changed v do (obj.sclZMin=v;obj.dirty=true;syncControls();redrawViews())
        on sclZMaxSpin changed v do (obj.sclZMax=v;obj.dirty=true;syncControls();redrawViews())
        on movXMinSpin changed v do (obj.movXMin=v;obj.dirty=true;syncControls();redrawViews())
        on movXMaxSpin changed v do (obj.movXMax=v;obj.dirty=true;syncControls();redrawViews())
        on movYMinSpin changed v do (obj.movYMin=v;obj.dirty=true;syncControls();redrawViews())
        on movYMaxSpin changed v do (obj.movYMax=v;obj.dirty=true;syncControls();redrawViews())
        on movZMinSpin changed v do (obj.movZMin=v;obj.dirty=true;syncControls();redrawViews())
        on movZMaxSpin changed v do (obj.movZMax=v;obj.dirty=true;syncControls();redrawViews())
        on randomUI_10 rolledUp state do parentView.layoutPanels()
        on randomUI_10 open do (wholeMinSpin.value=obj.wholeScaleMin;wholeMaxSpin.value=obj.wholeScaleMax;projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMin;movXMaxSpin.value=obj.movXMax;movYMinSpin.value=obj.movYMin;movYMaxSpin.value=obj.movYMax;movZMinSpin.value=obj.movZMin;movZMaxSpin.value=obj.movZMax;controlsReady=true;alignCheck.checked=obj.alignNormal)
    )
randomUI_10.obj=target;randomUI_10.parentView=view;randomUI_10
)
global CyrusUIBuildTarget,CyrusUIBuildView,CyrusUIBuildIndex,CyrusMount
fn CyrusMount host r collapsed = (
    CyrusUIBuildTarget=r.obj;CyrusUIBuildView=r.parentView
    CyrusUIBuildIndex=try(r.layerIndex)catch(0)
    addSubRollout host r rolledUp:collapsed
    CyrusUIBuildTarget=undefined;CyrusUIBuildView=undefined
)
fn CyrusMakeManager target view = (
    CyrusUIBuildView=view
    rollout manager "Layer Manager" width:(CyrusUISize 162 0) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,refreshing=false
        dotNetControl layerList "System.Windows.Forms.ListView" pos:[(CyrusUISize 8 0),8] width:(CyrusUISize 146 0) height:120
        button addButton "Add Layer" pos:[(CyrusUISize 8 0),136] width:(CyrusUISize 146 0)
        button removeButton "Remove Layer" pos:[(CyrusUISize 8 0),162] width:(CyrusUISize 146 0)
        edittext nameEdit "Name:" pos:[(CyrusUISize 8 0),196] width:(CyrusUISize 146 0)
        local blockerRows=#()
        label overlapTitle "Remove Overlaps" pos:[(CyrusUISize 8 0),226] width:(CyrusUISize 146 0)
        checkbox overlapCheck "Enable" pos:[(CyrusUISize 8 0),249] width:(CyrusUISize 146 0)
        multiListBox blockerList "Blocking layers (Ctrl/Shift)" pos:[(CyrusUISize 8 0),273] width:(CyrusUISize 146 0) height:5
        spinner radiusSpin "Radius: " type:#worldunits range:[0,1000000,10] pos:[(CyrusUISize 8 0),383] width:(CyrusUISize 146 0) fieldWidth:(CyrusUISize 62 0)
        spinner gapSpin "Extra gap: " type:#worldunits range:[0,1000000,0] pos:[(CyrusUISize 8 0),409] width:(CyrusUISize 146 0) fieldWidth:(CyrusUISize 62 0)
        checkbox planarCheck "Plan XY (ignore height)" checked:true pos:[(CyrusUISize 8 0),435] width:(CyrusUISize 146 0)
        label overlapInfo "Before / Removed / Left" pos:[(CyrusUISize 8 0),461] width:(CyrusUISize 146 0)
        label overlapCounts "-- / -- / --" pos:[(CyrusUISize 8 0),481] width:(CyrusUISize 146 0)
        button statsButton "Refresh counts" pos:[(CyrusUISize 8 0),505] width:(CyrusUISize 146 0)
        dropdownlist radiusMode "Collision radius" items:#("Fixed Radius","Source Radius") pos:[(CyrusUISize 8 0),535] width:(CyrusUISize 146 0)
        label finalTitle "Final Cleanup / Boundary Relax" pos:[(CyrusUISize 8 0),590] width:(CyrusUISize 146 0)
        checkbox cleanCheck "Remove isolated points" pos:[(CyrusUISize 8 0),615] width:(CyrusUISize 146 0)
        spinner neighborSpin "Neighbor radius:" type:#worldunits range:[0.001,1e9,100] pos:[(CyrusUISize 8 0),642] width:(CyrusUISize 146 0) fieldWidth:(CyrusUISize 55 0)
        spinner minNeighborSpin "Min neighbors:" type:#integer range:[0,10000,2] pos:[(CyrusUISize 8 0),669] width:(CyrusUISize 146 0) fieldWidth:(CyrusUISize 55 0)
        spinner minIslandSpin "Min island size:" type:#integer range:[0,100000,5] pos:[(CyrusUISize 8 0),696] width:(CyrusUISize 146 0) fieldWidth:(CyrusUISize 55 0)
        checkbox boundaryRelaxCheck "Boundary Relax (move only)" pos:[(CyrusUISize 8 0),724] width:(CyrusUISize 146 0)
        spinner finalStrengthSpin "Strength:" range:[0,1,.3] pos:[(CyrusUISize 8 0),751] width:(CyrusUISize 146 0) fieldWidth:(CyrusUISize 55 0)
        spinner finalIterSpin "Iterations:" type:#integer range:[0,100,5] pos:[(CyrusUISize 8 0),778] width:(CyrusUISize 146 0) fieldWidth:(CyrusUISize 55 0)
        spinner finalMoveSpin "Max movement:" type:#worldunits range:[0,1e9,10] pos:[(CyrusUISize 8 0),805] width:(CyrusUISize 146 0) fieldWidth:(CyrusUISize 55 0)
        fn currentLayer = (if obj.activeLayer>0 and obj.activeLayer<=obj.layerObjects.count then obj.layerObjects[obj.activeLayer] else undefined)
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
            refreshing=false
        )
        fn changedOverlap = (for layer in obj.layerObjects do layer.dirty=true;redrawViews())
        on overlapCheck changed v do if not refreshing do (undo "Remove overlaps" on (currentLayer()).overlapEnabled=v;changedOverlap())
        on radiusMode selected i do if not refreshing do ((currentLayer()).overlapSourceRadius=i==2;changedOverlap())
        on cleanCheck changed v do if not refreshing and currentLayer()!=undefined do (undo "Final cleanup setting" on (currentLayer()).finalCleanup=v;changedOverlap())
        on neighborSpin changed v do if not refreshing and currentLayer()!=undefined do (undo "Final cleanup setting" on (currentLayer()).finalNeighborRadius=v;changedOverlap())
        on minNeighborSpin changed v do if not refreshing and currentLayer()!=undefined do (undo "Final cleanup setting" on (currentLayer()).finalMinNeighbors=v;changedOverlap())
        on minIslandSpin changed v do if not refreshing and currentLayer()!=undefined do (undo "Final cleanup setting" on (currentLayer()).finalMinIsland=v;changedOverlap())
        on boundaryRelaxCheck changed v do if not refreshing and currentLayer()!=undefined do (undo "Final cleanup setting" on (currentLayer()).finalRelax=v;changedOverlap())
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
        fn refresh = (
            refreshing=true;layerList.BeginUpdate();layerList.Items.Clear()
            for i=1 to obj.layerNames.count do (
                local item=layerList.Items.Add obj.layerNames[i]
                item.Checked=obj.layerEnabled[i]
                item.Selected=i==obj.activeLayer
            )
            layerList.EndUpdate();refreshing=false
            local valid=obj.activeLayer>0 and obj.activeLayer<=obj.layerNames.count
            nameEdit.enabled=valid;removeButton.enabled=valid
            addButton.enabled=obj.layerNames.count<10
            nameEdit.text=if valid then obj.layerNames[obj.activeLayer] else ""
            refreshOverlap()
        )
        on manager open do (
            layerList.View=(dotNetClass "System.Windows.Forms.View").Details
            layerList.HeaderStyle=(dotNetClass "System.Windows.Forms.ColumnHeaderStyle").None
            layerList.CheckBoxes=true;layerList.MultiSelect=false;layerList.FullRowSelect=true;layerList.HideSelection=false
            layerList.BackColor=(dotNetClass "System.Drawing.Color").FromArgb 80 80 80
            layerList.ForeColor=(dotNetClass "System.Drawing.Color").WhiteSmoke
            layerList.Columns.Add "Layer" (layerList.ClientSize.Width-4)
            refresh()
        )
        on manager rolledUp state do (if not state do refreshOverlap();parentView.layoutPanels())
        on layerList SelectedIndexChanged sender args do (
            if not refreshing and layerList.SelectedIndices.Count>0 do (
                obj.selectLayer (layerList.SelectedIndices.Item[0]+1)
                nameEdit.text=obj.layerNames[obj.activeLayer]
                refreshOverlap()
            )
        )
        on layerList ItemChecked sender args do (
            if not refreshing do (
                local i=args.Item.Index+1
                if i>0 and i<=obj.layerEnabled.count do undo "Cyrus Scatter enable layer" on obj.layerEnabled[i]=args.Item.Checked
                redrawViews()
            )
        )
        on addButton pressed do (obj.newLayer();parentView.rebuildLayers();refresh();redrawViews())
        on removeButton pressed do (obj.removeLayer();parentView.rebuildLayers();refresh();redrawViews())
        on nameEdit entered value do (
            if obj.activeLayer>0 and value!="" do undo "Cyrus Scatter rename layer" on obj.layerNames[obj.activeLayer]=value
            parentView.refreshTitles();refresh()
        )
    )
    manager.obj=target;manager.parentView=view;manager
)
global CyrusMake_spacingUI_1
fn CyrusMake_spacingUI_1 target view = (
    CyrusUIBuildView=view
    rollout spacingUI_1 "Collision / Relax" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,ready=false
        checkbox collisionCheck "Enable collision" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner radiusSpin "Radius: " pos:[(CyrusUISize 8 1),34] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.1]
        label radiusHint "Min gap = 2 x radius" pos:[(CyrusUISize 8 1),62] width:(CyrusUISize 146 1)
        checkbox relaxCheck "Enable relax" pos:[(CyrusUISize 8 1),94] width:(CyrusUISize 146 1)
        spinner spacingSpin "Spacing: " pos:[(CyrusUISize 8 1),120] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.2]
        spinner iterationsSpin "Iterations: " pos:[(CyrusUISize 8 1),146] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) type:#integer range:[1,100,10]
        spinner strengthSpin "Strength %: " pos:[(CyrusUISize 8 1),172] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) range:[0,100,50]
        label orderHint "Relax, then collision" pos:[(CyrusUISize 8 1),202] width:(CyrusUISize 146 1)
        label layerHint "Within this layer only" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 146 1)
        fn syncControls = (
            ready=false
            collisionCheck.checked=obj.collisionEnabled;radiusSpin.value=obj.collisionRadius;radiusSpin.enabled=obj.collisionEnabled
            relaxCheck.checked=obj.relaxEnabled;spacingSpin.value=obj.relaxSpacing;iterationsSpin.value=obj.relaxIterations;strengthSpin.value=obj.relaxStrength*100
            spacingSpin.enabled=obj.relaxEnabled;iterationsSpin.enabled=obj.relaxEnabled;strengthSpin.enabled=obj.relaxEnabled
            ready=true
        )
        on collisionCheck changed v do if ready do (obj.collisionEnabled=v;syncControls();redrawViews())
        on radiusSpin changed v do if ready do (obj.collisionRadius=v;redrawViews())
        on relaxCheck changed v do if ready do (obj.relaxEnabled=v;syncControls();redrawViews())
        on spacingSpin changed v do if ready do (obj.relaxSpacing=v;redrawViews())
        on iterationsSpin changed v do if ready do (obj.relaxIterations=v;redrawViews())
        on strengthSpin changed v do if ready do (obj.relaxStrength=v/100.0;redrawViews())
        on spacingUI_1 open do syncControls()
        on spacingUI_1 close do ready=false
        on spacingUI_1 rolledUp state do (parentView.layoutPanels();for c in spacingUI_1.controls do c.visible=false;for c in spacingUI_1.controls do c.visible=true)
    )
    spacingUI_1.obj=target;spacingUI_1.parentView=view;spacingUI_1
)

global CyrusMakeLayer_1
fn CyrusMakeLayer_1 target view index = (
    CyrusUIBuildView=view
    rollout layerPanel_1 "Layer" width:(CyrusUISize 162 0) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,layerIndex=CyrusUIBuildIndex,children=#()
        subrollout sections "" pos:[(CyrusUISize 8 0),2] width:(CyrusUISize 158 0) height:180
        fn fitHeight = (
            local h=0
            local dpi=parentView.dpiScale
            local header=floor(23.333*dpi+0.5)
            for r in children do h+=(if r.open then r.height+header else header)
            sections.pos=[2,0];sections.height=h;layerPanel_1.height=h
        )
        fn ensureContents = (
            if children.count==0 do (
            children=#(CyrusMake_sourceUI_1 obj parentView,CyrusMake_distributionUI_1 obj parentView,CyrusMake_spacingUI_1 obj parentView,CyrusMake_areaUI_1 obj parentView,CyrusMake_diversityUI_1 obj parentView,CyrusMake_randomUI_1 obj parentView)
            for r in children do CyrusMount sections r true
            fitHeight()
            )
        )
        on layerPanel_1 open do (children=#();layerPanel_1.height=24)
        on layerPanel_1 close do (children=#())
        on layerPanel_1 rolledUp state do (if not state and not parentView.building do ensureContents();parentView.layoutPanels())
    )
    layerPanel_1.obj=target;layerPanel_1.parentView=view;layerPanel_1.layerIndex=index;layerPanel_1
)






global CyrusMake_spacingUI_2
fn CyrusMake_spacingUI_2 target view = (
    CyrusUIBuildView=view
    rollout spacingUI_2 "Collision / Relax" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,ready=false
        checkbox collisionCheck "Enable collision" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner radiusSpin "Radius: " pos:[(CyrusUISize 8 1),34] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.1]
        label radiusHint "Min gap = 2 x radius" pos:[(CyrusUISize 8 1),62] width:(CyrusUISize 146 1)
        checkbox relaxCheck "Enable relax" pos:[(CyrusUISize 8 1),94] width:(CyrusUISize 146 1)
        spinner spacingSpin "Spacing: " pos:[(CyrusUISize 8 1),120] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.2]
        spinner iterationsSpin "Iterations: " pos:[(CyrusUISize 8 1),146] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) type:#integer range:[1,100,10]
        spinner strengthSpin "Strength %: " pos:[(CyrusUISize 8 1),172] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) range:[0,100,50]
        label orderHint "Relax, then collision" pos:[(CyrusUISize 8 1),202] width:(CyrusUISize 146 1)
        label layerHint "Within this layer only" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 146 1)
        fn syncControls = (
            ready=false
            collisionCheck.checked=obj.collisionEnabled;radiusSpin.value=obj.collisionRadius;radiusSpin.enabled=obj.collisionEnabled
            relaxCheck.checked=obj.relaxEnabled;spacingSpin.value=obj.relaxSpacing;iterationsSpin.value=obj.relaxIterations;strengthSpin.value=obj.relaxStrength*100
            spacingSpin.enabled=obj.relaxEnabled;iterationsSpin.enabled=obj.relaxEnabled;strengthSpin.enabled=obj.relaxEnabled
            ready=true
        )
        on collisionCheck changed v do if ready do (obj.collisionEnabled=v;syncControls();redrawViews())
        on radiusSpin changed v do if ready do (obj.collisionRadius=v;redrawViews())
        on relaxCheck changed v do if ready do (obj.relaxEnabled=v;syncControls();redrawViews())
        on spacingSpin changed v do if ready do (obj.relaxSpacing=v;redrawViews())
        on iterationsSpin changed v do if ready do (obj.relaxIterations=v;redrawViews())
        on strengthSpin changed v do if ready do (obj.relaxStrength=v/100.0;redrawViews())
        on spacingUI_2 open do syncControls()
        on spacingUI_2 close do ready=false
        on spacingUI_2 rolledUp state do (parentView.layoutPanels();for c in spacingUI_2.controls do c.visible=false;for c in spacingUI_2.controls do c.visible=true)
    )
    spacingUI_2.obj=target;spacingUI_2.parentView=view;spacingUI_2
)

global CyrusMakeLayer_2
fn CyrusMakeLayer_2 target view index = (
    CyrusUIBuildView=view
    rollout layerPanel_2 "Layer" width:(CyrusUISize 162 0) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,layerIndex=CyrusUIBuildIndex,children=#()
        subrollout sections "" pos:[(CyrusUISize 8 0),2] width:(CyrusUISize 158 0) height:180
        fn fitHeight = (
            local h=0
            local dpi=parentView.dpiScale
            local header=floor(23.333*dpi+0.5)
            for r in children do h+=(if r.open then r.height+header else header)
            sections.pos=[2,0];sections.height=h;layerPanel_2.height=h
        )
        fn ensureContents = (
            if children.count==0 do (
            children=#(CyrusMake_sourceUI_2 obj parentView,CyrusMake_distributionUI_2 obj parentView,CyrusMake_spacingUI_2 obj parentView,CyrusMake_areaUI_2 obj parentView,CyrusMake_diversityUI_2 obj parentView,CyrusMake_randomUI_2 obj parentView)
            for r in children do CyrusMount sections r true
            fitHeight()
            )
        )
        on layerPanel_2 open do (children=#();layerPanel_2.height=24)
        on layerPanel_2 close do (children=#())
        on layerPanel_2 rolledUp state do (if not state and not parentView.building do ensureContents();parentView.layoutPanels())
    )
    layerPanel_2.obj=target;layerPanel_2.parentView=view;layerPanel_2.layerIndex=index;layerPanel_2
)






global CyrusMake_spacingUI_3
fn CyrusMake_spacingUI_3 target view = (
    CyrusUIBuildView=view
    rollout spacingUI_3 "Collision / Relax" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,ready=false
        checkbox collisionCheck "Enable collision" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner radiusSpin "Radius: " pos:[(CyrusUISize 8 1),34] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.1]
        label radiusHint "Min gap = 2 x radius" pos:[(CyrusUISize 8 1),62] width:(CyrusUISize 146 1)
        checkbox relaxCheck "Enable relax" pos:[(CyrusUISize 8 1),94] width:(CyrusUISize 146 1)
        spinner spacingSpin "Spacing: " pos:[(CyrusUISize 8 1),120] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.2]
        spinner iterationsSpin "Iterations: " pos:[(CyrusUISize 8 1),146] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) type:#integer range:[1,100,10]
        spinner strengthSpin "Strength %: " pos:[(CyrusUISize 8 1),172] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) range:[0,100,50]
        label orderHint "Relax, then collision" pos:[(CyrusUISize 8 1),202] width:(CyrusUISize 146 1)
        label layerHint "Within this layer only" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 146 1)
        fn syncControls = (
            ready=false
            collisionCheck.checked=obj.collisionEnabled;radiusSpin.value=obj.collisionRadius;radiusSpin.enabled=obj.collisionEnabled
            relaxCheck.checked=obj.relaxEnabled;spacingSpin.value=obj.relaxSpacing;iterationsSpin.value=obj.relaxIterations;strengthSpin.value=obj.relaxStrength*100
            spacingSpin.enabled=obj.relaxEnabled;iterationsSpin.enabled=obj.relaxEnabled;strengthSpin.enabled=obj.relaxEnabled
            ready=true
        )
        on collisionCheck changed v do if ready do (obj.collisionEnabled=v;syncControls();redrawViews())
        on radiusSpin changed v do if ready do (obj.collisionRadius=v;redrawViews())
        on relaxCheck changed v do if ready do (obj.relaxEnabled=v;syncControls();redrawViews())
        on spacingSpin changed v do if ready do (obj.relaxSpacing=v;redrawViews())
        on iterationsSpin changed v do if ready do (obj.relaxIterations=v;redrawViews())
        on strengthSpin changed v do if ready do (obj.relaxStrength=v/100.0;redrawViews())
        on spacingUI_3 open do syncControls()
        on spacingUI_3 close do ready=false
        on spacingUI_3 rolledUp state do (parentView.layoutPanels();for c in spacingUI_3.controls do c.visible=false;for c in spacingUI_3.controls do c.visible=true)
    )
    spacingUI_3.obj=target;spacingUI_3.parentView=view;spacingUI_3
)

global CyrusMakeLayer_3
fn CyrusMakeLayer_3 target view index = (
    CyrusUIBuildView=view
    rollout layerPanel_3 "Layer" width:(CyrusUISize 162 0) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,layerIndex=CyrusUIBuildIndex,children=#()
        subrollout sections "" pos:[(CyrusUISize 8 0),2] width:(CyrusUISize 158 0) height:180
        fn fitHeight = (
            local h=0
            local dpi=parentView.dpiScale
            local header=floor(23.333*dpi+0.5)
            for r in children do h+=(if r.open then r.height+header else header)
            sections.pos=[2,0];sections.height=h;layerPanel_3.height=h
        )
        fn ensureContents = (
            if children.count==0 do (
            children=#(CyrusMake_sourceUI_3 obj parentView,CyrusMake_distributionUI_3 obj parentView,CyrusMake_spacingUI_3 obj parentView,CyrusMake_areaUI_3 obj parentView,CyrusMake_diversityUI_3 obj parentView,CyrusMake_randomUI_3 obj parentView)
            for r in children do CyrusMount sections r true
            fitHeight()
            )
        )
        on layerPanel_3 open do (children=#();layerPanel_3.height=24)
        on layerPanel_3 close do (children=#())
        on layerPanel_3 rolledUp state do (if not state and not parentView.building do ensureContents();parentView.layoutPanels())
    )
    layerPanel_3.obj=target;layerPanel_3.parentView=view;layerPanel_3.layerIndex=index;layerPanel_3
)






global CyrusMake_spacingUI_4
fn CyrusMake_spacingUI_4 target view = (
    CyrusUIBuildView=view
    rollout spacingUI_4 "Collision / Relax" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,ready=false
        checkbox collisionCheck "Enable collision" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner radiusSpin "Radius: " pos:[(CyrusUISize 8 1),34] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.1]
        label radiusHint "Min gap = 2 x radius" pos:[(CyrusUISize 8 1),62] width:(CyrusUISize 146 1)
        checkbox relaxCheck "Enable relax" pos:[(CyrusUISize 8 1),94] width:(CyrusUISize 146 1)
        spinner spacingSpin "Spacing: " pos:[(CyrusUISize 8 1),120] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.2]
        spinner iterationsSpin "Iterations: " pos:[(CyrusUISize 8 1),146] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) type:#integer range:[1,100,10]
        spinner strengthSpin "Strength %: " pos:[(CyrusUISize 8 1),172] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) range:[0,100,50]
        label orderHint "Relax, then collision" pos:[(CyrusUISize 8 1),202] width:(CyrusUISize 146 1)
        label layerHint "Within this layer only" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 146 1)
        fn syncControls = (
            ready=false
            collisionCheck.checked=obj.collisionEnabled;radiusSpin.value=obj.collisionRadius;radiusSpin.enabled=obj.collisionEnabled
            relaxCheck.checked=obj.relaxEnabled;spacingSpin.value=obj.relaxSpacing;iterationsSpin.value=obj.relaxIterations;strengthSpin.value=obj.relaxStrength*100
            spacingSpin.enabled=obj.relaxEnabled;iterationsSpin.enabled=obj.relaxEnabled;strengthSpin.enabled=obj.relaxEnabled
            ready=true
        )
        on collisionCheck changed v do if ready do (obj.collisionEnabled=v;syncControls();redrawViews())
        on radiusSpin changed v do if ready do (obj.collisionRadius=v;redrawViews())
        on relaxCheck changed v do if ready do (obj.relaxEnabled=v;syncControls();redrawViews())
        on spacingSpin changed v do if ready do (obj.relaxSpacing=v;redrawViews())
        on iterationsSpin changed v do if ready do (obj.relaxIterations=v;redrawViews())
        on strengthSpin changed v do if ready do (obj.relaxStrength=v/100.0;redrawViews())
        on spacingUI_4 open do syncControls()
        on spacingUI_4 close do ready=false
        on spacingUI_4 rolledUp state do (parentView.layoutPanels();for c in spacingUI_4.controls do c.visible=false;for c in spacingUI_4.controls do c.visible=true)
    )
    spacingUI_4.obj=target;spacingUI_4.parentView=view;spacingUI_4
)

global CyrusMakeLayer_4
fn CyrusMakeLayer_4 target view index = (
    CyrusUIBuildView=view
    rollout layerPanel_4 "Layer" width:(CyrusUISize 162 0) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,layerIndex=CyrusUIBuildIndex,children=#()
        subrollout sections "" pos:[(CyrusUISize 8 0),2] width:(CyrusUISize 158 0) height:180
        fn fitHeight = (
            local h=0
            local dpi=parentView.dpiScale
            local header=floor(23.333*dpi+0.5)
            for r in children do h+=(if r.open then r.height+header else header)
            sections.pos=[2,0];sections.height=h;layerPanel_4.height=h
        )
        fn ensureContents = (
            if children.count==0 do (
            children=#(CyrusMake_sourceUI_4 obj parentView,CyrusMake_distributionUI_4 obj parentView,CyrusMake_spacingUI_4 obj parentView,CyrusMake_areaUI_4 obj parentView,CyrusMake_diversityUI_4 obj parentView,CyrusMake_randomUI_4 obj parentView)
            for r in children do CyrusMount sections r true
            fitHeight()
            )
        )
        on layerPanel_4 open do (children=#();layerPanel_4.height=24)
        on layerPanel_4 close do (children=#())
        on layerPanel_4 rolledUp state do (if not state and not parentView.building do ensureContents();parentView.layoutPanels())
    )
    layerPanel_4.obj=target;layerPanel_4.parentView=view;layerPanel_4.layerIndex=index;layerPanel_4
)






global CyrusMake_spacingUI_5
fn CyrusMake_spacingUI_5 target view = (
    CyrusUIBuildView=view
    rollout spacingUI_5 "Collision / Relax" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,ready=false
        checkbox collisionCheck "Enable collision" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner radiusSpin "Radius: " pos:[(CyrusUISize 8 1),34] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.1]
        label radiusHint "Min gap = 2 x radius" pos:[(CyrusUISize 8 1),62] width:(CyrusUISize 146 1)
        checkbox relaxCheck "Enable relax" pos:[(CyrusUISize 8 1),94] width:(CyrusUISize 146 1)
        spinner spacingSpin "Spacing: " pos:[(CyrusUISize 8 1),120] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.2]
        spinner iterationsSpin "Iterations: " pos:[(CyrusUISize 8 1),146] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) type:#integer range:[1,100,10]
        spinner strengthSpin "Strength %: " pos:[(CyrusUISize 8 1),172] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) range:[0,100,50]
        label orderHint "Relax, then collision" pos:[(CyrusUISize 8 1),202] width:(CyrusUISize 146 1)
        label layerHint "Within this layer only" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 146 1)
        fn syncControls = (
            ready=false
            collisionCheck.checked=obj.collisionEnabled;radiusSpin.value=obj.collisionRadius;radiusSpin.enabled=obj.collisionEnabled
            relaxCheck.checked=obj.relaxEnabled;spacingSpin.value=obj.relaxSpacing;iterationsSpin.value=obj.relaxIterations;strengthSpin.value=obj.relaxStrength*100
            spacingSpin.enabled=obj.relaxEnabled;iterationsSpin.enabled=obj.relaxEnabled;strengthSpin.enabled=obj.relaxEnabled
            ready=true
        )
        on collisionCheck changed v do if ready do (obj.collisionEnabled=v;syncControls();redrawViews())
        on radiusSpin changed v do if ready do (obj.collisionRadius=v;redrawViews())
        on relaxCheck changed v do if ready do (obj.relaxEnabled=v;syncControls();redrawViews())
        on spacingSpin changed v do if ready do (obj.relaxSpacing=v;redrawViews())
        on iterationsSpin changed v do if ready do (obj.relaxIterations=v;redrawViews())
        on strengthSpin changed v do if ready do (obj.relaxStrength=v/100.0;redrawViews())
        on spacingUI_5 open do syncControls()
        on spacingUI_5 close do ready=false
        on spacingUI_5 rolledUp state do (parentView.layoutPanels();for c in spacingUI_5.controls do c.visible=false;for c in spacingUI_5.controls do c.visible=true)
    )
    spacingUI_5.obj=target;spacingUI_5.parentView=view;spacingUI_5
)

global CyrusMakeLayer_5
fn CyrusMakeLayer_5 target view index = (
    CyrusUIBuildView=view
    rollout layerPanel_5 "Layer" width:(CyrusUISize 162 0) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,layerIndex=CyrusUIBuildIndex,children=#()
        subrollout sections "" pos:[(CyrusUISize 8 0),2] width:(CyrusUISize 158 0) height:180
        fn fitHeight = (
            local h=0
            local dpi=parentView.dpiScale
            local header=floor(23.333*dpi+0.5)
            for r in children do h+=(if r.open then r.height+header else header)
            sections.pos=[2,0];sections.height=h;layerPanel_5.height=h
        )
        fn ensureContents = (
            if children.count==0 do (
            children=#(CyrusMake_sourceUI_5 obj parentView,CyrusMake_distributionUI_5 obj parentView,CyrusMake_spacingUI_5 obj parentView,CyrusMake_areaUI_5 obj parentView,CyrusMake_diversityUI_5 obj parentView,CyrusMake_randomUI_5 obj parentView)
            for r in children do CyrusMount sections r true
            fitHeight()
            )
        )
        on layerPanel_5 open do (children=#();layerPanel_5.height=24)
        on layerPanel_5 close do (children=#())
        on layerPanel_5 rolledUp state do (if not state and not parentView.building do ensureContents();parentView.layoutPanels())
    )
    layerPanel_5.obj=target;layerPanel_5.parentView=view;layerPanel_5.layerIndex=index;layerPanel_5
)






global CyrusMake_spacingUI_6
fn CyrusMake_spacingUI_6 target view = (
    CyrusUIBuildView=view
    rollout spacingUI_6 "Collision / Relax" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,ready=false
        checkbox collisionCheck "Enable collision" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner radiusSpin "Radius: " pos:[(CyrusUISize 8 1),34] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.1]
        label radiusHint "Min gap = 2 x radius" pos:[(CyrusUISize 8 1),62] width:(CyrusUISize 146 1)
        checkbox relaxCheck "Enable relax" pos:[(CyrusUISize 8 1),94] width:(CyrusUISize 146 1)
        spinner spacingSpin "Spacing: " pos:[(CyrusUISize 8 1),120] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.2]
        spinner iterationsSpin "Iterations: " pos:[(CyrusUISize 8 1),146] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) type:#integer range:[1,100,10]
        spinner strengthSpin "Strength %: " pos:[(CyrusUISize 8 1),172] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) range:[0,100,50]
        label orderHint "Relax, then collision" pos:[(CyrusUISize 8 1),202] width:(CyrusUISize 146 1)
        label layerHint "Within this layer only" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 146 1)
        fn syncControls = (
            ready=false
            collisionCheck.checked=obj.collisionEnabled;radiusSpin.value=obj.collisionRadius;radiusSpin.enabled=obj.collisionEnabled
            relaxCheck.checked=obj.relaxEnabled;spacingSpin.value=obj.relaxSpacing;iterationsSpin.value=obj.relaxIterations;strengthSpin.value=obj.relaxStrength*100
            spacingSpin.enabled=obj.relaxEnabled;iterationsSpin.enabled=obj.relaxEnabled;strengthSpin.enabled=obj.relaxEnabled
            ready=true
        )
        on collisionCheck changed v do if ready do (obj.collisionEnabled=v;syncControls();redrawViews())
        on radiusSpin changed v do if ready do (obj.collisionRadius=v;redrawViews())
        on relaxCheck changed v do if ready do (obj.relaxEnabled=v;syncControls();redrawViews())
        on spacingSpin changed v do if ready do (obj.relaxSpacing=v;redrawViews())
        on iterationsSpin changed v do if ready do (obj.relaxIterations=v;redrawViews())
        on strengthSpin changed v do if ready do (obj.relaxStrength=v/100.0;redrawViews())
        on spacingUI_6 open do syncControls()
        on spacingUI_6 close do ready=false
        on spacingUI_6 rolledUp state do (parentView.layoutPanels();for c in spacingUI_6.controls do c.visible=false;for c in spacingUI_6.controls do c.visible=true)
    )
    spacingUI_6.obj=target;spacingUI_6.parentView=view;spacingUI_6
)

global CyrusMakeLayer_6
fn CyrusMakeLayer_6 target view index = (
    CyrusUIBuildView=view
    rollout layerPanel_6 "Layer" width:(CyrusUISize 162 0) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,layerIndex=CyrusUIBuildIndex,children=#()
        subrollout sections "" pos:[(CyrusUISize 8 0),2] width:(CyrusUISize 158 0) height:180
        fn fitHeight = (
            local h=0
            local dpi=parentView.dpiScale
            local header=floor(23.333*dpi+0.5)
            for r in children do h+=(if r.open then r.height+header else header)
            sections.pos=[2,0];sections.height=h;layerPanel_6.height=h
        )
        fn ensureContents = (
            if children.count==0 do (
            children=#(CyrusMake_sourceUI_6 obj parentView,CyrusMake_distributionUI_6 obj parentView,CyrusMake_spacingUI_6 obj parentView,CyrusMake_areaUI_6 obj parentView,CyrusMake_diversityUI_6 obj parentView,CyrusMake_randomUI_6 obj parentView)
            for r in children do CyrusMount sections r true
            fitHeight()
            )
        )
        on layerPanel_6 open do (children=#();layerPanel_6.height=24)
        on layerPanel_6 close do (children=#())
        on layerPanel_6 rolledUp state do (if not state and not parentView.building do ensureContents();parentView.layoutPanels())
    )
    layerPanel_6.obj=target;layerPanel_6.parentView=view;layerPanel_6.layerIndex=index;layerPanel_6
)






global CyrusMake_spacingUI_7
fn CyrusMake_spacingUI_7 target view = (
    CyrusUIBuildView=view
    rollout spacingUI_7 "Collision / Relax" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,ready=false
        checkbox collisionCheck "Enable collision" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner radiusSpin "Radius: " pos:[(CyrusUISize 8 1),34] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.1]
        label radiusHint "Min gap = 2 x radius" pos:[(CyrusUISize 8 1),62] width:(CyrusUISize 146 1)
        checkbox relaxCheck "Enable relax" pos:[(CyrusUISize 8 1),94] width:(CyrusUISize 146 1)
        spinner spacingSpin "Spacing: " pos:[(CyrusUISize 8 1),120] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.2]
        spinner iterationsSpin "Iterations: " pos:[(CyrusUISize 8 1),146] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) type:#integer range:[1,100,10]
        spinner strengthSpin "Strength %: " pos:[(CyrusUISize 8 1),172] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) range:[0,100,50]
        label orderHint "Relax, then collision" pos:[(CyrusUISize 8 1),202] width:(CyrusUISize 146 1)
        label layerHint "Within this layer only" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 146 1)
        fn syncControls = (
            ready=false
            collisionCheck.checked=obj.collisionEnabled;radiusSpin.value=obj.collisionRadius;radiusSpin.enabled=obj.collisionEnabled
            relaxCheck.checked=obj.relaxEnabled;spacingSpin.value=obj.relaxSpacing;iterationsSpin.value=obj.relaxIterations;strengthSpin.value=obj.relaxStrength*100
            spacingSpin.enabled=obj.relaxEnabled;iterationsSpin.enabled=obj.relaxEnabled;strengthSpin.enabled=obj.relaxEnabled
            ready=true
        )
        on collisionCheck changed v do if ready do (obj.collisionEnabled=v;syncControls();redrawViews())
        on radiusSpin changed v do if ready do (obj.collisionRadius=v;redrawViews())
        on relaxCheck changed v do if ready do (obj.relaxEnabled=v;syncControls();redrawViews())
        on spacingSpin changed v do if ready do (obj.relaxSpacing=v;redrawViews())
        on iterationsSpin changed v do if ready do (obj.relaxIterations=v;redrawViews())
        on strengthSpin changed v do if ready do (obj.relaxStrength=v/100.0;redrawViews())
        on spacingUI_7 open do syncControls()
        on spacingUI_7 close do ready=false
        on spacingUI_7 rolledUp state do (parentView.layoutPanels();for c in spacingUI_7.controls do c.visible=false;for c in spacingUI_7.controls do c.visible=true)
    )
    spacingUI_7.obj=target;spacingUI_7.parentView=view;spacingUI_7
)

global CyrusMakeLayer_7
fn CyrusMakeLayer_7 target view index = (
    CyrusUIBuildView=view
    rollout layerPanel_7 "Layer" width:(CyrusUISize 162 0) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,layerIndex=CyrusUIBuildIndex,children=#()
        subrollout sections "" pos:[(CyrusUISize 8 0),2] width:(CyrusUISize 158 0) height:180
        fn fitHeight = (
            local h=0
            local dpi=parentView.dpiScale
            local header=floor(23.333*dpi+0.5)
            for r in children do h+=(if r.open then r.height+header else header)
            sections.pos=[2,0];sections.height=h;layerPanel_7.height=h
        )
        fn ensureContents = (
            if children.count==0 do (
            children=#(CyrusMake_sourceUI_7 obj parentView,CyrusMake_distributionUI_7 obj parentView,CyrusMake_spacingUI_7 obj parentView,CyrusMake_areaUI_7 obj parentView,CyrusMake_diversityUI_7 obj parentView,CyrusMake_randomUI_7 obj parentView)
            for r in children do CyrusMount sections r true
            fitHeight()
            )
        )
        on layerPanel_7 open do (children=#();layerPanel_7.height=24)
        on layerPanel_7 close do (children=#())
        on layerPanel_7 rolledUp state do (if not state and not parentView.building do ensureContents();parentView.layoutPanels())
    )
    layerPanel_7.obj=target;layerPanel_7.parentView=view;layerPanel_7.layerIndex=index;layerPanel_7
)






global CyrusMake_spacingUI_8
fn CyrusMake_spacingUI_8 target view = (
    CyrusUIBuildView=view
    rollout spacingUI_8 "Collision / Relax" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,ready=false
        checkbox collisionCheck "Enable collision" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner radiusSpin "Radius: " pos:[(CyrusUISize 8 1),34] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.1]
        label radiusHint "Min gap = 2 x radius" pos:[(CyrusUISize 8 1),62] width:(CyrusUISize 146 1)
        checkbox relaxCheck "Enable relax" pos:[(CyrusUISize 8 1),94] width:(CyrusUISize 146 1)
        spinner spacingSpin "Spacing: " pos:[(CyrusUISize 8 1),120] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.2]
        spinner iterationsSpin "Iterations: " pos:[(CyrusUISize 8 1),146] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) type:#integer range:[1,100,10]
        spinner strengthSpin "Strength %: " pos:[(CyrusUISize 8 1),172] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) range:[0,100,50]
        label orderHint "Relax, then collision" pos:[(CyrusUISize 8 1),202] width:(CyrusUISize 146 1)
        label layerHint "Within this layer only" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 146 1)
        fn syncControls = (
            ready=false
            collisionCheck.checked=obj.collisionEnabled;radiusSpin.value=obj.collisionRadius;radiusSpin.enabled=obj.collisionEnabled
            relaxCheck.checked=obj.relaxEnabled;spacingSpin.value=obj.relaxSpacing;iterationsSpin.value=obj.relaxIterations;strengthSpin.value=obj.relaxStrength*100
            spacingSpin.enabled=obj.relaxEnabled;iterationsSpin.enabled=obj.relaxEnabled;strengthSpin.enabled=obj.relaxEnabled
            ready=true
        )
        on collisionCheck changed v do if ready do (obj.collisionEnabled=v;syncControls();redrawViews())
        on radiusSpin changed v do if ready do (obj.collisionRadius=v;redrawViews())
        on relaxCheck changed v do if ready do (obj.relaxEnabled=v;syncControls();redrawViews())
        on spacingSpin changed v do if ready do (obj.relaxSpacing=v;redrawViews())
        on iterationsSpin changed v do if ready do (obj.relaxIterations=v;redrawViews())
        on strengthSpin changed v do if ready do (obj.relaxStrength=v/100.0;redrawViews())
        on spacingUI_8 open do syncControls()
        on spacingUI_8 close do ready=false
        on spacingUI_8 rolledUp state do (parentView.layoutPanels();for c in spacingUI_8.controls do c.visible=false;for c in spacingUI_8.controls do c.visible=true)
    )
    spacingUI_8.obj=target;spacingUI_8.parentView=view;spacingUI_8
)

global CyrusMakeLayer_8
fn CyrusMakeLayer_8 target view index = (
    CyrusUIBuildView=view
    rollout layerPanel_8 "Layer" width:(CyrusUISize 162 0) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,layerIndex=CyrusUIBuildIndex,children=#()
        subrollout sections "" pos:[(CyrusUISize 8 0),2] width:(CyrusUISize 158 0) height:180
        fn fitHeight = (
            local h=0
            local dpi=parentView.dpiScale
            local header=floor(23.333*dpi+0.5)
            for r in children do h+=(if r.open then r.height+header else header)
            sections.pos=[2,0];sections.height=h;layerPanel_8.height=h
        )
        fn ensureContents = (
            if children.count==0 do (
            children=#(CyrusMake_sourceUI_8 obj parentView,CyrusMake_distributionUI_8 obj parentView,CyrusMake_spacingUI_8 obj parentView,CyrusMake_areaUI_8 obj parentView,CyrusMake_diversityUI_8 obj parentView,CyrusMake_randomUI_8 obj parentView)
            for r in children do CyrusMount sections r true
            fitHeight()
            )
        )
        on layerPanel_8 open do (children=#();layerPanel_8.height=24)
        on layerPanel_8 close do (children=#())
        on layerPanel_8 rolledUp state do (if not state and not parentView.building do ensureContents();parentView.layoutPanels())
    )
    layerPanel_8.obj=target;layerPanel_8.parentView=view;layerPanel_8.layerIndex=index;layerPanel_8
)






global CyrusMake_spacingUI_9
fn CyrusMake_spacingUI_9 target view = (
    CyrusUIBuildView=view
    rollout spacingUI_9 "Collision / Relax" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,ready=false
        checkbox collisionCheck "Enable collision" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner radiusSpin "Radius: " pos:[(CyrusUISize 8 1),34] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.1]
        label radiusHint "Min gap = 2 x radius" pos:[(CyrusUISize 8 1),62] width:(CyrusUISize 146 1)
        checkbox relaxCheck "Enable relax" pos:[(CyrusUISize 8 1),94] width:(CyrusUISize 146 1)
        spinner spacingSpin "Spacing: " pos:[(CyrusUISize 8 1),120] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.2]
        spinner iterationsSpin "Iterations: " pos:[(CyrusUISize 8 1),146] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) type:#integer range:[1,100,10]
        spinner strengthSpin "Strength %: " pos:[(CyrusUISize 8 1),172] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) range:[0,100,50]
        label orderHint "Relax, then collision" pos:[(CyrusUISize 8 1),202] width:(CyrusUISize 146 1)
        label layerHint "Within this layer only" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 146 1)
        fn syncControls = (
            ready=false
            collisionCheck.checked=obj.collisionEnabled;radiusSpin.value=obj.collisionRadius;radiusSpin.enabled=obj.collisionEnabled
            relaxCheck.checked=obj.relaxEnabled;spacingSpin.value=obj.relaxSpacing;iterationsSpin.value=obj.relaxIterations;strengthSpin.value=obj.relaxStrength*100
            spacingSpin.enabled=obj.relaxEnabled;iterationsSpin.enabled=obj.relaxEnabled;strengthSpin.enabled=obj.relaxEnabled
            ready=true
        )
        on collisionCheck changed v do if ready do (obj.collisionEnabled=v;syncControls();redrawViews())
        on radiusSpin changed v do if ready do (obj.collisionRadius=v;redrawViews())
        on relaxCheck changed v do if ready do (obj.relaxEnabled=v;syncControls();redrawViews())
        on spacingSpin changed v do if ready do (obj.relaxSpacing=v;redrawViews())
        on iterationsSpin changed v do if ready do (obj.relaxIterations=v;redrawViews())
        on strengthSpin changed v do if ready do (obj.relaxStrength=v/100.0;redrawViews())
        on spacingUI_9 open do syncControls()
        on spacingUI_9 close do ready=false
        on spacingUI_9 rolledUp state do (parentView.layoutPanels();for c in spacingUI_9.controls do c.visible=false;for c in spacingUI_9.controls do c.visible=true)
    )
    spacingUI_9.obj=target;spacingUI_9.parentView=view;spacingUI_9
)

global CyrusMakeLayer_9
fn CyrusMakeLayer_9 target view index = (
    CyrusUIBuildView=view
    rollout layerPanel_9 "Layer" width:(CyrusUISize 162 0) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,layerIndex=CyrusUIBuildIndex,children=#()
        subrollout sections "" pos:[(CyrusUISize 8 0),2] width:(CyrusUISize 158 0) height:180
        fn fitHeight = (
            local h=0
            local dpi=parentView.dpiScale
            local header=floor(23.333*dpi+0.5)
            for r in children do h+=(if r.open then r.height+header else header)
            sections.pos=[2,0];sections.height=h;layerPanel_9.height=h
        )
        fn ensureContents = (
            if children.count==0 do (
            children=#(CyrusMake_sourceUI_9 obj parentView,CyrusMake_distributionUI_9 obj parentView,CyrusMake_spacingUI_9 obj parentView,CyrusMake_areaUI_9 obj parentView,CyrusMake_diversityUI_9 obj parentView,CyrusMake_randomUI_9 obj parentView)
            for r in children do CyrusMount sections r true
            fitHeight()
            )
        )
        on layerPanel_9 open do (children=#();layerPanel_9.height=24)
        on layerPanel_9 close do (children=#())
        on layerPanel_9 rolledUp state do (if not state and not parentView.building do ensureContents();parentView.layoutPanels())
    )
    layerPanel_9.obj=target;layerPanel_9.parentView=view;layerPanel_9.layerIndex=index;layerPanel_9
)






global CyrusMake_spacingUI_10
fn CyrusMake_spacingUI_10 target view = (
    CyrusUIBuildView=view
    rollout spacingUI_10 "Collision / Relax" width:(CyrusUISize 162 1) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,ready=false
        checkbox collisionCheck "Enable collision" pos:[(CyrusUISize 8 1),8] width:(CyrusUISize 146 1)
        spinner radiusSpin "Radius: " pos:[(CyrusUISize 8 1),34] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.1]
        label radiusHint "Min gap = 2 x radius" pos:[(CyrusUISize 8 1),62] width:(CyrusUISize 146 1)
        checkbox relaxCheck "Enable relax" pos:[(CyrusUISize 8 1),94] width:(CyrusUISize 146 1)
        spinner spacingSpin "Spacing: " pos:[(CyrusUISize 8 1),120] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 54 1) type:#worldUnits range:[0.00001,1e9,0.2]
        spinner iterationsSpin "Iterations: " pos:[(CyrusUISize 8 1),146] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) type:#integer range:[1,100,10]
        spinner strengthSpin "Strength %: " pos:[(CyrusUISize 8 1),172] width:(CyrusUISize 146 1) fieldWidth:(CyrusUISize 45 1) range:[0,100,50]
        label orderHint "Relax, then collision" pos:[(CyrusUISize 8 1),202] width:(CyrusUISize 146 1)
        label layerHint "Within this layer only" pos:[(CyrusUISize 8 1),224] width:(CyrusUISize 146 1)
        fn syncControls = (
            ready=false
            collisionCheck.checked=obj.collisionEnabled;radiusSpin.value=obj.collisionRadius;radiusSpin.enabled=obj.collisionEnabled
            relaxCheck.checked=obj.relaxEnabled;spacingSpin.value=obj.relaxSpacing;iterationsSpin.value=obj.relaxIterations;strengthSpin.value=obj.relaxStrength*100
            spacingSpin.enabled=obj.relaxEnabled;iterationsSpin.enabled=obj.relaxEnabled;strengthSpin.enabled=obj.relaxEnabled
            ready=true
        )
        on collisionCheck changed v do if ready do (obj.collisionEnabled=v;syncControls();redrawViews())
        on radiusSpin changed v do if ready do (obj.collisionRadius=v;redrawViews())
        on relaxCheck changed v do if ready do (obj.relaxEnabled=v;syncControls();redrawViews())
        on spacingSpin changed v do if ready do (obj.relaxSpacing=v;redrawViews())
        on iterationsSpin changed v do if ready do (obj.relaxIterations=v;redrawViews())
        on strengthSpin changed v do if ready do (obj.relaxStrength=v/100.0;redrawViews())
        on spacingUI_10 open do syncControls()
        on spacingUI_10 close do ready=false
        on spacingUI_10 rolledUp state do (parentView.layoutPanels();for c in spacingUI_10.controls do c.visible=false;for c in spacingUI_10.controls do c.visible=true)
    )
    spacingUI_10.obj=target;spacingUI_10.parentView=view;spacingUI_10
)

global CyrusMakeLayer_10
fn CyrusMakeLayer_10 target view index = (
    CyrusUIBuildView=view
    rollout layerPanel_10 "Layer" width:(CyrusUISize 162 0) (
        local obj=CyrusUIBuildTarget,parentView=CyrusUIBuildView,layerIndex=CyrusUIBuildIndex,children=#()
        subrollout sections "" pos:[(CyrusUISize 8 0),2] width:(CyrusUISize 158 0) height:180
        fn fitHeight = (
            local h=0
            local dpi=parentView.dpiScale
            local header=floor(23.333*dpi+0.5)
            for r in children do h+=(if r.open then r.height+header else header)
            sections.pos=[2,0];sections.height=h;layerPanel_10.height=h
        )
        fn ensureContents = (
            if children.count==0 do (
            children=#(CyrusMake_sourceUI_10 obj parentView,CyrusMake_distributionUI_10 obj parentView,CyrusMake_spacingUI_10 obj parentView,CyrusMake_areaUI_10 obj parentView,CyrusMake_diversityUI_10 obj parentView,CyrusMake_randomUI_10 obj parentView)
            for r in children do CyrusMount sections r true
            fitHeight()
            )
        )
        on layerPanel_10 open do (children=#();layerPanel_10.height=24)
        on layerPanel_10 close do (children=#())
        on layerPanel_10 rolledUp state do (if not state and not parentView.building do ensureContents();parentView.layoutPanels())
    )
    layerPanel_10.obj=target;layerPanel_10.parentView=view;layerPanel_10.layerIndex=index;layerPanel_10
)






fn CyrusMakeLayer target view index = (
if index==1 then (CyrusMakeLayer_1 target view index) else 
if index==2 then (CyrusMakeLayer_2 target view index) else 
if index==3 then (CyrusMakeLayer_3 target view index) else 
if index==4 then (CyrusMakeLayer_4 target view index) else 
if index==5 then (CyrusMakeLayer_5 target view index) else 
if index==6 then (CyrusMakeLayer_6 target view index) else 
if index==7 then (CyrusMakeLayer_7 target view index) else 
if index==8 then (CyrusMakeLayer_8 target view index) else 
if index==9 then (CyrusMakeLayer_9 target view index) else 
if index==10 then (CyrusMakeLayer_10 target view index) else undefined
)

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

plugin simpleObject AminScatterObject
name:"Cyrus Scatter"
classID:#(0x617d43a1,0x395c2e17)
category:"Cyrus"
version:46
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
    parameters surfaceSettings (
        surfaceNodes type:#nodeTab tabSize:0 tabSizeVariable:true useNodeTmValidity:true useNodeOsValidity:true
        on surfaceNodes set v i do dirty=true
    )
    parameters updateSettings (
        updateMode type:#integer default:2
        on updateMode set v do (dirty=true;if not layerTransfer do redrawViews())
    )
    parameters populationSettings (
        populationMode type:#integer default:1
        plantsPerM2 type:#float default:100
        on populationMode set v do dirty=true
        on plantsPerM2 set v do dirty=true
    )
    fn validSurfaces = (
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
        on pointColorMode set v do if not layerTransfer do redrawViews()
        on solidPointColor set v do if not layerTransfer do redrawViews()
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
        on cyrusEnabled set v do (dirty=true;redrawViews())
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
        local key=stream as string
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
        local result=if finalPass==undefined and sourceWeights.count==0 and not collisionEnabled and not relaxEnabled and not advancedAxes and areas[1].count==0 and targets.count==1 and populationMode==1 and diversityMode<3 then (
            aminScatterTransforms targets[1] requestedCount randomSeed sourceCount scaleMinimum scaleMaximum [-tiltDegrees,-tiltDegrees,yawMinimum] [tiltDegrees,tiltDegrees,yawMaximum] [movementRange,movementRange,movementRange] alignNormal
        ) else (
            local groups=if plants.count==0 then #(0) else (for n in plants collect (colorKey (sourceColor (sourceRow n))))
            aminScatterAdvanced targets requestedCount randomSeed sourceCount [sclXMin,sclYMin,sclZMin] [sclXMax,sclYMax,sclZMax] [rotXMin,rotYMin,rotZMin] [rotXMax,rotYMax,rotZMax] [movXMin,movYMin,movZMin] [movXMax,movYMax,movZMax] alignNormal projectMove (distributionMode-1) clusterCount clusterRadius weights 128 groups (diversityMode==2) diversitySize diversitySeed (roughness/100.0) (blurryEdge/100.0) (diversityNoise/100.0) areas[1] areas[2] (populationMode==2) (lineInputs plants previewOnly:previewOnly) #(collisionEnabled,collisionRadius,relaxEnabled,relaxSpacing,relaxIterations,relaxStrength) (if sourceWeights.count==0 or plants.count==0 then #() else (for n in plants collect sourceWeight (sourceRow n))) finalPass
        )
        if finalPass!=undefined do return result
        if wholeScaleMin!=1.0 or wholeScaleMax!=1.0 do result=cyrusWholeScale result wholeScaleMin wholeScaleMax randomSeed
        result=applyAnalyzerArea result
        result=applyFalloff result
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
            if (finalCleanup or finalRelax) and result.count>0 do (
                local own=if overlapSourceRadius and plants.count>0 then placementRadii result plants else (for row in result collect 0.0)
                if not overlapSourceRadius do obstacleRadii=for row in obstacles collect 0.0
                local gap=if overlapEnabled then (if overlapSourceRadius then overlapGap else overlapRadius+overlapGap) else 0.0
                result=placements plants previewOnly:previewOnly finalPass:#(result,obstacles,own,obstacleRadii,finalCleanup,finalNeighborRadius,finalMinNeighbors,finalMinIsland,finalRelax,finalStrength,finalIterations,finalMaxMove,gap,overlapPlanar)
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
            local samples=if viewportMode!=1 then #() else if showCenters then (for i=1 to (amax 1 plants.count) collect #([0,0,0])) else (for n in plants collect (if classof n==Integer then (for p=1 to pointsPerPlant collect [0,0,0]) else aminScatterSourcePoints n pointsPerPlant randomSeed))
            local colors=if plants.count==0 then #(solidPointColor) else (for n in plants collect (sourceColor (sourceRow n)))
            cachedPoints=if viewportMode==1 then aminScatterBuildPreview data samples colors (if showCenters then 500000 else previewBudget) else cyrusBuildGeometryPreview data (if plants.count==0 then #(-1) else plants) colors (if viewportMode==2 then proxyShape else 4) viewportInstances viewportFaces
            cachedPointCount=aminScatterPreviewCount cachedPoints
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
    local cachedDisabledInput=false
    fn previewCache interactionHeld:undefined = (
        local held=if interactionHeld==undefined then CyrusInteractionHeld() else interactionHeld
        if held do (CyrusWasDragging=true;return cachedPoints)
        local inputOff=disabledAnalyzerInput()
        if inputOff!=cachedDisabledInput do (dirty=true;cachedDisabledInput=inputOff)
        if inputOff do return (aminScatterBuildPreview #() #() #() 1)
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
            obj.checkAnalyzerRevision()
            append entries #(i,obj)
        )
        if (for e in entries where layerEnabled[e[1]] and e[2].dirty collect e).count>0 do
            for e in entries where layerEnabled[e[1]] and e[2].overlapEnabled do e[2].dirty=true
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
                -- Remap surviving indices on deletion.
                for layer in layerObjects do (
                    layer.overlapBlockers=for k in layer.overlapBlockers where k!=i collect (if k>i then k-1 else k)
                    
                    layer.dirty=true
                )
                deleteItem layerObjects i;deleteItem layerNames i;deleteItem layerEnabled i
                activeLayer=amin i layerObjects.count
            )
        )
        activeLayer
    )
    fn refreshDisplay = (
        for entry in (layerEntries()) do entry[2].refreshPreview()
        redrawViews()
    )
    fn refreshAll = (
        global CyrusPFManualRevision; if CyrusPFManualRevision!=undefined do CyrusPFManualRevision+=1
        for entry in (layerEntries()) do entry[2].refreshPreview()
        redrawViews()
    )
    fn allStatus = (
        local plants=0;local points=0
        for entry in (layerEntries()) do (
            local state=entry[2].cacheSnapshot()
            plants+=state[5];points+=state[2]
        )
        (layerObjects.count as string)+" layers; "+(plants as string)+" plants; "+(points as string)+(if viewportMode==1 then " points" else " shown instances (display limits apply)")
    )
    fn clearAllBaked = (
        local owners=refs.dependentNodes this
        if owners.count==1 do for entry in (layerEntries includeDisabled:true) do entry[2].clearBaked owners[1]
        autoRender=true;showPoints=true;redrawViews()
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
    rollout mainUI "Cyrus Scatter" width:#cmdPanel (
        local controlsReady=false,building=false,controller
        local roots=#(),layerPanels=#(),dpiScale=1.0
        checkbox enableCyrus "Enable Cyrus Scatter" checked:true pos:[8,4] width:220
        on enableCyrus changed v do undo "Enable Cyrus Scatter" on cyrusEnabled=v
        subrollout panels "" pos:[0,28] width:162 height:200
        timer widthTimer interval:300 active:true
        fn fitWidth = (
            local h=mainUI.hwnd,p=windows.getParentHWND h
            if h==0 or p==0 do return false
            local b=windows.getWindowPos h,pb=windows.getWindowPos p
            local desired=amax 160 (pb.w-8),changed=abs(b.w-desired)>1
            if changed or abs(b.x-pb.x-4)>1 do windows.setWindowPos h 4 (b.y-pb.y) desired b.h true
            if panels.width!=desired do panels.width=desired
            changed
        )
        fn layoutPanels = (
            if controlsReady and not building do (
                local h=0
                dpiScale=mainUI.height as float / (amax 1 (windows.getWindowPos mainUI.hwnd).h)
                local header=floor(23.333*dpiScale+0.5)
                for r in layerPanels do r.fitHeight()
                for r in roots do h+=(if r.open then r.height+header else header)
                for r in layerPanels do h+=(if r.open then r.height+header else header)
                panels.pos=[0,28];panels.height=h;mainUI.height=h+28;fitWidth()
                -- Nested rollout resizing can leave stale child paint regions in Max.
                for panel in layerPanels where panel.open do for section in panel.children where section.open and section.title=="Collision / Relax" do (
                    for c in section.controls do c.visible=false
                    for c in section.controls do c.visible=true
                )
            )
        )
        fn refreshTitles = (
            for i=1 to layerPanels.count do layerPanels[i].title=controller.layerNames[i]
        )
        fn rebuildLayers = (
            building=true
            local states=for r in layerPanels collect #(r.obj,r.open,(for c in r.children collect c.open))
            for r in layerPanels do removeSubRollout panels r
            layerPanels=#()
            for i=1 to controller.layerObjects.count do (
                controller.syncLayerSurface controller.layerObjects[i]
                local r=CyrusMakeLayer controller.layerObjects[i] mainUI i
                append layerPanels r
                r.title=controller.layerNames[i]
                local previous=undefined
                for state in states where state[1]==controller.layerObjects[i] do previous=state
                CyrusMount panels r (if previous==undefined then true else not previous[2])
                r.title=controller.layerNames[i]
                if previous!=undefined and previous[2] do (r.ensureContents();for k=1 to (amin r.children.count previous[3].count) do r.children[k].open=previous[3][k])
            )
            building=false;layoutPanels()
        )
        fn rebuild = (
            if controlsReady do (rebuildLayers();roots[4].refresh())
        )
        fn rebuildWidth = (
            local states=for r in roots collect r.open
            building=true
            for r in roots do removeSubRollout panels r
            roots=#(CyrusMake_updateUI controller mainUI,CyrusMake_surfaceUI controller mainUI,CyrusMake_previewUI controller mainUI,CyrusMakeManager controller mainUI)
            for i=1 to roots.count do CyrusMount panels roots[i] (not states[i])
            building=false;rebuildLayers()
        )
        on widthTimer tick do if controlsReady and not building do (if fitWidth() do rebuildWidth())
        on mainUI open do (
            controller=this
            enableCyrus.checked=cyrusEnabled
            building=true
            fitWidth()
            roots=#(CyrusMake_updateUI controller mainUI,CyrusMake_surfaceUI controller mainUI,CyrusMake_previewUI controller mainUI,CyrusMakeManager controller mainUI)
            for r in roots do CyrusMount panels r true
            controlsReady=true;building=false;rebuildLayers()
        )
        on mainUI close do (controlsReady=false;roots=#();layerPanels=#())
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
        for entry in n.baseObject.layerEntries() do (
            local obj=entry[2]
            local cache=obj.previewCache interactionHeld:held
            obj.drawRadii()
            if obj.showPoints or obj.showCenters do (
                if cache!=undefined do aminScatterDrawPreview cache (obj.pointColorMode==1) obj.solidPointColor
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
        if wanted and AminScatterRenderRedrawHeld!=true do (CyrusLiveRedrawRequests+=1;redrawViews())
    )
)
fn AminScatterLiveChanged event handles = (
    if CyrusPerfTraceInput!=undefined do try(CyrusPerfTraceInput "scatter_input_received" event handles)catch()
    CyrusLiveChangeCalls+=1
    if event==#deleted do (handles=for h in handles where findItem CyrusPFDeletedHandles h==0 collect h;if handles.count==0 do return false)
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
            else (CyrusLiveRedrawRequests+=1;redrawViews())
        )
    )
)
fn AminScatterLiveTime = (
    if AminScatterRenderRedrawHeld!=true do (
        for n in objects where classof n.baseObject==AminScatterObject do (for entry in (n.baseObject.layerEntries includeDisabled:true) do entry[2].invalidateLive())
        redrawViews()
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
    redrawViews()
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
 else if CyrusWasDragging do (CyrusWasDragging=false;redrawViews())
)
CyrusReleaseTimer=dotNetObject "System.Windows.Forms.Timer"
CyrusReleaseTimer.Interval=200
dotNet.addEventHandler CyrusReleaseTimer "Tick" CyrusReleaseTick
CyrusReleaseTimer.Start()
