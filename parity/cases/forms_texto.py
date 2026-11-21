"""Formulários, texto e seleção (lado original): checkbox, radio, switch, segmented, chip, pill_select,
textarea, otp, number, password, input_group, form_section, select, autocomplete, pillbox, tags, phone, filter_menu."""
from _common import *
from base import seg, menu_item, av, badge, btn, check, demo, col  # noqa: E402

FC = c9.FC


def gr(cols, *items, gap="10px 14px", just="start"):
    unit = "minmax(0,1fr)" if just == "stretch" else "max-content"
    return f'<div style="display:grid;grid-template-columns:repeat({cols},{unit});gap:{gap};align-items:center;justify-items:{just}">' + "".join(items) + "</div>"


C = {}

# ------------------------------------------------------------------ Checkbox
CB_STATES = ["off", "on", "partial", "filled", "dis"]
C["checkbox-colors"] = (560, gr(5, *[c9.cb(checked=st in ("on", "dis"), color=c, ind=st == "partial", filled=st == "filled", dis=st == "dis")
                                    for c in FC for st in CB_STATES], gap="12px 28px"))
C["checkbox-sizes"] = (560, gr(4, *[c9.cb("Rótulo", True, size=s, shape="circle" if sh == "circle" else "") for sh in ["square", "circle"] for s in ["xs", "sm", "md", "lg"]], gap="12px 24px"))
C["checkbox-desc"] = (460, colm(
    c9.cb("Enviar DANFE por e-mail", True, sub="O cliente recebe o PDF e o XML assim que a nota é autorizada."),
    c9.cb("Reter ISS", sub="Só para serviços com retenção na fonte."),
    c9.cb("Selecionar todos", ind=True, sub="3 de 8 pedidos marcados"),
    c9.cb("Desabilitado", dis=True)))
C["checkbox-outline"] = (360, colm(
    '<label class="lu-check c-primary" style="padding:8px 12px;border:1px solid var(--line-strong);border-radius:10px"><input type="checkbox" checked><span class="t">Variante outline</span></label>'))

# ------------------------------------------------------------------ Switch
C["switch-colors"] = (560, gr(5, *[c9.sw(on=st != "off", color=c, outline="outline" in st, filled="filled" in st, dis=st == "dis")
                                  for c in FC for st in ["off", "on", "outline on", "outline filled", "dis"]], gap="12px 28px"))
C["switch-sizes"] = (560, gr(6, *[c9.sw(on=on, size=s, shape="pill" if sh == "pill" else "") for sh in ["squircle", "pill"] for s in ["sm", "md", "lg"] for on in (False, True)], gap="14px 24px"))
C["switch-inset"] = (460, row(*[c9.sw(on=True, size="lg", inset=i) for i in [2, 3, 4, 5, 6]]))
C["switch-labels"] = (560, gr(2,
    c9.sw("Notificar no WhatsApp", True, sub="Mensagem quando a nota for autorizada"),
    c9.sw("Cobrança automática", False, left=True, sub="Rótulo à esquerda"),
    c9.sw("Atualização ao vivo", True), c9.sw("Pequeno", True, size="sm"), gap="16px 40px"))

# ------------------------------------------------------------------ Radio
C["radio-basic"] = (520, gr(8, *[c9.cb(typ="radio", checked=on, color=c, size=s) for c in FC for s in ["xs", "sm", "md", "lg"] for on in (True, False)], gap="12px 16px"))
C["radio-shapes"] = (520, row(c9.cb("circle", True, typ="radio"), c9.cb("squircle", True, typ="radio", shape="squircle"),
                              c9.cb("filled", typ="radio", filled=True), c9.cb("desabilitado", True, typ="radio", dis=True)))
# o `choice()` da c9 deixa o radio nativo (`lu-rd`, sem regra); o design (c2) o desenha como `lu-check`: é o que a lib faz
def _card(h):
    import re
    return re.sub(r'<input type="radio" name="([^"]+)" ?(checked)? ?class="lu-rd">', lambda m: f'<span class="lu-check c-primary"><input type="radio" name="{m.group(1)}" {m.group(2) or ""}></span>', h)


