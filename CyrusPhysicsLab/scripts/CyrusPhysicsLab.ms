-- Independent laboratory class. Does not reference or modify CyrusScatter.
global CyrusPhysicsLab
plugin simpleObject CyrusPhysicsLab
name:"Cyrus Physics Lab" classID:#(0x6de730c2,0x24af591c) category:"Cyrus Labs"
(
    parameters data
    (
        physicsDocument type:#maxObject
        sourceNodes type:#nodeTab tabSize:0 tabSizeVariable:true
        receiverNode type:#node
        colliderNodes type:#nodeTab tabSize:0 tabSizeVariable:true
        brushRadius type:#float default:0.25
        birthSpacing type:#float default:0.08
        emissionHeight type:#float default:0.4
        friction type:#float default:0.6
        bounce type:#float default:0.05
        scaleMinimum type:#float default:0.8
        scaleMaximum type:#float default:1.2
        randomSeed type:#integer default:42
        bodyLimit type:#integer default:1000
        proxyThickness type:#float default:0.002
        areaBoundary type:#node
        areaCount type:#integer default:100
        receiverCollision type:#boolean default:true
        stickiness type:#float default:0
        showCollisionShapes type:#boolean default:false
        showViewportIcon type:#boolean default:true
        viewportIconSize type:#float default:0.25
    )
    fn ensureDocument =
    (
        if physicsDocument==undefined do physicsDocument=cplCreate()
        physicsDocument
    )
    fn configure =
    (
        cplReceiverCollision (ensureDocument()) receiverCollision
        cplConfigure (ensureDocument()) brushRadius birthSpacing emissionHeight friction bounce scaleMinimum scaleMaximum randomSeed bodyLimit proxyThickness
        cplSetGrip (ensureDocument()) (stickiness/100.)
    )
    fn ownerNode = (refs.dependentNodes this firstOnly:true)
    fn applyCollisionDisplay = (local owner=ownerNode();if isValidNode owner do cplSetCollisionDisplay (ensureDocument()) owner showCollisionShapes;true)
    fn applyViewportIcon = (local owner=ownerNode();if isValidNode owner do cplSetViewportIcon (ensureDocument()) owner showViewportIcon viewportIconSize;true)
    fn logEvent event message:"" = (try(cplLogEvent (ensureDocument()) event message)catch();true)
    fn stopBrush = (logEvent "ui.stop.enter";if physicsDocument!=undefined do cplStop physicsDocument;logEvent "ui.stop.exit";true)
    fn startBrush =
    (
        logEvent "ui.start.enter"
        if not (cplUIState (ensureDocument()))[2] do (configure();this.rebuildMaterial())
        applyCollisionDisplay()
        applyViewportIcon()
        cplBegin physicsDocument (ownerNode())
        logEvent "ui.start.exit"
        true
    )
    fn addSource node proxy:undefined =
    (
        if not isValidNode node do throw "Choose a valid source mesh."
        if findItem sourceNodes node>0 do throw "Source already bound."
        undo "Physics add model" on
        (
            cplBindSource (ensureDocument()) node proxy
            append sourceNodes node
            this.rebuildMaterial()
        )
        true
    )
    fn removeSource slot =
    (
        if slot<1 or slot>sourceNodes.count do throw "Select a model to remove."
        undo "Physics remove model" on (cplRemoveSource (ensureDocument()) slot;deleteItem sourceNodes slot)
        true
    )
    fn replaceSource slot node =
    (
        undo "Physics replace model" on (cplReplaceSource (ensureDocument()) slot node;sourceNodes[slot]=node;this.rebuildMaterial())
        true
    )
    fn setReceiver node =
    (
        cplBindReceiver (ensureDocument()) node
        receiverNode=node
        true
    )
    fn addCollider node =
    (
        undo "Physics add collider" on (cplBindCollider (ensureDocument()) node;append colliderNodes node)
        true
    )
    fn settleArea =
    (
        stopBrush()
        configure()
        local polygon=#()
        if isValidNode areaBoundary do
        (
            if (numSplines areaBoundary)!=1 or not (isClosed areaBoundary 1) do throw "Area boundary must be one closed spline."
            for i=1 to numKnots areaBoundary 1 do
            (
                if getKnotType areaBoundary 1 i!=#corner do throw "Use a polygon boundary with corner knots for this test object."
                append polygon ((in coordsys local (getKnotPoint areaBoundary 1 i))*areaBoundary.objectTransform)
            )
        )
        cplArea physicsDocument (ownerNode()) polygon areaCount
    )
    local uiError=""
    fn uiWidth panel =
    (
        local result=amax 96 panel.width
        if panel!=undefined and panel.isDisplayed do result=amax 96 (windows.getWindowPos panel.hwnd removeUIScaling:true).w
        result
    )
    fn fitWidth item widthValue =
    (
        local wanted=amax 1 (widthValue as integer)
        if classOf item==SpinnerControl then
        (
            local arrow=windows.getWindowPos item.hwnd[1],fieldWidth=amax 14 (wanted-12)
            for handle in item.hwnd where (windows.getHWNDData handle)[4]=="CustEdit" do
            (
                local rectangle=windows.getWindowPos handle,data=windows.getHWNDData handle
                local position=windows.screenToClient data[2] (arrow.x-fieldWidth) arrow.y
                windows.setWindowPos handle position.x position.y fieldWidth rectangle.h true
            )
        )
        else if isProperty item #width then (if item.width!=wanted do item.width=wanted)
        else for handle in item.hwnd where handle!=0 do
        (
            local rectangle=windows.getWindowPos handle,data=windows.getHWNDData handle
            if rectangle.w!=wanted do
            (
                local point=windows.screenToClient data[2] rectangle.x rectangle.y
                windows.setWindowPos handle point.x point.y wanted rectangle.h true
            )
        )
        true
    )
    fn place item x y w h =
    (
        local position=if classOf item==SpinnerControl then [x+w-12,y] else [x,y]
        if item.pos!=position do item.pos=position
        fitWidth item w
        -- Dropdown height includes its popup, rather than only the collapsed row.
        if classOf item!=DropdownListControl and isProperty item #height do if item.height!=h do item.height=h
        true
    )
    fn fitPage page logicalHeight = (local pixels=ceil (logicalHeight*GetUIScaleFactor());if page.height!=pixels do page.height=pixels;true)
    fn fieldRow caption field y w =
    (
        if w<150 then (place caption 8 y (w-16) 16;place field 8 (y+19) (w-16) 18)
        else (place caption 8 (y+2) (w-98) 16;place field (w-86) y 78 18)
    )
    fn shortName node =
    (
        if not isValidNode node then "None selected"
        else if node.name.count>24 then (substring node.name 1 21)+"..." else node.name
    )
    fn wrapStatus message columns =
    (
        local result="",line=""
        for paragraph in filterString message "\n" do
        (
            for word in filterString paragraph " " do
            (
                if line.count>0 and line.count+word.count+1>columns do (result+=line+"\n";line="")
                line+=(if line=="" then "" else " ")+word
            )
            result+=line+"\n";line=""
        )
        trimRight result "\n"
    )
    fn rebuildMaterial =
    (
        local node=ownerNode()
        if isValidNode node do
        (
            local old=node.material,count=cplSourceSlotCount (ensureDocument())
            if classOf old==MultiMaterial do count=amax count old.numsubs
            local materials=multiMaterial numsubs:(amax 1 count)
            if classOf old==MultiMaterial do for i=1 to old.numsubs do materials.materialList[i]=old.materialList[i]
            for i=1 to sourceNodes.count where isValidNode sourceNodes[i] do
            (
                local source=sourceNodes[i],slot=cplSourceIndex physicsDocument i,assigned=source.material
                if assigned==undefined do
                (
                    local previous=materials.materialList[slot],fallbackName="Physics colour: "+source.name
                    if classOf previous==StandardMaterial and previous.name==fallbackName and previous.diffuse==source.wirecolor then assigned=previous
                    else assigned=standardMaterial name:fallbackName diffuse:source.wirecolor
                )
                materials.materialList[slot]=assigned
            )
            node.material=materials
        )
    )
    fn enableControl item value = (if item.enabled!=value do item.enabled=value)
    fn syncUI =
    (
        local state=if physicsDocument==undefined then #(false,false,false,false,0L,0L,"",false,0,0,false,false,0,0,0,0,false,false,"") else cplUIState physicsDocument
        local ready=isValidNode receiverNode and sourceNodes.count>0,enabledModels=0
        for i=1 to sourceNodes.count do if (cplSourceOptions (ensureDocument()) i)[1] do enabledModels+=1
        if enabledModels==0 do ready=false
        for node in sourceNodes where not isValidNode node do ready=false
        if this.objectsUI.isDisplayed and this.objectsUI.controlsReady do
        (
            local caption="Models ("+(enabledModels as string)+"/"+(sourceNodes.count as string)+")"
            if this.objectsUI.sourceCaption.text!=caption do this.objectsUI.sourceCaption.text=caption
        )
        local editable=not state[1] and not state[2],message=""
        if uiError!="" then message=uiError
        else if state[7]!="" then message=state[7]
        else if not isValidNode receiverNode then message="Pick a receiver in Objects.\nAdd the models you want to spray."
        else if not ready then message="Check at least one valid model in Objects.\nThen start the brush."
        else if state[2] then
        (
            if state[8] then message="Paused. Resume, Finish or Freeze."
            else if state[3] then message="Finishing all pending strokes..."
            else message="Brush live. Keep drawing while objects move."
            message+="\n"+(state[6] as string)+" pending / "+(state[13] as string)+" moving"
            if state[14]>0 do message+="\n"+(state[14] as string)+" fell beyond the scene"
            if state[16]>0 do message+="\n"+(state[16] as string)+" blocked births skipped. Keep brushing."
        )
        else message="Ready. Drag on the receiver."
        message+="\n"+((state[5] as integer) as string)+" retained bodies / "+((cplColliderNodes (ensureDocument())).count as string)+" colliders"
        local panel=this.brushHeader
        if panel!=undefined and panel.isDisplayed do
        (
            panel.startButton.text=if state[2] then "Resume" else "Start brush"
            enableControl panel.startButton (ready and not state[1] and (not state[2] or state[8]))
            enableControl panel.stopButton (state[1] or (state[2] and not state[8]))
            enableControl panel.finishButton state[2]
            enableControl panel.keepButton state[2]
            enableControl panel.undoButton (state[9]>0)
            enableControl panel.redoButton (state[10]>0)
            enableControl panel.cancelButton state[2]
            local text=wrapStatus message (amax 12 (((uiWidth panel)-16)/6) as integer)
            if panel.statusLabel.text!=text do (panel.statusLabel.tooltip=message;panel.statusLabel.text=text;panel.layout())
        )
        for page in #(this.objectsUI,this.brushUI,this.collisionUI,this.areaUI,this.resultUI) where page!=undefined and page.isDisplayed and page.controlsReady do page.setEditable editable
        if this.collisionUI.isDisplayed and this.collisionUI.controlsReady do this.collisionUI.syncDisplay state
        true
    )
    fn showError message = (logEvent "ui.error" message:message;message=substituteString message "-- Runtime error: " "";uiError=message;local panel=this.brushHeader;if panel!=undefined and panel.isDisplayed do (panel.statusLabel.text=wrapStatus message (amax 12 (((uiWidth panel)-16)/6) as integer);panel.statusLabel.tooltip=message;panel.layout());false)
    fn refreshBindings =
    (
        for page in #(this.objectsUI,this.brushUI,this.collisionUI,this.areaUI,this.viewportUI) where page!=undefined and page.isDisplayed and page.controlsReady do page.bindFields()
        syncUI()
    )
    rollout brushHeader "Cyrus Physics 0.2.1" width:#cmdPanel height:282 autoLayoutOnResize:false
    (
        local root=undefined,resizing=false,controlsReady=false,lastLayoutWidth=0,lastDiagnostics=0
        label titleLabel "Continuous physics brush" pos:[8,6] width:160 height:16
        button startButton "Start brush" enabled:false tooltip:"Draw several strokes while earlier bodies continue moving."
        button stopButton "Pause" enabled:false tooltip:"Pause simulation and leave the brush. Pending bodies and stroke history are retained."
        button finishButton "Finish" enabled:false tooltip:"Settle and bake this session to one Editable Poly static collider. Later quality changes affect new strokes. One Max Undo removes the batch."
        button keepButton "Freeze" enabled:false tooltip:"Bake current positions to an Editable Poly collider immediately, including any unfinished overlaps."
        button undoButton "Undo stroke" enabled:false tooltip:"Pause and restore the whole world to before the last stroke, including bodies it moved."
        button redoButton "Redo stroke" enabled:false tooltip:"Restore the full world state captured by Undo."
        button cancelButton "Cancel session" enabled:false tooltip:"Discard all pending strokes. Previously saved bodies remain."
        label statusLabel "Pick a receiver and add a model." width:160 height:64
        button logsButton "Open logs" tooltip:"Crash diagnostics and the last durable session recovery are recorded automatically."
        timer updateTimer interval:40 active:false
        fn layout =
        (
            if resizing do return false
            resizing=true
            local w=root.uiWidth root.brushHeader,half=((w-24)/2) as integer,narrow=w<170,y=28
            root.place titleLabel 8 6 (w-16) 16
            titleLabel.text=if narrow then "Physics brush" else "Continuous physics brush"
            for pair in #(#(startButton,stopButton),#(finishButton,keepButton),#(undoButton,redoButton)) do
            (
                if narrow then (root.place pair[1] 8 y (w-16) 24;root.place pair[2] 8 (y+28) (w-16) 24;y+=56)
                else (root.place pair[1] 8 y half 24;root.place pair[2] (16+half) y (w-24-half) 24;y+=28)
            )
            root.place cancelButton 8 (y+4) (w-16) 22;y+=34
            local lines=(filterString statusLabel.text "\n").count,h=amax 64 (lines*16)
            root.place statusLabel 8 y (w-16) h;y+=h+8
            root.place logsButton 8 y (w-16) 22
            root.fitPage root.brushHeader (y+30);lastLayoutWidth=w;resizing=false;true
        )
        fn act operation = (local model=root;if model!=undefined do try(model.uiError="";operation model;model.syncUI();redrawViews())catch(model.showError (getCurrentException())))
        fn doStart model = model.startBrush()
        fn doPause model = cplPause (model.ensureDocument())
        fn doFinish model = (model.rebuildMaterial();cplFinishBake (model.ensureDocument()) (model.ownerNode()) false)
        fn doFreeze model = (model.rebuildMaterial();cplFinishBake (model.ensureDocument()) (model.ownerNode()) true)
        fn doUndo model = cplUndoStroke (model.ensureDocument())
        fn doRedo model = cplRedoStroke (model.ensureDocument())
        fn doCancel model = model.stopBrush()
        on startButton pressed do act doStart
        on stopButton pressed do act doPause
        on finishButton pressed do act doFinish
        on keepButton pressed do act doFreeze
        on undoButton pressed do act doUndo
        on redoButton pressed do act doRedo
        on cancelButton pressed do act doCancel
        on logsButton pressed do (local model=root;if model!=undefined do try(model.logEvent "ui.logs.open";shellLaunch (cplDiagnosticPath()) "")catch(model.showError (getCurrentException())))
        on updateTimer tick do
        (
            local model=root
            if model!=undefined and controlsReady do try
            (
                if model.physicsDocument!=undefined and cplBusy model.physicsDocument do
                (
                    if timeStamp()-lastDiagnostics>=1000 do (model.logEvent "ui.live.heartbeat";lastDiagnostics=timeStamp())
                    cplTick model.physicsDocument 2;redrawViews()
                )
                model.syncUI()
            )catch(model.showError (getCurrentException()))
        )
        on brushHeader open do try(root=this;controlsReady=true;layout();updateTimer.active=true)catch(controlsReady=false;root.showError (getCurrentException()))
        on brushHeader resized size do if controlsReady and not resizing do try(layout();root.syncUI())catch(root.showError (getCurrentException()))
        on brushHeader close do (controlsReady=false;updateTimer.active=false;local model=root;root=undefined;if model!=undefined and model.physicsDocument!=undefined do try(cplPause model.physicsDocument)catch())
    )
    rollout objectsUI "Objects" width:#cmdPanel height:370 autoLayoutOnResize:false
    (
        local root=undefined,binding=false,controlsReady=false,lastLayoutWidth=0,pressedCheckIndex=-1,lastSelectedIndex=-1
        label receiverCaption "Receiver" pos:[8,6] width:160 height:16
        pickbutton receiverPick "Pick receiver..." pos:[8,26] width:160 height:22 autoDisplay:false
        label receiverName "None selected" pos:[8,52] width:160 height:16
        checkbox receiverCollisionCheck "Receiver collides" pos:[8,73] width:160 tooltip:"The receiver is both the brush target and a static collider."
        label sourceCaption "Models" pos:[8,100] width:160 height:16
        dotNetControl sourceList "System.Windows.Forms.CheckedListBox" pos:[8,120] width:160 height:110
        label listHint "Tick to spray. Row to edit." pos:[8,236] width:160 height:16
        pickbutton sourcePick "+" pos:[8,258] width:24 height:22 autoDisplay:false tooltip:"Add a model to this brush."
        button removeSourceButton "x" pos:[36,258] width:24 height:22 tooltip:"Remove the highlighted model from future strokes. Existing scattered bodies and the scene model are kept. Undo restores its binding."
        pickbutton replaceSourcePick "Replace..." pos:[64,258] width:104 height:22 autoDisplay:false tooltip:"Replace the highlighted model. Rebuild applies changed geometry to saved strokes."
        pickbutton colliderPick "Add collider..." pos:[8,320] width:160 height:22 autoDisplay:false
        label colliderInfo "0 additional colliders" pos:[8,347] width:160 height:16
        fn selectedSlot = (if sourceList.SelectedIndex<0 then 0 else sourceList.SelectedIndex+1)
        fn setChecked values = (cplSetEnabledSources (root.ensureDocument()) values;root.uiError="";root.refreshBindings())
        -- CheckedListBox itself toggles a selected row on repeated clicks, including
        -- blank-space notifications. Reject those toggles; only a glyph press/release
        -- pair issues the explicit authored command below.
        fn checkboxAt x y =
        (
            local index=sourceList.IndexFromPoint x y
            if index<0 do return -1
            local rectangle=sourceList.GetItemRectangle index,graphics=sourceList.CreateGraphics()
            local size=(dotNetClass "System.Windows.Forms.CheckBoxRenderer").GetGlyphSize graphics (dotNetClass "System.Windows.Forms.VisualStyles.CheckBoxState").UncheckedNormal
            graphics.Dispose()
            local inset=amax 0 ((rectangle.Height-size.Height)/2) as integer
            local left=rectangle.X+1,top=rectangle.Y+inset
            if x>=left and x<left+size.Width and y>=top and y<top+size.Height then index else -1
        )
        fn checkPointerDown x y = (pressedCheckIndex=checkboxAt x y)
        fn checkPointerUp x y =
        (
            local index=checkboxAt x y,pressed=pressedCheckIndex
            pressedCheckIndex=-1
            if index<0 or pressed!=index or binding or root==undefined do return false
            local model=root,values=for i=1 to model.sourceNodes.count collect (cplSourceOptions model.physicsDocument i)[1]
            values[index+1]=not values[index+1]
            try(cplSetEnabledSources model.physicsDocument values;model.uiError="";model.refreshBindings();true)catch(model.showError (getCurrentException()))
        )
        fn layout =
        (
            local w=root.uiWidth root.objectsUI,half=((w-24)/2) as integer,narrow=w<150,y=258
            -- Native labels also need their positions reapplied after UI-scale
            -- changes; otherwise the managed list moves but its hint stays behind.
            for entry in #(#(receiverCaption,6,16),#(receiverPick,26,22),#(receiverName,52,16),#(receiverCollisionCheck,73,18),#(sourceCaption,100,16),#(listHint,236,16)) do root.place entry[1] 8 entry[2] (w-16) entry[3]
            sourceList.pos=[8,120];sourceList.width=w-16;sourceList.height=110
            receiverPick.text=if narrow then "Pick..." else "Pick receiver..."
            receiverCollisionCheck.text=if narrow then "Collides" else "Receiver collides"
            listHint.text=if narrow then "Tick to spray" else "Tick to spray. Row to edit."
            root.place sourcePick 8 y 24 22;root.place removeSourceButton 36 y 24 22
            if w<145 then (y+=28;root.place replaceSourcePick 8 y (w-16) 22) else root.place replaceSourcePick 66 y (w-74) 22
            y+=34
            root.place colliderPick 8 y (w-16) 22;y+=27;root.place colliderInfo 8 y (w-16) 16
            colliderInfo.text=((cplColliderNodes (root.ensureDocument())).count as string)+(if narrow then " colliders" else " additional colliders")
            lastLayoutWidth=w;root.fitPage root.objectsUI (y+24)
        )
        fn bindFields =
        (
            binding=true
            receiverName.text=root.shortName root.receiverNode;receiverName.tooltip=if isValidNode root.receiverNode then root.receiverNode.name else "Pick a receiving mesh."
            receiverCollisionCheck.checked=root.receiverCollision
            local previous=sourceList.SelectedIndex,active=0
            sourceList.BeginUpdate();sourceList.Items.Clear()
            for i=1 to root.sourceNodes.count do
            (
                local node=root.sourceNodes[i],options=cplSourceOptions (root.ensureDocument()) i
                sourceList.Items.Add (if isValidNode node then node.name else "<missing model>") options[1]
                if options[1] do active+=1
            )
            if root.sourceNodes.count>0 do sourceList.SelectedIndex=amax 0 (amin previous (root.sourceNodes.count-1))
            sourceList.EndUpdate()
            sourceCaption.text="Models ("+(active as string)+"/"+(root.sourceNodes.count as string)+")"
            colliderInfo.tooltip="Static scene colliders; receiver collision is independent."
            binding=false;layout()
        )
        fn setEditable value = (for item in #(receiverPick,receiverCollisionCheck,sourcePick,colliderPick) do root.enableControl item value;for item in #(replaceSourcePick,removeSourceButton) do root.enableControl item (value and selectedSlot()>0))
        on receiverPick picked node do (local model=root;if model!=undefined do try(model.uiError="";model.setReceiver node;model.refreshBindings())catch(model.showError (getCurrentException())))
        on receiverCollisionCheck changed value do if not binding do (root.receiverCollision=value;root.uiError="";root.syncUI())
        on sourcePick picked node do (local model=root;if model!=undefined do try(model.uiError="";model.addSource node;model.refreshBindings())catch(model.showError (getCurrentException())))
        on sourceList SelectedIndexChanged sender args do if not binding and root!=undefined do
        (
            if sourceList.SelectedIndex<0 and lastSelectedIndex>=0 and lastSelectedIndex<sourceList.Items.Count then sourceList.SelectedIndex=lastSelectedIndex
            else (lastSelectedIndex=sourceList.SelectedIndex;if root.collisionUI.isDisplayed and root.collisionUI.controlsReady do root.collisionUI.bindFields())
        )
        on sourceList ItemCheck sender args do if not binding do args.NewValue=args.CurrentValue
        on sourceList MouseDown sender args do if args.Button==(dotNetClass "System.Windows.Forms.MouseButtons").Left do checkPointerDown args.X args.Y
        on sourceList MouseUp sender args do if args.Button==(dotNetClass "System.Windows.Forms.MouseButtons").Left do checkPointerUp args.X args.Y
        on sourceList MouseLeave sender args do pressedCheckIndex=-1
        on removeSourceButton pressed do (local model=root,slot=selectedSlot();if model!=undefined do try(model.uiError="";model.removeSource slot;model.refreshBindings())catch(model.showError (getCurrentException())))
        on replaceSourcePick picked node do
        (
            local model=root,slot=selectedSlot()
            if model!=undefined do try(model.uiError="";model.replaceSource slot node;model.refreshBindings())catch(model.showError (getCurrentException()))
        )
        on colliderPick picked node do (local model=root;if model!=undefined do try(model.uiError="";model.addCollider node;model.refreshBindings())catch(model.showError (getCurrentException())))
        on objectsUI open do try
        (
            root=this;controlsReady=true
            sourceList.CheckOnClick=false;sourceList.IntegralHeight=false;sourceList.HorizontalScrollbar=true
            sourceList.BackColor=(dotNetClass "System.Drawing.Color").FromArgb 58 58 58
            sourceList.ForeColor=(dotNetClass "System.Drawing.Color").FromArgb 225 225 225
            sourceList.BorderStyle=(dotNetClass "System.Windows.Forms.BorderStyle").FixedSingle
            bindFields()
        )catch(controlsReady=false;root.showError (getCurrentException()))
        on objectsUI resized size do if controlsReady and root!=undefined and (root.uiWidth root.objectsUI)!=lastLayoutWidth do try(layout())catch(root.showError (getCurrentException()))
        on objectsUI close do (controlsReady=false;root=undefined)
    )
    rollout brushUI "Brush" width:#cmdPanel height:216 autoLayoutOnResize:false
    (
        local root=undefined,binding=false,controlsReady=false,lastLayoutWidth=0
        label unitsLabel "Distances are in metres" pos:[8,6] width:160 height:16
        label radiusLabel "Radius (m)";spinner radiusSpin "" range:[0.001,100,0.25] type:#float scale:.01
        label spacingLabel "Spacing (m)";spinner spacingSpin "" range:[0.0001,100,0.08] type:#float scale:.01 tooltip:"Distance between births along the stroke. Holding still adds none."
        label heightLabel "Height (m)";spinner heightSpin "" range:[0,100,0.4] type:#float scale:.01 tooltip:"Drop height above the receiving surface."
        label scaleMinLabel "Min scale";spinner scaleMinSpin "" range:[0.01,100,0.8] type:#float scale:.05
        label scaleMaxLabel "Max scale";spinner scaleMaxSpin "" range:[0.01,100,1.2] type:#float scale:.05
        label seedLabel "Seed";spinner seedSpin "" range:[1,2147483647,42] type:#integer
        label limitLabel "Body limit";spinner limitSpin "" range:[1,5000,1000] type:#integer tooltip:"Admission limit for saved and pending bodies together."
        fn layout =
        (
            local w=root.uiWidth root.brushUI
            local narrow=w<150,step=if narrow then 43 else 25
            unitsLabel.text=if narrow then "Distances: metres" else "Distances are in metres"
            root.fitWidth unitsLabel (w-16)
            local labels=#(radiusLabel,spacingLabel,heightLabel,scaleMinLabel,scaleMaxLabel,seedLabel,limitLabel),fields=#(radiusSpin,spacingSpin,heightSpin,scaleMinSpin,scaleMaxSpin,seedSpin,limitSpin)
            for i=1 to fields.count do root.fieldRow labels[i] fields[i] (30+(i-1)*step) w
            lastLayoutWidth=w;root.fitPage root.brushUI (if narrow then 330 else 206)
        )
        fn bindFields = (binding=true;radiusSpin.value=root.brushRadius;spacingSpin.value=root.birthSpacing;heightSpin.value=root.emissionHeight;scaleMinSpin.value=root.scaleMinimum;scaleMaxSpin.value=root.scaleMaximum;seedSpin.value=root.randomSeed;limitSpin.value=root.bodyLimit;binding=false;layout())
        fn setEditable value = (for item in #(radiusSpin,spacingSpin,heightSpin,scaleMinSpin,scaleMaxSpin,seedSpin,limitSpin) do root.enableControl item value)
        on radiusSpin changed value do if not binding do root.brushRadius=value
        on spacingSpin changed value do if not binding do root.birthSpacing=value
        on heightSpin changed value do if not binding do root.emissionHeight=value
        on scaleMinSpin changed value do if not binding do root.scaleMinimum=value
        on scaleMaxSpin changed value do if not binding do root.scaleMaximum=value
        on seedSpin changed value do if not binding do root.randomSeed=value
        on limitSpin changed value do if not binding do root.bodyLimit=value
        on brushUI open do try(root=this;controlsReady=true;bindFields())catch(controlsReady=false;root.showError (getCurrentException()))
        on brushUI resized size do if controlsReady and root!=undefined and (root.uiWidth root.brushUI)!=lastLayoutWidth do try(layout())catch(root.showError (getCurrentException()))
        on brushUI close do (controlsReady=false;root=undefined)
    )
    rollout collisionUI "Collision and proxies" width:#cmdPanel height:174 rolledUp:true autoLayoutOnResize:false
    (
        local root=undefined,binding=false,controlsReady=false,lastLayoutWidth=0
        label modelLabel "Model: none" pos:[8,6] width:160 height:32
        label proxyLabel "Shape: automatic" pos:[8,42] width:160 height:32
        label qualityLabel "Collision quality" pos:[8,80] width:160 height:16
        dropdownlist qualityList "" items:#("Fast","Balanced","Detailed") pos:[8,100] width:160 height:4 tooltip:"Fast uses one hull. Balanced and Detailed can use several convex pieces. Already convex solids keep one hull. All modes approximate the model."
        label piecesLabel "Max pieces";spinner piecesSpin "" range:[1,16,16] type:#integer tooltip:"Maximum convex pieces for this model. More pieces can preserve openings but cost more to simulate."
        label errorLabel "Volume error (%)";spinner errorSpin "" range:[0.1,10,1] type:#float scale:.1 tooltip:"V-HACD voxel/hull volume error target. Lower can improve decomposition. This is not a distance tolerance or exact-fit guarantee."
        label qualityInfo "Prepare on Start" width:160 height:32
        pickbutton proxyPick "Pick proxy..." pos:[8,80] width:160 height:22 autoDisplay:false tooltip:"Optional simplified copy of the selected moving model, with matching size and pivot. At most 128 vertices. Do not pick the receiving surface. Add static colliders in Objects."
        button autoProxyButton "Use auto" pos:[8,108] width:160 height:22 enabled:false tooltip:"Build the collision shape from the selected model. Removes its custom proxy without changing the render mesh."
        checkbox showCollisionCheck "Show collision shapes" pos:[8,140] width:160 height:22 tooltip:"Inspect the actual cooked model proxies (cyan) and static collision surfaces (amber) in the active viewport. This only changes viewport wires; it stays available while brushing or paused."
        label displayLegend "Cyan: models\nAmber: surfaces" pos:[8,168] width:160 height:32
        label thicknessLabel "Thickness";spinner thicknessSpin "" range:[0.00001,1,0.002] type:#float scale:.001 tooltip:"Minimum automatic proxy thickness in metres. The render mesh stays unchanged."
        label frictionLabel "Friction";spinner frictionSpin "" range:[0,2,.6] type:#float scale:.05 tooltip:"Resistance to sliding at contacts. Zero permits free sliding, including off receiver edges. Use Stickiness for extra rolling resistance."
        label bounceLabel "Bounce";spinner bounceSpin "" range:[0,1,.05] type:#float scale:.01
        label gripLabel "Stickiness (%)";spinner gripSpin "" range:[0,100,0] type:#float scale:1 tooltip:"Extra surface grip against sliding and rolling on supported slopes. 0 is off. Bodies remain dynamic; this does not glue them to walls."
        fn customProxy = (if root.sourceNodes.count>0 and root.physicsDocument!=undefined and (root.objectsUI.selectedSlot())>0 then cplCustomProxy root.physicsDocument (root.objectsUI.selectedSlot()) else false)
        fn layout =
        (
            local w=root.uiWidth root.collisionUI,narrow=w<190,step=if narrow then 43 else 30
            local slot=(root.objectsUI.selectedSlot()),model=undefined,proxy=undefined
            local columns=amax 4 (((w-16)/8) as integer)
            fn fittedName node count = (local value=if isValidNode node then node.name else "None";if value.count>count then (substring value 1 (count-3))+"..." else value)
            if slot>0 and slot<=root.sourceNodes.count do (model=root.sourceNodes[slot];proxy=cplProxyNode root.physicsDocument slot)
            modelLabel.text="Model:\n"+(fittedName model columns)
            modelLabel.tooltip=if isValidNode model then "Moving model: "+model.name else "Add a model in Objects."
            proxyLabel.text=if isValidNode proxy then (if narrow then "Proxy:\n" else "Custom proxy:\n")+(fittedName proxy columns) else (if narrow then "Shape:\nAutomatic" else "Shape: automatic\nFrom selected model")
            proxyLabel.tooltip=if isValidNode proxy then "Collision shape for this model: "+proxy.name+". Its size and pivot must match the model." else "The collision shape is built from the model. The receiver is a separate static surface."
            root.fitWidth modelLabel (w-16);root.fitWidth proxyLabel (w-16)
            qualityLabel.text=if w<150 then "Quality" else "Collision quality";errorLabel.text=if w<150 then "Error (%)" else "Volume error (%)"
            root.place qualityLabel 8 80 (w-16) 16;root.place qualityList 8 100 (w-16) 24
            -- Max's width setter can reset the ComboBox popup to its closed height.
            -- Recompute capacity from the actual native font after every layout.
            for handle in qualityList.hwnd where handle!=0 and (windows.getHWNDData handle)[4]=="ComboBox" do
            (
                local itemHeight=amax 1 (windows.sendMessage handle 0x0154 0 0)
                qualityList.height=qualityList.items.count*itemHeight+8
            )
            local y=132
            for pair in #(#(piecesLabel,piecesSpin),#(errorLabel,errorSpin)) do (if narrow then (root.place pair[1] 8 y (w-16) 16;root.place pair[2] 8 (y+19) (w-16) 18) else root.fieldRow pair[1] pair[2] y w;y+=step)
            root.place qualityInfo 8 y (w-16) 32;y+=40
            root.place proxyPick 8 y (w-16) 22;y+=28;root.place autoProxyButton 8 y (w-16) 22;y+=32
            showCollisionCheck.text=if w<190 then "Show shapes" else "Show collision shapes"
            root.place showCollisionCheck 8 y (w-16) 22;y+=28;root.place displayLegend 8 y (w-16) 32;y+=42
            for pair in #(#(thicknessLabel,thicknessSpin),#(frictionLabel,frictionSpin),#(bounceLabel,bounceSpin),#(gripLabel,gripSpin)) do
            (
                if narrow then (root.place pair[1] 8 y (w-16) 16;root.place pair[2] 8 (y+19) (w-16) 18)
                else root.fieldRow pair[1] pair[2] y w
                y+=step
            )
            lastLayoutWidth=w;root.fitPage root.collisionUI (y+6)
        )
        fn syncDisplay state =
        (
            local text=if (root.uiWidth root.collisionUI)<150 then "Cyan: model\nAmber: scene" else "Cyan: models\nAmber: surfaces"
            if root.showCollisionShapes do (if state[19]!="" then text="Display error\nSee logs" else if state[17] then text="Display limited\nSee logs" else if not state[18] do text="Start brush\nto prepare")
            if displayLegend.text!=text do displayLegend.text=text
            displayLegend.tooltip=if state[19]!="" then state[19] else "Cyan: moving models and completed blockers. Amber: the captured static colliders. A limited display shows only part of the collision wires; physics is unchanged."
        )
        fn bindFields =
        (
            binding=true;thicknessSpin.value=root.proxyThickness;frictionSpin.value=root.friction;bounceSpin.value=root.bounce;gripSpin.value=root.stickiness;showCollisionCheck.checked=root.showCollisionShapes
            local slot=root.objectsUI.selectedSlot()
            if slot>0 then
            (
                local options=cplSourceOptions (root.ensureDocument()) slot
                qualityList.selection=options[2]+1;piecesSpin.value=options[3];errorSpin.value=options[4]
                qualityInfo.text=if customProxy() then "Custom convex hull" else if options[5]>0 then "Cached: "+(options[5] as string)+" pieces" else "Prepare on Start"
                qualityInfo.tooltip="Quality changes apply on Start for an empty result, or explicit Rebuild. Cached means the last preparation, which may precede edited options."
            )
            else (qualityList.selection=1;piecesSpin.value=16;errorSpin.value=1;qualityInfo.text="Add a model in Objects")
            binding=false;root.applyCollisionDisplay();layout()
        )
        fn setEditable value =
        (
            for item in #(proxyPick,thicknessSpin,frictionSpin,bounceSpin,gripSpin) do root.enableControl item value
            local automatic=value and root.sourceNodes.count>0 and not customProxy()
            root.enableControl qualityList automatic;root.enableControl piecesSpin (automatic and qualityList.selection>1);root.enableControl errorSpin (automatic and qualityList.selection>1)
            root.enableControl proxyPick (value and root.sourceNodes.count>0);root.enableControl autoProxyButton (value and customProxy())
        )
        fn changeQuality = (local model=root;if model!=undefined do try(model.uiError="";cplSetSourceOptions (model.ensureDocument()) (model.objectsUI.selectedSlot()) (qualityList.selection-1) piecesSpin.value errorSpin.value;model.refreshBindings())catch(model.showError (getCurrentException())))
        fn selectQuality item = (binding=true;qualityList.selection=item;piecesSpin.value=if item==2 then 8 else 16;binding=false;changeQuality())
        on qualityList selected item do if not binding do selectQuality item
        on piecesSpin changed value do if not binding do changeQuality()
        on errorSpin changed value do if not binding do changeQuality()
        on proxyPick picked node do (local model=root;if model!=undefined do try(model.uiError="";cplSetProxy (model.ensureDocument()) (model.objectsUI.selectedSlot()) node;model.refreshBindings())catch(model.showError (getCurrentException())))
        on autoProxyButton pressed do (local model=root;if model!=undefined do try(model.uiError="";cplAutoProxy (model.ensureDocument()) (model.objectsUI.selectedSlot());model.refreshBindings())catch(model.showError (getCurrentException())))
        on thicknessSpin changed value do if not binding do root.proxyThickness=value
        on frictionSpin changed value do if not binding do root.friction=value
        on bounceSpin changed value do if not binding do root.bounce=value
        on gripSpin changed value do if not binding do root.stickiness=value
        on showCollisionCheck changed value do if not binding do (local model=root;if model!=undefined do try(model.showCollisionShapes=value;model.applyCollisionDisplay();model.syncUI();redrawViews())catch(model.showError (getCurrentException())))
        on collisionUI open do try(root=this;controlsReady=true;bindFields())catch(controlsReady=false;root.showError (getCurrentException()))
        on collisionUI resized size do if controlsReady and root!=undefined and (root.uiWidth root.collisionUI)!=lastLayoutWidth do try(layout())catch(root.showError (getCurrentException()))
        on collisionUI close do (controlsReady=false;root=undefined)
    )
    rollout areaUI "Physics Area" width:#cmdPanel height:172 rolledUp:true autoLayoutOnResize:false
    (
        local root=undefined,binding=false,controlsReady=false,lastLayoutWidth=0
        label areaHint "Fill a receiver or a polygon.\nReplaces the saved result." pos:[8,6] width:160 height:32
        pickbutton areaPick "Pick boundary..." pos:[8,46] width:160 height:22 autoDisplay:false tooltip:"Optional closed Editable Spline with corner knots in world XY."
        label boundaryName "Whole receiver" pos:[8,74] width:160 height:16
        label countLabel "Body count";spinner areaCountSpin "" range:[1,5000,100] type:#integer
        button areaButton "Settle area" pos:[8,135] width:160 height:24
        fn layout = (local w=root.uiWidth root.areaUI,narrow=w<150;areaHint.text=if narrow then "Fill the receiver\nor a polygon.\nReplaces result." else "Fill a receiver or a polygon.\nReplaces the saved result.";root.place areaHint 8 6 (w-16) (if narrow then 48 else 32);root.place areaPick 8 (if narrow then 62 else 46) (w-16) 22;areaPick.text=if narrow then "Boundary..." else "Pick boundary...";root.place boundaryName 8 (if narrow then 90 else 74) (w-16) 16;root.fieldRow countLabel areaCountSpin (if narrow then 119 else 103) w;root.place areaButton 8 (if narrow then 165 else 135) (w-16) 24;lastLayoutWidth=w;root.fitPage root.areaUI (if narrow then 198 else 168))
        fn bindFields = (binding=true;areaCountSpin.value=root.areaCount;boundaryName.text=if isValidNode root.areaBoundary then root.shortName root.areaBoundary else "Whole receiver";boundaryName.tooltip=if isValidNode root.areaBoundary then root.areaBoundary.name else "No boundary: emit on upward receiver faces.";binding=false;layout())
        fn setEditable value = (for item in #(areaPick,areaCountSpin,areaButton) do root.enableControl item value)
        on areaPick picked node do (local model=root;if model!=undefined do (model.areaBoundary=node;bindFields()))
        on areaCountSpin changed value do if not binding do root.areaCount=value
        on areaButton pressed do (local model=root;if model!=undefined do try(model.uiError="";model.settleArea();model.syncUI())catch(model.showError (getCurrentException())))
        on areaUI open do try(root=this;controlsReady=true;bindFields())catch(controlsReady=false;root.showError (getCurrentException()))
        on areaUI resized size do if controlsReady and root!=undefined and (root.uiWidth root.areaUI)!=lastLayoutWidth do try(layout())catch(root.showError (getCurrentException()))
        on areaUI close do (controlsReady=false;root=undefined)
    )
    rollout viewportUI "Viewport" width:#cmdPanel height:112 rolledUp:false autoLayoutOnResize:false
    (
        local root=undefined,binding=false,controlsReady=false,lastLayoutWidth=0
        checkbox iconCheck "Show Lab icon" pos:[8,8] width:160 checked:true tooltip:"Draw a selectable Physics Lab marker at the node pivot, including when the Lab has no bodies. Turn off before converting the Lab to a mesh."
        label iconSizeLabel "Radius (m)";spinner iconSizeSpin "" range:[0.0001,1000,0.25] type:#float
        label iconHint "Select the icon\nto edit this Lab." pos:[8,70] width:160 height:32
        fn layout = (local w=root.uiWidth root.viewportUI,y=if w<150 then 91 else 72;root.place iconCheck 8 8 (w-16) 22;root.fieldRow iconSizeLabel iconSizeSpin 44 w;root.place iconHint 8 y (w-16) 32;lastLayoutWidth=w;root.fitPage root.viewportUI (y+40))
        fn bindFields = (binding=true;iconCheck.checked=root.showViewportIcon;iconSizeSpin.value=root.viewportIconSize;binding=false;root.applyViewportIcon();layout())
        on iconCheck changed value do if not binding do (local model=root;if model!=undefined do try(model.showViewportIcon=value;model.applyViewportIcon();redrawViews())catch(model.showError (getCurrentException())))
        on iconSizeSpin changed value do if not binding do (local model=root;if model!=undefined do try(model.viewportIconSize=value;model.applyViewportIcon();redrawViews())catch(model.showError (getCurrentException())))
        on viewportUI open do try(root=this;controlsReady=true;bindFields())catch(controlsReady=false;root.showError (getCurrentException()))
        on viewportUI resized size do if controlsReady and root!=undefined and (root.uiWidth root.viewportUI)!=lastLayoutWidth do try(layout())catch(root.showError (getCurrentException()))
        on viewportUI close do (controlsReady=false;root=undefined)
    )
    rollout resultUI "Result and files" width:#cmdPanel height:184 rolledUp:true autoLayoutOnResize:false
    (
        local root=undefined,controlsReady=false,lastLayoutWidth=0
        button eraseButton "Erase nearby..." pos:[8,8] width:160 height:22 tooltip:"Pick a centre. Remaining bodies stay fixed; Undo is available."
        button rebuildButton "Rebuild all strokes" pos:[8,38] width:160 height:22 tooltip:"Explicitly simulate authored births again with the current settings and bindings."
        button clearButton "Clear result" pos:[8,68] width:160 height:22 tooltip:"Remove all saved bodies. Undo restores them."
        button exportButton "Save..." pos:[8,102] width:78 height:22 tooltip:"Save a JSON result snapshot. Save the MAX scene for materials and live bindings."
        button importButton "Load..." pos:[94,102] width:74 height:22 tooltip:"Load a JSON snapshot. Review and rebind models/materials before new authoring."
        button recoveryButton "Recover session..." pos:[8,138] width:160 height:22 tooltip:"Load a live-recovery JSON from Open logs. Use the saved MAX scene with its bindings to Resume; Freeze also works from the cached preview."
        label fileHint "Save the MAX scene for\nmodels and materials." pos:[8,138] width:160 height:32
        fn layout = (local w=root.uiWidth root.resultUI,half=((w-24)/2) as integer,narrow=w<150;for item in #(eraseButton,rebuildButton,clearButton,recoveryButton,fileHint) do root.fitWidth item (w-16);rebuildButton.text=if narrow then "Rebuild strokes" else "Rebuild all strokes";if narrow then (root.place exportButton 8 102 (w-16) 22;root.place importButton 8 130 (w-16) 22) else (root.place exportButton 8 102 half 22;root.place importButton (16+half) 102 (w-24-half) 22);fileHint.text=if narrow then "Save MAX for\nmodels and\nmaterials." else "Save the MAX scene for\nmodels and materials.";root.place recoveryButton 8 (if narrow then 164 else 138) (w-16) 22;root.place fileHint 8 (if narrow then 194 else 168) (w-16) (if narrow then 48 else 32);lastLayoutWidth=w;root.fitPage root.resultUI (if narrow then 250 else 208))
        fn setEditable value = (for item in #(eraseButton,rebuildButton,clearButton,importButton,recoveryButton) do root.enableControl item value)
        on eraseButton pressed do (local model=root;if model!=undefined do try(model.uiError="";model.stopBrush();local centre=pickPoint prompt:"Pick erase centre.";if classOf centre==Point3 do cplErase (model.ensureDocument()) centre model.brushRadius;model.syncUI())catch(model.showError (getCurrentException())))
        on rebuildButton pressed do (local model=root;if model!=undefined do try(model.uiError="";model.stopBrush();model.configure();cplRebuild model.physicsDocument (model.ownerNode());model.syncUI())catch(model.showError (getCurrentException())))
        on clearButton pressed do (local model=root;if model!=undefined do try(model.uiError="";cplClear (model.ensureDocument());model.syncUI())catch(model.showError (getCurrentException())))
        on exportButton pressed do (local model=root;if model!=undefined do (local path=getSaveFileName caption:"Save Physics result" types:"Physics Lab JSON (*.json)|*.json|";if path!=undefined do try(cplExportFile (model.ensureDocument()) path)catch(model.showError (getCurrentException()))))
        on importButton pressed do (local model=root;if model!=undefined do (local path=getOpenFileName caption:"Load Physics result" types:"Physics Lab JSON (*.json)|*.json|";if path!=undefined do try(model.uiError="";cplImportFile (model.ensureDocument()) path;model.syncUI())catch(model.showError (getCurrentException()))))
        on recoveryButton pressed do (local model=root;if model!=undefined do (local path=getOpenFileName caption:"Recover Physics session" types:"Physics recovery JSON (*.json)|*.json|";if path!=undefined do try(model.uiError="";cplRecoverFile (model.ensureDocument()) path;model.syncUI())catch(model.showError (getCurrentException()))))
        on resultUI open do try(root=this;controlsReady=true;layout())catch(controlsReady=false;root.showError (getCurrentException()))
        on resultUI resized size do if controlsReady and root!=undefined and (root.uiWidth root.resultUI)!=lastLayoutWidth do try(layout())catch(root.showError (getCurrentException()))
        on resultUI close do (controlsReady=false;root=undefined)
    )

    on buildMesh do
    (
        if physicsDocument!=undefined then mesh=cplViewportMesh physicsDocument showViewportIcon viewportIconSize
        else setMesh mesh vertices:#() faces:#()
    )
    fn creationRadius anchor target = (amax .0001 (amin 1000 ((amax 0.1 (distance anchor target))/(units.decodeValue "1m"))))
    on create do (ensureDocument();viewportIconSize=amax .0001 (amin 1000 (10.0/(units.decodeValue "1m"))))
    on attachedToNode node do cplSetViewportIcon (ensureDocument()) node showViewportIcon viewportIconSize
    tool create
    (
        on mousePoint click do (if click==1 do (nodeTM.translation=gridPoint;viewportIconSize=creationRadius gridPoint gridPoint);if click==2 do #stop)
        on mouseMove click do (if click==2 do viewportIconSize=creationRadius nodeTM.translation gridPoint)
    )
)

-- Redraw only consumes cached native wires/current poses. No scene nodes are created.
global CyrusPhysicsCollisionDraw
try(unregisterRedrawViewsCallback CyrusPhysicsCollisionDraw)catch()
fn CyrusPhysicsCollisionDraw = (cplDrawCollisionShapes())
registerRedrawViewsCallback CyrusPhysicsCollisionDraw

-- Restore transient icon ownership after loading; never create extra scene nodes.
global CyrusPhysicsRebindIcons
fn CyrusPhysicsRebindIcons =
(
    for model in getClassInstances CyrusPhysicsLab do try(model.applyViewportIcon();if model.objectsUI.isDisplayed do model.refreshBindings())catch()
)
callbacks.removeScripts id:#CyrusPhysicsLabViewportIcons
callbacks.addScript #filePostOpen "CyrusPhysicsRebindIcons()" id:#CyrusPhysicsLabViewportIcons persistent:false
callbacks.addScript #filePostMerge "CyrusPhysicsRebindIcons()" id:#CyrusPhysicsLabViewportIcons persistent:false
callbacks.addScript #sceneUndo "CyrusPhysicsRebindIcons()" id:#CyrusPhysicsLabViewportIcons persistent:false
callbacks.addScript #sceneRedo "CyrusPhysicsRebindIcons()" id:#CyrusPhysicsLabViewportIcons persistent:false
