param([string]$Workspace='F:\Cursor\_Cyrus_Apps\CyrusScatter',[ValidatePattern('^real-installer(-[a-z0-9]+)?$')][string]$RunName='real-installer')
$ErrorActionPreference='Stop'
$out=Join-Path $Workspace ('build\update-08671-20261020\'+$RunName)
if(Test-Path -LiteralPath "$out\result.json"){throw 'Existing receipt; use a fresh campaign'}
[void][IO.Directory]::CreateDirectory($out)
$dist=Join-Path $Workspace 'dist\CyrusScatter-0.86.7.1-20261020'
$content=Join-Path $Workspace 'dist\CyrusScatter-0.86.7-20261020\Content'
$assembly=[Reflection.Assembly]::LoadFrom("$dist\CyrusScatter-0.86.7.1-Setup.exe")
$receipt=Get-Content -LiteralPath "$dist\CyrusScatter-0.86.7.1-Setup.build.json" -Raw | ConvertFrom-Json
$checks=[Collections.Generic.List[string]]::new()
$releases=@{}
function Check([bool]$condition,[string]$label){if(-not $condition){throw $label};$checks.Add($label)}
function Hash([string]$path){return [Cyrus.Content.LibraryLocation]::Hash($path)}
$manifestBefore=Hash "$content\content-manifest.json"
foreach($year in @(2024,2026,2027)){
    $package=$receipt.packages | Where-Object {$_.year -eq "$year"}
    $payload=[Cyrus.Setup.Distribution]::Extract($assembly,"$out\extracted",$package.package_sha256,$null,$package.resource)
    $inventory=[IO.File]::ReadAllBytes("$payload\InstallInventory.txt")
    $engine=[Cyrus.Setup.InstallEngine]::new($payload,[Cyrus.Setup.InstallEngine]::Hash($inventory))
    $base="$out\$year"
    $paths=[Cyrus.Setup.InstallPaths]::new("$base\s","$base\st","$base\m","$base\p","$base\r")
    $paths.LibraryStatePath="$out\shared\library-state.txt";$paths.SharedContentRoot="$out\shared"
    [void][IO.Directory]::CreateDirectory($paths.Profile)
    if($year -eq 2024){$engine.SetContentDirectory($content);$engine.LibraryAction='UseExisting'}
    $plan=$engine.Plan($paths)
    [IO.File]::WriteAllText("$out\plan-$year.txt",$plan)
    $release=$engine.Install($paths)
    Check ($engine.Year -eq "$year" -and $engine.Version -eq '0.86.7.1') "Exact host/version $year"
    Check ((Hash "$release\bin\AminScatter.dlx") -eq (Hash "$payload\AminScatter.dlx")) "Installed native identity $year"
    Check ((Hash "$release\CyrusScatter.ms") -eq (Hash "$payload\CyrusScatter.ms")) "Installed script identity $year"
    Check ([Cyrus.Content.LibraryLocation]::ResolveRoot($release,$year) -eq "$content\Library") "Shared existing library resolves for $year"
    Check (-not (Test-Path -LiteralPath "$release\Library-0.86.7.1")) "No per-host model copy for $year"
    $engine.LibraryAction='Keep'
    Check ($engine.Install($paths) -eq $release) "Plugin-only repair $year"
    $releases["$year"]=$release
    [Cyrus.Setup.Distribution]::Cleanup("$out\extracted",$payload)
}
Check ((Hash "$content\content-manifest.json") -eq $manifestBefore) 'Original content manifest is unchanged'
# A real small runtime on C: can use the same verified content on F:.
$cOwned=Join-Path ([IO.Path]::GetTempPath()) ('Cyrus08671Real-'+[Guid]::NewGuid().ToString('N'))
$package=$receipt.packages | Where-Object {$_.year -eq '2027'}
$payload=[Cyrus.Setup.Distribution]::Extract($assembly,"$out\extracted",$package.package_sha256,$null,$package.resource)
$engine=[Cyrus.Setup.InstallEngine]::new($payload,[Cyrus.Setup.InstallEngine]::Hash([IO.File]::ReadAllBytes("$payload\InstallInventory.txt")))
$paths=[Cyrus.Setup.InstallPaths]::new("$cOwned\s","$cOwned\st","$cOwned\m","$cOwned\p","$cOwned\r")
$paths.LibraryStatePath="$out\shared\library-state.txt"
$release=$engine.Install($paths)
Check ([Cyrus.Content.LibraryLocation]::ResolveRoot($release,2027) -eq "$content\Library") 'Actual C: runtime / F: library works'
[Cyrus.Setup.Distribution]::Cleanup("$out\extracted",$payload)
@{status='passed';releases=$releases;checks=$checks;content_root="$content\Library";content_manifest_sha256=$manifestBefore;cross_volume_runtime=$release;artist_profile_modified=$false} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$out\result.json"
Write-Output "$($checks.Count) real installer checks passed"
