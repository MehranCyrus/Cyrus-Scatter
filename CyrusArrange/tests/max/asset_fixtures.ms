/* Original accessory models. FileIn defines factories only; no scene edits on load. */
global caAFmm, caAFmaterial, caAFtag, caAFbox, caAFcylinder, caAFbranch, caAFrevolve, caAFgroup
global caAFbook, caAFflatBook, caAFbookStack, caAFplant, caAFcandle, caAFframe, caAFvase, caAFbowl, caAFsculpture, caAFmug, caAFtray
global caCreateAccessoryFixtures

fn caAFmm amount = amount * (units.decodeValue "1mm")
fn caAFmaterial label tint = standardMaterial name:("CAA_" + label) diffuse:tint specularLevel:20 glossiness:35
fn caAFtag node =
(
    setUserProp node "CyrusArrangeFixture" true
    setUserProp node "CyrusArrangeAssetFixture" true
    node
)
fn caAFbox label sizeMM baseMM material =
(
    local n = box name:("CAA_" + label) width:(caAFmm sizeMM.x) length:(caAFmm sizeMM.y) height:(caAFmm sizeMM.z) pos:[(caAFmm baseMM.x),(caAFmm baseMM.y),(caAFmm baseMM.z)]
    n.material = material
    n.wirecolor = material.diffuse
    caAFtag n
)
fn caAFcylinder label radiusMM heightMM baseMM material =
(
    local n = cylinder name:("CAA_" + label) radius:(caAFmm radiusMM) height:(caAFmm heightMM) sides:24 heightsegs:1 capsegs:1 pos:[(caAFmm baseMM.x),(caAFmm baseMM.y),(caAFmm baseMM.z)]
    n.material = material
    n.wirecolor = material.diffuse
    caAFtag n
)
fn caAFbranch label startMM endMM material =
(
    local delta = endMM-startMM
    local n = caAFcylinder label 1.6 (length delta) startMM material
    n.dir = normalize delta
    n
)
fn caAFrevolve label profileMM baseMM material sides:24 =
(
    local vertices = #()
    local faces = #()
    for p in profileMM do
        for j = 0 to sides-1 do
        (
            local angle = 360.0*j/sides
            append vertices [(caAFmm (p.x*cos angle)),(caAFmm (p.x*sin angle)),(caAFmm p.z)]
        )
    for ring = 0 to profileMM.count-2 do
        for j = 0 to sides-1 do
        (
            local next = mod (j+1) sides
            local a = ring*sides+j+1
            local b = ring*sides+next+1
            local c = (ring+1)*sides+next+1
            local d = (ring+1)*sides+j+1
            append faces [a,b,c]
            append faces [a,c,d]
        )
    local n = mesh name:("CAA_" + label) vertices:vertices faces:faces
    n.pos = [(caAFmm baseMM.x),(caAFmm baseMM.y),(caAFmm baseMM.z)]
    n.material = material
    n.wirecolor = material.diffuse
    update n
    caAFtag n
)
fn caAFgroup nodes label categoryIndex stackable =
(
    local head = group nodes name:("CAA_" + label)
    caAFtag head
    setUserProp head "CyrusArrangeAssetCategory" categoryIndex
    setUserProp head "CyrusArrangeAssetStackable" stackable
    head
)

fn caAFbook baseMM =
(
    local cover = caAFmaterial "Book_Terracotta" (color 150 69 47)
    local pages = caAFmaterial "Book_Paper" (color 229 217 190)
    local foil = caAFmaterial "Book_Foil" (color 194 158 83)
    local parts = #()
    append parts (caAFbox "UprightBook_Pages" [20,169,234] (baseMM+[0,0,3]) pages)
    append parts (caAFbox "UprightBook_CoverLeft" [2,175,240] (baseMM+[-11,0,0]) cover)
    append parts (caAFbox "UprightBook_CoverRight" [2,175,240] (baseMM+[11,0,0]) cover)
    append parts (caAFbox "UprightBook_Spine" [24,6,240] (baseMM+[0,84.5,0]) cover)
    append parts (caAFbox "UprightBook_SpineBand" [24.3,6.3,3] (baseMM+[0,84.5,185]) foil)
    caAFgroup parts "Book_Upright" 1 false
)

