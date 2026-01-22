# ==============================================================================
# TITAN ARC | PERFORMANCE OPTIMIZER MODULE V2.0
# ==============================================================================
# Advanced Performance Monitoring and Optimization
# Author: Knoux | Abu Retaj — KNOUX VISIO™
# ==============================================================================

function Optimize-TitanPerformance {
    param(
        [int]$MaxMemoryMB = 2048,
        [int]$MaxCpuPercent = 80,
        [switch]$Aggressive,
        [switch]$Monitor
    )
    
    $PerformanceConfig = @{
        MaxMemory = $MaxMemoryMB * 1024 * 1024  # Convert to bytes
        MaxCpu = $MaxCpuPercent
        AggressiveMode = $Aggressive
        Monitoring = $Monitor
    }
    
    # Initialize performance monitoring
    if ($Monitor) {
        Start-PerformanceMonitoring $PerformanceConfig
    }
    
    # Apply optimizations
    Apply-MemoryOptimizations $PerformanceConfig
    Apply-CpuOptimizations $PerformanceConfig
    Apply-IOOptimizations $PerformanceConfig
    
    return $PerformanceConfig
}

function Start-PerformanceMonitoring {
    param($Config)
    
    $Script:PerformanceMonitor = {
        $Counter = 0
        
        while ($true) {
            $Memory = Get-Process -Id $PID | Select-Object WorkingSet, CPU
            $MemoryMB = [math]::Round($Memory.WorkingSet / 1MB, 2)
            $CpuPercent = [math]::Round((Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue, 2)
            
            Write-Host "[PERF] Memory: ${MemoryMB}MB | CPU: ${CpuPercent}%" -ForegroundColor Cyan
            
            # Auto-optimization if thresholds exceeded
            if ($MemoryMB -gt ($Config.MaxMemory / 1MB)) {
                Write-Host "[PERF] Memory threshold exceeded, triggering cleanup..." -ForegroundColor Yellow
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
                [System.GC]::Collect()
            }
            
            if ($CpuPercent -gt $Config.MaxCpu) {
                Write-Host "[PERF] CPU threshold exceeded, applying throttling..." -ForegroundColor Yellow
                Start-Sleep -Milliseconds 100
            }
            
            Start-Sleep -Seconds 5
            $Counter++
            
            if ($Counter -gt 60) { break }  # Monitor for 5 minutes max
        }
    }
    
    Start-Job -ScriptBlock $Script:PerformanceMonitor | Out-Null
}

function Apply-MemoryOptimizations {
    param($Config)
    
    Write-Host "[PERF] Applying memory optimizations..." -ForegroundColor Green
    
    # Force garbage collection
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
    
    # Set memory limits if aggressive mode
    if ($Config.AggressiveMode) {
        $CurrentProcess = Get-Process -Id $PID
        $CurrentProcess.MaxWorkingSet = $Config.MaxMemory
        Write-Host "[PERF] Memory limit set to $($Config.MaxMemory / 1MB)MB" -ForegroundColor Green
    }
    
    # Optimize PowerShell memory
    $PSVersionTable.PSVersion.Major
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        $ProgressPreference = "SilentlyContinue"
        $ErrorActionPreference = "Continue"
    }
}

function Apply-CpuOptimizations {
    param($Config)
    
    Write-Host "[PERF] Applying CPU optimizations..." -ForegroundColor Green
    
    # Set process priority
    $CurrentProcess = Get-Process -Id $PID
    if ($Config.AggressiveMode) {
        $CurrentProcess.PriorityClass = "BelowNormal"
        Write-Host "[PERF] Process priority set to BelowNormal" -ForegroundColor Green
    } else {
        $CurrentProcess.PriorityClass = "Normal"
    }
    
    # Optimize thread usage
    if ($PSVersionTable.PSVersion.Major -ge 5) {
        $env:POWERSHELL_UPDATECHECK = "Off"
    }
}

function Apply-IOOptimizations {
    param($Config)
    
    Write-Host "[PERF] Applying I/O optimizations..." -ForegroundColor Green
    
    # Optimize file operations
    $env:POWERSHELL_TELEMETRY_OPTOUT = "1"
    
    # Set buffer sizes
    $Script:FileBufferSize = if ($Config.AggressiveMode) { 8192 } else { 4096 }
    
    # Disable unnecessary features
    $ProgressPreference = "SilentlyContinue"
    $ConfirmPreference = "None"
}

function Get-PerformanceMetrics {
    $Process = Get-Process -Id $PID
    $MemoryMB = [math]::Round($Process.WorkingSet / 1MB, 2)
    $CpuTime = $Process.CPU
    $Threads = $Process.Threads.Count
    $Handles = $Process.HandleCount
    
    $SystemInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $TotalMemoryMB = [math]::Round($SystemInfo.TotalVisibleMemorySize / 1KB, 2)
    $FreeMemoryMB = [math]::Round($SystemInfo.FreePhysicalMemory / 1KB, 2)
    
    return @{
        ProcessMemoryMB = $MemoryMB
        SystemTotalMemoryMB = $TotalMemoryMB
        SystemFreeMemoryMB = $FreeMemoryMB
        MemoryUsagePercent = [math]::Round(($MemoryMB / $TotalMemoryMB) * 100, 2)
        CpuTimeSeconds = $CpuTime
        ThreadCount = $Threads
        HandleCount = $Handles
        Timestamp = Get-Date
    }
}

