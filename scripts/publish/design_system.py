#!/usr/bin/env python3
"""Design System export (claude.ai "Design System" artifact type): writes out/publish/design-system/project/.
Called by design_system.sh:  python design_system.py <repo_root> <design_dir> <esbuild_module_dir>
Needs the vitrine export (out/publish/vitrine/), node, the Tailwind v4 binary of showcase/_build, playwright."""
import glob, hashlib, html as htmllib, json, math, os, re, shutil, subprocess, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "ds"))
from ds_harness import tokens_css, defined_vars, harness_html, open_page  # noqa: E402

ROOT, DESIGN, ESB = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
OUT = ROOT / "out/publish/design-system"
PROJ = OUT / "project"
BUILD = OUT / "_build"
VITRINE = ROOT / "out/publish/vitrine/c"
COMP = PROJ / "components"
DEPS = Path(os.environ.get("MIX_DEPS_PATH") or ROOT / "showcase/deps")
warnings = []
warn = lambda m: (warnings.append(m), print("WARN", m))

MAX_PREVIEW = 256 * 1024
PREVIEW_BYTES = 150 * 1024      # per preview: sections are added while the body stays under this
MAX_SECTIONS = 4
MAX_HEIGHT = 1500               # sections are added while the last one ends above this (px, 960 wide)
HARD_HEIGHT = 4000
WIDTH = 960


def kebab(n):
    return re.sub(r"(?<!^)([A-Z])", r"-\1", n).lower()


def write(rel, data):
    f = PROJ / rel
    f.parent.mkdir(parents=True, exist_ok=True)
    f.write_bytes(data if isinstance(data, bytes) else data.encode("utf-8"))


# ---------------------------------------------------------------- clean + plain copies
shutil.rmtree(PROJ, ignore_errors=True)
PROJ.mkdir(parents=True)
write("tokens.json", (DESIGN / "canvas/tokens.json").read_bytes())
write("PARIDADE.md", (DESIGN / "system/PARIDADE.md").read_bytes())
print("design tokens.json sha256", hashlib.sha256((PROJ / "tokens.json").read_bytes()).hexdigest())

# ---------------------------------------------------------------- fonts: woff2 (latin + latin-ext) from the vitrine cache -> fonts/, listed in the EXPORTED tokens.json
def ship_fonts():
    cache = ROOT / "out/publish/_cache"
    css = (cache / "fonts.css").read_text(encoding="utf-8")
    faces = {}   # (family, subset, file) -> {"weights": set, "range": str}
    for m in re.finditer(r"/\*\s*([a-z-]+)\s*\*/\s*@font-face\s*\{([^}]*)\}", css):
        subset, body = m.group(1), m.group(2)
        if subset not in ("latin", "latin-ext"):
            continue
        fam = re.search(r"font-family:\s*'([^']+)'", body).group(1)
        if re.search(r"font-style:\s*(\w+)", body).group(1) != "normal":
            continue
        f = re.search(r"/([^/)]+\.woff2)\)", body).group(1)
        d = faces.setdefault((fam, subset, f), {"weights": set(), "range": re.search(r"unicode-range:\s*([^;]+);", body).group(1).strip()})
        d["weights"].add(re.search(r"font-weight:\s*(\d+)", body).group(1))
    fonts = []
    for (fam, subset, f), d in sorted(faces.items()):
        name = f"{fam.replace(' ', '')}-{subset}.woff2"
        write(f"fonts/{name}", (cache / f).read_bytes())
        # one file serving several weights is a variable font (Google Fonts serves the whole wght axis)
        weight = "100 900" if len(d["weights"]) > 1 else next(iter(d["weights"]))
        fonts.append({"family": fam, "file": f"fonts/{name}", "weight": weight, "style": "normal", "unicodeRange": d["range"]})
    t = json.loads((PROJ / "tokens.json").read_text(encoding="utf-8"))
    t["type"]["fonts"] = fonts
    write("tokens.json", json.dumps(t, ensure_ascii=False, indent=2) + "\n")
    return fonts


