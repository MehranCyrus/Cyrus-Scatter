-- Independent scalar oracle in the owned Max process; no viewport drawing.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned density profile required"
    local log=createFile (MCPFixtureDir+"field-numeric.txt")
    fn check yes message log = (format "%: %\n" (if yes then "PASS" else "FAIL") message to:log;flush log;if not yes do throw message)
    fn periodicRamp coordinate = (
        local u=coordinate-floor coordinate,x=u*2.0-0.5,base=floor x,alpha=x-base
        if mod (base+2) 2==0 then alpha else 1.0-alpha
    )
    local bitmapValue=undefined
    try (
        check (isValidNode DTerrain) "Projection setup exists" log
        local publication=cyrusRecipePublicationFingerprint DRoot.groupSnapshotRows,epoch=DRoot.procEpoch,material=DTerrain.material
        bitmapValue=bitmap 2 2 color:black
        setPixels bitmapValue [0,0] #(black,white);setPixels bitmapValue [0,1] #(black,white)
        local image=cyrusCaptureDensityImage bitmapValue
        close bitmapValue;bitmapValue=undefined
        local cfg=#(false,2,1,0.,1.,false,#(0.,1.))
        local mapping=#(1,1,40.,70.,1.,1.,0.,0.,0.,matrix3 1,#(0.,1.))
        local filters=#(false,0.,180.,0.,0.,false,0.,1000.,0.,0.)
        local field=cyrusPrepareDensityOverlay #(DTerrain) cfg image mapping 1 0 4096 false filters false #() #(#(),#())
        local details=cyrusDensityOverlayInfo field,step=amax 1 ((details[1]/100) as integer),maximumError=0.
        for triangle=1 to details[1] by step do for corner=1 to 3 do (
            local vertex=cyrusDensityOverlayVertex field triangle corner,expected=periodicRamp (vertex[1].x/40.0)
            maximumError=amax maximumError (abs(vertex[2]-expected))
        )
        format "RAMP maximum_error=% triangles=%\n" maximumError details[1] to:log
        check (maximumError<0.0001) "Native image overlay matches independent periodic texel-centre oracle" log
        with undo off (
            convertToMesh DTerrain
            meshop.setNumMaps DTerrain 3 keep:true
            meshop.setMapSupport DTerrain 2 true
            meshop.setNumMapVerts DTerrain 2 DTerrain.numverts
            meshop.setNumMapFaces DTerrain 2 DTerrain.numfaces
            for i=1 to DTerrain.numverts do meshop.setMapVert DTerrain 2 i [0.25,0.5,0.75]
            for i=1 to DTerrain.numfaces do meshop.setMapFace DTerrain 2 i (getFace DTerrain i)
            update DTerrain
        )
        cfg[1]=true
        field=cyrusPrepareDensityOverlay #(DTerrain) cfg image mapping 1 2 4096 false filters false #() #(#(),#())
        details=cyrusDensityOverlayInfo field;maximumError=0.
        for triangle=1 to details[1] by step do for corner=1 to 3 do (
            local vertex=cyrusDensityOverlayVertex field triangle corner,expected=0.25*(periodicRamp (vertex[1].x/40.0))
            maximumError=amax maximumError (abs(vertex[2]-expected))
        )
        check (maximumError<0.0001) "Combined image and R/X channel multiply without changing either input" log
        cfg[3]=2;cfg[6]=true;cfg[7]=#(0.,0.25,1.)
        field=cyrusPrepareDensityOverlay #(DTerrain) cfg undefined mapping 1 1 4096 false filters false #() #(#(),#())
        details=cyrusDensityOverlayInfo field
        check (details[2]==0.25 and details[3]==0.25) "G/Y reads numeric channel values; Invert then response order agrees with oracle" log
        check (DTerrain.material==material) "Field preparation does not change the receiver material" log
        check (DRoot.procEpoch==epoch and (cyrusRecipePublicationFingerprint DRoot.groupSnapshotRows)==publication) "All field queries preserve the Manual plant publication" log
        close log
    )catch(if bitmapValue!=undefined do close bitmapValue;format "ERROR %\n" (getCurrentException()) to:log;close log;throw())
)
