// File-only thumbnail workers. All controls, cache ownership and events stay on the UI thread.
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Security.Cryptography;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Globalization;

[assembly: AssemblyVersion("0.86.8.2")]
[assembly: AssemblyFileVersion("0.86.8.2")]
namespace CyrusScatter.UI
{
    // Bounded data-only JSON reader shared by the three supported managed runtimes.
    // No serializer assembly deployment or executable catalog content.
    internal sealed class CatalogJson
    {
        readonly object value;
        CatalogJson(object value){this.value=value;}
        internal CatalogJson GetProperty(string key)=>((Dictionary<string,CatalogJson>)value)[key];
        internal string GetString()=>value as string??throw new InvalidDataException("Expected catalog text.");
        internal long GetInt64()=>value is long number?number:throw new InvalidDataException("Expected catalog integer.");
        internal int GetInt32()=>checked((int)GetInt64());
        internal bool IsArray=>value is List<CatalogJson>;
        internal int GetArrayLength()=>((List<CatalogJson>)value).Count;
        internal IEnumerable<CatalogJson> EnumerateArray()=>(List<CatalogJson>)value;
        internal static CatalogJson Parse(byte[] bytes)
        {
            string text=new UTF8Encoding(false,true).GetString(bytes);int at=0,nodes=0;
            void Space(){while(at<text.Length&&" \r\n\t".IndexOf(text[at])>=0)at++;}
            InvalidDataException Invalid()=>new("Invalid model catalog JSON.");
            void Take(char c){Space();if(at>=text.Length||text[at++]!=c)throw Invalid();}
            string ReadString(){
                Take('"');var result=new StringBuilder();
                while(at<text.Length){char c=text[at++];if(c=='"')return result.ToString();if(c<32)throw Invalid();
                    if(c=='\\'){if(at>=text.Length)throw Invalid();c=text[at++];
                        switch(c){case '"':case '\\':case '/':break;case 'n':c='\n';break;case 'r':c='\r';break;case 't':c='\t';break;case 'b':c='\b';break;case 'f':c='\f';break;
                        case 'u':if(at+4>text.Length||!UInt16.TryParse(text.Substring(at,4),NumberStyles.HexNumber,CultureInfo.InvariantCulture,out ushort code))throw Invalid();c=(char)code;at+=4;break;
                        default:throw Invalid();}
                    }result.Append(c);
                }throw Invalid();
            }
            CatalogJson Read(int depth){
                if(depth>16||++nodes>32768)throw Invalid();Space();if(at>=text.Length)throw Invalid();
                if(text[at]=='"')return new(ReadString());
                if(text[at]=='{'){
                    at++;var result=new Dictionary<string,CatalogJson>(StringComparer.Ordinal);Space();
                    if(at<text.Length&&text[at]=='}'){at++;return new(result);}
                    while(true){string key=ReadString();Take(':');if(result.ContainsKey(key))throw Invalid();result.Add(key,Read(depth+1));Space();
                        if(at>=text.Length)throw Invalid();char end=text[at++];if(end=='}')return new(result);if(end!=',')throw Invalid();}
                }
                if(text[at]=='['){
                    at++;var result=new List<CatalogJson>();Space();if(at<text.Length&&text[at]==']'){at++;return new(result);}
                    while(true){result.Add(Read(depth+1));Space();if(at>=text.Length)throw Invalid();char end=text[at++];if(end==']')return new(result);if(end!=',')throw Invalid();}
                }
                foreach(string word in new[]{"true","false","null"})if(at+word.Length<=text.Length&&text.Substring(at,word.Length)==word){at+=word.Length;return new(word=="null"?DBNull.Value:(object)(word=="true"));}
                int start=at;if(text[at]=='-')at++;if(at>=text.Length||text[at]<'0'||text[at]>'9')throw Invalid();
                bool zero=text[at++]=='0';if(!zero)while(at<text.Length&&text[at]>='0'&&text[at]<='9')at++;
                // Metadata may contain dimensions. Follow JSON's number grammar;
                // integer-only fields still reject decimal/exponent forms.
                bool realToken=false;
                if(at<text.Length&&text[at]=='.'){
                    realToken=true;at++;int digits=at;
                    while(at<text.Length&&text[at]>='0'&&text[at]<='9')at++;
                    if(at==digits)throw Invalid();
                }
                if(at<text.Length&&(text[at]=='e'||text[at]=='E')){
                    realToken=true;at++;if(at<text.Length&&(text[at]=='+'||text[at]=='-'))at++;
                    int digits=at;while(at<text.Length&&text[at]>='0'&&text[at]<='9')at++;
                    if(at==digits)throw Invalid();
                }
                string token=text.Substring(start,at-start);
                if(!realToken&&Int64.TryParse(token,NumberStyles.AllowLeadingSign,CultureInfo.InvariantCulture,out long number))return new(number);
                if(Double.TryParse(token,NumberStyles.Float,CultureInfo.InvariantCulture,out double real)&&!Double.IsNaN(real)&&!Double.IsInfinity(real))return new(real);
                throw Invalid();
            }
            if(text.Length>0&&text[0]=='\ufeff')at++;
            var root=Read(0);Space();if(at!=text.Length)throw Invalid();return root;
        }
    }
    // Data-only installed models. Reading a catalog never opens a Max scene or runs code.
    public sealed class IndividualModelEntry
    {
        public string Id {get;internal set;}="";
        public string Name {get;internal set;}="";
        public string Category {get;internal set;}="";
        public string Scene {get;internal set;}="";
        public string NodeName {get;internal set;}="";
        public string SceneHash {get;internal set;}="";
        public long SceneBytes {get;internal set;}
        public string Thumbnail {get;internal set;}="";
        public string ThumbnailHash {get;internal set;}="";
        public int ThumbnailBytes {get;internal set;}
    }
    public sealed class IndividualModelCatalog
    {
        const long MaximumSceneBytes=2L*1024*1024*1024;
        readonly List<IndividualModelEntry> entries=new();
        readonly List<string> categories=new();
        public string Root {get;private set;}="";
        public int Count=>entries.Count;
        public int CategoryCount=>categories.Count;
        public string CategoryAt(int index)=>categories[index];
        static string Hash(string path)
        {using var stream=File.OpenRead(path);using var sha=SHA256.Create();return BitConverter.ToString(sha.ComputeHash(stream)).Replace("-","").ToLowerInvariant();}
        static string Text(CatalogJson item,string key,int maximum)
        {
            string value=item.GetProperty(key).GetString()??"";
            if(value.Length<1||value.Length>maximum||value.Trim()!=value)throw new InvalidDataException("Invalid model field: "+key);
            foreach(char c in value)if(Char.IsControl(c))throw new InvalidDataException("Invalid model field: "+key);
            return value;
        }
        static void NoLinks(string path)
        {
            for(string? at=path;!String.IsNullOrEmpty(at);at=Path.GetDirectoryName(at))
                if((File.Exists(at)||Directory.Exists(at))&&(File.GetAttributes(at)&FileAttributes.ReparsePoint)!=0)
                    throw new IOException("Model content cannot use linked folders or files.");
        }
        public string ContentPath(string relative)
        {
            if(relative.Length<1||relative.Length>220||relative.IndexOf(':')>=0||relative.IndexOf('\\')>=0||relative.StartsWith("/",StringComparison.Ordinal))throw new InvalidDataException("Invalid model content path.");
            foreach(string part in relative.Split('/'))
                if(part.Length==0||part=="."||part==".."||part.TrimEnd(' ','.')!=part||part.IndexOfAny(Path.GetInvalidFileNameChars())>=0)
                    throw new InvalidDataException("Invalid model content path.");
            string result=Path.GetFullPath(Path.Combine(Root,relative.Replace('/',Path.DirectorySeparatorChar)));
            if(!result.StartsWith(Root+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)||result.Length>=260)throw new IOException("Model path exceeds the installed content root.");
            NoLinks(result);return result;
        }
        public string MapPath(string relative)
        {
            relative=relative.Replace('\\','/');
            if(!relative.StartsWith("Maps/",StringComparison.Ordinal))throw new IOException("Model image is outside its installed Maps folder.");
            string path=ContentPath(relative);
            if(!File.Exists(path))throw new IOException("Installed model image is missing: "+relative);
            return path;
        }
        public void Load(string root,string version,int hostYear)
        {
            entries.Clear();categories.Clear();
            Root=Path.GetFullPath(root).TrimEnd(Path.DirectorySeparatorChar);NoLinks(Root);
            string manifest=ContentPath("model-catalog.json");var info=new FileInfo(manifest);
            if(!info.Exists||info.Length<1||info.Length>2*1024*1024)throw new IOException("Installed model catalog is missing or exceeds its bound.");
            using var stream=new FileStream(manifest,FileMode.Open,FileAccess.Read,FileShare.Read);
            if(stream.Length!=info.Length)throw new IOException("Model catalog changed while opening.");
            byte[] bytes=new byte[(int)info.Length];int offset=0,read;
            while(offset<bytes.Length&&(read=stream.Read(bytes,offset,bytes.Length-offset))>0)offset+=read;
            if(offset!=bytes.Length)throw new IOException("Model catalog ended while reading.");
            if(stream.ReadByte()!=-1)throw new IOException("Model catalog grew beyond its admitted size.");
            var document=CatalogJson.Parse(bytes);
            if(Text(document,"format",80)!="cyrus.individual-model-library"||document.GetProperty("formatVersion").GetInt32()!=1||
               (hostYear!=2024&&hostYear!=2026&&hostYear!=2027)||document.GetProperty("max_year").GetInt32()>hostYear||document.GetProperty("max_year").GetInt32()<2024||document.GetProperty("source_cards").GetInt32()!=104)
                throw new InvalidDataException("Model library format or required Max host is unsupported.");
            var rows=document.GetProperty("entries");
            if(!rows.IsArray||rows.GetArrayLength()<1||rows.GetArrayLength()>104)throw new InvalidDataException("Invalid individual model count.");
            var ids=new HashSet<string>(StringComparer.OrdinalIgnoreCase);var paths=new HashSet<string>(StringComparer.OrdinalIgnoreCase);long total=0;
            foreach(var row in rows.EnumerateArray())
            {
                var entry=new IndividualModelEntry{Id=Text(row,"id",80),Name=Text(row,"name",160),Category=Text(row,"category",80),NodeName=Text(row,"node_name",100),SceneHash=Text(row,"scene_sha256",64),SceneBytes=row.GetProperty("scene_bytes").GetInt64()};
                if(!ids.Add(entry.Id)||entry.NodeName!="CyrusModel_"+entry.Id||entry.SceneHash.Length!=64||row.GetProperty("geometry_count").GetInt32()!=1||entry.SceneBytes<1||entry.SceneBytes>MaximumSceneBytes)
                    throw new InvalidDataException("Invalid independent model record.");
                foreach(char c in entry.Id)if(!(c>='A'&&c<='Z'||c>='a'&&c<='z'||c>='0'&&c<='9'||c=='_'||c=='-'))throw new InvalidDataException("Invalid model identity.");
                foreach(char c in entry.SceneHash)if(!(c>='0'&&c<='9'||c>='a'&&c<='f'))throw new InvalidDataException("Invalid model identity hash.");
                string scene=Text(row,"scene",220),thumbnail=Text(row,"thumbnail",220);
                if(!scene.StartsWith("Models/",StringComparison.Ordinal)||!scene.EndsWith("/model.max",StringComparison.Ordinal)||thumbnail!=scene.Substring(0,scene.Length-9)+"preview.jpg")throw new InvalidDataException("Invalid model folder layout.");
                entry.Scene=ContentPath(scene);entry.Thumbnail=ContentPath(thumbnail);
                if(!paths.Add(entry.Scene)||!File.Exists(entry.Scene)||new FileInfo(entry.Scene).Length!=entry.SceneBytes)throw new IOException("Installed model bytes differ: "+entry.Name);
                var image=new FileInfo(entry.Thumbnail);
                if(!image.Exists||image.Length<33||image.Length>2*1024*1024)throw new IOException("Installed model preview is missing or too large: "+entry.Name);
                entry.ThumbnailBytes=(int)image.Length;entry.ThumbnailHash=Hash(entry.Thumbnail);
                total+=entry.SceneBytes;if(total>16L*1024*1024*1024)throw new IOException("Installed model library exceeds its declared size bound.");
                entries.Add(entry);if(!categories.Contains(entry.Category))categories.Add(entry.Category);
            }
            entries.Sort((a,b)=>StringComparer.CurrentCultureIgnoreCase.Compare(a.Name,b.Name));categories.Sort(StringComparer.CurrentCultureIgnoreCase);
        }
        bool Matches(IndividualModelEntry item,string search,string category)=>
            (category.Length==0||item.Category==category)&&(search.Length==0||(item.Name+" "+item.Category+" "+item.Id).IndexOf(search,StringComparison.CurrentCultureIgnoreCase)>=0);
        public int MatchingCount(string search,string category)
        {int count=0;foreach(var entry in entries)if(Matches(entry,search,category))count++;return count;}
        public IndividualModelEntry MatchingAt(string search,string category,int index)
        {foreach(var entry in entries)if(Matches(entry,search,category)&&index--==0)return entry;throw new ArgumentOutOfRangeException(nameof(index));}
        public void VerifyScene(IndividualModelEntry entry)
        {
            if(!entries.Contains(entry))throw new InvalidDataException("Model is outside this catalog.");
            NoLinks(entry.Scene);
            if(!File.Exists(entry.Scene)||new FileInfo(entry.Scene).Length!=entry.SceneBytes||Hash(entry.Scene)!=entry.SceneHash)throw new IOException("Installed model changed. Reinstall the matching content: "+entry.Name);
        }
    }
    // Restore the owned Max dialog itself, not its embedded WinForms panel.
    public static class LibraryWindow
    {
        [DllImport("user32.dll")] private static extern bool IsWindow(IntPtr window);
        [DllImport("user32.dll")] private static extern bool IsIconic(IntPtr window);
        [DllImport("user32.dll")] private static extern bool ShowWindow(IntPtr window,int command);
        [DllImport("user32.dll")] private static extern bool SetForegroundWindow(IntPtr window);
        [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr window,out uint process);
        [DllImport("kernel32.dll")] private static extern uint GetCurrentProcessId();

