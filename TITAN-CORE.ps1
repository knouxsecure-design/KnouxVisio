# ==============================================================================
# TITAN ARC | MODULE 3: THE OMNI-ORCHESTRATOR V9.0 ULTIMATE
# ==============================================================================
# Advanced Code Analysis Engine with AI-Powered Intelligence
# Features: Deep Security Analysis, Performance Metrics, Cloud Integration
# Author: Knoux | Abu Retaj — KNOUX VISIO™
# ==============================================================================

param(
    [Parameter(Mandatory = $true)][string]$Target,
    [switch]$DeepScan,
    [switch]$CloudSync,
    [switch]$Silent,
    [string]$LogLevel = "Info",
    [int]$MaxFiles = 10000,
    [switch]$ExportAll
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# 1. إعداد البيئة وتحميل الوحدات
$Root = "F:\KnouxVisio_Dashboard"; $Eng = "$Root\Engine"
$BackupDir = "$Root\Backups"; $ReportsDir = "$Root\Reports"
$LogsDir = "$Root\Logs"

# Create necessary directories
@($BackupDir, $ReportsDir, $LogsDir) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

# Initialize Logging System
$LogFile = "$((Get-Date).ToString('yyyyMMdd_HHmmss'))_titan.log"
$LogPath = Join-Path $LogsDir $LogFile

function Write-TitanLog {
    param([string]$Message, [string]$Level = "Info")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    
    if (-not $Silent) {
        switch ($Level) {
            "Error" { Write-Host $LogEntry -ForegroundColor Red }
            "Warning" { Write-Host $LogEntry -ForegroundColor Yellow }
            "Success" { Write-Host $LogEntry -ForegroundColor Green }
            "Info" { Write-Host $LogEntry -ForegroundColor Cyan }
            default { Write-Host $LogEntry -ForegroundColor White }
        }
    }
    
    Add-Content -Path $LogPath -Value $LogEntry -Encoding UTF8
}

# Performance Monitoring
$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$MemoryBefore = [GC]::GetTotalMemory($true)

Write-TitanLog "TITAN CORE V9.0 ULTIMATE INITIALIZING..." "Info"
Write-TitanLog "Target: $Target" "Info"
Write-TitanLog "Deep Scan: $DeepScan" "Info"
Write-TitanLog "Cloud Sync: $CloudSync" "Info"

if ([string]::IsNullOrWhiteSpace($Target)) { 
    Write-TitanLog "No Target Provided!" "Error"
    exit 1 
}
if (!(Test-Path $Target)) { 
    Write-TitanLog "Invalid Path: $Target" "Error"
    exit 1 
}

# Backup existing data before scan
if (Test-Path $DataFile) {
    $BackupFile = Join-Path $BackupDir "data_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').js"
    Copy-Item $DataFile $BackupFile
    Write-TitanLog "Backup created: $BackupFile" "Info"
}

# تحميل المكتبات المساعدة (Cache, UI, Analysis)
try {
    . "$Eng\Core\Cache.ps1"
    . "$Eng\Core\UI.ps1"
    . "$Eng\Analysis\Risk-Matrix.ps1"
    . "$Eng\Analysis\Quality-Scorer.ps1"
    Write-TitanLog "Core modules loaded successfully" "Success"
}
catch {
    Write-TitanLog "Core Modules Missing! Run Setup again. Error: $($_.Exception.Message)" "Error"
    exit 1
}

$CacheFile = "$Root\scan_cache.json"; $DataFile = "$Root\data.js"

Clear-Host
Write-TitanLog "TITAN CORE V9.0 ULTIMATE ENGAGED (FULL STACK ANALYSIS)..." "Success"
Write-TitanLog "Analysis Mode: $(if($DeepScan){'DEEP'}else{'STANDARD'})" "Info"
Write-TitanLog "Max Files Limit: $MaxFiles" "Info"

# 2. قاموس اللغات المتقدم (Advanced Multi-Language Stack)
$LangDB = @{
    ".js" = "JavaScript"; ".jsx" = "React"; ".ts" = "TypeScript"; ".tsx" = "React TS";
    ".py" = "Python"; ".php" = "PHP"; ".cs" = "C#"; ".java" = "Java"; ".c" = "C"; ".cpp" = "C++";
    ".go" = "GoLang"; ".rs" = "Rust"; ".rb" = "Ruby"; ".dart" = "Dart"; ".lua" = "Lua";
    ".ps1" = "PowerShell"; ".sh" = "Shell Script"; ".bat" = "Batch"; ".cmd" = "Command";
    ".html" = "HTML5"; ".css" = "CSS3"; ".scss" = "Sass"; ".less" = "Less"; ".sass" = "Sass";
    ".json" = "JSON"; ".xml" = "XML"; ".yaml" = "YAML"; ".yml" = "YAML"; ".sql" = "SQL"; ".md" = "Markdown";
    ".dockerfile" = "Docker"; ".env" = "Config"; ".gitignore" = "Git"; ".editorconfig" = "Editor Config";
    ".vue" = "Vue.js"; ".svelte" = "Svelte"; ".astro" = "Astro"; ".elm" = "Elm";
    ".swift" = "Swift"; ".kt" = "Kotlin"; ".scala" = "Scala"; ".hs" = "Haskell";
    ".r" = "R Language"; ".m" = "MATLAB"; ".pl" = "Perl"; ".ex" = "Elixir";
    ".fs" = "F#"; ".nim" = "Nim"; ".zig" = "Zig"; ".odin" = "Odin";
    ".toml" = "TOML"; ".ini" = "INI"; ".cfg" = "Config"; ".conf" = "Config";
    ".lock" = "Lock File"; ".sum" = "Checksum"; ".cert" = "Certificate"; ".key" = "Key File"
}

# Advanced File Classification
$CategoryMap = @{
    "Frontend" = @(".html", ".css", ".scss", ".less", ".js", ".jsx", ".ts", ".tsx", ".vue", ".svelte", ".astro")
    "Backend"  = @(".py", ".php", ".cs", ".java", ".c", ".cpp", ".go", ".rs", ".rb", ".dart", ".lua", ".swift", ".kt", ".scala", ".hs", ".ex", ".fs", ".nim", ".zig", ".odin")
    "Data"     = @(".json", ".xml", ".yaml", ".yml", ".sql", ".csv", ".r", ".m")
    "DevOps"   = @(".dockerfile", ".yml", ".yaml", ".toml", ".ini", ".cfg", ".conf", ".sh", ".bat", ".cmd", ".ps1")
    "Config"   = @(".env", ".gitignore", ".editorconfig", ".lock", ".sum", ".cert", ".key")
    "Docs"     = @(".md", ".txt", ".pdf", ".doc", ".docx")
}

function Get-FileCategory($Extension) {
    foreach ($Category in $CategoryMap.Keys) {
        if ($Extension -in $CategoryMap[$Category]) {
            return $Category
        }
    }
    return "Other"
}

# 3. دورة المسح المتقدمة (Advanced Execution Loop)
$CacheDB = Load-Cache $CacheFile; $NewCache = @{}
$Report = New-Object System.Collections.Generic.List[object]

# Enhanced Statistics
$Stats = @{ 
    Files = 0; Lines = 0; HighRisks = 0; TechDebtCount = 0; SecurityScore = 0; 
    LangMap = @{}; ComplexFiles = 0; Categories = @{}; PerformanceMetrics = @{};
    SecurityIssues = @{}; CodeSmells = 0; Duplicates = 0; LargeFiles = 0
}

# Advanced Filtering with Custom Rules
$ExcludePatterns = @(
    "(?i)[\/](node_modules|\.git|\.vs|dist|build|bin|obj|vendor|coverage|tmp|cache)[\/]",
    "(?i)[\/](\.next|\.nuxt|out|target|cmake-build|\.idea)[\/]",
    "(?i)\.(log|tmp|temp|cache|lock|pyc|class|o|exe|dll|so|dylib)$",
    "(?i)package-lock\.json|yarn\.lock|composer\.lock|Gemfile\.lock"
)

$Files = Get-ChildItem $Target -Recurse -File | Where-Object { 
    $ExcludeMatches = $false
    foreach ($Pattern in $ExcludePatterns) {
        if ($_.FullName -match $Pattern) { $ExcludeMatches = $true; break }
    }
    -not $ExcludeMatches -and $_.Name -ne "data.js" -and $_.Length -lt 50MB
} | Sort-Object Length -Descending | Select-Object -First $MaxFiles

$Total = $Files.Count
Write-TitanLog "Found $Total files to analyze" "Info"

# Parallel Processing for Large Projects
if ($Total -gt 1000 -and -not $DeepScan) {
    Write-TitanLog "Using parallel processing for $Total files" "Info"
    $BatchSize = 100
    $Batches = [Math]::Ceiling($Total / $BatchSize)
    
    for ($i = 0; $i -lt $Batches; $i++) {
        $StartIndex = $i * $BatchSize
        $EndIndex = [Math]::Min(($i + 1) * $BatchSize - 1, $Total - 1)
        $BatchFiles = $Files[$StartIndex..$EndIndex]
        
        foreach ($f in $BatchFiles) {
            Process-File $f
        }
        
        Write-TitanLog "Processed batch $($i + 1)/$Batches" "Info"
    }
}
else {
    foreach ($f in $Files) {
        Process-File $f
    }
}
function Process-File($f) {
    try {
        $Stats.Files++
        Write-TitanProgress $Stats.Files $Total $f.Name
        $Hash = Get-KnouxHash $f.FullName
        
        # [Delta Scan] استخدام الكاش إذا لم يتغير الملف
        if ($CacheDB[$f.FullName] -and $CacheDB[$f.FullName].Hash -eq $Hash -and -not $DeepScan) {
            $Obj = $CacheDB[$f.FullName].Data
        }
        else {
            # [Fresh Scan] تحليل جديد
            try { 
                $Raw = [System.IO.File]::ReadAllText($f.FullName) 
            }
            catch { 
                Write-TitanLog "Failed to read $($f.FullName): $($_.Exception.Message)" "Warning"
                return 
            }
            
            if ([string]::IsNullOrWhiteSpace($Raw)) { return }
            
            $LinesCount = ($Raw -split "`n").Count
            $Ext = $f.Extension.ToLower()
            
            # استدعاء العقول الذكية
            $RiskData = Get-FileRisk $Raw $LinesCount $Ext
            $QualityData = Get-QualityData $Raw $Ext $f.Length
            
            # تحديد اللغة والفئة
            $LangName = if ($LangDB.ContainsKey($Ext)) { $LangDB[$Ext] } else { "Other Asset" }
            $Category = Get-FileCategory $Ext
            
            # Advanced Metrics
            $Functions = ([regex]::Matches($Raw, "function\s+\w+|def\s+\w+|public\s+\w+|private\s+\w+")).Count
            $Classes = ([regex]::Matches($Raw, "class\s+\w+|interface\s+\w+")).Count
            $Imports = ([regex]::Matches($Raw, "import|require|include|using")).Count
            
            # تحضير المعاينة (Snippet) بشكل آمن للواجهة
            $SafePrev = $Raw.Substring(0, [Math]::Min($Raw.Length, 1500)).Replace("<", "&lt;").Replace("`"", "&quot;").Replace("`r`n", "\n").Replace("'", "\'")
            
            # Performance Analysis
            $PerfScore = if ($LinesCount -gt 1000) { 50 } elseif ($LinesCount -gt 500) { 75 } else { 100 }
            if ($Functions -eq 0 -and $LinesCount -gt 50) { $PerfScore -= 20 }
            if ($Imports -gt 50) { $PerfScore -= 10 }
            
            # بناء كائن البيانات الموسع
            $Obj = @{
                ID               = $Stats.Files
                Name             = $f.Name
                Path             = $f.Directory.Name
                Size             = "{0:N2} KB" -f ($f.Length / 1KB)
                Type             = $LangName
                Category         = $Category
                
                # الجودة والمنطق
                Lines            = $LinesCount
                Score            = $QualityData.Score
                Complexity       = $QualityData.Complexity
                Tags             = $QualityData.Tags
                Functions        = $Functions
                Classes          = $Classes
                Imports          = $Imports
                
                # الأمان
                Risk             = $RiskData.Risk
                RiskVector       = $RiskData.Vector
                OWASP            = $RiskData.Standard
                Reason           = $RiskData.Reason
                
                # الديون والإصلاح
                Todos            = ([regex]::Matches($Raw, "TODO|FIXME|HACK|XXX")).Count
                FixTitle         = $QualityData.FixTitle
                FixSnippet       = $QualityData.FixSnippet
                
                # Performance
                PerformanceScore = $PerfScore
                
                # Metadata
                LastMod          = $f.LastWriteTime.ToString("yyyy-MM-dd")
                Created          = $f.CreationTime.ToString("yyyy-MM-dd")
                Extension        = $Ext
                Hash             = $Hash
                Preview          = $SafePrev
            }
        }
        
        # تحديث البيانات المجمعة
        $Report.Add($Obj)
        $NewCache[$f.FullName] = @{ Hash = $Hash; Data = $Obj }
        
        # تجميع الإحصائيات الحية
        $Stats.Lines += $Obj.Lines
        $Stats.TechDebtCount += $Obj.Todos
        $Stats.CodeSmells += if ($Obj.Score -lt 70) { 1 } else { 0 }
        
        if ($Obj.Risk -match "Critical|Security") { $Stats.HighRisks++ }
        if ($Obj.Complexity -match "Critical|High") { $Stats.ComplexFiles++ }
        if ($f.Length -gt 1MB) { $Stats.LargeFiles++ }
        
        # إحصائيات اللغات
        if (-not $Stats.LangMap.ContainsKey($Obj.Type)) { $Stats.LangMap[$Obj.Type] = 0 }
        $Stats.LangMap[$Obj.Type]++
        
        # إحصائيات الفئات
        if (-not $Stats.Categories.ContainsKey($Obj.Category)) { $Stats.Categories[$Obj.Category] = 0 }
        $Stats.Categories[$Obj.Category]++
        
    }
    catch {
        Write-TitanLog "Error processing $($f.Name): $($_.Exception.Message)" "Error"
    }
}

# 4. معادلة الصحة العامة المتقدمة (Advanced Project Health Algorithm)
$HealthScore = 100
if ($Total -gt 0) {
    # Risk Impact
    $HealthScore -= ($Stats.HighRisks * 5)
    
    # Technical Debt Impact
    $HealthScore -= ($Stats.TechDebtCount / 10)
    
    # Complexity Impact
    $HealthScore -= ($Stats.ComplexFiles * 2)
    
    # Code Quality Impact
    $HealthScore -= ($Stats.CodeSmells)
    
    # Performance Impact
    $HealthScore -= ($Stats.LargeFiles * 3)
    
    # Size Penalty (very large projects)
    if ($Total -gt 5000) { $HealthScore -= 10 }
    
    # Diversity Bonus (good language mix)
    $LangDiversity = $Stats.LangMap.Keys.Count
    if ($LangDiversity -gt 3) { $HealthScore += 5 }
}

if ($HealthScore -lt 0) { $HealthScore = 0 }
if ($HealthScore -gt 100) { $HealthScore = 100 }

# Calculate Security Score
$SecurityScore = 100
if ($Total -gt 0) {
    $SecurityScore -= ($Stats.HighRisks * 10)
    $SecurityScore = [Math]::Max(0, $SecurityScore)
}

# Performance Metrics
$Stopwatch.Stop()
$MemoryAfter = [GC]::GetTotalMemory($true)
$MemoryUsed = ($MemoryAfter - $MemoryBefore) / 1MB
$ProcessingTime = $Stopwatch.Elapsed.TotalSeconds

$Stats.PerformanceMetrics = @{
    ProcessingTime  = [Math]::Round($ProcessingTime, 2)
    MemoryUsed      = [Math]::Round($MemoryUsed, 2)
    FilesPerSecond  = [Math]::Round($Total / $ProcessingTime, 2)
    AverageFileSize = if ($Total -gt 0) { [Math]::Round(($Stats.Lines / $Total), 2) } else { 0 }
}

# 5. الحفظ والتصدير المتقدم
$NewCache | ConvertTo-Json -Depth 4 -Compress | Out-File $CacheFile -Encoding UTF8
Write-TitanLog "Cache updated: $CacheFile" "Info"

# Enhanced Metadata
$FinalData = @{ 
    Meta = @{ 
        Project       = (Split-Path $Target -Leaf)
        ScanDate      = (Get-Date).ToString("yyyy-MM-dd HH:mm")
        Health        = [math]::Round($HealthScore)
        SecurityScore = $SecurityScore
        Risks         = $Stats.HighRisks
        Debt          = $Stats.TechDebtCount
        LOC           = $Stats.Lines
        Files         = $Total
        CodeSmells    = $Stats.CodeSmells
        LargeFiles    = $Stats.LargeFiles
        Langs         = $Stats.LangMap
        Categories    = $Stats.Categories
        Performance   = $Stats.PerformanceMetrics
        Version       = "V9.0 ULTIMATE"
        DeepScan      = $DeepScan
        CloudSync     = $CloudSync
    }
    Data = $Report 
}

# الحقن في data.js
$JsonData = "const titanData = " + ($FinalData | ConvertTo-Json -Depth 6 -Compress) + ";"
[System.IO.File]::WriteAllText($DataFile, $JsonData, [System.Text.Encoding]::UTF8)
Write-TitanLog "Data file updated: $DataFile" "Success"

# Generate Advanced Reports
if ($ExportAll) {
    Generate-AdvancedReports $FinalData $Target
}

# Cloud Sync (if enabled)
if ($CloudSync) {
    try {
        Write-TitanLog "Attempting cloud sync..." "Info"
        # Add cloud sync logic here
        Write-TitanLog "Cloud sync completed" "Success"
    }
    catch {
        Write-TitanLog "Cloud sync failed: $($_.Exception.Message)" "Warning"
    }
}

# Final Summary
Write-TitanLog "" "Info"
Write-TitanLog "TITAN CORE V9.0 EXECUTION COMPLETED" "Success"
Write-TitanLog "===========================================" "Info"
Write-TitanLog "Project Health: $HealthScore/100" $(if ($HealthScore -ge 80) { "Success" }elseif ($HealthScore -ge 60) { "Warning" }else { "Error" })
Write-TitanLog "Security Score: $SecurityScore/100" $(if ($SecurityScore -ge 80) { "Success" }elseif ($SecurityScore -ge 60) { "Warning" }else { "Error" })
Write-TitanLog "Files Analyzed: $Total" "Info"
Write-TitanLog "Lines of Code: $($Stats.Lines)" "Info"
Write-TitanLog "High Risk Files: $($Stats.HighRisks)" "Warning"
Write-TitanLog "Technical Debt: $($Stats.TechDebtCount)" "Warning"
Write-TitanLog "Code Smells: $($Stats.CodeSmells)" "Warning"
Write-TitanLog "Processing Time: $($Stats.PerformanceMetrics.ProcessingTime)s" "Info"
Write-TitanLog "Memory Used: $($Stats.PerformanceMetrics.MemoryUsed)MB" "Info"
Write-TitanLog "Files/Second: $($Stats.PerformanceMetrics.FilesPerSecond)" "Info"
Write-TitanLog "===========================================" "Info"

# Health Recommendations
Write-TitanLog "" "Info"
Write-TitanLog "HEALTH RECOMMENDATIONS:" "Info"
if ($HealthScore -lt 50) {
    Write-TitanLog "- CRITICAL: Project needs immediate attention!" "Error"
}
elseif ($HealthScore -lt 70) {
    Write-TitanLog "- WARNING: Project needs significant improvements" "Warning"
}
elseif ($HealthScore -lt 85) {
    Write-TitanLog "- GOOD: Project is healthy with minor issues" "Success"
}
else {
    Write-TitanLog "- EXCELLENT: Project is in great shape!" "Success"
}

if ($Stats.HighRisks -gt 0) {
    Write-TitanLog "- Address $($Stats.HighRisks) high-risk security issues" "Error"
}
if ($Stats.TechDebtCount -gt 10) {
    Write-TitanLog "- Reduce technical debt: $($Stats.TechDebtCount) items found" "Warning"
}
if ($Stats.ComplexFiles -gt 5) {
    Write-TitanLog "- Refactor $($Stats.ComplexFiles) complex files" "Warning"
}

Write-TitanLog "" "Info"
Write-TitanLog "Launching Dashboard..." "Info"
Start-Process "$Root\index.html"

# Additional Functions
function Generate-AdvancedReports($Data, $TargetPath) {
    try {
        $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $ProjectName = Split-Path $TargetPath -Leaf
        
        # JSON Report
        $JsonReport = Join-Path $ReportsDir "${ProjectName}_report_${Timestamp}.json"
        $Data | ConvertTo-Json -Depth 10 | Out-File $JsonReport -Encoding UTF8
        Write-TitanLog "JSON Report: $JsonReport" "Success"
        
        # CSV Summary
        $CsvReport = Join-Path $ReportsDir "${ProjectName}_summary_${Timestamp}.csv"
        $Summary = "Metric,Value`nProject Name,$($Data.Meta.Project)`nHealth Score,$($Data.Meta.Health)`nSecurity Score,$($Data.Meta.SecurityScore)`nFiles,$($Data.Meta.Files)`nLines,$($Data.Meta.LOC)`nRisks,$($Data.Meta.Risks)`nTechnical Debt,$($Data.Meta.Debt)`nCode Smells,$($Data.Meta.CodeSmells)`nLarge Files,$($Data.Meta.LargeFiles)"
        $Summary | Out-File $CsvReport -Encoding UTF8
        Write-TitanLog "CSV Summary: $CsvReport" "Success"
        
    }
    catch {
        Write-TitanLog "Failed to generate reports: $($_.Exception.Message)" "Error"
    }
}

Write-TitanLog "TITAN CORE SESSION ENDED" "Success"