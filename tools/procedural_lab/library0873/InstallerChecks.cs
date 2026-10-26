using System;
using System.IO;
using System.Reflection;
using System.Text;
using Cyrus.Setup;
static class InstallerChecks {
 static int checks;
 static void Check(bool value,string message){if(!value)throw new Exception(message);checks++;Console.WriteLine("PASS "+message);}
 static string Hash(string path){return InstallEngine.Hash(File.ReadAllBytes(path));}
 static string[] Values(Assembly a,string name){return (string[])a.GetType("Cyrus.Setup.BuildIdentity").GetField(name).GetValue(null);}
 static InstallPaths Paths(string root,string key){var p=Path.Combine(root,key);return new InstallPaths(Path.Combine(p,"scripts"),Path.Combine(p,"startup"),Path.Combine(p,"macros"),Path.Combine(p,"profile"),Path.Combine(p,"runtime"));}
 static void Profile(InstallPaths paths){Directory.CreateDirectory(paths.Profile);File.WriteAllText(Path.Combine(paths.Profile,"Plugin.UserSettings.ini"),"[Directories]\r\nOtherPlugin=F:\\Keep\r\n",Encoding.Unicode);}
 static int Main(string[] args){try{
  string root=Path.GetFullPath(args[1]);if(!root.StartsWith(Path.GetFullPath(args[2])+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase))throw new Exception("Owned build destination required");Directory.CreateDirectory(root);
  var assembly=Assembly.LoadFrom(args[0]);var years=Values(assembly,"Years");var hashes=Values(assembly,"PackageHashes");var inventories=Values(assembly,"InventoryHashes");var resources=Values(assembly,"Resources");
  Check(String.Join(",",years)=="2024,2026,2027","EXE embeds exactly the requested host mapping");
  for(int i=0;i<years.Length;i++){
   string year=years[i],payload=Distribution.Extract(assembly,Path.Combine(root,"extract"),hashes[i],null,resources[i]);var engine=new InstallEngine(payload,inventories[i]);
   Check(engine.Year==year&&engine.Version=="0.87.3","embedded inventory version and host "+year);Check(engine.LibraryAction=="Keep","plugin update defaults to retaining content "+year);
   var paths=Paths(root,year);Profile(paths);string ini=Path.Combine(paths.Profile,"Plugin.UserSettings.ini");string personal=Path.Combine(paths.Profile,"my-recipe.json"),license=Path.Combine(paths.Profile,"activation.cyruslicense");File.WriteAllText(personal,"Keep recipe");File.WriteAllText(license,"Keep activation");
   var release=engine.Install(paths);Check(File.Exists(Path.Combine(release,"bin","AminScatter.dlx")),"native installed "+year);Check(File.Exists(Path.Combine(paths.Startup,"CyrusScatterStartup.ms")),"paired startup registered "+year);
   Check(File.ReadAllText(ini).Contains("CyrusScatter"+year+"=")&&File.ReadAllText(ini).Contains("OtherPlugin=F:\\Keep"),"registration preserves other plugins "+year);
   string registered=Hash(ini);Check(engine.Install(paths)==release&&Hash(ini)==registered,"repeat install is idempotent "+year);
   var missing=Path.Combine(release,"bin","CyrusBrush.dlx");File.Delete(missing);engine.Install(paths);Check(File.Exists(missing),"missing binary repair "+year);
   File.WriteAllText(missing,"Owned modified bytes");bool rejected=false;try{engine.Install(paths);}catch(IOException){rejected=true;}Check(rejected&&File.ReadAllText(missing)=="Owned modified bytes","modified file is retained and rejected "+year);File.Copy(Path.Combine(payload,"CyrusBrush.dlx"),missing,true);
   foreach(string phase in new[]{"copied:CyrusGallery.dll","journal","publishing:1","publishing:2","publishing:3"}){
    var cancelled=Paths(root,year+"-"+phase.Replace(':','-'));Profile(cancelled);var prior=Hash(Path.Combine(cancelled.Profile,"Plugin.UserSettings.ini"));rejected=false;
    try{engine.Install(cancelled,p=>{if(p==phase)throw new OperationCanceledException("Owned cancellation");});}catch(OperationCanceledException){rejected=true;}
    Check(rejected&&Hash(Path.Combine(cancelled.Profile,"Plugin.UserSettings.ini"))==prior&&!File.Exists(Path.Combine(cancelled.Startup,"CyrusScatterStartup.ms")),"rollback "+phase+" / "+year);
    engine.Install(cancelled);Check(File.Exists(Path.Combine(cancelled.Startup,"CyrusScatterStartup.ms")),"retry "+phase+" / "+year);
   }
   Check(File.ReadAllText(personal)=="Keep recipe"&&File.ReadAllText(license)=="Keep activation","personal files preserved "+year);
   Console.WriteLine("INSTALLED\t"+year+"\t"+release+"\t"+paths.Startup+"\t"+paths.Macros+"\t"+paths.Profile);
   Distribution.Cleanup(Path.Combine(root,"extract"),payload);
  }
  Console.WriteLine("PASSED "+checks+" exact-EXE owned-profile checks");return 0;
 }catch(Exception error){Console.WriteLine(error);return 1;}}
}
