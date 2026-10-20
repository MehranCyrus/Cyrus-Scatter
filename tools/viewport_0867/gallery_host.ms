(
 if not matchPattern MCPFixtureDir pattern:"*/viewport0867-test*-202*/" do throw "Owned gallery host required"
 local output=createFile (MCPFixtureDir+"gallery-host.txt"),gallery=undefined
 fn check value message output=(format "%: %\n" (if value then "PASS" else "FAIL") message to:output;flush output;if not value do throw message)
 fn waitGallery gallery=(
  local deadline=timeStamp()+15000
  while gallery.IsLoading do (
   (dotNetClass "System.Windows.Forms.Application").DoEvents();sleep 0.01
   if timeStamp()>deadline do throw "Gallery timeout"
  )
 )
 try(
  dotNet.loadAssembly (MCPFixtureDir+"scripts/CyrusGallery.dll")
  local catalog=dotNetObject "CyrusScatter.UI.IndividualModelCatalog"
  catalog.Load @"F:\Cursor\_Cyrus_Apps\CyrusScatter\dist\CyrusScatter-0.86.7-20261020\Content\Library" "0.86.7" ((maxVersion())[1]/1000+1998)
  check (catalog.Count==96 and catalog.CategoryCount==7) "Shared catalog loads: 96 models / 7 categories" output
  gallery=dotNetObject "CyrusScatter.UI.LibraryGallery"
  gallery.Size=dotNetObject "System.Drawing.Size" 800 500;gallery.TileSize=176
  local handle=gallery.Handle
  gallery.BeginPage()
  for i=0 to catalog.Count-1 do (
   local item=catalog.MatchingAt "" "" i
   gallery.AddItem item.Id item.Name item.Category item.Thumbnail item.ThumbnailHash item.ThumbnailBytes
  )
  gallery.EndPage 0;waitGallery gallery
  local before=gallery.JobsStarted
  local flags=(dotNetClass "System.Reflection.BindingFlags"),kind=gallery.GetType()
  local wheel=kind.GetMethod "OnMouseWheel" (dotNet.combineEnums flags.Instance flags.NonPublic)
  local event=dotNetObject "System.Windows.Forms.MouseEventArgs" ((dotNetClass "System.Windows.Forms.MouseButtons").None) 0 50 50 -600
  wheel.Invoke gallery #(event);waitGallery gallery
  local after=gallery.JobsStarted
  check (gallery.AutoScrollPosition.Y<0 and after>before) "Wheel after idle decodes new thumbnails without clicking" output
  event=dotNetObject "System.Windows.Forms.MouseEventArgs" ((dotNetClass "System.Windows.Forms.MouseButtons").None) 0 50 50 600
  wheel.Invoke gallery #(event);waitGallery gallery
  check (gallery.JobsStarted==after) "Warm revisit reuses decoded images" output
  gallery.Size=dotNetObject "System.Drawing.Size" 1100 700;waitGallery gallery
  gallery.BeginPage()
  local item=catalog.MatchingAt "A027" "Leaves" 0
  gallery.AddItem item.Id item.Name item.Category item.Thumbnail item.ThumbnailHash item.ThumbnailBytes
  gallery.EndPage 0;waitGallery gallery
  check (gallery.ItemCount==1 and gallery.SelectedId==item.Id) "Search/category replacement keeps valid selection" output
  gallery.BeginPage()
  for i=0 to catalog.Count-1 do (
   item=catalog.MatchingAt "" "" i
   gallery.AddItem item.Id item.Name item.Category item.Thumbnail item.ThumbnailHash item.ThumbnailBytes
  )
  gallery.EndPage 0;gallery.Dispose()
  check gallery.IsDisposed "Closing during thumbnail work disposes the control" output
  format "SUCCESS\n" to:output
 )catch(format "ERROR %\n%\n" (getCurrentException()) (getCurrentExceptionStackTrace()) to:output)
 if gallery!=undefined do gallery.Dispose()
 close output
)
