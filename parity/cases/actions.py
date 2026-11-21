"""Ações: button, badge (lado original)."""
from _common import *
from base import btn, ibtn


def b(label, color="neutral", v="solid", s="md", shape="rounded", icon=None, after=None, extra="", dis=False):
    i = ic(icon) if icon else ""; a = ic(after) if after else ""
    return f'<button type="button" class="lu-b c-{color} v-{v} s-{s} sh-{shape}" {"disabled" if dis else ""} {extra}>{i}{label}{a}</button>'


def bd(t, c="neutral", v="soft", s="md", sh="rounded"): return f'<span class="lu-bd c-{c} v-{v} s-{s} sh-{sh}">{t}</span>'


C = {}
for v in VARIANTS:
    C[f"button-{v}"] = (900, row(*[b("Botão", c, v, "sm") for c in COLORS]))
C["button-sizes"] = (700, row(*[b(s.upper(), s=s) for s in SIZES]))
C["button-shapes"] = (600, row(b("Rounded"), b("Pill", shape="pill"), b("", shape="square", icon="plus", extra='aria-label="Adicionar"'), b("", "primary", "soft", shape="square", icon="sparkles", extra='aria-label="IA"')))
C["button-states"] = (700, row(b("Export report", icon="download"), b("Com ícone à direita", "neutral", "outline", after="arrow-right"), b("Disabled", dis=True)))
C["button-group"] = (700, row('<div class="lu-bgroup">' + b("Day", "neutral", "outline", "sm") + b("Week", "neutral", "outline", "sm") + b("Month", "neutral", "soft", "sm") + "</div>",
                              '<div class="lu-bgroup sh-pill">' + b("Anterior", "neutral", "outline", "sm", icon="chevron-left") + b("Próximo", "neutral", "outline", "sm", after="chevron-right") + "</div>"))

for v in ["solid", "glow", "soft", "outline", "flat", "bordered"]:
    C[f"badge-{v}"] = (800, row(*[bd(c.capitalize(), c, v) for c in COLORS[:7]]))
C["badge-sizes"] = (500, row(*[bd(s.upper(), "primary", "soft", s) for s in SIZES], bd("Pill", "success", "soft", "md", "pill")))

# --- matriz completa: cor x variante x tamanho x forma
for sz in ["xs", "md", "lg", "xl"]:
    C[f"button-matrix-{sz}"] = (1500, colm(*[row(*[b("Btn", c, v, sz) for c in COLORS]) for v in VARIANTS]))
C["button-pill"] = (900, colm(*[row(*[b("Pill", c, v, "sm", "pill") for c in COLORS]) for v in VARIANTS]))
C["button-square"] = (800, colm(*[row(*[b("", c, v, sz, "square", icon="plus", extra='aria-label="x"') for sz in SIZES]) for c, v in [("neutral", "solid"), ("primary", "soft"), ("error", "outline"), ("success", "ghost"), ("secondary", "glow"), ("mono", "flat")]]))
LOAD = 'style="color:transparent;position:relative"'
C["button-loading-pip"] = (800, row(
    b("Salvando", "neutral", "solid", extra=LOAD).replace("</button>", '<span class="lu-sp v-border s-sm" style="position:absolute;color:var(--on-inverse)"></span></button>'),
    b("Salvando", "primary", "soft", extra=LOAD).replace("</button>", '<span class="lu-sp v-border s-sm" style="position:absolute;color:var(--c-ink)"></span></button>'),
    b("Salvando", "error", "solid", extra=LOAD).replace("</button>", '<span class="lu-sp v-border s-sm" style="position:absolute;color:var(--c-on)"></span></button>'),
    b("", "neutral", "outline", shape="square", icon="bell", extra='aria-label="Notificações" style="position:relative"').replace("</button>", '<span style="position:absolute;top:6px;right:7px;width:7px;height:7px;border-radius:50%;background:var(--neg);box-shadow:0 0 0 2px var(--bg-panel)"></span></button>')))
