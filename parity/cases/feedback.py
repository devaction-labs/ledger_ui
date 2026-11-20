"""Feedback: alert, aura, empty_state, error_page, progress, skeleton, spinner, toast, connection_banner (lado original)."""
from _common import *
from actions import b
import json

C = {}
PCOL = ["neutral", "primary", "secondary", "info", "success", "warning", "error", "white"]


def stack(*x, gap=10, align=None):
    a = f";align-items:{align}" if align else ""
    return f'<div style="display:flex;flex-direction:column;gap:{gap}px{a}">' + "".join(x) + "</div>"


# ------------------------------------------------------------------ alert
ACOL = ["neutral", "primary", "secondary", "info", "success", "warning", "error", "dark"]
AIC = {"neutral": "info", "primary": "sparkles", "secondary": "ai", "info": "info", "success": "check-circle", "warning": "alert", "error": "x-circle", "dark": "info"}


def alert(c, v, title="Título do aviso", desc="Uma frase de contexto.", shape="", accent="", action=False, dismiss=False):
    a = b("Ação", c if v != "solid" else "white", "soft" if v != "solid" else "solid", "xs") if action else ""
    d = f'<button class="x" type="button" aria-label="Fechar" style="border:0;background:none;color:inherit;opacity:.7;cursor:pointer">{ic("x", "md")}</button>' if dismiss else ""
    return f'<div class="lu-al c-{c} v-{v} {shape} {accent}" role="alert">{ic(AIC[c])}<div class="t"><b>{title}</b><span>{desc}</span></div>{a}{d}</div>'


for v in ["canvas", "soft", "bordered", "outline", "solid"]:
    C[f"alert-{v}"] = (420, colm(*[alert(c, v, c.title(), "Contexto curto.") for c in ACOL]))
C["alert-pill"] = (520, colm(alert("info", "soft", "Dados de demonstração", "Workspace com dados gerados.", shape="sh-pill"),
                             alert("warning", "bordered", "Atenção", "Revise antes de continuar.", shape="sh-pill"),
                             alert("neutral", "canvas", "Aviso", "Contexto curto.", shape="sh-pill", dismiss=True)))
T7 = "7 de 11 cancelamentos Pro vieram de falha de pagamento"
C["alert-accent"] = (560, colm(alert("warning", "canvas", T7, "Revise a régua de cobrança.", accent="accent", action=True, dismiss=True),
                               alert("error", "soft", "Sincronização falhou", "Última tentativa há 12 min.", accent="acc-left"),
                               alert("success", "outline", "Relatório exportado", "board-pack-oct-2026.pdf", accent="acc-right"),
                               alert("info", "solid", "Dados de demonstração", "Este workspace usa dados gerados.", accent="accent", action=True)))
C["alert-actions"] = (560, colm(*[alert(c, v, "Pagamento pendente", "Revise a régua.", action=True, dismiss=True) for c, v in
                                  [("primary", "soft"), ("error", "solid"), ("warning", "bordered"), ("info", "outline"), ("neutral", "canvas")]]))
C["alert-bare"] = (420, colm('<div class="lu-al c-warning" role="alert">Certificado vence em 3 dias</div>',
                             '<div class="lu-al c-info v-soft" role="alert">Só texto, sem ícone nem título</div>'))

# ------------------------------------------------------------------ aura
CHIP = '<span style="display:block;background:var(--bg-panel);padding:12px 16px;font-size:13.5px;white-space:nowrap">{}</span>'


def aura(inner, mode="spin", tone="accent", w="default", r="default", shadow=False):
    return f'<span class="lu-aura m-{mode} t-{tone} w-{w} r-{r} {"shadow" if shadow else ""}">{inner}</span>'


C["aura-modes"] = (520, row(*[aura(CHIP.format(m), m, "ai") for m in ["spin", "dual", "glow"]]))
C["aura-modes-accent"] = (520, row(*[aura(CHIP.format(m), m, "accent") for m in ["spin", "dual", "glow"]]))
C["aura-tones"] = (520, row(*[aura(CHIP.format(t), "spin", t) for t in ["accent", "ai", "info", "pos", "warn", "neg", "violet"]]))
C["aura-tones-dual"] = (520, row(*[aura(CHIP.format(t), "dual", t) for t in ["accent", "ai", "info", "pos", "warn", "neg", "violet"]]))
C["aura-tones-glow"] = (520, row(*[aura(CHIP.format(t), "glow", t) for t in ["accent", "ai", "info", "pos", "warn", "neg", "violet"]]))
C["aura-widths"] = (520, row(*[aura(CHIP.format("width=" + w), "spin", "ai", w) for w in ["xs", "sm", "default", "lg"]]))
C["aura-shapes"] = (520, row(aura(b("Resumir com IA", "neutral", "solid", "md", "pill", icon="sparkles"), "spin", "ai", "sm", "pill"),
                            aura(CHIP.format("r12 + shadow"), "spin", "accent", "default", "r12", True),
                            aura(CHIP.format("pill"), "dual", "info", "default", "pill", True)))

