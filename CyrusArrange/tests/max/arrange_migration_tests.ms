/* Exact released schema3/4 inputs; save successors only under owned output.
   Native Batch migration/transaction coverage; current mounted Modify lives in
   dedicated UI suites. No claim that a new solver repeats an older algorithm.
   External expected rows below were decoded read-only from the original native
   chunks, not generated with the candidate. See baseline031 manifest provenance. */
global CA_TEST_ROOT,CA_TEST_OUTPUT,CA_AUTO_SHOW_UI
global caMigLog=#(),caMigPasses=0,caMigFailures=0,caMigFinished=false
fn caMigWrite =
(
    local f=createFile(CA_TEST_OUTPUT+"result.txt")
    format "% passes=% failures=%\n"(if caMigFinished then(if caMigFailures==0 then "SUCCESS"else "ERROR")else "RUNNING")caMigPasses caMigFailures to:f
    for line in caMigLog do format "%\n"line to:f
    close f
)
fn caMigNote line=(append caMigLog line;caMigWrite();true)
fn caMigCheck label value=
(
    if value then caMigPasses+=1 else caMigFailures+=1
    caMigNote((if value then "PASS "else "FAIL ")+label)
    if not value do throw("Migration: "+label)
    value
)
fn caMigEqual a b=deepEqual a b strictCompare:true
fn caMigHash path=
(
    local a=(dotNetClass "System.Security.Cryptography.SHA256").Create()
    local digest=a.ComputeHash((dotNetClass "System.IO.File").ReadAllBytes path);a.Dispose()
    toLower(substituteString((dotNetClass "System.BitConverter").ToString digest)"-""")
)
fn caMigSetups=for row in(caSceneSetups #())collect row[1]
fn caMigOwner guid=(for node in(caMigSetups())where(caSetupSummary node)[1]==guid do return node;undefined)
fn caMigRecords owner=for row in(caOutputRows owner)collect #(row[1],row[2],row[3],row[4],row[5],row[6],row[7],row[8])
fn caMigNodes owner=for row in(caOutputRows owner)collect #(row[1],getHandleByAnim row[9])
fn caMigSame a b=
(
    local good=a.count==b.count
    for i=1 to a.count while good do
    (
        for k in #(1,2,3,5,6,7,8)where a[i][k]!=b[i][k]do good=false
        if a[i][4]!=b[i][4]do good=false
    )
    good
)
fn caMigActualPoses owner=
(
    local good=true
    for row in(caOutputRows owner)do
    (
        if not isValidNode row[9]then good=false
        else
        (
            local tm=row[9].transform,scaleValue=row[6],yaw=row[5]
            if distance tm[4] row[4]>0.001 do good=false
            if distance tm[1] ([(cos yaw),(sin yaw),0]*scaleValue)>0.0001 do good=false
            if distance tm[2] ([-(sin yaw),(cos yaw),0]*scaleValue)>0.0001 do good=false
            if distance tm[3] ([0,0,1]*scaleValue)>0.0001 do good=false
        )
    )
    good
)
fn caMigGroupSame a b=
(
    local good=a.count==b.count
    for i=1 to a.count while good do
    (
        for k in #(1,2,3,6)where a[i][k]!=b[i][k]do good=false
        if not(caMigEqual a[i][4] b[i][4])or a[i][5]!=b[i][5]do good=false
    )
    good
)
fn caMigScalars a b=(local good=a.count==b.count;for i=1 to a.count while good do if a[i]!=b[i]do good=false;good)
fn caMigState owner=
(
    local s=caSetupSummary owner
    #(s[1],s[3],s[9],caPlacementSettings owner,caCompositionSettings owner,caCompositionRows owner,caPropMinimums owner,caMigRecords owner,caAssetRows owner,caRegionRows owner,(for node in(caReceiverNodes owner)collect node.name),(for a in(caAssetRows owner)collect(local d=caAssetDetail owner a[1];#(a[1],d[10],(if isValidNode d[11]then d[11].name else undefined)))))
)
fn caMigMaterial material=
(
    if material==undefined then #()
    else if isProperty material #materialIDList then #(classOf material as string,material.name,(for id in material.materialIDList collect id),(for child in material.materialList collect caMigMaterial child))
    else #(classOf material as string,material.name,(if isProperty material #diffuse then material.diffuse else undefined),(if isProperty material #opacity then material.opacity else undefined))
)
fn caMigSources=
(
    local names=sort(for node in objects where((getUserProp node "CyrusArrangeGenerated")as string)!="true" and((getUserProp node "CyrusArrangeSetup")as string)!="true"collect node.name)
    for label in names collect
    (
        local node=getNodeByName label exact:true,meshValue=undefined,geometry=#()
        -- Autodesk TargetObject is historically GeometryClass but has no mesh.
        -- Preserve its class/transform/hierarchy below; every real mesh is strict.
        if(superClassOf node)==GeometryClass and classOf node!=TargetObject do
        (
            meshValue=snapshotAsMesh node
            if meshValue==undefined do throw("No mesh for original source "+node.name)
            geometry=#((for i=1 to meshValue.numverts collect getVert meshValue i),(for i=1 to meshValue.numfaces collect #(getFace meshValue i,getFaceMatID meshValue i,getFaceSmoothGroup meshValue i)))
            delete meshValue
        )
        #(node.name,classOf node as string,(if node.parent==undefined then ""else node.parent.name),(for i=1 to 4 collect node.transform[i]),isGroupHead node,isGroupMember node,node.isHidden,caMigMaterial node.material,geometry)
    )
)
fn caMigProtectedExact expected actual=
(
    local good=expected.count==actual.count,seen=#()
    for before in expected do
    (
        local matches=0,after=undefined
        if findItem seen before[1]>0 do good=false
        append seen before[1]
        for row in actual where row[1]==before[1]do(matches+=1;after=row)
        if matches!=1 then good=false else if not(caMigEqual before after)do good=false
    )
    good
)
fn caMigCount owner id=(local total=0;for row in(caOutputRows owner)where row[2]==id do total+=1;total)
fn caMigExpected011 = #(
    #("{BD71B23E-6EB9-4ADC-B721-6FBB3B74DAD0}",21L,#(false,2L,6L,3.0,0.0),#(
        #(-1855415129518098545L,3L,11L,[-4425.986328125,431.95065307617188,600],180.0,1.0,false,0L),
        #(4217526329739087862L,2L,11L,[-4141.63134765625,576.39501953125,600],180.0,1.0,false,0L),
        #(4833438889399539039L,9L,11L,[-5433.73291015625,651.5762939453125,600],180.0,1.0,false,0L),
        #(8889760689492450290L,4L,11L,[-5255.48291015625,496.8587646484375,600],270.0,1.0,false,0L),
        #(-9070381127371035277L,4L,12L,[-4847.33251953125,571.18426513671875,80],90.0,1.0,false,0L),
        #(-1163130795133684355L,3L,12L,[-4847.33251953125,571.18426513671875,152],90.0,1.0,false,-9070381127371035277L),
        #(-732569253532407839L,3L,12L,[-5124.9208984375,420.767333984375,80],270.0,1.0,false,0L),
        #(4619979183241347064L,3L,12L,[-4067.38818359375,551.2449951171875,80],90.0,1.0,false,0L),
        #(-4613837639303247428L,2L,13L,[-4085.793212890625,535.001953125,275],90.0,1.0,false,0L),
        #(-8801237885587234118L,7L,13L,[-4367.310546875,418.06256103515625,275],180.0,1.0,false,0L),
        #(4204197238081073408L,9L,13L,[-4174.2109375,353.54428100585938,275],180.0,1.0,false,0L),
        #(-4571788105691540757L,2L,13L,[-4941.41015625,461.08807373046875,275],90.0,1.0,false,0L)
    ),#(),8),
    #("{B16410A4-059A-467D-B2B8-D7F0E693780E}",20L,#(false,2L,6L,3.0,0.0),#(
        #(-6336915223179900834L,3L,12L,[-2091.236572265625,495.278564453125,30],0.0,1.0,false,0L),
        #(-3510840117002288680L,10L,12L,[-2494.823486328125,573.7718505859375,30],180.0,1.0,false,0L),
        #(-3577833086030952047L,2L,13L,[-2530.318603515625,520.58892822265625,450],270.0,1.0,false,0L),
        #(-3928343257577888216L,8L,13L,[-2301.154296875,421.66854858398438,450],90.0,1.0,false,0L),
        #(-6522784150512875367L,2L,14L,[-2320.228515625,524.325927734375,890],0.0,1.0,false,0L),
        #(2009464621278682395L,2L,14L,[-2527.928466796875,416.1060791015625,890],270.0,1.0,false,0L),
        #(-7330871187446167237L,8L,15L,[-2800.461181640625,555.2510986328125,1330],180.0,1.0,false,0L),
        #(-9155954630173995774L,2L,15L,[-2573.317626953125,599.82965087890625,1330],90.0,1.0,false,0L)
    ),#(),9),
    #("{F8EAEE8B-F9E1-4A35-B094-A4D93CE789C9}",17L,#(false,2L,6L,3.0,0.0),#(
        #(-5391899028951837273L,6L,10L,[281.70657348632812,-150.48558044433594,420],270.0,1.0,false,0L),
        #(6001856776379392136L,9L,10L,[42.527481079101562,-290.9134521484375,420],270.0,1.0,false,0L),
        #(-8752328516640743050L,2L,10L,[-207.814208984375,-160.03558349609375,420],180.0,1.0,false,0L)
    ),#(),8),
    #("{352108FE-07B6-4BAF-9A3F-0359E61ECDD0}",14L,#(false,2L,6L,3.0,0.0),#(
        #(-375689582942756329L,5L,7L,[2655.857177734375,-425.17092895507812,755],180.0,1.0,false,0L),
        #(-4097739504199105900L,5L,7L,[2622.28662109375,-583.1219482421875,755],90.0,1.0,false,0L),
        #(4339878513871124217L,3L,7L,[2389.24853515625,322.69696044921875,755],270.0,1.0,false,0L),
        #(-8420681876439808334L,2L,7L,[2429.68701171875,-588.58349609375,755],180.0,1.0,false,0L),
        #(2703544917310095540L,5L,7L,[2663.796630859375,141.20451354980469,755],180.0,1.0,false,0L)
    ),#(),5),
    #("{C5997310-83C2-4278-B033-2A3C42D10B27}",17L,#(false,2L,6L,3.0,0.0),#(
        #(4407637097407560523L,3L,9L,[4447.5986328125,1369.5118408203125,935],0.0,1.0,false,0L),
        #(-5851407117558401586L,6L,9L,[4354.8076171875,1069.041015625,935],0.0,1.0,false,0L),
        #(-7106489156178791060L,7L,9L,[4452.8037109375,1770.960693359375,935],180.0,1.0,false,0L),
        #(-7291391612154265245L,2L,9L,[6945.62109375,259.42556762695312,935],0.0,1.0,false,0L),
        #(-6892142966719149459L,7L,9L,[4888.93798828125,380.59503173828125,935],180.0,1.0,false,0L),
        #(-4820730300532289684L,7L,9L,[4406.55517578125,1613.8253173828125,935],90.0,1.0,false,0L),
        #(-5253552295921539159L,7L,9L,[4664.50048828125,1152.464111328125,935],0.0,1.0,false,0L)
    ),#(),7)
)
fn caMigExpected031 = #(
    #("{0668748D-7E12-4FD6-8A17-1C9239BFC1CA}",19L,#(true,3L,3L,3.0,0.0),#(
        #(1928949923716288663L,3L,5L,[-1470.4525146484375,550.90997314453125,30],0.0,1.0,false,0L),
        #(8326335847997077887L,3L,5L,[-1437.4525146484375,550.90997314453125,30],0.0,1.0,false,0L),
        #(8682693167543329863L,3L,5L,[-1404.4525146484375,550.90997314453125,30],0.0,1.0,false,0L),
        #(8529341362936255142L,2L,5L,[-2206.076416015625,382.86325073242188,30],0.0,1.0,false,0L),
        #(-3310839942335624706L,3L,5L,[-2504.338134765625,452.8531494140625,30],0.0,1.0,false,0L),
        #(-9209535093415327198L,2L,7L,[-1439.8951416015625,263.91769409179688,600],0.0,1.0,false,0L),
        #(1849479067798172009L,3L,7L,[-1240.515869140625,529.24755859375,600],0.0,1.0,false,0L),
        #(6315842419481787893L,4L,7L,[-1202.515869140625,529.24755859375,600],0.0,1.0,false,0L),
        #(-7585338649840760566L,2L,7L,[-1169.515869140625,529.24755859375,600],0.0,1.0,false,0L),
        #(3575887496813238926L,4L,7L,[-2744.384033203125,418.6903076171875,600],0.0,1.0,false,0L),
        #(3224629016857672713L,4L,7L,[-1744.27587890625,246.018310546875,600],0.0,1.0,false,0L),
        #(-1522043242757735168L,2L,8L,[-1928.32421875,288.1201171875,309],0.0,1.0,false,0L),
        #(-5523897349546118960L,3L,8L,[-2476.734619140625,342.07794189453125,309],0.0,1.0,false,0L),
        #(9132353054902957601L,2L,8L,[-2448.734619140625,342.07794189453125,309],0.0,1.0,false,0L),
        #(1647616206186809305L,2L,8L,[-2425.734619140625,342.07794189453125,309],0.0,1.0,false,0L),
        #(-5982786089910148242L,2L,8L,[-1529.61181640625,292.9456787109375,309],0.0,1.0,false,0L)
    ),#(#(3255164100089955283L,1,8L,#(-5523897349546118960L,9132353054902957601L,1647616206186809305L),[0,-1,0],3.0),#(-7585722097098090867L,1,5L,#(1928949923716288663L,8326335847997077887L,8682693167543329863L),[0,-1,0],3.0),#(-6330367402617321983L,1,7L,#(1849479067798172009L,6315842419481787893L,-7585338649840760566L),[0,-1,0],3.0)),3),
    #("{0DCB304C-78A1-44F3-A15A-A6B2D197A708}",22L,#(true,3L,3L,3.0,0.0),#(
        #(-6739042197277435560L,3L,5L,[2090.958251953125,703.1905517578125,30],0.0,1.0,false,0L),
        #(-3174674179124444828L,2L,5L,[2118.958251953125,703.1905517578125,30],0.0,1.0,false,0L),
        #(2531295867705228507L,3L,5L,[2146.958251953125,703.1905517578125,30],0.0,1.0,false,0L),
        #(4915188570518134776L,3L,5L,[1110.896484375,685.60107421875,30],0.0,1.0,false,0L),
        #(-4219061243164954599L,2L,5L,[1629.315185546875,667.66571044921875,30],0.0,1.0,false,0L),
        #(-2102743307431788369L,4L,8L,[1694.285400390625,630.4708251953125,364],0.0,1.0,false,0L),
        #(-4311785162035408289L,3L,8L,[1196.1739501953125,739.08062744140625,364],0.0,1.0,false,0L),
        #(52987818774580484L,2L,8L,[1224.1739501953125,739.08062744140625,364],0.0,1.0,false,0L),
        #(-5494708225664631659L,4L,8L,[1257.1739501953125,739.08062744140625,364],0.0,1.0,false,0L),
        #(7221321767765939966L,2L,8L,[1994.3873291015625,683.96759033203125,364],0.0,1.0,false,0L),
        #(-6768112566940933123L,2L,9L,[1294.2628173828125,694.52801513671875,704],0.0,1.0,false,0L),
        #(2513143220182935971L,4L,9L,[1327.2628173828125,694.52801513671875,704],0.0,1.0,false,0L),
        #(-6496294343267926230L,3L,9L,[1365.2628173828125,694.52801513671875,704],0.0,1.0,false,0L),
        #(717199971928806738L,3L,9L,[1213.5797119140625,608.1168212890625,704],0.0,1.0,false,0L),
        #(3644144673200241345L,4L,9L,[1827.678466796875,587.458740234375,704],0.0,1.0,false,0L),
        #(-2323239123666365089L,2L,10L,[1486.728515625,546.27374267578125,1044],0.0,1.0,false,0L),
        #(4277336467655726578L,3L,10L,[1514.728515625,546.27374267578125,1044],0.0,1.0,false,0L),
        #(-4539805794083168623L,2L,10L,[1542.728515625,546.27374267578125,1044],0.0,1.0,false,0L),
        #(-8209640628054682270L,2L,10L,[1221.1466064453125,712.10943603515625,1044],0.0,1.0,false,0L),
        #(5466303496562356703L,4L,10L,[1166.737548828125,586.73455810546875,1044],0.0,1.0,false,0L),
        #(7559393730189731086L,2L,11L,[1209.107666015625,599.6214599609375,1384],0.0,1.0,false,0L),
        #(5124058758185781372L,2L,11L,[1232.107666015625,599.6214599609375,1384],0.0,1.0,false,0L),
        #(-3474885855714852612L,2L,11L,[1255.107666015625,599.6214599609375,1384],0.0,1.0,false,0L),
        #(2633069053208206159L,2L,11L,[1410.70166015625,647.14117431640625,1384],0.0,1.0,false,0L),
        #(-538029070654949626L,2L,11L,[1747.1651611328125,717.97869873046875,1384],0.0,1.0,false,0L)
    ),#(#(3786358656379012195L,1,9L,#(-6768112566940933123L,2513143220182935971L,-6496294343267926230L),[0,-1,0],3.0),#(5944548669434504831L,1,10L,#(-2323239123666365089L,4277336467655726578L,-4539805794083168623L),[0,-1,0],3.0),#(6866406392163304554L,1,8L,#(-4311785162035408289L,52987818774580484L,-5494708225664631659L),[0,-1,0],3.0),#(-6977707173600630951L,1,5L,#(-6739042197277435560L,-3174674179124444828L,2531295867705228507L),[0,-1,0],3.0),#(-3779254836273323081L,1,11L,#(7559393730189731086L,5124058758185781372L,-3474885855714852612L),[0,-1,0],3.0)),3),
    #("{64FD666D-93C2-4FC2-8672-3374BF581624}",71L,#(true,3L,3L,3.0,0.0),#(
        #(6518254783315550200L,5L,6L,[-294.60232543945312,-1553.5567626953125,600],0.0,1.0,true,0L),
        #(4922516686407626374L,2L,6L,[133.17318725585938,-1492.529541015625,600],0.0,1.0,false,0L),
        #(6083442188609876066L,4L,6L,[166.17318725585938,-1492.529541015625,600],0.0,1.0,false,0L),
        #(8614651594991076523L,2L,6L,[199.17318725585938,-1492.529541015625,600],0.0,1.0,false,0L)
    ),#(#(-1049387774245672822L,1,6L,#(4922516686407626374L,6083442188609876066L,8614651594991076523L),[0,-1,0],3.0)),4)
)

