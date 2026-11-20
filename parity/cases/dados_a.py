"""Dados A (lado original): avatar, bulk_bar, card_table, carousel, cash_timer, cover, description_list,
mini_card, pixel_card, tag, timer, mask."""
import os, re
from _common import *
from base import av, badge, btn, ibtn, check  # noqa: E402,F401

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def lib_css(name):
    """Regras do CSS companheiro da lib (priv/static/ledger_ui.css) de uma seção `/* --- nome */`: o original
    não as tem no bundle da referência (anel, sobreposição, grupo spread, tag ativa…)."""
    out, on = [], False
    for ln in open(f"{ROOT}/priv/static/ledger_ui.css").read().splitlines():
        if ln.startswith("/* ---"):
            on = ln.rstrip(" */").endswith(name)
            continue
        if on: out.append(ln)
    return "\n".join(out)


def gr(cols, *items, gap="10px 14px", just="start"):
    unit = "minmax(0,1fr)" if just == "stretch" else "max-content"
    return f'<div style="display:grid;grid-template-columns:repeat({cols},{unit});gap:{gap};align-items:center;justify-items:{just}">' + "".join(items) + "</div>"


TONES = ["neutral", "primary", "secondary", "info", "success", "warning", "error"]

C = {}

# ------------------------------------------------------------------ Avatar
def A(init="AN", cls="", size=40, st="", style="", inner=None):
    s = f'<span class="st {st}"></span>' if st else ""
    return f'<span class="lu-av {cls}" style="--s:{size}px{";" + style if style else ""}">{init if inner is None else inner}{s}</span>'


AV_CSS = lib_css("avatar")
C["avatar-colors"] = (460, gr(4, *[A("BP", f"c-{c} v-{v}") for c in TONES for v in ["solid", "soft", "bordered", "skeleton"]], gap="12px 28px"), AV_CSS)
C["avatar-sizes"] = (620, row(*[A("AN", "c-primary v-soft", px) for px in [16, 20, 24, 26, 30, 32, 36, 44, 56, 72]]))
C["avatar-shapes"] = (620, row(*[A("AN", f"c-primary v-solid sh-{s}", 44) for s in ["circle", "square", "rounded", "squircle", "reuleaux-triangle", "diamond", "hexagon", "hexagon-2", "octagon", "star", "star-2", "heart"]]))
C["avatar-status"] = (560, colm(
    row(*[A("AN", "c-primary v-soft", 40, f"{t} {p}".strip()) for t in ["on", "away", "busy", "off"] for p in ["", "tl", "tr", "bl"]]),
    row(*[A("AN", "c-primary v-soft", 40, f"{t} m") for t in ["on", "away", "busy", "off"]],
        *[f'<span class="lu-av c-primary v-soft" style="--s:40px">AN<span class="st c-{c} tr" style="background:var(--c)"></span></span>' for c in ["primary", "secondary", "info"]]),
    row(*[A("AN", "c-primary v-soft", px, "on") for px in [16, 24, 32, 56, 72]])), AV_CSS)
INV = lambda x: f'<span style="background:var(--inverse);padding:6px;border-radius:12px;display:inline-flex">{x}</span>'
C["avatar-rings"] = (620, colm(
    row(*[A("AN", f"c-primary v-soft {r}", 40) for r in ["ring1", "ring1", "ring2", "ring4", "ringp"]], INV(A("AN", "c-primary v-soft ringw", 40))),
    row(*[A("AN", f"c-primary v-soft ring-{c}", 40) for c in ["primary", "secondary", "info", "success", "warning", "error", "neutral"]]),
    row(*[A("AN", f"grad g-{g}", 40) for g in ["sky-blue", "amber-orange", "pink-rose", "purple-orange", "green-fuchsia", "purple-indigo", "fuchsia-pink"]])), AV_CSS)
