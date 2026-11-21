"""Shared by design_system.py and check_ds.py: tokens.css from tokens.json and a harness page that imitates the
claude.ai preview frame (tokens.css + bundle.css + bundle.js preloaded, <html data-theme>, the preview's own head/body)."""
import json, re


def tokens_css(tokens_path):
    t = json.load(open(tokens_path, encoding="utf-8"))
    themes = [x["id"] for x in t["color"]["themes"]]
    first = themes[0]
    toks = t["color"]["tokens"]

    def val(v, theme):
        if isinstance(v, str):
            return v
        return v.get(theme, v[first])

    def css(v):
        m = re.fullmatch(r"\{([^}]+)\}", v)
        return f"var(--{m.group(1)})" if m else v

    def decl(items, theme):
        return "".join(f"--{x['name']}:{css(val(x['value'], theme))};" for x in items)

    shadows = t.get("shadow", {}).get("tokens", [])
    out = [f':root,[data-theme="{first}"]{{{decl(toks, first)}{decl(shadows, first)}}}']
    for th in themes[1:]:
        out.append(f'[data-theme="{th}"]{{{decl(toks, th)}{decl(shadows, th)}}}')
    plain = "".join(f"--{x['name']}:{x['value']};" for fam in ("spacing", "radius") for x in t.get(fam, {}).get("tokens", []))
    fams = "".join(f"--font-{k}:{v};" for k, v in t["type"]["families"].items())
    out.append(f":root{{{plain}{fams}}}")
    for g in t["type"]["groups"]:
        for s in g["styles"]:
            fam = s.get("family", g["family"])
            body = f"font-family:var(--font-{fam});font-size:{s['fontSize']};line-height:{s['lineHeight']};font-weight:{s['fontWeight']};"
            if "letterSpacing" in s:
                body += f"letter-spacing:{s['letterSpacing']};"
            out.append(f".{s['name']}{{{body}}}")
    for f in t["type"].get("fonts", []):
        ur = f' unicode-range:{f["unicodeRange"]};' if f.get("unicodeRange") else ""
        out.append(f'@font-face{{font-family:"{f["family"]}";src:url("{f["file"]}") format("woff2");font-weight:{f["weight"]};font-style:{f.get("style", "normal")};font-display:swap;{ur}}}')
    return "\n".join(out)


def defined_vars(tcss):
    return set(re.findall(r"(--[A-Za-z0-9_.-]+):", tcss))


def harness_html(preview, theme, tcss, bundle_css, bundle_js):
    """The preview document with the frame's preloads injected and <html data-theme=...>."""
    html = re.sub(r"^<!--.*?-->\s*", "", preview, count=1, flags=re.S)
    pre = f"<style>{tcss}</style><style>{bundle_css}</style><script>{bundle_js}</script>"
    if re.search(r"<html\b", html):
        html = re.sub(r"<html\b([^>]*)>", lambda m: f'<html{re.sub(chr(32) + "data-theme=.[^ >]*", "", m.group(1))} data-theme="{theme}">', html, count=1)
    else:
        html = f'<html data-theme="{theme}">' + html + "</html>"
    if re.search(r"<head\b[^>]*>", html):
        html = re.sub(r"(<head\b[^>]*>)", lambda m: m.group(1) + pre, html, count=1)
    else:
        html = html.replace(f'data-theme="{theme}">', f'data-theme="{theme}"><head>{pre}</head>', 1)
    return html


URL = "http://ds.test/preview.html"


def open_page(pg, doc, ext=None, fonts_dir=None):
    """Loads `doc` on a real http origin served from memory (so localStorage/sessionStorage work, as in the artifact frame).
    Any other request that is not data:/blob: is aborted and appended to `ext`."""
    def route(r):
        u = r.request.url
        if u == URL:
            r.fulfill(status=200, content_type="text/html; charset=utf-8", body=doc)
        elif fonts_dir and u.startswith("http://ds.test/fonts/") and (fonts_dir / u.rsplit("/", 1)[1]).is_file():
            r.fulfill(status=200, content_type="font/woff2", body=(fonts_dir / u.rsplit("/", 1)[1]).read_bytes())
        elif u.startswith(("data:", "blob:")):
            r.continue_()
        else:
            if ext is not None:
                ext.append(u)
            r.abort()
    pg.route("**/*", route)
    pg.goto(URL, wait_until="load")
