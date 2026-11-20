# FilterMenu

Botão de filtro que abre painel com grupos de opções e mostra quantos filtros estão ativos.

**Grupo:** 04 · Formulários — seleção  
**Resumo visual:** mode apply/live · variant (6) × color (7) · size xs–xl · apply_color

## Uso (Phoenix / HEEx)

```heex
<.filter_menu filters={@filters} active={@active_filters} />
```

## Regras

- O botão mostra a contagem de filtros ativos.
- Rodapé com Limpar e Aplicar.

## Tokens e classes

Estilos em `components/bundle.css` (prefixo `.lu-`), cores só por tokens de `tokens.json`; funciona em claro e escuro sem classes extras. Ícones: `<i data-i="nome"></i>` + `LedgerUI.hydrate()`, ou o componente de ícone do seu app com Hugeicons Stroke Rounded.

## API completa (paridade: filter_menu)

Todos os function components, atributos, valores e slots que este componente cobre.

A filter button that opens a menu of filters: one row per group (Status, Sales channel, Seller) that opens a second
panel to its side with the group's options as checkboxes, and flat sections (Sort by) in the same menu. It is
the Signetum canvas's "Menu de filtros com submenus", and the replacement for a row of status chips that eats a
toolbar. It is built on `dropdown/1` and its filter items, so the keyboard and ARIA are the dropdown's.

