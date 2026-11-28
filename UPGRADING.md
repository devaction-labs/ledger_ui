# Atualizando o Ledger UI

Para cada versão: o que mudou de requisito e o que o seu app pode apagar ou trocar agora. O que cada versão traz em detalhe está no [CHANGELOG](CHANGELOG.md).

Rode `mix ledger_ui.doctor` no app depois de atualizar: ele só lê e lista, com `arquivo:linha`, boa parte do que está abaixo (atributos iguais ao padrão do kit, wrappers com `{@rest}`, `:for` sem `:key`, `app.js` importando o pacote inteiro, endpoint sem `compress: true`). Código de saída `0` quando não há pendência.

## 0.12.1

**Requisitos novos (pisos de versão):**

- Elixir `~> 1.20` (antes `~> 1.16`).
- `phoenix_live_view` 1.2.13 ou mais novo (antes `~> 1.1`). A serialização de `%JS{}` exige a 1.2, e os ganhos de diff da 0.12 só se sustentam a partir da 1.2.13. Se o seu `mix.lock` tem uma 1.2 mais antiga, rode `mix deps.update phoenix_live_view`.

**O que você pode apagar ou mudar:**

- Em `<.table>`, `<.card_table>` e `<.data_table>`, o corpo de `<:col>`/`<:action>`/`<:expand>`/`<:detail>`/`<:edit>` que lê um assign do pai (`{@moeda}`) volta a atualizar quando esse assign muda (regressão da 0.12.0, #90). Um contorno seu que repassava o valor por dentro de cada linha só para forçar a atualização pode sair.
- Os slots `dropdown_item <:icon>`, `sidebar`/`shell <:mobile_drawer>`, `sidebar <:view>`, `calendar <:event>` e o `name` de `tabs <:panel>` também voltam a refletir assigns do pai (#91): o mesmo vale para contornos que forçavam o redesenho.
- `theme_script` escapa `</script>` nos valores de `theme` e `default` (#133): se você sanitizava esses valores só por isso, a checagem do kit não substitui a validação do que vem do usuário, mas o contorno do `</script>` pode sair.

## 0.12.0

**Requisitos:** os mesmos da 0.12.1 (a 0.12.0 declarava uma faixa mais larga que não funcionava de fato).

**O que você pode apagar ou mudar:**

- **`{assigns}` e `{@rest}` repassados a componentes do kit em wrappers seus:** apague. Dentro de um wrapper HEEx, `<.badge {@rest}>` desliga o rastreamento do LiveView e o kit reenvia tudo a cada chamada (um `card_table` de 25 linhas passa de ~1 KB para ~81 KB por clique de seleção). Delegue por função (seção "Embrulhando um componente" do README).
- **`:key` nas suas listas:** `<.table_row :for={r <- @rows} :key={r.id}>`, `row_id` em `<.table rows>`; sem eles a lista é rastreada por posição.
- **`websocket: [compress: true]`** no endpoint: se você ainda não ligou, os diffs comprimem de 30 a 70 vezes.
- **`command_palette defer_items`:** acrescente em toda paleta; as linhas deixam de ir no HTML a cada montagem (40 itens: 54 KB para 10 KB).
- **`<.tip>` dentro de `<.tip_host>`:** troque os `<.tooltip>` só de texto; cada dica custa ~108 B em vez de ~1,6 KB.
- **JS:** troque `import {Hooks, DOM} from "ledger_ui"` por `import {Hooks, DOM, lazyHook} from "ledger_ui/core"` e registre os hooks pesados (`chart`, `date_picker`, `text_editor`...) um a um ou com `lazyHook`. O import antigo continua funcionando.
- **Cromo persistente:** shell, sidebar, toaster e paleta num LiveView `sticky` (README, seção Performance). Só vale dentro de uma única `live_session`.
- **Componentes seus que derivam valores no corpo** (`assign(:cls, ...)`): chame uma função pura no template (`class={[cls(@variant), @class]}`) ou use `LedgerUI.Helpers.settle/3`; um `assign/3` solto reenvia o valor a cada chamada (`CONVENTIONS.md`, "Derived values: two forms").

## 0.11.0

**Requisitos:** `phoenix_live_view ~> 1.1` na época; veja os pisos da 0.12.1.

**O que você pode apagar ou mudar:**

- **Wrappers de campo só para traduzir erro:** apague o módulo e as entradas em `use LedgerUI, except: [...]`. Configure uma vez:

  ```elixir
  config :ledger_ui, :error_translator, {MyAppWeb.Gettext, :translate_error}
  ```

  A função recebe `{msg, opts}`, como o `translate_error/1` do Phoenix. Vale para `input`, `select`, `autocomplete`, `date_picker`, `checkbox`, `switch`, `textarea`, `number_input`, `radio_group`, `pillbox`, `segmented` e os demais com `field`.
- **`locale="pt_BR"` repetido:** apague os attrs e use `config :ledger_ui, :locale, "pt_BR"`.
- **Rótulos iguais aos do kit:** `no_results="Nenhum resultado."`, `remove_label="Remover"`, `close_label="Fechar"`, `clear_label="Limpar"` e os rótulos da paleta de comandos. O kit traduz esses textos pelo locale; passe o attr só quando o texto for diferente do do kit.
- **`<:cell class="whitespace-normal!">`:** troque por `wrap="auto"` no slot `:cell` (e em `table_cell`, `table_detail_row`, `table_empty`). `padded={false}` tira o padding da célula.
- **Paginação própria:** `shape="compact"`, `summary="%{shown} de %{total}"`, `page_sizes`, `page_size_at` e `patch` cobrem a compacta, a numerada e o seletor de tamanho de página. Os números do resumo agora usam o milhar do locale, e com `id` o form e o select do seletor ganham ids `<id>-size-form` e `<id>-page-size`: confira testes que dependiam dos ids antigos.
- **Tabela plana por seletor (`[&_th]:...`):** use `variant="flat"` e as variáveis `--tpx` e `--th-py`.
- **`color-scheme` e `body`:** o kit define `color-scheme` por modo; remova o seu. Se não quiser que o kit pinte o `body`, use `<body data-lu-base="off">`.
- **Card de KPI refeito no app:** `<:label_extra>`, `value_tone`, `footer_layout`, `spark_variant` e `arrow` cobrem as variações.
