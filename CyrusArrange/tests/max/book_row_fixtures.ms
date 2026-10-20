/* Original book-row fixtures. FileIn defines factories only; never resets a scene.
   All dimensions/offsets are millimetres. Every source is freshly modeled at unit scale.
   caCreateBookRowFixtures returns #(bookRows, coffeeTable, tvConsole, openShelf).
   bookRows = #( #(groupHead,label,heightMM,thicknessMM,depthMM,#negativeY), ... ).
   The final name describes authored spine direction; native row eligibility must still
   be registered explicitly by the caller. No native commands run in this helper.
*/
global caBRmm, caBRmaterial, caBRtag, caBRbox, caBRgroup, caBRbook
global caBRcoffeeTable, caBRTVConsole, caBROpenShelf, caCreateBookRowFixtures
global caBRWorldGeometryBounds

-- Group heads are helpers; measure the actual modeled geometry recursively.
fn caBRWorldGeometryBounds root =
(
    local pending = #(root), lower = [1e30,1e30,1e30], upper = [-1e30,-1e30,-1e30], found = false
    while pending.count > 0 do
    (
        local node = pending[pending.count]
        deleteItem pending pending.count
        for child in node.children do append pending child
        if not (isGroupHead node) and (superClassOf node) == GeometryClass do
        (
            local bounds = nodeGetBoundingBox node (matrix3 1)
            for axis = 1 to 3 do
            (
                lower[axis] = amin #(lower[axis],bounds[1][axis])
                upper[axis] = amax #(upper[axis],bounds[2][axis])
            )
            found = true
        )
    )
    if not found do throw "Fixture has no measurable geometry."
    #(lower,upper)
)

