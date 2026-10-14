(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-*/" do throw "Owned P04 host required"
    local log=createFile (MCPFixtureDir+"phase04-edit-saved.txt")
    fn verify value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
    try (
        local year=if (maxVersion())[1]>=29000 then "2027" else "2026"
        local scene=pathConfig.appendPath (pathConfig.appendPath MCPFixtureDir "..") ("foundation-roadmap-p03-max"+year+"-02/P03_lifecycle.max")
        if not doesFileExist scene do throw "Qualified owned P03 scene is unavailable"
        CyrusPerfHeadless=true;resetMaxFile #noPrompt;loadMaxFile scene quiet:true
        local node=getNodeByName "P03 lifecycle",root=node.baseObject,leaf=root.layerObjects[1]
        verify (root.uiVersion()=="0.85.0" and leaf.densityUVChannel==1 and leaf.densityResolution==128) "Saved P03 scene receives neutral density controls" log
        root.refreshAll()
        verify (leaf.generatedCount==70 and leaf.slopeEnabled and leaf.altitudeEnabled) "Saved P03 filter behavior remains intact" log
        resetMaxFile #noPrompt
        node=AminScatterObject name:"P04 Edit density";root=node.baseObject;root.updateMode=1;root.autoRender=false
        local receiver=plane length:50 width:50 lengthsegs:1 widthsegs:1
        root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces leaf #(receiver);leaf.addPointSource();leaf.amount=100
        leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.distributionMode=3
        leaf.densityMap=checker color1:white color2:white
        root.evaluateProcedural()
        local edit=CyrusScatterEdit();addModifier node edit;root.evaluateProcedural()
        cyrusEditSelect edit #(1,2);cyrusEditCommand edit 4 (transMatrix [0,0,10]);root.evaluateProcedural()
        local protected=for row in root.groupSnapshotRows[1] where row[7] collect row
        verify (protected.count==2) "Real Edit stores two protected transforms" log
        local before=cyrusEditFingerprint root.groupSnapshotRows[1] "P04",binding=leaf.procBindingKey
        leaf.densityResolution=64;root.evaluateProcedural()
        verify (cyrusEditFingerprint root.groupSnapshotRows[1] "P04"==before and leaf.procBindingKey==binding) "Resolution-only edit preserves complete rows and Edit binding for a white map" log
        leaf.densityMap.color1=black;leaf.densityMap.color2=black;root.evaluateProcedural()
        verify (leaf.generatedCount==0 and leaf.procBindingKey==binding) "Zero map density makes edited base candidates dormant without changing their binding" log
        leaf.densityMap.color1=white;leaf.densityMap.color2=white;root.evaluateProcedural()
        verify (cyrusEditFingerprint root.groupSnapshotRows[1] "P04"==before and leaf.procBindingKey==binding) "Restoring map eligibility restores all rows and exact saved Edit transforms" log
        format "COMPLETE\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
