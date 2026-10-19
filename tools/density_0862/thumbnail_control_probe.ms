(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/density0862-*/" do throw "Owned profile required"
 global DensityThumbnailProbe
 rollout DensityThumbnailProbe "Owned thumbnail control qualification" width:220 height:120 (
  imgTag fullTile "" pos:[8,8] width:96 height:96 style:#bmp_stretch
 )
 createDialog DensityThumbnailProbe
 local source=openBitmap (MCPFixtureDir+"scripts/Patterns/wide-bands.png")
 DensityThumbnailProbe.fullTile.bitmap=source
 DensityThumbnailProbe.fullTile.bitmap=undefined
 if DensityThumbnailProbe.fullTile.bitmap!=undefined do throw "ImgTag failed to clear"
 DensityThumbnailProbe.fullTile.bitmap=source
 (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"thumbnail-control-probe.txt") "PASS: imgTag accepts the source bitmap, clears undefined, and reassigns the source."
)
