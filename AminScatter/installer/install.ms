-- Build placeholders are expanded by tools/build_max.py; run the packaged MZP.
(
    if (maxVersion())[1]!=__MAX_VERSION__ then (
        messageBox "This Cyrus Scatter __VERSION__ build requires 3ds Max __MAX_YEAR__." title:"Cyrus Scatter"
    ) else (
        local packageDir=getFilenamePath (getSourceFileName())
        local destination=pathConfig.appendPath (getDir #userScripts) "CyrusScatter"
        local binaries=pathConfig.appendPath destination "bin-max__MAX_YEAR__-__NATIVE_ID__"
        local pluginIni=pathConfig.appendPath (getFilenamePath (getMAXIniFile())) "Plugin.UserSettings.ini"
        local io=dotNetClass "System.IO.File",convert=dotNetClass "System.Convert"
        try (
            makeDir binaries all:true
            makeDir (getDir #userStartupScripts) all:true
            makeDir (getDir #userMacros) all:true
            for name in #("AminScatter.dlx","CyrusScatterEdit.dlm","CyrusBrush.dlx","CyrusBrushStorage.dlh") do (
                local target=pathConfig.appendPath binaries name,source=pathConfig.appendPath packageDir name
                if doesFileExist target then (
                    if (convert.ToBase64String (io.ReadAllBytes target))!=(convert.ToBase64String (io.ReadAllBytes source)) do throw ("Native package identity mismatch: "+name)
                ) else if not copyFile source target do throw ("Could not copy "+name)
            )
            for name in #("CyrusScatter.ms","Uninstall.ms","manifest.json","INSTALL.txt") do io.Copy (pathConfig.appendPath packageDir name) (pathConfig.appendPath destination name) true
            io.Copy (packageDir+"CyrusScatter.mcr") (pathConfig.appendPath (getDir #userMacros) "CyrusScatter.mcr") true
            io.Copy (packageDir+"CyrusScatterStartup.ms") (pathConfig.appendPath (getDir #userStartupScripts) "CyrusScatterStartup.ms") true
            if not setINISetting pluginIni "Directories" "CyrusScatter__MAX_YEAR__" binaries do throw "Could not register the Cyrus plugin path."
            -- Retire only registrations and startup files owned by this product.
            -- Old binaries and scene files are preserved for recovery.
            for key in #("AminScatter2026","AminScatter2027") do delINISetting pluginIni "Directories" key
            deleteFile (pathConfig.appendPath (getDir #userStartupScripts) "AminScatterStartup.ms")
            for name in #("AminScatter.mcr","Cyrus-AminScatterOpen.mcr") do deleteFile (pathConfig.appendPath (getDir #userMacros) name)
            messageBox "Cyrus Scatter __VERSION__ is installed. Restart 3ds Max __MAX_YEAR__ to load the matching native engine.\n\nCreate > Geometry > Cyrus > Cyrus Scatter, then use Modify.\nChoose a receiving surface in Surface Scatter. Select a layer in Layer Manager to edit its native rollouts below. Edit layer in window... is an optional floating view of the same settings.\nPaint sets keep separate assets and Brush histories; population, area and transforms share layer defaults. Spacing saves automatically. Diagnostics provides local Start, Stop and Save controls without MCP.\n\nReopen a saved copy of your scene after restarting Max." title:"Cyrus Scatter __VERSION__"
        ) catch (messageBox (getCurrentException()) title:"Cyrus Scatter installation")
    )
)
