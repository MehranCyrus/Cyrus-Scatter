// Managed file-transaction tests. Native SDK/renderer acceptance is a separate host campaign.
using System;
using System.IO;
using System.Text;
using System.Linq;
using System.Collections.Generic;
using System.Threading;
using System.Security.Cryptography;
using System.Runtime.InteropServices;
using System.Diagnostics;
using System.Reflection;
using Cyrus.Content;

internal static class StoreTests {
    static int checks;
    static void Check(bool value,string message){checks++;if(!value)throw new Exception(message);}
    static void Reject(Action action,string message){bool failed=false;try{action();}catch{failed=true;}Check(failed,message);}
    static Dictionary<string,object> M(params object[] x){return LibraryJson.Map(x);}
    static List<object> L(params object[] x){return x.ToList();}
    static Dictionary<string,object> D(object x){return LibraryJson.Obj(x);}
    static string S(object x){return LibraryJson.Str(x);}
    static byte[] Bytes(string s){return new UTF8Encoding(false,true).GetBytes(s);}
    static string Hash(byte[] b){using(var h=SHA256.Create())return BitConverter.ToString(h.ComputeHash(b)).Replace("-","").ToLowerInvariant();}
    static string Write(string path,byte[] bytes){Directory.CreateDirectory(Path.GetDirectoryName(path));File.WriteAllBytes(path,bytes);return Hash(bytes);}
    static string Wait(LibraryOperation op,bool success=true){var end=DateTime.UtcNow.AddSeconds(60);while(!op.Terminal&&DateTime.UtcNow<end)Thread.Sleep(5);Check(op.Terminal,"operation timeout");Check((op.State=="complete")==success,"operation result: "+op.State+" "+op.Error);return op.Result;}
    static void ValidateFixture(string directory){
        Check(File.Exists(Path.Combine(directory,"cyrus.package.json")),"validation called on complete private package");
        var graph=D(LibraryJson.Parse(File.ReadAllText(Path.Combine(directory,"assets.json"))));
        foreach(var raw in LibraryJson.Arr(graph["files"])){var f=D(raw);var sha=S(f["sha256"]);ContentObjects.Verify(Path.Combine(directory,"assets",sha+"."+S(f["suffix"])),sha,LibraryJson.Int(f["bytes"]));}
    }
    static LibrarySave Fixture(SharedLibrary store,string id,int look=1,string expected="",string original="",bool broken=false){
        var save=store.BeginSave(original,expected,id+".csrecipe.json");
        var recipe=M("format","cyrus.planting-recipe","formatVersion",8L,"id",id,"name","Look "+look,"revision",(long)look,
            "presentation",null,"roles",L(),"layers",L(M("id","layer","paint",null,"areas",L())),"setting",look);
        var files=L();var nodes=L();var meshes=L();var maps=L();var materials=L();var roles=LibraryJson.Arr(recipe["roles"]);
        var package=Path.Combine(save.Directory,"ready");Directory.CreateDirectory(package);
        for(int i=0;i<3;i++){
            var role="source"+i;roles.Add(M("id",role,"kind","node","purposes",L("procSourceNodes")));
            var geometry=Bytes("fixture-native-mesh-"+i+new string('M',32000));var geometryHash=Hash(geometry);
            files.Add(M("id","meshfile"+i,"kind","mesh","sha256",geometryHash,"bytes",(long)geometry.Length,"suffix","cmesh"));
            Write(Path.Combine(package,"assets",geometryHash+".cmesh"),geometry);
            meshes.Add(M("id","mesh"+i,"file","meshfile"+i));nodes.Add(M("id","node"+i,"name","Plant "+i,"mesh","mesh"+i,"material","material"+i,"roles",L(role)));
            var references=L();for(int j=0;j<2;j++){var n=i*2+j;var image=Bytes("fixture-image-"+n+new string('I',4000));var imageHash=Hash(image);
                Write(Path.Combine(package,"assets",imageHash+".png"),image);
                files.Add(M("id","image"+n,"kind","bitmap","sha256",imageHash,"bytes",(long)image.Length,"suffix","png"));
                maps.Add(M("id","map"+n,"kind","bitmap","file","image"+n,"gamma",2.2));references.Add("map"+n);
            }materials.Add(M("id","material"+i,"kind","standard-blinn","maps",references));
        }
        var text=LibraryJson.Write(recipe);var sha=Write(save.RecipePath,Bytes(text));Write(Path.Combine(package,"entry.csrecipe.json"),Bytes(text));
        var graph=Bytes(LibraryJson.Write(M("format","cyrus.library-assets","version",4L,"nodes",nodes,"meshes",meshes,"files",files,"maps",maps,"materials",materials,"splines",L(),"externalRoles",L())));
        var graphHash=Write(Path.Combine(package,"assets.json"),graph);
        var manifest=M("format","cyrus.library-package","version",1L,"recipe",M("file","entry.csrecipe.json","sha256",sha,"bytes",(long)Bytes(text).Length),
            "graph",M("file","assets.json","sha256",graphHash,"bytes",(long)graph.Length),"hostYear",2027L,"redistribution","Owned fixture");
        Write(Path.Combine(package,"cyrus.package.json"),Bytes(LibraryJson.Write(manifest)));
        if(broken)File.Delete(Directory.GetFiles(Path.Combine(package,"assets"),"*.cmesh")[0]);return save;
    }
    static string Save(SharedLibrary store,string id,int look=1){var ticket=Fixture(store,id,look);return Wait(store.Publish(ticket,Path.Combine(ticket.Directory,"ready")));}
    [StructLayout(LayoutKind.Sequential)]struct Information{public uint attributes;public System.Runtime.InteropServices.ComTypes.FILETIME creation,access,write;public uint volume,sizeHigh,sizeLow,links,indexHigh,indexLow;}
    [DllImport("kernel32.dll",SetLastError=true)]static extern bool GetFileInformationByHandle(IntPtr handle,out Information info);
    static string FileId(string path){using(var f=new FileStream(path,FileMode.Open,FileAccess.Read,FileShare.ReadWrite|FileShare.Delete)){Information info;if(!GetFileInformationByHandle(f.SafeFileHandle.DangerousGetHandle(),out info))throw new Exception("file identity unavailable");return info.volume+":"+info.indexHigh+":"+info.indexLow;}}
    static int CrashChild(string mode,string root,string signal){
        var store=new SharedLibrary(root,ValidateFixture);
        if(mode=="crash-scene-load"){
            var entry=store.RecipePaths().Single(path=>File.ReadAllText(path).Contains("cyrus.scene-preset"));
            var staged=Wait(store.PrepareScene(entry,ContentObjects.Hash(entry)));File.WriteAllText(signal,staged);Thread.Sleep(Timeout.Infinite);
        }else if(mode=="crash-promote"){
            int before=Directory.GetFiles(Path.Combine(root,"objects")).Length;var save=Fixture(store,"interrupted-save");
            Action check=()=>{if(Directory.GetFiles(Path.Combine(root,"objects")).Length>before){File.WriteAllText(signal,"promoted-before-catalog");Thread.Sleep(Timeout.Infinite);}};
            typeof(SharedLibrary).GetMethod("PublishNow",BindingFlags.NonPublic|BindingFlags.Instance).Invoke(store,new object[]{save,Path.Combine(save.Directory,"ready"),check,false});
        }else{
            var pointer=D(LibraryJson.Parse(File.ReadAllText(Path.Combine(root,"catalog/current.json"))));var sha=S(pointer["sha256"]);
            var c=D(LibraryJson.Parse(File.ReadAllText(Path.Combine(root,"catalog/snapshots",sha+".json"))));
            D(c["collections"])["interrupted-collection"]=M("name","Committed interrupted generation","recipes",L(),"models",L());
            using(var locked=new FileStream(Path.Combine(root,"content.lock"),FileMode.OpenOrCreate,FileAccess.ReadWrite,FileShare.None)){
                Action check=()=>{if(File.Exists(Path.Combine(root,"receipts/operation-crash-commit.json"))){File.WriteAllText(signal,"before-head");while(!File.Exists(signal+".release"))Thread.Sleep(5);}};
                typeof(SharedLibrary).GetMethod("PublishCatalog",BindingFlags.NonPublic|BindingFlags.Instance).Invoke(store,new object[]{c,check,"crash-commit"});
                File.WriteAllText(signal+".committed","head-published-completion-receipt-absent");Thread.Sleep(Timeout.Infinite);
            }
        }return 0;
    }
    static void CrashCheck(string mode,string storeRoot,string signal){
        var info=new ProcessStartInfo(typeof(StoreTests).Assembly.Location,mode+" \""+storeRoot+"\" \""+signal+"\""){UseShellExecute=false,CreateNoWindow=true,RedirectStandardOutput=true,RedirectStandardError=true};
        using(var child=Process.Start(info)){
            var end=DateTime.UtcNow.AddSeconds(30);while(!File.Exists(signal)&&!child.HasExited&&DateTime.UtcNow<end)Thread.Sleep(5);
            if(!File.Exists(signal)){if(!child.HasExited)child.Kill();child.WaitForExit();throw new Exception("Child did not reach its transaction boundary: "+child.StandardError.ReadToEnd());}
            if(mode=="crash-commit"){
                File.WriteAllText(signal+".release","continue");while(!File.Exists(signal+".committed")&&!child.HasExited&&DateTime.UtcNow<end)Thread.Sleep(5);Check(File.Exists(signal+".committed"),"child failed to publish its atomic head");
            }
            child.Kill();Check(child.WaitForExit(10000),"owned interruption child did not exit");
        }
    }
    public static int Main(string[] args){try{
        if(args.Length==3&&args[0].StartsWith("crash-",StringComparison.Ordinal))return CrashChild(args[0],args[1],args[2]);
        var root=Path.GetFullPath(args[0]);if(Directory.Exists(root))throw new Exception("Fresh owned test directory required");Directory.CreateDirectory(root);
        Reject(()=>LibraryJson.Parse("{\"a\":1,\"a\":2}"),"duplicate JSON key accepted");Reject(()=>LibraryJson.Parse("[1e9999]"),"nonfinite JSON accepted");
        Check(LibraryJson.Write(LibraryJson.Parse("{\"z\":1,\"a\":2}"))=="{\"a\":2,\"z\":1}","canonical field order");
        var store=new SharedLibrary(Path.Combine(root,"author"),ValidateFixture);var paths=new List<string>();
        for(int i=0;i<10;i++)paths.Add(Save(store,"look"+i,i));
        Check(paths.All(File.Exists),"ten complete recipe views missing");
        Check(store.Models().Length==3,"unchanged models duplicated or missing");
        var objects=Path.Combine(store.Root,"objects");var meshes=new HashSet<string>();var images=new HashSet<string>();
        foreach(var package in Directory.GetDirectories(Path.Combine(store.Root,"packs/user"))){foreach(var mesh in Directory.GetFiles(Path.Combine(package,"assets"),"*.cmesh"))meshes.Add(FileId(mesh));foreach(var image in Directory.GetFiles(Path.Combine(package,"assets"),"*.png"))images.Add(FileId(image));}
        Check(meshes.Count==3,"ten recipes allocated duplicate meshes");Check(images.Count==6,"ten recipes allocated duplicate images");
        foreach(var image in Directory.GetFiles(store.BitmapDirectory)){var hash=Path.GetFileNameWithoutExtension(image);Check(FileId(image)==FileId(Path.Combine(objects,hash)),"texture view duplicates its object");}
        var modelRevisions=store.Models().Select(x=>x.Revision).OrderBy(x=>x).ToArray();
        store.AddToCollection("Ten looks",Enumerable.Range(0,10).Select(i=>"look"+i).ToArray(),new string[0]);
        store.AddToCollection("Favorites",new[]{"look0","look1"},new[]{store.Models()[0].Id});
        Check(store.Collections().Length==2,"multiple collection membership missing");Check(modelRevisions.SequenceEqual(store.Models().Select(x=>x.Revision).OrderBy(x=>x)),"membership changed model revisions");
        var chosen=store.Models()[0];store.AddToCollection("One source only",new string[0],new[]{chosen.Id});var modelArchive=Path.Combine(root,"one-model.cyruslib");Wait(store.Export("One source only",modelArchive));
        using(var stream=File.OpenRead(modelArchive))using(var zip=new System.IO.Compression.ZipArchive(stream,System.IO.Compression.ZipArchiveMode.Read))using(var reader=new StreamReader(zip.GetEntry("library.json").Open())){
            var selection=D(LibraryJson.Parse(reader.ReadToEnd()));Check(D(selection["packages"]).Count==0&&D(selection["modelPackages"]).Count==1,"selected model leaks an original recipe or unrelated model packages");
            var info=D(D(selection["modelPackages"]).Values.Single());var names=D(info["files"]).Keys.ToArray();Check(names.Count(x=>x.EndsWith(".cmesh",StringComparison.Ordinal))==1&&names.Count(x=>x.EndsWith(".png",StringComparison.Ordinal))==2,"selected model includes unrelated meshes or images");
        }
        var modelRecipient=new SharedLibrary(Path.Combine(root,"one-model"),ValidateFixture);Wait(modelRecipient.Import(modelArchive));Check(modelRecipient.RecipePaths().Length==0&&modelRecipient.Models().Length==1,"model-only archive import adds unrelated recipe cards");
        var rootDefinition=D(LibraryJson.Parse(File.ReadAllText(Path.Combine(chosen.Package,"model.json"))));Check(File.Exists(Path.Combine(store.Root,"objects",S(rootDefinition["material"]))),"model does not reuse a separately stored material definition");
        var oldGeneration=File.ReadAllText(Path.Combine(store.Root,"catalog/current.json"));var failed=Fixture(store,"broken",1,broken:true);Wait(store.Publish(failed,Path.Combine(failed.Directory,"ready")),false);Check(File.ReadAllText(Path.Combine(store.Root,"catalog/current.json"))==oldGeneration,"failed ready save changed visible catalog");
        var one=Fixture(store,"concurrent",1);var two=Fixture(store,"concurrent",2);var a=store.Publish(one,Path.Combine(one.Directory,"ready"));var b=store.Publish(two,Path.Combine(two.Directory,"ready"));
        var end=DateTime.UtcNow.AddSeconds(60);while((!a.Terminal||!b.Terminal)&&DateTime.UtcNow<end)Thread.Sleep(5);Check(a.Terminal&&b.Terminal,"concurrent writers deadlocked");Check(new[]{a,b}.Count(x=>x.State=="complete")==1,"concurrent entry update was lost");
        var archive=Path.Combine(root,"ten.cyruslib");Wait(store.Export("Ten looks",archive));Check(File.Exists(archive),"archive not published");
        var recipient=new SharedLibrary(Path.Combine(root,"recipient"),ValidateFixture);Wait(recipient.Import(archive));
        Check(recipient.RecipePaths().Length==10,"clean recipient lacks ten looks");Check(recipient.Models().Length==3,"clean recipient models differ");
        var before=Directory.GetFiles(Path.Combine(recipient.Root,"objects")).Select(Path.GetFileName).OrderBy(x=>x).ToArray();Wait(recipient.Import(archive));
        Check(before.SequenceEqual(Directory.GetFiles(Path.Combine(recipient.Root,"objects")).Select(Path.GetFileName).OrderBy(x=>x)),"repeat import adds objects");
        var preserved=File.ReadAllText(Path.Combine(recipient.Root,"catalog/current.json"));var corrupt=Path.Combine(root,"corrupt.cyruslib");File.WriteAllText(corrupt,"not a zip");Wait(recipient.Import(corrupt),false);Check(File.ReadAllText(Path.Combine(recipient.Root,"catalog/current.json"))==preserved,"corrupt import changed catalog");
        var used=recipient.Models()[0];var dependency=Directory.GetFiles(Path.Combine(used.Package,"assets"),"*.png")[0];var dependencyHash=Path.GetFileNameWithoutExtension(dependency);recipient.RemoveRecipe("look0");recipient.RemoveCollection("Ten looks");
        Check(File.Exists(dependency)&&File.Exists(Path.Combine(recipient.Root,"objects",dependencyHash)),"deletion removed retained scene data");
        // Corrupting a hard-link view also damages its shared inode. Ordinary
        // reuse must refuse it; explicit repair replaces it with verified bytes.
        File.WriteAllText(dependency,"corrupt shared image");var repairHead=File.ReadAllText(Path.Combine(recipient.Root,"catalog/current.json"));
        Wait(recipient.Import(archive),false);Check(File.ReadAllText(Path.Combine(recipient.Root,"catalog/current.json"))==repairHead,"corrupt reuse changed the catalog");
        Wait(recipient.RepairFromArchive(archive));Check(FileId(dependency)==FileId(Path.Combine(recipient.Root,"objects",dependencyHash)),"repaired view does not share its canonical allocation");
        File.Delete(dependency);Wait(recipient.RepairFromArchive(archive));Check(File.Exists(dependency),"missing stable package view was not repaired");
        var modelOnly=Fixture(store,"model-only");var recipeCount=store.RecipePaths().Length;Wait(store.PublishModels(modelOnly,Path.Combine(modelOnly.Directory,"ready")));Check(store.RecipePaths().Length==recipeCount,"model-only save created a recipe card");
        store.AddToCollection("Single later look",new[]{"look9"},new string[0]);var singleArchive=Path.Combine(root,"single.cyruslib");Wait(store.Export("Single later look",singleArchive));
        var single=new SharedLibrary(Path.Combine(root,"single"),ValidateFixture);Wait(single.Import(singleArchive));Check(single.Models().Length==3,"a later look lost models whose original cards use another package");Wait(recipient.Import(singleArchive));
        var changed=Fixture(store,"look1",123,ContentObjects.Hash(paths[1]),paths[1]);Wait(store.Publish(changed,Path.Combine(changed.Directory,"ready")));
        store.AddToCollection("Changed look",new[]{"look1"},new string[0]);var changedArchive=Path.Combine(root,"changed.cyruslib");Wait(store.Export("Changed look",changedArchive));
        Wait(recipient.Import(changedArchive),false);var countBeforeCopy=recipient.RecipePaths().Length;Wait(recipient.Import(changedArchive,true));Check(recipient.RecipePaths().Length==countBeforeCopy+1,"conflicting recipe was not copied");
        Wait(recipient.Import(changedArchive,true));Check(recipient.RecipePaths().Length==countBeforeCopy+1,"repeat conflicting-copy import duplicated a card");
        File.Delete(archive);Check(recipient.RecipePaths().Any(p=>recipient.RecipeId(p)=="look1"&&File.Exists(p)),"recipient depends on transport archive");
        var immutableBefore=recipient.RecipePaths().Select(ContentObjects.Hash).OrderBy(x=>x).ToArray();
        Wait(recipient.RenameModel(used.Id,"Renamed tree"));Check(recipient.Models().Single(x=>x.Id==used.Id).Name=="Renamed tree","model rename was lost");
        Check(immutableBefore.SequenceEqual(recipient.RecipePaths().Select(ContentObjects.Hash).OrderBy(x=>x)),"model metadata changed saved recipes");
        Wait(recipient.UpdateModelRevision(used.Id,recipient.Models().First(x=>x.Id!=used.Id).Id));
        Check(immutableBefore.SequenceEqual(recipient.RecipePaths().Select(ContentObjects.Hash).OrderBy(x=>x)),"model revision replaced pinned recipes");
        recipient.AddToCollection("Recipient favorites",new[]{"look1"},new string[0]);
        Check(recipient.ModelCount("","Recipient favorites")==3,"recipe membership does not include its source models");
        Wait(recipient.StorageReport());
        var relocated=Path.Combine(root,"moved");var oldRoot=recipient.Root;Wait(recipient.Relocate(relocated));
        var reopened=new SharedLibrary(oldRoot,ValidateFixture);Check(reopened.Root==relocated,"relocation did not redirect future writers");
        Check(reopened.RecipePaths().All(File.Exists),"relocation lost recipe closure");Check(File.Exists(dependency),"relocation broke an earlier saved-scene path");
        Check(immutableBefore.SequenceEqual(reopened.RecipePaths().Select(ContentObjects.Hash).OrderBy(x=>x)),"relocation changed authored recipe bytes");
        var movedMeshes=new HashSet<string>();foreach(var package in Directory.GetDirectories(Path.Combine(relocated,"packs/user")))foreach(var mesh in Directory.GetFiles(Path.Combine(package,"assets"),"*.cmesh"))movedMeshes.Add(FileId(mesh));
        Check(movedMeshes.Count==3,"relocated hard-link views duplicate meshes");
        var migration=Path.Combine(root,"legacy");Directory.CreateDirectory(migration);var legacyPath=Path.Combine(migration,"legacy.csrecipe.json");File.Copy(paths[0],legacyPath);
        var legacyHash=ContentObjects.Hash(legacyPath);var sourcePackage=store.Package(legacyHash);var legacyPackage=Path.Combine(migration,"Presets",legacyHash);
        foreach(var path in Directory.GetFiles(sourcePackage,"*",SearchOption.AllDirectories)){var relative=path.Substring(sourcePackage.Length+1);var to=Path.Combine(legacyPackage,relative);Directory.CreateDirectory(Path.GetDirectoryName(to));File.Copy(path,to);}
        Wait(reopened.Migrate(migration));Check(File.Exists(legacyPath),"migration removed its original recipe");Check(reopened.RecipePaths().Any(p=>reopened.RecipeId(p)=="look0"),"legacy complete recipe was not migrated");
        Wait(reopened.ConsolidateMigrated(migration));foreach(var legacyMesh in Directory.GetFiles(Path.Combine(legacyPackage,"assets"),"*.cmesh"))Check(FileId(legacyMesh)==FileId(Path.Combine(reopened.Root,"objects",Path.GetFileNameWithoutExtension(legacyMesh))),"migration consolidation did not reuse the canonical allocation");
        Wait(reopened.ConsolidateMigrated(migration));
        var restoredCount=reopened.RecipePaths().Length;reopened.RemoveRecipe("look0");Wait(reopened.RestorePrevious());Check(reopened.RecipePaths().Length==restoredCount,"previous committed catalog did not restore removed cards");
        var receiptBefore=File.ReadAllText(Path.Combine(relocated,"catalog/current.json"));Wait(reopened.Migrate(migration));Check(File.ReadAllText(Path.Combine(relocated,"catalog/current.json"))==receiptBefore,"repeat migration adds a catalog revision");
        Wait(reopened.RecoverStaging());
        var headBeforeCrash=File.ReadAllText(Path.Combine(reopened.Root,"catalog/current.json"));CrashCheck("crash-promote",reopened.Root,Path.Combine(root,"promote.signal"));
        var afterCrash=new SharedLibrary(reopened.Root,ValidateFixture);Check(File.ReadAllText(Path.Combine(reopened.Root,"catalog/current.json"))==headBeforeCrash,"interrupted promotion exposed a partial successor");Check(afterCrash.RecipePaths().All(File.Exists),"interrupted promotion damaged previous recipe closure");
        Wait(afterCrash.RecoverStaging());Check(!Directory.GetDirectories(Path.Combine(afterCrash.Root,"staging"),"save-*").Any(),"dead owned save staging was not recovered");
        Save(afterCrash,"interrupted-save");Check(afterCrash.RecipePaths().Any(p=>afterCrash.RecipeId(p)=="interrupted-save"),"interrupted save cannot be retried");
        CrashCheck("crash-commit",afterCrash.Root,Path.Combine(root,"commit.signal"));var committed=new SharedLibrary(afterCrash.Root,ValidateFixture);
        Check(committed.Collections().Contains("Committed interrupted generation"),"a published head was lost when the process ended before its completion receipt");Check(committed.RecipePaths().All(File.Exists),"interrupted post-commit work damaged dependency closure");
        var sceneSave=committed.BeginSceneSave("","");File.WriteAllBytes(Path.Combine(sceneSave.Directory,"scene.max"),Bytes("bounded opaque scene fixture"));
        var sceneEntry=Wait(committed.PublishScene(sceneSave,"Recovery scene","{}","[]",.001,1,"[]",""));var sceneHash=ContentObjects.Hash(sceneEntry);
        var sceneDoc=D(LibraryJson.Parse(File.ReadAllText(sceneEntry)));Check(S(sceneDoc["scatterVersion"])==typeof(SharedLibrary).Assembly.GetName().Version.ToString(),"Scene provenance differs from its actual assembly version");
        var activeScene=Wait(committed.PrepareScene(sceneEntry,sceneHash));Check(File.Exists(Path.Combine(Path.GetDirectoryName(activeScene),".cyrus-operation.json")),"Scene-load stage has no ownership marker");
        Wait(committed.RecoverStaging());Check(File.Exists(activeScene),"Recovery removed an active scene load");committed.DiscardSceneLoad(activeScene);Check(!Directory.Exists(Path.GetDirectoryName(activeScene)),"Successful scene load did not discard its stage");
        var unverified=Path.Combine(committed.Root,"staging","scene-load-unverified");Directory.CreateDirectory(unverified);File.WriteAllText(Path.Combine(unverified,"scene.max"),"unverified user data");
        var sceneSignal=Path.Combine(root,"scene-load.signal");CrashCheck("crash-scene-load",committed.Root,sceneSignal);var abandoned=File.ReadAllText(sceneSignal);Check(File.Exists(abandoned),"Owned crash fixture did not retain a staged copy");
        Wait(committed.RecoverStaging());Check(!Directory.Exists(Path.GetDirectoryName(abandoned)),"Abandoned Scene-load copy was not recovered");Check(File.Exists(Path.Combine(unverified,"scene.max")),"Recovery removed an unverified folder");Check(ContentObjects.Hash(sceneEntry)==sceneHash,"Recovery changed the published Scene preset");
        Console.WriteLine("PASS "+checks+" managed transaction checks; native validation is a separately injected fixture boundary.");return 0;
    }catch(Exception ex){Console.Error.WriteLine(ex);return 1;}}
}
