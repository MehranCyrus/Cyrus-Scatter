-- Owned, redirected Max 2027 fixture. No artist scene or profile mutations.
global R76Checks=#(),R76Metrics=#(),R76Root,R76Layer,R76Node,R76Surfaces,R76Models,R76Before
global LRSetup,LRRun,LRAdditional,LRLayer,LRRoot,LRNode,LRA,LRB
global R76Assert,R76Snapshot,R76Compare,R76Setup,R76Membership,R76Edit,R76Paint,R76Save,R76Reopen,R76Settle
fn R76Assert value label = (
    if not value do throw ("Receiver 0.76: "+label)
    append R76Checks label
    local out=createFile (MCPFixtureDir+"receiver-checks.txt")
    for item in R76Checks do format "%\n" item to:out
    close out;true
)
fn R76Settle = (for i=1 to 4 do (windows.processPostedMessages();sleep .05);CyrusPointSync();completeRedraw())
fn R76Snapshot root = (
    for row in root.groupSnapshotRows[1] collect #((copy row[1]),row[2],(if classof row[3]==String then row[3] else "c:"+(row[3] as string)))
)
fn R76Compare before after = (
    local lookup=dotNetObject "System.Collections.Hashtable",matched=0,moved=0
    for i=1 to before.count do lookup.Add before[i][3] i
    for row in after where lookup.ContainsKey row[3] do (
        local old=before[lookup.Item[row[3]]],same=old[2]==row[2]
        for axis=1 to 4 do same=same and old[1][axis]==row[1][axis]
        matched+=1;if not same do moved+=1
    )
    #(matched,moved)
)
fn R76Setup count:20 = (
    if findString (toLower MCPFixtureDir) "/build/mcp-qualification/"==undefined do throw "Owned qualification host required"
    CyrusStopBrush();resetMaxFile #noPrompt;viewport.setLayout #layout_1;viewport.setType #view_top
    local m=units.decodeValue "1m"
    R76Surfaces=for i=1 to count+1 collect (plane name:("R76_Surface_"+i as string) width:m length:m widthsegs:2 lengthsegs:2 pos:[i*m*2,0,0])
    R76Models=#((box name:"R76_Model_A" width:2 length:3 height:4 pos:[0,10000,0]),(cone name:"R76_Model_B" radius1:2 height:8 pos:[20,10000,0]))
    for source in R76Models do hide source
    R76Node=AminScatterObject name:"R76_Controller";R76Root=R76Node.baseObject
    R76Root.setLayerTransfer true;R76Root.updateMode=1;R76Root.autoRender=false;R76Root.newLayer();R76Layer=R76Root.selectedLayer()
    R76Layer.sources=R76Models;R76Layer.sourceWeights=#(.5,1.0);R76Layer.amount=count*500;R76Layer.populationMode=2;R76Layer.plantsPerM2=500
    R76Layer.advancedAxes=true;R76Layer.sclXMin=.8;R76Layer.sclXMax=1.4;R76Layer.rotXMin=-10;R76Layer.rotXMax=10;R76Layer.movXMin=-1;R76Layer.movXMax=1
    R76Root.setLayerTransfer false;R76Root.setLayerSurfaces R76Layer (for i=1 to count collect R76Surfaces[i])
    R76Settle();R76Root.refreshAll();R76Settle();true
)
fn R76Membership = (
    R76Setup();local r=R76Root,a=R76Layer
    R76Before=R76Snapshot r;R76Assert (R76Before.count==10000) "Density baseline: 20 receivers / 10000 plants"
    local caches=a.receiverCacheStats(),epoch=r.procEpoch,start=timestamp()
    r.setLayerSurfaces a R76Surfaces
    local pending=R76Snapshot r
    R76Assert (r.procEpoch==epoch and pending.count==10000) "Manual receiver addition stays pending"
    r.refreshAll();local after=R76Snapshot r,comparison=R76Compare R76Before after
    append R76Metrics #("Density append milliseconds",timestamp()-start)
    R76Assert (after.count==10500 and comparison[1]==10000 and comparison[2]==0) "Density 20 to 21: all 10000 IDs, matrices and models unchanged"
    local next=a.receiverCacheStats()
    R76Assert (next[1]-caches[1]==1 and next[2]-caches[2]==20) "Append prepares one receiver and reuses twenty candidate caches"
    local original=after
    r.setLayerSurfaces a (for i=R76Surfaces.count to 1 by -1 collect R76Surfaces[i]);r.refreshAll()
    comparison=R76Compare original (R76Snapshot r)
    R76Assert (comparison[1]==10500 and comparison[2]==0) "Receiver reorder preserves every matrix/model/ID"
    R76Surfaces[1].name="R76 renamed receiver";r.refreshAll();comparison=R76Compare original (R76Snapshot r)
    R76Assert (comparison[1]==10500 and comparison[2]==0) "Receiver rename preserves every matrix/model/ID"
    r.setLayerSurfaces a (for i=1 to 21 where i!=8 collect R76Surfaces[i]);r.refreshAll();comparison=R76Compare original (R76Snapshot r)
    R76Assert (comparison[1]==10000 and comparison[2]==0) "Removing a middle receiver preserves all remaining plants"
    r.setLayerSurfaces a R76Surfaces;r.refreshAll();comparison=R76Compare original (R76Snapshot r)
    R76Assert (comparison[1]==10500 and comparison[2]==0) "Restoring the same receiver restores its identities and transforms"
    a.procReceiverCache=#();a.procPreparedKey="";a.paintBaseKey="";r.refreshAll();comparison=R76Compare original (R76Snapshot r)
    R76Assert (comparison[1]==10500 and comparison[2]==0) "Cold receiver recomputation matches cached result"
    a.populationMode=1;a.amount=10000;r.setLayerSurfaces a (for i=1 to 20 collect R76Surfaces[i]);r.refreshAll();local fixed=R76Snapshot r
    r.setLayerSurfaces a R76Surfaces;r.refreshAll();comparison=R76Compare fixed (R76Snapshot r)
    R76Assert ((R76Snapshot r).count==10000 and comparison[1]==9524 and comparison[2]==0) "Fixed Total: 9524 survivors unchanged, 476 new receiver plants"
    a.populationMode=2;r.refreshAll();R76Before=R76Snapshot r
    R76Settle();local builds=a.receiverCacheStats(),groups=r.groupCounters(),owner=CyrusPointOwner R76Node,retained=cyrusRetainedStats owner
    local camera=viewport.getTM()
    for i=1 to 6 do (viewport.setTM ((rotateZMatrix i)*camera);completeRedraw();r.procReadSnapshot())
    local endStats=cyrusRetainedStats owner
    R76Assert (a.receiverCacheStats() as string==builds as string and (r.groupCounters())[1]==groups[1]) "Unchanged navigation/read does not regenerate"
    for k in #(3,4,5,6,7) do R76Assert (retained[k]==endStats[k]) "Unchanged navigation reuses retained resources/uploads"
    true
)
fn R76Edit = (
    R76Setup count:2;local r=R76Root,a=R76Layer,edit=CyrusScatterEdit()
    addModifier R76Node edit;r.refreshAll();cyrusEditCommand edit 1 (matrix3 1);cyrusEditCommand edit 4 (transMatrix [0,0,2]);cyrusEditCommand edit 3 (matrix3 1)
    r.refreshAll();a.procSelectedRadius 1 3.0;r.refreshAll();local before=R76Snapshot r
    r.setLayerSurfaces a R76Surfaces;r.refreshAll();local comparison=R76Compare before (R76Snapshot r)
    R76Assert (comparison[1]==before.count and comparison[2]==0) "Existing edits/clones survive adding a receiver"
    R76Assert (a.procRadiusIDs.count>0 and (amax r.procPublishedRadii[1])==3.0) "Radius overrides survive receiver addition"
    a.populationMode=1;a.amount=0;r.refreshAll()
    R76Assert ((R76Snapshot r).count==before.count) "Zero quota retains protected receiver-local candidate suffixes"
    local protectedRows=R76Snapshot r
    r.setLayerSurfaces a #(R76Surfaces[1]);r.refreshAll()
    R76Assert ((R76Snapshot r).count<protectedRows.count and (R76Snapshot r).count>0) "Missing receiver makes its edits inactive"
    r.setLayerSurfaces a R76Surfaces;r.refreshAll();comparison=R76Compare protectedRows (R76Snapshot r)
    R76Assert (comparison[1]==protectedRows.count and comparison[2]==0) "Restoring receiver recovers protected edits"
    local epoch=r.procEpoch,last=r.groupSnapshotRows[1],oldWidth=R76Surfaces[1].width
    R76Surfaces[1].width=oldWidth*1.1;r.refreshAll();local failed=a.previewError!=""
    R76Assert (failed and r.procEpoch==epoch and r.groupSnapshotRows[1]==last) "Changed bound geometry rejects successor and preserves publication"
    R76Surfaces[1].width=oldWidth;r.refreshAll();comparison=R76Compare protectedRows (R76Snapshot r)
    R76Assert (comparison[1]==protectedRows.count and comparison[2]==0) "Restoring geometry recovers the binding without losing edits"
    true
)
fn R76Paint = (
    LRSetup();LRRun();LRAdditional();LRLayer.populationMode=2;LRLayer.plantsPerM2=100;LRRoot.refreshAll()
    R76Root=LRRoot;R76Layer=LRLayer;R76Node=LRNode
    local r=R76Root,a=R76Layer,original=R76Snapshot r,receivers=a.validSurfaces()
    local extra=plane width:200 length:200 pos:[1000,0,0]
    r.setLayerSurfaces a (receivers+#(extra));r.refreshAll();local comparison=R76Compare original (R76Snapshot r)
    R76Assert (comparison[1]==original.count and comparison[2]==0 and (R76Snapshot r).count==original.count) "Adding unpainted receiver preserves plane/sphere painted plants"
    true
)
fn R76Save = (
    R76Before=R76Snapshot R76Root
    R76Assert (saveMaxFile (MCPFixtureDir+"receiver-stable.max") quiet:true) "Save private receiver fixture"
)
fn R76Reopen = (
    R76Assert (loadMaxFile (MCPFixtureDir+"receiver-stable.max") quiet:true) "Reopen private receiver fixture"
    R76Node=getNodeByName "R76_Controller";R76Root=R76Node.baseObject;R76Layer=R76Root.layerObjects[1]
    R76Root.refreshAll();local comparison=R76Compare R76Before (R76Snapshot R76Root)
    R76Assert (comparison[1]==R76Before.count and comparison[2]==0) "Save/reopen preserves full matrices, models and stable IDs"
    true
)

global R76Variants,R76LiveStart,R76LiveEnd,R76Performance
fn R76Variants = (
    for variant in #(1,2,3) do (
        R76Setup count:2;local r=R76Root,a=R76Layer,m=units.decodeValue "1m"
        if variant==1 do (a.diversityMode=2;a.diversitySize=m*.2;a.sourceColors=#(red,blue);a.roughness=25;a.blurryEdge=30)
        if variant==2 do (a.procLayerSelfEnabled=true;a.procLayerSelfMultiplier=0;a.procLayerSelfGap=m*.03;a.finalCleanup=true;a.finalNeighborRadius=m*.2;a.finalMinNeighbors=1;a.finalMinIsland=2)
        if variant==3 do (a.relaxEnabled=true;a.relaxSpacing=m*.06;a.relaxIterations=3;a.relaxStrength=.5;a.finalRelax=true;a.finalIterations=2;a.finalMaxMove=m*.01)
        r.refreshAll();R76Assert (a.previewError=="" and a.generatedCount>0) ("Variant "+variant as string+" valid baseline")
        local before=R76Snapshot r
        r.setLayerSurfaces a R76Surfaces;r.refreshAll();local comparison=R76Compare before (R76Snapshot r)
        R76Assert (a.previewError=="" and comparison[1]==before.count and comparison[2]==0) ("Variant "+variant as string+" unchanged receivers stable: clustering / spacing-cleanup / Relax")
    )
    -- A same-name new node must not inherit the removed receiver's stream.
    R76Setup count:2;local r=R76Root,a=R76Layer,before=R76Snapshot r
    local substitute=copy R76Surfaces[1];substitute.name=R76Surfaces[1].name
    r.setLayerSurfaces a #(substitute,R76Surfaces[2]);r.refreshAll();local comparison=R76Compare before (R76Snapshot r)
    R76Assert (comparison[1]==500 and comparison[2]==0) "Same-name replacement gets new IDs; other receiver unchanged"
    r.setLayerSurfaces a #(R76Surfaces[1],R76Surfaces[2]);r.refreshAll();comparison=R76Compare before (R76Snapshot r)
    R76Assert (comparison[1]==1000 and comparison[2]==0) "Restoring original node recovers its stream"
    true
)
fn R76LiveStart = (
    R76Setup count:2;R76Root.updateMode=2;R76Root.refreshAll();R76Settle();R76Before=R76Snapshot R76Root
    R76Root.setLayerSurfaces R76Layer R76Surfaces
    true
)
fn R76LiveEnd = (
    R76Settle();local comparison=R76Compare R76Before (R76Snapshot R76Root)
    R76Assert (R76Layer.previewError=="" and R76Root.groupSnapshotRows[1].count==1500 and comparison[1]==1000 and comparison[2]==0) "Live scheduled receiver addition preserves existing transforms"
    true
)
fn R76Performance = (
    R76Setup();local r=R76Root,a=R76Layer,times=#()
    for trial=1 to 7 do (
        r.setLayerSurfaces a (for i=1 to 20 collect R76Surfaces[i]);r.refreshAll()
        local before=a.receiverCacheStats(),start=timestamp()
        r.setLayerSurfaces a R76Surfaces;r.refreshAll()
        local elapsed=timestamp()-start,after=a.receiverCacheStats()
        append times elapsed
        R76Assert (a.previewError=="" and after[1]-before[1]==1 and after[2]-before[2]==20) "Timed append reuses twenty receiver candidate caches"
    )
    local out=createFile (MCPFixtureDir+"receiver-performance.txt")
    format "Append 20-to-21 synchronous milliseconds: %\n" times to:out
    format "Counts: 10000 -> 10500; seven warm append runs. Includes allocation, hashing, acceptance and publication; not presented FPS.\n" to:out
    close out;true
)

global R76FractionalAndGuards
fn R76FractionalAndGuards = (
    LRSetup();LRRun()
    cyrusBrushFill LRA.paintDocument .35;cyrusBrushFill LRB.paintDocument .65
    LRLayer.populationMode=2;LRLayer.plantsPerM2=100;LRRoot.refreshAll()
    local r=LRRoot,a=LRLayer,before=R76Snapshot LRRoot
    R76Assert (before.count>0 and a.previewError=="") "Fractional plane/sphere coverage has valid output"
    local extra=plane width:200 length:200 pos:[1000,0,0]
    r.setLayerSurfaces a ((a.validSurfaces())+#(extra));r.refreshAll()
    local comparison=R76Compare before (R76Snapshot r)
    R76Assert (comparison[1]==before.count and comparison[2]==0 and r.groupSnapshotRows[1].count==before.count) "Fractional plane/sphere coverage remains stable after receiver addition"

    R76Setup count:2;r=R76Root;a=R76Layer
    local edit=CyrusScatterEdit();addModifier R76Node edit;r.refreshAll();cyrusEditSelect edit #(1);a.procSelectedRadius 1 3;r.refreshAll()
    local binding=a.procRadiusBinding,epoch=r.procEpoch,published=r.groupSnapshotRows[1]
    for invalidBinding in #("old combined sampler","") do (
        a.procRadiusBinding=invalidBinding;r.refreshAll()
        R76Assert (a.previewError!="" and r.procEpoch==epoch and r.groupSnapshotRows[1]==published and a.procRadiusIDs.count==1) "Invalid radius binding preserves authored override and prior publication"
    )
    a.procRadiusBinding=binding;r.refreshAll()
    R76Assert (a.previewError=="" and (amax r.procPublishedRadii[1])==3) "Restoring valid radius binding recovers publication"
    true
)
