# =========================================================
# ClickByChris Setup Tool - Auto-Config Windows
# Auteur  : Christophe (ClickByChris)
# Version : 1.0.0
# Date    : 2026-06-16
# Repository : https://github.com/christophe939/ClickByChris-Setup-Tool
# =========================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationCore

$ProgressPreference = 'SilentlyContinue'

# VERSION GLOBALE
$Script:CurrentVersion = "1.0.0"
$Script:VersionManifestUrl = "https://raw.githubusercontent.com/christophe939/ClickByChris-Setup-Tool/main/version.json"

# =========================================================
# INITIALISATION DES RESULTATS
# =========================================================
$Script:ActionResults = @()
$Script:CurrentReportTitle = ""

# =========================================================
# EXECUTION REPORT MANAGEMENT
# =========================================================

function Start-ExecutionReport {
    param([string]$Title = "Execution")
    $Script:ActionResults = @()
    $Script:CurrentReportTitle = $Title
    Write-Log "============================================="
    Write-Log "Debut du rapport : $Title"
    Write-Log "============================================="
}

function Add-ExecutionResult {
    param(
        [string]$Name,
        [ValidateSet("OK","WARN","ERROR","SKIP")]
        [string]$Status,
        [string]$Detail = ""
    )

    if (-not $Script:ActionResults) {
        $Script:ActionResults = @()
    }

    $Script:ActionResults += [PSCustomObject]@{
        Time   = (Get-Date).ToString("HH:mm:ss")
        Name   = $Name
        Status = $Status
        Detail = $Detail
    }

    switch ($Status) {
        "OK"    { Write-Log "[✅ OK]      $Name - $Detail" "INFO" }
        "WARN"  { Write-Log "[⚠️  WARN]   $Name - $Detail" "WARN" }
        "ERROR" { Write-Log "[❌ ERROR]  $Name - $Detail" "ERROR" }
        "SKIP"  { Write-Log "[⏭️  SKIP]   $Name - $Detail" "WARN" }
    }
}

function Show-ExecutionSummary {
    param([string]$Title = $Script:CurrentReportTitle)

    if (-not $Script:ActionResults -or $Script:ActionResults.Count -eq 0) {
        Write-Log "⚠️  Aucun resultat a afficher pour : $Title" "WARN"
        return
    }

    $ok   = @($Script:ActionResults | Where-Object { $_.Status -eq "OK"    }).Count
    $warn = @($Script:ActionResults | Where-Object { $_.Status -eq "WARN"  }).Count
    $err  = @($Script:ActionResults | Where-Object { $_.Status -eq "ERROR" }).Count
    $skip = @($Script:ActionResults | Where-Object { $_.Status -eq "SKIP"  }).Count

    Write-Log "============== RESUME : $Title =============="
    foreach ($r in $Script:ActionResults) {
        switch ($r.Status) {
            "OK"    { Write-Log "[✅] $($r.Name) : $($r.Detail)" "OK"   }
            "WARN"  { Write-Log "[⚠️ ] $($r.Name) : $($r.Detail)" "WARN" }
            "ERROR" { Write-Log "[❌] $($r.Name) : $($r.Detail)" "ERROR"}
            "SKIP"  { Write-Log "[⏭️ ] $($r.Name) : $($r.Detail)" "WARN" }
        }
    }
    Write-Log "Bilan : $ok OK / $warn avertissement(s) / $err erreur(s) / $skip ignore(s)"
    Write-Log "============================================="

    $csvPath = ""
    try {
        Ensure-Dir $Script:LogsRoot
        $safeName = ($Title -replace '[^\w\- ]', '').Trim() -replace '\s+', '_'
        if ([string]::IsNullOrWhiteSpace($safeName)) { $safeName = "Rapport" }
        $csvPath = Join-Path $Script:LogsRoot ("rapport_" + $safeName + "_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".csv")
        $Script:ActionResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log "✅ Rapport CSV exporte : $csvPath"
    }
    catch {
        Write-Log "⚠️  Export CSV impossible : $($_.Exception.Message)" "WARN"
    }

    Show-ExecutionSummaryDialog -Title $Title -Results $Script:ActionResults -CsvPath $csvPath
}

function Show-ExecutionSummaryDialog {
    param(
        [string]$Title,
        [object[]]$Results,
        [string]$CsvPath = ""
    )

    if (-not $Results -or $Results.Count -eq 0) { return }

    try {
        $total = $Results.Count
        $ok    = @($Results | Where-Object { $_.Status -eq "OK"    }).Count
        $warn  = @($Results | Where-Object { $_.Status -eq "WARN"  }).Count
        $err   = @($Results | Where-Object { $_.Status -eq "ERROR" }).Count
        $skip  = @($Results | Where-Object { $_.Status -eq "SKIP"  }).Count

        $failedNames = @($Results | Where-Object { $_.Status -eq "ERROR" } | Select-Object -ExpandProperty Name)
        $failedStr   = if ($failedNames.Count -gt 0) { $failedNames -join ", " } else { "" }

        $dureeStr = ""
        try {
            $first = $Results | Select-Object -First 1
            $last  = $Results | Select-Object -Last  1
            if ($first -and $last -and $first.Time -and $last.Time) {
                $t1   = [datetime]::ParseExact($first.Time, "HH:mm:ss", $null)
                $t2   = [datetime]::ParseExact($last.Time,  "HH:mm:ss", $null)
                if ($t2 -lt $t1) { $t2 = $t2.AddDays(1) }
                $span = $t2 - $t1
                $dureeStr = "$([int]$span.TotalMinutes)min $($span.Seconds)s"
            }
        } catch { }

        if ($err -gt 0) {
            $bandeauBg    = [System.Drawing.Color]::FromArgb(80,20,20)
            $bandeauTitle = "❌ TERMINE AVEC ERREURS"
            $bandeauColor = [System.Drawing.Color]::FromArgb(255,100,100)
        } elseif ($warn -gt 0) {
            $bandeauBg    = [System.Drawing.Color]::FromArgb(60,50,10)
            $bandeauTitle = "⚠️  TERMINE AVEC AVERTISSEMENTS"
            $bandeauColor = [System.Drawing.Color]::FromArgb(255,210,90)
        } else {
            $bandeauBg    = [System.Drawing.Color]::FromArgb(15,50,30)
            $bandeauTitle = "✅ TERMINE AVEC SUCCES"
            $bandeauColor = [System.Drawing.Color]::FromArgb(90,230,140)
        }

        $summaryForm = New-Object System.Windows.Forms.Form
        $summaryForm.Text            = "Rapport - $Title"
        $summaryForm.StartPosition   = "CenterScreen"
        $summaryForm.Size            = New-Object System.Drawing.Size(960,700)
        $summaryForm.MinimumSize     = New-Object System.Drawing.Size(860,600)
        $summaryForm.BackColor       = [System.Drawing.Color]::FromArgb(10,10,14)
        $summaryForm.ForeColor       = [System.Drawing.Color]::WhiteSmoke
        $summaryForm.FormBorderStyle = "FixedDialog"
        $summaryForm.MaximizeBox     = $false
        $summaryForm.MinimizeBox     = $false
        $summaryForm.TopMost         = $true

        $bandeau = New-Object System.Windows.Forms.Panel
        $bandeau.Location  = [System.Drawing.Point]::new(16,12)
        $bandeau.Size      = New-Object System.Drawing.Size(912,120)
        $bandeau.BackColor = $bandeauBg
        $bandeau.BorderStyle = "FixedSingle"
        $summaryForm.Controls.Add($bandeau)

        $lblTitle = New-Object System.Windows.Forms.Label
        $lblTitle.Text      = $bandeauTitle
        $lblTitle.Location  = [System.Drawing.Point]::new(20,12)
        $lblTitle.Size      = New-Object System.Drawing.Size(870,36)
        $lblTitle.Font      = New-Object System.Drawing.Font("Segoe UI Semibold",16,[System.Drawing.FontStyle]::Bold)
        $lblTitle.ForeColor = $bandeauColor
        $lblTitle.AutoSize  = $false
        $bandeau.Controls.Add($lblTitle)

        $ligne1 = if ($err -gt 0) {
            "  ✅ Reussis : $ok/$total     ❌ Echoues : $err/$total  →  $failedStr"
        } else {
            "  ✅ Reussis : $ok/$total     ⚠️  Avertissements : $warn     ⏭️  Ignores : $skip"
        }
        $lblStats = New-Object System.Windows.Forms.Label
        $lblStats.Text      = $ligne1
        $lblStats.Location  = [System.Drawing.Point]::new(20,52)
        $lblStats.Size      = New-Object System.Drawing.Size(870,24)
        $lblStats.Font      = New-Object System.Drawing.Font("Segoe UI",11)
        $lblStats.ForeColor = [System.Drawing.Color]::WhiteSmoke
        $lblStats.AutoSize  = $false
        $bandeau.Controls.Add($lblStats)

        $ligne2 = if ($dureeStr) { "  ⏱️  Duree totale : $dureeStr" } else { "  ⏱️  Duree : non disponible" }
        $lblDuree = New-Object System.Windows.Forms.Label
        $lblDuree.Text      = $ligne2
        $lblDuree.Location  = [System.Drawing.Point]::new(20,80)
        $lblDuree.Size      = New-Object System.Drawing.Size(870,24)
        $lblDuree.Font      = New-Object System.Drawing.Font("Segoe UI",11)
        $lblDuree.ForeColor = [System.Drawing.Color]::Gainsboro
        $lblDuree.AutoSize  = $false
        $bandeau.Controls.Add($lblDuree)

        $grid = New-Object System.Windows.Forms.DataGridView
        $grid.Location             = [System.Drawing.Point]::new(16,144)
        $grid.Size                 = New-Object System.Drawing.Size(912,420)
        $grid.Anchor               = "Top,Bottom,Left,Right"
        $grid.BackgroundColor      = [System.Drawing.Color]::FromArgb(32,32,40)
        $grid.GridColor            = [System.Drawing.Color]::FromArgb(50,50,62)
        $grid.BorderStyle          = "None"
        $grid.RowHeadersVisible    = $false
        $grid.AllowUserToAddRows   = $false
        $grid.AllowUserToDeleteRows = $false
        $grid.ReadOnly             = $true
        $grid.SelectionMode        = "FullRowSelect"
        $grid.AutoSizeRowsMode     = "AllCells"
        $grid.EnableHeadersVisualStyles = $false
        $grid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(24,24,32)
        $grid.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::WhiteSmoke
        $grid.ColumnHeadersDefaultCellStyle.Font      = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
        $grid.DefaultCellStyle.BackColor              = [System.Drawing.Color]::FromArgb(32,32,40)
        $grid.DefaultCellStyle.ForeColor              = [System.Drawing.Color]::WhiteSmoke
        $grid.DefaultCellStyle.SelectionBackColor     = [System.Drawing.Color]::FromArgb(126,87,255)
        $grid.DefaultCellStyle.SelectionForeColor     = [System.Drawing.Color]::WhiteSmoke
        $grid.DefaultCellStyle.WrapMode               = "True"
        $grid.DefaultCellStyle.Padding                = New-Object System.Windows.Forms.Padding(4,2,4,2)

        [void]$grid.Columns.Add("Time",   "Heure")
        [void]$grid.Columns.Add("Status", "Etat")
        [void]$grid.Columns.Add("Name",   "Action")
        [void]$grid.Columns.Add("Detail", "Detail")
        $grid.Columns[0].Width        = 70
        $grid.Columns[1].Width        = 80
        $grid.Columns[2].Width        = 220
        $grid.Columns[3].AutoSizeMode = "Fill"

        foreach ($r in $Results) {
            [void]$grid.Rows.Add($r.Time, $r.Status, $r.Name, $r.Detail)
            $rowIndex = $grid.Rows.Count - 1
            $row = $grid.Rows[$rowIndex]
            switch ($r.Status) {
                "OK"    { $row.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(90,230,140)  }
                "WARN"  { $row.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(255,210,90)  }
                "ERROR" { $row.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(255,100,100) }
                "SKIP"  { $row.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(190,190,205) }
            }
        }
        $summaryForm.Controls.Add($grid)

        $csvLbl = New-Object System.Windows.Forms.Label
        $csvLbl.Text      = if ([string]::IsNullOrWhiteSpace($CsvPath)) { "Rapport CSV : non exporte" } else { "Rapport CSV : $CsvPath" }
        $csvLbl.Location  = [System.Drawing.Point]::new(16,574)
        $csvLbl.Size      = New-Object System.Drawing.Size(700,22)
        $csvLbl.Anchor    = "Left,Right,Bottom"
        $csvLbl.Font      = New-Object System.Drawing.Font("Segoe UI",8)
        $csvLbl.ForeColor = [System.Drawing.Color]::Gainsboro
        $summaryForm.Controls.Add($csvLbl)

        $btnOpenLogs = New-Object System.Windows.Forms.Button
        $btnOpenLogs.Text      = "📂 Ouvrir Logs"
        $btnOpenLogs.Size      = New-Object System.Drawing.Size(130,38)
        $btnOpenLogs.Location  = [System.Drawing.Point]::new(746,618)
        $btnOpenLogs.Anchor    = "Right,Bottom"
        $btnOpenLogs.FlatStyle = "Flat"
        $btnOpenLogs.FlatAppearance.BorderSize = 0
        $btnOpenLogs.BackColor = [System.Drawing.Color]::FromArgb(61,157,234)
        $btnOpenLogs.ForeColor = [System.Drawing.Color]::Black
        $btnOpenLogs.Font      = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
        $btnOpenLogs.Cursor    = [System.Windows.Forms.Cursors]::Hand
        $btnOpenLogs.Add_Click({ 
            try { Start-Process $Script:LogsRoot } 
            catch { [System.Windows.Forms.MessageBox]::Show("Impossible d'ouvrir le dossier des logs", "Erreur", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null }
        })
        $summaryForm.Controls.Add($btnOpenLogs)

        $btnOk = New-Object System.Windows.Forms.Button
        $btnOk.Text      = "✓ Fermer"
        $btnOk.Size      = New-Object System.Drawing.Size(130,38)
        $btnOk.Location  = [System.Drawing.Point]::new(798,618)
        $btnOk.Anchor    = "Right,Bottom"
        $btnOk.FlatStyle = "Flat"
        $btnOk.FlatAppearance.BorderSize = 0
        $btnOk.BackColor = [System.Drawing.Color]::FromArgb(126,87,255)
        $btnOk.ForeColor = [System.Drawing.Color]::WhiteSmoke
        $btnOk.Font      = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
        $btnOk.Cursor    = [System.Windows.Forms.Cursors]::Hand
        $btnOk.Add_Click({ $summaryForm.Close() })
        $summaryForm.Controls.Add($btnOk)

        [void]$summaryForm.ShowDialog()
    }
    catch {
        Write-Log "❌ Impossible d afficher le resume visuel : $($_.Exception.Message)" "ERROR"
    }
}


# =========================================================
# DÉTECTION MULTI-ÉCRAN & RÉSOLUTION (NOUVEAU - CORRIGÉ)
# =========================================================
# =========================================================
# DÉTECTION MULTI-ÉCRAN & RÉSOLUTION (NOUVEAU - CORRIGÉ)
# =========================================================
function Get-ScreenResolution {
    try {
        $primaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen
        $screenWidth   = $primaryScreen.Bounds.Width
        $screenHeight  = $primaryScreen.Bounds.Height
        $screenRatio   = [Math]::Round($screenWidth / $screenHeight, 2)
        
        return @{
            Width      = $screenWidth
            Height     = $screenHeight
            Ratio      = $screenRatio
            IsPrimary  = $true
        }
    }
    catch {
        return @{
            Width  = 1920
            Height = 1080
            Ratio  = 1.78
        }
    }
}

function Get-AllScreensInfo {
    try {
        $allScreens = [System.Windows.Forms.Screen]::AllScreens
        $screensInfo = @()
        
        foreach ($screen in $allScreens) {
            $screensInfo += @{
                Name      = $screen.DeviceName
                Width     = $screen.Bounds.Width
                Height    = $screen.Bounds.Height
                Ratio     = [Math]::Round($screen.Bounds.Width / $screen.Bounds.Height, 2)
                IsPrimary = $screen.Primary
            }
        }
        
        return $screensInfo
    }
    catch {
        return @()
    }
}

function Calculate-ResponsiveScale {
    param([int]$ScreenWidth, [int]$ScreenHeight)
    
    $refWidth = 1920.0
    $scale = $ScreenWidth / $refWidth
    
    if ($scale -lt 0.6) { $scale = 0.6 }
    if ($scale -gt 1.5) { $scale = 1.5 }
    
    return $scale
}

# =========================================================
# SYSTÈME DE RESPONSIVE SCALING UNIFORME
# =========================================================

function Get-ResponsiveScaleFactor {
    <#
    Calcule le facteur d'échelle basé sur la résolution détectée
    Référence: 1920x1080 = scale 1.0
    #>
    param([int]$ScreenWidth, [int]$ScreenHeight)
    
    $refWidth = 1920.0
    $scale = $ScreenWidth / $refWidth
    
    # Limites de sécurité
    if ($scale -lt 0.5)  { $scale = 0.5 }
    if ($scale -gt 2.0)  { $scale = 2.0 }
    
    return [Math]::Round($scale, 2)
}

function Apply-ResponsiveScale {
    <#
    Applique l'échelle à tous les contrôles et la fenêtre principale
    #>
    param(
        [System.Windows.Forms.Form]$Form,
        [double]$Scale
    )
    
    # Redimensionner la fenêtre principale
    $Form.Width = [int](1400 * $Scale)
    $Form.Height = [int](900 * $Scale)
    
    # Centrer la fenêtre
    $Form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    
    # Appliquer l'échelle récursivement à tous les contrôles
    Scale-Control -Control $Form -Factor $Scale
}

function Scale-Control {
    <#
    Redimensionne un contrôle et tous ses enfants
    #>
    param(
        [System.Windows.Forms.Control]$Control,
        [double]$Factor
    )
    
    if ($Control -eq $null) { return }
    
    # Redimensionner le contrôle lui-même
    if ($Control -isnot [System.Windows.Forms.Form]) {
        $Control.Width = [int]($Control.Width * $Factor)
        $Control.Height = [int]($Control.Height * $Factor)
        $Control.Left = [int]($Control.Left * $Factor)
        $Control.Top = [int]($Control.Top * $Factor)
    }
    
    # Redimensionner la police
    if ($Control.Font -ne $null) {
        $newSize = [Math]::Round($Control.Font.Size * $Factor, 1)
        if ($newSize -lt 6) { $newSize = 6 }
        if ($newSize -gt 24) { $newSize = 24 }
        
        try {
            $Control.Font = New-Object System.Drawing.Font($Control.Font.FontFamily, $newSize, $Control.Font.Style)
        } catch {}
    }
    
    # Récursif sur les enfants
    foreach ($child in $Control.Controls) {
        Scale-Control -Control $child -Factor $Scale
    }
}


# =========================================================
# INITIALISATION DES VARIABLES GLOBALES
# =========================================================

$Script:ScreenInfo = Get-ScreenResolution
$Script:AllScreens = Get-AllScreensInfo
$Script:ResponsiveScale = Get-ResponsiveScaleFactor -ScreenWidth $Script:ScreenInfo.Width -ScreenHeight $Script:ScreenInfo.Height

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "DÉTECTION MULTI-ÉCRAN - ClickByChris Setup Tool V1.0.0" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Écran principal    : $($Script:ScreenInfo.Width)x$($Script:ScreenInfo.Height)" -ForegroundColor Yellow
Write-Host "Ratio              : $($Script:ScreenInfo.Ratio):1" -ForegroundColor Yellow
Write-Host "Scale responsive   : $($Script:ResponsiveScale)x" -ForegroundColor Green

if ($Script:AllScreens.Count -gt 1) {
    Write-Host "`nÉcrans connectés :" -ForegroundColor Cyan
    foreach ($screen in $Script:AllScreens) {
        $marker = if ($screen.IsPrimary) { "PRINCIPAL" } else { "SECONDAIRE" }
        Write-Host "  $marker - $($screen.Name): $($screen.Width)x$($screen.Height) (Ratio: $($screen.Ratio):1)" -ForegroundColor Gray
    }
}

Write-Host "`n" -ForegroundColor Cyan

# =========================================================
# AUTO-UPDATE : Vérification de la dernière version GitHub
# =========================================================
$Script:CurrentVersion = "1.0.0"
$Script:VersionManifestUrl = "https://raw.githubusercontent.com/christophe939/ClickByChris-Setup-Tool/main/version.json"

function Test-ClickByChrisUpdate {
    try {
        $manifest = Invoke-RestMethod -Uri $Script:VersionManifestUrl -UseBasicParsing -TimeoutSec 8

        $latest  = ($manifest.version -replace '^[Vv]', '').Trim()
        $current = $Script:CurrentVersion.Trim()

        if ([string]::IsNullOrWhiteSpace($latest)) {
            Write-Host "version.json vide ou invalide. Lancement normal..." -ForegroundColor Yellow
            return
        }

        if ([version]$latest -gt [version]$current) {

            $zipUrl  = $manifest.download_url
            $TempZip = "$env:TEMP\ClickByChris_Update.zip"
            $TempDir = "$env:TEMP\ClickByChris_Update"

            Write-Host ""
            Write-Host "=========================================" -ForegroundColor Cyan
            Write-Host "  Mise a jour disponible : V$latest"      -ForegroundColor Yellow
            Write-Host "  Version actuelle        : V$current"    -ForegroundColor White
            Write-Host "=========================================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "[1/3] Telechargement de la mise a jour..." -ForegroundColor White

            Invoke-WebRequest -Uri $zipUrl -OutFile $TempZip -UseBasicParsing

            Write-Host "[2/3] Extraction des fichiers..." -ForegroundColor White

            if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
            New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
            Expand-Archive -Path $TempZip -DestinationPath $TempDir -Force

            Write-Host "[3/3] Lancement de la nouvelle version..." -ForegroundColor White

            $Launcher = Get-ChildItem -Path $TempDir -Recurse -Filter "*.cmd" | Select-Object -First 1

            if ($Launcher) {
                [System.Windows.Forms.MessageBox]::Show(
                    "La version V$latest a ete installee automatiquement.`r`n`r`nL'outil va redemarrer maintenant avec la derniere version.`r`n`r`nCliquez sur OK pour continuer.",
                    "ClickByChris Setup Tool - Mise a jour automatique",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                ) | Out-Null

                Start-Process $Launcher.FullName
                exit
            }
            else {
                Write-Host "Launcher introuvable apres mise a jour. Lancement normal..." -ForegroundColor Red
            }

        }
        else {
            Write-Host "Deja a jour : V$current" -ForegroundColor Green
        }

    }
    catch {
        Write-Host "Verification mise a jour impossible. Lancement normal..." -ForegroundColor Yellow
    }
}

Add-Type -AssemblyName System.Windows.Forms
Test-ClickByChrisUpdate

# -------------------------
# ADMIN
# -------------------------
function Ensure-PowerShell7 {
    if ($PSVersionTable.PSVersion.Major -ge 7) { return }

    $pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwshCmd) {
        Start-Process $pwshCmd.Source -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        exit
    }

    $title = "ClickByChris Setup Tool"
    $msg = "PowerShell 7 est recommande pour ce script.`r`n`r`nVoulez-vous l installer maintenant ?"
    $choice = [System.Windows.Forms.MessageBox]::Show($msg, $title, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)

    if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetCmd) {
            winget install --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements
            [System.Windows.Forms.MessageBox]::Show("PowerShell 7 a ete installe ou mis a jour. Relancez maintenant le script pour utiliser pwsh.", $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
            exit
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("winget est introuvable. Installez PowerShell 7 puis relancez le script.", $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            exit
        }
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Le script peut continuer avec Windows PowerShell, mais PowerShell 7 reste recommande.", $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    }
}

function Ensure-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal   = New-Object Security.Principal.WindowsPrincipal($currentUser)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $shellExe = "powershell"
        $pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
        if ($pwshCmd) { $shellExe = $pwshCmd.Source }
        Start-Process $shellExe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        exit
    }
}
Ensure-PowerShell7
Ensure-Admin

# -------------------------
# GLOBALS
# -------------------------
$Script:ProjectRoot = if ($PSScriptRoot) { $PSScriptRoot } elseif ($PSCommandPath) { Split-Path -Parent $PSCommandPath } else { (Get-Location).Path }
$Script:AssetsRoot = Join-Path $Script:ProjectRoot "Assets"
$Script:SoundsRoot = Join-Path $Script:AssetsRoot "Sounds"
$Script:ConfigRoot = Join-Path $Script:ProjectRoot "Config"
$Script:LogsRoot   = Join-Path $Script:ProjectRoot "Logs"
$Script:TempRoot   = Join-Path $Script:ProjectRoot "Temp"
$Script:SettingsPath = Join-Path $Script:ConfigRoot "settings.json"

$Script:AppRoot    = Join-Path $env:SystemDrive "Logiciel Pre-Installer"
$Script:AdminRoot  = Join-Path $env:USERPROFILE "Desktop\Administrateur"
$Script:LogoPath   = Join-Path $Script:AssetsRoot "logo.png"
$Script:MusicRoot  = Join-Path $Script:ProjectRoot "Data\Music"
$Script:AudioBackgroundRoot = Join-Path $Script:AssetsRoot "AudioBackgrounds"
$Script:AudioBackgroundCache = @{}

$Script:lblStatus          = $null
$Script:LogBox             = $null
$Script:InfoGrid           = $null
$Script:AppCheckboxes      = @()
$Script:RuntimeCheckboxes  = @()
$Script:NavButtons         = @()
$Script:LogoPulseDirection = 1
$Script:LogoBaseSize       = 210
$Script:ActiveNavButton    = $null
$Script:HoverNormalMap     = @{}
$Script:HoverOverMap       = @{}
$Script:ProgressBar        = $null
$Script:ProgressHost       = $null
$Script:ProgressFill       = $null
$Script:ActionResults      = @()
$Script:CurrentReportTitle = ""

$Script:OptCheckboxes = @{}
$Script:OptProfiles = @{
    Safe = @()
    Gaming = @()
    Advanced = @()
}


$Script:MediaPlayer          = New-Object System.Windows.Media.MediaPlayer
$Script:StartupPlayer        = New-Object System.Windows.Media.MediaPlayer
$Script:StartupFadeInTimer   = $null
$Script:StartupMonitorTimer  = $null
$Script:StartupFadeOutTimer  = $null
$Script:StartupTargetVolume  = 0.70
$Script:StartupFadeOutStarted = $false
$Script:CurrentTrackList     = @()
$Script:CurrentTrackIndex    = -1
$Script:CurrentArtistPath    = $null
$Script:CurrentAlbumPath     = $null
$Script:CurrentStyle         = $null
$Script:CurrentArtistName    = ""
$Script:CurrentAlbumName     = ""

$Script:AudioViewPanels          = @{}
$Script:AudioNavButtons          = @{}
$Script:AudioArtistFlow          = $null
$Script:AudioAlbumFlow           = $null
$Script:AudioTrackList           = $null
$Script:AudioNowPlaying          = $null
$Script:AudioSelectedStyleLabel  = $null
$Script:AudioSelectedArtistLabel = $null
$Script:AudioSelectedAlbumLabel  = $null
$Script:AudioCoverPicture        = $null
$Script:AudioArtistPicture       = $null
$Script:AudioSummaryLabel        = $null
$Script:AudioFinishLabel         = $null
$Script:AudioStyleCombo          = $null
$Script:AudioTrackTitle          = $null
$Script:AudioPageBadge           = $null
$Script:AudioPageBadgeLabel      = $null
$Script:WelcomeHeroCard          = $null
$Script:WelcomeStyleBadge        = $null
$Script:WelcomeComboHost         = $null
$Script:NeonPulseStep            = 0
$Script:AudioStyleCombos         = @()
$Script:AudioStyleSyncing        = $false
$Script:CurrentAudioViewName     = "Welcome"
$Script:AudioOverlayMode       = 'Invisible'   # 'Invisible' ou 'Visible'
$Script:IconRoot                 = Join-Path $Script:AssetsRoot "Icons\V2"
$Script:IconFileMap             = @{
    "home"       = @("01_accueil.png", "*accueil*.png", "*home*.png")
    "info"       = @("02_infos_pc.png", "*infos*pc*.png", "*info*.png")
    "apps"       = @("03_applications.png", "*applications*.png", "*apps*.png")
    "run"        = @("04_runtimes.png", "*runtimes*.png", "*runtime*.png")
    "opt"        = @("05_optimisation.png", "*optimisation*.png", "*optim*.png")
    "drv"        = @("06_drivers.png", "*drivers*.png", "*driver*.png")
    "tools"      = @("07_outils.png", "*outils*.png", "*tools*.png")
    "short"      = @("08_raccourcis.png", "*raccourcis*.png", "*shortcut*.png")
    "audio"      = @("09_audio_premium.png", "*audio*premium*.png", "*audio*.png")
    "contact"    = @("10_contact_aide.png", "*contact*aide*.png", "*contact*.png")
    "logs"       = @("11_logs.png", "*logs*.png", "*log*.png")
    "scan"       = @("12_scan_pc.png", "*scan*pc*.png", "*scan*.png")
    "install"    = @("13_installer_apps.png", "*installer*apps*.png", "*apps*.png")
    "runt"       = @("04_runtimes.png", "*runtimes*.png", "*runtime*.png")
    "optim"      = @("05_optimisation.png", "*optimisation*.png", "*optim*.png")
    "struct"     = @("14_structure.png", "*structure*.png")
    "shortcuts"  = @("08_raccourcis.png", "*raccourcis*.png", "*shortcut*.png")
    "restore"    = @("15_restauration.png", "*restauration*.png", "*restore*.png")
    "all"        = @("16_tout_faire.png", "*tout*faire*.png")
    "clear"      = @("17_vider.png", "*vider*.png", "*clear*.png")
    "assistant"  = @("18_assistant_tout_faire.png", "*assistant*tout*faire*.png")
}

$Script:AudioSelectedAlbumCard       = $null

$Script:Folders = @(
    "1_Systeme","2_Drivers","3_Desinstallation","4_Diagnostic",
    "5_Reseau","6_Securite","7_Utilitaires","8_Installation","9_Backup"
)

# Applications groupées par catégorie
$Script:AppCategories = [ordered]@{
    "Navigateurs"      = [ordered]@{
        "Firefox"            = "Mozilla.Firefox"
        "Google Chrome"      = "Google.Chrome"
        "Brave"              = "Brave.Brave"
    }
    "Communication"    = [ordered]@{
        "Discord"            = "Discord.Discord"
        "Telegram"           = "Telegram.TelegramDesktop"
    }
    "Multimedia"       = [ordered]@{
        "Spotify"            = "Spotify.Spotify"
        "VLC"                = "VideoLAN.VLC"
        "OBS Studio"         = "OBSProject.OBSStudio"
        "MPC-HC"             = "clsid2.mpc-hc"
    }
    "Gaming & Stream"  = [ordered]@{
        "Steam"              = "Valve.Steam"
        "Playnite"           = "Playnite.Playnite"
    }
    "Utilitaires"      = [ordered]@{
        "Notepad++"          = "Notepad++.Notepad++"
        "WinRAR"             = "RARLab.WinRAR"
        "7-Zip"              = "7zip.7zip"
        "Everything"         = "voidtools.Everything"
        "qBittorrent"        = "qBittorrent.qBittorrent"
        "ShareX"             = "ShareX.ShareX"
        "AutoHotkey"         = "AutoHotkey.AutoHotkey"
        "PowerToys"          = "Microsoft.PowerToys"
        "TreeSize Free"      = "JAMSoftware.TreeSize.Free"
    }
    "Dev & Systeme"    = [ordered]@{
        "VS Code"            = "Microsoft.VisualStudioCode"
        "Git"                = "Git.Git"
        "Python 3.12"        = "Python.Python.3.12"
    }
    "Admin & Diagnostic" = [ordered]@{
        "BCUninstaller"      = "Klocman.BulkCrapUninstaller"
        "CrystalDiskInfo"    = "CrystalDewWorld.CrystalDiskInfo"
        "HWMonitor"          = "CPUID.HWMonitor"
        "CPU-Z"              = "CPUID.CPU-Z"
        "GPU-Z"              = "TechPowerUp.GPU-Z"
        "Rufus"              = "Rufus.Rufus"
        "Malwarebytes"       = "Malwarebytes.Malwarebytes"
        "Speedtest"          = "Ookla.Speedtest.Desktop"
        "UniGetUI"           = "UniGetUI"
    }
}

# Flat map winget
$Script:AppsMap = @{}
foreach ($cat in $Script:AppCategories.Keys) {
    foreach ($app in $Script:AppCategories[$cat].Keys) {
        $Script:AppsMap[$app] = $Script:AppCategories[$cat][$app]
    }
}

$Script:RuntimeMap = [ordered]@{
    "Visual C++ 2005 x86 (anciens systemes)" = "Microsoft.VCRedist.2005.x86"
    "Visual C++ 2005 x64 (anciens systemes)" = "Microsoft.VCRedist.2005.x64"
    "Visual C++ 2008 x86 (anciens systemes)" = "Microsoft.VCRedist.2008.x86"
    "Visual C++ 2008 x64 (anciens systemes)" = "Microsoft.VCRedist.2008.x64"
    "Visual C++ 2010 x86 (anciens systemes)" = "Microsoft.VCRedist.2010.x86"
    "Visual C++ 2010 x64 (anciens systemes)" = "Microsoft.VCRedist.2010.x64"
    "Visual C++ 2012 x86 (anciens systemes)" = "Microsoft.VCRedist.2012.x86"
    "Visual C++ 2012 x64 (anciens systemes)" = "Microsoft.VCRedist.2012.x64"
    "Visual C++ 2013 x86 (anciens systemes)" = "Microsoft.VCRedist.2013.x86"
    "Visual C++ 2013 x64 (anciens systemes)" = "Microsoft.VCRedist.2013.x64"
    "Visual C++ 2015-2022 x64"               = "Microsoft.VCRedist.2015+.x64"
    "Visual C++ 2015-2022 x86"               = "Microsoft.VCRedist.2015+.x86"
    ".NET Desktop Runtime 8"                 = "Microsoft.DotNet.DesktopRuntime.8"
    ".NET Desktop Runtime 9"                 = "Microsoft.DotNet.DesktopRuntime.9"
    "WebView2 Runtime"                       = "Microsoft.EdgeWebView2Runtime"
}

# -------------------------
# COULEURS
# -------------------------
$bgMain       = [System.Drawing.Color]::FromArgb(10,10,14)
$bgPanel      = [System.Drawing.Color]::FromArgb(24,24,30)
$bgCard       = [System.Drawing.Color]::FromArgb(32,32,40)
$bgHover      = [System.Drawing.Color]::FromArgb(44,44,54)
$blue         = [System.Drawing.Color]::FromArgb(61,157,234)
$green        = [System.Drawing.Color]::FromArgb(60,210,120)
$red          = [System.Drawing.Color]::FromArgb(220,70,70)
$yellow       = [System.Drawing.Color]::FromArgb(240,210,70)
$white        = [System.Drawing.Color]::WhiteSmoke
$muted        = [System.Drawing.Color]::Gainsboro
$black        = [System.Drawing.Color]::Black
$purple1      = [System.Drawing.Color]::FromArgb(114,96,255)
$purple2      = [System.Drawing.Color]::FromArgb(225,156,235)
$purpleActive = [System.Drawing.Color]::FromArgb(126,87,255)
$purpleHover  = [System.Drawing.Color]::FromArgb(150,115,255)
$audioDark    = [System.Drawing.Color]::FromArgb(6,6,10)
$audioPanel   = [System.Drawing.Color]::FromArgb(18,18,28)
$audioCard    = [System.Drawing.Color]::FromArgb(28,28,42)
$audioText    = [System.Drawing.Color]::WhiteSmoke
$audioMuted   = [System.Drawing.Color]::FromArgb(210,210,225)

# -------------------------
# HELPERS
# -------------------------

# Buffer log pour performance
$Script:LogBuffer    = New-Object System.Collections.Generic.List[object]
$Script:LogLastFlush = [DateTime]::Now
$Script:LogLineCount = 0
$Script:LogMaxLines  = 500

