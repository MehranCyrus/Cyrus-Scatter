-- Product-registration cleanup in the disposable installed profile only.
(
    for kind in #(#userScripts,#userMacros,#userStartupScripts) do (
        local directory=substituteString (getDir kind) "\\" "/"
        if findString (toLower directory) (toLower BLDir)!=1 do throw "Uninstall escaped the private profile"
    )
    local controllers=for n in objects where classof n.baseObject==CyrusScatterObject collect #(n.name,getHandleByAnim n)
    local ini=pathConfig.appendPath (getFilenamePath(getMAXIniFile())) "Plugin.UserSettings.ini"
    setINISetting ini "Directories" "UnrelatedFixturePlugin" "preserve-this-registration"
    fileIn (pathConfig.appendPath (getDir #userScripts) "CyrusScatter/Uninstall.ms")
    if getINISetting ini "Directories" "CyrusScatter2027"!="" do throw "Cyrus registration was not removed"
    if getINISetting ini "Directories" "UnrelatedFixturePlugin"!="preserve-this-registration" do throw "Unrelated registration was changed"
    for name in #("CyrusScatterStartup.ms","AminScatterStartup.ms") where doesFileExist (pathConfig.appendPath (getDir #userStartupScripts) name) do throw "Owned startup survived uninstall"
    for item in controllers do (
        local n=getNodeByName item[1]
        if not isValidNode n or getHandleByAnim n!=item[2] do throw "Uninstall removed a scene controller"
    )
    if not doesFileExist (pathConfig.appendPath (getDir #userScripts) "CyrusScatter/CyrusScatter.ms") do throw "Uninstall removed the preserved product folder"
    CSPWriteText (BLDir+"uninstall-acceptance.json") (CSPObject #(#("private_directories",true),#("owned_registration_removed",true),#("unrelated_registration_preserved",true),#("scene_controllers_preserved",controllers.count),#("product_folder_preserved",true)))
)