        public static bool RestoreAndActivate(long handle)
        {
            var window=new IntPtr(handle);
            uint process;
            if(!IsWindow(window)||GetWindowThreadProcessId(window,out process)==0) return false;
            if(process!=GetCurrentProcessId()) return false;
            if(IsIconic(window)) ShowWindow(window,9); // SW_RESTORE retains normal bounds.
            SetForegroundWindow(window);
            return true;
        }
    }

    internal static class GalleryLimits
    {
        internal static int Clamp(int value,int low,int high)=>Math.Max(low,Math.Min(high,value));
        internal static double Clamp(double value,double low,double high)=>Math.Max(low,Math.Min(high,value));
    }
    // Explicit item backgrounds and text avoid mixing Windows' pale hover with Max's white text.
    internal sealed class LibraryRenderer : ToolStripProfessionalRenderer
    {
        internal LibraryRenderer(){RoundedEdges=false;}
        protected override void OnRenderToolStripBackground(ToolStripRenderEventArgs e)
        {using(var brush=new SolidBrush(SystemInformation.HighContrast?SystemColors.Menu:Color.FromArgb(59,59,59)))e.Graphics.FillRectangle(brush,e.AffectedBounds);}
        private static void Item(ToolStripItemRenderEventArgs e)
        {
            Color color=SystemInformation.HighContrast?(e.Item.Selected?SystemColors.Highlight:SystemColors.Menu):
                e.Item.Pressed?Color.FromArgb(37,91,119):e.Item.Selected?Color.FromArgb(68,94,108):Color.FromArgb(59,59,59);
            using(var brush=new SolidBrush(color))e.Graphics.FillRectangle(brush,new Rectangle(Point.Empty,e.Item.Size));
        }
        protected override void OnRenderButtonBackground(ToolStripItemRenderEventArgs e)=>Item(e);
        protected override void OnRenderDropDownButtonBackground(ToolStripItemRenderEventArgs e)=>Item(e);
        protected override void OnRenderMenuItemBackground(ToolStripItemRenderEventArgs e)=>Item(e);
        protected override void OnRenderImageMargin(ToolStripRenderEventArgs e)=>OnRenderToolStripBackground(e);
        private static Color TextColor(ToolStripItem? item)=>SystemInformation.HighContrast?
            (item==null||!item.Enabled?SystemColors.GrayText:item.Selected?SystemColors.HighlightText:SystemColors.MenuText):
            item!=null&&item.Enabled?Color.White:Color.FromArgb(155,155,155);
        protected override void OnRenderItemText(ToolStripItemTextRenderEventArgs e){e.TextColor=TextColor(e.Item);base.OnRenderItemText(e);}
        protected override void OnRenderArrow(ToolStripArrowRenderEventArgs e){e.ArrowColor=TextColor(e.Item);base.OnRenderArrow(e);}
    }
    // Layout and navigation only. The host owns catalog requests and all scene actions.
    public sealed class LibraryPanel : UserControl
    {
        public LibraryGallery Gallery { get; } = new();
        private readonly TreeView tree=new(){HideSelection=false,ShowLines=false,FullRowSelect=true,BorderStyle=BorderStyle.None};
        private readonly ToolStrip toolbar=new(){GripStyle=ToolStripGripStyle.Hidden,Dock=DockStyle.None,AutoSize=false};
        private readonly ToolStrip footer=new(){GripStyle=ToolStripGripStyle.Hidden,Dock=DockStyle.None,AutoSize=false};
        private readonly ToolStripTextBox search=new(){AutoSize=false,ToolTipText="Search names, tags and descriptions"};
        private readonly ToolStripDropDownButton view=new(){AutoSize=false};
        private readonly ToolStripDropDownButton zoom=new(){AutoSize=false};
        private readonly Label location=new(){AutoEllipsis=true},status=new(){AutoEllipsis=true},detail=new(){AutoEllipsis=true};
        private readonly Label notice=new(){AutoEllipsis=true,Visible=false,Padding=new Padding(9,5,9,5)};
        private bool noticeActive;
        private readonly ToolStripButton previous=new("Previous"),next=new("Next"),load=new("Load Selected"),merge=new("Merge model"),refresh=new("Refresh"),cancel=new("Cancel scan");
        private readonly ToolStripDropDownButton actions=new("Recipe actions...");
        private readonly ToolStripMenuItem edit=new("Edit details..."),update=new("Update selected..."),style=new("Apply Style..."),export=new("Export portable package...");
        private readonly ToolStripButton save=new("Save Recipe...");
        public bool HasSetup {get;set;}
        public bool IndividualModels {get;set;}
        private readonly ToolStripLabel page=new();
        private bool binding;
        private int viewIndex,zoomIndex=1;
        private double userScale=1;
        private Font? ownedFont;
        public string RequestedAction {get;private set;}="";
        public event EventHandler? ActionRequested;
        public int LibraryIndex {get;private set;}=1;
        public string Category {get;private set;}="";
        public bool CollectionsView {get;private set;}=true;
        public string SearchText {get=>search.Text;set{search.Text=value;}}
        public string StatusText {get=>status.Text;set=>status.Text=value;}
        public string NoticeText=>notice.Text;
        public void ShowNotice(string message,bool success)
        {
            notice.Text=message;notice.BackColor=success?Color.FromArgb(38,88,61):Color.FromArgb(112,48,43);
            notice.ForeColor=Color.White;noticeActive=true;notice.Visible=true;status.Text=message;Arrange();notice.Refresh();
        }
        public void ShowProgress(string message)
        {
            notice.Text=message;notice.BackColor=Color.FromArgb(67,74,88);notice.ForeColor=Color.White;
            noticeActive=true;notice.Visible=true;Arrange();notice.Refresh();
        }
        public string DetailText {get=>detail.Text;set=>detail.Text=value;}
        public string LocationText {get=>location.Text;set=>location.Text=value;}
        public int ViewIndex {get=>viewIndex;set{viewIndex=GalleryLimits.Clamp(value,0,1);view.Text=new[]{"Thumbnails","Compact list"}[viewIndex];Gallery.ListMode=viewIndex==1;Request("view");}}
        public int ZoomIndex {get=>zoomIndex;set{zoomIndex=GalleryLimits.Clamp(value,0,2);zoom.Text=new[]{"Small tiles","Medium tiles","Large tiles"}[zoomIndex];Gallery.TileSize=new[]{128,176,224}[zoomIndex];Request("view");}}
        public double UserScale {get=>userScale;set{
            // Max's default 0 means no custom scaling (1), not half size.
            userScale=NormalizeUserScale(value);Gallery.UserScale=userScale;
            // Own a point-size font. Never dispose a Max/shared HFONT or a borrowed system font.
            var previousFont=ownedFont;ownedFont=new Font("Segoe UI",(float)(9*userScale),FontStyle.Regular,GraphicsUnit.Point);
            Font=ownedFont;previousFont?.Dispose();Arrange();
        }}
        internal static double NormalizeUserScale(double value)=>GalleryLimits.Clamp(value==0?1:value,.5,4);
        public int TreeNodeCount {get{int n=tree.Nodes.Count;foreach(TreeNode node in tree.Nodes)n+=node.Nodes.Count;return n;}}
        private void Request(string action){if(binding||IsDisposed)return;RequestedAction=action;ActionRequested?.Invoke(this,EventArgs.Empty);}
        private ToolStripButton Button(string text,string action){var b=new ToolStripButton(text);b.Click+=(_,_)=>Request(action);return b;}
        public LibraryPanel()
        {
            AutoScaleMode=AutoScaleMode.None;BackColor=Color.FromArgb(48,48,48);ForeColor=Color.Gainsboro;
            tree.BackColor=Color.FromArgb(42,42,42);tree.ForeColor=ForeColor;
            var renderer=new LibraryRenderer();
            foreach(var bar in new[]{toolbar,footer}){bar.BackColor=Color.FromArgb(59,59,59);bar.ForeColor=ForeColor;bar.Renderer=renderer;}
            foreach(var menu in new[]{view,zoom,actions}){menu.DropDown.Renderer=renderer;menu.DropDown.BackColor=Color.FromArgb(59,59,59);}
            toolbar.Items.Add(Button("Collections","home"));toolbar.Items.Add(refresh);toolbar.Items.Add(cancel);toolbar.Items.Add(Button("Choose folder...","folder"));toolbar.Items.Add(new ToolStripSeparator());
            toolbar.Items.Add(new ToolStripLabel("Search"));toolbar.Items.Add(search);toolbar.Items.Add(view);toolbar.Items.Add(zoom);
            for(int i=0;i<2;i++){int index=i;var item=new ToolStripMenuItem(new[]{"Thumbnails","Compact list"}[i]);item.Click+=(_,_)=>ViewIndex=index;view.DropDownItems.Add(item);}
            for(int i=0;i<3;i++){int index=i;var item=new ToolStripMenuItem(new[]{"Small tiles","Medium tiles","Large tiles"}[i]);item.Click+=(_,_)=>ZoomIndex=index;zoom.DropDownItems.Add(item);}
            ViewIndex=0;ZoomIndex=1;
            search.TextChanged+=(_,_)=>Request("search");
            refresh.Click+=(_,_)=>Request("refresh");cancel.Click+=(_,_)=>Request("cancel");
            actions.DropDownItems.AddRange(new ToolStripItem[]{edit,update,style,export});
            save.Click+=(_,_)=>Request("save");footer.Items.Add(save);footer.Items.Add(actions);footer.Items.Add(new ToolStripSeparator());footer.Items.Add(previous);footer.Items.Add(next);footer.Items.Add(page);
            load.Alignment=ToolStripItemAlignment.Right;merge.Alignment=ToolStripItemAlignment.Right;merge.Visible=false;footer.Items.Add(load);footer.Items.Add(merge);
            merge.Click+=(_,_)=>Request("merge");
            previous.Click+=(_,_)=>Request("previous");next.Click+=(_,_)=>Request("next");load.Click+=(_,_)=>Request("load");edit.Click+=(_,_)=>Request("edit");update.Click+=(_,_)=>Request("update");style.Click+=(_,_)=>Request("style");export.Click+=(_,_)=>Request("export");
            for(int i=1;i<=3;i++){var node=new TreeNode(new[]{"My recipes","Plant models","Custom library"}[i-1]){Tag=i};node.Nodes.Add(new TreeNode(i==2?"All models":"All recipes"){Tag=""});tree.Nodes.Add(node);}
            tree.AfterSelect+=(_,e)=>{
                if(binding||e.Node==null)return;
                var owner=e.Node.Parent??e.Node;int index=(int)owner.Tag!;bool changed=index!=LibraryIndex;
                LibraryIndex=index;CollectionsView=index!=2&&e.Node.Parent==null;Category=e.Node.Parent==null?"":(string)e.Node.Tag!;
                Request(changed?"library":"collection");
            };
            Gallery.SelectionChanged+=(_,_)=>Request("selection");Gallery.ItemActivated+=(_,_)=>Request("load");
            Controls.AddRange(new Control[]{toolbar,tree,Gallery,location,notice,detail,footer,status});
            SetNavigation(1,"",true);Arrange();
        }
        public void SetNavigation(int index,string category,bool overview)
        {
            binding=true;LibraryIndex=GalleryLimits.Clamp(index,1,3);Category=category;CollectionsView=overview&&LibraryIndex!=2;
            var owner=tree.Nodes[LibraryIndex-1];TreeNode choice=owner;
            if(!CollectionsView){choice=owner.Nodes[0];foreach(TreeNode n in owner.Nodes)if((string)n.Tag! == category){choice=n;break;}}
            tree.SelectedNode=choice;owner.Expand();binding=false;
        }
        public void BeginCollections(){binding=true;var nodes=tree.Nodes[LibraryIndex-1].Nodes;while(nodes.Count>1)nodes.RemoveAt(nodes.Count-1);}
        public void AddCollection(string name){var nodes=tree.Nodes[LibraryIndex-1].Nodes;if(nodes.Count<129)nodes.Add(new TreeNode(name){Tag=name});}
        public void EndCollections(){binding=false;SetNavigation(LibraryIndex,Category,CollectionsView);}
        public void SetPage(int number,int pages,int matches,bool scanning)
        {
            previous.Enabled=number>1;next.Enabled=number<pages;page.Text=$"{number} / {pages}   ({matches})";
            refresh.Enabled=!scanning;cancel.Enabled=scanning;tree.Enabled=!scanning;
        }
        public void SetSelectionActions(bool selected,bool writable,bool scanning)
        {
            merge.Visible=IndividualModels;merge.Enabled=IndividualModels&&selected&&!scanning;
            load.Enabled=selected&&!scanning&&(!IndividualModels||HasSetup);load.Text=IndividualModels?"Add to selected layer":CollectionsView?"Open Collection":"Load onto surface";
            actions.Enabled=edit.Enabled=!IndividualModels&&selected&&!CollectionsView&&!scanning;
            update.Enabled=edit.Enabled&&writable&&HasSetup;style.Enabled=export.Enabled=edit.Enabled&&HasSetup;save.Enabled=HasSetup&&!scanning;
        }
        private int S(int n)=>Math.Max(1,(int)Math.Round(n*DeviceDpi/96.0*userScale));
        private void Arrange()
        {
            if(toolbar==null)return;
            int gap=S(7),top=S(34),bottom=S(36),foot=S(27),details=S(36),caption=S(26),left=S(206);
            search.Width=S(154);view.Width=S(112);zoom.Width=S(112);
            toolbar.SetBounds(0,0,Width,top);footer.SetBounds(0,Math.Max(top,Height-foot-bottom),Width,bottom);
            status.SetBounds(gap,Math.Max(top,Height-foot),Math.Max(1,Width-2*gap),foot);
            tree.SetBounds(gap,top+gap,left,Math.Max(1,footer.Top-top-2*gap));
            int x=left+2*gap,w=Math.Max(1,Width-x-gap);
            location.SetBounds(x,top+gap,w,caption);
            detail.SetBounds(x,Math.Max(top+caption,footer.Top-details-gap),w,details);
            int noticeHeight=noticeActive?S(52):0;
            notice.SetBounds(x,top+gap+caption,w,Math.Max(1,noticeHeight-gap));
            Gallery.SetBounds(x,top+gap+caption+noticeHeight,w,Math.Max(1,detail.Top-top-caption-2*gap-noticeHeight));
        }
        protected override void OnResize(EventArgs e){base.OnResize(e);Arrange();}
        protected override void OnDpiChangedAfterParent(EventArgs e){base.OnDpiChangedAfterParent(e);Arrange();}
        protected override void OnFontChanged(EventArgs e)
        {
            base.OnFontChanged(e);
            if(toolbar==null)return;
            foreach(Control c in Controls)c.Font=Font;
            toolbar.Font=Font;footer.Font=Font;Arrange();
        }
        protected override void Dispose(bool disposing){if(disposing)ActionRequested=null;base.Dispose(disposing);if(disposing){ownedFont?.Dispose();ownedFont=null;}}
    }
    public sealed class DensityPatternPanel : UserControl
    {
        public readonly LibraryGallery Gallery=new() {Dock=DockStyle.Fill,TileSize=112};
        private readonly List<string[]> records=new();
        public string SelectedPath => Gallery.SelectedIndex>=0 ? records[Gallery.SelectedIndex][3] : "";
        public string SelectedPattern => Gallery.SelectedIndex>=0 ? records[Gallery.SelectedIndex][0] : "";
        public string SelectedHash => Gallery.SelectedIndex>=0 ? records[Gallery.SelectedIndex][4] : "";
        public event EventHandler? ItemActivated;
        public DensityPatternPanel(){Controls.Add(Gallery);Gallery.ItemActivated+=(_,_)=>ItemActivated?.Invoke(this,EventArgs.Empty);}
        public void LoadPatterns(string directory)
        {
            var lines=File.ReadAllLines(Path.Combine(directory,"catalog.tsv"));
            if(lines.Length>128)throw new InvalidDataException("Pattern catalog exceeds its page bound.");
            records.Clear();Gallery.BeginPage();
            foreach(string line in lines){
                var item=line.Split('\t');
                if(item.Length!=5||Path.GetFileName(item[3])!=item[3]||Path.GetExtension(item[3])!=".png")throw new InvalidDataException("Invalid pattern record.");
                item[3]=Path.Combine(directory,item[3]);var info=new FileInfo(item[3]);
                if(info.Length<1||info.Length>2*1024*1024)throw new InvalidDataException("Pattern image exceeds bounds.");
                records.Add(item);Gallery.AddItem(item[0],item[1],item[2],item[3],item[4],(int)info.Length);
            }
            Gallery.EndPage(-1);
        }
        public void InspectSelected()
        {
            using Bitmap? image=Gallery.CopySelectedPreview();if(image==null)return;
            using var view=new Form {Text="Density mask",ClientSize=new Size(512,512),StartPosition=FormStartPosition.CenterParent,MinimizeBox=false};
            using var picture=new PictureBox {Dock=DockStyle.Fill,Image=image,SizeMode=PictureBoxSizeMode.Zoom,BackColor=Color.FromArgb(48,48,48)};
            view.Controls.Add(picture);view.ShowDialog(FindForm());
        }
        protected override void Dispose(bool disposing){if(disposing)ItemActivated=null;base.Dispose(disposing);}
    }

