r"""PDF -> Markdown for the literature review, with Docling (IBM's open-source document converter).

Run it from the AI_Tools folder with the workshop Python:

    ..\.tools\py\Scripts\python.exe .agents\skills\literature-review\scripts\pdf_to_text.py [--force] [--fast]

1. Converts every PDF in 3_papers/pdf/ that has no up-to-date 3_papers/text/<same name>.md yet. Docling keeps headings,
   paragraphs and tables (as Markdown tables); images become <!-- image --> placeholders. No OCR: journal PDFs have text.
2. Matches each text to its paper in 2_search/papers.csv: by the rank at the start of the file name (03_Kabzan_2019.pdf),
   the ScienceDirect PII in the file name (1-s2.0-S0196890423003990-main.pdf), the DOI on the first page, or the title.
   Writes 3_papers/text/index.csv and lists the papers that have no PDF (abstract-only).

--force  convert again even if the text exists      --fast  faster, less accurate table recognition
If Docling is not installed, MarkItDown is used instead (lower quality: words can run together).
"""

import argparse
import csv
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]          # .../AI_Tools
TOOLS = ROOT.parent / ".tools"
PDF_DIR = ROOT / "3_papers" / "pdf"
TEXT_DIR = ROOT / "3_papers" / "text"
INDEX = TEXT_DIR / "index.csv"
PAPERS = ROOT / "2_search" / "papers.csv"
CANDIDATES = ROOT / "2_search" / "candidates.csv"
MODELS = TOOLS / "docling-models"

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def find_exe(name, *dirs):
    for d in dirs:
        exe = Path(d) / f"{name}.exe"
        if exe.exists():
            return exe
    return None


def convert_docling(exe, pdfs, fast):
    cmd = [str(exe), *map(str, pdfs), "--to", "md", "--output", str(TEXT_DIR), "--no-ocr",
           "--image-export-mode", "placeholder", "--table-mode", "fast" if fast else "accurate"]
    env = dict(os.environ, PYTHONIOENCODING="utf-8")
    if MODELS.exists():                       # models downloaded by setup: work offline
        cmd += ["--artifacts-path", str(MODELS)]
        env["HF_HUB_OFFLINE"] = "1"
    print(f"Docling: converting {len(pdfs)} PDF(s), about 1-2 s per page...\n", flush=True)
    subprocess.run(cmd, env=env)


def convert_markitdown(exe, pdfs):
    print(f"Docling is not installed: using MarkItDown for {len(pdfs)} PDF(s) (check the text: words may run together).")
    for pdf in pdfs:
        subprocess.run([str(exe), str(pdf), "-o", str(TEXT_DIR / f"{pdf.stem}.md")])


def read_csv(path):
    if not path.exists():
        return []
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def norm(t):
    return re.sub(r"[^a-z0-9]", "", (t or "").lower())


def match(md, papers, pii_to_rank):
    """(rank, how) for one converted text, or (None, '')."""
    by_rank = {p["rank"].strip(): p for p in papers if (p.get("rank") or "").strip()}
    m = re.match(r"0*(\d{1,3})_[^\W\d_]", md.name)            # <rank>_<first-author>_<year>.pdf
    if m and m.group(1) in by_rank:
        return m.group(1), "file name"
    for pii in re.findall(r"S[0-9]{7}[0-9X][0-9]{7}[0-9X]", md.name, re.I):
        if pii.upper() in pii_to_rank:
            return pii_to_rank[pii.upper()], "PII in file name"
    head = md.read_text(encoding="utf-8", errors="replace")[:10000]
    dois = {d.rstrip(".,;)").lower() for d in re.findall(r"10\.\d{4,9}/[^\s\"<>|\]]+", head)}
    for p in papers:
        if (p.get("doi") or "").lower().strip() in dois:
            return p["rank"], "DOI"
    flat = norm(head)
    for p in papers:
        t = norm(p.get("title"))
        if len(t) > 20 and t[:80] in flat:
            return p["rank"], "title"
    return None, ""


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--force", action="store_true", help="convert again even if the text exists")
    ap.add_argument("--fast", action="store_true", help="faster, less accurate tables")
    a = ap.parse_args()

    pdfs = sorted(PDF_DIR.glob("*.pdf"), key=lambda p: p.name.lower())
    if not pdfs:
        print("No PDFs in 3_papers/pdf/: download the papers you can through the library and put them there first.")
        sys.exit(1)
    TEXT_DIR.mkdir(parents=True, exist_ok=True)
    todo = [p for p in pdfs if a.force or not (TEXT_DIR / f"{p.stem}.md").exists()
            or (TEXT_DIR / f"{p.stem}.md").stat().st_mtime < p.stat().st_mtime]
    if todo:
        docling = find_exe("docling", Path(sys.executable).parent, TOOLS / "py" / "Scripts")
        markitdown = find_exe("markitdown", TOOLS / "mcp" / "markitdown" / ".venv" / "Scripts")
        if docling:
            convert_docling(docling, todo, a.fast)
        elif markitdown:
            convert_markitdown(markitdown, todo)
        else:
            print("Neither Docling nor MarkItDown is installed: run the workshop setup again.")
            sys.exit(1)
    else:
        print(f"All {len(pdfs)} PDFs already have a text in 3_papers/text/ (use --force to convert again).")

    papers = [p for p in read_csv(PAPERS) if (p.get("rank") or "").strip()]
    doi_to_rank = {(p.get("doi") or "").lower().strip(): p["rank"] for p in papers}
    pii_to_rank = {(c.get("pii") or "").upper(): doi_to_rank[(c.get("doi") or "").lower().strip()]
                   for c in read_csv(CANDIDATES) if c.get("pii") and (c.get("doi") or "").lower().strip() in doi_to_rank}
    titles = {p["rank"]: p.get("title", "") for p in papers}
    rows, failed = [], []
    for pdf in pdfs:
        md = TEXT_DIR / f"{pdf.stem}.md"
        if not md.exists() or md.stat().st_size < 500:
            failed.append(pdf.name)
            continue
        rank, how = match(md, papers, pii_to_rank)
        rows.append({"file": md.name, "pdf": pdf.name, "rank": rank or "", "title": titles.get(rank, ""), "matched_by": how})
    rows.sort(key=lambda r: (not r["rank"], int(r["rank"]) if r["rank"] else 0, r["file"]))
    with INDEX.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["file", "pdf", "rank", "title", "matched_by"])
        w.writeheader()
        w.writerows(rows)

    print(f"\n{len(rows)} texts in 3_papers/text/ (index: 3_papers/text/index.csv)")
    for r in rows:
        print(f"  [{r['rank'] or '?':>2}] {r['file']}" + (f"  <- {r['matched_by']}" if r["rank"] else "  NOT MATCHED to papers.csv"))
    for name in failed:
        print(f"  FAILED: {name} (no text; is the PDF a scan or damaged?)")
    with_pdf = {r["rank"] for r in rows if r["rank"]}
    missing = [p["rank"] for p in papers if p["rank"] not in with_pdf]
    print(f"\nFull text: {len(with_pdf)} of {len(papers)} papers. Abstract-only: "
          + (", ".join(f"[{r}]" for r in missing) if missing else "none"))


if __name__ == "__main__":
    main()
