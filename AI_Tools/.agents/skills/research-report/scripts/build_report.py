r"""Build the IEEE-format report (LaTeX, IEEEtran class) from 6_report/report.md, ready to open in Overleaf.

Run it from the AI_Tools folder with the workshop Python:

    ..\.tools\py\Scripts\python.exe .agents\skills\research-report\scripts\build_report.py [--open]

Reads 6_report/report.md (front matter + Markdown; papers cited as [rank] from 2_search/papers.csv) and writes
    6_report/overleaf/main.tex          IEEE conference paper, two columns
    6_report/overleaf/references.bib    the cited papers only; IEEE numbers them in order of first citation
    6_report/overleaf/figures/          the figure(s) used in the report
    6_report/report_overleaf.zip        the same files, for Overleaf > New Project > Upload Project
    6_report/open_in_overleaf.html      double-click it: one button opens and compiles the report in Overleaf
It stops with a clear message if the report cites a paper that is not in papers.csv, a figure file is missing,
or the proposal's figure is not used. No LaTeX is needed on this computer (Overleaf compiles it). --open opens the
HTML page in the browser.
"""

import argparse
import base64
import csv
import html
import re
import shutil
import struct
import sys
import unicodedata
import webbrowser
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]          # .../AI_Tools
REPORT_DIR = ROOT / "6_report"
SOURCE = REPORT_DIR / "report.md"
OUT = REPORT_DIR / "overleaf"
ZIP = REPORT_DIR / "report_overleaf.zip"
HTML = REPORT_DIR / "open_in_overleaf.html"
PAPERS = ROOT / "2_search" / "papers.csv"
CANDIDATES = ROOT / "2_search" / "candidates.csv"
FIGURE_DIR = ROOT / "5_proposal" / "figure"

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

warnings = []


class BuildError(Exception):
    pass


# =============================================================================================== characters
GREEK = dict(zip("αβγδεζηθικλμνξπρστυφχψωΓΔΘΛΞΠΣΥΦΨΩ",
                 "alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu nu xi pi rho sigma tau upsilon "
                 "phi chi psi omega Gamma Delta Theta Lambda Xi Pi Sigma Upsilon Phi Psi Omega".split()))
MATH_SYMBOLS = {
    "≥": r"\geq", "≤": r"\leq", "≈": r"\approx", "≠": r"\neq", "±": r"\pm", "∓": r"\mp", "×": r"\times",
    "÷": r"\div", "·": r"\cdot", "⋅": r"\cdot", "∙": r"\cdot", "∆": r"\Delta", "µ": r"\mu", "ϵ": r"\epsilon",
    "ϕ": r"\phi", "ς": r"\varsigma", "Ω": r"\Omega", "→": r"\rightarrow", "←": r"\leftarrow",
    "↔": r"\leftrightarrow", "⇒": r"\Rightarrow", "⇔": r"\Leftrightarrow", "↑": r"\uparrow", "↓": r"\downarrow",
    "∞": r"\infty", "√": r"\surd", "∝": r"\propto", "∂": r"\partial", "∑": r"\sum", "∏": r"\prod", "∫": r"\int",
    "≪": r"\ll", "≫": r"\gg", "∈": r"\in", "∉": r"\notin", "∼": r"\sim", "≃": r"\simeq", "≅": r"\cong",
    "≡": r"\equiv", "∇": r"\nabla", "∀": r"\forall", "∃": r"\exists", "∩": r"\cap", "∪": r"\cup", "⊂": r"\subset",
    "⊆": r"\subseteq", "∠": r"\angle", "⊥": r"\perp", "∥": r"\parallel", "′": r"\prime", "″": r"\prime\prime",
    "−": "-", "∕": "/",
}
MATH_SYMBOLS.update({k: "\\" + v for k, v in GREEK.items()})
SUPER = dict(zip("⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻", "0123456789+-"))
SUB = dict(zip("₀₁₂₃₄₅₆₇₈₉₊₋", "0123456789+-"))
TEXT_SYMBOLS = {
    "°": r"\textdegree{}", "–": "--", "—": "---", "‘": "`", "’": "'", "‚": ",", "“": "``", "”": "''", "„": ",,",
    "…": r"\ldots{}", "•": r"\textbullet{}", "€": r"\texteuro{}", "™": r"\texttrademark{}", "®": r"\textregistered{}",
    "©": r"\textcopyright{}", "‰": r"\textperthousand{}", "§": r"\S{}", "†": r"\textdagger{}", "‡": r"\textdaggerdbl{}",
    "\u00a0": "~", "\u2009": r"\,", "\u202f": r"\,", "\u2002": " ", "\u2003": " ", "\u2010": "-", "\u2011": "-",
    "\u200b": "", "\ufeff": "", "\u00ad": "", "√": r"\ensuremath{\surd}",
}
TEXT_ESCAPES = {"\\": r"\textbackslash{}", "{": r"\{", "}": r"\}", "&": r"\&", "%": r"\%", "#": r"\#", "_": r"\_",
                "$": r"\$", "^": r"\textasciicircum{}", "~": r"\ensuremath{\sim}", "<": r"\textless{}",
                ">": r"\textgreater{}", "|": r"\textbar{}"}


