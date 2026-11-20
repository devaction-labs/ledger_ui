defmodule LedgerUI.Components.Drawer do
  @moduledoc """
  Side panel (`<.drawer>`) and its sheet parts (`<.sheet_header>`, `<.sheet_body>`, `<.sheet_footer>`).

      <.drawer id="customer" placement="right" size="md" title="New customer" description="Who buys from you.">
        <.form for={@form} id="customer-form" phx-submit="save">...</.form>
        <:footer>
          <.button variant="ghost" phx-click={LedgerUI.close("customer")}>Cancel</.button>
          <.button type="submit" form="customer-form" variant="primary">Save</.button>
        </:footer>
      </.drawer>

  A bare drawer is a sliding frame for a menu; with `title`, `:header` or `:footer` (or `variant`)
  it is a sheet: header, scrolling body and fixed footer. `placement="bottom"` is the phone's
  sheet (rounded top, grab handle). It opens and closes like `LedgerUI.Components.Modal`
  (`LedgerUI.open/close/toggle`, `open`, `on_open`, `on_close`) through the `LedgerUI.Overlay` hook;
  by default it does not lock the page's scroll (`lock_scroll`).

  Keep `class` and `panel_class` free of `transform`, `filter` and `contain`, so a modal rendered
  inside the drawer still covers the whole viewport.

  `inline` renders it in the page flow (a static preview, always open, without the hook).
  """
  use LedgerUI.Component
  alias LedgerUI.Components.Modal.Support

  @widths %{"sm" => 400, "md" => 520, "lg" => 640, "wide" => 800, "xl" => 1080}

  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :side, :string, default: "left", values: ~w(left right)

  attr :placement, :string,
    default: nil,
    values: [nil, "", "left", "right", "bottom"],
    doc: "The same as `side`, which it overrides when given."

  attr :size, :string, default: nil, values: [nil, "", "sm", "md", "lg", "wide", "xl"]
  attr :variant, :string, default: nil, values: [nil, "", "float", "flush"]
  attr :title, :string, default: nil
  attr :description, :string, default: nil
  attr :close_button, :boolean, default: true
  attr :close_label, :string, default: "Close"
  attr :overlay, :boolean, default: true
  attr :lock_scroll, :boolean, default: false
  attr :prevent_close, :boolean, default: false
  attr :on_open, :any, default: nil
  attr :on_close, :any, default: nil
  attr :target, :any, default: nil
  attr :class, :any, default: nil, doc: "Merged into the sliding frame."
  attr :panel_class, :any, default: nil
  attr :body_class, :any, default: nil

  attr :inline, :boolean,
    default: false,
    doc: "Static preview: in the page flow, always open, no hook."

  attr :rest, :global

  slot :actions
  slot :back

  slot :footer do
    attr :class, :any
  end

  slot :header do
    attr :class, :any
    attr :style, :string
  end

  slot :inner_block, required: true

  def drawer(assigns) do
    side = if assigns.placement in [nil, ""], do: assigns.side, else: assigns.placement
    bottom? = side == "bottom"
    flush? = assigns.variant == "flush"
    user_style = assigns.rest[:style]

    sheet? =
      assigns.title != nil or assigns.header != [] or assigns.footer != [] or
        assigns.variant not in [nil, ""] or assigns.back != [] or assigns.actions != []

    root_style =
      if assigns.inline do
        user_style
      else
        Support.style([
          "position:fixed;inset:0;z-index:var(--ledger-z-overlay,50);border-radius:0",
          !assigns.overlay && "background:transparent;pointer-events:none",
          !assigns.open && "display:none",
          user_style
        ])
      end

    panel_style =
      Support.style([
        panel_position(side, flush?),
        assigns.size not in [nil, ""] && !bottom? &&
          "width:#{@widths[assigns.size]}px;max-width:calc(100% - #{if flush?, do: 0, else: 16}px)",
        bottom? && !assigns.inline && "height:78%",
        !assigns.overlay && "pointer-events:auto"
      ])

    cfg =
      if assigns.inline,
        do: %{},
        else:
          Support.cfg("drawer",
            open: Support.flag(assigns.open),
            overlay: Support.flag(assigns.overlay),
            "prevent-close": Support.flag(assigns.prevent_close),
            "lock-scroll": Support.flag(assigns.lock_scroll),
            "on-open": Support.handler(assigns.on_open),
            "on-close": Support.handler(assigns.on_close),
            target: assigns.target
          )

    # ARIA is always rendered (also in the inline preview); only the modal behavior differs.
    panel_attrs = %{
      "role" => "dialog",
      "aria-modal" => if(!assigns.inline, do: "true"),
      "aria-labelledby" => if(assigns.title, do: assigns.id <> "-title"),
      "tabindex" => if(!assigns.inline, do: "-1")
    }

    assigns =
      assigns
      |> assign(:rest, Map.delete(assigns.rest, :style))
      |> assign(:root_style, root_style)
      |> assign(
        :panel_class_s,
        cx([
          if(bottom?, do: "lu-sheet", else: "lu-drawer"),
          flush? && !bottom? && "edge",
          assigns.class,
          assigns.panel_class
        ])
      )
      |> assign(:panel_style, panel_style)
      |> assign(:panel_attrs, panel_attrs)
      |> assign(:cfg, cfg)
      |> assign(:hook, if(assigns.inline, do: nil, else: "LedgerUI.Overlay"))
      |> assign(:bottom?, bottom?)
      |> assign(:sheet?, sheet?)
      |> assign(
        :header?,
        assigns.title != nil or assigns.header != [] or assigns.back != [] or
          assigns.actions != []
      )
      |> assign(:header_slot, List.first(assigns.header))

    ~H"""
    <div
      id={@id}
      class="lu-scrim"
      {Support.st(@root_style)}
      phx-hook={@hook}
      data-lu-overlay={!@inline && ""}
      keep-style={!@inline}
      {@cfg}
      {@rest}
    >
      <div class={@panel_class_s} {Support.st(@panel_style)} {@panel_attrs}>
        <div :if={@bottom?} class="grab"></div>
        <.sheet_header
          :if={@header?}
          id={@id <> "-title"}
          drawer={@id}
          title={@title}
          description={@description}
          close_button={@close_button}
          close_label={@close_label}
          class={@header_slot && @header_slot[:class]}
          style={@header_slot && @header_slot[:style]}
        >
          <:back :if={@back != []}>{render_slot(@back)}</:back>
          <:actions :if={@actions != []}>{render_slot(@actions)}</:actions>
          <:content :if={@header != []}>{render_slot(@header)}</:content>
        </.sheet_header>
        <.sheet_body :if={@sheet?} class={@body_class}>{render_slot(@inner_block)}</.sheet_body>
        <%= if !@sheet? do %>
          {render_slot(@inner_block)}
        <% end %>
        <.sheet_footer :for={f <- @footer} class={f[:class]}>{render_slot(f)}</.sheet_footer>
      </div>
    </div>
    """
  end

  defp panel_position("left", true), do: "right:auto;left:0;border-width:0 1px 0 0"
  defp panel_position("left", false), do: "right:auto;left:8px"
  defp panel_position(_, _), do: nil

  attr :id, :string, default: nil, doc: "The id of the title, for the drawer's `aria-labelledby`."

  attr :drawer, :string,
    default: nil,
    doc: "The id of the drawer the close button closes; the closest one when not given."

  attr :title, :string, default: nil
  attr :description, :string, default: nil
  attr :close_button, :boolean, default: true
  attr :close_label, :string, default: "Close"
  attr :class, :any, default: nil
  attr :style, :string, default: nil
  attr :rest, :global

  slot :actions
  slot :back
  slot :content

  @doc """
  The header of a sheet: title and description (or `:content`), a back arrow, buttons and the close ×.
  """
  def sheet_header(assigns) do
    close =
      if assigns.drawer,
        do: LedgerUI.close(assigns.drawer),
        else: JS.remove_class("open", to: {:closest, "[data-lu-overlay]"})

    assigns = assign(assigns, :close_js, close)

    ~H"""
    <div class={cx(["lu-modal-h", @class])} {Support.st(@style)} {@rest}>
      {render_slot(@back)}
      <%= if @content == [] do %>
        <div>
          <h3 id={@id}>{@title}</h3>
          <p :if={@description}>{@description}</p>
        </div>
      <% else %>
        {render_slot(@content)}
      <% end %>
      {render_slot(@actions)}
      <button
        :if={@close_button}
        aria-label={@close_label}
        class="lu-x"
        type="button"
        phx-click={@close_js}
      >
        <.icon name="x" size="md" />
      </button>
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "The scrolling body of a sheet: it takes the height the header and the footer leave."
  def sheet_body(assigns) do
    ~H"""
    <div class={cx(["lu-modal-b", @class])} style="flex:1;overflow:auto" {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "The footer of a sheet: the buttons, aligned to the end on a tinted bar."
  def sheet_footer(assigns) do
    ~H"""
    <div class={cx(["lu-modal-f", @class])} {@rest}>{render_slot(@inner_block)}</div>
    """
  end
end
