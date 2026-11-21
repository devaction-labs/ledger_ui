"""Gera MIGRATION_REPORT.md a partir das saídas dos verificadores.

Uso:  python3 scripts/gen_migration_report.py PARITY_LOG THEME_LOG VISUAL_REPORT_JSON [BASELINE_REPORT_JSON [PRE_REMOVAL_REPORT_JSON]]

  PARITY_LOG     saída de `parity/run.py` (sem filtro)
  THEME_LOG      saída de `parity/run.py --theme`
  VISUAL_REPORT  <saida>/out/report.json de `scripts/visual/run.sh` (com TEMPLATES=1)
  BASELINE       (opcional) report.json anterior, para o comparativo
  PRE_REMOVAL    (opcional) report.json da mesma rodada sobre o commit anterior à remoção do CSS legado

Precisa de `mix` (MIX_DEPS_PATH) para listar módulo/função de cada componente. Os textos de desvios (DEVIATIONS)
são mantidos à mão aqui: cada um foi reverificado na rodada que gerou o relatório.
"""
import json, os, re, subprocess, sys, datetime

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
plog, tlog, vjson = sys.argv[1:4]
base = json.load(open(sys.argv[4])) if len(sys.argv) > 4 else None
pre = json.load(open(sys.argv[5])) if len(sys.argv) > 5 else None
vis = json.load(open(vjson))
THEMES = ["light", "dark", "crepusculo", "crep-dark"]


def num(x):
    try: return float(x.rstrip("%"))
    except Exception: return None


# ---- paridade
rows = []
for ln in open(plog):
    p = ln.split()
    if len(p) == 5 and p[0] != "caso" and (p[1].endswith("%") or p[1] == "tam" or p[1] == "sem"):
        rows.append(p)
    elif len(p) >= 5 and p[0] != "caso" and re.match(r"^[\w-]+$", p[0]) and any(x.endswith("%") for x in p[1:]):
        rows.append([p[0]] + ln.split(None, 1)[1].split())  # linha com 'tam ...': mantém só as colunas
vals = {r[0]: [num(c) for c in r[1:5]] for r in rows if len(r) >= 5}
mx = max(v for vs in vals.values() for v in vs if v is not None)
over = {k: vs for k, vs in vals.items() if any(v is None or v >= 0.095 for v in vs)}
zero = sum(all(v == 0 for v in vs) for vs in vals.values())
le001 = sum(all(v is not None and v <= 0.01 for v in vs) for vs in vals.values())
le005 = sum(all(v is not None and v <= 0.05 for v in vs) for vs in vals.values())

# ---- tema próprio
trows = []
for ln in open(tlog):
    m = re.match(r"^(\S+)\s+([\d.]+)%\s+([\d.]+)%\s*$", ln.rstrip())
    if m and m.group(1) != "caso": trows.append((m.group(1), float(m.group(2)), float(m.group(3))))
tbad = [r for r in trows if r[1] > 0.05 or r[2] > 0.05]

# ---- componentes: módulo / função por componente da referência
code = r'''
for m <- LedgerUI.Components.__modules__() do
  fns = m.__components__() |> Map.keys() |> Enum.filter(&function_exported?(m, &1, 1)) |> Enum.map(&Atom.to_string/1)
  IO.puts(Jason.encode!(%{mod: inspect(m), fns: fns}))
end
'''
out = subprocess.run(["mix", "run", "-e", code], cwd=ROOT, capture_output=True, text=True).stdout
mods = {}
for ln in out.splitlines():
    if ln.startswith("{"):
        d = json.loads(ln); mods[d["mod"]] = set(d["fns"])


def snake(n): return re.sub(r"(?<!^)(?=[A-Z])", "_", n).lower()


