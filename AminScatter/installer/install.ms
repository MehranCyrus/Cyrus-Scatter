-- Expanded only by the package builder; run the complete MZP.
(
    local paths=undefined,helperReady=false
    if (maxVersion())[1]!=__MAX_VERSION__ then (
        messageBox "This Cyrus Scatter __VERSION__ build requires 3ds Max __MAX_YEAR__." title:"Cyrus Scatter"
    ) else try (
        local packageDir=getFilenamePath (getSourceFileName())
        local helper=pathConfig.appendPath packageDir "CyrusInstaller.dll"
        fn digest path = (
            local hash=(dotNetClass "System.Security.Cryptography.SHA256").Create()
            local stream=(dotNetClass "System.IO.File").OpenRead path
            local result=""
            try(result=toLower ((dotNetClass "System.BitConverter").ToString(hash.ComputeHash stream));stream.Dispose();hash.Dispose())
            catch(stream.Dispose();hash.Dispose();throw())
            substituteString result "-" ""
        )
        if digest helper!="__HELPER_SHA256__" do throw "Scatter installer helper differs. Run the complete matching MZP."
        local loaded=undefined
        local assemblies=(dotNetClass "System.AppDomain").CurrentDomain.GetAssemblies()
        for assembly in assemblies do (
            local assemblyName=assembly.GetName()
            if assemblyName.Name=="CyrusInstaller" do (
                if toLower(assembly.ManifestModule.ModuleVersionId.ToString())!="__HELPER_MVID__" do
                    throw "A different Cyrus installer is already loaded. Save your work, restart Max, then run this MZP again."
                if digest assembly.Location!="__HELPER_SHA256__" do throw "The loaded Cyrus installer identity differs. Restart Max and run the complete MZP again."
                loaded=assembly
            )
        )
        if loaded==undefined do loaded=(dotNetClass "System.Reflection.Assembly").LoadFrom helper
        local loadedName=loaded.GetName()
        if loadedName.Name!="CyrusInstaller" or toLower(loaded.ManifestModule.ModuleVersionId.ToString())!="__HELPER_MVID__" or digest loaded.Location!="__HELPER_SHA256__" do
            throw "Max could not load the matching Cyrus installer. Restart Max and run the complete MZP again."
        helperReady=true
        paths=(dotNetClass "Cyrus.Setup.InstallPaths").ForMax (getDir #userScripts) (getDir #userStartupScripts) (getDir #userMacros) (getFilenamePath (getMAXIniFile())) "__MAX_YEAR__"
        local installer=dotNetObject "Cyrus.Setup.InstallEngine" packageDir "__INSTALL_HASH__"
        (dotNetClass "Cyrus.Setup.LibraryOptions").ShowForMax installer paths
    )catch(
        local details=(getCurrentException())+"\n"+(getCurrentExceptionStackTrace()),logPath=""
        if helperReady and paths!=undefined do try(logPath=(dotNetClass "Cyrus.Setup.InstallEngine").SaveFailure paths details)catch()
        messageBox (details+"\n\nInstallation log: "+logPath) title:"Cyrus Scatter installation"
    )
)
