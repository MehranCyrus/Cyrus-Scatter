(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned host required."
    local out=createFile (MCPFixtureDir+"bitmap-uv-probe-"+(timeStamp() as string)+".txt"),source=GalleryBitmapOriginalTexture.coords,baseline=(bitmaptexture()).coords
    for key in #(#mapChannel,#U_Offset,#V_Offset,#U_Tiling,#V_Tiling,#W_Angle,#U_Mirror,#V_Mirror,#U_Tile,#V_Tile,#blur,#Blur_Offset) do setProperty baseline key (getProperty source key)
    for key in getPropNames source do format "% | source % | baseline % | equal %\n" key (getProperty source key) (getProperty baseline key) (CyrusAssetSettingsEqual (getProperty source key) (getProperty baseline key)) to:out
    local a=source.UVTransform,b=baseline.UVTransform
    format "Types % %\n" (classof a) (classof b) to:out
    for i=1 to 4 do for j=1 to 3 do format "[%][%]: % / % = diff %\n" i j a[i][j] b[i][j] (a[i][j]-b[i][j]) to:out
    close out
)
