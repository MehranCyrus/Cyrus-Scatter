param(
    [string]$PythonExe = 'python',
    [string]$InstallRoot = (Join-Path $env:USERPROFILE '.cyrus-scatter\mcp'),
    [switch]$RegisterCodex
)
$ErrorActionPreference = 'Stop'
$packageRoot = $PSScriptRoot
$manifestPath = Join-Path $packageRoot 'package-manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath)) { throw 'Run this installer from the built Cyrus MCP package.' }
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.build_id -notmatch '^\d+\.\d+\.\d+-[0-9a-f]{12}$') { throw 'Invalid package build identity.' }
foreach ($entry in $manifest.files) {
    $file = Join-Path $packageRoot $entry.path
    $resolved = [IO.Path]::GetFullPath($file)
    $expectedRoot = [IO.Path]::GetFullPath($packageRoot) + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($expectedRoot,[StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid package path.' }
    if ((Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.sha256) { throw "Package checksum mismatch: $($entry.path)" }
}
& $PythonExe -c 'import sys,struct; assert sys.version_info[:2]==(3,11) and struct.calcsize("P")==8, "Use 64-bit Python 3.11 for this package"'
if ($LASTEXITCODE -ne 0) { throw 'A 64-bit Python 3.11 runtime is required.' }
$destination = Join-Path $InstallRoot $manifest.build_id
if (Test-Path -LiteralPath $destination) { throw "This build already exists at $destination. Reuse its Start_Cyrus_Automation.ms and environment; no files were overwritten." }
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $packageRoot 'host') -Destination (Join-Path $destination 'host') -Recurse
& $PythonExe -m venv (Join-Path $destination 'venv')
if ($LASTEXITCODE -ne 0) { throw 'Could not create the isolated MCP environment.' }
$clientPython = Join-Path $destination 'venv\Scripts\python.exe'
& $clientPython -m pip install --no-index --find-links (Join-Path $packageRoot 'wheels') --require-hashes -r (Join-Path $packageRoot 'requirements-windows-py311.lock')
if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed. Codex was not changed.' }
& $clientPython -m pip check
if ($LASTEXITCODE -ne 0) { throw 'Dependency verification failed.' }
& $clientPython -c 'from cyrus_mcp.server import make_server; make_server(); print("Cyrus MCP server import verified")'
if ($LASTEXITCODE -ne 0) { throw 'Server verification failed.' }
if ($RegisterCodex) {
    $existing = codex mcp list --json | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { throw 'Could not inspect Codex MCP configuration.' }
    if ($existing | Where-Object { $_.name -eq 'cyrus-scatter' }) { throw 'A cyrus-scatter connection already exists. The package is installed; inspect that connection before changing it.' }
    & codex mcp add cyrus-scatter -- $clientPython -m cyrus_mcp.server
    if ($LASTEXITCODE -ne 0) { throw 'Codex registration failed; the verified package remains installed.' }
}
$installed = [pscustomobject]@{ build_id=$manifest.build_id; python=$clientPython; max_script=(Join-Path $destination 'host\Start_Cyrus_Automation.ms'); codex_registered=[bool]$RegisterCodex }
$installed | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $destination 'installed.json') -Encoding UTF8
$installed | Format-List
