"""tokens.json (referência) + @keyframes do bundle.css -> assets/css/ledger_ui.css (Tailwind v4).

Uso:  python3 scripts/tw/tw_theme.py   (LEDGER_UI_CSS_OUT=/caminho grava em outro lugar; nunca edite assets/css/ledger_ui.css à mão)

Entradas do tema (como no Flux): --color-accent* e --color-gray-50…950; o resto deriva em oklch.
As variáveis de runtime ganham o prefixo --lu-; o @theme inline expõe bg-panel, text-ink, border-line,
shadow-btn, bg-accent-500… Adaptado de tools/tw_theme.py da referência.
"""
import json, re, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ref, render

T = render.T
# Só os TOKENS de design ganham o prefixo --lu- (nomes do tokens.json + chaves das paletas + fontes); as variáveis locais do
# componente (--c, --th, --tw, --t1, --n, --to, --o1…) ficam como no bundle, e o que já nasce --lu-* não é prefixado de novo.
# ANIMATED: variáveis animadas que os componentes definem com o prefixo (`--lu-sp`, `--lu-stp`).
_T = json.load(open(ref.TOKENS))
TOKEN_NAMES = ({t["name"] for k in ("color", "shadow", "radius", "spacing") for t in _T[k]["tokens"]} | {"font-sans", "font-mono", "font-display"}
               | {k for p in _T["color"].get("palettes", []) for k in (p.get("overrides") or {})})
ANIMATED = {"stp", "sp"}
def _pref(m):
    n = m.group(1)
    if n.startswith("lu-") or not (n in TOKEN_NAMES or n in ANIMATED): return m.group(0)
    return "--lu-" + n
pref = lambda s: re.sub(r"--([a-z][a-z0-9-]*)", _pref, s).replace("--lu-teal-", "--lu-accent-")

# ---------- oklch: o tema derivado reproduz os valores do Ledger ----------
import math
def oklch(h):
    h = h.lstrip("#"); lin = lambda c: c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4
    r, g, b = [lin(int(h[i:i+2], 16) / 255) for i in (0, 2, 4)]
    l = (.4122214708*r + .5363325363*g + .0514459929*b) ** (1/3); m = (.2119034982*r + .6806995451*g + .1073969566*b) ** (1/3); q = (.0883024619*r + .2817188376*g + .6299787005*b) ** (1/3)
    L = .2104542553*l + .7936177850*m - .0040720468*q; A = 1.9779984951*l - 2.4285922050*m + .4505937099*q; B = .0259040371*l + .7827717662*m - .8086757660*q
    return L, math.hypot(A, B), math.degrees(math.atan2(B, A)) % 360
TOK = {t["name"]: t["value"] for t in T["color"]["tokens"]}
STEPS = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900]
NEUTRAL = ["bg-page", "bg-shell", "bg-tray", "bg-panel", "bg-sunken", "bg-hover", "bg-selected", "line", "line-strong",
           "ink", "ink-2", "muted", "subtle", "inverse", "on-inverse", "chart-grid", "chart-ghost"]
ACC = {th: TOK["teal-600"][th] for th in ("light", "dark")}
# accent-content (accent-ink: text/icon in the brand colour) is its own input: light is slightly darker than the accent (#0a7a69 vs #0b8572)
INK = {th: re.sub(r"\{([^}]+)\}", lambda m: TOK[m.group(1)][th], TOK["accent-ink"][th]) for th in ("light", "dark")}
INPUT = {"light": {"accent": ACC["light"], "accent-content": INK["light"], "accent-foreground": TOK["on-accent"]["light"]},
         "dark": {"accent": ACC["dark"], "accent-content": INK["dark"], "accent-foreground": TOK["on-accent"]["dark"]}}
