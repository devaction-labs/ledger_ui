"""Paridade visual: original (lu-*, referência) x HEEx + Tailwind (esta lib), por tema.

Uso:   python parity/run.py [filtro ...]        # ex.: python parity/run.py button badge
Saída: tabela id x tema (% de pixels diferentes) e PNGs em $PARITY_DIR (padrão /tmp/parity).

Temas: light, dark, crepusculo (paleta crepúsculo no claro) e crepusculo-dark.
Pré-requisitos: ver MIGRATION.md (venv, LEDGER_REF, Tailwind v4, MIX_DEPS_PATH).
"""
import asyncio, glob, importlib.util, json, os, subprocess, sys, tempfile
H = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.dirname(H)
sys.path.insert(0, f"{ROOT}/scripts/tw"); sys.path.insert(0, f"{H}/cases")
import ref, render
import numpy as np
from PIL import Image, ImageChops
from playwright.async_api import async_playwright

THEMES = [("light", "light", None), ("dark", "dark", None), ("crepusculo", "light", "crepusculo"), ("crep-dark", "dark", "crepusculo")]
TOL = 24          # limiar de diferença por pixel (0-255)
LIMIT = 0.1       # % máximo aceito por caso
THEME_CHECK = "--theme" in sys.argv          # modo tema próprio: HEEx com parity/theme_demo.css (fuchsia + slate)
filters = [a for a in sys.argv[1:] if not a.startswith("--")]
OUTD = ref.PARITY_DIR; os.makedirs(OUTD, exist_ok=True)
RUN = tempfile.mkdtemp(prefix="run-", dir=OUTD)


def load_cases():
    cases = {}
    for f in sorted(glob.glob(f"{H}/cases/[a-z]*.py")):
        spec = importlib.util.spec_from_file_location("pc_" + os.path.basename(f)[:-3], f)
        mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
        dup = set(mod.C) & set(cases)
        if dup: sys.exit(f"ids repetidos em {f}: {sorted(dup)}")
        cases.update(mod.C)
    return cases


def tailwind_bin():
    if os.environ.get("TAILWIND_BIN"): return os.environ["TAILWIND_BIN"]
    found = sorted(glob.glob(f"{ROOT}/showcase/_build/tailwind-linux-x64*") + glob.glob(f"{ROOT}/_build/tailwind-linux-x64*"))
    if found: return found[-1]
    sys.exit("Tailwind v4 não encontrado: rode `cd showcase && mix tailwind.install` ou defina TAILWIND_BIN")


def render_heex():
    out = f"{RUN}/heex.json"
    env = dict(os.environ, LANG="C.UTF-8", OUT=out)
    r = subprocess.run(["mix", "run", "parity/cases.exs"], cwd=ROOT, env=env, capture_output=True, text=True)
    if r.returncode: sys.exit((r.stdout[-3000:] + r.stderr[-3000:]) or "mix run falhou")
    return json.load(open(out))


def build_css(inp="app.css"):
    out = f"{RUN}/tw-{os.path.basename(inp)}"
    subprocess.run([tailwind_bin(), "-i", f"{H}/{inp}", "-o", out], cwd=ROOT, check=True, capture_output=True)
    return open(out).read()


def page(css, body, th, pal, w, js=""):
    attrs = f'data-theme="{th}"' + (f' data-palette="{pal}"' if pal else "")
    return (f'<!doctype html><html {attrs}><head><meta charset="utf-8"><style>{css}</style><script>{js}</script></head>'
            f'<body style="margin:0"><div id="c" style="padding:16px;width:{w}px;display:flow-root">{body}</div></body></html>')


def ledger_colors():
    """Cores do Ledger (accent teal e neutros) que NÃO podem sobrar com o tema próprio."""
    out = set()
    for t in render.T["color"]["tokens"]:
        n = t["name"]
        if not (n.startswith("teal-") or n in ("accent", "accent-ink", "accent-soft", "bg-page", "bg-shell", "bg-tray", "bg-panel", "bg-sunken", "bg-hover", "bg-selected", "line", "line-strong", "ink", "ink-2", "muted", "subtle", "inverse", "on-inverse")): continue
        for th in ("light", "dark"):
            v = t["value"][th]
            # #141514 #f2f3f2 #2a2e2c #f4f4f2 #0e100f são as cores FIXAS de `dark`/`white` (LedgerUI.Color): não são tema
            if v.startswith("#") and len(v) == 7 and v.lower() not in ("#ffffff", "#000000", "#141514", "#f2f3f2", "#2a2e2c", "#f4f4f2", "#0e100f"):
                out.add(tuple(int(v[i:i + 2], 16) for i in (1, 3, 5)))
    return np.array(sorted(out))


