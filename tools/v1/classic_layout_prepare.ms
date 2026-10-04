-- Source-load UI fixture, restricted to our disposable classic-layout host.
if not matchPattern BLDir pattern:"*/hosts/classic-layout*/*" do throw "Private classic-layout fixture only"
global CFNode=getNodeByName "Cyrus_Scatter_1_Demo"
if CFNode==undefined do throw "Expected frozen layers demo"
global CFRoot=CFNode.baseObject
select CFNode
max modify mode
modPanel.setCurrentObject CFRoot
windows.processPostedMessages()
CFRoot.mainUI.open=true
CFRoot.mainUI.bind()
for r in CFRoot.nativeEditors() do r.open=false
for p in CFRoot.layerPanels do p.open=false
CFRoot.mainUI.layoutPanels()
windows.processPostedMessages()
if CFRoot.uiVersion()!="1.2.2" do throw "Expected source script version 1.2.2"
CSPWriteText (BLDir+"classic-layout-prepared.json") (CSPObject #(#("script_version",CFRoot.uiVersion()),#("root_rollouts",for r in CFRoot.nativeEditors() collect #(r.title,r.width,r.height,r.open)),#("layer_rollouts",for p in CFRoot.layerPanels collect #(p.title,p.width,p.height,p.open)),#("main_size",#(CFRoot.mainUI.width,CFRoot.mainUI.height)),#("status",CFRoot.allStatus())))
fileIn (BLRoot+"tools/v1/identity_fixture.ms")
