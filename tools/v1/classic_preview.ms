if not matchPattern BLDir pattern:"*/hosts/classic-layout*/*" do throw "Private classic-layout fixture only"
if CFLayoutTimer!=undefined do CFLayoutTimer.Stop()
loadMaxFile (BLRoot+"dist/layers-first-1.2.0/Cyrus_Scatter_1.2_Layers_Demo.max") useFileUnits:true quiet:true
fileIn (BLRoot+"tools/v1/classic_layout_prepare.ms")
viewport.setRenderLevel #smoothhighlights
CFRoot.mainUI.scrollPos=0
completeRedraw()
global CFUIBefore=for leaf in CFRoot.layerObjects collect leaf.cacheSnapshot()
global CFUIBeforePaint=for leaf in CFRoot.layerObjects collect leaf.paintCacheStats()
global CFUIDisplay=CyrusPointOwner CFNode
global CFUIBeforeRetained=cyrusRetainedStats CFUIDisplay
