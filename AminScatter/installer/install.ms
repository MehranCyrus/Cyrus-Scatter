-- Expanded only by the package builder; run the complete MZP.
(
    if (maxVersion())[1]!=__MAX_VERSION__ then (
        messageBox "This Cyrus Scatter __VERSION__ build requires 3ds Max __MAX_YEAR__." title:"Cyrus Scatter"
    ) else try (
        local packageDir=getFilenamePath (getSourceFileName())
        dotNet.loadAssembly (pathConfig.appendPath packageDir "CyrusInstaller.dll")
        local paths=(dotNetClass "Cyrus.Setup.InstallPaths").ForMax (getDir #userScripts) (getDir #userStartupScripts) (getDir #userMacros) (getFilenamePath (getMAXIniFile())) "__MAX_YEAR__"
        local installer=dotNetObject "Cyrus.Setup.InstallEngine" packageDir "__INSTALL_HASH__"
        (dotNetClass "Cyrus.Setup.LibraryOptions").ShowForMax installer paths
    )catch(
        local details=(getCurrentException())+"\n"+(getCurrentExceptionStackTrace()),logPath=""
        try(logPath=(dotNetClass "Cyrus.Setup.InstallEngine").SaveFailure paths details)catch()
        messageBox (details+"\n\nInstallation log: "+logPath) title:"Cyrus Scatter installation"
    )
)