fn caMigPassive expected label=
(
    caMigCheck(label+": exact number of original native Documents")((caMigSetups()).count==expected.count)
    local snapshots=#()
    for e in expected do
    (
        local owner=caMigOwner e[1]
        caMigCheck(label+": original GUID and revision are preserved")(isValidNode owner and(caSetupSummary owner)[3]==e[2])
        caMigCheck(label+": every original placement ID source region world pose scale lock and parent survives")(caMigSame e[4](caMigRecords owner))
        caMigCheck(label+": original ordered relationship IDs members fronts and gaps survive")(caMigGroupSame e[5](caCompositionRows owner))
        caMigCheck(label+": original row settings survive without invented minima")(caMigScalars e[3](caCompositionSettings owner)and(caPropMinimums owner).count==0)
        caMigCheck(label+": exact original embedded asset count survives")((caAssetRows owner).count==e[6])
        local profiles=for a in(caAssetRows owner)where caAssetBookRow owner a[1]!=0 collect caAssetBookRow owner a[1]
        local invalidProfileValues=#()
        if e[5].count!=0 and profiles.count==3 and(findItem profiles 0)==0 do
            for profile in profiles do if profile!=3 do append invalidProfileValues profile
        caMigCheck(label+": explicit old book profiles survive without inferred eligibility")((if e[5].count==0 then profiles.count==0 else profiles.count==3 and(findItem profiles 0)==0 and invalidProfileValues.count==0))
        caMigCheck(label+": old default remains Fill and source size with no generated transient statistics")((caPlacementSettings owner)[2]==1 and not(caPlacementSettings owner)[7]and not(caPlacementSettings owner)[8]and not(caCompositionStats owner)[1]and(caGeometryCacheInfo owner)[3]==undefined)
        local missingSavedOutputRows=#()
        for row in(caOutputRows owner)do if not isValidNode row[9]do append missingSavedOutputRows row
        caMigCheck(label+": every real saved output reference survives")(missingSavedOutputRows.count==0)
        caMigCheck(label+": actual saved node transforms agree with complete public world poses")(caMigActualPoses owner)
        append snapshots #(e[1],caMigState owner,caMigNodes owner)
    )
    caMigCheck(label+": passive tick executes no generation")(caTick()==0)
    for row in snapshots do caMigCheck(label+": passive tick retains full authored state and output handles")(caMigEqual row[2](caMigState(caMigOwner row[1]))and caMigEqual row[3](caMigNodes(caMigOwner row[1])))
    snapshots
)
fn caMigReopenPassive expected label=
(
    local sources=caMigSources(),states=for owner in(caMigSetups())collect #((caSetupSummary owner)[1],caMigState owner)
    local path=CA_TEST_OUTPUT+label+"-current-schema.max"
    caMigCheck(label+": saves a successor exclusively under owned output")(saveMaxFile path quiet:true)
    caMigCheck(label+": current-schema successor reopens")(loadMaxFile path quiet:true useFileUnits:true)
    caMigPassive expected label
    for row in states do caMigCheck(label+": complete old state roundtrips without regeneration")(caMigEqual row[2](caMigState(caMigOwner row[1])))
    caMigCheck(label+": complete original source scene geometry transforms hierarchy and material descriptions roundtrip")(caMigEqual sources(caMigSources()))
    true
)
fn caMigGeometry011=
(
    local sources=caMigSources(),accepted=#()
    for e in(caMigExpected011())do
    (
        local owner=caMigOwner e[1],before=caMigState(caMigOwner e[1]),nodes=caMigNodes(caMigOwner e[1]),v=caPlacementSettings(caMigOwner e[1])
        v[2]=2;v[3]=e[4].count;v[7]=false;v[8]=false
        local result=undefined
        undo "Migrate old scene through current geometry Generate"on(result=caGeneratePlacement owner v false)
        caMigCheck "0.1.1 explicit geometry generation reports truthful requested placed and unfilled counts"(result[1]==v[3]and result[2]==(caOutputRows owner).count and result[2]>0 and result[5]==v[3]-result[2])
        caMigCheck "0.1.1 explicit generation uses current original-size Quantity without inventing row relationships"((caPlacementSettings owner)[2]==2 and(caPlacementSettings owner)[3]==v[3]and not(caCompositionSettings owner)[1]and(caCompositionRows owner).count==0)
        local after=caMigState owner,afterNodes=caMigNodes owner
        caMigCheck "0.1.1 explicit generation preserves complete original source scene"(caMigEqual sources(caMigSources()))
        max undo
        caMigCheck "One geometry Generate Undo restores exact released state and original output bindings"(caMigEqual before(caMigState owner)and caMigEqual nodes(caMigNodes owner))
        max redo
        caMigCheck "One geometry Generate Redo restores accepted current state and bindings"(caMigEqual after(caMigState owner)and caMigEqual afterNodes(caMigNodes owner))
        local pose=caMigRecords owner,settings=caPlacementSettings owner
        caGeneratePlacement owner settings false
        caMigCheck "Current geometry repeats its own accepted settings and complete poses"(caMigEqual settings(caPlacementSettings owner)and caMigEqual pose(caMigRecords owner))
        append accepted #(e[1],caPlacementSettings owner,caMigRecords owner)
    )
    local path=CA_TEST_OUTPUT+"migrated-011-current-geometry.max"
    caMigCheck "Current geometry successors save separately"(saveMaxFile path quiet:true)
    caMigCheck "Current geometry successors reopen"(loadMaxFile path quiet:true useFileUnits:true)
    for row in accepted do caMigCheck "Reopened current geometry retains accepted settings and poses"(caMigEqual row[2](caPlacementSettings(caMigOwner row[1]))and caMigEqual row[3](caMigRecords(caMigOwner row[1])))
    caMigCheck "Current geometry save/reopen preserves all original source geometry and appearance descriptions"(caMigEqual sources(caMigSources()))
    true
)
fn caMigTVPhysical owner protectedGroup=
(
    -- Analytical original fixture: baseZ30, middleZ309, topZ600;
    -- fixed yaw0 books and literal actual node bounds, not generated proxies.
    local good=true,rows=caOutputRows owner,allBounds=#(),center=[-1900,400,0]
    for row in rows do
    (
        local bounds=nodeGetBoundingBox row[9](matrix3 1),lower=bounds[1]-center,upper=bounds[2]-center,asset=undefined
        for a in(caAssetRows owner)where a[1]==row[2]do asset=a
        if asset==undefined then good=false
        else if row[5]!=0 or row[6]!=1 or distance (bounds[2]-bounds[1]) asset[4]>0.04 do good=false
        local support=false
        for h in #(30,309,600)where abs(lower.z-h)<0.03 do support=true
        if not support do good=false
        local exterior=lower.z>599,half=if exterior then 900 else 870,rear=if exterior then 225 else 213
        if lower.x< -half+9.97 or upper.x>half-9.97 or lower.y< -215.03 or upper.y>rear-9.97 do good=false
        if not exterior and upper.x> -11.97 and lower.x<11.97 do good=false
        if lower.z<31 and upper.z>285.03 do good=false
        if lower.z>308 and lower.z<310 and upper.z>570.03 do good=false
        append allBounds bounds
    )
    for i=1 to rows.count do for j=1 to i-1 do
    (
        local a=allBounds[i],b=allBounds[j]
        if (amin #(a[2].z,b[2].z))>(amax #(a[1].z,b[1].z))+0.02 do
        (
            local dx=amax #(0.0,a[1].x-b[2].x,b[1].x-a[2].x),dy=amax #(0.0,a[1].y-b[2].y,b[1].y-a[2].y)
            local gap=if findItem protectedGroup[4]rows[i][1]>0 and findItem protectedGroup[4]rows[j][1]>0 then protectedGroup[6]else 20
            if sqrt(dx*dx+dy*dy)<gap-0.04 do good=false
        )
    )
    good and rows.count==8
)
fn caMigRows031=
(
    local owner=getNodeByName "CA_BV_SETUP_TV"exact:true
    caMigCheck "Preserved released TV document is the independently decoded schema4 GUID"(isValidNode owner and(caSetupSummary owner)[1]=="{0668748D-7E12-4FD6-8A17-1C9239BFC1CA}")
    local sources=caMigSources(),legacy=caMigState owner,legacyNodes=caMigNodes owner,groups=caCompositionRows owner,protectedGroup=groups[1]
    local unrelated=for node in(caMigSetups())where node!=owner collect #((caSetupSummary node)[1],caMigState node,caMigNodes node)
    caMigCheck "Real old row is a nonempty three-member relationship with saved3mm gap"(groups.count==3 and protectedGroup[4].count==3 and protectedGroup[6]==3)
    undo "Protect released schema4 row"on(caSetLocked owner #(protectedGroup[4][1])true)
    local protected=for row in(caMigRecords owner)where findItem protectedGroup[4]row[1]>0 collect row
    local unlockedProtectedRows=#()
    if protected.count==3 do
        for row in protected do if not row[7]do append unlockedProtectedRows row
    caMigCheck "Protecting one old member closes over all three actual row members"(protected.count==3 and unlockedProtectedRows.count==0 and caMigGroupSame groups(caCompositionRows owner))
    local protectedLegacy=caMigState owner,protectedNodes=caMigNodes owner
    max undo
    caMigCheck "Protection Undo restores all released records and original handles"(caMigEqual legacy(caMigState owner)and caMigEqual legacyNodes(caMigNodes owner))
    max redo
    caMigCheck "Protection Redo restores exact legacy row closure"(caMigEqual protectedLegacy(caMigState owner)and caMigEqual protectedNodes(caMigNodes owner))
    local bookID=(caAssetRows owner)[1][1],v=caPlacementSettings owner,minimums=#(#(bookID,4))
    v[2]=2;v[3]=8;v[5]=20;v[6]=10;v[7]=false;v[8]=false;v[9]=1;v[10]=1
    local result=undefined,before=caMigState owner,beforeNodes=caMigNodes owner,rejected=false
    try(caGeneratePlacementMinimums owner v #(#(bookID,9))true false)catch(rejected=true)
    caMigCheck "Invalid minimum draft cannot migrate old rows commit a fresh seed or replace outputs"(rejected and caMigEqual before(caMigState owner)and caMigEqual beforeNodes(caMigNodes owner))
    undo "Generate ordinary geometry from released rows with minimums"on(result=caGeneratePlacementMinimums owner v minimums true false)
    caMigCheck "Current geometry transition atomically commits Quantity8 Min4 and fresh seed"(result[1]==8 and result[2]==8 and result[5]==0 and(caPlacementSettings owner)[1]!=before[4][1]and(caSetupSummary owner)[3]==before[2]+1 and caMigEqual minimums(caPropMinimums owner)and caMigCount owner bookID>=4)
    caMigCheck "Protected released support and saved region intent retain the accepted25mm sampling grid" (((caSetupSummary owner)[9][10])==25.0)
    caMigCheck "Current transition disables old row generation while preserving its other saved options"(not(caCompositionSettings owner)[1]and(caCompositionSettings owner)[2]==3 and(caCompositionSettings owner)[3]==3 and(caCompositionSettings owner)[4]==3 and(caCompositionSettings owner)[5]==0)
    local kept=for row in(caMigRecords owner)where findItem protectedGroup[4]row[1]>0 collect row
    caMigCheck "Protected old ID poses locks and ordered row descriptor remain exact"(caMigProtectedExact protected kept and(caCompositionRows owner).count==1 and caMigGroupSame #(protectedGroup)(caCompositionRows owner))
    local stats=caCompositionStats owner
    caMigCheck "Ordinary transition performs no new row or balancing work"(stats[1]and stats[2]==0 and stats[3]==0 and stats[5]==0)
    caMigCheck "Complete original-size book meshes satisfy independent TV support gap edge divider and roof limits"(caMigTVPhysical owner protectedGroup)
    caMigCheck "Transition preserves all original receiver/source geometry hierarchy transforms and material descriptions"(caMigEqual sources(caMigSources()))
    for row in unrelated do caMigCheck "Transition retains every unrelated old Document and actual output handle"(caMigEqual row[2](caMigState(caMigOwner row[1]))and caMigEqual row[3](caMigNodes(caMigOwner row[1])))
    local accepted=caMigState owner,acceptedNodes=caMigNodes owner
    max undo
    caMigCheck "One transition Undo restores enabled old rows seed policy revision all poses and actual handles"(caMigEqual before(caMigState owner)and caMigEqual beforeNodes(caMigNodes owner))
    max redo
    caMigCheck "One transition Redo restores complete ordinary successor"(caMigEqual accepted(caMigState owner)and caMigEqual acceptedNodes(caMigNodes owner))
    local untouched=for node in(caMigSetups())where node!=owner collect #((caSetupSummary node)[1],caMigState node)
    local path=CA_TEST_OUTPUT+"migrated-031-protected-ordinary.max"
    caMigCheck "Protected ordinary successor saves separately"(saveMaxFile path quiet:true)
    caMigCheck "Protected ordinary successor reopens"(loadMaxFile path quiet:true useFileUnits:true)
    owner=caMigOwner accepted[1]
    caMigCheck "Reopened successor retains complete accepted state"(caMigEqual accepted(caMigState owner)and caTick()==0)
    for row in untouched do caMigCheck "Other real legacy documents remain unchanged by migration transition"(caMigEqual row[2](caMigState(caMigOwner row[1])))
    caGeneratePlacementMinimums owner(caPlacementSettings owner)(caPropMinimums owner)false false
    caMigCheck "Reopened current repeat reproduces accepted settings minimums protected relationship and poses"(caMigEqual accepted[4](caPlacementSettings owner)and caMigGroupSame accepted[6](caCompositionRows owner)and caMigEqual accepted[7](caPropMinimums owner)and caMigEqual accepted[8](caMigRecords owner))
    caMigCheck "Repeated successor keeps original source geometry and appearance descriptions"(caMigEqual sources(caMigSources()))
    true
)
fn caMigRun=
(
    if CA_TEST_ROOT==undefined or CA_TEST_OUTPUT==undefined do throw "Owned runner paths required."
    caMigCheck "Exact0.3.2 Max2027 native migration host"((maxVersion())[1]==29000 and caVersion()=="0.3.2")
    local folder=CA_TEST_ROOT+"tests/data/baseline-011/",scene=folder+"CyrusArrange-Gallery.max",library=folder+"CyrusArrange-Original-Accessories.cyalib"
    local rowScene=CA_TEST_ROOT+"tests/data/baseline-031/CyrusArrange-BookRows-Balance-Off.max"
    caMigCheck "Preserved schema3 gallery bytes are exact"(caMigHash scene=="7b7e0c7c4ee96473912aca79b4f6ee631dd3c93a184d907df6d5b273c1b45436")
    caMigCheck "Preserved library1 bytes are exact"(caMigHash library=="6b94e5182f3a52eab838f9955baa8e7d4248425fb49944316e1d79185a159dd3")
    caMigCheck "Preserved schema4 row scene is the exact archive member distributed with0.3.1"(caMigHash rowScene=="03820ebf35cef8b8bd409a804ae942af2539265e2f70dd2fbc00096909aacae7")
    resetMaxFile #noPrompt
    caMigCheck "Original released schema3 gallery opens"(loadMaxFile scene quiet:true useFileUnits:true)
    caMigPassive(caMigExpected011())"released011"
    caMigReopenPassive(caMigExpected011())"released011-passive"
    caMigGeometry011()
    local support=box name:"MIGRATION_IndependentSupport"width:1000 length:500 height:30 pos:[15000,0,700]
    local imported=caCreateArrangement #(support)
    caLoadAssetLibrary imported library
    local assets=caAssetRows imported
    local invalidImportedAssets=#()
    if assets.count==11 do
        for a in assets do if a[10]or caAssetBookRow imported a[1]!=0 do append invalidImportedAssets a
    caMigCheck "All11 actual legacy portable assets import without sources or guessed row profiles"(assets.count==11 and invalidImportedAssets.count==0)
    local currentLibrary=CA_TEST_OUTPUT+"migrated-library2.cyalib"
    caSaveAssetLibrary imported currentLibrary
    local reader=dotNetObject "System.IO.BinaryReader"((dotNetClass "System.IO.File").OpenRead currentLibrary)
    reader.ReadBytes 8;local version=reader.ReadUInt32();reader.Close()
    caMigCheck "Explicit current portable save writes format2"(version==2)
    local reimported=caCreateArrangement #(support)
    caLoadAssetLibrary reimported currentLibrary
    caMigCheck "Current portable library reimports all migrated assets"((caAssetRows reimported).count==11)
    resetMaxFile #noPrompt
    caMigCheck "Actual older-authored row scene distributed with0.3.1 opens"(loadMaxFile rowScene quiet:true useFileUnits:true)
    caMigPassive(caMigExpected031())"released031-schema4"
    caMigReopenPassive(caMigExpected031())"released031-passive"
    caMigRows031()
    caMigCheck "All original baseline bytes remain unchanged"(caMigHash scene=="7b7e0c7c4ee96473912aca79b4f6ee631dd3c93a184d907df6d5b273c1b45436"and caMigHash library=="6b94e5182f3a52eab838f9955baa8e7d4248425fb49944316e1d79185a159dd3"and caMigHash rowScene=="03820ebf35cef8b8bd409a804ae942af2539265e2f70dd2fbc00096909aacae7")
    caMigNote "SCOPE actual schema3 and4 storage migration; exact passive legacy state; explicit current geometry may change old unlocked arrangements. No old-algorithm reproduction, renderer, UV/explicit-normal, current UI-mount or general performance claim."
    true
)
try(caMigRun())catch(caMigFailures+=1;caMigNote("EXCEPTION "+(getCurrentException()as string));caMigNote("ERROR_SOURCE "+(getErrorSourceFileName()as string)+":"+(getErrorSourceFileLine()as string));caMigNote("STACK "+(getCurrentExceptionStackTrace()as string)))
caMigFinished=true;caMigWrite()
