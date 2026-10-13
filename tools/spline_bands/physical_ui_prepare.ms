-- Prepare only disposable authoring data. Physical actions are recorded separately.
(
if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-spline-*" do throw "Owned spline host required"
if CyrusFalloffGraph!=undefined do try(destroyDialog CyrusFalloffGraph)catch()
CyrusStopBrush();resetMaxFile #noPrompt
fileIn (MCPFixtureDir+"../../../AminScatter/scripts/AminScatterObject.ms")
global PhysicalNode=AminScatterObject name:"Owned physical Band acceptance"
global PhysicalRoot=PhysicalNode.baseObject
PhysicalRoot.updateMode=1;PhysicalRoot.autoRender=false;PhysicalRoot.newLayer()
global PhysicalLeaf=PhysicalRoot.selectedLayer()
global PhysicalReceiver=plane width:240 length:240 widthsegs:2 lengthsegs:2
global PhysicalSource=box width:3 length:3 height:5 pos:[350,0,0]
global PhysicalPath=rectangle name:"Main Garden Path" width:80 length:80
global PhysicalOtherPath=rectangle name:"Second Garden Path" width:50 length:50 pos:[70,0,0]
PhysicalRoot.setLayerSurfaces PhysicalLeaf #(PhysicalReceiver)
PhysicalLeaf.sources=#(PhysicalSource);PhysicalLeaf.amount=600;PhysicalLeaf.diversityMode=3
PhysicalLeaf.addStroke PhysicalPath;PhysicalLeaf.addStroke PhysicalPath;PhysicalLeaf.addStroke PhysicalOtherPath
PhysicalLeaf.patternWidths=#(15.,25.,20.)
for b=1 to 3 do PhysicalLeaf.setStrokeSelection b 2 #(PhysicalSource)
PhysicalLeaf.procSelfEnabled=false;PhysicalLeaf.procLayerSelfEnabled=false
PhysicalRoot.setGroupDisplay 4;PhysicalRoot.evaluateProcedural()
global PhysicalEpoch=PhysicalRoot.procEpoch
global PhysicalFingerprint=cyrusEditFingerprint PhysicalRoot.groupSnapshotRows[1] "physical"
hide #(PhysicalReceiver,PhysicalSource,PhysicalPath,PhysicalOtherPath)
select PhysicalNode;max modify mode
if not PhysicalRoot.mainUI.controlsReady do PhysicalRoot.mainUI.mountTimer.tick()
PhysicalRoot.mainUI.selectLayerView PhysicalLeaf
PhysicalRoot.layoutUI.open=true;PhysicalRoot.mainUI.bindSection PhysicalRoot.layoutUI
select PhysicalNode;max modify mode
if not PhysicalRoot.mainUI.controlsReady do PhysicalRoot.mainUI.mountTimer.tick()
PhysicalRoot.layoutUI.open=true;PhysicalRoot.mainUI.bindSection PhysicalRoot.layoutUI
global PhysicalPage=PhysicalRoot.layoutUI
PhysicalPage.diversityUI_selectedPathID=PhysicalLeaf.strokePathIDs[1]
PhysicalPage.diversityUI_selectedBandID=PhysicalLeaf.strokeIDs[1]
PhysicalPage.diversityUI_updatePattern();PhysicalPage.layout()
viewport.setType #view_top;viewport.setGridVisibility #all false
viewport.ZoomToBounds false [-130,-130,-10] [130,130,30]
completeRedraw()
)
