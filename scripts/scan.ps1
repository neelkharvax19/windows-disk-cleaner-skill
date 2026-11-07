[CmdletBinding()]
param(
    [string]$Drive = "C",
    [switch]$AsJson
)

function Get-FastFolderSize([string]$path) {
    if (-not (Test-Path $path)) { return 0 }
    $out = robocopy $path NULL /L /e /nfl /ndl /njh /bytes /r:0 /w:0 2>$null
    $match = $out | Select-String 'Bytes\s*:\s*(\d+)'
    if ($match -and $match.Matches.Groups[1].Value) {
        return [double]$match.Matches.Groups[1].Value
    }
    return 0
}

# 1. Drive Metrics
$vol = Get-Volume -DriveLetter $Drive -ErrorAction SilentlyContinue
if (-not $vol) {
    Write-Error "Drive $Drive not found."
    return
}

$totalGB = [math]::Round(($vol.Size / 1GB), 2)
$freeGB = [math]::Round(($vol.SizeRemaining / 1GB), 2)
$usedGB = [math]::Round((($vol.Size - $vol.SizeRemaining) / 1GB), 2)
$pctFree = [math]::Round((($vol.SizeRemaining / $vol.Size) * 100), 1)

# 2. Recycle Bin
$rb = (New-Object -ComObject Shell.Application).Namespace(0xA).Items() | Measure-Object -Property Size -Sum
$rbBytes = if ($rb.Sum) { [double]$rb.Sum } else { 0 }

# 3. Known Safe Locations (Category 1)
$safeTargets = @(
    @{ Name = "Recycle Bin"; Path = "RecycleBin"; Bytes = $rbBytes; Note = "Deleted user files pending permanent purge" },
    @{ Name = "User Temp Files"; Path = "$env:LOCALAPPDATA\Temp"; Bytes = (Get-FastFolderSize "$env:LOCALAPPDATA\Temp"); Note = "Temporary installer and application caches" },
    @{ Name = "CapCut Video Cache"; Path = "$env:LOCALAPPDATA\CapCut\User Data\Cache"; Bytes = (Get-FastFolderSize "$env:LOCALAPPDATA\CapCut\User Data\Cache"); Note = "Video proxy and render cache" },
    @{ Name = "Crash Dumps"; Path = "$env:LOCALAPPDATA\CrashDumps"; Bytes = (Get-FastFolderSize "$env:LOCALAPPDATA\CrashDumps"); Note = "Application crash memory dumps" },
    @{ Name = "pnpm Package Cache"; Path = "$env:LOCALAPPDATA\pnpm-cache"; Bytes = (Get-FastFolderSize "$env:LOCALAPPDATA\pnpm-cache"); Note = "Global pnpm dependency cache" },
    @{ Name = "Puppeteer Binaries Cache"; Path = "$env:USERPROFILE\.cache\puppeteer"; Bytes = (Get-FastFolderSize "$env:USERPROFILE\.cache\puppeteer"); Note = "Downloaded headless Chrome binaries" },
    @{ Name = "HuggingFace Model Cache"; Path = "$env:USERPROFILE\.cache\huggingface"; Bytes = (Get-FastFolderSize "$env:USERPROFILE\.cache\huggingface"); Note = "Cached AI model weights" },
    @{ Name = "Chroma Vector Cache"; Path = "$env:USERPROFILE\.cache\chroma"; Bytes = (Get-FastFolderSize "$env:USERPROFILE\.cache\chroma"); Note = "Vector database cache" },
    @{ Name = "Gemini/Antigravity Backup"; Path = "$env:USERPROFILE\.gemini\antigravity-backup"; Bytes = (Get-FastFolderSize "$env:USERPROFILE\.gemini\antigravity-backup"); Note = "Old IDE backup files" }
)

# 4. Review / Dev Environments (Category 2)
$reviewTargets = @(
    @{ Name = "Claude VM Bundles"; Path = "$env:LOCALAPPDATA\Claude-3p\vm_bundles"; Bytes = (Get-FastFolderSize "$env:LOCALAPPDATA\Claude-3p\vm_bundles"); Note = "Claude desktop virtual disk (rootfs.vhdx)" },
    @{ Name = "Android Emulator AVDs"; Path = "$env:USERPROFILE\.android\avd"; Bytes = (Get-FastFolderSize "$env:USERPROFILE\.android\avd"); Note = "Virtual smartphone system images" },
    @{ Name = "Ollama Local Models"; Path = "$env:USERPROFILE\.ollama\models"; Bytes = (Get-FastFolderSize "$env:USERPROFILE\.ollama\models"); Note = "Locally downloaded Ollama LLMs" }
)

