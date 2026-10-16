(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned host required."
    local out=createFile (MCPFixtureDir+"bitmap-probe-"+(timeStamp() as string)+".txt")
    for key in #(#Mode,#OCIOConfigPath,#RenderingColorSpace,#DataColorSpace,#Status,#ModifiedOCIOConfigPath) do try(format "ColorPipeline %: %\n" key (getProperty ColorPipelineMgr key) to:out)catch(format "ColorPipeline %: unavailable\n" key to:out)
    local path=MCPFixtureDir+"owned-bitmap-probe.png",bitmapValue=bitmap 16 16 color:(color 40 150 70) filename:path
    save bitmapValue;close bitmapValue
    local texture=bitmaptexture filename:path
    for value in #(texture.output,texture.bitmap) do (
        format "CLASS %\n" (classof value) to:out
        for key in (if classof value==Bitmap then #(#filename,#width,#height,#numframes,#inputGamma,#inputGammaValue,#gamma,#colorSpace,#colorSpaceStatus,#colorSpaceReq,#aspect) else getPropNames value) do try(format "% | % | %\n" key (classof (getProperty value key)) (getProperty value key) to:out)catch(format "% unavailable\n" key to:out)
    )
    close out
)
