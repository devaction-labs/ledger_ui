"""Correções de fidelidade ao canvas (lote fx-forms-b): lado original = marcação `lu-*` do bundle
(`ledger_ui_ref/gen/bundle.css`), montada à mão como nos geradores dos canvas.

Calendário mini (tamanhos, faixa de uma semana), lista de horários nua, linha de amostras de cor,
etapas (linhas de 2px), assinatura só com o texto digitado, editor compacto, view_switcher esticado,
paginação com a seta anterior antes das páginas.
Não entram: o `variant="compact"` do color_picker (o bundle pinta o fim do degradê com a cor escolhida e
sem marcador de matiz; o componente real pinta o matiz puro e tem o marcador do controle) e as animações (`loop`).
"""
from _common import *

# setembro de 2023 (1º numa sexta; semana começando no domingo), como o canvas
LETTERS = "DSTQQSS"
DAYS_BEFORE = [27, 28, 29, 30, 31]
DOTS = {4, 11, 19, 25}


def cal2(size="", today=19, sel=None, rng=None, tint=False, dots=(), week=False):
    cells = "".join(f'<span class="h">{l}</span>' for l in LETTERS)
    if week:
        days = [(d, "d") for d in range(17, 24)]
    else:
        days = [(d, "o") for d in DAYS_BEFORE] + [(d, "d") for d in range(1, 31)]
    for d, k in days:
        cls = [k]
        if k == "d":
            if d == today: cls.append("t")
            if d == sel: cls.append("s")
            if rng and d == rng[0]: cls.append("rs")
            elif rng and d == rng[1]: cls.append("re")
            elif rng and rng[0] < d < rng[1]: cls.append("r")
            if d in dots: cls.append("tint" if tint else "dot")
        cells += f'<span class="{" ".join(cls)}">{d}</span>'
    return f'<div class="lu-cal2 {size}">{cells}</div>'


def box(c, body):
    return f'<div style="display:flex;flex-direction:column;gap:6px"><span class="lu-xs lu-muted mono">{c}</span>{body}</div>'


C = {}
C["fx-calendar-mini-sizes"] = (900, row(
    box("sm", cal2("sm", sel=19)),
    box("md · range", cal2("", rng=(12, 18))),
    box("lg", cal2("lg", sel=11))))
C["fx-calendar-mini-dots"] = (700, row(box("dot", cal2("", sel=19, dots=DOTS)), box("tint · sm", cal2("sm", dots=DOTS, tint=True))))
C["fx-calendar-mini-week"] = (400, cal2("", week=True))

TIMES = ["12:00", "12:30", "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30", "17:00"]
tl = lambda h="": f'<div class="lu-tlist" style="{h}"><div style="animation:none">' + "".join(f'<span class="{"on" if t == "14:30" else ""}">{t}</span>' for t in TIMES) + "</div></div>"
C["fx-time-list-bare"] = (400, row(tl(), tl("height:120px")))

SW = ["#141514", "#1f9282", "#6a4fd8", "#2d6fb7", "#11773e", "#b07a2c", "#b72f48", "#e57487", "#e8b04a", "#76cbb9"]
sw2 = lambda size="": f'<div class="lu-sw2 {size}">' + "".join(f'<i class="{"on" if i == 1 else ""}" style="background:{c}"></i>' for i, c in enumerate(SW)) + "</div>"
C["fx-color-picker-row"] = (420, colm(sw2("sm"), sw2(), sw2("lg")))

C["fx-signature-typed"] = (360, '<div class="lu-sig" style="width:300px"><span class="typed">Ana Nogueira</span></div>')

# editor compacto: o `.lu-rte` do bundle (toolbar 30x28, texto 12/14px, 90px)
rte_tb = "".join(f"<span>{ic(n, 'sm')}</span>" for n in ["bold", "italic", "link", "list"])
C["fx-text-editor-compact"] = (560, f'<div class="lu-rte" style="max-width:520px"><div class="tb">{rte_tb}</div><div class="tx"><b>Entrega:</b> após as 14h, portão lateral, falar com Rita</div></div>')

seg = lambda: '<div class="lu-seg block" style="width:330px"><button class="on" type="button">Lista</button><button type="button">Quadro</button><button type="button">Agenda</button></div>'
C["fx-view-switcher-stretch"] = (400, seg())

ar = lambda ic_: f'<span class="ar">{ic(ic_, "sm")}</span>'
pg = '<div class="lu-pg2 s-sm">' + ar("chevron-left") + "".join(f'<span class="{"on" if n == 2 else ""}">{n}</span>' for n in [1, 2, 3, 4]) + "<span>…</span><span>44</span>" + ar("chevron-right") + "</div>"
C["fx-pagination-sides"] = (500, pg)