function Optimize-FileProcessing {
    param(
        [array]$Files,
        [int]$BatchSize = 100,
        [switch]$Parallel
    )
    
    if ($Parallel -and $Files.Count -gt $BatchSize) {
        Write-Host "[PERF] Using parallel processing for $($Files.Count) files" -ForegroundColor Green
        
        # Split into batches
        $Batches = for ($i = 0; $i -lt $Files.Count; $i += $BatchSize) {
            ,($Files[$i..[Math]::Min($i + $BatchSize - 1, $Files.Count - 1)])
        }
        
        # Process batches in parallel (limited to avoid system overload)
        $MaxParallelJobs = [Math]::Min(4, $Batches.Count)
        $Jobs = @()
        
        foreach ($Batch in $Batches) {
            while ($Jobs.Count -ge $MaxParallelJobs) {
                $Jobs = $Jobs | Where-Object { $_.State -eq 'Running' }
                Start-Sleep -Milliseconds 100
            }
            
            $Job = Start-Job -ScriptBlock {
                param($BatchFiles, $BufferSize)
                # Process batch here
                $BatchFiles | ForEach-Object {
                    # Simulate processing
                    Start-Sleep -Milliseconds 10
                }
                return $BatchFiles.Count
            } -ArgumentList $Batch, $Script:FileBufferSize
            
            $Jobs += $Job
        }
        
        # Wait for all jobs
        $Jobs | Wait-Job | Out-Null
        $Results = $Jobs | Receive-Job
        $Jobs | Remove-Job
        
        Write-Host "[PERF] Parallel processing completed: $($Results.Count) batches" -ForegroundColor Green
        return $Results | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    } else {
        Write-Host "[PERF] Using sequential processing" -ForegroundColor Green
        return $Files.Count
    }
}

function Optimize-CacheUsage {
    param($CacheFile, $MaxCacheSizeMB = 100)
    
    Write-Host "[PERF] Optimizing cache usage..." -ForegroundColor Green
    
    if (Test-Path $CacheFile) {
        $CacheSize = (Get-Item $CacheFile).Length / 1MB
        
        if ($CacheSize -gt $MaxCacheSizeMB) {
            Write-Host "[PERF] Cache size ($([math]::Round($CacheSize, 2))MB) exceeds limit, cleaning..." -ForegroundColor Yellow
            
            try {
                $CacheData = Get-Content $CacheFile | ConvertFrom-Json
                $TotalEntries = $CacheData.Keys.Count
                $EntriesToRemove = [Math]::Ceiling($TotalEntries * 0.3)  # Remove 30%
                
                # Remove oldest entries
                $SortedEntries = $CacheData.Keys | Sort-Object { $CacheData[$_].Timestamp }
                $ToRemove = $SortedEntries | Select-Object -First $EntriesToRemove
                
                foreach ($Key in $ToRemove) {
                    $CacheData.PSObject.Properties.Remove($Key)
                }
                
                $CacheData | ConvertTo-Json -Depth 10 | Out-File $CacheFile -Encoding UTF8
                
                $NewSize = (Get-Item $CacheFile).Length / 1MB
                Write-Host "[PERF] Cache cleaned: $([math]::Round($CacheSize, 2))MB -> $([math]::Round($NewSize, 2))MB" -ForegroundColor Green
                
            } catch {
                Write-Warning "[PERF] Cache cleanup failed: $($_.Exception.Message)"
            }
        }
    }
}

function Stop-PerformanceMonitoring {
    Write-Host "[PERF] Stopping performance monitoring..." -ForegroundColor Yellow
    
    try {
        Get-Job | Where-Object { $_.Command -like "*PerformanceMonitor*" } | Stop-Job
        Get-Job | Where-Object { $_.Command -like "*PerformanceMonitor*" } | Remove-Job
        Write-Host "[PERF] Performance monitoring stopped" -ForegroundColor Green
    } catch {
        Write-Warning "[PERF] Failed to stop monitoring: $($_.Exception.Message)"
    }
}

# Performance-aware file reader
function Read-FileOptimized {
    param(
        [string]$Path,
        [int]$MaxSizeMB = 10
    )
    
    $FileInfo = Get-Item $Path
    $SizeMB = $FileInfo.Length / 1MB
    
    if ($SizeMB -gt $MaxSizeMB) {
        Write-Warning "[PERF] File too large ($([math]::Round($SizeMB, 2))MB), reading in chunks"
        
        # Read first chunk for preview
        $Stream = [System.IO.File]::OpenRead($Path)
        $Buffer = New-Object byte[] $Script:FileBufferSize
        $BytesRead = $Stream.Read($Buffer, 0, $Buffer.Length)
        $Stream.Close()
        
        return [System.Text.Encoding]::UTF8.GetString($Buffer, 0, $BytesRead)
    } else {
        return [System.IO.File]::ReadAllText($Path)
    }
}

# Export functions
Export-ModuleMember -Function *