# Escala de cinza do Ledger (como a zinc do Flux): L da zinc do Tailwind, croma/matiz médios
# dos neutros do Ledger que caem em cada degrau. Cada neutro guarda seu L exato e pega c/h do degrau.
GSTEPS = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950]
ZINC_L = [.985, .967, .92, .871, .705, .552, .442, .37, .274, .21, .141]
def gstep(L): return min(range(len(GSTEPS)), key=lambda i: abs(ZINC_L[i] - L))
# Escala de cinza do tema padrão (Aurora): c/h médios por degrau, calculados com os valores do tokens.json. A paleta `classic`
# (neutros quentes de antes da Aurora, com o subtle escurecido por contraste em #117) carrega a escala antiga própria
# (`gray` em color.palettes[classic]) e os neutros antigos literais; nada dela entra neste cálculo.
GRAY_SRC = {}
_acc = {i: [] for i in range(len(GSTEPS))}
for _n in NEUTRAL:
    for _th in ("light", "dark"):
        _v = GRAY_SRC.get(_n, TOK[_n])[_th]
        if _v.startswith("#"):
            _L, _C, _H = oklch(_v)
            if _C > .0015: _acc[gstep(_L)].append((_C, _H))
_all = [x for v in _acc.values() for x in v]
def _avg(v): v = v or _all; return sum(c for c, _ in v) / len(v), sum(h for _, h in v) / len(v)
GRAY = {GSTEPS[i]: (ZINC_L[i],) + _avg(_acc[i]) for i in range(len(GSTEPS))}
CHART_ACCENT = []   # Aurora: chart-2 (ameixa) e chart-5 (lavanda) não são tons do accent; a classic os deriva do accent (override)
# tokens do kit que não vêm do tokens.json (valores do bundle; iguais nos dois temas salvo indicação)
EXTRA = {"star": {"light": "#e3a008", "dark": "#e3a008"},                     # rating: estrelas e barras
         "ai-1": {"light": "#0d8f91", "dark": "#2bbfbd"}, "ai-2": {"light": "#8a5cd6", "dark": "#a98bf0"},   # aura tone=ai
         "aura-2": {"light": "#8a5cd6", "dark": "#8a5cd6"}}                      # 2ª cor das demais tonalidades da aura

def hero_tokens():
    """--hero-* do bundle (`.lu-hero, .lu-auth .art, .lu-summit-host` claro e `[data-theme=dark] …` escuro) viram --lu-hero-* no tema."""
    src = open(ref.BUNDLE_CSS).read(); out = {}
    for th, pat in (("light", r"\n\.lu-hero, \.lu-auth \.art, \.lu-summit-host \{([^}]*)\}"),
                    ("dark", r'\n\[data-theme="dark"\] \.lu-hero, \[data-theme="dark"\] \.lu-auth \.art, \[data-theme="dark"\] \.lu-summit-host \{([^}]*)\}')):
        m = re.search(pat, src); assert m, "hero tokens não encontrados no bundle"
        for k, v in re.findall(r"--hero-([\w-]+):\s*([^;]+);", m.group(1)): out.setdefault(f"hero-{k}", {})[th] = v.strip()
    return out

def f(x): return f"{x:.4f}".rstrip("0").rstrip(".")
def derived(th):
    """Variáveis --lu-* calculadas a partir de --color-accent e --color-gray."""
    La, Ca, Ha = oklch(ACC[th])
    out = []
    for st in STEPS:
        if st == 600: out.append("--lu-accent-600:var(--color-accent);"); continue
        L, C, H = oklch(TOK[f"teal-{st}"][th]); d = (H - Ha + 180) % 360 - 180   # L, croma (c * k) e matiz (h + d) relativos ao accent
        out.append(f"--lu-accent-{st}:oklch(from var(--color-accent) {f(L)} calc(c * {f(C / Ca)}) calc(h {'+' if d >= 0 else '-'} {f(abs(d))}));")
    out += ["--lu-accent:var(--lu-accent-500);", "--lu-accent-ink:var(--color-accent-content);", "--lu-accent-soft:var(--lu-accent-50);",
            "--lu-on-accent:var(--color-accent-foreground);"]
    # --lu-focus: Aurora = anel translúcido (token focus do tokens.json); #116 (accent-600 opaco, 3:1) vale só na paleta `classic`
    # chart-2/chart-5 são tons do accent (L e croma do Ledger, matiz do accent): recolorem com o tema
    for n in CHART_ACCENT:
        L, C, _ = oklch(TOK[n][th])
        out.append(f"--lu-{n}:oklch(from var(--color-accent) {f(L)} calc(c * {f(C / Ca)}) h);")
    out += [f"--lu-{k}:{v[th]};" for k, v in EXTRA.items()] + [f"--lu-{k}:{v[th]};" for k, v in hero_tokens().items()]
    for n in NEUTRAL:
        v = TOK[n][th]
        if not v.startswith("#"): continue
        L, C, H = oklch(v); st = GSTEPS[gstep(L)]
        if C < .0015: out.append(f"--lu-{n}:oklch(from var(--color-gray-{st}) {f(L)} 0 h);"); continue
        # L exato; croma e matiz do neutro relativos ao degrau (c * k, h + d): reproduz o hex e ainda recolore se o app trocar a escala
        _, Cb, Hb = GRAY[st]; d = (H - Hb + 180) % 360 - 180
        out.append(f"--lu-{n}:oklch(from var(--color-gray-{st}) {f(L)} calc(c * {f(C / Cb)}) calc(h {'+' if d >= 0 else '-'} {f(abs(d))}));")
    return "".join(out)

