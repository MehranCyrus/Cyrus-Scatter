(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-202*/" do throw "Owned library host required"
 local output=createFile (MCPFixtureDir+"library-binding.txt")
 try(
  local expected=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\dist\CyrusScatter-0.86.7-20261020\Content\Library"
  local actual=CyrusRecipeBundledDirectory (CyrusLibraryVersion())
  if toLower actual!=toLower expected do throw ("Wrong shared library: "+actual)
  CyrusOpenRecipeLibrary VRoot
  local browser=CyrusRecipeBrowser
  if browser.modelCatalog.Count!=96 or toLower browser.modelCatalog.Root!=toLower expected do throw "The real browser did not bind the shared catalog."
  format "PASS: actual browser uses content revision 0.86.7 with plugin 0.86.7.2\n" to:output
  browser.refresh()
  if browser.modelCatalog.Count!=96 do throw "Browser refresh lost the shared catalog."
  format "PASS: refresh retains the complete shared catalog\n" to:output
  destroyDialog browser
  format "SUCCESS\n" to:output
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 if CyrusRecipeBrowser!=undefined do try(destroyDialog CyrusRecipeBrowser)catch()
 close output
)
