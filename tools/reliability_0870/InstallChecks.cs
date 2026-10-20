using System; using System.IO; using Cyrus.Setup;
class InstallChecks {
 static void Check(bool ok,string msg){if(!ok)throw new Exception(msg);Console.WriteLine("PASS: "+msg);}
 static int Main(string[] args){try{
  string root=Path.GetFullPath(args[1]);if(!root.StartsWith(@"D:\CyrusScatterBuilds\i0870-",StringComparison.OrdinalIgnoreCase)||Directory.Exists(root))throw new Exception("Fresh owned install root required");
  Directory.CreateDirectory(root);string payload=Path.GetFullPath(args[0]);var engine=new InstallEngine(payload,InstallEngine.Hash(File.ReadAllBytes(Path.Combine(payload,"InstallInventory.txt"))));
  Check(engine.Year=="2027","Exact package targets Max 2027");
  var p=new InstallPaths(Path.Combine(root,"scripts"),Path.Combine(root,"startup"),Path.Combine(root,"macros"),Path.Combine(root,"profile"),Path.Combine(root,"runtime"));
  Directory.CreateDirectory(p.Profile);string ini=Path.Combine(p.Profile,"Plugin.UserSettings.ini");File.WriteAllText(ini,"[Directories]\r\nOtherPlugin=F:\\Keep\r\n");
  string sentinel=Path.Combine(p.Profile,"my-recipe.json");File.WriteAllText(sentinel,"keep");string release=engine.Install(p);
  Check(File.Exists(Path.Combine(release,"bin","AminScatter.dlx"))&&File.Exists(Path.Combine(release,"CyrusScatter.ms")),"Matched native and script payload install");
  Check(File.Exists(Path.Combine(release,"Library-0.87.0","inventory.json")),"Updated complete library installs");
  Check(Directory.GetFiles(Path.Combine(release,"Patterns"),"*.png").Length==3,"Three starter patterns install");
  Check(File.ReadAllText(ini).Contains("OtherPlugin=F:\\Keep")&&File.ReadAllText(ini).Contains("CyrusScatter2027="),"Registration preserves other plugins");
  Check(engine.Install(p)==release,"Identical repair is idempotent");
  string missing=Path.Combine(release,"bin","CyrusBrush.dlx");File.Delete(missing);engine.Install(p);Check(File.Exists(missing),"Missing payload repairs");
  var bad=new InstallPaths(Path.Combine(root,"failure/scripts"),Path.Combine(root,"failure/startup"),Path.Combine(root,"failure/macros"),Path.Combine(root,"failure/profile"),Path.Combine(root,"failure/runtime"));
  bool failed=false;try{engine.Install(bad,x=>{if(x=="publishing:2")throw new OperationCanceledException("Owned failure");});}catch(OperationCanceledException){failed=true;}
  Check(failed&&!File.Exists(Path.Combine(bad.Startup,"CyrusScatterStartup.ms")),"Interrupted installation rolls back registration");engine.Install(bad);
  Check(File.Exists(Path.Combine(bad.Startup,"CyrusScatterStartup.ms")),"Retry after interrupted installation succeeds");
  InstallEngine.RemoveRegistration(p,"2027");Check(!File.ReadAllText(ini).Contains("CyrusScatter2027=")&&File.ReadAllText(ini).Contains("OtherPlugin="),"Unregister preserves other plugins");
  Check(File.ReadAllText(sentinel)=="keep"&&Directory.Exists(release),"Personal data and recovery payload remain");
  Console.WriteLine("PASS: complete");return 0;
 }catch(Exception e){Console.WriteLine(e);return 1;}}
}
