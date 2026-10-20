param([string]$Output)
$ErrorActionPreference='Stop'
$workspace='F:\Cursor\_Cyrus_Apps\CyrusScatter'
if(-not [IO.Path]::GetFullPath($Output).StartsWith("$workspace\build\viewport-0867-20261020\installer-")){throw 'Owned fixture required'}
Add-Type -Path "$workspace\build\viewport-0867-20261020\CyrusInstaller.dll"
$packages=Get-Content -LiteralPath "$Output\packages.json" -Raw | ConvertFrom-Json
$checks=[Collections.Generic.List[string]]::new()
function Check([bool]$value,[string]$message){if(-not $value){throw $message};$checks.Add($message)}
function Paths([string]$name){
    $base=Join-Path $Output $name
    $p=[Cyrus.Setup.InstallPaths]::new("$base\scripts","$base\startup","$base\macros","$base\profile","$base\runtime")
    $p.SharedContentRoot="$Output\shared"
    [void][IO.Directory]::CreateDirectory($p.Profile)
    return $p
}
function Engine($package,[string]$selection){
    $e=[Cyrus.Setup.InstallEngine]::new($package.path,$package.hash)
    $e.SetContentDirectory($selection)
    return $e
}
function FileId([string]$path){return (& fsutil.exe file queryfileid $path | Out-String).Trim()}
$paths=Paths 'Max2027 profile'
$oldEngine=Engine $packages[0] ($packages[0].path+'\Content')
$old=$oldEngine.Install($paths)
$oldFile="$old\Library-0.86.6.2\Maps\reused.bin"
$oldId=FileId $oldFile
# Remove only owned store links. The installed file remains, simulating a
# pre-store installation; its bytes must be reused during upgrade.
Get-ChildItem -LiteralPath "$Output\shared" -File | ForEach-Object {Remove-Item -LiteralPath $_.FullName}
$newEngine=Engine $packages[1] ($packages[1].path+'\Content\Library')
$new=$newEngine.Install($paths)
$newFile="$new\Library-0.86.7\Maps\reused.bin"
Check ((FileId $newFile) -eq $oldId) 'Upgrade reuses the old physical content file'
Check (Test-Path -LiteralPath $oldFile) 'Previous release remains usable by an open host'
foreach($index in @(2,3)){
    $other=Paths ('Max'+$packages[$index].year)
    $e=Engine $packages[$index] $packages[$index].path
    $release=$e.Install($other)
    Check ((FileId "$release\Library-0.86.7\Maps\reused.bin") -eq $oldId) ('Max '+$packages[$index].year+' shares content bytes')
    Check ([IO.File]::ReadAllText($other.Profile+'\Plugin.UserSettings.ini').Contains('CyrusScatter'+$packages[$index].year+'=')) 'Matching host registration'
}
$prior=[IO.File]::ReadAllText($paths.Scripts+'\CyrusScatter\installed.txt')
Check ($newEngine.Install($paths) -eq $new) 'Repair reuses the same release'
Remove-Item -LiteralPath $newFile
[void]$newEngine.Install($paths)
Check ((FileId $newFile) -eq $oldId) 'Missing content repair restores a hard link'
foreach($phase in @('copied:Library/Maps/reused.bin','journal','publishing:1','publishing:3')){
    $failurePaths=Paths ('failure-'+$phase.Replace(':','-').Replace('/','-'))
    $checkpoint=[Action[string]]{param($value)if($value -eq $phase){throw 'Injected owned failure'}}
    $failed=$false
    try{[void]$newEngine.Install($failurePaths,$checkpoint)}catch{$failed=$true}
    Check $failed ('Failure injected at '+$phase)
    Check (-not (Test-Path -LiteralPath ($failurePaths.Scripts+'\CyrusScatter\installed.txt'))) 'Failed install publishes no active release'
    [void]$newEngine.Install($failurePaths)
}
Check ([IO.File]::ReadAllText($paths.Scripts+'\CyrusScatter\installed.txt') -eq $prior) 'Other host failures preserve the active registration'
# A modified shared file must be rejected, never silently overwritten.
[IO.File]::WriteAllText($newFile,'Owned modification')
$failed=$false;try{[void]$newEngine.Install($paths)}catch{$failed=$true}
Check $failed 'Modified content is rejected and preserved'
Check ([IO.File]::ReadAllText($newFile) -eq 'Owned modification') 'Modified content bytes retained'
@{status='passed';checks=$checks;artist_profile_modified=$false;scope='Inert filesystem payloads and actual NTFS file identity'} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath "$Output\result.json"
Write-Output ($checks.Count.ToString()+' content/installer checks passed')
