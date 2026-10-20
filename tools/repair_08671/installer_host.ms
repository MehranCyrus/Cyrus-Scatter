(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-202*/" do throw "Owned installer host required"
 global RepairInstallerTimer,RepairInstallerPhase=0,RepairInstallerDeadline,RepairInstallerOutput,RepairInstallerPassed=false
 RepairInstallerOutput=createFile (MCPFixtureDir+"installer-corrected.txt")
 fn RepairInstallerTick sender event = (
  try (
   local forms=(dotNetClass "System.Windows.Forms.Application").OpenForms,window=undefined
   for i=0 to forms.Count-1 where forms.Item[i].Text=="Cyrus Scatter 0.86.7.1" do window=forms.Item[i]
   if window!=undefined do (
    local view=undefined
    for i=0 to window.Controls.Count-1 where (window.Controls.Item[i].GetType()).FullName=="Cyrus.Setup.InstallerView" do view=window.Controls.Item[i]
    if RepairInstallerPhase==0 then (view.Primary.PerformClick();RepairInstallerPhase=1)
    else if RepairInstallerPhase==1 and view.Primary.Enabled do (
     if not matchPattern view.Status.Text pattern:"Cyrus Scatter 0.86.7.1 installed.*" do throw view.Status.Text
     if not matchPattern view.Details.Text pattern:"*Library new bytes: 0*" do throw "Content should be reused."
     format "PASS: actual hosted Install click completed with existing content and zero content copies\n" to:RepairInstallerOutput
     if view.Primary.Text!="Update" do throw "Installed host should offer Update."
     format "PASS: installed host offers Update\nSUCCESS\n" to:RepairInstallerOutput;flush RepairInstallerOutput
     RepairInstallerPassed=true;sender.Stop();window.Close()
    )
   )
   if timeStamp()>RepairInstallerDeadline do throw "Hosted installer timed out."
  )catch(
   format "ERROR %\n" (getCurrentException()) to:RepairInstallerOutput;flush RepairInstallerOutput;sender.Stop()
   local forms=(dotNetClass "System.Windows.Forms.Application").OpenForms
   for i=forms.Count-1 to 0 by -1 where forms.Item[i].Text=="Cyrus Scatter 0.86.7.1" do forms.Item[i].Close()
  )
 )
 try(
  local year=((maxVersion())[1]/1000+1998) as string
  local payload=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\build\repair-08671-20261020\payload-final"+year
  dotNet.loadAssembly (payload+"/CyrusInstaller.dll")
  local file=dotNetClass "System.IO.File",inventory=file.ReadAllBytes (payload+"/InstallInventory.txt")
  local engine=dotNetObject "Cyrus.Setup.InstallEngine" payload ((dotNetClass "Cyrus.Setup.InstallEngine").Hash inventory)
  local base=MCPFixtureDir+"installer-corrected"
  local paths=dotNetObject "Cyrus.Setup.InstallPaths" (base+"/s") (base+"/st") (base+"/m") (base+"/p") (base+"/r")
  paths.LibraryStatePath=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\build\update-08671-20261020\real-installer\shared\library-state.txt"
  RepairInstallerTimer=dotNetObject "System.Windows.Forms.Timer";RepairInstallerTimer.Interval=100
  dotNet.addEventHandler RepairInstallerTimer "Tick" RepairInstallerTick
  RepairInstallerDeadline=timeStamp()+60000;RepairInstallerTimer.Start()
  (dotNetClass "Cyrus.Setup.LibraryOptions").ShowForMax engine paths
  if not RepairInstallerPassed do throw "Hosted installer did not complete."
 )catch(format "ERROR %\n" (getCurrentException()) to:RepairInstallerOutput)
 if RepairInstallerTimer!=undefined do (RepairInstallerTimer.Stop();RepairInstallerTimer.Dispose())
 close RepairInstallerOutput
)
