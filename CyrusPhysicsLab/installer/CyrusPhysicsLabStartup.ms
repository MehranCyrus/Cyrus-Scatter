-- Expanded by package.py for one exact native/script pair. Startup only.
if (maxVersion())[1]==29000 do
(
    local root=@"__ROOT__"
    local native=pathConfig.appendPath root "native/"
    local specs=#(#("CyrusPhysicsLab.dlx","__DLX_SHA__"),#("CyrusPhysicsStorage.dlh","__DLH_SHA__"))
    fn fileSHA path =
    (
        local stream=(dotNetClass "System.IO.File").OpenRead path
        local hash=(dotNetClass "System.Security.Cryptography.SHA256").Create()
        local bytes=undefined
        try(bytes=hash.ComputeHash stream;stream.Close();hash.Dispose())catch(stream.Close();hash.Dispose();throw())
        toLower (substituteString ((dotNetClass "System.BitConverter").ToString bytes) "-" "")
    )
    fn loadedPath name =
    (
        local result=""
        local process=(dotNetClass "System.Diagnostics.Process").GetCurrentProcess()
        for i=0 to process.Modules.Count-1 do
        (
            local item=process.Modules.Item[i]
            if toLower item.ModuleName==toLower name do result=item.FileName
        )
        result
    )
    for spec in specs do
    (
        local expected=pathConfig.appendPath native spec[1]
        local loaded=loadedPath spec[1]
        if loaded=="" do throw "Physics Lab native module is not loaded. Restart Max with its registered plug-in directory."
        if loaded!="" and toLower loaded!=toLower expected do throw "A different Physics Lab module is already loaded. Restart Max with the matching package."
        if fileSHA expected!=spec[2] do throw "Physics Lab native payload changed. Reinstall its complete package."
    )
    if fileSHA (pathConfig.appendPath native "CyrusPhysicsCrashWatch.exe")!="__WATCH_SHA__" do throw "Physics crash watcher does not match this package."
    if fileSHA (pathConfig.appendPath native "build-identity.json")!="__IDENTITY_SHA__" do throw "Physics diagnostic identity does not match this package."
    local script=pathConfig.appendPath root "scripts/CyrusPhysicsLab.ms"
    if fileSHA script!="__SCRIPT_SHA__" do throw "Physics Lab script does not match its installed native pair."
    fileIn script
)
