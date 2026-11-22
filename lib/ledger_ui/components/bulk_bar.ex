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

    * `inverse` (default), `soft` and `solid`: the selection pill (dark, accent-soft and accent).
    * `inline`: the strip at the top of a table (a panel tinted with the accent): a checkbox
      that clears the selection, the count, "select all" and the buttons.

    * `float` (the canvas template's bar): a dark pill absolutely positioned at the
      bottom center of the closest positioned ancestor (the app shell), with the count, one
      `:action` per button (`variant="danger"` is red and set apart by a rule) and the close. It
      ignores `floating`, `progress` and the `confirm` of an action (the action runs at once).

  `floating` (default) pins a pill to the bottom center of the viewport; `floating={false}` lays
  it out where it is (a bar inside a card or a toolbar). `progress`/`progress_max` turn the bar
  into a progress bar while a bulk action runs. Esc runs `on_clear` (`phx-window-keydown`).

  An `:action` with `confirm` opens a small card first (above the bar when floating, below
  otherwise); only its confirm button runs the action's `phx-click`. A `disabled` action keeps the
  focus (`aria-disabled`) and renders no `phx-*` attributes.

  Styled only with Tailwind utilities.
  """
  use LedgerUI.Component

  import LedgerUI.Components.Checkbox, only: [checkbox: 1]
  import LedgerUI.Components.Typography, only: [kbd: 1]

  alias LedgerUI.Components.Button

  # The pill: dark (`inverse`), accent-soft or accent. `btn` is the colour of its ghost buttons.
  @bar_base "flex w-max max-w-full items-center gap-2.5 rounded-lg py-2 pr-2 pl-3.5"
  @bars %{
    "inverse" => {"bg-inverse text-on-inverse shadow-lg", "text-on-inverse"},
    "soft" =>
      {"bg-accent-soft text-accent-content shadow-[0_0_0_1px_color-mix(in_oklab,var(--lu-accent)_30%,transparent),var(--lu-shadow-md)]",
       "text-accent-content"},
    "solid" => {"bg-accent-600 text-accent-foreground shadow-lg", "text-accent-foreground"}
  }
  @bar_sep "h-[22px] w-px bg-current opacity-20"

  # A `ghost` button of the pill (30px, 13px): the hover is a neutral veil that works on any fill.
  @ghost "inline-flex h-[30px] cursor-pointer items-center justify-center gap-1.5 rounded-[8px] border border-transparent bg-transparent px-2.5 text-[13px] leading-none font-medium whitespace-nowrap no-underline shadow-none transition-[background,border-color,box-shadow,transform] duration-150 hover:bg-[rgba(127,127,127,.22)] focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none active:translate-y-[.5px] [&_svg]:size-4"
  @link "inline-flex cursor-pointer items-center justify-center gap-1.5 rounded-[8px] border-0 bg-none px-2.5 text-[13px] leading-none font-medium whitespace-nowrap text-accent-content shadow-none hover:underline hover:underline-offset-[3px]"

  # The strip at the top of a table.
  @inline "flex items-center gap-2.5 rounded-lg border border-[color-mix(in_oklab,var(--lu-accent)_30%,transparent)] bg-accent-soft px-2.5 py-2"

  # The canvas template's floating bar.
  @float "absolute bottom-[22px] left-1/2 z-20 flex -translate-x-1/2 items-center gap-1.5 rounded-[14px] bg-inverse py-1.5 pr-1.5 pl-3.5 text-[13.5px] whitespace-nowrap text-panel shadow-[0_16px_40px_rgba(0,0,0,.25)]"
  @float_btn "inline-flex h-8 cursor-pointer items-center gap-1.5 rounded-[9px] border-0 bg-transparent px-2.5 [font:inherit] hover:bg-white/10 dark:hover:bg-black/[.08]"
  @float_sep "mx-1 h-5 w-px bg-white/[.18] dark:bg-black/15"
  @float_danger "text-[#ff9b8f] dark:text-[#c4321f]"

  # The card that asks to confirm an action.
  @confirm "absolute right-0 z-[60] hidden min-w-[240px] rounded-xl border border-line bg-tray px-3.5 py-3"

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
    {bar_look, _btn} = @bars[assigns.variant] || @bars["inverse"]

    assigns =
      assigns
      |> assign(:inline?, inline?)
      |> assign(:floating?, floating?)
      |> assign(:text, count_text(assigns))
      |> assign(:running?, assigns.progress != nil and assigns.progress_max != nil)
      |> assign(:acts, actions(assigns, last_normal))
      |> assign(
        :select_all?,
        assigns.on_select_all != nil and partial?(assigns.count, assigns.total)
      )
      |> assign(
        :select_all_text,
        String.replace(assigns.select_all_label, "%{total}", to_string(assigns.total))
      )
      |> assign(
        :classes,
        cx([
          @bar_base,
          bar_look,
          floating? && "fixed bottom-6 left-1/2 z-50 -translate-x-1/2",
          assigns.class
        ])
      )
      |> assign(
        :pct,
        assigns.progress_max && assigns.progress_max > 0 &&
          min(round((assigns.progress || 0) / assigns.progress_max * 100), 100)
      )
      |> assign(:all?, is_integer(assigns.total) and not partial?(assigns.count, assigns.total))
      |> assign(:partial?, partial?(assigns.count, assigns.total))
      |> assign(:link_class, @link)
      |> assign(:ghost_class, [@ghost, bar_btn(assigns.variant)])
      |> assign(:icon_class, [@ghost, bar_btn(assigns.variant), "w-[30px] px-0"])
      |> assign(:float_btn, @float_btn)
      |> assign(:float, @float)
      |> assign(:float_sep, @float_sep)
      |> assign(:float_danger, @float_danger)
      |> assign(:inline, @inline)
      |> assign(:sep_class, @bar_sep)

    ~H"""
    <%= if @variant == "float" do %>
      <div
        id={@id}
        data-part="bulk-bar"
        class={cx([@float, @class])}
        role="region"
        aria-label={@text}
        phx-window-keydown={@on_clear}
        phx-key={@on_clear && "Escape"}
        phx-target={@on_clear && @target}
        {@rest}
      >
        <b data-part="bulk-bar-count" class="mr-2 font-semibold">{@text}</b>
        <div :for={f <- @field} data-part="bulk-bar-field">{render_slot(f)}</div>
        <%= for a <- @acts do %>
          <span :if={a.sep_before} data-part="bulk-bar-separator" class={@float_sep}></span>
          <button
            type="button"
            data-part="bulk-bar-action"
            class={[@float_btn, if(a.variant == "danger", do: @float_danger, else: "text-inherit")]}
            {a.attrs}
          >
            <.icon :if={a.icon} name={a.icon} />{render_slot(a.slot)}
          </button>
        <% end %>
        <button
          :if={@on_clear}
          type="button"
          data-part="bulk-bar-clear"
          class={[@float_btn, "text-inherit"]}
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
        data-part="bulk-bar"
        class={cx([@inline, @class])}
        phx-window-keydown={@on_clear}
        phx-key={@on_clear && "Escape"}
        phx-target={@on_clear && @target}
        {@rest}
      >
        <.checkbox
          id={@id <> "-check"}
          color="primary"
          aria-label={@check_label}
          checked={@all?}
          indeterminate={@partial?}
          phx-click={@on_clear}
          phx-target={@on_clear && @target}
        />
        <%= if @running? do %>
          <.progress_part text={@text} pct={@pct} progress={@progress} max={@progress_max} />
        <% else %>
          <b data-part="bulk-bar-count" class="tabular-nums">{@text}</b>
          <a
            :if={@select_all?}
            data-part="bulk-bar-select-all"
            class={@link_class}
            href="#"
            phx-click={@on_select_all}
            phx-target={@target}
          >
            {@select_all_text}
          </a>
          <span data-part="bulk-bar-spacer" class="min-w-0 flex-1"></span>
          <div :for={f <- @field} data-part="bulk-bar-field">{render_slot(f)}</div>
          <.bar_action :for={a <- @acts} act={a} bar_id={@id} floating={false} />
        <% end %>
      </div>
    <% end %>
    <%= if !@inline? and @variant != "float" do %>
      <div
        id={@id}
        data-part="bulk-bar"
        class={@classes}
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
          <b data-part="bulk-bar-count" class="tabular-nums">{@text}</b>
          <a
            :if={@select_all?}
            data-part="bulk-bar-select-all"
            class={@link_class}
            href="#"
            phx-click={@on_select_all}
            phx-target={@target}
          >
            {@select_all_text}
          </a>
          <span data-part="bulk-bar-separator" class={@sep_class}></span>
          <div :for={f <- @field} data-part="bulk-bar-field">{render_slot(f)}</div>
          <%= for a <- @acts do %>
            <span :if={a.sep_before} data-part="bulk-bar-separator" class={@sep_class}></span>
            <.bar_action act={a} bar_id={@id} floating={@floating?} />
          <% end %>
          <button
            :if={@on_clear}
            data-part="bulk-bar-clear"
            aria-label={@clear_label}
            class={@icon_class}
            type="button"
            phx-click={@on_clear}
            phx-target={@target}
          >
            <.icon name="x" size="md" /><.kbd :if={@show_esc}>Esc</.kbd>
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
    <b data-part="bulk-bar-count">{@text}</b>
    <div
      data-part="bulk-bar-progress"
      class="h-1 min-w-[120px] flex-1 overflow-hidden rounded-[4px] bg-sunken"
      role="progressbar"
      aria-valuemin="0"
      aria-valuemax={@max}
      aria-valuenow={@progress}
    >
      <i
        data-part="bulk-bar-progress-bar"
        class="block h-full rounded-[4px] bg-accent-500"
        style={"width:#{@pct}%"}
      ></i>
    </div>
    <span data-part="bulk-bar-progress-text" class="tabular-nums">{@progress}/{@max}</span>
    """
  end

  # A button of the bar, with its confirm card when the action has `confirm`.
  defp bar_action(%{act: %{confirm: nil}} = assigns) do
    ~H"""
    <button data-part="bulk-bar-action" class={@act.class} type="button" {@act.attrs}>
      <.icon :if={@act.icon} name={@act.icon} />{render_slot(@act.slot)}
    </button>
    """
  end

  defp bar_action(assigns) do
    assigns = assign(assigns, :confirm_card, @confirm)

    ~H"""
    <span data-part="bulk-bar-confirm-wrap" class="relative inline-flex">
      <button
        data-part="bulk-bar-action"
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
        data-part="bulk-bar-confirm"
        role="alertdialog"
        aria-label={@act.confirm}
        class={[
          @confirm_card,
          if(@floating, do: "bottom-[calc(100%+8px)]", else: "top-[calc(100%+8px)]")
        ]}
      >
        <b data-part="bulk-bar-confirm-title" class="mb-1 block">{@act.confirm}</b>
        <p
          :if={@act.confirm_text}
          data-part="bulk-bar-confirm-text"
          class="m-0 mb-2.5 text-xs/4 text-muted"
        >
          {@act.confirm_text}
        </p>
        <div
          data-part="bulk-bar-confirm-actions"
          class="flex flex-wrap items-center justify-end gap-2"
        >
          <button
            data-part="bulk-bar-cancel"
            class={@act.cancel_class}
            type="button"
            phx-click={JS.hide(to: "#" <> @act.confirm_id)}
          >
            {@act.cancel_label}
          </button>
          <button
            data-part="bulk-bar-confirm-button"
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

  defp actions(assigns, last_normal) do
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
        class: action_class(variant, assigns.variant),
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
        cancel_class: Button.canvas_classes("sm", "default"),
        confirm_class:
          Button.canvas_classes("sm", if(variant == "danger", do: "danger-soft", else: "primary")),
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

  # The buttons of the strip are canvas buttons; those of the pill are ghost buttons in its colour.
  defp action_class("primary", "inline"), do: Button.canvas_classes("sm", "primary")
  defp action_class("danger", "inline"), do: Button.canvas_classes("sm", "danger-soft")
  defp action_class(_, "inline"), do: Button.canvas_classes("sm", "default")
  defp action_class(_, variant), do: [@ghost, bar_btn(variant)]

  defp bar_btn(variant), do: elem(@bars[variant] || @bars["inverse"], 1)

  defp count_text(%{count: 1, label: label} = a), do: "#{a.count} #{label}"
  defp count_text(a), do: "#{a.count} #{a.label_plural || a.label}"
end