fn caAFflatBook baseMM label:"Book_Flat" tint:(color 54 85 102) =
(
    local cover = caAFmaterial (label+"_Cover") tint
    local pages = caAFmaterial (label+"_Paper") (color 235 225 203)
    local parts = #()
    append parts (caAFbox (label+"_BottomCover") [220,160,2] baseMM cover)
    append parts (caAFbox (label+"_Pages") [216,156,20] (baseMM+[0,0,2]) pages)
    append parts (caAFbox (label+"_TopCover") [220,160,2] (baseMM+[0,0,22]) cover)
    append parts (caAFbox (label+"_Spine") [220,4,24] (baseMM+[0,78,0]) cover)
    caAFgroup parts label 1 true
)

fn caAFbookStack baseMM =
(
    local a = caAFflatBook baseMM label:"StackBook_Lower" tint:(color 111 119 85)
    local b = caAFflatBook (baseMM+[0,0,24]) label:"StackBook_Middle" tint:(color 193 156 107)
    local c = caAFflatBook (baseMM+[0,0,48]) label:"StackBook_Upper" tint:(color 86 105 120)
    caAFgroup #(a,b,c) "BookStack_Horizontal" 2 true
)

fn caAFplant baseMM =
(
    local ceramic = caAFmaterial "Plant_Pot" (color 151 91 61)
    local soil = caAFmaterial "Plant_Soil" (color 48 35 25)
    local stemMat = caAFmaterial "Plant_Stem" (color 66 90 40)
    local leafMat = caAFmaterial "Plant_Leaf" (color 63 111 50)
    local parts = #()
    append parts (caAFrevolve "Plant_Pot" #([0,0,0],[35,0,0],[48,0,75],[50,0,80],[43,0,80],[39,0,16],[0,0,12]) baseMM ceramic)
    append parts (caAFcylinder "Plant_Soil" 42 5 (baseMM+[0,0,70]) soil)
    append parts (caAFcylinder "Plant_Stem" 3 205 (baseMM+[0,0,75]) stemMat)
    for i = 0 to 5 do
    (
        local angle = i*137.5
        local reach = if mod i 2 == 0 then 42 else 31
        local height = 125+i*24
        local leafBase = baseMM+[(cos angle)*reach,(sin angle)*reach,height]
        append parts (caAFbranch ("Plant_Branch_"+(i as string)) (baseMM+[0,0,height-25]) leafBase stemMat)
        local leaf = sphere name:("CAA_Plant_Leaf_"+(i as string)) radius:(caAFmm 1) segs:12 pos:[(caAFmm leafBase.x),(caAFmm leafBase.y),(caAFmm leafBase.z)]
        leaf.scale = [29,7,53]
        rotate leaf (eulerAngles 36 0 angle)
        leaf.material = leafMat
        leaf.wirecolor = leafMat.diffuse
        append parts (caAFtag leaf)
    )
    caAFgroup parts "Plant_Potted" 3 false
)

fn caAFcandle baseMM =
(
    local brass = caAFmaterial "Candle_Brass" (color 164 131 66)
    local wax = caAFmaterial "Candle_Wax" (color 230 221 197)
    local wick = caAFmaterial "Candle_Wick" (color 34 30 27)
    local parts = #()
    append parts (caAFcylinder "CandleHolder_Foot" 40 8 baseMM brass)
    append parts (caAFcylinder "CandleHolder_Stem" 7 34 (baseMM+[0,0,8]) brass)
    append parts (caAFcylinder "CandleHolder_Cup" 29 7 (baseMM+[0,0,42]) brass)
    append parts (caAFcylinder "Candle_Wax" 25 78 (baseMM+[0,0,49]) wax)
    append parts (caAFcylinder "Candle_Wick" 1.2 7 (baseMM+[0,0,127]) wick)
    caAFgroup parts "Candle_Holder" 4 false
)

fn caAFframe baseMM =
(
    local wood = caAFmaterial "Frame_Walnut" (color 84 54 36)
    local mount = caAFmaterial "Frame_Mount" (color 224 215 195)
    local art = caAFmaterial "Frame_Artwork" (color 98 131 137)
    local parts = #()
    append parts (caAFbox "Frame_Lower" [140,16,10] baseMM wood)
    append parts (caAFbox "Frame_Upper" [140,16,10] (baseMM+[0,0,180]) wood)
    append parts (caAFbox "Frame_Left" [10,16,170] (baseMM+[-65,0,10]) wood)
    append parts (caAFbox "Frame_Right" [10,16,170] (baseMM+[65,0,10]) wood)
    append parts (caAFbox "Frame_Mount" [120,4,170] (baseMM+[0,3,10]) mount)
    append parts (caAFbox "Frame_Artwork" [96,1,138] (baseMM+[0,0,26]) art)
    append parts (caAFbox "Frame_Stand" [42,65,8] (baseMM+[0,24,0]) wood)
    caAFgroup parts "Frame_Standing" 5 false
)

fn caAFvase baseMM =
(
    local ceramic = caAFmaterial "Vase_Ceramic" (color 202 193 169)
    local body = caAFrevolve "Vase_Hollow" #([0,0,0],[35,0,0],[49,0,22],[65,0,100],[45,0,180],[30,0,230],[32,0,240],[27,0,240],[25,0,230],[38,0,180],[56,0,100],[42,0,22],[0,0,15]) baseMM ceramic sides:32
    caAFgroup #(body) "Vase_Ceramic" 6 false
)

fn caAFbowl baseMM =
(
    local stoneware = caAFmaterial "Bowl_Stoneware" (color 108 118 105)
    local body = caAFrevolve "Bowl_Hollow" #([0,0,0],[32,0,0],[52,0,12],[75,0,50],[78,0,60],[71,0,60],[68,0,50],[46,0,15],[0,0,8]) baseMM stoneware sides:32
    caAFgroup #(body) "Bowl_Stoneware" 8 false
)

fn caAFsculpture baseMM =
(
    local wood = caAFmaterial "Sculpture_Wood" (color 155 111 67)
    local ring = torus name:"CAA_Accessory_SculptureRing" radius1:(caAFmm 35) radius2:(caAFmm 8) segments:24 sides:12 pos:[(caAFmm baseMM.x),(caAFmm baseMM.y),(caAFmm (baseMM.z+45))]
    rotate ring (eulerAngles 90 0 0)
    ring.material = wood
    ring.wirecolor = wood.diffuse
    caAFtag ring
    local foot = caAFcylinder "Accessory_SculptureFoot" 30 8 baseMM wood
    caAFgroup #(ring,foot) "Accessory_Sculpture" 7 false
)

fn caAFmug baseMM =
(
    local ceramic = caAFmaterial "Mug_Ceramic" (color 185 172 146)
    local body = caAFrevolve "Mug_Body" #([0,0,0],[32,0,0],[35,0,85],[37,0,90],[31,0,90],[29,0,8],[0,0,8]) baseMM ceramic
    local handle = torus name:"CAA_Mug_Handle" radius1:(caAFmm 25) radius2:(caAFmm 5) segments:24 sides:10 pos:[(caAFmm (baseMM.x+36)),(caAFmm baseMM.y),(caAFmm (baseMM.z+47))]
    rotate handle (eulerAngles 90 0 0)
    handle.material = ceramic
    handle.wirecolor = ceramic.diffuse
    caAFtag handle
    caAFgroup #(body,handle) "Tableware_Mug" 9 false
)

fn caAFtray baseMM =
(
    local wood = caAFmaterial "Tray_Wood" (color 143 106 67)
    local body = caAFrevolve "Tray_Round" #([0,0,0],[84,0,0],[94,0,8],[96,0,17],[90,0,17],[86,0,7],[0,0,7]) baseMM wood sides:32
    caAFgroup #(body) "Tray_Round" 11 false
)

fn caCreateAccessoryFixtures offsetMM:[0,0,0] =
(
    local rows = #()
    append rows #(caAFbook (offsetMM+[0,0,0]),"Upright terracotta book",1,false)
    append rows #(caAFflatBook (offsetMM+[400,0,0]),"Flat blue book",1,true)
    append rows #(caAFbookStack (offsetMM+[800,0,0]),"Three-book horizontal stack",2,true)
    append rows #(caAFplant (offsetMM+[1200,0,0]),"Potted green plant",3,false)
    append rows #(caAFcandle (offsetMM+[0,450,0]),"Brass candle holder",4,false)
    append rows #(caAFframe (offsetMM+[400,450,0]),"Standing walnut frame",5,false)
    append rows #(caAFvase (offsetMM+[800,450,0]),"Hollow ceramic vase",6,false)
    append rows #(caAFbowl (offsetMM+[1200,450,0]),"Stoneware bowl",8,false)
    append rows #(caAFsculpture (offsetMM+[0,900,0]),"Wood ring sculpture",7,false)
    append rows #(caAFmug (offsetMM+[400,900,0]),"Ceramic mug",9,false)
    append rows #(caAFtray (offsetMM+[800,900,0]),"Round wooden tray",11,false)
    rows
)