function Write-Log {
    param([string]$Text, [string]$Level = "INFO")

    $Text = $Text -replace '[^\x20-\x7E\u00C0-\u024F\u2019\u2018\u201C\u201D]', ''
    $Text = $Text.Trim()
    if ([string]::IsNullOrWhiteSpace($Text)) { return }

    $time = (Get-Date).ToString("HH:mm:ss")
    $line = "[$time] [$Level] $Text"

    try {
        $logFile = Join-Path $Script:LogsRoot "session_$(Get-Date -Format 'yyyyMMdd').log"
        Add-Content -Path $logFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {}

    $color = switch ($Level) {
        "ERROR" { [System.Drawing.Color]::FromArgb(255,80,80) }
        "WARN"  { [System.Drawing.Color]::FromArgb(255,200,0) }
        "OK"    { [System.Drawing.Color]::FromArgb(0,210,100) }
        default { [System.Drawing.Color]::WhiteSmoke           }
    }

    $Script:LogBuffer.Add(@{ Line=$line; Color=$color })

    $now     = [DateTime]::Now
    $elapsed = ($now - $Script:LogLastFlush).TotalMilliseconds
    if ($Script:LogBuffer.Count -ge 5 -or $elapsed -ge 200) {
        Flush-LogBuffer
    }

    if ($Script:lblStatus) { $Script:lblStatus.Text = "Etat : $Text" }

    if ($Script:lblCurrentApp -and $Level -in "INFO","WARN","OK") {
    $icon = switch ($Level) {
    "OK"    { "[OK]" }
    "WARN"  { "[!!]" }
    default { ">>" }
}
    $shortText = if ($Text.Length -gt 100) { $Text.Substring(0,100) + "..." } else { $Text }
    $Script:lblCurrentApp.Text = "$icon  $shortText"
}

}

function Flush-LogBuffer {
    if (-not $Script:LogBox) { return }
    if ($Script:LogBuffer.Count -eq 0) { return }

    try {
        $Script:LogBox.SuspendLayout()

        foreach ($entry in $Script:LogBuffer) {
            $Script:LogLineCount++
            if ($Script:LogLineCount -gt $Script:LogMaxLines) {
                $Script:LogBox.SelectionStart = 0
                $firstNL  = $Script:LogBox.Text.IndexOf("`n", 0)
                $toRemove = 0
                $removed  = 0
                while ($removed -lt 100 -and $firstNL -gt 0) {
                    $toRemove = $firstNL + 1
                    $firstNL  = $Script:LogBox.Text.IndexOf("`n", $toRemove)
                    $removed++
                }
                if ($toRemove -gt 0) {
                    $Script:LogBox.SelectionStart  = 0
                    $Script:LogBox.SelectionLength = $toRemove
                    $Script:LogBox.SelectedText    = ""
                    $Script:LogLineCount -= $removed
                }
            }

            $Script:LogBox.SelectionStart  = $Script:LogBox.TextLength
            $Script:LogBox.SelectionLength = 0
            $Script:LogBox.SelectionColor  = $entry.Color
            $Script:LogBox.AppendText($entry.Line + "`n")
        }

        $Script:LogBox.SelectionStart = $Script:LogBox.TextLength
        $Script:LogBox.ScrollToCaret()
        $Script:LogBox.ResumeLayout()

    } catch {}

    $Script:LogBuffer.Clear()
    $Script:LogLastFlush = [DateTime]::Now
    [System.Windows.Forms.Application]::DoEvents()
}

# Update compteur
if ($Script:lblLogCount) {
    $Script:lblLogCount.Text = ">> $($Script:LogLineCount) lignes"
}





function Start-ExecutionReport {
    param([string]$Title = "Execution")
    $Script:ActionResults = @()
    $Script:CurrentReportTitle = $Title
    Write-Log "--------------------------------------------"
    Write-Log "Debut du rapport : $Title"
}

function Add-ExecutionResult {
    param(
        [string]$Name,
        [ValidateSet("OK","WARN","ERROR","SKIP")]
        [string]$Status,
        [string]$Detail = ""
    )

    $Script:ActionResults += [PSCustomObject]@{
        Time   = (Get-Date).ToString("HH:mm:ss")
        Name   = $Name
        Status = $Status
        Detail = $Detail
    }

    switch ($Status) {
        "OK"    { Write-Log "[OK] $Name - $Detail" "INFO" }
        "WARN"  { Write-Log "[WARN] $Name - $Detail" "WARN" }
        "ERROR" { Write-Log "[ERREUR] $Name - $Detail" "ERROR" }
        "SKIP"  { Write-Log "[IGNORE] $Name - $Detail" "WARN" }
    }
}


function Show-ExecutionSummaryDialog {
    param(
        [string]$Title,
        [object[]]$Results,
        [string]$CsvPath = ""
    )

    if (-not $Results -or $Results.Count -eq 0) { return }

    try {
        $total = $Results.Count
        $ok    = @($Results | Where-Object { $_.Status -eq "OK"    }).Count
        $warn  = @($Results | Where-Object { $_.Status -eq "WARN"  }).Count
        $err   = @($Results | Where-Object { $_.Status -eq "ERROR" }).Count
        $skip  = @($Results | Where-Object { $_.Status -eq "SKIP"  }).Count

        # Noms des echecs
        $failedNames = @($Results | Where-Object { $_.Status -eq "ERROR" } | Select-Object -ExpandProperty Name)
        $failedStr   = if ($failedNames.Count -gt 0) { $failedNames -join ", " } else { "" }

        # Duree totale (premiere a derniere entree)
        $dureeStr = ""
        try {
            $first = $Results | Select-Object -First 1
            $last  = $Results | Select-Object -Last  1
            if ($first.Time -and $last.Time) {
                $t1 = [datetime]::ParseExact($first.Time, "HH:mm:ss", $null)
                $t2 = [datetime]::ParseExact($last.Time,  "HH:mm:ss", $null)
                $span = $t2 - $t1
                $dureeStr = "$([int]$span.TotalMinutes)min $($span.Seconds)s"
            }
        } catch {}

        # Icone et couleur du bandeau selon resultat global
        if ($err -gt 0) {
            $bandeauBg   = [System.Drawing.Color]::FromArgb(80,20,20)
            $bandeauIcon = "❌ TERMINE AVEC ERREURS"
            $bandeauColor = [System.Drawing.Color]::FromArgb(255,100,100)
        } elseif ($warn -gt 0) {
            $bandeauBg   = [System.Drawing.Color]::FromArgb(60,50,10)
            $bandeauIcon = "⚠️  TERMINE AVEC AVERTISSEMENTS"
            $bandeauColor = [System.Drawing.Color]::FromArgb(255,210,90)
        } else {
            $bandeauBg   = [System.Drawing.Color]::FromArgb(15,50,30)
            $bandeauIcon = "✅ TERMINE AVEC SUCCES"
            $bandeauColor = [System.Drawing.Color]::FromArgb(90,230,140)
        }

        # -------------------------
        # FORM
        # -------------------------
        $summaryForm = New-Object System.Windows.Forms.Form
        $summaryForm.Text = "Rapport - $Title"
        $summaryForm.StartPosition = "CenterParent"
        $summaryForm.Size = New-Object System.Drawing.Size(920,660)
        $summaryForm.MinimumSize = New-Object System.Drawing.Size(820,560)
        $summaryForm.BackColor = [System.Drawing.Color]::FromArgb(10,10,14)
        $summaryForm.ForeColor = [System.Drawing.Color]::WhiteSmoke
        $summaryForm.FormBorderStyle = "FixedDialog"
        $summaryForm.MaximizeBox = $false
        $summaryForm.MinimizeBox = $false

        # -------------------------
        # BANDEAU VISUEL PRINCIPAL
        # -------------------------
        $bandeau = New-Object System.Windows.Forms.Panel
        $bandeau.Location = [System.Drawing.Point]::new(20,14)
        $bandeau.Size = New-Object System.Drawing.Size(864,110)
        $bandeau.BackColor = $bandeauBg
        $summaryForm.Controls.Add($bandeau)

        $lblIcon = New-Object System.Windows.Forms.Label
        $lblIcon.Text = $bandeauIcon
        $lblIcon.Location = [System.Drawing.Point]::new(18,12)
        $lblIcon.Size = New-Object System.Drawing.Size(830,34)
        $lblIcon.Font = New-Object System.Drawing.Font("Segoe UI Semibold",15,[System.Drawing.FontStyle]::Bold)
        $lblIcon.ForeColor = $bandeauColor
        $bandeau.Controls.Add($lblIcon)

        # Ligne 1 : Reussis / Echoues
        $ligne1 = if ($err -gt 0) {
            "  ✅ Reussis : $ok/$total     ❌ Echoues : $err/$total  →  $failedStr"
        } else {
            "  ✅ Reussis : $ok/$total     ⚠️  Avertissements : $warn"
        }
        $lblStats = New-Object System.Windows.Forms.Label
        $lblStats.Text = $ligne1
        $lblStats.Location = [System.Drawing.Point]::new(18,50)
        $lblStats.Size = New-Object System.Drawing.Size(830,22)
        $lblStats.Font = New-Object System.Drawing.Font("Segoe UI",10)
        $lblStats.ForeColor = [System.Drawing.Color]::WhiteSmoke
        $bandeau.Controls.Add($lblStats)

        # Ligne 2 : Duree
        $ligne2 = if ($dureeStr) { "  ⏱  Duree totale : $dureeStr" } else { "  ⏱  Duree : non disponible" }
        $lblDuree = New-Object System.Windows.Forms.Label
        $lblDuree.Text = $ligne2
        $lblDuree.Location = [System.Drawing.Point]::new(18,76)
        $lblDuree.Size = New-Object System.Drawing.Size(830,22)
        $lblDuree.Font = New-Object System.Drawing.Font("Segoe UI",10)
        $lblDuree.ForeColor = [System.Drawing.Color]::Gainsboro
        $bandeau.Controls.Add($lblDuree)

        # -------------------------
        # GRILLE DETAILLEE
        # -------------------------
        $grid = New-Object System.Windows.Forms.DataGridView
        $grid.Location = [System.Drawing.Point]::new(20,140)
        $grid.Size = New-Object System.Drawing.Size(864,360)
        $grid.Anchor = "Top,Bottom,Left,Right"
        $grid.BackgroundColor = [System.Drawing.Color]::FromArgb(32,32,40)
        $grid.GridColor = [System.Drawing.Color]::FromArgb(50,50,62)
        $grid.BorderStyle = "None"
        $grid.RowHeadersVisible = $false
        $grid.AllowUserToAddRows = $false
        $grid.AllowUserToDeleteRows = $false
        $grid.ReadOnly = $true
        $grid.SelectionMode = "FullRowSelect"
        $grid.AutoSizeRowsMode = "AllCells"
        $grid.EnableHeadersVisualStyles = $false
        $grid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(24,24,32)
        $grid.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::WhiteSmoke
        $grid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
        $grid.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(32,32,40)
        $grid.DefaultCellStyle.ForeColor = [System.Drawing.Color]::WhiteSmoke
        $grid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(126,87,255)
        $grid.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::WhiteSmoke
        $grid.DefaultCellStyle.WrapMode = "True"

        [void]$grid.Columns.Add("Time",   "Heure")
        [void]$grid.Columns.Add("Status", "Etat")
        [void]$grid.Columns.Add("Name",   "Action")
        [void]$grid.Columns.Add("Detail", "Detail")
        $grid.Columns[0].Width = 75
        $grid.Columns[1].Width = 90
        $grid.Columns[2].Width = 220
        $grid.Columns[3].AutoSizeMode = "Fill"

        foreach ($r in $Results) {
            $rowIndex = $grid.Rows.Add($r.Time, $r.Status, $r.Name, $r.Detail)
            $row = $grid.Rows[$rowIndex]
            switch ($r.Status) {
                "OK"    { $row.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(90,230,140)  }
                "WARN"  { $row.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(255,210,90)  }
                "ERROR" { $row.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(255,100,100) }
                "SKIP"  { $row.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(190,190,205) }
            }
        }
        $summaryForm.Controls.Add($grid)

        # -------------------------
        # BAS DE FORM
        # -------------------------
        $csvLbl = New-Object System.Windows.Forms.Label
        $csvLbl.Text = if ([string]::IsNullOrWhiteSpace($CsvPath)) { "Rapport CSV : non exporte" } else { "Rapport CSV : $CsvPath" }
        $csvLbl.Location = [System.Drawing.Point]::new(20,516)
        $csvLbl.Size = New-Object System.Drawing.Size(690,24)
        $csvLbl.Anchor = "Left,Right,Bottom"
        $csvLbl.Font = New-Object System.Drawing.Font("Segoe UI",9)
        $csvLbl.ForeColor = [System.Drawing.Color]::Gainsboro
        $summaryForm.Controls.Add($csvLbl)

        $btnOpenLogs = New-Object System.Windows.Forms.Button
        $btnOpenLogs.Text = "Ouvrir Logs"
        $btnOpenLogs.Size = New-Object System.Drawing.Size(120,38)
        $btnOpenLogs.Location = [System.Drawing.Point]::new(636,548)
        $btnOpenLogs.Anchor = "Right,Bottom"
        $btnOpenLogs.FlatStyle = "Flat"
        $btnOpenLogs.FlatAppearance.BorderSize = 0
        $btnOpenLogs.BackColor = [System.Drawing.Color]::FromArgb(61,157,234)
        $btnOpenLogs.ForeColor = [System.Drawing.Color]::Black
        $btnOpenLogs.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
        $btnOpenLogs.Add_Click({ try { Start-Process $Script:LogsRoot } catch {} })
        $summaryForm.Controls.Add($btnOpenLogs)

        $btnOk = New-Object System.Windows.Forms.Button
        $btnOk.Text = "Fermer"
        $btnOk.Size = New-Object System.Drawing.Size(120,38)
        $btnOk.Location = [System.Drawing.Point]::new(764,548)
        $btnOk.Anchor = "Right,Bottom"
        $btnOk.FlatStyle = "Flat"
        $btnOk.FlatAppearance.BorderSize = 0
        $btnOk.BackColor = [System.Drawing.Color]::FromArgb(126,87,255)
        $btnOk.ForeColor = [System.Drawing.Color]::WhiteSmoke
        $btnOk.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
        $btnOk.Add_Click({ $summaryForm.Close() })
        $summaryForm.Controls.Add($btnOk)

        [void]$summaryForm.ShowDialog($form)
    }
    catch {
        Write-Log "Impossible d afficher le resume visuel : $($_.Exception.Message)" "WARN"
    }
}


function Show-ExecutionSummary {
    param([string]$Title = $Script:CurrentReportTitle)

    if (-not $Script:ActionResults -or $Script:ActionResults.Count -eq 0) {
        Write-Log "Aucun resultat a afficher pour : $Title" "WARN"
        return
    }

    $ok   = @($Script:ActionResults | Where-Object { $_.Status -eq "OK"    }).Count
    $warn = @($Script:ActionResults | Where-Object { $_.Status -eq "WARN"  }).Count
    $err  = @($Script:ActionResults | Where-Object { $_.Status -eq "ERROR" }).Count
    $skip = @($Script:ActionResults | Where-Object { $_.Status -eq "SKIP"  }).Count

    # -------------------------
    # LOGS CONSOLE
    # -------------------------
    Write-Log "============== RESUME : $Title =============="
    foreach ($r in $Script:ActionResults) {
        switch ($r.Status) {
            "OK"    { Write-Log "[OK]     $($r.Name) : $($r.Detail)" "OK"   }
            "WARN"  { Write-Log "[WARN]   $($r.Name) : $($r.Detail)" "WARN" }
            "ERROR" { Write-Log "[ERREUR] $($r.Name) : $($r.Detail)" "ERROR"}
            "SKIP"  { Write-Log "[IGNORE] $($r.Name) : $($r.Detail)" "WARN" }
        }
    }
    Write-Log "Bilan : $ok OK / $warn avertissement(s) / $err erreur(s) / $skip ignore(s)"
    Write-Log "============================================="

    # -------------------------
    # EXPORT CSV
    # -------------------------
    $csvPath = ""
    try {
        Ensure-Dir $Script:LogsRoot
        $safeName = ($Title -replace '[^\w\- ]', '').Trim() -replace '\s+', '_'
        if ([string]::IsNullOrWhiteSpace($safeName)) { $safeName = "Rapport" }
        $csvPath = Join-Path $Script:LogsRoot ("rapport_" + $safeName + "_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".csv")
        $Script:ActionResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Log "Rapport CSV exporte : $csvPath"
    }
    catch {
        Write-Log "Export CSV impossible : $($_.Exception.Message)" "WARN"
    }

    # -------------------------
    # DIALOG VISUEL
    # -------------------------
    Show-ExecutionSummaryDialog -Title $Title -Results $Script:ActionResults -CsvPath $csvPath
}

function Show-ExecutionSummaryDialog {
    param(
        [string]$Title,
        [object[]]$Results,
        [string]$CsvPath = ""
    )

    if (-not $Results -or $Results.Count -eq 0) { return }

    try {
        $total = $Results.Count
        $ok    = @($Results | Where-Object { $_.Status -eq "OK"    }).Count
        $warn  = @($Results | Where-Object { $_.Status -eq "WARN"  }).Count
        $err   = @($Results | Where-Object { $_.Status -eq "ERROR" }).Count
        $skip  = @($Results | Where-Object { $_.Status -eq "SKIP"  }).Count

        $failedNames = @($Results | Where-Object { $_.Status -eq "ERROR" } | Select-Object -ExpandProperty Name)
        $failedStr   = if ($failedNames.Count -gt 0) { $failedNames -join ", " } else { "" }

        # Duree totale
        $dureeStr = ""
        try {
            $first = $Results | Select-Object -First 1
            $last  = $Results | Select-Object -Last  1
            if ($first.Time -and $last.Time) {
                $t1   = [datetime]::ParseExact($first.Time, "HH:mm:ss", $null)
                $t2   = [datetime]::ParseExact($last.Time,  "HH:mm:ss", $null)
                $span = $t2 - $t1
                $dureeStr = "$([int]$span.TotalMinutes)min $($span.Seconds)s"
            }
        } catch {}

        # Couleur bandeau selon resultat global
        if ($err -gt 0) {
            $bandeauBg    = [System.Drawing.Color]::FromArgb(80,20,20)
            $bandeauTitle = "TERMINE AVEC ERREURS"
            $bandeauColor = [System.Drawing.Color]::FromArgb(255,100,100)
        } elseif ($warn -gt 0) {
            $bandeauBg    = [System.Drawing.Color]::FromArgb(60,50,10)
            $bandeauTitle = "TERMINE AVEC AVERTISSEMENTS"
            $bandeauColor = [System.Drawing.Color]::FromArgb(255,210,90)
        } else {
            $bandeauBg    = [System.Drawing.Color]::FromArgb(15,50,30)
            $bandeauTitle = "TERMINE AVEC SUCCES"
            $bandeauColor = [System.Drawing.Color]::FromArgb(90,230,140)
        }

        # -------------------------
        # FORM
        # -------------------------
        $summaryForm = New-Object System.Windows.Forms.Form
        $summaryForm.Text            = "Rapport - $Title"
        $summaryForm.StartPosition   = "CenterParent"
        $summaryForm.Size            = New-Object System.Drawing.Size(920,660)
        $summaryForm.MinimumSize     = New-Object System.Drawing.Size(820,560)
        $summaryForm.BackColor       = [System.Drawing.Color]::FromArgb(10,10,14)
        $summaryForm.ForeColor       = [System.Drawing.Color]::WhiteSmoke
        $summaryForm.FormBorderStyle = "FixedDialog"
        $summaryForm.MaximizeBox     = $false
        $summaryForm.MinimizeBox     = $false

        # -------------------------
        # BANDEAU VISUEL
        # -------------------------
        $bandeau = New-Object System.Windows.Forms.Panel
        $bandeau.Location  = [System.Drawing.Point]::new(20,14)
        $bandeau.Size      = New-Object System.Drawing.Size(864,110)
        $bandeau.BackColor = $bandeauBg
        $summaryForm.Controls.Add($bandeau)

        $lblTitle = New-Object System.Windows.Forms.Label
        $lblTitle.Text      = $bandeauTitle
        $lblTitle.Location  = [System.Drawing.Point]::new(18,12)
        $lblTitle.Size      = New-Object System.Drawing.Size(830,34)
        $lblTitle.Font      = New-Object System.Drawing.Font("Segoe UI Semibold",15,[System.Drawing.FontStyle]::Bold)
        $lblTitle.ForeColor = $bandeauColor
        $bandeau.Controls.Add($lblTitle)

        # Stats reussis / echoues
        $ligne1 = if ($err -gt 0) {
            "  Reussis : $ok/$total     Echoues : $err/$total  ->  $failedStr"
        } else {
            "  Reussis : $ok/$total     Avertissements : $warn     Ignores : $skip"
        }
        $lblStats = New-Object System.Windows.Forms.Label
        $lblStats.Text      = $ligne1
        $lblStats.Location  = [System.Drawing.Point]::new(18,50)
        $lblStats.Size      = New-Object System.Drawing.Size(830,22)
        $lblStats.Font      = New-Object System.Drawing.Font("Segoe UI",10)
        $lblStats.ForeColor = [System.Drawing.Color]::WhiteSmoke
        $bandeau.Controls.Add($lblStats)

        # Duree
        $ligne2 = if ($dureeStr) { "  Duree totale : $dureeStr" } else { "  Duree : non disponible" }
        $lblDuree = New-Object System.Windows.Forms.Label
        $lblDuree.Text      = $ligne2
        $lblDuree.Location  = [System.Drawing.Point]::new(18,76)
        $lblDuree.Size      = New-Object System.Drawing.Size(830,22)
        $lblDuree.Font      = New-Object System.Drawing.Font("Segoe UI",10)
        $lblDuree.ForeColor = [System.Drawing.Color]::Gainsboro
        $bandeau.Controls.Add($lblDuree)

        # -------------------------
        # GRILLE DETAILLEE
        # -------------------------
        $grid = New-Object System.Windows.Forms.DataGridView
        $grid.Location             = [System.Drawing.Point]::new(20,140)
        $grid.Size                 = New-Object System.Drawing.Size(864,360)
        $grid.Anchor               = "Top,Bottom,Left,Right"
        $grid.BackgroundColor      = [System.Drawing.Color]::FromArgb(32,32,40)
        $grid.GridColor            = [System.Drawing.Color]::FromArgb(50,50,62)
        $grid.BorderStyle          = "None"
        $grid.RowHeadersVisible    = $false
        $grid.AllowUserToAddRows   = $false
        $grid.AllowUserToDeleteRows = $false
        $grid.ReadOnly             = $true
        $grid.SelectionMode        = "FullRowSelect"
        $grid.AutoSizeRowsMode     = "AllCells"
        $grid.EnableHeadersVisualStyles = $false
        $grid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(24,24,32)
        $grid.ColumnHeadersDefaultCellStyle.ForeColor = [System.Drawing.Color]::WhiteSmoke
        $grid.ColumnHeadersDefaultCellStyle.Font      = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
        $grid.DefaultCellStyle.BackColor              = [System.Drawing.Color]::FromArgb(32,32,40)
        $grid.DefaultCellStyle.ForeColor              = [System.Drawing.Color]::WhiteSmoke
        $grid.DefaultCellStyle.SelectionBackColor     = [System.Drawing.Color]::FromArgb(126,87,255)
        $grid.DefaultCellStyle.SelectionForeColor     = [System.Drawing.Color]::WhiteSmoke
        $grid.DefaultCellStyle.WrapMode               = "True"

        [void]$grid.Columns.Add("Time",   "Heure")
        [void]$grid.Columns.Add("Status", "Etat")
        [void]$grid.Columns.Add("Name",   "Action")
        [void]$grid.Columns.Add("Detail", "Detail")
        $grid.Columns[0].Width        = 75
        $grid.Columns[1].Width        = 90
        $grid.Columns[2].Width        = 220
        $grid.Columns[3].AutoSizeMode = "Fill"

        foreach ($r in $Results) {
            $rowIndex = $grid.Rows.Add($r.Time, $r.Status, $r.Name, $r.Detail)
            $row = $grid.Rows[$rowIndex]
            switch ($r.Status) {
                "OK"    { $row.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(90,230,140)  }
                "WARN"  { $row.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(255,210,90)  }
                "ERROR" { $row.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(255,100,100) }
                "SKIP"  { $row.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(190,190,205) }
            }
        }
        $summaryForm.Controls.Add($grid)

        # -------------------------
        # BAS DE FORM
        # -------------------------
        $csvLbl = New-Object System.Windows.Forms.Label
        $csvLbl.Text      = if ([string]::IsNullOrWhiteSpace($CsvPath)) { "Rapport CSV : non exporte" } else { "Rapport CSV : $CsvPath" }
        $csvLbl.Location  = [System.Drawing.Point]::new(20,516)
        $csvLbl.Size      = New-Object System.Drawing.Size(690,24)
        $csvLbl.Anchor    = "Left,Right,Bottom"
        $csvLbl.Font      = New-Object System.Drawing.Font("Segoe UI",9)
        $csvLbl.ForeColor = [System.Drawing.Color]::Gainsboro
        $summaryForm.Controls.Add($csvLbl)

        $btnOpenLogs = New-Object System.Windows.Forms.Button
        $btnOpenLogs.Text      = "Ouvrir Logs"
        $btnOpenLogs.Size      = New-Object System.Drawing.Size(120,38)
        $btnOpenLogs.Location  = [System.Drawing.Point]::new(636,548)
        $btnOpenLogs.Anchor    = "Right,Bottom"
        $btnOpenLogs.FlatStyle = "Flat"
        $btnOpenLogs.FlatAppearance.BorderSize = 0
        $btnOpenLogs.BackColor = [System.Drawing.Color]::FromArgb(61,157,234)
        $btnOpenLogs.ForeColor = [System.Drawing.Color]::Black
        $btnOpenLogs.Font      = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
        $btnOpenLogs.Add_Click({ try { Start-Process $Script:LogsRoot } catch {} })
        $summaryForm.Controls.Add($btnOpenLogs)

        $btnOk = New-Object System.Windows.Forms.Button
        $btnOk.Text      = "Fermer"
        $btnOk.Size      = New-Object System.Drawing.Size(120,38)
        $btnOk.Location  = [System.Drawing.Point]::new(764,548)
        $btnOk.Anchor    = "Right,Bottom"
        $btnOk.FlatStyle = "Flat"
        $btnOk.FlatAppearance.BorderSize = 0
        $btnOk.BackColor = [System.Drawing.Color]::FromArgb(126,87,255)
        $btnOk.ForeColor = [System.Drawing.Color]::WhiteSmoke
        $btnOk.Font      = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
        $btnOk.Add_Click({ $summaryForm.Close() })
        $summaryForm.Controls.Add($btnOk)

        [void]$summaryForm.ShowDialog($form)
    }
    catch {
        Write-Log "Impossible d afficher le resume visuel : $($_.Exception.Message)" "WARN"
    }
}


function Invoke-TrackedAction {
    param(
        [string]$Name,
        [scriptblock]$Action
    )
    try {
        & $Action
        Add-ExecutionResult -Name $Name -Status "OK" -Detail "Action executee"
        return $true
    }
    catch {
        Add-ExecutionResult -Name $Name -Status "ERROR" -Detail $_.Exception.Message
        return $false
    }
}

function Test-WingetPackageInstalled {
    param([string]$WingetId)
    if ([string]::IsNullOrWhiteSpace($WingetId)) { return $false }
    if (-not (Test-WingetAvailable)) { return $false }
    try {
        $out = winget list --id $WingetId --exact 2>&1 | Out-String
        if ($out -match "No installed package found matching input criteria") { return $false }
        if ($out -match "Aucun package installe") { return $false }
        return ($out -match [regex]::Escape($WingetId))
    }
    catch { return $false }
}



function Invoke-WingetLogged {
    param(
        [string[]]$Arguments,
        [string]$Label = "winget"
    )

    $outputLines = New-Object System.Collections.Generic.List[string]

    # Lignes utiles seulement
    $keepPatterns = @(
        'Successfully installed',
        'Successfully upgraded', 
        'No newer package',
        'No available upgrade',
        'already installed',
        'No installed package found',
        'Aucun package',
        'failed',
        'error',
        'erreur',
        'Found',
        'Installed',
        'upgraded'
    )

    # Lignes a ignorer completement
    $skipPatterns = @(
        'Name\s+Id\s+Version',
        '^[-=_\s\.\|\\\/\[\]]+$',
        'Source$',
        '^\s*$',
        'winget\s+',
        'accept-package',
        'accept-source',
        'Copyright',
        'Windows Package Manager',
        '--include-unknown'
    )

    try {
        & winget @Arguments 2>&1 | ForEach-Object {
            $line = ([string]$_).Trim()
            if ([string]::IsNullOrWhiteSpace($line)) { return }

            # Skip lignes inutiles
            foreach ($skip in $skipPatterns) {
                if ($line -match $skip) {
                    [System.Windows.Forms.Application]::DoEvents()
                    return
                }
            }

            # Garde uniquement les lignes utiles
            $isUseful = $false
            foreach ($keep in $keepPatterns) {
                if ($line -match $keep) { $isUseful = $true; break }
            }

            if ($isUseful) {
                $outputLines.Add($line) | Out-Null
                Write-Log "$Label : $line"
            }

            [System.Windows.Forms.Application]::DoEvents()
        }
    }
    catch {
        $msg = $_.Exception.Message
        $outputLines.Add($msg) | Out-Null
        Write-Log "$Label : $msg" "ERROR"
    }

    return ($outputLines -join [Environment]::NewLine)
}



function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
}


function Load-JsonFileSafe {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path $Path)) { return $null }
    try {
        return (Get-Content -Path $Path -Raw -Encoding UTF8 | ConvertFrom-Json)
    }
    catch {
        Write-Host "settings.json invalide ou illisible : $Path" -ForegroundColor Yellow
        return $null
    }
}

function Initialize-ProjectConfiguration {
    Ensure-Dir $Script:AssetsRoot
    Ensure-Dir $Script:SoundsRoot
    Ensure-Dir $Script:ConfigRoot
    Ensure-Dir $Script:LogsRoot
    Ensure-Dir $Script:TempRoot
    Ensure-Dir $Script:MusicRoot

    $settings = Load-JsonFileSafe -Path $Script:SettingsPath
    if ($settings) {
        if ($settings.AppRoot)   { $Script:AppRoot   = [string]$settings.AppRoot }
        if ($settings.AdminRoot) { $Script:AdminRoot = [string]$settings.AdminRoot }
    }

    $legacyClickByChrisRoot = Join-Path $env:SystemDrive "Logiciel Pre-Installer\ClickByChris"

    if (-not (Test-Path $Script:LogoPath)) {
        $legacyLogo = Join-Path $legacyClickByChrisRoot "logo.png"
        if (Test-Path $legacyLogo) { $Script:LogoPath = $legacyLogo }
    }

    if (-not (Test-Path $Script:IconRoot)) {
        $legacyIconRoot = Join-Path $legacyClickByChrisRoot "Assets\Icons\V2"
        if (Test-Path $legacyIconRoot) { $Script:IconRoot = $legacyIconRoot }
    }

    if (-not (Test-Path $Script:SoundsRoot)) {
        $legacySoundsRoot = Join-Path $legacyClickByChrisRoot "Sounds"
        if (Test-Path $legacySoundsRoot) { $Script:SoundsRoot = $legacySoundsRoot }
    }
}

# =========================================================
# INITIALIZE LAYOUT SIZES - Tailles spécialisées par résolution
# =========================================================
function Initialize-LayoutSizes {
    Write-Log "Initialisation des tailles de layout adaptes a la resolution"

    $width = $Script:ScreenInfo.Width
    $height = $Script:ScreenInfo.Height

    # Table de référence : 1920x1080
    $layoutTemplates = @{
        "1920x1080" = @{
            "LogoSize"           = 180
            "NavIconSize"        = 64
            "ButtonIconSize"     = 48
            "Spacing"            = 20
            "CardSpacing"        = 12
            "TitleFont"          = 18
            "TextFont"           = 12
            "SmallFont"          = 10
            "ButtonHeight"       = 62
            "CardHeight"         = 110
            "NavWidth"           = 200
            "MainPanelLeft"      = 220
        }

        "1600x900" = @{
            "LogoSize"           = 150
            "NavIconSize"        = 54
            "ButtonIconSize"     = 40
            "Spacing"            = 18
            "CardSpacing"        = 11
            "TitleFont"          = 16
            "TextFont"           = 11
            "SmallFont"          = 9
            "ButtonHeight"       = 52
            "CardHeight"         = 95
            "NavWidth"           = 180
            "MainPanelLeft"      = 200
        }

        "1366x768" = @{
            "LogoSize"           = 130
            "NavIconSize"        = 48
            "ButtonIconSize"     = 36
            "Spacing"            = 16
            "CardSpacing"        = 10
            "TitleFont"          = 15
            "TextFont"           = 10
            "SmallFont"          = 8
            "ButtonHeight"       = 48
            "CardHeight"         = 90
            "NavWidth"           = 170
            "MainPanelLeft"      = 190
        }

        "1360x768" = @{
            "LogoSize"           = 130
            "NavIconSize"        = 48
            "ButtonIconSize"     = 36
            "Spacing"            = 16
            "CardSpacing"        = 10
            "TitleFont"          = 15
            "TextFont"           = 10
            "SmallFont"          = 8
            "ButtonHeight"       = 48
            "CardHeight"         = 90
            "NavWidth"           = 170
            "MainPanelLeft"      = 190
        }

        "1280x720" = @{
            "LogoSize"           = 120
            "NavIconSize"        = 44
            "ButtonIconSize"     = 32
            "Spacing"            = 14
            "CardSpacing"        = 9
            "TitleFont"          = 14
            "TextFont"           = 10
            "SmallFont"          = 8
            "ButtonHeight"       = 44
            "CardHeight"         = 82
            "NavWidth"           = 160
            "MainPanelLeft"      = 180
        }

        "1024x768" = @{
            "LogoSize"           = 100
            "NavIconSize"        = 40
            "ButtonIconSize"     = 28
            "Spacing"            = 12
            "CardSpacing"        = 8
            "TitleFont"          = 13
            "TextFont"           = 9
            "SmallFont"          = 7
            "ButtonHeight"       = 40
            "CardHeight"         = 75
            "NavWidth"           = 150
            "MainPanelLeft"      = 170
        }
    }

    # Clé de résolution
    $resKey = "$width`x$height"

    # Si la résolution EXACTE existe, l'utiliser
    if ($layoutTemplates.ContainsKey($resKey)) {
        $Script:LayoutSizes = $layoutTemplates[$resKey]
        Write-Log "Layout personnalise pour $resKey charge"
        return
    }

    # Sinon, chercher la résolution la plus proche
    $closest = $null
    $minDiff = [int]::MaxValue

    foreach ($key in $layoutTemplates.Keys) {
        $parts = $key -split 'x'
        $refWidth = [int]$parts[0]
        $refHeight = [int]$parts[1]
        $diff = [Math]::Abs($refWidth - $width) + [Math]::Abs($refHeight - $height)

        if ($diff -lt $minDiff) {
            $minDiff = $diff
            $closest = $key
        }
    }

    $Script:LayoutSizes = $layoutTemplates[$closest]
    Write-Log "Layout approche pour $resKey (utilise $closest) : difference = $minDiff px"
}


function Test-StartupEnvironment {
    $pwshFound   = [bool](Get-Command pwsh -ErrorAction SilentlyContinue)
    $wingetFound = [bool](Get-Command winget -ErrorAction SilentlyContinue)
    $isAdmin = $false
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {}

    $startupFolder = Join-Path $Script:SoundsRoot "Startup"
    $assetsOk = (Test-Path $Script:AssetsRoot)
    $iconsOk  = (Test-Path $Script:IconRoot)
    $soundOk  = (Test-Path $startupFolder)

    [PSCustomObject]@{
        WindowsVersion = [Environment]::OSVersion.VersionString
        PowerShell     = $PSVersionTable.PSVersion.ToString()
        PwshFound      = $pwshFound
        WingetFound    = $wingetFound
        IsAdmin        = $isAdmin
        AssetsOk       = $assetsOk
        IconsOk        = $iconsOk
        StartupSoundOk = $soundOk
        ProjectRoot    = $Script:ProjectRoot
    }
}

Initialize-ProjectConfiguration

Initialize-LayoutSizes

function New-Shortcut {
    param([string]$TargetPath, [string]$ShortcutPath)
    if (Test-Path $TargetPath) {
        $WshShell = New-Object -ComObject WScript.Shell
        $sc = $WshShell.CreateShortcut($ShortcutPath)
        $sc.TargetPath = $TargetPath
        $sc.Save()
    }
}

function New-UrlShortcut {
    param([string]$Url, [string]$ShortcutPath)
    Set-Content -Path $ShortcutPath -Value "[InternetShortcut]`r`nURL=$Url`r`n" -Encoding ASCII
}

