"""Checks out/publish/vitrine/ in a real browser (served by python http.server). Screenshots -> out/publish/_check/.
   /home/alex/ElixirProjects/open-source/.venv-ledger/bin/python scripts/publish/check.py"""
import subprocess, sys, time, pathlib, socket
from playwright.sync_api import sync_playwright

root = pathlib.Path(__file__).resolve().parents[2]
site, shots = root / "out/publish/vitrine", root / "out/publish/_check"
shots.mkdir(parents=True, exist_ok=True)
s = socket.socket(); s.bind(("127.0.0.1", 0)); port = s.getsockname()[1]; s.close()
srv = subprocess.Popen([sys.executable, "-m", "http.server", str(port), "--bind", "127.0.0.1"], cwd=site, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
time.sleep(1)
base = f"http://127.0.0.1:{port}/"
fails = []
def check(cond, msg):
    print(("ok   " if cond else "FAIL ") + msg)
    if not cond: fails.append(msg)

try:
    with sync_playwright() as p:
        b = p.chromium.launch(executable_path="/usr/bin/chromium", args=["--no-sandbox"])
        for theme in ("light", "dark"):
            ctx = b.new_context(viewport={"width": 1400, "height": 900}, color_scheme=theme)
            def visit(path, name):
                pg = ctx.new_page()
                errs, reqs = [], []
                pg.on("console", lambda m: errs.append(m.text) if m.type == "error" else None)
                pg.on("pageerror", lambda e: errs.append(str(e)))
                pg.on("request", lambda r: reqs.append(r.url))
                pg.on("response", lambda r: errs.append(f"{r.status} {r.url}") if r.status >= 400 else None)
                pg.goto(base + path); pg.wait_for_load_state("networkidle"); pg.wait_for_timeout(400)
                bg = pg.evaluate("getComputedStyle(document.body).backgroundColor")
                check(bg != "rgba(0, 0, 0, 0)" and pg.evaluate("document.fonts.size >= 0"), f"[{theme}] {path}: styled (body bg {bg})")
                pg.screenshot(path=str(shots / f"{theme}-{name}.png"))
                return pg, errs, reqs
            def done(pg, errs, reqs, path):
                check(not errs, f"[{theme}] {path}: no console/network errors {errs[:3]}")
                check(not [r for r in reqs if "localhost" in r or ":41" in r or not r.startswith(base) and not r.startswith("data:")], f"[{theme}] {path}: only local requests")
                pg.close()
            for path in ["index.html", "c/button.html", "instalacao.html", "cores.html", "temas.html", "novidades.html", "templates.html"]:
                pg, e, r = visit(path, path.replace("/", "_").replace(".html", "")); done(pg, e, r, path)
            # dropdown
            pg, e, r = visit("c/dropdown.html", "dropdown")
            root_dd = pg.locator("#dd2-neutral")
            trig = root_dd.locator("button").first
            trig.scroll_into_view_if_needed(); trig.click(); pg.wait_for_timeout(300)
            check("open" in (root_dd.get_attribute("class") or "") and root_dd.locator("[role=menu]").first.is_visible(), f"[{theme}] dropdown opens on click")
            pg.screenshot(path=str(shots / f"{theme}-dropdown-open.png"))
            pg.mouse.click(2, 2); pg.wait_for_timeout(300)
            check("open" not in (root_dd.get_attribute("class") or ""), f"[{theme}] dropdown closes on click-away")
            done(pg, e, r, "c/dropdown.html")
            # modal
            pg, e, r = visit("c/modal.html", "modal")
            btn = pg.locator("[phx-click*='\"show\"'], [phx-click*='add_class'], [phx-click*='set_attr']").first
            btn.scroll_into_view_if_needed(); btn.click(); pg.wait_for_timeout(500)
            dlg = pg.locator("[role=dialog]:visible, dialog[open], [data-lu-overlay].open [role=dialog]").first
            check(dlg.count() > 0, f"[{theme}] modal opens on click")
            pg.screenshot(path=str(shots / f"{theme}-modal-open.png"))
            done(pg, e, r, "c/modal.html")
            # tabs
            pg, e, r = visit("c/tabs.html", "tabs")
            tabs = pg.locator("[role=tab]")
            if tabs.count() > 1:
                t2 = tabs.nth(1); t2.scroll_into_view_if_needed(); t2.click(); pg.wait_for_timeout(300)
                check(t2.get_attribute("aria-selected") == "true", f"[{theme}] second tab becomes selected")
            else: check(False, "tabs: no [role=tab]")
            pg.screenshot(path=str(shots / f"{theme}-tabs-clicked.png"))
            done(pg, e, r, "c/tabs.html")
            # sidebar / rail_module
            pg, e, r = visit("c/sidebar.html", "sidebar"); done(pg, e, r, "c/sidebar.html")
            pg, e, r = visit("c/sub-nav.html", "rail_module")
            rail = pg.locator("[phx-click*='hidden']").first
            if rail.count():
                rail.scroll_into_view_if_needed()
                before = pg.evaluate("document.querySelectorAll('[hidden]').length")
                rail.click(); pg.wait_for_timeout(400)
                mid = pg.evaluate("document.querySelectorAll('[hidden]').length")
                pg.screenshot(path=str(shots / f"{theme}-rail_module-open.png"))
                rail.click(); pg.wait_for_timeout(400)
                after = pg.evaluate("document.querySelectorAll('[hidden]').length")
                check(mid != before and after == before, f"[{theme}] rail_module group opens and closes (hidden {before}->{mid}->{after})")
            else: check(False, "sub-nav (rail_module): no toggle with hidden attr")
            done(pg, e, r, "c/sub-nav.html")
            # template
            pg, e, r = visit("t/dashboard.html", "t-dashboard"); done(pg, e, r, "t/dashboard.html")
            # search palette + nav
            pg, e, r = visit("index.html", "search")
            pg.keyboard.press("Control+k"); pg.wait_for_timeout(200); pg.keyboard.type("butt"); pg.wait_for_timeout(300)
            pg.screenshot(path=str(shots / f"{theme}-search.png"))
            pg.keyboard.press("Enter"); pg.wait_for_url("**/c/*.html"); pg.wait_for_load_state("networkidle")
            check("/c/" in pg.url, f"[{theme}] search + Enter navigates to {pg.url}")
            pg.click("a.d-brand"); pg.wait_for_url("**/index.html"); pg.wait_for_load_state("networkidle")
            check(pg.url.endswith("/index.html") or pg.url == base, f"[{theme}] brand link goes home ({pg.url})")
            pg.close()
            if theme == "light":
                pg, e, r = visit("c/button.html", "button")
                pg.click("#th"); pg.wait_for_timeout(200)
                check(pg.evaluate("document.documentElement.dataset.theme") == "dark", "theme toggle works")
                pg.close()
            ctx.close()
        b.close()
finally:
    srv.terminate()
print("FAILS:", len(fails))
sys.exit(1 if fails else 0)
