# ═══════════════════════════════════════════════════════════════════════════════
# تنزيل وتشغيل برنامجي الشخصي (نسخة آمنة ومحسّنة)
# ═══════════════════════════════════════════════════════════════════════════════

# متغيرات التهيئة
$Owner = "alhlhli"         
$Repo = "pro3mer"          # اسم المستودع
$AssetName = "pro3mer.exe"        # اسم الملف التنفيذي
$TargetDir = "$env:USERPROFILE\Downloads\Office"
$TempFile = "$env:TEMP\$AssetName"
$ExpectedHash = "B9A952A8F64F02BD79A21902D61C17938FD705B36BEACCCB96C4C2E63E5E548E"  # ضع الـ Hash المتوقع هنا

# ═══════════════════════════════════════════════════════════════════════════════
# 1. الحصول على رابط التنزيل من GitHub Releases
# ═══════════════════════════════════════════════════════════════════════════════
Write-Host "🔍 جاري البحث عن أحدث إصدار..." -ForegroundColor Cyan

try {
    $ApiUrl = "https://api.github.com/repos/$Owner/$Repo/releases/latest"
    $ReleaseData = Invoke-RestMethod -Uri $ApiUrl -Headers @{"User-Agent"="PowerShell"}
    
    # البحث عن الملف في الإصدار
    $Asset = $ReleaseData.assets | Where-Object { $_.name -eq $AssetName }
    
    if (-not $Asset) {
        Write-Host "❌ لم يتم العثور على الملف $AssetName في الإصدار الأخير!" -ForegroundColor Red
        Write-Host "📋 الملفات المتوفرة:" -ForegroundColor Yellow
        $ReleaseData.assets | ForEach-Object { Write-Host "   - $($_.name)" }
        exit 1
    }
    
    $DownloadUrl = $Asset.browser_download_url
    $Version = $ReleaseData.tag_name
    Write-Host "✅ تم العثور على الإصدار $Version" -ForegroundColor Green
    
} catch {
    Write-Host "❌ فشل الاتصال بـ GitHub: $_" -ForegroundColor Red
    exit 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# 2. تنزيل الملف مع تقدم
# ═══════════════════════════════════════════════════════════════════════════════
Write-Host "📥 جاري تنزيل الملف..." -ForegroundColor Cyan

try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempFile -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ تم التنزيل بنجاح" -ForegroundColor Green
} catch {
    Write-Host "❌ فشل التنزيل: $_" -ForegroundColor Red
    exit 1
}

# ═══════════════════════════════════════════════════════════════════════════════
# 3. التحقق من سلامة الملف (HASH)
# ═══════════════════════════════════════════════════════════════════════════════
Write-Host "🔐 جاري التحقق من سلامة الملف..." -ForegroundColor Cyan

$ActualHash = (Get-FileHash $TempFile -Algorithm SHA256).Hash

if ($ExpectedHash -ne "IGNORE_HASH_CHECK") {  # اترك "IGNORE_HASH_CHECK" لتجاهل التحقق مؤقتاً
    if ($ActualHash -ne $ExpectedHash) {
        Write-Host "❌ فشل التحقق من السلامة!" -ForegroundColor Red
        Write-Host "   المتوقع: $ExpectedHash" -ForegroundColor Yellow
        Write-Host "   الموجود: $ActualHash" -ForegroundColor Yellow
        Remove-Item $TempFile -Force
        exit 1
    }
    Write-Host "✅ التحقق من السلامة ناجح" -ForegroundColor Green
} else {
    Write-Host "⚠️  تم تخطي التحقق من HASH (للاختبار فقط)" -ForegroundColor Yellow
}

# ═══════════════════════════════════════════════════════════════════════════════
# 4. التحقق من التوقيع الرقمي
# ═══════════════════════════════════════════════════════════════════════════════
Write-Host "🛡️ جاري التحقق من التوقيع الرقمي..." -ForegroundColor Cyan

$Signature = Get-AuthenticodeSignature -FilePath $TempFile

if ($Signature.Status -eq "Valid") {
    Write-Host "✅ التوقيع الرقمي صحيح!" -ForegroundColor Green
    Write-Host "   الموقّع: $($Signature.SignerCertificate.Subject)" -ForegroundColor Gray
    Write-Host "   التاريخ: $($Signature.SignerCertificate.NotBefore) - $($Signature.SignerCertificate.NotAfter)" -ForegroundColor Gray
} else {
    Write-Host "⚠️ تحذير: التوقيع الرقمي غير صالح أو مفقود!" -ForegroundColor Yellow
    Write-Host "   الحالة: $($Signature.Status)" -ForegroundColor Yellow
    
    # يمكنك إما التوقف هنا أو المتابعة مع تحذير
    $choice = Read-Host "هل تريد المتابعة رغم ذلك؟ (y/n)"
    if ($choice -ne 'y') {
        Remove-Item $TempFile -Force
        exit 1
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# 5. إنشاء المجلد ونقل الملف
# ═══════════════════════════════════════════════════════════════════════════════
if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

# نسخ الملف إلى المجلد النهائي
Copy-Item -Path $TempFile -Destination "$TargetDir\$AssetName" -Force

# ═══════════════════════════════════════════════════════════════════════════════
# 6. تشغيل البرنامج بصلاحيات المسؤول
# ═══════════════════════════════════════════════════════════════════════════════
Write-Host "🚀 جاري تشغيل البرنامج..." -ForegroundColor Cyan

try {
    $Process = Start-Process -FilePath "$TargetDir\$AssetName" -WorkingDirectory $TargetDir -Verb RunAs -PassThru
    Write-Host "✅ تم تشغيل البرنامج بنجاح (PID: $($Process.Id))" -ForegroundColor Green
} catch {
    Write-Host "❌ فشل تشغيل البرنامج: $_" -ForegroundColor Red
}

# ═══════════════════════════════════════════════════════════════════════════════
# 7. تنظيف الملفات المؤقتة
# ═══════════════════════════════════════════════════════════════════════════════
if (Test-Path $TempFile) {
    Remove-Item $TempFile -Force
    Write-Host "🧹 تم حذف الملفات المؤقتة" -ForegroundColor Gray
}

Write-Host "✨ اكتمل التنفيذ!" -ForegroundColor Green