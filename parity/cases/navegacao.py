"""Navegação: tabs, breadcrumb, pagination, stepper, menu list, scrollspy, view switcher, dropdown,
action menu / action button, context menu (lado original). O mesmo id existe em navegacao.exs.

Menus (dropdown, action menu): o original abre o menu como a vitrine (`lu-anc` > `.fl` visível); o lado
HEEx usa `demo="loop"` (o menu desenhado aberto, sem camada superior). O menu de contexto só abre com
o ponteiro (popover), então o seu visual é o mesmo `lu-pop`/`lu-menu-item` do dropdown e a abertura é
verificada no navegador (ver o relatório)."""
from _common import *
from base import menu_item, kbd, btn, ibtn, badge, av, grid
from c7 import b

TVARS = ["line", "boxed", "pill", "text", "segmented", "nav"]
TSIZES = ["xs", "sm", "md"]
C = {}


def tabs(v="line", size="md", color="", on=0, items=("Todas", "Abertas", "Pagas"), vert=False):
    return c10.tabs(v, size, color, on, items, vert)


# ---------------------------------------------------------------- tabs
C["tabs-matrix"] = (900, colm(*[row(*[tabs(v, s) for s in TSIZES]) for v in TVARS]))
C["tabs-color"] = (700, row(colm(tabs("pill", color="primary"), tabs("pill", color="neutral"), tabs("text", color="primary"), tabs("text", color="neutral")),
                            tabs("line", vert=True, items=("Geral", "Cobrança", "Equipe", "Integrações"), on=1),
                            tabs("nav", vert=True, items=("Geral", "Cobrança", "Equipe"), on=0)))
C["tabs-active"] = (700, colm(*[tabs(v, "md", on=2) for v in TVARS]))
C["tabs-vertical"] = (900, row(*[tabs(v, s, vert=True, items=("Geral", "Cobrança", "Equipe"), on=1) for v, s in [("boxed", "md"), ("boxed", "sm"), ("pill", "md"), ("text", "sm"), ("segmented", "md"), ("line", "xs")]]))
C["tabs-count"] = (700, colm(
    '<div class="lu-tb line" role="tablist">' + "".join(f'<button type="button" role="tab" class="{"on" if i == 0 else ""}">{t}{c}</button>' for i, (t, c) in enumerate([("Visão geral", ""), ("Faturas", badge("12", "")), ("Uso", ""), ("Atividade", badge("3", "acc")), ("Vencidas", badge("2", "neg"))])) + "</div>",
    '<div class="lu-tb boxed" role="tablist">' + "".join(f'<button type="button" role="tab" class="{"on" if i == 1 else ""}">{t}{c}</button>' for i, (t, c) in enumerate([("Todas", badge("48", "")), ("Abertas", badge("7", "acc")), ("Pagas", badge("41", "pos"))])) + "</div>"))
C["tabs-classic"] = (700, colm(
    '<div class="lu-tabs" role="tablist" data-lu-single>' + "".join(f'<button class="lu-tab {"on" if i == 0 else ""}" role="tab" aria-selected="{str(i == 0).lower()}" type="button">{t}{c}</button>' for i, (t, c) in enumerate([("Visão geral", ""), ("Faturas", badge("12", "")), ("Uso", ""), ("Atividade", badge("3", "acc")), ("Configurações", "")])) + "</div>",
    '<div class="lu-tabs" role="tablist" data-lu-single>' + "".join(f'<button class="lu-tab {"on" if i == 1 else ""}" role="tab" type="button">{ic(n, "md")}{t}</button>' for i, (n, t) in enumerate([("grid", "Overview"), ("trend-up", "Revenue"), ("users", "Customers")])) + "</div>"))