C["button-current"] = (500, '<div style="color:#b45309">' + row(b("Current", "current", "solid"), b("Current", "current", "outline"), b("Current", "current", "ghost"), b("Current", "current", "soft")) + "</div>")

# --- canvas: lu-btn, icon_button, barra de topo
C["button-canvas"] = (600, row(btn("Default"), btn("Small", "sm"), btn("Large", "lg"), btn("Disabled", "", None, None, "disabled"), btn("Filter", "", "filter")))
C["icon-button"] = (700, colm(
    row(ibtn("plus", "Adicionar", "primary"), ibtn("filter", "Filtrar"), ibtn("more-h", "Mais", "soft"), ibtn("x", "Fechar", "ghost"), ibtn("trash", "Excluir", "danger-soft"), ibtn("sparkles", "IA", "accent")),
    row(ibtn("settings", "Config", "sm"), ibtn("settings", "Config"), ibtn("settings", "Config", "lg"))))
C["icon-button-topbar"] = (700, row(
    '<button class="lu-insight-btn" type="button"><span class="n">3</span>New AI insights</button>',
    '<button class="lu-tbtn dot" type="button" aria-label="Notificações">' + ic("bell") + "</button>",
    '<button class="lu-tbtn" type="button" aria-label="Tema escuro">' + ic("moon") + "</button>",
    '<button class="lu-round-go" type="button" aria-label="Abrir">' + ic("arrow-right", "md") + "</button>"))

# --- badge: forma x tamanho, ícone, pontos e a versão canvas
C["badge-shapes"] = (700, colm(*[row(*[bd(f"{sh} {s}", c, "soft", s, sh) for s in SIZES]) for sh in ["rounded", "pill", "square"] for c in ["info"]]))
C["badge-colors-all"] = (900, colm(*[row(*[bd(c.capitalize(), c, v, "lg") for c in COLORS]) for v in ["solid", "soft", "outline"]]))
# o `lu-bd` original não tem regra para ícone (só o `lu-badge` canvas, 13px): a regra extra é a intenção do design
C["badge-icon"] = (500, row(bd(ic("sparkles") + "3 novos", "primary", "outline"), bd(ic("check") + "Pago", "success", "soft", "lg", "pill")),
                   ".lu-bd .lu-i{width:13px;height:13px}")
C["badge-canvas"] = (800, row(
    '<span class="lu-badge acc caps"><span class="lu-dot live"></span>Live</span>',
    '<span class="lu-badge">Neutral</span>', '<span class="lu-badge acc">Primary</span>', '<span class="lu-badge pos">Success</span>', '<span class="lu-badge neg">Error</span>',
    '<span class="lu-badge warn">Warning</span>', '<span class="lu-badge info">Info</span>', '<span class="lu-badge lime">Lime</span>', '<span class="lu-badge solid">Solid</span>',
    '<span class="lu-badge outline">Outline</span>', '<span class="lu-badge outline pos">Pos</span>', '<span class="lu-badge outline warn">Warn</span>', '<span class="lu-badge outline acc">Acc</span>', '<span class="lu-badge outline neg">Neg</span>',
    '<span class="lu-badge acc sm">Beta</span>', '<span class="lu-badge lg">Grande</span>'))

# --- icon: tamanhos e caixa por estado
C["icon-sizes"] = (700, colm(
    row(*[ic("package", c) for c in ["sm", "md", "", "lg", "xl"]]),
    row(*[f'<span class="lu-ic {t}">{ic(n)}</span>' for t, n in [("acc", "sparkles"), ("pos", "check"), ("neg", "x-circle"), ("warn", "alert"), ("info", "info"), ("lime", "ai"), ("", "file")]]),
    row('<span class="lu-ic lg acc">' + ic("sparkles", "lg") + "</span>")))
