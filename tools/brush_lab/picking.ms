(
BLPanel.refresh.active=false
cyrusBrushStop()
local results=#()
local previousTM=viewport.getTM()
for spec in #(#(BLFlat,BLFlatLayer),#(BLCurved,BLCurvedLayer)) do (
    local node=spec[1],d=spec[2].CyrusBrushLabData.paintDocument
    for viewType in #(#view_top,#view_persp_user) do (
        viewport.setType viewType
        select node;max zoomext sel all
        cyrusBrushBegin d
        completeRedraw()
        local size=getViewSize(),hits=0,maxReconstruction=0.0,maxRayDifference=0.0,repaired=0
        for y=2 to 8 do for x=2 to 8 do (
            local hit=cyrusBrushProbe d [size.x*x/10.0,size.y*y/10.0]
            if hit!=undefined do (
                hits+=1
                maxReconstruction=amax maxReconstruction hit[2]
                BLAssert (hit[4]>=0) "Native hit missed by brush BVH"
                maxRayDifference=amax maxRayDifference hit[4]
                if not hit[5] do repaired+=1
                BLAssert hit[6] "BVH must match exhaustive snapshot query"
            )
        )
        cyrusBrushStop()
        BLAssert (hits>=5) "Picking fixture had too few hits"
        BLAssert (maxReconstruction<.005) "Painter face reconstruction disagreed with supplied snapshot"
        -- Native screen-space face choice is diagnostic, not the hit oracle:
        -- at shared edges it can report an extrapolated point. Probe verifies
        -- canonical BVH hits against an exhaustive query before returning.
        append results #(node.name,viewType,hits,maxReconstruction,maxRayDifference,repaired)
    )
)
CSPWriteText (BLDir+"picking.json") (CSPObject #(#("cases",results)))
viewport.setType #view_persp_user;viewport.setTM previousTM
BLPanel.refresh.active=true
)
