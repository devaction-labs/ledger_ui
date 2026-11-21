"""Rodada de correções (feedback/overlays/ações): casos novos dos recursos acrescentados (lado original)."""
from _common import *
from actions import b


C = {}


def steps_card(n, done, title, desc):
    segs = "".join(f'<i class="{"d" if i < done else "c" if i == done else ""}"></i>' for i in range(n))
    return (f'<div class="lu-tcard c-primary" style="width:100%"><span class="tile">{ic("layers", "md")}</span>'
            f'<div class="t"><b>{title}</b><span>{desc}</span><div class="segs">{segs}</div></div></div>')


C["fx-toast-steps"] = (420, colm(steps_card(5, 0, "Emitindo lote #118", "Validando, assinando e transmitindo."),
                                  steps_card(5, 2, "Emitindo lote #118", "Passo 3 de 5."),
                                  steps_card(4, 4, "Lote concluído", "Todos os passos.")))


# progress_ring: `.lu-ring` (anel de 56px, valor no centro)
C["fx-ring"] = (420, row('<div class="lu-ring" style="--p:64" data-l="64%"></div>', '<div class="lu-ring" style="--p:92" data-l="92%"></div>',
                         '<div class="lu-ring" style="--p:0" data-l="0%"></div>', '<div class="lu-ring" style="--p:100" data-l="100%"></div>'))


# connection_banner preview: faixa `.lu-conn` (off/re/on e o ciclo de 9s)
RE = '<span class="lu-ring2" style="width:16px;height:16px;border-color:currentColor;border-right-color:transparent"></span>'
C["fx-conn"] = (420, colm(
    f'<div class="lu-conn off">{ic("wifi", "md")}<span class="t" style="display:block">Sem conexão</span></div>',
    f'<div class="lu-conn re">{RE}<span class="t" style="display:block">Reconectando…</span></div>',
    f'<div class="lu-conn on">{ic("check-circle", "md")}<span class="t" style="display:block">Conectado</span></div>'))


# command_palette state="no_match": `.lu-pop.pad` com a mensagem e a linha do assistente
C["fx-palette-nomatch"] = (420, '<div class="lu-pop pad" style="width:280px"><span class="lu-small lu-muted">Nada encontrado para "bolet".</span>'
                           f'<div style="margin-top:8px"><button class="lu-menu-item" role="menuitem" type="button">{ic("sparkles")}Perguntar ao assistente</button></div></div>')


# tooltip_tip: o balão `.lu-tooltip` (12.5px, seta embaixo/à esquerda/em cima)
KB = '<kbd class="lu-kbd dark">⌘K</kbd>'
C["fx-tooltip-tip"] = (420, '<div style="display:flex;flex-direction:column;gap:22px;padding:8px 0 10px 8px;align-items:flex-start">'
                       f'<span class="lu-tooltip">Buscar {KB}</span><span class="lu-tooltip r">Salvar rascunho</span><span class="lu-tooltip b">Em cima</span></div>')


# count / delta / badge dot="live" (ponto pisca por opacidade; o anel fica fixo)
C["fx-count-delta"] = (420, row('<span class="lu-count">23</span>', '<span class="lu-count warn">8</span>', '<span class="lu-count">128</span>',
                               '<span class="lu-delta up">8.8%</span>', '<span class="lu-delta down">0.4 pts</span>', '<span class="lu-delta bad-up">0.4 pts</span>',
                               '<span class="lu-badge acc"><span class="lu-dot live"></span>Live</span>'))

# error_state compact: `.lu-errnum` (72px, gradiente) + título + descrição
C["fx-error-compact"] = (420, '<div class="lu-col" style="align-items:center;gap:8px;padding:20px"><span class="lu-errnum">404</span><b>Página não encontrada</b><span class="lu-small lu-muted">O endereço pode ter mudado.</span></div>')
