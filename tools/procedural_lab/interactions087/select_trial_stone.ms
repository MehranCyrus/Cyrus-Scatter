-- Optional artist helper for the supplied trial. No scene load or deletion.
(
if (maxVersion())[1]!=29000 or CyrusLoadedScriptFingerprint==undefined or CyrusLoadedScriptFingerprint!="7ab4f6baf4855debdacdc89b492071929404eedd302f8bc0f31c94421d86b287" do throw "Use the matching CyrusScatter 0.87.0 Max 2027 build, then restart Max."
if cyrusInteractionVersion==undefined do throw "Install the matching 0.87.0 native modules and restart Max."
local owner=getNodeByName "CyrusScatter 0.87 - Terrace contact study"
if not isValidNode owner do throw "Open one of the supplied Terraces 0.87 trial scenes first."
local root=owner.baseObject
if root.layerObjects.count!=10 or not root.layerObjects[6].interactionCollider do throw "This helper only selects stones in the supplied terrace trial."
local edit=owner.modifiers[1],rocks=root.layerObjects[6]
root.selectLayer 6
select owner;max modify mode;modPanel.setCurrentObject edit;subObjectLevel=1;max move
CyrusPointSync();completeRedraw()
local deadline=timeStamp()+800
while timeStamp()<deadline do (windows.processPostedMessages();redrawViews())
cyrusEditActiveLayers edit #(rocks.editLayerKey);cyrusEditSelect edit #(1);completeRedraw()
)
