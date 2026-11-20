defmodule LedgerUI.Components.BulkBar do
  @moduledoc """
  The bar of bulk actions for a table with selection: how many are selected, optional fields,
  buttons for the actions and a close that clears the selection. It shows only while `count` is
  above zero.

      <.bulk_bar
        id="orders-bulk"
        count={@count}
        label="selecionado"
        label_plural="selecionados"
        total={@total}
        on_select_all="select_all"
        on_clear="clear_selection"
      >
        <:action icon="file" phx-click="issue">Emitir NF-e</:action>
        <:action icon="download" phx-click="export">Exportar</:action>
        <:action variant="danger" icon="trash" phx-click="delete" confirm="Excluir 3 pedidos?"
          confirm_text="Os rascunhos somem para todos." confirm_label="Excluir" cancel_label="Cancelar">
          Excluir
        </:action>
      </.bulk_bar>

  Texts come from outside (`label`, `label_plural`, `select_all_label` with `%{total}`,
  `clear_label`); nothing is pluralized here.

  ## Looks

    * `inverse` (default), `soft` and `solid`: the `lu-selbar` pill (dark, accent-soft and teal).
    * `inline`: the strip at the top of a table (`lu-panel` tinted with the accent): a checkbox
      that clears the selection, the count, "select all" and the buttons.

    * `float` (`lu-bulkfloat`, the canvas template's bar): a dark pill absolutely positioned at the
      bottom center of the closest positioned ancestor (the app shell), with the count, one
      `:action` per button (`variant="danger"` is red and set apart by a rule) and the close. It
      ignores `floating`, `progress` and the `confirm` of an action (the action runs at once).

  `floating` (default) pins a pill to the bottom center of the viewport; `floating={false}` lays
  it out where it is (a bar inside a card or a toolbar). `progress`/`progress_max` turn the bar
  into a progress bar while a bulk action runs. Esc runs `on_clear` (`phx-window-keydown`).

  An `:action` with `confirm` opens a small card first (above the bar when floating, below
  otherwise); only its confirm button runs the action's `phx-click`. A `disabled` action keeps the
  focus (`aria-disabled`) and renders no `phx-*` attributes.

  `selection_bar/1` is the same bar with `floating` off by default.
  """
  use LedgerUI.Component

  @bar %{"inverse" => nil, "soft" => "soft", "solid" => "solid", "inline" => nil, "float" => nil}

  # `style={nil}` renders `style=""`, so an optional style goes through a spread.
  defp st(v) when v in [nil, false], do: []
  defp st(v), do: [style: v]

  @action_keys [
    :__slot__,
    :inner_block,
    :variant,
    :disabled,
    :icon,
    :confirm,
    :confirm_text,
    :confirm_label,
    :cancel_label
  ]

  attr :id, :string, required: true

  attr :count, :integer,
    required: true,
    doc: "How many are selected; the bar shows only above zero."

  attr :label, :string, default: "selected", doc: "The text after the count, for one selected."
  attr :label_plural, :string, default: nil
  attr :total, :integer, default: nil, doc: "How many there are in all (every page)."
  attr :select_all_label, :string, default: "Select all %{total}"
  attr :on_clear, :any, default: nil
  attr :on_select_all, :any, default: nil
  attr :target, :any, default: nil
  attr :clear_label, :string, default: "Clear selection"
  attr :check_label, :string, default: "Selection", doc: "`aria-label` of the `inline` checkbox."
  attr :show_esc, :boolean, default: false
  attr :variant, :string, default: "inverse", values: ~w(inverse soft solid inline float)
  attr :floating, :boolean, default: true
  attr :progress, :integer, default: nil
  attr :progress_max, :integer, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :action, doc: "A button." do
    attr :variant, :string, values: ~w(default primary danger)
    attr :disabled, :boolean
    attr :icon, :string
    attr :confirm, :string
    attr :confirm_text, :string
    attr :confirm_label, :string
    attr :cancel_label, :string
    attr :id, :string
    attr :title, :string
    attr :"aria-label", :string
    attr :"phx-click", :any
    attr :"phx-target", :any
    attr :"phx-disable-with", :string
    attr :"phx-value-id", :any
  end

  slot :field, doc: "A control (a select, an input) in the bar."

  def bulk_bar(%{count: count} = assigns) when count <= 0 do
    ~H""
  end

  def bulk_bar(assigns) do
    inline? = assigns.variant == "inline"
    floating? = assigns.floating and not inline?
    last_normal = last_normal_index(assigns.action)

    assigns =
      assigns
      |> assign(:inline?, inline?)
      |> assign(:floating?, floating?)
      |> assign(:text, count_text(assigns))
      |> assign(:running?, assigns.progress != nil and assigns.progress_max != nil)
      |> assign(:acts, actions(assigns, inline?, last_normal))
      |> assign(
        :select_all?,
        assigns.on_select_all != nil and partial?(assigns.count, assigns.total)
      )
      |> assign(
        :select_all_text,
        String.replace(assigns.select_all_label, "%{total}", to_string(assigns.total))
      )
      |> assign(:classes, cx(["lu-selbar", @bar[assigns.variant], assigns.class]))
      |> assign(:fixed, floating? && fixed_style())
      |> assign(
        :pct,
        assigns.progress_max && assigns.progress_max > 0 &&
          min(round((assigns.progress || 0) / assigns.progress_max * 100), 100)
      )
      |> assign(:all?, is_integer(assigns.total) and not partial?(assigns.count, assigns.total))
      |> assign(:ind, partial?(assigns.count, assigns.total) && "1")

    ~H"""
    <%= if @variant == "float" do %>
      <div
        id={@id}
        class={cx(["lu-bulkfloat", @class])}
        role="region"
        aria-label={@text}
        phx-window-keydown={@on_clear}
        phx-key={@on_clear && "Escape"}
        phx-target={@on_clear && @target}
        {@rest}
      >
        <b>{@text}</b>
        <div :for={f <- @field}>{render_slot(f)}</div>
        <%= for a <- @acts do %>
          <span :if={a.sep_before} class="sep"></span>
          <button
            type="button"
            class={a.variant == "danger" && "danger"}
            {a.attrs}
          >
            <.icon :if={a.icon} name={a.icon} />{render_slot(a.slot)}
          </button>
        <% end %>
        <button
          :if={@on_clear}
          type="button"
          aria-label={@clear_label}
          phx-click={@on_clear}
          phx-target={@target}
        >
          <.icon name="x" />
        </button>
      </div>
    <% end %>
    <%= if @inline? and @variant != "float" do %>
      <div
        id={@id}
        class={cx(["lu-panel", @class])}
        style="display:flex;align-items:center;gap:10px;padding:8px 10px;background:var(--accent-soft);border-color:color-mix(in oklab,var(--accent) 30%,transparent)"
        phx-window-keydown={@on_clear}
        phx-key={@on_clear && "Escape"}
        phx-target={@on_clear && @target}
        {@rest}
      >
        <label class="lu-check"><input
          id={@id <> "-check"}
          type="checkbox"
          aria-label={@check_label}
          checked={@all?}
          data-ind={@ind}
          phx-hook="LedgerUI.TableCheckbox"
          phx-click={@on_clear}
          phx-target={@on_clear && @target}
        /></label>
        <%= if @running? do %>
          <.progress_part text={@text} pct={@pct} progress={@progress} max={@progress_max} />
        <% else %>
          <b class="num">{@text}</b>
          <a
            :if={@select_all?}
            class="lu-btn link sm"
            href="#"
            phx-click={@on_select_all}
            phx-target={@target}
          >
            {@select_all_text}
          </a>
          <span class="lu-grow"></span>
          <div :for={f <- @field}>{render_slot(f)}</div>
          <.bar_action :for={a <- @acts} act={a} bar_id={@id} floating={false} />
        <% end %>
      </div>
    <% end %>
    <%= if !@inline? and @variant != "float" do %>
      <div
        id={@id}
        class={@classes}
        {st(@fixed)}
        role={@floating? && "region"}
        aria-label={@floating? && @text}
        phx-window-keydown={@on_clear}
        phx-key={@on_clear && "Escape"}
        phx-target={@on_clear && @target}
        {@rest}
      >
        <%= if @running? do %>
          <.progress_part text={@label} pct={@pct} progress={@progress} max={@progress_max} />
        <% else %>
          <b class="num">{@text}</b>
          <a
            :if={@select_all?}
            class="lu-btn link sm"
            href="#"
            phx-click={@on_select_all}
            phx-target={@target}
          >
            {@select_all_text}
          </a>
          <span class="sep"></span>
          <div :for={f <- @field}>{render_slot(f)}</div>
          <%= for a <- @acts do %>
            <span :if={a.sep_before} class="sep"></span>
            <.bar_action act={a} bar_id={@id} floating={@floating?} />
          <% end %>
          <button
            :if={@on_clear}
            aria-label={@clear_label}
            class="lu-btn icon sm ghost"
            type="button"
            phx-click={@on_clear}
            phx-target={@target}
          >
            <.icon name="x" size="md" /><kbd :if={@show_esc} class="lu-kbd">Esc</kbd>
          </button>
        <% end %>
      </div>
    <% end %>
    """
  end

  attr :text, :string, required: true
  attr :pct, :any, required: true
  attr :progress, :integer, required: true
  attr :max, :integer, required: true

  defp progress_part(assigns) do
    ~H"""
    <b>{@text}</b>
    <div
      class="lu-progress sm"
      style="flex:1;min-width:120px"
      role="progressbar"
      aria-valuemin="0"
      aria-valuemax={@max}
      aria-valuenow={@progress}
    >
      <i style={"width:#{@pct}%"}></i>
    </div>
    <span class="num">{@progress}/{@max}</span>
    """
  end

  # A button of the bar, with its confirm card when the action has `confirm`.
  defp bar_action(%{act: %{confirm: nil}} = assigns) do
    ~H"""
    <button class={@act.class} type="button" {@act.attrs}>
      <.icon :if={@act.icon} name={@act.icon} />{render_slot(@act.slot)}
    </button>
    """
  end

  defp bar_action(assigns) do
    ~H"""
    <span style="position:relative;display:inline-flex">
      <button
        class={@act.class}
        type="button"
        aria-haspopup="dialog"
        phx-click={JS.toggle(to: "#" <> @act.confirm_id)}
        {@act.base_attrs}
      >
        <.icon :if={@act.icon} name={@act.icon} />{render_slot(@act.slot)}
      </button>
      <div
        id={@act.confirm_id}
        role="alertdialog"
        aria-label={@act.confirm}
        class="lu-card"
        style={"display:none;position:absolute;right:0;z-index:60;padding:12px 14px;min-width:240px;" <> if(@floating, do: "bottom:calc(100% + 8px)", else: "top:calc(100% + 8px)")}
      >
        <b style="display:block;margin-bottom:4px">{@act.confirm}</b>
        <p :if={@act.confirm_text} class="lu-xs lu-muted" style="margin:0 0 10px">
          {@act.confirm_text}
        </p>
        <div class="lu-row" style="justify-content:flex-end;gap:8px">
          <button
            class="lu-btn sm"
            type="button"
            phx-click={JS.hide(to: "#" <> @act.confirm_id)}
          >
            {@act.cancel_label}
          </button>
          <button
            class={@act.confirm_class}
            type="button"
            {@act.confirm_attrs}
            phx-click={confirm_js(@act.confirm_id, @act.event)}
            phx-target={@act.attrs[:"phx-target"]}
            phx-disable-with={@act.attrs[:"phx-disable-with"]}
          >
            {@act.confirm_button}
          </button>
        </div>
      </div>
    </span>
    """
  end

  defp actions(assigns, inline?, last_normal) do
    assigns.action
    |> Enum.with_index()
    |> Enum.map(fn {a, i} ->
      variant = a[:variant] || "default"
      disabled? = !!a[:disabled]
      raw = Map.drop(a, @action_keys)

      attrs =
        if disabled?,
          do:
            raw
            |> Map.reject(fn {k, _} -> String.starts_with?(to_string(k), "phx-") end)
            |> Map.put(:"aria-disabled", "true"),
          else: raw

      event = raw[:"phx-click"]

      %{
        slot: a,
        icon: a[:icon],
        class: action_class(variant, inline?),
        attrs: attrs,
        base_attrs: base_attrs_of(attrs),
        event: event,
        confirm_attrs: Map.drop(base_attrs_of(attrs), [:id, :title, :"aria-label"]),
        confirm: if(disabled?, do: nil, else: a[:confirm]),
        confirm_id: "#{assigns.id}-confirm-#{i}",
        confirm_text: a[:confirm_text],
        confirm_label: a[:confirm_label],
        confirm_button: a[:confirm_label] || "OK",
        cancel_label: a[:cancel_label] || "Cancel",
        confirm_class:
          if(variant == "danger", do: "lu-btn sm danger-soft", else: "lu-btn sm primary"),
        variant: variant,
        sep_before: variant == "danger" and i > 0 and last_normal != nil
      }
    end)
  end

  defp partial?(count, total) when is_integer(count) and is_integer(total), do: count < total
  defp partial?(_, _), do: false

  defp base_attrs_of(attrs),
    do:
      Map.reject(attrs, fn {k, _} -> k in [:"phx-click", :"phx-target", :"phx-disable-with"] end)

  # Closes the confirm card, then runs the action's event (a name or a `%JS{}`).
  defp confirm_js(id, %JS{} = event), do: %JS{ops: JS.hide(to: "#" <> id).ops ++ event.ops}
  defp confirm_js(id, nil), do: JS.hide(to: "#" <> id)
  defp confirm_js(id, event), do: id |> then(&JS.hide(to: "#" <> &1)) |> JS.push(event)

  defp last_normal_index(actions) do
    actions
    |> Enum.with_index()
    |> Enum.filter(fn {a, _} -> (a[:variant] || "default") != "danger" end)
    |> List.last()
    |> case do
      nil -> nil
      {_, i} -> i
    end
  end

  defp action_class("primary", true), do: "lu-btn primary sm"
  defp action_class("danger", true), do: "lu-btn sm danger-soft"
  defp action_class(_, true), do: "lu-btn sm"
  defp action_class("primary", false), do: "lu-btn ghost sm primary"
  defp action_class(_, false), do: "lu-btn ghost sm"

  defp count_text(%{count: 1, label: label} = a), do: "#{a.count} #{label}"
  defp count_text(a), do: "#{a.count} #{a.label_plural || a.label}"

  defp fixed_style,
    do: "position:fixed;bottom:24px;left:50%;transform:translateX(-50%);z-index:50"

  # -- selection_bar ----------------------------------------------------------------------------

  attr :id, :string, default: "selection-bar"
  attr :count, :integer, required: true
  attr :label, :string, default: "selected"
  attr :label_plural, :string, default: nil
  attr :variant, :string, default: "inverse", values: ~w(inverse soft solid inline)
  attr :floating, :boolean, default: false
  attr :on_clear, :any, default: nil
  attr :clear_label, :string, default: "Clear selection"
  attr :target, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :action

  @doc "The selection pill: `bulk_bar/1` laid out in place (not floating) by default."
  def selection_bar(assigns) do
    ~H"""
    <.bulk_bar
      id={@id}
      count={@count}
      label={@label}
      label_plural={@label_plural}
      variant={@variant}
      floating={@floating}
      on_clear={@on_clear}
      clear_label={@clear_label}
      target={@target}
      class={@class}
      {@rest}
    >
      <:action :for={a <- @action} {Map.drop(a, [:__slot__, :inner_block])}>
        {render_slot(a)}
      </:action>
    </.bulk_bar>
    """
  end
end
