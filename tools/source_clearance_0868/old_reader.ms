-- The previous qualified runtime must refuse new scene/recipe semantics.
(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test-clearance-old-reader-2027/" do throw "Owned previous-runtime host required"
 local log=createFile (MCPFixtureDir+"old-reader.txt")
 fn check value label log = (format "%: %\n" (if value then "PASS" else "FAIL") label to:log;flush log;if not value do throw label)
 try (
  CyrusPointSuspended=true
  local loaded=false
  try(loaded=loadMaxFile @"F:/Cursor/_Cyrus_Apps/CyrusScatter/build/mcp-qualification/update08671-test-clearance-new-2027/clearance59.max" quiet:true)catch(format "Load refusal: %\n" (getCurrentException()) to:log)
  local controllers=for node in objects where classOf node==AminScatterObject collect node
  local rejected=not loaded
  for node in controllers do (
   local denied=false
   try(node.baseObject.procAssertSchema())catch(denied=true;format "Schema refusal: %\n" (getCurrentException()) to:log)
   check denied "Previous runtime denies schema 59 controller evaluation" log
   rejected=true
  )
  check rejected "New semantics cannot silently evaluate in the previous runtime" log
  local failed=false
  try(cyrusRecipeRead @"F:/Cursor/_Cyrus_Apps/CyrusScatter/AminScatter/tests/data/recipe_v8_defaults.json")catch(failed=true;format "Recipe refusal: %\n" (getCurrentException()) to:log)
  check failed "Previous recipe reader refuses format 8" log
  format "SUCCESS\n" to:log
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:log)
 close log
)
