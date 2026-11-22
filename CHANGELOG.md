# Changelog

## Unreleased

### Alterações

- `button/1` é o único componente de botão. O modo `canvas` aceita `appearance` `default primary accent soft ghost
  danger-soft topbar go` (`topbar` 40x40 e `go` 30px redondo têm medida fixa e ignoram `size`; `go` usa ícone `md`),
  `pip` com posição por aparência e o novo attr `part` (o `data-part`, padrão `button`). Corrigido: `canvas` com `icon`
  em string e sem conteúdo agora é quadrado.
- `icon_button/1` está **deprecado**: é um alias fino de `button/1`, sem mudança visual (mesmas classes; `dot` do
  `topbar` virou o `pip`, um `<span data-part="button-pip">` no lugar do pseudo-elemento, mesma posição e aparência).
- `selection_bar/1` está **deprecado**: use `bulk_bar/1` com `floating={false}`. Continua funcionando.
- `dropdown` faz tudo o que o `action_menu` fazia: `trigger_style="ghost"` (botão "⋯"), slot `:title`, `row_mark`
  (tinge a linha da tabela aberta, `data-row-mark` + hook `LedgerUI.Dropdown`), `part` (prefixo do `data-part`) e `hook`.
  `dropdown_item` ganha `kbd` e `two_line`. O hook `Dropdown` passa a marcar a linha (`data-am-open`) com `data-row-mark`.
- `action_menu`, `action_menu_item` e `action_menu_separator` são aliases finos (deprecados) de `dropdown`,
  `dropdown_item` e `dropdown_separator`: mesmo HTML de antes (só muda a ordem dos atributos de `data-lu-demo` e espaços
  em branco). O hook `LedgerUI.ActionMenu` continua exportado (Dropdown com `rowMark: true`). `action_button` não muda.
- `badge` e `tag` compartilham as classes das variantes `solid` e `soft` em `LedgerUI.Variants`. Saída idêntica
  (`outline`, `bordered` e `flat` diferem entre os dois e ficam em cada componente).

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
