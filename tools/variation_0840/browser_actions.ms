(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-variation0840-*/" do throw "Owned host required."
 local log=createFile (MCPFixtureDir+"browser-actions-"+(timeStamp() as string)+".txt")
 fn check v label log = (format "%: %\n" (if v then "PASS" else "FAIL") label to:log;flush log;if not v do throw label)
 fn equalRows a b = (if a.count!=b.count do return false;for i=1 to a.count do for j=1 to 8 where a[i][j]!=b[i][j] do return false;true)
 try (
  if theHold.Holding() do theHold.Cancel()
  loadMaxFile (MCPFixtureDir+"variation-core.max") quiet:true useFileUnits:true
  local root=(getNodeByName "Variation qualification").baseObject,leaf=root.layerObjects[1]
  root.updateMode=1;root.refreshAll()
  local document=CyrusRecipeCapture root #(leaf) "UI variation import",bindings=CyrusRecipeSuggestBindings root document,baseline=deepCopy root.groupSnapshotRows[1]
  for choice=1 to 2 do (
   CyrusOpenRecipeLibrary root;local browser=CyrusRecipeBrowser
   if browser.scan!=0 do cyrusRecipeLibraryCancel browser.scan
   browser.scanTimer.active=false;browser.document=document;browser.bindings=bindings;browser.showBindings()
   browser.importVariation.selection=choice;browser.newSetupCheck.checked=true;browser.newSetupCheck.changed true
   check (browser.importButton.text=="Create new setup") "New setup choice names its explicit action" log
   local existing=for node in objects where classof node.baseObject==AminScatterObject collect node
   browser.importButton.pressed()
   local added=for node in objects where classof node.baseObject==AminScatterObject and findItem existing node==0 collect node
   check (added.count==1) "Actual recipe Import button creates the setup" log
   added[1].baseObject.refreshAll()
   check ((equalRows baseline added[1].baseObject.groupSnapshotRows[1])==(choice==2)) "Actual import choice selects New versus Saved variation" log
   browser.closeButton.pressed()
   max undo;check (not isValidNode added[1]) "Recipe UI action remains one Undo" log
  )
  CyrusOpenRecipeLibrary root
  check (CyrusRecipeBrowser.importButton.text=="Add layers" and not CyrusRecipeBrowser.newSetupCheck.checked) "Recipe default clearly names Add layers" log
  CyrusRecipeBrowser.closeButton.pressed()
  -- Numeric files live under this disposable profile's plugcfg directory.
  local presetFolder=substituteString (CyrusPresetDirectory()) "\\" "/"
  format "OWNED PRESET DIRECTORY %\n" presetFolder to:log
  check (matchPattern presetFolder pattern:(MCPFixtureDir+"*")) "Settings files are in the owned profile" log
  CyrusOpenPresets root leaf "population";local browser=CyrusPresetBrowser,savedSeed=leaf.randomSeed
  browser.presetName.text="Owned seed-policy test";browser.saveNew.pressed()
  check (browser.entries.count>0) "Actual Save new stores Amount settings in owned profile" log
  for choice=1 to 3 do (
   leaf.randomSeed=777;browser.seedChoice.selection=choice;browser.applyPreset.pressed()
   local expected=if choice==1 then leaf.randomSeed==savedSeed else if choice==2 then leaf.randomSeed==777 else leaf.randomSeed!=777
   check expected "Actual Apply button obeys Amount seed policy" log
   local applied=leaf.randomSeed
   max undo;check (leaf.randomSeed==777) "Actual Amount Apply remains one Undo" log
   max redo;check (leaf.randomSeed==applied) "Actual Amount Redo retains chosen seed" log
  )
  browser.closeButton.pressed();check (not theHold.Holding()) "No stranded browser transaction" log
  format "PASS: complete\n" to:log;close log
 )catch(
  if CyrusRecipeBrowser!=undefined do try(CyrusRecipeBrowser.closeButton.pressed())catch()
  if CyrusPresetBrowser!=undefined do try(CyrusPresetBrowser.closeButton.pressed())catch()
  format "ERROR: %\n" (getCurrentException()) to:log;close log;throw()
 )
)