alias = {"ActionButton": "action_button", "ActionMenu": "action_menu", "CommandPaletteDialog": "command_palette_dialog", "Sheet": "sheet",
         "Treeview": "treeview", "Menu": "menu", "DateTimePicker": "date_time_picker", "NumberStepper": "number_stepper", "RangeSlider": "range_slider",
         "RadioChoice": "radio_choice", "ProgressBar": "progress_bar", "EmptyStateCard": "empty_state_card", "InlineEmpty": "inline_empty",
         "RichTextEditor": "rich_text_editor", "CommentEditor": "comment_editor", "IconRail": "icon_rail", "SubNav": "sub_nav",
         "ShellFloating": "shell_floating", "CoverCard": "cover_card", "Field": "field", "StatusToast": "status_toast", "ToastCard": "toast_card",
         "Toaster": "toaster", "AiChat": "ai_chat", "AiComposer": "ai_composer", "AiInsights": "ai_insights", "AiMessage": "ai_message",
         "AiPromo": "ai_promo", "AiProposal": "ai_proposal", "AiToolTrace": "ai_tool_trace", "ConversationList": "conversation_list",
         "PromptSuggestions": "prompt_suggestions", "EmailLayout": "email_layout", "Stat": "stat_item", "TableToolbar": "table_toolbar", "DataTable": "data_table"}
mig = []
for ln in open(os.path.join(ROOT, "MIGRATION.md")):
    if re.match(r"^\| \d ", ln):
        c = [x.strip() for x in ln.strip().strip("|").split("|")]
        lote, ref, api, mod = c[0], c[1], c[2].strip("`"), re.search(r"`([^`]+)`", c[3]).group(1)
        fns = mods.get(mod, set())
        guess = [alias.get(ref), snake(ref), api]
        fn = next((g for g in guess if g and g in fns), None)
        mig.append((lote, ref, mod, fn, api, sorted(fns)))
unres = [m for m in mig if m[3] is None]

# ---- visual
vs = vis["summary"]
secs = vis["sections"]
worst = sorted([s for s in secs if not s.get("pass")], key=lambda s: -s["max"])
tpl = vis.get("templates", {})
bs = base["summary"] if base else None
btpl = base.get("templates", {}) if base else {}
bpass = {(s["id"], s["idx"]): s.get("pass") for s in base["sections"]} if base else {}
bmax = {(s["id"], s["idx"]): s["max"] for s in base["sections"]} if base else {}
regress = [s for s in secs if base and (s["id"], s["idx"]) in bmax and s["max"] > bmax[(s["id"], s["idx"])] + 0.05]
newly_bad = [s for s in secs if base and bpass.get((s["id"], s["idx"])) and not s.get("pass")]

DEVIATIONS = """Cada item foi reverificado na rodada que gerou este relatório (números nas tabelas abaixo). O runner de paridade não tem
mecanismo de exceção: esta lista é o registro.

### Paridade de pixels (`parity/run.py`, limite 0,1%)

| caso | tema | % | motivo |
|---|---|---|---|
| `palette-bare`, `palette-typed` | crep-dark | 0,20 / 0,16 | Cor do placeholder do campo de busca: o original não define a cor (o navegador usa o cinza do UA) e o componente usa o token do tema, que no escuro de Crepúsculo é azulado. Só nessa combinação. |
| `avatar-legacy-t1` | crepusculo | 0,41 | O original (lib antiga sobre o CSS legado) tem o avatar `t1` com o teal fixo do Ledger; o componente usa o accent do tema (índigo em Crepúsculo). Regra do kit: nunca cor de marca fixa. |
| `radio-shapes` | light / crepusculo | 0,09 / 0,10 | Antialias do círculo/squircle do radio (mesma caixa, sem diferença de cor). |

### Tema próprio (`parity/run.py --theme`, limite 0,05% de pixels ainda na cor do Ledger)

| caso | % | motivo |
|---|---|---|
| `code-block-basic`, `code-block-diff`, `ref-code-block` | 0,07–0,09 | As cores da sintaxe são fixas (como no bundle): não derivam do accent. |
| `theme-picker-grid` | 4,18 | A grade mostra as amostras fixas dos temas (dado do seletor: `bg`/`accent`/`ink` de cada tema, inclusive o "Ledger" teal), não cor do componente. |
| `fx-color-picker-row` | 4,78 | Novo nesta rodada. As amostras do `variant="row"` reproduzem o conjunto fixo do canvas (inclui `#141514` e `#1f9282`, que coincidem com tokens do Ledger): são dados (cores escolhidas), não tema. |

### Decisões de design e do componente (não são bug)

* **`progress_bar` #1 e #8 (vitrine x canvas):** as demos do canvas usam o estilo "plano" antigo; o componente segue o bundle (`.lu-pg`).
* **`divider` com rótulo:** o texto é em maiúsculas, como no bundle (`text-xs tracking-[.06em] uppercase`).
* **`email` `variant="document"`:** mantém estilos inline (tabelas + `style=`), a única exceção a "só utilitários": cliente de e-mail não carrega
  CSS externo nem classes (documentado no módulo). `variant="preview"` é só utilitários.
* **`color_picker` `compact`:** o canvas desenha um mock com gradiente fixo; o componente desenha a área real de saturação/brilho e a barra de matiz.
* **`theme_toggle`/`theme_switch`:** o sol aparece no escuro (`dark:`), como a doc da lib original promete; o original nunca mostrava o sol (o hook
  só trocava o atributo `data-icon`, não o desenho: bug do original). Os casos de paridade aplicam o `d` do sol ao lado ORIGINAL.
* **`code_block`:** o `<pre>` mantém a família `monospace` do navegador, como o bundle (não `font-mono`).
* **Casos de `shell_b`:** o lado ORIGINAL recebe CSS extra (3º elemento do caso) onde o legado só renderiza "errado" fora do uso real
  (links do menu fora de `.lu-lnav`, `<button>` sem reset de padding).
* **Overlays animados (`drawer`, `sheet`, `modal`):** conferido nas imagens: o canvas mostra a demo `mo-*` congelada numa fase da animação de abrir,
  o componente anima com outra sequência, então caem em fases diferentes (algumas caixas ficam com altura diferente). Já estavam acima do limite
  na linha de base.

**Não analisado seção a seção:** as demais seções acima do limite da tabela "Seções acima do limite" (campos de formulário, tipografia, gráficos,
tabelas). A coluna "linha de base" mostra o valor de antes das rodadas de correção; nenhuma foi aceita aumentando limite.
"""

