(
    if (maxVersion())[1] != 28000 then (
        messageBox "This build requires 3ds Max 2026." title:"Cyrus Scatter"
    ) else (
        local packageDir=getFilenamePath (getSourceFileName())
        local destination=pathConfig.appendPath (getDir #userScripts) "AminScatter"
        local binaries=pathConfig.appendPath destination "bin55"
        local pluginIni=pathConfig.appendPath (getFilenamePath (getMAXIniFile())) "Plugin.UserSettings.ini"
        local io=dotNetClass "System.IO.File"
        try (
            makeDir binaries all:true
            makeDir (getDir #userStartupScripts) all:true
            local dllPath=pathConfig.appendPath binaries "AminScatter.dlx"
            if doesFileExist dllPath then (
                local convert=dotNetClass "System.Convert"
                if (convert.ToBase64String (io.ReadAllBytes dllPath)) != (convert.ToBase64String (io.ReadAllBytes (packageDir+"AminScatter.dlx"))) do
                    throw "A different native engine is installed. Uninstall it, restart Max, and remove its old AminScatter folder before installing."
            ) else (
                if not copyFile (packageDir+"AminScatter.dlx") dllPath do throw "Could not copy the native plugin."
            )
            local editPath=pathConfig.appendPath binaries "CyrusScatterEdit.dlm"
            if doesFileExist editPath then (
                local convert=dotNetClass "System.Convert"
                if (convert.ToBase64String (io.ReadAllBytes editPath)) != (convert.ToBase64String (io.ReadAllBytes (packageDir+"CyrusScatterEdit.dlm"))) do throw "Restart Max before updating a different CS Edit build."
            ) else if not copyFile (packageDir+"CyrusScatterEdit.dlm") editPath do throw "Could not copy CS Edit modifier."
            io.Copy (packageDir+"AminScatterObject.ms") (destination+"\\AminScatterObject.ms") true
            io.Copy (packageDir+"Uninstall.ms") (destination+"\\Uninstall.ms") true
            io.Copy (packageDir+"AminScatter.mcr") ((getDir #userMacros)+"\\AminScatter.mcr") true
            io.Copy (packageDir+"AminScatterStartup.ms") ((getDir #userStartupScripts)+"\\AminScatterStartup.ms") true
            if not setINISetting pluginIni "Directories" "AminScatter2026" binaries do throw "Could not register the plugin path."
            try(destroyDialog AminScatterUI)catch()
            try(unRegisterRedrawViewsCallback AminScatterDraw)catch()
            messageBox "Installed / upgraded to 0.59. Restart 3ds Max 2026.\nCreate > Geometry > Cyrus > Cyrus Scatter.\nClick and drag to place the controller, then use Modify.\n\nAutomatic final render is enabled. Point Cloud stays in the viewport." title:"Cyrus Scatter 0.59"
        ) catch (messageBox (getCurrentException()) title:"Cyrus Scatter installation")
    )
)











































