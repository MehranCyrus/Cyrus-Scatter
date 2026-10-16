global CyrusFalloffGraph,CyrusPointSuspended,CyrusViewportRedraw,CyrusNewLayerID
-- Named data presets. Scene bindings are captured here, never stored in files.
global CyrusPresetBinding,CyrusPresetBrowser,CyrusPresetOpenBinding,CyrusOpenPresets
global CyrusPresetMakeBinding,CyrusPresetCheckBinding,CyrusPresetCapture,CyrusPresetApply
global CyrusPresetDirectory,CyrusPresetRead,CyrusPresetWrite,CyrusPresetEntries
struct CyrusPresetBinding (root,node,owner,ownerID,category,peer=undefined,peerID="",editor=undefined)

fn CyrusPresetMakeBinding root owner category peer:undefined editor:undefined = (
    if root==undefined or owner==undefined do throw "Select a layer before opening presets."
    local nodes=for n in refs.dependentNodes root where isValidNode n and n.baseObject==root collect n
    if nodes.count!=1 do throw "Presets require one unambiguous Scatter controller."
    CyrusPresetBinding root:root node:nodes[1] owner:owner ownerID:owner.layerID category:category peer:peer peerID:(if peer==undefined then "" else peer.layerID) editor:editor
)
fn CyrusPresetCheckBinding target = (
    if target==undefined or not isValidNode target.node or target.node.baseObject!=target.root do throw "The preset controller was removed or replaced."
    if target.owner.layerID!=target.ownerID do throw "The preset layer identity changed."
    local parent=target.root.logicalParent target.owner
    if findItem target.root.layerObjects parent==0 do throw "The preset layer was removed."
    if target.owner.isPaintArea and findItem parent.paintAreas target.owner==0 do throw "The preset Paint Area was removed."
    if target.peer!=undefined and (findItem target.root.layerObjects target.peer==0 or target.peer.layerID!=target.peerID) do throw "The other spacing layer was removed or replaced."
    if target.editor!=undefined and (target.editor!=CyrusFalloffGraph or not target.editor.presetTargetValid()) do throw "The curve target is no longer available. Reopen its graph."
    true
)
fn CyrusPresetCapture target = (
    CyrusPresetCheckBinding target
    if target.editor!=undefined do return target.editor.presetValues()
    local meters=units.decodeValue "1m",schema=cyrusPresetSchema target.category
    if target.category=="spacing" do (
        local values=target.owner.procSelfRule()
        if target.peer!=undefined do (
            local i=target.root.procPair 2 target.owner target.peer
            values=if i==0 then #(false,1.0,0.0,false) else #(target.root.procRuleEnabled[i],target.root.procRuleMultiplier[i],target.root.procRuleGapWU[i],target.root.procRulePlanar[i])
        )
        values[3]/=meters;return values
    )
    for field in schema collect (local v=getProperty target.owner (field[1] as name);if field[3] then v/meters else v)
)
fn CyrusPresetApply target document seedPolicy:#saved = (
    if findItem #(#saved,#current,#new) seedPolicy==0 do throw "Choose Saved, Current or New seed."
    if target.category!="population" and seedPolicy!=#saved do throw "Seed choices apply only to Amount presets."
    CyrusRequireAuthor();CyrusPresetCheckBinding target
    if theHold.Holding() do throw "Finish the current undoable operation before applying a preset."
    -- Revalidate the entire typed proposal even for callers that bypass the browser.
    document=cyrusPresetDecode (cyrusPresetEncode document[1] document[2] document[3])
    if document[1]!=target.category do throw "This preset belongs to a different category."
    local schema=cyrusPresetSchema target.category,values=deepCopy document[3],owner=target.owner,meters=units.decodeValue "1m"
    local fields=for f in schema collect (f[1] as name)
    if target.category=="population" do (
        local index=findItem fields #randomSeed
        if seedPolicy==#current then values[index]=owner.randomSeed
        else if seedPolicy==#new do (
            local identity=(dotNetClass "System.Guid").NewGuid()
            local chosen=bit.and (identity.GetHashCode()) 2147483647
            if chosen==owner.randomSeed do chosen=if chosen==2147483647 then 0 else chosen+1
            values[index]=chosen
        )
    )
    if target.category=="spacing" then (
        fields=if target.peer==undefined then #(#procSelfEnabled,#procSelfMultiplier,#procSelfGap,#procSelfPlanar) else #()
        values[3]*=meters
    ) else if target.editor==undefined do for i=1 to fields.count where schema[i][3] do values[i]*=meters
    if target.editor==undefined do for v in values where classof v!=BooleanClass do if v!=v or abs v>1e30 do throw "Preset units exceed the scene's supported numeric range."
    if target.category=="transforms" do (
        local modeIndex=findItem fields #orientationMode
        if values[modeIndex]==3 and not isValidNode owner.orientationTarget do throw "Pick a destination target before applying Look at target settings, or import a complete recipe with its target binding."
    )
    local controllers=#()
    for field in fields do (
        local control=getPropertyController owner field
        if control!=undefined do (
            if findItem #(Bezier_Float,Linear_Float,TCB_Float) (classof control)==0 or (numKeys control)!=0 do throw "Apply requires static numeric settings. Animated or wired target parameters are preserved."
            append controllers #(field,control)
        )
    )
    -- Reconstruct and validate editor-only data before starting authored Undo.
    local curveRollback=if target.editor==undefined then undefined else target.editor.presetPrepare values
    local priorTransfer=owner.getLayerTransfer(),priorSuspended=CyrusPointSuspended
    theHold.Begin();CyrusPointSuspended=true;owner.setLayerTransfer true
    try (
        with animate off (
            -- Detach static controllers before changing their values, preserving
            -- other owners that shared the original controller.
            for pair in controllers do setPropertyController owner pair[1] (copy pair[2])
            if target.editor!=undefined then target.editor.presetApply values
            else if target.category=="spacing" and target.peer!=undefined then target.root.procSetPair 2 owner target.peer values[1] values[2] values[3] values[4]
            else (
                if target.category=="spacing" do owner.procSelfOverride=true
                for i=1 to fields.count do setProperty owner fields[i] values[i]
            )
        )
        owner.setLayerTransfer priorTransfer;CyrusPointSuspended=priorSuspended
        theHold.Accept "Cyrus apply preset"
    )catch(
        local failure=getCurrentException()
        theHold.Cancel();owner.setLayerTransfer priorTransfer;CyrusPointSuspended=priorSuspended
        if target.editor!=undefined do target.editor.presetRestore curveRollback
        throw()
    )
    owner.markInputDirty();target.root.bindNativeUI();CyrusViewportRedraw();true
)
fn CyrusPresetDirectory = (pathConfig.appendPath (getDir #plugcfg) "CyrusScatter\\Presets")
fn CyrusPresetRead path = (
    local file=dotNetObject "System.IO.FileInfo" path
    if not file.Exists do throw "The preset file no longer exists. Refresh the list."
    if file.Length>65536 do throw "Preset files are limited to 64 KiB."
    local stream=dotNetObject "System.IO.FileStream" path (dotNetClass "System.IO.FileMode").Open (dotNetClass "System.IO.FileAccess").Read (dotNetClass "System.IO.FileShare").Read
    local reader=undefined,text=""
    try (
        if stream.Length>65536 do throw "Preset files are limited to 64 KiB."
        reader=dotNetObject "System.IO.StreamReader" stream (dotNetObject "System.Text.UTF8Encoding" false true) false
        text=reader.ReadToEnd();reader.Close()
    )catch(local failure=getCurrentException();if reader!=undefined do reader.Close();stream.Close();throw())
    cyrusPresetDecode text
)
fn CyrusPresetWrite path document replace:false = (
    local text=cyrusPresetEncode document[1] document[2] document[3],io=dotNetClass "System.IO.File",dir=dotNetClass "System.IO.Path"
    local directory=dir.GetDirectoryName path
    (dotNetClass "System.IO.Directory").CreateDirectory directory
    local temp=pathConfig.appendPath directory (CyrusNewLayerID()+".tmp")
    local backup=temp+".bak"
    try (
        io.WriteAllText temp text (dotNetObject "System.Text.UTF8Encoding" false true)
        CyrusPresetRead temp
        if replace then io.Replace temp path backup else io.Move temp path
    )catch(local failure=getCurrentException();if io.Exists temp do io.Delete temp;throw())
    -- Replacement is already committed; backup cleanup cannot undo that success.
    if io.Exists backup do try(io.Delete backup)catch()
    true
)
fn CyrusPresetEntries directory category = (
    if not (dotNetClass "System.IO.Directory").Exists directory do return #(#(),0)
    local files=getFiles (pathConfig.appendPath directory "*.cspreset.json"),items=#(),invalid=0
    if files.count>512 do throw "The preset folder contains more than 512 items. Move unused files to another folder."
    for path in files do try (
        local document=CyrusPresetRead path
        if document[1]==category do append items #(path,document[2])
    )catch(invalid+=1)
    #(items,invalid)
)
fn CyrusOpenPresets root owner category peer:undefined editor:undefined = (
    if cyrusPresetVersion==undefined or cyrusPresetVersion()!=3 do throw "Load the matching Cyrus preset native module."
    local target=CyrusPresetMakeBinding root owner category peer:peer editor:editor
    CyrusPresetCheckBinding target
    if CyrusPresetBrowser!=undefined do try(destroyDialog CyrusPresetBrowser)catch()
    rollout browser "Cyrus presets" width:420 height:385 (
        local target=undefined,entries=#(),directory=""
        label targetInfo "" pos:[12,10] width:396 height:38
        listbox presets "Saved presets" pos:[12,50] width:396 height:8
        edittext presetName "Name:" pos:[12,190] width:396
        button saveNew "Save new" pos:[12,220] width:90
        button applyPreset "Apply" pos:[112,220] width:90
        button renamePreset "Rename" pos:[212,220] width:90
        button deletePreset "Delete" pos:[312,220] width:96
        button refreshList "Refresh" pos:[12,255] width:90
        button closeButton "Close" pos:[312,255] width:96
        dropdownlist seedChoice "Amount seed:" items:#("Saved seed","Keep current seed","New seed") selection:1 pos:[12,288] width:396 tooltip:"Amount presets save a seed, not receiver variation domains. Changing this choice does not change the scene."
        label status "Selecting a preset does not change the scene." pos:[12,336] width:396 height:44
        fn refresh selectPath:undefined = (
            if selectPath==undefined and presets.selection>0 and presets.selection<=entries.count do selectPath=entries[presets.selection][1]
            local result=CyrusPresetEntries directory target.category
            entries=result[1];presets.items=for item in entries collect item[2]
            local selected=0
            for i=1 to entries.count where entries[i][1]==selectPath do selected=i
            presets.selection=if selected>0 then selected else if entries.count>0 then 1 else 0
            presetName.text=if presets.selection>0 then entries[presets.selection][2] else ""
            status.text=(entries.count as string)+" saved; "+(result[2] as string)+" invalid files skipped. Select, then Apply."
        )
        fn selectedPath = (if presets.selection<1 or presets.selection>entries.count then throw "Select a saved preset." else entries[presets.selection][1])
        fn enteredName = (local value=trimRight (trimLeft presetName.text);if value=="" do throw "Enter a preset name.";value)
        on browser open do (
            target=CyrusPresetOpenBinding;directory=CyrusPresetDirectory()
            seedChoice.visible=target.category=="population";seedChoice.enabled=seedChoice.visible
            targetInfo.text=(target.root.layerCaption (target.root.logicalParent target.owner))+" / "+target.category+(if target.peer!=undefined then " / "+target.root.layerCaption target.peer else "")
            if target.editor!=undefined do targetInfo.text+=("\nCurve is "+(if target.editor.presetEnabled() then "enabled" else "disabled")+". Apply preserves this state.")
            try(refresh())catch(status.text=getCurrentException())
        )
        on presets selected i do if i>0 and i<=entries.count do presetName.text=entries[i][2]
        on saveNew pressed do try(
            if (getFiles (pathConfig.appendPath directory "*.cspreset.json")).count>=512 do throw "The preset library is full (512 files)."
            local document=#(target.category,enteredName(),CyrusPresetCapture target)
            local path=pathConfig.appendPath directory (CyrusNewLayerID()+".cspreset.json")
            CyrusPresetWrite path document;refresh selectPath:path;status.text="Preset saved. Scene settings are unchanged."
        )catch(status.text=getCurrentException())
        on applyPreset pressed do try(
            local document=CyrusPresetRead (selectedPath())
            CyrusPresetApply target document seedPolicy:(if target.category=="population" then #(#saved,#current,#new)[seedChoice.selection] else #saved)
            status.text=if target.root.updateMode==1 then "Applied. Manual mode: use Update scatter." else "Applied. Live update follows the normal dependency rules."
        )catch(status.text=getCurrentException())
        on renamePreset pressed do try(
            local path=selectedPath(),document=CyrusPresetRead path
            document[2]=enteredName();CyrusPresetWrite path document replace:true;refresh selectPath:path
        )catch(status.text=getCurrentException())
        on deletePreset pressed do try(
            local path=selectedPath()
            if queryBox ("Delete preset '"+entries[presets.selection][2]+"'?") title:"Cyrus presets" do ((dotNetClass "System.IO.File").Delete path;refresh())
        )catch(status.text=getCurrentException())
        on refreshList pressed do try(refresh())catch(status.text=getCurrentException())
        on closeButton pressed do destroyDialog browser
        on browser close do CyrusPresetBrowser=undefined
    )
    CyrusPresetOpenBinding=target;CyrusPresetBrowser=browser
    createDialog browser style:#(#style_titlebar,#style_sysmenu,#style_toolwindow)
    true
)
