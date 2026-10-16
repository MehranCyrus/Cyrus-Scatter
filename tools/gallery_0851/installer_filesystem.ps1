param([string]$CorePath, [string]$PackageDir, [string]$InventoryHash, [string]$OutputDir)
$ErrorActionPreference = 'Stop'
if (-not [IO.Path]::GetFullPath($OutputDir).StartsWith('F:\Cursor\_Cyrus_Apps\CyrusScatter\build\gallery-0851-20261016-01\installer-files-')) { throw 'Owned installer fixture required' }
Add-Type -Path $CorePath
$taskChecks = [Collections.Generic.List[string]]::new()
function Check([bool]$Value, [string]$Message) { if (-not $Value) { throw $Message }; $taskChecks.Add($Message) }
function Fingerprint([string]$Path) { if (Test-Path -LiteralPath $Path) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }; return 'missing' }
$taskDestination = Join-Path $OutputDir 'Owned profile with spaces ژ'
$taskScripts = Join-Path $taskDestination 'scripts'
$taskStartup = Join-Path $taskDestination 'startup'
$taskMacros = Join-Path $taskDestination 'macros'
$taskProfile = Join-Path $taskDestination 'profile'
New-Item -ItemType Directory -Path $taskProfile -Force | Out-Null
$taskINI = Join-Path $taskProfile 'Plugin.UserSettings.ini'
[IO.File]::WriteAllText($taskINI, "[Directories]`r`nOtherPlugin=F:\Keep me`r`n[Other]`r`nsetting=yes`r`n")
$taskPaths = [Cyrus.Setup.InstallPaths]::new($taskScripts, $taskStartup, $taskMacros, $taskProfile)
$taskEngine = [Cyrus.Setup.InstallEngine]::new($PackageDir, $InventoryHash)
$taskRelease = $taskEngine.Install($taskPaths)
Check ((Test-Path -LiteralPath (Join-Path $taskRelease 'bin/AminScatter.dlx'))) 'Fresh install stages the complete versioned runtime'
Check ((Test-Path -LiteralPath (Join-Path $taskRelease 'Library-0.85.1/example.csrecipe.json'))) 'Bundled content stays inside its release'
$taskContent = [IO.File]::ReadAllText($taskINI)
Check ($taskContent.Contains('OtherPlugin=F:\Keep me') -and $taskContent.Contains('setting=yes') -and $taskContent.Contains('CyrusScatter2027=')) 'Other plugin/profile settings survive registration'
$taskTargets = @((Join-Path $taskStartup 'CyrusScatterStartup.ms'), (Join-Path $taskMacros 'CyrusScatter.mcr'), (Join-Path $taskScripts 'CyrusScatter/installed.txt'), $taskINI)
$taskBefore = @($taskTargets | ForEach-Object { Fingerprint $_ })
$null = $taskEngine.Install($taskPaths)
Check ((Compare-Object $taskBefore @($taskTargets | ForEach-Object { Fingerprint $_ })).Count -eq 0) 'Identical reinstall leaves registration and wrapper bytes unchanged'
$taskMissing = Join-Path $taskRelease 'bin/CyrusBrush.dlx'
Remove-Item -LiteralPath $taskMissing
$null = $taskEngine.Install($taskPaths)
Check ((Test-Path -LiteralPath $taskMissing)) 'Repair restores a missing owned payload'
# A changed owned file is preserved and blocks repair, rather than being overwritten.
[IO.File]::WriteAllText($taskMissing, 'Owned user modification')
$taskFailed = $false
try { $null = $taskEngine.Install($taskPaths) } catch { $taskFailed = $true }
Check ($taskFailed -and [IO.File]::ReadAllText($taskMissing) -eq 'Owned user modification') 'Changed payload is preserved and rejected'
[IO.File]::Copy((Join-Path $PackageDir 'CyrusBrush.dlx'), $taskMissing, $true)
# Use a clean profile per publication boundary. All prior files must be restored.
foreach ($taskPhase in @('journal', 'publishing:1', 'publishing:2', 'publishing:3')) {
    $taskCase = Join-Path $OutputDir ('failure-' + $taskPhase.Replace(':', '-'))
    $taskCasePaths = [Cyrus.Setup.InstallPaths]::new((Join-Path $taskCase 'scripts'), (Join-Path $taskCase 'startup'), (Join-Path $taskCase 'macros'), (Join-Path $taskCase 'profile'))
    New-Item -ItemType Directory -Path (Join-Path $taskCase 'profile') -Force | Out-Null
    $taskCaseINI = Join-Path $taskCase 'profile/Plugin.UserSettings.ini'
    [IO.File]::WriteAllText($taskCaseINI, '[Directories]')
    $taskPriorINI = Fingerprint $taskCaseINI
    $taskAction = [Action[string]] { param($phase) if ($phase -eq $taskPhase) { throw 'Owned injected install failure' } }
    $taskFailed = $false
    try { $null = $taskEngine.Install($taskCasePaths, $taskAction) } catch { $taskFailed = $true }
    Check $taskFailed ('Injected failure reached ' + $taskPhase)
    Check ((Fingerprint $taskCaseINI) -eq $taskPriorINI -and -not (Test-Path -LiteralPath (Join-Path $taskCase 'startup/CyrusScatterStartup.ms')) -and -not (Test-Path -LiteralPath (Join-Path $taskCase 'macros/CyrusScatter.mcr')) -and -not (Test-Path -LiteralPath (Join-Path $taskCase 'scripts/CyrusScatter/installed.txt'))) ('Rollback restores prior bindings after ' + $taskPhase)
    $null = $taskEngine.Install($taskCasePaths)
    Check ([IO.File]::ReadAllText($taskCaseINI).Contains('CyrusScatter2027=')) ('Retry succeeds after ' + $taskPhase)
}
[Cyrus.Setup.InstallEngine]::RemoveRegistration($taskPaths)
Check (-not [IO.File]::ReadAllText($taskINI).Contains('CyrusScatter2027=') -and [IO.File]::ReadAllText($taskINI).Contains('OtherPlugin=')) 'Unregister preserves other plugin settings'
Check (-not (Test-Path -LiteralPath $taskTargets[0]) -and -not (Test-Path -LiteralPath $taskTargets[1])) 'Unregister removes owned startup and macro'
Check ((Test-Path -LiteralPath (Join-Path $taskRelease 'Library-0.85.1/example.csrecipe.json'))) 'Unregister preserves bundled recovery content'
$null = $taskEngine.Install($taskPaths)
Check ([IO.File]::ReadAllText($taskINI).Contains('CyrusScatter2027=')) 'Reinstall after unregister succeeds'
@{status='passed';checks=$taskChecks;installed_artist_profile=$false;scope='Filesystem only; inert payloads'} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $OutputDir 'result.json') -Encoding utf8
Write-Output ($taskChecks.Count.ToString() + ' installer filesystem checks passed')