C["radio-card"] = (700, gr(2,
    col(_card(c9.choice("Essencial", "Até 500 notas/mês", "R$ 89", True)), _card(c9.choice("Profissional", "Notas ilimitadas", "R$ 189")), _card(c9.choice("Sem preço", "Só descrição"))),
    col(_card(c9.choice("Básico", "Até 500 notas/mês", "R$ 89", True, True)), _card(c9.choice("Premium", "Notas ilimitadas", "R$ 189", False, True))),
    gap="10px 16px", just="stretch"), ".lu-choice.end .lu-check { order: 3; }")  # a regra do original ordena `input`; aqui o radio vem no span lu-check
C["radio-chip"] = (560, colm(
    row(*[f'<span class="lu-rchip {"on" if i == 1 else ""}">{t}</span>' for i, t in enumerate(["Pix", "Boleto", "Cartão", "Dinheiro"])]),
    row(*[f'<span class="lu-rchip pill c-success {"on" if i == 0 else ""}">{t}</span>' for i, t in enumerate(["Aberto", "Pago", "Vencido"])])))
C["radio-tile"] = (560, row(*[f'<span class="lu-rtile {"on" if t == "M" else ""}">{t}</span>' for t in ["PP", "P", "M", "G", "GG"]],
                            *[f'<span class="lu-rtile c-secondary {"on" if t == "2" else ""}">{t}</span>' for t in ["1", "2", "3"]]))

# ------------------------------------------------------------------ Segmented
C["segmented-basic"] = (620, colm(
    row(seg(["Day", "Month", "Year"], 1), seg(["Todos", "Erros", "Sucesso", "Avisos"], 0, counts=[15, 3, 8, 4])),
    row(seg(["7d", "30d", "90d", "12m"], 1, "sm")),
    '<div style="max-width:420px">' + seg(["Mensal", "Anual"], 0, "block") + "</div>"))

# ------------------------------------------------------------------ Chip
CH_ON = lambda t, on=False, cls="": f'<button class="lu-chip {cls} {"on" if on else ""}" type="button">{t}</button>'
C["chip-basic"] = (620, colm(
    row(*[CH_ON(t, i == 0) for i, t in enumerate(["Todos", "Em risco", "Expansão", "Novos"])], f'<button class="lu-chip dashed" type="button">{ic("plus", "sm")}Filtro</button>'),
    row(*[f'<button class="lu-chip acc {"on" if i in (0, 2) else ""}" type="button">{ic("check", "sm") if i in (0, 2) else ""}{t}<span class="n">{n}</span></button>' for i, (t, n) in enumerate([("Pro", 412), ("Scale", 298), ("Starter", 386)])])))

# ------------------------------------------------------------------ PillSelect
C["pill-select-basic"] = (620, colm(
    row(*[f'<button class="lu-chip {"on" if i == 1 else ""}" type="button">{t}</button>' for i, t in enumerate(["7 dias", "30 dias", "90 dias", "12 meses"])]),
    row(*[f'<button class="lu-chip acc {"on" if i in (0, 2) else ""}" type="button">{ic("check", "sm") if i in (0, 2) else ""}{t}<span class="n">{n}</span></button>' for i, (t, n) in enumerate([("Pro", 412), ("Scale", 298), ("Starter", 386)])])))

# ------------------------------------------------------------------ Textarea
fld, ta, help_cnt = c9.fld, c9.ta, c9.help_cnt
C["textarea-variants"] = (760, gr(3, *[ta(ph="Escreva uma observação…", cls=f'{"" if v == "outlined" else v} s-{s}') for v in ["outlined", "filled", "plain"] for s in ["sm", "md", "lg"]], gap="12px 14px", just="stretch"))
C["textarea-counter"] = (900, gr(4,
    fld("normal", ta("Cliente pediu nota com CPF.") + help_cnt("", "27 / 200")),
    fld("aviso (≥ 90%)", ta("Texto longo quase no limite…") + help_cnt("", "28 / 30", "warn")),
    fld("excedido", ta("Texto que passou do limite…", cls="err") + help_cnt("", "27 / 20", "over")),
    fld("mínimo", ta("Curto") + help_cnt("Explique o motivo", "5 / 20 mín.")), gap="12px 14px", just="stretch"))