def cname(n):
    return n[3:] if n.startswith("bg-") else n

colors = [t["name"] for t in T["color"]["tokens"]]
shadows = [t["name"] for t in T["shadow"]["tokens"]]
radius = {t["name"]: t["value"] for t in T["radius"]["tokens"]}

BG_ONLY = {"bg-app"}   # `background` (gradientes), não cor: sem --color-*; vira o utilitário bg-app
SKIP = {"accent", "accent-ink", "on-accent"} | BG_ONLY | {f"teal-{s}" for s in STEPS}
inputs = ["/* Entradas do tema — sobrescreva no app, como no Flux */", "@theme {",
          f"  --color-accent: {INPUT['light']['accent']};", f"  --color-accent-content: {INPUT['light']['accent-content']};",
          f"  --color-accent-foreground: {INPUT['light']['accent-foreground']};"] + [
          f"  --color-gray-{st}: oklch({f(L)} {f(C)} {f(H)});" for st, (L, C, H) in GRAY.items()] + ["}",
          "@layer theme {", "  [data-theme=dark] {"] + [f"    --color-{k}: {v};" for k, v in INPUT["dark"].items()] + ["  }",
          "  /* light nested in dark (e.g. a mode preview): back to the light inputs */",
          "  [data-theme=dark] [data-theme=light] {"] + [f"    --color-{k}: {v};" for k, v in INPUT["light"].items()] + ["  }", "}"]
theme = ["@theme inline {"]
theme += [f"  --color-{cname(n)}: var(--lu-{n});" for n in colors if n not in SKIP]
theme += ["  --color-star: var(--lu-star);"]
theme += [f"  --color-accent-{st}: var(--lu-accent-{st});" for st in STEPS]
theme += ["  --shadow-*: initial;"] + [f"  --{n}: var(--lu-{n});" for n in shadows]
theme += ["  --radius-*: initial;"] + [f"  --{n}: {v};" for n, v in radius.items()]
theme += ["  --font-sans: var(--lu-font-sans);", "  --font-mono: var(--lu-font-mono);", "  --font-display: var(--lu-font-display);", "}"]

def palette_inputs():
    """Paletas prontas (data-palette) também alimentam as entradas do accent."""
    out = []
    for p in T["color"].get("palettes", []):
        o = p.get("overrides") or {}
        if "teal-600" not in o: continue
        q = f'[data-palette="{p["id"]}"]'
        for th, sel in (("light", f"{q}, [data-theme=light]{q}, {q} [data-theme=light], [data-theme=light] {q}"),
                        ("dark", f"[data-theme=dark]{q}, [data-theme=dark] {q}, {q} [data-theme=dark]")):
            v = lambda k, d: pref(re.sub(r"\{([^}]+)\}", r"var(--\1)", (o.get(k) or TOK[d])[th]))
            gray = "".join(f"--color-gray-{st}:{x};" for st, x in (p.get("gray") or {}).items())   # escala de cinza própria (classic)
            out.append(f"{sel}{{--color-accent:{v('teal-600','teal-600')};--color-accent-content:{v('accent-ink','accent-ink')};--color-accent-foreground:{v('on-accent','on-accent')};{gray}}}")
    return "\n".join(out)

