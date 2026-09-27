    parameters areaFalloffSettings (
        fallScaleGraph type:#string default:""
        fallDensityGraph type:#string default:""
        areaFallConfigs type:#stringTab tabSize:0 tabSizeVariable:true
        areaFallScaleGraphs type:#stringTab tabSize:0 tabSizeVariable:true
        areaFallDensityGraphs type:#stringTab tabSize:0 tabSizeVariable:true
        on areaFallConfigs set v i do dirty=true
    )
    fn ensureAreaFalloffs = (
        while areaFallConfigs.count<this.areaNodes.count do append areaFallConfigs ""
        while areaFallScaleGraphs.count<this.areaNodes.count do append areaFallScaleGraphs ""
        while areaFallDensityGraphs.count<this.areaNodes.count do append areaFallDensityGraphs ""
    )
    fn getFallConfig areaNode = (
        ensureFallCurves()
        if areaNode==undefined then #(fallDelete,fallDeleteWidth,fallScale,fallScaleWidth,fallScaleCurve as array,fallDensity,fallDensityWidth,fallDensityCurve as array) else (
            local i=findItem this.areaNodes areaNode
            if i==0 do throw "Area line was removed. Close this graph."
            ensureAreaFalloffs()
            local parts=filterString areaFallConfigs[i] "|"
            if parts.count==8 then #((parts[1] as integer)==1,parts[2] as float,(parts[3] as integer)==1,parts[4] as float,CyrusFallUnpack parts[5],(parts[6] as integer)==1,parts[7] as float,CyrusFallUnpack parts[8]) else #(false,0.0,false,100.0,#(0.0,1.0),false,100.0,#(0.0,1.0))
        )
    )
    fn setFallConfig areaNode cfg = (
        if areaNode==undefined then (
            fallDelete=cfg[1];fallDeleteWidth=cfg[2];fallScale=cfg[3];fallScaleWidth=cfg[4];fallScaleCurve=cfg[5];fallDensity=cfg[6];fallDensityWidth=cfg[7];fallDensityCurve=cfg[8]
        ) else (
            local i=findItem this.areaNodes areaNode
            if i==0 do throw "Area line was removed. Close this graph."
            ensureAreaFalloffs()
            local s=stringStream ""
            format "%|%|%|%|%|%|%|%" (if cfg[1] then 1 else 0) cfg[2] (if cfg[3] then 1 else 0) cfg[4] (CyrusFallPack cfg[5]) (if cfg[6] then 1 else 0) cfg[7] (CyrusFallPack cfg[8]) to:s
            areaFallConfigs[i]=s as string
        )
        dirty=true
    )
    fn getFallGraph areaNode density = (
        if areaNode==undefined then (if density then fallDensityGraph else fallScaleGraph) else (
            ensureAreaFalloffs();local i=findItem this.areaNodes areaNode
            if i==0 then "" else (if density then areaFallDensityGraphs[i] else areaFallScaleGraphs[i])
        )
    )
    fn setFallGraph areaNode density data = (
        if areaNode==undefined then (if density then fallDensityGraph=data else fallScaleGraph=data) else (
            ensureAreaFalloffs();local i=findItem this.areaNodes areaNode
            if i>0 do (if density then areaFallDensityGraphs[i]=data else areaFallScaleGraphs[i]=data)
        )
    )
    fn applyFalloff rows = (
        local cfg=getFallConfig undefined
        if cfg[1] or cfg[3] or cfg[6] do (
            if not (CyrusAnalyzerFilter fallAnalyzer) do throw "Area Edge Falloff: pick a Surface Analyzer."
            local paths=fallAnalyzer.packedLines fallAnalyzer.boundaryVertices fallAnalyzer.boundaryCounts
            if paths.count==0 do throw "Area Edge Falloff: Analyzer has no Boundary. Run Analyze first."
            rows=cyrusBoundaryFalloff rows paths cfg randomSeed
        )
        for i=1 to this.areaNodes.count where isValidNode this.areaNodes[i] do (
            cfg=getFallConfig this.areaNodes[i]
            if cfg[1] or cfg[3] or cfg[6] do rows=cyrusAreaFalloff rows this.areaNodes[i] cfg randomSeed (if i<=this.areaModes.count then this.areaModes[i] else 1)
        )
        rows
    )