def tex_char(ch):
    """One character of running text as LaTeX that pdfLaTeX (Overleaf's default) can typeset."""
    if ch in TEXT_ESCAPES:
        return TEXT_ESCAPES[ch]
    if ord(ch) < 128 or ch in "\x00\x01\x02\x03\x04":
        return ch
    if ch in TEXT_SYMBOLS:
        return TEXT_SYMBOLS[ch]
    if ch in MATH_SYMBOLS:
        return r"\ensuremath{" + MATH_SYMBOLS[ch] + "}"
    if ch in SUPER:
        return r"\textsuperscript{" + SUPER[ch] + "}"
    if ch in SUB:
        return r"\textsubscript{" + SUB[ch] + "}"
    if 0xC0 <= ord(ch) <= 0x17F and unicodedata.category(ch).startswith("L"):
        return ch                                     # accented Latin letters: fine with utf8 + T1
    plain = unicodedata.normalize("NFKD", ch).encode("ascii", "ignore").decode()
    if plain:
        return tex_text(plain)
    warnings.append(f"character {ch!r} (U+{ord(ch):04X}) cannot be typeset; replaced by '?'")
    return "?"


def tex_text(s):
    return "".join(tex_char(c) for c in s)


def tex_math(s):
    """Inside $...$: keep LaTeX as written, turn Unicode symbols into commands."""
    out = []
    for ch in s:
        if ch in MATH_SYMBOLS:
            cmd = MATH_SYMBOLS[ch]
            out.append(cmd + (" " if cmd.startswith("\\") else ""))
        elif ch == "°":
            out.append(r"^{\circ}")
        elif ch in SUPER:
            out.append("^{" + SUPER[ch] + "}")
        elif ch in SUB:
            out.append("_{" + SUB[ch] + "}")
        elif ord(ch) > 127:
            out.append(r"\text{" + tex_text(ch) + "}")
        else:
            out.append(ch)
    return "".join(out)


def url_arg(u):
    return u.replace("\\", "/").replace("%", r"\%").replace("#", r"\#").replace("{", "%7B").replace("}", "%7D")


# =============================================================================================== inline Markdown
MATH_RE = re.compile(r"(?<![\\$\w])\$(?=\S)([^$\n]+?)(?<=\S)\$(?![\d$])")
CITE_RE = re.compile(r"( ?)\[(\s*\d+\s*(?:[-–—]\s*\d+\s*)?(?:[,;]\s*\d+\s*(?:[-–—]\s*\d+\s*)?)*)\](?!\()")


