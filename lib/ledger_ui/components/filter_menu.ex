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
  """
  use LedgerUI.Component

  alias LedgerUI.Components.Select.Options

  @text %{
    "en" => %{
      label: "Filters",
      clear: "Clear",
      apply: "Apply",
      custom: "Custom…",
      from: "From",
      to: "To",
      results: "results"
    },
    "pt_BR" => %{
      label: "Filtros",
      clear: "Limpar",
      apply: "Aplicar",
      custom: "Personalizado…",
      from: "De",
      to: "Até",
      results: "resultados"
    }
  }
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
  attr :groups, :list, default: []
  attr :mode, :string, default: "apply", values: ~w(apply live)
  attr :locale, :string, default: "en", values: ~w(en pt_BR)
  attr :results, :integer, default: nil
  attr :variant, :string, default: "outline", values: ~w(solid glow outline soft bordered flat)
  attr :color, :string, default: "neutral", values: @colors
  attr :size, :string, default: "md", values: ~w(xs sm md lg xl)
  attr :dashed, :boolean, default: false
  attr :placement, :string, default: "bottom-start"
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
    t = @text[assigns.locale]

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
      |> assign(:grp, groups)
      |> assign(:applied, applied)
      |> assign(:trigger_label, assigns.label || t.label)
      |> assign(:pop_id, assigns.id <> "-pop")
      |> assign(
        :btn_class,
        "lu-b c-#{assigns.color} v-#{assigns.variant} s-#{assigns.size} sh-rounded"
      )

    ~H"""
    <span
      id={@id}
      class={cx(["lu-anc", @open && "open"])}
      phx-hook="LedgerUI.FilterMenu"
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
      <button
        type="button"
        class={@btn_class}
        {Options.style_attrs(@dashed && "border-style:dashed")}
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
          class="count"
          data-lu-count
          hidden={@applied == 0}
          style={"min-width:22px;height:22px;border-radius:6px;background:var(--bg-sunken);color:var(--ink);font-size:12px;place-items:center;margin-left:-4px;display:" <> if(@applied == 0, do: "none", else: "inline-grid")}
        >{@applied}</span>
      </button>
      <span
        id={@pop_id}
        class={"fl p-#{@placement}"}
        hidden={!@open}
        data-part="panel"
        phx-mounted={JS.ignore_attributes(["hidden", "style"])}
      >
        <div
          class={cx(["lu-pop", @class])}
          role="menu"
          style="width:18rem;position:relative;white-space:normal"
        >
          <.group_block :for={g <- @grp} g={g} t={@t} />
          <div class="lu-menu-sep"></div>
          <div class="lu-row" style="justify-content:space-between;padding:2px 5px 0">
            <button type="button" class="lu-b c-neutral v-flat s-xs sh-rounded" data-lu-clear>
              {@t.clear}
            </button>
            <button
              :if={@mode == "apply"}
              type="button"
              class="lu-b c-primary v-solid s-xs sh-rounded"
              data-lu-apply
            >
              {@t.apply}
            </button>
          </div>
        </div>
      </span>
    </span>
    """
  end

  defp group_block(%{g: %{display: :section}} = assigns) do
    ~H"""
    <div data-lu-group={@g.name} data-lu-type={@g.type} data-lu-section>
      <div :if={@g.caption} class="lu-menu-label">{@g.caption}</div>
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
    <div data-lu-group={@g.name} data-lu-type={@g.type} style="position:relative">
      <button
        type="button"
        class="lu-menu-item"
        role="menuitem"
        aria-haspopup="true"
        aria-expanded="false"
        data-lu-row
      >
        <.icon :if={@g.icon} name={@g.icon} /><span>{@g.label}</span>
        <span class="r">
          <span
            class="count"
            data-lu-gcount
            hidden={@g.selected == []}
            style={"min-width:20px;height:20px;border-radius:6px;background:var(--accent-soft);color:var(--accent-ink);place-items:center;padding:0 4px;display:" <> if(@g.selected == [], do: "none", else: "inline-grid")}
          >{length(@g.selected)}</span>
          <.icon name="chevron-right" size="sm" />
        </span>
      </button>
      <div
        class="lu-pop pad"
        role="group"
        aria-label={@g.label}
        hidden
        data-lu-sub
        style="position:absolute;left:calc(100% + 6px);top:0;min-width:15rem;z-index:2"
      >
        <div style="display:flex;flex-direction:column;gap:10px">
          <%= if @g.content do %>
            {render_slot(@g.content)}
          <% else %>
            <.option_row :for={o <- @g.options} g={@g} o={o} />
          <% end %>
        </div>
        <%= if @g.custom do %>
          <div class="lu-menu-sep" style="margin:0 -14px"></div>
          <button
            type="button"
            class="lu-menu-item"
            role="menuitem"
            data-lu-custom-row
            style="margin:0 -6px"
          >
            <.icon name="calendar" /><span data-lu-custom-text data-lu-default={@g.custom}>{@g.custom_text ||
              @g.custom}</span>
          </button>
          <div hidden data-lu-custom-panel>
            <div style="display:flex;flex-direction:column;gap:8px">
              <label class="lu-field">
                <span class="lu-label">{@t.from}</span>
                <span class="lu-input sm"><input type="date" data-lu-from value={@g.custom_from} /></span>
              </label>
              <label class="lu-field">
                <span class="lu-label">{@t.to}</span>
                <span class="lu-input sm"><input type="date" data-lu-to value={@g.custom_to} /></span>
              </label>
            </div>
          </div>
          <input
            type="radio"
            name={@g.input_name}
            value={@g.custom_value || ""}
            checked={@g.custom_value != nil}
            data-lu-custom-input
            style="position:absolute;opacity:0;width:1px;height:1px;pointer-events:none"
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

    ~H"""
    <label
      class="lu-check c-primary s-sm"
      style={if @wide, do: "padding:6px 10px;width:100%;box-sizing:border-box", else: "width:100%"}
    >
      <input
        type={if @g.type == :single, do: "radio", else: "checkbox"}
        name={@g.input_name}
        value={@o.value}
        checked={@o.value in @g.selected}
        disabled={@o.disabled}
        data-lu-count={@o.count}
      />
      <span class="t">{@o.label}</span>
      <span :if={@o.count} style="margin-left:auto;color:var(--muted);font-size:12px">{@o.count}</span>
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
