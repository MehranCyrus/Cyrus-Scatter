<# Local companion to CyrusPerformanceMonitor.ms. Never sends commands to Max. #>
param([Parameter(Mandatory = $true)][string]$SessionDir)
$ErrorActionPreference = 'Stop'
$taskDir = [IO.Path]::GetFullPath($SessionDir)
$taskUtf8 = New-Object Text.UTF8Encoding($false)
$taskWriter = $null
$taskSamples = 0
$taskPeakPrivate = 0L
$taskPeakWorking = 0L
$taskStatus = 'initializing'
$taskError = $null
function Write-TaskJson($Name, $Value) {
    [IO.File]::WriteAllText((Join-Path $taskDir $Name), ($Value | ConvertTo-Json -Depth 12), $taskUtf8)
}
function Get-TaskFingerprint([string]$FilePath, [string]$Role) {
    if (-not $FilePath -or -not [IO.File]::Exists($FilePath)) { return $null }
    $taskFile = Get-Item -LiteralPath $FilePath
    $taskHash = [Security.Cryptography.SHA256]::Create()
    $taskStream = [IO.File]::OpenRead($taskFile.FullName)
    try { $taskDigest = [BitConverter]::ToString($taskHash.ComputeHash($taskStream)).Replace('-', '').ToLowerInvariant() }
    finally { $taskStream.Dispose(); $taskHash.Dispose() }
    [ordered]@{
        role = $Role; path = $taskFile.FullName; bytes = $taskFile.Length
        sha256 = $taskDigest
        version = $taskFile.VersionInfo.FileVersion
    }
}
try {
    $taskManifest = Get-Content -LiteralPath (Join-Path $taskDir 'manifest.json') -Raw | ConvertFrom-Json
    $taskProcess = [Diagnostics.Process]::GetProcessById([int]$taskManifest.pid)
    if ($taskProcess.StartTime.ToUniversalTime().ToString('o') -ne $taskManifest.process_start_utc) {
        throw 'The Max process identity changed. Start a new recording.'
    }
    $taskFiles = @()
    foreach ($taskModule in $taskProcess.Modules) {
        if ($taskModule.ModuleName -match '^(AminScatter|CyrusScatterEdit|CyrusSurfaceAnalyzer|Corona).*\.(dlx|dlm|dll|dlu)$') {
            $taskFiles += Get-TaskFingerprint $taskModule.FileName 'loaded_module_file_on_disk'
        }
    }
    foreach ($taskScript in $taskManifest.script_candidates) {
        $taskFiles += Get-TaskFingerprint $taskScript 'script_candidate_on_disk_not_proof_of_loaded_script'
    }
    $taskFiles += Get-TaskFingerprint $taskManifest.tool_path 'measurement_tool'
    if ($taskManifest.trace_tool_path) { $taskFiles += Get-TaskFingerprint $taskManifest.trace_tool_path 'measurement_tool' }
    $taskFiles += Get-TaskFingerprint $PSCommandPath 'resource_sampler'
    $taskScene = Get-TaskFingerprint $taskManifest.scene_path 'saved_scene_not_unsaved_memory'
    # Max may inherit a PowerShell 7 PSModulePath; load the Windows PowerShell module explicitly.
    Import-Module (Join-Path $PSHOME 'Modules/CimCmdlets/CimCmdlets.psd1') -ErrorAction Stop
    $taskCpu = @(Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors)
    $taskComputer = Get-CimInstance Win32_ComputerSystem
    $taskOS = Get-CimInstance Win32_OperatingSystem
    $taskGpus = @(Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion)
    $taskLogical = [Environment]::ProcessorCount
    $taskPower = (& "$env:SystemRoot\System32\powercfg.exe" /GETACTIVESCHEME 2>$null | Out-String).Trim()
    Write-TaskJson 'host.json' ([ordered]@{
        schema_version = 1; machine = $env:COMPUTERNAME; cpu = $taskCpu; gpu = $taskGpus
        logical_processors = $taskLogical; physical_ram_bytes = [long]$taskComputer.TotalPhysicalMemory
        os = $taskOS.Caption; os_version = $taskOS.Version; power_scheme = $taskPower
        scene = $taskScene; files = @($taskFiles | Where-Object { $null -ne $_ })
        gpu_utilization = $null; interval_ms = 500
        limitations = @('File hashes describe files on disk, not in-memory script provenance.',
            'Memory and CPU include all work in this Max process.',
            'Sampled memory peaks can miss shorter allocation spikes; CPU is normalized across logical processors.')
    })
    $taskWriter = New-Object IO.StreamWriter((Join-Path $taskDir 'resources.csv'), $false, $taskUtf8)
    $taskWriter.AutoFlush = $true
    $taskWriter.WriteLine('utc,elapsed_s,cpu_percent_total_capacity,private_bytes,working_set_bytes')
    $taskClock = [Diagnostics.Stopwatch]::StartNew()
    $taskLastCpu = $taskProcess.TotalProcessorTime.TotalSeconds
    $taskLastTime = $taskClock.Elapsed.TotalSeconds
    [IO.File]::WriteAllText((Join-Path $taskDir 'sampler.ready'), 'Ready', $taskUtf8)
    $taskStatus = 'recording'
    while ($taskClock.Elapsed.TotalSeconds -lt 3600 -and -not [IO.File]::Exists((Join-Path $taskDir 'stop.request'))) {
        $taskProcess.Refresh()
        if ($taskProcess.HasExited) { $taskStatus = 'max_exited'; break }
        $taskNow = $taskClock.Elapsed.TotalSeconds
        $taskCpuNow = $taskProcess.TotalProcessorTime.TotalSeconds
        $taskCpuPercent = ''
        if ($taskNow - $taskLastTime -ge 0.1) {
            $taskCpuPercent = ([Math]::Max(0, 100 * ($taskCpuNow - $taskLastCpu) / ($taskNow - $taskLastTime) / $taskLogical)).ToString('F3', [Globalization.CultureInfo]::InvariantCulture)
        }
        $taskPrivate = $taskProcess.PrivateMemorySize64
        $taskWorking = $taskProcess.WorkingSet64
        $taskPeakPrivate = [Math]::Max($taskPeakPrivate, $taskPrivate)
        $taskPeakWorking = [Math]::Max($taskPeakWorking, $taskWorking)
        $taskWriter.WriteLine(('{0},{1},{2},{3},{4}' -f [DateTime]::UtcNow.ToString('o'),
            $taskNow.ToString('F6', [Globalization.CultureInfo]::InvariantCulture), $taskCpuPercent, $taskPrivate, $taskWorking))
        $taskLive = 'CPU {0}% | Private {1:N2} GiB | Working set {2:N2} GiB (sample {3})' -f $taskCpuPercent, ($taskPrivate / 1GB), ($taskWorking / 1GB), [DateTime]::UtcNow.ToString('HH:mm:ss UTC')
        [IO.File]::WriteAllText((Join-Path $taskDir 'live.txt'), $taskLive, $taskUtf8)
        $taskSamples++
        $taskLastCpu = $taskCpuNow; $taskLastTime = $taskNow
        Start-Sleep -Milliseconds 500
    }
    if ($taskStatus -eq 'recording') {
        if ([IO.File]::Exists((Join-Path $taskDir 'stop.request'))) { $taskStatus = 'stopped' }
        else { $taskStatus = 'time_limit' }
    }
} catch {
    $taskStatus = 'failed'; $taskError = $_.Exception.Message
    [IO.File]::WriteAllText((Join-Path $taskDir 'sampler-error.txt'), $taskError, $taskUtf8)
} finally {
    if ($null -ne $taskWriter) { $taskWriter.Dispose() }
    Write-TaskJson 'sampler-summary.json' ([ordered]@{
        status = $taskStatus; error = $taskError; samples = $taskSamples
        sampled_peak_private_bytes = $taskPeakPrivate; sampled_peak_working_set_bytes = $taskPeakWorking
    })
}
