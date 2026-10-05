r"""Scopus search limited to Q1 journals of chosen publishers (default: IEEE and Elsevier).

Run it from the AI_Tools folder with the workshop Python:

    ..\.tools\py\Scripts\python.exe .agents\skills\literature-search\scripts\scopus_q1.py search "QUERY" ["QUERY" ...]
    ..\.tools\py\Scripts\python.exe .agents\skills\literature-search\scripts\scopus_q1.py add "10.1109/..." "Exact paper title" ...
    ..\.tools\py\Scripts\python.exe .agents\skills\literature-search\scripts\scopus_q1.py finalize
    ..\.tools\py\Scripts\python.exe .agents\skills\literature-search\scripts\scopus_q1.py selftest

search    Runs each topic query in Scopus with a filter added: journal articles and reviews only, from the chosen
          publishers. Looks up every journal in the Scopus Serial Title API and keeps papers whose journal is in the
          top 25 % (CiteScore percentile >= 75, i.e. Q1) of at least one of its subject areas. Writes
          2_search/candidates.csv (with abstracts) and the table in 2_search/search_log.md.
add       Checks papers found elsewhere (e.g. Google Scholar) by DOI or exact title. Only Q1 papers of the chosen
          publishers are added to candidates.csv.
finalize  Checks 2_search/papers.csv against candidates.csv: refills every metadata column from the Scopus record,
          drops papers that are not candidates, sorts (relevance, citations per year, recency), numbers the ranks
          and fills the "Kept" column of the search log.
selftest  One search and one journal lookup, to check the key.

The Scopus key is read from my_keys.env (SCOPUS_API_KEY, optional SCOPUS_INST_TOKEN). It is never printed.
Standard library only.
"""

import argparse
import csv
import datetime
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]          # .../AI_Tools
SEARCH_DIR = ROOT / "2_search"
CANDIDATES = SEARCH_DIR / "candidates.csv"
PAPERS = SEARCH_DIR / "papers.csv"
LOG = SEARCH_DIR / "search_log.md"
KEYS_FILE = ROOT / "my_keys.env"
API = "https://api.elsevier.com"

CAND_FIELDS = ["id", "title", "authors", "year", "venue", "publisher", "quartile", "percentile", "subject", "doi",
               "volume", "issue", "pages", "citations", "type", "source", "query", "pii", "abstract"]
PAPER_FIELDS = ["rank", "title", "authors", "year", "venue", "publisher", "quartile", "doi", "doi_link", "citations",
                "source", "relevance", "why_selected"]
FROM_CANDIDATE = ["title", "authors", "year", "venue", "publisher", "quartile", "doi", "citations", "source"]

# Scopus query clause and a check on the journal's publisher name, per publisher keyword.
PUBLISHERS = {
    "ieee": ('PUBLISHER("Institute of Electrical and Electronics Engineers") OR PUBLISHER(ieee) OR SRCTITLE(ieee)',
             r"institute of electrical and electronics engineers|\bieee\b", "IEEE"),
    "elsevier": ('PUBLISHER(elsevier) OR PUBLISHER("Cell Press") OR PUBLISHER("Academic Press") OR PUBLISHER(pergamon)',
                 r"elsevier|cell press|academic press|pergamon", "Elsevier"),
}

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")


class ScopusError(Exception):
    pass


# ----------------------------------------------------------------------------------------------- Scopus API
def read_keys():
    keys = {}
    if KEYS_FILE.exists():
        for line in KEYS_FILE.read_text(encoding="utf-8-sig").splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                keys[k.strip()] = v.strip().strip('"').strip("'")
    for k in ("SCOPUS_API_KEY", "SCOPUS_INST_TOKEN"):
        if os.environ.get(k):
            keys[k] = os.environ[k]
    if not keys.get("SCOPUS_API_KEY"):
        raise ScopusError("No Scopus key: put it after SCOPUS_API_KEY= in my_keys.env and save.")
    return keys


