// Drive the delivered EXE's real selection/install flow against disposable profiles.
// No Max process or native module is launched. The form is constructed but not shown.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using Cyrus.Setup;

static class InstallerSelectionChecks {
    static readonly BindingFlags Fields=BindingFlags.Instance|BindingFlags.NonPublic;
    static void Check(bool ok,string message){if(!ok)throw new Exception(message);Console.WriteLine("PASS "+message);}
    static object Field(object instance,string name){return instance.GetType().GetField(name,Fields|BindingFlags.Public).GetValue(instance);}
    static string Receipt(InstallPaths paths){return Path.Combine(paths.Scripts,"CyrusScatter","installed.txt");}
    [STAThread] static int Main(string[] args){try{
        string work=Path.GetFullPath(args[0]),legacy=Path.GetFullPath(args[1]),previous=Path.GetFullPath(args[2]);
        Directory.CreateDirectory(work);
        foreach(string year in new[]{"2024","2026","2027"})using(var resource=typeof(Distribution).Assembly.GetManifestResourceStream("Cyrus.Payload."+year+".mzp"))using(var bytes=new MemoryStream()){
            Check(resource!=null,"EXE embeds Max "+year);resource.CopyTo(bytes);
            Check(InstallEngine.Hash(bytes.ToArray())==InstallEngine.Hash(File.ReadAllBytes(Path.Combine(args[3],"CyrusScatter-0.87.6-Max"+year+".mzp"))),"embedded MZP bytes match delivered archive "+year);
        }
        var initialized=new Dictionary<string,string>();var paths=new Dictionary<string,InstallPaths>();
        foreach(string year in new[]{"2024","2026","2027"}){
            string folder=Path.Combine(work,year);Directory.CreateDirectory(folder);
            string ini=Path.Combine(folder,"3dsMax.ini");
            File.WriteAllText(ini,"[Directories]\nAdditional Scripts="+Path.Combine(folder,"scripts")+
                "\nAdditional Startup Scripts="+Path.Combine(folder,"startup")+"\nAdditional Macros="+Path.Combine(folder,"macros")+"\n");
            var p=Distribution.FromProfile(ini,year);paths.Add(year,p);initialized.Add(year,ini);
            Check(p.RuntimeRoot.StartsWith(work+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)&&
                  InstallEngine.StatePath(p).StartsWith(work+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase),"owned runtime and library state "+year);
            foreach(string d in new[]{p.Scripts,p.Startup,p.Macros})Directory.CreateDirectory(d);
            File.WriteAllText(Path.Combine(folder,"Plugin.UserSettings.ini"),"[Directories]\r\nUnrelated=C:\\Preserve\\Plugins\r\n",Encoding.Unicode);
        }
        var old=paths["2026"];string oldRoot=Path.Combine(old.Scripts,"CyrusScatter"),bins=Path.Combine(oldRoot,"bin-max2026-866ea3d51489");Directory.CreateDirectory(bins);
        var legacyHashes=new Dictionary<string,string>();
        foreach(string name in new[]{"AminScatter.dlx","CyrusBrush.dlx","CyrusBrushStorage.dlh","CyrusScatterEdit.dlm"}){
            string file=Path.Combine(bins,name);File.Copy(Path.Combine(legacy,name),file);legacyHashes.Add(file,InstallEngine.Hash(File.ReadAllBytes(file)));
        }
        File.Copy(Path.Combine(legacy,"CyrusScatterStartup.ms"),Path.Combine(old.Startup,"CyrusScatterStartup.ms"));
        File.Copy(Path.Combine(legacy,"CyrusScatter.mcr"),Path.Combine(old.Macros,"CyrusScatter.mcr"));
        string oldIni=Path.Combine(old.Profile,"Plugin.UserSettings.ini");
        File.AppendAllText(oldIni,"CyrusScatter2026="+bins+"\\\r\n",Encoding.Unicode);byte[] before=File.ReadAllBytes(oldIni);
        new InstallEngine(previous,InstallEngine.Hash(File.ReadAllBytes(Path.Combine(previous,"InstallInventory.txt")))).Install(paths["2027"]);
        string previousReceipt=File.ReadAllText(Receipt(paths["2027"]));
        var type=typeof(Distribution).Assembly.GetType("Cyrus.Setup.SetupWindow",true);
        using(var window=(Form)Activator.CreateInstance(type)){
            var profiles=(Dictionary<string,string>)Field(window,"profiles");profiles.Clear();foreach(var item in initialized)profiles.Add(item.Key,item.Value);
            var hosts=(Dictionary<string,CheckBox>)Field(window,"hosts");
            type.GetField("hostRunning",Fields).SetValue(window,new Func<string,bool>(year=>false));
            foreach(var host in hosts.Values){host.Enabled=true;host.Checked=true;}
            type.GetMethod("RefreshSelection",Fields).Invoke(window,null);
            var states=(Dictionary<string,Label>)Field(window,"states");var view=Field(window,"view");
            var primary=(Button)Field(view,"Primary");var uninstall=(Button)Field(view,"Uninstall");
            Check(states["2024"].Text=="Ready to install","clean Max 2024 UI status");
            Check(states["2026"].Text=="Older installation found","old Max 2026 UI status");
            Check(states["2027"].Text=="Installed 0.87.6","receipted Max 2027 UI status");
            hosts["2024"].Checked=false;hosts["2027"].Checked=false;
            Check(primary.Text=="Install / Update"&&!uninstall.Enabled,"legacy presence does not grant receipt-based uninstall");
            hosts["2024"].Checked=true;hosts["2027"].Checked=true;
            for(int pass=0;pass<2;++pass){
                var task=(Task)type.GetMethod("Run",Fields).Invoke(window,new object[]{false});var timer=Stopwatch.StartNew();
                while(!task.IsCompleted&&timer.Elapsed.TotalSeconds<90){Application.DoEvents();Thread.Sleep(10);}
                Check(task.IsCompleted,"combined EXE command completed within bound");task.GetAwaiter().GetResult();
                var status=(Label)Field(view,"Status");var details=(TextBox)Field(view,"Details");
                File.WriteAllText(Path.Combine(work,"exe-pass-"+pass+".log"),status.Text+"\n"+details.Text);
                Check(status.Text=="Installation completed. You can now open Max.","combined three-host install/retry success: "+status.Text);
                foreach(var pair in paths)Check(InstallEngine.InstalledVersion(pair.Value)=="0.87.6"&&states[pair.Key].Text=="Installed 0.87.6","completed receipt and UI "+pair.Key);
            }
        }
        Check(previousReceipt!=File.ReadAllText(Receipt(paths["2027"])),"existing modern installation moved to revised runtime");
        foreach(var pair in paths)Check(File.ReadAllText(Path.Combine(pair.Value.Profile,"Plugin.UserSettings.ini")).Contains("Unrelated=C:\\Preserve\\Plugins"),"unrelated registration retained "+pair.Key);
        Check(InstallEngine.Hash(File.ReadAllBytes(Path.Combine(oldRoot,"Backups","v2","registration-"+InstallEngine.Hash(before)+".ini")))==InstallEngine.Hash(before),"legacy INI durable backup matches before upgrade");
        foreach(var entry in legacyHashes)Check(InstallEngine.Hash(File.ReadAllBytes(entry.Key))==entry.Value,"legacy native bytes retained");
        return 0;
    }catch(Exception error){Console.Error.WriteLine(error);return 1;}}
}
