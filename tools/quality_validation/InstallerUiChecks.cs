// Owns only explicit disposable destinations; does not launch or install into Max.
using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Threading.Tasks;
using System.Windows.Forms;
using Cyrus.Setup;
static class InstallerUiChecks {
    static int checks;
    const BindingFlags Private=BindingFlags.Instance|BindingFlags.NonPublic;
    static void Check(bool value,string message){if(!value)throw new Exception(message);++checks;Console.WriteLine("PASS: "+message);}
    static T Field<T>(Form form,string name){return (T)form.GetType().GetField(name,Private).GetValue(form);}
    static void Run(Form form){
        var task=(Task)form.GetType().GetMethod("Run",Private).Invoke(form,new object[]{false});
        var clock=System.Diagnostics.Stopwatch.StartNew();
        while(!task.IsCompleted&&clock.ElapsedMilliseconds<90000){Application.DoEvents();System.Threading.Thread.Sleep(10);}
        Check(task.IsCompleted,"Async installer finishes within the fixture deadline");task.GetAwaiter().GetResult();Application.DoEvents();
    }
    static void Capture(Form form,string path){using(var image=new Bitmap(form.Width,form.Height)){form.DrawToBitmap(image,new Rectangle(Point.Empty,image.Size));image.Save(path);}}
    [STAThread] static int Main(string[] args){try{
        string output=Path.GetFullPath(args[1]);
        if(!output.Contains("\\build\\installer-panels-08684-20261022\\"))throw new Exception("Owned test directory required");
        Directory.CreateDirectory(output);Application.EnableVisualStyles();
        var assembly=Assembly.LoadFrom(Path.GetFullPath(args[0]));
        using(var form=(Form)Activator.CreateInstance(assembly.GetType("Cyrus.Setup.SetupWindow"),true)){
            form.ShowInTaskbar=false;form.StartPosition=FormStartPosition.Manual;form.Location=new Point(-32000,-32000);form.Show();Application.DoEvents();
            var cards=Field<TableLayoutPanel>(form,"cards");var view=Field<InstallerView>(form,"view");
            Check(cards.ColumnCount==1&&cards.Controls.Count==1,"Max 2027 package uses one full-width host card");
            foreach(Control control in form.Controls)if(control is Label&&control.Text=="Cyrus Scatter"){
                int required=TextRenderer.MeasureText(control.Text,control.Font).Height;
                Check(control.Height>=required,"Installer title fits its font (height "+control.Height+", required "+required+")");
            }
            Capture(form,Path.Combine(output,"installer-100.png"));
            form.Scale(new SizeF(1.5f,1.5f));form.PerformLayout();Application.DoEvents();
            Capture(form,Path.Combine(output,"installer-150.png"));
            string profile=Path.Combine(output,"recipient");Directory.CreateDirectory(profile);
            string scripts=Path.Combine(profile,"scripts"),startup=Path.Combine(profile,"startup"),macros=Path.Combine(profile,"macros");
            Directory.CreateDirectory(startup);Directory.CreateDirectory(macros);
            using(var zip=ZipFile.OpenRead(Path.GetFullPath(args[2])))foreach(string name in new[]{"CyrusScatterStartup.ms","CyrusScatter.mcr"})
                zip.GetEntry(name).ExtractToFile(Path.Combine(name.EndsWith(".mcr")?macros:startup,name));
            string ini=Path.Combine(profile,"3dsMax.ini");
            File.WriteAllText(ini,"[Directories]\r\nAdditional Scripts="+scripts+"\r\nAdditional Startup Scripts="+startup+"\r\nAdditional Macros="+macros+"\r\n",System.Text.Encoding.Unicode);
            var profiles=Field<Dictionary<string,string>>(form,"profiles");profiles["2027"]=ini;
            var hosts=Field<Dictionary<string,CheckBox>>(form,"hosts");hosts["2027"].Enabled=true;hosts["2027"].Checked=true;
            form.GetType().GetField("hostRunning",Private|BindingFlags.Public).SetValue(form,new Func<string,bool>(year=>false));
            Run(form);Check(view.Status.Text=="Installation completed. You can now open Max.","Actual EXE handler migrates the older wrappers");
            Check(File.Exists(Path.Combine(scripts,"CyrusScatter","installed.txt")),"Actual handler writes the owned receipt");
            Run(form);Check(view.Status.Text=="Installation completed. You can now open Max.","Actual EXE repeated update succeeds");
            string edited=Path.Combine(macros,"CyrusScatter.mcr");File.WriteAllText(edited,"Preserved custom macro");
            Run(form);Check(view.Status.Text.Contains("Max 2027")&&view.Details.Text.Contains(edited),"Failure names the host and exact conflicting file");
            Check(File.ReadAllText(edited)=="Preserved custom macro","Actual EXE handler preserves unknown edits");
            Capture(form,Path.Combine(output,"installer-error.png"));
        }
        Console.WriteLine("PASSED "+checks+" installer UI/actual-handler checks");return 0;
    }catch(Exception error){Console.WriteLine(error);return 1;}}
}
