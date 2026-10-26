(
global IOwner,IRoot,IGrass,IRocks,IEdit,IAssert,IWrite,ISettle,RBaked
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/procedural_lab/interactions087/smoke_driver.ms"
python.ExecuteFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/procedural_lab/interactions087/render_data.py"
IAssert (doesFileExist (GardenRun+"material-bake.json")) "Material/Bake fixture failed."
unhide IOwner
IRoot.autoRender=true
for leaf in IRoot.layerObjects do leaf.autoRender=true
IRoot.interactionsBeforeSave()
IAssert (CyrusPFBuild()) ("First render bridge build failed: "+CyrusPFLastError)
IAssert (IRoot.interactionOutputNodes.count==1) "One private posed source output must be built."
local output=IRoot.interactionOutputNodes[1]
IAssert (findItem CyrusPFNodes output==0) "Private posed outputs must not belong to the disposable PFlow bridge."
CyrusPFClear()
IAssert (isValidNode output) "PFlow cleanup must retain the complete posed output."
hide IOwner;IRoot.interactionsEnsure()
IAssert (IRoot.interactionOutputNodes.count==0) "Hiding the scatter must retire its posed render output."
unhide IOwner;IRoot.interactionsEnsure()
IAssert (IRoot.interactionOutputNodes.count==1) "Unhiding the scatter must reconstruct its posed render output."
IAssert (CyrusPFBuild()) CyrusPFLastError
local colliderPosition=(cyrusEditHandleMatrix IEdit IRocks.editLayerKey 1).translation
local cam=targetCamera name:"Interaction render witness" pos:(colliderPosition+[0,-22,15]) target:(targetObject pos:(colliderPosition+[0,0,-1]))
renderers.current=Default_Scanline_Renderer()
-- Isolate the private posed output in the actual renderer. The full ordinary
-- bridge is separately checked above; this image must exercise GetRenderMesh.
for node in CyrusPFNodes where isValidNode node do node.renderable=false
(getNodeByName "INTERACTION_Receiver").renderable=false
viewport.setCamera cam
local image=render camera:cam width:320 height:240 vfb:false outputfile:(GardenRun+"posed-render.png")
close image
IWrite "render-bridge.json" "{\"status\":\"pass\",\"checks\":[\"PFlow separation\",\"clear/rebuild\",\"owner hide/unhide\",\"actual scanline render of private posed output\"]}"
IWrite "completed.json" "{\"status\":\"pass\",\"host\":2027,\"scope\":\"Small lifecycle suite, full grass UV/material Bake, private output cleanup and visibility, actual scanline render; inspect pixel and world-float delivery receipts separately.\"}"
)
