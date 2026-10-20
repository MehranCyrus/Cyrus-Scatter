using System;
using System.IO;
using System.Reflection;
using System.Text;
using Cyrus.Setup;
[assembly:System.Runtime.Versioning.TargetFramework(".NETFramework,Version=v4.0")]
static class RecipientChecks {
 static int checks;
 static void Check(bool value,string message){if(!value)throw new Exception(message);checks++;Console.WriteLine("PASS: "+message);}
 static string Hash(string path){return InstallEngine.Hash(File.ReadAllBytes(path));}
 static InstallPaths Paths(string root,string key){
  string p=Path.Combine(root,key);return new InstallPaths(Path.Combine(p,"Windows user باغ","Max profile","scripts"),Path.Combine(p,"Windows user باغ","Max profile","startup"),Path.Combine(p,"Windows user باغ","Max profile","macros"),Path.Combine(p,"Windows user باغ","Max profile"),Path.Combine(p,"r"));
 }
 static void Profile(InstallPaths paths){Directory.CreateDirectory(paths.Profile);File.WriteAllText(Path.Combine(paths.Profile,"Plugin.UserSettings.ini"),"[Directories]\r\nOtherPlugin=F:\\Keep\r\n",Encoding.Unicode);}
 static string[] Values(Assembly a,string name){return (string[])a.GetType("Cyrus.Setup.BuildIdentity").GetField(name).GetValue(null);}
 static int Main(string[] args){try{
  AppContext.SetSwitch("Switch.System.IO.UseLegacyPathHandling",true);AppContext.SetSwitch("Switch.System.IO.BlockLongPaths",true);
  string root=Path.GetFullPath(args[1]);if(!root.StartsWith(@"D:\CyrusScatterBuilds\if0862\",StringComparison.OrdinalIgnoreCase))throw new Exception("Owned recipient root required");
  Directory.CreateDirectory(root);var a=Assembly.LoadFrom(args[0]);string[] years=Values(a,"Years"),hashes=Values(a,"PackageHashes"),inventories=Values(a,"InventoryHashes"),resources=Values(a,"Resources");
  Check(String.Join(",",years)=="2024,2026,2027","Exact EXE embeds the three matching host packages");
  bool blocked=false;try{Path.GetFullPath(Path.Combine(root,new string('x',230),"file.txt"));}catch(PathTooLongException){blocked=true;}
  Check(blocked,"This process actually enforces legacy MAX_PATH; no Windows policy change");
  for(int i=0;i<years.Length;i++){
   string year=years[i],payload=Distribution.Extract(a,Path.Combine(root,"extract"),hashes[i],null,resources[i]);
   var engine=new InstallEngine(payload,inventories[i]);Check(engine.Year==year,"Mapped package inventory selects "+year);
   string inventoryPath=Path.Combine(payload,"InstallInventory.txt"),inventory=File.ReadAllText(inventoryPath);string[] rows=inventory.TrimEnd('\r','\n').Split('\n');
   foreach(string bad in new[]{"p/../escape.png","p/0000.png:stream","p/0000.png\\escape"}) {
    string[] altered=(string[])rows.Clone();string[] columns=altered[1].TrimEnd('\r').Split('\t');columns[3]=bad;altered[1]=String.Join("\t",columns);
    File.WriteAllText(inventoryPath,String.Join("\n",altered)+"\n",new UTF8Encoding(false));blocked=false;
    try{new InstallEngine(payload,Hash(inventoryPath));}catch(IOException){blocked=true;}
    Check(blocked,"Mapped archive source rejects traversal/alternate path "+bad+" / "+year);
   }
   File.WriteAllText(inventoryPath,inventory,new UTF8Encoding(false));
   Check(Hash(inventoryPath)==inventories[i],"Admission probes restore the exact inventory "+year);
   var normal=InstallPaths.ForMax(Path.Combine(root,"s"),Path.Combine(root,"a"),Path.Combine(root,"m"),Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),@"Autodesk\3dsMax\"+year+@" - 64bit\ENU"),year);
   Check(normal.RuntimeRoot==Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"CyrusScatter",year),"Standard Windows profile selects the short per-user runtime "+year);
   var paths=Paths(root,year);Profile(paths);string ini=Path.Combine(paths.Profile,"Plugin.UserSettings.ini");
   string personal=Path.Combine(paths.Profile,"personal-recipe.json"),license=Path.Combine(paths.Profile,"sentinel.cyruslicense");File.WriteAllText(personal,"Keep recipe");File.WriteAllText(license,"Keep activation sentinel");
   string release=engine.Install(paths);
   Check(release.StartsWith(Path.Combine(paths.RuntimeRoot,"r")),"Compact runtime is independent of the deep Max scripts folder "+year);
   Check(File.Exists(Path.Combine(release,"bin","AminScatter.dlx")),"Native files install under legacy path handling "+year);
   Check(File.Exists(Path.Combine(release,"Library-0.86.2","inventory.json")),"Complete logical library is reconstructed "+year);
   int maximum=0;foreach(string p in Directory.GetFiles(release,"*",SearchOption.AllDirectories))maximum=Math.Max(maximum,p.Length);
   Check(maximum<260,"Every installed asset path fits legacy MAX_PATH "+year+" (maximum "+maximum+")");
   Check(Directory.GetFiles(Path.Combine(release,"Patterns"),"*.png").Length==3,"Three starter masks are installed "+year);
   Check(File.ReadAllText(ini).Contains("CyrusScatter"+year+"=")&&File.ReadAllText(ini).Contains("OtherPlugin=F:\\Keep"),"Host-specific registration preserves other plugins "+year);
   string previous=Hash(ini);Check(engine.Install(paths)==release&&Hash(ini)==previous,"Identical repair preserves registration "+year);
   var tooLong=new InstallPaths(paths.Scripts,paths.Startup,paths.Macros,paths.Profile,Path.Combine(root,new string('q',110)));blocked=false;
   try{engine.Install(tooLong);}catch(IOException error){blocked=error.Message.Contains("too long");}
   Check(blocked&&Hash(ini)==previous,"Overlong custom destination is rejected before registration "+year);
   string missing=Path.Combine(release,"bin","CyrusBrush.dlx");File.Delete(missing);engine.Install(paths);Check(File.Exists(missing),"Missing-file repair works "+year);
   File.WriteAllText(missing,"Keep modified bytes");blocked=false;try{engine.Install(paths);}catch(IOException){blocked=true;}
   Check(blocked&&File.ReadAllText(missing)=="Keep modified bytes","Modified owned files are retained and rejected "+year);
   File.Copy(Path.Combine(payload,"CyrusBrush.dlx"),missing,true);
   foreach(string phase in new[]{"copied:CyrusGallery.dll","journal","publishing:1","publishing:2","publishing:3"}){
    var failure=Paths(root,year+"-"+phase.Replace(':','-'));Profile(failure);string original=Hash(Path.Combine(failure.Profile,"Plugin.UserSettings.ini"));
    blocked=false;try{engine.Install(failure,p=>{if(p==phase)throw new OperationCanceledException("Owned cancellation");});}catch(OperationCanceledException){blocked=true;}
    Check(blocked&&Hash(Path.Combine(failure.Profile,"Plugin.UserSettings.ini"))==original&&!File.Exists(Path.Combine(failure.Startup,"CyrusScatterStartup.ms")),"Cancellation/rollback retains preceding files at "+phase+" / "+year);
    engine.Install(failure);Check(File.ReadAllText(Path.Combine(failure.Profile,"Plugin.UserSettings.ini")).Contains("CyrusScatter"+year+"="),"Retry succeeds after "+phase+" / "+year);
   }
   string u=Path.Combine(root,"u"+year);var upgrade=new InstallPaths(Path.Combine(u,"s"),Path.Combine(u,"a"),Path.Combine(u,"m"),Path.Combine(u,"p"),Path.Combine(u,"r"));Profile(upgrade);
   string old=Path.Combine(root,"old"+year);var oldEngine=new InstallEngine(old,Hash(Path.Combine(old,"InstallInventory.txt")));
   var oldPaths=new InstallPaths(upgrade.Scripts,upgrade.Startup,upgrade.Macros,upgrade.Profile);string oldRelease=oldEngine.Install(oldPaths);string oldIni=Hash(Path.Combine(upgrade.Profile,"Plugin.UserSettings.ini"));
   blocked=false;try{engine.Install(upgrade,p=>{if(p=="publishing:2")throw new OperationCanceledException("Owned interrupted upgrade");});}catch(OperationCanceledException){blocked=true;}
   Check(blocked&&Hash(Path.Combine(upgrade.Profile,"Plugin.UserSettings.ini"))==oldIni,"Interrupted legacy-to-compact upgrade retains old registration "+year);
   string next=engine.Install(upgrade);Check(Directory.Exists(oldRelease)&&next!=oldRelease&&File.ReadAllText(Path.Combine(upgrade.Profile,"Plugin.UserSettings.ini")).Contains(next),"Same-version upgrade publishes compact runtime and retains old recovery files "+year);
   InstallEngine.RemoveRegistration(upgrade,year);
   InstallEngine.RemoveRegistration(paths,year);Check(!File.ReadAllText(ini).Contains("CyrusScatter"+year+"=")&&File.ReadAllText(ini).Contains("OtherPlugin="),"Unregister removes only the selected host "+year);
   Check(File.ReadAllText(personal)=="Keep recipe"&&File.ReadAllText(license)=="Keep activation sentinel"&&Directory.Exists(release),"Personal recipes, activation and recovery files survive "+year);
   string log=InstallEngine.SaveFailure(paths,"Owned full failure detail\r\n"+new string('x',700));Check(File.ReadAllText(log).Length>700,"Complete error details persist to an owned log "+year);
   Distribution.Cleanup(Path.Combine(root,"extract"),payload);
  }
  Console.WriteLine("PASSED "+checks+" exact-EXE recipient checks under legacy path limits");return 0;
 }catch(Exception e){Console.WriteLine(e);return 1;}}
}
