(
    try(CyrusStopBrush())catch()
    try(CyrusBrushTimer.Stop())catch()
    try(unRegisterRedrawViewsCallback CyrusBrushViewportDraw)catch()
    try(CyrusReleaseTimer.Stop())catch()
    try(CyrusPointClear())catch()
    callbacks.removeScripts id:#CyrusBrushSession
    try(CyrusPFTimer.Stop())catch()
    try(CyrusPFBeforeSceneChange())catch()
    callbacks.removeScripts id:#CyrusPFBridge
    callbacks.removeScripts id:#CyrusScatterIconColor
    try(AminScatterRenderEnd())catch()
    callbacks.removeScripts id:#AminScatterAutoRender
    callbacks.removeScripts id:#AminScatterLayers
    try(AminScatterNodeEvents.enabled=false)catch()
    try(unRegisterTimeCallback AminScatterLiveTime)catch()
    try(unRegisterRedrawViewsCallback AminScatterObjectDraw)catch()
    local pluginIni=pathConfig.appendPath (getFilenamePath (getMAXIniFile())) "Plugin.UserSettings.ini"
    for key in #("CyrusScatter2026","CyrusScatter2027","AminScatter2026","AminScatter2027") do delINISetting pluginIni "Directories" key
    for name in #("CyrusScatter.mcr","Cyrus-CyrusScatterCreate.mcr","AminScatter.mcr","Cyrus-AminScatterOpen.mcr") do deleteFile (pathConfig.appendPath (getDir #userMacros) name)
    for name in #("CyrusScatterStartup.ms","AminScatterStartup.ms") do deleteFile (pathConfig.appendPath (getDir #userStartupScripts) name)
    messageBox "Cyrus Scatter startup registration has been removed.\nRestart Max before removing its CyrusScatter folder from your user scripts directory.\nSaved scenes and baked instances are preserved.\n\nClose the separate Cyrus Automation panel if it is running." title:"Cyrus Scatter"
)
