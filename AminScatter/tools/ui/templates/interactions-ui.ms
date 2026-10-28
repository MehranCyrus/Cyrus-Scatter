    rollout selected_interactionsUI "Interactions - layer" width:#cmdPanel category:185 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined,obj=undefined,controlsReady=false,binding=false,models=#(),modelIDs=#(),selectedSource=undefined,selectedSourceID=""
        dropdownlist roleList "Layer role" items:#("Off","Scattered colliders","React to colliders") selection:1 pos:[6,6] width:220
        label workflowInfo "" pos:[6,34] width:220 height:60
        listbox modelList "Original source model" items:#() height:4 pos:[6,94] width:220
        pickbutton sourcePickButton "+" pos:[6,190] width:110 height:22
        button sourceRemoveButton "x" pos:[118,190] width:108 height:22
        button focusSourceButton "Frame source" pos:[118,190] width:108 height:22
        dropdownlist proxyList "Collision geometry" items:#("Original closed mesh","Bounding box","Assigned custom mesh") selection:1 pos:[6,220] width:220
        button buildTrunksButton "Build trunk colliders" pos:[6,248] width:220 height:22
        button pickColliderButton "Assign custom collider..." pos:[6,274] width:220 height:22
        checkbutton reviewColliderButton "Show collider" pos:[6,300] width:220 height:22
        button prepareButton "Prepare model" pos:[6,248] width:220 height:22
        button editorButton "Edit preparation..." pos:[6,274] width:220 height:22
        checkbutton guideReviewButton "Show source guides" pos:[6,300] width:220 height:22
        checkbox rootsCheck "Hide covered roots" pos:[6,328] width:220
        dropdownlist responseList "Response" items:#("Bend","Trim","Bend and trim","Detailed contact (slow)") selection:1 pos:[6,328] width:220
        spinner strengthSpin "Bend strength (%):" type:#float range:[0,100,50] pos:[6,328] width:220
        spinner trunkSpin "Trunk bend (%):" type:#float range:[0,100,0] pos:[6,328] width:220
        spinner fixedBaseSpin "Fixed base (% height):" type:#float range:[0,100,0] pos:[6,328] width:220
        spinner transitionSpin "Bend fade (% height):" type:#float range:[0,100,25] pos:[6,328] width:220
        spinner pruneThresholdSpin "Trim after overlap:" type:#worldUnits range:[0,(units.decodeValue "10m"),0] pos:[6,328] width:220
        spinner pruneAmountSpin "Trim amount (%):" type:#float range:[0,100,100] pos:[6,328] width:220
        checkbox neighborsCheck "React to neighboring trees" pos:[6,328] width:220
        dropdownlist hideAreaList "Hide area" items:#("Inside solid","Under collider") selection:2 pos:[6,354] width:220
        spinner hideMarginSpin "Hide margin:" type:#worldUnits range:[0,(units.decodeValue "10m"),0] pos:[6,380] width:220
        spinner gapSpin "Clearance:" type:#worldUnits range:[0,(units.decodeValue "10m"),0] pos:[6,354] width:220
        spinner foliageSpin "Preview leaves / blades (%):" type:#float range:[1,100,5] pos:[6,380] width:220
        label info "" pos:[6,406] width:220 height:100
        button retryButton "Retry contact update" pos:[6,510] width:220 height:22
        button validateButton "Check full visible mesh" pos:[6,536] width:220 height:22
        button repairSettingsButton "Repair preparation settings" pos:[6,562] width:220 height:22
        spinner minimumSpin "Minimum stem:" type:#worldUnits range:[(units.decodeValue "1mm"),(units.decodeValue "100mm"),(units.decodeValue "5mm")] pos:[6,590] width:220
        spinner stiffnessSpin "Refinement stiffness:" type:#float range:[0,1,0.5] scale:0.05 pos:[6,616] width:220
        spinner connectionSpin "Branch connection:" type:#worldUnits range:[(units.decodeValue "1mm"),(units.decodeValue "50cm"),(units.decodeValue "15cm")] pos:[6,642] width:220
        spinner verticesLimitSpin "Source vertices:" type:#integer range:[3,8000000,2000000] pos:[6,668] width:220
        spinner trianglesLimitSpin "Source triangles:" type:#integer range:[1,16000000,4000000] pos:[6,694] width:220
        spinner partsLimitSpin "Connected pieces:" type:#integer range:[1,500000,100000] pos:[6,720] width:220
        spinner guidesLimitSpin "Prepared guides:" type:#integer range:[1,32768,8192] pos:[6,746] width:220
        spinner previewLimitSpin "Preview triangles:" type:#integer range:[1,2000000,500000] pos:[6,772] width:220
        spinner memoryLimitSpin "Preparation memory (MiB):" type:#integer range:[64,16384,2048] pos:[6,798] width:220
        spinner workLimitSpin "Preparation work (millions):" type:#integer range:[1,2048,256] pos:[6,824] width:220
        button cleanColliderLinksButton "Clean unused collider links" pos:[6,850] width:220 height:22
        -- Both source lists are views of the same authored rows. Resolve actions
        -- through the saved row identity, never a captured node or row position.
        -- A deleted scene node still has a row which the artist can remove.
        fn currentRow = (
            local chosen=modelList.selection
            if obj==undefined or chosen<1 or chosen>modelIDs.count then 0 else findItem (obj.sourceRowIDs as array) modelIDs[chosen]
        )
        fn currentSource = (
            local row=currentRow()
            if row>0 and row<=obj.sources.count and not obj.isEmptySource row and not obj.isPointSource row and obj.usableSource obj.sources[row] then obj.sources[row] else undefined
        )
        fn sourceState = (
            local row=currentRow(),node=currentSource();selectedSource=node
            selectedSourceID=if row>0 then obj.sourceRowIDs[row] else ""
            prepareButton.enabled=node!=undefined and not obj.interactionCollider
            editorButton.enabled=node!=undefined and not obj.interactionCollider
            guideReviewButton.checked=obj.interactionsReviewVisible #guides node
            guideReviewButton.enabled=node!=undefined and (obj.interactionReviewNode==node or obj.interactionsReady #(node))
            reviewColliderButton.checked=obj.interactionsReviewVisible #collider node
            reviewColliderButton.enabled=node!=undefined and obj.interactionCollider
            focusSourceButton.enabled=node!=undefined;sourceRemoveButton.enabled=row>0;pickColliderButton.enabled=node!=undefined and obj.interactionCollider
            workflowInfo.text=if obj.interactionCollider then "Uses scattered copies in this layer. For ordinary walls and stones, use Scene colliders."
                else if obj.interactionReact then obj.interactionsPreparationStatus() else "Choose React to colliders for plants. Add ordinary walls or stones in Scene colliders."
            true
        )
        fn bind leaf = (
            binding=true
            if obj!=undefined and obj!=leaf do (obj.interactionsClearGuides();selectedSource=undefined;selectedSourceID="")
            obj=leaf;obj.ensureSourceRows();models=obj.sources as array;modelIDs=for id in obj.sourceRowIDs collect id
            roleList.selection=if obj.interactionCollider then 2 else if obj.interactionReact then 3 else 1
            rootsCheck.checked=obj.interactionCoverRoots;hideMarginSpin.value=obj.interactionHideMarginWU;hideAreaList.selection=obj.interactionHideArea;hideMarginSpin.enabled=obj.interactionCoverRoots;hideAreaList.enabled=obj.interactionCoverRoots;gapSpin.value=obj.interactionGapWU;stiffnessSpin.value=obj.interactionStiffness;proxyList.selection=obj.interactionColliderMode
            responseList.selection=if obj.interactionResponse==0 then 4 else obj.interactionResponse;strengthSpin.value=obj.interactionBendStrength*100;pruneThresholdSpin.value=obj.interactionPruneThresholdWU;pruneAmountSpin.value=obj.interactionPruneAmount*100;neighborsCheck.checked=obj.interactionNeighbors
            trunkSpin.value=obj.interactionTrunkBend*100;fixedBaseSpin.value=obj.interactionFixedBase*100;transitionSpin.value=obj.interactionBendTransition*100
            modelList.items=for row=1 to models.count collect (
                if obj.isPointSource row then ((obj.sourceLabel row)+" | Point (no interaction mesh)")
                else if obj.isEmptySource row then ((obj.sourceLabel row)+" | Empty")
                else if not obj.usableSource models[row] then ((obj.sourceLabel row)+" | Missing model - remove or replace")
                else obj.interactionsSourceCaption models[row]
            )
            local row=findItem modelIDs selectedSourceID
            if row==0 and selectedSource!=undefined do row=findItem models selectedSource
            modelList.selection=if row>0 then row else if models.count>0 then 1 else 0
            minimumSpin.range=point3 (units.decodeValue "1mm") (units.decodeValue "100mm") (units.decodeValue "5mm")
            minimumSpin.value=if obj.interactionUnitsPending then obj.interactionMinimumWU else obj.interactionMinimumM*(units.decodeValue "1m");foliageSpin.value=obj.interactionFoliage*100
            verticesLimitSpin.value=obj.interactionMaxVertices;trianglesLimitSpin.value=obj.interactionMaxTriangles;partsLimitSpin.value=obj.interactionMaxParts;guidesLimitSpin.value=obj.interactionMaxGuides;previewLimitSpin.value=obj.interactionMaxPreview;memoryLimitSpin.value=obj.interactionMemoryMiB;workLimitSpin.value=obj.interactionWorkMillions
            connectionSpin.value=obj.interactionConnectionM*(units.decodeValue "1m")
            repairSettingsButton.enabled=obj.interactionUnitsPending or obj.interactionMinimumM<0.001 or obj.interactionMinimumM>0.10000001 or obj.interactionFoliage<0.01 or obj.interactionFoliage>1.0
            sourceState();info.text=root.interactionsStatus();controlsReady=true;binding=false;true
        )
        fn apply = (
            local controller=root,target=obj
            try(controller.interactionsEnsure();CyrusViewportRecordsDirty=true;CyrusViewportRedraw();if controlsReady and root==controller and obj==target do (bind target;info.text=controller.interactionsStatus());true)
            catch(controller.interactionError=getCurrentException();if controlsReady and root==controller and obj==target do info.text=controller.interactionsStatus();false)
        )
        fn changePreparation key value rebuild:false = (
            local target=obj,controller=root
            try(
                undo "Cyrus preparation setting" on (
                    setProperty target key value
                    if key==#interactionMinimumM do (target.interactionMinimumWU=value*(units.decodeValue "1m");target.interactionUnitsPending=false)
                    target.interactionsRefreshPreparation rebuild:rebuild
                )
                if controlsReady and obj==target do (bind target;apply())
            )catch(local message=getCurrentException();controller.interactionError=message;if controlsReady and obj==target do (bind target;info.text=controller.interactionsStatus()))
        )
        fn chooseRole v = if controlsReady and not binding and CyrusLicenseCanEdit() do (
            local target=obj
            try(
                if v==2 do target.interactionsSources (target.validSources()) 1
                undo "Cyrus interaction role" on (target.interactionCollider=(v==2);target.interactionReact=(v==3))
                target.interactionsClearGuides();bind target;apply()
            )catch(local message=getCurrentException();bind target;info.text=message)
        )
        on roleList selected v do chooseRole v
        fn responseSetting key value = if controlsReady and not binding and CyrusLicenseCanEdit() do try(local target=obj;target.interactionsResponseSetting key value;bind target;apply())catch(info.text=getCurrentException())
        on responseList selected v do responseSetting #interactionResponse (if v==4 then 0 else v)
        on strengthSpin changed v do responseSetting #interactionBendStrength (v/100.0)
        on trunkSpin changed v do responseSetting #interactionTrunkBend (v/100.0)
        on fixedBaseSpin changed v do responseSetting #interactionFixedBase (v/100.0)
        on transitionSpin changed v do responseSetting #interactionBendTransition (v/100.0)
        on pruneThresholdSpin changed v do responseSetting #interactionPruneThresholdWU v
        on pruneAmountSpin changed v do responseSetting #interactionPruneAmount (v/100.0)
        on neighborsCheck changed v do responseSetting #interactionNeighbors v
        on modelList selected row do if controlsReady and not binding do (obj.interactionsClearGuides();sourceState();info.text=if currentSource()!=undefined then "Source: "+(currentSource()).name else "Choose a source model.")
        on sourcePickButton picked node do if controlsReady and not binding and CyrusLicenseCanEdit() do try(
            local target=obj,controller=root
            if not (target.usableSource node) do throw "Pick an original scene model. Receivers and Scatter objects cannot be source models."
            target.interactionsClearGuides()
            undo "Cyrus add interaction source" on target.addModelSource node
            if controlsReady and obj==target do (selectedSource=node;local row=target.sourceRow node;selectedSourceID=if row>0 then target.sourceRowIDs[row] else "")
            if controller.mainUI!=undefined do controller.mainUI.bind()
            if controlsReady and obj==target do (bind target;apply())
        )catch(info.text=getCurrentException())
        on sourceRemoveButton pressed do if controlsReady and not binding and CyrusLicenseCanEdit() do try(
            local target=obj,controller=root,row=currentRow()
            -- If another view already removed the selected ID, refresh this
            -- view; do not delete whichever new source now occupies its index.
            if row>0 do (target.interactionsClearGuides();target.removeModelSources #(row))
            if controlsReady and obj==target do (selectedSource=undefined;selectedSourceID="")
            if controller.mainUI!=undefined do controller.mainUI.bind()
            if controlsReady and obj==target do (bind target;apply())
        )catch(info.text=getCurrentException())
        on focusSourceButton pressed do if controlsReady and not binding do try(
            local node=currentSource();if node==undefined do throw "Choose a source model."
            local bounds=nodeGetBoundingBox node (matrix3 1)
            if viewport.getType()==#view_camera then info.text="Switch to a perspective or orthographic viewport to frame the source."
            else (viewport.ZoomToBounds false bounds[1] bounds[2];redrawViews())
        )catch(info.text=getCurrentException())
        on rootsCheck changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do (undo "Cyrus root coverage" on obj.interactionCoverRoots=v;apply())
        on hideMarginSpin changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do (undo "Cyrus hide margin" on obj.interactionHideMarginWU=v;apply())
        on hideAreaList selected v do if controlsReady and not binding and CyrusLicenseCanEdit() do (undo "Cyrus hide area" on obj.interactionHideArea=v;apply())
        on gapSpin changed v do responseSetting #interactionGapWU v
        on stiffnessSpin changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do (undo "Cyrus contact stiffness" on obj.interactionStiffness=v;apply())
        fn chooseColliderMode v = if controlsReady and not binding and CyrusLicenseCanEdit() do try(local target=obj;target.interactionsValidateColliderMode v;undo "Cyrus collision geometry" on target.interactionsSetColliderMode v;bind target;apply())catch(local message=getCurrentException();bind obj;info.text=message)
        on proxyList selected v do chooseColliderMode v
        on buildTrunksButton pressed do if controlsReady and not binding and CyrusLicenseCanEdit() do try(local target=obj;undo "Build Cyrus trunk colliders" on target.interactionsBuildTrunks();bind target;apply())catch(info.text=getCurrentException())
        on pickColliderButton pressed do if controlsReady and not binding and CyrusLicenseCanEdit() do try(
            local target=obj,node=currentSource();if node==undefined do throw "Choose an original source first."
            local proxy=pickObject prompt:"Pick a closed collider mesh (Esc cancels)"
            if isValidNode proxy do (
                if target!=obj or findItem (target.validSources()) node==0 do throw "The source selection changed during picking. Choose it and pick again."
                target.interactionsValidateProxy node proxy
                undo "Assign Cyrus collider" on target.interactionsSetProxy node proxy
                bind target;apply()
                if target.interactionColliderMode!=3 and proxy!=node do info.text="Custom mesh saved. Assign the remaining sources before choosing Assigned custom mesh."
            )
        )catch(info.text=getCurrentException())
        on reviewColliderButton changed v do if controlsReady and not binding do try(if v then obj.interactionsReviewCollider (currentSource()) else obj.interactionsClearGuides();sourceState();redrawViews())catch(reviewColliderButton.checked=false;info.text=getCurrentException())
        on prepareButton pressed do if controlsReady and not binding and CyrusLicenseCanEdit() do try(
            local target=obj,node=currentSource();if node==undefined do throw "Choose an original source model."
            undo "Prepare Cyrus model" on target.interactionsPrepare #(node)
            bind target;apply()
        )catch(info.text=getCurrentException())
        on guideReviewButton changed v do if controlsReady and not binding do try(if v then obj.interactionsShowGuides (currentSource()) else obj.interactionsClearGuides();sourceState();redrawViews())catch(guideReviewButton.checked=false;info.text=getCurrentException())
        on editorButton pressed do if controlsReady and not binding and CyrusLicenseCanEdit() do try(CyrusOpenPreparationEditor obj (currentSource()))catch(info.text=getCurrentException())
        on foliageSpin changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do (undo "Cyrus foliage preview" on obj.interactionFoliage=v/100.0;obj.interactionSourceCache=#();obj.interactionsChanged();apply())
        on minimumSpin changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do changePreparation #interactionMinimumM (v/(units.decodeValue "1m")) rebuild:true
        on connectionSpin changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do changePreparation #interactionConnectionM (v/(units.decodeValue "1m")) rebuild:true
        on repairSettingsButton pressed do if controlsReady and not binding and CyrusLicenseCanEdit() do try(local target=obj;local message=target.interactionsRepairSettings();bind target;info.text=message)catch(info.text=getCurrentException())
        on verticesLimitSpin changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do changePreparation #interactionMaxVertices v
        on trianglesLimitSpin changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do changePreparation #interactionMaxTriangles v
        on partsLimitSpin changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do changePreparation #interactionMaxParts v
        on guidesLimitSpin changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do changePreparation #interactionMaxGuides v
        on previewLimitSpin changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do changePreparation #interactionMaxPreview v
        on memoryLimitSpin changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do changePreparation #interactionMemoryMiB v
        on workLimitSpin changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do changePreparation #interactionWorkMillions v
        on cleanColliderLinksButton pressed do if controlsReady and not binding and CyrusLicenseCanEdit() do (local target=obj,n=target.interactionsCleanProxies();bind target;info.text=(n as string)+" unused collider links removed. Scene meshes were kept.")
        on retryButton pressed do if controlsReady and not binding do apply()
        on validateButton pressed do if controlsReady and not binding do try(
            local state=root.interactionsEnsure();if state==undefined do throw "Prepare a reacting source and enable a collider layer first."
            local report=cyrusInteractionValidate state 2000000;info.text=report[2];format "Cyrus full mesh contact validation:\n%\n" report[3]
        )catch(info.text=getCurrentException())
    )
    rollout selected_collidersUI "Scene colliders - setup" width:#cmdPanel category:186 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined,obj=undefined,controlsReady=false,binding=false
        label hint "Add walls or stones from the scene. Move and scale them normally in Max." pos:[6,6] width:220 height:42
        listbox colliderList "Scene objects" items:#() height:5 pos:[6,50] width:220
        pickbutton addButton "+" pos:[6,165] width:70 height:22
        button selectedButton "Add selected" pos:[80,165] width:100 height:22
        button removeButton "x" pos:[184,165] width:42 height:22
        button selectButton "Select collider" pos:[6,192] width:220 height:22
        label info "" pos:[6,220] width:220 height:64
        fn bind leaf = (
            binding=true;obj=leaf
            local selected=colliderList.selection
            colliderList.items=for node in root.interactionSceneColliders collect (if isValidNode node then node.name else "Missing collider - remove this row")
            colliderList.selection=if colliderList.items.count>0 then amax 1 (amin selected colliderList.items.count) else 0
            removeButton.enabled=colliderList.selection>0;selectButton.enabled=colliderList.selection>0
            info.text=root.interactionsStatus();binding=false;controlsReady=true;true
        )
        fn apply = (
            local controller=root,target=obj
            try(controller.interactionsEnsure();CyrusViewportRecordsDirty=true;CyrusViewportRedraw();if controlsReady and root==controller do bind target;true)
            catch(controller.interactionError=getCurrentException();if controlsReady and root==controller do info.text=controller.interactionsStatus();false)
        )
        on addButton picked node do if controlsReady and not binding and CyrusLicenseCanEdit() do try(local controller=root;controller.interactionsSceneCommand #(node);apply())catch(info.text=getCurrentException())
        on selectedButton pressed do if controlsReady and not binding and CyrusLicenseCanEdit() do try(local controller=root;controller.interactionsSceneCommand (selection as array);apply())catch(info.text=getCurrentException())
        on removeButton pressed do if controlsReady and not binding and CyrusLicenseCanEdit() do try(local controller=root,index=colliderList.selection;controller.interactionsSceneCommand #() removeIndex:index;apply())catch(info.text=getCurrentException())
        on colliderList selected row do if controlsReady and not binding do (removeButton.enabled=row>0;selectButton.enabled=row>0)
        on selectButton pressed do if controlsReady and not binding do (local row=colliderList.selection;if row>0 and row<=root.interactionSceneColliders.count and isValidNode root.interactionSceneColliders[row] do select root.interactionSceneColliders[row])
    )
