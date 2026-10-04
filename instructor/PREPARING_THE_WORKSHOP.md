# Preparing the Workshop Repo for One-Command Setup

This guide explains how the `AI_Grand_Prix` GitHub repo must be prepared so that students can run **one line** and get
every MCP server and skill for Google Antigravity:

```powershell
irm https://raw.githubusercontent.com/Rasoolpey/AI_Grand_Prix/main/setup.ps1 | iex
```

> **Key idea:** `setup.ps1` does **not** invent skills or configs. It
> 1. **copies** what is committed in the repo (workspaces, skills, instructions),
> 2. **installs** the MCP servers into a private `.tools\` folder, and
> 3. **merges** those servers into the global `%USERPROFILE%\.gemini\config\mcp_config.json` (keeping the student's own
>    servers, saving a `.bak` first).
>
> Why global: Antigravity loads MCP servers **only** from `~/.gemini/config/mcp_config.json` or from plugins. A workspace
> `.agents\mcp_config.json` is ignored (skills in `.agents\skills\` *are* per workspace). **Found by testing** on a lab-style
> PC (2026-10-04, VS Code extension 1.6.0), even though the extension's own README says a local `.agents/mcp_config.json`
> works. Don't move the servers back into the workspaces without re-testing. Nothing is written to PATH or
> environment variables. Outside the workshop folder there are only that MCP config and the Google Antigravity
> extension, added to the student's VS Code (per user, no admin).

---

## 1. Required repo layout

The script checks for these names, so keep them exactly as shown:

```
AI_Grand_Prix/                         <- repo root (branch: main)
├─ setup.ps1                           REQUIRED – the installer
├─ README.md                           optional – student guide (re-copied on every run, except in-place installs)
├─ remove-keys.ps1                     optional – wipes keys on shared PCs (re-copied on every run, except in-place)
│
├─ AI_Tools/                           REQUIRED – Part 1 workspace (research)
│  ├─ AGENTS.md                        always-on rules for the agent in this workspace
│  ├─ my_instructions.md, README.md, 1_topic/ … 6_report/
│  ├─ my_keys.env                      committed as an EMPTY template; setup fills the student's copy
│  └─ .agents/
│     └─ skills/
│        ├─ research-question/SKILL.md
│        ├─ literature-search/SKILL.md
│        ├─ literature-review/SKILL.md
│        ├─ research-figure/SKILL.md
│        └─ research-report/SKILL.md
│        (grill-me/ and grilling/ are downloaded by the script – do not commit)
│
├─ AI_Grand_Prix/                      REQUIRED – Part 2 workspace (the race); SAME NAME as the repo
│  ├─ AGENTS.md
│  ├─ practiceRace.m                   REQUIRED – used by the self-test
│  ├─ simulator/, student/, tracks/, garage.m, plotLap.m, submitCar.m …
│  └─ .agents/
│     └─ skills/
│        ├─ race-debrief/SKILL.md
│        └─ car-design-review/SKILL.md
│
└─ instructor/                         never copied to students
```

### How the script finds the files

| Where the student runs it | What happens |
|---|---|
| Inside the extracted ZIP folder (`AI_Grand_Prix-main\`, or one level above it) | **In-place install:** that folder becomes the workshop folder. It is detected because `setup.ps1`, `AI_Tools\` and `AI_Grand_Prix\` all exist there. |
| Anywhere else | Downloads `https://github.com/Rasoolpey/AI_Grand_Prix/archive/refs/heads/main.zip` and installs to `%USERPROFILE%\AI_Workshop` (or `$env:AIW_DIR`). |

Files a student already has are **never overwritten** (`Copy-Missing`), so re-running the script is safe.

---

## 2. Commit vs. generate

