-- Failure after actual asset staging, independent save/reopen, captured review.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned gallery host required."
    local log=createFile (MCPFixtureDir+"package-import-boundaries-"+(timeStamp() as string)+".txt"),savedApply=CyrusRecipeApplySettings,moved="",directory=""
    fn check value message log = (format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
    fn rejected root directory bindings message log = (
        local nodes=objects as array,layers=root.layerObjects as array,epoch=root.procEpoch,rows=cyrusRecipePublicationFingerprint root.groupSnapshotRows,failed=false
        try(CyrusAssetImport (CyrusAssetReview root directory bindings variation:#same))catch(failed=true;format "Expected rejection: %\n" (getCurrentException()) to:log)
        check failed message log
        check (CyrusPresetSameValues nodes (objects as array) and CyrusPresetSameValues layers (root.layerObjects as array)) "Failure restores scene inventory and ordered owners" log
        check (root.procEpoch==epoch and (cyrusRecipePublicationFingerprint root.groupSnapshotRows)==rows and not theHold.Holding()) "Failure retains complete publication and closes its hold" log
    )
    try (
        CyrusPerfHeadless=true
        directory=(dotNetClass "System.IO.File").ReadAllText (MCPFixtureDir+"portable-package-path.txt")
        check (matchPattern directory pattern:"*build*mcp-qualification*foundation-roadmap-gallery0851-*") "Owned package" log
        local expectedLayers=(CyrusRecipeGet (CyrusRecipeGet (cyrusAssetPackageRead directory) "recipe") "layers").count
        moved=directory+"-temporarily-unavailable";(dotNetClass "System.IO.Directory").Move directory moved
        check (loadMaxFile (MCPFixtureDir+"portable-import-scene.max") quiet:true useFileUnits:true) "Imported scene reopens without package files" log
        local node=undefined;for n in objects where classof n.baseObject==AminScatterObject do node=n
        local root=node.baseObject;root.refreshAll()
        check (root.layerObjects.count==2*expectedLayers and root.groupSnapshotRows.count>0) "Reopened layers calculate from their scene-owned assets" log
        for i=(expectedLayers+1) to root.layerObjects.count do for source in root.layerObjects[i].sources do check (isValidNode source and source.isHidden and source.mesh.numfaces>0) "Reopened hidden source contains its own mesh" log
        (dotNetClass "System.IO.Directory").Move moved directory;moved=""
        check (loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/library/borders.max" quiet:true useFileUnits:true) "Fresh original scene for rejection witnesses" log
        node=undefined;for n in objects where classof n.baseObject==AminScatterObject do node=n
        root=node.baseObject;root.refreshAll()
        local package=cyrusAssetPackageRead directory,document=CyrusRecipeGet package "recipe",external=CyrusRecipeGet (CyrusRecipeGet package "graph") "externalRoles",all=CyrusRecipeSuggestBindings root document
        local bindings=for pair in all where findItem external pair[1]>0 collect pair,plan=CyrusAssetReview root directory bindings variation:#same
        undo "Prior import sentinel" on (node.name="Portable boundary sentinel")
        -- Failure after the native source factory has created all meshes and after
        -- the first owner's settings have actually been applied.
        global GalleryAssetSavedApply,GalleryAssetApplyCount;GalleryAssetSavedApply=CyrusRecipeApplySettings;GalleryAssetApplyCount=0
        fn CyrusRecipeApplySettings owner settings bindings variation:#new = (
            GalleryAssetSavedApply owner settings bindings variation:variation
            GalleryAssetApplyCount+=1
            throw "Owned injected failure after asset staging and first-owner setters."
        )
        rejected root directory bindings "Post-staging authored failure rejects atomically" log
        CyrusRecipeApplySettings=savedApply
        max undo;check (node.name!="Portable boundary sentinel") "Failed import preserves preceding Undo" log
        max redo;check (node.name=="Portable boundary sentinel") "Failed import preserves preceding Redo" log
        local stale=CyrusAssetReview root directory bindings variation:#same
        root.layerObjects[1].randomSeed+=1
        local failed=false;try(CyrusAssetImport stale)catch(failed=true)
        check failed "Changed destination invalidates captured review" log
        local wrong=for pair in bindings collect #(pair[1],pair[2]);wrong[1][2]=undefined
        rejected root directory wrong "Missing external binding rejects before mutation" log
        -- New Setup is a distinct authored transaction, with independent sources.
        local before=objects as array,newPlan=CyrusAssetReview root directory bindings newSetup:true variation:#same,result=CyrusAssetImport newPlan
        check (result[1]!=root and result[1].layerObjects.count==expectedLayers) "Create New Setup has fresh independent ownership" log
        local newNode=result[3]
        max undo;check (not isValidNode newNode and CyrusPresetSameValues before (objects as array)) "One Undo removes the new setup and every owned model" log
        max redo;check (isValidNode newNode and result[1].layerObjects.count==expectedLayers) "Redo restores the new setup" log
        result[1].refreshAll();check (result[1].groupSnapshotRows.count>0) "New setup can publish imported sources" log
        check (not theHold.Holding()) "No transaction remains" log
        format "PASS: complete\n" to:log;close log
    )catch(
        CyrusRecipeApplySettings=savedApply
        if moved!="" and doesDirectoryExist moved and not doesDirectoryExist directory do (dotNetClass "System.IO.Directory").Move moved directory
        format "ERROR: %\n" (getCurrentException()) to:log;close log;throw()
    )
)
