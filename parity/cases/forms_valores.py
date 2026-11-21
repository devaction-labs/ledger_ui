"""Formulários (data/hora, valores, editores, upload): lado original.

O original de cada caso é um instantâneo de `forms_valores.exs` renderizado com a biblioteca ANTES da migração
(classes lu-* + estilos inline, commit 3506478) sobre a folha legada: o bundle da referência (já carregado por
run.py) mais o CSS companheiro da biblioteca (`parity/legacy/ledger_ui.css`, 3º elemento do caso). Regenerar:
`bash parity/cases/forms_valores_snapshot.sh`.
"""
import json, os
from _common import *

H = os.path.dirname(os.path.abspath(__file__))
ORIG = json.load(open(f"{H}/forms_valores_orig.json"))
COMPANION = open(f"{H}/../legacy/ledger_ui.css").read()   # regras lu-* que só existem no CSS da lib

# id -> largura do quadro (px)
W = {
    "calendar-month": 760, "calendar-month-handlers": 760, "calendar-month-more": 760, "calendar-month-noheader": 700,
    "calendar-week": 760, "calendar-week-handlers": 700, "calendar-day": 500,
    "calendar-mini-dot": 360, "calendar-mini-tint": 360, "calendar-mini-range": 360, "calendar-mini-multi": 700,
    "calendar-mini-bare": 360,
    "color-picker-full": 300, "color-picker-alpha": 300, "color-picker-popover": 340, "color-picker-swatches": 420,
    "date-picker-basic": 320, "date-picker-states": 320, "date-picker-open": 340, "date-picker-open-range": 560,
    "date-picker-panel": 900,
    "time-picker-basic": 320, "time-picker-list": 420,
    "datetime-picker-basic": 380, "datetime-picker-panel": 900,
    "image-input-states": 900, "image-input-field": 520,
    "rating-readonly": 400, "rating-interactive": 420, "rating-distribution": 560,
    "range-colors": 420, "range-sizes": 420, "range-wrapped": 420, "range-vertical": 320,
    "signature-pad": 440,
    "upload-drop": 400, "upload-zone": 1500, "upload-file": 460, "upload-thumbs": 560,
    "text-editor-default": 560, "text-editor-comment": 520, "text-editor-content": 520,
    "due-calendar": 520, "due-calendar-animated": 520,
}

# the hook turns off the demo animation of the stored paths (dash offset): the same for the original
SIG_HOOK = ".lu-sig svg path{animation:none!important;stroke-dasharray:none!important;stroke-dashoffset:0!important}"
C = {k: (w, ORIG[k], COMPANION + (SIG_HOOK if k.startswith("signature") else "")) for k, w in W.items() if k in ORIG}
