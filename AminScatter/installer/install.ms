-- Expanded only by the package builder; run the complete MZP.
(
    if (maxVersion())[1]!=__MAX_VERSION__ then (
        messageBox "This Cyrus Scatter __VERSION__ build requires 3ds Max __MAX_YEAR__." title:"Cyrus Scatter"
    ) else try (
        local packageDir=getFilenamePath (getSourceFileName())
        dotNet.loadAssembly (pathConfig.appendPath packageDir "CyrusInstaller.dll")
        local paths=dotNetObject "Cyrus.Setup.InstallPaths" (getDir #userScripts) (getDir #userStartupScripts) (getDir #userMacros) (getFilenamePath (getMAXIniFile()))
        local installer=dotNetObject "Cyrus.Setup.InstallEngine" packageDir "__INSTALL_HASH__"
        local release=installer.Install paths
        messageBox ("Cyrus Scatter __VERSION__ is installed for Max __MAX_YEAR__.\nRestart Max to load the matching native/script pair.\n\nCreate > Geometry > Cyrus > Cyrus Scatter.\nLayers > Recipes opens the gallery and bundled examples.\nPersonal recipes and activation are preserved.\n\nInstallation: "+release+"\n\nThis development build uses schema 58. Preserve earlier scenes with their matching older build.") title:"Cyrus Scatter __VERSION__"
    )catch(messageBox (getCurrentException()) title:"Cyrus Scatter installation")
)
