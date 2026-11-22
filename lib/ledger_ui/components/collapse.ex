defmodule LedgerUI.Components.Collapse do
  @moduledoc """
  A section that opens and closes under its trigger (`<.collapse>`) and a text clamped to a few
  lines with a "show more" link (`<.collapse_text>`).

      <.collapse id="details">
        <:trigger>Shipping details</:trigger>
        <p>Ships in two days.</p>
      </.collapse>

      <.collapse id="files" open chevron="down" variant="section">
        <:trigger>My files</:trigger>
        ...
      </.collapse>

      <.collapse_text id="desc" lines={2} more="Show more" less="Show less">
        Long text...
      </.collapse_text>

  `collapse` is a native `<details>`: the trigger works with the mouse and the keyboard and the
  browser owns `open`; when the server changes `open`, the server wins. `LedgerUI.open/close/toggle("id")`
  open and close it too. `on_open` / `on_close` run on every toggle (an event name pushes
  `%{"id" => id}` to the LiveView or `target`; a `%JS{}` is run as is). The `LedgerUI.Collapse` hook
  (`priv/static/ledger_ui/hooks/collapse.js`) provides the events and the chevron's turn.

  `variant` is the design canvas section by default; `classic` (or `nil`) leaves the trigger to its
  `class`; `framed`, `flat` and `section` are the other ready-made looks.
  """
  use LedgerUI.Component
  alias LedgerUI.Components.Modal.Support

  @details %{
    "canvas" => "rounded-lg bg-panel shadow-[inset_0_0_0_1px_var(--lu-line)]",
    "framed" => "rounded-[12px] shadow-[inset_0_0_0_1px_var(--lu-line)]",
    "flat" => "border-b border-line"
  }
  @summary %{
    "canvas" => "px-4 py-3.5 text-sm/[21px] font-medium text-ink",
    "framed" => "px-4 py-3.5 font-medium",
    "flat" => "py-3 font-medium",
    "section" => "py-2 text-[11.5px] font-medium tracking-[.06em] text-muted uppercase"
  }
  @panel %{
    "canvas" => "px-4 pb-3.5 text-[13.5px]/[21px] text-muted",
    "framed" => "px-4 pb-3.5",
    "flat" => "pb-3",
    "section" => "pb-2"
  }
  @summary_base "cursor-pointer list-none"
  @flex "flex items-center justify-between gap-2.5"
  @more "inline-flex cursor-pointer items-center justify-center gap-1.5 px-2.5 text-[13px] leading-none font-medium whitespace-nowrap text-accent-content hover:underline hover:underline-offset-[3px]"

  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :on_open, :any, default: nil
  attr :on_close, :any, default: nil
  attr :target, :any, default: nil
  attr :chevron, :string, default: nil, values: [nil, "", "down", "right"]

  attr :variant, :string,
    default: "canvas",
    values: [nil, "", "classic", "framed", "flat", "section", "canvas"]

  attr :panel_class, :any, default: nil
  attr :chevron_class, :any, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  slot :trigger, required: true do
    attr :class, :any
    attr :style, :string
  end

  def collapse(assigns) do
    v = if assigns.variant in [nil, "", "classic"], do: nil, else: assigns.variant
    [trigger | _] = assigns.trigger
    chevron = assigns.chevron not in [nil, ""] && assigns.chevron

    cfg =
      Support.cfg("collapse",
        open: Support.flag(assigns.open),
        chevron: chevron || nil,
        "on-open": Support.handler(assigns.on_open),
        "on-close": Support.handler(assigns.on_close),
        target: assigns.target
      )

    assigns =
      assigns
      |> assign(:cfg, cfg)
      |> assign(:cls, Support.class(cx([v && @details[v], assigns.class])))
      |> assign(:rest, Map.delete(assigns.rest, :style))
      |> assign(:style_d, assigns.rest[:style])
      |> assign(:trigger_style, trigger[:style])
      |> assign(
        :summary_class,
        Support.class(
          cx([v && @summary_base, v && @summary[v], chevron && @flex, trigger[:class]])
        )
      )
      |> assign(:chevron_name, if(chevron == "right", do: "chevron-right", else: "chevron-down"))
      |> assign(:chevron?, chevron)
      |> assign(:wrap?, v != nil or assigns.panel_class != nil)
      |> assign(:panel_class_s, cx([v && @panel[v], assigns.panel_class]))
      |> assign(:trigger_slot, trigger)

    ~H"""
    <details
      id={@id}
      data-part="collapse"
      class={@cls}
      {Support.st(@style_d)}
      open={@open}
      phx-hook="LedgerUI.Collapse"
      {@cfg}
      {@rest}
    >
      <summary data-part="collapse-trigger" class={@summary_class} {Support.st(@trigger_style)}>
        {render_slot(@trigger_slot)}
        <.icon
          :if={@chevron?}
          name={@chevron_name}
          size="sm"
          class={@chevron_class}
          data-part="collapse-chevron"
          data-lu-chevron-el=""
        />
      </summary>
      <%= if @wrap? do %>
        <div data-part="collapse-panel" class={Support.class(@panel_class_s)}>
          {render_slot(@inner_block)}
        </div>
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
    </details>
    """
  end

  attr :id, :string, required: true
  attr :lines, :integer, default: 2
  attr :open, :boolean, default: false
  attr :more, :string, default: nil
  attr :less, :string, default: nil
  attr :class, :any, default: nil
  attr :text_class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  @doc """
  A text clamped to `lines` lines, with a link under it that shows the rest and hides it again.
  Works in the browser (no event to the server); the link has `aria-expanded` and `aria-controls`.
  """
  attr :locale, :string,
    default: nil,
    doc:
      "`\"en\"` or `\"pt_BR\"`; default: the process locale, the app config, `\"en\"` (see `LedgerUI.I18n`)."

  def collapse_text(assigns) do
    assigns = I18n.texts(assigns, more: "collapse.more", less: "collapse.less")

    clamp =
      "display:-webkit-box;-webkit-box-orient:vertical;-webkit-line-clamp:#{assigns.lines};overflow:hidden"

    cfg =
      Support.cfg("collapse-text",
        open: Support.flag(assigns.open),
        lines: assigns.lines,
        more: assigns.more,
        less: assigns.less
      )

    assigns =
      assigns
      |> assign(:cfg, cfg)
      |> assign(:text_style, if(!assigns.open, do: clamp))
      |> assign(:label, if(assigns.open, do: assigns.less, else: assigns.more))
      |> assign(:text_id, assigns.id <> "-text")
      |> assign(:more_class, @more)

    ~H"""
    <div id={@id} data-part="collapse-text" class={@class} phx-hook="LedgerUI.Collapse" {@cfg} {@rest}>
      <div
        id={@text_id}
        data-part="collapse-text-body"
        class={@text_class}
        {Support.st(@text_style)}
        keep-style
      >
        {render_slot(@inner_block)}
      </div>
      <button
        type="button"
        data-part="collapse-more"
        class={@more_class}
        aria-expanded={Support.flag(@open)}
        aria-controls={@text_id}
        data-lu-more=""
      >
        {@label}
      </button>
    </div>
    """
  end
end
