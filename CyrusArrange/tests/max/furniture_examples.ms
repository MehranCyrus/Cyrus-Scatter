/* Original procedural furniture examples. FileIn defines factories only.
   Factories return #(assemblyRoot, geometryNodes), matching fixtures.ms.
   Dimensions/offsets are millimetres. No external models, booleans or plugins.
*/
global caFEMM, caFEMaterial, caFEBox, caFECylinder, caFEGroup
global caFECurvedCoffeeTable, caFERoundDiningTable, caFELKitchenCounter
fn caFEMM value = value * (units.decodeValue "1mm")
fn caFEMaterial label tint = standardMaterial name:("CA_FURNITURE_"+label) diffuse:tint specularLevel:25 glossiness:42
fn caFEBox label sizeMM baseMM material =
(
    local node = box name:("CA_FURNITURE_"+label) width:(caFEMM sizeMM.x) length:(caFEMM sizeMM.y) height:(caFEMM sizeMM.z) pos:[(caFEMM baseMM.x),(caFEMM baseMM.y),(caFEMM baseMM.z)]
    node.material = material
    setUserProp node "CyrusArrangeFixture" true
    node
)
fn caFECylinder label radiusMM heightMM baseMM material sides:64 =
(
    local node = cylinder name:("CA_FURNITURE_"+label) radius:(caFEMM radiusMM) height:(caFEMM heightMM) sides:sides capsegs:1 heightsegs:1 pos:[(caFEMM baseMM.x),(caFEMM baseMM.y),(caFEMM baseMM.z)]
    node.material = material
    setUserProp node "CyrusArrangeFixture" true
    node
)
fn caFEGroup nodes label category =
(
    local root = group nodes name:("CA_FURNITURE_"+label)
    setUserProp root "CyrusArrangeFixture" true
    setUserProp root "CyrusArrangeFurnitureCategory" category
    #(root,nodes)
)
fn caFECurvedCoffeeTable offsetMM:[0,0,0] =
(
    local oak = caFEMaterial "CoffeeTable_Oak" (color 148 101 61)
    local graphite = caFEMaterial "CoffeeTable_Graphite" (color 35 40 42)
    local nodes = #()
    local top = caFECylinder "CurvedCoffeeTable_Top" 450 35 (offsetMM+[0,0,385]) oak sides:96
    top.scale = [1.55,0.88,1]
    append nodes top
    append nodes (caFECylinder "CurvedCoffeeTable_LeftSupport" 42 385 (offsetMM+[-370,0,0]) graphite sides:48)
    append nodes (caFECylinder "CurvedCoffeeTable_RightSupport" 42 385 (offsetMM+[370,0,0]) graphite sides:48)
    caFEGroup nodes "Curved_Coffee_Table" 3
)
fn caFERoundDiningTable offsetMM:[0,0,0] =
(
    local stone = caFEMaterial "DiningTable_WarmStone" (color 200 193 178)
    local bronze = caFEMaterial "DiningTable_Bronze" (color 100 75 47)
    local nodes = #()
    append nodes (caFECylinder "RoundDiningTable_Top" 650 35 (offsetMM+[0,0,720]) stone sides:96)
    append nodes (caFECylinder "RoundDiningTable_Pedestal" 150 685 (offsetMM+[0,0,35]) bronze sides:64)
    append nodes (caFECylinder "RoundDiningTable_Base" 360 35 offsetMM bronze sides:64)
    caFEGroup nodes "Round_Dining_Table" 5
)
fn caFELKitchenCounter offsetMM:[0,0,0] =
(
    local quartz = caFEMaterial "Kitchen_Quartz" (color 216 214 205)
    local cabinet = caFEMaterial "Kitchen_SageCabinet" (color 94 113 99)
    local steel = caFEMaterial "Kitchen_SinkSteel" (color 150 160 163)
    local nodes = #()
    -- Horizontal run: x[-1500,1500], y[-325,325]. A REAL unsupported
    -- rectangular sink opening occupies x[200,800], y[-200,200]. The return
    -- occupies x[-1500,-850], y[325,1550]. All slab pieces are closed solids.
    append nodes (caFEBox "KitchenCounter_LeftSlab" [1700,650,35] (offsetMM+[-650,0,900]) quartz)
    append nodes (caFEBox "KitchenCounter_RightSlab" [700,650,35] (offsetMM+[1150,0,900]) quartz)
    append nodes (caFEBox "KitchenCounter_SinkFrontSlab" [600,125,35] (offsetMM+[500,-262.5,900]) quartz)
    append nodes (caFEBox "KitchenCounter_SinkBackSlab" [600,125,35] (offsetMM+[500,262.5,900]) quartz)
    append nodes (caFEBox "KitchenCounter_ReturnSlab" [650,1225,35] (offsetMM+[-1175,937.5,900]) quartz)
    append nodes (caFEBox "KitchenCabinet_Left" [1660,610,820] (offsetMM+[-650,0,80]) cabinet)
    append nodes (caFEBox "KitchenCabinet_Right" [660,610,820] (offsetMM+[1150,0,80]) cabinet)
    append nodes (caFEBox "KitchenCabinet_Return" [610,1185,820] (offsetMM+[-1175,937.5,80]) cabinet)
    -- Open sink walls provide depth and visible metal without inventing a
    -- horizontal support in the hole. This is a diagnostic display fixture,
    -- not a plumbing/solid-modeling specification.
    append nodes (caFEBox "KitchenSink_LeftWall" [6,400,235] (offsetMM+[203,0,700]) steel)
    append nodes (caFEBox "KitchenSink_RightWall" [6,400,235] (offsetMM+[797,0,700]) steel)
    append nodes (caFEBox "KitchenSink_FrontWall" [588,6,235] (offsetMM+[500,-197,700]) steel)
    append nodes (caFEBox "KitchenSink_BackWall" [588,6,235] (offsetMM+[500,197,700]) steel)
    local assembly = caFEGroup nodes "L_Kitchen_Counter_Sink" 4
    setUserProp assembly[1] "CyrusArrangeFixtureSinkHoleMM" "x=200..800;y=-200..200;top=935;relative-to-offset"
    assembly
)
