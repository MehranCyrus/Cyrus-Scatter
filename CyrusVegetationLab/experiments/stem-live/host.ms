loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vegetation-stem-plugin-20261024-02/" "CyrusVegetationStemLab.dlx"
loadDllsFromDir @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vegetation-stem-plugin-20261024-02/" "CyrusVegetationStemGeometry.dlo"
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/CyrusVegetationLab/experiments/stem-live/StemLab.ms"
(
    fn require ok message = (if not ok do throw message)
    fn write name value = ((dotNetClass "System.IO.File").WriteAllText (CVLTestDir+name) value)
    cvlStage "load original source"
    loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusScatter-0.86.7-20261020/Content/Library/Models/Shrubs/A084 - Lavender - 05/model.max" quiet:true useFileUnits:true
    local source=getNodeByName "CyrusModel_A084",meter=units.decodeValue "1m"
    global CVSSphere=sphere name:"CVS_Collider_Sphere" radius:(.167*meter) segments:48 pos:[.7*meter,.096*meter,.78*meter]
    CVSSphere.material=standardMaterial name:"Collider stone" diffuse:(color 148 144 136)
    cvlStage "create stem native object"
    global CVSOutput=cvsCreate source CVSSphere @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vegetation-stem-preparation-20261024-02/lavender.stems.json" @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vegetation-stem-preparation-20261024-02/lavender.parts.bin"
    local material=multiMaterial numsubs:4 name:"Stem Lab botanical preview"
    material[1]=standardMaterial name:"Woody stems" diffuse:(color 112 83 56)
    material[2]=standardMaterial name:"Green stems" diffuse:(color 91 123 63)
    material[3]=standardMaterial name:"Leaves" diffuse:(color 82 131 65) twoSided:true
    material[4]=standardMaterial name:"Lavender flowers" diffuse:(color 146 104 179) twoSided:true
    CVSOutput.material=material
    source.material=material;source.renderable=false
    hide source;freeze source
    setTransformLockFlags CVSOutput #{1..9}
    local floor=plane name:"CVS_Ground" length:(2.8*meter) width:(2.8*meter) lengthSegs:1 widthSegs:1 pos:[0,0,-.005*meter]
    floor.material=standardMaterial diffuse:(color 100 94 78)
    viewport.setLayout #layout_1;viewport.setType #view_front;viewport.setRenderLevel #smoothhighlights
    select #(CVSOutput,CVSSphere);max zoomext sel all
    cvlStage "preview realization"
    redrawViews()
    write "created.json" (cvsStats CVSOutput)
    local before=getPolygonCount CVSOutput
    write "preview-counts.txt" (before as string)
    require (before[1]==90640) "Preview geometry did not realize."
    cvlStage "native dependency sweep without Fit calls"
    local clock=dotNetClass "System.Diagnostics.Stopwatch",log=createFile (CVLTestDir+"sweep.tsv")
    format "x_m\twall_ms\n" to:log
    for x in #(.6,.55,.50,.47,.44,.42,.40,.38,.5,.7) do
    (
        local start=clock.GetTimestamp()
        CVSSphere.pos=[x*meter,.096*meter,.78*meter]
        redrawViews();local probe=getPolygonCount CVSOutput
        format "%\t%\n" x (1000.*((clock.GetTimestamp()-start) as double)/(clock.Frequency as double)) to:log;flush log
        write "progress.json" (cvsStats CVSOutput)
    )
    close log
    write "sweep.json" (cvsStats CVSOutput)
    cvlStage "audit near contact"
    CVSSphere.pos=[.42*meter,.096*meter,.78*meter];redrawViews();local near=getPolygonCount CVSOutput
    write "audit.json" (cvsAudit CVSOutput)
    write "near.json" (cvsStats CVSOutput)
    cvsMode CVSOutput 1;redrawViews()
    require ((getPolygonCount CVSOutput)[1]==832240) "Full geometry mode failed."
    cvsMode CVSOutput 0;redrawViews()
    cvlStage "save reopen embedded bindings"
    select CVSSphere;max move
    require (saveMaxFile (CVLTestDir+"Lavender_Stem_Live_Max2027.max") quiet:true) "Scene save failed."
    loadMaxFile (CVLTestDir+"Lavender_Stem_Live_Max2027.max") quiet:true useFileUnits:true
    CVSOutput=getNodeByName "CVS_Stem_Lavender";CVSSphere=getNodeByName "CVS_Collider_Sphere"
    require ((getPolygonCount CVSOutput)[1]==90640) "Reopened preview missing."
    write "reopened.json" (cvsStats CVSOutput)
    CVSSphere.pos=[.47*meter,.096*meter,.78*meter];redrawViews();local changed=getPolygonCount CVSOutput
    write "reopened-moved.json" (cvsStats CVSOutput)
    cvlStage "render full geometry"
    local cam=targetCamera name:"CVS_TestCamera" pos:[-1.8*meter,-2.3*meter,1.45*meter] target:(targetObject pos:[.12*meter,0,.5*meter]) fov:42
    renderers.current=Default_Scanline_Renderer();ambientLight=color 45 45 45
    omniLight name:"CVS_Key" pos:[-2*meter,-2*meter,3*meter] multiplier:.8
    omniLight name:"CVS_Fill" pos:[2*meter,-meter,meter] multiplier:.5
    render camera:cam outputfile:(CVLTestDir+"Stem_Bent.png") vfb:false outputwidth:1100 outputheight:850
    write "rendered.json" (cvsStats CVSOutput)
    select CVSSphere;max move
    saveMaxFile (CVLTestDir+"Lavender_Stem_Live_Max2027.max") quiet:true
    CVSOpen()
    cvlStage "done"
)
