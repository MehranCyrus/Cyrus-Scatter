/* Actual owned Max2027 Modify: complete source, quantity recovery and history. */
global CA_TEST_ROOT,CA_TEST_OUTPUT,CA_AUTO_SHOW_UI,CyrusArrange,caModifierUI,caModifierViewOwner
global caDIMakeAppliance,caDIBox,caDILog,caDIPasses,caDIFailures,caDIFinished
global caDIWrite,caDICheck,caDIEqual,caDIPose,caDIGenerate,caDISignature,caDIOpen,caDIVisual,caDIConfigure,caDIExport
fileIn(CA_TEST_ROOT+"tests/max/device_imported_helpers.ms")
fn caPRRun=
(
    resetMaxFile #noPrompt;units.SystemType=#millimeters;units.SystemScale=1;CA_AUTO_SHOW_UI=false
    for script in #("CyrusArrange.ms","ArrangeAssets.ms","ArrangeRegions.ms","ArrangeCollision.ms","ArrangeWorkflow.ms","ArrangeModifier.ms")do fileIn(CA_TEST_ROOT+"scripts/"+script)
    fileIn(CA_TEST_ROOT+"tests/max/device_imported_fixture.ms")
    caDICheck "Exact current native runs in normal owned Max2027"(caVersion()=="0.3.2"and(maxVersion())[1]==29000 and not maxOps.isInNonInteractiveMode())
    local source=caDIMakeAppliance(),material=standardMaterial name:"RECOVERY_Table_Material",table=caDIBox "RECOVERY_Table" [0,0,0] [1185,780,20]material
    local original=caDISignature source,receiving=caDISignature table,owner=caCreateArrangement();owner.name="RECOVERY_Arrange"
    caBindReceivers owner #(table);caDICheck "Complete-device setup mounts its actual Modify controls"(caDIOpen owner)
    caDICheck "Bulk prop binding is an inline Modify command"(caModifierViewOwner.dispatch #addProps data:#(source))
    caDIConfigure owner 2 false 50
    local start=timeStamp()
    for seed=7712033 to 7712048 do
    (
        caModifierUI.seedText.text=seed as string
        caDICheck("Saved seed "+(seed as string)+" generates two full-size complete devices")(caDIGenerate owner and(caOutputRows owner).count==2 and(caPlacementSettings owner)[1]==seed)
        local pose=caDIPose owner,fullSize=true;for row in(caOutputRows owner)do if row[6]!=1 do fullSize=false
        caDICheck "Recovery preserves original scale and complete topology materials and mapped UV corners"(fullSize and caDIVisual source owner)
        caDICheck "Repeat seed preserves the recovered complete result"(caDIGenerate owner and caDIEqual pose(caDIPose owner))
    )
    append caDILog("MEASURE sixteen_seed_pairs_ms="+((timeStamp()-start)as string));caDIWrite()
    caDIExport "packing-original" #(table)#()source owner
    local first=(caOutputRows owner)[1],protectedID=first[1],protectedPose=(caDIPose owner)[1],oldSeed=(caPlacementSettings owner)[1]
    caSetLocked owner #(protectedID)true;caDIOpen owner
    protectedPose=(caDIPose owner)[1];caModifierUI.keepSeed.checked=false;caModifierUI.keepSeed.changed false
    caDICheck "Fresh Generate retains both copies and changes the saved artist seed"(caDIGenerate owner and(caOutputRows owner).count==2 and(caPlacementSettings owner)[1]!=oldSeed)
    local kept=false;for row in(caDIPose owner)where row[1]==protectedID do kept=caDIEqual row protectedPose
    caDICheck "Recovery and fresh variation retain the protected complete pose exactly"kept
    caDIExport "protected-original" #(table)#()source owner
    caSetLocked owner #(protectedID)false;caDIOpen owner
    caModifierUI.keepSeed.checked=true;caModifierUI.keepSeed.changed true;caModifierUI.seedText.text="7712034"
    local blocker=caDIBox "RECOVERY_Explicit_Obstacle" [0,0,20] [600,780,1000]material
    caDICheck "Keep clear binds the explicit occupied half without another window"(caModifierViewOwner.dispatch #addObstacles data:#(blocker))
    local before=caDIPose owner,beforeSettings=caPlacementSettings owner
    caDICheck "Impossible capacity keeps the actual request and reports one unfilled copy"(caDIGenerate owner and(caOutputRows owner).count==1 and(caPlacementSettings owner)[3]==2 and findString caModifierUI.statusText.text "1 unfilled"!=undefined)
    local obstructed=caDIPose owner,obstructedSettings=caPlacementSettings owner
    max undo
    caDICheck "One Undo restores all pre-Generate complete placements and saved settings"(caDIEqual before(caDIPose owner)and caDIEqual beforeSettings(caPlacementSettings owner))
    max redo
    caDICheck "Redo restores the complete bounded obstacle result"(caDIEqual obstructed(caDIPose owner)and caDIEqual obstructedSettings(caPlacementSettings owner))
    caDIExport "obstacle-original" #(table)#(blocker)source owner
    caRemoveObstacle owner 1 (caSetupSummary owner)[3];caDIOpen owner;caDIConfigure owner 2 false 50
    local assetID=(caAssetRows owner)[1][1]
    caGeneratePlacementMinimums owner (caPlacementSettings owner)#(#(assetID,2))false
    caDICheck "Required copies recover both full-size source instances"((caOutputRows owner).count==2 and caDIEqual(caPropMinimums owner)#(#(assetID,2)))
    caDIExport "minimum-original" #(table)#()source owner
    caDIOpen owner;caModifierViewOwner.scaleControls.randomScale.checked=true;caModifierViewOwner.scaleControls.randomScale.changed true
    caModifierViewOwner.scaleControls.minimumScale.value=80;caModifierViewOwner.scaleControls.maximumScale.value=110
    caDICheck "Generate applies inline random-scale drafts to two complete devices"(caDIGenerate owner and(caOutputRows owner).count==2)
    local scales=true;for row in(caOutputRows owner)do if row[6]<.8 or row[6]>1.1 do scales=false
    caDICheck "Every final random size is within 80-110 percent and preserves source appearance"(scales and caDIVisual source owner)
    caDIExport "random" #(table)#()source owner
    caDICheck "All source vertices faces materials UVs and receiving geometry remain unchanged"(caDIEqual original(caDISignature source)and caDIEqual receiving(caDISignature table))
    local saved=caDIPose owner,savedSettings=caPlacementSettings owner,scene=CA_TEST_OUTPUT+"CyrusArrange-Packing-Recovery-032.max"
    caDICheck "Recovered complete-device scene saves"(saveMaxFile scene quiet:true)
    loadMaxFile scene quiet:true useFileUnits:true;owner=getNodeByName "RECOVERY_Arrange"
    caDICheck "Reopen restores quantity scale and every recovered pose"(caDIEqual saved(caDIPose owner)and caDIEqual savedSettings(caPlacementSettings owner)and caDIOpen owner)
    caModifierUI.keepSeed.checked=true;caModifierUI.keepSeed.changed true
    caDICheck "Reopened Modify Generate repeats the complete recovered scene"(caDIGenerate owner and caDIEqual saved(caDIPose owner))
    append caDILog "LIMIT: static upright full modeled appliance on literal table; separate reversed-glass imported receiver remains open. Independent mesh proof required."
    true
)
try(caPRRun())catch(caDIFailures+=1;append caDILog("EXCEPTION "+(getCurrentException()as string));append caDILog("ERROR_SOURCE "+(getErrorSourceFileName()as string)+":"+(getErrorSourceFileLine()as string));append caDILog("STACK "+(getCurrentExceptionStackTrace()as string)))
caDIFinished=true;caDIWrite()