def properties():
    """@property do bundle (variáveis animadas), com o prefixo --lu-. `--a` (par do range, em %) colide com o ângulo do aura
    (`--lu-a`, que o kit não usa: o anel gira por transform) e fica sem registro."""
    src = open(ref.BUNDLE_CSS).read(); props = {}
    for name, body in re.findall(r"@property\s+(--[\w-]+)\s*\{([^}]*)\}", src):
        n = pref(name)
        if n == "--lu-a": continue
        props[n] = f"@property {n} {{ " + re.sub(r"\s+", " ", body.strip()) + " }"   # a última ocorrência vence
    return "\n".join(props.values())

def no_color_mix(css):
    """Tailwind/lightningcss reescreve `color-mix()` dentro de @keyframes como `prop: <1ª cor>` + `@supports (color-mix…) {prop: …}`
    ANINHADO no keyframe (inválido: o anel fica sólido em vez de 22%). `color-mix(in S, X N%, transparent)` é a cor X com alfa N%,
    que a sintaxe de cor relativa escreve sem fallback: `S(from X l a b / N%)`. Misturas de duas cores opacas (lu-pxbd) ficam."""
    pat = re.compile(r"color-mix\(in (oklab|srgb),\s*")
    out, i = [], 0
    while True:
        m = pat.search(css, i)
        if not m: out.append(css[i:]); break
        j, depth = m.end(), 1
        while depth:
            depth += {"(": 1, ")": -1}.get(css[j], 0); j += 1
        inner = css[m.end():j - 1]
        t = re.fullmatch(r"(.+?)\s+([\d.]+)%,\s*transparent", inner, re.S)
        if t and m.group(1) == "oklab":
            out += [css[i:m.start()], f"oklab(from {t.group(1)} l a b / {t.group(2)}%)"]
        elif t:
            out += [css[i:m.start()], f"rgb(from {t.group(1)} r g b / {t.group(2)}%)"]
        else:
            out += [css[i:j]]
        i = j
    return "".join(out)

# O bundle anima `width` (força layout a cada quadro); o kit usa transform (#131). Substitui o corpo do keyframe do bundle.
KEYFRAME_OVERRIDES = {"lu-timer": "{ from { transform: scaleX(1); transform-origin: left; } to { transform: scaleX(0); transform-origin: left; } }",
                      "lu-timerloop": "{ from { transform: scaleX(1); transform-origin: left; } to { transform: scaleX(0); transform-origin: left; } }"}

def keyframes():
    src = open(ref.BUNDLE_CSS).read()
    out, seen, i = [], set(), 0
    for m in re.finditer(r"@keyframes\s+([\w-]+)\s*\{", src):
        if m.start() < i: continue
        depth, j = 1, m.end()
        while depth:
            depth += {"{": 1, "}": -1}.get(src[j], 0); j += 1
        i = j
        name = m.group(1)
        if name in seen: out = [o for o in out if not o.startswith(f"@keyframes {name} ")]
        seen.add(name)
        out.append(f"@keyframes {name} " + KEYFRAME_OVERRIDES.get(name, re.sub(r"\s+", " ", src[m.end()-1:j])))
    return pref(no_color_mix("\n".join(out)))

