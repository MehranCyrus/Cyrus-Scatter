global SPBefore=theHold.getUndoNames(),SPRecord,SPMerged=false,SPAddUndo,SPMergeUndo
undo "Import scene preset probe" on (
    SPRecord=objXRefMgr.AddXRefItemsFromFile SPFile promptObjNames:false xrefOptions:#(#mergeModifiers,#mergeControllers,#mergeMaterials,#mergeChildren)
    SPAddUndo=theHold.getUndoNames()
    SPMerged=objXRefMgr.MergeRecordIntoScene SPRecord
    SPMergeUndo=theHold.getUndoNames()
)
(dotNetClass "System.IO.File").WriteAllText (GardenRun+"xref-merge.txt") ((SPBefore as string)+"\n"+(SPMerged as string)+"\n"+(SPAddUndo as string)+"\n"+(SPMergeUndo as string))
