-- Independent Max 2027 laboratory. Native state owns all prepared and fitted geometry.
if (maxVersion())[1]!=29000 do throw "Cyrus Vegetation Lab 0.1.0 requires Max 2027."
if findString (cvlVersion()) "\"version\":\"0.1.0\""==undefined do throw "Vegetation Lab script/native version differs. Restart Max with the matching pair."
global CyrusVegetationLab, CVLCreateDemo, CVLOpen, CVLNewMesh
plugin simpleObject CyrusVegetationLab
name:"Cyrus Vegetation Lab" classID:#(0x6c58a114,0x2c4e7b8a) category:"Cyrus Labs"
(
    parameters data rollout:labUI
    (
        nativeState type:#maxObject
        stoneNode type:#node ui:stonePicker
        bladeCount type:#integer default:7
        clearance type:#worldUnits default:0 ui:clearanceSpinner
        lockBase type:#boolean default:false ui:baseCheck
    )
    local root, uiMessage="Rest blades. Press Fit to bend around the stone."
    fn ensureState = (if nativeState==undefined do nativeState=cvlCreate bladeCount;nativeState)
    fn ownerNode =
    (
        local owners=refs.dependentNodes this
        if owners.count!=1 do throw "Fit needs one grass owner. Use Copy instead of Instance for independent patches."
        owners[1]
    )
    fn syncUI = (try(labUI.statusLabel.text=uiMessage)catch();true)
    fn fitNow =
    (
        if not isValidNode stoneNode do throw "Pick a complete standard Sphere as the stone."
        local owner=ownerNode()
        cvlFit (ensureState()) owner stoneNode clearance lockBase
        uiMessage="Fit accepted. Roots stay planted. Move the stone and Fit again."
        syncUI();redrawViews();true
    )
    fn resetNow =
    (
        local owner=ownerNode()
        cvlReset (ensureState());uiMessage="Rest shape restored. Press Fit when ready."
        syncUI();redrawViews();true
    )
    fn bakeNow =
    (
        local owner=ownerNode(), baked=undefined
        undo "Bake grass mesh" on
        (
            baked=CVLNewMesh (cvlMesh (ensureState())) (uniqueName "CVL_Baked_Grass")
            baked.transform=owner.objectTransform
            baked.material=owner.material;baked.wirecolor=owner.wirecolor
        )
        uiMessage="Baked a regular mesh copy. The editable lab patch is retained."
        syncUI();select baked;redrawViews();baked
    )
    fn showError message = (uiMessage=message as string;syncUI();format "Vegetation Lab: %\n" uiMessage)
    rollout labUI "Grass and stone | 0.1.0"
    (
        label intro "Move the sphere, then press Fit." align:#left
        pickButton stonePicker "Pick sphere stone" autoDisplay:true width:200 align:#left
        spinner clearanceSpinner "Clearance: " type:#worldUnits range:[0,100000,0] fieldWidth:80 align:#left
        checkbox baseCheck "Lock base direction" checked:false align:#left
        button fitButton "Fit grass to stone" width:200 height:32 align:#left
        button resetButton "Reset grass" width:200 align:#left
        button bakeButton "Bake Mesh" width:200 align:#left
        label statusLabel "" width:218 height:72 align:#left
        label hint "Prepared ribbons + spherical collider.\nManual fitting; up to 21 blades.\nClearance range: 0 to 5 cm.\nKeep grass scale at 100%." width:218 height:76 align:#left
        button demoButton "Create another demo" width:200 align:#left
        button statsButton "Print validation details" width:200 align:#left
        on labUI open do (root=this;root.syncUI())
        on labUI close do root=undefined
        on fitButton pressed do (local model=root;if model!=undefined do try(model.fitNow())catch(model.showError (getCurrentException())))
        on resetButton pressed do (local model=root;if model!=undefined do try(model.resetNow())catch(model.showError (getCurrentException())))
        on bakeButton pressed do (local model=root;if model!=undefined do try(model.bakeNow())catch(model.showError (getCurrentException())))
        on demoButton pressed do CVLCreateDemo()
        on statsButton pressed do (local model=root;if model!=undefined do format "%\n" (cvlStats (model.ensureState())))
        on clearanceSpinner changed value do (local model=root;if model!=undefined do (model.uiMessage="Clearance changed. Press Fit to apply.";model.syncUI()))
        on baseCheck changed value do (local model=root;if model!=undefined do (model.uiMessage="Base direction changed. Press Fit to apply.";model.syncUI()))
        on stonePicker picked node do (local model=root;if model!=undefined do (model.uiMessage="Stone selected. Press Fit to apply.";model.syncUI()))
    )
    on buildMesh do (if nativeState!=undefined then mesh=cvlMesh nativeState else setMesh mesh vertices:#() faces:#())
    on create do (ensureState();clearance=.005*(units.decodeValue "1m"))
    tool create
    (
        on mousePoint click do (if click==1 do nodeTM.translation=gridPoint;if click==2 do #stop)
        on mouseMove click do ()
    )
)
fn CVLNewMesh data nodeName = (mesh mesh:data name:nodeName)
fn CVLCreateDemo count:7 =
(
    if count<1 or count>21 do throw "Choose 1 to 21 blades."
    local meter=units.decodeValue "1m", grass=undefined, stone=undefined, ground=undefined
    undo "Create grass and stone demo" on
    (
        grass=CyrusVegetationLab name:(uniqueName "CVL_Grass") bladeCount:count nativeState:(cvlCreate count)
        grass.clearance=.005*meter
        grass.wirecolor=color 64 145 44
        grass.material=standardMaterial name:"CVL Grass" diffuse:(color 67 133 37) twoSided:true
        stone=sphere name:(uniqueName "CVL_Stone") radius:(.25*meter) segments:48 smooth:true pos:[0,0,.2*meter]
        stone.wirecolor=color 150 146 137
        stone.material=standardMaterial name:"CVL Stone" diffuse:(color 140 134 122) specularLevel:12 glossiness:18
        grass.stoneNode=stone
        ground=plane name:(uniqueName "CVL_Ground") length:meter width:meter lengthSegs:1 widthSegs:1 pos:[0,0,-.002*meter]
        ground.material=standardMaterial name:"CVL Ground" diffuse:(color 93 77 56) twoSided:true
        ground.wirecolor=color 108 92 68
    )
    select #(grass,stone)
    try(max zoomext sel all)catch()
    select grass;max modify mode
    redrawViews();#(grass,stone,ground)
)
global CVLLauncher
try(destroyDialog CVLLauncher)catch()
rollout CVLLauncher "Cyrus Vegetation Lab 0.1.0"
(
    label title "Grass + stone interaction | Max 2027" width:270 align:#left
    spinner countSpinner "Blades: " type:#integer range:[1,21,7] fieldWidth:60 align:#left
    button createButton "Create Demo" width:270 height:38 align:#left
    label help "1. Create the demo.\n2. Select CVL_Grass and press Fit.\n3. Move CVL_Stone, reselect grass and Fit.\nReset and Bake Mesh are in the same panel." width:270 height:76 align:#left
    on createButton pressed do try(CVLCreateDemo count:countSpinner.value)catch(messageBox (getCurrentException()) title:"Vegetation Lab")
)
fn CVLOpen = (try(destroyDialog CVLLauncher)catch();createDialog CVLLauncher 300 205)
macroScript CyrusVegetationLabOpen category:"Cyrus Labs" toolTip:"Grass and Stone Lab" buttonText:"Vegetation Lab"
(
    on execute do CVLOpen()
)
