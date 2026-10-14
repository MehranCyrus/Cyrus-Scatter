(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-p04-*/" do throw "Owned P04 host required"
    local log=createFile (MCPFixtureDir+"phase04-memory.txt")
    fn stage label = ((dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"phase04-memory-stage.txt") label)
    fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
    try (
        CyrusPerfHeadless=true;resetMaxFile #noPrompt;stage "setup"
        local node=AminScatterObject name:"P04 bounded memory",root=node.baseObject
        root.updateMode=1;root.autoRender=false
        local receiver=plane length:100 width:100 lengthsegs:1 widthsegs:1
        for i=1 to 10 do (
            root.newLayer();local leaf=root.selectedLayer()
            root.setLayerSurfaces leaf #(receiver);leaf.addPointSource();leaf.amount=1000
            leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.distributionMode=3;leaf.densityResolution=512
            leaf.densityMap=noise color1:(color 32 32 32) color2:(color 224 224 224)
        )
        stage "ten cold 512 maps and preparation"
        local started=timeStamp();root.evaluateProcedural()
        format "COLD: ten 512-square maps and 10000 candidates ms=%\n" (timeStamp()-started) to:log
        stage "ten inverted 512 arrays"
        for leaf in root.layerObjects do (leaf.invertDensity=true;leaf.procDensityWeights())
        local samples=0;for leaf in root.layerObjects do samples+=(leaf.densityCacheStats())[5]
        verify (samples==10*2*512*512) "Ten layers retain exactly twenty 512-square arrays at the maximum setting" log
        stage "warm mapped publication"
        root.procManualRevision+=1;root.evaluateProcedural()
        verify ((for leaf in root.layerObjects where leaf.generatedCount<=0 or leaf.generatedCount>=1000 or (leaf.densityCacheStats())[1]!=1 collect leaf).count==0) "Inverted successors reuse every map bake and publish their graded density results" log
        stage "replace all maps with 64 samples"
        for leaf in root.layerObjects do leaf.densityResolution=64
        root.procManualRevision+=1;root.evaluateProcedural()
        samples=0;for leaf in root.layerObjects do samples+=(leaf.densityCacheStats())[5]
        verify (samples==10*2*64*64) "Replacing resolution releases all old sample arrays from the retained caches" log
        stage "complete"
        format "COMPLETE\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
