dotNet.loadAssembly "Autodesk.Max"
global SPCore=(dotNetClass "Autodesk.Max.GlobalInterface").Instance.COREInterface
global SPBefore=theHold.getUndoNames()
global SPResult=SPCore.MergeFromFile SPFile true false false 1000 undefined 1000 0 true undefined false
(dotNetClass "System.IO.File").WriteAllText (GardenRun+"sdk-merge.txt") ((SPBefore as string)+"\n"+(SPResult as string)+"\n"+((theHold.getUndoNames()) as string))
