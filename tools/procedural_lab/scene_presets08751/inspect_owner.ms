global SPInspectOwner=""
for n in refs.dependentNodes SPRoot where n.baseObject==SPRoot do SPInspectOwner+=(n.name+" inScene="+((findItem (objects as array) n) as string)+" mods="+(n.modifiers.count as string)+"\n")
SPInspectOwner+="ownerMatch="+((SPRoot.layerObjects[1].overlapOwner==SPRoot) as string)+"\n"
(dotNetClass "System.IO.File").WriteAllText (GardenRun+"owner.txt") SPInspectOwner