# ------------------------------------------------------------------ spinner
SVG = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><path d="M12 3a9 9 0 1 1-9 9"/></svg>'


def sp(v, s, c="primary"):
    return f'<span class="lu-sp c-{c} v-{v} s-{s}" role="status" aria-label="Carregando">{SVG if v == "svg" else ""}</span>'


C["spinner-variants"] = (380, colm(*[row(*[sp(v, s) for s in SIZES]) for v in ["canvas", "border", "soft", "grow", "svg"]]))
C["spinner-colors"] = (380, colm(row(*[sp("border", "md", c) for c in PCOL[:7]]), row(*[sp("canvas", "md", c) for c in PCOL[:7]]), row(*[sp("soft", "md", c) for c in PCOL[:7]])))

# ------------------------------------------------------------------ skeleton
C["skeleton-animation"] = (380, '<div style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:16px">' + "".join(
    f'<div class="lu-col" style="gap:8px"><span class="lu-xs lu-muted mono">{a}</span><div class="lu-sk a-{a}" style="width:80%"></div><div class="lu-sk a-{a}" style="width:55%"></div></div>' for a in ["wave", "pulse", "none"]) + "</div>")
C["skeleton-shapes"] = (380, row(*[f'<div class="lu-sk a-wave {s}" style="width:{w}px;height:{h}px"></div>' for s, w, h in
                                   [("", 48, 32), ("sh-pill", 64, 20), ("sh-circle", 40, 40), ("sh-square", 48, 32), ("sh-lg", 64, 40)]]))
C["skeleton-layout"] = (380, '<div class="lu-panel lu-col" style="padding:14px;gap:14px">' + "".join(
    '<div class="lu-row" style="flex-wrap:nowrap"><div class="lu-sk a-wave sh-circle" style="width:32px;height:32px"></div><div class="lu-col lu-grow" style="gap:6px"><div class="lu-sk a-wave" style="width:55%"></div><div class="lu-sk a-pulse" style="width:35%;height:10px"></div></div></div>' for _ in range(3)) + "</div>")
C["skeleton-lineone"] = (380, colm('<div class="lu-sk a-wave" style="width:60%;border-radius:3px"></div>', '<div class="lu-sk a-wave" style="width:40%;height:34px;border-radius:3px"></div>'))

# ------------------------------------------------------------------ progress
for v in ["solid", "soft", "gradient"]:
    C[f"progress-{v}"] = (420, colm(*[f'<div class="lu-pg c-{c} v-{v}" style="width:100%"><i style="width:{40 + i * 8}%"></i></div>' for i, c in enumerate(PCOL)]))
C["progress-default"] = (420, colm('<div class="lu-pg c-neutral"><i style="width:64%"></i></div>', '<div class="lu-pg c-primary"><i style="width:0%"></i></div>', '<div class="lu-pg c-success"><i style="width:100%"></i></div>'))
C["progress-sizes"] = (420, colm(*[f'<div class="lu-pg c-primary s-{s}"><i style="width:68%">{"68%" if s == "xl" else ""}</i></div>' for s in ["sm", "md", "lg", "xl"]]))
C["progress-heights"] = (420, colm(*[f'<div class="lu-pg c-info" style="--hgt:{px}px"><i style="width:60%"></i></div>' for px in [4, 6, 8, 12, 16]]))
C["progress-states"] = (420, colm(
    '<div class="lu-pg c-primary"><i style="width:35%;animation:lu-ind 1.3s ease-in-out infinite"></i></div>',
    '<div class="lu-pg c-primary"><i style="width:60%;background-image:repeating-linear-gradient(45deg,rgba(255,255,255,.22) 0 8px,transparent 8px 16px);background-size:22px 22px;animation:lu-stripes .8s linear infinite"></i></div>',
    '<div class="lu-pg c-primary"><i style="width:100%;background:linear-gradient(90deg,transparent,var(--c),transparent);animation:lu-ind 1.3s ease-in-out infinite"></i></div>',
    '<div class="lu-pg c-success v-soft s-lg"><i style="width:45%;background-image:repeating-linear-gradient(45deg,rgba(255,255,255,.22) 0 8px,transparent 8px 16px);background-size:22px 22px;animation:lu-stripes .8s linear infinite"></i></div>'))
