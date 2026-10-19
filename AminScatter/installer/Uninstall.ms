-- Remove only this profile's recorded startup registration.
(
    try (
        local directory=getFilenamePath (getSourceFileName())
        dotNet.loadAssembly (pathConfig.appendPath directory "CyrusInstaller.dll")
        local paths=dotNetObject "Cyrus.Setup.InstallPaths" (getDir #userScripts) (getDir #userStartupScripts) (getDir #userMacros) (getFilenamePath (getMAXIniFile()))
        (dotNetClass "Cyrus.Setup.InstallEngine").RemoveRegistration paths "__MAX_YEAR__"
        messageBox "Cyrus Scatter startup registration has been removed from this Max profile. Restart Max.\n\nPersonal recipes, imported textures, activation and versioned recovery files are retained. Existing scene objects remain in the running session until it closes." title:"Cyrus Scatter"
    )catch(messageBox (getCurrentException()) title:"Cyrus Scatter removal")
)
