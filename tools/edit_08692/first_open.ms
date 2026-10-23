-- Physical Create -> Modify witness. Run only in an owned Max 2027 test profile.
global FORun,FONodesBefore,FOSnapshots,FONew,FOState
fn FOState node = (
 local r=node.baseObject
 #(r.procEpoch,r.groupBuilds,cyrusPlacementPublicationFingerprint r.groupSnapshotRows r.procPublishedRadii #("fresh-create") #())
)
fn FORun scenario = (
 case scenario of (
  "arm": (
   FONodesBefore=for node in objects where isKindOf node.baseObject AminScatterObject collect node
   FOSnapshots=for node in FONodesBefore collect FOState node
   clearSelection();CyrusPerfHeadless=false;CyrusPointSuspended=false
   setCommandPanelTaskMode #create
   startObjectCreation AminScatterObject
   QAssert true "armed" "The actual Scatter creation tool is armed for physical viewport clicks (one Scatter per click)."
  )
  "verify": (
   local added=for node in objects where isKindOf node.baseObject AminScatterObject and findItem FONodesBefore node==0 collect node
   QAssert (added.count==2) "created" "Physical input created two new Scatter nodes (one per click)."
   FONew=selection[1]
   local r=FONew.baseObject
   QAssert (getCommandPanelTaskMode()==#modify and selection.count==1 and selection[1]==FONew and r.mainUI.controlsReady and r.mainUI.root==r and r.mainUI.view==r and r.mainUI.mountQueue.count==0) "first_modify" "The new empty Scatter owns its Modify panel after native event-loop idle."
   local unchanged=true
   for i=1 to FONodesBefore.count where not CyrusPresetSameValues (FOState FONodesBefore[i]) FOSnapshots[i] do unchanged=false
   QAssert unchanged "existing_results" "Creating/selecting another Scatter preserves the existing complete publications."
  )
 )
)
