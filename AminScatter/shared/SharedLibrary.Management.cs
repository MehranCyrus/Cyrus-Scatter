#nullable disable
using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;

namespace Cyrus.Content {
    public sealed partial class SharedLibrary {
        readonly object modelQueryGate=new object();
        Dictionary<string,object> modelQuery;
        long modelQueryToken;
        public LibraryOperation PrepareModels(){var token=Interlocked.Increment(ref modelQueryToken);return new LibraryOperation(check=>{check();var snapshot=Catalog();check();lock(modelQueryGate){if(token!=modelQueryToken)throw new OperationCanceledException();modelQuery=snapshot;}return "Model catalog ready.";});}
        Dictionary<string,object> QueryModels(){lock(modelQueryGate)if(modelQuery!=null)return modelQuery;return Catalog();}
        public string[] ModelCollections(){return D(QueryModels()["collections"]).Values.Select(x=>S(D(x)["name"])).OrderBy(x=>x,StringComparer.OrdinalIgnoreCase).ToArray();}
        IEnumerable<KeyValuePair<string,object>> ModelRows(string search,string collection) {
            var catalog=QueryModels();HashSet<string> allowed=null;
            if(!String.IsNullOrEmpty(collection)){
                object value;if(!D(catalog["collections"]).TryGetValue(HashText("collection:"+collection),out value))throw new IOException("Collection no longer exists.");
                var group=D(value);allowed=new HashSet<string>(A(group["models"]).Select(S),StringComparer.Ordinal);
                foreach(var raw in A(group["recipes"])){object entry;if(!D(catalog["recipes"]).TryGetValue(S(raw),out entry))throw new IOException("Collection recipe is missing.");
                    object refs;if(D(entry).TryGetValue("models",out refs))foreach(var id in A(refs))allowed.Add(S(id));}
            }
            search=search??"";if(search.Length>1024)throw new IOException("Search text is too long.");
            return D(catalog["models"]).Where(p=>(allowed==null||allowed.Contains(p.Key))&&(search.Length==0||S(D(p.Value)["name"]).IndexOf(search,StringComparison.OrdinalIgnoreCase)>=0)).OrderBy(p=>S(D(p.Value)["name"]),StringComparer.OrdinalIgnoreCase);
        }
        public int ModelCount(string search,string collection){return ModelRows(search,collection).Count();}
        public LibraryModel[] ModelPage(string search,string collection,int page){if(page<1||page>79)throw new IOException("Invalid model page.");return ModelRows(search,collection).Skip((page-1)*128).Take(128).Select(p=>Model(p.Key,D(p.Value))).ToArray();}
        public LibraryOperation AddToCollectionFromJson(string name,string recipeIds,string modelIds) {
            var recipes=A(LibraryJson.Parse(recipeIds,131072)).Select(S).ToArray();var models=A(LibraryJson.Parse(modelIds,131072)).Select(S).ToArray();
            if(recipes.Length+models.Length>10000)throw new IOException("Collection selection exceeds its bound.");
            return new LibraryOperation(check=>{check();AddToCollection(name,recipes,models);return "Added to "+name+". Model and texture bytes were reused.";});
        }
        public LibraryOperation RenameModel(string id,string name) {
            name=(name??"").Trim();if(name.Length<1||name.Length>160||name.Any(c=>c<32))throw new IOException("Choose a model name of 1–160 characters.");
            return new LibraryOperation(check=>{using(Lock(check)){var c=Catalog();object row;if(!D(c["models"]).TryGetValue(id,out row))throw new IOException("Model no longer exists.");D(row)["name"]=name;PublishCatalog(c,check);return "Model details saved; payload bytes were reused.";}});
        }
        public LibraryOperation UpdateModelRevision(string id,string replacement) {
            return new LibraryOperation(check=>{using(Lock(check)){var c=Catalog();object current,next;
                if(!D(c["models"]).TryGetValue(id,out current)||!D(c["models"]).TryGetValue(replacement,out next))throw new IOException("Choose two current library models.");
                var row=D(LibraryJson.Parse(LibraryJson.Write(next)));row["name"]=D(current)["name"];D(c["models"])[id]=row;PublishCatalog(c,check);
                return "Model revision selected. Existing recipes retain their saved asset revisions.";
            }});
        }
        public LibraryOperation Migrate(string directory) {
            directory=LibraryLocation.Full(directory);
            return new LibraryOperation(check=>{
                if(directory==Root)return "This is already the active shared library.";
                var candidates=Directory.EnumerateFiles(directory,"*.csrecipe.json",SearchOption.TopDirectoryOnly).Take(10001).ToArray();
                if(candidates.Length>10000)throw new IOException("Choose a folder containing at most 10,000 recipes.");
                if(candidates.Length==0)throw new IOException("No supported saved recipes were found in the selected folder.");
                using(Lock(check)){
                    var c=Catalog();var adopted=new List<object>();int ready=0,settings=0;
                    foreach(var path in candidates){check();var text=Read(path,8388608);var sha=HashText(text);var recipe=D(LibraryJson.Parse(text));
                        ValidateRecipe(path);
                        if(S(recipe["format"])!="cyrus.planting-recipe"||N(recipe["formatVersion"])<1||N(recipe["formatVersion"])>9)throw new IOException("Resave unsupported recipes with the current plugin before migration. Original files were retained.");
                        var id=S(recipe["id"]);if(!System.Text.RegularExpressions.Regex.IsMatch(id,"^[A-Za-z0-9_-]{1,80}$"))throw new IOException("Invalid migrated recipe identity.");
                        object previous;if(D(c["recipes"]).TryGetValue(id,out previous)&&S(D(previous)["sha256"])!=sha)throw new IOException("A recipe with this identity has a different local revision. Resolve the conflict before migration.");
                        var package=Child(directory,"Presets/"+sha);var complete=File.Exists(Child(package,"cyrus.package.json"));
                        // A present invalid package is a failure, never a settings-only downgrade.
                        if(complete){if(AdoptPackage(package,check)!=sha)throw new IOException("Migrated recipe/package mismatch.");ready++;}else settings++;
                        Ingest(path,sha,UTF8.GetByteCount(text),check);
                        Attachments(recipe,row=>Ingest(Child(directory,S(row["file"])),S(row["sha256"]),N(row["bytes"]),check));
                        var refs=complete?RegisterModels(c,sha):new List<object>();D(c["recipes"])[id]=M("sha256",sha,"package",complete?(object)sha:null,"models",refs,"modelRevisions",new List<object>(refs));
                        adopted.Add(M("original",path,"id",id,"sha256",sha,"ready",complete));
                    }
                    var operation="migration-"+Guid.NewGuid().ToString("N");PublishCatalog(c,check,operation);
                    // Preserve source folders and existing absolute texture paths.
                    try{NewText(Child(Root,"receipts/"+operation+".json"),LibraryJson.Write(M("format","cyrus.library-migration","version",1,"source",directory,"recipes",adopted)));}catch{}
                    return "Migrated "+ready+" complete recipes and "+settings+" settings-only recipes. Original files and scene paths were retained.";
                }
            });
        }
        public LibraryOperation StorageReport() {
            return new LibraryOperation(check=>{
                long bytes=0,allocated=0;int objects=0;foreach(var file in Directory.EnumerateFiles(Child(Root,"objects"))){check();if(++objects>1000000)throw new IOException("Storage report reached its object-count bound.");bytes=checked(bytes+new FileInfo(file).Length);allocated=checked(allocated+ContentObjects.AllocatedBytes(file));}
                long metadata=0;int snapshots=0;foreach(var file in Directory.EnumerateFiles(Child(Root,"catalog/snapshots"),"*.json")){check();if(++snapshots>100000)throw new IOException("Storage report reached its history bound.");metadata=checked(metadata+new FileInfo(file).Length);}
                var c=Catalog();return Root+"\n\n"+D(c["recipes"]).Count+" recipes, "+D(c["models"]).Count+" models, "+D(c["collections"]).Count+" collections.\n"+
                    objects+" unique stored objects: "+(bytes/1048576.0).ToString("N2")+" MiB data; "+(allocated/1048576.0).ToString("N2")+" MiB allocated.\nCatalog history: "+(metadata/1048576.0).ToString("N2")+" MiB.\n\nView links reuse object allocations. Migration originals, old relocated stores, repair quarantine and staging may use additional space. Removing cards does not purge published assets.";
            });
        }
        public LibraryOperation ConsolidateMigrated(string directory) {
            directory=LibraryLocation.Full(directory);
            return new LibraryOperation(check=>{using(Lock(check)){
                if(!String.Equals(Path.GetPathRoot(directory),Path.GetPathRoot(Root),StringComparison.OrdinalIgnoreCase))throw new IOException("Consolidation requires the same NTFS volume. Migration originals were retained.");
                var allowed=new HashSet<string>(StringComparer.Ordinal);int count=0;
                foreach(var file in Directory.EnumerateFiles(Child(Root,"receipts"),"migration-*.json")){check();if(++count>10000)throw new IOException("Migration receipt count exceeds its bound.");var receipt=D(ReadJson(file));if(S(receipt["source"])==directory)foreach(var raw in A(receipt["recipes"])){var row=D(raw);if((bool)row["ready"])allowed.Add(S(row["sha256"]));}}
                if(allowed.Count==0)throw new IOException("Migrate this exact folder first. Consolidation only touches verified migration originals.");
                // Resume prepared file transactions. Both filenames are siblings
                // of a reviewed legacy dependency; no original path is removed.
                foreach(var file in Directory.EnumerateFiles(Child(Root,"receipts"),"consolidation-*.json")){check();var receipt=D(ReadJson(file,16384));if(S(receipt["source"])!=directory||S(receipt["phase"])!="prepared")continue;
                    var sha=S(receipt["sha256"]);var bytes=N(receipt["bytes"]);var target=Child(directory,S(receipt["relative"]));var temp=Child(directory,S(receipt["temporary"]));var backup=Child(directory,S(receipt["backup"]));
                    if(Path.GetDirectoryName(target)!=Path.GetDirectoryName(temp)||Path.GetDirectoryName(target)!=Path.GetDirectoryName(backup)||!Path.GetFileName(temp).StartsWith(".cyrus-link-")||!Path.GetFileName(backup).StartsWith(".cyrus-old-"))throw new IOException("Consolidation journal ownership differs.");
                    if(!File.Exists(target)&&File.Exists(backup)){ContentObjects.Verify(backup,sha,bytes);ContentObjects.AtomicNew(backup,target);}
                    ContentObjects.Verify(target,sha,bytes);foreach(var leftover in new[]{temp,backup})if(File.Exists(leftover)){ContentObjects.Verify(leftover,sha,bytes);File.Delete(leftover);}
                    receipt["phase"]="complete";AtomicText(file,LibraryJson.Write(receipt));
                }
                int linked=0,reused=0;long retired=0;
                foreach(var id in allowed){check();var package=Child(directory,"Presets/"+id);validatePackage(package);var info=PackageFiles(package);
                    foreach(var raw in D(info["files"]).Values){check();var row=D(raw);var relative="Presets/"+id+"/"+S(row["file"]);var target=Child(directory,relative);var sha=S(row["sha256"]);var bytes=N(row["bytes"]);var blob=Child(Root,"objects/"+sha);
                        ContentObjects.Verify(target,sha,bytes);ContentObjects.Verify(blob,sha,bytes);if(ContentObjects.FileIdentity(target)==ContentObjects.FileIdentity(blob)){reused++;continue;}
                        var parent=relative.Substring(0,relative.LastIndexOf('/')+1);var token=Guid.NewGuid().ToString("N").Substring(0,16);var temp=parent+".cyrus-link-"+token;var backup=parent+".cyrus-old-"+token;
                        var journal=Child(Root,"receipts/consolidation-"+Guid.NewGuid().ToString("N")+".json");var record=M("source",directory,"relative",relative,"temporary",temp,"backup",backup,"sha256",sha,"bytes",bytes,"phase","prepared");
                        NewText(journal,LibraryJson.Write(record));ContentObjects.Link(blob,Child(directory,temp));File.Replace(Child(directory,temp),target,Child(directory,backup));ContentObjects.Verify(target,sha,bytes);
                        retired=checked(retired+bytes);File.Delete(Child(directory,backup));record["phase"]="complete";AtomicText(journal,LibraryJson.Write(record));linked++;
                    }
                }
                return "Consolidated "+linked+" legacy dependency files; "+reused+" already shared. Replaced "+retired+" logical duplicate bytes with verified hard links. Existing scene paths were preserved.";
            }});
        }
        public LibraryOperation Relocate(string destination) {
            destination=LibraryLocation.Full(destination);
            if(destination.Length>80||destination.StartsWith(Root+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)||Root.StartsWith(destination+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)||destination==Root)throw new IOException("Choose a separate short local NTFS folder.");
            return new LibraryOperation(check=>{
                using(Lock(check)){
                    if(Directory.Exists(destination)&&Directory.EnumerateFileSystemEntries(destination).Any())throw new IOException("Relocation needs an empty destination. Existing folders were retained.");
                    var next=new SharedLibrary(destination,validatePackage);
                    using(next.Lock(check)){
                        int count=0;foreach(var file in Directory.EnumerateFiles(Child(Root,"objects"))){check();if(++count>1000000)throw new IOException("Relocation reached its object count bound.");var sha=Path.GetFileName(file);if(!LibraryLocation.IsHash(sha))throw new IOException("Unexpected object in the source store.");next.Ingest(file,sha,new FileInfo(file).Length,check);}
                        count=0;foreach(var path in Directory.EnumerateDirectories(Child(Root,"packs/user"))){check();if(++count>10000)throw new IOException("Relocation reached its package count bound.");next.AdoptPackage(path,check);}
                        count=0;foreach(var path in Directory.EnumerateDirectories(Child(Root,"models"))){check();if(++count>10000)throw new IOException("Relocation reached its model revision count bound.");next.AdoptModel(path,check);}
                        count=0;foreach(var file in Directory.EnumerateFiles(Child(Root,"catalog/snapshots"),"*.json")){check();if(++count>100000)throw new IOException("Relocation reached its history bound.");var text=Read(file,8388608);if(Path.GetFileNameWithoutExtension(file)!=HashText(text))throw new IOException("Catalog history is corrupt.");var target=Child(destination,"catalog/snapshots/"+Path.GetFileName(file));if(!File.Exists(target))NewText(target,text);}
                        count=0;foreach(var file in Directory.EnumerateFiles(Child(Root,"receipts"),"*.json")){check();if(++count>100000)throw new IOException("Relocation reached its receipt bound.");var text=Read(file);LibraryJson.Parse(text);var target=Child(destination,"receipts/"+Path.GetFileName(file));if(!File.Exists(target))NewText(target,text);}
                        var catalog=Catalog();foreach(var raw in D(catalog["recipes"]).Values){check();next.EnsureEntry(D(raw));}
                        check();AtomicText(Child(destination,"store.json"),Read(Child(Root,"store.json"),16384));
                        AtomicText(Child(destination,"catalog/current.json"),Read(Child(Root,"catalog/current.json"),16384));
                        // The destination is complete before the old store redirects new writers.
                        AtomicText(Child(Root,"relocated.json"),LibraryJson.Write(M("format","cyrus.library-relocation","version",1,"store",Id,"destination",destination)));
                        return destination;
                    }
                }
            });
        }
        public void MarkStage(string directory) {
            directory=LibraryLocation.Full(directory);if(Path.GetDirectoryName(directory)!=Child(Root,"staging"))throw new IOException("Staging ownership differs.");
            var p=Process.GetCurrentProcess();NewText(Child(directory,".cyrus-operation.json"),LibraryJson.Write(M("format","cyrus.owned-stage","version",1,"pid",p.Id,"start_utc",p.StartTime.ToUniversalTime().Ticks)));
        }
        public LibraryOperation RecoverStaging() {
            return new LibraryOperation(check=>{int removed=0,retained=0;using(Lock(check)){
                foreach(var directory in Directory.EnumerateDirectories(Child(Root,"staging"))){check();var marker=Child(directory,".cyrus-operation.json");if(!File.Exists(marker)){retained++;continue;}
                    var data=D(ReadJson(marker,16384));if(S(data["format"])!="cyrus.owned-stage"||N(data["version"])!=1){retained++;continue;}
                    bool alive=false;try{var process=Process.GetProcessById(checked((int)N(data["pid"])));alive=!process.HasExited&&process.StartTime.ToUniversalTime().Ticks==N(data["start_utc"]);}catch(ArgumentException){}catch(InvalidOperationException){}catch(System.ComponentModel.Win32Exception){retained++;continue;}
                    if(alive){retained++;continue;}Directory.Delete(LibraryLocation.Full(directory),true);removed++;
                }
            }return "Recovered "+removed+" abandoned owned staging folders; retained "+retained+" active or unverified folders. Published assets were preserved.";});
        }
        public LibraryOperation RestorePrevious() {
            return new LibraryOperation(check=>{using(Lock(check)){
                var current=Catalog();object prior;if(!current.TryGetValue("previous",out prior)||prior==null)throw new IOException("There is no previous committed catalog.");
                var hash=S(prior);if(!LibraryLocation.IsHash(hash))throw new IOException("Invalid history identity.");var text=Read(Child(Root,"catalog/snapshots/"+hash+".json"),8388608);if(HashText(text)!=hash)throw new IOException("Catalog history differs.");
                var restored=D(LibraryJson.Parse(text));foreach(var row in D(restored["recipes"]).Values){check();var data=D(row);if(data["package"]!=null)validatePackage(Package(S(data["package"])));else ValidateRecipe(Child(Root,"objects/"+S(data["sha256"])));}
                foreach(var row in D(restored["models"]).Values){check();ValidateModel(ModelDirectory(S(D(row)["revision"])));}
                PublishCatalog(restored,check);return "Previous catalog restored as a new complete revision. Published assets and saved scenes were retained.";
            }});
        }
        public LibraryOperation PrepareRelink(string pathsJson) {
            var paths=A(LibraryJson.Parse(pathsJson,1048576)).Select(S).Distinct(StringComparer.OrdinalIgnoreCase).ToArray();if(paths.Length>4096)throw new IOException("Relink exceeds 4,096 image paths.");
            return new LibraryOperation(check=>{using(Lock(check)){var result=M();foreach(var path in paths){check();var sha=ImageDigest(path);var suffix=Path.GetExtension(path).TrimStart('.').ToLowerInvariant();
                if(sha.Length==0||!new[]{"png","jpg","jpeg","tga","bmp","tif","tiff"}.Contains(suffix))continue;
                var blob=Child(Root,"objects/"+sha);if(!File.Exists(blob))continue;var bytes=new FileInfo(blob).Length;if(bytes<1||bytes>MaxObject)throw new IOException("Image exceeds the relink byte bound.");ContentObjects.Verify(blob,sha,bytes);
                var target=Child(Root,"resolved/"+Path.GetFileNameWithoutExtension(path)+"."+suffix);LinkObject(target,sha,bytes);result[path]=target;
            }return LibraryJson.Write(result);}});
        }
        public static string RelinkTarget(string result,string original){var data=D(LibraryJson.Parse(result,1048576));object value;return data.TryGetValue(original,out value)?S(value):"";}
        static string ImageDigest(string path){var name=Path.GetFileNameWithoutExtension(path);if(LibraryLocation.IsHash(name))return name;if(name.Length==129&&name[64]=='-'&&LibraryLocation.IsHash(name.Substring(0,64))&&LibraryLocation.IsHash(name.Substring(65)))return name.Substring(0,64);return "";}
        public static void RegisterRoot(string config,string root){root=LibraryLocation.Full(root);if(root.Length>80)throw new IOException("Choose a shared root of at most 80 characters.");config=LibraryLocation.Full(config);Directory.CreateDirectory(Path.GetDirectoryName(config));AtomicText(config,root);}
        public static string[] SourceProvenance(string directory) {
            directory=LibraryLocation.Full(directory);var package=new DirectoryInfo(directory);if(!LibraryLocation.IsHash(package.Name)||package.Parent==null)return new string[0];
            var model=package.Parent.Name=="models"&&package.Parent.Parent!=null;
            var recipe=package.Parent.Name=="user"&&package.Parent.Parent!=null&&package.Parent.Parent.Name=="packs"&&package.Parent.Parent.Parent!=null;if(!model&&!recipe)return new string[0];
            var root=LibraryLocation.Full(model?package.Parent.Parent.FullName:package.Parent.Parent.Parent.FullName);var marker=Child(root,"store.json");if(!File.Exists(marker))return new string[0];var data=D(ReadJson(marker,16384));
            if(S(data["format"])!="cyrus.asset-store"||N(data["version"])!=1)throw new IOException("Shared source ownership differs.");return new[]{S(data["id"]),root,package.Name,model?"model":"recipe"};
        }
        public LibraryOperation RepairFromArchive(string archive) {
            archive=LibraryLocation.Full(archive);
            return new LibraryOperation(check=>{
                VerifyArchive(archive,check);int repaired=0,views=0;
                using(Lock(check))using(var input=new FileStream(archive,FileMode.Open,FileAccess.Read,FileShare.Read))using(var zip=new System.IO.Compression.ZipArchive(input,System.IO.Compression.ZipArchiveMode.Read)){
                    var manifest=ArchiveManifest(zip);Directory.CreateDirectory(Child(Root,"quarantine"));
                    foreach(var pair in D(manifest["objects"])){check();var blob=Child(Root,"objects/"+pair.Key);bool valid=false;
                        if(File.Exists(blob))try{ContentObjects.Verify(blob,pair.Key,N(pair.Value));valid=true;}catch(IOException){}
                        if(valid)continue;var stage=Child(Root,"staging/repair-"+Guid.NewGuid().ToString("N"));
                        try{using(var source=zip.GetEntry("objects/"+pair.Key).Open())using(var output=new FileStream(stage,FileMode.CreateNew,FileAccess.Write,FileShare.None)){if(Copy(source,output,N(pair.Value),check)!=pair.Key)throw new IOException("Repair archive changed.");output.Flush(true);}
                            if(File.Exists(blob))File.Replace(stage,blob,Child(Root,"quarantine/"+pair.Key+"-"+Guid.NewGuid().ToString("N")));else ContentObjects.AtomicNew(stage,blob);repaired++;
                        }finally{if(File.Exists(stage))File.Delete(stage);}
                    }
                    Action<string,string,long> repairView=(path,sha,bytes)=>{
                        bool valid=false;if(File.Exists(path))try{ContentObjects.Verify(path,sha,bytes);valid=true;}catch(IOException){}
                        if(valid)return;var blob=Child(Root,"objects/"+sha);ContentObjects.Verify(blob,sha,bytes);var temporary=Child(Root,"staging/view-"+Guid.NewGuid().ToString("N"));
                        try{ContentObjects.Link(blob,temporary);if(File.Exists(path))File.Replace(temporary,path,Child(Root,"quarantine/view-"+Guid.NewGuid().ToString("N")));else ContentObjects.AtomicNew(temporary,path);views++;}finally{if(File.Exists(temporary))File.Delete(temporary);}
                    };
                    int count=0;foreach(var directory in Directory.EnumerateDirectories(Child(Root,"packs/user"))){check();if(++count>10000)throw new IOException("Repair reached the package bound.");var id=Path.GetFileName(directory);object info;
                        var files=D(manifest["packages"]).TryGetValue(id,out info)?D(info):PackageFiles(directory);
                        foreach(var raw in D(files["files"]).Values){var file=D(raw);repairView(Child(directory,S(file["file"])),S(file["sha256"]),N(file["bytes"]));}validatePackage(directory);
                    }
                    count=0;foreach(var directory in Directory.EnumerateDirectories(Child(Root,"models"))){check();if(++count>10000)throw new IOException("Repair reached the model revision bound.");var id=Path.GetFileName(directory);object info;
                        var files=D(manifest["modelPackages"]).TryGetValue(id,out info)?D(info):ModelFiles(directory);
                        foreach(var raw in D(files["files"]).Values){var file=D(raw);repairView(Child(directory,S(file["file"])),S(file["sha256"]),N(file["bytes"]));}ValidateModel(directory);
                    }
                    count=0;foreach(var path in Directory.EnumerateFiles(BitmapDirectory)){check();if(++count>1000000)throw new IOException("Repair reached the bitmap view bound.");var sha=ImageDigest(path);if(sha.Length==0)throw new IOException("Unexpected bitmap view.");var blob=Child(Root,"objects/"+sha);repairView(path,sha,new FileInfo(blob).Length);}
                    return "Repaired "+repaired+" objects and "+views+" views from verified backup bytes. Replaced corrupt bytes were retained in quarantine.";
                }
            });
        }
    }
}
