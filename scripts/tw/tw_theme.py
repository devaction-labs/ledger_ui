"""tokens.json (referência) + @keyframes do bundle.css -> assets/css/ledger_ui.css (Tailwind v4).

Uso:  python3 scripts/tw/tw_theme.py        (nunca edite assets/css/ledger_ui.css à mão)

As variáveis de runtime ganham o prefixo --lu- (trocam por tema e paleta);
o @theme inline expõe cada uma como utilitário: bg-panel, text-ink, border-line,
shadow-btn, rounded-lg, font-display...
Adaptado de tools/tw_theme.py da referência (piloto aprovado).
"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ref, render

T = render.T
pref = lambda s: re.sub(r"--([a-z])", r"--lu-\1", s)
cname = lambda n: n[3:] if n.startswith("bg-") else n

colors = [t["name"] for t in T["color"]["tokens"]]
shadows = [t["name"] for t in T["shadow"]["tokens"]]
radius = {t["name"]: t["value"] for t in T["radius"]["tokens"]}

theme = ["@theme inline {", "  --color-*: initial;", "  --color-white: #fff;", "  --color-black: #000;", "  --color-transparent: transparent;", "  --color-current: currentColor;"]
theme += [f"  --color-{cname(n)}: var(--lu-{n});" for n in colors]
theme += ["  --shadow-*: initial;"] + [f"  --{n}: var(--lu-{n});" for n in shadows]
theme += ["  --radius-*: initial;"] + [f"  --{n}: {v};" for n, v in radius.items()]
theme += ["  --font-sans: var(--lu-font-sans);", "  --font-mono: var(--lu-font-mono);", "  --font-display: var(--lu-font-display);", "}"]


def keyframes():
    """Todos os @keyframes do bundle.css; em duplicatas vale a última (como no CSS)."""
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
        out.append(f"@keyframes {name} " + re.sub(r"\s+", " ", src[m.end() - 1:j]))
    return pref("\n".join(out))


css = f"""/* Ledger UI · Tailwind CSS v4 — GERADO por scripts/tw/tw_theme.py (tokens.json + @keyframes do bundle). Não edite à mão.
   Uso no app:   @import "tailwindcss";  @import "../../deps/ledger_ui/assets/css/ledger_ui.css"; */
@source "../../lib";

@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));

{chr(10).join(theme)}

{pref(render.css())}

@layer base {{
  body {{ background: var(--lu-bg-page); color: var(--lu-ink); font-family: var(--lu-font-sans); font-size: 14px; line-height: 20px; -webkit-font-smoothing: antialiased; font-feature-settings: "cv11", "ss01"; }}
  button, input, select, textarea {{ font: inherit; color: inherit; }}
  input::placeholder, textarea::placeholder {{ color: var(--lu-muted); opacity: .85; }}
}}

/* keyframes do kit (os componentes usam via animate-[nome_…]) */
{keyframes()}
"""
out = os.path.join(ref.REPO, "assets", "css", "ledger_ui.css")
os.makedirs(os.path.dirname(out), exist_ok=True)
open(out, "w").write(css)
print("ok", out, len(css))