async def theme_check(cases, HX):
    """Renderiza só o lado HEEx com o tema de demonstração e mede os pixels ainda na cor do Ledger."""
    TW = build_css("theme_demo.css"); led = ledger_colors(); res = {}
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path=ref.CHROME, args=["--no-sandbox"])
        pg = await b.new_page(viewport={"width": 1100, "height": 800})
        for cid, case in cases.items():
            if cid not in HX: continue
            res[cid] = {}
            for th in ("light", "dark"):
                await pg.set_content(page(TW, HX[cid], th, None, case[0]))
                f = f"{OUTD}/{cid}-theme-{th}.png"
                await (await pg.query_selector("#c")).screenshot(path=f, animations="disabled")
                im = np.array(Image.open(f).convert("RGB")).reshape(-1, 3).astype(int)
                hit = np.zeros(len(im), bool)
                for c in led: hit |= (np.abs(im - c).max(axis=1) <= 0)
                res[cid][th] = 100 * hit.sum() / len(im)
        await b.close()
    print(f"{'caso (tema próprio)':24}{'light':>12}{'dark':>12}   % de pixels ainda na cor do Ledger (accent teal / cinzas)")
    bad = 0
    for cid, r in res.items():
        print(f"{cid:24}" + "".join(f"{r[t]:11.2f}%" for t in ("light", "dark")))
        bad += sum(v > 0.05 for v in r.values())
    print(f"\n{len(res)} casos; acima de 0.05%: {bad}")
    sys.exit(1 if bad else 0)


async def main():
    cases = {k: v for k, v in load_cases().items() if not filters or any(f in k for f in filters)}
    if not cases: sys.exit("nenhum caso para o filtro " + " ".join(filters))
    HX = render_heex()
    if THEME_CHECK: return await theme_check(cases, HX)
    TW = build_css()
    ORIG = render.TCSS + render.BCSS
    res = {}
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path=ref.CHROME, args=["--no-sandbox"])
        pg = await b.new_page(viewport={"width": 1100, "height": 800})
        for cid, case in cases.items():
            w, orig = case[0], case[1]
            extra = case[2] if len(case) > 2 else ""      # CSS extra do lado ORIGINAL (regra que o original não tem; justifique no caso)
            if cid not in HX: res[cid] = {t[0]: "sem HEEx" for t in THEMES}; continue
            res[cid] = {}
            for name, th, pal in THEMES:
                shots = []
                for side, css, body, js in (("o", ORIG + extra, orig, render.BJS), ("t", TW, HX[cid], "")):
                    await pg.set_content(page(css, body, th, pal, w, js))
                    await pg.evaluate("window.LedgerUI && LedgerUI.hydrate(document)"); await pg.wait_for_timeout(60)
                    f = f"{OUTD}/{cid}-{name}-{side}.png"
                    await (await pg.query_selector("#c")).screenshot(path=f, animations="disabled"); shots.append(f)
                a, c = Image.open(shots[0]).convert("RGB"), Image.open(shots[1]).convert("RGB")
                if a.size != c.size: res[cid][name] = f"tam {a.size[0]}x{a.size[1]} != {c.size[0]}x{c.size[1]}"; continue
                d = ImageChops.difference(a, c).convert("L").point(lambda x: 255 if x > TOL else 0)
                pct = 100 * sum(d.histogram()[255:]) / (a.size[0] * a.size[1])
                res[cid][name] = pct
                if pct > 0:
                    Image.fromarray(np.hstack([np.array(a), np.array(c)])).save(f"{OUTD}/{cid}-{name}-diff.png")
        await b.close()
    names = [t[0] for t in THEMES]
    print(f"{'caso':24}" + "".join(f"{n:>12}" for n in names))
    bad = 0
    for cid, r in res.items():
        cells = []
        for n in names:
            v = r[n]
            cells.append(f"{v:11.2f}%" if isinstance(v, float) else f"{v:>12}")
            if not isinstance(v, float) or v > LIMIT: bad += 1
        print(f"{cid:24}" + "".join(cells))
    print(f"\n{len(res)} casos x {len(names)} temas; fora de {LIMIT}%: {bad}   (imagens: {OUTD})")
    sys.exit(1 if bad else 0)

asyncio.run(main())