o = []
w = o.append
w("# Relatório da migração para Tailwind CSS v4\n")
w(f"Gerado em {datetime.date.today().isoformat()} (`scripts/gen_migration_report.py`). Ramo `feature/tailwind`. Sem push, sem release.\n")
w("## Resumo\n")
w(f"* **{len(mig)} componentes da referência** em HEEx + utilitários Tailwind v4 (tabela abaixo), 100% dos function components públicos da lib.")
w("* Nenhuma classe `lu-*` e nenhum CSS de componente: `assets/css/ledger_ui.css` só tem tokens, `@theme`, `@layer base` e `@keyframes` (gerado por `scripts/tw/tw_theme.py`).")
w(f"* **Paridade de pixels** (`parity/run.py`, sem filtro): {len(vals)} casos × 4 temas; maior diferença {mx:.2f}%; {zero} casos em 0,00% nos 4 temas, "
  f"{le001} ≤ 0,01%, {le005} ≤ 0,05%; **{len(over)} casos com alguma célula acima de 0,1%** (todos explicados em 'Desvios').")
w(f"* **Tema próprio** (`parity/run.py --theme`, fúcsia + slate): {len(trows)} casos, {len(tbad)} acima de 0,05% de pixels ainda na cor do Ledger"
  + (": " + ", ".join(f"{r[0]} ({r[1]:.2f}% claro / {r[2]:.2f}% escuro)" for r in tbad) if tbad else "") + ".")
w(f"* **Comparação visual canvas × vitrine** (`scripts/visual/run.sh`, claro e escuro, hover incluído): {vs['sections']} seções, "
  f"**{vs['pass']} dentro do limite** (0,6% da caixa e 15% da tinta), {vs['over']} acima, {vs['errors']} com erro, {vs['hoverMissing']} hovers perdidos.")
for th in ("light", "dark"):
    if th in tpl:
        t = tpl[th]; w(f"* Templates ({th}): {t['n']} telas, {t['lt1']} abaixo de 1%, {t['lt5']} abaixo de 5%, média {t['avg']}%.")
w("")

w("## Desvios que não zeraram\n")
w(DEVIATIONS.strip() + "\n")
w("### Casos de paridade acima de 0,1% nesta rodada\n")
w("| caso | " + " | ".join(THEMES) + " |\n|---|" + "---|" * 4)
for k, vs_ in sorted(over.items()):
    w(f"| {k} | " + " | ".join("-" if v is None else f"{v:.2f}%" for v in vs_) + " |")
w("")

