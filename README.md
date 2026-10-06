# 🤖 AI Workshop

Two parts, one folder:

| | Folder | What you do |
|---|---|---|
| **Part 1 — AI tools** | `AI_Tools\` | Turn a research topic into a literature review and a research proposal, with an AI agent that searches Scopus (Q1 journals) for you and writes an IEEE-format report |
| **Part 2 — AI Grand Prix** | `AI_Grand_Prix\` | Design a small electric race car and the code that drives it, with an AI agent that runs MATLAB for you. Beat your own best run (a ghost car), then race everyone on the projector |

Do the **setup** once. Then **click a part below to open its instructions** (▶ closed, ▼ open).

---

## 1. Setup (once, about 5–15 minutes)

**MATLAB must already be installed and activated** (R2024a or later recommended). The Grand Prix uses **base MATLAB only**:
no Simulink or additional toolboxes are required. MATLAB Copilot is optional. The workshop installer sets up the agent's MATLAB connection.

1. **Open VS Code** (it is already on the lab PCs; you don't need to install any program) and add the
   **Google Antigravity extension**: *Extensions* (`Ctrl+Shift+X`) → search `Google Antigravity` → the one by **Google** →
   *Install*. Open the Antigravity panel and sign in with your student Google account.
   (If you skip this, the installer in step 4 adds the extension for you; you still sign in yourself.)
2. **Get a Scopus API key** at https://dev.elsevier.com → *I want an API key* (register with your university e-mail).
   It is only needed for Part 1.
3. **Download the workshop** (no Git needed): open https://github.com/Rasoolpey/AI_Grand_Prix → green **Code** button →
   **Download ZIP**. In File Explorer, right-click the zip → **Extract All…** → choose your **Documents** folder → *Extract*.
4. **Open a terminal in that folder:** open **`Documents\AI_Grand_Prix-main`** (if you see another `AI_Grand_Prix-main`
   inside it, open that one: it is the folder with `setup.ps1`, `README.md`, `AI_Tools` and `AI_Grand_Prix` in it).
   Right-click an empty spot in the folder → **Open in Terminal** (Windows 10: hold *Shift*, right-click → *Open
   PowerShell window here*). Paste and press Enter:
   ```powershell
   irm https://raw.githubusercontent.com/Rasoolpey/AI_Grand_Prix/main/setup.ps1 | iex
   ```
   It installs everything **in this folder**, your **workshop folder** from now on. Don't move or rename it after setup
   (the tools are set up for this path; if you do, run setup again in the new place).
   *Cloned it with Git, or saved it somewhere else?* Open the terminal in that folder instead: setup installs into the
   folder you run it from, whatever its name, as long as `setup.ps1`, `AI_Tools` and `AI_Grand_Prix` are in it.
5. Paste your Scopus key when asked (it stays hidden; that's normal), then press **Enter** to skip the institution token.
   No key yet? Press Enter; you can paste it later into `AI_Tools\my_keys.env` (Part 1 shows how).
6. Wait for **ALL SET!** The last check starts MATLAB and drives a test race, which takes 1–3 minutes.
   Then, if VS Code was already open, reload it: `Ctrl+Shift+P` → *Reload Window*.

You now have, in your workshop folder (`Documents\AI_Grand_Prix-main` if you followed the steps above):
```
AI_Grand_Prix-main\
  README.md        this guide
  remove-keys.ps1  clears your key at the end
  AI_Tools\        Part 1   (your Scopus key: AI_Tools\my_keys.env)
  AI_Grand_Prix\   Part 2
  instructor\      for the instructor (you can ignore it)
