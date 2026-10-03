---
name: literature-search
description: Search Scopus and Google Scholar for the research question in 1_topic/research_brief.md and save the 30-40 most important papers to 2_search/papers.csv, with the queries in 2_search/search_log.md. Use after the research brief is written and before any reading or reviewing.
---

# Literature search (step 2)

**Input:** `1_topic/research_brief.md`. If it is still a blank template, stop and say "Run the research-question skill first."
**Output:** `2_search/papers.csv` and `2_search/search_log.md` only.

1. **Write 3–5 queries** from the brief's keywords and synonyms: the method + the application, synonyms, one broad query.
   Show them to the student in one short list before searching.
2. **Scopus** (`scopus_search`, Scopus syntax, e.g. `TITLE-ABS-KEY("model predictive control" AND "autonomous racing")`): collect
   title, authors, year, venue, DOI, citation count.
3. **Google Scholar** (`search_google_scholar_key_words`, about 10 results per query): catches preprints, theses, conference papers.
4. **Merge and remove duplicates:** match by DOI, otherwise by normalised title.
5. **Rank:** relevance 0–3 to the research question first, then citations per year since publication, then recency (favour the last
   5 years, but keep foundational classics). Include 3–5 review/survey papers if they exist.
6. **Keep the top 30–40** (or the number in `my_instructions.md`). Fill `2_search/papers.csv` (keep the header row):
   `rank,title,authors,year,venue,doi,doi_link,citations,source,relevance,why_selected` with `doi_link = https://doi.org/<doi>`.
7. Fill `2_search/search_log.md`: one row per query (database, query, results, kept) and a 2–3 sentence summary.
8. Tell the student: "Download the PDFs you can through the library into `3_papers/pdf/`, named `<rank>_<first-author>_<year>.pdf`
   (e.g. `03_Kabzan_2019.pdf`). Then run the literature-review skill."

Only list papers a tool actually returned. If one database fails, continue with the other and say so.