# os tons 2 e 5 do gráfico são hex fixos (parecem teal), então ficam de fora: o caso vale para o tema próprio também
C["progress-stack"] = (420, colm('<div class="lu-pgstack"><i style="width:52.6%;background:var(--chart-1)"></i><i style="width:26.6%;background:var(--chart-3)"></i><i style="width:20.8%;background:var(--chart-4)"></i></div>',
                                 '<div class="lu-pgstack"><i style="width:40%;background:var(--chart-3)"></i><i style="width:30%;background:var(--chart-4)"></i></div>'))

# ------------------------------------------------------------------ empty_state
EMP_TEXT = "Conecte o Stripe para ver a retenção mês a mês dos seus clientes."
C["empty-canvas"] = (360, colm('<div class="lu-panel"><div class="lu-empty"><span class="art">' + ic("table", "lg") + '</span><b>Nenhuma coorte ainda</b><p>' + EMP_TEXT + '</p>' + b("Conectar Stripe", "neutral", "solid", "sm") + "</div></div>",
                               '<div class="lu-panel"><div class="lu-empty" style="--muted:var(--pos)"><span class="art">' + ic("check-circle", "lg") + '</span><b>Tudo em dia</b><p>Nenhuma fatura vencida.</p></div></div>',
                               '<div class="lu-panel"><div class="lu-empty"><b>Sem ícone</b></div></div>'))


def emp_card(tone="default", title="Nenhum pedido ainda", kicker="", level=""):
    t = {"default": "", "gradient": "acc", "positive": "pos"}[tone]
    k = f'<span class="lu-xs lu-muted" style="text-transform:uppercase;letter-spacing:.06em">{kicker}</span>' if kicker else ""
    lv = f' role="heading" aria-level="{level}"' if level else ""
    return (f'<div class="lu-panel"><div class="lu-col" style="align-items:center;gap:10px;text-align:center;padding:26px"><span class="lu-empty-ring" style="display:inline-grid"><span class="lu-ic {t}" style="width:52px;height:52px">{ic("inbox", "lg")}</span></span>'
            f'{k}<b{lv}>{title}</b><span class="lu-small lu-muted">Os pedidos do balcão e do site aparecem aqui.</span>{b("Novo pedido", "mono", "solid", "sm", icon="plus")}</div></div>')


C["empty-card"] = (900, '<div style="display:grid;grid-template-columns:repeat(3,1fr);gap:16px">' + "".join(emp_card(t) for t in ["default", "gradient", "positive"]) + "</div>")
C["empty-card-heading"] = (360, emp_card("default", "Nenhum pedido", "Pedidos", 3))
C["empty-inline"] = (420, colm(*[f'<div class="lu-row lu-panel" style="padding:12px 14px;color:var(--{c});border-style:dashed">{ic("inbox", "md")}Sem comentários ainda.Escrever o primeiro</div>' for c in ["muted", "pos", "neg"]]))
C["empty-plain"] = (420, '<div class="lu-panel" style="padding:8px 12px"><div class="lu-row lu-small lu-muted" style="padding:10px 4px">' + ic("check-circle", "md") + "Tudo em dia — nenhuma fatura vencida.</div></div>")
C["empty-table"] = (420, '<div class="lu-panel">' + "".join(
    f'<div class="lu-col" style="align-items:center;gap:8px;text-align:center;padding:32px 16px"><span class="lu-av c-{c} v-soft sh-rounded" style="--s:48px">{ic("inbox", "md")}</span><b>Nada por aqui</b><span class="lu-small lu-muted">Importe uma planilha para começar.</span>{b("Importar", "neutral", "outline", "sm")}</div>'
    for c in ["neutral", "success", "error"]) + "</div>")

