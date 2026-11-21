"""Shell/app, parte B (container, scroll area, sticky, logo, tema, trilho, cabeçalho, shell, sidebar, navbar,
landing nav, auth): lado original.

O original de cada caso é um instantâneo de `shell_b.exs` renderizado com a biblioteca ANTES da migração
(classes lu-* + estilos inline, commit 3506478) sobre a folha legada: o bundle da referência (já carregado por
run.py) mais o CSS companheiro da biblioteca (`priv/static/ledger_ui.css`, 3º elemento do caso). A referência não
tem a marcação equivalente (os componentes da biblioteca vão além do canvas). Regenerar:
`bash parity/cases/shell_b_snapshot.sh`. O que o JS aplica (menu recolhido) vai nos casos como `data-collapsed`.
"""
import json, os
from _common import *

H = os.path.dirname(os.path.abspath(__file__))
ORIG = json.load(open(f"{H}/shell_b_orig.json"))
COMPANION = open(f"{H}/../../priv/static/ledger_ui.css").read()   # regras lu-* que só existem no CSS da lib

# id -> largura do quadro (px)
W = {
    "container-fixed": 1500, "container-fluid": 900, "container-preview": 700,
    "scroll-plain": 700, "scroll-panel": 400, "scroll-preview": 700,
    "sticky-preview": 500, "sticky-bar": 400,
    "logo-chart": 700, "logo-hexagon": 500,
    "theme-switch-matrix": 400, "theme-picker-grid": 800, "theme-picker-menu": 200,
    "icon-rail": 500, "sidebar-panel": 700, "page-header-inline": 900, "page-header-page": 900,
    "app-shell-sidebar": 1000, "app-shell-framed": 1000, "app-shell-minimal": 900, "shell-floating": 800,
    "app-shell-sideblock": 900, "app-shell-horizontal": 900, "header-full": 1000, "framed-sidebar": 700,
    "tab-bar": 400, "right-sidebar": 500, "monochrome": 300, "shell-wire": 900, "shell-app": 900,
    "sidebar-sections": 900, "sidebar-collapsed": 500, "sidebar-tree": 700, "sidebar-rail": 1000, "sidebar-items": 400,
    "navbar-variants": 900, "navbar-pieces": 1300,
    "landing-nav-variants": 900, "landing-nav-responsive": 900, "landing-mega": 900, "landing-products": 900,
    "landing-announcement": 700,
    "auth-split-card": 1100, "auth-split-art": 1100, "auth-page": 1050,
}
# Dentro de uma `landing_nav` o `.lu-lnav a {color:inherit; text-decoration:none}` apaga o azul/sublinhado do UA nos
# links; estes casos mostram o menu fora da barra (o menu é sempre filho dela na prática), então o lado ORIGINAL
# recebe essa mesma regra (o `opacity:.8` da barra é anulado pelo `.lu-mega a {opacity:1}`). Sem isso o original
# mostraria links azuis sublinhados que não existem no uso real.
IN_NAV = ".lu-mega a, .lu-ann a {color:inherit;text-decoration:none}"
# O avatar `t1` do legado é teal fixo em todos os temas (não há regra de paleta); a lib nova o deriva do accent
# (bg-accent-100 / text-accent-800), que é o comportamento correto com a paleta crepúsculo. O lado ORIGINAL recebe
# os valores do accent crepúsculo escuro para comparar só o layout.
AV_T1 = '[data-theme=dark][data-palette=crepusculo] .lu-av.t1 {background:#141c48;color:#c9d6ff}'
# O legado não zera o padding do <button> (UA: 1px 6px): um avatar de 36px dentro do botão de 42px do trilho transborda
# e cola à direita (+3px). O HEEx (Tailwind preflight) o centra, que é o desenho. O ORIGINAL recebe o reset.
BTN0 = ".lu-rail-btn {padding:0}"
# `theme_toggle`: a doc da lib original diz "sol no escuro", mas o hook só trocava `data-icon` e o desenho ficava a lua
# (bug do original). O HEEx mostra o sol no escuro (`dark:`); o ORIGINAL recebe o `d` do sol para comparar o layout.
SUN = ("[data-theme=dark] [data-part=theme-toggle] svg[data-icon=moon] path {d:path('M17 12C17 14.7614 14.7614 17 12 17C9.23858 17 7 14.7614 7 12"
       "C7 9.23858 9.23858 7 12 7C14.7614 7 17 9.23858 17 12Z M12 2V3.5M12 20.5V22M19.0708 19.0713L18.0101 18.0106"
       "M5.98926 5.98926L4.9286 4.9286M22 12H20.5M3.5 12H2M19.0713 4.92871L18.0106 5.98937M5.98975 18.0107L4.92909 19.0714')}")
EXTRA = {"header-full": SUN, "theme-switch-matrix": SUN, "icon-rail": BTN0, "navbar-pieces": AV_T1, "landing-mega": IN_NAV, "landing-products": IN_NAV, "landing-announcement": IN_NAV}
C = {k: (w, ORIG[k], COMPANION + EXTRA.get(k, "")) for k, w in W.items() if k in ORIG}
# logo-chart (feat(logo)): the bundle's tile has a glyph of half the side (28 in 56) and a radius of ~.29 x side (16 in 56),
# the snapshot is the old .45/.3: patch the original (glyph sizes by `--s`, radius by CSS).
import re as _re
_h = _re.sub(r'(--s:(\d+)px" aria-hidden="true">\s*<svg width=")\d+(" height=")\d+', lambda m: f"{m[1]}{round(int(m[2]) / 2)}{m[3]}{round(int(m[2]) / 2)}", ORIG["logo-chart"])
C["logo-chart"] = (W["logo-chart"], _h, COMPANION + ".lu-logomark{border-radius:calc(var(--s)*.29)}")
