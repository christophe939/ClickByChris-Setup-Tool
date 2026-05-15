# =========================================================
# ClickByChris Setup Tool - Official Installer
# =========================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'

$VersionManifestUrl = "https://raw.githubusercontent.com/christophe939/ClickByChris-Setup-Tool/main/version.json"
$TempZip = "$env:TEMP\ClickByChris_Setup_Tool.zip"
$TempDir = "$env:TEMP\ClickByChris_Setup_Tool"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "     ClickByChris Setup Tool - Installer" -ForegroundColor White
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# -------------------------
# Etape 1 : Lecture version.json
# -------------------------
Write-Host "[1/5] Recuperation des informations de version..." -ForegroundColor Yellow

try {
    $manifest = Invoke-RestMethod -Uri $VersionManifestUrl -UseBasicParsing -TimeoutSec 10
    $Version  = $manifest.version
    $ZipUrl   = $manifest.download_url
    Write-Host "      Version detectee : $Version" -ForegroundColor Green
}
catch {
    Write-Host "      Impossible de lire version.json." -ForegroundColor Red
    Write-Host "      Erreur : $($_.Exception.Message)" -ForegroundColor Red
    Pause
    exit 1
}

if ([string]::IsNullOrWhiteSpace($ZipUrl)) {
    Write-Host "      Erreur : download_url vide dans version.json" -ForegroundColor Red
    Pause
    exit 1
}

# -------------------------
# Etape 2 : Telechargement
# -------------------------
Write-Host "[2/5] Telechargement de la derniere version..." -ForegroundColor Yellow

try {
    Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing
    Write-Host "      Telechargement termine." -ForegroundColor Green
}
catch {
    Write-Host "      Echec du telechargement : $($_.Exception.Message)" -ForegroundColor Red
    Pause
    exit 1
}

# -------------------------
# Etape 3 : Extraction
# -------------------------
Write-Host "[3/5] Extraction des fichiers..." -ForegroundColor Yellow

try {
    if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    Expand-Archive -Path $TempZip -DestinationPath $TempDir -Force
    Write-Host "      Extraction reussie." -ForegroundColor Green
}
catch {
    Write-Host "      Echec de l extraction : $($_.Exception.Message)" -ForegroundColor Red
    Pause
    exit 1
}

# -------------------------
# Etape 4 : Recherche launcher
# -------------------------
Write-Host "[4/5] Recherche du launcher..." -ForegroundColor Yellow

$Launcher = Get-ChildItem -Path $TempDir -Recurse -Filter "*.cmd" | Select-Object -First 1

if ($Launcher) {
    Write-Host "      Launcher detecte : $($Launcher.Name)" -ForegroundColor Green
}
else {
    Write-Host "      Launcher introuvable dans le ZIP." -ForegroundColor Red
    Pause
    exit 1
}

# -------------------------
# Etape 5 : Lancement
# -------------------------
Write-Host "[5/5] Lancement de ClickByChris Setup Tool..." -ForegroundColor Yellow

Start-Process $Launcher.FullName

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "     Installation terminee avec succes !" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
