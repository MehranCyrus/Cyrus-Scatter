// Actual combined EXE handlers; all destination profiles are replaced first.
// Does not invoke Program.Main or load native plugins. Only owned paths mutate.
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Windows.Forms;

static class Installer0869Checks {
    const BindingFlags Fields=BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.Instance;
    static readonly string[] Years={"2024","2026","2027"};
    static Assembly assembly;
    static string root,libraryState;
    static int checks;
    static string Hash(byte[] bytes){using(var sha=SHA256.Create())return BitConverter.ToString(sha.ComputeHash(bytes)).Replace("-","").ToLowerInvariant();}
    static string FileHash(string path){return Hash(File.ReadAllBytes(path));}
    static void Check(bool value,string label){if(!value)throw new Exception(label);++checks;Console.WriteLine("PASS "+label);}
    static object Field(object value,string name){return value.GetType().GetField(name,Fields).GetValue(value);}
    static string[] Targets(string folder){return new[]{Path.Combine(folder,"u/CyrusScatterStartup.ms"),Path.Combine(folder,"m/CyrusScatter.mcr"),Path.Combine(folder,"s/CyrusScatter/installed.txt"),Path.Combine(folder,"u/CyrusSurfaceAnalyzerStartup.ms"),Path.Combine(folder,"s/CyrusSurfaceAnalyzer/installed.txt"),Path.Combine(folder,"Plugin.UserSettings.ini")};}
    static string Snapshot(string folder){return String.Join("|",Array.ConvertAll(Targets(folder),p=>File.Exists(p)?Convert.ToBase64String(File.ReadAllBytes(p)):"ABSENT"));}
    static string Profile(string group,string year){
        string folder=Path.Combine(root,group,year);Directory.CreateDirectory(folder);
        foreach(string d in new[]{"s","u","m","cs"})Directory.CreateDirectory(Path.Combine(folder,d));
        File.WriteAllText(Path.Combine(folder,"max.ini"),"[Directories]\nAdditional Scripts="+Path.Combine(folder,"s")+"\nAdditional Startup Scripts="+Path.Combine(folder,"u")+"\nAdditional Macros="+Path.Combine(folder,"m")+"\n",Encoding.Unicode);
        File.WriteAllText(Path.Combine(folder,"Plugin.UserSettings.ini"),"[Directories]\nUnrelatedOwned=C:\\Preserve\\Plugins\n",Encoding.Unicode);
        File.Copy(libraryState,Path.Combine(folder,"cs/library-state.txt"));
        return folder;
    }
    static Dictionary<string,string> Profiles(string group){var result=new Dictionary<string,string>();foreach(string year in Years)result.Add(year,Profile(group,year));return result;}
    static Form Window(Dictionary<string,string> destinations){
        var type=assembly.GetType("Cyrus.Setup.SetupWindow",true);var form=(Form)Activator.CreateInstance(type,true);
        form.ShowInTaskbar=false;form.Opacity=0;form.StartPosition=FormStartPosition.Manual;form.Location=new System.Drawing.Point(-32000,-32000);
        var profiles=(IDictionary)Field(form,"profiles");profiles.Clear();
        foreach(var entry in destinations)profiles.Add(entry.Key,Path.Combine(entry.Value,"max.ini"));
        var hosts=(IDictionary)Field(form,"hosts");
        Check(hosts.Count==3&&hosts.Contains("2024")&&hosts.Contains("2026")&&hosts.Contains("2027"),"EXE presents exactly the three requested host cards");
        foreach(DictionaryEntry entry in hosts){var pick=(CheckBox)entry.Value;pick.Enabled=destinations.ContainsKey((string)entry.Key);pick.Checked=pick.Enabled;}
        // Bypass only process discovery after every possible action target has
        // been replaced by verified disposable profiles. This never controls Max.
        type.GetField("hostRunning",Fields).SetValue(form,new Func<string,bool>(year=>{if(!destinations.ContainsKey(year))throw new Exception("Unexpected host");return false;}));
        ((CheckBox)Field(Field(form,"view"),"InstallContent")).Checked=false;
        type.GetMethod("RefreshSelection",Fields).Invoke(form,null);form.Show();Application.DoEvents();return form;
    }
    static string Run(Form form){
        SynchronizationContext.SetSynchronizationContext(new WindowsFormsSynchronizationContext());
        ((Button)Field(Field(form,"view"),"Primary")).PerformClick();
        var deadline=DateTime.UtcNow.AddSeconds(120);
        do{Application.DoEvents();Thread.Sleep(10);if(DateTime.UtcNow>deadline)throw new TimeoutException("Owned EXE action unresolved");}while((bool)Field(form,"busy"));
        Application.DoEvents();var view=Field(form,"view");
        string status=((Label)Field(view,"Status")).Text;Console.WriteLine("STATUS "+status);Console.WriteLine(((TextBox)Field(view,"Details")).Text);return status;
    }
    static Dictionary<string,byte[]> Payload(string resource){
        var result=new Dictionary<string,byte[]>();
        using(var stream=assembly.GetManifestResourceStream(resource)){
            if(stream==null)throw new Exception("Missing resource "+resource);
            using(var archive=new ZipArchive(stream,ZipArchiveMode.Read))foreach(var entry in archive.Entries)
                using(var input=entry.Open())using(var memory=new MemoryStream()){input.CopyTo(memory);result.Add(entry.FullName,memory.ToArray());}
        }
        return result;
    }
    static string VerifyInstall(string folder,string year){
        var scatter=Payload("Cyrus.Payload."+year+".mzp");var analyzer=Payload("Cyrus.Analyzer."+year+".mzp");
        string[] record=File.ReadAllLines(Targets(folder)[2]);Check(record[1]=="0.86.9",year+" current Scatter receipt");
        string runtime=record[2];Check(runtime.StartsWith(folder+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase),year+" Scatter runtime is owned");
        foreach(string name in new[]{"AminScatter.dlx","CyrusBrush.dlx","CyrusBrushStorage.dlh","CyrusScatterEdit.dlm"})
            Check(FileHash(Path.Combine(runtime,"bin",name))==Hash(scatter[name]),year+" exact embedded native "+name);
        foreach(string name in new[]{"CyrusScatter.ms","CyrusGallery.dll"})
            Check(FileHash(Path.Combine(runtime,name))==Hash(scatter[name]),year+" exact embedded managed/script "+name);
        record=File.ReadAllLines(Targets(folder)[4]);Check(record[1]==year&&record[2]=="0.14.2",year+" independent Analyzer receipt");
        string analyzerRuntime=Path.Combine(folder,"s/CyrusSurfaceAnalyzer/r",record[3]);
        Check(FileHash(Path.Combine(analyzerRuntime,"bin/CyrusSurfaceAnalyzer.dlx"))==Hash(analyzer["CyrusSurfaceAnalyzer.dlx"]),year+" exact embedded Analyzer native");
        Check(FileHash(Path.Combine(analyzerRuntime,"CyrusSurfaceAnalyzer.ms"))==Hash(analyzer["CyrusSurfaceAnalyzer.ms"]),year+" exact embedded Analyzer script");
        string ini=File.ReadAllText(Path.Combine(folder,"Plugin.UserSettings.ini"));
        Check(ini.Contains("UnrelatedOwned=C:\\Preserve\\Plugins")&&ini.Contains("CyrusScatter"+year+"=")&&ini.Contains("CyrusSurfaceAnalyzer"+year+"="),year+" both product registrations preserve unrelated INI entry");
        Check(FileHash(Path.Combine(folder,"cs/library-state.txt"))==FileHash(libraryState)&&!Directory.Exists(Path.Combine(folder,"cs/Library")),year+" plugin-only action preserves existing library without copying it");
        File.WriteAllText(Path.Combine(folder,"installed-runtime.tsv"),year+"\t"+runtime+"\t"+analyzerRuntime+"\n");
        return runtime;
    }
    static string GroupSnapshot(Dictionary<string,string> profiles){var rows=new List<string>();foreach(string year in Years)rows.Add(year+"="+Snapshot(profiles[year]));return String.Join("\n",rows);}
    [STAThread] static int Main(string[] args){try{
        string executable=Path.GetFullPath(args[0]);root=Path.GetFullPath(args[2]);libraryState=Path.GetFullPath(args[3]);
        if(FileHash(executable)!=args[1])throw new Exception("EXE identity differs");
        if(Directory.Exists(root))throw new Exception("Fresh profile output is required");Directory.CreateDirectory(root);
        assembly=Assembly.LoadFrom(executable);Application.EnableVisualStyles();Application.SetCompatibleTextRenderingDefault(false);
        var profiles=Profiles("installed");
        using(var form=Window(profiles)){
            Check(Run(form).StartsWith("Installation completed"),"Actual Install click completes Scatter and Analyzer for all three hosts");
            foreach(string year in Years)VerifyInstall(profiles[year],year);
            string before=GroupSnapshot(profiles);
            Check(((Button)Field(Field(form,"view"),"Primary")).Text=="Update","Installed selection changes primary action to Update");
            Check(Run(form).StartsWith("Installation completed")&&GroupSnapshot(profiles)==before,"Actual repeated Update preserves all six product bindings");
            string details=((TextBox)Field(Field(form,"view"),"Details")).Text;
            foreach(string year in Years)Check(details.Contains("Completed Scatter 0.86.9 for Max "+year)&&details.Contains("Completed Surface Analyzer 0.14.2 for Max "+year),year+" reports distinct completed product actions");
        }
        // Refuse each host's unknown registration before installing any of the
        // selected hosts. Existing files are observed independently of log text.
        foreach(string blockedYear in Years){
            var custom=Profiles("custom"+blockedYear);
            File.AppendAllText(Path.Combine(custom[blockedYear],"Plugin.UserSettings.ini"),"CyrusScatter"+blockedYear+"=C:\\Custom\\Plugins\n",Encoding.Unicode);
            string before=GroupSnapshot(custom);
            using(var form=Window(custom))Check(Run(form).StartsWith("Could not finish")&&GroupSnapshot(custom)==before,blockedYear+" custom registration blocks before publishing any selected host");
        }
        Check(FileHash(executable)==args[1],"Exact tested EXE remains unchanged");Console.WriteLine("CHECKS "+checks);return 0;
    }catch(Exception error){Console.Error.WriteLine(error);return 1;}}
}
