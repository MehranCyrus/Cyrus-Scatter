(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p04-*/" do throw "Owned P04 host required"
    local log=createFile (MCPFixtureDir+"phase04-edges.txt")
    fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
    fn evaluate root = (root.procManualRevision+=1;root.evaluateProcedural())
    try (
        CyrusPerfHeadless=true;resetMaxFile #noPrompt
        local node=AminScatterObject name:"P04 edge cases",root=node.baseObject
        root.updateMode=1;root.autoRender=false
        local receiver=plane length:100 width:100 lengthsegs:1 widthsegs:1
        convertToMesh receiver;meshop.setNumMaps receiver 100 keep:true;meshop.setMapSupport receiver 99 true
        local vertices=meshop.getNumMapVerts receiver 1
        meshop.setNumMapVerts receiver 99 vertices;meshop.setNumMapFaces receiver 99 receiver.numfaces
        for i=1 to vertices do meshop.setMapVert receiver 99 i (meshop.getMapVert receiver 1 i)
        for i=1 to receiver.numfaces do meshop.setMapFace receiver 99 i (meshop.getMapFace receiver 1 i)
        update receiver
        root.newLayer();local first=root.selectedLayer()
        root.setLayerSurfaces first #(receiver);first.addPointSource();first.amount=1000
        first.procSelfOverride=true;first.procSelfEnabled=false;first.distributionMode=3
        first.densityMap=checker color1:white color2:white;first.densityUVChannel=99
        evaluate root
        verify (first.generatedCount==1000) "Highest supported texture channel 99 is transported" log
        local before=cyrusEditFingerprint root.groupSnapshotRows[1] "P04",epoch=root.procEpoch,reason=""
        first.densityUVChannel=100
        try(evaluate root)catch(reason=getCurrentException())
        verify (findString reason "1..99"!=undefined and root.procEpoch==epoch) "Out-of-range UV channel rejects before publication" log
        first.densityUVChannel=99
        local uvIndex=(meshop.getMapFace receiver 99 1).x as integer,uv=meshop.getMapVert receiver 99 uvIndex
        meshop.setMapVert receiver 99 uvIndex [(bit.intAsFloat 2143289344),0,0];update receiver
        reason="";try(evaluate root)catch(reason=getCurrentException())
        verify (findString reason "nonfinite"!=undefined and root.procEpoch==epoch and cyrusEditFingerprint root.groupSnapshotRows[1] "P04"==before) "Nonfinite referenced UV rejects with previous publication intact" log
        meshop.setMapVert receiver 99 uvIndex uv;update receiver;evaluate root
        -- One-pixel stripe cannot be reliably captured by every coarse grid.
        local file=MCPFixtureDir+"P04_one_pixel.bmp",image=bitmap 512 512 color:black filename:file
        for y=0 to 511 do setPixels image [123,y] #(white)
        save image;close image
        first.densityMap=bitmaptexture filename:file filtering:2
        local nonzero=#()
        for resolution in #(64,128,256,512) do (
            first.densityResolution=resolution
            local weights=first.procDensityWeights(),positive=(for w in weights where w>0.5 collect w).count
            append nonzero positive
            format "DETAIL: resolution=% high_weight_pixels=% bake_ms=%\n" resolution positive (first.densityCacheStats())[4] to:log
        )
        verify (nonzero[4]>=512 and nonzero[1]<64) "512 sampling resolves the fixture's thin stripe that 64 misses" log
        first.densityMap=checker color1:white color2:white;first.densityResolution=512;evaluate root
        local weights=first.procDensityWeights(),bakes=(first.densityCacheStats())[1],start=timeStamp()
        for i=1 to 100 do if first.procDensityWeights()!=weights do throw "Warm bake copied samples"
        verify ((first.densityCacheStats())[1]==bakes and (first.densityCacheStats())[5]==512*512) "100 warm reads reuse the identical bounded sample array" log
        format "WARM: 100 cache reads ms=%\n" (timeStamp()-start) to:log
        first.invertDensity=true;first.procDensityWeights()
        verify ((first.densityCacheStats())[5]==2*512*512) "Maximum retained inversion cache is two 512-square arrays" log
        first.invertDensity=false
        root.newLayer();local second=root.selectedLayer()
        root.setLayerSurfaces second #(receiver);second.addPointSource();second.amount=20
        second.procSelfOverride=true;second.procSelfEnabled=false;evaluate root
        before=cyrusEditFingerprint root.groupSnapshotRows[1] "P04";epoch=root.procEpoch;bakes=(first.densityCacheStats())[1]
        first.densityResolution=256;first.densityMap=checker color1:black color2:black;second.sourceWeights=#(-1.0)
        reason="";try(evaluate root)catch(reason=getCurrentException())
        verify (reason!="" and (first.densityCacheStats())[1]>bakes) "Later owner fails after the first owner's new map bake" log
        verify (root.procEpoch==epoch and first.generatedCount==1000 and cyrusEditFingerprint root.groupSnapshotRows[1] "P04"==before) "Late failure retains preceding complete published result" log
        second.sourceWeights=#(1.0);evaluate root
        verify (first.generatedCount==0 and second.generatedCount==20) "Repair publishes both owners together" log
        format "COMPLETE\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
