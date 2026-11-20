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
C = {k: (w, ORIG[k], COMPANION) for k, w in W.items() if k in ORIG}