function Load-ImageSafe {
    param([string]$ImagePath)
    if ([string]::IsNullOrWhiteSpace($ImagePath)) { return $null }
    if (-not (Test-Path $ImagePath)) { return $null }
    try {
        $fs  = [System.IO.File]::Open($ImagePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        try {
            $img = [System.Drawing.Image]::FromStream($fs)
            $bmp = New-Object System.Drawing.Bitmap $img
            $img.Dispose()
            return $bmp
        } finally { $fs.Close(); $fs.Dispose() }
    } catch {
        Write-Log "Impossible de charger : $ImagePath" "WARN"
        return $null
    }
}

function New-RoundedRegion {
    param([int]$Width, [int]$Height, [int]$Radius)
    if ($Width -le 0 -or $Height -le 0) { return $null }
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diam = $Radius * 2
    if ($diam -gt $Width)  { $diam = $Width  }
    if ($diam -gt $Height) { $diam = $Height }
    $path.AddArc(0, 0, $diam, $diam, 180, 90)
    $path.AddArc($Width - $diam, 0, $diam, $diam, 270, 90)
    $path.AddArc($Width - $diam, $Height - $diam, $diam, $diam, 0, 90)
    $path.AddArc(0, $Height - $diam, $diam, $diam, 90, 90)
    $path.CloseFigure()
    return New-Object System.Drawing.Region($path)
}

function Set-ControlRounded {
    param([System.Windows.Forms.Control]$Control, [int]$Radius = 16)
    if (-not $Control) { return }
    if ($Control.Width -le 0 -or $Control.Height -le 0) { return }
    $region = New-RoundedRegion -Width $Control.Width -Height $Control.Height -Radius $Radius
    if ($region) { $Control.Region = $region }
}

function Add-ModernHoverEffect {
    param(
        [System.Windows.Forms.Control]$Control,
        [System.Drawing.Color]$NormalColor,
        [System.Drawing.Color]$HoverColor
    )
    if (-not $Control) { return }
    if (-not $NormalColor) { $NormalColor = $bgCard }
    if (-not $HoverColor)  { $HoverColor  = $NormalColor }
    $Script:HoverNormalMap[$Control.Handle] = $NormalColor
    $Script:HoverOverMap[$Control.Handle]   = $HoverColor
    $Control.BackColor = $NormalColor
    $Control.Add_MouseEnter({
        $handle = $this.Handle
        if ($this.Tag -ne 'nav-active' -and $Script:HoverOverMap.ContainsKey($handle)) {
            $this.BackColor = $Script:HoverOverMap[$handle]
        }
    })
    $Control.Add_MouseLeave({
        $handle = $this.Handle
        if ($this.Tag -ne 'nav-active' -and $Script:HoverNormalMap.ContainsKey($handle)) {
            $this.BackColor = $Script:HoverNormalMap[$handle]
        }
    })
}

function Apply-ModernStyleRecursive {
    param([System.Windows.Forms.Control]$Root)
    if (-not $Root) { return }
    foreach ($ctrl in $Root.Controls) {
        if ($ctrl -is [System.Windows.Forms.Button]) {
            $ctrl.FlatStyle = "Flat"
            $ctrl.FlatAppearance.BorderSize = 0
            $radius = 16
            if ($ctrl.Height -le 40) { $radius = 14 }
            if ($ctrl.Width -ge 150 -and $ctrl.Height -le 50) { $radius = 20 }
            Set-ControlRounded -Control $ctrl -Radius $radius
            if ($ctrl.AccessibleName -eq 'todo-toggle') {
                $ctrl.Add_SizeChanged({ Set-ControlRounded -Control $this -Radius 16 })
            } elseif ($ctrl.Text -match "TOUT FAIRE") {
                Add-ModernHoverEffect -Control $ctrl -NormalColor $blue -HoverColor ([System.Drawing.Color]::FromArgb(90,180,255))
            } elseif ($ctrl.Text -match "Page suivante|Fin") {
                Add-ModernHoverEffect -Control $ctrl -NormalColor $purple2 -HoverColor ([System.Drawing.Color]::FromArgb(235,180,242))
            } elseif ($ctrl.Text -match "Vider") {
                Add-ModernHoverEffect -Control $ctrl -NormalColor $yellow -HoverColor ([System.Drawing.Color]::FromArgb(248,224,110))
            } elseif ($ctrl.Parent -eq $navPanel) {
                Add-ModernHoverEffect -Control $ctrl -NormalColor $bgCard -HoverColor $purpleHover
            } else {
                Add-ModernHoverEffect -Control $ctrl -NormalColor $bgCard -HoverColor ([System.Drawing.Color]::FromArgb(50,50,65))
            }
            $ctrl.Add_SizeChanged({ Set-ControlRounded -Control $this -Radius 16 })
        } elseif ($ctrl -is [System.Windows.Forms.Panel]) {
            if ($ctrl.Width -gt 100 -and $ctrl.Height -gt 30) {
                Set-ControlRounded -Control $ctrl -Radius 18
                $ctrl.Add_SizeChanged({ Set-ControlRounded -Control $this -Radius 18 })
            }
        } elseif ($ctrl -is [System.Windows.Forms.PictureBox]) {
            if ($ctrl.Width -ge 120 -and $ctrl.Height -ge 120) {
                Set-ControlRounded -Control $ctrl -Radius 14
                $ctrl.Add_SizeChanged({ Set-ControlRounded -Control $this -Radius 14 })
            }
        } elseif ($ctrl -is [System.Windows.Forms.ListBox]) {
            Set-ControlRounded -Control $ctrl -Radius 12
            $ctrl.Add_SizeChanged({ Set-ControlRounded -Control $this -Radius 12 })
        } elseif ($ctrl -is [System.Windows.Forms.ComboBox]) {
            Set-ControlRounded -Control $ctrl -Radius 12
            $ctrl.Add_SizeChanged({ Set-ControlRounded -Control $this -Radius 12 })
        }
        if ($ctrl.Controls.Count -gt 0) { Apply-ModernStyleRecursive -Root $ctrl }
    }
}

function Set-NavActiveButton {
    param([System.Windows.Forms.Button]$Button)
    foreach ($b in $Script:NavButtons) {
        $b.BackColor = $bgCard
        $b.ForeColor = $white
        $b.Tag = $null
    }
    if ($Button) {
        $Button.BackColor = $purpleActive
        $Button.ForeColor = $white
        $Button.Tag = 'nav-active'
        $Script:ActiveNavButton = $Button
    }
}

function Update-Progress {
    param([int]$Value, [string]$Text = "")
    $safeValue = [Math]::Min([Math]::Max($Value, 0), 100)

    if ($Script:ProgressBar) {
        try { $Script:ProgressBar.Value = $safeValue } catch {}
    }

    if ($Script:ProgressHost -and $Script:ProgressFill) {
        $trackWidth = [Math]::Max(10, $Script:ProgressHost.ClientSize.Width - 4)
        $fillWidth = [int][Math]::Round(($trackWidth * $safeValue) / 100)
        if ($safeValue -gt 0 -and $fillWidth -lt 10) { $fillWidth = 10 }
        $Script:ProgressFill.Location = [System.Drawing.Point]::new(2,2)
        $Script:ProgressFill.Size = New-Object System.Drawing.Size($fillWidth, [Math]::Max(8, $Script:ProgressHost.Height - 4))
        $Script:ProgressFill.Visible = ($safeValue -gt 0)
    }

    if ($Text -and $Script:lblStatus) { $Script:lblStatus.Text = "Etat : $Text" }
    [System.Windows.Forms.Application]::DoEvents()
}


function Test-WingetAvailable {
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    return [bool]$wingetCmd
}

function Set-RegistryDWORDSafe {
    param(
        [string]$Path,
        [string]$Name,
        [int]$Value
    )
    try {
        New-Item -Path $Path -Force | Out-Null
        Set-ItemProperty -Path $Path -Name $Name -Type DWord -Value $Value -Force
        return $true
    }
    catch {
        Write-Log "Registre : impossible de modifier $Path\$Name" "WARN"
        return $false
    }
}

function Disable-BackgroundAppsSafe {
    Write-Log "Optimisation : limitation des applications en arriere-plan"
    [void](Set-RegistryDWORDSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1)
}

function Disable-WindowsSuggestionsAndAds {
    Write-Log "Optimisation : reduction des suggestions et publicites Windows"
    $base = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    [void](Set-RegistryDWORDSafe -Path $base -Name "SilentInstalledAppsEnabled" -Value 0)
    [void](Set-RegistryDWORDSafe -Path $base -Name "SubscribedContent-338388Enabled" -Value 0)
    [void](Set-RegistryDWORDSafe -Path $base -Name "SubscribedContent-338389Enabled" -Value 0)
    [void](Set-RegistryDWORDSafe -Path $base -Name "SubscribedContent-353694Enabled" -Value 0)
    [void](Set-RegistryDWORDSafe -Path $base -Name "SubscribedContent-353696Enabled" -Value 0)
    [void](Set-RegistryDWORDSafe -Path $base -Name "SystemPaneSuggestionsEnabled" -Value 0)
}

function Reduce-TelemetrySafe {
    Write-Log "Optimisation : reduction de la telemetrie et des experiences personnalisees"
    [void](Set-RegistryDWORDSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0)
    [void](Set-RegistryDWORDSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0)
}

function Disable-OneDriveSafe {
    Write-Log "Optimisation : desactivation de OneDrive (sans suppression forcee)"
    try { Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue } catch {}
    [void](Set-RegistryDWORDSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Name "DisableFileSyncNGSC" -Value 1)
}

function Optimize-SearchIndexingSafe {
    Write-Log "Optimisation : limitation de l indexation Windows"
    try {
        Set-Service -Name "WSearch" -StartupType Manual -ErrorAction SilentlyContinue
        Stop-Service -Name "WSearch" -ErrorAction SilentlyContinue
    } catch {}
}

function Set-VisualEffectsPerformance {
    Write-Log "Optimisation : effets visuels regles sur performance"
    [void](Set-RegistryDWORDSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2)
}

function Set-PowerPlanBestPerformance {
    Write-Log "Gaming : activation du plan d alimentation performance"
    try {
        powercfg /setactive SCHEME_MIN | Out-Null
    } catch {
        Write-Log "Alimentation : impossible d activer le plan performance" "WARN"
    }
}

function Enable-GameModeSafe {
    Write-Log "Gaming : activation du mode jeu"
    [void](Set-RegistryDWORDSafe -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -Value 1)
    [void](Set-RegistryDWORDSafe -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1)
}

function Enable-HAGSSafe {
    Write-Log "Gaming : activation de HAGS (si supporte)"
    [void](Set-RegistryDWORDSafe -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2)
}

function Disable-GameDVRSafe {
    Write-Log "Gaming : desactivation du Xbox Game DVR"
    [void](Set-RegistryDWORDSafe -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0)
    [void](Set-RegistryDWORDSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0)
}

function Disable-XboxServicesSafe {
    Write-Log "Gaming : desactivation des services Xbox non utilises"
    $disableServices = @("XblAuthManager","XblGameSave","XboxGipSvc","XboxNetApiSvc")
    foreach ($svc in $disableServices) {
        try {
            Stop-Service -Name $svc -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        } catch {}
    }
}

function Test-SystemDriveIsSSD {
    try {
        $physical = Get-PhysicalDisk -ErrorAction Stop | Select-Object -First 1
        if ($physical -and $physical.MediaType) {
            return ($physical.MediaType.ToString() -match "SSD")
        }
    } catch {}
    return $false
}

function Apply-SysMainSmart {
    Write-Log "Avance : reglage intelligent de SysMain"
    try {
        if (Test-SystemDriveIsSSD) {
            Stop-Service -Name "SysMain" -ErrorAction SilentlyContinue
            Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Log "SysMain desactive (SSD detecte)"
        }
        else {
            Set-Service -Name "SysMain" -StartupType Manual -ErrorAction SilentlyContinue
            Write-Log "SysMain laisse en Manuel (HDD ou type inconnu)"
        }
    } catch {
        Write-Log "SysMain : impossible d appliquer le reglage" "WARN"
    }
}

function Disable-NDUSafe {
    Write-Log "Avance : desactivation de NDU"
    [void](Set-RegistryDWORDSafe -Path "HKLM:\SYSTEM\ControlSet001\Services\Ndu" -Name "Start" -Value 4)
}

function Disable-DefenderRealtimeWarn {
    Write-Log "Avance : demande de desactivation de Defender temps reel"
    try {
        if (Get-Command Set-MpPreference -ErrorAction SilentlyContinue) {
            Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
            Write-Log "Defender temps reel desactive (si autorise par Windows)"
        }
        else {
            Write-Log "Defender : Set-MpPreference indisponible sur ce PC" "WARN"
        }
    } catch {
        Write-Log "Defender : Windows a refuse la desactivation ou l operation a echoue" "WARN"
    }
}

function Open-LocalAccountSettingsSafe {
    Write-Log "Avance : ouverture des parametres de compte local"
    try { Start-Process "ms-settings:yourinfo" } catch { Write-Log "Impossible d ouvrir les parametres de compte" "WARN" }
}

function Apply-SelectedOptimizations {
    param([switch]$SkipRestore)

    if ($Script:OptCheckboxes.ContainsKey('SafeRestore') -and $Script:OptCheckboxes['SafeRestore'].Checked -and -not $SkipRestore) {
        Create-RestorePoint
    }
    if ($Script:OptCheckboxes.ContainsKey('SafeBloat') -and $Script:OptCheckboxes['SafeBloat'].Checked) { Remove-BloatSafe }
    if ($Script:OptCheckboxes.ContainsKey('SafeServices') -and $Script:OptCheckboxes['SafeServices'].Checked) { Apply-SafeServices }
    if ($Script:OptCheckboxes.ContainsKey('SafeBackground') -and $Script:OptCheckboxes['SafeBackground'].Checked) { Disable-BackgroundAppsSafe }
    if ($Script:OptCheckboxes.ContainsKey('SafeAds') -and $Script:OptCheckboxes['SafeAds'].Checked) { Disable-WindowsSuggestionsAndAds }
    if ($Script:OptCheckboxes.ContainsKey('SafeTelemetry') -and $Script:OptCheckboxes['SafeTelemetry'].Checked) { Reduce-TelemetrySafe }
    if ($Script:OptCheckboxes.ContainsKey('SafeOneDrive') -and $Script:OptCheckboxes['SafeOneDrive'].Checked) { Disable-OneDriveSafe }
    if ($Script:OptCheckboxes.ContainsKey('SafeIndexing') -and $Script:OptCheckboxes['SafeIndexing'].Checked) { Optimize-SearchIndexingSafe }
    if ($Script:OptCheckboxes.ContainsKey('SafeVisuals') -and $Script:OptCheckboxes['SafeVisuals'].Checked) { Set-VisualEffectsPerformance }

    if ($Script:OptCheckboxes.ContainsKey('GamePower') -and $Script:OptCheckboxes['GamePower'].Checked) { Set-PowerPlanBestPerformance }
    if ($Script:OptCheckboxes.ContainsKey('GameMode') -and $Script:OptCheckboxes['GameMode'].Checked) { Enable-GameModeSafe }
    if ($Script:OptCheckboxes.ContainsKey('GameHAGS') -and $Script:OptCheckboxes['GameHAGS'].Checked) { Enable-HAGSSafe }
    if ($Script:OptCheckboxes.ContainsKey('GameDVR') -and $Script:OptCheckboxes['GameDVR'].Checked) { Disable-GameDVRSafe }
    if ($Script:OptCheckboxes.ContainsKey('GameXbox') -and $Script:OptCheckboxes['GameXbox'].Checked) { Disable-XboxServicesSafe }

    if ($Script:OptCheckboxes.ContainsKey('AdvSysMain') -and $Script:OptCheckboxes['AdvSysMain'].Checked) { Apply-SysMainSmart }
    if ($Script:OptCheckboxes.ContainsKey('AdvNDU') -and $Script:OptCheckboxes['AdvNDU'].Checked) { Disable-NDUSafe }
    if ($Script:OptCheckboxes.ContainsKey('AdvDefender') -and $Script:OptCheckboxes['AdvDefender'].Checked) { Disable-DefenderRealtimeWarn }
    if ($Script:OptCheckboxes.ContainsKey('AdvLocalAccount') -and $Script:OptCheckboxes['AdvLocalAccount'].Checked) { Open-LocalAccountSettingsSafe }
}

# -------------------------
# WINGET
# -------------------------
function Install-OrUpgrade {
    param([string]$WingetId, [string]$DisplayName)

    if (-not (Test-WingetAvailable)) {
        Add-ExecutionResult -Name $DisplayName -Status "ERROR" -Detail "winget introuvable"
        return $false
    }

    if ($Script:lblCurrentApp) {
        $Script:lblCurrentApp.Text     = "En cours : $DisplayName"
        $Script:lblCurrentApp.ForeColor = [System.Drawing.Color]::FromArgb(255,200,0)
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        Write-Log "--------------------------------------------"
        Write-Log "[ $DisplayName ]  >>  $WingetId"

        $listOutput  = Invoke-WingetLogged -Arguments @("list","--id",$WingetId,"--exact") -Label "$DisplayName"
        $isInstalled = -not (
            $listOutput -match "No installed package found" -or
            $listOutput -match "Aucun package installe"     -or
            $listOutput -match "No installed package"
        )

        if (-not $isInstalled) {
            Write-Log "[>>] $DisplayName : absent - installation en cours..." "WARN"
            [void](Invoke-WingetLogged -Arguments @(
                "install","--id",$WingetId,"-e",
                "--accept-package-agreements",
                "--accept-source-agreements",
                "--silent"
            ) -Label "$DisplayName")
        }
        else {
            Write-Log "[>>] $DisplayName : deja present - verification mise a jour..."
            [void](Invoke-WingetLogged -Arguments @(
                "upgrade","--id",$WingetId,"-e",
                "--accept-package-agreements",
                "--accept-source-agreements",
                "--silent"
            ) -Label "$DisplayName")
        }

        Start-Sleep -Milliseconds 900
        $stopwatch.Stop()
        $mins = [int]$stopwatch.Elapsed.TotalMinutes
        $secs = $stopwatch.Elapsed.Seconds

        if (Test-WingetPackageInstalled -WingetId $WingetId) {
            Write-Log "[OK] $DisplayName - Termine en ${mins}min ${secs}s" "OK"
            Add-ExecutionResult -Name $DisplayName -Status "OK" -Detail "Installe/MaJ en ${mins}min ${secs}s"
            return $true
        }
        else {
            Write-Log "[!!] $DisplayName : non confirme par winget list" "WARN"
            Add-ExecutionResult -Name $DisplayName -Status "WARN" -Detail "Commande lancee mais non confirmee"
            return $false
        }
    }
    catch {
        $stopwatch.Stop()
        Write-Log "[ERROR] $DisplayName : $($_.Exception.Message)" "ERROR"
        Add-ExecutionResult -Name $DisplayName -Status "ERROR" -Detail $_.Exception.Message
        return $false
    }
    finally {
        if ($Script:lblCurrentApp) {
            $Script:lblCurrentApp.ForeColor = [System.Drawing.Color]::WhiteSmoke
        }
    }
}



function Install-UniGetUI {
    if (-not (Test-WingetAvailable)) { Write-Log "winget est introuvable : UniGetUI ne peut pas etre installe" "ERROR"; return }
    Write-Log "Controle de UniGetUI"
    $candidates = @("MartiCliment.UniGetUI","Devolutions.UniGetUI")
    foreach ($id in $candidates) {
        $search = winget show --id $id -e 2>&1 | Out-String
        if ($search -notmatch "No package found matching input criteria") {
            Install-OrUpgrade $id "UniGetUI"
            return
        }
    }
    Write-Log "UniGetUI introuvable dans les sources winget" "WARN"
}

function Find-AppPath {
    param([string[]]$Candidates)
    foreach ($p in $Candidates) { if (Test-Path $p) { return $p } }
    return $null
}

function Find-StartMenuShortcut {
    param([string[]]$Candidates)
    $bases = @(
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
        "$env:AppData\Microsoft\Windows\Start Menu\Programs"
    )
    foreach ($base in $bases) {
        foreach ($c in $Candidates) {
            $full = Join-Path $base $c
            if (Test-Path $full) { return $full }
        }
    }
    return $null
}

# -------------------------
# FONCTIONS PRINCIPALES
# -------------------------
function Create-RestorePoint {
    Write-Log "Gestion du point de restauration"
    try {
        Enable-ComputerRestore -Drive "C:\"
        $before = Get-ComputerRestorePoint | Sort-Object CreationTime -Descending | Select-Object -First 1
        if ($before) { Write-Log "Dernier point : $($before.Description) - Sequence $($before.SequenceNumber)" }
        $restoreWarnings = @(); $out = Checkpoint-Computer -Description "ClickByChris Setup Tool V5" -RestorePointType "MODIFY_SETTINGS" -WarningAction SilentlyContinue -WarningVariable restoreWarnings 2>&1 | Out-String; $out = ($out + [Environment]::NewLine + ($restoreWarnings | Out-String))
        if ($out -match "1440 minutes" -or $out -match "Impossible") {
            Add-ExecutionResult -Name "Point de restauration" -Status "WARN" -Detail "Windows bloque parfois la creation pendant 24h"
            Write-Log "Windows bloque la creation dans les 24h (normal)" "WARN"
        } else {
            Add-ExecutionResult -Name "Point de restauration" -Status "OK" -Detail "Creation demandee avec succes"
            Write-Log "Nouveau point de restauration cree"
        }
        $after = Get-ComputerRestorePoint | Sort-Object CreationTime -Descending | Select-Object -First 1
        if ($after) { Write-Log "Point utilisable : Sequence $($after.SequenceNumber)" }
    } catch {
        Add-ExecutionResult -Name "Point de restauration" -Status "ERROR" -Detail $_.Exception.Message
        Write-Log "Erreur point de restauration : $($_.Exception.Message)" "ERROR"
    }
}



function Initialize-Structure {
    Write-Log "Creation de la structure de dossiers"
    Ensure-Dir $Script:AppRoot
    Ensure-Dir $Script:AdminRoot
    Ensure-Dir (Join-Path $Script:AppRoot "ClickByChris")
    Ensure-Dir (Join-Path $Script:AppRoot "ClickByChris\Sounds")
    Ensure-Dir (Join-Path $Script:AppRoot "ClickByChris\Sounds\Startup")
    foreach ($folder in $Script:Folders) {
        Ensure-Dir (Join-Path $Script:AppRoot $folder)
        Ensure-Dir (Join-Path $Script:AdminRoot $folder)
    }

    # Raccourcis URL admin
    New-Shortcut -TargetPath $Script:AppRoot -ShortcutPath (Join-Path $Script:AdminRoot "Depot Logiciels.lnk")
    New-UrlShortcut "https://www.amd.com/en/support"                      (Join-Path $Script:AdminRoot "2_Drivers\AMD Drivers.url")
    New-UrlShortcut "https://www.nvidia.com/Download/index.aspx"           (Join-Path $Script:AdminRoot "2_Drivers\NVIDIA Drivers.url")
    New-UrlShortcut "https://www.intel.com/content/www/us/en/download-center/home.html" (Join-Path $Script:AdminRoot "2_Drivers\Intel Drivers.url")
    New-UrlShortcut "https://www.wagnardsoft.com/display-driver-uninstaller-ddu"        (Join-Path $Script:AdminRoot "2_Drivers\DDU.url")
    New-UrlShortcut "https://learn.microsoft.com/en-us/sysinternals/"      (Join-Path $Script:AdminRoot "1_Systeme\Sysinternals.url")
    New-UrlShortcut "https://userdiag.com/"                                (Join-Path $Script:AdminRoot "4_Diagnostic\UserDiag.url")
    New-UrlShortcut "https://www.crystaldewworld.com/downloads/"           (Join-Path $Script:AdminRoot "4_Diagnostic\CrystalDisk.url")
    New-UrlShortcut "https://www.oo-software.com/en/shutup10"              (Join-Path $Script:AdminRoot "6_Securite\OOSU10.url")
    New-UrlShortcut "https://www.winaero.com/winaero-tweaker/"             (Join-Path $Script:AdminRoot "7_Utilitaires\WinaeroTweaker.url")
    New-UrlShortcut "https://www.macrium.com/reflectfree"                  (Join-Path $Script:AdminRoot "9_Backup\Macrium Reflect.url")
    New-UrlShortcut "https://ninite.com/"                                  (Join-Path $Script:AdminRoot "8_Installation\Ninite.url")
    New-UrlShortcut "https://www.virustotal.com/"                          (Join-Path $Script:AdminRoot "6_Securite\VirusTotal.url")
    New-UrlShortcut "https://speedtest.net/"                               (Join-Path $Script:AdminRoot "5_Reseau\Speedtest Web.url")

    Write-Log "Structure creee avec succes : $Script:AppRoot"
    Write-Log "Dossier admin bureau : $Script:AdminRoot"
    if ((Test-Path $Script:AppRoot) -and (Test-Path $Script:AdminRoot)) {
        Add-ExecutionResult -Name "Structure de dossiers" -Status "OK" -Detail "Dossiers crees/verifies"
    }
    else {
        Add-ExecutionResult -Name "Structure de dossiers" -Status "WARN" -Detail "Creation lancee, verification partielle"
    }
}

function Remove-BloatSafe {
    Write-Log "Suppression du bloat safe (non critique)"
    $bloat = @(
        "Microsoft.XboxApp","Microsoft.Xbox.TCUI","Microsoft.XboxGamingOverlay",
        "Microsoft.XboxGameOverlay","Microsoft.XboxIdentityProvider","Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.GamingApp","Microsoft.YourPhone","Microsoft.WindowsFeedbackHub",
        "Clipchamp.Clipchamp","Microsoft.Teams","Microsoft.Todos","Microsoft.Family",
        "Microsoft.OutlookForWindows","Microsoft.PowerAutomateDesktop","Microsoft.BingNews",
        "Microsoft.BingWeather","Microsoft.GetHelp","Microsoft.Getstarted",
        "Microsoft.MicrosoftSolitaireCollection","Microsoft.ZuneVideo","Microsoft.ZuneMusic",
        "Microsoft.People","Microsoft.windowscommunicationsapps"
    )
    foreach ($pkg in $bloat) {
        try {
            Write-Log "Bloat safe : traitement de $pkg"
            Get-AppxPackage -Name $pkg -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue | Out-Null
            Get-AppxPackage -AllUsers -Name $pkg -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue | Out-Null
        } catch {
            Write-Log "Bloat safe : $pkg non traite ($($_.Exception.Message))" "WARN"
        }
    }
    Add-ExecutionResult -Name "Bloatware safe" -Status "OK" -Detail "Applications inutiles traitees quand presentes"
    Write-Log "Bloatware safe traite"
}

function Apply-SafeServices {
    Write-Log "Application des services safe"
    $disableServices = @(
        "XblAuthManager","XblGameSave","XboxGipSvc","XboxNetApiSvc",
        "DiagTrack","lfsvc","MapsBroker","SharedAccess"
    )
    foreach ($svc in $disableServices) {
        try {
            Stop-Service -Name $svc -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        } catch {}
    }
    try { Set-Service -Name "WSearch" -StartupType Manual -ErrorAction SilentlyContinue } catch {}
    try { Set-Service -Name "SysMain"  -StartupType Manual -ErrorAction SilentlyContinue } catch {}
    Add-ExecutionResult -Name "Services safe" -Status "OK" -Detail "Services non critiques appliques"
    Write-Log "Services safe appliques"
}

function Apply-PrivacyGaming {
    Write-Log "Application privacy + gaming safe"
    # Telemetrie
    try {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
        Write-Log "Telemetrie reduite (niveau 0)"
    } catch { Write-Log "Telemetrie : modification impossible" "WARN" }

    # Copilot
    try {
        New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Force | Out-Null
        Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Type DWord -Value 1
        Write-Log "Copilot desactive"
    } catch { Write-Log "Copilot : modification impossible" "WARN" }

    # Game DVR
    try {
        New-Item -Path "HKCU:\System\GameConfigStore" -Force | Out-Null
        Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Type DWord -Value 0
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Force | Out-Null
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Type DWord -Value 0
        Write-Log "Game DVR desactive"
    } catch { Write-Log "Game DVR : modification impossible" "WARN" }

    # Notifications publicitaires
    try {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Force | Out-Null
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Type DWord -Value 0
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Type DWord -Value 0
        Write-Log "Publicites Windows desactivees"
    } catch { Write-Log "Publicites : modification impossible" "WARN" }

    # Mode performances elevees
    powercfg /setactive SCHEME_MIN | Out-Null
    Add-ExecutionResult -Name "Privacy + gaming safe" -Status "OK" -Detail "Reglages privacy/gaming appliques quand autorises"
    Write-Log "Mode performances elevees active"
}

function Get-PCInfo {
    $cs   = Get-CimInstance Win32_ComputerSystem
    $os   = Get-CimInstance Win32_OperatingSystem
    $cpu  = Get-CimInstance Win32_Processor | Select-Object -First 1
    $gpus = @(Get-CimInstance Win32_VideoController | Select-Object Name)
    $bios = Get-CimInstance Win32_BIOS
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object -First 1
    $gpuStr = ($gpus | ForEach-Object { $_.Name }) -join " / "
    $diskFree = if ($disk) { [math]::Round($disk.FreeSpace / 1GB, 1) } else { "N/A" }
    $diskSize = if ($disk) { [math]::Round($disk.Size / 1GB, 1) } else { "N/A" }
    [PSCustomObject]@{
        "Nom PC"          = $env:COMPUTERNAME
        "Utilisateur"     = $env:USERNAME
        "Fabricant"       = $cs.Manufacturer
        "Modele"          = $cs.Model
        "CPU"             = $cpu.Name
        "Coeurs / Threads"= "$($cpu.NumberOfCores) coeurs / $($cpu.NumberOfLogicalProcessors) threads"
        "GPU"             = $gpuStr
        "RAM (Go)"        = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        "Windows"         = $os.Caption
        "Build"           = $os.BuildNumber
        "Version OS"      = $os.Version
        "Architecture"    = $os.OSArchitecture
        "BIOS"            = $bios.SMBIOSBIOSVersion
        "Disque C: Libre" = "$diskFree Go libres / $diskSize Go"
        "Dossier System"  = $env:SystemRoot
    }
}

function Show-PCInfo {
    $info = Get-PCInfo
    $Script:InfoGrid.Rows.Clear()
    foreach ($prop in $info.PSObject.Properties) {
        [void]$Script:InfoGrid.Rows.Add($prop.Name, [string]$prop.Value)
    }
    Write-Log "Analyse du PC terminee"
}

function Install-SelectedApps {
    if (-not (Test-WingetAvailable)) {
        Add-ExecutionResult -Name "Applications" -Status "ERROR" -Detail "winget introuvable"
        Write-Log "winget est introuvable : installation d applications impossible" "ERROR"
        return
    }
    $selected = @($Script:AppCheckboxes | Where-Object { $_.Checked })
    if ($selected.Count -eq 0) {
        Add-ExecutionResult -Name "Applications" -Status "SKIP" -Detail "Aucune application selectionnee"
        Write-Log "Aucune application selectionnee" "WARN"
        return
    }
    $step = [int](100 / $selected.Count)
    $prog = 0
    foreach ($cb in $selected) {
        $name = $cb.Text
        Update-Progress -Value $prog -Text "Installation : $name"
        if ($name -eq "UniGetUI") {
            Install-UniGetUI
            Add-ExecutionResult -Name $name -Status "WARN" -Detail "Verification specifique UniGetUI a confirmer manuellement"
        }
        elseif ($Script:AppsMap.ContainsKey($name)) {
            [void](Install-OrUpgrade $Script:AppsMap[$name] $name)
        }
        else {
            Add-ExecutionResult -Name $name -Status "ERROR" -Detail "ID winget introuvable dans AppsMap"
        }
        $prog += $step
    }
    Update-Progress -Value 100 -Text "Installation terminee"
}

function Install-SelectedRuntimes {
    if (-not (Test-WingetAvailable)) {
        Add-ExecutionResult -Name "Compatibilite" -Status "ERROR" -Detail "winget introuvable"
        Write-Log "winget est introuvable : installation de compatibilite impossible" "ERROR"
        return
    }
    $selected = @($Script:RuntimeCheckboxes | Where-Object { $_.Checked })
    if ($selected.Count -eq 0) {
        Add-ExecutionResult -Name "Compatibilite" -Status "SKIP" -Detail "Aucun composant selectionne"
        Write-Log "Aucun composant de compatibilite selectionne" "WARN"
        return
    }
    $step = [int](100 / $selected.Count)
    $prog = 0
    foreach ($cb in $selected) {
        $name = $cb.Text
        Update-Progress -Value $prog -Text "Compatibilite : $name"
        if ($Script:RuntimeMap.Contains($name)) {
            [void](Install-OrUpgrade $Script:RuntimeMap[$name] $name)
        }
        else {
            Add-ExecutionResult -Name $name -Status "ERROR" -Detail "ID winget introuvable dans RuntimeMap"
        }
        $prog += $step
    }
    Update-Progress -Value 100 -Text "Compatibilite installee"
}

function Create-AppShortcuts {
    Write-Log "Creation des raccourcis applications"
    $appShortcuts = @(
        @{ Name="Firefox";       Target=Find-AppPath @("$env:ProgramFiles\Mozilla Firefox\firefox.exe","$env:ProgramFiles(x86)\Mozilla Firefox\firefox.exe"); Dir="8_Installation" },
        @{ Name="Chrome";        Target=Find-AppPath @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe","$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe"); Dir="8_Installation" },
        @{ Name="Brave";         Target=Find-AppPath @("$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe"); Dir="8_Installation" },
        @{ Name="Spotify";       Target=Find-StartMenuShortcut @("Spotify.lnk"); Dir="8_Installation" },
        @{ Name="Steam";         Target=Find-StartMenuShortcut @("Steam\Steam.lnk","Steam.lnk"); Dir="8_Installation" },
        @{ Name="Discord";       Target=Find-StartMenuShortcut @("Discord Inc\Discord.lnk","Discord.lnk"); Dir="8_Installation" },
        @{ Name="VLC";           Target=Find-AppPath @("$env:ProgramFiles\VideoLAN\VLC\vlc.exe","$env:ProgramFiles(x86)\VideoLAN\VLC\vlc.exe"); Dir="8_Installation" },
        @{ Name="OBS Studio";    Target=Find-StartMenuShortcut @("OBS Studio\OBS Studio (64bit).lnk","OBS Studio.lnk"); Dir="8_Installation" },
        @{ Name="qBittorrent";   Target=Find-StartMenuShortcut @("qBittorrent\qBittorrent.lnk","qBittorrent.lnk"); Dir="8_Installation" },
        @{ Name="Notepad++";     Target=Find-StartMenuShortcut @("Notepad++\Notepad++.lnk","Notepad++.lnk"); Dir="7_Utilitaires" },
        @{ Name="WinRAR";        Target=Find-AppPath @("$env:ProgramFiles\WinRAR\WinRAR.exe","$env:ProgramFiles(x86)\WinRAR\WinRAR.exe"); Dir="7_Utilitaires" },
        @{ Name="7-Zip";         Target=Find-AppPath @("$env:ProgramFiles\7-Zip\7zFM.exe","$env:ProgramFiles(x86)\7-Zip\7zFM.exe"); Dir="7_Utilitaires" },
        @{ Name="Everything";    Target=Find-AppPath @("$env:ProgramFiles\Everything\Everything.exe","$env:ProgramFiles(x86)\Everything\Everything.exe"); Dir="7_Utilitaires" },
        @{ Name="BCUninstaller"; Target=Find-StartMenuShortcut @("BCUninstaller\BCUninstaller.lnk","Bulk Crap Uninstaller\BCUninstaller.lnk","BCUninstaller.lnk"); Dir="3_Desinstallation" },
        @{ Name="CrystalDiskInfo"; Target=Find-AppPath @("$env:ProgramFiles\CrystalDiskInfo\DiskInfo64.exe","$env:ProgramFiles(x86)\CrystalDiskInfo\DiskInfo32.exe"); Dir="4_Diagnostic" },
        @{ Name="HWMonitor";     Target=Find-AppPath @("$env:ProgramFiles\CPUID\HWMonitor\HWMonitor.exe","$env:ProgramFiles(x86)\CPUID\HWMonitor\HWMonitor.exe"); Dir="4_Diagnostic" },
        @{ Name="CPU-Z";         Target=Find-StartMenuShortcut @("CPUID\CPU-Z\CPU-Z.lnk","CPU-Z.lnk"); Dir="4_Diagnostic" },
        @{ Name="GPU-Z";         Target=Find-StartMenuShortcut @("GPU-Z.lnk","TechPowerUp\GPU-Z.lnk"); Dir="4_Diagnostic" },
        @{ Name="Rufus";         Target=Find-AppPath @("$env:ProgramFiles\Rufus\Rufus.exe","$env:LocalAppData\Microsoft\WinGet\Links\rufus.exe"); Dir="7_Utilitaires" },
        @{ Name="Malwarebytes";  Target=Find-StartMenuShortcut @("Malwarebytes\Malwarebytes.lnk","Malwarebytes.lnk"); Dir="6_Securite" },
        @{ Name="Speedtest";     Target=Find-StartMenuShortcut @("Speedtest by Ookla.lnk","Speedtest.lnk"); Dir="5_Reseau" },
        @{ Name="VS Code";       Target=Find-AppPath @("$env:ProgramFiles\Microsoft VS Code\Code.exe","$env:LocalAppData\Programs\Microsoft VS Code\Code.exe"); Dir="8_Installation" },
        @{ Name="PowerToys";     Target=Find-StartMenuShortcut @("PowerToys (Preview)\PowerToys.lnk","PowerToys.lnk"); Dir="7_Utilitaires" },
        @{ Name="UniGetUI";      Target=Find-StartMenuShortcut @("UniGetUI.lnk","Devolutions\UniGetUI.lnk"); Dir="8_Installation" }
    )
    $count = 0
    foreach ($app in $appShortcuts) {
        if ($app.Target) {
            $shortcutPath = Join-Path $Script:AdminRoot "$($app.Dir)\$($app.Name).lnk"
            New-Shortcut -TargetPath $app.Target -ShortcutPath $shortcutPath
            Write-Log "Raccourci : $($app.Name)"
            $count++
        } else {
            Write-Log "Non trouve (pas installe ?) : $($app.Name)" "WARN"
        }
    }
    Write-Log "$count raccourci(s) cree(s)"
    if ($count -gt 0) {
        Add-ExecutionResult -Name "Raccourcis" -Status "OK" -Detail "$count raccourci(s) cree(s)"
    }
    else {
        Add-ExecutionResult -Name "Raccourcis" -Status "WARN" -Detail "Aucun raccourci cree - applications peut-etre absentes"
    }
}


function Show-RunAllConfirmationDialog {
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = "Assistant TOUT FAIRE"
    $dialog.StartPosition = "CenterParent"
    $dialog.Size = New-Object System.Drawing.Size(1040,860)
    $dialog.MinimumSize = New-Object System.Drawing.Size(1040,860)
    $dialog.FormBorderStyle = "FixedDialog"
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.BackColor = $bgMain
    $dialog.ForeColor = $white

    $toggleOnColor  = [System.Drawing.Color]::FromArgb(42,178,91)
    $toggleOffColor = [System.Drawing.Color]::FromArgb(205,64,64)

    $header = New-Object System.Windows.Forms.Panel
    $header.Dock = 'Top'
    $header.Height = 74
    $header.BackColor = [System.Drawing.Color]::FromArgb(16,20,40)

    $headerIcon = New-Object System.Windows.Forms.PictureBox
    $headerIcon.Location = [System.Drawing.Point]::new(28,14)
    $headerIcon.Size = New-Object System.Drawing.Size(42,42)
    $headerIcon.BackColor = [System.Drawing.Color]::Transparent
    $headerIcon.SizeMode = 'Zoom'
    $assistantIcon = Resolve-IconPath -Key "assistant"
    if ($assistantIcon) { try { $headerIcon.Image = [System.Drawing.Image]::FromFile($assistantIcon) } catch {} }
    $header.Controls.Add($headerIcon)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "Assistant TOUT FAIRE"
    $title.Location = [System.Drawing.Point]::new(82,10)
    $title.Size = New-Object System.Drawing.Size(580,40)
    $title.Font = New-Object System.Drawing.Font("Segoe UI",17,[System.Drawing.FontStyle]::Bold)
    $title.ForeColor = $white
    $header.Controls.Add($title)

    $introPanel = New-Object System.Windows.Forms.Panel
    $introPanel.Dock = 'Top'
    $introPanel.Height = 78
    $introPanel.BackColor = [System.Drawing.Color]::FromArgb(12,16,32)

    $desc = New-Object System.Windows.Forms.Label
    $desc.Text = "Choisis exactement ce que le script doit executer. Chaque action est expliquee clairement pour que la personne comprenne ce qui sera fait sur le PC avant de lancer le traitement."
    $desc.Location = [System.Drawing.Point]::new(28,14)
    $desc.Size = New-Object System.Drawing.Size(972,48)
    $desc.Font = New-Object System.Drawing.Font("Segoe UI",10)
    $desc.ForeColor = $muted
    $introPanel.Controls.Add($desc)

    $introLine = New-Object System.Windows.Forms.Panel
    $introLine.Dock = 'Bottom'
    $introLine.Height = 2
    $introLine.BackColor = [System.Drawing.Color]::FromArgb(42,48,74)
    $introPanel.Controls.Add($introLine)

    $btnPanel = New-Object System.Windows.Forms.Panel
    $btnPanel.Dock = 'Bottom'
    $btnPanel.Height = 76
    $btnPanel.BackColor = $bgMain

    $driverNotePanel = New-Object System.Windows.Forms.Panel
    $driverNotePanel.Dock = 'Bottom'
    $driverNotePanel.Height = 58
    $driverNotePanel.BackColor = [System.Drawing.Color]::FromArgb(40,32,18)

    $driverNote = New-Object System.Windows.Forms.Label
    $driverNote.Text = "Important : les drivers ne sont pas inclus automatiquement dans TOUT FAIRE. Ils restent dans la page Drivers, car leur installation depend du materiel exact de chaque PC."
    $driverNote.Location = [System.Drawing.Point]::new(14,10)
    $driverNote.Size = New-Object System.Drawing.Size(972,40)
    $driverNote.Font = New-Object System.Drawing.Font("Segoe UI",9)
    $driverNote.ForeColor = $yellow
    $driverNotePanel.Controls.Add($driverNote)

    $bodyHost = New-Object System.Windows.Forms.Panel
    $bodyHost.Dock = 'Fill'
    $bodyHost.BackColor = $bgMain
    $bodyHost.Padding = New-Object System.Windows.Forms.Padding(0,12,0,10)

    $flow = New-Object System.Windows.Forms.FlowLayoutPanel
    $flow.Dock = 'Fill'
    $flow.AutoScroll = $true
    $flow.WrapContents = $false
    $flow.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
    $flow.BackColor = $bgMain
    $flow.Padding = New-Object System.Windows.Forms.Padding(16,8,16,8)
    $bodyHost.Controls.Add($flow)

    $items = @(
        @{ Key="RestorePoint"; Label="Creer un point de restauration"; Description="Cree une sauvegarde systeme avant les grosses modifications. Cela permet de revenir en arriere si un logiciel, un runtime ou un reglage pose probleme apres execution." },
        @{ Key="Structure"; Label="Creer la structure de dossiers ClickByChris"; Description="Prepare automatiquement le depot principal, les sous-dossiers techniques et l espace Administrateur sur le Bureau. Cette etape organise correctement les outils, drivers, raccourcis et ressources du projet." },
        @{ Key="Applications"; Label="Installer les applications selectionnees"; Description="Installe ou met a jour les logiciels coches dans la page Applications a l aide de winget. Cette etape permet de preparer rapidement un PC avec les programmes essentiels." },
        @{ Key="Runtimes"; Label="Installer les runtimes et composants de compatibilite"; Description="Installe les composants Visual C++, .NET Desktop Runtime, WebView2 et autres bibliotheques utiles. Sans eux, certains logiciels, jeux ou anciens programmes peuvent ne pas demarrer correctement." },
        @{ Key="Optimization"; Label="Appliquer l optimisation safe"; Description="Applique les reglages de nettoyage, de confidentialite et de performance prevus dans le script sans toucher aux points critiques du systeme. Le but est d ameliorer la proprete et la reactivite du PC en restant prudent." },
        @{ Key="Shortcuts"; Label="Creer les raccourcis utiles"; Description="Genere les raccourcis vers les applications installees, les dossiers de travail et les outils importants pour faciliter la prise en main du PC apres la preparation." }
    )

    $states = @{}
    $updateToggleVisual = {
        param($button, [bool]$state)
        if (-not $button) { return }
        $button.FlatStyle = 'Flat'
        $button.FlatAppearance.BorderSize = 0
        $button.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::Transparent
        $button.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::Transparent
        $button.ForeColor = $white
        $button.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
        if ($state) {
            $button.Text = "ACTIVE"
            $button.BackColor = $toggleOnColor
        } else {
            $button.Text = "DESACTIVE"
            $button.BackColor = $toggleOffColor
        }
        Set-ControlRounded -Control $button -Radius 16
    }

    foreach ($item in $items) {
        $states[$item.Key] = $true

        $card = New-Object System.Windows.Forms.Panel
        $card.Margin = New-Object System.Windows.Forms.Padding(0,0,0,14)
        $card.Size = New-Object System.Drawing.Size(960,110)
        $card.BackColor = $bgCard
        Set-ControlRounded -Control $card -Radius 18
        $flow.Controls.Add($card)

        $titleLbl = New-Object System.Windows.Forms.Label
        $titleLbl.Text = $item.Label
        $titleLbl.Location = [System.Drawing.Point]::new(18,14)
        $titleLbl.Size = New-Object System.Drawing.Size(680,28)
        $titleLbl.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)
        $titleLbl.ForeColor = $white
        $card.Controls.Add($titleLbl)

        $toggle = New-Object System.Windows.Forms.Button
        $toggle.AccessibleName = 'todo-toggle'
        $toggle.Tag = $item.Key
        $toggle.Location = [System.Drawing.Point]::new(806,14)
        $toggle.Size = New-Object System.Drawing.Size(122,32)
        $toggle.Cursor = [System.Windows.Forms.Cursors]::Hand
        $card.Controls.Add($toggle)
        & $updateToggleVisual $toggle $true
        $toggle.Add_Click({
            $key = [string]$this.Tag
            if (-not $states.ContainsKey($key)) { return }
            $states[$key] = -not [bool]$states[$key]
            & $updateToggleVisual $this ([bool]$states[$key])
        })

        $descLbl = New-Object System.Windows.Forms.Label
        $descLbl.Text = $item.Description
        $descLbl.Location = [System.Drawing.Point]::new(20,50)
        $descLbl.Size = New-Object System.Drawing.Size(900,46)
        $descLbl.Font = New-Object System.Drawing.Font("Segoe UI",10)
        $descLbl.ForeColor = $muted
        $card.Controls.Add($descLbl)
    }

    $flow.Add_Resize({
        $cardWidth = [Math]::Max(900, $flow.ClientSize.Width - 34)
        foreach ($card in $flow.Controls) {
            $card.Width = $cardWidth
            if ($card.Controls.Count -ge 3) {
                $toggle = $card.Controls[1]
                $descLbl = $card.Controls[2]
                $toggle.Location = [System.Drawing.Point]::new(($card.Width - 140),14)
                $descLbl.Size = New-Object System.Drawing.Size(($card.Width - 44),46)
            }
        }
    })

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "Lancer"
    $btnOk.Size = New-Object System.Drawing.Size(142,42)
    $btnOk.Location = [System.Drawing.Point]::new(708,16)
    $btnOk.BackColor = $blue
    $btnOk.ForeColor = $black
    $btnOk.FlatStyle = "Flat"
    $btnOk.FlatAppearance.BorderSize = 0
    $btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $btnPanel.Controls.Add($btnOk)
    Set-ControlRounded -Control $btnOk -Radius 18

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Annuler"
    $btnCancel.Size = New-Object System.Drawing.Size(142,42)
    $btnCancel.Location = [System.Drawing.Point]::new(866,16)
    $btnCancel.BackColor = $bgCard
    $btnCancel.ForeColor = $white
    $btnCancel.FlatStyle = "Flat"
    $btnCancel.FlatAppearance.BorderSize = 0
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $btnPanel.Controls.Add($btnCancel)
    Set-ControlRounded -Control $btnCancel -Radius 18

    $dialog.Controls.Add($bodyHost)
    $dialog.Controls.Add($btnPanel)
    $dialog.Controls.Add($driverNotePanel)
    $dialog.Controls.Add($introPanel)
    $dialog.Controls.Add($header)

    Apply-ModernStyleRecursive -Root $dialog
    foreach ($card in $flow.Controls) {
        foreach ($ctrl in $card.Controls) {
            if ($ctrl -is [System.Windows.Forms.Button] -and $ctrl.AccessibleName -eq 'todo-toggle') {
                $key = [string]$ctrl.Tag
                if ($states.ContainsKey($key)) {
                    & $updateToggleVisual $ctrl ([bool]$states[$key])
                }
            }
        }
    }

    $result = $dialog.ShowDialog($form)
    if ($result -ne [System.Windows.Forms.DialogResult]::OK) { return $null }

    return [PSCustomObject]@{
        RestorePoint = [bool]$states["RestorePoint"]
        Structure    = [bool]$states["Structure"]
        Applications = [bool]$states["Applications"]
        Runtimes     = [bool]$states["Runtimes"]
        Optimization = [bool]$states["Optimization"]
        Shortcuts    = [bool]$states["Shortcuts"]
    }
}

function Run-All {
    param([object]$Plan)

    $defaultPlan = @{
        RestorePoint = $true
        Structure    = $true
        Applications = $true
        Runtimes     = $true
        Optimization = $true
        Shortcuts    = $true
    }

    $normalizedPlan = @{}
    foreach ($key in $defaultPlan.Keys) {
        $normalizedPlan[$key] = [bool]$defaultPlan[$key]
    }

    if ($Plan) {
        foreach ($key in $defaultPlan.Keys) {
            try {
                if ($Plan -is [System.Collections.IDictionary]) {
                    if ($Plan.Contains($key)) { $normalizedPlan[$key] = [bool]$Plan[$key] }
                    elseif ($Plan.ContainsKey($key)) { $normalizedPlan[$key] = [bool]$Plan[$key] }
                }
                else {
                    $prop = $Plan.PSObject.Properties[$key]
                    if ($prop) { $normalizedPlan[$key] = [bool]$prop.Value }
                }
            }
            catch {
                Write-Log "Plan TOUT FAIRE : valeur invalide pour $key, valeur par defaut conservee." "WARN"
            }
        }
    }

    $Plan = $normalizedPlan

    $tasks = @()
    if ($Plan["RestorePoint"]) { $tasks += @{ Name="Point de restauration"; Action={ Create-RestorePoint } } }
    if ($Plan["Structure"])    { $tasks += @{ Name="Creation de la structure"; Action={ Initialize-Structure } } }
    if ($Plan["Applications"]) { $tasks += @{ Name="Installation des applications"; Action={ Install-SelectedApps } } }
    if ($Plan["Runtimes"])     { $tasks += @{ Name="Installation des compatibilites"; Action={ Install-SelectedRuntimes } } }
    if ($Plan["Optimization"]) { $tasks += @{ Name="Optimisation safe"; Action={
        Apply-SelectedOptimizations -SkipRestore:$([bool]$Plan["RestorePoint"])
    } } }
    if ($Plan["Shortcuts"])    { $tasks += @{ Name="Creation des raccourcis"; Action={ Create-AppShortcuts } } }

    if ($tasks.Count -eq 0) {
        Write-Log "Aucune action selectionnee pour TOUT FAIRE." "WARN"
        return
    }

    if (-not $Script:CurrentReportTitle) { Start-ExecutionReport "TOUT FAIRE" }
    Write-Log "=== DEMARRAGE : MODE TOUT FAIRE ==="
    Update-Progress 0 "Preparation..."
    $stepIndex = 0

    foreach ($task in $tasks) {
        $stepIndex++
        $percent = [int](($stepIndex - 1) / $tasks.Count * 100)
        Update-Progress $percent "$($task.Name) en cours..."
        Write-Log "TOUT FAIRE -> $($task.Name)"
        & $task.Action
        $donePercent = [int]($stepIndex / $tasks.Count * 100)
        Update-Progress $donePercent "$($task.Name) termine"
    }

    Update-Progress 100 "TOUT FAIRE termine avec succes !"
    Write-Log "=== TOUT FAIRE TERMINE ==="
    Show-ExecutionSummary "TOUT FAIRE"
}

# -------------------------
# AUDIO HELPERS
# -------------------------
function Stop-StartupSoundTimers {
    foreach ($timerName in @("StartupFadeInTimer","StartupMonitorTimer","StartupFadeOutTimer")) {
        $timer = Get-Variable -Scope Script -Name $timerName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Value -ErrorAction SilentlyContinue
        if ($timer) {
            try { $timer.Stop() } catch {}
            try { $timer.Dispose() } catch {}
            Set-Variable -Scope Script -Name $timerName -Value $null
        }
    }
}

function Play-StartupSound {
    try {
        $startupFolder = Join-Path $Script:SoundsRoot "Startup"
        if (-not (Test-Path $startupFolder)) {
            Write-Log "Dossier du son de demarrage introuvable" "WARN"
            return
        }

        $startupFile = Get-ChildItem -Path $startupFolder -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in ".mp3", ".wav" } |
            Sort-Object Name |
            Select-Object -First 1

        if (-not $startupFile) {
            Write-Log "Aucun son de demarrage detecte dans Startup" "WARN"
            return
        }

        Stop-StartupSoundTimers
        $Script:StartupFadeOutStarted = $false
        $Script:StartupPlayer.Open([System.Uri]::new($startupFile.FullName))
        $Script:StartupPlayer.Volume = 0.0
        $Script:StartupPlayer.Play()

        $Script:StartupFadeInTimer = New-Object System.Windows.Forms.Timer
        $Script:StartupFadeInTimer.Interval = 80
        $Script:StartupFadeInTimer.Add_Tick({
            $nextVolume = [Math]::Round(($Script:StartupPlayer.Volume + 0.07), 2)
            if ($nextVolume -ge $Script:StartupTargetVolume) {
                $Script:StartupPlayer.Volume = $Script:StartupTargetVolume
                $this.Stop()
            }
            else {
                $Script:StartupPlayer.Volume = $nextVolume
            }
        })
        $Script:StartupFadeInTimer.Start()

        $Script:StartupMonitorTimer = New-Object System.Windows.Forms.Timer
        $Script:StartupMonitorTimer.Interval = 200
        $Script:StartupMonitorTimer.Add_Tick({
            try {
                if (-not $Script:StartupFadeOutStarted -and $Script:StartupPlayer.NaturalDuration.HasTimeSpan) {
                    $remaining = $Script:StartupPlayer.NaturalDuration.TimeSpan - $Script:StartupPlayer.Position
                    if ($remaining.TotalMilliseconds -le 1200) {
                        $Script:StartupFadeOutStarted = $true
                        $Script:StartupFadeOutTimer = New-Object System.Windows.Forms.Timer
                        $Script:StartupFadeOutTimer.Interval = 80
                        $Script:StartupFadeOutTimer.Add_Tick({
                            $nextVolume = [Math]::Round(($Script:StartupPlayer.Volume - 0.07), 2)
                            if ($nextVolume -le 0) {
                                $Script:StartupPlayer.Volume = 0.0
                                try { $Script:StartupPlayer.Stop() } catch {}
                                $this.Stop()
                            }
                            else {
                                $Script:StartupPlayer.Volume = $nextVolume
                            }
                        })
                        $Script:StartupFadeOutTimer.Start()
                    }
                }
            }
            catch {}
        })
        $Script:StartupMonitorTimer.Start()

        Write-Log "Son de demarrage charge : $($startupFile.Name)"
    }
    catch {
        Write-Log "Erreur lecture son de demarrage : $($_.Exception.Message)" "WARN"
    }
}

