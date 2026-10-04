# Part 1 — AI tools for research

You go from a **topic** to a **literature review, a research proposal and a short report**, with an AI agent as your assistant.

## Before you start (2 minutes)
1. 🔑 Open **`my_keys.env`**, paste your Scopus key after `SCOPUS_API_KEY=`, save, and reload VS Code (`Ctrl+Shift+P` → *Reload Window*).
   (If you already gave your key during setup, it's there.)
2. Write your topic in **`1_topic/my_topic.md`**: your own topic, or the one you drew from the topic pool.
3. Optional: write your own rules for the agent in **`my_instructions.md`** (e.g. "only papers from the last 5 years").

## The steps
Type each line in the agent panel, one at a time. Every result lands in a fixed file, so you always know where to look.

| Step | You type | Result appears in |
|---|---|---|
| 1 | `Run the research-question skill` | `1_topic/research_brief.md` |
| 2 | `Run the literature-search skill` | `2_search/papers.csv` (30–40 papers with links) |
| 3 | *(you)* Download the PDFs you can through the library | put them in `3_papers/pdf/` |
| 4 | `Run the literature-review skill` | `4_review/evidence.csv`, `4_review/review.md`, then `5_proposal/proposal.md` |
| 5 | `Run the research-figure skill` (PaperViz, Google's figure method, draws the proposal's **Figure brief**) | `5_proposal/figure/` |
| 6 | `Run the research-report skill` | `6_report/report.md` |

The MATLAB experiment in your proposal stays **pending**: you build it after the workshop.

## ✅ Check the agent's work
- Every claim in `review.md` points to a row in `evidence.csv`.
- Papers marked `abstract-only` were not read in full: treat those claims as weaker.
- Spot-check 3 claims against the PDFs.
- Check the figure: every label spelled right, nothing drawn that the proposal does not say.
