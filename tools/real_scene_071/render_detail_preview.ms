(
 RSReload()
 renderWidth=1100;renderHeight=760
 renderers.current.progressive_passLimit=8;renderers.current.progressive_timeLimit=0
 local begin=timeStamp(),frame=render camera:(getNodeByName "02 WALK | planting detail") vfb:false outputfile:(RSOut+"Preview_Detail.png")
 if frame==undefined do throw "No detail render returned"
 close frame
 CSPWriteText (MCPFixtureDir+"render-detail-preview.json") (CSPObject #(#("elapsed_ms",timeStamp()-begin),#("automatic_render_error",CyrusPFLastError)))
)
