function Get-FileRisk($Content, $Lines, $Extension) {
    $ThreatScore = 0
    $DetectedThreats = New-Object System.Collections.Generic.List[string]
    $AttackVector = "None"
    $ComplianceTag = "Compliant"
    $Remediation = ""
    $ForensicNote = ""

    # 1. تحليل الأسرار باستخدام "الإنتروبيا النصية" (Entropy Heuristics)
    # البحث عن سلاسل نصية طويلة وعشوائية (مؤشر قوي على مفاتيح API مخفية)
    # Regex يبحث عن سلاسل MixAlphanumeric طويلة (أكثر من 30 حرف)
    $HighEntropyMatches = [regex]::Matches($Content, "['`""][A-Za-z0-9+/=]{30,}['`""]")
    if ($HighEntropyMatches.Count -gt 0) {
        # فلترة لتقليل الخطأ (استبعاد الروابط والمسارات)
        $SuspiciousKey = $HighEntropyMatches[0].Value
        if ($SuspiciousKey -notmatch "http|\\|/") {
            $ThreatScore += 25
            $DetectedThreats.Add("High Entropy String (Potential Key Leak)")
            $AttackVector = "Data Exposure"
            $Remediation = "وجدنا نصوصا مشفرة/عشوائية صريحة. تأكد أنها ليست Secrets."
            $ForensicNote = "Suspect: $SuspiciousKey"
        }
    }

    # 2. كاشف الاتصالات الصلبة (Hardcoded Infrastructure)
    # البحث عن عناوين IP (غير الـ Localhost)
    if ($Content -match "\b(?!(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.))\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b") {
        if ($Content -notmatch "127.0.0.1") {
            $ThreatScore += 15
            $DetectedThreats.Add("Hardcoded Public IP")
            $ComplianceTag = "Infrastructure Risk"
        }
    }
    
    # 3. مصفوفة OWASP (التصنيف العالمي)
    $Sanitized = $Content -replace '\s+', ' '
    
    # >> A01: Broken Access Control
    if ($Sanitized -match "(admin=true|role:\s*'admin'|bypass_auth|chmod 777)") {
        $ThreatScore += 30
        $DetectedThreats.Add("OWASP: Broken Access Control")
        $AttackVector = "Privilege Escalation"
    }

    # >> A03: Injection (SQL/Command/Code)
    $InjectPats = "eval\(|exec\(|system\(|shell_exec|Start-Process|xp_cmdshell|Select\s+\*\s+from.*(\+|'|\"")"
    if ($Content -match $InjectPats) {
        $ThreatScore += 40
        $DetectedThreats.Add("OWASP: Injection Vulnerability")
        $AttackVector = "RCE / SQLi"
        $Remediation = "تعقيم المدخلات (Input Sanitization) أمر حتمي هنا."
    }

    # >> A07: Identification Failures (Hardcoded Credentials)
    if ($Content -match "(password|passwd|pwd|secret|api_key|token)\s*[:=]\s*['`"][^\s]+['`"]") {
        $ThreatScore += 50
        $DetectedThreats.Add("OWASP: Credential Leakage")
        $AttackVector = "Identity Theft"
        $ComplianceTag = "Critical Non-Compliance"
        $Remediation = "انقل هذه القيم فورا إلى Vault أو .env ولا ترفعها للـ Git."
    }

    # 4. الممارسات السيئة (Code Rot)
    if ($Content -match "TODO.*(fix|remove|hack|later)") {
        $ThreatScore += 5
        $DetectedThreats.Add("Security Debt (TODO comments)")
    }
    if ($Content -match "console\.log\(|print\(") {
        # ليس خطرا لكنه ممارسة سيئة في الإنتاج (Data Leakage possibility)
        $ThreatScore += 2
        $DetectedThreats.Add("Debug Info Leftover")
    }

    # 5. الحكم النهائي (The Verdict)
    $Verdict = "Stable"
    $Level = 0 # 0=Safe, 1=Low, 2=Med, 3=High, 4=Crit
    
    if ($ThreatScore -ge 50) { 
        $Verdict = "CRITICAL"
        $Level = 4
    } elseif ($ThreatScore -ge 30) {
        $Verdict = "High Risk"
        $Level = 3
    } elseif ($ThreatScore -ge 15) {
        $Verdict = "Warning"
        $Level = 2
    } elseif ($ThreatScore -gt 0) {
        $Verdict = "Notice"
        $Level = 1
    }

    if ($Remediation -eq "" -and $Level -gt 0) {
        $Remediation = "قم بمراجعة السطور المشار إليها يدويا."
    }

    return @{
        Verdict = $Verdict
        RiskLevel = $Level
        RiskScore = $ThreatScore
        Flags = ($DetectedThreats -join " | ")
        Vector = $AttackVector
        Standard = $ComplianceTag
        Solution = $Remediation
        ForensicEvidence = $ForensicNote
    }
}