using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;
public sealed class DropFocusProbe2 : NativeWindow {
    [DllImport("user32.dll")] static extern IntPtr SetFocus(IntPtr h);
    [DllImport("user32.dll")] static extern IntPtr GetParent(IntPtr h);
    [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern int GetClassName(IntPtr h,StringBuilder text,int size);
    public bool Enabled {get;set;}
    public static void Reset(long h) {SetFocus(new IntPtr(h));}
    public DropFocusProbe2(long h) {AssignHandle(new IntPtr(h));}
    protected override void WndProc(ref Message m) {
        if(Enabled && m.Msg==0x201) {
            SetFocus(new IntPtr(14885604));
        }
        base.WndProc(ref m);
    }
}
