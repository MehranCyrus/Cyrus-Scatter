param([string]$Executable,[string]$OutputDir,[string]$ProfileTemplate)
$ErrorActionPreference='Stop'
$taskRoot=[IO.Path]::GetFullPath($OutputDir)
if(-not ($taskRoot.StartsWith('F:\Cursor\_Cyrus_Apps\CyrusScatter\build\ui-0852-20261016-01\exe-test-') -or $taskRoot.StartsWith('F:\Cursor\_Cyrus_Apps\CyrusScatter\build\mcp-qualification\foundation-ui0852-recipient-'))) {throw 'Owned EXE fixture required'}
New-Item -ItemType Directory -Path $taskRoot -Force | Out-Null
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
[Threading.SynchronizationContext]::SetSynchronizationContext([Windows.Forms.WindowsFormsSynchronizationContext]::new())
$taskAssembly=[Reflection.Assembly]::LoadFrom($Executable)
$taskFlags=[Reflection.BindingFlags]'Instance,NonPublic'
$taskForm=[Activator]::CreateInstance($taskAssembly.GetType('Cyrus.Setup.SetupWindow'),$true)
$taskType=$taskForm.GetType()
$taskProfile=$taskType.GetField('profile',$taskFlags).GetValue($taskForm)
$taskStatus=$taskType.GetField('status',$taskFlags).GetValue($taskForm)
$taskINI=Join-Path $taskRoot 'max.ini'
$taskINIText=[IO.File]::ReadAllText($ProfileTemplate)
foreach($taskPair in @(@('Additional Scripts','scripts'),@('Additional Startup Scripts','startup'),@('Additional Macros','macros'))) {
    $taskReplacement=$taskPair[0]+'='+(Join-Path $taskRoot $taskPair[1])
    $taskINIText=[regex]::Replace($taskINIText,('(?m)^'+[regex]::Escape($taskPair[0])+'=.*$'),[Text.RegularExpressions.MatchEvaluator]{param($match) $taskReplacement})
}
[IO.File]::WriteAllText($taskINI,$taskINIText,[Text.Encoding]::Unicode)
$taskProfile.Text=$taskINI
$null=$taskType.GetMethod('RefreshDestination',$taskFlags).Invoke($taskForm,@())
$taskForm.StartPosition=[Windows.Forms.FormStartPosition]::Manual
$taskForm.Location=[Drawing.Point]::new(-32000,-32000)
$taskForm.ShowInTaskbar=$false
$taskForm.Show()
[Windows.Forms.Application]::DoEvents()
$taskChecks=[Collections.Generic.List[string]]::new()
function Check([bool]$Value,[string]$Message){if(-not $Value){throw $Message};$taskChecks.Add($Message)}
try {
    $taskButton=$taskType.GetField('install',$taskFlags).GetValue($taskForm)
    Check $taskButton.Enabled 'Initialized owned profile enables installation'
    $taskTask=$taskType.GetMethod('Run',$taskFlags).Invoke($taskForm,@($false))
    $taskDeadline=[DateTime]::UtcNow.AddMinutes(2)
    while(-not $taskTask.IsCompleted -and [DateTime]::UtcNow -lt $taskDeadline){[Windows.Forms.Application]::DoEvents();Start-Sleep -Milliseconds 20}
    Check $taskTask.IsCompleted 'EXE Install handler completes asynchronously'
    $taskTask.GetAwaiter().GetResult()
    Check ($taskStatus.Text.StartsWith('Installed.')) ('EXE reports committed install: '+$taskStatus.Text)
    Check (Test-Path -LiteralPath (Join-Path $taskRoot 'Plugin.UserSettings.ini')) 'EXE registers only the owned profile'
    $taskReceipt=[IO.File]::ReadAllLines((Join-Path $taskRoot 'scripts/CyrusScatter/installed.txt'))
    Check (Test-Path -LiteralPath (Join-Path $taskReceipt[2] 'bin/AminScatter.dlx')) 'EXE stages its embedded native module'
    Check (Test-Path -LiteralPath (Join-Path $taskReceipt[2] 'Library-0.85.2/inventory.json')) 'EXE includes bundled presets and previews'
    $taskBitmap=[Drawing.Bitmap]::new($taskForm.Width,$taskForm.Height)
    $taskForm.DrawToBitmap($taskBitmap,[Drawing.Rectangle]::new(0,0,$taskForm.Width,$taskForm.Height))
    $taskBitmap.Save((Join-Path $taskRoot 'installer-100.png'));$taskBitmap.Dispose()
    $taskForm.Scale([Drawing.SizeF]::new(1.5,1.5))
    $taskBitmap=[Drawing.Bitmap]::new($taskForm.Width,$taskForm.Height)
    $taskForm.DrawToBitmap($taskBitmap,[Drawing.Rectangle]::new(0,0,$taskForm.Width,$taskForm.Height))
    $taskBitmap.Save((Join-Path $taskRoot 'installer-scaled-150.png'));$taskBitmap.Dispose()
    Check ($taskButton.Right -le $taskButton.Parent.ClientSize.Width -and $taskButton.Bottom -le $taskButton.Parent.ClientSize.Height) 'Install button fits the scaled layout'
    Check ($taskButton.Visible -and $taskButton.Width -gt 50) 'Actual visible child controls are created for visual inspection'
    $taskHasher=[Security.Cryptography.SHA256]::Create()
    try{$taskHash=[BitConverter]::ToString($taskHasher.ComputeHash([IO.File]::ReadAllBytes($Executable))).Replace('-','').ToLowerInvariant()}finally{$taskHasher.Dispose()}
    @{status='passed';checks=$taskChecks;scope='Actual compiled EXE async handler; scripted 100/150% layout, not physical mixed-DPI input';executable_sha256=$taskHash;release=$taskReceipt[2]} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $taskRoot 'result.json') -Encoding utf8
    Write-Output ($taskChecks.Count.ToString()+' EXE checks passed')
}finally{$taskForm.Dispose()}
