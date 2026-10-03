# Setup notes (instructor)

Students follow the workshop [README.md](../README.md). This page covers what `setup.ps1` does, so you can support students.

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
                   .agents\mcp_config.json (matlab, google-scholar, scopus, markitdown)
                   .agents\skills\ (research-question, grill-me, grilling, literature-search, literature-review, research-report)
  AI_Grand_Prix\   .agents\mcp_config.json (matlab) · .agents\skills\race-debrief
  .tools\ (hidden) uv 0.12.22 · Python 3.12 · MCP servers (matlab v0.14.0, Scholar @738d60a, Scopus @4968cc6, markitdown 0.0.1a7) · log\
```
Nothing global: no `~/.gemini` config, no user environment variables, no PATH change. Uninstall = delete `AI_Workshop` + the two desktop shortcuts.
**Keys** live in `AI_Tools\my_keys.env`, inside the Part 1 workspace so students see it in Antigravity's file list. The Scopus server
is started through `.tools\mcp\run_with_keys.py`, which loads that file at start-up, so a changed key takes effect after restarting Antigravity.

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
