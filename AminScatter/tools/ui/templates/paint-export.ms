-- Export options retain one captured owner/document, never the current UI row.
global CyrusPaintExportDialog,CyrusOpenPaintExport,CyrusClosePaintExport
fn CyrusClosePaintExport = (try(destroyDialog CyrusPaintExportDialog)catch();CyrusPaintExportDialog=undefined)
CyrusClosePaintExport()
callbacks.removeScripts id:#CyrusPaintExportUI
callbacks.addScript #systemPreReset "CyrusClosePaintExport()" id:#CyrusPaintExportUI persistent:false
callbacks.addScript #filePreOpen "CyrusClosePaintExport()" id:#CyrusPaintExportUI persistent:false
fn CyrusOpenPaintExport controller area = (
    controller.validatePaintConversion area
    try(destroyDialog CyrusPaintExportDialog)catch()
    local document=area.paintDocument,key=area.paintKey(),target=area.areaTarget,transform=area.areaTarget.objectTransform
    local surfaceAttached=cyrusBrushAttached document
    rollout exportOptions "Paint spline export" width:330 height:250 (
        local targetController,targetArea,targetDocument,capturedKey,capturedTarget,capturedTransform,attached=false
        radiobuttons mode "Create independent spline" labels:#("Optimized","Exact snapshot") columns:2 pos:[12,12] width:306
        spinner deviation "Maximum deviation:" type:#worldunits range:[1e-9,1e9,0.1] fieldWidth:90 pos:[12,60] width:306
        label help "Optimized reduces planar boundary knots within tolerance.\nExact preserves existing snapshot/reimport behavior.\nThe original Paint is unchanged." pos:[12,94] width:306 height:48
        button createSpline "Create spline" pos:[12,150] width:178 height:26
        button cancel "Close" pos:[200,150] width:118 height:26
        label result "" pos:[12,186] width:306 height:54
        fn validateCapture = (
            if targetController==undefined or targetArea==undefined do throw "The export context is closed. Open Export spline again."
            local alive=false
            for node in refs.dependentNodes targetController where isValidNode node and node.baseObject==targetController do alive=true
            if not alive do throw "The source Scatter was removed. Open Export spline again."
            targetController.validatePaintConversion targetArea
            if targetArea.paintDocument!=targetDocument or targetArea.paintKey()!=capturedKey or targetArea.areaTarget!=capturedTarget or capturedTarget.objectTransform!=capturedTransform do
                throw "The Paint Area or receiver changed. Close this view and open Export spline again."
            true
        )
        on exportOptions open do (mode.state=if attached then 2 else 1;deviation.value=units.decodeValue "1mm";deviation.enabled=(mode.state==1))
        on mode changed value do deviation.enabled=(value==1)
        on cancel pressed do destroyDialog exportOptions
        on createSpline pressed do try (
            validateCapture()
            local owner=targetController,source=targetArea,optimized=(mode.state==1),tolerance=deviation.value
            -- Export selects its new node and can unmount the Scatter panel.
            local outcome=owner.exportPaintSpline source optimized:optimized tolerance:tolerance
            if optimized then result.text=(if outcome[5] then "Optimized: " else "Exact: ")+(outcome[2] as string)+" → "+(outcome[3] as string)+" knots\n"+(if outcome[5] then ("Certified deviation ≤ "+units.formatValue outcome[4]) else outcome[6])
            else result.text="Exact independent snapshot created. Original Paint unchanged."
        )catch(result.text=getCurrentException())
        on exportOptions close do (targetController=undefined;targetArea=undefined;targetDocument=undefined;capturedTarget=undefined)
    )
    CyrusPaintExportDialog=exportOptions
    createDialog exportOptions style:#(#style_titlebar,#style_sysmenu,#style_toolwindow)
    -- Max initializes rollout locals when creating the dialog. Bind the captured
    -- values afterwards; pre-creation assignments are reset by that lifecycle.
    exportOptions.targetController=controller;exportOptions.targetArea=area;exportOptions.targetDocument=document
    exportOptions.capturedKey=key;exportOptions.capturedTarget=target;exportOptions.capturedTransform=transform
    exportOptions.attached=surfaceAttached;exportOptions.mode.state=if surfaceAttached then 2 else 1
    exportOptions.deviation.enabled=not surfaceAttached
    try(exportOptions.validateCapture())catch(CyrusClosePaintExport();throw())
    exportOptions
)