# link tabs: o CSS companheiro da lib estiliza `.lu-tb > a`
TAB_LINK_CSS = (".lu-tb > a { position: relative; height: 40px; border: 0; background: none; padding: 0; font-size: 14px; font-weight: 500; color: var(--muted); display: inline-flex; align-items: center; gap: 7px; text-decoration: none; cursor: pointer; }"
                ".lu-tb > a.on, .lu-tb > a[aria-current] { color: var(--ink); }"
                ".lu-tb.line > a.on::after, .lu-tb.line > a[aria-current]::after { content: \"\"; position: absolute; left: 0; right: 0; bottom: -1px; height: 2px; border-radius: 2px; background: var(--ink); }"
                ".lu-tb.boxed > a { height: 30px; padding: 0 12px; border-radius: 7px; } .lu-tb.boxed > a.on { background: var(--bg-panel); box-shadow: var(--shadow-xs), 0 0 0 1px var(--line); }"
                ".lu-tb.pill > a { height: 32px; padding: 0 14px; border-radius: 9px; } .lu-tb.pill > a.on { background: var(--teal-600); color: var(--on-accent); }"
                ".lu-tb.nav > a { height: 32px; padding: 0 10px; border-radius: 8px; } .lu-tb.nav > a.on { background: var(--bg-selected); }")
C["tabs-links"] = (700, colm(*['<div class="lu-tb %s" role="tablist">' % v + "".join(f'<a href="#" class="{"on" if i == 1 else ""}" {"aria-current=page" if i == 1 else ""}>{t}</a>' for i, t in enumerate(["Todas", "Abertas", "Pagas"])) + "</div>" for v in ["line", "boxed", "pill", "nav"]]), TAB_LINK_CSS)

# ---------------------------------------------------------------- breadcrumb
C["breadcrumb-variants"] = (700, colm(*[row(f'<span class="lu-xs lu-muted mono" style="width:80px">{v or "default"}</span>', c10.crumb(v)) for v in ["", "canvas", "plain", "bordered"]]))
C["breadcrumb-icon"] = (700, colm(
    '<nav class="lu-crumb" aria-label="Trilha">' + ic("grid", "md") + '<a href="#">Orbit Cloud</a><span class="s">/</span><span class="cur">Overview</span></nav>',
    '<nav class="lu-crumb canvas" aria-label="Trilha">' + ic("grid", "md") + '<a href="#">Orbit Cloud</a><span class="s">/</span><a href="#">Contas</a><span class="s">/</span><span class="cur">Nordic Pay</span></nav>'))
C["breadcrumb-truncated"] = (700, colm(
    '<nav class="lu-crumb" aria-label="Trilha"><a href="#">St. Aurelia General</a><span class="s">/</span><a href="#">…</a><span class="s">/</span><a href="#">ICU</a><span class="s">/</span><span class="cur">Cases</span></nav>',
    '<nav class="lu-crumb canvas" aria-label="Trilha"><a href="#">Início</a><span class="s">/</span><a href="#">…</a><span class="s">/</span><a href="#">Vendas</a><span class="s">/</span><span class="cur">Pedido #2491</span></nav>'))

# ---------------------------------------------------------------- pagination
C["pagination-matrix"] = (700, colm(*[row(f'<span class="lu-xs lu-muted mono" style="width:70px">{sh}</span>', *[c10.pg2(sh, s) for s in ["sm", "md", "lg"]]) for sh in ["canvas", "rounded", "pill"]]))
C["pagination-current"] = (600, colm(c10.pg2("canvas", "md", on="1"), c10.pg2("rounded", "md", on="4"), c10.pg2("pill", "sm", on="3")))
C["pagination-classic"] = (700, row('<span class="lu-small lu-muted">1–25 de 1.096</span>', '<span class="lu-grow"></span>',
                                   '<div class="lu-pages" data-lu-single>' + ibtn("chevron-left", "Anterior", "ghost sm") + "".join(f'<button type="button" class="{"on" if p == "2" else ""}">{p}</button>' for p in ["1", "2", "3", "4", "…", "44"]) + ibtn("chevron-right", "Próximo", "ghost sm") + "</div>"))
