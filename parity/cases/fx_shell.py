"""Rodada de correções FX (shell/app): recursos novos de ai_tool_trace (variant bare), navbar_search (demo typing),
theme_picker (open), theme_switch (value + slot icon), sidebar_nav_link (color + count), main_sidebar_link (count),
rail_workspace (bare), ai_chat (variants default/canvas/bare/page + compact). Lado original: marcação do bundle da
referência (classes lu-*, helpers dos geradores cN.py)."""
from _common import *
import base
from base import menu_item

W = {
    "fx-ai-tool-trace-bare": 420, "fx-navbar-search-typing": 300, "fx-theme-picker-menu-open": 240,
    "fx-theme-switch-value": 300, "fx-sidebar-nav-color": 220, "fx-sidebar-nav-count": 260,
    "fx-main-sidebar-count": 120, "fx-rail-workspace-bare": 300, "fx-ai-chat-variants": 360,
}

TOOLS = [("check-circle", "buscar_pedidos", "status=atrasado", "0,4s"), ("check-circle", "ler_extrato", "Banco do Brasil", "1,1s"),
         ("refresh", "conciliar", "64 lançamentos", "0,7s")]
TRACE = '<div class="lu-trace">' + "".join(
    f'<div class="lu-trace-i">{ic(i,"md")}<span class="nm">{n}</span><span class="lu-xs lu-muted">{d}</span><span class="ms">{t}</span></div>'
    for i, n, d, t in TOOLS) + "</div>"

SEARCH = (f'<span class="lu-input search m-type" style="width:240px;height:36px;border-radius:10px">{ic("search","md")}'
          '<span class="val"><span class="typed" style="--steps:7">pedidos</span><span class="caret"></span></span><kbd class="lu-kbd">⌘K</kbd></span>')

THM = ["Ledger", "Noite", "Areia", "Oceano"]
MENU = '<div class="lu-pop" style="width:200px">' + "".join(menu_item(n, None, sel=k == 0) for k, n in enumerate(THM)) + "</div>"


def ts(on, cls=""):
    return f'<span class="lu-ts {cls}">' + "".join(
        f'<span class="{"on" if k == on else ""}">{ic(i,"md")}</span>' for k, i in enumerate(["sun", "moon", "monitor"])) + "</span>"


TS = row(ts(1), ts(2, "icons"), ts(2, "icons sm"), f'<span class="lu-sw on"><i></i><span class="t">{ic("moon","md")}</span></span>')

NAV_COLORS = ["neutral", "secondary", "info", "success", "warning", "error"]
NAV = '<div style="display:flex;flex-direction:column;gap:6px">' + "".join(
    f'<span class="lu-nav-item on c-{c}" style="background:var(--c-soft);color:var(--c-ink)">{ic("grid","md")}Item</span>' for c in NAV_COLORS) + "</div>"

NAVR = ('<div style="display:flex;flex-direction:column;gap:6px">'
        f'<span class="lu-nav-item on">{ic("cart","md")}Vendas<span class="r">1.096</span></span>'
        f'<span class="lu-nav-item">{ic("wallet","md")}Financeiro<span class="r">12</span></span>'
        f'<span class="lu-nav-item">{ic("plus","md")}Novo pedido<span class="r">N</span></span></div>')

RAIL = ('<div style="display:flex;gap:8px;padding:10px">'
        f'<button class="lu-rail-btn" type="button" aria-label="Notas">{ic("invoice")}<span class="lu-count warn">3</span></button>'
        f'<button class="lu-rail-btn" type="button" aria-label="Alertas">{ic("bell")}<span class="lu-count">12</span></button></div>')

WS = (f'<div class="lu-ws" style="width:280px;box-sizing:border-box;margin-bottom:0"><span class="logo">{c6.LOGO}</span><span class="t"><b>Ledgerly</b>'
      f'<span>Orbit Cloud · Finance</span></span>{ic("updown","md lu-muted")}</div>')

CELLS = {"default": "lu-panel", "canvas": "lu-cv flat", "bare": "", "page": "lu-cv default"}
CHAT = '<div style="display:flex;flex-direction:column;gap:8px">' + "".join(
    f'<div class="{c}" style="padding:12px;width:100%;min-height:0"><span class="lu-small">variant={v}</span></div>' for v, c in CELLS.items()) + "</div>"

# rail_workspace pinta o logo com o accent (o canvas usa o logo inverso: o exemplo da vitrine passa <.logo tone="mono">)
WS_ACCENT = ".lu-ws .logo { background: var(--accent-soft); color: var(--accent-ink); }"

# o legado não zera o padding do <button> (UA: 1px 6px), como em shell_b.py (BTN0)
BTN0 = ".lu-rail-btn { padding: 0; }"

C = {
    "fx-ai-tool-trace-bare": (420, TRACE),
    "fx-navbar-search-typing": (300, SEARCH),
    "fx-theme-picker-menu-open": (240, MENU),
    "fx-theme-switch-value": (300, TS),
    "fx-sidebar-nav-color": (220, NAV),
    "fx-sidebar-nav-count": (260, NAVR),
    "fx-main-sidebar-count": (120, RAIL, BTN0),
    "fx-rail-workspace-bare": (300, WS, WS_ACCENT),
    "fx-ai-chat-variants": (360, CHAT),
}