class Inline:
    def __init__(self, ranks):
        self.ranks = ranks          # rank (str) -> True for papers in papers.csv
        self.cited = []             # ranks in order of first citation
        self.unknown = set()

    def cite(self, inner):
        keys = []
        for part in re.split(r"[,;]", inner):
            m = re.fullmatch(r"\s*(\d+)\s*(?:[-–—]\s*(\d+)\s*)?", part)
            a, b = int(m.group(1)), int(m.group(2) or m.group(1))
            for n in range(a, min(b, a + 30) + 1):
                if str(n) not in self.ranks:
                    self.unknown.add(n)
                    continue
                if str(n) not in self.cited:
                    self.cited.append(str(n))
                keys.append(f"r{n}")
        return r"\cite{" + ",".join(keys) + "}" if keys else "[?]"

    def __call__(self, s):
        tokens = []

        def keep(tex):
            tokens.append(tex)
            return f"\x00{len(tokens) - 1}\x00"

        s = s.replace(r"\$", keep(r"\$"))
        s = re.sub(r"`([^`]+)`", lambda m: keep(r"\texttt{" + tex_text(m.group(1)) + "}"), s)
        s = MATH_RE.sub(lambda m: keep("$" + tex_math(m.group(1)) + "$"), s)
        s = re.sub(r"\\([*_`\[\]#|])", lambda m: keep(tex_text(m.group(1))), s)          # Markdown escapes
        s = re.sub(r"!\[[^\]]*\]\([^)]*\)", "", s)                                          # stray images
        s = re.sub(r"\[([^\]]+)\]\((https?://[^)\s]+)\)",
                   lambda m: keep(r"\href{" + url_arg(m.group(2)) + "}{" + self(m.group(1)) + "}"), s)
        s = CITE_RE.sub(lambda m: keep(("~" if m.group(1) else "") + self.cite(m.group(2))), s)
        s = re.sub(r"(?<![\w/])(https?://[^\s<>()]*[^\s<>().,;:])", lambda m: keep(r"\url{" + url_arg(m.group(1)) + "}"), s)
        s = re.sub(r"</?(br|sup|sub|span|div|p)[^>]*>", " ", s)
        s = re.sub(r'(?<!\w)"(?=\S)([^"\n]+?)(?<=\S)"', "\x05\\1\x06", s)                   # "quotes"
        s = re.sub(r"\*\*(?=\S)(.+?)(?<=\S)\*\*", "\x01\\1\x02", s)
        s = re.sub(r"(?<!\w)__(?=\S)(.+?)(?<=\S)__(?!\w)", "\x01\\1\x02", s)
        s = re.sub(r"(?<![\w*])\*(?=\S)(.+?)(?<=\S)\*(?![\w*])", "\x03\\1\x04", s)
        s = re.sub(r"(?<![\w_])_(?=\S)(.+?)(?<=\S)_(?![\w_])", "\x03\\1\x04", s)
        s = tex_text(s)
        for a, b in (("\x01", r"\textbf{"), ("\x02", "}"), ("\x03", r"\emph{"), ("\x04", "}"), ("\x05", "``"), ("\x06", "''")):
            s = s.replace(a, b)
        while "\x00" in s:
            s = re.sub(r"\x00(\d+)\x00", lambda m: tokens[int(m.group(1))], s)
        return s


# =============================================================================================== Markdown blocks
LIST_RE = re.compile(r"^(\s*)([-*+]|\d{1,2}[.)])\s+(.*)$")
TABLE_SEP_RE = re.compile(r"^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?\s*$")
CAPTION_RE = re.compile(r"^\**\s*Table\s*[IVX\d]*\s*[:.]\s*\**\s*(.+?)\s*$", re.I)
IMAGE_RE = re.compile(r'^!\[(.*?)\]\(\s*<?([^)>"]+?)>?(?:\s+"[^"]*")?\s*\)$')


def indent(line):
    return len(line.expandtabs(4)) - len(line.expandtabs(4).lstrip())


def starts_block(line):
    s = line.strip()
    return (s.startswith("#") or s.startswith("|") or s.startswith("$$") or bool(LIST_RE.match(line))
            or bool(IMAGE_RE.match(s)) or bool(CAPTION_RE.match(s)) or s.startswith(">"))


def split_row(line):
    s = line.strip()
    s = s[1:] if s.startswith("|") else s
    s = s[:-1] if s.endswith("|") and not s.endswith(r"\|") else s
    return [c.strip().replace(r"\|", "|") for c in re.split(r"(?<!\\)\|", s)]


