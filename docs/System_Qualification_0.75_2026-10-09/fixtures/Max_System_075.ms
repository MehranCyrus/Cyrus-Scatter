-- Focused current-system checks. Load after P07 acceptance definitions in an owned host.
global Q75Check,Q75Checks=#(),Q75Sources,Q75OtherBindings
fn Q75Check condition message = (
 if not condition do throw ("System 0.75: "+message)
 append Q75Checks message
 local f=createFile (MCPFixtureDir+"system075-checks.txt")
 for item in Q75Checks do format "%\n" item to:f
 close f
)
fn Q75OtherBindings = (
 P07Case="Other control bindings";P07New count:50
 select P07Node;max modify mode;modPanel.setCurrentObject P07Root
 if not P07Root.mainUI.controlsReady do P07Root.mainUI.mountTimer.tick()
 local f=createFile (MCPFixtureDir+"other-control-bindings.tsv")
 for spec in #(#("general.host","enabledCheck"),#("general.updateUI","updateRadio"),#("general.updateUI","updateNow")) do (
  if not isProperty P07Root.mainUI (spec[2] as name) do throw ("Missing "+spec[2])
  format "%.%\tBOUND\n" spec[1] spec[2] to:f
 )
 CyrusOpenLayerEditor P07Root P07Layer
 for controlName in #("updateNow","layerList","setList","assetsTab","populationTab","paintTab","transformTab","spacingTab","statisticsTab","refreshButton") do (
  if not isProperty CyrusLayerEditor (controlName as name) do throw ("Missing editor "+controlName)
  format "general.editor.%\tBOUND\n" controlName to:f
 )
 CyrusCloseLayerEditor()
 local c=P07Layer.containerCreate()
 select c;modPanel.setCurrentObject c.baseObject
 if not c.mainUI.controlsReady do c.mainUI.mountTimer.tick()
 for controlName in #("consumerList","widthSpin","lengthSpin","labelCheck","sourceList","assignOwner","editLayer") do (
  if not isProperty c.containerUI (controlName as name) do throw ("Missing container "+controlName)
  format "container.properties.%\tBOUND\n" controlName to:f
 )
 close f
)
fn Q75Sources = (
 Q75OtherBindings()
 for trial=1 to 3 do (
  P07Case="Repeated Live pair render publication";P07New count:100
  local root=P07Root,first=P07Layer
  root.newLayer();local later=root.selectedLayer();later.sources=#(P07Source);later.amount=100;later.paintEnabled=false
  root.updateMode=2;root.autoRender=true;root.refreshAll()
  Q75Check (CyrusPFBuild()) "Initial render bridge builds"
  root.procSetPair 2 first later true 0 100000 false;AminScatterRenderBegin()
  Q75Check (later.generatedCount==0 and CyrusPFData.count==1 and CyrusPFData[1].count==100 and first.previewError=="" and later.previewError=="") ("Live pair rule reaches render, repeat "+trial as string)
  AminScatterRenderEnd();CyrusPFClear();root.autoRender=false
 )
 P07Case="System source controls";P07New count:1000
 local r=P07Root,a=P07Layer,s=P07Source
 select P07Node;max modify mode;modPanel.setCurrentObject r
 if not r.mainUI.controlsReady do r.mainUI.mountTimer.tick()
 local page=r.modelsUI
 page.open=true;page.advancedToggle.checked=true;r.mainUI.bindSection page
 page.sourceUI_addPoint.pressed()
 Q75Check (a.sources.count==2 and a.isPointSource 2 and a.isEmptySource 2) "Add Point button creates a point placeholder"
 max undo
 Q75Check (a.sources.count==1) "Add Point Undo removes its source slot"
 max redo
 Q75Check (a.sources.count==2 and a.isPointSource 2) "Add Point Redo restores point kind"
 page=r.modelsUI;r.mainUI.bindSection page
 page.sourceUI_addEmpty.pressed()
 Q75Check (a.sources.count==3 and a.isEmptySource 3 and not a.isPointSource 3) "Add Empty button creates a distinct empty slot"
 page.sourceUI_plantList.selection=#{1,2};page.sourceUI_groupColor.changed red
 Q75Check (a.sourceColor 1==red and a.sourceColor 2==red and a.sourceColor 3!=red) "Multi-selection grouping edits only selected rows"
 page.sourceUI_plantList.selection=#{1};page.sourceUI_showSelectedColor()
 local sceneName=s.name
 page.sourceUI_sourceName.entered "Tree label"
 Q75Check (a.sourceLabel 1=="Tree label" and s.name==sceneName) "Source alias preserves scene node name"
 local group=a.sourceColor 1
 page.sourceUI_idColor.changed blue
 Q75Check (a.sourceColor 1==group) "Identification color does not change assignment group"
 page.sourceUI_weightSpin.changed 0.0
 local rows=(r.evaluateGroups())[1]
 Q75Check ((for row in rows where row[2]==1 collect row).count==0) "Zero source weight excludes that source"
 page.sourceUI_weightSpin.changed 1.0
 local replacement=box name:"Q75_Replacement" pos:[1400,0,0]
 page.sourceUI_plantList.selection=#{2};page.sourceUI_showSelectedColor()
 page.sourceUI_replacePoint.picked replacement
 Q75Check (a.sources[2]==replacement and not a.isPointSource 2 and not a.isEmptySource 2) "Replace Point callback changes only selected slot"
 page.sourceUI_plantList.selection=#{1};page.sourceUI_showSelectedColor()
 page.sourceUI_radiusSourceSpin.changed 7.0;page.sourceUI_sourceScaleSpin.changed 2.0
 page.sourceUI_followRadiusCheck.changed true
 Q75Check (a.sourceRadii[1]==7.0 and a.sourceScales[1]==2.0 and a.sourceFollowScale[1]) "Radius scale and Follow Scale callbacks save selected source settings"
 page.sourceUI_plantList.selection=#{2,3};page.sourceUI_removePlant.pressed()
 Q75Check (a.sources.count==1 and a.sources[1]==s and a.sourceRadii[1]==7.0 and a.sourceLabel 1=="Tree label") "Remove multiple rows preserves remaining metadata"
 max undo
 Q75Check (a.sources.count==3 and a.sources[2]==replacement and a.isEmptySource 3) "Remove source rows Undo restores types and nodes"
 r.refreshAll()
 local before=P07Fingerprint r,path=MCPFixtureDir+"System075-Sources.max"
 saveMaxFile path quiet:true;loadMaxFile path quiet:true
 r=(getNodeByName "P07_Controller").baseObject;a=r.layerObjects[1]
 Q75Check ((P07Fingerprint r) as string==before as string and a.sourceLabel 1=="Tree label") "Source types aliases groups and output survive reopen"
 true
)

