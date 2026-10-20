/* Dedicated disposable Max 2027 host only. No file dialogs or computer-use automation. */
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global caFxTVConsole, caFxOpenShelf, caCreateAccessoryFixtures, caAFmm
global caCreateSetup, caSetupSummary, caSetArrangeSettings, caRegisterAsset, caAssetRows
global caSaveAssetLibrary, caLoadAssetLibrary, caRefreshAssets, caGenerate, caOutputRows, caSetLocked, caTick
global caDiagnostics, caVersion
global caAssetDetail, caUpdateAsset, caRebindAsset, caUseStoredAsset, caRemoveAssets
global caAssetSupport, caSetAssetSupport, caResetAssetSupport
global caSuggestFurniture, caCategoryRules, caSetCategoryRules, caResetCategoryRules
global caPreview, caPreviewInfo, caCommitPreview, caClearPreview, caPreviewBounds
global caWLog, caWPasses, caWFailures, caWCheck, caWEqualRows, caWSourceSignature, caWSameSources, caWRun
global caWFinished, caWWrite, caWRecord
global caWEqualRowsByID, caWEqualRules, caWEqualPreview
global caModifierUI,caModifierViewOwner,caFocusArrange,caCreateArrangement,caBindReceivers,caPlacementSettings,caGenerateVariation,caRegionRows,caGeometryCacheInfo
caWLog = #()
caWPasses = 0
caWFailures = 0
caWFinished = false

