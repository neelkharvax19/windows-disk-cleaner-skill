# 🧹 Windows Disk Cleaner & Cache Manager (AI Skill & CLI)

> **Free, open-source skill for any AI model or human to analyze, safely clean, and permanently prevent C: drive disk bloat on Windows.**

Compatible with **Google Antigravity**, **Claude Code**, **Cursor**, **Windsurf**, **GitHub Copilot**, **Cline**, **ChatGPT**, or as a **standalone PowerShell tool**.

---

## 🌟 Features

- ⚡ **Lightning Fast Scanner:** Uses multi-threaded Robocopy byte counting to scan dozens of gigabytes in seconds.
- 🛡️ **Categorized Safety:**
  - **Category 1 (Safe Junk):** Recycle Bin, User Temp, CapCut video proxy caches, pnpm cache, dev tool caches, crash dumps.
  - **Category 2 (Review Required):** Android AVD emulators, Claude desktop VM bundles (`rootfs.vhdx`), local Ollama models, stale app builds (WPS Office, inactive Node runtimes).
- 🔒 **Safe By Default:** Includes `-WhatIf` dry-run simulation mode and never deletes without consent.
- 🔀 **Permanent Redirection:** Automatically creates NTFS **Directory Junctions** and sets environment variables (`HF_HOME`, `PIP_CACHE_DIR`, `OLLAMA_MODELS`, `pnpm store-dir`) so apps write to `D:` or `E:` instead of re-bloating `C:`.

---

## 🚀 How to Install & Use With Any AI Model

### 1. Google Antigravity / Gemini CLI
Copy the skill folder into your workspace or global skills directory:
- **Project Scope:** Copy `windows-disk-cleaner-skill` to `.agents/skills/windows-disk-cleaner`
- **Global Scope:** Copy to `~/.gemini/skills/windows-disk-cleaner`

Whenever you ask Antigravity *"cleanup my C drive"* or *"why is my disk full"*, it will automatically load and run the skill!

---

### 2. Claude Code
Install as a skill in Claude Code:
```bash
# Add to your global Claude skills directory:
cp -r windows-disk-cleaner-skill ~/.claude/skills/windows-disk-cleaner
```
Or simply prompt Claude Code in the folder:
> *"Run the windows-disk-cleaner skill to scan and optimize my C drive."*

---

### 3. Cursor / Windsurf / GitHub Copilot / Cline
Add the skill to your project's agent rules:
- **Cursor:** Copy `SKILL.md` into your `.cursorrules` or `.cursor/rules/`
- **GitHub Copilot / VS Code:** Reference `SKILL.md` in `.github/copilot-instructions.md`
- **Cline:** Add the folder path into your custom instructions or prompt Cline to read `SKILL.md`.

---

### 4. ChatGPT / Custom GPTs / Open WebUI
1. In your Custom GPT or System Prompt, upload `SKILL.md`.
2. Give the AI access to Code Interpreter or terminal execution.
3. The AI will follow the standardized instructions in `SKILL.md` to guide you or execute the commands.

---

### 5. Standalone (No AI Needed - Run Directly in PowerShell)
You can run the bundled scripts directly in Windows PowerShell without any AI assistant:

#### Step 1: Scan
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\scan.ps1
```

#### Step 2: Clean Safe Junk
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\clean.ps1 -SafeOnly
```

#### Step 3: Redirect Caches to Secondary Drive (e.g. E: or D:)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\redirect.ps1 -TargetDrive "E"
```

---

## 📂 Repository Structure

```
windows-disk-cleaner-skill/
├── SKILL.md              # Universal Agent Skill definition (YAML frontmatter + AI instructions)
├── README.md             # Documentation & installation guide for all AI models
├── LICENSE               # Free & Open Source (MIT License)
└── scripts/
    ├── scan.ps1          # Fast disk scanner with JSON/Table outputs
    ├── clean.ps1         # Safe cleaner with Category 1 & 2 toggles and -WhatIf mode
    └── redirect.ps1      # Automatic Directory Junction & env var redirector
```

---

## 📄 License
MIT License — Free to use, modify, distribute, and share with anyone.