C["avatar-kinds"] = (460, row(*[A("", f"c-{c} v-soft", 40, inner=ic(i, "md")) for c, i in [("neutral", "building"), ("primary", "user"), ("warning", "truck"), ("secondary", "sparkles"), ("info", "plus")]],
                              A("", "c-primary v-soft", 40, inner=ic("user", "md")), A("", "", 40, inner=ic("user", "md"))))
C["avatar-custom"] = (460, row(A("AN", "", 40, style="background:#1a7f4b;color:#fff"), A("CA", "sh-rounded", 56, style="background:linear-gradient(135deg,#f97316,#ec4899);color:#fff"),
                               A("FP", "sh-hexagon", 56, style="background:#4f46e5;color:#fff"), A("", "mono", 32, inner="IS"), A("", "mono sq", 32, inner="SM"), A("OC", "sq", 40)))
_IMG = "data:image/svg+xml;utf8,%3Csvg xmlns='http://www.w3.org/2000/svg' width='40' height='40'%3E%3Crect width='40' height='40' fill='%23e8b04a'/%3E%3Ccircle cx='20' cy='16' r='7' fill='%23fff'/%3E%3Crect x='8' y='26' width='24' height='14' rx='7' fill='%23fff'/%3E%3C/svg%3E"
C["avatar-image"] = (460, row(*[f'<span class="lu-av {c}" style="--s:{p}px"><img src="{_IMG}" alt="Ana" style="width:100%;height:100%;object-fit:cover;border-radius:inherit">{"<span class=" + chr(34) + "st on" + chr(34) + "></span>" if p == 56 else ""}</span>'
                                for c, p in [("c-neutral v-solid", 32), ("c-neutral v-solid sh-squircle", 44), ("c-neutral v-solid sh-hexagon", 56), ("c-neutral v-solid sh-heart", 56)]]), AV_CSS)
LEG_CSS = AV_CSS
C["avatar-legacy"] = (460, row(*[A("IS", t, 36) for t in ["t2", "t3", "t4", "t5", ""]], A("IS", "t3 sq", 36), A("PB", "mono", 32), A("SM", "mono", 32, "on")), LEG_CSS)
# t1 segue o accent (a referência fixa o teal #d6f1ea / #0c4b44): igual no tema claro e no escuro, diverge só na paleta crepúsculo
C["avatar-legacy-t1"] = (260, row(*[A("IS", "t1", px) for px in [24, 36, 48]]), LEG_CSS)
C["avatar-group"] = (620, colm(
    *[f'<span class="lu-av-grp {o}">' + "".join(A(i, t, 32) for i, t in [("IS", "t2"), ("FP", "t3"), ("CA", "t4"), ("AN", "t5")]) + A("+8", "", 32, style="background:var(--bg-selected);color:var(--ink-2)") + "</span>" for o in ["", "ov3", "ov7", "ova"]],
    '<span class="lu-av-grp">' + "".join(A(i, f"c-{c} v-soft", 24) for i, c in [("IS", "info"), ("FP", "success"), ("CA", "warning")]) + A("+2", "ringp", 24, style="background:var(--bg-selected);color:var(--ink-2)") + "</span>",
    '<span class="lu-av-grp">' + A("A", "c-primary v-soft ring2", 36) + A("B", "c-primary v-bordered", 36) + A("C", "c-primary v-solid", 36) + "</span>",
    '<span class="lu-av-grp spread" tabindex="0">' + "".join(A(i, f"c-{c} v-soft", 36) for i, c in [("AN", "primary"), ("CA", "info"), ("FP", "warning")]) + "</span>"), AV_CSS)
C["avatar-group-more"] = (360, '<span class="lu-av-grp">' + "".join(A(i, f"c-{c} v-soft", 30) for i, c in [("AN", "primary"), ("CA", "info")]) +
                          '<span style="position:relative;display:inline-flex"><button type="button" class="lu-av" style="--s:30px;background:var(--bg-selected);color:var(--ink-2);border:0;padding:0" aria-haspopup="true" aria-expanded="false">+3</button></span></span>', AV_CSS)

