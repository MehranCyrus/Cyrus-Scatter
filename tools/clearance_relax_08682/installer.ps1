param([string]$Run='installer-three-hosts')
$ErrorActionPreference='Stop'
$workspace='F:\Cursor\_Cyrus_Apps\CyrusScatter'
$work="$workspace\build\clearance-relax-08682-20261021"
$output=Join-Path $work $Run
if(Test-Path -LiteralPath $output){throw 'Fresh owned installer fixture required'}
[void][IO.Directory]::CreateDirectory($output)
Add-Type -Path "$work\CyrusInstaller.dll"
function Check([bool]$value,[string]$message){
 if(-not $value){throw $message}
 Add-Content -LiteralPath "$output\result.txt" -Value "PASS: $message"
}
$state="$output\library-state.txt"
Copy-Item -LiteralPath "$workspace\build\clearance-performance-08681-20261020\final\installer-final\library-state.txt" -Destination $state
$original=[Cyrus.Content.LibraryLocation]::Read($state)
Check ($original.Root.StartsWith("$workspace\build\")) 'Shared library belongs to the disposable workspace'
$missing="$output\missing"
[void][IO.Directory]::CreateDirectory($missing)
foreach($year in @(2024,2026,2027)){
 $payload="$work\payload$year"
 $inventory=[IO.File]::ReadAllBytes("$payload\InstallInventory.txt")
 $engine=[Cyrus.Setup.InstallEngine]::new($payload,[Cyrus.Setup.InstallEngine]::Hash($inventory))
 $root="$output\$year"
 $paths=[Cyrus.Setup.InstallPaths]::new("$root\scripts","$root\startup","$root\macros","$root\profile","$root\runtime")
 $paths.SharedContentRoot="$output\Library"
 $paths.LibraryStatePath=$state
 [void][IO.Directory]::CreateDirectory($paths.Profile)
 [void]$engine.ConfigureLibraryChoice($paths,$false,$missing)
 Check ($engine.LibraryAction -eq 'Keep') "$year plugin-only works without a ZIP"
 $failed=$false
 try{[void]$engine.ConfigureLibraryChoice($paths,$true,$missing)}catch{$failed=$_.Exception.Message.Contains('content ZIP not found')}
 Check $failed "$year checked missing ZIP fails before install"
 [void]$engine.ConfigureLibraryChoice($paths,$true,"$workspace\dist\CyrusScatter-0.86.8.2-20261021")
 $plan=$engine.Plan($paths)
 Check ($plan.Contains('Library new bytes: 0')) "$year reuses shared content with zero new library bytes"
 [void]$engine.Install($paths)
 Check ([Cyrus.Setup.InstallEngine]::InstalledVersion($paths) -eq '0.86.8.2') "$year exact plugin version installed"
 Check (([Cyrus.Content.LibraryLocation]::Read($state)).Root -eq $original.Root) "$year retains the same shared library"
 $plan=$engine.Plan($paths)
 Check ($plan.Contains('Plugin new bytes: 0') -and $plan.Contains('Library new bytes: 0')) "$year repeated update adds zero bytes"
 [IO.File]::WriteAllText("$root\plan.txt",$plan)
 [IO.File]::WriteAllText("$root\installed-runtime.txt",([IO.File]::ReadAllLines("$root\scripts\CyrusScatter\installed.txt")[2]))
}
Check (-not (Test-Path -LiteralPath "$output\Library")) 'No second content directory was created'
Add-Content -LiteralPath "$output\result.txt" -Value 'SUCCESS'