| Item | Who creates it | Commit it? |
|---|---|---|
| Workspace content (`AI_Tools\`, `AI_Grand_Prix\`) | You | ✅ Yes |
| `AGENTS.md` per workspace (always-on rules) | You | ✅ Yes |
| Your own skills: `<workspace>\.agents\skills\<name>\SKILL.md` | You | ✅ Yes |
| `grill-me`, `grilling` skills | Script (pinned commit of `mattpocock/skills`) | ❌ No |
| `.tools\` (uv, Python, MCP servers, logs) | Script | ❌ No |
| MCP server entries in `%USERPROFILE%\.gemini\config\mcp_config.json` | Script (absolute local paths, outside the repo) | ❌ No – never in the repo |
| Legacy `<workspace>\.agents\mcp_config.json` (+ `.bak`) | Older script versions; the current one deletes them | ❌ No – keep in `.gitignore` |
| `AI_Tools\my_keys.env` | You commit it as an **empty template**; setup fills the student's copy (asks for / finds the Scopus key) | ✅ Template only. With a real key **only on purpose** (a shared workshop key), and delete that key on the Elsevier portal afterwards |

The root `.gitignore` already covers the generated files: `.tools/`, both workspaces' `.agents/mcp_config.json` (+ `.bak`),
the downloaded `grill-me`/`grilling` skills, and `workshop_keys*`. Do **not** ignore `AI_Tools/my_keys.env`: the empty template
must be in the repo, because setup copies it to students.

---

## 3. Writing a skill

A skill is a folder containing a `SKILL.md` file. The YAML front matter is mandatory. The agent only sees `name` and
`description` until it decides to use the skill, so the description must say **what the skill does and when to use it**.

```markdown
---
name: race-debrief
description: Run a headless practice race in MATLAB, read the lap report, name the limiting factor and propose ONE improvement. Use when the student asks how the car is doing, why it is slow, crashing or running out of energy.
---

# Race debrief

1. Run this through the `matlab` MCP server (`evaluate_matlab_code`):
   ```matlab
   r = practiceRace('Path', "technical", 'Headless', true, 'Quiet', true);
   ```
2. Open `lapPlot.png` and ...
3. Name the limiting factor ...
```

Tips:
- Name the MCP server and tool explicitly (for example `matlab` → `evaluate_matlab_code`, `scopus`, `google-scholar`, `markitdown`).
- Use relative paths, or `fileparts(which(...))`, so the skill works in any install folder.
- Extra files (templates, scripts) can live next to `SKILL.md` in the same folder.
- Put a skill in the workspace where it is used: research skills in `AI_Tools`, race skills in `AI_Grand_Prix`.

**Adding a new skill does not require any change to `setup.ps1`.** Just commit the folder.

---

## 4. MCP servers installed by `setup.ps1`

| Server | Registered in | Source (pinned in `$Pins`) | Installed to |
|---|---|---|---|
| `matlab` | global `mcp_config.json` | `matlab/matlab-mcp-server` release `.exe` | `.tools\mcp\matlab\` |
| `google-scholar` | global `mcp_config.json` | `JackKuo666/Google-Scholar-MCP-Server` (source + wrapper `run_server.py`) | `.tools\mcp\google-scholar\` |
| `scopus` | global `mcp_config.json` | `JOSETRA44/scopus-mcp`, started via `run_with_keys.py` (loads `my_keys.env`) | `.tools\mcp\scopus\` |
| `markitdown` | global `mcp_config.json` | PyPI `markitdown-mcp` | `.tools\mcp\markitdown\` |

There is **one** `matlab` entry, with `--initial-working-folder` set to `AI_Grand_Prix\`, so `practiceRace`/`garage` are on
the MATLAB path for the race skills. Research work can `cd()` anywhere.

### Adding a new MCP server

Edit `setup.ps1` in three places:

1. **Pin the version** in `$Pins`. Never use "latest".
2. **Install it** (step 4/5):
   ```powershell
   # Python package from PyPI or a GitHub zip:
   $myVenv = Install-PyServer 'my-server' @('my-mcp-package==1.2.3')
   # or a standalone exe:
   Save-Url "https://github.com/<org>/<repo>/releases/download/<tag>/<file>.exe" (Join-Path $McpDir 'my-server\my-server.exe')
   ```
   If the server needs an API key, start it through `run_with_keys.py` (like `scopus`) and add the key name to `Write-KeysFile`.
3. **Register it** in step 7 (it is merged into the global `mcp_config.json`):
   ```powershell
   $servers['my-server'] = [ordered]@{
       command = "$myVenv\Scripts\my-mcp.exe"
       args    = @()
   }
   ```
4. *(Optional)* Add the name to the self-test loop in step 8 so the script checks that it answers `tools/list`.

`Merge-McpConfig` keeps any servers a student added themselves and saves a `.bak` before rewriting.

---

## 5. What the script does (steps 1–9)

| Step | Action |
|---|---|
| 1 | Finds MATLAB (registry, `Program Files`, PATH). Override with `$env:AIW_MATLAB_ROOT`. |
| 2 | In place (run inside the extracted ZIP): uses that folder as is. Otherwise copies `AI_Tools\` and `AI_Grand_Prix\` (from GitHub) into `AI_Workshop`. Creates a hidden `.tools\`. |
| 3 | Installs pinned `uv` and a private Python 3.12 inside `.tools\`. |
| 4 | Downloads the MATLAB MCP server. |
| 5 | Installs the Google Scholar, Scopus and MarkItDown servers (separate venvs). |
| 6 | Scopus key: from an environment variable, a `workshop_keys*` file (next to the ZIP, or in Downloads/Documents/Desktop), the existing `my_keys.env`, or a prompt. Tests the key, then writes `AI_Tools\my_keys.env`. |
| 7 | Merges the 4 servers into `%USERPROFILE%\.gemini\config\mcp_config.json` (or `$env:AIW_MCP_CONFIG`) and deletes any legacy `<workspace>\.agents\mcp_config.json`. Downloads the `grill-me` and `grilling` skills and appends the workshop's 10-question limit to `grilling`. |
| 8 | Self-test: talks MCP to each server; runs `practiceRace('Headless', true)` through MATLAB and expects `finished`, `totalTime` and `score` in the result. |
| 9 | Installs the `google.google-antigravity` VS Code extension and creates 2 desktop shortcuts (one per workspace). |

Optional switches (set before running):
`AIW_DIR`, `AIW_MATLAB_ROOT`, `AIW_SKIP_TEST=1`, `AIW_LOCAL_WORKSHOP`, `AIW_REPO_BRANCH`, `AIW_NO_SHORTCUTS=1`,
`AIW_NO_EXTENSION=1`, `AIW_LOG_DIR`, `AIW_KEYS_FILE`, `AIW_MCP_CONFIG`, `SCOPUS_API_KEY`, `SCOPUS_INST_TOKEN`.

**Sharing one Scopus key for the class:** give students a file called `workshop_keys.env` containing
`SCOPUS_API_KEY=...`. If it sits in Downloads, Documents, the Desktop or next to the ZIP, setup uses it without asking.

---

## 6. Students: open the right folder ⚠️

**MCP servers are global** (any folder, after a window reload). **Skills are per workspace**: Antigravity reads
`.agents\skills\` in the folder that is open in VS Code, not in its subfolders. So:

| Open this folder | You get |
|---|---|
| `AI_Grand_Prix-main\AI_Tools` | matlab, google-scholar, scopus, markitdown + the research skills |
| `AI_Grand_Prix-main\AI_Grand_Prix` | matlab, google-scholar, scopus, markitdown + race-debrief, car-design-review |
| `AI_Grand_Prix-main` (the parent) | the 4 MCP servers, but ❌ **no skills** |

Use the desktop shortcuts created in step 9, or **File > Open Folder** on one of the two part folders. Then check
**… (Additional Options) > MCP Servers** in the Antigravity panel to confirm that the servers are connected.

---

## 7. Pre-release checklist

- [ ] `setup.ps1`, `AI_Tools\` and `AI_Grand_Prix\` are at the repo root on `main`.
- [ ] Every skill folder has a `SKILL.md` with `name` and `description` front matter.
- [ ] No `mcp_config.json`, `.tools\`, `.venv\` or downloaded `grill-me`/`grilling` folder is committed; `AI_Tools\my_keys.env`
      is the empty template (or holds the shared workshop key only on purpose).
- [ ] `practiceRace('Headless', true)` runs headless and returns `finished`, `totalTime` and `score`.
- [ ] All `$Pins` versions/SHAs have been tested together.
- [ ] Clean test on a lab PC: download the ZIP → extract → run the one-liner inside `AI_Grand_Prix-main` → "ALL SET!".
- [ ] After setup, `%USERPROFILE%\.gemini\config\mcp_config.json` lists matlab, google-scholar, scopus, markitdown, and no
      `<workspace>\.agents\mcp_config.json` is left.
- [ ] Open `AI_Tools` in VS Code → the MCP Servers list shows 4 servers, and the skills are offered.
- [ ] Open `AI_Grand_Prix` → `matlab` is connected, and `race-debrief` works end to end.
- [ ] Local testing without pushing: `$env:AIW_LOCAL_WORKSHOP = "<path to repo>"` before running the script.

---

## 8. Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| No MCP servers in Antigravity | Antigravity was open during setup: reload the window (Ctrl+Shift+P → Reload Window), then check **… > MCP Servers**. Make sure `%USERPROFILE%\.gemini\config\mcp_config.json` lists the 4 servers (re-run setup if not). |
| No skills in Antigravity | The parent folder is open. Open `AI_Tools` or `AI_Grand_Prix` instead (section 6). |
| `matlab` fails to start | MATLAB is not licensed or signed in for this user: open MATLAB once, sign in, then re-run setup. Logs are in `.tools\log`. |
| MATLAB socket / path errors | The path is too long. The script falls back to `%LOCALAPPDATA%\AIW\log`; or set `$env:AIW_LOG_DIR` to a short path. |
| Scopus returns 401/403 | Wrong key, or off campus: add `SCOPUS_INST_TOKEN` or connect to the VPN. Edit `AI_Tools\my_keys.env`, then reload. |
| Python package build errors | Windows 260-character path limit. Install to a shorter `$env:AIW_DIR` (for example `C:\aiw`). |
