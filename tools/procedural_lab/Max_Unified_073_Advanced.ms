global U73Advanced,U73ContainerEdges
fn U73Advanced = (
    P07Checks=#();P07Case="unified layer defaults and Relax";P07New count:600
    local r=P07Root,a=P07Layer,s=P07Source
    local before=P07Fingerprint r,builds=(a.procStatistics())[3]
    a.procLayerSelfEnabled=true;a.procLayerSelfMultiplier=0;a.procLayerSelfGap=40
    local rows=(r.evaluateGroups())[1]
    P07Assert (rows.count<600 and (a.procStatistics())[3]==builds) "Layer spacing default failed to invalidate acceptance or regenerated candidates"
    for i=1 to rows.count do for j=i+1 to rows.count do P07Assert (distance rows[i][1].row4 rows[j][1].row4>=39.999) "Inherited self-spacing leaked"
    local b=r.addPaintSet a label:"Child";b.sources=#(s);b.paintEnabled=false
    P07Assert ((b.procSelfRule())[1] and (b.procSelfRule())[3]==40) "Child does not inherit layer self rule"
    b.procSelfOverride=true;b.procSelfEnabled=false
    P07Assert (not (b.procSelfRule())[1]) "Child override changed the layer default"
    a.procLayerSelfEnabled=false
    a.relaxEnabled=true;a.relaxSpacing=45;a.relaxIterations=4;a.relaxStrength=.6
    a.finalRelax=true;a.finalIterations=2;a.finalStrength=.3;a.finalMaxMove=5
    r.setGroupCoverage a true;cyrusBrushFill a.paintDocument 0
    cyrusBrushSettings a.paintDocument 230 1 0 false 1;cyrusBrushDab a.paintDocument [0,0,500] [0,0,-1] true
    rows=r.evaluateGroups();local fingerprint=P07Fingerprint r
    P07Assert (rows[1].count>10 and rows[2].count==300) "Relax/Brush/shared population is missing"
    for row in rows[1] do P07Assert (length row[1].row4<=230.001) "Relax applied Brush at an old anchor"
    P07Assert ((P07Fingerprint r) as string==fingerprint as string) "Relax is not deterministic"
    local cache=(a.paintCacheStats())[1]
    cyrusBrushSettings a.paintDocument 60 1 0 true 1;cyrusBrushDab a.paintDocument [0,0,500] [0,0,-1] true
    r.evaluateGroups();P07Assert ((a.paintCacheStats())[1]==cache) "Brush edit rebuilt Relax candidates"
    P07Record "relax_brush_defaults" #(for row in rows collect row.count)

    P07Case="Line Pattern with independent paint sets";P07New count:2000
    r=P07Root;a=P07Layer;s=P07Source
    local other=box name:"U73_Flower" width:4 length:4 height:6 pos:[1200,30,0]
    a.sources=#(s,other);a.sourceWeights=#(1.0,1.0);a.syncColors()
    local line=rectangle name:"U73_Path" width:900 length:400
    a.patternLines=#(line);a.diversityMode=3
    a.patternWidths=#(50.0);a.strokeSides=#(1);a.strokeModes=#(2);a.strokeSourceRows=#(1);a.strokeSourceNodes=#(s)
    a.strokeMin=#(.8);a.strokeMax=#(1.2)
    b=r.addPaintSet a label:"Flowers";b.sources=#(other);b.sourceWeights=#(1.0);b.paintEnabled=false
    rows=r.evaluateGroups()
    P07Assert (rows[1].count>40 and rows[2].count==0) "Missing per-set line choices fell back or valid choice was gated"
    for row in rows[1] do (
        local p=row[1].row4,dx=amax 0 (abs p.x-450),dy=amax 0 (abs p.y-200)
        P07Assert ((dx>0 or dy>0) and sqrt(dx*dx+dy*dy)<=50.001) "Line domain leaked"
    )
    local ids=for row in rows[1] collect row[3],positions=for row in rows[1] collect row[1].row4
    a.amount=2400;rows=r.evaluateGroups()
    for i=1 to ids.count do (
        local match=for row in rows[1] where row[3]==ids[i] collect row
        P07Assert (match.count==1 and distance match[1][1].row4 positions[i]<.0001) "Line candidate growth changed old identities/anchors"
    )
    P07Record "line_sets" #(rows[1].count,rows[2].count)
    true
)
fn U73ContainerEdges = (
    P07Case="container shared contexts and guards";P07New count:400
    local r=P07Root,a=P07Layer,s=P07Source,c=a.containerCreate();c.pos=s.pos
    r.evaluateGroups();CyrusContainerRefreshAll()
    local b=r.addPaintSet a label:"Shared flowers";b.sources=#(s);b.containerMode=2;b.paintEnabled=false;b.sourceRadii=#(13.0)
    r.evaluateGroups();CyrusContainerRefreshAll()
    P07Assert (c.consumerRows.count==2 and a.sourceRadii.count==0 and b.sourceRadii[1]==13) "Shared geometry merged source settings"
    select c;max modify mode;modPanel.setCurrentObject c.baseObject;c.mainUI.mountTimer.tick()
    c.containerUI.consumerList.selection=2;c.containerUI.selectConsumer 2;c.mainUI.mountTimer.tick()
    P07Assert (c.contextSetID==b.layerID and (CyrusContainerResolve c.baseObject)[2]==b) "Shared consumer selector bound the wrong set"
    c.mainUI.selectLayerView a;c.mainUI.bindSection c.managerUI
    P07Assert (c.contextSetID==(r.selectedPaintSet a).layerID and findString c.cachedLabel "Layer_01"!=undefined) "Layer browsing left the container label/context stale"
    local p=s.pos;c.movePalette [40,0,0]
    P07Assert (distance s.pos (p+[40,0,0])<.0001) "Shared source moved twice"
    -- Partial hierarchies cannot carry an unrelated child or a parked member.
    local unmanaged=box name:"U73_Unmanaged" pos:(s.pos+[400,0,0]);unmanaged.parent=s
    CyrusContainerRefreshAll();p=s.pos;local childPos=unmanaged.pos
    c.movePalette [30,0,0]
    P07Assert (s.pos==p and unmanaged.pos==childPos and c.movementUnits.count==0) "Partial hierarchy moved artist nodes"
    unmanaged.parent=undefined;delete unmanaged
    setTransformLockFlags s #all;CyrusContainerRefreshAll();p=s.pos;c.movePalette [30,0,0]
    P07Assert (s.pos==p and c.movementUnits.count==0) "Locked source moved"
    setTransformLockFlags s #none
    s.pos=c.pos;CyrusContainerRefreshAll()
    local boundaryNode=rectangle name:"U73_Original" width:400 length:200 pos:[1800,0,0],originalTM=boundaryNode.transform
    clearUndoBuffer();b.containerAdd boundaryNode
    P07Assert (isValidNode boundaryNode and boundaryNode.transform==originalTM and classof b.containerNodes[1].baseObject==CyrusSourceContainer) "Rectangle conversion modified the original spline"
    max undo
    P07Assert (b.containerNodes.count==0 and isValidNode boundaryNode and boundaryNode.transform==originalTM) "Boundary copy/registration was not one Undo action"
    b.containerAdd boundaryNode
    local copied=copy c
    P07Assert (copied.containerID!=c.containerID and copied.movementSources.count==0) "Clone copied movement ownership/identity"
    delete copied
    local history=c.savedSources as array
    a.containerRemove 1;CyrusContainerRefreshAll()
    P07Assert (c.consumerRows.count==0 and c.movementUnits.count==0 and c.savedSources.count==0) "Unlinked container retained active followers/consumers"
    a.containerAdd c;a.containerMode=4;b.containerMode=2;r.evaluateGroups();CyrusContainerRefreshAll()
    local path=MCPFixtureDir+"Unified073-Containers.max",id=c.containerID,sourceID=a.procSourceSlots[1]
    r.refreshAll();saveMaxFile path quiet:true;loadMaxFile path quiet:true
    c=getNodeByName "CS Sources - Layer_01 001";r=(getNodeByName "P07_Controller").baseObject;a=r.layerObjects[1]
    r.evaluateGroups();CyrusContainerRefreshAll()
    P07Assert (c.containerID==id and a.procSourceSlots[1]==sourceID and c.consumerRows.count==2) "Container persistence lost durable identities/contexts"
    P07Record "container_edges" #(c.cachedLabel,c.movementStatus,path)
    a.containerSetMode 1;b.containerSetMode 1;CyrusContainerRefreshAll()
    select c;max modify mode;modPanel.setCurrentObject c.baseObject;c.mainUI.mountTimer.tick()
    P07Assert (c.mainUI.root==r and c.mainUI.controlsReady and c.cachedConsumerCount==0 and c.movementUnits.count==0) "Inactive source pool lost its linked Scatter editor or kept followers"
    -- Global creation must provide the setup UI before any layer exists.
    resetMaxFile #noPrompt
    local emptyNode=AminScatterObject name:"U73_EmptyGlobal",emptyRoot=emptyNode.baseObject,globalContainer=emptyRoot.containerCreate globalPool:true
    select globalContainer;max modify mode;modPanel.setCurrentObject globalContainer.baseObject;globalContainer.mainUI.mountTimer.tick()
    P07Assert (globalContainer.mainUI.root==emptyRoot and globalContainer.mainUI.controlsReady and globalContainer.mainUI.owner==undefined) "Global container without layers lost its setup controls"
    P07Record "inactive_global_contexts" true
    true
)
