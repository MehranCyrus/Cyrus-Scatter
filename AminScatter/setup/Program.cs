using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

[assembly: System.Runtime.Versioning.TargetFramework(".NETFramework,Version=v4.8")]

namespace Cyrus.Setup {
    sealed class SetupWindow : Form {
        readonly TextBox profile=new TextBox(),details=new TextBox();
        readonly Button browse=new Button(),install=new Button(),remove=new Button(),close=new Button(),copy=new Button();
        readonly LinkLabel more=new LinkLabel();
        readonly Label status=new Label();
        readonly ComboBox host=new ComboBox {DropDownStyle=ComboBoxStyle.DropDownList,Dock=DockStyle.Fill};
        readonly TableLayoutPanel layout=new TableLayoutPanel(),advanced=new TableLayoutPanel();
        readonly List<string> years=new List<string>();
        string Year {get{return years[host.SelectedIndex];}}
        CancellationTokenSource cancellation;bool busy,expanded;string failure="";
        public SetupWindow() {
            AppContext.SetSwitch("Switch.System.IO.UseLegacyPathHandling",false);
            AppContext.SetSwitch("Switch.System.IO.BlockLongPaths",false);
            Text="Cyrus Scatter "+BuildIdentity.Version;StartPosition=FormStartPosition.CenterScreen;
            Font=new Font("Segoe UI",10);AutoScaleMode=AutoScaleMode.Dpi;ClientSize=new Size(600,264);MinimumSize=new Size(540,295);
            layout.Dock=DockStyle.Fill;layout.Padding=new Padding(16);layout.ColumnCount=1;layout.RowCount=6;
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100));
            foreach(int height in new[]{40,36,38,62,0,44})layout.RowStyles.Add(new RowStyle(SizeType.Absolute,height));
            layout.Controls.Add(new Label {Text="Install Cyrus Scatter "+BuildIdentity.Version,Font=new Font(Font,FontStyle.Bold),AutoSize=true,Dock=DockStyle.Fill},0,0);
            layout.Controls.Add(new Label {Text="Choose your 3ds Max version. Includes the library and starter patterns.",AutoSize=true,Dock=DockStyle.Fill},0,1);
            foreach(string year in BuildIdentity.Years)try{Distribution.DetectMax(year);years.Add(year);host.Items.Add("3ds Max "+year);}catch(IOException){}
            layout.Controls.Add(host,0,2);host.SelectedIndex=years.Count-1;
            status.Dock=DockStyle.Fill;layout.Controls.Add(status,0,3);
            advanced.ColumnCount=2;advanced.RowCount=3;advanced.Dock=DockStyle.Fill;
            advanced.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100));advanced.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
            advanced.RowStyles.Add(new RowStyle(SizeType.Absolute,26));advanced.RowStyles.Add(new RowStyle(SizeType.Absolute,34));advanced.RowStyles.Add(new RowStyle(SizeType.Percent,100));
            advanced.Controls.Add(new Label {Text="Detected Max configuration",AutoSize=true,Dock=DockStyle.Fill},0,0);advanced.SetColumnSpan(advanced.Controls[0],2);
            profile.Dock=DockStyle.Fill;profile.ReadOnly=true;advanced.Controls.Add(profile,0,1);
            browse.Text="Browse…";browse.AutoSize=true;advanced.Controls.Add(browse,1,1);
            details.Multiline=true;details.ReadOnly=true;details.ScrollBars=ScrollBars.Both;details.WordWrap=false;details.Dock=DockStyle.Fill;
            advanced.Controls.Add(details,0,2);advanced.SetColumnSpan(details,2);advanced.Visible=false;layout.Controls.Add(advanced,0,4);
            var footer=new TableLayoutPanel {Dock=DockStyle.Fill,ColumnCount=2,RowCount=1};footer.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100));footer.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
            more.Text="Details";more.AutoSize=true;more.Anchor=AnchorStyles.Left;footer.Controls.Add(more,0,0);
            var buttons=new FlowLayoutPanel {AutoSize=true,Dock=DockStyle.Fill,FlowDirection=FlowDirection.RightToLeft,WrapContents=false};
            close.Text="Close";install.Text="Install / Repair";remove.Text="Unregister";copy.Text="Copy details";
            foreach(var button in new[]{close,install,remove,copy}){button.AutoSize=true;buttons.Controls.Add(button);}
            remove.Visible=copy.Visible=false;footer.Controls.Add(buttons,1,0);layout.Controls.Add(footer,0,5);Controls.Add(layout);
            host.SelectedIndexChanged+=(s,e)=>{failure="";SetProfile();RefreshDestination();};
            more.LinkClicked+=(s,e)=>SetExpanded(!expanded);
            copy.Click+=(s,e)=>{if(details.Text.Length>0)Clipboard.SetText(details.Text);};
            browse.Click+=(s,e)=>{using(var dialog=new OpenFileDialog {Filter="Max configuration (*.ini)|*.ini",Title="Choose Max "+Year+" configuration"})if(dialog.ShowDialog(this)==DialogResult.OK){profile.Text=dialog.FileName;failure="";RefreshDestination();}};
            install.Click+=async(s,e)=>await Run(false);remove.Click+=async(s,e)=>await Run(true);
            close.Click+=(s,e)=>{if(busy){cancellation.Cancel();status.Text="Cancelling safely…";}else Close();};
            FormClosing+=(s,e)=>{if(busy){e.Cancel=true;cancellation.Cancel();status.Text="Cancelling safely…";}};
            SetProfile();RefreshDestination();
        }
        void SetExpanded(bool value) {
            if(expanded==value)return;
            expanded=value;float scale=Font.SizeInPoints/10f;
            layout.RowStyles[4].Height=value?230*scale:0;advanced.Visible=value;remove.Visible=copy.Visible=value;
            ClientSize=new Size(ClientSize.Width,ClientSize.Height+(int)((value?230:-230)*scale));more.Text=value?"Hide details":"Details";
        }
        void SetProfile() {
            profile.Text="";if(host.SelectedIndex<0)return;
            try{profile.Text=Distribution.FindProfile(Year);}catch(IOException error){status.Text=error.Message;}
        }
        void RefreshDestination(bool updateStatus=true) {
            try {
                if(host.SelectedIndex<0)throw new IOException("No supported Max installation found. Install and open Max 2024, 2026 or 2027 first.");
                string executable=Distribution.DetectMax(Year);
                if(profile.Text.Length==0)profile.Text=Distribution.FindProfile(Year);
                var paths=Distribution.FromProfile(profile.Text,Year);
                string destination="Max: "+executable+"\r\nPlugin and library: "+paths.RuntimeRoot+"\r\nStartup: "+paths.Startup+"\r\nMacros: "+paths.Macros;
                details.Text=failure.Length>0?failure+"\r\n\r\n"+destination:destination;
                if(updateStatus)status.Text="Ready for Max "+Year+". Close that Max version before installing.\nRestart it after installation.";
                install.Enabled=remove.Enabled=true;
            }catch(Exception error){details.Text=failure.Length>0?failure:error.Message;if(updateStatus)status.Text=error.Message;install.Enabled=remove.Enabled=false;}
        }
        async Task Run(bool unregister) {
            InstallPaths paths;string year=Year;int index=Array.IndexOf(BuildIdentity.Years,year);
            try{Distribution.DetectMax(year);paths=Distribution.FromProfile(profile.Text,year);}catch(Exception error){status.Text=error.Message;return;}
            if(unregister&&MessageBox.Show(this,"Remove Cyrus Scatter registration? Personal recipes, activation and recovery files will be retained.","Unregister Cyrus Scatter",MessageBoxButtons.OKCancel)!=DialogResult.OK)return;
            busy=true;failure="";cancellation=new CancellationTokenSource();host.Enabled=browse.Enabled=install.Enabled=remove.Enabled=false;close.Text="Cancel";
            var progress=new Progress<string>(value=>status.Text=value);
            try {
                string result=await Task.Run(()=>{
                    if(unregister){cancellation.Token.ThrowIfCancellationRequested();InstallEngine.RemoveRegistration(paths,year);return "Registration removed. Restart Max. Personal content was retained.";}
                    string parent=Path.Combine(Path.GetTempPath(),"CyrusSetup"),extracted=null;
                    Action<string> checkpoint=value=>{cancellation.Token.ThrowIfCancellationRequested();((IProgress<string>)progress).Report(value.StartsWith("extracting:")?"Unpacking plugin and library…":"Installing verified files…");};
                    try {
                        extracted=Distribution.Extract(Assembly.GetExecutingAssembly(),parent,BuildIdentity.PackageHashes[index],checkpoint,BuildIdentity.Resources[index]);
                        var engine=new InstallEngine(extracted,BuildIdentity.InventoryHashes[index]);if(engine.Year!=year)throw new IOException("Selected Max version and payload differ.");engine.Install(paths,checkpoint);
                    }catch {
                        if(extracted!=null)try{Distribution.Cleanup(parent,extracted);}catch(IOException){}
                        throw;
                    }
                    try{Distribution.Cleanup(parent,extracted);}catch(IOException error){
                        string log=InstallEngine.SaveFailure(paths,"Installation completed; temporary extraction retained.\r\n"+error);
                        return "Installed for Max "+year+". Restart Max.\nTemporary files were retained; details: "+log;
                    }
                    return "Installed for Max "+year+". Restart Max to use Cyrus Scatter.\nSelect terrain, then open Cyrus Library.";
                });
                status.Text=result;
            }catch(OperationCanceledException){status.Text="Cancelled. Previous registration was retained.";}
            catch(Exception error){
                string log=InstallEngine.SaveFailure(paths,error.ToString());failure=error+"\r\n\r\nLog: "+log;
                status.Text="Installation did not complete. Full error details are shown below.";SetExpanded(true);
            }
            finally{busy=false;cancellation.Dispose();cancellation=null;close.Text="Close";host.Enabled=browse.Enabled=true;RefreshDestination(false);}
        }
    }
    static class Program {
        [STAThread] static void Main(){Application.EnableVisualStyles();Application.SetCompatibleTextRenderingDefault(false);Application.Run(new SetupWindow());}
    }
}
