param([string]$Run='installer-final')
$ErrorActionPreference='Stop'
$workspace='F:\Cursor\_Cyrus_Apps\CyrusScatter'
$work="$workspace\build\clearance-performance-08681-20261020\final"
$output=Join-Path $work $Run
if(Test-Path -LiteralPath $output){throw 'Fresh owned installer fixture required'}
[void][IO.Directory]::CreateDirectory($output)
Add-Type -Path "$work\CyrusInstaller.dll"
function Check([bool]$value,[string]$message){
 if(-not $value){throw $message}
 Add-Content -LiteralPath "$output\result.txt" -Value "PASS: $message"
}
$payload="$work\payload2027"
$inventory=[IO.File]::ReadAllBytes("$payload\InstallInventory.txt")
$engine=[Cyrus.Setup.InstallEngine]::new($payload,[Cyrus.Setup.InstallEngine]::Hash($inventory))
$paths=[Cyrus.Setup.InstallPaths]::new("$output\scripts","$output\startup","$output\macros","$output\profile","$output\runtime")
$paths.SharedContentRoot="$output\Library"
$paths.LibraryStatePath="$output\library-state.txt"
[void][IO.Directory]::CreateDirectory($paths.Profile)
$oldState="$workspace\build\final-08672-20261020\exe-ui-final\2027\cs\library-state.txt"
Copy-Item -LiteralPath $oldState -Destination $paths.LibraryStatePath
$before=[IO.File]::ReadAllBytes($paths.LibraryStatePath)
$old=[Cyrus.Content.LibraryLocation]::Read($paths.LibraryStatePath)
Check ($old.Root.StartsWith("$workspace\build\")) 'Existing library fixture belongs to the test workspace'
$missing="$output\missing"
[void][IO.Directory]::CreateDirectory($missing)
[void]$engine.ConfigureLibraryChoice($paths,$false,$missing)
Check ($engine.LibraryAction -eq 'Keep') 'Plugin-only update works without adjacent content'
$failed=$false
try{[void]$engine.ConfigureLibraryChoice($paths,$true,$missing)}catch{$failed=$_.Exception.Message.Contains('content ZIP not found')}
Check $failed 'Explicit content choice requires a matching ZIP'
[void]$engine.ConfigureLibraryChoice($paths,$false,$missing)
$plan=$engine.Plan($paths)
Check ($plan.Contains('Library new bytes: 0')) 'Plugin-only admission requests no new library bytes'
[void]$engine.Install($paths)
Check ([Cyrus.Setup.InstallEngine]::InstalledVersion($paths) -eq '0.86.8.1') 'Exact 0.86.8.1 package installs into disposable Max 2027 paths'
Check (([Cyrus.Content.LibraryLocation]::Read($paths.LibraryStatePath)).Root -eq $old.Root) 'Plugin update keeps the existing shared library location'
$plan=$engine.Plan($paths)
Check ($plan.Contains('Plugin new bytes: 0') -and $plan.Contains('Library new bytes: 0')) 'Repeat update admits zero new plugin and content bytes'
$delivery="$workspace\dist\CyrusScatter-0.86.8.1-20261020"
[void]$engine.ConfigureLibraryChoice($paths,$true,$delivery)
$plan=$engine.Plan($paths)
Check ($plan.Contains('Library new bytes: 0')) 'Checked real content ZIP reuses the verified existing library'
[void]$engine.Install($paths)
Check (([Cyrus.Content.LibraryLocation]::Read($paths.LibraryStatePath)).Root -eq $old.Root) 'Checked update creates no second library'
[IO.File]::WriteAllText("$output\plan.txt",$plan)
[IO.File]::WriteAllText("$output\installed-runtime.txt",([IO.File]::ReadAllLines("$output\scripts\CyrusScatter\installed.txt")[2]))
Add-Content -LiteralPath "$output\result.txt" -Value 'SUCCESS'
