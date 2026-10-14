(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-*/" do throw "Owned P02 host required"
    local log=createFile (MCPFixtureDir+"phase02-bezier.txt")
    fn verify value label log = (
        format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log
        if not value do throw label
    )
    try (
        CyrusPerfHeadless=true;resetMaxFile #noPrompt
        local node=AminScatterObject name:"P02 editable curves",root=node.baseObject
        root.updateMode=1;root.autoRender=false
        root.newLayer();local first=root.selectedLayer()
        root.newLayer();local second=root.selectedLayer()
        CyrusPerfHeadless=false
        local editor=CyrusOpenFalloffGraph first undefined true
        editor.loading=true
        local curve=editor.graph.curves[1];curve.numPoints=2
        local p=curve.points[1];p.value=[0,20];p.bezier=true;p.corner=true;p.inTangent=[0,0];p.outTangent=[0.3,60];curve.points[1]=p
        p=curve.points[2];p.value=[1,80];p.bezier=true;p.corner=true;p.inTangent=[-0.3,0];p.outTangent=[0,0];curve.points[2]=p
        editor.loading=false
        local target=CyrusPresetMakeBinding root first "density_curve" editor:editor
        local original=CyrusPresetCapture target
        verify (abs(original[1][129]-0.5)>0.02) "Witness is a nonlinear Bezier curve" log
        local json=cyrusPresetEncode "density_curve" "Bezier witness" original
        local doc=cyrusPresetDecode json
        destroyDialog editor
        editor=CyrusOpenFalloffGraph second undefined true
        target=CyrusPresetMakeBinding root second "density_curve" editor:editor
        CyrusPresetApply target doc
        local restored=CyrusPresetCapture target,maximum=0.0
        for i=1 to 257 do maximum=amax maximum (abs(original[1][i]-restored[1][i]))
        verify (maximum<0.0001) "Serialized Bezier curve reconstructs every sample on a different layer" log
        verify (restored[2] as string==original[2] as string) "Bezier handles remain editable and retain their values" log
        local values=for i=0 to 256 collect (0.5+0.4*sin(i*360.0/256))
        CyrusPresetApply target #("density_curve","257 samples",#(values,#(),false))
        local captured=CyrusPresetCapture target
        verify (captured[2].count==2056) "All 257 sampled polyline points remain editable without downsampling" log
        maximum=0.0
        for i=1 to 257 do maximum=amax maximum (abs(values[i]-captured[1][i]))
        verify (maximum<0.0001) "Maximum-size sampled polyline preserves every sample" log
        destroyDialog editor
        verify (not theHold.Holding()) "Curve qualification leaves no transaction open" log
        format "COMPLETE\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
