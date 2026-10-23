// Independent Analyzer installation; no scene operations or MAXScript execution.
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;

namespace Cyrus.Setup {
    public sealed class AnalyzerPackage {
        public readonly string Year,Version,RuntimeID,NativeHash,ScriptHash,StartupHash;
        public AnalyzerPackage(string year,string version,string runtimeID,string nativeHash,string scriptHash,string startupHash) {
            InstallEngine.CheckYear(year);
            if(version==null||!Regex.IsMatch(version,@"^0\.[0-9]{1,3}\.[0-9]{1,3}(\.[0-9]{1,3})?$"))throw new IOException("Invalid Analyzer version.");
            foreach(string hash in new[]{nativeHash,scriptHash,startupHash})
                if(hash==null||!InstallEngine.Hex(hash,64))throw new IOException("Invalid Analyzer payload identity.");
            if(runtimeID==null||!InstallEngine.Hex(runtimeID,16))throw new IOException("Invalid Analyzer runtime identity.");
            Year=year;Version=version;RuntimeID=runtimeID;NativeHash=nativeHash;ScriptHash=scriptHash;StartupHash=startupHash;
        }
    }

    public sealed class AnalyzerInstallEngine {
        const string Marker="CyrusAnalyzerInstall1";
        // Exact original repository-delivered 0.14 startup wrapper. Current MZP
        // startup bytes are bound separately by the embedded package descriptor.
        const string LegacyStartup="fdef46e54790c5c6d893479a17c6c885e4ff39897d00f1eac6b8567f86c18425";
        const string PairedStartup="368e005445a17fb28e5f2843cbc5547d303ebea85b97d9405529618b11fb1223";
        // Exact archived .14/.14.1 MZP bytes, not a path-pattern ownership rule.
        // Columns: host, registered relative directory, native hash, script hash.
        static readonly string[,] LegacyRuntimes={
            {"2024","r/4a86a117b8994e5c/bin","2267a7e3142657a29db2ae5834a1a7e61b250fee122e5bc59e679ae3f3eeca20","2238771589587b346abe1c018e4301162684bd06176136b77ef752c12bacedd7"},
            {"2026","r/cfe2ca335f9fb1ec/bin","e9ee53805d17b094b8b0eb08168c3815dba7c97be93376855ad5f21cd33ce829","2238771589587b346abe1c018e4301162684bd06176136b77ef752c12bacedd7"},
            {"2027","r/6089dbb859775490/bin","8f9acb86a27f59c97077f2409a693eda4aaf73fc8043becb689371c0cf2e58f3","2238771589587b346abe1c018e4301162684bd06176136b77ef752c12bacedd7"},
            {"2026","bin-max2026-15750cab0159","15750cab0159dd1608067b66a1e96806187312f934765275bff2d063509ad599","b9a1f1aa2ba7847566eb8f36bee711f9c64753572955ed4549f2f68669e5f923"},
            {"2027","bin-max2027-e2318bd967cf","e2318bd967cf8b17ce1b1208e156c61a9f6361a80b8160c34c54bd2eb2a886de","b9a1f1aa2ba7847566eb8f36bee711f9c64753572955ed4549f2f68669e5f923"},
            {"2026","bin-max2026-e46a3c1822c6","e46a3c1822c672108c1a995490872efd88c4da9b7c6c87edd30fc847f5dcb8a7","716a78868a78ea01842bdfa680baa628316530ca774aea7b537c7fef3db0d7ae"},
            {"2027","bin-max2027-1f4727b909cc","1f4727b909cc3d46f88c51f0feba282d5ec51b53731c75f6633da4297f0839a6","716a78868a78ea01842bdfa680baa628316530ca774aea7b537c7fef3db0d7ae"},
            {"2027","bin-max2027-3dc35151a817","3dc35151a8179a22fb93309e9648a8e7ca7cb76d68a48163a4166c1b77e50582","716a78868a78ea01842bdfa680baa628316530ca774aea7b537c7fef3db0d7ae"},
            {"2027","bin-max2027-ca333595a53d","ca333595a53d5252dc68c8a797beb6971d6d3f36a298323ee3edc8f8371cfefb","9f1f146814870a094ab226334675459e0130a9f1d8bd1d621405b52f99ffb3c8"},
            {"2026","bin-max2026-3df3fb4bed5f","3df3fb4bed5ffc5d40415c080a5b0db574cc430619ff43e0ba7769089a1dcdf0","9f1f146814870a094ab226334675459e0130a9f1d8bd1d621405b52f99ffb3c8"},
            {"2026","bin-max2026-3892ba42c81b","3892ba42c81bad5c7653b16bbb4ce3bcbe1d275983f405a628746a87d7bc8e4b","9f1f146814870a094ab226334675459e0130a9f1d8bd1d621405b52f99ffb3c8"},
            {"2027","bin-max2027-ec6d41636d04","ec6d41636d045b33693e0c70ea0cbb4bb0b357f4cd643ab07e6411dde98102a2","9f1f146814870a094ab226334675459e0130a9f1d8bd1d621405b52f99ffb3c8"},
            {"2027","bin-max2027-737c50438892","737c50438892916cff7ece1b90fc606f7d6d08f695effc7e0bab76b3e9b15131","b9a1f1aa2ba7847566eb8f36bee711f9c64753572955ed4549f2f68669e5f923"},
            {"2026","bin-max2026-b2e3534d6ee6","b2e3534d6ee63adc79f34105e1a283b9a382322a81a956d031d975eda54fad64","9f1f146814870a094ab226334675459e0130a9f1d8bd1d621405b52f99ffb3c8"}
        };
        readonly string source;
        readonly AnalyzerPackage package;
        static readonly string[] Names={"CyrusSurfaceAnalyzer.dlx","CyrusSurfaceAnalyzer.ms"};
        public AnalyzerInstallEngine(string directory,AnalyzerPackage descriptor) {
            source=InstallPaths.Full(directory);package=descriptor??throw new ArgumentNullException("descriptor");
            VerifyPayload(null);
        }
        // Reflection entry point bound to the adapter's exact assembly. String
        // arguments avoid globally resolving any previously loaded Cyrus type.
        public static string InstallFromHost(string directory,string descriptorHash,string scripts,string startup,string macros,string profile,string year) {
            byte[] bytes=InstallEngine.ReadBounded(InstallEngine.Child(InstallPaths.Full(directory),"AnalyzerPackage.txt"),4096);
            if(!InstallEngine.Hex(descriptorHash,64)||InstallEngine.Hash(bytes)!=descriptorHash)throw new IOException("Analyzer package descriptor differs.");
            string[] fields=InstallEngine.Decode(bytes).Replace("\r","").Split('\n');
            if(fields.Length!=8||fields[0]!="CyrusAnalyzerPackage1"||fields[1]!=year)throw new IOException("Analyzer descriptor requires its matching Max host.");
            var descriptor=new AnalyzerPackage(fields[1],fields[2],fields[3],fields[4],fields[5],fields[6]);
            return new AnalyzerInstallEngine(directory,descriptor).Install(InstallPaths.ForMax(scripts,startup,macros,profile,year));
        }
        static string Root(InstallPaths paths) { return InstallEngine.Child(paths.Scripts,"CyrusSurfaceAnalyzer"); }
        static string[] Targets(InstallPaths paths) { return new[]{
            InstallEngine.Child(paths.Startup,"CyrusSurfaceAnalyzerStartup.ms"),
            InstallEngine.Child(Root(paths),"installed.txt"),
            InstallEngine.Child(paths.Profile,"Plugin.UserSettings.ini")
        }; }
        static string Journal(InstallPaths paths) { return InstallEngine.Child(Root(paths),"install-transaction.bin"); }
        string Runtime(InstallPaths paths) { return InstallEngine.Child(Root(paths),"r/"+package.RuntimeID); }
        static string Relative(int i) { return i==0?"bin/"+Names[i]:Names[i]; }
        string Expected(int i) { return i==0?package.NativeHash:package.ScriptHash; }
        static void CheckPath(string path) {
            if(path.Length>=260||Path.GetDirectoryName(path).Length>=248)throw new IOException("Analyzer destination exceeds the supported path length: "+path);
            InstallPaths.Full(path);
        }
        long VerifyPayload(Action<string> checkpoint) {
            long total=0;
            for(int i=0;i<Names.Length;++i) {
                string path=InstallEngine.Child(source,Names[i]);long size=new FileInfo(path).Length;
                if(size>128L*1024*1024||size==0||InstallEngine.FileHash(path,checkpoint)!=Expected(i))throw new IOException("Analyzer package differs: "+path);
                total=checked(total+size);
            }
            byte[] startup=InstallEngine.ReadBounded(InstallEngine.Child(source,"CyrusSurfaceAnalyzerStartup.ms"),2*1024*1024);
            if(InstallEngine.Hash(startup)!=package.StartupHash)throw new IOException("Analyzer startup payload differs.");
            return checked(total+startup.Length);
        }
        static string RegisteredPath(byte[] bytes,string key) {
            string result=null;bool inside=false,seen=false;
            foreach(string raw in InstallEngine.Decode(bytes).Replace("\r","").Split('\n')) {
                string line=raw.Trim();
                if(line.StartsWith("[")&&line.EndsWith("]")) {
                    inside=line.Equals("[Directories]",StringComparison.OrdinalIgnoreCase);
                    if(inside&&seen)throw new IOException("Duplicate Directories sections require review.");
                    seen|=inside;continue;
                }
                int at=line.IndexOf('=');
                if(inside&&at>=0&&line.Substring(0,at).Trim().Equals(key,StringComparison.OrdinalIgnoreCase)) {
                    if(result!=null)throw new IOException("Duplicate Analyzer registration requires review.");
                    result=line.Substring(at+1).Trim();
                }
            }
            return result;
        }
        void CheckOwnership(InstallPaths paths,string[] targets,byte[][] before) {
            string[] record=null;
            if(before[1]!=null) {
                record=InstallEngine.Decode(before[1]).Replace("\r","").Split('\n');
                if(record.Length!=8||record[0]!=Marker||record[1]!=package.Year||!Regex.IsMatch(record[2],@"^0\.[0-9]{1,3}\.[0-9]{1,3}(\.[0-9]{1,3})?$")||!InstallEngine.Hex(record[3],16))
                    throw new IOException("Max "+package.Year+": Analyzer installation receipt differs: "+targets[1]);
                for(int i=4;i<7;++i)if(!InstallEngine.Hex(record[i],64))throw new IOException("Invalid Analyzer installation receipt: "+targets[1]);
            }
            if(before[0]!=null) {
                string hash=InstallEngine.Hash(before[0]);
                bool owned=record!=null?hash==record[4]:hash==package.StartupHash||hash==LegacyStartup||hash==PairedStartup;
                if(!owned)throw new IOException("Max "+package.Year+": Analyzer startup was modified or is not recognized. It was preserved. File: "+targets[0]);
            }
            string registered=RegisteredPath(before[2],"CyrusSurfaceAnalyzer"+package.Year);
            if(registered!=null) {
                string full=InstallPaths.Full(registered),root=Root(paths);
                bool owned=false;string nativeHash=null,scriptHash=null;
                if(record!=null) {
                    owned=String.Equals(full,InstallEngine.Child(root,"r/"+record[3]+"/bin"),StringComparison.OrdinalIgnoreCase);
                    nativeHash=record[5];scriptHash=record[6];
                } else if(String.Equals(full,InstallEngine.Child(Runtime(paths),"bin"),StringComparison.OrdinalIgnoreCase)) {
                    owned=true;nativeHash=package.NativeHash;scriptHash=package.ScriptHash;
                } else for(int i=0;i<LegacyRuntimes.GetLength(0);++i) {
                    if(package.Year==LegacyRuntimes[i,0]&&String.Equals(full,InstallEngine.Child(root,LegacyRuntimes[i,1]),StringComparison.OrdinalIgnoreCase)) {
                        owned=true;nativeHash=LegacyRuntimes[i,2];scriptHash=LegacyRuntimes[i,3];break;
                    }
                }
                if(!owned)throw new IOException("Max "+package.Year+": Analyzer registration differs and was preserved. File: "+targets[2]+"; entry: "+registered);
                string[] runtimeFiles={InstallEngine.Child(full,Names[0]),InstallEngine.Child(Path.GetDirectoryName(full),Names[1])};
                string[] hashes={nativeHash,scriptHash};
                for(int i=0;i<runtimeFiles.Length;++i) {
                    string file=runtimeFiles[i];
                    if((record==null&&!File.Exists(file))||(File.Exists(file)&&(new FileInfo(file).Length>128L*1024*1024||InstallEngine.FileHash(file)!=hashes[i])))
                        throw new IOException("An Analyzer runtime differs or cannot establish legacy ownership. It was preserved: "+file);
                }
            }
        }
        byte[][] Inspect(InstallPaths paths,Action<string> checkpoint) {
            long bytes=VerifyPayload(checkpoint);string runtime=Runtime(paths);
            foreach(string name in new[]{"bin/CyrusSurfaceAnalyzer.dlx","CyrusSurfaceAnalyzer.ms"})CheckPath(InstallEngine.Child(runtime,name));
            string[] targets=Targets(paths);var before=new byte[targets.Length][];
            for(int i=0;i<targets.Length;++i){CheckPath(targets[i]);before[i]=InstallEngine.ReadOptional(targets[i]);}
            CheckOwnership(paths,targets,before);
            if(before[0]!=null&&before[1]==null)
                VerifiedBackup.CheckPath(Path.Combine(Root(paths),"Backups","v2","startup-"+InstallEngine.Hash(before[0])+".ms"));
            for(int i=0;i<Names.Length;++i) {
                string existing=InstallEngine.Child(runtime,Relative(i));
                if(File.Exists(existing)&&InstallEngine.FileHash(existing,checkpoint)!=Expected(i))throw new IOException("An immutable Analyzer runtime was modified and preserved: "+existing);
            }
            var volumes=new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach(string path in new[]{runtime,paths.Startup,paths.Profile})
                if(volumes.Add(Path.GetPathRoot(path)))InstallEngine.RequireSpace(path,checked(bytes*2));
            return before;
        }
        public static void RecoverRegistration(InstallPaths paths) {
            string root=Root(paths);Directory.CreateDirectory(root);
            using(var held=new FileStream(InstallEngine.Child(root,"install.lock"),FileMode.OpenOrCreate,FileAccess.ReadWrite,FileShare.None))
                InstallEngine.RecoverJournal(Journal(paths),Targets(paths),Marker);
        }
        public string Plan(InstallPaths paths,Action<string> checkpoint=null) {
            string root=Root(paths);Directory.CreateDirectory(root);
            using(var held=new FileStream(InstallEngine.Child(root,"install.lock"),FileMode.OpenOrCreate,FileAccess.ReadWrite,FileShare.None)) {
                InstallEngine.RecoverJournal(Journal(paths),Targets(paths),Marker);Inspect(paths,checkpoint);
                return "Max "+package.Year+": Surface Analyzer "+package.Version+" verified; runtime "+Runtime(paths);
            }
        }
        void CopyRuntime(string stage,int i,Action<string> checkpoint) {
            string destination=InstallEngine.Child(stage,Relative(i));CheckPath(destination);Directory.CreateDirectory(Path.GetDirectoryName(destination));
            using(var input=new FileStream(InstallEngine.Child(source,Names[i]),FileMode.Open,FileAccess.Read,FileShare.Read))
            using(var output=new FileStream(destination,FileMode.CreateNew,FileAccess.Write,FileShare.None)) {
                if(input.Length>128L*1024*1024)throw new IOException("Analyzer runtime exceeds its size limit.");
                byte[] buffer=new byte[65536];int count;long total=0;
                while((count=input.Read(buffer,0,buffer.Length))!=0) {
                    total=checked(total+count);if(total>128L*1024*1024)throw new IOException("Analyzer runtime grew beyond its bound.");
                    if(checkpoint!=null)checkpoint("analyzer-copy:"+Names[i]);output.Write(buffer,0,count);
                }
                output.Flush(true);
            }
            if(InstallEngine.FileHash(destination,checkpoint)!=Expected(i))throw new IOException("Staged Analyzer runtime differs: "+Names[i]);
        }
        void PreserveStartup(string root,string original,byte[][] before,Action<string> checkpoint) {
            if(before[0]==null||before[1]!=null)return;
            string name="startup-"+InstallEngine.Hash(before[0]);
            string legacy=InstallEngine.Child(root,"Backups/"+name+".ms"),backup=InstallEngine.Child(root,"Backups/v2/"+name+".ms");
            VerifiedBackup.Publish(backup,before[0],checkpoint,"analyzer-startup");
            string metadata="CyrusBackupSet2\n"+VerifiedBackup.MigrationRecord(original,legacy,backup,before[0]);
            VerifiedBackup.Publish(InstallEngine.Child(root,"Backups/v2/"+name+".txt"),InstallEngine.Text(metadata),checkpoint,"analyzer-set");
        }
        public string Install(InstallPaths paths,Action<string> checkpoint=null) {
            string root=Root(paths);Directory.CreateDirectory(root);
            using(var held=new FileStream(InstallEngine.Child(root,"install.lock"),FileMode.OpenOrCreate,FileAccess.ReadWrite,FileShare.None)) {
                InstallEngine.RecoverJournal(Journal(paths),Targets(paths),Marker);
                var before=Inspect(paths,checkpoint);string runtime=Runtime(paths);
                string stage=InstallEngine.Child(root,"s/"+Guid.NewGuid().ToString("N").Substring(0,12));
                try {
                    bool complete=true;
                    for(int i=0;i<Names.Length;++i)complete&=File.Exists(InstallEngine.Child(runtime,Relative(i)));
                    if(!complete)for(int i=0;i<Names.Length;++i)CopyRuntime(stage,i,checkpoint);
                    if(!complete&&Directory.Exists(runtime)) {
                        for(int i=0;i<Names.Length;++i) {
                            string target=InstallEngine.Child(runtime,Relative(i));
                            if(File.Exists(target)) {
                                if(InstallEngine.FileHash(target,checkpoint)!=Expected(i))throw new IOException("Analyzer runtime changed during preparation: "+target);
                            } else {Directory.CreateDirectory(Path.GetDirectoryName(target));File.Copy(InstallEngine.Child(stage,Relative(i)),target,false);}
                        }
                    } else if(!complete) {Directory.CreateDirectory(Path.GetDirectoryName(runtime));Directory.Move(stage,runtime);}
                    for(int i=0;i<Names.Length;++i)if(InstallEngine.FileHash(InstallEngine.Child(runtime,Relative(i)),checkpoint)!=Expected(i))throw new IOException("Installed Analyzer runtime differs.");
                    string[] targets=Targets(paths);
                    var after=new[]{InstallEngine.ReadBounded(InstallEngine.Child(source,"CyrusSurfaceAnalyzerStartup.ms"),2*1024*1024),
                        InstallEngine.Text(Marker+"\n"+package.Year+"\n"+package.Version+"\n"+package.RuntimeID+"\n"+package.StartupHash+"\n"+package.NativeHash+"\n"+package.ScriptHash+"\n"),
                        InstallEngine.RegistrationEntry(before[2],InstallEngine.Child(runtime,"bin"),"CyrusSurfaceAnalyzer"+package.Year)};
                    if(InstallEngine.Hash(after[0])!=package.StartupHash)throw new IOException("Analyzer startup changed during preparation.");
                    for(int i=0;i<targets.Length;++i)if(!InstallEngine.Equal(InstallEngine.ReadOptional(targets[i]),before[i]))throw new IOException("Analyzer registration changed during preparation: "+targets[i]);
                    PreserveStartup(root,targets[0],before,checkpoint);
                    for(int i=0;i<targets.Length;++i)if(!InstallEngine.Equal(InstallEngine.ReadOptional(targets[i]),before[i]))throw new IOException("Analyzer registration changed during backup and was preserved: "+targets[i]);
                    InstallEngine.SaveJournal(Journal(paths),targets,before,after,Marker);
                    try {
                        if(checkpoint!=null)checkpoint("analyzer-journal");
                        for(int i=0;i<targets.Length;++i) {
                            if(checkpoint!=null)checkpoint("analyzer-publish:"+i);
                            if(!InstallEngine.Equal(InstallEngine.ReadOptional(targets[i]),before[i]))throw new IOException("Analyzer registration changed during publication: "+targets[i]);
                            InstallEngine.WriteAtomic(targets[i],after[i]);
                        }
                        if(checkpoint!=null)checkpoint("analyzer-published");
                        for(int i=0;i<targets.Length;++i)if(!InstallEngine.Equal(InstallEngine.ReadOptional(targets[i]),after[i]))throw new IOException("Analyzer registration verification failed: "+targets[i]);
                        File.Delete(Journal(paths));return runtime;
                    } catch {
                        InstallEngine.RecoverJournal(Journal(paths),targets,Marker);throw;
                    }
                } finally {
                    // Remove only the two known staged files, never recursively
                    // erase an unexpected directory or another install's runtime.
                    if(Directory.Exists(stage))try {
                        for(int i=0;i<Names.Length;++i){string path=InstallEngine.Child(stage,Relative(i));if(File.Exists(path))File.Delete(path);}
                        string bin=InstallEngine.Child(stage,"bin");if(Directory.Exists(bin))Directory.Delete(bin,false);Directory.Delete(stage,false);
                    }catch(IOException){}
                }
            }
        }
    }
}
