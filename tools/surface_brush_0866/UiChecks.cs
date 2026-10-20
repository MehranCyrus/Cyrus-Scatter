using System;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Threading.Tasks;
using System.Windows.Forms;
using Cyrus.Setup;
static class UiChecks {
 static int checks;
 static BindingFlags flags=BindingFlags.Instance|BindingFlags.NonPublic;
 static void Check(bool value,string message){if(!value)throw new Exception(message);checks++;Console.WriteLine("PASS: "+message);}
 static T Field<T>(Form f,string name){return (T)f.GetType().GetField(name,flags).GetValue(f);}
 static void Invoke(Form f,string name,params object[] args){f.GetType().GetMethod(name,flags).Invoke(f,args);Application.DoEvents();}
 static void Fits(Control c){foreach(Control child in c.Controls)if(child.Visible){Check(child.Left>=0&&child.Top>=0&&child.Right<=c.ClientSize.Width&&child.Bottom<=c.ClientSize.Height,"Visible control fits: "+child.GetType().Name);Fits(child);}}
 [STAThread] static int Main(string[] args){try{
  string root=Path.GetFullPath(args[1]);if(!root.StartsWith(@"D:\CyrusScatterBuilds\if0866\",StringComparison.OrdinalIgnoreCase))throw new Exception("Owned UI recipient required");
  Directory.CreateDirectory(root);Application.EnableVisualStyles();var a=Assembly.LoadFrom(args[0]);
  using(var f=(Form)Activator.CreateInstance(a.GetType("Cyrus.Setup.SetupWindow"),true)){
   f.ShowInTaskbar=false;f.StartPosition=FormStartPosition.Manual;f.Location=new Point(-32000,-32000);f.Show();Application.DoEvents();
   var host=Field<ComboBox>(f,"host");var profile=Field<TextBox>(f,"profile");var details=Field<TextBox>(f,"details");
   Check(host.Items.Count==1,"Only qualified Max 2027 is offered");
   Check(!profile.Visible&&!details.Visible&&!Field<Button>(f,"remove").Visible,"Normal view has version/install controls and hides technical paths");
   Check(!String.Join(",",new[]{host.Items[0].ToString()}).Contains("preview"),"Host captions do not carry the retired preview label");
   Fits(f);using(var bitmap=new Bitmap(f.Width,f.Height)){f.DrawToBitmap(bitmap,new Rectangle(Point.Empty,bitmap.Size));bitmap.Save(Path.Combine(args[2],"installer-simple.png"));}
   Invoke(f,"SetExpanded",true);Check(profile.Visible&&details.Visible&&Field<Button>(f,"copy").Visible,"Details provides a full scrollable/copyable report");Fits(f);
   Invoke(f,"SetExpanded",false);f.Scale(new SizeF(1.5f,1.5f));f.PerformLayout();Application.DoEvents();Fits(f);
   Invoke(f,"SetExpanded",true);Fits(f);using(var bitmap=new Bitmap(f.Width,f.Height)){f.DrawToBitmap(bitmap,new Rectangle(Point.Empty,bitmap.Size));bitmap.Save(Path.Combine(args[2],"installer-details-150.png"));}Invoke(f,"SetExpanded",false);
   for(int i=0;i<host.Items.Count;i++){
    host.SelectedIndex=i;string year=host.Items[i].ToString().Substring(8);string p=Path.Combine(root,"ui"+year,"p");Directory.CreateDirectory(p);
    string ini=Path.Combine(p,"3dsMax.ini");string scripts=Path.Combine(p,"scripts"),startup=Path.Combine(p,"startup"),macros=Path.Combine(p,"macros");
    File.WriteAllText(ini,"[Directories]\r\nAdditional Scripts="+scripts+"\r\nAdditional Startup Scripts="+startup+"\r\nAdditional Macros="+macros+"\r\n",System.Text.Encoding.Unicode);
    profile.Text=ini;Invoke(f,"RefreshDestination",true);Check(Field<Button>(f,"install").Enabled,"Detected host can install to its owned initialized profile "+year);
    var task=(Task)f.GetType().GetMethod("Run",flags).Invoke(f,new object[]{false});
    var clock=System.Diagnostics.Stopwatch.StartNew();while(!task.IsCompleted&&clock.ElapsedMilliseconds<90000){Application.DoEvents();System.Threading.Thread.Sleep(10);}task.GetAwaiter().GetResult();Application.DoEvents();
    string message=Field<Label>(f,"status").Text;Check(message.StartsWith("Installed for Max "+year+"."),"Actual async EXE Install handler succeeds and retains completion status "+year+": "+message);
    Check(File.Exists(Path.Combine(scripts,"CyrusScatter","installed.txt")),"Actual handler writes the owned installation receipt "+year);
    if(i==0){
     string release=File.ReadAllLines(Path.Combine(scripts,"CyrusScatter","installed.txt"))[2],asset=Path.Combine(release,"CyrusGallery.dll");
     byte[] original=File.ReadAllBytes(asset);File.WriteAllText(asset,"owned modified file for rejection probe");
     try {
      task=(Task)f.GetType().GetMethod("Run",flags).Invoke(f,new object[]{false});clock.Restart();
      while(!task.IsCompleted&&clock.ElapsedMilliseconds<90000){Application.DoEvents();System.Threading.Thread.Sleep(10);}task.GetAwaiter().GetResult();Application.DoEvents();
      Check(Field<Label>(f,"status").Text.StartsWith("Installation did not complete."),"Actual handler reports a failed repair without replacing its status");
      Check(details.Visible&&details.Text.Contains("Log:")&&details.Text.Contains("CyrusGallery.dll"),"Failure expands Details with the complete filename and saved log");
      Check(File.ReadAllText(asset)=="owned modified file for rejection probe","Failed repair preserves the modified file");
      using(var bitmap=new Bitmap(f.Width,f.Height)){f.DrawToBitmap(bitmap,new Rectangle(Point.Empty,bitmap.Size));bitmap.Save(Path.Combine(args[2],"installer-failure.png"));}
     }finally{File.WriteAllBytes(asset,original);Invoke(f,"SetExpanded",false);}
    }
   }
  }
  Console.WriteLine("PASSED "+checks+" actual installer UI/layout/handler checks");return 0;
 }catch(Exception e){Console.WriteLine(e);return 1;}}
}
