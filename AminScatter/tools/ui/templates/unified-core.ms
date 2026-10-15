-- Only registered Scatter nodes participate in timeline notifications. This
-- registry is rebuilt at scene boundaries, never by scanning every animation frame.
global AminScatterObject,CyrusSourceContainer,CyrusContainerRefreshLabels
global CyrusMeshMaskPreviewTarget=undefined,CyrusMeshMaskPreviewNode=undefined,CyrusMeshMaskPreviewRows=#()
fn CyrusClearMeshMaskPreview target = (
    if target==undefined or target==CyrusMeshMaskPreviewTarget do (
        CyrusMeshMaskPreviewRows=#();CyrusMeshMaskPreviewTarget=undefined;CyrusMeshMaskPreviewNode=undefined
    )
)
fn CyrusShowMeshMaskPreview target = (
    if not target.meshMaskEnabled do throw "Enable the mesh channel density mask first."
    local node=undefined
    for candidate in refs.dependentNodes target where isValidNode candidate and classof candidate.baseObject==AminScatterObject do node=candidate
    if node==undefined do throw "The mesh mask owner is no longer in this scene."
    local targets=target.validSurfaces(),rows=#()
    if targets.count==0 do throw "Add a receiving surface first."
    local perReceiver=amax 1 ((2048/targets.count) as integer),cfg=target.meshMaskPayload()
    for receiver in targets do join rows (cyrusMeshDensityPreview receiver cfg perReceiver)
    CyrusMeshMaskPreviewTarget=target;CyrusMeshMaskPreviewNode=node;CyrusMeshMaskPreviewRows=rows
    redrawViews();rows.count
)
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
global CyrusReleaseTimer,CyrusPFTimer,CyrusPFBusy,CyrusPointPending,AminScatterObject
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
    local obj=try(modPanel.getCurrentObject())catch(undefined)
    if obj!=undefined do (
        local panel=if classof obj==CyrusSourceContainer then obj.containerUI else if classof obj==AminScatterObject then obj.mainUI else undefined
        if panel!=undefined and panel.controlsReady do panel.statusTimer.active=true
    )
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
global CyrusLayerStatusData,CyrusUICount,CyrusUILayerState,CyrusUIPreviewLabel,CyrusUIResultText
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
    if stats.errorText!="" do return #("Error",if stats.hasResult then "Update / preview failed; previous result retained" else "Update / preview failed; no calculated result")
    if not previewVisible do return #("Hidden",if stats.needsUpdate then "Preview hidden; needs Update" else "Preview hidden")
    if not stats.hasResult do return #("--","No calculated result")
    if stats.needsUpdate do return #("Pending","Marked for Update")
    if stats.mode>1 and stats.previewCount<stats.placements do return #("Limited","Prepared preview is sampled")
    if stats.placements==0 do return #("Empty","Last calculation accepted no placements")
    #("OK","Last completed result")
)
fn CyrusUIPreviewLabel mode = (
    case mode of (
        1:"Prepared cloud points"
        2:"Prepared proxy instances"
        3:"Prepared mesh instances"
        4:"Prepared centres"
        default:"Prepared preview samples"
    )
)
-- Passive presentation: only read already published counts and cached status.
-- In particular, procReadSnapshot/validSources can realize or scan input state
-- and are intentionally not used by this statistics/help path.
fn CyrusUIResultText root owner = (
    if root==undefined or owner==undefined do return "Select a layer to inspect its last calculated result."
    local index=findItem root.layerObjects owner
    if index==0 do return "Select a layer to inspect its last calculated result."
    local state=owner.uiLayerStats(),enabled=root.enabledLayer index,visible=root.visibleLayer index
    local status=CyrusUILayerState state enabled root.cyrusEnabled visible
    local text="Layer: "+(root.layerCaption owner)+"\n"+status[2]
    if not root.cyrusEnabled then text+="\nEnable Cyrus Scatter to calculate."
    else if not enabled then text+="\nEnable this layer to include it in calculation."
    else if state.inputOff then text+="\nEnable the linked Analyzer input before updating."
    else if state.errorText!="" then text+="\nResolve the error below, then retry Update scatter."
    else if not state.hasResult then text+="\nChoose surfaces and models or Points, then Update scatter."
    else if state.needsUpdate then text+=(if root.updateMode==1 then "\nManual: press Update scatter to apply pending settings." else "\nLive: a relevant update is pending.")
    else if state.placements==0 then text+="\nCheck Amount, coverage, source weights and spacing."
    if not visible do text+="\nEnable Visible in Layers to show this layer."
    if state.hasResult do (
        local stats=owner.groupStats(),cache=owner.cacheSnapshot(),detail=owner.procStatistics()
        text+="\n\nLast calculation\nRequested: "+(CyrusUICount cache[8])
        text+="\nConsidered for spacing: "+(CyrusUICount stats[1])
        text+="\nAccepted placements: "+(CyrusUICount state.placements)+" | Removed: "+(CyrusUICount stats[2])
        if stats[3]>0 do text+="\nProtected edit conflicts: "+(CyrusUICount stats[3])
        if detail[1].count==12 do (
            text+="\nSpacing rejected, between layers: "+(CyrusUICount detail[1][5])+" | Within layer: "+(CyrusUICount (detail[1][6]+detail[1][7]))
            text+="\nCleanup removed: "+(CyrusUICount detail[1][8])+" | Target shortfall: "+(CyrusUICount detail[1][11])
            text+="\nAttempts: "+(CyrusUICount detail[1][10])+" | Rounds: "+(detail[2][1] as string)
        )
        text+="\n\n"+(CyrusUIPreviewLabel state.mode)+": "+(CyrusUICount state.previewCount)
        text+="\nLast preview preparation: "+(state.buildMs as string)+" ms\nDraw limits can display fewer without changing accepted placements."
        if state.densityCapped do text+="\nDensity limited to 1,000,000 candidates."
    )
    if state.errorText!="" do text+="\n\n"+state.errorText
    text
)

global CyrusPointOwner,CyrusPointSync,CyrusViewportRedraw,CyrusPointClear,CyrusPointAfterSave
global CyrusPointOwners,CyrusPointEnabled=true,CyrusMeshEnabled=true,CyrusPointAvailable=false,CyrusPointBusy=false,CyrusPointPending=false,CyrusPointSuspended=false,CyrusPointLastError="",CyrusPointDetailStatus="",CyrusPointDeletedHandles=#()
global CyrusViewportRecords=#(),CyrusViewportAnalyzers=#(),CyrusViewportRecordsDirty=true,CyrusPointPresentationPending=false
global CyrusPointSceneOwners=#()
try(CyrusPointClear())catch()
CyrusPointOwners=#()
global cyrusFilterSourceRows,cyrusApplySourceTransforms
global CyrusInteractionHeld,CyrusWasDragging=false,CyrusReleaseTimer,CyrusReleaseTick
 global CyrusPreviewActivity,CyrusPreviewIdleTimer,CyrusPreviewView=undefined,CyrusPreviewProjection=undefined,CyrusPreviewViewID=undefined
