-- Register the script that belongs to the native module Max actually loaded.
-- A versioned install never combines a new loose script with an older engine.
(
    local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess(),nativePath=""
    for i=0 to process.Modules.Count-1 do (
        local module=process.Modules.Item[i]
        if toLower module.ModuleName=="aminscatter.dlx" do nativePath=module.FileName
    )
    if nativePath!="" then (
        local paths=dotNetClass "System.IO.Path",binFolder=paths.GetDirectoryName nativePath,release=paths.GetDirectoryName binFolder
        local script=pathConfig.appendPath release "CyrusScatter.ms"
        if doesFileExist script then fileIn script
        else messageBox "Cyrus Scatter could not find the script paired with its loaded native module. Run the complete installer and restart Max." title:"Cyrus Scatter"
    )
)
