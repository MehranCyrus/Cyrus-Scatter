(
 -- Two real Corona views of the saved procedural scene, with automatic PFlow output.
 RSReload()
 global RSRenderReceipts=#()
 renderers.current.progressive_passLimit=8;renderers.current.progressive_timeLimit=0
 renderWidth=1200;renderHeight=840
 for spec in #(#("01 HERO | garden pavilion","01_Garden_Pavilion_Hero.png"),#("02 WALK | planting detail","02_Garden_Walk_Detail.png")) do (
  local started=timeStamp()
  CSPWriteText (MCPFixtureDir+"render-progress.json") (CSPObject #(#("view",spec[1]),#("state","rendering"),#("previous",RSRenderReceipts)))
  local camera=getNodeByName spec[1]
  local frame=render camera:camera vfb:false outputfile:(RSOut+spec[2])
  if frame==undefined do throw "Corona returned no frame"
  close frame
  append RSRenderReceipts #(spec[1],spec[2],timeStamp()-started,CyrusPFLastError)
  CSPWriteText (MCPFixtureDir+"render-final.json") (CSPObject #(#("views",RSRenderReceipts),#("resolution",#(1200,840)),#("pass_limit",8),#("threads",8),#("renderer",CoronaRenderer.getVersionString()),#("finished",RSRenderReceipts.count==2)))
 )
 CSPWriteText (MCPFixtureDir+"render-progress.json") (CSPObject #(#("state","finished"),#("views",RSRenderReceipts)))
)
