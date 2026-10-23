// Filesystem-only fixtures. Synthetic native files must never be loaded by Max.
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Threading;
using Cyrus.Setup;

static class InstallerRepairChecks {
    static string work;
    static int checks;
    // Exact public startup/macro bytes from the archived Max 2027 .81.6 MZP.
    static readonly byte[] LegacyStartup=Convert.FromBase64String("LS0gUmVnaXN0ZXIgdGhlIHBlcnNpc3RlbnQgc2NlbmUgY2xhc3MgYmVmb3JlIG9wZW5pbmcgdXNlciBzY2VuZXMuCmZpbGVJbiAocGF0aENvbmZpZy5hcHBlbmRQYXRoIChnZXREaXIgI3VzZXJTY3JpcHRzKSAiQ3lydXNTY2F0dGVyL0N5cnVzU2NhdHRlci5tcyIpCg==");
    static readonly byte[] LegacyMacro=Convert.FromBase64String("bWFjcm9TY3JpcHQgQ3lydXNTY2F0dGVyQ3JlYXRlIGNhdGVnb3J5OiJDeXJ1cyIgdG9vbHRpcDoiQ3JlYXRlIEN5cnVzIFNjYXR0ZXIiIGJ1dHRvblRleHQ6IkN5cnVzIFNjYXR0ZXIiICgKICAgIGdsb2JhbCBDeXJ1c1NjYXR0ZXJPYmplY3QKICAgIG9uIGV4ZWN1dGUgZG8gKAogICAgICAgIGlmIEN5cnVzU2NhdHRlck9iamVjdD09dW5kZWZpbmVkIHRoZW4gbWVzc2FnZUJveCAiUmVzdGFydCAzZHMgTWF4IGFmdGVyIGluc3RhbGxpbmcgQ3lydXMgU2NhdHRlciAwLjgxLjYuIiB0aXRsZToiQ3lydXMgU2NhdHRlciIKICAgICAgICBlbHNlIHN0YXJ0T2JqZWN0Q3JlYXRpb24gQ3lydXNTY2F0dGVyT2JqZWN0CiAgICApCikK");
    static void Check(bool value,string label){if(!value)throw new Exception(label);++checks;Console.WriteLine("PASS "+label);}
    static bool Reject(Action action){try{action();return false;}catch(IOException){return true;}}
    static InstallPaths Paths(string name) {
        string root=Path.Combine(work,name);
        return new InstallPaths(Path.Combine(root,"s"),Path.Combine(root,"u"),Path.Combine(root,"m"),root,Path.Combine(work,"runtime"));
    }
    static string Root(InstallPaths p,string product){return Path.Combine(p.Scripts,product=="scatter"?"CyrusScatter":"CyrusSurfaceAnalyzer");}
    static string[] Targets(InstallPaths p,string product){return product=="scatter"?new[]{Path.Combine(p.Startup,"CyrusScatterStartup.ms"),Path.Combine(p.Macros,"CyrusScatter.mcr"),Path.Combine(Root(p,product),"installed.txt"),Path.Combine(p.Profile,"Plugin.UserSettings.ini")}:new[]{Path.Combine(p.Startup,"CyrusSurfaceAnalyzerStartup.ms"),Path.Combine(Root(p,product),"installed.txt"),Path.Combine(p.Profile,"Plugin.UserSettings.ini")};}
    static string Snapshot(InstallPaths p,string product){return String.Join("|",Array.ConvertAll(Targets(p,product),x=>File.Exists(x)?Convert.ToBase64String(File.ReadAllBytes(x)):"ABSENT"));}
    static string Payload(string product){return Path.Combine(work,"payload-"+product);}
    static void CreatePayloads() {
        string folder=Payload("scatter");Directory.CreateDirectory(folder);
        string[] names={"AminScatter.dlx","CyrusBrush.dlx","CyrusBrushStorage.dlh","CyrusScatterEdit.dlm","CyrusScatter.ms","CyrusGallery.dll","CyrusInstaller.dll","Clipper2-LICENSE.txt","SurfaceGeodesic-LICENSE.txt","SurfaceGeodesic-NOTICE.txt","nlohmann-json-LICENSE.txt","libjpeg-turbo-LICENSE.txt","libjpeg-turbo-IJG-README.txt","libjpeg-turbo-NOTICE.txt","INSTALL.txt","LibraryFiles.ms","CyrusScatterStartup.ms","CyrusScatter.mcr","Uninstall.ms"};
        var rows=new StringBuilder("CyrusScatterInstall2\t0.86.8.7\t2027\t0123456789ab\n");
        foreach(string name in names){byte[] bytes=Encoding.UTF8.GetBytes("Owned filesystem fixture only: "+name+"\n");File.WriteAllBytes(Path.Combine(folder,name),bytes);rows.Append(name+"\t"+InstallEngine.Hash(bytes)+"\t"+bytes.Length+"\t"+name+"\n");}
        File.WriteAllText(Path.Combine(folder,"InstallInventory.txt"),rows.ToString(),new UTF8Encoding(false));
        folder=Payload("analyzer");Directory.CreateDirectory(folder);
        foreach(string name in new[]{"CyrusSurfaceAnalyzer.dlx","CyrusSurfaceAnalyzer.ms","CyrusSurfaceAnalyzerStartup.ms"})File.WriteAllText(Path.Combine(folder,name),"Owned Analyzer filesystem fixture: "+name+"\n",new UTF8Encoding(false));
        var descriptor=Descriptor();File.WriteAllText(Path.Combine(folder,"AnalyzerPackage.txt"),"CyrusAnalyzerPackage1\n"+descriptor.Year+"\n"+descriptor.Version+"\n"+descriptor.RuntimeID+"\n"+descriptor.NativeHash+"\n"+descriptor.ScriptHash+"\n"+descriptor.StartupHash+"\n",new UTF8Encoding(false));
    }
    static AnalyzerPackage Descriptor(){string f=Payload("analyzer");return new AnalyzerPackage("2027","0.14.2","0123456789abcdef",InstallEngine.Hash(File.ReadAllBytes(Path.Combine(f,"CyrusSurfaceAnalyzer.dlx"))),InstallEngine.Hash(File.ReadAllBytes(Path.Combine(f,"CyrusSurfaceAnalyzer.ms"))),InstallEngine.Hash(File.ReadAllBytes(Path.Combine(f,"CyrusSurfaceAnalyzerStartup.ms"))));}
    static void Install(string product,InstallPaths p,Action<string> checkpoint=null){if(product=="scatter"){string f=Payload(product);new InstallEngine(f,InstallEngine.Hash(File.ReadAllBytes(Path.Combine(f,"InstallInventory.txt")))).Install(p,checkpoint);}else new AnalyzerInstallEngine(Payload(product),Descriptor()).Install(p,checkpoint);}
    static void Seed(string product,InstallPaths p){
        foreach(string d in new[]{p.Scripts,p.Startup,p.Macros,p.Profile,Root(p,product)})Directory.CreateDirectory(d);
        File.WriteAllText(Path.Combine(p.Profile,"Plugin.UserSettings.ini"),"[Directories]\r\nUnrelated=C:\\Preserve\\Plugins\r\n",Encoding.Unicode);
        if(product=="scatter"){File.WriteAllBytes(Targets(p,product)[0],LegacyStartup);File.WriteAllBytes(Targets(p,product)[1],LegacyMacro);}
        else File.Copy(Path.Combine(Payload(product),"CyrusSurfaceAnalyzerStartup.ms"),Targets(p,product)[0]);
    }
    static string Backup(string product,InstallPaths p,bool corrected){
        string root=Path.Combine(Root(p,product),"Backups");if(corrected)root=Path.Combine(root,"v2");
        if(product=="analyzer")return Path.Combine(root,"startup-"+Descriptor().StartupHash+".ms");
        string[] targets=Targets(p,product);
        using(var data=new MemoryStream())using(var writer=new BinaryWriter(data,Encoding.UTF8)){
            for(int i=0;i<3;++i){byte[] bytes=i==0?LegacyStartup:i==1?LegacyMacro:null;writer.Write(targets[i]);writer.Write(bytes==null?-1:bytes.Length);if(bytes!=null)writer.Write(bytes);}
            writer.Flush();return Path.Combine(root,"wrappers-"+InstallEngine.Hash(data.ToArray()),"CyrusScatterStartup.ms");
        }
    }
    static void VerifyBackups(string product,InstallPaths p,bool required){
        string canonical=Backup(product,p,true);byte[] expected=product=="scatter"?LegacyStartup:File.ReadAllBytes(Path.Combine(Payload(product),"CyrusSurfaceAnalyzerStartup.ms"));
        if(required)Check(File.Exists(canonical),product+" canonical backup exists");
        if(File.Exists(canonical))Check(InstallEngine.Hash(File.ReadAllBytes(canonical))==InstallEngine.Hash(expected),product+" canonical backup is complete");
    }
    static void CheckInstall(string product,InstallPaths p){Install(product,p);VerifyBackups(product,p,true);Check(File.ReadAllText(Path.Combine(p.Profile,"Plugin.UserSettings.ini")).Contains("Unrelated=C:\\Preserve\\Plugins"),product+" unrelated INI entry preserved");int count=Directory.GetFiles(Path.Combine(Root(p,product),"Backups"),"*",SearchOption.AllDirectories).Length;Install(product,p);Check(count==Directory.GetFiles(Path.Combine(Root(p,product),"Backups"),"*",SearchOption.AllDirectories).Length,product+" repeat does not create backup copies");}
    static void Checks(){
        CreatePayloads();int n=0;
        foreach(string product in new[]{"scatter","analyzer"}){
            var p=Paths("p"+(n++));Seed(product,p);CheckInstall(product,p);
            p=Paths("p"+(n++));Seed(product,p);string old=Backup(product,p,false);Directory.CreateDirectory(Path.GetDirectoryName(old));File.WriteAllText(old,"interrupted");CheckInstall(product,p);Check(File.ReadAllText(old)=="interrupted",product+" poisoned legacy final is retained");
            string metadata=product=="scatter"?Path.Combine(Path.GetDirectoryName(Backup(product,p,true)),"complete.txt"):Path.ChangeExtension(Backup(product,p,true),"txt");Check(File.ReadAllText(metadata).Contains(old)&&File.ReadAllText(metadata).Contains(Backup(product,p,true)),product+" migration records old and new backup paths");
            p=Paths("p"+(n++));Seed(product,p);string current=Backup(product,p,true);Directory.CreateDirectory(Path.GetDirectoryName(current));File.WriteAllText(current,"different canonical backup");string before=Snapshot(p,product);Check(Reject(()=>Install(product,p))&&Snapshot(p,product)==before&&File.ReadAllText(current)=="different canonical backup",product+" unexpected current backup and original are preserved");
            string[] labels=product=="scatter"?new[]{"scatter-0","scatter-1","scatter-set"}:new[]{"analyzer-startup","analyzer-set"};
            foreach(string label in labels)foreach(string phase in new[]{"before-create","partial-write","before-flush","after-flush","before-verify","verified","before-move","after-move"}){
                p=Paths("p"+(n++));Seed(product,p);before=Snapshot(p,product);bool hit=false;string target="backup:"+label+":"+phase;
                Check(Reject(()=>Install(product,p,value=>{if(value==target){hit=true;throw new IOException("Owned checkpoint error");}}))&&hit&&Snapshot(p,product)==before,product+" original registration retained at "+target);VerifyBackups(product,p,false);CheckInstall(product,p);
            }
            p=Paths("p"+(n++));Seed(product,p);File.WriteAllText(Targets(p,product)[0],"Artist customization");before=Snapshot(p,product);Check(Reject(()=>Install(product,p))&&Snapshot(p,product)==before,product+" customized startup preserved");
            p=Paths("p"+(n++));Seed(product,p);File.WriteAllText(Targets(p,product)[product=="scatter"?2:1],"Unknown installation receipt");before=Snapshot(p,product);Check(Reject(()=>Install(product,p))&&Snapshot(p,product)==before,product+" unknown receipt preserved");
            p=Paths("p"+(n++));Seed(product,p);before=Snapshot(p,product);using(var held=new FileStream(Path.Combine(Root(p,product),"install.lock"),FileMode.OpenOrCreate,FileAccess.ReadWrite,FileShare.None))Check(Reject(()=>Install(product,p))&&Snapshot(p,product)==before,product+" concurrent installer refused");
            p=Paths("p"+(n++));Seed(product,p);before=Snapshot(p,product);File.WriteAllBytes(Path.Combine(Root(p,product),"install-transaction.bin"),new byte[]{1,2,3});Check(Reject(()=>Install(product,p))&&Snapshot(p,product)==before,product+" malformed journal refuses publication");
            p=Paths("p"+(n++));Seed(product,p);before=Snapshot(p,product);bool refused;
            using(var held=new FileStream(Targets(p,product)[0],FileMode.Open,FileAccess.Read,FileShare.Read))refused=Reject(()=>Install(product,p));
            Check(refused&&Snapshot(p,product)==before,product+" locked startup preserves registration");CheckInstall(product,p);
            p=Paths(product+new string('x',85));Seed(product,p);before=Snapshot(p,product);Check(Reject(()=>Install(product,p))&&Snapshot(p,product)==before,product+" long backup destination refuses before publication");
            p=Paths("p"+(n++));Seed(product,p);bool edited=false;string editedState=null;
            string editAt=product=="scatter"?"backup:scatter-0:before-create":"backup:analyzer-startup:before-create";
            refused=Reject(()=>Install(product,p,phase=>{if(phase==editAt){edited=true;File.WriteAllText(Targets(p,product)[0],"External edit during backup");editedState=Snapshot(p,product);}}));
            Check(refused&&edited&&Snapshot(p,product)==editedState,product+" external edit during backup is preserved");
            p=Paths("p"+(n++));Seed(product,p);edited=false;editedState=null;
            editAt=product=="scatter"?"publishing:1":"analyzer-publish:1";
            refused=Reject(()=>Install(product,p,phase=>{if(phase==editAt){edited=true;File.WriteAllText(Targets(p,product)[0],"External edit during recovery");editedState=Snapshot(p,product);throw new IOException("Owned recovery interruption");}}));
            Check(refused&&edited&&Snapshot(p,product)==editedState&&File.Exists(Path.Combine(Root(p,product),"install-transaction.bin")),product+" recovery preserves external edit and journal");
            Check(Reject(()=>Install(product,p))&&Snapshot(p,product)==editedState,product+" retry does not overwrite external recovery edit");
        }
        var modifiedMacro=Paths("modified-macro");Seed("scatter",modifiedMacro);File.WriteAllText(Targets(modifiedMacro,"scatter")[1],"Artist macro customization");string macroSnapshot=Snapshot(modifiedMacro,"scatter");Check(Reject(()=>Install("scatter",modifiedMacro))&&Snapshot(modifiedMacro,"scatter")==macroSnapshot,"customized Scatter macro preserved");
        var checkSpace=typeof(InstallEngine).GetMethod("CheckFreeSpace",System.Reflection.BindingFlags.NonPublic|System.Reflection.BindingFlags.Static);
        bool lowSpace=false;try{checkSpace.Invoke(null,new object[]{"owned synthetic volume",1024L,2048L});}catch(System.Reflection.TargetInvocationException error){lowSpace=error.InnerException is IOException;}
        Check(lowSpace,"shared free-space guard refuses an explicitly insufficient allowance");
        var custom=Paths("custom-registration");Seed("analyzer",custom);File.WriteAllText(Path.Combine(custom.Profile,"Plugin.UserSettings.ini"),"[Directories]\nCyrusSurfaceAnalyzer2027="+Path.Combine(Root(custom,"analyzer"),"r","0000000000000000","bin"));string snapshot=Snapshot(custom,"analyzer");Check(Reject(()=>Install("analyzer",custom))&&Snapshot(custom,"analyzer")==snapshot,"unknown Analyzer runtime path is not ownership");
        var owned=Paths("edited-runtime");Seed("analyzer",owned);Install("analyzer",owned);File.WriteAllText(Path.Combine(Root(owned,"analyzer"),"r","0123456789abcdef","bin","CyrusSurfaceAnalyzer.dlx"),"External native edit");snapshot=Snapshot(owned,"analyzer");Check(Reject(()=>Install("analyzer",owned))&&Snapshot(owned,"analyzer")==snapshot,"receipt-owned edited Analyzer runtime is preserved");
        var adapter=Paths("adapter");Seed("analyzer",adapter);snapshot=Snapshot(adapter,"analyzer");
        string descriptorHash=InstallEngine.Hash(File.ReadAllBytes(Path.Combine(Payload("analyzer"),"AnalyzerPackage.txt")));
        Check(Reject(()=>AnalyzerInstallEngine.InstallFromHost(Payload("analyzer"),descriptorHash,adapter.Scripts,adapter.Startup,adapter.Macros,adapter.Profile,"2026"))&&Snapshot(adapter,"analyzer")==snapshot,"host entry rejects wrong descriptor year before changing destinations");
        Check(Reject(()=>AnalyzerInstallEngine.InstallFromHost(Payload("analyzer"),new string('0',64),adapter.Scripts,adapter.Startup,adapter.Macros,adapter.Profile,"2027"))&&Snapshot(adapter,"analyzer")==snapshot,"host entry rejects descriptor tampering before changing destinations");
        string source=Path.Combine(Payload("analyzer"),"CyrusSurfaceAnalyzer.dlx");byte[] original=File.ReadAllBytes(source);File.WriteAllText(source,"Tampered payload");
        Check(Reject(()=>AnalyzerInstallEngine.InstallFromHost(Payload("analyzer"),descriptorHash,adapter.Scripts,adapter.Startup,adapter.Macros,adapter.Profile,"2027"))&&Snapshot(adapter,"analyzer")==snapshot,"host entry rejects payload tampering before changing destinations");File.WriteAllBytes(source,original);
        AnalyzerInstallEngine.InstallFromHost(Payload("analyzer"),descriptorHash,adapter.Scripts,adapter.Startup,adapter.Macros,adapter.Profile,"2027");VerifyBackups("analyzer",adapter,true);
        Console.WriteLine("CHECKS "+checks);
    }
    static int Main(string[] args){try{
        work=Path.GetFullPath(args[1]);Directory.CreateDirectory(work);
        if(args[0]=="checks"){Checks();return 0;}
        if(args[0]=="linked"){Check(Reject(()=>new InstallPaths(args[2],Path.Combine(work,"u"),Path.Combine(work,"m"),work)),"linked destination rejected without following it");return 0;}
        string product=args[2];var p=Paths(args[3]);
        if(args[0]=="seed"){CreatePayloads();Seed(product,p);return 0;}
        if(args[0]=="registration"){
            CreatePayloads();Seed(product,p);File.AppendAllText(Path.Combine(p.Profile,"Plugin.UserSettings.ini"),(product=="scatter"?"CyrusScatter2027":"CyrusSurfaceAnalyzer2027")+"=C:\\Custom\\Plugins\r\n",Encoding.Unicode);string before=Snapshot(p,product);
            Check(Reject(()=>Install(product,p))&&Snapshot(p,product)==before,product+" custom registration preserved");return 0;
        }
        if(args[0]=="legacy-scatter"){
            CreatePayloads();Seed("scatter",p);string legacy=args[4];
            string bins=args[5].StartsWith("r/")?Path.Combine(p.RuntimeRoot,args[5]):Path.Combine(Root(p,"scatter"),args[5]);Directory.CreateDirectory(bins);
            var originals=new Dictionary<string,string>();
            foreach(string name in new[]{"AminScatter.dlx","CyrusBrush.dlx","CyrusBrushStorage.dlh","CyrusScatterEdit.dlm"}){
                string path=Path.Combine(bins,name);File.Copy(Path.Combine(legacy,name),path);originals[path]=InstallEngine.Hash(File.ReadAllBytes(path));
            }
            File.Copy(Path.Combine(legacy,"CyrusScatterStartup.ms"),Targets(p,"scatter")[0],true);File.Copy(Path.Combine(legacy,"CyrusScatter.mcr"),Targets(p,"scatter")[1],true);
            string wrapperHash=InstallEngine.Hash(File.ReadAllBytes(Targets(p,"scatter")[0]));
            File.AppendAllText(Path.Combine(p.Profile,"Plugin.UserSettings.ini"),"CyrusScatter2027="+bins+"\r\n",Encoding.Unicode);
            Install("scatter",p);foreach(var original in originals)Check(InstallEngine.Hash(File.ReadAllBytes(original.Key))==original.Value,"exact archived Scatter native survives upgrade");
            bool backup=false;foreach(string file in Directory.GetFiles(Path.Combine(Root(p,"scatter"),"Backups","v2"),"CyrusScatterStartup.ms",SearchOption.AllDirectories))backup|=InstallEngine.Hash(File.ReadAllBytes(file))==wrapperHash;
            Check(backup,"exact archived Scatter startup has durable backup");return 0;
        }
        if(args[0]=="retry"){CheckInstall(product,p);return 0;}
        if(args[0]=="legacy"){
            CreatePayloads();Seed("analyzer",p);string legacy=args[4],bins=Path.Combine(Root(p,"analyzer"),args[5]);Directory.CreateDirectory(bins);
            string native=Path.Combine(bins,"CyrusSurfaceAnalyzer.dlx"),script=Path.Combine(Path.GetDirectoryName(bins),"CyrusSurfaceAnalyzer.ms");
            File.Copy(Path.Combine(legacy,"CyrusSurfaceAnalyzer.dlx"),native);File.Copy(Path.Combine(legacy,"CyrusSurfaceAnalyzer.ms"),script);
            File.Copy(Path.Combine(legacy,"CyrusSurfaceAnalyzerStartup.ms"),Targets(p,"analyzer")[0],true);
            File.AppendAllText(Path.Combine(p.Profile,"Plugin.UserSettings.ini"),"CyrusSurfaceAnalyzer2027="+bins+"\r\n",Encoding.Unicode);
            string nativeHash=InstallEngine.Hash(File.ReadAllBytes(native)),scriptHash=InstallEngine.Hash(File.ReadAllBytes(script));
            Install("analyzer",p);Check(InstallEngine.Hash(File.ReadAllBytes(native))==nativeHash&&InstallEngine.Hash(File.ReadAllBytes(script))==scriptHash,"exact archived Analyzer runtime survives upgrade");
            string backup=Path.Combine(Root(p,"analyzer"),"Backups","v2","startup-"+InstallEngine.Hash(File.ReadAllBytes(Path.Combine(legacy,"CyrusSurfaceAnalyzerStartup.ms")))+".ms");Check(File.Exists(backup),"exact archived Analyzer startup has durable backup");return 0;
        }
        if(args[0]=="child"){
            Install(product,p,phase=>{if(phase==args[4]){using(var marker=new FileStream(args[5],FileMode.CreateNew,FileAccess.Write,FileShare.Read)){byte[] bytes=Encoding.UTF8.GetBytes(phase);marker.Write(bytes,0,bytes.Length);marker.Flush(true);}while(true)Thread.Sleep(100);}});
            throw new Exception("Requested interruption point was not reached");
        }
        throw new Exception("Unknown fixture mode");
    }catch(Exception error){Console.Error.WriteLine(error);return 1;}}
}