FONTS = ship_fonts()
sha = hashlib.sha256((PROJ / "tokens.json").read_bytes()).hexdigest()
print("exported tokens.json sha256", sha)
comps = sorted(d.name for d in (DESIGN / "system/components").iterdir() if d.is_dir() and (d / "README.md").exists())
for c in comps:
    write(f"components/{c}/README.md", (DESIGN / f"system/components/{c}/README.md").read_bytes())
write("components/Cover/preview.html", (HERE / "ds/cover.preview.html").read_bytes())

# ---------------------------------------------------------------- vitrine pages -> sections
def take_div(s, start):
    """inner HTML of the <div> that opens at s[start]; depth counted over <div ...> / </div>."""
    depth, i = 0, start
    for m in re.finditer(r"<div\b|</div>", s[start:]):
        depth += 1 if m.group(0) != "</div>" else -1
        if depth == 0:
            inner_start = s.index(">", start) + 1
            return s[inner_start:start + m.start()]
    raise ValueError("unbalanced div")


FORBID = re.compile(r"<(iframe|frame|object|embed|portal|noscript)\b", re.I)
LINK = re.compile(r'\b(href|src)="((?:\.\./)?(?:c|t|full)/[^"]*|(?:\.\./)?(?:index|instalacao|cores|temas|novidades|templates)\.html[^"]*)"')


def clean(inner, cid):
    inner = LINK.sub(lambda m: f'{m.group(1)}="#"', inner)
    for m in re.finditer(r'\b(?:href|src)="([^"#][^"]*)"', inner):
        v = m.group(1)
        if not v.startswith("data:") and not v.startswith("mailto:") and not v.startswith("tel:"):
            warn(f"{cid}: external/unmapped url kept: {v[:80]}")
    for m in re.finditer(r"url\(\s*['\"]?([^)'\"]+)", inner):
        if not m.group(1).startswith(("data:", "#", "var(")):
            warn(f"{cid}: css url() kept: {m.group(1)[:80]}")
    return inner


def vitrine(comp):
    cid = kebab(comp)
    s = (VITRINE / f"{cid}.html").read_text(encoding="utf-8")
    main = s[s.index("<main"):]
    sub = re.search(r'<p class="d-sub">(.*?)</p>', main, re.S)
    sub = re.sub(r"\s+", " ", htmllib.unescape(re.sub(r"<[^>]+>", "", sub.group(1)))).strip().replace('"', "'") if sub else comp
    crumb = re.search(r'<div class="d-crumb">([^<]*)</div>', main).group(1)
    secs = []
    for m in re.finditer(r'<section class="d-ex" id="x-(\d+)">\s*<h2>(.*?)</h2>', main, re.S):
        st = main.find('<div class="d-in2">', m.end())
        wide = "d-exp wide" in main[m.end():st]
        inner = take_div(main, st).strip()
        title = re.sub(r"\s+", " ", re.sub(r"<[^>]+>", "", m.group(2))).strip()
        if FORBID.search(inner):
            warn(f"{cid}: section '{title}' dropped (iframe/object/embed/noscript)")
            continue
        secs.append({"title": title, "wide": wide, "html": clean(inner, cid)})
    return {"id": cid, "sub": sub, "crumb": crumb, "secs": secs}


V = {c: vitrine(c) for c in comps}

# ---------------------------------------------------------------- groups (README table; vitrine crumb for what the table lacks)
author = (DESIGN / "system/README.md").read_text(encoding="utf-8")
GROUP = {}
for m in re.finditer(r"^\| (\d\d) \| ([^|]+) \| ([^|]+) \|$", author, re.M):
    for name in re.findall(r"[A-Z][A-Za-z]+", re.sub(r"\([^)]*\)", "", m.group(3))):
        GROUP[name] = f"{m.group(1)} · {m.group(2).strip()}"
missing_in_table = [c for c in comps if c not in GROUP]
for c in missing_in_table:
    GROUP[c] = V[c]["crumb"]
for c in comps:
    if V[c]["crumb"] != GROUP[c]:
        warn(f"{c}: README table says '{GROUP[c]}', vitrine says '{V[c]['crumb']}' (README wins)")

