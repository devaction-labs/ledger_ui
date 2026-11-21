# Migração para Tailwind CSS v4 (HEEx + utilitários)

Cada componente vira HEEx estilizado **só com utilitários do Tailwind** (estilo Fluxon/shadcn), com a mesma
imagem do original (`lu-*`) em claro, escuro e paleta `crepusculo`. O piloto (Icon, Button, Badge, Input, Card,
Stat + `Form.field/label/error/help_text`) está pronto e é o modelo: leia `lib/ledger_ui/components/{button,badge,card,input,stat}.ex`.
Nunca chame o kit de "LineaUI".

## Regras do kit (obrigatórias)

1. Só utilitários nos componentes; valores arbitrários valem (`h-[30px]`, `shadow-[…]`, `[--c:var(--lu-ink)]`, `bg-(--c-soft)`).
   Nenhuma classe CSS nova. Exceções no CSS: tokens, `@theme`, `@layer base` mínimo e `@keyframes`.
2. Variáveis de runtime com prefixo `--lu-`, trocadas por `data-theme="light|dark"` e `data-palette="crepusculo"`.
3. `dark:` = `@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *))`.
4. **Tema como no Flux**: nunca cor de marca nem cinza fixos, e nunca escreva `teal`. Accent: `bg-accent`, `text-accent-content`,
   `text-accent-foreground`, `bg-accent-50…900`, `bg-accent-soft` (em arbitrário: `var(--color-accent)`, `var(--lu-accent-500)`).
   Neutros pelos tokens: `bg-page|shell|tray|panel|sunken|hover|selected`, `border-line|line-strong`, `text-ink|ink-2|muted|subtle`,
   `bg-inverse text-on-inverse`, `bg-pos|neg|warn|info|lime|violet` (+ `-soft`), `shadow-xs…lg|btn`, `rounded-xs|sm|md|lg|xl|2xl` (4/6/10/14/20/28px),
   `font-sans|display|mono`. Tudo deriva de `--color-accent*` e `--color-gray-50…950` (README, "Tema próprio").
5. Cores semânticas (`color=`): `LedgerUI.Color.vars(color)` (`--c`, `--c-on`, `--c-soft`, `--c-ink`); as variantes só leem essas quatro.
6. Arredondado por padrão; pílula só com `shape="pill"`.
7. Ícones: `<.icon name="huge-…" size="sm|md|base|lg|xl">` (Hugeicons Stroke Rounded, `priv/icons.json` = `priv/hugeicons.json` da referência).
8. Movimento: manter as animações originais (`@keyframes` no CSS gerado; `animate-[nome_dur_easing_infinite]`); interação por `Phoenix.LiveView.JS` + hooks.
9. Tudo é componente utilizável; atributos dirigem o visual; formulários aceitam `field={@form[:x]}` e mostram erros do changeset via `<.field>`.
10. `attr`/`slot` com `values:` e `doc`. **Nunca dependa da ordem das classes**: escolha UM utilitário por propriedade em Elixir
    (o tamanho decide `px` e `rounded`; `shape="square"` troca `px-N` por `w-N px-0`; a cor da borda mora na variante, não na base).
    `class` serve para layout (`w-full`, `ml-auto`), não para sobrescrever o visual do componente.
11. Sem `font-size` no `html`, só no `body` (o showcase força `html{font-size:16px}` por causa do CSS antigo).
12. Todo elemento do componente leva `data-part="<nome>"` (veja "Testes do showcase").
13. Espaço em branco dentro de contêiner flex vira item: escreva conteúdo inline "colado" (`>{@x}<span …`), como em `Button.button_content/1`.

## Ferramentas (reprodutível)

Requisitos: Elixir (mise), Chromium (`/usr/bin/chromium`), Python com `playwright pillow numpy beautifulsoup4 markdown`
em um venv **fora do repo** e o binário standalone do Tailwind v4.

```bash
python3 -m venv /home/alex/ElixirProjects/open-source/.venv-ledger
/home/alex/ElixirProjects/open-source/.venv-ledger/bin/pip install playwright pillow numpy beautifulsoup4 markdown
(cd showcase && mix deps.get && mix tailwind.install)       # binário em showcase/_build/tailwind-linux-x64-4.1.7
export MIX_DEPS_PATH=/home/alex/ElixirProjects/open-source/ledger_ui/deps           # raiz (showcase: .../ledger_ui/showcase/deps)
export LEDGER_REF=/home/alex/ElixirProjects/open-source/ledger_ui_ref               # padrão: ../ledger_ui_ref ou ../../ledger_ui_ref
python=/home/alex/ElixirProjects/open-source/.venv-ledger/bin/python
$python scripts/tw/tw_theme.py                # regera assets/css/ledger_ui.css (NUNCA edite à mão)
$python parity/run.py [filtro ...]            # paridade de pixels; saída em /tmp/parity (PARITY_DIR)
$python parity/run.py --theme [filtro ...]    # verificação do tema próprio (fuchsia + slate)
```

Escolha do Tailwind: binário standalone pelo pacote hex `tailwind` (dep do showcase), sem Node. `TAILWIND_BIN` sobrescreve.
`scripts/tw/` guarda `tw_theme.py`, `render.py`, `ref.py` e `tokens.json` (cópia de `referencia/tokens.json`); a referência
(`LEDGER_REF`) é só leitura, nunca publicada nem lida em runtime: `ref.py` monta uma cópia dos geradores `gen/c*.py` em
`/tmp/parity/_refws` (eles esperam `out/design-system/…`) sem editar a referência.

## Receita por componente

