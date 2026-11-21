"""Formulários: input (lado original)."""
from _common import *

C = {}
C["input-basic"] = (420, colm(
    field("E-mail", inp("voce@empresa.com", icon="mail")),
    field("Valor", inp("0,00", pre="R$", suf="BRL")),
    field("Nome", inp("", "Bompreço", cls="err"), "Campo obrigatório", err=True),
    field("Apelido", inp("Opcional"), "Aparece no recibo", opt=True)))
C["input-variants"] = (420, colm(
    inp("Filled", cls="filled"), inp("Small", cls="sm"), inp("Large", cls="lg"), inp("Pill", cls="pill"), inp("Desabilitado", cls="disabled", extra="disabled")))

C["input-states"] = (420, colm(
    '<label class="lu-field"><span class="lu-label">Cupom</span>' + inp("", "ORBIT20", icon="tag", cls="ok") + '<span class="lu-help ok">' + ic("check-circle", "sm") + "Cupom válido: 20% por 3 meses.</span></label>",
    field("Senha", inp("", "12345", icon="lock", cls="err", typ="password"), "Mínimo de 8 caracteres.", err=True),
    field("Obrigatório", inp("Digite"), req=True),
    inp("Plain", cls="plain"), inp("Direita", "1.234,00", cls="right"),
    inp("Filled sm", cls="filled sm"), inp("Pill lg", cls="pill lg"), inp("Erro sem rótulo", cls="err")))
C["input-pill-sizes"] = (420, colm(*[inp((v or "outlined") + " " + (s or "md"), cls=(v + " " + s).strip()) for v in ["", "filled", "plain"] for s in ["sm", "", "lg"]]))
C["input-inline-hint"] = (520, colm(
    '<label class="lu-field inline"><span class="lu-label">Nome</span>' + inp("Seu nome") + "</label>",
    '<label class="lu-field inline"><span class="lu-label">Valor</span>' + inp("0,00", pre="R$") + "</label>",
    '<label class="lu-field"><span class="lu-label">Telefone <span class="hint">só números</span></span>' + inp("(11) 99999-0000", icon="phone") + "</label>"))
