"""Métricas e gráficos: stat (lado original)."""
from _common import *

it, gr = c17.item, c17.group
C = {}
C["stat-default"] = (900, gr(it("Subtotal", "R$ 3.240"), it("Desconto", "− R$ 120"), it("Frete", "R$ 0", hint="grátis acima de R$ 300"), it("Total", "R$ 3.120", tone="accent")))
C["stat-sunken"] = (900, gr(it("Estoque", "1.284", "un"), it("Reservado", "96", "un"), it("Giro", "18", "dias"), it("Cobertura", "42", "dias", tone="accent"), variant="sunken"))
C["stat-bare"] = (900, gr(it("Abertas", "12"), it("Vencidas", "3", delta=("1", "up", False)), it("Pagas no mês", "R$ 48,2 mil", delta=("9%",)), card=False))
C["stat-rich"] = (1000, gr(
    it("Faturamento", "R$ 184.320", icon="wallet", delta=("12,4%",), hint="vs. outubro", sp=c17.V1),
    it("Cancelamentos", "23", icon="alert", delta=("0,4 pt", "down", True), hint="caiu", sp=(c17.V3, "pos")),
    it("Ticket médio", "R$ 168", icon="tag", delta=("0%", "flat"), hint="estável", sp=(c17.V4, "mut")),
    it("Meta do mês", "72%", meter=(72, "R$ 184 mil de R$ 256 mil"), size="sm")))
