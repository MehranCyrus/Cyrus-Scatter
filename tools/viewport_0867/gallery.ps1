param([Parameter(Mandatory=$true)][string]$Assembly,[Parameter(Mandatory=$true)][string]$Catalog,[string]$Version="0.86.6.2")
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[void][Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $Assembly).Path)
$catalogObject=New-Object CyrusScatter.UI.IndividualModelCatalog
if($catalogObject.GetType().GetMethod('Load').GetParameters().Count -eq 3){$catalogObject.Load($Catalog,$Version,2027)}else{$catalogObject.Load($Catalog,$Version)}
$gallery=New-Object CyrusScatter.UI.LibraryGallery
$gallery.Size=New-Object Drawing.Size(800,500)
$gallery.TileSize=176
$handle=$gallery.Handle
function Wait-Gallery {
    $deadline=[DateTime]::UtcNow.AddSeconds(15)
    do {
        [Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 10
        if([DateTime]::UtcNow -gt $deadline){throw "Gallery completion timed out"}
    } while($gallery.PendingJobs -gt 0)
}
try {
    $gallery.BeginPage()
    for($i=0;$i -lt $catalogObject.Count;$i++){
        $entry=$catalogObject.MatchingAt('','',$i)
        $gallery.AddItem($entry.Id,$entry.Name,$entry.Category,$entry.Thumbnail,$entry.ThumbnailHash,$entry.ThumbnailBytes)
    }
    $gallery.EndPage(0)
    Wait-Gallery
    $before=$gallery.JobsStarted
    $wheel=$gallery.GetType().GetMethod('OnMouseWheel',[Reflection.BindingFlags]'Instance,NonPublic')
    $argsDown=[object[]]@([Windows.Forms.MouseEventArgs]::new([Windows.Forms.MouseButtons]::None,0,50,50,-600))
    $wheel.Invoke($gallery,$argsDown) | Out-Null
    Wait-Gallery
    $after=$gallery.JobsStarted
    if($gallery.AutoScrollPosition.Y -ge 0){throw 'Wheel did not move the viewport'}
    if($after -le $before){throw "THUMBNAIL STALL: wheel moved to $($gallery.AutoScrollPosition.Y), jobs stayed $before"}
    # Revisit the same admitted thumbnails without another decode.
    $argsUp=[object[]]@([Windows.Forms.MouseEventArgs]::new([Windows.Forms.MouseButtons]::None,0,50,50,600))
    $wheel.Invoke($gallery,$argsUp) | Out-Null
    Wait-Gallery
    if($gallery.JobsStarted -ne $after){throw 'Warm revisit unexpectedly decoded again'}
    $gallery.Size=New-Object Drawing.Size(1100,700)
    Wait-Gallery
    $gallery.BeginPage()
    $entry=$catalogObject.MatchingAt('','Leaves',0)
    $gallery.AddItem($entry.Id,$entry.Name,$entry.Category,$entry.Thumbnail,$entry.ThumbnailHash,$entry.ThumbnailBytes)
    $gallery.EndPage(0)
    Wait-Gallery
    if($gallery.ItemCount -ne 1){throw 'Category replacement failed'}
    [pscustomobject]@{status='passed';initial_jobs=$before;after_wheel_jobs=$after;decoded=$gallery.ImagesDecoded;bytes=$gallery.DecodedBytes;checks='wheel after idle, no clicks, warm revisit, resize, generation replacement'} | ConvertTo-Json
}finally{$gallery.Dispose()}