1. **Leia as regras** em `ledger_ui_ref/gen/bundle.css` (`lu-*`). Regras duplicadas: a última vence; leia TODAS as ocorrências da classe.
2. **Gerador**: `ledger_ui_ref/gen/cN.py` (`comp("Nome", …)`) mostra a marcação de cada variação; `referencia/components/<Nome>/preview.html`.
3. **API**: `ledger_ui_ref/docs/heex.py` e `ex/` (piloto). A API do piloto vence; preserve capacidades existentes da lib que não a contradizem
   (`field=`, máscaras/hooks, `use LedgerUI, only:/except:`, `data-part`, ARIA). Nome de `attr` e `slot` iguais não compilam: reaproveite o
   atributo global (`title`, ver `Card`) ou renomeie o slot (`Input`: `prefix`/`suffix` viraram texto; slots `:leading`/`:trailing`).
4. **Escreva o `.ex`** em `lib/ledger_ui/components/<api>.ex` só com utilitários (mapas `@variants`/`@sizes`, um utilitário por propriedade).
5. **Casos de paridade** com o MESMO id em `parity/cases/<lote>.py` (lado original) e `parity/cases/<lote>.exs` (módulo
   `Parity.Cases.<Lote>` com `cases/0`): cor × variante × tamanho × forma × estados. Regra do original que só existe no CSS companheiro da lib
   entra como 3º elemento do caso (`(largura, html, css_extra)`), com comentário.
6. **Rode** `parity/run.py <filtro>` e `--theme <filtro>`. Meta 0,00% (aceito ≤ 0,1%), mesmo tamanho de caixa em
   light, dark, crepusculo e crep-dark. Divergiu: **corrija o componente, nunca o original**.
7. **Testes**: ajuste `test/ledger_ui/components/<api>_test.exs` para afirmar utilitários, não `lu-*`. `mix test`, `mix format` e
   `mix compile --warnings-as-errors` (raiz e `showcase/`).
8. **Exemplos**: ajuste `showcase/examples/<id>/NN.heex` para a API nova (animações legadas `mo-*` viram `loop`/`animate-[…]`).
9. **Commit**: `Tailwind: lote <grupo> (<componentes>)`.

## Testes do showcase (migração em andamento)

* O CSS legado (`ledger.css`/`ledger_ui.css`, `legacy_icons.css`) foi removido do pacote e da vitrine. Uma cópia fica em `parity/legacy/`
  (só referência: o lado ORIGINAL dos casos por snapshot da lib antiga; não entra no pacote Hex).
* O teste de marcação (`Parity`, `converted_parts.exs`, `parity_exceptions.exs`) também saiu; os testes são `examples_test.exs`
  (sem `lu-*`, ARIA/estrutura, `data-part`), os de estrutura dos templates e os LiveView.

## Exemplos da vitrine

Os exemplos (`showcase/examples/<id>/NN.heex`) são componentes reais; nenhum pode depender de classes `lu-*`. `NN` = posição da seção em `design/vitrine/sec/<id>.json`,
depois as demos só do canvas (`design/canvas/extras.json`).

### Receita

1. Reescreva o exemplo só com `<.componente …>` da lib (atributos/slots dirigem o visual; `color=`, `variant=`, `size=`, `shape=`,
   `loading={…}`, `field={…}`). Marcação crua só para **contêineres de layout** do exemplo, com utilitários do Tailwind:
   `lu-row` = `flex flex-wrap items-center gap-2.5`, `lu-col` = `flex flex-col gap-2.5`, `lu-grid` (`--cols:N`) = `grid grid-cols-N gap-4`
   (`grid-cols-4` etc.), `lu-cap` = `font-mono text-[11px] text-muted`, `lu-cell` = `flex flex-col items-start gap-1.5`,
   `lu-muted` = `text-muted`, `lu-xs` = `text-xs`. Nunca `style="…"` para o que um
   atributo do componente resolve. Nenhuma classe `lu-*`, nenhum `<style>`, nenhuma cor/cinza fixos (tokens: `bg-panel`, `text-ink`,
   `border-line`, `bg-accent`…). `class=` do componente só para layout (`w-full`, `ml-auto`); nunca para sobrescrever o visual.
2. Falta um atributo/variante para reproduzir o canvas? Corrija o **componente** (e o caso de `parity/`), não o exemplo.
3. Tire o `lu-*` do exemplo (o teste falha com qualquer token `lu-*` em `class`).
4. Compare com o canvas, por seção (próxima seção). Alvo: **≤ 0,6 % da caixa e ≤ 15 % dos pixels desenhados** (padrões do script), em
   claro e escuro, hover incluído, mesmo tamanho de caixa, **sem hover que o canvas tem e a vitrine não tem**.
5. `cd showcase && mix test test/examples_test.exs --only component:<id>`; antes do commit: `mix test`, `mix format`,
   `mix compile --warnings-as-errors` (raiz e `showcase/`).

### Teste do exemplo (`showcase/test/examples_test.exs`)

Para cada exemplo: renderiza; **nenhum token `lu-*` em `class`**; ARIA/estrutura
(`ExampleChecks.a11y/1`: ids únicos, `aria-controls|labelledby|describedby` apontam para ids existentes, `role=tab` com `aria-selected`,
botão/link/imagem com nome); chamar `<.componente>` (fora `<.icon>`) tem de renderizar `data-part`.

### Comparação visual canvas × vitrine (`scripts/visual/`)

Cada seção da vitrine (NN-ésimo `.d-ex` de `/full/<id>`) é pareada com a demo do canvas de mesmo id/ordem (título da demo = título da
seção; ver `visual.mjs`). Nada de `lu-*` do lado da vitrine: os alvos de hover são pareados por tag + texto acessível + ocorrência.
Chromium headless liga `(hover: hover)` (sem isso nenhum `hover:` do Tailwind aplica).

