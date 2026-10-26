-- Thin host UI. Native code owns geometry, analysis jobs, immutable bindings and live evaluation.
if (maxVersion())[1]!=29000 do throw "Vegetation Preparation Lab requires Max 2027."
if findString (cvsVersion()) "\"version\":\"0.3.1\""==undefined do throw "Load the matching Vegetation Preparation Lab 0.3.1 modules first."
global CVPAttributes, CVPDialog, CVPOpen, CVPDocument, CVPOverlayCallback, CVPAllowedCollider, CVPRowID=0
fn CVPAllowedCollider node = (classOf node.baseObject==Sphere)
CVPAttributes=attributes CyrusVegetationPreparation attribID:#(0x6c58a217,0x2c4e7c8d)
(
    parameters sceneData (nativeState type:#maxObject)
)
fn CVPDocument create:false =
(
    local owner=try(rootNode.CyrusVegetationPreparation)catch(undefined)
    if owner==undefined and create do (custAttributes.add rootNode CVPAttributes;owner=rootNode.CyrusVegetationPreparation)
    if owner==undefined then undefined
    else (if owner.nativeState==undefined and create do owner.nativeState=cvpCreate();owner.nativeState)
)
fn CVPOverlayCallback =
(
    if CVPRowID>0 and CVPDialog!=undefined do
    (
        local doc=CVPDocument()
        if doc!=undefined and CVPDialog.showGuides.checked do try(cvpDraw doc CVPRowID)catch()
    )
)
try(unRegisterRedrawViewsCallback CVPOverlayCallback)catch()
try(destroyDialog CVPDialog)catch()
rollout CVPDialog "Vegetation Preparation Lab 0.3.1" width:440 height:635
(
    label title "MODEL PREPARATION" align:#left style_sunkenedge:false
    label subtitle "Analyze once. Review the guides. Reuse them for interaction." align:#left
    listBox models "Scene models" items:#() height:5 width:414
    button addSelected "Add selected model(s)" width:200 across:2
    button selectSource "Select source" width:200
    button removeRow "Remove catalog row (keep scene objects)" width:414
    spinner minLength "Minimum stem length (mm)" range:[1,100,5] type:#float fieldwidth:60 align:#left
    spinner foliage "Preview foliage (%)" range:[1,25,5] type:#float fieldwidth:60 align:#left
    button analyze "Analyze model" width:200 across:2
    button cancelJob "Cancel analysis" width:200
    checkbox showGuides "Show inferred guides and root markers" checked:true
    editText details "" text:"Add an original plant mesh to begin." height:120 width:414 readOnly:true
    button report "Print technical report" width:200 across:2
    button acceptGuides "Accept reviewed guides" width:200
    label review "Inspect roots and branch direction before accepting." align:#left
    pickButton pickCollider "Pick sphere collider" width:200 across:2 autoDisplay:true filter:CVPAllowedCollider
    button makeCollider "Create test sphere" width:200
    button prepareModel "Prepare interactive model" width:414 height:30
    checkbox hideOriginal "Hide source after successful preparation" checked:true
    button selectCollider "Select collider to drag" width:200 across:2
    checkButton pauseLive "Pause interaction" width:200
    checkButton fullView "Full viewport geometry" width:200 across:2
    button auditMesh "Validate full mesh" width:200
    label liveStatus "No prepared model selected." width:414 height:30 align:#left
    timer poll interval:300 active:true
    local rowIDs=#(),collider=undefined
    fn selectedID = (if models.selection>0 and models.selection<=rowIDs.count then rowIDs[models.selection] else 0)
    fn selectedDoc = (CVPDocument create:true)
    fn outputNode = (local id=selectedID();if id>0 then cvpNode (selectedDoc()) id true else undefined)
    fn refresh =
    (
        local doc=selectedDoc(),old=selectedID(),names=#(),ids=#()
        for id=1 to 8 do (local s=cvpLabel doc id;if s!="" do (append names s;append ids id))
        if models.items!=names do models.items=names
        rowIDs=ids
        local index=findItem ids old
        if index==0 and ids.count>0 do index=1
        if models.selection!=index do models.selection=index
        CVPRowID=selectedID()
        if CVPRowID>0 do details.text=cvpSummary doc CVPRowID
        local output=outputNode()
        if isValidNode output and not isValidNode collider do
        (
            collider=refs.getReference output.baseObject 2
            if isValidNode collider do pickCollider.object=collider
        )
        liveStatus.text=if isValidNode output then cvsStatus output else "Prepare a reviewed model to enable live interaction."
    )
    fn fail = (details.text=getCurrentException())
    on CVPDialog open do (CVPDocument create:true;registerRedrawViewsCallback CVPOverlayCallback;refresh())
    on CVPDialog close do (poll.active=false;unRegisterRedrawViewsCallback CVPOverlayCallback;CVPRowID=0;local doc=CVPDocument();if doc!=undefined do cvpCancel doc)
    on models selected index do (CVPRowID=selectedID();refresh();redrawViews())
    on addSelected pressed do try(undo "Add preparation models" on (for node in selection do cvpAdd (selectedDoc()) node);refresh())catch(fail())
    on selectSource pressed do try(local node=cvpNode (selectedDoc()) (selectedID()) false;if isValidNode node do select node)catch(fail())
    on removeRow pressed do try(cvpRemove (selectedDoc()) (selectedID());refresh();redrawViews())catch(fail())
    on analyze pressed do try(cvpAnalyze (selectedDoc()) (selectedID()) (minLength.value/1000.) (foliage.value/100.);refresh())catch(fail())
    on cancelJob pressed do try(cvpCancel (selectedDoc()))catch(fail())
    on report pressed do try(format "%\n" (cvpInfo (selectedDoc()) (selectedID()));actionMan.executeAction 0 "40472")catch(fail())
    on acceptGuides pressed do try(cvpAccept (selectedDoc()) (selectedID());refresh())catch(fail())
    on pickCollider picked node do collider=node
    on makeCollider pressed do try
    (
        local source=cvpNode (selectedDoc()) (selectedID()) false,bounds=nodeGetBoundingBox source (matrix3 1)
        local height=bounds[2].z-bounds[1].z
        undo "Create vegetation test sphere" on (collider=sphere name:"CVP_Test_Sphere" radius:(height*.14) segments:32 pos:[bounds[2].x+height*.1,(bounds[1].y+bounds[2].y)/2,bounds[1].z+height*.65])
        pickCollider.object=collider
    )catch(fail())
    on prepareModel pressed do try
    (
        if not isValidNode collider do throw "Pick or create a standard sphere first."
        undo "Prepare interactive vegetation" on
        (
            local id=selectedID(),doc=selectedDoc(),previous=cvpNode doc id true,output=cvpPrepare doc id collider
            setTransformLockFlags output #{1..9}
            if isValidNode previous and previous!=output do (hide previous;previous.renderable=false)
            if hideOriginal.checked do (local source=cvpNode doc id false;hide source;source.renderable=false)
            select collider;max move
        )
        refresh();redrawViews()
    )catch(fail())
    on showGuides changed value do redrawViews()
    on selectCollider pressed do (if isValidNode collider then (select collider;max move) else details.text="Pick the saved test sphere to enable selection.")
    on pauseLive changed value do try(cvsLive (outputNode()) (not value);redrawViews())catch(fail())
    on fullView changed value do try(cvsMode (outputNode()) (if value then 1 else 0);redrawViews())catch(fail())
    on auditMesh pressed do try(format "%\n" (cvsAudit (outputNode()));details.text="Full mesh audit printed in the MAXScript Listener.")catch(fail())
    on poll tick do try(local doc=CVPDocument();if doc!=undefined do (cvpPoll doc;refresh()))catch(fail())
)
fn CVPOpen =
(
    try(destroyDialog CVPDialog)catch()
    local area=(dotNetClass "System.Windows.Forms.Screen").PrimaryScreen.WorkingArea
    createDialog CVPDialog pos:[(amax 0 (area.Right-460)),(amax 0 (area.Top+5))]
)
