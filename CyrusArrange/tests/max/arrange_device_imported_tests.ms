/* Owned complete-device fixture; helpers are shared with packing acceptance. */
global CA_TEST_ROOT,CA_TEST_OUTPUT,CA_AUTO_SHOW_UI,CyrusArrange,caModifierUI,caModifierViewOwner,CoronaShadows
global caDIMakeAppliance,caDIMakeCabinet,caDIBox,caDILog,caDIPasses,caDIFailures,caDIFinished
global caDIWrite,caDICheck,caDIEqual,caDIPose,caDIGenerate,caDIMesh,caDIBounds,caDIHash,caDISignature,caDIPlace,caDIOpen,caDIVisual,caDIConfigure,caDIExport,caDIImport,caDIRender
fileIn(CA_TEST_ROOT+"tests/max/device_imported_helpers.ms")
fn caDIRun=
(
    resetMaxFile #noPrompt;units.SystemType=#millimeters;units.SystemScale=1;CA_AUTO_SHOW_UI=false
    for script in #("CyrusArrange.ms","ArrangeAssets.ms","ArrangeRegions.ms","ArrangeCollision.ms","ArrangeWorkflow.ms","ArrangeModifier.ms")do fileIn(CA_TEST_ROOT+"scripts/"+script)
    fileIn(CA_TEST_ROOT+"tests/max/device_imported_fixture.ms")
    caDICheck "Exact current native and actual normal Max2027"(caVersion()=="0.3.2"and(maxVersion())[1]==29000 and not maxOps.isInNonInteractiveMode())
    local source=caDIMakeAppliance(),cabinet=caDIMakeCabinet(),owner=caCreateArrangement();owner.name="DEVICE_Cabinet_Arrange"
    local original=caDISignature source,m=caDIMesh source,b=caDIBounds m
    caDICheck "Complete appliance has literal dimensions materials and detailed authored topology"(m.numverts>700 and m.numfaces>1400 and distance(b[2]-b[1]) [460,500,560]<.02 and source.material.numsubs==5);delete m
    caBindReceivers owner cabinet[1];caDICheck "The cabinet opens its actual native Modify view"(caDIOpen owner)
    caDICheck "Inline props and Keep clear bind without generating"(caModifierViewOwner.dispatch #addProps data:#(source)and caModifierViewOwner.dispatch #addObstacles data:cabinet[2]and(caOutputRows owner).count==0)
    caDIConfigure owner 1 true 50
    local start=timeStamp(),generated=caDIGenerate owner,originalOK=generated and(caOutputRows owner).count==1 and(caOutputRows owner)[1][6]==1.0
    if not originalOK do(caDIExport "cabinet-original-witness"cabinet[1]cabinet[2]source owner;saveMaxFile(CA_TEST_OUTPUT+"Cabinet-Original-Failure-Witness.max")quiet:true)
    caDICheck "Original size wins in the tall compartment before any fit fallback"originalOK
    append caDILog("MEASURE cabinet_original_generate_ms="+((timeStamp()-start)as string));caDIWrite()
    local row=(caOutputRows owner)[1]
    caDICheck "The complete original appliance is inside the tall cabinet opening"(row[4].x>-1970 and row[4].x< -1370 and abs(row[4].z-80)<.03 and caDIVisual source owner)
    caDIExport "cabinet-original"cabinet[1]cabinet[2]source owner
    local blocker=caDIBox "DEVICE_Tall_Compartment_Occupant" [-1970,-300,80] [-1370,300,750](standardMaterial name:"DEVICE_Occupied_Space"diffuse:(color 75 80 90))
    append cabinet[2]blocker
    caDICheck "Inline Keep clear occupies the tall compartment"(caModifierViewOwner.dispatch #addObstacles data:#(blocker))
    caDIConfigure owner 2 true 60
    start=timeStamp();caDICheck "Two complete appliances fit the remaining short compartments"(caDIGenerate owner and(caOutputRows owner).count==2)
    append caDILog("MEASURE cabinet_fit_generate_ms="+((timeStamp()-start)as string));caDIWrite()
    local scales=true;for row in(caOutputRows owner)do if row[6]<.6 or row[6]>.715 do scales=false
    caDICheck "Uniform fit sizes respect actual height clearance and preserve all appearance"(scales and caDIVisual source owner)
    caDIExport "cabinet-fit"cabinet[1]cabinet[2]source owner
    local accepted=caPlacementSettings owner,poses=caDIPose owner
    caDICheck "Repeat seed reproduces complete fitted appliance poses"(caDIGenerate owner and caDIEqual poses(caDIPose owner))
    caModifierViewOwner.scaleControls.minimumScale.value=100
    caDICheck "A forbidden minimum leaves two honest unfilled copies"(caDIGenerate owner and(caOutputRows owner).count==0 and findString caModifierUI.statusText.text "2 unfilled"!=undefined)
    max undo
    caDICheck "Undo restores the preceding complete fitted result and every setting"(caDIEqual accepted(caPlacementSettings owner)and caDIEqual poses(caDIPose owner))
    max redo
    caDICheck "Redo restores the honestly unfilled result"((caOutputRows owner).count==0)
    max undo;caDIOpen owner;caModifierUI.keepSeed.checked=true;caModifierUI.keepSeed.changed true
    caModifierViewOwner.scaleControls.randomScale.checked=true;caModifierViewOwner.scaleControls.randomScale.changed true
    caModifierViewOwner.scaleControls.minimumScale.value=60;caModifierViewOwner.scaleControls.maximumScale.value=70
    caDICheck "Random size combined with fit still places two complete appliances"(caDIGenerate owner and(caOutputRows owner).count==2 and caDIVisual source owner)
    caDIExport "cabinet-random"cabinet[1]cabinet[2]source owner
    accepted=caPlacementSettings owner;poses=caDIPose owner
    caModifierViewOwner.scaleControls.minimumScale.value=110;caModifierViewOwner.scaleControls.maximumScale.value=80
    caDICheck "Rejected scale drafts retain accepted settings seed and all complete outputs"(not(caDIGenerate owner)and caDIEqual accepted(caPlacementSettings owner)and caDIEqual poses(caDIPose owner))
    caDIOpen owner
    local imported=#(caDIImport "Coffee_Table_05" "151abb1fd20b3c1f2a8d8e844162a6318373baa0596e9d7d6c7aaccc97900f64" "1a5e47777df109ab9982542e14709f79b64d1eabfa859c59e2e5ef8a3aa82675" [1000,0,0],caDIImport "Coffee_Table_06" "581f19c1626321edbb785e897dcb604409f35ae48aa47310e168ae071f3b9c58" "477756151d93712f11899f0adcd1d7febd0157c213f09585229a2a9ad1afb9cc" [3000,0,0])
    local signatures=(for item in imported collect(caDISignature item[1])),owners=#(),tableObstacles=#()
    for index=1 to imported.count do
    (
        local table=imported[index][1],setup=caCreateArrangement();setup.name="DEVICE_Table_Arrange_"+(index as string);append owners setup
        caBindReceivers setup #(table);caDICheck "Imported receiver mounts its actual Modify controls"(caDIOpen setup)
        caDICheck "Inline bulk prop binding accepts the complete appliance on imported furniture"(caModifierViewOwner.dispatch #addProps data:#(source))
        caDIConfigure setup (if index==1 then 1 else 2)false 50
        caDIExport(if index==1 then "imported-two-level-input"else "imported-rim-input")#(table)#()source setup
        start=timeStamp();local importedGenerated=caDIGenerate setup,importedOK=importedGenerated and(caOutputRows setup).count==(if index==1 then 1 else 2)and caDIVisual source setup
        if not importedOK do(caDIExport(if index==1 then "imported-upper-witness"else "imported-rim-witness")#(table)#()source setup;saveMaxFile(CA_TEST_OUTPUT+"Imported-Original-Failure-Witness.max")quiet:true)
        caDICheck "Complete original-size devices generate on actual imported support geometry"importedOK
        append caDILog("MEASURE imported_"+(index as string)+"_original_generate_ms="+((timeStamp()-start)as string));caDIWrite()
        caDIExport(if index==1 then "imported-two-level-original"else "imported-rim-original")#(table)#()source setup
        if index==1 do
        (
            local meshValue=caDIMesh table,bounds=caDIBounds meshValue;delete meshValue
            local cap=caDIBox "DEVICE_Imported_Upper_Space_Occupant" [bounds[1].x-100,bounds[1].y-100,bounds[2].z] [bounds[2].x+100,bounds[2].y+100,bounds[2].z+1000]blocker.material
            cap.renderable=false;append tableObstacles cap
            caDICheck "Inline obstacle restricts placement to the imported lower space"(caModifierViewOwner.dispatch #addObstacles data:#(cap))
            caDIConfigure setup 4 true 50
            start=timeStamp();local lowerGenerated=caDIGenerate setup,lowerOK=lowerGenerated and(caOutputRows setup).count==4 and caDIVisual source setup
            if not lowerOK do(caDIExport "imported-lower-witness"#(table)#(cap)source setup;saveMaxFile(CA_TEST_OUTPUT+"Imported-Lower-Failure-Witness.max")quiet:true)
            caDICheck "Four complete fitted devices use the actual imported lower shelf"lowerOK
            append caDILog("MEASURE imported_lower_fit_generate_ms="+((timeStamp()-start)as string));caDIWrite()
            caDIExport "imported-two-level-fit"#(table)#(cap)source setup
        )
    )
    local unchanged=caDIEqual original(caDISignature source)
    for i=1 to imported.count do if not(caDIEqual signatures[i](caDISignature imported[i][1]))or caDIHash imported[i][2]!=imported[i][3]or caDIHash imported[i][4]!=imported[i][5]do unchanged=false
    caDICheck "Original device imported receivers material roots UVs and external files remain unchanged"unchanged
    caDIRender()
    local scene=CA_TEST_OUTPUT+"CyrusArrange-Device-Imported-032.max",allOwners=#(owner)+owners,saved=for n in allOwners collect #(n.name,caPlacementSettings n,caDIPose n)
    caDICheck "Complete cabinet and imported furniture scene saves"(saveMaxFile scene quiet:true)
    loadMaxFile scene quiet:true useFileUnits:true
    local restored=true;for entry in saved do(local n=getNodeByName entry[1];if not isValidNode n or not(caDIEqual entry[2](caPlacementSettings n))or not(caDIEqual entry[3](caDIPose n))do restored=false)
    caDICheck "Reopen restores all three independent arrangements and complete output poses"restored
    for entry in saved do
    (
        local n=getNodeByName entry[1];caDIOpen n;caModifierUI.keepSeed.checked=true;caModifierUI.keepSeed.changed true
        caDICheck "Each reopened Modify Generate repeats its accepted complete-device result"(caDIGenerate n and caDIEqual entry[3](caDIPose n))
    )
    append caDILog "LIMIT: static upright complete modeled appliance and two supplied imported furniture models. Independent actual-mesh proof required; no artist profile, dynamics or mouse-pick qualification."
    true
)
try(caDIRun())catch(caDIFailures+=1;append caDILog("EXCEPTION "+(getCurrentException()as string));append caDILog("ERROR_SOURCE "+(getErrorSourceFileName()as string)+":"+(getErrorSourceFileLine()as string));append caDILog("STACK "+(getCurrentExceptionStackTrace()as string)))
caDIFinished=true;caDIWrite()
