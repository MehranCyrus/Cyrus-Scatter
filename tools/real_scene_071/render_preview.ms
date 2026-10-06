(
 if RSRoot==undefined do throw "Build the real scene first"
 if RSRoot.groupPolicy!=3 do throw "Procedural policy is not active"
 local counts=for leaf in RSRoot.layerObjects collect leaf.generatedCount
 for count in counts do if count<=0 do throw "A demonstration population is empty"
 local camera=getNodeByName "01 HERO | garden pavilion"
 renderWidth=1000;renderHeight=720
 renderers.current.progressive_passLimit=8;renderers.current.progressive_timeLimit=0
 local op=renderers.current.colorMap_pipeline
 while op!=undefined do (
  if isProperty op #colorMappingOperator_simpleExposure do op.colorMappingOperator_simpleExposure=-3.2
  op=op.colorMappingOperator_nextOperator
 )
 local started=timeStamp()
 local frame=render camera:camera vfb:false outputfile:(RSOut+"Preview_Hero.png")
 if frame==undefined do throw "Corona returned no bitmap"
 close frame
 CSPWriteText (MCPFixtureDir+"render-preview.json") (CSPObject #(#("elapsed_ms",timeStamp()-started),#("counts",counts),#("pflow_error",CyrusPFLastError),#("passes",CoronaRenderer.getStatistic 0),#("primitives_with_instances",CoronaRenderer.getStatistic 2),#("corona_peak_bytes",CoronaRenderer.getStatistic 10)))
)
