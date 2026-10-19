-- Called only through the isolated qualification transport, never artist Max.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/library-surface0861-*/" do throw "Owned profile required"
    local io=dotNetClass "System.IO.File",phase=io.ReadAllText (MCPFixtureDir+"phase.txt")
    local log=createFile (MCPFixtureDir+"workflow-"+phase+".txt")
    fn check value message log = (format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
    fn closeDialogs = (for dialog in #(CyrusRecipeBrowser,CyrusReadyPresetEditor,CyrusRecipeSaveEditor,CyrusPresetSaveEditor) where dialog!=undefined do destroyDialog dialog)
    try (
        case phase of (
            "setup":(
                closeDialogs()
                with undo off (
                    resetMaxFile #noPrompt;units.SystemType=#centimeters;units.SystemScale=1.0;CyrusPerfHeadless=false
                    global LT=plane name:"Selected terrain" width:1000 length:1000 widthsegs:12 lengthsegs:12
                    global LO=plane name:"Other terrain" width:200 length:200 pos:[1500,0,0]
                )
                undo "Prior terrain move" on (LO.pos.x=1600)
                global LBefore=objects as array,LStats=cyrusPlacementTransportStats(),LRoot=undefined,LNode=undefined,LLayers=#(),LHash="",LName=""
                select LT
                CyrusOpenRecipeLibrary undefined
                check (CyrusRecipeBrowser.root==undefined) "Browsing does not create an empty Scatter setup" log
                check ((objects as array).count==LBefore.count) "Opening library creates no scene nodes" log
                CyrusRecipeBrowser.customDirectory=io.ReadAllText (MCPFixtureDir+"library-path.txt")
                CyrusRecipeBrowser.directory=CyrusRecipeBrowser.customDirectory
                CyrusRecipeBrowser.panel.SetNavigation 3 "" false;CyrusRecipeBrowser.refresh()
            )
            "load":(
                check (not CyrusRecipeBrowser.scanTimer.active) "Catalog completes asynchronously" log
                local index=0
                for i=1 to CyrusRecipeBrowser.entries.count where CyrusRecipeBrowser.entries[i][2][1]=="Layered meadow" do index=i
                check (index>0) "Actual catalog finds ready meadow preset" log
                CyrusRecipeBrowser.panel.Gallery.SelectedIndex=index-1
                select LO
                CyrusRecipeBrowser.loadSelected()
            )
            "verify":(
                check (CyrusReadyPresetEditor!=undefined and CyrusReadyPresetEditor.finished) "Actual load timer completes" log
                format "STATUS: %\n" CyrusReadyPresetEditor.status.text to:log;flush log
                check (matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*") "Load succeeds onto captured selection" log
                LRoot=CyrusReadyPresetEditor.result[1];LNode=CyrusReadyPresetEditor.result[3];LName=LNode.name
                check (CyrusRecipeBrowser.root==LRoot) "Rootless browser binds the newly created owner" log
                check (LRoot.layerObjects.count==3) "New setup contains the preset's three layers" log
                for layer in LRoot.layerObjects do check (CyrusPresetSameValues (layer.validSurfaces()) #(LT)) "Every imported layer uses captured terrain despite later selection change" log
                check ((for n in objects where superclassof n==GeometryClass and classof n.baseObject!=AminScatterObject and not n.isHidden collect n).count==2) "No included terrain was imported" log
                check ((for rows in LRoot.groupSnapshotRows where not cyrusPlacementIsNative rows collect rows).count==0) "Published placement buffers remain native" log
                LLayers=LRoot.layerObjects as array;LHash=cyrusRecipePublicationFingerprint LRoot.groupSnapshotRows
                check ((for rows in LRoot.groupSnapshotRows where rows.count>0 collect rows).count>0) "Load publishes visible planting once" log
                destroyDialog CyrusReadyPresetEditor
            )
            "undo":(max undo)
            "verifyUndo":(
                check (not isValidNode LNode) "One Undo removes newly created setup" log
                check ((objects as array).count==LBefore.count) "One Undo removes all imported sources" log
                check (isValidNode LT and LO.pos.x==1600) "Target terrain and preceding Undo operation survive" log
            )
            "redo":(max redo)
            "verifyRedo":(
                check (isValidNode LNode and CyrusPresetSameValues LLayers (LRoot.layerObjects as array)) "Redo restores exact setup and layer identities" log
                check ((cyrusRecipePublicationFingerprint LRoot.groupSnapshotRows)==LHash) "Redo restores exact publication" log
            )
            "append":(
                with undo off LRoot.updateMode=1
                CyrusRecipeBrowser.loadSelected()
            )
            "verifyAppend":(
                check (CyrusReadyPresetEditor.finished and matchPattern CyrusReadyPresetEditor.title.text pattern:"Loaded:*") "Repeated load succeeds" log
                check (LRoot.layerObjects.count==6 and LRoot.updateMode==1) "Existing setup receives new layers and retains Manual mode" log
                for i=1 to LLayers.count do check (LRoot.layerObjects[i]==LLayers[i]) "Existing layer identities and order survive" log
                for layer in LRoot.layerObjects do check (CyrusPresetSameValues (layer.validSurfaces()) #(LT)) "Appended receivers still use selected terrain" log
                destroyDialog CyrusReadyPresetEditor
            )
            "verifyAppendUndo":(
                check (CyrusPresetSameValues LLayers (LRoot.layerObjects as array)) "Undo appended preset retains prior layers" log
                check ((cyrusRecipePublicationFingerprint LRoot.groupSnapshotRows)==LHash) "Undo appended preset restores preceding publication" log
            )
            "save":(check (saveMaxFile (MCPFixtureDir+"loaded.max") quiet:true) "Selected-surface scene saves" log)
            "reopen":(
                closeDialogs()
                check (loadMaxFile (MCPFixtureDir+"loaded.max") quiet:true useFileUnits:true) "Selected-surface scene reopens" log
                LNode=getNodeByName LName;LRoot=LNode.baseObject;LT=getNodeByName "Selected terrain";LO=getNodeByName "Other terrain"
                LRoot.refreshAll()
                check ((cyrusRecipePublicationFingerprint LRoot.groupSnapshotRows)==LHash) "Saved result reproduces after reopening" log
                for layer in LRoot.layerObjects do check (CyrusPresetSameValues (layer.validSurfaces()) #(LT)) "Saved layers retain selected receiver" log
            )
            "boundaries":(
                local package=cyrusAssetPackageRead (io.ReadAllText (MCPFixtureDir+"mask-package.txt")),document=CyrusRecipeGet package "recipe",before=objects as array,oldLayers=LRoot.layerObjects as array,rejected=false
                try(CyrusPresetPlan LRoot "" package document surface:LT)catch(rejected=matchPattern (getCurrentException()) pattern:"*needs mesh channel*")
                check rejected "Missing mesh channel is explained before mutation" log
                check (CyrusPresetSameValues before (objects as array) and CyrusPresetSameValues oldLayers (LRoot.layerObjects as array)) "Preflight failure leaves nodes and layers intact" log
                local second=AminScatterObject name:"Second owner",secondRoot=second.baseObject
                with undo off (secondRoot.newLayer();secondRoot.setLayerSurfaces (secondRoot.selectedLayer()) #(LT))
                rejected=false;try(CyrusLibraryDestination LT undefined)catch(rejected=true)
                check rejected "Multiple destination owners require explicit setup selection" log
                check ((CyrusLibraryDestination LT LRoot)==LRoot) "Modify Recipes supplies an explicit valid owner" log
                with undo off delete second
            )
            "cancel":(
                local before=objects as array
                CyrusOpenReadyPreset LRoot (io.ReadAllText (MCPFixtureDir+"meadow-package.txt")) surface:LT
                destroyDialog CyrusReadyPresetEditor
                check (CyrusPresetSameValues before (objects as array)) "Cancel before preparation creates no scene nodes" log
            )
            "idleStart":(
                select LT;CyrusOpenRecipeLibrary LRoot surface:LT
                global LIdle=cyrusPlacementTransportStats()
            )
            "idleEnd":(
                check (CyrusPresetSameValues LIdle (cyrusPlacementTransportStats())) "Open gallery and idle do not materialize or upload placements" log
            )
            default:throw "Unknown qualification phase"
        )
        format "PASS: complete\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