```
Nothing else is installed (the tools sit in a hidden `.tools` folder), apart from the Antigravity extension in your VS Code
and the list of tools it may use (`%USERPROFILE%\.gemini\config\mcp_config.json`). Setup also puts two shortcuts on your
desktop: **AI Workshop - Part 1 AI Tools** and **AI Workshop - Part 2 Grand Prix**.

---

<details>
<summary><b>📚 Part 1 — AI tools for research</b> &nbsp;(click to open)</summary>

<br>

**Open the folder:** in VS Code, *File → Open Folder* → your workshop folder's `AI_Tools` (or the desktop shortcut
**AI Workshop - Part 1 AI Tools**).

**Check:** in the Antigravity panel, the list of **MCP servers** shows `matlab`, `google-scholar`, `scopus`, `markitdown`.

**First, write your topic:** in VS Code, open **`1_topic\my_topic.md`**, replace the text in `[brackets]` with your name
and your research topic, and save (`Ctrl+S`). Everything after this starts from that file.

Then type these in the agent panel, one at a time. Each result lands in a fixed, numbered folder:

| Step | You type | What runs | Result appears in |
|---|---|---|---|
| 1 | `Run the research-question skill` | skills *research-question* + *grilling*: up to 10 questions in the chat; no tools | `1_topic\research_brief.md` |
| 2 | `Run the literature-search skill` (Scopus, **Q1 journals** of IEEE and Elsevier only) | script `scopus_q1.py` (Scopus API, Q1 filter); optional MCP `scopus` and `google-scholar` | `2_search\papers.csv` (30–40 papers with links) |
| 3 | *(you)* Download the PDFs you can, through the library | you and your library login | put them in `3_papers\pdf\` |
| 4 | `Run the literature-review skill` | script `pdf_to_text.py` (Docling turns the PDFs into text); MCP `scopus` for missing abstracts, `markitdown` as a fallback | `4_review\` then `5_proposal\proposal.md` |
| 5 | `Run the research-figure skill` (PaperViz, Google's figure method, draws the **Figure brief**) | the agent's built-in image generation; no key needed | `5_proposal\figure\` |
| 6 | `Run the research-report skill` (a short review paper in **IEEE format**, with your figure) | script `build_report.py` (LaTeX), then Overleaf on the web makes the PDF | `6_report\report.md`, then double-click `6_report\open_in_overleaf.html` for the **PDF** (free Overleaf account) |

**See what is running:** the agent says which skill or tool it uses before it uses it, and every tool call and terminal
command shows up in the agent panel (terminal commands may wait for your OK).

Want the agent to work differently (shorter review, only recent papers, another language)? Write it in **`my_instructions.md`**:
your rules override the defaults.

✅ **Check the agent's work:** every claim in `4_review\review.md` must point to a row in `4_review\evidence.csv`.

#### Your Scopus key

It lives in **`AI_Tools\my_keys.env`**. You see it in the VS Code file list when you open Part 1:
```
SCOPUS_API_KEY=your-key
SCOPUS_INST_TOKEN=
```
To add or change it: paste it after the `=`, save (Ctrl+S), then reload VS Code (`Ctrl+Shift+P` → *Reload Window*).
The institution token is only needed **off campus** without the VPN (ask the library).

</details>

<details>
<summary><b>🏎️ Part 2 — AI Grand Prix</b> &nbsp;(click to open)</summary>

<br>

**Open the folder:** in VS Code, *File → Open Folder* → your workshop folder's `AI_Grand_Prix` (or the desktop shortcut
**AI Workshop - Part 2 Grand Prix**).

**Check:** the Antigravity panel's MCP servers list shows the same 4 servers as in Part 1, and when you ask the agent
`Which skills do you have?` it names **`car-design-review`** and **`race-debrief`**.

#### What you do

You get a small electric race car that already works, slowly. You race it on four paths (a drag strip, a technical
circuit, a 5-lap endurance and a muddy road) and see your scores. Then you **ask the AI agent to improve it**: it suggests
changes, **you pick one**, and it edits the files and tests them. You race the new car against your best run so far (a
grey **ghost** car) and keep what is better. You don't write code yourself.

#### The steps

| Step | What you do | Where |
|---|---|---|
| **1. Race the starting car** | In `student\carDesign.m`, change `"Team Name"` (in `car.team = "Team Name";`) to your team name and save. Open **MATLAB**, make `AI_Grand_Prix` the current folder (MATLAB's address bar, or `cd('<your workshop folder>\AI_Grand_Prix')`) and run `garage`, then `practiceRace` (watch it drive), then `practiceRace('Path', 'all')`. Note your **overall score** and your **weakest path**. | MATLAB |
| **2. Ask the AI to improve the car** | Type: `Read AGENTS.md. I raced my car with practiceRace('Path', 'all'). Which path is my weakest, and why? Suggest 2–3 changes to my car's parts, with what each gains and costs. Don't change anything yet.` Pick one: `Make change 2 and test it on all four paths.` (The first time, the agent's MATLAB takes about a minute to start.) | agent panel |
| **3. Ask the AI to improve the driver** | Type: `Improve my controller so the car is faster on my weakest path without new penalties. Explain the change in simple words, make one change, and test it on all four paths.` Not better? `Undo that change.` | agent panel |
| **4. Race your ghost** | Run `practiceRace('Path', 'all')`. Your car races a grey ghost: your best run so far. If the **overall score** is better, it is saved as your **best model** (`best_model\<team>.zip`); if not, nothing is saved. | MATLAB |
| **5. Repeat 2–4, then hand in** | Run `bestModel` (your best model: scores and team name), then `submitCar` (checks it and hands it in). | MATLAB |

`AGENTS.md` is the agent's rule book for this project; you don't need to read it. It makes the agent offer options, wait
for your choice, change one thing at a time and test it. Only *your* `practiceRace('Path', 'all')` saves your best model.

Want more? Ask it anything in plain words: `Why is my car slow on the muddy road?`, `What would soft tyres change?`,
`Check my controller for anything that only works on the practice tracks.`

#### Handy MATLAB commands (in the `AI_Grand_Prix` folder)

```matlab
garage                                     % your car: drawing, numbers, cost, estimated times
practiceRace                               % the technical circuit, animated, with your best run as a ghost
practiceRace('Path', 'mud')                % "drag" | "technical" | "endurance" | "mud" | "wet"
practiceRace('Path', 'all')                % all four paths vs your ghost, overall score, saves a better model
r = practiceRace('Path', 'technical', 'Headless', true);  plotLap(r)   % lap report: grip, speed, battery
bestModel                                  % your best model: scores, parts, the file you hand in
submitCar                                  % check your best model and hand it in
```

#### Race day

Your instructor collects every team's best model into one folder and starts the race on the projector: first a
**scrutineering** screen (every car is checked and driven on the same computer), then **four races** on new layouts with
every car on the track at once (ghost cars: they never touch), each about 12 seconds long with a live running order,
then the standings. The names on screen are the team names inside the models.

#### More

The full guide (the parts, how the car is modelled, scoring, the sweet spot): `AI_Grand_Prix\README.md`. The equations:
`AI_Grand_Prix\PHYSICS.md`. How to talk to your agent: `AI_Grand_Prix\AGENT_GUIDE.md`.

✅ **Stay in charge:** the agent asks before it changes anything. If it decides for you anyway, type
`Stop. Undo that and give me the options instead. I'll choose.`

