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
        readonly string source;
        readonly AnalyzerPackage package;
        static readonly string[] Names={"CyrusSurfaceAnalyzer.dlx","CyrusSurfaceAnalyzer.ms"};
        public AnalyzerInstallEngine(string directory,AnalyzerPackage descriptor) {
            source=InstallPaths.Full(directory);package=descriptor??throw new ArgumentNullException("descriptor");
            VerifyPayload(null);
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
                bool owned=record!=null?hash==record[4]:hash==package.StartupHash||hash==LegacyStartup;
                if(!owned)throw new IOException("Max "+package.Year+": Analyzer startup was modified or is not recognized. It was preserved. File: "+targets[0]);
            }
            string registered=RegisteredPath(before[2],"CyrusSurfaceAnalyzer"+package.Year);
            if(registered!=null) {
                string full=InstallPaths.Full(registered),root=Root(paths);
                bool owned=record!=null?String.Equals(full,InstallEngine.Child(root,"r/"+record[3]+"/bin"),StringComparison.OrdinalIgnoreCase)
                    :String.Equals(full,InstallEngine.Child(root,"bin05"),StringComparison.OrdinalIgnoreCase)
                     ||Regex.IsMatch(full.Substring(Math.Min(full.Length,root.Length)),@"^[\\/]r[\\/][0-9a-f]{16}[\\/]bin$",RegexOptions.IgnoreCase)
                       &&full.StartsWith(root+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase);
                if(!owned)throw new IOException("Max "+package.Year+": Analyzer registration differs and was preserved. File: "+targets[2]+"; entry: "+registered);
            }
        }
        byte[][] Inspect(InstallPaths paths,Action<string> checkpoint) {
            long bytes=VerifyPayload(checkpoint);string runtime=Runtime(paths);
            foreach(string name in new[]{"bin/CyrusSurfaceAnalyzer.dlx","CyrusSurfaceAnalyzer.ms"})CheckPath(InstallEngine.Child(runtime,name));
            string[] targets=Targets(paths);var before=new byte[targets.Length][];
            for(int i=0;i<targets.Length;++i){CheckPath(targets[i]);before[i]=InstallEngine.ReadOptional(targets[i]);}
            CheckOwnership(paths,targets,before);
            if(before[0]!=null&&before[1]==null)
                CheckPath(Path.Combine(Root(paths),"Backups","startup-"+InstallEngine.Hash(before[0])+".ms"));
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
        void PreserveStartup(string root,byte[][] before) {
            if(before[0]==null||before[1]!=null)return;
            string backup=InstallEngine.Child(root,"Backups/startup-"+InstallEngine.Hash(before[0])+".ms");CheckPath(backup);
            if(File.Exists(backup)) {
                if(!InstallEngine.Equal(InstallEngine.ReadOptional(backup),before[0]))throw new IOException("Analyzer startup backup differs and was preserved: "+backup);
            } else {
                Directory.CreateDirectory(Path.GetDirectoryName(backup));
                using(var output=new FileStream(backup,FileMode.CreateNew,FileAccess.Write,FileShare.None)){output.Write(before[0],0,before[0].Length);output.Flush(true);}
            }
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
                    PreserveStartup(root,before);InstallEngine.SaveJournal(Journal(paths),targets,before,after,Marker);
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