Nothing is applied until Apply (`mode="apply"`, the default): ticks only stage, a group's row shows how many
values are staged, Apply shows how many records they leave (from the options' `count`), Clear unticks the filter
groups, and closing the menu any other way takes the staged values back. The trigger shows how many values are
applied, from the `value` of the groups. This is an orders list inside a form; Apply submits it:

    <.form for={@form} phx-submit="apply_filters">
      <.filter_menu
        id="orders-filter"
        label="Filtrar"
        locale="pt_BR"
        variant="outline"
        dashed
        size="sm"
        groups={[
          %{
            name: "filter[status]",
            label: "Status",
            icon: "huge-checkmark-circle-02",
            value: @filter["status"],
            options: [{"Faturado", "invoiced", 3}, {"Aprovado", "approved", 2}, {"Rascunho", "draft", 2}, {"Cancelado", "canceled", 1}]
          },
          %{
            name: "filter[channel]",
            label: "Canal de venda",
            icon: "huge-store-01",
            value: @filter["channel"],
            options: [{"Balcão", "counter", 3}, {"Representante", "rep", 3}, {"Loja online", "online", 2}]
          },
          %{
            name: "filter[seller]",
            label: "Vendedor",
            icon: "huge-user",
            value: @filter["seller"],
            options: [{"Ana Souza", "ana", 3}, {"Carlos Lima", "carlos", 3}, {"Juliana Moraes", "juliana", 2}]
          },
          %{
            name: "filter[sort]",
            label: "Ordenar por",
            caption: "Ordenar por",
            display: :section,
            type: :single,
            value: @filter["sort"],
            options: [{"Mais recentes", "recent"}, {"Maior valor", "value"}, {"Cliente A-Z", "client"}]
          }
        ]}
      />
    </.form>

Every option is a real input named `filter[status][]` (a multiple group) or `filter[sort]` (a single one), so a
plain form posts them too, and the LiveView gets them on Apply. A group with nothing ticked posts no key, so merge
the defaults, and assign the result back: the `value`s are what the menu then shows as applied.

    def handle_event("apply_filters", %{"filter" => params}, socket) do
      defaults = %{"status" => [], "channel" => [], "seller" => []}
      {:noreply, assign(socket, filter: Map.merge(defaults, params))}
    end

In `apply` mode the ticks do not reach the form's `phx-change`; the staged state is the browser's until Apply.
`icon` takes a Hugeicons name; the default is the `:filter` glyph (`icon="huge-filter"` is the funnel).

### A custom period

A single group takes `custom: true` (or the row's text, `custom: "Outro período…"`) and ends with a separator and a
row with a calendar icon, "Personalizado…" in pt_BR, that opens a panel to its side with an inline range
calendar (`date_picker/1`). Picking the second day stages the period: the row shows it (`13/11/2026 – 20/11/2026`
in pt_BR, `2026-11-13 – 2026-11-20` otherwise), the group's presets uncheck and the panel closes. A preset chosen
afterwards takes the period back. The group's value is then the text `custom:FROM..TO` with ISO days:

    %{
      name: "filter[period]",
      label: "Período",
      caption: "Período",
      display: :section,
      type: :single,
      custom: true,
      value: @filter["period"],
      options: [{"Hoje", "today"}, {"7 dias", "7d"}, {"Este mês", "month"}]
    }

The form posts `filter[period]=custom:2026-11-01..2026-11-13` and the events carry the same text under the group's
name; `custom_range/1` turns it into `{~D[2026-11-01], ~D[2026-11-13]}` (`nil` for a preset). Hand the text back
as the group's `value` to show the period as applied.

    def handle_event("apply_filters", %{"filter" => %{"period" => "custom:" <> _ = period}}, socket) do
      {from, to} = LedgerUI.Components.FilterMenu.custom_range(period)
      {:noreply, assign(socket, from: from, to: to)}
    end

The calendar's own two inputs never reach the form or the events. In the panel the keys are the calendar's (arrows,
Page Up and Down, Enter picks); `Esc` closes the panel and gives the focus back to the row.

`display: :submenu` (the default) is a row that opens a panel; `display: :section` is the options laid flat in the
menu under a `caption`, for settings such as a sort order. Only submenu groups are filters: sections do not count in
the trigger, in a group's pill or in Apply. `type: :multiple` (the default) is checkboxes, `type: :single` radios.

One group, with the trigger of a toolbar:

    <.filter_menu
      id="status-filter"
      label="Status"
      groups={[%{name: "status", label: "Status", value: @status, options: ~w(Paid Open Late) |> Enum.map(&{&1, &1})}]}
      on_apply="set_status"
    />

With `on_apply` (and `on_change`, `on_clear`) the events carry `%{"id" => id, "values" => %{"status" => ["Paid"]}}`, to
`target`, so the form is optional. `mode="live"` has no Apply: every tick reaches the form's `phx-change` and
`on_change` at once, and the footer is only Clear.

    <.form for={@form} phx-change="filter">
      <.filter_menu id="live-filter" mode="live" groups={@groups} />
    </.form>

A `:group` slot takes the same attributes as a group and your own content, any `dropdown_checkbox` or
`dropdown_radio` (give each a `name`, and `data-count` for what Apply counts):

    <.filter_menu id="custom">
      <:group name="tags[]" label="Tags" value={@tags}>
        <.dropdown_checkbox :for={tag <- @all_tags} name="tags[]" value={tag.id} checked={tag.id in @tags}>
          {tag.name}
        </.dropdown_checkbox>
      </:group>
    </.filter_menu>

### `<.filter_menu>`

Renders the filter menu.

Events: `on_change` (every tick, staged ones too), `on_apply` (Apply) and `on_clear` (Clear) push
`%{"id" => id, "values" => %{group_name => ["a", "b"] | "x"}}` to `target`: a list for a multiple group and the chosen
value (or `""`) for a single one. `LedgerUI.open/close/toggle` work on the `id`.

| Attr | Type | Default | Values / notes |
|---|---|---|---|
| `id` (required) | `:string` |  |  |
| `label` | `:string` | `nil` | The trigger's text; "Filters" ("Filtros" in pt_BR) when not given. |
| `icon` | `:string` | `nil` | A Hugeicons name (`huge-filter`) or icon classes before the label; the `:filter` glyph by default. |
| `groups` | `:list` | `[]` | A list of maps: `name` (the input name, required), `label` (required), `icon` (`huge-...`), `display` (`:submenu` or `:section`), `type` (`:multiple` or `:single`), `caption` (over a section), `custom` (`true` or a text: a last row that opens a calendar for a period, in a `:single` group), `options` (`{label, value}` or `{label, value, count}`) and `value` (a list for a multiple group, the value for a single one). |
| `mode` | `:string` | `"apply"` | `apply`, `live` — `apply` stages the ticks until Apply; `live` pushes each one at once and has no Apply. |
| `locale` | `:string` | `"en"` | `en`, `pt_BR` |
| `results` | `:integer` | `nil` | The number after Apply, when the server knows the exact records the staged filters leave. Without it the menu adds up the options' `count`s (the smallest staged group when several are staged). |
| `variant` | `:string` | `"outline"` | `solid`, `glow`, `outline`, `soft`, `bordered`, `flat` — The trigger button's variant. |
| `color` | `:string` | `"neutral"` | `neutral`, `primary`, `secondary`, `info`, `success`, `warning`, `error` — The trigger button's color. |
| `size` | `:string` | `"md"` | `xs`, `sm`, `md`, `lg`, `xl` — The trigger button's size. |
| `dashed` | `:boolean` | `false` | A dashed border on the trigger button. |
| `placement` | `:string` | `"bottom-start"` |  |
| `open` | `:boolean` | `false` |  |
| `on_change` | `:string` | `nil` | An event name pushed on every tick. |
| `on_apply` | `:string` | `nil` | An event name pushed by Apply instead of submitting the form. |
| `on_clear` | `:string` | `nil` | An event name pushed by Clear. |
| `target` | `:any` | `nil` | The `phx-target` of the events. |
| `class` | `:any` | `nil` | Merged into the menu box (`w-72`...). |

Any other HTML/phx attribute goes to the root element.

Slots:

- `<:group>` — attrs: `name`, `label`, `icon`, `display`, `type`, `caption`, `custom`, `value` — A group with your own options: the attributes of a `groups` entry (except `options`), and `dropdown_checkbox` / `dropdown_radio` items inside.
