-- Copies tested tracing scripts for the NEXT Max start. Never fileIn/redefine live objects.
global CSPTraceInstaller,CSPTraceInstallerHeadless
global CSPTraceInstallerPath=getSourceFileName()
try(destroyDialog CSPTraceInstaller)catch()
fn CSPInstallHash path = (
    local sha=(dotNetClass "System.Security.Cryptography.SHA256").Create()
    local bytes=(dotNetClass "System.IO.File").ReadAllBytes path
    local hash=sha.ComputeHash bytes
    sha.Dispose()
    substituteString ((dotNetClass "System.BitConverter").ToString hash) "-" ""
)
fn CSPInstallTracing sourceRoot targetRoot = (
    local paths=#("AminScatter/AminScatterObject.ms","CyrusSurfaceAnalyzer/CyrusSurfaceAnalyzer.ms")
    local sources=#(sourceRoot+"AminScatter/scripts/AminScatterObject.ms",sourceRoot+"CyrusSurfaceAnalyzer/scripts/CyrusSurfaceAnalyzer.ms")
    local originals=#("3F764C104FC809E2442B351DD1ADE0204FF29DC3E4E11F12132B9CF6D99BE3CD","BCC3162975E5EDF3A9EFA4AE3BEA11C8AEF97D0393D430D9F971CB0C355997AA")
    local targets=for path in paths collect targetRoot+path
    local needed=false
    -- Preflight BOTH targets before any write. Unknown versions require review.
    for i=1 to 2 do (
        if not doesFileExist sources[i] or not doesFileExist targets[i] do throw ("Missing source/installed script: "+paths[i])
        local old=CSPInstallHash targets[i],new=CSPInstallHash sources[i]
        if old!=new and old!=originals[i] do throw ("Installed script differs from the tested version: "+paths[i]+". Nothing copied; send this message for review.")
        if old!=new do needed=true
    )
    if not needed do return "Tracing scripts already match. Restart Max if it was open during installation."
    local stamp=(dotNetClass "System.DateTime").UtcNow.ToString "yyyyMMdd-HHmmss-ffff"
    local backup=targetRoot+"CyrusPerformanceTraceBackups/"+stamp+"/"
    (dotNetClass "System.IO.Directory").CreateDirectory backup
    for i=1 to 2 do (dotNetClass "System.IO.File").Copy targets[i] (backup+(filenameFromPath targets[i])) false
    local failure=undefined
    try (
        for i=1 to 2 do (
            (dotNetClass "System.IO.File").Copy sources[i] targets[i] true
            if CSPInstallHash sources[i]!=CSPInstallHash targets[i] do throw "Installed script verification failed."
        )
    )catch(
        failure=getCurrentException()
        for i=1 to 2 do try((dotNetClass "System.IO.File").Copy (backup+(filenameFromPath targets[i])) targets[i] true)catch()
    )
    if failure!=undefined do throw (failure+"\nRestore originals from: "+backup)
    "Installed for next start. Save your scene and RESTART MAX.\nBackup: "+backup
)
rollout CSPTraceInstaller "Cyrus - install performance tracing" width:530 height:170 (
    label intro "Adds optional timing hooks to the existing Scatter and Analyzer scripts." width:505 align:#left
    label scope "Backs up both files. A Max restart is required; live objects are not reloaded." width:505 align:#left
    button install "Install tracing scripts for next Max start" width:490
    label result "Ready. No installed files changed yet." width:505 height:65 align:#left
    on install pressed do try (
        local root=(dotNetClass "System.IO.Path").GetFullPath ((getFilenamePath CSPTraceInstallerPath)+"../../")
        result.text=CSPInstallTracing root ((getDir #userScripts)+"/")
    )catch(result.text=getCurrentException())
)
if CSPTraceInstallerHeadless!=true do createDialog CSPTraceInstaller