fn caBRmm amount = amount * (units.decodeValue "1mm")
fn caBRmaterial label tint = standardMaterial name:("CA_BOOKROW_"+label) diffuse:tint specularLevel:20 glossiness:32
fn caBRtag node =
(
    setUserProp node "CyrusArrangeFixture" true
    setUserProp node "CyrusArrangeBookRowFixture" true
    node
)
fn caBRbox label sizeMM baseMM material =
(
    local node = box name:("CA_BOOKROW_"+label) width:(caBRmm sizeMM.x) length:(caBRmm sizeMM.y) height:(caBRmm sizeMM.z) pos:[(caBRmm baseMM.x),(caBRmm baseMM.y),(caBRmm baseMM.z)]
    node.material = material
    node.wirecolor = material.diffuse
    caBRtag node
)
fn caBRgroup parts label baseMM =
(
    local head = group parts name:("CA_BOOKROW_"+label)
    caBRtag head
    head.pivot = [(caBRmm baseMM.x),(caBRmm baseMM.y),(caBRmm baseMM.z)]
    head
)
fn caBRbook label heightMM thicknessMM baseMM tint titleRules =
(
    local cover = caBRmaterial (label+"_Cloth") tint
    local paper = caBRmaterial (label+"_IvoryPages") (color 231 222 201)
    local edge = caBRmaterial (label+"_PageEdges") (color 192 178 151)
    local foil = caBRmaterial (label+"_BrassFoil") (color 181 143 63)
    local parts = #()
    -- Covers set exact outer thickness/depth/height; pages and spine detail remain inside.
    append parts (caBRbox (label+"_LeftBoard") [2,120,heightMM] (baseMM+[-thicknessMM/2+1,0,0]) cover)
    append parts (caBRbox (label+"_RightBoard") [2,120,heightMM] (baseMM+[thicknessMM/2-1,0,0]) cover)
    append parts (caBRbox (label+"_PageBlock") [thicknessMM-4,114,heightMM-6] (baseMM+[0,1.5,3]) paper)
    append parts (caBRbox (label+"_NegativeYSpine") [thicknessMM-4,2.5,heightMM] (baseMM+[0,-58.25,0]) cover)
    for level in #(0.18,0.78) do
        append parts (caBRbox (label+"_SpineFoilBand") [thicknessMM-4,0.5,2] (baseMM+[0,-59.75,heightMM*level]) foil)
    for line = 1 to titleRules do
        append parts (caBRbox (label+"_SpineTitleRule") [thicknessMM-8,0.5,1.5] (baseMM+[0,-59.75,heightMM*0.47+line*4]) foil)
    -- Separate modeled page-edge lines make the +Y opening visually distinct from the -Y spine.
    for level in #(0.2,0.4,0.6,0.8) do
        append parts (caBRbox (label+"_ExposedPageLine") [thicknessMM-5,0.5,0.4] (baseMM+[0,58.75,3+(heightMM-6)*level]) edge)
    local head = caBRgroup parts label baseMM
    setUserProp head "CyrusArrangeAssetCategory" 1
    setUserProp head "CyrusArrangeAssetStackable" false
    setUserProp head "CyrusArrangeFixtureSpine" "NegativeY"
    head
)
fn caBRcoffeeTable baseMM =
(
    local oak = caBRmaterial "Table_Oak" (color 139 99 61)
    local metal = caBRmaterial "Table_Graphite" (color 42 46 49)
    local parts = #()
    append parts (caBRbox "Table_Top" [1200,600,30] (baseMM+[0,0,700]) oak)
    for x in #(-520,520) do for y in #(-220,220) do
        append parts (caBRbox "Table_Leg" [40,40,700] (baseMM+[x,y,0]) metal)
    local head = caBRgroup parts "CoffeeTable_1200x600x730" baseMM
    setUserProp head "CyrusArrangeFurnitureCategory" 3
    head
)
fn caBRTVConsole baseMM =
(
    local oak = caBRmaterial "TV_Oak" (color 121 82 47)
    local back = caBRmaterial "TV_Back" (color 87 61 39)
    local parts = #()
    append parts (caBRbox "TV_Base" [1800,450,30] baseMM oak)
    append parts (caBRbox "TV_Top" [1800,450,30] (baseMM+[0,0,570]) oak)
    for x in #(-885,885) do append parts (caBRbox "TV_Side" [30,450,540] (baseMM+[x,0,30]) oak)
    append parts (caBRbox "TV_Back" [1740,12,540] (baseMM+[0,219,30]) back)
    append parts (caBRbox "TV_MiddleShelf" [1740,438,24] (baseMM+[0,-6,285]) oak)
    append parts (caBRbox "TV_CenterDivider" [24,438,540] (baseMM+[0,-6,30]) oak)
    local head = caBRgroup parts "TVConsole_1800x450x600" baseMM
    setUserProp head "CyrusArrangeFurnitureCategory" 1
    head
)
fn caBROpenShelf baseMM =
(
    local enamel = caBRmaterial "Shelf_StoneEnamel" (color 182 178 161)
    local back = caBRmaterial "Shelf_Back" (color 136 137 124)
    local parts = #()
    append parts (caBRbox "Shelf_Base" [1200,350,30] baseMM enamel)
    append parts (caBRbox "Shelf_Top" [1200,350,30] (baseMM+[0,0,1770]) enamel)
    for x in #(-585,585) do append parts (caBRbox "Shelf_Side" [30,350,1740] (baseMM+[x,0,30]) enamel)
    append parts (caBRbox "Shelf_Back" [1140,12,1740] (baseMM+[0,169,30]) back)
    for level in #(340,680,1020,1360) do
        append parts (caBRbox "Shelf_Board" [1140,338,24] (baseMM+[0,-6,level]) enamel)
    append parts (caBRbox "Shelf_Divider" [20,338,1740] (baseMM+[0,-6,30]) enamel)
    local head = caBRgroup parts "OpenShelf_1200x350x1800" baseMM
    setUserProp head "CyrusArrangeFurnitureCategory" 2
    head
)
fn caCreateBookRowFixtures offsetMM:[0,0,0] includeFurniture:true =
(
    local books = #()
    append books #((caBRbook "Book_Short_100mm" 100 20 (offsetMM+[-300,-1400,0]) (color 153 66 45) 1),"Short terracotta book",100,20,120,#negativeY)
    append books #((caBRbook "Book_Medium_200mm" 200 30 (offsetMM+[0,-1400,0]) (color 39 73 101) 2),"Medium ink-blue book",200,30,120,#negativeY)
    append books #((caBRbook "Book_Tall_300mm" 300 40 (offsetMM+[300,-1400,0]) (color 85 104 65) 3),"Tall olive book",300,40,120,#negativeY)
    local table = undefined
    local tv = undefined
    local shelf = undefined
    if includeFurniture do
    (
        table = caBRcoffeeTable offsetMM
        tv = caBRTVConsole (offsetMM+[2600,0,0])
        shelf = caBROpenShelf (offsetMM+[5200,0,0])
    )
    #(books,table,tv,shelf)
)
