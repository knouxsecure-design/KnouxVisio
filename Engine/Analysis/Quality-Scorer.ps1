function Get-QualityData($Content, $Extension, $FileSize) {
    
    # 1. القراءة المعرفية (Cognitive Stats)
    $Lines = ($Content -split "`n").Count
    $CleanCode = ($Content -replace "//.*|#.*|/\*[\s\S]*?\*/", "") # كود بدون تعليقات
    $LOC = ($CleanCode -split "`n").Count
    
    # 2. الكشف عن المكدس التقني (Tech Stack Detection)
    $Stack = New-Object System.Collections.Generic.List[string]
    if ($Content -match "useState|useEffect|jsx") { $Stack.Add("React Hook") }
    if ($Content -match "express|app\.get|app\.use") { $Stack.Add("Express.js") }
    if ($Content -match "mongoose|Schema|Model") { $Stack.Add("MongoDB") }
    if ($Content -match "tailwind|class=") { $Stack.Add("TailwindCSS") }
    if ($Content -match "def __init__|self\.") { $Stack.Add("Python OOP") }
    if ($Content -match "CmdletBinding|Param\(") { $Stack.Add("PowerShell Adv") }
    
    # 3. تحليل "رائحة الكود" (Code Smells - Deep Scan)
    $Issues = New-Object System.Collections.Generic.List[string]
    $ComplexityScore = 0
    $ActionPlan = ""
    $CodeSnippet = ""

    # >> فحص: التعقيد الحلزوني (Cyclomatic Complexity)
    $DecisionPoints = [regex]::Matches($CleanCode, "(if\s*\(|else|case|default|for|while|catch|&&|\|\||\?|or\s+|and\s+)").Count
    $ComplexityScore += $DecisionPoints

    # >> فحص: التداخل العميق (Deep Nesting - The Arrow Code)
    # البحث عن أسطر تبدأ بمسافات كثيرة جدا (دليل على if داخل for داخل if...)
    if ($CleanCode -match "`n\s{16,}[^\s]") {
        $Issues.Add("Deep Nesting Hell (>4 levels)")
        $ActionPlan = "الكود متداخل جدا ويصعب قراءته. استخدم نمط 'Guard Clauses' أو قسمه لدوال أصغر."
        $ComplexityScore += 20
        # استخراج عينة
        $CodeSnippet = [regex]::Match($Content, "(?m)^(\s{12,}.{1,100})").Value.Trim()
    }

    # >> فحص: الأرقام السحرية (Magic Numbers)
    $MagicNumCount = [regex]::Matches($CleanCode, " [=<>] \d{2,}").Count
    if ($MagicNumCount -gt 5) {
        $Issues.Add("Magic Numbers Detected ($MagicNumCount)")
        $ComplexityScore += 5
        if ($ActionPlan -eq "") { 
            $ActionPlan = "تجنب استخدام الأرقام المجردة في الشروط. استبدلها بثوابت (CONSTANTS) ذات أسماء واضحة."
            $CodeSnippet = "Example: if (status === 200) -> const HTTP_OK = 200;"
        }
    }

    # >> فحص: الدوال الطويلة (God Functions)
    if ($Lines -gt 300 -and $Extension -match "js|ts|py|cs") {
        $Issues.Add("God Class/File ($Lines Lines)")
        $ComplexityScore += 30
        if ($ActionPlan -eq "") {
            $ActionPlan = "الملف يقوم بمهام كثيرة جدا (SRP Violation). قم بتوزيع المهام على ملفات (Services/Utils) منفصلة."
        }
    }

    # 4. حسابات الصحة (Metrics Engine)
    # مؤشر القابلية للصيانة (Maintainability Index - Simulated)
    # كلما قل الرقم زادت صعوبة صيانة الكود
    $Maintainability = 100 - ($ComplexityScore * 0.5) - ($Lines / 50)
    if ($Maintainability -lt 0) { $Maintainability = 0 }

    # تقدير "زمن الإصلاح" (Technical Debt Estimation)
    # المعادلة: كل نقطة تعقيد زائدة عن 10 تكلف 15 دقيقة إصلاح
    $DebtMinutes = 0
    if ($ComplexityScore -gt 10) {
        $DebtMinutes = ($ComplexityScore - 10) * 15
    }
    $DebtTime = if ($DebtMinutes -gt 60) { "$([math]::Round($DebtMinutes/60, 1)) Hrs" } else { "$DebtMinutes Mins" }

    # 5. التقييم النهائي والتصنيف (Final Verdict)
    $TagStr = ($Stack -join ", ")
    if ($TagStr -eq "") { $TagStr = "Standard" }
    
    $Labels = New-Object System.Collections.Generic.List[string]
    if ($Issues.Count -gt 0) { $Labels.Add("⚠️ Dirty") } else { $Labels.Add("✅ Clean") }
    if ($FileSize -gt 100KB) { $Labels.Add("📦 Heavy") }
    if ($Content -match "TODO") { $Labels.Add("📌 WIP") }

    return @{
        Score = [int]$Maintainability
        ComplexityVal = $ComplexityScore
        ComplexityLabel = if ($ComplexityScore -gt 30) { "Critical" } elseif ($ComplexityScore -gt 10) { "High" } else { "Low" }
        TechStack = $TagStr
        DebtTime = $DebtTime
        Smells = ($Issues -join " | ")
        Tags = ($Labels -join " ")
        AutoFix_Title = if ($Issues.Count -gt 0) { $Issues[0] } else { "None" }
        AutoFix_Guide = $ActionPlan
        AutoFix_Snippet = $CodeSnippet
    }
}

function Detect-Layer($Path, $Ext) {
    if ($Path -match "(?i)node_modules|vendor|\.git") { return "External Libs" }
    if ($Path -match "(?i)test|spec") { return "QA/Testing" }
    if ($Path -match "(?i)core|engine|kernel|system") { return "🛑 Core System" }
    if ($Path -match "(?i)api|service|controller|handler") { return "⚙️ Business Logic" }
    if ($Path -match "(?i)component|view|ui|page") { return "🎨 Presentation" }
    if ($Path -match "(?i)util|helper|shared") { return "🛠️ Shared Utils" }
    
    if ($Ext -match "\.(json|xml|yaml|env)") { return "📄 Configuration" }
    if ($Ext -match "\.(png|jpg|svg|ico)") { return "🖼️ Assets" }
    
    return "📦 General Module"
}