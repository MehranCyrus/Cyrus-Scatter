-- Focused ownership/UI contract; the independent-group/output suites run too.
if findString (toLower BLDir) "/build/cyrus-v1/hosts/"==undefined do throw "Private profile required"
fileIn (BLRoot+"tools/v1/layers_first_load.ms")
(
    fn require value message = if not value do throw message
    local root=LFRoot.baseObject,grass=root.layerObjects[1],flowers=root.layerObjects[2],records=#()
    local panels=root.layerPanels,first=panels[1].editors,second=panels[2].editors
    require (panels.count==2 and first.count==10 and second.count==10) "Missing per-layer feature editors"
    for r in first where isProperty r #obj and not isProperty r #currentLayer do require (r.obj==grass) "Grass editor bound to another layer"
    for r in second where isProperty r #obj and not isProperty r #currentLayer do require (r.obj==flowers) "Flowers editor bound to another layer"
    local rect=windows.getWindowPos root.layersUI.hwnd,handles=for r in first collect r.hwnd,start=timeStamp()
    for i=1 to 30 do (
        first[7].open=not first[7].open;second[3].open=not second[3].open
        windows.processPostedMessages()
        local next=windows.getWindowPos root.layersUI.hwnd
        require (next.w==rect.w and next.h==rect.h) "Section expansion resized outer Layers host"
        require ((for r in first collect r.hwnd) as string==handles as string) "Section expansion remounted controls"
    )
    append records #("sixty_section_toggles_ms",timeStamp()-start)
    -- The event closures use the captured owner even when activeLayer changes.
    root.activeLayer=2
    first[7].obj.rotXMin=35;first[7].resetBoundRandomization #rotation
    require (grass.rotXMin==0 and flowers.rotXMin==0) "Bound transform reset failed"
    flowers.rotXMin=44;first[7].obj.rotXMin=12;first[7].resetBoundRandomization #rotation
    require (grass.rotXMin==0 and flowers.rotXMin==44) "Grass reset changed Flowers"
    flowers.rotXMin=0
    append records #("independent_editors_and_reset",true)
    flowers.amount=91;flowers.paintSetName="Red";root.setGroupCoverage flowers true;cyrusBrushFill flowers.paintDocument 1
    local blue=root.addPaintSet flowers label:"Blue",yellow=root.addPaintSet flowers label:"Yellow"
    blue.sources=#(LFSource);yellow.sources=#(LFSource)
    cyrusBrushFill blue.paintDocument 1;cyrusBrushFill yellow.paintDocument 1
    root.syncLogicalSettings()
    local allocations=for leaf in root.layerSets flowers collect (root.populationAllocation leaf)[1]
    require (allocations as string=="#(31, 30, 30)") "Parent count was not deterministically shared"
    require ((root.logicalLayers()).count==2 and root.layerObjects.count==4) "Paint sets became top-level layers"
    require (flowers.paintDocument!=blue.paintDocument and blue.paintDocument!=yellow.paintDocument) "Sets share a paint document"
    root.refreshAll();local rows=root.evaluateGroups(),placed=0
    for i=2 to 4 do placed+=rows[i].count
    require (placed==91) "Adding sets multiplied or lost the parent budget"
    require (root.layerPanels[1]==panels[1] and root.layerPanels[2]==panels[2]) "Adding a set rebuilt unrelated layer panels"
    flowers.uiPaintSetID=blue.layerID;panels[2].bindEditors()
    require (second[2].obj==blue and second[4].obj==blue and second[7].obj==flowers and first[2].obj==grass) "Set source/Brush routing or parent settings changed owner"
    flowers.sclXMin=1.3;flowers.sclXMax=1.3;root.syncLogicalSettings()
    require (blue.sclXMin==1.3 and yellow.sclXMax==1.3) "Parent transforms did not reach all sets"
    flowers.collisionEnabled=true;flowers.collisionRadius=12;root.refreshAll();rows=root.evaluateGroups()
    local union=#()
    for i=2 to 4 do join union rows[i]
    for i=1 to union.count do for j=i+1 to union.count do require (distance union[i][1].row4 union[j][1].row4>=23.999) "Collision across paint sets failed"
    append records #("shared_budget_and_collision",union.count)
    root.setGroupPair grass flowers true 10 false true
    root.refreshAll();rows=root.evaluateGroups()
    for a in rows[1] do for i=2 to 4 do for b in rows[i] do require (distance a[1].row4 b[1].row4>=9.999) "Parent rule did not reach every set"
    root.layerVisible[2]=false
    require ((root.viewportLayerEntries false).count==1 and (root.evaluateGroups())[2].count==rows[2].count) "Hiding parent changed output or left a child visible"
    root.layerVisible[2]=true;root.layerEnabled[2]=false
    rows=root.evaluateGroups();for i=2 to 4 do require (rows[i].count==0) "Disabled parent left active children"
    root.layerEnabled[2]=true
    blue.paintSetEnabled=false
    require ((root.populationAllocation blue)[1]==0 and (root.evaluateGroups())[3].count==0) "Disabled set retained population"
    blue.paintSetEnabled=true
    local clone=root.copyLogicalLayer flowers
    require ((root.layerSets clone).count==3 and clone.layerID!=flowers.layerID) "Copy lost membership or identity"
    local cloned=root.layerSets clone,original=root.layerSets flowers
    for i=1 to 3 do require (cloned[i].paintDocument!=original[i].paintDocument and cloned[i].layerID!=original[i].layerID) "Copy shares paint or IDs"
    local copyID=clone.layerID
    root.removeLogicalLayer clone
    require ((root.logicalLayers()).count==2 and root.layerObjects.count==4) "Remove did not remove entire owned set"
    max undo
    require (root.layerObjects.count==7 and (root.layerSets clone).count==3) "Remove Undo lost membership"
    max redo
    require (root.layerObjects.count==4) "Remove Redo lost ownership"
    root.bindNativeUI()
    append records #("visibility_enable_copy_delete_undo",true)
    -- Cleanup is over the accepted union. Two sets with 1 candidate each are
    -- neighbors at a large radius; cleaning separately would remove both.
    flowers.amount=2;flowers.collisionEnabled=false;yellow.paintSetEnabled=false
    flowers.finalCleanup=true;flowers.finalNeighborRadius=1000;flowers.finalMinNeighbors=1;flowers.finalMinIsland=2
    root.setGroupPair grass flowers false 0 false true
    rows=root.evaluateGroups()
    require (rows[2].count==1 and rows[3].count==1) "Cleanup ignored neighbors in another set"
    append records #("cleanup_over_union",true)
    flowers.finalCleanup=false;flowers.populationMode=2;yellow.paintSetEnabled=true
    local meters=units.decodeValue "1m",area=(aminScatterSurfaceArea #(LFSurface))/(meters*meters)
    flowers.plantsPerM2=100.0/area
    rows=root.evaluateGroups()
    require (rows[2].count+rows[3].count+rows[4].count==100) "Density was multiplied by set count or rounding"
    flowers.populationMode=1
    append records #("density_budget_shared",true)
    flowers.finalCleanup=false;flowers.amount=91;yellow.paintSetEnabled=true;root.refreshAll()
    local saved=#()
    for leaf in root.layerObjects do append saved #(leaf.layerID,leaf.logicalParentID,leaf.paintSetName,leaf.paintSetWeight,leaf.paintSetEnabled,leaf.paintSetVisible,cyrusEditFingerprint (leaf.placements (leaf.validSources()) previewOnly:true) "ownership")
    local stream=createFile (BLDir+"layers-reopen-expected.ms")
    with printAllElements on format "global LFOwnershipExpected=%\n" saved to:stream
    close stream
    saveMaxFile (BLDir+"layers-qualified.max") quiet:true
    CSPWriteText (BLDir+"layers-first-acceptance.json") (CSPObject records)
)