</details>

---

## Finished? (shared PC)
```powershell
& "$env:USERPROFILE\Documents\AI_Grand_Prix-main\remove-keys.ps1"
```
(Installed somewhere else? Run `remove-keys.ps1` from your workshop folder.) Or delete the workshop folder and the two
desktop shortcuts.

---

## Help

| Problem | Fix |
|---|---|
| Anything went wrong in setup | Run the setup command again. It's safe and keeps your work. |
| `MATLAB has no licence` | Open MATLAB once normally, sign in, then run setup again. |
| `Scopus rejected the key` | Check `AI_Tools\my_keys.env`. Off campus you need the VPN or an institution token. |
| A tool is missing in the Antigravity panel | *Reload Window* (`Ctrl+Shift+P`): VS Code must be reloaded after setup. Still missing? Run the setup command again. |
| A skill is missing (the agent doesn't know `research-question` or `race-debrief`) | Open the **part folder** (`AI_Tools` or `AI_Grand_Prix`) in VS Code, not the workshop folder itself. |
| No Antigravity panel in VS Code | Install the extension: *Extensions* (`Ctrl+Shift+X`) → `Google Antigravity` (publisher Google) → *Install*. |
| `Unrecognized function or variable 'carDesign'` in MATLAB | Make `AI_Grand_Prix` MATLAB's current folder and run `garage` once. |
| No best model / no ghost | Run `practiceRace('Path', 'all')`: your first run that finishes a path is saved. `bestModel` shows it. |
| Still stuck | Raise your hand and show the yellow `[!!]` lines. |

---

<details>
<summary><b>🧑‍🏫 For the instructor: test the setup and rehearse race day</b> &nbsp;(click to open)</summary>

<br>

#### Try the setup on a new machine

Use a machine (or a fresh Windows account) that has never run the workshop, so nothing is left over from earlier tests.

**Prerequisites:** Windows, MATLAB installed and signed in (R2024a or later; base MATLAB only), VS Code (as on the lab PCs).
No admin rights, Docker, Git or Python are needed. The installer adds the Google Antigravity extension to VS Code
(skip that with `$env:AIW_NO_EXTENSION = "1"` to test the manual step).

1. **Install exactly as a student would** (section 1): download the ZIP, extract it into Documents, open a terminal in
   `AI_Grand_Prix-main` and paste the one-line command. A Git clone works the same way: open the terminal in the clone.
   (Run in a folder without the workshop files, setup downloads them into `%USERPROFILE%\AI_Workshop`.)
   - To try a branch instead of `main` (only when setup downloads the files itself), first run `$env:AIW_REPO_BRANCH = "<branch>"`.
   - To try a local copy of this repo, first run `$env:AIW_LOCAL_WORKSHOP = "C:\path\to\the\copy"`.
   - More than one MATLAB? Choose one with `$env:AIW_MATLAB_ROOT = "C:\Program Files\MATLAB\R2026b"`.
2. **Read the installer's summary.** Expect `ALL SET!`, a line `MATLAB via MCP works - baseline race ...`, a line
   `Google Antigravity extension installed` (or `already installed`), and no yellow `[!!]` lines.
3. **Part 1 in VS Code:** open the workshop folder's `AI_Tools`, open the Antigravity panel and sign in; its MCP servers list
   shows `matlab`, `google-scholar`, `scopus`, `markitdown`; the agent finds the skills (ask it: `Which skills do you have?`).
   **Figure (PaperViz):** with a filled-in proposal, type `Run the research-figure skill` and check that the agent can generate
   an image itself (Antigravity's built-in image generation) and saves it in `5_proposal\figure\`.
4. **Part 2 in VS Code:** open the workshop folder's `AI_Grand_Prix`; the MCP servers list shows the same 4 servers; the agent
   lists `race-debrief` and `car-design-review`. Then ask the agent:
   ```
   Run testMCP, then garage, then practiceRace('Path', 'all') through MATLAB and report the results.
   ```
   Expected: every check `[OK]`; the starting car finishes all four paths with no penalties (about 22 s drag strip,
   54 s technical, 278 s endurance, 64 s muddy road; overall ≈ 48), and the run is saved as the first best model.
5. **Graphics in MATLAB itself** (current folder: `AI_Grand_Prix`): `garage`; `practiceRace` (animated race view with the
   HUD); `practiceRace('Path', 'all')` (the fast replay of all four paths; from the second run on, with the grey ghost);
   `bestModel`; `r = practiceRace('Path', 'endurance', 'Headless', true); plotLap(r)`.
6. **Agent loop:** `Run the race-debrief skill on the technical path.` It should run the race, write `lapPlot.png`, say
   in plain words what limits the car and propose one change, without editing anything until you agree; after your yes,
   it makes the change and tests it on all four paths.
7. **Hand-in:** change `car.team` in `student\carDesign.m`, run `practiceRace('Path', 'all')` again (the same car under a new
   name replaces the best model), then `submitCar`: it checks the best model, adds the log and names the file to send.
8. **Clean up:** run `remove-keys.ps1`, or delete the workshop folder and the two desktop shortcuts.

#### Tests

In MATLAB, from the workshop folder (the one with `README.md` in it):
```matlab
addpath('instructor/race/tests');  report = checkInstallation();
```
Expected last line: `INSTALLATION_CHECK_PASSED: <release>, 25/25 tests, baseline score 48.16`. It does not touch your
best model.

#### Race day: `finalRace`

Every team hands in its best model, `best_model\<team>.zip` (`submitCar`; or they send you the file). Put all the zips in
one folder. In MATLAB, from the workshop folder:
```matlab
cd instructor/race
addpath(pwd, fullfile(pwd, 'controllers'), fullfile(pwd, 'tests'));  setupPaths();
finalRace('C:\path\to\the\folder with the models')
```
A **scrutineering** screen checks and drives every model, then come the four races (about 12 s each on screen, with a
3-2-1 countdown and a live running order), each race's results, and the standings. **Press a key in the figure** to move
on to the next scene. The names on screen come from `car.team` inside each model. Results are saved in
`instructor\race\results\final_<date>_<time>\`.

**The race-day layouts are private.** They are longer and busier than the practice paths and are **not in the repo** (it is
public): they live in `instructor\race\finals\`, which git ignores. Copy that folder from the machine where you keep it,
then build the race-day paths once with a secret number of your choice:
```matlab
makeFinals(<secret number>)
```
Without them (a fresh clone or ZIP), `finalRace` says **REHEARSAL** and races on the practice paths. Everything else is the same.

**Rehearse with fake teams** (8 teams; one crashes on purpose and one is flagged by the code check and not raced):
```matlab
inbox = makeRehearsal(8, '', 'Hang', false);
finalRace(inbox)
```
To put your own best model in the rehearsal, copy it in first:
`copyfile(fullfile('..', '..', 'AI_Grand_Prix', 'best_model', '*.zip'), inbox)`.

More: `instructor\race\submissions\README.md` (including the fully isolated pipeline, each team in its own MATLAB).
Setup details and troubleshooting: `instructor\SETUP_NOTES.md`.

Please note anything that fails (the yellow `[!!]` lines and the log folder `.tools\log\` in the workshop folder).

</details>
