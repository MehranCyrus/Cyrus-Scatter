#nullable disable
using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;

namespace Cyrus.Content {
    public sealed partial class SharedLibrary {
        sealed class ModelBuild {
            public string Revision,Definition,Graph;
            public readonly Dictionary<string,string> Definitions=new Dictionary<string,string>(StringComparer.Ordinal);
            public readonly Dictionary<string,object> Files=new Dictionary<string,object>(StringComparer.Ordinal);
        }
        ModelBuild BuildModel(Dictionary<string,object> graph,Dictionary<string,object> node) {
            var build=new ModelBuild();var lookup=new Dictionary<string,object>(StringComparer.Ordinal);var categories=new Dictionary<string,string>(StringComparer.Ordinal);
            foreach(var category in new[]{"files","meshes","materials","maps"})foreach(var raw in A(graph[category])){var id=S(D(raw)["id"]);lookup.Add(id,raw);categories.Add(id,category);}
            var resolved=new Dictionary<string,string>(StringComparer.Ordinal);var required=new Dictionary<string,bool>(StringComparer.Ordinal);var visiting=new HashSet<string>(StringComparer.Ordinal);
            var records=new Dictionary<string,Dictionary<string,object>>(StringComparer.Ordinal);bool legacy=false,extended=false;object profile=null;graph.TryGetValue("rendererProfile",out profile);
            var ordinals=new Dictionary<string,int>{{"meshes",0},{"materials",0},{"maps",0}};
            Func<string,int,string> resolve=null;
            resolve=(id,depth)=>{
                if(depth>32)throw new IOException("Model definition dependency depth exceeds its bound.");string ready;if(resolved.TryGetValue(id,out ready))return ready;
                if(!lookup.ContainsKey(id)||!visiting.Add(id))throw new IOException("Model definition has an unresolved or cyclic reference.");
                var input=D(lookup[id]);var category=categories[id];bool renderer=false;
                if(category=="files"){
                    var file=D(LibraryJson.Parse(LibraryJson.Write(input)));var sha=S(file["sha256"]);if(!LibraryLocation.IsHash(sha))throw new IOException("Invalid model payload identity.");
                    if(S(file["suffix"])=="jpg")file["suffix"]="jpeg";file["id"]="f-"+sha;
                    object old;if(build.Files.TryGetValue(sha,out old)&&LibraryJson.Write(old)!=LibraryJson.Write(file))throw new IOException("Conflicting model payload descriptors.");
                    build.Files[sha]=file;ready="f-"+sha;required[id]=false;
                }else{
                    var data=M();Func<object,int,object> rewrite=null;
                    rewrite=(value,level)=>{
                        if(level>64)throw new IOException("Model definition nesting exceeds its bound.");
                        if(value is string&&lookup.ContainsKey((string)value)){var reference=resolve((string)value,depth+1);renderer|=required[(string)value];return reference;}
                        var dictionary=value as Dictionary<string,object>;if(dictionary!=null){var result=M();foreach(var pair in dictionary.OrderBy(p=>p.Key,StringComparer.Ordinal))result[pair.Key]=rewrite(pair.Value,level+1);return result;}
                        var array=value as List<object>;return array==null?value:array.Select(v=>rewrite(v,level+1)).ToList();
                    };
                    foreach(var pair in input.OrderBy(p=>p.Key,StringComparer.Ordinal))if(pair.Key!="id"&&pair.Key!="name"&&pair.Key!="roles")data[pair.Key]=rewrite(pair.Value,0);
                    var kind=category=="meshes"?"mesh":S(input["kind"]);
                    renderer|=category!="meshes"&&kind!="bitmap"&&kind!="standard-blinn";
                    if(category=="maps"&&kind=="bitmap"){
                        object color;if(!input.TryGetValue("color",out color)||!D(color).ContainsKey("inputGamma"))legacy=true;
                        object size;if(input.TryGetValue("size",out size)&&A(size).Any(v=>N(v)>4096))extended=true;
                    }
                    if(renderer&&profile==null)throw new IOException("A model shader has no supported renderer profile.");
                    var type=category=="meshes"?"mesh":category=="materials"?"material":"map";
                    // Definitions share values; graph occurrences preserve the
                    // author's distinct-vs-instanced shader object topology.
                    Func<object,object> values=null;values=value=>{
                        if(value is string&&records.ContainsKey((string)value))return ((string)value).Substring(0,66);
                        var dictionary=value as Dictionary<string,object>;if(dictionary!=null){var result=M();foreach(var pair in dictionary)result[pair.Key]=values(pair.Value);return result;}
                        var array=value as List<object>;return array==null?value:array.Select(values).ToList();
                    };
                    var definition=LibraryJson.Write(M("format","cyrus."+type+"-definition","version",1,"profile",renderer?profile:null,"data",values(data)));
                    var sha=HashText(definition);build.Definitions[sha]=definition;ready=(type=="mesh"?"g-":type=="material"?"m-":"x-")+sha+"-"+(++ordinals[category]);
                    var record=D(LibraryJson.Parse(LibraryJson.Write(data)));record["id"]=ready;
                    if(category!="meshes")record["name"]=kind;if(category=="maps")record["roles"]=new List<object>();
                    records[ready]=record;required[id]=renderer;
                }
                visiting.Remove(id);resolved[id]=ready;return ready;
            };
            var mesh=resolve(S(node["mesh"]),0);string material=null;if(node["material"]!=null)material=resolve(S(node["material"]),0);
            var rendererNeeded=(material!=null&&required[S(node["material"])])||extended;
            if(rendererNeeded&&profile==null)throw new IOException("Extended model image admission requires its supported adapter profile.");
            int version=rendererNeeded?3:legacy?2:4;
            object wireColor;node.TryGetValue("wireColor",out wireColor);if(wireColor==null)wireColor=new List<object>{128L,128L,128L};
            var modelGraph=M("format","cyrus.library-assets","version",version,"nodes",new List<object>{M("id","model-1","name","Model","mesh",mesh,"material",material,"transform",new List<object>{1L,0L,0L,0L,1L,0L,0L,0L,1L,0L,0L,0L},"wireColor",wireColor,"roles",new List<object>{"model-role"})},
                "meshes",records.Where(p=>p.Key.StartsWith("g-",StringComparison.Ordinal)).OrderBy(p=>p.Key,StringComparer.Ordinal).Select(p=>(object)p.Value).ToList(),
                "materials",records.Where(p=>p.Key.StartsWith("m-",StringComparison.Ordinal)).OrderBy(p=>p.Key,StringComparer.Ordinal).Select(p=>(object)p.Value).ToList(),
                "maps",records.Where(p=>p.Key.StartsWith("x-",StringComparison.Ordinal)).OrderBy(p=>p.Key,StringComparer.Ordinal).Select(p=>(object)p.Value).ToList(),
                "files",build.Files.OrderBy(p=>p.Key,StringComparer.Ordinal).Select(p=>p.Value).ToList(),"splines",new List<object>(),"externalRoles",new List<object>());
            if(version==3){modelGraph["rendererProfile"]=profile;modelGraph["resourceProfile"]="plant-assets-v1";}
            if(version==4)modelGraph["resourceProfile"]="shared-static-v1";
            build.Graph=LibraryJson.Write(modelGraph);if(UTF8.GetByteCount(build.Graph)>2097152)throw new IOException("Model graph exceeds 2 MiB.");
            build.Definition=LibraryJson.Write(M("format","cyrus.model-definition","version",1,"mesh",mesh.Substring(2,64),"material",material==null?null:material.Substring(2,64),"rendererProfile",rendererNeeded?profile:null,"graph",HashText(build.Graph)));
            build.Revision=HashText(build.Definition);return build;
        }
        string ModelDirectory(string revision){if(!LibraryLocation.IsHash(revision))throw new IOException("Invalid model revision.");return Child(Root,"models/"+revision);}
        static HashSet<string> SourceRoles(Dictionary<string,object> recipe){var result=new HashSet<string>(StringComparer.Ordinal);foreach(var raw in A(recipe["roles"])){var role=D(raw);var purposes=A(role["purposes"]);if(purposes.Count>0&&purposes.All(x=>S(x)=="sources"||S(x)=="procSourceNodes"))result.Add(S(role["id"]));}return result;}
        void RegisterModel(Dictionary<string,object> catalog,ModelBuild build,Dictionary<string,object> node,object thumbnail){
            var models=D(catalog["models"]);if(!models.ContainsKey(build.Revision))models[build.Revision]=M("name",S(node["name"]),"revision",build.Revision,"package",build.Revision,"node","model-1","thumbnail",thumbnail);
        }
        string PublishModelsNow(LibrarySave save,string directory,Action check){
            ValidateRecipe(save.RecipePath);validatePackage(directory);
            var manifest=D(ReadJson(Child(directory,"cyrus.package.json"),16384));if(S(D(manifest["recipe"])["sha256"])!=ContentObjects.Hash(save.RecipePath))throw new IOException("Model capture and recipe differ.");
            var recipe=D(ReadJson(Child(directory,"entry.csrecipe.json"),8388608));var graph=D(ReadJson(Child(directory,"assets.json"),2097152));if(A(graph["externalRoles"]).Count>0)throw new IOException("Model capture has unsupported external dependencies.");
            using(Lock(check)){
                var catalog=Catalog();var roles=SourceRoles(recipe);int count=0;object thumbnail=null,presentation;if(recipe.TryGetValue("presentation",out presentation)&&presentation!=null)thumbnail=D(presentation)["thumbnail"];
                if(thumbnail!=null){var t=D(thumbnail);Ingest(Child(directory,S(t["file"])),S(t["sha256"]),N(t["bytes"]),check);}
                foreach(var raw in A(graph["nodes"])){check();var node=D(raw);if(!A(node["roles"]).Any(x=>roles.Contains(S(x))))continue;var build=BuildModel(graph,node);
                    foreach(var fileRaw in build.Files.Values){var file=D(fileRaw);var sha=S(file["sha256"]);var source=A(graph["files"]).Select(D).First(x=>S(x["sha256"])==sha);Ingest(Child(directory,"assets/"+sha+"."+S(source["suffix"])),sha,N(file["bytes"]),check);}
                    StoreModel(build,S(manifest["redistribution"]));RegisterModel(catalog,build,node,thumbnail);count++;
                }
                if(count==0)throw new IOException("No supported model was captured.");PublishCatalog(catalog,check,Path.GetFileName(save.Directory));try{Discard(save);}catch{}
                return "Saved "+count+" model sources. Existing geometry, textures and shader definitions were reused.";
            }
        }
        void ValidateModel(string directory) {
            if(validatePackage.Method==((Action<string>)NativeValidate).Method)NativeCheck(directory,"CyrusLibraryVerifyModelV1");
            else{
                // Managed transaction fixtures inject their own byte boundary;
                // real mesh/shader acceptance always uses the native validator.
                var info=ModelFiles(directory);foreach(var raw in D(info["files"]).Values){var row=D(raw);ContentObjects.Verify(Child(directory,S(row["file"])),S(row["sha256"]),N(row["bytes"]));}
            }
        }
        Dictionary<string,object> ModelFiles(string directory) {
            var manifest=D(ReadJson(Child(directory,"cyrus.model.json"),262144));
            if(S(manifest["format"])!="cyrus.model-package"||N(manifest["version"])!=1)throw new IOException("Unsupported model package.");
            var files=M();Action<Dictionary<string,object>> add=row=>{var relative=S(row["file"]);Child(directory,relative);object old;if(files.TryGetValue(relative,out old)&&LibraryJson.Write(old)!=LibraryJson.Write(row))throw new IOException("Conflicting model dependency.");files[relative]=row;};
            add(D(manifest["definition"]));add(D(manifest["graph"]));foreach(var raw in A(manifest["definitions"]))add(D(raw));
            var graph=D(ReadJson(Child(directory,"assets.json"),2097152));foreach(var raw in A(graph["files"])){var f=D(raw);add(Descriptor("assets/"+S(f["sha256"])+"."+S(f["suffix"]),S(f["sha256"]),N(f["bytes"])));}
            if(files.Count>1024)throw new IOException("Model dependency count exceeds its bound.");return M("manifest",manifest,"files",files);
        }
        void StoreModel(ModelBuild build,string redistribution) {
            foreach(var definition in build.Definitions.Values)PutText(definition);PutText(build.Graph);PutText(build.Definition);
            var target=ModelDirectory(build.Revision);
            if(Directory.Exists(target)){ValidateModel(target);return;}
            var staging=Child(Root,"staging/model-"+Guid.NewGuid().ToString("N"));Directory.CreateDirectory(staging);MarkStage(staging);
            try{
                var definitions=new List<object>();foreach(var pair in build.Definitions.OrderBy(p=>p.Key,StringComparer.Ordinal)){
                    var relative="definitions/"+pair.Key+".json";var bytes=UTF8.GetByteCount(pair.Value);LinkObject(Child(staging,relative),pair.Key,bytes);definitions.Add(Descriptor(relative,pair.Key,bytes));
                }
                var graphHash=HashText(build.Graph);LinkObject(Child(staging,"assets.json"),graphHash,UTF8.GetByteCount(build.Graph));LinkObject(Child(staging,"model.json"),build.Revision,UTF8.GetByteCount(build.Definition));
                foreach(var raw in build.Files.Values){var file=D(raw);var sha=S(file["sha256"]);var bytes=N(file["bytes"]);LinkObject(Child(staging,"assets/"+sha+"."+S(file["suffix"])),sha,bytes);
                    if(S(file["kind"])=="bitmap")LinkObject(Child(Root,"resolved/"+sha+"."+S(file["suffix"])),sha,bytes);
                }
                NewText(Child(staging,"cyrus.model.json"),LibraryJson.Write(M("format","cyrus.model-package","version",1,"definition",Descriptor("model.json",build.Revision,UTF8.GetByteCount(build.Definition)),"graph",Descriptor("assets.json",graphHash,UTF8.GetByteCount(build.Graph)),"definitions",definitions,"redistribution",redistribution)));
                ValidateModel(staging);File.Delete(Child(staging,".cyrus-operation.json"));Directory.CreateDirectory(Path.GetDirectoryName(target));Directory.Move(staging,target);
            }finally{if(Directory.Exists(staging))Directory.Delete(staging,true);}
        }
        string AdoptModel(string directory,Action check) {
            ValidateModel(directory);var info=ModelFiles(directory);var manifest=D(info["manifest"]);var revision=S(D(manifest["definition"])["sha256"]);
            long bytes=0;foreach(var raw in D(info["files"]).Values){check();var file=D(raw);bytes=checked(bytes+N(file["bytes"]));if(bytes>648L*1024*1024)throw new IOException("Model exceeds its bounded payload and metadata admission.");Ingest(Child(directory,S(file["file"])),S(file["sha256"]),N(file["bytes"]),check);}
            var target=ModelDirectory(revision);if(Directory.Exists(target)){ValidateModel(target);return revision;}
            var staging=Child(Root,"staging/model-"+Guid.NewGuid().ToString("N"));Directory.CreateDirectory(staging);MarkStage(staging);
            try{foreach(var raw in D(info["files"]).Values){var file=D(raw);LinkObject(Child(staging,S(file["file"])),S(file["sha256"]),N(file["bytes"]));}
                NewText(Child(staging,"cyrus.model.json"),LibraryJson.Write(manifest));ValidateModel(staging);File.Delete(Child(staging,".cyrus-operation.json"));Directory.CreateDirectory(Path.GetDirectoryName(target));Directory.Move(staging,target);
                var graph=D(ReadJson(Child(target,"assets.json"),2097152));foreach(var raw in A(graph["files"])){var file=D(raw);if(S(file["kind"])=="bitmap")LinkObject(Child(Root,"resolved/"+S(file["sha256"])+"."+S(file["suffix"])),S(file["sha256"]),N(file["bytes"]));}
            }finally{if(Directory.Exists(staging))Directory.Delete(staging,true);}return revision;
        }
    }
}
