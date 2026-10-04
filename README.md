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

1. **Open VS Code** (it is already on the lab PCs; you don't need to install any program) and add the
   **Google Antigravity extension**: *Extensions* (`Ctrl+Shift+X`) → search `Google Antigravity` → the one by **Google** →
   *Install*. Open the Antigravity panel and sign in with your student Google account.
   (If you skip this, the installer in step 4 adds the extension for you; you still sign in yourself.)
2. **Get a Scopus API key** at https://dev.elsevier.com → *I want an API key* (register with your university e-mail).
3. **Download the workshop** (no Git needed): open https://github.com/Rasoolpey/AI_Grand_Prix → green **Code** button →
   **Download ZIP**. In File Explorer, right-click the zip → **Extract All…** → choose your **Documents** folder → *Extract*.
4. **Open a terminal in that folder:** open **`Documents\AI_Grand_Prix-main`** (if you see another `AI_Grand_Prix-main`
   inside it, open that one: it is the folder with `setup.ps1` and `README.md` in it). Right-click an empty spot in the folder
   → **Open in Terminal** (Windows 10: hold *Shift*, right-click → *Open PowerShell window here*). Paste and press Enter:
   ```powershell
   irm https://raw.githubusercontent.com/Rasoolpey/AI_Grand_Prix/main/setup.ps1 | iex
   ```
   It installs everything **in this folder**: `Documents\AI_Grand_Prix-main` is the folder you work in from now on. Don't
   move or rename it after setup (the tools are set up for this path; if you do, run setup again in the new place).
5. Paste your Scopus key when asked (it stays hidden; that's normal). Press **Enter** to skip the institution token.
   No key yet? Press Enter; you can paste it later into `AI_Tools\my_keys.env`.
6. Wait for **ALL SET!** The last check starts MATLAB and drives a test race, which takes 1–3 minutes.

You now have, in `Documents\`:
```
AI_Grand_Prix-main\
  README.md        this guide
  remove-keys.ps1  clears your key at the end
  AI_Tools\        Part 1   (your Scopus key: AI_Tools\my_keys.env)
  AI_Grand_Prix\   Part 2
  instructor\      for the instructor (you can ignore it)
```
Nothing else is installed (the tools sit in a hidden `.tools` folder), apart from the Antigravity extension in your VS Code.

---

## 2. Part 1 — AI tools for research

**Open the folder:** in VS Code, *File → Open Folder* → `Documents\AI_Grand_Prix-main\AI_Tools` (or the desktop shortcut **AI Workshop – Part 1 AI Tools**).

**Check:** in the Antigravity panel, the list of **MCP servers** shows `matlab`, `google-scholar`, `scopus`, `markitdown`.

**Your topic:** bring your own, or join the **topic pool** and draw one in class. Write it in `1_topic\my_topic.md`.

Then type these in the agent panel, one at a time. Each result lands in a fixed, numbered folder:

| Step | You type | Result appears in |
|---|---|---|
| 1 | `Run the research-question skill` | `1_topic\research_brief.md` |
| 2 | `Run the literature-search skill` | `2_search\papers.csv` (30–40 papers with links) |
| 3 | *(you)* Download the PDFs you can, through the library | put them in `3_papers\pdf\` |
| 4 | `Run the literature-review skill` | `4_review\` then `5_proposal\proposal.md` |
| 5 | `Run the research-figure skill` (PaperViz, Google's figure method, draws the **Figure brief**; no key needed) | `5_proposal\figure\` |
| 6 | `Run the research-report skill` | `6_report\report.md` |

Want the agent to work differently (shorter review, only recent papers, another language)? Write it in **`my_instructions.md`**:
your rules override the defaults.

✅ **Check the agent's work:** every claim in `4_review\review.md` must point to a row in `4_review\evidence.csv`.

---

## 3. Part 2 — AI Grand Prix

**Open the folder:** in VS Code, `Documents\AI_Grand_Prix-main\AI_Grand_Prix` (or **AI Workshop – Part 2 Grand Prix**). The Antigravity panel's MCP servers list shows `matlab`.

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

It lives in **`AI_Tools\my_keys.env`**. You see it in the VS Code file list when you open Part 1:
```
SCOPUS_API_KEY=your-key
SCOPUS_INST_TOKEN=
```
To add or change it: paste it after the `=`, save (Ctrl+S), then reload VS Code (`Ctrl+Shift+P` → *Reload Window*).
The institution token is only needed **off campus** without the VPN (ask the library).

---

## 5. Finished? (shared PC)
```powershell
& "$env:USERPROFILE\Documents\AI_Grand_Prix-main\remove-keys.ps1"
```
Or delete the `AI_Grand_Prix-main` folder and the two desktop shortcuts.

---

## Help

| Problem | Fix |
|---|---|
| Anything went wrong in setup | Run the setup command again. It's safe and keeps your work. |
| `MATLAB has no licence` | Open MATLAB once normally, sign in, then run setup again. |
| `Scopus rejected the key` | Check `AI_Tools\my_keys.env`. Off campus you need the VPN or an institution token. |
| A tool is missing in the Antigravity panel | Open the **part folder** (`AI_Tools` or `AI_Grand_Prix`) in VS Code, not `AI_Grand_Prix-main` itself; then *Reload Window*. |
| No Antigravity panel in VS Code | Install the extension: *Extensions* (`Ctrl+Shift+X`) → `Google Antigravity` (publisher Google) → *Install*. |
| Still stuck | Raise your hand and show the yellow `[!!]` lines. |

---

## Trying the setup on a new machine (instructor)

Use a machine (or a fresh Windows account) that has never run the workshop, so nothing is left over from earlier tests.

**Prerequisites:** Windows, MATLAB installed and signed in (R2024a or later; base MATLAB only), VS Code (as on the lab PCs).
No admin rights, Docker, Git or Python are needed. The installer adds the Google Antigravity extension to VS Code
(skip that with `$env:AIW_NO_EXTENSION = "1"` to test the manual step).

1. **Install exactly as a student would** (section 1): download the ZIP, extract it into Documents, open a terminal in
   `AI_Grand_Prix-main` and paste the one-line command. (Run in any other folder, it downloads the files itself.)
   - To try a branch instead of `main`, first run `$env:AIW_REPO_BRANCH = "<branch>"`.
   - To try a local copy of this repo instead of GitHub, first run `$env:AIW_LOCAL_WORKSHOP = "C:\path\to\AI-Workshop"`.
   - More than one MATLAB? Choose one with `$env:AIW_MATLAB_ROOT = "C:\Program Files\MATLAB\R2026b"`.
2. **Read the installer's summary.** Expect `ALL SET!`, a line `MATLAB via MCP works - baseline race ...`, a line
   `Google Antigravity extension installed` (or `already installed`), and no yellow `[!!]` lines.
3. **Part 1 in VS Code:** open `AI_Grand_Prix-main\AI_Tools`, open the Antigravity panel and sign in; its MCP servers list shows
   `matlab`, `google-scholar`, `scopus`, `markitdown`; the agent finds the skills (ask it: `Which skills do you have?`).
   **Figure (PaperViz):** with a filled-in proposal, type `Run the research-figure skill` and check that the agent can generate
   an image itself (Antigravity's built-in image generation) and saves it in `5_proposal\figure\`.
   **Still unverified:** that the VS Code extension reads the workspace `.agents\skills\` folder like the app does.
4. **Part 2 in VS Code:** open `AI_Grand_Prix-main\AI_Grand_Prix`; the MCP servers list shows `matlab`; the agent lists
   `race-debrief` and `car-design-review`. Then ask the agent:
   ```
   Run testMCP, then garage, then practiceRace('Path', 'all') through MATLAB and report the results.
   ```
   Expected: every check `[OK]`; the baseline finishes all three paths with no penalties
   (about 22 s drag strip, 54 s technical, 278 s endurance; overall ≈ 48).
5. **Graphics in MATLAB itself** (from `AI_Grand_Prix-main\AI_Grand_Prix`): `garage`, `practiceRace` (animated race view with HUD),
   `r = practiceRace('Path', 'endurance', 'Headless', true); plotLap(r)`.
6. **Agent loop:** `Run the race-debrief skill on the technical path.` It should run the race, write `lapPlot.png` and propose
   one change without editing anything until you agree.
7. **Clean up:** run `remove-keys.ps1`, or delete `AI_Grand_Prix-main` and the two desktop shortcuts.

**Instructor tools** (race day, tests, balance) are not copied to students. Clone the repo for those:
```powershell
git clone https://github.com/Rasoolpey/AI_Grand_Prix.git
```
then, in MATLAB from the repo root: `addpath('instructor/race/tests'); report = checkInstallation();` (tests, baseline races and
figures). Race-day steps: `instructor/race/submissions/README.md`. Setup details and troubleshooting: `instructor/SETUP_NOTES.md`.

Please note anything that fails (the yellow `[!!]` lines and the log folder `AI_Grand_Prix-main\.tools\log\`).