C["textarea-state"] = (700, gr(2,
    fld("Motivo", ta("Cancelado a pedido do cliente.", cls="ok"), "Motivo registrado", "success"),
    fld("Motivo", ta("", "Obrigatório", cls="err"), "Informe o motivo do cancelamento", "error"), gap="12px 14px", just="stretch"))
C["textarea-bars"] = (700, gr(2,
    fld("Modelo de mensagem", ta(c9.MSG, bot=ic("bold", "sm") + ic("italic", "sm") + '<span class="lu-cnt">96 / 300</span>', top='<span class="lu-xs lu-muted">Variáveis</span>')), "", gap="12px 14px", just="stretch"))

# ------------------------------------------------------------------ OTP
otp = c9.otp
C["otp-sizes"] = (560, colm(*[row(otp("4829", 6, s, on=4)) for s in ["sm", "md", "lg"]]))
C["otp-variants"] = (760, gr(3,
    fld("length=4", otp("1234", 4)), fld("separator=3", otp("482915", sep=3)), fld("alphanumeric", otp("A7K2Q9")), gap="14px 24px"))
C["otp-states"] = (760, gr(3,
    fld("success", otp("482915", cls="ok"), "Código confirmado", "success"),
    fld("error", otp("482910", cls="err"), "Código inválido. Restam 2 tentativas.", "error"),
    fld("disabled", otp("", cls="dis")), gap="14px 24px"))

# ------------------------------------------------------------------ NumberStepper
num = c9.num
C["number-styles"] = (620, gr(3, *[num("12", st, s) for st in ["inset", "round", "joined"] for s in ["sm", "md", "lg"]], gap="14px 18px"))
C["number-addons"] = (760, gr(4,
    fld("Preço", num("1.284,90", pre="R$", steppers=False)), fld("Desconto", num("12,5", suf="%", steppers=False)),
    fld("Peso", num("0,750", suf="kg", steppers=False)), fld("Quantidade", num("3", pre="un")), gap="14px 18px"))
C["number-states"] = (560, row(num("8", filled=True), num("0", dis=True), fld("max=10", num("10"))))

# ------------------------------------------------------------------ PasswordInput (meter)
def pwd(label, level, help_):
    col_ = ["var(--neg)", "var(--warn)", "var(--teal-500)", "var(--pos)"][level - 1]
    bars = "".join(f'<i style="display:block;flex:1;height:4px;border-radius:2px;background:{col_ if i < level else "var(--bg-selected)"}"></i>' for i in range(4))
    # bundle: `.lu-dots` (18px, letter-spacing 3px) draws the masked text; the eye is 16px (fx-forms-a: lib follows)
    ctl = ('<span class="lu-input">' + ic("lock") + '<input type="password" value="abc123" style="font-size:18px;letter-spacing:3px"><button class="eye" type="button" aria-label="Mostrar">' + ic("eye", "md") + "</button></span>"
           + '<div style="display:flex;gap:4px;margin-top:4px">' + bars + "</div>")
    return fld(label, ctl, help_)


C["password-strength"] = (900, gr(4, pwd("Fraca", 1, "Muito curta"), pwd("Média", 2, "Adicione símbolos"), pwd("Boa", 3, "Quase lá"), pwd("Forte", 4, "Senha forte"), gap="14px 18px", just="stretch"))

# ------------------------------------------------------------------ InputGroup e FormSection
# A referência não tem InputGroup/FormSection como a lib os desenha (grupo de borda única; seção em grade): o
# lado original é o CSS companheiro da própria lib (parity/legacy/ledger.css 1794-1802, ledger_ui.css 59-69).
def _lib(path, a, b):
    root = os.path.join(os.path.dirname(__file__), "..", "legacy")
    return "".join(open(os.path.join(root, path)).readlines()[a - 1:b])


