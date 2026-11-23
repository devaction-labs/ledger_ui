defmodule LedgerUI.Components.FilterMenu do
  @moduledoc """
  A filter button that opens a menu of filters: one row per group that opens a second panel to
  its side with the group's options as checkboxes (or radios), plus flat sections (a sort order)
  in the same menu. Behaviour lives in the `LedgerUI.FilterMenu` hook
  (`priv/static/ledger_ui/hooks/filter_menu.js`): opening, submenus, keyboard (arrows, Enter,
  Esc, `ArrowRight` into a submenu) and staging never leave the browser.

      <.form for={@form} phx-submit="apply_filters">
        <.filter_menu id="orders-filter" label="Filtrar" locale="pt_BR" variant="outline" size="sm"
          groups={[
            %{name: "filter[status]", label: "Status", icon: "checkmark-circle-02",
              value: @filter["status"],
              options: [{"Faturado", "invoiced", 3}, {"Aprovado", "approved", 2}]},
            %{name: "filter[sort]", label: "Ordenar por", caption: "Ordenar por",
              display: :section, type: :single, value: @filter["sort"],
              options: [{"Mais recentes", "recent"}, {"Maior valor", "value"}]}
          ]} />
      </.form>

  Every option is a real input (`filter[status][]` for a multiple group, `filter[sort]` for a
  single one), so a form posts them. In `mode="apply"` (default) ticks only stage: the group's
  row shows how many are staged, Apply shows how many records they leave (the options' `count`,
  or `results`), Clear unticks the filter groups and closing the menu any other way takes the
  staged values back; the trigger shows how many values are applied (the groups' `value`).
  `mode="live"` has no Apply: every tick reaches the form's `phx-change` and `on_change`.

  `on_change`, `on_apply` and `on_clear` push `%{"id" => id, "values" => %{group_name => [..] | "x"}}`
  to `target`. A `:single` group takes `custom: true` (or the row's text): a last row that
  opens two date fields; the value is then `"custom:FROM..TO"` (ISO days), parsed by
  `custom_range/1`. A `:group` slot takes the same attributes as a group and your own content
  (any checkbox/radio inputs with a `name`, and `data-lu-count` for what Apply counts).

  With no groups and no `:group` slot the panel shows a small empty state (`empty_label`, default
  "No filters available" / "Nenhum filtro disponível") and hides the Clear/Apply footer.

  ## Locale

  The texts (Filters, Clear, Apply, Custom…, From, To, results, empty state) follow the `locale`
  attr (`"en"` or `"pt_BR"`), else the process locale, else `config :ledger_ui, locale:` (see
  `LedgerUI.I18n`).
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Button
  alias LedgerUI.Components.Checkbox
  alias LedgerUI.Components.FieldBox
  alias LedgerUI.Components.Form
  alias LedgerUI.Components.Radio.Choice
  alias LedgerUI.Components.Select.Options

  # where the panel sits around the trigger (the 12 placements)
  @placements %{
    "top" => "bottom-[calc(100%+8px)] left-1/2 -translate-x-1/2",
    "top-start" => "bottom-[calc(100%+8px)] left-0",
    "top-end" => "bottom-[calc(100%+8px)] right-0",
    "bottom" => "top-[calc(100%+8px)] left-1/2 -translate-x-1/2",
    "bottom-start" => "top-[calc(100%+8px)] left-0",
    "bottom-end" => "top-[calc(100%+8px)] right-0",
    "left" => "right-[calc(100%+8px)] top-1/2 -translate-y-1/2",
    "left-start" => "right-[calc(100%+8px)] top-0",
    "left-end" => "right-[calc(100%+8px)] bottom-0",
    "right" => "left-[calc(100%+8px)] top-1/2 -translate-y-1/2",
    "right-start" => "left-[calc(100%+8px)] top-0",
    "right-end" => "left-[calc(100%+8px)] bottom-0"
  }

  @badge "inline-grid place-items-center rounded-[6px] text-xs"

  @colors ~w(neutral primary secondary info success warning error)

  @doc """
  Parses the text of a custom period.

      iex> LedgerUI.Components.FilterMenu.custom_range("custom:2026-11-01..2026-11-13")
      {~D[2026-11-01], ~D[2026-11-13]}
      iex> LedgerUI.Components.FilterMenu.custom_range("7d")
      nil
  """
  def custom_range("custom:" <> range) do
    with [from, to] <- String.split(range, "..", parts: 2),
         {:ok, from} <- Date.from_iso8601(from),
         {:ok, to} <- Date.from_iso8601(to) do
      {from, to}
    else
      _ -> nil
    end
  end

  def custom_range(_), do: nil

  attr :id, :string, required: true
  attr :label, :string, default: nil
  attr :icon, :string, default: nil

  attr :empty_label, :string,
    default: nil,
    doc: "Text of the empty panel (no groups, no `:group` slot)."

  attr :groups, :list, default: []
  attr :mode, :string, default: "apply", values: ~w(apply live)

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  attr :results, :integer, default: nil
  attr :variant, :string, default: "outline", values: ~w(solid glow outline soft bordered flat)
  attr :color, :string, default: "neutral", values: @colors
  attr :size, :string, default: "md", values: ~w(xs sm md lg xl)
  attr :dashed, :boolean, default: false
  attr :placement, :string, default: "bottom-start", values: Map.keys(@placements)
  attr :open, :boolean, default: false
  attr :on_change, :string, default: nil
  attr :on_apply, :string, default: nil
  attr :on_clear, :string, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :group do
    attr :name, :string
    attr :label, :string
    attr :icon, :string
    attr :display, :any
    attr :type, :any
    attr :caption, :string
    attr :custom, :any
    attr :value, :any
  end

  slot :trigger, doc: "The text of the button, as markup (instead of `label`)."

  def filter_menu(assigns) do
    locale = I18n.locale(assigns.locale)

    t =
      Map.new(~w(label clear apply custom from to results empty)a, fn k ->
        {k, I18n.t("filter_menu.#{k}", locale)}
      end)

    groups =
      Enum.map(assigns.groups, &group(&1, nil)) ++
        Enum.map(assigns.group, &group(&1, [&1]))

    applied =
      groups
      |> Enum.filter(&(&1.display == :submenu))
      |> Enum.map(&length(&1.selected))
      |> Enum.sum()

    assigns =
      assigns
      |> assign(:t, t)
      |> assign(:locale, locale)
      |> assign(:grp, groups)
      |> assign(:applied, applied)
      |> assign(:empty, groups == [])
      |> assign(:empty_text, assigns.empty_label || t.empty)
      |> assign(:trigger_label, assigns.label || t.label)
      |> assign(:pop_id, assigns.id <> "-pop")
      |> assign(:place_class, @placements[assigns.placement] || @placements["bottom-start"])
      |> assign(:item_class, Options.item_class())
      |> assign(:badge_class, @badge)

    ~H"""
    <span
      id={@id}
      data-part="filter-menu"
      class="relative inline-flex"
      phx-hook="LedgerUI.FilterMenu"
      data-open={@open && ""}
      data-lu-mode={@mode != "apply" && @mode}
      data-lu-locale={@locale != "en" && @locale}
      data-lu-results={@results}
      data-lu-on-change={@on_change}
      data-lu-on-apply={@on_apply}
      data-lu-on-clear={@on_clear}
      data-lu-target={@target && to_string(@target)}
      data-lu-apply-label={@t.apply}
      data-lu-results-label={@t.results}
      {@rest}
    >
      <Button.button
        color={@color}
        variant={@variant}
        size={@size}
        shape="rounded"
        class={@dashed && "border-dashed"}
        aria-haspopup="menu"
        aria-expanded={to_string(@open)}
        aria-controls={@pop_id}
        data-lu-trigger
      >
        <.icon name={@icon || "filter"} />
        <%= if @trigger != [] do %>
          {render_slot(@trigger)}
        <% else %>
          {@trigger_label}
        <% end %>
        <span
          data-part="filter-count"
          class={[@badge_class, "-ml-1 h-[22px] min-w-[22px] bg-sunken text-ink"]}
          data-lu-count
          hidden={@applied == 0}
        >{@applied}</span>
      </Button.button>
      <span
        id={@pop_id}
        data-part="filter-popup"
        class={["absolute z-[4] whitespace-nowrap", @place_class]}
        hidden={!@open}
        phx-mounted={JS.ignore_attributes(["hidden", "style"])}
      >
        <div
          data-part="filter-panel"
          class={[Options.panel_class("min-w-[220px]"), "relative w-72 whitespace-normal", @class]}
          role="menu"
        >
          <.group_block
            :for={g <- @grp}
            g={g}
            t={@t}
            item_class={@item_class}
            badge_class={@badge_class}
          />
          <div
            :if={@empty}
            data-part="filter-empty"
            class="px-2.5 py-3 text-center text-sm text-muted"
          >
            {@empty_text}
          </div>
          <div :if={!@empty} data-part="filter-separator" class={Options.sep_class()}></div>
          <div
            :if={!@empty}
            data-part="filter-footer"
            class="flex flex-wrap items-center justify-between gap-2.5 px-[5px] pt-0.5"
          >
            <Button.button color="neutral" variant="flat" size="xs" shape="rounded" data-lu-clear>
              {@t.clear}
            </Button.button>
            <Button.button
              :if={@mode == "apply"}
              color="primary"
              variant="solid"
              size="xs"
              shape="rounded"
              data-lu-apply
            >
              {@t.apply}
            </Button.button>
          </div>
        </div>
      </span>
    </span>
    """
  end

  attr :g, :map, required: true
  attr :t, :map, required: true
  attr :item_class, :any, required: true
  attr :badge_class, :string, required: true

  defp group_block(%{g: %{display: :section}} = assigns) do
    ~H"""
    <div data-part="filter-section" data-lu-group={@g.name} data-lu-type={@g.type} data-lu-section>
      <div :if={@g.caption} data-part="listbox-group" class={Options.group_label_class()}>
        {@g.caption}
      </div>
      <%= if @g.content do %>
        {render_slot(@g.content)}
      <% else %>
        <.option_row :for={o <- @g.options} g={@g} o={o} wide />
      <% end %>
    </div>
    """
  end

  defp group_block(assigns) do
    ~H"""
    <div data-part="filter-group" data-lu-group={@g.name} data-lu-type={@g.type} class="relative">
      <button
        type="button"
        data-part="listbox-option"
        class={@item_class}
        role="menuitem"
        aria-haspopup="true"
        aria-expanded="false"
        data-lu-row
      >
        <.icon :if={@g.icon} name={@g.icon} class="text-ink" /><span>{@g.label}</span>
        <span data-part="listbox-option-right" class={Options.right_class()}>
          <span
            data-part="filter-count"
            class={[@badge_class, "h-5 min-w-5 bg-accent-soft px-1 text-accent-content"]}
            data-lu-gcount
            hidden={@g.selected == []}
          >{length(@g.selected)}</span>
          <.icon name="chevron-right" size="sm" />
        </span>
      </button>
      <div
        data-part="filter-sub"
        class={[
          Options.panel_class("min-w-60", "p-3.5"),
          "absolute top-0 left-[calc(100%+6px)] z-[2]"
        ]}
        role="group"
        aria-label={@g.label}
        hidden
        data-lu-sub
      >
        <div class="flex flex-col gap-2.5">
          <%= if @g.content do %>
            {render_slot(@g.content)}
          <% else %>
            <.option_row :for={o <- @g.options} g={@g} o={o} />
          <% end %>
        </div>
        <%= if @g.custom do %>
          <div class="-mx-3.5 my-0 h-px bg-line"></div>
          <button
            type="button"
            data-part="listbox-option"
            class={[@item_class, "-mx-1.5"]}
            role="menuitem"
            data-lu-custom-row
          >
            <.icon name="calendar" class="text-ink" /><span
              data-lu-custom-text
              data-lu-default={@g.custom}
            >{@g.custom_text ||
              @g.custom}</span>
          </button>
          <div hidden data-lu-custom-panel>
            <div class="flex flex-col gap-2">
              <Form.field as="label" label={@t.from}>
                <span class={FieldBox.classes("outlined", "sm", "rounded", nil, false)}>
                  <input
                    type="date"
                    class={FieldBox.control_class()}
                    data-lu-from
                    value={@g.custom_from}
                  />
                </span>
              </Form.field>
              <Form.field as="label" label={@t.to}>
                <span class={FieldBox.classes("outlined", "sm", "rounded", nil, false)}>
                  <input
                    type="date"
                    class={FieldBox.control_class()}
                    data-lu-to
                    value={@g.custom_to}
                  />
                </span>
              </Form.field>
            </div>
          </div>
          <input
            type="radio"
            name={@g.input_name}
            value={@g.custom_value || ""}
            checked={@g.custom_value != nil}
            data-lu-custom-input
            class={Choice.vh()}
            tabindex="-1"
            aria-hidden="true"
          />
        <% end %>
      </div>
    </div>
    """
  end

  defp option_row(assigns) do
    assigns = assign_new(assigns, :wide, fn -> false end)
    type = if assigns.g.type == :single, do: "radio", else: "checkbox"
    assigns = assign(assigns, :type, type)

    ~H"""
    <label
      data-part="filter-option"
      class={[
        Checkbox.label_class("sm", @o.disabled),
        Checkbox.color_vars("primary"),
        "w-full",
        @wide && "box-border px-2.5 py-1.5"
      ]}
    >
      <input
        data-part="filter-option-input"
        type={@type}
        class={Checkbox.input_class(@type, "sm", "square", false, @o.disabled)}
        name={@g.input_name}
        value={@o.value}
        checked={@o.value in @g.selected}
        disabled={@o.disabled}
        data-lu-count={@o.count}
      />
      <span data-part="filter-option-text" class={Checkbox.text_class()}>{@o.label}</span>
      <span :if={@o.count} class="ml-auto text-xs leading-5 text-muted">{@o.count}</span>
    </label>
    """
  end

  defp group(%{} = g, content) do
    name = to_string(g.name)
    type = to_atom(g[:type], :multiple)
    display = to_atom(g[:display], :submenu)
    value = g[:value]
    selected = Options.values(value)
    selected = if type == :single, do: Enum.take(selected, 1), else: selected

    {custom_value, selected} =
      case selected do
        ["custom:" <> _ = c] -> {c, []}
        _ -> {nil, selected}
      end

    {from, to} =
      case LedgerUI.Components.FilterMenu.custom_range(custom_value) do
        {f, t} -> {Date.to_iso8601(f), Date.to_iso8601(t)}
        _ -> {nil, nil}
      end

    custom =
      case g[:custom] do
        true -> "custom"
        nil -> nil
        false -> nil
        text -> to_string(text)
      end

    %{
      name: name,
      label: g[:label],
      icon: g[:icon],
      display: display,
      type: type,
      caption: g[:caption],
      custom: custom,
      custom_value: custom_value,
      custom_from: from,
      custom_to: to,
      custom_text: from && "#{from} – #{to}",
      input_name: if(type == :single, do: name, else: multi_name(name)),
      options: g |> Map.get(:options, []) |> Options.normalize() |> Options.flatten(),
      selected: if(custom_value, do: [custom_value | selected], else: selected),
      content: content && content != [] && content
    }
  end

  defp multi_name(name), do: if(String.ends_with?(name, "[]"), do: name, else: name <> "[]")

  defp to_atom(nil, default), do: default
  defp to_atom(value, _) when is_atom(value), do: value
  defp to_atom("single", _), do: :single
  defp to_atom("section", _), do: :section
  defp to_atom("submenu", _), do: :submenu
  defp to_atom(_, default), do: default
end
