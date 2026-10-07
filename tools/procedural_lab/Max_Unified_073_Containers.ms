-- Definitions are loaded after Max_Procedural_07_Acceptance.ms in a private host.
global U73Containers,U73ContainerUI
fn U73Containers = (
    P07Checks=#();P07Case="unified source containers";P07New count:2000
    P07Record "setup_created" true
    local root=P07Root,leaf=P07Layer,source=P07Source
    local c=leaf.containerCreate();c.pos=[1200,0,0]
    P07Record "container_created" true
    root.evaluateGroups();CyrusContainerRefreshAll()
    P07Record "membership_reconciled" true
    P07Assert (classof c.baseObject==CyrusSourceContainer and superclassof c==Helper and c.renderable==false) "Container is not a nonrendering helper"
    P07Assert (leaf.containerMode==4 and leaf.containerActive[1]) "Create did not activate its own source pool"
    leaf.sourceRadii=#(7.0);leaf.sourceScales=#(1.25);leaf.sourceZOffsets=#(2.0)
    local baseline=P07Fingerprint root,builds=(root.groupCounters())[1],id=leaf.procSourceSlots[1],start=source.transform,containerStart=c.transform
    c.movePalette [200,50,0]
    P07Assert (distance source.pos (start.row4+[200,50,0])<.0001) "Palette source did not follow translation"
    P07Assert (distance c.pos (containerStart.row4+[200,50,0])<.0001) "Container did not translate"
    P07Assert ((P07Fingerprint root) as string==baseline as string and (root.groupCounters())[1]==builds) "Palette translation regenerated placements"
    max undo
    P07Assert (distance source.pos start.row4<.0001 and distance c.pos containerStart.row4<.0001) "Container and sources were not one Undo"
    max redo
    P07Assert (distance source.pos (start.row4+[200,50,0])<.0001) "Palette Redo differs"
    root.evaluateGroups();CyrusContainerRefreshAll()
    local parked=source.pos+[1000,0,0]
    source.pos=parked;root.evaluateGroups()
    P07Assert (not leaf.containerActive[1] and leaf.sources.count==1 and leaf.procSourceSlots[1]==id) "Parking removed source correspondence"
    c.movePalette [100,0,0]
    P07Assert (source.pos==parked) "Parked source still follows"
    source.pos=c.pos;root.evaluateGroups()
    P07Assert (leaf.containerActive[1] and leaf.procSourceSlots[1]==id and leaf.sourceRadii[1]==7 and leaf.sourceScales[1]==1.25 and leaf.sourceZOffsets[1]==2) "Returning source lost its saved settings"
    local pos=source.pos,w=c.width
    undo "U73 Resize" on c.width=w/2
    root.evaluateGroups()
    P07Assert (source.pos==pos) "Resizing moved models"
    local beginSource=source.pos,beginContainer=c.pos
    undo "U73 Combined selection" on (
        cyrusContainerGesture c.delegate 0
        c.pos+= [50,0,0];source.pos+= [50,0,0]
        cyrusContainerGesture c.delegate 1
    )
    P07Assert (distance source.pos (beginSource+[50,0,0])<.0001) "Combined selection moved source twice"
    max undo
    P07Assert (distance source.pos beginSource<.0001 and distance c.pos beginContainer<.0001) "Combined Undo differs"
    root.evaluateGroups();CyrusContainerRefreshAll()
    P07Record "containers" #(c.cachedLabel,c.movementStatus,c.movementStats(),leaf.sources.count,id)
    true
)
fn U73ContainerUI = (
    P07Case="container Modify binding"
    local c=(for node in helpers where classof node.baseObject==CyrusSourceContainer collect node)[1],root=P07Root,leaf=P07Layer
    local builds=root.groupCounters(),cache=leaf.paintCacheStats()
    select c;max modify mode;modPanel.setCurrentObject c.baseObject
    c.mainUI.mountTimer.active=false
    c.mainUI.mountTimer.tick()
    P07Assert (c.mainUI.controlsReady and c.mainUI.root==root and c.mainUI.owner==leaf and selection.count==1 and selection[1]==c) "Container selection did not bind linked settings while retaining selection"
    c.mainUI.bindSection c.modelsUI
    P07Assert (c.modelsUI.root==root and c.modelsUI.owner==leaf) "Source controls bound to a different owner"
    P07Assert (builds[1]==(root.groupCounters())[1] and cache[1]==(leaf.paintCacheStats())[1]) "Opening container UI generated candidates"
    P07Record "container_ui" #(c.mainUI.controlsReady,c.mainUI.editors.count,c.containerUI.consumerList.items)
    true
)