css = f"""/* Ledger UI · Tailwind CSS v4 — GERADO por scripts/tw/tw_theme.py (tokens.json + @keyframes do bundle). Não edite à mão.
   Regerar: python3 scripts/tw/tw_theme.py (precisa do repo ../ledger_ui_ref, ou LEDGER_REF=...: dele vêm gen/bundle.css e bundle.js).
   test/ledger_ui/theme_generator_test.exs falha se este arquivo divergir do gerado (pula se a referência não existir).
   Uso no app:   @import "tailwindcss";  @import "../../deps/ledger_ui/assets/css/ledger_ui.css"; */
@source "../../lib";

@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));

{chr(10).join(inputs)}

{chr(10).join(theme)}

@utility bg-app {{ background: var(--lu-bg-app); }}

{pref(chr(10).join(render.css().splitlines()[:3]))}

/* derivado de --color-accent e --color-gray (oklch relativo) */
:root, [data-theme="light"]{{color-scheme:light;{derived("light")}}}
[data-theme="dark"]{{color-scheme:dark;{derived("dark")}}}
/* light aninhado em dark: o próprio elemento casa [data-theme="light"] e volta a light (como os tokens --lu-*) */

/* paletas prontas */
{pref(chr(10).join(l for l in render.css().splitlines()[3:] if '.lu-' not in l))}

{palette_inputs()}

@layer base {{
  /* tipo, cor e fundo do kit: no body (desligue com <body data-lu-base="off">) e em [data-ui="ledger"]; :where() não sobe a especificidade */
  :where(body:not([data-lu-base="off"])), :where([data-ui="ledger"]) {{ background: var(--lu-bg-page); color: var(--lu-ink); font-family: var(--lu-font-sans); font-size: 14px; line-height: 20px; -webkit-font-smoothing: antialiased; font-feature-settings: "cv11", "ss01"; }}
  button, input, select, textarea {{ font: inherit; color: inherit; }}
  /* o bundle/canvas não tem preflight: <small> é o do navegador (`smaller`); o preflight do Tailwind põe 80% */
  small {{ font-size: smaller; }}
  input::placeholder, textarea::placeholder {{ color: var(--lu-subtle); opacity: 1; }}

  /* portais do LiveView (teleport): o contêiner do destino não participa do layout */
  [data-phx-teleported-src] {{ display: contents; }}

  /* movimento reduzido: nada anima sem parar nem demora (o spinner, indicador de carregamento, segue girando).
     !important em @layer base vence os utilitários animate-[...]; WAAPI (toaster) não é afetado. */
  @media (prefers-reduced-motion: reduce) {{
    :not([data-part="spinner"], [data-part="spinner"] *, [data-part="button-spinner"], [data-part="button-auto-spinner"]),
    :not([data-part="spinner"], [data-part="spinner"] *, [data-part="button-spinner"], [data-part="button-auto-spinner"])::before,
    :not([data-part="spinner"], [data-part="spinner"] *, [data-part="button-spinner"], [data-part="button-auto-spinner"])::after {{
      animation-duration: .01ms !important;
      animation-iteration-count: 1 !important;
      transition-duration: .01ms !important;
      scroll-behavior: auto !important;
    }}
  }}
}}

/* alto contraste (forced-colors): box-shadow é descartado e os componentes tiram o outline, então o foco e o estado
   de switch, segmented e checkbox somem. Fora do @layer de propósito: precisa vencer `focus-visible:outline-none`. */
@media (forced-colors: active) {{
  :focus-visible {{ outline: 2px solid Highlight; outline-offset: 2px; }}
  [data-part="switch-track"] {{ forced-color-adjust: none; background: Canvas; border: 2px solid ButtonText; }}
  [data-part="switch-track"]::after {{ background: ButtonText; top: calc(var(--in) - 2px); left: calc(var(--in) - 2px); }}
  [data-part="switch"][aria-checked="true"] [data-part="switch-track"] {{ background: Highlight; border-color: Highlight; }}
  [data-part="switch"][aria-checked="true"] [data-part="switch-track"]::after {{ background: HighlightText; }}
  [data-part="segmented-item"][aria-pressed="true"], [data-part="segmented-item"][aria-selected="true"] {{ forced-color-adjust: none; background: Highlight; color: HighlightText; }}
  [data-part="checkbox-input"]:checked, [data-part="checkbox-input"]:indeterminate {{ forced-color-adjust: none; background: Highlight; border-color: Highlight; }}
  [data-part="checkbox-input"]:checked::after, [data-part="checkbox-input"]:indeterminate::after {{ border-color: HighlightText; }}
  [data-part="checkbox-input"]:indeterminate::after {{ background: HighlightText; }}
}}

/* variáveis animadas (registradas: interpolam nos @keyframes) */
{properties()}

/* keyframes do kit (os componentes usam via animate-[nome_…]) */
{keyframes()}
"""
out = os.environ.get("LEDGER_UI_CSS_OUT") or os.path.join(ref.REPO, "assets", "css", "ledger_ui.css")
os.makedirs(os.path.dirname(out), exist_ok=True)
open(out, "w").write(css)
print("ok", out, len(css))