fn caWWrite =
(
    if CA_TEST_OUTPUT != undefined do
    (
        local report = createFile (CA_TEST_OUTPUT+"result.txt")
        local state = if caWFinished then (if caWFailures == 0 then "SUCCESS" else "ERROR") else "RUNNING"
        format "% passes=% failures=%\n" state caWPasses caWFailures to:report
        for line in caWLog do format "%\n" line to:report
        close report
    )
    true
)
fn caWRecord message =
(
    append caWLog message
    caWWrite()
    true
)
fn caWCheck label condition =
(
    if condition then (caWPasses += 1; caWRecord ("PASS "+label))
    else
    (
        caWFailures += 1
        caWRecord ("FAIL "+label)
        if caModifierUI != undefined do caWRecord("MODIFY_ERROR "+caModifierUI.errorMessage())
    )
    condition
)
fn caWEqualRows a b =
(
    if a.count != b.count then false
    else
    (
        local same = true
        for i = 1 to a.count while same do
        (
            if a[i][1] != b[i][1] or a[i][2] != b[i][2] or a[i][3] != b[i][3] or a[i][7] != b[i][7] or a[i][8] != b[i][8] do same = false
            if distance a[i][4] b[i][4] > 0.001 or abs(a[i][5]-b[i][5]) > 0.00001 or abs(a[i][6]-b[i][6]) > 0.00001 do same = false
        )
        same
    )
)
fn caWEqualRowsByID a b =
(
    local same = a.count == b.count
    local seen = #()
    for row in a while same do
    (
        if (findItem seen row[1]) > 0 then same = false
        else
        (
            append seen row[1]
            local matched = undefined
            for candidate in b while matched == undefined do
                if candidate[1] == row[1] do matched = candidate
            if matched == undefined then same = false
            else same = caWEqualRows #(row) #(matched)
        )
    )
    same
)
fn caWEqualRules a b =
(
    local same = a.count == b.count
    for i = 1 to a.count while same do
    (
        if a[i].count != b[i].count then same = false
        else for j = 1 to a[i].count where a[i][j] != b[i][j] do same = false
    )
    same
)
fn caWEqualPreview a b =
(
    local same = a.count == b.count
    for i = 1 to a.count while same do
    (
        if distance a[i][1] b[i][1] > 0.001 or distance a[i][2] b[i][2] > 0.001 or abs(a[i][3]-b[i][3]) > 0.00001 do same = false
    )
    same
)
fn caWSourceSignature nodes =
(
    for n in nodes collect #(n,n.name,n.transform,n.material,(nodeGetBoundingBox n (matrix3 1)))
)
fn caWSameSources signature =
(
    local same = true
    for row in signature while same do
    (
        local node = row[1]
        if not isValidNode node then same = false
        else
        (
            if node.name != row[2] or node.material != row[4] do same = false
            for i = 1 to 4 where distance node.transform[i] row[3][i] > 0.00001 do same = false
            local bounds = nodeGetBoundingBox node (matrix3 1)
            if distance bounds[1] row[5][1] > 0.00001 or distance bounds[2] row[5][2] > 0.00001 do same = false
        )
    )
    same
)
fn caWOpen owner =
(
    max modify mode;modPanel.setPinStack false;select owner
    modPanel.setCurrentObject owner.modifiers[1] node:owner ui:true
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    if not(caWCheck "Current native Modify document really mounts" (caModifierUI!=undefined and caModifierUI.hwnd!=0 and caModifierUI.currentSetup()==owner)) do throw "Cannot mount workflow owner."
    true
)
fn caWRun =
(
    if CA_TEST_ROOT==undefined or CA_TEST_OUTPUT==undefined do throw "Private paths are required."
    resetMaxFile #noPrompt;units.SystemType=#millimeters;units.SystemScale=1;CA_AUTO_SHOW_UI=false
    for script in #("CyrusArrange.ms","ArrangeAssets.ms","ArrangeRegions.ms","ArrangeCollision.ms","ArrangeWorkflow.ms","ArrangeModifier.ms") do fileIn(CA_TEST_ROOT+"scripts/"+script)
    fileIn(CA_TEST_ROOT+"tests/max/fixtures.ms");fileIn(CA_TEST_ROOT+"tests/max/asset_fixtures.ms")
    caWCheck "Exact 0.3.2 in owned normal Max2027 host" ((maxVersion())[1]==29000 and caVersion()=="0.3.2" and not maxOps.isInNonInteractiveMode())
    caWRecord("NATIVE_PATH "+(caDiagnostics())[1])
    local tv=caFxTVConsole grouped:true,shelf=caFxOpenShelf offsetMM:[3000,0,0] grouped:true
    local accessories=caCreateAccessoryFixtures offsetMM:[0,5000,0]
    caWCheck "Eleven original procedural prop assemblies" (accessories.count==11)
    local originals=caWSourceSignature(objects as array)
    select tv[1];caFocusArrange createNew:true
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    local tvSetup=caModifierUI.currentSetup();tvSetup.name="WF_TV_Arrangement"
    caWCheck "Current creation binds geometry with empty catalog and no solve" ((caAssetRows tvSetup).count==0 and(caOutputRows tvSetup).count==0 and(caGeometryCacheInfo tvSetup)[3]==undefined)
    modPanel.setPinStack true;select(for entry in accessories collect entry[1])
    caWCheck "Inline bulk Add accepts eleven unrelated original assemblies" (caModifierViewOwner.propControls.addSelection.pressed() and(caAssetRows tvSetup).count==11)
    local registered=caAssetRows tvSetup
    local invalidRegisteredRows=#()
    if registered.count==11 and registered[1].count==10 do
        for row in registered do if row[4].x<=0 or row[4].y<=0 or row[4].z<=0 or not row[10]do append invalidRegisteredRows row
    caWCheck "Bounded ten-field asset rows have positive millimetre dimensions and live sources" (registered.count==11 and registered[1].count==10 and invalidRegisteredRows.count==0)
    max undo
    caWCheck "One Undo removes complete inline catalog batch" ((caAssetRows tvSetup).count==0)
    max redo
    caWCheck "One Redo restores exact batch IDs metadata and source bindings" (deepEqual registered(caAssetRows tvSetup) strictCompare:true)
    local flatID=registered[2][1],originalFlat=caAssetDetail tvSetup registered[2][1],originalSupport=caAssetSupport tvSetup registered[2][1]
    caWRecord "STAGE native library/support contracts retained without retired editor popups"
    undo "WF edit asset metadata" on(caUpdateAsset tvSetup flatID "Curated flat book" 7 29 #(-15.0,0.0,25.0) 2.5 0.9 1.1 false)
    local edited=caAssetDetail tvSetup flatID
    caWCheck "Metadata edit keeps ID and exact source binding" (edited[1]==flatID and edited[10]==1 and edited[11]==originalFlat[11])
    caWCheck "Native yaw weight scale and descriptive mask store exactly" (edited[4]==29 and deepEqual edited[5] #(-15.0,0.0,25.0) and edited[6]==2.5 and abs(edited[7]-0.9)<0.00001 and abs(edited[8]-1.1)<0.00001)
    caWCheck "Metadata edit preserves captured anchor" ((distance ((caAssetSupport tvSetup flatID)[1]) originalSupport[1])<0.00001)
    local support=#([-100,-70,0],[100,-70,0],[100,70,0],[-100,70,0])
    undo "WF author support" on(caSetAssetSupport tvSetup flatID [5,0,0] support false 0 #() 0)
    local authored=caAssetSupport tvSetup flatID
    caWCheck "Authored anchor and complete contact are native state" (authored[1].x==5 and deepEqual authored[2] support and authored[7][1] and authored[7][2])
    caRefreshAssets tvSetup
    caWCheck "Refreshing original models retains authored support" (deepEqual authored(caAssetSupport tvSetup flatID) strictCompare:true)
    local rejected=false
    try(caSetAssetSupport tvSetup flatID [0,0,0] #([0,0,0],[1,0,0],[2,0,0]) false 0 #() 0)catch(rejected=true)
    caWCheck "Collinear contact rejects atomically" (rejected and deepEqual authored(caAssetSupport tvSetup flatID) strictCompare:true)
    caResetAssetSupport tvSetup flatID
    caWCheck "Reset support returns to geometry-derived contact" (not(caAssetSupport tvSetup flatID)[7][1] and(caAssetSupport tvSetup flatID)[1].x==0)
    caUpdateAsset tvSetup flatID originalFlat[2] originalFlat[3] originalFlat[4] originalFlat[5] originalFlat[6] originalFlat[7] originalFlat[8] originalFlat[9]
    local libraryPath=CA_TEST_OUTPUT+"original-accessories.cyalib"
    caWCheck "Reusable library saves complete mesh payload" (caSaveAssetLibrary tvSetup libraryPath and doesFileExist libraryPath and getFileSize libraryPath>1000)
    local shelfSetup=caCreateArrangement();caBindReceivers shelfSetup #(shelf[1]);shelfSetup.name="WF_Shelf_Arrangement"
    caLoadAssetLibrary shelfSetup libraryPath
    local libraryRows=caAssetRows shelfSetup
    local invalidImportedRows=#()
    if libraryRows.count==11 do
        for row in libraryRows do if row[10] or(caAssetDetail shelfSetup row[1])[10]!=2 do append invalidImportedRows row
    caWCheck "Library import is explicit stored geometry with no live source references" (libraryRows.count==11 and invalidImportedRows.count==0)
    caWCheck "Import leaves first arrangement catalog unchanged" ((caAssetRows tvSetup).count==11)
    rejected=false;try(caLoadAssetLibrary shelfSetup(CA_TEST_OUTPUT+"missing.cyalib"))catch(rejected=true)
    caWCheck "Missing library rejects retaining complete catalog" (rejected and deepEqual libraryRows(caAssetRows shelfSetup) strictCompare:true)
    local importedID=libraryRows[1][1]
    local replacement=box name:"WF_Rebound_Original" width:60 length:40 height:120 pos:[9000,0,0]
    local beforeRebind=caAssetDetail shelfSetup importedID,beforeRebindSupport=caAssetSupport shelfSetup importedID,beforeRebindRevision=(caSetupSummary shelfSetup)[3]
    rejected=false;try(caRebindAsset shelfSetup importedID replacement)catch(rejected=true)
    caWCheck "Rebind rejects an incompatible preserved authored footprint without changing catalog source policy or revision" (rejected and(deepEqual beforeRebind(caAssetDetail shelfSetup importedID) strictCompare:true)and(deepEqual beforeRebindSupport(caAssetSupport shelfSetup importedID) strictCompare:true)and(caSetupSummary shelfSetup)[3]==beforeRebindRevision and(deepEqual libraryRows(caAssetRows shelfSetup) strictCompare:true))
    -- Portable numeric support is authoritative. Explicit reset requests a
    -- geometry-derived base before binding a differently sized replacement.
    caResetAssetSupport shelfSetup importedID
    local resetPolicy=(caAssetSupport shelfSetup importedID)[7]
    caWCheck "Explicit support reset restores automatic contact and top provenance" (resetPolicy.count==2 and not resetPolicy[1] and not resetPolicy[2])
    caRebindAsset shelfSetup importedID replacement
    caWCheck "Rebind imported geometry retains ID and installs exact scene source" ((caAssetDetail shelfSetup importedID)[1]==importedID and(caAssetDetail shelfSetup importedID)[10]==1 and(caAssetDetail shelfSetup importedID)[11]==replacement)
    caWCheck "Explicit reset permits original-size replacement geometry with a newly derived base" ((distance ((caAssetRows shelfSetup)[1][4]) [60,40,120])<0.001 and not(caAssetSupport shelfSetup importedID)[7][1] and not(caAssetSupport shelfSetup importedID)[7][2])
    delete replacement
    caWCheck "Deleted live source differs from intentionally embedded geometry" ((caAssetDetail shelfSetup importedID)[10]==3)
    caUseStoredAsset shelfSetup importedID
    caWCheck "Explicit stored-geometry command repairs missing provenance" ((caAssetDetail shelfSetup importedID)[10]==2)
    undo "WF remove unused imported asset" on(caRemoveAssets shelfSetup #(importedID) false)
    caWCheck "Unused asset removal updates only second catalog" ((caAssetRows shelfSetup).count==10 and(caAssetRows tvSetup).count==11)
    max undo
    caWCheck "Unused removal Undo restores complete catalog" ((caAssetRows shelfSetup).count==11)
    max redo
    caWCheck "Unused removal Redo restores successor" ((caAssetRows shelfSetup).count==10)
    -- Saved descriptive rules remain native data, never current source eligibility.
    local otherRules=caCategoryRules shelfSetup 1,rules=caCategoryRules tvSetup 1
    rules[1][2]=3;rules[1][3]=2;rules[1][4]=false
    caSetCategoryRules tvSetup 1 rules
    caWCheck "Native descriptive rule state remains bounded and owner-local" ((caCategoryRules tvSetup 1).count==11 and caWEqualRules otherRules(caCategoryRules shelfSetup 1))
    caResetCategoryRules tvSetup 1
    caWCheck "Explicit rule reset restores defaults" ((caCategoryRules tvSetup 1)[1][3]!=2)
    caSetCategoryRules tvSetup 1 rules
    caWCheck "All library edits leave original models transforms names and materials unchanged" (caWSameSources originals)

    caWRecord "STAGE actual unified Generate and native preview publication"
    caWOpen tvSetup
    caModifierUI.quantity.value=12;caModifierUI.spacing.value=18
    caModifierViewOwner.protectionControls.edgeGap.value=25
    caModifierUI.keepSeed.checked=true;caModifierViewOwner.dispatch #scale;caModifierUI.seedText.text="42"
    caWCheck "Actual Modify Generate accepts current drafts without Apply" (caModifierUI.generateButton.pressed())
    local first=caOutputRows tvSetup
    caWCheck "Generated bounded nonempty owned real nodes" (first.count>0 and first.count<=12 and first[1].count==9 and isValidNode first[1][9] and (getUserProp first[1][9] "CyrusArrangeGenerated")==true)
    caWCheck "Generate seed remains exact decimal UI text" (caModifierUI.seedText.text=="42" and(caPlacementSettings tvSetup)[1]==42L)
    caWCheck "Actual Repeat Generate preserves exact IDs and poses" (caModifierUI.generateButton.pressed() and caWEqualRows first(caOutputRows tvSetup))
    local originalSourcesPreserved=caWSameSources originals,outputRowsWithoutMaterials=#()
    if originalSourcesPreserved do
        for row in(caOutputRows tvSetup)do if row[9].material==undefined do append outputRowsWithoutMaterials row
    caWCheck "Generation preserves original scene sources and real output materials" (originalSourcesPreserved and outputRowsWithoutMaterials.count==0)
    local committed=caOutputRows tvSetup,candidate=caPreview tvSetup #()
    caWCheck "Native preview stages valid nonempty transient bounds without publication" ((caPreviewInfo tvSetup)[1] and(caPreviewInfo tvSetup)[2] and(caPreviewInfo tvSetup)[3]>0 and caWEqualRows committed(caOutputRows tvSetup))
    local bounds=caPreviewBounds tvSetup
    caPreview tvSetup #()
    caWCheck "Same preview inputs repeat all world bounds" (caWEqualPreview bounds(caPreviewBounds tvSetup))
    caClearPreview tvSetup
    caWCheck "Clear preview removes transient state retaining output" (not(caPreviewInfo tvSetup)[1] and caWEqualRows committed(caOutputRows tvSetup))
    caPreview tvSetup #()
    local raw=(caSetupSummary tvSetup)[9];raw[1]=43L;caSetArrangeSettings tvSetup raw
    caWCheck "Authored settings invalidate prior preview" (not(caPreviewInfo tvSetup)[2])
    rejected=false;try(caCommitPreview tvSetup)catch(rejected=true)
    caWCheck "Stale preview commit rejects retaining exact output" (rejected and caWEqualRows committed(caOutputRows tvSetup))
    caPreview tvSetup #()
    undo "WF commit native preview" on(caCommitPreview tvSetup)
    caWCheck "Valid preview commit publishes changed successor" (not(caWEqualRows committed(caOutputRows tvSetup)))
    caWOpen tvSetup;caModifierUI.keepSeed.checked=true;caModifierViewOwner.dispatch #scale;caModifierUI.generateButton.pressed()
    local beforeRemoval=caOutputRows tvSetup,usedID=beforeRemoval[1][2]
    rejected=false;try(caRemoveAssets tvSetup #(usedID) false)catch(rejected=true)
    caWCheck "In-use asset removal requires explicit output removal" (rejected and(caAssetRows tvSetup).count==11 and caWEqualRows beforeRemoval(caOutputRows tvSetup))
    undo "WF remove asset plus owned copies" on(caRemoveAssets tvSetup #(usedID) true)
    caWCheck "Explicit removal deletes only matching owned output and retains sources" ((caAssetRows tvSetup).count==10 and(caOutputRows tvSetup).count<beforeRemoval.count and caWSameSources originals)
    max undo
    caWCheck "One removal Undo restores full catalog and prior publication" ((caAssetRows tvSetup).count==11 and caWEqualRows beforeRemoval(caOutputRows tvSetup))
    local lockRow=(caOutputRows tvSetup)[1]
    modPanel.setPinStack true;select lockRow[9]
    caWCheck "Inline Protect selected captures one output" (caModifierViewOwner.protectionControls.lockSelected.pressed())
    local protectedRows=for row in(caOutputRows tvSetup)where row[7]collect row
    local protectedPlacementID=lockRow[1]
    caModifierUI.keepSeed.checked=false;caModifierViewOwner.dispatch #scale
    local protectedGenerateSucceeded=caModifierUI.generateButton.pressed(),generatedProtectedRows=#()
    if protectedGenerateSucceeded do
        for row in(caOutputRows tvSetup)do if row[7]do append generatedProtectedRows row
    caWCheck "Fresh Generate retains protected IDs poses and source records" (protectedGenerateSucceeded and caWEqualRowsByID protectedRows generatedProtectedRows)
    local currentLockRows=#()
    for row in(caOutputRows tvSetup)do if row[1]==protectedPlacementID do append currentLockRows row
    if currentLockRows.count!=1 do throw "Protected stable ID must resolve to one current output before Unprotect."
    local currentLockRow=currentLockRows[1]
    if not(isValidNode currentLockRow[9]) do throw "Protected stable ID has no valid current output node."
    select currentLockRow[9]
    if not(caWCheck "Unprotect selection is the current protected binding for the saved stable ID" (currentLockRow[7] and isValidNode currentLockRow[9] and selection.count==1 and selection[1]==currentLockRow[9])) do throw "Unprotect must target the current protected output binding."
    caWCheck "Inline Unprotect selected releases saved protection" (caModifierViewOwner.protectionControls.unlockSelected.pressed())
    local regions=caRegionRows tvSetup,chosen=regions[1][1]
    local untouched=for row in(caOutputRows tvSetup)where row[3]!=chosen collect row
    raw=(caSetupSummary tvSetup)[9];raw[1]+=1L;caSetArrangeSettings tvSetup raw
    caGenerate tvSetup #(chosen)
    local regeneratedUnselectedRows=#()
    for row in(caOutputRows tvSetup)do if row[3]!=chosen do append regeneratedUnselectedRows row
    caWCheck "Explicit raw selective regeneration retains all unselected-region records" (caWEqualRowsByID untouched regeneratedUnselectedRows)
    local beforeUndo=caOutputRows tvSetup
    undo "WF regenerate accepted native seed" on(caGenerateVariation tvSetup ((caSetupSummary tvSetup)[9]) #() true)
    local afterUndo=caOutputRows tvSetup
    max undo
    caWCheck "Generate Undo restores complete prior result" (caWEqualRows beforeUndo(caOutputRows tvSetup))
    max redo
    caWCheck "Generate Redo restores complete accepted successor" (caWEqualRows afterUndo(caOutputRows tvSetup))
    local complete=caOutputRows tvSetup
    rejected=false;try(caGenerate tvSetup #(2147483647L))catch(rejected=true)
    caWCheck "Unknown region rejects retaining full publication" (rejected and caWEqualRows complete(caOutputRows tvSetup))
    raw=(caSetupSummary tvSetup)[9];raw[10]=0.1;caSetArrangeSettings tvSetup raw
    rejected=false;try(caGenerate tvSetup #())catch(rejected=true)
    caWCheck "Over-budget raw grid rejects retaining full publication" (rejected and caWEqualRows complete(caOutputRows tvSetup))
    raw[10]=25;caSetArrangeSettings tvSetup raw
    local savedGUID=(caSetupSummary tvSetup)[1],savedRows=caOutputRows tvSetup
    max create mode
    local scene=CA_TEST_OUTPUT+"arrange-workflow.max"
    caWCheck "Native arrangement and catalog scene saves" (saveMaxFile scene quiet:true)
    caWCheck "Native arrangement scene reopens" (loadMaxFile scene quiet:true useFileUnits:true)
    tvSetup=getNodeByName "WF_TV_Arrangement" exact:true
    caWCheck "GUID full catalog placements and descriptive rules roundtrip" ((caSetupSummary tvSetup)[1]==savedGUID and(caAssetRows tvSetup).count==11 and caWEqualRows savedRows(caOutputRows tvSetup) and(caCategoryRules tvSetup 1)[1][2]==3)
    local passive=caOutputRows tvSetup
    caWOpen tvSetup
    caWCheck "Mounting reopened Modify remains passive" (caWEqualRows passive(caOutputRows tvSetup) and caTick()==0)
    -- Raw Live remains an explicitly authored API contract, not another popup.
    raw=(caSetupSummary tvSetup)[9];raw[11]=true;caSetArrangeSettings tvSetup raw
    caWCheck "Loading and authoring Live remains disarmed before Generate" (caTick()==0)
    caGenerate tvSetup #()
    caWCheck "Explicit raw Generate arms Live and consumes pending work" (caTick()==0)
    local beforeLive=caOutputRows tvSetup
    move (getNodeByName "CA_FIXTURE_TV_Assembly" exact:true) [100,0,0]
    caWCheck "Live services exactly one relevant receiver change" (caTick()==1 and not(caWEqualRows beforeLive(caOutputRows tvSetup)))
    caWCheck "Repeated warm Live tick avoids rebuild" (caTick()==0)
    local beforeUnrelated=caOutputRows tvSetup,unrelated=box name:"WF_Unrelated" width:1 length:1 height:1 pos:[10000,10000,10000]
    move unrelated [13,0,0]
    caWCheck "Unrelated edits do not rebuild or change existing outputs" (caTick()==0 and caWEqualRows beforeUnrelated(caOutputRows tvSetup))
    raw=(caSetupSummary tvSetup)[9];raw[11]=false;caSetArrangeSettings tvSetup raw
    caWCheck "Live can be explicitly disarmed" (caTick()==0)
    caWRecord "LIMIT preview/library/support/region/Live checks use explicit native APIs. Current artist actions are tested only through mounted unified Modify; retired popup formatting is not qualified."
    max create mode;true
)
try (caWRun()) catch
(
    caWFailures += 1
    caWRecord ("EXCEPTION "+(getCurrentException() as string))
    caWRecord ("ERROR_SOURCE "+(getErrorSourceFileName() as string)+":"+(getErrorSourceFileLine() as string))
    caWRecord ("STACK "+(getCurrentExceptionStackTrace() as string))
)
caWFinished = true
caWWrite()
