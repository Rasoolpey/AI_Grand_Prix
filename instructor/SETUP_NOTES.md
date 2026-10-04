# Setup notes (instructor)

Students follow the workshop [README.md](../README.md). This page covers what `setup.ps1` does, so you can support students.

## MATLAB requirements and installation checks

- Students need installed, licensed **base MATLAB**. No Simulink, Control System Toolbox, Robotics System Toolbox,
  Statistics and Machine Learning Toolbox, or separately installed MATLAB add-on is required by the current race code.
  MATLAB Copilot is optional.
- **Parallel Computing Toolbox is optional for the instructor**: it speeds up `balanceSweep`. Without it, the `parfor`
  loop runs serially. Qualification uses separate MATLAB processes rather than a parallel pool.
- The installer selects the newest installed MATLAB, or the folder specified by `AIW_MATLAB_ROOT`.
  Its MCP self-test uses the current simulator's `finished`, `totalTime`, and `score` result fields.
- Verified on this machine on **2026-10-03**, MATLAB **R2026b**, with only MATLAB and MATLAB Copilot installed:
  **24/24 physics and rule tests passed**; all three student baseline paths finished with zero penalties
  (drag 22.37 s, technical 54.00 s, endurance 278.28 s; overall 47.70).
  The endurance practice path uses a **360 s simulated-time limit**, leaving the baseline about 82 s of margin.
  Garage, lap-report and race-HUD figures rendered; a one-design, three-path balance sweep completed without
  Parallel Computing Toolbox. Dependency analysis reported MATLAB only; the runtime checks provide additional evidence
  because dependency analysis can miss dynamically selected functions or unavailable products.
- The pinned **MATLAB MCP server v0.14.0** was tested separately against R2026b: five tools were offered and the
  technical baseline finished in 54.00 s through `evaluate_matlab_code`. The local per-project configs point explicitly
  to R2026b. Loading those configs in the VS Code Antigravity extension still needs a check on a lab PC.

To repeat the installation check from the repository root in MATLAB:

```matlab
addpath('instructor/race/tests');
report = checkInstallation();
```

To install/check only the MATLAB MCP connection and update the two local project configs, from PowerShell at the repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\instructor\check-matlab-connection.ps1 -MatlabRoot "C:\Program Files\MATLAB\R2026b"
```

The process-only execution-policy setting leaves the system policy unchanged. The connection script reuses the installer's
protocol client, preserves other configured MCP servers, and writes only inside this workshop. It does not install the
Scholar, Scopus or MarkItDown servers. Results, logs and figure checks are in the git-ignored `.tools/log/` folder.

## Figure (Part 1): PaperViz as a skill, no key

`AI_Tools\.agents\skills\research-figure\` runs PaperViz (Google Research's PaperVizAgent, github.com/google-research/papervizagent)
inside the agent: Planner → Stylist → Visualizer → Critic (≤ 2 rounds), with PaperViz's own prompts (`prompts.md`) and diagram style
guide (`style_guide.md`), copied unchanged under Apache-2.0 (`LICENSE-PaperViz.txt`). The agent draws with **Antigravity's built-in
image generation** (Nano Banana Pro, included with the student's Antigravity sign-in): no API key, no server, no cost to us.
Running PaperViz's own code instead would need a Gemini API key with billing: Google lists no free API tier for any image model.

**To verify on a lab PC:** that the VS Code Antigravity extension offers image generation like the Antigravity app does, and that the
agent can save the image into `5_proposal\figure\`.

## Shared workshop key (students sign up for nothing)

Students get the Scopus key from one file you share on the day: **`workshop_keys.env`** (Teams / course page / USB). They save it in
Downloads; `setup.ps1` looks next to the extracted zip, in Downloads, Documents and on the Desktop (also `workshop_keys (1).env`
etc.), copies the key into each student's `AI_Tools\my_keys.env` and asks no key question. Order: environment variable, then the
workshop file, then what `my_keys.env` already has, then a prompt. Re-running setup with a new file updates the key.

Make the file **outside the repo** (`workshop_keys*` is git-ignored anyway; the repo is public):
```
# AI Workshop shared key - delete it after the workshop
SCOPUS_API_KEY=<Elsevier key, dev.elsevier.com>
SCOPUS_INST_TOKEN=
```
One key for the class shares Elsevier's quota (20,000 searches/week, 9 requests/s); check that sharing it in a class is fine under
your library's Elsevier agreement. On campus no institution token is needed. Delete the key after the workshop.

## Distribution
- **One repo**, `github.com/Rasoolpey/AI_Grand_Prix` (public), mirrors this folder: `README.md`, `setup.ps1`, `remove-keys.ps1`,
  `AI_Tools/` (Part 1), `AI_Grand_Prix/` (Part 2) and `instructor/`.
- **Student flow (lab PCs have no git):** download the repo ZIP, extract it into Documents, open a terminal in
  `Documents\AI_Grand_Prix-main` and run the command below. Run inside the extracted folder, `setup.ps1` installs **in place**:
  that folder is the workshop folder (its `instructor/` is simply ignored). Run anywhere else, it downloads one zip of `main` and
  copies only `README.md`, `remove-keys.ps1`, `AI_Tools/` and `AI_Grand_Prix/` into `%USERPROFILE%\AI_Workshop`.
- `instructor/TODO_WORKSHOP.md` and `instructor/TODO_RACE.md` are git-ignored: they stay on this machine only.
- Student command: `irm https://raw.githubusercontent.com/Rasoolpey/AI_Grand_Prix/main/setup.ps1 | iex`

