# ==============================================================================
# TITAN ARC | DEPENDENCY ANALYZER MODULE V2.0
# ==============================================================================
# Advanced Dependency Analysis and Relationship Mapping
# Author: Knoux | Abu Retaj — KNOUX VISIO™
# ==============================================================================

function Get-DependencyMap {
    param(
        [array]$Files,
        [string]$RootPath,
        [switch]$DeepAnalysis
    )
    
    $DependencyGraph = @{}
    $ImportPatterns = @{
        "JavaScript" = @("import\s+.*from\s+['\"](.*)['\"]", "require\(['\"](.*)['\"]\)")
        "Python" = @("import\s+(.*)", "from\s+(.*)\s+import")
        "PowerShell" = @("Import-Module\s+(.*)", "\. .+(.*)")
        "CSharp" = @("using\s+(.*)")
        "Java" = @("import\s+(.*)")
        "TypeScript" = @("import\s+.*from\s+['\"](.*)['\"]", "import\s+\{.*\}\s+from\s+['\"](.*)['\"]")
    }
    
    foreach ($file in $Files) {
        $Dependencies = @()
        $Content = [System.IO.File]::ReadAllText($file.FullName)
        $Extension = $file.Extension.ToLower()
        
        # Determine language and patterns
        $Language = switch ($Extension) {
            ".js" { "JavaScript" }
            ".ts" { "TypeScript" }
            ".py" { "Python" }
            ".ps1" { "PowerShell" }
            ".cs" { "CSharp" }
            ".java" { "Java" }
            default { "Unknown" }
        }
        
        if ($ImportPatterns.ContainsKey($Language)) {
            foreach ($pattern in $ImportPatterns[$Language]) {
                $Matches = [regex]::Matches($Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                foreach ($match in $Matches) {
                    if ($match.Groups.Count -gt 1) {
                        $Dependency = $match.Groups[1].Value.Trim()
                        if ($Dependency -and $Dependency -notmatch "^\.\.") {
                            $Dependencies += $Dependency
                        }
                    }
                }
            }
        }
        
        # Build dependency graph
        $DependencyGraph[$file.FullName] = @{
            File = $file.Name
            Path = $file.DirectoryName
            Language = $Language
            Dependencies = $Dependencies
            DependencyCount = $Dependencies.Count
            CircularDependencies = @()
        }
    }
    
    # Detect circular dependencies
    if ($DeepAnalysis) {
        $DependencyGraph = Detect-CircularDependencies $DependencyGraph
    }
    
    return $DependencyGraph
}

function Detect-CircularDependencies {
    param($DependencyGraph)
    
    $Visited = @{}
    $RecursionStack = @{}
    
    foreach ($file in $DependencyGraph.Keys) {
        if (-not $Visited.ContainsKey($file)) {
            $CircularDeps = Find-CircularDependencies $file $DependencyGraph $Visited $RecursionStack @()
            if ($CircularDeps.Count -gt 0) {
                $DependencyGraph[$file].CircularDependencies = $CircularDeps
            }
        }
    }
    
    return $DependencyGraph
}

function Find-CircularDependencies {
    param(
        [string]$File,
        $DependencyGraph,
        $Visited,
        $RecursionStack,
        [array]$Path
    )
    
    $Visited[$File] = $true
    $RecursionStack[$File] = $true
    $CurrentPath = $Path + @($File)
    
    $CircularDeps = @()
    
    if ($DependencyGraph.ContainsKey($File)) {
        foreach ($dep in $DependencyGraph[$File].Dependencies) {
            # Try to find the actual file for this dependency
            $DepFile = Find-DependencyFile $dep $DependencyGraph.Keys
            
            if ($DepFile -and $RecursionStack.ContainsKey($DepFile)) {
                # Found circular dependency
                $CycleIndex = $CurrentPath.IndexOf($DepFile)
                if ($CycleIndex -ge 0) {
                    $CircularDeps += $CurrentPath[$CycleIndex..($CurrentPath.Count - 1)] + @($DepFile)
                }
            }
            elseif ($DepFile -and -not $Visited.ContainsKey($DepFile)) {
                $CircularDeps += Find-CircularDependencies $DepFile $DependencyGraph $Visited $RecursionStack $CurrentPath
            }
        }
    }
    
    $RecursionStack.Remove($File)
    return $CircularDeps
}

function Find-DependencyFile {
    param(
        [string]$Dependency,
        [array]$AllFiles
    )
    
    # Try to find the dependency file by name
    foreach ($file in $AllFiles) {
        $FileName = [System.IO.Path]::GetFileNameWithoutExtension($file)
        if ($Dependency -match $FileName -or $FileName -match $Dependency) {
            return $file
        }
    }
    
    return $null
}

function Get-DependencyMetrics {
    param($DependencyGraph)
    
    $TotalFiles = $DependencyGraph.Keys.Count
    $FilesWithDependencies = ($DependencyGraph.Values | Where-Object { $_.Dependencies.Count -gt 0 }).Count
    $TotalDependencies = ($DependencyGraph.Values | Measure-Object -Property DependencyCount -Sum).Sum
    $FilesWithCircularDeps = ($DependencyGraph.Values | Where-Object { $_.CircularDependencies.Count -gt 0 }).Count
    
    # Calculate dependency density
    $MaxPossibleDependencies = $TotalFiles * ($TotalFiles - 1)
    $DependencyDensity = if ($MaxPossibleDependencies -gt 0) { 
        [math]::Round(($TotalDependencies / $MaxPossibleDependencies) * 100, 2) 
    } else { 0 }
    
    # Find most dependent files
    $MostDependent = $DependencyGraph.Values | Sort-Object DependencyCount -Descending | Select-Object -First 5
    
    # Find files with most circular dependencies
    $MostCircular = $DependencyGraph.Values | Where-Object { $_.CircularDependencies.Count -gt 0 } | 
                    Sort-Object { $_.CircularDependencies.Count } -Descending | Select-Object -First 5
    
    return @{
        TotalFiles = $TotalFiles
        FilesWithDependencies = $FilesWithDependencies
        TotalDependencies = $TotalDependencies
        FilesWithCircularDependencies = $FilesWithCircularDeps
        DependencyDensity = $DependencyDensity
        AverageDependenciesPerFile = if ($TotalFiles -gt 0) { [math]::Round($TotalDependencies / $TotalFiles, 2) } else { 0 }
        MostDependentFiles = $MostDependent
        MostCircularFiles = $MostCircular
    }
}

function Export-DependencyReport {
    param(
        $DependencyGraph,
        $Metrics,
        [string]$OutputPath
    )
    
    $Report = @{
        GeneratedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Metrics = $Metrics
        DependencyGraph = $DependencyGraph
    }
    
    $JsonPath = Join-Path $OutputPath "dependency_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $Report | ConvertTo-Json -Depth 10 | Out-File $JsonPath -Encoding UTF8
    
    Write-Host "Dependency report exported to: $JsonPath" -ForegroundColor Green
    return $JsonPath
}

# Export functions
Export-ModuleMember -Function *
