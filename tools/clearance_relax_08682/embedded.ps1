$ErrorActionPreference='Stop'
$root='F:\Cursor\_Cyrus_Apps\CyrusScatter'
$out="$root\dist\CyrusScatter-0.86.8.2-20261021"
$assembly=[Reflection.Assembly]::LoadFile("$out\CyrusScatter-0.86.8.2-Setup.exe")
$rows=@()
foreach($year in @(2024,2026,2027)) {
 $stream=$assembly.GetManifestResourceStream("Cyrus.Payload.$year.mzp")
 if($null -eq $stream){throw "Missing host resource $year"}
 $hash=[Security.Cryptography.SHA256]::Create()
 try{$actual=([BitConverter]::ToString($hash.ComputeHash($stream))).Replace('-','').ToLowerInvariant()}
 finally{$hash.Dispose();$stream.Dispose()}
 $expected=(Get-FileHash -LiteralPath "$out\CyrusScatter-0.86.8.2-Max$year.mzp" -Algorithm SHA256).Hash.ToLowerInvariant()
 if($actual -ne $expected){throw "Embedded package mismatch $year"}
 $rows+=@{year=$year;sha256=$actual;matches=$true}
}
$rows | ConvertTo-Json | Set-Content -LiteralPath "$root\build\clearance-relax-08682-20261021\embedded-payloads.json"
Write-Output 'PASS: all three embedded MZPs match their delivered archives'