function Reset-AudioState {
    $Script:CurrentTrackList  = @()
    $Script:CurrentTrackIndex = -1
    $Script:CurrentArtistPath = $null
    $Script:CurrentAlbumPath  = $null
    $Script:CurrentArtistName = ""
    $Script:CurrentAlbumName  = ""
    if ($Script:AudioNowPlaying)          { $Script:AudioNowPlaying.Text          = "Lecture : aucune" }
    if ($Script:AudioSelectedArtistLabel) { $Script:AudioSelectedArtistLabel.Text = "Aucun artiste selectionne" }
    if ($Script:AudioSelectedAlbumLabel)  { $Script:AudioSelectedAlbumLabel.Text  = "Aucun album selectionne" }
    if ($Script:AudioSelectedStyleLabel)  { $Script:AudioSelectedStyleLabel.Text  = "Style : aucun" }
    if ($Script:AudioSummaryLabel)        { $Script:AudioSummaryLabel.Text        = "Choisis un style pour commencer." }
    if ($Script:AudioArtistPicture)       { $Script:AudioArtistPicture.Image      = $null; $Script:AudioArtistPicture.Visible = $false }
    if ($Script:AudioCoverPicture)        { $Script:AudioCoverPicture.Image       = $null; $Script:AudioCoverPicture.Visible = $false }
    if ($Script:AudioTrackList)           { $Script:AudioTrackList.Items.Clear() }
    if ($Script:AudioArtistFlow)          { $Script:AudioArtistFlow.Controls.Clear() }
    if ($Script:AudioAlbumFlow)           { $Script:AudioAlbumFlow.Controls.Clear() }
    if ($Script:AudioTrackTitle)          { $Script:AudioTrackTitle.Text          = "aucune" }
}

function Set-AudioView {
    param([string]$ViewName)
    foreach ($k in $Script:AudioViewPanels.Keys) { $Script:AudioViewPanels[$k].Visible = $false }
    foreach ($k in $Script:AudioNavButtons.Keys) {
        $Script:AudioNavButtons[$k].ForeColor = $audioText
        $Script:AudioNavButtons[$k].BackColor = $audioDark
        $Script:AudioNavButtons[$k].Font = New-Object System.Drawing.Font("Segoe UI",13,[System.Drawing.FontStyle]::Regular)
    }
    if ($Script:AudioViewPanels.ContainsKey($ViewName)) { $Script:AudioViewPanels[$ViewName].Visible = $true }
    if ($Script:AudioNavButtons.ContainsKey($ViewName)) {
        $Script:AudioNavButtons[$ViewName].ForeColor = $white
        $Script:AudioNavButtons[$ViewName].BackColor = $purpleActive
        $Script:AudioNavButtons[$ViewName].Font = New-Object System.Drawing.Font("Segoe UI",13,[System.Drawing.FontStyle]::Bold)
    }
    if ($Script:AudioPageBadgeLabel) {
        switch ($ViewName) {
            "Welcome" { $Script:AudioPageBadgeLabel.Text = "Page 01" }
            "Artists" { $Script:AudioPageBadgeLabel.Text = "Page 02" }
            "Albums"  { $Script:AudioPageBadgeLabel.Text = "Page 03" }
            "Songs"   { $Script:AudioPageBadgeLabel.Text = "Page 04" }
            "Finish"  { $Script:AudioPageBadgeLabel.Text = "Page 05" }
        }
    }
    if (Get-Command Update-ResponsiveLayout -ErrorAction SilentlyContinue) {
        Update-ResponsiveLayout
    }
}

function Get-AudioStyles {
    if (-not (Test-Path $Script:MusicRoot)) { return @() }
    return @(Get-ChildItem $Script:MusicRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -ExpandProperty Name)
}

function Load-AudioStyleList {
    if (-not $Script:AudioStyleCombo) { return }
    $Script:AudioStyleCombo.Items.Clear()
    foreach ($style in (Get-AudioStyles)) { [void]$Script:AudioStyleCombo.Items.Add($style) }
    if ($Script:AudioStyleCombo.Items.Count -gt 0) { $Script:AudioStyleCombo.SelectedIndex = 0 }
}

function New-AudioArtistCard {
    param([string]$ArtistPath)
    $card = New-Object System.Windows.Forms.Panel
    $card.Size = New-Object System.Drawing.Size(180,220)
    $card.BackColor = $audioCard
    $card.Margin = New-Object System.Windows.Forms.Padding(18)
    $card.Cursor = [System.Windows.Forms.Cursors]::Hand
    $card.Tag = $ArtistPath

    $pic = New-Object System.Windows.Forms.PictureBox
    $pic.Location = [System.Drawing.Point]::new(15,15)
    $pic.Size = New-Object System.Drawing.Size(150,135)
    $pic.SizeMode = "Zoom"
    $pic.BackColor = $audioPanel
    $pic.Tag = $ArtistPath
    $artistImg = Join-Path $ArtistPath "artist.jpg"
    $loadedImg = Load-ImageSafe -ImagePath $artistImg
    if ($loadedImg) { $pic.Image = $loadedImg }

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = Split-Path $ArtistPath -Leaf
    $lbl.Location = [System.Drawing.Point]::new(10,165)
    $lbl.Size = New-Object System.Drawing.Size(160,35)
    $lbl.TextAlign = "MiddleCenter"
    $lbl.ForeColor = $audioText
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
    $lbl.Tag = $ArtistPath

    $clickAction = { $path = $this.Tag; if (-not [string]::IsNullOrWhiteSpace($path)) { Show-AudioArtist -ArtistPath $path } }
    $card.Add_Click($clickAction); $pic.Add_Click($clickAction); $lbl.Add_Click($clickAction)
    $card.Controls.Add($pic); $card.Controls.Add($lbl)
    return $card
}

function Load-AudioArtists {
    param([string]$Style)
    if ([string]::IsNullOrWhiteSpace($Style)) { Write-Log "Aucun style musical selectionne" "WARN"; return }
    $Script:CurrentStyle = $Style
    if ($Script:AudioSelectedStyleLabel) { $Script:AudioSelectedStyleLabel.Text = "Style : $Style" }
    $Script:AudioArtistFlow.Controls.Clear()
    $artistRoot = Join-Path $Script:MusicRoot $Style
    if (-not (Test-Path $artistRoot)) { Write-Log "Dossier style introuvable : $artistRoot" "ERROR"; return }
    $validArtists = @()
    $artists = @(Get-ChildItem $artistRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name)
    foreach ($artist in $artists) {
        $albums = @(Get-ChildItem $artist.FullName -Directory -ErrorAction SilentlyContinue)
        $hasAudio = $false
        foreach ($album in $albums) {
            $tracks = @(Get-ChildItem $album.FullName -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in ".mp3",".wav",".flac" })
            if ($tracks.Count -gt 0) { $hasAudio = $true; break }
        }
        if ($hasAudio) { $validArtists += $artist }
    }
    foreach ($artist in $validArtists) { $Script:AudioArtistFlow.Controls.Add((New-AudioArtistCard -ArtistPath $artist.FullName)) }
    if ($Script:AudioSummaryLabel) { $Script:AudioSummaryLabel.Text = "$($validArtists.Count) artiste(s) detecte(s) dans $Style." }
    Write-Log "Style : $Style | $($validArtists.Count) artiste(s)"
    Set-AudioView "Artists"
}

function Show-AudioArtist {
    param([string]$ArtistPath)
    if ([string]::IsNullOrWhiteSpace($ArtistPath) -or -not (Test-Path $ArtistPath)) {
        Write-Log "Dossier artiste introuvable" "ERROR"; return
    }
    $Script:CurrentArtistPath = $ArtistPath
    $Script:CurrentArtistName = Split-Path $ArtistPath -Leaf
    if ($Script:AudioSelectedArtistLabel) { $Script:AudioSelectedArtistLabel.Text = "Artiste : $($Script:CurrentArtistName)" }
    $artistImg = Join-Path $ArtistPath "artist.jpg"
    $loadedArtist = Load-ImageSafe -ImagePath $artistImg
    if ($loadedArtist) { $Script:AudioArtistPicture.Image = $loadedArtist }
    else { $Script:AudioArtistPicture.Image = $null }
    Load-AudioAlbums -ArtistPath $ArtistPath
    Set-AudioView "Albums"
    Write-Log "Artiste charge : $($Script:CurrentArtistName)"
}

function New-AudioAlbumCard {
    param([string]$AlbumPath)
    $card = New-Object System.Windows.Forms.Panel
    $card.Size = New-Object System.Drawing.Size(150,180)
    $card.BackColor = $audioCard
    $card.Margin = New-Object System.Windows.Forms.Padding(12)
    $card.Cursor = [System.Windows.Forms.Cursors]::Hand
    $card.Tag = $AlbumPath

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = Split-Path $AlbumPath -Leaf
    $lbl.Location = [System.Drawing.Point]::new(10,8)
    $lbl.Size = New-Object System.Drawing.Size(130,24)
    $lbl.TextAlign = "MiddleCenter"
    $lbl.ForeColor = $audioText
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $lbl.Tag = $AlbumPath

    $pic = New-Object System.Windows.Forms.PictureBox
    $pic.Location = [System.Drawing.Point]::new(20,40)
    $pic.Size = New-Object System.Drawing.Size(110,110)
    $pic.SizeMode = "Zoom"
    $pic.BackColor = $audioPanel
    $pic.Tag = $AlbumPath
    $cover = Join-Path $AlbumPath "cover.jpg"
    $loadedCover = Load-ImageSafe -ImagePath $cover
    if ($loadedCover) { $pic.Image = $loadedCover }

    $clickAction = { $path = $this.Tag; if (-not [string]::IsNullOrWhiteSpace($path)) { Show-AudioAlbum -AlbumPath $path } }
    $card.Add_Click($clickAction); $pic.Add_Click($clickAction); $lbl.Add_Click($clickAction)
    $card.Controls.Add($lbl); $card.Controls.Add($pic)
    return $card
}

function Load-AudioAlbums {
    param([string]$ArtistPath)
    if ([string]::IsNullOrWhiteSpace($ArtistPath) -or -not (Test-Path $ArtistPath)) { return }
    $Script:AudioAlbumFlow.Controls.Clear()
    $albums = @(Get-ChildItem $ArtistPath -Directory -ErrorAction SilentlyContinue | Sort-Object Name)
    foreach ($album in $albums) { $Script:AudioAlbumFlow.Controls.Add((New-AudioAlbumCard -AlbumPath $album.FullName)) }
    if ($Script:AudioSummaryLabel) { $Script:AudioSummaryLabel.Text = "$($albums.Count) album(s) pour $($Script:CurrentArtistName)." }
    if ($albums.Count -eq 0) { Write-Log "Aucun album : $($Script:CurrentArtistName)" "WARN" }
    else { Write-Log "Albums : $($Script:CurrentArtistName) / $($albums.Count)" }
}

function Show-AudioAlbum {
    param([string]$AlbumPath)
    if ([string]::IsNullOrWhiteSpace($AlbumPath) -or -not (Test-Path $AlbumPath)) {
        Write-Log "Dossier album introuvable" "ERROR"; return
    }
    $Script:CurrentAlbumPath = $AlbumPath
    $Script:CurrentAlbumName = Split-Path $AlbumPath -Leaf
    if ($Script:AudioSelectedAlbumLabel) { $Script:AudioSelectedAlbumLabel.Text = "Album : $($Script:CurrentAlbumName)" }
    $cover = Join-Path $AlbumPath "cover.jpg"
    $loadedCover = Load-ImageSafe -ImagePath $cover
    if ($loadedCover) { $Script:AudioCoverPicture.Image = $loadedCover }
    else { $Script:AudioCoverPicture.Image = $null }
    Load-AudioTracks -AlbumPath $AlbumPath
    Set-AudioView "Songs"
    Write-Log "Album charge : $($Script:CurrentAlbumName)"
}

function Load-AudioTracks {
    param([string]$AlbumPath)
    if ([string]::IsNullOrWhiteSpace($AlbumPath) -or -not (Test-Path $AlbumPath)) { return }
    $Script:AudioTrackList.Items.Clear()
    $tracks = @(Get-ChildItem $AlbumPath -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in ".mp3",".wav",".flac" } | Sort-Object Name)
    $Script:CurrentTrackList  = @($tracks)
    $Script:CurrentTrackIndex = -1
    foreach ($track in $tracks) { [void]$Script:AudioTrackList.Items.Add($track.BaseName) }
    if ($Script:AudioSummaryLabel) { $Script:AudioSummaryLabel.Text = "$($tracks.Count) chanson(s) dans $($Script:CurrentAlbumName)." }
    if ($tracks.Count -eq 0) { Write-Log "Aucune musique dans l album" "WARN" }
    else { Write-Log "Album : $($Script:CurrentAlbumName) / $($tracks.Count) chanson(s)" }
}

function Update-AudioNowPlaying { param([string]$Text)
    if ($Script:AudioNowPlaying) { $Script:AudioNowPlaying.Text = "Lecture : $Text" }
    if ($Script:AudioTrackTitle) { $Script:AudioTrackTitle.Text = $Text }
}

function Play-AudioTrackByIndex {
    param([int]$Index)
    if (-not $Script:CurrentTrackList -or $Script:CurrentTrackList.Count -eq 0) { Write-Log "Aucune chanson" "WARN"; return }
    if ($Index -lt 0 -or $Index -ge $Script:CurrentTrackList.Count) { return }
    $track = $Script:CurrentTrackList[$Index]
    $Script:CurrentTrackIndex = $Index
    try {
        $uri = New-Object System.Uri($track.FullName)
        $Script:MediaPlayer.Open($uri)
        $Script:MediaPlayer.Play()
        Update-AudioNowPlaying $track.BaseName
        Write-Log "Lecture : $($track.BaseName)"
    } catch { Write-Log "Impossible de lire : $($track.FullName)" "ERROR" }
}

function Play-SelectedAudioTrack {
    if ($Script:AudioTrackList.SelectedIndex -ge 0) { Play-AudioTrackByIndex -Index $Script:AudioTrackList.SelectedIndex }
    else { Write-Log "Aucune chanson selectionnee" "WARN" }
}

function Pause-AudioTrack { try { $Script:MediaPlayer.Pause(); Write-Log "Pause" } catch {} }
function Stop-AudioTrack  { try { $Script:MediaPlayer.Stop(); Update-AudioNowPlaying "aucune"; Write-Log "Stop" } catch {} }
function Next-AudioTrack  {
    if (-not $Script:CurrentTrackList -or $Script:CurrentTrackList.Count -eq 0) { return }
    if ($Script:CurrentTrackIndex -lt ($Script:CurrentTrackList.Count - 1)) {
        Play-AudioTrackByIndex -Index ($Script:CurrentTrackIndex + 1)
        $Script:AudioTrackList.SelectedIndex = $Script:CurrentTrackIndex
    } else { Write-Log "Derniere chanson" "WARN" }
}
function Previous-AudioTrack {
    if (-not $Script:CurrentTrackList -or $Script:CurrentTrackList.Count -eq 0) { return }
    if ($Script:CurrentTrackIndex -gt 0) {
        Play-AudioTrackByIndex -Index ($Script:CurrentTrackIndex - 1)
        $Script:AudioTrackList.SelectedIndex = $Script:CurrentTrackIndex
    } else { Write-Log "Premiere chanson" "WARN" }
}

# =========================================================
# CONSTRUCTION DU FORMULAIRE
# =========================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "ClickByChris Setup Tool V5.0 Ultra Premium - Multi-PC Stage 2"
$form.StartPosition = "CenterScreen"
$form.BackColor = $bgMain
$form.ForeColor = $white
$form.WindowState = "Maximized"
$form.FormBorderStyle = "None"
$form.TopMost = $false
$form.KeyPreview = $true
$form.Add_KeyDown({ if ($_.KeyCode -eq "Escape") { $form.Close() } })

# -------------------------
# PANEL GAUCHE (navigation)
# -------------------------
$leftPanel = New-Object System.Windows.Forms.Panel
$leftPanel.Dock = 'Left'
$leftPanel.Width = 260
$leftPanel.BackColor = $bgPanel
$form.Controls.Add($leftPanel)

# Logo
$logoBox = New-Object System.Windows.Forms.PictureBox
$logoBox.Location = [System.Drawing.Point]::new(25,20)
$logoBox.Size = New-Object System.Drawing.Size(210,210)
$logoBox.SizeMode = "Zoom"
$logoBox.BackColor = $bgPanel
$img = Load-ImageSafe -ImagePath $Script:LogoPath
if ($img) { $logoBox.Image = $img }
$leftPanel.Controls.Add($logoBox)

$title1 = New-Object System.Windows.Forms.Label
$title1.Text = "ClickByChris"
$title1.Location = [System.Drawing.Point]::new(30,245)
$title1.Size = New-Object System.Drawing.Size(200,35)
$title1.Font = New-Object System.Drawing.Font("Segoe UI",18,[System.Drawing.FontStyle]::Bold)
$title1.ForeColor = $white
$leftPanel.Controls.Add($title1)

$title2 = New-Object System.Windows.Forms.Label
$title2.Text = "Setup Tool V1.0"
$title2.Location = [System.Drawing.Point]::new(32,280)
$title2.Size = New-Object System.Drawing.Size(210,25)
$title2.Font = New-Object System.Drawing.Font("Segoe UI",10)
$title2.ForeColor = $yellow
$leftPanel.Controls.Add($title2)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = "Modern UI  Ultra Premium Audio"
$subtitle.Location = [System.Drawing.Point]::new(32,308)
$subtitle.Size = New-Object System.Drawing.Size(205,22)
$subtitle.Font = New-Object System.Drawing.Font("Segoe UI",8)
$subtitle.ForeColor = $muted
$leftPanel.Controls.Add($subtitle)

# Version badge
$versionLabel = New-Object System.Windows.Forms.Label
$versionLabel.Text = "V1.0 - 2026"
$versionLabel.Location = [System.Drawing.Point]::new(32,330)
$versionLabel.Size = New-Object System.Drawing.Size(200,18)
$versionLabel.Font = New-Object System.Drawing.Font("Segoe UI",8)
$versionLabel.ForeColor = [System.Drawing.Color]::FromArgb(114,96,255)
$leftPanel.Controls.Add($versionLabel)

# Panneau navigation
$navPanel = New-Object System.Windows.Forms.Panel
$navPanel.Location = [System.Drawing.Point]::new(20,360)
$navPanel.Size = New-Object System.Drawing.Size(220,510)
$navPanel.BackColor = $bgPanel
$leftPanel.Controls.Add($navPanel)

# Panel principal contenu
$contentPanel = New-Object System.Windows.Forms.Panel
$contentPanel.Location = [System.Drawing.Point]::new(275,20)
$contentPanel.Size = New-Object System.Drawing.Size(1080,650)
$contentPanel.BackColor = $bgMain
$form.Controls.Add($contentPanel)

function New-PagePanel {
    $p = New-Object System.Windows.Forms.Panel
    $p.Dock = 'Fill'
    $p.BackColor = $bgMain
    $p.Visible = $false
    $contentPanel.Controls.Add($p)
    return $p
}

$pageHome    = New-PagePanel
$pageInfo    = New-PagePanel
$pageApps    = New-PagePanel
$pageRun     = New-PagePanel
$pageOpt     = New-PagePanel
$pageOpt.AutoScroll = $true
$pageDrv     = New-PagePanel
$pageTools   = New-PagePanel
$pageShort   = New-PagePanel
$pageAudio   = New-PagePanel
$pageContact = New-PagePanel
$pageLogs    = New-PagePanel

function Set-ActivePage {
    param($targetPage, $targetButton)
    foreach ($p in @($pageHome,$pageInfo,$pageApps,$pageRun,$pageOpt,$pageDrv,$pageTools,$pageShort,$pageAudio,$pageContact,$pageLogs)) {
        $p.Visible = $false
    }
    $targetPage.Visible = $true
    Set-NavActiveButton -Button $targetButton
}

function New-NavButton {
    param($text,$y)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Location = [System.Drawing.Point]::new(5,[int]$y)
    $btn.Size = New-Object System.Drawing.Size(210,42)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.BackColor = $bgCard
    $btn.ForeColor = $white
    $btn.Font = New-Object System.Drawing.Font("Segoe UI",10.5,[System.Drawing.FontStyle]::Bold)
    $btn.Add_MouseEnter({ if ($this.Tag -ne 'nav-active') { $this.BackColor = $purpleHover } })
    $btn.Add_MouseLeave({ if ($this.Tag -ne 'nav-active') { $this.BackColor = $bgCard } })
    $Script:NavButtons += $btn
    $navPanel.Controls.Add($btn)
    return $btn
}

$navHome    = New-NavButton "Accueil"           0
$navInfo    = New-NavButton "Infos PC"          46
$navApps    = New-NavButton "Applications"      92
$navRun     = New-NavButton "Compatibilite"     138
$navOpt     = New-NavButton "Optimisation"      184
$navDrv     = New-NavButton "Drivers"           230
$navTools   = New-NavButton "Outils"            276
$navShort   = New-NavButton "Raccourcis"        322
$navAudio   = New-NavButton "Audio Premium"     460
$navAudio.Visible = $false
$navAudio.Enabled = $false
$navContact = New-NavButton "Contact / Aide"    368
$navLogs    = New-NavButton "Logs"              414

# =========================================================
# ACTIVATION WINDOWS/OFFICE
# =========================================================

function Activate-WindowsOffice {
    # Dialog de confirmation
    $title = "⚠️ Activation Windows/Office"
    $msg = "Vous etes sur le point d'executer le script d'activation.`r`n`r`nCette action :`r`n• Necessite les droits Admin`r`n• Peut trigger l'antivirus`r`n• Modifie votre licence Windows/Office`r`n`r`nEtes-vous sur ?"

    $choice = [System.Windows.Forms.MessageBox]::Show(
        $msg, 
        $title, 
        [System.Windows.Forms.MessageBoxButtons]::YesNo, 
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) {
        Write-Log "Activation annulee par l'utilisateur"
        Add-ExecutionResult -Name "Activation Windows/Office" -Status "SKIP" -Detail "Utilisateur a decline"
        return
    }

    Start-ExecutionReport "Activation Windows/Office"
    Write-Log "Lancement de l'activation Windows/Office..."

    try {
        $activationUrl = "https://get.activated.win"
        Write-Log "Telechargement du script d'activation depuis : $activationUrl"

        $result = Invoke-RestMethod -Uri $activationUrl -ErrorAction Stop
        Invoke-Expression $result

        Add-ExecutionResult -Name "Activation Windows/Office" -Status "OK" -Detail "Script execute avec succes"
        Write-Log "Script d'activation execute"
    }
    catch {
        Add-ExecutionResult -Name "Activation Windows/Office" -Status "ERROR" -Detail $_.Exception.Message
        Write-Log "Erreur lors de l'activation : $($_.Exception.Message)" "ERROR"
    }

    Show-ExecutionSummary "Activation Windows/Office"
}