C["pagination-footer"] = (700, '<div class="lu-row"><span class="lu-small lu-muted" role="status">Showing 16–30 of 660</span><span class="lu-grow"></span>'
                          + c10.pg2("rounded", "sm", on="2") + '<form><select name="page_size" aria-label="Rows per page" class="lu-input sm"><option value="15" selected>15 / page</option><option value="30">30 / page</option></select></form></div>')

# ---------------------------------------------------------------- stepper
STEPS = [("Conta", "done"), ("Plano", "done"), ("Pagamento", "cur"), ("Revisão", "")]
C["steps-color"] = (760, colm(*[row(f'<span class="lu-xs lu-muted mono" style="width:80px">{c}</span>', c10.st2(color=c)) for c in ["neutral", "primary", "secondary", "info", "success", "warning", "error"]]))
C["steps-size"] = (760, colm(*[c10.st2(size=s) for s in ["xs", "sm", "md", "lg"]], c10.st2([("Conta", "done"), ("Plano", "done"), ("Pagamento", "err"), ("Revisão", "")])))
C["steps-vertical"] = (760, grid(c10.st2(vert=True, subs=["Dados do CNPJ", "Profissional", "Cartão final 4417", "Confirme e ative"]),
                                 c10.st2([("Pedido recebido", "done"), ("Separado", "done"), ("NF-e emitida", "cur"), ("Saiu para entrega", "")], "success", vert=True, subs=["14:02", "14:40", "agora", "—"]), cols=2))
C["steps-classic"] = (700, '<div class="lu-steps"><div class="lu-step done"><span class="n">' + ic("check", "sm") + '</span>Conta</div><div class="lu-step-line done"></div><div class="lu-step done"><span class="n">' + ic("check", "sm") + '</span>Plano</div><div class="lu-step-line done"></div><div class="lu-step cur"><span class="n">3</span>Pagamento</div><div class="lu-step-line"></div><div class="lu-step"><span class="n">4</span>Revisão</div></div>')

# ---------------------------------------------------------------- menu list
MLI = [("grid", "Visão geral"), ("cart", "Pedidos"), ("users", "Clientes"), ("wallet", "Financeiro")]


def ml(v, c="primary", counts=False):
    return f'<nav class="lu-ml {v} c-{c}">' + "".join(f'<a href="#" class="{"on" if k == 1 else ""}">{ic(i)}{t}' + (f'<span class="lu-badge sm" style="margin-left:auto">{k * 4 + 3}</span>' if counts else "") + "</a>" for k, (i, t) in enumerate(MLI)) + "</nav>"


C["menu-list-matrix"] = (800, colm(*[row(*[ml(v, c) for v in ["link", "solid", "pill"]]) for c in ["primary", "neutral"]], *[row(*[ml(v, c) for v in ["gradient", "bordered", "static"]]) for c in ["primary", "neutral"]]))
C["menu-list-count"] = (500, row(ml("solid", counts=True), ml("pill", "neutral", counts=True)))
# o CSS companheiro da lib (priv/static/ledger_ui.css) define `lu-list`/`lu-list-row`, que o bundle do original não tem
LIST_CSS = (".lu-list { display: flex; flex-direction: column; background: var(--bg-panel); border: 1px solid var(--line); border-radius: var(--radius-lg); overflow: hidden; }"
            ".lu-list-row { display: flex; align-items: center; gap: 12px; padding: 10px 12px; border-bottom: 1px solid var(--line); color: inherit; text-decoration: none; }"
            ".lu-list-row:last-child { border-bottom: 0; } a.lu-list-row:hover, button.lu-list-row:hover, .lu-list-row[role=button]:hover { background: var(--bg-hover); }"
            ".lu-list-row .t { font-weight: 500; } .lu-list-row .s { font-size: 12.5px; color: var(--muted); }")
