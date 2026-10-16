param([string]$CorePath,[string]$PackageDir,[string]$InventoryHash,[string]$Root,[string]$Phase)
$ErrorActionPreference='Stop'
if(-not [IO.Path]::GetFullPath($Root).StartsWith('F:\Cursor\_Cyrus_Apps\CyrusScatter\build\gallery-0851-20261016-01\installer-crash-')){throw 'Owned crash fixture required'}
Add-Type -Path $CorePath
$taskEngine=[Cyrus.Setup.InstallEngine]::new($PackageDir,$InventoryHash)
$taskPaths=[Cyrus.Setup.InstallPaths]::new((Join-Path $Root 'scripts'),(Join-Path $Root 'startup'),(Join-Path $Root 'macros'),(Join-Path $Root 'profile'))
$taskHook=[Action[string]] {param($value) if($value -eq $Phase){[Environment]::Exit(86)}}
$null=$taskEngine.Install($taskPaths,$taskHook)
