/* Disposable Max2027 host only. Original procedural fixtures; actual native Modify UI + native bulk transactions. */
global CA_TEST_ROOT, CA_TEST_OUTPUT, CA_AUTO_SHOW_UI
global caModifierUI,caModifierViewOwner,CyrusArrange,caFocusArrange,caVersion,caReadExactSeed,caBWRequired=#()
global caCreateSetup,caSceneSetups,caSetupSummary,caRegisterAssets,caCreatePropGroup,caAssetRows,caAssetDetail
global caUpdateAsset,caRemoveAssets,caOutputRows,caCompositionRows,caAnalyzeSetup,caRegionRows,caSetRegionRules
global caSetArrangeSettings,caSetCollisionScope,caGenerate,caGenerateVariation,caTick
global caFxBox,caFxTVConsole,caFxOpenShelf
global caBWLog=#(),caBWPasses=0,caBWFailures=0,caBWFinished=false,caBWContext="entry"
global caBWWrite,caBWNote,caBWCheck,caBWRequire,caBWEqual,caBWClose,caBWMaterial,caBWLeaf,caBWTree,caBWTrees
global caBWAssets,caBWRecords,caBWState,caBWID,caBWRoots,caBWFailBatch,caBWPrepare,caBWOnly
global caBWBounds,caBWLeafBounds,caBWOverlap,caBWPhysical,caBWGenerate,caBWRun,caBWCapture,caBWLeaves