    public sealed class LibraryGallery : ScrollableControl
    {
        public const long CacheLimit = 64L * 1024 * 1024;
        private const int MaximumPage = 128, MaximumImageBytes = 2 * 1024 * 1024;
        private sealed class Entry
        {
            internal readonly string Id,Title,Detail,Path,Hash; internal readonly int Bytes;
            internal Entry(string id,string title,string detail,string path,string hash,int bytes){Id=id;Title=title;Detail=detail;Path=path;Hash=hash;Bytes=bytes;}
        }
        private sealed class Result
        {
            internal readonly int Generation; internal readonly string Key; internal readonly Bitmap? Image;
            internal Result(int generation,string key,Bitmap? image){Generation=generation;Key=key;Image=image;}
        }
        private sealed class Cached
        {
            public Bitmap Image;
            public long Used;
            internal Cached(Bitmap image,long used){Image=image;Used=used;}
            public long Bytes => (long)Image.Width * Image.Height * 4;
        }
        private readonly List<Entry> entries = new();
        private readonly Dictionary<string, Cached> cache = new(StringComparer.Ordinal);
        private readonly HashSet<string> pending = new(StringComparer.Ordinal), failed = new(StringComparer.Ordinal);
        private readonly Queue<Result> completed = new();
        private readonly object gate = new();
        private readonly System.Windows.Forms.Timer pump = new() { Interval = 40 };
        private volatile bool closed;
        private bool editing, listMode;
        private volatile int generation;
        private int jobs, selected = -1, tileSize = 112;
        private double userScale = 1;
        private long bytes, clock, started, decoded;
        public event EventHandler? SelectionChanged;
        public event EventHandler? PreviewChanged;
        public event EventHandler? ItemActivated;
        public long DecodedBytes => bytes;
        public long JobsStarted => started;
        public long ImagesDecoded => decoded;
        public int PendingJobs => jobs;
        public int ItemCount => entries.Count;
        public bool IsLoading => pump.Enabled;
        public string SelectedId => selected >= 0 && selected < entries.Count ? entries[selected].Id : "";
        public int SelectedIndex
        {
            get => selected;
            set
            {
                int next = value >= 0 && value < entries.Count ? value : -1;
                if (selected == next) return;
                selected = next; Invalidate(); Schedule();
                if (!editing) SelectionChanged?.Invoke(this, EventArgs.Empty);
            }
        }
        public bool ListMode { get => listMode; set { listMode = value; LayoutItems(); } }
        public int TileSize { get => tileSize; set { tileSize = GalleryLimits.Clamp(value, 96, 256); LayoutItems(); } }
        public double UserScale { get => userScale; set { userScale = LibraryPanel.NormalizeUserScale(value); LayoutItems(); } }
        public LibraryGallery()
        {
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer |
                ControlStyles.UserPaint | ControlStyles.ResizeRedraw | ControlStyles.Selectable, true);
            AutoScroll = true; TabStop = true;
            BackColor = Color.FromArgb(48, 48, 48); ForeColor = Color.Gainsboro;
            pump.Tick += (_, _) => Drain();
        }
        public void BeginPage()
        {
            editing = true; generation++; entries.Clear(); failed.Clear(); selected = -1;
            // Pending jobs keep their slots until drained; old generations can never update this page.
        }
        public void AddItem(string id, string title, string detail, string path, string hash, int length)
        {
            if (!editing || entries.Count >= MaximumPage) throw new InvalidOperationException("Gallery page limit exceeded.");
            if (id.Length > 32768 || title.Length > 1024 || detail.Length > 2048 || path.Length > 32768)
                throw new ArgumentException("Gallery text exceeds bounds.");
            if (path.Length != 0 && (!(Path.IsPathRooted(path)&&Path.GetFullPath(path)==path) || hash.Length != 64 || length < 33 || length > MaximumImageBytes))
                throw new ArgumentException("Invalid thumbnail descriptor.");
            entries.Add(new(id, title, detail, path, hash, length));
        }
        public void EndPage(int selection)
        {
            if (!editing) throw new InvalidOperationException("No gallery page is being built.");
            editing = false; SelectedIndex = selection; LayoutItems();
        }
        private static string Key(Entry e) => e.Hash + ":" + e.Bytes;
        private int Scale(int n) => Math.Max(1, (int)Math.Round(n * DeviceDpi / 96.0 * userScale));
        private int Columns => listMode ? 1 : Math.Max(1, ClientSize.Width / Scale(tileSize));
        private int RowHeight => Scale(listMode ? 42 : tileSize + 30);
        private Rectangle BoundsFor(int i)
        {
            int columns = Columns, width = Math.Max(1, ClientSize.Width / columns);
            return new Rectangle((i % columns) * width, (i / columns) * RowHeight + AutoScrollPosition.Y, width, RowHeight);
        }
        private bool VisibleItem(int i) => BoundsFor(i).IntersectsWith(ClientRectangle);
        private void LayoutItems()
        {
            AutoScrollMinSize = new Size(0, ((entries.Count + Columns - 1) / Columns) * RowHeight);
            Invalidate(); Schedule();
        }
        protected override void OnResize(EventArgs e) { base.OnResize(e); LayoutItems(); }
        protected override void OnDpiChangedAfterParent(EventArgs e) { base.OnDpiChangedAfterParent(e); LayoutItems(); }
        protected override void OnScroll(ScrollEventArgs e) { base.OnScroll(e); Invalidate(); Schedule(); }
        protected override void OnMouseWheel(MouseEventArgs e)
        {
            // ScrollableControl moves its display rectangle directly for wheel input;
            // it does not raise OnScroll. Restart the queue after the offset changes,
            // including when the previous visible set finished and stopped the pump.
            base.OnMouseWheel(e);
            Invalidate();
            Schedule();
        }
        protected override void OnMouseDown(MouseEventArgs e)
        {
            base.OnMouseDown(e); Focus();
            for (int i = 0; i < entries.Count; i++) if (BoundsFor(i).Contains(e.Location)) { SelectedIndex = i; break; }
        }
        protected override bool IsInputKey(Keys keyData) => (keyData & Keys.KeyCode) is Keys.Left or Keys.Right or Keys.Up or Keys.Down or Keys.Home or Keys.End || base.IsInputKey(keyData);
        protected override void OnMouseDoubleClick(MouseEventArgs e)
        {
            base.OnMouseDoubleClick(e);
            if(e.Button==MouseButtons.Left && selected>=0 && BoundsFor(selected).Contains(e.Location))ItemActivated?.Invoke(this,EventArgs.Empty);
        }
        protected override void OnKeyDown(KeyEventArgs e)
        {
            base.OnKeyDown(e);
            if(e.KeyCode==Keys.Enter && selected>=0){e.Handled=true;e.SuppressKeyPress=true;ItemActivated?.Invoke(this,EventArgs.Empty);return;}
            int next = e.KeyCode switch { Keys.Left => selected - 1, Keys.Right => selected + 1,
                Keys.Up => selected - Columns, Keys.Down => selected + Columns, Keys.Home => 0,
                Keys.End => entries.Count - 1, _ => selected };
            if (entries.Count == 0 || next == selected) return;
            SelectedIndex = GalleryLimits.Clamp(next, 0, entries.Count - 1);
            Rectangle r = BoundsFor(selected);
            if (r.Top < 0) AutoScrollPosition = new Point(0, -AutoScrollPosition.Y + r.Top);
            else if (r.Bottom > ClientSize.Height) AutoScrollPosition = new Point(0, -AutoScrollPosition.Y + r.Bottom - ClientSize.Height);
            e.Handled = true; Schedule();
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            for (int i = 0; i < entries.Count; i++)
            {
                Rectangle outer = BoundsFor(i); if (!outer.IntersectsWith(e.ClipRectangle)) continue;
                Rectangle r = Rectangle.Inflate(outer, -Scale(3), -Scale(3));
                using (var brush = new SolidBrush(i == selected ? Color.FromArgb(50, 100, 125) : Color.FromArgb(63, 63, 63))) e.Graphics.FillRectangle(brush, r);
                Rectangle preview = listMode ? new(r.X + Scale(4), r.Y + Scale(3), Scale(30), Scale(30))
                    : new(r.X + Scale(5), r.Y + Scale(5), r.Width - Scale(10), r.Height - Scale(44));
                Entry item = entries[i]; string key = Key(item);
                if (cache.TryGetValue(key, out Cached? value))
                {
                    value.Used = ++clock;
                    double ratio = Math.Min((double)preview.Width / value.Image.Width, (double)preview.Height / value.Image.Height);
                    int width = Math.Max(1, (int)(value.Image.Width * ratio)), height = Math.Max(1, (int)(value.Image.Height * ratio));
                    e.Graphics.DrawImage(value.Image, new Rectangle(preview.X + (preview.Width - width) / 2, preview.Y + (preview.Height - height) / 2, width, height));
                }
                else TextRenderer.DrawText(e.Graphics, item.Path.Length == 0 ? "No preview" : failed.Contains(key) ? "Unavailable" : "Loading", Font, preview, ForeColor, TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis);
                Rectangle label = listMode ? new(preview.Right + Scale(7), r.Y + Scale(2), r.Right - preview.Right - Scale(10), Scale(18))
                    : new(r.X + Scale(5), preview.Bottom + Scale(2), r.Width - Scale(10), Scale(18));
                TextRenderer.DrawText(e.Graphics, item.Title, Font, label, ForeColor, TextFormatFlags.EndEllipsis | TextFormatFlags.NoPrefix);
                label.Y += Scale(17);
                TextRenderer.DrawText(e.Graphics, item.Detail, Font, label, Color.Silver, TextFormatFlags.EndEllipsis | TextFormatFlags.NoPrefix);
            }
        }
        private void Schedule()
        {
            if (closed || editing || !IsHandleCreated) return;
            if (selected >= 0) Request(entries[selected]);
            for (int i = 0; i < entries.Count && jobs < 2; i++) if (VisibleItem(i)) Request(entries[i]);
            pump.Enabled = jobs > 0;
        }
        protected override void OnHandleCreated(EventArgs e) { base.OnHandleCreated(e); Schedule(); }
        private void Request(Entry entry)
        {
            string key = Key(entry);
            if (jobs >= 2 || entry.Path.Length == 0 || cache.ContainsKey(key) || failed.Contains(key) || pending.Contains(key)) return;
            int expected = generation; pending.Add(key); jobs++; started++;
            _ = Task.Run(() =>
            {
                Bitmap? image = null;
                try { if (!closed && expected == generation) image = Decode(entry, () => closed || expected != generation); }
                catch (Exception) { /* Invalid or unavailable file: bounded placeholder; always release the job slot. */ }
                lock (gate)
                {
                    if (closed) image?.Dispose();
                    else completed.Enqueue(new(expected, key, image));
                }
            });
        }
        private static Bitmap? Decode(Entry entry, Func<bool> cancelled)
        {
            // Disallow image symlinks/junctions after cataloging as well as in the native descriptor.
            FileInfo info = new(entry.Path);
            if ((info.Attributes&FileAttributes.ReparsePoint)!=0 || info.Length != entry.Bytes) throw new IOException("Thumbnail changed.");
            byte[] data = new byte[entry.Bytes];
            using (var input = new FileStream(entry.Path, FileMode.Open, FileAccess.Read, FileShare.Read, 8192, FileOptions.SequentialScan))
            { int offset=0,count;while(offset<data.Length&&(count=input.Read(data,offset,data.Length-offset))>0)offset+=count;
              if(offset!=data.Length||input.ReadByte()!=-1)throw new IOException("Thumbnail changed."); }
            if (cancelled()) return null;
            using(var sha=SHA256.Create())if(!BitConverter.ToString(sha.ComputeHash(data)).Replace("-","").Equals(entry.Hash,StringComparison.OrdinalIgnoreCase))throw new IOException("Thumbnail hash changed.");
            var dimensions=ImageDimensions(data);int width=dimensions.Width,height=dimensions.Height;
            if (width < 1 || height < 1 || width > 1024 || height > 1024) throw new IOException("Thumbnail dimensions exceed bounds.");
            using var stream = new MemoryStream(data, false);
            using var source = Image.FromStream(stream, false, true);
            double ratio = Math.Min(1, 256.0 / Math.Max(width, height));
            Bitmap output = new(Math.Max(1, (int)(width * ratio)), Math.Max(1, (int)(height * ratio)), PixelFormat.Format32bppPArgb);
            try { using var g = Graphics.FromImage(output); g.InterpolationMode = InterpolationMode.HighQualityBicubic; g.DrawImage(source, new Rectangle(0, 0, output.Width, output.Height)); return output; }
            catch { output.Dispose(); throw; }
        }
        // Read dimensions before asking the decoder to allocate pixels. The original
        // Corona catalog uses JPEG; personal recipe captures continue to use PNG.
        private static Size ImageDimensions(byte[] data)
        {
            if(data.Length<33)throw new IOException("Invalid thumbnail.");
            byte[] signature={137,80,78,71,13,10,26,10};bool png=true;
            for(int i=0;i<signature.Length;i++)if(data[i]!=signature[i])png=false;
            if(png)
            {
                if(data[12]!=73||data[13]!=72||data[14]!=68||data[15]!=82)throw new IOException("Invalid PNG header.");
                return new Size(ReadBigEndian(data,16),ReadBigEndian(data,20));
            }
            if(data[0]!=255||data[1]!=216)throw new IOException("Unsupported thumbnail image.");
            int at=2,segments=0;
            while(at<data.Length&&segments++<1024)
            {
                if(data[at++]!=255)throw new IOException("Invalid JPEG marker.");
                while(at<data.Length&&data[at]==255)at++;
                if(at>=data.Length)break;int marker=data[at++];
                if(marker==217||marker==218)break;
                if(marker==216||marker==1||marker>=208&&marker<=215)continue;
                if(at+2>data.Length)break;int length=(data[at]<<8)|data[at+1];
                if(length<2||at+length>data.Length)break;
                if(marker==192||marker==193||marker==194)
                {
                    if(length<8)break;
                    return new Size((data[at+5]<<8)|data[at+6],(data[at+3]<<8)|data[at+4]);
                }
                at+=length;
            }
            throw new IOException("Invalid JPEG dimensions.");
        }
        private static int ReadBigEndian(byte[] data,int at)=>(data[at]<<24)|(data[at+1]<<16)|(data[at+2]<<8)|data[at+3];
        private void Drain()
        {
            bool changed = false;
            lock (gate)
            {
                while (completed.Count>0)
                {
                    Result result=completed.Dequeue();
                    jobs--; pending.Remove(result.Key);
                    if (result.Generation != generation) { result.Image?.Dispose(); continue; }
                    if (result.Image == null) { failed.Add(result.Key); continue; }
                    Cached value = new(result.Image, ++clock);
                    while (bytes + value.Bytes > CacheLimit && cache.Count > 0)
                    {
                        string? oldest = null; long age = long.MaxValue;
                        foreach (var pair in cache) if (pair.Value.Used < age) { oldest = pair.Key; age = pair.Value.Used; }
                        Cached victim = cache[oldest!]; bytes -= victim.Bytes; victim.Image.Dispose(); cache.Remove(oldest!);
                    }
                    cache.Add(result.Key, value); bytes += value.Bytes; decoded++; changed = true;
                }
            }
            Invalidate(); Schedule(); if (changed) PreviewChanged?.Invoke(this, EventArgs.Empty);
        }
        // The caller owns this small clone. Never expose a cache-owned Bitmap to MAXScript.
        public Bitmap? CopySelectedPreview() => selected >= 0 && cache.TryGetValue(Key(entries[selected]), out Cached? value) ? new Bitmap(value.Image) : null;
        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                pump.Stop(); pump.Dispose();
                lock (gate) { closed = true; while(completed.Count>0)completed.Dequeue().Image?.Dispose(); }
                foreach (Cached item in cache.Values) item.Image.Dispose(); cache.Clear(); bytes = 0;
                SelectionChanged = null; PreviewChanged = null; ItemActivated = null;
            }
            base.Dispose(disposing);
        }
    }
}