```bash
export MIX_DEPS_PATH=<raiz>/deps ; cd showcase && MIX_DEPS_PATH=<raiz>/showcase/deps mix assets.build
PORT=<porta> mix phx.server &            # a SUA porta (ex.: 4223); o servidor de dev usa o CSS gerado em priv/static/assets/app.css
cd .. && ONLY=button,badge SHOW_URL=http://localhost:<porta> CANVAS_PORT=<porta+400> scripts/visual/run.sh /tmp/visual-<seu-lote>
# saída: /tmp/visual-<seu-lote>/out/report.html (piores primeiro, com canvas|vitrine|diff) e report.json (% por seção/tema/hover)
```

Variáveis: `ONLY=id1,id2` (rodar só estes; os resultados dos outros ids ficam), `THEMES=light,dark`, `THRESHOLD=0.6` e
`INK_THRESHOLD=15` (limites por seção), `STRICT=1` (exit 1 se alguma seção passar do limite, faltar exemplo ou tiver hover perdido),
`TEMPLATES=1` (inclui `/templates/*`). Para vários agentes em paralelo: **diretório de saída, `CANVAS_PORT` e porta do showcase
próprios** (o Chromium escolhe a porta de depuração sozinho; o perfil mora em `<saida>/out/`). `mix assets.build` de novo se mudar
utilitário nos componentes (`mix phx.server` em dev também roda o watcher do Tailwind).

Como ler: `max` = pior % de pixels diferentes sobre a caixa; `ink` = % sobre os pixels desenhados (mais duro em widget pequeno).
Validação (componentes idênticos): seções só com componentes dão **0,00 %** (button 4/7, card 1/3/4, input 1/5, badge 2); ruído de
antialias/1 px de linha-base fica em 0,05–0,5 % (ink ≤ 12 %); seção que ainda mistura marcação crua legada ou mock (`span.val`) passa de
1,5 % (ink ≥ 15 %). Por isso o alvo é 0,6 / 15; `size differs` no relatório = caixas de tamanho diferente (corrija primeiro).
Diferença que é decisão de design (não bug) vai documentada no relatório do lote, não em limite maior.

### Demos que são mock de animação

O canvas desenha `m-loop`/`mo-*` (cursor falso `lu-cur2`, ciclos de abrir/fechar) com marcação crua. No
exemplo use o `loop`/`demo="click"`/`highlight` do próprio componente (confira os `attr` do componente) (ou `animate-[nome_dur_easing_infinite]` quando o mock for só uma
animação decorativa) e **apague o cursor falso**: o componente já mostra o que o mock simulava. A comparação congela as animações
na mesma fase (todas voltam a 0 e recebem `animation-delay:-.5s`), então componente e mock caem no mesmo quadro. Se o canvas mostra o estado
aberto de um overlay, use o atributo de estado do componente (`open`, `demo=`), não JS.

## Ordem dos lotes

Ações → Formulários → Feedback → Overlays → Navegação → Dados → Métricas/gráficos → Shell/app → Templates.
Lotes em paralelo não podem repetir componente: use a tabela abaixo (uma linha = um dono).

## Arquivos compartilhados (não editar em paralelo)

`lib/ledger_ui/{components.ex,component.ex,helpers.ex,color.ex}`, `lib/ledger_ui.ex`, `mix.exs`, `assets/css/ledger_ui.css`
(gerado), `scripts/tw/*`, `parity/run.py`, `parity/cases.exs`, `parity/app.css`, `showcase/assets/css/app.css`, `showcase/mix.exs`,
`showcase/lib/**`, `showcase/test/support/**`, `components/icon.ex`, `form.ex`.
Precisa de mudança num deles? Peça ao coordenador (ou faça em um commit próprio, rebaseando antes).

Como adicionar sem conflito:
* **Casos de paridade**: um arquivo por lote (`parity/cases/<lote>.py` + `.exs`); `run.py` e `cases.exs` os descobrem sozinhos. Ids de caso
  prefixados pelo componente e sem repetição (o driver falha em ids repetidos).
* **Keyframe novo** ou token novo: vem do bundle/tokens da referência; peça regeneração do CSS (`tw_theme.py`), nunca edite à mão.
* Cor semântica nova: entrada em `LedgerUI.Color` (compartilhado).

## Interações a preservar nos lotes seguintes

Drawer/modal abrir e fechar; toasts; upload abrindo o seletor de arquivos e arrastar-e-soltar; treeview expandir/recolher com
marcação em cascata; flow com nós arrastáveis e "+" em cada card abrindo uma ramificação (Condição → Sim/Não); calendário; OTP; slider;
rating; olho da senha (`password-toggle`). Botão `loading` do showcase é alternado por JS legado (`.loading`): ao migrar os exemplos, use `loading={…}`.

## Notas do piloto

* `Card`: padrão `variant="tray"` (API do piloto). Superfícies antigas (`default`, `bordered`, `solid`, `gradient`…) seguem como variantes;
  `flat` é o painel sem bandeja. `body`/`divider`/`highlight` ficam reservados (sem estilo no design). Título: `title="…"` ou slot `<:title>`.
* `Input`: `class` vai para a caixa, `wrapper_class` para o campo; `prefix`/`suffix` são texto; `Form.field` é o quadro de rótulo/ajuda/erros
  de todo controle de formulário.
* `Badge`/`Button` aceitam `color="current"`/`"light"`/`"lime"` por `LedgerUI.Color` (a lib já os aceitava).
* Sem consenso do design: ícone dentro de `lu-bd` (o original não tem regra; adotado 13px como `lu-badge`).

## Base compartilhada (tokens, @property, utilitários novos)

Tudo vem de `scripts/tw/tw_theme.py` (nunca edite `assets/css/ledger_ui.css`):