# ------------------------------------------------------------------ error_page / error_state / error_links
# regras da página de erro: só existem no CSS companheiro da lib (priv/static/ledger_ui.css), não no bundle da referência
ERR_CSS = """.lu-err{min-height:100vh;display:flex;flex-direction:column;background:var(--bg-page,var(--bg-panel));color:var(--ink)}
.lu-err>header{display:flex;align-items:center;justify-content:space-between;gap:16px;padding:20px 32px}
.lu-err>footer{justify-content:space-between;gap:16px;padding:16px 32px;border-top:1px solid var(--line)}
.lu-err h1{margin:0;font-size:36px;line-height:1.1;letter-spacing:-.02em}
@media (max-width:767px){.lu-err>header,.lu-err>footer{padding-left:16px;padding-right:16px}.lu-err h1{font-size:28px}}"""
TONE = {"neutral": "var(--ink-2)", "error": "var(--neg)", "warning": "var(--warn)", "accent": "var(--accent)"}


def err_links(title, links):
    items = "".join(
        f'<a class="lu-row lu-panel" style="gap:12px;padding:10px 12px;text-decoration:none;color:inherit" href="#"><span class="lu-ic" style="">{ic(i)}</span><span class="lu-col lu-grow" style="gap:0"><b>{t}</b><span class="lu-xs lu-muted">{d}</span></span>{ic("chevron-right", "sm")}</a>'
        for i, t, d in links)
    return f'<nav aria-label="{title}" class="lu-col" style="gap:6px;width:100%;max-width:460px"><span class="lu-xs lu-muted" style="text-transform:uppercase;letter-spacing:.06em">{title}</span>{items}</nav>'


def err_page(code, tone, label, title, desc, header="", actions="", extra="", card="", footer=""):
    c = TONE[tone]
    act = f'<div class="lu-row" style="gap:10px;margin-top:6px">{actions}</div>' if actions else ""
    cd = f'<div style="position:absolute;left:24px;right:24px;bottom:24px">{card}</div>' if card else ""
    return (f'<main class="lu-err" aria-labelledby="e-title">{header}'
            '<div style="flex:1;display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:48px;align-items:center;padding:32px;max-width:1200px;width:100%;margin:0 auto">'
            f'<div class="lu-col" style="gap:14px;align-items:flex-start"><span class="lu-row lu-small" style="gap:8px"><span class="lu-badge mono" style="color:{c}">{code}</span><span class="lu-muted">{label}</span></span>'
            f'<h1 id="e-title">{title}</h1><p class="lu-muted" style="margin:0;max-width:460px">{desc}</p>{act}{extra}</div>'
            f'<aside aria-hidden="true" style="position:relative;min-height:320px;display:grid;place-items:center;border-radius:24px;overflow:hidden;background-image:radial-gradient(var(--line-strong) 1px,transparent 1px);background-size:18px 18px;background-color:var(--bg-tray)">'
            f'<span class="mono" style="font-size:230px;font-weight:700;letter-spacing:-.06em;line-height:1;color:transparent;-webkit-text-stroke:1.5px {c};opacity:.55">{code}</span>{cd}</aside></div>{footer}</main>')


HDR = ('<header><div class="lu-row" style="gap:8px"><b>Acme</b></div>'
       '<a class="lu-row lu-small lu-muted" style="gap:8px;text-decoration:none" href="https://status.acme.com"><span class="lu-dot" style="color:var(--pos)"></span>All systems operational</a></header>')
FTR = ('<footer class="lu-row lu-small lu-muted"><span class="lu-row" style="gap:8px"><span>Request ID: <code class="mono" style="user-select:all">req_8f2a91</code></span>'
       '<button type="button" class="lu-btn icon ghost sm" aria-label="Copy request ID">' + ic("copy") + '</button><span>2026-11-04 14:22 UTC</span></span>'
       '<span class="lu-row" style="gap:12px"><a href="/help">Help center</a></span></footer>')
C["error-page-404"] = (1100, err_page("404", "neutral", "Page not found", "We could not find that page", "The address may have changed or the page was removed.", HDR,
                                      b("Back home", "neutral", "solid", "lg") + b("Go back", "neutral", "outline", "md"), err_links("Maybe you were looking for", [("file", "Orders", "Every order"), ("users", "Customers", "")]), footer=FTR), ERR_CSS)
C["error-page-500"] = (1100, err_page("500", "error", "Server error", "Something went wrong on our side", "We were notified and are looking into it. Try again in a moment.", "",
                                      b("Try again", "neutral", "solid", "md"), card='<div class="lu-panel" style="padding:12px 14px">Incident INC-204 is being investigated</div>'), ERR_CSS)
