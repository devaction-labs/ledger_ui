"""Tokens e CSS original (lu-*) da referência. Adaptado de tools/render.py da referência:
lê `referencia/tokens.json` direto (sem out/design-system) e não depende do Chrome."""
import json, os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
import ref

T = json.load(open(ref.TOKENS))


def css():
    out = []
    def v(x): return re.sub(r"\{([^}]+)\}", r"var(--\1)", x)
    for th in ["light", "dark"]:
        sel = ':root, [data-theme="light"]' if th == "light" else '[data-theme="dark"]'
        out.append(sel + "{" + "".join(f'--{t["name"]}:{v(t["value"][th])};' for t in T["color"]["tokens"]) + "".join(f'--{t["name"]}:{t["value"][th]};' for t in T["shadow"]["tokens"]) + "}")
    out.append(":root{" + "".join(f'--{t["name"]}:{t["value"]};' for f in ["spacing","radius"] for t in T[f]["tokens"]) + "".join(f"--font-{k}:{s};" for k, s in T["type"]["families"].items()) + "--font-display:var(--font-sans);}")
    for p in T["color"].get("palettes", []):
        o = p.get("overrides") or {}
        if not o: continue
        q = f'[data-palette="{p["id"]}"]'
        fd = (p.get("fonts") or {}).get("display")
        out.append(f'{q}, [data-theme="light"]{q}, {q} [data-theme="light"], [data-theme="light"] {q}' + "{" + "".join(f'--{k}:{v(x["light"])};' for k, x in o.items()) + (f"--font-display:{fd};" if fd else "") + "}")
        out.append(f'[data-theme="dark"]{q}, [data-theme="dark"] {q}, {q} [data-theme="dark"]' + "{" + "".join(f'--{k}:{v(x["dark"])};' for k, x in o.items()) + (f"--font-display:{fd};" if fd else "") + "}")
        hero = {k: x for k, x in o.items() if k.startswith("hero-")}
        if hero:
            tg = [".lu-hero", ".lu-auth .art", ".lu-summit-host"]
            out.append(", ".join(f'{q}{q} {t}' for t in tg) + "{" + "".join(f'--{k}:{x["light"]};' for k, x in hero.items()) + "}")
            out.append(", ".join(f'{a} {t}' for a in (f'[data-theme="dark"]{q}', f'[data-theme="dark"] {q}{q}', f'{q}{q} [data-theme="dark"]') for t in tg) + "{" + "".join(f'--{k}:{x["dark"]};' for k, x in hero.items()) + "}")
    return "\n".join(out)


TCSS = css()
BCSS = open(ref.BUNDLE_CSS).read()
BJS = open(ref.BUNDLE_JS).read()
