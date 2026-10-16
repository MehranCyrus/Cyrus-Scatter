-- Native MAXScript fixture; keeps product Undo outside Python's implicit hold.
(
    if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned gallery host required."
    local log=createFile (MCPFixtureDir+"style-boundaries-"+(timeStamp() as string)+".txt")
    fn check value message log = (format "%: %\n" (if value then "PASS" else "FAIL") message to:log;flush log;if not value do throw message)
    try (
        check (not theHold.Holding()) "No surrounding hold" log
        CyrusPerfHeadless=true;resetMaxFile #noPrompt
        local node,root,leaf,peer,target,surface,source
        undo off (
            units.SystemType=#centimeters;units.SystemScale=1
            surface=plane width:500 length:500 widthsegs:2 lengthsegs:2
            source=pyramid width:10 depth:10 height:20 pos:[1000,0,0]
            target=point name:"Style target" pos:[100,50,150]
            node=AminScatterObject name:"Style boundaries";root=node.baseObject;root.updateMode=1;root.autoRender=false
            root.newLayer();leaf=root.selectedLayer();root.setLayerSurfaces leaf #(surface);leaf.sources=#(source);leaf.ensureSourceRows()
            leaf.amount=300;leaf.procPopulation=1;leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false
            root.newLayer();peer=root.selectedLayer();root.setLayerSurfaces peer #(surface)
            setPropertyController leaf #wholeScaleMin (bezier_float());leaf.wholeScaleMin=0.7
            setPropertyController peer #wholeScaleMin (getPropertyController leaf #wholeScaleMin)
            root.refreshAll()
        )
        local shared=getPropertyController leaf #wholeScaleMin,epoch=root.procEpoch
        local data=CyrusRecipeCapture root #(leaf) "Style boundaries",record=(CyrusRecipeGet data "layers")[1],recordID=CyrusRecipeGet record "id",settings=CyrusRecipeGet record "settings"
        local path=MCPFixtureDir+"style-bounds-"+CyrusNewLayerID()+".csrecipe.json",metadata=CyrusRecipeObject #(#("category","Boundaries"),#("tags",#()),#("description","Disposable fixture"))
        local digest=cyrusRecipeEntryWrite path data metadata "" undefined "" false,plan=CyrusStylePrepare root leaf path digest recordID #("Transforms") #()
        check (not (CyrusStyleCommit plan) and (getPropertyController leaf #wholeScaleMin)==shared) "Identical style retains shared controller" log
        CyrusRecipePut settings "wholeScaleMin" 0.8
        digest=cyrusRecipeEntryWrite path data metadata "" undefined digest false
        plan=CyrusStylePrepare root leaf path digest recordID #("Transforms") #()
        check (CyrusStyleCommit plan and leaf.wholeScaleMin==0.8 and peer.wholeScaleMin==0.7) "Changing selected transform detaches shared controller" log
        check ((getPropertyController leaf #wholeScaleMin)!=shared and (getPropertyController peer #wholeScaleMin)==shared) "Unselected owner keeps original controller" log
        max undo;check ((getPropertyController leaf #wholeScaleMin)==shared and leaf.wholeScaleMin==0.7) "Undo restores controller sharing" log
        max redo;check (leaf.wholeScaleMin==0.8 and peer.wholeScaleMin==0.7) "Redo restores independent authored value" log
        local unsupported=false
        undo off (setPropertyController leaf #wholeScaleMin (float_expression()))
        try(CyrusStylePrepare root leaf path digest recordID #("Amount") #())catch(unsupported=true)
        check unsupported "Unsupported static expression is protected even outside selected group" log
        undo off (setPropertyController leaf #wholeScaleMin (copy shared);leaf.wholeScaleMin=0.8)
        undo off (leaf.orientationMode=3;leaf.orientationTarget=target;leaf.densityMap=checker();leaf.distributionMode=3)
        data=CyrusRecipeCapture root #(leaf) "Bound role style";record=(CyrusRecipeGet data "layers")[1];recordID=CyrusRecipeGet record "id";settings=CyrusRecipeGet record "settings"
        digest=cyrusRecipeEntryWrite path data metadata "" undefined digest false
        local targetRole=CyrusRecipeGet settings "orientationTarget",mapRole=CyrusRecipeGet settings "densityMap",rejected=false
        try(CyrusStylePrepare root leaf path digest recordID #("Transforms") #(#(targetRole,undefined)))catch(rejected=true)
        check rejected "Explicit but unbound orientation role rejects before mutation" log
        rejected=false;try(CyrusStylePrepare root leaf path digest recordID #("Density texture") #(#(mapRole,undefined)))catch(rejected=true)
        check rejected "Explicit but unbound density map rejects" log
        plan=CyrusStylePrepare root leaf path digest recordID #("Transforms","Density texture") #(#(targetRole,target),#(mapRole,leaf.densityMap))
        check (not (CyrusStyleCommit plan)) "Bound same target and texture are a no-op" log
        local newTarget=point name:"Rebound target" pos:[-100,0,200]
        plan=CyrusStylePrepare root leaf path digest recordID #("Transforms") #(#(targetRole,newTarget))
        check (CyrusStyleCommit plan and leaf.orientationTarget==newTarget) "Explicit target rebinding commits" log
        max undo;check (leaf.orientationTarget==target) "Binding Undo" log
        max redo;check (leaf.orientationTarget==newTarget) "Binding Redo" log
        plan=CyrusStylePrepare root leaf path digest recordID #("Transforms") #(#(targetRole,target))
        delete target;rejected=false;try(CyrusStyleCommit plan)catch(rejected=true)
        check rejected "Deleted reviewed binding rejects without applying" log
        undo off (leaf.orientationMode=1;leaf.orientationTarget=undefined;leaf.densityMap=undefined;leaf.distributionMode=1)
        data=CyrusRecipeCapture root #(leaf) "Curves and units";record=(CyrusRecipeGet data "layers")[1];recordID=CyrusRecipeGet record "id";settings=CyrusRecipeGet record "settings"
        CyrusRecipePut settings "gridColumnWU" 2.0;CyrusRecipePut settings "gridRowWU" 3.0
        CyrusRecipePut settings "meshMaskSamples" #(0.0,0.3,1.0);CyrusRecipePut settings "meshMaskGraph" ""
        digest=cyrusRecipeEntryWrite path data metadata "" undefined digest false
        plan=CyrusStylePrepare root leaf path digest recordID #("Grid layout","Mesh channel mask") #()
        check (CyrusStyleCommit plan and leaf.gridColumnWU==200.0 and leaf.gridRowWU==300.0) "Metres convert to destination centimetres" log
        check (CyrusPresetSameValues (leaf.meshMaskSamples as array) #(0.0,0.3,1.0)) "Selected channel curve samples retained exactly" log
        max undo;check (not (CyrusPresetSameValues (leaf.meshMaskSamples as array) #(0.0,0.3,1.0))) "Curve Undo" log
        max redo;check (CyrusPresetSameValues (leaf.meshMaskSamples as array) #(0.0,0.3,1.0)) "Curve Redo" log
        CyrusRecipePut settings "meshMaskSamples" #(0.0,1.0)
        CyrusRecipePut settings "meshMaskGraph" "0,0,0,0,0,0,0,1,1,100,0,0,0,0,0,1"
        digest=cyrusRecipeEntryWrite path data metadata "" undefined digest false
        plan=CyrusStylePrepare root leaf path digest recordID #("Mesh channel mask") #()
        check (CyrusStyleCommit plan) "Matching editable graph and samples apply" log
        local graphBefore=leaf.meshMaskGraph
        CyrusRecipePut settings "meshMaskSamples" #(1.0,0.0)
        digest=cyrusRecipeEntryWrite path data metadata "" undefined digest false
        rejected=false;try(CyrusStylePrepare root leaf path digest recordID #("Mesh channel mask") #())catch(rejected=true)
        check (rejected and leaf.meshMaskGraph==graphBefore) "Mismatched graph/sample data rejects before mutation" log
        local amountsBefore=leaf.amount
        undo off leaf.procRadiusIDs=#("protected-record")
        rejected=false;try(CyrusStylePrepare root leaf path digest recordID #("Amount") #())catch(rejected=true)
        check (rejected and leaf.procRadiusIDs.count==1 and leaf.amount==amountsBefore) "Authored radius records block style without erasure" log
        undo off leaf.procRadiusIDs=#()
        plan=CyrusStylePrepare root leaf path digest recordID #("Amount") #()
        delete node;rejected=false;try(CyrusStyleCommit plan)catch(rejected=true)
        check rejected "Deleted destination rejects reviewed style" log
        check (not theHold.Holding()) "No stranded hold after rejected operations" log
        format "PASS: complete\n" to:log;close log
    )catch(format "ERROR: %\n" (getCurrentException()) to:log;close log;throw())
)