def parse_list(lines, i, base):
    items, ordered = [], None
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            j = i + 1
            while j < len(lines) and not lines[j].strip():
                j += 1
            if j < len(lines) and LIST_RE.match(lines[j]) and indent(lines[j]) >= base:
                i = j
                continue
            if j < len(lines) and items and indent(lines[j]) > base and not LIST_RE.match(lines[j]):
                i = j                                                    # indented paragraph inside an item
                continue
            break
        m, ind = LIST_RE.match(line), indent(line)
        if m and ind < base:
            break
        if m and ind <= base + 1:
            if ordered is None:
                ordered = m.group(2)[0].isdigit()
            items.append([m.group(3).strip(), None])
            i += 1
        elif m and items:
            sub, i = parse_list(lines, i, ind)
            items[-1][1] = sub
        elif items and (ind > base or not starts_block(line)):
            items[-1][0] += " " + line.strip()
            i += 1
        else:
            break
    return ("list", ordered, items), i


def parse_blocks(text):
    lines, blocks, i = text.splitlines(), [], 0
    caption = None
    while i < len(lines):
        line, s = lines[i], lines[i].strip()
        if not s or re.fullmatch(r"(-{3,}|\*{3,}|_{3,})", s):
            i += 1
            continue
        m = re.match(r"^(#{1,6})\s+(.*?)\s*#*$", s)
        if m:
            blocks.append(("h", len(m.group(1)), m.group(2)))
            i += 1
            continue
        if s.startswith("$$"):
            body = s[2:]
            if body.rstrip().endswith("$$"):
                body, i = body.rstrip()[:-2], i + 1
            else:
                parts, i = [body], i + 1
                while i < len(lines) and "$$" not in lines[i]:
                    parts.append(lines[i])
                    i += 1
                if i < len(lines):
                    parts.append(lines[i].split("$$")[0])
                    i += 1
                body = "\n".join(parts)
            blocks.append(("math", body.strip()))
            continue
        m = CAPTION_RE.match(s)
        if m:
            if blocks and blocks[-1][0] == "table" and not blocks[-1][1]:
                blocks[-1] = ("table", m.group(1)) + blocks[-1][2:]
            else:
                caption = m.group(1)
            i += 1
            continue
        if s.startswith("|") and i + 1 < len(lines) and TABLE_SEP_RE.match(lines[i + 1]):
            header, rows, i = split_row(s), [], i + 2
            while i < len(lines) and lines[i].strip().startswith("|"):
                rows.append(split_row(lines[i]))
                i += 1
            blocks.append(("table", caption or "", header, rows))
            caption = None
            continue
        m = IMAGE_RE.match(s)
        if m:
            blocks.append(("figure", m.group(1).strip(), m.group(2).strip()))
            i += 1
            continue
        if LIST_RE.match(line):
            block, i = parse_list(lines, i, indent(line))
            blocks.append(block)
            continue
        quote = s.startswith(">")
        para = []
        while i < len(lines) and lines[i].strip() and (not para or not starts_block(lines[i]) or (quote and lines[i].strip().startswith(">"))):
            para.append(lines[i].strip().lstrip(">").strip() if quote else lines[i].strip())
            i += 1
        blocks.append(("quote" if quote else "p", " ".join(para)))
    return blocks


# =============================================================================================== LaTeX
SPECIAL = {"abstract": "abstract", "index terms": "keywords", "keywords": "keywords", "references": "skip",
           "bibliography": "skip", "reference list": "skip"}
UNNUMBERED = re.compile(r"^(acknowledg|use of ai|ai use|declaration|statement on|disclosure)", re.I)


def clean_heading(h):
    h = re.sub(r"^\s*(?:[IVXLC]+|\d+(?:\.\d+)*|[A-Z])[.)]\s+", "", h)        # numbering: IEEEtran adds its own
    return h.strip().strip("*").strip()


def png_size(path):
    try:
        with open(path, "rb") as f:
            head = f.read(24)
        if head[:8] == b"\x89PNG\r\n\x1a\n":
            return struct.unpack(">II", head[16:24])
    except OSError:
        pass
    return None


