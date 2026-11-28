# LiveView eficiente

Vinte e seis regras para escrever telas LiveView que enviam pouco e redesenham pouco, com as fontes, e a lista de decisões que o kit analisou e não adotou. As regras valem para código do app e para o próprio Ledger UI.

Fontes citadas nas regras:

- [G] [Assigns and HEEx templates](https://hexdocs.pm/phoenix_live_view/assigns-eex.html)
- [C11] [changelog do LiveView 1.1](https://github.com/phoenixframework/phoenix_live_view/blob/v1.1/CHANGELOG.md)
- [C12] `CHANGELOG.md` do LiveView 1.2 (em `deps/phoenix_live_view`)
- [JS] `Phoenix.LiveView.JS`
- [PC] `Phoenix.Component`
- [M] medição do kit com `LedgerUI.DiffCase` (`test/support/diff_case.ex`): tamanho do JSON de diff do websocket, sem compressão

As regras 17, 20, 21 e 24 foram conferidas no código e na documentação inline do `phoenix_live_view` 1.2.13 (cliente em `assets/js/phoenix_live_view`, `Phoenix.Component`, `Phoenix.LiveView.Router`), citado em cada uma.

## Templates e change tracking

1. **Não crie variável dentro do `~H`** (`<% x = ... %>`): desliga o rastreamento do bloco. Variáveis de `for`, `if`, `case`, `:let` e `:for` são permitidas. [G]
2. **Não repasse `assigns` inteiro** (`<.parte {assigns} />`): o filho redesenha sempre. Passe attr por attr. [G]
3. **Dentro de um function component, só mude `assigns` com `assign/3`, `assign_new/3` ou `update/3`.** `Map.put/3` faz o valor não atualizar depois do primeiro render. [G]
4. **Um valor derivado criado com `assign/3` no corpo do componente é sempre "alterado".** Prefira chamar uma função no template com os assigns como argumentos (`class={[cls(@variant, @size), @class]}`): ela só é reavaliada quando um deles muda. No kit, `settle/3` dá o mesmo resultado quando o valor é usado em vários pontos (ver `CONVENTIONS.md`). [G] [M: trocar o slot de um badge, 171 B com `assign`, 21 B com a função ou com `settle/3`]
5. **Mantenha a maior parte do template estática.** O que é literal vai uma vez só; `:if` e `case` com ramos pequenos custam pouco. [G]
6. **Tag variável: uma cláusula por tag, não `<.dynamic_tag>`**, que reenvia tag e atributos a cada nova chamada. [PC] [M: 166 B com `dynamic_tag`, 25 B com uma cláusula por tag, em protótipo]
7. **Atributos globais (`{@rest}`):** desde o 1.2.13 só contam como alterados quando um deles muda. Evite montar o mapa de `rest` à mão no corpo do componente. [C12, #4478]
8. **Não carregue dados dentro do template nem em função chamada por ele.** [G]

## Listas

9. **`:for` sem `:key` rastreia por índice:** inserir no topo reenvia tudo que vem depois. Use `:key={item.id}`. [G] [C11]
10. **O corpo do `:for` deve ser um componente** (`<.linha :for={r <- @rows} :key={r.id} row={r} />`) que recebe o item; nada de `Enum.zip` ou `Enum.with_index` dentro do `~H`, calcule antes. [M: `notification_center`, 5 164 B contra 368 B ao inserir um item]
11. **`:key` guarda estado no servidor.** Para listas grandes ou que crescem use `stream/4` com `limit:` e `stream_insert(at:, limit:)`. [G] [C11]
12. **Lista longa com rolagem:** `phx-viewport-top` e `phx-viewport-bottom` no contêiner do stream (e `phx-viewport-overrun-target` em tabelas), nunca um hook de scroll próprio. [C11, 1.1.18]
13. **Carga lenta:** `assign_async` com `<.async_result>`, ou `stream_async/4` (1.1.5). Nada de consulta no mount desconectado. [C11]

## Cliente

14. **Abrir, fechar, alternar classe ou atributo:** `Phoenix.LiveView.JS` (`toggle_attribute`, `add_class`, `hide` com `transition:`). O que um comando JS muda é reaplicado depois de cada patch; o que `el.setAttribute` muda num hook, não. [JS]
15. **Dentro de hook, use `this.js().setAttribute/addClass/show/hide`** em vez de mexer direto no DOM, pelo mesmo motivo. [`assets/js/phoenix_live_view/js_commands.ts`]
16. **Atributo que o cliente controla** (`open`, `hidden`, `style`, `aria-expanded`): `JS.ignore_attributes([...])` em `phx-mounted`, ou `this.js().ignoreAttributes(el, [...])` no `mounted()`. `phx-mounted` não preserva o que foi mudado antes de conectar. [JS]
17. **DOM que pertence ao cliente** (gráfico, editor): `phx-update="ignore"` com `id` estável. Conferido: o cliente trata o elemento como ignorado quando `phx-update` (ou `data-phx-update`) vale `"ignore"` e, nesse caso, só mescla atributos `data-*` vindos do servidor (`dom.ts`, `isIgnored` e o comentário em "if an element is ignored, we only merge data attributes"); o próprio LiveView usa `data-phx-update="ignore"` em `live_img_preview` (`phoenix_component.ex`) e cita `phx-update="ignore"` como alternativa em `<.form>`. Elementos com hook exigem `id` (o cliente registra o erro `hook.missing-id`). [PC] [`dom.ts`]
18. **Entrada e saída animadas:** `phx-mounted={JS.transition(...)}` e `phx-remove={JS.hide(transition: ...)}`. [JS]
19. **Do servidor para o cliente:** a partir do 1.2 mande o próprio comando (`push_event(socket, "x", %{js: JS.add_class(...)})`) e execute com `this.js().execJS(el, js)`, em vez de inventar um evento por ação. [C12]
20. **`phx-debounce` em campo de texto e `phx-throttle` em clique repetido ou slider.** Conferido em `dom.ts` (`debounce/8`): o valor é um número de milissegundos ou `"blur"` (só para `phx-debounce`); um valor vazio usa o padrão do `LiveSocket`, 300 ms (`defaults.debounce` e `defaults.throttle` em `live_socket.ts`); valor não numérico gera o erro `dom.invalid-debounce`. Com `phx-throttle` o primeiro evento passa na hora e os seguintes só depois do intervalo; com `phx-debounce` o evento só sai depois da pausa. [`dom.ts`] [`live_socket.ts`]
21. **Feedback sem ida ao servidor:** classes `phx-click-loading`, `phx-submit-loading`, `phx-change-loading` (e as de `keydown`, `keyup`, `blur`, `focus` e `hook`) e `phx-disable-with`. Conferido em `constants.ts` (`PHX_EVENT_CLASSES`, `PHX_DISABLE_WITH`): o cliente põe a classe no elemento que disparou o evento enquanto o servidor não responde, e `phx-disable-with="Salvando..."` troca o texto de botão ou input de envio durante o `submit`. Estilize essas classes (por exemplo com variantes do Tailwind que a app defina para `.phx-click-loading`) em vez de guardar estado de carregamento no servidor. [`constants.ts`]

## Formulários

22. **`to_form/2` e `@form[:campo]`.** Mostre erro só quando `Phoenix.Component.used_input?/1` for verdadeiro (`phx-feedback-for` não existe mais). [PC]
23. **Todo `<form phx-change>` precisa de `id`:** sem ele a recuperação do formulário após reconexão não funciona, e o 1.2 avisa em teste. [C12]

## Página e transporte

24. **Cromo fixo (shell, paleta, toaster) num LiveView `sticky` dentro do `live_session`.** Use `<.link patch>` na mesma tela e `<.link navigate>` entre telas do mesmo `live_session`. Conferido em `Phoenix.Component.live_render/3` ("this only works for LiveViews that are in the same live_session") e em `Phoenix.LiveView.Router` ("Redirecting between `live_session`s will always force a full page reload"). Consequência: se o roteador tem uma `live_session` por módulo, o LiveView sticky não sobrevive a quase nenhum clique; junte as rotas numa só e decida o requisito por rota num `on_mount` (por `socket.view` ou por `metadata:` da rota). O LiveView sticky renderizado dentro de outro LiveView deve voltar `{:ok, socket, layout: false}` no mount. [PC] [`router.ex`]
25. **`websocket: [compress: true]` no endpoint.** [M: relatório anterior do kit, 30 a 70 vezes menos bytes no fio]
26. **Em dev, `debug_heex_annotations` e `debug_attributes` engordam o HTML** (78% numa página do kit): meça o payload em prod ou com as duas opções desligadas. [M] [PC]

## Decisões registradas

O que foi analisado e não é recomendado, para não reaparecer como proposta.

### N1. Colocated hooks, `ColocatedJS` e `ColocatedCSS` para distribuir o kit

Existem no 1.2.13 (`Phoenix.LiveView.ColocatedHook`, `ColocatedJS`, `ColocatedCSS`) e o kit não os usa. Não deve usar.

- A documentação diz para quem servem: dependências "would typically still bundle their own hooks and colocated JavaScript into a separate file before publishing"; ganchos simples, sem biblioteca de terceiros, podem ser importados direto no bundle do app. O post do 1.1 diz que são mais úteis para trechos pequenos.
- Como ficaria: `compilers: [:phoenix_live_view] ++ Mix.compilers()` no `mix.exs` do kit; o código sai em `_build/<env>/phoenix-colocated/ledger_ui/` e a app importaria `phoenix-colocated/ledger_ui`, o que exige `NODE_PATH` com o caminho de build (padrão só em apps geradas no Phoenix 1.8). O nome dos hooks passaria a levar o prefixo do módulo (`LedgerUI.Components.Dropdown.Dropdown`), quebrando todo `phx-hook="LedgerUI.X"`.
- O que se perde: o manifesto passaria a importar todos os hooks estaticamente, então somem `ledger_ui/core`, `lazyHook` e `ledger_ui/hooks/*`, que foram o ganho da 0.12; os testes de `test/js` deixam de importar arquivos `.js`; hooks de mais de 500 linhas (`dropdown.js`) iriam para dentro de `.ex`; imports relativos entre hooks e `lib/popfloat.js` não funcionam em código extraído.
- O que se ganha: nada que `import {Hooks} from "ledger_ui"` já não dê.
- `ColocatedCSS` está fora de questão pelo princípio do kit (só utilitários Tailwind).
- O inverso vale e pode ser feito pela app: usar colocated hooks ao lado dos do kit, com `hooks: {...colocatedHooks, ...LedgerHooks}`.

### N2. Variantes stateful (LiveComponent) de `data_table`, `command_palette`, `notification_center` e `select`

O kit não tem nenhum LiveComponent. Avaliação:

- Um LiveComponent dá diff isolado, `update_many` e estado local, ao custo de um `cid`, de memória no servidor e de um módulo com ciclo de vida. O 1.1 fez `:key` deixar de usar LiveComponents por baixo justamente para reduzir payload e funcionar em qualquer componente.
- `data_table`: ordenação, página e seleção são estado de domínio (vão para a query); a 0.12 já resolveu o diff com `trow` e `:key`. Um LiveComponent só mudaria quem guarda o estado. Não recomendado.
- `select` e `autocomplete` com busca no servidor: é o caso em que outros kits oferecem LiveComponent. O kit já aceita `target` (o `@myself` do chamador). Um wrapper opcional seria conveniência, não desempenho; baixa prioridade.
- `notification_center`: o ganho vem de `:key` e do LiveView sticky do cromo.
- `command_palette`: `defer_items` já tirou o custo.

### N3. Itens do changelog 1.2 sem ação para o kit

- Formatador de `<script>` e `<style>` (`TagFormatter`): só importa com colocated assets. Sem uso.
- `phx-no-unused-field` (1.2): impede o envio de `_unused_*`. Os campos do kit dependem de `used_input?/1`, que lê esses parâmetros; não aplicar nos inputs do kit. Pode servir em campos escondidos que a app não valida.
- `Phoenix.LiveView.navigation_type/2` (1.2.10) e `phx:before-navigate` (1.2.8, permite `preventDefault()`): base para um futuro helper de "alterações não salvas". Ideia, não há componente hoje.
- Type checker do Elixir 1.20: 932 de 4 226 `attr` são `:any` (22%). Os `values:` já dão verificação em compilação, que é o que o LiveView oferece hoje; não há integração de `attr` com o type checker no 1.2.13. Sem ação.
- `temporary_assigns`, longpoll e compressão: decisão da app; o README já cobre `compress`.
