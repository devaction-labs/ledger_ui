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
    * `inline`: the strip at the top of a table (a panel tinted with the accent, no wrap), in
      this order: an indeterminate checkbox that clears the selection, the count, "select all", a
      rule, the `:field`s, the actions, a rule and a close (`clear_label` as `aria-label` and
      `title`; only with `on_clear`). Every `:action` is a ghost button (no border); `danger` (or
      `neg`) is ghost with the negative colour (`data-neg`). A `:field` is ghost too: the strip
      strips border, fill and shadow from the buttons inside it (not from `role="menuitem"`), so a
      dropdown toggle looks ghost; if the control is not a plain button, pass `variant="ghost"`
      to the inner `<.button>`.

    * `float` (the canvas template's bar): a dark pill absolutely positioned at the
      bottom center of the closest positioned ancestor (the app shell), with the count, one
      `:action` per button (`variant="danger"` is red and set apart by a rule) and the close. It
      ignores `floating`, `progress` and the `confirm` of an action (the action runs at once).

  An `:action` takes `variant` `default`, `primary`, `danger`, `ghost` or `neg` in every look
  (`ghost` is the same as `default`, `neg` the same as `danger`: the pills keep their ghost
  buttons, the `danger` one set apart by a rule).

  `canvas` (default `false`) gives the `inverse`/`soft`/`solid` pill the canvas look (`np-bulkf`):
  a leading indeterminate checkbox (accent-500, a dash; it clears the selection, `check_label` as
  `aria-label`), rules between the count/"select all", the fields/actions and the close, "select
  all" in accent-300, a `danger` action with the negative colour and no line wrap. The close
  button has `clear_label` as `title` in every look.

  A floating pill is centred at `left: 50%` plus `margin-left: var(--lu-bulk-offset, 0px)`. `offset` (an
  integer, in px) sets that variable on the bar, so the app can centre it in the content area
  (`offset={136}` beside a 272px sidebar, `offset={-74}` with the assistant panel open); an app
  can also set `--lu-bulk-offset` in its own CSS. Default: `0`, the bar stays at the viewport centre.

  `offset="auto"` centres the pill on the main area of the `shell` with CSS only: it sits at
  `left: calc(50% + (var(--lu-sidebar-w, 0px) - var(--lu-aside-w, 0px)) / 2)`, and the shell sets
  `--lu-sidebar-w` to the current width of its menu (open, closed or collapsed; see
  `LedgerUI.Components.Shell`). A right panel the app docks sets `--lu-aside-w`. Outside a shell
  both fall back to `0px`: the plain centre.

  `floating` (default) pins a pill to the bottom center of the viewport; `floating={false}` lays
  it out where it is (a bar inside a card or a toolbar). `progress`/`progress_max` turn the bar
  into a progress bar while a bulk action runs. Esc runs `on_clear` (`phx-window-keydown`).

  An `:action` with `confirm` opens a small card first (above the bar when floating, below
  otherwise); only its confirm button runs the action's `phx-click`. A `disabled` action keeps the
  focus (`aria-disabled`) and renders no `phx-*` attributes.

  ## Optimistic count (`for`)

  `for` is the DOM id of the `<.table>`/`<.card_table>` the bar belongs to. The table sends a
  `lu:selection` DOM event on each click of a checkbox (`detail: {id, count, delta, ids}`: `count`
  and `ids` are the checked rows of the page, `delta` how many rows differ from what the server
  last rendered); the bar (`LedgerUI.BulkBar` hook) shows `count + delta` in the browser at once:
  it appears with the first selection, its text follows and it hides when the last one is
  cleared. The server prevails: its `count` is what the bar rebuilds from on every patch, and when
  the server answered and kept the old selection the table settles back and so does the bar. Where
  the server confirms the number already shown nothing is touched (no flicker).

  Without `for` nothing changes: the bar renders only while `count` is above zero. With `for` it is
  always rendered, `hidden` (and `data-lu-empty`) while `count` is zero, so the browser has
  something to show. Its count text is the one of `label`/`label_plural` (`data-lu-one`,
  `data-lu-many`); the "select all" link and the progress state come from the server only.

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
  # `offset="auto"`: centred on the shell's main area (the shell sets `--lu-sidebar-w`).
  @auto_float "fixed bottom-6 left-[calc(50%_+_(var(--lu-sidebar-w,0px)_-_var(--lu-aside-w,0px))_/_2)] z-50 -translate-x-1/2"
  @bar_sep "h-[22px] w-px bg-current opacity-20"

  # A `ghost` button of the pill (30px, 13px): the hover is a neutral veil that works on any fill.
  @ghost "inline-flex h-[30px] cursor-pointer items-center justify-center gap-1.5 rounded-md border border-transparent bg-transparent px-2.5 text-[13px] leading-none font-medium whitespace-nowrap no-underline shadow-none transition-[background,border-color,box-shadow,transform] duration-150 hover:bg-[rgba(127,127,127,.22)] focus-visible:shadow-[0_0_0_3px_var(--lu-focus)] focus-visible:outline-none active:translate-y-[.5px] [&_svg]:size-4"
  @link_canvas "inline-flex cursor-pointer items-center justify-center gap-1.5 rounded-md border-0 bg-none px-2.5 text-[13px] leading-none font-medium whitespace-nowrap text-accent-300 shadow-none hover:underline hover:underline-offset-[3px]"
  @canvas_check "[&_input]:border-accent-500 [&_input]:bg-accent-500 [&_input[data-ind]]:border-accent-500 [&_input[data-ind]]:bg-accent-500"
  @link "inline-flex cursor-pointer items-center justify-center gap-1.5 rounded-md border-0 bg-none px-2.5 text-[13px] leading-none font-medium whitespace-nowrap text-accent-content shadow-none hover:underline hover:underline-offset-[3px]"

  # The strip at the top of a table.
  @inline "flex flex-nowrap items-center gap-2.5 rounded-lg border border-[color-mix(in_oklab,var(--lu-accent)_30%,transparent)] bg-accent-soft py-1.5 pr-1.5 pl-3 whitespace-nowrap"
  @inline_count "text-[13.5px] font-semibold text-ink tabular-nums"
  @inline_sep "h-[22px] w-px shrink-0 bg-line-strong"
  # A `:field` in the strip looks ghost: its toggle button loses border, fill and shadow (the
  # menu items of an open overlay are left alone).
  @inline_field "[&_button:not([role=menuitem])]:border-transparent [&_button:not([role=menuitem])]:bg-transparent [&_button:not([role=menuitem])]:shadow-none"
  # A `:field` in the pill: the same ghost, in the pill's colour and with its translucent hover.
  @pill_field "[&_button:not([role=menuitem])]:border-transparent [&_button:not([role=menuitem])]:bg-transparent [&_button:not([role=menuitem])]:shadow-none [&_button:not([role=menuitem]):hover]:bg-[rgba(127,127,127,.22)]"

  # The canvas template's floating bar.
  @float "absolute bottom-[22px] left-1/2 z-20 flex -translate-x-1/2 items-center gap-1.5 rounded-xl bg-inverse py-1.5 pr-1.5 pl-3.5 text-[13.5px] whitespace-nowrap text-panel shadow-[0_16px_40px_rgba(0,0,0,.25)]"
  # Automatic loading state of the action buttons (#74): LiveView puts `phx-click-loading` on the
  # clicked button until the server replies.
  @act_loading "[&.phx-click-loading]:pointer-events-none [&.phx-click-loading]:cursor-progress [&.phx-click-loading]:opacity-60"
  @float_btn "inline-flex h-8 cursor-pointer items-center gap-1.5 rounded-md border-0 bg-transparent px-2.5 [font:inherit] hover:bg-white/10 dark:hover:bg-black/[.08]"
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

  attr :for, :string,
    default: nil,
    doc:
      "DOM id of the table this bar belongs to: the bar shows the table's selection at once (`lu:selection`), the server's `count` confirms or corrects it. Always rendered (`hidden` at zero)."

  attr :count, :integer,
    required: true,
    doc: "How many are selected; the bar shows only above zero."

  attr :label, :string, default: nil, doc: "The text after the count, for one selected."
  attr :label_plural, :string, default: nil
  attr :total, :integer, default: nil, doc: "How many there are in all (every page)."
  attr :select_all_label, :string, default: nil
  attr :on_clear, :any, default: nil
  attr :on_select_all, :any, default: nil
  attr :target, :any, default: nil
  attr :clear_label, :string, default: nil
  attr :check_label, :string, default: nil, doc: "`aria-label` of the `inline` checkbox."
  attr :show_esc, :boolean, default: false
  attr :variant, :string, default: "inverse", values: ~w(inverse soft solid inline float)
  attr :floating, :boolean, default: true

  attr :canvas, :boolean,
    default: false,
    doc: "Canvas look of the pill (checkbox, rules, accent-300 select all, negative danger)."

  attr :offset, :any,
    default: nil,
    doc:
      "Horizontal shift of the floating pill: an integer in px (`--lu-bulk-offset`), or `\"auto\"` to centre it on the shell's main area; default 0."

  attr :progress, :integer, default: nil
  attr :progress_max, :integer, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :action, doc: "A button." do
    attr :variant, :string, values: ~w(default primary danger ghost neg)
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

  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def bulk_bar(%{count: count, for: nil} = assigns) when count <= 0 do
    ~H""
  end

  def bulk_bar(%{offset: offset})
      when not is_nil(offset) and not is_integer(offset) and offset != "auto" do
    raise ArgumentError,
          "bulk_bar offset must be an integer (px) or \"auto\", got: #{inspect(offset)}"
  end

  def bulk_bar(assigns) do
    changed0 = assigns.__changed__
    assigns = bulk_texts(assigns)
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
          floating? && assigns.offset == "auto" && @auto_float,
          floating? && assigns.offset != "auto" &&
            "fixed bottom-6 left-1/2 z-50 ml-[var(--lu-bulk-offset,0px)] -translate-x-1/2",
          assigns.canvas && "flex-nowrap whitespace-nowrap",
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
      |> assign(:all_class, if(assigns.canvas, do: @link_canvas, else: @link))
      |> assign(
        :offset_attrs,
        if(is_integer(assigns.offset),
          do: %{style: "--lu-bulk-offset:#{assigns.offset}px"},
          else: %{}
        )
      )
      |> assign(:check_class, @canvas_check)
      |> assign(:ghost_class, [@ghost, bar_btn(assigns.variant)])
      |> assign(:icon_class, [@ghost, bar_btn(assigns.variant), "w-[30px] px-0"])
      |> assign(:float_btn, @float_btn)
      |> assign(:act_loading, @act_loading)
      |> assign(:float, @float)
      |> assign(:float_sep, @float_sep)
      |> assign(:float_danger, @float_danger)
      |> assign(:inline, @inline)
      |> assign(:sep_class, @bar_sep)
      |> assign(:inline_count, @inline_count)
      |> assign(:inline_sep, @inline_sep)
      |> assign(:inline_field, @inline_field)
      |> assign(:pill_field, [@pill_field, pill_field_color(assigns.variant)])
      |> assign(:inline_icon, Button.canvas_classes("sm", "ghost", true))
      |> assign(:opt, opt_attrs(assigns))

    # A new count must not send the classes again. `text`, `acts` (the actions' texts), the
    # select-all text and `opt` read the locale or the count: they are sent every time.
    assigns =
      settle(assigns, changed0,
        inline?: [:variant],
        floating?: [:floating, :variant],
        running?: [:progress, :progress_max],
        classes: [:variant, :floating, :offset, :canvas, :class],
        pct: [:progress, :progress_max],
        all?: [:total, :count],
        partial?: [:count, :total],
        link_class: [],
        all_class: [:canvas],
        offset_attrs: [:offset],
        check_class: [],
        ghost_class: [:variant],
        icon_class: [:variant],
        float_btn: [],
        act_loading: [],
        float: [],
        float_sep: [],
        float_danger: [],
        inline: [],
        sep_class: [],
        inline_count: [],
        inline_sep: [],
        inline_field: [],
        pill_field: [:variant],
        inline_icon: []
      )

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
        {@opt}
        {@rest}
      >
        <b data-part="bulk-bar-count" class="mr-2 font-semibold">{@text}</b>
        <div :for={f <- @field} data-part="bulk-bar-field">{render_slot(f)}</div>
        <%= for a <- @acts do %>
          <span :if={a.sep_before} data-part="bulk-bar-separator" class={@float_sep}></span>
          <button
            type="button"
            data-part="bulk-bar-action"
            class={[
              @float_btn,
              @act_loading,
              if(a.variant == "danger", do: @float_danger, else: "text-inherit")
            ]}
            {a.attrs}
          >
            <.icon :if={a.icon} name={a.icon} />{render_slot_full(a.slot)}
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
        {@opt}
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
          <b data-part="bulk-bar-count" class={@inline_count}>{@text}</b>
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
          <span
            :if={@field != [] or @acts != []}
            data-part="bulk-bar-separator"
            class={@inline_sep}
          ></span>
          <div :for={f <- @field} data-part="bulk-bar-field" class={@inline_field}>
            {render_slot(f)}
          </div>
          <.bar_action :for={a <- @acts} act={a} bar_id={@id} floating={false} />
          <span :if={@on_clear} data-part="bulk-bar-separator" class={@inline_sep}></span>
          <button
            :if={@on_clear}
            data-part="bulk-bar-clear"
            type="button"
            class={@inline_icon}
            aria-label={@clear_label}
            title={@clear_label}
            phx-click={@on_clear}
            phx-target={@target}
          >
            <.icon name="x" size="md" />
          </button>
        <% end %>
      </div>
    <% end %>
    <%= if !@inline? and @variant != "float" do %>
      <div
        id={@id}
        data-part="bulk-bar"
        class={@classes}
        {@offset_attrs}
        role={@floating? && "region"}
        aria-label={@floating? && @text}
        phx-window-keydown={@on_clear}
        phx-key={@on_clear && "Escape"}
        phx-target={@on_clear && @target}
        {@opt}
        {@rest}
      >
        <%= if @running? do %>
          <.progress_part text={@label} pct={@pct} progress={@progress} max={@progress_max} />
        <% else %>
          <.checkbox
            :if={@canvas}
            id={@id <> "-check"}
            color="primary"
            class={@check_class}
            aria-label={@check_label}
            checked={@all?}
            indeterminate={@partial?}
            phx-click={@on_clear}
            phx-target={@on_clear && @target}
          />
          <b data-part="bulk-bar-count" class="tabular-nums">{@text}</b>
          <a
            :if={@select_all?}
            data-part="bulk-bar-select-all"
            class={@all_class}
            href="#"
            phx-click={@on_select_all}
            phx-target={@target}
          >
            {@select_all_text}
          </a>
          <span data-part="bulk-bar-separator" class={@sep_class}></span>
          <div :for={f <- @field} data-part="bulk-bar-field" class={@pill_field}>
            {render_slot(f)}
          </div>
          <%= for a <- @acts do %>
            <span :if={a.sep_before} data-part="bulk-bar-separator" class={@sep_class}></span>
            <.bar_action act={a} bar_id={@id} floating={@floating?} />
          <% end %>
          <span :if={@canvas and @on_clear} data-part="bulk-bar-separator" class={@sep_class}></span>
          <button
            :if={@on_clear}
            data-part="bulk-bar-clear"
            aria-label={@clear_label}
            title={@clear_label}
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
    assigns = assign(assigns, :act_loading, @act_loading)

    ~H"""
    <button
      data-part="bulk-bar-action"
      class={[@act.class, @act_loading]}
      type="button"
      data-neg={@act.neg_inline || nil}
      {@act.attrs}
    >
      <.icon :if={@act.icon} name={@act.icon} />{render_slot_full(@act.slot)}
    </button>
    """
  end

  defp bar_action(assigns) do
    assigns = assign(assigns, confirm_card: @confirm, act_loading: @act_loading)

    ~H"""
    <span data-part="bulk-bar-confirm-wrap" class="relative inline-flex">
      <button
        data-part="bulk-bar-action"
        class={[@act.class, @act_loading]}
        type="button"
        aria-haspopup="dialog"
        data-neg={@act.neg_inline || nil}
        phx-click={JS.toggle(to: "#" <> @act.confirm_id)}
        {@act.base_attrs}
      >
        <.icon :if={@act.icon} name={@act.icon} />{render_slot_full(@act.slot)}
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
            class={[@act.confirm_class, @act_loading]}
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
      raw_variant = a[:variant] || "default"
      # `ghost` is the plain look; `neg` is `danger`.
      variant =
        case raw_variant do
          "neg" -> "danger"
          "ghost" -> "default"
          v -> v
        end

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
        class: action_class(variant, assigns.variant, assigns.canvas),
        neg_inline: assigns.variant == "inline" and variant == "danger",
        attrs: attrs,
        base_attrs: base_attrs_of(attrs),
        event: event,
        confirm_attrs: Map.drop(base_attrs_of(attrs), [:id, :title, :"aria-label"]),
        confirm: if(disabled?, do: nil, else: a[:confirm]),
        confirm_id: "#{assigns.id}-confirm-#{i}",
        confirm_text: a[:confirm_text],
        confirm_label: a[:confirm_label],
        confirm_button: a[:confirm_label] || I18n.t("common.ok", assigns.locale),
        cancel_label: a[:cancel_label] || I18n.t("common.cancel", assigns.locale),
        cancel_class: Button.canvas_classes("sm", "default"),
        confirm_class:
          Button.canvas_classes("sm", if(variant == "danger", do: "danger-soft", else: "primary")),
        variant: variant,
        sep_before: variant == "danger" and i > 0 and last_normal != nil
      }
    end)
  end

  # The optimistic link (`for`): the hook, the table id, the server's count and the labels for the
  # text the hook writes; `hidden` while there is nothing selected.
  defp opt_attrs(%{for: nil}), do: %{}

  defp opt_attrs(a) do
    %{
      "phx-hook": "LedgerUI.BulkBar",
      "data-lu-for": a.for,
      "data-lu-count": a.count,
      "data-lu-one": a.label,
      "data-lu-many": a.label_plural || a.label,
      hidden: a.count <= 0,
      "data-lu-empty": a.count <= 0
    }
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
    |> Enum.filter(fn {a, _} -> (a[:variant] || "default") not in ["danger", "neg"] end)
    |> List.last()
    |> case do
      nil -> nil
      {_, i} -> i
    end
  end

  # The buttons of the strip are canvas buttons; those of the pill are ghost buttons in its colour.
  defp action_class("danger", "inline", _), do: Button.canvas_classes("sm", "ghost-neg")
  defp action_class(_, "inline", _), do: Button.canvas_classes("sm", "ghost")
  defp action_class("danger", _variant, true), do: [@ghost, "text-neg"]
  defp action_class(_, variant, _), do: [@ghost, bar_btn(variant)]

  # `bar_btn/1` as a descendant utility: a toggle's own `text-ink` must not win in dark theme.
  defp pill_field_color("soft"), do: "[&_button:not([role=menuitem])]:text-accent-content"
  defp pill_field_color("solid"), do: "[&_button:not([role=menuitem])]:text-accent-foreground"
  defp pill_field_color(_), do: "[&_button:not([role=menuitem])]:text-on-inverse"

  defp bar_btn(variant), do: elem(@bars[variant] || @bars["inverse"], 1)

  defp bulk_texts(assigns) do
    assigns =
      if assigns.label == nil and assigns.label_plural == nil,
        do: %{assigns | label_plural: I18n.t("bulk_bar.selected_plural", assigns.locale)},
        else: assigns

    I18n.texts(assigns,
      label: "bulk_bar.selected",
      select_all_label: "bulk_bar.select_all",
      clear_label: "bulk_bar.clear",
      check_label: "bulk_bar.selection"
    )
  end

  defp count_text(%{count: 1, label: label} = a), do: "#{a.count} #{label}"
  defp count_text(a), do: "#{a.count} #{a.label_plural || a.label}"
end