# Detect old WPS Office leftover versions
$wpsDir = "$env:LOCALAPPDATA\Kingsoft\WPS Office"
if (Test-Path $wpsDir) {
    $versions = Get-ChildItem $wpsDir -Directory | Where-Object { $_.Name -match '^\d+\.\d+' } | Sort-Object Name -Descending
    if ($versions.Count -gt 1) {
        # Old versions besides the newest
        $oldVersions = $versions | Select-Object -Skip 1
        foreach ($ov in $oldVersions) {
            $bytes = Get-FastFolderSize $ov.FullName
            $reviewTargets += @{
                Name = "Old WPS Version ($($ov.Name))"
                Path = $ov.FullName
                Bytes = $bytes
                Note = "Older build left behind after an update (Active: $($versions[0].Name))"
            }
        }
    }
}

# Detect old Node.js versions in nvm
$nvmDir = "$env:LOCALAPPDATA\nvm"
if (Test-Path $nvmDir) {
    $currentActive = (node -v 2>$null)
    $nvmVersions = Get-ChildItem $nvmDir -Directory | Where-Object { $_.Name -match '^v\d+' }
    foreach ($nv in $nvmVersions) {
        if ($currentActive -and $nv.Name -ne $currentActive) {
            $bytes = Get-FastFolderSize $nv.FullName
            if ($bytes -gt 100MB) {
                $reviewTargets += @{
                    Name = "NVM Inactive Node ($($nv.Name))"
                    Path = $nv.FullName
                    Bytes = $bytes
                    Note = "Inactive Node.js runtime and global node_modules"
                }
            }
        }
    }
}

# Format results
function Format-ListItems($items) {
    return $items | Where-Object { $_.Bytes -gt 1MB } | ForEach-Object {
        [PSCustomObject]@{
            Name     = $_.Name
            Size_MB  = [math]::Round(($_.Bytes / 1MB), 2)
            Size_GB  = [math]::Round(($_.Bytes / 1GB), 2)
            Location = $_.Path
            Note     = $_.Note
        }
    } | Sort-Object Size_MB -Descending
}

$safeReport = Format-ListItems $safeTargets
$reviewReport = Format-ListItems $reviewTargets

$totalSafeGB = [math]::Round((($safeTargets | ForEach-Object { [double]$_.Bytes } | Measure-Object -Sum).Sum / 1GB), 2)
$totalReviewGB = [math]::Round((($reviewTargets | ForEach-Object { [double]$_.Bytes } | Measure-Object -Sum).Sum / 1GB), 2)

$data = [PSCustomObject]@{
    Drive = @{
        Letter       = $Drive
        Total_GB     = $totalGB
        Used_GB      = $usedGB
        Free_GB      = $freeGB
        Percent_Free = $pctFree
    }
    Category1_SafeJunk = @{
        Total_Cleanable_GB = $totalSafeGB
        Items              = $safeReport
    }
    Category2_ReviewRequired = @{
        Total_Cleanable_GB = $totalReviewGB
        Items              = $reviewReport
    }
}

if ($AsJson) {
    $data | ConvertTo-Json -Depth 5
} else {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host " Windows Disk Cleanup Scanner (Drive ${Drive}:)" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Total: $totalGB GB | Used: $usedGB GB | Free: $freeGB GB ($pctFree% free)"
    Write-Host ""
    Write-Host "--- Category 1: Safe To Clean (~$totalSafeGB GB) ---" -ForegroundColor Green
    if ($safeReport) {
        $safeReport | Format-Table Name, Size_GB, Note -AutoSize
    } else {
        Write-Host "No significant junk found in Category 1."
    }

    Write-Host "--- Category 2: Review Before Deleting (~$totalReviewGB GB) ---" -ForegroundColor Yellow
    if ($reviewReport) {
        $reviewReport | Format-Table Name, Size_GB, Note -AutoSize
    } else {
        Write-Host "No dev/VM environments detected."
    }
}