class Scopus:
    def __init__(self):
        keys = read_keys()
        self.headers = {"X-ELS-APIKey": keys["SCOPUS_API_KEY"], "Accept": "application/json"}
        if keys.get("SCOPUS_INST_TOKEN"):
            self.headers["X-ELS-Insttoken"] = keys["SCOPUS_INST_TOKEN"]
        self.journals = {}
        self.complete_view = True        # abstracts + all authors; needs campus network, VPN or institution token

    def get(self, path, params):
        url = API + path + "?" + urllib.parse.urlencode(params)
        for attempt in range(5):
            req = urllib.request.Request(url, headers=self.headers)
            try:
                with urllib.request.urlopen(req, timeout=60) as r:
                    return json.load(r)
            except urllib.error.HTTPError as e:
                if e.code == 429:
                    time.sleep(2 * (attempt + 1))
                    continue
                if e.code == 404:
                    return None
                body = e.read().decode("utf-8", "replace")[:300]
                if e.code in (401, 403):
                    raise ScopusError(f"Scopus refused the request (HTTP {e.code}). Check the key in my_keys.env; "
                                      "off campus you need the VPN or an institution token.") from None
                if e.code == 400:
                    raise ScopusError(f"Scopus did not accept the query (HTTP 400): {body}") from None
                time.sleep(2 * (attempt + 1))
            except (urllib.error.URLError, TimeoutError) as e:
                if attempt == 4:
                    raise ScopusError(f"Could not reach Scopus: {e}") from None
                time.sleep(2 * (attempt + 1))
        raise ScopusError("Scopus kept answering 'too many requests'. Wait a minute and run again.")

    def search(self, query, count, sort="relevancy"):
        """Up to `count` results in `sort` order ('relevancy' or '-citedby-count') and the total number of hits."""
        entries, total, start = [], 0, 0
        while start < count:
            n = min(25, count - start)
            params = {"query": query, "count": n, "start": start, "sort": sort,
                      "view": "COMPLETE" if self.complete_view else "STANDARD"}
            try:
                js = self.get("/content/search/scopus", params)
            except ScopusError:
                if not self.complete_view:
                    raise
                self.complete_view = False          # no abstract entitlement: titles and first authors only
                print("  (abstracts not available on this network: continuing without them)")
                continue
            res = (js or {}).get("search-results", {})
            total = int(res.get("opensearch:totalResults") or 0)
            page = [e for e in as_list(res.get("entry")) if "error" not in e]
            entries += page
            start += n
            if len(page) < n or start >= total:
                break
        return entries, total

    def journal(self, issn):
        """Title, publisher, best CiteScore percentile, its subject and the CiteScore year, for one ISSN."""
        issn = (issn or "").replace("-", "").strip()
        if not issn:
            return None
        if issn in self.journals:
            return self.journals[issn]
        js = self.get(f"/content/serial/title/issn/{issn}", {"view": "CITESCORE"})
        time.sleep(0.25)
        info = None
        entry = as_list(((js or {}).get("serial-metadata-response") or {}).get("entry"))
        if entry and "error" not in entry[0]:
            e = entry[0]
            subjects = {s.get("@code"): s.get("$") for s in as_list(e.get("subject-area"))}
            years = as_list((e.get("citeScoreYearInfoList") or {}).get("citeScoreYearInfo"))
            years = sorted(years, key=lambda y: (y.get("@status") == "Complete", y.get("@year", "")), reverse=True)
            best, best_code, year = -1, None, ""
            for y in years[:1]:
                year = y.get("@year", "")
                for lst in as_list(y.get("citeScoreInformationList")):
                    for info_ in as_list(lst.get("citeScoreInfo")):
                        if info_.get("docType", "all") != "all":
                            continue
                        for rank in as_list(info_.get("citeScoreSubjectRank")):
                            p = to_int(rank.get("percentile"))
                            if p is not None and p > best:
                                best, best_code = p, rank.get("subjectCode")
            info = {"title": e.get("dc:title", ""), "publisher": e.get("dc:publisher", ""),
                    "percentile": best if best >= 0 else None, "subject": subjects.get(best_code, ""), "year": year}
        self.journals[issn] = info
        return info


