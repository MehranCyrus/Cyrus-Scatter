// Create-only backup publication. Callers hold their product installation lock.
using System;
using System.IO;

namespace Cyrus.Setup {
    internal static class VerifiedBackup {
        internal const int Limit=2*1024*1024;
        internal static void CheckPath(string path) {
            InstallPaths.Full(path);
            if(path.Length>=260||Path.GetDirectoryName(path).Length>=248)
                throw new IOException("Backup destination exceeds the supported path length: "+path);
        }
        static void Verify(string path,byte[] bytes) {
            CheckPath(path);
            if(!InstallEngine.Equal(InstallEngine.ReadBounded(path,Limit),bytes))
                throw new IOException("A verified backup differs and was preserved. Review this file before retrying: "+path);
        }
        internal static void Publish(string path,byte[] bytes,Action<string> checkpoint,string label) {
            if(bytes==null||bytes.Length>Limit)throw new IOException("Backup exceeds its byte allowance: "+path);
            CheckPath(path);
            if(File.Exists(path)){Verify(path,bytes);return;}
            if(Directory.Exists(path))throw new IOException("A backup destination is an existing directory: "+path);
            InstallEngine.RequireSpace(path,checked(bytes.LongLength*2));
            string directory=Path.GetDirectoryName(path);
            string temporary=Path.Combine(directory,".backup-"+Guid.NewGuid().ToString("N").Substring(0,12));
            CheckPath(temporary);Directory.CreateDirectory(directory);
            Action<string> step=phase=>{if(checkpoint!=null)checkpoint("backup:"+label+":"+phase);};
            step("before-create");
            // A failed/terminated process may leave this uniquely owned temporary
            // file. Retry never consumes it or deletes unknown temporary files.
            using(var output=new FileStream(temporary,FileMode.CreateNew,FileAccess.Write,FileShare.None)) {
                int first=Math.Min(32768,bytes.Length/2);
                output.Write(bytes,0,first);step("partial-write");
                for(int offset=first;offset<bytes.Length;) {
                    int count=Math.Min(65536,bytes.Length-offset);output.Write(bytes,offset,count);offset+=count;
                }
                step("before-flush");output.Flush(true);step("after-flush");
            }
            step("before-verify");Verify(temporary,bytes);step("verified");
            step("before-move");CheckPath(path);CheckPath(temporary);
            try { File.Move(temporary,path); }
            catch(IOException) {
                // No replacement semantics: an equal published file may be
                // reused, but differing bytes are retained and reported.
                if(!File.Exists(path))throw;
                Verify(path,bytes);Verify(temporary,bytes);File.Delete(temporary);
            }
            step("after-move");Verify(path,bytes);
        }
        internal static string MigrationRecord(string original,string legacy,string current,byte[] bytes) {
            CheckPath(legacy);CheckPath(current);
            string observed="absent";
            if(File.Exists(legacy)) {
                long size=new FileInfo(legacy).Length;
                observed=size>Limit?"oversize:"+size:InstallEngine.Hash(InstallEngine.ReadBounded(legacy,Limit));
            }
            return original+"\t"+InstallEngine.Hash(bytes)+"\t"+legacy+"\t"+observed+"\t"+current+"\n";
        }
    }
}
