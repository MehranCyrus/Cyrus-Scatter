-- Load in an owned private Max host after Max_Procedural_07_Acceptance.ms.
-- Reflection raises real WinForms mouse events; it does not inject pointer input.
global G074Event,G074Mouse,G074CheckPage,G074Run,G074Rows,G074Lifecycle
fn G074Event control eventName args = (
    local flags=dotNet.combineEnums (dotNetClass "System.Reflection.BindingFlags").Instance (dotNetClass "System.Reflection.BindingFlags").NonPublic
    local method=(control.GetType()).GetMethod eventName flags
    local values=dotNetObject "System.Object[]" 1
    values.SetValue args 0
    method.Invoke control values
)
fn G074Mouse control eventName y button:#left = (
    local buttons=dotNetClass "System.Windows.Forms.MouseButtons"
    local key=if button==#left then buttons.Left else if button==#right then buttons.Right else buttons.None
    G074Event control eventName (dotNetObject "System.Windows.Forms.MouseEventArgs" key 1 4 (y as integer) 0)
)
fn G074CheckPage page label = (
    local names=#(#flow_surfaceUI_receiversList,#flow_surfaceUI_globalContainers,#flow_layersUI_layerList,#sourceContainersUI_containersList,#sourceUI_plantList,#brushUI_strokeList,#backgroundUI_referenceList,#diversityUI_strokeChoices,#diversityUI_strokesList,#areaUI_areaList)
    page.open=true;page.advancedToggle.checked=true;page.bind page.owner
    for key in names where isProperty page key do (
        local list=getProperty page key,grip=getProperty page ((key as string)+"_grip" as name)
        -- Include conditionally hidden lists: validate their shared handlers too.
        grip.visible=true;grip.enabled=true
        local initial=list.height,items=list.items as string,selection=list.selection as string
        local before=page.height
        G074Mouse grip "OnMouseMove" 4 button:#none
        P07Assert (list.height==initial and page.height==before and page.dragList==undefined) (label+": hover resized list")
        G074Mouse grip "OnMouseDown" 4 button:#right
        P07Assert (page.dragList==undefined) (label+": right click began drag")
        G074Mouse grip "OnMouseDown" 4
        P07Assert (page.dragList==list and grip.Capture) (label+": mouse-down failed")
        local screenPoint=grip.PointToScreen (dotNetObject "System.Drawing.Point" 4 68)
        G074Mouse grip "OnMouseMove" 68
        P07Assert (list.height>=initial+50) (label+": drag did not enlarge "+key as string)
        -- Layout can move the grip and the entire rollout between columns.
        local larger=list.height
        grip.visible=true
        G074Mouse grip "OnMouseMove" (grip.PointToClient screenPoint).Y
        P07Assert (abs(list.height-larger)<16) (label+": moving grip caused runaway growth "+key as string)
        G074Mouse grip "OnMouseUp" 4
        P07Assert (not grip.Capture and page.dragList==undefined) (label+": mouse-up retained capture")
        grip.visible=true
        G074Mouse grip "OnMouseDown" 4
        G074Mouse grip "OnMouseMove" -10000
        P07Assert (list.height>=32 and list.height<=56) (label+": minimum clamp failed")
        G074Mouse grip "OnMouseUp" 4
        grip.visible=true
        G074Mouse grip "OnMouseDown" 4
        G074Mouse grip "OnMouseMove" 10000
        P07Assert (list.height>=880 and list.height<=900) (label+": maximum clamp failed")
        G074Mouse grip "OnMouseUp" 4
        list.height=initial;page.layout();grip.visible=true
        G074Mouse grip "OnMouseDown" 4
        grip.Capture=false
        P07Assert (page.dragList==undefined) (label+": capture loss retained drag")
        G074Mouse grip "OnMouseDown" 4
        page.bind page.owner
        P07Assert (page.dragList==undefined and not grip.Capture) (label+": rebind retained drag")
        P07Assert (list.items as string==items and list.selection as string==selection) (label+": resize changed list content/selection")
        P07Assert (grip.BorderStyle==(dotNetClass "System.Windows.Forms.BorderStyle").None and grip.BackColor.R==65) (label+": old raised handle remains")
        local bitmap=dotNetObject "System.Drawing.Bitmap" 120 8,graphics
        graphics=(dotNetClass "System.Drawing.Graphics").FromImage bitmap
        G074Event grip "OnPaint" (dotNetObject "System.Windows.Forms.PaintEventArgs" graphics (dotNetObject "System.Drawing.Rectangle" 0 0 120 8))
        graphics.Dispose();bitmap.Dispose()
        append G074Rows (label+"/"+key as string)
    )
)
fn G074Run mode = (
    if findString (toLower MCPFixtureDir) "/build/mcp-qualification/"==undefined do throw "Private host required"
    P07Case="0.74 grip events";P07New count:100;G074Rows=#()
    local r=P07Root,a=P07Layer,node=P07Node
    select node;max modify mode;modPanel.setCurrentObject r
    if not r.mainUI.controlsReady do r.mainUI.mountTimer.tick()
    r.refreshAll()
    local epoch=r.procEpoch,key=r.procInputKey(),prepared=a.procPreparedBuilds
    case mode of (
        #main: (for page in r.mainUI.editors do G074CheckPage page "main")
        #container: (
            local container=a.containerCreate()
            select container;modPanel.setCurrentObject container.baseObject
            if not container.baseObject.mainUI.controlsReady do container.baseObject.mainUI.mountTimer.tick()
            -- Container creation is a separate model edit, before measuring UI work.
            epoch=r.procEpoch;key=r.procInputKey();prepared=a.procPreparedBuilds
            for page in container.baseObject.mainUI.editors do G074CheckPage page "container"
        )
        #popup: (
            CyrusOpenLayerEditor r a
            for topic=1 to 6 do (
                CyrusLayerEditor.showTopic topic
                for page in CyrusLayerEditor.activeEditors() do G074CheckPage page ("popup"+topic as string)
            )
            CyrusCloseLayerEditor()
        )
    )
    P07Assert (r.procEpoch==epoch and r.procInputKey()==key and a.procPreparedBuilds==prepared) "Grip events rebuilt placements"
    local output=createFile (MCPFixtureDir+"grips-"+mode as string+".txt")
    format "PASS: % grip controls; down/move/up, stationary point, bounds, hover, right click, capture loss, rebind, paint, contents/selection and placement isolation.\n%\n" G074Rows.count G074Rows to:output
    close output
    G074Rows.count
)
fn G074Lifecycle = (
    if findString (toLower MCPFixtureDir) "/build/mcp-qualification/"==undefined do throw "Private host required"
    P07Case="0.74 grip lifecycle";P07New count:100
    local r=P07Root,a=P07Layer,node=P07Node
    select node;max modify mode;modPanel.setCurrentObject r
    if not r.mainUI.controlsReady do r.mainUI.mountTimer.tick()
    r.modelsUI.open=true;r.mainUI.bindSection r.modelsUI
    local page=r.modelsUI,grip=page.sourceUI_plantList_grip,initial=page.sourceUI_plantList.height
    G074Mouse grip "OnMouseDown" 4;G074Mouse grip "OnMouseMove" 68;G074Mouse grip "OnMouseUp" 4
    local resized=page.sourceUI_plantList.height
    P07Assert (resized>initial) "Lifecycle drag did not resize"
    a.amount=177;a.markInputDirty()
    local epoch=r.procEpoch,key=r.procInputKey()
    G074Mouse grip "OnMouseDown" 4
    select P07Source
    P07Assert (page.dragList==undefined and page.dragGrip==undefined) "Closing main view retained drag"
    select node;modPanel.setCurrentObject r
    if not r.mainUI.controlsReady do r.mainUI.mountTimer.tick()
    P07Assert (r.modelsUI.sourceUI_plantList.height==resized) "Dragged height was not restored"
    CyrusOpenLayerEditor r a
    local popup=undefined
    for candidate in CyrusLayerEditor.activeEditors() where isProperty candidate #sourceUI_plantList_grip do popup=candidate
    P07Assert (popup!=undefined) "Popup model page missing"
    G074Mouse popup.sourceUI_plantList_grip "OnMouseDown" 4
    P07Assert (popup.dragList!=undefined) "Popup drag did not begin"
    CyrusCloseLayerEditor()
    P07Assert (popup.dragList==undefined and popup.dragGrip==undefined) "Closing popup retained drag"
    P07Assert (r.procEpoch==epoch and r.procInputKey()==key) "Lifecycle published pending Manual edits"
    (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"grips-lifecycle.txt") "PASS: close while dragging in main/popup; actual dragged height restored after reselection; pending Manual edits retained."
    true
)
