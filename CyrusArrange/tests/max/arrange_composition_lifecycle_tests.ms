/* Native row ownership/lifecycle qualification, isolated Max 2027 batch only. */
global CA_TEST_ROOT,CA_TEST_OUTPUT,CA_AUTO_SHOW_UI
global caCreateBookRowFixtures
global caCLLog=#(),caCLPasses=0,caCLFailures=0,caCLFinished=false
global caCLWrite,caCLNote,caCLCheck,caCLRequire,caCLCase,caCLFixture,caCLFind,caCLRecords,caCLHandles,caCLGroup
global caCLMemberRecords,caCLLocks,caCLSelective,caCLDeletion,caCLAssetRemoval,caCLClone,caCLReopen,caCLFailure
fn caCLWrite=
(
    local f=createFile(CA_TEST_OUTPUT+"result.txt")
    format "% passes=% failures=%\n" (if caCLFinished then(if caCLFailures==0 then "SUCCESS" else "ERROR")else "RUNNING") caCLPasses caCLFailures to:f
    for line in caCLLog do format "%\n" line to:f
    close f
)
fn caCLNote text=(append caCLLog text;caCLWrite())
fn caCLCheck text value=(if value then(caCLPasses+=1;caCLNote("PASS "+text))else(caCLFailures+=1;caCLNote("FAIL "+text));value)
fn caCLRequire text value=(caCLCheck text value;if not value do throw("Required row lifecycle prerequisite: "+text);value)
fn caCLCase label action=(caCLNote("CASE "+label);try(action())catch(caCLFailures+=1;caCLNote("EXCEPTION "+label+": "+(getCurrentException() as string));caCLNote("STACK "+(getCurrentExceptionStackTrace() as string))))
fn caCLFind setup id=(local found=undefined;for row in caOutputRows setup where row[1]==id do found=row;found)
fn caCLGroup setup id=(local found=undefined;for row in caCompositionRows setup where row[1]==id do found=row;found)
fn caCLRecords setup=
(
    local records=#()
    for row in caOutputRows setup do append records #(row[1],row[2],row[3],row[4],row[5],row[6],row[7],row[8])
    records as string
)
fn caCLHandles setup=(local handles=#();for row in caOutputRows setup do append handles(if isValidNode row[9] then getHandleByAnim row[9] else 0);handles as string)
fn caCLMemberRecords setup rowGroup=
(
    local records=#()
    for id in rowGroup[4] do
    (
        local row=caCLFind setup id
        if row==undefined then append records undefined else append records #(row[1],row[2],row[3],row[4],row[5],row[6],row[7],row[8])
    )
    records as string
)
/* #(setup,boards,bookFixtureRows,registeredAssetIds), two separate support regions. */
fn caCLFixture=
(
    resetMaxFile #noPrompt
    units.SystemType=#millimeters;units.SystemScale=1
    fileIn(CA_TEST_ROOT+"tests/max/book_row_fixtures.ms")
    local books=(caCreateBookRowFixtures includeFurniture:false)[1]
    local boards=#(box name:"ROWLIFE_LeftSupport" width:900 length:260 height:30 pos:[-700,0,500],box name:"ROWLIFE_RightSupport" width:900 length:260 height:30 pos:[700,0,500])
    local setup=caCreateSetup boards 1
    setup.name="ROWLIFE_Setup"
    local ids=#()
    for book in books do
    (
        local id=caRegisterAsset setup book[1] book[2] 1 31 #(0) 1 1 1 false
        caSetAssetBookRow setup id 3
        append ids id
    )
    local settings=(caSetupSummary setup)[9]
    settings[1]=137;settings[2]=0.28;settings[3]=20;settings[4]=10;settings[5]=0;settings[6]=0;settings[7]=0.3
    settings[8]=2;settings[9]=1;settings[10]=25;settings[11]=false
    caSetArrangeSettings setup settings
    caSetCompositionSettings setup #(true,3,3,3,0)
    caGenerate setup #()
    local groups=caCompositionRows setup
    caCLRequire "fixture generates independently owned row relationships" (groups.count>=2)
    local regions=#()
    for rowGroup in groups where (findItem regions rowGroup[3])==0 do append regions rowGroup[3]
    caCLRequire "fixture rows cover both independent support regions" (regions.count==2)
    caCLRequire "fixture publishes transient composition statistics" ((caCompositionStats setup)[1] and (caCompositionStats setup)[3]>0)
    #(setup,boards,books,ids)
)
fn caCLLocks=
(
    local fixture=caCLFixture(),setup=fixture[1]
    local rowGroup=(caCompositionRows setup)[1]
    local member=rowGroup[4][1]
    undo "Lock whole generated row" on(caSetLocked setup #(member) true)
    local locked=true
    for id in rowGroup[4] where not ((caCLFind setup id)[7]) do locked=false
    caCLCheck "locking one member locks complete row" locked
    local keptSignature=caCLMemberRecords setup rowGroup
    local settings=(caSetupSummary setup)[9];settings[1]+=19
    caSetArrangeSettings setup settings
    caCLCheck "authored edit clears last-success composition stats" (not ((caCompositionStats setup)[1]))
    caGenerate setup #()
    caCLCheck "reroll retains complete protected row records" ((caCLMemberRecords setup rowGroup)==keptSignature)
    caCLCheck "successful generation restores transient stats" ((caCompositionStats setup)[1])
    caSetLocked setup #(member) false
    local unlocked=true
    for id in rowGroup[4] where ((caCLFind setup id)[7]) do unlocked=false
    caCLCheck "unlocking one member unlocks complete row" unlocked
    local before=caCLRecords setup,revision=(caSetupSummary setup)[3]
    local moved=(caCLFind setup member)[9]
    undo "Break one row member relationship" on(moved.pos += [11,0,0])
    local editedPosition=moved.pos
    local rejected=false
    try(caSetLocked setup #(member) true)catch(rejected=true)
    caCLCheck "invalid moved member rejects whole-row lock immediately" rejected
    caCLCheck "failed row lock retains every native pose flag and revision" ((caCLRecords setup)==before and (caSetupSummary setup)[3]==revision)
    caCLCheck "failed lock leaves actual artist-edited output untouched" ((distance moved.pos editedPosition)<0.001)
    max undo
    caSetLocked setup #(member) true
    local profileId=(caCLFind setup member)[2]
    caSetAssetBookRow setup profileId 0
    before=caCLRecords setup;local oldGroups=(caCompositionRows setup) as string;revision=(caSetupSummary setup)[3]
    rejected=false;try(caGenerate setup #())catch(rejected=true)
    caCLCheck "protected row rejects removed upright profile" rejected
    caCLCheck "profile failure retains group and placement publication" ((caCLRecords setup)==before and ((caCompositionRows setup)as string)==oldGroups and (caSetupSummary setup)[3]==revision)
    caSetAssetBookRow setup profileId 3
    caGenerate setup #()
    caCLCheck "repaired profile permits protected row update" ((caSetupSummary setup)[6]==0)
)
fn caCLSelective=
(
    local fixture=caCLFixture(),setup=fixture[1]
    local retained=(caCompositionRows setup)[1],other=undefined
    for rowGroup in caCompositionRows setup where rowGroup[3]!=retained[3] do other=rowGroup
    caCLRequire "selective fixture has another region" (other!=undefined)
    local before=caCLMemberRecords setup retained
    local settings=(caSetupSummary setup)[9];settings[1]+=3
    caSetArrangeSettings setup settings
    caGenerate setup #(other[3])
    caCLCheck "selective reroll retains complete unselected row membership" ((caCLGroup setup retained[1])!=undefined and ((caCLGroup setup retained[1])[4]as string)==(retained[4]as string))
    caCLCheck "selective reroll retains all unselected member poses" ((caCLMemberRecords setup retained)==before)
    local doomed=(caCompositionRows setup)[1]
    local pose=(caCLFind setup doomed[4][1])[4]
    local board=if pose.x<0 then fixture[2][1] else fixture[2][2]
    undo "Retire unprotected surface and regenerate" on
    (
        board.pos += [0,0,80]
        caAnalyzeSetup setup
        caGenerate setup #()
    )
    local retired=true
    for rowGroup in caCompositionRows setup where rowGroup[3]==doomed[3] do retired=false
    caCLCheck "full regeneration drops unprotected rows on retired support" retired
    max undo
    caCLCheck "Undo restores retired row relationship and support" ((caCLGroup setup doomed[1])!=undefined and isValidNode board and abs(board.pos.z-500)<0.001)
)
fn caCLDeletion=
(
    local fixture=caCLFixture(),setup=fixture[1]
    local rowGroup=(caCompositionRows setup)[1],member=rowGroup[4][1]
    local victim=(caCLFind setup member)[9]
    local before=caCLRecords setup,groups=(caCompositionRows setup)as string,revision=(caSetupSummary setup)[3]
    undo "Delete one generated row output" on(delete victim)
    local rejected=false;try(caSetLocked setup #(member) true)catch(rejected=true)
    caCLCheck "missing output member rejects complete-row lock" rejected
    caCLCheck "missing output lock failure retains native records and groups" ((caCLRecords setup)==before and ((caCompositionRows setup)as string)==groups and (caSetupSummary setup)[3]==revision)
    max undo
    caCLCheck "output deletion Undo restores real member binding" (isValidNode ((caCLFind setup member)[9]))
    caSetLocked setup #(member) true
    local source=fixture[3][1][1]
    before=caCLRecords setup;groups=(caCompositionRows setup)as string
    undo "Delete bound original row source" on(delete source)
    revision=(caSetupSummary setup)[3]
    rejected=false;try(caGenerate setup #())catch(rejected=true)
    caCLCheck "missing bound book source rejects generation" rejected
    caCLCheck "source failure retains row records and output nodes" ((caCLRecords setup)==before and ((caCompositionRows setup)as string)==groups and (caSetupSummary setup)[3]==revision)
    max undo
    caGenerate setup #()
    caCLCheck "source deletion Undo permits row regeneration" ((caSetupSummary setup)[6]==0)
)
fn caCLAssetRemoval=
(
    local fixture=caCLFixture(),setup=fixture[1]
    local rowGroup=(caCompositionRows setup)[1],assetId=(caCLFind setup rowGroup[4][1])[2]
    local before=caCLRecords setup,groups=(caCompositionRows setup)as string,handles=caCLHandles setup
    local rejected=false;try(caRemoveAssets setup #(assetId) false)catch(rejected=true)
    caCLCheck "in-use asset removal without output consent rejects" (rejected and (caCLRecords setup)==before)
    undo "Remove source asset and whole generated rows" on(caRemoveAssets setup #(assetId) true)
    local closed=true
    for id in rowGroup[4] where(caCLFind setup id)!=undefined do closed=false
    caCLCheck "asset removal deletes every affected row member" (closed and (caCLGroup setup rowGroup[1])==undefined)
    local coherent=true
    for retained in caCompositionRows setup do for id in retained[4] where(caCLFind setup id)==undefined do coherent=false
    caCLCheck "asset removal leaves no dangling group membership" coherent
    caCLCheck "unrequested catalog assets remain registered" ((caAssetRows setup).count==2)
    max undo
    caCLCheck "Undo restores catalog relationships and exact output references" ((caAssetRows setup).count==3 and (caCLRecords setup)==before and ((caCompositionRows setup)as string)==groups and (caCLHandles setup)==handles)
    max redo
    caCLCheck "Redo repeats complete-row removal" ((caCLGroup setup rowGroup[1])==undefined)
)
fn caCLClone=
(
    local fixture=caCLFixture(),setup=fixture[1]
    local before=caCLRecords setup,groups=(caCompositionRows setup)as string,guid=(caSetupSummary setup)[1]
    local originals,copies
    caCLRequire "setup-only clone command succeeds" (maxOps.cloneNodes #(setup) cloneType:#copy expandHierarchy:false actualNodeList:&originals newNodes:&copies)
    local index=findItem originals setup
    caCLRequire "setup-only clone maps owner" (index>0)
    local clone=copies[index]
    caCLCheck "setup-only clone clears groups with placements" ((caCompositionRows clone).count==0 and(caOutputRows clone).count==0)
    caCLCheck "setup-only clone retains authored composition options" (((caCompositionSettings clone)as string)==((caCompositionSettings setup)as string))
    local all=#(setup)
    for board in fixture[2] do append all board
    for book in fixture[3] do append all book[1]
    for row in caOutputRows setup do append all row[9]
    caCLRequire "zero-offset whole-system clone succeeds" (maxOps.cloneNodes all cloneType:#copy expandHierarchy:true actualNodeList:&originals newNodes:&copies)
    index=findItem originals setup
    caCLRequire "whole-system clone maps owner" (index>0)
    clone=copies[index]
    caCLCheck "whole-system clone preserves ordered group records and poses" (((caCompositionRows clone)as string)==groups and(caCLRecords clone)==before)
    caCLCheck "whole-system clone receives independent document namespace" ((caSetupSummary clone)[1]!=guid)
    local owned=true
    for row in caOutputRows clone where (findItem copies row[9])==0 do owned=false
    caCLCheck "whole-system clone output bindings belong to copied nodes" owned
    caGenerate clone #()
    caCLCheck "cloned row system regenerates with retained identities" (((caCompositionRows clone)as string)==groups and(caCLRecords clone)==before)
    caCLCheck "clone generation leaves original system unchanged" ((caCLRecords setup)==before and((caCompositionRows setup)as string)==groups)
)
fn caCLReopen=
(
    local fixture=caCLFixture(),setup=fixture[1]
    local rowGroup=(caCompositionRows setup)[1]
    caSetLocked setup #(rowGroup[4][1]) true
    local before=caCLRecords setup,groups=(caCompositionRows setup)as string,guid=(caSetupSummary setup)[1],revision=(caSetupSummary setup)[3]
    local scene=CA_TEST_OUTPUT+"composition-schema4.max"
    caCLRequire "composition successor saves" (saveMaxFile scene quiet:true)
    caCLRequire "composition successor reopens" (loadMaxFile scene useFileUnits:true quiet:true)
    setup=getNodeByName "ROWLIFE_Setup" exact:true
    caCLCheck "reopen preserves GUID revision options and groups" ((caSetupSummary setup)[1]==guid and(caSetupSummary setup)[3]==revision and((caCompositionRows setup)as string)==groups and(caCompositionSettings setup)[1])
    caCLCheck "reopen preserves member identities poses and locks" ((caCLRecords setup)==before)
    caCLCheck "reopen does not deserialize transient composition stats" (not ((caCompositionStats setup)[1]))
    local profiles=true
    for asset in caAssetRows setup where(caAssetBookRow setup asset[1])!=3 do profiles=false
    caCLCheck "embedded library2 restores every authored spine profile" profiles
    caGenerate setup #()
    before=caCLRecords setup;groups=(caCompositionRows setup)as string
    local settings=(caSetupSummary setup)[9];settings[1]+=17
    undo "Complete row reroll transaction" on(caSetArrangeSettings setup settings;caGenerate setup #())
    local after=caCLRecords setup,afterGroups=(caCompositionRows setup)as string
    max undo
    caCLCheck "outer Undo restores previous placements and row relationships" ((caCLRecords setup)==before and((caCompositionRows setup)as string)==groups)
    max redo
    caCLCheck "outer Redo restores successor placements and relationships" ((caCLRecords setup)==after and((caCompositionRows setup)as string)==afterGroups)
)
fn caCLFailure=
(
    local fixture=caCLFixture(),setup=fixture[1]
    local before=caCLRecords setup,groups=(caCompositionRows setup)as string,handles=caCLHandles setup
    local settings=(caSetupSummary setup)[9];settings[10]=0.1
    caSetArrangeSettings setup settings
    local revision=(caSetupSummary setup)[3],rejected=false
    try(caGenerate setup #())catch(rejected=true)
    caCLCheck "bounded analysis failure rejects row successor" rejected
    caCLCheck "generation failure preserves whole committed state and nodes" ((caCLRecords setup)==before and((caCompositionRows setup)as string)==groups and(caCLHandles setup)==handles and(caSetupSummary setup)[3]==revision)
    settings[10]=25;caSetArrangeSettings setup settings;caGenerate setup #()
    caCLCheck "repair publishes complete row state" ((caSetupSummary setup)[6]==0 and(caCompositionRows setup).count>0)
)
try
(
    if CA_TEST_ROOT==undefined or CA_TEST_OUTPUT==undefined do throw "Owned runner paths required."
    if(maxVersion())[1]!=29000 do throw "Max 2027 only."
    caCLCase "whole-row locks and captured-pose validation" caCLLocks
    caCLCase "selective scope and retired unprotected support" caCLSelective
    caCLCase "output/source deletion and Undo" caCLDeletion
    caCLCase "asset removal closes full rows" caCLAssetRemoval
    caCLCase "setup-only and complete clone ownership" caCLClone
    caCLCase "save-reopen and outer Undo-Redo" caCLReopen
    caCLCase "retained publication on hard failure" caCLFailure
)
catch(caCLFailures+=1;caCLNote("EXCEPTION bootstrap: "+(getCurrentException()as string)))
caCLFinished=true
caCLWrite()
