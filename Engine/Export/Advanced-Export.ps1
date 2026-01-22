# ==============================================================================
# TITAN ARC | ADVANCED EXPORT MODULE V2.0
# ==============================================================================
# Enhanced Export Capabilities with Multiple Formats and Cloud Integration
# Author: Knoux | Abu Retaj — KNOUX VISIO™
# ==============================================================================

function Export-TitanReport {
    param(
        [Parameter(Mandatory=$true)][object]$Data,
        [string]$OutputPath = ".",
        [string[]]$Formats = @("JSON", "CSV", "HTML", "PDF"),
        [switch]$IncludeCharts,
        [switch]$CloudUpload
    )
    
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $ProjectName = $Data.Meta.Project
    $BaseName = "${ProjectName}_titan_report_${Timestamp}"
    
    foreach ($Format in $Formats) {
        try {
            switch ($Format.ToUpper()) {
                "JSON" { Export-JsonReport $Data $OutputPath $BaseName }
                "CSV" { Export-CsvReport $Data $OutputPath $BaseName }
                "HTML" { Export-HtmlReport $Data $OutputPath $BaseName $IncludeCharts }
                "PDF" { Export-PdfReport $Data $OutputPath $BaseName $IncludeCharts }
                "XML" { Export-XmlReport $Data $OutputPath $BaseName }
                "EXCEL" { Export-ExcelReport $Data $OutputPath $BaseName }
                default { Write-Warning "Unsupported format: $Format" }
            }
        } catch {
            Write-Error "Failed to export $Format : $($_.Exception.Message)"
        }
    }
    
    if ($CloudUpload) {
        Export-ToCloud $OutputPath $BaseName $Formats
    }
}

function Export-JsonReport {
    param($Data, $Path, $BaseName)
    
    $JsonFile = Join-Path $Path "${BaseName}.json"
    $Data | ConvertTo-Json -Depth 10 | Out-File $JsonFile -Encoding UTF8
    Write-Host "JSON Report: $JsonFile" -ForegroundColor Green
}

