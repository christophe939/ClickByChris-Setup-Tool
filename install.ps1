# =========================================================
# ClickByChris Setup Tool - Official Installer V1.0.5
# =========================================================

$Version = "V1.0.5"
$ZipUrl = "https://github.com/christophe939/ClickByChris-Setup-Tool/releases/download/$Version/ClickByChris_Setup_Tool_V1_0_5.zip"

$TempZip = "$env:TEMP\ClickByChris_Setup_Tool.zip"
$TempDir = "$env:TEMP\ClickByChris_Setup_Tool"
$TempExtract = "$TempDir\extract_temp"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "     ClickByChris Setup Tool Installer"
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/5] Nettoyage..." -ForegroundColor Yellow
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

Write-Host "[2/5] Téléchargement de la version $Version..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Host "✗ Erreur téléchargement : $_" -ForegroundColor Red
    Pause
    exit
}

Write-Host "[3/5] Extraction du ZIP..." -ForegroundColor Yellow
try {
    Expand-Archive -Path $TempZip -DestinationPath $TempExtract -Force
} catch {
    Write-Host "✗ Erreur extraction : $_" -ForegroundColor Red
    Pause
    exit
}

Write-Host "[4/5] Recherche du launcher..." -ForegroundColor Yellow
$launcherPath = Get-ChildItem -Path $TempExtract -Filter "*.cmd" -Recurse | Select-Object -First 1

if (-not $launcherPath) {
    Write-Host "✗ Launcher .cmd introuvable dans le ZIP" -ForegroundColor Red
    Pause
    exit
}

Write-Host "[5/5] Lancement du setup..." -ForegroundColor Yellow
Start-Process -FilePath $launcherPath.FullName -Verb RunAs

Write-Host ""
Write-Host "Setup lancé ! Le launcher va prendre le relais." -ForegroundColor Green
Write-Host "Fermeture du PowerShell dans 3 secondes..." -ForegroundColor Gray

Start-Sleep -Seconds 3
