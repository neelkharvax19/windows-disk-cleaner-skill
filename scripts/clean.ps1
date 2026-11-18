[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$SafeOnly,
    [switch]$CleanOldWPS,
    [switch]$CleanChromeAIModel,
    [switch]$CleanClaudeVM,
    [switch]$CleanAndroidAVD,
    [switch]$CleanOllamaModels,
    [string]$CleanNvmVersion
)

$beforeVol = Get-Volume -DriveLetter C
$beforeBytes = $beforeVol.SizeRemaining

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Windows Disk Cleaner Execution" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

function Remove-PathSafe([string]$path, [string]$description) {
    if (-not (Test-Path $path)) { return }
    Write-Host "[+] Cleaning ${description}: $path" -ForegroundColor Yellow
    if ($WhatIf) {
        Write-Host "    [WhatIf] Would remove $path" -ForegroundColor DarkGray
        return
    }
    try {
        Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        # If it's a specific file or folder itself
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "    Warning: Could not remove some files in $path ($($_))" -ForegroundColor Red
    }
}

# --- Category 1: Safe Junk ---
Write-Host "`n--- Cleaning Safe Junk (Category 1) ---" -ForegroundColor Green

# 1. Recycle Bin
Write-Host "[+] Emptying Recycle Bin..." -ForegroundColor Yellow
if (-not $WhatIf) {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "    [WhatIf] Would empty Recycle Bin" -ForegroundColor DarkGray
}

# 2. Temp directory
Write-Host "[+] Cleaning User Temp Files..." -ForegroundColor Yellow
if (-not $WhatIf) {
    $tempFiles = Get-ChildItem -Path $env:TEMP -Force -ErrorAction SilentlyContinue
    foreach ($f in $tempFiles) {
        Remove-Item -Path $f.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "    [WhatIf] Would delete contents of $env:TEMP" -ForegroundColor DarkGray
}

# 3. CapCut Cache (if not already junctioned)
$capcutCache = "$env:LOCALAPPDATA\CapCut\User Data\Cache"
$isJunction = (Get-Item $capcutCache -Force -ErrorAction SilentlyContinue).Attributes -band [System.IO.FileAttributes]::ReparsePoint
if (Test-Path $capcutCache) {
    if (-not $isJunction) {
        Remove-PathSafe $capcutCache "CapCut Video Cache"
    } else {
        Write-Host "[i] CapCut Cache is safely redirected to secondary drive (junction active)." -ForegroundColor Cyan
    }
}

# 4. pnpm Cache
Remove-PathSafe "$env:LOCALAPPDATA\pnpm-cache" "pnpm Cache"

# 5. Dev caches
Remove-PathSafe "$env:USERPROFILE\.cache\puppeteer" "Puppeteer Browser Cache"
Remove-PathSafe "$env:USERPROFILE\.cache\huggingface" "HuggingFace Model Cache"
Remove-PathSafe "$env:USERPROFILE\.cache\chroma" "Chroma Vector Cache"
Remove-PathSafe "$env:USERPROFILE\.gemini\antigravity-backup" "Gemini IDE Backup"

# 6. Crash dumps
Remove-PathSafe "$env:LOCALAPPDATA\CrashDumps" "Windows Crash Dumps"

# 7. Package and updater caches
Remove-PathSafe "$env:USERPROFILE\.npm-cache" "Global npm Cache"
Remove-PathSafe "$env:LOCALAPPDATA\Ollama\updates_v2" "Ollama Stale Updates"

# --- Category 2: Optional Developer Items ---
if (-not $SafeOnly) {
    Write-Host "`n--- Optional Items (Category 2) ---" -ForegroundColor Green

    # Chrome On-Device AI Model
    if ($CleanChromeAIModel) {
        Remove-PathSafe "$env:LOCALAPPDATA\Google\Chrome\User Data\OptGuideOnDeviceModel" "Chrome On-Device AI Model (Gemini Nano)"
    }

    # Claude VM
    if ($CleanClaudeVM) {
        Remove-PathSafe "$env:LOCALAPPDATA\Claude-3p\vm_bundles" "Claude VM Bundles (rootfs.vhdx)"
    }

    # Android AVDs
    if ($CleanAndroidAVD) {
        Remove-PathSafe "$env:USERPROFILE\.android\avd" "Android Emulator AVDs"
    }

    # Ollama Models
    if ($CleanOllamaModels) {
        Remove-PathSafe "$env:USERPROFILE\.ollama\models" "Ollama Local Models"
    }

    # Inactive NVM version
    if ($CleanNvmVersion) {
        $nvmTarget = "$env:LOCALAPPDATA\nvm\$CleanNvmVersion"
        if (Test-Path $nvmTarget) {
            Remove-PathSafe $nvmTarget "NVM Inactive Node Version ($CleanNvmVersion)"
        }
    }

    # WPS Office handling (Clean older unused versions only)
    if ($CleanOldWPS) {
        $wpsDir = "$env:LOCALAPPDATA\Kingsoft\WPS Office"
        if (Test-Path $wpsDir) {
            $versions = Get-ChildItem $wpsDir -Directory | Where-Object { $_.Name -match '^\d+\.\d+' } | Sort-Object Name -Descending
            if ($versions.Count -gt 1) {
                $oldVersions = $versions | Select-Object -Skip 1
                foreach ($ov in $oldVersions) {
                    Remove-PathSafe $ov.FullName "Old WPS Office Version ($($ov.Name))"
                }
            }
        }
    }
}

$afterVol = Get-Volume -DriveLetter C
$afterBytes = $afterVol.SizeRemaining
$freedGB = [math]::Round((($afterBytes - $beforeBytes) / 1GB), 2)
$currentFreeGB = [math]::Round(($afterBytes / 1GB), 2)

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host " Cleanup Finished" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
if ($WhatIf) {
    Write-Host "[WhatIf Mode] No files were deleted." -ForegroundColor DarkGray
} else {
    Write-Host "Space Freed: $freedGB GB" -ForegroundColor Green
    Write-Host "Current Free Space on C: $currentFreeGB GB" -ForegroundColor Green
}