# =========================================================
# PAGE ACCUEIL
# =========================================================
$homeTitle = New-Object System.Windows.Forms.Label
$homeTitle.Text = "Bienvenue dans ClickByChris Setup Tool v1.0.0"
$homeTitle.Location = [System.Drawing.Point]::new(25,25)
$homeTitle.Size = New-Object System.Drawing.Size(880,42)
$homeTitle.Font = New-Object System.Drawing.Font("Segoe UI",20,[System.Drawing.FontStyle]::Bold)
$homeTitle.ForeColor = $white
$pageHome.Controls.Add($homeTitle)

$homeDesc = New-Object System.Windows.Forms.Label
$homeDesc.Text = "Centre de pilotage Windows : analyse PC, applications, compatibilite logicielle, optimisation safe, structure admin, raccourcis et son de demarrage."
$homeDesc.Location = [System.Drawing.Point]::new(28,78)
$homeDesc.Size = New-Object System.Drawing.Size(1000,40)
$homeDesc.Font = New-Object System.Drawing.Font("Segoe UI",10)
$homeDesc.ForeColor = $muted
$pageHome.Controls.Add($homeDesc)

# Cartes actions home
$homeButtonDefs = @(
    @{Label="Infos PC"; Color=$bgCard},
    @{Label="Applications"; Color=$bgCard},
    @{Label="Compatibilite"; Color=$bgCard},
    @{Label="Optimisation"; Color=$bgCard},
    @{Label="Outils"; Color=$bgCard},
    @{Label="Assistant TOUT FAIRE"; Color=$blue}
)
$homeButtons = @()
for ($i=0; $i -lt $homeButtonDefs.Count; $i++) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $homeButtonDefs[$i].Label
    $btn.Size = New-Object System.Drawing.Size(250,70)
    $x = 30 + (($i % 3) * 280)
    $y = 140 + ([math]::Floor($i / 3) * 95)
    $btn.Location = [System.Drawing.Point]::new([int]$x,[int]$y)
    $btn.BackColor = $bgCard
    $btn.ForeColor = $white
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
    $pageHome.Controls.Add($btn)
    $homeButtons += $btn
}

# =========================================================
# BOUTON ACTIVATION WINDOWS / OFFICE
# =========================================================

$btnActivate = New-Object System.Windows.Forms.Button
$btnActivate.Text = "Activation`r`nWindows/Office"

# Taille du bouton
$btnActivate.Size = New-Object System.Drawing.Size(180,115)

# Position EXACTE style screenshot
$btnActivate.Location = [System.Drawing.Point]::new(660,660)

# Style visuel
$btnActivate.BackColor = ([System.Drawing.Color]::FromArgb(26,26,30))
$btnActivate.ForeColor = ([System.Drawing.Color]::FromArgb(220,40,40))

$btnActivate.FlatStyle = "Flat"
$btnActivate.FlatAppearance.BorderSize = 0
$btnActivate.FlatAppearance.MouseDownBackColor = ([System.Drawing.Color]::FromArgb(40,40,48))
$btnActivate.FlatAppearance.MouseOverBackColor = ([System.Drawing.Color]::FromArgb(34,34,40))

# Police
$btnActivate.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    10,
    [System.Drawing.FontStyle]::Bold
)

# Curseur
$btnActivate.Cursor = [System.Windows.Forms.Cursors]::Hand

# Alignements
$btnActivate.ImageAlign = [System.Drawing.ContentAlignment]::TopCenter
$btnActivate.TextAlign = [System.Drawing.ContentAlignment]::BottomCenter
$btnActivate.TextImageRelation = "ImageAboveText"

# Padding interne
$btnActivate.Padding = New-Object System.Windows.Forms.Padding(0,10,0,8)

# =========================================================
# ICONE
# =========================================================

$activateIconPath = Join-Path $Script:AssetsRoot "Icons\V2\19_activation_office.png"

if (Test-Path $activateIconPath) {
    try {
        $icon = [System.Drawing.Image]::FromFile($activateIconPath)
        # Taille icône propre
        $resizedIcon = New-Object System.Drawing.Bitmap($icon, 52, 52)
        $btnActivate.Image = $resizedIcon
        $icon.Dispose()
    }
    catch {
        Write-Log "Erreur chargement icone activation : $_"
    }
}

# =========================================================
# ARRONDI PREMIUM
# =========================================================

Set-ControlRounded -Control $btnActivate -Radius 22

# =========================================================
# EFFETS HOVER AVANCES
# =========================================================

$btnActivate.Add_MouseEnter({
    $this.BackColor = ([System.Drawing.Color]::FromArgb(36,36,42))
    $this.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
})

$btnActivate.Add_MouseLeave({
    $this.BackColor = ([System.Drawing.Color]::FromArgb(26,26,30))
    $this.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
})

# =========================================================
# GESTION MEMOIRE ICONE
# =========================================================

$btnActivate.Add_Disposed({
    if ($btnActivate.Image) {
        $btnActivate.Image.Dispose()
    }
})

# =========================================================
# CLICK
# =========================================================

$btnActivate.Add_Click({
    Set-ActivePage $pageLogs $navLogs
    Start-ExecutionReport "Activation Windows/Office"
    Write-Log "Activation de Windows/Office"
    Activate-WindowsOffice
    Show-ExecutionSummary "Activation Windows/Office"
})

# =========================================================
# AJOUT PAGE
# =========================================================

$pageHome.Controls.Add($btnActivate)


# Tip home
$homeTip = New-Object System.Windows.Forms.Label
$homeTip.Text = "Les cartes du centre servent de raccourcis de navigation. Les actions directes d execution restent dans la barre du bas."
$homeTip.Location = [System.Drawing.Point]::new(28,418)
$homeTip.Size = New-Object System.Drawing.Size(950,32)
$homeTip.Font = New-Object System.Drawing.Font("Segoe UI",10)
$homeTip.ForeColor = $yellow

$pageHome.Controls.Add($homeTip)

$homeCard1 = New-Object System.Windows.Forms.Panel
$homeCard1.Location = [System.Drawing.Point]::new(28,462)
$homeCard1.Size = New-Object System.Drawing.Size(470,142)
$homeCard1.BackColor = [System.Drawing.Color]::FromArgb(20,22,34)
$pageHome.Controls.Add($homeCard1)

$homeCard1Title = New-Object System.Windows.Forms.Label
$homeCard1Title.Text = "Etape a suivre"
$homeCard1Title.Location = [System.Drawing.Point]::new(18,14)
$homeCard1Title.Size = New-Object System.Drawing.Size(220,24)
$homeCard1Title.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$homeCard1Title.ForeColor = $white
$homeCard1.Controls.Add($homeCard1Title)

$homeCard1Body = New-Object System.Windows.Forms.RichTextBox
$homeCard1Body.Text = "Verifier les infos PC pour identifier rapidement la machine.`r`nChoisir ensuite les applications et les composants utiles.`r`nTerminer avec l Assistant TOUT FAIRE pour executer proprement les actions selectionnees."
$homeCard1Body.Location = [System.Drawing.Point]::new(16,44)
$homeCard1Body.Size = New-Object System.Drawing.Size(438,84)
$homeCard1Body.Font = New-Object System.Drawing.Font("Segoe UI",9)
$homeCard1Body.ForeColor = [System.Drawing.Color]::FromArgb(185,188,198)
$homeCard1Body.BackColor = $homeCard1.BackColor
$homeCard1Body.BorderStyle = "None"
$homeCard1Body.ReadOnly = $true
$homeCard1Body.ScrollBars = "Vertical"
$homeCard1.Controls.Add($homeCard1Body)

$homeCard2 = New-Object System.Windows.Forms.Panel
$homeCard2.Location = [System.Drawing.Point]::new(520,462)
$homeCard2.Size = New-Object System.Drawing.Size(520,142)
$homeCard2.BackColor = [System.Drawing.Color]::FromArgb(23,19,36)
$pageHome.Controls.Add($homeCard2)

$homeCard2Title = New-Object System.Windows.Forms.Label
$homeCard2Title.Text = "Important"
$homeCard2Title.Location = [System.Drawing.Point]::new(18,14)
$homeCard2Title.Size = New-Object System.Drawing.Size(200,24)
$homeCard2Title.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$homeCard2Title.ForeColor = $yellow
$homeCard2.Controls.Add($homeCard2Title)

$homeCard2Body = New-Object System.Windows.Forms.RichTextBox
$homeCard2Body.Text = "La page Accueil sert de guide principal.`r`n`r`nLe menu de gauche permet de naviguer entre les modules.`r`n`r`nLa barre du bas sert aux actions directes.`r`n`r`nL Assistant TOUT FAIRE affiche un resume detaille avant toute execution."
$homeCard2Body.Location = [System.Drawing.Point]::new(16,42)
$homeCard2Body.Size = New-Object System.Drawing.Size(486,88)
$homeCard2Body.Font = New-Object System.Drawing.Font("Segoe UI",9)
$homeCard2Body.ForeColor = [System.Drawing.Color]::FromArgb(185,188,198)
$homeCard2Body.BackColor = $homeCard2.BackColor
$homeCard2Body.BorderStyle = "None"
$homeCard2Body.ReadOnly = $true
$homeCard2Body.ScrollBars = "Vertical"
$homeCard2.Controls.Add($homeCard2Body)

# =========================================================
# PAGE INFOS PC
# =========================================================
$infoTitle = New-Object System.Windows.Forms.Label
$infoTitle.Text = "Analyse du systeme"
$infoTitle.Location = [System.Drawing.Point]::new(25,18)
$infoTitle.Size = New-Object System.Drawing.Size(400,30)
$infoTitle.Font = New-Object System.Drawing.Font("Segoe UI",15,[System.Drawing.FontStyle]::Bold)
$infoTitle.ForeColor = $white
$pageInfo.Controls.Add($infoTitle)

$btnScanInfo = New-Object System.Windows.Forms.Button
$btnScanInfo.Text = "Rafraichir"
$btnScanInfo.Location = [System.Drawing.Point]::new(450,12)
$btnScanInfo.Size = New-Object System.Drawing.Size(150,38)
$btnScanInfo.BackColor = $blue
$btnScanInfo.ForeColor = $black
$btnScanInfo.FlatStyle = "Flat"
$btnScanInfo.FlatAppearance.BorderSize = 0
$btnScanInfo.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$pageInfo.Controls.Add($btnScanInfo)

$Script:InfoGrid = New-Object System.Windows.Forms.DataGridView
$Script:InfoGrid.Location = [System.Drawing.Point]::new(25,60)
$Script:InfoGrid.Size = New-Object System.Drawing.Size(1000,520)
$Script:InfoGrid.Anchor = 'Top,Bottom,Left,Right'
$Script:InfoGrid.BackgroundColor = $bgCard
$Script:InfoGrid.GridColor = $bgPanel
$Script:InfoGrid.ColumnHeadersDefaultCellStyle.BackColor = $bgPanel
$Script:InfoGrid.ColumnHeadersDefaultCellStyle.ForeColor = $white
$Script:InfoGrid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$Script:InfoGrid.EnableHeadersVisualStyles = $false
$Script:InfoGrid.DefaultCellStyle.BackColor = $bgCard
$Script:InfoGrid.DefaultCellStyle.ForeColor = $white
$Script:InfoGrid.DefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI",10)
$Script:InfoGrid.DefaultCellStyle.SelectionBackColor = $purpleActive
$Script:InfoGrid.DefaultCellStyle.SelectionForeColor = $white
$Script:InfoGrid.AlternatingRowsDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(28,28,36)
$Script:InfoGrid.AlternatingRowsDefaultCellStyle.ForeColor = $white
$Script:InfoGrid.RowHeadersVisible = $false
$Script:InfoGrid.AllowUserToAddRows = $false
$Script:InfoGrid.AllowUserToDeleteRows = $false
$Script:InfoGrid.ReadOnly = $true
$Script:InfoGrid.RowTemplate.Height = 32
[void]$Script:InfoGrid.Columns.Add("Nom","Propriete")
[void]$Script:InfoGrid.Columns.Add("Valeur","Valeur")
$Script:InfoGrid.Columns[0].Width = 240
$Script:InfoGrid.Columns[1].AutoSizeMode = 'Fill'
$pageInfo.Controls.Add($Script:InfoGrid)

# =========================================================
# PAGE APPLICATIONS
# =========================================================
$appsTitle = New-Object System.Windows.Forms.Label
$appsTitle.Text = "Installation des applications"
$appsTitle.Location = [System.Drawing.Point]::new(25,18)
$appsTitle.Size = New-Object System.Drawing.Size(500,30)
$appsTitle.Font = New-Object System.Drawing.Font("Segoe UI",15,[System.Drawing.FontStyle]::Bold)
$appsTitle.ForeColor = $white
$pageApps.Controls.Add($appsTitle)

# Barre de recherche
$lblSearchApps = New-Object System.Windows.Forms.Label
$lblSearchApps.Text = "Recherche :"
$lblSearchApps.Location = [System.Drawing.Point]::new(25,58)
$lblSearchApps.Size = New-Object System.Drawing.Size(120,26)
$lblSearchApps.Font = New-Object System.Drawing.Font("Segoe UI",10)
$lblSearchApps.ForeColor = $muted
$pageApps.Controls.Add($lblSearchApps)

$txtSearchApps = New-Object System.Windows.Forms.TextBox
$txtSearchApps.Location = [System.Drawing.Point]::new(148,55)
$txtSearchApps.Size = New-Object System.Drawing.Size(220,26)
$txtSearchApps.BackColor = $bgCard
$txtSearchApps.ForeColor = $white
$txtSearchApps.BorderStyle = "None"
$txtSearchApps.Font = New-Object System.Drawing.Font("Segoe UI",11)
$pageApps.Controls.Add($txtSearchApps)

$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "Tout cocher"
$btnSelectAll.Location = [System.Drawing.Point]::new(390,50)
$btnSelectAll.Size = New-Object System.Drawing.Size(120,32)
$btnSelectAll.BackColor = $bgCard
$btnSelectAll.ForeColor = $green
$btnSelectAll.FlatStyle = "Flat"
$btnSelectAll.FlatAppearance.BorderSize = 0
$btnSelectAll.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$pageApps.Controls.Add($btnSelectAll)

$btnDeselectAll = New-Object System.Windows.Forms.Button
$btnDeselectAll.Text = "Tout decocher"
$btnDeselectAll.Location = [System.Drawing.Point]::new(520,50)
$btnDeselectAll.Size = New-Object System.Drawing.Size(130,32)
$btnDeselectAll.BackColor = $bgCard
$btnDeselectAll.ForeColor = $red
$btnDeselectAll.FlatStyle = "Flat"
$btnDeselectAll.FlatAppearance.BorderSize = 0
$btnDeselectAll.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$pageApps.Controls.Add($btnDeselectAll)

# Panel scrollable pour les apps
$appsScrollPanel = New-Object System.Windows.Forms.Panel
$appsScrollPanel.Location = [System.Drawing.Point]::new(20,98)
$appsScrollPanel.Size = New-Object System.Drawing.Size(1040,500)
$appsScrollPanel.BackColor = $bgMain
$appsScrollPanel.AutoScroll = $true
$pageApps.Controls.Add($appsScrollPanel)

# Apps par catégorie avec headers
$appY = 5
$defaultChecked = @("Firefox","Discord","VLC","Steam","Spotify","Notepad++","WinRAR","BCUninstaller","CrystalDiskInfo","HWMonitor","Rufus","Malwarebytes","Google Chrome","VS Code","CPU-Z","GPU-Z","PowerToys")
foreach ($catName in $Script:AppCategories.Keys) {
    # Header catégorie
    $catLabel = New-Object System.Windows.Forms.Label
    $catLabel.Text = $catName
    $catLabel.Location = [System.Drawing.Point]::new(10,$appY)
    $catLabel.Size = New-Object System.Drawing.Size(400,26)
    $catLabel.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $catLabel.ForeColor = $yellow
    $appsScrollPanel.Controls.Add($catLabel)
    $appY += 30

    # Séparateur
    $sep = New-Object System.Windows.Forms.Panel
    $sep.Location = [System.Drawing.Point]::new(10,$appY)
    $sep.Size = New-Object System.Drawing.Size(1000,1)
    $sep.BackColor = [System.Drawing.Color]::FromArgb(60,60,80)
    $appsScrollPanel.Controls.Add($sep)
    $appY += 8

    $colIdx = 0
    foreach ($appName in $Script:AppCategories[$catName].Keys) {
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = $appName
        $cb.ForeColor = $white
        $cb.BackColor = $bgMain
        $cb.Font = New-Object System.Drawing.Font("Segoe UI",10)
        $cb.AutoSize = $true
        $cb.Checked = ($appName -in $defaultChecked)
        $x = 15 + ($colIdx % 4) * 255
        $y = $appY + ([math]::Floor($colIdx / 4) * 36)
        $cb.Location = [System.Drawing.Point]::new([int]$x,[int]$y)
        $appsScrollPanel.Controls.Add($cb)
        $Script:AppCheckboxes += $cb
        $colIdx++
    }
    $rows = [math]::Ceiling($colIdx / 4)
    $appY += ($rows * 36) + 16
}

# Recherche dynamique
$txtSearchApps.Add_TextChanged({
    $query = $txtSearchApps.Text.ToLower().Trim()
    foreach ($cb in $Script:AppCheckboxes) {
        if ([string]::IsNullOrWhiteSpace($query)) { $cb.Visible = $true }
        else { $cb.Visible = $cb.Text.ToLower().Contains($query) }
    }
})
$btnSelectAll.Add_Click({   foreach ($cb in $Script:AppCheckboxes) { if ($cb.Visible) { $cb.Checked = $true  } } })
$btnDeselectAll.Add_Click({ foreach ($cb in $Script:AppCheckboxes) { if ($cb.Visible) { $cb.Checked = $false } } })

# =========================================================
# PAGE RUNTIMES
# =========================================================
$runTitle = New-Object System.Windows.Forms.Label
$runTitle.Text = "Composants de compatibilite"
$runTitle.Location = [System.Drawing.Point]::new(25,18)
$runTitle.Size = New-Object System.Drawing.Size(500,30)
$runTitle.Font = New-Object System.Drawing.Font("Segoe UI",15,[System.Drawing.FontStyle]::Bold)
$runTitle.ForeColor = $white
$pageRun.Controls.Add($runTitle)

$runDesc = New-Object System.Windows.Forms.Label
$runDesc.Text = "Ces composants de compatibilite sont necessaires au bon fonctionnement de nombreux logiciels, jeux et utilitaires Windows."
$runDesc.Location = [System.Drawing.Point]::new(25,58)
$runDesc.Size = New-Object System.Drawing.Size(900,26)
$runDesc.Font = New-Object System.Drawing.Font("Segoe UI",10)
$runDesc.ForeColor = $muted
$pageRun.Controls.Add($runDesc)

$rIdx = 0
foreach ($rName in $Script:RuntimeMap.Keys) {
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $rName
    $cb.ForeColor = $white
    $cb.BackColor = $bgMain
    $cb.Font = New-Object System.Drawing.Font("Segoe UI",11)
    $cb.AutoSize = $true
    $cb.Checked = $true
    $cb.Location = [System.Drawing.Point]::new(35,(100 + $rIdx * 48))
    $Script:RuntimeCheckboxes += $cb
    $pageRun.Controls.Add($cb)
    $rIdx++
}

$runtimeNote = New-Object System.Windows.Forms.Label
$runtimeNote.Text = "Note : les packs Visual C++ 2005 / 2008 / 2010 / 2012 / 2013 sont surtout utiles pour la compatibilite avec des logiciels anciens, notamment sur d anciens PC ou des systemes comme Windows 7.`r`nLes runtimes 2015-2022, .NET et WebView2 restent les plus utiles pour les applications modernes."
$runtimeNote.Location = [System.Drawing.Point]::new(35,(120 + $rIdx * 48))
$runtimeNote.Size = New-Object System.Drawing.Size(950,60)
$runtimeNote.ForeColor = $yellow
$runtimeNote.Font = New-Object System.Drawing.Font("Segoe UI",9)
$pageRun.Controls.Add($runtimeNote)


# =========================================================
# PAGE OPTIMISATION
# =========================================================
$optTitle = New-Object System.Windows.Forms.Label
$optTitle.Text = "Optimisation Windows (Safe / Gaming / Avance)"
$optTitle.Location = [System.Drawing.Point]::new(25,18)
$optTitle.Size = New-Object System.Drawing.Size(820,30)
$optTitle.Font = New-Object System.Drawing.Font("Segoe UI",15,[System.Drawing.FontStyle]::Bold)
$optTitle.ForeColor = $white
$pageOpt.Controls.Add($optTitle)

$optDesc = New-Object System.Windows.Forms.Label
$optDesc.Text = "Choisis les reglages a appliquer. Le bloc SAFE est recommande. Le bloc Gaming est optionnel. Le bloc Avance peut presenter des risques et reste sous ta responsabilite."
$optDesc.Location = [System.Drawing.Point]::new(25,56)
$optDesc.Size = New-Object System.Drawing.Size(980,38)
$optDesc.Font = New-Object System.Drawing.Font("Segoe UI",10)
$optDesc.ForeColor = $muted
$pageOpt.Controls.Add($optDesc)

function New-OptGroupPanel {
    param(
        [string]$Title,
        [string]$Subtitle,
        [int]$X,
        [int]$Y,
        [int]$W,
        [int]$H,
        [System.Drawing.Color]$Accent
    )

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = [System.Drawing.Point]::new($X,$Y)
    $panel.Size = New-Object System.Drawing.Size($W,$H)
    $panel.BackColor = $bgCard
    Set-ControlRounded -Control $panel -Radius 18
    $panel.Add_SizeChanged({ Set-ControlRounded -Control $this -Radius 18 })

    $bar = New-Object System.Windows.Forms.Panel
    $bar.Location = [System.Drawing.Point]::new(0,0)
    $bar.Size = New-Object System.Drawing.Size($W,6)
    $bar.BackColor = $Accent
    $panel.Controls.Add($bar)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = $Title
    $lblTitle.Location = [System.Drawing.Point]::new(18,16)
    $lblTitle.Size = New-Object System.Drawing.Size(($W - 36),26)
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = $white
    $panel.Controls.Add($lblTitle)

    $lblSub = New-Object System.Windows.Forms.Label
    $lblSub.Text = $Subtitle
    $lblSub.Location = [System.Drawing.Point]::new(18,44)
    $lblSub.Size = New-Object System.Drawing.Size(($W - 36),34)
    $lblSub.Font = New-Object System.Drawing.Font("Segoe UI",9)
    $lblSub.ForeColor = $muted
    $panel.Controls.Add($lblSub)

    return $panel
}

function Add-OptCheckbox {
    param(
        [System.Windows.Forms.Control]$Parent,
        [string]$Key,
        [string]$Text,
        [int]$X,
        [int]$Y,
        [bool]$Checked = $false
    )

    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Text = $Text
    $cb.Checked = $Checked
    $cb.ForeColor = $white
    $cb.BackColor = $bgCard
    $cb.Location = [System.Drawing.Point]::new($X,$Y)
    $cb.Size = New-Object System.Drawing.Size(($Parent.Width - ($X * 2)),24)
    $cb.Font = New-Object System.Drawing.Font("Segoe UI",10)
    $Parent.Controls.Add($cb)
    $Script:OptCheckboxes[$Key] = $cb
    return $cb
}

$panelSafe = New-OptGroupPanel -Title "Profil SAFE" -Subtitle "Recommande sur la majorite des PC. Nettoyage, confidentialite et performances sans modifications trop agressives." -X 25 -Y 110 -W 495 -H 410 -Accent $purple1
$pageOpt.Controls.Add($panelSafe)

$panelGaming = New-OptGroupPanel -Title "Profil GAMING" -Subtitle "Options jeu a activer seulement si le PC est utilise pour jouer ou streamer." -X 545 -Y 110 -W 495 -H 260 -Accent $blue
$pageOpt.Controls.Add($panelGaming)

$panelAdvanced = New-OptGroupPanel -Title "Profil AVANCE / RISQUE" -Subtitle "Reglages sensibles. A utiliser seulement si tu sais ce que tu fais. Je ne suis pas responsable en cas d effet secondaire." -X 25 -Y 540 -W 1015 -H 215 -Accent $yellow
$pageOpt.Controls.Add($panelAdvanced)

$null = Add-OptCheckbox -Parent $panelSafe -Key 'SafeRestore'   -Text "Creer un point de restauration avant modifications" -X 20 -Y 92  -Checked $true
$null = Add-OptCheckbox -Parent $panelSafe -Key 'SafeBloat'     -Text "Supprimer le bloatware non critique (Xbox, Bing, Clipchamp...)" -X 20 -Y 124 -Checked $true
$null = Add-OptCheckbox -Parent $panelSafe -Key 'SafeServices'  -Text "Services safe (DiagTrack, MapsBroker, services Xbox inutiles)" -X 20 -Y 156 -Checked $true
$null = Add-OptCheckbox -Parent $panelSafe -Key 'SafeBackground' -Text "Limiter les applications inutiles en arriere-plan" -X 20 -Y 188 -Checked $true
$null = Add-OptCheckbox -Parent $panelSafe -Key 'SafeAds'       -Text "Couper les suggestions, widgets marketing et publicites Windows" -X 20 -Y 220 -Checked $true
$null = Add-OptCheckbox -Parent $panelSafe -Key 'SafeTelemetry' -Text "Reduire la telemetrie optionnelle et les experiences personnalisees" -X 20 -Y 252 -Checked $true
$null = Add-OptCheckbox -Parent $panelSafe -Key 'SafeOneDrive'  -Text "Desactiver OneDrive si la personne ne l utilise pas" -X 20 -Y 284 -Checked $true
$null = Add-OptCheckbox -Parent $panelSafe -Key 'SafeIndexing'  -Text "Limiter l indexation Windows (recherche moins agressive)" -X 20 -Y 316 -Checked $true
$null = Add-OptCheckbox -Parent $panelSafe -Key 'SafeVisuals'   -Text "Regler les effets visuels sur performance" -X 20 -Y 348 -Checked $true

$null = Add-OptCheckbox -Parent $panelGaming -Key 'GamePower'    -Text "Activer le plan d alimentation performance" -X 20 -Y 92  -Checked $true
$null = Add-OptCheckbox -Parent $panelGaming -Key 'GameMode'     -Text "Activer le mode jeu Windows" -X 20 -Y 124 -Checked $true
$null = Add-OptCheckbox -Parent $panelGaming -Key 'GameHAGS'    -Text "Activer HAGS si la carte graphique le supporte" -X 20 -Y 156 -Checked $false
$null = Add-OptCheckbox -Parent $panelGaming -Key 'GameDVR'      -Text "Desactiver Xbox Game DVR et les captures en arriere-plan" -X 20 -Y 156 -Checked $true
$null = Add-OptCheckbox -Parent $panelGaming -Key 'GameXbox'    -Text "Desactiver les services Xbox si non utilises" -X 20 -Y 220 -Checked $false

$null = Add-OptCheckbox -Parent $panelAdvanced -Key 'AdvSysMain'      -Text "Regler SysMain intelligemment (desactive si SSD detecte)" -X 20 -Y 92  -Checked $false
$null = Add-OptCheckbox -Parent $panelAdvanced -Key 'AdvNDU'          -Text "Desactiver NDU" -X 20 -Y 124 -Checked $false
$null = Add-OptCheckbox -Parent $panelAdvanced -Key 'AdvDefender'     -Text "Desactiver Defender temps reel (risque de securite)" -X 520 -Y 92 -Checked $false
$null = Add-OptCheckbox -Parent $panelAdvanced -Key 'AdvLocalAccount' -Text "Ouvrir les parametres pour passer vers un compte local" -X 520 -Y 124 -Checked $false

$optWarning = New-Object System.Windows.Forms.Label
$optWarning.Text = "Conseil : garde SAFE actif, ajoute GAMING seulement si utile, et n active AVANCE que si tu assumes le risque."
$optWarning.Location = [System.Drawing.Point]::new(25,770)
$optWarning.Size = New-Object System.Drawing.Size(980,28)
$optWarning.Font = New-Object System.Drawing.Font("Segoe UI",9)
$optWarning.ForeColor = $yellow
$pageOpt.Controls.Add($optWarning)

# Compatibilite avec les anciennes variables
$cbRestore  = $Script:OptCheckboxes['SafeRestore']
$cbBloat    = $Script:OptCheckboxes['SafeBloat']
$cbServices = $Script:OptCheckboxes['SafeServices']
$cbPrivacy  = $Script:OptCheckboxes['SafeTelemetry']

# =========================================================
# PAGE DRIVERS
# =========================================================
$drvTitle = New-Object System.Windows.Forms.Label
$drvTitle.Text = "Telechargement des drivers"
$drvTitle.Location = [System.Drawing.Point]::new(25,18)
$drvTitle.Size = New-Object System.Drawing.Size(500,30)
$drvTitle.Font = New-Object System.Drawing.Font("Segoe UI",15,[System.Drawing.FontStyle]::Bold)
$drvTitle.ForeColor = $white
$pageDrv.Controls.Add($drvTitle)

$drvLabel = New-Object System.Windows.Forms.Label
$drvLabel.Text = "Clique sur le fabricant pour acceder a la page officielle de telechargement. Le PC est scanne automatiquement au demarrage."
$drvLabel.Location = [System.Drawing.Point]::new(25,58)
$drvLabel.Size = New-Object System.Drawing.Size(950,26)
$drvLabel.Font = New-Object System.Drawing.Font("Segoe UI",10)
$drvLabel.ForeColor = $muted
$pageDrv.Controls.Add($drvLabel)

function New-SmallActionButton {
    param($text,$x,$y,$back,$fore,$w=185)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Location = [System.Drawing.Point]::new([int]$x,[int]$y)
    $btn.Size = New-Object System.Drawing.Size($w,50)
    $btn.BackColor = $back
    $btn.ForeColor = $fore
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
    return $btn
}

$btnAMD    = New-SmallActionButton "AMD"           30 100 $bgCard $white
$btnNVIDIA = New-SmallActionButton "NVIDIA"        230 100 $bgCard $white
$btnIntel  = New-SmallActionButton "Intel"         430 100 $bgCard $white
$btnOEM    = New-SmallActionButton "Fabricant PC"  630 100 $bgCard $white
$btnDDU    = New-SmallActionButton "DDU Uninstall" 830 100 $bgCard $white
$pageDrv.Controls.AddRange(@($btnAMD,$btnNVIDIA,$btnIntel,$btnOEM,$btnDDU))

$drvNote = New-Object System.Windows.Forms.Label
$drvNote.Text = "Conseil DDU : desinstalleur de pilotes graphiques. A utiliser en mode sans echec pour un nettoyage complet."
$drvNote.Location = [System.Drawing.Point]::new(25,175)
$drvNote.Size = New-Object System.Drawing.Size(950,40)
$drvNote.Font = New-Object System.Drawing.Font("Segoe UI",9)
$drvNote.ForeColor = $yellow
$pageDrv.Controls.Add($drvNote)

# =========================================================
# PAGE OUTILS
# =========================================================
$toolsTitle = New-Object System.Windows.Forms.Label
$toolsTitle.Text = "Outils & Structure"
$toolsTitle.Location = [System.Drawing.Point]::new(25,18)
$toolsTitle.Size = New-Object System.Drawing.Size(400,30)
$toolsTitle.Font = New-Object System.Drawing.Font("Segoe UI",15,[System.Drawing.FontStyle]::Bold)
$toolsTitle.ForeColor = $white
$pageTools.Controls.Add($toolsTitle)

$toolsItems = @(
    @{T="Depot principal :"; V="C:\Logiciel Pre-Installer";     Y=60},
    @{T="Dossier admin Bureau :"; V="Desktop\Administrateur";   Y=95},
    @{T="Dossier musique :"; V="C:\Logiciel Pre-Installer\ClickByChris\Sounds\Music"; Y=130},
    @{T="Sous-dossiers auto :"; V="Systeme / Drivers / Diagnostic / Reseau / Securite / Utilitaires / Installation / Backup"; Y=165},
    @{T="Raccourcis web :";  V="AMD, NVIDIA, Intel, DDU, Sysinternals, OOSU10, Macrium..."; Y=200},
    @{T="Styles musicaux :"; V="Rock / Metal / Hip-Hop / Reggae / Musique Francaise / RAP US / RAP FR / Electro / Jazz / Classical"; Y=235}
)
foreach ($item in $toolsItems) {
    $lT = New-Object System.Windows.Forms.Label
    $lT.Text = $item.T
    $lT.Location = [System.Drawing.Point]::new(25,$item.Y)
    $lT.Size = New-Object System.Drawing.Size(240,26)
    $lT.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $lT.ForeColor = $yellow
    $pageTools.Controls.Add($lT)
    $lV = New-Object System.Windows.Forms.Label
    $lV.Text = $item.V
    $lV.Location = [System.Drawing.Point]::new(270,$item.Y)
    $lV.Size = New-Object System.Drawing.Size(750,26)
    $lV.Font = New-Object System.Drawing.Font("Segoe UI",10)
    $lV.ForeColor = $white
    $pageTools.Controls.Add($lV)
}

$toolsNote = New-Object System.Windows.Forms.Label
$toolsNote.Text = "Utilise le bouton 'Creer structure' dans la barre du bas pour generer tous les dossiers et raccourcis automatiquement."
$toolsNote.Location = [System.Drawing.Point]::new(25,290)
$toolsNote.Size = New-Object System.Drawing.Size(950,40)
$toolsNote.Font = New-Object System.Drawing.Font("Segoe UI",10)
$toolsNote.ForeColor = [System.Drawing.Color]::FromArgb(114,96,255)
$pageTools.Controls.Add($toolsNote)

# =========================================================
# PAGE RACCOURCIS
# =========================================================
$shortTitle = New-Object System.Windows.Forms.Label
$shortTitle.Text = "Gestion des raccourcis"
$shortTitle.Location = [System.Drawing.Point]::new(25,18)
$shortTitle.Size = New-Object System.Drawing.Size(400,30)
$shortTitle.Font = New-Object System.Drawing.Font("Segoe UI",15,[System.Drawing.FontStyle]::Bold)
$shortTitle.ForeColor = $white
$pageShort.Controls.Add($shortTitle)

$shortInfo = New-Object System.Windows.Forms.Label
$shortInfo.Text = "Le dossier 'Administrateur' sera cree sur le Bureau avec tous les sous-dossiers et raccourcis organises."
$shortInfo.Location = [System.Drawing.Point]::new(25,58)
$shortInfo.Size = New-Object System.Drawing.Size(950,26)
$shortInfo.Font = New-Object System.Drawing.Font("Segoe UI",10)
$shortInfo.ForeColor = $muted
$pageShort.Controls.Add($shortInfo)

$shortApps = @(
    "Firefox","Chrome","Brave","Discord","Spotify","Steam",
    "VLC","OBS Studio","qBittorrent","Notepad++","WinRAR","7-Zip",
    "Everything","BCUninstaller","CrystalDiskInfo","HWMonitor",
    "CPU-Z","GPU-Z","Rufus","Malwarebytes","Speedtest","VS Code","PowerToys","UniGetUI"
)

$shortY = 98
$shortCols = 4
for ($i=0; $i -lt $shortApps.Count; $i++) {
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "-  $($shortApps[$i])"
    $lbl.Location = [System.Drawing.Point]::new(30 + ($i % $shortCols) * 250, $shortY + ([math]::Floor($i / $shortCols) * 34))
    $lbl.Size = New-Object System.Drawing.Size(240,28)
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI",10)
    $lbl.ForeColor = $white
    $pageShort.Controls.Add($lbl)
}

# =========================================================
# PAGE AUDIO ULTRA PREMIUM
# =========================================================
$pageAudio.BackColor = $audioDark

$audioTop = New-Object System.Windows.Forms.Panel
$audioTop.Dock = 'Top'
$audioTop.Height = 1
$audioTop.BackColor = [System.Drawing.Color]::Transparent
$pageAudio.Controls.Add($audioTop)

$audioBrand = New-Object System.Windows.Forms.Label
$audioBrand.Text = "Saison`r`nMusique`r`nUnlimited."
$audioBrand.Location = [System.Drawing.Point]::new(18,4)
$audioBrand.Size = New-Object System.Drawing.Size(260,78)
$audioBrand.ForeColor = $audioText
$audioBrand.Font = New-Object System.Drawing.Font("Segoe UI",14,[System.Drawing.FontStyle]::Bold)
$audioTop.Controls.Add($audioBrand)
$audioBrand.BringToFront()

function New-AudioNavButton {
    param([string]$Text,[int]$X,[string]$Key)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.Location = [System.Drawing.Point]::new($X,22)
    $btn.Size = New-Object System.Drawing.Size(130,42)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.BackColor = $audioDark
    $btn.ForeColor = $audioText
    $btn.Font = New-Object System.Drawing.Font("Segoe UI",13,[System.Drawing.FontStyle]::Regular)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.Tag = $Key
    $btn.Add_Click({
        $target = $this.Tag
        if ([string]::IsNullOrWhiteSpace($target)) { return }
        switch ($target) {
            "Welcome" {
                Set-AudioView "Welcome"
            }
            "Artists" {
                Load-AudioArtists -Style (Get-SelectedAudioStyle)
                Set-AudioView "Artists"
            }
            "Albums" {
                Load-AudioAlbums
                Set-AudioView "Albums"
            }
            "Songs" {
                Load-AudioTracks
                Set-AudioView "Songs"
            }
        }
    })
    $audioTop.Controls.Add($btn)
    $Script:AudioNavButtons[$Key] = $btn
    return $btn
}

[void](New-AudioNavButton "Accueil" 330 "Welcome")
[void](New-AudioNavButton "Artistes" 475 "Artists")
[void](New-AudioNavButton "Albums"   625 "Albums")
[void](New-AudioNavButton "Chansons" 775 "Songs")

# Badge page
$Script:AudioPageBadge = New-Object System.Windows.Forms.Panel
$Script:AudioPageBadge.Location = [System.Drawing.Point]::new(920,14)
$Script:AudioPageBadge.Size = New-Object System.Drawing.Size(150,46)
$Script:AudioPageBadge.BackColor = [System.Drawing.Color]::FromArgb(124,96,255)
$audioTop.Controls.Add($Script:AudioPageBadge)