C["error-page-tones"] = (1100, err_page("403", "warning", "Forbidden", "You do not have access", "Ask the owner of the workspace to grant you access.", "", "") +
                         err_page("419", "accent", "Page expired", "This page expired", "Reload it and try again.", "", ""), ERR_CSS)


def err_state(code, tone, icon, title, desc, actions="", more=""):
    c = TONE[tone]
    act = f'<div class="lu-row" style="gap:10px;margin-top:6px">{actions}</div>' if actions else ""
    mo = f'<div style="width:100%;margin-top:12px">{more}</div>' if more else ""
    return (f'<section class="lu-col" aria-labelledby="s-{code}" style="align-items:center;gap:8px;padding:20px;text-align:center">'
            f'<span class="lu-errnum" aria-hidden="true" style="font-size:150px;background:none;-webkit-text-fill-color:currentColor;color:{c}">{code}</span>'
            f'<span class="lu-ic lg">{ic(icon)}</span><b id="s-{code}">{title}</b><span class="lu-small lu-muted">{desc}</span>{act}{mo}</section>')


C["error-state"] = (420, colm(
    err_state("404", "neutral", "search", "Order #2499 not found", "It may have been deleted or belong to another branch."),
    err_state("500", "error", "alert", "We were notified", "Try again in a moment.", b("Retry", "neutral", "solid", "sm")),
    err_state("403", "warning", "lock", "You do not have access", "Ask the owner.", b("Request access", "neutral", "outline", "sm"), err_links("Try instead", [("file", "Orders", "Every order")])),
    err_state("401", "accent", "lock", "Sign in to continue", "Your session ended.")))
C["error-links"] = (420, err_links("Maybe you were looking for", [("file", "Orders", "Every order"), ("users", "Customers", "People and companies"), ("settings", "Settings", "")]))

# ------------------------------------------------------------------ toast_card / status_toast / toaster
TIC = {"neutral": "info", "primary": "sparkles", "info": "info", "success": "check-circle", "warning": "alert", "error": "x-circle"}
SPIN = '<span class="lu-sp v-border s-sm c-primary" style="align-self:center"></span>'


def tcard(kind, title, desc="", tone="light", icon=None, acts="", busy=False, fill="", pct="", state="", x=True, aura=None):
    cls = f"lu-tcard c-{kind} {'dark' if tone == 'dark' else ''} {state}".replace("  ", " ").strip()
    xx = f'<button class="x" type="button" aria-label="Close">{ic("x", "sm")}</button>' if x else ""
    d = f"<span>{desc}</span>" if desc else ""
    tile = "" if icon is False else f'<span class="tile">{ic(icon or TIC[kind], "md")}</span>'
    card = (f'<div class="{cls}" style="width:100%">{fill}{tile}<div class="t"><b>{title}</b>{d}</div>{acts}{SPIN if busy else ""}{pct}{xx}</div>')
    if not aura: return card
    m, t, w = aura
    return f'<span class="lu-aura m-{m} t-{t} w-{w} shadow" style="width:100%;--r:15px">{card}</span>'


def wrap(x, w=380): return f'<div style="width:{w}px;max-width:100%">{x}</div>'


KINDS = [("neutral", "Alterações salvas"), ("primary", "Assistente pronto"), ("info", "Nova versão disponível"), ("success", "Relatório exportado"), ("warning", "Assentos em 80%"), ("error", "Falha ao sincronizar")]
GRID3 = lambda *x: '<div style="display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:12px">' + "".join(x) + "</div>"
C["toast-card-light"] = (900, GRID3(*[tcard(k, t, "Orbit Cloud · agora") for k, t in KINDS]))
C["toast-card-dark"] = (900, GRID3(*[tcard(k, t, "Orbit Cloud · agora", "dark") for k, t in KINDS[:2] + KINDS[3:4] + KINDS[5:]]))
C["toast-card-plain"] = (420, stack(tcard("neutral", "Só o título", icon=False, x=False), tcard("success", "Sem ícone", "Com descrição", icon=False, x=True),
                                   tcard("primary", "Escuro sem descrição", tone="dark")))
