param([string]$CorePath,[string]$PackageDir,[string]$InventoryHash,[string]$Root,[string]$Mode)
$ErrorActionPreference='Stop'
if(-not [IO.Path]::GetFullPath($Root).StartsWith('F:\Cursor\_Cyrus_Apps\CyrusScatter\build\gallery-0851-20261016-01\installer-crash-')){throw 'Owned recovery fixture required'}
Add-Type -Path $CorePath
$taskEngine=[Cyrus.Setup.InstallEngine]::new($PackageDir,$InventoryHash)
$taskPaths=[Cyrus.Setup.InstallPaths]::new((Join-Path $Root 'scripts'),(Join-Path $Root 'startup'),(Join-Path $Root 'macros'),(Join-Path $Root 'profile'))
$taskLock=$null
$taskHook=[Action[string]] {param($value)
    if($Mode -eq 'lock' -and $value -eq 'publishing:3') {
        $script:taskLock=[IO.File]::Open((Join-Path $Root 'profile/Plugin.UserSettings.ini'),[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
    }
    if($Mode -eq 'cancel' -and $value -eq 'copied:CyrusGallery.dll'){throw [OperationCanceledException]::new('Owned cancellation')}
}
try{
    try{$taskRelease=$taskEngine.Install($taskPaths,$taskHook);$taskResult=@{status='installed';release=$taskRelease}}
    catch{$taskResult=@{status='rejected';error=$_.Exception.ToString()}}
}finally{if($taskLock){$taskLock.Dispose()}}
$taskResult | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $Root 'result.json') -Encoding utf8
