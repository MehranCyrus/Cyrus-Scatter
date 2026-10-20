param([string]$Workspace='F:\Cursor\_Cyrus_Apps\CyrusScatter')
$ErrorActionPreference='Stop'
$dist=Join-Path $Workspace 'dist\CyrusScatter-0.86.7.1-20261020'
$out=Join-Path $Workspace 'build\update-08671-20261020\installer-visual'
[void][IO.Directory]::CreateDirectory($out)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$assembly=[Reflection.Assembly]::LoadFrom("$dist\CyrusScatter-0.86.7.1-Setup.exe")
[Windows.Forms.Application]::EnableVisualStyles()
$form=[Activator]::CreateInstance($assembly.GetType('Cyrus.Setup.SetupWindow'),$true)
# Render the real installer form off-screen. Never click Apply/Unregister.
$form.StartPosition=[Windows.Forms.FormStartPosition]::Manual
$form.Location=[Drawing.Point]::new(-3000,-3000)
$form.ShowInTaskbar=$false
Add-Type -TypeDefinition 'using System;using System.Runtime.InteropServices;public static class PreviewWindow { [DllImport("user32.dll")] public static extern IntPtr GetWindowLongPtr(IntPtr h,int i);[DllImport("user32.dll")] public static extern IntPtr SetWindowLongPtr(IntPtr h,int i,IntPtr v); }'
$form.CreateControl()
$form.PerformLayout()
$handle=$form.Handle
$style=[PreviewWindow]::GetWindowLongPtr($handle,-20).ToInt64()
[void][PreviewWindow]::SetWindowLongPtr($handle,-20,[IntPtr]($style -bor 0x08000000))
$form.Show()
[Windows.Forms.Application]::DoEvents()
$bmp=[Drawing.Bitmap]::new($form.Width,$form.Height)
$form.DrawToBitmap($bmp,[Drawing.Rectangle]::new(0,0,$form.Width,$form.Height))
$bmp.Save("$out\plugin-only.png",[Drawing.Imaging.ImageFormat]::Png);$bmp.Dispose()
$options=@($form.Controls | Where-Object {$_.GetType().FullName -eq 'Cyrus.Setup.LibraryOptions'})[0]
$flags=[Reflection.BindingFlags]'Instance,NonPublic'
$mode=$options.GetType().GetField('mode',$flags).GetValue($options)
$action=$options.GetType().GetField('action',$flags).GetValue($options)
$mode.SelectedIndex=1;$action.SelectedIndex=1
$form.PerformLayout();[Windows.Forms.Application]::DoEvents()
$bmp=[Drawing.Bitmap]::new($form.Width,$form.Height)
$form.DrawToBitmap($bmp,[Drawing.Rectangle]::new(0,0,$form.Width,$form.Height))
$bmp.Save("$out\plugin-and-content.png",[Drawing.Imaging.ImageFormat]::Png);$bmp.Dispose()
@{status='rendered';scope='Real EXE form, default plugin-only and explicit shared-content choices; no installation buttons activated';size=@($form.Width,$form.Height)} | ConvertTo-Json | Set-Content "$out\result.json"
$form.Dispose()