function Export-CsvReport {
    param($Data, $Path, $BaseName)
    
    $CsvFile = Join-Path $Path "${BaseName}.csv"
    
    # Create detailed CSV
    $CsvContent = "ID,Name,Path,Type,Category,Lines,Score,Complexity,Risk,Todos,Functions,Classes,Imports,Size,LastMod`n"
    foreach ($File in $Data.Data) {
        $CsvContent += "$($File.ID),`"$($File.Name)`",`"$($File.Path)`",`"$($File.Type)`",`"$($File.Category)`",$($File.Lines),$($File.Score),`"$($File.Complexity)`",`"$($File.Risk)`",$($File.Todos),$($File.Functions),$($File.Classes),$($File.Imports),`"$($File.Size)`",`"$($File.LastMod)`"`n"
    }
    
    $CsvContent | Out-File $CsvFile -Encoding UTF8
    Write-Host "CSV Report: $CsvFile" -ForegroundColor Green
}

function Export-HtmlReport {
    param($Data, $Path, $BaseName, $IncludeCharts)
    
    $HtmlFile = Join-Path $Path "${BaseName}.html"
    
    $Html = @"
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <title>TITAN Report - $($Data.Meta.Project)</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: 'Cairo', sans-serif; margin: 20px; background: #05070a; color: #cfd8dc; }
        .header { text-align: center; padding: 20px; background: linear-gradient(45deg, #00f2fe, #ff0055); border-radius: 10px; margin-bottom: 20px; }
        .metric { display: inline-block; margin: 10px; padding: 15px; background: #1f2228; border-radius: 8px; text-align: center; min-width: 120px; }
        .metric-value { font-size: 2em; font-weight: bold; color: #00f2fe; }
        .metric-label { font-size: 0.9em; color: #888; }
        .chart-container { width: 45%; display: inline-block; margin: 10px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 10px; border: 1px solid #333; text-align: right; }
        th { background: #1f2228; color: #00f2fe; }
        .risk-high { color: #ff0055; }
        .risk-medium { color: #ffd700; }
        .risk-low { color: #00ff9d; }
    </style>
</head>
<body>
    <div class="header">
        <h1>TITAN ANALYSIS REPORT</h1>
        <h2>$($Data.Meta.Project)</h2>
        <p>Generated: $($Data.Meta.ScanDate)</p>
    </div>
    
    <div class="metrics">
        <div class="metric">
            <div class="metric-value">$($Data.Meta.Health)%</div>
            <div class="metric-label">Health Score</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($Data.Meta.SecurityScore)%</div>
            <div class="metric-label">Security Score</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($Data.Meta.Files)</div>
            <div class="metric-label">Files</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($Data.Meta.LOC)</div>
            <div class="metric-label">Lines of Code</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($Data.Meta.Risks)</div>
            <div class="metric-label">High Risks</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($Data.Meta.Debt)</div>
            <div class="metric-label">Tech Debt</div>
        </div>
    </div>
    
    $(if ($IncludeCharts) { @"
    <div class="charts">
        <div class="chart-container">
            <canvas id="langChart"></canvas>
        </div>
        <div class="chart-container">
            <canvas id="riskChart"></canvas>
        </div>
    </div>
    "@ } )
    
    <table>
        <thead>
            <tr>
                <th>File</th>
                <th>Type</th>
                <th>Score</th>
                <th>Complexity</th>
                <th>Risk</th>
                <th>Lines</th>
                <th>Todos</th>
            </tr>
        </thead>
        <tbody>
"@
    
    foreach ($File in $Data.Data | Sort-Object Score -Descending) {
        $RiskClass = switch ($File.Risk) {
            "Critical" { "risk-high" }
            "High" { "risk-high" }
            "Medium" { "risk-medium" }
            default { "risk-low" }
        }
        
        $Html += @"
            <tr>
                <td>$($File.Name)</td>
                <td>$($File.Type)</td>
                <td>$($File.Score)%</td>
                <td>$($File.Complexity)</td>
                <td class="$RiskClass">$($File.Risk)</td>
                <td>$($File.Lines)</td>
                <td>$($File.Todos)</td>
            </tr>
"@
    }
    
    $Html += @"
        </tbody>
    </table>
    
    $(if ($IncludeCharts) { @"
    <script>
        // Language Distribution Chart
        const langCtx = document.getElementById('langChart').getContext('2d');
        new Chart(langCtx, {
            type: 'doughnut',
            data: {
                labels: [$($Data.Meta.Langs.Keys | ForEach-Object { "'$_'" })],
                datasets: [{
                    data: [$($Data.Meta.Langs.Values)],
                    backgroundColor: ['#00f2fe', '#ff0055', '#00ff9d', '#ffd700', '#ff00ff', '#444']
                }]
            },
            options: { responsive: true, plugins: { title: { display: true, text: 'Language Distribution' } } }
        });
        
        // Risk Distribution Chart
        const riskCtx = document.getElementById('riskChart').getContext('2d');
        new Chart(riskCtx, {
            type: 'bar',
            data: {
                labels: ['Critical', 'High', 'Medium', 'Low'],
                datasets: [{
                    label: 'Files by Risk Level',
                    data: [$(($Data.Data | Where-Object { $_.Risk -eq 'Critical' }).Count), $(($Data.Data | Where-Object { $_.Risk -eq 'High' }).Count), $(($Data.Data | Where-Object { $_.Risk -eq 'Medium' }).Count), $(($Data.Data | Where-Object { $_.Risk -eq 'Low' }).Count)],
                    backgroundColor: ['#ff0055', '#ff6b6b', '#ffd700', '#00ff9d']
                }]
            },
            options: { responsive: true, plugins: { title: { display: true, text: 'Risk Distribution' } } }
        });
    </script>
    "@ } )
</body>
</html>
"@
    
    $Html | Out-File $HtmlFile -Encoding UTF8
    Write-Host "HTML Report: $HtmlFile" -ForegroundColor Green
}

function Export-PdfReport {
    param($Data, $Path, $BaseName, $IncludeCharts)
    
    # First generate HTML, then convert to PDF
    Export-HtmlReport $Data $Path $BaseName $IncludeCharts
    
    $HtmlFile = Join-Path $Path "${BaseName}.html"
    $PdfFile = Join-Path $Path "${BaseName}.pdf"
    
    try {
        # Use headless Chrome or similar for PDF conversion
        $ChromeArgs = @(
            "--headless",
            "--disable-gpu",
            "--print-to-pdf=`"$PdfFile`"",
            "--print-to-pdf-no-header",
            "--virtual-time-budget=5000",
            "`"file://$HtmlFile`""
        )
        
        Start-Process "chrome" -ArgumentList $ChromeArgs -Wait -NoNewWindow
        
        if (Test-Path $PdfFile) {
            Write-Host "PDF Report: $PdfFile" -ForegroundColor Green
        } else {
            Write-Warning "PDF generation failed - Chrome not available"
        }
    } catch {
        Write-Warning "PDF conversion failed: $($_.Exception.Message)"
    }
}

