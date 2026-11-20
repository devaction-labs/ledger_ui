"""Ações: palette, clipboard, divider, fab, fab-dial, illustration, kbd, typography (lado original)."""
from _common import *
from base import grid, demo, btn

C = {}

# ---------------------------------------------------------------- palette
STEPS = ["50", "100", "200", "300", "400", "500", "600", "700", "800", "900"]
RAMP = "".join(f'<div style="background:var(--teal-{k});color:{"var(--teal-900)" if int(k) < 400 else "#fff"}">{k}</div>' for k in STEPS)
C["palette-ramp"] = (980, f'<div class="lu-ramp">{RAMP}</div>')
C["palette-chips"] = (700, '<div class="lu-row lu-palrow" style="gap:6px">' + "".join(
    f'<i style="display:block;width:44px;height:44px;border-radius:10px;background:var(--teal-{k});--dl:{i * 0.12:.2f}s"></i>' for i, k in enumerate(STEPS)) + "</div>")


def sw(n, label, light, dark):
    return f'<div class="lu-swc"><div class="c" style="background:var(--{n})"></div><div class="m"><b>{label}</b><span>--{n}</span><span>{light} · {dark}</span></div></div>'


C["palette-swatches"] = (980, colm(
    grid(sw("bg-page", "Página", "#ffffff", "#0e100f"), sw("bg-shell", "Shell / sidebar", "#f6f6f4", "#121413"), sw("bg-tray", "Bandeja do card", "#f4f4f2", "#161918"),
         sw("bg-panel", "Painel", "#ffffff", "#1b1e1d"), sw("bg-sunken", "Afundado", "#f1f1ef", "#202422"), sw("bg-selected", "Selecionado", "#e9e9e6", "#2a2e2c"), cols=6, gap=10),
    grid(sw("ink", "Ink", "#141514", "#f2f3f2"), sw("ink-2", "Ink 2", "#3b3d3b", "#c9cdcb"), sw("muted", "Muted", "#6b6d69", "#9ba19e"),
         sw("subtle", "Subtle (ícone)", "#8f918c", "#6f7572"), sw("line", "Linha", "#e8e8e5", "#2a2e2c"), sw("line-strong", "Linha forte", "#d7d7d3", "#3a3f3c"), cols=6, gap=10),
    grid(sw("inverse", "Inverso (botão)", "#141514", "#f2f3f2"), sw("accent", "Accent", "#1f9282", "#2fa792"), sw("pos", "Positivo", "#11773e", "#4cc985"),
         sw("neg", "Negativo", "#b72f48", "#f0788b"), sw("warn", "Aviso", "#8f5606", "#f0b453"), sw("info", "Info", "#2e64c9", "#7aa7f2"),
         sw("lime", "Oportunidade", "#3f6b0e", "#b9e27a"), sw("lime-soft", "Oportunidade suave", "#e2f6c6", "#1f2c10"), cols=8, gap=10)))

# `--chart-2` is a fixed token (#0c4b44 = teal-800 do Ledger), não deriva de `--color-accent`: fica isolado para
# o `--theme` apontar só ele (mudança pedida no token compartilhado, ver relatório)
C["palette-swatches-chart"] = (980, grid(sw("chart-1", "Série 1 · Pro", "#1f9282", "#2fa792"), sw("chart-3", "Série 3 · Contract", "#e8b04a", "#e8b04a"),
         sw("chart-4", "Série 4 · Churn", "#e57487", "#e57487"), sw("chart-5", "Série 5 · Starter", "#9fdacc", "#2e5f56"), sw("chart-ghost", "Comparação", "#b9bbb6", "#565c59"), cols=5, gap=10))
C["palette-chart-2"] = (320, sw("chart-2", "Série 2 · Scale", "#0c4b44", "#a5e3d6"))

# ---------------------------------------------------------------- divider
CENTER = '<div class="lu-row" style="gap:12px"><hr class="lu-sep lu-grow"><span class="lu-xs lu-muted" style="letter-spacing:.06em;text-transform:uppercase">ou continue com</span><hr class="lu-sep lu-grow"></div>'
LEFT = '<div class="lu-row" style="gap:12px"><span class="lu-xs lu-muted" style="letter-spacing:.06em;text-transform:uppercase">Entrega</span><hr class="lu-sep lu-grow"></div>'
VLINE = '<span style="width:1px;height:18px;background:var(--line)"></span>'
C["divider-horizontal"] = (420, colm('<hr class="lu-sep">', CENTER, LEFT, '<hr class="lu-sep">'))
C["divider-vertical"] = (420, colm(
    row("<span>Day</span>", VLINE, "<span>Month</span>", VLINE, "<span>Year</span>"),
    row("<span>Esquerda</span>", '<span style="width:1px;height:40px;background:var(--line)"></span>', "<span>Direita</span>")))

# ---------------------------------------------------------------- kbd
def kbd(*keys): return "".join(f'<kbd class="lu-kbd">{k}</kbd>' for k in keys)


