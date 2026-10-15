(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-meshmask-*/" do throw "Owned mask host required"
    local log=createFile (MCPFixtureDir+"mesh-mask-edit-undo.txt")
    fn verify pass label log = (format "%: %\n" (if pass then "PASS" else "FAIL") label to:log;flush log;if not pass do throw label)
    try (
        if theHold.Holding() do throw "Run outside a Python Undo hold."
        CyrusPerfHeadless=true;resetMaxFile #noPrompt
        local node=AminScatterObject name:"Mesh mask Undo",root=node.baseObject
        root.updateMode=1;root.autoRender=false
        local receiver=plane length:40 width:40 lengthsegs:4 widthsegs:4
        convertToMesh receiver
        for i=1 to meshop.getNumMapVerts receiver 1 do meshop.setMapVert receiver 1 i [1,1,1]
        update receiver
        root.newLayer();local leaf=root.selectedLayer();root.setLayerSurfaces leaf #(receiver);leaf.addPointSource()
        leaf.amount=1000;leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.meshMaskChannel=1;leaf.meshMaskEnabled=true
        MeshMaskNode=node;MeshMaskRoot=root;MeshMaskLeaf=leaf;MeshMaskReceiver=receiver
        root.evaluateProcedural()
        local before=for row in root.groupSnapshotRows[1] collect row[1]
        undo "Mesh mask invert test" on leaf.meshMaskInvert=true
        verify (root.groupSnapshotRows[1].count==before.count) "Manual Undoable mask edit retains plants until Update" log
        root.evaluateProcedural()
        verify (leaf.generatedCount==0) "Inverted white mask excludes all candidates" log
        max undo
        verify (not leaf.meshMaskInvert) "Undo restores mask setting" log
        root.evaluateProcedural()
        verify (leaf.generatedCount==before.count) "Undo plus Update restores complete result" log
        max redo
        verify leaf.meshMaskInvert "Redo restores mask setting" log
        root.evaluateProcedural()
        verify (leaf.generatedCount==0) "Redo plus Update restores empty result" log
        leaf.meshMaskInvert=false;root.evaluateProcedural()
        local edit=CyrusScatterEdit();addModifier node edit;root.evaluateProcedural()
        cyrusEditSelect edit #(1,2);cyrusEditCommand edit 4 (transMatrix [0,0,2]);root.evaluateProcedural()
        local protected=for row in root.groupSnapshotRows[1] where row[7] collect row
        verify (protected.count==2) "Two real protected Edit transforms are published" log
        local binding=leaf.procBindingKey,transforms=for row in protected collect #(row[3],row[1])
        leaf.meshMaskInvert=true;root.evaluateProcedural()
        verify (leaf.generatedCount==0 and leaf.procBindingKey==binding) "Black mesh mask makes base edits dormant and retains their binding" log
        leaf.meshMaskInvert=false;root.evaluateProcedural()
        protected=for row in root.groupSnapshotRows[1] where row[7] collect #(row[3],row[1])
        verify (protected as string==transforms as string and leaf.procBindingKey==binding) "Restoring eligibility restores exact saved Edit transforms" log
        MeshMaskEdit=edit
        format "COMPLETE\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
