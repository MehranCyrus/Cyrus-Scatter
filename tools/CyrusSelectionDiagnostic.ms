-- Standalone support tool. Scan/report uses direct state reads, not geometry evaluation.
-- Select buttons change selection/panel mode; Unlock explicitly clears only the selection-set lock.
global CyrusSelectionDiagnostic, CyrusSelectionDiagnosticHeadless
global AminScatterObject, CyrusSurfaceAnalyzer
global CyrusSelectionDiagnosticPath=getSourceFileName()
try(destroyDialog CyrusSelectionDiagnostic)catch()

fn CyrusSelectionKind node = (
    if not isValidNode node do return ""
    local kind=classof node.baseObject
    if AminScatterObject!=undefined and kind==AminScatterObject then "Scatter"
    else if CyrusSurfaceAnalyzer!=undefined and kind==CyrusSurfaceAnalyzer then "Analyzer"
    else ""
)
fn CyrusSelectionNodes = (for n in objects where (CyrusSelectionKind n)!="" collect n)
-- Autodesk's selection-set lock is separate from node/layer frozen flags.
fn CyrusSelectionCore = ((dotNetClass "Autodesk.Max.GlobalInterface").Instance.COREInterface)
fn CyrusSelectionLocked = (
    try (
        local value=(CyrusSelectionCore()).SelectionFrozen
        value==true or value==1
    )catch(undefined)
)
fn CyrusSelectionUnlock = (
    if (CyrusSelectionLocked())==undefined do throw "Selection-lock state unavailable; inspect the status-bar padlock."
    if (CyrusSelectionLocked())==true do (CyrusSelectionCore()).ThawSelection()
    (CyrusSelectionLocked())==false
)
fn CyrusSelectionState node = (
    local s=stringStream ""
    format "% | % | handle %\n" node.name (CyrusSelectionKind node) node.handle to:s
    for key in #(#isSelected,#isFrozen,#isNodeFrozen,#isHidden,#isNodeHidden,#isHiddenInVpt,#renderable) do (
        local value=try(getProperty node key)catch("unavailable")
        format "  %: %\n" key value to:s
    )
    format "  shown by ViewportFilter (viewport %): %\n" (try(ViewportFilter.ViewportID)catch("unavailable")) (try(ViewportFilter.IsNodeShown node)catch("unavailable")) to:s
    local layer=try(node.layer)catch(undefined)
    local depth=0
    while layer!=undefined and depth<64 do (
        format "  layer %: frozen=% hidden=%\n" layer.name layer.isFrozen layer.isHidden to:s
        layer=try(layer.getParent())catch(undefined);depth+=1
    )
    format "  group member: % | open group member: %\n" (try(isGroupMember node)catch("unavailable")) (try(isOpenGroupMember node)catch("unavailable")) to:s
    local parent=node.parent;depth=0
    while parent!=undefined and depth<64 do (
        format "  parent: % | group head=% | open=%\n" parent.name (try(isGroupHead parent)catch("unavailable")) (try(isOpenGroupHead parent)catch("unavailable")) to:s
        parent=parent.parent;depth+=1
    )
    s as string
)
fn CyrusSelectionReport nodes = (
    local s=stringStream ""
    format "Cyrus selection diagnostic\nUTC: %\nMax: %\nScene: %%\n" ((dotNetClass "System.DateTime").UtcNow.ToString "o") (maxVersion()) maxFilePath maxFileName to:s
    format "Selected node handles: %\n" (for n in selection collect n.handle) to:s
    local locked=CyrusSelectionLocked()
    format "Selection lock: %\nSub-object level: %\nCommand panel: %\n" (if locked==undefined then "unavailable; inspect the status-bar padlock" else locked) subObjectLevel (getCommandPanelTaskMode()) to:s
    format "Selection filter: % (%)\n" (GetSelectFilter()) (GetSelectFilterName (GetSelectFilter())) to:s
    format "Active viewport: % | ViewportFilter target: %\n" viewport.activeViewport (try(ViewportFilter.ViewportID)catch("unavailable")) to:s
    format "ViewportFilter enabled: % | renderable-only: %\n" (try(ViewportFilter.Enabled)catch("unavailable")) (try(ViewportFilter.ShowRenderable)catch("unavailable")) to:s
    format "Current layer: %\n" (try(LayerManager.current.name)catch("unavailable")) to:s
    format "Geometry hidden by category: %\nHide frozen objects: %\n" (try(hideByCategory.geometry)catch("unavailable")) (try(maxOps.hideFrozenObjects)catch("unavailable")) to:s
    format "Cyrus nodes found: %\n\n" nodes.count to:s
    for n in nodes do format "%\n" (CyrusSelectionState n) to:s
    format "\nRegistered redraw callbacks (source locations):\n" to:s
    try(showRegisteredRedrawViewsCallbacks to:s)catch(format "Unavailable: %\n" (getCurrentException()) to:s)
    format "\nSelection callbacks:\n" to:s
    try(callbacks.show #selectionSetChanged to:s)catch(format "Unavailable: %\n" (getCurrentException()) to:s)
    format "\nInterpretation:\n- Frozen nodes or layers can block selection. This tool does not unfreeze them.\n- Both Cyrus controllers are Geometry objects with renderable=false by design. Explorer filters for helpers or renderable-only objects can omit them.\n- A successful direct selection with unchanged flags separates viewport/list filtering from a missing node.\n- This report does not rebuild previews, run analysis, or inspect heavy meshes.\n" to:s
    s as string
)
fn CyrusSelectDirect node = (
    if not isValidNode node do throw "This object is no longer present. Click Scan again."
    select node
    node.isSelected
)

rollout CyrusSelectionDiagnostic "Cyrus - selection diagnostic" width:620 height:700 (
    local nodes=#(),text="",lastReport="",pendingNode=undefined,pendingTicks=0,pendingClock=undefined
    label intro "Scan is read-only. Select changes selection. Unlock clears only the selection lock." align:#left
    button scan "Scan Cyrus objects" width:280 across:2
    button save "Save diagnostic report" width:280
    listbox found "Cyrus objects (including hidden/frozen nodes)" items:#() width:590 height:9
    button direct "Select listed object" width:280 across:2
    button createPanel "Select via Create panel" width:280
    label hint "Create-panel selection helps identify Modify-panel errors; it leaves that panel active." align:#left
    label lockState "Selection lock: checking..." width:280 across:2
    button unlock "Turn off selection lock" width:280 enabled:false
    label outcome "Select a row to inspect its flags." align:#left width:590 height:42
    edittext details "" text:"" width:590 height:240 readOnly:true
    button openFolder "Open saved report folder" width:250
    timer later interval:250 active:false
    fn displayReport = (details.text=text)
    fn appendNote value = (text+="\n"+value+"\n";displayReport())
    fn refreshLock = (
        local locked=CyrusSelectionLocked()
        lockState.text=if locked==undefined then "Selection lock: unavailable" else if locked then "Selection lock: ON" else "Selection lock: OFF"
        unlock.enabled=(locked==true)
    )
    fn scanNow = (
        nodes=CyrusSelectionNodes()
        found.items=for n in nodes collect ((CyrusSelectionKind n)+" | "+n.name+" | "+(n.handle as string)+(if n.isFrozen then " | FROZEN" else "")+(if n.isHiddenInVpt then " | HIDDEN" else ""))
        text=CyrusSelectionReport nodes;displayReport();refreshLock()
        outcome.text=(nodes.count as string)+" Cyrus objects found. Scanning did not change their flags."
    )
    fn selectedNode = (
        if found.selection<1 or found.selection>nodes.count do throw "Select a Cyrus object from this list first."
        nodes[found.selection]
    )
    fn trySelect useCreate = (
        local node=selectedNode()
        appendNote ("BEFORE selection attempt:\n"+(CyrusSelectionState node))
        if useCreate do setCommandPanelTaskMode mode:#create
        local success=CyrusSelectDirect node
        appendNote ("Direct selection returned "+(success as string)+". Current panel: "+(getCommandPanelTaskMode() as string))
        pendingNode=node;pendingTicks=0;pendingClock=(dotNetClass "System.Diagnostics.Stopwatch").StartNew();later.active=true
        outcome.text=if success then "Selected now. Checking whether selection persists..." else "Selection did not take effect. Save the report."
    )
    on scan pressed do try(scanNow())catch(outcome.text=getCurrentException())
    on unlock pressed do try (
        appendNote ("Selection lock before explicit unlock: "+(CyrusSelectionLocked() as string))
        local success=CyrusSelectionUnlock()
        appendNote ("Selection lock after explicit unlock: "+(CyrusSelectionLocked() as string))
        refreshLock()
        outcome.text=if success then "Selection lock is OFF. Try normal selection in Max now." else "Could not turn off selection lock. Save the report."
    )catch(appendNote ("UNLOCK ERROR: "+getCurrentException());outcome.text="Could not read/change selection lock. Save the report.")
    on found selected index do (if index>0 and index<=nodes.count do details.text=CyrusSelectionState nodes[index])
    on direct pressed do try(trySelect false)catch(appendNote ("SELECTION ERROR: "+getCurrentException());outcome.text="Selection raised an error. Save the report.")
    on createPanel pressed do try(trySelect true)catch(appendNote ("CREATE-PANEL SELECTION ERROR: "+getCurrentException());outcome.text="Selection raised an error. Save the report.")
    on later tick do (
        pendingTicks+=1
        if pendingTicks>=4 do (
            later.active=false
            local stillSelected=try(isValidNode pendingNode and pendingNode.isSelected)catch(false)
            appendNote ("Selected after "+(formattedPrint pendingClock.Elapsed.TotalSeconds format:".1f")+" seconds: "+(stillSelected as string))
            outcome.text=if stillSelected then "Selection persisted. The result is recorded; save the report." else "Selection did not persist. Save the report."
        )
    )
    on save pressed do try (
        local root=(dotNetClass "System.IO.Path").GetFullPath ((getFilenamePath CyrusSelectionDiagnosticPath)+"../build/selection-diagnostics/")
        (dotNetClass "System.IO.Directory").CreateDirectory root
        local stamp=(dotNetClass "System.DateTime").UtcNow.ToString "yyyyMMdd-HHmmss-ffff"
        lastReport=root+"selection-"+stamp+".txt"
        local full=text+"\nSTATE AT EXPORT:\n"+(CyrusSelectionReport (CyrusSelectionNodes()))
        (dotNetClass "System.IO.File").WriteAllText lastReport full (dotNetObject "System.Text.UTF8Encoding" false)
        outcome.text="Saved: "+lastReport
    )catch(outcome.text=getCurrentException())
    on openFolder pressed do (if lastReport!="" do shellLaunch (getFilenamePath lastReport) "")
    on CyrusSelectionDiagnostic open do try(scanNow())catch(outcome.text=getCurrentException())
    on CyrusSelectionDiagnostic close do (later.active=false;pendingNode=undefined;nodes=#())
)
if CyrusSelectionDiagnosticHeadless!=true do createDialog CyrusSelectionDiagnostic
