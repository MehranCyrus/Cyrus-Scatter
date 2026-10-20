(
 if not matchPattern MCPFixtureDir pattern:"*/update08671-test*-202*/" do throw "Owned installer host required"
 global UIInstallerTimer,UIInstallerPhase=0,UIInstallerDeadline=0,UIInstallerOutput,UIInstallerPassed=false
 UIInstallerOutput=createFile (MCPFixtureDir+"installer-host.txt")
 fn UIInstallerTick sender event = (
  try (
   local forms=(dotNetClass "System.Windows.Forms.Application").OpenForms,window=undefined
   for i=0 to forms.Count-1 where matchPattern forms.Item[i].Text pattern:"Cyrus Scatter 0.86.7.1 / Max *" do window=forms.Item[i]
   if window!=undefined do (
    local info=undefined,analyze=undefined,apply=undefined
    for controlIndex=0 to window.Controls.Count-1 do (
     local control=window.Controls.Item[controlIndex]
     if (control.GetType()).FullName=="System.Windows.Forms.TextBox" do info=control
     if (control.GetType()).FullName=="System.Windows.Forms.FlowLayoutPanel" do for buttonIndex=0 to control.Controls.Count-1 do (
      local button=control.Controls.Item[buttonIndex]
      if button.Text=="Analyze" do analyze=button
      if button.Text=="Apply" do apply=button
     )
    )
    if UIInstallerPhase==0 then (analyze.PerformClick();UIInstallerPhase=1)
    else if UIInstallerPhase==1 and apply.Enabled then (
     if not matchPattern info.Text pattern:"*Library new bytes: 0*" do throw "MZP analysis charged for content during plugin-only installation."
     format "PASS: actual hosted Analyze exposes plugin-only plan\n" to:UIInstallerOutput;flush UIInstallerOutput
     apply.PerformClick();UIInstallerPhase=2
    )
    else if UIInstallerPhase==2 and matchPattern info.Text pattern:"Completed.*" then (
     format "PASS: actual hosted Apply completes on the UI thread\nSUCCESS\n" to:UIInstallerOutput;flush UIInstallerOutput
     UIInstallerPassed=true;sender.Stop();window.Close()
    )
    if matchPattern info.Text pattern:"*Log:*" do throw info.Text
   )
   if timeStamp()>UIInstallerDeadline do throw "Hosted installer UI timed out."
  )catch(
   format "ERROR %\n" (getCurrentException()) to:UIInstallerOutput;flush UIInstallerOutput
   sender.Stop()
   local forms=(dotNetClass "System.Windows.Forms.Application").OpenForms
   for i=forms.Count-1 to 0 by -1 where matchPattern forms.Item[i].Text pattern:"Cyrus Scatter 0.86.7.1 / Max *" do forms.Item[i].Close()
  )
 )
 try(
  local year=((maxVersion())[1]/1000+1998) as string
  local payload=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\build\update-08671-20261020\payload"+year
  dotNet.loadAssembly (payload+"/CyrusInstaller.dll")
  local file=dotNetClass "System.IO.File",inventory=file.ReadAllBytes (payload+"/InstallInventory.txt")
  local engine=dotNetObject "Cyrus.Setup.InstallEngine" payload ((dotNetClass "Cyrus.Setup.InstallEngine").Hash inventory)
  local base=MCPFixtureDir+"installer-ui"
  local paths=dotNetObject "Cyrus.Setup.InstallPaths" (base+"/s") (base+"/st") (base+"/m") (base+"/p") (base+"/r")
  paths.LibraryStatePath=base+"/library-state.txt"
  UIInstallerTimer=dotNetObject "System.Windows.Forms.Timer";UIInstallerTimer.Interval=100
  dotNet.addEventHandler UIInstallerTimer "Tick" UIInstallerTick
  UIInstallerDeadline=timeStamp()+30000;UIInstallerTimer.Start()
  (dotNetClass "Cyrus.Setup.LibraryOptions").ShowForMax engine paths
  if not UIInstallerPassed do throw "Hosted installer did not complete."
 )catch(format "ERROR %\n" (getCurrentException()) to:UIInstallerOutput)
 if UIInstallerTimer!=undefined do (UIInstallerTimer.Stop();UIInstallerTimer.Dispose())
 close UIInstallerOutput
)