ACTS = b("Ver", "neutral", "outline", "sm")
C["toast-card-actions"] = (420, stack(tcard("primary", "3 new AI insights", "Churn liderado por Pro, expansão em Scale.", acts=b("Ver", "neutral", "solid", "sm") + b("Depois", "neutral", "ghost", "sm")),
                                      tcard("success", "Relatório exportado", "board-pack.pdf", acts=ACTS),
                                      tcard("error", "Falha ao sincronizar", "Tente de novo", acts=b("Tentar", "error", "soft", "sm"), tone="dark")))
C["toast-card-aura"] = (420, stack(
    tcard("primary", "Lendo a nota fiscal…", "O assistente está extraindo os itens.", icon="sparkles", busy=True, x=False, aura=("spin", "ai", "default")),
    tcard("success", "Conciliação pronta", "18 lançamentos casados", acts=ACTS, x=False, aura=("dual", "ai", "default")),
    tcard("warning", "Certificado vence hoje", "Renove para continuar", acts=b("Renovar", "neutral", "solid", "sm"), x=False, aura=("glow", "warn", "default")),
    tcard("info", "Aura fina", "width xs", x=False, aura=("spin", "info", "xs")), gap=16))
C["toast-card-progress"] = (420, stack(
    tcard("primary", "Emitindo NF-e do pedido #2491", "Assinando o XML…", icon="file", x=False, busy=True, fill='<span class="fill" style="transform:scaleX(.42)"></span>', pct='<span class="pct">42%</span>'),
    tcard("success", "NF-e 48.212 autorizada", "Protocolo 129 2611 0004 8221", icon="check", x=False, state="done", fill='<span class="fill" style="transform:none"></span>', pct='<span class="pct" style="color:var(--pos)">100%</span>'),
    tcard("error", "Envio da planilha falhou", "Linha 214: CNPJ inválido", icon="x-circle", x=False, state="fail", acts=b("Tentar de novo", "neutral", "outline", "sm")),
    tcard("primary", "Importando com valor zero", "0%", icon="file", x=False, busy=True, fill='<span class="fill" style="transform:scaleX(0)"></span>', pct='<span class="pct">0%</span>'), gap=12))

ST = '<span class="lu-st"{s}><i></i></span>'
C["toast-status"] = (420, stack(
    '<div class="lu-stoast">' + ST.format(s="") + '<span class="msg">Importando <b>stripe-oct.csv</b></span></div>',
    '<div class="lu-stoast">' + ST.format(s=' style="--stp:64%"') + '<span class="msg">Gerando board pack · <b>64%</b></span><button class="act ghost" type="button">Cancelar</button></div>',
    '<div class="lu-stoast"><span class="lu-st queue"><i></i></span><span class="msg">Backup <b>orbit-db</b> na fila</span></div>',
    '<div class="lu-stoast"><span class="dot ok"></span><span class="msg">Deploy de <b>nexus_pro</b> concluído</span><button class="act" type="button">Ver</button></div>',
    '<div class="lu-stoast"><span class="dot err"></span><span class="msg">Falha ao transmitir <b>NF-e 4312</b></span><button class="act" type="button">Tentar de novo</button></div>', align="flex-start"))

C["toaster-static"] = (520, '<div class="lu-toaster" data-pos="center-bottom"><div class="stack">'
                       + wrap(tcard("success", "Relatório exportado", "board-pack-oct-2026.pdf", x=False))
                       + wrap(tcard("info", "3 new AI insights", x=False))
                       + '<div class="lu-stoast">' + ST.format(s="") + '<span class="msg">Importando <b>stripe-oct.csv</b></span></div>'
                       + wrap(tcard("neutral", "Quarto toast, escondido", x=False)) + "</div></div>")
C["toaster-static-top"] = (520, '<div class="lu-toaster" data-pos="right-top"><div class="stack">'
                           + wrap(tcard("success", "Relatório exportado", "board-pack-oct-2026.pdf", x=False))
                           + wrap(tcard("warning", "Assentos em 80%", x=False)) + "</div></div>")
C["connection-banner-toast"] = (420, tcard("primary", "Connection lost", "Trying to reconnect...", icon="info", x=False, aura=("spin", "warn", "default"), busy=False).replace(
    f'<span class="tile">{ic("info", "md")}</span>', '<span class="tile"><span class="lu-sp v-border s-sm c-primary" role="status" aria-label="Loading"></span></span>'))
C["connection-banner"] = (200, '<span hidden></span><span class="lu-small">sem marcação visível</span>')