LIBCSS = _lib("ledger.css", 1794, 1802) + _lib("ledger_ui.css", 59, 69) + _lib("ledger_ui.css", 21, 33)


def igrp(cls, *items): return f'<span class="lu-igrp {cls}">' + "".join(items) + "</span>"


AD = lambda t: f'<span class="ad">{t}</span>'
IN = lambda v: f'<span class="lu-input plain"><input value="{v}"></span>'
C["input-group-basic"] = (620, colm(
    igrp("", AD("R$"), IN("1.250"), AD(",00")),
    igrp("sm", AD("$"), IN("49")), igrp("lg", AD("https://"), IN("ledgerly.app")),
    igrp("pill", AD("@"), IN("usuario")), igrp("filled", AD("USD"), IN("14.860")),
    igrp("err", AD("$"), IN("-3"))), LIBCSS)
C["form-section-basic"] = (760, colm(
    '<div class="lu-fsec"><div class="h"><b>Contato</b><p>Como falamos com você</p></div><div class="f" style="--cols:2">'
    + field("E-mail", inp("", "voce@empresa.com")) + field("Telefone", inp("", "(11) 99999-0000")) + "</div></div>",
    '<div class="lu-fsec aside"><div class="h"><b>Endereço</b><p>Usado na NF-e</p></div><div class="f" style="--cols:3">'
    + field("CEP", inp("", "40000-000")) + field("Cidade", inp("", "Salvador")) + field("UF", inp("", "BA")) + "</div></div>"), LIBCSS)

# ------------------------------------------------------------------ Select / Pillbox
SELCSS = LIBCSS + _lib("ledger.css", 1779, 1780) + _lib("ledger.css", 1784, 1786)
W260 = lambda x: f'<div style="width:260px">{x}</div>'
SELV = lambda v, ph=False, cls="": f'<span class="lu-input lu-select {cls}"><span class="val {"ph" if ph else ""}">{v}</span>{ic("chevron-down", "md chev")}</span>'
C["select-basic"] = (320, colm(
    W260(field("Plano", SELV("Pro"))), W260(field("Região", SELV("Escolha uma região", True))), W260(field("Desabilitado", SELV("EMEA", cls="disabled")))), SELCSS)
C["select-open"] = (320, W260(SELV("Pro") + '<div class="lu-pop" style="margin-top:6px">'
                              + menu_item("Pro", None, "", sel=True) + menu_item("Scale") + menu_item("Starter")
                              + menu_item("Enterprise", None, "Em breve").replace('type="button"', 'type="button" aria-disabled="true"') + "</div>"), SELCSS)
RMB = f'<button type="button" style="border:0;background:none;padding:0;display:inline-grid;cursor:pointer;color:inherit">{ic("x", "sm")}</button>'
C["pillbox-basic"] = (320, colm(
    W260('<div class="lu-pbox">' + "".join(f'<span class="lu-chip" style="height:24px">{t}{RMB}</span>' for t in ["Pro", "Scale"]) + ic("chevron-down", "sm") + "</div>"),
    W260('<div class="lu-pbox"><span class="val ph" style="flex:1;color:var(--muted)">Escolha segmentos</span>' + ic("chevron-down", "sm") + "</div>")), SELCSS)

# ------------------------------------------------------------------ Autocomplete
ACI = lambda a, t, n, p, hl=False: f'<button class="lu-menu-item {"hl" if hl else ""}" type="button">{av(a, t, 24)}<span>Orb{n}</span><span class="r">{p}</span></button>'
C["autocomplete-open"] = (420, W260('<span class="lu-input" style="width:100%">' + ic("search", "md") + '<input value="Orbit Cloud"></span>'
    + '<div class="lu-pop" style="margin-top:6px">' + ACI("OC", "t1", "it Cloud", "Pro · $4.2k") + ACI("OL", "t2", "ital Labs", "Scale · $1.9k") + ACI("OS", "t3", "is Systems", "Starter · $340") + "</div>"), SELCSS)
