---
name: research-report
description: Write the student's Part 1 report as a short review paper in IEEE format, with the proposal's figure and an automatic IEEE reference list, then build it for Overleaf (one click gives the PDF). Writes 6_report/report.md and builds 6_report/open_in_overleaf.html. Use as the last step of Part 1, when the student asks for their report.
---

# Research report in IEEE format (step 6)

**Inputs:** `1_topic/research_brief.md`, `2_search/search_log.md`, `2_search/papers.csv`, `4_review/review.md`, `4_review/evidence.csv`,
`5_proposal/proposal.md`, `5_proposal/figure/`. **Output:** `6_report/report.md`, then the build script writes `6_report/overleaf/`,
`6_report/report_overleaf.zip` and `6_report/open_in_overleaf.html`.

The report is a **short review paper (about 4 pages) in IEEE conference format**. You write the content in `6_report/report.md`
(Markdown); a script turns it into LaTeX with the official IEEE class (IEEEtran), the IEEE reference style and the figure. Overleaf
compiles it online: nothing to install.

## 1. Check and ask
Check the inputs are filled (not blank templates); if one is missing, say which step to run first. Then ask the student, in one
message: their **name**, **department and university** (and e-mail if they want it on the paper), **what the agent did well**, and
**what they had to check or correct**. Use their own words for the last two.

## 2. Write `6_report/report.md`
Fill the template. Keep the front matter (`title`, `author`, `affiliation`, `email`, `keywords`) and **every heading, in this order**:
Abstract · Introduction · Literature Search Method · Review of the Literature (one `###` subsection per theme) · Research Gap and
Proposed Study · Planned MATLAB Experiment · Conclusion · Use of AI Tools. Don't number the headings and don't write a reference
list: both are made automatically.

- **Style:** formal academic English, full paragraphs (lists only for the experiment). About 2,500–3,000 words in total.
- **Abstract:** one paragraph, 150–200 words, no citations.
- **Citations:** only `[rank]` with ranks from `2_search/papers.csv`, e.g. `[4]`, `[4], [9]` or `[3–5]`. Every claim and number must
  come from `4_review/evidence.csv`: no new facts.
- **Literature Search Method:** the queries, the filter (Scopus, Q1 journals, publishers, years), found/kept, full-text vs abstract-only.
- **Table:** the comparison table from `4_review/review.md`, with a caption line `Table: <caption>` right above it.
- **Figure:** the proposal's figure (the `Figure:` line under the Figure brief in `5_proposal/proposal.md`), in the Research Gap
  section, on its own line: `![<one-sentence caption>](../5_proposal/figure/<file>.png)`. Refer to it in the text as "Fig. 1".
- **Math:** between `$...$` (e.g. `$T_{\max} < 40$ °C`); symbols like ≥, ° and Δ can be typed directly.
- **Planned MATLAB Experiment:** testable claim, baseline, metrics, simulation sketch, from the proposal; status **pending**.
- **Use of AI Tools:** the student's answers.

## 3. Build
In the terminal, from the `AI_Tools` folder:
```
..\.tools\py\Scripts\python.exe .agents\skills\research-report\scripts\build_report.py
```
If it prints `ERROR` (an unknown citation, a missing figure, an empty title) or `WARNING` (template text left), fix `report.md`
and build again. It reports the length in words and pages: aim for about 4 pages.

## 4. Hand over
Tell the student:
"Your report is ready in IEEE format. Double-click `6_report/open_in_overleaf.html` (sign in to Overleaf first) and click
**Open in Overleaf**: it compiles the PDF. If the button doesn't work: Overleaf → New Project → Upload Project →
`6_report/report_overleaf.zip`. To change the text, edit `6_report/report.md` and ask me to build it again."
