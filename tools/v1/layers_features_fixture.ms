-- Parent area policy, set-specific Brush history, and unsupported-mode guards.
if findString (toLower BLDir) "/build/cyrus-v1/hosts/"==undefined do throw "Private profile required"
fileIn (BLRoot+"tools/v1/layers_first_load.ms")
(
    fn require value message = if not value do throw message
    local root=LFRoot.baseObject,parent=root.layerObjects[2],grass=root.layerObjects[1],records=#()
    parent.amount=2000;root.setGroupCoverage parent true;cyrusBrushFill parent.paintDocument 1
    local child=root.addPaintSet parent label:"Blue"
    child.sources=#(LFSource);cyrusBrushFill child.paintDocument 1
    local includeShape=rectangle width:160 length:160,excludeShape=rectangle width:50 length:50
    local area=root.layerPanels[2].editors[5]
    area.bind parent;root.activeLayer=1
    area.addArea includeShape;area.addArea excludeShape;parent.areaModes=#(1,2)
    local rows=root.evaluateGroups(),total=0
    for i in #(2,3) do for row in rows[i] do (
        local p=row[1].row4
        require (abs p.x<=80.001 and abs p.y<=80.001 and (abs p.x>=24.999 or abs p.y>=24.999)) "Include/exclude did not apply to every set"
        total+=1
    )
    require (total>100 and total<=2000 and grass.areaNodes.count==0) "Area routing affected another layer"
    append records #("parent_include_exclude",total)
    parent.areaNodes=#();parent.areaModes=#()
    cyrusBrushSettings child.paintDocument 40 1 0 true 1
    cyrusBrushDab child.paintDocument [0,0,100] [0,0,-1] true
    rows=root.evaluateGroups()
    require (rows[2].count==1000 and rows[3].count<1000) "Erase affected another paint set"
    cyrusBrushStroke child.paintDocument 1 false 1 40 0 true
    require ((root.evaluateGroups())[3].count==1000) "Disabling child erase did not restore coverage"
    cyrusBrushStroke child.paintDocument 1 true 1 40 0 true
    append records #("independent_erase_history",true)
    parent.paintEnabled=false;parent.relaxEnabled=true
    require (parent.layerPaintActive() and parent.brushRelaxPaused()) "Sibling Brush failed to pause parent Relax"
    root.refreshAll()
    for leaf in root.layerObjects do require (leaf.previewError=="") "Paused Relax produced a preview error"
    child.paintEnabled=false
    require (not parent.layerPaintActive()) "Inactive sibling Brush kept point Relax paused"
    parent.relaxEnabled=false;child.paintEnabled=true
    grass.diversityMode=3
    local before=root.layerObjects.count,rejected=false
    try(root.addPaintSet grass)catch(rejected=true)
    require (rejected and root.layerObjects.count==before) "Unsupported assignment mutated ownership"
    grass.diversityMode=1
    append records #("relax_and_assignment_guards",true)
    root.updateMode=2;root.refreshAll();grass.amount=123;CyrusViewportRedraw();completeRedraw()
    require (grass.generatedCount==123) "Live update did not publish the changed layer"
    root.updateMode=1;grass.amount=135;CyrusViewportRedraw();completeRedraw()
    require (grass.generatedCount==123 and grass.dirty) "Manual edit published early"
    root.refreshAll();require (grass.generatedCount==135) "Manual Update did not publish"
    append records #("manual_and_live",true)
    CSPWriteText (BLDir+"layers-features.json") (CSPObject records)
)