* **Prefixo `--lu-`**: só os tokens de design (nomes do `tokens.json`, chaves das paletas, fontes) e as animadas `--lu-sp`/`--lu-stp`.
  Variáveis locais de componente (`--c`, `--c-on`, `--th`, `--tw`, `--t1`, `--n`, `--to`, `--o1`…) NÃO são renomeadas nos `@keyframes` copiados
  do bundle (antes viravam `--lu-c`, `--lu-lu-n`…), então o componente deve defini-las com o nome do bundle. Os `@keyframes` que as leem:
  `lu-cbbox`/`lu-rdbox`/`lu-swtrack*` (`--c`), `lu-swthumb*` (`--th`, `--tw`), `lu-aura-glow` (`--t1`), `lu-pct` (`--n`), `lu-numloop`/`lu-cntloop`/`mo-count`
  (`--lu-n`; `mo-count` lê `--to`). `lu-chipon` lê os tokens (`--lu-accent-600` etc.), não `--c`, como no original.
* **`@property`** (registradas, para interpolar nos `@keyframes`): `--lu-sp` e `--lu-stp` (`<percentage>`: slider/anel/progresso e status toast),
  `--lu-n` (`<integer>`: contadores), `--lu-p` (`<percentage>`), `--n`. O `--lu-a` do bundle (ângulo do aura) fica sem registro: o range usa
  `--lu-a` como porcentagem (início do par) e o aura gira por `transform`. Defina-as inline (`style="--lu-sp:40%"`) e anime com `animate-[lu-slloop_5s_…]`.
* **Gráficos**: `--lu-chart-2` e `--lu-chart-5` derivam de `--color-accent` (L e croma do Ledger, matiz do accent) e recoloram com o tema; as
  paletas continuam com os valores próprios. `chart-1` já era `accent-500`; `chart-3`/`chart-4` são âmbar/rosa fixos.
* **Hero**: `--lu-hero-sky1|sky2|sun|m1a|m1b|m2a|m2b|m3a|m3b|line` existem no tema (claro, escuro e crepúsculo), sem host `.lu-hero`.
  `Illustration.summit/1` (e `hero_card`/`auth_split`) pintam com `var(--lu-hero-*)`; dê tamanho com `class="size-full"`. Estrelas: `g[data-part=summit-stars]`.
  Os nomes curtos `sun`, `sun-c`, `st`, `m1…m3`, `ln` ficam nas formas como ganchos para animar (`[&_.m3]:animate-[lu-hero-drift_14s_…]`).
