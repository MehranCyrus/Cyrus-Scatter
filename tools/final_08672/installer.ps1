param([string]$Output)
$ErrorActionPreference='Stop'
$workspace='F:\Cursor\_Cyrus_Apps\CyrusScatter'
if(-not [IO.Path]::GetFullPath($Output).StartsWith("$workspace\build\final-08672-20261020\installer-")){throw 'Owned fixture required'}
Add-Type -Path "$workspace\build\final-08672-20261020\CyrusInstaller.dll"
$packages=Get-Content -LiteralPath "$Output\packages.json" -Raw | ConvertFrom-Json
$checks=[Collections.Generic.List[string]]::new()
function Check([bool]$value,[string]$message){if(-not $value){throw $message};$checks.Add($message)}
function Paths([string]$name){
    $base=Join-Path $Output $name
    $p=[Cyrus.Setup.InstallPaths]::new("$base\scripts","$base\startup","$base\macros","$base\profile","$base\runtime")
    $p.SharedContentRoot="$Output\Shared"
    $p.LibraryStatePath="$Output\Shared\library-state.txt"
    [void][IO.Directory]::CreateDirectory($p.Profile)
    return $p
}
function Engine([int]$index){return [Cyrus.Setup.InstallEngine]::new($packages[$index].path,$packages[$index].hash)}
function FileId([string]$path){return (& fsutil.exe file queryfileid $path | Out-String).Trim()}
function Get-FileHash([string]$LiteralPath){return @{Hash=[Cyrus.Setup.InstallEngine]::Hash([IO.File]::ReadAllBytes($LiteralPath))}}
$zipPaths=Paths 'zip-install'
$zipPaths.SharedContentRoot="$Output\ZipShared"
$zipPaths.LibraryStatePath="$Output\ZipShared\state.txt"
$zip=Engine 2
$note=$zip.ConfigureLibraryChoice($zipPaths,$false,$Output)
Check ($zip.LibraryAction -eq 'Keep') 'Unchecked content ignores adjacent ZIP'
$missingZip="$Output\no-zip";[void][IO.Directory]::CreateDirectory($missingZip)
$failed=$false;try{[void]$zip.ConfigureLibraryChoice($zipPaths,$true,$missingZip)}catch{$failed=$true}
Check $failed 'Checked content requires matching ZIP before any installation'
foreach($bad in @('traversal','extra','duplicate')){
 $failed=$false;try{[void]$zip.ConfigureLibraryChoice($zipPaths,$true,"$Output\$bad")}catch{$failed=$true}
 Check $failed ("Reject invalid ZIP "+$bad)
}
$note=$zip.ConfigureLibraryChoice($zipPaths,$true,$Output)
Check ($zip.LibraryAction -eq 'Install') 'ZIP selects managed shared installation'
$checkpoint=[Action[string]]{param($value)if($value -eq 'content-ready'){throw 'Owned cancellation'}}
$failed=$false;try{[void]$zip.InstallLibrary($zipPaths,$checkpoint)}catch{$failed=$true}
Check ($failed -and -not (Test-Path -LiteralPath $zipPaths.LibraryStatePath)) 'Cancellation leaves no incomplete active library'
$zipRoot=$zip.InstallLibrary($zipPaths,$null)
## A newer-host library must not prevent an older host's plugin-only update.
$newerOnly=Paths 'newer-content'
$newerOnly.LibraryStatePath="$Output\newer-content\state.txt"
[void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($newerOnly.LibraryStatePath))
$newerRegistration=[Cyrus.Content.LibraryLocation]::Read($zipPaths.LibraryStatePath)
$newerRegistration.MinimumHost=2027
[IO.File]::WriteAllText($newerOnly.LibraryStatePath,$newerRegistration.Serialize())
$olderEngine=Engine 0
$newerNote=$olderEngine.ConfigureLibraryChoice($newerOnly,$false,$Output)
Check ($olderEngine.LibraryAction -eq 'Keep' -and $newerNote.Contains('requires Max 2027')) 'Plugin-only Max 2024 update retains a Max-2027-only shared library without blocking'
[void]$olderEngine.Install($newerOnly)
Check ([Cyrus.Content.LibraryLocation]::Read($newerOnly.LibraryStatePath).MinimumHost -eq 2027) 'Older host plugin installation preserves the newer shared content registration'
Check ([IO.File]::ReadAllText("$zipRoot\Models\leaf\model.max").StartsWith('Owned inert')) 'ZIP streams real entry bytes into shared pack'
Check (-not (Test-Path -LiteralPath "$Output\Library")) 'No full ZIP extraction beside the download'
foreach($index in @(0,1,2)){
 $e=Engine $index;$note=$e.ConfigureLibraryChoice($zipPaths,$true,$Output)
 Check ($e.Plan($zipPaths).Contains('Library new bytes: 0')) 'Repeat ZIP installation adds zero library bytes'
 [void]$e.InstallLibrary($zipPaths,$null)
 Check ([Cyrus.Content.LibraryLocation]::Read($zipPaths.LibraryStatePath).Root -eq $zipRoot) 'Three hosts reuse the same ZIP-installed pack'
}
$damaged=Paths 'damaged-zip';$damaged.SharedContentRoot="$Output\DamagedShared";$damaged.LibraryStatePath="$Output\DamagedShared\state.txt"
$badEngine=Engine 2;[void]$badEngine.ConfigureLibraryChoice($damaged,$true,"$Output\damaged")
$failed=$false;try{[void]$badEngine.InstallLibrary($damaged,$null)}catch{$failed=$true}
Check ($failed -and -not (Test-Path -LiteralPath $damaged.LibraryStatePath)) 'Wrong ZIP payload hash cannot publish content'
$existing=Paths 'existing-choice';$existing.LibraryStatePath=$zipPaths.LibraryStatePath
$keep=Engine 2;[void]$keep.ConfigureLibraryChoice($existing,$false,$missingZip)
Check ($keep.LibraryAction -eq 'Keep') 'Plugin-only retains library even without download ZIP'
$failed=$false;try{[void]$keep.ConfigureLibraryChoice($existing,$true,$missingZip)}catch{$failed=$true}
Check $failed 'Explicit content choice still reports missing ZIP on an installed machine'
$p=Paths 'Max2027'
$e=Engine 2
$fresh=Paths 'automatic-fresh'
$fresh.LibraryStatePath="$Output\automatic-fresh\library-state.txt"
$auto=Engine 2
$note=$auto.ConfigureAutomaticLibrary($fresh,[string[]]@("$Output\absent"))
Check ($auto.LibraryAction -eq 'Keep' -and $note.Contains('Plant library not found')) 'Automatic fresh install clearly reports absent content'
$note=$auto.ConfigureAutomaticLibrary($fresh,[string[]]@("$Output\absent","$Output\Content"))
Check ($auto.LibraryAction -eq 'UseExisting' -and $note.Contains('without copying')) 'Automatic discovery selects existing companion content'
$autoRelease=$auto.Install($fresh)
Check ([Cyrus.Content.LibraryLocation]::ResolveRoot($autoRelease,2027) -eq "$Output\Content\Library") 'Automatic adoption publishes the existing content root'
$auto2=Engine 2
$note=$auto2.ConfigureAutomaticLibrary($fresh,[string[]]@("$Output\absent"))
Check ($auto2.LibraryAction -eq 'Keep') 'Automatic updates reuse the registered library'
# Reproduce the legacy fallback left by an earlier plugin-only update.
$legacy=Paths 'automatic-legacy'
$legacy.LibraryStatePath="$Output\automatic-legacy\state.txt"
$legacyEngine=Engine 2
$legacyRelease=$legacyEngine.Install($legacy)
$registration=[Cyrus.Content.LibraryLocation]::Read($fresh.LibraryStatePath)
[IO.File]::WriteAllText("$legacyRelease\LibraryBinding.txt",[Cyrus.Content.LibraryLocation]::BindingText($legacy.LibraryStatePath,$registration),[Text.UTF8Encoding]::new($false))
Check ([Cyrus.Setup.InstallEngine]::SuggestContentDirectory($legacy) -eq "$Output\Content\Library") 'Legacy runtime fallback is discovered through its installed receipt'
$note=$legacyEngine.ConfigureAutomaticLibrary($legacy,[string[]]@())
Check ($legacyEngine.LibraryAction -eq 'UseExisting') 'Legacy fallback automatically becomes a shared library'
$missing=Paths 'automatic-missing'
$missing.LibraryStatePath="$Output\automatic-missing\state.txt"
[void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($missing.LibraryStatePath))
$registration.Root="$Output\unavailable\Library"
[IO.File]::WriteAllText($missing.LibraryStatePath,$registration.Serialize())
$failed=$false;try{[void]$auto2.ConfigureAutomaticLibrary($missing,[string[]]@())}catch{$failed=$true}
Check $failed 'Missing previously registered catalog is reported before installation'
$release=$e.Install($p)
Check (Test-Path -LiteralPath "$release\CyrusScatter.ms") 'Plugin-only installs without any content selection'
Check (-not (Test-Path -LiteralPath "$release\Library-0.86.7.2")) 'Plugin runtime contains no copied model library'
Check ([Cyrus.Content.LibraryLocation]::ResolveRoot($release,2027) -eq '') 'Fresh plugin-only has a clean unconfigured library'
Check ($e.Plan($p).Contains('Library new bytes: 0')) 'Plugin-only preflight does not charge for content'
$id=FileId "$Output\Content\Library\Maps\shared.bin"
$e.SetContentDirectory("$Output\Content\Library")
$e.LibraryAction='UseExisting'
$adopt=$e.InstallLibrary($p,$null)
Check ($adopt -eq "$Output\Content\Library") 'Adopt keeps existing content in its original folder'
Check ((FileId "$adopt\Maps\shared.bin") -eq $id) 'Adoption preserves the physical file'
Check ([Cyrus.Content.LibraryLocation]::ResolveRoot($release,2027) -eq $adopt) 'Existing new plugin resolves an independently selected library'
foreach($index in @(0,1)){
    $other=Paths ('Max'+$packages[$index].year)
    $otherEngine=Engine $index
    $installed=$otherEngine.Install($other)
    Check ([Cyrus.Content.LibraryLocation]::ResolveRoot($installed,$packages[$index].year) -eq $adopt) ('Max '+$packages[$index].year+' uses the same library root')
    Check (-not (Test-Path -LiteralPath "$installed\Library-0.86.7.2")) 'No per-host content copy'
}
$beforeState=[IO.File]::ReadAllBytes($p.LibraryStatePath)
$e.LibraryAction='Install'
$managed=$e.InstallLibrary($p,$null)
Check ($managed.StartsWith("$Output\Shared\packs\")) 'Explicit library install uses shared packs independently of plugin version'
Check ((FileId "$managed\Maps\shared.bin") -eq $id) 'Same-volume installation reuses verified physical bytes'
$stateHash=(Get-FileHash -LiteralPath $p.LibraryStatePath).Hash
Check ($e.InstallLibrary($p,$null) -eq $managed) 'Identical content reinstall is idempotent'
Check ((Get-FileHash -LiteralPath $p.LibraryStatePath).Hash -eq $stateHash) 'Repeated install preserves the selected content identity'
Remove-Item -LiteralPath "$managed\Maps\shared.bin"
[void]$e.InstallLibrary($p,$null)
Check ((FileId "$managed\Maps\shared.bin") -eq $id) 'Repair restores only the missing hard link'
$e.LibraryAction='Keep'
foreach($phase in @('copied:CyrusScatter.ms','journal','publishing:1','publishing:3')){
    $failure=Paths ('failure-'+$phase.Replace(':','-'))
    $checkpoint=[Action[string]]{param($value)if($value -eq $phase){throw 'Injected owned failure'}}
    $failed=$false;try{[void]$e.Install($failure,$checkpoint)}catch{$failed=$true}
    Check $failed ('Failure injected at '+$phase)
    Check (-not (Test-Path -LiteralPath ($failure.Scripts+'\CyrusScatter\installed.txt'))) 'Failed plugin publication leaves no active receipt'
    [void]$e.Install($failure)
}
$e.LibraryAction='UseExisting'
$checkpoint=[Action[string]]{param($value)if($value -eq 'content-ready'){throw 'Injected content cancellation'}}
$failed=$false;try{[void]$e.InstallLibrary($p,$checkpoint)}catch{$failed=$true}
Check $failed 'Cancellation before library publication is honored'
Check ((Get-FileHash -LiteralPath $p.LibraryStatePath).Hash -eq $stateHash) 'Cancelled library selection preserves prior active content'
$e.LibraryAction='Keep'
$prior=(Get-FileHash -LiteralPath "$release\CyrusScatter.ms").Hash
[void]$e.Install($p)
Check ((Get-FileHash -LiteralPath "$release\CyrusScatter.ms").Hash -eq $prior) 'Plugin repair preserves its exact runtime'
[Cyrus.Setup.InstallEngine]::RemoveRegistration($p,'2027')
Check (Test-Path -LiteralPath "$managed\Maps\shared.bin") 'Unregistering one host retains shared content'
$other=Paths 'Max2024'
Check (Test-Path -LiteralPath ($other.Scripts+'\CyrusScatter\installed.txt')) 'Other hosts stay registered'
# Exercise the exact admission calculation with deterministic free-space inputs;
# this does not fill the user's drive or claim a physical low-disk experiment.
$method=[Cyrus.Setup.InstallEngine].GetMethod('CheckFreeSpace',[Reflection.BindingFlags]'NonPublic,Static')
$failed=$false
try{[void]$method.Invoke($null,@('C:\',[long]1024,[long]2048))}catch{$failed=$_.Exception.ToString().Contains('Not enough free space')}
Check $failed 'Synthetic per-volume low-space admission rejects before writes'
[void]$method.Invoke($null,@('F:\',[long](20*1024*1024),[long]0))
Check $true 'Zero-byte reuse needs only the working-space allowance'
$e.LibraryAction='Install'
$e.LibraryDestination=Join-Path $Output ('long-'+('x'*170))
$failed=$false;try{[void]$e.Plan($p)}catch{$failed=$_.Exception.ToString().Contains('shorter shared library')}
Check $failed 'Long library paths are rejected during read-only preflight'
Check (-not (Test-Path -LiteralPath $e.LibraryDestination)) 'Long-path preflight creates no content destination'
$e.LibraryDestination=$null;$e.LibraryAction='UseExisting'
$lock=[IO.File]::Open($p.LibraryStatePath+'.lock',[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
$failed=$false;try{[void]$e.InstallLibrary($p,$null)}catch{$failed=$true}finally{$lock.Dispose()}
Check $failed 'Concurrent library publication is rejected by the shared lock'
Check ((Get-FileHash -LiteralPath $p.LibraryStatePath).Hash -eq $stateHash) 'Contended publication retains the prior active state'
Check ($e.Plan($p,$null,$false).Contains('Plugin new bytes: 0')) 'Manage library only charges no runtime bytes'
[IO.File]::WriteAllText("$managed\Maps\shared.bin",'Owned modified content')
$failed=$false;try{[void]$e.InstallLibrary($p,$null)}catch{$failed=$true}
Check $failed 'Explicit content verification rejects modified shared bytes'
Check ([IO.File]::ReadAllText("$managed\Maps\shared.bin") -eq 'Owned modified content') 'Modified content is preserved without replacement'
$e.LibraryAction='Keep'
[void]$e.Install($p)
Check $true 'Plugin-only repair does not require hashing model and texture files'
@{status='passed';checks=$checks;artist_profile_modified=$false;scope='Inert payloads; actual NTFS file identity, shared resolution and failure transactions'} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$Output\result.json"
Write-Output ($checks.Count.ToString()+' installer checks passed')