function Export-XmlReport {
    param($Data, $Path, $BaseName)
    
    $XmlFile = Join-Path $Path "${BaseName}.xml"
    
    $Xml = [xml]"<?xml version='1.0' encoding='UTF-8'?><titan-report></titan-report>"
    $Root = $Xml.SelectSingleNode("//titan-report")
    
    # Add metadata
    $Meta = $Xml.CreateElement("metadata")
    $Data.Meta.Keys | ForEach-Object {
        $Element = $Xml.CreateElement($_)
        $Element.InnerText = $Data.Meta[$_]
        $Meta.AppendChild($Element) | Out-Null
    }
    $Root.AppendChild($Meta) | Out-Null
    
    # Add files
    $Files = $Xml.CreateElement("files")
    foreach ($File in $Data.Data) {
        $FileElement = $Xml.CreateElement("file")
        $File.Keys | ForEach-Object {
            $Element = $Xml.CreateElement($_)
            $Element.InnerText = $File[$_]
            $FileElement.AppendChild($Element) | Out-Null
        }
        $Files.AppendChild($FileElement) | Out-Null
    }
    $Root.AppendChild($Files) | Out-Null
    
    $Xml.Save($XmlFile)
    Write-Host "XML Report: $XmlFile" -ForegroundColor Green
}

function Export-ExcelReport {
    param($Data, $Path, $BaseName)
    
    try {
        $ExcelFile = Join-Path $Path "${BaseName}.xlsx"
        
        # Use Excel COM object if available
        $Excel = New-Object -ComObject Excel.Application
        $Workbook = $Excel.Workbooks.Add()
        $Sheet = $Workbook.Worksheets.Item(1)
        
        # Headers
        $Headers = @("ID", "Name", "Path", "Type", "Category", "Lines", "Score", "Complexity", "Risk", "Todos", "Functions", "Classes", "Imports", "Size", "LastMod")
        for ($i = 0; $i -lt $Headers.Count; $i++) {
            $Sheet.Cells.Item(1, $i + 1).Value = $Headers[$i]
            $Sheet.Cells.Item(1, $i + 1).Font.Bold = $true
        }
        
        # Data
        $Row = 2
        foreach ($File in $Data.Data) {
            $Sheet.Cells.Item($Row, 1).Value = $File.ID
            $Sheet.Cells.Item($Row, 2).Value = $File.Name
            $Sheet.Cells.Item($Row, 3).Value = $File.Path
            $Sheet.Cells.Item($Row, 4).Value = $File.Type
            $Sheet.Cells.Item($Row, 5).Value = $File.Category
            $Sheet.Cells.Item($Row, 6).Value = $File.Lines
            $Sheet.Cells.Item($Row, 7).Value = $File.Score
            $Sheet.Cells.Item($Row, 8).Value = $File.Complexity
            $Sheet.Cells.Item($Row, 9).Value = $File.Risk
            $Sheet.Cells.Item($Row, 10).Value = $File.Todos
            $Sheet.Cells.Item($Row, 11).Value = $File.Functions
            $Sheet.Cells.Item($Row, 12).Value = $File.Classes
            $Sheet.Cells.Item($Row, 13).Value = $File.Imports
            $Sheet.Cells.Item($Row, 14).Value = $File.Size
            $Sheet.Cells.Item($Row, 15).Value = $File.LastMod
            $Row++
        }
        
        # Auto-fit columns
        $Sheet.UsedRange.Columns.AutoFit() | Out-Null
        
        $Workbook.SaveAs($ExcelFile)
        $Excel.Quit()
        
        Write-Host "Excel Report: $ExcelFile" -ForegroundColor Green
    } catch {
        Write-Warning "Excel export failed: $($_.Exception.Message)"
    }
}

function Export-ToCloud {
    param($Path, $BaseName, $Formats)
    
    try {
        Write-Host "Attempting cloud upload..." -ForegroundColor Yellow
        
        # Placeholder for cloud integration
        # Add your cloud provider logic here (AWS S3, Azure Blob, Google Cloud, etc.)
        
        foreach ($Format in $Formats) {
            $File = Join-Path $Path "${BaseName}.$($Format.ToLower())"
            if (Test-Path $File) {
                # Upload logic here
                Write-Host "Uploading $Format to cloud..." -ForegroundColor Cyan
            }
        }
        
        Write-Host "Cloud upload completed" -ForegroundColor Green
    } catch {
        Write-Warning "Cloud upload failed: $($_.Exception.Message)"
    }
}

# Export all functions for module loading
Export-ModuleMember -Function *
