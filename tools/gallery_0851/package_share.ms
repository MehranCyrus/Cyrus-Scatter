-- Explicit borrowed asset references, including non-Cyrus dependents.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned host required."
    local log=createFile (MCPFixtureDir+"package-share-"+(timeStamp() as string)+".txt"),moved="",directory=""
    fn check value message log=(format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
    fn settle editor=(local start=timeStamp();while editor.progress.active and timeStamp()-start<30000 do ((dotNetClass "System.Threading.Thread").Sleep 10;if editor.progress.active do editor.progress.tick());if editor.progress.active do throw "Preparation timeout.")
    try (
        local root=GalleryExportRoot,node=CyrusRecipeOwnerNode root
        directory=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"portable-package-path.txt")
        local sources=#();for owner in root.layerObjects do for source in owner.sources do appendIfUnique sources source
        local external=box name:"Independent non-Cyrus material user" material:sources[1].material
        local beforeNodes=objects as array,beforeLayers=root.layerObjects as array,rows=cyrusRecipePublicationFingerprint root.groupSnapshotRows,epoch=root.procEpoch
        CyrusOpenAssetImport root directory;local editor=CyrusAssetImportEditor;settle editor
        editor.assets.selection=2;editor.readyPackage editor.package;editor.suggest.pressed();editor.variation.selection=2
        for pair in editor.bindings do check (pair[2]!=undefined) "Every reused role has an explicit binding" log
        editor.review.pressed();check editor.commit.enabled ("Reuse review: "+editor.status.text) log
        local savedPlan=editor.plan
        editor.commit.pressed();settle editor;check (matchPattern editor.status.text pattern:"Loaded*") ("Reuse load: "+editor.status.text) log
        check (CyrusPresetSameValues beforeNodes (objects as array)) "Reuse adds no source nodes and keeps external dependents" log
        local imported=for owner in root.layerObjects where findItem beforeLayers owner==0 collect owner
        for owner in imported do for source in owner.sources do check (findItem sources source>0) "New layers share the chosen source object identity" log
        check (imported[1].densityMap==GalleryBitmapOriginalTexture and external.material==GalleryBitmapOriginalMaterial) "Reused materials/maps remain shared with non-Cyrus dependents" log
        check (root.procEpoch==epoch and (cyrusRecipePublicationFingerprint root.groupSnapshotRows)==rows) "Manual reuse retains the previous publication" log
        moved=directory+"-temporarily-unavailable";(dotNetClass "System.IO.Directory").Move directory moved
        max undo;check (CyrusPresetSameValues beforeLayers (root.layerObjects as array) and CyrusPresetSameValues beforeNodes (objects as array)) "One Undo removes only imported layers" log
        max redo;check (root.layerObjects.count==beforeLayers.count+imported.count and isValidNode external and isValidNode sources[1]) "Redo restores shared layers without package access" log
        (dotNetClass "System.IO.Directory").Move moved directory;moved=""
        destroyDialog editor
        -- A newly reviewed plan must notice an external material/geometry edit.
        local package=cyrusAssetPackageRead directory,bindings=CyrusRecipeSuggestBindings root (CyrusRecipeGet package "recipe")
        local plan=CyrusAssetReview root directory bindings variation:#same assets:#share
        local original=GalleryBitmapOriginalMaterial.diffuse
        GalleryBitmapOriginalMaterial.diffuse=color 4 5 6
        local rejected=false
        try(CyrusAssetImport plan)catch(rejected=matchPattern (getCurrentException()) pattern:"*shared source*changed*")
        check rejected "Same reference with changed material content rejects before import" log
        check (CyrusPresetSameValues beforeNodes (objects as array) and root.layerObjects.count==beforeLayers.count+imported.count) "Stale shared plan preserves owners and node inventory" log
        GalleryBitmapOriginalMaterial.diffuse=original
        plan=CyrusAssetReview root directory bindings newSetup:true variation:#same assets:#share
        local result=CyrusAssetImport plan,newRoot=result[1],newNode=result[3]
        check (newRoot!=root and isValidNode newNode and newRoot.layerObjects[1].sources[1]==sources[1]) "Separate setup deliberately shares the same source" log
        undo "Delete sharing setup" on delete newNode
        check (isValidNode sources[1] and isValidNode external and root.layerObjects[1].sources[1]==sources[1]) "Deleting one setup retains shared sources and independent users" log
        max undo
        check (saveMaxFile (MCPFixtureDir+"shared-package-scene.max") quiet:true) "Shared references save" log
        local id=newRoot.layerID,sourceName=sources[1].name
        check (loadMaxFile (MCPFixtureDir+"shared-package-scene.max") quiet:true useFileUnits:true) "Shared scene reopens" log
        local roots=for n in objects where classof n.baseObject==AminScatterObject collect n.baseObject
        check (roots.count==2 and roots[1].layerObjects[1].sources[1]==roots[2].layerObjects[1].sources[1]) "Reopen preserves two setups sharing one model" log
        format "PASS: complete\n" to:log;close log
    )catch(
        if moved!="" and doesDirectoryExist moved and not doesDirectoryExist directory do (dotNetClass "System.IO.Directory").Move moved directory
        format "ERROR: %\n" (getCurrentException()) to:log;close log;throw()
    )
)
