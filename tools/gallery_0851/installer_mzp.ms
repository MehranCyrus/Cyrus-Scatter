-- Historical diagnostic: Max 2027's Qt messageBox is not observed by this
-- DialogMonitorOPS fixture. Use installer_mzp.py for the passing wrapper test.
-- Execute the exact packaged wrapper in redirected, disposable Max paths.
(
 if not matchPattern MCPFixtureDir pattern:"*/build/mcp-qualification/foundation-roadmap-gallery0851-*/" do throw "Owned host required."
 local io=dotNetClass "System.IO.Path",file=dotNetClass "System.IO.File"
 local base=toLower (trimRight (io.GetFullPath MCPFixtureDir) "\\/")
 for path in #((getDir #userScripts),(getDir #userStartupScripts),(getDir #userMacros),(getFilenamePath (getMAXIniFile()))) do (
  local resolved=toLower (trimRight (io.GetFullPath path) "\\/")
  if resolved!=base and not matchPattern resolved pattern:(base+"\\*") do throw "Installer fixture destination is outside its owned profile."
 )
 local directory=file.ReadAllText (MCPFixtureDir+"installer-pilot-payload.txt")
 local log=createFile (MCPFixtureDir+"installer-wrapper-"+(timeStamp() as string)+".txt"),oldEnabled=DialogMonitorOPS.Enabled
 global GalleryInstallerDialogs=#()
 fn GalleryInstallerNotice = (
  local handle=DialogMonitorOPS.GetWindowHandle(),title=UIAccessor.GetWindowText handle
  if matchPattern title pattern:"Cyrus Scatter*" do (
   append GalleryInstallerDialogs #(title,for child in UIAccessor.GetChildWindows handle collect UIAccessor.GetWindowText child)
   UIAccessor.PressButtonByName handle "OK"
  )
  true
 )
 try (
  DialogMonitorOPS.RegisterNotification GalleryInstallerNotice id:#GalleryInstallerFixture
  DialogMonitorOPS.Enabled=true
  fileIn (pathConfig.appendPath directory "install.ms")
  DialogMonitorOPS.UnRegisterNotification id:#GalleryInstallerFixture;DialogMonitorOPS.Enabled=oldEnabled
  format "Dialog: %\n" GalleryInstallerDialogs to:log;flush log
  if GalleryInstallerDialogs.count!=1 or GalleryInstallerDialogs[1][1]!="Cyrus Scatter 0.85.1" do throw "Packaged wrapper did not report successful installation."
  local receipt=file.ReadAllLines (pathConfig.appendPath (getDir #userScripts) "CyrusScatter/installed.txt")
  local release=receipt.GetValue 2
  if not doesFileExist (pathConfig.appendPath release "CyrusScatter.ms") do throw "Installed script missing."
  if not doesFileExist (pathConfig.appendPath release "Library-0.85.1/inventory.json") do throw "Installed library missing."
  format "PASS: exact packaged install.ms executed in Max 2027 with redirected profile paths.\nRelease: %\n" release to:log;close log
 )catch(
  DialogMonitorOPS.UnRegisterNotification id:#GalleryInstallerFixture;DialogMonitorOPS.Enabled=oldEnabled
  format "ERROR: %\n" (getCurrentException()) to:log;close log;throw()
 )
)
