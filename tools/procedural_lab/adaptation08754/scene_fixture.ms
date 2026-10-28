-- Fresh neutral fixture for persistence; it deliberately has no renderer assets.
-- The imported artist-derived fixture is preserved as a separate setup.
global ADImportedOwner,ADImportedRoot,ADImportedGrass,ADImportedWall
(
    if not matchPattern GardenRun pattern:"*/build/adaptation08754-20261028-01/host-*/" do throw "Owned adaptation host required."
    if theHold.Holding() or theHold.IsSuspended() do throw "Finish the current operation first."
    ADImportedOwner=WFOwner;ADImportedRoot=WFRoot;ADImportedGrass=WFGrass;ADImportedWall=ADWall
    local busy=CyrusPointBusy,suspended=CyrusPointSuspended,failure=""
    try (
        CyrusPointBusy=true;CyrusPointSuspended=true
        fileIn @"F:\Cursor\_Cyrus_Apps\CyrusScatter\tools\procedural_lab\adaptation08754\tree_generated.ms"
        local metre=units.decodeValue "1m",ground=plane name:"AD_Neutral_Ground" width:(4*metre) length:(4*metre) pos:[2000,0,0]
        WFOwner=AminScatterObject name:"AD_Neutral_Scene_Controller"
        WFRoot=WFOwner.baseObject;WFRoot.setLayerTransfer true
        WFRoot.updateMode=1;WFRoot.autoRender=false;WFRoot.surfaceNodes=#(ground);WFRoot.viewportMode=3
        WFRoot.newLayer();WFGrass=WFRoot.selectedLayer();WFGrass.amount=6;WFGrass.randomSeed=42
        WFGrass.addModelSource ADTree
        WFGrass.interactionReact=true;WFGrass.interactionResponse=3;WFGrass.interactionNeighbors=true
        WFGrass.interactionBendStrength=.6;WFGrass.interactionPruneAmount=.8;WFGrass.interactionPruneThresholdWU=.2
        WFGrass.interactionMinimumM=.005;WFGrass.interactionConnectionM=.15;WFGrass.interactionFoliage=1
        WFGrass.interactionsPrepare #(ADTree) rebuild:true
        WFRoot.setLayerTransfer false
        ADWall=box name:"AD_Neutral_Scaled_Wall" width:metre length:metre height:metre pos:[2000,0,0]
        ADWall.scale=[2,.15,1.3];WFRoot.interactionSceneColliders=#(ADWall)
        CyrusPointBusy=busy;CyrusPointSuspended=suspended
        WFRoot.refreshAll();WFRoot.interactionsEnsure();CyrusPointSync()
        if WFRoot.interactionError!="" do throw WFRoot.interactionError
    )catch(failure=getCurrentException())
    CyrusPointBusy=busy;CyrusPointSuspended=suspended
    (dotNetClass "System.IO.File").WriteAllText (GardenRun+"scene-fixture.txt") (if failure=="" then "PASS fresh neutral geometry/material-free dependency graph" else failure)
    if failure!="" do throw failure
)
