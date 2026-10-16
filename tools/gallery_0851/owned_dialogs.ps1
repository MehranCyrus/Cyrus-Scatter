param([int]$HostProcessId,[string]$ProfileName,[switch]$AcceptInstaller)
$ErrorActionPreference='Stop'
$taskProcess=Get-CimInstance Win32_Process -Filter "ProcessId=$HostProcessId"
if($taskProcess.Name -ne '3dsmax.exe' -or !$ProfileName.StartsWith('foundation-roadmap-gallery0851-') -or $taskProcess.CommandLine -notlike ('*'+$ProfileName+'*')){throw 'Owned Max host required'}
Add-Type @'
using System;using System.Runtime.InteropServices;using System.Text;
public static class GalleryWindows {
 public delegate bool Callback(IntPtr h,IntPtr l);
 [DllImport("user32.dll")]public static extern bool EnumWindows(Callback c,IntPtr l);
 [DllImport("user32.dll")]public static extern bool EnumChildWindows(IntPtr h,Callback c,IntPtr l);
 [DllImport("user32.dll")]public static extern uint GetWindowThreadProcessId(IntPtr h,out uint p);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)]public static extern int GetWindowText(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)]public static extern int GetClassName(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")]public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")]public static extern IntPtr SendMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
 public static string Text(IntPtr h){var s=new StringBuilder(1024);GetWindowText(h,s,1024);return s.ToString();}
 public static string Class(IntPtr h){var s=new StringBuilder(256);GetClassName(h,s,256);return s.ToString();}
}
'@
$taskRows=[Collections.Generic.List[object]]::new()
[GalleryWindows]::EnumWindows({param($handle,$unused)
 $taskOwner=[uint32]0;[void][GalleryWindows]::GetWindowThreadProcessId($handle,[ref]$taskOwner)
 if($taskOwner -eq $HostProcessId -and [GalleryWindows]::IsWindowVisible($handle) -and [GalleryWindows]::Text($handle) -like 'Cyrus Scatter*'){
  $taskTitle=[GalleryWindows]::Text($handle);$taskChildren=[Collections.Generic.List[object]]::new()
  [void][GalleryWindows]::EnumChildWindows($handle,{param($child,$other)
   $taskChildren.Add(@{handle=$child.ToInt64();title=[GalleryWindows]::Text($child);class=[GalleryWindows]::Class($child)})
   return $true
  },[IntPtr]::Zero)
  $taskRows.Add(@{handle=$handle.ToInt64();title=$taskTitle;class=[GalleryWindows]::Class($handle);children=$taskChildren})
  if($AcceptInstaller -and $taskTitle -eq 'Cyrus Scatter 0.85.1'){
   if([GalleryWindows]::Class($handle) -like 'Qt*'){[void][GalleryWindows]::SendMessage($handle,0x10,[IntPtr]::Zero,[IntPtr]::Zero)}
   foreach($button in $taskChildren){if($button.title -eq 'OK' -and $button.class -eq 'Button'){[void][GalleryWindows]::SendMessage([IntPtr]$button.handle,0xF5,[IntPtr]::Zero,[IntPtr]::Zero)}}
  }
 }
 return $true
},[IntPtr]::Zero)|Out-Null
$taskRows|ConvertTo-Json -Depth 5
