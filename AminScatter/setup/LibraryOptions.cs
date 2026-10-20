using System;
using System.Drawing;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Cyrus.Setup {
    // Shared presentation for EXE and hosted MZP. Checks run inside Install/Update.
    public sealed class InstallerView : UserControl {
        public readonly Button Primary=new Button {Text="Install",Width=138,Height=40};
        public readonly Button Uninstall=new Button {Text="Uninstall",Width=105,Height=40};
        public readonly Button CloseButton=new Button {Text="Close",Width=88,Height=40};
        public readonly CheckBox InstallContent=new CheckBox {Text="Install / update plant library",Dock=DockStyle.Top,Height=32,AutoSize=false};
        readonly Label contentHint=new Label {Text="Optional. Place the content ZIP beside the EXE. One library is shared by all Max versions.",Dock=DockStyle.Top,Height=42,ForeColor=Color.FromArgb(89,103,111)};
        public readonly Label Status=new Label {Dock=DockStyle.Top,Height=84,Padding=new Padding(0,14,0,8)};
        public readonly TextBox Details=new TextBox {Dock=DockStyle.Fill,Multiline=true,ReadOnly=true,ScrollBars=ScrollBars.Vertical,Visible=false,BackColor=Color.FromArgb(245,247,249),BorderStyle=BorderStyle.FixedSingle};
        readonly ProgressBar progress=new ProgressBar {Dock=DockStyle.Top,Height=5,Visible=false,Style=ProgressBarStyle.Marquee};
        readonly LinkLabel detailsLink=new LinkLabel {Text="Error details",Visible=false,AutoSize=true,Margin=new Padding(0,13,20,0),LinkColor=Color.FromArgb(66,87,102)};
        public InstallerView() {
            Dock=DockStyle.Fill;BackColor=Color.White;
            var row=new FlowLayoutPanel {Dock=DockStyle.Bottom,Height=54,FlowDirection=FlowDirection.RightToLeft,WrapContents=false};
            foreach(var button in new[]{CloseButton,Uninstall,Primary}) {
                button.FlatStyle=FlatStyle.Flat;button.FlatAppearance.BorderColor=Color.FromArgb(210,216,220);
                button.BackColor=Color.White;button.Cursor=Cursors.Hand;button.Margin=new Padding(8,6,0,6);row.Controls.Add(button);
            }
            Primary.BackColor=Color.FromArgb(27,119,93);Primary.ForeColor=Color.White;Primary.FlatAppearance.BorderSize=0;
            row.Controls.Add(detailsLink);
            Controls.Add(Details);Controls.Add(progress);Controls.Add(Status);Controls.Add(contentHint);Controls.Add(InstallContent);Controls.Add(row);
            detailsLink.Click+=(s,e)=>{Details.Visible=!Details.Visible;detailsLink.Text=Details.Visible?"Hide details":"Details";var form=FindForm();if(form!=null)form.Height+=Details.Visible?190:-190;};
        }
        public void SetBusy(bool value) {
            Primary.Enabled=Uninstall.Enabled=InstallContent.Enabled=!value;progress.Visible=value;CloseButton.Text=value?"Cancel":"Close";
            if(value)SetFailure(false);
        }
        public void SetFailure(bool failed) {
            if(Details.Visible){Details.Visible=false;var form=FindForm();if(form!=null)form.Height-=190;}
            detailsLink.Visible=failed;detailsLink.Text="Error details";
        }
        public void HideContentChoice(){InstallContent.Visible=contentHint.Visible=false;}
        public void Report(string message) {
            if(IsDisposed)return;
            if(InvokeRequired){BeginInvoke(new Action<string>(Report),message);return;}
            Status.Text=message;
        }
    }
    public static class LibraryOptions {
        public static void ShowForMax(InstallEngine engine,InstallPaths paths) {
            using(var window=new Form {Text="Cyrus Scatter "+engine.Version,ClientSize=new Size(700,400),MinimumSize=new Size(620,410),StartPosition=FormStartPosition.CenterScreen,AutoScaleMode=AutoScaleMode.Dpi,Font=new Font("Segoe UI",10),BackColor=Color.White,Padding=new Padding(24)}) {
                var title=new Label {Text="Cyrus Scatter  /  Max "+engine.Year,Dock=DockStyle.Top,Height=58,Font=new Font("Segoe UI",17,FontStyle.Bold)};
                var view=new InstallerView();window.Controls.Add(view);window.Controls.Add(title);
                bool busy=false;CancellationTokenSource cancel=null;
                Action refresh=()=>{
                    bool installed=InstallEngine.InstalledVersion(paths).Length>0;
                    view.Primary.Text=installed?"Update":"Install";view.Uninstall.Enabled=installed;
                };
                view.HideContentChoice();
                refresh();view.Status.Text="Updates the plugin and keeps your library. Use the EXE to install the optional content ZIP.";
                Func<bool,Task> run=async remove=>{
                    if(busy)return;
                    if(remove&&MessageBox.Show(window,"Uninstall Cyrus Scatter from Max "+engine.Year+"? Your shared library and scenes will be kept.","Uninstall Cyrus Scatter",MessageBoxButtons.OKCancel)!=DialogResult.OK)return;
                    busy=true;cancel=new CancellationTokenSource();view.SetBusy(true);view.Report(remove?"Uninstalling Cyrus Scatter…":"Checking your installation…");
                    try {
                        string note="";
                        string result=await Task.Run(()=>{
                            Action<string> check=value=>cancel.Token.ThrowIfCancellationRequested();
                            if(remove){check("uninstall");InstallEngine.RemoveRegistration(paths,engine.Year);return "Registration removed. Shared content retained.";}
                            note=engine.ConfigureLibraryChoice(paths,false,engine.PackageDirectory);
                            string plan=engine.Plan(paths,check);view.Report("Installing Cyrus Scatter. Existing models are being reused…");
                            engine.Install(paths,check);return plan;
                        });
                        view.Details.Text=result;view.SetFailure(false);view.Status.Text=remove?"Uninstall completed. Restart Max.":"Installation completed. Restart Max.";
                    }catch(OperationCanceledException){view.Status.Text="Cancelled. Your previous complete installation is preserved.";}
                    catch(Exception error){view.Status.Text="Installation could not finish. "+error.Message.Split('\r','\n')[0];view.Details.Text=error+"\r\nLog: "+InstallEngine.SaveFailure(paths,error.ToString());view.SetFailure(true);}
                    finally {busy=false;cancel.Dispose();cancel=null;view.SetBusy(false);refresh();}
                };
                view.Primary.Click+=async(s,e)=>await run(false);view.Uninstall.Click+=async(s,e)=>await run(true);
                view.CloseButton.Click+=(s,e)=>{if(busy)cancel.Cancel();else window.Close();};
                window.FormClosing+=(s,e)=>{if(busy){e.Cancel=true;cancel.Cancel();}};
                window.ShowDialog();
            }
        }
    }
}
