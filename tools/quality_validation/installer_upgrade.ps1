param([Parameter(Mandatory=$true)][string]$Work,[Parameter(Mandatory=$true)][string]$Package)
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$workPath=[IO.Path]::GetFullPath($Work)
if(!$workPath.StartsWith((Join-Path $root 'build')+'\')){throw 'Owned build directory required'}
$output=Join-Path $workPath ('installer-upgrade-'+[Guid]::NewGuid().ToString('N').Substring(0,8))
[void][IO.Directory]::CreateDirectory($output)
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -Path (Join-Path $workPath 'CyrusInstaller.dll')
$payload=Join-Path $output 'payload'
[IO.Compression.ZipFile]::ExtractToDirectory([IO.Path]::GetFullPath($Package),$payload)
$engine=[Cyrus.Setup.InstallEngine]::new($payload,[Cyrus.Setup.InstallEngine]::Hash([IO.File]::ReadAllBytes((Join-Path $payload 'InstallInventory.txt'))))
$checks=[Collections.Generic.List[string]]::new()
function Check([bool]$value,[string]$message){if(!$value){throw $message};$checks.Add($message);Write-Output "PASS: $message"}
function Paths([string]$name){
 $p=Join-Path $output $name
 $v=[Cyrus.Setup.InstallPaths]::new((Join-Path $p 'scripts'),(Join-Path $p 'startup'),(Join-Path $p 'macros'),(Join-Path $p 'profile'),(Join-Path $p 'runtime'))
 $v.LibraryStatePath=Join-Path $p 'library-state.txt';$v.SharedContentRoot=Join-Path $p 'Library'
 foreach($dir in @($v.Startup,$v.Macros,$v.Profile)){[void][IO.Directory]::CreateDirectory($dir)}
 [IO.File]::WriteAllText((Join-Path $v.Profile 'Plugin.UserSettings.ini'),"[Directories]`r`nUnrelatedPlugin=C:\Unrelated\bin`r`n")
 return $v
}
function Targets($paths){return @((Join-Path $paths.Startup 'CyrusScatterStartup.ms'),(Join-Path $paths.Macros 'CyrusScatter.mcr'),(Join-Path $paths.Scripts 'CyrusScatter/installed.txt'),(Join-Path $paths.Profile 'Plugin.UserSettings.ini'))}
function Snapshot($paths){$v=@{};foreach($p in (Targets $paths)){$v[$p]=if(Test-Path -LiteralPath $p){[Convert]::ToBase64String([IO.File]::ReadAllBytes($p))}else{'ABSENT'}};return $v}
function Unchanged($paths,$before){$after=Snapshot $paths;foreach($p in $before.Keys){if($after[$p] -ne $before[$p]){return $false}};return $true}
function Legacy($paths,[string]$version,[int]$only=-1){
 $archive=Get-ChildItem (Join-Path $root 'dist') -Directory -Filter "CyrusScatter-$version-*" | ForEach-Object {Join-Path $_.FullName "CyrusScatter-$version-Max2027.mzp"} | Where-Object {Test-Path -LiteralPath $_} | Select-Object -Last 1
 $zip=[IO.Compression.ZipFile]::OpenRead($archive)
 try{$index=0;foreach($name in @('CyrusScatterStartup.ms','CyrusScatter.mcr')){
  if($only -lt 0 -or $only -eq $index){$entry=$zip.GetEntry($name);$input=$entry.Open();$dest=if($index -eq 0){Join-Path $paths.Startup $name}else{Join-Path $paths.Macros $name};$stream=[IO.File]::Create($dest);try{$input.CopyTo($stream)}finally{$stream.Dispose();$input.Dispose()}}
  $index++
 }}finally{$zip.Dispose()}
}
$fresh=Paths 'fresh';[void]$engine.Install($fresh)
Check ([Cyrus.Setup.InstallEngine]::InstalledVersion($fresh) -eq '0.86.8.4') 'Fresh exact-version install'
foreach($version in @('0.81.6','0.85.0','0.86.8.2','0.86.8.3')){
 $paths=Paths ('legacy-'+$version);Legacy $paths $version;$before=Snapshot $paths
 [void]$engine.Install($paths)
 Check ([Cyrus.Setup.InstallEngine]::InstalledVersion($paths) -eq '0.86.8.4') "Recognized no-receipt migration $version"
 $backup=@(Get-ChildItem (Join-Path $paths.Scripts 'CyrusScatter/Backups') -Directory)
 Check ($backup.Count -eq 1) "One backup for $version"
 foreach($name in @('CyrusScatterStartup.ms','CyrusScatter.mcr')){Check ([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $backup[0].FullName $name))) -eq $before[(Join-Path $(if($name.EndsWith('.mcr')){$paths.Macros}else{$paths.Startup}) $name)]) "Exact original backup $version / $name"}
 [void]$engine.Install($paths)
 Check (@(Get-ChildItem (Join-Path $paths.Scripts 'CyrusScatter/Backups') -Directory).Count -eq 1) "Repeat update does not duplicate backup $version"
 Check ([IO.File]::ReadAllText((Join-Path $paths.Profile 'Plugin.UserSettings.ini')).Contains('UnrelatedPlugin=C:\Unrelated\bin')) "Unrelated registration preserved $version"
}
foreach($only in @(0,1)){$paths=Paths "single-$only";Legacy $paths '0.81.6' $only;[void]$engine.Install($paths);Check ([Cyrus.Setup.InstallEngine]::InstalledVersion($paths) -eq '0.86.8.4') "Single remaining recognized wrapper $only"}
foreach($kind in @('startup','macro','receipt','recorded-edit')){
 $paths=Paths ('reject-'+$kind)
 if($kind -eq 'recorded-edit'){[void]$engine.Install($paths)}else{Legacy $paths '0.81.6'}
 $target=if($kind -eq 'macro'){Join-Path $paths.Macros 'CyrusScatter.mcr'}elseif($kind -eq 'receipt'){Join-Path $paths.Scripts 'CyrusScatter/installed.txt'}else{Join-Path $paths.Startup 'CyrusScatterStartup.ms'}
 [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target));[IO.File]::WriteAllText($target,'Unrecognized artist customization')
 $before=Snapshot $paths;$errorText='';try{[void]$engine.Install($paths)}catch{$errorText=$_.Exception.ToString()}
 Check ($errorText.Contains('Max 2027') -and $errorText.Contains($target)) "Conflict identifies host and path: $kind"
 Check (Unchanged $paths $before) "Conflict preserves all registration bytes: $kind"
}
foreach($phase in @('journal','publishing:0','publishing:1','publishing:2','publishing:3')){
 $paths=Paths ('interrupt-'+$phase.Replace(':','-'));Legacy $paths '0.81.6';$before=Snapshot $paths
 $interrupt=[Action[string]]{param($point) if($point -eq $phase){throw 'Owned interruption'}}
 $failed=$false;try{[void]$engine.Install($paths,$interrupt)}catch{$failed=$true}
 Check $failed "Interruption observed at $phase"
 Check (Unchanged $paths $before) "Original registration restored at $phase"
 Check (@(Get-ChildItem (Join-Path $paths.Scripts 'CyrusScatter/Backups') -Directory).Count -eq 1) "Migration backup retained at $phase"
 [void]$engine.Install($paths);Check ([Cyrus.Setup.InstallEngine]::InstalledVersion($paths) -eq '0.86.8.4') "Retry succeeds at $phase"
}
@{status='passed';max_year=2027;checks=$checks;package_sha256=(Get-FileHash -LiteralPath $Package).Hash.ToLowerInvariant();core_sha256=(Get-FileHash -LiteralPath (Join-Path $workPath 'CyrusInstaller.dll')).Hash.ToLowerInvariant();artist_profile_modified=$false}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath (Join-Path $output 'receipt.json')
Write-Output $output