def as_list(x):
    if x is None:
        return []
    return x if isinstance(x, list) else [x]


def to_int(x):
    try:
        return int(str(x).strip())
    except (TypeError, ValueError):
        return None


def quartile(p):
    if p is None:
        return ""
    return "Q1" if p >= 75 else "Q2" if p >= 50 else "Q3" if p >= 25 else "Q4"


def publisher_clause(names):
    if names == ["any"]:
        return ""
    parts = [PUBLISHERS[n][0] if n in PUBLISHERS else f'PUBLISHER("{n}")' for n in names]
    return " AND (" + " OR ".join(parts) + ")"


def publisher_ok(name, names):
    if names == ["any"]:
        return True
    if not name:
        return True                                  # journal record without a publisher: trust the query filter
    return any(re.search(PUBLISHERS[n][1] if n in PUBLISHERS else re.escape(n), name, re.I) for n in names)


def short_publisher(name, names):
    for n in names:
        if n in PUBLISHERS and re.search(PUBLISHERS[n][1], name or "", re.I):
            return PUBLISHERS[n][2]
    return name


def authors_of(e):
    names = []
    for a in as_list(e.get("author")):
        n = a.get("authname") or " ".join(x for x in (a.get("surname"), a.get("initials")) if x)
        if n and n not in names:
            names.append(n)
    if not names and e.get("dc:creator"):
        names = [e["dc:creator"], "et al."]
    return "; ".join(names)


def clean_abstract(text):
    text = re.sub(r"\s+", " ", text or "").strip()
    text = re.sub(r"\s*(©|\(c\)|Copyright).*$", "", text, flags=re.I)        # publisher copyright line at the end
    return text[:1500]


def norm_title(t):
    return re.sub(r"[^a-z0-9]", "", (t or "").lower())


# ----------------------------------------------------------------------------------------------- checking a result
def check_entry(sc, e, names, max_q):
    """(row, None) if the paper passes, else (None, reason)."""
    if (e.get("prism:aggregationType") or "").lower() != "journal":
        return None, f"not a journal ({e.get('prism:aggregationType') or 'unknown'})"
    if e.get("subtype") not in ("ar", "re"):
        return None, f"not an article or review ({e.get('subtypeDescription') or e.get('subtype')})"
    j = sc.journal(e.get("prism:issn")) or sc.journal(e.get("prism:eIssn"))
    if not j or j["percentile"] is None:
        return None, "journal has no CiteScore rank"
    if not publisher_ok(j["publisher"], names):
        return None, f"publisher {j['publisher']} is not one of: {', '.join(names)}"
    q = quartile(j["percentile"])
    if int(q[1]) > max_q:
        return None, f"{q} journal (best CiteScore percentile {j['percentile']} in {j['subject']})"
    doi = (e.get("prism:doi") or "").strip()
    row = {
        "title": (e.get("dc:title") or "").strip(),
        "authors": authors_of(e),
        "year": (e.get("prism:coverDate") or "")[:4],
        "venue": e.get("prism:publicationName") or j["title"],
        "publisher": short_publisher(j["publisher"], names),
        "quartile": q,
        "percentile": j["percentile"],
        "subject": j["subject"],
        "doi": doi,
        "volume": e.get("prism:volume") or "",
        "issue": e.get("prism:issueIdentifier") or "",
        "pages": e.get("prism:pageRange") or e.get("article-number") or "",
        "citations": e.get("citedby-count") or "0",
        "type": e.get("subtypeDescription") or "",
        "pii": e.get("pii") or "",
        "abstract": clean_abstract(e.get("dc:description")),
    }
    return row, None


