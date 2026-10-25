-- Owned native parity fixture only. Not installed or exposed to MCP callers.
global CyrusMCPPresetCurveProbe
fn CyrusMCPPresetCurveProbe = (
    if CyrusFalloffGraph!=undefined do throw "Owned parity fixture requires a closed artist curve editor"
    local traces=#()
    rollout probe "Owned curve evaluator parity" width:400 height:240 (
        curveControl graph "" pos:[4,4] width:392 height:232 numCurves:1 x_range:[0,1] y_range:[0,400] asPopup:false
    )
    createDialog probe
    try (
        for spec in #(
            #("density_curve",#(#(0,0,0,0,0,0,0,1),#(1,100,0,0,0,0,0,1))),
            #("density_curve",#(#(0,0,0,0,0.2,10,1,1),#(0.5,70,-0.1,-20,0.1,15,1,1),#(1,100,-0.2,-5,0,0,1,1))),
            #("scale_curve",#(#(0,50,0,0,0.2,100,1,1),#(0.5,200,-0.1,-20,0.1,10,1,1),#(1,100,-0.2,20,0,0,1,1))),
            #("density_curve",#(#(0,10,0,0,0,0,0,1),#(0.1,30,0,0,0,0,0,1),#(0.3,60,0,0,0,0,0,1),#(0.9,40,0,0,0,0,0,1),#(1,90,0,0,0,0,0,1))),
            #("density_curve",#(#(0,0.123456789,0,0,0.123456789,12.3456789,1,1),#(0.43789123,73.891234,-0.112233445,-9.87654321,0.198765432,8.7654321,1,1),#(1,99.9876543,-0.123456789,-4.56789123,0,0,1,1))),
            #("scale_curve",#(#(0,50.1234567,0,0,0.123456789,100.234567,1,1),#(0.43789123,203.891234,-0.112233445,-29.87654321,0.198765432,18.7654321,1,1),#(1,103.9876543,-0.123456789,24.56789123,0,0,1,1)))
        ) do (
            local curve=probe.graph.curves[1],packed=#(),values=#(),points=spec[2]
            curve.numPoints=points.count
            for i=1 to points.count do (
                local p=ccPoint [0,0] [0,0] [0,0] end:(i==1 or i==points.count),v=points[i]
                p.value=[v[1],v[2]];p.inTangent=[v[3],v[4]];p.outTangent=[v[5],v[6]]
                p.bezier=v[7]>0;p.corner=v[8]>0;p.lock_x=(i==1 or i==points.count);setPoint curve i p checkConstraints:false
            )
            for i=1 to curve.numPoints do (
                local p=curve.points[i]
                join packed #(p.value.x,p.value.y,p.inTangent.x,p.inTangent.y,p.outTangent.x,p.outTangent.y,(if p.bezier then 1 else 0),(if p.corner then 1 else 0))
            )
            for i=0 to 256 do (
                local v=amax 0.0 ((getValue curve 0 (i/256.0))/100.0)
                append values (if spec[1]=="density_curve" then amin 1.0 v else v)
            )
            append traces (cyrusPresetEncode spec[1] "Owned artist curve trace" #(values,packed,spec[1]=="scale_curve"))
        )
        destroyDialog probe
    ) catch (destroyDialog probe;throw())
    traces
)
