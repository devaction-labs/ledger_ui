"""Dados: card (lado original)."""
from _common import *
from actions import b

C = {}
C["card-tray"] = (460, card("Revenue by plan", '<p class="lu-muted" style="margin:0">Conteúdo do painel.</p>', b("Plans", "neutral", "outline", "sm", after="arrow-up-right"), foot="trailing 12 mo"))
C["card-flat"] = (460, '<section class="lu-card flat"><div class="lu-card-b"><b>Card plano</b><p class="lu-muted" style="margin:6px 0 0">Sem bandeja.</p></div></section>')

C["card-surfaces"] = (900, '<div style="display:grid;grid-template-columns:repeat(4,1fr);gap:12px">' + "".join(c13.cv(v) for v in ["default", "bordered", "outline", "muted", "soft", "filled", "solid", "glow", "gradient", "gradient_outline"]) + "</div>")
C["card-surface-colors"] = (900, '<div style="display:grid;grid-template-columns:repeat(6,1fr);gap:8px">' + "".join(c13.cv(v, c) for v in ["solid", "soft"] for c in ["primary", "secondary", "info", "success", "warning", "error"]) + "".join(c13.cv("gradient", "primary", g) for g in ["purple-indigo", "fuchsia-pink", "amber-orange", "sky-blue", "green-fuchsia"]) + "</div>")
C["card-sizes"] = (700, row(*[f'<div class="lu-cv default" style="padding:{p}px;{"" if s == "md" else "min-height:0"}"><b>{s}</b></div>' for s, p in [("xs", 8), ("sm", 11), ("md", 14), ("lg", 20)]]))
# regras das partes que só existem no CSS companheiro da lib (parity/legacy/ledger_ui.css), não no bundle da referência
PARTS_CSS = """.lu-card-s{font-size:13px;line-height:18px;margin:0}.lu-card-t.t-lg{font-size:15px;line-height:22px;letter-spacing:-.01em;text-transform:none;font-weight:600;color:var(--ink)}
.lu-card-t.t-xl{font-size:18px;line-height:26px;letter-spacing:-.015em;text-transform:none;font-weight:600;color:var(--ink)}
.lu-card-h.s-lg{padding:12px 14px 12px 18px;min-height:52px}.lu-card-h.s-xl{padding:16px 18px 16px 22px;min-height:60px}"""
C["card-parts"] = (520, '<section class="lu-card"><header class="lu-card-h"><h3 class="lu-card-t" style="margin:0">Profile</h3><div class="act">' + b("Edit", "neutral", "outline", "sm") + '</div></header><div class="lu-card-b">Corpo do cartão<p class="lu-card-s lu-muted" style="margin-top:8px">Subtítulo</p></div><div class="lu-card-f">All changes saved</div></section>', PARTS_CSS)
C["card-sizes-heading"] = (520, '<section class="lu-card"><header class="lu-card-h s-lg"><h3 class="lu-card-t t-lg" style="margin:0">Heading lg</h3></header><div class="lu-card-b">x</div></section>', PARTS_CSS)
