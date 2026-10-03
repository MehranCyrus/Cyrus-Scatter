-- Actual packaged installer, confined to the disposable Max profile.
(
    for kind in #(#userScripts,#userMacros,#userStartupScripts) do (
        local directory=substituteString (getDir kind) "\\" "/"
        if findString (toLower directory) (toLower BLDir)!=1 do throw "Installer test directory escaped its private profile"
    )
    -- Exercise Max's MZP reader and mzp.run, as the artist will use them.
    fileIn (BLRoot+"dist/v1/CyrusScatter-1.0.0-Max2027.mzp")
    local destination=pathConfig.appendPath (getDir #userScripts) "CyrusScatter"
    for name in #("CyrusScatter.ms","Uninstall.ms","manifest.json","INSTALL.txt") where not doesFileExist (pathConfig.appendPath destination name) do throw ("Installer omitted "+name)
    local ini=pathConfig.appendPath (getFilenamePath (getMAXIniFile())) "Plugin.UserSettings.ini"
    local binaries=getINISetting ini "Directories" "CyrusScatter2027"
    for name in #("AminScatter.dlx","CyrusScatterEdit.dlm","CyrusBrush.dlx","CyrusBrushStorage.dlh") where not doesFileExist (pathConfig.appendPath binaries name) do throw ("Installer omitted native "+name)
    if not doesFileExist (pathConfig.appendPath (getDir #userStartupScripts) "CyrusScatterStartup.ms") do throw "No Cyrus startup registration"
    CSPWriteText (BLDir+"installer-acceptance.json") (CSPObject #(#("private_directories",true),#("native_folder",binaries),#("script",pathConfig.appendPath destination "CyrusScatter.ms"),#("all_four_native_modules",true),#("public_cyrus_names",true)))
)
