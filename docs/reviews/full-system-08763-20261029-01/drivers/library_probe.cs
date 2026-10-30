using System;using System.IO;using System.Linq;using System.Threading;using System.Diagnostics;using System.Collections.Generic;using System.IO.Compression;using Cyrus.Content;
class LibraryProbe {
 static string Wait(LibraryOperation x){var end=DateTime.UtcNow.AddSeconds(40);while(!x.Terminal&&DateTime.UtcNow<end)Thread.Sleep(5);if(!x.Terminal||x.State!="complete")throw new Exception(x.State+" "+x.Error);return x.Result;}
 static void Check(bool b,string m){if(!b)throw new Exception(m);}
 static SharedLibrary Store(string p){return new SharedLibrary(p,_=>{});}
 static void BadArchive(SharedLibrary store,string root,string name,Action<ZipArchive> make){
  var path=Path.Combine(root,name+".zip");using(var f=File.Create(path))using(var z=new ZipArchive(f,ZipArchiveMode.Create))make(z);
  var head=File.ReadAllBytes(Path.Combine(store.Root,"catalog/current.json"));var op=store.Import(path);var end=DateTime.UtcNow.AddSeconds(30);while(!op.Terminal&&DateTime.UtcNow<end)Thread.Sleep(5);
  Check(op.Terminal&&op.State=="failed","Unsafe archive accepted: "+name);Check(head.SequenceEqual(File.ReadAllBytes(Path.Combine(store.Root,"catalog/current.json"))),"Archive failure changed catalog");Console.WriteLine("REJECT "+name+" "+op.Error);
 }
 static void Entry(ZipArchive z,string path){using(var w=new StreamWriter(z.CreateEntry(path).Open()))w.Write("x");}
 static int Main(string[] args){try{
  if(args[0]=="child"){var s=Store(args[1]);var file=Wait(s.PrepareScene(args[2],ContentObjects.Hash(args[2])));File.WriteAllText(args[3],file);return 0;}
  var root=Path.GetFullPath(args[0]);Check(!Directory.Exists(root),"Fresh owned directory required");Directory.CreateDirectory(root);var store=Store(Path.Combine(root,"store"));
  var save=store.BeginSceneSave("","");File.WriteAllBytes(Path.Combine(save.Directory,"scene.max"),new byte[524288]);
  var entry=Wait(store.PublishScene(save,"Review scene","{}","[]",.01,1,"[]",""));
  var metadata=LibraryJson.Obj(LibraryJson.Parse(File.ReadAllText(entry)));Console.WriteLine("SCENE writer_version="+metadata["scatterVersion"]);
  var signal=Path.Combine(root,"stage.txt");var psi=new ProcessStartInfo(typeof(LibraryProbe).Assembly.Location,"child \""+store.Root+"\" \""+entry+"\" \""+signal+"\""){UseShellExecute=false,CreateNoWindow=true};
  using(var p=Process.Start(psi)){Check(p.WaitForExit(45000),"Child timeout");Check(p.ExitCode==0,"Child failure");}
  var staged=File.ReadAllText(signal);var marker=Path.Combine(Path.GetDirectoryName(staged),".cyrus-operation.json");Console.WriteLine("SCENE dead_owner_stage_marker="+File.Exists(marker));
  Console.WriteLine("RECOVER "+Wait(store.RecoverStaging()));Console.WriteLine("SCENE stage_retained_after_owner_exit="+File.Exists(staged)+" bytes="+new FileInfo(staged).Length);
  Check(File.Exists(entry),"Recovery damaged published recipe");store.DiscardSceneLoad(staged);Check(!File.Exists(staged),"Explicit discard failed");
  var sha=new string('a',64);
  BadArchive(store,root,"traversal",z=>Entry(z,"../outside.txt"));
  BadArchive(store,root,"absolute",z=>Entry(z,"C:/outside.txt"));
  BadArchive(store,root,"duplicate",z=>{Entry(z,"library.json");Entry(z,"library.json");});
  BadArchive(store,root,"symlink",z=>{var e=z.CreateEntry("objects/"+sha);e.ExternalAttributes=unchecked((int)0xA0000000);using(var w=new StreamWriter(e.Open()))w.Write("outside");});
  BadArchive(store,root,"file-count",z=>{for(int i=0;i<4098;++i)Entry(z,"x"+i);});
  bool rejected=false;try{Store(Path.Combine(root,new string('x',81)));}catch(IOException){rejected=true;}Check(rejected,"Unsupported long root silently accepted");
  var unicode=Store(Path.Combine(root,"فارسی"));Check(Directory.Exists(unicode.Root),"Unicode root failed");
  Console.WriteLine("PASS supplemental managed safety checks; scene recovery/version observations reproduced; native validator intentionally injected");return 0;
 }catch(Exception e){Console.Error.WriteLine(e);return 1;}}
}
