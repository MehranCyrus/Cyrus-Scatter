-- Select one tree instance in the supplied 0.87.2 Max 2027 trial.
(
 if (maxVersion())[1]!=29000 do throw "This trial requires Max 2027."
 local controllers=for n in objects where classof n.baseObject==AminScatterObject and n.baseObject.overlapOwner==undefined collect n
 if controllers.count!=1 do throw "Open the supplied small-scene trial first."
 local owner=controllers[1],root=owner.baseObject,index=findItem (root.layerNames as array) "Trees"
 if root.version!=61 or root.uiVersion()!="0.87.2" or index<1 do throw "Load the matched 0.87.2 package and trial scene."
 local layer=root.layerObjects[index],mods=for m in owner.modifiers where classof m==CyrusScatterEdit collect m
 if mods.count!=1 do throw "The trial requires its one Cyrus Edit modifier."
 root.selectLayer index;select owner;max modify mode;modPanel.setCurrentObject mods[1];subObjectLevel=1;max move
 cyrusEditActiveLayers mods[1] #(layer.editLayerKey);cyrusEditSelect mods[1] #(1);CyrusPointSync();completeRedraw()
)
