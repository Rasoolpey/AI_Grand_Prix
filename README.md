# 🤖 AI Workshop

Two parts, one folder:

| | Folder | What you do |
|---|---|---|
| **Part 1 — AI tools** | `AI_Tools\` | Turn a research topic into a literature review and a research proposal, with an AI agent that searches Google Scholar and Scopus for you |
| **Part 2 — AI Grand Prix** | `AI_Grand_Prix\` | Design an autonomous race car with an AI agent that runs MATLAB for you, then race everyone else |

---

## 1. Setup (once, about 5 minutes)

**MATLAB must already be installed and activated** (R2024a or later recommended). The Grand Prix uses **base MATLAB only**:
no Simulink or additional toolboxes are required. MATLAB Copilot is optional. The workshop installer sets up the agent's MATLAB connection.

1. **Install Antigravity** from https://antigravity.google/download and sign in with your student account.
2. **Get a Scopus API key** at https://dev.elsevier.com → *I want an API key* (register with your university e-mail).
3. **Open PowerShell** (Start menu → type `PowerShell`) and paste:
   ```powershell
   irm https://raw.githubusercontent.com/Rasoolpey/AI_Grand_Prix/main/setup.ps1 | iex
   ```
4. Paste your Scopus key when asked (it stays hidden; that's normal). Press **Enter** to skip the institution token.
   No key yet? Press Enter; you can paste it later into `AI_Tools\my_keys.env`.
5. Wait for **ALL SET!** The last check starts MATLAB and drives a test race, which takes 1–3 minutes.

You now have:
```
AI_Workshop\
  README.md        this guide
  remove-keys.ps1  clears your key at the end
  AI_Tools\        Part 1   (your Scopus key: AI_Tools\my_keys.env)
  AI_Grand_Prix\   Part 2
