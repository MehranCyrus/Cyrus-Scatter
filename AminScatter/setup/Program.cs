using System;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

[assembly: System.Runtime.Versioning.TargetFramework(".NETFramework,Version=v4.8")]

namespace Cyrus.Setup {
    sealed class SetupWindow : Form {
        readonly TextBox profile=new TextBox(), details=new TextBox();
        readonly Button browse=new Button(), install=new Button(), remove=new Button(), close=new Button();
        readonly Label status=new Label();
        readonly ComboBox host=new ComboBox { DropDownStyle=ComboBoxStyle.DropDownList,Dock=DockStyle.Fill };
        string Year { get { return BuildIdentity.Years[host.SelectedIndex]; } }
        CancellationTokenSource cancellation;bool busy;
        public SetupWindow() {
            // The standalone net48 host must opt into modern paths before any
            // library IO; content-addressed preset paths can exceed MAX_PATH.
            AppContext.SetSwitch("Switch.System.IO.UseLegacyPathHandling", false);
            AppContext.SetSwitch("Switch.System.IO.BlockLongPaths", false);
            Text="Cyrus Scatter "+BuildIdentity.Version+" — Max "+String.Join(" / ",BuildIdentity.Years);StartPosition=FormStartPosition.CenterScreen;
            Font=new Font("Segoe UI",10);AutoScaleMode=AutoScaleMode.Dpi;ClientSize=new Size(700,470);MinimumSize=new Size(620,450);
            var layout=new TableLayoutPanel { Dock=DockStyle.Fill,Padding=new Padding(20),ColumnCount=2,RowCount=8 };
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100));layout.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
            foreach(int height in new[]{44,48,36,26,34})layout.RowStyles.Add(new RowStyle(SizeType.Absolute,height));
            layout.RowStyles.Add(new RowStyle(SizeType.Percent,100));layout.RowStyles.Add(new RowStyle(SizeType.Absolute,54));layout.RowStyles.Add(new RowStyle(SizeType.Absolute,42));
            var title=new Label { Text="Install Cyrus Scatter "+BuildIdentity.Version,Font=new Font(Font,FontStyle.Bold),AutoSize=true,Dock=DockStyle.Fill };
            layout.Controls.Add(title,0,0);layout.SetColumnSpan(title,2);
            var explanation=new Label { Text="Plugin, preset gallery and bundled examples. Choose the Max version below.\nInstalls for this Windows user. Personal recipes and activation are preserved.",AutoSize=true,Dock=DockStyle.Fill };
            layout.Controls.Add(explanation,0,1);layout.SetColumnSpan(explanation,2);
            foreach(string year in BuildIdentity.Years)host.Items.Add("3ds Max "+year+(year=="2024"?" (preview)":""));
            host.SelectedIndex=BuildIdentity.Years.Length-1;layout.Controls.Add(host,0,2);layout.SetColumnSpan(host,2);
            layout.Controls.Add(new Label { Text="Max profile",AutoSize=true,Dock=DockStyle.Fill },0,3);
            profile.Dock=DockStyle.Fill;profile.ReadOnly=true;
            SetProfile();
            layout.Controls.Add(profile,0,4);browse.Text="Browse…";browse.AutoSize=true;layout.Controls.Add(browse,1,4);
            details.Multiline=true;details.ReadOnly=true;details.ScrollBars=ScrollBars.Vertical;details.Dock=DockStyle.Fill;layout.Controls.Add(details,0,5);layout.SetColumnSpan(details,2);
            status.Dock=DockStyle.Fill;status.Text="Restart Max after installing to load the matching plugin version.";layout.Controls.Add(status,0,6);layout.SetColumnSpan(status,2);
            var buttons=new FlowLayoutPanel { Dock=DockStyle.Fill,FlowDirection=FlowDirection.RightToLeft,WrapContents=false };
            close.Text="Close";install.Text="Install / Repair";remove.Text="Unregister";
            foreach(var button in new[]{close,install,remove}) { button.AutoSize=true;buttons.Controls.Add(button); }
            layout.Controls.Add(buttons,0,7);layout.SetColumnSpan(buttons,2);Controls.Add(layout);
            host.SelectedIndexChanged+=(s,e)=>{SetProfile();RefreshDestination();};
            browse.Click+=(s,e)=> { using(var dialog=new OpenFileDialog { Filter="Max profile (*.ini)|*.ini",Title="Select the initialized 3ds Max "+Year+" profile" })if(dialog.ShowDialog(this)==DialogResult.OK) {profile.Text=dialog.FileName;RefreshDestination();} };
            install.Click+=async(s,e)=>await Run(false);remove.Click+=async(s,e)=>await Run(true);
            close.Click+=(s,e)=> { if(busy) { cancellation.Cancel();status.Text="Cancelling at the next safe file boundary…"; }else Close(); };
            FormClosing+=(s,e)=> { if(busy) {e.Cancel=true;cancellation.Cancel();status.Text="Cancelling at the next safe file boundary…";} };
            RefreshDestination();
        }
        void SetProfile() { profile.Text=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),@"Autodesk\3dsMax\"+Year+@" - 64bit\ENU\3dsMax.ini"); }
        void RefreshDestination() {
            try { string executable=Distribution.DetectMax(Year);var paths=Distribution.FromProfile(profile.Text,Year);details.Text="Detected Max "+Year+":\r\n"+executable+"\r\n\r\nPlugin and bundled library:\r\n"+Path.Combine(paths.Scripts,"CyrusScatter","Releases")+"\r\n\r\nStartup: "+paths.Startup+"\r\nMacros: "+paths.Macros+"\r\n\r\nUnregister removes startup and plugin registration. It retains personal recipes, imported assets and versioned recovery files.";install.Enabled=remove.Enabled=true; }
            catch(Exception error) { details.Text=error.Message;install.Enabled=remove.Enabled=false; }
        }
        async Task Run(bool unregister) {
            InstallPaths paths;string year=Year;int index=host.SelectedIndex;
            try { Distribution.DetectMax(year);paths=Distribution.FromProfile(profile.Text,year); }catch(Exception error){status.Text=error.Message;return;}
            if(unregister&&MessageBox.Show(this,"Remove Cyrus Scatter startup and plugin registration from this profile? Personal recipes, activation and recovery files will be retained.","Unregister Cyrus Scatter",MessageBoxButtons.OKCancel)!=DialogResult.OK)return;
            busy=true;cancellation=new CancellationTokenSource();host.Enabled=browse.Enabled=install.Enabled=remove.Enabled=false;close.Text="Cancel";
            var progress=new Progress<string>(value=>status.Text=value);
            try {
                string result=await Task.Run(()=> {
                    if(unregister) { cancellation.Token.ThrowIfCancellationRequested();InstallEngine.RemoveRegistration(paths,year);return "Registration removed. Restart Max. Personal content and recovery files were retained."; }
                    string parent=Path.Combine(Path.GetTempPath(),"CyrusScatterSetup"),extracted=null;
                    Action<string> checkpoint=value=> { cancellation.Token.ThrowIfCancellationRequested();((IProgress<string>)progress).Report(value.StartsWith("extracting:")?"Unpacking plugin and library…":"Installing verified plugin and library files…"); };
                    try { extracted=Distribution.Extract(Assembly.GetExecutingAssembly(),parent,BuildIdentity.PackageHashes[index],checkpoint,BuildIdentity.Resources[index]);
                        var engine=new InstallEngine(extracted,BuildIdentity.InventoryHashes[index]);if(engine.Year!=year)throw new IOException("Selected host and payload differ.");engine.Install(paths,checkpoint);
                    }catch { if(extracted!=null)try{Distribution.Cleanup(parent,extracted);}catch(IOException){} throw; }
                    string completed="Installed for Max "+year+". Restart Max. Select terrain, then use the Cyrus Library action (Cyrus category), or Layers > Recipes.";
                    try{Distribution.Cleanup(parent,extracted);}catch(IOException error){completed+=" Temporary extraction was retained: "+error.Message;}
                    return completed;
                });
                status.Text=result;
            }catch(OperationCanceledException){status.Text="Cancelled. Previous plugin registration was retained.";}
            catch(Exception error){status.Text="Installation did not complete: "+error.Message;}
            finally {busy=false;cancellation.Dispose();cancellation=null;close.Text="Close";host.Enabled=browse.Enabled=true;RefreshDestination();}
        }
    }
    static class Program {
        [STAThread] static void Main() { Application.EnableVisualStyles();Application.SetCompatibleTextRenderingDefault(false);Application.Run(new SetupWindow()); }
    }
}
