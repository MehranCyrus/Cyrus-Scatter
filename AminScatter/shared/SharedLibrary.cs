#nullable disable
using System;
using System.IO;
using System.Text;
using System.Linq;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Threading;
using System.Threading.Tasks;
using System.IO.Compression;
using System.Runtime.InteropServices;

namespace Cyrus.Content {
    public sealed class LibrarySave {
        public string Directory {get;internal set;}
        public string RecipePath {get;internal set;}
        public string ExpectedHash {get;internal set;}
        public string OriginalPath {get;internal set;}
    }
    public sealed class LibraryOperation {
        static readonly SemaphoreSlim workers=new SemaphoreSlim(2,2);
        static int pending;
        readonly CancellationTokenSource cancel=new CancellationTokenSource();
        readonly Task task;
        volatile string state="working",error="",result="";
        public string State {get{return state;}}
        public string Error {get{return error;}}
        public string Result {get{return result;}}
        internal LibraryOperation(Func<Action,string> action) {
            if(Interlocked.Increment(ref pending)>8){Interlocked.Decrement(ref pending);throw new IOException("The library has eight pending operations. Wait or cancel before starting another.");}
            task=Task.Run(()=>{bool acquired=false;try{workers.Wait(cancel.Token);acquired=true;ContentObjects.Checkpoint=()=>cancel.Token.ThrowIfCancellationRequested();result=action(ContentObjects.Checkpoint);state="complete";}
                catch(OperationCanceledException){state="cancelled";}catch(Exception ex){error=ex.Message;state="failed";}
                finally{ContentObjects.Checkpoint=null;if(acquired)workers.Release();Interlocked.Decrement(ref pending);}});
        }
        public void Cancel(){cancel.Cancel();}
        internal void Finally(Action<LibraryOperation> cleanup){task.ContinueWith(_=>{try{cleanup(this);}catch{}},TaskScheduler.Default);}
        public bool Terminal {get{return task.IsCompleted;}}
    }
    public sealed class LibraryModel {
        public string Id {get;internal set;}
        public string Name {get;internal set;}
        public string Revision {get;internal set;}
        public string Package {get;internal set;}
        public string Node {get;internal set;}
        public string StoreID {get;internal set;}="";
        public string Thumbnail {get;internal set;}="";
        public string ThumbnailHash {get;internal set;}="";
        public long ThumbnailBytes {get;internal set;}
    }
    public sealed partial class SharedLibrary {
        const long MaxObject=2L*1024*1024*1024,MaxBundle=16L*1024*1024*1024;
        const int MaxCatalog=10000;
        public string Root {get;private set;}
        public string Id {get;private set;}
        public string LastSummary {get;private set;}="";
        readonly Action<string> validatePackage;
        public string BitmapDirectory {get{return Child(Root,"resolved");}}
        static readonly UTF8Encoding UTF8=new UTF8Encoding(false,true);
        static Dictionary<string,object> D(object x){return LibraryJson.Obj(x);}
        static List<object> A(object x){return LibraryJson.Arr(x);}
        static string S(object x){return LibraryJson.Str(x);}
        static long N(object x){return LibraryJson.Int(x);}
        static Dictionary<string,object> M(params object[] x){return LibraryJson.Map(x);}
        static string Hash(byte[] bytes){using(var h=SHA256.Create())return BitConverter.ToString(h.ComputeHash(bytes)).Replace("-","").ToLowerInvariant();}
        static string HashText(string text){return Hash(UTF8.GetBytes(text));}
        internal static string Child(string root,string relative) {
            if(String.IsNullOrEmpty(relative)||relative.Contains(":")||relative.Contains("\\")||relative.StartsWith("/"))throw new IOException("Invalid library relative path.");
            foreach(var part in relative.Split('/'))if(part.Length==0||part=="."||part==".."||part.TrimEnd(' ','.')!=part||part.IndexOfAny(Path.GetInvalidFileNameChars())>=0)throw new IOException("Invalid library path component.");
            var path=LibraryLocation.Full(Path.Combine(root,relative.Replace('/',Path.DirectorySeparatorChar)));
            if(!path.StartsWith(root+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase))throw new IOException("Library path escaped its root.");return path;
        }
        static string Read(string path,int cap=33554432) {
            path=LibraryLocation.Full(path);using(var stream=new FileStream(path,FileMode.Open,FileAccess.Read,FileShare.Read)){
                if(stream.Length<1||stream.Length>cap)throw new IOException("Library metadata exceeds its bound.");
                using(var reader=new StreamReader(stream,UTF8,false)){var text=reader.ReadToEnd();if(UTF8.GetByteCount(text)>cap)throw new IOException("Library metadata grew beyond its bound.");return text;}}
        }
        static object ReadJson(string path,int cap=33554432){return LibraryJson.Parse(Read(path,cap),cap);}
        static void NewText(string path,string text) {
            Directory.CreateDirectory(Path.GetDirectoryName(path));var bytes=UTF8.GetBytes(text);
            using(var output=new FileStream(path,FileMode.CreateNew,FileAccess.Write,FileShare.None)){output.Write(bytes,0,bytes.Length);output.Flush(true);}
        }
        static void AtomicText(string path,string text) {
            var temp=path+"."+Guid.NewGuid().ToString("N")+".tmp";
            try{NewText(temp,text);if(File.Exists(path))File.Replace(temp,path,null);else ContentObjects.AtomicNew(temp,path);}finally{if(File.Exists(temp))File.Delete(temp);}
        }
        IDisposable Lock(Action checkpoint=null) {
            if(File.Exists(Child(Root,"relocated.json")))throw new IOException("This library was relocated. Reopen the library to use its current location.");
            var until=DateTime.UtcNow.AddSeconds(120);
            while(true){try{return new FileStream(Child(Root,"content.lock"),FileMode.OpenOrCreate,FileAccess.ReadWrite,FileShare.None);}
                catch(IOException){if(checkpoint!=null)checkpoint();if(checkpoint==null||DateTime.UtcNow>=until)throw new IOException("Library is busy. Retry when the other operation finishes.");Thread.Sleep(50);}}
        }
        [DllImport("kernel32.dll",CharSet=CharSet.Unicode)] static extern bool GetModuleHandleEx(int flags,string name,out IntPtr module);
        [DllImport("kernel32.dll")] static extern bool FreeLibrary(IntPtr module);
        [DllImport("kernel32.dll",CharSet=CharSet.Ansi)] static extern IntPtr GetProcAddress(IntPtr module,string name);
        [UnmanagedFunctionPointer(CallingConvention.Cdecl,CharSet=CharSet.Unicode)]
        delegate int CancelCheck();
        [UnmanagedFunctionPointer(CallingConvention.Cdecl,CharSet=CharSet.Unicode)]
        delegate int PackageCheck([MarshalAs(UnmanagedType.LPWStr)]string directory,StringBuilder error,int capacity,CancelCheck cancel);
        static readonly SemaphoreSlim nativeValidation=new SemaphoreSlim(1,1);
        static void NativeCheck(string directory,string export) {
            // The export only reads copied bytes. Pin the DLL for the entire call;
            // decoding is serialized to bound peak package memory across workers.
            while(!nativeValidation.Wait(50)){if(ContentObjects.Checkpoint!=null)ContentObjects.Checkpoint();}
            IntPtr module=IntPtr.Zero;
            try{
                // Max plug-ins are process-resident. PIN also prevents the last
                // worker reference from unloading SDK statics on a file thread.
                if(!GetModuleHandleEx(1,"AminScatter.dlx",out module))throw new IOException("Load the complete matching shared-library native package and restart Max.");
                var function=GetProcAddress(module,export);if(function==IntPtr.Zero)throw new IOException("The shared-library native validator does not match this gallery.");
                var check=(PackageCheck)Marshal.GetDelegateForFunctionPointer(function,typeof(PackageCheck));var error=new StringBuilder(2048);
                CancelCheck cancellation=()=>{try{if(ContentObjects.Checkpoint!=null)ContentObjects.Checkpoint();return 0;}catch(OperationCanceledException){return 1;}};
                var result=check(directory,error,error.Capacity,cancellation);GC.KeepAlive(cancellation);
                if(ContentObjects.Checkpoint!=null)ContentObjects.Checkpoint();
                if(result!=1)throw new IOException(error.Length==0?"Native library validation failed.":error.ToString());
            }finally{if(module!=IntPtr.Zero)FreeLibrary(module);nativeValidation.Release();}
        }
        static void NativeValidate(string directory){NativeCheck(directory,"CyrusLibraryVerifyPackageV1");}
        void ValidateRecipe(string path){if(validatePackage.Method==((Action<string>)NativeValidate).Method)NativeCheck(path,"CyrusLibraryVerifyRecipeV1");}
        public SharedLibrary(string root):this(root,NativeValidate){}
        internal SharedLibrary(string root,Action<string> validator) {
            validatePackage=validator??throw new ArgumentNullException("validator");
            var visited=new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            while(true){root=LibraryLocation.Full(root);if(!visited.Add(root)||visited.Count>16)throw new IOException("Library relocation chain is invalid.");
                var redirect=Path.Combine(root,"relocated.json");if(!File.Exists(redirect))break;
                var move=D(ReadJson(redirect,16384));if(S(move["format"])!="cyrus.library-relocation"||N(move["version"])!=1)throw new IOException("Unsupported library relocation record.");
                var next=LibraryLocation.Full(S(move["destination"]));var marker=D(ReadJson(Path.Combine(next,"store.json"),16384));
                if(S(marker["id"])!=S(move["store"]))throw new IOException("Relocated library ownership differs.");root=next;
            }
            Root=LibraryLocation.Full(root);if(Root.Length>80)throw new IOException("Choose a shared library path of at most 80 characters for all supported Max hosts.");Directory.CreateDirectory(Root);
            var drive=new DriveInfo(Path.GetPathRoot(Root));if(!String.Equals(drive.DriveFormat,"NTFS",StringComparison.OrdinalIgnoreCase)||!(drive.DriveType==DriveType.Fixed||drive.DriveType==DriveType.Removable))throw new IOException("Choose a local NTFS library location.");
            using(Lock()) {
                var marker=Child(Root,"store.json");if(File.Exists(marker)){var doc=D(ReadJson(marker,16384));if(S(doc["format"])!="cyrus.asset-store"||N(doc["version"])!=1)throw new IOException("Unsupported shared library.");Id=S(doc["id"]);}
                else{Id=Guid.NewGuid().ToString("N");NewText(marker,LibraryJson.Write(M("format","cyrus.asset-store","version",1,"id",Id)));}
                foreach(var name in new[]{"objects","resolved","staging","packs/user","models","catalog/snapshots","catalog/views","receipts"})Directory.CreateDirectory(Child(Root,name));
                if(!File.Exists(Child(Root,"catalog/current.json")))PublishCatalog(Empty(),null);
            }
        }
        static Dictionary<string,object> Empty(){return M("format","cyrus.library-catalog","version",1,"recipes",M(),"models",M(),"collections",M());}
        Dictionary<string,object> Catalog() {
            var pointer=D(ReadJson(Child(Root,"catalog/current.json"),16384));var sha=S(pointer["sha256"]);if(!LibraryLocation.IsHash(sha))throw new IOException("Invalid library generation.");
            var path=Child(Root,"catalog/snapshots/"+sha+".json");var text=Read(path);if(HashText(text)!=sha)throw new IOException("Library generation differs; previous data was retained.");return D(LibraryJson.Parse(text));
        }
        string Generation(){return S(D(ReadJson(Child(Root,"catalog/current.json"),16384))["sha256"]);}
        public string RecipeDirectory {get{return Root;}}
        public string[] RecipePaths(){return D(Catalog()["recipes"]).Values.Select(x=>RecipeEntry(D(x))).ToArray();}
        string RecipeEntry(Dictionary<string,object> row){var sha=S(row["sha256"]);return row["package"]==null?Child(Root,"entries/"+sha+"/entry.csrecipe.json"):Child(Root,"packs/user/"+S(row["package"])+"/entry.csrecipe.json");}
        string PutText(string text) {
            var sha=HashText(text);var target=Child(Root,"objects/"+sha);if(File.Exists(target)){ContentObjects.Verify(target,sha,UTF8.GetByteCount(text));return sha;}
            var temp=Child(Root,"staging/text-"+Guid.NewGuid().ToString("N"));try{NewText(temp,text);ContentObjects.AtomicNew(temp,target);}finally{if(File.Exists(temp))File.Delete(temp);}return sha;
        }
        static void Attachments(Dictionary<string,object> recipe,Action<Dictionary<string,object>> add) {
            if(IsScene(recipe)){add(D(recipe["scene"]));foreach(var raw in A(recipe["assets"]))add(D(D(raw)["payload"]));}
            else foreach(var raw in A(recipe["layers"])) {var layer=D(raw);if(layer["paint"]!=null)add(D(D(layer["paint"])["payload"]));foreach(var rawArea in A(layer["areas"])){var area=D(rawArea);if(area["paint"]!=null)add(D(D(area["paint"])["payload"]));}}
            object presentation;if(recipe.TryGetValue("presentation",out presentation)&&presentation!=null){var p=D(presentation);if(p["thumbnail"]!=null)add(D(p["thumbnail"]));}
        }
        static Dictionary<string,object> Descriptor(string path,string sha,long bytes){return M("file",path,"sha256",sha,"bytes",bytes);}
        void CopyImmutable(string from,string to,string sha,long bytes) {
            ContentObjects.Verify(from,sha,bytes);Directory.CreateDirectory(Path.GetDirectoryName(to));
            if(File.Exists(to)){ContentObjects.Verify(to,sha,bytes);return;}
            if(LibraryLocation.Full(from).StartsWith(Root+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase))ContentObjects.Link(from,to);
            else File.Copy(from,to,false);ContentObjects.Verify(to,sha,bytes);
        }
        public LibrarySave BeginSave(string original,string expected,string filename) {
            if(Path.GetFileName(filename)!=filename||!filename.EndsWith(".csrecipe.json",StringComparison.Ordinal)||filename.Length>110)throw new IOException("Invalid recipe filename.");
            var directory=Child(Root,"staging/save-"+Guid.NewGuid().ToString("N"));Directory.CreateDirectory(directory);
            var result=new LibrarySave{Directory=directory,RecipePath=Child(directory,filename),OriginalPath=original??"",ExpectedHash=expected??""};
            try{MarkStage(directory);if(result.ExpectedHash.Length>0){if(!LibraryLocation.IsHash(expected))throw new IOException("Invalid reviewed recipe identity.");ContentObjects.Verify(original,expected,new FileInfo(original).Length);
                var text=Read(original,8388608);var recipe=D(LibraryJson.Parse(text));NewText(result.RecipePath,text);
                Attachments(recipe,row=>CopyImmutable(Child(Path.GetDirectoryName(original),S(row["file"])),Child(directory,S(row["file"])),S(row["sha256"]),N(row["bytes"])));
            }return result;}catch{Discard(result);throw;}
        }
        public void Discard(LibrarySave save) {
            var path=LibraryLocation.Full(save.Directory);if(Path.GetDirectoryName(path)!=Child(Root,"staging")||!Path.GetFileName(path).StartsWith("save-",StringComparison.Ordinal))throw new IOException("Save staging ownership differs.");
            if(Directory.Exists(path))Directory.Delete(path,true);
        }
        string Ingest(string source,string sha,long bytes,Action checkpoint) {
            if(!LibraryLocation.IsHash(sha)||bytes<1||bytes>MaxObject)throw new IOException("Stored object descriptor exceeds its bound.");
            var target=Child(Root,"objects/"+sha);if(File.Exists(target)){ContentObjects.Verify(target,sha,bytes);return target;}
            // Completed native staging is owned and immutable. Adopt its allocation.
            var full=LibraryLocation.Full(source);if(full.StartsWith(Child(Root,"staging")+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)){
                ContentObjects.Verify(full,sha,bytes);ContentObjects.Link(full,target);return target;
            }
            return ContentObjects.Ingest(Root,source,sha,bytes,checkpoint);
        }
        void LinkObject(string destination,string sha,long bytes) {
            if(!LibraryLocation.IsHash(sha)||bytes<1||bytes>MaxObject)throw new IOException("Invalid linked object descriptor.");
            var source=Child(Root,"objects/"+sha);ContentObjects.Verify(source,sha,bytes);
            if(File.Exists(destination)){ContentObjects.Verify(destination,sha,bytes);return;}ContentObjects.Link(source,destination);
        }
        string AdoptPackage(string directory,Action checkpoint) {
            validatePackage(directory);
            var manifest=D(ReadJson(Child(directory,"cyrus.package.json"),16384));
            if(S(manifest["format"])!="cyrus.library-package"||N(manifest["version"])!=1)throw new IOException("Unsupported portable package.");
            var r=D(manifest["recipe"]);var g=D(manifest["graph"]);
            if(S(r["file"])!="entry.csrecipe.json"||S(g["file"])!="assets.json")throw new IOException("Unexpected package documents.");
            ContentObjects.Verify(Child(directory,"entry.csrecipe.json"),S(r["sha256"]),N(r["bytes"]));
            ContentObjects.Verify(Child(directory,"assets.json"),S(g["sha256"]),N(g["bytes"]));
            var recipe=D(ReadJson(Child(directory,"entry.csrecipe.json"),8388608));var graph=D(ReadJson(Child(directory,"assets.json"),2097152));
            if(A(graph["externalRoles"]).Count>0)throw new IOException("This package has unpackaged dependencies. Resave it with all supported models, materials, terrain and paths before adopting it into the shared library.");
            var files=new Dictionary<string,Dictionary<string,object>>(StringComparer.OrdinalIgnoreCase);
            Action<Dictionary<string,object>> add=row=>{var name=S(row["file"]);Child(directory,name);if(files.ContainsKey(name)){if(LibraryJson.Write(files[name])!=LibraryJson.Write(row))throw new IOException("Conflicting package dependency.");return;}files.Add(name,row);};
            add(r);add(g);Attachments(recipe,add);
            foreach(var raw in A(graph["files"])){var f=D(raw);var sha=S(f["sha256"]);var suffix=S(f["suffix"]);if(!LibraryLocation.IsHash(sha)||!new[]{"cmesh","png","jpg","jpeg","tga","bmp","tif","tiff"}.Contains(suffix))throw new IOException("Unsupported dependency type.");add(Descriptor("assets/"+sha+"."+suffix,sha,N(f["bytes"])));}
            if(files.Count>1024)throw new IOException("Package dependency count exceeds its bound.");
            long total=0;foreach(var row in files.Values){total=checked(total+N(row["bytes"]));if(total>640L*1024*1024)throw new IOException("Package exceeds its bounded profile.");if(checkpoint!=null)checkpoint();Ingest(Child(directory,S(row["file"])),S(row["sha256"]),N(row["bytes"]),checkpoint);}
            var hash=S(r["sha256"]);var target=Child(Root,"packs/user/"+hash);
            if(!Directory.Exists(target)){
                var stage=Child(Root,"staging/package-"+Guid.NewGuid().ToString("N"));Directory.CreateDirectory(stage);
                try{foreach(var row in files.Values)LinkObject(Child(stage,S(row["file"])),S(row["sha256"]),N(row["bytes"]));
                    NewText(Child(stage,"cyrus.package.json"),LibraryJson.Write(manifest));Directory.Move(stage,target);
                }finally{if(Directory.Exists(stage))Directory.Delete(stage,true);}
            }
            foreach(var raw in A(graph["files"])){var f=D(raw);if(S(f["kind"])!="bitmap")continue;LinkObject(Child(Root,"resolved/"+S(f["sha256"])+"."+S(f["suffix"])),S(f["sha256"]),N(f["bytes"]));}
            return hash;
        }
        string PublishCatalog(Dictionary<string,object> catalog,Action checkpoint,string operationId=null) {
            if(D(catalog["recipes"]).Count+D(catalog["models"]).Count>MaxCatalog||D(catalog["collections"]).Count>MaxCatalog)throw new IOException("Library catalog exceeds 10,000 entries or collections.");
            var head=Child(Root,"catalog/current.json");
            if(File.Exists(head)){
                var previous=Generation();
                if(LibraryJson.Write(catalog)==Read(Child(Root,"catalog/snapshots/"+previous+".json")))return Root;
                catalog["previous"]=previous;
            }else catalog["previous"]=null;
            var text=LibraryJson.Write(catalog);if(UTF8.GetByteCount(text)>8388608)throw new IOException("Shared catalog exceeds its 8 MiB native metadata bound.");
            var hash=HashText(text);var snap=Child(Root,"catalog/snapshots/"+hash+".json");if(!File.Exists(snap))NewText(snap,text);
            foreach(var row in D(catalog["recipes"]).Values){if(checkpoint!=null)checkpoint();EnsureEntry(D(row));}
            if(operationId!=null)AtomicText(Child(Root,"receipts/operation-"+operationId+".json"),LibraryJson.Write(M("phase","prepared","generation",hash)));
            if(checkpoint!=null)checkpoint();AtomicText(head,LibraryJson.Write(M("sha256",hash)));return Root;
        }
        void EnsureEntry(Dictionary<string,object> row) {
            var target=RecipeEntry(row);var sha=S(row["sha256"]);var source=Child(Root,"objects/"+sha);
            if(File.Exists(target)){ContentObjects.Verify(target,sha,new FileInfo(source).Length);return;}
            var staging=Child(Root,"staging/entry-"+Guid.NewGuid().ToString("N"));Directory.CreateDirectory(staging);
            try{var recipe=D(ReadJson(source,8388608));LinkObject(Child(staging,"entry.csrecipe.json"),sha,new FileInfo(source).Length);
                Attachments(recipe,x=>LinkObject(Child(staging,S(x["file"])),S(x["sha256"]),N(x["bytes"])));
                Directory.CreateDirectory(Path.GetDirectoryName(Path.GetDirectoryName(target)));Directory.Move(staging,Path.GetDirectoryName(target));
            }finally{if(Directory.Exists(staging))Directory.Delete(staging,true);}
        }
        public LibraryOperation Publish(LibrarySave save,string packageDirectory) {
            return new LibraryOperation(check=>PublishNow(save,packageDirectory,check));
        }
        public LibraryOperation PublishModels(LibrarySave save,string packageDirectory) {
            if(String.IsNullOrEmpty(packageDirectory))throw new IOException("Saving models requires a complete asset package.");
            return new LibraryOperation(check=>PublishNow(save,packageDirectory,check,true));
        }
        string PublishNow(LibrarySave save,string packageDirectory,Action check,bool modelsOnly=false) {
                if(modelsOnly)return PublishModelsNow(save,packageDirectory,check);
                ValidateRecipe(save.RecipePath);
                var text=Read(save.RecipePath,8388608);var sha=HashText(text);var recipe=D(LibraryJson.Parse(text));var id=S(recipe["id"]);
                if(!System.Text.RegularExpressions.Regex.IsMatch(id,"^[A-Za-z0-9_-]{1,80}$"))throw new IOException("Invalid recipe identity.");
                using(Lock(check)){
                    var catalog=Catalog();var recipes=D(catalog["recipes"]);object prior;
                    if(recipes.TryGetValue(id,out prior)){if(S(D(prior)["sha256"])!=save.ExpectedHash)throw new IOException("Recipe changed since review. Save a copy or review its current revision.");}
                    else if(save.ExpectedHash.Length>0){if(!File.Exists(save.OriginalPath)||ContentObjects.Hash(save.OriginalPath)!=save.ExpectedHash)throw new IOException("Original recipe changed during adoption.");}
                    var package=String.IsNullOrEmpty(packageDirectory)?null:AdoptPackage(packageDirectory,check);
                    if(package!=null&&package!=sha)throw new IOException("Ready package and recipe differ.");
                    Ingest(save.RecipePath,sha,UTF8.GetByteCount(text),check);
                    Attachments(recipe,row=>Ingest(Child(save.Directory,S(row["file"])),S(row["sha256"]),N(row["bytes"]),check));
                    var modelRefs=package==null?new List<object>():RegisterModels(catalog,package);
                    if(modelsOnly&&modelRefs.Count==0)throw new IOException("No supported model source was captured.");
                    if(!modelsOnly)recipes[id]=M("sha256",sha,"package",package,"models",modelRefs,"modelRevisions",new List<object>(modelRefs));
                    var publishedView=PublishCatalog(catalog,check,Path.GetFileName(save.Directory));LastSummary="Saved complete library revision; unchanged model and texture bytes were reused.";
                    var result=package==null?Path.Combine(Root,"entries",sha,"entry.csrecipe.json"):Path.Combine(Root,"packs","user",package,"entry.csrecipe.json");
                    // Nothing after the catalog commit is allowed to turn success into retry.
                    try{NewText(Child(Root,"receipts/save-"+Guid.NewGuid().ToString("N")+".json"),LibraryJson.Write(M("recipe",id,"sha256",sha,"generation",Generation())));Discard(save);}catch{}return result;
                }
        }
        public LibraryOperation PublishMetadata(LibrarySave save,string previousHash) {
            return new LibraryOperation(check=>{
                var old=Package(previousHash);if(!Directory.Exists(old)){
                    var legacy=Path.Combine(Path.GetDirectoryName(save.OriginalPath),"Presets",previousHash);
                    if(File.Exists(Path.Combine(legacy,"cyrus.package.json"))){using(Lock(check)){if(AdoptPackage(legacy,check)!=previousHash)throw new IOException("Legacy ready package identity differs.");}}
                    else return PublishNow(save,"",check);
                }
                var original=D(ReadJson(Child(old,"cyrus.package.json"),16384));var graph=D(ReadJson(Child(old,"assets.json"),2097152));
                var text=Read(save.RecipePath,8388608);var sha=HashText(text);var recipe=D(LibraryJson.Parse(text));
                var ready=Child(save.Directory,"metadata-ready");Directory.CreateDirectory(ready);
                NewText(Child(ready,"entry.csrecipe.json"),text);ContentObjects.Link(Child(old,"assets.json"),Child(ready,"assets.json"));
                Attachments(recipe,row=>CopyImmutable(Child(save.Directory,S(row["file"])),Child(ready,S(row["file"])),S(row["sha256"]),N(row["bytes"])));
                foreach(var value in A(graph["files"])){check();var f=D(value);var relative="assets/"+S(f["sha256"])+"."+S(f["suffix"]);ContentObjects.Link(Child(old,relative),Child(ready,relative));}
                original["recipe"]=Descriptor("entry.csrecipe.json",sha,UTF8.GetByteCount(text));NewText(Child(ready,"cyrus.package.json"),LibraryJson.Write(original));
                return PublishNow(save,ready,check);
            });
        }
        List<object> RegisterModels(Dictionary<string,object> catalog,string package,bool persist=true) {
            var directory=Child(Root,"packs/user/"+package);var recipe=D(ReadJson(Child(directory,"entry.csrecipe.json"),8388608));var graph=D(ReadJson(Child(directory,"assets.json"),2097152));
            var sourceRoles=SourceRoles(recipe);
            var references=new List<object>();
            var redistribution=S(D(ReadJson(Child(directory,"cyrus.package.json"),16384))["redistribution"]);
            foreach(var raw in A(graph["nodes"])){var node=D(raw);if(!A(node["roles"]).Any(x=>sourceRoles.Contains(S(x))))continue;
                var build=BuildModel(graph,node);if(persist)StoreModel(build,redistribution);
                var models=D(catalog["models"]);if(!models.ContainsKey(build.Revision)){
                    object thumbnail=null,presentation;if(recipe.TryGetValue("presentation",out presentation)&&presentation!=null)thumbnail=D(presentation)["thumbnail"];
                    models[build.Revision]=M("name",S(node["name"]),"revision",build.Revision,"package",build.Revision,"node","model-1","thumbnail",thumbnail);
                }
                if(!references.Contains(build.Revision))references.Add(build.Revision);
            }return references;
        }
        public LibraryModel[] Models() {
            return D(Catalog()["models"]).Select(p=>Model(p.Key,D(p.Value))).ToArray();
        }
        LibraryModel Model(string id,Dictionary<string,object> d) {
            var item=new LibraryModel{Id=id,Name=S(d["name"]),Revision=S(d["revision"]),Package=ModelDirectory(S(d["package"])),Node=S(d["node"]),StoreID=Id};object image;
            if(d.TryGetValue("thumbnail",out image)&&image!=null){var t=D(image);item.ThumbnailHash=S(t["sha256"]);item.ThumbnailBytes=N(t["bytes"]);item.Thumbnail=Child(Root,"objects/"+item.ThumbnailHash);}return item;
        }
        public string Package(string digest){if(!LibraryLocation.IsHash(digest))throw new IOException("Invalid package identity.");return Child(Root,"packs/user/"+digest);}

