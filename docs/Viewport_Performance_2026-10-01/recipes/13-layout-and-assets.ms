try (
 makeDir (CVDir+"layout")
 CVBFrameRows=#();CVBCaseRows=#()
 CVBCallbacks()
 for r=1 to 3 do CVBRunCase "two_views_baseline" frames:40 warmup:6 repeat:r
 max tool maximize
 windows.processPostedMessages()
 for r=1 to 3 do CVBRunCase "maximized_baseline" frames:40 warmup:6 repeat:r
 CVBCallbacks scatter:false analyzer:false
 for r=1 to 3 do CVBRunCase "maximized_callbacks_off" frames:40 warmup:6 repeat:r
 CVBWrite (CVDir+"layout")
 max tool maximize
 windows.processPostedMessages()
 CVBRestoreCallbacks()
 viewport.setTM CVOriginalView;redrawViews()
 local f=createFile (CVDir+"source-assets.txt")
 for n in objects where (classof n as string)=="CProxy" do (
  format "\n%\n" n.name to:f
  try(showProperties n to:f)catch()
  for k in getPropNames n where matchPattern (k as string) pattern:"*file*" do (
   local value=try(getProperty n k)catch(undefined)
   format "% = % exists=%\n" k value (if classof value==String then doesFileExist value else undefined) to:f
  )
  format "polygon count %\n" (try(getPolygonCount n)catch("unavailable")) to:f
 )
 close f
 CSPWriteText (CVDir+"layout-success.txt") "Layout restored after tests."
)catch(
 try(CVBRestoreCallbacks())catch()
 CSPWriteText (CVDir+"layout-error.txt") ((getCurrentException())+"\n"+(getCurrentExceptionStackTrace()))
)
