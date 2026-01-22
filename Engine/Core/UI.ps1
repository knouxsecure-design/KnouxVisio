function Write-TitanProgress($Current, $Total, $Name) {
    $Pct = [Math]::Round(($Current / $Total) * 100)
    $BarSize = 25; $Filled = [int](($Pct / 100) * $BarSize)
    $Bar = "█" * $Filled + "░" * ($BarSize - $Filled)
    
    # ANSI Colors
    $C_Cyan = "$([char]27)[1;36m"; $C_Reset = "$([char]27)[0m"; $C_Green = "$([char]27)[1;32m"
    
    Write-Host "`r $C_Cyan[TITAN]$C_Reset $Bar $C_Green$Pct%$C_Reset | Analyzing: $($Name.PadRight(25).Substring(0,25))" -NoNewline
}
