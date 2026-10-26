-- Cyrus Vegetation Lab owned startup v1
-- Expanded for one exact qualified native/script pair.
if (maxVersion())[1]==29000 do
(
    local root=@"__ROOT__"
    local specs=#(#("native/CyrusVegetationLab.dlx","__DLX_SHA__"),#("native/CyrusVegetationStorage.dlh","__DLH_SHA__"),#("scripts/CyrusVegetationLab.ms","__SCRIPT_SHA__"))
    fn cvlFileSHA path =
    (
        local stream=(dotNetClass "System.IO.File").OpenRead path
        local hash=(dotNetClass "System.Security.Cryptography.SHA256").Create(), bytes=undefined
        try(bytes=hash.ComputeHash stream;stream.Close();hash.Dispose())catch(stream.Close();hash.Dispose();throw())
        toLower (substituteString ((dotNetClass "System.BitConverter").ToString bytes) "-" "")
    )
    for spec in specs do if cvlFileSHA (pathConfig.appendPath root spec[1])!=spec[2] do throw "Vegetation Lab installed payload differs. Reinstall its complete package."
    fn cvlCanonical path = (toLower (substituteString ((dotNetClass "System.IO.Path").GetFullPath path) "\\" "/"))
    fn cvlLoadedPath name =
    (
        local result="",process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
        for i=0 to process.Modules.Count-1 do (local item=process.Modules.Item[i];if toLower item.ModuleName==toLower name do result=item.FileName)
        result
    )
    -- Check both existing modules before loading either. Never replace a loaded pair.
    for name in #("CyrusVegetationLab.dlx","CyrusVegetationStorage.dlh") do
    (
        local loaded=cvlLoadedPath name,expected=pathConfig.appendPath root ("native/"+name)
        if loaded!="" and cvlCanonical loaded!=cvlCanonical expected do throw "A different Vegetation Lab module is loaded. Restart with the complete matching package."
    )
    for name in #("CyrusVegetationLab.dlx","CyrusVegetationStorage.dlh") do
    (
        if cvlLoadedPath name=="" do loadDllsFromDir (pathConfig.appendPath root "native/") name
        local loaded=cvlLoadedPath name,expected=pathConfig.appendPath root ("native/"+name)
        if loaded=="" or cvlCanonical loaded!=cvlCanonical expected do throw "The verified Vegetation Lab native pair could not load."
    )
    fileIn (pathConfig.appendPath root "scripts/CyrusVegetationLab.ms")
)
