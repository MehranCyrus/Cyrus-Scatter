-- Load definitions; invoke stages separately so the real Max node-event timer
-- runs between requests. Do not call the event handlers directly in this test.
global SCEventRoot,SCEventLeaf,SCEventSource,SCEventNew,SCEventRect,SCEventEpoch,SCEventBase,SCEventPrepared,SCEventRows
global SCEventSetup,SCEventPark,SCEventReturn,SCEventEnroll,SCEventFinish,SCText
global SCEventGroup,SCEventChild,SCEventGroupFinish,SCEventContainerReturn,SCEventGeometry,SCEventGeometryFinish
fn SCEventSetup = (
    P07Case="source containers: real Live scene events"
    P07New count:300
    SCEventRoot=P07Root;SCEventLeaf=P07Layer;SCEventSource=P07Source
    SCEventSource.pos=[1000,0,0]
    SCEventRect=rectangle name:"SC Event Rect" width:300 length:200 pos:[1000,0,0]
    SCEventNew=box name:"SC New Event Asset" width:3 length:3 height:4 pos:[1600,0,0]
    SCEventGroup=dummy pos:[2000,0,0]
    SCEventChild=box name:"SC Parented New Asset" width:4 length:4 height:4 pos:[2000,0,0]
    SCEventChild.parent=SCEventGroup
    SCEventLeaf.containerMode=4;SCEventLeaf.containerNodes=#(SCEventRect)
    SCEventRoot.updateMode=2;SCEventRoot.refreshAll()
    true
)
fn SCEventPark = (
    P07Assert (SCEventLeaf.sources.count==1 and SCEventLeaf.generatedCount==300) "Initial Live state differs"
    SCEventEpoch=SCEventRoot.procEpoch;SCEventBase=SCEventLeaf.paintBaseBuilds;SCEventPrepared=SCEventLeaf.procPreparedBuilds
    SCEventRows=SCText SCEventRoot.groupSnapshotRows
    SCEventSource.pos=[1400,0,0]
    true
)
fn SCEventReturn = (
    P07Assert (SCEventLeaf.generatedCount==0 and SCEventRoot.procEpoch>SCEventEpoch) "Scene event did not automatically park Live source"
    P07Assert (SCEventLeaf.paintBaseBuilds==SCEventBase and SCEventLeaf.procPreparedBuilds==SCEventPrepared) "Live staging event regenerated candidates"
    SCEventSource.pos=[1000,0,0]
    true
)
fn SCEventEnroll = (
    P07Assert (SCText SCEventRoot.groupSnapshotRows==SCEventRows) "Live reentry changed rows"
    P07Assert (SCEventLeaf.paintBaseBuilds==SCEventBase) "Live reentry rebuilt candidates"
    SCEventNew.pos=[1050,0,0]
    true
)
fn SCEventFinish = (
    P07Assert (SCEventLeaf.sources.count==2 and SCEventLeaf.containerActive as string=="#(true, true)") "Moved unregistered asset was not automatically enrolled"
    P07Assert (SCEventLeaf.generatedCount==300) "Live enrollment did not publish"
    SCEventGroup.pos=[1000,0,0]
    true
)
fn SCEventGroupFinish = (
    P07Assert (SCEventLeaf.sources.count==3 and findItem SCEventLeaf.sources SCEventChild>0) "Moved parent did not enroll its child geometry"
    SCEventBase=SCEventLeaf.paintBaseBuilds
    SCEventRect.pos=[3000,0,0]
    true
)
fn SCEventContainerReturn = (
    P07Assert (SCEventLeaf.generatedCount==0) "Moved container did not park its members"
    P07Assert (SCEventLeaf.paintBaseBuilds==SCEventBase) "Container transform rebuilt candidate recipe"
    SCEventRect.pos=[1000,0,0]
    true
)
fn SCEventGeometry = (
    P07Assert (SCEventLeaf.generatedCount==300 and SCEventLeaf.paintBaseBuilds==SCEventBase) "Container reentry failed"
    SCEventEpoch=SCEventRoot.procEpoch
    SCEventSource.height=35
    true
)
fn SCEventGeometryFinish = (
    P07Assert (SCEventRoot.procEpoch>SCEventEpoch and SCEventLeaf.paintBaseBuilds>SCEventBase) "Geometry edit was wrongly treated as staging-only movement"
    CSPWriteText (MCPFixtureDir+"source-container-events.json") (CSPObject #(#("passed",true),#("timer_events",true),#("park_return_reused_candidates",true),#("auto_enrolled",true),#("parent_movement",true),#("container_movement",true),#("geometry_invalidation",true),#("sources",SCEventLeaf.sources.count)))
    true
)
