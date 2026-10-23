param([string]$Run='installer-core-final02')
$ErrorActionPreference='Stop'
if($Run -notmatch '^[a-zA-Z0-9_-]+$'){throw 'Invalid owned run name'}
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$work=Join-Path $root 'build/refinement-08683-20261022'
$output=Join-Path $work $Run
if(Test-Path -LiteralPath $output){throw 'Fresh owned installer directory required'}
[void][IO.Directory]::CreateDirectory($output)
Add-Type -Path (Join-Path $work 'CyrusInstaller.dll')
$checks=[Collections.Generic.List[string]]::new()
function Check([bool]$value,[string]$message){if(!$value){throw $message};$checks.Add($message);Write-Output "PASS: $message"}
$state=Join-Path $output 'library-state.txt'
$seed=Join-Path $root 'build/clearance-relax-08682-20261021/installer-three-hosts/library-state.txt'
Copy-Item -LiteralPath $seed -Destination $state
$original=[Cyrus.Content.LibraryLocation]::Read($state)
Check ($original.Root.StartsWith((Join-Path $root 'build')+'\')) 'Content reuse target is an existing owned fixture'
$payload=Join-Path $output 'payload'
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $root 'dist/CyrusScatter-0.86.8.3-20261022/CyrusScatter-0.86.8.3-Max2027.mzp'),$payload)
$inventory=[IO.File]::ReadAllBytes((Join-Path $payload 'InstallInventory.txt'))
$engine=[Cyrus.Setup.InstallEngine]::new($payload,[Cyrus.Setup.InstallEngine]::Hash($inventory))
$paths=[Cyrus.Setup.InstallPaths]::new((Join-Path $output 'scripts'),(Join-Path $output 'startup'),(Join-Path $output 'macros'),(Join-Path $output 'profile'),(Join-Path $output 'runtime'))
$paths.LibraryStatePath=$state;$paths.SharedContentRoot=Join-Path $output 'Library'
[void][IO.Directory]::CreateDirectory($paths.Profile)
$missing=Join-Path $output 'missing';[void][IO.Directory]::CreateDirectory($missing)
[void]$engine.ConfigureLibraryChoice($paths,$false,$missing)
Check ($engine.LibraryAction -eq 'Keep') 'Plugin-only update requires no content ZIP'
$failed=$false
try{[void]$engine.ConfigureLibraryChoice($paths,$true,$missing)}catch{$failed=$_.Exception.Message.Contains('content ZIP not found')}
Check $failed 'Checked missing content fails before installation'
[void]$engine.ConfigureLibraryChoice($paths,$false,$missing)
$old=Join-Path $root 'build/clearance-relax-08682-20261021/payload2027'
$oldInventory=[IO.File]::ReadAllBytes((Join-Path $old 'InstallInventory.txt'))
$oldEngine=[Cyrus.Setup.InstallEngine]::new($old,[Cyrus.Setup.InstallEngine]::Hash($oldInventory))
[void]$oldEngine.Install($paths)
Check ([Cyrus.Setup.InstallEngine]::InstalledVersion($paths) -eq '0.86.8.2') 'Disposable preceding-version installation is established'
$before=@{}
foreach($path in @((Join-Path $paths.Startup 'CyrusScatterStartup.ms'),(Join-Path $paths.Macros 'CyrusScatter.mcr'),(Join-Path $paths.Profile 'Plugin.UserSettings.ini'),(Join-Path $paths.Scripts 'CyrusScatter/installed.txt'))){$before[$path]=[IO.File]::ReadAllBytes($path)}
$failed=$false
$interrupt=[Action[string]]{param($phase) if($phase -eq 'publishing:1'){throw 'Owned publication interruption'}}
try{[void]$engine.Install($paths,$interrupt)}catch{$failed=$true}
Check $failed 'Publication interruption is observed'
foreach($path in $before.Keys){Check ([Convert]::ToBase64String([IO.File]::ReadAllBytes($path)) -eq [Convert]::ToBase64String($before[$path])) ('Rollback preserved '+[IO.Path]::GetFileName($path))}
Check ([Cyrus.Setup.InstallEngine]::InstalledVersion($paths) -eq '0.86.8.2') 'Interrupted update retains preceding version'
[void]$engine.Install($paths)
Check ([Cyrus.Setup.InstallEngine]::InstalledVersion($paths) -eq '0.86.8.3') 'Retry installs exact current version'
$plan=$engine.Plan($paths)
Check ($plan.Contains('Plugin new bytes: 0') -and $plan.Contains('Library new bytes: 0')) 'Repeated update requires zero new plugin/content bytes'
Check (([Cyrus.Content.LibraryLocation]::Read($state)).Root -eq $original.Root) 'Existing shared content binding is retained'
Check (!(Test-Path -LiteralPath $paths.SharedContentRoot)) 'No duplicate content directory was created'
$exe=Join-Path $root 'dist/CyrusScatter-0.86.8.3-20261022/CyrusScatter-0.86.8.3-Setup.exe'
$assembly=[Reflection.Assembly]::LoadFile($exe)
$resources=$assembly.GetManifestResourceNames()
Check (($resources | Where-Object {$_ -like 'Cyrus.Payload.*.mzp'}).Count -eq 1) 'EXE embeds only the qualified Max 2027 package'
$stream=$assembly.GetManifestResourceStream('Cyrus.Payload.2027.mzp');$hash=[Security.Cryptography.SHA256]::Create()
try{$actual=([BitConverter]::ToString($hash.ComputeHash($stream))).Replace('-','').ToLowerInvariant()}finally{$stream.Dispose();$hash.Dispose()}
$expected=(Get-FileHash -LiteralPath (Join-Path $root 'dist/CyrusScatter-0.86.8.3-20261022/CyrusScatter-0.86.8.3-Max2027.mzp')).Hash.ToLowerInvariant()
Check ($actual -eq $expected) 'Embedded MZP equals the standalone exact archive'
$runtime=([IO.File]::ReadAllLines((Join-Path $paths.Scripts 'CyrusScatter/installed.txt')))[2]
@{status='passed';max_year=2027;checks=$checks;runtime=$runtime;artist_installation=$false;content_root=$original.Root;driver_sha256=(Get-FileHash -LiteralPath $PSCommandPath).Hash.ToLowerInvariant();package_sha256=$expected}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $output 'receipt.json')
