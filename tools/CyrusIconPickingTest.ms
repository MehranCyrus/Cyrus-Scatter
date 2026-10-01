-- Temporary A/B mesh probes only. No plugin redefinition, installation or scene save.
-- Closing the panel removes its own four probes. Keep it open while testing.
global CyrusIconPickingTest, CyrusIconProbeNodes, CyrusIconProbeLines, CyrusIconPickingHeadless
global AminScatterObject, CyrusSurfaceAnalyzer
try(destroyDialog CyrusIconPickingTest)catch()
if CyrusIconProbeNodes==undefined do CyrusIconProbeNodes=#()
if CyrusIconProbeLines==undefined do CyrusIconProbeLines=#()

fn CyrusIconProbeRemove = (
    for n in CyrusIconProbeNodes where isValidNode n do delete n
    CyrusIconProbeNodes=#();CyrusIconProbeLines=#()
    redrawViews()
)
fn CyrusIconProbeGeometry paths validGeometry = (
    local verts=#(),faces=#()
    for path in paths do for i=1 to path.count-1 do (
        local a=path[i],b=path[i+1],k=verts.count
        if validGeometry then (
            if distance a b>0.00001 do (
                local axis=normalize(b-a)
                local u=normalize(cross axis [0,0,1])
                local v=normalize(cross axis u)
                -- Closed triangular tube: nonzero area from all viewing directions.
                for p in #(a,b) do for angle in #(0,120,240) do append verts (p+0.45*(u*cos(angle)+v*sin(angle)))
                join faces #([k+1,k+3,k+2],[k+4,k+5,k+6], [k+1,k+2,k+5],[k+1,k+5,k+4], [k+2,k+3,k+6],[k+2,k+6,k+5], [k+3,k+1,k+4],[k+3,k+4,k+6])
            )
        )else(
            join verts #(a,b);append faces [k+1,k+2,k+2]
        )
    )
    #(verts,faces)
)
fn CyrusIconProbeDraw = (
    for entry in CyrusIconProbeLines where isValidNode entry[1] do (
        gw.setTransform entry[1].objectTransform
        gw.setColor #line entry[1].wirecolor
        for path in entry[2] do gw.polyline path false
    )
    gw.setTransform(matrix3 1)
    gw.enlargeUpdateRect #whole
)
try(unregisterRedrawViewsCallback CyrusIconProbeDraw)catch()
fn CyrusIconProbeCreate = (
    -- Read only icon paths; no preview builds, snapshots or analysis of source nodes.
    local sources=#()
    for cls in #(AminScatterObject,CyrusSurfaceAnalyzer) do (
        local found=undefined
        if cls!=undefined do for n in objects while found==undefined where classof n.baseObject==cls do found=n
        if found==undefined do throw "The scene needs an existing Cyrus Scatter and Surface Analyzer."
        append sources found
    )
    local pathsByType=#()
    for n in sources do (
        local paths=n.baseObject.iconLines()
        local radius=0.0
        for path in paths do for p in path do radius=amax radius (length p)
        if radius<0.00001 do throw "An icon has zero size. Increase its icon size before testing."
        append pathsByType (for path in paths collect (for p in path collect p*(30.0/radius)))
    )
    CyrusIconProbeRemove()
    try (
        for row=1 to 2 do for col=1 to 2 do (
            local validGeometry=col==2
            local data=CyrusIconProbeGeometry pathsByType[row] validGeometry
            local title="CYRUS_PICK_TEST_"+(if row==1 then "SC_" else "SA_")+(if validGeometry then "B_VALID" else "A_ORIGINAL")
            local n=mesh name:(uniqueName title) vertices:data[1] faces:data[2]
            append CyrusIconProbeNodes n
            n.pos=[(col-1.5)*90,(1.5-row)*90,0]
            n.renderable=false;n.isHidden=false;n.isFrozen=false
            n.wirecolor=if validGeometry then green else red
            append CyrusIconProbeLines #(n,pathsByType[row])
        )
    )catch(CyrusIconProbeRemove();throw())
    registerRedrawViewsCallback CyrusIconProbeDraw
    redrawViews()
    CyrusIconProbeNodes
)
rollout CyrusIconPickingTest "Cyrus - icon picking test" width:470 height:215 (
    label instructions "Creates 4 temporary mesh probes. Existing controllers stay unchanged." align:#left
    button create "1. Create test icons" width:440
    button frame "2. Show test icons (Top view)" width:440
    label legend "LEFT RED = original triangles | RIGHT GREEN = valid tubes" align:#left
    label hint "Click a viewport, press Q, then try each icon. Also test H > Select." align:#left
    label note "Keep this panel open. Closing it removes the test objects." align:#left
    label status "Ready. No objects created yet." width:440 height:40 align:#left
    on create pressed do try (
        -- New probes belong to the default layer, avoiding changes to the artist's current layer.
        local priorLayer=LayerManager.current
        try (
            (LayerManager.getLayer 0).current=true
            if (LayerManager.getLayer 0).isFrozen or (LayerManager.getLayer 0).isHidden do throw "Default layer is frozen/hidden. Test in a scene with a visible, unfrozen default layer."
            CyrusIconProbeCreate()
            priorLayer.current=true
        )catch(priorLayer.current=true;throw())
        status.text="Created: SC above, SA below. Click Show test icons."
    )catch(status.text=getCurrentException())
    on frame pressed do try (
        local nodes=for n in CyrusIconProbeNodes where isValidNode n collect n
        if nodes.count==0 do throw "Create the test icons first."
        select nodes
        viewport.setType #view_top
        max zoomext sel
        clearSelection()
        status.text="Test red and green icons by click and H. Report which methods work."
    )catch(status.text=getCurrentException())
    on CyrusIconPickingTest close do (
        unregisterRedrawViewsCallback CyrusIconProbeDraw
        CyrusIconProbeRemove()
    )
)
if CyrusIconPickingHeadless!=true do createDialog CyrusIconPickingTest
