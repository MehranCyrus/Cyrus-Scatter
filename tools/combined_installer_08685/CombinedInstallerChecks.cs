// Private tests of the exact compiled EXE; never part of a product payload.
using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Threading.Tasks;
using System.Windows.Forms;
using Cyrus.Setup;

static class CombinedInstallerChecks {
    static int checks;static string output;
    static readonly BindingFlags Hidden=BindingFlags.Instance|BindingFlags.NonPublic;
    static void Check(bool value,string message){if(!value)throw new Exception(message);++checks;Console.WriteLine("PASS: "+message);}
    static T Field<T>(Form form,string name){return (T)form.GetType().GetField(name,Hidden).GetValue(form);}
    static string[] Targets(InstallPaths p){return new[]{Path.Combine(p.Startup,"CyrusSurfaceAnalyzerStartup.ms"),Path.Combine(p.Scripts,"CyrusSurfaceAnalyzer","installed.txt"),Path.Combine(p.Profile,"Plugin.UserSettings.ini")};}
    static string[] Snapshot(InstallPaths p){return Array.ConvertAll(Targets(p),x=>File.Exists(x)?Convert.ToBase64String(File.ReadAllBytes(x)):"ABSENT");}
    static bool Same(InstallPaths p,string[] before){return String.Join("|",Snapshot(p))==String.Join("|",before);}
    static InstallPaths Paths(string name,string year){
        string root=Path.Combine(output,name);Directory.CreateDirectory(root);
        var p=InstallPaths.ForMax(Path.Combine(root,"scripts"),Path.Combine(root,"startup"),Path.Combine(root,"macros"),root,year);
        foreach(string d in new[]{p.Startup,p.Macros,p.Scripts,Path.Combine(p.Scripts,"CyrusSurfaceAnalyzer")})Directory.CreateDirectory(d);
        File.WriteAllText(Path.Combine(root,"Plugin.UserSettings.ini"),"[Directories]\r\nAdditional MAX plug-ins=C:\\Program Files\\Autodesk\\3ds Max "+year+"\\PlugIns\r\n",System.Text.Encoding.Unicode);
        return p;
    }
    static bool Reject(Action action){try{action();return false;}catch(IOException){return true;}catch(OperationCanceledException){return true;}catch(System.Reflection.TargetInvocationException e){return e.InnerException is IOException;}}
    static void Legacy(InstallPaths p,string legacy){File.Copy(legacy,Targets(p)[0],false);}
    static void Core(string year,string folder,AnalyzerPackage descriptor,string legacy){
        var engine=new AnalyzerInstallEngine(folder,descriptor);var fresh=Paths("core-fresh-"+year,year);
        string runtime=engine.Install(fresh);Check(File.Exists(Path.Combine(runtime,"bin","CyrusSurfaceAnalyzer.dlx")),year+" fresh Analyzer native runtime");
        Check(File.ReadAllText(Targets(fresh)[1]).Contains("\n0.14.1\n"),year+" Analyzer receipt/version");
        Check(File.ReadAllText(Targets(fresh)[2]).Contains("Additional MAX plug-ins="),year+" unrelated plugin registration retained");
        int copies=0;string repeated=engine.Install(fresh,p=>{if(p.StartsWith("analyzer-copy:"))++copies;});
        Check(repeated==runtime&&copies==0,year+" repeat reuses verified runtime without staging another copy");
        File.Delete(Targets(fresh)[0]);engine.Install(fresh);Check(File.Exists(Targets(fresh)[0]),year+" missing owned startup repairs");
        var old=Paths("core-legacy-"+year,year);Legacy(old,legacy);engine.Install(old);
        var backups=Directory.GetFiles(Path.Combine(old.Scripts,"CyrusSurfaceAnalyzer","Backups"));
        Check(backups.Length==1&&InstallEngine.Hash(File.ReadAllBytes(backups[0]))==InstallEngine.Hash(File.ReadAllBytes(legacy)),year+" exact legacy Analyzer startup backed up");
        engine.Install(old);Check(Directory.GetFiles(Path.GetDirectoryName(backups[0])).Length==1,year+" legacy backup reused");
        var custom=Paths("core-custom-"+year,year);File.WriteAllText(Targets(custom)[0],"Artist customization");var before=Snapshot(custom);
        Check(Reject(()=>engine.Plan(custom))&&Same(custom,before),year+" unknown Analyzer startup preserved before publication");
        File.WriteAllText(Targets(fresh)[0],"Modified owned startup");before=Snapshot(fresh);
        Check(Reject(()=>engine.Install(fresh))&&Same(fresh,before),year+" receipt-mismatched startup preserved");
        var tamper=Paths("core-runtime-tamper-"+year,year);string release=engine.Install(tamper);
        File.WriteAllText(Path.Combine(release,"bin","CyrusSurfaceAnalyzer.dlx"),"Modified native module");before=Snapshot(tamper);
        Check(Reject(()=>engine.Plan(tamper))&&Same(tamper,before),year+" modified immutable native runtime rejected without changing registration");
        var receipt=Paths("core-receipt-"+year,year);File.WriteAllText(Targets(receipt)[1],"Invalid receipt");before=Snapshot(receipt);
        Check(Reject(()=>engine.Install(receipt))&&Same(receipt,before),year+" invalid Analyzer receipt retained");
        var longPath=Paths("lp-"+year+"-"+new String('x',50),year);Legacy(longPath,legacy);before=Snapshot(longPath);
        Check(Reject(()=>engine.Plan(longPath))&&Same(longPath,before),year+" long legacy-backup path rejected during preflight");
        int phaseIndex=0;
        foreach(string phase in new[]{"analyzer-copy:CyrusSurfaceAnalyzer.dlx","analyzer-journal","analyzer-publish:0","analyzer-publish:1","analyzer-publish:2"}){
            var p=Paths("interrupt-"+year+"-"+(phaseIndex++),year);Legacy(p,legacy);before=Snapshot(p);
            bool failed=Reject(()=>engine.Install(p,value=>{if(value==phase)throw new OperationCanceledException("Owned interruption");}));
            Check(failed&&Same(p,before),year+" interrupted Analyzer registration retains old bytes at "+phase);
            engine.Install(p);Check(File.Exists(Targets(p)[1]),year+" Analyzer retry succeeds at "+phase);
        }
        var tail=Paths("core-tail-"+year,year);
        Check(Reject(()=>engine.Install(tail,p=>{if(p=="analyzer-published")throw new IOException("Owned commit-tail interruption");})),year+" commit-tail interruption observed");
        Check(File.Exists(Targets(tail)[1])&&File.ReadAllText(Targets(tail)[2]).Contains("CyrusSurfaceAnalyzer"+year+"="),year+" complete Analyzer commit retained at tail");
        engine.Install(tail);Check(File.Exists(Targets(tail)[0]),year+" complete-tail retry succeeds");
        var external=Paths("core-external-"+year,year);
        Check(Reject(()=>engine.Install(external,p=>{if(p=="analyzer-publish:1")File.WriteAllText(Targets(external)[0],"External edit during publication");})),year+" external publication edit blocks recovery");
        Check(File.ReadAllText(Targets(external)[0])=="External edit during publication"&&File.Exists(Path.Combine(external.Scripts,"CyrusSurfaceAnalyzer","install-transaction.bin")),year+" external edit and recovery evidence preserved");
    }
    static void Run(Form form,bool remove=false){
        var task=(Task)form.GetType().GetMethod("Run",Hidden).Invoke(form,new object[]{remove});var clock=System.Diagnostics.Stopwatch.StartNew();
        while(!task.IsCompleted&&clock.ElapsedMilliseconds<180000){Application.DoEvents();System.Threading.Thread.Sleep(10);}
        Check(task.IsCompleted,"Actual EXE async handler terminates within deadline");task.GetAwaiter().GetResult();Application.DoEvents();
    }
    static void Capture(Form form,string name){using(var image=new Bitmap(form.Width,form.Height)){form.DrawToBitmap(image,new Rectangle(Point.Empty,image.Size));image.Save(Path.Combine(output,name));}}
    static Dictionary<string,InstallPaths> SetRecipients(Form form,string prefix,string[] years){
        var profiles=Field<Dictionary<string,string>>(form,"profiles");var hosts=Field<Dictionary<string,CheckBox>>(form,"hosts");profiles.Clear();
        foreach(var h in hosts.Values)h.Checked=false;
        var result=new Dictionary<string,InstallPaths>();
        foreach(string year in years){
            var p=Paths(prefix+"-"+year,year);result.Add(year,p);string ini=Path.Combine(p.Profile,"3dsMax.ini");
            File.WriteAllText(ini,"[Directories]\r\nAdditional Scripts="+p.Scripts+"\r\nAdditional Startup Scripts="+p.Startup+"\r\nAdditional Macros="+p.Macros+"\r\n",System.Text.Encoding.Unicode);
            profiles.Add(year,ini);hosts[year].Enabled=true;hosts[year].Checked=true;
        }
        form.GetType().GetField("hostRunning",Hidden|BindingFlags.Public).SetValue(form,new Func<string,bool>(y=>false));return result;
    }
    [STAThread] static int Main(string[] args){try{
        output=Path.GetFullPath(args[1]);if(!output.Contains("\\build\\combined-installer-08685-20261022\\"))throw new Exception("Owned output required");Directory.CreateDirectory(output);
        var assembly=Assembly.LoadFrom(Path.GetFullPath(args[0]));var identity=assembly.GetType("Cyrus.Setup.BuildIdentity");
        Func<string,object> get=name=>identity.GetField(name,BindingFlags.Public|BindingFlags.Static).GetValue(null);
        var years=(string[])get("Years");var packages=(AnalyzerPackage[])get("AnalyzerPackages");var hashes=(string[])get("AnalyzerPackageHashes");var resources=(string[])get("AnalyzerResources");
        Check(String.Join(",",years)=="2024,2026,2027"&&packages.Length==3,"EXE embeds matched Analyzer packages for all three supported hosts");
        for(int i=0;i<years.Length;++i){string p=Distribution.Extract(assembly,Path.Combine(output,"extracted"),hashes[i],null,resources[i]);Core(years[i],p,packages[i],args[2]);}
        var saveJournal=typeof(InstallEngine).GetMethod("SaveJournal",BindingFlags.NonPublic|BindingFlags.Static);byte[] block=new byte[2*1024*1024];
        string journal=Path.Combine(output,"oversized.bin");
        Check(Reject(()=>saveJournal.Invoke(null,new object[]{journal,new[]{"a","b","c"},new[]{block,block,block},new[]{block,block,block},"BudgetTest"}))&&!File.Exists(journal),"Oversized recovery journal rejected before publication");
        Application.EnableVisualStyles();
        using(var form=(Form)Activator.CreateInstance(assembly.GetType("Cyrus.Setup.SetupWindow"),true)){
            form.ShowInTaskbar=false;form.StartPosition=FormStartPosition.Manual;form.Location=new Point(-32000,-32000);form.Show();Application.DoEvents();
            var cards=Field<TableLayoutPanel>(form,"cards");var view=Field<InstallerView>(form,"view");
            Check(cards.ColumnCount==3&&cards.Controls.Count==3,"Actual UI displays three host cards");
            foreach(Control c in form.Controls)if(c is Label&&c.Text=="Cyrus Scatter")Check(c.Height>=TextRenderer.MeasureText(c.Text,c.Font).Height,"Actual title height fits its font");
            foreach(Control card in cards.Controls)foreach(Control c in card.Controls)if(c is CheckBox)Check(c.ClientSize.Width>=TextRenderer.MeasureText(c.Text,c.Font).Width+24,"Host caption fits: "+c.Text);
            Capture(form,"installer-100.png");form.Scale(new SizeF(1.5f,1.5f));form.PerformLayout();Capture(form,"installer-150.png");
            var failed=SetRecipients(form,"ui-preflight",years);File.WriteAllText(Targets(failed["2026"])[0],"Preserved unknown startup");Run(form);
            Check(view.Status.Text.Contains("Max 2026")&&view.Details.Text.Contains(Targets(failed["2026"])[0]),"Analyzer preflight failure identifies host/file");
            foreach(var p in failed.Values)Check(!File.Exists(Path.Combine(p.Scripts,"CyrusScatter","installed.txt")),"Both-product preflight prevents early Scatter publication");
            var scatterFailure=SetRecipients(form,"ui-scatter-preflight",years);
            string conflict=Path.Combine(scatterFailure["2026"].Macros,"CyrusScatter.mcr");File.WriteAllText(conflict,"Preserved custom Scatter macro");Run(form);
            Check(view.Status.Text.Contains("Max 2026")&&view.Details.Text.Contains(conflict),"Scatter preflight identifies conflicting host/file");
            foreach(var p in scatterFailure.Values)Check(!File.Exists(Path.Combine(p.Scripts,"CyrusScatter","installed.txt")),"Scatter ownership preflight prevents earlier-host publication");
            var recipients=SetRecipients(form,"recipient",years);Run(form);Check(view.Status.Text=="Installation completed. You can now open Max.","Standalone EXE handler installs both plugins");
            var lines=new List<string>();
            foreach(string year in years){
                var p=recipients[year];string[] record=File.ReadAllLines(Path.Combine(p.Scripts,"CyrusScatter","installed.txt"));
                Check(record[1]=="0.86.8.5",year+" actual EXE Scatter receipt");
                Check(File.ReadAllText(Targets(p)[1]).Contains("\n0.14.1\n"),year+" actual EXE Analyzer receipt");
                Check(File.Exists(Targets(p)[0])&&File.ReadAllText(Targets(p)[2]).Contains("CyrusSurfaceAnalyzer"+year+"="),year+" actual EXE Analyzer startup/registration");
                lines.Add(year+"\t"+p.Profile+"\t"+record[2]+"\t"+Path.Combine(p.Scripts,"CyrusSurfaceAnalyzer","r",packages[Array.IndexOf(years,year)].RuntimeID));
            }
            File.WriteAllLines(Path.Combine(output,"recipients.tsv"),lines);Run(form);Check(view.Status.Text=="Installation completed. You can now open Max.","Actual three-host repeated update succeeds");
            File.WriteAllText(Targets(recipients["2027"])[0],"Preserved modified Analyzer startup");Run(form);
            Check(view.Status.Text.Contains("Max 2027")&&File.ReadAllText(Targets(recipients["2027"])[0])=="Preserved modified Analyzer startup","Actual EXE preserves modified Analyzer startup");
            File.Delete(Targets(recipients["2027"])[0]);Run(form);Check(view.Status.Text=="Installation completed. You can now open Max.","Actual EXE repairs missing owned Analyzer startup");
            Capture(form,"installer-completed.png");
            var uninstall=SetRecipients(form,"ui-uninstall",years);Run(form);Run(form,true);
            Check(view.Uninstall.Text=="Uninstall Scatter"&&view.Status.Text.StartsWith("Uninstall completed"),"Actual uninstall handler is explicitly Scatter-only");
            foreach(var p in uninstall.Values){
                Check(!File.Exists(Path.Combine(p.Scripts,"CyrusScatter","installed.txt")),"Scatter-only uninstall removes Scatter receipt");
                Check(File.Exists(Targets(p)[0])&&File.Exists(Targets(p)[1])&&File.ReadAllText(Targets(p)[2]).Contains("CyrusSurfaceAnalyzer"),"Scatter-only uninstall retains independent Analyzer registration and startup");
            }
            var shared=SetRecipients(form,"ui-shared",years);
            string sharedINI=Path.Combine(shared["2026"].Profile,"3dsMax.ini");File.WriteAllText(sharedINI,File.ReadAllText(sharedINI).Replace(shared["2026"].Startup,shared["2024"].Startup),System.Text.Encoding.Unicode);Run(form);
            Check(view.Status.Text.Contains("share an installation target"),"Shared cross-host target rejected");
            foreach(var p in shared.Values)Check(!File.Exists(Path.Combine(p.Scripts,"CyrusScatter","installed.txt")),"Shared target rejection preserves all hosts");
            var running=SetRecipients(form,"ui-running",years);
            form.GetType().GetField("hostRunning",Hidden|BindingFlags.Public).SetValue(form,new Func<string,bool>(y=>y=="2024"));Run(form);
            Check(view.Status.Text.Contains("Close 3ds Max 2024"),"Running selected host blocks updates");
            foreach(var p in running.Values)Check(!File.Exists(Path.Combine(p.Scripts,"CyrusScatter","installed.txt")),"Running-host rejection preserves all hosts");
        }
        File.WriteAllText(Path.Combine(output,"passed.txt"),checks.ToString());Console.WriteLine("PASSED "+checks+" exact combined EXE checks");return 0;
    }catch(Exception error){Console.WriteLine(error);return 1;}}
}
