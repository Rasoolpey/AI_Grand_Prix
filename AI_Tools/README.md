# Part 1 — AI tools for research

You go from a **topic** to a **literature review, a research proposal and a short review paper in IEEE format**, with an AI agent
as your assistant.

## Before you start (2 minutes)
1. 🔑 Open **`my_keys.env`**, paste your Scopus key after `SCOPUS_API_KEY=`, save, and reload VS Code (`Ctrl+Shift+P` → *Reload Window*).
   (If you already gave your key during setup, it's there.)
2. Write your topic in **`1_topic/my_topic.md`**: replace the text in `[brackets]` with your name and your topic, and save.
3. Optional: write your own rules for the agent in **`my_instructions.md`** (e.g. "only papers from the last 5 years").

## The steps
Type each line in the agent panel, one at a time. Every result lands in a fixed file, so you always know where to look.

| Step | You type | Result appears in |
|---|---|---|
| 1 | `Run the research-question skill` | `1_topic/research_brief.md` |
| 2 | `Run the literature-search skill` (Scopus, **Q1 journals** of IEEE and Elsevier only) | `2_search/papers.csv` (30–40 papers with links) |
| 3 | *(you)* Download the PDFs you can through the library | put them in `3_papers/pdf/` |
| 4 | `Run the literature-review skill` (Docling turns the PDFs into text) | `4_review/evidence.csv`, `4_review/review.md`, then `5_proposal/proposal.md` |
| 5 | `Run the research-figure skill` (PaperViz, Google's figure method, draws the proposal's **Figure brief**) | `5_proposal/figure/` |
| 6 | `Run the research-report skill` (IEEE format, with your figure) | `6_report/report.md`, then double-click `6_report/open_in_overleaf.html` for the **PDF** |

The MATLAB experiment in your proposal stays **pending**: you build it after the workshop.

For the PDF you need a free [Overleaf](https://www.overleaf.com) account (your university may offer a premium one).
Want other journals too? Write it in `my_instructions.md`, e.g. "also accept Springer journals" or "accept Q2 journals".

## ✅ Check the agent's work
- Every claim in `review.md` points to a row in `evidence.csv`.
- Papers marked `abstract-only` were not read in full: treat those claims as weaker.
- Spot-check 3 claims against the PDFs.
- Every paper in `papers.csv` comes from Scopus and a Q1 journal (`quartile` column), so none is made up.
- Check the figure: every label spelled right, nothing drawn that the proposal does not say.
