[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# =========================================================
# ClickByChris Setup Tool - Official Installer
# Auteur  : Christophe (ClickByChris)
# Version : 1.0.3 - 2025
# =========================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$VersionManifestUrl = "https://raw.githubusercontent.com/christophe939/ClickByChris-Setup-Tool/main/version.json"

$TempZip = Join-Path $env:TEMP "ClickByChris_Setup_Tool.zip"
$TempDir = Join-Path $env:TEMP "ClickByChris_Setup_Tool"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   ClickByChris Setup Tool - Installer"   -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------
# 1. Récupération du manifest version.json
# ---------------------------------------------------------
Write-Host "[1/5] Récupération des informations de version..." -ForegroundColor Yellow

try {
    $manifest = Invoke-RestMethod -Uri $VersionManifestUrl -UseBasicParsing
    $Version  = $manifest.version
    $ZipUrl   = $manifest.download_url
    Write-Host "      Version détectée : $Version" -ForegroundColor Green
}
catch {
    Write-Host "      Impossible de lire version.json - Utilisation du lien de secours." -ForegroundColor Yellow
    $Version = "V1.0.3"
    $ZipUrl  = "https://github.com/christophe939/ClickByChris-Setup-Tool/releases/download/$Version/ClickByChris_Setup_Tool_V1_0_3.zip"
}

# ---------------------------------------------------------
# 2. Téléchargement du ZIP
# ---------------------------------------------------------
Write-Host "[2/5] Téléchargement de la dernière version..." -ForegroundColor Yellow

try {
    Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing
    Write-Host "      Téléchargement terminé." -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "Erreur lors du téléchargement : $($_.Exception.Message)" -ForegroundColor Red
    Pause
    exit 1
}

# ---------------------------------------------------------
# 3. Extraction
# ---------------------------------------------------------
Write-Host "[3/5] Extraction des fichiers..." -ForegroundColor Yellow

if (Test-Path $TempDir) {
    Remove-Item $TempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    Expand-Archive -Path $TempZip -DestinationPath $TempDir -Force
    Write-Host "      Extraction réussie." -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "Erreur lors de l'extraction : $($_.Exception.Message)" -ForegroundColor Red
    Pause
    exit 1
}

# ---------------------------------------------------------
# 4. Recherche du launcher CMD
# ---------------------------------------------------------
Write-Host "[4/5] Recherche du launcher..." -ForegroundColor Yellow

$Launcher = Get-ChildItem -Path $TempDir -Recurse -Filter "*.cmd" | Select-Object -First 1

if (-not $Launcher) {
    Write-Host ""
    Write-Host "Launcher .cmd introuvable dans l'archive." -ForegroundColor Red
    Pause
    exit 1
}

Write-Host "      Launcher détecté : $($Launcher.Name)" -ForegroundColor Green

# ---------------------------------------------------------
# 5. Lancement
# ---------------------------------------------------------
Write-Host "[5/5] Lancement de ClickByChris Setup Tool..." -ForegroundColor Yellow
Write-Host ""

Start-Process -FilePath $Launcher.FullName

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "   Installation terminée avec succès !"   -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
