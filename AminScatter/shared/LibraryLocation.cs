#nullable disable
using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;

namespace Cyrus.Content {
    // Shared by the installer and the host-specific gallery. Data only: no Max API.
    public sealed class LibraryRegistration {
        public string Root, Revision, CatalogHash, ManifestHash, ManagedRoot, PackId;
        public int MinimumHost;
        public bool Supports(int year) { return (year==2024||year==2026||year==2027)&&MinimumHost<=year; }
        public string[] Fields() { return new[]{Root,Revision,CatalogHash,ManifestHash,MinimumHost.ToString(System.Globalization.CultureInfo.InvariantCulture),ManagedRoot??"",PackId}; }
        public static LibraryRegistration FromFields(string[] fields,int offset) {
            if(fields.Length<offset+7)throw new IOException("Incomplete library registration.");
            int year;
            if(!Int32.TryParse(fields[offset+4],out year)||(year!=2024&&year!=2026&&year!=2027)||
               !Regex.IsMatch(fields[offset+1],@"^[a-zA-Z0-9][a-zA-Z0-9._-]{0,63}$")||
               !LibraryLocation.IsHash(fields[offset+2])||!LibraryLocation.IsHash(fields[offset+3])||
               fields[offset+6]!="cyrus-plants")throw new IOException("Invalid library registration.");
            return new LibraryRegistration {Root=LibraryLocation.Full(fields[offset]),Revision=fields[offset+1],
                CatalogHash=fields[offset+2],ManifestHash=fields[offset+3],MinimumHost=year,
                ManagedRoot=fields[offset+5].Length==0?"":LibraryLocation.Full(fields[offset+5]),PackId=fields[offset+6]};
        }
        public string Serialize() { return "CyrusLibrary1\n"+String.Join("\n",Fields())+"\n"; }
        public void VerifyCatalog() {
            string catalog=Path.Combine(Root,"model-catalog.json");
            LibraryLocation.Full(catalog);
            var info=new FileInfo(catalog);
            if(!info.Exists||info.Length<1||info.Length>2*1024*1024||LibraryLocation.Hash(catalog)!=CatalogHash)
                throw new IOException("The selected library catalog is missing or changed. Use Manage library to repair or choose its folder.");
        }
    }

    public static class LibraryLocation {
        public static bool IsHash(string value) { return value!=null&&Regex.IsMatch(value,@"^[a-f0-9]{64}$"); }
        public static string Hash(string path) {
            using(var input=File.OpenRead(path))using(var hash=SHA256.Create())
                return BitConverter.ToString(hash.ComputeHash(input)).Replace("-","").ToLowerInvariant();
        }
        public static string Full(string path) {
            if(String.IsNullOrWhiteSpace(path)||!Path.IsPathRooted(path)||path.IndexOf('\n')>=0||path.IndexOf('\r')>=0)
                throw new IOException("An absolute local library path is required.");
            string result=Path.GetFullPath(path).TrimEnd(Path.DirectorySeparatorChar);
            if(result.StartsWith(@"\\",StringComparison.Ordinal)||result.Length<4||result.Length>=248)
                throw new IOException("Choose a short local library path.");
            for(string at=result;!String.IsNullOrEmpty(at);at=Path.GetDirectoryName(at))
                if((File.Exists(at)||Directory.Exists(at))&&(File.GetAttributes(at)&FileAttributes.ReparsePoint)!=0)
                    throw new IOException("Library paths cannot traverse linked folders: "+at);
            return result;
        }
        static string[] ReadLines(string path) {
            Full(path);
            using(var stream=new FileStream(path,FileMode.Open,FileAccess.Read,FileShare.Read)) {
                if(stream.Length>16384)throw new IOException("Library registration exceeds its bound.");
                using(var reader=new StreamReader(stream,new UTF8Encoding(false,true),true))
                    return reader.ReadToEnd().Replace("\r","").TrimEnd('\n').Split('\n');
            }
        }
        public static LibraryRegistration Read(string path) {
            if(!File.Exists(path))return null;
            var fields=ReadLines(path);
            if(fields.Length!=8||fields[0]!="CyrusLibrary1")throw new IOException("Library registration differs.");
            return LibraryRegistration.FromFields(fields,1);
        }
        public static string BindingText(string statePath,LibraryRegistration fallback) {
            return "CyrusLibraryBinding1\n"+Full(statePath)+"\n"+
                (fallback==null?"":String.Join("\n",fallback.Fields())+"\n");
        }
        public static LibraryRegistration Resolve(string runtime,int year) {
            string path=Path.Combine(Full(runtime),"LibraryBinding.txt");
            if(!File.Exists(path))return null;
            var fields=ReadLines(path);
            if((fields.Length!=2&&fields.Length!=9)||fields[0]!="CyrusLibraryBinding1")
                throw new IOException("Installed library binding differs. Repair the plugin.");
            LibraryRegistration selected=Read(Full(fields[1]));
            if(selected!=null&&selected.Supports(year)){selected.VerifyCatalog();return selected;}
            var fallback=fields.Length==9?LibraryRegistration.FromFields(fields,2):null;
            if(fallback!=null&&fallback.Supports(year)){fallback.VerifyCatalog();return fallback;}
            if(selected!=null)throw new IOException("This library requires Max "+selected.MinimumHost+". Choose compatible content in Manage library.");
            return null;
        }
        public static string ResolveRoot(string runtime,int year) {
            var registration=Resolve(runtime,year);
            return registration==null?"":registration.Root;
        }
    }
}
