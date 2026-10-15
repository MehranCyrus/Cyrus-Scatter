(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-orientation0830-*/" do throw "Owned orientation host required."
    local log=createFile (MCPFixtureDir+"transactions-"+(timeStamp() as string)+".txt")
    format "REQUEST: %\n" MCPFixtureLast to:log
    fn check value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;if not value do throw label)
    fn controllers = (for node in objects where classof node.baseObject==AminScatterObject collect node)
    try (
        if theHold.Holding() do (format "FIXTURE: cancel Python preparation hold before reloading owned scene\n" to:log;theHold.Cancel())
        local scenes=getFiles (MCPFixtureDir+"orientation-*.max")
        check (scenes.count>0) "Immutable orientation scene exists" log
        loadMaxFile scenes[scenes.count] quiet:true useFileUnits:true
        local node=getNodeByName "Orientation qualification",root=node.baseObject,leaf=root.layerObjects[1],target=leaf.orientationTarget
        root.updateMode=1;root.refreshAll();CyrusPerfHeadless=false
        select node;max modify mode;modPanel.setCurrentObject root
        if not root.mainUI.controlsReady do root.mainUI.mountTimer.tick()
        root.mainUI.slots[9].open=true;root.mainUI.slots[9].rolledUp false
        local page=root.mainUI.editors[9],before=deepCopy root.groupSnapshotRows[1],oldBlend=leaf.orientationBlend
        page.randomUI_normalBlendSpin.changed 15.0
        check (leaf.orientationBlend==15.0 and cyrusPreviewPlacementsEqual before root.groupSnapshotRows[1]) "Actual blend handler edits Manual settings without publishing" log
        root.mainUI.updateNow.pressed();local changed=deepCopy root.groupSnapshotRows[1]
        check (not cyrusPreviewPlacementsEqual before changed) "Update publishes changed target roll" log
        max undo
        check (leaf.orientationBlend==oldBlend and cyrusPreviewPlacementsEqual changed root.groupSnapshotRows[1]) "Undo restores authored blend and preserves Manual publication" log
        root.mainUI.updateNow.pressed()
        check (cyrusPreviewPlacementsEqual before root.groupSnapshotRows[1]) "Update after Undo restores complete original rows" log
        max redo
        check (leaf.orientationBlend==15.0) "Redo restores authored blend" log
        root.refreshAll()
        check (cyrusPreviewPlacementsEqual changed root.groupSnapshotRows[1]) "Update after Redo restores complete changed rows" log

        local binding=CyrusPresetMakeBinding root leaf "transforms",values=CyrusPresetCapture binding
        local preset=cyrusPresetDecode (cyrusPresetEncode "transforms" "Target roll" values)
        leaf.orientationTarget=undefined;local missingFailed=false,mode=leaf.orientationMode,blend=leaf.orientationBlend
        try(CyrusPresetApply binding preset)catch(missingFailed=true)
        check (missingFailed and leaf.orientationMode==mode and leaf.orientationBlend==blend and leaf.orientationTarget==undefined) "Numeric target preset rejects missing destination binding before mutation" log
        leaf.orientationTarget=target;leaf.orientationBlend=45.0
        CyrusPresetApply binding preset
        check (leaf.orientationBlend==15.0 and leaf.orientationTarget==target) "Numeric transform preset includes blend and preserves destination target" log
        max undo
        check (leaf.orientationBlend==45.0 and leaf.orientationTarget==target) "One Undo restores numeric preset edits" log
        max redo
        check (leaf.orientationBlend==15.0) "One Redo restores numeric preset edits" log

        local document=CyrusRecipeCapture root #(leaf) "Target recipe",bindings=CyrusRecipeSuggestBindings root document,nodes=controllers()
        check (findItem (for pair in bindings collect pair[2]==undefined) true==0) "Complete recipe target and terrain roles have explicit bindings" log
        local result=CyrusRecipeImport root document bindings newSetup:true
        local created=for n in controllers() where findItem nodes n==0 collect n
        check (created.count==1 and created[1].baseObject.layerObjects[1].orientationTarget==target) "Recipe creates setup with correct target role" log
        max undo
        check ((controllers()).count==nodes.count) "One Undo removes the entire orientation recipe import" log
        max redo
        created=for n in controllers() where findItem nodes n==0 collect n
        check (created.count==1 and created[1].baseObject.layerObjects[1].orientationMode==3 and created[1].baseObject.layerObjects[1].orientationBlend==15.0 and created[1].baseObject.layerObjects[1].orientationTarget==target) "One Redo restores complete authored orientation and binding" log
        created[1].baseObject.refreshAll()
        check (created[1].baseObject.groupSnapshotRows[1].count==2000) "Imported orientation setup calculates successfully" log
        check (not theHold.Holding()) "No stranded Undo transaction" log
        format "PASS: complete\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
