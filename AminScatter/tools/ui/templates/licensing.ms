global CyrusOpenLicenseDialog,CyrusLicenseDialog,CyrusRequireAuthor,CyrusLicenseCanEdit
fn CyrusRequireAuthor = (
    if cyrusLicenseAllows==undefined do throw "Load the matching licensed Cyrus 0.79.1 native modules and restart Max."
    if not cyrusLicenseAllows() do throw "Cyrus creation and editing require an active team license. Existing work can still load and render. Open Cyrus > License to activate or renew."
    true
)
fn CyrusLicenseCanEdit = (
    try(CyrusRequireAuthor())catch(messageBox (getCurrentException()) title:"Cyrus license";false)
)
fn CyrusOpenLicenseDialog = (
    if CyrusLicenseDialog!=undefined do try(destroyDialog CyrusLicenseDialog)catch()
    rollout licenseUI "Cyrus 0.79.1 - Team License" width:480 height:240 (
        label statusLabel "" pos:[16,16] width:448 height:70
        button requestButton "1. Save activation request..." pos:[16,98] width:218 height:30
        button importButton "2. Import license..." pos:[246,98] width:218 height:30
        label instructions "Send the request to Mehran. Import the license file he returns.\nThe license lasts 30 days from generation, including days before import.\nWhen it expires, existing scenes still load and render; editing locks." pos:[16,140] width:448 height:58
        button refreshButton "Refresh status" pos:[16,205] width:218 height:25
        button closeButton "Close" pos:[246,205] width:218 height:25
        fn refresh = (
            if cyrusLicenseStatus==undefined then statusLabel.text="The licensed native modules are not loaded. Restart with the matching 0.79.1 package."
            else (
                local state=cyrusLicenseStatus(),expiry=""
                if state[4]>0 do (
                    local epoch=dotNetObject "System.DateTime" 1970 1 1
                    expiry="\nExpires (UTC): "+((epoch.AddSeconds state[4]).ToString "yyyy-MM-dd HH:mm:ss")
                )
                statusLabel.text=(if state[1] then "Active - creation and editing enabled." else "Editing locked: "+state[2])+expiry
            )
        )
        fn saveRequest path = (
            if path==undefined do return false
            if cyrusLicenseRequest==undefined do throw "Licensed native modules are not loaded."
            (dotNetClass "System.IO.File").WriteAllText path (cyrusLicenseRequest())
            refresh();true
        )
        fn importLicense path = (
            if path==undefined do return false
            local info=dotNetObject "System.IO.FileInfo" path
            if info.Length<1 or info.Length>8192 do throw "The license file must contain at most 8192 bytes."
            local content=trimRight (trimLeft ((dotNetClass "System.IO.File").ReadAllText path))
            cyrusLicenseImport content
            refresh();true
        )
        on licenseUI open do refresh()
        on requestButton pressed do try(saveRequest (getSaveFileName caption:"Save activation request" filename:"Cyrus-activation-request.json" types:"JSON (*.json)|*.json|"))catch(messageBox (getCurrentException()) title:"Cyrus activation")
        on importButton pressed do try(importLicense (getOpenFileName caption:"Import Cyrus license" types:"Cyrus license (*.cyruslicense)|*.cyruslicense|"))catch(messageBox (getCurrentException()) title:"Cyrus activation")
        on refreshButton pressed do refresh()
        on closeButton pressed do destroyDialog licenseUI
    )
    CyrusLicenseDialog=licenseUI;createDialog licenseUI
)
macroScript CyrusTeamLicense category:"Cyrus" buttonText:"Cyrus License" tooltip:"Activate or renew Cyrus Scatter" (
    on execute do CyrusOpenLicenseDialog()
)
