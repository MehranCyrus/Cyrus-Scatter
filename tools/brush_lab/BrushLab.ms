-- M0/M1 interaction harness. Authoritative paint lives in a saved native
-- ReferenceTarget on the helper, never in a rollout/global or displayed plants.
global CyrusBrushLabData,BLPanel,BLController,BLPreviewOwner,BLPublished=0,BLMaskRevision=0,BLCache,BLSyncing=false
global BLDocument,BLPublish,BLUse,BLCreate,BLApplySettings,BLRefreshHistory,BLSelectStroke,BLStop
CyrusBrushLabData = attributes CyrusBrushLabData version:1 attribID:#(0x42ab0196,0x20de1327) (
    parameters saved (
        paintDocument type:#maxObject
        plantSource type:#node
    )
)
fn BLDocument = (
    if not isValidNode BLController do throw "Choose or create a Brush lab layer"
    BLController.CyrusBrushLabData.paintDocument
)
fn BLPublish = (
    local d=BLDocument()
    local rows=cyrusBrushLabRows d
    local source=BLController.CyrusBrushLabData.plantSource
    if not isValidNode source do throw "Brush lab source is missing"
    -- Capacity is 10,000 and this preview publishes every survivor. No unstable
    -- percentage thinning or regenerated random population during painting.
    local nextCache=cyrusBuildGeometryPreview rows #(source) #((color 90 185 105)) 4 10000 2000000
    if not isValidNode BLPreviewOwner do BLPreviewOwner=cyrusRetainedCreate()
    cyrusRetainedPublish BLPreviewOwner BLController #(nextCache) #(#(true,(color 90 185 105)))
    BLCache=nextCache
    BLPublished=(cyrusBrushLabStats d)[1]
    BLMaskRevision=BLPublished
    if BLPanel!=undefined do BLPanel.status.text=((rows.count as string)+" plants | "+(((cyrusBrushLabStats d)[2] as integer) as string)+" strokes")
    redrawViews()
    rows
)
fn BLRefreshHistory = (
    if BLPanel!=undefined and isValidNode BLController do (
        local stats=cyrusBrushLabStats (BLDocument())
        if BLPanel.history.items.count!=stats[2] do (
            BLPanel.history.items=(for i=1 to (stats[2] as integer) collect ("Stroke "+(i as string)))
            BLSelectStroke()
        )
    )
)
fn BLSelectStroke = (
    local rows=cyrusBrushLabHistory (BLDocument())
    local index=BLPanel.history.selection
    if index>0 and index<=rows.count do (
        BLPanel.strokeEnabled.checked=rows[index][1]
        BLPanel.editRadius.value=rows[index][3]
        BLPanel.editStrength.value=rows[index][4]
    )
)
fn BLApplySettings = (
    if not BLSyncing do cyrusBrushLabSettings (BLDocument()) BLPanel.radius.value BLPanel.strength.value BLPanel.softness.value (BLPanel.mode.state==2) BLPanel.density.value
)
fn BLStop = (
    cyrusBrushLabStop()
    if BLPanel.live.checked then BLPublish()
    else BLPanel.status.text="Preview pending - use Update preview."
)
fn BLUse controller = (
    cyrusBrushLabStop()
    cyrusBrushLabBind controller.CyrusBrushLabData.paintDocument
    BLController=controller
    BLPublished=0
    BLMaskRevision=0
    if BLPanel!=undefined do (
        BLPanel.layerLabel.text=controller.name
        local settings=cyrusBrushLabOptions (BLDocument())
        BLSyncing=true
        BLPanel.radius.value=settings[1];BLPanel.strength.value=settings[2];BLPanel.softness.value=settings[3];BLPanel.density.value=settings[4];BLPanel.mode.state=if settings[5] then 2 else 1
        BLSyncing=false
        BLPanel.history.items=#()
    )
    BLPublish();BLRefreshHistory()
)
fn BLCreate target source = (
    if not isValidNode target or not isValidNode source do throw "Select a target and source"
    local document=cyrusBrushLabCreate target
    local controller=point name:(uniqueName "Brush_Lab_Layer") size:2 box:false cross:false
    custAttributes.add controller CyrusBrushLabData
    controller.CyrusBrushLabData.paintDocument=document
    controller.CyrusBrushLabData.plantSource=source
    BLUse controller
    controller
)
try(destroyDialog BLPanel)catch()
rollout BLPanel "Cyrus Brush - Prototype" width:280 height:534 (
    label heading "Procedural surface paint | M0/M1 lab" align:#left
    label layerLabel "Choose a lab layer" align:#left width:260
    button flat "Use flat test surface" width:250
    button curved "Use curved test surface" width:250
    pickbutton customTarget "New layer on picked surface" width:250 autoDisplay:false
    radiobuttons mode "Stroke tool" labels:#("Paint","Erase") default:1 columns:2
    spinner radius "Radius" range:[0.1,10000,24] type:#worldunits fieldwidth:80
    spinner strength "Strength" range:[0,1,1] type:#float fieldwidth:80 scale:.01
    spinner softness "Softness" range:[0,1,.5] type:#float fieldwidth:80 scale:.01
    spinner density "Density" range:[0,1,1] type:#float fieldwidth:80 scale:.01
    button start "Start brushing" width:122 across:2
    button stop "Stop / navigate" width:122
    checkbox live "Update plants while painting" checked:true
    button update "Update preview" width:250
    dropdownlist history "Recorded strokes" items:#() width:250
    checkbox strokeEnabled "Selected stroke enabled" checked:true
    spinner editRadius "Stroke radius" range:[0.1,10000,24] type:#worldunits fieldwidth:80
    spinner editStrength "Stroke strength" range:[0,1,1] type:#float fieldwidth:80 scale:.01
    button edit "Apply stroke edit (Undo supported)" width:250
    label status "Ready" width:260 height:35 align:#left
    timer refresh interval:250 active:true
    on flat pressed do try(BLUse BLFlatLayer)catch(status.text=getCurrentException())
    on curved pressed do try(BLUse BLCurvedLayer)catch(status.text=getCurrentException())
    on customTarget picked node do try(BLCreate node BLSource)catch(status.text=getCurrentException())
    on start pressed do try(BLApplySettings();cyrusBrushLabBegin (BLDocument());status.text="Drag on the surface. Right-click stops.")catch(status.text=getCurrentException())
    on stop pressed do try(BLStop())catch(status.text=getCurrentException())
    on update pressed do try(BLApplySettings();BLPublish())catch(status.text=getCurrentException())
    on radius changed v do try(BLApplySettings())catch(status.text=getCurrentException())
    on strength changed v do try(BLApplySettings())catch(status.text=getCurrentException())
    on softness changed v do try(BLApplySettings())catch(status.text=getCurrentException())
    on density changed v do try(BLApplySettings())catch(status.text=getCurrentException())
    on mode changed v do try(BLApplySettings())catch(status.text=getCurrentException())
    on history selected v do try(BLSelectStroke())catch(status.text=getCurrentException())
    on edit pressed do try(
        cyrusBrushLabStroke (BLDocument()) history.selection strokeEnabled.checked editStrength.value editRadius.value
        if live.checked then BLPublish() else (
            cyrusBrushLabRefreshMask (BLDocument())
            BLMaskRevision=(cyrusBrushLabStats (BLDocument()))[1]
            status.text="Preview pending - use Update preview."
            redrawViews()
        )
    )catch(status.text=getCurrentException())
    on refresh tick do (
        if isValidNode BLController do (
            try (
                local stats=cyrusBrushLabStats (BLDocument())
                if stats[4]==0 then status.text="Target changed - stop, then choose it again."
                else if live.checked then (
                    if stats[1]!=BLPublished do BLPublish()
                ) else if stats[5]==1 and stats[1]!=BLMaskRevision do (
                    cyrusBrushLabRefreshMask (BLDocument())
                    BLMaskRevision=stats[1]
                    status.text="Mask updated - plants wait for Update preview."
                    redrawViews()
                )
                BLRefreshHistory()
            )catch(status.text=getCurrentException())
        )
    )
    on BLPanel close do (cyrusBrushLabStop())
)
createDialog BLPanel pos:[40,180] style:#(#style_titlebar,#style_border,#style_sysmenu)
