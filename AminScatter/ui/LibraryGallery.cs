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

[assembly: AssemblyVersion("0.85.2.0")]
[assembly: AssemblyFileVersion("0.85.2.0")]
namespace CyrusScatter.UI
{
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
        private readonly ToolStripButton previous=new("Previous"),next=new("Next"),load=new("Load Selected"),refresh=new("Refresh"),cancel=new("Cancel scan");
        private readonly ToolStripDropDownButton actions=new("Recipe actions...");
        private readonly ToolStripMenuItem edit=new("Edit details..."),update=new("Update selected..."),style=new("Apply Style..."),export=new("Export portable package...");
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
        public string DetailText {get=>detail.Text;set=>detail.Text=value;}
        public string LocationText {get=>location.Text;set=>location.Text=value;}
        public int ViewIndex {get=>viewIndex;set{viewIndex=Math.Clamp(value,0,1);view.Text=new[]{"Thumbnails","Compact list"}[viewIndex];Gallery.ListMode=viewIndex==1;Request("view");}}
        public int ZoomIndex {get=>zoomIndex;set{zoomIndex=Math.Clamp(value,0,2);zoom.Text=new[]{"Small tiles","Medium tiles","Large tiles"}[zoomIndex];Gallery.TileSize=new[]{128,176,224}[zoomIndex];Request("view");}}
        public double UserScale {get=>userScale;set{
            // Max's default 0 means no custom scaling (1), not half size.
            userScale=NormalizeUserScale(value);Gallery.UserScale=userScale;
            // Own a point-size font. Never dispose a Max/shared HFONT or a borrowed system font.
            var previousFont=ownedFont;ownedFont=new Font("Segoe UI",(float)(9*userScale),FontStyle.Regular,GraphicsUnit.Point);
            Font=ownedFont;previousFont?.Dispose();Arrange();
        }}
        internal static double NormalizeUserScale(double value)=>Math.Clamp(value==0?1:value,.5,4);
        public int TreeNodeCount {get{int n=tree.Nodes.Count;foreach(TreeNode node in tree.Nodes)n+=node.Nodes.Count;return n;}}
        private void Request(string action){if(binding||IsDisposed)return;RequestedAction=action;ActionRequested?.Invoke(this,EventArgs.Empty);}
        private ToolStripButton Button(string text,string action){var b=new ToolStripButton(text);b.Click+=(_,_)=>Request(action);return b;}
        public LibraryPanel()
        {
            AutoScaleMode=AutoScaleMode.None;BackColor=Color.FromArgb(48,48,48);ForeColor=Color.Gainsboro;
            tree.BackColor=Color.FromArgb(42,42,42);tree.ForeColor=ForeColor;
            foreach(var bar in new[]{toolbar,footer}){bar.BackColor=Color.FromArgb(59,59,59);bar.ForeColor=ForeColor;bar.RenderMode=ToolStripRenderMode.System;}
            toolbar.Items.Add(Button("Collections","home"));toolbar.Items.Add(refresh);toolbar.Items.Add(cancel);toolbar.Items.Add(Button("Choose folder...","folder"));toolbar.Items.Add(new ToolStripSeparator());
            toolbar.Items.Add(new ToolStripLabel("Search"));toolbar.Items.Add(search);toolbar.Items.Add(view);toolbar.Items.Add(zoom);
            for(int i=0;i<2;i++){int index=i;var item=new ToolStripMenuItem(new[]{"Thumbnails","Compact list"}[i]);item.Click+=(_,_)=>ViewIndex=index;view.DropDownItems.Add(item);}
            for(int i=0;i<3;i++){int index=i;var item=new ToolStripMenuItem(new[]{"Small tiles","Medium tiles","Large tiles"}[i]);item.Click+=(_,_)=>ZoomIndex=index;zoom.DropDownItems.Add(item);}
            ViewIndex=0;ZoomIndex=1;
            search.TextChanged+=(_,_)=>Request("search");
            refresh.Click+=(_,_)=>Request("refresh");cancel.Click+=(_,_)=>Request("cancel");
            actions.DropDownItems.AddRange(new ToolStripItem[]{edit,update,style,export});
            footer.Items.Add(Button("Save Recipe...","save"));footer.Items.Add(actions);footer.Items.Add(new ToolStripSeparator());footer.Items.Add(previous);footer.Items.Add(next);footer.Items.Add(page);
            load.Alignment=ToolStripItemAlignment.Right;footer.Items.Add(load);
            previous.Click+=(_,_)=>Request("previous");next.Click+=(_,_)=>Request("next");load.Click+=(_,_)=>Request("load");edit.Click+=(_,_)=>Request("edit");update.Click+=(_,_)=>Request("update");style.Click+=(_,_)=>Request("style");export.Click+=(_,_)=>Request("export");
            for(int i=1;i<=3;i++){var node=new TreeNode(new[]{"My recipes","Bundled examples","Custom library"}[i-1]){Tag=i};node.Nodes.Add(new TreeNode("All recipes"){Tag=""});tree.Nodes.Add(node);}
            tree.AfterSelect+=(_,e)=>{
                if(binding||e.Node==null)return;
                var owner=e.Node.Parent??e.Node;int index=(int)owner.Tag!;bool changed=index!=LibraryIndex;
                LibraryIndex=index;CollectionsView=e.Node.Parent==null;Category=CollectionsView?"":(string)e.Node.Tag!;
                Request(changed?"library":"collection");
            };
            Gallery.SelectionChanged+=(_,_)=>Request("selection");Gallery.ItemActivated+=(_,_)=>Request("load");
            Controls.AddRange(new Control[]{toolbar,tree,Gallery,location,detail,footer,status});
            SetNavigation(1,"",true);Arrange();
        }
        public void SetNavigation(int index,string category,bool overview)
        {
            binding=true;LibraryIndex=Math.Clamp(index,1,3);Category=category;CollectionsView=overview;
            var owner=tree.Nodes[LibraryIndex-1];TreeNode choice=owner;
            if(!overview){choice=owner.Nodes[0];foreach(TreeNode n in owner.Nodes)if((string)n.Tag! == category){choice=n;break;}}
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
        {load.Enabled=selected&&!scanning;load.Text=CollectionsView?"Open Collection":"Load Selected";actions.Enabled=edit.Enabled=selected&&!CollectionsView&&!scanning;update.Enabled=edit.Enabled&&writable;style.Enabled=export.Enabled=edit.Enabled;}
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
            Gallery.SetBounds(x,top+gap+caption,w,Math.Max(1,detail.Top-top-caption-2*gap));
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
    public sealed class LibraryGallery : ScrollableControl
    {
        public const long CacheLimit = 64L * 1024 * 1024;
        private const int MaximumPage = 128, MaximumImageBytes = 2 * 1024 * 1024;
        private sealed record Entry(string Id, string Title, string Detail, string Path, string Hash, int Bytes);
        private sealed record Result(int Generation, string Key, Bitmap? Image);
        private sealed class Cached(Bitmap image, long used)
        {
            public Bitmap Image = image;
            public long Used = used;
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
        public int TileSize { get => tileSize; set { tileSize = Math.Clamp(value, 96, 256); LayoutItems(); } }
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
            if (path.Length != 0 && (!Path.IsPathFullyQualified(path) || hash.Length != 64 || length < 33 || length > MaximumImageBytes))
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
            SelectedIndex = Math.Clamp(next, 0, entries.Count - 1);
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
            if (info.LinkTarget != null || info.Length != entry.Bytes) throw new IOException("Thumbnail changed.");
            byte[] data = new byte[entry.Bytes];
            using (var input = new FileStream(entry.Path, FileMode.Open, FileAccess.Read, FileShare.Read, 8192, FileOptions.SequentialScan))
            { input.ReadExactly(data); if (input.ReadByte() != -1) throw new IOException("Thumbnail changed."); }
            if (cancelled()) return null;
            if (!Convert.ToHexString(SHA256.HashData(data)).Equals(entry.Hash, StringComparison.OrdinalIgnoreCase)) throw new IOException("Thumbnail hash changed.");
            ReadOnlySpan<byte> signature = [137, 80, 78, 71, 13, 10, 26, 10];
            if (!data.AsSpan(0, 8).SequenceEqual(signature) || data[12] != 73 || data[13] != 72 || data[14] != 68 || data[15] != 82) throw new IOException("Invalid PNG.");
            int width = System.Buffers.Binary.BinaryPrimitives.ReadInt32BigEndian(data.AsSpan(16, 4));
            int height = System.Buffers.Binary.BinaryPrimitives.ReadInt32BigEndian(data.AsSpan(20, 4));
            if (width < 1 || height < 1 || width > 1024 || height > 1024) throw new IOException("Thumbnail dimensions exceed bounds.");
            using var stream = new MemoryStream(data, false);
            using var source = Image.FromStream(stream, false, true);
            double ratio = Math.Min(1, 256.0 / Math.Max(width, height));
            Bitmap output = new(Math.Max(1, (int)(width * ratio)), Math.Max(1, (int)(height * ratio)), PixelFormat.Format32bppPArgb);
            try { using var g = Graphics.FromImage(output); g.InterpolationMode = InterpolationMode.HighQualityBicubic; g.DrawImage(source, new Rectangle(0, 0, output.Width, output.Height)); return output; }
            catch { output.Dispose(); throw; }
        }
        private void Drain()
        {
            bool changed = false;
            lock (gate)
            {
                while (completed.TryDequeue(out Result? result))
                {
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
                lock (gate) { closed = true; while (completed.TryDequeue(out Result? result)) result.Image?.Dispose(); }
                foreach (Cached item in cache.Values) item.Image.Dispose(); cache.Clear(); bytes = 0;
                SelectionChanged = null; PreviewChanged = null; ItemActivated = null;
            }
            base.Dispose(disposing);
        }
    }
}