fn CyrusInteractionHeld = (try((dotNetClass "System.Windows.Forms.Control").MouseButtons != (dotNetClass "System.Windows.Forms.MouseButtons").None)catch(false))
global CyrusFallPack,CyrusFallUnpack,CyrusOpenFalloffGraph
fn CyrusFallPack values = (local s=stringStream "";for i=1 to values.count do format "% %" values[i] (if i<values.count then "," else "") to:s;s as string)
fn CyrusFallUnpack data = (for v in filterString data "," collect (v as float))
global CyrusFalloffGraph,CyrusFallGraphTarget,CyrusFallGraphArea,CyrusFallGraphDensity,CyrusFallGraphBandID=0,CyrusFallGraphMeshMask=false
global CyrusFallGraphOwnerRoot,CyrusFallGraphOwnerNode
fn CyrusOpenFalloffGraph target areaNode density bandID:0 meshMask:false = (
    local bandRoot=undefined,bandNode=undefined
    if bandID>0 and findItem target.strokeIDs bandID==0 do throw "The selected Band no longer exists."
    for node in refs.dependentNodes target where isValidNode node and classof node.baseObject==AminScatterObject do (
        local candidate=node.baseObject,parent=try(candidate.logicalParent target)catch(undefined)
        if parent!=undefined and findItem candidate.layerObjects parent>0 do (
            if bandNode!=undefined and bandNode!=node do throw "The curve owner must belong to one Scatter controller."
            bandRoot=candidate;bandNode=node
        )
    )
    if bandRoot==undefined do throw "The curve controller is no longer in this scene."
    if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()
    rollout editor "Area Falloff - Edit Graph" width:760 height:505 (
        local obj,area,isDensity=false,isMeshMask=false,loading=true,ownerRoot=undefined,ownerNode=undefined,ownerLayerID="",ownerBandID=0,ownerPathID=0,invalidated=false,curveTimer=undefined,pendingCurve=false,lastGraphTrace="",lastPresetTrace="",presetStoredValues=undefined,presetStoredGraph=""
        curveControl graph "" pos:[8,8] width:744 height:396 numCurves:1 x_range:[0,1] y_range:[0,100] commandMode:#move_xy asPopup:false
        button presetsButton "Presets..." pos:[12,464] width:120
        button applyButton "Apply" pos:[538,424] width:100
        button doneButton "Close" pos:[648,424] width:100
        label help "X: distance along ramp (0 to 1). Y: percent. Drag points / edit Bezier handles." pos:[12,424] width:510 height:36
        fn bandTargetRow = (
            if ownerBandID==0 do return 0
            if invalidated do return 0
            local row=0,valid=false
            try (
                row=findItem obj.strokeIDs ownerBandID
                valid=isValidNode ownerNode and ownerNode.baseObject==ownerRoot and findItem ownerRoot.layerObjects obj>0 and obj.layerID==ownerLayerID and row>0
                if valid do valid=obj.strokePathIDs[row]==ownerPathID
            )catch(valid=false)
            if not valid do (invalidated=true;applyButton.enabled=false;help.text="This Band target is no longer available. Close and reopen its graph.")
            if valid then row else 0
        )
        fn bandSamples = (if isDensity then obj.strokeCurveSamples else obj.strokeScaleSamples)
        fn bandGraphs = (if isDensity then obj.strokeCurveGraphs else obj.strokeScaleGraphs)
        fn curveTrace = (
            local curve=graph.curves[1],packed=#()
            if curve.numPoints<2 do return undefined
            if curve.numPoints>257 do (help.text="Curves support at most 257 control points. Remove excess points before Apply.";return undefined)
            for i=1 to curve.numPoints do (
                local p=curve.points[i]
                join packed #(p.value.x,p.value.y,p.inTangent.x,p.inTangent.y,p.outTangent.x,p.outTangent.y,(if p.bezier then 1 else 0),(if p.corner then 1 else 0))
            )
            local values=for i=0 to 256 collect (
                local v=amax 0.0 ((getValue curve 0 (i/256.0))/100.0)
                if ownerBandID>0 and not isDensity and (v>100 or v!=v) do throw "Band scale curve exceeds 10000% or is non-finite."
                if isDensity or obj.isPaintArea then amin 1.0 v else v
            )
            #(values,CyrusFallPack values,CyrusFallPack packed)
        )
        fn storeCurve = (
            pendingCurve=false
            if curveTimer!=undefined do curveTimer.Stop()
            if invalidated do return false
            if not loading do (
                local bandRow=bandTargetRow()
                if ownerBandID>0 and bandRow==0 do return false
                local trace=curveTrace()
                if trace==undefined do return false
                local values=trace[1],packedValues=trace[2],packedGraph=trace[3],identity=trace[3]
                if isMeshMask do (
                    if not isValidNode ownerNode or ownerNode.baseObject!=ownerRoot or findItem ownerRoot.layerObjects obj==0 or obj.layerID!=ownerLayerID do (
                        invalidated=true;applyButton.enabled=false;help.text="This mesh mask owner was removed. Close and reopen its graph.";return false
                    )
                    if identity==lastGraphTrace do return true
                    local changed=(CyrusFallPack (obj.meshMaskCurve()))!=packedValues
                    undo "Cyrus mesh density curve" on (
                        if changed do obj.meshMaskSamples=values
                        obj.meshMaskGraph=packedGraph
                    )
                    lastGraphTrace=identity
                    if changed do CyrusViewportRedraw()
                    return true
                )
                -- Compare the canonical saved representation, not rounded
                -- control geometry, not the SDK's deferred sample cache.
                -- A close after external Undo must not reapply an unchanged UI.
                local cfg=if ownerBandID>0 then undefined else obj.getFallConfig area
                local curveIndex=if isDensity then 8 else 5
                local oldValues=if ownerBandID>0 then CyrusFallUnpack ((bandSamples())[bandRow]) else cfg[curveIndex]
                local oldGraph=if ownerBandID>0 then (bandGraphs())[bandRow] else obj.getFallGraph area isDensity
                if presetStoredValues!=undefined and ((CyrusFallPack oldValues)!=presetStoredValues or oldGraph!=presetStoredGraph) do (
                    invalidated=true;applyButton.enabled=false;presetsButton.enabled=false
                    help.text="This curve changed outside the graph. Close and reopen it to continue."
                    return false
                )
                if identity==lastPresetTrace do return true
                lastPresetTrace="";presetStoredValues=undefined
                if ownerBandID>0 and identity==lastGraphTrace do return true
                local samplesChanged=oldValues.count!=values.count
                if not samplesChanged do for i=1 to values.count where oldValues[i]!=values[i] do samplesChanged=true
                if ownerBandID==0 do cfg[curveIndex]=values
                if ownerBandID>0 then (
                    local samples=bandSamples(),graphs=bandGraphs()
                    if samples[bandRow]!=packedValues or graphs[bandRow]!=packedGraph do undo "Cyrus Band curve" on (
                        if isDensity then (obj.strokeCurveSamples[bandRow]=packedValues;obj.strokeCurveGraphs[bandRow]=packedGraph)
                        else (obj.strokeScaleSamples[bandRow]=packedValues;obj.strokeScaleGraphs[bandRow]=packedGraph)
                    )
                    lastGraphTrace=identity
                ) else if obj.isPaintArea then (
                    -- Max can update its sampled values after the point-change event.
                    -- Apply/Close must also compare samples, even for identical handles.
                    if samplesChanged or (obj.getFallGraph area isDensity)!=packedGraph do undo "Cyrus vector curve" on (
                        obj.setFallConfig area cfg
                        obj.setFallGraph area isDensity packedGraph
                    )
                ) else (
                    obj.setFallConfig area cfg
                    obj.setFallGraph area isDensity packedGraph
                )
                CyrusViewportRedraw()
            )
            true
        )
        fn presetTargetValid = (
            if invalidated do return false
            local valid=isValidNode ownerNode and ownerNode.baseObject==ownerRoot and obj.layerID==ownerLayerID
            if valid do (
                local parent=try(ownerRoot.logicalParent obj)catch(undefined)
                valid=parent!=undefined and findItem ownerRoot.layerObjects parent>0
                if valid and obj.isPaintArea do valid=findItem parent.paintAreas obj>0
                if valid and area!=undefined do valid=isValidNode area and findItem obj.areaNodes area>0
                if valid and ownerBandID>0 do valid=bandTargetRow()>0
            )
            valid
        )
        fn presetEnabled = (
            if not presetTargetValid() do return false
            if ownerBandID>0 then (local row=bandTargetRow();if isDensity then obj.strokeCurveEnabled[row] else obj.strokeScaleModes[row]==3)
            else (obj.getFallConfig area)[if isDensity then 6 else 3]
        )
        fn presetValues = (
            if not presetTargetValid() do throw "The curve target was removed or replaced."
            local trace=curveTrace()
            if trace==undefined do throw "The curve has no valid editable representation."
            #(trace[1],CyrusFallUnpack trace[3],not isDensity and not obj.isPaintArea)
        )
        fn presetLoadGraph values = (
            local c=graph.curves[1],samples=values[1],packed=values[2]
            graph.y_range=[0,(if isDensity or obj.isPaintArea then 100 else amax 200.0 ((amax samples)*100))]
            c.numPoints=if packed.count>0 then packed.count/8 else samples.count
            for i=1 to c.numPoints do (
                local point=c.points[i],j=(i-1)*8
                if packed.count>0 then (
                    point.value=[packed[j+1],packed[j+2]];point.inTangent=[packed[j+3],packed[j+4]];point.outTangent=[packed[j+5],packed[j+6]]
                    point.bezier=packed[j+7]>0;point.corner=packed[j+8]>0
                ) else (point.value=[(i-1.0)/(samples.count-1),samples[i]*100];point.bezier=false;point.corner=true)
                point.lock_x=(i==1 or i==c.numPoints);c.points[i]=point
            )
            zoom graph #all
        )
        fn presetRestore state = (
            loading=true
            undo off (presetLoadGraph state[1])
            lastGraphTrace=state[2];lastPresetTrace=state[3];presetStoredValues=state[4];presetStoredGraph=state[5]
            loading=false;true
        )
        fn presetPrepare values = (
            if not presetTargetValid() do throw "The curve target was removed or replaced."
            if values[3] and (isDensity or obj.isPaintArea) do throw "This target requires a unit-range curve."
            local state=#(presetValues(),lastGraphTrace,lastPresetTrace,presetStoredValues,presetStoredGraph)
            if curveTimer!=undefined do curveTimer.Stop()
            pendingCurve=false;loading=true
            try (
                undo off (presetLoadGraph values)
                local trace=curveTrace(),samples=values[1]
                if trace==undefined do throw "Cannot reconstruct the preset graph."
                for i=1 to trace[1].count do (
                    local position=(i-1.0)*(samples.count-1)/256.0,lo=(floor position) as integer,hi=amin (samples.count-1) (lo+1)
                    local expected=samples[lo+1]+(samples[hi+1]-samples[lo+1])*(position-lo)
                    if abs (trace[1][i]-expected)>0.0001*(amax 1.0 (abs expected)) do throw "Preset handles do not match its sampled curve."
                )
                loading=false
            )catch(presetRestore state;throw())
            state
        )
        fn presetApply values = (
            lastGraphTrace="";lastPresetTrace="";presetStoredValues=undefined
            if not storeCurve() do throw "The curve could not be stored."
            local trace=curveTrace(),row=bandTargetRow()
            lastPresetTrace=trace[3]
            presetStoredValues=if ownerBandID>0 then (bandSamples())[row] else CyrusFallPack ((obj.getFallConfig area)[if isDensity then 8 else 5])
            presetStoredGraph=if ownerBandID>0 then (bandGraphs())[row] else obj.getFallGraph area isDensity
            true
        )
        on presetsButton pressed do try(CyrusOpenPresets ownerRoot obj (if isDensity then "density_curve" else "scale_curve") editor:editor)catch(messageBox (getCurrentException()) title:"Cyrus presets")
        on editor open do (
            obj=CyrusFallGraphTarget;area=CyrusFallGraphArea;isDensity=CyrusFallGraphDensity;ownerBandID=CyrusFallGraphBandID;isMeshMask=CyrusFallGraphMeshMask
            ownerRoot=CyrusFallGraphOwnerRoot;ownerNode=CyrusFallGraphOwnerNode;ownerLayerID=obj.layerID
            if ownerBandID>0 do (
                local row=findItem obj.strokeIDs ownerBandID
                if row==0 do throw "The selected Band no longer exists."
                ownerPathID=obj.strokePathIDs[row]
            )
            editor.title=(if isDensity then "Area Density Falloff" else "Area Scale Falloff")+" - "+(if area==undefined then (if obj.isPaintArea then obj.paintSetName+" / Vector Border" else "Analyzer Boundary") else area.name)
            local row=bandTargetRow(),cfg=if ownerBandID>0 or isMeshMask then undefined else obj.getFallConfig area
            if ownerBandID>0 do (editor.title=(if isDensity then "Band Density - " else "Band Scale - ")+obj.bandName row;help.text="Band "+(ownerBandID as string)+". X: normalized Start to End. Y: "+(if isDensity then "density 0-100%." else "size percent; 100% = unchanged.")+" Drag applies on release.")
            local packed=CyrusFallUnpack (if isMeshMask then obj.meshMaskGraph else if ownerBandID>0 then (bandGraphs())[row] else obj.getFallGraph area isDensity)
            local values=if isMeshMask then obj.meshMaskCurve() else if ownerBandID>0 then CyrusFallUnpack ((bandSamples())[row]) else cfg[if isDensity then 8 else 5]
            if isMeshMask do (
                editor.title="Mesh Channel Density - "+(ownerRoot.layerCaption obj)
                help.text="X: remapped channel value (after Invert). Y: planting eligibility 0-100%. Apply or release to update."
                presetsButton.enabled=false
            )
            local c=graph.curves[1];c.color=red
            graph.y_range=[0,(if isDensity then 100 else amax 200.0 ((amax values)*100))]
            -- Fit the full density domain before loading the authored curve.
            -- Zoom extents on a constant curve hides almost all of 0–100%.
            local densityZoom=undefined,densityScroll=undefined
            if ownerBandID>0 or isMeshMask do (
                c.numPoints=2
                local low=c.points[1],high=c.points[2]
                low.value=[0,0];high.value=[1,(if isDensity then 100 else amax 200.0 ((amax values)*100))]
                c.points[1]=low;c.points[2]=high
                zoom graph #all
                densityZoom=graph.zoomValues;densityScroll=graph.scrollValues
            )
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
            if ownerBandID>0 or isMeshMask then (graph.zoomValues=densityZoom;graph.scrollValues=densityScroll) else zoom graph #all
            if ownerBandID>0 or isMeshMask do (local trace=curveTrace();if trace!=undefined do lastGraphTrace=trace[3])
            loading=false
        )
        fn flushCurve sender args = (
            if pendingCurve and not (CyrusInteractionHeld()) do (pendingCurve=false;if curveTimer!=undefined do curveTimer.Stop();storeCurve())
        )
        fn queueCurve = (
            if loading do return false
            if ownerBandID==0 and not isMeshMask then storeCurve() else (
                pendingCurve=true
                if curveTimer==undefined do (curveTimer=dotNetObject "System.Windows.Forms.Timer";curveTimer.Interval=100;dotNet.addEventHandler curveTimer "Tick" flushCurve)
                -- Point-change callbacks can precede the control's sampled
                -- curve update. Commit in the next timer event, after release.
                curveTimer.Start()
            )
        )
        on graph ptChanged ci val do queueCurve()
        on graph tangentChanged ci val kind do queueCurve()
        on graph ptInserted ci val do queueCurve()
        on graph deleted ci val do queueCurve()
        on graph reset ci do queueCurve()
        on applyButton pressed do storeCurve()
        on doneButton pressed do (storeCurve();destroyDialog editor)
        on editor close do (if curveTimer!=undefined do (curveTimer.Stop();dotNet.removeEventHandler curveTimer "Tick" flushCurve;curveTimer.Dispose();curveTimer=undefined);pendingCurve=false;storeCurve();CyrusFalloffGraph=undefined)
    )
    CyrusFallGraphTarget=target;CyrusFallGraphArea=areaNode;CyrusFallGraphDensity=density;CyrusFallGraphBandID=bandID;CyrusFallGraphMeshMask=meshMask
    CyrusFalloffGraph=editor
    CyrusFallGraphOwnerRoot=bandRoot;CyrusFallGraphOwnerNode=bandNode
    try(createDialog editor style:#(#style_titlebar,#style_sysmenu,#style_minimizebox) pos:[200,160])catch(
        editor.loading=true
        try(destroyDialog editor)catch()
        if CyrusFalloffGraph==editor do CyrusFalloffGraph=undefined
        throw()
    )
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

global AminScatterSurfaceFilterFields=#(#slopeEnabled,#slopeMinimum,#slopeMaximum,#slopeLowerFade,#slopeUpperFade,#altitudeEnabled,#altitudeMinimum,#altitudeMaximum,#altitudeLowerFade,#altitudeUpperFade)
global AminScatterLayerFields, AminScatterLayerTabs
global AminScatterCopyLayer, AminScatterRefreshLayerPanels
global AminScatterMeshMaskFields=#(#meshMaskEnabled,#meshMaskChannel,#meshMaskComponent,#meshMaskMinimum,#meshMaskMaximum,#meshMaskInvert,#meshMaskSamples,#meshMaskGraph)
AminScatterLayerFields=#(#meshMaskEnabled,#meshMaskChannel,#meshMaskComponent,#meshMaskMinimum,#meshMaskMaximum,#meshMaskInvert,#meshMaskSamples,#meshMaskGraph,#slopeEnabled,#slopeMinimum,#slopeMaximum,#slopeLowerFade,#slopeUpperFade,#altitudeEnabled,#altitudeMinimum,#altitudeMaximum,#altitudeLowerFade,#altitudeUpperFade,#procOrder,#procSetOrder,#procSamplingSalt,#procPopulation,#procAttemptFactor,#procRounds,#procRepair,#procSelfOverride,#procSelfEnabled,#procSelfMultiplier,#procSelfGap,#procSelfPlanar,#procLayerSelfEnabled,#procLayerSelfMultiplier,#procLayerSelfGap,#procLayerSelfPlanar,#procSiblingEnabled,#procSiblingMultiplier,#procSiblingGap,#procSiblingPlanar,#procRadiusIDs,#procRadiusModes,#procRadiusValues,#procRadiusDistances,#procRadiusBinding,#procSourceNodes,#procSourceIDs,#procSourceSlots,#procReceiverNodes,#procReceiverIDs,#procReceiverID,#containerMode,#containerNodes,#logicalParentID,#paintSetName,#paintSetEnabled,#paintSetVisible,#paintView,#paintColor,#paintDocument,#paintEnabled,#paintDensity,#streetTrimStart,#streetTrimEnd,#centerStreetOffset,#areaAnalyzer,#areaUseLine,#areaLineWidth,#areaLineCaps,#areaUsePoints,#areaPointRadius,#wholeScaleMin,#wholeScaleMax,#fallScaleGraph,#fallDensityGraph,#areaFallConfigs,#areaFallDeleteWidths,#areaFallScaleWidths,#areaFallDensityWidths,#areaFallScaleGraphs,#areaFallDensityGraphs,#fallAnalyzer,#fallDelete,#fallDeleteWidth,#fallScale,#fallScaleWidth,#fallScaleCurve,#fallDensity,#fallDensityWidth,#fallDensityCurve,#edgeRotX,#edgeRotY,#edgeRotZ,#edgeKeepCorners,#edgeCornerAngle,#edgeCornerCount,#edgeFaceOut,#edgeCornerRadius,#edgeOffsetsWU,#edgeAlongWU,#edgeAcrossWU,#borderFaceOut,#streetFaceOut,#borderCornerRadius,#streetCornerRadius,#sourceForwardAxes,#finalCleanup,#finalNeighborRadius,#finalMinNeighbors,#finalMinIsland,#finalRelax,#finalStrength,#finalIterations,#finalMaxMove,#sourceRadiiWU,#sourceAutoRadius,#sourceFollowScale,#sourceShowRadius,#streetStraight,#sourcePoint,#sourceEmpty,#cleanupPlanar,#sourceZOffsetsWU,#sourceScales,#sourceWeights,#showCenters,#relaxEnabled,#relaxSpacing,#relaxIterations,#relaxStrength,#sources,#bakedNodes,#amount,#randomSeed,#scaleMinimum,#scaleMaximum,#tiltDegrees,#yawMinimum,#yawMaximum,#movementRange,#alignNormal,#showPoints,#pointsPerPlant,#updateMode,#populationMode,#plantsPerM2,#advancedAxes,#projectMove,#rotXMin,#rotXMax,#rotYMin,#rotYMax,#rotZMin,#rotZMax,#sclXMin,#sclXMax,#sclYMin,#sclYMax,#sclZMin,#sclZMax,#movXMinWU,#movXMaxWU,#movYMinWU,#movYMaxWU,#movZMinWU,#movZMaxWU,#distributionMode,#densityMap,#invertDensity,#densityUVChannel,#densityResolution,#diversityMode,#diversitySize,#diversitySeed,#roughness,#blurryEdge,#diversityNoise,#autoRender,#previewBudget,#pointColorMode,#solidPointColor,#areaNodes,#areaModes,#sourceColors,#patternLines,#patternWidths,#fieldFalloff,#fieldBoundaries,#fieldCombined,#fieldSamples,#fieldBandID)
AminScatterLayerTabs=#(#meshMaskSamples,#procRadiusIDs,#procRadiusModes,#procRadiusValues,#procRadiusDistances,#procSourceNodes,#procSourceIDs,#procSourceSlots,#procReceiverNodes,#procReceiverIDs,#containerNodes,#areaFallConfigs,#areaFallDeleteWidths,#areaFallScaleWidths,#areaFallDensityWidths,#areaFallScaleGraphs,#areaFallDensityGraphs,#fallScaleCurve,#fallDensityCurve,#edgeRotX,#edgeRotY,#edgeRotZ,#edgeOffsetsWU,#edgeAlongWU,#edgeAcrossWU,#sourceForwardAxes,#sourceRadiiWU,#sourceAutoRadius,#sourceFollowScale,#sourceShowRadius,#sourcePoint,#sourceEmpty,#sourceZOffsetsWU,#sourceScales,#sourceWeights,#sources,#bakedNodes,#areaNodes,#areaModes,#sourceColors,#patternLines,#patternWidths)
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
        origin.syncStrokes()
        for key in #(#sourceRowIDs,#visualSourceKeys,#visualSourceLabels,#visualSourceColors,#visualSourceColorSet,#strokeSides,#strokeModes,#strokeColorRows,#strokeColorKeys,#strokeSourceRows,#strokeSourceIDs,#strokeMin,#strokeMax,#patternPaths,#pathIDs,#pathJoins,#strokeIDs,#strokePathIDs,#strokeStarts,#strokeEnds,#strokeStrengths,#strokeCurveEnabled,#strokeScaleModes,#strokeScaleSamples,#strokeCurveSamples,#strokeScaleGraphs,#strokeCurveGraphs,#strokeDisplayColors) do setProperty destination key ((getProperty origin key) as array)
        destination.nextPathID=origin.nextPathID;destination.nextBandID=origin.nextBandID
        destination.bandArrangement=origin.bandArrangement
        destination.analyzerNode=origin.analyzerNode
        destination.layerIDColor=origin.layerIDColor
        destination.surfaceNodes=origin.validSurfaces();destination.surface=undefined
        destination.paintAreas=#();destination.uiAreaID=""
        for area in origin.paintAreas do (
            local duplicate=createInstance AminScatterObject
            duplicate.isPaintArea=true;duplicate.layerID=CyrusNewLayerID();duplicate.logicalParentID=destination.layerID
            duplicate.areaTarget=area.areaTarget;duplicate.paintSetName=area.paintSetName
            duplicate.paintSetEnabled=area.paintSetEnabled;duplicate.paintEnabled=true
            duplicate.fallScaleGraph=area.fallScaleGraph;duplicate.fallDensityGraph=area.fallDensityGraph
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
 local owners=if root==undefined then #() else (for n in refs.dependentNodes root where n.baseObject==root collect n)
 local mods=if owners.count==0 then #() else owners[1].modifiers
 local active=for m in mods where classof m==CyrusScatterEdit and m.enabled collect m
 local index=if layer.editLayerKey>0 then layer.editLayerKey else if root==undefined then 0 else findItem root.layerObjects layer
 local signature=layer.procBindingKey
 cyrusEditStack active rows index signature
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
    local index=findItem root.layerObjects parent
    if index==0 do return #(0,0,"Removed")
    local state=parent.uiLayerStats(),status=CyrusUILayerState state (root.enabledLayer index) root.cyrusEnabled (root.visibleLayer index)
    #((if state.hasResult then state.placements else 0),(if state.hasResult then state.previewCount else 0),status[1])
)

global CyrusBrushSessionRoot,CyrusStopBrush

plugin simpleObject AminScatterObject
name:"Cyrus Scatter"
classID:#(0x617d43a1,0x395c2e17)
category:"Cyrus"
version:58
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
    -- Deleted nodes may no longer resolve from the callback's handles. Retain
    -- only the dependency handles of the complete published result, not nodes.
    local procDependencyHandles=#()
    local timeOwnerRegistered=false
    fn ensureTimeOwner = (
        if not timeOwnerRegistered do (
            for node in refs.dependentNodes this where isValidNode node and node.baseObject==this do (
                CyrusRegisterTimeOwner node;timeOwnerRegistered=true
            )
        )
    )
    fn markInputDirty = (inputTimeValidity=undefined;dirty=true;CyrusViewportRecordsDirty=true)
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
        if not this.cyrusEnabled do return false
        if this.updateMode!=2 do (
            -- Manual placements remain frozen, but an explicitly enabled field
            -- view follows animated inputs and labels them as pending.
            local changed=false
            for i=1 to this.layerObjects.count where this.enabledLayer i do (
                local leaf=this.layerObjects[i]
                if leaf.fieldPreviewEnabled() and leaf.invalidateInputTime() do changed=true
            )
            return changed
        )
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
        procRadiusIDs type:#stringTab tabSize:0 tabSizeVariable:true
        procRadiusModes type:#intTab tabSize:0 tabSizeVariable:true
        procRadiusValues type:#floatTab tabSize:0 tabSizeVariable:true
        procRadiusDistances type:#worldUnitsTab tabSize:0 tabSizeVariable:true
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
        procRuleGapWU type:#worldUnitsTab tabSize:0 tabSizeVariable:true
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
        on procRadiusIDs set value index do markInputDirty()
        on procRadiusModes set value index do markInputDirty()
        on procRadiusValues set value index do markInputDirty()
        on procRadiusDistances set value index do markInputDirty()
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
        on procRuleGapWU set value index do markInputDirty()
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
    local procPublishedMetadata=#(),procDisplayFailure=false
    local procDensityMap=undefined,procDensityWatch=undefined,procDensityRevision=0
    local procDensityCache=#(),procDensityBakes=0,procDensityHits=0,procDensityInversions=0,procDensityBakeMs=0
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
        if this.layerObjects.count>0 do for layer in this.layerObjects do join nodes (layer.validSurfaces())
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
    local radiusPreview=#(),inspectionCache=undefined
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
        viewportNavigationPoints type:#integer default:10000
        viewportNavigationInstances type:#integer default:500
        viewportNavigationFaces type:#integer default:500000
        on viewportMode set v do markInputDirty()
        on proxyShape set v do markInputDirty()
        on viewportNavigationPoints set v do markInputDirty()
        on viewportNavigationInstances set v do markInputDirty()
        on viewportNavigationFaces set v do markInputDirty()
        on viewportInstances set v do markInputDirty()
        on viewportFaces set v do markInputDirty()
    )
    parameters radiusDisplaySettings (
        radiusDisplayLimit type:#integer default:2000
        radiusDisplayAll type:#boolean default:false
        radiusDisplayMetric type:#integer default:1
        on radiusDisplayLimit set v do markInputDirty()
        on radiusDisplayAll set v do markInputDirty()
        on radiusDisplayMetric set v do markInputDirty()
    )
    parameters radiusSettings (
        sourceRadiiWU type:#worldUnitsTab tabSize:0 tabSizeVariable:true
        sourceFollowScale type:#boolTab tabSize:0 tabSizeVariable:true
        sourceShowRadius type:#boolTab tabSize:0 tabSizeVariable:true
        sourceAutoRadius type:#boolTab tabSize:0 tabSizeVariable:true
        on sourceRadiiWU set v i do markInputDirty()
        on sourceFollowScale set v i do markInputDirty()
        on sourceShowRadius set v i do markInputDirty()
        on sourceAutoRadius set v i do markInputDirty()
    )
    fn sourceRadius i = (if i>0 and i<=sourceRadiiWU.count then sourceRadiiWU[i] else 0.0)
    fn sourceFollows i = (i>0 and i<=sourceFollowScale.count and sourceFollowScale[i])
    fn sourceShows i = (i>0 and i<=sourceShowRadius.count and sourceShowRadius[i])
    fn sourceUsesAuto i = (i>0 and i<=sourceAutoRadius.count and sourceAutoRadius[i] and not this.isPointSource i and not this.isEmptySource i)
    fn sourceCanAuto i = (i>0 and i<=sources.count and isValidNode sources[i] and not this.isPointSource i and not this.isEmptySource i and cyrusSourceSupportsAuto sources[i])
    fn setSourceRadius rows value kind:1 = (
        if kind==4 and value do for i in rows where not this.sourceCanAuto i do throw "Auto Radius is unavailable for a selected source. Point, Empty and unqualified source types use Manual radius."
        undo "Source collision radius" on (
            while sourceRadiiWU.count<sources.count do append sourceRadiiWU 0.0
            while sourceFollowScale.count<sources.count do append sourceFollowScale false
            while sourceShowRadius.count<sources.count do append sourceShowRadius false
            while sourceAutoRadius.count<sources.count do append sourceAutoRadius false
            for i in rows do case kind of (1: (sourceRadiiWU[i]=value); 2: (sourceFollowScale[i]=value); 3: (sourceShowRadius[i]=value); 4: (sourceAutoRadius[i]=value))
        )
        markInputDirty()
    )
    parameters emptySettings (
        sourceRowIDs type:#stringTab tabSize:0 tabSizeVariable:true
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
        areaFallDeleteWidths type:#worldUnitsTab tabSize:0 tabSizeVariable:true
        areaFallScaleWidths type:#worldUnitsTab tabSize:0 tabSizeVariable:true
        areaFallDensityWidths type:#worldUnitsTab tabSize:0 tabSizeVariable:true
        areaFallScaleGraphs type:#stringTab tabSize:0 tabSizeVariable:true
        areaFallDensityGraphs type:#stringTab tabSize:0 tabSizeVariable:true
        on areaFallConfigs set v i do markInputDirty()
        on areaFallDeleteWidths set v i do markInputDirty()
        on areaFallScaleWidths set v i do markInputDirty()
        on areaFallDensityWidths set v i do markInputDirty()
    )
    fn ensureAreaFalloffs = (
        while areaFallConfigs.count<this.areaNodes.count do append areaFallConfigs ""
        while areaFallDeleteWidths.count<this.areaNodes.count do append areaFallDeleteWidths 0.0
        while areaFallScaleWidths.count<this.areaNodes.count do append areaFallScaleWidths 100.0
        while areaFallDensityWidths.count<this.areaNodes.count do append areaFallDensityWidths 100.0
        while areaFallScaleGraphs.count<this.areaNodes.count do append areaFallScaleGraphs ""
        while areaFallDensityGraphs.count<this.areaNodes.count do append areaFallDensityGraphs ""
    )
    fn getFallConfig areaNode = (
        if this.isPaintArea do (
            local cfg=cyrusBrushFalloff paintDocument
            return #(false,0.0,cfg[4],cfg[1],cfg[8],cfg[3],cfg[1],cfg[7])
        )
        ensureFallCurves()
        if areaNode==undefined then #(fallDelete,fallDeleteWidth,fallScale,fallScaleWidth,fallScaleCurve as array,fallDensity,fallDensityWidth,fallDensityCurve as array) else (
            local i=findItem this.areaNodes areaNode
            if i==0 do throw "Area line was removed. Close this graph."
            ensureAreaFalloffs()
            local parts=filterString areaFallConfigs[i] "|"
            if parts.count==8 then #((parts[1] as integer)==1,areaFallDeleteWidths[i],(parts[3] as integer)==1,areaFallScaleWidths[i],CyrusFallUnpack parts[5],(parts[6] as integer)==1,areaFallDensityWidths[i],CyrusFallUnpack parts[8]) else #(false,areaFallDeleteWidths[i],false,areaFallScaleWidths[i],#(0.0,1.0),false,areaFallDensityWidths[i],#(0.0,1.0))
        )
    )
    fn setFallConfig areaNode cfg = (
        if this.isPaintArea do (
            local values=cyrusBrushFalloff paintDocument
            values[7]=cfg[8];values[8]=cfg[5]
            cyrusBrushSetFalloff paintDocument values
            this.publishPaint();return true
        )
        if areaNode==undefined then (
            fallDelete=cfg[1];fallDeleteWidth=cfg[2];fallScale=cfg[3];fallScaleWidth=cfg[4];fallScaleCurve=cfg[5];fallDensity=cfg[6];fallDensityWidth=cfg[7];fallDensityCurve=cfg[8]
        ) else (
            local i=findItem this.areaNodes areaNode
            if i==0 do throw "Area line was removed. Close this graph."
            ensureAreaFalloffs()
            local s=stringStream ""
            -- The string owns flags/curves only. Distances use Max unit scaling.
            format "%|0|%|0|%|%|0|%" (if cfg[1] then 1 else 0) (if cfg[3] then 1 else 0) (CyrusFallPack cfg[5]) (if cfg[6] then 1 else 0) (CyrusFallPack cfg[8]) to:s
            areaFallDeleteWidths[i]=cfg[2];areaFallScaleWidths[i]=cfg[4];areaFallDensityWidths[i]=cfg[7]
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
            rows=cyrusBoundaryFalloff rows paths cfg (this.effectiveSeed())
        )
        for i=1 to this.areaNodes.count where isValidNode this.areaNodes[i] do (
            cfg=getFallConfig this.areaNodes[i]
            if cfg[1] or cfg[3] or cfg[6] do rows=cyrusAreaFalloff rows this.areaNodes[i] cfg (((mod ((this.effectiveSeed() as integer64)+i*1009) 2147483647)) as integer) (if i<=this.areaModes.count then this.areaModes[i] else 1)
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
        edgeOffsetsWU type:#worldUnitsTab tabSize:0 tabSizeVariable:true
        edgeAlongWU type:#worldUnitsTab tabSize:0 tabSizeVariable:true
        edgeAcrossWU type:#worldUnitsTab tabSize:0 tabSizeVariable:true
        edgeFaceOut type:#boolean default:true
        edgeCornerRadius type:#worldunits default:10.0
        on edgeOffsetsWU set v i do markInputDirty()
        on edgeAlongWU set v i do markInputDirty()
        on edgeAcrossWU set v i do markInputDirty()
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
        sourceZOffsetsWU type:#worldUnitsTab tabSize:0 tabSizeVariable:true
        sourceScales type:#floatTab tabSize:0 tabSizeVariable:true
        on sourceZOffsetsWU set v i do markInputDirty()
        on sourceScales set v i do markInputDirty()
    )
    fn sourceZOffset i = (if i>0 and i<=sourceZOffsetsWU.count then sourceZOffsetsWU[i] else 0.0)
    fn sourceScale i = (if i>0 and i<=sourceScales.count then sourceScales[i] else 1.0)
    fn assignSourceTransform rows value scaling:false = (
        undo "Cyrus Scatter source transform" on (
            if scaling then (
                while sourceScales.count<sources.count do append sourceScales 1.0
                for i in rows where i>0 and i<=sources.count do sourceScales[i]=amax 0.0 value
            ) else (
                while sourceZOffsetsWU.count<sources.count do append sourceZOffsetsWU 0.0
                for i in rows where i>0 and i<=sources.count do sourceZOffsetsWU[i]=value
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
        movXMinWU type:#worldUnits default:0
        movXMaxWU type:#worldUnits default:0
        movYMinWU type:#worldUnits default:0
        movYMaxWU type:#worldUnits default:0
        movZMinWU type:#worldUnits default:0
        movZMaxWU type:#worldUnits default:0
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
        on movXMinWU set v do (if not layerTransfer and v>movXMaxWU do movXMaxWU=v;markInputDirty())
        on movXMaxWU set v do (if not layerTransfer and v<movXMinWU do movXMinWU=v;markInputDirty())
        on movYMinWU set v do (if not layerTransfer and v>movYMaxWU do movYMaxWU=v;markInputDirty())
        on movYMaxWU set v do (if not layerTransfer and v<movYMinWU do movYMinWU=v;markInputDirty())
        on movZMinWU set v do (if not layerTransfer and v>movZMaxWU do movZMaxWU=v;markInputDirty())
        on movZMaxWU set v do (if not layerTransfer and v<movZMinWU do movZMinWU=v;markInputDirty())
    )
    parameters distributionSettings (
        distributionMode type:#integer default:1
        densityMap type:#textureMap
        invertDensity type:#boolean default:false
        densityUVChannel type:#integer default:1
        densityResolution type:#integer default:128
        on densityUVChannel set v do markInputDirty()
        on densityResolution set v do markInputDirty()
        on distributionMode set v do markInputDirty()
        on densityMap set v do markInputDirty()
        on invertDensity set v do markInputDirty()
    )
    parameters meshDensitySettings (
        meshMaskEnabled type:#boolean default:false
        meshMaskChannel type:#integer default:0
        meshMaskComponent type:#integer default:1
        meshMaskMinimum type:#float default:0
        meshMaskMaximum type:#float default:1
        meshMaskInvert type:#boolean default:false
        meshMaskSamples type:#floatTab tabSize:0 tabSizeVariable:true
        meshMaskGraph type:#string default:""
        on meshMaskEnabled set v do this.meshMaskChanged()
        on meshMaskChannel set v do this.meshMaskChanged()
        on meshMaskComponent set v do this.meshMaskChanged()
        on meshMaskMinimum set v do this.meshMaskChanged()
        on meshMaskMaximum set v do this.meshMaskChanged()
        on meshMaskInvert set v do this.meshMaskChanged()
        on meshMaskSamples set v i do this.meshMaskChanged()
    )
    fn meshMaskCurve = (if meshMaskSamples.count==0 then #(0.0,1.0) else meshMaskSamples as array)
    fn meshMaskPayload = (#(meshMaskEnabled,meshMaskChannel,meshMaskComponent,meshMaskMinimum,meshMaskMaximum,meshMaskInvert,this.meshMaskCurve()))
    fn meshMaskChanged = (CyrusClearMeshMaskPreview this;markInputDirty())
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
        on patternLines set v i do markInputDirty()
        on patternWidths set v i do markInputDirty()
    )
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
    fn ensureSourceRows = (
        -- Row identities survive placeholder replacement, removal of other rows
        -- and save/reopen. They do not reseed the native candidate streams.
        undo off while sourceRowIDs.count<sources.count do append sourceRowIDs (CyrusNewLayerID())
        true
    )
    fn addEmptySource = (
        this.ensureSourceRows()
        undo "Cyrus Scatter add empty source" on (
            syncColors()
            while sourcePoint.count<sources.count do append sourcePoint false
            append sourcePoint false
            while sourceEmpty.count<sources.count do append sourceEmpty false
            while sourceWeights.count<sources.count do append sourceWeights 1.0
            sources.count=sources.count+1;append sourceEmpty true;append sourceWeights 1.0
            append sourceRowIDs (CyrusNewLayerID())
            append sourceColors (color 100 100 100)
            if sourceZOffsetsWU.count>0 do append sourceZOffsetsWU 0.0
            if sourceScales.count>0 do append sourceScales 1.0
        )
        markInputDirty();sources.count
    )
    fn addPointSource = (
        local i
        undo "Cyrus Scatter add Point" on (i=addEmptySource();sourcePoint[i]=true)
        markInputDirty();i
    )
    fn replacePointSource row node = (
        if not (isPointSource row) or not (usableSource node) or (findItem sources node>0 and findItem sources node!=row) do return false
        this.ensureSourceRows()
        undo "Cyrus Scatter replace point" on (
            sources[row]=node;sourcePoint[row]=false;sourceEmpty[row]=false
        )
        containerConfigKey="";containerUIChanged=true
        markInputDirty();previewBuildCount=0;true
    )
    fn makePointSource row = (
        if row<1 or row>sources.count or this.isEmptySource row or not this.usableSource sources[row] do return false
        this.ensureSourceRows()
        undo "Cyrus Scatter make Point" on (
            while sourcePoint.count<sources.count do append sourcePoint false
            while sourceEmpty.count<sources.count do append sourceEmpty false
            sourcePoint[row]=true;sourceEmpty[row]=true
        )
        -- Retain the registered node so an automatic container scan cannot
        -- add it again. validSources resolves this row to a Point token; the
        -- scene object, row identity and stored Manual/Auto settings survive.
        containerConfigKey="";containerUIChanged=true
        markInputDirty();previewBuildCount=0;true
    )
    fn placementRadii rows plants = (this.procRadii rows plants)
    fn cacheRadii rows plants values:undefined = (
        radiusPreview=#()
        if plants.count>0 and (findItem (sourceShowRadius as array) true)>0 do (
            local radii=if values==undefined then placementRadii rows plants else values
            if radiusDisplayMetric<1 or radiusDisplayMetric>2 do throw "Radius display metric must be XY or 3D."
            local eligible=for j=1 to rows.count where (sourceShows (sourceRow plants[rows[j][2]])) and radii[j][radiusDisplayMetric]>0 collect j
            local count=if radiusDisplayAll then eligible.count else amin (amax 0 radiusDisplayLimit) eligible.count
            local ringsPerRadius=if radiusDisplayMetric==1 then 1 else 3
            if count*ringsPerRadius>10000 do throw "Radius display exceeds 10,000 rings. Reduce Radii / layer (at most 3,333 in 3D)."
            for k=1 to count do (
                local j=eligible[1+(floor((k-1.0)*eligible.count/(amax 1 count)) as integer)]
                local i=sourceRow plants[rows[j][2]]
                if sourceShows i and radii[j][radiusDisplayMetric]>0 do (
                    local center=rows[j][1].row4,r=radii[j][radiusDisplayMetric]
                    for axis=1 to ringsPerRadius do (
                        local points=#()
                        for segment=0 to 23 do (
                            local a=r*cos(segment*15),b=r*sin(segment*15)
                            local offset=case axis of (
                                1: [a,b,0]
                                2: [a,0,b]
                                default: [0,a,b]
                            )
                            append points (center+offset)
                        )
                        append radiusPreview #(points,sourceColor i)
                    )
                )
            )
        )
    )
    fn radiusDisplayCount = radiusPreview.count
    fn drawInspection = (if inspectionCache!=undefined do aminScatterDrawPreview inspectionCache false white)
    fn validSources = (for i=1 to sources.count where (isEmptySource i) or (usableSource sources[i]) collect (if isEmptySource i then -i else sources[i]))
    parameters fieldDisplaySettings (
        fieldFalloff type:#boolean default:false animatable:false
        fieldBoundaries type:#boolean default:false animatable:false
        fieldCombined type:#boolean default:false animatable:false
        fieldSamples type:#integer default:4000 animatable:false
        fieldBandID type:#integer default:0 animatable:false
        on fieldFalloff set v do markInputDirty()
        on fieldBoundaries set v do markInputDirty()
        on fieldCombined set v do markInputDirty()
        on fieldSamples set v do markInputDirty()
        on fieldBandID set v do markInputDirty()
    )
    parameters strokeSettings (
        streetStraight type:#boolean default:false
        on streetStraight set v do markInputDirty()
        strokeSides type:#intTab tabSize:0 tabSizeVariable:true
        patternPaths type:#nodeTab tabSize:0 tabSizeVariable:true
        strokeModes type:#intTab tabSize:0 tabSizeVariable:true
        strokeColorRows type:#intTab tabSize:0 tabSizeVariable:true
        strokeColorKeys type:#intTab tabSize:0 tabSizeVariable:true
        strokeSourceRows type:#intTab tabSize:0 tabSizeVariable:true
        strokeSourceIDs type:#stringTab tabSize:0 tabSizeVariable:true
        strokeMin type:#floatTab tabSize:0 tabSizeVariable:true
        strokeMax type:#floatTab tabSize:0 tabSizeVariable:true
        analyzerNode type:#node useNodeTmValidity:true useNodeOsValidity:true
        on analyzerNode set v do markInputDirty()
    )
    -- Schema 58: IDs are local to the existing layer namespace, never RNG seeds.
    parameters splineBandSettings (
        nextPathID type:#integer default:1
        nextBandID type:#integer default:1
        pathIDs type:#intTab tabSize:0 tabSizeVariable:true
        pathJoins type:#intTab tabSize:0 tabSizeVariable:true
        strokeIDs type:#intTab tabSize:0 tabSizeVariable:true
        strokePathIDs type:#intTab tabSize:0 tabSizeVariable:true
        bandArrangement type:#integer default:1
        strokeStarts type:#worldUnitsTab tabSize:0 tabSizeVariable:true
        strokeEnds type:#worldUnitsTab tabSize:0 tabSizeVariable:true
        strokeStrengths type:#floatTab tabSize:0 tabSizeVariable:true
        strokeCurveEnabled type:#boolTab tabSize:0 tabSizeVariable:true
        strokeCurveSamples type:#stringTab tabSize:0 tabSizeVariable:true
        strokeCurveGraphs type:#stringTab tabSize:0 tabSizeVariable:true
        strokeScaleModes type:#intTab tabSize:0 tabSizeVariable:true
        strokeScaleSamples type:#stringTab tabSize:0 tabSizeVariable:true
        strokeScaleGraphs type:#stringTab tabSize:0 tabSizeVariable:true
        strokeDisplayColors type:#colorTab tabSize:0 tabSizeVariable:true
        on bandArrangement set v do markInputDirty()
        on pathJoins set v i do markInputDirty()
        on strokeStarts set v i do markInputDirty()
        on strokeEnds set v i do markInputDirty()
        on strokeStrengths set v i do markInputDirty()
        on strokeCurveEnabled set v i do markInputDirty()
        on strokeCurveSamples set v i do markInputDirty()
        on strokeScaleModes set v i do markInputDirty()
        on strokeScaleSamples set v i do markInputDirty()
    )
    fn allocatePathID = (
        if nextPathID<1 or nextPathID>=2147483647 do throw "Path identity space exhausted."
        local result=nextPathID;nextPathID+=1;result
    )
    fn allocateBandID = (
        if nextBandID<1 or nextBandID>=2147483647 do throw "Band identity space exhausted."
        local result=nextBandID;nextBandID+=1;result
    )
    fn syncBandRecords = (
        if pathIDs.count!=patternPaths.count or pathJoins.count!=pathIDs.count do throw "Saved Path records are incomplete; this scene requires complete schema-58 records."
        for key in #(#patternWidths,#strokeSides,#strokeModes,#strokeMin,#strokeMax,#edgeRotX,#edgeRotY,#edgeRotZ,#edgeOffsetsWU,#edgeAlongWU,#edgeAcrossWU,#strokeIDs,#strokePathIDs,#strokeStarts,#strokeEnds,#strokeStrengths,#strokeCurveEnabled,#strokeScaleModes,#strokeScaleSamples,#strokeCurveSamples,#strokeScaleGraphs,#strokeCurveGraphs,#strokeDisplayColors) where (getProperty this key).count!=patternLines.count do throw ("Incomplete Band records: "+(key as string))
        if strokeSourceRows.count!=strokeSourceIDs.count or strokeColorRows.count!=strokeColorKeys.count do throw "Incomplete Band assignment records."
        if pathIDs.count>32 or strokeIDs.count>64 do throw "A layer supports at most 32 Paths and 64 Bands."
        local seen=#(),largest=0
        for id in pathIDs do (if id<1 or findItem seen id>0 do throw "Saved Path identities must be positive and unique.";append seen id;largest=amax largest id)
        if nextPathID<=largest do throw "Saved Path identity counter is invalid."
        seen=#();largest=0
        for id in strokeIDs do (if id<1 or findItem seen id>0 do throw "Saved Band identities must be positive and unique.";append seen id;largest=amax largest id)
        if nextBandID<=largest do throw "Saved Band identity counter is invalid."
        for i=1 to strokePathIDs.count do (
            local p=findItem pathIDs strokePathIDs[i]
            if p==0 or (isValidNode patternLines[i] and patternPaths[p]!=patternLines[i]) do throw "Saved Band-to-Path identity is inconsistent."
        )
        for mode in strokeScaleModes where mode<1 or mode>3 do throw "Unknown saved Band scale profile."
        for rows in #(strokeSourceRows,strokeColorRows) do for row in rows where row<1 or row>strokeIDs.count do throw "Band assignment refers to a missing row."
        true
    )
    fn addBandPath node = (
        if not isValidNode node do throw "Choose an active closed Path."
        local slot=findItem patternPaths node
        if slot>0 do return pathIDs[slot]
        if patternPaths.count>=32 do throw "A layer supports at most 32 Paths."
        local id=this.allocatePathID()
        append patternPaths node;append pathIDs id;append pathJoins 1
        markInputDirty();id
    )
    fn bandInterval row = (
        if bandArrangement==2 do return #(strokeStarts[row],strokeEnds[row])
        local first=0.0
        for i=1 to row-1 where strokePathIDs[i]==strokePathIDs[row] and strokeSides[i]==strokeSides[row] do first+=patternWidths[i]
        #(first,first+patternWidths[row])
    )
    fn bandName row = (
        local ordinal=0
        for i=1 to row where strokePathIDs[i]==strokePathIDs[row] and strokeSides[i]==strokeSides[row] do ordinal+=1
        local prefix=#("Out ","In ","Both ","Radius ","Single ","Street ","Edge ")
        prefix[strokeSides[row]]+(ordinal as string)
    )
    fn sourceBandRows sourceIndex = (
        if diversityMode!=3 or sourceIndex<1 or sourceIndex>sourceRowIDs.count do return #()
        local id=sourceRowIDs[sourceIndex],group=this.colorKey (this.sourceColor sourceIndex),result=#()
        for row=1 to strokeIDs.count do (
            local selected=false
            if strokeModes[row]==1 then (for j=1 to strokeColorRows.count where strokeColorRows[j]==row and strokeColorKeys[j]==group do selected=true)
            else (for j=1 to strokeSourceRows.count where strokeSourceRows[j]==row and strokeSourceIDs[j]==id do selected=true)
            if selected do append result row
        )
        result
    )
    fn sourceBandLabel sourceIndex = (
        local rows=this.sourceBandRows sourceIndex
        if rows.count==0 then "Unassigned" else if rows.count==1 then this.bandName rows[1] else (rows.count as string)+" Bands"
    )
    fn bandAssignmentCount row = (
        local count=0
        for i=1 to sources.count where findItem (this.sourceBandRows i) row>0 do count+=1
        count
    )
    fn sourceBandDetails sourceIndex = (
        local rows=this.sourceBandRows sourceIndex,stream=stringStream ""
        for row in rows do (
            local slot=findItem pathIDs strokePathIDs[row],node=if slot>0 then patternPaths[slot] else undefined,interval=this.bandInterval row
            format "% #% / %: % - % (%)\n" (if isValidNode node then node.name else "Missing Path") strokePathIDs[row] (this.bandName row) (units.formatValue interval[1]) (units.formatValue interval[2]) (if strokeModes[row]==1 then "group" else "direct") to:stream
        )
        if rows.count==0 then "No authored Band assignment." else stream as string
    )
    fn consecutiveBandProposal = (
        local result=#(),keys=#(),totals=#(),lossless=true
        for i=1 to strokeIDs.count do (
            local key=(strokePathIDs[i] as string)+":"+(strokeSides[i] as string),slot=findItem keys key
            if slot==0 do (append keys key;append totals 0.0;slot=keys.count)
            local first=totals[slot],width=strokeEnds[i]-strokeStarts[i]
            if width<=0 do throw "Independent Bands require Start < End."
            local last=first+width,tolerance=amax (units.decodeValue "0.0001mm") (width*0.000001)
            if abs(first-strokeStarts[i])>tolerance or abs(last-strokeEnds[i])>tolerance do lossless=false
            append result #(strokeIDs[i],first,last);totals[slot]=last
        )
        #(lossless,result)
    )
    fn convertBandArrangement mode acceptChanges:false = (
        if mode!=1 and mode!=2 do throw "Unknown Band arrangement."
        if mode==bandArrangement do return true
        this.syncStrokes()
        local intervals=if mode==2 then (for i=1 to strokeIDs.count collect this.bandInterval i) else (this.consecutiveBandProposal())[2]
        if mode==1 and not acceptChanges and not (this.consecutiveBandProposal())[1] do throw "Review and confirm the proposed consecutive ranges before conversion."
        undo "Cyrus Band arrangement" on (
            for i=1 to strokeIDs.count do (
                if mode==2 then (strokeStarts[i]=intervals[i][1];strokeEnds[i]=intervals[i][2])
                else patternWidths[i]=intervals[i][3]-intervals[i][2]
            )
            bandArrangement=mode
        )
        true
    )
    fn bandCurve row = (
        if not strokeCurveEnabled[row] then #(1.0,1.0) else (
            local parts=filterString strokeCurveSamples[row] ","
            if parts.count<2 or parts.count>257 do throw "Band density requires 2 to 257 bounded samples."
            for part in parts collect (local v=part as float;if v<0 or v>1 or v!=v do throw "Band density samples must be finite and between zero and one.";v)
        )
    )
    fn bandScaleCurve row = (
        case strokeScaleModes[row] of (
            1: #(1.0,1.0)
            2: this.bandCurve row
            3: (
                local parts=filterString strokeScaleSamples[row] ","
                if parts.count<2 or parts.count>257 do throw "Band scale requires 2 to 257 bounded samples."
                for part in parts collect (local v=part as float;if v<0 or v>100 or v!=v do throw "Band scale samples must be finite and between zero and 100 (10000%).";v)
            )
            default: throw "Unknown Band scale profile."
        )
    )
    fn syncStrokes = (this.ensureSourceRows();this.syncBandRecords())
    fn addStroke path side:1 = (
        if not isValidNode path do throw "Choose an active Path before adding a Band."
        this.syncStrokes()
        if patternLines.count>=64 or side<1 or side>7 do throw "Invalid Band side or 64-Band limit reached."
        local pathID=this.addBandPath path,id=this.allocateBandID(),first=0.0,width=units.decodeValue "1m"
        for i=1 to strokeIDs.count where strokePathIDs[i]==pathID and strokeSides[i]==side do first+=patternWidths[i]
        append patternLines path;append patternWidths width
        append strokeSides side;append strokeModes (if diversityMode==4 then 1 else 2);append strokeMin 1.0;append strokeMax 1.0
        for key in #(#edgeRotX,#edgeRotY,#edgeRotZ,#edgeOffsetsWU,#edgeAlongWU,#edgeAcrossWU) do append (getProperty this key) 0.0
        append strokeIDs id;append strokePathIDs pathID;append strokeStarts first;append strokeEnds (first+width)
        append strokeStrengths 1.0;append strokeCurveEnabled false;append strokeCurveSamples "1,1";append strokeCurveGraphs "";append strokeScaleModes 1;append strokeScaleSamples "1,1";append strokeScaleGraphs ""
        append strokeDisplayColors (color (64+mod((mod pathID 160)*53) 160) (64+mod((mod id 160)*97) 160) (64+mod((mod id 160)*29) 160))
        if fieldBandID==0 do fieldBandID=id
        if diversityMode==4 and sources.count>0 do this.setStrokeSelection patternLines.count 1 #((this.colorKey (this.sourceColor 1)))
        this.syncStrokes();markInputDirty();patternLines.count
    )
    fn removeStroke row = (
        syncStrokes()
        for pair in #(#strokeColorRows,#strokeSourceRows) do (
            local rows=getProperty this pair
            local values=getProperty this (if pair==#strokeColorRows then #strokeColorKeys else #strokeSourceIDs)
            for i=rows.count to 1 by -1 do (
                if rows[i]==row then (deleteItem rows i;deleteItem values i)
                else if rows[i]>row do rows[i]-=1
            )
        )
        for key in #(#edgeRotX,#edgeRotY,#edgeRotZ,#edgeOffsetsWU,#edgeAlongWU,#edgeAcrossWU,#strokeSides,#patternLines,#patternWidths,#strokeModes,#strokeMin,#strokeMax,#strokeIDs,#strokePathIDs,#strokeStarts,#strokeEnds,#strokeStrengths,#strokeCurveEnabled,#strokeScaleModes,#strokeScaleSamples,#strokeCurveSamples,#strokeScaleGraphs,#strokeCurveGraphs,#strokeDisplayColors) do deleteItem (getProperty this key) row
        markInputDirty()
    )
    fn removeBandPath id = (
        this.syncStrokes();local slot=findItem pathIDs id
        if slot==0 do return false
        undo "Cyrus remove Path" on (
            for i=strokeIDs.count to 1 by -1 where strokePathIDs[i]==id do this.removeStroke i
            deleteItem patternPaths slot;deleteItem pathIDs slot;deleteItem pathJoins slot
        )
        markInputDirty();true
    )
    fn moveBand id target = (
        this.syncStrokes();local row=findItem strokeIDs id
        if row==0 or target<1 or target>strokeIDs.count do throw "Invalid Band move."
        if row==target do return false
        local previous=strokeIDs as array
        undo "Cyrus reorder Band" on (
            for key in #(#edgeRotX,#edgeRotY,#edgeRotZ,#edgeOffsetsWU,#edgeAlongWU,#edgeAcrossWU,#strokeSides,#patternLines,#patternWidths,#strokeModes,#strokeMin,#strokeMax,#strokeIDs,#strokePathIDs,#strokeStarts,#strokeEnds,#strokeStrengths,#strokeCurveEnabled,#strokeScaleModes,#strokeScaleSamples,#strokeCurveSamples,#strokeScaleGraphs,#strokeCurveGraphs,#strokeDisplayColors) do (
                local values=(getProperty this key) as array,value=values[row]
                deleteItem values row;insertItem value values target;setProperty this key values
            )
            for key in #(#strokeColorRows,#strokeSourceRows) do (
                local rows=getProperty this key
                for i=1 to rows.count do rows[i]=findItem strokeIDs previous[rows[i]]
            )
        )
        this.syncStrokes();markInputDirty();true
    )
    fn setStrokeSelection row mode values = (
        syncStrokes()
        local rows=if mode==1 then strokeColorRows else strokeSourceRows
        local targets=if mode==1 then strokeColorKeys else strokeSourceIDs
        for i=rows.count to 1 by -1 where rows[i]==row do (deleteItem rows i;deleteItem targets i)
        for value in values do (
            if mode==1 then (append rows row;append targets value) else (
                local index=if classof value==String then findItem sourceRowIDs value else findItem sources value
                if index>0 do (
                    append rows row;append targets sourceRowIDs[index]
                )
            )
        )
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

    local procSplineField=undefined,procSplineKey="",procSplineBuilds=0,procSplineHits=0
    fn splineFieldStats = (#(procSplineBuilds,procSplineHits,(if procSplineField==undefined then #() else cyrusSplineFieldStats procSplineField)))
    fn lineInputs plants previewOnly:false = (
        if diversityMode!=3 and diversityMode!=4 then #(false,#()) else (
            syncStrokes()
            if diversityMode==4 and not isValidNode analyzerNode do throw "Pick a Surface Analyzer."
            local keys=for n in plants collect colorKey(sourceColor(sourceRow n))
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
                    choices=for j=1 to plants.count where findItem groups keys[j]>0 collect j
                ) else (
                    for j=1 to strokeSourceRows.count where strokeSourceRows[j]==i do (
                        local slot=findItem sourceRowIDs strokeSourceIDs[j]
                        local k=if slot>0 then findItem plants (if isEmptySource slot then -slot else sources[slot]) else 0
                        if k>0 and findItem choices k==0 do append choices k
                    )
                )
                if previewOnly and plants.count==0 and diversityMode==4 do choices=#(1)
                if choices.count>0 or diversityMode==3 do (
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
                    append bands #(data,(if side==7 then patternWidths[i] else totals[pathIndex][side]),choices,strokeMin[i],strokeMax[i],(if side==7 then 6 else if side==6 then 2 else side),(if side==7 then 0 else start),mask,(side==6 and streetStraight),#((if side==7 then edgeFaceOut else if side==6 then streetFaceOut else if side<=2 then borderFaceOut else false),(if side==7 then edgeCornerRadius else if side==6 then streetCornerRadius else borderCornerRadius)),#(edgeOffsetsWU[i],edgeAlongWU[i],edgeAcrossWU[i],edgeKeepCorners,edgeCornerAngle,edgeCornerCount,edgeRotX[i],edgeRotY[i],edgeRotZ[i]))
                ) else (
                    local savedPath=findItem pathIDs strokePathIDs[i]
                    if savedPath==0 do throw "Band refers to a missing Path identity."
                    local sourceIDs=for k in choices collect sourceRowIDs[sourceRow plants[k]]
                    local empties=for k in choices collect (isEmptySource(sourceRow plants[k]) and not isPointSource(sourceRow plants[k]))
                    local first=if bandArrangement==1 then start else strokeStarts[i]
                    local last=if bandArrangement==1 then totals[pathIndex][side] else strokeEnds[i]
                    append bands #(path,strokePathIDs[i],strokeIDs[i],side==2,first,last,pathJoins[savedPath],strokeStrengths[i],this.bandCurve i,choices,sourceIDs,empties,strokeMin[i],strokeMax[i],this.bandScaleCurve i)
                )
                )
            )
            #(true,bands)
        )
    )


    fn preparedSplineField records weights = (
        local nodes=#(),stream=stringStream "",quantum=units.decodeValue "0.0001mm"
        for row in records do appendIfUnique nodes row[1]
        with printAllElements on format "%|%|%|%|%" records weights bandArrangement quantum (cyrusReceiverShapeKey nodes) to:stream
        local key=stream as string
        if procSplineField!=undefined and key==procSplineKey do (procSplineHits+=1;return procSplineField)
        local successor=cyrusPrepareSplineField records weights bandArrangement quantum
        procSplineField=successor;procSplineKey=key;procSplineBuilds+=1
        successor
    )


    fn fieldSelectedID = (if findItem strokeIDs fieldBandID>0 then fieldBandID else 0)
    fn fieldPreviewEnabled = (diversityMode==3 and (fieldFalloff or fieldBoundaries) and (fieldCombined or this.fieldSelectedID()>0))
    local procFieldCache=undefined,procFieldCacheKey="",procFieldStatus="Preview hidden."
    fn fieldPreviewStatus = (
        if previewError!="" and this.fieldPreviewEnabled() then "Previous preview retained. "+previewError
        else if not (fieldFalloff or fieldBoundaries) then "Preview hidden."
        else if not fieldCombined and this.fieldSelectedID()==0 then "Select a Band to preview."
        else procFieldStatus
    )
    fn procFieldInputKey = (
        if diversityMode!=3 do return ""
        local stream=stringStream "",plants=this.validSources(),nodes=this.validSurfaces()
        for node in patternPaths where isValidNode node do appendIfUnique nodes node
        with printAllElements on (
            format "Field1:%:%|" (units.decodeValue "0.0001mm") (cyrusFieldDependencyKey nodes) to:stream
            for key in #(#bandArrangement,#pathIDs,#pathJoins,#patternLines,#patternWidths,#strokeIDs,#strokePathIDs,#strokeSides,#strokeStarts,#strokeEnds,#strokeStrengths,#strokeCurveEnabled,#strokeScaleModes,#strokeScaleSamples,#strokeCurveSamples,#strokeModes,#strokeColorRows,#strokeColorKeys,#strokeSourceRows,#strokeSourceIDs,#sourceRowIDs,#strokeMin,#strokeMax) do format "%:%|" key (getProperty this key) to:stream
            for node in plants do (local row=this.sourceRow node;format "%:%:%:%|" node (this.sourceWeight row) (this.sourceColor row) (this.isEmptySource row and not this.isPointSource row) to:stream)
        )
        stream as string
    )
    fn procStageField publishedKey = (
        if not this.fieldPreviewEnabled() do return #(undefined,"","Preview hidden.")
        if fieldSamples<1 or fieldSamples>20000 do throw "Field sample limit must be 1..20,000."
        local recipe=this.procFieldInputKey(),selected=if fieldCombined then 0 else this.fieldSelectedID()
        local stream=stringStream ""
        format "%|%:%:%:%" recipe selected fieldFalloff fieldBoundaries fieldSamples to:stream
        local key=stream as string,cache=procFieldCache
        if cache==undefined or key!=procFieldCacheKey do (
            local plants=this.validSources(),records=(this.lineInputs plants)[2]
            local shares=for node in plants collect this.sourceWeight (this.sourceRow node)
            local field=this.preparedSplineField records shares
            cache=cyrusBuildFieldPreview field (this.validSurfaces()) #(selected,fieldFalloff,fieldBoundaries,fieldSamples,(units.decodeValue "0.05mm"))
        )
        local stats=cyrusFieldPreviewInfo cache 0
        local mode=if fieldCombined then "Combined density" else this.bandName (findItem strokeIDs selected)
        local status=mode+"\n"+(if recipe==publishedKey then "Field from last Update" else "Pending field; plants from last Update")
        status+="\n"+(if fieldFalloff then ((CyrusUICount stats[2])+" samples / "+(CyrusUICount stats[5])+" faces; approximate coverage") else "Boundaries only")
        if fieldBoundaries do status+="\n"+(CyrusUICount stats[4])+" clipped boundary segments"
        #(cache,key,status)
    )

    -- Logical layers own policy; population objects are stable, independent sets.
    parameters layerOwnership (
        logicalParentID type:#string default:""
        paintSetName type:#string default:"Base"
        paintSetEnabled type:#boolean default:true
        paintSetVisible type:#boolean default:true
        on logicalParentID set value do markInputDirty()
        on paintSetEnabled set value do markInputDirty()
    )
    fn logicalParent leaf = (
        if leaf.logicalParentID=="" do return leaf
        for candidate in this.layerObjects where candidate.layerID==leaf.logicalParentID and candidate.logicalParentID=="" do return candidate
        throw "Paint Area has no owning layer."
    )
    fn logicalLayers = (
        local members=for leaf in this.layerObjects where leaf.logicalParentID=="" collect leaf
        this.procSort members
    )
    fn layerSets parent = (#(parent))
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
    fn layerCaption parent = (local i=findItem this.layerObjects parent;if i>0 then this.layerNames[i] else "Removed layer")
    fn setCaption leaf = ((this.layerCaption (this.logicalParent leaf))+" / "+leaf.paintSetName)
    fn populationAllocation leaf countOverride:undefined = (
        if not this.enabledLayer (findItem this.layerObjects leaf) do return #(0,0.0)
        #(if countOverride==undefined then leaf.amount else countOverride,leaf.plantsPerM2)
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
    fn removeLogicalLayer parent = (
        local members=this.layerSets parent
        for member in members where (for node in member.bakedNodes where isValidNode node collect node).count>0 do throw "Remove the layer's baked output before deleting it."
        undo "Cyrus remove layer" on (
            for i=this.layerObjects.count to 1 by -1 where findItem members this.layerObjects[i]>0 do (this.activeLayer=i;this.removePopulation())
        )
        this.invalidateGroups();this.bindNativeUI()
    )
    fn copyLogicalLayer origin = (
        local members=(for candidate in this.layerObjects where candidate==origin or candidate.logicalParentID==origin.layerID collect candidate),copyParent,copies=#()
        if this.layerObjects.count+members.count>10 do throw "Copy exceeds the 10-population capacity."
        undo "Cyrus copy layer and areas" on (
            for member in members do (
                this.newLayer();local destination=this.selectedLayer();append copies destination
                AminScatterCopyLayer member destination
                destination.bakedNodes=#()
                if member==origin then (
                    copyParent=destination;destination.logicalParentID="";destination.uiAreaID=""
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
        if group==undefined or not group.isPaintArea do throw "Select a Paint Area first."
        local parent=this.logicalParent group,target=group.areaTarget
        if not isValidNode target or findItem (parent.validSurfaces()) target==0 do throw "This Paint Area is inactive. Restore its surface or create another area."
        CyrusStopBrush()
        undo "Cyrus vector area" on (
            if group.paintDocument==undefined or reset do group.paintDocument=cyrusBrushCreate target
            parent.paintEnabled=painted;group.paintEnabled=true
        )
        group.setOverlapOwner this;parent.markInputDirty();this.bindNativeUI();true
    )

    local paintBaseFaceCounts=#()
    local blockerCacheKey="",blockerCacheRows=#(),blockerCacheBuilds=0,blockerCacheHits=0

    fn blockerCacheStats = (#(blockerCacheBuilds,blockerCacheHits))
    fn filterSourceRowsByPolicy rows keep = (
        cyrusFilterSourceRows rows keep
    )
    -- One generation path. Eligibility follows candidate movement; author edits
    -- and the three collision scopes run later in the ordered publication pass.
    fn cspImpl_placements plants previewOnly:false rawOnly:false finalPass:undefined = (
        this.procAssertSchema()
        if not rawOnly and finalPass==undefined and overlapOwner!=undefined do return overlapOwner.groupPlacements this plants previewOnly
        if not cyrusEnabled or disabledAnalyzerInput() do return #()
        if (this.brushMaskActive() or meshMaskEnabled) and not projectMove and (movXMinWU!=0 or movXMaxWU!=0 or movYMinWU!=0 or movYMaxWU!=0 or movZMinWU!=0 or movZMaxWU!=0 or movementRange!=0) do throw "Paint and mesh density masks require Keep on surface for nonzero movement."
        local targets=this.validSurfaces(),seed=this.effectiveSeed(),sourceCount=amax 1 plants.count
        if targets.count==0 do return #()
        if plants.count==0 and not previewOnly do throw "Add a plant model."
        requestedCount=if procCandidateCount==undefined then (this.effectivePopulation())[1] else procCandidateCount
        if requestedCount<=0 do return #()
        local baseKey=(this.paintBaseInputKey plants previewOnly)+"|StablePool:"+(requestedCount as string)
        local result
        if finalPass==undefined and baseKey==paintBaseKey and paintBaseRows!=undefined then (result=paintBaseRows;paintBaseHits+=1)
        else (
            local weights=if distributionMode==3 then this.procDensityWeights() else #()
            local areas=this.areaInputs(),line=this.lineInputs plants previewOnly:previewOnly
            local groups=if plants.count==0 then #(0) else for n in plants collect colorKey (sourceColor (sourceRow n))
            local shares=if plants.count==0 then #(1.0) else for n in plants collect sourceWeight (sourceRow n)
            if diversityMode==3 do line=this.preparedSplineField line[2] shares
            if finalPass!=undefined do throw "Use the receiver-local candidate path before final acceptance."
            local shapeNodes=for node in areaNodes where isValidNode node collect node
            if diversityMode==3 do for node in patternLines where isValidNode node do appendIfUnique shapeNodes node
            local commonKey=(this.paintBaseInputKey plants previewOnly receiverLocal:true)+"|Shapes:"+(cyrusReceiverShapeKey shapeNodes)
            local nextCache=#(),faceOffset=0
            result=#();paintBaseFaceCounts=cyrusReceiverFaceCounts targets
            for receiverIndex=1 to targets.count do (
                local receiver=targets[receiverIndex],slot=findItem procReceiverNodes receiver,request=undefined,geometryKey=""
                for entry in procReceiverPlanData[1] where entry[1]==slot do request=entry
                for entry in procReceiverGeometry where entry[1]==slot do geometryKey=entry[2]+"|MeshMask:"+entry[3]
                if request==undefined do throw "Receiver allocation is missing."
                local receiverCount=request[4],receiverRows=#()
                local receiverKey=commonKey+"|"+procReceiverIDs[slot]+"|"+geometryKey+"|"+(receiverCount as string)
                local cached=undefined
                for entry in procReceiverCache where entry[1]==slot and entry[2]==receiverKey do cached=entry[3]
                if cached!=undefined then (receiverRows=cached;procReceiverHits+=1)
                else if receiverCount>0 do (
                    local options=#(not advancedAxes,scaleMinimum,scaleMaximum,tiltDegrees,yawMinimum,yawMaximum,movementRange,1,0,procReceiverIDs[slot],slot,(if distributionMode==3 then densityUVChannel else 1))
                    receiverRows=cyrusScatterAdvanced #(receiver) receiverCount seed sourceCount [sclXMin,sclYMin,sclZMin] [sclXMax,sclYMax,sclZMax] [rotXMin,rotYMin,rotZMin] [rotXMax,rotYMax,rotZMax] [movXMinWU,movYMinWU,movZMinWU] [movXMaxWU,movYMaxWU,movZMaxWU] alignNormal projectMove (distributionMode-1) weights densityResolution groups (diversityMode==2) diversitySize diversitySeed (roughness/100.0) (blurryEdge/100.0) (diversityNoise/100.0) areas[1] areas[2] line #(relaxEnabled,relaxSpacing,relaxIterations,relaxStrength) shares undefined options
                    if finalRelax and receiverRows.count>0 do (
                        local relaxPass=#(receiverRows,#(),(for row in receiverRows collect 0.0),#(),false,relaxSpacing,0,1,true,finalStrength,finalIterations,finalMaxMove,0.0,cleanupPlanar)
                        receiverRows=cyrusScatterAdvanced #(receiver) receiverCount seed sourceCount [sclXMin,sclYMin,sclZMin] [sclXMax,sclYMax,sclZMax] [rotXMin,rotYMin,rotZMin] [rotXMax,rotYMax,rotZMax] [movXMinWU,movYMinWU,movZMinWU] [movXMaxWU,movYMaxWU,movZMaxWU] alignNormal projectMove (distributionMode-1) weights densityResolution groups (diversityMode==2) diversitySize diversitySeed (roughness/100.0) (blurryEdge/100.0) (diversityNoise/100.0) areas[1] areas[2] line #(relaxEnabled,relaxSpacing,relaxIterations,relaxStrength) shares relaxPass options
                    )
                    if wholeScaleMin!=1.0 or wholeScaleMax!=1.0 do receiverRows=cyrusWholeScale receiverRows wholeScaleMin wholeScaleMax seed
                    if meshMaskEnabled do receiverRows=cyrusMeshDensityFilter receiverRows receiver (this.meshMaskPayload()) seed procReceiverIDs[slot]
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
        if plants.count>0 and (sourceZOffsetsWU.count>0 or sourceScales.count>0) do result=cyrusApplySourceTransforms result (for n in plants collect sourceZOffset (sourceRow n)) (for n in plants collect sourceScale (sourceRow n))
        result
    )

    fn pointSourceSamples n sampleSeed:undefined = (
        local result=undefined,reason=""
        try(result=aminScatterSourcePoints n pointsPerPlant (if sampleSeed==undefined then randomSeed else sampleSeed))catch(reason=getCurrentException())
        if reason!="" do throw ("Point Cloud source "+n.name+": "+reason)
        result
    )
    local uiPreviewMode=0
    fn uiLayerStats = (
        -- Display can stage an empty cache for a newly authored Manual layer.
        -- Only a committed calculation epoch establishes its first result.
        CyrusLayerStatusData hasResult:(procEpoch>0 and cachedPoints!=undefined) placements:generatedCount previewCount:cachedPointCount mode:uiPreviewMode buildMs:previewBuildMs needsUpdate:dirty errorText:previewError densityCapped:densityCapped inputOff:(disabledAnalyzerInput())
    )
    fn uiVersion = "0.82.4"
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
    fn previewCache interactionHeld:undefined allowRefresh:true = (
        local held=if interactionHeld==undefined then CyrusInteractionHeld() else interactionHeld
        if held do ((CyrusWasDragging=true;CyrusScheduleRelease());return cachedPoints)
        local inputOff=disabledAnalyzerInput()
        if inputOff!=cachedDisabledInput do (markInputDirty();cachedDisabledInput=inputOff)
        if inputOff do (
            if cachedDisabledPreview==undefined do cachedDisabledPreview=aminScatterBuildPreview #() #() #(1,1,#(),#(),false) 1
            return cachedDisabledPreview
        )
        checkAnalyzerRevision()
        if updateMode==2 or this.fieldPreviewEnabled() do this.invalidateInputTime()
        -- Manual refresh reconstructs display from the last published owners;
        -- procRefreshPreview still gates placement evaluation on explicit Update.
        -- This also applies display-only Undo/Redo while recipes remain pending.
        if dirty and allowRefresh do refreshPreview()
        cachedPoints
    )
    fn previewPoints = (
        local cache=previewCache()
        if cache==undefined then #() else aminScatterPreviewPoints cache
    )
    fn previewStats = (#(previewBuildCount,previewBuildMs,cachedPointCount))
    fn statusText = (
        if previewError!="" then previewError else (generatedCount as string)+" / "+(requestedCount as string)+" plants; "+(cachedPointCount as string)+(if viewportMode==1 then " points" else " shown instances")+(if densityCapped then " (density capped at 1,000,000)" else "")
    )
    -- Eligibility is separate from candidate generation and Edit binding.
    parameters surfaceFilterSettings (
        slopeEnabled type:#boolean default:false
        slopeMinimum type:#float default:0
        slopeMaximum type:#float default:180
        slopeLowerFade type:#float default:0
        slopeUpperFade type:#float default:0
        altitudeEnabled type:#boolean default:false
        altitudeMinimum type:#worldUnits default:0
        altitudeMaximum type:#worldUnits default:1000
        altitudeLowerFade type:#worldUnits default:0
        altitudeUpperFade type:#worldUnits default:0
        on slopeEnabled set value do markInputDirty()
        on slopeMinimum set value do markInputDirty()
        on slopeMaximum set value do markInputDirty()
        on slopeLowerFade set value do markInputDirty()
        on slopeUpperFade set value do markInputDirty()
        on altitudeEnabled set value do markInputDirty()
        on altitudeMinimum set value do markInputDirty()
        on altitudeMaximum set value do markInputDirty()
        on altitudeLowerFade set value do markInputDirty()
        on altitudeUpperFade set value do markInputDirty()
    )
    fn surfaceFilterPayload = (for key in AminScatterSurfaceFilterFields collect getProperty this key)
    fn surfaceFilterKey = (
        if not slopeEnabled and not altitudeEnabled then "off" else (
            local stream=stringStream ""
            with printAllElements on (format "%|%" (if slopeEnabled then #(slopeMinimum,slopeMaximum,slopeLowerFade,slopeUpperFade) else #()) (if altitudeEnabled then #(altitudeMinimum,altitudeMaximum,altitudeLowerFade,altitudeUpperFade) else #()) to:stream)
            stream as string
        )
    )
    local procPreparedSurfaceStats=#(0,0,0),procLastSurfaceStats=#(0,0,0)
    fn surfaceFilterStats = (procLastSurfaceStats as array)
    fn applySurfaceFilter rows = (
        if not slopeEnabled and not altitudeEnabled then (procPreparedSurfaceStats=#(-1,0,0);rows) else (
            local targets=this.validSurfaces()
            local keys=for target in targets collect (local slot=findItem procReceiverNodes target;#(slot,procReceiverIDs[slot]))
            local filtered=cyrusSurfaceFilter rows targets keys (this.effectiveSeed()) (this.surfaceFilterPayload())
            procPreparedSurfaceStats=filtered[2];filtered[1]
        )
    )
    parameters layerSettings (
        layerID type:#string default:""
        layerVisible type:#boolTab tabSize:0 tabSizeVariable:true
        on layerVisible set value index do (global CyrusPointPending;CyrusViewportRecordsDirty=true;(CyrusPointPending=true;CyrusScheduleRelease()))
        layerObjects type:#maxObjectTab tabSize:0 tabSizeVariable:true
        layerNames type:#stringTab tabSize:0 tabSizeVariable:true
        layerEnabled type:#boolTab tabSize:0 tabSizeVariable:true
        on layerEnabled set v i do (for layer in layerObjects do layer.markInputDirty())
        activeLayer type:#integer default:1
    )
    -- Saved identification metadata never enters placement keys.
    parameters identificationSettings (
        visualSourceKeys type:#stringTab tabSize:0 tabSizeVariable:true
        visualSourceLabels type:#stringTab tabSize:0 tabSizeVariable:true
        visualSourceColors type:#colorTab tabSize:0 tabSizeVariable:true
        visualSourceColorSet type:#boolTab tabSize:0 tabSizeVariable:true
        layerIDColor type:#color default:(color 100 220 120)
        identificationMode type:#integer default:1
    )
    -- Current per-layer Paint Area ownership.
    parameters regionSettings (
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
    fn addPaintArea parent target:undefined = (
        if parent==undefined or findItem layerObjects parent==0 or parent.logicalParentID!="" do throw "Select an owning layer first."
        if parent.paintAreas.count>=128 do throw "A layer supports up to 128 Paint Areas."
        local targets=parent.validSurfaces(),area
        if target==undefined and targets.count==1 do target=targets[1]
        if target!=undefined and findItem targets target==0 do throw "Choose a surface assigned to this layer."
        CyrusStopBrush()
        undo "Cyrus add Paint Area" on (
            area=createInstance AminScatterObject
            area.isPaintArea=true;area.layerID=CyrusNewLayerID();area.logicalParentID=parent.layerID
            area.paintSetName="Area "+((parent.paintAreas.count+1) as string)
            area.areaTarget=target;area.paintEnabled=true;area.setOverlapOwner this
            if isValidNode target do area.paintDocument=cyrusBrushCreate target
            append parent.paintAreas area;parent.uiAreaID=area.layerID;parent.paintEnabled=true
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
        if area.paintDocument!=undefined and ((cyrusBrushStats area.paintDocument)[2]>0) do throw "This area already has paint. Add another area for a different surface; existing paint is preserved."
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
            parent.surfaceNodes=targets;parent.surface=undefined
        )
        parent.markInputDirty();this.bindNativeUI();CyrusViewportRedraw();true
    )
    fn validatePaintConversion area = (
        if cyrusMeshDensityVersion==undefined or cyrusMeshDensityVersion()!=1 or cyrusBrushConversionVersion==undefined or cyrusBrushConversionVersion()!=1 do throw "Paint/spline conversion requires the matching Cyrus native plugins. Restart Max with the complete pair."
        local parent=if area==undefined then undefined else this.logicalParent area
        if parent==undefined or findItem layerObjects parent==0 or findItem parent.paintAreas area==0 do throw "Select a Paint Area owned by this setup."
        if area.paintDocument==undefined or not isValidNode area.areaTarget or findItem (parent.validSurfaces()) area.areaTarget==0 do throw "Choose a valid receiving surface for this Paint Area."
        if cyrusBrushTarget area.paintDocument!=area.areaTarget do throw "Paint Area and stored receiver do not match."
        true
    )
    fn exportPaintSpline area = (
        this.validatePaintConversion area
        cyrusBrushExportSpline area.paintDocument ((substring area.paintSetName 1 90)+"_Paint_Snapshot")
    )
    fn importPaintSpline area node add:false tolerance:0.1 = (
        this.validatePaintConversion area
        local changed=cyrusBrushImportSpline area.paintDocument node add tolerance
        if changed do area.publishPaint()
        changed
    )
    fn sourceVisualIndex row create:false = (
        if row<1 or row>this.sources.count do return 0
        this.ensureSourceRows()
        for values in #(visualSourceLabels,visualSourceColors,visualSourceColorSet) where values.count!=visualSourceKeys.count do throw "Incomplete current source presentation records."
        local index=findItem visualSourceKeys sourceRowIDs[row]
        if index==0 and create do (
            append visualSourceLabels ""
            append visualSourceKeys sourceRowIDs[row]
            append visualSourceColors (this.sourceColor row);append visualSourceColorSet false
            index=visualSourceKeys.count
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
        if classof value!=Color and classof value!=Point3 do throw "Source identification color requires a Color or Point3 value."
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
    fn getLayerTransfer = layerTransfer
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
    fn viewportPreparationLimit idle navigating = (if idle==0 or navigating==0 then 0 else amax idle navigating)
    fn viewportPointPreparationBudget = (
        local wanted=viewportPreparationLimit previewBudget viewportNavigationPoints,capacity=cyrusViewportPointCapacity()
        if wanted==0 then capacity else amin wanted capacity
    )
    fn viewportPointMemoryReduced = (
        local wanted=viewportPreparationLimit previewBudget viewportNavigationPoints,capacity=cyrusViewportPointCapacity()
        if wanted!=0 and wanted<=capacity do return false
        local total=0L
        for i=1 to procPublishedOwners.count where findItem layerObjects procPublishedOwners[i]>0 do (
            local slot=findItem layerObjects procPublishedOwners[i]
            if this.enabledLayer slot and this.visibleLayer slot do total+=(groupSnapshotRows[i].count as integer64)*(if groupCenters then 1 else pointsPerPlant)
        )
        total>capacity
    )
    fn syncLayerSurface obj targets:undefined layerBudget:undefined = (
        obj.setOverlapOwner this
        if obj.showCenters!=this.groupCenters do undo off obj.showCenters=this.groupCenters
        targets=obj.validSurfaces()
        local equal=obj.surfaceNodes.count==targets.count
        if equal do for i=1 to targets.count where obj.surfaceNodes[i]!=targets[i] do equal=false
        if not equal do undo off (obj.surfaceNodes=targets;obj.surface=undefined)
        if layerBudget==undefined do (
            local enabledCount=(for i=1 to layerObjects.count where this.enabledLayer i collect i).count
            layerBudget=this.viewportPointPreparationBudget()
            layerBudget=if layerBudget==0 then 0 else amax 1 (ceil(layerBudget as float/(amax 1 enabledCount)))
        )
        if obj.previewBudget!=layerBudget do undo off obj.previewBudget=layerBudget
        -- These settings belong to the controller, not an individual layer.
        undo off for key in #(#viewportMode,#proxyShape,#viewportInstances,#viewportFaces,#viewportNavigationInstances,#viewportNavigationFaces,#radiusDisplayLimit,#radiusDisplayAll,#radiusDisplayMetric,#updateMode,#showPoints,#pointsPerPlant,#pointColorMode,#solidPointColor,#autoRender) do (
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
        local key=CyrusEditStackKey this
        if key!=editCacheKey do (
            editCacheKey=key
            for layer in layerObjects do layer.markInputDirty()
        )
        local entries=#(),targets=validSurfaces()
        local enabledCount=(for i=1 to layerObjects.count where this.enabledLayer i collect i).count
        local layerBudget=this.viewportPointPreparationBudget()
            layerBudget=if layerBudget==0 then 0 else amax 1 (ceil(layerBudget as float/(amax 1 enabledCount)))
        for i=1 to layerObjects.count where includeDisabled or (cyrusEnabled and this.enabledLayer i) do (
            local obj=layerObjects[i]
            syncLayerSurface obj targets:targets layerBudget:layerBudget
            obj.checkAnalyzerRevision();obj.checkPaintRevision()
            append entries #(i,obj)
        )
        if (for e in entries where this.enabledLayer e[1] and e[2].dirty collect e).count>0 do
            for e in entries where this.enabledLayer e[1] and not e[2].dirty do e[2].markInputDirty()
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
            obj.surfaceNodes=this.surfaceNodes as array;obj.surface=this.surface
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
        local entries=layerEntries(),pending=groupSnapshotKey!="" and groupSnapshotKey!=this.groupInputKey()
        groupDisplayOnly=updateMode==1
        -- One leaf stages the controller's complete display publication.
        -- Repeating it per leaf repeats the same input/owner validation.
        try (
            if entries.count>0 do entries[1][2].refreshPreview()
            if pending and updateMode==1 do for entry in entries do entry[2].markInputDirty()
        ) catch(groupDisplayOnly=false;throw())
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
        (layerObjects.count as string)+" groups; "+(plants as string)+" plants; "+(points as string)+(if viewportMode==1 then " cached points" else " cached instances (draw limits apply)")+(if errors>0 then "; "+(errors as string)+" group(s) have a preview error" else "")+(if CyrusPointLastError!="" then "; "+CyrusPointLastError else if CyrusPointDetailStatus!="" then "; "+CyrusPointDetailStatus else "")
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
    fn brushMaskActive = (paintEnabled)
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
        local post=if this.sharedSpacing() then #(#cleanupPlanar,#sourceRadiiWU,#sourceAutoRadius,#sourceFollowScale,#finalCleanup,#finalNeighborRadius,#finalMinNeighbors,#finalMinIsland,#finalRelax,#finalStrength,#finalIterations,#finalMaxMove) else #()
        join post #(#procOrder,#procSetOrder,#procPopulation,#procAttemptFactor,#procRounds,#procRepair,#procSelfOverride,#procSelfEnabled,#procSelfMultiplier,#procSelfGap,#procSelfPlanar,#procLayerSelfEnabled,#procLayerSelfMultiplier,#procLayerSelfGap,#procLayerSelfPlanar,#procSiblingEnabled,#procSiblingMultiplier,#procSiblingGap,#procSiblingPlanar,#procRadiusIDs,#procRadiusModes,#procRadiusValues,#procRadiusDistances,#procRadiusBinding,#procSourceNodes,#procSourceIDs,#procSourceSlots,#procReceiverNodes,#procReceiverIDs,#procReceiverID,#containerMode,#containerNodes)
        local stream=stringStream ""
        with printAllElements on (
            format "%|%|%|%|%|" (this.inputTimeKey()) (if receiverLocal then 0 else procGeometryRevision) (if receiverLocal then 0 else if overlapOwner!=undefined then overlapOwner.procManualRevision else procManualRevision) (this.containerSourceKey plants) previewOnly to:stream
            format "DensityMap:%|" (if densityMap==undefined then 0 else getHandleByAnim densityMap) to:stream
            format "Ownership:%:%:%:%|" logicalParentID paintSetEnabled (if receiverLocal then 0 else this.effectivePopulation()) (this.effectiveSeed()) to:stream
            format "EffectiveRelax:%|" (relaxEnabled and not this.layerPaintActive()) to:stream
            format "FinalRelax:%:%:%:%|" finalRelax finalStrength finalIterations finalMaxMove to:stream
            format "Texture:%|" (this.procWatchDensity()) to:stream
            format "MeshMask:%|" (if meshMaskEnabled then this.meshMaskPayload() else #(false)) to:stream
            for key in AminScatterLayerFields where (distributionMode==3 or findItem #(#densityUVChannel,#densityResolution) key==0) and findItem AminScatterSurfaceFilterFields key==0 and findItem AminScatterMeshMaskFields key==0 and findItem #(#paintDocument,#paintEnabled,#paintDensity,#bakedNodes,#showPoints,#pointsPerPlant,#updateMode,#autoRender,#previewBudget,#pointColorMode,#solidPointColor) key==0 and findItem post key==0 and findItem #(#paintView,#paintColor,#showCenters,#sourceShowRadius,#paintSetName,#paintSetVisible,#fieldFalloff,#fieldBoundaries,#fieldCombined,#fieldSamples,#fieldBandID) key==0 and (not receiverLocal or findItem #(#amount,#plantsPerM2,#populationMode) key==0) do format "%:%|" key (if key==#sources then this.containerSourceKey (sources as array) else getProperty this key) to:stream
            for n in ((if receiverLocal then #() else this.validSurfaces())+(sources as array)+(areaNodes as array)+(patternLines as array)+#(analyzerNode,areaAnalyzer,fallAnalyzer)) where isValidNode n do (
                local tm=n.objectTransform
                if this.containerProvider()!=undefined and findItem sources n>0 do tm.row4=[0,0,0]
                format "%:%|" (getHandleByAnim n) tm to:stream
            )
            for n in #(analyzerNode,areaAnalyzer,fallAnalyzer) where isValidNode n do format "%|" (n.getAnalysisRuns()) to:stream
            format "%|%|%|%|%|%|%|%|%|" strokeSides strokeModes strokeColorRows strokeColorKeys strokeSourceRows strokeMin strokeMax strokeSourceIDs sourceRowIDs to:stream
            if diversityMode==3 do format "Bands2:%|%|%|%|%|%|%|%|%|%|" bandArrangement pathIDs pathJoins strokeIDs strokePathIDs strokeStarts strokeEnds strokeStrengths strokeCurveEnabled strokeCurveSamples to:stream
            if diversityMode==3 do format "BandScale:%|%|" strokeScaleModes strokeScaleSamples to:stream
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
            #movement: #(#(#movXMinWU,0.0),#(#movXMaxWU,0.0),#(#movYMinWU,0.0),#(#movYMaxWU,0.0),#(#movZMinWU,0.0),#(#movZMaxWU,0.0),#(#movementRange,0.0))
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
                if nextEditLayerKey<=layer.editLayerKey do nextEditLayerKey=layer.editLayerKey+1
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
        this.removeLogicalLayer leaf
    )
    local updateUI,surfaceUI,previewUI,layersUI,uiRootState=#(),uiPresentationState=#()

    -- One bounded map-only bake, independent of receiver geometry and selected UVs.
    -- A failed successor never replaces a complete sampled image.
    fn densityCacheStats = (#(procDensityBakes,procDensityHits,procDensityInversions,procDensityBakeMs,if procDensityCache.count==0 then 0 else procDensityCache[5].count+(if procDensityCache[6]==undefined then 0 else procDensityCache[6].count)))
    fn procDensityWeights = (
        if densityMap==undefined do throw "Choose a density texture map."
        if densityUVChannel<1 or densityUVChannel>99 do throw "Density UV channel must be 1..99."
        if findItem #(64,128,256,512) densityResolution==0 do throw "Density resolution must be 64, 128, 256 or 512."
        local revision=this.procWatchDensity(),tick=currentTime as integer,cached=procDensityCache
        local reusable=cached.count==6 and cached[1]==densityMap and cached[2]==revision and cached[3]==densityResolution
        if reusable do reusable=tick>=cached[4][1] and tick<=cached[4][2]
        if reusable then procDensityHits+=1
        else (
            local image=undefined,weights=#(),started=timeStamp(),interval=cyrusScatterInputValidity #() #() #(densityMap)
            try (
                image=renderMap densityMap size:[densityResolution,densityResolution]
                if image==undefined do throw "Density map could not be sampled."
                weights.count=densityResolution*densityResolution
                local index=1
                for y=0 to densityResolution-1 do for c in (getPixels image [0,y] densityResolution) do (
                    weights[index]=amin 1.0 (amax 0.0 ((c.r*0.2126+c.g*0.7152+c.b*0.0722)/255.0));index+=1
                )
                close image;image=undefined
            )catch(if image!=undefined do try(close image)catch();throw())
            cached=#(densityMap,revision,densityResolution,interval,weights,undefined)
            procDensityCache=cached;procDensityBakes+=1;procDensityBakeMs=timeStamp()-started
        )
        if not invertDensity do return cached[5]
        if cached[6]==undefined do (cached[6]=for weight in cached[5] collect (1-weight);procDensityInversions+=1)
        cached[6]
    )
    fn procWatchDensity = (
        global CyrusDensityMapChanged
        local watched=if distributionMode==3 then densityMap else undefined
        if procDensityMap!=watched do (
            if procDensityWatch!=undefined do deleteChangeHandler procDensityWatch
            procDensityWatch=undefined;procDensityMap=watched;procDensityRevision+=1;procDensityCache=#()
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
        members[i]=members[j];members[j]=item
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
        this.syncStrokes()
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
                append procRuleEnabled false;append procRuleMultiplier 1.0;append procRuleGapWU 0.0;append procRulePlanar false;i=procRuleA.count
            )
            procRuleEnabled[i]=enabled;procRuleMultiplier[i]=multiplier;procRuleGapWU[i]=gap;procRulePlanar[i]=planar
        )
        this.invalidateGroups()
    )
    fn procRemoveRule i = (
        if i>0 do for key in #(#procRuleScope,#procRuleA,#procRuleB,#procRuleEnabled,#procRuleMultiplier,#procRuleGapWU,#procRulePlanar) do deleteItem (getProperty this key) i
    )
    fn procRemoveOwner leaf = (
        for i=procRuleA.count to 1 by -1 where procRuleA[i]==leaf.layerID or procRuleB[i]==leaf.layerID do this.procRemoveRule i
    )
    fn procCopyRelations originals copies = (
        -- Remap references inside the copy; preserve external layer rules.
        (
            for s=1 to copies.count do (
                local leaf=copies[s]
                leaf.procRadiusIDs=#();leaf.procRadiusModes=#();leaf.procRadiusValues=#();leaf.procRadiusDistances=#();leaf.procRadiusBinding=""
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
                    if a!=undefined and b!=undefined do this.procSetPair procRuleScope[i] a b procRuleEnabled[i] procRuleMultiplier[i] procRuleGapWU[i] procRulePlanar[i]
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
    fn procAutoRequired i = (
        if not this.sourceUsesAuto i or this.sourceWeight i<=0 do return false
        if this.containerProvider()!=undefined and (i>containerActive.count or not containerActive[i]) do return false
        if diversityMode!=3 and diversityMode!=4 do return true
        this.syncStrokes()
        for band=1 to patternLines.count where isValidNode patternLines[band] do (
            local active=if diversityMode==3 then not isProperty patternLines[band] #samplePoints else patternLines[band]==analyzerNode
            if active and diversityMode==3 do active=(strokeStrengths[band]>0 and (amax (this.bandCurve band))>0 and (if bandArrangement==1 then patternWidths[band]>0 else strokeEnds[band]>strokeStarts[band]))
            if active do (
                if strokeModes[band]==1 then (
                    for k=1 to strokeColorRows.count where strokeColorRows[k]==band and strokeColorKeys[k]==colorKey(this.sourceColor i) do return true
                ) else (
                    for k=1 to strokeSourceRows.count where strokeSourceRows[k]==band and strokeSourceIDs[k]==sourceRowIDs[i] do return true
                )
            )
        )
        false
    )
    fn procRadiusGeometry plants rows:#() enabled:true = (
        -- Validate the whole active lottery before sampling, including missing
        -- original rows which validSources deliberately omits from transport.
        local required=for i=1 to sources.count collect (enabled and this.procAutoRequired i)
        for i=1 to required.count where required[i] and not this.sourceCanAuto i do throw ("Auto Radius: "+this.sourceLabel i+" is missing or has an unqualified source type. Restore supported geometry or choose Manual.")
        local used=#{}
        for row in rows do used[row[2]]=true
        local inputs=for k=1 to plants.count collect (
            local i=this.sourceRow plants[k]
            if used[k] or (i>0 and required[i]) then plants[k] else 0
        )
        local info=cyrusSourceGeometryInfo inputs
        for k=1 to plants.count do (
            local i=this.sourceRow plants[k]
            if this.sourceUsesAuto i and (used[k] or required[i]) do (
                if info[k][1]!=1 or not info[k][6] do throw ("Auto Radius: "+this.sourceLabel i+". "+info[k][7]+". The previous result is retained; repair the source or choose Manual.")
            )
        )
        info
    )
    fn procRadii rows plants geometry:undefined = (
        if geometry==undefined do geometry=this.procRadiusGeometry plants rows:rows
        if procRadiusIDs.count>0 do (
            if procRadiusBinding=="" do throw "Radius overrides have no generation binding. Explicitly clear them before updating."
            cyrusReceiverMergeBinding procRadiusBinding procBindingKey
        )
        local specs=if plants.count==0 then #(#(1,0.0,false,[0,0,0],[0,0,0])) else for k=1 to plants.count collect (
            local i=this.sourceRow plants[k],info=geometry[k]
            #(if this.sourceUsesAuto i and info[1]==1 then 2 else 1,this.sourceRadius i,this.sourceFollows i,info[4],info[5])
        )
        if procRadiusDistances.count!=procRadiusIDs.count do throw "Instance distance metadata is incomplete."
        local values=for i=1 to procRadiusIDs.count collect (if procRadiusModes[i]==1 then procRadiusDistances[i] else procRadiusValues[i])
        cyrusProceduralRadii rows specs (procRadiusIDs as array) (procRadiusModes as array) values
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
            if reset then (if i>0 do (deleteItem procRadiusIDs i;deleteItem procRadiusModes i;deleteItem procRadiusValues i;deleteItem procRadiusDistances i))
            else (
                if i==0 do (append procRadiusIDs id;append procRadiusModes mode;append procRadiusValues 1.0;append procRadiusDistances 0.0;i=procRadiusIDs.count)
                procRadiusModes[i]=mode
                if mode==1 then procRadiusDistances[i]=value else procRadiusValues[i]=value
            )
        )
        procRadiusBinding=if procRadiusIDs.count>0 then cyrusReceiverMergeBinding procRadiusBinding procBindingKey else ""
        )
        overlapOwner.invalidateGroups()
    )
    fn procClearRadii = (
        undo "Cyrus clear set radius overrides" on (procRadiusIDs=#();procRadiusModes=#();procRadiusValues=#();procRadiusDistances=#();procRadiusBinding="")
        if overlapOwner!=undefined do overlapOwner.invalidateGroups()
    )
    fn procCoverageKey = (
        local stream=stringStream ""
        format "%:%:%|" (this.paintKey()) paintEnabled paintDensity to:stream
        for area in paintAreas do format "Area:%:%:%:%:%|" area.layerID area.areaTarget area.paintSetEnabled area.paintDensity (area.paintKey()) to:stream
        stream as string
    )
    fn procApplyPaint rows = (
        if not paintEnabled or rows.count==0 do return cyrusClonePlacementRows rows
        local docs=#(),densities=#(),targets=this.validSurfaces()
        for area in paintAreas where area.paintSetEnabled and area.paintDocument!=undefined and findItem targets area.areaTarget>0 do (
            if cyrusBrushTarget area.paintDocument!=area.areaTarget do throw "Paint Area target mismatch; saved vector borders are preserved."
            append docs area.paintDocument;append densities area.paintDensity
        )
        cyrusBrushRegionFilter rows docs densities targets paintBaseFaceCounts ("CyrusStableMask1:"+(this.effectiveSeed() as string))
    )
    fn procBinding plants rows = (
        local stream=stringStream ""
        with printAllElements on (
            format "CyrusBinding2:%|" (this.effectiveSeed()) to:stream
            for n in plants do (local i=sourceRow n;format "%|" (if i>0 and i<=procSourceSlots.count then procSourceSlots[i] else "preview") to:stream)
            for key in #(#distributionMode,#diversityMode,#diversitySize,#diversitySeed,#roughness,#blurryEdge,#diversityNoise,#sourceWeights,#sourceColors,#sourceEmpty,#sourcePoint,#sourceScales,#sourceZOffsetsWU,#advancedAxes,#scaleMinimum,#scaleMaximum,#tiltDegrees,#yawMinimum,#yawMaximum,#movementRange,#sclXMin,#sclXMax,#sclYMin,#sclYMax,#sclZMin,#sclZMax,#rotXMin,#rotXMax,#rotYMin,#rotYMax,#rotZMin,#rotZMax,#movXMinWU,#movXMaxWU,#movYMinWU,#movYMaxWU,#movZMinWU,#movZMaxWU,#wholeScaleMin,#wholeScaleMax,#projectMove,#alignNormal) do format "%:%|" key (getProperty this key) to:stream
            if diversityMode>=3 do for key in #(#patternLines,#patternWidths,#strokeSides,#strokeModes,#strokeColorRows,#strokeColorKeys,#strokeSourceRows,#strokeSourceIDs,#sourceRowIDs,#pathIDs,#pathJoins,#strokeIDs,#strokePathIDs,#bandArrangement,#strokeStarts,#strokeEnds,#strokeStrengths,#strokeCurveEnabled,#strokeScaleModes,#strokeScaleSamples,#strokeCurveSamples,#strokeMin,#strokeMax,#analyzerNode,#edgeOffsetsWU,#edgeAlongWU,#edgeAcrossWU,#edgeKeepCorners,#edgeCornerAngle,#edgeCornerCount,#edgeFaceOut,#edgeCornerRadius,#edgeRotX,#edgeRotY,#edgeRotZ,#borderFaceOut,#streetFaceOut,#borderCornerRadius,#streetCornerRadius,#streetStraight,#streetTrimStart,#streetTrimEnd,#centerStreetOffset) do format "%:%|" key (getProperty this key) to:stream
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
            append procReceiverGeometry #(slot,(cyrusProceduralSurfaceKey #(node) (distributionMode==3) densityUVChannel),(if meshMaskEnabled then cyrusMeshDensityKey node (this.meshMaskPayload()) else "off"))
        )
        procReceiverPlanData=cyrusReceiverPlan inputs allocation[1] (if parent.populationMode==2 then allocation[2]/(meters*meters) else -1.0) (if parent.procPopulation==2 then parent.procAttemptFactor else 1) ((overlapOwner.populationAllocation this countOverride:1000000)[1])
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
        for n in nodes where isValidNode n and n.collectEnabled do (
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
        this.ensureSourceRows()
        if findItem sources node>0 do return false
        if sources.count>=1024 do throw "Source registration is full (1,024 rows). Remove unused rows explicitly."
        -- Fill optional tabs before appending so a new source cannot inherit
        -- a prior row's sparse setting. Automatic registration survives parking.
        undo off (
            syncColors()
            for spec in #(#(#sourceWeights,1.0),#(#sourceZOffsetsWU,0.0),#(#sourceScales,1.0),#(#sourceForwardAxes,1),#(#sourceRadiiWU,0.0),#(#sourceAutoRadius,false),#(#sourceFollowScale,false),#(#sourceShowRadius,false),#(#sourcePoint,false),#(#sourceEmpty,false)) do (
                local values=getProperty this spec[1]
                while values.count<sources.count do append values spec[2]
                append values spec[2]
            )
            append sources node;append sourceRowIDs (CyrusNewLayerID());append sourceColors (this.sourceColor sources.count)
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
                    #(n,n.objectTransform,n.width,n.length,n.modifiers.count,if isProperty n #cornerRadius then n.cornerRadius else 0,n.collectEnabled)
                ) else #(undefined)
            )
            local configurationChanged=containerConfigKey=="" or state.count!=containerFrameState.count
            if not configurationChanged do for i=1 to state.count while not configurationChanged do (
                if state[i].count!=containerFrameState[i].count then configurationChanged=true
                else for j=1 to state[i].count where state[i][j]!=containerFrameState[i][j] do configurationChanged=true
            )
            if configurationChanged do (containerScan=true;containerCachedFrames=this.containerFrames())
            local frames=containerCachedFrames
            local candidates=if frames.count==0 then #() else if containerScan then (geometry as array) else containerPending as array
            if containerScan and frames.count>0 do containerScans+=1
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
                containerActive=for i=1 to sources.count collect (this.isEmptySource i or this.containerContains sources[i] frames)
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
    fn procStageDependencyHandles = (
        local inputs=this.validSurfaces(),handles=#()
        join inputs (sources as array);join inputs (areaNodes as array);join inputs (patternLines as array)
        join inputs #(analyzerNode,areaAnalyzer,fallAnalyzer)
        for input in inputs where isValidNode input do (
            local dep=input
            while isValidNode dep do (
                local handle=getHandleByAnim dep
                if findItem handles handle>0 then exit
                append handles handle;dep=dep.parent
            )
        )
        handles
    )
    fn procExternalChanged event nodes deletedHandles:undefined = (
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
        if event==#deleted do (
            -- Direct callers without the original handles remain conservative.
            -- New/pending dependencies are already dirty; published dependencies
            -- survive failed successors until a complete replacement commits.
            if deletedHandles==undefined then affected=true
            else for handle in deletedHandles while not affected do if findItem procDependencyHandles handle>0 do affected=true
        )
        if affected do (CyrusClearMeshMaskPreview this;procGeometryRevision+=1;markInputDirty())
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
        node
    )

    fn procInputKey = (
        local stream=stringStream ""
        with printAllElements on (
            format "Proc1:%:%:%:%:%:%:%:%|" (this.inputTimeKey()) 0 procManualRevision cyrusEnabled layerEnabled (this.procEditKey()) procRuleScope procRuleA to:stream
            format "%:%:%:%:%|" procRuleB procRuleEnabled procRuleMultiplier procRuleGapWU procRulePlanar to:stream
            for parent in this.logicalLayers() do for leaf in this.layerSets parent do (
                leaf.containerRefresh()
                format "Membership:%|Filter:%|" leaf.containerMembershipKey (leaf.surfaceFilterKey()) to:stream
                format "Texture:%|" (leaf.procWatchDensity()) to:stream
                format "%:%:%:%:%:%|" leaf.layerID leaf.logicalParentID leaf.procReceiverID leaf.procRadiusBinding (leaf.paintBaseInputKey (leaf.validSources()) true) (leaf.procCoverageKey()) to:stream
                for key in #(#procOrder,#procSetOrder,#procSamplingSalt,#procPopulation,#procAttemptFactor,#procRounds,#procRepair,#procSelfOverride,#procSelfEnabled,#procSelfMultiplier,#procSelfGap,#procSelfPlanar,#procLayerSelfEnabled,#procLayerSelfMultiplier,#procLayerSelfGap,#procLayerSelfPlanar,#procSiblingEnabled,#procSiblingMultiplier,#procSiblingGap,#procSiblingPlanar,#procRadiusIDs,#procRadiusModes,#procRadiusValues,#procRadiusDistances,#procSourceIDs,#sourceRadiiWU,#sourceAutoRadius,#sourceFollowScale,#finalCleanup,#finalNeighborRadius,#finalMinNeighbors,#finalMinIsland,#cleanupPlanar) do format "%:%|" key (getProperty leaf key) to:stream
            )
        )
        stream as string
    )
    fn procQuota = (
        local parent=overlapOwner.logicalParent this,budget=parent.amount
        if parent.populationMode==2 do (
            local meters=units.decodeValue "1m",wanted=(aminScatterSurfaceArea (this.validSurfaces()))/(meters*meters)*parent.plantsPerM2
            densityCapped=wanted>1000000;budget=(amin 1000000 (floor(wanted+0.5))) as integer
        )
        (overlapOwner.populationAllocation this countOverride:budget)[1]
    )
    fn procPrepare pool plants = (
        local key=(this.paintBaseInputKey plants true)+"|Texture:"+(this.procWatchDensity() as string)+"|Pool:"+(pool as string)+"|"+(this.procCoverageKey())+"|"+(overlapOwner.procEditKey())+"|Filter:"+(this.surfaceFilterKey())
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
        rows=this.applySurfaceFilter rows
        procPreparedRows=rows;procPreparedKey=key;procPreparedBuilds+=1
        rows
    )
    fn procAssertSchema = (
        local message="This development scene does not use the current schema 58. Create a new Cyrus 0.82.4 setup; earlier schemas are unsupported."
        if not procSchemaValid do throw message
        for leaf in layerObjects where not leaf.procSchemaValid do throw message
        true
    )
    fn procValidate = (
        this.procAssertSchema()
        if cyrusMeshDensityVersion==undefined or cyrusMeshDensityVersion()!=1 or cyrusBrushConversionVersion==undefined or cyrusBrushConversionVersion()!=1 or cyrusDensityMapVersion==undefined or cyrusDensityMapVersion()!=1 or cyrusSurfaceFilterVersion==undefined or cyrusSurfaceFilterVersion()!=1 or cyrusPresetVersion==undefined or cyrusPresetVersion()!=1 or cyrusSplineBandVersion==undefined or cyrusSplineBandVersion()!=10 or cyrusEvaluateProcedural==undefined or cyrusEditTransaction==undefined or cyrusProceduralPublicationVersion==undefined or cyrusProceduralPublicationVersion()!=2 or cyrusBuildInspectionPreview==undefined or cyrusBuildFieldPreview==undefined or cyrusFieldDependencyKey==undefined or cyrusRecolorPreview==undefined or cyrusPreviewPlacementsEqual==undefined or cyrusPreviewRadiiEqual==undefined or cyrusViewportPolicyVersion==undefined or cyrusViewportPolicyVersion()!=2 or cyrusViewportPointCapacity==undefined do throw "Cyrus 0.82.4 requires the matching native plugin binaries. Restart Max with the complete matching script/native pair."
        if layerObjects.count>10 do throw "A setup supports ten total populations."
        for parent in this.logicalLayers() do (
            if parent.procPopulation<1 or parent.procPopulation>2 or parent.procAttemptFactor<1 or parent.procAttemptFactor>32 or parent.procRounds<1 or parent.procRounds>16 do throw "Invalid procedural work limits."
            for leaf in this.layerSets parent where this.enabledLayer (findItem layerObjects leaf) do (
                if cyrusEnabled do (leaf.requireCurrentAnalyzers();cyrusValidateSurfaceFilter (leaf.surfaceFilterPayload());cyrusValidateMeshDensity (leaf.meshMaskPayload()))
                if parent.procPopulation==2 and leaf.diversityMode==3 do (
                    leaf.syncStrokes()
                    if leaf.bandArrangement==2 do throw "Independent Bands require Candidate budget. Accepted target would refill their density."
                    for i=1 to leaf.strokeIDs.count do (
                        if leaf.strokeStrengths[i]!=1.0 do throw "Band density requires Candidate budget. Accepted target would refill its density."
                        for value in (leaf.bandCurve i) where value!=1.0 do throw "Band density curves require Candidate budget."
                    )
                )
                if parent.procPopulation==2 do for source in leaf.validSources() do (
                    local index=leaf.sourceRow source
                    if leaf.isEmptySource index and not leaf.isPointSource index and leaf.sourceWeight index>0 do throw "Accepted target does not refill weighted Empty assets. Use candidate budget, Point placeholders, or remove the Empty weight."
                )
            )
        )
        true
    )
    local procPreviewDisplayKey="",procPreviewGeometryKey="",procPreviewInspectionKey=""
    -- One current-publication CPU snapshot per representation (points, centres,
    -- Mesh, and each proxy shape). Warm switching must not duplicate snapshots
    -- that MAXScript would otherwise retain until its next garbage collection.
    local procPreviewModes=#(),procPreviewModesEpoch=-1
    fn procDisplayGeometryKey leaf epoch:undefined = (
        local stream=stringStream ""
        with printAllElements on (
            format "Geometry:%:%|" (if epoch==undefined then procEpoch else epoch) leaf.layerID to:stream
            format "%:%|" leaf.viewportMode leaf.showCenters to:stream
            if leaf.viewportMode==1 then format "%:%|" leaf.previewBudget leaf.pointsPerPlant to:stream
            else if leaf.viewportMode==2 do format "%:%|" leaf.proxyShape (viewportPreparationLimit leaf.viewportInstances leaf.viewportNavigationInstances) to:stream
            -- Mesh retains source geometry independently of draw limits. Changing
            -- either phase must not duplicate the complete CPU source snapshot.
        )
        stream as string
    )
    fn procDisplayLayerKey leaf epoch:undefined = (
        local stream=stringStream ""
        with printAllElements on (
            format "Display:%:%|" (if epoch==undefined then procEpoch else epoch) identificationMode to:stream
            format "%:%:%|" leaf.layerID (for i=1 to leaf.sources.count collect leaf.sourceIDColor i) (this.logicalParent leaf).layerIDColor to:stream
            format "%:%|" leaf.strokeIDs leaf.strokeDisplayColors to:stream
            format "Field:%:%:%:%:%:%|" leaf.fieldFalloff leaf.fieldBoundaries leaf.fieldCombined leaf.fieldSamples (leaf.fieldSelectedID()) (if leaf.fieldPreviewEnabled() then leaf.procFieldInputKey() else "") to:stream
            for key in #(#viewportMode,#proxyShape,#viewportInstances,#viewportFaces,#viewportNavigationInstances,#viewportNavigationFaces,#previewBudget,#showCenters,#pointsPerPlant,#pointColorMode,#solidPointColor,#sourceShowRadius,#radiusDisplayLimit,#radiusDisplayAll,#radiusDisplayMetric) do format "%:%|" key (getProperty leaf key) to:stream
        )
        stream as string
    )
    fn procDisplayInputKey epoch:undefined = (
        local stream=stringStream ""
        for leaf in layerObjects do format "%|" (this.procDisplayLayerKey leaf epoch:epoch) to:stream
        stream as string
    )
    fn procPreviewMetadata plants geometry:undefined = (
        local sourceEntries=for n in plants collect (
            local row=this.sourceRow n
            if row<1 or row>sourceRowIDs.count do throw "Preview source correspondence is missing."
            #(sourceRowIDs[row],this.sourceIDColor row)
        )
        local bands=if diversityMode==3 then (for i=1 to strokeIDs.count collect #(strokeIDs[i],strokeDisplayColors[i],this.bandName i,strokePathIDs[i])) else #()
        #(sourceEntries,bands,diversityMode==3,(if geometry==undefined then cyrusSourceGeometryInfo plants else geometry),(this.procFieldInputKey()),randomSeed)
    )
    fn procPreviewPalette metadata = (
        local controller=if overlapOwner==undefined then this else overlapOwner,parent=controller.logicalParent this
        local colors=for entry in metadata[1] collect (
            local row=findItem sourceRowIDs entry[1]
            if controller.identificationMode==2 then parent.layerIDColor else if row>0 then this.sourceIDColor row else entry[2]
        )
        local bands=for entry in metadata[2] collect (
            local row=findItem strokeIDs entry[1]
            #(entry[1],if row>0 then strokeDisplayColors[row] else entry[2])
        )
        #(1,controller.identificationMode,colors,bands,metadata[3])
    )
    fn procRefreshPreviewMetadata metadata = (
        local result=deepCopy metadata
        for entry in result[1] do (local row=findItem sourceRowIDs entry[1];if row>0 do entry[2]=this.sourceIDColor row)
        for entry in result[2] do (local row=findItem strokeIDs entry[1];if row>0 do entry[2]=strokeDisplayColors[row])
        result
    )
    fn procCheckPublishedGeometry plants metadata = (
        local previous=metadata[4]
        local current=cyrusSourceGeometryInfo (for i=1 to plants.count collect (if i<=previous.count and previous[i][1]!=0 then plants[i] else 0))
        if current.count!=previous.count do throw "Source correspondence changed. Use Update before changing the display mode."
        for i=1 to current.count do for field=1 to 3 where current[i][field]!=previous[i][field] do throw "Source geometry is pending. Use Update before changing to an uncached display representation. The complete previous preview is retained."
        true
    )
    fn procPublishedPreviewMatches leaf data plants metadata = (
        local slot=findItem procPublishedOwners leaf
        if slot==0 do return false
        local previous=procPublishedMetadata[slot],oldPlants=procPublishedSources[slot]
        if plants.count!=oldPlants.count or metadata[1].count!=previous[1].count or metadata[2].count!=previous[2].count or metadata[3]!=previous[3] or metadata[4].count!=previous[4].count do return false
        -- Geometry uses source correspondence and the sorted Band dictionary;
        -- colors/names remain independently replaceable palette metadata.
        for i=1 to plants.count do (
            if plants[i]!=oldPlants[i] or metadata[1][i][1]!=previous[1][i][1] do return false
            for field=1 to 3 where metadata[4][i][field]!=previous[4][i][field] do return false
        )
        local bands=sort (for entry in metadata[2] collect entry[1]),oldBands=sort (for entry in previous[2] collect entry[1])
        for i=1 to bands.count where bands[i]!=oldBands[i] do return false
        if leaf.viewportMode==1 and not leaf.showCenters and metadata[6]!=previous[6] do return false
        cyrusPreviewPlacementsEqual data groupSnapshotRows[slot]
    )
    fn procInspectionKey plants fieldKey epoch = (
        local stream=stringStream ""
        with printAllElements on format "%:%:%:%:%:%:%|%" epoch sourceShowRadius radiusDisplayLimit radiusDisplayAll radiusDisplayMetric (for i=1 to sources.count collect this.sourceColor i) plants fieldKey to:stream
        stream as string
    )
    fn procStagePreview data plants:undefined placementRadiusValues:undefined displayEpoch:undefined metadata:undefined = (
        local start=timeStamp(),previousRadius=radiusPreview,radii
        if plants==undefined do plants=this.validSources()
        if metadata==undefined do metadata=this.procPreviewMetadata plants
        metadata=this.procRefreshPreviewMetadata metadata
        local controller=if overlapOwner==undefined then this else overlapOwner
        local geometryKey=controller.procDisplayGeometryKey this epoch:displayEpoch,palette=this.procPreviewPalette metadata
        local geometryEpoch=if displayEpoch==undefined then controller.procEpoch else displayEpoch
        local modeSlot=if viewportMode==2 then proxyShape+4 else if viewportMode==1 and showCenters then 4 else viewportMode
        local cache=cachedPoints
        local reuseGeometry=cache!=undefined and procPreviewGeometryKey==geometryKey
        if not reuseGeometry and procPreviewModesEpoch==geometryEpoch do (
            for entry in procPreviewModes where entry[1]==modeSlot and entry[2]==geometryKey do (cache=entry[3];reuseGeometry=true)
        )
        -- A new publication may share an unchanged layer's immutable buffers.
        -- Compare against the committed owner, never pending/prepared rows; do
        -- not change any cache key or owner until the normal atomic install.
        if cache!=undefined and not reuseGeometry and displayEpoch!=undefined and procPreviewGeometryKey==(controller.procDisplayGeometryKey this) do reuseGeometry=controller.procPublishedPreviewMatches this data plants metadata
        if reuseGeometry then cache=cyrusRecolorPreview cache palette
        else (
            -- An inspection-only change never reads pending source geometry.
            -- A new Mesh/Point Cloud representation still verifies its epoch.
            if displayEpoch==undefined and data.count>0 and (viewportMode!=1 or not showCenters) do this.procCheckPublishedGeometry plants metadata
            local used=#{}
            for row in data do used[row[2]]=true
            local samples=if viewportMode!=1 then #() else if showCenters then (for i=1 to (amax 1 plants.count) collect #([0,0,0])) else (for i=1 to plants.count collect (if not used[i] or classof plants[i]==Integer then (for p=1 to pointsPerPlant collect [0,0,0]) else pointSourceSamples plants[i] sampleSeed:metadata[6]))
            cache=if viewportMode==1 or data.count==0 then aminScatterBuildPreview data (if data.count==0 then for n in plants collect #([0,0,0]) else samples) palette previewBudget else cyrusBuildGeometryPreview data plants palette (if viewportMode==2 then proxyShape else 4) (if viewportMode==2 then viewportPreparationLimit viewportInstances viewportNavigationInstances else 0) 0
        )
        local field=this.procStageField metadata[5],inspection=inspectionCache
        local inspectionKey=this.procInspectionKey plants field[2] (if displayEpoch==undefined then controller.procEpoch else displayEpoch)
        local reuseInspection=procPreviewInspectionKey==inspectionKey
        if not reuseInspection and reuseGeometry and displayEpoch!=undefined and placementRadiusValues!=undefined and procPreviewInspectionKey==(this.procInspectionKey plants field[2] controller.procEpoch) do (
            local slot=findItem controller.procPublishedOwners this
            if slot>0 do reuseInspection=cyrusPreviewRadiiEqual placementRadiusValues controller.procPublishedRadii[slot]
        )
        if reuseInspection then radii=radiusPreview
        else (
            try(cacheRadii data plants values:placementRadiusValues;radii=radiusPreview;radiusPreview=previousRadius)catch(radiusPreview=previousRadius;throw())
            inspection=if radii.count==0 and field[1]==undefined then undefined else cyrusBuildInspectionPreview radii field[1]
        )
        #(cache,(aminScatterPreviewCount cache),data.count,radii,(if viewportMode==1 and showCenters then 4 else viewportMode),timeStamp()-start,(if isValidNode areaAnalyzer then areaAnalyzer.getAnalysisRuns() else -1),(if isValidNode fallAnalyzer then fallAnalyzer.getAnalysisRuns() else -1),inspection,(controller.procDisplayLayerKey this epoch:displayEpoch),(if isValidNode analyzerNode then analyzerNode.getAnalysisRuns() else -1),inputTimeStamp,geometryKey,metadata,inspectionKey,field[1],field[2],field[3],geometryEpoch,modeSlot)
    )
    -- Publication snapshots retain references to immutable staged rows/caches.
    -- No host queries or copies of large point arrays run in the install tail.
    fn procPreviewState = (#(inputTimeObserved,cachedPoints,cachedPointCount,generatedCount,radiusPreview,uiPreviewMode,inspectionCache,procPreviewDisplayKey,previewBuildMs,cachedAreaAnalyzerRun,cachedFallRun,cachedAnalyzerRun,previewBuildCount,previewError,dirty,procPreviewGeometryKey,procPreviewInspectionKey,procFieldCache,procFieldCacheKey,procFieldStatus,procPreviewModes,procPreviewModesEpoch))
    fn procReleaseRetiredDisplay = (
        -- Max can retain detached scripted objects after scene reset. These
        -- transient resources belong to the departed scene, not its saved data.
        cachedPoints=undefined;inspectionCache=undefined;cachedDisabledPreview=undefined
        procPreviewModes=#();procPreviewModesEpoch=-1
        procSplineField=undefined;procPreparedRows=#();radiusPreview=#();procFieldCache=undefined;procFieldCacheKey="";procFieldStatus="Preview hidden.";procPreviewInspectionKey=""
        procPreviewDisplayKey="";procPreviewGeometryKey="";procPublishedDisplayKey=""
        true
    )
    fn procRestorePreview state = (
        inputTimeObserved=state[1];cachedPoints=state[2];cachedPointCount=state[3];generatedCount=state[4];radiusPreview=state[5]
        uiPreviewMode=state[6];inspectionCache=state[7];procPreviewDisplayKey=state[8];previewBuildMs=state[9]
        cachedAreaAnalyzerRun=state[10];cachedFallRun=state[11];cachedAnalyzerRun=state[12];previewBuildCount=state[13];previewError=state[14];dirty=state[15]
        procPreviewGeometryKey=state[16]
        procPreviewInspectionKey=state[17];procFieldCache=state[18];procFieldCacheKey=state[19];procFieldStatus=state[20]
        procPreviewModes=state[21];procPreviewModesEpoch=state[22]
    )
    fn procResultState = (#(this.procPreviewState(),procLastStats,procLastRounds,procEpoch,requestedCount,groupEligible,groupRemoved,groupConflicts,overlapBefore,overlapAfter,procLastSurfaceStats,procDependencyHandles))
    fn procRestoreResult state = (
        this.procRestorePreview state[1];procLastStats=state[2];procLastRounds=state[3];procEpoch=state[4];requestedCount=state[5]
        groupEligible=state[6];groupRemoved=state[7];groupConflicts=state[8];overlapBefore=state[9];overlapAfter=state[10];procLastSurfaceStats=state[11]
        procDependencyHandles=state[12]
    )
    fn procInstallPreview state pending = (
        inputTimeObserved=state[12]
        cachedPoints=state[1];cachedPointCount=state[2];generatedCount=state[3];radiusPreview=state[4];uiPreviewMode=state[5];inspectionCache=state[9]
        procPreviewDisplayKey=state[10]
        procPreviewGeometryKey=state[13]
        procPreviewInspectionKey=state[15];procFieldCache=state[16];procFieldCacheKey=state[17];procFieldStatus=state[18]
        CyrusViewportRecordsDirty=true
        previewBuildMs=state[6];cachedAreaAnalyzerRun=state[7];cachedFallRun=state[8]
        cachedAnalyzerRun=state[11]
        local modes=if procPreviewModesEpoch==state[19] then (for entry in procPreviewModes where entry[1]!=state[20] collect entry) else #()
        append modes #(state[20],state[13],state[1])
        procPreviewModes=modes;procPreviewModesEpoch=state[19]
        previewBuildCount+=1;previewError="";dirty=pending
    )
    fn procEnsureDisplay pending:false = (
        local key=this.procDisplayInputKey()
        if key!=procPublishedDisplayKey do (
            local before=for leaf in layerObjects collect leaf.procPreviewState(),previousKey=procPublishedDisplayKey,previousDirty=CyrusViewportRecordsDirty,previousMetadata=procPublishedMetadata
            local nextMetadata=procPublishedMetadata as array
            -- Pending Manual topology can differ from the last publication.
            -- Resolve by owner, including an empty preview for unpublished layers.
            local stage=for leaf in layerObjects collect (
                if leaf.procPreviewDisplayKey==(this.procDisplayLayerKey leaf) then undefined
                else (
                    local slot=findItem procPublishedOwners leaf
                    -- An unpublished layer has no published owner dictionary.
                    -- Pending authoring/copy callbacks may change its Bands
                    -- while this empty cache remains at the same epoch.
                    if slot==0 then leaf.procStagePreview #() plants:#() placementRadiusValues:#() metadata:#(#(),#(),false,#(),"",leaf.randomSeed)
                    else leaf.procStagePreview groupSnapshotRows[slot] plants:procPublishedSources[slot] placementRadiusValues:procPublishedRadii[slot] metadata:procPublishedMetadata[slot]
                )
            )
            for i=1 to layerObjects.count where stage[i]!=undefined do (
                local slot=findItem procPublishedOwners layerObjects[i]
                if slot>0 do nextMetadata[slot]=stage[i][14]
            )
            -- Preserve atomic failure retention: stage every changed layer
            -- before installing any successor. Unchanged snapshots stay shared.
            try (
                for i=1 to layerObjects.count where stage[i]!=undefined do layerObjects[i].procInstallPreview stage[i] pending
                -- Recovery also clears failure status on reused siblings.
                for i=1 to layerObjects.count where stage[i]==undefined do (
                    layerObjects[i].previewError="";layerObjects[i].dirty=pending
                )
                procPublishedDisplayKey=key
                procPublishedMetadata=nextMetadata
            ) catch (
                local failure=getCurrentException()
                for i=1 to layerObjects.count do layerObjects[i].procRestorePreview before[i]
                procPublishedDisplayKey=previousKey;CyrusViewportRecordsDirty=previousDirty
                procPublishedMetadata=previousMetadata
                throw()
            )
            try(CyrusScheduleUI())catch()
        )
    )
    fn procRefreshPreview = (
        local root=overlapOwner,displayPhase=false
        try (
            local evaluated=root.groupSnapshotKey=="" or (not root.groupDisplayOnly and (root.updateMode==2 or root.procExplicitUpdate))
            if evaluated do root.evaluateProcedural()
            -- A successful evaluation has just checked/published this complete
            -- recipe. Only an unevaluated Manual recipe needs a pending check.
            local pending=not evaluated and root.groupSnapshotKey!=root.procInputKey()
            displayPhase=true
            root.procEnsureDisplay pending:pending
            if root.procDisplayFailure do (for leaf in root.layerObjects do leaf.previewError="";root.procDisplayFailure=false)
            for leaf in root.layerObjects do leaf.dirty=pending
            cachedPointCount
        ) catch (
            -- A failed successor cannot erase the preceding complete viewport.
            local failure=getCurrentException()
            root.procDisplayFailure=displayPhase
            for leaf in root.layerObjects do (leaf.previewError=failure;leaf.dirty=false)
            cachedPointCount
        )
    )
    fn evaluateProcedural = (
        this.procAssertSchema()
        if groupSolving do throw "Recursive procedural evaluation."
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
            if pool>1000000 do throw "This population requires more than 1,000,000 candidates, including protected edits. Reduce its Amount or retry budget."
            requests[i]=#(quota,attempts,pool);admission+=pool
        )
        if admission>1000000 do throw ("This Scatter requests "+(admission as string)+" candidates across its layers; the total limit is 1,000,000 including retries. Reduce Amount or retry limits. The previous result is retained.")
        for i=1 to layerObjects.count where cyrusEnabled and this.enabledLayer i do layerObjects[i].procRadiusGeometry (layerObjects[i].validSources())
        local publishedMetadata=for leaf in layerObjects collect undefined
        local transaction=false,previousBindings=for leaf in layerObjects collect leaf.procBindingKey
        local previousResults=for leaf in layerObjects collect leaf.procResultState()
        local previousPublication=#(procEpoch,procPublishedOwners,procPublishedSources,procPublishedFinalKeep,procPublishedRadii,procPublishedInfo,groupSnapshotRows,groupSnapshotKey,procPublishedDisplayKey,groupBuilds,CyrusViewportRecordsDirty,procPublishedMetadata)
        groupSolving=true
        try (
            cyrusEditTransaction mods 0;transaction=true
            for parent in parents do (
                local members=this.layerSets parent,sets=#(),indices=#()
                for leaf in members do (
                    local i=findItem layerObjects leaf,request=requests[i],plants=leaf.validSources(),rows=#()
                    if cyrusEnabled and this.enabledLayer i do rows=leaf.containerFilter (leaf.procPrepare request[3] plants) plants
                    local geometry=leaf.procRadiusGeometry plants rows:rows enabled:(cyrusEnabled and this.enabledLayer i)
                    publishedMetadata[i]=leaf.procPreviewMetadata plants geometry:geometry
                    append sets #(leaf.layerID,rows,(leaf.procRadii rows plants geometry:geometry),(leaf.procSelfRule()),request[1],request[2],(if cyrusEnabled and this.enabledLayer i then leaf.procReceiverPlanData[2] else #()))
                    append indices i
                )
                append layers #(parent.layerID,parent.procPopulation==2,parent.procRepair,parent.procRounds,#(parent.procSiblingEnabled,parent.procSiblingMultiplier,parent.procSiblingGap,parent.procSiblingPlanar),#(parent.finalCleanup,parent.finalNeighborRadius,parent.finalMinNeighbors,parent.finalMinIsland,parent.cleanupPlanar),sets)
                append mapping indices
            )
            local pairs=for i=1 to procRuleA.count collect #(procRuleScope[i],procRuleA[i],procRuleB[i],#(procRuleEnabled[i],procRuleMultiplier[i],procRuleGapWU[i],procRulePlanar[i]))
            local resolved=cyrusEvaluateProcedural layers pairs 1000000
            local accepted=for leaf in layerObjects collect #(),stats=for leaf in layerObjects collect #(),rounds=for leaf in layerObjects collect #(),radii=for leaf in layerObjects collect #()
            for l=1 to mapping.count do for s=1 to mapping[l].count do (
                local i=mapping[l][s]
                accepted[i]=resolved[1][l][s];stats[i]=resolved[2][l][s];rounds[i]=resolved[3][l]
                radii[i]=resolved[4][l][s]
            )
            local display=for i=1 to layerObjects.count collect layerObjects[i].procStagePreview accepted[i] placementRadiusValues:radii[i] displayEpoch:(procEpoch+1) metadata:publishedMetadata[i]
            local displayKey=this.procDisplayInputKey epoch:(procEpoch+1)
            local publishedOwners=layerObjects as array,publishedSources=for leaf in layerObjects collect leaf.validSources()
            local finalKeep=for i=1 to layerObjects.count collect (for n in publishedSources[i] collect not (layerObjects[i].isPointSource (layerObjects[i].sourceRow n)))
            local publicationInfo=this.procStagePublication accepted requests publishedSources finalKeep
            local dependencyHandles=for leaf in layerObjects collect leaf.procStageDependencyHandles()
            -- Allocation and computation have finished; publish one coherent epoch.
            this.publishGroupEdits accepted
            this.procSyncEditVisibility()
            local finishedKey=this.procInputKey()
            procEpoch+=1
            for i=1 to layerObjects.count do (
                local leaf=layerObjects[i]
                leaf.procLastStats=stats[i];leaf.procLastRounds=rounds[i];leaf.procEpoch=procEpoch
                leaf.procDependencyHandles=dependencyHandles[i]
                leaf.procLastSurfaceStats=if cyrusEnabled and this.enabledLayer i then leaf.procPreparedSurfaceStats as array else #(0,0,0)
                leaf.requestedCount=requests[i][1]
                -- Unconsumed refill capacity is not a rejected plant.
                leaf.setGroupResult (stats[i][1]-stats[i][9]) stats[i][2] stats[i][4]
                leaf.procInstallPreview display[i] false
            )
            procPublishedOwners=publishedOwners;procPublishedSources=publishedSources;procPublishedFinalKeep=finalKeep
            procPublishedRadii=radii;procPublishedInfo=publicationInfo
            procPublishedMetadata=publishedMetadata
            groupSnapshotRows=accepted;groupSnapshotKey=finishedKey;procPublishedDisplayKey=displayKey;groupBuilds+=1
            -- Keep native Edit rollback alive until every script owner agrees.
            cyrusEditTransaction mods 1;transaction=false
        ) catch (
            local failure=getCurrentException()
            for i=1 to layerObjects.count do layerObjects[i].procRestoreResult previousResults[i]
            procEpoch=previousPublication[1];procPublishedOwners=previousPublication[2];procPublishedSources=previousPublication[3];procPublishedFinalKeep=previousPublication[4]
            procPublishedRadii=previousPublication[5];procPublishedInfo=previousPublication[6];groupSnapshotRows=previousPublication[7]
            groupSnapshotKey=previousPublication[8];procPublishedDisplayKey=previousPublication[9];groupBuilds=previousPublication[10];CyrusViewportRecordsDirty=previousPublication[11]
            procPublishedMetadata=previousPublication[12]
            for i=1 to layerObjects.count do (layerObjects[i].procPreparedKey="";layerObjects[i].procCandidateCount=undefined;layerObjects[i].procBindingKey=previousBindings[i])
            groupSolving=false
            if transaction do cyrusEditTransaction mods 2
            try(CyrusDiagnosticEmit "publication.retained" "engine" layerID procEpoch "successor_failed")catch()
            throw()
        )
        groupSolving=false
        -- Observer failures do not relabel an already committed result as retained.
        try(CyrusScheduleUI())catch()
        try(CyrusPFRequestCheck())catch()
        try(CyrusDiagnosticEmit "publication.committed" "engine" layerID procEpoch "complete")catch()
        groupSnapshotRows
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
        local pairs=for i=1 to procRuleA.count collect #(procRuleScope[i],procRuleA[i],procRuleB[i],procRuleEnabled[i],procRuleMultiplier[i],procRuleGapWU[i],procRulePlanar[i])
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
                if row.count!=8 or row[8]!=2 do throw "Invalid published placement transport."
                local protectedEdit=row[7]
                append result #(i,(copy row[1]),row[2],id,protectedEdit,procPublishedRadii[i][j],keep)
            )
            base+=rows.count
        )
        #(procPublishedInfo[1],procPublishedInfo[5],offset+result.count,result)
    )

    fn nativeEditors = (for r in #(updateUI,surfaceUI,previewUI,layersUI) where r!=undefined collect r)
    fn brushEditors = (
        local editors=#()
        if (CyrusContainerPanel this).controlsReady do for r in (CyrusContainerPanel this).editors where isProperty r #refreshBrushStatus and r.controlsReady do appendIfUnique editors r
        editors
    )
    fn refreshBrushEditors = (for r in this.brushEditors() where r.controlsReady do r.refreshBrushStatus())
    fn syncBrushAvailability = (
        local editors=#()
        if (CyrusContainerPanel this).controlsReady do join editors (CyrusContainerPanel this).editors
        for r in editors where r.controlsReady do (
            if isProperty r #syncRelaxAvailability do r.syncRelaxAvailability()
            if isProperty r #syncFinalRelaxAvailability do r.syncFinalRelaxAvailability()
        )
    )
    fn bindNativeUI = (
        if (CyrusContainerPanel this).controlsReady do (CyrusContainerPanel this).bind()
        true
    )
    rollout mainUI "Cyrus Scatter 0.82.4" width:#cmdPanel height:30 autoLayoutOnResize:true (
        local root=undefined,controlsReady=false,binding=false,layerBinding=false,roots=#(),editors=#(),owner=undefined,layerPagesVisible=false
        checkbox enabledCheck "Enable Cyrus Scatter" pos:[8,6] width:(mainUI.width-16) tooltip:"Enable calculation and output for this entire Scatter setup."
        button licenseButton "License / activation..." pos:[8,112] width:(mainUI.width-16) height:22 tooltip:"Import a team license or inspect its expiry. Existing scenes remain available after expiry."
        timer mountTimer interval:1 active:false
        timer statusTimer interval:1000 active:false
        fn layoutPanels = true
        fn refreshTitles = (
            if owner!=undefined and root.selected_setsUI!=undefined do root.selected_setsUI.title="Paint Areas | "+(root.layerCaption owner)
            CyrusContainerRefreshLabels root;true
        )
        fn refreshStats = (
            if not controlsReady do return false
            if root.layersUI!=undefined and root.layersUI.controlsReady do root.layersUI.refreshStats()
            if root.surfaceUI!=undefined and root.surfaceUI.controlsReady do root.surfaceUI.refreshStats()
            root.syncBrushAvailability();true
        )
        fn bindSection section = (
            if not controlsReady or owner==undefined or findItem root.layerObjects owner==0 do return false
            section.root=root;section.owner=owner;section.panel=mainUI
            if section.open then section.bind (if isProperty section #setSpecific and section.setSpecific then owner else owner)
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
        fn rebuild = bind()
        fn rebuildLayers = rebuild()
        fn selectLayerView layer = (
            if layer==undefined do return false
            local parent=root.logicalParent layer
            if root.selectedLayer()!=parent do undo off root.selectLayer (findItem root.layerObjects parent)
            bindEditors()
            if root.layersUI!=undefined and root.layersUI.controlsReady do root.layersUI.bind undefined
            true
        )
        on mainUI open do (root=this;controlsReady=false;mountTimer.active=true)
        on mountTimer tick do (
            if not mainUI.isDisplayed do return false
            mountTimer.active=false
            if cyrusSetRolloutVisible==undefined do throw "Load the matching Cyrus 0.82.4 native plugin and restart Max."
            root.syncLayerIdentity()
            roots=#(root.flow_updateUI,root.flow_surfaceUI,root.flow_previewUI,root.flow_layersUI)
            root.updateUI=roots[1];root.surfaceUI=roots[2];root.previewUI=roots[3];root.layersUI=roots[4]
            editors=#(root.selected_setsUI,root.selected_sourceUI,root.selected_sourceContainersUI,root.selected_distributionUI,root.selected_populationPolicyUI,root.selected_areaUI,root.selected_brushUI,root.selected_randomUI,root.selected_diversityUI,root.selected_proceduralUI,root.selected_instanceRadiusUI,root.selected_spacingUI,root.selected_separationUI,root.selected_detailsUI,root.selected_workflowUI)
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
        button updateNow "Update now" pos:[6,78] width:(flow_updateUI.width-12) tooltip:"Calculate enabled layers in order."
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
            local text=((root.logicalLayers()).count as string)+" layers | "+(CyrusUICount total)+" cached placements\n"+(root.layerObjects.count as string)+" / 10 populations"+(if pending>0 then " | Pending update" else "")
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
        spinner instancesLimitSpin "Idle instances:" range:[0,2147483647,2000] type:#integer fieldWidth:58 pos:[6,138] width:(flow_previewUI.width-12)
        spinner faceLimitSpin "Idle triangles:" range:[0,2147483647,2000000] type:#integer fieldWidth:58 pos:[6,166] width:(flow_previewUI.width-12)
        dropdownlist identificationDrop "Color by" items:#("Model","Layer","Bands") pos:[6,208] width:(flow_previewUI.width-12) tooltip:"Use Model, Layer or published Band ownership in Points, Proxy and shaded Mesh. Non-Band layouts use neutral gray (Unbanded). Render materials are unchanged."
        radiobuttons pointColorRadio "Preview color" labels:#("Solid Color","Identification Colors") columns:1 pos:[6,194] width:(flow_previewUI.width-12)
        colorpicker solidColorPicker "Solid: " color:(color 100 220 120) pos:[6,264] width:(flow_previewUI.width-12)
        spinner budgetSpin "Idle points: " range:[0,2147483647,20000] type:#integer fieldWidth:58 width:(flow_previewUI.width-12) pos:[6,292]
        spinner navigationPointsSpin "Navigating points:" range:[0,2147483647,10000] type:#integer fieldWidth:58 width:(flow_previewUI.width-12) pos:[6,300]
        spinner navigationInstancesSpin "Navigating instances:" range:[0,2147483647,500] type:#integer fieldWidth:58 width:(flow_previewUI.width-12) pos:[6,302]
        spinner navigationFacesSpin "Navigating triangles:" range:[0,2147483647,500000] type:#integer fieldWidth:58 width:(flow_previewUI.width-12) pos:[6,304]
        label limitsHint "Controller totals; 0 = unlimited" pos:[6,306] width:(flow_previewUI.width-12)
        spinner pointsSpin "Points/plant: " range:[10,10000,80] type:#integer fieldWidth:58 width:(flow_previewUI.width-12) pos:[6,318]
        spinner radiusLimitSpin "Radii / layer:" range:[0,1000000,2000] type:#integer fieldWidth:58 width:(flow_previewUI.width-12) pos:[6,344]
        dropdownlist radiusMetricDrop "Radius display" items:#("XY footprint","3D bound") pos:[6,346] width:(flow_previewUI.width-12) tooltip:"Inspect the published radius pair. This display choice does not change any spacing rule. 3D uses three orthogonal rings."
        checkbox radiusAllCheck "Show All Radii" pos:[6,370] width:(flow_previewUI.width-12)
        label radiusHint "Display only; 0 = hide radii" pos:[6,396] width:(flow_previewUI.width-12)
        spinner iconSpin "Icon size: " range:[0.1,10000,10] type:#worldUnits fieldWidth:58 width:(flow_previewUI.width-12) pos:[6,422]
        button refreshButton "Refresh preview" pos:[6,452] width:(flow_previewUI.width-12)
        checkbox autoRenderCheck "Automatic final render" pos:[6,482] width:(flow_previewUI.width-12)
        button clearBakedButton "Remove old baked output" pos:[6,512] width:(flow_previewUI.width-12)
        label status "Ready" pos:[6,572] width:(flow_previewUI.width-12) height:60

        fn syncDisplay = (
            radiusMetricDrop.selection=obj.radiusDisplayMetric
            displayModeDrop.selection=if obj.groupCenters then 4 else obj.viewportMode;proxyShapeDrop.selection=obj.proxyShape
            proxyShapeDrop.visible=obj.viewportMode==2
            instancesLimitSpin.visible=obj.viewportMode==2;faceLimitSpin.visible=obj.viewportMode==3
            navigationPointsSpin.visible=obj.viewportMode==1;navigationInstancesSpin.visible=obj.viewportMode==2;navigationFacesSpin.visible=obj.viewportMode==3
            navigationPointsSpin.value=obj.viewportNavigationPoints;navigationInstancesSpin.value=obj.viewportNavigationInstances;navigationFacesSpin.value=obj.viewportNavigationFaces
            budgetSpin.visible=obj.viewportMode==1
            instancesLimitSpin.value=obj.viewportInstances;faceLimitSpin.value=obj.viewportFaces
            budgetSpin.enabled=obj.viewportMode==1;pointsSpin.enabled=obj.viewportMode==1 and not obj.groupCenters
        )
        fn syncControls = (syncDisplay();identificationDrop.selection=obj.identificationMode;radiusLimitSpin.value=obj.radiusDisplayLimit;radiusAllCheck.checked=obj.radiusDisplayAll;radiusLimitSpin.enabled=not obj.radiusDisplayAll;autoRenderCheck.checked=obj.autoRender;budgetSpin.value=obj.previewBudget;pointColorRadio.state=obj.pointColorMode;solidColorPicker.color=obj.solidPointColor;)
        on radiusLimitSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.radiusDisplayLimit=v;obj.refreshDisplay();syncControls();CyrusViewportRedraw())
        on radiusMetricDrop selected v do if controlsReady and not binding and obj!=undefined do (obj.radiusDisplayMetric=v;obj.refreshDisplay();syncControls();CyrusViewportRedraw())
        on radiusAllCheck changed v do if controlsReady and not binding and obj!=undefined do (obj.radiusDisplayAll=v;obj.refreshDisplay();syncControls();CyrusViewportRedraw())
        on displayModeDrop selected v do if controlsReady and not binding and obj!=undefined do (obj.setGroupDisplay v;syncControls();status.text=obj.allStatus();CyrusViewportRedraw())
        on proxyShapeDrop selected v do if controlsReady and not binding and obj!=undefined do (obj.proxyShape=v;obj.refreshDisplay();syncControls();status.text=obj.allStatus();CyrusViewportRedraw())
        on navigationPointsSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.viewportNavigationPoints=v;obj.refreshDisplay();CyrusViewportRedraw())
        on navigationInstancesSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.viewportNavigationInstances=v;obj.refreshDisplay();CyrusViewportRedraw())
        on navigationFacesSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.viewportNavigationFaces=v;obj.refreshDisplay();CyrusViewportRedraw())
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
        on pointColorRadio changed v do if controlsReady and not binding and obj!=undefined do (obj.pointColorMode=v;syncControls();CyrusViewportRedraw())
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
            local text=if selectedSummary==undefined then "Select a layer." else "Accepted: "+(CyrusUICount selectedSummary[1])+"\n"+(CyrusUIPreviewLabel (selected.uiLayerStats()).mode)+": "+(CyrusUICount selectedSummary[2])+" | "+selectedSummary[3]
            if countInfo.text!=text do countInfo.text=text
            binding=false
        )
        fn bind layer = (
            binding=true;members=root.logicalLayers()
            local selected=currentLayer(),index=findItem root.layerObjects selected,valid=index>0
            for c in #(copyButton,removeButton,nameEdit,visibleCheck,enabledCheck) do c.enabled=valid
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
        on layerList doubleClicked i do if not binding and i>0 do (CyrusContainerPanel root).selectLayerView members[i]
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
        dropdownlist setList "Paint Area" items:#() pos:[4,36] width:(selected_setsUI.width-8)
        button addButton "+" pos:[4,86] width:60 tooltip:"Create a named area. Painting again edits the selected area."
        button removeButton "Remove" pos:[68,86] width:60 tooltip:"Remove the selected area. Undo restores it."
        edittext nameEdit "Name:" pos:[4,116] width:(selected_setsUI.width-8)
        dropdownlist targetList "Surface" items:#() pos:[4,144] width:(selected_setsUI.width-8) tooltip:"Explicit target within this layer. An area with saved paint cannot be silently retargeted."
        checkbox enabledCheck "Enable area" pos:[4,198] width:(selected_setsUI.width-8) tooltip:"Enable this Paint Area's contribution to the layer."
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
            addButton.enabled=members.count<128
            info.text=if area!=undefined and findItem targets area.areaTarget==0 then "Inactive: assign a surface, or restore this area's original surface to the layer. Saved paint is retained." else "Paint and Erase edit this area. Areas share the layer's models; overlaps do not duplicate plants."
            controlsReady=true;binding=false
        )
        fn selectSet i = (
            if binding or i<1 or i>members.count do return false
            local controller=root,parent=owner
            CyrusStopBrush();parent.uiAreaID=members[i].layerID;controller.bindNativeUI();true
        )
        on setList selected i do selectSet i
        on addButton pressed do try(root.addPaintArea owner)catch(messageBox (getCurrentException()) title:"Cyrus Paint Area")
        on removeButton pressed do try(root.removePaintArea owner (currentSet()))catch(messageBox (getCurrentException()) title:"Cyrus Paint Area")
        on nameEdit entered value do if not binding and value!="" and currentSet()!=undefined do (undo "Cyrus area name" on (currentSet()).paintSetName=value;root.bindNativeUI())
        on paintedCheck changed value do if not binding do (
            local controller=root,parent=owner
            CyrusStopBrush();undo "Cyrus coverage mode" on (parent.paintEnabled=value)
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
        pickbutton addPlant "Pick model" pos:[4,140] width:((selected_sourceUI.width-12)/2) tooltip:"Pick a scene model for this layer."
        button addSelected "Add selection" pos:[(selected_sourceUI.width/2+2),140] width:((selected_sourceUI.width-12)/2) tooltip:"Add the currently selected scene objects to this layer."
        button removePlant "Remove rows" pos:[4,200] width:(selected_sourceUI.width-8) tooltip:"Unregister highlighted rows. To keep their settings, park models outside a source rectangle instead."
        button selectPlant "Select sources" pos:[(selected_sourceUI.width/2+2),170] width:((selected_sourceUI.width-12)/2) tooltip:"Select the highlighted source models in the scene."
        button addPoint "Add Point" pos:[4,460] width:((selected_sourceUI.width-12)/2) tooltip:"Add a named placeholder type. Scatter points now, then replace this row with a model."
        button addEmpty "Add Empty" pos:[(selected_sourceUI.width/2+2),460] width:((selected_sourceUI.width-12)/2) tooltip:"Add a weighted empty source for intentional gaps in candidate-budget mode."
        pickbutton replacePoint "Pick object" filter:AminScatterSourceFilter pos:[4,490] width:(selected_sourceUI.width-8) tooltip:"Use a scene model for the selected Point; keep its identity, settings and Band assignments."
        button makePoint "Make point" pos:[4,514] width:(selected_sourceUI.width-8) tooltip:"Use the selected model row as a Point. Keep its settings and registration; do not delete the scene object."
        label groupHeading "Assignment group" pos:[4,530] width:(selected_sourceUI.width-8)
        dropdownlist existingGroups "Reuse a group" items:#() pos:[4,552] width:(selected_sourceUI.width-8) tooltip:"Assign highlighted sources to an existing color group for clustering."
        colorpicker groupColor "Color: " color:(color 100 220 120) pos:[4,606] width:(selected_sourceUI.width-8) modal:true notifyAfterAccept:true tooltip:"Assign a color group to highlighted sources when the color is accepted."
        button applyColor "Apply to selected rows" pos:[4,634] width:(selected_sourceUI.width-8) tooltip:"Assign the chosen color group to all highlighted source rows."
        label colorHelp "OK saves the selected color." pos:[4,664] width:(selected_sourceUI.width-8)
        spinner weightSpin "Weight: " range:[0,1,1] scale:0.01 pos:[4,236] width:((selected_sourceUI.width-12)/2) fieldWidth:82 tooltip:"Relative model frequency in this layer. Zero disables the model."
        label weightHelp "0 = off; relative share" pos:[4,378] width:(selected_sourceUI.width-8)
        spinner sourceZSpin "Z Offset: " range:[-1000000,1000000,0] type:#worldunits pos:[4,266] width:((selected_sourceUI.width-12)/2) fieldWidth:82 tooltip:"Offset instances of highlighted models along world Z."
        spinner sourceScaleSpin "Scale: " range:[0,10000,1] scale:0.01 pos:[(selected_sourceUI.width/2+2),236] width:((selected_sourceUI.width-12)/2) fieldWidth:82 tooltip:"Per-model scale multiplier. 1 keeps the model's original scale."
        label sourceTransformHelp "Scale: 1 = original" pos:[4,398] width:(selected_sourceUI.width-8)
        spinner radiusSourceSpin "Radius:" type:#worldunits range:[0,1e9,0] pos:[(selected_sourceUI.width/2+2),266] width:((selected_sourceUI.width-12)/2) fieldWidth:82 tooltip:"Collision footprint radius for highlighted source rows, in scene units."
        dropdownlist radiusModeDrop "Radius mode" items:#("Manual","Auto") pos:[4,268] width:(selected_sourceUI.width-8) tooltip:"Auto bounds supported model geometry around its pivot after final instance scale and orientation. This is conservative spacing, not mesh collision or Band containment."
        label radiusModeHelp "Manual radius in scene units" pos:[4,272] width:(selected_sourceUI.width-8) height:32
        checkbox followRadiusCheck "Follow Scale" pos:[4,294] width:((selected_sourceUI.width-12)/2) tooltip:"Scale this source's collision footprint with its instance scale."
        checkbox showRadiusCheck "Show Radius" pos:[(selected_sourceUI.width/2+2),294] width:((selected_sourceUI.width-12)/2) tooltip:"Show this source's radius in the viewport; does not change collision rules."
        dropdownlist forwardAxis "Forward axis:" items:#("+Y","-Y","+X","-X") pos:[4,326] width:(selected_sourceUI.width-8) tooltip:"The model's local forward direction, used for orientation."
        fn updateList = (
            local selectedRows=plantList.selection
            if selectedRows.numberSet==0 and obj.sources.count>0 do selectedRows=#{1}
            plantList.items=for i=1 to obj.sources.count collect ((obj.sourceLabel i)+" | "+(formattedPrint (obj.sourceWeight i) format:".2f")+(if obj.diversityMode==3 then " | "+obj.sourceBandLabel i else ""))
            plantList.selection=selectedRows
            groupPalette=#()
            local keys=#()
            for i=1 to obj.sources.count do (
                local c=obj.sourceColor i
                local k=obj.colorKey c
                if findItem keys k==0 do (append keys k;append groupPalette c)
            )
            existingGroups.items=for i=1 to groupPalette.count collect ("Group "+(i as string))
        )
        fn addSource n = (
            if obj.usableSource n and (findItem obj.sources n)==0 do (
                obj.ensureSourceRows()
                obj.syncColors();while obj.sourceEmpty.count<obj.sources.count do append obj.sourceEmpty false;append obj.sourceEmpty false;append obj.sources n;append obj.sourceRowIDs (CyrusNewLayerID());append obj.sourceColors groupColor.color;if obj.sourceWeights.count>0 do append obj.sourceWeights 1.0;if obj.sourceZOffsetsWU.count>0 do append obj.sourceZOffsetsWU 0.0;if obj.sourceScales.count>0 do append obj.sourceScales 1.0;obj.markInputDirty()
            )
        )

        fn showSelectedColor = (
            local rows=plantList.selection
            weightSpin.enabled=rows.numberSet>0;sourceZSpin.enabled=rows.numberSet>0;sourceScaleSpin.enabled=rows.numberSet>0;forwardAxis.enabled=rows.numberSet>0
            if rows.numberSet>0 then (
                if focusedRow<1 or not rows[focusedRow] do focusedRow=(rows as array)[1]
                loadingColor=true
                sourceName.text=obj.sourceLabel focusedRow;idColor.color=obj.sourceIDColor focusedRow
                sourceName.enabled=true;idColor.enabled=true
                groupColor.color=obj.sourceColor focusedRow
                weightSpin.enabled=true;weightSpin.value=obj.sourceWeight focusedRow
                radiusSourceSpin.value=obj.sourceRadius focusedRow;followRadiusCheck.checked=obj.sourceFollows focusedRow;showRadiusCheck.checked=obj.sourceShows focusedRow;sourceZSpin.value=obj.sourceZOffset focusedRow;sourceScaleSpin.value=obj.sourceScale focusedRow;forwardAxis.selection=obj.sourceForward focusedRow
                local auto=obj.sourceUsesAuto focusedRow,allSupported=true,anyAuto=false
                for i in rows do (if not obj.sourceCanAuto i do allSupported=false;if obj.sourceUsesAuto i do anyAuto=true)
                radiusModeDrop.items=if allSupported then #("Manual","Auto") else if anyAuto then #("Manual","Auto (unavailable)") else #("Manual")
                radiusModeDrop.selection=if auto then 2 else 1
                radiusModeDrop.enabled=true;radiusSourceSpin.enabled=not anyAuto;followRadiusCheck.enabled=not anyAuto;showRadiusCheck.enabled=true
                radiusModeHelp.text=if obj.isPointSource focusedRow then "Points have no model geometry to measure. Use Manual radius." else if not allSupported then "Auto unavailable for this selection. Manual radius remains available." else if anyAuto then "Auto follows instance size. Manual settings are saved." else "Manual radius in scene units; Follow Scale is optional."
                existingGroups.selection=findItem groupPalette (obj.sourceColor focusedRow)
                loadingColor=false
            ) else (
                sourceName.text="";sourceName.enabled=false;idColor.enabled=false
                radiusModeDrop.enabled=false;radiusSourceSpin.enabled=false;followRadiusCheck.enabled=false;showRadiusCheck.enabled=false;radiusModeHelp.text="Select a source to edit its radius."
                loadingColor=true;groupColor.color=obj.sourceColor 1;existingGroups.selection=0;focusedRow=0;loadingColor=false
            )
            radiusModeDrop.tooltip=radiusModeHelp.text
            replacePoint.enabled=rows.numberSet==1 and obj.isPointSource focusedRow
            makePoint.enabled=rows.numberSet==1 and focusedRow>0 and not obj.isEmptySource focusedRow and obj.usableSource obj.sources[focusedRow]
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
            replacePoint.text="Pick object";updateList();showSelectedColor();CyrusViewportRedraw()
        )
        on makePoint pressed do if controlsReady and not binding and obj!=undefined do (
            local rows=plantList.selection as array
            if rows.count==1 and obj.makePointSource rows[1] do (updateList();showSelectedColor();CyrusViewportRedraw())
        )
        on addEmpty pressed do if controlsReady and not binding and obj!=undefined do (
            local i=obj.addEmptySource();updateList();plantList.selection=#{i};focusedRow=i;showSelectedColor();CyrusViewportRedraw()
        )
        on radiusSourceSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingColor do (obj.setSourceRadius plantList.selection v;CyrusViewportRedraw())
        on radiusModeDrop selected v do if controlsReady and not binding and obj!=undefined and not loadingColor do (
            try(obj.setSourceRadius plantList.selection (v==2) kind:4)catch(messageBox (getCurrentException()) title:"Cyrus Scatter")
            showSelectedColor();CyrusViewportRedraw()
        )
        on followRadiusCheck changed v do if controlsReady and not binding and obj!=undefined do if not loadingColor do (obj.setSourceRadius plantList.selection v kind:2;CyrusViewportRedraw())
        on showRadiusCheck changed v do if controlsReady and not binding and obj!=undefined do if not loadingColor do (
            local controller=if obj.overlapOwner==undefined then obj else obj.overlapOwner
            obj.setSourceRadius plantList.selection v kind:3;controller.refreshDisplay()
        )
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
            obj.syncStrokes()
            local rows=plantList.selection as array
            undo "Cyrus Scatter remove sources" on (
                for k=rows.count to 1 by -1 do (
                    deleteItem obj.sourceRowIDs rows[k]
                    for key in #(#sourceRadiiWU,#sourceAutoRadius,#sourceFollowScale,#sourceShowRadius) do (local tab=getProperty obj key;if rows[k]<=tab.count do deleteItem tab rows[k])
                    if rows[k]<=obj.sourcePoint.count do deleteItem obj.sourcePoint rows[k]
                    if rows[k]<=obj.sourceEmpty.count do deleteItem obj.sourceEmpty rows[k]
                    if rows[k]<=obj.sourceZOffsetsWU.count do deleteItem obj.sourceZOffsetsWU rows[k]
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
            for c in selected_sourceUI.controls where c.enabled!=(layer!=undefined) do c.enabled=layer!=undefined
            try (undo off ((controlsReady=true;(updateList();showSelectedColor())))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        checkbutton detailsToggle "Point / Empty sources and color groups" pos:[4,426] width:(selected_sourceUI.width-8) height:26 tooltip:"Show or hide these advanced controls; their saved settings are preserved."
        fn arrangeDetails = (
            for c in #(addPoint,addEmpty,replacePoint,makePoint,groupHeading,existingGroups,groupColor,applyColor,colorHelp) do c.visible=detailsToggle.checked
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
        checkbox enabledCheck "Enable collection" pos:[4,136] width:(selected_sourceContainersUI.width-8) tooltip:"Enable the selected rectangle to collect models. New rectangles start off so you can position them first. Manual mode needs Update."
        button createContainer "Create container" pos:[4,154] width:(selected_sourceContainersUI.width-8) tooltip:"Create an inactive source rectangle. Position it around model pivots, then enable collection."
        pickbutton pickContainer "Pick boundary" filter:CyrusSourceContainerFilter pos:[4,184] width:(selected_sourceContainersUI.width-8) tooltip:"Link a Cyrus container, or copy a square-corner Rectangle into a container. The original spline is preserved."
        button removeContainer "Unlink selected rectangle" pos:[4,214] width:(selected_sourceContainersUI.width-8) tooltip:"Unlink this rectangle without deleting it or registered source settings."
        label membershipInfo "Manual source list." pos:[4,244] width:(selected_sourceContainersUI.width-8) height:48
        label helpInfo "Pivot inside = active. Height is ignored. Moving out keeps source settings. Manual needs Update." pos:[4,286] width:(selected_sourceContainersUI.width-8) height:44
        fn currentSet = owner
        fn selectedContainer = (
            local nodes=(currentSet()).effectiveContainers(),index=containersList.selection
            if index>0 and index<=nodes.count and isValidNode nodes[index] then nodes[index] else undefined
        )
        fn refreshCollection = (
            local node=selectedContainer()
            enabledCheck.enabled=node!=undefined;enabledCheck.checked=node!=undefined and node.collectEnabled
        )
        fn bind layer = (
            binding=true
            local leaf=currentSet(),active=true,own=leaf.logicalParentID==""
            modes=if own then #(1,3,4) else #(1,2,3,4)
            modeList.items=if own then #("Manual models","Shared containers","Layer containers") else #("Manual sources","Layer default","Global containers","This set's containers")
            modeList.selection=amax 1 (findItem modes leaf.containerMode)
            local nodes=leaf.effectiveContainers(),selected=containersList.selection
            containersList.items=for node in nodes collect (if isValidNode node then node.name+(if node.collectEnabled then "" else " [off]") else "<deleted rectangle>")
            containersList.selection=if nodes.count==0 then 0 else amax 1 (amin selected nodes.count)
            refreshCollection()
            modeList.enabled=active;containersList.enabled=active
            createContainer.enabled=true;pickContainer.enabled=true;removeContainer.enabled=leaf.containerMode==4
            local registered=leaf.sources.count,count=0
            for value in leaf.containerActive where value do count+=1
            membershipInfo.text=if leaf.containerProvider()==undefined then "Manual source list." else (count as string)+" active / "+(registered as string)+" registered\nShared rectangles: Surface Scatter."
            controlsReady=true;binding=false
        )
        on selected_sourceContainersUI open do (root=this;controlsReady=false)
        on selected_sourceContainersUI close do controlsReady=false
        on containersList selected index do refreshCollection()
        on enabledCheck changed value do if not binding do (
            local node=selectedContainer(),layer=owner
            if node!=undefined do undo "Cyrus container collection" on node.collectEnabled=value
            bind layer
        )
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

        button presetsButton "Presets..." width:130 height:22 tooltip:"Save or apply named population settings. Assets and receiver references are preserved."
        radiobuttons modeRadio "Method" labels:#("Random","Texture Density") columns:2 pos:[4,130] width:(selected_distributionUI.width-8)
        radiobuttons populationRadio "Population" labels:#("Count","Plants per m2") columns:2 pos:[4,8] width:(selected_distributionUI.width-8)
        spinner countSpin "Requested count: " range:[1,1000000,200] type:#integer fieldWidth:82 width:(selected_distributionUI.width-8) pos:[4,62] tooltip:"Layer population before eligibility, up to 1,000,000. All layers and retries share the Scatter's 1,000,000 candidate limit."
        spinner densitySpin "Per m2: " range:[0,1000000,100] fieldWidth:82 width:(selected_distributionUI.width-8) pos:[4,62] tooltip:"Requested plants per square metre; capped at 1,000,000 per layer. All layers and retries share the Scatter's 1,000,000 candidate limit."
        spinner seedSpin "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:82 width:(selected_distributionUI.width-8) pos:[4,92] tooltip:"Deterministic generation seed. Changing it can invalidate existing Edit bindings."
        label densityHeading "Texture density" pos:[4,180] width:(selected_distributionUI.width-8)
        mapbutton densityButton "Choose density map" pos:[4,204] width:(selected_distributionUI.width-8) tooltip:"Use the selected receiver UV channel: white permits candidates; black excludes them. UVs clamp to 0..1."
        checkbox invertCheck "Invert density" pos:[4,234] width:(selected_distributionUI.width-8) tooltip:"Reverse the density map's white and black eligibility."
        spinner uvChannelSpin "UV channel:" type:#integer range:[1,99,1] width:(selected_distributionUI.width-8) fieldWidth:82 tooltip:"Receiver texture coordinates, channels 1..99. Missing or invalid mapping retains the previous complete result."
        dropdownlist resolutionList "Map resolution" items:#("64 x 64","128 x 128","256 x 256","512 x 512") selection:2 width:(selected_distributionUI.width-8) tooltip:"Sampled map detail. Higher resolutions cost more time and memory; tiny features may need more samples. Default: 128 x 128."
        label uvHint "UVs clamp to 0..1" pos:[4,260] width:(selected_distributionUI.width-8)
        label mapHint "White: dense / Black: empty" pos:[4,282] width:(selected_distributionUI.width-8)
        checkbox meshCheck "Use mesh channel mask" tooltip:"Thin this layer using values stored on each receiving mesh. Combines with Paint, texture density and slope/altitude filters."
        spinner meshChannelSpin "Channel:" type:#integer range:[0,99,0] fieldWidth:82 width:(selected_distributionUI.width-8) tooltip:"0 reads vertex colors; 1..99 read numbered mesh map channels. These are values, independent of density UV coordinates."
        dropdownlist meshComponentList "Component" items:#("R / X","G / Y","B / Z") selection:1 width:(selected_distributionUI.width-8) tooltip:"Read one component of the selected mesh channel. Match Data Channel's Vertex Output component."
        spinner meshMinSpin "Input min:" range:[-1e9,1e9,0] fieldWidth:82 width:(selected_distributionUI.width-8) tooltip:"Channel value mapped to 0 before Invert and the Density curve. Must be less than Input max."
        spinner meshMaxSpin "Input max:" range:[-1e9,1e9,1] fieldWidth:82 width:(selected_distributionUI.width-8) tooltip:"Channel value mapped to 1 before Invert and the Density curve. Values outside the range clamp."
        checkbox meshInvertCheck "Invert mesh mask" tooltip:"Reverse the normalized channel values before applying the Density curve."
        button meshCurveButton "Density curve..." width:(selected_distributionUI.width-8) tooltip:"Remap normalized mesh values into planting eligibility. Left is 0; right is 1."
        button meshPreviewButton "Preview mask" width:82 tooltip:"Read a snapshot of the current mask as at most 2,048 grayscale face-centre markers. White permits plants; black excludes. Refresh after edits."
        button meshHideButton "Hide preview" width:82 tooltip:"Hide the cached mesh mask markers without recalculating plants."
        label meshHint "Data Channel / VertexPaint. White: permitted; black: excluded. Preview shows current inputs; Manual plants wait for Update." width:(selected_distributionUI.width-8) height:48

        fn arrangePopulation = (
            local textured=obj.distributionMode==3
            countSpin.visible=obj.populationMode==1;densitySpin.visible=obj.populationMode==2
            for c in #(densityHeading,densityButton,invertCheck,uvChannelSpin,resolutionList,uvHint,mapHint) do c.visible=textured
            selected_distributionUI.height=if obj.sharedSpacing() then (if textured then 308 else 184) else (if textured then 340 else 208)
        )
        fn syncControls = (
            populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;uvChannelSpin.value=obj.densityUVChannel;resolutionList.selection=findItem #(64,128,256,512) obj.densityResolution
            meshCheck.checked=obj.meshMaskEnabled;meshChannelSpin.value=obj.meshMaskChannel;meshComponentList.selection=obj.meshMaskComponent
            meshMinSpin.value=obj.meshMaskMinimum;meshMaxSpin.value=obj.meshMaskMaximum;meshInvertCheck.checked=obj.meshMaskInvert
            for c in #(meshChannelSpin,meshComponentList,meshMinSpin,meshMaxSpin,meshInvertCheck,meshCurveButton,meshPreviewButton) do c.enabled=obj.meshMaskEnabled
            arrangePopulation()
        )
        fn setMeshMask key value = (
            if controlsReady and not binding and obj!=undefined do (
                local target=obj
                undo "Cyrus mesh density mask" on setProperty target key value
                syncControls();CyrusViewportRedraw()
            )
        )
        on meshCheck changed value do setMeshMask #meshMaskEnabled value
        on meshChannelSpin changed value do setMeshMask #meshMaskChannel value
        on meshComponentList selected value do setMeshMask #meshMaskComponent value
        on meshMinSpin changed value do setMeshMask #meshMaskMinimum value
        on meshMaxSpin changed value do setMeshMask #meshMaskMaximum value
        on meshInvertCheck changed value do setMeshMask #meshMaskInvert value
        on meshCurveButton pressed do if controlsReady and not binding and obj!=undefined do CyrusOpenFalloffGraph obj undefined true meshMask:true
        on meshPreviewButton pressed do if controlsReady and not binding and obj!=undefined do try(CyrusShowMeshMaskPreview obj)catch(messageBox (getCurrentException()) title:"Mesh density preview")
        on meshHideButton pressed do (CyrusClearMeshMaskPreview undefined;redrawViews())
        on modeRadio changed v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.distributionMode=if v==2 then 3 else 1;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on countSpin changed v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.amount=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on seedSpin changed v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.randomSeed=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())

        on populationRadio changed v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.populationMode=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on densitySpin changed v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.plantsPerM2=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on densityButton picked v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.densityMap=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on invertCheck changed v do if controlsReady and not binding and obj!=undefined do undo "Cyrus layer population" on (obj.invertDensity=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on uvChannelSpin changed v do if controlsReady and not binding and obj!=undefined do (
            local target=obj
            undo "Cyrus density UV channel" on (target.densityUVChannel=v;target.markInputDirty())
            syncControls();CyrusViewportRedraw()
        )
        on resolutionList selected v do if controlsReady and not binding and obj!=undefined and v>=1 and v<=4 do (
            local target=obj,value=#(64,128,256,512)[v]
            undo "Cyrus density resolution" on (target.densityResolution=value;target.markInputDirty())
            syncControls();CyrusViewportRedraw()
        )



        fn bindFeatures layer = (
            local next=layer
            binding=true;controlsReady=false
            if obj!=next do ()
            obj=next;parentView=(CyrusContainerPanel root)
            for c in selected_distributionUI.controls where c.enabled!=(layer!=undefined) do c.enabled=layer!=undefined
            try (undo off ((populationRadio.state=obj.populationMode;densitySpin.value=obj.plantsPerM2;densityButton.map=obj.densityMap;invertCheck.checked=obj.invertDensity;uvChannelSpin.value=obj.densityUVChannel;resolutionList.selection=findItem #(64,128,256,512) obj.densityResolution;controlsReady=true;(countSpin.value=obj.amount;seedSpin.value=obj.randomSeed;modeRadio.state=if obj.distributionMode==3 then 2 else 1)))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        fn bind layer = (bindFeatures layer;binding=true;syncControls();binding=false)
        on presetsButton pressed do try(CyrusOpenPresets root owner "population")catch(messageBox (getCurrentException()) title:"Cyrus presets")
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
        checkbox slopeCheck "Filter slope" pos:[4,1220] width:180 tooltip:"Eligibility from world up: 0 degrees upward, 90 vertical, 180 underside. Protected Edit plants are retained."
        spinner slopeMinSpin "Min slope:" type:#float range:[0,180,0] pos:[4,1250] width:(selected_areaUI.width-8) fieldWidth:82 tooltip:"Minimum slope in degrees. Zero inside fade includes this endpoint."
        spinner slopeMaxSpin "Max slope:" type:#float range:[0,180,180] pos:[4,1280] width:(selected_areaUI.width-8) fieldWidth:82 tooltip:"Maximum slope in degrees; plant alignment does not affect surface slope."
        spinner slopeLowerSpin "Lower fade:" type:#float range:[0,180,0] pos:[4,1310] width:(selected_areaUI.width-8) fieldWidth:82 tooltip:"Inside fade above the minimum, in degrees. Fades must not overlap."
        spinner slopeUpperSpin "Upper fade:" type:#float range:[0,180,0] pos:[4,1340] width:(selected_areaUI.width-8) fieldWidth:82 tooltip:"Inside fade below the maximum, in degrees. Fades must not overlap."
        spinner altitudeMinSpin "Min height:" type:#worldunits range:[-1000000000.0,1000000000.0,0] pos:[4,1370] width:(selected_areaUI.width-8) fieldWidth:82 tooltip:"Minimum world Z of the final receiver anchor, before source offsets."
        spinner altitudeMaxSpin "Max height:" type:#worldunits range:[-1000000000.0,1000000000.0,1000] pos:[4,1400] width:(selected_areaUI.width-8) fieldWidth:82 tooltip:"Maximum world Z of the final receiver anchor, in scene units."
        spinner altitudeLowerSpin "Lower fade:" type:#worldunits range:[0,1000000000.0,0] pos:[4,1430] width:(selected_areaUI.width-8) fieldWidth:82 tooltip:"Inside fade above minimum height. Zero keeps the hard endpoint."
        spinner altitudeUpperSpin "Upper fade:" type:#worldunits range:[0,1000000000.0,0] pos:[4,1460] width:(selected_areaUI.width-8) fieldWidth:82 tooltip:"Inside fade below maximum height. Fades must not overlap."
        checkbox altitudeCheck "Filter altitude" pos:[4,1500] width:180 tooltip:"World Z eligibility. Fades reduce density inside the range; source Z offsets do not change eligibility."
        label filterInfo "Surface filters are off by default." pos:[4,1530] width:(selected_areaUI.width-8) height:54
        fn syncSurfaceFilters = (
            if obj!=undefined do (
                slopeCheck.checked=obj.slopeEnabled
                slopeMinSpin.value=obj.slopeMinimum
                slopeMaxSpin.value=obj.slopeMaximum
                slopeLowerSpin.value=obj.slopeLowerFade
                slopeUpperSpin.value=obj.slopeUpperFade
                altitudeCheck.checked=obj.altitudeEnabled
                altitudeMinSpin.value=obj.altitudeMinimum
                altitudeMaxSpin.value=obj.altitudeMaximum
                altitudeLowerSpin.value=obj.altitudeLowerFade
                altitudeUpperSpin.value=obj.altitudeUpperFade
                for c in #(slopeMinSpin,slopeMaxSpin,slopeLowerSpin,slopeUpperSpin) do c.enabled=obj.slopeEnabled
                for c in #(altitudeMinSpin,altitudeMaxSpin,altitudeLowerSpin,altitudeUpperSpin) do c.enabled=obj.altitudeEnabled
                local stats=obj.surfaceFilterStats()
                filterInfo.text=if obj.procEpoch==0 then "No calculated filter result yet." else if stats[1]<0 then "Filters off at last Update." else "Last Update: "+(stats[2] as string)+" of "+(stats[1] as string)+" prepared rows filtered; "+(stats[3] as string)+" protected."
            )
        )
        fn setSurfaceFilter key value = (
            if controlsReady and not binding and obj!=undefined do (
                local target=obj
                undo "Cyrus surface filter" on (setProperty target key value)
                syncSurfaceFilters();CyrusViewportRedraw()
            )
        )
        on slopeCheck changed value do setSurfaceFilter #slopeEnabled value
        on slopeMinSpin changed value do setSurfaceFilter #slopeMinimum value
        on slopeMaxSpin changed value do setSurfaceFilter #slopeMaximum value
        on slopeLowerSpin changed value do setSurfaceFilter #slopeLowerFade value
        on slopeUpperSpin changed value do setSurfaceFilter #slopeUpperFade value
        on altitudeCheck changed value do setSurfaceFilter #altitudeEnabled value
        on altitudeMinSpin changed value do setSurfaceFilter #altitudeMinimum value
        on altitudeMaxSpin changed value do setSurfaceFilter #altitudeMaximum value
        on altitudeLowerSpin changed value do setSurfaceFilter #altitudeLowerFade value
        on altitudeUpperSpin changed value do setSurfaceFilter #altitudeUpperFade value
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
        dropdownlist fallTarget "Edge falloff target" items:#("Analyzer Boundary","Selected Area line") selection:2 pos:[4,738] width:(selected_areaUI.width-8) tooltip:"Edit Analyzer boundary falloff or one highlighted Area's independent falloff."
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
            local n=fallNode(),valid=(if fallTarget.selection==1 then isValidNode obj.fallAnalyzer else isValidNode n)
            local cfg=if valid then obj.getFallConfig n else #(false,0,false,100,#(0,1),false,100,#(0,1))
            fallPick.enabled=fallTarget.selection==1;fallRemove.enabled=fallTarget.selection==1
            fallPick.text=if isValidNode obj.fallAnalyzer then obj.fallAnalyzer.name else "Pick Surface Analyzer"
            fallTargetName.text=if fallTarget.selection==1 then "Full Boundary / inward" else (if valid then n.name+" / "+(if obj.areaModes[findItem obj.areaNodes n]==2 then "outward" else "inward") else "Select exactly one Area line above."
            )
            for c in #(fallDeleteCheck,fallDeleteSpin,fallScaleCheck,fallScaleSpin,fallScaleEdit,fallDensityCheck,fallDensitySpin,fallDensityEdit) do c.enabled=valid
            fallDeleteCheck.checked=cfg[1];fallDeleteSpin.value=cfg[2];fallScaleCheck.checked=cfg[3];fallScaleSpin.value=cfg[4];fallDensityCheck.checked=cfg[6];fallDensitySpin.value=cfg[7]
            fallDeleteSpin.enabled=valid and cfg[1]
            fallScaleSpin.enabled=valid and cfg[3];fallScaleEdit.enabled=valid and cfg[3]
            fallDensitySpin.enabled=valid and cfg[6];fallDensityEdit.enabled=valid and cfg[6]
            loadingFall=false
        )
        fn setFallValue index value = (
            if not loadingFall do (
                local n=fallNode()
                if (fallTarget.selection==1 and isValidNode obj.fallAnalyzer) or isValidNode n do (local cfg=obj.getFallConfig n;cfg[index]=value;obj.setFallConfig n cfg;syncFalloff();CyrusViewportRedraw())
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
            local modes=for i in selectedRows where i<=obj.areaModes.count collect obj.areaModes[i]
            areaMode.enabled=modes.count>0
            areaMode.state=if modes.count==0 then 0 else if (for m in modes where m!=modes[1] collect m).count>0 then 0 else modes[1]
            areaHint.text=if modes.count==0 then "Select an area to edit its mode." else if areaMode.state==0 then "Mixed modes. Choose one to apply to all selected." else "Exclude overrides Include."
            syncFalloff()
        )
        fn addArea n = (
            if AminScatterAreaFilter n and findItem obj.areaNodes n==0 do (
                undo "Cyrus add area" on (append obj.areaNodes n;append obj.areaModes 1)
                local index=obj.areaNodes.count;updateAreas();areaList.selection=#{index};fallTarget.selection=2;obj.markInputDirty()
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
            updateAreas()
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
                for i=rows.count to 1 by -1 do (deleteItem obj.areaNodes rows[i];deleteItem obj.areaModes rows[i];deleteItem obj.areaFallConfigs rows[i];deleteItem obj.areaFallDeleteWidths rows[i];deleteItem obj.areaFallScaleWidths rows[i];deleteItem obj.areaFallDensityWidths rows[i];deleteItem obj.areaFallScaleGraphs rows[i];deleteItem obj.areaFallDensityGraphs rows[i])
            )
            areaList.selection=#{};obj.markInputDirty();updateAreas();CyrusViewportRedraw()
        )
        on refreshAreas pressed do if controlsReady and not binding and obj!=undefined do (obj.markInputDirty();(if obj.overlapOwner==undefined then obj else obj.overlapOwner).refreshAll();CyrusViewportRedraw())




        fn bindFeatures layer = (
            local next=layer
            binding=true;controlsReady=false
            if obj!=next do (areaList.selection=#{};)
            obj=next;parentView=(CyrusContainerPanel root)
            for c in selected_areaUI.controls where c.enabled!=(layer!=undefined) do c.enabled=layer!=undefined
            try (undo off ((syncAnalyzerArea();syncFalloff();syncSurfaceFilters();controlsReady=true;updateAreas()))) catch(binding=false;controlsReady=true;throw())
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
    rollout selected_brushUI "Vector Brush" width:#cmdPanel category:110 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined,obj=undefined,controlsReady=false,binding=false,setSpecific=true
        label targetInfo "Add a Paint Area to begin." pos:[4,8] width:(selected_brushUI.width-8) height:36
        radiobuttons modeRadio "Brush" labels:#("Paint","Erase") columns:2 pos:[4,48] width:(selected_brushUI.width-8) tooltip:"Paint adds coverage and merges overlapping strokes. Erase removes coverage and cuts holes."
        spinner radiusSpin "Radius:" type:#worldunits range:[0.001,1e7,20] pos:[4,94] width:(selected_brushUI.width-8) fieldWidth:82 tooltip:"Distance from the brush center to its edge. A 100 mm radius paints a 200 mm wide stroke."
        button beginButton "Start Brush" pos:[4,178] width:80 tooltip:"Start painting or erasing on this Paint Area's receiving surface."
        button stopButton "Stop" pos:[88,178] width:80 tooltip:"Finish the current brush session."
        button fillButton "Fill" pos:[4,208] width:80 tooltip:"Cover the entire receiving surface with this Paint Area."
        button emptyButton "Clear" pos:[88,208] width:80 tooltip:"Remove all painted coverage from this area."
        label brushState "" pos:[4,238] width:(selected_brushUI.width-8) height:54
        spinner densitySpin "Area density %:" range:[0,100,100] pos:[4,298] width:(selected_brushUI.width-8) fieldWidth:82 tooltip:"Control this area's planting density. 100% keeps its full density before other masks and filters."
        dropdownlist overlayMode "Paint feedback" items:#("Vector borders","Coverage samples","Off") pos:[4,326] width:(selected_brushUI.width-8) tooltip:"Show painted borders, bounded coverage samples, or hide the Paint overlay."
        colorpicker overlayColor "" color:(color 100 220 120) pos:[4,380] width:(selected_brushUI.width-8) tooltip:"Set this Paint Area's viewport overlay color."
        label brushHelp "Paint merges borders; Erase cuts holes. Zero fade = hard edge. Local XY terrain/planes only. Manual mode needs Update." pos:[4,412] width:(selected_brushUI.width-8) height:78
        spinner insideSpin "Inside fade:" type:#worldunits range:[0,1e9,0] pos:[4,492] width:(selected_brushUI.width-8) fieldWidth:74 tooltip:"Distance inside the painted border for the density and size transition. Both fade distances at zero create a hard edge."
        spinner outsideSpin "Outside fade:" type:#worldunits range:[0,1e9,0] pos:[4,522] width:(selected_brushUI.width-8) fieldWidth:74 tooltip:"Extend the transition beyond the painted border, within the receiving surface. Both fade distances at zero create a hard edge."
        checkbox densityFade "Fade density" checked:true pos:[4,552] width:(selected_brushUI.width-8) tooltip:"Gradually thin plants across the fade region using the Density curve."
        button densityCurve "Density curve..." pos:[4,578] width:(selected_brushUI.width-8) tooltip:"Shape the density transition. Left is the outer end; right is the fully interior end."
        checkbox scaleFade "Fade scale" checked:false pos:[4,608] width:(selected_brushUI.width-8) tooltip:"Vary plant size across the fade region using Edge scale, Inner scale and the Scale curve."
        spinner scaleMin "Edge scale:" range:[0,1000,0] pos:[4,638] width:(selected_brushUI.width-8) fieldWidth:74 tooltip:"Outer-end size multiplier with the default curve. 0.5 means half size; 1 means unchanged. Must not exceed Inner scale."
        spinner scaleMax "Inner scale:" range:[0,1000,1] pos:[4,668] width:(selected_brushUI.width-8) fieldWidth:74 tooltip:"Interior size multiplier with the default curve. 1 means unchanged; 2 means double size. Must be at least Edge scale."
        button scaleCurve "Scale curve..." pos:[4,698] width:(selected_brushUI.width-8) tooltip:"Shape the size transition. Left is the outer end; right is the fully interior end."
        button exportSpline "Export spline" width:(selected_brushUI.width-8) tooltip:"Export this area's closed contours and holes as an independent editable spline on the receiver's local XY plane (local Z=0). Keeps the Paint Area; selects the snapshot. Stop the brush first."
        radiobuttons importMode "Spline import" labels:#("Replace","Add") columns:2 width:(selected_brushUI.width-8) tooltip:"Replace this area's coverage, or union imported coverage with it. Closed loops use even-odd fill and project along receiver-local Z. Source spline is preserved."
        spinner splineTolerance "Curve tolerance:" type:#worldunits range:[1e-9,1e9,0.1] fieldWidth:74 width:(selected_brushUI.width-8) tooltip:"Maximum projected curve approximation error in world units. Smaller values create more vertices; import is limited to 8,192 samples. The receiver's Paint precision also sets a minimum."
        button importSpline "Pick spline..." width:(selected_brushUI.width-8) tooltip:"Pick one closed spline shape to apply to this Paint Area using Replace or Add. One Undo; Manual waits for Update. Stop the brush first."
        local toleranceInitialized=false
        fn saveFalloff = (
            if not binding and obj!=undefined and obj.paintDocument!=undefined do (
                local area=obj,cfg=cyrusBrushFalloff obj.paintDocument
                cfg[1]=insideSpin.value;cfg[2]=outsideSpin.value;cfg[3]=densityFade.checked;cfg[4]=scaleFade.checked
                cfg[5]=scaleMin.value;cfg[6]=scaleMax.value
                try(cyrusBrushSetFalloff area.paintDocument cfg;area.publishPaint())catch(messageBox (getCurrentException()) title:"Vector feather")
            )
        )
        fn status = (
            local text="Add or select a Paint Area."
            if obj!=undefined do (
                local state=if obj.paintDocument==undefined then undefined else cyrusBrushStats obj.paintDocument
                text=if state==undefined then "Choose this area's surface." else (if state[5]==1 then "Brush active" else "Brush stopped")+(if state[11]!="" then "\n"+state[11] else "")
                if owner!=undefined and not owner.paintEnabled do text+="\nWhole surfaces; areas retained."
            )
            if brushState.text==text then false else (brushState.text=text;true)
        )
        -- MAXScript resolves rollout function names in declaration order.
        -- Declare status first; an unbound forward call stops the paint timer.
        fn refreshBrushStatus = (status())
        fn saveOptions = (
            if not binding and obj!=undefined and obj.paintDocument!=undefined do (
                cyrusBrushSettings obj.paintDocument radiusSpin.value (modeRadio.state==2)
                cyrusBrushDisplay obj.paintDocument obj.paintView obj.paintColor
            )
        )
        fn bind layer = (
            binding=true;obj=layer
            local has=obj!=undefined and obj.paintDocument!=undefined
            for control in selected_brushUI.controls do control.enabled=obj!=undefined
            for control in #(stopButton,fillButton,emptyButton,insideSpin,outsideSpin,densityFade,scaleFade,densityCurve,scaleCurve,scaleMin,scaleMax,exportSpline,importSpline,importMode,splineTolerance) do control.enabled=has
            if not toleranceInitialized do (splineTolerance.value=units.decodeValue "1mm";toleranceInitialized=true)
            local target=if obj==undefined then undefined else obj.areaTarget
            targetInfo.text=if obj==undefined then "Add a Paint Area to begin." else obj.paintSetName+" / "+(if isValidNode target then target.name else "<choose surface>")
            beginButton.enabled=obj!=undefined and isValidNode target and findItem (owner.validSurfaces()) target>0
            if obj!=undefined do (densitySpin.value=obj.paintDensity*100;overlayMode.selection=findItem #(2,1,0) obj.paintView;overlayColor.color=obj.paintColor;obj.setOverlapOwner root)
            if has do (local cfg=cyrusBrushOptions obj.paintDocument;radiusSpin.value=cfg[1];modeRadio.state=if cfg[2] then 2 else 1
                local fade=cyrusBrushFalloff obj.paintDocument
                insideSpin.value=fade[1];outsideSpin.value=fade[2];densityFade.checked=fade[3];scaleFade.checked=fade[4];scaleMin.value=fade[5];scaleMax.value=fade[6])
            controlsReady=true;binding=false;status()
        )
        on beginButton pressed do if obj!=undefined do try (
            local controller=root,area=obj,options=#(radiusSpin.value,modeRadio.state)
            controller.setGroupCoverage area true
            cyrusBrushSettings area.paintDocument options[1] (options[2]==2)
            cyrusBrushDisplay area.paintDocument area.paintView area.paintColor
            CyrusStartBrush controller area
        )catch(messageBox (getCurrentException()) title:"Cyrus Brush")
        on stopButton pressed do (CyrusStopBrush();status())
        on modeRadio changed value do saveOptions()
        on radiusSpin changed value do saveOptions()
        on insideSpin changed value do saveFalloff()
        on outsideSpin changed value do saveFalloff()
        on densityFade changed value do saveFalloff()
        on scaleFade changed value do saveFalloff()
        on scaleMin changed value do saveFalloff()
        on scaleMax changed value do saveFalloff()
        on densityCurve pressed do if obj!=undefined do CyrusOpenFalloffGraph obj undefined true
        on scaleCurve pressed do if obj!=undefined do CyrusOpenFalloffGraph obj undefined false
        on densitySpin changed value do if not binding and obj!=undefined do (undo "Cyrus area density" on obj.paintDensity=value/100.0;owner.markInputDirty();obj.publishPaint())
        on overlayMode selected value do if not binding and obj!=undefined do (undo "Cyrus paint feedback" on obj.paintView=(#(2,1,0))[value];saveOptions();redrawViews())
        on overlayColor changed value do if not binding and obj!=undefined do (undo "Cyrus paint color" on obj.paintColor=value;saveOptions();redrawViews())
        on fillButton pressed do if obj!=undefined and obj.paintDocument!=undefined do (cyrusBrushFill obj.paintDocument 1.0;obj.publishPaint();status())
        on emptyButton pressed do if obj!=undefined and obj.paintDocument!=undefined do (cyrusBrushFill obj.paintDocument 0.0;obj.publishPaint();status())
        on exportSpline pressed do if controlsReady and not binding and obj!=undefined do (
            local controller=root,area=obj
            try(controller.exportPaintSpline area)catch(messageBox (getCurrentException()) title:"Paint to spline")
        )
        on importSpline pressed do if controlsReady and not binding and obj!=undefined do (
            local controller=root,area=obj,add=(importMode.state==2),tolerance=splineTolerance.value
            try (
                controller.validatePaintConversion area
                local node=pickObject prompt:("Import spline into "+area.paintSetName) filter:AminScatterAreaFilter
                if isValidNode node do controller.importPaintSpline area node add:add tolerance:tolerance
            )catch(messageBox (getCurrentException()) title:"Spline to Paint")
        )
        on selected_brushUI open do (root=this;controlsReady=false)
        on selected_brushUI close do (controlsReady=false;CyrusStopBrush())
    )

    rollout selected_randomUI "Random transforms - layer" width:#cmdPanel category:130 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined
        local setSpecific=false
        local binding=false,
        obj=undefined,parentView=undefined
        local controlsReady=false

        button presetsButton "Presets..." width:130 height:22 tooltip:"Save or apply named transforms settings. Assets and receiver references are preserved."
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
        fn syncControls = (projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMinWU;movXMaxSpin.value=obj.movXMaxWU;movYMinSpin.value=obj.movYMinWU;movYMaxSpin.value=obj.movYMaxWU;movZMinSpin.value=obj.movZMinWU;movZMaxSpin.value=obj.movZMaxWU;)
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
        on movXMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movXMinWU=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on movXMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movXMaxWU=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on movYMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movYMinWU=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on movYMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movYMaxWU=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on movZMinSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movZMinWU=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on movZMaxSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.movZMaxWU=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())



        fn bind layer = (
            local next=layer
            binding=true;controlsReady=false
            if obj!=next do ()
            obj=next;parentView=(CyrusContainerPanel root)
            for c in selected_randomUI.controls do c.enabled=layer!=undefined
            try (undo off ((wholeMinSpin.value=obj.wholeScaleMin;wholeMaxSpin.value=obj.wholeScaleMax;projectCheck.checked=obj.projectMove;rotXMinSpin.value=obj.rotXMin;rotXMaxSpin.value=obj.rotXMax;rotYMinSpin.value=obj.rotYMin;rotYMaxSpin.value=obj.rotYMax;rotZMinSpin.value=obj.rotZMin;rotZMaxSpin.value=obj.rotZMax;sclXMinSpin.value=obj.sclXMin;sclXMaxSpin.value=obj.sclXMax;sclYMinSpin.value=obj.sclYMin;sclYMaxSpin.value=obj.sclYMax;sclZMinSpin.value=obj.sclZMin;sclZMaxSpin.value=obj.sclZMax;movXMinSpin.value=obj.movXMinWU;movXMaxSpin.value=obj.movXMaxWU;movYMinSpin.value=obj.movYMinWU;movYMaxSpin.value=obj.movYMaxWU;movZMinSpin.value=obj.movZMinWU;movZMaxSpin.value=obj.movZMaxWU;controlsReady=true;alignCheck.checked=obj.alignNormal))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        on presetsButton pressed do try(CyrusOpenPresets root owner "transforms")catch(messageBox (getCurrentException()) title:"Cyrus presets")
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
        local controlsReady=false

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




        local pathRows=#(),strokeRows=#(),choiceValues=#(),loadingStroke=false,selectedPathID=0,selectedBandID=0
        label strokeTitle "Spline bands" pos:[4,118] width:(selected_diversityUI.width-8)
        listbox pathsList "Paths" items:#() pos:[4,142] width:(selected_diversityUI.width-8) height:3
        dropdownlist cornerMode "Path corners" items:#("Rounded","Sharp") pos:[4,150] width:(selected_diversityUI.width-8) tooltip:"Rounded uses Euclidean distance. Sharp uses bounded miter offsets; complex Paths may require simplification."
        dropdownlist arrangementMode "Band ranges" items:#("Consecutive","Independent") pos:[4,160] width:(selected_diversityUI.width-8) tooltip:"Consecutive accumulates widths. Independent permits overlapping Start/End ranges and uses a shared candidate population."
        dropdownlist analyzerChannel "Analyzer data" items:#("Border","Centerline","Points","Street Side","Edge Border") pos:[4,142] width:(selected_diversityUI.width-8)
        pickbutton pickAnalyzer "Pick Surface Analyzer" filter:CyrusAnalyzerFilter pos:[4,192] width:(selected_diversityUI.width-8) tooltip:"Use Surface Analyzer output for bands, rows and fixed anchors."
        pickbutton pickPath "Add: pick closed line" filter:AminScatterAreaFilter pos:[4,192] width:(selected_diversityUI.width-8) tooltip:"Pick a spline for Line Pattern assignment."
        button removePath "Remove path" pos:[4,218] width:(selected_diversityUI.width-8) tooltip:"Remove the selected assignment path while keeping the scene spline."
        listbox strokesList "Bands" items:#() pos:[4,250] width:(selected_diversityUI.width-8) height:4
        button addOutside "Add Outside" pos:[4,346] width:((selected_diversityUI.width-12)/2) tooltip:"Add a source-assignment band outside the selected path."
        button addInside "Add Inside" pos:[(if boundaryOnly then 4 else selected_diversityUI.width/2+2),346] width:(if boundaryOnly then selected_diversityUI.width-8 else (selected_diversityUI.width-12)/2) tooltip:"Add a source-assignment band inside the selected path."
        button removeStrokeButton "Remove band" pos:[4,372] width:(selected_diversityUI.width-8) tooltip:"Remove the selected band and its settings."
        spinner strokeWidth "Width:" range:[0.001,100000,1] type:#worldUnits pos:[4,406] width:(selected_diversityUI.width-8) fieldWidth:82
        spinner bandStart "Start:" range:[0,100000,0] type:#worldUnits pos:[4,410] width:(selected_diversityUI.width-8) fieldWidth:82 tooltip:"Independent range starts at this physical distance from its Path."
        spinner bandEnd "End:" range:[0.001,100000,1] type:#worldUnits pos:[4,412] width:(selected_diversityUI.width-8) fieldWidth:82 tooltip:"Independent range must end after Start."
        spinner bandStrength "Density %:" range:[0,100,100] pos:[4,414] width:(selected_diversityUI.width-8) fieldWidth:82 tooltip:"Band contribution before other masks and spacing. Independent overlaps share one candidate population."
        checkbox bandCurveCheck "Density curve" pos:[4,416] width:(selected_diversityUI.width-8) tooltip:"Use the saved sampled density curve from Start to End."
        dropdownlist bandScaleMode "Scale profile" items:#("Off","Follow Density","Custom") selection:1 pos:[4,646] width:(selected_diversityUI.width-8) tooltip:"Multiply the random Band size by the effective density curve shape or an independent Custom scale curve. Density % is not a size multiplier."
        button bandScaleEdit "Edit scale curve" pos:[4,674] width:(selected_diversityUI.width-8) tooltip:"Size multiplier across this Band. 100% preserves size; zero collapses size without deleting the placement. Edit in Custom mode."
        button bandCurveEdit "Edit curve" pos:[4,418] width:(selected_diversityUI.width-8) tooltip:"Edit this Band by its captured identity. Changes apply on drag release, Apply or Close."
        colorpicker bandColor "Band color:" color:white pos:[4,420] width:(selected_diversityUI.width-8) tooltip:"Identification color belongs to this Band. It never changes placements or source materials."
        checkbox fieldFalloffCheck "Preview Falloff" pos:[4,422] width:(selected_diversityUI.width-8) tooltip:"Sample Band density on receiver surfaces before other masks, spacing and cleanup. This never changes plant counts."
        checkbox fieldBoundaryCheck "Show Boundaries" pos:[4,424] width:(selected_diversityUI.width-8) tooltip:"Show admitted start/end contours clipped to every receiver surface, including stacked and vertical receivers."
        dropdownlist fieldView "Field view" items:#("Selected Band","Combined density") pos:[4,426] width:(selected_diversityUI.width-8) tooltip:"Selected Band shows its contribution. Combined shows capped total occupancy."
        spinner fieldSampleSpin "Field samples:" range:[1,20000,4000] type:#integer pos:[4,428] width:(selected_diversityUI.width-8) fieldWidth:72 tooltip:"Bounded visualization samples; sparse coverage can miss narrow intervals. Show Boundaries preserves admitted outlines."
        label fieldLegend "Band density before masks/spacing/cleanup\n0% blue | 100% red | boundaries white" pos:[4,430] width:(selected_diversityUI.width-8) height:40
        label fieldInfo "Preview hidden." pos:[4,432] width:(selected_diversityUI.width-8) height:88
        button bandUp "Move up" pos:[4,422] width:65 tooltip:"Move the selected Band up on its Path. Consecutive priority and ranges follow authored order."
        button bandDown "Move down" pos:[72,422] width:65 tooltip:"Move the selected Band down on its Path. Independent decisions keep stable Band identities."
        label bandAssignmentHelp "Models used by this Band" pos:[4,430] width:(selected_diversityUI.width-8) height:18
        radiobuttons strokeMode "Select from" labels:#("Assignment groups","Models / Points") columns:1 pos:[4,434] width:(selected_diversityUI.width-8)
        multiListBox strokeChoices "Click to toggle" items:#() pos:[4,506] width:(selected_diversityUI.width-8) height:5
        spinner strokeScaleMin "Scale min:" tooltip:"Additional Band multiplier, combined once with source, layer and transform scale." range:[0.001,100,1] pos:[4,618] width:(selected_diversityUI.width-8) fieldWidth:82
        spinner strokeScaleMax "Scale max:" tooltip:"Additional Band multiplier; it does not change the source asset or its base Scale setting." range:[0.001,100,1] pos:[4,644] width:(selected_diversityUI.width-8) fieldWidth:82
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
        fn selectedPathSlot = (findItem obj.pathIDs selectedPathID)
        fn selectedPathNode = (local slot=selectedPathSlot();if slot>0 then obj.patternPaths[slot] else undefined)
        fn selectedStroke = (findItem obj.strokeIDs selectedBandID)
        fn refreshFieldInfo = (if obj!=undefined do fieldInfo.text=obj.fieldPreviewStatus())
        fn changeFieldDisplay key value = (
            local savedOwner=obj,controller=if obj.overlapOwner==undefined then obj else obj.overlapOwner
            undo "Cyrus field display" on setProperty savedOwner key value
            controller.refreshDisplay()
            if obj==savedOwner do refreshFieldInfo()
        )
        fn choiceColor index = (
            if index<1 or index>choiceValues.count do return (color 128 128 128)
            local row=selectedStroke()
            if row>0 and obj.strokeModes[row]==1 then (
                local key=choiceValues[index]
                for i=1 to obj.sources.count where obj.colorKey(obj.sourceColor i)==key do return obj.sourceColor i
            ) else (
                local source=findItem obj.sourceRowIDs choiceValues[index]
                if source>0 do return obj.sourceIDColor source
            )
            color 128 128 128
        )
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
            for c in #(strokeWidth,strokeMode,strokeChoices,strokeScaleMin,strokeScaleMax,removeStrokeButton,bandStart,bandEnd,bandStrength,bandCurveCheck,bandCurveEdit,bandScaleMode,bandScaleEdit,bandColor,bandUp,bandDown) do c.enabled=active
            local ordinary=obj.diversityMode==3
            for c in #(bandStart,bandEnd) do c.visible=ordinary and obj.bandArrangement==2
            strokeWidth.visible=not ordinary or obj.bandArrangement==1
            for c in #(bandStrength,bandCurveCheck,bandCurveEdit,bandScaleMode,bandScaleEdit,bandColor,bandUp,bandDown) do c.visible=ordinary
            bandAssignmentHelp.visible=ordinary
            for c in #(fieldFalloffCheck,fieldBoundaryCheck,fieldView,fieldSampleSpin,fieldLegend,fieldInfo) do c.visible=ordinary
            fieldFalloffCheck.checked=obj.fieldFalloff;fieldBoundaryCheck.checked=obj.fieldBoundaries
            fieldView.selection=if obj.fieldCombined then 2 else 1;fieldSampleSpin.value=obj.fieldSamples
            fieldView.enabled=ordinary;fieldSampleSpin.enabled=ordinary and obj.fieldFalloff
            if ordinary and not binding and obj.fieldBandID!=selectedBandID do undo off obj.fieldBandID=selectedBandID
            refreshFieldInfo()
            if active and ordinary do (
                bandStart.value=obj.strokeStarts[row];bandEnd.value=obj.strokeEnds[row]
                bandStrength.value=obj.strokeStrengths[row]*100;bandCurveCheck.checked=obj.strokeCurveEnabled[row];bandCurveEdit.enabled=bandCurveCheck.checked
                bandScaleMode.selection=obj.strokeScaleModes[row];bandScaleEdit.enabled=obj.strokeScaleModes[row]==3
                bandColor.color=obj.strokeDisplayColors[row]
                local rank=findItem strokeRows row;bandUp.enabled=rank>1;bandDown.enabled=rank>0 and rank<strokeRows.count
            )
            choiceValues=#();strokeChoices.items=#()
            for c in #(edgeOffsetSpin,edgeAlongSpin,edgeAcrossSpin,edgeRotXSpin,edgeRotYSpin,edgeRotZSpin) do c.enabled=active
            if active do (
                edgeRotXSpin.value=obj.edgeRotX[row]
                edgeRotYSpin.value=obj.edgeRotY[row]
                edgeRotZSpin.value=obj.edgeRotZ[row]
                edgeOffsetSpin.value=obj.edgeOffsetsWU[row];edgeAlongSpin.value=obj.edgeAlongWU[row];edgeAcrossSpin.value=obj.edgeAcrossWU[row]
                strokeWidth.value=obj.patternWidths[row];strokeMode.state=obj.strokeModes[row]
                strokeWidth.enabled=obj.strokeSides[row]!=5
                strokeScaleMin.value=obj.strokeMin[row];strokeScaleMax.value=obj.strokeMax[row]
                local labels=#();local selectedRows=#{}
                if obj.strokeModes[row]==1 then (
                    for i=1 to obj.sources.count do (
                        local key=obj.colorKey(obj.sourceColor i)
                        if findItem choiceValues key==0 do (append choiceValues key;append labels ("Group "+(choiceValues.count as string)))
                    )
                    local keys=for i=1 to obj.strokeColorRows.count where obj.strokeColorRows[i]==row collect obj.strokeColorKeys[i]
                    for i=1 to choiceValues.count where findItem keys choiceValues[i]>0 do selectedRows[i]=true
                ) else (
                    for i=1 to obj.sources.count where obj.isEmptySource i or obj.usableSource obj.sources[i] do (append choiceValues obj.sourceRowIDs[i];append labels (obj.sourceLabel i))
                    for i=1 to obj.strokeSourceRows.count where obj.strokeSourceRows[i]==row do (
                        local k=findItem choiceValues obj.strokeSourceIDs[i];if k>0 do selectedRows[k]=true
                    )
                )
                strokeChoices.items=labels;strokeChoices.selection=selectedRows
            )
            loadingStroke=false
            if obj.diversityMode>=3 do (
                local analyzed=obj.diversityMode==4
                strokeHelp.text=if analyzed then "Width is spread per side; spacing and masks still apply." else if obj.bandArrangement==2 then "Overlaps combine density; each candidate chooses at most one Band." else "Empty Bands reserve their intervals. First geometric match wins."
                local guideReady=if analyzed then isValidNode obj.analyzerNode else isValidNode (selectedPathNode())
                if not guideReady then strokeHelp.text=if analyzed then "Pick an Analyzer to begin." else "Pick a closed spline to begin."
                else if strokeRows.count==0 then strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "Add an edge row, then choose models." else "Add a band, then choose models."
                else if selectedStroke()>0 and strokeChoices.selection.numberSet==0 then strokeHelp.text="Choose models or groups for this band."
                else if analyzed and analyzerChannel.selection==5 then strokeHelp.text="Spacing controls row count. Amount 0 disables output."
                else if analyzed and analyzerChannel.selection==3 and obj.strokeSides[selectedStroke()]==5 then strokeHelp.text="Analyzer points control count. Amount 0 disables output."
            )
        )
        fn showPath = (
            loadingStroke=true
            strokeRows=#();local labels=#(),analyzed=obj.diversityMode==4,path=if obj.diversityMode==4 then obj.analyzerNode else selectedPathNode()
            local pathSlot=selectedPathSlot()
            if not analyzed and pathSlot>0 do cornerMode.selection=obj.pathJoins[pathSlot]
            cornerMode.enabled=not analyzed and pathSlot>0
            arrangementMode.selection=obj.bandArrangement
            for i=1 to obj.patternLines.count where (if analyzed then isValidNode path and obj.patternLines[i]==path else obj.strokePathIDs[i]==selectedPathID) and (not analyzed or (analyzerChannel.selection==1 and obj.strokeSides[i]<=2) or (analyzerChannel.selection==2 and obj.strokeSides[i]==3) or (analyzerChannel.selection==3 and (obj.strokeSides[i]==4 or obj.strokeSides[i]==5)) or (analyzerChannel.selection==4 and obj.strokeSides[i]==6) or (analyzerChannel.selection==5 and obj.strokeSides[i]==7)) do (
                append strokeRows i
                local interval=obj.bandInterval i,label=obj.bandName i
                label+=if obj.strokeSides[i]==7 then ": spacing "+units.formatValue obj.patternWidths[i] else ": "+units.formatValue interval[1]+" - "+units.formatValue interval[2]
                if not analyzed and obj.bandAssignmentCount i==0 do label+=" | empty"
                if not isValidNode path do label+=" | inactive"
                append labels label
            )
            strokesList.items=labels
            local rank=0
            for j=1 to strokeRows.count where obj.strokeIDs[strokeRows[j]]==selectedBandID do rank=j
            if rank==0 and strokeRows.count>0 do rank=1
            strokesList.selection=rank;selectedBandID=if rank>0 then obj.strokeIDs[strokeRows[rank]] else 0
            addOutside.enabled=isValidNode path and (not analyzed or analyzerChannel.selection==2 or analyzerChannel.selection==3);addInside.enabled=isValidNode path and (not analyzed or analyzerChannel.selection!=2)
            removePath.enabled=if analyzed then isValidNode path else pathSlot>0
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
            obj.syncStrokes()
            local analyzed=obj.diversityMode==4
            pathRows=for i=1 to obj.patternPaths.count where not isValidNode obj.patternPaths[i] or not isProperty obj.patternPaths[i] #samplePoints collect obj.pathIDs[i]
            pathsList.items=for id in pathRows collect (
                local slot=findItem obj.pathIDs id,node=obj.patternPaths[slot],count=0
                for value in obj.strokePathIDs where value==id do count+=1
                (if isValidNode node then node.name else "Missing / inactive Path #"+(id as string))+" | "+(count as string)+(if count==1 then " Band" else " Bands")
            )
            local selected=findItem pathRows selectedPathID
            if selected==0 and pathRows.count>0 do selected=1
            pathsList.selection=selected;selectedPathID=if selected>0 then pathRows[selected] else 0
            for control in #(pathsList,pickPath,cornerMode,arrangementMode) do control.visible=obj.diversityMode==3
            analyzerChannel.visible=analyzed;pickAnalyzer.visible=analyzed
            pickAnalyzer.text=if isValidNode obj.analyzerNode then obj.analyzerNode.name else "Pick Surface Analyzer"
            removePath.text="×";removePath.tooltip=if analyzed then "Remove the linked Analyzer assignment." else "Remove the selected Path and its Bands; keep the scene spline."
            pickPath.enabled=not analyzed
            strokeTitle.text=if analyzed then "Analyzer bands / rows" else "Spline bands"
            addOutside.text="↗";addOutside.tooltip=if not analyzed then "Add Outside Band." else if analyzerChannel.selection==2 then "Add Centerline Band." else "Add Radius Band."
            addInside.text="↙";addInside.tooltip=if analyzed and analyzerChannel.selection==3 then "Add Single anchor assignment." else "Add Inside Band."
            boundaryOnly=analyzed and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5)
            addOutside.visible=(obj.diversityMode==3 or analyzed) and not boundaryOnly
            addInside.pos=[if boundaryOnly then 4 else selected_diversityUI.width/2+2,addOutside.pos.y]
            addInside.width=if boundaryOnly then selected_diversityUI.width-8 else (selected_diversityUI.width-12)/2
            if boundaryOnly do addInside.tooltip=if analyzerChannel.selection==5 then "Add Edge Row." else "Add Band inside."
            strokeHelp.text=if analyzed and analyzerChannel.selection==5 then "One row along the boundary." else if analyzed then "Width = spread per side." else if obj.bandArrangement==2 then "Overlaps combine density; each candidate chooses at most one Band." else "Empty Bands reserve their intervals. First geometric match wins."
            showPath()

        )

        on pathsList selected i do if controlsReady and not binding and not loadingStroke and obj!=undefined do (selectedPathID=if i>0 and i<=pathRows.count then pathRows[i] else 0;selectedBandID=0;showPath();CyrusViewportRedraw())
        on analyzerChannel selected i do if controlsReady and not binding and obj!=undefined do updatePattern()
        on pickAnalyzer picked n do if controlsReady and not binding and obj!=undefined do (
            if CyrusAnalyzerFilter n do (obj.analyzerNode=n;obj.markInputDirty();updatePattern();CyrusViewportRedraw())
        )
        on strokesList selected i do if controlsReady and not binding and not loadingStroke and obj!=undefined do (selectedBandID=if i>0 and i<=strokeRows.count then obj.strokeIDs[strokeRows[i]] else 0;showStroke();CyrusViewportRedraw())
        on pickPath picked n do if controlsReady and not binding and obj!=undefined and obj.diversityMode==3 do (
            local savedOwner=obj,id=0
            if isValidNode n do undo "Cyrus add Path" on (id=savedOwner.addBandPath n)
            if controlsReady and obj==savedOwner do (selectedPathID=id;selectedBandID=0;updatePattern())
        )
        on removePath pressed do if controlsReady and not binding and obj!=undefined do (
            local savedOwner=obj,id=selectedPathID
            if savedOwner.diversityMode==4 then (
                local path=savedOwner.analyzerNode
                undo "Cyrus remove Analyzer assignment" on (
                    for i=savedOwner.patternLines.count to 1 by -1 where savedOwner.patternLines[i]==path do savedOwner.removeStroke i
                    savedOwner.analyzerNode=undefined
                )
            ) else savedOwner.removeBandPath id
            if controlsReady and obj==savedOwner do (selectedPathID=0;selectedBandID=0;updatePattern();syncControls())
            savedOwner.markInputDirty();CyrusViewportRedraw()
        )
        on addOutside pressed do if controlsReady and not binding and obj!=undefined do (
            if obj.diversityMode==4 and (analyzerChannel.selection==1 or analyzerChannel.selection==4 or analyzerChannel.selection==5) do return false
            local path=if obj.diversityMode==4 then obj.analyzerNode else selectedPathNode()
            local types=#(1,3,4)
            local side=if obj.diversityMode==4 then types[analyzerChannel.selection] else 1
            local savedOwner=obj,row=0;undo "Cyrus add Band" on (row=savedOwner.addStroke path side:side);if controlsReady and obj==savedOwner do (selectedBandID=savedOwner.strokeIDs[row];updatePattern());CyrusViewportRedraw()
        )
        on addInside pressed do if controlsReady and not binding and obj!=undefined do (
            local path=if obj.diversityMode==4 then obj.analyzerNode else selectedPathNode()
            local side=if obj.diversityMode==4 and analyzerChannel.selection==5 then 7 else if obj.diversityMode==4 and analyzerChannel.selection==4 then 6 else if obj.diversityMode==4 and analyzerChannel.selection==3 then 5 else 2
            local savedOwner=obj,row=0;undo "Cyrus add Band" on (row=savedOwner.addStroke path side:side);if controlsReady and obj==savedOwner do (selectedBandID=savedOwner.strokeIDs[row];updatePattern());CyrusViewportRedraw()
        )
        on removeStrokeButton pressed do if controlsReady and not binding and obj!=undefined do (
            local savedOwner=obj,row=selectedStroke()
            if row>0 do undo "Cyrus remove Band" on (savedOwner.removeStroke row)
            if controlsReady and obj==savedOwner do (selectedBandID=0;updatePattern())
            CyrusViewportRedraw()
        )
        on cornerMode selected v do if controlsReady and not binding and not loadingStroke and obj!=undefined do (local slot=selectedPathSlot();if slot>0 do undo "Cyrus Path corners" on (obj.pathJoins[slot]=v);CyrusViewportRedraw())
        on arrangementMode selected v do if controlsReady and not binding and not loadingStroke and obj!=undefined do (
            local savedOwner=obj,approved=true
            if v==1 and savedOwner.bandArrangement==2 do (
                local proposal=savedOwner.consecutiveBandProposal()
                if not proposal[1] do (
                    local message="Consecutive mode removes independent offsets/overlap. Proposed ranges:\n"
                    for row in proposal[2] do message+=("Band #"+(row[1] as string)+": "+units.formatValue row[2]+" - "+units.formatValue row[3]+"\n")
                    approved=queryBox message title:"Convert Band ranges"
                )
            )
            if approved do savedOwner.convertBandArrangement v acceptChanges:true
            if controlsReady and obj==savedOwner do updatePattern()
            CyrusViewportRedraw()
        )
        on bandStart changed v do if controlsReady and not binding and not loadingStroke and obj!=undefined do (local row=selectedStroke();if row>0 do (obj.strokeStarts[row]=v;showPath());CyrusViewportRedraw())
        on bandEnd changed v do if controlsReady and not binding and not loadingStroke and obj!=undefined do (local row=selectedStroke();if row>0 do (obj.strokeEnds[row]=v;showPath());CyrusViewportRedraw())
        on bandStrength changed v do if controlsReady and not binding and not loadingStroke and obj!=undefined do (local row=selectedStroke();if row>0 do obj.strokeStrengths[row]=v/100.0;CyrusViewportRedraw())
        on bandCurveCheck changed v do if controlsReady and not binding and not loadingStroke and obj!=undefined do (local row=selectedStroke();if row>0 do obj.strokeCurveEnabled[row]=v;showStroke();CyrusViewportRedraw())
        fn setBandScaleProfile v = (
            if not controlsReady or binding or loadingStroke or obj==undefined do return false
            if v<1 or v>3 do throw "Unknown Band scale profile."
            local row=selectedStroke();if row<1 do return false
            CyrusRequireAuthor()
            undo "Cyrus Band scale profile" on obj.strokeScaleModes[row]=v
            showStroke();CyrusViewportRedraw();true
        )
        on bandScaleMode selected v do setBandScaleProfile v
        on bandScaleEdit pressed do if controlsReady and not binding and obj!=undefined and selectedStroke()>0 and obj.strokeScaleModes[selectedStroke()]==3 do CyrusOpenFalloffGraph obj undefined false bandID:selectedBandID
        on bandCurveEdit pressed do if controlsReady and not binding and obj!=undefined and selectedStroke()>0 do CyrusOpenFalloffGraph obj undefined true bandID:selectedBandID
        on bandColor changed v do if controlsReady and not binding and not loadingStroke and obj!=undefined do (local row=selectedStroke();if row>0 do obj.strokeDisplayColors[row]=v;CyrusViewportRedraw())
        on fieldFalloffCheck changed v do if controlsReady and not binding and not loadingStroke and obj!=undefined do changeFieldDisplay #fieldFalloff v
        on fieldBoundaryCheck changed v do if controlsReady and not binding and not loadingStroke and obj!=undefined do changeFieldDisplay #fieldBoundaries v
        on fieldView selected v do if controlsReady and not binding and not loadingStroke and obj!=undefined do changeFieldDisplay #fieldCombined (v==2)
        on fieldSampleSpin changed v do if controlsReady and not binding and not loadingStroke and obj!=undefined do changeFieldDisplay #fieldSamples v
        fn moveSelectedBand direction = (
            local row=selectedStroke(),rank=findItem strokeRows row,savedOwner=obj
            if rank+direction<1 or rank+direction>strokeRows.count do return false
            savedOwner.moveBand selectedBandID strokeRows[rank+direction]
            if controlsReady and obj==savedOwner do updatePattern()
            CyrusViewportRedraw();true
        )
        on bandUp pressed do if controlsReady and not binding and obj!=undefined do moveSelectedBand -1
        on bandDown pressed do if controlsReady and not binding and obj!=undefined do moveSelectedBand 1
        on edgeOffsetSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeOffsetsWU[row]=v;CyrusViewportRedraw())
        on edgeAlongSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAlongWU[row]=v;CyrusViewportRedraw())
        on edgeAcrossSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeAcrossWU[row]=v;CyrusViewportRedraw())
        on keepCornerCheck changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (obj.edgeKeepCorners=v;cornerAngleSpin.enabled=v;cornerCountSpin.enabled=v;CyrusViewportRedraw())
        on cornerAngleSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (obj.edgeCornerAngle=v;CyrusViewportRedraw())
        on cornerCountSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (obj.edgeCornerCount=v;CyrusViewportRedraw())
        on edgeRotXSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotX[row]=v;CyrusViewportRedraw())
        on edgeRotYSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotY[row]=v;CyrusViewportRedraw())
        on edgeRotZSpin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.edgeRotZ[row]=v;CyrusViewportRedraw())
        on strokeWidth changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.patternWidths[row]=v;obj.markInputDirty();showPath();CyrusViewportRedraw())
        on strokeMode changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();if row>0 do obj.strokeModes[row]=v;showStroke();obj.markInputDirty();syncControls();CyrusViewportRedraw())
        fn setBandChoices indices = (
            if not controlsReady or binding or loadingStroke or obj==undefined do return false
            local savedOwner=obj,row=selectedStroke()
            if row<1 do return false
            CyrusRequireAuthor()
            local values=for i in indices where i>0 and i<=choiceValues.count collect choiceValues[i]
            undo "Cyrus Band assignment" on savedOwner.setStrokeSelection row savedOwner.strokeModes[row] values
            CyrusViewportRedraw();true
        )
        on strokeChoices selectionEnd do setBandChoices strokeChoices.selection
        on strokeScaleMin changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();obj.strokeMin[row]=v;if v>obj.strokeMax[row] do obj.strokeMax[row]=v;showStroke();obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on strokeScaleMax changed v do if controlsReady and not binding and obj!=undefined do if not loadingStroke do (local row=selectedStroke();obj.strokeMax[row]=v;if v<obj.strokeMin[row] do obj.strokeMin[row]=v;showStroke();obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on refreshGroups pressed do if controlsReady and not binding and obj!=undefined do updatePattern()
        -- The composed page owns mode visibility and lays out once after this
        -- event. Do not show/hide obsolete component rows or reflow other pages.
        on diversityRadio changed v do if controlsReady and not binding and obj!=undefined do (obj.diversityMode=v;updatePattern();obj.markInputDirty();syncControls();CyrusViewportRedraw())


        on sizeSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.diversitySize=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on divSeedSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.diversitySeed=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on roughSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.roughness=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on blurSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.blurryEdge=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())
        on noiseSpin changed v do if controlsReady and not binding and obj!=undefined do (obj.diversityNoise=v;obj.markInputDirty();syncControls();CyrusViewportRedraw())



        fn bind layer = (
            local next=layer
            binding=true;controlsReady=false
            if obj!=next do (
                selectedBandID=if next==undefined then 0 else next.fieldSelectedID()
                local row=if next==undefined then 0 else findItem next.strokeIDs selectedBandID
                selectedPathID=if row>0 then next.strokePathIDs[row] else 0
                strokesList.selection=0;strokeChoices.selection=0
            )
            if next!=undefined and next.fieldSelectedID()>0 do (
                selectedBandID=next.fieldSelectedID()
                selectedPathID=next.strokePathIDs[findItem next.strokeIDs selectedBandID]
            )
            obj=next;parentView=(CyrusContainerPanel root)
            for c in selected_diversityUI.controls do c.enabled=layer!=undefined
            try (undo off ((diversityRadio.state=obj.diversityMode;sizeSpin.value=obj.diversitySize;divSeedSpin.value=obj.diversitySeed;roughSpin.value=obj.roughness;blurSpin.value=obj.blurryEdge;noiseSpin.value=obj.diversityNoise;controlsReady=true;updatePattern()))) catch(binding=false;controlsReady=true;throw())
            controlsReady=true;binding=false
        )
        on selected_diversityUI open do (root=this;controlsReady=false)
        on selected_diversityUI close do controlsReady=false
        on selected_diversityUI rolledUp state do (CyrusContainerPanel root).bindSection selected_diversityUI
    )
    rollout selected_proceduralUI "Spacing rules - selected scope" width:146 category:150 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined,controlsReady=false,binding=false,setSpecific=true,peers=#(),scopeRows=#(1,4)
        button presetsButton "Presets..." width:130 height:22 tooltip:"Save or apply named spacing settings. Assets and receiver references are preserved."
        dropdownlist scopeList "Spacing scope" items:#("Within this layer","Between layers") pos:[4,12] width:(selected_proceduralUI.width-8) selection:1 tooltip:"Choose spacing within the selected layer or between it and another layer."
        dropdownlist peerList "Other owner" items:#() pos:[4,64] width:(selected_proceduralUI.width-8)
        checkbox enabledCheck "Enable this spacing" pos:[4,118] width:(selected_proceduralUI.width-8)
        spinner multiplierSpin "Radius factor:" range:[0,10000,1] pos:[4,146] width:(selected_proceduralUI.width-8) fieldWidth:82
        spinner gapSpin "Extra gap:" range:[0,1e9,0] type:#worldUnits pos:[4,174] width:(selected_proceduralUI.width-8) fieldWidth:82
        checkbox planarCheck "XY distance (off = 3D)" pos:[4,202] width:(selected_proceduralUI.width-8)
        label ruleInfo "Factor x (radius A + radius B) + gap" pos:[4,230] width:(selected_proceduralUI.width-8) height:40
        button resetRule "Use inherited / default" pos:[4,274] width:(selected_proceduralUI.width-8)
        fn currentScope = (if scopeList.selection>0 and scopeList.selection<=scopeRows.count then scopeRows[scopeList.selection] else 1)
        fn currentSet = (owner)
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
                    if i>0 then rule=#(root.procRuleEnabled[i],root.procRuleMultiplier[i],root.procRuleGapWU[i],root.procRulePlanar[i])
                    else if scope==3 do rule=#(owner.procSiblingEnabled,owner.procSiblingMultiplier,owner.procSiblingGap,owner.procSiblingPlanar)
                )
                enabledCheck.checked=rule[1];multiplierSpin.value=rule[2];gapSpin.value=rule[3];planarCheck.checked=rule[4]
                ruleInfo.text=if not editable then "Add another owner for a pair rule." else if scope==1 and not leaf.procSelfOverride then "Using the saved default. Changing a value creates an override." else "Factor x (radius A + radius B) + gap. Saves automatically."
                binding=wasBinding
            )catch(binding=wasBinding;throw())
        )
        fn bind layer = (
            binding=true
            local previous=currentScope()
            scopeRows=#(1,4)
            scopeList.items=#("Within this layer","Between layers")
            scopeList.selection=amax 1 (findItem scopeRows previous)
            bindRule();controlsReady=true;binding=false
        )
        on presetsButton pressed do try(
            local peer=undefined
            if currentScope()==4 do (
                if peerList.selection<1 or peerList.selection>peers.count do throw "Select another layer for the spacing pair."
                peer=peers[peerList.selection]
            )
            CyrusOpenPresets root owner "spacing" peer:peer
        )catch(messageBox (getCurrentException()) title:"Cyrus presets")
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
        button applyRadius "Set selected radii" pos:[4,88] width:(selected_instanceRadiusUI.width-8) tooltip:"Apply radius overrides to selected instances in this layer."
        button resetRadius "Clear selected overrides" pos:[4,116] width:(selected_instanceRadiusUI.width-8) tooltip:"Restore the selected instances' inherited source radii."
        button clearRadius "Clear radius overrides" pos:[4,144] width:(selected_instanceRadiusUI.width-8) tooltip:"Remove instance-radius overrides for this layer."
        label info "Select instances with CS Edit before applying a radius. Overrides follow their stable instance identities." pos:[4,180] width:(selected_instanceRadiusUI.width-8) height:54
        fn currentSet = (owner)
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
        fn refreshStats = (
            local text=CyrusUIResultText root owner
            if info.text==text do return false
            info.text=text;info.height=amax 300 ((filterString text "\n").count*17+20);selected_detailsUI.height=info.height+86;true
        )
        fn bind layer = (refreshStats();controlsReady=true)
        on selected_detailsUI open do (root=this;controlsReady=false)
        on selected_detailsUI close do controlsReady=false
        on refreshButton pressed do bind owner
        on helpButton pressed do messageBox (info.text+"\n\nLayers own surfaces, models, population and transforms. Paint Areas bind individual surfaces and union vector coverage. Feather curves control density and multiply random scale. Include/Exclude and collision rules still apply.\n\nManual retains the previous complete build until Update. Live updates relevant edits. Failed builds preserve the last complete result. Vector painting supports local XY terrain and planes; closed or overlapping receivers are rejected.") title:"Cyrus layer help"
        on selected_detailsUI rolledUp state do (CyrusContainerPanel root).bindSection selected_detailsUI
    )

    rollout selected_workflowUI "Workflow and ownership" width:#cmdPanel category:200 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined,controlsReady=false
        label steps "1. LAYERS + SURFACES\nChoose a layer and its receiving surfaces. Layers calculate in their listed order.\n\n2. MODELS + POINTS\nAdd models or Points to the layer. Source rectangles can collect models; parked models keep their saved settings.\n\n3. LAYOUT + AMOUNT\nChoose the layout and the layer's count or density. Paint Areas share this population. Accepted target retries within explicit limits.\n\n4. OPTIONAL PAINTING\nEach Paint Area belongs to one receiver. Painted regions combine coverage without duplicating placements. Include/Exclude limits still apply.\n\n5. TRANSFORMS + SPACING\nLayer transforms apply to its placements. Configure Within this layer and Between layers independently. Protected edits reserve space.\n\n6. UPDATE + INSPECT\nManual keeps the last completed result until Update scatter. Live follows relevant edits. Hidden layers still calculate; disabled layers do not. Statistics separate accepted placements from prepared preview samples." pos:[4,8] width:(selected_workflowUI.width-8) height:500
        label help "The editor stays on this Scatter when scene selection changes. Use the Layer selector to change the recipe and the Paint Area selector to edit its coverage. Hover buttons and numeric fields for short explanations.\n\nPoint Cloud samples and viewport budgets affect display. They are not plant counts or a promise of presented FPS." pos:[4,516] width:(selected_workflowUI.width-8) height:120
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
        if version!=58 do procSchemaValid=false
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
            if not CyrusLicenseCanEdit() do return #abort
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
    if CyrusPreviewActivity!=undefined do CyrusPreviewActivity held
    if not held do for watch in CyrusViewportAnalyzers do (
        if not isValidNode watch[1] or watch[1].getAnalysisRuns()!=watch[2] do CyrusViewportRecordsDirty=true
    )
    if CyrusViewportRecordsDirty and not CyrusPointBusy do (
        if held then (CyrusWasDragging=true;CyrusScheduleRelease()) else CyrusPointSync()
    )
    gw.setTransform (matrix3 1)
    -- Empty/new controllers have no published placement record yet. Draw their
    -- lightweight icons from the node registry, including during mouse sizing;
    -- discovering an icon must not rebuild or publish any layer's scatter.
    for n in CyrusTimeOwners where isValidNode n and not n.isHidden do (
        gw.setTransform n.objectTransform;gw.setColor #line red
        for path in n.baseObject.iconLines() do gw.polyline path false
    )
    gw.setTransform (matrix3 1)
    for record in CyrusViewportRecords where isValidNode record[1] and not record[1].isHidden do (
        local n=record[1],owner=record[2],caches=record[3],styles=record[4]
        for fallback in record[5] do aminScatterDrawPreview fallback[1] fallback[2] fallback[3]
        local ready=false
        if (CyrusPointEnabled or CyrusMeshEnabled) and isValidNode owner do try(ready=cyrusRetainedMatches owner caches styles)catch(CyrusPointLastError=getCurrentException())
        if not ready do (
            for i=1 to caches.count do aminScatterDrawPreview caches[i] styles[i][1] styles[i][2]
            if caches.count>0 and CyrusPointAvailable and not CyrusPointSuspended do (
                local failed=false
                if isValidNode owner do try(failed=(cyrusRetainedStats owner)[12]==2)catch()
                if failed do CyrusPointLastError="GPU preview unavailable; showing bounded centre markers. Refresh preview to retry."
                -- Submission can be delayed indefinitely for a hidden native
                -- helper. Give a new publication two presentation-only redraws,
                -- then retain its fallback until a real event/explicit refresh.
                -- Never turn missing GPU readiness into another scene sync.
                if not failed and record[6]>0 do (
                    record[6]-=1;CyrusPointPresentationPending=true;CyrusScheduleRelease()
                )
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
   format "Enabled:%|" r.cyrusEnabled to:s
   for layer in r.layerObjects do format "Brush:%:%:%|" layer.paintEnabled layer.paintDensity (layer.paintKey()) to:s
   format "|Edit:%|" (CyrusEditStackKey r) to:s
   format "%|%|%|%|%|" n.handle n.isHidden r.autoRender r.layerEnabled r.updateMode to:s
   for obj in r.layerObjects do format "Analyzer enabled:%|" (not obj.disabledAnalyzerInput()) to:s
   (
    format "Procedural:%|" r.procEpoch to:s
    for plants in r.procPublishedSources do for src in plants where isValidNode src do format "%:%|" (getHandleByAnim src) (if src.material==undefined then 0 else getHandleByAnim src.material) to:s
   )

  )
 )
 s as string
)
fn CyrusPFBuild = (
 CyrusDiagnosticEmit "bridge.build_requested" "renderer" "" 0 (if CyrusPFBusy then "busy" else "admitted")
 if CyrusPFBusy do return false
 CyrusPFClear();CyrusPFBusy=true;AminScatterRenderRedrawHeld=true
 local before=objects as array;local links=#(),prototypeSources=#(),prototypeNodes=#()
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
     if enabled and obj.autoRender and sources.count>0 do (
      local rows=obj.placements sources
      local groups=for src in sources collect #()
      for row in rows do append groups[row[2]] row[1]
      for k=1 to sources.count where groups[k].count>0 do (
       append CyrusPFData groups[k];local slot=CyrusPFData.count
       local prototypeIndex=findItem prototypeSources sources[k],prototype
       if prototypeIndex>0 then prototype=prototypeNodes[prototypeIndex]
       else (
        local resolved=sources[k]
        -- Resolve the evaluated geometry before changing its frame. Shape Instance
        -- otherwise incorporates source-node scale a second time relative to the
        -- pivot-local geometry used by preview, Auto Radius and baked instances.
        -- Snapshot also freezes world-dependent modifiers at the source location.
        if (try(classof resolved==CProxy)catch(false)) do (
         resolved=copy resolved;resolved.name="Cyrus_Render_ProxyPrototype"
         resolved.previzType=3;resolved.renderable=false;hide resolved
        )
        prototype=snapshot resolved
        prototype.name="Cyrus_Render_SourcePrototype";prototype.parent=undefined
        prototype.transform=matrix3 1;prototype.renderable=false;hide prototype
        append prototypeSources sources[k];append prototypeNodes prototype
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
        for n in CyrusTimeOwners where isValidNode n and classof n.baseObject==AminScatterObject do (
            if n.baseObject.containerNote event nodes do redraw=true
            -- Classify external events against the existing layer records.
            -- layerEntries synchronizes settings and invalidates siblings; it
            -- must not run merely because an unrelated scene node notified us.
            for leaf in n.baseObject.layerObjects do (
                if leaf.procExternalChanged event nodes deletedHandles:handles do redraw=true
            )
            if findItem nodes n>0 do (
                n.baseObject.layerEntries includeDisabled:true
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
    -- Restored controllers may have been pruned from the registry on deletion.
    CyrusResetTimeOwners()
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

try(CyrusPreviewIdleTimer.Stop();CyrusPreviewIdleTimer.Dispose())catch()
fn CyrusPreviewActivity held = (
    if CyrusViewportRecords.count==0 do return false
    local tm=viewport.getTM(),fov=viewport.getFOV(),viewID=viewport.activeViewport
    local changed=CyrusPreviewView!=undefined and (tm!=CyrusPreviewView or fov!=CyrusPreviewProjection or viewID!=CyrusPreviewViewID)
    CyrusPreviewView=tm;CyrusPreviewProjection=fov;CyrusPreviewViewID=viewID
    if held or changed do (cyrusRetainedInteraction true;CyrusPreviewIdleTimer.Stop();CyrusPreviewIdleTimer.Start())
    true
)
fn CyrusPreviewIdleTick sender args = (
    if not (CyrusInteractionHeld()) do (
        CyrusPreviewIdleTimer.Stop();cyrusRetainedInteraction false
        -- Draw the already prepared idle buffers; never schedule a solve/sync.
        redrawViews()
    )
)
CyrusPreviewIdleTimer=dotNetObject "System.Windows.Forms.Timer"
CyrusPreviewIdleTimer.Interval=400
dotNet.addEventHandler CyrusPreviewIdleTimer "Tick" CyrusPreviewIdleTick

try(CyrusReleaseTimer.Stop();CyrusReleaseTimer.Dispose())catch()
fn CyrusReleaseTick sender args = (
 CyrusReleaseTimer.Stop()
 if CyrusInteractionHeld() then (CyrusWasDragging=true;CyrusScheduleRelease())
 else if CyrusWasDragging or CyrusPointPending then (
     CyrusWasDragging=false;CyrusPointPending=false;CyrusPointPresentationPending=false;CyrusViewportRedraw()
 ) else if CyrusPointPresentationPending do (CyrusPointPresentationPending=false;redrawViews())
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
    CyrusPointPending=false;CyrusPointPresentationPending=false
    CyrusViewportRecords=#();CyrusViewportAnalyzers=#();CyrusViewportRecordsDirty=true
    local old=CyrusPointOwners;CyrusPointOwners=#()
    if old!=undefined do CyrusPointDelete (for pair in old collect pair[2])
)
fn CyrusPointSync = (
    if CyrusPointBusy or CyrusPointSuspended or AminScatterRenderRedrawHeld==true or CyrusInteractionHeld() do return false
    CyrusPointBusy=true
    try (
        local publishError="",detailStatus="",records=#(),analyzers=#()
        local surviving=#()
        for pair in CyrusPointOwners do (
            if isValidNode pair[1] and classof pair[1].baseObject==AminScatterObject and isValidNode pair[2] then append surviving pair
            else CyrusPointDelete #(pair[2])
        )
        CyrusPointOwners=surviving
        for n in CyrusTimeOwners where isValidNode n and classof n.baseObject==AminScatterObject do (
            local caches=#(),styles=#(),fallback=#()
            local limits=#(n.baseObject.previewBudget,n.baseObject.viewportNavigationPoints,n.baseObject.viewportInstances,n.baseObject.viewportNavigationInstances,n.baseObject.viewportFaces,n.baseObject.viewportNavigationFaces)
            local entries=if n.isHidden then #() else n.baseObject.viewportLayerEntries false,refreshLeaf=undefined
            -- Observe every visible dependency before staging the root once.
            -- A Manual pending flag survives display preparation; checking it
            -- separately on each leaf repeats whole-controller validation.
            for entry in entries do (
                local obj=entry[2]
                obj.previewCache interactionHeld:false allowRefresh:false
                if obj.dirty and not obj.cachedDisabledInput do refreshLeaf=obj
            )
            if refreshLeaf!=undefined do refreshLeaf.refreshPreview()
            for entry in entries do (
                local obj=entry[2],cache=if obj.cachedDisabledInput then obj.cachedDisabledPreview else obj.cachedPoints
                for analyzer in #(obj.analyzerNode,obj.areaAnalyzer,obj.fallAnalyzer) where isValidNode analyzer do appendIfUnique analyzers analyzer
                if (obj.showPoints or obj.showCenters) and cache!=undefined do (
                    if CyrusPointAvailable and ((obj.viewportMode==1 and CyrusPointEnabled) or ((obj.viewportMode==2 or obj.viewportMode==3) and CyrusMeshEnabled)) then (
                        append caches cache;append styles (join #(obj.pointColorMode==1,obj.solidPointColor) limits)
                    ) else append fallback #(cache,obj.pointColorMode==1,obj.solidPointColor)
                )
                if obj.inspectionCache!=undefined and not obj.disabledAnalyzerInput() do (
                    if CyrusPointAvailable and (CyrusPointEnabled or CyrusMeshEnabled) then (
                        append caches obj.inspectionCache;append styles #(false,white)
                    ) else append fallback #(obj.inspectionCache,false,white)
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
                if not cyrusRetainedPublish owner n caches styles then publishError="GPU preview unavailable; showing bounded centre markers. Refresh preview to retry."
                else if n.baseObject.viewportMode==1 and n.baseObject.viewportPointMemoryReduced() then detailStatus="Point Cloud sampled to fit the preview memory allowance; draw limits still apply."
                else if n.baseObject.viewportMode==3 do (
                    local detail=cyrusRetainedViewportStats owner
                    if detail[10]!=0 then detailStatus="Preview memory allowance reached; showing cached boxes."
                    else if detail[8]>0 do detailStatus="Mesh preview uses cached boxes to fit the triangle limit."
                )
            )
            append records #(n,owner,caches,styles,fallback,2)
        )
        CyrusViewportRecords=records
        CyrusViewportAnalyzers=for analyzer in analyzers collect #(analyzer,analyzer.getAnalysisRuns())
        CyrusViewportRecordsDirty=false
        CyrusPointLastError=publishError;CyrusPointDetailStatus=detailStatus
    )catch(CyrusPointLastError=getCurrentException())
    CyrusPointBusy=false
    true
)
fn CyrusViewportRedraw = (
    CyrusViewportRecordsDirty=true
    CyrusScheduleUI()
    CyrusPFRequestCheck()
    if not CyrusPointBusy do CyrusPointSync()
    redrawViews()
)
fn CyrusPointBeforeSave = (CyrusPointSuspended=true;CyrusPointClear())
fn CyrusPointAfterSave = (CyrusPointSuspended=false;(CyrusPointPending=true;CyrusScheduleRelease()))
fn CyrusPointBeforeScene = (
    for node in objects where classof node.baseObject==AminScatterObject do appendIfUnique CyrusPointSceneOwners node.baseObject
    CyrusPointSuspended=true;CyrusPointClear()
)
fn CyrusPointAfterScene = (
    local retired=CyrusPointSceneOwners;CyrusPointSceneOwners=#()
    for root in retired do (
        local live=for node in refs.dependentNodes root where isValidNode node and node.baseObject==root collect node
        if live.count==0 do (
            for leaf in root.layerObjects do leaf.procReleaseRetiredDisplay()
            root.procReleaseRetiredDisplay()
        )
    )
    CyrusPointSuspended=false;CyrusPointDeletedHandles=#();(CyrusPointPending=true;CyrusScheduleRelease())
)
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
-- does not scan documents, pick meshes, evaluate geometry or upload buffers.
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
            local feedbackChanged=cyrusBrushRefreshMask layer.paintDocument
            CyrusBrushSessionRevision=state[1]
            if state[6]==0 then (layer.checkPaintRevision();CyrusViewportRedraw()) else if feedbackChanged do redrawViews()
            root.refreshBrushEditors()
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

-- Explicit mask-preview snapshots. Redraw only consumes cached numeric markers.
try(unregisterRedrawViewsCallback CyrusMeshMaskViewportDraw)catch()
fn CyrusMeshMaskViewportDraw = (
    if CyrusMeshMaskPreviewRows.count>0 do (
        local valid=isValidNode CyrusMeshMaskPreviewNode and not CyrusMeshMaskPreviewNode.isHidden
        if valid do valid=findItem CyrusMeshMaskPreviewNode.baseObject.layerObjects CyrusMeshMaskPreviewTarget>0
        if valid then (
            gw.setTransform (matrix3 1)
            for row in CyrusMeshMaskPreviewRows do (local v=row[2]*255.0;gw.marker row[1] #smallDiamond color:(color v v v))
            gw.enlargeUpdateRect #whole
        ) else CyrusClearMeshMaskPreview undefined
    )
)
registerRedrawViewsCallback CyrusMeshMaskViewportDraw
