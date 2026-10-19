using System;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Windows.Forms;
using CyrusScatter.UI;
static class ManagedGalleryChecks {
    static int count;
    static void Check(bool value,string text){if(!value)throw new Exception(text);count++;Console.WriteLine("PASS: "+text);}
    [STAThread] static int Main(string[] args){try{
        Application.EnableVisualStyles();
        using(var form=new Form())using(var panel=new LibraryPanel()) {
            form.ShowInTaskbar=false;form.StartPosition=FormStartPosition.Manual;form.Location=new Point(-32000,-32000);
            form.Controls.Add(panel);panel.Dock=DockStyle.Fill;form.Show();
            panel.SetNavigation(1,"",false);panel.HasSetup=false;panel.SetSelectionActions(true,true,false);
            var flags=BindingFlags.Instance|BindingFlags.NonPublic;
            var save=(ToolStripButton)typeof(LibraryPanel).GetField("save",flags).GetValue(panel);
            var load=(ToolStripButton)typeof(LibraryPanel).GetField("load",flags).GetValue(panel);
            var view=(ToolStripDropDownButton)typeof(LibraryPanel).GetField("view",flags).GetValue(panel);
            var toolbar=(ToolStrip)typeof(LibraryPanel).GetField("toolbar",flags).GetValue(panel);
            Check(load.Enabled&&load.Text=="Load onto surface"&&!save.Enabled,"Rootless selection can load; Save requires a setup");
            panel.HasSetup=true;panel.SetSelectionActions(true,true,false);Check(save.Enabled,"Save becomes available on the imported setup");
            foreach(double scale in new[]{0.0,1.0,1.5}) {
                double effective=scale==0?1:scale;form.ClientSize=new Size((int)(1000*effective),(int)(680*effective));panel.UserScale=scale;Application.DoEvents();
                Check(Math.Abs(panel.Font.SizeInPoints-9*effective)<0.01,"Readable font at UI scale "+scale);
                foreach(Control control in panel.Controls)Check(control.Left>=0&&control.Top>=0&&control.Right<=panel.Width&&control.Bottom<=panel.Height,"Control fits at scale "+scale+": "+control.GetType().Name);
                using(var bitmap=new Bitmap(panel.Width,panel.Height)){panel.DrawToBitmap(bitmap,new Rectangle(0,0,bitmap.Width,bitmap.Height));bitmap.Save(Path.Combine(args[3],"gallery-net48-scale-"+scale+".png"));}
            }
            panel.UserScale=1;view.Select();
            using(var bitmap=new Bitmap(view.Width,view.Height))using(var graphics=Graphics.FromImage(bitmap)) {
                toolbar.Renderer.DrawDropDownButtonBackground(new ToolStripItemRenderEventArgs(graphics,view));
                if(!SystemInformation.HighContrast)Check(bitmap.GetPixel(2,2).R<100,"Selected dropdown uses an explicit dark background");
                var text=new ToolStripItemTextRenderEventArgs(graphics,view,"Thumbnails",new Rectangle(0,0,view.Width,view.Height),Color.Black,panel.Font,TextFormatFlags.Default);
                toolbar.Renderer.DrawItemText(text);if(!SystemInformation.HighContrast)Check(text.TextColor==Color.White,"Selected dropdown text remains white on dark background");
                view.Enabled=false;toolbar.Renderer.DrawItemText(text);if(!SystemInformation.HighContrast)Check(text.TextColor.R==155,"Disabled dropdown text uses readable disabled color");
            }
            panel.Gallery.BeginPage();panel.Gallery.AddItem("thumbnail","Real PNG","",Path.GetFullPath(args[0]),args[1],Int32.Parse(args[2]));panel.Gallery.EndPage(0);
            var clock=System.Diagnostics.Stopwatch.StartNew();while(panel.Gallery.ImagesDecoded==0&&clock.ElapsedMilliseconds<10000){Application.DoEvents();System.Threading.Thread.Sleep(10);}
            Check(panel.Gallery.ImagesDecoded==1&&panel.Gallery.DecodedBytes>0,"Bounded PNG worker decodes and publishes on .NET Framework 4.8");
        }
        Console.WriteLine("PASSED "+count+" managed gallery checks");return 0;
    }catch(Exception error){Console.WriteLine(error);return 1;}}
}