* **Estrelas do rating**: `--lu-star` (#e3a008) → `text-star`, `bg-star`, `fill-star`.
* **Aura**: `--lu-ai-1`/`--lu-ai-2` (tom `ai`: #0d8f91/#8a5cd6 claro, #2bbfbd/#a98bf0 escuro; a marca do assistente, não segue o accent) e
  `--lu-aura-2` (#8a5cd6, 2ª cor de `dual` nos demais tons). Não há token equivalente no `tokens.json` (`violet` e `assistant-*` têm outros valores).
* **`<.button canvas appearance="default|primary|ghost">`** (com `size="sm|md|lg"`, `icon`, `disabled`): o botão compacto do canvas. Hooks que criam o
  botão em JS pegam as classes com `Button.canvas_classes("sm", "ghost")`. `datetime_picker`, `signature_pad` e `text_editor` usam isso e `<.kbd>`:
  não copie classes de botão.
* **Modal `placement`**: `center` (padrão, pixels intactos), `top` e `bottom` (colado à borda com a margem de 12px dos drawers); vale também em `layout="page"`.
* **Form.field** renderiza `inner_block`, `below` e `aside` no lugar (slots nunca passam como atributo: perdem o change tracking); há um teste LiveView
  (`form_live_test.exs`). `Icon.svg_class(size)` devolve as classes do `<svg>` do ícone para hooks.
* **Vitrine**: `showcase/priv/static/assets/showcase.css` está na camada `showcase` (abaixo de `utilities`), então `a{color:inherit}` não vence `text-ink`.
  A ordem das camadas (`theme, base, showcase, components, utilities`) está em `showcase/assets/css/app.css` e no topo do `showcase.css`.

### Notas do CSS gerado (o legado já saiu)

* O CSS gerado (`tw_theme.py`, `properties()`) NÃO registra `--lu-a` (o ângulo do aura do legado colidia com o preenchimento do `range`, que usa `--lu-rlo`).
* `color-mix(…, transparent)` dentro de `@keyframes` é reescrito pelo Tailwind/lightningcss com um `@supports` ANINHADO no keyframe (inválido: o anel
  de `mo-glow` ficava sólido). `tw_theme.py` (`no_color_mix`) escreve esses casos como cor relativa `oklab(from X l a b / N%)`. Sobra só `lu-pxbd`
  (mistura de duas cores opacas): o Tailwind a reduz à 1ª cor.
* O preflight põe `small{font-size:80%}`; o canvas usa o do navegador (`smaller`). A camada `base` do CSS gerado repõe `small{font-size:smaller}`.

## Desvios aceitos

Casos que ficam fora do limite do runner por motivo conhecido (o runner não tem mecanismo de exceção; esta lista é o registro).

- `theme-picker-grid` falha em `--theme` (4,18%): a grade mostra as amostras fixas do tema "Ledger" (dado do seletor, `bg`/`accent`/`ink` de cada
  tema), não cor do componente. O resto do componente usa tokens.
- `theme_toggle` (casos `theme-switch-matrix`, `header-full`): mostra o sol no escuro (`dark:`), como a doc da lib original promete
  ("a moon in light mode, a sun in dark"). O original nunca mostrava o sol: o hook só trocava o atributo `data-icon` do `<svg>`, não o desenho
  (bug do original). Os casos aplicam ao lado ORIGINAL o `d` do sol no escuro para comparar o layout.
- Casos de `shell_b`: o lado ORIGINAL recebe CSS extra (3º elemento do caso, ver `parity/cases/shell_b.py`) onde o legado só renderiza "errado" fora do uso
  real: links do menu fora de uma `.lu-lnav` (azul/sublinhado do UA), `<button>` sem reset de padding (UA 1px 6px) avatar `t1` teal fixo
  na paleta crepúsculo escura e o sol do `theme_toggle` (acima).

## Tabela de componentes

Lote = quem migra. "API" é o módulo de função da lib (`PARIDADE.md`); vários componentes da referência podem ser do mesmo módulo
(migre-os juntos). Templates (`showcase/lib/**/templates`) formam o último lote, sem componente de referência.

| Lote | Componente da referência | API (`PARIDADE.md`) | Módulo da lib | Estado |
|---|---|---|---|---|
| 1 Ações | Palette | `palette` | `LedgerUI.Components.Palette` (`lib/ledger_ui/components/palette.ex`) |  |
| 1 Ações | ActionButton | `action_menu` | `LedgerUI.Components.ActionMenu` (`lib/ledger_ui/components/action_menu.ex`) |  |
| 1 Ações | Button | `button` | `LedgerUI.Components.Button` (`lib/ledger_ui/components/button.ex`) | piloto ✓ |
| 1 Ações | IconButton | `button` | `LedgerUI.Components.Button` (`lib/ledger_ui/components/button.ex`) | piloto ✓ |
| 1 Ações | Clipboard | `clipboard` | `LedgerUI.Components.Clipboard` (`lib/ledger_ui/components/clipboard.ex`) |  |
| 1 Ações | Divider | `divider` | `LedgerUI.Components.Divider` (`lib/ledger_ui/components/divider.ex`) |  |
| 1 Ações | Fab | `fab` | `LedgerUI.Components.Fab` (`lib/ledger_ui/components/fab.ex`) |  |
| 1 Ações | FabDial | `fab` | `LedgerUI.Components.Fab` (`lib/ledger_ui/components/fab.ex`) |  |
| 1 Ações | Icon | `icon` | `LedgerUI.Components.Icon` (`lib/ledger_ui/components/icon.ex`) | piloto ✓ |
| 1 Ações | Illustration | `illustration` | `LedgerUI.Components.Illustration` (`lib/ledger_ui/components/illustration.ex`) |  |
| 1 Ações | Kbd | `typography` | `LedgerUI.Components.Typography` (`lib/ledger_ui/components/typography.ex`) |  |
| 1 Ações | Typography | `typography` | `LedgerUI.Components.Typography` (`lib/ledger_ui/components/typography.ex`) |  |
| 2 Formulários | Autocomplete | `autocomplete` | `LedgerUI.Components.Autocomplete` (`lib/ledger_ui/components/autocomplete.ex`) |  |
| 2 Formulários | Calendar | `calendar` | `LedgerUI.Components.Calendar` (`lib/ledger_ui/components/calendar.ex`) |  |
| 2 Formulários | Checkbox | `checkbox` | `LedgerUI.Components.Checkbox` (`lib/ledger_ui/components/checkbox.ex`) |  |
| 2 Formulários | Chip | `chip` | `LedgerUI.Components.Chip` (`lib/ledger_ui/components/chip.ex`) |  |
| 2 Formulários | ColorPicker | `color_picker` | `LedgerUI.Components.ColorPicker` (`lib/ledger_ui/components/color_picker.ex`) |  |
| 2 Formulários | DatePicker | `date_picker` | `LedgerUI.Components.DatePicker` (`lib/ledger_ui/components/date_picker.ex`) |  |
| 2 Formulários | DateTimePicker | `datetime_picker` | `LedgerUI.Components.DatetimePicker` (`lib/ledger_ui/components/datetime_picker.ex`) |  |
| 2 Formulários | FilterMenu | `filter_menu` | `LedgerUI.Components.FilterMenu` (`lib/ledger_ui/components/filter_menu.ex`) |  |
| 2 Formulários | Field | `form` | `LedgerUI.Components.Form` (`lib/ledger_ui/components/form.ex`) | piloto ✓ |
| 2 Formulários | FormSection | `form_section` | `LedgerUI.Components.FormSection` (`lib/ledger_ui/components/form_section.ex`) |  |
| 2 Formulários | ImageInput | `image_input` | `LedgerUI.Components.ImageInput` (`lib/ledger_ui/components/image_input.ex`) |  |
| 2 Formulários | Input | `input` | `LedgerUI.Components.Input` (`lib/ledger_ui/components/input.ex`) | piloto ✓ |
| 2 Formulários | InputGroup | `input_group` | `LedgerUI.Components.InputGroup` (`lib/ledger_ui/components/input_group.ex`) |  |
| 2 Formulários | NumberStepper | `number_input` | `LedgerUI.Components.NumberInput` (`lib/ledger_ui/components/number_input.ex`) |  |
| 2 Formulários | OtpInput | `otp_input` | `LedgerUI.Components.OtpInput` (`lib/ledger_ui/components/otp_input.ex`) |  |
| 2 Formulários | PasswordInput | `password_input` | `LedgerUI.Components.PasswordInput` (`lib/ledger_ui/components/password_input.ex`) |  |
| 2 Formulários | PhoneInput | `phone_input` | `LedgerUI.Components.PhoneInput` (`lib/ledger_ui/components/phone_input.ex`) |  |
| 2 Formulários | PillSelect | `pill_select` | `LedgerUI.Components.PillSelect` (`lib/ledger_ui/components/pill_select.ex`) |  |
| 2 Formulários | Pillbox | `pillbox` | `LedgerUI.Components.Pillbox` (`lib/ledger_ui/components/pillbox.ex`) |  |
| 2 Formulários | RadioChoice | `radio` | `LedgerUI.Components.Radio` (`lib/ledger_ui/components/radio.ex`) |  |
| 2 Formulários | RangeSlider | `range` | `LedgerUI.Components.Range` (`lib/ledger_ui/components/range.ex`) |  |
| 2 Formulários | Rating | `rating` | `LedgerUI.Components.Rating` (`lib/ledger_ui/components/rating.ex`) |  |
| 2 Formulários | Segmented | `segmented` | `LedgerUI.Components.Segmented` (`lib/ledger_ui/components/segmented.ex`) |  |
| 2 Formulários | Select | `select` | `LedgerUI.Components.Select` (`lib/ledger_ui/components/select.ex`) |  |
| 2 Formulários | SignaturePad | `signature_pad` | `LedgerUI.Components.SignaturePad` (`lib/ledger_ui/components/signature_pad.ex`) |  |
| 2 Formulários | Switch | `switch` | `LedgerUI.Components.Switch` (`lib/ledger_ui/components/switch.ex`) |  |
| 2 Formulários | TagsInput | `tags_input` | `LedgerUI.Components.TagsInput` (`lib/ledger_ui/components/tags_input.ex`) |  |
| 2 Formulários | CommentEditor | `text_editor` | `LedgerUI.Components.TextEditor` (`lib/ledger_ui/components/text_editor.ex`) |  |
| 2 Formulários | RichTextEditor | `text_editor` | `LedgerUI.Components.TextEditor` (`lib/ledger_ui/components/text_editor.ex`) |  |
| 2 Formulários | Textarea | `textarea` | `LedgerUI.Components.Textarea` (`lib/ledger_ui/components/textarea.ex`) |  |
| 2 Formulários | TimePicker | `time_picker` | `LedgerUI.Components.TimePicker` (`lib/ledger_ui/components/time_picker.ex`) |  |
| 2 Formulários | Upload | `upload` | `LedgerUI.Components.Upload` (`lib/ledger_ui/components/upload.ex`) |  |
| 3 Feedback | Alert | `alert` | `LedgerUI.Components.Alert` (`lib/ledger_ui/components/alert.ex`) |  |
| 3 Feedback | Aura | `aura` | `LedgerUI.Components.Aura` (`lib/ledger_ui/components/aura.ex`) |  |
| 3 Feedback | ConnectionBanner | `connection_banner` | `LedgerUI.Components.ConnectionBanner` (`lib/ledger_ui/components/connection_banner.ex`) |  |
| 3 Feedback | EmptyStateCard | `empty_state` | `LedgerUI.Components.EmptyState` (`lib/ledger_ui/components/empty_state.ex`) |  |
| 3 Feedback | InlineEmpty | `empty_state` | `LedgerUI.Components.EmptyState` (`lib/ledger_ui/components/empty_state.ex`) |  |
| 3 Feedback | ErrorPage | `error_page` | `LedgerUI.Components.ErrorPage` (`lib/ledger_ui/components/error_page.ex`) |  |
| 3 Feedback | ProgressBar | `progress` | `LedgerUI.Components.Progress` (`lib/ledger_ui/components/progress.ex`) |  |
| 3 Feedback | Skeleton | `skeleton` | `LedgerUI.Components.Skeleton` (`lib/ledger_ui/components/skeleton.ex`) |  |
| 3 Feedback | Spinner | `spinner` | `LedgerUI.Components.Spinner` (`lib/ledger_ui/components/spinner.ex`) |  |
| 3 Feedback | StatusToast | `toast` | `LedgerUI.Components.Toast` (`lib/ledger_ui/components/toast.ex`) |  |
| 3 Feedback | ToastCard | `toast` | `LedgerUI.Components.Toast` (`lib/ledger_ui/components/toast.ex`) |  |
| 3 Feedback | Toaster | `toast` | `LedgerUI.Components.Toast` (`lib/ledger_ui/components/toast.ex`) |  |
| 4 Overlays | Accordion | `accordion` | `LedgerUI.Components.Accordion` (`lib/ledger_ui/components/accordion.ex`) |  |
| 4 Overlays | Collapse | `collapse` | `LedgerUI.Components.Collapse` (`lib/ledger_ui/components/collapse.ex`) |  |
| 4 Overlays | CommandPaletteDialog | `command_palette` | `LedgerUI.Components.CommandPalette` (`lib/ledger_ui/components/command_palette.ex`) |  |
| 4 Overlays | Drawer | `drawer` | `LedgerUI.Components.Drawer` (`lib/ledger_ui/components/drawer.ex`) |  |
| 4 Overlays | Sheet | `drawer` | `LedgerUI.Components.Drawer` (`lib/ledger_ui/components/drawer.ex`) |  |
| 4 Overlays | Modal | `modal` | `LedgerUI.Components.Modal` (`lib/ledger_ui/components/modal.ex`) |  |
| 4 Overlays | NotificationCenter | `notification_center` | `LedgerUI.Components.NotificationCenter` (`lib/ledger_ui/components/notification_center.ex`) |  |
| 4 Overlays | Popover | `popover` | `LedgerUI.Components.Popover` (`lib/ledger_ui/components/popover.ex`) |  |
| 4 Overlays | Tooltip | `tooltip` | `LedgerUI.Components.Tooltip` (`lib/ledger_ui/components/tooltip.ex`) |  |
| 5 Navegação | ActionMenu | `action_menu` | `LedgerUI.Components.ActionMenu` (`lib/ledger_ui/components/action_menu.ex`) |  |
| 5 Navegação | Breadcrumb | `breadcrumb` | `LedgerUI.Components.Breadcrumb` (`lib/ledger_ui/components/breadcrumb.ex`) |  |
| 5 Navegação | ContextMenu | `context_menu` | `LedgerUI.Components.ContextMenu` (`lib/ledger_ui/components/context_menu.ex`) |  |
| 5 Navegação | Dropdown | `dropdown` | `LedgerUI.Components.Dropdown` (`lib/ledger_ui/components/dropdown.ex`) |  |
| 5 Navegação | Menu | `menu_list` | `LedgerUI.Components.MenuList` (`lib/ledger_ui/components/menu_list.ex`) |  |
| 5 Navegação | MenuList | `menu_list` | `LedgerUI.Components.MenuList` (`lib/ledger_ui/components/menu_list.ex`) |  |
| 5 Navegação | Pagination | `pagination` | `LedgerUI.Components.Pagination` (`lib/ledger_ui/components/pagination.ex`) |  |
| 5 Navegação | Scrollspy | `scrollspy` | `LedgerUI.Components.Scrollspy` (`lib/ledger_ui/components/scrollspy.ex`) |  |
| 5 Navegação | Stepper | `steps` | `LedgerUI.Components.Steps` (`lib/ledger_ui/components/steps.ex`) |  |
| 5 Navegação | Tabs | `tabs` | `LedgerUI.Components.Tabs` (`lib/ledger_ui/components/tabs.ex`) |  |
| 5 Navegação | ViewSwitcher | `view_switcher` | `LedgerUI.Components.ViewSwitcher` (`lib/ledger_ui/components/view_switcher.ex`) |  |
| 6 Dados | Avatar | `avatar` | `LedgerUI.Components.Avatar` (`lib/ledger_ui/components/avatar.ex`) |  |
| 6 Dados | AvatarGroup | `avatar` | `LedgerUI.Components.Avatar` (`lib/ledger_ui/components/avatar.ex`) |  |
| 6 Dados | AvatarVariants | `avatar` | `LedgerUI.Components.Avatar` (`lib/ledger_ui/components/avatar.ex`) |  |
| 6 Dados | Badge | `badge` | `LedgerUI.Components.Badge` (`lib/ledger_ui/components/badge.ex`) | piloto ✓ |
| 6 Dados | BulkBar | `bulk_bar` | `LedgerUI.Components.BulkBar` (`lib/ledger_ui/components/bulk_bar.ex`) |  |
| 6 Dados | SelectionBar | `bulk_bar` | `LedgerUI.Components.BulkBar` (`lib/ledger_ui/components/bulk_bar.ex`) |  |
| 6 Dados | DueCalendar | `calendar` | `LedgerUI.Components.Calendar` (`lib/ledger_ui/components/calendar.ex`) |  |
| 6 Dados | Card | `card` | `LedgerUI.Components.Card` (`lib/ledger_ui/components/card.ex`) | piloto ✓ |
| 6 Dados | CardTable | `card_table` | `LedgerUI.Components.CardTable` (`lib/ledger_ui/components/card_table.ex`) |  |
| 6 Dados | Carousel | `carousel` | `LedgerUI.Components.Carousel` (`lib/ledger_ui/components/carousel.ex`) |  |
| 6 Dados | CashTimer | `cash_timer` | `LedgerUI.Components.CashTimer` (`lib/ledger_ui/components/cash_timer.ex`) |  |
| 6 Dados | Cover | `cover` | `LedgerUI.Components.Cover` (`lib/ledger_ui/components/cover.ex`) |  |
| 6 Dados | CoverCard | `cover` | `LedgerUI.Components.Cover` (`lib/ledger_ui/components/cover.ex`) |  |
| 6 Dados | DataTable | `data_table` | `LedgerUI.Components.DataTable` (`lib/ledger_ui/components/data_table.ex`) |  |
| 6 Dados | TableToolbar | `data_table` | `LedgerUI.Components.DataTable` (`lib/ledger_ui/components/data_table.ex`) |  |
| 6 Dados | DescriptionList | `description_list` | `LedgerUI.Components.DescriptionList` (`lib/ledger_ui/components/description_list.ex`) |  |
| 6 Dados | Flow | `flow` | `LedgerUI.Components.Flow` (`lib/ledger_ui/components/flow.ex`) |  |
| 6 Dados | HeroCard | `hero_card` | `LedgerUI.Components.HeroCard` (`lib/ledger_ui/components/hero_card.ex`) |  |
| 6 Dados | Kanban | `kanban` | `LedgerUI.Components.Kanban` (`lib/ledger_ui/components/kanban.ex`) |  |
| 6 Dados | Mask | `mask` | `LedgerUI.Components.Mask` (`lib/ledger_ui/components/mask.ex`) |  |
| 6 Dados | MiniCard | `mini_card` | `LedgerUI.Components.MiniCard` (`lib/ledger_ui/components/mini_card.ex`) |  |
| 6 Dados | PixelCard | `pixel_card` | `LedgerUI.Components.PixelCard` (`lib/ledger_ui/components/pixel_card.ex`) |  |
| 6 Dados | StepGroup | `step_group` | `LedgerUI.Components.StepGroup` (`lib/ledger_ui/components/step_group.ex`) |  |
| 6 Dados | Table | `table` | `LedgerUI.Components.Table` (`lib/ledger_ui/components/table.ex`) |  |
| 6 Dados | Tag | `tag` | `LedgerUI.Components.Tag` (`lib/ledger_ui/components/tag.ex`) |  |
| 6 Dados | Timeline | `timeline` | `LedgerUI.Components.Timeline` (`lib/ledger_ui/components/timeline.ex`) |  |
| 6 Dados | Timer | `timer` | `LedgerUI.Components.Timer` (`lib/ledger_ui/components/timer.ex`) |  |
| 6 Dados | Treeview | `treeview` | `LedgerUI.Components.Treeview` (`lib/ledger_ui/components/treeview.ex`) |  |
| 7 Métricas/gráficos | BarChart | `chart` | `LedgerUI.Components.Chart` (`lib/ledger_ui/components/chart.ex`) |  |
| 7 Métricas/gráficos | CohortHeatmap | `chart` | `LedgerUI.Components.Chart` (`lib/ledger_ui/components/chart.ex`) |  |
| 7 Métricas/gráficos | DonutChart | `chart` | `LedgerUI.Components.Chart` (`lib/ledger_ui/components/chart.ex`) |  |
| 7 Métricas/gráficos | LineChart | `chart` | `LedgerUI.Components.Chart` (`lib/ledger_ui/components/chart.ex`) |  |
| 7 Métricas/gráficos | WaterfallChart | `chart` | `LedgerUI.Components.Chart` (`lib/ledger_ui/components/chart.ex`) |  |
| 7 Métricas/gráficos | KpiCard | `kpi_card` | `LedgerUI.Components.KpiCard` (`lib/ledger_ui/components/kpi_card.ex`) |  |
| 7 Métricas/gráficos | Sparkline | `sparkline` | `LedgerUI.Components.Sparkline` (`lib/ledger_ui/components/sparkline.ex`) |  |
| 7 Métricas/gráficos | Stat | `stat` | `LedgerUI.Components.Stat` (`lib/ledger_ui/components/stat.ex`) | piloto ✓ |
| 8 Shell/app | AiChat | `ai` | `LedgerUI.Components.Ai` (`lib/ledger_ui/components/ai.ex`) |  |
| 8 Shell/app | AiComposer | `ai` | `LedgerUI.Components.Ai` (`lib/ledger_ui/components/ai.ex`) |  |
| 8 Shell/app | AiInsights | `ai` | `LedgerUI.Components.Ai` (`lib/ledger_ui/components/ai.ex`) |  |
| 8 Shell/app | AiMessage | `ai` | `LedgerUI.Components.Ai` (`lib/ledger_ui/components/ai.ex`) |  |
| 8 Shell/app | AiPromo | `ai` | `LedgerUI.Components.Ai` (`lib/ledger_ui/components/ai.ex`) |  |
| 8 Shell/app | AiProposal | `ai` | `LedgerUI.Components.Ai` (`lib/ledger_ui/components/ai.ex`) |  |
| 8 Shell/app | AiToolTrace | `ai` | `LedgerUI.Components.Ai` (`lib/ledger_ui/components/ai.ex`) |  |
| 8 Shell/app | ConversationList | `ai` | `LedgerUI.Components.Ai` (`lib/ledger_ui/components/ai.ex`) |  |
| 8 Shell/app | PromptSuggestions | `ai` | `LedgerUI.Components.Ai` (`lib/ledger_ui/components/ai.ex`) |  |
| 8 Shell/app | IconRail | `app_shell` | `LedgerUI.Components.AppShell` (`lib/ledger_ui/components/app_shell.ex`) |  |
| 8 Shell/app | PageHeader | `app_shell` | `LedgerUI.Components.AppShell` (`lib/ledger_ui/components/app_shell.ex`) |  |
| 8 Shell/app | ShellFloating | `app_shell` | `LedgerUI.Components.AppShell` (`lib/ledger_ui/components/app_shell.ex`) |  |
| 8 Shell/app | SubNav | `app_shell` | `LedgerUI.Components.AppShell` (`lib/ledger_ui/components/app_shell.ex`) |  |
| 8 Shell/app | AuthSplit | `auth_split` | `LedgerUI.Components.AuthSplit` (`lib/ledger_ui/components/auth_split.ex`) |  |
| 8 Shell/app | CodeBlock | `code_block` | `LedgerUI.Components.CodeBlock` (`lib/ledger_ui/components/code_block.ex`) |  |
| 8 Shell/app | Container | `container` | `LedgerUI.Components.Container` (`lib/ledger_ui/components/container.ex`) |  |
| 8 Shell/app | EmailLayout | `email` | `LedgerUI.Components.Email` (`lib/ledger_ui/components/email.ex`) |  |
| 8 Shell/app | GlowText | `glow_text` | `LedgerUI.Components.GlowText` (`lib/ledger_ui/components/glow_text.ex`) |  |
| 8 Shell/app | LandingNav | `landing_nav` | `LedgerUI.Components.LandingNav` (`lib/ledger_ui/components/landing_nav.ex`) |  |
| 8 Shell/app | Logo | `logo` | `LedgerUI.Components.Logo` (`lib/ledger_ui/components/logo.ex`) |  |
| 8 Shell/app | Navbar | `navbar` | `LedgerUI.Components.Navbar` (`lib/ledger_ui/components/navbar.ex`) |  |
| 8 Shell/app | ScrollArea | `scroll_area` | `LedgerUI.Components.ScrollArea` (`lib/ledger_ui/components/scroll_area.ex`) |  |
| 8 Shell/app | Shell | `shell` | `LedgerUI.Components.Shell` (`lib/ledger_ui/components/shell.ex`) |  |
| 8 Shell/app | Sidebar | `sidebar` | `LedgerUI.Components.Sidebar` (`lib/ledger_ui/components/sidebar.ex`) |  |
| 8 Shell/app | Sticky | `sticky` | `LedgerUI.Components.Sticky` (`lib/ledger_ui/components/sticky.ex`) |  |
| 8 Shell/app | ThemePicker | `theme_picker` | `LedgerUI.Components.ThemePicker` (`lib/ledger_ui/components/theme_picker.ex`) |  |
| 8 Shell/app | ThemeSwitch | `theme_switch` | `LedgerUI.Components.ThemeSwitch` (`lib/ledger_ui/components/theme_switch.ex`) |  |
| 8 Shell/app | Tool | `tool` | `LedgerUI.Components.Tool` (`lib/ledger_ui/components/tool.ex`) |  |
| 8 Shell/app | Trace | `trace` | `LedgerUI.Components.Trace` (`lib/ledger_ui/components/trace.ex`) |  |