$audioPageInner = New-Object System.Windows.Forms.Panel
$audioPageInner.Location = [System.Drawing.Point]::new(4,4)
$audioPageInner.Size = New-Object System.Drawing.Size(142,38)
$audioPageInner.BackColor = [System.Drawing.Color]::FromArgb(150,115,255)
$Script:AudioPageBadge.Controls.Add($audioPageInner)

$Script:AudioPageBadgeLabel = New-Object System.Windows.Forms.Label
$Script:AudioPageBadgeLabel.Text = "Page 01"
$Script:AudioPageBadgeLabel.Dock = 'Fill'
$Script:AudioPageBadgeLabel.BackColor = [System.Drawing.Color]::Transparent
$Script:AudioPageBadgeLabel.ForeColor = $white
$Script:AudioPageBadgeLabel.TextAlign = 'MiddleCenter'
$Script:AudioPageBadgeLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold",12,[System.Drawing.FontStyle]::Bold)
$audioPageInner.Controls.Add($Script:AudioPageBadgeLabel)

# Overlay navigation directly on the audio page (no opaque top bar)
$audioBrand.Visible = $false
$audioTop.Visible = $false
foreach ($ctrl in @($Script:AudioNavButtons['Welcome'],$Script:AudioNavButtons['Artists'],$Script:AudioNavButtons['Albums'],$Script:AudioNavButtons['Songs'],$Script:AudioPageBadge)) {
    if ($null -ne $ctrl) {
        try { if ($ctrl.Parent) { $ctrl.Parent.Controls.Remove($ctrl) } } catch {}
        $pageAudio.Controls.Add($ctrl)
        $ctrl.BringToFront()
    }
}
$Script:AudioPageBadge.Visible = $false

# Corps audio
$audioBody = New-Object System.Windows.Forms.Panel
$audioBody.Dock = 'Fill'
$audioBody.BackColor = $audioDark
$pageAudio.Controls.Add($audioBody)

function New-AudioViewPanel {
    $p = New-Object System.Windows.Forms.Panel
    $p.Dock = 'Fill'
    $p.BackColor = $audioDark
    $p.Visible = $false
    $audioBody.Controls.Add($p)
    return $p
}

$audioWelcome = New-AudioViewPanel
$audioArtists = New-AudioViewPanel
$audioAlbums  = New-AudioViewPanel
$audioSongs   = New-AudioViewPanel
$audioFinish  = New-AudioViewPanel

$Script:AudioViewPanels["Welcome"] = $audioWelcome
$Script:AudioViewPanels["Artists"] = $audioArtists
$Script:AudioViewPanels["Albums"]  = $audioAlbums
$Script:AudioViewPanels["Songs"]   = $audioSongs
$Script:AudioViewPanels["Finish"]  = $audioFinish

# --- Welcome view ---
$Script:WelcomeHeroCard = New-Object System.Windows.Forms.Panel
$Script:WelcomeHeroCard.Size = New-Object System.Drawing.Size(960,340)
$Script:WelcomeHeroCard.BackColor = [System.Drawing.Color]::FromArgb(34,20,70)
$audioWelcome.Controls.Add($Script:WelcomeHeroCard)

$welcomeOuterGlow = New-Object System.Windows.Forms.Panel
$welcomeOuterGlow.Location = [System.Drawing.Point]::new(8,8)
$welcomeOuterGlow.Size = New-Object System.Drawing.Size(944,324)
$welcomeOuterGlow.BackColor = [System.Drawing.Color]::FromArgb(58,38,125)
$Script:WelcomeHeroCard.Controls.Add($welcomeOuterGlow)

$welcomeInnerGlow = New-Object System.Windows.Forms.Panel
$welcomeInnerGlow.Location = [System.Drawing.Point]::new(16,16)
$welcomeInnerGlow.Size = New-Object System.Drawing.Size(928,308)
$welcomeInnerGlow.BackColor = [System.Drawing.Color]::FromArgb(82,64,175)
$Script:WelcomeHeroCard.Controls.Add($welcomeInnerGlow)

$welcomeTitle1 = New-Object System.Windows.Forms.Label
$welcomeTitle1.Text = "Bienvenue"
$welcomeTitle1.Size = New-Object System.Drawing.Size(560,68)
$welcomeTitle1.ForeColor = $white
$welcomeTitle1.BackColor = [System.Drawing.Color]::Transparent
$welcomeTitle1.Font = New-Object System.Drawing.Font("Segoe UI Light",30,[System.Drawing.FontStyle]::Regular)
$audioWelcome.Controls.Add($welcomeTitle1)

$welcomeTitle2 = New-Object System.Windows.Forms.Label
$welcomeTitle2.Text = "Music"
$welcomeTitle2.Size = New-Object System.Drawing.Size(640,132)
$welcomeTitle2.ForeColor = $white
$welcomeTitle2.BackColor = [System.Drawing.Color]::Transparent
$welcomeTitle2.Font = New-Object System.Drawing.Font("Segoe UI Semibold",70,[System.Drawing.FontStyle]::Bold)
$audioWelcome.Controls.Add($welcomeTitle2)

$Script:WelcomeStyleBadge = New-Object System.Windows.Forms.Panel
$Script:WelcomeStyleBadge.Size = New-Object System.Drawing.Size(250,40)
$Script:WelcomeStyleBadge.BackColor = [System.Drawing.Color]::FromArgb(132,96,255)
$audioWelcome.Controls.Add($Script:WelcomeStyleBadge)

$welcomeStyleLabel = New-Object System.Windows.Forms.Label
$welcomeStyleLabel.Text = "Choisis un style musical"
$welcomeStyleLabel.Dock = 'Fill'
$welcomeStyleLabel.TextAlign = "MiddleCenter"
$welcomeStyleLabel.ForeColor = $white
$welcomeStyleLabel.BackColor = [System.Drawing.Color]::Transparent
$welcomeStyleLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold",10,[System.Drawing.FontStyle]::Bold)
$Script:WelcomeStyleBadge.Controls.Add($welcomeStyleLabel)
Set-ControlRounded -Control $Script:WelcomeStyleBadge -Radius 20
$Script:WelcomeStyleBadge.Add_SizeChanged({ Set-ControlRounded -Control $this -Radius 20 })

$Script:WelcomeComboHost = New-Object System.Windows.Forms.Panel
$Script:WelcomeComboHost.Size = New-Object System.Drawing.Size(320,52)
$Script:WelcomeComboHost.BackColor = [System.Drawing.Color]::FromArgb(24,18,44)
$audioWelcome.Controls.Add($Script:WelcomeComboHost)
Set-ControlRounded -Control $Script:WelcomeComboHost -Radius 22
$Script:WelcomeComboHost.Add_SizeChanged({ Set-ControlRounded -Control $this -Radius 22 })

$Script:AudioStyleCombo = New-Object System.Windows.Forms.ComboBox
$Script:AudioStyleCombo.Size = New-Object System.Drawing.Size(288,34)
$Script:AudioStyleCombo.DropDownStyle = "DropDownList"
$Script:AudioStyleCombo.BackColor = $white
$Script:AudioStyleCombo.ForeColor = $black
$Script:AudioStyleCombo.Font = New-Object System.Drawing.Font("Segoe UI",11)
$Script:WelcomeComboHost.Controls.Add($Script:AudioStyleCombo)

$btnWelcomeNext = New-Object System.Windows.Forms.Button
$btnWelcomeNext.Text = "Page suivante"
$btnWelcomeNext.Size = New-Object System.Drawing.Size(184,52)
$btnWelcomeNext.FlatStyle = "Flat"
$btnWelcomeNext.FlatAppearance.BorderSize = 0
$btnWelcomeNext.BackColor = $purple2
$btnWelcomeNext.ForeColor = $white
$btnWelcomeNext.Font = New-Object System.Drawing.Font("Segoe UI Semibold",12,[System.Drawing.FontStyle]::Bold)
$audioWelcome.Controls.Add($btnWelcomeNext)

$welcomeTitle1.BringToFront(); $welcomeTitle2.BringToFront()
$Script:WelcomeStyleBadge.BringToFront(); $Script:WelcomeComboHost.BringToFront()
$btnWelcomeNext.BringToFront()

# --- Artists view ---
$Script:AudioSelectedStyleLabel = New-Object System.Windows.Forms.Label
$Script:AudioSelectedStyleLabel.Text = "Style : aucun"
$Script:AudioSelectedStyleLabel.Location = [System.Drawing.Point]::new(40,30)
$Script:AudioSelectedStyleLabel.Size = New-Object System.Drawing.Size(350,32)
$Script:AudioSelectedStyleLabel.BackColor = [System.Drawing.Color]::Transparent
$Script:AudioSelectedStyleLabel.ForeColor = $white
$Script:AudioSelectedStyleLabel.Font = New-Object System.Drawing.Font("Segoe UI",18,[System.Drawing.FontStyle]::Bold)
$audioArtists.Controls.Add($Script:AudioSelectedStyleLabel)

$Script:AudioSummaryLabel = New-Object System.Windows.Forms.Label
$Script:AudioSummaryLabel.Text = "Choisis un style pour commencer."
$Script:AudioSummaryLabel.Location = [System.Drawing.Point]::new(40,70)
$Script:AudioSummaryLabel.Size = New-Object System.Drawing.Size(900,28)
$Script:AudioSummaryLabel.BackColor = [System.Drawing.Color]::Transparent
$Script:AudioSummaryLabel.ForeColor = $audioMuted
$Script:AudioSummaryLabel.Font = New-Object System.Drawing.Font("Segoe UI",11)
$audioArtists.Controls.Add($Script:AudioSummaryLabel)

$Script:AudioArtistFlow = New-Object System.Windows.Forms.FlowLayoutPanel
$Script:AudioArtistFlow.Location = [System.Drawing.Point]::new(40,115)
$Script:AudioArtistFlow.Size = New-Object System.Drawing.Size(1000,380)
$Script:AudioArtistFlow.Anchor = 'Top,Bottom,Left,Right'
$Script:AudioArtistFlow.AutoScroll = $true
$Script:AudioArtistFlow.BackColor = [System.Drawing.Color]::Transparent
$audioArtists.Controls.Add($Script:AudioArtistFlow)

$btnArtistsNext = New-Object System.Windows.Forms.Button
$btnArtistsNext.Text = "Page suivante"
$btnArtistsNext.Size = New-Object System.Drawing.Size(170,46)
$btnArtistsNext.FlatStyle = "Flat"; $btnArtistsNext.FlatAppearance.BorderSize = 0
$btnArtistsNext.BackColor = $purple2; $btnArtistsNext.ForeColor = $white
$btnArtistsNext.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)
$audioArtists.Controls.Add($btnArtistsNext)

# --- Albums view ---
$Script:AudioSelectedArtistLabel = New-Object System.Windows.Forms.Label
$Script:AudioSelectedArtistLabel.Text = "Aucun artiste selectionne"
$Script:AudioSelectedArtistLabel.Location = [System.Drawing.Point]::new(40,30)
$Script:AudioSelectedArtistLabel.Size = New-Object System.Drawing.Size(500,32)
$Script:AudioSelectedArtistLabel.BackColor = [System.Drawing.Color]::Transparent
$Script:AudioSelectedArtistLabel.ForeColor = $white
$Script:AudioSelectedArtistLabel.Font = New-Object System.Drawing.Font("Segoe UI",18,[System.Drawing.FontStyle]::Bold)
$audioAlbums.Controls.Add($Script:AudioSelectedArtistLabel)

$Script:AudioArtistPicture = New-Object System.Windows.Forms.PictureBox
$Script:AudioArtistPicture.Location = [System.Drawing.Point]::new(40,90)
$Script:AudioArtistPicture.Size = New-Object System.Drawing.Size(220,200)
$Script:AudioArtistPicture.SizeMode = "Zoom"
$Script:AudioArtistPicture.BackColor = [System.Drawing.Color]::FromArgb(26,26,36)
$audioAlbums.Controls.Add($Script:AudioArtistPicture)

$Script:AudioAlbumFlow = New-Object System.Windows.Forms.FlowLayoutPanel
$Script:AudioAlbumFlow.Location = [System.Drawing.Point]::new(300,90)
$Script:AudioAlbumFlow.Size = New-Object System.Drawing.Size(720,360)
$Script:AudioAlbumFlow.Anchor = 'Top,Bottom,Left,Right'
$Script:AudioAlbumFlow.AutoScroll = $true
$Script:AudioAlbumFlow.BackColor = [System.Drawing.Color]::Transparent
$audioAlbums.Controls.Add($Script:AudioAlbumFlow)

$btnAlbumsNext = New-Object System.Windows.Forms.Button
$btnAlbumsNext.Text = "Page suivante"
$btnAlbumsNext.Size = New-Object System.Drawing.Size(170,46)
$btnAlbumsNext.FlatStyle = "Flat"; $btnAlbumsNext.FlatAppearance.BorderSize = 0
$btnAlbumsNext.BackColor = $purple2; $btnAlbumsNext.ForeColor = $white
$btnAlbumsNext.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)
$audioAlbums.Controls.Add($btnAlbumsNext)

# --- Songs view ---
$Script:AudioSelectedAlbumLabel = New-Object System.Windows.Forms.Label
$Script:AudioSelectedAlbumLabel.Text = "Aucun album selectionne"
$Script:AudioSelectedAlbumLabel.Location = [System.Drawing.Point]::new(40,30)
$Script:AudioSelectedAlbumLabel.Size = New-Object System.Drawing.Size(500,32)
$Script:AudioSelectedAlbumLabel.BackColor = [System.Drawing.Color]::Transparent
$Script:AudioSelectedAlbumLabel.ForeColor = $white
$Script:AudioSelectedAlbumLabel.Font = New-Object System.Drawing.Font("Segoe UI",18,[System.Drawing.FontStyle]::Bold)
$audioSongs.Controls.Add($Script:AudioSelectedAlbumLabel)

$Script:AudioCoverPicture = New-Object System.Windows.Forms.PictureBox
$Script:AudioCoverPicture.Location = [System.Drawing.Point]::new(40,90)
$Script:AudioCoverPicture.Size = New-Object System.Drawing.Size(240,240)
$Script:AudioCoverPicture.SizeMode = "Zoom"
$Script:AudioCoverPicture.BackColor = [System.Drawing.Color]::FromArgb(26,26,36)
$audioSongs.Controls.Add($Script:AudioCoverPicture)

$Script:AudioTrackTitle = New-Object System.Windows.Forms.Label
$Script:AudioTrackTitle.Text = "aucune"
$Script:AudioTrackTitle.Location = [System.Drawing.Point]::new(320,90)
$Script:AudioTrackTitle.Size = New-Object System.Drawing.Size(520,50)
$Script:AudioTrackTitle.ForeColor = $white
$Script:AudioTrackTitle.Font = New-Object System.Drawing.Font("Segoe UI",22,[System.Drawing.FontStyle]::Regular)
$audioSongs.Controls.Add($Script:AudioTrackTitle)

$Script:AudioTrackList = New-Object System.Windows.Forms.ListBox
$Script:AudioTrackList.Location = [System.Drawing.Point]::new(320,160)
$Script:AudioTrackList.Size = New-Object System.Drawing.Size(470,220)
$Script:AudioTrackList.Anchor = 'Top,Bottom,Left,Right'
$Script:AudioTrackList.BackColor = $audioCard
$Script:AudioTrackList.ForeColor = $audioText
$Script:AudioTrackList.Font = New-Object System.Drawing.Font("Segoe UI",11)
$audioSongs.Controls.Add($Script:AudioTrackList)

function New-AudioControlButton {
    param([string]$Text,[int]$X,[int]$Y,[int]$W,[System.Drawing.Color]$Back,[System.Drawing.Color]$Fore)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.Location = [System.Drawing.Point]::new($X,$Y)
    $btn.Size = New-Object System.Drawing.Size($W,42)
    $btn.FlatStyle = "Flat"; $btn.FlatAppearance.BorderSize = 0
    $btn.BackColor = $Back; $btn.ForeColor = $Fore
    $btn.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
    return $btn
}

$btnAudioPlay  = New-AudioControlButton "Play"      320 400 120 $blue  $black
$btnAudioPause = New-AudioControlButton "Pause"     452 400 110 $audioCard $white
$btnAudioStop  = New-AudioControlButton "Stop"      574 400 100 $audioCard $white
$btnAudioPrev  = New-AudioControlButton "Prec"      686 400 110 $audioCard $white
$btnAudioNext  = New-AudioControlButton "Suiv"      808 400 110 $audioCard $white
$audioSongs.Controls.AddRange(@($btnAudioPlay,$btnAudioPause,$btnAudioStop,$btnAudioPrev,$btnAudioNext))

$Script:AudioNowPlaying = New-Object System.Windows.Forms.Label
$Script:AudioNowPlaying.Text = "Lecture : aucune"
$Script:AudioNowPlaying.Location = [System.Drawing.Point]::new(320,455)
$Script:AudioNowPlaying.Size = New-Object System.Drawing.Size(520,28)
$Script:AudioNowPlaying.ForeColor = $yellow
$Script:AudioNowPlaying.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)
$audioSongs.Controls.Add($Script:AudioNowPlaying)

$btnSongsNext = New-Object System.Windows.Forms.Button
$btnSongsNext.Text = "Page suivante"
$btnSongsNext.Size = New-Object System.Drawing.Size(170,46)
$btnSongsNext.FlatStyle = "Flat"; $btnSongsNext.FlatAppearance.BorderSize = 0
$btnSongsNext.BackColor = $purple2; $btnSongsNext.ForeColor = $white
$btnSongsNext.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)

$audioSongs.Controls.Add($btnSongsNext)

function Register-AudioStyleCombo {
    param([System.Windows.Forms.ComboBox]$Combo)
    if (-not $Combo) { return }
    if (-not $Script:AudioStyleCombos) { $Script:AudioStyleCombos = @() }
    if (-not ($Script:AudioStyleCombos -contains $Combo)) { $Script:AudioStyleCombos += $Combo }
    $Combo.Add_SelectedIndexChanged({
        if ($Script:AudioStyleSyncing) { return }
        $selected = $this.SelectedItem
        if ($null -eq $selected) { return }
        if (Get-Command Sync-AudioStyleCombos -ErrorAction SilentlyContinue) {
            Sync-AudioStyleCombos -Value $selected.ToString() -SourceCombo $this
        }
        if (Get-Command Refresh-AudioViewData -ErrorAction SilentlyContinue) {
            Refresh-AudioViewData
        }
    })
}

function New-AudioPageStyleCombo {
    param(
        [System.Windows.Forms.Control]$Parent,
        [int]$X,
        [int]$Y,
        [string]$HostScriptName,
        [string]$LabelText = "Style"
    )

    $comboWrap = New-Object System.Windows.Forms.Panel
    $comboWrap.Location = [System.Drawing.Point]::new($X,$Y)
    $comboWrap.Size = New-Object System.Drawing.Size(286,38)
    $comboWrap.BackColor = [System.Drawing.Color]::FromArgb(18,18,26)
    $comboWrap.Anchor = 'Top,Right'
    $Parent.Controls.Add($comboWrap)
    Set-ControlRounded -Control $comboWrap -Radius 18
    $comboWrap.Add_SizeChanged({ Set-ControlRounded -Control $this -Radius 18 })

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $LabelText
    $lbl.Location = [System.Drawing.Point]::new(10,8)
    $lbl.Size = New-Object System.Drawing.Size(44,22)
    $lbl.ForeColor = $white
    $lbl.BackColor = [System.Drawing.Color]::Transparent
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $comboWrap.Controls.Add($lbl)

    $combo = New-Object System.Windows.Forms.ComboBox
    $combo.Location = [System.Drawing.Point]::new(60,4)
    $combo.Size = New-Object System.Drawing.Size(216,30)
    $combo.DropDownStyle = "DropDownList"
    $combo.BackColor = $white
    $combo.ForeColor = $black
    $combo.Font = New-Object System.Drawing.Font("Segoe UI",10)
    $combo.Anchor = 'Top,Right'
    $comboWrap.Controls.Add($combo)

    if (-not [string]::IsNullOrWhiteSpace($HostScriptName)) {
        Set-Variable -Scope Script -Name $HostScriptName -Value $comboWrap
    }

    Register-AudioStyleCombo -Combo $combo
    return $combo
}

$Script:AudioArtistsStyleHost = $null
$Script:AudioAlbumsStyleHost = $null
$Script:AudioSongsStyleHost = $null
$Script:AudioArtistsStyleCombo = New-AudioPageStyleCombo -Parent $audioArtists -X 792 -Y 20 -HostScriptName "AudioArtistsStyleHost"
$Script:AudioAlbumsStyleCombo = New-AudioPageStyleCombo -Parent $audioAlbums -X 792 -Y 20 -HostScriptName "AudioAlbumsStyleHost"
$Script:AudioSongsStyleCombo = New-AudioPageStyleCombo -Parent $audioSongs -X 792 -Y 20 -HostScriptName "AudioSongsStyleHost"

# --- Finish view ---
$finishText1 = New-Object System.Windows.Forms.Label
$finishText1.Text = "A bientot."
$finishText1.Size = New-Object System.Drawing.Size(350,60)
$finishText1.ForeColor = $white
$finishText1.Font = New-Object System.Drawing.Font("Segoe UI",34,[System.Drawing.FontStyle]::Regular)
$audioFinish.Controls.Add($finishText1)

$Script:AudioFinishLabel = New-Object System.Windows.Forms.Label
$Script:AudioFinishLabel.Text = "Merci pour ce`r`nmoment ecoute"
$Script:AudioFinishLabel.Size = New-Object System.Drawing.Size(760,220)
$Script:AudioFinishLabel.ForeColor = $audioMuted
$Script:AudioFinishLabel.Font = New-Object System.Drawing.Font("Segoe UI",52,[System.Drawing.FontStyle]::Regular)
$Script:AudioFinishLabel.TextAlign = "MiddleCenter"
$audioFinish.Controls.Add($Script:AudioFinishLabel)

$btnFinishRestart = New-Object System.Windows.Forms.Button
$btnFinishRestart.Text = "Recommencer"
$btnFinishRestart.Size = New-Object System.Drawing.Size(180,46)
$btnFinishRestart.FlatStyle = "Flat"; $btnFinishRestart.FlatAppearance.BorderSize = 0
$btnFinishRestart.BackColor = $purple2; $btnFinishRestart.ForeColor = $white
$btnFinishRestart.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)
$audioFinish.Controls.Add($btnFinishRestart)


function Get-AudioBackgroundPath {
    param([string]$Mode)
    if ([string]::IsNullOrWhiteSpace($Mode)) { return $null }
    $map = @{
        'Welcome' = 'page1_accueil.png'
        'Artists' = 'page2_artistes.png'
        'Albums'  = 'page3_albums.png'
        'Songs'   = 'page4_chansons.png'
        'Finish'  = 'page5_fin.png'
    }
    if (-not $map.ContainsKey($Mode)) { return $null }
    return Join-Path $Script:AudioBackgroundRoot $map[$Mode]
}

function Test-AudioBackgroundExists {
    param([string]$Mode)
    $path = Get-AudioBackgroundPath -Mode $Mode
    return (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path $path))
}

function Get-AudioBackgroundImage {
    param([string]$Mode)
    if ([string]::IsNullOrWhiteSpace($Mode)) { return $null }
    if ($Script:AudioBackgroundCache.ContainsKey($Mode)) {
        return $Script:AudioBackgroundCache[$Mode]
    }
    $path = Get-AudioBackgroundPath -Mode $Mode
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path $path)) {
        $Script:AudioBackgroundCache[$Mode] = $null
        return $null
    }
    $img = Load-ImageSafe -ImagePath $path
    $Script:AudioBackgroundCache[$Mode] = $img
    return $img
}

function Add-AudioBackgroundPainter {
    param(
        [System.Windows.Forms.Panel]$Panel,
        [string]$Mode
    )
    if (-not $Panel) { return }
    $Panel.Tag = $Mode
    $Panel.Add_Paint({
        param($sender,$e)
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $rect = $this.ClientRectangle
        $g.Clear($audioDark)

        $bgImage = Get-AudioBackgroundImage -Mode $this.Tag
        if ($bgImage) {
            $g.DrawImage($bgImage, $rect)
            return
        }

        $topHeight = [Math]::Max(165,[int]($rect.Height * 0.29))
        $topRect = New-Object System.Drawing.Rectangle(0,0,$rect.Width,$topHeight)
        $lowerRect = New-Object System.Drawing.Rectangle(0,[int]($rect.Height * 0.29),$rect.Width,($rect.Height - [int]($rect.Height * 0.29)))
        $topBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($topRect,[System.Drawing.Color]::FromArgb(4,4,8),[System.Drawing.Color]::FromArgb(9,9,14),90.0)
        $lowerBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($lowerRect,[System.Drawing.Color]::FromArgb(44,42,58),[System.Drawing.Color]::FromArgb(84,66,210),90.0)
        $g.FillRectangle($topBrush,$topRect)
        $g.FillRectangle($lowerBrush,$lowerRect)
        $topBrush.Dispose(); $lowerBrush.Dispose()

        switch ($this.Tag) {
            'Welcome' {
                $heroRect = New-Object System.Drawing.Rectangle(-12,[int]($rect.Height*0.24),($rect.Width + 24),[int]($rect.Height*0.82))
                $heroBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($heroRect,[System.Drawing.Color]::FromArgb(34,30,46),[System.Drawing.Color]::FromArgb(88,74,198),90.0)
                $g.FillRectangle($heroBrush,$heroRect)
                $heroBrush.Dispose()

                $fadeRect = New-Object System.Drawing.Rectangle(0,[int]($rect.Height*0.18),$rect.Width,[int]($rect.Height*0.20))
                $fadeBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($fadeRect,[System.Drawing.Color]::FromArgb(0,0,0,0),[System.Drawing.Color]::FromArgb(34,34,52),90.0)
                $g.FillRectangle($fadeBrush,$fadeRect)
                $fadeBrush.Dispose()
            }
            'Artists' {
                $path = New-Object System.Drawing.Drawing2D.GraphicsPath
                $path.AddEllipse(70,-120,560,560)
                $sphereBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($path)
                $sphereBrush.CenterColor = [System.Drawing.Color]::FromArgb(224,164,231)
                $sphereBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(16,10,20))
                $g.FillPath($sphereBrush,$path)
                $sphereBrush.Dispose(); $path.Dispose()

                $glowRect = New-Object System.Drawing.Rectangle([int]($rect.Width*0.68),[int]($rect.Height*0.18),[int]($rect.Width*0.34),[int]($rect.Height*0.76))
                $glowBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($glowRect,[System.Drawing.Color]::FromArgb(0,0,0,0),[System.Drawing.Color]::FromArgb(112,112,255),0.0)
                $g.FillRectangle($glowBrush,$glowRect)
                $glowBrush.Dispose()

                $linePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(55,155,145,255),1)
                $g.DrawLine($linePen,[int]($rect.Width*0.66),[int]($rect.Height*0.24),$rect.Width,[int]($rect.Height*0.72))
                $linePen.Dispose()

                $pieBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(68,58,122))
                $g.FillPie($pieBrush,$rect.Width-334,$rect.Height-242,470,470,180,90)
                $pieBrush.Dispose()
            }
            'Albums' {
                $path = New-Object System.Drawing.Drawing2D.GraphicsPath
                $path.AddEllipse(86,[int]($rect.Height*0.54),250,250)
                $sphereBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($path)
                $sphereBrush.CenterColor = [System.Drawing.Color]::FromArgb(100,104,255)
                $sphereBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(38,32,68))
                $g.FillPath($sphereBrush,$path)
                $sphereBrush.Dispose(); $path.Dispose()

                $glowRect = New-Object System.Drawing.Rectangle([int]($rect.Width*0.68),[int]($rect.Height*0.12),[int]($rect.Width*0.34),[int]($rect.Height*0.70))
                $glowBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($glowRect,[System.Drawing.Color]::FromArgb(0,0,0,0),[System.Drawing.Color]::FromArgb(112,112,255),0.0)
                $g.FillRectangle($glowBrush,$glowRect)
                $glowBrush.Dispose()

                $linePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(58,165,165,255),1)
                $g.DrawLine($linePen,[int]($rect.Width*0.76),[int]($rect.Height*0.14),$rect.Width,[int]($rect.Height*0.50))
                $linePen.Dispose()

                $pieBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(70,60,125))
                $g.FillPie($pieBrush,$rect.Width-316,$rect.Height-240,456,456,180,90)
                $pieBrush.Dispose()
            }
            'Songs' {
                $path = New-Object System.Drawing.Drawing2D.GraphicsPath
                $path.AddEllipse(48,[int]($rect.Height*0.10),255,255)
                $sphereBrush = New-Object System.Drawing.Drawing2D.PathGradientBrush($path)
                $sphereBrush.CenterColor = [System.Drawing.Color]::FromArgb(80,88,235)
                $sphereBrush.SurroundColors = @([System.Drawing.Color]::FromArgb(10,8,16))
                $g.FillPath($sphereBrush,$path)
                $sphereBrush.Dispose(); $path.Dispose()

                $glowRect = New-Object System.Drawing.Rectangle([int]($rect.Width*0.58),0,[int]($rect.Width*0.42),$rect.Height)
                $glowBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($glowRect,[System.Drawing.Color]::FromArgb(0,0,0,0),[System.Drawing.Color]::FromArgb(220,166,232),0.0)
                $g.FillRectangle($glowBrush,$glowRect)
                $glowBrush.Dispose()

                $linePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(70,225,190,255),1)
                $g.DrawLine($linePen,[int]($rect.Width*0.61),[int]($rect.Height*0.08),$rect.Width,[int]($rect.Height*0.58))
                $linePen.Dispose()

                $pieBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(76,64,132))
                $g.FillPie($pieBrush,$rect.Width-360,$rect.Height-285,540,540,180,90)
                $pieBrush.Dispose()
            }
            'Finish' {
                $heroRect = New-Object System.Drawing.Rectangle(-10,[int]($rect.Height*0.28),($rect.Width + 20),[int]($rect.Height*0.76))
                $heroBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($heroRect,[System.Drawing.Color]::FromArgb(28,26,38),[System.Drawing.Color]::FromArgb(96,78,220),90.0)
                $g.FillRectangle($heroBrush,$heroRect)
                $heroBrush.Dispose()
            }
        }
    })
    $Panel.Add_Resize({ $this.Invalidate() })
}

Add-AudioBackgroundPainter -Panel $audioWelcome -Mode 'Welcome'
Add-AudioBackgroundPainter -Panel $audioArtists -Mode 'Artists'
Add-AudioBackgroundPainter -Panel $audioAlbums  -Mode 'Albums'
Add-AudioBackgroundPainter -Panel $audioSongs   -Mode 'Songs'
Add-AudioBackgroundPainter -Panel $audioFinish  -Mode 'Finish'

$welcomeTitle1.Text = "Bienvenue"
$welcomeTitle2.Text = "Music"
$finishText1.Text = "en revoir."
$Script:AudioFinishLabel.Text = "Merci pour ce`r`nmoment ecoute"
$Script:AudioFinishLabel.Font = New-Object System.Drawing.Font("Segoe UI Light",52,[System.Drawing.FontStyle]::Regular)
$btnFinishRestart.Text = "Fin"
# =========================================================
# PAGE CONTACT
# =========================================================
$contactTitle = New-Object System.Windows.Forms.Label
$contactTitle.Text = "Contact / Aide"
$contactTitle.Location = [System.Drawing.Point]::new(25,18)
$contactTitle.Size = New-Object System.Drawing.Size(400,32)
$contactTitle.Font = New-Object System.Drawing.Font("Segoe UI",16,[System.Drawing.FontStyle]::Bold)
$contactTitle.ForeColor = $white
$pageContact.Controls.Add($contactTitle)

# Carte contact principale
$contactCard = New-Object System.Windows.Forms.Panel
$contactCard.Location = [System.Drawing.Point]::new(25,65)
$contactCard.Size = New-Object System.Drawing.Size(580,380)
$contactCard.BackColor = $bgCard
$pageContact.Controls.Add($contactCard)

$contactCardTitle = New-Object System.Windows.Forms.Label
$contactCardTitle.Text = "Christophe - ClickByChris"
$contactCardTitle.Location = [System.Drawing.Point]::new(25,20)
$contactCardTitle.Size = New-Object System.Drawing.Size(530,30)
$contactCardTitle.Font = New-Object System.Drawing.Font("Segoe UI",14,[System.Drawing.FontStyle]::Bold)
$contactCardTitle.ForeColor = $yellow
$contactCard.Controls.Add($contactCardTitle)

$contactSub = New-Object System.Windows.Forms.Label
$contactSub.Text = "Createur de l outil - Support & aide"
$contactSub.Location = [System.Drawing.Point]::new(25,52)
$contactSub.Size = New-Object System.Drawing.Size(530,22)
$contactSub.Font = New-Object System.Drawing.Font("Segoe UI",10)
$contactSub.ForeColor = $muted
$contactCard.Controls.Add($contactSub)

$contactLines = @(
    @{Label="Discord :";    Value="RPKILLER60";              Y=98},
    @{Label="Instagram :";  Value="Anonymous_zrdz";          Y=135},
    @{Label="TikTok :";     Value="RPKILLER";                Y=172},
    @{Label="Mail :";       Value="chris.clickby@gmail.com"; Y=209}
)
foreach ($item in $contactLines) {
    $lL = New-Object System.Windows.Forms.Label
    $lL.Text = $item.Label
    $lL.Location = [System.Drawing.Point]::new(25,$item.Y)
    $lL.Size = New-Object System.Drawing.Size(100,28)
    $lL.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $lL.ForeColor = $muted
    $contactCard.Controls.Add($lL)
    $lV = New-Object System.Windows.Forms.Label
    $lV.Text = $item.Value
    $lV.Location = [System.Drawing.Point]::new(130,$item.Y)
    $lV.Size = New-Object System.Drawing.Size(400,28)
    $lV.Font = New-Object System.Drawing.Font("Segoe UI",11)
    $lV.ForeColor = $white
    $contactCard.Controls.Add($lV)
}

# Liens web
$contactLinksCard = New-Object System.Windows.Forms.Panel
$contactLinksCard.Location = [System.Drawing.Point]::new(625,65)
$contactLinksCard.Size = New-Object System.Drawing.Size(390,380)
$contactLinksCard.BackColor = $bgCard
$pageContact.Controls.Add($contactLinksCard)

$contactLinksTitle = New-Object System.Windows.Forms.Label
$contactLinksTitle.Text = "Liens & Ressources"
$contactLinksTitle.Location = [System.Drawing.Point]::new(20,20)
$contactLinksTitle.Size = New-Object System.Drawing.Size(350,28)
$contactLinksTitle.Font = New-Object System.Drawing.Font("Segoe UI",13,[System.Drawing.FontStyle]::Bold)
$contactLinksTitle.ForeColor = $yellow
$contactLinksCard.Controls.Add($contactLinksTitle)

$linkItems = @(
    @{T="YouTube ClickByChris";        U="https://www.youtube.com/@ClickByChris"; Y=65},
    @{T="Winget packages";             U="https://winget.run/";                   Y=110},
    @{T="Ninite - Install rapide";     U="https://ninite.com/";                   Y=155},
    @{T="Documentation Microsoft";     U="https://learn.microsoft.com/";          Y=200},
    @{T="Sysinternals Suite";          U="https://learn.microsoft.com/en-us/sysinternals/"; Y=245},
    @{T="GitHub ClickByChris";         U="https://github.com/";                   Y=290}
)
foreach ($li in $linkItems) {
    $lnkBtn = New-Object System.Windows.Forms.Button
    $lnkBtn.Text = "$($li.T)"
    $lnkBtn.Location = [System.Drawing.Point]::new(20,$li.Y)
    $lnkBtn.Size = New-Object System.Drawing.Size(350,32)
    $lnkBtn.BackColor = [System.Drawing.Color]::FromArgb(38,38,50)
    $lnkBtn.ForeColor = $blue
    $lnkBtn.FlatStyle = "Flat"
    $lnkBtn.FlatAppearance.BorderSize = 0
    $lnkBtn.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $lnkBtn.Tag = $li.U
    $lnkBtn.Add_Click({ Start-Process $this.Tag })
    $contactLinksCard.Controls.Add($lnkBtn)
}

# =========================================================
# PAGE LOGS - REDESIGN PREMIUM
# =========================================================

# Header row
$logsHeader = New-Object System.Windows.Forms.Panel
$logsHeader.Location  = [System.Drawing.Point]::new(0,0)
$logsHeader.Size      = New-Object System.Drawing.Size(1060,50)
$logsHeader.BackColor = [System.Drawing.Color]::FromArgb(22,22,32)
$pageLogs.Controls.Add($logsHeader)

# Titre
$logsTitle = New-Object System.Windows.Forms.Label
$logsTitle.Text = "[ LOG ]  Logs en temps reel"
$logsTitle.Location = [System.Drawing.Point]::new(16,12)
$logsTitle.Size     = New-Object System.Drawing.Size(320,26)
$logsTitle.Font     = New-Object System.Drawing.Font("Segoe UI",13,[System.Drawing.FontStyle]::Bold)
$logsTitle.ForeColor = [System.Drawing.Color]::White
$logsTitle.BackColor = [System.Drawing.Color]::Transparent
$logsHeader.Controls.Add($logsTitle)

# Compteur lignes
$Script:lblLogCount = New-Object System.Windows.Forms.Label
$Script:lblLogCount.Text = ">> 0 lignes"
$Script:lblLogCount.Location  = [System.Drawing.Point]::new(360,14)
$Script:lblLogCount.Size      = New-Object System.Drawing.Size(130,22)
$Script:lblLogCount.Font      = New-Object System.Drawing.Font("Segoe UI",9)
$Script:lblLogCount.ForeColor = [System.Drawing.Color]::FromArgb(0,210,100)
$Script:lblLogCount.BackColor = [System.Drawing.Color]::Transparent
$logsHeader.Controls.Add($Script:lblLogCount)