# ---------------------------------------------------------------- README.md (the brand book)
def md_section(md, title):
    m = re.search(rf"^## {re.escape(title)}\n(.*?)(?=^## |\Z)", md, re.S | re.M)
    if not m:
        raise SystemExit(f"design README has no '## {title}' section: update scripts/publish/ds/readme.tmpl.md")
    return m.group(1).strip("\n")


def groups_section():
    body = md_section(author, "Grupos (uma página cada)")
    extra = {}
    for c in missing_in_table:
        extra.setdefault(GROUP[c].split(" · ")[0], []).append(c)

    def row(m):
        add = extra.get(m.group(1))
        return f"| {m.group(1)} | {m.group(2)} | {m.group(3)}{', ' + ', '.join(add) if add else ''} |"

    return "## Grupos (uma página cada)\n\n" + re.sub(r"^\| (\d\d) \| ([^|]+) \| ([^|]+?) \|$", row, body, flags=re.M).strip()


first_par = author.split("\n\n")[1]
assert "(123 componentes, todos em claro e escuro)" in first_par, "design README intro changed"
intro = first_par.replace("(123 componentes, todos em claro e escuro)", f"({len(comps)} cards de componente, todos em claro e escuro)")
tmpl = (HERE / "ds/readme.tmpl.md").read_text(encoding="utf-8")
readme = tmpl.replace("{{intro}}", intro).replace("{{section:Grupos (uma página cada)}}", groups_section())
readme = re.sub(r"\{\{section:([^}]+)\}\}", lambda m: f"## {m.group(1)}\n\n" + md_section(author, m.group(1)), readme)
write("README.md", readme.rstrip() + "\n")

# ---------------------------------------------------------------- previews
def preview(comp, nsec=None):
    v = V[comp]
    parts, size = [], 0
    for sec in v["secs"]:
        if parts and (len(parts) >= (nsec or MAX_SECTIONS) or size + len(sec["html"]) > PREVIEW_BYTES):
            break
        size += len(sec["html"])
        cls = "items-stretch" if sec["wide"] else "items-center"
        parts.append(
            f'<div data-ds-sec><h2 class="mb-3 font-mono text-[11px] font-normal uppercase tracking-wider text-muted">{sec["title"]}</h2>'
            f'<div class="relative flex w-full flex-col {cls} gap-4 *:max-w-full">{sec["html"]}</div></div>')
    return parts


def render(comp, nsec=None, height=400):
    v = V[comp]
    body = "\n".join(preview(comp, nsec))
    # ThemeSwitch follows the OS when nothing was chosen and would overwrite the frame's data-theme: hand the frame's mode over as the choice
    theme = ('<script>(function(){var h=document.documentElement;h.setAttribute("data-theme-choice",h.getAttribute("data-theme")||"light")})()</script>\n'
             if "LedgerUI.ThemeSwitch" in body else "")
    marker = f'<!-- @dsCard group="{GROUP[comp]}" height={height} subtitle="{v["sub"][:200]}" -->'
    doc = (f'{marker}\n<!doctype html>\n<html lang="pt-BR">\n<head><meta charset="utf-8"><title>{comp}</title></head>\n<body>\n'
           f'<div data-ds-root class="flex flex-col gap-8 p-6">\n{body}\n</div>\n{theme}<script>window.LedgerUI&&window.LedgerUI.init()</script>\n</body>\n</html>\n')
    return doc


def write_previews(counts=None, heights=None):
    for c in comps:
        write(f"components/{c}/preview.html", render(c, (counts or {}).get(c), (heights or {}).get(c, 400)))


# ---------------------------------------------------------------- bundle.js / bundle.css
def build_js():
    subprocess.run(["node", str(HERE / "ds-bundle.mjs"), str(ESB), str(ROOT), str(DEPS), str(BUILD / "js"), str(COMP / "bundle.js")], check=True)
    js = (COMP / "bundle.js").read_text(encoding="utf-8")
    assert "</script" not in js and "<!--" not in js
    subprocess.run(["node", "--check", str(COMP / "bundle.js")], check=True)
    assert len(js.encode()) <= 6 * 1024 * 1024


