# =========================================================
# ClickByChris Setup Tool - Official Installer
# =========================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$ProgressPreference = 'SilentlyContinue'

# Lecture dynamique de la version depuis version.json
$VersionManifestUrl = "https://raw.githubusercontent.com/christophe939/ClickByChris-Setup-Tool/main/version.json"

$TempZip = "$env:TEMP\ClickByChris_Setup_Tool.zip"
$TempDir = "$env:TEMP\ClickByChris_Setup_Tool"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "     ClickByChris Setup Tool - Installer" -ForegroundColor White
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Etape 1 : Lecture version.json
Write-Host "[1/5] Récupération des informations de version..." -ForegroundColor White

try {
    $manifest = Invoke-RestMethod -Uri $VersionManifestUrl -UseBasicParsing -TimeoutSec 10
    $Version     = $manifest.version
    $ZipUrl      = $manifest.zip_url
    $LauncherName = $manifest.launcher
    Write-Host "      Version détectée : $Version" -ForegroundColor Green
}
catch {
    Write-Host "      Impossible de lire version.json. Vérifiez votre connexion." -ForegroundColor Red
    Pause
    exit 1
}

# Etape 2 : Téléchargement
Write-Host "[2/5] Téléchargement de la dernière version..." -ForegroundColor White

try {
    Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing
    Write-Host "      Téléchargement terminé." -ForegroundColor Green
}
catch {
    Write-Host "      Echec du téléchargement : $($_.Exception.Message)" -ForegroundColor Red
    Pause
    exit 1
}

# Etape 3 : Extraction
Write-Host "[3/5] Extraction des fichiers..." -ForegroundColor White

try {
    if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    Expand-Archive -Path $TempZip -DestinationPath $TempDir -Force
    Write-Host "      Extraction réussie." -ForegroundColor Green
}
catch {
    Write-Host "      Echec de l'extraction : $($_.Exception.Message)" -ForegroundColor Red
    Pause
    exit 1
}

# Etape 4 : Recherche launcher
Write-Host "[4/5] Recherche du launcher..." -ForegroundColor White

$Launcher = Get-ChildItem -Path $TempDir -Recurse -Filter "*.cmd" | Select-Object -First 1

if ($Launcher) {
    Write-Host "      Launcher détecté : $($Launcher.Name)" -ForegroundColor Green
}
else {
    Write-Host "      Launcher introuvable." -ForegroundColor Red
    Pause
    exit 1
}

# Etape 5 : Lancement
Write-Host "[5/5] Lancement de ClickByChris Setup Tool..." -ForegroundColor White

Start-Process $Launcher.FullName

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "     Installation terminée avec succès !" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