C["menu-row"] = (500, '<div class="lu-list"><div class="lu-list-row">' + ic("grid") + '<div style="flex:1;min-width:0"><div class="t" style="font-weight:500">Pedidos</div><div class="s lu-muted" style="font-size:12.5px">11 abertos</div></div><b>R$ 4.200</b><span role="img" aria-label="Unread" style="width:8px;height:8px;border-radius:50%;background:var(--accent);flex:none"></span></div>'
                  '<a href="#" class="lu-list-row"><div style="flex:1;min-width:0"><div class="t" style="font-weight:500">Clientes</div></div><span class="lu-muted">38</span></a></div>', LIST_CSS)

# ---------------------------------------------------------------- scrollspy (the mock; the real one is a hook)
C["scrollspy-demo"] = (420, '<div class="lu-spy" style="display:block;height:auto;width:170px"><nav>' + "".join(f'<a href="#" style="--dl:{k * 2}s">{t}</a>' for k, t in enumerate(["Dados gerais", "Endereço", "Fiscal", "Financeiro"])) + "</nav></div>")

# ---------------------------------------------------------------- view switcher
VIEWS = [("list", "Lista"), ("kanban", "Quadro"), ("calendar", "Agenda"), ("table", "Tabela")]


def vs(on=0, counts=False):
    return '<div class="lu-seg" data-lu-single>' + "".join(f'<button type="button" class="{"on" if i == on else ""}" aria-pressed="{str(i == on).lower()}">{ic(n, "md")}{t}{"<span class=n>" + str(i * 3 + 4) + "</span>" if counts else ""}</button>' for i, (n, t) in enumerate(VIEWS)).replace("<span class=n>", '<span class="n">') + "</div>"


C["view-switcher-seg"] = (700, colm(vs(0), vs(2), vs(1, True)))
C["view-switcher-row"] = (700, row(vs(0), btn("Pro churn watch", "", "folder", "chevron-down"), btn("Salvar visão", "ghost", "plus")))

# ---------------------------------------------------------------- dropdown
def dd_menu(hl=False, w=220):
    return f'<div class="lu-pop {"m-hl" if hl else ""}" style="width:{w}px">' + "".join(menu_item(t, i) for t, i in [("Editar", "edit"), ("Duplicar", "copy"), ("Compartilhar", "link"), ("Arquivar", "folder")]) + '<div class="lu-menu-sep"></div>' + menu_item("Excluir", "trash", cls="danger") + "</div>"


def anc(trigger, menu, place="bottom-start", box="height:300px;padding:10px 20px 0"):
    return f'<div style="{box}"><span class="lu-anc">{trigger}<span class="fl p-{place}">{menu}</span></span></div>'


TRIG = c7.b("Ações", "neutral", "outline", "md", after="chevron-down")
C["dropdown-open"] = (360, anc(TRIG, dd_menu()))
C["dropdown-open-end"] = (360, '<div style="height:300px;padding:10px 20px 0;text-align:right"><span class="lu-anc"><button class="lu-kebab" type="button" aria-label="Mais ações">' + ic("more-h") + '</button><span class="fl p-bottom-end">' + dd_menu() + "</span></span></div>")
C["dropdown-triggers"] = (900, row(*[b("Período", c, "solid" if c != "neutral" else "outline", "md", after="chevron-down") for c in ["neutral", "primary", "secondary", "info", "success", "warning", "error", "mono"]]))
C["dropdown-kebab"] = (700, row(f'<button class="lu-kebab" type="button" aria-label="Mais">{ic("more-h")}</button>', f'<button class="lu-kebab" type="button" aria-label="Mais">{ic("more-v")}</button>',
                                b("rounded", "neutral", "outline", "md", after="chevron-down"), b("pill", "neutral", "outline", "md", "pill", after="chevron-down")))
C["dropdown-split"] = (500, row('<span class="lu-split c-mono">' + b("Emitir NF-e", "mono", "solid") + b("", "mono", "solid", icon="chevron-down") + "</span>",
                                '<span class="lu-split c-primary">' + b("Salvar", "primary", "solid") + b("", "primary", "solid", icon="chevron-down") + "</span>",
                                '<span class="lu-split c-neutral">' + b("Exportar", "neutral", "outline") + b("", "neutral", "outline", icon="chevron-down") + "</span>"))