# ------------------------------------------------------------------ Tag
TAG_CSS = lib_css("tag")
TCOLORS = ["neutral", "primary", "secondary", "info", "success", "warning", "error", "light"]
X = ic("x", "sm")
C["tag-matrix"] = (700, gr(5, *[f'<span class="lu-tg c-{c} v-{v}">{c.capitalize()}</span>' for c in TCOLORS for v in ["solid", "soft", "bordered", "outline", "flat"]], gap="10px 12px"))
C["tag-shapes"] = (620, colm(
    row('<span class="lu-tg c-primary v-soft">rounded</span>', '<span class="lu-tg c-primary v-soft sh-pill">pill</span>', '<span class="lu-tg c-primary v-soft sh-square">square</span>',
        f'<span class="lu-tg c-neutral v-solid">Removível<span class="x">{X}</span></span>', '<span class="lu-tg c-info v-bordered sh-pill">Com contagem<span class="lu-count">3</span></span>'),
    row('<span class="lu-tg v-solid" style="color:#0d8f91;background:color-mix(in oklab, #0d8f91 14%, transparent)">VIP</span>',
        f'<span class="lu-tg c-error v-soft sh-pill">Inadimplente<span class="x">{X}</span></span>', f'<span class="lu-tg c-primary v-outline sh-square">Contorno<span class="x">{X}</span></span>'),
    '<span class="lu-tg-grp"><span class="lu-tg c-neutral v-solid">Primary</span><span class="lu-tg c-primary v-solid">55</span><span class="lu-tg c-success v-soft sh-pill">Ok</span></span>'), TAG_CSS)
C["tag-pressable"] = (520, row('<button type="button" class="lu-tg c-primary v-soft">Botão</button>', '<a href="#" class="lu-tg c-info v-bordered sh-pill" style="text-decoration:none">Link</a>',
                               '<button type="button" class="lu-tg c-primary v-soft active" aria-pressed="true">Ativa</button>',
                               f'<button type="button" class="lu-tg c-neutral v-flat">Filtro<span class="lu-count">2</span><span class="x">{X}</span></button>'), TAG_CSS)
C["tag-canvas"] = (620, row(*[f'<span class="lu-tag"><span class="sw" style="background:var(--{c})"></span>{t}<button type="button" data-lu-remove aria-label="Remover">{X}</button></span>'
                              for t, c in [("Pro", "chart-1"), ("Scale", "chart-2"), ("Contract", "chart-3"), ("Churn", "chart-4"), ("Starter", "chart-5")]],
                            '<span class="lu-tag">Sem amostra</span>', '<span class="lu-tag" aria-pressed="true">Pressionada</span>', '<span class="lu-tag active">Ativa</span>'), TAG_CSS)

# ------------------------------------------------------------------ DescriptionList
DL = [("Razão social", "Mercadinho Bom Preço Ltda"), ("CNPJ", "12.345.678/0001-90"), ("Regime", "Simples Nacional"), ("Cidade", "Feira de Santana · BA"), ("Desde", "jan 2024"), ("Limite", "R$ 15.000,00")]
def dl(cols, layout="", mono=(), empty=False):
    items = "".join(f'<div><dt>{k}</dt><dd{" class=" + chr(34) + "mono" + chr(34) if k in mono else ""}>{v}</dd></div>' for k, v in DL)
    if empty: items += "<div><dt>Observação</dt><dd>—</dd></div>"
    return f'<dl class="lu-dl2{" " + layout if layout else ""}" style="--cols:{cols};margin:0">{items}</dl>'
C["description-list-cols"] = (700, colm(*[dl(c) for c in [1, 2, 3, 4]], dl(3, mono=("CNPJ",), empty=True)))
C["description-list-inline"] = (560, colm(dl(2, "inline"), dl(1, "inline", mono=("CNPJ",))))

