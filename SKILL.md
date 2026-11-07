---
name: windows-disk-cleaner
description: Diagnoses, safely frees, and prevents disk space bloat on Windows drives (especially C:). Safely cleans app and developer caches (CapCut, Temp, Recycle Bin, pnpm, crash dumps), audits heavy dev environments (VMs, emulators, local models), and redirects future caches to a secondary drive.
---

# Windows Disk Cleaner & Cache Manager

A universal AI Agent Skill to analyze, clean, and permanently optimize disk usage on Windows systems.

## When to Activate This Skill
- The user reports running out of disk space on their `C:` drive (or any drive).
- The system is experiencing slowdowns due to low drive capacity.
- The user wants to find out where hidden space is being consumed (e.g., CapCut, dev packages, LLM weights, virtual disks).
- The user wants to prevent `C:` from filling up again by redirecting caches to another partition (`D:`, `E:`, etc.).

---

## Safety Principles (Crucial)
1. **Never delete user documents or project files.**
2. **Always separate findings into two categories:**
   - **Category 1 (Safe Junk):** Recycle Bin, temporary files, video editor render caches (CapCut), package manager store caches (pnpm), and crash dumps.
   - **Category 2 (Review Required):** Active or inactive virtual machines (Claude VM rootfs, Android emulators), locally downloaded AI models (Ollama/HuggingFace), and older installed application versions (WPS Office, inactive Node runtimes).
3. **Always ask for user confirmation before executing deletions on Category 2 items.**
4. **Respect explicit user exclusions** (e.g. "don't touch WPS Office").

---

## Workflow Instructions for AI Models

### Step 1: Analyze Disk Usage
Run the bundled PowerShell scanner script:
```powershell
powershell -ExecutionPolicy Bypass -File "./scripts/scan.ps1" -AsJson
```
Or view human-readable table:
```powershell
powershell -ExecutionPolicy Bypass -File "./scripts/scan.ps1"
```

The script performs lightning-fast robocopy byte-level calculations across common Windows bloatware locations.

### Step 2: Present Findings to User
Summarize the current drive status:
- Total capacity, current free space, and percentage free.
- **Category 1 (Safe Junk):** Items that can be purged immediately with zero impact.
- **Category 2 (Review Required):** Large environments (AVDs, VM disks, local models) that require user consent.

### Step 3: Execute Cleanup
Once the user confirms their selection, run the cleanup script:
- To clean **Safe Junk only** (preserving WPS Office by default):
  ```powershell
  powershell -ExecutionPolicy Bypass -File "./scripts/clean.ps1" -SafeOnly
  ```
- To clean specific Category 2 items approved by the user:
  ```powershell
  powershell -ExecutionPolicy Bypass -File "./scripts/clean.ps1" -CleanAndroidAVD -CleanOllamaModels -CleanNvmVersion "v22.12.0"
  ```
- To simulate before deleting (dry-run):
  ```powershell
  powershell -ExecutionPolicy Bypass -File "./scripts/clean.ps1" -WhatIf
  ```

### Step 4: Prevent Future Space Exhaustion
If the system has a secondary drive (e.g., `D:` or `E:`), offer to redirect heavy caches:
```powershell
powershell -ExecutionPolicy Bypass -File "./scripts/redirect.ps1" -TargetDrive "E"
```
This automatically:
1. Creates an NTFS **Directory Junction** (`mklink /J`) for CapCut's cache folder so future video edits save on the secondary drive.
2. Moves the `pnpm` global store to the secondary drive.
3. Sets persistent user environment variables (`HF_HOME`, `OLLAMA_MODELS`, `PIP_CACHE_DIR`, `PUPPETEER_CACHE_DIR`) to point to the secondary drive.

