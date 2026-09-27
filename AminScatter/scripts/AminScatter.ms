/* AminScatter 0.2: native C++ placement with a MAXScript prototype panel.
   Preview is transient. Build Instances creates persistent renderable nodes.
   Ordinary meshes only; Corona Proxy support remains unverified. */
global AminScatterUI
global AminScatterPreview = #()
global AminScatterDraw
try(unRegisterRedrawViewsCallback AminScatterDraw)catch()
try(destroyDialog AminScatterUI)catch()
fn AminScatterDraw = (
    gw.setTransform (matrix3 1)
    for entry in AminScatterPreview do (
        gw.setColor #line entry[2]
        gw.marker entry[1] #point
    )
    gw.enlargeUpdateRect #whole
)
registerRedrawViewsCallback AminScatterDraw
rollout AminScatterUI "AminScatter 0.2 - mesh prototype" width:340 (
    local target = undefined
    local sources = #()
    local placements = #()
    local generated = #()
    pickbutton pickSurface "Pick scatter surface" width:310 autoDisplay:true
    button addSources "Use selected objects as plants" width:310
    label sourceLabel "0 sources" align:#left
    spinner amount "Plant count: " range:[1,10000,200] type:#integer fieldWidth:80
    spinner seed "Seed: " range:[0,2147483647,42] type:#integer fieldWidth:80
    spinner scaleMin "Scale min: " range:[0.001,100,0.8] fieldWidth:80
    spinner scaleMax "Scale max: " range:[0.001,100,1.2] fieldWidth:80
    spinner tilt "Random X/Y tilt (+/- degrees): " range:[0,180,0] fieldWidth:80
    spinner yawMin "Z rotation min: " range:[-360,360,0] fieldWidth:80
    spinner yawMax "Z rotation max: " range:[-360,360,360] fieldWidth:80
    spinner movement "XYZ movement (+/- scene units): " range:[0,10000,0] fieldWidth:80
    checkbox alignNormal "Align to surface normal" checked:true
    spinner sampleCount "Points per plant: " range:[10,1000,80] type:#integer fieldWidth:80
    label budgetLabel "Preview budget: 50,000 points" align:#left
    button preview "Update Point Cloud" width:310
    button build "Build / replace instances for render" width:310
    button clearPreview "Clear Point Cloud" width:310
    label status "Pick a surface, then select plant meshes." width:310 height:36
    fn validateInputs = (
        if not isValidNode target do throw "Pick a surface first."
        if sources.count == 0 do throw "Select one or more plant meshes."
        for n in sources do if not isValidNode n do throw "A plant source was deleted. Reselect sources."
        if scaleMin.value > scaleMax.value do throw "Scale minimum exceeds maximum."
        if yawMin.value > yawMax.value do throw "Rotation minimum exceeds maximum."
    )
    fn calculate = (
        validateInputs()
        local t = tilt.value
        local m = movement.value
        aminScatterTransforms target amount.value seed.value sources.count scaleMin.value scaleMax.value [-t,-t,yawMin.value] [t,t,yawMax.value] [m,m,m] alignNormal.checked
    )
    on pickSurface picked obj do (target=obj; placements=#(); AminScatterPreview=#(); redrawViews())
    on addSources pressed do (
        sources=for n in selection where n != target and (findItem generated n)==0 collect n
        sourceLabel.text=(sources.count as string)+" sources"
        placements=#(); AminScatterPreview=#();redrawViews()
    )
    on preview pressed do (
        try (
            local nextPlacements=calculate()
            local samples=for n in sources collect (aminScatterSourcePoints n sampleCount.value seed.value)
            local colors=#((color 100 220 120),(color 240 190 70),(color 90 175 255),(color 230 110 170))
            local nextPreview=#()
            local total=nextPlacements.count*sampleCount.value
            local step=amax 1 (ceil (total/50000.0))
            for flat=0 to (total-1) by step do (
                local plantIndex=(floor(flat/sampleCount.value))+1
                local pointIndex=(mod flat sampleCount.value)+1
                local item=nextPlacements[plantIndex]
                append nextPreview #((samples[item[2]][pointIndex]*item[1]),colors[(mod (item[2]-1) colors.count)+1])
            )
            placements=nextPlacements; AminScatterPreview=nextPreview
            status.text=(placements.count as string)+" plants; "+(nextPreview.count as string)+" points. Preview only."
            redrawViews()
        ) catch (messageBox (getCurrentException()) title:"AminScatter")
    )
    on build pressed do (
        try (
            local nextPlacements=calculate()
            local newNodes=#()
            undo "AminScatter build" on (
                try (
                    with redraw off (
                        for item in nextPlacements do (
                            local n=instance sources[item[2]]
                            append newNodes n
                            n.name=uniqueName "AminScatterPlant_"
                            n.parent=undefined
                            n.transform=item[1]
                            n.renderable=true
                            n.isHidden=false
                        )
                        for n in generated where isValidNode n do delete n
                    )
                ) catch (
                    for n in newNodes where isValidNode n do delete n
                    throw()
                )
            )
            generated=newNodes;placements=nextPlacements
            AminScatterPreview=#();redrawViews()
            status.text=(generated.count as string)+" renderable instances created. Save the scene."
        ) catch (messageBox (getCurrentException()) title:"AminScatter")
    )
    on clearPreview pressed do (AminScatterPreview=#();redrawViews())
    on AminScatterUI close do (
        AminScatterPreview=#()
        unRegisterRedrawViewsCallback AminScatterDraw
        redrawViews()
    )
)
createDialog AminScatterUI
