# Changelog

## Não lançado

### Desempenho

Diffs de atualização sem as classes e os ícones que não mudaram (#85). Medido com `Phoenix.LiveView.Diff.render/4`, sem compressão; o HTML renderizado é o mesmo byte a byte (2 562 chamadas comparadas antes e depois no primeiro lote, em `button`, `badge`, `input`, `select`, `autocomplete`, `modal` e nos componentes que tinham `{assigns}`; mais 5 665 no segundo lote, nos campos de formulário).

- **`LedgerUI.Helpers.settle/3`:** um valor derivado no corpo do componente (`assign(:cls, ...)`) era chave nova a cada chamada, então o LiveView reenviava a string de classes sempre que o componente era chamado de novo (por exemplo, quando só o slot mudava). `settle(assigns, changed0, cls: [:variant, :size, ...])` tira o derivado de `__changed__` quando nenhuma das fontes mudou. Primeiro lote: `button` (e `insight_button`), `badge`, `count`, `delta`, `input`, `Form.field` e as linhas de ajuda/erro, `select` (nativo e lista), `listbox`, `autocomplete`, `modal`.
- **Campos de formulário (segundo lote):** `settle/3` em `checkbox`, `switch`, `textarea`, `radio_group` (e `radio`), `segmented`, `number_input`, `pillbox`, `tags_input`, `phone_input`, `otp_input`, `password_input`, `date_picker` e `date_time_picker` (só `id`, `state` e o que não lê locale nem a data de hoje), e nas funções que preenchem `id`/`name`/`value`/`errors` a partir de `field` (`Form.lu_assign_field/1`, `Select.Options.resolve/3` e `resolve_field/1`). Texto, rótulo ou digitação não reenviam mais as classes da caixa, do controle e dos botões. Os textos que dependem do locale do processo (`config`/`text` do `number_input`, contador do `textarea`, lista de países do `phone_input`) só entram no `settle` quando o `locale` é passado como attr.
- **Sem `{assigns}` repassado:** as 27 chamadas `<.parte {assigns} />` (a busca por `{assigns}` achava 29: 2 eram comentários) a componentes privados (`button`, `insight_button`, `input`, `checkbox_group`, `color_picker`, `donut_chart`, `kpi_card`, `data_table`, `number_input`, `rating`, `range`, `toast_card`) passam só os assigns que usam. Repassar todos desligava o rastreamento: o SVG do ícone voltava junto com o texto do botão.
- **`:key` nas listas de opções** de `select` e `autocomplete` (chave repetida não quebra: a segunda ocorrência ganha o número). No `autocomplete` a classe de cada opção é literal no template (igual a `Options.item_class/0`, com teste), então não vai mais uma vez por opção.

| Cenário | Antes | Depois |
|---|---:|---:|
| Botão com ícone, troca do texto | 2 180 B | 45 B |
| Badge, troca do texto | 333 B | 27 B |
| Modal, troca do texto do corpo | 1 567 B | 38 B |
| Autocomplete, servidor devolve 20 opções | 10 164 B | 4 110 B |
| Formulário de 8 campos, 1 tecla | 1 008 B | 746 B |
| Formulário de 8 campos, 1 erro de validação | 13 269 B | 6 467 B |
| Formulário de 7 campos (checkbox, switch, textarea, radio_group, number_input, date_picker, tags_input), 1 tecla no textarea | 925 B | 645 B |
| Formulário de 7 campos, 1 erro de validação | 13 353 B | 8 134 B |

Nos campos ligados a `field={@form[:x]}` as classes que dependem do estado de erro continuam indo quando `field` muda (o LiveView não informa se os erros mudaram). Falta aplicar o `settle/3` aos módulos que não são de formulário (`table`, `card_table`, `data_table`, `toast`... ), que seguem como antes.

## 0.11.0 — 2026-11-27

### Tema

- **`color-scheme` por modo:** `light` em `:root` e `[data-theme="light"]`, `dark` em `[data-theme="dark"]` (um `light` aninhado em `dark` volta a `light`). Barra de rolagem, `<select>` nativo, `<input type="date">` e autofill acompanham o modo sem CSS do app.
- **Regra de `body` opcional:** a camada `base` continua pintando o `body`, mas com `<body data-lu-base="off">` ele não recebe nenhuma das propriedades. A mesma regra vale para `[data-ui="ledger"]` (tipo, cor, fundo e `font-feature-settings`). Os seletores usam `:where()` (especificidade zero).

### Formulários

- **Tradutor de erros configurável:** `config :ledger_ui, :error_translator, {Módulo, :função}` faz os campos mostrarem o erro do changeset traduzido (a função recebe `{msg, opts}`, como o `translate_error/1` do Phoenix). Vale para todo componente com `field` (`input`, `select`, `autocomplete`, `date_picker`, `date_time_picker`, `checkbox`, `switch`, `textarea`, `number_input`, `radio_group`, `pillbox`, `segmented`...). Sem a config a saída é a mesma de antes, e as strings passadas à mão em `errors={[...]}` não passam pelo tradutor. Dispensa os wrappers de campo no app.
- **`date_picker`/`date_time_picker` com `start_field`/`end_field`:** passam a mostrar os erros dos dois campos (antes eram descartados).

### Tabela

- **`wrap` na célula da API composta:** o `:cell` de `table_row` e de `table_foot`, `table_cell`, `table_detail_row` e `table_empty` aceitam `wrap` (`"never"` padrão, `"auto"`, `"truncate"`), o mesmo vocabulário do `:col`. `wrap="auto"` não renderiza `whitespace-nowrap`, então não precisa mais de `whitespace-normal!`.
- **`padded` na célula:** `padded={false}` no `:cell` de `table_row` e de `table_foot` e em `table_cell` tira o padding horizontal e o vertical (linha de detalhe de ponta a ponta).
- **Sem os attrs novos o HTML é o mesmo de antes.** O padrão do `table_empty` e do `table_detail_row` continua `"never"`; `wrap="auto"` é opt-in.

### `kpi_card` e `sparkline`

Pontos de extensão para o app deixar de redesenhar o card de KPI; exceto pelo `flex-wrap` do rodapé padrão, sem os attrs novos o HTML é o mesmo.

- **`<:label_extra>`:** conteúdo no fim da linha do rótulo (`ml-auto`).
- **`value_tone`** (`nil | "warning" | "error"`): pinta só o número; prefixo e unidade continuam `subtle`.
- **`footer_layout`** (`"row"` padrão | `"stack"`): `stack` põe o rodapé em coluna, alinhado à esquerda. O `row` agora quebra linha (`flex-wrap`), o que muda o HTML do rodapé padrão.
- **`spark_variant`** (`"backdrop"` padrão | `"corner"`): `corner` é a sparkline de 96×30 no canto de baixo à direita, sem o ponto final.
- **`arrow`** (padrão `true`): `false` tira a seta ao lado do número.
- **`sparkline`:** `dot={false}` não desenha o ponto final e `variant="corner"` é a forma de canto.

### Pagination

- **`shape="compact"`:** seta anterior, `<página> / <total>` em mono e seta seguinte (`‹ 1 / 8.775 ›`), sem números de página. Com uma página, as duas setas ficam desabilitadas (`aria-disabled`) e aparece `1 / 1`; `aria-current="page"` fica no texto da página.
- **Milhar pelo locale:** os números do resumo e da forma compacta usam `.` em `pt_BR` e `,` em `en` (`105.299` / `105,299`). Antes saía `105299`.
- **Resumo traduzido:** chave `pagination.summary` nos dois locales. Sem `summary`, em `pt_BR`: "Mostrando 1–15 de 128". O prefixo do app (`1 selecionado ·`) vai no template do `summary`.
- **`page_size_at`:** `"end"` (padrão, depois das páginas), `"summary"` (ao lado do resumo) ou `"before"` (antes das páginas).
- **Ids do seletor:** com `id`, o form do seletor é `"<id>-size-form"` e o select `"<id>-page-size"`.
- **HTML padrão:** sem os attrs novos muda só o milhar nos números a partir de 1.000 e, com `id`, os ids do form e do select.

### Descrição

- **`description_list divider`:** `"all"` (padrão, o HTML de sempre), `"between"` (o último item de cada coluna fica sem traço e sem `padding-bottom`) ou `"none"` (sem traços), no `layout="inline"`.
  - **Respiro simétrico:** com `"between"` ou `"none"` cada item leva `py-2.5`, a primeira linha sem `pt`, a última sem `pb` e a raiz `gap-y-0`; o app não precisa mais de `divide-y` nem de seletores filhos sobre a estrutura interna.
  - **Colunas:** o último item de cada coluna é calculado no servidor a partir do número de itens e de `cols`.

### Correções

Três regressões visuais em relação à referência original da suíte de paridade (#76):

- **`checkbox`/`radio` desabilitados:** a caixa nativa deixa de ter `opacity-50`; o desabilitado é só `bg-sunken` + `border-line` (o texto continua `text-muted`), como no original. `choice` `card`/`chip`/`tile` não mudam.
- **`hero_card`:** o eyebrow volta a ser mono, 11,5px, `uppercase` e com `tracking-[.09em]` (era sans 12,5px sem caixa-alta).
- **`tool variant="panel"`:** o ícone volta a ser o quadrado de 32px com ícone de 16px (era `icon boxed` de 40px); o painel perde até 8px de altura. `tool_approval` e o `icon boxed` não mudam.
- **`alert` com `title`/`description` (#84):** o inner block passa a ser renderizado dentro da coluna de texto, abaixo do título e da descrição e na largura toda, com o mesmo tom quieto da descrição nas variantes tingidas (antes virava uma coluna ao lado e espremia o título, uma palavra por linha). Texto longo, lista e botões vão para baixo do título. Sem `title`/`description`, ou com os dois e sem inner block, o HTML é o mesmo de antes; as ações continuam no `:action`, à direita.

- **`autocomplete`, `select` (inclusive `multiple`/busca) e `tags_input` dentro de `modal`, `drawer` e `sheet`** (#83): o painel abria deslocado e criava rolagem horizontal, porque `position: fixed` sob um ancestral com `transform` conta a partir do ancestral, não da viewport. Os hooks agora põem o painel no top layer (`popover="manual"` definido pelo hook, `showPopover()`/`hidePopover()`), como o `dropdown`; o cálculo de `left`/`top`/`maxHeight`/largura é o mesmo e o HTML do servidor não muda. Fora de overlay o comportamento é o mesmo. O `context_menu` já usava o top layer.

## 0.10.0 — 2026-11-26

### Novos componentes

- **`page_trail`** (`LedgerUI.Components.PageTrail`, `LedgerUI.PageTrail`): as abas de tela da navbar, com as fixadas primeiro e as recentes depois.
  - **URL completa:** cada aba guarda a última URL completa da tela, então os filtros que estão na URL voltam pelo `handle_params` da própria tela (uma fixada também abre no último estado).
  - **Estado e scroll:** `put_state/2` guarda um snapshot opcional por tela (devolvido pelo callback `page_trail_restore/2`) e a posição do scroll é salva e restaurada por tela.
  - **Trilha no navegador, validada no servidor:** a trilha vive em `localStorage` e o `on_mount {LedgerUI.PageTrail, :default}` valida cada item contra o router (caminho relativo que case com uma rota, rótulo e listas com limite).
  - **Preferências do usuário:** `on_change` entrega a trilha ao app e `put_trail/2` a semeia das preferências (a cópia do navegador passa a ser ignorada); `sanitize/2` valida o que vem de fora.
  - **Parâmetro de conexão:** `params: () => ({lu_trail: localStorage.getItem("lu:trail")})` no `LiveSocket` evita o piscar na navegação entre LiveViews.
  - **Botão de fixar:** o botão de fixar/desafixar de cada item reserva o seu espaço (sem deslocar os itens ao passar o mouse) e aparece no hover, no foco e em telas de toque.
- **`navbar_cluster`:** agrupa os itens da direita da navbar (busca, idioma, tela cheia, tema, sino, usuário) num único bloco, com `shape` (arredondado ou `pill`) e `size` (`sm`).

### Navbar

- **`navbar_search icon_only`:** só o ícone de busca, como botão da barra (o `placeholder` vira o `aria-label`); é a forma compacta do `navbar_cluster`.
- **`lu:fullscreen`:** o JS do kit passa a ouvir o evento `lu:fullscreen` (`JS.dispatch("lu:fullscreen")` num `phx-click`) e alterna a tela cheia do navegador.

## 0.9.0 — 2026-11-23

### Visual (refino)

O visual padrão do kit mudou. Não há atributo para voltar ao antigo; as opções que já existiam continuam aceitas.

- **Tokens:**
  - **Claro:** shell `#fafaf9`, tray `#f6f6f4`, line `#ebebe8`, line-strong `#dcdcd7`, muted `#5e615c`.
  - **Marca:** accent `#0b8572` (500 `#0fa08a`), accent-ink `#0a7a69` (`--color-accent-content` passa a ser uma entrada própria do tema) e accent-soft `#e8f8f4`.
  - **Escuro:** equivalentes com bordas um pouco mais suaves e muted `#a3a9a6`.
  - **Anel de foco:** 3px na cor nova do accent.
- **Raios:** md 8px, lg 12px, xl 16px, 2xl 24px (antes 10, 14, 20 e 28).
- **Sombras:**
  - `shadow-xs` virou uma linha fina (hairline).
  - Novo `shadow-popover` (`0 0 1px #0006, 0 8px 24px #00000014`, com equivalente escuro), usado em popover, dropdown, menus, `command_palette`, `notification_center`, `select`, `date_picker` e `color_picker`.
- **Card:**
  - **Superfície:** uma só, sem bandeja em volta: `rounded-lg`, borda line, `shadow-xs`. O cabeçalho tem linha embaixo e o corpo não tem borda.
  - **Tabela no corpo:** encosta no card, com corpo `p-0` e cantos cortados pelo card.
  - **Outros componentes:** `card_table`, `data_table`, `kpi_card`, `stat`, `mini_card` e `hero_card` seguem a mesma superfície.
  - **Variantes:** as que dependiam da bandeja (`tray`, `inset`, `flush`) passam a ter esse visual.
- **Títulos sem caixa-alta:**
  - Títulos de card, rótulos de KPI e `th` de tabela perderam a caixa-alta e o espaçamento largo.
  - O `th` tem 12.5px e é muted.
  - O valor de KPI tem 32px em todas as variantes, e a sparkline tem opacidade .55.
- **Ícones:**
  - Traço 1.75 e cor ink: os ícones de interface deixaram de ser cinza (muted ou subtle).
  - `<.icon boxed>` (moldura de ícone): 40×40, raio 8, fundo panel, borda line, ícone de 20px.
- **Controles:**
  - **Tamanho:** `button`, `input`, `select` e os demais campos têm sm 32, md 36 e lg 40 (antes 38 e 44), raio 8 e nenhuma sombra.
  - **Checkbox:** raio 4px, preenchido com o accent quando marcado. A cor padrão passou de `neutral` para `primary`.
  - **Anel de foco:** checkbox, radio, switch e range também ganharam o anel de 3px.
- **Chips de campo concêntricos:**
  - Em `tags_input`, `select multiple`/`pillbox` e `pill_select`, o chip acompanha o formato do campo.
  - Campo arredondado → chip `rounded-[5px]` (7px no `lg`); campo `shape="pill"` → chip `rounded-full`.
  - `tags_input`, `pillbox`, `pill_select`, `chip` e `tabs` ganharam o atributo `shape`.
- **Pílula só como opção:** o padrão é arredondado e `shape="pill"` vira pílula. Mudaram a paginação (setas), `chip`, `tabs` (variante `pill`) e `tag`.

## 0.8.5 — 2026-11-23

### Novidades

- **Seleção otimista** no `card_table`/`table` com `<.bulk_bar for="id-da-tabela">` (#73).
  - **No clique, sem esperar o servidor:** o checkbox, a linha (`aria-selected` e o destaque), o checkbox "todos" (marcado ou indeterminado) e a contagem da `bulk_bar` mudam na hora.
  - **O servidor continua sendo a verdade:** `on_select`/`on_select_all` saem com os mesmos payloads, e o patch dele prevalece (ids fora da página, seleção recusada). Se ele confirma o que já está na tela, nada pisca.
  - **Atributos novos:** a tabela publica o evento DOM `lu:selection` (`{id, count, delta, ids}`). Com seleção, cada `<tr>` ganha `aria-selected`.
  - **Com `for`:** a `bulk_bar` fica sempre no DOM, escondida quando a contagem é 0. Sem `for`, nada muda.
- **Cache de buscas** no `autocomplete` e no `select`/`pillbox` com `on_search` (#75).
  - **Texto já buscado:** as opções aparecem na hora, sem "Buscando…", e a busca ainda vai ao servidor para atualizar a lista.
  - **Texto que estende o anterior** ("barb" → "barbara"): o navegador filtra o que já está na tela enquanto a resposta não chega.
  - **Tamanho:** guarda as últimas 20 respostas por campo.
  - **Opt-out:** `cache={false}`.
- **Carregando automático** (#74).
  - **Onde:** `<.button>` com `phx-click` ou `type="submit"`, os itens de `<.dropdown>` com `phx-click` e as ações da `<.bulk_bar>`.
  - **Como:** usa as classes `phx-click-loading`/`phx-submit-loading` do LiveView, com spinner no estilo do kit, sem clique e sem mudar a largura. Não precisa de `phx-disable-with`.
  - **Opt-out:** `auto_loading={false}`.
- **Esqueletos** (#74): `<.card loading loading_rows={3}>` troca o corpo por linhas de esqueleto. `<.skeleton variant="table" rows={5} cols={4}>` serve para listas, com `<.async_result>`.

### Correções

- **Hooks** (#74): a espera termina sempre pela resposta do servidor (callback do push, e só a resposta mais recente vale), nunca só por um patch do DOM.
  - **`autocomplete`:** um patch de uma resposta antiga não encerra mais o "Buscando…" de uma busca nova.
  - **`select`:** o "carregar mais" não fica mais travado quando o servidor responde `{:noreply, socket}` sem mudar nada.
  - **Demais hooks:** foram revisados e não tinham estado de espera.

## 0.8.4 — 2026-11-23

### Correções

- `autocomplete` com `on_search` (#72): o "Buscando…" agora some quando o servidor responde à busca, mesmo que a resposta traga as mesmas opções (buscar o cliente já escolhido, "barb" e depois "barbara") ou que a busca falhe. Só a resposta da busca mais recente encerra o carregamento. O `pillbox` não tinha esse estado e não mudou.

### Desempenho

- `card_table` (#70): marcar ou desmarcar linhas reenvia só o checkbox "todos" do cabeçalho, o selo/tira de seleção e as linhas reinseridas pelo app. Cabeçalho, toolbar, classes e estrutura da tabela e do card não vão mais no diff. Numa tabela de 25 linhas o patch de um clique caiu de 8,3 KB para 5,4 KB na medição do kit. O `<.table>` direto ganha o mesmo ganho quando só `selected`/`all_selected`/`rows` mudam. Sem mudança de API.

### Novidades

- Ícone `pin-off` (#71): `<.icon name="huge-pin-off" />` (alfinete cortado, Hugeicons Stroke Rounded), para "desafixar". O dicionário embutido passa a 142 ícones.

## 0.8.3 — 2026-11-23

### Correções

- `pillbox` (e `select multiple`) (#69): com tags selecionadas, a seta fica sempre na ponta direita do campo; antes ia para logo depois da última tag. Com o botão de limpar, ele e a seta ficam juntos na ponta. Sem tags, nada muda.

### Novidades

- `<.button variant="link">` e `<.button canvas appearance="link">` (#69): texto em accent (ou na cor de `color`), sem fundo, borda nem sombra, sublinhado no hover e anel de foco mantido. Funciona em `xs`, `sm` e `md`.

### Observação

- O "+N" do `pillbox` já trazia no `title` os nomes das tags escondidas e um `aria-label` ("4 ocultos"), atualizados pelo hook a cada recálculo. A 0.8.3 ganhou um exemplo e um teste disso.

## 0.8.2 — 2026-11-23

### Correções

- `line_chart` (#68): a faixa de incerteza não sai mais do gráfico. O eixo Y passa a considerar o `band.lower` e o `band.upper` de cada série (ignorando `nil`). Um `min`/`max` explícito continua valendo.
- `chart type="bar"` (#67):
  - **Margem do eixo Y:** acompanha o maior rótulo formatado (mínimo de 46px, ou 70px na horizontal), e rótulos como "R$ 14,3 mi" deixam de sair cortados. A nova opção `yaxis: %{width: px}` fixa a margem.
  - **Legenda:** ganha espaço próprio no topo e não fica mais por cima do primeiro rótulo do eixo nem da primeira linha de grade. Gráficos que já tinham legenda ficam 12px mais baixos.
  - **Série real na legenda:** com `legend.projection`, `legend.error` ou `legend: %{show: "always"}`, a série real aparece primeiro, com o nome dela, mesmo quando há uma só. Depois vêm a projeção e a faixa.

## 0.8.1 — 2026-11-23

### Correções

- `bulk_bar` em pílula (`inverse`, `soft`, `solid`) (#66): o botão dentro do `:field` (por exemplo o toggle "Mover para" de um `dropdown`) sumia no tema escuro e só aparecia no hover. Agora ele sai ghost (sem borda, fundo ou sombra) na cor do texto da pílula, com o hover translúcido, nos dois temas. Um menu aberto (`role=menuitem`) mantém as cores do painel.

### Novidades

- `bulk_bar offset="auto"` (#65): centraliza a pílula flutuante na área principal do `shell` só com CSS, em `left: calc(50% + (var(--lu-sidebar-w) - var(--lu-aside-w)) / 2)`. Fora de um shell, fica no centro da tela. `offset` inteiro (px) funciona como antes.
- `shell` (#65) expõe `--lu-sidebar-w`, a largura atual do menu lateral, que acompanha o recolhimento feito pelo hook e o `data-collapsed` da sidebar.
  - **Padrões, aberto/fechado:** `sidebar` e `framed` 248px/60px; `sideblock` 260px/0; `minimal` 60px; `horizontal` 0.
  - **Larguras próprias do app:** `--lu-sidebar-open-w`, `--lu-sidebar-closed-w` e `--lu-sidebar-collapsed-w`.
  - **Painel lateral fixo (ex.: Assistente):** o app informa a largura em `--lu-aside-w` no shell, por exemplo `style="--lu-aside-w:360px"`. O `:aside` do kit é sobreposto e não desloca o conteúdo, por isso o kit não define essa variável.
- `line_chart` (#64):
  - **Legenda:** `legend` aceita `:auto` (padrão: como antes), `:always` (mostra a legenda mesmo com uma série) e `:never`. Também aceita as strings equivalentes; `true` equivale a `:auto` e `false` a `:never`.
  - **Nota:** `legend_note` é um texto livre em muted depois dos itens ("Sem projeção · histórico de 7 meses") e já faz a legenda aparecer no modo `:auto`.

## 0.8.0 — 2026-11-23

Pranchas "Relatórios pelo Assistente" e np-bulkf do Nexus Pro (#53 a #63). Tudo é opt-in: sem os atributos novos o HTML é o de antes, com as exceções listadas em "Mudanças de comportamento".

### Novidades

- `line_chart` (#55, #63):
  - **Faixa de incerteza:** `band: %{lower: [..], upper: [..]}` na série (`nil` fora da faixa). Fica atrás das linhas, com `band_opacity` (`.13`), `band_label` (padrão "Faixa de incerteza"), item na legenda e linha "lo – hi" no tooltip (`kind: "band"` ou `"band:<cor>"`).
  - **Linha "hoje":** `split: %{at: i, before:, after:}`, tracejada entre os pontos `i` e `i + 1`, com "realizado" e "projeção" de cada lado.
  - **Área na cor da série:** `area: %{opacity: n}` (padrão `.16`); `area: true` continua com o gradiente do acento.
  - **Projeção tracejada como na prancha:** `dash_style: "report"` com `dashed: true` (2px, `5 5`, traço da legenda e ponto do hover na cor da série).
  - **Cabeçalho:** `head_size="md"` (24/30) e slot `:sub_content` (texto rico depois do `sub`).
  - **Eixo Y:** a margem esquerda acompanha o maior rótulo (mínimo 46px); `axis_width` fixa um valor.
- Formatador compacto pt-BR (#63): `brl_compact` (servidor e `chart.js`) e `LedgerUI.Components.Chart.format_brl_compact/1` escrevem "R$ 850 mil", "R$ 2,6 mi", "R$ 10,4 mi" e "R$ 1,2 bi".
- `chart type="bar"` com projeção (#56):
  - **Barras projetadas:** `plotOptions.bar.projectedFrom` (índice ou categoria) deixa translúcidas e com contorno tracejado as barras simples ou empilhadas a partir dali. Ajustes: `projectedFillOpacity` (`.28`), `projectedStrokeDashArray` (`"3 2"`) e `projectedStrokeWidth` (`1.2`).
  - **Bigodes:** `series[].error: %{lower:, upper:}` desenha o intervalo nas barras projetadas.
  - **Linha "hoje":** `annotations.xaxis[]` com `split: true | %{before:, after:}` (rótulos dos dois lados) ou `line: true`.
  - **Legenda:** `legend: %{projection: true | "texto", error: true | "texto"}`.
- `donut_chart` (#57):
  - **Layout:** `layout="side"` (anel à esquerda, lista à direita, quebra quando falta largura).
  - **Anel:** `size` (180) e `thickness` (14).
  - **Percentual:** `percent_precision` (1; `0` dá "52%"), com vírgula em pt_BR.
  - **Centro:** `center_upcase` e `center_size="sm"` (19/24).
  - **Linhas da lista:** `rows_style` `"default" | "canvas"`; o padrão é `canvas` quando `layout="side"`.
- `ai_tool_trace` (#58):
  - **Resumo:** `summary_text` substitui "Usou N ferramentas".
  - **Chevron:** `chevron` põe uma seta no fim do resumo, que gira ao abrir.
  - **Nome em sans:** `name_style="sans"` (nome `ink` 500 em sans, `ms` em mono).
- `prompt_suggestions variant="pill"` (#59):
  - **Ícone:** `item[:icon]` aparece antes do texto, em accent-ink.
  - **Link:** `item[:href]`, `item[:navigate]` ou `item[:patch]` vira um `<.link>`.
  - **Valor:** `item[:value]` é o que vai no evento (padrão: o texto).
- `tag canvas` (#60):
  - **Tamanho:** `size="sm"` (24px, 12,5px).
  - **Rótulo e valor:** `label` (muted) e `value` (`ink` 500).
  - **Tracejada:** `dashed` e `tone="acc"`.
  - **Slot:** o bloco deixa de ser obrigatório.
- `segmented` (#61):
  - **Só ícones:** `icons` dá botões quadrados com o ícone centrado.
  - **Opções:** ganham `title` (vira `title` e `aria-label`) e `icon_only`.
  - **Abas:** com `role="tablist"` os botões viram `role="tab"` com `aria-selected`; o hook também alterna o atributo.
- `stat_group variant="tile"` (#62): blocos afundados numa grade de `cols` (1 a 4, padrão 2), com rótulo em caixa alta, número de 22px e nota. `stat_item tone="accent"` pinta o número.
- `bulk_bar` flutuante (#53):
  - **Look da prancha np-bulkf:** `canvas` com `variant="inverse"`, `"soft"` ou `"solid"` traz o checkbox indeterminado (desmarca a seleção), os separadores do `inline`, "Selecionar todos" em teal-300, ações `danger`/`neg` em texto negativo e nada quebra linha.
  - **Posição:** `offset={136}` (ou a variável CSS `--lu-bulk-offset`) desloca a pílula pelo menu lateral ou pelo painel do Assistente.
- `card` composto (#54):
  - **Paddings da prancha:** `body="inset" size="md"` usa cabeçalho 8/8/10/12, ações com margem −5/−5/−2 e rodapé 9/10/5/12 em 13px.
  - **Flat:** `variant="flat"` é só o painel, sem moldura.
  - **Meta:** slot `:meta` mostra uma informação no título (13px, muted).

### Mudanças de comportamento

- `ai_tool_trace`:
  - **Tempo:** sai com vírgula em pt_BR ("1,8s"; o padrão do componente é pt_BR).
  - **Borda do resumo:** só aparece aberto.
  - **Linha com erro:** pinta só o ícone de negativo.
  - **Linha `running`:** mostra um spinner e "—".
- `line_chart`: a margem do eixo Y cresce quando os rótulos passam de 46px; antes eles vazavam do card.
- `card` composto: `variant="flat"` antes caía em `default`. O cabeçalho e o rodapé de `body="inset" size="md"` ficaram com os paddings da prancha.
- `bulk_bar`: o X das pílulas ganhou `title`.
- `tag canvas`: não quebra mais linha.

## 0.7.0 — 2026-11-22

### Novidades

- Internacionalização (inglês e português do Brasil): todo texto padrão dos componentes (rótulos, `aria-label`, `title`, placeholders, textos para leitores de tela, estados vazios, paginação, meses e dias da semana, toasts, upload, paleta de comandos, IA...) vem de `LedgerUI.I18n`, a única fonte de traduções (`t/3`, `tp/3`, `texts/3`, `labels/2`, `list/2`). O locale vale na ordem: attr `locale` do componente, locale do processo (`LedgerUI.put_locale/1`; em LiveView, `on_mount {LedgerUI.I18n, :default}` lê `"locale"` da sessão e `{LedgerUI.I18n, {:locale, "pt_BR"}}` fixa um), `config :ledger_ui, locale:` e `"en"`. Nada muda sem configuração: o HTML padrão dos componentes em inglês é idêntico ao de antes (verificado com `scripts/i18n_snapshot.exs`, 775 renderizações). Um texto passado pelo chamador (`close_label="Fechar"`) sempre vence. Os componentes que já tinham `locale` (`calendar`, `due_calendar`, `date_picker`, `datetime_picker`, `time_picker`, `color_picker`, `signature_pad`, `clipboard`, `dropdown_footer`, `filter_menu`, `tool`...) passam a ter `nil` como padrão (antes `"en"`), e os outros ganham o attr. Os hooks de JS não escrevem texto próprio: `range` (min/máx dos polegares) e `chart` (nome do SVG e do total) recebem os textos do servidor. Os componentes cujo texto padrão já era português (`notification_center`, `rating`, `tag`, `tabs`, `card_table`, `cash_timer`, `table_toolbar`, `textarea`, `number_input`, `phone_input`, gráficos e `ai.ex`) continuam em português enquanto nenhum locale for configurado; a lista está no README ("Idioma / Locale"). Os atributos de texto cujo padrão era uma string passam a ter `nil` como padrão e caem no texto do locale.
- `card` composto (opt-in, atributo `body`): `seamless`, `divided`, `separated`, `inset` (corpo como painel interno com raio concêntrico: raio do card menos o gap) e `flush`. Sem `body` o HTML é idêntico ao de antes. `variant` aceita `default` (painel + borda + sombra suave; no escuro, painel mais claro com realce interno), `muted`, `soft`, `filled` (tintas translúcidas de `ink`, que se adaptam ao fundo em claro e escuro) e `outline`. `size` (`xs`/`sm`/`md`/`lg`) ajusta padding, raio, gap e tipografia por variáveis (`--card-p`, `--card-py`, `--card-r`, `--card-gap`). Slots novos: `:description` e `:bleed` (conteúdo, como uma imagem, de ponta a ponta do corpo até os cantos arredondados); `:actions` ganha `placement="start"` e as ações "penduram" no padding do cabeçalho (alinhadas à primeira linha do título, sem aumentar o cabeçalho, com a mesma distância do topo e da lateral). `card_header` e `card_footer` aceitam `padded={false}` para virar subseções dentro de um corpo.
- `table` implementa `bleed`: sem caixa própria (sem borda, raio ou fundo) e com a primeira e a última célula de cada linha com o padding `--card-p` do card, para as linhas irem de ponta a ponta com o conteúdo alinhado ao padding do card. Em um `card_table` as linhas já ocupam o corpo, então não há `bleed` nele.
- Dimensionamento de colunas em `table`, `data_table` e `card_table` (opt-in, no `:col`): `grow={n}` faz a coluna ficar com a sobra de largura (peso: `grow={2}` leva o dobro de `grow={1}`) e as demais ficam no tamanho do conteúdo; `wrap` escolhe `auto` (uma linha enquanto couber, quebra quando a tabela estreita; é o padrão de uma coluna com `grow`), `never` (uma linha, a tabela rola) ou `truncate` (uma linha com reticências, sem alargar a tabela); `min` (`"12rem"`) fixa a largura mínima. `width` continua mandando: com ele, `grow`, `wrap` e `min` são ignorados. No layout de cards (`card_below`) a coluna volta a `w-auto` e sem largura mínima. Sem esses atributos o HTML é idêntico ao de antes (o `role="title"` não cresce sozinho). Exemplo: `<:col label="Cliente" grow={1}>` no lugar de `width="minmax(...)"`/`whitespace-normal`, que deixavam as outras colunas inchadas.

## 0.6.1 — 2026-11-22

### Correções

- `filter_menu` sem grupos (`groups={[]}` e sem slot `:group`) não abre mais um painel vazio: mostra um estado vazio ("Nenhum filtro disponível" em `pt_BR`, "No filters available" em `en`; texto próprio em `empty_label`) e esconde o rodapé Limpar/Aplicar. Com grupos o HTML não muda. Os textos seguem o attr `locale` (`"en"` por padrão; não há config global `config :ledger_ui, locale:`, então páginas pt-BR passam `locale="pt_BR"`), agora documentado no moduledoc. Corrige também o botão Aplicar, que sempre voltava para "Apply" depois que o hook atualizava o texto (lia `applyLabel` em vez de `luApplyLabel`) e ignorava o `locale`.
- `bulk_bar variant="inline"` igual à prancha do Nexus Pro (#52): checkbox indeterminado, contagem em 13,5px `ink`, "Selecionar todos os N", separador, campos e ações (todas ghost sm, sem borda; `danger` vira ghost com texto negativo), separador e um X para limpar (`clear_label` como `aria-label` e `title`, só com `on_clear`), padding `6px 6px 6px 12px`, sem quebra de linha. O slot `:action` aceita `variant="ghost"` e `"neg"` em todos os looks; o `:field` do inline sai ghost (os botões dentro dele perdem borda, fundo e sombra). Os outros looks não mudam.

## 0.6.0 — 2026-11-22

Versão com quebras: remove as APIs deprecadas e junta `app_shell` e `shell` em um só quadro. Só o app Nexus Pro usa o
kit; a tabela abaixo é a migração completa.

### Quebras (migração)

| Antes | Depois |
|---|---|
| `<.icon_button icon="x" label="L" variant="primary" size="sm" />` (visual do canvas) | `<.button canvas appearance="primary" size="sm" icon="x" aria-label="L" part="icon-button" />` (`variant` do `icon_button` vira `appearance`; `part="icon-button"` só se você depende do `data-part`) |
| `<.icon_button icon="bell" label="L" variant="topbar" dot />` | `<.button canvas appearance="topbar" icon="bell" aria-label="L" pip part="icon-button" />` (`dot` vira `pip`) |
| `<.icon_button icon label color="error" variant="outline" size="xs" shape="square" />` (variantes do kit: com `color`, `shape`, `size` `xs`/`xl` ou `variant` `solid glow outline bordered flat glass dim`) | `<.button icon="x" color="error" variant="outline" size="xs" shape="square" aria-label="L" />` (`shape="square"` é o padrão do `icon_button` nesse modo) |
| `<.selection_bar count={n}>` | `<.bulk_bar count={n} floating={false}>` (mesmos attrs e slot `:action`; o `id` do `bulk_bar` é obrigatório, a `selection_bar` usava `"selection-bar"`) |
| `<.action_menu id label placement ...>` | `<.dropdown id label placement="bottom-end" trigger_style="ghost" row_mark part="action-menu" ...>` (slots `:title`, `:trigger`, `:overlay`, attrs `demo`, `highlight`, `menu_style`, `anchor_class` iguais) |
| `<.action_menu_item icon="i" hint="h" kbd="k" danger disabled>` | `<.dropdown_item kbd="k" description="h" two_line danger disabled><:icon><.icon name="i" /></:icon>...</.dropdown_item>` (`icon` vira o slot `:icon`; `hint` vira `description` + `two_line`; `two_line` só se havia `hint`) |
| `<.action_menu_separator />` | `<.dropdown_separator />` |
| hook `LedgerUI.ActionMenu` (`hooks/action_menu.js`) | `LedgerUI.Dropdown` (a marcação da linha vem de `row_mark`); remova `LedgerUI.ActionMenu` do mapa de hooks do app |
| `LedgerUI.Components.ActionMenu` | `LedgerUI.Components.Dropdown` (`action_button/1` mudou para lá, sem mudança de API) |
| `<.app_shell ...>` | `<.shell ...>` (tabela abaixo) |
| `<.shell_floating ...>` | `<.shell float ...>` |
| `<.shell sidebar="rail" nav=...>` (formato do menu de dados) | `<.shell format="rail" nav=...>` (o slot `:sidebar` ficou com o nome `sidebar`) |
| `LedgerUI.Components.AppShell` (módulo) | `LedgerUI.Components.Shell`; todos os blocos (`rail_link/1`, `rail_module/1`, `rail_heading/1`, `main_sidebar/1`, `sidebar_nav_*`, `header/1`, `framed_sidebar/1`, `tab_bar/1`, `sideblock/1`, `*_classes`...) têm os mesmos nomes e attrs |
| `AppShell.page_header/1` (chamada qualificada) | `Shell.page_header/1` (`LedgerUI.Components.Shell.page_header/1`; `<.page_header>` continua via `use LedgerUI`) |
| hook `LedgerUI.AppShell` (`hooks/app_shell.js`) | `LedgerUI.Shell` (`hooks/shell.js`): mesmo comportamento (`sidebar_open`, `on_toggle`, `target`, `persist`, `[data-sidebar-toggle]`, `preloader`); atualize o mapa de hooks |

`app_shell` para `shell`, attr por attr e slot por slot:

| `app_shell` | `shell` |
|---|---|
| `id` (padrão `"app-shell"`) | `id` (padrão `"shell"`; passe `id="app-shell"` se usa `LedgerUI.toggle(..., "app-shell")`) |
| (sem `full`: sem moldura, `min-height: 100vh`) | `full` (sem borda, raio e sombra, `100vh`); **sem `full` o `shell` desenha a moldura arredondada de 520px**: para o comportamento antigo escreva `<.shell full>` |
| `layout` `sidebar\|minimal\|sideblock\|horizontal\|framed` | `layout` igual, com o slot `:sidebar` (no modo de dados é ignorado; `rail` só existe no `variant="preview"`) |
| `float` | `float` (`layout="framed"` continua implicando) |
| `sidebar_open`, `on_toggle`, `target`, `persist` | iguais |
| `preloader` | `preloader` (`data-part` `shell-preloader`) |
| `header_sticky`, `header_blur` (padrão `true`) | iguais; padrão `true` no modo slot, `false` no modo de dados |
| `min_height` | `min_height` (padrão 520px, ou a viewport com `full`; no `app_shell` era `100vh`) |
| `main_class`, `class`, atributos globais | iguais |
| slot `:sidebar` | slot `:sidebar` (ativa o modo slot; `nav`/`format` são ignorados) |
| slot `:header` | slot `:topbar` |
| slots `:aside`, `:tab_bar`, bloco interno | iguais (`max-md:pb-16` agora só com `:tab_bar`) |
| `data-part` `app-shell`, `app-shell-main`, `app-shell-preloader` | `shell`, `shell-main`, `shell-preloader` |

### Removido

- `icon_button/1`, `selection_bar/1`, `action_menu/1`, `action_menu_item/1`, `action_menu_separator/1`, `app_shell/1`,
  `shell_floating/1`, os módulos `LedgerUI.Components.ActionMenu` e `LedgerUI.Components.AppShell` e os hooks
  `LedgerUI.ActionMenu` e `LedgerUI.AppShell`.

### Alterações

- `shell/1` é o único quadro do app, com dois modos: de dados (`nav` + `format`, desenhado por `sidebar/1`, como antes) ou
  de slot (`<:sidebar>` com o markup livre do `app_shell`). Traz tudo do `app_shell`: `layout`, `float`,
  `sidebar_open`/`on_toggle`/`target`/`persist` (hook `LedgerUI.Shell`), `preloader`, `header_sticky`, `header_blur`.
  A raiz é o `group/shell` das peças e leva `open`/`is-sidebar-open`, então `LedgerUI.open/close/toggle(.., "shell")`
  funcionam nos dois modos.
- `button/1` é o único componente de botão. O modo `canvas` aceita `appearance` `default primary accent soft ghost
  danger-soft topbar go` (`topbar` 40x40 e `go` 30px redondo têm medida fixa e ignoram `size`; `go` usa ícone `md`),
  `pip` com posição por aparência e o novo attr `part` (o `data-part`, padrão `button`). Corrigido: `canvas` com `icon`
  em string e sem conteúdo agora é quadrado.
- `dropdown` faz tudo o que o `action_menu` fazia: `trigger_style="ghost"` (botão "⋯"), slot `:title`, `row_mark`
  (tinge a linha da tabela aberta, `data-row-mark` + hook `LedgerUI.Dropdown`), `part` (prefixo do `data-part`) e `hook`.
  `dropdown_item` ganha `kbd` e `two_line`. O hook `Dropdown` passa a marcar a linha (`data-am-open`) com `data-row-mark`.
- `badge` e `tag` compartilham as classes das variantes `solid` e `soft` em `LedgerUI.Variants`. Saída idêntica
  (`outline`, `bordered` e `flat` diferem entre os dois e ficam em cada componente).

### Novidades

- `shell/1`: `full` (app em tela cheia: sem borda, raio e sombra, altura da viewport), `min_height` e o slot `:aside`
  (renderizado depois da página, sobre o shell: drawer, modal).
- Feedback (placa G10): os loops "em loop" do canvas, só com CSS e respeitando `prefers-reduced-motion`. `alert loop`
  (o alerta entra e sai, `mo-alin`); `progress`/`progress_bar loop` (a barra enche até o `value` e esvazia,
  `mo-fillw`); `empty_state loop` e `inline_empty loop` (o aviso aparece e some, `mo-stg`); `toast_card progress_loop`
  (preenchimento e % sobem sozinhos); `skeleton_group loop` com o slot `:loaded` (o placeholder e o conteúdo que chega,
  em revezamento); `toast_loop` (`mode="stack"`: toasts entrando e empilhando; `mode="swap"`: o toast de carregando
  dá lugar à resposta). Sem os atributos o HTML não muda.
- `empty_state variant="plain"` aceita `color` (`success` deixa a linha verde, "tudo em dia"); o padrão segue neutro.
- `connection_banner position="top|bottom"`: o toast de queda de conexão aparece no centro do topo ou da base (sem o
  atributo, na posição do toaster).

## 0.5.13 — 2026-11-21

### Correções

- `select`/`pillbox` com `on_search`: quando a busca é limpa (escolher um item, Esc, clicar fora, Tab), o hook envia
  `on_search` com `query: ""`, com o mesmo payload e `target`, para o servidor voltar à lista padrão. Uma busca pendente no
  debounce é cancelada. Nada é enviado se o texto já estava vazio ou sem `on_search` (#51).

## 0.5.12 — 2026-11-21

### Correções

- `rail_module`: com o grupo aberto, só o subitem ativo fica destacado; o cabeçalho do grupo marca o ativo apenas com o
  grupo fechado ou com a sidebar recolhida. O destaque segue o `aria-expanded` que o componente já alterna no cliente, sem
  JS novo. Sem filho ativo o HTML não muda (#50).

## 0.5.11 — 2026-11-21

### Novidades

- `landing_nav` `variant="hero"`: `theme="auto"` segue o tema da página (hero claro com texto escuro; o estado sólido ao
  rolar também), e `theme="light"` fixa o claro. O padrão continua `dark`, como na 0.5.8. `align="center"` centraliza os
  links entre a marca e as ações nas outras variantes (o `hero` já centralizava). Sem os atributos o HTML não muda (#48).
- Toaster: ações aceitam `navigate:` e `patch:` além de `href:` (em `send_toast`, `put_toast`, `update_toast`,
  `show_toast` e no flash) e trocam de tela pelo LiveView, sem recarregar; o toast fecha ao clicar. Só caminhos do mesmo
  site são aceitos (validação no servidor e no hook); valor inválido vira um botão sem link. `href` continua igual (#49).

## 0.5.10 — 2026-11-21

Inclui a 0.5.9 (só no GitHub).

### Novidades

- `input`: `shortcut="/"` (mesma sintaxe do `hotkey`, ex.: `"Mod+k"`) desenha um `kbd` no fim do campo e foca o campo pelo
  atalho; ignorado com o foco em outro campo de texto ou com Ctrl/Meta/Alt; Esc tira o foco; `aria-keyshortcuts`. Com
  vários campos com atalho, responde o primeiro visível. O hook fica na caixa do campo, então convive com `mask`. Sem o
  atributo o HTML não muda (#47).

## 0.5.9 — 2026-11-21

### Novidades

- `bar_chart`: eixo Y opcional. `y_axis` calcula ticks (`Chart.nice_ticks/1`: 1,7 → 0, 0,5, 1, 1,5, 2), `y_ticks` define à
  mão, `y_format` aceita função ou formatter do kit (`"brl_thousands"`, `"k"`…) e `y_grid` desenha a grade. Com eixo, as
  barras usam o maior tick como topo. Sem os atributos o HTML não muda (#41).
- Toast de status: ação ghost (`action: %{label: "Desfazer", event: "undo", variant: :ghost}`), em `send_toast`,
  `update_toast`, `show_toast` e no `status_toast` (`<:action variant="ghost">`). `action:` (singular) entra antes de
  `actions`. O padrão continua o botão cheio (#42).
- Toast de cartão: com `icon` e `progress`, o ícone do tipo fica e o fundo do tile enche de 0 a 100% (no lugar do anel
  girando); `update_toast` anima do nível anterior. Qualquer ícone do kit funciona no cartão do hook (#43).
- `autocomplete`: `label_hint`, como no `input` (#44).
- `radio_group` `variant="card"`: slot `<:trailing :let={opt}>` desenha conteúdo à direita dentro do card. Um botão ali não
  seleciona a opção; um texto ou badge sim; opção desabilitada desliga também o trailing (`inert`). Com trailing o card vira
  `<div>` com o `<label>` esticado por cima, sem controle interativo dentro de `<label>` (#45).
- `stat`: `badge` (com `badge_tone` e `badge_dot`, `"live"` pulsa) ou slot `<:label_badge>` ao lado do rótulo, e `prefix`
  ("R$") sobrescrito antes do valor (#46).

### Correções

- Toaster: `update_toast` com `progress` agora é aplicado no navegador (antes só `value`).

## 0.5.8 — 2026-11-21

### Componentes novos

- `hotkey`: atalho global (`keys="Mod+j"`, várias combinações) que dispara um evento ou um `%JS{}`; ignora campos de texto
  salvo `in_inputs`; aceita `phx-target` (#31).
- `persist`: guarda um valor do LiveView em `sessionStorage`/`localStorage` e o devolve por `on_restore` ao montar, inclusive
  depois de `push_navigate`. O valor fica no navegador: não use para segredos (#32).
- `scroll_target`: rola suave até `[data-block=<target>]` uma vez a cada mudança de `target`; `scope` e `block`; respeita
  `prefers-reduced-motion`. Também `LedgerUI.scroll_to(socket, selector, opts)` (#33).
- `placement_stage`: posiciona e redimensiona uma caixa sobre uma imagem (ex.: carimbo de assinatura num PDF) com mouse,
  toque e teclado; empurra o centro em fração (`on_place`) e a largura (`on_resize`); `disabled` (#34).

### Novidades

- `toaster`: formatos `status` (pílula escura embaixo, ícone de progresso ou anel de fila, `**negrito**`, uma ação, some em
  5 s ou 8 s com ação) e `card` (canto, descrição, várias ações, progresso, etapas); `kind` explícito ou inferido;
  `max_visible` com fila, dedupe por id, `status_position`/`card_position`, `persist_errors`; `update_toast` com
  `replace: true`; eventos `toast:show|update|dismiss`. O contrato `ledger:toast` continua (#37).
- `card_table`: `copy_toast` e `copy_toast_message` (`"%s copiado"`) mostram um toast com o valor copiado; padrão ligado no
  `card_table`, desligado no `table` (#35).
- `table`/`card_table`/`data_table`: `row_groups` usa um `tbody` por item. Liga sozinho quando `rows` é stream e há `:expand`
  ou painel de detalhe, e o detalhe não fica mais órfão no reset, na inserção no início ou no `stream_delete`.
  `row_groups={false}` volta ao `tbody` único (#24).
- `ai` composer: com `streaming`, Enter não envia (Shift+Enter ainda quebra linha) (#36).
- `error_page`: "voltar" e "copiar request id" sem handler inline, para páginas com CSP `script-src 'self'` e sem LiveView.
  `back_label` agora é um link para `back_href` (padrão `/`) que volta no histórico com JS; o listener vem do próprio
  `ledger_ui.esm.js` (#38).
- `landing_nav`: `variant="hero"` (transparente sobre hero escuro), `autohide` (some ao descer, volta ao subir), `spy`
  (marca a seção visível com `aria-current`) e slot `:signed_in` (#39).

### Correções

- `select multiple`: chip, `+N`, select oculto e `aria-selected` não se dessincronizam mais depois de um patch. Se o valor do
  servidor mudou, ele vence; senão a escolha do usuário fica. O `reset` do form volta ao último valor do servidor (#40).

### Desempenho

- Tabelas: a classe das células vai uma vez no `<table>` (seletores descendentes); 50×8 caiu de ~226 KB para ~68 KB de HTML
  (`card_table`: ~318 → ~161 KB), com paridade visual de 0 pixel (#25).
- `select`: a classe das opções vai uma vez no painel e `data-lu-label` só existe com slot `:option`; 1000 opções caíram de
  ~504 KB para ~161 KB (#25).
- `phone_input`: a lista de países vem de um módulo JS do pacote em vez de ir no HTML de cada campo; um campo caiu de ~77 KB
  para ~3,3 KB, seis campos de ~464 KB para ~20 KB (#26).
- Hooks: `select.js` e `treeview.js` cacheiam o DOM e só processam o que o patch mudou (select com 3000 opções: `updated` de
  ~52 ms para ~3 ms; treeview com 3000 nós: ~6 ms para ~0,7 ms). `landing_nav.js` remove todos os listeners (#27).
- Change tracking restaurado em `sidebar` (recolher: ~22 KB → ~0,9 KB), `command_palette` (abrir: 7 → 0,6 KB),
  `notification_center` (5,9 → 1,5 KB), header do `app_shell`, `tag`, `upload_drop` e `chart` (mudar a classe não reenvia
  mais o JSON) (#28).

### Atenção

- Tabelas: uma `class` em `:col` que mexa em padding ou fundo da célula agora sempre vence a regra da tabela (antes dependia
  da ordem no CSS).
- `sidebar`: `nav={{Mod, :fun}}` recebe só os assigns do corpo da sidebar, não mais `collapsed`, `class` e `rest`.
- `error_page`: o "voltar" virou `<a>`; passe `back_href` se `/` não for o destino certo sem JS.
- `toaster`: a pílula de status usa tokens (escura nos dois temas), e uma pílula com ação agora fecha sozinha em 8 s.

## 0.5.7 — 2026-11-21

### Novidades

- `drawer`, `sheet` e `modal`: `size="auto"` faz o painel acompanhar a largura do conteúdo (mínimo do `sm`, máximo da tela),
  sem rolagem horizontal quando o conteúdo cabe. `width` define a largura em px (`width={900}`) ou CSS
  (`width="min(90vw, 56rem)"`), sempre limitada à tela; vence `size`. Sem os dois, o HTML não muda. No `sheet`, vale com
  `placement="right"`/`"left"` (#29).
- `select`: `search="auto"` é o novo padrão: no `multiple` a busca fica numa caixa no topo do painel, focada ao abrir; no
  simples continua no controle. `control`, `panel` e `none` explícitos não mudam (#30).

### Correções

- `select`: no `overflow="count"` o controle tem a mesma altura do input em cada tamanho (o `sm` com chips ficava com 36px
  contra 32px e desalinhava o rótulo numa linha de filtros). A largura padrão continua 260px; em grade ou formulário use
  `class="w-full"` (#30).

### Desempenho (sem mudança de API nem de HTML)

- `data_table`, `card_table`, `menu_list` e `treeview` não passam mais o `assigns` inteiro para componentes internos, o que
  desligava o change tracking. Num `data_table` de 50 linhas, mudar `search` ou `page` enviava ~211 KB com todas as linhas;
  agora ~1,5 KB, sem nenhuma linha. No `card_table`, mudar `description`: de ~162 KB para ~0,4 KB.
- `table`: classe e estilo das células são calculados uma vez por coluna, não por célula (sem regex por célula).
- `table`: `selected` vira `MapSet` internamente; 8000 linhas com 8000 selecionadas renderizam em ~220 ms em vez de ~630 ms.
- `select`, `chart` e `tags_input`: o JSON constante de classes é montado na compilação; um formulário com 20 selects e 5
  gráficos renderiza ~30% mais rápido. `icon` sem regex no lookup.

## 0.5.6 — 2026-11-21

Inclui a 0.5.4 e a 0.5.5 (só no GitHub).

### Correções

- `card_table` e `data_table` não re-envolvem mais os slots `:col`/`:action`/`:expand`/`:foot` ao repassá-los para o `table`:
  as entradas originais seguem adiante. Antes, cada célula guardava closures que capturavam o `assigns` inteiro em cadeia, e
  qualquer cópia do estado da LiveView (relatório de crash, `:sys.get_state`) explodia de tamanho. Numa tabela de 4×4 o
  `flat_size` do estado caiu cerca de 10×, para ~2× o de uma tabela em markup puro, em qualquer profundidade de repasse (#23).

  Cada camada em que o **app** re-envolve as colunas (`<:col :for={c <- @col}>{render_slot(c, row)}</:col>`) ainda multiplica
  o tamanho pelo número de colunas. Para repassar colunas entre componentes, passe a lista de slots adiante (`col={@col}`) em vez
  de re-envolver.

## 0.5.5 — 2026-11-21

Inclui a 0.5.4 (só no GitHub).

### Correções

- `clipboard`: o toast de "copiado" agora aparece. O hook despachava `ledger:toast` no `window`, mas o toaster só escuta no
  próprio elemento; agora o evento vai para o toaster da página, com o `window` como fallback quando não há toaster (#20).
- `modal`: `size="sm"` volta a 440px, entre `xs` (320px) e `md` (560px), como no design. O `layout="page"` continua com 620px
  (#21).

## 0.5.4 — 2026-11-21

### Correções

- Os painéis flutuantes de `date_picker`, `time_picker` (variante `input`), `datetime_picker`, a lista de países do
  `phone_input` e o "+N" do `avatar_group` não são mais cortados por ancestrais com `overflow` (corpo de `card`/`card_table`,
  tabelas). Eles vão para a camada de topo (`popover="manual"` + `position: fixed`), com o mesmo posicionamento do `dropdown`:
  abrem embaixo do campo, viram para cima perto da borda da viewport e acompanham scroll e resize. O `date_picker` `inline`
  não muda. Hook novo: `LedgerUI.AvatarMore` (#22).

## 0.5.3 — 2026-11-21

- `theme_script`: `nonce` (e atributos globais) repassados ao `<script>`, para CSP estrita (`script-src 'nonce-...'`). Sem o
  attr, a saída não muda (#18).
- `theme_switch variant="cards"`: cartões Claro, Escuro e Sistema com miniatura do modo (Sistema com as duas metades),
  `radiogroup` com setas, Enter e espaço. Usa o mesmo hook e contrato das outras variantes (`localStorage["theme"]`,
  `data-theme`, `data-theme-choice`, `ledger:theme`) e sincroniza com elas (#19).
- Tema: um bloco `[data-theme=dark] [data-theme=light]` restaura o accent claro quando um elemento claro está dentro de um
  escuro (como a miniatura clara numa página escura). Fora desse aninhamento nada muda. Esse bloco usa o accent padrão do
  kit; um app com accent próprio que dependa desse aninhamento deve repetir o próprio accent nesse seletor.

## 0.5.2 — 2026-11-21

Inclui a 0.5.1 (só no GitHub).

### `auth_split` (#17)

- `<:top>`: faixa no alto da metade do formulário (marca à esquerda, link "Já tem conta?" à direita).
- `<:page_footer>`: rodapé da metade do formulário (termos, privacidade, ajuda). O `:footer` abaixo do formulário continua.
- `<:heading>`: título com markup (destaque, quebra de linha). `title` deixa de ser obrigatório.
- `form_width`: largura da coluna do formulário pela variável `--lu-auth-form-w` (padrão 360px). A classe muda de `w-[360px]`
  para `w-(--lu-auth-form-w,360px)`, sem mudança visual. A metade do formulário passa a ser uma coluna (topo, formulário
  centralizado, rodapé).

## 0.5.1 — 2026-11-21

### Correções

- `upload`: as entradas já enviadas também têm o botão de remover, ao lado do check, com o mesmo evento e `phx-value-ref` das
  entradas em andamento. Sem `on_remove` (exemplos estáticos), o cartão concluído continua só com o check (#16).

## 0.5.0 — 2026-11-21

### Gráficos (#14)

`chart/1` (opções no formato ApexCharts):
- `chart.stacked: true`: barras empilhadas com várias séries, em colunas ou horizontais. Sem `yaxis.max`, o topo do eixo é
  arredondado.
- `annotations.xaxis`: faixas no eixo X (`x`, `x2`, `tone="neg|warn|pos|info"`, `label.text`), desenhadas atrás das séries.
- `markers.size` (número ou lista por série), `stroke.curve: "straight" | "smooth"` e `stroke.dashArray` por série.
- `tooltip`: tooltip compartilhada com o valor de cada série na categoria (`tooltip.y.formatter`) e `total: true`. Abre também
  por teclado (Tab, setas, Home/End, Esc); o SVG ganha um `<desc>` com os dados.
- `xaxis.tickAmount`: limita os rótulos do eixo X.
- `nil` como ponto sem valor: a linha quebra no buraco (também no `line_chart`), e a tooltip mostra "—".
- Formatadores novos: `thousands_br` ("12 mil"), `k` ("1,5k"), `brl_thousands` ("R$ 12 mil") e `brl_full` ("R$ 1.234,56").
  No Elixir, `format_thousands_br/1`, `format_k/1`, `format_brl_thousands/1` e `format_brl_full/1` servem para o `line_chart`.

Sem as opções novas, os gráficos existentes desenham o mesmo SVG.

### `card_table` (#15)

- `<:toolbar>` e `<:selection :let={%{count: n, selected: s}}>` dentro do card, entre o cabeçalho e a tabela. A barra de
  seleção (fundo `accent-soft`, `aria-live`) aparece enquanto houver itens em `selected`, com badge de contagem
  (`selection_label`, `selection_label_plural`, `selection_badge`).
- `loading` (`loading_rows`, `loading_label`): linhas skeleton no lugar das linhas.
- `error` com `on_retry` (`retry_label`): estado de erro com botão para tentar de novo. Prevalece sobre `loading`.

## 0.4.3 — 2026-11-21

Sem mudança nos componentes; versão de organização do repositório.

- O showcase (vitrine Phoenix), a paridade visual (`parity/`) e as ferramentas de comparação e publicação
  (`scripts/visual`, `scripts/publish`) saíram do repositório público e vivem no repositório privado de design. O repositório
  público fica só com o pacote, os testes, a documentação e os scripts que geram arquivos do próprio pacote.
- README: sem referências às pastas que saíram.

## 0.4.2 — 2026-11-21

Sem mudança nos componentes; versão de organização do repositório.

- Os dados de design (canvas, vitrine de referência, `system/` com os READMEs de API) saíram do repositório público e vivem no
  repositório privado `devaction-labs/ledger_ui_design`. O showcase, os testes e os scripts leem por `LEDGER_DESIGN`
  (padrão `../ledger_ui_design`); sem ele, o showcase compila e os testes que dependem dos dados são pulados. O pacote Hex nunca
  incluiu essa pasta.
- `scripts/publish/`: exportação estática da vitrine (showcase sem servidor, com um runtime que executa os JS commands e monta os
  hooks) e do design system no formato de artifact.
- README: exemplo do `rail_link` regenerado.

## 0.4.1 — 2026-11-21

### Correções

- `rail_module` volta a abrir e fechar. O corpo do grupo usa o atributo `hidden`, e o preflight do Tailwind v4 o esconde com
  `display: none !important`, que vence o `display` inline do `JS.toggle`/`JS.show`. Agora o clique alterna o próprio atributo
  (`JS.toggle_attribute({"hidden", "hidden"})`), e fechar usa `JS.set_attribute({"hidden", ""})` (#11).
- O mesmo problema foi corrigido nos outros alvos escondidos pelo atributo `hidden`: grupos do `sidebar_nav_group` (incluindo o
  acordeão) e do `sub_nav`, caixa do `sidebar_profile`, resultados da busca e notificações do `header`, menu do
  `horizontal_nav_menu`/`horizontal_nav_link`, menus de time e usuário do `sidebar`, menu do `navbar_user` e popover do
  `theme_picker` (#11).

## 0.4.0 — 2026-11-21

### Correções

- `breadcrumb`: o conteúdo dinâmico dos `<:item>` volta a acompanhar os assigns no LiveView. O slot era desenhado dentro dos
  componentes internos a partir de um mapa derivado, e o rastreamento de mudanças não via a troca (#2).
- `avatar`: foto em retrato ou paisagem não sai mais do círculo (`absolute inset-0` na `<img>`). O mesmo vale para as fotos do
  cartão de usuário e dos logos do `app_shell`/`sidebar` e para o avatar de pessoa do `select` (#1).

### Atributos novos

- `chip`: `size="sm|md|lg"` (24, 30 e 32px; o padrão `md` não muda) (#5).
- `navbar_search`: `size="sm"`, compacto com 32px, raio de 8px e `px-2.5` (#3).
- `page_header`: `show_heading={false}` omite o `<h1>`; `density="compact"` usa 24px de padding no topo, em vez de 26px (#4).
- `sidebar`/`framed_sidebar`: a largura recolhida vem de `--lu-rail-collapsed` (padrão 60px) e pode ser definida com
  `collapsed_width={72}` (#9). A classe muda de `data-[collapsed]:w-[60px]` para `data-[collapsed]:w-(--lu-rail-collapsed,60px)`,
  sem mudança visual.
- `insight_button`: com `navigate`, `patch` ou `href`, gera um `<.link>`; `icon="..."` mostra um ícone no lugar do contador e
  vence o `count` (#7).
- `stat_item`: `value_id` (vira o `id` do valor), slots `:inner_block` e `:footer`. `kpi_card`: slot `:footer` no rodapé e
  `value_id` também na variante canvas (#10).
- `rail_link`: slot `<:trailing>` (ex.: `<.kbd>⌘K</.kbd>`) e `variant="sub"` (sub-link de 32px). `rail_module`: `badge` nos `:item`
  filhos. `rail_heading`: `variant="sans"` (11.5px, maiúsculas, peso 500) (#6).
- `notification_center` (variante `classic`): slot `:actions` e `closable` no cabeçalho; `size="sm"` no sino (32px);
  `count_tone` (attr ou por aba) deixa o contador neutro e aplica o tom só na aba selecionada, que acompanha a troca de aba
  via `group-aria-selected:*`, sem JS novo (#8).

## 0.3.0 — 2026-11-21

Os componentes são HEEx estilizado **só com utilitários do Tailwind CSS v4**; o pacote deixa de trazer folhas de estilo de componente.

### Quebra de compatibilidade

- **Sem `ledger.css` nem `ledger_ui.css` de componentes, sem classes `lu-*`.** `priv/static/ledger.css` e `priv/static/ledger_ui.css`
  foram removidos, assim como os exports de CSS do `package.json`. O app hospedeiro roda o Tailwind v4 e importa o tema do pacote
  (`assets/css/ledger_ui.css`: tokens, `@theme`, base e `@keyframes`, com o `@source` da `lib/` do pacote):

  ```css
  @import "tailwindcss";
  @import "../../deps/ledger_ui/assets/css/ledger_ui.css";
  ```

  Quem estilizava com `lu-*` ou com `var(--ink)`/`var(--accent)` passa a usar os utilitários do kit (`bg-panel`, `text-ink`,
  `border-line`, `bg-accent`...) ou as variáveis `--lu-*`. O `package.json` exporta `./ledger_ui.css`, `./css` e `./css/ledger_ui.css`
  (todos para `assets/css/ledger_ui.css`) e o módulo ES continua em `import {Hooks, DOM} from "ledger_ui"`.
- Os hooks não consultam mais classes `lu-*`: usam `data-part`, `data-state` e `aria-*` (os nós criados pelo JS recebem classes por
  `data-lu-cls`/`data-lu-config`, gerados no Elixir). Quem sobrescrevia seletores `.lu-*` precisa trocá-los por `[data-part=...]`.
- `card`: a superfície `flat` agora é o cinza (`bg-sunken`); o antigo `flat` da bandeja é `panel`; `canvas` e `page` são variantes
  novas. `table`: tamanho, cor e família do texto das células com especificidade zero (a classe da célula vence), seta de ordenação
  ao passar o mouse nas colunas inativas.
- `mix ledger_ui.install` e a skill passam a descrever o setup com o Tailwind v4.

### Tema como no Flux

- Duas entradas: o accent (`--color-accent`, `--color-accent-content`, `--color-accent-foreground`) e a escala de cinza
  (`--color-gray-50…950`). Tons 50–900 do accent, fundo suave, foco, fundos, bordas, textos e as cores do gráfico derivam delas em
  oklch; o padrão reproduz o Ledger. O snippet "Tema próprio" do README muda accent e cinza em **todos** os componentes.
- Utilitários do kit: `bg-accent`, `text-accent-content`, `bg-accent-50…900`, `bg-accent-soft`, `bg-page|shell|tray|panel|sunken|hover|selected`,
  `border-line`, `text-ink|ink-2|muted|subtle`, `bg-pos|neg|warn|info|lime|violet`, `shadow-xs…lg|btn`, `rounded-xs…2xl`, `font-sans|display|mono`.
- `LedgerUI.Color`: as cores semânticas (`color=`) em quatro variáveis locais (`--c`, `--c-on`, `--c-soft`, `--c-ink`).
- A paleta `crepusculo` (`data-palette`) alimenta o accent pelas mesmas entradas; modo (`data-theme`) e paleta continuam independentes.
- Vitrine: gerador de tema em `/temas` (accent + cinza), com o CSS pronto para colar.

### Componentes e atributos novos (rodadas de correção)

- `progress_ring/1`, `tooltip_tip/1` (só o balão), `count/1` e `delta/1` (em `badge`; `dot="live"` pisca por opacidade),
  `select` `listbox/1` público (painel estático), `dropdown` `menu_panel/1` público.
- `card variant="panel|canvas|page"`, `card_body` com padding; `pagination arrows_at="sides"`; `view_switcher` `stretch`;
  `calendar` mini `sm|md|lg`, faixa de uma semana e demo de escolha/intervalo; `time_picker_panel` na variante lista;
  `color_picker` `compact`/`row` (amostras 20/26/34px); `signature_pad name_input`; `text_editor` densidade compacta e barra animada.
- Atributos `loop`/`demo` (movimento do canvas feito pelo próprio componente, sem mock): `number_input`, `switch`, `checkbox`,
  `otp_input`, `textarea`, `tags_input`, `password_input`, `upload`, `breadcrumb`, `tabs`, `range`, `carousel`, `timer`, `cash_timer`,
  `avatar` (`speak`), `bar_chart`/`donut_chart`, `pixel_card` (`lit`), `sub_nav`, `connection_banner` (`state=off|re|on|cycle`),
  `command_palette` (`state="no_match"`), `toast_card` (`steps`), `navbar` (busca digitando, sino).
- `app_shell`/`sidebar`: cor e contador no link, título de navegação, contador no trilho, `min_height`; `theme_picker open`, `theme_switch`
  com `value` e slot de ícone; `ai_tool_trace` bare, `ai_chat` `default`/`canvas` e compacto; `kanban` local; `flow` com ramificação;
  `empty_state`/`error_state` compactos e flutuantes, `logo` com tom/glifo, `fab` estático.
- `pillbox`/`tags_input`: as etiquetas são os chips do design, `removable`/`chevron`; a linha "criar" só aparece com `create`.
- Senha: id seguro para nomes com colchetes, bolinhas de 18px e olho de 16px; `phone_input` com o prefixo discreto, sem seta.
- `Form.field` renderiza `inner_block`, `below` e `aside` no lugar (slots não passam como atributo: mantêm o change tracking);
  `Icon.svg_class/1` devolve as classes do `<svg>` para os hooks; `modal placement="top|bottom"` e o alinhamento mantém o centro.
- Vitrine: os exemplos são componentes reais (sem marcação crua) e os dez templates de tela usam só componentes da biblioteca.

### Correções

- `range`: o valor inferior do par é `--lu-rlo` (não colide com o ângulo `--lu-a` do aura).
- `steps`: os conectores têm 2px e ficam alinhados ao pixel; `code_block` mantém a família `monospace` do navegador.
- `theme_toggle`/`theme_switch`: o sol aparece no escuro (o original só trocava o atributo `data-icon`, nunca o desenho).
- `small` volta ao `smaller` do navegador (o preflight do Tailwind põe 80%), pela camada `base` do tema.

### Ferramentas

- Paridade de pixels `parity/run.py` (original `lu-*` x HEEx, em claro, escuro, crepúsculo e crepúsculo escuro; `--theme` com accent fúcsia + cinza slate),
  comparação visual canvas x vitrine `scripts/visual/` e `MIGRATION_REPORT.md` com os números finais. Nada disso vai no pacote Hex.
- README: instalação, temas, paletas, "Tema próprio" e um exemplo por componente (`mix run scripts/gen_readme_components.exs`),
  compilados por `test/readme_examples_test.exs`.

## 0.2.0 — 2026-11-21

Design v3 (paleta Crepúsculo, app em tela cheia, templates de página), API da vitrine completa, ícones Hugeicons sob demanda (`mix ledger_ui.icons`), skill do Claude Code (`mix ledger_ui.gen.skill`), movimento dos overlays e gráficos responsivos.

### A API da vitrine vira real

- Os nomes que a vitrine usa e faltavam são componentes de verdade (mesmos attrs e slots do componente de que
  são apelido, então `__components__/0`, os avisos de compilação e a skill os enxergam): `progress_bar`,
  `number_stepper`, `range_slider`, `radio` (um radio ou um grupo) e `radio_choice`, `cover_card`, `sheet`, `menu`,
  `typography`, `command_palette_dialog`, `date_time_picker`, `empty_state_card`, `rich_text_editor`,
  `comment_editor`, `icon_rail`, `shell_floating`; e `container`, `inline_empty`, `tree` (a árvore como dado) e
  `sub_nav`, novos. `list/1` não existe de propósito (é o do CoreComponents); a vitrine fica com `description_list`.
- `use LedgerUI, only: [...]` e `except: [...]` (nomes ou `nome: aridade`), para quem tem um CoreComponents com
  `button`, `input`, `table`, `header`, `icon`, `modal`...; um nome desconhecido derruba a compilação. README e
  moduledoc explicam.
- Slots que faltavam: `:trigger` em `dropdown`, `action_menu`, `filter_menu`, `context_menu` e `tooltip` (neste, o
  `trigger="click"` e o `content="..."` em forma de texto passam por `rest`), `:title` em `modal` e `drawer` (o
  `title="..."` continua valendo), `:actions` em `modal`, `:item` em `accordion`, `:option` em `segmented`, `:item` e
  `:view` em `sidebar`.
- Attrs que faltavam: `logo` `name`/`context`; `alert` `title`/`description` e `accent` sem valor; `status_toast`
  `status`/`title`/`action`; `divider` `label`; `tabs` `:tab active`; `modal` `show`; `drawer` `floating`;
  `icon_button` `color`/`shape` e as variantes do `button`; `bar_chart` `data`; `calendar` `month`; `color_picker`
  `swatches`; `date_picker` `range`; `password_input` `strength`; `scrollspy` `target`; `theme_picker` `current`;
  `time_picker` `step`; `timer` `seconds`; `step_group` `steps`/`current`; `trace` `spans`; `timeline` `items`;
  `ai_tool_trace` `steps`; `conversation_list` `current`; `sidebar` `workspace`; `tree_item` `icon="nome"`;
  `context_menu` `placement`; `illustration` `color`; `variant` como apelido do `layout`/`shape` em
  `description_list`, `form_section` e `pagination`; `navbar variant="canvas"`.
- `test/support/vitrine_code_known.ex` só guarda artefatos do gerador (modificadores do canvas escritos como
  `variant=`, `<.chip>` com prop de outro componente) e a decisão do `list`, cada um com o motivo.

### Design v3: paleta Crepúsculo, app em tela cheia e vitrine v2

- Paleta `crepusculo` (`<html data-palette="crepusculo">`, tokens claro/escuro no `ledger.css`): `theme_picker` a lista
  (`themes/0` ganha "Crepúsculo"), o hook guarda a escolha em `localStorage["ledger-palette"]` (lê a chave antiga
  `ledger-theme`) e `theme_script/1` a aplica antes da primeira pintura. `LedgerUI` e `theme_switch` documentam
  modo e paleta como duas chaves independentes.
- `app_shell full` (`lu-app full`: tela cheia, sem moldura); o `app/1` dos templates usa `lu-app full`.
- `button icon="nome"`: o ícone antes do rótulo (`icon` continua aceitando `true` para o botão quadrado só de ícone);
  `stat_item` aceita `delta`, `hint`, `goal`, `spark` e `delta_tone`; `aura motion` é apelido de `mode`.
- Showcase: seletor de paleta no topo e página "Temas" como na vitrine v2 (`data-palette` no `<html>`, `lu-palette`),
  os templates aceitam `?palette=crepusculo`, `/templates/paleta` (quadro `TCrepPaleta`) e `/templates/tabela-app`
  ("Pedidos · interativa"); o índice `/templates` lista os da `t/index.json` na mesma ordem e com os mesmos títulos,
  mais o grupo Crepúsculo. Paridade com os quadros `TCrep*` e com `design/vitrine/t/*.html`; o painel agora é
  comparado fora do gráfico de linha.
- Vitrine v2: as seções "Referência visual" saíram (os exemplos foram renumerados), `retired.json` deixou de existir
  e os demos "Referência visual" do canvas não viram extras. `test/vitrine_code_test.exs` compila o HEEx de cada
  seção contra a biblioteca; as que ainda não compilam estão em `test/support/vitrine_code_known.ex`, com o motivo.

### Gaveta e modal: movimento e dados do exemplo

- Gaveta/modal (`layout="page"` e hook `LedgerUI.Overlay`) com o movimento da vitrine: fundo .22s, gaveta .32s,
  modal opacidade .2s + transform .28s, curva `cubic-bezier(.2,.8,.2,1)` nos dois sentidos. A gaveta da página
  não deslizava porque o foco rolava o `.lu-app` (`overflow: hidden`); agora é `overflow: clip`.
- Showcase `/templates/tabela`: cada pedido tem seus itens, desconto, histórico e passos coerentes com a linha da
  tabela; `?pedido=` e `tabela-gaveta` começam sem seleção.

### Ícones e skill

- `mix ledger_ui.icons` (`get`, `sync`, `search`, `update`): baixa os ícones Hugeicons Stroke Rounded que a app usa
  para `config :ledger_ui, :icons_path` (commit fixado, `.hugeicons.json`, `LICENSE.md`), convertidos para o formato do kit.
  `<.icon>` os lê de `LedgerUI.Icons` (`:persistent_term`, recarrega ao achar a pasta alterada); embutidos vencem.
- Skill do Claude Code: `mix ledger_ui.gen.skill` e `mix ledger_ui.install` escrevem `.claude/skills/ledger-ui/`
  (`SKILL.md` + `references/<componente>.md`) a partir do pacote instalado; o compilador opt-in `:ledger_ui_skill`
  a regenera quando a versão muda (não faz nada em `:prod`).

### Integração

- `use LedgerUI` importa só function components e os helpers documentados (`show_toast/2`, `dismiss_alert/0`...);
  os helpers internos (`Chart.num/1`, `money/1`...) não vazam mais. Teste: `use_imports_test.exs`.
- Uma só paisagem: `Illustration.summit/1` (`svg.lu-summit`, tokens `--hero-*`, attr `tone`); `hero_summit/1` e
  `auth_art/1` delegam a ela.
- Novos: `button canvas` (`lu-btn`), `number_input canvas`, `segmented stretch`/`role`, `checkbox style` (vai no `label`).
- Showcase: as seções do vitrine que o canvas aposentou saem da página; as demais são renumeradas a partir de 01.

### Templates

- Showcase: seção "16 · Templates" (`/templates`) com nove telas LiveView do canvas (auth, painel,
  tabela de pedidos com gaveta e modal) e teste de paridade contra os quadros.
- `auth_page/1` e `auth_art/1` (tela `lu-auth`); `bulk_bar variant="float"` (`lu-bulkfloat`);
  `drawer` e `modal` com `layout="page"` (sobreposição controlada pelo LiveView; o modal vira
  `<form>` com `phx-submit`/`phx-change`).
- `line_chart sub_delta`; `alert` com `color`/`variant` nulos; `checkbox size={nil}`; `otp_input
  autofocus` marca a primeira caixa vazia (`on`); a rosca mostra `45%` em vez de `45.0%`;
  `label_aside` dos campos fica numa linha com o rótulo (`lu-row`).

## 0.1.0 — 2026-11-20

Primeira versão do Ledger UI: function components para Phoenix LiveView com o visual do canvas
"Ledger UI · Componentes" (claro e escuro).

### Componentes

- 140 componentes em 15 grupos, 110 módulos (`use LedgerUI` importa todos): fundamentos, ações,
  formulários (texto, seleção, datas e valores), exibição, métricas e gráficos, tabelas, fluxo de
  trabalho, feedback, navegação, sobreposições, estrutura e shell, temas e marca, IA.
- API dos function components conforme os guias do design system (`design/system/components`).
- Formulários aceitam `field={@form[:x]}`; listas e tabelas aceitam `@streams`.

### Arquitetura

- Classes resolvidas em compilação (`@styles` por módulo), `data-part`, prefixo global `keep-`.
- CSS do canvas sem alterações (`ledger.css`) e complemento `ledger_ui.css` para controles reais,
  estados de overlay e classes extras. Sem Tailwind.
- JS como módulo ES (`ledger_ui.esm.js`) exportando `{Hooks, DOM}`: 58 hooks `LedgerUI.*` e
  `DOM.onBeforeElUpdated` para preservar estado do cliente entre patches.
- Ícones Hugeicons renderizados no servidor; gráficos em SVG no servidor; ARIA no HTML do servidor.
- Abrir/fechar overlays com `Phoenix.LiveView.JS` (`LedgerUI.open/close/toggle`), sem ida ao servidor.

### Vitrine

- `showcase/`: app LiveView que replica a vitrine do kit (`mix phx.server`, porta 4100), com
  exemplos em HEEx e teste de paridade contra o canvas (`mix test test/parity_test.exs`).
