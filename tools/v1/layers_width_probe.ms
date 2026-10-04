-- Isolated native layout diagnostic; does not save or modify artist scenes.
(
if not matchPattern BLDir pattern:"*/hosts/layers-width*/*" do throw "Private width fixture only"
global LWNode=getNodeByName "Cyrus_Scatter_1_Demo",LWRoot
LWRoot=LWNode.baseObject
select LWNode
max modify mode
modPanel.setCurrentObject LWNode
windows.processPostedMessages()
LWRoot.mainUI.open=false
LWRoot.layersUI.open=true
LWRoot.bindNativeUI()
for p in LWRoot.layerPanels do p.open=false
LWRoot.layerPanels[1].open=true
LWRoot.layerPanels[1].mount()
windows.processPostedMessages()
local log=createFile (BLDir+"width-probe.txt")
fn dumpWidth r stream = (
    format "% width=% HWND=% rect=%\n" r r.width r.hwnd (windows.getWindowPos r.hwnd) to:stream
    local handle=r.hwnd
    for i=1 to 4 do (
        handle=windows.getParentHWND handle
        if handle!=0 do format "  parent%: hwnd=% rect=%\n" i handle (windows.getWindowPos handle) to:stream
    )
)
dumpWidth LWRoot.layersUI log
format "subrollout width=% pos=%\n" LWRoot.layersUI.layers.width LWRoot.layersUI.layers.pos to:log
dumpWidth LWRoot.layerPanels[1] log
format "sections width=%\n" LWRoot.layerPanels[1].sections.width to:log
dumpWidth LWRoot.layerPanels[1].editors[1] log
close log
)