# ------------------------------------------------------------------ MiniCard
def mini(icon, tone, name, meta, link=True):
    arr = ic("arrow-up-right", "md lu-muted") if link else ""
    tag, attrs = ("a", ' href="#"') if link else ("div", "")
    return (f'<{tag}{attrs} class="lu-panel" style="display:flex;gap:12px;align-items:center;padding:12px;color:inherit;text-decoration:none"><span class="lu-ic {tone}">{ic(icon)}</span>'
            f'<span class="lu-col lu-grow" style="gap:0"><b style="font-weight:600">{name}</b><span class="lu-xs lu-muted">{meta}</span></span>{arr}</{tag}>')
def mini_val(label, value):
    return (f'<div class="lu-panel" style="display:flex;gap:12px;align-items:center;padding:12px;color:inherit;text-decoration:none"><span class="lu-col lu-grow" style="gap:0">'
            f'<span class="lu-xs lu-muted">{label}</span><b style="font-weight:600" class="mono">{value}</b></span></div>')
def mini_card(icon, color, label, extra=""):
    return (f'<div class="lu-cv default" style="flex-direction:row;align-items:center;gap:10px;min-height:0"><span class="lu-av c-{color} v-soft sh-rounded" style="--s:34px">{ic(icon, "md")}</span>'
            f'<span class="lu-col" style="gap:0"><b>{label}</b>{extra}</span></div>')
C["mini-card-panel"] = (640, gr(3, *[mini(i, t, n, m) for i, t, n, m in [("invoice", "acc", "Board packs", "4 relatórios"), ("user-minus", "neg", "Pro churn watch", "23 contas"), ("globe", "info", "EMEA expansion", "12 contas"),
                                                                    ("wallet", "pos", "Receber", "Pix e boleto"), ("zap", "warn", "Atenção", "3 pendências")]], mini("file", "", "Sem tom", "Neutro", link=False), gap="12px", just="stretch"))
C["mini-card-value"] = (460, gr(2, mini_val("A receber", "R$ 41,2 mil"), mini_val("Vencidas", "R$ 3,4 mil"), gap="12px", just="stretch"))
C["mini-card-surface"] = (640, gr(3, *[mini_card("file", c, n, "<span>Atalho</span>") for c, n in [("primary", "accent"), ("success", "success"), ("warning", "warning"), ("error", "error"), ("info", "info"), ("neutral", "neutral")]], gap="10px", just="stretch"))

# ------------------------------------------------------------------ PixelCard
def px(color, icon, title, desc, arrow=True, cls=""):
    c = f" px-{color}" if color else ""
    return (f'<a href="#" class="lu-px{c}{cls}"><span class="ico">{ic(icon, "md")}</span><b>{title}</b><span class="d">{desc}</span>' + (f'<span class="arr">{ic("arrow-right", "md")}</span>' if arrow else "") + "</a>")
PXS = [("red", "cart", "Loja", "PDV, estoque, NFC-e"), ("rose", "smile", "Clínica", "Agenda e prontuário"), ("green", "wallet", "Financeiro", "Contas e conciliação"), ("teal", "trend-up", "Receita", "MRR e coortes"),
       ("blue", "users", "CRM", "Contas e pipeline"), ("violet", "sparkles", "Assistente", "IA nos seus dados"), ("amber", "calendar", "Agenda", "Horários e lembretes"), ("ink", "code", "API", "Chaves e webhooks")]
C["pixel-card-colors"] = (860, gr(4, *[px(*p) for p in PXS], gap="10px", just="stretch"))
C["pixel-card-states"] = (620, gr(3, px(None, "trend-up", "Padrão", "Sem cor, usa o accent"), px("ink", "code", "Sem seta", "Sem seta", arrow=False),
                                  '<button type="button" class="lu-px px-violet"><span class="ico">' + ic("sparkles", "md") + '</span><b>Botão</b><span class="d">Sem link</span><span class="arr">' + ic("arrow-right", "md") + "</span></button>", gap="10px", just="stretch"))

