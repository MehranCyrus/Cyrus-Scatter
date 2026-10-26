#nullable disable
// Shared immutable byte-store primitives. No Max API or UI ownership.
using System;
using System.IO;
using System.Security.Cryptography;
using System.Runtime.InteropServices;
using System.ComponentModel;

namespace Cyrus.Content {
    public static class ContentObjects {
        [ThreadStatic] internal static Action Checkpoint=null;
        static byte[] Digest(Stream input,SHA256 hash) {
            var buffer=new byte[262144];int count;
            while((count=input.Read(buffer,0,buffer.Length))>0){hash.TransformBlock(buffer,0,count,null,0);if(Checkpoint!=null)Checkpoint();}
            hash.TransformFinalBlock(new byte[0],0,0);return hash.Hash;
        }
        [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]
        static extern bool CreateHardLink(string destination,string existing,IntPtr reserved);
        [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]
        static extern bool MoveFileEx(string existing,string destination,int flags);
        [StructLayout(LayoutKind.Sequential)] struct StandardInfo {public long allocation,endOfFile;public uint links;public byte deletePending,directory;}
        [StructLayout(LayoutKind.Sequential)] struct FileInfoData {public uint attributes;public System.Runtime.InteropServices.ComTypes.FILETIME creation,access,write;public uint volume,sizeHigh,sizeLow,links,indexHigh,indexLow;}
        [DllImport("kernel32.dll",SetLastError=true)] static extern bool GetFileInformationByHandle(IntPtr handle,out FileInfoData data);
        public static string FileIdentity(string path) {
            using(var file=new FileStream(LibraryLocation.Full(path),FileMode.Open,FileAccess.Read,FileShare.ReadWrite|FileShare.Delete)){
                FileInfoData data;if(!GetFileInformationByHandle(file.SafeFileHandle.DangerousGetHandle(),out data))throw new Win32Exception(Marshal.GetLastWin32Error(),"Cannot verify file allocation identity.");return data.volume+":"+data.indexHigh+":"+data.indexLow;
            }
        }
        [DllImport("kernel32.dll",SetLastError=true)] static extern bool GetFileInformationByHandleEx(IntPtr handle,int kind,out StandardInfo data,uint size);
        public static long AllocatedBytes(string path) {
            using(var file=new FileStream(LibraryLocation.Full(path),FileMode.Open,FileAccess.Read,FileShare.ReadWrite|FileShare.Delete)){
                StandardInfo data;if(!GetFileInformationByHandleEx(file.SafeFileHandle.DangerousGetHandle(),1,out data,(uint)Marshal.SizeOf(typeof(StandardInfo))))throw new Win32Exception(Marshal.GetLastWin32Error(),"Cannot measure object allocation.");return data.allocation;
            }
        }

        public static string Hash(string path) {
            using(var input=new FileStream(LibraryLocation.Full(path),FileMode.Open,FileAccess.Read,FileShare.Read))
            using(var hash=SHA256.Create())return BitConverter.ToString(Digest(input,hash)).Replace("-","").ToLowerInvariant();
        }
        public static void Verify(string path,string digest,long bytes) {
            if(!LibraryLocation.IsHash(digest)||bytes<0)throw new IOException("Invalid stored object descriptor.");
            path=LibraryLocation.Full(path);
            using(var input=new FileStream(path,FileMode.Open,FileAccess.Read,FileShare.Read)) {
                if(input.Length!=bytes)throw new IOException("Stored object size differs: "+Path.GetFileName(path));
                using(var hash=SHA256.Create())if(BitConverter.ToString(Digest(input,hash)).Replace("-","").ToLowerInvariant()!=digest)
                    throw new IOException("Stored object content differs; original data was preserved: "+Path.GetFileName(path));
            }
        }
        public static void Link(string existing,string destination) {
            existing=LibraryLocation.Full(existing);destination=LibraryLocation.Full(destination);
            Directory.CreateDirectory(Path.GetDirectoryName(destination));
            if(!CreateHardLink(destination,existing,IntPtr.Zero))
                throw new IOException("Cannot share immutable content on this volume. Windows error "+Marshal.GetLastWin32Error()+": "+destination);
        }
        public static void AtomicNew(string staged,string destination) {
            staged=LibraryLocation.Full(staged);destination=LibraryLocation.Full(destination);
            if(!MoveFileEx(staged,destination,8))throw new Win32Exception(Marshal.GetLastWin32Error(),"Cannot publish verified content.");
        }
        // The caller owns content.lock. Never overwrite an existing hash object.
        public static string Ingest(string root,string source,string digest,long bytes,Action checkpoint=null) {
            root=LibraryLocation.Full(root);source=LibraryLocation.Full(source);
            if(!LibraryLocation.IsHash(digest)||bytes<=0)throw new IOException("Invalid immutable content descriptor.");
            var objects=Path.Combine(root,"objects");Directory.CreateDirectory(objects);
            var target=Path.Combine(objects,digest);
            if(File.Exists(target)){Verify(target,digest,bytes);return target;}
            var staging=Path.Combine(root,"staging");Directory.CreateDirectory(staging);
            var temporary=Path.Combine(staging,"object-"+Guid.NewGuid().ToString("N"));
            try {
                using(var input=new FileStream(source,FileMode.Open,FileAccess.Read,FileShare.Read))
                using(var output=new FileStream(temporary,FileMode.CreateNew,FileAccess.Write,FileShare.None))
                using(var hash=SHA256.Create()) {
                    if(input.Length!=bytes)throw new IOException("Source changed before ingestion.");
                    var buffer=new byte[262144];long total=0;int count;
                    while((count=input.Read(buffer,0,buffer.Length))>0) {
                        total=checked(total+count);if(total>bytes)throw new IOException("Source grew during ingestion.");
                        hash.TransformBlock(buffer,0,count,null,0);output.Write(buffer,0,count);if(checkpoint!=null)checkpoint();
                    }
                    hash.TransformFinalBlock(new byte[0],0,0);
                    if(total!=bytes||BitConverter.ToString(hash.Hash).Replace("-","").ToLowerInvariant()!=digest)
                        throw new IOException("Source changed or has an incorrect hash.");
                    output.Flush(true);
                }
                Verify(temporary,digest,bytes);AtomicNew(temporary,target);return target;
            }finally{if(File.Exists(temporary))File.Delete(temporary);}
        }
        public static void View(string root,string source,string destination,string digest,long bytes,Action checkpoint=null) {
            var blob=Ingest(root,source,digest,bytes,checkpoint);
            if(File.Exists(destination)){Verify(destination,digest,bytes);return;}
            Link(blob,destination);
        }
    }
}
