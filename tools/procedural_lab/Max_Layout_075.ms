-- Owned disposable Max host only; load after Max_Procedural_07_Acceptance.ms.
global L75Check,L75Rows,L75Run,L75Checks=#()
fn L75Check condition message = (
 if not condition do throw message
 append L75Checks message
 local f=createFile (MCPFixtureDir+"layout075-checks.txt")
 for line in L75Checks do format "%\n" line to:f
 close f
)
fn L75Rows page = (
 page.open=true;page.bind page.owner;page.layout()
 for prefix in #("rot","scl","mov") do for axis in #("X","Y","Z") do (
  local lo=getProperty page ("randomUI_"+prefix+axis+"MinSpin" as name),hi=getProperty page ("randomUI_"+prefix+axis+"MaxSpin" as name)
  local lc=getProperty page ("randomUI_"+prefix+axis+"MinSpin_caption" as name),hc=getProperty page ("randomUI_"+prefix+axis+"MaxSpin_caption" as name)
  L75Check (lo.visible and hi.visible and lo.pos.y==hi.pos.y and hi.pos.x>lo.pos.x) (prefix+axis+": paired Min/Max")
  local edit=undefined
  for h in lo.hwnd where (windows.getHWNDData h)[4]=="CustEdit" do edit=windows.getWindowPos h
  local labelBox=windows.getWindowPos lc.hwnd[1],arrowBox=windows.getWindowPos lo.hwnd[1]
  L75Check (lc.text==axis+" Min" and hc.text==axis+" Max" and lc.pos.y==hc.pos.y and edit!=undefined and edit.w>=14 and labelBox.x+labelBox.w<=edit.x+1 and abs(edit.x+edit.w-arrowBox.x)<=1) (prefix+axis+": native label/edit/arrow bounds do not overlap")
 )
 L75Check (not page.advancedToggle.visible) "Transform axes visible without Advanced"
)
fn L75Run = (
 if findString (toLower MCPFixtureDir) "/build/mcp-qualification/"==undefined do throw "Private profile required"
 L75Checks=#();P07Case="Layout 0.75";P07New count:300
 local r=P07Root,a=P07Layer,source=P07Source,node=P07Node
 r.refreshAll();select node;max modify mode;modPanel.setCurrentObject r
 if not r.mainUI.controlsReady do r.mainUI.mountTimer.tick()
 for p in r.mainUI.editors do (p.open=true;r.mainUI.bindSection p)
 local page=r.layoutUI,epoch=r.procEpoch,builds=a.procPreparedBuilds
 L75Check (r.mainUI.editors.count==11 and r.mainUI.editors[4]==page) "Layout has its own main section after Models"
 L75Check (not r.managerUI.advancedToggle.visible and not isProperty r.managerUI #propertiesToggle and r.managerUI.flow_layersUI_enabledCheck.visible and r.managerUI.flow_layersUI_visibleCheck.visible) "Layers controls visible without Properties/Advanced"
 L75Rows r.transformsUI
 page.diversityUI_diversityRadio.state=3;page.diversityUI_diversityRadio.changed 3
 L75Check (page.diversityUI_pickPath.visible and not page.diversityUI_pickAnalyzer.visible and not page.diversityUI_analyzerStatus.visible) "Spline mode shows only spline setup"
 L75Check (findString page.diversityUI_strokeHelp.text "Pick a closed spline"!=undefined) "Empty spline mode explains next action"
 local path=rectangle width:400 length:400
 page.diversityUI_pickPath.picked path
 page.diversityUI_addOutside.pressed()
 L75Check (findString page.diversityUI_strokeHelp.text "Add a band"==undefined) "Band creation refreshes next-action help"
 a.setSourceLabel 1 "Friendly model"
 page.diversityUI_strokeMode.state=2;page.diversityUI_strokeMode.changed 2
 L75Check (page.diversityUI_strokeChoices.items[1]=="Friendly model") "Band model picker uses Scatter label"
 page.diversityUI_diversityRadio.state=4;page.diversityUI_diversityRadio.changed 4
 L75Check (page.diversityUI_pickAnalyzer.visible and page.diversityUI_analyzerStatus.visible and not page.diversityUI_pickPath.visible) "Analyzer mode shows link and status"
 local guide=CyrusSurfaceAnalyzer name:"L75_Guide"
 guide.surface=P07Surface;guide.updateMode=1;guide.resolution=48;guide.relaxIterations=0
 page.diversityUI_pickAnalyzer.picked guide
 local runs=guide.getAnalysisRuns()
 page.diversityUI_updateAnalyzer.pressed()
 L75Check (guide.getAnalysisRuns()==runs+1 and findString page.diversityUI_analyzerStatus.text "Ready"!=undefined) "Update Analyzer executes and refreshes status"
 L75Check (r.procEpoch==epoch) "Layout authoring preserves pending Manual publication"
 local curved=sphere radius:100
 guide.surface=curved
 page.diversityUI_updateAnalyzer.pressed()
 L75Check (findString page.diversityUI_analyzerStatus.text "Analysis failed"!=undefined and r.procEpoch==epoch) "Unsupported Analyzer input reports failure and retains publication"
 guide.surface=P07Surface
 page.diversityUI_selectAnalyzer.pressed()
 L75Check (selection.count==1 and selection[1]==guide) "Select Analyzer action safely changes selection"
 select node;modPanel.setCurrentObject r
 if not r.mainUI.controlsReady do r.mainUI.mountTimer.tick()
 page=r.layoutUI;page.open=true;r.mainUI.bindSection page
 r.transformsUI.open=true;r.mainUI.bindSection r.transformsUI
 local value=a.rotXMin
 r.transformsUI.randomUI_rotXMinSpin.changed -15
 L75Check (a.rotXMin== -15 and a.rotXMax>=a.rotXMin) "Paired transform callback changes correct setting"
 r.transformsUI.randomUI_resetRotation.pressed()
 L75Check (a.rotXMin==0 and a.rotZMax==0) "Transform reset callback remains wired"
 page.diversityUI_diversityRadio.state=1;page.diversityUI_diversityRadio.changed 1
 L75Check (not page.diversityUI_analyzerStatus.visible and not page.diversityUI_strokesList.visible) "Random mode hides guide settings"
 CyrusOpenLayerEditor r a
 CyrusLayerEditor.showTopic 1
 local layoutPopup=undefined
 for p in CyrusLayerEditor.activeEditors() where isProperty p #diversityUI_diversityRadio do layoutPopup=p
 L75Check (layoutPopup!=undefined) "Popup includes Layout on Models topic"
 CyrusLayerEditor.showTopic 4
 for size in #([720,500],[920,650]) do (
  setDialogSize CyrusLayerEditor size;windows.processPostedMessages()
  for p in CyrusLayerEditor.activeEditors() where isProperty p #randomUI_rotXMinSpin do L75Rows p
 )
 CyrusCloseLayerEditor()
 local second=r.newLayer()
 r.mainUI.selectLayerView (r.selectedLayer())
 r.layoutUI.open=true;r.mainUI.bindSection r.layoutUI
 r.layoutUI.diversityUI_diversityRadio.state=2;r.layoutUI.diversityUI_diversityRadio.changed 2
 L75Check (a.diversityMode==1 and (r.selectedLayer()).diversityMode==2) "Layout controls isolate layer owners"
 r.mainUI.selectLayerView a
 local container=a.containerCreate()
 select container;modPanel.setCurrentObject container.baseObject
 if not container.mainUI.controlsReady do container.mainUI.mountTimer.tick()
 L75Check (container.mainUI.editors.count==11) "Container view includes Layout"
 container.layoutUI.open=true;container.mainUI.bindSection container.layoutUI
 L75Check (container.layoutUI.owner==a) "Container Layout uses the same layer owner"
 container.transformsUI.open=true;container.mainUI.bindSection container.transformsUI
 L75Rows container.transformsUI
)
