---
name: literature-review
description: Convert the PDFs in 3_papers/pdf to text, build the evidence table in 4_review/evidence.csv, write the literature review with candidate gaps in 4_review/review.md, and, once the student picks a gap, write 5_proposal/proposal.md. Use after literature-search and after the student has downloaded PDFs.
---

# Literature review → gaps → proposal (steps 4–5)

**Inputs:** `2_search/papers.csv`, `2_search/candidates.csv`, `3_papers/pdf/`. **Outputs:** `3_papers/text/`,
`4_review/evidence.csv`, `4_review/review.md`, `5_proposal/proposal.md` only.

## 1. Text (Docling)
Convert all PDFs at once with **Docling** (keeps headings, paragraphs and tables). In the terminal, from the `AI_Tools` folder:
```
..\.tools\py\Scripts\python.exe .agents\skills\literature-review\scripts\pdf_to_text.py
```
It writes `3_papers/text/<same name>.md` for each PDF (about 1–2 s per page; tell the student it takes a few minutes), matches each
text to its rank in `papers.csv` (file name, DOI or title), writes `3_papers/text/index.csv`, and lists the **abstract-only** papers
(no PDF). If a text is `NOT MATCHED`, open its first lines and find the paper yourself. Read the texts from the files: don't
convert PDFs any other way. (If Docling is missing, the script falls back to MarkItDown and says so.)
Abstract-only papers: their abstract is in `2_search/candidates.csv` (`abstract` column); if it is empty, use `scopus_get_abstract`.

## 2. Evidence table: `4_review/evidence.csv`
Keep the header `rank,doi,evidence_level,method,key_finding,limitation,location`. One row per paper; `evidence_level` = `full-text` or
`abstract-only`; `location` = the section/page that supports the finding (or `abstract`). Work in batches of about 5 papers and save
after each batch.

## 3. Review: `4_review/review.md`
Fill the template: 3–5 **themes** (not paper by paper), each claim cited as `[rank]`, the comparison table, and the evidence base line
(how many full-text vs abstract-only). End with **3 candidate gaps**, each a hypothesis with its evidence rows and what would prove it wrong.

## 4. Choose
Ask the student which gap to pursue. Don't continue until they choose.

## 5. Proposal: `5_proposal/proposal.md`
Fill every section of the template, including the **Figure brief** and the **MATLAB experiment — PENDING** section (testable claim,
baseline, metrics, simulation sketch). Then say: "Next: run the research-figure skill to draw the Figure brief, then the research-report skill."

Never invent findings, numbers or quotes. If it is not in `evidence.csv`, it is not in the review or the proposal.