        public string[] Collections(){return D(Catalog()["collections"]).Values.Select(x=>S(D(x)["name"])).OrderBy(x=>x,StringComparer.OrdinalIgnoreCase).ToArray();}
        public void AddToCollection(string name,string[] recipeIds,string[] modelIds) {
            name=(name??"").Trim();if(name.Length<1||name.Length>80||name.Any(c=>c<32))throw new IOException("Choose a collection name of 1–80 characters.");
            using(Lock()) {var c=Catalog();var id=HashText("collection:"+name);var groups=D(c["collections"]);object existing;
                var group=groups.TryGetValue(id,out existing)?D(existing):M("name",name,"recipes",new List<object>(),"models",new List<object>());
                foreach(var pair in new[]{new{kind="recipes",ids=recipeIds??new string[0]},new{kind="models",ids=modelIds??new string[0]}}){
                    foreach(var key in pair.ids){if(!D(c[pair.kind]).ContainsKey(key))throw new IOException("Selected item no longer exists.");if(!A(group[pair.kind]).Contains(key))A(group[pair.kind]).Add(key);}}
                groups[id]=group;PublishCatalog(c,null);
            }
        }
        public void RemoveCollection(string name) {using(Lock()){var c=Catalog();D(c["collections"]).Remove(HashText("collection:"+name));PublishCatalog(c,null);}}
        public void RemoveRecipe(string id) {using(Lock()){var c=Catalog();D(c["recipes"]).Remove(id);foreach(var g in D(c["collections"]).Values)A(D(g)["recipes"]).Remove(id);PublishCatalog(c,null);}}
        public void RemoveModel(string id) {using(Lock()){var c=Catalog();D(c["models"]).Remove(id);foreach(var g in D(c["collections"]).Values)A(D(g)["models"]).Remove(id);PublishCatalog(c,null);}}
        public string RecipeId(string path){return S(D(ReadJson(path,8388608))["id"]);}

