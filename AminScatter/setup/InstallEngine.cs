// Shared file transaction for the MZP host adapter and standalone installer.
// All destinations are explicit; this engine never launches Max or edits licensing.
using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace Cyrus.Setup {
    public sealed class InstallPaths {
        public string Scripts, Startup, Macros, Profile;
        public InstallPaths(string scripts, string startup, string macros, string profile) {
            Scripts = Full(scripts); Startup = Full(startup); Macros = Full(macros); Profile = Full(profile);
        }
        internal static string Full(string path) {
            if (String.IsNullOrWhiteSpace(path) || !Path.IsPathRooted(path)) throw new IOException("An absolute destination is required.");
            string result = Path.GetFullPath(path).TrimEnd(Path.DirectorySeparatorChar);
            if (result.StartsWith(@"\\", StringComparison.Ordinal) || result.Length < 4) throw new IOException("Installation requires a local destination.");
            for (string at = result; !String.IsNullOrEmpty(at); at = Path.GetDirectoryName(at))
                if ((File.Exists(at) || Directory.Exists(at)) && (File.GetAttributes(at) & FileAttributes.ReparsePoint) != 0)
                    throw new IOException("Installation does not follow linked folders: " + at);
            return result;
        }
    }
    public sealed class Entry {
        public string Name, Hash; public long Bytes;
    }
    public sealed class InstallEngine {
        const string Marker = "CyrusScatterInstall1";
        public string Version { get; private set; }
        public string ContentID { get; private set; }
        public long PayloadBytes { get; private set; }
        readonly string source;
        readonly List<Entry> files = new List<Entry>();
        static readonly HashSet<string> Runtime = new HashSet<string>(StringComparer.OrdinalIgnoreCase) {
            "AminScatter.dlx", "CyrusBrush.dlx", "CyrusBrushStorage.dlh", "CyrusScatterEdit.dlm", "CyrusScatter.ms", "CyrusGallery.dll",
            "CyrusInstaller.dll", "Clipper2-LICENSE.txt", "nlohmann-json-LICENSE.txt", "INSTALL.txt", "LibraryFiles.ms", "CyrusScatterStartup.ms", "CyrusScatter.mcr", "Uninstall.ms"
        };
        static readonly HashSet<string> Native = new HashSet<string>(StringComparer.OrdinalIgnoreCase) {
            "AminScatter.dlx", "CyrusBrush.dlx", "CyrusBrushStorage.dlh", "CyrusScatterEdit.dlm"
        };
        public static string Hash(byte[] bytes) { using (var sha = SHA256.Create()) return BitConverter.ToString(sha.ComputeHash(bytes)).Replace("-", "").ToLowerInvariant(); }
        static string FileHash(string path) { using (var stream = File.OpenRead(path)) using (var sha = SHA256.Create()) return BitConverter.ToString(sha.ComputeHash(stream)).Replace("-", "").ToLowerInvariant(); }
        static bool Hex(string value, int length) {
            if (value.Length != length) return false;
            foreach (char c in value) if (!(c >= '0' && c <= '9') && !(c >= 'a' && c <= 'f')) return false;
            return true;
        }
        static string Child(string root, string relative) {
            if (String.IsNullOrEmpty(relative) || relative.Contains(":") || relative.StartsWith("/") || relative.StartsWith("\\")) throw new IOException("Invalid package path.");
            foreach (string part in relative.Replace('\\', '/').Split('/'))
                if (part.Length == 0 || part == "." || part == ".." || part.TrimEnd(' ', '.') != part || part.IndexOfAny(Path.GetInvalidFileNameChars()) >= 0)
                    throw new IOException("Invalid package path: " + relative);
            string result = InstallPaths.Full(Path.Combine(root, relative.Replace('/', Path.DirectorySeparatorChar)));
            if (!result.StartsWith(root.TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase)) throw new IOException("Package path escaped its destination.");
            return result;
        }
        public InstallEngine(string packageDirectory, string inventoryHash) {
            source = InstallPaths.Full(packageDirectory);
            byte[] data = ReadBounded(Child(source, "InstallInventory.txt"),262144);
            if (data.Length > 262144 || !Hex(inventoryHash, 64) || Hash(data) != inventoryHash) throw new IOException("Installer inventory identity differs.");
            var lines = new UTF8Encoding(false, true).GetString(data).Replace("\r", "").Split('\n');
            string[] header = lines[0].Split('\t');
            if (header.Length != 4 || header[0] != Marker || header[2] != "2027" || !Hex(header[3], 12)) throw new IOException("This installer requires the Max 2027 payload contract.");
            Version = header[1]; ContentID = header[3];
            if (!System.Text.RegularExpressions.Regex.IsMatch(Version, @"^0\.[0-9]{1,3}\.[0-9]{1,3}(\.[0-9]{1,3})?$")) throw new IOException("Invalid development version.");
            var names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            for (int i = 1; i < lines.Length; ++i) {
                if (lines[i].Length == 0) continue;
                string[] row = lines[i].Split('\t'); long size;
                if (row.Length != 3 || !Hex(row[1], 64) || !Int64.TryParse(row[2], out size) || size < 0 || size > 128L * 1024 * 1024 || !names.Add(row[0])) throw new IOException("Invalid inventory entry.");
                if (!Runtime.Contains(row[0]) && !row[0].StartsWith("Library/", StringComparison.Ordinal)) throw new IOException("Unsupported installer file: " + row[0]);
                Child(source, row[0]); files.Add(new Entry { Name = row[0], Hash = row[1], Bytes = size }); PayloadBytes += size;
            }
            if (files.Count > 512 || PayloadBytes > 512L * 1024 * 1024) throw new IOException("Installer payload exceeds its bound.");
            foreach (string name in Runtime) if (!names.Contains(name)) throw new IOException("Missing runtime file: " + name);
        }
        void Verify(string path, Entry item) {
            if (!File.Exists(path) || new FileInfo(path).Length != item.Bytes || FileHash(path) != item.Hash) throw new IOException("Payload differs: " + item.Name);
        }
        static byte[] ReadBounded(string path, long limit) {
            using(var stream=File.OpenRead(path)) {
                if(stream.Length>limit)throw new IOException("File exceeds the installation bound: "+path);
                using(var memory=new MemoryStream()) { var buffer=new byte[65536];int count;
                    while((count=stream.Read(buffer,0,buffer.Length))!=0) { if(memory.Length+count>limit)throw new IOException("File grew beyond the installation bound: "+path); memory.Write(buffer,0,count); }
                    return memory.ToArray();
                }
            }
        }
        static byte[] ReadOptional(string path) { return File.Exists(path) ? ReadBounded(path,2*1024*1024) : null; }
        static bool Equal(byte[] a, byte[] b) {
            if (a == null || b == null) return a == b;
            if (a.Length != b.Length) return false;
            for (int i = 0; i < a.Length; ++i) if (a[i] != b[i]) return false;
            return true;
        }
        static void WriteAtomic(string path, byte[] value) {
            InstallPaths.Full(path); Directory.CreateDirectory(Path.GetDirectoryName(path));
            string temp = path + ".cyrus-" + Guid.NewGuid().ToString("N");
            try {
                using (var stream = new FileStream(temp, FileMode.CreateNew, FileAccess.Write, FileShare.None)) { stream.Write(value, 0, value.Length); stream.Flush(true); }
                if (File.Exists(path)) File.Replace(temp, path, null); else File.Move(temp, path);
            } finally { if (File.Exists(temp)) File.Delete(temp); }
        }
        static byte[] Text(string value) { return new UTF8Encoding(true).GetBytes(value); }
        static string Decode(byte[] value) { if (value == null) return ""; using (var reader = new StreamReader(new MemoryStream(value), Encoding.UTF8, true)) return reader.ReadToEnd(); }
        static byte[] Registration(byte[] previous, string nativePath) {
            string text = Decode(previous); if (text.Length > 1048576) throw new IOException("Plugin settings exceed the installation bound.");
            var output = new List<string>(); bool section = false, found = false;
            foreach (string raw in text.Replace("\r", "").Split('\n')) {
                string line = raw.Trim();
                if (line.StartsWith("[") && line.EndsWith("]")) {
                    if (section && nativePath != null) output.Add("CyrusScatter2027=" + nativePath);
                    section = line.Equals("[Directories]", StringComparison.OrdinalIgnoreCase);
                    if (section && found) throw new IOException("Duplicate Directories sections require manual review.");
                    found |= section;
                }
                int equals = line.IndexOf('=');
                if (section && equals >= 0 && (line.Substring(0, equals).Trim().Equals("CyrusScatter2027", StringComparison.OrdinalIgnoreCase) || line.Substring(0, equals).Trim().Equals("AminScatter2027", StringComparison.OrdinalIgnoreCase))) continue;
                output.Add(raw);
            }
            if (!found && nativePath != null) { output.Add("[Directories]"); section = true; }
            if (section && nativePath != null) output.Add("CyrusScatter2027=" + nativePath);
            return Encoding.Unicode.GetPreambleConcat(String.Join("\r\n", output));
        }
        static string[] Targets(InstallPaths paths) { return new[] {
            Path.Combine(paths.Startup,"CyrusScatterStartup.ms"), Path.Combine(paths.Macros,"CyrusScatter.mcr"),
            Path.Combine(paths.Scripts,"CyrusScatter","installed.txt"), Path.Combine(paths.Profile,"Plugin.UserSettings.ini")
        }; }
        static string Journal(InstallPaths paths) { return Path.Combine(paths.Scripts,"CyrusScatter","install-transaction.bin"); }
        static void CheckWrappers(byte[][] before) {
            string[] expected;
            if(before[2]!=null) {
                string[] record=Decode(before[2]).Replace("\r","").Split('\n');
                if(record.Length!=6||record[0]!=Marker||!Hex(record[3],64)||!Hex(record[4],64))throw new IOException("The existing installation receipt differs.");
                expected=new[]{record[3],record[4]};
            }else {
                // Exact wrappers from the last delivered 0.85.0 package only.
                // Unknown/custom files need review, never a name-based overwrite.
                expected=new[]{"fdf38b3bc83187eecb34b833bfff2751e78626e9e3dba41aa20a0ff7ff9e8405","758c4d94d47eab5dbfe9a30b358e7ba94c5734b18968133ba78b8a5d18df262b"};
            }
            for(int i=0;i<2;++i)if(before[i]!=null&&Hash(before[i])!=expected[i])throw new IOException("An existing startup/macro file differs from its owned version. Preserve/review it before updating.");
        }
        static void SaveJournal(string journal, string[] paths, byte[][] before, byte[][] after) {
            using (var stream = new MemoryStream()) using (var writer = new BinaryWriter(stream, Encoding.UTF8)) {
                writer.Write(Marker); writer.Write(paths.Length);
                for (int i=0;i<paths.Length;++i) { writer.Write(paths[i]); foreach(var bytes in new[]{before[i],after[i]}) { writer.Write(bytes==null?-1:bytes.Length); if(bytes!=null)writer.Write(bytes); } }
                writer.Flush(); WriteAtomic(journal, stream.ToArray());
            }
        }
        static void Recover(InstallPaths paths) {
            string journal=Journal(paths); if(!File.Exists(journal))return;
            var targets=Targets(paths); var before=new byte[targets.Length][]; var after=new byte[targets.Length][];
            byte[] data=ReadBounded(journal,8*1024*1024);
            using(var reader=new BinaryReader(new MemoryStream(data),Encoding.UTF8)) {
                if(reader.ReadString()!=Marker||reader.ReadInt32()!=targets.Length)throw new IOException("Unknown installation recovery journal.");
                for(int i=0;i<targets.Length;++i) {
                    if(!String.Equals(reader.ReadString(),targets[i],StringComparison.OrdinalIgnoreCase))throw new IOException("Recovery destinations differ. Use the original profile.");
                    for(int side=0;side<2;++side) { int length=reader.ReadInt32(); if(length < -1 || length>2*1024*1024)throw new IOException("Invalid recovery data."); byte[] bytes=length<0?null:reader.ReadBytes(length); if(bytes!=null&&bytes.Length!=length)throw new IOException("Incomplete recovery data."); if(side==0)before[i]=bytes;else after[i]=bytes; }
                }
                if(reader.BaseStream.Position!=reader.BaseStream.Length)throw new IOException("Unexpected recovery bytes.");
            }
            bool complete=true;
            for(int i=0;i<targets.Length;++i) { var now=ReadOptional(targets[i]); if(!Equal(now,before[i])&&!Equal(now,after[i]))throw new IOException("A recovery file was edited externally; it was preserved: "+targets[i]); complete &= Equal(now,after[i]); }
            if(!complete) for(int i=targets.Length-1;i>=0;--i) {
                // A locked file that already has its old bytes needs no rewrite.
                if(Equal(ReadOptional(targets[i]),before[i]))continue;
                if(before[i]==null) {if(File.Exists(targets[i]))File.Delete(targets[i]);} else WriteAtomic(targets[i],before[i]);
            }
            File.Delete(journal);
        }
        string Relative(Entry item) { return Native.Contains(item.Name)?"bin/"+item.Name:item.Name.StartsWith("Library/",StringComparison.Ordinal)?"Library-"+Version+"/"+item.Name.Substring(8):item.Name; }
        public string Install(InstallPaths paths) { return Install(paths, null); }
        // Checkpoints support bounded cancellation and the owned failure fixture.
        // Callbacks never arrive from an installed library entry or package data.
        public string Install(InstallPaths paths, Action<string> checkpoint) {
            string root=InstallPaths.Full(Path.Combine(paths.Scripts,"CyrusScatter")); Directory.CreateDirectory(root);
            using(var installLock=new FileStream(Path.Combine(root,"install.lock"),FileMode.OpenOrCreate,FileAccess.ReadWrite,FileShare.None)) {
                Recover(paths);
                string release=Child(root,"Releases/"+Version+"-"+ContentID),stage=Child(root,".install-"+Guid.NewGuid().ToString("N"));
                string[] targets=Targets(paths); var before=new byte[targets.Length][]; var after=new byte[targets.Length][];
                for(int i=0;i<targets.Length;++i) { InstallPaths.Full(targets[i]); before[i]=ReadOptional(targets[i]); if(before[i]!=null&&before[i].Length>2*1024*1024)throw new IOException("Installation target exceeds bounds."); }
                // A previous current receipt owns only the registered wrapper files.
                // Unknown custom startup/macros cannot silently be replaced.
                CheckWrappers(before);
                var drive=new DriveInfo(Path.GetPathRoot(root));
                if(!drive.DriveFormat.Equals("NTFS",StringComparison.OrdinalIgnoreCase))throw new IOException("This installer currently requires local NTFS storage.");
                if(drive.AvailableFreeSpace<PayloadBytes+16*1024*1024)throw new IOException("Not enough free disk space for staged installation.");
                bool staged=false;
                try {
                    foreach(var entry in files)Verify(Child(source,entry.Name),entry);
                    if(checkpoint!=null)checkpoint("verified");
                    if(Directory.Exists(release)) {
                        // Repair missing owned files; never overwrite changed bytes.
                        foreach(var entry in files) { string path=Child(release,Relative(entry)); if(File.Exists(path))Verify(path,entry); }
                        foreach(var entry in files) { string path=Child(release,Relative(entry)); if(!File.Exists(path)) { Directory.CreateDirectory(Path.GetDirectoryName(path)); WriteAtomic(path,File.ReadAllBytes(Child(source,entry.Name))); Verify(path,entry); } }
                    }
                    else {
                        Directory.CreateDirectory(stage); staged=true;
                        foreach(var entry in files) { string path=Child(stage,Relative(entry)); Directory.CreateDirectory(Path.GetDirectoryName(path)); File.Copy(Child(source,entry.Name),path,false); Verify(path,entry); if(checkpoint!=null)checkpoint("copied:"+entry.Name); }
                        Directory.CreateDirectory(Path.GetDirectoryName(release)); Directory.Move(stage,release); staged=false;
                    }
                    // The stable loader follows the module that Max actually loaded,
                    // so a publication interruption cannot mix loose script/native pairs.
                    after[0]=File.ReadAllBytes(Child(source,"CyrusScatterStartup.ms"));
                    after[1]=File.ReadAllBytes(Child(source,"CyrusScatter.mcr"));
                    after[2]=Text(Marker+"\n"+Version+"\n"+release+"\n"+Hash(after[0])+"\n"+Hash(after[1])+"\n");
                    after[3]=Registration(before[3],Path.Combine(release,"bin"));
                    for(int i=0;i<targets.Length;++i)if(!Equal(ReadOptional(targets[i]),before[i]))throw new IOException("An installation target changed during preparation; retry.");
                    SaveJournal(Journal(paths),targets,before,after);
                    if(checkpoint!=null)checkpoint("journal");
                    for(int i=0;i<targets.Length;++i) {
                        if(checkpoint!=null)checkpoint("publishing:"+i);
                        if(!Equal(ReadOptional(targets[i]),before[i]))throw new IOException("An installation target changed before publication; it was preserved.");
                        if(!Equal(before[i],after[i]))WriteAtomic(targets[i],after[i]);
                    }
                    File.Delete(Journal(paths));
                    return release;
                } catch { if(File.Exists(Journal(paths)))Recover(paths); throw; }
                finally {
                    if(staged&&Directory.Exists(stage)) {
                        // Only our unique staging path is eligible for recursive removal.
                        string checkedStage=InstallPaths.Full(stage);
                        if(Path.GetDirectoryName(checkedStage)!=root||!Path.GetFileName(checkedStage).StartsWith(".install-",StringComparison.Ordinal))throw new IOException("Staging ownership changed.");
                        Directory.Delete(checkedStage,true);
                    }
                }
            }
        }
        public static void RemoveRegistration(InstallPaths paths) {
            string root=InstallPaths.Full(Path.Combine(paths.Scripts,"CyrusScatter"));
            if(!Directory.Exists(root))return;
            using(var installLock=new FileStream(Path.Combine(root,"install.lock"),FileMode.OpenOrCreate,FileAccess.ReadWrite,FileShare.None)) {
                Recover(paths); var targets=Targets(paths); var before=new byte[targets.Length][]; var after=new byte[targets.Length][];
                for(int i=0;i<targets.Length;++i)before[i]=ReadOptional(targets[i]);
                if(before[2]==null)throw new IOException("No owned installation receipt was found. No registration was removed.");
                string[] record=Decode(before[2]).Replace("\r","").Split('\n');
                if(record.Length!=6||record[0]!=Marker||!Hex(record[3],64)||!Hex(record[4],64))throw new IOException("The installation receipt differs. No registration was removed.");
                string release=InstallPaths.Full(record[2]);
                if(!release.StartsWith(Path.Combine(root,"Releases")+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase))throw new IOException("Installation ownership differs.");
                for(int i=0;i<2;++i)if(before[i]!=null&&Hash(before[i])!=record[i+3])throw new IOException("A startup/macro file was edited; it was preserved: "+targets[i]);
                string native=Path.Combine(release,"bin");bool directories=false;int registrations=0;
                foreach(string raw in Decode(before[3]).Replace("\r","").Split('\n')) {
                    string line=raw.Trim();
                    if(line.StartsWith("[")&&line.EndsWith("]"))directories=line.Equals("[Directories]",StringComparison.OrdinalIgnoreCase);
                    int equals=line.IndexOf('=');
                    if(directories&&equals>=0&&line.Substring(0,equals).Trim().Equals("CyrusScatter2027",StringComparison.OrdinalIgnoreCase)) {
                        if(!line.Substring(equals+1).Trim().Equals(native,StringComparison.OrdinalIgnoreCase))throw new IOException("The native registration changed externally. It was preserved.");
                        ++registrations;
                    }
                }
                if(registrations!=1)throw new IOException("The native registration changed externally. It was preserved.");
                // Removing registration retains versioned recovery files, bundled
                // libraries, imported textures and personal recipes by design.
                after[3]=Registration(before[3],null);
                SaveJournal(Journal(paths),targets,before,after);
                try {
                    for(int i=0;i<targets.Length;++i) {
                        if(!Equal(ReadOptional(targets[i]),before[i]))throw new IOException("A registration target changed before removal; it was preserved.");
                        if(after[i]==null) {if(File.Exists(targets[i]))File.Delete(targets[i]);}else WriteAtomic(targets[i],after[i]);
                    }
                    File.Delete(Journal(paths));
                }catch{Recover(paths);throw;}
            }
        }
    }
    internal static class EncodingExtensions {
        public static byte[] GetPreambleConcat(this Encoding encoding,string value) { byte[] preamble=encoding.GetPreamble(),content=encoding.GetBytes(value),result=new byte[preamble.Length+content.Length]; Buffer.BlockCopy(preamble,0,result,0,preamble.Length);Buffer.BlockCopy(content,0,result,preamble.Length,content.Length);return result; }
    }
}