# ----------------------------------------------------------------------------------------------- files
def read_csv(path):
    if not path.exists():
        return []
    with path.open(encoding="utf-8-sig", newline="") as f:
        return [r for r in csv.DictReader(f) if any((v or "").strip() for v in r.values() if isinstance(v, str))]


def write_csv(path, fields, rows):
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
        w.writeheader()
        for r in rows:
            w.writerow({k: r.get(k, "") for k in fields})


def key_of(row):
    return (row.get("doi") or "").lower().strip() or norm_title(row.get("title"))


LOG_HEAD = "| # | Database | Query | Results | Q1 candidates | Kept |\n|---|---|---|---|---|---|\n"


def write_log(rows, filter_text):
    body = "".join(f"| {r['n']} | {r['db']} | `{r['query']}` | {r['results']} | {r['cands']} | {r.get('kept', '')} |\n"
                   for r in rows)
    old = LOG.read_text(encoding="utf-8") if LOG.exists() else ""
    m = re.search(r"\*\*Summary:\*\*.*", old, re.S)
    summary = m.group(0) if m and "[how many" not in m.group(0) else \
        "**Summary:** [2–3 sentences: how many found, how many kept, main themes noticed]"
    LOG.write_text("# Search log\n\n<!-- Written by scopus_q1.py (literature-search skill). The agent writes the summary. -->\n\n"
                   f"**Filter on every Scopus query:** {filter_text}\n\n" + LOG_HEAD + body + "\n" + summary.strip() + "\n",
                   encoding="utf-8")


def read_log_rows():
    rows = []
    if LOG.exists():
        for line in LOG.read_text(encoding="utf-8").splitlines():
            m = re.match(r"\|\s*(G?\d+)\s*\|\s*(.*?)\s*\|\s*`(.*)`\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|\s*$", line)
            if m:
                rows.append(dict(zip(["n", "db", "query", "results", "cands", "kept"], m.groups())))
    return rows


def read_filter_text():
    if LOG.exists():
        m = re.search(r"\*\*Filter on every Scopus query:\*\*\s*(.*)", LOG.read_text(encoding="utf-8"))
        if m:
            return m.group(1).strip()
    return ""


def describe_filter(names, max_q, since):
    pubs = "any publisher" if names == ["any"] else " or ".join(PUBLISHERS[n][2] if n in PUBLISHERS else n for n in names)
    qs = "Q1" if max_q == 1 else f"Q1–Q{max_q}"
    years = f", published {since} or later" if since else ""
    return (f"journal articles and reviews from {pubs}{years}; journal must be {qs} by CiteScore percentile "
            "(Scopus Serial Title API, best subject area)")


# ----------------------------------------------------------------------------------------------- commands
def cmd_search(a):
    names = [n.strip().lower() for n in a.publishers.split(",") if n.strip()]
    sc = Scopus()
    extra = " AND SRCTYPE(j) AND DOCTYPE(ar OR re)" + publisher_clause(names)
    if a.since:
        extra += f" AND PUBYEAR > {a.since - 1}"
    cands, log_rows, reasons = {}, [], Counter()
    for i, q in enumerate(a.queries, 1):
        q = q.strip()
        full = f"({q}){extra}"
        print(f"\n[{i}/{len(a.queries)}] {q}")
        entries, total = sc.search(full, a.per_query)
        if a.top_cited:                                # the most cited papers too, so classics are not missed
            seen = {e.get("eid") for e in entries}
            entries += [e for e in sc.search(full, a.top_cited, "-citedby-count")[0] if e.get("eid") not in seen]
        kept = 0
        for e in entries:
            row, why = check_entry(sc, e, names, a.max_quartile)
            if not row:
                reasons[re.sub(r" \(.*", "", why)] += 1
                continue
            k = key_of(row)
            if k in cands:
                cands[k]["query"] += f";{i}"
            else:
                row["source"], row["query"] = "Scopus", str(i)
                cands[k] = row
            kept += 1
        print(f"  {total} results in Scopus with the filter; checked {len(entries)} (most relevant + most cited); "
              f"{kept} in Q1 journals")
        log_rows.append({"n": i, "db": "Scopus", "query": q, "results": total, "cands": kept})
    rows = list(cands.values())
    for n, r in enumerate(rows, 1):
        r["id"] = f"c{n:03d}"
    write_csv(CANDIDATES, CAND_FIELDS, rows)
    write_log(log_rows, describe_filter(names, a.max_quartile, a.since))
    summarise(rows, reasons)
    print(f"\nWrote {CANDIDATES.relative_to(ROOT)} ({len(rows)} candidate papers) and {LOG.relative_to(ROOT)}.")
    if len(rows) < 40:
        print("Fewer than 40 candidates: broaden the queries (synonyms, fewer AND terms, more years) and search again,"
              " or check papers from Google Scholar with the 'add' command.")


