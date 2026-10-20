/* Procedural test assets. All dimensions are millimetres; no external assets. */
global caFxBox, caFxTVConsole, caFxOpenShelf, caFxRing, caFxMM

fn caFxMM value = value * (units.decodeValue "1mm")

fn caFxBox label sizeMM baseMM =
(
    local n = box name:("CA_FIXTURE_" + label) width:(caFxMM sizeMM.x) length:(caFxMM sizeMM.y) height:(caFxMM sizeMM.z) pos:[caFxMM baseMM.x, caFxMM baseMM.y, caFxMM baseMM.z]
    setUserProp n "CyrusArrangeFixture" true
    n
)

fn caFxTVConsole offsetMM:[0,0,0] grouped:false =
(
    local nodes = #()
    append nodes (caFxBox "TV_Top" [1800,450,40] (offsetMM + [0,0,560]))
    append nodes (caFxBox "TV_Left" [40,450,560] (offsetMM + [-880,0,0]))
    append nodes (caFxBox "TV_Right" [40,450,560] (offsetMM + [880,0,0]))
    append nodes (caFxBox "TV_Bottom" [1720,450,30] (offsetMM + [0,0,50]))
    append nodes (caFxBox "TV_MidShelf" [1720,450,25] (offsetMM + [0,0,250]))
    append nodes (caFxBox "TV_UpperDivider" [30,450,285] (offsetMM + [0,0,275]))
    if grouped then #((group nodes name:"CA_FIXTURE_TV_Assembly"), nodes) else #(undefined,nodes)
)

fn caFxOpenShelf offsetMM:[0,0,0] grouped:false =
(
    local nodes = #()
    append nodes (caFxBox "Shelf_Left" [30,350,1800] (offsetMM + [-585,0,0]))
    append nodes (caFxBox "Shelf_Right" [30,350,1800] (offsetMM + [585,0,0]))
    for z in #(0,420,860,1300,1770) do append nodes (caFxBox ("Shelf_Level_" + (z as string)) [1140,350,30] (offsetMM + [0,0,z]))
    append nodes (caFxBox "Shelf_LowerDivider" [30,350,390] (offsetMM + [0,0,30]))
    append nodes (caFxBox "Shelf_UpperDivider" [30,350,410] (offsetMM + [200,0,890]))
    if grouped then #((group nodes name:"CA_FIXTURE_Shelf_Assembly"),nodes) else #(undefined,nodes)
)

fn caFxRing offsetMM:[0,0,0] =
(
    #(
        caFxBox "Hole_Left" [300,800,20] (offsetMM + [-350,0,180]),
        caFxBox "Hole_Right" [300,800,20] (offsetMM + [350,0,180]),
        caFxBox "Hole_Front" [400,250,20] (offsetMM + [0,-275,180]),
        caFxBox "Hole_Back" [400,250,20] (offsetMM + [0,275,180])
    )
)
