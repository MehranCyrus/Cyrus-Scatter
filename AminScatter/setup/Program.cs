using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
[assembly: System.Runtime.Versioning.TargetFramework(".NETFramework,Version=v4.8")]
namespace Cyrus.Setup {
    sealed class SetupWindow : Form {
        readonly Dictionary<string,string> profiles=new Dictionary<string,string>();
        readonly Dictionary<string,CheckBox> hosts=new Dictionary<string,CheckBox>();
        readonly Dictionary<string,Label> states=new Dictionary<string,Label>();
        readonly InstallerView view=new InstallerView();
        readonly TableLayoutPanel cards=new TableLayoutPanel {Dock=DockStyle.Top,Height=112,ColumnCount=BuildIdentity.Years.Length};
        bool busy;CancellationTokenSource cancellation;
        internal Func<string,bool> hostRunning=HostRunning;
        public SetupWindow() {
            AppContext.SetSwitch("Switch.System.IO.UseLegacyPathHandling",false);AppContext.SetSwitch("Switch.System.IO.BlockLongPaths",false);
            Text="Cyrus Scatter "+BuildIdentity.Version;Font=new Font("Segoe UI",10);AutoScaleMode=AutoScaleMode.Dpi;
            StartPosition=FormStartPosition.CenterScreen;ClientSize=new Size(760,475);MinimumSize=new Size(700,505);Padding=new Padding(24);BackColor=Color.White;
            var title=new Label {Text="Cyrus Scatter",Dock=DockStyle.Top,AutoSize=true,Padding=new Padding(0,0,0,6),Font=new Font("Segoe UI",22,FontStyle.Bold),ForeColor=Color.FromArgb(26,47,52)};
            var subtitle=new Label {Text="Scatter "+BuildIdentity.Version+(BuildIdentity.AnalyzerPackages.Length>0?"   ·   Surface Analyzer "+BuildIdentity.AnalyzerPackages[0].Version:"")+"   ·   Select your Max versions",Dock=DockStyle.Top,AutoSize=true,Padding=new Padding(0,0,0,12),ForeColor=Color.FromArgb(89,103,111)};
            foreach(string year in BuildIdentity.Years) {
                cards.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100f/BuildIdentity.Years.Length));
                var card=new Panel {Dock=DockStyle.Fill,BackColor=Color.FromArgb(244,247,248),Padding=new Padding(10),Margin=new Padding(0,0,8,12)};
                var pick=new CheckBox {Text="3ds Max "+year,Dock=DockStyle.Top,Height=32,Font=new Font("Segoe UI",11,FontStyle.Bold),Cursor=Cursors.Hand};
                var state=new Label {Dock=DockStyle.Fill,Padding=new Padding(0,5,0,0),ForeColor=Color.FromArgb(85,100,108)};
                try{
                    Distribution.DetectMax(year);
                    try{profiles.Add(year,Distribution.FindProfile(year));pick.Checked=true;}
                    catch(IOException){pick.Enabled=false;state.Text="Open Max once to set up";}
                }catch(IOException){pick.Enabled=false;state.Text="Not installed";}
                hosts.Add(year,pick);states.Add(year,state);pick.CheckedChanged+=(s,e)=>RefreshSelection();
                card.Controls.Add(state);card.Controls.Add(pick);cards.Controls.Add(card);
            }
            Controls.Add(view);Controls.Add(cards);Controls.Add(subtitle);Controls.Add(title);
            view.Primary.Click+=async(s,e)=>await Run(false);
            view.Uninstall.Text="Uninstall Scatter";
            view.Uninstall.Click+=async(s,e)=>{if(MessageBox.Show(this,"Uninstall Cyrus Scatter from the selected Max versions? Surface Analyzer, your shared library and scenes will be kept.","Uninstall Cyrus Scatter",MessageBoxButtons.OKCancel)==DialogResult.OK)await Run(true);};
            view.CloseButton.Click+=(s,e)=>{if(busy)cancellation.Cancel();else Close();};
            FormClosing+=(s,e)=>{if(busy){e.Cancel=true;cancellation.Cancel();}};
            RefreshSelection();view.Status.Text="Close the selected Max versions, then click Install or Update.";
        }
        static bool HostRunning(string year) {
            foreach(var process in Process.GetProcessesByName("3dsmax"))using(process) {
                try{if(FileVersionInfo.GetVersionInfo(process.MainModule.FileName).FileMajorPart==Int32.Parse(year)-1998)return true;}
                catch(System.ComponentModel.Win32Exception){throw new IOException("Close running 3ds Max sessions before updating.");}
                catch(InvalidOperationException){}
            }
            return false;
        }
        void RefreshSelection() {
            if(busy)return;
            bool any=false,installed=false,missing=false,previous=false;
            foreach(var pair in hosts) {
                if(!profiles.ContainsKey(pair.Key))continue;
                string version;bool existing;
                try{var paths=Distribution.FromProfile(profiles[pair.Key],pair.Key);version=InstallEngine.InstalledVersion(paths);existing=version.Length==0&&InstallEngine.HasPreviousInstallation(paths,pair.Key);}
                catch(IOException){states[pair.Key].Text="Profile unavailable";pair.Value.Enabled=false;continue;}
                states[pair.Key].Text=version.Length>0?"Installed "+version:existing?"Older installation found":"Ready to install";
                if(pair.Value.Checked){any=true;installed|=version.Length>0;missing|=version.Length==0;previous|=existing;}
                pair.Value.Parent.BackColor=pair.Value.Checked?Color.FromArgb(228,243,237):Color.FromArgb(244,247,248);
            }
            view.Primary.Text=previous?"Install / Update":installed?(missing?"Install / Update":"Update"):"Install";
            view.Primary.Enabled=any;view.Uninstall.Enabled=installed;
        }
        async Task Run(bool remove) {
            if(busy)return;
            var selected=new List<string>();foreach(var pair in hosts)if(pair.Value.Checked&&profiles.ContainsKey(pair.Key))selected.Add(pair.Key);
            if(selected.Count==0){view.Status.Text="Select a Max version to continue.";return;}
            var targets=new Dictionary<string,InstallPaths>();
            bool installContent=view.InstallContent.Checked;
            string companion=Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
            try {
                var destinations=new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                foreach(string year in selected) {
                    if(hostRunning(year))throw new IOException("Close 3ds Max "+year+", then click "+(remove?"Uninstall":"Install / Update")+" again. Your installation has not changed.");
                    targets.Add(year,Distribution.FromProfile(profiles[year],year));
                    var paths=targets[year];
                    foreach(string destination in new[]{Path.Combine(paths.Scripts,"CyrusScatter","installed.txt"),Path.Combine(paths.Scripts,"CyrusSurfaceAnalyzer","installed.txt"),Path.Combine(paths.Startup,"CyrusScatterStartup.ms"),Path.Combine(paths.Startup,"CyrusSurfaceAnalyzerStartup.ms"),Path.Combine(paths.Macros,"CyrusScatter.mcr"),Path.Combine(paths.Profile,"Plugin.UserSettings.ini")})
                        if(!destinations.Add(destination))throw new IOException("Selected Max versions share an installation target. Use separate initialized profiles. File: "+destination);
                }
            }catch(Exception error){view.Status.Text=error.Message;view.Details.Text=error.ToString();view.SetFailure(true);return;}
            busy=true;cancellation=new CancellationTokenSource();cards.Enabled=false;view.SetBusy(true);view.Report("Checking your installation…");view.Details.Text="";
            var log=new System.Text.StringBuilder();var notes=new List<string>();
            try {
                await Task.Run(()=>{
                    string parent=Path.Combine(Path.GetTempPath(),"CyrusSetup");var extracted=new List<string>();var engines=new Dictionary<string,InstallEngine>();var analyzers=new Dictionary<string,AnalyzerInstallEngine>();
                    Action<string> check=value=>cancellation.Token.ThrowIfCancellationRequested();
                    try {
                        foreach(string year in selected) {
                            check("preflight");
                            if(remove)continue;
                            int index=Array.IndexOf(BuildIdentity.Years,year);
                            string folder=Distribution.Extract(Assembly.GetExecutingAssembly(),parent,BuildIdentity.PackageHashes[index],check,BuildIdentity.Resources[index]);extracted.Add(folder);
                            var engine=new InstallEngine(folder,BuildIdentity.InventoryHashes[index]);if(engine.Year!=year)throw new IOException("Selected host and package differ.");
                            engine.PreflightRegistration(targets[year]);
                            notes.Add("Max "+year+": "+engine.ConfigureLibraryChoice(targets[year],installContent,companion));
                            engines.Add(year,engine);log.AppendLine(engine.Plan(targets[year],check));
                            if(BuildIdentity.AnalyzerPackages.Length>0) {
                                string analyzerFolder=Distribution.Extract(Assembly.GetExecutingAssembly(),parent,BuildIdentity.AnalyzerPackageHashes[index],check,BuildIdentity.AnalyzerResources[index]);extracted.Add(analyzerFolder);
                                var analyzer=new AnalyzerInstallEngine(analyzerFolder,BuildIdentity.AnalyzerPackages[index]);
                                log.AppendLine(analyzer.Plan(targets[year],check));analyzers.Add(year,analyzer);
                            }
                        }
                        var publishedStates=new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                        foreach(string year in selected) {
                            check("host:"+year);view.Report((remove?"Uninstalling":"Updating")+" Cyrus Scatter for Max "+year+"…");
                            if(remove) {
                                if(BuildIdentity.AnalyzerPackages.Length>0)AnalyzerInstallEngine.RecoverRegistration(targets[year]);
                                if(InstallEngine.InstalledVersion(targets[year]).Length>0)InstallEngine.RemoveRegistration(targets[year],year);
                                log.AppendLine("Uninstalled Max "+year+"; shared content retained.");continue;
                            }
                            var engine=engines[year];string state=InstallEngine.StatePath(targets[year]);
                            if(publishedStates.Contains(state))engine.LibraryAction="Keep";
                            engine.Install(targets[year],check);
                            if(engine.LibraryAction!="Keep")publishedStates.Add(state);
                            log.AppendLine("Completed Scatter "+BuildIdentity.Version+" for Max "+year+".");
                            if(analyzers.ContainsKey(year)) {
                                view.Report("Installing Surface Analyzer for Max "+year+"…");
                                try {analyzers[year].Install(targets[year],check);}
                                catch(OperationCanceledException){throw;}
                                catch(Exception error){throw new IOException("Max "+year+": Surface Analyzer could not finish. Scatter completed; retry to finish Analyzer. "+error.Message,error);}
                                log.AppendLine("Completed Surface Analyzer "+BuildIdentity.AnalyzerPackages[Array.IndexOf(BuildIdentity.Years,year)].Version+" for Max "+year+".");
                            }
                        }
                    }finally{foreach(string folder in extracted)try{Distribution.Cleanup(parent,folder);}catch(IOException error){log.AppendLine(error.Message);}}
                });
                view.Details.Text=log+"\r\n"+String.Join("\r\n",notes);
                view.SetFailure(false);
                view.Status.Text=remove?"Uninstall completed. Your library is kept.":"Installation completed. You can now open Max.";
            }catch(OperationCanceledException){view.Status.Text="Cancelled. Completed updates are retained; incomplete registration is rolled back.";view.Details.Text=log.ToString();}
            catch(Exception error){view.Status.Text="Could not finish: "+error.Message.Split('\r','\n')[0];view.Details.Text=log+"\r\n"+error+"\r\nLog: "+InstallEngine.SaveFailure(targets[selected[0]],error.ToString());view.SetFailure(true);}
            finally{busy=false;cancellation.Dispose();cancellation=null;cards.Enabled=true;view.SetBusy(false);RefreshSelection();}
        }
    }
    static class Program {
        [STAThread] static void Main(){Application.EnableVisualStyles();Application.SetCompatibleTextRenderingDefault(false);Application.Run(new SetupWindow());}
    }
}
