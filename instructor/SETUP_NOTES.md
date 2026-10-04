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

## Figure tools (Part 1, research-figure skill)

Neither tool ships an MCP server, so `setup.ps1` writes one for each into `.tools\mcp\<name>\server.py` (the Python is
embedded in `setup.ps1`, like the Scholar wrapper) and registers them in `AI_Tools\.agents\mcp_config.json`. Both save into
`AI_Tools\5_proposal\figure\`, never overwrite a file, and re-read `my_keys.env` on every call (no restart after pasting a key).

| | SciDraw AI (`scidraw`) | PaperViz (`paperviz`) |
|---|---|---|
| What | Official REST API, `https://sci-draw.com/api/v1` (`images/generations`, `jobs`, `credits`) | Google Research's PaperVizAgent @e088a8f: Planner → Visualizer → Critic, run in-process |
| Key | `SCIDRAW_API_KEY` (sci-draw.com → Settings → API Keys, `sd_…`) | `GOOGLE_API_KEY` (aistudio.google.com/apikey) |
| Cost | Free plan: 10 credits at sign-up + 5/day; 2K image = 5, 4K = 20 | Gemini API quota; the image model may need billing on the AI Studio project |
| Tools | `scidraw_generate_figure`, `scidraw_check_job`, `scidraw_credits` | `paperviz_generate_diagram`, `paperviz_check_job`, `paperviz_check_setup` |

PaperViz adaptations in the wrapper (Google's code untouched): prints to stderr (stdout is the MCP channel), `time.tzset` no-op on
Windows, Gemini client forced onto the API key (upstream tries Google Cloud credentials first), empty `ref.json` so it runs without
the PaperBananaBench dataset, Anthropic/OpenAI SDKs stubbed (Gemini only; the Anthropic SDK also has file paths over Windows'
260-character limit), and a key/model check before each run (a wrong key fails in seconds instead of after minutes of retries).
Models: `gemini-3-pro-preview` + `gemini-3-pro-image-preview`, changeable with `PAPERVIZ_MODEL` / `PAPERVIZ_IMAGE_MODEL`.

**Tested 2026-10-04 without real keys:** both servers install with the pinned versions, start over MCP, list 3 tools each, reach
the real APIs and turn a missing/invalid key into a clear instruction. **Not yet tested:** an actual figure from either tool
(needs a SciDraw key and a Gemini key with image-model access).

## Shared workshop keys (students sign up for nothing)

Students get every key from one file you share on the day: **`workshop_keys.env`** (Teams / course page / USB). They save it in
Downloads; `setup.ps1` looks next to the extracted zip, in Downloads, Documents and on the Desktop (also `workshop_keys (1).env`
etc.), copies the keys into each student's `AI_Tools\my_keys.env` and asks no key questions. Order per key: environment variable,
then the workshop file, then what `my_keys.env` already has, then a prompt. Re-running setup with a new file updates the keys.

Make the file **outside the repo** (`workshop_keys*` is git-ignored anyway; the repo is public and Google disables leaked keys):
```
# AI Workshop shared keys - delete them in each service after the workshop
SCOPUS_API_KEY=<Elsevier key, dev.elsevier.com>
SCOPUS_INST_TOKEN=
SCIDRAW_API_KEY=<sd_... from sci-draw.com -> Settings -> API Keys; scopes images:generate, jobs:read, credits:read>
GOOGLE_API_KEY=<aistudio.google.com/apikey, on a project with billing and a budget cap>
```
- **Scopus:** one key for the class shares Elsevier's quota (20,000 searches/week, 9 requests/s); check that sharing it in a class
  is fine under your library's Elsevier agreement. On campus no institution token is needed.
- **SciDraw:** one credit balance for everyone: the free plan (10 + 5/day) is not enough; Standard ($20/month, 300 credits ≈ 60
  2K images) fits ~30 students x 2 figures. At most 20 jobs run at once per account; extra ones queue or retry.
- **Gemini (PaperViz):** billed to your project (roughly $0.5-1 per figure); set a budget cap in Google Cloud billing.
- **After the workshop:** delete all three keys (Elsevier developer portal, SciDraw Settings → API Keys, AI Studio).

## Distribution
- **One repo**, `github.com/Rasoolpey/AI_Grand_Prix` (public), mirrors this folder: `README.md`, `setup.ps1`, `remove-keys.ps1`,
  `AI_Tools/` (Part 1), `AI_Grand_Prix/` (Part 2) and `instructor/`. `setup.ps1` downloads one zip of `main` and copies only
  `README.md`, `remove-keys.ps1`, `AI_Tools/` and `AI_Grand_Prix/` to students; `instructor/` is never copied (but it is public on GitHub).
- `instructor/TODO_WORKSHOP.md` and `instructor/TODO_RACE.md` are git-ignored: they stay on this machine only.
- Student command: `irm https://raw.githubusercontent.com/Rasoolpey/AI_Grand_Prix/main/setup.ps1 | iex`

## What a student gets
```
AI_Workshop\
  README.md · remove-keys.ps1
  AI_Tools\        my_keys.env (Scopus key) · my_instructions.md (student overrides) · AGENTS.md (defaults)
                   1_topic\ … 6_report\ (fixed result folders, pre-filled templates)
                   .agents\mcp_config.json (matlab, google-scholar, scopus, markitdown, scidraw, paperviz)
                   .agents\skills\ (research-question, grill-me, grilling, literature-search, literature-review, research-figure, research-report)
  AI_Grand_Prix\   .agents\mcp_config.json (matlab) · .agents\skills\ (race-debrief, car-design-review)
  .tools\ (hidden) uv 0.12.22 · Python 3.12 · MCP servers (matlab v0.14.0, Scholar @738d60a, Scopus @4968cc6, markitdown 0.0.1a7,
                   scidraw + paperviz: small servers written by setup.ps1; PaperVizAgent @e088a8f) · log\
```
Nothing global: no `~/.gemini` config, no user environment variables, no PATH change. Uninstall = delete `AI_Workshop` + the two desktop shortcuts.
**Keys** live in `AI_Tools\my_keys.env`, inside the Part 1 workspace so students see it in VS Code's file list. The Scopus server
is started through `.tools\mcp\run_with_keys.py`, which loads that file at start-up, so a changed key takes effect after reloading the VS Code window.

## Options (set before running)
| Variable | Effect |
|---|---|
| `AIW_DIR` | Workshop folder (default `%USERPROFILE%\AI_Workshop`; use a short path like `C:\AIW` for very long usernames) |
| `AIW_MATLAB_ROOT` | Force a MATLAB install (default: the newest found) |
| `AIW_SKIP_TEST=1` | Skip the self-test (it starts MATLAB and drives a baseline lap, about 1–3 min) |
| `AIW_NO_SHORTCUTS=1` | No desktop shortcuts |
| `AIW_LOCAL_WORKSHOP` | Copy `AI_Tools` + `AI_Grand_Prix` from a local copy of this repo instead of GitHub (testing, USB install) |
| `AIW_REPO_BRANCH` | Branch to download (default `main`) |
| `SCOPUS_API_KEY`, `SCOPUS_INST_TOKEN` | Written to `AI_Tools\my_keys.env` without prompting |

## Troubleshooting (beyond the student README)
- Logs: `AI_Workshop\.tools\log` (MATLAB MCP server).
- Lab IT blocking executables: allow `AI_Workshop\.tools\**`, or set `AIW_DIR` to an allowed location.
- Python servers are pinned on purpose: Scholar/Scopus need `mcp<2` (FastMCP); Scholar needs `bibtexparser<2`; MarkItDown needs `mcp>=2.1.1`.
