[CmdletBinding()]
param(
    [string]$TargetDrive
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Windows Drive Cache Redirection Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Auto-detect target drive if not specified
if (-not $TargetDrive) {
    $candidates = Get-Volume | Where-Object { 
        $_.DriveLetter -and $_.DriveLetter -ne 'C' -and $_.DriveType -eq 'Fixed' -and $_.FileSystemType -eq 'NTFS' 
    } | Sort-Object SizeRemaining -Descending

    if ($candidates) {
        $TargetDrive = $candidates[0].DriveLetter
        Write-Host "[i] Auto-selected Drive ${TargetDrive}: ($([math]::Round($candidates[0].SizeRemaining/1GB, 1)) GB free)" -ForegroundColor Green
    } else {
        Write-Error "No secondary NTFS fixed drive found. Please specify -TargetDrive manually (e.g. -TargetDrive D)."
        return
    }
}

$vol = Get-Volume -DriveLetter $TargetDrive -ErrorAction SilentlyContinue
if (-not $vol) {
    Write-Error "Target drive ${TargetDrive}: not found."
    return
}

# 1. CapCut Junction
Write-Host "`n[1/3] Setting up CapCut Cache redirection..." -ForegroundColor Yellow
$capcutTarget = "${TargetDrive}:\CapCut_Cache"
$capcutLink = "$env:LOCALAPPDATA\CapCut\User Data\Cache"

if (-not (Test-Path $capcutTarget)) {
    New-Item -ItemType Directory -Path $capcutTarget -Force | Out-Null
}

if (Test-Path $capcutLink) {
    $item = Get-Item $capcutLink -Force
    $isJunction = $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint
    if (-not $isJunction) {
        # Move any existing contents or remove empty folder
        Remove-Item -Path $capcutLink -Force -Recurse -ErrorAction SilentlyContinue
        cmd /c "mklink /J `"$capcutLink`" `"$capcutTarget`""
        Write-Host "      Redirected CapCut Cache -> $capcutTarget" -ForegroundColor Green
    } else {
        Write-Host "      CapCut Cache is already redirected." -ForegroundColor Cyan
    }
} else {
    $parent = Split-Path $capcutLink -Parent
    if (Test-Path $parent) {
        cmd /c "mklink /J `"$capcutLink`" `"$capcutTarget`""
        Write-Host "      Redirected CapCut Cache -> $capcutTarget" -ForegroundColor Green
    }
}

# 2. pnpm Store
Write-Host "`n[2/3] Setting up pnpm package store redirection..." -ForegroundColor Yellow
if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    $pnpmTarget = "${TargetDrive}:\pnpm-store"
    pnpm config set store-dir "$pnpmTarget" | Out-Null
    Write-Host "      pnpm store-dir set to $pnpmTarget" -ForegroundColor Green
} else {
    Write-Host "      pnpm is not installed on this system. Skipping." -ForegroundColor DarkGray
}

# 3. AI & Developer Environment Variables
Write-Host "`n[3/3] Setting persistent User Environment Variables..." -ForegroundColor Yellow
$envVars = @{
    "HF_HOME"             = "${TargetDrive}:\.cache\huggingface"
    "OLLAMA_MODELS"       = "${TargetDrive}:\.ollama\models"
    "PIP_CACHE_DIR"       = "${TargetDrive}:\.cache\pip"
    "PUPPETEER_CACHE_DIR" = "${TargetDrive}:\.cache\puppeteer"
}

foreach ($entry in $envVars.GetEnumerator()) {
    $dir = $entry.Value
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    [System.Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, [System.EnvironmentVariableTarget]::User)
    Write-Host "      $($entry.Key) -> $($entry.Value)" -ForegroundColor Green
}

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host " Setup Complete!" -ForegroundColor Green
Write-Host " Heavy video and AI caches are now routed to Drive ${TargetDrive}:." -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan

