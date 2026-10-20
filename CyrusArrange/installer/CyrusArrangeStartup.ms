global CA_AUTO_SHOW_UI, CA_STARTUP_OK, CA_STARTUP_ERROR
global caVersion, caModulePaths
CA_STARTUP_OK = false
CA_STARTUP_ERROR = ""
(
    local io = dotNetClass "System.IO.File"
    local paths = dotNetClass "System.IO.Path"
    local destination = (getDir #userScripts)+"/CyrusArrange/__VERSION__-__PAYLOAD_ID__/"
    fn hashFile io path =
    (
        local algorithm = (dotNetClass "System.Security.Cryptography.SHA256").Create()
        local digest = algorithm.ComputeHash (io.ReadAllBytes path)
        algorithm.Dispose()
        toLower (substituteString ((dotNetClass "System.BitConverter").ToString digest) "-" "")
    )
    try
    (
        if (maxVersion())[1] != 29000 do throw "Cyrus Arrange __VERSION__ requires Max 2027."
        if caVersion == undefined or caModulePaths == undefined do throw "Restart Max 2027 after installing Cyrus Arrange."
        if caVersion() != "__VERSION__" do throw "The loaded Cyrus Arrange version differs from this installed UI. Restart Max 2027."
        local loaded = caModulePaths()
        local modules = #("CyrusArrange.dlx","CyrusArrangeStorage.dlh")
        for i = 1 to 2 do
            if (toLower ((paths.GetFullPath loaded[i]) as string)) != (toLower ((paths.GetFullPath (destination+"bin/"+modules[i])) as string)) do
                throw ("A different native module is loaded: "+modules[i]+". Check duplicate plugin paths and restart Max.")
        for item in __CORE_FILES__ do
            if (hashFile io (destination+item[1])) != item[2] do throw ("Installed payload hash mismatch: "+item[1])
        CA_AUTO_SHOW_UI = false
        for script in #("CyrusArrange.ms","ArrangeAssets.ms","ArrangeRegions.ms","ArrangeCollision.ms","ArrangeWorkflow.ms","ArrangeModifier.ms") do
            fileIn (destination+script)
        CA_STARTUP_OK = true
    )
    catch
    (
        CA_STARTUP_ERROR = getCurrentException() as string
        format "Cyrus Arrange startup: %\n" CA_STARTUP_ERROR
    )
)