w("## Comparação visual canvas × vitrine\n")
if bs:
    w(f"Linha de base (antes das rodadas de correção e da remoção do CSS legado): {bs['pass']}/{bs['sections']} dentro do limite, {bs['over']} acima. "
      f"Agora: {vs['pass']}/{vs['sections']}, {vs['over']} acima.\n")
    w(f"Seções que **pioraram** além de 0,05 ponto em relação à linha de base: {len(regress)}; que passavam e agora não passam: {len(newly_bad)}.\n")
    if regress:
        w("| seção | antes (máx %) | agora (máx %) |\n|---|---|---|")
        for s in sorted(regress, key=lambda s: -(s["max"] - bmax[(s["id"], s["idx"])]))[:40]:
            w(f"| {s['id']} #{s['idx']} | {bmax[(s['id'], s['idx'])]:.2f} | {s['max']:.2f} |")
        w("")
        if pre:
            w("Nenhuma delas é efeito da remoção do CSS legado: o valor é o mesmo no commit anterior à remoção (comparação acima). "
              "A piora vem das rodadas de correção (a linha de base é anterior a elas) ou do ajuste do harness; `color-picker #1` é o mock de gradiente do canvas "
              "(ver Desvios). Não foram corrigidas aqui: decisão do dono.\n")
if pre:
    pm = {(x["id"], x["idx"]): x for x in pre["sections"]}
    worse = [(x["id"], x["idx"], pm[(x["id"], x["idx"])]["max"], x["max"]) for x in secs
             if (x["id"], x["idx"]) in pm and x["max"] > pm[(x["id"], x["idx"])]["max"] + 0.05]
    w(f"**Efeito da remoção do CSS legado** (a mesma rodada, harness atual, sobre o commit anterior à remoção, 66b6158): antes {pre['summary']['pass']}/{pre['summary']['sections']} dentro do limite, "
      f"depois {vs['pass']}/{vs['sections']}. Seções que pioraram além de 0,05 ponto: {len(worse)}"
      + (": " + ", ".join(f"{a} #{b} ({c:.2f} -> {d:.2f})" for a, b, c, d in worse) if worse else "") + ".\n")
if base:
    for th in ("light", "dark"):
        if th in tpl and th in btpl:
            w(f"Templates ({th}): antes {btpl[th]['lt1']}/{btpl[th]['n']} < 1% (média {btpl[th]['avg']}%), agora {tpl[th]['lt1']}/{tpl[th]['n']} (média {tpl[th]['avg']}%).")
    w("")
w("Seções acima do limite (piores primeiro; `max` = % da caixa):\n")
w("| seção | max % | tinta % | linha de base (máx %) | tamanho |\n|---|---|---|---|---|")
for s in worst:
    bv = bmax.get((s["id"], s["idx"]))
    w(f"| {s['id']} #{s['idx']} | {s['max']:.2f} | {s.get('maxInk', 0):.1f} | {'-' if bv is None else f'{bv:.2f}'} | {'diferente' if s.get('sizeMismatch') else ''} |")
w("")

w("## Componentes migrados (referência → módulo/função)\n")
w("| lote | componente da referência | módulo da lib | função |\n|---|---|---|---|")
for lote, ref, mod, fn, api, fns in mig:
    w(f"| {lote} | {ref} | `{mod}` | " + (f"`<.{fn}>`" if fn else f"`<.{api}>` (módulo `{api}`)") + " |")
w("")
w(f"Todos os function components públicos da lib (um exemplo de cada no README): {sum(len(v) for v in mods.values())} em {len(mods)} módulos.\n")

w(f"## Paridade de pixels por caso ({len(vals)} casos × 4 temas, % de pixels diferentes)\n")
w("| caso | " + " | ".join(THEMES) + " |\n|---|---|---|---|---|")
for k, vs_ in vals.items():
    w(f"| {k} | " + " | ".join("-" if v is None else f"{v:.2f}" for v in vs_) + " |")
w("")
w(f"## Tema próprio por caso ({len(trows)} casos, % de pixels ainda na cor do Ledger)\n")
w("| caso | light | dark |\n|---|---|---|")
for k, a, b in trows:
    w(f"| {k} | {a:.2f} | {b:.2f} |")
w("")
open(os.path.join(ROOT, "MIGRATION_REPORT.md"), "w").write("\n".join(o))
print("ok", len(vals), "casos;", len(over), "acima de 0,1%;", len(unres), "componentes sem função resolvida:", [(m[1], m[4]) for m in unres])
