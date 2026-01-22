function Get-KnouxHash($Path) {
    try { (Get-FileHash $Path -Algorithm MD5).Hash } catch { "ERR" }
}

function Load-Cache($CacheFile) {
    if (Test-Path $CacheFile) { 
        try { return Get-Content $CacheFile | ConvertFrom-Json -AsHashtable } catch { return @{} } 
    }
    return @{}
}
