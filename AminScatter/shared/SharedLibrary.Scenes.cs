#nullable disable
using System;
using System.IO;
using System.Collections.Generic;

namespace Cyrus.Content {
    public sealed partial class SharedLibrary {
        static bool IsScene(Dictionary<string,object> d){object format;return d.TryGetValue("format",out format)&&S(format)=="cyrus.scene-preset";}
        public int ScenePresetVersion {get{return 1;}}
        public LibrarySave BeginSceneSave(string original,string expected){
            var save=BeginSave("","","entry.csrecipe.json");
            try{if(!String.IsNullOrEmpty(expected)){
                ContentObjects.Verify(original,expected,new FileInfo(original).Length);var d=D(ReadJson(original,8388608));if(!IsScene(d))throw new IOException("Save a scene preset as a new copy.");
                save.ExpectedHash=expected;save.OriginalPath=original;NewText(save.RecipePath,LibraryJson.Write(d));
            }return save;}catch{Discard(save);throw;}
        }
        // Max has already serialized the owned save stage. Only bytes and copied
        // asset metadata enter this worker; no Max wrappers or callbacks escape.
        public LibraryOperation PublishScene(LibrarySave save,string name,string metadata,string layers,
                                            double metersPerUnit,int nodeCount,string assetMetadata,string image) {
            return new LibraryOperation(check=>{
                try {
                    var captured=A(LibraryJson.Parse(assetMetadata));if(captured.Count>1024)throw new IOException("Scene presets support at most 1,024 collected assets.");
                    var files=new Dictionary<string,Dictionary<string,object>>(StringComparer.OrdinalIgnoreCase);
                    var assets=new List<object>();var ids=new HashSet<string>(StringComparer.Ordinal);long total=0;
                    foreach(var raw in captured){
                        check();var item=D(raw);var id=S(item["id"]);if(!ids.Add(id))throw new IOException("Duplicate captured asset identity.");
                        var source=LibraryLocation.Full(S(item["path"]));Dictionary<string,object> payload;
                        if(!files.TryGetValue(source,out payload)){
                            var info=new FileInfo(source);if(!info.Exists||info.Length<1||info.Length>MaxObject)throw new IOException("Missing or oversized scene asset: "+Path.GetFileName(source));
                            var suffix=Path.GetExtension(source).ToLowerInvariant();if(suffix.Length<2||suffix.Length>17||!System.Text.RegularExpressions.Regex.IsMatch(suffix,"^\\.[a-z0-9]+$"))throw new IOException("Unsupported asset filename: "+Path.GetFileName(source));
                            var sha=ContentObjects.Hash(source);payload=Descriptor("assets/"+sha+suffix,sha,info.Length);total=checked(total+info.Length);if(total>MaxBundle)throw new IOException("Scene preset exceeds 16 GiB.");
                            Ingest(source,sha,info.Length,check);LinkObject(Child(save.Directory,S(payload["file"])),sha,info.Length);files.Add(source,payload);
                        }
                        assets.Add(M("id",id,"type",S(item["type"]),"payload",payload));
                    }
                    var scene=Child(save.Directory,"scene.max");var sceneBytes=new FileInfo(scene).Length;if(sceneBytes<1||sceneBytes>MaxObject||sceneBytes+total>MaxBundle)throw new IOException("Scene preset exceeds its file storage bound.");
                    var idValue=Guid.NewGuid().ToString("N");long revision=1;
                    if(save.ExpectedHash.Length>0){var prior=D(ReadJson(save.RecipePath,8388608));if(!IsScene(prior))throw new IOException("Save a scene preset as a new copy.");idValue=S(prior["id"]);revision=checked(N(prior["revision"])+1);File.Delete(save.RecipePath);}
                    object thumbnail=null;
                    if(!String.IsNullOrEmpty(image)){
                        var bytes=new FileInfo(image).Length;if(bytes<1||bytes>2*1024*1024)throw new IOException("Thumbnail exceeds 2 MiB.");
                        var sha=ContentObjects.Hash(image);thumbnail=Descriptor("thumbnail-"+sha+".png",sha,bytes);CopyImmutable(image,Child(save.Directory,S(D(thumbnail)["file"])),sha,bytes);
                    }
                    var document=M("format","cyrus.scene-preset","version",1,"id",idValue,"revision",revision,"name",name,
                        "maxYear",2027,"scatterVersion","0.87.5.5","metersPerUnit",metersPerUnit,"nodeCount",nodeCount,
                        "layers",A(LibraryJson.Parse(layers)),"scene",Descriptor("scene.max",ContentObjects.Hash(scene),sceneBytes),"assets",assets,
                        "presentation",M("metadata",D(LibraryJson.Parse(metadata)),"thumbnail",thumbnail,"capture",null));
                    NewText(save.RecipePath,LibraryJson.Write(document));ValidateRecipe(save.RecipePath);
                    return PublishNow(save,"",check);
                }catch{try{Discard(save);}catch{}throw;}
            });
        }
        // Verify all payloads before Max is allowed to read a staged scene. This
        // is a real copy: updating its Max asset stream must not mutate hardlinks.
        public LibraryOperation PrepareScene(string entry,string expected) {
            return new LibraryOperation(check=>{
                ContentObjects.Verify(entry,expected,new FileInfo(entry).Length);ValidateRecipe(entry);var d=D(ReadJson(entry,8388608));if(!IsScene(d))throw new IOException("Select a scene preset.");
                var directory=Path.GetDirectoryName(LibraryLocation.Full(entry));
                Attachments(d,p=>{check();ContentObjects.Verify(Child(directory,S(p["file"])),S(p["sha256"]),N(p["bytes"]));});
                var stage=Child(Root,"staging/scene-load-"+Guid.NewGuid().ToString("N"));Directory.CreateDirectory(stage);
                try{var copy=Child(stage,"scene.max");File.Copy(Child(directory,"scene.max"),copy,false);ContentObjects.Verify(copy,S(D(d["scene"])["sha256"]),N(D(d["scene"])["bytes"]));check();return copy;}
                catch{Directory.Delete(stage,true);throw;}
            });
        }
        public LibraryOperation ReviseSceneDetails(LibrarySave save,string name,string metadata){
            return new LibraryOperation(check=>{
                try{var d=D(ReadJson(save.RecipePath,8388608));if(!IsScene(d))throw new IOException("Select a scene preset.");d["name"]=name;d["revision"]=checked(N(d["revision"])+1);D(d["presentation"])["metadata"]=D(LibraryJson.Parse(metadata));
                    File.Delete(save.RecipePath);NewText(save.RecipePath,LibraryJson.Write(d));return PublishNow(save,"",check);
                }catch{try{Discard(save);}catch{}throw;}
            });
        }
        public void DiscardSceneLoad(string file){
            var full=LibraryLocation.Full(file);var directory=Path.GetDirectoryName(full);
            if(Path.GetFileName(full)!="scene.max"||Path.GetDirectoryName(directory)!=Child(Root,"staging")||!Path.GetFileName(directory).StartsWith("scene-load-",StringComparison.Ordinal))throw new IOException("Scene load staging ownership differs.");
            if(Directory.Exists(directory))Directory.Delete(directory,true);
        }
        public void CancelSceneLoad(LibraryOperation operation){operation.Cancel();operation.Finally(done=>{if(done.State=="complete"&&!String.IsNullOrEmpty(done.Result))DiscardSceneLoad(done.Result);});}
    }
}
