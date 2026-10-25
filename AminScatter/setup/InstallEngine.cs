// Shared file transaction for the MZP host adapter and standalone installer.
// All destinations are explicit; this engine never launches Max or edits licensing.
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;
using System.Runtime.InteropServices;
using Cyrus.Content;

namespace Cyrus.Setup {
    public sealed class InstallPaths {
        public string Scripts, Startup, Macros, Profile, RuntimeRoot, SharedContentRoot, LibraryStatePath;
        public InstallPaths(string scripts, string startup, string macros, string profile) {
            Scripts = Full(scripts); Startup = Full(startup); Macros = Full(macros); Profile = Full(profile);
        }
        public InstallPaths(string scripts, string startup, string macros, string profile, string runtimeRoot)
            : this(scripts,startup,macros,profile) { RuntimeRoot=Full(runtimeRoot); }
        public static InstallPaths ForMax(string scripts,string startup,string macros,string profile,string year) {
            InstallEngine.CheckYear(year);
            string ownedProfile=Full(profile),local=Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            string standard=Full(Path.Combine(local,@"Autodesk\3dsMax\"+year+" - 64bit"));
            // Explicitly relocated Max profiles keep their runtime in that profile.
            // The normal Windows profile uses a short per-user, per-host root.
            bool standardProfile=ownedProfile.StartsWith(standard+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase);
            string runtime=standardProfile
                ? Path.Combine(local,"CyrusScatter",year) : Path.Combine(ownedProfile,"cs");
            var result=new InstallPaths(scripts,startup,macros,ownedProfile,runtime);
            result.SharedContentRoot=standardProfile?Path.Combine(local,"CyrusScatter","Library"):Path.Combine(runtime,"Library");
            result.LibraryStatePath=standardProfile?Path.Combine(local,"CyrusScatter","library-state.txt"):Path.Combine(runtime,"library-state.txt");
            return result;
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
        public string Name, Source, Hash; public long Bytes; public bool External;
    }
    public sealed class InstallEngine {
        const string Marker = "CyrusScatterInstall1";
        public string Version { get; private set; }
        public string Year { get; private set; }
        public static void CheckYear(string year) { if(year!="2024"&&year!="2026"&&year!="2027")throw new IOException("Supported hosts: Max 2024, 2026 and 2027."); }
        public string ContentID { get; private set; }
        public long PayloadBytes { get; private set; }
        readonly string source;
        readonly List<Entry> files = new List<Entry>();
        readonly List<Entry> externalFiles = new List<Entry>();
        string contentDirectory, contentLibrary, contentManifestHash, selectedManifestHash, contentRevision;
        string contentArchive;
        ZipArchive activeArchive;
        int contentMinimumHost;
        long corePayloadBytes;
        // Keep is deliberately the default: a plugin update never admits/copies
        // a multi-gigabyte optional library merely because a sidecar exists.
        public string LibraryAction { get; set; } = "Keep";
        public string LibraryDestination { get; set; }
        public bool RequiresExternalContent { get { return contentManifestHash != null; } }
        public string PackageDirectory { get { return source; } }
        public void SetContentDirectory(string directory) {
            contentArchive=null;
            string candidate=InstallPaths.Full(directory);
            // Both the delivery folder and its Library child are common selections.
            if(!File.Exists(Path.Combine(candidate,"content-manifest.json"))&&File.Exists(Path.Combine(candidate,"Content","content-manifest.json")))
                candidate=InstallPaths.Full(Path.Combine(candidate,"Content"));
            if(String.Equals(Path.GetFileName(candidate),"Library",StringComparison.OrdinalIgnoreCase)&&File.Exists(Path.Combine(Path.GetDirectoryName(candidate),"content-manifest.json")))
                candidate=InstallPaths.Full(Path.GetDirectoryName(candidate));
            contentDirectory=candidate;
            contentLibrary=Directory.Exists(Path.Combine(candidate,"Library"))?Child(candidate,"Library"):candidate;
        }
        IEnumerable<Entry> AllFiles { get { foreach(var item in files)yield return item;foreach(var item in externalFiles)yield return item; } }
        static readonly HashSet<string> Runtime = new HashSet<string>(StringComparer.OrdinalIgnoreCase) {
            "AminScatter.dlx", "CyrusBrush.dlx", "CyrusBrushStorage.dlh", "CyrusScatterEdit.dlm", "CyrusScatter.ms", "CyrusGallery.dll",
            "CyrusInstaller.dll", "Clipper2-LICENSE.txt", "SurfaceGeodesic-LICENSE.txt", "SurfaceGeodesic-NOTICE.txt", "nlohmann-json-LICENSE.txt",
            "libjpeg-turbo-LICENSE.txt", "libjpeg-turbo-IJG-README.txt", "libjpeg-turbo-NOTICE.txt",
            "INSTALL.txt", "LibraryFiles.ms", "CyrusScatterStartup.ms", "CyrusScatter.mcr", "Uninstall.ms"
        };
        static readonly HashSet<string> Native = new HashSet<string>(StringComparer.OrdinalIgnoreCase) {
            "AminScatter.dlx", "CyrusBrush.dlx", "CyrusBrushStorage.dlh", "CyrusScatterEdit.dlm"
        };
        public static string Hash(byte[] bytes) { using (var sha = SHA256.Create()) return BitConverter.ToString(sha.ComputeHash(bytes)).Replace("-", "").ToLowerInvariant(); }
        internal static string FileHash(string path,Action<string> checkpoint=null) {
            using(var stream=File.OpenRead(path))using(var sha=SHA256.Create()) {
                var buffer=new byte[262144];int count;long next=0;
                while((count=stream.Read(buffer,0,buffer.Length))>0) {
                    sha.TransformBlock(buffer,0,count,buffer,0);
                    if(stream.Position>=next){if(checkpoint!=null)checkpoint("checking:"+Path.GetFileName(path));next=stream.Position+8*1024*1024;}
                }
                sha.TransformFinalBlock(new byte[0],0,0);
                return BitConverter.ToString(sha.Hash).Replace("-","").ToLowerInvariant();
            }
        }
        internal static bool Hex(string value, int length) {
            if (value.Length != length) return false;
            foreach (char c in value) if (!(c >= '0' && c <= '9') && !(c >= 'a' && c <= 'f')) return false;
            return true;
        }
        internal static string Child(string root, string relative) {
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
            if (header.Length != 4 || (header[0] != Marker && header[0] != "CyrusScatterInstall2") || !Hex(header[3], 12)) throw new IOException("Invalid Max payload contract.");
            bool mapped=header[0]=="CyrusScatterInstall2";
            CheckYear(header[2]);Year=header[2];Version = header[1]; ContentID = header[3];
            if (!System.Text.RegularExpressions.Regex.IsMatch(Version, @"^0\.[0-9]{1,3}\.[0-9]{1,3}(\.[0-9]{1,3})?$")) throw new IOException("Invalid development version.");
            var names = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var sourceNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            for (int i = 1; i < lines.Length; ++i) {
                if (lines[i].Length == 0) continue;
                string[] row = lines[i].Split('\t'); long size;
                if (row.Length != (mapped?4:3) || !Hex(row[1], 64) || !Int64.TryParse(row[2], out size) || size < 0 || size > 128L * 1024 * 1024 || !names.Add(row[0])) throw new IOException("Invalid inventory entry.");
                bool pattern = System.Text.RegularExpressions.Regex.IsMatch(row[0], @"^Patterns/(catalog\.tsv|index\.json|README\.md|[a-z0-9][a-z0-9_-]{0,80}\.png)$");
                // The modification notice is carried by new packages. Earlier
                // qualified inventories remain readable without that new file.
                bool clipperNotice=String.Equals(row[0],"Clipper2-NOTICE.txt",StringComparison.OrdinalIgnoreCase);
                if (!Runtime.Contains(row[0]) && !clipperNotice && row[0]!="ExternalContent.json" && !row[0].StartsWith("Library/", StringComparison.Ordinal) && !pattern) throw new IOException("Unsupported installer file: " + row[0]);
                string sourceName=mapped?row[3]:row[0];
                if(mapped && sourceName!=row[0] && !(row[0].StartsWith("Library/",StringComparison.Ordinal) && System.Text.RegularExpressions.Regex.IsMatch(sourceName,@"^p/[0-9]{4}\.[a-z0-9]{1,12}$")))throw new IOException("Invalid mapped package source.");
                if(!sourceNames.Add(sourceName))throw new IOException("Duplicate mapped package source.");
                // Validate the logical destination without expanding it under the
                // (possibly deep) archive extraction directory.
                foreach(string part in row[0].Split('/'))if(part.Length==0||part=="."||part==".."||part.Contains(":")||part.Contains("\\")||part.TrimEnd(' ','.')!=part||part.IndexOfAny(Path.GetInvalidFileNameChars())>=0)throw new IOException("Invalid logical destination.");
                Child(source, sourceName); files.Add(new Entry { Name = row[0], Source=sourceName, Hash = row[1], Bytes = size }); PayloadBytes += size;
            }
            if (files.Count > 512 || PayloadBytes > 512L * 1024 * 1024) throw new IOException("Installer payload exceeds its bound.");
            foreach (string name in Runtime) if (!names.Contains(name)) throw new IOException("Missing runtime file: " + name);
            corePayloadBytes=PayloadBytes;
            if(names.Contains("ExternalContent.json")) {
                Entry pin=files.Find(item=>item.Name=="ExternalContent.json");Verify(Child(source,pin.Source),pin);
                var identity=ReadObject(ReadBounded(Child(source,pin.Source),16384));
                CheckContentIdentity(identity);
                object hash;if(!identity.TryGetValue("manifest_sha256",out hash)||!(hash is string)||!Hex((string)hash,64))throw new IOException("Invalid external content identity.");
                contentManifestHash=(string)hash;contentDirectory=Path.Combine(source,"Content");
                foreach(var item in files)if(item.Name.StartsWith("Library/",StringComparison.Ordinal))throw new IOException("External and embedded libraries cannot be mixed.");
            }
        }
        static Dictionary<string,object> ReadObject(byte[] bytes) {
            return new ContentJson(new UTF8Encoding(false,true).GetString(bytes)).Read();
        }
        // The manifest contract contains objects, strings and integral numbers only.
        // Keep this bounded reader self-contained: Max and the EXE do not need a
        // legacy web serializer or a separately deployed JSON assembly.
        sealed class ContentJson {
            readonly string text;int at;
            public ContentJson(string value){text=value;if(text.Length>1048576)throw new IOException("Content manifest exceeds its bound.");if(text.Length>0&&text[0]=='\uFEFF')at=1;}
            void Space(){while(at<text.Length&&(text[at]==' '||text[at]=='\t'||text[at]=='\r'||text[at]=='\n'))++at;}
            IOException Invalid(){return new IOException("Invalid content manifest JSON at character "+at+".");}
            void Take(char expected){Space();if(at>=text.Length||text[at++]!=expected)throw Invalid();}
            string String(){
                Take('"');var value=new StringBuilder();
                while(at<text.Length){char c=text[at++];if(c=='"')return value.ToString();if(c<32)throw Invalid();
                    if(c=='\\'){
                        if(at>=text.Length)throw Invalid();c=text[at++];
                        switch(c){case '"':case '\\':case '/':break;case 'b':c='\b';break;case 'f':c='\f';break;case 'n':c='\n';break;case 'r':c='\r';break;case 't':c='\t';break;
                        case 'u':int number=0;for(int i=0;i<4;++i){if(at>=text.Length)throw Invalid();char hex=text[at++];int digit=hex>='0'&&hex<='9'?hex-'0':hex>='a'&&hex<='f'?hex-'a'+10:hex>='A'&&hex<='F'?hex-'A'+10:-1;if(digit<0)throw Invalid();number=number*16+digit;}c=(char)number;break;
                        default:throw Invalid();}
                    }
                    value.Append(c);
                }
                throw Invalid();
            }
            object Number(){
                Space();int start=at;if(at<text.Length&&text[at]=='-')++at;
                if(at>=text.Length||text[at]<'0'||text[at]>'9')throw Invalid();
                bool zero=text[at]=='0';++at;if(!zero)while(at<text.Length&&text[at]>='0'&&text[at]<='9')++at;
                long value;if(at-start>20||!Int64.TryParse(text.Substring(start,at-start),System.Globalization.NumberStyles.AllowLeadingSign,System.Globalization.CultureInfo.InvariantCulture,out value))throw Invalid();
                if(value>=Int32.MinValue&&value<=Int32.MaxValue)return (int)value;return value;
            }
            Dictionary<string,object> Object(int depth){
                if(depth>16)throw new IOException("Content manifest nesting exceeds its bound.");
                Take('{');var result=new Dictionary<string,object>(StringComparer.Ordinal);Space();if(at<text.Length&&text[at]=='}'){++at;return result;}
                while(true){string name=String();Take(':');Space();if(at>=text.Length)throw Invalid();object value=text[at]=='{'?(object)Object(depth+1):text[at]=='"'?(object)String():Number();
                    if(result.ContainsKey(name))throw new IOException("Duplicate content manifest key: "+name);result.Add(name,value);Space();if(at>=text.Length)throw Invalid();char delimiter=text[at++];if(delimiter=='}')return result;if(delimiter!=',')throw Invalid();
                }
            }
            public Dictionary<string,object> Read(){var result=Object(1);Space();if(at!=text.Length)throw Invalid();return result;}
        }
        void CheckContentIdentity(Dictionary<string,object> value) {
            object format,schema,version,year;
            bool identity=value.TryGetValue("format",out format)&&Object.Equals(format,"cyrus.scatter.content")&&value.TryGetValue("version",out version)&&version is string&&System.Text.RegularExpressions.Regex.IsMatch((string)version,@"^0\.[0-9]{1,3}\.[0-9]{1,3}(\.[0-9]{1,3})?$");
            value.TryGetValue("schema",out schema);value.TryGetValue("max_year",out year);
            bool host=Object.Equals(schema,1)&&year is int&&((int)year==2024||(int)year==2026||(int)year==2027)&&(int)year<=Int32.Parse(Year);
            if(Object.Equals(schema,2)&&Object.Equals(year,2024)) {
                object raw;value.TryGetValue("hosts",out raw);var hosts=raw as Dictionary<string,object>;
                object a,b,c;
                host=hosts!=null&&hosts.Count==3&&hosts.TryGetValue("2024",out a)&&Object.Equals(a,1)&&hosts.TryGetValue("2026",out b)&&Object.Equals(b,1)&&hosts.TryGetValue("2027",out c)&&Object.Equals(c,1);
            }
            if(!identity||!host)throw new IOException("The library format or Max host is unsupported. Max 2027-only content cannot be used in an older host.");
        }
        void LoadExternalContent() {
            externalFiles.Clear();PayloadBytes=corePayloadBytes;
            if(contentDirectory==null)throw new IOException("Choose an existing library or the supplied Content folder.");
            if(contentLibrary==null&&contentArchive==null)SetContentDirectory(contentDirectory);
            string manifest=Child(contentDirectory,"content-manifest.json");
            if(contentArchive==null&&!File.Exists(manifest))throw new IOException("No content manifest in the selected library: "+manifest);
            byte[] bytes=contentArchive==null?ReadBounded(manifest,1048576):ReadArchiveManifest();selectedManifestHash=Hash(bytes);
            var value=ReadObject(bytes);CheckContentIdentity(value);object listed;
            contentRevision=(string)value["version"];contentMinimumHost=Convert.ToInt32(value["max_year"]);
            if(!value.TryGetValue("files",out listed))throw new IOException("Missing content file inventory.");
            var inventory=listed as Dictionary<string,object>;if(inventory==null||inventory.Count==0||inventory.Count>4096)throw new IOException("Content file count exceeds its bound.");
            var names=new HashSet<string>(StringComparer.OrdinalIgnoreCase);long total=0;
            foreach(var row in inventory) {
                if(!row.Key.StartsWith("Library/",StringComparison.Ordinal)||row.Key=="Library/content-manifest.json"||!names.Add(row.Key))throw new IOException("Invalid or duplicate content destination.");
                Child(contentDirectory,row.Key);
                var descriptor=row.Value as Dictionary<string,object>;object length,digest;
                if(descriptor==null||!descriptor.TryGetValue("bytes",out length)||!(length is int||length is long)||!descriptor.TryGetValue("sha256",out digest)||!(digest is string)||!Hex((string)digest,64))throw new IOException("Invalid content file descriptor.");
                long size=Convert.ToInt64(length);if(size<0||size>2L*1024*1024*1024)throw new IOException("Content file exceeds the 2 GiB bound.");
                total+=size;if(total>16L*1024*1024*1024)throw new IOException("Content library exceeds the 16 GiB bound.");
                externalFiles.Add(new Entry { Name=row.Key,Source=row.Key,Bytes=size,Hash=(string)digest,External=true });
            }
            externalFiles.Add(new Entry {Name="Library/content-manifest.json",Source="content-manifest.json",Bytes=bytes.Length,Hash=selectedManifestHash,External=true});PayloadBytes+=total+bytes.Length;
            if(externalFiles.Find(item=>item.Name=="Library/model-catalog.json")==null)throw new IOException("The library has no model catalog.");
        }
        string SourcePath(Entry item) { return item.External?(item.Source=="content-manifest.json"?Child(contentDirectory,item.Source):Child(contentLibrary,item.Name.Substring(8))):Child(source,item.Source); }
        byte[] ReadArchiveManifest() {
            using(var zip=new ZipArchive(File.OpenRead(contentArchive),ZipArchiveMode.Read)) {
                if(zip.Entries.Count>4097)throw new IOException("Content ZIP has too many entries.");
                var names=new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                long total=0;
                foreach(var entry in zip.Entries) {
                    Child(contentDirectory,entry.FullName);
                    if(entry.FullName.Contains("\\")||!names.Add(entry.FullName)||entry.Length>2L*1024*1024*1024)
                        throw new IOException("Invalid or duplicate content ZIP entry.");
                    total=checked(total+entry.Length);
                    if(total>16L*1024*1024*1024)throw new IOException("Content ZIP exceeds its expanded size limit.");
                }
                var manifest=zip.GetEntry("content-manifest.json");
                if(manifest==null||manifest.Length>1048576)throw new IOException("Content ZIP is missing its manifest.");
                using(var input=manifest.Open())using(var output=new MemoryStream()) {
                    var buffer=new byte[65536];int count;
                    while((count=input.Read(buffer,0,buffer.Length))>0) {
                        if(output.Length+count>1048576)throw new IOException("Content manifest exceeds its limit.");
                        output.Write(buffer,0,count);
                    }
                    byte[] bytes=output.ToArray();
                    if(Hash(bytes)!=contentManifestHash)throw new IOException("This content ZIP does not match this installer. Download the matching plant library ZIP.");
                    var value=ReadObject(bytes);CheckContentIdentity(value);
                    var listed=value["files"] as Dictionary<string,object>;
                    if(listed==null||listed.Count+1!=zip.Entries.Count)throw new IOException("Content ZIP inventory differs.");
                    foreach(var row in listed) {
                        var entry=zip.GetEntry(row.Key);var spec=row.Value as Dictionary<string,object>;
                        if(entry==null||spec==null||entry.Length!=Convert.ToInt64(spec["bytes"]))throw new IOException("Content ZIP is incomplete: "+row.Key);
                        // Reject links, devices and other non-regular Unix entries.
                        int kind=(entry.ExternalAttributes>>16)&0xf000;
                        if(kind!=0&&kind!=0x8000)throw new IOException("Content ZIP contains a linked or special file.");
                    }
                    return bytes;
                }
            }
        }
        public string ConfigureLibraryChoice(InstallPaths paths,bool installContent,string companionDirectory) {
            LibraryAction="Keep";LibraryDestination=null;contentArchive=null;
            if(!installContent) {
                // Only preserve/adopt an already installed library; do not adopt a
                // download merely because it happens to sit beside the installer.
                var retained=LibraryLocation.Read(StatePath(paths));
                if(retained!=null&&!retained.Supports(Int32.Parse(Year)))
                    return "Plugin only. The retained library requires Max "+retained.MinimumHost+". Use the library option to install compatible content.";
                string previous=SuggestContentDirectory(paths);
                if(previous.Length==0)return "Plugin only. Existing content is kept.";
                return ConfigureAutomaticLibrary(paths,new string[0]);
            }
            string folder=InstallPaths.Full(companionDirectory),selected=null;int count=0;
            foreach(string path in Directory.EnumerateFiles(folder,"CyrusScatter-Content-*.zip")) {
                if(++count>32)throw new IOException("Too many content ZIPs beside the installer.");
                InstallPaths.Full(path);contentArchive=path;contentDirectory=folder;
                try{ReadArchiveManifest();if(selected==null)selected=path;}catch(IOException){continue;}
            }
            if(selected==null)throw new IOException("Matching content ZIP not found. Place CyrusScatter-Content-0.86.7.zip beside the EXE, or uncheck Install plant library.");
            contentArchive=selected;contentDirectory=folder;
            contentLibrary=SuggestContentDirectory(paths);
            if(contentLibrary.Length==0)contentLibrary=null;
            LoadExternalContent();LibraryAction="Install";
            // An identical complete installed revision remains in place. Verify
            // every file at install time; corrupt files are never silently reused.
            if(contentLibrary!=null&&File.Exists(Path.Combine(contentLibrary,"content-manifest.json"))&&
                FileHash(Path.Combine(contentLibrary,"content-manifest.json"))==selectedManifestHash) {
                bool complete=true;
                foreach(var item in externalFiles) {
                    string path=PreviousFile(contentLibrary,item);
                    if(!File.Exists(path)||new FileInfo(path).Length!=item.Bytes){complete=false;break;}
                }
                if(complete){string previous=contentLibrary;SetContentDirectory(previous);LoadExternalContent();LibraryAction="UseExisting";}
            }
            return "Plant library selected.";
        }
        // Copy and hash in bounded chunks. Multi-gigabyte model files never become byte arrays.
        void CopyVerified(string from,string destination,Entry item,Action<string> checkpoint) {
            using(var input=new FileStream(from,FileMode.Open,FileAccess.Read,FileShare.Read)) {
                if(input.Length!=item.Bytes)throw new IOException("Content file size differs: "+item.Name);
                CopyVerified(input,destination,item,checkpoint);
            }
        }
        void CopyVerified(Stream input,string destination,Entry item,Action<string> checkpoint) {
            Directory.CreateDirectory(Path.GetDirectoryName(destination));string temporary=Path.Combine(Path.GetDirectoryName(destination),".c-"+Guid.NewGuid().ToString("N").Substring(0,12));
            try {
                using(var output=new FileStream(temporary,FileMode.CreateNew,FileAccess.Write,FileShare.None))using(var hash=SHA256.Create()) {
                    var buffer=new byte[262144];int count;long written=0,nextCheckpoint=8*1024*1024;
                    while((count=input.Read(buffer,0,buffer.Length))!=0) {
                        written+=count;if(written>item.Bytes)throw new IOException("Content file grew while copying: "+item.Name);
                        output.Write(buffer,0,count);hash.TransformBlock(buffer,0,count,buffer,0);
                        if(written>=nextCheckpoint){if(checkpoint!=null)checkpoint("copying:"+item.Name);nextCheckpoint=written+8*1024*1024;}
                    }
                    hash.TransformFinalBlock(new byte[0],0,0);
                    if(written!=item.Bytes||BitConverter.ToString(hash.Hash).Replace("-","").ToLowerInvariant()!=item.Hash)throw new IOException("Content file hash differs: "+item.Name);
                    output.Flush(true);
                }
                File.Move(temporary,destination);
            }finally{if(File.Exists(temporary))File.Delete(temporary);}
        }
        void Verify(string path, Entry item,Action<string> checkpoint=null) {
            if (!File.Exists(path) || new FileInfo(path).Length != item.Bytes || FileHash(path,checkpoint) != item.Hash) throw new IOException("Payload differs: " + item.Name);
        }
        [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]
        static extern bool CreateHardLink(string destination,string existing,IntPtr reserved);
        static void Link(string existing,string destination) {
            InstallPaths.Full(existing);InstallPaths.Full(destination);
            Directory.CreateDirectory(Path.GetDirectoryName(destination));
            if(!CreateHardLink(destination,existing,IntPtr.Zero))
                throw new IOException("Could not reuse installed content. Windows error "+Marshal.GetLastWin32Error()+": "+destination);
        }
        string PreviousContent(InstallPaths paths,string runtime,string root,byte[] receipt) {
            if(receipt==null)return null;
            string[] record=Decode(receipt).Replace("\r","").Split('\n');
            if(record.Length!=6||record[0]!=Marker||!System.Text.RegularExpressions.Regex.IsMatch(record[1],@"^0\.[0-9]{1,3}\.[0-9]{1,3}(\.[0-9]{1,3})?$"))return null;
            string previous=InstallPaths.Full(record[2]);
            bool owned=previous.StartsWith(Path.Combine(root,"Releases")+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)
                ||previous.StartsWith(Path.Combine(runtime,"r")+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase);
            return owned?Child(previous,"Library-"+record[1]):null;
        }
        static bool Matches(string path,Entry item,Action<string> checkpoint=null) {
            return File.Exists(path)&&new FileInfo(path).Length==item.Bytes&&FileHash(path,checkpoint)==item.Hash;
        }
        string PreviousFile(string previous,Entry item) {
            return previous==null?null:Child(previous,item.Name.Substring("Library/".Length));
        }
        long MissingContentBytes(string store,string previous,Action<string> checkpoint=null) {
            long total=0;var hashes=new HashSet<string>(StringComparer.Ordinal);
            foreach(var item in externalFiles)if(hashes.Add(item.Hash)) {
                string blob=Child(store,item.Hash),old=PreviousFile(previous,item);
                if(checkpoint!=null)checkpoint("checking:"+item.Name);
                if(File.Exists(blob)){Verify(blob,item,checkpoint);continue;}
                if(old!=null&&String.Equals(Path.GetPathRoot(old),Path.GetPathRoot(store),StringComparison.OrdinalIgnoreCase)&&Matches(old,item,checkpoint))continue;
                total=checked(total+item.Bytes);
            }
            return total;
        }
        void InstallFile(Entry item,string destination,string store,string previous,Action<string> checkpoint) {
            if(!item.External){CopyVerified(SourcePath(item),destination,item,checkpoint);return;}
            string blob=Child(store,item.Hash);
            if(!File.Exists(blob)) {
                string old=PreviousFile(previous,item);
                // Keep previous releases usable by open Max processes. NTFS names
                // share immutable bytes instead of making another library copy.
                if(old!=null&&File.Exists(old)&&String.Equals(Path.GetPathRoot(old),Path.GetPathRoot(store),StringComparison.OrdinalIgnoreCase)) {
                    using(var guard=new FileStream(old,FileMode.Open,FileAccess.Read,FileShare.Read)) {
                        if(Matches(old,item,checkpoint))Link(old,blob);
                    }
                }
                if(!File.Exists(blob)) {
                    if(activeArchive!=null) {
                        var entry=activeArchive.GetEntry(item.Source);
                        if(entry==null||entry.Length!=item.Bytes)throw new IOException("Content ZIP changed: "+item.Name);
                        using(var input=entry.Open())CopyVerified(input,blob,item,checkpoint);
                    }else CopyVerified(SourcePath(item),blob,item,checkpoint);
                }
            }
            using(var guard=new FileStream(blob,FileMode.Open,FileAccess.Read,FileShare.Read)) {
                Verify(blob,item,checkpoint);Link(blob,destination);
            }
        }
        internal static byte[] ReadBounded(string path, long limit) {
            using(var stream=File.OpenRead(path)) {
                if(stream.Length>limit)throw new IOException("File exceeds the installation bound: "+path);
                using(var memory=new MemoryStream()) { var buffer=new byte[65536];int count;
                    while((count=stream.Read(buffer,0,buffer.Length))!=0) { if(memory.Length+count>limit)throw new IOException("File grew beyond the installation bound: "+path); memory.Write(buffer,0,count); }
                    return memory.ToArray();
                }
            }
        }
        internal static byte[] ReadOptional(string path) { return File.Exists(path) ? ReadBounded(path,2*1024*1024) : null; }
        internal static bool Equal(byte[] a, byte[] b) {
            if (a == null || b == null) return a == b;
            if (a.Length != b.Length) return false;
            for (int i = 0; i < a.Length; ++i) if (a[i] != b[i]) return false;
            return true;
        }
        internal static void WriteAtomic(string path, byte[] value) {
            InstallPaths.Full(path); Directory.CreateDirectory(Path.GetDirectoryName(path));
            string temp = Path.Combine(Path.GetDirectoryName(path),".w-"+Guid.NewGuid().ToString("N").Substring(0,12));
            try {
                using (var stream = new FileStream(temp, FileMode.CreateNew, FileAccess.Write, FileShare.None)) { stream.Write(value, 0, value.Length); stream.Flush(true); }
                if (File.Exists(path)) File.Replace(temp, path, null); else File.Move(temp, path);
            } finally { if (File.Exists(temp)) File.Delete(temp); }
        }
        internal static byte[] Text(string value) { return new UTF8Encoding(true).GetBytes(value); }
        internal static string Decode(byte[] value) { if (value == null) return ""; using (var reader = new StreamReader(new MemoryStream(value), Encoding.UTF8, true)) return reader.ReadToEnd(); }
        static byte[] Registration(byte[] previous, string nativePath,string year) {
            return RegistrationEntry(previous,nativePath,"CyrusScatter"+year,"AminScatter"+year);
        }
        internal static byte[] RegistrationEntry(byte[] previous,string nativePath,string key,string legacyKey=null) {
            string text = Decode(previous); if (text.Length > 1048576) throw new IOException("Plugin settings exceed the installation bound.");
            var output = new List<string>(); bool section = false, found = false;
            foreach (string raw in text.Replace("\r", "").Split('\n')) {
                string line = raw.Trim();
                if (line.StartsWith("[") && line.EndsWith("]")) {
                    if (section && nativePath != null) output.Add(key+"=" + nativePath);
                    section = line.Equals("[Directories]", StringComparison.OrdinalIgnoreCase);
                    if (section && found) throw new IOException("Duplicate Directories sections require manual review.");
                    found |= section;
                }
                int equals = line.IndexOf('=');
                if (section && equals >= 0 && (line.Substring(0, equals).Trim().Equals(key, StringComparison.OrdinalIgnoreCase) || (legacyKey!=null&&line.Substring(0, equals).Trim().Equals(legacyKey, StringComparison.OrdinalIgnoreCase)))) continue;
                output.Add(raw);
            }
            if (!found && nativePath != null) { output.Add("[Directories]"); section = true; }
            if (section && nativePath != null) output.Add(key+"=" + nativePath);
            return Encoding.Unicode.GetPreambleConcat(String.Join("\r\n", output));
        }
        static string[] Targets(InstallPaths paths) { return new[] {
            Path.Combine(paths.Startup,"CyrusScatterStartup.ms"), Path.Combine(paths.Macros,"CyrusScatter.mcr"),
            Path.Combine(paths.Scripts,"CyrusScatter","installed.txt"), Path.Combine(paths.Profile,"Plugin.UserSettings.ini")
        }; }
        static string Journal(InstallPaths paths) { return Path.Combine(paths.Scripts,"CyrusScatter","install-transaction.bin"); }
        // Exact delivered Max 2027 wrapper bytes, independently verified against
        // archived packages. No filename/content-pattern ownership inference.
        static readonly string[,] LegacyWrappers = {
            {"0.81.6","fdf38b3bc83187eecb34b833bfff2751e78626e9e3dba41aa20a0ff7ff9e8405","d76b48b84c4b882d4a5a40fd07e880c3b9fb3b0c12bbdac7bfccea3045c91b20"},
            {"0.85.0","fdf38b3bc83187eecb34b833bfff2751e78626e9e3dba41aa20a0ff7ff9e8405","758c4d94d47eab5dbfe9a30b358e7ba94c5734b18968133ba78b8a5d18df262b"},
            {"0.86.8.2","eea8435810d7c2489c1b5062194459156500f7efc1bc4e36a315cc52151d3d06","0f22569def0cab74a0a90d8a14bbf0c2836bd4af22d667da825487e84e74b811"},
            {"0.86.8.3","eea8435810d7c2489c1b5062194459156500f7efc1bc4e36a315cc52151d3d06","67da84af1e5b6ffc3711c3e540d831f90182846b7a59f4706abafa146a6de162"},
            {"0.86.8.4","eea8435810d7c2489c1b5062194459156500f7efc1bc4e36a315cc52151d3d06","d6a7ad19ca2979f4695780cec03f4aef268187d9d5b7e8cf378124d9d76ff619"},
        };
        static bool CheckWrappers(byte[][] before, string[] targets, string year) {
            if(before[2]!=null) {
                string[] record=Decode(before[2]).Replace("\r","").Split('\n');
                if(record.Length!=6||record[0]!=Marker||!Hex(record[3],64)||!Hex(record[4],64))
                    throw new IOException("Max "+year+": the installation receipt is invalid. See Error details.\nFile: "+targets[2]);
                for(int i=0;i<2;++i)if(before[i]!=null&&Hash(before[i])!=record[i+3])
                    throw new IOException("Max "+year+": "+Path.GetFileName(targets[i])+" differs from its installation record. It was preserved. See Error details.\nFile: "+targets[i]);
                return false;
            }
            if(before[0]==null&&before[1]==null)return false;
            for(int row=0;row<LegacyWrappers.GetLength(0);++row) {
                bool matches=true;
                for(int i=0;i<2;++i)matches &= before[i]==null||Hash(before[i])==LegacyWrappers[row,i+1];
                if(matches)return true;
            }
            throw new IOException("Max "+year+": older startup/macro files are not recognized. They were preserved. See Error details.\nReview these files before updating: "+targets[0]+"\n"+targets[1]+"\nNo installation receipt: "+targets[2]);
        }
        // Matching original Max 2027 packages for the admitted wrapper rows.
        // version, inventory identity (empty for old loose layouts), native-set SHA.
        static readonly string[,] LegacyRegistrations={
            {"0.81.6","","7800997061d5627efa377fb24e67519e3224d42215c248436298a03b82953bfa"},
            {"0.85.0","","29c9e9ffb122870c9c8bb9fa26fd6be1468eb31230437bba0acdae18725464b9"},
            {"0.86.8.2","a0e8fbbd7f89","38b7f80122838eb8ae52f9302803e2cd985070f72addadee029575cff7665418"},
            {"0.86.8.3","872f09e13064","cbd5fd34baf73fa4856d31495caa86606b4f430739f05244c0f53c74f430aef9"},
            {"0.86.8.4","09f2cdd4bbb1","c36dd6e84081f474abd4fd1b3f8a3e77e6dc4d609c3773969f6fc2b2fd74223c"}
        };
        static string NativeSetHash(string folder) {
            using(var sha=SHA256.Create()) {
                var names=new List<string>(Native);names.Sort(StringComparer.Ordinal);var buffer=new byte[65536];
                foreach(string name in names)using(var stream=File.OpenRead(Child(folder,name))) {
                    if(stream.Length>128L*1024*1024)throw new IOException("Legacy native module exceeds its byte allowance: "+stream.Name);
                    int count;while((count=stream.Read(buffer,0,buffer.Length))!=0)sha.TransformBlock(buffer,0,count,buffer,0);
                }
                sha.TransformFinalBlock(new byte[0],0,0);return BitConverter.ToString(sha.Hash).Replace("-","").ToLowerInvariant();
            }
        }
        void CheckRegistration(InstallPaths paths,string[] targets,byte[][] before) {
            string root=Child(paths.Scripts,"CyrusScatter"),runtime=paths.RuntimeRoot??root;
            string current=Child(runtime,paths.RuntimeRoot==null?"Releases/"+Version+"-"+ContentID+"/bin":"r/"+ContentID+"/bin");
            string owned=null;
            if(before[2]!=null) {
                string[] record=Decode(before[2]).Replace("\r","").Split('\n');
                string release=InstallPaths.Full(record[2]);
                bool allowed=release.StartsWith(Child(runtime,"r")+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)
                    ||release.StartsWith(Child(root,"Releases")+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase);
                if(!allowed)throw new IOException("The Scatter receipt runtime is not owned and was preserved: "+targets[2]);
                owned=Child(release,"bin");
            }
            bool section=false,seen=false;var keys=new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach(string raw in Decode(before[3]).Replace("\r","").Split('\n')) {
                string line=raw.Trim();
                if(line.StartsWith("[")&&line.EndsWith("]")) {
                    section=line.Equals("[Directories]",StringComparison.OrdinalIgnoreCase);
                    if(section&&seen)throw new IOException("Duplicate plugin directory sections were preserved: "+targets[3]);
                    seen|=section;continue;
                }
                int at=line.IndexOf('=');if(!section||at<0)continue;
                string key=line.Substring(0,at).Trim();
                if(!key.Equals("CyrusScatter"+Year,StringComparison.OrdinalIgnoreCase)&&!key.Equals("AminScatter"+Year,StringComparison.OrdinalIgnoreCase))continue;
                if(!keys.Add(key))throw new IOException("Duplicate Scatter registration was preserved: "+targets[3]+"; "+key);
                string registered=InstallPaths.Full(line.Substring(at+1).Trim());
                bool recognized=owned!=null&&String.Equals(registered,owned,StringComparison.OrdinalIgnoreCase);
                if(owned==null&&String.Equals(registered,current,StringComparison.OrdinalIgnoreCase)) {
                    foreach(var entry in files)if(Native.Contains(entry.Name))Verify(Child(registered,entry.Name),entry);
                    recognized=true;
                }
                if(owned==null&&Year=="2027")for(int i=0;!recognized&&i<LegacyRegistrations.GetLength(0);++i) {
                    string version=LegacyRegistrations[i,0],id=LegacyRegistrations[i,1],hash=LegacyRegistrations[i,2];
                    bool knownPath=id.Length==0?String.Equals(registered,Child(root,"bin-max2027-"+hash.Substring(0,12)),StringComparison.OrdinalIgnoreCase)
                        :String.Equals(registered,Child(runtime,"r/"+id+"/bin"),StringComparison.OrdinalIgnoreCase)
                            ||String.Equals(registered,Child(root,"Releases/"+version+"-"+id+"/bin"),StringComparison.OrdinalIgnoreCase);
                    if(knownPath)recognized=NativeSetHash(registered)==hash;
                }
                if(!recognized)throw new IOException("Max "+Year+": Scatter registration differs and was preserved. File: "+targets[3]+"; entry: "+key+"="+registered);
            }
        }
        static void PreserveLegacyWrappers(string root, string[] targets, byte[][] before,Action<string> checkpoint) {
            // Content-addressed backups survive successful migration and rollback.
            // Repeat installs do not create additional copies.
            using(var data=new MemoryStream())using(var writer=new BinaryWriter(data,Encoding.UTF8)) {
                for(int i=0;i<3;++i){writer.Write(targets[i]);writer.Write(before[i]==null?-1:before[i].Length);if(before[i]!=null)writer.Write(before[i]);}
                writer.Flush();string identity=Hash(data.ToArray());
                string legacy=Child(root,"Backups/wrappers-"+identity),folder=Child(root,"Backups/v2/wrappers-"+identity);
                string metadata="CyrusBackupSet2\n";
                for(int i=0;i<3;++i)if(before[i]!=null) {
                    string path=Child(folder,Path.GetFileName(targets[i]));
                    VerifiedBackup.Publish(path,before[i],checkpoint,"scatter-"+i);
                    metadata+=VerifiedBackup.MigrationRecord(targets[i],Child(legacy,Path.GetFileName(targets[i])),path,before[i]);
                }
                VerifiedBackup.Publish(Child(folder,"complete.txt"),Text(metadata),checkpoint,"scatter-set");
            }
        }
        internal static void SaveJournal(string journal, string[] paths, byte[][] before, byte[][] after,string marker=Marker) {
            using (var stream = new MemoryStream()) using (var writer = new BinaryWriter(stream, Encoding.UTF8)) {
                writer.Write(marker); writer.Write(paths.Length);
                for (int i=0;i<paths.Length;++i) { writer.Write(paths[i]); foreach(var bytes in new[]{before[i],after[i]}) { writer.Write(bytes==null?-1:bytes.Length); if(bytes!=null)writer.Write(bytes); } }
                writer.Flush();
                if(stream.Length>8*1024*1024)throw new IOException("Installation recovery journal exceeds its 8 MiB bound.");
                WriteAtomic(journal, stream.ToArray());
            }
        }
        static void Recover(InstallPaths paths) {
            RecoverJournal(Journal(paths),Targets(paths),Marker);
        }
        internal static void RecoverJournal(string journal,string[] targets,string marker) {
            if(!File.Exists(journal))return;
            var before=new byte[targets.Length][]; var after=new byte[targets.Length][];
            byte[] data=ReadBounded(journal,8*1024*1024);
            using(var reader=new BinaryReader(new MemoryStream(data),Encoding.UTF8)) {
                if(reader.ReadString()!=marker||reader.ReadInt32()!=targets.Length)throw new IOException("Unknown installation recovery journal.");
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
        public static string SaveFailure(InstallPaths paths,string message) {
            try {
                string directory=paths==null?Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"CyrusScatter","logs")
                    : Path.Combine(paths.RuntimeRoot??Path.Combine(paths.Scripts,"CyrusScatter"),"logs");
                Directory.CreateDirectory(directory);
                string path=Path.Combine(directory,"install-"+DateTime.UtcNow.ToString("yyyyMMdd-HHmmss")+"-"+Guid.NewGuid().ToString("N").Substring(0,8)+".txt");
                File.WriteAllText(path,(message??"").Substring(0,Math.Min((message??"").Length,65536)),Encoding.UTF8);return path;
            }catch(IOException){return "";}catch(UnauthorizedAccessException){return "";}
        }
        void CheckDestination(string root) {
            foreach(var entry in AllFiles) {
                string path=Path.Combine(root,Relative(entry).Replace('/',Path.DirectorySeparatorChar));
                if(path.Length>=260||Path.GetDirectoryName(path).Length>=248)
                    throw new IOException("The installation folder is too long for this Max version. No registration was changed. Destination: "+path);
            }
        }
        public static string StatePath(InstallPaths paths) {
            return InstallPaths.Full(paths.LibraryStatePath??Path.Combine(paths.RuntimeRoot??Path.Combine(paths.Scripts,"CyrusScatter"),"library-state.txt"));
        }
        public static string SuggestContentDirectory(InstallPaths paths) {
            var shared=LibraryLocation.Read(StatePath(paths));
            if(shared!=null)return shared.Root;
            string root=InstallPaths.Full(Path.Combine(paths.Scripts,"CyrusScatter"));
            var receipt=ReadOptional(Path.Combine(root,"installed.txt"));
            if(receipt==null)return "";
            string[] rows=Decode(receipt).Replace("\r","").Split('\n');
            if(rows.Length!=6||rows[0]!=Marker||!System.Text.RegularExpressions.Regex.IsMatch(rows[1],@"^0\.[0-9]{1,3}\.[0-9]{1,3}(\.[0-9]{1,3})?$"))return "";
            string release=InstallPaths.Full(rows[2]),runtime=paths.RuntimeRoot??root;
            if(!release.StartsWith(Path.Combine(runtime,"r")+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)&&!release.StartsWith(Path.Combine(root,"Releases")+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase))return "";
            if(File.Exists(Path.Combine(release,"LibraryBinding.txt"))) {
                var binding=LibraryLocation.Resolve(release,2027);
                if(binding!=null)return binding.Root;
            }
            string content=Child(release,"Library-"+rows[1]);
            return File.Exists(Path.Combine(content,"content-manifest.json"))?content:"";
        }
        public static string InstalledVersion(InstallPaths paths) {
            var data=ReadOptional(Path.Combine(paths.Scripts,"CyrusScatter","installed.txt"));
            if(data==null)return "";
            var rows=Decode(data).Replace("\r","").Split('\n');
            return rows.Length==6&&rows[0]==Marker&&System.Text.RegularExpressions.Regex.IsMatch(rows[1],@"^0\.[0-9]{1,3}\.[0-9]{1,3}(\.[0-9]{1,3})?$")?rows[1]:"";
        }
        // Explicit installation command preflight, separate from the read-only
        // Plan used by library/UI inspection. Recover before checking ownership.
        public void PreflightRegistration(InstallPaths paths) {
            string root=Child(paths.Scripts,"CyrusScatter");Directory.CreateDirectory(root);
            using(var held=new FileStream(Child(root,"install.lock"),FileMode.OpenOrCreate,FileAccess.ReadWrite,FileShare.None)) {
                Recover(paths);string[] targets=Targets(paths);var before=new byte[targets.Length][];
                for(int i=0;i<targets.Length;++i){InstallPaths.Full(targets[i]);before[i]=ReadOptional(targets[i]);}
                CheckWrappers(before,targets,Year);CheckRegistration(paths,targets,before);
            }
        }
        // Artist-facing installers resolve known locations automatically. No drive
        // crawl, asset re-export or copying merely to match the plugin version.
        public string ConfigureAutomaticLibrary(InstallPaths paths,IEnumerable<string> candidates) {
            LibraryAction="Keep";LibraryDestination=null;
            var shared=LibraryLocation.Read(StatePath(paths));
            if(shared!=null&&shared.Supports(Int32.Parse(Year))) {
                shared.VerifyCatalog();return "Existing plant library will be reused.";
            }
            var locations=new List<string>();string existing=SuggestContentDirectory(paths);
            if(existing.Length>0)locations.Add(existing);
            if(candidates!=null)foreach(string candidate in candidates)if(!locations.Contains(candidate)&&locations.Count<80)locations.Add(candidate);
            var rejected=new List<string>();
            foreach(string location in locations) {
                try {
                    SetContentDirectory(location);
                    if(!File.Exists(Path.Combine(contentDirectory,"content-manifest.json")))continue;
                    LoadExternalContent();
                    LibraryAction="UseExisting";
                    return "Plant library found. Its existing files will be shared without copying models.";
                }catch(IOException error){rejected.Add(error.Message);}
            }
            if(existing.Length>0||shared!=null||rejected.Count>0)
                throw new IOException("The existing plant library is unavailable or incompatible with Max "+Year+". Restore its Content folder beside the installer and try again.\r\n"+String.Join("\r\n",rejected));
            return "Plant library not found. The plugin will work with your scene models. Keep the supplied Content folder beside this installer to add the library automatically.";
        }
        LibraryRegistration ContentRegistration(string root,string managed) {
            var catalog=externalFiles.Find(item=>item.Name=="Library/model-catalog.json");
            return new LibraryRegistration { Root=InstallPaths.Full(root),Revision=contentRevision,CatalogHash=catalog.Hash,
                ManifestHash=selectedManifestHash,MinimumHost=contentMinimumHost,ManagedRoot=managed??"",PackId="cyrus-plants" };
        }
        LibraryRegistration LegacyRegistration(InstallPaths paths,string runtime,string root,byte[] receipt) {
            string previous=PreviousContent(paths,runtime,root,receipt);
            if(previous==null)return null;
            string release=Path.GetDirectoryName(previous);
            if(File.Exists(Path.Combine(release,"LibraryBinding.txt")))return LibraryLocation.Resolve(release,Int32.Parse(Year));
            string manifest=Path.Combine(previous,"content-manifest.json");
            if(!File.Exists(manifest))return null;
            byte[] bytes=ReadBounded(manifest,1048576);var value=ReadObject(bytes);CheckContentIdentity(value);
            var inventory=value["files"] as Dictionary<string,object>;
            object raw;if(inventory==null||!inventory.TryGetValue("Library/model-catalog.json",out raw))throw new IOException("The previous content manifest has no catalog.");
            var catalog=raw as Dictionary<string,object>;
            if(catalog==null||!catalog.ContainsKey("sha256")||!(catalog["sha256"] is string)||!Hex((string)catalog["sha256"],64))throw new IOException("Invalid previous catalog identity.");
            var registration=new LibraryRegistration {Root=previous,Revision=(string)value["version"],CatalogHash=(string)catalog["sha256"],
                ManifestHash=Hash(bytes),MinimumHost=Convert.ToInt32(value["max_year"]),ManagedRoot="",PackId="cyrus-plants"};
            registration.VerifyCatalog();return registration;
        }
        internal static void CheckFreeSpace(string volume,long available,long bytes) {
            long required=checked(bytes+16L*1024*1024);
            if(available<required)throw new IOException(String.Format("Not enough free space on {0}. Required {1:N0} bytes (including 16 MiB working space); available {2:N0}. Choose another library drive or Update plugin only.",volume,required,available));
        }
        internal static void RequireSpace(string destination,long bytes) {
            var drive=new DriveInfo(Path.GetPathRoot(destination));
            if(!drive.DriveFormat.Equals("NTFS",StringComparison.OrdinalIgnoreCase))throw new IOException("Use local NTFS storage: "+drive.Name);
            CheckFreeSpace(drive.Name,drive.AvailableFreeSpace,bytes);
        }
        static void MoveDirectory(string from,string to) {
            // Windows scanners can briefly retain a freshly written directory.
            // Retry only sharing/access conflicts; never replace a destination.
            for(int attempt=0;;++attempt) {
                try{Directory.Move(from,to);return;}
                catch(IOException error) {
                    int code=error.HResult&65535;
                    if(attempt>=4||Directory.Exists(to)||(code!=5&&code!=32&&code!=33))throw;
                    System.Threading.Thread.Sleep(100);
                }
                catch(UnauthorizedAccessException) {
                    if(attempt>=4||Directory.Exists(to))throw;
                    System.Threading.Thread.Sleep(100);
                }
            }
        }
        string LibraryBase(InstallPaths paths) {return InstallPaths.Full(String.IsNullOrWhiteSpace(LibraryDestination)?(paths.SharedContentRoot??Path.Combine(paths.RuntimeRoot??paths.Profile,"Library")):LibraryDestination);}
        void CheckLibraryPaths(string root) {
            string pack=Child(root,"packs/"+selectedManifestHash.Substring(0,16));
            foreach(var item in externalFiles) {
                string target=Path.Combine(pack,item.Name.Replace('/',Path.DirectorySeparatorChar));
                if(target.Length>=260||Path.GetDirectoryName(target).Length>=248)throw new IOException("Choose a shorter shared library folder. This content path exceeds the supported Windows path length: "+target);
            }
        }
        void CheckAction() {if(LibraryAction!="Keep"&&LibraryAction!="UseExisting"&&LibraryAction!="Install")throw new IOException("Unknown library action.");}
        // Read-only preflight. It deliberately hashes only content participating in
        // an explicitly selected content action, never during a plugin-only update.
        public string Plan(InstallPaths paths) {return Plan(paths,null,true);}
        public string Plan(InstallPaths paths,Action<string> checkpoint) {return Plan(paths,checkpoint,true);}
        public string Plan(InstallPaths paths,Action<string> checkpoint,bool includePlugin) {
            CheckAction();
            string runtime=paths.RuntimeRoot??Path.Combine(paths.Scripts,"CyrusScatter");
            string release=Child(runtime,paths.RuntimeRoot==null?"Releases/"+Version+"-"+ContentID:"r/"+ContentID);
            long pluginBytes=0;if(includePlugin)foreach(var item in files) {
                string target=Child(release,Relative(item));
                if(File.Exists(target))Verify(target,item,checkpoint);else pluginBytes+=item.Bytes;
            }
            var result=new StringBuilder();
            var needed=new Dictionary<string,long>(StringComparer.OrdinalIgnoreCase);
            foreach(string destination in includePlugin?new[]{runtime,paths.Scripts,paths.Startup,paths.Macros,paths.Profile,StatePath(paths)}:new[]{StatePath(paths)})
                needed[Path.GetPathRoot(destination)]=0;
            if(includePlugin)needed[Path.GetPathRoot(runtime)]=pluginBytes;
            result.AppendLine("Plugin "+Version+" / Max "+Year+": "+(includePlugin?runtime:"not selected"));
            result.AppendLine(String.Format("Plugin new bytes: {0:N0}; free on {1}: {2:N0}",pluginBytes,Path.GetPathRoot(runtime),new DriveInfo(Path.GetPathRoot(runtime)).AvailableFreeSpace));
            result.AppendLine("Library registration: "+StatePath(paths));
            if(LibraryAction=="Keep") {
                var registered=LibraryLocation.Read(StatePath(paths));
                string existing=SuggestContentDirectory(paths);
                result.AppendLine(existing.Length==0?"No library configured; choose content later.":"Keep existing library: "+existing);
                if(registered!=null&&!registered.Supports(Int32.Parse(Year)))result.AppendLine("The selected shared library requires Max "+registered.MinimumHost+". This host needs compatible content or its existing fallback.");
                result.AppendLine("Library new bytes: 0. No model or texture copies.");
            }else {
                LoadExternalContent();
                string root=LibraryAction=="Install"?LibraryBase(paths):contentLibrary,store=Child(root,"objects");
                if(LibraryAction=="Install")CheckLibraryPaths(root);
                long bytes=LibraryAction=="UseExisting"?0:MissingContentBytes(store,contentLibrary,checkpoint);
                if(LibraryAction=="Install") {
                    string drive=Path.GetPathRoot(root);
                    if(!needed.ContainsKey(drive))needed.Add(drive,0);
                    needed[drive]=checked(needed[drive]+bytes);
                }
                result.AppendLine("Library "+contentRevision+" / minimum Max "+contentMinimumHost+": "+contentLibrary);
                result.AppendLine(LibraryAction=="UseExisting"?"Use these verified files in their current folder.":"Shared destination: "+root);
                result.AppendLine(String.Format("Library new bytes: {0:N0}; free on {1}: {2:N0}",bytes,Path.GetPathRoot(root),new DriveInfo(Path.GetPathRoot(root)).AvailableFreeSpace));
            }
            foreach(var drive in needed)result.AppendLine(String.Format("Drive {0}: {1:N0} new bytes + 16 MiB working allowance; {2:N0} bytes free.",drive.Key,drive.Value,new DriveInfo(drive.Key).AvailableFreeSpace));
            result.AppendLine("16 MiB working allowance per destination volume. Existing releases and old texture paths are retained.");
            return result.ToString();
        }
        public string InstallLibrary(InstallPaths paths,Action<string> checkpoint) {
            if(contentArchive!=null) {
                using(var zip=new ZipArchive(File.OpenRead(contentArchive),ZipArchiveMode.Read)) {
                    activeArchive=zip;
                    try{return InstallLibraryCore(paths,checkpoint);}finally{activeArchive=null;}
                }
            }
            return InstallLibraryCore(paths,checkpoint);
        }
        string InstallLibraryCore(InstallPaths paths,Action<string> checkpoint) {
            CheckAction();if(LibraryAction=="Keep")return "";
            LoadExternalContent();
            string state=StatePath(paths),root=LibraryAction=="Install"?LibraryBase(paths):contentLibrary;
            RequireSpace(state,16384);Directory.CreateDirectory(Path.GetDirectoryName(state));
            using(var stateLock=new FileStream(state+".lock",FileMode.OpenOrCreate,FileAccess.ReadWrite,FileShare.None)) {
                LibraryRegistration registration;
                if(LibraryAction=="UseExisting") {
                    foreach(var item in externalFiles) {
                        if(checkpoint!=null)checkpoint("verify-content:"+item.Name);
                        Verify(SourcePath(item),item,checkpoint);
                    }
                    registration=ContentRegistration(contentLibrary,"");
                }else {
                    CheckLibraryPaths(root);
                    string store=Child(root,"objects"),pack=Child(root,"packs/"+selectedManifestHash.Substring(0,16));
                    RequireSpace(root,MissingContentBytes(store,contentLibrary,checkpoint));
                    Directory.CreateDirectory(root);
                    using(var contentLock=new FileStream(Path.Combine(root,"content.lock"),FileMode.OpenOrCreate,FileAccess.ReadWrite,FileShare.None)) {
                        RequireSpace(root,MissingContentBytes(store,contentLibrary,checkpoint));
                        bool exists=Directory.Exists(pack);
                        string stage=exists?pack:Child(root,"staging/"+Guid.NewGuid().ToString("N").Substring(0,12));
                        try {
                            foreach(var item in externalFiles) {
                                string target=Child(stage,item.Name);
                                if(File.Exists(target))Verify(target,item,checkpoint);
                            }
                            foreach(var item in externalFiles) {
                                string target=Child(stage,item.Name);
                                if(!File.Exists(target))InstallFile(item,target,store,contentLibrary,checkpoint);
                                if(checkpoint!=null)checkpoint("content:"+item.Name);
                            }
                            if(!exists){Directory.CreateDirectory(Path.GetDirectoryName(pack));MoveDirectory(stage,pack);}
                        }finally {
                            if(!exists&&Directory.Exists(stage)) {
                                if(Path.GetDirectoryName(InstallPaths.Full(stage))!=Child(root,"staging"))throw new IOException("Content staging ownership changed.");
                                Directory.Delete(stage,true);
                            }
                        }
                    }
                    registration=ContentRegistration(Child(pack,"Library"),root);
                }
                registration.VerifyCatalog();
                if(checkpoint!=null)checkpoint("content-ready");
                // Only a complete verified library becomes active. This independent
                // transaction also supports managing content without a plugin update.
                WriteAtomic(state,new UTF8Encoding(false).GetBytes(registration.Serialize()));
                return registration.Root;
            }
        }
        public string Install(InstallPaths paths) { return Install(paths, null); }
        // Checkpoints support bounded cancellation and the owned failure fixture.
        // Callbacks never arrive from an installed library entry or package data.
        public string Install(InstallPaths paths, Action<string> checkpoint) {
            CheckAction();
            if(LibraryAction!="Keep")InstallLibrary(paths,checkpoint);
            externalFiles.Clear();PayloadBytes=corePayloadBytes;
            string root=InstallPaths.Full(Path.Combine(paths.Scripts,"CyrusScatter")); Directory.CreateDirectory(root);
            using(var installLock=new FileStream(Path.Combine(root,"install.lock"),FileMode.OpenOrCreate,FileAccess.ReadWrite,FileShare.None)) {
                Recover(paths);
                string runtime=paths.RuntimeRoot??root;
                string release=Child(runtime,paths.RuntimeRoot==null?"Releases/"+Version+"-"+ContentID:"r/"+ContentID);
                string stage=Child(runtime,"s/"+Guid.NewGuid().ToString("N").Substring(0,12));
                CheckDestination(release);CheckDestination(stage);
                string[] targets=Targets(paths); var before=new byte[targets.Length][]; var after=new byte[targets.Length][];
                for(int i=0;i<targets.Length;++i) { InstallPaths.Full(targets[i]); before[i]=ReadOptional(targets[i]); if(before[i]!=null&&before[i].Length>2*1024*1024)throw new IOException("Installation target exceeds bounds."); }
                // A previous current receipt owns only the registered wrapper files.
                // Unknown custom startup/macros cannot silently be replaced.
                bool legacyWrappers=CheckWrappers(before,targets,Year);
                CheckRegistration(paths,targets,before);
                string contentStore=null,previous=null;
                var fallback=LegacyRegistration(paths,runtime,root,before[2]);
                string statePath=StatePath(paths);
                var registered=LibraryLocation.Read(statePath);
                if(registered!=null&&registered.Supports(Int32.Parse(Year)))registered.VerifyCatalog();
                byte[] bindingBytes=new UTF8Encoding(false).GetBytes(LibraryLocation.BindingText(statePath,fallback));
                long requiredPayload=bindingBytes.Length;
                foreach(var item in files)if(!File.Exists(Child(release,Relative(item))))requiredPayload+=item.Bytes;
                var volumes=new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                foreach(string destination in new[]{root,runtime,paths.Startup,paths.Macros,paths.Profile})volumes.Add(Path.GetPathRoot(destination));
                foreach(string volume in volumes) {
                    RequireSpace(volume,volume.Equals(Path.GetPathRoot(runtime),StringComparison.OrdinalIgnoreCase)?requiredPayload:0);
                }
                bool staged=false;
                try {
                    foreach(var entry in files)Verify(Child(source,entry.Source),entry);
                    if(checkpoint!=null)checkpoint("verified");
                    if(Directory.Exists(release)) {
                        // Repair missing owned files; never overwrite changed bytes.
                        foreach(var entry in AllFiles) { string path=Child(release,Relative(entry)); if(File.Exists(path))Verify(path,entry); }
                        foreach(var entry in AllFiles) { string path=Child(release,Relative(entry)); if(!File.Exists(path))InstallFile(entry,path,contentStore,previous,checkpoint); }
                        string binding=Child(release,"LibraryBinding.txt");
                        // Preserve the release's fallback after repeated plugin-only
                        // repairs. Its stable state path must still be the same.
                        if(File.Exists(binding)) {
                            string[] lines=File.ReadAllLines(binding);
                            if(lines.Length<2||lines[0]!="CyrusLibraryBinding1"||lines[1]!=statePath)throw new IOException("The installed library binding was edited; it was preserved.");
                        }else WriteAtomic(binding,bindingBytes);
                    }
                    else {
                        Directory.CreateDirectory(stage); staged=true;
                        foreach(var entry in AllFiles) {
                            string path=Child(stage,Relative(entry)),from=SourcePath(entry);
                            try { InstallFile(entry,path,contentStore,previous,checkpoint); }
                            catch(IOException error){throw new IOException("Copy failed. Source: "+from+" Destination: "+path+". "+error.Message,error);}
                            if(checkpoint!=null)checkpoint("copied:"+entry.Name);
                        }
                        WriteAtomic(Child(stage,"LibraryBinding.txt"),bindingBytes);
                        Directory.CreateDirectory(Path.GetDirectoryName(release)); MoveDirectory(stage,release); staged=false;
                    }
                    // The stable loader follows the module that Max actually loaded,
                    // so a publication interruption cannot mix loose script/native pairs.
                    after[0]=File.ReadAllBytes(Child(source,"CyrusScatterStartup.ms"));
                    after[1]=File.ReadAllBytes(Child(source,"CyrusScatter.mcr"));
                    after[2]=Text(Marker+"\n"+Version+"\n"+release+"\n"+Hash(after[0])+"\n"+Hash(after[1])+"\n");
                    after[3]=Registration(before[3],Path.Combine(release,"bin"),Year);
                    for(int i=0;i<targets.Length;++i)if(!Equal(ReadOptional(targets[i]),before[i]))throw new IOException("An installation target changed during preparation; retry.");
                    if(legacyWrappers)PreserveLegacyWrappers(root,targets,before,checkpoint);
                    for(int i=0;i<targets.Length;++i)if(!Equal(ReadOptional(targets[i]),before[i]))throw new IOException("An installation target changed during backup; it was preserved: "+targets[i]);
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
                        if(Path.GetDirectoryName(checkedStage)!=Child(runtime,"s"))throw new IOException("Staging ownership changed.");
                        Directory.Delete(checkedStage,true);
                    }
                }
            }
        }
        public static void RemoveRegistration(InstallPaths paths,string year="2027") {
            CheckYear(year);
            string root=InstallPaths.Full(Path.Combine(paths.Scripts,"CyrusScatter"));
            if(!Directory.Exists(root))return;
            using(var installLock=new FileStream(Path.Combine(root,"install.lock"),FileMode.OpenOrCreate,FileAccess.ReadWrite,FileShare.None)) {
                Recover(paths); var targets=Targets(paths); var before=new byte[targets.Length][]; var after=new byte[targets.Length][];
                for(int i=0;i<targets.Length;++i)before[i]=ReadOptional(targets[i]);
                if(before[2]==null)throw new IOException("No owned installation receipt was found. No registration was removed.");
                string[] record=Decode(before[2]).Replace("\r","").Split('\n');
                if(record.Length!=6||record[0]!=Marker||!Hex(record[3],64)||!Hex(record[4],64))throw new IOException("The installation receipt differs. No registration was removed.");
                string release=InstallPaths.Full(record[2]);
                bool legacy=release.StartsWith(Path.Combine(root,"Releases")+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase);
                bool compact=paths.RuntimeRoot!=null&&release.StartsWith(Path.Combine(paths.RuntimeRoot,"r")+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase);
                if(!legacy&&!compact)throw new IOException("Installation ownership differs.");
                for(int i=0;i<2;++i)if(before[i]!=null&&Hash(before[i])!=record[i+3])throw new IOException("A startup/macro file was edited; it was preserved: "+targets[i]);
                string native=Path.Combine(release,"bin");bool directories=false;int registrations=0;
                foreach(string raw in Decode(before[3]).Replace("\r","").Split('\n')) {
                    string line=raw.Trim();
                    if(line.StartsWith("[")&&line.EndsWith("]"))directories=line.Equals("[Directories]",StringComparison.OrdinalIgnoreCase);
                    int equals=line.IndexOf('=');
                    if(directories&&equals>=0&&line.Substring(0,equals).Trim().Equals("CyrusScatter"+year,StringComparison.OrdinalIgnoreCase)) {
                        if(!line.Substring(equals+1).Trim().Equals(native,StringComparison.OrdinalIgnoreCase))throw new IOException("The native registration changed externally. It was preserved.");
                        ++registrations;
                    }
                }
                if(registrations!=1)throw new IOException("The native registration changed externally. It was preserved.");
                // Removing registration retains versioned recovery files, bundled
                // libraries, imported textures and personal recipes by design.
                after[3]=Registration(before[3],null,year);
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
