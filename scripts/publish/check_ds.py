"""Checks out/publish/design-system/project/ in a real browser, imitating the preview frame (tokens.css + bundle.css + bundle.js
preloaded, <html data-theme>). Every preview, light and dark. Screenshots -> out/publish/_check-ds/.
   python scripts/publish/check_ds.py            (python with playwright)"""
import os, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "ds"))
from ds_harness import tokens_css, harness_html, open_page  # noqa: E402
from playwright.sync_api import sync_playwright  # noqa: E402

ROOT = HERE.parents[1]
COMP = ROOT / "out/publish/design-system/project/components"
SHOTS = ROOT / "out/publish/_check-ds"
SHOTS.mkdir(parents=True, exist_ok=True)
for f in SHOTS.glob("*.png"):
    f.unlink()
tcss = tokens_css(ROOT / "out/publish/design-system/project/tokens.json")
css = (COMP / "bundle.css").read_text(encoding="utf-8")
js = (COMP / "bundle.js").read_text(encoding="utf-8")
names = sorted(d.name for d in COMP.iterdir() if d.is_dir())
fails, notes = [], []


def check(cond, msg):
    if not cond:
        fails.append(msg)
        print("FAIL", msg)
    return cond


def run(b):
    bg = {}
    for theme in ("light", "dark"):
        ctx = b.new_context(viewport={"width": 960, "height": 400}, color_scheme="light")
        for name in names:
            src = (COMP / name / "preview.html").read_text(encoding="utf-8")
            height = int(re.match(r"<!-- @dsCard[^>]*height=(\d+)", src).group(1))
            pg = ctx.new_page()
            pg.set_viewport_size({"width": 960, "height": min(max(height, 120), 1600)})
            errs, ext = [], []
            pg.on("console", lambda m, e=errs: e.append(m.text) if m.type == "error" else (notes.append(f"{theme} {name}: {m.text}") if m.type == "warning" else None))
            pg.on("pageerror", lambda e, errs=errs: errs.append(str(e)))
            open_page(pg, harness_html(src, theme, tcss, css, js), ext)
            pg.wait_for_timeout(400)
            tag = f"[{theme}] {name}"
            info = pg.evaluate("""() => {
              const b = document.body, root = document.querySelector('[data-ds-root]') || b.firstElementChild
              const ch = root.getBoundingClientRect().bottom + scrollY
              const lu = [...document.querySelectorAll('[class]')].flatMap(e => [...e.classList]).filter(c => /^lu-/.test(c))
              return {h: Math.ceil(ch), n: b.querySelectorAll('*').length,
                      text: b.innerText.trim().length, vis: !!b.querySelector('svg,img,canvas,input,button'),
                      lu: [...new Set(lu)], theme: document.documentElement.dataset.theme, bg: getComputedStyle(b).backgroundColor}
            }""")
            check(not errs, f"{tag}: console/page errors {errs[:3]}")
            check(not ext, f"{tag}: external requests {ext[:3]}")
            check(info["theme"] == theme, f"{tag}: data-theme is {info['theme']}")
            check(info["h"] >= 40 and info["n"] > 5 and (info["text"] > 0 or info["vis"]), f"{tag}: blank or near-zero height ({info})")
            check(not info["lu"], f"{tag}: lu- classes {info['lu']}")
            if name != "Cover" or True:
                check(info["h"] <= height + 4, f"{tag}: content {info['h']}px > marker height {height}")
            bg.setdefault(name, {})[theme] = info["bg"]
            pg.screenshot(path=str(SHOTS / f"{theme}-{name}.png"))
            if name == "Dropdown":
                root = pg.locator('[phx-hook="LedgerUI.Dropdown"]:not([class*="animate"])').first
                trig = root.locator("button").first
                trig.scroll_into_view_if_needed(); trig.click(); pg.wait_for_timeout(300)
                ok = "open" in (root.get_attribute("class") or "") and root.locator("[role=menu]").first.is_visible()
                check(ok, f"{tag}: dropdown opens on click")
                pg.screenshot(path=str(SHOTS / f"{theme}-Dropdown-open.png"))
                pg.mouse.click(2, 2); pg.wait_for_timeout(300)
                check("open" not in (root.get_attribute("class") or ""), f"{tag}: dropdown closes on click-away")
                print(f"ok   {tag}: dropdown opens and closes")
            if name == "Modal":
                # the vitrine examples are inline modals (always shown, no trigger): check the dialog renders, the close button
                # is clickable, and that the JS-command runtime hides/shows an overlay (execJS, as phx-click="[[...]]" does)
                dlg = pg.locator("[role=dialog]:visible, [role=alertdialog]:visible")
                check(dlg.count() > 0, f"{tag}: no visible dialog")
                pg.locator("[data-part=modal-close]").first.click(); pg.wait_for_timeout(200)
                ov = pg.locator("#mo-chip")
                hid = pg.evaluate("""() => { const el = document.querySelector('#mo-chip'), n = document.querySelector('[data-part=modal-close]')
                  const run = (c) => window.LedgerUI.liveSocket.execJS(n, JSON.stringify(c))
                  run([["hide", {"to": "#mo-chip", "time": 0}]]); return new Promise(res => setTimeout(() => { const hidden = getComputedStyle(el).display === "none"
                    run([["show", {"to": "#mo-chip", "time": 0}]]); setTimeout(() => res([hidden, getComputedStyle(el).display !== "none"]), 300) }, 300)) }""")
                check(hid == [True, True], f"{tag}: JS commands hide/show on the modal overlay {hid}")
                pg.screenshot(path=str(SHOTS / f"{theme}-Modal-after.png"))
                print(f"ok   {tag}: modal renders ({dlg.count()} dialogs), close clickable, hide/show via execJS")
            if name == "Tabs":
                tabs = pg.locator("[role=tab]")
                if check(tabs.count() > 1, f"{tag}: tabs has no [role=tab]"):
                    t2 = tabs.nth(1); t2.scroll_into_view_if_needed(); t2.click(); pg.wait_for_timeout(300)
                    check(t2.get_attribute("aria-selected") == "true", f"{tag}: second tab becomes selected")
                    pg.screenshot(path=str(SHOTS / f"{theme}-Tabs-clicked.png"))
                    print(f"ok   {tag}: tabs switch")
            errs2 = [e for e in errs]
            check(not errs2, f"{tag}: errors after interaction {errs2[:3]}")
            pg.close()
        ctx.close()
    for name, v in bg.items():
        check(v["light"] != v["dark"], f"{name}: body background is the same in light and dark ({v['light']})")


with sync_playwright() as p:
    kw = {"executable_path": "/usr/bin/chromium"} if os.path.exists("/usr/bin/chromium") else {}
    b = p.chromium.launch(args=["--no-sandbox"], **kw)
    run(b)
    b.close()
uniq = sorted(set(re.sub(r"^(light|dark) ", "", n) for n in notes))
print(f"previews: {len(names)} x 2 themes   warnings: {len(uniq)}")
for n in uniq[:25]:
    print("  warn", n[:200])
print("FAILS:", len(fails))
sys.exit(1 if fails else 0)