# Bouton copier
$btnCopyLogs = New-Object System.Windows.Forms.Button
$btnCopyLogs.Text = "Copier"
$btnCopyLogs.Location  = [System.Drawing.Point]::new(820,8)
$btnCopyLogs.Size      = New-Object System.Drawing.Size(100,34)
$btnCopyLogs.FlatStyle = "Flat"
$btnCopyLogs.BackColor = [System.Drawing.Color]::FromArgb(50,50,70)
$btnCopyLogs.ForeColor = [System.Drawing.Color]::White
$btnCopyLogs.Font      = New-Object System.Drawing.Font("Segoe UI",9)
$btnCopyLogs.Cursor    = [System.Windows.Forms.Cursors]::Hand
$btnCopyLogs.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80,80,100)
$btnCopyLogs.Add_Click({
    if ($Script:LogBox.Text.Length -gt 0) {
        [System.Windows.Forms.Clipboard]::SetText($Script:LogBox.Text)
        $btnCopyLogs.Text = "✅ Copié !"
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 1500
        $timer.Add_Tick({ $btnCopyLogs.Text = "📋 Copier"; $timer.Stop() })
        $timer.Start()
    }
})
$logsHeader.Controls.Add($btnCopyLogs)

# Bouton vider
$btnClearLogsPage = New-Object System.Windows.Forms.Button
$btnClearLogsPage.Text = "Vider"
$btnClearLogsPage.Location  = [System.Drawing.Point]::new(930,8)
$btnClearLogsPage.Size      = New-Object System.Drawing.Size(100,34)
$btnClearLogsPage.FlatStyle = "Flat"
$btnClearLogsPage.BackColor = [System.Drawing.Color]::FromArgb(80,30,30)
$btnClearLogsPage.ForeColor = [System.Drawing.Color]::White
$btnClearLogsPage.Font      = New-Object System.Drawing.Font("Segoe UI",9)
$btnClearLogsPage.Cursor    = [System.Windows.Forms.Cursors]::Hand
$btnClearLogsPage.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(120,50,50)
$btnClearLogsPage.Add_Click({
    $Script:LogBox.Clear()
    $Script:LogLineCount = 0
    if ($Script:lblLogCount) { $Script:lblLogCount.Text = "🟢 0 lignes" }
    if ($Script:lblCurrentApp) { $Script:lblCurrentApp.Text = "En attente..." }
    if ($Script:lblStatus) { $Script:lblStatus.Text = "Etat : logs vides" }
    if ($Script:ProgressFill) { $Script:ProgressFill.Visible = $false }
})
$logsHeader.Controls.Add($btnClearLogsPage)

# Barre "En cours"
$currentPanel = New-Object System.Windows.Forms.Panel
$currentPanel.Location  = [System.Drawing.Point]::new(0,50)
$currentPanel.Size      = New-Object System.Drawing.Size(1060,30)
$currentPanel.BackColor = [System.Drawing.Color]::FromArgb(28,20,45)
$pageLogs.Controls.Add($currentPanel)

$Script:lblCurrentApp = New-Object System.Windows.Forms.Label
$Script:lblCurrentApp.Text      = "⚡  En attente..."
$Script:lblCurrentApp.Location  = [System.Drawing.Point]::new(12,5)
$Script:lblCurrentApp.Size      = New-Object System.Drawing.Size(1020,20)
$Script:lblCurrentApp.Font      = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$Script:lblCurrentApp.ForeColor = [System.Drawing.Color]::FromArgb(180,140,255)
$Script:lblCurrentApp.BackColor = [System.Drawing.Color]::Transparent
$currentPanel.Controls.Add($Script:lblCurrentApp)

# Barre filtres
$filterPanel = New-Object System.Windows.Forms.Panel
$filterPanel.Location  = [System.Drawing.Point]::new(0,80)
$filterPanel.Size      = New-Object System.Drawing.Size(1060,36)
$filterPanel.BackColor = [System.Drawing.Color]::FromArgb(18,18,28)
$pageLogs.Controls.Add($filterPanel)

$filterLabel = New-Object System.Windows.Forms.Label
$filterLabel.Text      = "Filtre :"
$filterLabel.Location  = [System.Drawing.Point]::new(12,9)
$filterLabel.Size      = New-Object System.Drawing.Size(50,20)
$filterLabel.Font      = New-Object System.Drawing.Font("Segoe UI",9)
$filterLabel.ForeColor = [System.Drawing.Color]::Gray
$filterLabel.BackColor = [System.Drawing.Color]::Transparent
$filterPanel.Controls.Add($filterLabel)

$Script:ActiveLogFilter = "ALL"

function New-FilterBtn {
    param([string]$Text, [string]$Filter, [int]$X, [System.Drawing.Color]$Clr)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text      = $Text
    $btn.Location  = [System.Drawing.Point]::new($X, 4)
    $btn.Size      = New-Object System.Drawing.Size(90,28)
    $btn.FlatStyle = "Flat"
    $btn.BackColor = [System.Drawing.Color]::FromArgb(35,35,50)
    $btn.ForeColor = $Clr
    $btn.Font      = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $btn.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $btn.FlatAppearance.BorderColor = $Clr
    $btn.Tag = $Filter
    $btn.Add_Click({
        $Script:ActiveLogFilter = $this.Tag
        Write-Log "Filtre actif : $($this.Tag)"
    })
    $filterPanel.Controls.Add($btn)
    return $btn
}

$null = New-FilterBtn -Text "Tous"   -Filter "ALL"   -X 68  -Clr ([System.Drawing.Color]::White)
$null = New-FilterBtn -Text "INFO"   -Filter "INFO"  -X 166 -Clr ([System.Drawing.Color]::FromArgb(100,180,255))
$null = New-FilterBtn -Text "WARN"   -Filter "WARN"  -X 264 -Clr ([System.Drawing.Color]::FromArgb(255,200,0))
$null = New-FilterBtn -Text "ERROR"  -Filter "ERROR" -X 362 -Clr ([System.Drawing.Color]::FromArgb(255,80,80))
$null = New-FilterBtn -Text "OK"     -Filter "OK"    -X 460 -Clr ([System.Drawing.Color]::FromArgb(0,210,100))

# LogBox principal
$Script:LogBox = New-Object System.Windows.Forms.RichTextBox
$Script:LogBox.Location    = [System.Drawing.Point]::new(0,116)
$Script:LogBox.Size        = New-Object System.Drawing.Size(1060,490)
$Script:LogBox.Anchor      = 'Top,Bottom,Left,Right'
$Script:LogBox.BackColor   = [System.Drawing.Color]::FromArgb(10,10,16)
$Script:LogBox.ForeColor   = [System.Drawing.Color]::WhiteSmoke
$Script:LogBox.Font        = New-Object System.Drawing.Font("Consolas",9)
$Script:LogBox.ReadOnly    = $true
$Script:LogBox.ScrollBars  = "ForcedVertical"
$Script:LogBox.WordWrap    = $false
$Script:LogBox.DetectUrls  = $false
$Script:LogBox.BorderStyle = "Fixed3D"
$Script:LogBox.HideSelection = $false
$pageLogs.Controls.Add($Script:LogBox)


# Force l'apparence de la scrollbar
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class ScrollBarStyle {
    [DllImport("uxtheme.dll", CharSet = CharSet.Unicode)]
    public static extern int SetWindowTheme(IntPtr hWnd, string pszSubAppName, string pszSubIdList);
}
"@ -ErrorAction SilentlyContinue

$Script:LogBox.Add_HandleCreated({
    try {
        [ScrollBarStyle]::SetWindowTheme($this.Handle, "DarkMode_Explorer", $null)
    } catch {}
})





# =========================================================
# BARRE D'ACTIONS BASSE
# =========================================================
$bottomPanel = New-Object System.Windows.Forms.Panel
$bottomPanel.Location = [System.Drawing.Point]::new(275,695)
$bottomPanel.Size = New-Object System.Drawing.Size(1080,175)
$bottomPanel.BackColor = $bgPanel
$form.Controls.Add($bottomPanel)

function New-ActionButton {
    param($text,$x,$y,$w,$h,$back,$fore)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Location = [System.Drawing.Point]::new([int]$x,[int]$y)
    $btn.Size = New-Object System.Drawing.Size($w,$h)
    $btn.BackColor = $back
    $btn.ForeColor = $fore
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.Font = New-Object System.Drawing.Font("Segoe UI",9.5,[System.Drawing.FontStyle]::Bold)
    return $btn
}

$bottomTitle = New-Object System.Windows.Forms.Label
$bottomTitle.Text = "Actions possibles"
$bottomTitle.Location = [System.Drawing.Point]::new(20,8)
$bottomTitle.Size = New-Object System.Drawing.Size(260,20)
$bottomTitle.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
$bottomTitle.ForeColor = $muted
$btnScan      = New-ActionButton "Scan PC"          20 36 160 42 $bgCard $white
$btnApps      = New-ActionButton "Installer apps"   195 36 160 42 $bgCard $white
$btnRuntimes  = New-ActionButton "Compatibilite"    370 36 170 42 $bgCard $white
$btnOptimize  = New-ActionButton "Optimisation"     555 36 160 42 $bgCard $white
$btnStructure = New-ActionButton "Structure"        730 36 160 42 $bgCard $white
$btnShortcuts = New-ActionButton "Raccourcis"       20  92 160 42 $bgCard $white
$btnRestore   = New-ActionButton "Restauration"     195 92 160 42 $bgCard $white
$btnAll       = New-ActionButton "TOUT FAIRE"       790 92 152 42 $blue  $black
$btnClearLogs = New-ActionButton "Vider logs"       948 92 126 42 $yellow $black

$btnClearLogs.Font = New-Object System.Drawing.Font("Segoe UI",8.75,[System.Drawing.FontStyle]::Bold)

$Script:ProgressHost = New-Object System.Windows.Forms.Panel
$Script:ProgressHost.Location = [System.Drawing.Point]::new(20,146)
$Script:ProgressHost.Size = New-Object System.Drawing.Size(720,20)
$Script:ProgressHost.BackColor = [System.Drawing.Color]::FromArgb(24,24,34)
$Script:ProgressHost.BorderStyle = 'FixedSingle'

$Script:ProgressFill = New-Object System.Windows.Forms.Panel
$Script:ProgressFill.Location = [System.Drawing.Point]::new(2,2)
$Script:ProgressFill.Size = New-Object System.Drawing.Size(0,16)
$Script:ProgressFill.BackColor = [System.Drawing.Color]::FromArgb(114,96,255)
$Script:ProgressFill.Visible = $false
$Script:ProgressHost.Controls.Add($Script:ProgressFill)

$Script:ProgressBar = New-Object System.Windows.Forms.ProgressBar
$Script:ProgressBar.Minimum = 0
$Script:ProgressBar.Maximum = 100
$Script:ProgressBar.Value = 0
$Script:ProgressBar.Visible = $false

$bottomPanel.Controls.AddRange(@($btnScan,$btnApps,$btnRuntimes,$btnOptimize,$btnStructure,$btnShortcuts,$btnRestore,$btnAll,$btnClearLogs,$Script:ProgressHost,$bottomTitle))

$Script:lblStatus = New-Object System.Windows.Forms.Label
$Script:lblStatus.Text = "Etat : pret"
$Script:lblStatus.Location = [System.Drawing.Point]::new(725,148)
$Script:lblStatus.Size = New-Object System.Drawing.Size(220,16)
$Script:lblStatus.Font = New-Object System.Drawing.Font("Segoe UI",8)
$Script:lblStatus.ForeColor = $muted
$bottomPanel.Controls.Add($Script:lblStatus)

# =========================================================
# MISE EN PAGE RESPONSIVE
# =========================================================
function Update-ResponsiveLayout {
    try {
        $cW = $leftPanel.Width
        $contentX = $cW + 15
        $contentY = 20
        $contentW = [Math]::Max(900, $form.ClientSize.Width - $cW - 30)
        $contentH = [Math]::Max(400, $form.ClientSize.Height - 220)

        $contentPanel.Location = [System.Drawing.Point]::new($contentX,$contentY)
        $contentPanel.Size = New-Object System.Drawing.Size($contentW,$contentH)

        $bottomPanel.Location = [System.Drawing.Point]::new($contentX, ($form.ClientSize.Height - $bottomPanel.Height - 5))
        $bottomPanel.Size = New-Object System.Drawing.Size($contentW,175)

        foreach ($page in @($pageHome,$pageInfo,$pageApps,$pageRun,$pageOpt,$pageDrv,$pageTools,$pageShort,$pageAudio,$pageContact,$pageLogs)) {
            $page.Size = $contentPanel.Size
        }

        # Barre de progression plus visible
        if ($Script:ProgressHost) {
            $progressWidth = [Math]::Max(420,$contentW - 500)
            $Script:ProgressHost.Location = [System.Drawing.Point]::new(20,146)
            $Script:ProgressHost.Size = New-Object System.Drawing.Size($progressWidth,20)
            if ($Script:ProgressFill) {
                $currentValue = if ($Script:ProgressBar) { $Script:ProgressBar.Value } else { 0 }
                Update-Progress -Value $currentValue
            }
            $Script:lblStatus.Location = [System.Drawing.Point]::new(($Script:ProgressHost.Right + 12),145)
        }

        $appsScrollPanel.Size = New-Object System.Drawing.Size(([Math]::Max(800,$contentW - 40)),($contentH - 110))
        $btnScanInfo.Location = [System.Drawing.Point]::new(([Math]::Min(450,$contentW - 200)),12)
        $Script:InfoGrid.Size = New-Object System.Drawing.Size(([Math]::Max(500,$contentW - 50)),($contentH - 75))

        $homeDesc.Size = New-Object System.Drawing.Size(([Math]::Max(600,$contentW - 80)),40)
        $homeTip.Size  = New-Object System.Drawing.Size(([Math]::Max(600,$contentW - 80)),32)

        for ($i=0; $i -lt $homeButtons.Count; $i++) {
            $gapX = [Math]::Max(18,[int](($pageHome.Width - 90 - 750) / 2))
            $x = 30 + (($i % 3) * (250 + $gapX))
            $y = 140 + ([math]::Floor($i / 3) * 95)
            $homeButtons[$i].Location = [System.Drawing.Point]::new($x,$y)
        }

        # Audio layout responsive + overlay navigation (sans bande noire)
        $audioTop.Location = [System.Drawing.Point]::new(0,0)
        $audioTop.Size = New-Object System.Drawing.Size($pageAudio.Width,$audioTop.Height)
        $audioBody.Location = [System.Drawing.Point]::new(0,0)
        $audioBody.Size = New-Object System.Drawing.Size($pageAudio.Width,$pageAudio.Height)

        foreach ($v in @($audioWelcome,$audioArtists,$audioAlbums,$audioSongs,$audioFinish)) {
            $v.Size = $audioBody.Size
            $v.Invalidate()
        }

        # Navigation overlay calibree sur les textes des fonds 1920x1080
        $designW = 1920.0
        $designH = 1080.0
        $sx = { param([double]$v,[int]$w) [int][Math]::Round(($v / $designW) * $w) }
        $sy = { param([double]$v,[int]$h) [int][Math]::Round(($v / $designH) * $h) }

        $hasWelcomeBg = Test-AudioBackgroundExists -Mode 'Welcome'
        $hasArtistsBg = Test-AudioBackgroundExists -Mode 'Artists'
        $hasAlbumsBg  = Test-AudioBackgroundExists -Mode 'Albums'
        $hasSongsBg   = Test-AudioBackgroundExists -Mode 'Songs'

        switch ($Script:CurrentAudioViewName) {
            'Welcome' {
                $navRects = @{
                    'Welcome' = @(490,42,170,52)
                    'Artists' = @(805,46,180,48)
                    'Albums'  = @(1062,46,170,48)
                    'Songs'   = @(1298,46,190,48)
                }
            }
            'Artists' {
                $navRects = @{
                    'Welcome' = @(456,44,170,48)
                    'Artists' = @(716,42,178,52)
                    'Albums'  = @(980,44,168,48)
                    'Songs'   = @(1225,44,192,48)
                }
            }
            'Albums' {
                $navRects = @{
                    'Welcome' = @(456,44,170,48)
                    'Artists' = @(716,44,178,48)
                    'Albums'  = @(970,40,176,54)
                    'Songs'   = @(1225,44,192,48)
                }
            }
            'Songs' {
                $navRects = @{
                    'Welcome' = @(456,44,170,48)
                    'Artists' = @(716,44,178,48)
                    'Albums'  = @(980,44,168,48)
                    'Songs'   = @(1210,40,205,54)
                }
            }
            default {
                $navRects = @{
                    'Welcome' = @(456,44,170,48)
                    'Artists' = @(716,44,178,48)
                    'Albums'  = @(980,44,168,48)
                    'Songs'   = @(1225,44,192,48)
                }
            }
        }

        $overlayMode = if ([string]::IsNullOrWhiteSpace($Script:AudioOverlayMode)) { 'Invisible' } else { $Script:AudioOverlayMode }
        $navTextMap = @{ Welcome='Accueil'; Artists='Artistes'; Albums='Albums'; Songs='Chansons' }
        foreach ($k in @('Welcome','Artists','Albums','Songs')) {
            if ($Script:AudioNavButtons.ContainsKey($k) -and $Script:AudioNavButtons[$k]) {
                $btnNav = $Script:AudioNavButtons[$k]
                $btnNav.FlatStyle = 'Flat'
                $btnNav.FlatAppearance.BorderSize = 0
                $btnNav.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::Transparent
                $btnNav.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::Transparent
                $rect = $navRects[$k]
                if ($rect) {
                    $btnNav.Location = [System.Drawing.Point]::new((& $sx $rect[0] $pageAudio.Width),(& $sy $rect[1] $pageAudio.Height))
                    $btnNav.Size = New-Object System.Drawing.Size((& $sx $rect[2] $pageAudio.Width),(& $sy $rect[3] $pageAudio.Height))
                }
                if ($overlayMode -eq 'Invisible') {
                    $btnNav.Text = ''
                    $btnNav.BackColor = [System.Drawing.Color]::Transparent
                    $btnNav.ForeColor = [System.Drawing.Color]::Transparent
                }
                else {
                    $btnNav.Text = $navTextMap[$k]
                    $btnNav.ForeColor = $white
                    $btnNav.Font = New-Object System.Drawing.Font('Segoe UI',12,[System.Drawing.FontStyle]::Bold)
                    if ($Script:CurrentAudioViewName -eq $k) {
                        $btnNav.BackColor = $purpleActive
                    }
                    else {
                        $btnNav.BackColor = [System.Drawing.Color]::FromArgb(16,16,24)
                    }
                }
                $btnNav.BringToFront()
            }
        }
        $audioBrand.Visible = $false
        $Script:AudioPageBadge.Visible = $false

        # Uniformisation des boutons "Page suivante"
        foreach ($btnNext in @($btnWelcomeNext,$btnArtistsNext,$btnAlbumsNext,$btnSongsNext)) {
            if ($btnNext) {
                $btnNext.FlatStyle = 'Flat'
                $btnNext.FlatAppearance.BorderSize = 0
                $btnNext.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::Transparent
                $btnNext.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::Transparent
                if ($overlayMode -eq 'Invisible') {
                    $btnNext.Text = ''
                    $btnNext.BackColor = [System.Drawing.Color]::Transparent
                    $btnNext.ForeColor = [System.Drawing.Color]::Transparent
                }
                else {
                    $btnNext.Text = 'Page suivante'
                    $btnNext.BackColor = $purple2
                    $btnNext.ForeColor = $white
                    $btnNext.Font = New-Object System.Drawing.Font('Segoe UI',12,[System.Drawing.FontStyle]::Bold)
                }
            }
        }

        # Welcome - calibration sur fond image et degagement du titre
        $welcomeTitle1.AutoSize = $true
        $welcomeTitle2.AutoSize = $true
        $welcomeTitle1.TextAlign = 'MiddleCenter'
        $welcomeTitle2.TextAlign = 'MiddleCenter'
        $welcomeTitle1.Font = New-Object System.Drawing.Font("Segoe UI Light",38,[System.Drawing.FontStyle]::Regular)
        $welcomeTitle2.Font = New-Object System.Drawing.Font("Segoe UI Semibold",66,[System.Drawing.FontStyle]::Bold)
        $Script:WelcomeStyleBadge.Visible = $true
        $Script:WelcomeComboHost.Visible = $true
        $Script:AudioStyleCombo.Location = [System.Drawing.Point]::new(16,9)

        if ($hasWelcomeBg) {
            $welcomeTitle1.Visible = $false
            $welcomeTitle2.Visible = $false
            $Script:WelcomeStyleBadge.Location = [System.Drawing.Point]::new((& $sx 834 $audioWelcome.Width),(& $sy 430 $audioWelcome.Height))
            $Script:WelcomeComboHost.Location = [System.Drawing.Point]::new((& $sx 800 $audioWelcome.Width),(& $sy 486 $audioWelcome.Height))
            $btnWelcomeNext.Size = New-Object System.Drawing.Size((& $sx 198 $audioWelcome.Width),(& $sy 62 $audioWelcome.Height))
            $btnWelcomeNext.Location = [System.Drawing.Point]::new((& $sx 860 $audioWelcome.Width),(& $sy 616 $audioWelcome.Height))
        }
        else {
            $welcomeTitle1.Visible = $true
            $welcomeTitle2.Visible = $true
            $welcomeTitle1.Location = [System.Drawing.Point]::new([int](($audioWelcome.Width - $welcomeTitle1.Width)/2),54)
            $welcomeTitle2.Location = [System.Drawing.Point]::new([int](($audioWelcome.Width - $welcomeTitle2.Width)/2),112)
            $Script:WelcomeStyleBadge.Location = [System.Drawing.Point]::new([int](($audioWelcome.Width - $Script:WelcomeStyleBadge.Width)/2),258)
            $Script:WelcomeComboHost.Location = [System.Drawing.Point]::new([int](($audioWelcome.Width - $Script:WelcomeComboHost.Width)/2),304)
            $btnWelcomeNext.Location = [System.Drawing.Point]::new([int](($audioWelcome.Width - $btnWelcomeNext.Width)/2),450)
        }

        if ($Script:WelcomeHeroCard) { $Script:WelcomeHeroCard.Visible = $false }
        $welcomeTitle1.BringToFront(); $welcomeTitle2.BringToFront(); $Script:WelcomeStyleBadge.BringToFront(); $Script:WelcomeComboHost.BringToFront(); $btnWelcomeNext.BringToFront()

        # Artists - rapprochement maquette page 02
        $Script:AudioSelectedStyleLabel.Visible = (-not $hasArtistsBg)
        $Script:AudioSummaryLabel.Visible = (-not $hasArtistsBg)
        $Script:AudioSelectedStyleLabel.Location = [System.Drawing.Point]::new(62,66)
        $Script:AudioSelectedStyleLabel.Size = New-Object System.Drawing.Size(500,28)
        $Script:AudioSelectedStyleLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold",13,[System.Drawing.FontStyle]::Bold)
        $Script:AudioSummaryLabel.Location = [System.Drawing.Point]::new(62,100)
        $Script:AudioSummaryLabel.Size = New-Object System.Drawing.Size(540,22)
        $Script:AudioArtistFlow.Location = [System.Drawing.Point]::new(62,136)
        $Script:AudioArtistFlow.Size = New-Object System.Drawing.Size(([Math]::Max(540,$audioArtists.Width - 124)),([Math]::Max(220,$audioArtists.Height - 260)))
        if ($Script:AudioArtistsStyleHost) { $Script:AudioArtistsStyleHost.Location = [System.Drawing.Point]::new(($audioArtists.Width - 306),18) }
        $btnArtistsNext.Size = New-Object System.Drawing.Size((& $sx 204 $audioArtists.Width),(& $sy 64 $audioArtists.Height))
        $btnArtistsNext.Location = [System.Drawing.Point]::new((& $sx 1658 $audioArtists.Width),(& $sy 996 $audioArtists.Height))
        $btnArtistsNext.BringToFront()

        # Albums - rapprochement maquette page 03
        $Script:AudioSelectedArtistLabel.Visible = (-not $hasAlbumsBg)
        $Script:AudioSelectedArtistLabel.Location = [System.Drawing.Point]::new(62,66)
        $Script:AudioSelectedArtistLabel.Size = New-Object System.Drawing.Size(540,28)
        $Script:AudioSelectedArtistLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold",13,[System.Drawing.FontStyle]::Bold)
        $Script:AudioArtistPicture.Location = [System.Drawing.Point]::new(62,136)
        $Script:AudioArtistPicture.Size = New-Object System.Drawing.Size(208,208)
        $Script:AudioAlbumFlow.Location = [System.Drawing.Point]::new(318,130)
        $Script:AudioAlbumFlow.Size = New-Object System.Drawing.Size(([Math]::Max(380,$audioAlbums.Width - 382)),([Math]::Max(220,$audioAlbums.Height - 258)))
        if ($Script:AudioAlbumsStyleHost) { $Script:AudioAlbumsStyleHost.Location = [System.Drawing.Point]::new(($audioAlbums.Width - 306),18) }
        $btnAlbumsNext.Size = New-Object System.Drawing.Size((& $sx 204 $audioAlbums.Width),(& $sy 64 $audioAlbums.Height))
        $btnAlbumsNext.Location = [System.Drawing.Point]::new((& $sx 1658 $audioAlbums.Width),(& $sy 996 $audioAlbums.Height))
        $btnAlbumsNext.BringToFront()

        # Songs - page 04 plus propre
        $Script:AudioSelectedAlbumLabel.Visible = (-not $hasSongsBg)
        $Script:AudioSelectedAlbumLabel.Location = [System.Drawing.Point]::new(62,66)
        $Script:AudioSelectedAlbumLabel.Size = New-Object System.Drawing.Size(520,30)
        $Script:AudioSelectedAlbumLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold",14,[System.Drawing.FontStyle]::Bold)
        $Script:AudioCoverPicture.Location = [System.Drawing.Point]::new(62,136)
        $Script:AudioCoverPicture.Size = New-Object System.Drawing.Size(208,208)
        $Script:AudioTrackTitle.Location = [System.Drawing.Point]::new(332,118)
        $Script:AudioTrackTitle.Size = New-Object System.Drawing.Size(([Math]::Max(320,$audioSongs.Width - 424)),46)
        $Script:AudioTrackTitle.Font = New-Object System.Drawing.Font("Segoe UI Light",24,[System.Drawing.FontStyle]::Regular)
        $Script:AudioTrackList.Location = [System.Drawing.Point]::new(332,176)
        $Script:AudioTrackList.Size = New-Object System.Drawing.Size(([Math]::Max(320,$audioSongs.Width - 424)),[Math]::Max(182,$audioSongs.Height - 382))
        if ($Script:AudioSongsStyleHost) { $Script:AudioSongsStyleHost.Location = [System.Drawing.Point]::new(($audioSongs.Width - 306),18) }

        $btnAudioPlay.Location  = [System.Drawing.Point]::new(332,($audioSongs.Height - 138))
        $btnAudioPause.Location = [System.Drawing.Point]::new(464,($audioSongs.Height - 138))
        $btnAudioStop.Location  = [System.Drawing.Point]::new(586,($audioSongs.Height - 138))
        $btnAudioPrev.Location  = [System.Drawing.Point]::new(698,($audioSongs.Height - 138))
        $btnAudioNext.Location  = [System.Drawing.Point]::new(820,($audioSongs.Height - 138))
        $Script:AudioNowPlaying.Location = [System.Drawing.Point]::new(332,($audioSongs.Height - 90))
        $btnSongsNext.Size = New-Object System.Drawing.Size((& $sx 204 $audioSongs.Width),(& $sy 64 $audioSongs.Height))
        $btnSongsNext.Location = [System.Drawing.Point]::new((& $sx 1658 $audioSongs.Width),(& $sy 996 $audioSongs.Height))
        $btnSongsNext.BringToFront()

        # Finish
        $finishText1.AutoSize = $true
        $Script:AudioFinishLabel.AutoSize = $false
        $finishText1.Location = [System.Drawing.Point]::new([int](($audioFinish.Width - $finishText1.PreferredWidth)/2),110)
        $Script:AudioFinishLabel.Location = [System.Drawing.Point]::new([int](($audioFinish.Width - 900)/2),210)
        $Script:AudioFinishLabel.Size = New-Object System.Drawing.Size(900,260)
        $btnFinishRestart.Location = [System.Drawing.Point]::new(($audioFinish.Width - 220),($audioFinish.Height - 78))

        # Contact responsive
        $contactLinksCard.Location = [System.Drawing.Point]::new(([Math]::Min(625,$contentW - 420)),65)

        # Actions basse: grille propre et alignement du bouton Structure
        $row1Y = 36
        $row2Y = 84
        $leftStart = 20
        $gap = 18
        $btnScan.Location = [System.Drawing.Point]::new($leftStart,$row1Y)
        $btnApps.Location = [System.Drawing.Point]::new(($btnScan.Right + $gap),$row1Y)
        $btnRuntimes.Location = [System.Drawing.Point]::new(($btnApps.Right + $gap),$row1Y)
        $btnOptimize.Location = [System.Drawing.Point]::new(($btnRuntimes.Right + $gap),$row1Y)
        $btnStructure.Location = [System.Drawing.Point]::new(($btnOptimize.Right + $gap),$row1Y)
        $btnShortcuts.Location = [System.Drawing.Point]::new($leftStart,$row2Y)
        $btnRestore.Location = [System.Drawing.Point]::new(($btnShortcuts.Right + $gap),$row2Y)

        $btnClearLogs.Location = [System.Drawing.Point]::new(($contentW - $btnClearLogs.Width - 20),62)
        $btnAll.Location = [System.Drawing.Point]::new(($btnClearLogs.Left - $btnAll.Width - 16),62)
    } catch {}
}


function Register-AudioStyleCombo {
    param([System.Windows.Forms.ComboBox]$Combo)
    if (-not $Combo) { return }
    $Script:AudioStyleCombos += $Combo
    $Combo.Add_SelectedIndexChanged({
        if ($Script:AudioStyleSyncing) { return }
        $selected = $this.SelectedItem
        if ($null -eq $selected) { return }
        Sync-AudioStyleCombos -Value $selected.ToString() -SourceCombo $this
        Refresh-AudioViewData
    })
}

function Sync-AudioStyleCombos {
    param(
        [string]$Value,
        [System.Windows.Forms.ComboBox]$SourceCombo
    )
    $Script:AudioStyleSyncing = $true
    foreach ($combo in $Script:AudioStyleCombos) {
        if ($combo -and $combo -ne $SourceCombo) {
            $idx = $combo.Items.IndexOf($Value)
            if ($idx -ge 0) { $combo.SelectedIndex = $idx }
        }
    }
    if ($Script:AudioStyleCombo -and $Script:AudioStyleCombo -ne $SourceCombo) {
        $idxMain = $Script:AudioStyleCombo.Items.IndexOf($Value)
        if ($idxMain -ge 0) { $Script:AudioStyleCombo.SelectedIndex = $idxMain }
    }
    $Script:AudioStyleSyncing = $false
}

function Get-SelectedAudioStyle {
    if ($Script:AudioStyleCombo -and $Script:AudioStyleCombo.SelectedItem) {
        return $Script:AudioStyleCombo.SelectedItem.ToString()
    }
    return "Tous les styles"
}

function Test-AudioPathMatchesStyle {
    param([string]$Path,[string]$StyleFilter)
    if ([string]::IsNullOrWhiteSpace($StyleFilter) -or $StyleFilter -eq "Tous les styles") { return $true }
    return ($Path -like "*\$StyleFilter\*")
}

function Get-AudioStyles {
    if (-not (Test-Path $Script:MusicRoot)) { return @() }
    return @(Get-ChildItem $Script:MusicRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -ExpandProperty Name)
}

function Load-AudioStyleList {
    $styleValues = @("Tous les styles") + (Get-AudioStyles)
    foreach ($combo in @($Script:AudioStyleCombo) + $Script:AudioStyleCombos) {
        if (-not $combo) { continue }
        $current = if ($combo.SelectedItem) { $combo.SelectedItem.ToString() } else { "Tous les styles" }
        $combo.Items.Clear()
        foreach ($style in $styleValues) { [void]$combo.Items.Add($style) }
        $idx = $combo.Items.IndexOf($current)
        if ($idx -lt 0) { $idx = 0 }
        $combo.SelectedIndex = $idx
    }
}

function Get-AudioArtistEntries {
    param([string]$StyleFilter)
    $entries = @()
    if (-not (Test-Path $Script:MusicRoot)) { return $entries }
    $styleDirs = if ([string]::IsNullOrWhiteSpace($StyleFilter) -or $StyleFilter -eq "Tous les styles") {
        @(Get-ChildItem $Script:MusicRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name)
    } else {
        $dir = Join-Path $Script:MusicRoot $StyleFilter
        if (Test-Path $dir) { @([System.IO.DirectoryInfo](Get-Item $dir)) } else { @() }
    }

    foreach ($styleDir in $styleDirs) {
        $artists = @(Get-ChildItem $styleDir.FullName -Directory -ErrorAction SilentlyContinue | Sort-Object Name)
        foreach ($artist in $artists) {
            $albums = @(Get-ChildItem $artist.FullName -Directory -ErrorAction SilentlyContinue)
            $hasAudio = $false
            foreach ($album in $albums) {
                $tracks = @(Get-ChildItem $album.FullName -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in ".mp3",".wav",".flac" })
                if ($tracks.Count -gt 0) { $hasAudio = $true; break }
            }
            if ($hasAudio) {
                $entries += [PSCustomObject]@{
                    StyleName  = $styleDir.Name
                    ArtistName = $artist.Name
                    ArtistPath = $artist.FullName
                }
            }
        }
    }
    return @($entries | Sort-Object StyleName, ArtistName)
}

function Get-AudioAlbumEntries {
    param([string]$StyleFilter,[string]$ArtistPath)

    $entries = @()
    if ($ArtistPath) {
        if (Test-Path $ArtistPath) {
            $styleName = Split-Path (Split-Path $ArtistPath -Parent) -Leaf
            if (Test-AudioPathMatchesStyle -Path $ArtistPath -StyleFilter $StyleFilter) {
                foreach ($album in @(Get-ChildItem $ArtistPath -Directory -ErrorAction SilentlyContinue | Sort-Object Name)) {
                    $entries += [PSCustomObject]@{
                        StyleName  = $styleName
                        ArtistName = Split-Path $ArtistPath -Leaf
                        AlbumName  = $album.Name
                        AlbumPath  = $album.FullName
                    }
                }
            }
        }
    }
    else {
        foreach ($artistEntry in Get-AudioArtistEntries -StyleFilter $StyleFilter) {
            foreach ($album in @(Get-ChildItem $artistEntry.ArtistPath -Directory -ErrorAction SilentlyContinue | Sort-Object Name)) {
                $entries += [PSCustomObject]@{
                    StyleName  = $artistEntry.StyleName
                    ArtistName = $artistEntry.ArtistName
                    AlbumName  = $album.Name
                    AlbumPath  = $album.FullName
                }
            }
        }
    }
    return @($entries | Sort-Object ArtistName, AlbumName)
}

function Get-AudioTrackEntries {
    param([string]$StyleFilter,[string]$AlbumPath)

    $entries = @()
    if ($AlbumPath) {
        if (Test-Path $AlbumPath) {
            $artistName = Split-Path (Split-Path $AlbumPath -Parent) -Leaf
            $styleName  = Split-Path (Split-Path (Split-Path $AlbumPath -Parent) -Parent) -Leaf
            if (Test-AudioPathMatchesStyle -Path $AlbumPath -StyleFilter $StyleFilter) {
                foreach ($track in @(Get-ChildItem $AlbumPath -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in ".mp3",".wav",".flac" } | Sort-Object Name)) {
                    $entries += [PSCustomObject]@{
                        StyleName   = $styleName
                        ArtistName  = $artistName
                        AlbumName   = Split-Path $AlbumPath -Leaf
                        TrackName   = $track.BaseName
                        TrackPath   = $track.FullName
                        FileObject  = $track
                    }
                }
            }
        }
    }
    else {
        foreach ($albumEntry in Get-AudioAlbumEntries -StyleFilter $StyleFilter) {
            foreach ($track in @(Get-ChildItem $albumEntry.AlbumPath -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in ".mp3",".wav",".flac" } | Sort-Object Name)) {
                $entries += [PSCustomObject]@{
                    StyleName   = $albumEntry.StyleName
                    ArtistName  = $albumEntry.ArtistName
                    AlbumName   = $albumEntry.AlbumName
                    TrackName   = $track.BaseName
                    TrackPath   = $track.FullName
                    FileObject  = $track
                }
            }
        }
    }
    return @($entries | Sort-Object ArtistName, AlbumName, TrackName)
}

function Reset-AudioState {
    $Script:CurrentTrackList  = @()
    $Script:CurrentTrackIndex = -1
    $Script:CurrentArtistPath = $null
    $Script:CurrentAlbumPath  = $null
    $Script:CurrentArtistName = ""
    $Script:CurrentAlbumName  = ""
    if ($Script:AudioNowPlaying)          { $Script:AudioNowPlaying.Text          = "Lecture : aucune" }
    if ($Script:AudioSelectedArtistLabel) { $Script:AudioSelectedArtistLabel.Text = "Artiste : vue globale" }
    if ($Script:AudioSelectedAlbumLabel)  { $Script:AudioSelectedAlbumLabel.Text  = "Album : vue globale" }
    if ($Script:AudioSelectedStyleLabel)  { $Script:AudioSelectedStyleLabel.Text  = "Style : Tous les styles" }
    if ($Script:AudioSummaryLabel)        { $Script:AudioSummaryLabel.Text        = "Choisis un style pour commencer." }
    if ($Script:AudioArtistPicture)       { $Script:AudioArtistPicture.Image      = $null; $Script:AudioArtistPicture.Visible = $false }
    if ($Script:AudioCoverPicture)        { $Script:AudioCoverPicture.Image       = $null; $Script:AudioCoverPicture.Visible = $false }
    if ($Script:AudioTrackList)           { $Script:AudioTrackList.Items.Clear() }
    if ($Script:AudioArtistFlow)          { $Script:AudioArtistFlow.Controls.Clear() }
    if ($Script:AudioAlbumFlow)           { $Script:AudioAlbumFlow.Controls.Clear() }
    if ($Script:AudioTrackTitle)          { $Script:AudioTrackTitle.Text          = "aucune" }
    Load-AudioStyleList
    Sync-AudioStyleCombos -Value "Tous les styles" -SourceCombo $null
}

