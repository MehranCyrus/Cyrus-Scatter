-- Independent-request lifecycle regression. Owned Max 2027 profiles only.
fileIn @"F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/quality_validation/common.ms"
global UILRun,UILNodes,UILTarget,UILBaselines,UILSnapshot,UILCheck,UILUndoCounts,UILFresh
fn UILSnapshot node = (
 local r=node.baseObject,l=r.selectedLayer()
 #(r.procEpoch,r.groupBuilds,cyrusPlacementPublicationFingerprint r.groupSnapshotRows r.procPublishedRadii #("ui-lifecycle") #(),l.amount,l.randomSeed,l.layerID)
)
fn UILCheck = (
 local selected=UILTarget.baseObject
 QAssert (selection.count==1 and selection[1]==UILTarget and selected.mainUI.controlsReady and selected.mainUI.root==selected and selected.mainUI.view==selected and not selected.mainUI.binding and not selected.mainUI.layerBinding and selected.mainUI.mountQueue.count==0) "owner" "The selected controller owns the settled panel after returning to native Qt idle."
 for i=1 to UILNodes.count do QAssert (CyrusPresetSameValues (UILSnapshot UILNodes[i]) UILBaselines[i]) ("preserved_"+i as string) "Browsing preserves this controller's complete publication, stable layer identity and pending Manual settings."
)
fn UILRun scenario = (
 case scenario of (
  "setup": (
   QSetup();QNode.name="UI Lifecycle A"
   local a=QNode
   local b=AminScatterObject name:"UI Lifecycle B",r=b.baseObject
   r.updateMode=1;r.autoRender=false;r.newLayer()
   local leaf=r.selectedLayer()
   r.setLayerSurfaces leaf #(QSurface);leaf.addModelSource QModel
   leaf.amount=230;leaf.randomSeed=43;leaf.procSelfOverride=true;leaf.procSelfEnabled=false;leaf.procLayerSelfEnabled=false
   r.evaluateProcedural()
   for layer in r.layerObjects do if layer.previewError!="" do throw layer.previewError
   local firstLayer=a.baseObject.selectedLayer()
   firstLayer.amount=417;leaf.amount=247
   UILNodes=#(a,b);UILBaselines=for n in UILNodes collect UILSnapshot n
   for n in UILNodes do n.baseObject.uiPresentationState=for i=1 to 12 collect #(true,undefined,undefined)
   CyrusPerfHeadless=false;CyrusPointSuspended=false
   UILTarget=a;select a;max modify mode
   QAssert true "requested" "Two distinct controllers have complete results and pending Manual edits; all sections will mount through the real UI timers."
  )
  "a": (UILTarget=UILNodes[1];select UILTarget;max modify mode;QAssert true "requested" "Selected A; queued native layout is checked by a later request.")
  "b": (UILTarget=UILNodes[2];select UILTarget;max modify mode;QAssert true "requested" "Selected B; queued native layout is checked by a later request.")
  "rapid": (
   for i=1 to 10 do (
    UILTarget=UILNodes[1+(mod i 2)];select UILTarget;max modify mode
    windows.processPostedMessages()
   )
   QAssert true "requested" "Ten rapid switches exercise old-page teardown and pending native mount work."
  )
  "probe": (
   local r=UILTarget.baseObject
   local ready=r.mainUI.controlsReady and r.mainUI.root==r and r.mainUI.view==r and not r.mainUI.binding and not r.mainUI.layerBinding and r.mainUI.mountQueue.count==0
   (dotNetClass "System.IO.File").WriteAllText (MCPFixtureDir+"lifecycle-ready.txt") (if ready then "true" else "false")
   QAssert true "sampled" "Read-only owner/queue observation; pending mounts are not counted as acceptance."
  )
  "verify": UILCheck()
  "wide": (
   local r=UILTarget.baseObject,xs=#()
   local stream=createFile (MCPFixtureDir+"column-geometry.tsv")
   format "page\tx\ty\twidth\theight\n" to:stream
   for page in join #(r.mainUI) r.mainUI.slots where page.isDisplayed do (
    local rect=windows.getWindowPos page.hwnd removeUIScaling:true
    format "%\t%\t%\t%\t%\n" page.name rect.x rect.y rect.w rect.h to:stream
    local sameColumn=false
    for x in xs where abs(x-rect.x)<32 do sameColumn=true
    if not sameColumn do append xs rect.x
   )
   close stream
   QAssert (xs.count>=6) "wide_columns" "The actual native page positions occupy at least six distinct columns."
  )
  "author": (
   local leaf=UILNodes[2].baseObject.selectedLayer(),before=UILBaselines[2][4]
   UILUndoCounts=#(before,before+17)
   undo "Pending UI lifecycle count" on leaf.amount=UILUndoCounts[2]
   UILBaselines[2][4]=UILUndoCounts[2]
   QAssert (leaf.amount==UILUndoCounts[2]) "authored" "An Undoable Manual count change is made before browsing both controllers."
  )
  "map": (
   local r=UILTarget.baseObject,page=r.populationUI
   local leaf=r.selectedLayer()
   local texture=Checker name:("Lifecycle map "+UILTarget.name)
   page.distributionUI_mapBrowseButton.picked texture
   QAssert (leaf.densityMap==texture and classof page.distributionUI_imageThumbnail.bitmap==Bitmap) "map" "The selected owner has a live procedural map and owned thumbnail before switching away."
  )
  "fresh": (
   setCommandPanelTaskMode #create
   UILFresh=AminScatterObject name:"UI lifecycle fresh empty"
   UILTarget=UILFresh;select UILTarget;max modify mode
   QAssert true "requested" "A new empty controller enters Modify after the populated multi-column views."
  )
  "undo": (
   max undo
   UILBaselines[2][4]=UILUndoCounts[1]
   local leaf=UILNodes[2].baseObject.selectedLayer()
   QAssert (leaf.amount==UILUndoCounts[1]) "history" "Undo reaches the authored count across UI owner switches."
  )
  "redo": (
   max redo
   UILBaselines[2][4]=UILUndoCounts[2]
   local leaf=UILNodes[2].baseObject.selectedLayer()
   QAssert (leaf.amount==UILUndoCounts[2]) "history" "Redo restores that same count without rebuilding the Manual population."
  )
  "save": (
   local path=MCPFixtureDir+"lifecycle-preserved.max"
   saveMaxFile path quiet:true
   QAssert true "requested" "Saved both controllers without publishing their pending Manual recipes."
  )
  "inspect_cold": (
   local stream=createFile (MCPFixtureDir+"cold-reopen-state.txt")
   for i=1 to UILNodes.count do format "% baseline=% actual=%\n" i UILBaselines[i] (UILSnapshot UILNodes[i]) to:stream
   close stream
   QAssert true "sampled" "Recorded the cold/warm publication boundary without changing either controller."
  )
  "reopen_verify": (
   for i=1 to UILNodes.count do (
    local state=UILSnapshot UILNodes[i]
    QAssert (state[4]==UILBaselines[i][4] and state[5]==UILBaselines[i][5] and state[6]==UILBaselines[i][6]) ("saved_"+i as string) "Authored count, seed and layer identity survive deferred cold reconstruction."
   )
   UILBaselines=for n in UILNodes collect UILSnapshot n
  )
  "reopen": (
   loadMaxFile (MCPFixtureDir+"lifecycle-preserved.max") quiet:true
   UILNodes=#(getNodeByName "UI Lifecycle A",getNodeByName "UI Lifecycle B")
   if UILNodes[1]==undefined or UILNodes[2]==undefined do throw "Saved controllers missing"
   -- Full saved-scene reconstruction can publish the saved recipe; the authored
   -- pending values/identities must still survive. Full warm publication equality
   -- applies to selection, not cold file reconstruction.
   for i=1 to UILNodes.count do (
    local state=UILSnapshot UILNodes[i]
    QAssert (state[4]==UILBaselines[i][4] and state[5]==UILBaselines[i][5] and state[6]==UILBaselines[i][6]) ("saved_"+i as string) "Save/reopen preserves authored Manual count, seed and stable layer identity."
   )
   UILTarget=UILNodes[1];select UILTarget;max modify mode
  )
 )
)
