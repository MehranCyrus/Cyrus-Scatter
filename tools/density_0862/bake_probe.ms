(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 local log=createFile (MCPFixtureDir+"bake-probe.txt"),before=renderMap NMap size:[128,128],path=MCPFixtureDir+"bake-probe.png"
 format "before space=% gamma=% file=% current_snapshot=%\n" before.colorSpace before.gamma before.filename DLayer.densityMap.filename to:log
 before.filename=path;save before;close before
 local raw=openBitmap path colorSpace:ColorPipelineMgr.DataColorSpace,standard=openBitmap path
 local rendered=renderMap DLayer.densityMap size:[128,128]
 format "raw space=% gamma=% standard space=% gamma=% rendered space=% gamma=%\n" raw.colorSpace raw.gamma standard.colorSpace standard.gamma rendered.colorSpace rendered.gamma to:log
 for p in #([5,7],[57,67],[91,111]) do format "% raw=% std=% rendered=% flipped=%\n" p (getPixels raw p 1) (getPixels standard p 1) (getPixels rendered p 1) (getPixels rendered [p.x,127-p.y] 1) to:log
 close raw;close standard;close rendered;close log
)
