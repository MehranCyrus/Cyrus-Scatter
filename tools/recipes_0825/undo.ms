-- Exercise the real transaction outside Python's enclosing execution hold.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-recipes0825-*/" do throw "Owned recipe host required"
    local log=createFile (MCPFixtureDir+"recipe-undo.txt")
    fn fullRowsEqual a b = (if a.count!=b.count do return false;for i=1 to a.count do (if a[i].count!=b[i].count do return false;for j=1 to a[i].count where a[i][j]!=b[i][j] do return false);true)
    fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
    fn expectFailure action label log = (local rejected=false;try(action())catch(rejected=true);verify rejected label log)
    try (
        verify (not theHold.Holding()) "Native fixture begins outside a hold" log
        CyrusPerfHeadless=true;resetMaxFile #noPrompt;units.SystemType=#meters;units.SystemScale=1
        local node=AminScatterObject name:"Recipe native Undo",root=node.baseObject,terrain=plane length:10 width:10
        convertToMesh terrain;root.updateMode=1;root.autoRender=false
        root.newLayer();local leaf=root.selectedLayer();root.setLayerSurfaces leaf #(terrain);leaf.addPointSource();leaf.amount=80;leaf.procLayerSelfEnabled=false
        local area=root.addPaintArea leaf target:terrain
        area.paintView=0;cyrusBrushFill area.paintDocument 1
        root.refreshAll();CyrusPointSync()
        local epoch=root.procEpoch,before=deepCopy root.groupSnapshotRows[1],payload=(cyrusBrushRecipeExport area.paintDocument)[1]
        local document=CyrusRecipeCapture root #(leaf) "Native Undo recipe",bindings=CyrusRecipeSuggestBindings root document
        leaf.amount=111
        local result=CyrusRecipeImport root document bindings
        verify (root.layerObjects.count==2) "Add commits all owners" log
        local importedID=root.layerObjects[2].layerID
        verify (root.procEpoch==epoch and fullRowsEqual root.groupSnapshotRows[1] before) "Manual import preserves published rows and epoch" log
        verify ((cyrusBrushRecipeExport root.layerObjects[2].paintAreas[1].paintDocument)[1]==payload) "Native transaction restores exact Paint bytes" log
        max undo
        verify (root.layerObjects.count==1 and leaf.amount==111) "One Undo removes the complete import and retains prior pending edits" log
        verify ((cyrusBrushRecipeExport area.paintDocument)[1]==payload) "Undo preserves source Paint" log
        max redo
        verify (root.layerObjects.count==2 and root.layerObjects[2].layerID==importedID) "Redo restores the same imported owner identity" log
        verify ((cyrusBrushRecipeExport root.layerObjects[2].paintAreas[1].paintDocument)[1]==payload) "Redo restores exact imported Paint" log
        local priorRules=root.procRuleA.count,priorNext=root.nextEditLayerKey
        leaf.procPopulation=9
        local failed=false
        try(CyrusRecipeImport root document bindings)catch(failed=true)
        verify failed "Late root validation failure is reported" log
        verify (root.layerObjects.count==2 and root.procRuleA.count==priorRules and root.nextEditLayerKey==priorNext) "Late failure rolls back owner graph, relationships and allocator" log
        verify (root.procEpoch==epoch and fullRowsEqual root.groupSnapshotRows[1] before) "Late failure preserves complete publication" log
        leaf.procPopulation=1
        local unitsDoc=deepCopy document
        CyrusRecipePut unitsDoc "unitsPerMetre" 100.0
        failed=false;try(CyrusRecipeImport root unitsDoc bindings)catch(failed=true)
        verify (failed and root.layerObjects.count==2) "Incompatible native Paint units reject without partial import" log
        leaf.procRadiusIDs=#(root.groupSnapshotRows[1][1][3]);leaf.procRadiusModes=#(1);leaf.procRadiusValues=#(1.0);leaf.procRadiusDistances=#(0.1);leaf.procRadiusBinding=leaf.procBindingKey
        failed=false;try(CyrusRecipeCapture root #(leaf) "Radius guard")catch(failed=true)
        verify (failed and leaf.procRadiusIDs.count==1) "Unsupported authored radius overrides block full save and remain intact" log
        leaf.procClearRadii()
        local savedControl=getPropertyController leaf #rotZMin
        setPropertyController leaf #rotZMin (float_expression())
        failed=false;try(CyrusRecipeCapture root #(leaf) "Controller guard")catch(failed=true)
        verify failed "Wired/expression controller blocks full save" log
        setPropertyController leaf #rotZMin savedControl
        root.refreshAll()
        local edit=CyrusScatterEdit();addModifier node edit;root.refreshAll()
        cyrusEditSelect edit #(1)
        verify (not (cyrusEditRecipeHasData edit)) "Selection-only Edit does not invent authored deltas" log
        local selectedCapture=CyrusRecipeCapture root #(leaf) "Selection is not an authored edit"
        cyrusEditCommand edit 4 (transMatrix [0,0,1]);root.refreshAll()
        failed=false;try(CyrusRecipeCapture root #(leaf) "Authored Edit guard")catch(failed=true)
        verify (failed and cyrusEditRecipeHasData edit) "Actual authored Edit delta blocks full save and remains intact" log
        verify (not theHold.Holding()) "Transaction exits without a leaked hold" log
        global RecipeUndoRoot=root,RecipeUndoNode=node
        format "PASSED\n" to:log
    )catch(format "FAILED: %\n" (getCurrentException()) to:log;close log;throw())
    close log
)
