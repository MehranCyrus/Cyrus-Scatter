-- One real-library coordinate witness; source assets are read-only inputs.
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/edit_0869/edit_workflow.ms"
global EWTreeRun,EWTreeInput
fn EWTreeRun scenario = (
    QRequire (scenario=="tree" and EWTreeInput!=undefined) "Explicit frozen Orange Tree input required"
    QSetup();QLayer.removeModelSources #(1);delete QModel
    QRequire (mergeMAXFile EWTreeInput #("CyrusModel_A076") #autoRenameDups #renameMtlDups #neverReparent quiet:true missingDLLsAction:#logmsg) "Orange Tree asset merge failed"
    local tree=getNodeByName "CyrusModel_A076" exact:true
    QRequire (isValidNode tree) "Library Orange Tree node missing"
    hide tree;QLayer.addModelSource tree;QLayer.amount=1;QLayer.sourceScales[1]=0.01
    QLayer.scaleMinimum=1;QLayer.scaleMaximum=1;QLayer.tiltDegrees=0;QLayer.yawMinimum=0;QLayer.yawMaximum=0
    EWEdit=CyrusScatterEdit();addModifier QNode EWEdit;cyrusSetViewportMemoryLimit 0;QCalculate()
    local view=EWVisible EWEdit,published=(EWRows QLayer)[1],info=(cyrusSourceGeometryInfo #(tree))[1]
    local log=createFile (MCPFixtureDir+"orange-tree-coordinates.txt")
    format "Source node: %\nNode transform: %\nObject transform: %\nObject offset position: %\nObject offset rotation: %\nObject offset scale: %\nNative geometry info: %\nPublished row: %\nNative marker: %\n" tree.name tree.transform tree.objectTransform tree.objectOffsetPos tree.objectOffsetRot tree.objectOffsetScale info published view[1] to:log
    local offset=tree.objectTransform*(inverse tree.transform),mesh=snapshotAsMesh tree
    local minZ=info[4].z,maxZ=info[5].z,threshold=minZ+(maxZ-minZ)*0.005,nearBase=[0,0,0],count=0
    for i=1 to mesh.numverts do (
        local point=(getVert mesh i)*offset
        if point.z<=threshold do (nearBase+=point;count+=1)
    )
    if count>0 do nearBase/=count
    format "Bottom 0.5 percent vertex sample count: %; mean in pivot-local space: %\nWorld sample: %\nBounds midpoint: %\n" count nearBase (nearBase*published[1]) (((info[4]+info[5])*0.5)*published[1]) to:log
    free mesh;close log
    QAssert (view.count==1 and EWNear view[1][13] published[1]) "E1_tree_placement_pivot" "The actual Orange Tree handle uses its published placement pivot; the source offset and base-geometry witness are recorded separately."
    QRoot.viewportFaces=20000000;QRoot.viewportNavigationFaces=20000000;QRoot.identificationMode=1
    QRoot.setGroupDisplay 3;CyrusPointSuspended=false;QRoot.refreshDisplay();CyrusViewportRedraw();completeRedraw();QSettle 1800
    local owner=CyrusPointOwner QNode,plan=cyrusRetainedViewportStats owner
    QAssert ((cyrusRetainedStats owner)[12]==1 and plan[6]>0 and plan[8]==0 and plan[10]==0) "E1_tree_full_mesh" "The real tree displays as a complete instanced mesh while handles are inspected."
    select QNode;max modify mode;QSettle 200;modPanel.setCurrentObject EWEdit;subObjectLevel=1
    local anchor=published[1].translation,size=amax 1 (length(info[5]-info[4])*0.01)
    local camera=targetCamera name:"EW Orange Tree evidence" pos:(anchor+[size*0.3,-size*1.4,size*0.5]) target:(targetObject pos:(anchor+[0,0,size*0.3]))
    viewport.setCamera camera;completeRedraw();QSettle 500
    local shot=gw.getViewportDib();shot.filename=MCPFixtureDir+"orange-tree-edit.png";save shot;close shot
    cyrusEditSelect EWEdit #(1)
    undo "EW actual tree move" on cyrusEditTransform EWEdit 0 [3,2,0] (matrix3 1) false
    QCalculate();QRoot.refreshDisplay();CyrusViewportRedraw();completeRedraw();QSettle 1000
    QAssert (EWNear (EWVisible EWEdit)[1][13].translation (anchor+[3,2,0])) "E1_tree_move" "The tree handle follows the same final world displacement as the displayed instance."
    QAssert (doesFileExist (MCPFixtureDir+"orange-tree-edit.png")) "E1_tree_visual" "Actual Max viewport capture retained for tree-pivot visual inspection."
    true
)