C["autocomplete-closed"] = (420, colm(W260(field("Conta", '<span class="lu-input">' + ic("search", "md") + '<input placeholder="Buscar conta"></span>')),
                                       W260(field("Plano", '<span class="lu-input sm">' + ic("search", "md") + '<input value="Pro"></span>'))), SELCSS)

# ------------------------------------------------------------------ TagsInput
# fx-forms-a: the tags are the design chips (24px, radius 10, 11px sides), as in the bundle pillbox/tags demos
C["tags-basic"] = (520, colm(
    field("Tags da conta", '<span class="lu-input" style="height:auto;min-height:38px;padding:5px 8px;flex-wrap:wrap;gap:6px">'
          + "".join(f'<span class="lu-chip" style="height:24px">{t}{RMB}</span>' for t in ["enterprise", "q4-renewal", "champion"])
          + '<input placeholder="Digite e pressione Enter" style="min-width:160px;height:26px"></span>'),
    field("Sem tags", '<span class="lu-input" style="height:auto;min-height:38px;padding:5px 8px;flex-wrap:wrap;gap:6px"><input placeholder="Adicionar tag" style="min-width:160px;height:26px"></span>')))

# ------------------------------------------------------------------ PhoneInput
# fx-forms-a: dial code muted and no chevron, as the bundle (`.addon.sep` is a muted text)
PH = lambda iso, dial, inp_: f'<span class="lu-input"><span class="addon sep" style="gap:6px;display:flex;align-items:center;cursor:pointer"><b class="lu-xs">{iso}</b>+{dial}</span>{inp_}</span>'
C["phone-basic"] = (620, gr(2,
    field("Telefone", PH("BR", "55", '<input value="(75) 99812-3344">')),
    field("WhatsApp", PH("US", "1", '<input placeholder="(555) 000-0000">')), gap="14px 18px", just="stretch"))

# ------------------------------------------------------------------ FilterMenu
# O painel da lib (seções de grupos, rodapé Limpar/Aplicar) não existe na referência: lado original = marcação e CSS da lib.
FMCSS = SELCSS + _lib("ledger.css", 1281, 1285)
LB = lambda t, c, v, s, extra="": f'<button type="button" class="lu-b c-{c} v-{v} s-{s} sh-rounded" {extra}>{t}</button>'
OPT = lambda t, n, on=False: f'<label class="lu-check c-primary s-sm" style="padding:6px 10px;width:100%;box-sizing:border-box"><input type="checkbox" {"checked" if on else ""}><span class="t">{t}</span><span style="margin-left:auto;color:var(--muted);font-size:12px">{n}</span></label>'
C["filter-menu-open"] = (520, '<span class="lu-anc">' + f'<button type="button" class="lu-b c-neutral v-outline s-md sh-rounded">{ic("filter")}Filtros</button>'
    + '<span class="fl p-bottom-start"><div class="lu-pop" style="width:288px;position:relative;white-space:normal">'
    + '<div><div class="lu-menu-label">Plano</div>' + OPT("Pro", 412, True) + OPT("Scale", 298, True) + OPT("Starter", 386) + "</div>"
    + '<div class="lu-menu-sep"></div><div class="lu-row" style="justify-content:space-between;padding:2px 5px 0">' + LB("Limpar", "neutral", "flat", "xs") + LB("Aplicar", "primary", "solid", "xs") + "</div></div></span></span>" + '<div style="height:260px"></div>', FMCSS)
C["filter-menu-closed"] = (420, row('<span class="lu-anc">' + f'<button type="button" class="lu-b c-neutral v-outline s-md sh-rounded">{ic("filter")}Filtros</button></span>',
                                    '<span class="lu-anc">' + f'<button type="button" class="lu-b c-primary v-soft s-sm sh-rounded" style="border-style:dashed">{ic("filter")}Status</button></span>'), FMCSS)
