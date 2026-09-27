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
