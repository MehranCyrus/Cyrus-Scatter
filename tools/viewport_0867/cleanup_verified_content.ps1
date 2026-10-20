$ErrorActionPreference='Stop'
$workspace=(Resolve-Path -LiteralPath 'F:\Cursor\_Cyrus_Apps\CyrusScatter').Path
$owned=(Resolve-Path -LiteralPath (Join-Path $workspace 'build\v867')).Path
if($owned -ne (Join-Path $workspace 'build\v867')){throw 'Unexpected owned test root'}
$manifest=Get-Content -LiteralPath (Join-Path $workspace 'dist\CyrusScatter-0.86.7-20261020\Content\content-manifest.json') -Raw | ConvertFrom-Json
if($manifest.version -ne '0.86.7'){throw 'Unexpected content version'}
$removed=0;$bytes=0
function Remove-VerifiedFile([string]$path,[string]$hash,[long]$length){
    if(-not (Test-Path -LiteralPath $path -PathType Leaf)){return}
    $resolved=(Resolve-Path -LiteralPath $path).Path
    if(-not $resolved.StartsWith($owned+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'File escaped owned test root'}
    for($at=$resolved;$at -ne $owned;$at=[IO.Path]::GetDirectoryName($at)){
        if((Get-Item -LiteralPath $at -Force).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Linked path refused'}
    }
    if((Get-Item -LiteralPath $resolved).Length -ne $length -or (Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash -ne $hash){throw "Changed test content preserved: $resolved"}
    # Only this verified file; no recursive directory removal.
    Remove-Item -LiteralPath $resolved -ErrorAction Stop
    $script:removed++;$script:bytes+=$length
}
foreach($year in @(2024,2026,2027)){
    foreach($release in Get-ChildItem -LiteralPath (Join-Path $owned "$year\r\r") -Directory){
        if($release.Name -notmatch '^[0-9a-f]{12}$'){throw 'Unexpected release directory'}
        foreach($entry in $manifest.files.PSObject.Properties){
            if(-not $entry.Name.StartsWith('Library/') -or $entry.Name.Contains('..')){throw 'Unexpected manifest entry'}
            $relative='Library-0.86.7\'+$entry.Name.Substring(8).Replace('/','\')
            Remove-VerifiedFile (Join-Path $release.FullName $relative) $entry.Value.sha256 $entry.Value.bytes
        }
        Write-Output "Removed verified content links from owned $year release $($release.Name)"
    }
}
$hashes=@{}
foreach($entry in $manifest.files.PSObject.Properties){$hashes[$entry.Value.sha256]=$entry.Value.bytes}
foreach($hash in $hashes.Keys){Remove-VerifiedFile (Join-Path $owned "c\$hash") $hash $hashes[$hash]}
$receipt=@{status='passed';owned_root=$owned;removed_verified_links=$removed;logical_bytes=$bytes;content_bytes=5851207027;recursive_delete=$false;small_runtimes_and_receipts_retained=$true}
$receipt | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $workspace 'build\viewport-0867-20261020\cleanup.json')
$receipt | ConvertTo-Json
