// Disposable host diagnostic only. Observe messages; never change them.
using System;
using System.IO;
using System.Windows.Forms;
public sealed class DropTrace : NativeWindow {
    readonly string path;
    public DropTrace(long handle, string file) { path=file; AssignHandle(new IntPtr(handle)); }
    protected override void WndProc(ref Message m) {
        int n=m.Msg;
        if(n==0x7||n==0x8||n==0x14F||n==0x201||n==0x202||n==0x215||n==0x1F||n==0x18||n==0x47||n==0x111)
            File.AppendAllText(path,Environment.TickCount+" hwnd="+Handle+" msg="+n.ToString("X")+" w="+m.WParam+" l="+m.LParam+"\n");
        base.WndProc(ref m);
    }
}
