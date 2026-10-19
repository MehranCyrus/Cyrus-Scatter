using System;
using System.IO;
using System.Reflection;
using System.Drawing;
using System.Windows.Forms;
using Cyrus.Setup;
static class DistributionChecks {
 static int checks;
 static void Check(bool value,string text){if(!value)throw new Exception(text);checks++;Console.WriteLine("PASS: "+text);}
 static string[] Values(Assembly assembly,string name){return (string[])assembly.GetType("Cyrus.Setup.BuildIdentity").GetField(name,BindingFlags.Public|BindingFlags.Static).GetValue(null);}
 [STAThread] static int Main(string[] args){try{
  AppContext.SetSwitch("Switch.System.IO.UseLegacyPathHandling",false);AppContext.SetSwitch("Switch.System.IO.BlockLongPaths",false);
  var assembly=Assembly.LoadFrom(args[0]);string root=Path.GetFullPath(args[1]);
  if(!root.StartsWith(@"F:\Cursor\_Cyrus_Apps\CyrusScatter\build\library-surface-0861-",StringComparison.OrdinalIgnoreCase))throw new Exception("Owned fixture directory required");
  var years=Values(assembly,"Years");var hashes=Values(assembly,"PackageHashes");var inventories=Values(assembly,"InventoryHashes");var resources=Values(assembly,"Resources");
  Check(String.Join(",",years)=="2024,2026,2027","One EXE has three distinct host descriptors");
  Application.EnableVisualStyles();
  using(var form=(Form)Activator.CreateInstance(assembly.GetType("Cyrus.Setup.SetupWindow"),true)) {
   var flags=BindingFlags.Instance|BindingFlags.NonPublic;var host=(ComboBox)form.GetType().GetField("host",flags).GetValue(form);var profile=(TextBox)form.GetType().GetField("profile",flags).GetValue(form);
   Check(host.Items.Count==3&&host.Items[0].ToString().Contains("preview"),"Installer exposes three hosts and labels unqualified 2024 preview");
   for(int index=0;index<years.Length;index++){host.SelectedIndex=index;Check(profile.Text.Contains(years[index]+" - 64bit"),"Host selector changes the profile to "+years[index]);}
   foreach(float scale in new[]{1.0f,1.5f}) {
    if(scale!=1)form.Scale(new SizeF(scale,scale));form.PerformLayout();
    var table=(TableLayoutPanel)form.Controls[0];
    foreach(Control control in table.Controls)Check(control.Right<=table.ClientSize.Width&&control.Bottom<=table.ClientSize.Height,"Installer control fits at scripted scale "+scale+": "+control.GetType().Name);
    using(var bitmap=new Bitmap(form.Width,form.Height)){form.DrawToBitmap(bitmap,new Rectangle(0,0,form.Width,form.Height));Directory.CreateDirectory(root);bitmap.Save(Path.Combine(root,"installer-scale-"+scale+".png"));}
   }
  }
  for(int index=0;index<years.Length;index++){
   string year=years[index],parent=Path.Combine(root,"extract-"+year);Directory.CreateDirectory(parent);
   string package=Distribution.Extract(assembly,parent,hashes[index],null,resources[index]);
   var engine=new InstallEngine(package,inventories[index]);Check(engine.Year==year,"Embedded payload/inventory host matches "+year);
   string target=Path.Combine(root,"owned-"+year);var paths=new InstallPaths(Path.Combine(target,"scripts"),Path.Combine(target,"startup"),Path.Combine(target,"macros"),Path.Combine(target,"profile"));
   Directory.CreateDirectory(paths.Profile);string settings=Path.Combine(paths.Profile,"Plugin.UserSettings.ini");File.WriteAllText(settings,"[Directories]\r\nOtherPlugin=F:\\Keep\r\nUnrelatedHost2025=F:\\KeepOther\r\n");
   string personal=Path.Combine(target,"personal-recipe.json"),activation=Path.Combine(target,"personal.cyruslicense");File.WriteAllText(personal,"preserve personal content");File.WriteAllText(activation,"owned inert activation sentinel");
   string release=engine.Install(paths);Check(File.Exists(Path.Combine(release,"bin","AminScatter.dlx")),"Actual native payload stages for "+year);
   Check(File.Exists(Path.Combine(release,"Library-0.86.1","inventory.json")),"Bundled presets stage for "+year);
   Check(File.ReadAllText(settings).Contains("CyrusScatter"+year+"=")&&File.ReadAllText(settings).Contains("OtherPlugin=F:\\Keep"),"Host-specific registration preserves unrelated settings "+year);
   string before=File.ReadAllText(settings);Check(engine.Install(paths)==release&&File.ReadAllText(settings)==before,"Identical repair retains registration "+year);
   InstallEngine.RemoveRegistration(paths,year);Check(!File.ReadAllText(settings).Contains("CyrusScatter"+year+"=")&&File.ReadAllText(settings).Contains("OtherPlugin="),"Unregister removes only this host registration "+year);
   Check(File.ReadAllText(personal)=="preserve personal content"&&File.ReadAllText(activation)=="owned inert activation sentinel","Personal recipe/activation sentinels survive "+year);
   bool rejected=false;try{Distribution.FromProfile(Path.Combine(root,(year=="2027"?"2026":"2027")+" - 64bit","3dsMax.ini"),year);}catch(IOException){rejected=true;}Check(rejected,"Wrong host profile rejected "+year);
   rejected=false;try{new InstallEngine(package,new string('0',64));}catch(IOException){rejected=true;}Check(rejected,"Changed inventory identity rejected "+year);
   var failurePaths=new InstallPaths(Path.Combine(target,"cancel/scripts"),Path.Combine(target,"cancel/startup"),Path.Combine(target,"cancel/macros"),Path.Combine(target,"cancel/profile"));
   rejected=false;try{engine.Install(failurePaths,value=>{if(value=="publishing:2")throw new OperationCanceledException("Owned cancellation");});}catch(OperationCanceledException){rejected=true;}
   Check(rejected&&!File.Exists(Path.Combine(failurePaths.Startup,"CyrusScatterStartup.ms"))&&!File.Exists(Path.Combine(failurePaths.Macros,"CyrusScatter.mcr")),"Cancellation rolls back publication "+year);
   Distribution.Cleanup(parent,package);Check(!Directory.Exists(package),"Owned extraction cleanup "+year);
  }
  Console.WriteLine("PASSED "+checks+" universal distribution checks; artist profiles untouched");return 0;
 }catch(Exception error){Console.WriteLine(error);return 1;}}
}
