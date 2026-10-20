param(
 [string]$Exe='F:\Cursor\_Cyrus_Apps\CyrusScatter\dist\CyrusScatter-0.86.7.1-20261020\CyrusScatter-0.86.7.1-Setup.exe',
 [string]$Output='F:\Cursor\_Cyrus_Apps\CyrusScatter\build\update-08671-apply-original',
 [switch]$Commit
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Windows.Forms,System.Drawing -TypeDefinition @'
using System;
using System.IO;
using System.Reflection;
using System.Threading;
using System.Windows.Forms;
using System.Drawing;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class ApplyProbe {
 [DllImport("user32.dll")] static extern IntPtr GetWindowLongPtr(IntPtr h,int i);
 [DllImport("user32.dll")] static extern IntPtr SetWindowLongPtr(IntPtr h,int i,IntPtr v);
 static object Field(object value,string name) {return value.GetType().GetField(name,BindingFlags.Instance|BindingFlags.NonPublic).GetValue(value);}
 static void Wait(Form f) {
  DateTime deadline=DateTime.UtcNow.AddSeconds(60);
  while((bool)Field(f,"busy")&&DateTime.UtcNow<deadline){Application.DoEvents();Thread.Sleep(10);}
  if((bool)Field(f,"busy"))throw new Exception("Installer UI timeout");
  for(int i=0;i<50;i++){Application.DoEvents();Thread.Sleep(10);}
 }
 public static void Run(string exe,string output,bool commit) {
  output=Path.GetFullPath(output);
  string allowed=Path.GetFullPath(@"F:\Cursor\_Cyrus_Apps\CyrusScatter\build")+Path.DirectorySeparatorChar;
  if(!output.StartsWith(allowed,StringComparison.OrdinalIgnoreCase)||Directory.Exists(output))throw new Exception("Fresh owned output required");
  Directory.CreateDirectory(output);
  Application.EnableVisualStyles();
  using(var log=new StreamWriter(Path.Combine(output,"events.txt")){AutoFlush=true})
  using(var form=(Form)Activator.CreateInstance(Assembly.LoadFrom(exe).GetType("Cyrus.Setup.SetupWindow"),true)) {
   var hosts=(CheckedListBox)Field(form,"hosts");var analyze=(Button)Field(form,"analyze");var apply=(Button)Field(form,"apply");
   var details=(TextBox)Field(form,"details");var options=(Control)Field(form,"options");
   var profiles=(Dictionary<string,string>)Field(form,"profiles");
   foreach(string year in new List<string>(profiles.Keys)) {
    string root=Path.Combine(output,year);Directory.CreateDirectory(root);
    string ini=Path.Combine(root,"max.ini");
    File.WriteAllText(ini,"[Directories]\r\nAdditional Scripts="+root+"\\scripts\r\nAdditional Startup Scripts="+root+"\\startup\r\nAdditional Macros="+root+"\\macros\r\n");
    profiles[year]=ini;
   }
   for(int i=0;i<hosts.Items.Count;i++)hosts.SetItemChecked(i,(string)hosts.Items[i]=="2027");
   hosts.ItemCheck+=(s,e)=>log.WriteLine("ItemCheck "+e.Index+" "+e.CurrentValue+" -> "+e.NewValue+"; apply="+apply.Enabled+"\n"+Environment.StackTrace);
   apply.EnabledChanged+=(s,e)=>log.WriteLine("Apply enabled="+apply.Enabled+"; busy="+Field(form,"busy")+"\n"+Environment.StackTrace);
   form.StartPosition=FormStartPosition.Manual;form.Location=new Point(-3000,-3000);form.ShowInTaskbar=false;
   IntPtr h=form.Handle;SetWindowLongPtr(h,-20,new IntPtr(GetWindowLongPtr(h,-20).ToInt64()|0x08000000));
   form.Show();Application.DoEvents();
   analyze.PerformClick();Wait(form);
   File.WriteAllText(Path.Combine(output,"plan.txt"),details.Text);
   log.WriteLine("AFTER ANALYZE apply="+apply.Enabled+" parent="+apply.Parent.Enabled+" checked="+hosts.CheckedItems.Count);
   using(var image=new Bitmap(form.Width,form.Height)){form.DrawToBitmap(image,new Rectangle(0,0,form.Width,form.Height));image.Save(Path.Combine(output,"after-analyze.png"));}
   if(commit) {
    if(!apply.Enabled)throw new Exception("Apply stays disabled after successful Analyze");
    apply.PerformClick();Wait(form);
    File.WriteAllText(Path.Combine(output,"apply.txt"),details.Text);
    if(!details.Text.StartsWith("Completed."))throw new Exception("Apply did not complete: "+details.Text);
    if(apply.Enabled)throw new Exception("Apply should require a new analysis after completion");
   }
   File.WriteAllText(Path.Combine(output,"result.txt"),"apply_after_analyze="+(!commit&&apply.Enabled)+"\r\ncommit="+commit+"\r\n");
  }
 }
}
'@
[ApplyProbe]::Run($Exe,$Output,$Commit.IsPresent)
