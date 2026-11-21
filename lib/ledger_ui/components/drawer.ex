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

  The title is either `title="New customer"` or the `<:title>` slot (markup).

  A bare drawer is a sliding frame for a menu; with `title`, `:header` or `:footer` (or `variant`)
  it is a sheet: header, scrolling body and fixed footer. `placement="bottom"` is the phone's
  sheet (rounded top, grab handle). It opens and closes like `LedgerUI.Components.Modal`
  (`LedgerUI.open/close/toggle`, `open`, `on_open`, `on_close`) through the `LedgerUI.Overlay` hook;
  by default it does not lock the page's scroll (`lock_scroll`).

  Keep `class` and `panel_class` free of `transform`, `filter` and `contain`, so a modal rendered
  inside the drawer still covers the whole viewport.

  `layout="page"` is the sheet of the app templates: it renders only while `open`, as a dim
  `lu-overlay` and an `aside.lu-drawer` laid over the closest positioned ancestor (the app shell),
  with no hook; the page owns the state. The overlay, the Esc key and the × push `on_close`. The
  `:header` slot is then the content before the ×, `:footer` the `<footer>`:

      <.drawer :if={@order} id="order" layout="page" open on_close="close_order">
        <:header><div><h3>Pedido #2495</h3><p>Criado hoje</p></div></:header>
        ...body...
        <:footer><.button>Imprimir</.button></:footer>
      </.drawer>

  `inline` renders it in the page flow (a static preview, always open, without the hook).
  """
  use LedgerUI.Component
  alias LedgerUI.Components.Modal.Support

  @width_class %{
    "sm" => "w-[400px]",
    "md" => "w-[520px]",
    "lg" => "w-[640px]",
    "wide" => "w-[800px]",
    "xl" => "w-[1080px]"
  }

  # the backdrop: closed = `hidden`; open (the `open` class LedgerUI.open sets, or data-state="open") and
  # closing (the hook plays the leave animation while it is `closing`) are `flex`
  @scrim_hooked "fixed inset-0 z-[var(--ledger-z-overlay,50)] hidden items-center justify-center overflow-hidden rounded-none p-7 " <>
                  "data-[state=open]:flex data-[state=closing]:pointer-events-none data-[state=closing]:flex [&.open]:flex"
  @scrim_inline "relative flex items-center justify-center overflow-hidden rounded-lg bg-overlay p-7"

  # the sliding frame: a side panel (`lu-drawer`) or the bottom sheet; the hook slides it with `translate`
  @panel "absolute z-[41] flex flex-col overflow-hidden border border-line bg-panel shadow-[0_30px_80px_rgba(0,0,0,.22),0_2px_8px_rgba(0,0,0,.08)]"
  @sheet "absolute inset-x-2 bottom-2 rounded-xl border border-line bg-panel shadow-lg"
  # side x (floating | flush against the edge)
  @position %{
    {"right", false} => "top-3 right-3 bottom-3 rounded-[18px]",
    {"right", true} => "inset-y-0 right-0 rounded-none border-0 border-l",
    {"left", false} => "top-3 bottom-3 left-2 rounded-[18px]",
    {"left", true} => "inset-y-0 left-0 rounded-none border-0 border-r"
  }

  # sheet header / body / footer (the canvas' modal parts)
  @header "flex items-start gap-3 px-5 pt-5 pb-1.5"
  @title "m-0 text-[18px]/[26px] font-semibold tracking-[-.01em]"
  @desc "mt-1 mb-0 text-[14px] text-muted"
  @body "flex flex-1 flex-col gap-3.5 overflow-auto px-5 py-3.5"
  @footer "flex justify-end gap-2 border-t border-line bg-tray px-5 py-3.5"
  @x "grid size-8 ml-auto flex-none cursor-pointer place-items-center rounded-[9px] border-0 bg-transparent text-muted hover:bg-hover hover:text-ink"

  # `layout="page"`: the sheet of the app templates
  @overlay "absolute inset-0 z-40 bg-[rgba(12,14,14,.38)] backdrop-blur-[2px] dark:bg-[rgba(0,0,0,.55)]"
  @page_panel "absolute top-3 right-3 bottom-3 z-[41] flex w-[500px] max-w-[80%] flex-col overflow-hidden rounded-[18px] border border-line bg-panel " <>
                "shadow-[0_30px_80px_rgba(0,0,0,.22),0_2px_8px_rgba(0,0,0,.08)] [&>[data-part=drawer-body]>*]:shrink-0"
  @page_header "flex items-start gap-3 px-[22px] pt-5 pb-3.5 [&_h3]:m-0 [&_h3]:font-display [&_h3]:text-[18px] [&_h3]:font-[650] [&_h3]:tracking-[-.02em] " <>
                 "[&_p]:mt-[3px] [&_p]:mb-0 [&_p]:text-[13.5px] [&_p]:text-muted"
  @page_body "flex flex-1 flex-col gap-[18px] overflow-auto px-[22px] pt-1 pb-5"
  @page_footer "flex items-center justify-end gap-2 border-t border-line bg-panel px-[22px] py-3.5"

  # the vitrine's timings: the backdrop fades .22s, the drawer slides .32s on cubic-bezier(.2,.8,.2,1);
  # leaving mirrors entering
  @fade "transition-opacity duration-[220ms] ease"
  @slide "transition-transform duration-[320ms] ease-[cubic-bezier(.2,.8,.2,1)]"
  @off "[transform:translateX(calc(100%+24px))]"
  @on "[transform:translateX(0)]"

  attr :id, :string, required: true
  attr :open, :boolean, default: false

  attr :layout, :string,
    default: nil,
    values: [nil, "", "page"],
    doc:
      "`page`: the canvas-v2 sheet (a dim overlay + an `aside` panel with `header`, `.bd`, `footer`), " <>
        "shown only while `open` and closed by `on_close` (a LiveView event or `%JS{}`)."

  attr :side, :string, default: "left", values: ~w(left right)

  attr :placement, :string,
    default: nil,
    values: [nil, "", "left", "right", "bottom"],
    doc: "The same as `side`, which it overrides when given."

  attr :size, :string, default: nil, values: [nil, "", "sm", "md", "lg", "wide", "xl"]
  attr :variant, :string, default: nil, values: [nil, "", "float", "flush"]
  attr :description, :string, default: nil
  attr :close_button, :boolean, default: true
  attr :close_label, :string, default: "Close"

  attr :floating, :boolean,
    default: false,
    doc:
      "A sheet that floats with margins around it, the look of `variant=\"float\"`; makes a bare drawer a sheet."

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

  slot :title,
    doc:
      "The sheet's title (the `title=\"...\"` attribute, a plain string, does the same); draws the header."

  slot :footer do
    attr :class, :any
  end

  slot :header do
    attr :class, :any
    attr :style, :string
  end

  slot :inner_block, required: true

  def drawer(assigns) do
    # `title` is a slot, and the string form is a global HTML attribute
    {text, slot, rest} = Support.split_title(assigns)

    assigns
    |> assign(:rest, rest)
    |> assign(:title_text, text)
    |> assign(:title, slot)
    |> assign(:titled?, text != nil or slot != [])
    |> render_drawer()
  end

  attr :id, :string, required: true
  attr :title, :list, default: []
  attr :text, :string, default: nil
  attr :description, :string, default: nil
  attr :h_class, :string, default: nil
  attr :p_class, :string, default: nil

  defp title_content(assigns) do
    ~H"""
    <div data-part="drawer-heading">
      <h3 id={@id} data-part="drawer-title" class={@h_class}>
        {if @title != [], do: render_slot(@title), else: @text}
      </h3>
      <p :if={@description} data-part="drawer-description" class={@p_class}>{@description}</p>
    </div>
    """
  end

  defp render_drawer(%{layout: "page"} = assigns) do
    assigns =
      assigns
      |> assign(:overlay_class, @overlay)
      |> assign(:panel_class, cx([@page_panel, assigns.class]))
      |> assign(:header_class, @page_header)
      |> assign(:body_class_s, cx([@page_body, assigns.body_class]))
      |> assign(:footer_class, @page_footer)
      |> assign(:x_class, @x)
      |> assign(:overlay_enter, JS.transition({@fade, "opacity-0", "opacity-100"}, time: 220))
      |> assign(
        :overlay_leave,
        JS.hide(transition: {@fade, "opacity-100", "opacity-0"}, time: 220)
      )
      |> assign(
        :enter,
        JS.transition(JS.focus_first(to: "#" <> assigns.id), {@slide, @off, @on}, time: 320)
      )
      |> assign(:leave, JS.hide(transition: {@slide, @on, @off}, time: 320))

    ~H"""
    <div
      :if={@open}
      data-part="drawer-overlay"
      class={@overlay_class}
      phx-mounted={@overlay_enter}
      phx-remove={@overlay_leave}
      phx-click={@on_close}
      phx-target={@target}
    >
    </div>
    <aside
      :if={@open}
      id={@id}
      data-part="drawer"
      class={@panel_class}
      phx-mounted={@enter}
      phx-remove={@leave}
      role="dialog"
      aria-modal="true"
      aria-labelledby={@titled? && @id <> "-title"}
      tabindex="-1"
      phx-window-keydown={@on_close}
      phx-key="Escape"
      phx-target={@target}
      {@rest}
    >
      <header data-part="drawer-header" class={@header_class}>
        <%= if @header == [] do %>
          <.title_content
            id={@id <> "-title"}
            title={@title}
            text={@title_text}
            description={@description}
          />
        <% else %>
          {render_slot(@header)}
        <% end %>
        <button
          :if={@close_button}
          data-part="drawer-close"
          type="button"
          class={@x_class}
          aria-label={@close_label}
          phx-click={@on_close}
          phx-target={@target}
        >
          <.icon name="x" />
        </button>
      </header>
      <div data-part="drawer-body" class={@body_class_s}>{render_slot(@inner_block)}</div>
      <footer :for={f <- @footer} data-part="drawer-footer" class={@footer_class}>
        {render_slot(f)}
      </footer>
    </aside>
    """
  end

  defp render_drawer(assigns) do
    side = if assigns.placement in [nil, ""], do: assigns.side, else: assigns.placement
    bottom? = side == "bottom"
    flush? = assigns.variant == "flush"

    sheet? =
      assigns.titled? or assigns.header != [] or assigns.footer != [] or assigns.floating or
        assigns.variant not in [nil, ""] or assigns.back != [] or assigns.actions != []

    panel_class =
      cond do
        bottom? ->
          [@sheet, !assigns.inline && "h-[78%]"]

        true ->
          [
            @panel,
            @position[{side, flush?}],
            if(assigns.size in [nil, ""],
              do: "w-[500px] max-w-[80%]",
              else: [
                @width_class[assigns.size],
                if(flush?, do: "max-w-full", else: "max-w-[calc(100%-16px)]")
              ]
            )
          ]
      end

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
      "aria-labelledby" => if(assigns.titled?, do: assigns.id <> "-title"),
      "tabindex" => if(!assigns.inline, do: "-1")
    }

    assigns =
      assigns
      |> assign(:side, side)
      |> assign(
        :root_class,
        cx([
          if(assigns.inline, do: @scrim_inline, else: @scrim_hooked),
          !assigns.inline &&
            if(assigns.overlay, do: "bg-overlay", else: "pointer-events-none bg-transparent")
        ])
      )
      |> assign(:state, if(assigns.open, do: "open", else: "closed"))
      |> assign(
        :panel_class_s,
        cx([
          panel_class,
          !assigns.overlay && !assigns.inline && "pointer-events-auto",
          assigns.class,
          assigns.panel_class
        ])
      )
      |> assign(:panel_attrs, panel_attrs)
      |> assign(:cfg, cfg)
      |> assign(:hook, if(assigns.inline, do: nil, else: "LedgerUI.Overlay"))
      |> assign(:bottom?, bottom?)
      |> assign(:sheet?, sheet?)
      |> assign(
        :header?,
        assigns.titled? or assigns.header != [] or assigns.back != [] or
          assigns.actions != []
      )
      |> assign(:header_slot, List.first(assigns.header))
      |> assign(:title_class, @title)
      |> assign(:desc_class, @desc)
      |> assign(:body_class_s, cx([@body, assigns.body_class]))

    ~H"""
    <div
      id={@id}
      data-part="drawer-overlay"
      class={@root_class}
      phx-hook={@hook}
      data-lu-overlay={!@inline && ""}
      data-state={!@inline && @state}
      {@cfg}
      {@rest}
    >
      <div
        data-part="drawer"
        data-lu-side={@side}
        class={@panel_class_s}
        {@panel_attrs}
      >
        <div
          :if={@bottom?}
          data-part="drawer-grab"
          class="mx-auto mt-2 mb-0.5 h-1 w-10 rounded-[2px] bg-line-strong"
        >
        </div>
        <.sheet_header
          :if={@header?}
          id={@id <> "-title"}
          drawer={@id}
          title={@title_text}
          description={@description}
          close_button={@close_button}
          close_label={@close_label}
          class={@header_slot && @header_slot[:class]}
          style={@header_slot && @header_slot[:style]}
        >
          <:back :if={@back != []}>{render_slot(@back)}</:back>
          <:actions :if={@actions != []}>{render_slot(@actions)}</:actions>
          <:content :if={@header != []}>{render_slot(@header)}</:content>
          <:content :if={@header == [] and @title != []}>
            <.title_content
              id={@id <> "-title"}
              title={@title}
              description={@description}
              h_class={@title_class}
              p_class={@desc_class}
            />
          </:content>
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

  attr :id, :string, required: true
  attr :open, :boolean, default: false

  attr :layout, :string,
    default: nil,
    values: [nil, "", "page"],
    doc:
      "`page`: the canvas-v2 sheet (a dim overlay + an `aside` panel with `header`, `.bd`, `footer`), shown only while `open` and closed by `on_close` (a LiveView event or `%JS{}`)."

  attr :side, :string, default: "left", values: ["left", "right"]

  attr :placement, :string,
    default: "bottom",
    values: [nil, "", "left", "right", "bottom"],
    doc: "The same as `side`, which it overrides when given."

  attr :size, :string, default: nil, values: [nil, "", "sm", "md", "lg", "wide", "xl"]
  attr :variant, :string, default: nil, values: [nil, "", "float", "flush"]
  attr :description, :string, default: nil
  attr :close_button, :boolean, default: true
  attr :close_label, :string, default: "Close"

  attr :floating, :boolean,
    default: false,
    doc:
      "A sheet that floats with margins around it, the look of `variant=\"float\"`; makes a bare drawer a sheet."

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

  slot :title,
    doc:
      "The sheet's title (the `title=\"...\"` attribute, a plain string, does the same); draws the header."

  slot :footer do
    attr :class, :any
  end

  slot :header do
    attr :class, :any
    attr :style, :string
  end

  slot :inner_block, required: true
  @doc "Same as `drawer/1` (same attributes and slots), under the name the design vitrine uses."
  def sheet(assigns), do: drawer(assigns)

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

    assigns =
      assigns
      |> assign(:close_js, close)
      |> assign(:header_class, @header)
      |> assign(:title_class, @title)
      |> assign(:desc_class, @desc)
      |> assign(:x_class, @x)

    ~H"""
    <div data-part="drawer-header" class={cx([@header_class, @class])} {Support.st(@style)} {@rest}>
      {render_slot(@back)}
      <%= if @content == [] do %>
        <div data-part="drawer-heading">
          <h3 id={@id} data-part="drawer-title" class={@title_class}>{@title}</h3>
          <p :if={@description} data-part="drawer-description" class={@desc_class}>{@description}</p>
        </div>
      <% else %>
        {render_slot(@content)}
      <% end %>
      {render_slot(@actions)}
      <button
        :if={@close_button}
        data-part="drawer-close"
        aria-label={@close_label}
        class={@x_class}
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
    assigns = assign(assigns, :body_class, @body)

    ~H"""
    <div data-part="drawer-body" class={cx([@body_class, @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "The footer of a sheet: the buttons, aligned to the end on a tinted bar."
  def sheet_footer(assigns) do
    assigns = assign(assigns, :footer_class, @footer)

    ~H"""
    <div data-part="drawer-footer" class={cx([@footer_class, @class])} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
