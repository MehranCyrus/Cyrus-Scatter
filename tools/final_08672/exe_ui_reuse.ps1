param([string]$RunName='exe-ui-release',[string]$DeliveryName='CyrusScatter-0.86.7.2-20261020')
$ErrorActionPreference='Stop'
$root='F:\Cursor\_Cyrus_Apps\CyrusScatter'
$delivery="$root\dist\$DeliveryName"
$out="$root\build\final-08672-20261020\$RunName"
if(Test-Path -LiteralPath $out){throw 'Fresh owned fixture required'}
[void][IO.Directory]::CreateDirectory($out)
$exe="$out\CyrusScatter-0.86.7.2-Setup.exe"
Copy-Item -LiteralPath "$delivery\CyrusScatter-0.86.7.2-Setup.exe" -Destination $exe
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type -ReferencedAssemblies System.Windows.Forms,System.Drawing -TypeDefinition @'
using System;
using System.IO;
using System.Reflection;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Drawing;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class FinalInstallerProbe {
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]
 static extern bool CreateHardLink(string path,string existing,IntPtr reserved);
 static object Field(object o,string n){return o.GetType().GetField(n,BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic).GetValue(o);}
 static void Check(bool v,string text,StreamWriter log){if(!v)throw new Exception(text);log.WriteLine("PASS: "+text);}
 static async Task Wait(Form f) {
  DateTime deadline=DateTime.UtcNow.AddMinutes(10);
  while((bool)Field(f,"busy")){if(DateTime.UtcNow>deadline)throw new Exception("UI deadline");await Task.Delay(100);}
  await Task.Delay(100);
 }
 static void Capture(Form f,string p){using(var b=new Bitmap(f.Width,f.Height)){f.DrawToBitmap(b,new Rectangle(0,0,b.Width,b.Height));b.Save(p);}}
 public static void Run(string exe,string output,string zip) {
  if(!Path.GetFullPath(output).StartsWith(@"F:\Cursor\_Cyrus_Apps\CyrusScatter\build\final-08672-20261020\"))throw new Exception("Owned fixture required");
  Application.EnableVisualStyles();Control.CheckForIllegalCrossThreadCalls=true;
  var a=Assembly.LoadFrom(exe);Exception failure=null;
  using(var log=new StreamWriter(Path.Combine(output,"result.txt")){AutoFlush=true})
  using(var f=(Form)Activator.CreateInstance(a.GetType("Cyrus.Setup.SetupWindow"),true)) {
   var profiles=(Dictionary<string,string>)Field(f,"profiles");var hosts=(Dictionary<string,CheckBox>)Field(f,"hosts");
   var view=Field(f,"view");var primary=(Button)Field(view,"Primary");var uninstall=(Button)Field(view,"Uninstall");
   var content=(CheckBox)Field(view,"InstallContent");var status=(Label)Field(view,"Status");var details=(TextBox)Field(view,"Details");var errorLink=(LinkLabel)Field(view,"detailsLink");
   profiles.Clear();
   foreach(string year in hosts.Keys) {
    string p=Path.Combine(output,year);Directory.CreateDirectory(p);string ini=Path.Combine(p,"max.ini");
    File.WriteAllText(ini,"[Directories]\r\nAdditional Scripts="+p+"\\scripts\r\nAdditional Startup Scripts="+p+"\\startup\r\nAdditional Macros="+p+"\\macros\r\n");
    profiles.Add(year,ini);hosts[year].Enabled=true;
    string state=Path.Combine(p,@"cs\library-state.txt");Directory.CreateDirectory(Path.GetDirectoryName(state));
    File.Copy(@"F:\Cursor\_Cyrus_Apps\CyrusScatter\build\final-08672-20261020\exe-ui-final\2027\cs\library-state.txt",state);
   }
   f.GetType().GetField("hostRunning",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(f,new Func<string,bool>(y=>true));
   foreach(var h in hosts.Values)h.Checked=true;
   f.GetType().GetMethod("RefreshSelection",BindingFlags.Instance|BindingFlags.NonPublic).Invoke(f,null);
   f.StartPosition=FormStartPosition.Manual;f.Location=new Point(-3000,-3000);f.ShowInTaskbar=false;
   f.Shown+=async(s,e)=>{
    try {
     Check(content.Visible&&!content.Checked&&!details.Visible&&!errorLink.Visible,"Content is explicit and diagnostics start hidden",log);
     Capture(f,Path.Combine(output,"initial.png"));
     primary.PerformClick();await Wait(f);
     Check(status.Text.Contains("Close 3ds Max")&&errorLink.Visible,"Running host produces actionable failure",log);
     f.GetType().GetField("hostRunning",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(f,new Func<string,bool>(y=>false));
     primary.PerformClick();await Wait(f);
     Check(status.Text=="Installation completed. You can now open Max."&&!details.Visible&&!errorLink.Visible,"Plugin-only success is concise with no details",log);
     foreach(string year in hosts.Keys)Check(File.Exists(Path.Combine(output,year+"/scripts/CyrusScatter/installed.txt")),"Matched Max "+year+" plugin installed",log);
     content.Checked=true;
     primary.PerformClick();await Wait(f);
     Check(status.Text.Contains("content ZIP not found")&&errorLink.Visible,"Missing checked ZIP gives a clear error",log);
     Capture(f,Path.Combine(output,"missing-content.png"));
     Check(CreateHardLink(Path.Combine(output,Path.GetFileName(zip)),zip,IntPtr.Zero),"Test reuses archive bytes through a hard link",log);
     hosts["2024"].Checked=hosts["2026"].Checked=false;
     primary.PerformClick();await Wait(f);
     Check(status.Text=="Installation completed. You can now open Max."&&!errorLink.Visible&&!details.Visible,"Actual final EXE validates the real ZIP and reuses the installed library",log);
     string state=Path.Combine(output,@"2027\cs\library-state.txt");
     var reg=a.GetType("Cyrus.Content.LibraryLocation").GetMethod("Read").Invoke(null,new object[]{state});
     string library=(string)Field(reg,"Root");
     Check(library.StartsWith(@"F:\Cursor\_Cyrus_Apps\CyrusScatter\build\final-08672-20261020\exe-ui-final\2027\cs\Library\packs\")&&File.Exists(Path.Combine(library,"model-catalog.json")),"Library is managed independently of plugin runtime",log);
     File.WriteAllText(Path.Combine(output,"library-root.txt"),library);
     Capture(f,Path.Combine(output,"completed.png"));
     primary.PerformClick();await Wait(f);
     Check(status.Text.StartsWith("Installation completed")&&details.Text.Contains("Library new bytes: 0")&&details.Text.Contains("Plugin new bytes: 0"),"Repeat checked update copies zero plugin/library bytes",log);
     // Relocated test profiles deliberately have isolated registration files.
     // Point them at the same verified library to exercise host reuse without
     // making extra content copies. Standard artist profiles share one state file.
     foreach(string year in new[]{"2024","2026"}){string dst=Path.Combine(output,year+@"\cs\library-state.txt");Directory.CreateDirectory(Path.GetDirectoryName(dst));File.Copy(state,dst,true);}
     content.Checked=false;hosts["2024"].Checked=hosts["2026"].Checked=true;
     primary.PerformClick();await Wait(f);
     foreach(string year in hosts.Keys) {
      var paths=a.GetType("Cyrus.Setup.Distribution").GetMethod("FromProfile").Invoke(null,new object[]{profiles[year],year});
      string found=(string)a.GetType("Cyrus.Setup.InstallEngine").GetMethod("SuggestContentDirectory").Invoke(null,new[]{paths});
      Check(found==library,"Max "+year+" reuses one installed library",log);
     }
     hosts["2024"].Checked=hosts["2026"].Checked=false;
     await (Task)f.GetType().GetMethod("Run",BindingFlags.Instance|BindingFlags.NonPublic).Invoke(f,new object[]{true});
     Check(status.Text.StartsWith("Uninstall completed")&&Directory.Exists(library),"Uninstall keeps shared content",log);
     Check(File.Exists(Path.Combine(output,@"2024\scripts\CyrusScatter\installed.txt")),"Uninstall preserves other Max installations",log);
     log.WriteLine("SUCCESS");
    }catch(Exception error){failure=error;log.WriteLine(error);File.WriteAllText(Path.Combine(output,"failure-details.txt"),details.Text);}
    finally{f.Close();}
   };
   Application.Run(f);
  }
  if(failure!=null)throw failure;
 }
}
'@
[FinalInstallerProbe]::Run($exe,$out,"$delivery\CyrusScatter-Content-0.86.7.zip")
(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant() | Set-Content -LiteralPath "$out\exe-sha256.txt"
