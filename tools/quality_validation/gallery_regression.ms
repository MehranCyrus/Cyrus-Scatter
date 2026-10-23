-- Max 2027 owned profile; uses the already-loaded, matched product pair.
-- The harness binds the existing 96-model Content read-only before this run.
-- Exercise the generated Recipes button; browsing never invokes model import.
fileIn ((getFilenamePath(getSourceFileName()))+"common.ms")

(
    QRequire (QScenarioID=="R7-M12") "Unknown Gallery regression scenario"
    QRequire (matchPattern MCPFixtureDir pattern:"*/build/*") "Owned test profile required"
    if CyrusRecipeBrowser!=undefined do destroyDialog CyrusRecipeBrowser
    QSetup()
    local fingerprint=QFingerprint(),epoch=QRoot.procEpoch,builds=QRoot.groupBuilds
    local rows=QRows() as string,rowCount=QRoot.groupSnapshotRows[1].count,token=cyrusPlacementToken QRoot.groupSnapshotRows[1]
    QLayer.amount=401
    local problem=undefined,evidence=createFile (MCPFixtureDir+"gallery-regression-evidence.txt")
    fn waitForGallery = (
        local deadline=timeStamp()+10000
        while timeStamp()<deadline do (
            if CyrusRecipeBrowser!=undefined and CyrusRecipeBrowser.hwnd!=0 do (
                local panel=CyrusRecipeBrowser.panel
                if matchPattern panel.StatusText pattern:"Ready:*" do return CyrusRecipeBrowser
            )
            QSettle 50
        )
        throw ("Gallery did not become ready: "+(if CyrusRecipeBrowser==undefined then "No window" else CyrusRecipeBrowser.panel.StatusText))
    )
    try (
        QMount pages:#("managerUISlot")
        QAssert (QRoot.updateMode==1 and QLayer.amount==401 and QFingerprint()==fingerprint and QRoot.procEpoch==epoch and QRoot.groupBuilds==builds and (QRows() as string)==rows) "R7-M12-01" "Mounting the generated Layers panel preserves the complete publication and pending Manual Count"

        QClick QRoot.layersUI.flow_layersUI_recipesButton
        local window=waitForGallery(),handle=window.hwnd,panel=window.panel
        local firstSession=try(window.sessionID)catch(undefined)
        QAssert (handle!=0 and panel.IndividualModels and panel.LibraryIndex==2 and panel.Gallery.ItemCount==96 and panel.StatusText=="Ready: 96 individual models; 96 matching.") "R7-M12-02" "The actual generated Recipes button opens the existing 96-model Gallery and completes catalog loading"

        local panelType=panel.GetType(),assembly=panelType.Assembly,assemblyName=assembly.GetName()
        local paths=dotNetClass "System.IO.Path",expectedPath=paths.GetFullPath (pathConfig.appendPath CyrusRecipeScriptDirectory "CyrusGallery.dll")
        local actualPath=paths.GetFullPath assembly.Location,version=QRoot.uiVersion()
        QAssert (version=="0.86.8.7" and CyrusLibraryVersion()==version and assemblyName.Version.ToString()==version and toLower actualPath==toLower expectedPath) "R7-M12-03" "The open Gallery control comes from the current 0.86.8.7 assembly at the exact staged script runtime path"
        format "Version:%\nAssembly:%\nExpected assembly:%\nLibrary:%\nInitial window:%\nCatalog:%\n" version actualPath expectedPath (CyrusRecipeBundledDirectory version) handle panel.StatusText to:evidence

        local reused=true
        for repetition=1 to 3 do (
            QClick QRoot.layersUI.flow_layersUI_recipesButton
            local again=waitForGallery()
            reused=reused and again==window and again.hwnd==handle and again.panel.Gallery.ItemCount==96
        )
        QAssert reused "R7-M12-04" "Three further Recipes button activations reuse the same Gallery window and populated catalog"

        -- Max remaps managed Control references to the rollout wrapper, which
        -- becomes null on destruction. Inspect release of its old handle.
        local panelHandle=panel.Handle
        destroyDialog window;QSettle 100
        local releasedControl=(dotNetClass "System.Windows.Forms.Control").FromHandle panelHandle
        QAssert (CyrusRecipeBrowser==undefined and releasedControl==undefined) "R7-M12-05" "Closing the Gallery clears its global window and unregisters the managed control's previous native handle"
        QClick QRoot.layersUI.flow_layersUI_recipesButton
        local reopened=waitForGallery(),reopenedPanel=reopened.panel
        local reopenedSession=try(reopened.sessionID)catch(undefined)
        format "Reopen predicates: hwndNonzero:% rolloutDifferent:% managedLive:% itemCount:% status:% rootSame:% nodeSame:% surfaceSame:%\n" (reopened.hwnd!=0) (reopened!=window) (not reopenedPanel.IsDisposed) reopenedPanel.Gallery.ItemCount reopenedPanel.StatusText (CyrusRecipeOpenRoot==QRoot) (CyrusRecipeOpenNode==QNode) (CyrusRecipeOpenSurface==QSurface) to:evidence
        format "Reopen identities: firstWindow:% currentWindow:% firstPanel:% currentPanel:% firstSession:% currentSession:%\n" handle reopened.hwnd panelHandle reopenedPanel.Handle firstSession (try(reopened.sessionID)catch(undefined)) to:evidence
        format "Reopen context: rootActual:% rootExpected:% nodeActual:% nodeExpected:% surfaceActual:% surfaceExpected:%\n" (try(getHandleByAnim CyrusRecipeOpenRoot)catch(undefined)) (getHandleByAnim QRoot) (try(CyrusRecipeOpenNode.handle)catch(undefined)) QNode.handle (try(CyrusRecipeOpenSurface.handle)catch(undefined)) QSurface.handle to:evidence
        flush evidence
        -- MAXScript reuses the rollout definition; its per-window session ID
        -- proves reopening without assuming native handles are never recycled.
        QAssert (reopened.hwnd!=0 and firstSession!=undefined and firstSession!="" and reopenedSession!=undefined and reopenedSession!="" and reopenedSession!=firstSession and not reopenedPanel.IsDisposed and reopenedPanel.Gallery.ItemCount==96 and reopenedPanel.StatusText=="Ready: 96 individual models; 96 matching." and CyrusRecipeOpenRoot==QRoot and CyrusRecipeOpenNode==QNode and CyrusRecipeOpenSurface==QSurface) "R7-M12-06" "The Recipes button reopens a fresh Gallery session with 96 models and the same Scatter and receiver context"

        QRequire (reopenedPanel.Width>0 and reopenedPanel.Height>0 and reopenedPanel.Width<=2048 and reopenedPanel.Height<=1536) "Gallery screenshot exceeds its bounded size"
        local image=dotNetObject "System.Drawing.Bitmap" reopenedPanel.Width reopenedPanel.Height
        local rectangle=dotNetObject "System.Drawing.Rectangle" 0 0 reopenedPanel.Width reopenedPanel.Height
        reopenedPanel.DrawToBitmap image rectangle
        image.Save (MCPFixtureDir+"gallery-regression-reopened.png") (dotNetClass "System.Drawing.Imaging.ImageFormat").Png
        image.Dispose()
        format "Reopened window:%\nCatalog:%\nFingerprint:%\nEpoch:%\nBuilds:%\nPublished rows:%\nPending Manual Count:%\n" reopened.hwnd reopenedPanel.StatusText (QFingerprint()) QRoot.procEpoch QRoot.groupBuilds QRoot.groupSnapshotRows[1].count QLayer.amount to:evidence
        destroyDialog reopened;QSettle 100
        local finalToken=cyrusPlacementToken QRoot.groupSnapshotRows[1],tokenSame=true
        tokenSame=finalToken.count==token.count
        if tokenSame do for i=1 to token.count do tokenSame=tokenSame and finalToken[i]==token[i]
        format "Final predicates: windowCleared:% manual:% pendingCount:% fingerprintSame:% epochSame:% buildsSame:% rowsSame:% rowCountSame:% tokenSame:% layerCount:% sourceCount:% sourceSame:%\n" (CyrusRecipeBrowser==undefined) (QRoot.updateMode==1) (QLayer.amount==401) (QFingerprint()==fingerprint) (QRoot.procEpoch==epoch) (QRoot.groupBuilds==builds) ((QRows() as string)==rows) (QRoot.groupSnapshotRows[1].count==rowCount) tokenSame QRoot.layerObjects.count QLayer.sources.count (QLayer.sources[1]==QModel) to:evidence
        format "Final values: fingerprintBefore:% after:% epochBefore:% after:% buildsBefore:% after:% rowCountBefore:% after:% tokenBefore:% after:% source:% model:%\n" fingerprint (QFingerprint()) epoch QRoot.procEpoch builds QRoot.groupBuilds rowCount QRoot.groupSnapshotRows[1].count token (cyrusPlacementToken QRoot.groupSnapshotRows[1]) QLayer.sources[1] QModel to:evidence
        flush evidence
        QAssert (CyrusRecipeBrowser==undefined and QRoot.updateMode==1 and QLayer.amount==401 and QFingerprint()==fingerprint and QRoot.procEpoch==epoch and QRoot.groupBuilds==builds and (QRows() as string)==rows and QRoot.groupSnapshotRows[1].count==rowCount and tokenSame and QRoot.layerObjects.count==1 and QLayer.sources.count==1 and QLayer.sources[1]==QModel) "R7-M12-07" "Gallery open, reuse, close and reopen preserve exact published rows, token, fingerprint and build epoch while Manual Count remains pending and no model is added"
    ) catch (problem=getCurrentException())
    if CyrusRecipeBrowser!=undefined do try(destroyDialog CyrusRecipeBrowser)catch()
    close evidence
    if problem!=undefined do throw problem
)