FLAT = "box-shadow:none;background:var(--bg-sunken);border-color:transparent"
DARK_BOX = "display:inline-block;padding:6px 10px;border-radius:8px;background:var(--inverse);color:var(--on-inverse)"
C["kbd-variants"] = (560, colm(
    row(kbd("⌘", "K"), kbd("Ctrl", "Shift", "P"), kbd("Esc"), kbd("↑", "↓"), kbd("Enter"), kbd("/")),
    row(*[f'<kbd class="lu-kbd" style="{FLAT}">{k}</kbd>' for k in ["⌘", "K", "Esc", "/"]]),
    row(f'<span style="{DARK_BOX}">Buscar <kbd class="lu-kbd dark">⌘K</kbd></span>')))

# ---------------------------------------------------------------- typography
def span(style, t="Signetum"): return f'<span style="{style}">{t}</span>'


SIZES_PX = [("xs", 12), ("xs-plus", 13), ("sm", 14), ("base", 16), ("lead", 18), ("lg", 18), ("xl", 20), ("meta", 12.5)]
C["typography-sizes"] = (700, colm(
    row(*[span(f"font-size:{px}px") for _, px in SIZES_PX]),
    row(*[span(f"color:var(--{v})", "Texto") for v in ["ink", "ink-2", "muted", "subtle", "accent-ink", "violet", "pos", "warn", "neg", "info"]]),
    row(span("font-weight:300", "light"), span("font-weight:400", "normal"), span("font-weight:500", "medium"), span("font-weight:600", "semibold"), span("font-weight:700", "bold")),
    row('<span class="mono">mono 14</span>', span("font-size:18px;font-weight:600;color:var(--ink)", "lg semibold ink"))))
GR = [("sky-blue", "#0ea5e9", "#2563eb"), ("green-fuchsia", "#22c55e", "#d946ef"), ("fuchsia-pink", "#d946ef", "#ec4899"), ("amber-orange", "#f59e0b", "#f97316"), ("purple-indigo", "#8b5cf6", "#4f46e5")]
C["typography-gradients"] = (700, colm(
    row(*[f'<span class="lu-ty-grad g-{g}" style="font-size:22px">Signetum</span>' for g, _, _ in GR]),
    row(f'<span class="lu-ty-grad g-sky-blue" style="font-size:18px;font-weight:500">weight medium</span>')))
C["typography-decoration"] = (700, row(
    span("text-decoration:underline", "underline"), span("text-decoration:line-through", "line-through"), span("text-decoration:overline", "overline")))
LINK = "color:inherit;text-decoration:underline {s};text-decoration-color:{c};text-decoration-thickness:1px;text-underline-offset:3px"
C["typography-links"] = (700, row(*[f'<a href="#" style="{LINK.format(s=s, c=c)}">{t}</a>' for t, s, c in [
    ("current", "solid", "currentColor"), ("info wavy", "wavy", "var(--info)"), ("primary dotted", "dotted", "var(--accent-ink)"), ("error dashed", "dashed", "var(--neg)"),
    ("secondary double", "double", "var(--violet)"), ("success", "solid", "var(--pos)"), ("warning", "solid", "var(--warn)")]]))
C["typography-inline-code"] = (500, row(
    '<span>Rode <code class="mono" style="font-size:12.5px;background:var(--bg-sunken);color:var(--ink);padding:1px 5px;border-radius:5px">mix test</code> e depois</span>',
    '<code class="mono" style="font-size:12.5px;background:var(--bg-sunken);color:var(--ink);padding:1px 5px;border-radius:5px">mix format</code>'))
HST = "margin:0;font-size:{px}px;font-weight:{w};letter-spacing:{ls};color:{c}"
H = lambda tag, px, w=600, ls="-.02em", c="inherit", lh="": f'<{tag} style="margin:0;font-size:{px}px;{lh}font-weight:{w};letter-spacing:{ls};color:{c}">Título {tag}</{tag}>'
C["typography-headings"] = (560, colm(
    H("h1", 40), H("h2", 32), H("h3", 26), H("h4", 20), H("h5", 17), H("h6", 15),
    H("h2", 34, ls="-.03em", c="var(--ink)", lh="line-height:40px;"), H("h1", 56, ls="-.03em"), H("h1", 28, ls="-.03em"),
    H("h3", 18, c="var(--info)"), H("h3", 24, w=300, c="var(--muted)"), H("h3", 14, w=700)))

# ---------------------------------------------------------------- illustration
ILL = lambda icn, c: f'<div class="lu-ill c-{c}"><span class="a"></span><span class="b"></span><span class="c"></span><span class="d">{ic(icn, "md")}</span></div>'
C["illustration-states"] = (700, row(*[ILL(i, c) for _, i, c in [("empty", "inbox", "neutral"), ("success", "check-circle", "success"), ("error", "x-circle", "error"), ("search", "search", "info"), ("offline", "wifi", "warning")]]))
C["illustration-tones"] = (700, row(ILL("inbox", "primary"), ILL("star", "primary"), ILL("bell", "warning"), ILL("lock", "error"), ILL("sparkles", "info")))

