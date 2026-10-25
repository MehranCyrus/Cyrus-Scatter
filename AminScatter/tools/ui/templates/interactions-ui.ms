    rollout selected_interactionsUI "Interactions - layer" width:#cmdPanel category:185 autoLayoutOnResize:true (
        local root=undefined,owner=undefined,panel=undefined,obj=undefined,controlsReady=false,binding=false,models=#()
        checkbox colliderCheck "Collider" pos:[6,6] width:220 tooltip:"Use the accepted instances in this layer as obstacles. Move an individual stone with Cyrus Edit to update nearby reacting plants."
        checkbox reactCheck "React to colliders" pos:[6,30] width:220 tooltip:"Bend prepared plant models near collider layers. Analyze and review each unique source once."
        checkbox rootsCheck "Hide roots under colliders" pos:[6,54] width:220 tooltip:"Hide rooted groups below a collider's footprint within the plant's reach, or inside its solid base. When off, covered groups retain their original shape. Nearby uncovered roots stay planted and react."
        spinner gapSpin "Contact gap:" type:#worldUnits range:[0,(units.decodeValue "10cm"),0] pos:[6,80] width:220 tooltip:"Additional visible clearance beyond the collider surface, up to 10 cm. Zero uses the prepared stem thickness only."
        spinner stiffnessSpin "Refinement stiffness:" type:#float range:[0,1,0.5] scale:0.05 pos:[6,104] width:220 tooltip:"Resistance used when a guide needs iterative refinement. The fast contact fit preserves original guide curves by rotation; this setting does not change those rotations."
        dropdownlist proxyList "Collider shape" items:#("Closed source mesh","Bounding box proxy") selection:1 pos:[6,130] width:220 tooltip:"Mesh requires a closed manifold source. Box is an explicit conservative approximation."
        listbox modelList "Plant source to prepare" items:#() height:4 pos:[6,160] width:220
        button analyzeButton "Analyze model" pos:[6,250] width:110 height:22
        button acceptButton "Accept reviewed guides" pos:[6,276] width:220 height:22 tooltip:"Accept only after inspecting root positions, branch directions and foliage attachments."
        button clearButton "Hide guide review" pos:[6,302] width:220 height:22
        button applyButton "Apply interactions" pos:[6,328] width:220 height:22 tooltip:"Apply contact settings to the last completed scatter result. Pending Manual amount and seed edits wait for Update scatter."
        button validateButton "Validate full visible mesh" pos:[6,354] width:220 height:22 tooltip:"Independently check complete plant triangles near colliders. This slower check also reports root drift and stem/leaf strain."
        spinner minimumSpin "Minimum stem:" type:#worldUnits range:[0.001,10000,5] pos:[6,354] width:220
        spinner foliageSpin "Preview leaves / blades (%):" type:#float range:[0.1,100,5] pos:[6,380] width:220 tooltip:"Draw a stable sample of complete leaves or grass blades in Mesh preview. Stem tubes use fewer rings. Full render and Bake retain all visible source faces."
        label info "" pos:[6,406] width:220 height:100
        fn bind leaf = (
            binding=true;obj=leaf;models=obj.validSources()
            colliderCheck.checked=obj.interactionCollider;reactCheck.checked=obj.interactionReact;rootsCheck.checked=obj.interactionCoverRoots
            gapSpin.value=obj.interactionGapWU;stiffnessSpin.value=obj.interactionStiffness;proxyList.selection=obj.interactionColliderMode
            minimumSpin.value=obj.interactionMinimumWU;foliageSpin.value=obj.interactionFoliage*100
            modelList.items=for node in models collect (if isValidNode node then node.name else "Unsupported source")
            acceptButton.enabled=obj.interactionReview!=undefined
            info.text=root.interactionsStatus();controlsReady=true;binding=false;true
        )
        fn apply = (
            try(root.interactionsEnsure();CyrusViewportRecordsDirty=true;CyrusViewportRedraw();info.text=root.interactionsStatus())
            catch(root.interactionError=getCurrentException();info.text=root.interactionsStatus())
            true
        )
        on colliderCheck changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do (local target=obj;undo "Cyrus collider layer" on (target.interactionCollider=v;if v do target.interactionReact=false);bind target;apply())
        on reactCheck changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do (local target=obj;undo "Cyrus reacting layer" on (target.interactionReact=v;if v do target.interactionCollider=false);bind target;apply())
        on rootsCheck changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do (undo "Cyrus root coverage" on obj.interactionCoverRoots=v;apply())
        on gapSpin changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do (undo "Cyrus contact gap" on obj.interactionGapWU=v;apply())
        on stiffnessSpin changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do (undo "Cyrus contact stiffness" on obj.interactionStiffness=v;apply())
        on proxyList selected v do if controlsReady and not binding and CyrusLicenseCanEdit() do (undo "Cyrus collider shape" on obj.interactionColliderMode=v;apply())
        on minimumSpin changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do (obj.interactionMinimumWU=v;obj.interactionSourceCache=#();obj.interactionReview=undefined;acceptButton.enabled=false;obj.interactionsChanged();info.text="Preparation settings changed. Analyze the model and review its guides again.")
        on foliageSpin changed v do if controlsReady and not binding and CyrusLicenseCanEdit() do (obj.interactionFoliage=v/100;obj.interactionSourceCache=#();obj.interactionReview=undefined;acceptButton.enabled=false;obj.interactionsChanged();info.text="Preview preparation changed. Analyze the model and review its guides again.")
        on analyzeButton pressed do if controlsReady and not binding and CyrusLicenseCanEdit() do (
            local target=obj,row=modelList.selection
            if row>0 and row<=models.count do try(target.interactionsAnalyze models[row];info.text=cyrusInteractionSourceSummary target.interactionReview;acceptButton.enabled=true)catch(info.text=getCurrentException())
        )
        on acceptButton pressed do if controlsReady and not binding and CyrusLicenseCanEdit() do try(obj.interactionsAccept();acceptButton.enabled=false;apply())catch(info.text=getCurrentException())
        on clearButton pressed do if controlsReady do obj.interactionsClearGuides()
        on applyButton pressed do if controlsReady and not binding do apply()
        on validateButton pressed do if controlsReady and not binding do try(
            local state=root.interactionsEnsure()
            if state==undefined do throw "Apply interactions first."
            local report=cyrusInteractionValidate state 2000000
            info.text=report[2];format "Cyrus full mesh contact validation:\n%\n" report[3]
        )catch(info.text=getCurrentException())
    )