# ------------------------------------------------------------------ Cover
CV_ACC = "linear-gradient(135deg,var(--teal-300),var(--teal-700))"
CV_NEU = "linear-gradient(135deg,var(--bg-selected),var(--line-strong))"
def cov(tone="accent", h=140, title=None, inner=""):
    bg = CV_ACC if tone == "accent" else CV_NEU
    pos = ";position:relative;overflow:hidden" if title else ""
    t = f'<b style="position:absolute;left:16px;bottom:12px;font-size:18px;color:{"#fff" if tone == "accent" else "var(--ink)"}">{title}</b>' if title else ""
    return f'<div style="height:{h}px;background:{bg}{pos}">{inner}{t}</div>'
def cov_av(tone, h, title, sub, avatar):
    return (f'<div><div style="height:{h}px;background:{CV_ACC if tone == "accent" else CV_NEU};position:relative;overflow:hidden"></div>'
            f'<div style="display:flex;align-items:flex-end;gap:14px;padding:0 16px"><span style="margin-top:-32px;display:inline-flex;border-radius:30%;box-shadow:0 0 0 4px var(--bg-panel)">{avatar}</span>'
            f'<span class="lu-col" style="gap:0;padding:10px 0"><b>{title}</b>' + (f'<span class="lu-small lu-muted">{sub}</span>' if sub else "") + "</span></div></div>")
C["cover-bands"] = (560, colm(cov(), cov("neutral", 100), cov("accent", 120, "Distribuidora Sertão"), cov("neutral", 90, "Título no neutro")))
C["cover-avatar"] = (560, colm(
    cov_av("accent", 110, "Distribuidora Sertão", "Cliente desde 2021", A("DS", "sh-rounded", 64, style="background:#1a7f4b;color:#fff")),
    cov_av("neutral", 90, "Sem subtítulo", None, A("SS", "c-primary v-solid sh-rounded", 64))))
_IMG2 = "data:image/svg+xml;utf8,%3Csvg xmlns='http://www.w3.org/2000/svg' width='200' height='80'%3E%3Crect width='200' height='80' fill='%23c4a000'/%3E%3Ccircle cx='60' cy='40' r='30' fill='%23fff' opacity='.4'/%3E%3C/svg%3E"
C["cover-image"] = (460, f'<div style="height:110px;background:{CV_ACC};position:relative;overflow:hidden"><img src="{_IMG2}" alt="" style="position:absolute;inset:0;width:100%;height:100%;object-fit:cover"></div>')

# ------------------------------------------------------------------ Mask
MASKS = ["squircle", "reuleaux-triangle", "diamond", "hexagon", "hexagon-2", "octagon", "star", "star-2", "heart"]
GRAD = "linear-gradient(135deg,var(--teal-300),var(--teal-700))"
C["mask-shapes"] = (700, row(*[f'<span class="lu-av c-primary v-solid sh-{s}" style="--s:64px;background:{GRAD}">BP</span>' for s in MASKS]))
C["mask-sizes"] = (560, row(*[f'<span class="lu-av c-primary v-solid sh-hexagon" style="--s:{px_}px">BP</span>' for px_ in [24, 32, 44, 56, 72]],
                          f'<span class="lu-av c-primary v-solid sh-star" style="--s:56px">MK</span>'))
C["mask-image"] = (460, row(*[f'<span class="lu-av c-primary v-solid sh-{s}" style="--s:64px"><img src="{_IMG}" alt="Ana" style="width:100%;height:100%;object-fit:cover;border-radius:inherit"></span>' for s in ["heart", "hexagon", "squircle"]]), AV_CSS)

# ------------------------------------------------------------------ Timer
def ring(pct, size="md", color="", t="04:20", state=""):
    return f'<div class="lu-timer s-{size} {("c-" + color) if color else ""}" style="--sp:{pct}%"><b>{t}</b></div>'.replace("s-md ", "")
