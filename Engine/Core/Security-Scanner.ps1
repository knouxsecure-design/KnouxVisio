# ==============================================================================
# TITAN ARC | SECURITY SCANNER MODULE V2.0
# ==============================================================================
# Advanced Security Vulnerability Detection and Analysis
# Author: Knoux | Abu Retaj — KNOUX VISIO™
# ==============================================================================

function Invoke-SecurityScan {
    param(
        [string]$FilePath,
        [string]$Content,
        [string]$Language,
        [switch]$DeepScan
    )
    
    $Vulnerabilities = @()
    $SecurityScore = 100
    
    # Common vulnerability patterns
    $VulnPatterns = @{
        "SQL Injection" = @(
            "SELECT\s+.*\s+FROM\s+.*\s+WHERE\s+.*\+.*",
            "executeQuery\s*\(\s*['\"].*\+.*['\"]",
            "query\s*\(\s*['\"].*\+.*['\"]",
            "\.sql\s*=\s*['\"].*\+.*['\"]"
        )
        
        "XSS" = @(
            "innerHTML\s*=\s*.*\+.*",
            "document\.write\s*\(\s*.*\+.*",
            "eval\s*\(\s*.*\+.*",
            "dangerouslySetInnerHTML"
        )
        
        "Hardcoded Credentials" = @(
            "password\s*=\s*['\"][^'\"]{4,}['\"]",
            "api[_-]?key\s*=\s*['\"][^'\"]{10,}['\"]",
            "secret\s*=\s*['\"][^'\"]{8,}['\"]",
            "token\s*=\s*['\"][^'\"]{10,}['\"]"
        )
        
        "Path Traversal" = @(
            "\.\./.*",
            "\.\\\.*",
            "readFile\s*\(\s*.*\+.*",
            "open\s*\(\s*.*\+.*"
        )
        
        "Command Injection" = @(
            "exec\s*\(\s*.*\+.*",
            "system\s*\(\s*.*\+.*",
            "shell_exec\s*\(\s*.*\+.*",
            "cmd\.exe.*\+.*"
        )
        
        "Insecure Random" = @(
            "Math\.random\s*\(\s*\)",
            "rand\s*\(\s*\)",
            "random\s*\(\s*\)"
        )
        
        "Weak Cryptography" = @(
            "md5\s*\(",
            "sha1\s*\(",
            "DES\s*",
            "RC4\s*"
        )
    }
    
    # Language-specific patterns
    $LanguagePatterns = @{
        "JavaScript" = @{
            "Prototype Pollution" = @("\[__proto__\]", "\[prototype\]", "\[constructor\]")
            "Unsafe Regex" = @("\(\.\*\*\)", "\(\.\+\)")
        }
        "Python" = @{
            "Pickle Injection" = @("pickle\.loads?", "cPickle\.loads?")
            "Unsafe Eval" = @("eval\s*\(", "exec\s*\(")
        }
        "PowerShell" = @{
            "Command Injection" = @("Invoke-Expression", "iex")
            "Unsafe Download" = @("Invoke-WebRequest.*|.*iex")
        }
    }
    
    # Scan for vulnerabilities
    foreach ($category in $VulnPatterns.Keys) {
        foreach ($pattern in $VulnPatterns[$category]) {
            $Matches = [regex]::Matches($Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            foreach ($match in $Matches) {
                $Line = Get-LineNumber $Content $match.Index
                $Severity = Get-Severity $category $match.Value
                
                $Vulnerabilities += @{
                    Type = $category
                    Severity = $Severity
                    Line = $Line
                    Code = $match.Value.Trim()
                    Description = Get-VulnerabilityDescription $category
                    Recommendation = Get-Recommendation $category
                    CWE = Get-CWE $category
                    ScoreImpact = Get-ScoreImpact $Severity
                }
                
                $SecurityScore -= (Get-ScoreImpact $Severity)
            }
        }
    }
    
    # Language-specific scanning
    if ($LanguagePatterns.ContainsKey($Language)) {
        foreach ($category in $LanguagePatterns[$Language].Keys) {
            foreach ($pattern in $LanguagePatterns[$Language][$category]) {
                $Matches = [regex]::Matches($Content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                foreach ($match in $Matches) {
                    $Line = Get-LineNumber $Content $match.Index
                    $Severity = "Medium"
                    
                    $Vulnerabilities += @{
                        Type = $category
                        Severity = $Severity
                        Line = $Line
                        Code = $match.Value.Trim()
                        Description = Get-VulnerabilityDescription $category
                        Recommendation = Get-Recommendation $category
                        CWE = Get-CWE $category
                        ScoreImpact = Get-ScoreImpact $Severity
                    }
                    
                    $SecurityScore -= (Get-ScoreImpact $Severity)
                }
            }
        }
    }
    
    # Deep scan additional checks
    if ($DeepScan) {
        $DeepVulns = Invoke-DeepSecurityScan $Content $Language
        $Vulnerabilities += $DeepVulns
        $SecurityScore -= ($DeepVulns | Measure-Object -Property ScoreImpact -Sum).Sum
    }
    
    # Ensure score doesn't go below 0
    $SecurityScore = [Math]::Max(0, $SecurityScore)
    
    return @{
        SecurityScore = $SecurityScore
        Vulnerabilities = $Vulnerabilities
        VulnerabilityCount = $Vulnerabilities.Count
        RiskLevel = Get-RiskLevel $SecurityScore $Vulnerabilities.Count
        ScanType = if ($DeepScan) { "Deep" } else { "Standard" }
    }
}

function Get-LineNumber {
    param(
        [string]$Content,
        [int]$Index
    )
    
    $Lines = $Content.Substring(0, $Index).Split("`n")
    return $Lines.Count
}

function Get-Severity {
    param(
        [string]$Category,
        [string]$Code
    )
    
    # Severity mapping based on category and code patterns
    $SeverityMap = @{
        "SQL Injection" = "Critical"
        "XSS" = "High"
        "Hardcoded Credentials" = "Critical"
        "Command Injection" = "Critical"
        "Path Traversal" = "High"
        "Insecure Random" = "Medium"
        "Weak Cryptography" = "Medium"
        "Prototype Pollution" = "High"
        "Unsafe Regex" = "Medium"
        "Pickle Injection" = "High"
        "Unsafe Eval" = "High"
    }
    
    return $SeverityMap[$Category] ?? "Medium"
}

function Get-VulnerabilityDescription {
    param([string]$Category)
    
    $Descriptions = @{
        "SQL Injection" = "Potential SQL injection vulnerability detected. User input may be directly concatenated into SQL queries."
        "XSS" = "Cross-Site Scripting (XSS) vulnerability detected. User input may be directly inserted into HTML without proper sanitization."
        "Hardcoded Credentials" = "Hardcoded credentials detected in source code. This poses a significant security risk."
        "Command Injection" = "Command injection vulnerability detected. User input may be executed in system commands."
        "Path Traversal" = "Path traversal vulnerability detected. User input may be used to access files outside intended directories."
        "Insecure Random" = "Insecure random number generation detected. This may lead to predictable values."
        "Weak Cryptography" = "Weak cryptographic algorithm detected. Consider using stronger alternatives."
        "Prototype Pollution" = "Prototype pollution vulnerability detected. This may lead to object prototype manipulation."
        "Unsafe Regex" = "Unsafe regular expression detected. May be vulnerable to ReDoS attacks."
        "Pickle Injection" = "Unsafe deserialization detected. May lead to remote code execution."
        "Unsafe Eval" = "Unsafe code evaluation detected. May lead to code injection."
    }
    
    return $Descriptions[$Category] ?? "Security vulnerability detected."
}

function Get-Recommendation {
    param([string]$Category)
    
    $Recommendations = @{
        "SQL Injection" = "Use parameterized queries or prepared statements to prevent SQL injection."
        "XSS" = "Sanitize user input and use proper encoding before inserting into HTML. Consider using CSP headers."
        "Hardcoded Credentials" = "Remove hardcoded credentials and use environment variables or secure credential management."
        "Command Injection" = "Avoid executing user input in system commands. Use safe alternatives and input validation."
        "Path Traversal" = "Validate and sanitize file paths. Use whitelist approach for allowed directories."
        "Insecure Random" = "Use cryptographically secure random number generators (e.g., crypto.getRandomValues)."
        "Weak Cryptography" = "Use strong cryptographic algorithms (AES-256, SHA-256, etc.)."
        "Prototype Pollution" = "Validate input and avoid merging untrusted objects into prototypes."
        "Unsafe Regex" = "Use safe regular expressions and avoid catastrophic backtracking patterns."
        "Pickle Injection" = "Avoid using pickle for untrusted data. Use safe serialization formats like JSON."
        "Unsafe Eval" = "Avoid using eval() with untrusted input. Use safer alternatives."
    }
    
    return $Recommendations[$Category] ?? "Review and fix the security vulnerability."
}

function Get-CWE {
    param([string]$Category)
    
    $CWEMap = @{
        "SQL Injection" = "CWE-89"
        "XSS" = "CWE-79"
        "Hardcoded Credentials" = "CWE-798"
        "Command Injection" = "CWE-78"
        "Path Traversal" = "CWE-22"
        "Insecure Random" = "CWE-338"
        "Weak Cryptography" = "CWE-327"
        "Prototype Pollution" = "CWE-1321"
        "Unsafe Regex" = "CWE-1333"
        "Pickle Injection" = "CWE-502"
        "Unsafe Eval" = "CWE-94"
    }
    
    return $CWEMap[$Category] ?? "CWE-Unknown"
}

function Get-ScoreImpact {
    param([string]$Severity)
    
    $ImpactMap = @{
        "Critical" = 25
        "High" = 15
        "Medium" = 8
        "Low" = 3
    }
    
    return $ImpactMap[$Severity] ?? 5
}

function Get-RiskLevel {
    param(
        [int]$SecurityScore,
        [int]$VulnCount
    )
    
    if ($VulnCount -eq 0) { return "Secure" }
    if ($SecurityScore -lt 30) { return "Critical" }
    if ($SecurityScore -lt 50) { return "High" }
    if ($SecurityScore -lt 70) { return "Medium" }
    return "Low"
}

function Invoke-DeepSecurityScan {
    param(
        [string]$Content,
        [string]$Language
    )
    
    $DeepVulns = @()
    
    # Check for sensitive data exposure
    $SensitivePatterns = @(
        "['\"][A-Za-z0-9+/]{40,}['\"]",  # Possible API keys/tokens
        "['\"][0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{4}['\"]",  # Credit card patterns
        "['\"][A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}['\"]"  # Email addresses
    )
    
    foreach ($pattern in $SensitivePatterns) {
        $Matches = [regex]::Matches($Content, $pattern)
        foreach ($match in $Matches) {
            $Line = Get-LineNumber $Content $match.Index
            
            $DeepVulns += @{
                Type = "Sensitive Data Exposure"
                Severity = "High"
                Line = $Line
                Code = $match.Value.Trim()
                Description = "Potential sensitive data exposure detected."
                Recommendation = "Remove sensitive data from source code and use secure storage."
                CWE = "CWE-200"
                ScoreImpact = 15
            }
        }
    }
    
    return $DeepVulns
}

# Export functions
Export-ModuleMember -Function *
