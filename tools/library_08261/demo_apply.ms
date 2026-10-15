-- Actual UI transaction, outside Python's implicit hold and undo-off scope.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-library08261-*/" do throw "Owned library host required."
    local log=createFile (MCPFixtureDir+"demo-"+VerifyDemoSlug+"-apply.txt")
    format "REQUEST: %\nDEMO: %\n" MCPFixtureLast VerifyDemoSlug to:log
    fn check value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
    fn controllers = (for node in objects where classof node.baseObject==AminScatterObject collect node)
    fn paintBytes root = (local values=#();for owner in root.layerObjects do for area in owner.paintAreas do append values (cyrusBrushRecipeExport area.paintDocument)[1];values)
    fn equalPaint a b = (if a.count!=b.count do return false;for i=1 to a.count where a[i]!=b[i] do return false;true)
    fn equalRows a b = (
        if a.count!=b.count do return false
        for l=1 to a.count do (
            if a[l].count!=b[l].count do return false
            for i=1 to a[l].count do (if a[l][i].count!=b[l][i].count do return false;for j=1 to a[l][i].count where a[l][i][j]!=b[l][i][j] do return false)
        );true
    )
    try (
        -- Python scene preparation can leave its enclosing execution hold active.
        -- This fixture owns the scene. Reload the immutable saved input outside
        -- that context before testing the product's native Undo transaction.
        format "TRACE: initial hold=%\n" (theHold.Holding()) to:log
        if CyrusRecipeBrowser!=undefined do CyrusRecipeBrowser.closeButton.pressed()
        if theHold.Holding() do (format "FIXTURE: cancel Python preparation hold before reloading owned scene\n" to:log;theHold.Cancel())
        format "TRACE: cancelled hold=%\n" (theHold.Holding()) to:log
        loadMaxFile VerifyScenePath quiet:true useFileUnits:true
        format "TRACE: loaded hold=%\n" (theHold.Holding()) to:log
        local root=(getNodeByName ("CYRUS EXAMPLE | "+VerifyDemoTitle)).baseObject
        root.refreshAll();format "TRACE: refreshed hold=%\n" (theHold.Holding()) to:log
        CyrusOpenRecipeLibrary root;format "TRACE: opened hold=%\n" (theHold.Holding()) to:log
        local browser=CyrusRecipeBrowser
        cyrusRecipeLibraryCancel browser.scan;browser.scanTimer.active=false
        browser.document=cyrusRecipeRead VerifyRecipePath
        browser.bindings=CyrusRecipeSuggestBindings root browser.document
        browser.showBindings();format "TRACE: bound hold=%\n" (theHold.Holding()) to:log
        check (not theHold.Holding()) "Native UI transaction begins outside an enclosing hold" log
        check (findItem (for pair in browser.bindings collect pair[2]==undefined) true==0) "All demo roles explicitly matched" log
        local original=paintBytes root,epoch=root.procEpoch,before=deepCopy root.groupSnapshotRows,nodes=controllers()
        browser.newSetupCheck.checked=true;browser.importButton.pressed()
        local created=for node in controllers() where findItem nodes node==0 collect node
        check (created.count==1) "Actual New setup creates one separate controller" log
        local other=created[1].baseObject
        check (other.layerObjects.count==root.layerObjects.count and equalPaint (paintBytes other) original) "New setup restores layers and exact native Paint" log
        check (root.procEpoch==epoch and equalRows root.groupSnapshotRows before) "Import preserves original complete publication" log
        max undo
        check ((controllers()).count==nodes.count) "One Undo removes the complete imported setup" log
        max redo
        created=for node in controllers() where findItem nodes node==0 collect node
        check (created.count==1 and equalPaint (paintBytes created[1].baseObject) original) "One Redo restores complete Paint-bearing setup" log
        other=created[1].baseObject;other.refreshAll()
        check (findItem (for rows in other.groupSnapshotRows collect rows.count>0) false==0) "Explicit Update calculates every imported layer" log
        check (not theHold.Holding()) "Transaction leaves no stranded hold" log
        browser.closeButton.pressed();format "PASS: complete\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
