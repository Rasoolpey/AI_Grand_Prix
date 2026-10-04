---
name: research-figure
description: Make the proposal's figure from the Figure brief in 5_proposal/proposal.md and save it in 5_proposal/figure/. Uses PaperViz (Google's diagram agents) for method/concept diagrams, or MATLAB for plots and when PaperViz is not available. Use after literature-review has written the proposal, when the student asks for the figure.
---

# Figure from the Figure brief (step 5)

**Input:** the **Figure brief** (and the method section) in `5_proposal/proposal.md`. **Output:** image files in `5_proposal/figure/` only,
plus one line in the proposal pointing to the chosen figure.

## 1. Read and plan
Read the Figure brief. Tell the student, in 3–4 lines, what the figure will show: every box/element, every arrow, the labels, and the
one message a reader should get. Ask them to confirm or correct it before you generate anything.

## 2. Pick the tool
| The figure is… | Tool | Call |
|---|---|---|
| a method, system, concept or pipeline (boxes and arrows, stages, data flow) | **PaperViz** (`paperviz` server) | `paperviz_generate_diagram(method_text, caption, filename, aspect_ratio, critic_rounds=1)` |
| a plot of numbers (axes, curves, bars), or PaperViz is not available | **MATLAB** (`matlab` server) | write a short script that draws it, `exportgraphics(gcf, '5_proposal/figure/<name>.png', 'Resolution', 200)` |

- **PaperViz:** `method_text` = the method in full sentences (from the proposal); `caption` = what the figure must communicate (the
  Figure brief). It takes 1–4 minutes; if it hands back a job id, call `paperviz_check_job` until it is done. If unsure whether it
  works, call `paperviz_check_setup` first.
- If PaperViz says its key is missing, tell the student to fill `GOOGLE_API_KEY` in `AI_Tools/my_keys.env`, or draw the figure with
  MATLAB instead. Never ask the student to paste a key into the chat.

## 3. Check the result
Open the saved image and compare it with the plan from step 1: is every element there, are the labels spelled correctly, is anything
invented that the proposal does not say? Report the problems to the student. Regenerate at most twice, each time with a more precise
description (or `critic_rounds=2`); every run uses the student's Gemini quota.

## 4. Record it
Add a line under the Figure brief in `5_proposal/proposal.md`: `Figure: figure/<file name> (made with <tool>)`. Then say:
"Next: run the research-report skill."

Generated figures can contain wrong labels or invented details: the student must check them before using them anywhere.
