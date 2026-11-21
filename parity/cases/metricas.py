"""Métricas e gráficos (kpi_card, sparkline, bar_chart, donut_chart, waterfall_chart, cohort_heatmap, line_chart,
bar_list, heatmap): lado original.

O original de cada caso é um instantâneo de `metricas.exs` renderizado com a biblioteca ANTES da migração
(classes lu-* + estilos inline, commit 3506478) sobre a folha legada: o bundle da referência (já carregado por
run.py) mais o CSS companheiro da biblioteca (`parity/legacy/ledger_ui.css`, 3º elemento do caso). Regenerar:
`bash parity/cases/metricas_snapshot.sh`.
"""
import json, os
from _common import *

H = os.path.dirname(os.path.abspath(__file__))
ORIG = json.load(open(f"{H}/metricas_orig.json"))
COMPANION = open(f"{H}/../legacy/ledger_ui.css").read()   # regras lu-* que só existem no CSS da lib

# id -> largura do quadro (px)
W = {
    "kpi-card-canvas": 1100, "kpi-card-trend": 900, "kpi-card-spark": 900, "kpi-card-progress": 900,
    "kpi-card-badge": 1100, "kpi-card-badge-icon": 1100, "kpi-card-badge-count": 900, "kpi-card-loading": 700,
    "sparkline-colors": 700, "sparkline-shapes": 700,
    "bar-chart-default": 400, "bar-chart-shapes": 1000,
    "donut-chart-default": 440, "donut-chart-variants": 700,
    "waterfall-chart-default": 520, "waterfall-chart-auto": 520,
    "cohort-heatmap-default": 600, "cohort-heatmap-thresholds": 460,
    "line-chart-default": 680, "line-chart-single": 600, "line-chart-sub-delta": 600,
    "bar-list-default": 400, "heatmap-default": 700,
}
# The previous lib (legacy CSS) plays `mo-bar` ONCE with `animation-fill-mode: both`, and that keyframe ends at
# `scaleY(0)`: after the entrance its columns (and the waterfall bars) vanish. The migrated bars grow once and
# stay, so the original is shown without that animation (its steady state is the intended picture).
BARS_STAY = ".lu-bars > div, [data-wf] svg rect { animation: none !important; }"
# The plain sparkline of the canvas gets its svg from `LedgerUI.spark` (JS), which sizes it to the box; the
# server-drawn svg of the previous lib has no size rule outside a KPI card (it collapses), so the original is shown
# with the size the JS would give it.
SPARK_SVG = ".lu-spark svg { width: 100%; height: 100%; display: block; }"


def extra(k):
    return COMPANION + (BARS_STAY if k.startswith(("bar-chart", "waterfall-chart")) else "") + (SPARK_SVG if k.startswith("sparkline") else "")


C = {k: (w, ORIG[k], extra(k)) for k, w in W.items() if k in ORIG}