```
Nothing is installed anywhere else (the tools sit in a hidden `.tools` folder).

---

## 2. Part 1 — AI tools for research

**Open the folder:** in Antigravity, *File → Open Folder* → `AI_Workshop\AI_Tools` (or the desktop shortcut **AI Workshop – Part 1 AI Tools**).

**Check:** agent panel → `...` → **MCP Servers** shows `matlab`, `google-scholar`, `scopus`, `markitdown`.

**Your topic:** bring your own, or join the **topic pool** and draw one in class. Write it in `1_topic\my_topic.md`.

Then type these in the agent panel, one at a time. Each result lands in a fixed, numbered folder:

| Step | You type | Result appears in |
|---|---|---|
| 1 | `Run the research-question skill` | `1_topic\research_brief.md` |
| 2 | `Run the literature-search skill` | `2_search\papers.csv` (30–40 papers with links) |
| 3 | *(you)* Download the PDFs you can, through the library | put them in `3_papers\pdf\` |
| 4 | `Run the literature-review skill` | `4_review\` then `5_proposal\proposal.md` |
| 5 | Make the figure from the proposal's **Figure brief** | `5_proposal\figure\` |
| 6 | `Run the research-report skill` | `6_report\report.md` |

Want the agent to work differently (shorter review, only recent papers, another language)? Write it in **`my_instructions.md`**:
your rules override the defaults.

✅ **Check the agent's work:** every claim in `4_review\review.md` must point to a row in `4_review\evidence.csv`.

---

## 3. Part 2 — AI Grand Prix

**Open the folder:** `AI_Workshop\AI_Grand_Prix` (or **AI Workshop – Part 2 Grand Prix**). MCP Servers shows `matlab`.

You build an electric race car from parts (`student\carDesign.m`, budget 80 credits) and write its driver
(`student\controller.m`). Start with:
```
Read AGENTS.md and the project, then run the car-design-review skill.
```
When the car is built, race it and let the agent read the telemetry:
```
Run the race-debrief skill on the technical path.
```
Useful MATLAB commands: `garage` (your car and its numbers), `practiceRace('Path', 'all')` (all three paths and your
score), `plotLap(r)` (lap report), `submitCar` (hand in). The rules and the parts are in `AI_Grand_Prix\README.md`, the
equations in `AI_Grand_Prix\PHYSICS.md`, and how to work with your agent in `AGENT_GUIDE.md`.

---

## 4. Your Scopus key

It lives in **`AI_Tools\my_keys.env`**. You see it in the file list as soon as you open Part 1 in Antigravity:
```
SCOPUS_API_KEY=your-key
SCOPUS_INST_TOKEN=
```
To add or change it: paste it after the `=`, save (Ctrl+S), restart Antigravity. The institution token is only needed **off campus**
without the VPN (ask the library).

---

## 5. Finished? (shared PC)
```powershell
& "$env:USERPROFILE\AI_Workshop\remove-keys.ps1"
```
Or delete the `AI_Workshop` folder and the two desktop shortcuts.

---

## Help

| Problem | Fix |
|---|---|
| Anything went wrong in setup | Run the setup command again. It's safe and keeps your work. |
| `MATLAB has no licence` | Open MATLAB once normally, sign in, then run setup again. |
| `Scopus rejected the key` | Check `AI_Tools\my_keys.env`. Off campus you need the VPN or an institution token. |
| A tool is missing in Antigravity | Open the **part folder** (`AI_Tools` or `AI_Grand_Prix`), not `AI_Workshop` itself. |
| Still stuck | Raise your hand and show the yellow `[!!]` lines. |

---

## Trying the setup on a new machine (instructor)

Use a machine (or a fresh Windows account) that has never run the workshop, so nothing is left over from earlier tests.

**Prerequisites:** Windows, MATLAB installed and signed in (R2024a or later; base MATLAB only), Antigravity installed.
No admin rights, Docker, Git or Python are needed.

1. **Install exactly as a student would** (section 1): paste the one-line command into PowerShell.
   - To try a branch instead of `main`, first run `$env:AIW_REPO_BRANCH = "<branch>"`.
   - To try a local copy of this repo instead of GitHub, first run `$env:AIW_LOCAL_WORKSHOP = "C:\path\to\AI-Workshop"`.
   - More than one MATLAB? Choose one with `$env:AIW_MATLAB_ROOT = "C:\Program Files\MATLAB\R2026b"`.
2. **Read the installer's summary.** Expect `ALL SET!`, a line `MATLAB via MCP works - baseline race ...`, and no yellow `[!!]` lines.
3. **Part 1 in Antigravity:** open `AI_Workshop\AI_Tools`; *MCP Servers* lists `matlab`, `google-scholar`, `scopus`,
   `markitdown`; the agent finds the skills (ask it: `Which skills do you have?`).
4. **Part 2 in Antigravity:** open `AI_Workshop\AI_Grand_Prix`; *MCP Servers* lists `matlab`; the agent lists
   `race-debrief` and `car-design-review`. Then ask the agent:
   ```
   Run testMCP, then garage, then practiceRace('Path', 'all') through MATLAB and report the results.
   ```
   Expected: every check `[OK]`; the baseline finishes all three paths with no penalties
   (about 22 s drag strip, 54 s technical, 278 s endurance; overall ≈ 48).
5. **Graphics in MATLAB itself** (from `AI_Workshop\AI_Grand_Prix`): `garage`, `practiceRace` (animated race view with HUD),
   `r = practiceRace('Path', 'endurance', 'Headless', true); plotLap(r)`.
6. **Agent loop:** `Run the race-debrief skill on the technical path.` It should run the race, write `lapPlot.png` and propose
   one change without editing anything until you agree.
7. **Clean up:** run `remove-keys.ps1`, or delete `AI_Workshop` and the two desktop shortcuts.

**Instructor tools** (race day, tests, balance) are not copied to students. Clone the repo for those:
```powershell
git clone https://github.com/Rasoolpey/AI_Grand_Prix.git
```
then, in MATLAB from the repo root: `addpath('instructor/race/tests'); report = checkInstallation();` (tests, baseline races and
figures). Race-day steps: `instructor/race/submissions/README.md`. Setup details and troubleshooting: `instructor/SETUP_NOTES.md`.

Please note anything that fails (the yellow `[!!]` lines and the log folder `AI_Workshop\.tools\log\`).