C["dropdown-items"] = (360, '<div class="lu-pop" style="width:280px">' + menu_item("Abrir pedido", "external") + menu_item("Emitir NF-e", "file", cls="c-primary") + '<div class="lu-menu-sep"></div>'
                        + "".join(f'<button class="lu-menu-item media" type="button">{ic("user")}<span class="tx">{n}<small>{r}</small></span></button>' for n, r in [("Ana Nogueira", "Financeiro"), ("Carlos André", "Dev")])
                        + '<div class="lu-menu-sep"></div>' + menu_item("Cancelar pedido", "x-circle", cls="c-error") + "</div>")
C["dropdown-rich"] = (700, row(
    '<div class="lu-pop" style="width:240px"><div class="lu-menu-label">Período</div>' + menu_item("Out 2026", "calendar", sel=True) + menu_item("Sep 2026", "calendar") + menu_item("Q3 2026", "calendar") + '<div class="lu-menu-sep"></div>' + menu_item("Personalizado…", "edit") + "</div>",
    '<div class="lu-pop" style="width:250px">' + menu_item("Editar", "edit", kbd("E")) + menu_item("Duplicar", "copy", kbd("⌘", "D")) + menu_item("Compartilhar", "link") + menu_item("Mover para", "folder", ic("chevron-right", "sm")) + '<div class="lu-menu-sep"></div>' + menu_item("Excluir", "trash", kbd("⌫"), cls="danger") + "</div>"))
C["dropdown-extras"] = (360, '<div class="lu-pop" style="width:260px"><div class="lu-menu-search">' + ic("search") + '<input type="text" placeholder="Buscar"></div>'
                        + '<div class="lu-menu-head" style="padding:8px 10px 6px"><div style="font-weight:500;color:var(--ink)">Ana Nogueira</div><div class="lu-muted" style="font-size:12px">ana@empresa.com</div></div><div class="lu-menu-sep"></div>'
                        + '<button class="lu-menu-item sel" type="button" role="menuitemcheckbox" aria-checked="true">Em aberto<span class="r"><span>12</span>' + ic("check", "sm ck") + '</span></button>'
                        + '<button class="lu-menu-item" type="button" role="menuitemcheckbox" aria-checked="false">Pagos<span class="r"><span>41</span>' + ic("check", "sm ck").replace('class="sm ck"', 'class="sm ck" style="visibility:hidden"') + '</span></button>'
                        + '<button class="lu-menu-item" type="button" aria-disabled="true">Arquivadas</button>'
                        + '<div class="lu-menu-foot" style="display:flex;gap:6px;justify-content:flex-end;padding:6px 0 0;margin-top:5px;border-top:1px solid var(--line)">'
                        + '<button class="lu-b c-neutral v-ghost s-sm sh-rounded" type="button">Clear</button><button class="lu-b c-primary v-solid s-sm sh-rounded" type="button">Apply (2)</button></div></div>')
PL = ["top-start", "top", "top-end", "right-start", "right", "right-end", "bottom-start", "bottom", "bottom-end", "left-start", "left", "left-end"]
C["dropdown-placement"] = (1100, '<div style="display:grid;grid-template-columns:repeat(4,1fr);gap:6px">' + "".join(
    f'<div style="height:170px;display:grid;place-items:center"><span class="lu-anc">{b(p, "neutral", "outline", "md", after="chevron-down")}<span class="fl p-{p}"><div class="lu-pop" style="width:230px">{menu_item("Editar", "edit")}{menu_item("Excluir", "trash", cls="danger")}</div></span></span></div>' for p in PL) + "</div>")

