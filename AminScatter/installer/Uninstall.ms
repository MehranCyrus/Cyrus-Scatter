(
    try(CyrusPFTimer.Stop())catch()
    try(CyrusPFBeforeSceneChange())catch()
    callbacks.removeScripts id:#CyrusPFBridge
    callbacks.removeScripts id:#CyrusScatterIconColor
    try(AminScatterRenderEnd())catch()
    callbacks.removeScripts id:#AminScatterAutoRender
    callbacks.removeScripts id:#AminScatterLayers
    try(AminScatterNodeEvents.enabled=false)catch()
    try(unRegisterTimeCallback AminScatterLiveTime)catch()
    try(destroyDialog AminScatterUI)catch()
    try(unRegisterRedrawViewsCallback AminScatterObjectDraw)catch()
    local pluginIni=pathConfig.appendPath (getFilenamePath (getMAXIniFile())) "Plugin.UserSettings.ini"
    delINISetting pluginIni "Directories" "AminScatter2026"
    deleteFile ((getDir #userMacros)+"\\AminScatter.mcr")
    deleteFile ((getDir #userStartupScripts)+"\\AminScatterStartup.ms")
    messageBox "AminScatter startup registration has been removed.\nRestart Max to release its DLL, then delete only the AminScatter folder inside your user scripts folder.\nExisting baked scene instances are preserved." title:"AminScatter"
)



