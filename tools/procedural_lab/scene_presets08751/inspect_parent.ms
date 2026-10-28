global SPImportedSource=(SPImported.baseObject.layerObjects[1].validSources())[1]
global SPParentText="original="+(SPOriginal.parent as string)+" imported="+(SPImportedSource.parent as string)
try(SPParentText+=" controller="+((SPImportedSource.parent.position.controller) as string)+" keys="+((numKeys SPImportedSource.parent.position.controller) as string))catch(SPParentText+=" error="+getCurrentException())
(dotNetClass "System.IO.File").WriteAllText (GardenRun+"parent.txt") SPParentText
