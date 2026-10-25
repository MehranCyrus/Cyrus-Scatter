-- Installation preference: shared by Scatter controllers in this Max process.
-- Applying it changes future native admission only; scene data and Undo stay untouched.
global CyrusViewportMemoryInitialized,CyrusViewportMemoryDialog,CyrusViewportMemoryOwner
global CyrusViewportMemoryPreferences,CyrusInitializeViewportMemory,CyrusApplyViewportMemory
global CyrusOpenViewportMemory,CyrusViewportMemoryOwnerValid

fn CyrusViewportMemoryPreferences = pathConfig.appendPath (getDir #plugcfg) "CyrusScatterViewport.ini"
fn CyrusInitializeViewportMemory = (
    if CyrusViewportMemoryInitialized==true do return true
    if cyrusSetViewportMemoryLimit==undefined or cyrusViewportMemoryStats==undefined do
        throw "Install the complete Cyrus 0.87.0 package and restart Max."
    local value=0,stored=getINISetting (CyrusViewportMemoryPreferences()) "Memory" "LimitMiB"
    if stored!="" do try(value=stored as integer)catch(value=0)
    if value!=0 and (value<256 or value>65536) do value=0
    cyrusSetViewportMemoryLimit value
    CyrusViewportMemoryInitialized=true
    true
)
fn CyrusApplyViewportMemory value = (
    CyrusInitializeViewportMemory()
    local previous=(cyrusViewportMemoryStats())[2]
    cyrusSetViewportMemoryLimit value
    try (
        if not (setINISetting (CyrusViewportMemoryPreferences()) "Memory" "LimitMiB" (value as string)) do
            throw "The viewport memory preference could not be saved."
    ) catch (cyrusSetViewportMemoryLimit previous;throw())
    true
)
fn CyrusViewportMemoryOwnerValid controller = (
    if controller==undefined do return false
    for node in refs.dependentNodes controller where isValidNode node and node.baseObject==controller do return true
    false
)
rollout CyrusViewportMemoryDialog "Cyrus viewport memory" width:410 height:340 (
    local controller=undefined
    radiobuttons mode "Memory allowance" labels:#("Automatic","Custom") columns:2 pos:[14,12] width:380
    spinner customLimit "Custom limit (MiB):" range:[256,65536,4096] type:#integer fieldWidth:84 pos:[14,63] width:380
    label scope "Shared by all Cyrus Scatter objects in this Max installation." pos:[14,94] width:380 height:32
    label usage "" pos:[14,130] width:380 height:54
    label detail "CPU and graphics resources are estimates. Native headroom and graphics safety limits still apply." pos:[14,188] width:380 height:40
    label status "Applying this preference keeps pending Manual edits unchanged." pos:[14,234] width:380 height:40
    button applyButton "Apply" pos:[14,290] width:105 height:28
    button refreshButton "Refresh display" pos:[127,290] width:150 height:28 tooltip:"Retry the current display using published placements. Pending Manual edits remain pending."
    button closeButton "Close" pos:[285,290] width:109 height:28
    fn showUsage = (
        local stats=cyrusViewportMemoryStats()
        if stats.count!=16 or stats[1]!=1 do throw "Unsupported viewport memory statistics. Install the matching package."
        local mib=1048576.0
        usage.text="Allowance: "+(((stats[3]/mib) as integer) as string)+" MiB\nIn use: "+(((stats[4]/mib) as integer) as string)+" MiB; peak: "+(((stats[5]/mib) as integer) as string)+" MiB (estimated)"
        customLimit.enabled=mode.state==2
        refreshButton.enabled=CyrusViewportMemoryOwnerValid controller
    )
    on mode changed value do customLimit.enabled=value==2
    on applyButton pressed do try (
        CyrusApplyViewportMemory (if mode.state==1 then 0 else customLimit.value)
        showUsage()
        status.text="Saved. Existing display resources are retained. Use Refresh display to retry."
    )catch(status.text=getCurrentException())
    on refreshButton pressed do try (
        local owner=controller
        if not (CyrusViewportMemoryOwnerValid owner) do throw "Select a current Scatter and open Viewport memory again."
        owner.refreshDisplay()
        showUsage()
        status.text=owner.allStatus()
    )catch(status.text=getCurrentException())
    on closeButton pressed do destroyDialog CyrusViewportMemoryDialog
    on CyrusViewportMemoryDialog open do (
        controller=CyrusViewportMemoryOwner
        CyrusInitializeViewportMemory()
        local requested=(cyrusViewportMemoryStats())[2]
        mode.state=if requested==0 then 1 else 2
        if requested!=0 do customLimit.value=requested
        showUsage()
    )
    on CyrusViewportMemoryDialog close do (controller=undefined;CyrusViewportMemoryOwner=undefined)
)
fn CyrusOpenViewportMemory controller = (
    CyrusInitializeViewportMemory()
    if CyrusViewportMemoryDialog.hwnd!=0 do destroyDialog CyrusViewportMemoryDialog
    CyrusViewportMemoryOwner=controller
    createDialog CyrusViewportMemoryDialog style:#(#style_titlebar,#style_border,#style_sysmenu)
    true
)
if cyrusSetViewportMemoryLimit!=undefined do CyrusInitializeViewportMemory()
