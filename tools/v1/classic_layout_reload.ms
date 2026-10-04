if not matchPattern BLDir pattern:"*/hosts/classic-layout*/*" do throw "Private classic-layout fixture only"
resetMaxFile #noPrompt
fileIn (BLRoot+"AminScatter/scripts/AminScatterObject.ms")
loadMaxFile (BLRoot+"dist/layers-first-1.2.0/Cyrus_Scatter_1.2_Layers_Demo.max") useFileUnits:true quiet:true
fileIn (BLRoot+"tools/v1/classic_layout_prepare.ms")