C["timer-ring"] = (620, colm(
    row(*[ring(65, s) for s in ["sm", "md", "lg"]]),
    row(*[ring(40 + k * 8, "sm", c, "%02d:%02d" % divmod(300 * (40 + k * 8) // 60, 60)) for k, c in enumerate(TONES)]),
    row(ring(0, "sm", "", "00:00"), ring(100, "sm", "success", "08:00"), ring(33.3, "sm", "warning", "02:40"))))
KICK = ('<div class="lu-col" style="align-items:center;gap:10px"><span class="lu-xs" style="text-transform:uppercase;letter-spacing:.08em;color:var(--{tone})">{kick}</span>'
        '<div class="lu-timer s-{size} {col}" style="--sp:{pct}%"><b>{t}</b></div><span class="lu-small lu-muted">{label}</span>{acts}</div>')
def kick_t(tone, kick, size, col, pct, t, label, acts=""):
    return KICK.format(tone=tone, kick=kick, size=size, col=col, pct=pct, t=t, label=label, acts=acts)
C["timer-extras"] = (620, row(
    kick_t("pos", "Register open", "md", "", 65, "04:20:00", "Register 01", '<div class="lu-row" style="gap:8px">' + btn("Pause", "sm") + btn("+15 min", "sm") + "</div>"),
    kick_t("warn", "Paused", "md", "c-warning", 30, "02:00:00", "Register 02"),
    kick_t("pos", "Break", "sm", "c-primary", 75, "00:45:00", "Countdown")))
C["timer-mini"] = (460, row('<span class="lu-tmini"><span class="lu-dot live" style="background:var(--neg)"></span>1h24</span>', '<span class="lu-tmini">01:24:36</span>', '<span class="lu-tmini"><span class="lu-dot live" style="background:var(--neg)"></span>0h24</span>'))

# ------------------------------------------------------------------ CashTimer
def cash(state, title, clock=None, amount=None, diff=None, stats=None, action=""):
    st = f" {state}" if state != "open" else ""
    wrap = "flex-wrap:wrap;" if stats else ""
    amt = ""
    if amount or diff:
        amt = '<div class="lu-col" style="gap:2px;text-align:right">' + (f'<span class="lu-xs lu-muted">Em caixa</span><b class="num">{amount}</b>' if amount else "") + (f'<b class="num" style="color:var(--warn)">{diff}</b>' if diff else "") + "</div>"
    clk = f'<b class="mono" style="font-size:28px;letter-spacing:-.02em">{clock}</b>' if clock else ""
    st_h = ""
    if stats:
        st_h = '<div style="flex-basis:100%;display:flex;gap:24px;padding-top:10px;border-top:1px solid var(--line)">' + "".join(f'<div class="lu-col" style="gap:2px"><span class="lu-xs lu-muted">{k}</span><b class="num">{v}</b></div>' for k, v in stats) + "</div>"
    return (f'<div class="lu-panel lu-cash{st}" style="padding:14px 16px;display:flex;{wrap}align-items:center;gap:16px;max-width:520px"><span class="lu-ic acc lg">{ic("timer", "lg")}</span>'
            f'<div class="lu-col lu-grow" style="gap:2px"><span class="lu-xs lu-muted">{title}</span>{clk}</div>{amt}{action}{st_h}</div>')
C["cash-timer-states"] = (560, colm(
    cash("open", "Caixa 1 · aberto às 08:00", "02:14:08", "R$ 3.412,90"),
    cash("closed", "Caixa 2 fechado · ontem às 18:04", "08:00:00", "R$ 6.412,30", action=btn("Abrir caixa", "sm")),
    cash("alert", "Conferência do caixa 2", None, None, "− R$ 12,50", stats=[("Esperado", "R$ 6.412,30"), ("Contado", "R$ 6.399,80")]),
    cash("open", "Revisão do board pack · Orbit Cloud", "01:24:36", "$169.20")), '.lu-cash.closed { opacity: .7; } .lu-cash.alert { box-shadow: 0 0 0 1px var(--warn), 0 0 0 4px var(--warn-soft); }')

# ------------------------------------------------------------------ BulkBar / SelectionBar
def ghost(label, icon=None, v=""):
    return btn(label, f"ghost sm {v}".strip(), icon)
def sel(look, text, danger=True, close=True, esc=False, link=None, fields=""):
    cls = f"lu-selbar {look}".strip()
    k = '<kbd class="lu-kbd">Esc</kbd>' if esc else ""
    lk = f'<a class="lu-btn link sm" href="#">{link}</a>' if link else ""
    return (f'<div class="{cls}"><b class="num">{text}</b>{lk}<span class="sep"></span>{fields}' + ghost("Emitir NF-e", "file") + ghost("Exportar", "download")
            + ('<span class="sep"></span>' + ghost("Excluir", "trash") if danger else "")
            + (f'<button aria-label="Limpar" class="lu-btn icon sm ghost" type="button">{ic("x", "md")}{k}</button>' if close else "") + "</div>")
C["bulk-bar-pill"] = (620, colm(sel("", "3 selecionados"), sel("soft", "3 selecionados"), sel("solid", "3 selecionados"), sel("", "1 selecionado", danger=False, close=False),
                                sel("", "2 selecionados", esc=True, link="Selecionar todos 50")))
C["bulk-bar-progress"] = (560, '<div class="lu-selbar"><b>selecionados</b><div class="lu-progress sm" style="flex:1;min-width:120px" role="progressbar" aria-valuemin="0" aria-valuemax="10" aria-valuenow="4"><i style="width:40%"></i></div><span class="num">4/10</span></div>')
def inl(text, ind=True, checked=False, link=None, acts=True):
    chk = f'<label class="lu-check c-primary"><input type="checkbox" aria-label="Seleção" {"checked" if checked else ""} {"data-ind=1" if ind else ""}></label>'
    lk = f'<a class="lu-btn link sm" href="#">{link}</a>' if link else ""
    a = (btn("Mover", "sm", "folder") + btn("Exportar", "sm primary", "download") + btn("Excluir", "sm danger-soft", "trash")) if acts else ""
    return (f'<div class="lu-panel" style="display:flex;align-items:center;gap:10px;padding:8px 10px;background:var(--accent-soft);border-color:color-mix(in oklab,var(--accent) 30%,transparent)">{chk}<b class="num">{text}</b>{lk}<span class="lu-grow"></span>{a}</div>')
C["bulk-bar-inline"] = (700, colm(inl("25 selecionadas", link="Selecionar todas as 1096"), inl("1096 selecionadas", ind=False, checked=True), inl("3 selecionados", ind=False, acts=False)))
FLOAT = ('<div style="position:relative;height:130px;background:var(--bg-tray);border-radius:14px"><div class="lu-bulkfloat"><b>3 selecionados</b>{b}</div></div>')
C["bulk-bar-float"] = (620, FLOAT.format(b='<button type="button"><i data-i="file"></i>Emitir NF-e</button><button type="button"><i data-i="download"></i>Exportar</button><span class="sep"></span><button type="button" class="danger"><i data-i="trash"></i>Excluir</button><button type="button" aria-label="Limpar"><i data-i="x"></i></button>'))

# ------------------------------------------------------------------ Carousel
SLIDES = [("linear-gradient(135deg,#1f9282,#0c4b44)", "Promoção de novembro"), ("linear-gradient(135deg,#6a4fd8,#2b3577)", "Novo: NFC-e"), ("linear-gradient(135deg,#e8b04a,#b07a2c)", "Black Friday")]
def car(cid, n=3, nav=False, dots=False, fraction=False, bar=False, thumbs=False, mw=560):
    sl = "".join(f'<div style="background:{bg}">{t}</div>' for bg, t in SLIDES[:n])
    prev = ('<button type="button" class="lu-btn icon sm" aria-label="Previous slide" aria-controls="{i}" data-carousel-prev style="position:absolute;top:50%;left:8px;transform:translateY(-50%);z-index:2">' + ic("chevron-left") + "</button>"
            '<button type="button" class="lu-btn icon sm" aria-label="Next slide" aria-controls="{i}" data-carousel-next style="position:absolute;top:50%;right:8px;transform:translateY(-50%);z-index:2">' + ic("chevron-right") + "</button>").format(i=cid) if nav else ""
    fr = f'<span class="mono lu-xs" data-carousel-fraction style="position:absolute;top:8px;right:10px;z-index:2;color:#fff">1/{n}</span>' if fraction else ""
    br = '<i data-carousel-bar style="position:absolute;left:0;top:0;height:3px;width:0;background:var(--ink);z-index:2"></i>' if bar else ""
    h = f'<div id="{cid}" class="lu-carousel2" style="max-width:{mw}px" role="region" aria-roledescription="carousel" tabindex="0"><div class="tr" style="animation:none">{sl}</div>{prev}{fr}{br}</div>'
    if dots:
        h += f'<div id="{cid}-dots" class="lu-cdots">' + "".join(f'<i role="button" tabindex="0" aria-label="Go to slide {k + 1}" aria-current="{"true" if k == 0 else "false"}" style="animation:none;{"background:var(--ink);width:18px" if k == 0 else ""}"></i>' for k in range(n)) + "</div>"
    if thumbs:
        h += f'<div id="{cid}-thumbs" class="lu-row" style="margin-top:10px;gap:8px">' + "".join(
            f'<button type="button" aria-label="Show slide {k + 1}" style="width:64px;height:64px;border:0;padding:0;border-radius:10px;overflow:hidden;cursor:pointer{";box-shadow:0 0 0 2px var(--bg-page), 0 0 0 4px var(--teal-500)" if k == 0 else ""}"><span style="display:block;width:100%;height:100%;background:{bg}"></span></button>'
            for k, (bg, _) in enumerate(SLIDES[:n])) + "</div>"
    return h
C["carousel-slide"] = (620, colm(car("c1", nav=True, dots=True), car("c2", fraction=True, mw=300), car("c3", bar=True, mw=300), car("c4", thumbs=True, mw=360)))

# ------------------------------------------------------------------ CardTable
# O miolo é o `Table.table` (lote Dados B, agora migrado): o original recebe o markup legado do miolo (`lu-table` do bundle).
def ct_body(cid):
    return (f'<div class="lu-tablewrap"><table id="{cid}" class="lu-table"><thead><tr><th class="">Pedido</th><th class="">Cliente</th></tr></thead>'
            f'<tbody id="{cid}-body" class=""><tr class=""><td class="">PED-2491</td><td class="">Mercadinho Bom Preço</td></tr></tbody></table></div>')
def ct(cid, title=None, meta=None, actions="", desc=None, foot=None, bare=False, flat=False):
    cls = "lu-card" + (" lu-ct-bare" if bare else "")
    head = ""
    if title or actions or meta:
        head = '<div class="lu-card-h">' + (f'<span class="lu-card-t">{title}</span>' if title else "") + (f'<span class="lu-xs lu-muted">{meta}</span>' if meta else "") + (f'<div class="act">{actions}</div>' if actions else "") + "</div>"
    d = f'<p class="lu-xs lu-muted lu-ct-desc">{desc}</p>' if desc else ""
    body = ct_body(cid) if flat else f'<div class="lu-card-b" style="padding:0">{ct_body(cid)}</div>'
    f = f'<div class="lu-card-f lu-ct-foot">{foot}</div>' if foot else ""
    return f'<section id="{cid}-card" class="{cls}">{head}{d}{body}{f}</section>'
CT_CSS = lib_css("tree / card / heading") + ".lu-card.lu-ct-bare { border: 0; box-shadow: none; background: none; }.lu-card .lu-ct-desc { margin: 0; padding: 0 14px 10px; }.lu-card-f.lu-ct-foot { flex-wrap: wrap; justify-content: space-between; border-top: 1px solid var(--line); }"
C["card-table-tray"] = (560, colm(
    ct("t1", "Pedidos", "128", desc="Os últimos pedidos do mês", foot="<span>Mostrando 1 de 128</span><span>Atualizado agora</span>", actions=btn("Exportar", "sm", "download")),
    ct("t2"), ct("t3", "Sem borda", bare=True), ct("t4", "Plano", "3", flat=True, foot="<span>Rodapé</span>")), CT_CSS)