# ---------------------------------------------------------------- clipboard
def clip(c="neutral", v="soft", s="sm", label="Copiar", only=False):
    return f'<button type="button" class="lu-b c-{c} v-{v} s-{s}" data-lu-copy="LDG-2026-1043" {"aria-label=Copiar" if only else ""}>{ic("copy", "sm")}{"" if only else f"<span class=lu-copy-label>{label}</span>"}</button>'


C["clipboard-variants"] = (700, colm(
    row(*[clip("neutral", v) for v in ["solid", "glow", "outline", "soft", "bordered", "flat", "ghost"]]),
    row(*[clip(c, "soft") for c in ["neutral", "primary", "secondary", "info", "success", "warning", "error"]]),
    row(*[clip(c, "solid", "md") for c in ["primary", "error"]], clip("primary", "solid", "md", "Copiar", True))))
C["clipboard-sizes"] = (700, row(
    *[clip("neutral", "outline", s) for s in SIZES], clip("neutral", "ghost", "sm", only=True),
    '<button type="button" class="lu-b c-success v-soft s-sm">' + ic("check", "sm") + "Copiado</button>"))
C["clipboard-input"] = (520, '<div style="max-width:460px">' + field("Chave de API", '<span class="lu-input"><span class="addon sep">' + ic("key", "md") +
    '</span><input readonly value="sk_live_51Hx…a9f2" style="font-family:var(--font-mono);font-size:13px"><button class="lu-b c-neutral v-soft s-sm" type="button" data-lu-copy="sk_live">' +
    ic("copy", "sm") + '<span class="lu-copy-label">Copiar</span></button></span>') + "</div>")

# ---------------------------------------------------------------- fab
import c7  # noqa: E402  (fab(), dial(), stage() do gerador original)

C["fab-canvas"] = (420, c7.stage(f'<button type="button" class="lu-fabc">{ic("plus", "md")}Novo pedido</button>'))
C["fab-pill-hover"] = (420, c7.stage(c7.fab("Pergunte ao assistente")))
C["fab-pill-expanded"] = (420, colm(
    c7.stage(c7.fab("Precisa de ajuda?", retract="auto", icon="help", state="expanded")),
    c7.stage(c7.fab("Nova fatura", "primary", "never", state="expanded")),
    c7.stage(c7.fab("Chat com a equipe", "light", "always", pos="pos-bl", badge=3, icon="chat")),
    c7.stage(c7.fab("Médio", "dark", "never", state="expanded", pos="pos-bl") + c7.fab("Grande", "assistant", "hover", "lg", state="expanded"))))
POS = 'style="position:relative;right:auto;bottom:auto" class="lu-fab2'
C["fab-pill-colors"] = (700, row(*[c7.fab(l, c, "never", state="expanded", icon="sparkles").replace('class="lu-fab2', POS) for c, l in [("assistant", "Assistente"), ("primary", "Primary"), ("dark", "Dark"), ("light", "Light")]]))
C["fab-pill-collapsed"] = (700, row(*[c7.fab(l, c, "always", badge=b, icon="sparkles").replace('class="lu-fab2', POS) for c, l, b in [("assistant", "Assistente", None), ("primary", "Primary", 7), ("dark", "Dark", None), ("light", "Light", 2)]]))
C["fab-positions"] = (700, grid(*[c7.stage(c7.fab("Novo", "dark", "always", pos=p, icon="plus"), 120) for p in ["", "pos-bl", "pos-tr", "pos-tl"]], cols=2, gap=12))
C["fab-dial-open"] = (700, grid(c7.stage(c7.dial("canvas", "open"), 300), c7.stage(c7.dial("pill", "open"), 300), cols=2, gap=16))
C["fab-dial-closed"] = (700, grid(c7.stage(c7.dial("canvas", "closed"), 300), c7.stage(c7.dial("pill", "closed"), 300), cols=2, gap=16))

# ---------------------------------------------------------------- button canvas: aparências (`appearance=`), tokens do tema
C["button-canvas-looks"] = (700, colm(
    row(btn("Primary", "primary"), btn("Ghost", "ghost"), btn("Primary", "primary", None, None, "disabled"), btn("Ghost", "ghost", None, None, "disabled")),
    row(btn("Confirm", "primary sm", "check"), btn("Clear", "ghost sm", "refresh"), btn("Primary lg", "primary lg"), btn("Ghost lg", "ghost lg"))))

# paisagem `summit`: o original pinta com --hero-* no host `.lu-summit-host` (+ svg preenchendo a caixa, regra do `.art`);
# a lib define --lu-hero-* no tema. Cobre claro, escuro e crepúsculo (as estrelas só aparecem no escuro)
SUMMIT_FILL = ".lu-summit{display:block;width:100%;height:100%}"
C["illustration-summit"] = (540, f'<div class="lu-summit-host" style="width:520px;height:300px">{c17.summit("hs")}</div>', SUMMIT_FILL)
C["illustration-summit-crop"] = (340, f'<div class="lu-summit-host" style="width:300px;height:300px;border-radius:14px;overflow:hidden">{c17.summit("hs")}</div>', SUMMIT_FILL)