fn caBWWrite =
(
    local f=createFile(CA_TEST_OUTPUT+"result.txt")
    format "% passes=% failures=%\n" (if caBWFinished then(if caBWFailures==0 then"SUCCESS"else"ERROR")else"RUNNING") caBWPasses caBWFailures to:f
    for line in caBWLog do format "%\n" line to:f
    close f
)
fn caBWNote text=(append caBWLog text;caBWWrite())
fn caBWCheck label value=(if value then(caBWPasses+=1;caBWNote("PASS "+label))else(caBWFailures+=1;caBWNote("FAIL "+label+" ["+caBWContext+"]"));value)
fn caBWRequire label value=(caBWCheck label value;if not value do throw("Bulk fixture prerequisite: "+label);value)
fn caBWEqual a b=(deepEqual a b strictCompare:true)
fn caBWClose = (modPanel.setPinStack false;max create mode)
fn caBWOpen setup =
(
    max modify mode;modPanel.setPinStack false;select setup
    modPanel.setCurrentObject setup.modifiers[1] node:setup ui:true
    windows.processPostedMessages throttle:false sendQtPostedEvents:true doProgressiveRendering:false
    caBWRequire "Actual native Modify view mounts this document" (caModifierUI!=undefined and caModifierUI.hwnd!=0 and caModifierUI.currentSetup()==setup)
    true
)
fn caBWSetRequired setup =
(
    local id=undefined
    for row in caBWRequired where row[1]==setup do id=row[2]
    if id!=undefined do caModifierUI.showMinimumDraft #(#(id,8))
    -- Raw caCreateSetup deliberately retains Fill; this current UI fixture
    -- explicitly chooses Quantity before reserving its eight-copy target.
    caModifierUI.amountMode.selection=1;caModifierViewOwner.amountChanged 1
    caModifierUI.quantity.value=8
    true
)
fn caBWCapture panel filename =
(
    local imageValue=undefined
    try
    (
        imageValue=windows.snapshot panel captureScreenPixels:false gammaCorrect:false
        imageValue.filename=CA_TEST_OUTPUT+filename
        save imageValue;close imageValue
        caBWNote("UI_CAPTURE "+filename+" owned rollout; image requires independent visual inspection")
    )
    catch
    (
        if imageValue!=undefined do try(close imageValue)catch()
        caBWNote("UI_CAPTURE_DIAGNOSTIC "+filename+" "+(getCurrentException()as string))
    )
)
fn caBWLeaves node =
(
    local result=#()
    if isGroupHead node then
    (
        for child in node.children do join result(caBWLeaves child)
    )
    else append result node
    result
)
fn caBWLeaf material id =
(
    local value=material
    if material!=undefined and isProperty material #materialIDList do
    (
        value=undefined
        for i=1 to material.materialIDList.count where material.materialIDList[i]==id do value=material.materialList[i]
    )
    value
)
fn caBWMaterial material =
(
    if material==undefined then #(false)
    else if isProperty material #materialIDList then
    (
        local ids=for id in material.materialIDList collect id
        local children=for child in material.materialList collect caBWMaterial child
        #((classOf material)as string,material.name,ids,children)
    )
    else
    (
        local c=material.diffuse
        #((classOf material)as string,material.name,[c.r,c.g,c.b],material.opacity)
    )
)
fn caBWTree node identities:true =
(
    if not isValidNode node do throw "Source tree contains a deleted node."
    local vertices=#(),faces=#()
    if not(isGroupHead node) do
    (
        local meshValue=snapshotAsMesh node
        vertices=for i=1 to meshValue.numverts collect(getVert meshValue i)
        faces=for i=1 to meshValue.numfaces collect #((getFace meshValue i),(getFaceMatID meshValue i),(getFaceSmoothGroup meshValue i))
    )
    local children=for child in node.children collect(caBWTree child identities:identities)
    #(node.name,(if node.parent==undefined then""else node.parent.name),(copy node.transform),
      (isGroupHead node),(isGroupMember node),(if isGroupHead node then isOpenGroupHead node else false),
      node.isHidden,vertices,faces,(caBWMaterial node.material),children,(if identities then getHandleByAnim node else 0L))
)
fn caBWTrees roots identities:true=(for n in roots collect(caBWTree n identities:identities))
fn caBWAssets setup references:true =
(
    local values=#()
    for row in(caAssetRows setup) do
    (
        local d=caAssetDetail setup row[1]
        local source=if references then d[11] else(if isValidNode d[11] then d[11].name else undefined)
        append values #(row,#(d[1],d[2],d[3],d[4],d[5],d[6],d[7],d[8],d[9],d[10],source,d[12],d[13]))
    )
    values
)
fn caBWRecords setup=(for row in(caOutputRows setup) collect #(row[1],row[2],row[3],row[4],row[5],row[6],row[7],row[8]))
fn caBWState setup =
(
    local s=caSetupSummary setup
    local handles=for row in(caOutputRows setup) collect(if isValidNode row[9] then getHandleByAnim row[9] else undefined)
    -- Error/dirty/cache diagnostics and monotonic ID high-water are not authored rollback state.
    #(s[1],s[3],s[4],s[5],s[9],(caBWAssets setup),(caBWRecords setup),handles,(caCompositionRows setup),(caRegionRows setup),(caPlacementSettings setup),(caPropMinimums setup))
)
fn caBWID setup source =
(
    local result=undefined
    for row in(caAssetRows setup) where(caAssetDetail setup row[1])[11]==source do result=row[1]
    result
)
fn caBWRoots setup ids=(for id in ids collect(caAssetDetail setup id)[11])
fn caBWFailBatch label setup other sources mode:0 =
(
    caBWContext=label
    local before=caBWState setup,otherBefore=caBWState other,nodeCount=objects.count,rejected=false
    try(if mode==0 then caRegisterAssets setup sources 7 else caCreatePropGroup setup sources "BW_FORBIDDEN_COPY" 7)catch(rejected=true)
    caBWCheck(label+" rejects the complete batch") rejected
    caBWCheck(label+" retains both authored documents and actual output handles") (caBWEqual before(caBWState setup) and caBWEqual otherBefore(caBWState other) and objects.count==nodeCount)
)
fn caBWPrepare setup height category =
(
    caAnalyzeSetup setup
    local kept=0
    for row in(caRegionRows setup) do
    (
        local keep=abs(row[5].z-height)<0.02 and abs(row[6].z-height)<0.02
        if keep do kept+=1
        caSetRegionRules setup row[1] "Bulk workflow surface" "Known top" 2 64 1.0 false (not keep) [0,-1,0]
    )
    caBWRequire "One analytic board is enabled for this furniture fixture" (kept==1)
    local s=(caSetupSummary setup)[9]
    s[1]=123456789L;s[2]=0.2;s[3]=15.0;s[4]=5.0;s[5]=0.0;s[6]=0.0;s[7]=0.0;s[8]=2;s[9]=category;s[10]=25.0;s[11]=false
    caSetArrangeSettings setup s
)
fn caBWOnly setup assetID category =
(
    -- Geometry placement does not filter source tags. Reserve this full eight-copy
    -- target through the actual minimum draft; other registrations remain intact.
    local found=false
    for row in caBWRequired where row[1]==setup do(row[2]=assetID;found=true)
    if not found do append caBWRequired #(setup,assetID)
    true
)
fn caBWBounds node=(nodeGetBoundingBox node(matrix3 1))
fn caBWLeafBounds node =
(
    -- A Max group head is a helper, not a mesh. Its display bounds are not the
    -- physical union required by this literal-geometry oracle.
    local lower=[1e30,1e30,1e30],upper=[-1e30,-1e30,-1e30],leaves=caBWLeaves node
    if leaves.count==0 do throw "Copied group has no geometric leaves."
    for leaf in leaves do
    (
        if (superClassOf leaf)!=GeometryClass or not leaf.renderable do throw "Literal copied-group fixture requires renderable geometry leaves."
        local b=caBWBounds leaf
        for axis=1 to 3 do(lower[axis]=amin #(lower[axis],b[1][axis]);upper[axis]=amax #(upper[axis],b[2][axis]))
    )
    #(lower,upper)
)
fn caBWOverlap a b =
(
    (amin #(a[2].x,b[2].x))-(amax #(a[1].x,b[1].x))>0.02 and
    (amin #(a[2].y,b[2].y))-(amax #(a[1].y,b[1].y))>0.02 and
    (amin #(a[2].z,b[2].z))-(amax #(a[1].z,b[1].z))>0.02
)
fn caBWPhysical setup groupID boardMin boardMax height obstacle =
(
    local rows=caOutputRows setup
    local contact=rows.count>0,fullSize=true,geometry=true,materials=true,separation=true,bounds=#()
    local expected=#()
    for spec in #(#([-65,-20,0],[-5,20,35]),#([25,-15,0],[65,15,55])) do
        for x in #(spec[1].x,spec[2].x) do for y in #(spec[1].y,spec[2].y) do for z in #(spec[1].z,spec[2].z) do append expected [x,y,z]
    for row in rows do
    (
        if not isValidNode row[9] or row[2]!=groupID then(contact=false;geometry=false)
        else
        (
            local n=row[9],b=caBWBounds row[9],size=b[2]-b[1],yaw=mod(row[5]+360.0)360.0
            local quarter=(abs(yaw)<0.0001 or abs(yaw-90)<0.0001 or abs(yaw-180)<0.0001 or abs(yaw-270)<0.0001)
            local sideways=abs(yaw-90)<0.0001 or abs(yaw-270)<0.0001
            if not quarter or abs(row[6]-1.0)>0.000001 or abs(size.z-55)>0.02 or abs(size.x-(if sideways then 40 else 130))>0.02 or abs(size.y-(if sideways then 130 else 40))>0.02 do fullSize=false
            if row[8]!=0 or abs(b[1].z-height)>0.02 or b[1].x<boardMin.x+4.98 or b[2].x>boardMax.x-4.98 or b[1].y<boardMin.y+4.98 or b[2].y>boardMax.y-4.98 do
            (
                contact=false
                caBWNote("PHYSICAL_BOARD id="+(row[1]as string)+" region="+(row[3]as string)+" parent="+(row[8]as string)+" bounds="+(b as string)+" expectedMin="+(boardMin as string)+" expectedMax="+(boardMax as string)+" expectedHeight="+(height as string)+" acceptedEdge="+((caPlacementSettings setup)[6]as string)+" acceptedGrid="+((caSetupSummary setup)[9][10]as string))
            )
            if caBWOverlap b(caBWBounds obstacle) do separation=false
            append bounds b
            -- Output is a plain TriObject. Apply its ObjectTM exactly once, then
            -- independently remove the recorded yaw/anchor to compare literal boxes.
            local m=n.mesh,canonical=#(),seen=#{},redFaces=0,blueFaces=0
            if m.numverts!=16 or m.numfaces!=24 then geometry=false
            else
            (
                for i=1 to m.numverts do
                (
                    local world=(getVert m i)*n.objectTransform,d=world-row[4]
                    local p=[(cos row[5])*d.x+(sin row[5])*d.y,-(sin row[5])*d.x+(cos row[5])*d.y,d.z]
                    append canonical p
                    local found=0
                    for k=1 to expected.count where distance p expected[k]<0.03 do found=k
                    if found==0 then geometry=false else seen[found]=true
                )
                if seen.numberSet!=16 do geometry=false
                for face=1 to m.numfaces do
                (
                    local f=getFace m face
                    local center=(canonical[f.x as integer]+canonical[f.y as integer]+canonical[f.z as integer])/3.0
                    local material=caBWLeaf n.material(getFaceMatID m face)
                    if material==undefined then materials=false
                    else
                    (
                        local c=material.diffuse,actual=[c.r,c.g,c.b],wanted=if center.x<0 then [210,55,45] else [35,90,210]
                        if distance actual wanted>0.01 do materials=false
                    )
                    if center.x<0 then redFaces+=1 else blueFaces+=1
                )
                if redFaces!=12 or blueFaces!=12 do materials=false
            )
        )
    )
    for i=1 to bounds.count do for j=i+1 to bounds.count where j<=bounds.count do if caBWOverlap bounds[i] bounds[j] do separation=false
    if not contact do for region in(caRegionRows setup)do caBWNote("PHYSICAL_REGION id="+(region[1]as string)+" min="+(region[5]as string)+" max="+(region[6]as string)+" excluded="+(region[12]as string))
    caBWCheck "Nonempty actual grouped props have full-scale quarter-turn dimensions" (rows.count>0 and fullSize)
    caBWCheck "Every complete generated footprint stays on the known board with clearance" contact
    caBWCheck "All sixteen literal component corners survive group copying and placement" geometry
    caBWCheck "All twenty-four faces retain the correct original component colors" materials
    caBWCheck "Actual generated bounds avoid existing decor and every other accessory" separation
    contact and fullSize and geometry and materials and separation
)
fn caBWGenerate setup =
(
    caBWOpen setup;caBWSetRequired setup
    caBWRequire "Actual inline Generate handler succeeds" (caModifierUI.generateButton.pressed())
    true
)

fn caBWRun =
(
    caBWClose();resetMaxFile #noPrompt
    units.SystemType=#millimeters;units.SystemScale=1;CA_AUTO_SHOW_UI=false
    fileIn(CA_TEST_ROOT+"scripts/CyrusArrange.ms")
    fileIn(CA_TEST_ROOT+"scripts/ArrangeAssets.ms")
    for script in #("ArrangeRegions.ms","ArrangeCollision.ms","ArrangeWorkflow.ms","ArrangeModifier.ms") do fileIn(CA_TEST_ROOT+"scripts/"+script)
    fileIn(CA_TEST_ROOT+"tests/max/fixtures.ms")
    caBWRequire "Dedicated exact 0.3.2 normal Max2027 host" ((maxVersion())[1]==29000 and caVersion()=="0.3.2" and not maxOps.isInNonInteractiveMode())
    caBWContext="original fixture construction"
    local tv=caFxTVConsole grouped:true,shelf=caFxOpenShelf offsetMM:[2600,0,0] grouped:true
    tv[1].name="CA_BULK_TV_FURNITURE";shelf[1].name="CA_BULK_SHELF_FURNITURE"
    local setupA=caCreateSetup #(tv[1])1,setupB=caCreateSetup #(shelf[1])2
    setupA.name="CA_BULK_SETUP_TV";setupB.name="CA_BULK_SETUP_SHELF"
    local red=box name:"CA_BULK_ORIGINAL_RED" width:60 length:40 height:35 pos:[4500,0,0]
    local blue=box name:"CA_BULK_ORIGINAL_BLUE" width:40 length:30 height:55 pos:[4580,0,0]
    red.material=standardMaterial name:"BW_RED_MATERIAL" diffuse:(color 210 55 45)
    blue.material=standardMaterial name:"BW_BLUE_MATERIAL" diffuse:(color 35 90 210)
    local green=box name:"CA_BULK_NESTED_GREEN" width:30 length:20 height:40 pos:[4500,100,0]
    local amber=box name:"CA_BULK_NESTED_AMBER" width:20 length:25 height:20 pos:[4540,100,0]
    green.material=standardMaterial name:"BW_GREEN_MATERIAL" diffuse:(color 45 170 70)
    amber.material=standardMaterial name:"BW_AMBER_MATERIAL" diffuse:(color 210 155 45)
    local inner=group #(green,amber)name:"CA_BULK_INNER_SOURCE"
    local cyan=box name:"CA_BULK_NESTED_CYAN" width:25 length:15 height:30 pos:[4500,140,0]
    cyan.material=standardMaterial name:"BW_CYAN_MATERIAL" diffuse:(color 35 165 180)
    local nested=group #(inner,cyan)name:"CA_BULK_NESTED_SOURCE"
    setGroupOpen nested true;setGroupOpen inner true
    local originals=#(red,blue,nested),originalBefore=caBWTrees #(red,blue,nested)
    caBWOpen setupA
    caModifierUI.quantity.value=17;caModifierUI.spacing.value=11
    modPanel.setPinStack true
    local raw=#(cyan,inner,blue,green,nested,red,amber)
    select raw
    local clock=(dotNetClass "System.Diagnostics.Stopwatch").StartNew()
    caBWRequire "Actual bulk Add accepts multiple original roots" (caModifierViewOwner.propControls.addSelection.pressed())
    clock.Stop()
    caBWNote("BULK_INTAKE scope=one_UI_command_not_general_benchmark rawNodes=7 expectedRoots=3 elapsedMS="+(clock.Elapsed.TotalMilliseconds as string))
    caBWRequire "Nested group plus descendants registers exactly three roots" ((caAssetRows setupA).count==3)
    local originalIDs=for n in originals collect(caBWID setupA n)
    caBWCheck "Original roots have distinct live source registrations" (findItem originalIDs undefined==0 and originalIDs[1]!=originalIDs[2] and originalIDs[2]!=originalIDs[3])
    caBWCheck "Bulk Add preserves main amount and spacing drafts" (caModifierUI.quantity.value==17 and abs(caModifierUI.spacing.value-11)<0.0001)
    caBWCheck "Bulk intake preserves all original hierarchy transforms meshes and materials" (caBWEqual originalBefore (caBWTrees originals))
    local afterAdd=caBWAssets setupA
    max undo
    caBWCheck "One Undo removes the entire bulk catalog addition" ((caAssetRows setupA).count==0 and caBWEqual originalBefore (caBWTrees originals))
    max redo
    caBWRequire "One Redo restores exact batch IDs metadata and source references" (caBWEqual afterAdd(caBWAssets setupA))
    -- First-run offscreen captures were blank; preserved as diagnostics, not retried or treated as visual evidence.
    local state=caBWState setupA
    local skipped=caRegisterAssets setupA #(red,blue,nested,green,red,inner)1
    local reversed=caRegisterAssets setupA #(inner,red,green,nested,blue,red)11
    caBWCheck "Duplicate and descendant arrays skip existing roots in stable order" (skipped[1].count==0 and skipped[2].count==3 and caBWEqual skipped reversed and caBWEqual state(caBWState setupA))
    select #(red,blue,nested)
    caBWCheck "Actual all-existing Add is a successful native no-op" (caModifierViewOwner.propControls.addSelection.pressed() and caBWEqual state(caBWState setupA))
    local extra=box name:"CA_BULK_EXTRA_ORIGINAL" width:70 length:35 height:25 pos:[4650,100,0]
    local beforeExisting=caAssetDetail setupA originalIDs[2]
    local mixed=caRegisterAssets setupA #(extra,blue,extra)1
    caBWRequire "Mixed fresh and existing intake adds exactly one root" (mixed[1].count==1 and mixed[2].count==1 and mixed[2][1]==originalIDs[2] and(caAssetRows setupA).count==4)
    caBWCheck "Mixed batch preserves existing metadata despite a different requested type" (caBWEqual beforeExisting(caAssetDetail setupA originalIDs[2]))
    append originals extra;append originalIDs mixed[1][1]

    caBWContext="copy reusable prop group and Undo"
    select #(red,blue);caModifierViewOwner.propControls.groupName.text="CA_BULK_REUSABLE_DECOR"
    local beforeGroup=caBWAssets setupA,countBefore=objects.count,rootsBefore=caBWTrees originals
    caBWRequire "Actual inline reusable group completion handler succeeds" (caModifierViewOwner.dispatch #groupProps data:#(red,blue))
    local copied=undefined,copiedID=undefined
    for row in(caAssetRows setupA) do
    (
        local source=(caAssetDetail setupA row[1])[11]
        if isValidNode source and source!=red and source!=blue and source!=nested and source!=extra do(copied=source;copiedID=row[1])
    )
    caBWRequire "Copied group is a distinct registered source with two copied leaves" (isValidNode copied and isGroupHead copied and copied.children.count==2 and copiedID!=undefined)
    local copiedTree=caBWTree copied,afterGroup=caBWAssets setupA
    caBWCheck "Group command adds exactly its own group and two copies" (objects.count==countBefore+3)
    caBWCheck "Grouping leaves originals and original source registrations untouched" (caBWEqual rootsBefore (caBWTrees originals))
    local helperBounds=caBWBounds copied,copiedBounds=caBWLeafBounds copied
    caBWNote("GROUP_BOUNDS helperMin="+(helperBounds[1]as string)+" helperMax="+(helperBounds[2]as string)+" meshLeafMin="+(copiedBounds[1]as string)+" meshLeafMax="+(copiedBounds[2]as string))
    caBWCheck "Copied group retains literal world extent" ((distance copiedBounds[1] [4470,-20,0])<0.02 and(distance copiedBounds[2] [4600,20,55])<0.02)
    max undo
    caBWCheck "One group Undo restores catalog and removes all copied nodes" (caBWEqual beforeGroup(caBWAssets setupA) and objects.count==countBefore and(findItem (objects as array) copied)==0)
    max redo
    copied=(caAssetDetail setupA copiedID)[11]
    caBWRequire "One group Redo restores complete source hierarchy material state and stable ID" (caBWEqual afterGroup(caBWAssets setupA) and caBWEqual copiedTree(caBWTree copied))
    caBWCheck "Group command retains main drafts" (caModifierUI.quantity.value==17 and abs(caModifierUI.spacing.value-11)<0.0001)
    caBWOpen setupB;modPanel.setPinStack true
    select copied
    caBWRequire "Same reusable source group adds through the second arrangement's inline Props" (caModifierViewOwner.propControls.addSelection.pressed() and(caAssetRows setupB).count==1)
    local copiedBID=caBWID setupB copied
    caBWCheck "Both documents refer to the same real source group" ((caAssetDetail setupA copiedID)[11]==copied and(caAssetDetail setupB copiedBID)[11]==copied)
    local secondBefore=caBWAssets setupB,d=caAssetDetail setupA copiedID
    caUpdateAsset setupA copiedID d[2] d[3] d[4] d[5] 2.0 d[7] d[8] d[9]
    caBWCheck "Editing one document's metadata does not mutate the reusable source or second catalog" (caBWEqual secondBefore(caBWAssets setupB) and caBWEqual copiedTree(caBWTree copied))
    local independent=instance red;independent.name="CA_BULK_INDEPENDENT_INSTANCE";independent.pos=[4700,0,0]
    local instanceResult=caRegisterAssets setupB #(independent)7
    caBWCheck "Independent node instance sharing geometry is a valid distinct source" (instanceResult[1].count==1 and(caAssetDetail setupB instanceResult[1][1])[11]==independent)
    local nestedBefore=caBWState setupB,nestedNodeCount=objects.count
    local nestedCopy=caCreatePropGroup setupB #(nested,extra) "BW_TEMP_NESTED_COPY" 7
    local clonedHead=undefined,innerHead=undefined
    for n in nestedCopy[1].children where isGroupHead n do clonedHead=n
    if isValidNode clonedHead do for n in clonedHead.children where isGroupHead n do innerHead=n
    caBWRequire "Copying an existing nested group retains both nested group levels" (isValidNode clonedHead and isValidNode innerHead and nestedCopy[1].children.count==2 and clonedHead.children.count==2 and innerHead.children.count==2)
    local copiedLeaves=caBWLeaves nestedCopy[1],literalCopies=true
    if copiedLeaves.count!=4 do literalCopies=false
    for source in #(green,amber,cyan,extra) do
    (
        local matches=0
        for leaf in copiedLeaves where caBWEqual(caBWBounds source)(caBWBounds leaf) and caBWEqual(caBWMaterial source.material)(caBWMaterial leaf.material) do matches+=1
        if matches!=1 do literalCopies=false
    )
    caBWCheck "Nested copied leaves keep all four original world extents and material values" literalCopies
    caBWCheck "Nested-copy command leaves complete original hierarchy untouched" (caBWEqual rootsBefore (caBWTrees originals))
    max undo
    caBWCheck "One native nested-copy Undo restores catalog and removes all seven copied nodes" (objects.count==nestedNodeCount and caBWEqual nestedBefore (caBWState setupB))

    caBWContext="real TV and shelf placement and Repeat seed"
    local obstacleA=box name:"CA_BULK_TV_EXISTING_SCREEN" width:600 length:40 height:360 pos:[0,180,600]
    local obstacleB=box name:"CA_BULK_SHELF_EXISTING_DECOR" width:80 length:80 height:100 pos:[2800,80,1330]
    obstacleA.material=standardMaterial name:"BW_SCREEN" diffuse:(color 25 25 30)
    obstacleB.material=standardMaterial name:"BW_KEEP_CLEAR" diffuse:(color 85 95 100)
    caSetCollisionScope setupA #(obstacleA)true;caSetCollisionScope setupB #(obstacleB)true
    caBWPrepare setupA 600 1;caBWPrepare setupB 1330 2
    caBWOnly setupA copiedID 1;caBWOnly setupB copiedBID 2
    local furnitureMin=#([-900,-225,600],[2030,-175,1330]),furnitureMax=#([900,225,600],[3170,175,1330])
    for entry in #(#(setupA,copiedID,obstacleA,1),#(setupB,copiedBID,obstacleB,2)) do
    (
        local owner=entry[1],id=entry[2],index=entry[4]
        caBWOpen owner;caBWSetRequired owner
        caModifierUI.keepSeed.checked=false;caModifierViewOwner.dispatch #scale
        caBWCheck "Fresh-variation mode hides and disables exact seed editing" (not caModifierUI.seedText.visible and not caModifierUI.seedText.enabled)
        local oldSeed=(caSetupSummary owner)[9][1]
        caModifierUI.seedText.text="hidden malformed seed must be ignored"
        caBWRequire "Fresh actual Generate ignores hidden seed draft" (caModifierUI.generateButton.pressed())
        caBWCheck "Fresh Generate commits a different nonnegative seed" ((caSetupSummary owner)[9][1]>=0 and(caSetupSummary owner)[9][1]!=oldSeed)
        caModifierUI.keepSeed.checked=true;caModifierViewOwner.dispatch #scale
        caBWCheck "Repeat seed exposes exact seed editing" (caModifierUI.seedText.visible and caModifierUI.seedText.enabled)
        caModifierUI.seedText.text="9223372036854775000"
        caBWRequire "Repeat mode accepts exact large Integer64 seed" (caModifierUI.generateButton.pressed())
        local storedSeed=(caSetupSummary owner)[9][1],typedSeed=9223372036854775000L
        local independentlyTypedSeed=9223372036854775807L-807L,convertedSeed=("9223372036854775000"as Integer64),parsedSeed=caReadExactSeed caModifierUI.seedText.text
        caBWNote("SEED_EXACT stored="+(storedSeed as string)+" storedClass="+((classOf storedSeed)as string)+" typedLiteral="+(typedSeed as string)+" maxMinus807="+(independentlyTypedSeed as string)+" stringCast="+(convertedSeed as string)+" stringCastClass="+((classOf convertedSeed)as string)+" UIreadSeed="+(parsedSeed as string)+" UItext="+caModifierUI.seedText.text)
        caBWCheck "Independent Integer64 literals agree exactly" (typedSeed==independentlyTypedSeed and(classOf typedSeed)==Integer64 and(classOf independentlyTypedSeed)==Integer64)
        caBWCheck "Full sixty-three-bit seed digits survive UI and native state" (storedSeed==typedSeed and parsedSeed==typedSeed and caModifierUI.seedText.text=="9223372036854775000")
        local logical=caBWRecords owner,groups=caCompositionRows owner
        caBWRequire "Repeated actual Generate succeeds" (caModifierUI.generateButton.pressed())
        caBWCheck "Kept seed repeats every ordered placement field and group" (caBWEqual logical(caBWRecords owner) and caBWEqual groups(caCompositionRows owner))
        caBWPhysical owner id furnitureMin[index] furnitureMax[index] furnitureMin[index].z entry[3]
        -- No repeat of the known-blank optional rollout snapshot.
    )

    caBWContext="atomic native admission and source-role guards"
    local valid=box name:"BW_TEMP_VALID" width:30 length:20 height:20 pos:[4900,0,0]
    local invalid=point name:"BW_TEMP_INVALID_NON_GEOMETRY" pos:[4900,50,0]
    caBWFailBatch "Valid then unsupported point" setupA setupB #(valid,invalid)
    caBWFailBatch "Valid then another setup's furniture child" setupA setupB #(valid,shelf[2][1])
    caBWFailBatch "Valid then setup owner" setupA setupB #(valid,setupB)
    caBWFailBatch "Valid then generated output" setupA setupB #(valid,(caOutputRows setupB)[1][9])
    caBWFailBatch "Valid then another setup's independent obstacle" setupA setupB #(valid,obstacleB)
    caBWFailBatch "Standalone member of registered nested group" setupA setupB #(green)
    caBWFailBatch "Group copy rejects another setup's furniture" setupA setupB #(valid,shelf[2][1])mode:1
    caBWFailBatch "Group copy rejects unsupported point without temporary-node leaks" setupA setupB #(valid,invalid)mode:1
    caBWFailBatch "Group copy needs two distinct normalized roots" setupA setupB #(nested,green)mode:1
    local parent=box name:"BW_TEMP_LINK_PARENT" width:10 length:10 height:10 pos:[5000,0,0]
    local child=box name:"BW_TEMP_LINK_CHILD" width:10 length:10 height:10 pos:[5020,0,0];child.parent=parent
    caBWFailBatch "Ungrouped linked parent and child are ambiguous" setupA setupB #(parent,child)
    local unchanged=caBWState setupA,rejected=false
    try(caRegisterAssets setupA #()7)catch(rejected=true)
    caBWCheck "Empty intake rejects without publication" (rejected and caBWEqual unchanged(caBWState setupA))
    rejected=false;try(caRegisterAssets setupA #(valid)0)catch(rejected=true)
    caBWCheck "Invalid category rejects without publication" (rejected and caBWEqual unchanged(caBWState setupA))
    local oversized=for i=1 to 257 collect(box name:("BW_TEMP_CAP_"+(i as string)) width:5 length:5 height:5 pos:[6000+i*10,0,0])
    caBWFailBatch "257 new source roots exceed normalized admission" setupA setupB oversized
    local remaining=257-(caAssetRows setupA).count
    local overflow=for i=1 to remaining collect oversized[i]
    caBWFailBatch "Existing catalog plus fresh roots exceeds 256 assets" setupA setupB overflow
    delete oversized;delete #(valid,invalid,parent,child)
    caBWCheck "Original sources are still completely unchanged after all rejected batches" (caBWEqual rootsBefore (caBWTrees originals))

    caBWContext="honest underfill without automatic shrinking"
    local tooWide=box name:"BW_TEMP_TOO_WIDE" width:2000 length:2000 height:55 pos:[7000,0,0]
    local wideOwner=caCreateArrangement();caBindReceivers wideOwner #(tv[1])
    local wideResult=caRegisterAssets wideOwner #(tooWide)7
    caBWRequire "Oversize physical asset registers at its true dimensions" (wideResult[1].count==1)
    caBWOpen wideOwner;caModifierUI.quantity.value=1
    caBWRequire "Too-wide scene generation completes truthfully" (caModifierUI.generateButton.pressed())
    local statusLines=filterString caModifierUI.statusText.text "\n"
    caBWCheck "No orientation forces or shrinks a 2000mm prop onto the board" ((caOutputRows wideOwner).count==0 and statusLines[1]=="0 placed / 1 requested" and statusLines[2]=="1 unfilled" and(caPlacementSettings wideOwner)[7]==false and(caPlacementSettings wideOwner)[8]==false)
    max create mode;delete wideOwner;delete tooWide
    caBWGenerate setupA;caBWPhysical setupA copiedID furnitureMin[1] furnitureMax[1] 600 obstacleA

    caBWContext="private save reopen and accepted artist example"
    local expectedA=caBWRecords setupA,expectedB=caBWRecords setupB,settingsA=caPlacementSettings setupA,settingsB=caPlacementSettings setupB
    local treeBefore=caBWTrees (caBWRoots setupA originalIDs) identities:false
    local reusableBefore=caBWTree copied identities:false
    caBWClose()
    local working=CA_TEST_OUTPUT+"Bulk-Working-Reopen.max"
    caBWRequire "Accepted scene saves privately" (saveMaxFile working quiet:true)
    caBWRequire "Accepted scene reopens" (loadMaxFile working useFileUnits:true quiet:true)
    setupA=getNodeByName "CA_BULK_SETUP_TV" exact:true;setupB=getNodeByName "CA_BULK_SETUP_SHELF" exact:true
    caBWRequire "Both native setups survive reopen" (isValidNode setupA and isValidNode setupB and(caSceneSetups #()).count==2)
    copied=(caAssetDetail setupA copiedID)[11]
    caBWCheck "Both saved catalogs retain the same reusable scene source reference" (isValidNode copied and copied==(caAssetDetail setupB copiedBID)[11] and caBWEqual reusableBefore(caBWTree copied identities:false))
    caBWCheck "Original source trees and appearance survive save reopen" (caBWEqual treeBefore (caBWTrees (caBWRoots setupA originalIDs) identities:false))
    caBWCheck "Accepted settings and complete ordered records save exactly" (caBWEqual settingsA(caPlacementSettings setupA) and caBWEqual settingsB(caPlacementSettings setupB) and caBWEqual expectedA(caBWRecords setupA) and caBWEqual expectedB(caBWRecords setupB))
    local finalEntries=#(#(setupA,copiedID,1,"CA_BULK_TV_EXISTING_SCREEN"),#(setupB,copiedBID,2,"CA_BULK_SHELF_EXISTING_DECOR"))
    for entry in finalEntries do
    (
        local owner=entry[1],before=caBWRecords entry[1],index=entry[3]
        local oldAssets=caBWAssets owner
        local skip=caRegisterAssets owner #(copied,copied)1
        caBWCheck "Reopened reusable source remains an idempotent existing registration" (skip[1].count==0 and skip[2].count==1 and caBWEqual oldAssets(caBWAssets owner))
        caBWOpen owner
        caModifierUI.keepSeed.checked=true;caModifierViewOwner.dispatch #scale
        caBWRequire "Reopened Repeat seed button succeeds" (caModifierUI.generateButton.pressed())
        caBWCheck "Reopened accepted seed repeats exact poses" (caBWEqual before(caBWRecords owner))
        caBWPhysical owner entry[2] furnitureMin[index] furnitureMax[index] furnitureMin[index].z (getNodeByName entry[4] exact:true)
    )
    caBWCheck "Manual source example has no pending Live job" (caTick()==0)
    caBWRequire "Save clean TV and shelf artist example privately" (saveMaxFile(CA_TEST_OUTPUT+"CyrusArrange-Bulk-TV-and-Shelf.max")quiet:true)
    caBWNote "SCOPE two original procedural furniture fixtures; source hierarchy/material preservation, bulk transaction semantics, conservative full-size oriented geometry and real source reuse. No render or general performance claim."
    caBWClose()
    true
)
try(caBWRun())catch
(
    caBWFailures+=1
    caBWNote("EXCEPTION "+(getCurrentException()as string))
    caBWNote("CONTEXT "+caBWContext)
    caBWNote("ERROR_SOURCE "+(getErrorSourceFileName()as string)+":"+(getErrorSourceFileLine()as string))
    caBWNote("STACK "+(getCurrentExceptionStackTrace()as string))
    caBWClose()
)
caBWFinished=true;caBWWrite()
