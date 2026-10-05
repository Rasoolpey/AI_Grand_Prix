---
name: literature-search
description: Search Scopus for the research question in 1_topic/research_brief.md, keep only papers from Q1 journals of IEEE and Elsevier, and save the 30-40 most important to 2_search/papers.csv, with the queries in 2_search/search_log.md. Use after the research brief is written and before any reading or reviewing.
---

# Literature search (step 2)

**Input:** `1_topic/research_brief.md`. If it is still a blank template, stop and say "Run the research-question skill first."
**Output:** `2_search/candidates.csv`, `2_search/papers.csv` and `2_search/search_log.md` only.

**Scopus first, Q1 only.** Papers come from **Scopus**, limited to **journal articles and reviews** published by **IEEE or Elsevier**
in **Q1 journals** (top 25 % of their subject area by CiteScore). The script below applies this filter; you never add a paper it
rejected. Google Scholar is only an optional extra, and its papers must pass the same check. `my_instructions.md` may change the
publishers, the quartile or the years (use the options at the end).

All commands run in the terminal **from the `AI_Tools` folder** (the workspace root), with the workshop Python:

```
..\.tools\py\Scripts\python.exe .agents\skills\literature-search\scripts\scopus_q1.py <command> ...
```

## 1. Queries
Write **3–5 Scopus queries** from the brief's keywords and synonyms, in Scopus syntax: the method + the application, synonyms joined
with `OR`, one broader query. Topic terms only: the script adds the journal, publisher and quartile filter itself.
Example: `TITLE-ABS-KEY(("model predictive control" OR MPC) AND ("autonomous racing" OR "race car"))`.
Show the queries to the student in one short list before searching.

## 2. Search (Scopus, filtered to Q1)
```
..\.tools\py\Scripts\python.exe .agents\skills\literature-search\scripts\scopus_q1.py search "QUERY 1" "QUERY 2" "QUERY 3" --since 2015
```
Use `--since` with the first year from the brief's scope (leave it out for no limit). For each query it checks the 40 most relevant
and the 15 most cited results, looks up every journal's CiteScore rank, and writes the papers that pass to
`2_search/candidates.csv` (title, authors, venue, publisher, quartile, DOI, citations, **abstract**) and the query table in
`2_search/search_log.md`. Tell the student how many candidates each query gave.

- **Fewer than about 40 candidates:** broaden the queries (more synonyms, fewer `AND` terms, earlier `--since`) and run `search` again.
- **Hundreds of results but few candidates:** the topic is covered mostly by other publishers; tell the student (they may allow
  more publishers in `my_instructions.md`).
- **Optional: Google Scholar** (`search_google_scholar_key_words`) for papers Scopus missed. Check each paper you want in Scopus:
  ```
  ..\.tools\py\Scripts\python.exe .agents\skills\literature-search\scripts\scopus_q1.py add "<DOI of one paper>" "<exact title of another>" --query "<the Scholar query>"
  ```
  Only papers it reports as `ADDED` become candidates.

## 3. Choose and rank
Read `2_search/candidates.csv`. Score each candidate's **relevance** to the research question from its title and abstract:
3 = answers it directly, 2 = important context or method, 1 = marginal, 0 = off-topic. Keep the **30–40** best (or the number in
`my_instructions.md`), relevance 2–3 only, including 3–5 **review** papers if there are any (`type` = Review).
Write them to `2_search/papers.csv` with the header
`rank,title,authors,year,venue,publisher,quartile,doi,doi_link,citations,source,relevance,why_selected`:
copy the fields from `candidates.csv`, add `relevance` and a one-line `why_selected` (leave `rank` empty). Then run:
```
..\.tools\py\Scripts\python.exe .agents\skills\literature-search\scripts\scopus_q1.py finalize
```
It refills every field from the Scopus record (so no typo or invented detail survives), removes anything that is not a candidate,
ranks the papers (relevance, then citations per year, then recency) and fills the **Kept** column of the search log. Read its
messages and fix what it reports.

## 4. Finish
Write the **Summary** in `2_search/search_log.md` (2–3 sentences: how many found, how many kept, the main themes). Then tell the student:
"Download the PDFs you can through the library into `3_papers/pdf/`. Name them `<rank>_<first-author>_<year>.pdf`
(e.g. `03_Kabzan_2019.pdf`), or keep the publisher's file name. Then run the literature-review skill."

## Options (`search` and `add`)
`--publishers ieee,elsevier` (default) · e.g. `--publishers ieee,elsevier,springer` · `--publishers any` (no publisher filter) ·
`--max-quartile 2` (accept Q1–Q2) · `--per-query 40` · `--top-cited 15`

## If something fails
- `ERROR: No Scopus key` or `Scopus refused the request`: tell the student to check `my_keys.env` (and the VPN off campus).
  Never read or print the key yourself.
- "abstracts not available on this network": the search still works; judge relevance from titles, and say so.
- `scopus_search` (the `scopus` MCP server) can test a query's hit count, but papers only come from the script.

Never list a paper that is not in `candidates.csv`.