def cmd_add(a):
    names = [n.strip().lower() for n in a.publishers.split(",") if n.strip()]
    sc = Scopus()
    rows = read_csv(CANDIDATES)
    have = {key_of(r): r for r in rows}
    next_id = max([int(r["id"][1:]) for r in rows if (r.get("id") or "").startswith("c") and r["id"][1:].isdigit()] + [0]) + 1
    log = read_log_rows()
    label = f"G{sum(1 for r in log if r['n'].startswith('G')) + 1}"
    added = 0
    for item in a.items:
        item = item.strip()
        doi = re.sub(r"^(https?://(dx\.)?doi\.org/|doi:\s*)", "", item, flags=re.I)
        q = f'DOI("{doi}")' if doi.startswith("10.") else f'TITLE("{item.replace(chr(34), "")}")'
        entries, _ = sc.search(q, 3)
        if not entries:
            print(f"- NOT IN SCOPUS: {item}")
            continue
        e = entries[0]
        row, why = check_entry(sc, e, names, a.max_quartile)
        title = e.get("dc:title", item)
        if not row:
            print(f"- REJECTED ({why}): {title}")
            continue
        if key_of(row) in have:
            print(f"- already a candidate ({have[key_of(row)]['id']}): {title}")
            continue
        row["id"], row["source"], row["query"] = f"c{next_id:03d}", f"{a.source} (checked in Scopus)", label
        rows.append(row)
        have[key_of(row)] = row
        next_id += 1
        added += 1
        print(f"- ADDED {row['id']} ({row['quartile']}, {row['venue']}): {title}")
    write_csv(CANDIDATES, CAND_FIELDS, rows)
    log.append({"n": label, "db": f"{a.source} → Scopus check", "query": a.query or "papers checked by DOI/title",
                "results": len(a.items), "cands": added})
    write_log(log, read_filter_text() or describe_filter(names, a.max_quartile, None))
    print(f"\n{added} of {len(a.items)} added. {CANDIDATES.relative_to(ROOT)} now has {len(rows)} candidates.")