def build_css():
    tw = os.environ.get("TAILWIND") or next(iter(sorted(glob.glob(str(ROOT / "showcase/_build/tailwind-*")))), None)
    if not tw:
        raise SystemExit("Tailwind v4 binary not found: run `cd showcase && mix assets.setup` or set TAILWIND")
    BUILD.mkdir(parents=True, exist_ok=True)
    (BUILD / "bundle.in.css").write_text(
        f'@import "tailwindcss" source(none);\n@import "{ROOT}/assets/css/ledger_ui.css";\n'
        f'@source "{COMP}/*/preview.html";\n', encoding="utf-8")
    subprocess.run([tw, "-i", str(BUILD / "bundle.in.css"), "-o", str(COMP / "bundle.css"), "--minify"], check=True, capture_output=True)
    css = (COMP / "bundle.css").read_text(encoding="utf-8")
    assert not re.search(r"</style", css, re.I), "bundle.css contains </style"
    assert len(css.encode()) <= 2 * 1024 * 1024, "bundle.css over 2 MB"


# ---------------------------------------------------------------- measure (playwright)
def measure(counts):
    from playwright.sync_api import sync_playwright
    tcss = tokens_css(PROJ / "tokens.json")
    css = (COMP / "bundle.css").read_text(encoding="utf-8")
    js = (COMP / "bundle.js").read_text(encoding="utf-8")
    res = {}
    with sync_playwright() as p:
        kw = {"executable_path": "/usr/bin/chromium"} if os.path.exists("/usr/bin/chromium") else {}
        b = p.chromium.launch(args=["--no-sandbox"], **kw)
        pg = b.new_page(viewport={"width": WIDTH, "height": 800})
        for c in comps:
            doc = harness_html((COMP / c / "preview.html").read_text(encoding="utf-8"), "light", tcss, css, js)
            pg.unroute_all()
            open_page(pg, doc, fonts_dir=PROJ / 'fonts')
            pg.wait_for_timeout(400)
            res[c] = pg.evaluate("""() => { const r = document.querySelector('[data-ds-root]'), y = scrollY;
              return {bottoms: [...r.children].map(e => e.getBoundingClientRect().bottom + y), total: r.getBoundingClientRect().bottom + y} }""")
        b.close()
    return res


write_previews()
build_js()
build_css()
m1 = measure(None)
counts = {}
for c in comps:
    n = 1
    for i, bt in enumerate(m1[c]["bottoms"], 1):
        if bt <= MAX_HEIGHT:
            n = i
    counts[c] = min(n, len(preview(c)))
write_previews(counts)
build_css()
m2 = measure(counts)
heights = {c: min(max(math.ceil(m2[c]["total"]), 40), HARD_HEIGHT) for c in comps}
for c in comps:
    if m2[c]["total"] > HARD_HEIGHT:
        warn(f"{c}: content is {math.ceil(m2[c]['total'])}px high, marker clamped to {HARD_HEIGHT}")
write_previews(counts, heights)
for c in comps:
    n = (COMP / c / "preview.html").stat().st_size
    if n > MAX_PREVIEW:
        raise SystemExit(f"{c}/preview.html is {n} bytes (> 256 KB)")
    if not V[c]["secs"]:
        warn(f"{c}: vitrine has no live example section: preview is empty")

# ---------------------------------------------------------------- cover variables
tcss = tokens_css(PROJ / "tokens.json")
have = defined_vars(tcss)
used = set(re.findall(r"var\((--[A-Za-z0-9_-]+)", (COMP / "Cover/preview.html").read_text()))
gone = sorted(used - have)
print("cover vars used:", " ".join(sorted(used)))
print("cover vars MISSING from tokens.css:", gone or "none")
(BUILD / "tokens.css").write_text(tcss, encoding="utf-8")

# ---------------------------------------------------------------- summary
files = [f for f in PROJ.rglob("*") if f.is_file()]
print(f"project/: {len(files)} files, {sum(f.stat().st_size for f in files)} bytes")
json.dump({"counts": counts, "heights": heights, "warnings": warnings}, open(BUILD / "report.json", "w"), ensure_ascii=False, indent=1)
print(f"previews: {len(comps)}  warnings: {len(warnings)}")