        Dictionary<string,object> SelectCatalog(Dictionary<string,object> catalog,string collection) {
            if(String.IsNullOrEmpty(collection))return catalog;
            object value;if(!D(catalog["collections"]).TryGetValue(HashText("collection:"+collection),out value))throw new IOException("Collection no longer exists.");
            var group=D(value);var selected=Empty();foreach(var key in A(group["recipes"]))D(selected["recipes"])[S(key)]=D(catalog["recipes"])[S(key)];
            foreach(var key in A(group["models"]))D(selected["models"])[S(key)]=D(catalog["models"])[S(key)];D(selected["collections"])[HashText("collection:"+collection)]=group;return selected;
        }
        Dictionary<string,object> PackageFiles(string directory) {
            var manifest=D(ReadJson(Child(directory,"cyrus.package.json"),16384));var files=M();
            Action<Dictionary<string,object>> add=row=>{var name=S(row["file"]);Child(directory,name);object old;if(files.TryGetValue(name,out old)&&LibraryJson.Write(old)!=LibraryJson.Write(row))throw new IOException("Conflicting package dependency.");files[name]=row;};
            add(D(manifest["recipe"]));add(D(manifest["graph"]));var recipe=D(ReadJson(Child(directory,"entry.csrecipe.json"),8388608));var graph=D(ReadJson(Child(directory,"assets.json"),2097152));Attachments(recipe,add);
            foreach(var value in A(graph["files"])){var f=D(value);add(Descriptor("assets/"+S(f["sha256"])+"."+S(f["suffix"]),S(f["sha256"]),N(f["bytes"])));}return M("manifest",manifest,"files",files);
        }
        public LibraryOperation Export(string collection,string destination) {
            destination=LibraryLocation.Full(destination);var selected=SelectCatalog(Catalog(),collection); // Pin the exact immutable selection.
            return new LibraryOperation(check=>{
                if(File.Exists(destination))throw new IOException("Export destination exists. Choose a new archive filename.");
                if(D(selected["recipes"]).Count>100||D(selected["models"]).Count>1000)throw new IOException("Choose at most 100 recipes and 1,000 models per archive.");
                var objects=M();var packages=M();var modelPackages=M();var packageIds=new HashSet<string>(StringComparer.Ordinal);var modelIds=new HashSet<string>(StringComparer.Ordinal);
                Action<string,long> add=(sha,bytes)=>{if(!LibraryLocation.IsHash(sha)||bytes<1||bytes>MaxObject)throw new IOException("Invalid archive object.");object existing;if(objects.TryGetValue(sha,out existing)&&N(existing)!=bytes)throw new IOException("Archive identity collision.");objects[sha]=bytes;};
                foreach(var row in D(selected["recipes"]).Values){var r=D(row);var sha=S(r["sha256"]);var path=Child(Root,"objects/"+sha);add(sha,new FileInfo(path).Length);Attachments(D(ReadJson(path,8388608)),x=>add(S(x["sha256"]),N(x["bytes"])));if(r["package"]!=null)packageIds.Add(S(r["package"]));}
                // Recipe pins resolve from their saved package, even after its
                // model card was removed or advanced to a newer revision.
                foreach(var packageId in packageIds.ToArray()){var review=Empty();RegisterModels(review,packageId,false);foreach(var pair in D(review["models"])){
                    var revision=S(D(pair.Value)["revision"]);add(revision,new FileInfo(Child(Root,"objects/"+revision)).Length);
                    modelIds.Add(revision);
                    if(!D(selected["models"]).ContainsKey(pair.Key))D(selected["models"])[pair.Key]=pair.Value;
                }}
                foreach(var row in D(selected["models"]).Values){var m=D(row);modelIds.Add(S(m["revision"]));object thumbnail;if(m.TryGetValue("thumbnail",out thumbnail)&&thumbnail!=null){var t=D(thumbnail);add(S(t["sha256"]),N(t["bytes"]));}}
                foreach(var id in packageIds){check();var path=Package(id);validatePackage(path);var info=PackageFiles(path);packages[id]=info;foreach(var raw in D(info["files"]).Values){var row=D(raw);add(S(row["sha256"]),N(row["bytes"]));}}
                if(modelIds.Count>1000||D(selected["models"]).Count>1000)throw new IOException("Choose a selection with at most 1,000 model revisions.");
                foreach(var id in modelIds){check();var path=ModelDirectory(id);ValidateModel(path);var info=ModelFiles(path);modelPackages[id]=info;foreach(var raw in D(info["files"]).Values){var row=D(raw);add(S(row["sha256"]),N(row["bytes"]));}}
                if(objects.Count>4096||objects.Values.Sum(x=>N(x))>MaxBundle)throw new IOException("Archive exceeds 4,096 objects / 16 GiB expanded.");
                var root=M("format","cyrus.library-bundle","version",1,"catalog",selected,"packages",packages,"modelPackages",modelPackages,"objects",objects);
                selected.Remove("previous");
                var temp=destination+"."+Guid.NewGuid().ToString("N")+".tmp";
                try{using(var stream=new FileStream(temp,FileMode.CreateNew,FileAccess.ReadWrite,FileShare.None)){
                    using(var zip=new ZipArchive(stream,ZipArchiveMode.Create,true)){
                        var meta=zip.CreateEntry("library.json",CompressionLevel.Optimal);using(var output=meta.Open()){var bytes=UTF8.GetBytes(LibraryJson.Write(root));if(bytes.Length>33554432)throw new IOException("Archive metadata exceeds 32 MiB.");output.Write(bytes,0,bytes.Length);}
                        foreach(var p in objects){check();var source=Child(Root,"objects/"+p.Key);ContentObjects.Verify(source,p.Key,N(p.Value));var entry=zip.CreateEntry("objects/"+p.Key,CompressionLevel.Fastest);
                            using(var input=new FileStream(source,FileMode.Open,FileAccess.Read,FileShare.Read))using(var output=entry.Open())Copy(input,output,N(p.Value),check);}
                    }stream.Flush(true);}
                    VerifyArchive(temp,check);check();ContentObjects.AtomicNew(temp,destination);return destination;
                }finally{if(File.Exists(temp))File.Delete(temp);}
            });
        }
        static string Copy(Stream input,Stream output,long expected,Action check) {
            using(var hash=SHA256.Create()){var buffer=new byte[262144];long total=0;int count;
                while((count=input.Read(buffer,0,buffer.Length))>0){total=checked(total+count);if(total>expected)throw new IOException("Expanded archive object exceeds its declared bound.");hash.TransformBlock(buffer,0,count,null,0);if(output!=null)output.Write(buffer,0,count);if(check!=null)check();}
                hash.TransformFinalBlock(new byte[0],0,0);if(total!=expected)throw new IOException("Archive object length differs.");return BitConverter.ToString(hash.Hash).Replace("-","").ToLowerInvariant();}
        }
        static Dictionary<string,object> ArchiveManifest(ZipArchive zip) {
            if(zip.Entries.Count>4097)throw new IOException("Archive file count exceeds its bound.");var names=new HashSet<string>(StringComparer.OrdinalIgnoreCase);ZipArchiveEntry manifest=null;
            foreach(var e in zip.Entries){if(!names.Add(e.FullName)||((e.ExternalAttributes>>16)&0xF000)==0xA000)throw new IOException("Duplicate or linked archive entry.");if(e.FullName=="library.json"){manifest=e;continue;}
                if(!e.FullName.StartsWith("objects/",StringComparison.Ordinal)||!LibraryLocation.IsHash(e.FullName.Substring(8))||e.Length<1||e.Length>MaxObject)throw new IOException("Unsupported archive member.");}
            if(manifest==null||manifest.Length<1||manifest.Length>33554432)throw new IOException("Archive manifest is missing or oversized.");
            string text;using(var stream=manifest.Open())using(var output=new MemoryStream()){Copy(stream,output,manifest.Length,null);text=UTF8.GetString(output.ToArray());}
            var root=D(LibraryJson.Parse(text));if(S(root["format"])!="cyrus.library-bundle"||N(root["version"])!=1)throw new IOException("Unsupported library archive.");
            var objects=D(root["objects"]);if(objects.Count+1!=zip.Entries.Count||objects.Count>4096)throw new IOException("Archive object inventory differs.");long total=0;
            foreach(var p in objects){if(!LibraryLocation.IsHash(p.Key)||N(p.Value)<1||N(p.Value)>MaxObject)throw new IOException("Invalid archive object.");var entry=zip.GetEntry("objects/"+p.Key);if(entry==null||entry.Length!=N(p.Value))throw new IOException("Archive object is missing or changed.");total=checked(total+N(p.Value));if(total>MaxBundle)throw new IOException("Archive exceeds 16 GiB expanded.");}
            var c=D(root["catalog"]);if(D(c["recipes"]).Count>100||D(c["models"]).Count>1000||D(root["packages"]).Count>100||D(root["modelPackages"]).Count>1000)throw new IOException("Archive root count exceeds its bound.");return root;
        }
        static void VerifyArchive(string path,Action check){using(var input=new FileStream(path,FileMode.Open,FileAccess.Read,FileShare.Read))using(var zip=new ZipArchive(input,ZipArchiveMode.Read)){var m=ArchiveManifest(zip);foreach(var p in D(m["objects"])){using(var stream=zip.GetEntry("objects/"+p.Key).Open())if(Copy(stream,null,N(p.Value),check)!=p.Key)throw new IOException("Archive object hash differs.");}}}
        public LibraryOperation Import(string archive){return Import(archive,false);}
        public LibraryOperation Import(string archive,bool copyConflicts) {
            archive=LibraryLocation.Full(archive);
            return new LibraryOperation(check=>{
                var operation=Child(Root,"staging/import-"+Guid.NewGuid().ToString("N"));Directory.CreateDirectory(operation);MarkStage(operation);long added=0,reused=0;bool committed=false;
                try{using(var input=new FileStream(archive,FileMode.Open,FileAccess.Read,FileShare.Read))using(var zip=new ZipArchive(input,ZipArchiveMode.Read)){
                    var manifest=ArchiveManifest(zip);
                    using(Lock(check)){
                        foreach(var p in D(manifest["objects"])){check();var sha=p.Key;var bytes=N(p.Value);var blob=Child(Root,"objects/"+sha);var exists=File.Exists(blob);
                            if(exists){ContentObjects.Verify(blob,sha,bytes);using(var s=zip.GetEntry("objects/"+sha).Open())if(Copy(s,null,bytes,check)!=sha)throw new IOException("Archive hash mismatch.");reused+=bytes;}
                            else{var temp=Child(operation,sha);using(var s=zip.GetEntry("objects/"+sha).Open())using(var output=new FileStream(temp,FileMode.CreateNew,FileAccess.Write,FileShare.None)){if(Copy(s,output,bytes,check)!=sha)throw new IOException("Archive hash mismatch.");output.Flush(true);}Ingest(temp,sha,bytes,check);added+=bytes;}}
                        foreach(var p in D(manifest["packages"])){if(!LibraryLocation.IsHash(p.Key))throw new IOException("Invalid imported package identity.");var info=D(p.Value);var staging=Child(operation,"p-"+p.Key.Substring(0,16));Directory.CreateDirectory(staging);
                            foreach(var raw in D(info["files"]).Values){var row=D(raw);var sha=S(row["sha256"]);object declared;if(!D(manifest["objects"]).TryGetValue(sha,out declared)||N(declared)!=N(row["bytes"]))throw new IOException("Package dependency is undeclared.");LinkObject(Child(staging,S(row["file"])),sha,N(row["bytes"]));}
                            NewText(Child(staging,"cyrus.package.json"),LibraryJson.Write(info["manifest"]));if(AdoptPackage(staging,check)!=p.Key)throw new IOException("Imported package identity differs.");}
                        foreach(var p in D(manifest["modelPackages"])){if(!LibraryLocation.IsHash(p.Key))throw new IOException("Invalid model package identity.");var info=D(p.Value);var staging=Child(operation,"m-"+p.Key.Substring(0,16));Directory.CreateDirectory(staging);
                            foreach(var raw in D(info["files"]).Values){var row=D(raw);var sha=S(row["sha256"]);object declared;if(!D(manifest["objects"]).TryGetValue(sha,out declared)||N(declared)!=N(row["bytes"]))throw new IOException("Model dependency is undeclared.");LinkObject(Child(staging,S(row["file"])),sha,N(row["bytes"]));}
                            NewText(Child(staging,"cyrus.model.json"),LibraryJson.Write(info["manifest"]));if(AdoptModel(staging,check)!=p.Key)throw new IOException("Imported model identity differs.");}
                        var current=Catalog();var incoming=D(manifest["catalog"]);
                        var copiedRecipes=new Dictionary<string,string>(StringComparer.Ordinal);
                        foreach(var pair in D(incoming["recipes"]).ToArray()){
                            object prior;if(!D(current["recipes"]).TryGetValue(pair.Key,out prior)||S(D(prior)["sha256"])==S(D(pair.Value)["sha256"]))continue;
                            if(!copyConflicts)throw new IOException("A recipe has a different local revision. Choose Import as copies to preserve both.");
                            var row=D(pair.Value);var original=S(row["sha256"]);var document=D(ReadJson(Child(Root,"objects/"+original),8388608));
                            // Stable derivation makes repeat conflict-copy import idempotent.
                            var id="copy-"+HashText(pair.Key+":"+original).Substring(0,40);document["id"]=id;
                            var text=LibraryJson.Write(document);var sha=PutText(text);ValidateRecipe(Child(Root,"objects/"+sha));
                            if(row["package"]!=null){var old=Package(original);var stage=Child(operation,"c-"+Guid.NewGuid().ToString("N").Substring(0,12));Directory.CreateDirectory(stage);
                                var info=PackageFiles(old);foreach(var raw in D(info["files"]).Values){var file=D(raw);if(S(file["file"])!="entry.csrecipe.json")LinkObject(Child(stage,S(file["file"])),S(file["sha256"]),N(file["bytes"]));}
                                LinkObject(Child(stage,"entry.csrecipe.json"),sha,UTF8.GetByteCount(text));var packageManifest=D(info["manifest"]);packageManifest["recipe"]=Descriptor("entry.csrecipe.json",sha,UTF8.GetByteCount(text));NewText(Child(stage,"cyrus.package.json"),LibraryJson.Write(packageManifest));AdoptPackage(stage,check);row["package"]=sha;
                            }
                            row["sha256"]=sha;D(incoming["recipes"]).Remove(pair.Key);D(incoming["recipes"])[id]=row;copiedRecipes[pair.Key]=id;
                            // These newly derived objects are verified locally rather than transport members.
                            D(manifest["objects"])[sha]=UTF8.GetByteCount(text);if(row["package"]!=null)D(manifest["packages"])[sha]=PackageFiles(Package(sha));
                        }
                        foreach(var group in D(incoming["collections"]).Values){var values=A(D(group)["recipes"]);for(int i=0;i<values.Count;i++){string replacement;if(copiedRecipes.TryGetValue(S(values[i]),out replacement))values[i]=replacement;}}
                        foreach(var kind in new[]{"recipes","models","collections"})foreach(var p in D(incoming[kind])){
                            if(!System.Text.RegularExpressions.Regex.IsMatch(p.Key,"^[A-Za-z0-9_-]{1,80}$"))throw new IOException("Invalid imported catalog identity.");object previous;
                            if(D(current[kind]).TryGetValue(p.Key,out previous)){
                                if(kind=="models"&&S(D(previous)["revision"])==S(D(p.Value)["revision"]))continue;
                                if(kind=="recipes"&&S(D(previous)["sha256"])==S(D(p.Value)["sha256"]))continue;
                                if(kind=="collections"&&S(D(previous)["name"])==S(D(p.Value)["name"])){
                                    foreach(var field in new[]{"recipes","models"})foreach(var id in A(D(p.Value)[field]))if(!A(D(previous)[field]).Contains(id))A(D(previous)[field]).Add(id);continue;
                                }
                                if(LibraryJson.Write(previous)!=LibraryJson.Write(p.Value))throw new IOException("An existing model has a different revision. Import into a separate store or resolve its model revision before merging.");
                            }D(current[kind])[p.Key]=p.Value;}
                        foreach(var pair in D(incoming["recipes"])){var row=D(pair.Value);var sha=S(row["sha256"]);if(!D(manifest["objects"]).ContainsKey(sha))throw new IOException("Imported recipe is undeclared.");var recipe=D(ReadJson(Child(Root,"objects/"+sha),8388608));ValidateRecipe(Child(Root,"objects/"+sha));if(S(recipe["id"])!=pair.Key)throw new IOException("Imported recipe identity differs.");Attachments(recipe,x=>ContentObjects.Verify(Child(Root,"objects/"+S(x["sha256"])),S(x["sha256"]),N(x["bytes"])));if(row["package"]!=null&&(S(row["package"])!=sha||!D(manifest["packages"]).ContainsKey(sha)))throw new IOException("Imported recipe/package mismatch.");
                            var exact=row["package"]==null?new List<object>():RegisterModels(Empty(),sha,false);object pins;
                            if(row.TryGetValue("modelRevisions",out pins)&&!new HashSet<string>(A(pins).Select(S)).SetEquals(exact.Select(S)))throw new IOException("Recipe model revision pins differ from its immutable graph.");
                            foreach(var revision in exact.Select(S))if(!D(manifest["objects"]).ContainsKey(revision)||!D(manifest["modelPackages"]).ContainsKey(revision))throw new IOException("A pinned model definition is undeclared.");row["modelRevisions"]=exact;
                        }
                        foreach(var raw in D(incoming["models"]).Values){var row=D(raw);var revision=S(row["revision"]);if(!LibraryLocation.IsHash(revision)||S(row["package"])!=revision||S(row["node"])!="model-1"||!D(manifest["objects"]).ContainsKey(revision)||!D(manifest["modelPackages"]).ContainsKey(revision))throw new IOException("Imported model dependency is undeclared.");
                            var definition=D(ReadJson(Child(Root,"objects/"+revision),2097152));if(S(definition["format"])!="cyrus.model-definition"||N(definition["version"])!=1)throw new IOException("Unsupported model definition.");
                            ValidateModel(ModelDirectory(revision));object thumbnail;if(row.TryGetValue("thumbnail",out thumbnail)&&thumbnail!=null){var t=D(thumbnail);ContentObjects.Verify(Child(Root,"objects/"+S(t["sha256"])),S(t["sha256"]),N(t["bytes"]));}}
                        foreach(var group in D(incoming["collections"]).Values){foreach(var id in A(D(group)["recipes"]))if(!D(current["recipes"]).ContainsKey(S(id)))throw new IOException("Collection recipe is missing.");foreach(var id in A(D(group)["models"]))if(!D(current["models"]).ContainsKey(S(id)))throw new IOException("Collection model is missing.");}
                        PublishCatalog(current,check);committed=true;LastSummary="Imported library: "+D(incoming["recipes"]).Count+" recipes; "+added+" new bytes; "+reused+" bytes reused.";return LastSummary;
                    }
                }}finally{try{if(Directory.Exists(operation))Directory.Delete(operation,true);}catch{if(!committed)throw;}}
            });
        }
    }
}
