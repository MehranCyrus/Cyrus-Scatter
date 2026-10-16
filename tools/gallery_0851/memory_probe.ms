(
 local log=createFile (MCPFixtureDir+"memory-probe-"+(timeStamp() as string)+".txt")
 format "heapSize=% free=% roots=% timeOwners=% pointOwners=% records=%\n" heapSize heapFree (for n in objects where classof n.baseObject==AminScatterObject collect n).count CyrusTimeOwners.count CyrusPointOwners.count CyrusViewportRecords.count to:log
 format "OpenData=% Editor=%\n" CyrusAssetImportOpenData CyrusAssetImportEditor to:log
 format "SceneOwners=% Jobs=%\n" CyrusPointSceneOwners.count CyrusAssetJobs.count to:log
 local instances=getClassInstances AminScatterObject processAllAnimatables:true
 format "All instances=%\n" instances.count to:log
 for n in instances do format "instance=% cachedRows=% owners=% overlap=% refs=%\n" n.layerID n.procPreparedRows.count n.layerObjects.count (try(n.overlapOwner)catch(undefined)) (refs.dependents n) to:log
 local startFree=heapFree,undoNames=theHold.GetUndoNames(),redoNames=theHold.GetRedoNames()
 gc light:true
 format "LightGC before=% after=% undo=% redo=% sameUndo=% sameRedo=%\n" startFree heapFree undoNames redoNames (CyrusPresetSameValues undoNames (theHold.GetUndoNames())) (CyrusPresetSameValues redoNames (theHold.GetRedoNames())) to:log
 format "heap details:%\n" (heapFree as string) to:log
 close log
)