function Set-AudioView {
    param([string]$ViewName)
    $Script:CurrentAudioViewName = $ViewName
    foreach ($k in $Script:AudioViewPanels.Keys) {
        $Script:AudioViewPanels[$k].Visible = $false
    }
    foreach ($k in $Script:AudioNavButtons.Keys) {
        $Script:AudioNavButtons[$k].ForeColor = $audioText
        $Script:AudioNavButtons[$k].BackColor = $audioDark
        $Script:AudioNavButtons[$k].Font = New-Object System.Drawing.Font("Segoe UI",13,[System.Drawing.FontStyle]::Regular)
    }
    if ($Script:AudioViewPanels.ContainsKey($ViewName)) { $Script:AudioViewPanels[$ViewName].Visible = $true }
    if ($Script:AudioNavButtons.ContainsKey($ViewName)) {
        $Script:AudioNavButtons[$ViewName].ForeColor = $white
        $Script:AudioNavButtons[$ViewName].BackColor = $purpleActive
        $Script:AudioNavButtons[$ViewName].Font = New-Object System.Drawing.Font("Segoe UI",13,[System.Drawing.FontStyle]::Bold)
    }
    if ($Script:AudioPageBadgeLabel) {
        switch ($ViewName) {
            "Welcome" { $Script:AudioPageBadgeLabel.Text = "Page 01" }
            "Artists" { $Script:AudioPageBadgeLabel.Text = "Page 02" }
            "Albums"  { $Script:AudioPageBadgeLabel.Text = "Page 03" }
            "Songs"   { $Script:AudioPageBadgeLabel.Text = "Page 04" }
            "Finish"  { $Script:AudioPageBadgeLabel.Text = "Page 05" }
        }
    }
}

function New-AudioArtistCard {
    param([psobject]$Entry)
    $card = New-Object System.Windows.Forms.Panel
    $card.Size = New-Object System.Drawing.Size(188,232)
    $card.BackColor = $audioCard
    $card.Margin = New-Object System.Windows.Forms.Padding(18)
    $card.Cursor = [System.Windows.Forms.Cursors]::Hand
    $card.Tag = $Entry.ArtistPath

    $pic = New-Object System.Windows.Forms.PictureBox
    $pic.Location = [System.Drawing.Point]::new(16,16)
    $pic.Size = New-Object System.Drawing.Size(156,136)
    $pic.SizeMode = "Zoom"
    $pic.BackColor = $audioPanel
    $pic.Tag = $Entry.ArtistPath
    $loadedImg = Load-ImageSafe -ImagePath (Join-Path $Entry.ArtistPath "artist.jpg")
    if ($loadedImg) { $pic.Image = $loadedImg }

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Entry.ArtistName
    $lbl.Location = [System.Drawing.Point]::new(10,162)
    $lbl.Size = New-Object System.Drawing.Size(168,28)
    $lbl.TextAlign = "MiddleCenter"
    $lbl.ForeColor = $audioText
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $lbl.Tag = $Entry.ArtistPath

    $styleLbl = New-Object System.Windows.Forms.Label
    $styleLbl.Text = $Entry.StyleName
    $styleLbl.Location = [System.Drawing.Point]::new(18,194)
    $styleLbl.Size = New-Object System.Drawing.Size(150,22)
    $styleLbl.TextAlign = "MiddleCenter"
    $styleLbl.ForeColor = $audioMuted
    $styleLbl.Font = New-Object System.Drawing.Font("Segoe UI",8)
    $styleLbl.Tag = $Entry.ArtistPath

    $clickAction = { $path = $this.Tag; if (-not [string]::IsNullOrWhiteSpace($path)) { Show-AudioArtist -ArtistPath $path } }
    $card.Add_Click($clickAction); $pic.Add_Click($clickAction); $lbl.Add_Click($clickAction); $styleLbl.Add_Click($clickAction)
    $card.Controls.AddRange(@($pic,$lbl,$styleLbl))
    return $card
}

function Load-AudioArtists {
    param([string]$Style = $(Get-SelectedAudioStyle))
    if (-not $Script:AudioArtistFlow) { return }
    $Script:CurrentStyle = $Style
    if ($Script:AudioSelectedStyleLabel) { $Script:AudioSelectedStyleLabel.Text = "Style : $Style" }
    $Script:AudioArtistFlow.Controls.Clear()
    $entries = Get-AudioArtistEntries -StyleFilter $Style
    foreach ($entry in $entries) {
        $Script:AudioArtistFlow.Controls.Add((New-AudioArtistCard -Entry $entry))
    }
    if ($Script:AudioSummaryLabel) { $Script:AudioSummaryLabel.Text = "$($entries.Count) artiste(s) detecte(s)." }
    Write-Log "Artistes charges : $($entries.Count) | Style : $Style"
}

function Show-AudioArtist {
    param([string]$ArtistPath)
    if ([string]::IsNullOrWhiteSpace($ArtistPath) -or -not (Test-Path $ArtistPath)) {
        Write-Log "Dossier artiste introuvable" "ERROR"; return
    }
    $Script:CurrentArtistPath = $ArtistPath
    $Script:CurrentArtistName = Split-Path $ArtistPath -Leaf
    if ($Script:AudioSelectedArtistLabel) { $Script:AudioSelectedArtistLabel.Text = "Artiste : $($Script:CurrentArtistName)" }
    $loadedArtist = Load-ImageSafe -ImagePath (Join-Path $ArtistPath "artist.jpg")
    if ($Script:AudioArtistPicture) { $Script:AudioArtistPicture.Image = $loadedArtist }
    Load-AudioAlbums -ArtistPath $ArtistPath
    Set-AudioView "Albums"
    Write-Log "Artiste charge : $($Script:CurrentArtistName)"
}

function Select-AudioAlbum {
    param(
        [string]$AlbumPath,
        [System.Windows.Forms.Control]$CardControl
    )
    if ([string]::IsNullOrWhiteSpace($AlbumPath) -or -not (Test-Path $AlbumPath)) { return }

    $Script:CurrentAlbumPath = $AlbumPath
    $Script:CurrentAlbumName = Split-Path $AlbumPath -Leaf
    $artistPath = Split-Path $AlbumPath -Parent
    $artistName = Split-Path $artistPath -Leaf
    $Script:CurrentArtistPath = $artistPath
    $Script:CurrentArtistName = $artistName

    if ($Script:AudioSelectedAlbumLabel)  { $Script:AudioSelectedAlbumLabel.Text  = "Album : $($Script:CurrentAlbumName)" }
    if ($Script:AudioSelectedArtistLabel) { $Script:AudioSelectedArtistLabel.Text = "Artiste : $artistName" }

    $artistImg = Load-ImageSafe -ImagePath (Join-Path $artistPath "artist.jpg")
    if ($Script:AudioArtistPicture) { $Script:AudioArtistPicture.Image = $artistImg }

    if ($Script:AudioSelectedAlbumCard -and $Script:AudioSelectedAlbumCard -is [System.Windows.Forms.Control]) {
        try { $Script:AudioSelectedAlbumCard.BackColor = $audioCard } catch {}
    }
    if ($CardControl) {
        try { $CardControl.BackColor = [System.Drawing.Color]::FromArgb(52,52,76) } catch {}
        $Script:AudioSelectedAlbumCard = $CardControl
    }

    Write-Log "Album selectionne : $($Script:CurrentAlbumName)"
}

function New-AudioAlbumCard {
    param([psobject]$Entry)
    $card = New-Object System.Windows.Forms.Panel
    $card.Size = New-Object System.Drawing.Size(172,198)
    $card.BackColor = $audioCard
    $card.Margin = New-Object System.Windows.Forms.Padding(12)
    $card.Cursor = [System.Windows.Forms.Cursors]::Hand
    $card.Tag = $Entry.AlbumPath

    $artistLbl = New-Object System.Windows.Forms.Label
    $artistLbl.Text = $Entry.ArtistName
    $artistLbl.Location = [System.Drawing.Point]::new(10,8)
    $artistLbl.Size = New-Object System.Drawing.Size(152,18)
    $artistLbl.TextAlign = "MiddleCenter"
    $artistLbl.ForeColor = $audioMuted
    $artistLbl.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
    $artistLbl.Tag = $Entry.AlbumPath

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Entry.AlbumName
    $lbl.Location = [System.Drawing.Point]::new(10,26)
    $lbl.Size = New-Object System.Drawing.Size(152,24)
    $lbl.TextAlign = "MiddleCenter"
    $lbl.ForeColor = $audioText
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $lbl.Tag = $Entry.AlbumPath

    $pic = New-Object System.Windows.Forms.PictureBox
    $pic.Location = [System.Drawing.Point]::new(24,58)
    $pic.Size = New-Object System.Drawing.Size(124,112)
    $pic.SizeMode = "Zoom"
    $pic.BackColor = $audioPanel
    $pic.Tag = $Entry.AlbumPath
    $loadedCover = Load-ImageSafe -ImagePath (Join-Path $Entry.AlbumPath "cover.jpg")
    if ($loadedCover) { $pic.Image = $loadedCover }

    $styleLbl = New-Object System.Windows.Forms.Label
    $styleLbl.Text = $Entry.StyleName
    $styleLbl.Location = [System.Drawing.Point]::new(10,174)
    $styleLbl.Size = New-Object System.Drawing.Size(152,16)
    $styleLbl.TextAlign = "MiddleCenter"
    $styleLbl.ForeColor = $audioMuted
    $styleLbl.Font = New-Object System.Drawing.Font("Segoe UI",8)
    $styleLbl.Tag = $Entry.AlbumPath

    $selectAction = {
        $path = $this.Tag
        if (-not [string]::IsNullOrWhiteSpace($path)) { Select-AudioAlbum -AlbumPath $path -CardControl $card }
    }
    $openAction = {
        $path = $this.Tag
        if (-not [string]::IsNullOrWhiteSpace($path)) {
            Select-AudioAlbum -AlbumPath $path -CardControl $card
            Show-AudioAlbum -AlbumPath $path
        }
    }

    $card.Add_Click($selectAction)
    $pic.Add_Click($selectAction)
    $lbl.Add_Click($selectAction)
    $artistLbl.Add_Click($selectAction)
    $styleLbl.Add_Click($selectAction)

    $card.Add_DoubleClick($openAction)
    $pic.Add_DoubleClick($openAction)
    $lbl.Add_DoubleClick($openAction)
    $artistLbl.Add_DoubleClick($openAction)
    $styleLbl.Add_DoubleClick($openAction)

    $card.Controls.AddRange(@($artistLbl,$lbl,$pic,$styleLbl))
    return $card
}

function Load-AudioAlbums {
    param([string]$ArtistPath)
    if (-not $Script:AudioAlbumFlow) { return }
    $Script:AudioAlbumFlow.Controls.Clear()
    $Script:AudioSelectedAlbumCard = $null
    $styleFilter = Get-SelectedAudioStyle
    $useArtistPath = if ($ArtistPath -and (Test-AudioPathMatchesStyle -Path $ArtistPath -StyleFilter $styleFilter)) { $ArtistPath } else { $null }
    $entries = Get-AudioAlbumEntries -StyleFilter $styleFilter -ArtistPath $useArtistPath

    if (-not $useArtistPath) {
        $Script:CurrentArtistPath = $null
        $Script:CurrentArtistName = ""
        if ($Script:AudioSelectedArtistLabel) { $Script:AudioSelectedArtistLabel.Text = "Artiste : vue globale" }
        if ($Script:AudioArtistPicture) { $Script:AudioArtistPicture.Image = $null; $Script:AudioArtistPicture.Visible = $false }
    }

    if ($useArtistPath -and $Script:AudioArtistPicture) { $Script:AudioArtistPicture.Visible = $true }

    foreach ($entry in $entries) {
        $Script:AudioAlbumFlow.Controls.Add((New-AudioAlbumCard -Entry $entry))
    }

    if ($Script:AudioSummaryLabel) {
        $Script:AudioSummaryLabel.Text = "$($entries.Count) album(s) detecte(s) | Filtre : $styleFilter | Clic = selection | Double-clic = ouvrir"
    }
    Write-Log "Albums charges : $($entries.Count) | Filtre : $styleFilter"
}

function Show-AudioAlbum {
    param([string]$AlbumPath)
    if ([string]::IsNullOrWhiteSpace($AlbumPath) -or -not (Test-Path $AlbumPath)) {
        Write-Log "Dossier album introuvable" "ERROR"; return
    }
    if (-not $Script:CurrentAlbumPath -or $Script:CurrentAlbumPath -ne $AlbumPath) {
        Select-AudioAlbum -AlbumPath $AlbumPath
    }
    $loadedCover = Load-ImageSafe -ImagePath (Join-Path $AlbumPath "cover.jpg")
    if ($Script:AudioCoverPicture) { $Script:AudioCoverPicture.Image = $loadedCover }
    Load-AudioTracks -AlbumPath $AlbumPath
    Set-AudioView "Songs"
    Write-Log "Album ouvert : $($Script:CurrentAlbumName)"
}

function Load-AudioTracks {
    param([string]$AlbumPath)
    if (-not $Script:AudioTrackList) { return }
    $Script:AudioTrackList.Items.Clear()
    $styleFilter = Get-SelectedAudioStyle
    $useAlbumPath = if ($AlbumPath -and (Test-AudioPathMatchesStyle -Path $AlbumPath -StyleFilter $styleFilter)) { $AlbumPath } else { $null }
    $entries = Get-AudioTrackEntries -StyleFilter $styleFilter -AlbumPath $useAlbumPath

    $Script:CurrentTrackList  = @($entries | ForEach-Object { $_.FileObject })
    $Script:CurrentTrackIndex = -1

    if (-not $useAlbumPath) {
        $Script:CurrentAlbumPath = $null
        $Script:CurrentAlbumName = ""
        if ($Script:AudioSelectedAlbumLabel) { $Script:AudioSelectedAlbumLabel.Text = "Album : vue globale" }
        if ($Script:AudioCoverPicture) { $Script:AudioCoverPicture.Image = $null; $Script:AudioCoverPicture.Visible = $false }
        if ($Script:AudioTrackTitle) { $Script:AudioTrackTitle.Text = "Bibliotheque filtree" }
    } else {
        if ($Script:AudioCoverPicture) { $Script:AudioCoverPicture.Visible = $true }
        if ($Script:AudioTrackTitle) { $Script:AudioTrackTitle.Text = $Script:CurrentAlbumName }
    }

    foreach ($entry in $entries) {
        $display = if ($useAlbumPath) { $entry.TrackName } else { "$($entry.ArtistName) - $($entry.AlbumName) - $($entry.TrackName)" }
        [void]$Script:AudioTrackList.Items.Add($display)
    }

    if ($Script:AudioSummaryLabel) {
        $Script:AudioSummaryLabel.Text = "$($entries.Count) chanson(s) detectee(s) | Filtre : $styleFilter"
    }
    Write-Log "Chansons chargees : $($entries.Count) | Filtre : $styleFilter"
}

function Refresh-AudioViewData {
    $currentStyle = Get-SelectedAudioStyle
    if ($Script:AudioSelectedStyleLabel) { $Script:AudioSelectedStyleLabel.Text = "Style : $currentStyle" }
    switch ($Script:CurrentAudioViewName) {
        "Artists" { Load-AudioArtists -Style $currentStyle }
        "Albums"  {
            if ($Script:CurrentArtistPath -and (Test-AudioPathMatchesStyle -Path $Script:CurrentArtistPath -StyleFilter $currentStyle)) {
                Load-AudioAlbums -ArtistPath $Script:CurrentArtistPath
            } else {
                Load-AudioAlbums
            }
        }
        "Songs"   {
            if ($Script:CurrentAlbumPath -and (Test-AudioPathMatchesStyle -Path $Script:CurrentAlbumPath -StyleFilter $currentStyle)) {
                Load-AudioTracks -AlbumPath $Script:CurrentAlbumPath
            } else {
                Load-AudioTracks
            }
        }
    }
}

function New-TextIconPng {
    param(
        [string]$Path,
        [string]$Text,
        [System.Drawing.Color]$BackColor,
        [System.Drawing.Color]$ForeColor,
        [int]$Size = 32
    )

    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    $dir = Split-Path -Path $Path -Parent
    if (-not [string]::IsNullOrWhiteSpace($dir)) { Ensure-Dir $dir }

    $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($bmp)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $backBrush = New-Object System.Drawing.SolidBrush($BackColor)
    $textBrush = New-Object System.Drawing.SolidBrush($ForeColor)
    $font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $iconRect = New-Object System.Drawing.RectangleF(0,0,($Size-1),($Size-1))
    $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
    $gp.AddArc(0,0,12,12,180,90)
    $gp.AddArc(($Size-13),0,12,12,270,90)
    $gp.AddArc(($Size-13),($Size-13),12,12,0,90)
    $gp.AddArc(0,($Size-13),12,12,90,90)
    $gp.CloseFigure()
    $graphics.FillPath($backBrush, $gp)

    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $graphics.DrawString($Text, $font, $textBrush, $iconRect, $sf)

    $bmp.Save($Path,[System.Drawing.Imaging.ImageFormat]::Png)
    $sf.Dispose(); $gp.Dispose(); $font.Dispose(); $textBrush.Dispose(); $backBrush.Dispose(); $graphics.Dispose(); $bmp.Dispose()
}

function Ensure-DefaultIcons {
    Ensure-Dir $Script:IconRoot
    $defs = @(
        @{Key="home";  Txt="A";  Back=$purpleActive},
        @{Key="info";  Txt="PC"; Back=$blue},
        @{Key="apps";  Txt="AP"; Back=$green},
        @{Key="run";   Txt="RT"; Back=$yellow},
        @{Key="opt";   Txt="OP"; Back=[System.Drawing.Color]::FromArgb(255,140,95)},
        @{Key="drv";   Txt="DR"; Back=[System.Drawing.Color]::FromArgb(80,170,255)},
        @{Key="tools"; Txt="OT"; Back=[System.Drawing.Color]::FromArgb(160,110,255)},
        @{Key="short"; Txt="RC"; Back=[System.Drawing.Color]::FromArgb(100,200,160)},
        @{Key="audio"; Txt="AU"; Back=[System.Drawing.Color]::FromArgb(220,120,240)},
        @{Key="contact"; Txt="CT"; Back=[System.Drawing.Color]::FromArgb(220,170,90)},
        @{Key="logs";  Txt="LG"; Back=[System.Drawing.Color]::FromArgb(120,130,160)},
        @{Key="scan";  Txt="SC"; Back=$blue},
        @{Key="install"; Txt="IN"; Back=$green},
        @{Key="runt"; Txt="RT"; Back=$yellow},
        @{Key="optim"; Txt="OP"; Back=[System.Drawing.Color]::FromArgb(255,140,95)},
        @{Key="struct"; Txt="ST"; Back=[System.Drawing.Color]::FromArgb(140,120,255)},
        @{Key="shortcuts"; Txt="RC"; Back=[System.Drawing.Color]::FromArgb(100,200,160)},
        @{Key="restore"; Txt="RS"; Back=[System.Drawing.Color]::FromArgb(220,90,140)},
        @{Key="all"; Txt="GO"; Back=$blue},
        @{Key="clear"; Txt="CL"; Back=$yellow},
        @{Key="assistant"; Txt="GO"; Back=$purpleActive}
    )
    foreach ($def in $defs) {
        $fallbackPath = Join-Path $Script:IconRoot ("fallback_" + $def.Key + ".png")
        if (-not (Test-Path $fallbackPath)) {
            New-TextIconPng -Path $fallbackPath -Text $def.Txt -BackColor $def.Back -ForeColor $white
        }
    }
}

function Resolve-IconPath {
    param([string]$Key)

    if ([string]::IsNullOrWhiteSpace($Key)) { return $null }
    if (-not (Test-Path $Script:IconRoot)) { return $null }

    $directCandidates = @()
    if ($Script:IconFileMap.ContainsKey($Key)) {
        $directCandidates += @($Script:IconFileMap[$Key])
    }

    foreach ($candidate in $directCandidates) {
        if ($candidate -notmatch '\*') {
            $full = Join-Path $Script:IconRoot $candidate
            if (Test-Path $full) { return $full }
        }
    }

    $pngs = @(Get-ChildItem -Path $Script:IconRoot -Recurse -File -Filter *.png -ErrorAction SilentlyContinue)
    foreach ($candidate in $directCandidates) {
        if ($candidate -match '\*') {
            $found = $pngs | Where-Object { $_.Name -like $candidate } | Select-Object -First 1
            if ($found) { return $found.FullName }
        }
    }

    $fallbackPath = Join-Path $Script:IconRoot ("fallback_" + $Key + ".png")
    if (Test-Path $fallbackPath) { return $fallbackPath }

    return $null
}

function Get-ScaledButtonImage {
    param(
        [string]$ImagePath,
        [int]$Width = 20,
        [int]$Height = 20
    )
    if ([string]::IsNullOrWhiteSpace($ImagePath) -or -not (Test-Path $ImagePath)) { return $null }
    try {
        $source = [System.Drawing.Image]::FromFile($ImagePath)
        $bmp = New-Object System.Drawing.Bitmap($Width, $Height)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($source, 0, 0, $Width, $Height)
        $g.Dispose()
        $source.Dispose()
        return $bmp
    } catch {
        return $null
    }
}

function Set-ButtonIcon {
    param([System.Windows.Forms.Button]$Button,[string]$Key)
    if (-not $Button) { return }

    $path = Resolve-IconPath -Key $Key
    if (-not $path) { return }

    $w = 32
    $h = 32
    $padLeft = 14
    $textAlign = [System.Drawing.ContentAlignment]::MiddleLeft

    if ($Button.Parent -eq $navPanel) {
        $w = 40; $h = 40; $padLeft = 12
        $textAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    } elseif ($homeButtons -and ($homeButtons -contains $Button)) {
        $w = 40; $h = 40; $padLeft = 12
        $textAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    } elseif ($Button -eq $btnAll) {
        $w = 34; $h = 34; $padLeft = 10
        $textAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    } elseif ($Button -eq $btnClearLogs) {
        $w = 34; $h = 34; $padLeft = 8
        $textAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    } else {
        $w = 34; $h = 34; $padLeft = 12
        $textAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }

    $scaled = Get-ScaledButtonImage -ImagePath $path -Width $w -Height $h
    if (-not $scaled) { return }

    try {
        $Button.Image = $scaled
        $Button.ImageAlign = [System.Drawing.ContentAlignment]::MiddleLeft
        $Button.TextImageRelation = [System.Windows.Forms.TextImageRelation]::ImageBeforeText
        $Button.TextAlign = $textAlign
        $Button.Padding = New-Object System.Windows.Forms.Padding($padLeft,0,10,0)
    } catch {}
}

function Apply-UiIcons {
    Ensure-DefaultIcons
    Set-ButtonIcon $navHome "home"
    Set-ButtonIcon $navInfo "info"
    Set-ButtonIcon $navApps "apps"
    Set-ButtonIcon $navRun "run"
    Set-ButtonIcon $navOpt "opt"
    Set-ButtonIcon $navDrv "drv"
    Set-ButtonIcon $navTools "tools"
    Set-ButtonIcon $navShort "short"
    Set-ButtonIcon $navContact "contact"
    Set-ButtonIcon $navLogs "logs"

    Set-ButtonIcon $btnScan "scan"
    Set-ButtonIcon $btnApps "install"
    Set-ButtonIcon $btnRuntimes "runt"
    Set-ButtonIcon $btnOptimize "optim"
    Set-ButtonIcon $btnStructure "struct"
    Set-ButtonIcon $btnShortcuts "shortcuts"
    Set-ButtonIcon $btnRestore "restore"
    Set-ButtonIcon $btnAll "all"
    Set-ButtonIcon $btnClearLogs "clear"

    if ($homeButtons.Count -ge 6) {
        Set-ButtonIcon $homeButtons[0] "info"
        Set-ButtonIcon $homeButtons[1] "apps"
        Set-ButtonIcon $homeButtons[2] "run"
        Set-ButtonIcon $homeButtons[3] "opt"
        Set-ButtonIcon $homeButtons[4] "tools"
        Set-ButtonIcon $homeButtons[5] "assistant"
    }
}

# =========================================================
# EVENEMENTS NAVIGATION PRINCIPALE
# =========================================================
$navHome.Add_Click({    Set-ActivePage $pageHome    $navHome    })
$navInfo.Add_Click({    Set-ActivePage $pageInfo    $navInfo    })
$navApps.Add_Click({    Set-ActivePage $pageApps    $navApps    })
$navRun.Add_Click({     Set-ActivePage $pageRun     $navRun     })
$navOpt.Add_Click({     Set-ActivePage $pageOpt     $navOpt     })
$navDrv.Add_Click({     Set-ActivePage $pageDrv     $navDrv     })
$navTools.Add_Click({   Set-ActivePage $pageTools   $navTools   })
$navShort.Add_Click({   Set-ActivePage $pageShort   $navShort   })
$navContact.Add_Click({ Set-ActivePage $pageContact $navContact })
$navLogs.Add_Click({    Set-ActivePage $pageLogs    $navLogs    })
$navAudio.Add_Click({
    Set-ActivePage $pageHome $navHome
})

# =========================================================
# EVENEMENTS BOUTONS D'ACTION
# =========================================================
$btnScan.Add_Click({ Set-ActivePage $pageLogs $navLogs; Write-Log "Scan PC en cours..."; Show-PCInfo; Set-ActivePage $pageInfo $navInfo })
$btnScanInfo.Add_Click({ Write-Log "Rafraichissement du scan PC"; Show-PCInfo })

$btnApps.Add_Click({
    Set-ActivePage $pageLogs $navLogs
    Start-ExecutionReport "Installation applications"
    Write-Log "Installation de la selection d applications"
    Install-SelectedApps
    Show-ExecutionSummary "Installation applications"
})
$btnRuntimes.Add_Click({
    Set-ActivePage $pageLogs $navLogs
    Start-ExecutionReport "Installation compatibilite"
    Write-Log "Installation des composants de compatibilite selectionnes"
    Install-SelectedRuntimes
    Show-ExecutionSummary "Installation compatibilite"
})
$btnOptimize.Add_Click({
    Set-ActivePage $pageLogs $navLogs
    Start-ExecutionReport "Optimisation Windows"
    Write-Log "Execution de l optimisation Windows"
    Apply-SelectedOptimizations
    Show-ExecutionSummary "Optimisation Windows"
})
$btnStructure.Add_Click({
    Set-ActivePage $pageLogs $navLogs
    Start-ExecutionReport "Creation structure"
    Write-Log "Creation de la structure de dossiers"
    Initialize-Structure
    Show-ExecutionSummary "Creation structure"
})
$btnShortcuts.Add_Click({
    Set-ActivePage $pageLogs $navLogs
    Start-ExecutionReport "Creation raccourcis"
    Write-Log "Creation des raccourcis"
    Create-AppShortcuts
    Show-ExecutionSummary "Creation raccourcis"
})
$btnRestore.Add_Click({
    Set-ActivePage $pageLogs $navLogs
    Start-ExecutionReport "Point de restauration"
    Write-Log "Gestion du point de restauration"
    Create-RestorePoint
    Show-ExecutionSummary "Point de restauration"
})
$btnAll.Add_Click({
    $plan = Show-RunAllConfirmationDialog
    if (-not $plan) { Write-Log "TOUT FAIRE annule par l utilisateur." "WARN"; return }
    Set-ActivePage $pageLogs $navLogs
    Start-ExecutionReport "TOUT FAIRE"
    Write-Log "=== DEMARRAGE TOUT FAIRE ==="
    Run-All -Plan $plan
})
$btnClearLogs.Add_Click({
    $Script:LogBox.Clear()
    $Script:lblStatus.Text = "Etat : logs vides"
    if ($Script:ProgressBar) { $Script:ProgressBar.Value = 0 }
    if ($Script:ProgressFill) { $Script:ProgressFill.Visible = $false; $Script:ProgressFill.Width = 0 }
})

# Home buttons
$homeButtons[0].Add_Click({ Set-ActivePage $pageInfo $navInfo; Show-PCInfo })
$homeButtons[1].Add_Click({ Set-ActivePage $pageApps $navApps })
$homeButtons[2].Add_Click({ Set-ActivePage $pageRun $navRun })
$homeButtons[3].Add_Click({ Set-ActivePage $pageOpt $navOpt })
$homeButtons[4].Add_Click({ Set-ActivePage $pageTools $navTools })
$homeButtons[5].Add_Click({
    $plan = Show-RunAllConfirmationDialog
    if (-not $plan) { return }
    Set-ActivePage $pageLogs $navLogs
    Start-ExecutionReport "TOUT FAIRE"
    Run-All -Plan $plan
})

# Drivers buttons
$btnAMD.Add_Click({    Start-Process "https://www.amd.com/en/support" })
$btnNVIDIA.Add_Click({ Start-Process "https://www.nvidia.com/Download/index.aspx" })
$btnIntel.Add_Click({  Start-Process "https://www.intel.com/content/www/us/en/download-center/home.html" })
$btnDDU.Add_Click({    Start-Process "https://www.wagnardsoft.com/display-driver-uninstaller-ddu" })
$btnOEM.Add_Click({
    $info = Get-PCInfo
    $vendor = $info."Fabricant"
    if ($vendor -match "ASUS")   { Start-Process "https://www.asus.com/support/" }
    elseif ($vendor -match "HP") { Start-Process "https://support.hp.com/" }
    elseif ($vendor -match "Lenovo") { Start-Process "https://support.lenovo.com/" }
    elseif ($vendor -match "Dell")   { Start-Process "https://www.dell.com/support/home/" }
    elseif ($vendor -match "Acer")   { Start-Process "https://www.acer.com/support" }
    elseif ($vendor -match "MSI")    { Start-Process "https://www.msi.com/support" }
    elseif ($vendor -match "Gigabyte") { Start-Process "https://www.gigabyte.com/Support" }
    else { Start-Process "https://www.google.com/search?q=$vendor+drivers+support" }
})

# =========================================================
# EVENEMENTS AUDIO
# =========================================================
$btnWelcomeNext.Add_Click({
    Load-AudioArtists -Style (Get-SelectedAudioStyle)
    Set-AudioView "Artists"
})
$btnArtistsNext.Add_Click({
    if ($Script:CurrentArtistPath) { Load-AudioAlbums -ArtistPath $Script:CurrentArtistPath } else { Load-AudioAlbums }
    Set-AudioView "Albums"
})
$btnAlbumsNext.Add_Click({
    if ($Script:CurrentAlbumPath) {
        Show-AudioAlbum -AlbumPath $Script:CurrentAlbumPath
    }
    else {
        Write-Log "Selectionne d abord un album ou double-clique sur une carte album." "WARN"
    }
})
$btnSongsNext.Add_Click({ Set-AudioView "Finish" })
$btnFinishRestart.Add_Click({ Reset-AudioState; Set-AudioView "Welcome" })

$Script:AudioStyleCombo.Add_SelectedIndexChanged({
    if ($Script:AudioStyleSyncing) { return }
    if ($Script:AudioStyleCombo.SelectedItem) {
        $styleName = $Script:AudioStyleCombo.SelectedItem.ToString()
        if ($Script:AudioSelectedStyleLabel) { $Script:AudioSelectedStyleLabel.Text = "Style : $styleName" }
        Sync-AudioStyleCombos -Value $styleName -SourceCombo $Script:AudioStyleCombo
        Refresh-AudioViewData
    }
})

$btnAudioPlay.Add_Click({ Play-SelectedAudioTrack })
$btnAudioPause.Add_Click({ Pause-AudioTrack })
$btnAudioStop.Add_Click({ Stop-AudioTrack })
$btnAudioPrev.Add_Click({ Previous-AudioTrack })
$btnAudioNext.Add_Click({ Next-AudioTrack })
$Script:AudioTrackList.Add_DoubleClick({ Play-SelectedAudioTrack })

# =========================================================
# ANIMATIONS : LOGO + NEON
# =========================================================
$logoTimer = New-Object System.Windows.Forms.Timer
$logoTimer.Interval = 60
$logoTimer.Add_Tick({
    $currentW = $logoBox.Width
    if ($currentW -ge ($Script:LogoBaseSize + 8)) { $Script:LogoPulseDirection = -1 }
    elseif ($currentW -le $Script:LogoBaseSize)   { $Script:LogoPulseDirection =  1 }
    $newSize = $currentW + $Script:LogoPulseDirection
    $logoBox.Size = New-Object System.Drawing.Size($newSize,$newSize)
    $cx = 25 + ([int](($Script:LogoBaseSize - $newSize) / 2))
    $cy = 20 + ([int](($Script:LogoBaseSize - $newSize) / 2))
    $logoBox.Location = [System.Drawing.Point]::new($cx,$cy)
})
$logoTimer.Start()

$neonTimer = New-Object System.Windows.Forms.Timer
$neonTimer.Interval = 70
$neonTimer.Add_Tick({
    $Script:NeonPulseStep++
    if ($Script:NeonPulseStep -gt 40) { $Script:NeonPulseStep = 0 }
    $phase  = $Script:NeonPulseStep
    $pulseA = [Math]::Min(40  + ($phase * 3), 120)
    $pulseB = [Math]::Min(70  + ($phase * 2), 150)
    $pulseC = [Math]::Min(95  + ($phase * 2), 180)

    if ($Script:WelcomeHeroCard) {
        $Script:WelcomeHeroCard.BackColor = [System.Drawing.Color]::FromArgb(28 + [Math]::Min($phase,18), 18, 58 + [Math]::Min($phase*2,45))
    }
    try { if ($welcomeOuterGlow) { $welcomeOuterGlow.BackColor = [System.Drawing.Color]::FromArgb(45 + [Math]::Min($phase,20), 30, 100 + [Math]::Min($phase*2,50)) } } catch {}
    try { if ($welcomeInnerGlow) { $welcomeInnerGlow.BackColor = [System.Drawing.Color]::FromArgb(70 + [Math]::Min($phase,25), 55, 155 + [Math]::Min($phase*2,55)) } } catch {}

    if ($Script:WelcomeStyleBadge) {
        $Script:WelcomeStyleBadge.BackColor = [System.Drawing.Color]::FromArgb($pulseC, 100, 255)
    }
    if ($Script:WelcomeComboHost) {
        $Script:WelcomeComboHost.BackColor = [System.Drawing.Color]::FromArgb(22 + [Math]::Min($phase,12), 16, 42 + [Math]::Min($phase,22))
    }
    if ($Script:AudioPageBadge) {
        $Script:AudioPageBadge.BackColor = [System.Drawing.Color]::FromArgb($pulseB, 90, 255)
        if ($Script:AudioPageBadge.Controls.Count -gt 0) {
            $Script:AudioPageBadge.Controls[0].BackColor = [System.Drawing.Color]::FromArgb($pulseC, 115, 255)
        }
    }
    foreach ($key in $Script:AudioNavButtons.Keys) {
        $navBtn = $Script:AudioNavButtons[$key]
        if ($navBtn.Font.Bold) {
            $navBtn.BackColor = [System.Drawing.Color]::FromArgb($pulseA, 70, 170)
        }
    }
})
$neonTimer.Start()

$form.Add_Shown({
    Update-ResponsiveLayout
    $startupTimer = New-Object System.Windows.Forms.Timer
    $startupTimer.Interval = 500
    $startupTimer.Add_Tick({
        $this.Stop()
        Play-StartupSound
    })
    $startupTimer.Start()
})
$form.Add_Resize({ Update-ResponsiveLayout })

# Nettoyage interface : module Audio Premium retire de l UI
try { if ($navAudio) { $navAudio.Visible = $false; $navAudio.Enabled = $false } } catch {}

# =========================================================
# DEMARRAGE
# =========================================================
Apply-UiIcons
Set-ActivePage $pageHome $navHome

Write-Log "============================================"
Write-Log "ClickByChris Setup Tool V5.0 Ultra Premium - Multi-PC Stage 2"
Write-Log "============================================"
Write-Log "Initialisation completee..."
Write-Log "Depot principal    : $Script:AppRoot"
Write-Log "Dossier admin      : $Script:AdminRoot"
Write-Log "Applications       : $($Script:AppsMap.Count) apps disponibles"
Write-Log "Compatibilite      : $($Script:RuntimeMap.Count) composants disponibles"
Write-Log "Navigation moderne + UI arrondie actives"
Write-Log "Son de demarrage active si un fichier audio est present"
Write-Log "Scan automatique au demarrage..."
Write-Log "============================================"

$envReport = Test-StartupEnvironment
Write-Log "Mode multi-PC       : actif"
Write-Log "Projet local        : $($envReport.ProjectRoot)"
Write-Log "PowerShell          : $($envReport.PowerShell)"
Write-Log "pwsh detecte        : $($envReport.PwshFound)"
Write-Log "winget detecte      : $($envReport.WingetFound)"
Write-Log "Admin               : $($envReport.IsAdmin)"
Write-Log "Assets detectes     : $($envReport.AssetsOk)"
Write-Log "Icones detectees    : $($envReport.IconsOk)"
Write-Log "Son startup detecte : $($envReport.StartupSoundOk)"

# Afficher les infos PC sans afficher les propriétés
Write-Log "Informations système chargées"
$null = Show-PCInfo  # Supprime l'output avec $null

Apply-ModernStyleRecursive -Root $form
Update-ResponsiveLayout

# ========== APPLIQUER LE RESPONSIVE SCALING ==========
Apply-ResponsiveScale -Form $form -Scale $Script:ResponsiveScale
# ===================================================

# Désactiver l'affichage accidentel des objets
$WarningPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'

# Afficher juste le message de démarrage
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  ClickByChris Setup Tool V1.0.0 - Interface en cours...   ║" -ForegroundColor Cyan
Write-Host "║                    Chargement complet                      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Lancer l'interface
[void]$form.ShowDialog()
