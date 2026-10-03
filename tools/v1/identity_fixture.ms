(
    local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
    local names=#("AminScatter.dlx","CyrusScatterEdit.dlm","CyrusBrush.dlx","CyrusBrushStorage.dlh"),modules=#()
    for i=0 to process.Modules.Count-1 do (
        local module=process.Modules.Item[i]
        if findItem names module.ModuleName>0 do append modules #(module.ModuleName,module.FileName)
    )
    if modules.count!=4 do throw "The four matching product modules were not loaded"
    local object=createInstance CyrusScatterObject
    if object.uiVersion()==undefined do throw "Missing Cyrus script version"
    CSPWriteText (BLDir+"loaded-identity.json") (CSPObject #(#("pid",process.Id),#("host",maxVersion()),#("modules",modules),#("script_version",object.uiVersion()),#("startup_script",pathConfig.appendPath (getDir #userStartupScripts) "CyrusScatterStartup.ms")))
)
