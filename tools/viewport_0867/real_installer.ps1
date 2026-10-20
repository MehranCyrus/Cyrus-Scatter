param([string]$Workspace='F:\Cursor\_Cyrus_Apps\CyrusScatter',[ValidatePattern('^result(-[a-z0-9]+)?\.json$')][string]$ResultName='result.json')
$ErrorActionPreference='Stop'
$out=Join-Path $Workspace 'build\v867'
if(Test-Path -LiteralPath "$out\$ResultName"){throw 'Existing acceptance receipt; choose a fresh run'}
$dist=Join-Path $Workspace 'dist\CyrusScatter-0.86.7-20261020'
$assembly=[Reflection.Assembly]::LoadFrom("$dist\CyrusScatter-0.86.7-Setup.exe")
$receipt=Get-Content -LiteralPath "$dist\CyrusScatter-0.86.7-Setup.build.json" -Raw | ConvertFrom-Json
$checks=[Collections.Generic.List[string]]::new()
$releases=@{}
function Check([bool]$condition,[string]$label){if(-not $condition){throw $label};$checks.Add($label)}
foreach($year in @(2024,2026,2027)){
    $package=$receipt.packages | Where-Object {$_.year -eq "$year"}
    $payload=[Cyrus.Setup.Distribution]::Extract($assembly,"$out\extracted",$package.package_sha256,$null,$package.resource)
    $inventory=[IO.File]::ReadAllBytes("$payload\InstallInventory.txt")
    $engine=[Cyrus.Setup.InstallEngine]::new($payload,[Cyrus.Setup.InstallEngine]::Hash($inventory))
    # Exercise parent, Content and Library selections against the real payload.
    $selection=switch($year){2024{$dist}2026{"$dist\Content\Library"}2027{"$dist\Content"}}
    $engine.SetContentDirectory($selection)
    $base="$out\$year"
    $paths=[Cyrus.Setup.InstallPaths]::new("$base\s","$base\st","$base\m","$base\p","$base\r")
    $paths.SharedContentRoot="$out\c"
    [void][IO.Directory]::CreateDirectory($paths.Profile)
    $release=$engine.Install($paths)
    Check ($engine.Year -eq "$year" -and $engine.Version -eq '0.86.7') "Host/version $year"
    Check ((Get-FileHash -LiteralPath "$release\bin\AminScatter.dlx").Hash -eq (Get-FileHash -LiteralPath "$payload\AminScatter.dlx").Hash) "Installed native identity $year"
    Check ((Get-FileHash -LiteralPath "$release\CyrusScatter.ms").Hash -eq (Get-FileHash -LiteralPath "$payload\CyrusScatter.ms").Hash) "Installed script identity $year"
    Check ($engine.Install($paths) -eq $release) "Repair real content $year"
    $releases["$year"]=$release
}
$sample='Models\Leaves\A027 - Bent Leaf - 01\model.max'
$ids=@(foreach($year in @(2024,2026,2027)){(& fsutil.exe file queryfileid "$($releases["$year"])\Library-0.86.7\$sample" | Out-String).Trim()})
Check (($ids|Select-Object -Unique).Count -eq 1) 'All hosts share the physical model content'
@{status='passed';releases=$releases;checks=$checks;file_ids=$ids;artist_profile_modified=$false} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$out\$ResultName"
Write-Output "$($checks.Count) real installer checks passed"
