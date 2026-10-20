param([string]$Workspace='F:\Cursor\_Cyrus_Apps\CyrusScatter')
$ErrorActionPreference='Stop'
$out=Join-Path $Workspace 'build\update-08671-20261020\real-managed'
$root=Join-Path $Workspace 'build\u8671-content'
if(Test-Path -LiteralPath "$out\result.json"){throw 'Existing managed-content receipt'}
[void][IO.Directory]::CreateDirectory($out)
$dist=Join-Path $Workspace 'dist\CyrusScatter-0.86.7.1-20261020'
$content=Join-Path $Workspace 'dist\CyrusScatter-0.86.7-20261020\Content'
$assembly=[Reflection.Assembly]::LoadFrom("$dist\CyrusScatter-0.86.7.1-Setup.exe")
$receipt=Get-Content -LiteralPath "$dist\CyrusScatter-0.86.7.1-Setup.build.json" -Raw | ConvertFrom-Json
$package=$receipt.packages | Where-Object {$_.year -eq '2027'}
$payload=[Cyrus.Setup.Distribution]::Extract($assembly,"$out\extracted",$package.package_sha256,$null,$package.resource)
$engine=[Cyrus.Setup.InstallEngine]::new($payload,[Cyrus.Setup.InstallEngine]::Hash([IO.File]::ReadAllBytes("$payload\InstallInventory.txt")))
$paths=[Cyrus.Setup.InstallPaths]::new("$out\s","$out\st","$out\m","$out\p","$out\r")
$paths.LibraryStatePath="$out\library-state.txt"
$engine.LibraryAction='Install';$engine.LibraryDestination=$root;$engine.SetContentDirectory($content)
[IO.File]::WriteAllText("$out\plan.txt",$engine.Plan($paths,$null,$false))
$installed=$engine.InstallLibrary($paths,$null)
$sample='Models\Leaves\A027 - Bent Leaf - 01\model.max'
$oldId=(& fsutil.exe file queryfileid "$content\Library\$sample" | Out-String).Trim()
$newId=(& fsutil.exe file queryfileid "$installed\$sample" | Out-String).Trim()
if($oldId -ne $newId){throw 'Real model was duplicated instead of reused'}
$catalogHash=[Cyrus.Content.LibraryLocation]::Hash("$installed\model-catalog.json")
if($catalogHash -ne [Cyrus.Content.LibraryLocation]::Hash("$content\Library\model-catalog.json")){throw 'Catalog bytes changed'}
@{status='passed';root=$installed;catalog_sha256=$catalogHash;file_id=$newId;source_id=$oldId;scope='Complete real library installed as verified hard links on the same volume; source files retained';artist_profile_modified=$false} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath "$out\result.json"
[Cyrus.Setup.Distribution]::Cleanup("$out\extracted",$payload)
Write-Output $installed
