-- Run only in the disposable width profile. Preserve the released demo file.
if not matchPattern BLDir pattern:"*/hosts/layers-width*/*" do throw "Private width fixture only"
resetMaxFile #noPrompt
fileIn (BLRoot+"AminScatter/scripts/AminScatterObject.ms")
loadMaxFile (BLRoot+"dist/layers-first-1.2.0/Cyrus_Scatter_1.2_Layers_Demo.max") useFileUnits:true quiet:true
fileIn (BLRoot+"tools/v1/layers_width_probe.ms")
viewport.setRenderLevel #smoothhighlights
completeRedraw()
