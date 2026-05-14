# =========================================================
# ClickByChris Setup Tool - Official Installer
# =========================================================

$Version = "V1.0.3"

$ZipUrl = "https://github.com/christophe939/ClickByChris-Setup-Tool/releases/download/$Version/ClickByChris_Setup_Tool_V1_0_3.zip"

$TempZip = "$env:TEMP\ClickByChris_Setup_Tool.zip"
$TempDir = "$env:TEMP\ClickByChris_Setup_Tool"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "     ClickByChris Setup Tool Installer"
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/4] Downloading latest version..." -ForegroundColor Yellow

Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip

Write-Host "[2/4] Extracting files..." -ForegroundColor Yellow

if (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse -Force
}

New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

Expand-Archive -Path $TempZip -DestinationPath $TempDir -Force

Write-Host "[3/4] Launching ClickByChris..." -ForegroundColor Yellow

$Launcher = Get-ChildItem -Path $TempDir -Recurse -Filter "*.cmd" | Select-Object -First 1

if ($Launcher) {
    Start-Process $Launcher.FullName
}
else {
    Write-Host ""
    Write-Host "Launcher not found." -ForegroundColor Red
    Pause
    exit
}

Write-Host "[4/4] Done." -ForegroundColor Green