## What a student gets
```
Documents\AI_Grand_Prix-main\   (in place; otherwise %USERPROFILE%\AI_Workshop\)
  README.md · remove-keys.ps1
  AI_Tools\        my_keys.env (Scopus key) · my_instructions.md (student overrides) · AGENTS.md (defaults)
                   1_topic\ … 6_report\ (fixed result folders, pre-filled templates)
                   .agents\skills\ (research-question, grill-me, grilling, literature-search, literature-review, research-figure, research-report)
  AI_Grand_Prix\   .agents\skills\ (race-debrief, car-design-review)
  .tools\ (hidden) uv 0.12.22 · Python 3.12 · MCP servers (matlab v0.14.0, Scholar @738d60a, Scopus @4968cc6, markitdown 0.0.1a7) · log\
%USERPROFILE%\.gemini\config\mcp_config.json   matlab, google-scholar, scopus, markitdown (merged in; other servers kept, .bak saved)
```
**MCP servers are global** (Antigravity ignored a workspace `.agents\mcp_config.json` in our tests); **skills are per workspace**.
No user environment variables, no PATH change. Uninstall = delete the workshop folder + the two desktop shortcuts, and remove the
4 entries from that `mcp_config.json`.
**Keys** live in `AI_Tools\my_keys.env`, inside the Part 1 workspace so students see it in VS Code's file list. The Scopus server
is started through `.tools\mcp\run_with_keys.py`, which loads that file at start-up, so a changed key takes effect after reloading the VS Code window.

## Options (set before running)
| Variable | Effect |
|---|---|
| `AIW_DIR` | Workshop folder (default: the extracted folder when run inside it, else `%USERPROFILE%\AI_Workshop`; use a short path like `C:\AIW` for very long usernames) |
| `AIW_MATLAB_ROOT` | Force a MATLAB install (default: the newest found) |
| `AIW_SKIP_TEST=1` | Skip the self-test (it starts MATLAB and drives a baseline lap, about 1–3 min) |
| `AIW_NO_SHORTCUTS=1` | No desktop shortcuts |
| `AIW_LOCAL_WORKSHOP` | Copy `AI_Tools` + `AI_Grand_Prix` from a local copy of this repo instead of GitHub (testing, USB install) |
| `AIW_REPO_BRANCH` | Branch to download (default `main`) |
| `SCOPUS_API_KEY`, `SCOPUS_INST_TOKEN` | Written to `AI_Tools\my_keys.env` without prompting |

## Troubleshooting (beyond the student README)
- Logs: `<workshop>\.tools\log` (MATLAB MCP server). If that path is longer than 70 characters (nested zip, long user name,
  OneDrive Documents), setup uses `%LOCALAPPDATA%\AIW\log` instead: the MATLAB server puts a socket there, and Windows caps socket
  paths at ~108 characters ("socket path is too long" in the server log).
- Lab IT blocking executables: allow `<workshop>\.tools\**`, or set `AIW_DIR` to an allowed location.
- Python servers are pinned on purpose: Scholar/Scopus need `mcp<2` (FastMCP); Scholar needs `bibtexparser<2`; MarkItDown needs `mcp>=2.1.1`.
