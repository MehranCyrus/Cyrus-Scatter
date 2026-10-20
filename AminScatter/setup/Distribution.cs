using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Text;

namespace Cyrus.Setup {
    // The EXE embeds the exact verified MZP. It does not execute extracted scripts.
    public static class Distribution {
        public static InstallPaths FromProfile(string ini,string year="2027") {
            InstallEngine.CheckYear(year);
            ini=InstallPaths.Full(ini);
            foreach(string part in ini.Split(Path.DirectorySeparatorChar))
                if(System.Text.RegularExpressions.Regex.IsMatch(part,@"^20[0-9]{2} - 64bit$",System.Text.RegularExpressions.RegexOptions.IgnoreCase)&&part!=year+" - 64bit")
                    throw new IOException("Select the profile for Max "+year+", or change the host selection.");
            if(!File.Exists(ini)||new FileInfo(ini).Length>2*1024*1024)throw new IOException("Select an initialized Max "+year+" profile INI.");
            var values=new Dictionary<string,string>(StringComparer.OrdinalIgnoreCase);
            using(var reader=new StreamReader(ini,Encoding.UTF8,true)) {
                string line;bool directories=false;
                while((line=reader.ReadLine())!=null) {
                    line=line.Trim();
                    if(line.StartsWith("[")&&line.EndsWith("]")) { directories=line.Equals("[Directories]",StringComparison.OrdinalIgnoreCase);continue; }
                    int at=line.IndexOf('=');if(!directories||at<0)continue;
                    string name=line.Substring(0,at).Trim();
                    if(name!="Additional Scripts"&&name!="Additional Startup Scripts"&&name!="Additional Macros")continue;
                    if(values.ContainsKey(name))throw new IOException("Ambiguous profile directory: "+name);
                    values.Add(name,Environment.ExpandEnvironmentVariables(line.Substring(at+1).Trim()));
                }
            }
            foreach(string name in new[]{"Additional Scripts","Additional Startup Scripts","Additional Macros"})
                if(!values.ContainsKey(name))throw new IOException("Profile directory missing: "+name+". Open Max "+year+" once before installing, or run the matching MZP inside Max.");
            return InstallPaths.ForMax(values["Additional Scripts"],values["Additional Startup Scripts"],values["Additional Macros"],Path.GetDirectoryName(ini),year);
        }
        public static string FindProfile(string year) {
            InstallEngine.CheckYear(year);
            string root=InstallPaths.Full(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),@"Autodesk\3dsMax\"+year+" - 64bit"));
            string english=Path.Combine(root,"ENU","3dsMax.ini");
            if(File.Exists(english)){FromProfile(english,year);return english;}
            string found=null;
            if(Directory.Exists(root)) {
                string[] children=Directory.GetDirectories(root);if(children.Length>64)throw new IOException("Too many Max profile folders. Use the matching MZP inside Max.");
                foreach(string child in children) {
                    string candidate=Path.Combine(child,"3dsMax.ini");if(!File.Exists(candidate))continue;
                    FromProfile(candidate,year);
                    if(found!=null)throw new IOException("Multiple Max language profiles found. Run the matching MZP inside the Max profile you use.");
                    found=candidate;
                }
            }
            if(found==null)throw new IOException("Open Max "+year+" once to initialize it, close it, then try Install again.");
            return found;
        }
        public static string DetectMax(string year) {
            InstallEngine.CheckYear(year);
            // Read the host's registered installation before the conventional
            // folder so installations on another drive are discovered as well.
            using(var key=Microsoft.Win32.Registry.LocalMachine.OpenSubKey(@"SOFTWARE\Autodesk\3dsMax\"+(Int32.Parse(year)-1998)+".0")) {
                string registered=key==null?null:key.GetValue("Installdir") as string;
                if(!String.IsNullOrWhiteSpace(registered)) {
                    string executable=Path.Combine(registered,"3dsmax.exe");
                    if(File.Exists(executable)&&System.Diagnostics.FileVersionInfo.GetVersionInfo(executable).FileMajorPart==Int32.Parse(year)-1998)return executable;
                }
            }
            string standard=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),@"Autodesk\3ds Max "+year+@"\3dsmax.exe");
            if(File.Exists(standard)&&System.Diagnostics.FileVersionInfo.GetVersionInfo(standard).FileMajorPart==Int32.Parse(year)-1998)return standard;
            // Do not search drives or infer a host from an old profile alone.
            throw new IOException("Max "+year+" was not found. For an unregistered installation, use Scripting > Run Script with the matching Max "+year+" MZP.");
        }
        public static string Extract(Assembly assembly,string parent,string packageHash,Action<string> checkpoint,string resource="Cyrus.Payload.mzp") {
            parent=InstallPaths.Full(parent);Directory.CreateDirectory(parent);
            string destination=Path.Combine(parent,"p-"+Guid.NewGuid().ToString("N").Substring(0,12));Directory.CreateDirectory(destination);
            try {
                using(var payload=assembly.GetManifestResourceStream(resource)) {
                    if(payload==null||payload.Length>512L*1024*1024)throw new IOException("Embedded payload is missing or too large.");
                    using(var sha=System.Security.Cryptography.SHA256.Create()) {
                        string actual=BitConverter.ToString(sha.ComputeHash(payload)).Replace("-","").ToLowerInvariant();
                        if(actual!=packageHash)throw new IOException("Embedded package identity differs.");
                    }
                    payload.Position=0;
                    using(var archive=new ZipArchive(payload,ZipArchiveMode.Read,true)) {
                        if(archive.Entries.Count>520)throw new IOException("Package exceeds its file limit.");
                        long expanded=0;
                        foreach(var entry in archive.Entries) {
                            expanded=checked(expanded+entry.Length);
                            if(entry.Length>128L*1024*1024||expanded>512L*1024*1024)throw new IOException("Extracted package exceeds its size limit.");
                        }
                        var temporaryDrive=new DriveInfo(Path.GetPathRoot(parent));
                        if(temporaryDrive.AvailableFreeSpace<expanded+16L*1024*1024)
                            throw new IOException(String.Format("Windows temporary storage {0} needs {1:N0} bytes for the plugin payload and working space; available {2:N0}. No model or texture content is extracted here.",parent,expanded+16L*1024*1024,temporaryDrive.AvailableFreeSpace));
                        var names=new HashSet<string>(StringComparer.OrdinalIgnoreCase);long total=0;
                        foreach(var entry in archive.Entries) {
                            string name=entry.FullName;
                            if(name.Contains("\\")||name.Contains(":")||name.StartsWith("/")||!names.Add(name))throw new IOException("Invalid archive path.");
                            foreach(string part in name.Split('/'))if(part.Length==0||part=="."||part==".."||part.TrimEnd(' ','.')!=part||part.IndexOfAny(Path.GetInvalidFileNameChars())>=0)throw new IOException("Invalid archive path.");
                            total+=entry.Length;if(entry.Length>128L*1024*1024||total>512L*1024*1024)throw new IOException("Extracted package exceeds its size limit.");
                            string target=InstallPaths.Full(Path.Combine(destination,name.Replace('/',Path.DirectorySeparatorChar)));
                            if(!target.StartsWith(destination+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase))throw new IOException("Archive path escaped its staging folder.");
                            if(checkpoint!=null)checkpoint("extracting:"+name);
                            Directory.CreateDirectory(Path.GetDirectoryName(target));
                            using(var input=entry.Open())using(var output=new FileStream(target,FileMode.CreateNew,FileAccess.Write,FileShare.None)) {
                                byte[] buffer=new byte[65536];int count;long written=0;
                                while((count=input.Read(buffer,0,buffer.Length))!=0) { written+=count;if(written>entry.Length)throw new IOException("Archive entry exceeds its declared size.");output.Write(buffer,0,count); }
                                if(written!=entry.Length)throw new IOException("Archive entry is incomplete.");output.Flush(true);
                            }
                        }
                    }
                }
                return destination;
            } catch { Cleanup(parent,destination);throw; }
        }
        public static void Cleanup(string parent,string destination) {
            parent=InstallPaths.Full(parent);destination=InstallPaths.Full(destination);
            if(Path.GetDirectoryName(destination)!=parent||!System.Text.RegularExpressions.Regex.IsMatch(Path.GetFileName(destination),@"^(payload-[0-9a-f]{32}|p-[0-9a-f]{12})$"))throw new IOException("Extraction ownership differs.");
            if(Directory.Exists(destination))Directory.Delete(destination,true);
        }
    }
}
