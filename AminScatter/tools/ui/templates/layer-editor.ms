-- One modeless editor; each topic is built on first use and retained. Binding
-- changes only owner references and controls, never calculation parameters.
global CyrusLayerEditor,CyrusOpenLayerEditor,CyrusBindLayerEditor,CyrusCloseLayerEditor,CyrusLayerEditorSections
global CyrusLayerEditorSize,CyrusLayerEditorPosition
global CyrusBrushSessionRoot,CyrusStopBrush
if CyrusCloseLayerEditor!=undefined do CyrusCloseLayerEditor()
if CyrusLayerEditorSize==undefined do CyrusLayerEditorSize=[920,800]
if CyrusLayerEditorPosition==undefined do CyrusLayerEditorPosition=[80,80]
fn CyrusLayerEditorSections root method:undefined = (
    if CyrusLayerEditor==undefined or CyrusLayerEditor.root!=root then #()
    else for r in CyrusLayerEditor.activeEditors() where method==undefined or isProperty r method collect r
)
fn CyrusCloseLayerEditor = (
    if CyrusLayerEditor!=undefined do destroyDialog CyrusLayerEditor
    CyrusLayerEditor=undefined
    true
)
fn CyrusBindLayerEditor root = (
    if CyrusLayerEditor!=undefined and CyrusLayerEditor.root==root and not CyrusLayerEditor.binding do CyrusLayerEditor.bind()
    true
)
fn CyrusOpenLayerEditor root owner = (
    if owner==undefined or findItem root.layerObjects owner==0 do return false
    if CyrusLayerEditor!=undefined then (CyrusLayerEditor.retarget root owner;CyrusLayerEditor.visible=true;return true)
    rollout editor "Cyrus Scatter 0.7.1 - Layer Editor" width:920 height:800 autoLayoutOnResize:true (
        local root=CyrusLayerUIRoot,owner=CyrusLayerUIOwner,ownerNode=undefined,binding=false,controlsReady=false,closing=false
        local clientSize=CyrusLayerEditorSize,layingOut=false
        local editors=#(),pages=#(),pageEditors=#(#(),#(),#(),#(),#(),#()),built=#{},topic=1,members=#(),sets=#(),pageSections=#(),ownerStates=#(),lastSet=undefined
        label setupInfo "" pos:[12,10] width:(clientSize.x-178) height:18
        button updateNow "Update setup" pos:[clientSize.x-158,8] width:146 height:24 tooltip:"Recalculate every enabled layer in this setup, in order."
        dropdownlist layerList "Layer" pos:[12,36] width:((clientSize.x-36)/2)
        dropdownlist setList "Paint set" pos:[clientSize.x/2+6,36] width:((clientSize.x-36)/2)
        checkbutton assetsTab "Assets" pos:[12,90] width:((clientSize.x-34)/6) height:26 checked:true tooltip:"Models, source rectangles and paint-set administration."
        checkbutton populationTab "Population" pos:[12+(clientSize.x-22)/6,90] width:((clientSize.x-34)/6) height:26 tooltip:"Shared layer count, density, Area and retry limits."
        checkbutton paintTab "Paint" pos:[12+2*(clientSize.x-22)/6,90] width:((clientSize.x-34)/6) height:26 tooltip:"Independent set coverage, strokes and background fill."
        checkbutton transformTab "Transform" pos:[12+3*(clientSize.x-22)/6,90] width:((clientSize.x-34)/6) height:26 tooltip:"Layer random transforms and source assignment."
        checkbutton spacingTab "Spacing" pos:[12+4*(clientSize.x-22)/6,90] width:((clientSize.x-34)/6) height:26 tooltip:"Self, between-set and layer-pair rules, radii and cleanup."
        checkbutton statisticsTab "Statistics" pos:[12+5*(clientSize.x-22)/6,90] width:((clientSize.x-34)/6) height:26 tooltip:"Cached calculation results and workflow help."
        label pageInfo "" pos:[12,122] width:(clientSize.x-24) height:34
        subrollout assetsLeft "" pos:[8,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout assetsRight "" pos:[clientSize.x/2+4,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout populationLeft "" pos:[8,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout populationRight "" pos:[clientSize.x/2+4,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout paintLeft "" pos:[8,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout paintRight "" pos:[clientSize.x/2+4,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout transformLeft "" pos:[8,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout transformRight "" pos:[clientSize.x/2+4,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout spacingLeft "" pos:[8,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout spacingRight "" pos:[clientSize.x/2+4,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout statisticsLeft "" pos:[8,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        subrollout statisticsRight "" pos:[clientSize.x/2+4,162] width:((clientSize.x-24)/2) height:(clientSize.y-204) scrollBar:#asNeeded autoLayoutOnResize:true
        label resultInfo "" pos:[12,clientSize.y-32] width:(clientSize.x-170) height:22
        button refreshButton "Refresh fields" pos:[clientSize.x-148,clientSize.y-34] width:136 height:24 tooltip:"Read current settings and cached counts; does not rebuild placements."
        timer statusTimer interval:1000 active:false
        fn validOwner = (isValidNode ownerNode and ownerNode.baseObject==root and findItem root.layerObjects owner>0 and owner.logicalParentID=="")
        fn activeEditors = pageEditors[topic]
        fn stopTools = (
            if CyrusBrushSessionRoot==root do CyrusStopBrush()
            -- End Max's pick mode before the same controls acquire a new owner.
            max select
        )
        fn rememberOwner = (
            if owner!=undefined do (
                local row=0
                for i=1 to ownerStates.count where ownerStates[i][1]==owner.layerID do row=i
                local state=#(owner.layerID,topic,for r in editors collect #(r,r.open))
                if row==0 then append ownerStates state else ownerStates[row]=state
            )
        )
        fn refreshStats = (
            if not controlsReady or not validOwner() do return false
            local summary=CyrusFlowLayerSummary root owner
            local unit=if root.viewportMode==1 and not root.groupCenters then " preview samples" else " shown"
            local text=(if root.updateMode==1 then "Manual" else "Live")+" | "+summary[3]+" | "+(CyrusUICount summary[1])+" placed / "+(CyrusUICount summary[2])+unit
            if resultInfo.text!=text do resultInfo.text=text
            local caption="Cyrus Scatter 0.7.1 | "+ownerNode.name+" / "+(root.layerCaption owner)
            if editor.title!=caption do editor.title=caption
            local setupText="Setup: "+ownerNode.name+"  |  Selecting scene models keeps this editor on its layer"
            if setupInfo.text!=setupText do setupInfo.text=setupText
            true
        )
        fn retainListItems control values = (
            local existing=control.items,changed=existing.count!=values.count
            if not changed do for i=1 to values.count while not changed do changed=existing[i]!=values[i]
            if changed do control.items=values
        )
        fn bindEditors = (
            if not validOwner() do return false
            local previous=binding;binding=true
            try (
                members=root.logicalLayers();sets=root.layerSets owner
                retainListItems layerList (for m in members collect root.layerCaption m)
                local layerIndex=findItem members owner
                if layerList.selection!=layerIndex do layerList.selection=layerIndex
                retainListItems setList (for m in sets collect m.paintSetName)
                local setIndex=findItem sets (root.selectedPaintSet owner)
                if setList.selection!=setIndex do setList.selection=setIndex
                for r in editors do (
                    local changedOwner=r.root!=root or r.owner!=owner
                    r.root=root;r.owner=owner;r.panel=editor
                    if findItem (activeEditors()) r>0 then r.bind (if isProperty r #setSpecific and r.setSpecific then root.selectedPaintSet owner else owner)
                    else (r.controlsReady=false;if changedOwner and isProperty r #obj do r.obj=undefined)
                )
                lastSet=root.selectedPaintSet owner
                refreshStats();binding=previous;true
            )catch(binding=previous;throw())
        )
        fn bind = (
            if binding or closing do return false
            if not validOwner() then (CyrusCloseLayerEditor();false) else bindEditors()
        )
        fn showTopic index = (
            if index<1 or index>6 do return false
            if topic==index and built[index] do (
                local tabs=#(assetsTab,populationTab,paintTab,transformTab,spacingTab,statisticsTab)
                local previous=binding;binding=true;tabs[index].checked=true;binding=previous
                refreshStats();return true
            )
            if topic!=index do stopTools()
            topic=index
            local tabs=#(assetsTab,populationTab,paintTab,transformTab,spacingTab,statisticsTab)
            for i=1 to tabs.count do tabs[i].checked=i==index
            -- Create native controls only after their parent is visible. Max
            -- can otherwise retain empty child pages after a height change.
            for p=1 to pages.count do for c in pages[p] do c.visible=p==index
            if not built[index] do (
                for col=1 to 2 do for spec in pageSections[index][col] do (
                    local r=CyrusCreateLayerEditorSection spec[1] root owner editor
                    append editors r
                    append pageEditors[index] r
                    addSubRollout pages[index][col] r rolledUp:spec[2]
                )
                built[index]=true
            )
            pageInfo.text=(#(
                "PAINT SET  |  Choose models, adjust their share and radii, or use source rectangles. Each model keeps its saved settings when parked outside.",
                "LAYER DEFAULTS  |  Set population and limits. All enabled paint sets share this budget, Area and generation seed.",
                "PAINT SET  |  Paint coverage on the shared surface. Background options reference earlier paint sets; spacing remains independent.",
                "LAYER DEFAULTS  |  Randomize transforms and source assignment. Per-model offsets, scale and forward axes are under Assets.",
                "LAYER + SET RULES  |  Choose the spacing scope first. Within a set, between sets and between layers are independent rules.",
                "CACHED RESULTS  |  Last completed calculation. In Manual mode, pending changes appear after Update."
            ))[index]
            bindEditors();true
        )
        fn retarget nextRoot nextOwner = (
            if root==nextRoot and owner==nextOwner do return bind()
            stopTools();rememberOwner()
            if root!=nextRoot do ownerStates=#()
            root=nextRoot;owner=nextOwner;ownerNode=undefined
            for node in refs.dependentNodes root where isValidNode node and node.baseObject==root do if ownerNode==undefined do ownerNode=node
            if not validOwner() do (CyrusCloseLayerEditor();return false)
            local nextTopic=1,state=undefined
            for row in ownerStates where row[1]==owner.layerID do (nextTopic=row[2];state=row)
            showTopic nextTopic
            if state!=undefined do for r in editors do for row in state[3] where row[1]==r do r.open=row[2]
            true
        )
        fn selectSet index = (
            if not binding and index>0 and index<=sets.count and (root.selectedPaintSet owner)!=sets[index] do (stopTools();owner.uiPaintSetID=sets[index].layerID;bindEditors())
        )
        on editor open do (
            pages=#(#(assetsLeft,assetsRight),#(populationLeft,populationRight),#(paintLeft,paintRight),#(transformLeft,transformRight),#(spacingLeft,spacingRight),#(statisticsLeft,statisticsRight))
            pageSections=#(
                #(#(#(#sourceUI,false)),#(#(#sourceContainersUI,false),#(#setsUI,true))),
                #(#(#(#distributionUI,false),#(#populationPolicyUI,false)),#(#(#areaUI,false))),
                #(#(#(#brushUI,false)),#(#(#backgroundUI,false))),
                #(#(#(#randomUI,false)),#(#(#diversityUI,false))),
                #(#(#(#proceduralUI,false),#(#instanceRadiusUI,true)),#(#(#spacingUI,false),#(#separationUI,false))),
                #(#(#(#detailsUI,false)),#(#(#workflowUI,false)))
            )
            for node in refs.dependentNodes root where isValidNode node and node.baseObject==root do if ownerNode==undefined do ownerNode=node
            controlsReady=true;showTopic 1
        )
        on editor resized size do if not layingOut do (
            local target=[amax size.x 720,amax size.y 500]
            if target!=size then setDialogSize editor target else (
                -- The rollout's intrinsic height can differ from the dialog's
                -- client area. Base scroll viewports and footer on this event.
                layingOut=true;clientSize=size
                try(updateRolloutLayout editor forceUpdate:true)catch(layingOut=false;throw())
                layingOut=false
            )
        )
        on editor close do (
            closing=true;statusTimer.active=false;stopTools()
            CyrusLayerEditorSize=getDialogSize editor;CyrusLayerEditorPosition=getDialogPos editor
            editors=#();ownerStates=#();owner=undefined;root=undefined;ownerNode=undefined;controlsReady=false
            CyrusLayerEditor=undefined
        )
        on assetsTab changed value do if not binding do showTopic 1
        on populationTab changed value do if not binding do showTopic 2
        on paintTab changed value do if not binding do showTopic 3
        on transformTab changed value do if not binding do showTopic 4
        on spacingTab changed value do if not binding do showTopic 5
        on statisticsTab changed value do if not binding do showTopic 6
        on layerList selected index do if not binding and index>0 do (
            local next=members[index]
            if next==owner do return false
            undo off root.selectLayer (findItem root.layerObjects next)
            retarget root next
            if root.mainUI.controlsReady do root.mainUI.bind()
        )
        on setList selected index do selectSet index
        on updateNow pressed do try(root.refreshAll();CyrusViewportRedraw();bind())catch(messageBox (getCurrentException()) title:"Cyrus update")
        on refreshButton pressed do bind()
        on statusTimer tick do (
            statusTimer.active=false
            if CyrusInteractionHeld() do (statusTimer.active=true;return false)
            if not validOwner() then CyrusCloseLayerEditor() else if not CyrusInteractionHeld() do (
                local sourceChanges=false
                for leaf in root.layerSets owner where leaf.containerUIChanged do (leaf.containerUIChanged=false;sourceChanges=true)
                if sourceChanges or lastSet!=root.selectedPaintSet owner then bind() else refreshStats()
            )
        )
    )
    CyrusLayerUIRoot=root;CyrusLayerUIOwner=owner
    CyrusLayerEditor=editor
    try (
        createDialog editor width:CyrusLayerEditorSize.x height:CyrusLayerEditorSize.y pos:CyrusLayerEditorPosition style:#(#style_titlebar,#style_sysmenu,#style_resizing) autoLayoutOnResize:false escapeEnable:false
        true
    )catch(CyrusCloseLayerEditor();throw())
)
callbacks.removeScripts id:#CyrusLayerEditorLifecycle
callbacks.addScript #filePreOpen "CyrusCloseLayerEditor()" id:#CyrusLayerEditorLifecycle persistent:false
callbacks.addScript #systemPreReset "CyrusCloseLayerEditor()" id:#CyrusLayerEditorLifecycle persistent:false
callbacks.addScript #nodePreDelete "if CyrusLayerEditor!=undefined and callbacks.notificationParam()==CyrusLayerEditor.ownerNode do CyrusCloseLayerEditor()" id:#CyrusLayerEditorLifecycle persistent:false
callbacks.addScript #sceneUndo "if CyrusLayerEditor!=undefined do CyrusLayerEditor.bind()" id:#CyrusLayerEditorLifecycle persistent:false
callbacks.addScript #sceneRedo "if CyrusLayerEditor!=undefined do CyrusLayerEditor.bind()" id:#CyrusLayerEditorLifecycle persistent:false