class Renderer:
    def __init__(self, inline):
        self.inline = inline
        self.figures = []           # (source path, name in figures/)
        self.tables = 0

    def list_(self, ordered, items, depth=0):
        env = "enumerate" if ordered else "itemize"
        out = [r"\begin{" + env + "}"]
        for text, sub in items:
            out.append(r"\item " + self.inline(text))
            if sub:
                out.append(self.list_(sub[1], sub[2], depth + 1))
        out.append(r"\end{" + env + "}")
        return "\n".join(out)

    def table(self, caption, header, rows):
        self.tables += 1
        ncol = max([len(header)] + [len(r) for r in rows])
        header = header + [""] * (ncol - len(header))
        rows = [r + [""] * (ncol - len(r)) for r in rows]
        lengths = [max(4, min(60, sum(len(r[c]) for r in rows + [header]) / (len(rows) + 1))) for c in range(ncol)]
        wide = sum(lengths) > 55 or ncol > 3
        widths = [ncol * l / sum(lengths) for l in lengths]
        cols = "".join(r">{\raggedright\arraybackslash\hsize=%.3f\hsize}X" % w for w in widths)
        env, width = ("table*", r"\textwidth") if wide else ("table", r"\columnwidth")
        body = [r"\begin{" + env + "}[!t]", r"\caption{" + self.inline(caption or "Comparison of approaches") + "}",
                r"\label{tab:%d}" % self.tables, r"\centering", r"\footnotesize", r"\renewcommand{\arraystretch}{1.2}",
                r"\begin{tabularx}{" + width + "}{@{}" + cols + "@{}}", r"\toprule",
                " & ".join(r"\textbf{" + self.inline(h) + "}" for h in header) + r" \\", r"\midrule"]
        body += [" & ".join(self.inline(c) for c in r) + r" \\" for r in rows]
        body += [r"\bottomrule", r"\end{tabularx}", r"\end{" + env + "}"]
        return "\n".join(body)

    def figure(self, caption, ref):
        path = find_figure(ref)
        name = f"figure{len(self.figures) + 1}{path.suffix.lower()}"
        self.figures.append((path, name))
        size = png_size(path)
        wide = not size or size[0] / max(1, size[1]) >= 1.3
        env, width = ("figure*", r"\textwidth") if wide else ("figure", r"\columnwidth")
        if not caption:
            warnings.append(f"figure {ref} has no caption: write one inside ![...]")
        return "\n".join([r"\begin{" + env + "}[!t]", r"\centering",
                          r"\includegraphics[width=" + width + r",height=0.42\textheight,keepaspectratio]{figures/" + name + "}",
                          r"\caption{" + self.inline(caption) + "}", r"\label{fig:%d}" % len(self.figures), r"\end{" + env + "}"])

    def blocks(self, blocks):
        out = []
        for b in blocks:
            kind = b[0]
            if kind == "p":
                out.append(self.inline(b[1]))
            elif kind == "quote":
                out.append(r"\begin{quote}" + self.inline(b[1]) + r"\end{quote}")
            elif kind == "list":
                out.append(self.list_(b[1], b[2]))
            elif kind == "table":
                out.append(self.table(b[1], b[2], b[3]))
            elif kind == "figure":
                out.append(self.figure(b[1], b[2]))
            elif kind == "math":
                out.append("\\begin{equation}\n" + tex_math(b[1]) + "\n\\end{equation}")
            elif kind == "h":
                level, title = b[1], clean_heading(b[2])
                if UNNUMBERED.match(title):
                    out.append(r"\section*{" + self.inline(title) + "}")
                else:
                    cmd = {1: "section", 2: "section", 3: "subsection", 4: "subsubsection"}.get(level, "paragraph")
                    out.append("\\" + cmd + "{" + self.inline(title) + "}")
        return "\n\n".join(out)


