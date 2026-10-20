param([string]$RunName='exe-ui')
$ErrorActionPreference='Stop'
$root='F:\Cursor\_Cyrus_Apps\CyrusScatter'
$exe="$root\dist\CyrusScatter-0.86.7.1-corrected-20261020\CyrusScatter-0.86.7.1-Setup.exe"
$out="$root\build\repair-08671-20261020\$RunName"
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
Add-Type -ReferencedAssemblies System.Windows.Forms,System.Drawing -TypeDefinition @'
using System;
using System.IO;
using System.Reflection;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Drawing;
using System.Collections.Generic;
public static class InstallerUIProbe {
 static object Field(object o,string n){return o.GetType().GetField(n,BindingFlags.Instance|BindingFlags.Public|BindingFlags.NonPublic).GetValue(o);}
 static void Check(bool v,string text,StreamWriter log){if(!v)throw new Exception(text);log.WriteLine("PASS: "+text);}
 static async Task Wait(Form f){
  DateTime deadline=DateTime.UtcNow.AddSeconds(120);
  while((bool)Field(f,"busy")){if(DateTime.UtcNow>deadline)throw new Exception("UI deadline");await Task.Delay(50);}
  await Task.Delay(150);
 }
 static void Capture(Form f,string path){using(var b=new Bitmap(f.Width,f.Height)){f.DrawToBitmap(b,new Rectangle(0,0,b.Width,b.Height));b.Save(path);}}
 public static void Run(string exe,string output){
  string allowed=@"F:\Cursor\_Cyrus_Apps\CyrusScatter\build\repair-08671-20261020\";
  output=Path.GetFullPath(output);
  if(!output.StartsWith(allowed)||Directory.Exists(output))throw new Exception("Fresh owned output required");
  Directory.CreateDirectory(output);Application.EnableVisualStyles();Control.CheckForIllegalCrossThreadCalls=true;
  var a=Assembly.LoadFrom(exe);Exception failure=null;
  using(var log=new StreamWriter(Path.Combine(output,"result.txt")){AutoFlush=true})
  using(var f=(Form)Activator.CreateInstance(a.GetType("Cyrus.Setup.SetupWindow"),true)){
   var profiles=(Dictionary<string,string>)Field(f,"profiles");
   var hosts=(Dictionary<string,CheckBox>)Field(f,"hosts");
   object view=Field(f,"view");var primary=(Button)Field(view,"Primary");var uninstall=(Button)Field(view,"Uninstall");
   var status=(Label)Field(view,"Status");var details=(TextBox)Field(view,"Details");
   profiles.Clear();
   foreach(string year in hosts.Keys){
    string p=Path.Combine(output,year);Directory.CreateDirectory(p);string ini=Path.Combine(p,"max.ini");
    File.WriteAllText(ini,"[Directories]\r\nAdditional Scripts="+p+"\\scripts\r\nAdditional Startup Scripts="+p+"\\startup\r\nAdditional Macros="+p+"\\macros\r\n");
    profiles.Add(year,ini);hosts[year].Enabled=true;
   }
   f.GetType().GetField("hostRunning",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(f,new Func<string,bool>(y=>true));
   foreach(var pick in hosts.Values)pick.Checked=true;
   f.GetType().GetMethod("RefreshSelection",BindingFlags.Instance|BindingFlags.NonPublic).Invoke(f,null);
   f.StartPosition=FormStartPosition.Manual;f.Location=new Point(-3000,-3000);f.ShowInTaskbar=false;
   f.Shown+=async(s,e)=>{
    try{
     Check(primary.Text=="Install"&&primary.Enabled&&!uninstall.Enabled,"Fresh selection offers Install",log);
     Capture(f,Path.Combine(output,"initial.png"));
     primary.PerformClick();await Wait(f);
     Check(status.Text.Contains("Close 3ds Max")&&primary.Enabled,"Running Max gets a clear actionable message and retry stays enabled",log);
     Check(!File.Exists(Path.Combine(output,"2027/scripts/CyrusScatter/installed.txt")),"Running-host gate changes no registration",log);
     f.GetType().GetField("hostRunning",BindingFlags.Instance|BindingFlags.NonPublic).SetValue(f,new Func<string,bool>(y=>false));
     primary.PerformClick();await Wait(f);
     File.WriteAllText(Path.Combine(output,"install-details.txt"),details.Text);
     Check(status.Text.StartsWith("Cyrus Scatter 0.86.7.1 installed."),"Actual Install click completes on the WinForms event loop",log);
     Check(status.Text.Contains("library is ready"),"Automatic discovery finds the supplied library",log);
     foreach(string year in hosts.Keys){
      Check(File.Exists(Path.Combine(output,year+"/scripts/CyrusScatter/installed.txt")),"Owned Max "+year+" registered",log);
      var paths=a.GetType("Cyrus.Setup.Distribution").GetMethod("FromProfile").Invoke(null,new object[]{profiles[year],year});
      string root=(string)a.GetType("Cyrus.Setup.InstallEngine").GetMethod("SuggestContentDirectory").Invoke(null,new[]{paths});
      Check(root.EndsWith(@"CyrusScatter-0.86.7-20261020\Content\Library"),"Max "+year+" shares original content folder",log);
     }
     Check(primary.Text=="Update"&&uninstall.Enabled,"Installed selection offers Update and Uninstall",log);
     Capture(f,Path.Combine(output,"installed.png"));
     primary.PerformClick();await Wait(f);
     File.WriteAllText(Path.Combine(output,"update-details.txt"),details.Text);
     Check(status.Text.StartsWith("Cyrus Scatter 0.86.7.1 installed.")&&details.Text.Contains("Plugin new bytes: 0"),"Repeated Update reuses complete runtime and content",log);
     foreach(var pick in hosts.Values)pick.Checked=false;
     Check(!primary.Enabled&&!uninstall.Enabled,"Empty selection disables mutation",log);
     hosts["2027"].Checked=true;
     var remove=(Task)f.GetType().GetMethod("Run",BindingFlags.Instance|BindingFlags.NonPublic).Invoke(f,new object[]{true});
     await remove;await Wait(f);
     Check(status.Text.StartsWith("Cyrus Scatter uninstalled."),"Uninstall operation completes",log);
     Check(!File.Exists(Path.Combine(output,"2027/scripts/CyrusScatter/installed.txt")),"Selected host registration removed",log);
     Check(File.Exists(Path.Combine(output,"2024/scripts/CyrusScatter/installed.txt"))&&File.Exists(Path.Combine(output,"2026/scripts/CyrusScatter/installed.txt")),"Other host registrations preserved",log);
     Check(Directory.Exists(@"F:\Cursor\_Cyrus_Apps\CyrusScatter\dist\CyrusScatter-0.86.7-20261020\Content\Library"),"Shared content retained",log);
     log.WriteLine("SUCCESS");
    }catch(Exception error){failure=error;log.WriteLine(error);}finally{f.Close();}
   };
   Application.Run(f);
  }
  if(failure!=null)throw failure;
 }
}
'@
[InstallerUIProbe]::Run($exe,$out)
(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant() | Set-Content -LiteralPath "$out\exe-sha256.txt"