def cmd_finalize(a):
    cands = read_csv(CANDIDATES)
    if not cands:
        raise ScopusError("2_search/candidates.csv is empty: run the 'search' command first.")
    by_key = {key_of(c): c for c in cands}
    by_title = {norm_title(c["title"]): c for c in cands}
    picked, problems, seen = [], [], set()
    for r in read_csv(PAPERS):
        c = by_key.get((r.get("doi") or "").lower().strip()) or by_title.get(norm_title(r.get("title")))
        if not c:
            problems.append(f"removed (not a Q1 candidate, check it with 'add' first): {r.get('title') or r.get('doi')}")
            continue
        if key_of(c) in seen:
            problems.append(f"removed duplicate: {c['title']}")
            continue
        seen.add(key_of(c))
        row = {k: c.get(k, "") for k in FROM_CANDIDATE}
        row["doi_link"] = f"https://doi.org/{c['doi']}" if c.get("doi") else ""
        row["relevance"] = (r.get("relevance") or "").strip()
        row["why_selected"] = (r.get("why_selected") or "").strip()
        row["_query"], row["type"] = c.get("query", ""), c.get("type", "")
        if to_int(row["relevance"]) is None:
            problems.append(f"no relevance score (0-3) for: {c['title']}")
        elif to_int(row["relevance"]) < 2:
            problems.append(f"relevance {row['relevance']} (keep only 2-3?): {c['title']}")
        picked.append(row)
    this_year = datetime.date.today().year

    def order(r):
        cites, year = to_int(r["citations"]) or 0, to_int(r["year"]) or 1900
        return (-(to_int(r["relevance"]) or 0), -cites / max(1, this_year - year + 1), -year)

    picked.sort(key=order)
    if a.keep and len(picked) > a.keep:
        problems.append(f"kept the top {a.keep} of {len(picked)}")
        picked = picked[:a.keep]
    for n, r in enumerate(picked, 1):
        r["rank"] = n
    write_csv(PAPERS, PAPER_FIELDS, picked)
    log = read_log_rows()
    if log:
        for row in log:
            row["kept"] = sum(1 for p in picked if row["n"] in p["_query"].split(";"))
        write_log(log, read_filter_text())
    for p in problems:
        print("! " + p)
    summarise(picked, {})
    print(f"\n{PAPERS.relative_to(ROOT)}: {len(picked)} papers, ranked 1-{len(picked)}. Search log 'Kept' column updated.")


def cmd_selftest(a):
    sc = Scopus()
    entries, total = sc.search('TITLE-ABS-KEY("battery thermal management") AND SRCTYPE(j)', 1)
    j = sc.journal("0378-7753")
    if not total or not j or j["percentile"] is None:
        raise ScopusError("Scopus answered, but without search results or journal metrics.")
    print(f"OK: Scopus search ({total} results for a test query) and journal metrics "
          f"(Journal of Power Sources: {quartile(j['percentile'])}, CiteScore {j['year']}); "
          f"abstracts {'available' if sc.complete_view else 'NOT available on this network'}.")


def summarise(rows, reasons):
    if reasons:
        print("\nLeft out: " + "; ".join(f"{n} {why}" for why, n in reasons.most_common()))
    if not rows:
        return

    def count(k):
        return ", ".join(f"{n} {v}" for v, n in Counter(r.get(k) or "?" for r in rows).most_common())

    years = sorted(to_int(r.get("year")) or 0 for r in rows)
    print(f"Publishers: {count('publisher')} | Types: {count('type')} | Years {years[0]}-{years[-1]}")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--publishers", default="ieee,elsevier",
                        help="comma-separated: ieee, elsevier, or any other publisher name; 'any' = no publisher filter")
    common.add_argument("--max-quartile", type=int, default=1, choices=[1, 2, 3, 4], help="1 = Q1 only (default)")
    s = sub.add_parser("search", parents=[common], help="run topic queries in Scopus")
    s.add_argument("queries", nargs="+", help='topic queries in Scopus syntax, e.g. TITLE-ABS-KEY("immersion cooling" AND battery)')
    s.add_argument("--since", type=int, help="first publication year to include, e.g. 2020")
    s.add_argument("--per-query", type=int, default=40, help="most relevant results checked per query (default 40)")
    s.add_argument("--top-cited", type=int, default=15, help="most cited results also checked per query (default 15)")
    ad = sub.add_parser("add", parents=[common], help="check papers found elsewhere by DOI or exact title")
    ad.add_argument("items", nargs="+")
    ad.add_argument("--source", default="Google Scholar")
    ad.add_argument("--query", help="the query that found them, for the search log")
    f = sub.add_parser("finalize", help="check, complete and rank 2_search/papers.csv")
    f.add_argument("--keep", type=int, help="keep at most this many papers")
    sub.add_parser("selftest", help="check the key, search and journal metrics")
    a = p.parse_args()
    try:
        {"search": cmd_search, "add": cmd_add, "finalize": cmd_finalize, "selftest": cmd_selftest}[a.cmd](a)
    except ScopusError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
