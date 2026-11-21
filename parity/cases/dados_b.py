"""Dados B: kanban, timeline, step_group, treeview, hero_card, flow, table, data_table (lado original).

O original de cada caso é um instantâneo de `dados_b.exs` renderizado com a biblioteca ANTES da migração
(classes lu-* + estilos inline, commit 3506478) sobre a folha legada: o bundle da referência (já carregado por
run.py) mais o CSS companheiro da biblioteca (`parity/legacy/ledger_ui.css`, 3º elemento do caso). Regenerar:
`bash parity/cases/dados_b_snapshot.sh`.
"""
import json, os
from _common import *

H = os.path.dirname(os.path.abspath(__file__))
ORIG = json.load(open(f"{H}/dados_b_orig.json"))
COMPANION = open(f"{H}/../legacy/ledger_ui.css").read()   # regras lu-* que só existem no CSS da lib

# id -> largura do quadro (px)
W = {
    "kanban-board": 900, "kanban-colors": 900, "kanban-scroll": 700,
    "timeline-markers": 900, "timeline-sizes": 700, "timeline-colors": 900, "timeline-dot": 700, "timeline-canvas": 420,
    "step-group-states": 360, "step-group-plain": 360, "step-group-logs": 420,
    "tree-basic": 360, "tree-data": 620, "tree-check": 380,
    "hero-soft": 820, "hero-lg-meter": 900, "hero-panel-steps": 820, "hero-ai": 820, "hero-picture": 820,
    "flow-edges": 1100, "flow-panel": 1000, "flow-grid": 1000,
    "table-variants": 620, "table-shapes": 620, "table-select": 620, "table-select-all": 520, "table-expand": 520,
    "table-hand": 520, "table-priority": 800, "table-card": 480, "table-details": 640, "table-edit": 520,
    "table-skeleton": 520,
    "data-table-advanced": 760, "data-table-grid": 700, "data-table-pagers": 700, "data-table-states": 620,
    "table-toolbar": 760,
}
# o original de um botão de passo é o <button> do navegador (a folha legada não zera o botão; a vitrine antiga o fazia): zera-se aqui
BTN_RESET = ".lu-sg2 button.r{background:none;border:0;margin:0}"
# o <select> do tamanho da página era `lu-input` (display:flex) e quebrava o rótulo "Show … entries" em três linhas; agora fica em linha
SELECT_INLINE = "select.lu-input{display:inline-block}"
EXTRA = {"step-group-logs": BTN_RESET, "data-table-pagers": SELECT_INLINE}


def _unescape_style(html):
    """O CSS que a biblioteca antiga punha em <style> saía com HTML escapado (`&gt;`, `&#39;`): não funcionava no navegador.
    O original de referência é o CSS pretendido, então o escape é desfeito dentro dos <style>."""
    import re
    return re.sub(r"<style>(.*?)</style>", lambda m: "<style>" + m.group(1).replace("&gt;", ">").replace("&#39;", "'").replace("&quot;", '"').replace("&amp;", "&") + "</style>", html, flags=re.S)


ORIG = {k: _unescape_style(v) for k, v in ORIG.items()}
C = {k: (w, ORIG[k], COMPANION + EXTRA.get(k, "")) for k, w in W.items() if k in ORIG}
# feat(table): in the bundle the body rows' checkbox sits at `vertical-align: middle` (rows 47.5px, not 49px); the snapshot
# is the old baseline-aligned one, so the original gets the rule.
for _k, (_w, _h, _c) in list(C.items()):
    if "lu-table" in _h and "lu-check" in _h:
        C[_k] = (_w, _h, _c + "\n.lu-table tbody td .lu-check{vertical-align:middle}")
