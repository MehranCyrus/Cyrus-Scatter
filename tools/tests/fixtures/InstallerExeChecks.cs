// Exercise the shipped EXE's actual button handler against disposable profiles.
// The fixture never loads native plugins and never invokes Program.Main.
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

static class InstallerExeChecks {
    const BindingFlags Fields=BindingFlags.Public|BindingFlags.NonPublic|BindingFlags.Instance;
    static Assembly assembly;static string root,scatterOld,analyzerOld;static int checks;
    static string Hash(byte[] bytes){using(var sha=SHA256.Create())return BitConverter.ToString(sha.ComputeHash(bytes)).Replace("-","").ToLowerInvariant();}
    static string FileHash(string path){return Hash(File.ReadAllBytes(path));}
    static void Check(bool value,string label){if(!value)throw new Exception(label);++checks;Console.WriteLine("PASS "+label);}
    static object Field(object obj,string name){return obj.GetType().GetField(name,Fields).GetValue(obj);}
    static string[] Targets(string folder){return Array.ConvertAll(new[]{Path.Combine(folder,"u/CyrusScatterStartup.ms"),Path.Combine(folder,"m/CyrusScatter.mcr"),Path.Combine(folder,"s/CyrusScatter/installed.txt"),Path.Combine(folder,"u/CyrusSurfaceAnalyzerStartup.ms"),Path.Combine(folder,"s/CyrusSurfaceAnalyzer/installed.txt"),Path.Combine(folder,"Plugin.UserSettings.ini")},Path.GetFullPath);}
    static string Snapshot(string folder){return String.Join("|",Array.ConvertAll(Targets(folder),p=>File.Exists(p)?Convert.ToBase64String(File.ReadAllBytes(p)):"ABSENT"));}
    static string Profile(string name){
        string folder=Path.Combine(root,name);Directory.CreateDirectory(folder);foreach(string d in new[]{"s","u","m"})Directory.CreateDirectory(Path.Combine(folder,d));
        File.WriteAllText(Path.Combine(folder,"max.ini"),"[Directories]\nAdditional Scripts="+Path.Combine(folder,"s")+"\nAdditional Startup Scripts="+Path.Combine(folder,"u")+"\nAdditional Macros="+Path.Combine(folder,"m")+"\n",Encoding.Unicode);
        File.WriteAllText(Path.Combine(folder,"Plugin.UserSettings.ini"),"[Directories]\nUnrelatedOwned=C:\\Preserve\\Plugins\n",Encoding.Unicode);return folder;
    }
    static Form Window(string folder){
        var type=assembly.GetType("Cyrus.Setup.SetupWindow",true);var form=(Form)Activator.CreateInstance(type,true);
        form.ShowInTaskbar=false;form.Opacity=0;form.StartPosition=FormStartPosition.Manual;form.Location=new System.Drawing.Point(-32000,-32000);
        var profiles=(IDictionary)Field(form,"profiles");profiles.Clear();profiles.Add("2027",Path.Combine(folder,"max.ini"));
        foreach(DictionaryEntry pair in (IDictionary)Field(form,"hosts")){var check=(CheckBox)pair.Value;check.Enabled=(string)pair.Key=="2027";check.Checked=check.Enabled;}
        // The real process guard is substituted only after all targets were
        // replaced by this verified disposable profile. No Max is controlled.
        type.GetField("hostRunning",Fields).SetValue(form,new Func<string,bool>(year=>{if(year!="2027")throw new Exception("Unexpected host");return false;}));
        ((CheckBox)Field(Field(form,"view"),"InstallContent")).Checked=false;
        type.GetMethod("RefreshSelection",Fields).Invoke(form,null);form.Show();Application.DoEvents();return form;
    }
    static string Run(Form form,bool remove=false){
        object view=Field(form,"view");
        // Application.Run supplies this for real click callbacks. DoEvents may
        // restore the outer context, so bind it immediately before every action.
        SynchronizationContext.SetSynchronizationContext(new WindowsFormsSynchronizationContext());
        if(remove)form.GetType().GetMethod("Run",Fields).Invoke(form,new object[]{true});
        else ((Button)Field(view,"Primary")).PerformClick();
        var deadline=DateTime.UtcNow.AddSeconds(90);
        do{Application.DoEvents();Thread.Sleep(10);if(DateTime.UtcNow>deadline)throw new TimeoutException("Owned EXE handler did not finish");}while((bool)Field(form,"busy"));
        Application.DoEvents();string status=((Label)Field(view,"Status")).Text,details=((TextBox)Field(view,"Details")).Text;
        Console.WriteLine("STATUS "+status);Console.WriteLine(details);
        Console.WriteLine("PRIMARY "+((Button)Field(view,"Primary")).Text+"; context="+(SynchronizationContext.Current==null?"none":SynchronizationContext.Current.GetType().FullName));
        foreach(DictionaryEntry item in (IDictionary)Field(form,"profiles")){
            object paths=assembly.GetType("Cyrus.Setup.Distribution").GetMethod("FromProfile").Invoke(null,new object[]{item.Value,item.Key});
            string version=(string)assembly.GetType("Cyrus.Setup.InstallEngine").GetMethod("InstalledVersion").Invoke(null,new[]{paths});
            Console.WriteLine("SELECTION "+item.Key+" checked="+((CheckBox)((IDictionary)Field(form,"hosts"))[item.Key]).Checked+" installed="+version);
        }
        return status;
    }
    static byte[] Resource(string name){using(var stream=assembly.GetManifestResourceStream(name))using(var memory=new MemoryStream()){stream.CopyTo(memory);return memory.ToArray();}}
    static Dictionary<string,byte[]> Payload(string resource){
        var result=new Dictionary<string,byte[]>();using(var stream=new MemoryStream(Resource(resource)))using(var archive=new ZipArchive(stream,ZipArchiveMode.Read))
            foreach(var entry in archive.Entries)using(var input=entry.Open())using(var memory=new MemoryStream()){input.CopyTo(memory);result.Add(entry.FullName,memory.ToArray());}return result;
    }
    static void VerifyInstall(string folder,Dictionary<string,byte[]> scatter,Dictionary<string,byte[]> analyzer){
        string[] record=File.ReadAllLines(Targets(folder)[2]);Check(record[1]=="0.86.8.7","EXE installed current Scatter receipt");
        string runtime=record[2];Check(runtime.StartsWith(folder+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase),"Scatter runtime belongs to owned profile");
        foreach(string name in new[]{"AminScatter.dlx","CyrusBrush.dlx","CyrusBrushStorage.dlh","CyrusScatterEdit.dlm"})Check(FileHash(Path.Combine(runtime,"bin",name))==Hash(scatter[name]),"EXE Scatter native matches its embedded MZP: "+name);
        Check(FileHash(Path.Combine(runtime,"CyrusScatter.ms"))==Hash(scatter["CyrusScatter.ms"]),"EXE Scatter script matches its embedded MZP");
        record=File.ReadAllLines(Targets(folder)[4]);Check(record[2]=="0.14.2","EXE installed independent Analyzer receipt");
        runtime=Path.Combine(folder,"s/CyrusSurfaceAnalyzer/r",record[3]);
        Check(FileHash(Path.Combine(runtime,"bin/CyrusSurfaceAnalyzer.dlx"))==Hash(analyzer["CyrusSurfaceAnalyzer.dlx"])&&FileHash(Path.Combine(runtime,"CyrusSurfaceAnalyzer.ms"))==Hash(analyzer["CyrusSurfaceAnalyzer.ms"]),"EXE Analyzer native/script match its embedded MZP");
        Check(File.ReadAllText(Path.Combine(folder,"Plugin.UserSettings.ini")).Contains("UnrelatedOwned=C:\\Preserve\\Plugins"),"EXE preserved unrelated plugin registration");
    }
    static string[] LegacySeed(string folder){
        var targets=Targets(folder);File.Copy(Path.Combine(scatterOld,"CyrusScatterStartup.ms"),targets[0]);File.Copy(Path.Combine(scatterOld,"CyrusScatter.mcr"),targets[1]);File.Copy(Path.Combine(analyzerOld,"CyrusSurfaceAnalyzerStartup.ms"),targets[3]);
        string scatterRoot=Path.Combine(folder,"s/CyrusScatter");Directory.CreateDirectory(scatterRoot);
        string oldBackup;using(var data=new MemoryStream())using(var writer=new BinaryWriter(data,Encoding.UTF8)){
            for(int i=0;i<3;++i){byte[] bytes=i<2?File.ReadAllBytes(targets[i]):null;writer.Write(targets[i]);writer.Write(bytes==null?-1:bytes.Length);if(bytes!=null)writer.Write(bytes);}writer.Flush();oldBackup=Path.Combine(scatterRoot,"Backups/wrappers-"+Hash(data.ToArray()),"CyrusScatterStartup.ms");
        }
        Directory.CreateDirectory(Path.GetDirectoryName(oldBackup));File.WriteAllText(oldBackup,"owned poisoned Scatter backup");
        string analyzerBackup=Path.Combine(folder,"s/CyrusSurfaceAnalyzer/Backups/startup-"+FileHash(targets[3])+".ms");Directory.CreateDirectory(Path.GetDirectoryName(analyzerBackup));File.WriteAllText(analyzerBackup,"owned poisoned Analyzer backup");
        return new[]{Path.GetFullPath(oldBackup),Path.GetFullPath(analyzerBackup)};
    }
    [STAThread] static int Main(string[] args){try{
        string executable=Path.GetFullPath(args[0]);root=Path.GetFullPath(args[2]);scatterOld=Path.GetFullPath(args[3]);analyzerOld=Path.GetFullPath(args[4]);
        if(FileHash(executable)!=args[1])throw new Exception("EXE identity differs");
        Directory.CreateDirectory(root);assembly=Assembly.LoadFrom(executable);
        Application.EnableVisualStyles();Application.SetCompatibleTextRenderingDefault(false);
        var scatter=Payload("Cyrus.Payload.2027.mzp");var analyzer=Payload("Cyrus.Analyzer.2027.mzp");
        string folder=Profile("fresh");using(var form=Window(folder)){
            Check(Run(form).StartsWith("Installation completed"),"Actual EXE Install click completed both products");VerifyInstall(folder,scatter,analyzer);
            string before=Snapshot(folder);Check(((Button)Field(Field(form,"view"),"Primary")).Text=="Update","Actual EXE changed primary action to Update");
            Check(Run(form).StartsWith("Installation completed")&&Snapshot(folder)==before,"Actual EXE Update click preserves identical bindings");
            string scatterRuntime=File.ReadAllLines(Targets(folder)[2])[2],analyzerRuntime=Path.Combine(folder,"s/CyrusSurfaceAnalyzer/r",File.ReadAllLines(Targets(folder)[4])[3]);
            string missingScatter=Path.Combine(scatterRuntime,"bin/AminScatter.dlx"),missingAnalyzer=Path.Combine(analyzerRuntime,"CyrusSurfaceAnalyzer.ms");
            Check(FileHash(missingScatter)==Hash(scatter["AminScatter.dlx"])&&FileHash(missingAnalyzer)==Hash(analyzer["CyrusSurfaceAnalyzer.ms"]),"Missing-file controls target exact owned installed bytes");
            File.Delete(missingScatter);File.Delete(missingAnalyzer);
            Check(Run(form).StartsWith("Installation completed")&&Snapshot(folder)==before,"Actual EXE Update repairs missing receipt-owned files");VerifyInstall(folder,scatter,analyzer);
            byte[] analyzerReceipt=File.ReadAllBytes(Targets(folder)[4]);
            Check(Run(form,true).StartsWith("Uninstall completed")&&File.ReadAllBytes(Targets(folder)[4]).Length==analyzerReceipt.Length&&FileHash(Targets(folder)[4])==Hash(analyzerReceipt),"Actual EXE removal handler preserves independent Analyzer receipt");
            Check(!File.Exists(Targets(folder)[2])&&File.ReadAllText(Targets(folder)[5]).Contains("CyrusSurfaceAnalyzer2027="),"Scatter-only removal keeps Analyzer registration");
        }
        folder=Profile("legacy");string[] poisoned=LegacySeed(folder),poisonHashes=Array.ConvertAll(poisoned,FileHash);using(var form=Window(folder)){
            Check(Run(form).StartsWith("Installation completed"),"Actual EXE installs despite both legacy poisoned backups");VerifyInstall(folder,scatter,analyzer);
            foreach(string product in new[]{"CyrusScatter","CyrusSurfaceAnalyzer"})Check(Directory.GetFiles(Path.Combine(folder,"s",product,"Backups/v2"),"*",SearchOption.AllDirectories).Length>=2,"Actual EXE retained verified "+product+" backup set");
            for(int index=0;index<poisoned.Length;++index){
                string current=poisoned[index].Replace(@"\Backups\",@"\Backups\v2\"),metadata=index==0?Path.Combine(Path.GetDirectoryName(current),"complete.txt"):Path.ChangeExtension(current,".txt");
                string originalBackup=Path.Combine(index==0?scatterOld:analyzerOld,index==0?"CyrusScatterStartup.ms":"CyrusSurfaceAnalyzerStartup.ms");
                Check(FileHash(poisoned[index])==poisonHashes[index]&&FileHash(current)==FileHash(originalBackup)&&File.ReadAllText(metadata).Contains(poisoned[index]+"\t"+poisonHashes[index]+"\t"+current),"Actual EXE records and preserves the exact poisoned old backup while publishing verified original bytes: "+index);
            }
            string before=Snapshot(folder);Check(Run(form).StartsWith("Installation completed")&&Snapshot(folder)==before,"Actual EXE legacy migration repeats safely");
        }
        foreach(string product in new[]{"Scatter","Analyzer"}){
            folder=Profile("custom"+product);string path=Path.Combine(folder,"u",product=="Scatter"?"CyrusScatterStartup.ms":"CyrusSurfaceAnalyzerStartup.ms");File.WriteAllText(path,"owned custom startup");string before=Snapshot(folder);
            using(var form=Window(folder))Check(Run(form).StartsWith("Could not finish")&&Snapshot(folder)==before,"Actual EXE preserves custom "+product+" startup before publishing either product");
        }
        folder=Profile("registration");File.AppendAllText(Path.Combine(folder,"Plugin.UserSettings.ini"),"CyrusScatter2027=C:\\Custom\\Plugins\n",Encoding.Unicode);string original=Snapshot(folder);
        using(var form=Window(folder))Check(Run(form).StartsWith("Could not finish")&&Snapshot(folder)==original,"Actual EXE refuses custom Scatter registration in its preflight");
        Check(FileHash(executable)==args[1],"Exact tested EXE remained unchanged");Console.WriteLine("CHECKS "+checks);return 0;
    }catch(Exception error){Console.Error.WriteLine(error);return 1;}}
}