# ---------------------------------------------------------------- action menu / action button
AM_ITEMS = menu_item("Ver relatório", "external") + menu_item("Baixar CSV", "download") + menu_item("Comparar com 2025", "compare") + menu_item("Perguntar à IA", "sparkles") + '<div class="lu-menu-sep"></div>' + menu_item("Remover do dashboard", "x", cls="danger")
C["action-menu-open"] = (360, '<div style="height:300px;padding:10px 20px 0"><span class="lu-anc"><button aria-label="Ações" aria-haspopup="menu" aria-expanded="false" class="lu-b c-neutral v-ghost s-md" type="button">' + ic("more-h", "md")
                         + '</button><span class="fl p-bottom-end"><div class="lu-pop" style="width:230px" role="menu"><div class="lu-menu-label" role="presentation">Pedido #2491</div>' + AM_ITEMS + "</div></span></span></div>")
C["action-menu-trigger"] = (360, row('<button aria-label="Ações" class="lu-b c-neutral v-ghost s-md" type="button">' + ic("more-h", "md") + "</button>"))
C["action-menu-rich"] = (360, '<div class="lu-pop" style="width:260px">' + menu_item("Abrir", "external", kbd("↵")) + menu_item("Renomear", "edit", kbd("F2")) + menu_item("Copiar link", "link", kbd("⌘ L")) + '<div class="lu-menu-sep"></div>'
                         + '<button class="lu-menu-item media" type="button">' + ic("file") + '<span class="tx">Emitir NF-e<small>Gera o XML e o PDF</small></span></button>' + '<button class="lu-menu-item" type="button" aria-disabled="true">Arquivar</button>' + menu_item("Excluir", "trash", kbd("⌫"), cls="danger") + "</div>")
VARIANTS = ["solid", "glow", "outline", "soft", "bordered", "flat", "glass", "ghost", "dim"]
SIZES = ["xs", "sm", "md", "lg", "xl"]
C["action-button-variants"] = (700, colm(
    row(*[b("", "neutral", v, "sm", "square", icon="trash", extra=f'aria-label="Excluir {v}"') for v in VARIANTS]),
    row(*[b("", "error", v, "sm", "square", icon="trash", extra=f'aria-label="Excluir {v}"') for v in VARIANTS])))
C["action-button-sizes"] = (500, row(*[b("", "neutral", "ghost", s, "square", icon="more-h", extra='aria-label="Ações"') for s in SIZES]))
C["action-button-label"] = (500, row(b("Abrir", "neutral", "outline", "sm", icon="external", extra='aria-label="Abrir"'), b("Excluir", "error", "soft", "md", icon="trash", extra='aria-label="Excluir"')))
C["action-button-row"] = (600, '<div class="lu-panel" style="display:flex;align-items:center;gap:12px;padding:10px 14px;width:420px"><span class="lu-grow">Nordic Pay · INV-1043</span>' + b("", "error", "ghost", "sm", "square", icon="trash", extra='aria-label="Excluir"') + "</div>")

# ---------------------------------------------------------------- context menu (the open box: the same parts as the dropdown)
C["context-menu-box"] = (520, '<div class="lu-pop" style="width:230px" role="menu">' + menu_item("Abrir", "external", kbd("↵")) + menu_item("Renomear", "edit", kbd("F2")) + menu_item("Copiar link", "link", kbd("⌘ L")) + '<div class="lu-menu-sep"></div>' + menu_item("Excluir", "trash", kbd("⌫"), cls="danger") + "</div>")

# ---------------------------------------------------------------- as maquetes animadas (m-loop), no quadro estático
C["steps-loop"] = (760, c10.st2([("Pedido", ""), ("Separação", ""), ("Nota fiscal", ""), ("Entrega", "")], loop=True))
C["pagination-loop"] = (500, c10.pg2(loop=True))
C["menu-list-loop"] = (400, '<nav class="lu-ml pill c-primary m-loop">' + "".join(f'<a href="#" style="--dl:{k * 1.5}s">{ic(i)}{t}</a>' for k, (i, t) in enumerate(MLI)) + "</nav>")
