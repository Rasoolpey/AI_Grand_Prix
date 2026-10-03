# 🤖 AI Workshop

Two parts, one folder:

| | Folder | What you do |
|---|---|---|
| **Part 1 — AI tools** | `AI_Tools\` | Turn a research topic into a literature review and a research proposal, with an AI agent that searches Google Scholar and Scopus for you |
| **Part 2 — AI Grand Prix** | `AI_Grand_Prix\` | Design an autonomous race car with an AI agent that runs MATLAB for you, then race everyone else |

---

## 1. Setup (once, about 5 minutes)

1. **Install Antigravity** from https://antigravity.google/download and sign in with your student account.
2. **Get a Scopus API key** at https://dev.elsevier.com → *I want an API key* (register with your university e-mail).
3. **Open PowerShell** (Start menu → type `PowerShell`) and paste:
   ```powershell
   irm https://raw.githubusercontent.com/Rasoolpey/AI_Grand_Prix/main/setup.ps1 | iex
   ```
4. Paste your Scopus key when asked (it stays hidden; that's normal). Press **Enter** to skip the institution token.
   No key yet? Press Enter; you can paste it later into `AI_Tools\my_keys.env`.
5. Wait for **ALL SET!** The last check starts MATLAB and drives a test lap, which takes 1–3 minutes.

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

Start with:
```
Read AGENTS.md and the project, then run the race-debrief skill.
```
Then follow `AI_Grand_Prix\README.md` (the challenge and the rules) and `AGENT_GUIDE.md` (how to work with your agent).

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
