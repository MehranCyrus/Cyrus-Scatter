(
 local f=createFile (MCPFixtureDir+"build-diagnostic.txt")
 for leaf in RSRoot.layerObjects do (
  format "\nLEAF %\n" leaf.paintSetName to:f
  for k in #(#amount,#procPopulation,#populationMode,#distributionMode,#diversityMode,#advancedAxes,#sourceWeights,#sourceColors,#scaleMinimum,#scaleMaximum,#rotXMin,#rotXMax,#sclXMin,#sclXMax,#areaNodes,#sourceScales,#areaModes,#densityMap) do format "%: %\n" k (getProperty leaf k) to:f
 )
 format "mesh faces % tverts %\n" RSSurface.numfaces RSSurface.numTVerts to:f
 try(RSRoot.evaluateGroups();format "OK\n" to:f)catch(format "%\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:f)
 close f
)
