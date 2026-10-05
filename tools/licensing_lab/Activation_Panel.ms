-- Private candidate utility only. Not loaded by product startup or installers.
global CyrusLicenseDevelopmentPanel
    if cyrusOwnedLabActivate==undefined or cyrusOwnedLabRequest==undefined do throw "Open the matching private installation-key licensing candidate first."
    try(destroyDialog CyrusLicenseDevelopmentPanel)catch()
    rollout CyrusLicenseDevelopmentPanel "Cyrus development license" width:350 (
        label warning "Private test issuer — not customer licensing" align:#left
        label current "" width:330 align:#left
        button refresh "Refresh status" width:330
        button request "Save activation request…" width:330
        button activate "Import activation response…" width:330
        button renew "Import renewal license…" width:330
        fn showStatus = (current.text="Status: "+cyrusOwnedLabStatus())
        fn readBounded path = (
            local info=dotNetObject "System.IO.FileInfo" path
            if info.Length>8192 do throw "Response exceeds the supported size."
            (dotNetClass "System.IO.File").ReadAllText path
        )
        fn applyFile path activation:false = (
            local result=if activation then cyrusOwnedLabActivate (readBounded path) else cyrusOwnedLabInstall (readBounded path)
            showStatus()
            if result!="verified" do throw result
            result
        )
        fn saveRequest path = (
            (dotNetClass "System.IO.File").WriteAllText path (cyrusOwnedLabRequest())
            showStatus()
        )
        on refresh pressed do (cyrusOwnedLabRefresh();showStatus())
        on request pressed do (
            local path=getSaveFileName caption:"Save private activation request" types:"JSON request (*.json)|*.json|"
            if path!=undefined do try(saveRequest path)catch(messageBox (getCurrentException()))
        )
        on activate pressed do (
            local path=getOpenFileName caption:"Import private activation response" types:"Activation response (*.response)|*.response|"
            if path!=undefined do try(applyFile path activation:true)catch(messageBox (getCurrentException()))
        )
        on renew pressed do (
            local path=getOpenFileName caption:"Import private renewal license" types:"Signed license (*.license)|*.license|"
            if path!=undefined do try(applyFile path)catch(messageBox (getCurrentException()))
        )
        on CyrusLicenseDevelopmentPanel open do showStatus()
    )
    createDialog CyrusLicenseDevelopmentPanel
