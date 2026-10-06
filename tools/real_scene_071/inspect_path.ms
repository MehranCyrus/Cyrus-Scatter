(
 CSPWriteText (MCPFixtureDir+"path-diagnostic.json") (CSPObject #(#("counts",for leaf in RSRoot.layerObjects collect #(leaf.paintSetName,leaf.generatedCount,leaf.procStatistics(),(leaf.cacheSnapshot())[4],cyrusBrushHistory leaf.paintDocument)),#("layer_order",for owner in RSRoot.logicalLayers() collect RSRoot.layerCaption owner)))
)
