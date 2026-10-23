// Private Max 2027 fixture. Never shipped; rejects artist-profile processes.
using System;
using System.IO;
using System.Runtime.InteropServices;
public static class OwnedRolloutLayout {
    [DllImport("OwnedRolloutSdk.dll",CallingConvention=CallingConvention.Cdecl)] static extern int qRolloutCategory(IntPtr page);
    [DllImport("OwnedRolloutSdk.dll",CallingConvention=CallingConvention.Cdecl)] static extern int qArrangeContainer(IntPtr page,int category);
    static void Owned() {
        string data=Environment.GetEnvironmentVariable("ADSK_3DSMAX_APPDATA_DIR");
        if(String.IsNullOrEmpty(data)||!Path.GetFullPath(data).Contains("\\build\\installer-panels-08684-20261022\\"))throw new InvalidOperationException("Owned host required");
    }
    public static int Category(long handle){Owned();return qRolloutCategory(new IntPtr(handle));}
    public static void ArrangeContainer(long handle,int category){Owned();if(qArrangeContainer(new IntPtr(handle),category)!=1)throw new InvalidOperationException("Native fixture could not arrange rollout");}
}
