# =========================================================
# ClickByChris Setup Tool - Official Installer V1.0.5
# =========================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'

$Version = "V1.0.5"
$RepoUrl = "https://github.com/christophe939/ClickByChris-Setup-Tool"
$ReleaseUrl = "$RepoUrl/releases/download/$Version/ClickByChris_Setup_Tool_V1_0_5.zip"

$TempDir = "$env:TEMP\ClickByChris_Setup_Tool"
$TempZip = "$TempDir\ClickByChris.zip"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  ClickByChris Setup Tool Installer" -ForegroundColor Cyan
Write-Host "  Version: $Version" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/5] Nettoyage..." -ForegroundColor Yellow
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

Write-Host "[2/5] Téléchargement de la version $Version..." -ForegroundColor Yellow
try {
    Write-Host "  Source: $ReleaseUrl" -ForegroundColor Gray
    Invoke-WebRequest -Uri $ReleaseUrl -OutFile $TempZip -UseBasicParsing -ErrorAction Stop
    Write-Host "  ✓ Téléchargement réussi" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Erreur téléchargement: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Vérifications:" -ForegroundColor Yellow
    Write-Host "  1. Vérifie ta connexion Internet"
    Write-Host "  2. Vérifie que la release existe: $ReleaseUrl"
    Write-Host "  3. Relance le script"
    Write-Host ""
    Pause
    exit 1
}

Write-Host "[3/5] Extraction du ZIP..." -ForegroundColor Yellow
try {
    Expand-Archive -Path $TempZip -DestinationPath $TempDir -Force -ErrorAction Stop
    Write-Host "  ✓ Extraction réussie" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Erreur extraction: $_" -ForegroundColor Red
    Pause
    exit 1
}

Write-Host "[4/5] Recherche du launcher..." -ForegroundColor Yellow
$launcherPath = Get-ChildItem -Path $TempDir -Filter "Launch_*.cmd" -Recurse | Select-Object -First 1

if (-not $launcherPath) {
    Write-Host "  ✗ Launcher .cmd introuvable dans le ZIP" -ForegroundColor Red
    Write-Host "  Contenu du ZIP:" -ForegroundColor Yellow
    Get-ChildItem -Path $TempDir -Recurse | Select-Object Name
    Pause
    exit 1
}

Write-Host "  ✓ Launcher trouvé: $($launcherPath.Name)" -ForegroundColor Green

Write-Host "[5/5] Lancement du setup..." -ForegroundColor Yellow
try {
    Start-Process -FilePath $launcherPath.FullName -Verb RunAs -ErrorAction Stop
    Write-Host "  ✓ Setup lancé avec succès" -ForegroundColor Green
} catch {
    Write-Host "  ✗ Erreur lancement: $_" -ForegroundColor Red
    Pause
    exit 1
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Le setup va prendre le relais..." -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Start-Sleep -Seconds 2