def find_figure(ref):
    ref = ref.strip().replace("\\", "/")
    name = Path(ref).name
    for cand in (REPORT_DIR / ref, ROOT / ref, ROOT / "5_proposal" / ref, FIGURE_DIR / name):
        if cand.is_file():
            if cand.suffix.lower() not in (".png", ".jpg", ".jpeg", ".pdf"):
                raise BuildError(f"{name}: LaTeX needs PNG, JPG or PDF figures (not {cand.suffix}).")
            return cand.resolve()
    have = ", ".join(p.name for p in sorted(FIGURE_DIR.glob("*")) if p.suffix.lower() in (".png", ".jpg", ".jpeg", ".pdf"))
    raise BuildError(f"figure not found: {ref}. Figures in 5_proposal/figure/: {have or 'none'}. "
                     "Use a path like ../5_proposal/figure/<file>.png")


# =============================================================================================== references
def read_csv(path):
    if not path.exists():
        return []
    with path.open(encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def bib_text(s):
    return tex_text(re.sub(r"\s+", " ", s or "").strip())


def bib_authors(raw):
    raw = (raw or "").strip()
    if not raw:
        return ""
    parts = [p.strip() for p in (raw.split(";") if ";" in raw else re.split(r",\s+(?=\S)", raw)) if p.strip()]
    names = []
    for p in parts:
        if re.fullmatch(r"et al\.?|others", p, re.I):
            names.append("others")
            continue
        m = re.fullmatch(r"(.*\S)\s+((?:[A-Z][a-z]?\.\s?-?)+)", p)          # Scopus style: "Gamra K.A."
        if m:
            initials = re.sub(r"\.(?=[A-Z])", ". ", m.group(2).replace(" ", ""))
            names.append(f"{bib_text(m.group(1))}, {bib_text(initials)}")
        else:
            names.append(bib_text(p))
    return " and ".join(names)


def bib_entry(rank, p, c):
    doi = (p.get("doi") or "").strip()
    fields = [("author", bib_authors(p.get("authors"))),
              ("title", "{" + bib_text(p.get("title")) + "}"),       # as published: IEEEtran.bst would lowercase it
              ("journal", bib_text(p.get("venue"))), ("year", (p.get("year") or "").strip())]
    notes = []
    if c:
        if c.get("volume"):
            fields.append(("volume", bib_text(c["volume"])))
        if c.get("issue"):
            fields.append(("number", bib_text(c["issue"])))
        pages = (c.get("pages") or "").strip()
        if re.fullmatch(r"\d+\s*[-–]\s*\d+", pages):
            fields.append(("pages", re.sub(r"\s*[-–]\s*", "--", pages)))
        elif pages:
            notes.append("Art. no. " + bib_text(pages))
    if doi:
        notes.append("doi: \\href{https://doi.org/" + url_arg(doi) + "}{" + bib_text(doi) + "}")
    if notes:
        fields.append(("note", ", ".join(notes)))
    body = ",\n".join(f"  {k:<7} = {{{v}}}" for k, v in fields if v)
    return f"@article{{r{rank},\n{body}\n}}\n"


# =============================================================================================== document
PREAMBLE = r"""%% Generated by build_report.py from 6_report/report.md (research-report skill).
%% Edit report.md and build again, or edit this file directly in Overleaf.
\documentclass[conference]{IEEEtran}
\IEEEoverridecommandlockouts
\usepackage[utf8]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{textcomp}
\usepackage{cite}
\usepackage{amsmath,amssymb,amsfonts}
\usepackage{graphicx}
\usepackage{array,tabularx,booktabs}
\usepackage{siunitx}
\usepackage{url}
\usepackage[hidelinks]{hyperref}
\urlstyle{same}
\begin{document}
"""


def read_front_matter(text):
    meta = {}
    m = re.match(r"\ufeff?\s*---\s*\n(.*?)\n---\s*(\n|$)", text, re.S)
    if m:
        for line in m.group(1).splitlines():
            if ":" in line and not line.lstrip().startswith("#"):
                k, v = line.split(":", 1)
                meta[k.strip().lower()] = v.strip()
        text = text[m.end():]
    return meta, text


def placeholder(s):
    return bool(re.search(r"\[[^\]\n]*[A-Za-z][^\]\n]*\](?!\()", s or ""))


def build():
    if not SOURCE.exists():
        raise BuildError("6_report/report.md not found.")
    meta, body = read_front_matter(SOURCE.read_text(encoding="utf-8-sig"))
    body = re.sub(r"<!--.*?-->", "", body, flags=re.S)
    papers = {(p.get("rank") or "").strip(): p for p in read_csv(PAPERS) if (p.get("rank") or "").strip()}
    if not papers:
        raise BuildError("2_search/papers.csv has no papers: run the literature-search skill first.")
    cands = {(c.get("doi") or "").lower().strip(): c for c in read_csv(CANDIDATES) if c.get("doi")}

    blocks = parse_blocks(body)
    meta.setdefault("author", meta.get("authors", ""))
    h1 = next((b for b in blocks if b[0] == "h" and b[1] == 1), None)
    if h1 and (not meta.get("title") or re.sub(r"\W", "", h1[2]).lower() == re.sub(r"\W", "", meta["title"]).lower()):
        meta["title"] = meta.get("title") or h1[2]           # a title written as '# Title' is not a section
        blocks.remove(h1)
    for field in ("title", "author"):
        if not meta.get(field) or placeholder(meta[field]):
            raise BuildError(f"fill in '{field}:' at the top of 6_report/report.md (it is empty or still a placeholder).")

    # Split the document at the headings that IEEE treats specially.
    abstract, keywords, sections, mode = [], meta.get("keywords", ""), [], "body"
    for b in blocks:
        if b[0] == "h":
            kind = SPECIAL.get(clean_heading(b[2]).lower().rstrip(":"))
            if kind:
                mode = kind
                continue
            mode = "body"
        if mode == "abstract":
            abstract.append(b)
        elif mode == "keywords":
            keywords = b[1] if b[0] == "p" else keywords
        elif mode == "body":
            sections.append(b)
    if not abstract:
        raise BuildError("report.md has no '## Abstract' section.")
    if FIGURE_DIR.exists() and any(p.suffix.lower() in (".png", ".jpg", ".jpeg") for p in FIGURE_DIR.iterdir()) \
            and not any(b[0] == "figure" for b in sections):
        raise BuildError("the report does not show the proposal's figure. Add a line like\n"
                         "  ![One-sentence caption.](../5_proposal/figure/<file>.png)\n"
                         "in the section that presents the proposed study.")
    for b in blocks:
        text = b[1] if b[0] in ("p", "quote") else ""
        if placeholder(re.sub(r"\[\s*\d[\d\s,;–—-]*\]", "", text)):
            warnings.append("template text left in report.md: " + text[:90])

    inline = Inline(papers)
    r = Renderer(inline)
    abstract_tex = "\n\n".join(inline(b[1]) for b in abstract if b[0] == "p")
    body_tex = r.blocks(sections)
    if inline.unknown:
        raise BuildError("report.md cites " + ", ".join(f"[{n}]" for n in sorted(inline.unknown)) +
                         ", which " + ("is" if len(inline.unknown) == 1 else "are") + " not in 2_search/papers.csv. "
                         "Cite only ranks from papers.csv.")

    authors = [a.strip() for a in re.split(r";|\band\b", meta["author"]) if a.strip()]
    block = [r"\IEEEauthorblockN{" + ", ".join(tex_text(a) for a in authors) + "}"]
    affil = [tex_text(x) for x in (meta.get("affiliation"), meta.get("email")) if x and not placeholder(x)]
    if affil:
        block.append(r"\IEEEauthorblockA{" + r" \\ ".join(affil) + "}")
    doc = [PREAMBLE, r"\title{" + inline(meta["title"]) + "}", "", r"\author{" + "\n".join(block) + "}", "",
           r"\maketitle", "", r"\begin{abstract}", abstract_tex, r"\end{abstract}", ""]
    if keywords and not placeholder(keywords):
        doc += [r"\begin{IEEEkeywords}", tex_text(keywords.strip().rstrip(".")), r"\end{IEEEkeywords}", ""]
    doc += [body_tex, "", r"\bibliographystyle{IEEEtran}", r"\bibliography{references}", "", r"\end{document}", ""]

    if OUT.exists():
        try:
            shutil.rmtree(OUT)
        except OSError:
            pass
    (OUT / "figures").mkdir(parents=True, exist_ok=True)
    (OUT / "main.tex").write_text("\n".join(doc), encoding="utf-8")
    bib = [bib_entry(n, papers[n], cands.get((papers[n].get("doi") or "").lower().strip())) for n in inline.cited]
    (OUT / "references.bib").write_text("\n".join(bib), encoding="utf-8")
    for src, name in r.figures:
        shutil.copyfile(src, OUT / "figures" / name)

    with zipfile.ZipFile(ZIP, "w", zipfile.ZIP_DEFLATED) as z:
        for f in sorted(OUT.rglob("*")):
            if f.is_file():
                z.write(f, f.relative_to(OUT).as_posix())
    write_html(meta["title"])

    words = len(re.findall(r"[A-Za-z]{2,}", re.sub(r"\[[^\]]*\]\([^)]*\)", "", body)))
    pages = words / 950 + 0.45 * len(r.figures) + 0.3 * r.tables + len(inline.cited) / 35
    print(f"Built the IEEE report: {words} words (about {max(1, round(pages))} pages), {len(r.figures)} figure(s), "
          f"{r.tables} table(s), {len(inline.cited)} references.")
    for w in dict.fromkeys(warnings):
        print("WARNING: " + w)
    print(f"\n  {HTML.relative_to(ROOT)}   <- double-click: opens and compiles the report in Overleaf")
    print(f"  {ZIP.relative_to(ROOT)}    <- or: Overleaf > New Project > Upload Project")
    print(f"  {(OUT / 'main.tex').relative_to(ROOT)}   <- the LaTeX source")


def write_html(title):
    data = base64.b64encode(ZIP.read_bytes()).decode("ascii")
    page = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>Open the report in Overleaf</title>
<style>
body {{ font: 17px/1.5 system-ui, Segoe UI, Arial, sans-serif; max-width: 720px; margin: 48px auto; padding: 0 20px; color: #1b2433; }}
h1 {{ font-size: 26px; margin-bottom: 4px; }} .t {{ color: #52607a; margin-top: 0; }}
button {{ font: 600 19px system-ui, Segoe UI, Arial, sans-serif; padding: 14px 28px; border: 0; border-radius: 8px;
          background: #138a36; color: #fff; cursor: pointer; }} button:hover {{ background: #0f6e2b; }}
ol {{ padding-left: 1.2em; }} code {{ background: #eef1f5; padding: 1px 5px; border-radius: 4px; }}
</style></head><body>
<h1>Your report, in IEEE format</h1>
<p class="t">{html.escape(title)}</p>
<ol>
<li>Sign in to <a href="https://www.overleaf.com/login" target="_blank">Overleaf</a> (free account; your university may give you a premium one).</li>
<li>Click the button. Overleaf creates a project from your report and compiles the PDF.</li>
<li>Read the PDF. Download it with the download button above the PDF.</li>
</ol>
<form action="https://www.overleaf.com/docs" method="post" target="_blank">
<input type="hidden" name="snip_uri" value="data:application/zip;base64,{data}">
<input type="hidden" name="engine" value="pdflatex">
<input type="hidden" name="main_document" value="main.tex">
<button type="submit">Open in Overleaf</button>
</form>
<p>Button not working? In Overleaf: <b>New Project &rarr; Upload Project</b> and choose
<code>6_report/report_overleaf.zip</code>.</p>
<p>To change the text, edit <code>6_report/report.md</code> and ask the agent to build the report again
(or edit <code>main.tex</code> directly in Overleaf).</p>
</body></html>
"""
    HTML.write_text(page, encoding="utf-8")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--open", action="store_true", help="open the Overleaf page in the browser afterwards")
    a = ap.parse_args()
    try:
        build()
    except BuildError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        sys.exit(1)
    if a.open:
        webbrowser.open(HTML.resolve().as_uri())


if __name__ == "__main__":
    main()
