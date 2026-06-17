# =========================================================
# ClickByChris Setup Tool - Official Installer
# Version : 1.0.0
# =========================================================

$Version = "v1.0.0"
$ZipUrl = "$ZipUrl = "https://github.com/christophe939/ClickByChris-Setup-Tool/releases/download/$Version/ClickByChris-Setup-Tool-v1.0.0.zip"

$TempZip = "$env:TEMP\ClickByChris_Setup_Tool.zip"
$TempDir = "$env:TEMP\ClickByChris_Setup_Tool"
$TempExtract = "$TempDir\extract_temp"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "     ClickByChris Setup Tool v1.0.0"
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

Write-Host "[4/5] Réorganisation des fichiers..." -ForegroundColor Yellow
$subFolders = @(Get-ChildItem -Path $TempExtract -Directory -ErrorAction SilentlyContinue)

if ($subFolders.Count -gt 0) {
    $mainFolder = $subFolders[0]
    Write-Host "  → Dossier détecté : $($mainFolder.Name)" -ForegroundColor Gray
    
    Get-ChildItem -Path $mainFolder.FullName -Force -ErrorAction SilentlyContinue | ForEach-Object {
        Move-Item -Path $_.FullName -Destination $TempDir -Force -ErrorAction SilentlyContinue
    }
}

Remove-Item $TempExtract -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "[5/5] Lancement de l'outil..." -ForegroundColor Yellow

$cmdFiles = @(Get-ChildItem -Path $TempDir -Filter "*.cmd" -ErrorAction SilentlyContinue)

if ($cmdFiles.Count -gt 0) {
    $launcher = $cmdFiles[0]
    Write-Host "✓ Launcher trouvé : $($launcher.Name)" -ForegroundColor Green
    Write-Host ""
    Start-Process -FilePath $launcher.FullName -WorkingDirectory $TempDir
} else {
    Write-Host "✗ Aucun fichier .cmd trouvé !" -ForegroundColor Red
    Write-Host ""
    Write-Host "Fichiers disponibles :" -ForegroundColor Yellow
    Get-ChildItem -Path $TempDir | Select-Object Name
    Pause
    exit
}

Write-Host "L'outil se lance..." -ForegroundColor Green
Start-Sleep -Seconds 2
